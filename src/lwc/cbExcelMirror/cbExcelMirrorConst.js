/**
* Library for common constants and methods for Excel downloading
*/
const EXCEL_STYLE = {
	// ----- FILL -------
	headerFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'c1d4f0' } },
	totalFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: '16325c' } },
	detailsHeaderFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'd4c08a' } },
	warningFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'ffbb99' } },
	nflFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'e2f4fa' } },

	mainLineWithNFLFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: '6f9ea6' } },
	mainLineFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: '6f9ea6' } },
	nflLineFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'd4c08a' } },
	helpLineFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: '7a91eb' } },
	formulaCellFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'eb5e34' } },
	inputCellFill: { type: 'pattern', pattern: 'solid', fgColor: { argb: '00d3d3d3' } },
	// ----- FONT -------
	headerFont: { bold: true, color: { argb: '00000000' }, size: 11 }, // black bold
	totalFont: { bold: true, color: { argb: '00000000' } }, // black bold
	simpleFont: { bold: false, color: { argb: '00000000' }, size: 11 }, // black
	nflFont: { bold: false, color: { argb: '00111111' }, size: 11 }, // black
	// ----- BORDER -------
	simpleBorders: { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } },
	headerBorder: { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: 'double', color: { argb: '00000000' } }, right: { style: "thin" } },
	detailsHeaderBorder: { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: 'double', color: { argb: '005493' } }, right: { style: "thin" } },
	inputCellBorder: {
		top: { style: 'medium', color: { argb: '0000004d' } },
		left: { style: 'medium', color: { argb: '0000004d' } },
		bottom: { style: 'medium', color: { argb: '0000004d' } },
		right: { style: 'medium', color: { argb: '0000004d' } }
	},
	RIGHT_ALIGN: { horizontal: 'right' },
	INDENTED: { horizontal: 'left', indent: 1 },
};

import { _cl } from "c/cbUtils";
const BL_SHEET_NAME = 'Budget Lines';
const SERVICE_SHEET_NAME = 'Service';
const TOTAL_SHEET_NAME = 'Total';
const FIVE_NFL = [1, 2, 3, 4, 5];
const TWO_NFL = [1, 2];
const HEAD_COLOMNS_BL = ['Title', 'Type', 'CB Division', 'CB Account'];
const TAIL_COLOMNS_BL = ['Total'];
const HEAD_COLOMNS_NOT_IN_TOTAL = { 'Title': 1, 'CB Division': 1, 'CB Account': 1 };
const HEAD_COLOMNS_NOT_IN_NFL = { 'Type': 1, 'CB Division': 1, 'CB Account': 1 };
const MAX_VAR = 5;
const MAX_NFL = 2;

const ANALYTIC_MAP = [
	{ 'key': 'CB Account', 'lookup': 'cblight__CBAccount__r', 'readso': 'AccountSO', 'so': 'AccountWithTypesSO', 'field': 'cblight__CBAccount__c', 'letter': 'D', 'readerKey': ['Type', 'CB Account'], 'required': true, errAdd: ' (CB Account with Type)' },
	{ 'key': 'CB Division', 'lookup': 'cblight__CBDivision__r', 'readso': 'divisionSO', 'so': 'divisionSO', 'field': 'cblight__CBDivision__c', 'letter': 'C', 'readerKey': null, 'required': false, errAdd: '' },
	{ 'key': 'Variable 1', 'lookup': 'cblight__CBVariable1__r', 'readso': 'Var1SO', 'so': 'Var1SO', 'field': 'cblight__CBVariable1__c', 'letter': 'E', 'readerKey': null, 'required': false, errAdd: '' },
	{ 'key': 'Variable 2', 'lookup': 'cblight__CBVariable2__r', 'readso': 'Var2SO', 'so': 'Var2SO', 'field': 'cblight__CBVariable2__c', 'letter': 'F', 'readerKey': null, 'required': false, errAdd: '' },
	{ 'key': 'Variable 3', 'lookup': 'cblight__CBVariable3__r', 'readso': 'Var3SO', 'so': 'Var3SO', 'field': 'cblight__CBVariable3__c', 'letter': 'G', 'readerKey': null, 'required': false, errAdd: '' },
	{ 'key': 'Variable 4', 'lookup': 'cblight__CBVariable4__r', 'readso': 'Var4SO', 'so': 'Var4SO', 'field': 'cblight__CBVariable4__c', 'letter': 'H', 'readerKey': null, 'required': false, errAdd: '' },
	{ 'key': 'Variable 5', 'lookup': 'cblight__CBVariable5__r', 'readso': 'Var5SO', 'so': 'Var5SO', 'field': 'cblight__CBVariable5__c', 'letter': 'I', 'readerKey': null, 'required': false, errAdd: '' },
];
const ANALYTIC_MAP_NFL = [
	{ 'key': 'Layer', 'lookup': 'cblight__Layer__r', 'readso': 'LayerSO', 'so': 'LayerSO', 'field': 'cblight__Layer__c', 'letter': 'A', 'readerKey': null, 'required': true, errAdd: '' }
];

const VALIDATION_MAP = {
	cblight__CBAccount__c: 'CB Account',
	cblight__CBDivision__c: 'CB Division',
	cblight__CBVariable1__c: 'Variable 1',
	cblight__CBVariable2__c: 'Variable 2',
	cblight__CBVariable3__c: 'Variable 3',
	cblight__CBVariable4__c: 'Variable 4',
	cblight__CBVariable5__c: 'Variable 5',
};

const ORGVARIABLES_MAP = [
	{ 'key': 'Account', 'orgVariable': 'cblight__CBAccountLabel__c' },
	{ 'key': 'Division', 'orgVariable': 'cblight__CBDivisionLabel__c' },
	{ 'key': 'Variable 1', 'orgVariable': 'cblight__CBVariable1Label__c' },
	{ 'key': 'Variable 2', 'orgVariable': 'cblight__CBVariable2Label__c' },
	{ 'key': 'Variable 3', 'orgVariable': 'cblight__CBVariable3Label__c' },
	{ 'key': 'Variable 4', 'orgVariable': 'cblight__CBVariable4Label__c' },
	{ 'key': 'Variable 5', 'orgVariable': 'cblight__CBVariable5Label__c' }
];

const MAX_INPUT_CELL_VALUE = 10000000000.0;
const BUDGET_LINES_PER_TRANSACTION = 100;

const ANALYTIC_MAP_BY_COLUMN_HEADER = {
	'Variable 1': 'cblight__CBVariable1__c',
	'Variable 2': 'cblight__CBVariable2__c',
	'Variable 3': 'cblight__CBVariable3__c',
	'Variable 4': 'cblight__CBVariable4__c',
	'Variable 5': 'cblight__CBVariable5__c'
};

const EMPTY_BUDGET_LINE = {
	Name: '',
	cblight__CBAccountType__c: '',
	cblight__CBAccount__c: '',
	cblight__CBDivision__c: '',
	cblight__CBVariable1__c: '',
	cblight__CBVariable2__c: '',
	cblight__CBVariable3__c: '',
	cblight__CBVariable4__c: '',
	cblight__CBVariable5__c: '',
	cblight__isFormulaBudgetLine__c: true,
	cblight__CBAmounts__r: [],
	cblight__NFLFormula__c: '#1 * #2'
};
const EMTY_NFL_LINE = { 'cblight__LayerTitle__c': 'Price', 'cblight__CBAccountType__c': '', "cblight__NonFinancialItems__r": [] };

const EMPTY_LINES_COUNT = 1;
const SERVICE_ACCOUNT_COLUMN_LETTER = 'B';

const KNOWN_FORMULAS = {
	"INDIRECT(ADDRESS(ROW()+1,COLUMN()))*INDIRECT(ADDRESS(ROW()+2,COLUMN()))": '#1 * #2',
	"INDIRECT(ADDRESS(ROW()+1,COLUMN()))+INDIRECT(ADDRESS(ROW()+2,COLUMN()))": '#1 + #2',
	"INDIRECT(ADDRESS(ROW()+1,COLUMN()))/INDIRECT(ADDRESS(ROW()+2,COLUMN()))": '#1 / #2',
	"INDIRECT(ADDRESS(ROW()+1,COLUMN()))-INDIRECT(ADDRESS(ROW()+2,COLUMN()))": '#1 - #2'
}

const nflStatic = 'Static';
const nflCustom = 'Custom';

/**
* Translate Excel column number to letter 
*/
const numToExcelColumn = (num) => {
	let letter = "", t;

	while (num > 0) {
		t = (num - 1) % 26;
		letter = String.fromCharCode(65 + t) + letter;
		num = (num - t) / 26 | 0;
	}
	return letter;
}

/**
*  Return period map in Excel start from 1 with Period Number key
* @param periodsFromDB
*/
const getPeriodByNumberFromDB = (periodsFromDB) => {
	let periodByNumber = {};
	periodsFromDB.forEach((item, index) => {
		periodByNumber[index + 1] = periodsFromDB[index];
	});
	return periodByNumber;
}

/**
*  Return period number map in Excel start from 1 with Id key  
* @param periodByNumber  
*/
const getPeriodNumberById = (periodByNumber) => {
	let periodNumberById = {};
	let periodsCount = Object.keys(periodByNumber).length;
	for (let j = 1; j <= periodsCount; j++) {
		let periodId = periodByNumber[j].Id;
		periodNumberById[periodId] = j;
	}
	return periodNumberById;
}

/**
*  Return columns map based on params   
* @param periodByNumber  
* @param headColumnsList  
* @param tailColumnsList  
*/
const getOrderOfColumns = (periodByNumber, headColumnsList, tailColumnsList, serviceColumns) => {
	let periodsCount = Object.keys(periodByNumber).length;
	let columns = {};
	let i = 1;
	headColumnsList.forEach(title => {
		columns[title] = {
			letter: numToExcelColumn(i),
			name: title,
			isPeriod: false,
			isAnalytic: false,
			isTotal: !HEAD_COLOMNS_NOT_IN_TOTAL[title],
			isNFL: !HEAD_COLOMNS_NOT_IN_NFL[title],
			number: i++,
			key: title,
		};
	});
	for (let j = 1; j <= MAX_VAR; j++) {
		let columnKey = 'cblight__CBVariable' + j + '__c';
		if (serviceColumns[columnKey]) {
			let columnParam = serviceColumns[columnKey];
			columns[columnParam.header] = {
				letter: numToExcelColumn(i),
				name: columnParam.header,
				isPeriod: false,
				isAnalytic: true,
				isTotal: false,
				isNFL: false,
				number: i++,
				key: columnParam.header
			};
		}
	}
	for (let j = 1; j <= periodsCount; j++) {
		columns['p' + j] = {
			letter: numToExcelColumn(i),
			name: periodByNumber[j].Name,
			isPeriod: true,
			isAnalytic: false,
			isTotal: true,
			isNFL: true,
			periodNumber: j,
			period: periodByNumber[j],
			number: i++,
			key: 'p' + j
		}; // Excel do not save the key of column.
	};
	tailColumnsList.forEach(title => {
		columns[title] = {
			letter: numToExcelColumn(i),
			name: title,
			isPeriod: false,
			isAnalytic: false,
			isTotal: !HEAD_COLOMNS_NOT_IN_TOTAL[title],
			isNFL: false,
			number: i++,
			key: title
		};
	});
	return columns;
}

/**
* Set Columns name from cblight__CBOrgVariable__c  in BL Sheet only
* @param columns  
* @param orgVariable    
*/
const setTitlesFromOrgVariable = (columns, orgVariable) => {
	ORGVARIABLES_MAP.forEach(elem => {
		if (orgVariable[elem['orgVariable']] && columns[elem['key']]) {
			columns[elem['key']].name = orgVariable[elem['orgVariable']];
		}
	});
}

/**
* Translate key to column number 
* @param columns  
* @param key    
*/
const getColumnNumberByColumnKey = (columns, key) => {
	return columns[key].number;
}


/**
* Translate key to column letter 
* @param columns  
* @param key    
*/
const getColumnLetterByColumnKey = (columns, key) => {
	return numToExcelColumn(columns[key].number);
}

/**
* Translate key to column name
* @param columns  
* @param key  
*/
const getColumnNameByColumnKey = (columns, key) => {
	return columns[key].name;
}

/**
* Translate key to column number and return row cell value by number
* @param row
* @param columns  
* @param key  
*/
const getValueFromRowCellByColumnKey = (row, columns, key) => {
	return getValueFromCell(row.getCell(getColumnNumberByColumnKey(columns, key)));
}

/**
* Get value from cell
* @param cell
*/
const getValueFromCell = (cell) => {
	if (!cell) {
		return "Cell error";
	}
	let tmpValue = cell.value;
	if (tmpValue && typeof tmpValue === 'object' && (tmpValue["formula"] || tmpValue["sharedFormula"])) {
		tmpValue = tmpValue["result"];
		if (tmpValue.error) {
			return "Formula error";
		}
	}
	return tmpValue;
}

/**
* Translate key to column number and return row cell formula by number
* @param row
* @param columns  
* @param key  
*/
const getFormulaFromRowCellByColumnKey = (row, columns, key) => {
	let tmpValue = row.getCell(getColumnNumberByColumnKey(columns, key)).value;
	if (tmpValue && typeof tmpValue === 'object' && tmpValue["formula"]) {
		tmpValue = tmpValue["formula"];
	} else {
		tmpValue = null;
	}
	return tmpValue;
}

/**
*  Convert array to object
*/
const convertArrayToObject = (array, key) => {
	return array.reduce((acc, curr) => {
		acc[curr[key]] = curr;
		return acc;
	}, {});
}

export {
	BL_SHEET_NAME, SERVICE_SHEET_NAME, EXCEL_STYLE, numToExcelColumn, FIVE_NFL, TWO_NFL, HEAD_COLOMNS_BL, TAIL_COLOMNS_BL, getOrderOfColumns,
	getPeriodNumberById, getPeriodByNumberFromDB, ORGVARIABLES_MAP, setTitlesFromOrgVariable, getValueFromRowCellByColumnKey,
	ANALYTIC_MAP, ANALYTIC_MAP_NFL, VALIDATION_MAP, MAX_INPUT_CELL_VALUE, BUDGET_LINES_PER_TRANSACTION, ANALYTIC_MAP_BY_COLUMN_HEADER,
	convertArrayToObject, EMPTY_BUDGET_LINE, EMPTY_LINES_COUNT, SERVICE_ACCOUNT_COLUMN_LETTER, TOTAL_SHEET_NAME,
	HEAD_COLOMNS_NOT_IN_TOTAL, MAX_NFL, getColumnLetterByColumnKey, getFormulaFromRowCellByColumnKey, getValueFromCell, getColumnNumberByColumnKey,
	KNOWN_FORMULAS, nflCustom, EMTY_NFL_LINE

};