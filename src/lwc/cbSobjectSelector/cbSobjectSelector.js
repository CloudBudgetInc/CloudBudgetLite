import {api, LightningElement} from "lwc";
import {_message, _parseServerError} from "c/cbUtils";
import getFilteredListOfSobjectsServer
	from "@salesforce/apex/CBModelingRulePageController.getFilteredListOfSobjectsServer";
import getSobjectLabelByReferenceServer
	from "@salesforce/apex/CBModelingRulePageController.getSobjectLabelByReferenceServer";

export default class CbSobjectSelector extends LightningElement {
	MIN_NUMBER_OF_CHARS_FOR_SEARCH = 3;
	BLANK_SELECT_OPTION_TEXT = "--BLANK--";

	@api name = "";
	@api label = "";

	@api get selectedItem() {
	}

	showDialog = false;
	showSpinner = false;
	@api showEmptyOption = false;

	set selectedItem(item) {
		try {
			if (!item) {
				this.selectedItemLabel = this.BLANK_SELECT_OPTION_TEXT;
			}
			this.getSobjectLabel(item);
		} catch (e) {
			_message("error", "SOS : Selected Item Error : " + e);
		}
	}

	selectedItemLabel = "";
	listToShow = [];

	/**
	 * Returns label of selected object
	 * @param {*} objectName name of the selected object
	 */
	getSobjectLabel = (objectName) => {
		if (!objectName) return;
		getSobjectLabelByReferenceServer({objectName})
			.then(label => this.selectedItemLabel = label)
			.catch(e => _parseServerError("MRD : Get List Of Available Source Child Sobjects Error : ", e));
	};

	/**
	 * Opens modal window
	 */
	openWindow = () => {
		this.showDialog = true;
	};

	/**
	 * Closes modal window
	 */
	closeWindow = () => {
		this.showDialog = false;
		this.listToShow = [];
	};

	/**
	 * if entered filter string is bigger or equals then expected - returns list of the filtered objects
	 * @param {*} event event from changed filter
	 */
	handleFilterChange = (event) => {
		try {
			const filterString = event.target.value;
			if (filterString.length >= this.MIN_NUMBER_OF_CHARS_FOR_SEARCH) {
				this.showSpinner = true;
				getFilteredListOfSobjectsServer({filterString})
					.then(listToShow => this.listToShow = listToShow)
					.catch(e => _parseServerError("MRD : Get List Of Available Source Child Sobjects Error : ", e))
					.finally(() => this.showSpinner = false);
			}
		} catch (e) {
			_message("error", "SOS : Handle Filter Change Error: " + e);
		}
	};

	/**
	 * This function detects when one of the options is selected and sends an event to the top with the selected value
	 * @param {*} event
	 */
	handleClick = (event) => {
		try {
			const label = event.target.dataset.label;
			const value = event.target.dataset.value;
			const selectorLabel = this.label;
			const selectorName = this.name;
			this.selectedItem = value;
			const detail = {value, label, selectorLabel, selectorName};
			const evt = new CustomEvent("sobjchanged", {detail: detail});
			this.dispatchEvent(evt);
			this.closeWindow();
		} catch (e) {
			_message("error", "SOS : Handle Click Error : " + e);
		}
	};
}