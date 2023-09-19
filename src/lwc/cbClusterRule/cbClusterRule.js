import { api, LightningElement, track } from "lwc";
import getCBClusterRuleServer from "@salesforce/apex/CBClusterRulePageController.getCBClusterRuleServer";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import getBLFieldsSOServer from "@salesforce/apex/CBClusterRulePageController.getBLFieldsSOServer";
import saveClusterLevelsToServer from "@salesforce/apex/CBClusterRulePageController.saveClusterLevelsToServer";
import deleteClusterRuleFromServer from "@salesforce/apex/CBClusterRulePageController.deleteClusterRuleFromServer";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { _cl } from "c/cbUtils";

export default class CbClusterRule extends NavigationMixin(LightningElement) {
	@api recordId; // render clusters rule details if modified
	@track clusterRule = {};
	@track showLevel = {};
	@track BLFieldsSO = [];
	@track orgVariable = {};
	@track showContent = false;
	@track notValid;
	IGNORED_FIELDS = [
		"Id",
		"cblight__User__c",
		"OwnerId",
		"Name",
		"cblight__APAheadTrigger__c",
		"cblight__APBackTrigger__c",
		"cblight__APHaveAccessToAhead__c",
		"cblight__APHaveAccessToBack__c",
		"cblight__APNextStatusName__c",
		"cblight__APPreviousStatusName__c",
		"cblight__NFL1__c",
		"cblight__NFL2__c",
		"cblight__NFL3__c",
		"cblight__NFL4__c",
		"cblight__NFL5__c",
		"cblight__isFormulaBudgetLine__c",
		"cblight__NFLFormula__c",
		"cblight__Approval_Status__c",
		"cblight__ButtonTitle__c",
		"cblight__CBAccountSign__c",
		"cblight__CBBudgetYear__c",
		"cblight__CBKey__c",
		"cblight__Code__c",
		"cblight__ForwardTrigger__c",
		"cblight__HasAccess__c",
		"cblight__Index__c",
		"cblight__Value__c",
		"CurrencyIsoCode",
		"cblight__Description__c",
		"cblight__ParentBudgetLine__c",
		"cblight__Buttontitle__c"
	];

	connectedCallback() {
		this.getClusterRulesFromServer();
		this.getBudgetLineFieldsFromServer();
	}

	/*
	 * getClusterRules method download  Cluster Rule from server
	 */
	getClusterRulesFromServer() {
		if (this.recordId !== undefined) {
			const recordId = this.recordId;
			getCBClusterRuleServer({ recordId })
				.then((clusterRule) => {
					this.clusterRule = clusterRule;
					this.showLevelCombobox();
				})
				.catch((e) => alert("GET CLUSTER RULES ERROR " + JSON.stringify(e)));
		}
	}

	/*
	 * getClusterRules method download  BL fields from server
	 */
	getBudgetLineFieldsFromServer() {
		getBLFieldsSOServer()
			.then((BLFieldsSO) => {
				this.BLFieldsSO = BLFieldsSO.filter(
					(so) => !this.IGNORED_FIELDS.includes(so.value)
				);
				this.getOrgVariable();
			})
			.catch((e) => alert("GET BL Fields ERROR " + JSON.stringify(e)));
	}

	/**
	 * Org variables for rendering
	 */
	getOrgVariable() {
		getOrgVariableServer()
			.then((variable) => {
				this.orgVariable = variable;
				const replaceMap = {};
				Object.keys(this.orgVariable).forEach(
					(key) =>
						(replaceMap[key.replace("Label", "")] = this.orgVariable[key])
				);
				this.BLFieldsSO.forEach(
					(so) =>
						(so.label = replaceMap[so.value] ? replaceMap[so.value] : so.label)
				);
				this.BLFieldsSO.sort((current,next)=>{ return current.label.localeCompare(next.label)});
				this.BLFieldsSO.unshift({ label: "Level is not in use", value: "" });
				this.showContent = true;
			})
			.catch((e) =>
				_parseServerError("Cluster Rule : Org Variables Error : ", e)
			);
	}

	/*
	 * This method handleChanges in input fields
	 */
	handleChange(event) {
		this.clusterRule[event.target.name] = event.target.value;
		this.removeValuefromLevel();
		this.showLevelCombobox();
	}

	/*
	 * This method makes hidden levels empty
	 */
	removeValuefromLevel() {
		for (let x = 1; x < 5; x++) {
			if (this.clusterRule[`cblight__Level${x}__c`] === "") {
				this.clusterRule[`cblight__Level${x + 1}__c`] = "";
			}
			if (
				this.clusterRule.cblight__Level1__c === "" ||
				this.clusterRule.Name === ""
			) {
				this.runToast(
					"Error",
					"Cluster Rule should have Name and first level at least!",
					"error"
				);
			}
		}
	}

	/*
	 * This method shows levels on page
	 */
	showLevelCombobox() {
		for (let i = 1; i < 5; i++) {
			if (this.clusterRule[`cblight__Level${i}__c`]) {
				this.showLevel[`cblight__Level${i}__c`] = true;
			}
			if (!this.clusterRule[`cblight__Level${i}__c`]) {
				this.showLevel[`cblight__Level${i}__c`] = false;
			}
		}
	}

	/*
	 * This method saves Cluster Rule to Server
	 */
	saveClusterRulesToServer() {
		this.prepareAndCheckLevels();
		if (this.notValid) {
			this.runToast(
				"Error",
				"Cluster Rule levels are duplicated or complete Name and first level at least!",
				"error"
			);
		} else if (
			confirm("Do you want to save changes and back to Cluster Rule list?")
		) {
			saveClusterLevelsToServer({ CRRecord: this.clusterRule })
				.then(() => {
					this.runToast("Saved", "Cluster Rule levels are updated", "success");
					this.openClusterRuleList();
				})
				.catch((e) =>
					this.runToast(
						"Error",
						"Cluster Rule levels updating ERROR " + JSON.stringify(e),
						"error"
					)
				);
		}
	}

	/*
	 *This method deletes Cluster Rule from Server
	 */
	deleteClusterRuleFromServer() {
		if (confirm("Do you want to delete and back to Cluster Rule list?")) {
			deleteClusterRuleFromServer({ CRRecord: this.clusterRule })
				.then(() => {
					this.runToast("Saved", "Cluster Rule levels are deleted", "success");
					this.openClusterRuleList();
				})
				.catch((e) =>
					this.runToast(
						"Error",
						"Cluster Rule levels delete ERROR " + JSON.stringify(e),
						"error"
					)
				);
		}
	}

	/*
	 * This method remove not used levels from Cluster rule properties
	 */
	prepareAndCheckLevels() {
		if (this.checkForDuplicates()) {
			this.notValid = true;
		} else if (!this.checkForDuplicates()) {
			this.notValid = false;
		}
		if (
			this.clusterRule.cblight__Level1__c === "" ||
			this.clusterRule.cblight__Level1__c === undefined ||
			this.clusterRule.Name === "" ||
			this.clusterRule.Name === undefined
		) {
			this.notValid = true;
		}
	}

	/*
	 * Method check if levels are duplicated
	 */
	checkForDuplicates() {
		let levelValues = [];
		for (let key in this.clusterRule) {
			for (let i = 1; i < 6; i++) {
				if (key === "cblight__Level" + i + "__c") {
					levelValues.push(this.clusterRule[`cblight__Level${i}__c`]);
				}
			}
		}
		let filteredLevelValues = levelValues.filter((notEmptyLevel) => {
			return notEmptyLevel !== "";
		});
		return new Set(filteredLevelValues).size !== filteredLevelValues.length;
	}

	/*
	 * This method opens Cluster Rule List
	 */
	openClusterRuleList() {
		try {
			this[NavigationMixin.Navigate]({
				type: "standard__objectPage",
				attributes: {
					objectApiName: "cblight__CBClusterRule__c",
					actionName: "list",
				},
				state: {
					filterName: "Recent",
				},
			});
		} catch (e) {
			alert("Open Cluster Rule List Error: " + e);
		}
	}

	/*
	 * This method shows toast message
	 */
	runToast(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title,
				message,
				variant,
			})
		);
	}
}