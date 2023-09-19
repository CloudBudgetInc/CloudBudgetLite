import {_generateFakeId, _message} from "c/cbUtils";

/**
 * Method adds lost amounts to a budget line if needed
 */
const addLostAmountsIfNeeded = (budgetLines) => {
	try {
		const relevantPeriods = JSON.parse(localStorage.getItem('BYPeriods'));
		budgetLines.forEach(bl => {
			const amounts = bl.cblight__CBAmounts__r;
			if (amounts.length === relevantPeriods.length) return null;
			const updatedAmounts = [];
			relevantPeriods.forEach(p => {
				let amount = amounts.find(am => am.cblight__CBPeriod__c === p.Id);
				if (!amount) amount = {
					cblight__Value__c: 0,
					cblight__CBPeriod__c: p.Id,
					cblight__CBBudgetYear__c: p.cblight__CBBudgetYear__c,
					cblight__CBBudgetYearSet__c: p.cblight__CBBudgetYearSet__c,
					cblight__PeriodName__c: p.Name,
					cblight__CBBudgetLine__c: bl.Id,
					Id: _generateFakeId()
				};
				updatedAmounts.push(amount);
			});
			bl.cblight__CBAmounts__r = updatedAmounts;
		});
	} catch (e) {
		_message('error', 'BLMLF : Add Lost Amounts Error : ' + e);
	}
};

export {addLostAmountsIfNeeded};