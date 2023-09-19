import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getListOfAvailableSObjectsServer
	from "@salesforce/apex/CBInitWizardPageController.getListOfAvailableSObjectsServer";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import getSobjectFieldsServer from "@salesforce/apex/CBInitWizardPageController.getSobjectFieldsServer";
import getRegularMappingServer from "@salesforce/apex/CBInitWizardPageController.getRegularMappingServer";
import saveMappingServer from "@salesforce/apex/CBInitWizardPageController.saveMappingServer";
import runMappingServer from "@salesforce/apex/CBInitWizardPageController.runMappingServer";
import saveConfigurationsServer from "@salesforce/apex/CBInitWizardPageController.saveConfigurationsServer";
import {_isInvalid, _message, _parseServerError} from "c/cbUtils";
import {ORGS_CONFIGS_MAP, SOBJECTS_PREFIXES_BY_ORG_TYPE_MAP,} from "./cbInitWizardConfigs";

export default class CbInitWizard extends LightningElement {
	stepOrder = [
		"accounts",
		"divisions",
		"periods",
		"variables1",
		"variables2",
		"variables3",
		"variables4",
		"variables5",
	];
	@track stepRender = {
		accounts: true,
		divisions: false,
		periods: false,
		variables1: false,
		variables2: false,
		variables3: false,
		variables4: false,
		variables5: false,
	};
	@track currentStep = "accounts"; // current step position
	@track availableSObjectSO; // available source sObject types
	@track sobjectFieldsSO; // existing fields of selected source sObject type
	@track filterTitle; // title that appear under the filter field
	@track usersAndQueues = []; //so far empty list
	@track filterString = []; // filter of source records
	@track showFilter = false;
	@track selectedSObjectName; // selected source sObject type
	@track mapping = {}; // rule of the current step mapping
	@track showSpinner = false;
	@track selectedConfiguration;
	@track showInitWizardReport = false;
	@track showWelcomeMat = false;
	@track orgVariable = {};

	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		this.getOrgVariable();
		this.getListOfAvailableSObjects();
		this.initSelectedStep();
		document.title = "Init Wizard";
	}

	/**
	 * Analitycs labels for rendering
	 */
	getOrgVariable() {
		getOrgVariableServer()
			.then((variable) => {
				this.orgVariable = variable;
				let orgVariableKeys = Object.keys(this.orgVariable);
				orgVariableKeys.forEach((key) => {
					if (key.includes("Label")) {
						this.orgVariable["map" + key] = "Map " + this.orgVariable[key];
					}
					if (key == "cblight__CBPeriodLabel__c") {
						this.orgVariable.CBPeriodSetup =
							this.orgVariable.cblight__CBPeriodLabel__c + " Setup";
						this.orgVariable.openPeriodSetup =
							"Open" + this.orgVariable.cblight__CBPeriodLabel__c + " Setup";
					}
				});
			})
			.catch((e) =>
				_parseServerError("Init Wizard : Org Variables Error : ", e)
			);
	}

	/**
	 *  This method searching SObjects API Names that belongs to other organizations such as Accounting Seed, etc.
	 */
	setPredefineConfigByOrgType() {
		loop1: for (const {value} of this.availableSObjectSO) {
			for (const key in SOBJECTS_PREFIXES_BY_ORG_TYPE_MAP) {
				if (value.startsWith(key)) {
					this.selectedConfiguration = SOBJECTS_PREFIXES_BY_ORG_TYPE_MAP[key];
					break loop1;
				}
			}
		}
	}

	constructor() {
		super();
		this.addEventListener("closeInitWizardReport", this.closeInitWizardReport);
	}

	///////////////// COMMON METHODS /////////////////////////
	/**
	 * This method get list of (custom and some CRM) SObjects API Names from current organization.
	 */
	getListOfAvailableSObjects() {
		getListOfAvailableSObjectsServer()
			.then((availableSObjectSO) => {
				const replaceMap = {};
				Object.keys(this.orgVariable).forEach(
					(key) =>
						(replaceMap[key.replace("Label", "")] = this.orgVariable[key])
				);
				availableSObjectSO.forEach(
					(so) =>
						(so.label = replaceMap[so.value] ? replaceMap[so.value] : so.label)
				);
				this.availableSObjectSO = availableSObjectSO;
				this.setPredefineConfigByOrgType();
			})
			.catch((e) =>
				_parseServerError(
					"Init Wizard : Get List of Available SObjects Error: ",
					e
				)
			);
	}

	/**
	 * List of fields of selected sObject
	 * @param sobjectType FF1__c as an example
	 */
	getListOfSObjectFields(sobjectType) {
		getSobjectFieldsServer({sobjectType})
			.then((sobjectFieldsSO) => {
				this.sobjectFieldsSO = sobjectFieldsSO;
				this.showFilter = true;
			})
			.catch((e) =>
				_parseServerError(
					"Init Wizard : Get List of Available SObjects Fields Error: ",
					e
				)
			);
	}

	/**
	 * The method gets the configuration record from the server
	 * @param type ("accounts", "divisions", "periods")
	 */
	getRegularMapping(type) {
		getRegularMappingServer({type})
			.then((mapping) => {
				this.mapping = mapping;
				this.mapping.cblight__SourceName__c = this.mapping.cblight__SourceName__c ? this.mapping.cblight__SourceName__c : "Name";
				if (!_isInvalid(this.mapping.cblight__SourceSObject__c)) {
					this.showFilter = true;
					this.getListOfSObjectFields(this.mapping.cblight__SourceSObject__c);
				}
			})
			.catch((e) =>
				_parseServerError("Init Wizard : Get Regular Mapping Error: ", e)
			)
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * Method validate and save the current step mapping
	 */
	saveMapping(callback) {
		const mapping = this.mapping;
		switch (this.currentStep) {
			case "accounts":
				if (
					_isInvalid(mapping.cblight__SourceName__c) ||
					_isInvalid(mapping.cblight__SourceType__c) ||
					_isInvalid(mapping.cblight__SourceSubtype__c)
				) {
					_message("info", "Specify Name, type and subtype");
					return;
				}
			default:
				if (_isInvalid(mapping.cblight__SourceName__c)) {
					_message("info", "Specify sObject Name");
					return;
				}
		}
		saveMappingServer({mapping})
			.then((mapping) => {
				this.mapping = mapping;
				if (!_isInvalid(callback)) {
					callback.bind(this)();
				}
			})
			.catch((e) => _parseServerError("Init Wizard : Save Mapping Error: ", e));
	}

	/**
	 * the main source object filter changed
	 */
	setSourceFilterString(event) {
		try {
			let mappingCopy = JSON.parse(JSON.stringify(this.mapping));
			mappingCopy.cblight__SourceFilter__c = event.detail.result;
			this.mapping = mappingCopy;
		} catch (e) {
			_message("error", "Init Wizard: Set Filter Source Error: " + e);
		}
	}

	setSpecialFilterString(event) {
		this.mapping.cblight__SpecialFilter__c = event.detail.result;
	}

	/**
	 * The method runs process of mapping of configured analytics
	 */
	runMappingProcess() {
		try {
			const mapping = this.mapping;
			this.showSpinner = true;
			runMappingServer({mapping})
				.then(() => {
					this.showSpinner = false;
					this.savedAndSyncMessage();
				})
				.catch((e) =>
					_parseServerError("Init Wizard : Map Analytics Callback Error: ", e)
				)
				.finally(() => (this.showSpinner = false));
		} catch (e) {
			_message("error", "Init Wizard : Map Divisions Error: " + e);
		}
	}

	///////////////// COMMON METHODS /////////////////////////

	///////////////// PREDEFINE CONFIGURATOR /////////////////
	/**
	 * This method save predefine data to BD
	 */
	savePredefineConfiguration() {
		if (
			!confirm(`Do you want to apply "${this.selectedConfiguration}" config?`)
		) {
			return null;
		}
		try {
			const configsList = ORGS_CONFIGS_MAP[this.selectedConfiguration];
			saveConfigurationsServer({configsList})
				.then(() => {
					this.initSelectedStep();
				})
				.catch((e) =>
					_parseServerError(
						"Init Wizard : Apply Configuration Callback Error: ",
						e
					)
				);
		} catch (e) {
			_message("error", "Init Wizard : Apply Configuration Error: " + e);
		}
	}

	///////////////// PREDEFINE CONFIGURATOR /////////////////

	///////////////// STEP SWITCHERS //////////////////////////
	/*
	 * Next step handler
	 */
	nextStep() {
		try {
			let setNextStep = false;
			let nextStep;
			this.showFilter = false;
			const stepRenderCopy = JSON.parse(JSON.stringify(this.stepRender));
			this.stepOrder.forEach((key) => {
				stepRenderCopy[key] = false;
				if (setNextStep) {
					nextStep = key;
					stepRenderCopy[key] = true;
					setNextStep = false;
				}
				if (key === this.currentStep) setNextStep = true;
			});
			this.stepRender = stepRenderCopy;
			this.currentStep = nextStep;
			this.initSelectedStep();
		} catch (e) {
			_message("error", "Init Wizard : Next Step Error : " + e);
		}
	}

	/*
	 * Previous step handler
	 */
	previousStep() {
		try {
			if (this.stepOrder[0] === this.currentStep) return;
			let setPreviousStep = false;
			let previousStep,
				skip = false;
			this.showFilter = false;
			const stepRenderCopy = JSON.parse(JSON.stringify(this.stepRender));
			this.stepOrder.forEach((key) => {
				if (skip) return;
				stepRenderCopy[key] = false;
				if (key === this.currentStep) setPreviousStep = true;
				if (setPreviousStep) {
					skip = true;
					stepRenderCopy[previousStep] = true;
					this.currentStep = previousStep;
				}
				previousStep = key;
			});
			this.stepRender = stepRenderCopy;
			this.initSelectedStep();
		} catch (e) {
			_message("error", "Init Wizard : Previous Step Error : " + e);
		}
	}

	/**
	 * Status string handler
	 * @param event
	 */
	setStep(event) {
		this.showFilter = false;
		this.currentStep = event.target.value;
		this.initSelectedStep();
		const stepRenderCopy = JSON.parse(JSON.stringify(this.stepRender));
		Object.keys(stepRenderCopy).forEach((st) => {
			stepRenderCopy[st] = st === this.currentStep;
		});
		this.stepRender = stepRenderCopy;
	}

	/**
	 * The method runs WelcomeMap
	 */

	openWelcome() {
		this.showWelcomeMat = true;
	}

	closeWelcome() {
		this.showWelcomeMat = false;
	}

	/**
	 * The method runs initial method when step was changed
	 */
	initSelectedStep() {
		this.mapping = {};
		switch (this.currentStep) {
			case "accounts":
				this.initAccounts();
				break;
			case "divisions":
				this.initDivisions();
				break;
			case "periods":
				this.initPeriods();
				break;
			case "variables1":
				this.initVariable(1);
				break;
			case "variables2":
				this.initVariable(2);
				break;
			case "variables3":
				this.initVariable(3);
				break;
			case "variables4":
				this.initVariable(4);
				break;
			case "variables5":
				this.initVariable(5);
				break;
			default:
				console.log(`Sorry, you missed`);
		}
	}

	///////////////// STEP SWITCHERS //////////////////////////

	////////////////   STEP ACCOUNTS ////////////
	@track
	selectedAccount;
	@track
	accountSubtypeField;
	@track
	accountTypeField;
	@track
	showAccountFields = false;

	/**
	 * The method starts when the "Accounts" step was selected
	 */
	initAccounts() {
		this.getRegularMapping("accounts");
		this.showSpinner = true;
	}

	/**
	 * Account source sObject was changed
	 */
	handleAccountChange(event) {
		this.mapping.cblight__SourceSObject__c = event.target.value;
		this.getListOfSObjectFields(this.mapping.cblight__SourceSObject__c);
		this.showAccountFields = true;
	}

	/**
	 * Account type of account subtype was changed
	 */
	handleAccountTypeChange(event) {
		switch (event.target.name) {
			case "accountSubType":
				this.mapping.cblight__SourceSubtype__c = event.target.value;
				break;
			case "accountName":
				this.mapping.cblight__SourceName__c = event.target.value;
				break;
			default:
				this.mapping.cblight__SourceType__c = event.target.value;
				break;
		}
	}

	/**
	 * The method maps account analytics
	 */
	saveAndRunMapAccounts() {
		this.saveMapping(this.runMappingProcess);
	}

	////////////////   STEP ACCOUNTS ////////////

	////////////////   STEP DIVISIONS ////////////
	@track
	selectedDivision;
	@track
	showDivisionFields = false;

	handleDivisionChange(event) {
		switch (event.target.name) {
			case "divisionName":
				this.mapping.cblight__SourceName__c = event.target.value;
				break;
			default:
				this.mapping.cblight__SourceSObject__c = event.target.value;
				this.getListOfSObjectFields(this.mapping.cblight__SourceSObject__c);
				this.showDivisionFields = true;
				break;
		}
	}

	/**
	 * The method starts when the "Divisions" step was selected
	 */
	initDivisions() {
		this.getRegularMapping("divisions");
		this.showSpinner = true;
	}

	saveAndRunMapDivisions() {
		this.saveMapping(this.runMappingProcess);
	}

	////////////////   STEP DIVISIONS ////////////

	////////////////   STEP PERIODS ////////////
	@track
	selectedPeriod;
	@track
	showPeriodFields = false;
	showPeriodDialog = false;

	handlePeriodChange(event) {
		const field = event.target.name;
		this.mapping[field] = event.target.value;
		if (field === "cblight__SourceSObject__c") {
			this.getListOfSObjectFields(this.mapping.cblight__SourceSObject__c);
		}
	}

	/**
	 * The method starts when the "Periods" step was selected
	 */
	initPeriods() {
		this.getRegularMapping("periods");
		this.showSpinner = true;
	}

	/**
	 * Method saves setup for periods and run mappings
	 */
	saveAndRunMapPeriods() {
		const mapping = this.mapping;
		if (!mapping.cblight__SourceName__c || !mapping.cblight__SourceType__c) {
			_message("info", "Please specify Name Field and Start Data Field");
			return;
		}
		this.saveMapping(this.runMappingProcess);
	}

	// Toggle period Dialog
	togglePeriodsSetupDialog() {
		this.showPeriodDialog = !this.showPeriodDialog;
	}

	////////////////   STEP DIVISIONS ////////////

	////////////////   STEP VARIABLE 1 ////////////
	@track
	selectedSource1;

	handleVariableChange(event) {
		const field = event.target.dataset.id;
		this.mapping[field] = event.target.value;
		if (field === "cblight__SourceSObject__c") {
			this.getListOfSObjectFields(this.mapping.cblight__SourceSObject__c);
		}
	}

	/**
	 * The method starts when the "Divisions" step was selected
	 */
	initVariable(idx) {
		this.getRegularMapping(`variables${idx}`);
		this.showSpinner = true;
	}

	saveAndRunMapVariable() {
		if (_isInvalid(this.mapping.cblight__SourceName__c)) {
			_message("info", "Specify sObject Name");
			return;
		}
		this.saveMapping(this.runMappingProcess);
	}

	////////////////   STEP VARIABLE 1 ////////////

	////////////////    INIT WIZARD REPORT ///////
	renderInitWizardReport() {
		this.showInitWizardReport = true;
	}

	closeInitWizardReport = () => {
		this.showInitWizardReport = false;
	};

	////////////////    INIT WIZARD REPORT ///////

	/////////////// MESSAGES /////////////////////////
	savedAndSyncMessage() {
		const event = new ShowToastEvent({
			title: "Success",
			message: "Saved and Synchronized",
			variant: "success",
		});
		this.dispatchEvent(event);
	}

	/////////////// MESSAGES /////////////////////////
}