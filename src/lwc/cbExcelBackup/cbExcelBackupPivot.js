import {_message, _setCell} from 'c/cbUtils';

let context;
let FIRST_ROW_FILL = {
	type: 'pattern',
	pattern: 'solid',
	fgColor: {argb: 'CACACA'}
};
const BOLD_FONT = {
	bold: true
};
const BOTTOM_BORDER = {
	bottom: {style: 'thin'},
};
const CURRENCY_FORMAT = '"$"#,##0;[Red]\-"$"#,##0';
const PIVOT_COLUMNS = [
	{name: 'BY', field: 'cblight__CBBudgetYear__r', isParent: true},
	{name: 'Department', field: 'cblight__CBDivision__r', isParent: true},
	{name: 'Account Type', field: 'cblight__CBAccountType__c', isParent: true},
	{name: 'Account Sub Type', field: 'cblight__CBSubAccountName__c', isParent: true},
	{name: 'Account', field: 'cblight__CBAccount__r', isParent: true},
	{name: 'Owner', field: 'Owner', isParent: true},
	{name: 'Status', field: 'cblight__Status__c', isParent: true},
	{name: 'Variable1', field: 'cblight__CBVariable1__r', isParent: true},
	{name: 'Variable2', field: 'cblight__CBVariable2__r', isParent: true},
	{name: 'Variable3', field: 'cblight__CBVariable3__r', isParent: true},
	{name: 'Variable4', field: 'cblight__CBVariable4__r', isParent: true},
	{name: 'Variable5', field: 'cblight__CBVariable5__r', isParent: true},
	{name: 'Period', field: 'cblight__CBPeriod__c', isParent: false},
	{name: 'Value', field: 'cblight__Value__c', isParent: false}
];

/**
 * Method generates pivot sheet of a backup Excel file
 */
const getPivotSheet = (pivotSheet, budgetSummary, globalCluster) => {
	try {
		let budgetLines = separateAndGetBudgetLines(globalCluster);
		populatePivotHeader(pivotSheet);
		populatePivotData(pivotSheet, budgetLines);
		console.log('budgetLines = ' + JSON.stringify(budgetLines));
	} catch (e) {
		_message('error', 'Excel Backup : Generate Pivot Sheet Error : ' + e);
	}
};
/**
 * Method refines a global cluster and return budget lines only
 */
const separateAndGetBudgetLines = (globalCluster) => {
	try {
		let budgetLines = [];
		const collectBudgetLines = (cluster) => {
			if (cluster.subClusters && cluster.subClusters.length > 0) {
				cluster.subClusters.forEach(scl => budgetLines = [...budgetLines, ...scl.lines]);
			}
			if (cluster.childClusters && cluster.childClusters.length > 0) {
				cluster.childClusters.forEach(cl => collectBudgetLines(cl));
			}
		};
		collectBudgetLines(globalCluster);
		return budgetLines;
	} catch (e) {
		_message('error', 'Excel Backup : Pivot : Separate Budget Lines Error : ' + e);
	}
};
/**
 * Method generates the first row of pivot sheet
 */
const populatePivotHeader = (pivotSheet) => {
	try {
		let orgVar = JSON.parse(localStorage.getItem('orgVariable'));
		Object.keys(orgVar).forEach(key => {
			if (key.includes('Label')) {
				let analyticLookupName = key.replace('Label', '').replace('__c', '__r');
				let column = PIVOT_COLUMNS.find(c => c.field === analyticLookupName);
				if (column) column.name = orgVar[key]
			}
		});
		const firstRow = pivotSheet.getRow(1);
		firstRow.height = 15;
		firstRow.fill = FIRST_ROW_FILL;
		firstRow.font = BOLD_FONT;
		PIVOT_COLUMNS.forEach((col, idx) => _setCell(firstRow.getCell(idx + 1), col.name, FIRST_ROW_FILL, BOLD_FONT, null, null, BOTTOM_BORDER));
		for (let i = 2; i <= PIVOT_COLUMNS.length; i++) pivotSheet.getColumn(i).width = 18;
	} catch (e) {
		_message('error', 'Excel Backup : Populate Pivot Header Error : ' + e);
	}
};
/**
 * Method populates data rows of the pivot sheet
 */
const populatePivotData = (pivotSheet, budgetLines) => {
	try {
		const periodMap = JSON.parse(localStorage.getItem('BYPeriods')).reduce((r, item) => {
			r[item.Id] = item.Name;
			return r;
		}, {});
		let rowIdx = 2;
		budgetLines.forEach(line => {
			let dataArray = [];
			PIVOT_COLUMNS.forEach(col => {
				if (!col.isParent) return null;
				let value = line[col.field];
				if (typeof value === "object") value = value.Name;
				dataArray.push(value);
			});
			line.cblight__CBAmounts__r.forEach(amount => {
				const row = pivotSheet.getRow(rowIdx++);
				let cellIdx = 1;
				dataArray.forEach(value => _setCell(row.getCell(cellIdx++), value));
				_setCell(row.getCell(cellIdx++), periodMap[amount.cblight__CBPeriod__c]);
				_setCell(row.getCell(cellIdx++), amount.cblight__Value__c, null, null, CURRENCY_FORMAT);
			});
		})
	} catch (e) {
		_message('error', 'Excel Backup : Populate Pivot Data Error : ' + e);
	}
};

export {
	getPivotSheet
};