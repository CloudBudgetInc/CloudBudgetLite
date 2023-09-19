/**
 * This lib is for MultiCurrency of BLM
 */
import getCurrencySOServer from "@salesforce/apex/CBMultiCurrencyService.getCurrencySOServer";
import {_message, _parseServerError} from "c/cbUtils";

let budgetLines; // List ob budget lines
let currencyList; // currencies in CBSO objects
let mainCurrency; // org currency by default
let currencyRateMap; // key - currency name, value currency rate

const manageMultiCurrency = async (bLines) => {
	budgetLines = bLines;
	await prepareMultiCurrency();
	if (!mainCurrency) return budgetLines; // multiCurrency disabled
	if (allBudgetLinesHaveTheSameCurrency()) return budgetLines; // conversion does not needed
	convertAllAmountCurrenciesToMainCurrency();
	return budgetLines;
};
/**
 * Method gets a list of Currencies if the org is multiCurrency enabled
 */
const prepareMultiCurrency = async () => {
	await getCurrencySOServer()
		.then(cSO => {
			if (cSO && cSO.length > 1) {
				currencyList = cSO;
				mainCurrency = cSO.find(c => c.type === 'true').value;
				currencyRateMap = cSO.reduce((r, so) => {
					r[so.label] = parseFloat(so.detail);
					return r;
				}, {});
			}
		})
		.catch(e => _parseServerError('BLM : Prepare Multi Currency Error : ', e));
};

/**
 * @return {boolean} true if all budget lines have the same currency
 */
const allBudgetLinesHaveTheSameCurrency = () => {
	const currencies = new Set(budgetLines.map(bl => bl.CurrencyIsoCode));
	return currencies.size === 1;
};
/**
 * Method converts bl value and all amount values to the main currency
 */
const convertAllAmountCurrenciesToMainCurrency = () => {
	_message('info', 'Note! All amounts are converted to the Org currency');
	const filteredBudgetLines = budgetLines.filter(bl => bl.CurrencyIsoCode !== mainCurrency);
	for (let i = 0; i < filteredBudgetLines.length; i++) {
		const bl = filteredBudgetLines[i], rate = currencyRateMap[bl.CurrencyIsoCode];
		bl.CurrencyIsoCode = mainCurrency;
		bl.cblight__Value__c = +(bl.cblight__Value__c / rate).toFixed(2);
		bl.cblight__CBAmounts__r.forEach(a => a.cblight__Value__c = +(a.cblight__Value__c / rate).toFixed(2));
	}
};

export {manageMultiCurrency};