import { LightningElement, track } from "lwc";
import getBudgetYearsFromServer from "@salesforce/apex/CBPeriodPageController.getBudgetYearsFromServer";
import getPeriodsFromServer from "@salesforce/apex/CBPeriodPageController.getPeriodsFromServer";
import saveBYandPeriodToServer from "@salesforce/apex/CBPeriodPageController.saveBYandPeriodToServer";
import { _cl, _isInvalid, _message, _parseServerError } from "c/cbUtils";
import { label } from "c/cbUtilityLabel";

export default class cbPeriodsSetup extends LightningElement {
  @track customLabel = label;
  @track quarterNumber = 1;
  @track bYList = [];
  @track periodList = [];
  @track bYId;
  @track showPeriodDialog = false;
  @track showBYDialog = false;
  @track bYNameList = [];
  @track sYNameList = [];
  @track monthArray = [
    "JANUARY",
    "FEBRUARY",
    "MARCH",
    "APRIL",
    "MAY",
    "JUNE",
    "JULY",
    "AUGUST",
    "SEPTEMBER",
    "OCTOBER",
    "NOVEMBER",
    "DECEMBER",
  ];

  @track periodDetail = {};
  BYSO = [];
  @track budgetYearSetting = {};

  periodNameFormatList = [];
  monthList = [];
  periodTypeOptionsList = [
    { label: this.customLabel.cb_month, value: "12" },
    { label: this.customLabel.cb_quarter, value: "4" },
  ];
  monthList = [
    { label: "JAN", value: "1" },
    { label: "FEB", value: "2" },
    { label: "MAR", value: "3" },
    { label: "APR", value: "4" },
    { label: "MAY", value: "5" },
    { label: "JUN", value: "6" },
    { label: "JUL", value: "7" },
    { label: "AUG", value: "8" },
    { label: "SEP", value: "9" },
    { label: "OCT", value: "10" },
    { label: "NOV", value: "11" },
    { label: "DEC", value: "12" },
  ];

  periodNameFormatList = [
    { label: "MM/YY (09/22)", value: "1" },
    { label: "YYYY/MM (2022/09)", value: "2" },
    { label: "MMM YY (SEP 22)", value: "3" },
    { label: "YYYY-MM (2022-09)", value: "4" },
    { label: "YYYY/MMM (2022/SEP)", value: "5" },
    { label: "Quarter (Q1/2022)", value: "6" },
  ];

  periodlenght = 1;

  connectedCallback() {
    this.getBYListFromServer();
    this.getPeriodListFromServer();

    document.title = this.customLabel.cb_period_setup;
  }
  //getBYListFromServer method download BY list from server
  getBYListFromServer() {
    getBudgetYearsFromServer()
      .then((result) => {
        this.bYList = result;
        this.budgetYearSetting = {};
        this.populateBYSO();
      })
      .catch((e) => {
        _parseServerError(this.customLabel.cb_get_by_error, e)
      });
  }

  //getBYListFromServer method download Period list from server
  getPeriodListFromServer() {
    getPeriodsFromServer()
      .then((result) => {
        this.periodList = result;
      })
      .catch((e) => {
        _parseServerError( this.customLabel.cb_get_periods_list_error, e)
      });
  }
  //This method handles period details from Period List  to period Dialod
  handlePeriodDetails(event) {
    this.periodId = event.target.dataset.id;
    this.togglePeriodDialog();
    this.periodDetail = Object.assign(
      {},
      this.periodList.find(({ Id }) => Id === this.periodId)
    );
  }
  //This method handles changes(period or BY object)
  handleChange(event) {
    const name = event.target.name;
    const value = event.target.value;
    if (this.showPeriodDialog) {
      this.periodDetail[name] = value;
    } else if (this.showBYDialog || !this.showPeriodDialog) {
      this.budgetYearSetting[name] = value;

      if (name == "periodTypeOptions") {
        switch (value) {
          case "12":
            this.budgetYearSetting.quarter = false;
            this.budgetYearSetting.periodNameFormat = "1";
            break;
          default:
            this.budgetYearSetting.quarter = true;
            this.budgetYearSetting.periodNameFormat = "6";
            break;
        }
      }
      if (name == "periodNameFormat") {
        switch (value) {
          case "6":
            this.budgetYearSetting.periodTypeOptions = "4";
            break;
          default:
            this.budgetYearSetting.periodTypeOptions = "12";
            break;
        }
      }
      if (name == "Name" && !this.showBYDialog) {
        this.budgetYearSetting.yearStart = value;
        this.budgetYearSetting.monthStart = "1";

      }
    }
  }



  //This method saves updated period details to server
  savePeriodDetails(event) {
    try {
      const periodRecords = [this.periodDetail];
      const byRecord = periodRecords[0].cblight__CBBudgetYear__r;
      let periodEndDate = new Date(this.periodDetail.cblight__End__c);
      let periodStartDate = new Date(this.periodDetail.cblight__Start__c);

      if (periodEndDate < periodStartDate) {
        _message('error',  this.customLabel.cb_end_and_start_dates_error, 'Error');
        return;
      }
      saveBYandPeriodToServer({ byRecord, periodRecords })
        .then(() => {
          _message('success', this.customLabel.cb_period_details_updated);
          this.getPeriodListFromServer();
        })
        .catch((e) => {
          _parseServerError(this.customLabel.cb_by-period_creating_error, e)
         
        });
      this.togglePeriodDialog();
    } catch (e) {
      _message('error', this.customLabel.cb_by-period_creating_error + e, 'Error');
    }
  }

  //This methods opens/closes period Dialog
  togglePeriodDialog() {
    this.showPeriodDialog = !this.showPeriodDialog;
  }

  //This methods opens/closes BY Dialog
  handleBYDetails(event) {
    this.budgetYearSetting.Id = event.target.dataset.id;
    this.toggleBYModal();
    this.budgetYearSetting = Object.assign(
      {},
      this.bYList.find(({ Id }) => Id === this.budgetYearSetting.Id)
    );
  }

  //This method saves updated BY details to server
  saveBYDetails(event) {
    const byRecord = this.budgetYearSetting;

    try {
      let bYEndDate = new Date(this.budgetYearSetting.cblight__End__c);
      let bYStartDate = new Date(this.budgetYearSetting.cblight__Start__c);

      if (bYEndDate < bYStartDate) {
        _message('error',  this.customLabel.cb_end_and_start_dates_error, 'Error');
        return;
      }
      saveBYandPeriodToServer({ byRecord })
        .then(() => {
          _message('success',  this.customLabel.cb_period_details_updated);
          this.getBYListFromServer();
          this.toggleBYModal();
        })
        .catch((e) => {
          _parseServerError(this.customLabel.cb_start_date_exists_error, e)
        });
    } catch (e) {
      _message('error',  this.customLabel.cb_start_date_exists_error + e);
    }
  }

  //This methods opens/closes BY Dialog
  toggleBYModal() {
    this.showBYDialog = !this.showBYDialog;
    if (!this.showBYDialog) {
      this.budgetYearSetting = {};
      delete this.budgetYearSetting.Id;
    }
  }

  //This methods generates new BY from inputed information
  generateNewBY() {
    return {
      Name: String(this.budgetYearSetting.Name),
      cblight__Start__c: new Date(
        this.budgetYearSetting.yearStart,
        this.budgetYearSetting.monthStart - 1,
        2
      ),
    };
  }

  //This methods generates new period Name depends of period name format choice
  generatePeriodName(periodYear, bYmonth, periodlenght) {
    if (periodlenght == 1) {
      switch (this.budgetYearSetting.periodNameFormat) {
        case "1":
          return bYmonth + "/" + String(periodYear).substring(2, 4);
        case "2":
          return periodYear + "/" + bYmonth.toString().padStart(2, "0");
        case "3":
          return (
            this.monthArray[bYmonth - 1].substring(0, 3) +
            " " +
            String(periodYear).substring(2, 4)
          );
        case "4":
          return periodYear + "-" + String(bYmonth).padStart(2, "0");
        case "5":
          return (
            periodYear + "/" + this.monthArray[bYmonth - 1].substring(0, 3)
          );
      }
    }
    this.quarterNumber = this.quarterNumber > 4 ? 1 : this.quarterNumber;
    const quarterNumber = "Q" + this.quarterNumber + "/" + periodYear;
    this.quarterNumber++;
    return quarterNumber;
  }
  //This methods generates new period Name list based on generated BY
  generateNewPeriodList() {
    let periodRecords = [];
    this.budgetYearSetting.periodTypeOptions == 4
      ? (this.periodlenght = 3)
      : (this.periodlenght = 1);
    let periodYear = parseInt(this.budgetYearSetting.yearStart);
    let bYmonth = parseInt(this.budgetYearSetting.monthStart);

    for (let j = 1; j <= this.budgetYearSetting.periodTypeOptions; j++) {
      if (bYmonth === 13) {
        bYmonth = 1;
        periodYear++;
      }
      periodRecords.push({
        Name: this.generatePeriodName(periodYear, bYmonth, this.periodlenght),
        cblight__Start__c: new Date(periodYear, bYmonth - 1, 2),
        cblight__End__c: new Date(periodYear, bYmonth + this.periodlenght - 1, 1),
      });
      bYmonth = bYmonth + this.periodlenght;
    }
    return periodRecords;
  }
  //This methods creates new  BY and period and save it to server
  createBYandPeriods(event) {
    try {
      if (
        this.budgetYearSetting.Name === undefined ||
        this.budgetYearSetting.periodNameFormat === undefined ||
        this.budgetYearSetting.yearStart === undefined ||
        this.budgetYearSetting.monthStart === undefined ||
        this.budgetYearSetting.periodTypeOptions === undefined
      ) {
        _message('error',   "Please, input data in all input fields");
      } else if (
        confirm(
          this.customLabel.cb_you_are_creating +
            " " +
            this.budgetYearSetting.Name +
            this.customLabel.cb_by_from +
            " " +
            this.monthArray[this.budgetYearSetting.monthStart - 1] +
            " " +
            this.budgetYearSetting.yearStart +
            ", " +
            this.customLabel.cb_totally +
            this.budgetYearSetting.periodTypeOptions +
            ". " +
            this.customLabel.cb_are_you_sure
        )
      ) {
        const byRecord = this.generateNewBY();
        const periodRecords = this.generateNewPeriodList();

        saveBYandPeriodToServer({ byRecord, periodRecords })
          .then(() => {
            this.getBYListFromServer();
            _message('success',   this.customLabel.cb_periods_and_by_created);
            this.getBYListFromServer();
            this.getPeriodListFromServer();
          })
          .catch((e) => {
            _parseServerError(this.customLabel.cb_by_period_creating_error, e)
          });
      }
    } catch (e) {
      _message('error',   this.customLabel.cb_year_periods_error + e);
    }
  }
  //This methods generates new period Name depends of period name format choice
  populateBYSO() {
    this.BYSO = [];
    let currentStartYear = new Date().getFullYear() - 10;
    this.bYNameList = this.bYList.map(({ cblight__Start__c }) =>
      cblight__Start__c.substring(0, 4)
    );
    let maxbY = new Date().getFullYear() + 15;
    while (this.BYSO.length < 25 && currentStartYear <= maxbY) {
      if (!this.bYNameList.includes(String(currentStartYear))) {
        this.BYSO.push({
          label: currentStartYear,
          value: currentStartYear + "",
        });
      }
      currentStartYear++;
    }
  }
}