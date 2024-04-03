import {api, LightningElement, track} from "lwc";
import getReportColumnsServer from "@salesforce/apex/CBReportColumnPageController.getReportColumnsServer";
import getStaticDataServer from "@salesforce/apex/CBReportColumnPageController.getStaticDataServer";
import saveColumnsServer from "@salesforce/apex/CBReportColumnPageController.saveColumnsServer";
import deleteColumnServer from "@salesforce/apex/CBReportColumnPageController.deleteColumnServer";
import {_cl, _deleteFakeId, _message, _generateFakeId, _getCopy, _isInvalid, _isFakeId, _validateFormula, _parseServerError, _confirm} from 'c/cbUtils';
import {enumerateColumns, getClonedMasterGroup} from './cbReportingColumnsMasterGroups';



export default class CbReportingColumns extends LightningElement {

	@track showSpinner = false;
	@track showDialog = false;
	@track columns;
	@track staticDate = {};
	@track modeSO = [{label: 'Auto', value: 'Auto'}, {label: 'Manual', value: 'Manual'}];
	@track subtotalModeSO = [{label: 'Top', value: 'Top'}, {label: 'Bottom', value: 'Bottom'}, {label: 'Bottom With Header', value: 'BottomWithHeader'}];
	@track trueFalseSO = [{label: 'Yes', value: true}, {label: 'No', value: false}];
	@api report;
	@api styles;


	@api
	get isManual() {
		return this.report.cblight__Mode__c === 'Manual';
	}

	set isManual(value) {

	}

	async connectedCallback() {
		await this.getStaticData();
		await this.getReportColumns();
		this.showDialog = true;
	}

	/**
	 * Get all data that will not be changed from server
	 */
	async getStaticData() {
		this.showSpinner = true;
		await getStaticDataServer()
			.then(result => {
				this.staticDate = result;
			})
			.catch(e => _parseServerError("Get Static Data Error: ", e))
			.finally(() => this.showSpinner = false)
	}

	/**
	 * Get list of report columns from the server
	 */
	async getReportColumns() {
		this.showSpinner = true;
		await getReportColumnsServer({reportId: this.report.Id})
			.then(result => {
				enumerateColumns(result);
				this.columns = result;
				this.columns.forEach(c => this.validateFormula(c));
			})
			.catch(e => _parseServerError("Get Report Columns Error: ", e))
			.finally(() => this.showSpinner = false)
	}


	/**
	 * Manual mode and auto mode
	 */
	changeMode(event) {
		try {
			const reportCopy = _getCopy(this.report);
			reportCopy.cblight__Mode__c = event.target.value;
			this.report = reportCopy;
		} catch (e) {
			_message('error', e, "Change Mode Error: ");
		}
	}
	/**
	 * top, bottom or bottom with header subtotals
	 */
	changeSubtotalMode(event) {
		try {
			const reportCopy = _getCopy(this.report);
			reportCopy.cblight__SubtotalMode__c = event.target.value;
			this.report = reportCopy;
		} catch (e) {
			_message('error', e, "Change Subtotal Mode Error: ");
		}
	}

	/**
	 * Handler for the Quarter select option
	 */
	changeQuarterTotals(event) {
		try {
			const reportCopy = _getCopy(this.report);
			reportCopy.cblight__needQuarterTotals__c = event.target.value === 'true';
			this.report = reportCopy;
		} catch (e) {
			_message('error', e, "Change Quarter Totals Error: ");
		}
	}

	/**
	 * Handler for the Only total select option
	 */
	changeOnlyTotals(event) {
		try {
			const reportCopy = _getCopy(this.report);
			reportCopy.cblight__needOnlyTotal__c = event.target.value === 'true';
			this.report = reportCopy;
		} catch (e) {
			_message('error', e, "Change Only Totals Error: ");
		}
	}

	/**
	 * Handler for the One Column Mode select option
	 */
	changeOneColumnMode(event) {
		try {
			const reportCopy = _getCopy(this.report);
			reportCopy.cblight__oneColumnMode__c = event.target.value === 'true';
			this.report = reportCopy;
		} catch (e) {
			_message('error', e, "Change Only Totals Error: ");
		}
	}

	/**
	 * Save configured columns
	 */
	async saveReportColumns() {
		this.showSpinner = true;
		const report = {
			Id: this.report.Id,
			cblight__Mode__c: this.report.cblight__Mode__c,
			cblight__SubtotalMode__c: this.report.cblight__SubtotalMode__c,
			cblight__needQuarterTotals__c: this.report.cblight__needQuarterTotals__c,
			cblight__needOnlyTotal__c: this.report.cblight__needOnlyTotal__c,
			cblight__oneColumnMode__c: this.report.cblight__oneColumnMode__c
		}; // short copy of report
		const columns = _getCopy(this.columns);
		_deleteFakeId(columns);

		columns.forEach(c => c.formulaWarning = null);  // removing formulaWarning before upsert to DB

		const message = this.validateColumns(columns);
		if (message) {
			_message("warning", message);
			return;
		}

		await saveColumnsServer({report, columns})
			.then(result => {
				this.columns = result;
				this.columns.forEach(i => this.validateFormula(i));
				this.updateFullReport();
				_message('success', 'Columns saved', 'Success');
			})
			.catch(error => _parseServerError("Save Columns Error: ", error))
			.finally(() => this.showSpinner = false)
	}

	/**
	 * The method validates columns.
	 */
	validateColumns(columns) {
		const errorCell = columns.find(col => (this.report.cblight__Mode__c === 'Manual' && !col.cblight__Formula__c && !col.cblight__CBPeriod__c));
		if (errorCell) return `The cell #${errorCell.cblight__OrderNumber__c} has no period.`;
	}

	/**
	 * Close column dialog window. Send an event to parent component
	 */
	closeReportColumns() {
		this.showDialog = false;
		this.dispatchEvent(new CustomEvent('closeReportColumns', {
			bubbles: true,
			composed: true,
			detail: this.line
		}));
	}

	updateFullReport() {
		this.dispatchEvent(new CustomEvent('updateReportAfterSavingColumns', {
			bubbles: true,
			composed: true,
			detail: this.line
		}));
	}

	/**
	 * The method returns a new default column
	 */
	getNewColumnObject() {
		return {
			Id: _generateFakeId(),
			Name: 'New Column',
			cblight__Color__c: 'White',
			cblight__Unit__c: '$',
			cblight__CBReport__c: this.report.Id,
			cblight__isHidden__c: false
		};
	}


	///////////////////// HANDLERS //////////////////////////

	handleChangeColumnData(event) {
		this.updateColumnValue(event);
	}

	updateColumnValue(event) {
		try {
			const field = event.target.name;
			const columnsCopy = _getCopy(this.columns);
			const column = columnsCopy.find(c => c.Id === event.target.dataset.id);
			let val = (field === 'cblight__NeedYTD__c' || field === 'cblight__isHidden__c') ? event.target.checked : event.target.value;
			column[field] = ['true', 'false'].includes(val) ? val === 'true' : val;
			if (field === 'cblight__Formula__c') this.validateFormula(column);
			this.columns = columnsCopy;
		} catch (e) {
			_message('error', e, "Update Column Value Error: ");
		}
	}

	/**
	 *  Method validates formula if value is not empty
	 * @param column
	 * @returns {{message: string, class: string}|{message: string, class: string}}
	 */

	validateFormula = (column) => {
		const formula = column.cblight__Formula__c;
		if (!formula) {
			delete column.formulaWarning;
			return;
		}
		const validationMessage = _validateFormula(formula, null, true);
		return column.formulaWarning = validationMessage ? {class: 'formulaWarning', message: '⚠ ' + validationMessage} : {
			class: 'formulaValid',
			message: '✓ Valid'
		};
	};

	/**
	 * Handler for the Add button over the list of columns
	 * The method adds a new column object
	 */
	addColumn() {
		try {
			let columnsCopy = _getCopy(this.columns);
			if (_isInvalid(columnsCopy)) { // new report does not have a list of columns
				columnsCopy = [];
			}
			let newColumn = this.getNewColumnObject();
			newColumn.cblight__OrderNumber__c = columnsCopy.reduce((max, col) => Math.max(max, col.cblight__OrderNumber__c + 1), 1);
			newColumn.cblight__Type__c = columnsCopy.some(col => col.cblight__Type__c !== 'Master') ? 'Simple' : 'Master';
			columnsCopy.push(newColumn);
			this.columns = columnsCopy;
		} catch (e) {
			_message('error', e, "Add Column Error: ");
		}
	}

	deleteColumnHandler(event) {
		const value = event.target.value; 
		this.deleteColumn(value);
	}
	/**
	 * It is the handler foe
	 */
	async deleteColumn(value) {
		const conf = await _confirm('Are you sure you want to delete this column?', 'Confirm');
		if (!conf) return null;
		try {
			this.showSpinner = true;
			const columnId = value;
			let columnsCopy = _getCopy(this.columns);
			columnsCopy = columnsCopy.filter(c => c.Id !== columnId);
			enumerateColumns(columnsCopy);
			this.columns = columnsCopy;
			if (!_isFakeId(columnId)) {
				await deleteColumnServer({columnIds: [columnId]})
				.catch(e => _parseServerError("Report Columns : Delete Columns Server Error: ", e));
			}
			_message('success', 'Deleted', 'Success');
			this.showSpinner = false;
		} catch (e) {
			alert('Delete Column Error: ' + e);
		}
	}

	cloneMasterGroup() {
		try {
			if (!confirm('This function may replace manually created columns. Are you sure?')) {
				return null;
			}
			this.showSpinner = true;

			const runClone = async () => {
				try {
					await this.saveReportColumns();
					this.columns = getClonedMasterGroup(this.columns, this.staticDate.periodsAll, this.report.cblight__needQuarterTotals__c, this.styles);
					this.columns.forEach(i => this.validateFormula(i));
					this.showSpinner = false;
					_message('success', 'Column Cloned', 'Success');
				} catch (e) {
					_message('error', e, "Reporting Columns : Run Clone Error: ");
				}
			};

			this.deleteSimpleColumns(runClone);
		} catch (e) {
			_message('error', e, "Clone Master Group Error: ");
		}
	}

	/**
	 * Method deletes automatically generated columns. NOT MASTER
	 */
	deleteSimpleColumns(callback) {
		const isFunctionParam = callback instanceof Function;

		if (!isFunctionParam) {
			if (!confirm('Are you sure you want to delete?')) return null;
		}
		try {
			let simpleColumnIds = this.columns.reduce((arr, c) => {
				if (c.cblight__Type__c !== 'Master' && !_isFakeId(c.Id)) {
					arr.push(c.Id);
				}
				return arr;
			}, []);

			this.columns = this.columns.filter(col => col.cblight__Type__c === 'Master');

			if (simpleColumnIds.length > 0) {
				deleteColumnServer({columnIds: simpleColumnIds})
					.then(() => {
						if (isFunctionParam) {
							callback();
						}
					})
					.catch(e => _parseServerError("Reporting Columns: Delete Columns Server Error: ", e))
					.finally(() => this.showSpinner = false);
			} else {
				if (isFunctionParam) {
					callback();
				}
			}
			if (!isFunctionParam) {
				_message('Success', 'Simple Columns Deleted.');
			}
		} catch (e) {
			_message('error', e, "Delete Simple Columns Error: ");
		}
	}

	///////////////////// HANDLERS //////////////////////////

	///////////////////// DRUG & DROP ///////////////////////
	dragStart(event) {
		event.target.classList.add('drag');
	}

	dragOver(event) {
		event.preventDefault();
		return false;
	}

	/**
	 * put dropped element into a new position
	 */
	dropElement(event) {
		try {
			event.stopPropagation();
			const dragElementOrderNumber = this.template.querySelector('.drag').textContent;
			const dropElementOrderNumber = event.target.textContent;// indexOfDroppedElement of line that dropped
			if (dragElementOrderNumber === dropElementOrderNumber) { // the same column, replacing is not needed
				return false
			}
			let indexOfDroppedElement = dropElementOrderNumber - 1,
				dragElement = this.columns[dragElementOrderNumber - 1];
			const updatedColumns = this.columns.reduce((newArray, curColumn, reduceIndex) => {
				if (reduceIndex === indexOfDroppedElement) {
					// if coincide - insert dragElement to the place
					return (indexOfDroppedElement > dragElementOrderNumber - 1) ? [...newArray, curColumn, dragElement] : [...newArray, dragElement, curColumn];
				} else if (+curColumn.cblight__OrderNumber__c !== +dragElementOrderNumber) {
					return [...newArray, curColumn]; // the regular case in the iteration
				}
				return newArray; // if drag element was met - skip it
			}, []);
			// set new indexes to columns
			enumerateColumns(updatedColumns);
			this.columns = updatedColumns;
			// update styles
			this.template.querySelectorAll('.draggableLine').forEach(element => element.classList.remove('drag'));
		} catch (e) {
			_message('error', e, "Drop Element Error: ");
		}
	}

	///////////////////// DRUG & DROP ///////////////////////

}