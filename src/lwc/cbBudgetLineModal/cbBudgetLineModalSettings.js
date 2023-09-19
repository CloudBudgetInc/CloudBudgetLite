import getNonFinancialLibrariesServer from "@salesforce/apex/CBBudgetLinePageController.getNonFinancialLibrariesServer";
import getLayersServer from "@salesforce/apex/CBNFLSelectorPageController.getLayersServer";
import {_cl, _message, _parseServerError, _validateFormula} from 'c/cbUtils';

let context;
const initSetup = async (_this) => {
	try {
		context = _this;
		await getLayers();
	} catch (e) {
		_message('error', 'BLM Settings : Init Setup Error : ' + e);
	}
};

const getLayers = async () => {
		const layers = await getLayersServer()
		.catch(e => _parseServerError("NFL Selector layers error : ", e));
		context.layers = layers;
};

const renderRedirectButtons = () => {

};

const passEditableToNFLItems = (libs) => {
	libs.forEach(lib => {
		lib.cblight__NonFinancialItems__r.forEach(item => item.disabled = lib.cblight__Type__c === 'Static')
	});
};

/**
 * Selected NFL passed to list of related NFLs
 */
const passToLegend = (NFLLine, legendIndex) => {
	try {
		context.budgetLine[`cblight__NFL${legendIndex}__c`] = NFLLine.Id;
		context.budgetLine[`cblight__NFLTitle${legendIndex}__c`] = `${NFLLine.Name} (${NFLLine.cblight__LayerTitle__c})`;
	} catch (e) {
		_message('error', 'BLM Settings : Pass to legend Error: ' + e);
	}
};

const deleteValueFromLegend = (event) => {
	try {
		context.budgetLine[`cblight__NFL${event.target.value}__c`] = null;
		context.budgetLine[`cblight__NFLTitle${event.target.value}__c`] = ``;
	} catch (e) {
		_message('error', 'BLM Setting : Delete Value Error : ' + e);
	}
};

/**
 * Handler for changed formula
 */
const changeFormula = (event) => {
	validateFormula(event.target.value);
	context.budgetLine.cblight__NFLFormula__c = event.target.value;
};

const validateFormula = (formula) => {
	const validationMessage = _validateFormula(formula, 5);
	context.formulaWarning = validationMessage ? {class: 'formulaWarning', message: '⚠ ' + validationMessage} : {
		class: 'formulaValid',
		message: '✓ Valid'
	};
};

/**
 * Service class to store group of budget lines with the common status
 */
function SourceGroup() {
	this.lines = [];
	this.title = '';
}


export {
	initSetup, passToLegend, changeFormula, deleteValueFromLegend, validateFormula, passEditableToNFLItems
};