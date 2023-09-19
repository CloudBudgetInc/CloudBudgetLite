import {api, LightningElement, track} from 'lwc';
import {_getCopy, _message, _selectWholeValue} from 'c/cbUtils';
import {getProcessedAmounts} from './cbBudgetLineAmounts';

export default class CbBudgetLine extends LightningElement {

	@api line;
	@api amounts = [];
	@track periods;
	@track isDetailMode = false;

	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		this.isDetailMode = localStorage.getItem('isDetailMode') === 'true';
		this.disableAmounts(_getCopy(this.line));
		this.addAmountsStyle();
	}

	/**
	 * Method pass event to budget line manager that opens needed budget line in dialog window
	 * @param event
	 */
	openLine = (event) => {
		try {
			event.preventDefault();
			const detail = event.target.dataset.id;
			this.dispatchEvent(new CustomEvent('openBudgetLineModal', {
				bubbles: true,
				composed: true,
				detail
			}));
		} catch (e) {
			_message('error', `Budget Line : Open Line Error : ${e}`);
		}
	};

	/**
	 * Method pass event to budget line manager that opens needed Calculation Rule dialog window
	 * @param event
	 */
	openLineCalculationRule = (event) => {
		try {
			event.preventDefault();
			this.dispatchEvent(new CustomEvent('openLineCalculationRule', {
				bubbles: true,
				composed: true,
				detail: this.line.cblight__CBCalculationRule__c
			}));
		} catch (e) {
			_message('error', `Budget Line : Open Line Calculation Rule Error : ${e}`);
		}
	};

	/**
	 * Reaction for changing data in the budget line
	 */
	handleBudgetLine = (event) => {
		try {
			const eventId = event.target.name ? event.target.name : event.target.fieldName;// field type
			const eventValue = event.target.value || '0'; // value of the field
			const validValue = eventValue.search(/^[-+]?[0-9]+\.[0-9]{3}$/) ? true : false;
			if (!eventValue || !validValue) return;
			this.line = _getCopy(this.line);
			this.line.amountObject = getProcessedAmounts(this);
			this.line.amountObject.applyNewValue(eventId, eventValue);
			this.line.cblight__Value__c = this.line.amountObject.getGlobalBLTotal();
			this.line.yearlyTotal = this.line.cblight__Value__c;
			this.line.cblight__CBAmounts__r = this.line.amountObject.wholeAmounts;
			delete this.line.amountObject;
			this.sendBudgetLineToBLM();
		} catch (e) {
			_message('error', 'BL: Handle Budget Line Error: ' + e);
		}
	};

	/**
	 * Method pass event to budget line manager that send budget line for saving
	 */
	sendBudgetLineToBLM = () => {
		try {
			this.dispatchEvent(new CustomEvent('updateBudgetLineInBLM', {
				bubbles: true,
				composed: true,
				detail: this.line
			}));
		} catch (e) {
			_message('error', `Budget Line : Send Budget Line To Blm Error : ${e}`);
		}
	};

	selectWhole = (event) => _selectWholeValue(event);

	/**
	 * This method disables amounts from editing if budget line is forecast OR formula OR Allocation
	 */
	disableAmounts = (line) => {
		try {
			line.cblight__CBAmounts__r.forEach(amount => amount.disabled = line.cblight__isFormulaBudgetLine__c || amount.cblight__CBStyleName__c || line.cblight__isAllocation__c || line.cblight__Lock__c === 'Editing');
			this.line = line;
		} catch (e) {
			_message('error', 'BL : Disable Amounts Error: ' + e);
		}
	};

	/**
	 * This method add style to amounts
	 */
	addAmountsStyle = () => {
		try {
			this.line.cblight__CBAmounts__r.forEach(amount => amount.inputStyle = 'dec');
		} catch (e) {
			_message('error', 'BL : Add Amounts Style Error: ' + e);
		}
	};
}