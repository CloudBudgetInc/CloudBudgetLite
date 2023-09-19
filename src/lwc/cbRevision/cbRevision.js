import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getBudgetLineHistoryByParentId from "@salesforce/apex/CBRevisionPageController.getBudgetLineHistoryByParentId";
import getAmountHistoryByParentId from "@salesforce/apex/CBRevisionPageController.getAmountHistoryByParentId";
import { _parseServerError, _message, _cl } from "c/cbUtils";

export default class CbRevision extends LightningElement {
  @api recordId; // parent record Id
  @api orgVariable;
  @api amounts;
  @track revisions = [];
  @track grouppedRevisions = [];
  @track showSpinner = false;
  @api revisionSaveToastNeeded = false;
  separator = ", and ";
  activeSections = ["budgetLine", "amounts"];
  BUDGET_LINE_STRING_ANALYTIC_NAMES = [
    "Name",
    "cblight__Description__c",
    "cblight__Value__c",
  ];

  connectedCallback() {
    this.getBudgetLineHistory();
  }

  /**
   * Get BL Histrory from Server
   */
  getBudgetLineHistory() {
    if (this.recordId) {
      getBudgetLineHistoryByParentId({ parentId: this.recordId })
        .then((lineAnalitycsRevisions) => {
          try {
            if (lineAnalitycsRevisions) {
              lineAnalitycsRevisions.forEach((rev) => {
                if (rev.Field != "created") this.revisions.push(rev);
              });
              this.getAmountHistory();
            }
          } catch (e) {
            _message("error", "Revision : Get BL Revision Callback Error " + e);
          }
        })
        .catch((e) => _parseServerError("Revision : Get BL Revision Error", e));
    }
  }

  /**
   * Get Amount Histrory from Server
   */
  getAmountHistory() {
    getAmountHistoryByParentId({ budgetLineId: this.recordId })
      .then((amountRevisions) => {
        try {
          if (amountRevisions && amountRevisions.length != 0) {
            amountRevisions.forEach((rev) => {
              if (rev.Field != "created") this.revisions.push(rev);
            });
          }
          if (this.revisions.length > 0) this.addPeriodNameAndLabels();
        } catch (e) {
          _message("error", "Revision : Get Amount Callback Error " + e);
        }
      })
      .catch((e) =>
        _parseServerError("Revision : Get Amout Revision Error", e)
      );
  }
  /**
   * render revision lines
   */
  get showRevisions() {
    return this.grouppedRevisions.length > 0;
  }

  /**
   * Add Period Names for Amount History and Org Variable labels for Bl History
   */
  addPeriodNameAndLabels() {
    const budgetlineAmounts = this.amounts;
    const orgVariableKeys = Object.keys(this.orgVariable);

    this.revisions.forEach((rev) => {
      switch (rev.Field) {
        case "Name":
        case "cblight__Description__c":
          rev.FieldLabel = rev.Field;
          break;
        case "cblight__Value__c":
          if (budgetlineAmounts) {
            budgetlineAmounts.forEach((amount) => {
              if (rev.ParentId && rev.ParentId === amount.Id) {
                rev.FieldLabel = amount.cblight__PeriodName__c;
              }
            });
          }
        default:
          if (this.orgVariable) {
            let revisionField = rev.Field.replace("__c", "");
            orgVariableKeys.forEach((key) => {
              if (key.includes(revisionField)) {
                rev.FieldLabel = this.orgVariable[key];
              }
            });
          }
          break;
      }
    });
    this.combineBLRevisionsWithId();
  }

  /**
   * Add Id field for BL Lookup fields History
   */
  combineBLRevisionsWithId() {
    const lookupRevisions = this.revisions.filter(
      (rev) => rev.DataType == "EntityId"
    );
    lookupRevisions.forEach((lookupRev) => {
      this.revisions.forEach((rev) => {
        if (
          lookupRev.Field == rev.Field &&
          lookupRev.CreatedDate == rev.CreatedDate &&
          lookupRev.ParentId == rev.ParentId
        ) {
          rev.OldValueId = lookupRev.OldValue;
          rev.NewValueId = lookupRev.NewValue;
        }
      });
    });
    this.groupRevisions();
  }

  /**
   * Group BL and Amount History for rendering
   */
  groupRevisions() {
    this.grouppedRevisions = [];
    this.revisions.forEach((rev) => {
      if (rev.DataType != "EntityId") {
        this.grouppedRevisions.push(rev);
      }
    });
    this.grouppedRevisions.sort(
      (a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate)
    );
  }

  /**
   * Handler for the restore data button. It calls the external method form a parent component
   */
  restoreValue(event) {
    try {
      event.preventDefault();

      const rev = this.revisions.find((r) => r.Id === event.target.value);
      this.dispatchEvent(
        new CustomEvent("restoreData", {
          bubbles: true,
          composed: true,
          detail: rev,
        })
      );
    } catch (e) {
      alert("Restore Data Error: " + e);
    }
  }

  /**
   * Close the modal window
   */
  toggleRevisionDialog() {
    this.dispatchEvent(new CustomEvent('closerevisionmodal', {detail: false}));
  }
}