import {api, LightningElement, track} from 'lwc';
import {_applyDecStyle, _message, _parseServerError} from 'c/cbUtils';
import getBudgetLinesBySearchServer
	from "@salesforce/apex/CBBudgetLineGlobalSearchService.getBudgetLinesBySearchServer";

export default class CbBudgetLineGlobalSearch extends LightningElement {
	@track searchString = '';
	@track showSpinner = false;
	@track budgetLines = [];
	@api openRecord;
	@api closeModal;

	connectedCallback() {
		_applyDecStyle();
	}

	/**
	 * Method gets list of functions form database to create SO list
	 */
	getBudgetLinesBySearch = () => {
		this.showSpinner = true;
		this.budgetLines = [];
		let searchString = this.searchString;
		getBudgetLinesBySearchServer({searchString})
			.then(budgetLines => {
				this.indexBudgetLinesAndSumTotal(budgetLines);
				this.manageAnalytics(budgetLines);
				this.budgetLines = budgetLines;
			})
			.catch(e => _parseServerError("BLGS : Get Budget Lines Error: ", e))
			.finally(() => this.showSpinner = false)
	};

	manageAnalytics = (budgetLines) => {
		budgetLines.forEach(bl => this.populateAnalytics(bl));
	};
	/**
	 * method sets indexes and calculates total of BL
	 */
	indexBudgetLinesAndSumTotal = (budgetLines) => {
		budgetLines.forEach((bl, idx) => {
			bl.idx = idx + 1;
			bl.total = bl.cblight__CBAmounts__r.reduce((total, a) => {
				total += a.cblight__Value__c ? a.cblight__Value__c : 0;
				return total;
			}, 0);
		});
	};
	/**
	 * Method generates columns with analytics
	 */
	populateAnalytics = (bl) => {
		try {
			bl.titleClass = this.getClassName(bl.Name) + ' slds-m-left_small';
			if (bl.cblight__Description__c) bl.descrClass = this.getClassName(bl.cblight__Description__c) + ' slds-m-left_small';

			bl.analyticsFirstColumn = [];
			this.pushAnalytic(bl.analyticsFirstColumn, 'BY', bl.cblight__CBBudgetYear__r.Name);
			this.pushAnalytic(bl.analyticsFirstColumn, 'GL Account', bl.cblight__CBAccount__r.Name);
			this.pushAnalytic(bl.analyticsFirstColumn, 'Status', bl.cblight__Status__c);
			if (bl.cblight__CBScenario__r) this.pushAnalytic(bl.analyticsFirstColumn, 'Scenario', bl.cblight__CBScenario__r.Name);

			bl.analyticsSecondColumn = [];
			if (bl.cblight__CBVariable1__r) this.pushAnalytic(bl.analyticsSecondColumn, 'Var1', bl.cblight__CBVariable1__r.Name);
			if (bl.cblight__CBVariable2__r) this.pushAnalytic(bl.analyticsSecondColumn, 'Var2', bl.cblight__CBVariable2__r.Name);
			if (bl.cblight__CBVariable3__r) this.pushAnalytic(bl.analyticsSecondColumn, 'Var3', bl.cblight__CBVariable3__r.Name);
			if (bl.cblight__CBVariable4__r) this.pushAnalytic(bl.analyticsSecondColumn, 'Var4', bl.cblight__CBVariable4__r.Name);
			if (bl.cblight__CBVariable5__r) this.pushAnalytic(bl.analyticsSecondColumn, 'Var5', bl.cblight__CBVariable5__r.Name);

			if (this.isNumeric(this.searchString)) {
				const fAmount = parseFloat(this.searchString);
				bl.cblight__CBAmounts__r.forEach(a => a.class = fAmount === a.cblight__Value__c ? 'underLine' : '');
				bl.totalClass = fAmount === bl.total ? 'underLine' : '';
			}
		} catch (e) {
			_message('error', 'BLGS : Title Generation Error : ' + e);
		}
	};

	pushAnalytic = (arr, title, value) => arr.push({label: `${title}:${value}`, class: this.getClassName(value)});

	getClassName = (value) => value.toLowerCase().includes(this.searchString.toLowerCase()) ? 'highLight' : 'simple';

	/**
	 * true if str is number
	 */
	isNumeric = (str) => {
		if (typeof str != "string") return false; // we only process strings!
		return !isNaN(str) && !isNaN(parseFloat(str));
	};

	handleChange = (event) => {
		this[event.target.name] = event.target.value;
	};

	/**
	 * Method use external method of parent to open selected budget line
	 */
	openBudgetLine = (event) => {
		try {
			this.openRecord(event.currentTarget.dataset.id);
			this.closeModal();
		} catch (e) {
			_message('error', 'BLGS : Open BL Error : ' + e);
		}
	};


}