import {getReportLinesWithYTDValues} from './cbReportingYTD';
import {addCustomSubtotalLines} from './cbReportingSubtotalLine';
import {_cl, _getCopy, _message} from "c/cbUtils";

let context; // this of the parent component
const NA_TITLE = 'N/A';
const POSITIVE_SIGN = '+';
let showTopTotal = false;
let showBottomTotal = true;
let showHeader = false;

const generateReportLines = (_this) => {
	try {
		context = _this;
		detectSubtotalMode();
		if (context.reportColumns === null || context.reportColumns.length === 0) {
			return null;
		}
		let reportLines = {};
		context.reportData.forEach(cube => generateReportLineFromCBCube(cube, context.reportColumns, context.configuration, reportLines));
		reportLines = Object.values(reportLines);
		reportLines = sortReportLines(reportLines, context.configuration.cblight__Grouping__c);
		reportLines = getGroupedReportLines(reportLines, context.configuration);
		reportLines = getReportLinesWithYTDValues(reportLines, context.reportColumns);
		reportLines = addGlobalTotalToReportLines(reportLines);
		reportLines = getTotalOnlyReportLines(reportLines, context.report);
		reportLines = addCustomSubtotalLines(reportLines, context.configuration.cblight__SubRows__c);
		reportLines = updateDisplayUnits(reportLines);
		reportLines = getUnitFormattedAndIndexedReportLines(reportLines, context.reportColumns);
		reportLines = updateReportLinesDrillDownKeys(reportLines);
		context.reportLines = reportLines;
	} catch (e) {
		_message('error', `Reporting : Generate Report Lines Error: ${e}`);
	}
};

const detectSubtotalMode = () => {
	switch (context.report.cblight__SubtotalMode__c) {
		case 'Top':
			showTopTotal = true;
			showHeader = false;
			showBottomTotal = false;
			break;
		case 'Bottom':
			showTopTotal = false;
			showHeader = false;
			showBottomTotal = true;
			break;
		case 'BottomWithHeader':
			showTopTotal = false;
			showHeader = true;
			showBottomTotal = true;
			break;
		default:
	}
};


//////////// PRIVATE METHODS /////////////////
const generateReportLineFromCBCube = (cube, reportColumns, configuration, reportLines) => {
	try {
		const lineKey = getLineKey(cube, configuration.cblight__Grouping__c);
		let reportLine = reportLines[lineKey];
		if (reportLine === undefined) {
			reportLine = getNewReportLine(cube, configuration.cblight__Grouping__c, reportColumns);
			reportLines[lineKey] = reportLine;
		}
		updateReportLineWithValues(cube, reportLine.reportCells);
		calculateReportLine(reportLine.reportCells);
	} catch (e) {
		_message('error', `Reporting : Generate Report Line From CBCube Error: ${e}`);
	}
};

/**
 * ID key of line
 */
const getLineKey = (cube, grouping) => {
	try {
		let key = '';
		grouping.forEach(field => key += cube[field]);
		return key;
	} catch (e) {
		_message('error', `Reporting : Get Line Key Error: ${e}`);
	}
};

/**
 * The method returns a new populated with zero report line
 * CB Cube creates a Report line with cells
 * @param cube cblight__CBCube__c of source data
 * @param grouping
 * @param reportColumns
 * @returns {ReportLine}
 */
const getNewReportLine = (cube, grouping, reportColumns) => {
	try {
		let reportLine = new ReportLine(), label, updatedField;
		reportLine.signIsPositive = cube.cblight__Sign__c === POSITIVE_SIGN;
		grouping.forEach(f => { // three cases: Name , cblight__CBAccount__r.Name,  KPI__c (text formula field)
			if (cube[f]) { // value exist in a cube
				updatedField = f.replace('__c', '__r');
				label = cube[updatedField] && f.endsWith('_c') ? cube[updatedField].Name : cube[f];
			} else {
				label = NA_TITLE; // lookup is not specified
			}
			reportLine.labels.push(label);
			reportLine.keys.push(cube[f]);
		});
		// Create report line cells from columns
		reportColumns.forEach(column => {
			let newCell = new Cell();
			newCell.periodId = column.periodId;
			newCell.field = column.field;
			newCell.unit = column.unit;
			newCell.class = column.class;
			newCell.formula = column.formula;
			reportLine.reportCells.push(newCell);
		});
		return reportLine;
	} catch (e) {
		_message('error', `Reporting : Get New Report Line Error : ${e}`);
	}
};
/**
 * The method sets values to cells of simple columns
 */
const updateReportLineWithValues = (cube, reportCells) => {
	try {
		reportCells.forEach(cell => {
			const {periodId, field} = cell;
			if (field === undefined || cube.cblight__CBPeriod__c !== periodId || !cube[field]) {
				return;
			}
			cell.value += Number(cube[field]);
		});
	} catch (error) {
		console.error(`Reporting: Update Report Line with Values Error: ${error}`);
	}
};
/**
 * The method calculates formula value from the left to the right
 */
const calculateReportLine = (reportCells) => {
	try {
		reportCells.forEach(cell => {
			if (cell.formula !== undefined && cell.formula.length > 1) {
				cell.value = getFormulaValue(cell.formula, reportCells);
				cell.isTotal = true;
			}
		});
	} catch (e) {
		_message('error', `Reporting : Calculate Report Line Error : ${e}`);
	}
};
/**
 * Using formula and list of report cells, the method returns calculated value
 */
const getFormulaValue = (formula, reportCells) => {
	try {
		let mathString = '';
		const pattern = /([()+\-*/]|\d+\.\d+|\d+|#\d+)/g;
		formula.match(pattern).forEach((k) => {
			if (k.startsWith('#')) {
				k = k.replace('#', '');
				mathString += reportCells[--k].value;
			} else {
				mathString += ` ${k} `;
			}
		});
		let result = eval(mathString);
		return isNaN(result) ? 0 : parseFloat(result.toFixed(2));
	} catch (e) {
		_message('error', `Reporting : Get Formula Value Error : ${e}`);
		return 0;
	}
};


/////////////// SORTING /////////////////
/**
 * The method sorts report lines starting from the first group
 */
const sortReportLines = (reportLines, grouping) => {
	const compare = (a, b) => {
		for (let lvl = 0; lvl < grouping.length; lvl++) {
			if (a.labels[lvl] < b.labels[lvl]) {
				return -1;
			}
			if (a.labels[lvl] > b.labels[lvl]) {
				return 1;
			}
		}
		return 0;
	};
	return reportLines.sort(compare);
};
/////////////// SORTING /////////////////

/////////////// GROUPING ////////////////
const getGroupedReportLines = (reportLines, configuration) => {
	try {
		let grouping = configuration.cblight__Grouping__c;
		let groupingLength = grouping.length;
		let subtotalNumber = configuration.cblight__SubtotalNumber__c;
		if (subtotalNumber > groupingLength) {
			subtotalNumber = groupingLength;
		}
		for (let lvl = subtotalNumber - 1; lvl >= 0; lvl--) {
			let updatedReportLines = [];
			let tempSection = [];
			let currentKey = getKey(reportLines[0], lvl);
			reportLines.forEach((rl) => {
				let rKey = getKey(rl, lvl);
				if (rKey !== currentKey) {
					updatedReportLines = [...updatedReportLines, ...new SubSection(tempSection, lvl).reportLines]; //closed section is added
					tempSection = [];
					currentKey = rKey;
				}
				tempSection.push(rl);
			});
			updatedReportLines = [...updatedReportLines, ...new SubSection(tempSection, lvl).reportLines]; //last section always added
			reportLines = updatedReportLines;
		}

		return reportLines;
	} catch (e) {
		_message('error', `Reporting : Get Grouped Report Lines Error : ${e}`);
	}
};


const getKey = (rl, lvl) => rl.keys.slice(0, lvl + 1).join('');

/**
 * The method returns a new group line needed level
 * @param reportLine as for a template
 * @param lvl (0 || 1 || 2 || 3) level of grouping
 * @returns {any}
 */
const getNewTotalLine = (reportLine, lvl) => {
	const totalRL = _getCopy(reportLine);
	const totalLineClass = `TotalLineLvl${lvl}`;
	totalRL.reportCells.forEach(cell => {
		cell.value = 0;
		cell.class = totalLineClass;
		cell.isTotal = true;
	});
	totalRL.isTotal = true;
	totalRL.class = totalLineClass;
	let totalLabels = [];
	totalRL.labels.forEach((l, idx) => totalLabels.push(idx === lvl ? `${l}  Total` : ''));
	totalRL.labels = totalLabels;
	return totalRL;
};
/**
 * The method returns a new header line needed level
 * @param reportLine as for a template
 * @param lvl (0 || 1 || 2 || 3) level of grouping
 * @returns {any}
 */
const getNewHeaderLine = (reportLine, lvl) => {
	const headerRL = _getCopy(reportLine);
	const totalLineClass = `TotalLineLvl${lvl}`;
	headerRL.reportCells.forEach(cell => {
		cell.value = null;
		// cell.class = totalLineClass;
		cell.isTotal = true;
		cell.isHeader = true;
	});
	headerRL.isTotal = true;
	headerRL.isHeader = true;
	headerRL.class = totalLineClass;
	let totalLabels = [];
	headerRL.labels.forEach((l, idx) => totalLabels.push(idx === lvl ? `${l} ` : ''));
	headerRL.labels = totalLabels;
	return headerRL;
};
/**
 * Private method to calculate two report lines
 * @param totalRL result line
 * @param simpleRL simple line
 */
const sumReportLines = (totalRL, simpleRL) => {
	totalRL.reportCells.forEach((tCell, idx) => {
		const sCell = simpleRL.reportCells[idx];
		tCell.value += simpleRL.signIsPositive ? Number(sCell.value) : -Number(sCell.value);
	});
};

/**
 * The method calculates lines and adds a global total to the end of list
 */
const addGlobalTotalToReportLines = (reportLines) => {
	let globalTotalLine = getNewTotalLine(reportLines[0], 'Global');
	globalTotalLine.isHeader = false;
	globalTotalLine.labels.forEach(l => l = '');
	globalTotalLine.labels[0] = 'TOTAL';
	reportLines.forEach(rl => {
		if (rl.isTotal) return null; // skip already calculated lines
		sumReportLines(globalTotalLine, rl);
	});
	reportLines.push(globalTotalLine);
	return reportLines;
};
/////////////// GROUPING ////////////////

/////////////// FORMATTING //////////////
/**
 * Method converts amounts to string in currency or percent format
 */
const getUnitFormattedAndIndexedReportLines = (reportLines, reportColumns) => {
	try {
		const floatPointOption = context.configuration.cblight__FloatPointCell__c;
		let numberFormatSettings;

		if (floatPointOption === '1.00') {
			numberFormatSettings = {
				currency: {minimumFractionDigits: 2, maximumFractionDigits: 2},
				percent: {minimumFractionDigits: 2, maximumFractionDigits: 2},
			};
		} else if (floatPointOption === '1.0') {
			numberFormatSettings = {
				currency: {minimumFractionDigits: 1, maximumFractionDigits: 1},
				percent: {minimumFractionDigits: 1, maximumFractionDigits: 1},
			};
		} else if (floatPointOption === '1') {
			numberFormatSettings = {
				currency: {minimumFractionDigits: 0, maximumFractionDigits: 0},
				percent: {minimumFractionDigits: 0, maximumFractionDigits: 0},
			};
		}
		const currencyFormat = new Intl.NumberFormat('en-US', {
			style: 'currency',
			currency: context.currencyCode,
			...numberFormatSettings.currency,
		});

		const percentFormat = new Intl.NumberFormat('en-US', {
			style: 'percent',
			...numberFormatSettings.percent,
		});

		const du = context.configuration.cblight__DisplayUnits__c;
		const displayUnits = !du || du === 'Whole Units' ? '' : (du === 'Thousands' ? 'K' : 'M');
		reportLines.forEach((rl, idx) => {
			if (!rl.isFormatted && !rl.isHeader) {
				rl.reportCells.forEach((cell, i) => {
					if (cell.unit === '$') {
						cell.value = currencyFormat.format(+cell.value);
						cell.value += displayUnits;
					} else if (cell.unit === '%') {
						cell.value = percentFormat.format(+cell.value);
					}
					cell.isHidden = reportColumns[i].isHidden;
				});
			} else {
				_cl('skipped rl: ' + JSON.stringify(rl));
			}
			rl.idx = idx + 1;
			rl.isFormatted = true;
		});
		return reportLines;
	} catch (e) {
		_message('error', `Reporting : Currency Formatted Report Lines Error : ${e}`);
	}
};
/////////////// FORMATTING //////////////

/////////////// TOTAL ONLY //////////////
/**
 * Report lines filter skip simple lines if needed
 */
const getTotalOnlyReportLines = (reportLines, report) => {
	if (!report.cblight__needOnlyTotal__c) return reportLines;
	let totals = reportLines.filter(rl => rl.isTotal && !rl.isHeader);
	return totals;
};
/////////////// TOTAL ONLY //////////////
/**
 * Method sets special keys for the report Drill Down to each cell
 * @param reportLines
 * @returns {*}
 */
const updateReportLinesDrillDownKeys = reportLines => {
	for (let rowIdx = 0; rowIdx < reportLines.length; rowIdx++) {
		const rl = reportLines[rowIdx];
		for (let cellIdx = 0; cellIdx < rl.reportCells.length; cellIdx++) {
			const cell = rl.reportCells[cellIdx];
			cell.drillDownKey = `${rowIdx}&${cellIdx}`;
		}
	}
	return reportLines;
};

/**
 * Method converts amounts to thousands or millions if needed
 */
const updateDisplayUnits = reportLines => {
	const du = context.configuration.cblight__DisplayUnits__c;
	if (!du || du === 'Whole Units') return reportLines;
	const divisor = du === 'Thousands' ? 1000 : 1000000;
	for (let rowIdx = 0; rowIdx < reportLines.length; rowIdx++) {
		const rl = reportLines[rowIdx];
		for (let cellIdx = 0; cellIdx < rl.reportCells.length; cellIdx++) {
			const cell = rl.reportCells[cellIdx];
			cell.value /= divisor;
		}
	}
	return reportLines;
};

//////////// CLASSES /////////////////////////
/**
 * SubSection of the report with totals on both sides
 */
class SubSection {
	reportLines = [];

	constructor(reportLines, lvl) {
		if (reportLines) {
			this.reportLines = reportLines;
			this.lvl = lvl;
			this.prepareHeaderAndTotalLine();
			this.calculateTotals();
			this.addTotalsToSection();
		}
	}

	prepareHeaderAndTotalLine() {
		for (let i = 0; i < this.reportLines.length; i++) {
			if (!this.reportLines[i].isTotal) {
				this.totalLine = getNewTotalLine(this.reportLines[i], this.lvl);
				this.headerLine = getNewHeaderLine(this.reportLines[i], this.lvl);
				break;
			}
		}
	}

	calculateTotals() {
		this.reportLines.forEach((rl) => {
			if (!rl.isTotal) {
				sumReportLines(this.totalLine, rl);
			}
		});
	}

	addTotalsToSection() {
		if (showHeader) {
			this.reportLines.unshift(this.headerLine);
		}
		if (showTopTotal) {
			this.reportLines.unshift(this.totalLine);
		}
		if (showBottomTotal) {
			this.reportLines.push(this.totalLine);
		}
	}
}

/**
 * ReportLine class
 */
function ReportLine() {
	this.class = '';
	this.idx = 1;
	this.isTotal = false;
	this.key = '-';
	this.keys = [];
	this.labels = [];
	this.reportCells = []; // columnsKey and cell
	this.signIsPositive = true; // true if '+'
}

/**
 * One report cell
 */
function Cell() {
	this.class = 'GeneralColumn'; // columnsKey and cell
	this.formula = '';
	this.field = '';
	this.periodId = '';
	this.value = 0;
	this.unit = '';
	this.isHidden = false;
	this.isTotal = false;
	this.drillDownKey = ''
}

//////////// CLASSES /////////////////////////


export {generateReportLines};