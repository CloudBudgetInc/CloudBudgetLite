import {LightningElement, track} from 'lwc';
import getSelectOptionsServer from '@salesforce/apex/CBGanttPageController.getSelectOptionsServer';
import getBudgetLinesServer from '@salesforce/apex/CBGanttPageController.getBudgetLinesServer';
import getPeriodsServer from '@salesforce/apex/CBGanttPageController.getPeriodsServer';
import saveBudgetLineServer from '@salesforce/apex/CBBudgetLinePageController.saveBudgetLineServer';
import {getTableStructure} from './cbBudgetLineGanttTableData';
import {_message, _parseServerError} from 'c/cbUtils';

export default class CbBudgetLineGantt extends LightningElement {

	@track totalLine;
	@track selectOptions;
	@track budgetLines;
	@track tableRows = []; // main list to show data on the screen
	@track periods; // list of all periods
	@track showSpinner;
	@track periodModeSO = [
		{label: 'Monthly', value: 'Monthly'},
		{label: 'Quarterly', value: 'Quarterly'},
		{label: 'Yearly', value: 'Yearly'}];
	@track periodMode = 'Monthly';
	@track periodMapping = {};
	@track showTable = false;
	@track showBudgetLineModal = false;
	@track selectedBudgetLineId; // for budget line modal component
	///// Drug and drop
	amountDragId;
	rowDragId;
	amountDropId;
	rowDropId;

	///// Drug and drop


	connectedCallback() {
		this.getSelectOptions();
		this.getPeriods();
		document.title = "CB Gantt";
	}

	/**
	 * Method takes selectOptions for header filters
	 */
	getSelectOptions() {
		this.showSpinner = true;
		getSelectOptionsServer()
			.then(selectOptions => {
				this.selectOptions = selectOptions;
			})
			.catch(e => _parseServerError("Gantt : Get Select Options Error", e));
	}

	/**
	 * Method gets full list of CBPeriods to generate the table columns
	 */
	getPeriods = () => {
		this.showTable = false;
		getPeriodsServer()
			.then(periods => {
				this.periods = periods;
				this.managePeriodMode();
				this.getBudgetLines();
				localStorage.setItem('cblight__CBBudgetYear__c', periods[0].cblight__CBBudgetYear__c);
				localStorage.setItem('periods', JSON.stringify(periods));
			})
			.catch(e => _parseServerError("Gantt : Get Periods Error", e));
	};

	/**
	 * Method takes budget lines from server to populate data
	 */
	getBudgetLines() {
		getBudgetLinesServer({params: {test: 'test'}})
			.then(budgetLines => {
				try {
					this.budgetLines = budgetLines;
					this.tableRows = getTableStructure(this);
					this.showTable = true;
				} catch (e) {
					_message(`error``Gantt : Get budget line Callback Error : ${e}`);
				}
			})
			.catch((e) => _parseServerError("Gantt : Get Budget Lines Error", e))
			.finally(() => this.showSpinner = false);
	}

	/**
	 *	Handler to change period mode
	 */
	changePeriodMode(event) {
		this.showTable = false;
		this.periodMode = event.target.value;
		this.getPeriods();
	}

	/**
	 * If period mode changed it's needed to change period list
	 */
	managePeriodMode() {
		if (this.periodMode === 'Quarterly') {
			this.changePeriodsToQuarters();
		}
		if (this.periodMode === 'Yearly') {
			this.changePeriodsToYears();
		}
	}

	/**
	 * Method converts list of months to list of quarters
	 */
	changePeriodsToQuarters() {
		let quarterCounter = 1, monthCounter = 1, quarter, quarters = [];
		this.periodMapping = this.periods.forEach(period => {
			if (!quarter) {
				quarter = {
					Name: `Quarter ${quarterCounter} ${period.cblight__CBBudgetYear__r.Name}`,
					Id: period.Id,
					includeIds: []
				};
				quarters.push(quarter);
			}
			quarter.includeIds.push(period.Id);
			monthCounter++;
			if (monthCounter === 4) {
				monthCounter = 1;
				quarterCounter++;
				quarter = undefined;
			}
			if (quarterCounter === 5) {
				quarterCounter = 1;
			}
		});
		this.periods = quarters;
	}

	/**
	 * Method converts list of months to list of budget years
	 */
	changePeriodsToYears() {
		let monthCounter = 1, year, years = [];
		this.periodMapping = this.periods.forEach(period => {
			if (!year) {
				year = {
					Name: `BY ${period.cblight__CBBudgetYear__r.Name}`,
					Id: period.Id,
					includeIds: []
				};
				years.push(year);
			}
			year.includeIds.push(period.Id);
			monthCounter++;
			if (monthCounter === 13) {
				monthCounter = 1;
				year = undefined;
			}
		});
		this.periods = years;
	}

	openBudgetLineModal(event) {
		this.selectedBudgetLineId = event.target.value;
		this.toggleBudgetLineModal();
	}

	toggleBudgetLineModal = () => {
		this.showBudgetLineModal = !this.showBudgetLineModal;
	};

	constructor() {
		super();
		this.addEventListener('closeBudgetLineModal', this.toggleBudgetLineModal); // Listener from the budget line modal
		this.addEventListener('refreshTable', this.getPeriods); // Listener from the budget line modal
	}


	////// DRAG AND DROP
	/**
	 * Budget line was taken
	 */
	drag(event) {
		console.log('DRAG : ' + event.target.dataset.amountid);
		console.log('DRAG : ' + event.target.dataset.rowid);
		this.amountDragId = event.target.dataset.amountid;
		this.rowDragId = event.target.dataset.rowid;
	}

	/**
	 * Budget line was over some cell
	 */
	allowDrop(event) {
		event.preventDefault();
		console.log('OVER : ' + event.target.dataset.amountid);
		if (event.target.dataset.amountid) {
			this.amountDropId = event.target.dataset.amountid;
			this.rowDropId = event.target.dataset.rowid;
		}
	}

	/**
	 * Budget line dropped
	 */
	drop(event) {
		try {
			event.stopPropagation();
			event.preventDefault();
			console.log('DROP : ' + this.amountDropId);
			console.log('DROP : ' + this.rowDropId);
			if (!this.rowDragId || !this.rowDropId || !this.amountDragId || !this.amountDropId) {
				alert('TRY AGAIN');
				return null;
			}
			if (this.rowDragId !== this.rowDropId) {
				alert('Drag amount to the same line');
				return null;
			}
			if (this.amountDragId === this.amountDropId) {
				return null;
			}
			let selectedRow = this.tableRows.find(row => row.id === this.rowDropId);
			const dragIndex = selectedRow.amounts.findIndex(amount => amount.Id === this.amountDragId);
			const dropIndex = selectedRow.amounts.findIndex(amount => amount.Id === this.amountDropId);
			const bl = this.getBLWithShiftedPeriods(this.rowDragId, dropIndex - dragIndex);
			this.saveBudgetLine(bl, bl.cblight__CBAmounts__r);
			this.showSpinner = true;
			this.showTable = false;
		} catch (e) {
			_message('info', `Drop Error : ${e}`);
		}
	}

	/**
	 * The method shifts periods in budget line to selected period number
	 * @param budgetLineId budget line Id needed to be update
	 * @param shift integer - period to shift on
	 */
	getBLWithShiftedPeriods(budgetLineId, shift) {
		const periodMap = {};
		this.periods.forEach((period, idx) => {
			try {
				periodMap[period.Id] = this.periods[idx + parseInt(shift)].Id;
			} catch (e) {

			}
		});
		const budgetLine = this.budgetLines.find(bl => bl.Id === budgetLineId);
		budgetLine.cblight__CBAmounts__r.forEach(a => a.cblight__CBPeriod__c = periodMap[a.cblight__CBPeriod__c]);
		return budgetLine;
	}

	/**
	 * Saves changed budget line and its amounts
	 * @param budgetLine needed to be save
	 * @param amounts budget line amounts
	 */
	saveBudgetLine(budgetLine, amounts) {
		saveBudgetLineServer({budgetLine, amounts})
			.then(() => {
				this.getPeriods();
			})
			.catch(e => {
				_parseServerError(`Gantt : Saving Error : `, e);
			})
			.finally(() => {
				this.showSpinner = false;
			})
	}

	////// DRAG AND DROP


}