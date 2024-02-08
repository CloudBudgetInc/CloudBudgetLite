import {api, LightningElement, track} from 'lwc';
import getBudgetLineServer from '@salesforce/apex/CBBudgetLinePageController.getSingleBudgetLineServer';
import getLibrariesFromBudgetLineServer
	from '@salesforce/apex/CBBudgetLinePageController.getLibrariesFromBudgetLineServer';
import saveBudgetLineServer from '@salesforce/apex/CBBudgetLinePageController.saveBudgetLineServer';
import updateNonFinancialItemsServer
	from '@salesforce/apex/CBNonFinancialLibraryPageController.updateNonFinancialItemsServer';
import deleteBudgetLineServer from '@salesforce/apex/CBBudgetLinePageController.deleteBudgetLineServer';
import getSelectOptionsServer from "@salesforce/apex/CBBudgetLinePageController.getSelectOptionsServer";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import getFunctionsServer from "@salesforce/apex/CBFunctionPageController.getFunctionsServer";
import {
	_applyDecStyle,
	_deleteFakeId,
	_getCopy,
	_getCustomPermissions,
	_isFakeId,
	_message,
	_parseServerError,
	_selectWholeValue
} from 'c/cbUtils';
import {NavigationMixin} from 'lightning/navigation';
import {getPeriodGroups} from './cbBudgetLineModalUtils';
import {cloneCurrentBudgetLine} from './cbBudgetLineModalClone';
import {
	addAllocatedBudgetLine,
	deleteAllocatedLine,
	fillInAllocatedAmounts,
	fillInBudgetLineFromAllocation,
	getAllocatedBudgetLines,
	handleAllocatedBudgetLine,
	handleAllocatedPercent,
	recalculateAllocationLine,
	saveAllocatedBudgetLines,
} from './cbBudgetLineModalAllocation';
import {getProcessedAmounts} from './cbBudgetLineModalAmounts';
import {getYTDAmounts} from './cbBudgetLineModalYTD';
import {
	changeFormula,
	deleteValueFromLegend,
	initSetup,
	passEditableToNFLItems,
	passToLegend,
	validateFormula
} from './cbBudgetLineModalSettings';

export default class CbBudgetLineModal extends NavigationMixin(LightningElement) {

	@api recordId; // Id of current budget line
	@track customPermissions;// list of custom permissions
	get periods() {
		return JSON.parse(localStorage.getItem('periods'));
	};

	@track selectOptionMap = {};
	layers = [];
	@track NFLMap = {};
	@track showRevisionDialog = false;
	@track sourceCatalog = []; // catalog of NFL items
	@track activeSections = []; // opened NFL accordion parts
	@track libsLoaded = false;
	@track showBudgetLineContent = false;
	@track showSpinner = false;
	@track budgetLine = {lines: [], yearlyTotal: 0, Name: 'N/A'}; //
	@track originalBudgetLine; //
	@track formula = '';
	@track complexLine = {Name: 'Test', yearlyTotal: 0, lines: [], show: false};

	get displayGroupId() {// default BY;
		return this.budgetLine && this.budgetLine.cblight__CBBudgetYear__c ? this.budgetLine.cblight__CBBudgetYear__c : localStorage.getItem('cblight__CBBudgetYear__c');
	}

	@track periodGroups = [];// list of BY in the budget line dialog window
	@track orgVariable = {};// global org variable with settings
	@track showAnalytics = true;
	@track showAllocation = false;
	@track functions = [];
	@track formulaWarning = {class: 'formulaValid', message: '✓ Valid'};
	@track allocationSummary = {cblight__CBAmounts__r: []};
	@track showYTDAmounts = false;
	@track YTDAmounts = [];

	commonFormulas = ["#1 * #2", "#1 + #2", "#1 * #2 * (1 + #3)"];
	ACCOUNT_MISSED_MESSAGE = 'CB Account is missed';
	NFLNumbersArr = [1, 2, 3, 4, 5];
	showRedirectFromBL = {
		field1: false,
		field2: false,
		field3: false,
		field4: false,
		field5: false
	};

	FUNCTION_VARIABLE_FIELDS = [`CBAccount`, `CBDivision`, `CBVariable1`, `CBVariable2`, `CBVariable3`, `CBVariable4`, `CBVariable5`];
	FUNCTION_NFL_FIELDS = [`NFL1`, `NFL2`, `NFL3`, `NFL4`, `NFL5`, `NFLFormula`];
	BUDGET_LINE_ANALYTIC_NAMES = ['cblight__CBAccount__c', 'cblight__CBDivision__c', 'Name', 'cblight__CBVariable1__c', 'cblight__CBVariable2__c', 'cblight__Description__c', 'cblight__CBVariable3__c', 'cblight__CBVariable4__c', 'cblight__CBVariable5__c'];
	permissions;

	/**
	 * LWC DoInit
	 */
	async connectedCallback() {
		this.doInit();
	}

	doInit = async () => {
		this.showSpinner = true;
		await this.getSelectOptions();
		await this.getCustomPermissions();
		await this.getOrgVariable();
		if (this.orgVariable.cblight__NonFinancialLibIsUsing__c) {
			this.getFunctions();
			await initSetup(this);
		}
		await this.getBudgetLine();
		_applyDecStyle();
	};


	/**
	 * Getter for rendering the function menu
	 * @returns {boolean} - is rendered
	 */
	get showFunctionMenu() {
		return (this.orgVariable.cblight__NonFinancialLibIsUsing__c && !this.budgetLine.cblight__isFormulaBudgetLine__c && !this.budgetLine.cblight__isAllocation__c);
	}

	/**
	 * Getter for rendering the allocation button
	 * @returns {boolean} - is rendered
	 */
	get showAllocateBtn() {
		return (this.orgVariable.cblight__AllocationIsUsing__c && !this.budgetLine.cblight__isFormulaBudgetLine__c && !this.budgetLine.cblight__isAllocation__c);
	}

	/**
	 * Org variables for rendering
	 */
	getOrgVariable = async () => {
		await getOrgVariableServer()
			.then(variable => this.orgVariable = variable)
			.catch(e => _parseServerError('BLM : Org Variables Error : ', e))
	};

	/**
	 * Method gets "Select Options" from the server
	 */
	getSelectOptions = async () => {
		await getSelectOptionsServer()
			.then(selectOptionMap => this.selectOptionMap = selectOptionMap)
			.catch(e => _parseServerError(`Budget Line Modal : Get Select Options Callback Error: `, e));
	};

	/**
	 * Method gets "Functions" from the server
	 */
	getFunctions = async () => {
		await getFunctionsServer({type: 'NFL'})
			.then(functions => this.functions = functions)
			.catch(e => _parseServerError("BL Modal : Get Function Error: ", e));
	};

	/**
	 * Method takes the budget line from the server
	 */
	getBudgetLine = async () => {
		try {
			this.showSpinner = true;
			if (!this.recordId) {
				this.setNewBudgetLine();
				return null;
			}
			await getBudgetLineServer({budgetLineId: this.recordId})
				.then(async (budgetLine) => {
					try {
						if (!budgetLine || budgetLine.length === 0) {
							_message('warning', 'Budget Line was deleted or you do not have access to the budget line');
							setTimeout(() => {
								this.refreshTable();
								this.closeBudgetLineModal();
							}, 10);
							return;
						}
						this.makeSyntheticNFLTitles(budgetLine[0]);
						await this.getNFLMap(budgetLine[0]);
						budgetLine = _getCopy(budgetLine[0]);
						this.periodGroups = getPeriodGroups();
						this.budgetLine = budgetLine;
						if (budgetLine.cblight__isFormulaBudgetLine__c) validateFormula(budgetLine.cblight__NFLFormula__c);
						this.budgetLine.amountObject = getProcessedAmounts(this);
						this.originalBudgetLine = _getCopy(this.budgetLine);
						if (budgetLine.cblight__isAllocation__c) {
							getAllocatedBudgetLines(this);
						}
						setTimeout(() => {
							this.showBudgetLineContent = true;
							this.showSpinner = false;
						}, 10);
					} catch (e) {
						_message('error', `Budget Line Modal : Get Budget Line Callback Error: ${e}`);
					}
				})
				.catch(e => _parseServerError("Budget Line Modal : Get List Of Budget Lines Error: ", e))
				.finally(() => {
					this.showSpinner = false;
				});
		} catch (e) {
			_message('error', `BLM : Get Budget Line Error: ${e}`);
		}
	};

	/**
	 * Method creates synthetic titles for NFLs
	 * @param budgetLine - current budget line
	 */
	makeSyntheticNFLTitles(budgetLine) {
		for (let i = 1; i <= 5; i++) {
			try {
				if (budgetLine['cblight__NFL' + i + '__r']) {
					budgetLine['cblight__NFLTitle' + i + '__c'] = budgetLine['cblight__NFL' + i + '__r'].Name + ' (' + budgetLine['cblight__NFL' + i + '__r'].cblight__Layer__r.Name + ')';
				}
			} catch (e) {
				console.error(e);
			}
		}
	}

	getNFLMap = async (budgetLine) => {
		let nflIdList = [];
		[1, 2, 3, 4, 5].forEach((index) => {
			const NFLId = budgetLine[`cblight__NFL${index}__c`];
			if (NFLId && !this.NFLMap[NFLId]) {
				nflIdList.push(NFLId);
			}
		});
		if (nflIdList.length === 0) return;
		await getLibrariesFromBudgetLineServer({nflIdList})
			.then(nflList => {
				let nflMap = this.NFLMap;
				nflList.forEach(nfl => nflMap[nfl.Id] = nfl);
				passEditableToNFLItems(Object.values(nflMap));
				this.NFLMap = nflMap;
			})
			.catch(e => _parseServerError("Budget Line Modal : getNFLMap Error: ", e))
			.finally(() => this.showSpinner = false);
	};

	/**
	 * List of custom permissions to display or hide some functions
	 */
	getCustomPermissions = async () => {
		this.customPermissions = await _getCustomPermissions();
	};

	/**
	 * Method creates a new budget line if Id not specified
	 */
	setNewBudgetLine() {
		try {
			this.periodGroups = getPeriodGroups();
			const newBlParameters = JSON.parse(localStorage.getItem('newBlParameters'));
			this.budgetLine = {
				cblight__CBAmounts__r: [],
				Name: 'New',
				cblight__isTopdown__c: localStorage.getItem('selectedApproach') === 'topdown',
				Owner: {Name: 'N/A'}
			};
			this.budgetLine = Object.assign(this.budgetLine, newBlParameters);
			localStorage.removeItem('newBlParameters');
			this.budgetLine.amountObject = getProcessedAmounts(this);
			setTimeout(() => {
				this.showBudgetLineContent = true;
				this.showSpinner = false;
			}, 10);
		} catch (e) {
			_message('error', `Budget Line Modal : setNewBudgetLine Error: ${e}`);
		}
	}


	/**
	 * The method saves a budget line from the dialog window
	 */
	async saveBudgetLine() {
		try {
			if (this.formulaWarning.class !== 'formulaValid') {
				_message('warning', 'Please enter a valid formula before saving');
				return null;
			}
			const budgetLine = this.budgetLine;
			await this.getNFLMap(budgetLine);
			budgetLine.Name = budgetLine.Name.slice(0, 80);
			if (!budgetLine.cblight__CBAccount__c) {
				_message('warning', this.ACCOUNT_MISSED_MESSAGE);
				this.budgetLine.cblight__isAllocation__c = false;
				return null;
			}
			this.showSpinner = true;
			this.showBudgetLineContent = false;
			budgetLine.amountObject = getProcessedAmounts(this);
			this.saveCustomNFLItems(budgetLine);
			budgetLine.cblight__Value__c = this.budgetLine.amountObject.getGlobalBLTotal();
			const amounts = budgetLine.amountObject.wholeAmounts;
			_deleteFakeId(amounts);
			delete budgetLine.cblight__CBAmounts__r;
			delete budgetLine.amountObject;
			if (budgetLine.Owner.Name === 'N/A') {
				delete budgetLine.Owner;
			}
			if (!budgetLine.cblight__CBBudgetYear__c) budgetLine.cblight__CBBudgetYear__c = localStorage.getItem("cblight__CBBudgetYear__c"); //budgetYearId
			if (this.orgVariable.cblight__ScenarioIsUsing__c) budgetLine.cblight__CBScenario__c = localStorage.getItem("cblight__CBScenario__c"); //scenario
			if (budgetLine.cblight__ChildrenBudgetLines__r) {
				saveAllocatedBudgetLines();
			}
			saveBudgetLineServer({budgetLine, amounts})
				.then(budgetLine => {
					try {
						this.recordId = budgetLine[0].Id;
						this.refreshTable();
						this.connectedCallback();
						_message('success', 'Saved');
					} catch (e) {
						_message('error', 'BLM: Save Budget Line Callback Error: ' + e);
					}
				})
				.catch(e => {
					_parseServerError(`BLM : Saving Error : `, e);
					this.closeBudgetLineModal();
				})
				.finally(() => {
				});
		} catch (e) {
			_message('error', `BLM : Saving Error: ${e}`);
		}
	}

	/**
	 * If BL has custom items it must be saved
	 */
	saveCustomNFLItems = (budgetLine) => {
		try {
			if (budgetLine.amountObject.wholeNFLibs && budgetLine.amountObject.wholeNFLibs.length > 0) {
				let wholeNFLItems = [];
				budgetLine.amountObject.wholeNFLibs.forEach(nflArray => {
					if (nflArray) wholeNFLItems = [...wholeNFLItems, ...nflArray];
				});
				updateNonFinancialItemsServer({items: wholeNFLItems}).catch(serverError => _parseServerError('BLM : Save NFL Items Callback Error: ', serverError));
			}
		} catch (e) {
			_message('error', 'BLM : Save NFL Items Error: ' + e);
		}
	};

	/**
	 * Custom event from a cbRevision component, restore History values for Bl or Amount fields
	 */
	restoreData = (event) => {
		try {
			const rev = event.detail;
			switch (rev.Field) {
				case "cblight__Value__c":
					this.budgetLine.amountObject.wholeAmounts.forEach((amount) => {
						if (amount.Id === rev.ParentId) {
							amount.cblight__Value__c = rev.OldValue;
							this.budgetLine.amountObject.wholeAmounts =
								this.budgetLine.amountObject.setDisplayedItems(
									this.budgetLine.amountObject.wholeAmounts
								);
							this.budgetLine.amountObject.calculateYearlyTotal();
							this.budgetLine.amountObject.getGlobalBLTotal();
						}
					});
					break;
				case "Name":
				case "cblight__Description__c":
					this.budgetLine[rev.Field] = rev.OldValue ? rev.OldValue : '';
					break;
				default:
					this.budgetLine[rev.Field] = rev.OldValueId ? rev.OldValueId : '';
					break;
			}
			_message("success", "Restored");
		} catch (e) {
			_message("error", "Budget Line Modal : Restore Data Error: " + e);
		}
	};

	/////// REVISION ///////

	/**
	 * This method deletes budget line
	 */
	deleteBudgetLine() {
		if (!confirm('Are you sure?')) {
			return null;
		}
		this.showSpinner = true;
		const deleteCallback = () => {
			_message('success', 'Deleted');
			this.showSpinner = false;
			this.closeBudgetLineModal();
			this.refreshTable();
		};
		if (this.budgetLine.Id) {
			deleteBudgetLineServer({budgetLineId: this.budgetLine.Id})
				.then(() => deleteCallback())
				.catch(e => {
					_parseServerError('BLM : Deleting Error ', e);
					this.showSpinner = false;
					this.closeBudgetLineModal();
				});
		} else {
			deleteCallback();
		}
	}

	/**
	 * Method refresh the base table in the parent component
	 */
	refreshTable = () => {
		this.dispatchEvent(new CustomEvent('refreshTable', {
			bubbles: true,
			composed: true,
			detail: '_'
		}))
	};

	/**
	 * Handler to change formula in the setup panel
	 */
	changeFormula(event) {
		changeFormula(event);
	}

	/**
	 * Event for parent component to close the Budget Line modal window
	 */
	closeBudgetLineModal() {
		this.dispatchEvent(new CustomEvent('closeBudgetLineModal', {
			bubbles: true,
			composed: true,
			detail: '_'
		}));
	}

	displayYTDAmounts = () => {
		this.YTDAmounts = getYTDAmounts(this.budgetLine.amountObject.wholeAmounts);
		this.showYTDAmounts = !this.showYTDAmounts;
	};

	/////////// HANDLERS /////////
	/**
	 * Handler for icon button. Converts the current simple budget line to the formula budget line
	 */
	convertSimpleLineToFormulaLine = () => {
		if (!this.budgetLine.cblight__CBAccount__c) {
			_message('warning', this.ACCOUNT_MISSED_MESSAGE);
			return null;
		}
		this.budgetLine.cblight__isFormulaBudgetLine__c = true;
		this.saveBudgetLine();
	};

	convertSimpleLineToFormulaLineAndApplyFunction = (event) => {
		if (!this.budgetLine.cblight__CBAccount__c) {
			_message('warning', this.ACCOUNT_MISSED_MESSAGE);
			return null;
		}
		this.budgetLine.cblight__isFormulaBudgetLine__c = true;
		const func = this.functions.find(f => f.Id === event.target.value);
		this.applyNFLFunction({detail: func});
		this.saveBudgetLine();
	};

	selectWhole = (event) => _selectWholeValue(event);

	/**
	 * Handler for icon button. Converts the current simple budget line to the formula budget line
	 */
	convertSimpleLineToAllocationLine() {
		if (!confirm("Are you sure? This action cannot be reversed.")) return null;
		this.budgetLine.cblight__isAllocation__c = true;
		this.saveBudgetLine();
	}

	/**
	 * Reaction for changing data in the budget line dialog window
	 */
	handleBudgetLine = (event) => {
		try {
			const eventId = event.target.name ? event.target.name : event.target.fieldName;// field type
			if (this.BUDGET_LINE_ANALYTIC_NAMES.includes(eventId)) {
				this.budgetLine[eventId] = event.target.value;
			} else {
				this.budgetLine.amountObject.applyNewValue(eventId, event.target.value ? event.target.value : 0);
				this.budgetLine.amountObject.calculateYearlyTotal();
				this.budgetLine.cblight__Value__c = this.budgetLine.amountObject.getGlobalBLTotal();
				this.budgetLine.cblight__CBAmounts__r = this.budgetLine.amountObject.wholeAmounts;
			}
		} catch (e) {
			_message('error', 'BL: Handle Budget Line Error: ' + e);
		}
	};

	handleAllocatedBudgetLine = (event) => {
		handleAllocatedBudgetLine(event);
	};
	handleAllocatedPercent = (event) => {
		handleAllocatedPercent(event);
	};

	addAllocatedBudgetLine = () => {
		addAllocatedBudgetLine();
	};

	fillInBudgetLineFromAllocation = () => {
		fillInBudgetLineFromAllocation();
	};

	fillInAllocatedAmounts = () => {
		fillInAllocatedAmounts();
	};

	redirectToParent = () => {
		this.recordId = this.budgetLine.cblight__ParentBudgetLine__c;
		this.showBudgetLineContent = false;
		this.connectedCallback();
	};
	redirectToAllocatedBL = (event) => {
		if (_isFakeId(event.target.value)) {
			_message('warning', 'This budget line was not saved');
			return null;
		}
		this.showBudgetLineContent = false;
		this.recordId = event.target.value;
		this.connectedCallback();
	};

	/**
	 * Method deletes allocated budget line
	 */
	deleteAllocatedBL = (event) => {
		if (!confirm('Are you sure?')) {
			return null;
		}

		const blId = event.target.value;
		const deleteCallback = () => {
			_message('success', 'Deleted');
			this.showSpinner = false;
			deleteAllocatedLine(blId);
			this.refreshTable();
		};

		if (_isFakeId(blId)) {
			deleteCallback();
		} else {
			this.showSpinner = true;
			deleteBudgetLineServer({budgetLineId: blId})
				.catch(e => _message('error', 'BLM : Deleting Error ' + JSON.stringify(e)))
				.finally(() => deleteCallback());
		}
	};

	/**
	 * Method clones current budget line to a new one
	 */
	async cloneBudgetLine() {
		if (!confirm('Are you sure?')) return;
		await cloneCurrentBudgetLine(this);
		this.saveBudgetLine();
		_message('success', 'Cloned');
	}

	redirectToNFL(event) {
		try {
			this[NavigationMixin.GenerateUrl]({
				type: 'standard__recordPage',
				attributes: {
					recordId: event.target.value,
					objectApiName: 'cblight__CBNonFinancialLibrary__c',
					actionName: 'view'
				}
			}).then(url => {
				window.open(url, "_blank");
			});
		} catch (e) {
			_message('error', 'BLM : Redirect to NFL Error : ' + e);
		}
	}

	handleBudgetTab = () => {
		this.showAnalytics = true;
	};
	handleFormulaSettingTab = () => {
		this.showAnalytics = false;
	};

	/**
	 * Handler for working with NFL values of a budget line.
	 */
	handleCustomNFLChange = (event) => {
		try {
			const itemId = event.target.name;
			const value = event.target.value;
			this.budgetLine.amountObject.applyNewValue(itemId, value);
			this.budgetLine.amountObject.calculateAmountsFromNFLibs();
			this.budgetLine.amountObject.calculateYearlyTotal();
			this.budgetLine.cblight__Value__c = this.budgetLine.amountObject.getGlobalBLTotal();
			this.budgetLine.cblight__CBAmounts__r = this.budgetLine.amountObject.wholeAmounts;
		} catch (e) {
			_message('error', 'BLM : Handle Custom NFL Change Error : ' + e);
		}
	};

	applyAutoFormula = (event) => {
		let budgetLine = _getCopy(this.budgetLine);
		budgetLine.cblight__NFLFormula__c = event.target.value;
		validateFormula(budgetLine.cblight__NFLFormula__c);
		this.budgetLine = budgetLine;
	};

	handleSectionToggle(event) {
		const openSections = event.detail.openSections;
		openSections.forEach((section) => {
			const components = this.template.querySelectorAll('c-cb-nfl-selector');
			components.forEach((component) => {
				if (component.name === section) {
					component.loadLatestNFL();
				}
			});
		});
	}

/////////// HANDLERS /////////

	/// DRAG AND DROP
	NFLLine;
	legendIndex;

	/**
	 * Budget line was over some cell
	 */
	allowDrop(event) {
		try {
			event.preventDefault();
			if (event.target.label) {
				this.legendIndex = event.target.label;
			}
		} catch (e) {
			_message('error', `BLM : Allow Drop Error : ${e}`);
		}
	}

	/**
	 * Budget line dropped
	 */

	drop(event) {
		event.stopPropagation();
		event.preventDefault();
		this.checkIfThereAndPass();
	}

	checkIfThereAndPass() {
		try {

			if (!this.NFLLine || !this.legendIndex) return null;
			for (let i of this.NFLNumbersArr) {
				if (this.NFLLine.Id === this.budgetLine[`cblight__NFL${i}__c`]) {
					_message('info', null, 'This data is already in the legend.');
					return null;
				}
			}
			passToLegend(this.NFLLine, this.legendIndex);
		} catch (e) {
			_message('error', `checkIfThereAndPass Error : ${e}`);
		}
	}

	lineClicked(event) {
		try {
			const line = JSON.parse(event.detail.line);
			this.NFLLine = line;
			for (let i of this.NFLNumbersArr) {
				if (!this.budgetLine[`cblight__NFL${i}__c`]) {
					this.legendIndex = i;
					break;
				}
			}
			this.checkIfThereAndPass();
		} catch (e) {
			_message('error', `BLM :Drop Error : ${e}`);
		}
	}

	lineDragged(event) {
		try {
			this.NFLLine = JSON.parse(event.detail.line);
		} catch (e) {
			_message('error', `BLM :Drop Error : ${e}`);
		}
	}

	/// DRAG AND DROP

	deleteLegendValue = (event) => {
		deleteValueFromLegend(event);
	};

	/**
	 * This function applies analytics from the selected Variable function
	 */
	applyVariableFunction = (event) => {
		try {
			const func = event.detail;
			if (!func) {
				return null;
			}
			this.FUNCTION_VARIABLE_FIELDS.forEach(ff => this.budgetLine[`cblight__${ff}__c`] = func[`cblight__${ff}__c`] ? func[`cblight__${ff}__c`] : null);
			_message('info', 'Applied', 'Note!');
		} catch (e) {
			_message('error', 'Budget Line Modal : Apply Variable Function Error : ' + e);
		}
	};

	/**
	 * This function applies NFL and Formulas from the selected NFL function
	 */
	applyNFLFunction = (event) => {
		try {
			const func = event.detail;
			if (!func) {
				_message('error', 'NO FUNCTION');
				return null;
			}
			this.FUNCTION_NFL_FIELDS.forEach(ff => this.budgetLine[`cblight__${ff}__c`] = func[`cblight__${ff}__c`] ? func[`cblight__${ff}__c`] : null);
			_message('info', 'Applied', 'Note!');
		} catch (e) {
			_message('error', 'Budget Line Modal : Apply NFL Function Error : ' + e);
		}
	};

	/**
	 * This functions is running by the child Function component event
	 * The function calls Function component method
	 */
	saveFunction = () => {
		this.template.querySelector('c-cb-function').saveFunction(JSON.stringify(this.budgetLine));
	};

	/**
	 * The method receives data from the CompleteAssistant component and apply them
	 */
	applyCompleteAmounts = (event) => {
		const firstAmount = event.detail.amounts[0];
		const bl = this.budgetLine;

		if (firstAmount.cblight__isFormulaBudgetLine__c || firstAmount.disabled) {
			_message('warning', 'Disabled amounts cannot be changed');
			return null;
		}

		if (bl.cblight__ChildrenBudgetLines__r && firstAmount.cblight__CBBudgetLine__c !== this.budgetLine.Id) {
			recalculateAllocationLine(event, this);
		}
		if (!firstAmount.cblight__CBBudgetLine__c || firstAmount.cblight__CBBudgetLine__c === bl.Id) { // firstAmount.cblight__CBBudgetLine__c = undefined for custom NFL
			event.detail.amounts.forEach(a => bl.amountObject.applyNewValue(a.Id, a.cblight__Value__c));
		}

		bl.amountObject.calculateAmountsFromNFLibs();
		bl.amountObject.calculateYearlyTotal();
		bl.cblight__Value__c = bl.amountObject.getGlobalBLTotal();
		bl.cblight__CBAmounts__r = bl.amountObject.wholeAmounts;
	};

	/////// DEVELOPERS DOOR /////////////
	showDevDoor = false;
	toggleDevDoor = () => {
		this.showDevDoor = !this.showDevDoor;
		this.lockEditingValue = this.budgetLine.cblight__Lock__c === 'Editing';
		this.lockDeletingValue = this.budgetLine.cblight__Lock__c === 'Deleting';
	};

	lockEditingValue = false;
	lockDeletingValue = false;

	handleLockEditing = event => {
		this.lockEditingValue = event.target.checked;
		this.lockDeletingValue = false;
		this.budgetLine.cblight__Lock__c = this.lockEditingValue ? 'Editing' : null;
	};

	handleLockDeleting = event => {
		this.lockDeletingValue = event.target.checked;
		this.lockEditingValue = false;
		this.budgetLine.cblight__Lock__c = this.lockDeletingValue ? 'Deleting' : null;
	};

	/////// DEVELOPERS DOOR /////////////

	constructor() {
		super();
		this.addEventListener('restoreData', this.restoreData); // Listener from the Revision component
		//this.addEventListener('closerevisionmodal', this.closeRevisionDialog); // Listener from the Revision component
		this.addEventListener('applyVariableFunction', this.applyVariableFunction); // Listener from the Variable Function component
		this.addEventListener('applyNFLFunction', this.applyNFLFunction); // Listener from the NFL Function component
		this.addEventListener('saveFunction', this.saveFunction); // Listener from the Function component
	}

	redirectToNFL(event) {
		const index = event.target.value;
		const nflId = this.budgetLine[`cblight__NFL${index}__c`];
		if (nflId) {
			this[NavigationMixin.GenerateUrl]({
				type: 'standard__recordPage',
				attributes: {
					recordId: nflId,
					objectApiName: 'cblight__CBNonFinancialLibrary__c',
					actionName: 'view'
				}
			}).then(url => {
				window.open(url, "_blank");
			});
		}
	}

	/*openRevisionDialog() {
		this.showRevisionDialog = true;
	}


	closeRevisionDialog() {
		this.showRevisionDialog = false;
	}*/


}


/**
 * Service class to store group of budget lines with the common status
 */
function SourceGroup() {
	this.lines = [];
	this.title = '';
}