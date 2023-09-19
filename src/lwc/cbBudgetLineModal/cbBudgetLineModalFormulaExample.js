import {_message} from 'c/cbUtils';

let context;

/**
 * Get example data
 */
const getFormulaExample = (_this) => {
	context = _this;
	const exampleObject = {
		state: 'OK'
	};
	try {
		let formula = context.budgetLine.cblight__NFLFormula__c;
		let nflNumber = 0;
		for (let i = 1; i <= 5; i++) {
			if (context.budgetLine[`title${i}`]) nflNumber++;
		}
		let maxArg = 0;
		formula.split('').forEach(s => {
			if (Number.isInteger(s)) {
				Math.max()
			}
		})
	} catch (e) {
		_message('error', 'BLM : Get Formula Example Error : ' + e);
	}
};


export {
	getFormulaExample
};