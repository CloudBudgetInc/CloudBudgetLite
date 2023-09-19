import {api, LightningElement, track} from 'lwc';
import {_getCustomPermissions, _message, _parseServerError, _cl} from 'c/cbUtils';
import getFunctionsServer from "@salesforce/apex/CBFunctionPageController.getFunctionsServer";
import saveFunctionServer from "@salesforce/apex/CBFunctionPageController.saveFunctionServer";
import {NavigationMixin} from 'lightning/navigation';

export default class CbFunction extends NavigationMixin(LightningElement) {
	@track functionSO = [];
	@track functions = [];
	@track selectedFunctionId;
	@track customPermissions;// list of custom permissions
	@api type; // Variable, NFL or Filter
	FUNCTION_VARIABLE_FIELDS = [`CBAccount`, `CBDivision`, `CBVariable1`, `CBVariable2`, `CBVariable3`, `CBVariable4`, `CBVariable5`];
	FUNCTION_NFL_FIELDS = [`NFL1`, `NFL2`, `NFL3`, `NFL4`, `NFL5`, `NFLFormula`];

	connectedCallback() {
		this.getFunctions();
		this.getCustomPermissions();
	}

	/**
	 * Method gets list of functions form database to create SO list
	 */
	getFunctions = () => {
		getFunctionsServer({type: this.type})
			.then(functions => {
				this.functionSO = functions.map(f => ({value: f.Id, label: f.cblight__Title__c}));
				if (this.functionSO.length > 0) {
					this.functionSO.unshift({value: '', label: '-'});
				}
				this.functions = functions;
			})
			.catch(e => _parseServerError("Function : Get Function Error: ", e));
	};

	/**
	 * List of custom permissions to display or hide some functions
	 */
	async getCustomPermissions() {
		this.customPermissions = await _getCustomPermissions();
	}

	/**
	 * Method receives event from a parent component and sends a function to a parent component
	 */
	applyFunction = (event) => {
		let func;
		if (event.target.value.length > 0) {
			func = this.functions.find(f => f.Id === event.target.value);
			if (!confirm(`Are you sure you want to apply "${func.Name}" function?`)) {
				return null;
			}
		}
		try {
			this.selectedFunctionId = (event.target.value.length > 0) ? func.Id : '';
			event.preventDefault();
			this.dispatchEvent(new CustomEvent(`apply${this.type}Function`, {
				bubbles: true,
				composed: true,
				detail: func
			}));
		} catch (e) {
			_message('error', 'Function : Pass Function Error: ' + e);
		}
	};

	/**
	 * The method saves a new CB Function
	 * @param obj some parent object with analytics which need to be stored as a function
	 */
	@api saveFunction = async (obj) => {
		try {
			obj = JSON.parse(obj);
			let functionTitle = prompt("Please specify the function name.");
			if(!functionTitle) return;
			functionTitle = functionTitle.slice(0, 40);

			const newFunction = {Name: this.type, cblight__Type__c: this.type, cblight__Title__c: functionTitle};
			switch (this.type) {
				case 'Variable':
					this.FUNCTION_VARIABLE_FIELDS.forEach(ff => newFunction[`cblight__${ff}__c`] = obj[`cblight__${ff}__c`]);
					break;
				case 'NFL':
					this.FUNCTION_NFL_FIELDS.forEach(ff => newFunction[`cblight__${ff}__c`] = obj[`cblight__${ff}__c`]);
					break;
				case 'BLM':
					newFunction.cblight__Details__c = JSON.stringify(obj);
					break;
				default:
					console.log(`N/A`);
			}
			await saveFunctionServer({newFunction})
				.then(() => {
					this.getFunctions();
					_message('success', 'Function Saved')
				})
				.catch(e => _parseServerError('Function : Saving error', e));
		} catch (e) {
			_message('error', ' CBFunction: saveFunction Error : ' + e);
		}
	};

	@api resetSelectedFunction = () => {
		this.selectedFunctionId = '';
	};

	@api setSelectedFunction = (Id) => {
		this.selectedFunctionId =Id;
		let func = this.functions.find(f => f.Id === Id);
		this.dispatchEvent(new CustomEvent('applyBLMFunction', {
			bubbles: true,
			composed: true,
			detail: func
		}));
		
	};

	/**
	 * The method redirects to list of CB Functions
	 */
	redirectToFunctions = () => {
		try {
			this[NavigationMixin.GenerateUrl]({
				type: 'standard__objectPage',
				attributes: {
					objectApiName: 'cblight__CBFunction__c',
					actionName: 'list'
				},
				state: {
					filterName: 'Recent'
				}
			}).then(url => {
				window.open(url, "_blank");
			});
		} catch (e) {
			_message('error', 'Function : Redirect Error ' + e);
		}
	};

	/**
	 *
	 */
	saveCombination = () => {
		if (!confirm(`Are you sure you want to save the current combination of analytics as a function?`)) {
			return null;
		}
		try {
			this.dispatchEvent(new CustomEvent('saveFunction', {
				bubbles: true,
				composed: true
			}));
		} catch (e) {
			_message('error', 'Function : Save Function Error: ' + e);
		}
	};

}