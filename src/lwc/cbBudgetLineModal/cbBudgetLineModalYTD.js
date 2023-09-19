/**
 * The method splits periods by BY for TAB TITLES
 */
import {_getCopy} from "c/cbUtils";

const getYTDAmounts = (displayedAmounts) => {
	try {
		let YTDAmounts = _getCopy(displayedAmounts);
		YTDAmounts.forEach((amount, idx) => {
			if (idx === 0) return;
			amount.cblight__Value__c += +YTDAmounts[idx - 1].cblight__Value__c;
		});
		return YTDAmounts;
	} catch (e) {
		alert('BLM Functions: Get YTD Amounts Error ' + e);
	}
};

export {
	getYTDAmounts,
};