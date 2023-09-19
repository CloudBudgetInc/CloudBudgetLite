/**
* Library for uploading Budget Lines from Excel
*/
import { _applyDecStyle, _cl, _generateFakeId, _getCopy, _message, _parseServerError } from "c/cbUtils";
import {
	BL_SHEET_NAME, FIVE_NFL, TWO_NFL, getValueFromRowCellByColumnKey, getFormulaFromRowCellByColumnKey,
	ANALYTIC_MAP, ANALYTIC_MAP_NFL, MAX_INPUT_CELL_VALUE, BUDGET_LINES_PER_TRANSACTION, MAX_NFL, KNOWN_FORMULAS, nflCustom,
	getColumnLetterByColumnKey
} from "./cbExcelMirrorConst";
import saveBudgetLinesWithNFLForExcelServer from '@salesforce/apex/CBExcelMirrorPageController.saveBudgetLinesWithNFLForExcelServer';
import deleteBudgetLinesServer from '@salesforce/apex/CBExcelMirrorPageController.deleteBudgetLinesServer';

/**
* Upsert custom NFL and Budget Lines from  Excel part 1 (before preview)
*/
const importFromExcel = async (_this) => {
	try {	
		_this.result = await setParams(_this.configData.readWorkbook, _this, BL_SHEET_NAME);
		_this.updateTextLog('Sheet name : ' + BL_SHEET_NAME);
		readByLineExcelFile(_this.result);
		recalculateLinesAmounts(_this.result);
		prepareBudgetLines(_this.result);
	} catch (e) {
		throw new Error(`Import from Excel ${e}`);
	}
}

/**
* Upsert custom NFL and Budget Lines from  Excel part 2 (after preview)
*/
const continueImportFromExcel = async (_this) => {
	try {
		await deleteBudgetLines(_this.result);
		await upsertBudgetLines(_this.result);
		if (_this.result.errors.length) {
			printErrors(_this.result);
		}
	} catch (e) {
		throw new Error(`Continue import from Excel ${e}`);
	}
}

/**
* Make Empty Amounts
*/
const makeNewAmounts = (periodByNumber) => {
	try {
		let result = [];
		Object.keys(periodByNumber).forEach(key => {
			let periodTmp = periodByNumber[key];
			result.push({ cblight__CBPeriod__c: periodTmp.Id, cblight__CBBudgetYear__c: periodTmp.cblight__CBBudgetYear__c, cblight__Value__c: 0 });
		});
		return result;
	} catch (e) {
		throw new Error(`Make new amounts ${e}`);
	}
}

/**
 * The method sets initial parameters for BL import
 */
const setParams = async (workBook, context, sheetName) => {
	try {
		context.updateTextLog("Budget Lines : " + sheetName + " Set params");
		const inputSheet = workBook.getWorksheet(sheetName);
		const { periodData, mapsSO, budgetLines, columns } = context;
		return {
			errors: [],
			context,
			workBook,
			inputSheet,
			inputLines: [],
			linesExisted: budgetLines,
			nflLines: {},
			periodByNumber: periodData.periodByNumber,
			periodNumberById: periodData.periodNumberById,
			columnsBL: columns,
			amountsNewExample: makeNewAmounts(periodData.periodByNumber),
			periodKeys: periodData.periodKeys,
			mapsSO
		};
	} catch (e) {
		throw new Error(`Set import parameters ${e}`);
	}
}

/**
* The method read Excel lines and return the list of Budget Line antecessor rowObj
* Excel row becames excel-free rowObj
*/
const readByLineExcelFile = (result) => {
	try {
		let rowObj;
		let isMainLine = false;
		let isNflSubline = false;
		let isMainLineOpen = false;
		let accTypes = {};
		let ignoredLines = { 'Title': 1 };
		let ignoredBLCount = 0;
		result.context.accTypesWithStylesNames.forEach(accType => {
			accTypes[accType.Name] = 1;
			ignoredLines[accType.Name.toUpperCase() + ' TOTAL'] = 1;
		});
		result.inputSheet.eachRow((row, rowNumber) => {
			if (rowNumber < 4) {
				return;
			}
			let isCell1 = row.getCell(1).value;
			let isCell2 = row.getCell(2).value;
			let isEmptyLine = !isCell1 && !isCell2;
			if (isEmptyLine || isCell1 && ignoredLines[row.getCell(1).value]) {
				isMainLineOpen = false;
				return true;
			}
			isMainLine = isCell2;
			isNflSubline = !isMainLine;

			if (isMainLine) {
				checkLine(result, rowObj, accTypes);// Check previous rowObj
				isMainLineOpen = true;
				rowObj = { 'isIgnored': !isCell1, 'hasError': false, 'rowNumber': rowNumber, 'currentNFL': 1, 'nfls': {}, formulas: {}, 'hasNFL': false, 'isFormula': false };
				if (rowObj.isIgnored) {
					ignoredBLCount++;
				} else {
					result.inputLines.push(rowObj);
					Object.keys(result.columnsBL).forEach(key => {
						rowObj[key] = getValueFromRowCellByColumnKey(row, result.columnsBL, key);
					});
					result.periodKeys.forEach(key => {
						rowObj.formulas[key] = getFormulaFromRowCellByColumnKey(row, result.columnsBL, key);
					});
				}
				return true;
			}
			if (isNflSubline && isMainLineOpen && !rowObj.isIgnored) {
				addNFLline(rowNumber, rowObj, row, result.columnsBL, result.errors);
				return true;
			} else {
				if (isNflSubline && !isMainLineOpen) {
					result.errors.push({ text: 'Column "Type" is empty or NFL line without parrent', rowNumber: rowNumber, colNumber: 'B' });
					return true;
				}
			}
		});
		checkLine(result, rowObj, accTypes); // Check remaining rowObj
		result.context.updateTextLog("Budget Lines readed: " + result.inputLines.length);
		result.context.updateTextLog("Budget Lines ignored: " + ignoredBLCount);
		if (result.inputLines.length === 0) {
			result.errors.push({ text: 'Input file does not contain Budget Lines.', rowNumber: 'Total', colNumber: 'Total' });
		}
		return result;
	} catch (e) {
		throw new Error(`Read by line ${e}`);
	}
}

/**
* Add rowObjNFL to  rowObj (BL) when importing
*/
const addNFLline = (rowNumber, rowObj, row, columns, errors) => {
	try {
		if (rowObj.currentNFL > MAX_NFL) {
			rowObj.hasError = true;
			errors.push({ text: "To many NFL lines(>" + MAX_NFL + ") in row " + rowObj.rowNumber, rowNumber: rowNumber, colNumber: 'A' });
			return true;
		}
		let rowObjNFL = {
			'hasError': false,
			'rowNumber': rowNumber,
			'lineNumber': rowObj.currentNFL,
			'Layer': getValueFromRowCellByColumnKey(row, columns, 'Title'),
			'Name': 'Custom'
		};
		Object.entries(columns).forEach(([key, value]) => {
			if (!value.isNFL) {
				let valueFromNFL = getValueFromRowCellByColumnKey(row, columns, value.key);
				if (valueFromNFL) {
					rowObj.hasError = true;
					errors.push({ text: "Cell is unused in NFL subline", rowNumber: rowObjNFL.rowNumber, colNumber: value.letter });
				}
			}
			if (value.isPeriod) {
				rowObjNFL[key] = getValueFromRowCellByColumnKey(row, columns, key);
			}
		});
		rowObj['nfls'][rowObj.currentNFL] = rowObjNFL;
		rowObj.currentNFL++;
		rowObj.hasNFL = true;
	} catch (e) {
		throw new Error(`Add NFL line ${e}`);
	}
}

/**
*  Check Budget Line when importing
*/
const checkLine = (result, rowObj, accTypes) => {
	try {
		if (!rowObj || rowObj.isIgnored) {
			return;
		}
		if (!rowObj['CB Account']) {
			result.errors.push({ text: 'CB Account is missed', rowNumber: rowObj.rowNumber, colNumber: getColumnLetterByColumnKey(result.context.columns, 'CB Account') });
			rowObj.hasError = true;
		}
		if (!rowObj['Title']) {
			result.errors.push({ text: "Invalid title", rowNumber: rowObj.rowNumber, colNumber: getColumnLetterByColumnKey(result.context.columns, 'Title') });
			rowObj.hasError = true;
		}
		if (rowObj['Title'].length > 80) {
			result.errors.push({ text: "Budget Line title length more then 80 characters", value: rowObj['Title'], rowNumber: rowObj.rowNumber, colNumber: getColumnLetterByColumnKey(result.context.columns, 'Title') });
			rowObj.hasError = true;
		}
		if (!accTypes[rowObj['Type']]) {
			rowObj.hasError = true;
			result.errors.push({ text: "Lookup was not found", rowNumber: rowObj.rowNumber, colNumber: 'B' });
		}
		let formulaWithoutSpaces = rowObj.formulas['p1'] ? rowObj.formulas['p1'].replace(/\s/g, "") : null;
		if (formulaWithoutSpaces) {
			let excelFormula = KNOWN_FORMULAS[formulaWithoutSpaces];
			if (!excelFormula) {
				rowObj.hasError = true;
				result.errors.push({ text: "Wrong formula", value: rowObj.formulas['p1'], rowNumber: rowObj.rowNumber, colNumber: getColumnLetterByColumnKey(result.context.columns, 'p1') });
			}
			rowObj.isFormula = true;
			rowObj.formulas['p1'] = excelFormula;
			if (Object.keys(rowObj.nfls).length < MAX_NFL) {
				rowObj.hasError = true;
				result.errors.push({ text: " Number of NFL <" + MAX_NFL, rowNumber: rowObj.rowNumber, colNumber: 'A' });
			}
		}
	} catch (e) {
		throw new Error(`Check line ${e}`);
	}
}

/**
* Print errors
*/
const printErrors = (result) => {
	try {
		result.errors.forEach(err => { result.context.updateTextLog(err.text + (err.value ? ':' + err.value + ' ' : '') + " row#: " + err.rowNumber); });
		if (result.errors.length > 0) {
			result.context.redTextLog("Fix errors and try again !");
			return;
		}
		return result;
	} catch (e) {
		throw new Error(`Print errors ${e}`);
	}
}

/**
*  Recalculate amounts when importing
*/
const recalculateLinesAmounts = (result) => {
	try {
		result.inputLines.forEach(line => {
			recalculateAmounts(line, result.periodKeys, result.errors, result.context.columns);
			Object.keys(line['nfls']).forEach(key => {
				recalculateAmounts(line['nfls'][key], result.periodKeys, result.errors, result.context.columns);
			});
		});
		result.context.updateTextLog("Budget Lines : recalculateLinesAmounts " + result.inputLines.length);
		return result;
	} catch (e) {
		throw new Error(`Recalculate Lines Amounts ${e}`);
	}

}

/**
* Recalculate amounts when importing
*/
const recalculateAmounts = (rowObj, periodKeys, errors, columns) => {
	try {
		periodKeys.forEach(key => {
			let tmpValue = rowObj[key] ? rowObj[key] : 0;
			if (isNaN('' + tmpValue)) {
				rowObj.hasError = true;
				errors.push({ text: 'Value is not a number ', value: tmpValue, rowNumber: rowObj.rowNumber, colNumber: getColumnLetterByColumnKey(columns, key) });
				return true;
			}
			if (Math.abs(tmpValue) > MAX_INPUT_CELL_VALUE) {
				rowObj.hasError = true;
				errors.push({ text: 'Value is too large ', value: tmpValue, rowNumber: rowObj.rowNumber, colNumber: getColumnLetterByColumnKey(columns, key) });
				return true;
			}
			tmpValue = Math.round((tmpValue + Number.EPSILON) * 100) / 100;
			rowObj[key] = tmpValue;
		});
	} catch (e) {
		throw new Error(`Recalculate Amounts ${e}`);
	}
}



/*DML limit === 10000 rows; 100 * (1 BL +12 Amounts +5*(1 NFL+12 NFL_Items)===7800 Sobject rows; 100 need to be verified ) */

/**
* Prepare Budget Lines from Excel to upsert
*/
const prepareBudgetLines = (result) => {
	try {
		const chunkToUpsert = {
			budgetLines: [],
			rowObjs: []
		}
		result.inputLines = sliceArray(result.inputLines, BUDGET_LINES_PER_TRANSACTION);
		result.budgetLinesToSave = [];
		result.inputLines.forEach(sourceChunk => {
			let resultLinesChunk = JSON.parse(JSON.stringify(chunkToUpsert));
			sourceChunk.forEach(rowObj => {
				let tmpResult = prepareBudgetLine(result, rowObj);
				if (!tmpResult) return;
				let tmpParam = {};
				tmpParam.budgetLine = tmpResult.budgetLine;
				tmpParam.amounts = tmpResult.amounts;
				TWO_NFL.forEach(index => {
					tmpParam['nfl' + index] = tmpResult.nflLines[index];
					tmpParam['nfl' + index + 'Items'] = tmpResult.nflItems[index];
				});
				resultLinesChunk.budgetLines.push(tmpParam);
				resultLinesChunk.rowObjs.push(tmpResult.mainRowObj);
			});
			result.budgetLinesToSave.push(resultLinesChunk);
		});
		result.context.updateTextLog("Prepared Budget Lines blocks " + result.inputLines.length);
		return result;
	} catch (e) {
		throw new Error(`Prepare Budget Lines ${e}`);
	}
}

/**
* Prepare Budget Line rowObj with custom NFLs rowObjNFL from Excel to upsert
*/
const prepareBudgetLine = (result, rowObj) => {
	try {
		let resultBL = {};
		setLookups(resultBL, rowObj, result.mapsSO, result.errors, ANALYTIC_MAP);
		let tmpNfls = {};
		let tmpNflItems = {};
		FIVE_NFL.forEach(index => {
			resultBL["cblight__NFL" + index + "__c"] = '';
			tmpNfls[index] = null;
			tmpNflItems[index] = [];
		});
		let amountsNew = setAmounts(rowObj, result.amountsNewExample, result.periodNumberById);
		resultBL.cblight__Value__c = amountsNew.sum;
		resultBL['Name'] = rowObj.Title;
		if (rowObj.isFormula) {
			resultBL.cblight__isFormulaBudgetLine__c = true;
			resultBL.cblight__NFLFormula__c = rowObj.formulas['p1'];
		}
		setLookupsFromConfig(resultBL, result.context);
		Object.values(rowObj['nfls']).forEach(rowObjNFL => {
			let tmpLineNumber = rowObjNFL['lineNumber'];
			let tmpNFLResult = prepareNFL(result, rowObj, rowObjNFL);
			if (!tmpNFLResult) {
				rowObj.hasError = true;
			}
			tmpNfls[tmpLineNumber] = tmpNFLResult.NFL;
			tmpNflItems[tmpLineNumber] = tmpNFLResult.itemList;
		});
		if (rowObj.hasError) {
			return null;
		}
		return { budgetLine: resultBL, amounts: amountsNew.amountsFiltered, nflLines: tmpNfls, nflItems: tmpNflItems, mainRowObj: rowObj };
	} catch (e) {
		throw new Error(`Prepare Budget Line ${e}`);
	}
}

/**
* Prepare rowObjNFL from Excel to upsert
*/
const prepareNFL = (result, rowObj, rowObjNFL) => {
	try {
		let resultNfl = {};
		if (setLookups(resultNfl, rowObjNFL, result.mapsSO, result.errors, ANALYTIC_MAP_NFL)) {
			rowObj.hasError = true;
		}
		let itemsNew = setAmounts(rowObjNFL, result.amountsNewExample, result.periodNumberById);
		resultNfl.cblight__Type__c = nflCustom;
		resultNfl.cblight__Value__c = itemsNew.sum;
		resultNfl.Name = rowObjNFL.Name;
		return { NFL: resultNfl, itemList: itemsNew.amountsFiltered };
	} catch (e) {
		throw new Error(`Prepare NFL ${e}`);
	}
};

/**
* Combined key for dependent fields  
*/
const getCombinedKey = (rowObj, keys, key) => {
	try {
		let tmpKeys = keys ? keys : [key];
		for (const key of tmpKeys) {
			if (!rowObj[key]) {
				return undefined;
			}
		}
		const keyValues = tmpKeys.map(key => rowObj[key]);
		return keyValues.join(':::');
	} catch (e) {
		throw new Error(`Get Combined Key ${e}`);
	}
}

/**
* Set Lookups for Budget Line 
*/
const setLookups = (line, rowObj, mapsSO, errors, analyticMap) => {
	try {
		let hasError = false;
		for (const elem of analyticMap) {
			const keyForLookup = getCombinedKey(rowObj, elem['readerKey'], elem['key']);
			if (!keyForLookup && elem['required']) {
				errors.push({ text: 'Required columns are empty:' + elem['errAdd'], rowNumber: rowObj.rowNumber, colNumber: elem['letter'] });
				hasError = true;
				continue;
			}
			const field = elem['field'];
			const so = elem['so'];
			if (!keyForLookup) {
				line[field] = '';
				continue;
			}
			const lookupValue = mapsSO[so][keyForLookup];
			if (!lookupValue) {
				errors.push({ text: 'Lookup was not found' + elem['errAdd'], rowNumber: rowObj.rowNumber, colNumber: elem['letter'] });
				hasError = true;
				continue;
			}
			line[field] = lookupValue;
		}
		return hasError;
	} catch (e) {
		throw new Error(`Set Lookups ${e}`);
	}
}

/**
* Set Lookups from Config 
*/
const setLookupsFromConfig = (line, context) => {
	try {
		line['cblight__CBBudgetYear__c'] = context.configData.filterConfiguration['cblight__CBBudgetYear__c'];
		line['cblight__CBScenario__c'] = context.configData.filterConfiguration['cblight__CBScenario__c'];
		ANALYTIC_MAP.forEach(elem => {
			if (context.configData.filterConfiguration[elem['field']]) {
				line[elem['field']] = context.configData.filterConfiguration[elem['field']];
			}
		});
	} catch (e) {
		throw new Error(`Set Lookups From Config ${e}`);
	}
}

/**
* Set Amounts for Budget Line and NFL 
*/
const setAmounts = (rowObj, amountsNewExample, periodNumberById) => {
	try {
		let amountsNew = JSON.parse(JSON.stringify(amountsNewExample));
		let sum = 0;
		amountsNew.forEach((elem, index) => {
			elem.cblight__Value__c = rowObj['p' + (index + 1)];
			sum += elem.cblight__Value__c;
		});
		return { sum: sum, amountsFiltered: amountsNew };
	} catch (e) {
		throw new Error(`Set Amounts ${e}`);
	}
}

/**
*  Slice array
*/
const sliceArray = (arr, chunkSize) => {
	const result = [];
	for (let i = 0; i < arr.length; i += chunkSize) {
		const chunk = arr.slice(i, i + chunkSize);
		result.push(chunk);
	}
	return result;
}

/**
* Split delete to chunks
*/
const deleteBudgetLines = async (result) => {
	try {
		if (result.errors.length) {
			return result;
		}
		result.context.budgetLineIds = sliceArray(result.context.budgetLineIds, BUDGET_LINES_PER_TRANSACTION);
		result.context.updateTextLog('Blocks of current Budget Lines to delete -> ' + result.context.budgetLineIds.length, 'blue');
		let index = 1
		for (const arr of result.context.budgetLineIds) {
			let arrLength = arr.length;
			await deleteBudgetLinesServer({ budgetLineIds: arr });
			result.context.updateTextLog("Deleted block # : " + index++ + " rows:" + arrLength);
		}
	} catch (e) {
		throw new Error(`Delete Budget Lines ${e}`);
	}
}

/**
* Upsert Budget Lines
*/
const upsertBudgetLines = async (result) => {
	try {
		if (result.errors.length) {
			return result;
		}
		result.context.updateTextLog("Update start : " + result.inputSheet.name + ' blocks count ->' + result.budgetLinesToSave.length);
		let index = 1
		for (const resultLinesChunk of result.budgetLinesToSave) {
			await saveBudgetLinesWithNFLForExcelServer({
				budgetLines: resultLinesChunk.budgetLines,
				byId: result.context.configData.filterConfiguration['cblight__CBBudgetYear__c']
			});
			let chunkMaxRowNumber = Math.max(...resultLinesChunk.rowObjs.map(rowObj => rowObj.rowNumber));
			let chunkMinRowNumber = Math.min(...resultLinesChunk.rowObjs.map(rowObj => rowObj.rowNumber));
			result.context.updateTextLog("Block# " + index++ + '  from row# ' + chunkMinRowNumber + " to row# " + chunkMaxRowNumber);

		}
		result.context.updateTextLog('Insert new Budget Lines completed')
		return result;
	} catch (e) {
		throw new Error(`Upsert Budget Lines ${e}`);
	}
}

export { importFromExcel, continueImportFromExcel };