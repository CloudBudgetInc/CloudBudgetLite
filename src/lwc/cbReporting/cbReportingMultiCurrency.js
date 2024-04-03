/**
 * This lib is for MultiCurrency of Report lines
 */
import getCurrencySOServer from "@salesforce/apex/CBMultiCurrencyService.getCurrencySOServer";
import getCurrencyMonthlyRatesServer from "@salesforce/apex/CBMultiCurrencyService.getCurrencyMonthlyRatesServer";
import {_message, _parseServerError} from "c/cbUtils";

let cubes;
let currencyList; // currencies in CBSO objects
let mainCurrency; // org currency by default
let currencyRateMap; // key - currency name, value currency rate
let monthlyCurrencyRateMap; // key - currency name, value - map periodId => currency rate

const manageMultiCurrency = async (c) => {
	cubes = c;
	await prepareMultiCurrency();
	if (!mainCurrency) return cubes; // multiCurrency disabled
	if (allCubesHaveTheSameCurrency()) return cubes; // conversion does not needed
	await getMonthlyCurrencyRates();
	convertAllAmountCurrenciesToMainCurrency();
	return cubes;
};

const getMonthlyCurrencyRates = async () => {
	monthlyCurrencyRateMap = await getCurrencyMonthlyRatesServer();
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
		.catch(e => _parseServerError('Reporting : Prepare Multi Currency Error : ', e));
};

/**
 * @return {boolean} true if all CB Cubes have the same currency
 */
const allCubesHaveTheSameCurrency = () => {
	const currencies = new Set(cubes.map(c => c.CurrencyIsoCode));
	return currencies.size === 1;
};
/**
 * Method converts bl value and all amount values to the main currency
 */
const convertAllAmountCurrenciesToMainCurrency = () => {
	_message('info', 'Note! All amounts are converted to the Org currency');
	const filteredCubes = cubes.filter(c => c.CurrencyIsoCode !== mainCurrency);
	for (let i = 0; i < filteredCubes.length; i++) {
		const cube = filteredCubes[i];
		if (monthlyCurrencyRateMap) {
			let rateMap = monthlyCurrencyRateMap[cube.CurrencyIsoCode];
			let rate = rateMap ? rateMap[cube.cblight__CBPeriod__c] : 1;
			rate = rate ? rate : 1;
			if (cube.cblight__Budget__c) cube.cblight__Budget__c = +(cube.cblight__Budget__c / rate).toFixed(2);
			if (cube.cblight__Actual__c) cube.cblight__Actual__c = +(cube.cblight__Actual__c / rate).toFixed(2);
		} else {
			const rate = currencyRateMap[cube.CurrencyIsoCode];
			cube.cblight__Budget__c = +(cube.cblight__Budget__c / rate).toFixed(2);
			cube.cblight__Actual__c = +(cube.cblight__Actual__c / rate).toFixed(2);
		}
		cube.CurrencyIsoCode = mainCurrency;
	}
};

export {manageMultiCurrency};