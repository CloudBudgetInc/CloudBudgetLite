import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getModelingRuleGroupsByFolderIdServer from "@salesforce/apex/CBModelingRulePageController.getModelingRuleGroupsByFolderIdServer";
import saveModelingRuleGroupServer from "@salesforce/apex/CBModelingRulePageController.saveModelingRuleGroupServer";
import deleteModelingRuleServer from "@salesforce/apex/CBModelingRulePageController.deleteModelingRuleServer";
import deleteModelingRuleGroupServer from "@salesforce/apex/CBModelingRulePageController.deleteModelingRuleGroupServer";
import deleteOldDataServer from "@salesforce/apex/CBModelingRulePageController.deleteOldDataServer";
import recalculateDataServer from "@salesforce/apex/CBModelingRulePageController.recalculateDataServer";
import getFullMRGStructureServer from "@salesforce/apex/CBModelingRulePageController.getFullMRGStructureServer";
import applyMRGStructureServer from "@salesforce/apex/CBModelingRulePageController.applyMRGStructureServer";
import { _deleteFakeId, _generateFakeId, _getCopy, _isInvalid, _message, _parseServerError, _cl } from "c/cbUtils";
import CB_MRG_OBJECT from "@salesforce/schema/CBModelingRuleGroup__c";
import FOLDER_FIELD from "@salesforce/schema/CBModelingRuleGroup__c.CBFolder__c";

export default class CbModelingRule extends LightningElement {
	modelingRuleGroupApiName = CB_MRG_OBJECT;
	folderField = FOLDER_FIELD;

	@track showSpinner = false;
	@track showModalWindow = false;
	@track modelingRuleGroups;
	@track modelingRuleGroup;
	@track selectedModelingRuleId;
	@track availableSObjects = []; // data for child component
	@track showModelingRuleGroupSetup = false;
	@track showMRGCloneButton = true;
	@track error;
	@track mrJSON;
	selectedFolder;

	constructor() {
		super();
		this.addEventListener("closeModelingRule", this.closeModelingRule);
		this.addEventListener("updateListOfModelingRules", this.doInit);
		this.addEventListener("closeWelcome", this.closeWelcome);
	}

	connectedCallback() {
		document.title = "Modeling Rules";
	}
	////////// FOLDERS ////////////
	handleSelectedFolder(event) {
		const selectedFolder = event.detail.selected;
		this.selectedFolder = selectedFolder;
		this.doInit();
	}
	////////// FOLDERS ////////////

	doInit = () => {
		this.getFolderModelingRuleGroups();
	}

	getFolderModelingRuleGroups = () => {
		this.showSpinner = true;
		getModelingRuleGroupsByFolderIdServer({ folderId: this.selectedFolder })
			.then((modelingRuleGroups) => {
				try {
					if (modelingRuleGroups) {
						this.processMRGTitlesAndApply(modelingRuleGroups);
					}
				} catch (e) {
					_message("error", "MR : getModelingRuleGroupsByFolderIdServer callback ERROR: " + e);
				}
			})
			.catch((e) => _parseServerError("Get All Modeling Rule Groups Error: ", e))
			.finally(() => {
				this.showSpinner = false;
			});
	};

	processMRGTitlesAndApply(modelingRuleGroups) {
		modelingRuleGroups.forEach((mrg, i) => {
			mrg.title = `MRG ${i + 1} : ${mrg.Name}`;
			if (mrg.cblight__CBModelingRules__r) {
				mrg.cblight__CBModelingRules__r.forEach((mr, j) => {
					mr.title = `MR ${i + 1}.${j + 1} : ${mr.Name}`
				});
			}
		});
		this.modelingRuleGroups = modelingRuleGroups;
	}

	addModelingRuleGroup() {
		this.showMRGCloneButton = false;
		this.modelingRuleGroup = { Name: "New Modeling Rule Group", Id: _generateFakeId() };
		if (!_isInvalid(this.selectedFolder)) {
			this.modelingRuleGroup.cblight__CBFolder__c = this.selectedFolder;
		}
	}

	addModelingRule(event) {
		try {
			const groupId = event.target.value;
			const group = this.modelingRuleGroups.find((gr) => gr.Id === groupId);
			let MRList = group.cblight__CBModelingRules__r;
			if (_isInvalid(MRList)) MRList = [];
			const newMR = {
				cblight__CBModelingRuleGroup__c: groupId,
				Id: _generateFakeId(),
				Name: "New PR",
				cblight__CBModelingLines__r: [],
				cblight__Description__c: "",
				cblight__ResultRecordParentType__c: "cblight__CBCube__c",
				cblight__ResultChildFilter__c: "",
				cblight__ResultParentFilter__c: "",
				cblight__SourceChildFilter__c: "",
				cblight__SourceParentFilter__c: "",
				cblight__Mode__c: "General",
				cblight__SourceRecordParentType__c: "cblight__CBBudgetLine__c"
			};
			MRList.push(newMR);
			group.cblight__CBModelingRules__r = MRList;
			this.showModalWindow = true;

			setTimeout(() => {
				const MRDialogComponent = this.template.querySelector("c-cb-modeling-rule-dialog");
				MRDialogComponent.saveModelingRuleFromParentComponent(newMR);
			}, 100);
		} catch (e) {
			_message("error", "Add Modeling Rule Error: " + e);
		}
	}

	openModelingRule(event) {
		this.selectedModelingRuleId = event.target.value;
		this.showModalWindow = true;
	}

	/**
	 * The method deletes the modeling rule from the mr group
	 */
	deleteModelingRule(event) {
		if (!confirm("Are you sure?")) return;
		this.showSpinner = true;
		const mrId = event.target.value;
		deleteModelingRuleServer({ mrId })
			.then(() => {
				this.deletedMessage();
				this.doInit();
			})
			.catch((e) => _parseServerError(" MRG : Delete Modeling Rule Server Error: ", e))
			.finally(() => (this.showSpinner = true));
	}

	closeModelingRule = () => {
		this.showModalWindow = false;
		this.selectedModelingRuleId = null;
	};

	editModelingRuleGroup(event) {
		try {
			this.mrJSON = undefined;
			this.showModelingRuleGroupSetup = true;
			this.showMRGCloneButton = true;
			this.modelingRuleGroup = this.modelingRuleGroups.find((gr) => gr.Id === event.target.value);
			if (_isInvalid(this.modelingRuleGroup)) {
				this.addModelingRuleGroup();
			} else {
				this.doInit();
			}
		} catch (e) {
			_message("error", "Edit Modeling Rule Group Error: " + e);
		}
	}

	/**
	 * The method deletes whole group of modeling rules
	 */
	deleteModelingRuleGroup(event) {
		if (!confirm("Are you sure? All related modeling rules will be deleted")) return;
		this.showSpinner = true;
		const mrgId = event.target.value;
		this.modelingRuleGroups = this.modelingRuleGroups.filter((item) => item.Id !== mrgId);
		deleteModelingRuleGroupServer({ mrgId })
			.then(() => {
				this.deletedMessage();
				this.doInit();
			})
			.catch((e) => _parseServerError("MRG : Delete Modeling Rule Group Server Error: ", e))
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * Handler for MRG dialog window
	 */
	handleModelingRuleGroupSetup(event) {
		let mrg = _getCopy(this.modelingRuleGroup);
		mrg[event.target.name] = ["cblight__DeleteOldResults__c", "cblight__StoreDrillDown__c"].includes(event.target.name) ? event.target.checked : event.target.value;
		this.modelingRuleGroup = mrg;
	}

	saveAndCloseModelingRuleGroup() {
		this.showSpinner = true;
		this.showModelingRuleGroupSetup = false;
		const modelingRuleGroup = this.modelingRuleGroup;
		_deleteFakeId(modelingRuleGroup);
		saveModelingRuleGroupServer({ modelingRuleGroup })
			.then(() => {
				_message("Success", "Saved");
				this.doInit();
			})
			.catch((e) => _parseServerError("MRG : Save And Close Modeling Rule Group Error:", e));
	}

	closeModelingRuleGroup() {
		this.showModelingRuleGroupSetup = false;
	}

	///////// PROCESSES /////////////////
	/**
	 * Method deletes previously generated data
	 */
	deleteModelingRuleGroupData(event) {
		this.showSpinner = true;
		deleteOldDataServer({ mrgId: event.target.value })
			.then(() => this.inProgressMessage())
			.catch((e) => _parseServerError("MRG : Delete Data Error ", e))
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * Method runs jobs to recalculate modeling rules in the group
	 */
	recalculateModelingRuleGroupData(event) {
		this.showSpinner = true;
		recalculateDataServer({ mrgId: event.target.value })
			.then(() => this.inProgressMessage())
			.catch((e) => _message("error", "MRG : Recalculate Modeling Rule Group Data Error: " + e))
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * this function gets selected Modeling rule group and all related rules and lines in form of a map to show them as a JSON block
	 */
	async getJSON() {
		if (this.modelingRuleGroup.Id.includes('fake')) {
			_message('warning', 'Save modeling rule group first');
			return;
		}
		this.showSpinner = true;
		const mrgStructure = await getFullMRGStructureServer({ mrgId: this.modelingRuleGroup.Id }).catch((e) => {
			_parseServerError("MRG : Get JSON Error: " + e);
		});
		this.mrJSON = JSON.stringify(mrgStructure);
		this.showSpinner = false;
	}

	/**
	 * this function applies modeling rule group in form of a JSON block creating new MRG with "Cloned" added to the start name
	 */
	setJSON() {
		if (!this.mrJSON) {
			this.mrJSON = 'Set a JSON string and press "Apply JSON" ("Magic Wand" button) again';
			return;
		}
		if (!confirm("Are you sure?")) return;
		this.showSpinner = true;
		let mrgMap = JSON.parse(this.mrJSON);
		const modelingRuleGroup = this.modelingRuleGroup;
		_deleteFakeId(modelingRuleGroup);
		mrgMap.mrg.Id = modelingRuleGroup.Id;
		applyMRGStructureServer({mrg: mrgMap.mrg, mrList: mrgMap.mrList, mlMap: mrgMap.mlMap})
			.then(() => {
				this.closeModelingRuleGroup();
				this.doInit();
			})
			.catch((e) => _message("error", "MRG : Set JSON Error: " + e))
			.finally(() => (this.showSpinner = false));
	}

	/**
	 * this function clones selected MRG using JSON functionality from two functions above
	 */
	async cloneRule() {
		if (!confirm("Are you sure?")) return;
		this.showSpinner = true;
		let mrgMap = await getFullMRGStructureServer({mrgId: this.modelingRuleGroup.Id})
		.catch(e => _parseServerError('MRG : Get Full MRG Structure Server Error: ', e));
		delete mrgMap.mrg.Id;
		const clonedMRGId = await applyMRGStructureServer({
			mrg: mrgMap.mrg,
			mrList: mrgMap.mrList,
			mlMap: mrgMap.mlMap
		}).catch((e) => {
			_parseServerError('MRG : Apply MRG Structure Server Error: ', e);
			console.error(e);
		});
		let modelingRuleGroups = await getModelingRuleGroupsByFolderIdServer({ folderId: this.selectedFolder })
		.catch(e => _parseServerError('MRG : Get ModelingRule Groups By Folder Id Server Error ', e));
		this.processMRGTitlesAndApply(modelingRuleGroups);
		this.mrJSON = undefined;
		this.modelingRuleGroup = this.modelingRuleGroups.find(gr => gr.Id === clonedMRGId);
		this.showSpinner = false;
	}

	handleJSONString(event) {
		this.mrJSON = event.target.value;
	}

	handleChangeMRGFolder(event) {
		_cl('handleChangeMRGFolder event.target.value: ' + event.target.value);
		this.modelingRuleGroup.cblight__CBFolder__c = event.target.value;
	}

	///////// PROCESSES /////////////////

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

	inProgressMessage() {
		const event = new ShowToastEvent({
			title: "Success",
			message: "Process started",
			variant: "success"
		});
		this.dispatchEvent(event);
	}

	//////// MESSAGES ///////////

	////////  WELCOME ///////////
	@track showWelcomeMat = false;

	showWelcome = () => {
		this.showWelcomeMat = true;
	};

	closeWelcome = () => {
		this.showWelcomeMat = false;
	};

	////////  WELCOME ///////////
}