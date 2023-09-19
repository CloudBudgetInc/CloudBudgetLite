import getNonFinancialLibrariesServer from '@salesforce/apex/CBBudgetLinePageController.getNonFinancialLibrariesServer';
import {_getCopy, _message} from 'c/cbUtils';

let context;
/**
 * Method is cloning budget line with static and custom NFLibs
 */
const cloneCurrentBudgetLine = async (_this) => {
	try {
		context = _this;
		let budgetLine = _getCopy(context.budgetLine);
		budgetLine.Name = 'Copy of ' + budgetLine.Name;
		budgetLine.Name.slice(0, 80);
		delete budgetLine.Id;
		delete budgetLine.cblight__Index__c;
		delete budgetLine.cblight__Lock__c;
		let NFLibMap = {};
		await getNonFinancialLibrariesServer().then(libs => {
			[1, 2, 3, 4, 5].forEach(i => {
				delete budgetLine[`cblight__NFL${i}__r`];
				let nflId = budgetLine[`cblight__NFL${i}__c`];
				if (!nflId) return;
				let NFLib = libs.find(n => n.Id === nflId);
				if (NFLib.cblight__Type__c === 'Custom') {
					budgetLine[`cblight__NFL${i}__c`] = NFLib.cblight__Layer__c;
				}
				NFLibMap[i] = budgetLine[`cblight__NFL${i}__c`];
			});
		});
		budgetLine.cblight__CBAmounts__r.forEach(a => {
			delete a.Id;
			delete a.cblight__CBBudgetLine__c;
		});
		budgetLine.amountObject.wholeAmounts.forEach(a => {
			delete a.Id;
			delete a.cblight__CBBudgetLine__c;
		});
		budgetLine.amountObject.wholeAmounts.forEach(a => {
			delete a.Id;
			delete a.cblight__CBBudgetLine__c;
		});
		budgetLine.amountObject.wholeNFLibs.forEach(libItems => {
			libItems.forEach((item, i) => {
				delete item.Id;
				delete item.cblight__CBBudgetLine__c;
				item.cblight__NonFinancialLibrary__c = NFLibMap[i + 1];
			});
		});
		budgetLine.amountObject.displayedNFLibs.forEach(libItems => {
			libItems.forEach((item, i) => {
				delete item.Id;
				delete item.cblight__CBBudgetLine__c;
				item.cblight__NonFinancialLibrary__c = NFLibMap[i + 1];
			});
		});

		context.budgetLine = budgetLine;
	} catch (e) {
		_message('error', 'BLM Clone Budget Line Error : ' + e);
	}
};


export {
	cloneCurrentBudgetLine
};