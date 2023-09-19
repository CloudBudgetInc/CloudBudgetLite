import { api, track, LightningElement } from 'lwc';
import exceljs from '@salesforce/resourceUrl/exceljs';
import { loadScript } from 'lightning/platformResourceLoader';
import getPeriodsServer from '@salesforce/apex/CBBudgetLinePageController.getPeriodsServer';
import getOrgVariableServer from '@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer';
import getStylesForAccountTypesServer from "@salesforce/apex/CBBudgetLinePageController.getStylesForAccountTypesServer";
import getAccTypesWithStylesNamesServer from "@salesforce/apex/CBBudgetLinePageController.getAccTypesWithStylesNamesServer";
import { makeExcelFileBeforePreview, writeExcelFileAfterPreview } from "./cbExcelMirrorWriter";
import { importFromExcel, continueImportFromExcel } from "./cbExcelMirrorReader";
import { _applyDecStyle, _cl, _generateFakeId, _getCopy, _message, _parseServerError } from "c/cbUtils";
import getSelectOptionsServer from "@salesforce/apex/CBExcelMirrorPageController.getSelectOptionsServer";
import getListOfNFL from "@salesforce/apex/CBExcelMirrorPageController.getListOfNFL";
import getFunctionByIdServer from "@salesforce/apex/CBFunctionPageController.getFunctionByIdServer";
import {
	BL_SHEET_NAME, SERVICE_SHEET_NAME, TOTAL_SHEET_NAME, numToExcelColumn, HEAD_COLOMNS_BL, TAIL_COLOMNS_BL, getOrderOfColumns,
	getValueFromCell, getValueFromRowCellByColumnKey, getPeriodNumberById, getPeriodByNumberFromDB, ANALYTIC_MAP_BY_COLUMN_HEADER,
	convertArrayToObject, SERVICE_ACCOUNT_COLUMN_LETTER, FIVE_NFL
} from "./cbExcelMirrorConst";

export default class CbExcelMirror extends LightningElement {
	@api budgetLines = [];
	@api configurationMirror;

	showSpinner = false;
	showExcelLog = false;
	showPreviewer = false;
	continueWithReader = false;
	disabledButtons = false;
	isPreviewerImportMode = false;
	updateBudgetLinesFromPreviewer = true;

	textLog = '';
	filterLog = '';
	headerLog = 'CLOUDBUDGET 3.0<br>Budget Manager';

	result;//object for reading from Excel

	orgVariable;
	selectOptionMap;
	mapReverseSO;
	mapsSO;
	columns;

	budgetLineIds;
	nflIds;
	nflLines = [];

	stylesForAccountTypes;
	accTypesWithStylesNames;
	accTypesFoormulae;

	periodData = {
		periodsFromDB: null,
		zero_amounts: null,
		periodKeys: null,
		periodsCount: null,
		periodNumberById: null,
		periodByNumber: null,
		firstPeriodColumnNumber: null,
		lastPeriodColumnNumber: null,
		firstNumberLetter: null,
		lastNumberLetter: null,
	}
	configData = {
		configFromFileName: '',
		configFromFile: '',
		func: {},
		filterConfiguration: null,
		isColumnFilteredByReader: false,
		readWorkbook: null,
		writeWorkbook: null,
		fileName: null
	}
	previewerData = {
		previewerColumns: [],
		previewerRows: [],
	};

	SERVER_PARAMETERS_SO_MAPPING = {
		cblight__CBDivision__c: 'divisionSO',
		cblight__CBAccount__c: 'AccountSO',
		cblight__CBVariable1__c: 'Var1SO',
		cblight__CBVariable2__c: 'Var2SO',
		cblight__CBVariable3__c: 'Var3SO',
		cblight__CBVariable4__c: 'Var4SO',
		cblight__CBVariable5__c: 'Var5SO',
		cblight__Layer__c: 'LayerSO'
	};

	SERVICE_COLUMNS_MAPPING = {
		cblight__CBDivision__c: { header: 'Division', key: 'Division', width: 20 },
		cblight__CBAccount__c: { header: 'Account', key: 'Account', width: 20, },
		cblight__CBVariable1__c: { header: 'Variable 1', key: 'Variable 1', width: 20 },
		cblight__CBVariable2__c: { header: 'Variable 2', key: 'Variable 2', width: 20 },
		cblight__CBVariable3__c: { header: 'Variable 3', key: 'Variable 3', width: 20 },
		cblight__CBVariable4__c: { header: 'Variable 4', key: 'Variable 4', width: 20 },
		cblight__CBVariable5__c: { header: 'Variable 5', key: 'Variable 5', width: 20 },
		cblight__Layer__c: { header: 'Layer', key: 'Layer', width: 20 },
		cblight__CBFunction__c: { header: 'Config', key: 'Config', width: 60 }
	};

	STICKY_CLASSES = { 1: "sticky-first", 2: "sticky-second", 3: "sticky-third" };
	MAX_STICKY_COL = 3;

	/**
	 * The method pulls initial options 
	 */
	async getInitialOptions() {
		try {
			this.showSpinner = true;
			this.selectOptionMap = await getSelectOptionsServer();
			this.periodData.periodsFromDB = await getPeriodsServer();
			this.orgVariable = await getOrgVariableServer();
			this.filterColumns();
			this.mapReverseSO = this.getReverseMapsSO();
			this.periodData.periodByNumber = getPeriodByNumberFromDB(this.periodData.periodsFromDB);
			this.columns = getOrderOfColumns(this.periodData.periodByNumber, HEAD_COLOMNS_BL, TAIL_COLOMNS_BL, this.SERVICE_COLUMNS_MAPPING);
			this.periodData.periodsCount = Object.keys(this.periodData.periodByNumber).length;
			this.periodData.periodNumberById = getPeriodNumberById(this.periodData.periodByNumber);
			let variableCount = Object.keys(this.columns).length - this.periodData.periodsCount - HEAD_COLOMNS_BL.length - TAIL_COLOMNS_BL.length;
			this.periodData.firstPeriodColumnNumber = HEAD_COLOMNS_BL.length + 1 + variableCount;
			this.periodData.firstNumberLetter = numToExcelColumn(this.periodData.firstPeriodColumnNumber);
			this.periodData.lastPeriodColumnNumber = HEAD_COLOMNS_BL.length + variableCount + this.periodData.periodsCount
			this.periodData.lastNumberLetter = numToExcelColumn(this.periodData.lastPeriodColumnNumber);
			this.periodData.periodKeys = this.getPeriodKeys(this.columns);
			this.periodData.zero_amounts = this.getZeroValuedAmounts();
			this.mapsSO = this.getMapsSO(this.selectOptionMap);
			this.getAccountWithType();
			this.budgetLineIds = this.makeArrayOfIds(this.budgetLines);
			this.nflIds = this.makeArrayOfNFLIds(this.budgetLines);
			this.nflLines = await getListOfNFL({ listOfNFLId: this.nflIds, idOfBudgetYear: this.configData.filterConfiguration['cblight__CBBudgetYear__c'] });
			this.nflLines = convertArrayToObject(this.nflLines, 'Id');
			this.stylesForAccountTypes = convertArrayToObject(await getStylesForAccountTypesServer(), 'Id');
			this.accTypesWithStylesNames = await getAccTypesWithStylesNamesServer();
			this.accTypesWithStylesNames.sort((a, b) =>
				(a["cblight__OrderNumber__c"] ? a["cblight__OrderNumber__c"] : 0) - (b["cblight__OrderNumber__c"] ? b["cblight__OrderNumber__c"] : 0));
		} catch (e) {
			throw new Error(`Get Initial Options ${e}`);
		}
	}

	/**
	* Get zero valued amounts
	*/
	getZeroValuedAmounts() {
		try {
			let newZeroAmounts = [];
			this.periodData.periodsFromDB.forEach(period => {
				newZeroAmounts.push({ cblight__CBPeriod__c: period.Id, cblight__Value__c: 0 })
			});
			return newZeroAmounts;
		} catch (e) {
			throw new Error(`Get zero valued amounts ${e}`);
		}
	}

	/**
	*  Filter unused analytics , calculate colomns parameters
	*/
	filterColumns() {
		try {
			this.configData.filterConfiguration = JSON.parse(this.configData.func.cblight__Details__c);
			Object.entries(this.SERVER_PARAMETERS_SO_MAPPING).forEach(([key, value]) => {
				if (this.configData.func[key] && !this.configData.filterConfiguration[key]) {
					this.configData.filterConfiguration[key] = this.configData.func[key];
				}
			});
			Object.entries(this.SERVER_PARAMETERS_SO_MAPPING).forEach(([key, value]) => {
				if (this.configData.filterConfiguration[key]) {
					this.selectOptionMap[value] = this.selectOptionMap[value].filter(selectOption => selectOption.value == this.configData.filterConfiguration[key])
				}
			});
			this.getAccountFormulaMap(SERVICE_ACCOUNT_COLUMN_LETTER);
			Object.entries(this.SERVER_PARAMETERS_SO_MAPPING).forEach(([key, value]) => {
				this.SERVICE_COLUMNS_MAPPING[key].names = this.getValues(this.selectOptionMap[value]);
			});
			this.periodData.periodsFromDB = this.periodData.periodsFromDB.filter(period => period.cblight__CBBudgetYear__c === this.configData.filterConfiguration['cblight__CBBudgetYear__c']);
			this.SERVICE_COLUMNS_MAPPING['cblight__CBFunction__c'].names = [this.configurationMirror, this.configData.func.Name, this.configData.func.cblight__Title__c];
			if (!this.isColumnFilteredByReader) {
				let deletedColumns = [];
				Object.entries(this.SERVICE_COLUMNS_MAPPING).forEach(([key, value, index]) => {
					if (!(value.names && value.names.length)) {
						deletedColumns.push(key);
					}
				});
				deletedColumns.forEach(key => delete this.SERVICE_COLUMNS_MAPPING[key]);
			}
			Object.values(this.SERVICE_COLUMNS_MAPPING).forEach((value, index) => {
				value.letter = numToExcelColumn(index + 1);
				value.formulae = 'Service!$' + value.letter + '$2:$' + value.letter + '$' + (value.names.length + 1);
			});
		} catch (e) {
			throw new Error(`Filter columns ${e}`);
		}
	}

	/**
	*  Translate array to Service sheet column values
	*/
	getValues(arr) {
		return arr.reduce((resultValues, element) => {
			resultValues.push(element.label ? element.label : element.Name)
			return resultValues;
		}, []);
	}

	/**
	 * The method load styles for file selector and exceljs from static resource
	 */
	renderedCallback() {
		Promise.all([
			loadScript(this, exceljs)
		]).catch(function (e) {
			_message(`error`, `BLME : Budget Lines load library ${e}`);
		});
	}

	/** 
	 * The method adds messages from import/export to component textarea
	 * @param msg - text
	 */
	updateTextLog(msg) {
		if (this.textLog) {
			this.textLog += '<br>';
		}
		this.textLog += msg;
	};

	/** 
	 * The method clears textarea
	 */
	clearTextLog() {
		this.textLog = '<b>Excel Log</b>';
	};

	/** 
	 * The method add messages from import/export to component textarea
	 * @param msg - text
	 */
	updateFilterLog(msg) {
		if (this.filterLog) {
			this.filterLog += ' ; ';
		}
		this.filterLog += msg;
	}

	/** 
	 * The method add messages from import/export to component textarea
	 * @param msg - text
	 */
	redFilterLog(msg) {
		this.updateFilterLog('<b><span style="color:red;">' + msg + '</b>')
	};

	/** 
	 * The method add messages from import/export to component textarea
	 * @param msg - text
	 */
	redTextLog(msg) {
		this.updateTextLog('<b><span style="color:red;">' + msg + '</b>')
	};

	/**
	* Prepare SO
	*/
	getReverseMapsSO() {
		let mapsSO = {};
		Object.keys(this.selectOptionMap).forEach(key => {
			this.addReverseMapSO(mapsSO, this.selectOptionMap[key], key);
		});
		return mapsSO;
	};

	/**
	* Prepare SO
	*/
	addReverseMapSO(mapsSO, arr, key) {
		let localMap = {};
		arr.forEach(element => {
			localMap[element['value']] = element['label'];
		});
		mapsSO[key] = localMap;
	};

	/**
	 * The method return array of period keys p1..pN
	 *
	 * @param columns
	 */
	getPeriodKeys(columns) {
		let result = [];
		Object.values(columns).filter(column => (column.isPeriod)).forEach(column => {
			result.push(column.key);
		});
		return result;
	};

	/**
	* Prepare SO
	*/
	getMapsSO(selectOptionMap) {
		let mapsSO = {};
		Object.keys(selectOptionMap).forEach(key => {
			this.addMapSO(mapsSO, selectOptionMap[key], key);
		});
		return mapsSO;
	};

	/**
	* Prepare SO
	*/
	addMapSO(mapsSO, arr, key) {
		let localMap = {};
		arr.forEach(element => {
			localMap[element['label']] = element['value'];
		});
		mapsSO[key] = localMap;
	}

	/**
	* Get array of budget Lines Ids from Budget Lines list
	*/
	makeArrayOfIds(lines) {
		return lines.reduce((resultArray, line) => {
			resultArray.push(line['Id']);
			return resultArray;
		}, []);
	}

	/**
	* Get array of NFL Ids from Budget Lines list
	*/
	makeArrayOfNFLIds(lines) {
		return lines.reduce((resultArray, line) => {
			if (line.cblight__isFormulaBudgetLine__c) {
				FIVE_NFL.forEach(value => {
					if (line['cblight__NFL' + value + '__c']) {
						resultArray.push(line['cblight__NFL' + value + '__c']);
					}
				});
			}
			return resultArray;
		}, []);
	}

	/**
	 * This method used to hide spinner from parent component
	 */
	@api
	hideExcelSpinner() {
		this.showSpinner = false;
	}

	/**
	 * The method closes Excel component and reloads the budget line page
	 * It sends an event to the Budget Manager component
	 */
	closeExcelWindow() {
		this.dispatchEvent(new CustomEvent('closeExcelWindow', {
			bubbles: true,
			composed: true
		}));
	}

	/**
	 * Set function in configuration list
	 * It sends an event to the Budget Manager component
	 */
	async setFunctionBeforeExcelImport(funcId) {
		try {
			this.dispatchEvent(new CustomEvent('setFunctionBeforeExcelImport', {
				bubbles: true,
				composed: true,
				detail: funcId
			}));
		} catch (e) {
			_parseServerError("EM : refresh parent error", e)
		}
	}

	/**
	 * Read Excel file, find config in Service sheet and call set configuration from cbBudgetLineManager 
	 */
	uploadFromConfigInFile(event) {
		this.clearTextLog();
		this.disabledButtons = true;
		this.showSpinner = true;
		this.showExcelLog = true;
		this.continueWithReader = false;
		this.isPreviewerImportMode = true;
		try {
			let file = event.target.files[0];
			let blob = new Blob([file, { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }]);
			let fileReader = new FileReader();

			fileReader.onload = async event => {
				try {
					this.configData.readWorkbook = new ExcelJS.Workbook();
					await this.configData.readWorkbook.xlsx.load(event.target.result);
					const serviceSheet = this.configData.readWorkbook.getWorksheet(SERVICE_SHEET_NAME);
					const configFromFileColumnNumber = serviceSheet.columnCount;
					this.configData.configFromFile = serviceSheet.getRow(2).getCell(configFromFileColumnNumber).value.trim();
					this.configData.configFromFileName = serviceSheet.getRow(4).getCell(configFromFileColumnNumber).value;
					this.updateTextLog('Сonfiguration from file: ' + this.configData.configFromFileName);
					let funcList = (await getFunctionByIdServer({ funcId: this.configData.configFromFile }));
					if (funcList.length === 0) {
						alert('Configuration from input file ' + this.configData.configFromFileName + ' do not exists ! Import canceled');
						this.disabledButtons = false;
						this.showSpinner = false;
						this.showExcelLog = false;
						return;
					}
					this.configData.func = funcList[0];
					this.updateTextLog('Loading configuration from file ' + this.configData.configFromFileName);
					this.setFunctionBeforeExcelImport(this.configData.configFromFile);
				} catch (e) {
					_message(`error`, `BLME : Budget Lines file read ${e}`);
				} finally {
					this.showSpinner = false;
				}
			};
			fileReader.readAsArrayBuffer(blob);
		} catch (e) {
			_parseServerError("BLME : Import from Excel file", e)
			this.showSpinner = false;
		}
	};

	/**
	 * Prepare previewer content - parse Excel file etc
	 */
	async preparingPreview() {
		try {
			this.removeNewAnalytics(); //remove unused columns according to Excel file
			await this.getInitialOptions();
			await importFromExcel(this);
			this.makePreviewerColumns();
			this.writeExcelToPreviewer(this.configData.readWorkbook);
			this.showPreviewer = true;
		} catch (e) {
			_message(`error`, `BLME : Preparing preview ${e}`);
		} finally {
			this.showSpinner = false;
		}
	}

	/**
	 * Call the import Budget Lines from Excel method
	 */
	async uploadFromConfigInFileAfterPreviewer(event) {
		let confirmAction = confirm('All Budget lines from Configuration "' + this.configData.configFromFileName + '"  will be deleted before import start. Are you sure to execute import ?');
		if (!confirmAction) {
			alert("Import canceled");
			this.disabledButtons = false;
			this.showSpinner = false;
			this.showExcelLog = false;
			this.showPreviewer = false;
			return;
		}
		try {
			this.showPreviewer = false;
			this.showSpinner = true;
			await continueImportFromExcel(this);
		} catch (e) {
			_message(`error`, `BLME : Upload from config in file after previewer ${e}`);
		}
		finally {
			this.showSpinner = false;
		}
	}

	/**
	 * Continue download/upload after forced configuration setup
	 */
	@api
	async continueImport() {
		this.showSpinner = true;
		this.updateTextLog('Configuration was reloaded'); 
		this.updateTextLog('Budget lines in configuration -> ' + this.budgetLines.length);
		if (this.continueWithReader) {
			await this.continueDownloadToExcel();
		} else {
			try {
				await this.preparingPreview();
			} catch (e) {
				_message(`error`, `BLME : Continue import error ${e}`);
			}
			finally {
				this.showSpinner = false;
			}
		}
	};

	/**
	 * Remove unused in the input file analytic
	 */
	removeNewAnalytics() {
		try {
			this.isColumnFilteredByReader = true;
			let serviceSheet = this.configData.readWorkbook.getWorksheet(SERVICE_SHEET_NAME);
			let columnsFromFile = {};
			serviceSheet.getRow(1).eachCell((cell, cellNumber) => {
				columnsFromFile[cell.value] = 1;
			});
			Object.entries(ANALYTIC_MAP_BY_COLUMN_HEADER).forEach(([key, value, index]) => {
				if (!columnsFromFile[key] && this.SERVICE_COLUMNS_MAPPING[value]) {
					delete this.SERVICE_COLUMNS_MAPPING[value];
					delete this.SERVER_PARAMETERS_SO_MAPPING[value];
					this.updateTextLog('Analytic was not found in file: ' + key);
				}
			});
		} catch (e) {
			throw new Error(`Remove new analytics ${e}`);
		}
	}

	/**
	 * Call the export Budget Lines to  Excel method
	 */
	async downloadToExcelFromConfig(event) {
		this.clearTextLog();
		this.disabledButtons = true;
		this.showExcelLog = true;
		this.continueWithReader = true;
		try {
			this.showSpinner = true;
			this.configData.func = (await getFunctionByIdServer({ funcId: this.configurationMirror }))[0];
			this.updateTextLog('Reloading current configuration "' + this.configData.func.cblight__Title__c + '"');
			this.setFunctionBeforeExcelImport(this.configurationMirror);
		} catch (e) {
			_message(`error`, `BLME : Download to Excel from Configuration ${e}`);
			this.showSpinner = false;
		}
	};

	/**
	 * 	Continue download after forced configuration setup
	 */
	async continueDownloadToExcel() {
		try {
			this.updateTextLog('File download started');
			await this.getInitialOptions();
			await makeExcelFileBeforePreview(this);
		} catch (e) {
			_message(`error`, `BLME : Continue download to Excel ${e}`);
		}
		finally {
			this.showSpinner = false;
		}
	};

	/**
	 * The method splits array on groups  
	 */
	groupBy(arr, property) {
		return arr.reduce(function (memo, x) {
			if (!memo[x[property]]) { memo[x[property]] = []; }
			memo[x[property]].push(x);
			return memo;
		}, {});
	}
	/**
	 * The method makes validation formula map for accounts 
	 */
	getAccountFormulaMap(accountColumnLeter) {
		try {
			this.accTypesFoormulae = {};
			this.selectOptionMap['AccountSO'].forEach(currentAccountSO => {
				let labelTmp = currentAccountSO["label"];
				currentAccountSO["accType"] = labelTmp.split(' ')[0];
				currentAccountSO["label"] = labelTmp.substring(labelTmp.indexOf(' ') + 1);
			});
			let groupedByType = this.groupBy(this.selectOptionMap['AccountSO'], "accType");
			let currentTypeStartRow = 2;
			let typeOrder = [];
			Object.entries(groupedByType).forEach(([key, value]) => {
				typeOrder.push(value);
				let len = value.length;
				let formulae = 'Service!$' + accountColumnLeter + '$' + currentTypeStartRow + ':$' + accountColumnLeter + '$' + (currentTypeStartRow + len - 1);
				currentTypeStartRow += len;
				this.accTypesFoormulae[key] = formulae;
			});
			this.selectOptionMap['AccountSO'] = typeOrder.flat();
		} catch (e) {
			throw new Error(`Get account formula map ${e}`);
		}
	}

	/**
	 * Close previewer and write file
	*/
	async writeAfterPreviewer(event) {
		try {
			writeExcelFileAfterPreview(this);
		} catch (e) {
			_message(`error`, `BLME : Write after previewer ${e}`);
		}
		finally {
			this.showSpinner = false;
		}
	};

	/**
	 * Close previewer
	 */
	closePreviewer(event) {
		this.showPreviewer = false;
	};

	/**
	 * Make previewer columns
	 */
	makePreviewerColumns() {
		try {
			let newPreviewerColumns = [];
			newPreviewerColumns.push({ label: "#", fieldName: "rowNumber", class: this.STICKY_CLASSES[1] });
			Object.entries(this.columns).forEach(([key, value]) => {
				let tmpColumn = { label: value.letter, fieldName: value.key };
				if (value.number < this.MAX_STICKY_COL) {
					tmpColumn.class = this.STICKY_CLASSES[value.number + 1];
				}
				newPreviewerColumns.push(tmpColumn);
			});
			newPreviewerColumns.push({ label: '\u00B1', fieldName: "Sign" });
			newPreviewerColumns.push({ label: "\u00B1Total", fieldName: "Total*Sign" });
			if (this.isPreviewerImportMode) {
				newPreviewerColumns.push({ label: "Error", fieldName: "Error", class: "errorColumn" });
			}
			this.previewerData.previewerColumns = [...newPreviewerColumns];
		} catch (e) {
			throw new Error(`Make previewer columns ${e}`);
		}
	}

	/**
	 * Adjust sticky columns
	 */
	adjustStickyColumns() {
		const columnData = [
			{ selector: '[data-id="#"]', className: '.sticky-first' },
			{ selector: '[data-id="A"]', className: '.sticky-second' },
			{ selector: '[data-id="B"]', className: '.sticky-third' }
		];
		setTimeout(() => {
			const previewerTable = this.template.querySelector('[data-id="previewerTable"]');
			if (previewerTable) {
				columnData.forEach((column) => {
					const columnElement = previewerTable.querySelector(column.selector);
					const columnLeft = columnElement.offsetLeft;
					const stickyColumns = previewerTable.querySelectorAll(column.className);
					stickyColumns.forEach((element) => {
						element.style.left = columnLeft + 'px';
					});
				});
			}
		}, 0);
	}

	/**
	* Filiing previewer rows
	*  @param workBook 
	*/

	writeExcelToPreviewer(workBook) {
		try {
			const blSheet = workBook.getWorksheet(BL_SHEET_NAME);
			const totalSheet = workBook.getWorksheet(TOTAL_SHEET_NAME);
			let newPreviewerRows = [];
			this.updateFilterLog('Configuration::' + this.configData.func.cblight__Title__c);
			this.writeExcelToPreviewerBL(newPreviewerRows, blSheet);
			this.writeExcelToPreviewerTotals(newPreviewerRows, totalSheet)
			this.previewerData.previewerRows = [...newPreviewerRows];
			this.adjustStickyColumns();
		} catch (e) {
			throw new Error(`Write Excel to previewer ${e}`);
		}
	};

	/**
	* Filling previewer rows from Budget Line Sheet
	*/
	writeExcelToPreviewerBL(newPreviewerRows, blSheet) {
		try {
			const _this = this;
			const maxColumnNumber = this.previewerData.previewerColumns.length;
			let errorObj = {};
			let errorByRowColumnObj = {};
			if (_this.isPreviewerImportMode) {
				errorObj = this.groupErrors(this.result.errors);
				errorByRowColumnObj = this.errorByRowColumn(errorObj);
			}
			blSheet.eachRow((row, rowNumber) => {
				if (rowNumber < 3) {
					return;
				}
				if (rowNumber === 3) {
					row.eachCell((cell, colNumber) => {
						if (cell.value) {
							_this.updateFilterLog(cell.value.toString());
						}
					});
					return;
				}
				const newRow = { id: rowNumber, values: [] };
				newRow.values.push({ key: 'rowNumber', data: rowNumber, class: _this.STICKY_CLASSES[1] });
				row.eachCell({ includeEmpty: true }, (cell, colNumber) => {
					const columnLetter = numToExcelColumn(colNumber);
					const columnAddress = rowNumber + columnLetter;
					const errorText = errorByRowColumnObj[columnAddress];
					const tmpClass = colNumber <= _this.MAX_STICKY_COL ? _this.STICKY_CLASSES[colNumber + 1] :
						colNumber < this.periodData.firstPeriodColumnNumber ? 'textColumn' : '';
					const tmpData = _this.getAbsoluteValueFormatted(cell, row, BL_SHEET_NAME, colNumber);
					newRow.values.push(
						{
							key: colNumber,
							class: tmpClass,
							style: _this.generateCellStyle(cell, row, errorText, colNumber, _this, false),
							data: tmpData,
							title: `${tmpData} (${rowNumber}:${columnLetter})`
						}
					);
				});
				if (row.cellCount < maxColumnNumber) {
					newRow.values.push({}, {});
				}
				if (_this.isPreviewerImportMode) {
					newRow.values.push({ key: 'error', class: 'errorColumn', data: _this.formatGroupedErrors(errorObj, rowNumber) });
				}
				newPreviewerRows.push(newRow);
			});
			let commonError = errorByRowColumnObj['TotalTotal'];
			if (commonError) {
				this.redFilterLog(commonError);
				this.updateBudgetLinesFromPreviewer = false;
			}
		} catch (e) {
			throw new Error(`Write Excel to previewer BL${e}`);
		}
	}

	/**
	* Filiing previewer rows from Totals Sheet
	*/
	writeExcelToPreviewerTotals(newPreviewerRows, totalSheet) {
		try {
			const _this = this;
			let prevStyle = '';
			const countEmtyColumn = 2 + (Object.values(_this.columns).filter(column => column.isAnalytic)).length;
			totalSheet.eachRow((row, rowNumber) => {
				let newRow = { id: row.getCell(1).value, values: [] };
				let emptyColnumber = 1;
				row.eachCell((cell, colNumber) => {//colNumber from Total Sheet - order of column differs from BL Sheet
					if (colNumber === 2) {
						newRow.values.unshift(
							{ key: 'rowNumber', data: rowNumber, class: _this.STICKY_CLASSES[1] },
							{ key: 'empty' + emptyColnumber++, style: prevStyle, class: _this.STICKY_CLASSES[2] }
						);
						for (let i = 0; i < countEmtyColumn; i++) {
							newRow.values.push({ key: 'empty' + emptyColnumber++, style: prevStyle });
						}
					}
					const tmpClass = colNumber === 1 ? _this.STICKY_CLASSES[3] : ''; //colNumber 1 - Type
					prevStyle = _this.generateCellStyle(cell, row, null, colNumber, _this, true, countEmtyColumn);
					newRow.values.push(
						{
							key: colNumber,
							class: tmpClass,
							style: prevStyle,
							data: _this.getAbsoluteValueFormatted(cell, row, TOTAL_SHEET_NAME, colNumber),
							title: 'Totals:' + rowNumber + ':' + numToExcelColumn(colNumber)
						}
					);
				});

				newPreviewerRows.push(newRow);
			});
		} catch (e) {
			throw new Error(`Write Excel to previewer Totals ${e}`);
		}
	}
	/**
	* Generating cell style from Excel
	*/
	generateCellStyle(cell, row, errorText, colNumber, _this, isTotal, countEmtyColumn) {
		const style = [];
		const fill = cell.fill;
		const font = cell.font;
		const value = getValueFromCell(cell);
		const alignment = cell.alignment;
		const redColor = 'tomato';
		let colomnNumber = colNumber;
		if (errorText) {
			this.updateBudgetLinesFromPreviewer = false;
		}

		if (isTotal && colNumber > 1) {
			colomnNumber += countEmtyColumn + 1;// In Totals missed title, account, division and analytic
		}

		if (fill && fill.type === 'pattern' && fill.pattern === 'solid' && fill.fgColor && fill.fgColor.argb) {
			const hexColor = errorText ? redColor : _this.convertARGBToHex(fill.fgColor.argb);
			style.push(`background-color: ${hexColor};`);
		} else {
			if (errorText) {
				style.push(`background-color: ${redColor};`);
			}
		}
		if (font) {
			const { bold, color, size } = font;
			if (bold) {
				style.push('font-weight: bold;');
			}
		}
		if (alignment) {
			const { horizontal, indent } = alignment;
			if (indent) {
				style.push(`padding-left: ${indent * 20}px;`);
			}
		}
		if (typeof value === 'number' && value < 0) {
			style.push('color: red;');
		}
		const align = colomnNumber < _this.periodData.firstPeriodColumnNumber ? 'left' : 'right';
		style.push(`text-align: ${align};`);

		if (value === 'Formula error') {
			style.push('color: red;');
		}
		return style.join(' ');
	}

	/**
	*  @param argb convert colors
	*/
	convertARGBToHex(argb) {
		const alphaChannelPresent = argb.length === 8;
		const hexColor = alphaChannelPresent ? `#${argb.substring(2)}` : `#${argb}`;
		return hexColor;
	}

	/**
	* Format number with report specific
	*/
	getAbsoluteValueFormatted(cell, row, sheetName, colNumber) {
		const value = getValueFromCell(cell);
		let formattedValue = value;
		const cellNumber = row.cellCount;

		if (sheetName === TOTAL_SHEET_NAME && typeof value === 'number' && colNumber + 1 === cellNumber) {
			formattedValue = value < 0 ? '-' : '+';
		} else
			if (typeof value === 'number') {
				formattedValue = value < 0 ? `($ ${Math.abs(value).toLocaleString()})` : `$ ${value.toLocaleString()}`;
			}
		if (!formattedValue) { formattedValue = '\u3164'; }
		return formattedValue;
	}

	/**
	* Group errors by Excel row number
	*/
	groupErrors(errors) {
		const errorObj = {};
		for (const error of errors) {
			const { rowNumber, text, colNumber } = error;
			if (!errorObj[rowNumber]) {
				errorObj[rowNumber] = {};
			}
			if (!errorObj[rowNumber][text]) {
				errorObj[rowNumber][text] = [];
			}
			errorObj[rowNumber][text].push(colNumber || 'N/A');
		}

		return errorObj;
	}

	/**
	* Format errors
	*/
	formatGroupedErrors(groupedErrors, rowNumber) {
		const rowErrors = groupedErrors[rowNumber];
		if (!rowErrors) {
			return '';
		}
		let formattedOutput = '';
		for (const errorText in rowErrors) {
			const colLetters = rowErrors[errorText].join(',');
			formattedOutput += `row ${rowNumber}: ${errorText}: ${colLetters} ; `;
		}
		return formattedOutput;
	}

	/**
	* Make object for quick find cells with error by row number and column letter
	*/
	errorByRowColumn(errorObj) {
		const errorObjByRowColumn = {}
		Object.entries(errorObj).forEach(([rowNumber, errorDict]) => {
			Object.entries(errorDict).forEach(([errorText, columnLetters]) => {
				columnLetters.forEach(columnLetter => {
					const combinedKey = `${rowNumber}${columnLetter}`;
					errorObjByRowColumn[combinedKey] = errorObjByRowColumn[combinedKey] ? errorText + '; ' + errorObjByRowColumn[combinedKey] : errorText;
				});
			});
		});
		return errorObjByRowColumn;
	}

	/**
	* Metood makes synthetic SO with account Type + account name
	*/
	getAccountWithType() {
		try {
			const accountWithTypes = {};
			const accountType = {};
			this.selectOptionMap['AccountTypeSO'].forEach(accType => {
				accountType[accType.value] = accType.label;
			});
			this.selectOptionMap['AccountSO'].forEach(account => {
				const accTypeName = accountType[account.accType];
				if (accTypeName) {
					const tmpKey = `${accTypeName}:::${account.label}`;
					accountWithTypes[tmpKey] = account.value;
				}
			});
			this.mapsSO['AccountWithTypesSO'] = accountWithTypes;
		} catch (e) {
			throw new Error(`Get account with type ${e}`);
		}
	}

	/**
	 * Set showDownloadPanel
	 */
	@api
	set showDownloadPanel(value) {
		this.showSpinner = !value;
	}

	/**
	 * Get showDownloadPanel
	 */
	get showDownloadPanel() {
		return !this.showSpinner;
	}

}