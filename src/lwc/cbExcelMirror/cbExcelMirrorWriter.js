/**
* Library for downloading Budget Lines to Excel
*/
import getBLForExcelServer from "@salesforce/apex/CBExcelMirrorPageController.getBLForExcelServer";

import { _applyDecStyle, _cl, _generateFakeId, _getCopy, _message, _parseServerError } from "c/cbUtils";
import { addHeader } from "./cbExcelMirrorHeader";
import {
	BL_SHEET_NAME, SERVICE_SHEET_NAME, EXCEL_STYLE, setTitlesFromOrgVariable, ANALYTIC_MAP, VALIDATION_MAP,
	EMPTY_BUDGET_LINE, EMPTY_LINES_COUNT, FIVE_NFL, TOTAL_SHEET_NAME, EMTY_NFL_LINE, numToExcelColumn, getValueFromRowCellByColumnKey, getValueFromCell, getColumnNumberByColumnKey
} from "./cbExcelMirrorConst";

/**
* Fill row  amounts for Excel export
*/
const fillTitleRow = (columns) => {
	try {
		let row = {};
		Object.entries(columns).forEach(([key, value]) => {
			row[key] = value.name;
		});
		return row;
	} catch (e) {
		throw new Error(`Fill Title Row ${e}`);
	}
}

/**
* Fill row  amounts for Excel export
*/
const fillTotalRow = (accountType, columns, firstNumberLetter, lastNumberLetter) => {
	try {
		let row = {};
		row['Total'] = { formula: 'SUM(INDIRECT("' + firstNumberLetter + '"& ROW()):INDIRECT("' + lastNumberLetter + '"& ROW()))', result: 0 };
		row['Title'] = accountType.toUpperCase() + ' TOTAL'
		Object.entries(columns).forEach(([key, value]) => {
			if (value.isPeriod) {
				row[key] = { formula: 'SUMIF(B:B,"' + accountType + '",' + value.letter + ':' + value.letter + ')', result: 0 };
			}
		});
		return row;
	} catch (e) {
		throw new Error(`Fill Total Row ${e}`);
	}
}

/**
 * Add Budget Line Sheet method
 * @param budgetLines array of Budget
 * @param workbook workbook
 * @param periodByNumber
 * @param serviceSheetData
 * @param nflSheetData
 */
const addBudgetLinesSheet = (_this, budgetLines, blSheet, totalSheet) => {
	try {
		setTitlesFromOrgVariable(_this.columns, _this.orgVariable);
		let blColumns = [];

		Object.entries(_this.columns).forEach(([key, value]) => {
			if (value.name === 'Title') {
				blColumns.push({ key: value.key, width: 40 });
			} else
				if (value.name === 'Total') {
					blColumns.push({ key: value.key, width: 20, style: { numFmt: '$ #,##0;[Red]($ #,##0)', font: EXCEL_STYLE.headerFont } });
				} else
					if (value.isPeriod) {
						blColumns.push({ key: value.key, width: 20, style: { numFmt: '$ #,##0;[Red]($ #,##0)' } });
					} else {
						blColumns.push({ key: value.key, width: 20 });
					}
		});
		blSheet.columns = blColumns;
		addHeader(blSheet);
		addAccountTypesToBudgetLinesSheet(_this, budgetLines, blSheet, totalSheet);

		return 'Ok';
	} catch (e) {
		throw new Error(`Add Budget Lines Sheet ${e}`);
	}
}

const addTotalSheet = (_this, blSheet, totalSheet) => {
	try {
		let totalColumns = [];
		Object.entries(_this.columns).forEach(([key, value]) => {
			if (value.name === 'Total') {
				totalColumns.push({ header: value.name, key: value.key, width: 20, style: { numFmt: '$ #,##0;[Red]($ #,##0)', font: EXCEL_STYLE.headerFont } });
			} else
				if (value.isPeriod) {
					totalColumns.push({ header: value.name, key: value.key, width: 20, style: { numFmt: '$ #,##0;[Red]($ #,##0)' } });
				} else
					if (value.name === 'Type') {
						totalColumns.push({ header: value.name, key: value.key, width: 20 });
					}
		});
		totalColumns.push({ header: "\u00B1", key: "Sign", width: 20, style: { numFmt: '+;[Red]-', font: EXCEL_STYLE.headerFont } });
		totalColumns.push({ header: "\u00B1Total", key: "Total*Sign", width: 20, style: { numFmt: '$ #,##0;[Red]($ #,##0)', font: EXCEL_STYLE.headerFont } });
		totalSheet.columns = totalColumns;
		totalSheet.getRow(1).eachCell({ includeEmpty: true }, (cell, cellNumber) => { // header
			cell.font = EXCEL_STYLE.headerFont;
			cell.border = EXCEL_STYLE.headerBorder;
			cell.fill = EXCEL_STYLE.headerFill;
		});
	} catch (e) {
		throw new Error(`Add Total Sheet ${e}`);
	}
}

/**
 * Compare Budget Lines for Excel
 */
const compareBL = (a, b) => {
	let divNameA = a.cblight__CBDivision__c && a.cblight__CBDivision__r.Name ? a.cblight__CBDivision__r.Name : '';
	let divNameB = b.cblight__CBDivision__c && b.cblight__CBDivision__r.Name ? b.cblight__CBDivision__r.Name : '';
	if (divNameA != divNameB) { return divNameA > divNameB ? 1 : -1 };
	return a.Name === b.Name ? 0 : a.Name > b.Name ? 1 : -1;
}

/**
* Add Account Types  to Budget Line Sheet
*/
const addTotalRowToTotalSheet = (blSheet, totalSheet, columns, color, accType, accTypeSign) => {
	try {
		let rowNew = {};
		let formulaTmp = '';
		Object.entries(columns).forEach(([key, value]) => {
			if (!value.isTotal) {
				return true;
			}
			formulaTmp = "'" + BL_SHEET_NAME + "'!$" + value.letter + blSheet.rowCount;
			rowNew[key] = { formula: formulaTmp, result: 0 };
		});
		rowNew['Type'] = accType;
		rowNew['Sign'] = accTypeSign;
		rowNew['Total*Sign'] = { formula: "" + accTypeSign + "*(" + formulaTmp + ")", result: 0 };
		totalSheet.addRow(rowNew);
		let tmpRow = totalSheet.getRow(totalSheet.rowCount);
		rowColor(tmpRow, color);
		return tmpRow;
	} catch (e) {
		throw new Error(`Add Total row to Total Sheet ${e}`);
	}
}

/**
* Add Grand Total to Total Sheet
*/
const addGrandTotalRowToTotalSheet = (totalSheet, _this, grandTotalSignedSumByPeriod) => {
	try {
		let signColumnLetter = numToExcelColumn(totalSheet.columnCount - 1);
		let rowMaxNumber = totalSheet.rowCount;
		let totalRowNumber = rowMaxNumber + 1;
		let rowNew = {};
		let periodLetter;
		let sumSign = 0;
		rowNew['Type'] = '\u00B1Total';
		Object.values(_this.columns).forEach(value => {
			if (!value.isPeriod) {
				return true;
			}
			periodLetter = numToExcelColumn(value.periodNumber + 1);
			sumSign += grandTotalSignedSumByPeriod[value.key];
			rowNew[value.key] = { formula: 'SUMPRODUCT(' + periodLetter + '2:' + periodLetter + rowMaxNumber + ',' + signColumnLetter + '2:' + signColumnLetter + rowMaxNumber + ')', result: grandTotalSignedSumByPeriod[value.key] };
		});

		rowNew['Total'] = { formula: 'SUM(B' + totalRowNumber + ':' + periodLetter + totalRowNumber + ')', result: sumSign };
		rowNew['Sign'] = '';
		rowNew['Total*Sign'] = { formula: 'SUM(INDIRECT(ADDRESS(2,COLUMN())&":"&ADDRESS(ROW()-1,COLUMN())))', result: sumSign };

		totalSheet.addRow(rowNew);
		let tmpRow = totalSheet.getRow(totalSheet.rowCount);
		tmpRow.eachCell({ includeEmpty: true }, (cell, cellNumber) => { // header
			cell.font = EXCEL_STYLE.headerFont;
			cell.border = EXCEL_STYLE.simpleBorders;
			cell.fill = EXCEL_STYLE.headerFill;
		});
		return tmpRow;
	} catch (e) {
		throw new Error(`Add Grand Total row to Total sheet ${e}`);
	}
}

const updateTotalRow = (rowTotal, row, _this, sign, rowGlobalTotal, grandTotalSignedSumByPeriod) => {
	try {
		let currentTotalTotalCell = rowTotal.getCell('Total');
		let tmpTotalTotalCellValue = currentTotalTotalCell.value;

		let currentRowTotalCell = row.getCell('Total');
		let tmpRowTotalCellValue = currentRowTotalCell.value;

		let currentGlobalTotalCell = rowGlobalTotal.getCell('Total');
		let tmpCurrentGlobalTotalCellValue = currentGlobalTotalCell.value;

		let currentGlobalTotalSignCell = rowGlobalTotal.getCell('Total*Sign');
		let tmpCurrentGlobalTotalSignCellValue = currentGlobalTotalSignCell.value;

		_this.periodData.periodKeys.forEach(key => {
			let currentTotalCell = rowTotal.getCell(key);
			let tmpCurrentTotalCellValue = currentTotalCell.value;

			let currentGlobalCell = rowGlobalTotal.getCell(key)
			let tmpCurrentGlobalCellValue = currentGlobalCell.value;

			let delta = getValueFromRowCellByColumnKey(row, _this.columns, key);

			tmpCurrentTotalCellValue.result += delta;
			tmpCurrentGlobalCellValue.result += delta;

			tmpTotalTotalCellValue.result += delta;
			tmpRowTotalCellValue.result += delta;

			tmpCurrentGlobalTotalCellValue.result += delta;
			tmpCurrentGlobalTotalSignCellValue.result += delta * sign;
			grandTotalSignedSumByPeriod[key] += delta * sign;
			currentTotalCell.value = tmpCurrentTotalCellValue;
			currentGlobalCell.value = tmpCurrentGlobalCellValue;
		});
		currentTotalTotalCell.value = tmpTotalTotalCellValue;
		currentGlobalTotalCell.value = tmpCurrentGlobalTotalCellValue;
		currentRowTotalCell.value = tmpRowTotalCellValue;
		currentGlobalTotalSignCell.value = tmpCurrentGlobalTotalSignCellValue;
	} catch (e) {
		throw new Error(`Update total row ${e}`);
	}
}
/**
* Add Account Types  to Budget Line Sheet
*/
const addAccountTypesToBudgetLinesSheet = (_this, budgetLines, blSheet, totalSheet) => {
	try {
		let grandTotalSignedSumByPeriod = {};
		_this.periodData.periodKeys.forEach(key => grandTotalSignedSumByPeriod[key] = 0);

		_this.accTypesWithStylesNames.forEach(accType => {
			if (!_this.accTypesFoormulae[accType["Id"]]) { // Check , if account type includes accounts
				return;
			}
			let bgColor = (accType["cblight__CBStyle__c"] && _this.stylesForAccountTypes[accType["cblight__CBStyle__c"]]["cblight__BackgroundColor__c"]) ?
				_this.stylesForAccountTypes[accType["cblight__CBStyle__c"]]["cblight__BackgroundColor__c"] : "FFFFFFFF";
			bgColor = { type: 'pattern', pattern: 'solid', fgColor: { argb: bgColor.replace('#', '00') } };
			blSheet.addRow(fillTotalRow(accType.Name, _this.columns, _this.periodData.firstNumberLetter, _this.periodData.lastNumberLetter));
			let tmpExcelTotalRow = blSheet.getRow(blSheet.rowCount);
			rowColor(tmpExcelTotalRow, bgColor);
			let tmpExcelTotalRowTotal = addTotalRowToTotalSheet(blSheet, totalSheet, _this.columns, bgColor, accType.Name, accType.cblight__Sign__c == '-' ? -1 : 1);
			blSheet.addRow(fillTitleRow(_this.columns));
			rowColor(blSheet.getRow(blSheet.rowCount), bgColor);

			let row;
			let filteredLines = budgetLines.filter(element => element['cblight__CBAccountType__c'] === accType.Name).sort(compareBL);
			if (!filteredLines.length) {
				filteredLines = makeTemplatesArray(accType.Name, _this);
			}
			filteredLines.forEach(element => {
				row = makeExcelRow(_this, element);
				fillRowAmounts(element, row, _this.periodData.periodNumberById, _this);
				row['Total'] = { formula: 'SUM(INDIRECT("' + _this.periodData.firstNumberLetter + '"& ROW()):INDIRECT("' + _this.periodData.lastNumberLetter + '"& ROW()))', result: 0 };
				blSheet.addRow(row);
				let tmpExcelRow = blSheet.getRow(blSheet.rowCount);
				updateTotalRow(tmpExcelTotalRow, tmpExcelRow, _this, accType.cblight__Sign__c === '-' ? -1 : 1, tmpExcelTotalRowTotal, grandTotalSignedSumByPeriod);

				rowsValidation(blSheet.getRow(blSheet.rowCount), _this, accType["Id"]);
				if (element['cblight__isFormulaBudgetLine__c']) {
					FIVE_NFL.forEach(value => {
						if (element['cblight__NFL' + value + '__c'] || value <= 2) {
							blSheet.addRow(fillNFLline(element, value, _this.periodData.periodNumberById, _this));
							nfllineValidation(blSheet.getRow(blSheet.rowCount), _this);
						}
					});
				}
			});
			FIVE_NFL.forEach(() => blSheet.addRow({}));
		});
		addGrandTotalRowToTotalSheet(totalSheet, _this, grandTotalSignedSumByPeriod);
	} catch (e) {
		throw new Error(`Add account types to Budget Lines sheet ${e}`);
	}
}

/**
* Add Service Sheet to workbook
*/
const addServiceSheet = (_this, serviceSheet) => {
	try {
		let serviceColumns = [];
		Object.entries(_this.SERVICE_COLUMNS_MAPPING).forEach(([key, value]) => {
			serviceColumns.push({ header: value.header, key: value.key, width: value.width });
		});
		serviceSheet.columns = serviceColumns;
		Object.entries(_this.SERVICE_COLUMNS_MAPPING).forEach(([key, value]) => {
			serviceSheet.getColumn(value.key).values = [, , ...value.names];
		});
		serviceSheet.getRow(1).eachCell({ includeEmpty: true }, (cell, cellNumber) => { // header
			cell.font = EXCEL_STYLE.headerFont;
			cell.border = EXCEL_STYLE.headerBorder;
			cell.fill = EXCEL_STYLE.headerFill;
		});
		return 'Ok';
	} catch (e) {
		throw new Error(`Add Service Sheet${e}`);
	}
}

/**
* Fill Budget Line row for Excel export
*/
const makeExcelRow = (_this, element) => {
	try {
		let row = {};
		ANALYTIC_MAP.forEach(elem => {
			row[elem['key']] = _this.mapReverseSO[elem['readso']][element[elem['field']]];
		});
		row['Type'] = element['cblight__CBAccountType__c'];
		row['Title'] = element['Name'];

		return row;
	} catch (e) {
		throw new Error(`Make Excel row ${e}`);
	}
}
/**
* Translate frormula to Excel
*/
const translateFormulaToExcel = (sourceFormula) => {
	try {
		let resultFormula = sourceFormula ? sourceFormula : '';
		FIVE_NFL.forEach(value => {
			let search = '#' + value;
			let replacement = 'INDIRECT(ADDRESS(ROW()+' + value + ',COLUMN()))';
			resultFormula = resultFormula.split(search).join(replacement);
		});
		return resultFormula;
	} catch (e) {
		throw new Error(`Translate formula to Excel ${e}`);
	}
}

/**
* Fill row  amounts for Excel export. Add default values in case when amount(s) did not exists
* Formula for Excel: INDIRECT(ADDRESS(ROW()+1,COLUMN()))*INDIRECT(ADDRESS(ROW()+2,COLUMN()))
*/
const fillRowAmounts = (element, row, periodNumberById, _this) => {
	try {
		Object.values(periodNumberById).forEach(value => {
			row['p' + value] = element['cblight__isFormulaBudgetLine__c'] ? {
				formula: translateFormulaToExcel(element['cblight__NFLFormula__c']),
				result: 0
			} : 0;
		});
		if (element['cblight__CBAmounts__r']) {
			if (element['cblight__CBAmounts__r'].length === 0) {
				element['cblight__CBAmounts__r'] = _this.periodData.zero_amounts;
			}
			element.cblight__CBAmounts__r.forEach(amount => {
				let tmpId = amount.cblight__CBPeriod__c;
				let periodNumber = periodNumberById[tmpId];
				if (periodNumber) {//period Number starts from 1
					let tmpKey = 'p' + periodNumber;
					let tmpValue = amount.cblight__Value__c;
					row[tmpKey] = element['cblight__isFormulaBudgetLine__c'] ? {
						formula: translateFormulaToExcel(element['cblight__NFLFormula__c']),
						result: tmpValue
					} : tmpValue;
				}
			})
		}
	} catch (e) {
		throw new Error(`Fill row amounts ${e}`);
	}
}

/**
* Fill NFL amounts for Excel export
*/
const fillNFLline = (element, lineNumber, periodNumberById, _this) => {
	try {
		let row = {};
		Object.values(periodNumberById).forEach(value => {
			row['p' + value] = 0;
		});
		let nflId = element['cblight__NFL' + lineNumber + '__c'];
		let nflLine = _this.nflLines[nflId];
		if (!nflLine) {
			nflLine = JSON.parse(JSON.stringify(EMTY_NFL_LINE));
			nflLine['cblight__NonFinancialItems__r'] = _this.periodData.zero_amounts;
			if (lineNumber === 2) {
				nflLine.cblight__LayerTitle__c = 'Quantity';
			}
		}
		row['Title'] = nflLine['cblight__LayerTitle__c'];
		if (nflLine['cblight__NonFinancialItems__r']) {
			nflLine['cblight__NonFinancialItems__r'].forEach(item => {
				let periodNumber = periodNumberById[item.cblight__CBPeriod__c];
				if (periodNumber) {
					row['p' + periodNumber] = item.cblight__Value__c;
				}
			});
		}
		return row;
	} catch (e) {
		throw new Error(`Fill NFL line ${e}`);
	}
}

/**
* Add lookups for NFL lines in Excel
*/
const nfllineValidation = (row, _this) => {
	try {
		let formula = _this.SERVICE_COLUMNS_MAPPING['cblight__Layer__c'].formulae;
		const firstCell = row.getCell(1);
		firstCell.dataValidation = {
			type: 'list',
			allowBlank: false,
			formulae: [formula]
		};
		firstCell.alignment = EXCEL_STYLE.INDENTED;
		_this.periodData.periodKeys.forEach(key => {
			let curentCell = row.getCell(key);
			curentCell.numFmt = '#,##0;[Red](#,##0)';
			curentCell.fill = EXCEL_STYLE.nflFill;
		});
		row.eachCell({ includeEmpty: true }, (cell) => {
			cell.font = EXCEL_STYLE.simpleFont;
			cell.border = EXCEL_STYLE.simpleBorders;
		});
		row.getCell('Total').font = EXCEL_STYLE.headerFont;
		return;
	} catch (e) {
		throw new Error(`NFL line validation ${e}`);
	}
};

/**
* Add lookups for rows in Excel
*/
const rowsValidation = (row, _this, accTypeId) => {
	try {
		Object.entries(VALIDATION_MAP).forEach(([key, value]) => {
			if (_this.SERVICE_COLUMNS_MAPPING[key]) {
				let formula = (key === 'cblight__CBAccount__c') ? _this.accTypesFoormulae[accTypeId] : _this.SERVICE_COLUMNS_MAPPING[key].formulae;
				row.getCell(value).dataValidation = {
					type: 'list',
					allowBlank: false,
					formulae: [formula]
				};
			}
		});
		row.eachCell({ includeEmpty: true }, (cell) => {
			cell.font = EXCEL_STYLE.simpleFont;
			cell.border = EXCEL_STYLE.simpleBorders;
		});
		row.getCell('Total').font = EXCEL_STYLE.headerFont;
		return;
	} catch (e) {
		throw new Error(`Rows validation ${e}`);
	}
};

/**
* Add row color
*/
const rowColor = (row, color) => {
	row.eachCell({ includeEmpty: true }, (cell) => {
		cell.fill = color;
		cell.font = EXCEL_STYLE.headerFont;
		cell.border = EXCEL_STYLE.simpleBorders;
	});
};

/**
* Add input templates to Budget Lines array for export to Excel
*/
const makeTemplatesArray = (accountTypeName, _this) => {
	try {
		let result = [];
		for (let i = 1; i <= EMPTY_LINES_COUNT; i++) {
			let tmpLine = JSON.parse(JSON.stringify(EMPTY_BUDGET_LINE));
			tmpLine['cblight__isFormulaBudgetLine__c'] = _this.orgVariable.cblight__NonFinancialLibIsUsing__c;
			tmpLine['cblight__CBAccountType__c'] = accountTypeName;
			result.push(tmpLine);
		}
		return result;
	} catch (e) {
		throw new Error(`Make templates array ${e}`);
	}
}

//////////////////////////////  PREVIEWER /////////////////////////
/**
* Export to  Excel method
*  @param _this component this
*/
const makeExcelFileBeforePreview = async (_this) => {
	try {
		_this.configData.writeWorkbook = new ExcelJS.Workbook();
		let blSheet = _this.configData.writeWorkbook.addWorksheet(BL_SHEET_NAME, { views: [{ state: 'frozen', xSplit: 2 }] });
		let serviceSheet = _this.configData.writeWorkbook.addWorksheet(SERVICE_SHEET_NAME);
		let totalSheet = _this.configData.writeWorkbook.addWorksheet(TOTAL_SHEET_NAME, { views: [{ state: 'frozen', ySplit: 1 }] });
		addServiceSheet(_this, serviceSheet);
		let budgetLinesForExcel = await getBLForExcelServer({ idsFromExcel: _this.budgetLineIds });
		addTotalSheet(_this, blSheet, totalSheet);
		addBudgetLinesSheet(_this, [...budgetLinesForExcel], blSheet, totalSheet);
		_this.showPreviewer = true;
		_this.isPreviewerImport = false;
		_this.makePreviewerColumns();
		_this.writeExcelToPreviewer(_this.configData.writeWorkbook);

	} catch (e) {
		_message(`error`, `BLME : Excel file preparing ${e}`);
	} finally {
		_this.showSpinner = false;
		_this.updateTextLog("Previewer starts");
	}
}

/**
* Export to  Excel method
*  @param _this component this
*/
const writeExcelFileAfterPreview = async (_this) => {
	try {
		_this.configData.fileName = 'Budget Lines ' + new Date().toLocaleString('en-US');
		_this.configData.fileName = prompt('Name to be used for the file', _this.configData.fileName);
		if (!_this.configData.fileName || _this.configData.fileName.length < 1) {
			_this.disabledButtons = false;
			return;
		}
		_this.updateTextLog("Writing Excel file after previewing to -> " + _this.configData.fileName);
		_this.showPreviewer = false;
		_this.showSpinner = true;
		let data = await _this.configData.writeWorkbook.xlsx.writeBuffer();
		const blob = new Blob([data], { type: 'application/octet-stream' });
		let downloadLink = document.createElement("a");
		downloadLink.href = window.URL.createObjectURL(blob);
		downloadLink.target = '_blank';
		downloadLink.download = _this.configData.fileName + '.xlsx';
		downloadLink.click();
	} catch (e) {
		_message(`error`, `BLME : Excel file writing ${e}`);
	} finally {
		_this.showSpinner = false;
	}
}

//////////////////////////////  PREVIEWER /////////////////////////
export { makeExcelFileBeforePreview, writeExcelFileAfterPreview };