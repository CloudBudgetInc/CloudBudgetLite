import {LightningElement, track} from "lwc";
import {_applyDecStyle, _cl, _deleteFakeId, _message, _parseServerError} from "c/cbUtils";
import {generateGlobalStructure} from "./cbBudgetLineManagerHelper";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import getSelectOptionsServer from "@salesforce/apex/CBBudgetLinePageController.getSelectOptionsServer";
import getBudgetLinesServer from "@salesforce/apex/CBBudgetLinePageController.getBudgetLinesServer";
import getClusterRuleServer from "@salesforce/apex/CBBudgetLinePageController.getClusterRuleServer";
import getPeriodsServer from "@salesforce/apex/CBBudgetLinePageController.getPeriodsServer";
import makeItemRecentServer from "@salesforce/apex/CBUtils.makeItemRecentServer";
import getSObjectFieldsDataServer from "@salesforce/apex/CBBudgetLinePageController.getSObjectFieldsDataServer";
import {setStyles, setStylesForClusters} from "./cbBudgetLineManagerStyles";
import {addLostAmountsIfNeeded} from "./cbBudgetLineManagerLineFunctions";
import getAccTypesWithStylesNamesServer
	from '@salesforce/apex/CBBudgetLinePageController.getAccTypesWithStylesNamesServer';
import saveBudgetLinesServer from '@salesforce/apex/CBBudgetLinePageController.saveBudgetLinesServer';
import limitIsReachedServer from '@salesforce/apex/CBBudgetLinePageController.limitIsReachedServer';
import getFunctionsServer from "@salesforce/apex/CBFunctionPageController.getFunctionsServer";
import saveFunctionServer from "@salesforce/apex/CBFunctionPageController.saveFunctionServer";
import {NavigationMixin} from 'lightning/navigation';
import deleteFunctionServer from "@salesforce/apex/CBFunctionPageController.deleteFunctionServer";

// sfdx force:source:deploy -m LightningComponentBundle
export default class CBBudgetLines extends NavigationMixin(LightningElement) {
	@track budgetLines = [];
	@track topdownBudgetLines = [];
	@track selectOptionMap = {};
	@track cblight__CBDivision__c;
	@track cblight__CBScenario__c;
	@track cblight__CBBudgetYear__c;
	@track cblight__CBAccount__c;
	@track cblight__CBVariable1__c;
	@track cblight__CBVariable2__c;
	@track cblight__CBVariable3__c;
	@track cblight__CBVariable4__c;
	@track cblight__CBVariable5__c;
	@track OwnerId;
	@track selectedMode;
	@track textFilter;
	@track cblight__CBClusterRule__c;
	@track periods;
	@track newLinesDisabled = false;
	@track tableIsReadyToRender = false;
	@track showWelcomeMat = false;
	@track modeOptions = [
		{value: "simple", label: "Simple"},
		{value: "detailed", label: "Detailed"}
	];
	@track allocationModeOptions = [
		{value: "onlyParents", label: "Source Only"},
		{value: "onlyChildren", label: "Sublines Only"}
	];
	@track approachOptions = [
		{value: "bottom-up", label: "Bottom-up"},
		{value: "topdown", label: "Topdown"}
	];
	@track selectedAllocationMode = 'onlyParents';
	@track selectedApproach = localStorage.getItem('selectedApproach') ? localStorage.getItem('selectedApproach') : "bottom-up";
	@track showSpinner = false;
	@track customLookupSelectOptions = [];
	@track globalCluster; // full object with all data
	@track complexFilterString = "";
	@track showComplexFilter = false;
	@track budgetLineSO = [{label: "Name", value: "Name"}];
	@track periodGroups = []; // list of BY in the budget line dialog window
	@track showMultiYearTabs = false;
	@track showMainFilters = false;
	@track displayGroupId; // opened budget year that displayGroupId
	@track BYPeriods;
	@track showBudgetLineModal = false;
	@track showBudgetLineCalculationRuleModal = false;
	@track selectedBudgetLineId; // budget line modal api record Id
	@track selectedBudgetLineCalculationRuleId; // budget line calculation rule modal api record Id
	@track showApprovalWindow = false;
	@track showGlobalSearchModal = false;
	@track showExcelWindow = false;
	@track showSummary = true;
	@track configurationMirror = '';
	@track functions = [];
	@track dynamicTabs = [];
	@track saveButton = false;
	@track budgetLineIdsToApproval = [];
	@track orgVariable = {};
	@track pageParameters = {};
	SERVER_PARAMETERS_MAPPING = {
		cblight__CBDivision__c: 'cblight__CBDivision__c',
		cblight__CBBudgetYear__c: 'cblight__CBBudgetYear__c',
		cblight__CBAccount__c: 'cblight__CBAccount__c',
		cblight__CBScenario__c: 'cblight__CBScenario__c',
		cblight__CBVariable1__c: 'cblight__CBVariable1__c',
		cblight__CBVariable2__c: 'cblight__CBVariable2__c',
		cblight__CBVariable3__c: 'cblight__CBVariable3__c',
		cblight__CBVariable4__c: 'cblight__CBVariable4__c',
		cblight__CBVariable5__c: 'cblight__CBVariable5__c',
		cblight__CBClusterRule__c: 'cblight__CBClusterRule__c',
		complexFilter: 'complexFilterString',
		textFilter: 'textFilter',
		allocationMode: 'selectedAllocationMode',
		approach: 'selectedApproach',
		OwnerId: 'OwnerId'
	};
	FILTER_LOOKUPS = [
		{bl: 'cblight__CBDivision__c', func: 'cblight__CBDivision__c'},
		{bl: 'cblight__CBAccount__c', func: 'cblight__CBAccount__c'},
		{bl: 'cblight__CBVariable1__c', func: 'cblight__CBVariable1__c'},
		{bl: 'cblight__CBVariable2__c', func: 'cblight__CBVariable2__c'},
		{bl: 'cblight__CBVariable3__c', func: 'cblight__CBVariable3__c'},
		{bl: 'cblight__CBVariable4__c', func: 'cblight__CBVariable4__c'},
		{bl: 'cblight__CBVariable5__c', func: 'cblight__CBVariable5__c'},
		{bl: 'OwnerId', func: 'cblight__CBOwner__c'}];
	@track PLACE_HOLDER = new Array(15);
	@track budgetLinesToSave = [];
	@track activeTabValue = 'simple';

	clusterRule = {};
	SObjectFieldsData = [];
	@track overSizeMode = false;
	@track overSizeAsked = false;
	OVER_SIZE_MESSAGE = 'The amount of data is too large to display budget details. Try using a less detailed cluster rule or a data filter. Click OK to continue or click Cancel if you want to continue the page loading';
	EXTRA_FIELDS_IN_BUDGET_LINE = ['cblight__CBAmounts__r', 'cblight__CBAccount__r', 'cblight__CBDivision__r', 'cblight__CBVariable1__r', 'cblight__CBVariable2__r', 'cblight__CBVariable3__r', 'cblight__CBVariable4__r', 'cblight__CBVariable5__r', 'cblight__CBBudgetYear__r', 'idx', 'yearlyTotal', 'percent', 'Owner', 'LastModifiedById', 'cblight__ParentBudgetLine__r'];

	//////// WELCOME /////////////
	openWelcome() {
		this.showWelcomeMat = true;
	}

	closeWelcomeMat = () => {
		this.showWelcomeMat = false;
	};

	//////// WELCOME /////////////

	get showTopdownSymbol() {
		return this.selectedApproach === "topdown";
	}

	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		document.title = "Budget Manager";
		localStorage.setItem('showAll', 'true');
		this.doInit().then(r => {

		});
	}

	doInit = async () => {
		this.tableIsReadyToRender = false;
		this.showSpinner = true;
		await setStyles();
		await setStylesForClusters();
		await this.getAccTypesWithStylesNames();
		await this.getOrgVariable();
		await this.checkBudgetLinesLiteLimit();
		await this.getPeriods();
		await this.getInitialSelectOptions();
		await this.getSObjectFieldsData();
		await this.getFunctions();
		await this.refreshTables();
		_applyDecStyle();
		this.saveButton = false;
		this.showSpinner = false;
	};

	/**
	 * Method refreshes summary and detail tables
	 */
	refreshTables = async () => {
		this.tableIsReadyToRender = false;
		if (!this.showExcelWindow) {
			this.showSpinner = true;
		}
		await this.getClusterRule();
		await this.getListOfBudgetLines();
		await this.getListOfTopdownBudgetLines();
		this.showSpinner = false;
		if (this.budgetLines.length === 0) {
			return;
		}
		this.globalCluster = generateGlobalStructure(this);
		if (!this.showExcelWindow) {
			this.tableIsReadyToRender = true;
		}
		this.budgetLinesToSave = [];
	};

	/**
	 * Org variables for rendering
	 */
	getOrgVariable = async () => {
		await getOrgVariableServer()
			.then(variable => {
				if (!variable) {
					variable = {
						cblight__ScenarioIsUsing__c: false,
						cblight__AllocationIsUsing__c: false,
						cblight__TopdownModeIsUsing__c: false,
						cblight__DisplayBLMNavigation__c: false
					}
				}
				localStorage.removeItem('orgVariable');
				localStorage.setItem('orgVariable', JSON.stringify(variable));
				this.orgVariable = variable;
			})
			.catch(e => _parseServerError('BLM : Org Variables Error : ', e))
	};

	/**
	 * The method pulls the list of SelectOptions and run the page initialization
	 */
	async getInitialSelectOptions() {
		this.showSpinner = true;
		await getSelectOptionsServer()
			.then(selectOptionMap => {
				const selectOpt = {
					cblight__CBAccount__c: 'cblight__CBAccountLabel__c',
					cblight__CBBudgetYear__c: 'cblight__CBBudgetYearLabel__c',
					cblight__CBDivision__c: 'cblight__CBDivisionLabel__c',
					cblight__CBVariable1__c: 'cblight__CBVariable1Label__c',
					cblight__CBVariable2__c: 'cblight__CBVariable2Label__c',
					cblight__CBVariable3__c: 'cblight__CBVariable3Label__c',
					cblight__CBVariable4__c: 'cblight__CBVariable4Label__c',
					cblight__CBVariable5__c: 'cblight__CBVariable5Label__c'
				};
				selectOptionMap.budgetLineFieldSO.forEach(item => {
					for (const key in selectOpt) {
						if (item.value === key) {
							for (const org in this.orgVariable) {
								if (selectOpt[key] === org) {
									item.label = this.orgVariable[org];
								}
							}
						}
					}
				});
				this.selectOptionMap = selectOptionMap;
				this.specifyDefaultHeaderFilters();
			})
			.catch(e => {
				_parseServerError('BLM : Get Initial Select Options Error', e);
				this.showSpinner = false;
			});
	}

	/**
	 * Default Budget Year and Division in the Budget Line header
	 */
	specifyDefaultHeaderFilters() {
		try {
			const cblight__CBBudgetYear__c = localStorage.getItem("cblight__CBBudgetYear__c");
			const cblight__CBDivision__c = localStorage.getItem("cblight__CBDivision__c");
			const cblight__CBAccount__c = localStorage.getItem("cblight__CBAccount__c");
			const cblight__CBClusterRule__c = localStorage.getItem("cblight__CBClusterRule__c");
			const cblight__CBScenario__c = localStorage.getItem("cblight__CBScenario__c");
			const complexFilter = localStorage.getItem("complexFilter");
			const cblight__CBVariable1__c = localStorage.getItem("cblight__CBVariable1__c");
			const cblight__CBVariable2__c = localStorage.getItem("cblight__CBVariable2__c");
			const cblight__CBVariable3__c = localStorage.getItem("cblight__CBVariable3__c");
			const cblight__CBVariable4__c = localStorage.getItem("cblight__CBVariable4__c");
			const cblight__CBVariable5__c = localStorage.getItem("cblight__CBVariable5__c");
			const OwnerId = localStorage.getItem("OwnerId");
			if (!this.selectOptionMap || !this.selectOptionMap.budgetYearSO || this.selectOptionMap.clusterRuleSO.length === 0) {
				_message('warning', 'Please configure "Budget Year" and "Cluster Rule" records before using the Budget Lines manager.', 'The organization is not configured, ask your Admin for help.');
				return;
			}
			if (this.orgVariable.cblight__ScenarioIsUsing__c) {
				if (!this.selectOptionMap.scenarioSO || this.selectOptionMap.scenarioSO.length === 0) {
					_message('warning', 'Please configure a "Scenario" record before using the Budget Lines manager.', 'The organization is not configured, ask your Admin for help. ');
					return;
				}
				this.cblight__CBScenario__c = cblight__CBScenario__c ? cblight__CBScenario__c : this.selectOptionMap.scenarioSO[0].value;
				localStorage.setItem("cblight__CBScenario__c", this.cblight__CBScenario__c);
			}
			this.cblight__CBBudgetYear__c = cblight__CBBudgetYear__c ? cblight__CBBudgetYear__c : this.selectOptionMap.budgetYearSO[0].value;
			this.cblight__CBDivision__c = cblight__CBDivision__c ? cblight__CBDivision__c : '';
			this.cblight__CBAccount__c = cblight__CBAccount__c ? cblight__CBAccount__c : '';
			this.cblight__CBVariable1__c = cblight__CBVariable1__c ? cblight__CBVariable1__c : '';
			this.cblight__CBVariable2__c = cblight__CBVariable2__c ? cblight__CBVariable2__c : '';
			this.cblight__CBVariable3__c = cblight__CBVariable3__c ? cblight__CBVariable3__c : '';
			this.cblight__CBVariable4__c = cblight__CBVariable4__c ? cblight__CBVariable4__c : '';
			this.cblight__CBVariable5__c = cblight__CBVariable5__c ? cblight__CBVariable5__c : '';
			this.OwnerId = OwnerId ? OwnerId : '';
			this.cblight__CBClusterRule__c = cblight__CBClusterRule__c ? cblight__CBClusterRule__c : this.selectOptionMap.clusterRuleSO[0].value;
			this.complexFilterString = complexFilter ? complexFilter : '';
			localStorage.setItem("cblight__CBBudgetYear__c", this.cblight__CBBudgetYear__c);
			localStorage.setItem("cblight__CBClusterRule__c", this.cblight__CBClusterRule__c);
		} catch (e) {
			_message('error', `BLM : Specify Default Header Filters Error: ${e}`, 'Error');
		}
	}

	handleChangeSimpleFilter(event) {
		this.handlePageEvent(event);
	}

	/** Refresh the main table*/
	applySimpleFilter(event) {
		this.showSpinner = true;
		this.complexFilterString = '';
		localStorage.removeItem('complexFilter');
		if (event.target.name) this.handlePageEvent(event);
		this.refreshTables().then(r => {
		});
	}

	/** Reset the main table*/
	resetSimpleFilter() {
		this.showSpinner = true;
		let resetParametrMapping = {
			cblight__CBDivision__c: 'cblight__CBDivision__c',
			cblight__CBAccount__c: 'cblight__CBAccount__c',
			cblight__CBVariable1__c: 'cblight__CBVariable1__c',
			cblight__CBVariable2__c: 'cblight__CBVariable2__c',
			cblight__CBVariable3__c: 'cblight__CBVariable3__c',
			cblight__CBVariable4__c: 'cblight__CBVariable4__c',
			cblight__CBVariable5__c: 'cblight__CBVariable5__c',
			OwnerId: 'OwnerId',
			textFilter: 'textFilter'
		};
		Object.values(resetParametrMapping).forEach(selector => {
			this[selector] = "";
			localStorage.setItem(selector, "");
		});
		this.refreshTables().then(r => {
		});
	}

	/**
	 * Complex field filters list ob budget lines
	 */
	applyComplexFilter(event) {
		this.complexFilterString = event.detail.result.length > 0 ? ` ( ${event.detail.result} ) ` : "";
		this.showSpinner = true;
		this.FILTER_LOOKUPS.forEach(element => {
			this[element.bl] = '';
			localStorage.setItem(element.bl, this[element.bl]);
		});
		localStorage.setItem('complexFilter', this.complexFilterString);
		this.refreshTables().then(r => {
		});
	}

	tabInitialization = true;

	/**
	 * Handler ot the simple filter tab
	 */
	setSimpleFilter(event) {
		this.resetConfiguration();
		try {
			if (this.tabInitialization) { // prevent of initial run
				this.tabInitialization = false;
				return null;
			}
			this.showComplexFilter = false;
		} catch (e) {
			_message('error', `BLM : Set Simple Filter Error: ${e} `);
		}
	}

	/**
	 * Handler ot the complex filter tab
	 */
	setComplexFilter() {
		this.resetConfiguration();
		this.showComplexFilter = true;
	}

	/**
	 * The method gets cluster rule and prepare data to display
	 */
	getClusterRule = async () => {
		try {
			const params = this.getPageHeaderParameters();
			if (!params.cblight__CBClusterRule__c) {
				_message('warning', 'Please configure a "Cluster Rule" record before using the Budget Lines manager.', 'The organization is not configured, ask your Admin for help.');
				return null;
			}
			const tryToGetClusterRule = async () => {
				await getClusterRuleServer({params})
					.then(cr => {
						if (!cr) { // if cr was deleted, use first cr in the list
							params.cblight__CBClusterRule__c = this.selectOptionMap.clusterRuleSO[0].value;
							localStorage.setItem("cblight__CBClusterRule__c", params.cblight__CBClusterRule__c);
							this.cblight__CBClusterRule__c = params.cblight__CBClusterRule__c;
							tryToGetClusterRule();
						}
						localStorage.setItem("CBClusterRule", JSON.stringify(cr));
						this.clusterRule = cr
					})
					.catch(e => _parseServerError("Get Cluster Rule Error: ", e))
			};
			await tryToGetClusterRule();
		} catch (e) {
			_message('error', `Get ClusterRule Error: " + ${e}`);
		}
	};

	/**
	 * The main method to get list of budget lines from the server
	 */
	getListOfBudgetLines = async () => {
		_cl("**GET LIST OF BUDGET LINES**", "green");
		this.tableIsReadyToRender = false;
		this.globalCluster = {};
		this.budgetLines = [];
		this.overSizeMode = false;
		const params = this.getPageHeaderParameters();
		try {
			await getBudgetLinesServer({params})
				.then(budgetLines => this.manageBudgetLines(budgetLines))
				.catch(e => {
					_parseServerError('BLM : Get List Of Budget Lines Error', e);
					this.showSpinner = false; // do not move to final
				});
		} catch (e) {
			_message('error', `BLM : Get List Of Budget Lines Error ${e}`);
		}
	};
	/**
	 * Method serves to process budget lines right after server before the BLM structure
	 */
	manageBudgetLines = async (budgetLines) => {
		try {
			if (!budgetLines) return;
			if (!this.showExcelWindow && (budgetLines.length > this.orgVariable.cblight__MaxNumberOfDisplayedLines__c)) {
				if (confirm(this.OVER_SIZE_MESSAGE)) {
					this.overSizeMode = true;
				}
			}
			if (!budgetLines || budgetLines.length === 0 || budgetLines === []) {
				if (!this.showExcelWindow) {
					_message('info', 'There are no lines matching the filter criteria');
				}
				this.showSpinner = false;
				return null;
			}
			this.checkBudgetLinesWarnings(budgetLines);
			this.setBYPeriods(this.periods, this.cblight__CBBudgetYear__c);
			addLostAmountsIfNeeded(budgetLines);
			this.budgetLines = budgetLines;
		} catch (e) {
			_message('error', `BLM : Get Budget Lines Callback Error ${e}`);
		}
	};

	/**
	 * Method checks if BL has warnings
	 */
	checkBudgetLinesWarnings(budgetLines) {
		if (budgetLines.some((line) => line.cblight__WarningMessage__c && line.cblight__WarningMessage__c.length > 0)) {
			_message('warning', `Please, check Budget Lines: One or more lines have warnings!`);
		}
	}

	getListOfTopdownBudgetLines = async () => {
		if (!this.orgVariable.cblight__TopdownModeIsUsing__c || this.selectedApproach !== 'bottom-up') return null;
		_cl("**GET LIST OF TOPDOWN BUDGET LINES**", "green");
		const params = this.getPageHeaderParameters();
		params.approach = 'topdown';
		try {
			await getBudgetLinesServer({params})
				.then(topdownBudgetLines => this.topdownBudgetLines = topdownBudgetLines)
				.catch(e => _parseServerError('BLM : Get List Of Topdown Budget Lines Error', e));
		} catch (e) {
			_message('error', `BLM : Get List Of Topdown Budget Lines Error ${e}`);
		}
	};

	setBYPeriods() {
		const relevantPeriods = this.periods.filter(period =>
			period.cblight__CBBudgetYear__c === this.cblight__CBBudgetYear__c ||
			period.cblight__CBBudgetYearSet__c === this.cblight__CBBudgetYear__c
		);
		this.BYPeriods = relevantPeriods;
		localStorage.setItem('BYPeriods', JSON.stringify(relevantPeriods));
	}

	/**
	 * the method handles changing page filters
	 */
	handlePageEvent(event) {
		try {
			Object.values(this.SERVER_PARAMETERS_MAPPING).forEach(selector => {
				if (event.target.name === selector) {
					this[selector] = event.target.value;
					this.makeItemRecent(event.target.value);
					localStorage.setItem(selector, event.target.value);
				}
			});
		} catch (e) {
			_message('error', `BLM : Handle event ERROR: ${e}`);
		}
	}

	/**
	 * The method returns page header parameters for the server request
	 * @return {object}
	 */
	getPageHeaderParameters() {
		this.pageParameters = this.getFilterObject();
		return this.pageParameters;
	}

	/**
	 * Method gets header filter variables and create an object for server
	 */
	getFilterObject() {
		return Object.entries(this.SERVER_PARAMETERS_MAPPING).reduce((acc, [key, value]) => {
			acc[key] = this[value];
			return acc;
		}, {});
	}

	getPeriods = async () => {
		await getPeriodsServer()
			.then(periods => {
				localStorage.setItem("periods", JSON.stringify(periods));
				this.periods = periods;
			})
			.catch(e => _parseServerError("BLM : Get Period Error: ", e));
	};

	/**
	 * The method get Budget Line SObject fields data such as type, name, label etc.
	 */
	getSObjectFieldsData = async () => {
		await getSObjectFieldsDataServer()
			.then(SObjectFieldsData => {
				const replaceMap = {};
				if (!this.orgVariable || !this.orgVariable.cblight__CBAccountLabel__c) {
					_message('warning', `Please configure the "Org Variable" record before using the Budget Lines manager.`, "The organization is not configured, ask your Admin for help.");
					return null;
				}
				Object.keys(this.orgVariable).forEach(key => replaceMap[key.replace('Label', '')] = this.orgVariable[key]);
				SObjectFieldsData.forEach(so => so.label = replaceMap[so.value] ? replaceMap[so.value] : so.label);
				this.SObjectFieldsData = SObjectFieldsData;
				this.showMainFilters = true;
			})
			.catch(e => _parseServerError("Get SObject Fields Data Error: ", e));
	};

	checkBudgetLinesLiteLimit = async () => {
		await limitIsReachedServer()
			.then(r => localStorage.setItem('newLinesDisabled', '' + r))
			.catch(e => _parseServerError('BLM : Check BL Limit Server Error', e));
	};

	/**
	 * Method gets full list of AccTypes With Styles Names
	 */
	getAccTypesWithStylesNames = async () => {
		await getAccTypesWithStylesNamesServer()
			.then(accTypeObj => localStorage.setItem('accTypeObj', JSON.stringify(accTypeObj)))
			.catch(e => _parseServerError('BLM : Get Acc Types With Styles Names Server Error', e));
	};

	/// APPROVING ///
	openApprovalWindow = (event) => {
		let selectedCluster = this.globalCluster.getSubCluster(event.detail);
		this.budgetLineIdsToApproval = [];
		selectedCluster.getAllBudgetLineIds(this.budgetLineIdsToApproval);
		this.showApprovalWindow = true;
	};

	closeApprovalWindow = (event) => {
		//this.showSpinner = true;
		this.showApprovalWindow = false;
	};

	closeApprovalWindowAfterChanges = (event) => {
		this.showSpinner = true;
		this.closeApprovalWindow(event);
		this.refreshTables().then(r => {
		});
	};
	/// APPROVING ///

	//////////////// BUDGET LINE MODAL //////////////////
	openBudgetLineModal = (event) => {
		try {
			this.selectedBudgetLineId = event.detail;
			this.toggleBudgetLineModal();
		} catch (e) {
			_message(`error`, `BLM : Open Budget Line Model ${e}`);
		}
	};

	openBudgetLineExternal = (blId) => {
		try {
			this.selectedBudgetLineId = blId;
			this.toggleBudgetLineModal();
		} catch (e) {
			_message(`error`, `BLM : Open Budget Line Model ${e}`);
		}
	};

	toggleBudgetLineModal = () => {
		this.showBudgetLineModal = !this.showBudgetLineModal;
	};

	addNewBudgetLine = () => {
		if (localStorage.getItem('newLinesDisabled') === 'true') {
			_message('info', 'You reached the limit on the number of budget lines for the CloudBudget Lite version. ' +
				'Please contact CloudBudget to get the unlimited version');
			return;
		}
		this.selectedBudgetLineId = undefined;
		this.toggleBudgetLineModal();
	};

	//////////////// BUDGET LINE MODAL //////////////////

	//////////////// CALCULATION RULE MODAL //////////////////
	openLineCalculationRule = (event) => {
		try {
			this.selectedBudgetLineCalculationRuleId = event.detail;
			this.toggleBudgetLineCalculationRuleModal();
		} catch (e) {
			_message(`error`, `BLM : Open Budget Line Calculation Rule Model ${e}`);
		}
	};

	toggleBudgetLineCalculationRuleModal = () => {
		this.showBudgetLineCalculationRuleModal = !this.showBudgetLineCalculationRuleModal;
	};

	//////////////// CALCULATION RULE MODAL //////////////////

	//////////////// BUDGET LINE TO SAVE//////////////////
	/**
	 * The method gets sent budget line for saving from budget line component
	 */
	updateBudgetLineInBLM = async (event) => {
		try {
			let line = event.detail;
			if (!line) return;
			this.saveButton = true;
			this.budgetLines.find(bl => {
				if (bl.Id === line.Id) {
					bl.cblight__CBAmounts__r = line.cblight__CBAmounts__r;
				}
			});
			if (this.budgetLinesToSave.length === 0) {
				this.budgetLinesToSave.push(line);
			} else {
				this.budgetLinesForSave(line);
			}
			this.showSummary = false;
			this.globalCluster = generateGlobalStructure(this);
			await this.template.querySelector('c-cb-budget-line-summary').recalculateBlmSummary();
			this.showSummary = true;
		} catch (e) {
			_message(`error`, `BLM : Send Budget Line To Blm Error ${e}`);
		}
	};

	/**
	 * The method prepare budget lines for saving to server
	 */
	budgetLinesForSave = (line) => {
		try {
			if (!line) return;
			let pushLine = true;
			this.budgetLinesToSave.find(bl => {
				if (bl.Id === line.Id) {
					bl.cblight__CBAmounts__r = line.cblight__CBAmounts__r;
					bl.cblight__Value__c = line.cblight__Value__c;
					bl.yearlyTotal = line.yearlyTotal;
					pushLine = false;
				}
			});
			if (pushLine) {
				this.budgetLinesToSave.push(line);
			}
		} catch (e) {
			_message(`error`, `BLM : Budget Lines For Save ${e}`);
		}
	};

	/**
	 * The method saves a budget lines to server from the BLM
	 */
	saveBudgetLines() {
		try {
			if (!this.budgetLinesToSave) {
				_message('warning', 'No budget lines to save');
				return null;
			}
			this.showSpinner = true;
			this.saveButton = false;
			const budgetLines = this.budgetLinesToSave;
			let amounts = [];
			budgetLines.forEach(bl => {
				_deleteFakeId(bl.cblight__CBAmounts__r);
				amounts.push(bl.cblight__CBAmounts__r);
				this.EXTRA_FIELDS_IN_BUDGET_LINE.forEach(f => delete bl[f]);
			});
			saveBudgetLinesServer({budgetLines, amounts})
				.then(() => {
					try {
						this.connectedCallback();
						_message('success', 'Budget lines saved');
					} catch (e) {
						_parseServerError('BLM: Save Budget Lines Server Callback Error: ' + e);
					}
				})
				.catch(e => _parseServerError(`BLM : Save Budget Lines Server Error: ${e}`, e))
				.finally(() => this.showSpinner = false)
		} catch (e) {
			_message('error', `BLM : Save Budget Lines Error: ${e}`);
		}
	}

	//////////////// BUDGET LINE TO SAVE//////////////////
	@track headerPeriodLineLeftPadding;


	toggleSections = async (event) => {
		if (event.detail.value === 'openFunctionList') {
			this.redirectToFunctions();
			return;
		}
		if (event.detail.value === 'deleteCurrentFunction') {
			await this.deleteFunction();
			return;
		}
		let showAll = '' + (event.detail.value === 'showAll');
		localStorage.setItem('showAll', showAll);
		if (showAll === 'false') {
			Object.keys(localStorage).forEach(key => {
				if (key.includes('openedSections')) {
					localStorage.removeItem(key);
				}
			});
		}
	};

	toggleDetailMode = () => {
		let isDetailMode = localStorage.getItem('isDetailMode');
		isDetailMode = !isDetailMode || isDetailMode === 'false' ? 'true' : 'false';
		localStorage.setItem('isDetailMode', isDetailMode);
		this.doInit();
	};

	constructor() {
		super();
		this.addEventListener("openBudgetLineModal", this.openBudgetLineModal); // Listener from the BudgetLine component
		this.addEventListener('closeBudgetLineModal', this.toggleBudgetLineModal); // Listener from the budget line modal
		this.addEventListener('refreshTable', this.doInit);
		this.addEventListener("openStatusWindow", this.openApprovalWindow); // Listener from the Cluster component
		this.addEventListener("closeStatusWindow", this.closeApprovalWindowAfterChanges); // Listener from the Cluster component
		this.addEventListener('openLineCalculationRule', this.openLineCalculationRule); // Listener from the Calculation Rule Dialog component
		this.addEventListener('closeDialog', this.toggleBudgetLineCalculationRuleModal); // Listener from the Calculation Rule Dialog
		this.addEventListener("closeExcelWindow", this.closeExcelWindow); // Listener from the Excel component
		this.addEventListener("setFunctionBeforeExcelImport", this.setFunctionBeforeExcelImport); // Listener from the Excel component
		this.addEventListener("updateBudgetLineInBLM", this.updateBudgetLineInBLM); // Listener from the BudgetLine component
		this.addEventListener('closeWelcome', this.closeWelcomeMat); // Listener from the Welcome Mat component
	}

	disconnectedCallback() {
		this.removeEventListener("openBudgetLineModal", this.openBudgetLineModal); // Listener from the BudgetLine component
		this.removeEventListener('closeBudgetLineModal', this.toggleBudgetLineModal); // Listener from the budget line modal
		this.removeEventListener('refreshTable', this.doInit);
		this.removeEventListener("openStatusWindow", this.openApprovalWindow); // Listener from the Cluster component
		this.removeEventListener("closeStatusWindow", this.closeApprovalWindow); // Listener from the Cluster component
		this.removeEventListener('openLineCalculationRule', this.openLineCalculationRule); // Listener from the Calculation Rule Dialog component
		this.removeEventListener('closeDialog', this.toggleBudgetLineCalculationRuleModal); // Listener from the Calculation Rule Dialog
		this.removeEventListener("closeExcelWindow", this.closeExcelWindow); // Listener from the Excel component
		this.removeEventListener("setFunctionBeforeExcelImport", this.setFunctionBeforeExcelImport); // Listener from the Excel component
		this.removeEventListener("updateBudgetLineInBLM", this.updateBudgetLineInBLM); // Listener from the BudgetLine component
		this.removeEventListener('closeWelcome', this.closeWelcome); // Listener from the Calculation Rule Dialog
	}

	/// EXCEL ///
	/**
	 * Return true if Excel Mirror Button disabled.
	 */
	get disabledExcelButton() {
		return !(this.configurationMirror);
	}

	/**
	 * Return true if Add Configuration Button disabled.
	 */
	get disabledAddConfigurationButton() {
		return !(this.disabledExcelButton);
	}

	/**
	 * The method opens Excel import/export component
	 */
	openExcelWindow = (event) => {
		this.showExcelWindow = true;
		this.tableIsReadyToRender = false;
	};

	/**
	 * The method closes Excel import/export component
	 */
	closeExcelWindow = async (event) => {
		try {
			this.showExcelWindow = false;
			await this.applyBLMFunction(this.functions.find(f => f.Id == this.configurationMirror));
		} catch (e) {
			_parseServerError('BLM : Close Excel Window Error : ', e)
		} finally {
			this.showSpinner = false;
		}
	};

	/// FILTER CONFIGURATION  /////
	/**
	 * The method sets configuration before import/export
	 */
	setFunctionBeforeExcelImport = (event) => {
		const func = this.functions.find(f => f.Id == event.detail);
		const oldConfId = this.configurationMirror;
		this.configurationMirror = event.detail;
		if (oldConfId != this.configurationMirror) {
			const tabset = this.template.querySelector('lightning-tabset');
			if (tabset) {
				setTimeout(() => {
					tabset.activeTabValue = this.configurationMirror;
				}, 0);
			}
		} else {
			this.applyBLMFunction(func);
		}
	};

	/**
	 * Method gets list of functions form database
	 */
	getFunctions = async () => {
		let func = await getFunctionsServer({type: 'BLM'});
		this.functions = [...func];
		this.addNewTabs();
	};

	/**
	 * Method add functions to tabset
	 */
	addNewTabs = () => {
		let newTabs = [];
		this.functions.forEach(f => {
			newTabs.push({
				label: f.cblight__Title__c,
				value: f.Id
			});
		});
		this.dynamicTabs = [...newTabs];
	};

	/**
	 * Apply configuration
	 */
	setConfiguration = (event) => {
		this.configurationMirror = event.target.value;
		this.applyBLMFunction(this.functions.find(f => f.Id == event.target.value));

	};

	/**
	 * Apply configuration
	 */
	resetConfiguration = () => {
		this.configurationMirror = '';
		let infoPanel = this.template.querySelector('c-cb-page-info ');
		if (infoPanel) {
			infoPanel.setConfig(null);
		}
	};

	/**
	 * Method applies Configuration
	 */
	applyBLMFunction = async (func) => {
		try {
			if (!func) {
				this.configurationMirror = '';
				return null;
			}
			if (!this.showExcelWindow) {
				this.showSpinner = true;
			}
			const filterConfiguration = JSON.parse(func.cblight__Details__c);
			Object.entries(this.SERVER_PARAMETERS_MAPPING).forEach(([key, value]) => {
				this[value] = filterConfiguration[key] ? filterConfiguration[key] : '';
				localStorage.setItem(value, this[value]);
			});
			this.FILTER_LOOKUPS.forEach(element => {
				this[element.bl] = filterConfiguration.complexFilterString ? '' : (func[element.func] ? func[element.func] : '');
				localStorage.setItem(element.bl, this[element.bl]);
			});
			localStorage.setItem('complexFilter', this.complexFilterString ? this.complexFilterString : '');
			await this.refreshTables();
			let infoPanel = this.template.querySelector('c-cb-page-info ');
			if (infoPanel) {
				infoPanel.setConfig(func);
			}
			if (this.showExcelWindow) {
				this.template.querySelector('c-cb-excel-mirror').continueImport();
			}
		} catch (e) {
			this.showSpinner = false;
			_message('error', 'BLM : Apply BLM Function Error : ' + e);
		}
	};

	/**
	 * Method saves the current combination of analytics as a function
	 */
	saveCombination = async () => {
		if (!confirm(`Are you sure you want to save the current combination of analytics as a function?`)) {
			return null;
		}
		try {
			let filterObject = this.getFilterObject();
			let functionTitle = prompt("Please specify the function name.");
			if (!functionTitle) {
				return;
			}
			functionTitle = functionTitle.slice(0, 40);
			if (this.functions.some(f => f.cblight__Title__c == functionTitle)) {
				_message('error', 'BLM : Function with name ' + functionTitle + ' exists. Please specify other name ');
				return;
			}
			const newFunction = {Name: 'BLM', cblight__Type__c: 'BLM', cblight__Title__c: functionTitle};
			this.FILTER_LOOKUPS.forEach(element => {
				let lookupValue = filterObject[element.bl];
				delete filterObject[element.bl];
				if (lookupValue && !filterObject.complexFilterString) {
					newFunction[element.func] = lookupValue;
				}
			})
			newFunction['cblight__Details__c'] = JSON.stringify(filterObject);
			await saveFunctionServer({newFunction: newFunction});
			await this.getFunctions();
			let newFunc = this.dynamicTabs.find(f => f.label == functionTitle);
			if (newFunc) {
				this.configurationMirror = newFunc.value;
				let tabset = this.template.querySelector('lightning-tabset');
				tabset.activeTabValue = this.configurationMirror;
			} else {
				_message('error', 'BLM : Save Function Error ');
			}
			_message('success', 'Function Saved')
		} catch (e) {
			_message('error', 'BLM : Save Function Error: ' + e);
		}
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
			_message('error', 'BLM : Redirect Error ' + e);
		}
	};

	/**
	 * The method delete current function
	 */
	deleteFunction = async () => {
		try {
			let deletedFunc = this.functions.find(f => f.Id == this.configurationMirror);
			if (!deletedFunc) {
				_message('error', 'BLM : Function did not find' + e);
				return;
			}
			if (!confirm('Are you sure you want to delete the "' + deletedFunc.cblight__Title__c + ' " function ?')) {
				return null;
			}
			this.showSpinner = true;
			await deleteFunctionServer({functionId: deletedFunc.Id})
			await this.getFunctions();
			if (this.dynamicTabs.length > 0) {
				let newActiveFunc = this.dynamicTabs[0];
				this.configurationMirror = newActiveFunc.value;
				let tabset = this.template.querySelector('lightning-tabset');
				tabset.activeTabValue = this.configurationMirror;
			} else {
				this.configurationMirror = '';
			}
			_message('success', 'Function deleted');
		} catch (e) {
			_message('error', 'BLM : Delete Function Error ' + e);
		} finally {
			this.showSpinner = false;
		}
	};
	//////////////////////////////  GLOBAL SEARCH /////////////////////////
	openGlobalSearchList = () => this.showGlobalSearchModal = true;
	closeGlobalSearchList = () => this.showGlobalSearchModal = false;
	//////////////////////////////  GLOBAL SEARCH /////////////////////////

	/**
	 *
	 * @param recordId Id of any type of record
	 */
	makeItemRecent = (recordId) => {
		if (recordId && (recordId.length === 15 || recordId.length === 18)) {
			makeItemRecentServer({recordId});
		}
	}
}