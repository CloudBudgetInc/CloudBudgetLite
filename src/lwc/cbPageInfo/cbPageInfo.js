import {api, LightningElement, track} from "lwc";
import {_isInvalid, _message, _parseServerError} from "c/cbUtils";
import getIdToNamesMapServer from "@salesforce/apex/CBBudgetLinePageController.getIdToNamesMapServer";
import getSingleScenarioServer from "@salesforce/apex/CBBudgetLinePageController.getSingleScenarioServer";

export default class CbPageInfo extends LightningElement {
	pageObjectInner = {};
	@track config = null;
	@track displayedList = []; // displayed list
	@track displayedListWithConfig = [];
	@track styleClassConst = 'slds-p-around_xxx-small slds-text-align_center blockTransparency ';
	@track styleClassAdd = '';
	@track styleClass = '';
	fieldsNeedToBeAddedLabels = {
		cblight__CBAccount__c: "cblight__CBAccountLabel__c",
		cblight__CBBudgetYear__c: "cblight__CBBudgetYearLabel__c",
		cblight__CBDivision__c: "cblight__CBDivisionLabel__c",
		cblight__CBVariable1__c: "cblight__CBVariable1Label__c",
		cblight__CBVariable2__c: "cblight__CBVariable2Label__c",
		cblight__CBVariable3__c: "cblight__CBVariable3Label__c",
		cblight__CBVariable4__c: "cblight__CBVariable4Label__c",
		cblight__CBVariable5__c: "cblight__CBVariable5Label__c"
	};

	/**
	 * Set pageObject
	 */
	@api
	set pageObject(value) {
		this.pageObjectInner = value;
		this.getPageObject();
	}

	/**
	 * Get pageObject
	 */
	get pageObject() {
		return this.pageObjectInner;
	}

	/**
	 * Set or clear Configuration
	 */
	@api setConfig = (func) => {
		this.config = func;
		if (this.config) {
			let tmpConfig = {
				key: 'Config:',
				value: this.config.cblight__Title__c
			};
			this.displayedListWithConfig = [tmpConfig, ...this.displayedList];
		} else {
			this.displayedListWithConfig = [...this.displayedList];
		}
	};

	/**
	 * Method gets the component object
	 */
	getPageObject() {
		try {
			if (!this.pageObjectInner) return;
			let obj = this.pageObjectInner;
			let scenarioId = false;
			Object.keys(obj).forEach(key => {
				let objKey = obj[key];
				if (key === 'cblight__CBScenario__c' && !_isInvalid(objKey)) {
					scenarioId = objKey;
				}
			});
			if (!scenarioId) {
				this.styleClassAdd = 'infoStyle';
				this.styleClass = this.styleClassConst + this.styleClassAdd;
			} else {
				this.getSingleScenario(scenarioId);
			}
			this.getIdToNamesMap(obj);
		} catch (e) {
			_message("error", `Page Info : Get Page Object Error: " + ${e}`);
		}
	}

	/**
	 * Method correct obj labels
	 */
	getCorrectLabels(obj) {
		try {
			if (!obj) return;
			console.log('OBJ: ' + JSON.stringify(obj));
			let orgVariable = JSON.parse(localStorage.getItem("orgVariable"));
			obj.forEach(item => {
				let orgLabel = this.fieldsNeedToBeAddedLabels[item.key];
				if (orgLabel) item.key = orgVariable[orgLabel];
			});
			this.checkObjValues(obj);
		} catch (e) {
			_message("error", `Page Info : Get Correct Labels Error: " + ${e}`);
		}
	}

	/**
	 * Method filter obj values
	 */
	checkObjValues(obj) {
		try {
			if (!obj) return;
			let selectOpt = {
				cblight__CBScenario__c: "CB Scenario",
				cblight__CBClusterRule__c: "CB Cluster Rule",
				complexFilter: "Complex Filter",
				allocationMode: "Allocation Mode",
				approach: "Approach",
				OwnerId: "User",
				textFilter: "Text Filter"
			};
			let tmpArray = [];
			obj.forEach((item) => {
				if (_isInvalid(item.value)) {
					return;
				}
				if (item.key === 'complexFilter' && !_isInvalid(item.value)) {
					item.value = localStorage.getItem("formattedRequestString");
				}
				let orgLabel = selectOpt[item.key];
				if (orgLabel) item.key = orgLabel;
				item.key += ": ";
				tmpArray.push(item);
			});
			this.displayedList = tmpArray;
			localStorage.setItem('displayedList', JSON.stringify(this.displayedList));
			if (this.config) {
				let tmpConfig = {
					key: 'Config:',
					value: this.config.cblight__Title__c
				};
				this.displayedListWithConfig = [tmpConfig, ...this.displayedList];
			} else {
				this.displayedListWithConfig = [...this.displayedList];
			}
		} catch (e) {
			_message("error", `Page Info : check Obj Values Error: " + ${e}`);
		}
	}

	/**
	 * Method gets Id To Names Map
	 */
	getIdToNamesMap(tmpArray) {
		try {
			if (!tmpArray) return;
			getIdToNamesMapServer({obj: tmpArray})
				.then(resultMap => this.getCorrectLabels(Object.entries(resultMap).map(([key, value]) => ({
					key,
					value
				}))))
				.catch(e => _parseServerError("Page Info : Get Id To Names Map Server Error", e))
		} catch (e) {
			_message("error", `Page Info : get Id To Names Map: " + ${e}`);
		}
	}

	/**
	 * Method gets Scenario
	 */
	getSingleScenario(id) {
		try {
			if (!id) return;
			getSingleScenarioServer({rId: id})
				.then((scenario) => {
					if (!scenario.cblight__CBStyle__r) {
						this.styleClassAdd = 'infoStyle';
					} else {
						this.styleClassAdd = scenario.cblight__CBStyle__r.Name.replace(/ /g, "");
					}
					this.styleClass = this.styleClassConst + this.styleClassAdd;
				})
				.catch(e => _parseServerError("Page Info : get Single Scenario Server Error", e))
		} catch (e) {
			_message("error", `Page Info : get Single Scenario: " + ${e}`);
		}
	}

	/**
	 * Handler of scrolling up
	 */
	scrollUp() {
		const scrollOptions = {
			left: 0,
			top: 0,
			behavior: 'smooth'
		}
		window.scrollTo(scrollOptions);
	}
}