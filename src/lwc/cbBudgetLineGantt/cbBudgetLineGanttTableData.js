let context;
const FIRST_AMOUNT = 'firstAmount'; // style class in CSS file
const LAST_AMOUNT = 'lastAmount';
const MIDDLE_AMOUNT = 'middleAmount';
const TRUNCATE_LIMIT = 20;
import {_generateFakeId, _message} from 'c/cbUtils';

/**
 * @return array processed data for the main report
 */
const getTableStructure = (_this) => {
	context = _this;
	const amountsMapTemplate = getAmountsTemplate();
	return getRowsConvertedFromBL(amountsMapTemplate);
};

/**

 * @returns array of rows with amounts
 */
const getRowsConvertedFromBL = (amountsMapTemplate) => {
	try {
		const rows = [];
		context.budgetLines.forEach((bl, idx) => {
			const row = new TableRow();
			row.title = bl.Name;
			row.id = bl.Id;
			row.idx = (idx + 1) + '. ';
			row.isFormula = bl.cblight__isFormulaBudgetLine__c;
			row.amountsMap = JSON.parse(JSON.stringify(amountsMapTemplate));
			bl.cblight__CBAmounts__r.forEach(a => {
				if (a.cblight__Value__c === 0) {
					return null;
				}
				a.cblight__CBPeriod__c = periodMap[a.cblight__CBPeriod__c];
				let amountValue = row.amountsMap[a.cblight__CBPeriod__c].cblight__Value__c;
				amountValue = amountValue ? amountValue : 0;
				amountValue += +a.cblight__Value__c;
				row.amountsMap[a.cblight__CBPeriod__c].cblight__Value__c = amountValue;
			});
			row.moveMapToAmounts();
			row.setStyles(bl.cblight__isFormulaBudgetLine__c);
			row.calculateRowTotal();
			row.setIdToAmounts();
			row.truncateTitle();
			rows.push(row);
		});
		return rows;
	} catch (e) {
		_message('error', `Gantt : Convert BL to row Error: ${e}`);
	}
};
/**
 * @returns special map where key is period Id, and value is a row amount
 */
const getAmountsTemplate = () => {
	try {
		return context.periods.reduce((r, period) => {
			let newAmount = {
				cblight__CBPeriod__c: period.Id
			};
			periodMap[period.Id] = period.Id;
			r[period.Id] = newAmount;
			if (period.includeIds) {
				period.includeIds.forEach(i => {
					periodMap[i] = period.Id;
				});
			}
			return r;
		}, {}); // key is period
	} catch (e) {
		_message('error', `Gantt : Get Amounts Map Template Error: ${e}`);
	}
};
const periodMap = {};

/**
 * Special Class Wrapper for a table row
 */
function TableRow() {
	this.amountsMap = {}; // key is period
	this.amounts = [];
	this.class = '';
	this.rowTotal = 0;
	this.title = 'N/A';
	this.id;
	this.moveMapToAmounts = () => this.amounts = Object.values(this.amountsMap);
	/**
	 * Set styles to first, last and middle amounts
	 */
	this.setStyles = (isFormula) => {
		try {
			setStyleToFirstRowAmount(this.amounts);
			setStyleToLastRowAmount(this.amounts);
			setMiddleStyle(this.amounts);
			if (isFormula) {
				setFormulaStyle(this.amounts);
			}
		} catch (e) {
			_message('error', `Gantt : Set Style Error: ${e}`);
		}
	};
	/**
	 * Calculates the row total
	 */
	this.calculateRowTotal = () => {
		try {
			this.rowTotal = this.amounts.reduce((total, amount) => +total + (amount.cblight__Value__c ? +amount.cblight__Value__c : 0), 0);
		} catch (e) {
			_message('error', `Gantt : Calculate Row Total Error: ${e}`);
		}
	};
	/**
	 * Method fills in amounts with the fake Ids
	 */
	this.setIdToAmounts = () => {
		this.amounts.forEach(amount => amount.Id = _generateFakeId());
	};
	/**
	 * This method cut a long title of a budget line
	 */
	this.truncateTitle = () => {
		this.title = this.title.replace(/(.{20})..+/, "$1…");
	}
}

/**
 * Finds and sets css class to first amount
 */
const setStyleToFirstRowAmount = (amounts) => {
	try {
		let fa = amounts.find(a => a.cblight__Value__c);
		if (!fa) return null;
		fa.class = FIRST_AMOUNT;
	} catch (e) {
		_message('error', `Gantt : Set Style To First Row Amount Error : ${e}`);
	}
};
/**
 * Finds and sets css class to last amount
 */
const setStyleToLastRowAmount = (amounts) => {
	try {
		let la;
		for (let i = amounts.length - 1; i >= 0; i--) {
			if (la) break;
			if (amounts[i].cblight__Value__c) {
				la = amounts[i];
			}
		}
		if (!la) return null;
		la.class = la.class ? la.class + ' ' + LAST_AMOUNT : LAST_AMOUNT;
	} catch (e) {
		_message('error', `Gantt : Set Style To First Last Amount Error : ${e}`);
	}
};
/**
 * Method populates middleClass to amounts between first and last amount
 */
const setMiddleStyle = (amounts) => {
	try {
		let needStyle = false;
		amounts.forEach(a => {
			if (a.class === FIRST_AMOUNT) {
				needStyle = true;
			}
			if (a.class === LAST_AMOUNT) {
				needStyle = false;
			}
			if (!a.class && needStyle) {
				a.class = MIDDLE_AMOUNT;
				if (!a.cblight__Value__c) {
					a.cblight__Value__c = 0;
				}
			}
		});
	} catch (e) {
		_message('error', `Gantt : Set Middle Style Error : ${e}`);
	}
};

/**
 * This method sets green style to formula budget line
 */
const setFormulaStyle = (amounts) => {
	try {
		amounts.forEach(a => {
			if (a.class) {
				a.class += ' formulaLine';
			}
		})
	} catch (e) {
		_message('error', `Gantt : Set Formula Style Error : ${e}`);
	}
};


export {getTableStructure};