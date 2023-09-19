import {api, LightningElement, track} from 'lwc';
import getSingleCalculationRuleServer
	from "@salesforce/apex/CBCalculationRulePageController.getSingleCalculationRuleServer";
import getSelectOptionsServer from "@salesforce/apex/CBCalculationRulePageController.getSelectOptionsServer";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import saveCalculationRuleServer from "@salesforce/apex/CBCalculationRulePageController.saveCalculationRuleServer";
import getNFLAmountsServer from "@salesforce/apex/CBCalculationRulePageController.getNFLAmountsServer";
import checkSourceBudgetLineServer from "@salesforce/apex/CBCalculationRulePageController.checkSourceBudgetLineServer";
import saveAllocationTermsServer from "@salesforce/apex/CBAllocationTermPageController.saveAllocationTermsServer";
import {_applyDecStyle, _isInvalid, _message, _parseServerError, _validateFormula, _cl} from 'c/cbUtils';
import {getAmounts} from './cbCalculationRuleDialogAmounts';
import CB_CR_OBJECT from "@salesforce/schema/CBCalculationRule__c";
import FOLDER_FIELD from "@salesforce/schema/CBCalculationRule__c.CBFolder__c";

export default class CbCalculationRuleDialog extends LightningElement {

	calculationRuleApiName = CB_CR_OBJECT;
	folderField = FOLDER_FIELD;

	@api selectedFolder;
	@api crId;
	@track oldCRId;
	@track isAllocationTermClonning = false;
	@track readyToRender = false;
	@track showSpinner = false;
	@track calculationRule = {};
	@track SOMap = {};
	@track orgVariable = {};
	@track amounts = {};
	@track NFLItems;
	@track exampleTableIndex = {'valueAmounts': '#2', 'NFLAmounts': '#3'};
	ANALYTICS = ['Division', 'BudgetYear', 'Account', 'Variable1', 'Variable2', 'Variable3', 'Variable4', 'Variable5', 'Scenario'];
	@track formulaWarning = {};
	@track COMMON_FORMULAS = ["#1 * #2", "#1 + #2", "#1 * #2 * (1 + #3)"];

	get isContractMode() {
		return this.calculationRule?.cblight__CBAllocationTerms__r?.length;
	}

	async connectedCallback() {
		try {
			this.getSO();
			await this.getCalculationRule();
			await this.getNFLAmounts();
			this.amounts = getAmounts(this);
			_applyDecStyle();
		} catch (e) {
			_message('error', 'CRD : Connected Callback Error : ' + e);
		}
	}

	/**
	 * list of calculation rules
	 */
	async getCalculationRule() {
		this.readyToRender = false;
		this.showSpinner = true;
		if (!this.crId) { // new Calculation Rule
			this.calculationRule = this.getNewCalculationRule();
			this.readyToRender = true;
			return null;
		}
		await getSingleCalculationRuleServer({crId: this.crId})
			.then(calculationRuleObject => {
				this.calculationRule = calculationRuleObject.calculationRule;
				this.readyToRender = true;
			})
			.catch(e => _parseServerError('CRD : Get Calculation Rule Error', e))
			.finally(() => this.showSpinner = false);
		if (!_isInvalid(this.calculationRule.cblight__Formula__c)) this.validateFormulaCR(this.calculationRule.cblight__Formula__c);
	};

	saveCalculationRule() {
		let calcRule = this.calculationRule;
		if (this.validateCR(calcRule)) return;
		this.readyToRender = false;
		this.showSpinner = true;
		calcRule.Name = calcRule.Name.slice(0, 80);
		saveCalculationRuleServer({cr: calcRule})
			.then(crId => {
				this.crId = crId;
				switch (this.isAllocationTermClonning) {
					case true:
						this.cloneAllocationTerm();
						break;
					case false:
						this.getCalculationRule().then(() => null);
						break;	
				}
				_message('success', 'Saved');
			}).catch(e => {
			_parseServerError('CRD : Saving Error', e);
			this.showSpinner = false;
		})
	};

	/**
	 * Method clones AT
	 */
	cloneAllocationTerm(){
		this.calculationRule.cblight__CBAllocationTerms__r.forEach(aTerm => {
			delete aTerm.Id;
			aTerm.cblight__CBCalculationRule__c = this.crId;
			aTerm.Name = aTerm.Name + " Cloned";
			aTerm.Name = aTerm.Name.length  > 79 ? aTerm.Name.substr(0, 79) : aTerm.Name;
		});
		saveAllocationTermsServer({aTerms: this.calculationRule.cblight__CBAllocationTerms__r})
			.then(() => {
				this.isAllocationTermClonning = false;
				this.getCalculationRule().then(() => null);
			})
			.catch(e => _parseServerError('CRD : Save Allocation Term Error : ', e))
		
    }


	validateCR = (cr) => {
		const ov = this.orgVariable;
		let errorMessage = null;
		if (!cr.cblight__copyBudgetYear__c && !cr.cblight__CBBudgetYear__c) {
			errorMessage = `"${ov.cblight__CBBudgetYearLabel__c}" for the target budget line cannot be blank unless "${ov.copyCBBudgetYearLabel}" is marked.`;
		}
		if (!cr.cblight__copyAccount__c && !cr.cblight__CBAccount__c) {
			errorMessage = `"${ov.cblight__CBAccountLabel__c}" for the target budget line cannot be blank unless "${ov.copyCBAccountLabel}" is marked.`;
		}
		if (!Number(cr.cblight__Value__c) && !cr.cblight__NFL1__c) errorMessage = 'Please specify Variable or NFL, or both before saving.'
		if (errorMessage) _message('warning', errorMessage);
		return errorMessage;
	};

	cloneCalculationRule = () => {
		
		if (this.isContractMode) {
			this.isAllocationTermClonning = true;
			this.oldCRId = this.calculationRule.Id;
		}
		delete this.calculationRule.Id;
		this.calculationRule.Name = 'Cloned ' + this.calculationRule.Name;
		_message('success', 'Cloned');
		this.saveCalculationRule();
	};

	getNewCalculationRule = () => {
		try {
			let r = {
				Name: 'New',
				cblight__Value__c: 1,
				cblight__Formula__c: '#1 * #2',
				cblight__ResultName__c: 'Auto Line',
				cblight__CBFolder__c: this.selectedFolder
			};
			this.ANALYTICS.forEach(a => r[`cblight__copy${a}__c`] = true);
			return r;
		} catch (e) {
			_message('error', 'CRD : New CR Error : ' + e);
		}
	};

	getNFLAmounts = async () => {
		if (!this.calculationRule || !this.calculationRule.cblight__NFL1__c) {
			this.NFLItems = undefined;
			return null;
		}
		await getNFLAmountsServer({nflId: this.calculationRule.cblight__NFL1__c}).then(NFLItems => this.NFLItems = NFLItems).catch(e => _parseServerError('CRD : Get NFL Amounts Error', e))
	};

	getSO = () => getSelectOptionsServer().then(SOMap => {
		this.SOMap = SOMap;
		this.getOrgVariable();
	}).catch(e => _parseServerError('CRD : Get SO Error', e));

	getOrgVariable = () => getOrgVariableServer().then(v => {
		this.orgVariable = v;
		let orgVariableKeys = Object.keys(this.orgVariable);
		orgVariableKeys.forEach(key => {
			if (key.includes('Label')) {
				const label = this.orgVariable[key];
				const copyKey = key.replace(/cblight__|__c/gi, '');
				this.orgVariable['copy' + copyKey] = 'Copy ' + label;
				const bLKey = key.replace('Label', '');
				this.SOMap.budgetLineFieldSO.forEach(field => {
					if (field.value === bLKey) field.label = label;
				});
			}

		});
	}).catch(e => _parseServerError('CRD : Org Variables Error : ', e));

	validateFormulaCR = (formula) => {
		const validationMessage = _validateFormula(formula, 5);
		this.formulaWarning = validationMessage ? {class: 'formulaWarning', message: '⚠ ' + validationMessage} : {
			class: 'formulaValid',
			message: '✓ Valid'
		};
	};

	applyAutoFormulaCR = (event) => {
		this.calculationRule.cblight__Formula__c = event.target.value;
		this.validateFormulaCR(event.target.value);
	};

	checkBudgetLines = () => {
		this.showSpinner = true;
		this.readyToRender = false;
		checkSourceBudgetLineServer({
			blFilter: this.calculationRule.cblight__SourceParentFilter__c,
			amountFilter: this.calculationRule.cblight__SourceChildFilter__c
		}).then(reportObject => {
			Object.keys(reportObject).forEach(key => _message('info', reportObject[key], key));
			this.showSpinner = false;
			this.readyToRender = true;
		}).catch(e => _parseServerError('CRD : Check Source Budget Lines Error', e))
	};

	nullifyValueIfCopy = () => {
		this.ANALYTICS.forEach(f => {
			if (this.calculationRule[`cblight__copy${f}__c`]) this.calculationRule[`cblight__CB${f}__c`] = null;
		});
	};

	setParentFilter = (event) => this.calculationRule.cblight__SourceParentFilter__c = event.detail.result.length > 0 ? `${event.detail.result}` : "";
	setChildFilter = (event) => this.calculationRule.cblight__SourceChildFilter__c = event.detail.result.length > 0 ? `${event.detail.result}` : "";

	/**
	 * Method closes a cr dialog
	 */
	closeDialog = () => {
		this.dispatchEvent(new CustomEvent('closeDialog', {
			bubbles: true,
			composed: true,
			detail: '_'
		}));
	};

	/**
	 * Main handler to manage inputs and dropdowns
	 */
	handleRuleChanging = async (event) => {
		const eventName = event.target.name;
		const eventValue = event.target.value;

		this.calculationRule[eventName] = eventName.includes('copy') ? event.target.checked : eventValue;
		if (eventName === 'cblight__NFL1__c') await this.getNFLAmounts();
		if (eventName === 'cblight__Formula__c') this.validateFormulaCR(eventValue);
		if (eventName === 'cblight__Value__c' && !this.calculationRule.cblight__Value__c) this.calculationRule.cblight__Value__c = 0;
		if (eventName === 'cblight__Mode__c') this.calculationRule.cblight__ResultName__c = (eventValue === 'many-to-one') ? 'Grouped Auto Line' : 'Auto Line';

		this.nullifyValueIfCopy();
		this.amounts = getAmounts(this);
	};

	/**
	 * Method to open AT component
	 */
	setAllocationMode = () => {
		this.calculationRule.cblight__CBAllocationTerms__r = [1];
	};
	/**
	 * Method to recieve Aloc Terms from AT components after changes or deletes
	 */
	updateAllocationTerms = (event) => {
		try {
			const allocationTerms =  event.detail.AllocationTerms;
			if (this.calculationRule.cblight__CBAllocationTerms__r[0] != 1 && allocationTerms.length != 0 ) {
				this.calculationRule.cblight__CBAllocationTerms__r = allocationTerms;
			}
		} catch (e) {
			_message('error', 'CRD : Update Allocation Terms Error : ' + e);
		}
	};

	/**
	 * Event Listerner from AT component
	 */
	constructor() {
		super();
		this.addEventListener("updateAllocationTerms", this.updateAllocationTerms); // Listener from the AT component
		
	}
}