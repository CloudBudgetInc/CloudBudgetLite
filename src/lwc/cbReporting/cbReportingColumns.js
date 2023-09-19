let context; // this of the parent component
import {_message} from "c/cbUtils";

/**
 * Method generates list of columns in manual and auto mode
 */
const generateReportColumns = (byId, _this) => {
	try {
		context = _this;
		const periodMap = context.staticData.periodMap;
		const styleList = context.staticData.styles;
		let sourceColumns = context.report.cblight__CBReportColumns__r; // list of CBColumn__c
		if (sourceColumns === undefined || sourceColumns.length === 0) {
			_message('warning', 'Please setup the report columns', 'Guideline');
			context.displayReportColumns();
			return null;
		}
		if (periodMap === undefined) {
			alert('Period Map is empty ');
			return null;
		}
		updateSourceColumns(sourceColumns, styleList);
		let resultColumns = [], byName = periodMap[byId][0].cblight__CBBudgetYear__r.Name;
		if (context.report.cblight__Mode__c === 'Manual') { // if report type is manual no columns need to be generated
			sourceColumns.forEach(col => resultColumns.push(new Column().setFields(col)));
			resultColumns = updateColumnsWithPeriodName(resultColumns, periodMap);
		} else { // generate extra columns
			const periods = periodMap[byId]; // 12 months of reported year
			context.BYIsQuarter = periods.length === 4;
			const createTemplateColumns = (per) => sourceColumns.forEach(col => resultColumns.push(new Column().setFields(col).setPeriod(per)));
			periods.forEach(per => createTemplateColumns(per));
			resultColumns = addQuarterColumns(sourceColumns, resultColumns, context.report);
			resultColumns = addYearlyTotalColumns(sourceColumns, resultColumns, context.report, byName);
		}
		resultColumns.forEach((item, index) => item.index = ++index);
		context.reportColumns = resultColumns;
	} catch (e) {
		_message('error', 'Reporting : Generate Report Columns Error: ' + e);
	}
};


//////////// PRIVATE METHODS /////////////////
/**
 * The method updates the list of columns with quarter columns
 */
const addQuarterColumns = (sourceColumns, resultColumns, report) => {
	try {
		const numberOfPeriods = resultColumns.length / sourceColumns.length; // 4 if quarter and 12 if monthly
		if (report.cblight__Mode__c === 'Manual' || !report.cblight__needQuarterTotals__c || numberOfPeriods === 4) {
			return resultColumns; // not needed
		}
		let counter = 0, quarterNumber = 0;
		let updatedColumns = [];
		let groupNum = sourceColumns.length; // number of simple columns per period. Example: (3)
		let simpleColInQuarterNum = groupNum * 3; // number of simple columns in a quarter. Example: (3*3 = 9)
		let allColInQuarterNum = groupNum * 4; // number of simple columns in a quarter with totals. Example: (3*4 = 12)
		resultColumns.forEach(col => {
			counter++;
			updatedColumns.push(col);
			if (counter === simpleColInQuarterNum) {
				counter = 0;
				sourceColumns.forEach((c, idx) => {
					let i = idx + 1; // 1, 2, 3
					const quarterCol = new Column().setFields(c);
					quarterCol.periodName = `Q${quarterNumber + 1} Total`;
					quarterCol.class = `QuarterColumn`;
					quarterCol.isTotal = true;
					quarterCol.formula = `#${quarterNumber * allColInQuarterNum + i} + #${quarterNumber * allColInQuarterNum + groupNum + i} + #${quarterNumber * allColInQuarterNum + groupNum * 2 + i}`;
					updatedColumns.push(quarterCol);
				});
				quarterNumber++; //( 1 , 2 , 3 , 4 )
			}
		});
		return updatedColumns;
	} catch (e) {
		_message('error', 'Reporting : Add Quarter Columns Error: ' + e);
	}
};
/**
 * The method add right total columns to the report
 */
const addYearlyTotalColumns = (sourceColumns, resultColumns, report, byName) => {
	try {
		if (report.cblight__Mode__c === 'Manual') {
			return resultColumns; // not needed
		}
		let updatedColumns = resultColumns;
		let hasQuarters = report.cblight__needQuarterTotals__c;
		let groupNum = sourceColumns.length; // number of simple columns per period. Example: (3)
		const BYIsQuarter = context.BYIsQuarter;
		sourceColumns.forEach((c, idx) => {
			let i = idx + 1; // shift
			const yearlyTotalCol = new Column().setFields(c);
			yearlyTotalCol.periodName = `BY${byName} Total`;
			yearlyTotalCol.class = `TotalColumn`;
			yearlyTotalCol.isTotal = true;
			if (BYIsQuarter) {
				yearlyTotalCol.formula = `#${i} + #${groupNum + i} + #${groupNum * 2 + i} + #${groupNum * 3 + i}`; // Budget year has only 4 periods (columns)
			} else {
				if (hasQuarters) {
					yearlyTotalCol.formula = `#${groupNum * 3 + i} + #${groupNum * 7 + i} + #${groupNum * 11 + i} + #${groupNum * 15 + i}`; // Yearly column based on quarters
				} else { // Yearly column based on months
					yearlyTotalCol.formula = `#${i} + #${groupNum + i} + #${groupNum * 2 + i} + #${groupNum * 3 + i} + #${groupNum * 4 + i} + #${groupNum * 5 + i} + #${groupNum * 6 + i} + #${groupNum * 7 + i} + #${groupNum * 8 + i} + #${groupNum * 9 + i} + #${groupNum * 10 + i} + #${groupNum * 11 + i}`;
				}
			}
			updatedColumns.push(yearlyTotalCol);
		});
		return updatedColumns;
	} catch (e) {
		_message('error', 'Add Yearly Total Columns Error: ' + e);
	}
};

const updateColumnsWithPeriodName = (columns, periodMap) => {
	try {
		let tmpMap = {};
		Object.values(periodMap).forEach(periodList => {
			periodList.forEach(per => tmpMap[per.Id] = per.Name);
		});
		columns.forEach(col => {
			col.periodName = tmpMap[col.periodId];
		});
		return columns;
	} catch (e) {
		_message('error', 'Reporting : Update Columns With Period Name Error: ' + e);
	}
};
/**
 * The method updates CBReportColumns with name of CBStyle
 * // TODO add cblight__CBStyle__r.Name to SELECT in CBReportSelector and replace this method
 */
const updateSourceColumns = (sourceColumns, styleList) => {
	try {
		const styleMap = styleList.reduce((map, curStyle) => {
			map[curStyle.Id] = curStyle.Name.replace(/ /g, "");
			return map;
		}, {});
		sourceColumns.forEach(col => {
			col.cblight__CBStyle__r = {Name: styleMap[col.cblight__CBStyle__c]};
		});
	} catch (e) {
		_message('error', 'Reporting : Update Source Columns Error: ' + e);
	}
};
//////////// PRIVATE METHODS /////////////////

//////////// CLASSES /////////////////////////
/**
 * Column class
 */
function Column() {
	this.class = 'GeneralColumn';
	this.index = -1;
	this.isMaster = false;
	this.field = '';
	this.formula = '';
	this.key = '';
	this.title = '-';
	this.masterColumnId = '-';
	this.periodId = '-';
	this.periodName = '-';
	this.needYTD = false;
	this.isHidden = false;
	this.unit = '$';
	this.columnId = undefined;

	/**
	 * @param col SObject
	 * @returns js object {Column}
	 */
	this.setFields = (col) => {
		const {
			cblight__CBStyle__r,
			cblight__ValueField__c,
			cblight__Formula__c,
			cblight__Type__c,
			cblight__OrderNumber__c,
			Id,
			cblight__MasterColumn__c,
			cblight__CBPeriod__c,
			cblight__CBPeriod__r,
			Name,
			cblight__NeedYTD__c,
			cblight__isHidden__c,
			cblight__Unit__c
		} = col;

		this.class = cblight__CBStyle__r?.Name || this.class;
		this.field = cblight__ValueField__c;
		this.formula = cblight__Formula__c;
		this.isMaster = cblight__Type__c === 'Master';
		this.index = cblight__OrderNumber__c;
		this.columnId = Id;
		this.masterColumnId = cblight__MasterColumn__c;
		this.periodId = cblight__CBPeriod__c;
		this.periodName = cblight__CBPeriod__r?.Name;
		this.title = Name;
		this.needYTD = cblight__NeedYTD__c;
		this.isHidden = cblight__isHidden__c;
		this.unit = cblight__Unit__c;

		return this;
	};

	this.setPeriod = (period) => {
		this.periodId = period.Id;
		this.periodName = period.Name;
		return this;
	}
}

//////////// CLASSES /////////////////////////

export {generateReportColumns};