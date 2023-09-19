import {_message} from 'c/cbUtils';

let context;
let AMOUNT_NUMBER = 12;
let amountObject = {};

const getAmounts = (_this) => {
	try {
		context = _this;
		amountObject = {};
		amountObject.baseAmounts = getBaseAmounts();
		amountObject.valueAmounts = getValueAmounts();
		if (context.NFLItems) amountObject.NFLAmounts = getNFLAmounts();
		amountObject.resultAmounts = getResultAmounts();
		context.exampleTableIndex = setExampleTableIndex(amountObject);
		return amountObject;
	} catch (e) {
		_message('error', 'CRD : Get Amount Error : ' + e);
	}
};

const getBaseAmounts = () => {
	try {
		const baseAmounts = [];
		for (let i = 0; i < AMOUNT_NUMBER; i++) baseAmounts.push({value: 100, label: `M${i + 1}`});
		return baseAmounts;
	} catch (e) {
		_message('error', 'CRD : Get Base Amounts Error : ' + e);
	}
};

const getValueAmounts = () => {
	try {
		if (!context.calculationRule.cblight__Value__c || isNaN(context.calculationRule.cblight__Value__c) || parseFloat(context.calculationRule.cblight__Value__c) === 0) return undefined;
		const valueAmounts = [];
		for (let i = 0; i < AMOUNT_NUMBER; i++) {
			if (!context.calculationRule.cblight__Value__c || isNaN(context.calculationRule.cblight__Value__c)) throw 'Parameter is not a number!';
			valueAmounts.push({
				value: context.calculationRule.cblight__Value__c
			});
		}
		return valueAmounts;
	} catch (e) {
		return getErrorAmounts();
		//_message('error', 'CRD : Get Value Amounts Error : ' + e);
	}
};

const getNFLAmounts = () => {
	try {
		const NFLAmounts = [];
		for (let i = 0; i < AMOUNT_NUMBER; i++) NFLAmounts.push({
			value: context.NFLItems[i].cblight__Value__c
		});
		return NFLAmounts;
	} catch (e) {
		return getErrorAmounts();
		//_message('error', 'CRD : Get NFL Amounts Error : ' + e);
	}
};

const getResultAmounts = (r) => {
	try {
		const formulaResult = [];
		for (let i = 0; i < AMOUNT_NUMBER; i++) {
			const amountArray = [amountObject.baseAmounts[i].value];
			if (amountObject.valueAmounts) amountArray.push(amountObject.valueAmounts[i].value);
			if (amountObject.NFLAmounts) amountArray.push(amountObject.NFLAmounts[i].value);
			formulaResult.push({value: getFormulaValue(amountArray)});
		}
		return formulaResult;
	} catch (e) {
		return getErrorAmounts();
		//_message('error', 'CRD : Get Result Amounts Error : ' + e);
	}
};

const getErrorAmounts = () => {
	const nullAmounts = [];
	for (let i = 0; i < AMOUNT_NUMBER; i++) nullAmounts.push({value: -1});
	return nullAmounts;
};

const getFormulaValue = (cells) => {
	try {
		let mathString = '';
		context.calculationRule.cblight__Formula__c.split(' ').forEach(k => {
			if (k.startsWith('#')) {
				k = k.replace('#', '');
				mathString += cells[--k];
			} else {
				mathString += k;
			}
		});
		let result = eval(mathString);
		return isNaN(result) ? 0 : parseFloat(result.toFixed(2));
	} catch (e) {
		return -1;
		//_message('error', `CRD : Get Formula Value Error : ${e}`);
	}
};

const setExampleTableIndex = (amountObject) => {
	if (amountObject.valueAmounts) {
		return context.NFLItems ? {'valueAmounts': '#2', 'NFLAmounts': '#3'} : {'valueAmounts': '#2'}
	} else {
		return {'NFLAmounts': '#2'};
	}
};


export {getAmounts};