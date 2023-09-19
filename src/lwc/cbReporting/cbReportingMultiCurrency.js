/**
 * This lib is for MultiCurrency of Report lines
 */
import getCurrencySOServer from "@salesforce/apex/CBMultiCurrencyService.getCurrencySOServer";
import {_message, _parseServerError} from "c/cbUtils";

let cubes;
let currencyList; // currencies in CBSO objects
let mainCurrency; // org currency by default
let currencyRateMap; // key - currency name, value currency rate

const manageMultiCurrency = async (c) => {
	cubes = c;
	await prepareMultiCurrency();
	if (!mainCurrency) return cubes; // multiCurrency disabled
	if (allCubesHaveTheSameCurrency()) return cubes; // conversion does not needed
	convertAllAmountCurrenciesToMainCurrency();
	return cubes;
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
	console.log('currencies.size = ' + currencies.size);
	return currencies.size === 1;
};
/**
 * Method converts bl value and all amount values to the main currency
 */
const convertAllAmountCurrenciesToMainCurrency = () => {
	_message('info', 'Note! All amounts are converted to the Org currency');

	const filteredCubes = cubes.filter(c => c.CurrencyIsoCode !== mainCurrency);
	for (let i = 0; i < filteredCubes.length; i++) {
		const cube = filteredCubes[i], rate = currencyRateMap[cube.CurrencyIsoCode];
		cube.CurrencyIsoCode = mainCurrency;
		cube.cblight__Budget__c /= rate;
		cube.cblight__Actual__c /= rate;
	}
};

export {manageMultiCurrency};