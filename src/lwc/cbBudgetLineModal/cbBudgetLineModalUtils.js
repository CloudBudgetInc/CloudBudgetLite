import {_message} from 'c/cbUtils';

/**
 * The method splits periods by BY for TAB TITLES
 */
const getPeriodGroups = () => {
	try {
		let byObj = {};
		const periods = JSON.parse(localStorage.getItem('periods'));
		for (const p of periods) {
			if (!byObj[p.cblight__CBBudgetYear__c]) {
				byObj[p.cblight__CBBudgetYear__c] = {
					label: p.cblight__CBBudgetYear__r.Name,
					value: p.cblight__CBBudgetYear__c
				}
			}
		}
		return Object.values(byObj);
	} catch (e) {
		_message('error', 'BLM Functions: Get Period Groups Error ' + e);
	}
};

export {
	getPeriodGroups,
};