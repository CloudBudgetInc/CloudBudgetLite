import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSelectedModelingRuleServer from "@salesforce/apex/CBModelingRulePageController.getSelectedModelingRuleServer";
import saveModelingRuleServer from "@salesforce/apex/CBModelingRulePageController.saveModelingRuleServer";
import getRecordNumberServer from "@salesforce/apex/CBModelingRulePageController.getRecordNumberServer";
import checkCBKeyFieldOfParentRecordsServer from "@salesforce/apex/CBModelingRulePageController.checkCBKeyFieldOfParentRecordsServer";
import getUsersAndQueuesServer from "@salesforce/apex/CBModelingRulePageController.getUsersAndQueuesServer";
import getGlobalModelingLinesServer from "@salesforce/apex/CBModelingRulePageController.getGlobalModelingLinesServer";
import createPredefinedModelingLinesServer from "@salesforce/apex/CBModelingRulePageController.createPredefinedModelingLinesServer";
import deleteModelingRuleLineServer from "@salesforce/apex/CBModelingRulePageController.deleteModelingRuleLineServer";
import getSourceParentAndChildSObjectFieldsServer from "@salesforce/apex/CBModelingRulePageController.getSourceParentAndChildSObjectFieldsServer";
import { _cl, _deleteFakeId, _generateFakeId, _getCopy, _isInvalid, _message, _parseServerError } from "c/cbUtils";

export default class CbModelingRuleDialog extends LightningElement {
	relationSO = [
		{ label: "Equal", value: "=" },
		{ label: "Not equal", value: "!=" },
		{ label: "More", value: ">" },
		{ label: "Less", value: "<" },
		{ label: "Equal Or Less", value: ">=" },
		{ label: "Equal Or More", value: "<=" },
		{ label: "Contains", value: "contains" },
		{ label: "Start With", value: "starts" },
		{ label: "End With", value: "ends" }
	];
	lookupRelationSO = [
		{ label: "Equal", value: "=" },
		{ label: "Not equal", value: "!=" }
	];
	radioSO = [
		{ label: "AND", value: "AND" },
		{ label: "OR", value: "OR" },
		{ label: "CUSTOM", value: "CUSTOM" }
	];
	dialogFields = [
		"Name",
		"cblight__SourceRecordParentType__c",
		"cblight__SourceRecordChildType__c",
		"cblight__ResultRecordParentType__c",
		"cblight__ResultRecordChildType__c",
		"cblight__Description__c",
		"cblight__KeyFields__c",
		"cblight__PeriodShift__c",
		"cblight__Mode__c"
	];
	modelingRuleModes = [
		{label:"General", value:"General"},
		{label:"Deleting", value:"Deleting"},
		{label:"Replacing", value:"Replacing"},
		{label:"Zeroing Amounts", value:"Zeroing Amounts"},
		{label:"Mass Update", value:"Mass Update"}
	];

	@track showSpinner = false;
	@track modelingRule = {};
	@track mrId;
	@track fieldMap = {};
	@track usersAndQueues = [];
	@track linesReadyToDisplay = false;
	@track sourceParentFieldSO = [];
	@track sourceChildFieldSO = [];
	@track parentRadioOption = "AND";
	@track customParentCondition = "";
	@track renderParentFilter = false;
	@track renderParentComplexCondition = false;
	@track showContent = false;
	@track showAddGenerateButtons = true;
	@track sourceParentFilterTitle = "Source Parent Filter";
	@track sourceChildFilterTitle = "Source Child Filter";
	@track resultParentFilterTitle = "Result Parent Filter";
	@track resultChildFilterTitle = "Result Child Filter";
	@track availableSourceChildSobjects;
	@track availableResultChildSobjects;
	@track lineSize = 0;

	/* DISPLAY BOOLEANS */
	@track displaySourceChildFilter = false;
	@track displayResultChildFilter = false;
	@track displayResultFields = false;
	@track displayResultFilters = true;
	@track column1Wide = 3;
	@track column2Wide = 3;
	@track column3Wide = 3;
	@track column4Wide = 3;
	/* DISPLAY BOOLEANS */
	/**
	 * list of available Sobjects taken from the parent Modeling Rule component
	 */
	@api availableSobjects;

	/**
	 * Selected Modeling Rule Id from parent component
	 */
	@api
	get modelingRuleId() {
		return this.mrId;
	}

	set modelingRuleId(value) {
		this.mrId = value;
		this.getSourceParentAndChildSObjectFields(true);
		this.getUsersAndQueues();
	}

	constructor() {
		super();
		this.addEventListener("passModelingRuleLine", this.passModelingRuleLine);
		this.addEventListener("deleteModelingRuleLine", this.deleteModelingRuleLine);
	}

	/**
	 * Get current modeling rule for the dialog window
	 */
	getModelingRule() {
		this.showSpinner = true;
		const modelingRuleId = this.mrId;
		if (_isInvalid(modelingRuleId)) return;
		getSelectedModelingRuleServer({ modelingRuleId })
			.then((mr) => {
				this.modelingRule = mr;
				this.showContent = true;
				this.linesReadyToDisplay = true;
				this.displaySourceChildFilter = !_isInvalid(this.modelingRule.cblight__SourceRecordChildType__c);
				this.displayResultChildFilter = !_isInvalid(this.modelingRule.cblight__ResultRecordChildType__c);
				this.indexModelingRuleLines();
				this.initModeRendering();
			})
			.catch((e) => _parseServerError("MRD : Get Modeling Rule Error: ", e))
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * This data will be passed to modeling lines
	 */
	getSourceParentAndChildSObjectFields(updateModelingRule) {
		this.showSpinner = true;
		const modelingRuleId = this.mrId;
		if (!modelingRuleId) return;
		getSourceParentAndChildSObjectFieldsServer({ modelingRuleId })
			.then((result) => {
				try {
					Object.values(result).forEach((list) => {
						list.forEach((item) => {
							item.label = item.label + " (" + item.type + ")";
						});
					});
					this.fieldMap = result;
					this.sourceParentFieldSO = this.fieldMap.sourceParentFieldSO;
					this.sourceChildFieldSO = this.fieldMap.sourceChildFieldSO;
					if (updateModelingRule) {
						this.getModelingRule();
					} else {
						this.showSpinner = false;
					}
				} catch (e) {
					_message("error", "MRD : Get Source Parent And Child SObject Fields Callback Error " + e);
				}
			})
			.catch((e) => {
				this.showSpinner = false;
				_parseServerError("MRD : Get Source Parent And Child SObject Fields Error : ", e);
			});
	}

	/**
	 * List of SO with users and queues for the filter component
	 */
	getUsersAndQueues() {
		getUsersAndQueuesServer()
			.then((usersAndQueues) => (this.usersAndQueues = usersAndQueues))
			.catch((e) => _parseServerError("MRD : Get Users And Queues Error: ", e));
	}

	/**
	 * External method used by parent component to save new MR
	 */
	@api
	saveModelingRuleFromParentComponent(modelingRule) {
		this.showContent = false;
		this.showSpinner = true;
		_deleteFakeId(modelingRule);
		this.modelingRule = modelingRule;
		saveModelingRuleServer({ modelingRule })
			.then((result) => {
				this.modelingRule.Id = result;
				this.mrId = result;
				getSourceParentAndChildSObjectFieldsServer({ modelingRuleId: this.modelingRule.Id })
					.then((result) => {
						this.fieldMap = result;
						this.sourceParentFieldSO = this.fieldMap.sourceParentFieldSO;
						this.sourceChildFieldSO = this.fieldMap.sourceChildFieldSO;
						this.getModelingRule();
					})
					.catch((e) => {
						this.showSpinner = false;
						_message("error", "MRD : Get Source Parent And Child SObject Fields Error: " + e);
					});
				this.updateListOfModelingRules();
			})
			.catch((e) => {
				this.showSpinner = false;
				_parseServerError("MRD : Save From The Parent Modeling Rule Error: ", e);
			});
	}

	/**
	 * Method checks if all parent sObject of Modeling rule have the CBKey__c field
	 */
	checkCBKeyFieldOfParentRecords = () => {
		const parentNames = [this.modelingRule.cblight__SourceRecordParentType__c, this.modelingRule.cblight__ResultRecordParentType__c];
		checkCBKeyFieldOfParentRecordsServer({ parentNames }).then((warning) => {
			if (warning) {
				_message("warning", warning);
			}
		});
	};

	/**
	 * The opened modeling rule saving. Data from modeling lines is actual due to events from lines
	 */
	saveModelingRule() {
		try {
			const modelingRule = this.modelingRule;
			const modelingLines = this.modelingRule.cblight__CBModelingLines__r;
			if ((modelingRule.cblight__Mode__c === 'General' || modelingRule.cblight__Mode__c === 'Replacing') && !modelingRule.cblight__ResultRecordParentType__c) {
				_message('error', 'Saving is impossible, select Result parent first');
				return;
			}
			this.showSpinner = true;
			this.showContent = false;
			this.checkCBKeyFieldOfParentRecords();
			if (_isInvalid(modelingRule.cblight__KeyFields__c) && (modelingRule.cblight__Mode__c === 'General' || modelingRule.cblight__Mode__c === 'Replacing')) {
				if (!confirm('Modeling Rule does not have any keys specified, do you want to save it anyway?')) {
					this.showSpinner = false;
					this.showContent = true;
					return;
				}
			}

			_deleteFakeId(modelingRule);
			if (modelingLines && modelingLines.length > 0) {
				_deleteFakeId(modelingLines);
				modelingLines.forEach((line) => {
					delete line.index;
				});
			}
			saveModelingRuleServer({ modelingRule, modelingLines })
				.then((mrId) => {
					this.savedMessage();
					this.mrId = mrId;
					this.getSourceParentAndChildSObjectFields(true);
					this.updateListOfModelingRules();
				})
				.catch((e) => {
					this.showSpinner = false;
					_parseServerError("MRD : Save Modeling Rule Error: ", e);
				});
		} catch (e) {
			_message("error", "MRD : Saving Error " + e);
		}
	}

	/**
	 *
	 * this function starts MR key generation
	 */
	generateKeysButton() {
		if (!confirm("Are you sure you want to replace keys with automatically generated ones?")) {
			return;
		}
		const modelingRule = this.modelingRule;
		const modelingLines = this.modelingRule.cblight__CBModelingLines__r;
		this.generateKeyFields(modelingRule, modelingLines);
		this.modelingRule = modelingRule;
	}

	/**
	 *
	 * @param {*} event evetn from keys manager
	 */
	handleKeysChanged(event) {
		const selectedKeys = event.detail.keys;
		const modelingRuleCopy = _getCopy(this.modelingRule);
		modelingRuleCopy.cblight__KeyFields__c = selectedKeys;
		this.modelingRule = modelingRuleCopy;
	}

	/**
	 * The method generates modeling rule key fields from parent lookups
	 * @param modelingRule
	 * @param modelingLines
	 * @returns something like 'cblight__CBAccount__c,cblight__CBBudgetYear__c,cblight__CBDivision__c,cblight__CBPeriod__c'
	 */
	generateKeyFields(modelingRule, modelingLines) {
		if (!modelingLines) return null;
		const keyFields = [],
			IGNORED_FIELDS = ["cblight__CBStyle__c"];
		modelingLines.forEach((line) => {
			if (line.Name === "Period") {
				return;
			}
			if (line.cblight__SourceFieldFrom__c === "Parent" && line.cblight__Type__c === "REFERENCE" && !IGNORED_FIELDS.includes(line.cblight__ResultField__c)) {
				keyFields.push(line.cblight__ResultField__c);
			}
		});
		modelingRule.cblight__KeyFields__c = keyFields.join(",");
	}

	/**
	 * Method counts a number of source records for current modeling rule
	 */
	getNumberOfSourceParentRecords() {
		this.showSpinner = true;
		const mrId = this.modelingRule.Id;
		if (!mrId) {
			_message("warning", "Please save the Modeling Rule first");
			return null;
		}
		getRecordNumberServer({ mrId })
			.then((recordNumber) => _message("info", `Number of source records: ${recordNumber}`))
			.catch((e) => _parseServerError("MRD : Get Number Of Parent Records Error: ", e))
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * The method generates list of modeling rule lines from global lines
	 */
	async createPredefinedModelingLines() {
		if (!confirm('Are you sure?')) {
			return;
		}
		await createPredefinedModelingLinesServer({ modelingRuleId: this.modelingRuleId }).catch((e) => {
			_parseServerError("MRD : Create Predefined Modeling Lines Error: ", e);
		});
		_message('warning', 'Modeling Lines may lack precision, so it is advisable to thoroughly verify the newly generated lines.');
		this.getModelingRule();
	}

	passModelingRuleLine = (event) => {
		let line = event.detail;
		let lineList = [];
		this.modelingRule.cblight__CBModelingLines__r.forEach((l) => (l.Id === line.Id ? lineList.push(line) : lineList.push(l)));
		const modelingRuleCopy = _getCopy(this.modelingRule);
		modelingRuleCopy.cblight__CBModelingLines__r = lineList;
		this.modelingRule = modelingRuleCopy;
		lineList.forEach((line) => _cl(`Updated Line: ${JSON.stringify(line)}`, "yellow"));
	};

	indexModelingRuleLines() {
		if (_isInvalid(this.modelingRule.cblight__CBModelingLines__r) || this.modelingRule.cblight__CBModelingLines__r.length < 1) return;
		let modelingRuleCopy = _getCopy(this.modelingRule);
		modelingRuleCopy.cblight__CBModelingLines__r.forEach((line, idx) => (line.index = ++idx));
		this.modelingRule = modelingRuleCopy;
	}

	deleteModelingRuleLine = (event) => {
		this.showSpinner = true;
		this.showContent = false;
		const mrLineId = event.detail;
		const callback = () => {
			this.deletedMessage();
			this.showSpinner = false;
			this.showContent = true;
			this.indexModelingRuleLines();
		};
		const modelingRuleCopy = JSON.parse(JSON.stringify(this.modelingRule));
		modelingRuleCopy.cblight__CBModelingLines__r = modelingRuleCopy.cblight__CBModelingLines__r.filter((l) => l.Id !== mrLineId);
		this.modelingRule = modelingRuleCopy;
		if (mrLineId.includes("fake")) {
			callback();
		} else {
			deleteModelingRuleLineServer({ mrLineId })
				.catch((e) => _parseServerError("MRD : Delete Modeling Rule Line Error: ", e))
				.finally(() => callback());
		}
	};

	/**
	 * The method adds a new modeling rule line in dialog window
	 */
	addModelingLine() {
		try {
			let clonedMR = JSON.parse(JSON.stringify(this.modelingRule));
			if (!clonedMR.cblight__CBModelingLines__r) {
				clonedMR.cblight__CBModelingLines__r = [];
			}
			const newLine = {
				Id: _generateFakeId(),
				Name: "Name",
				cblight__Type__c: "STRING",
				cblight__ResultFieldFrom__c: "Parent",
				cblight__ResultField__c: "Name",
				cblight__SourceFieldFrom__c: "Parent",
				cblight__SourceField__c: "Name"
			};
			clonedMR.cblight__CBModelingLines__r.push(newLine);
			this.modelingRule = clonedMR;
			this.indexModelingRuleLines();
		} catch (e) {
			_message("error", "MRD : Add New Modeling Rule Line Error: " + e);
		}
	}

	/**
	 * The method passes event to the parent component forcing to close the current modal window
	 */
	closeModalWindow() {
		this.dispatchEvent(new CustomEvent("closeModelingRule", { bubbles: true, composed: true }));
	}

	/**
	 * The method passes event to the parent component forcing to update list of modeling rules
	 */
	updateListOfModelingRules() {
		this.dispatchEvent(new CustomEvent("updateListOfModelingRules", { bubbles: true, composed: true }));
	}

	/**
	 * Handle of changing a modeling rule parameters
	 */
	handleModelingRuleChange(event) {
		try {
			let modelingRule = _getCopy(this.modelingRule),
				updateFieldMap = false;
			this.dialogFields.forEach((f) => {
				if (f.includes(event.target.name)) {
					modelingRule[f] = event.target.value;
					if (!["Name", "cblight__Description__c", "cblight__KeyFields__c", "cblight__Mode__c", "cblight__PeriodShift__c"].includes(event.target.name)) {
						updateFieldMap = true;
					}
					if ("cblight__SourceRecordParentType__c".includes(event.target.name)) {
						modelingRule.cblight__SourceRecordChildType__c = null;
					}
					if ("cblight__ResultRecordParentType__c".includes(event.target.name)) {
						modelingRule.cblight__ResultRecordChildType__c = null;
					}
				}
			});
			this.modelingRule = modelingRule;
			if (updateFieldMap) this.saveModelingRule();
			this.displaySourceChildFilter = !_isInvalid(this.modelingRule.cblight__SourceRecordChildType__c);
			this.displayResultChildFilter = !_isInvalid(this.modelingRule.cblight__ResultRecordChildType__c);
			this.initModeRendering();
		} catch (e) {
			_message("error", "MRD : Handle event ERROR: " + e);
		}
	}

	handleSobjectChange(event) {
		let falseEvent = { target: { name: event.detail.selectorName, value: event.detail.value } };
		this.handleModelingRuleChange(falseEvent);
	}

	/**
	 * The method for receiving the filter string from the filter components
	 * @param event from the filter component
	 */
	setNewFilterString(event) {
		if (event.detail.title === this.sourceParentFilterTitle) {
			this.modelingRule.cblight__SourceParentFilter__c = event.detail.result;
		} else if (event.detail.title === this.sourceChildFilterTitle) {
			this.modelingRule.cblight__SourceChildFilter__c = event.detail.result;
		} else if (event.detail.title === this.resultParentFilterTitle) {
			this.modelingRule.cblight__ResultParentFilter__c = event.detail.result;
		} else if (event.detail.title === this.resultChildFilterTitle) {
			this.modelingRule.cblight__ResultChildFilter__c = event.detail.result;
		}
	}

	initModeRendering() {
		switch (this.modelingRule.cblight__Mode__c) {
			case "General":
				this.displayResultFields = true;
				this.displayResultFilters = false;
				this.column2Wide = 6;
				this.showAddGenerateButtons = true;
				break;
			case "Deleting":
				this.displayResultFields = this.displayResultFilters = false;
				this.column2Wide = 9;
				this.modelingRule.cblight__ResultRecordParentType__c = null;
				this.modelingRule.cblight__ResultRecordChildType__c = null;
				this.showAddGenerateButtons = false;
				break;
			case "Replacing":
				if (!this.modelingRule.cblight__ResultRecordParentType__c) {
					_message('warning','Result filters will appear after selecting Result Parent');
					this.displayResultFields = true;
					this.displayResultFilters = false;
					this.column2Wide = 6;
				} else {
					this.displayResultFields = this.displayResultFilters = true;
					this.column2Wide = 3;
				}
				this.showAddGenerateButtons = true;
				break;
			case "Zeroing amounts":
				this.displayResultFields = this.displayResultFilters = false;
				this.column2Wide = 9;
				this.modelingRule.cblight__ResultRecordParentType__c = null;
				this.modelingRule.cblight__ResultRecordChildType__c = null;
				this.showAddGenerateButtons = false;
				break;
			case "Mass Update":
				this.displayResultFields = this.displayResultFilters = false;
				this.column2Wide = 9;
				break;
			default:
				this.displayResultFields = this.displayResultFilters = true;
				this.showAddGenerateButtons = true;
		}
	}

	//////// MESSAGES ///////////
	savedMessage() {
		const event = new ShowToastEvent({
			title: "Success",
			message: "Saved",
			variant: "success"
		});
		this.dispatchEvent(event);
	}

	deletedMessage() {
		const event = new ShowToastEvent({
			title: "Success",
			message: "Deleted",
			variant: "success"
		});
		this.dispatchEvent(event);
	}

	errorMessage(message) {
		const event = new ShowToastEvent({
			title: "Note!",
			message,
			variant: "warning"
		});
		this.dispatchEvent(event);
	}

	infoMessage(message) {
		const event = new ShowToastEvent({
			title: "Hint",
			message,
			variant: "info"
		});
		this.dispatchEvent(event);
	}

	//////// MESSAGES ///////////
}