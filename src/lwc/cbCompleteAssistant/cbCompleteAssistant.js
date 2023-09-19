import {api, LightningElement, track} from 'lwc';
import {_applyDecStyle, _getCopy, _message} from "c/cbUtils";
import {calculateExampleTotal, funcCatalog} from "./cbCompleteAssistantCalculations";


export default class CbCompleteAssistant extends LightningElement {

	@api objects; // List of amounts or something
	@api field; // cblight__Value__c
	@track isStartBtnDisabled = false; //disable the start button
	@track showDialog = false;
	@track exampleAmounts = [];
	@track exampleTotal = 0;
	@track mathModeSO = [
		{label: 'Repeat Evenly', value: 'spread'},
		{label: 'Divide Evenly', value: 'splitBY'},
		{label: 'Multiply Each Cell by…', value: 'multiplyBy'},
		{label: 'Add to Each Cell', value: 'add'},
	];
	@track selectedMode = 'spread';
	@track baseAmount = '1000';

	connectedCallback() {
		if (this.objects && this.objects.length > 0) {
			this.isStartBtnDisabled = this.objects[0].disabled;
		}
		_applyDecStyle();
	};

	/**
	 * Open/close dialog window
	 */
	toggleDialogWindow = () => {
		this.showDialog = !this.showDialog;
		if (this.showDialog) {
			this.baseAmount = this.objects[0][this.field];
			this.exampleAmounts = _getCopy(this.objects);
			calculateExampleTotal(this);
		}
	};

	/**
	 * Method passes updated amounts to a parent component
	 */
	applyAmounts = () => {
		const parentEvent = new CustomEvent("applycompleteamounts", {detail: {amounts: this.exampleAmounts}});
		this.dispatchEvent(parentEvent);
		this.toggleDialogWindow();
	};

	/**
	 * Method receives changes from the component
	 */
	handleChanges = (event) => {
		this[event.target.name] = event.target.value;
		try {
			this.exampleAmounts = _getCopy(this.objects);
			funcCatalog[this.selectedMode](this);
			calculateExampleTotal(this);
		} catch (e) {
			_message('error', 'CA : Calculation Error : ' + e)
		}
	}


}