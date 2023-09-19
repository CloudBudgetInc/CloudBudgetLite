/**
 * Library for populating and managing amount
 */
import {_message} from 'c/cbUtils';

let context; // this from parent
/**
 * All lines stores in special class called Amounts. This method populated Amounts object to display on the screen
 */
const getProcessedAmounts = (_this) => {
	try {
		context = _this;
		const amountObject = new Amounts(context.line.cblight__CBAmounts__r);
		return amountObject;
	} catch (e) {
		_message('error', 'BL Amounts: Get Processed Amounts Error: ' + e);
	}
};

/**
 * Special class to manage amounts
 * @param amounts
 * @constructor
 */
function Amounts(amounts) {
	this.wholeAmounts = amounts; // all currency budget line amounts

	/**
	 * Calculating the main total of the budget line
	 */
	this.getGlobalBLTotal = () => {
		try {
			let total = 0;
			this.wholeAmounts.forEach(amount => total += amount.cblight__Value__c ? +amount.cblight__Value__c : 0);
			return +total;
		} catch (e) {
			_message('error', 'BLM Amounts : Calculate Global Total Error: ' + e);
		}
	};

	/**
	 *
	 * @param amountId id of needed amount
	 * @param value new value of this amount
	 */
	this.applyNewValue = (amountId, value) => {
		try {
			const amount = this.wholeAmounts.find(({Id}) => Id === amountId);
			amount.cblight__Value__c = Number(value);
			amount.inputStyle = 'dec inputStyle';
		} catch (e) {
			_message('error', 'BL Amounts : Apply New Value Error : ' + e);
		}
	};
}

export {getProcessedAmounts};