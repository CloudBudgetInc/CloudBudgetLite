import {LightningElement, track} from "lwc";
import getCalculationRulesServer from "@salesforce/apex/CBCalculationRulePageController.getCalculationRulesServer";
import deleteCalculationRuleServer from "@salesforce/apex/CBCalculationRulePageController.deleteCalculationRuleServer";
import {_message, _parseServerError} from "c/cbUtils";

export default class CbCalculationRuleManager extends LightningElement {
	@track readyToRender = false;
	@track showSpinner = false;
	@track showDialog = false;
	@track selectedCR;
	@track calculationRules = [];
	selectedFolder;

	constructor() {
		super();
		this.addEventListener("closeDialog", this.closeDialog); // Listener from the budget line modal
	}

	connectedCallback() {
		document.title = "Calculation Rules";
		this.addEventListener('folderselected', this.handleSelectedFolder);
		//this.doInit();
	}

	/**
	 * this function is catching selected folder
	 * @param {*} event
	 */
	handleSelectedFolder(event) {
		const selectedFolderName = event.detail.selected;
		this.selectedFolder = selectedFolderName;
		this.doInit();
	}


	doInit() {
		this.getCalculationRules();
	}

	/**
	 * list of calculation rules
	 */
	getCalculationRules() {
		this.readyToRender = false;
		this.showSpinner = true;
		getCalculationRulesServer({folderId: this.selectedFolder})
			.then((calculationRules) => {
				calculationRules.forEach((cr, i) => (cr.title = `CR${i + 1} : ${cr.Name}`));
				this.calculationRules = calculationRules;
				this.readyToRender = true;
			})
			.catch((e) => _parseServerError("CR : Get Calculation Rules Error", e))
			.finally(() => (this.showSpinner = false));
	}

	openCalcRule = (event) => {
		this.selectedCR = event.target.value;
		this.showDialog = true;
	};

	deleteCalcRule = (event) => {
		if (!confirm("Are you sure?")) return null;
		deleteCalculationRuleServer({crId: event.target.value})
			.then(() => {
				_message("success", "Deleted");
				this.getCalculationRules();
			})
			.catch((e) => _parseServerError("CR : Deleting Error : ", e));
	};

	closeDialog = () => {
		this.showDialog = false;
		this.getCalculationRules();
	};


}