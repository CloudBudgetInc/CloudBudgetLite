import {_message, _setCell} from 'c/cbUtils';

const BOLD_FONT = {
	bold: true
};
const TOTAL_FILL = {
	type: 'pattern',
	pattern: 'solid',
	fgColor: {argb: 'F7F7F7'}
};
const LINE_FONT = {
	size: 10,
	color: {argb: '7D7D7D'}
};
const SUB_CLUSTER_FONT = {
	underline: true,
	italic: true
};

const LEFT_BORDER = {
	left: {style: 'thin'},
};

const RIGHT_ALIGN = {horizontal: 'right'};

let numberColumnsOffset;
const analyticsArray = [];
let currentCurrencyFormat;

/**
 * Method generates additional lines to cluster total
 */
const getBudgetSheet = (blSheet, summaryData, globalCluster) => {
	try {
		prepareAnalyticList();
		numberColumnsOffset = calculateNumberColumnOffset(globalCluster);
		getBudgetSummary(blSheet, summaryData); //	hyperlink: '#\'Budget\'!A50'
		getBudgetDetails(blSheet, globalCluster);
		addHyperLinks(blSheet);
		for (let i = 2; i < numberColumnsOffset; i++) {
			let accColumn = blSheet.getColumn(i); //.hidden
			accColumn.outlineLevel = 1;
			accColumn.hidden = true;
		}
	} catch (e) {
		_message('error', 'Excel Backup : Generate Budget Sheet Error : ' + e);
	}
};
/**
 * List of additional dynamic analytics in hidden columns
 */
const prepareAnalyticList = () => {
	const orgVar = localStorage.getItem('orgVariable');
	['CBAccount', 'CBDivision', 'CBVariable1', 'CBVariable2', 'CBVariable3', 'CBVariable4', 'CBVariable5'].forEach((a, i) => {
		const varLabel = orgVar[`cblight__${a}Label__c`] || a;
		analyticsArray.push({
			field: `cblight__${a}__c`,
			fieldName: `cblight__${a}__r`,
			label: varLabel,
			offset: i + 3,
			columnIdx: i + 2
		});
	});
};
/**
 * method returns a number of columns that may be reserved for analytics. It can be different for different clients
 */
const calculateNumberColumnOffset = (globalCluster) => {
	let r = 3; // Account is required
	const parseClusterContent = (cluster) => {
		if (cluster.subClusters && cluster.subClusters.length > 0) {
			cluster.subClusters.forEach(subCluster => {
				subCluster.lines.forEach(line => {
					analyticsArray.forEach(a => r = line[a.field] ? Math.max(r, a.offset) : r);
				});
			});
		}
		if (cluster.childClusters && cluster.childClusters.length > 0) {
			cluster.childClusters.forEach(cl => parseClusterContent(cl));
		}
	};
	parseClusterContent(globalCluster);
	return r;
};

/**
 * Method generates budget summary table
 */
const getBudgetSummary = (blSheet, summaryData) => {
	try {
		const titleRow = blSheet.getRow(5); // periods
		_setCell(titleRow.getCell(1), 'Title');
		analyticsArray.forEach(a => {
			if (a.offset <= numberColumnsOffset) _setCell(titleRow.getCell(a.columnIdx), a.label);
		});

		const BYPeriods = JSON.parse(localStorage.getItem('BYPeriods'));
		let colIdx = numberColumnsOffset, rowIdx = 7;
		BYPeriods.forEach(period => {
			_setCell(titleRow.getCell(colIdx), period.Name, null, null, null, RIGHT_ALIGN);
			colIdx++;
		});
		_setCell(titleRow.getCell(colIdx), 'Total', null, null, null, RIGHT_ALIGN);

		const headRow = blSheet.getRow(6);
		_setCell(headRow.getCell(1), 'Budget Summary');

		summaryData.forEach(line => {
			const row = blSheet.getRow(rowIdx);
			const currencyFormat = getCurrencyFormat(line.CurrencyIsoCode);
			_setCell(row.getCell(1), line.name);
			let cIdx = numberColumnsOffset;
			line.cblight__CBAmounts__r.forEach(amount => {
				_setCell(row.getCell(cIdx), amount.cblight__Value__c, null, null, currencyFormat);
				cIdx++;
			});
			_setCell(row.getCell(cIdx), line.yearlyTotal, null, BOLD_FONT, currencyFormat, null, LEFT_BORDER);
			rowIdx++;
		});
	} catch (e) {
		_message('error', 'Excel Backup : Get Budget Summary Error : ' + e);
	}
};

/**
 * Method generates currency format for Excel
 */
const getCurrencyFormat = (currencyCode) => {
	if (!currentCurrencyFormat) {
		if (currencyCode) {
			const symbol = new Intl.NumberFormat("en-US", {
				style: 'currency',
				currency: currencyCode
			}).formatToParts("1").find(part => part.type = "currency").value || '$';
			currentCurrencyFormat = `"${symbol}"#,##0;[Red]\-"${symbol}"#,##0`;
		} else {
			currentCurrencyFormat = '"$"#,##0;[Red]\-"$"#,##0';
		}
	}
	return currentCurrencyFormat;
};

/**
 * Method generates budget lines table
 */
const getBudgetDetails = (blSheet, globalCluster) => {
	try {
		let lastRowIdx = blSheet.actualRowCount;
		const headRow = blSheet.getRow(lastRowIdx + 3);
		_setCell(headRow.getCell(1), 'Budget Details');
		let rowIdx = lastRowIdx + 4;
		const parseClusterContent = (cluster) => {
			let row = blSheet.getRow(rowIdx);
			const indent = getTitleIndent(cluster.level);
			_setCell(row.getCell(1), indent + cluster.name.toUpperCase(), null, BOLD_FONT);
			let cIdx = numberColumnsOffset;
			const currencyFormat = getCurrencyFormat(cluster.totalLine.CurrencyIsoCode);
			cluster.totalLine.cblight__CBAmounts__r.forEach(amount => {
				_setCell(row.getCell(cIdx), amount.cblight__Value__c, null, BOLD_FONT, currencyFormat);
				cIdx++;
			});
			_setCell(row.getCell(cIdx), cluster.totalLine.yearlyTotal, null, BOLD_FONT, currencyFormat, null, LEFT_BORDER);
			rowIdx++;

			if (cluster.subClusters && cluster.subClusters.length > 0) {
				cluster.subClusters.forEach(subCluster => {
					/// SubCluster Total Line
					let subClusterTotalRow = blSheet.getRow(rowIdx);
					subClusterTotalRow.outlineLevel = 1;
					_setCell(subClusterTotalRow.getCell(1), indent + subCluster.key, null, SUB_CLUSTER_FONT);
					cIdx = numberColumnsOffset;
					const currencyFormat = getCurrencyFormat(subCluster.totalLine.CurrencyIsoCode);
					subCluster.totalLine.cblight__CBAmounts__r.forEach(amount => {
						_setCell(subClusterTotalRow.getCell(cIdx), amount.cblight__Value__c, null, null, currencyFormat);
						cIdx++;
					}); //(cell, value, fill, font, numFmt, alignment, border)
					_setCell(subClusterTotalRow.getCell(cIdx), subCluster.totalLine.yearlyTotal, null, BOLD_FONT, currencyFormat, null, LEFT_BORDER);
					rowIdx++;
					/// Simple Lines
					subCluster.lines.forEach(line => {
						let lineRow = blSheet.getRow(rowIdx);
						lineRow.outlineLevel = 2;
						lineRow.height = 11;
						_setCell(lineRow.getCell(1), ' ' + indent + line.Name, null, LINE_FONT);
						analyticsArray.forEach(a => {
							if (a.offset <= numberColumnsOffset) {
								_setCell(lineRow.getCell(a.columnIdx), line[a.fieldName]?.Name, null, LINE_FONT);
							}
						});
						cIdx = numberColumnsOffset;
						const currencyFormat = getCurrencyFormat(line.CurrencyIsoCode);
						line.cblight__CBAmounts__r.forEach(amount => {
							_setCell(lineRow.getCell(cIdx), amount.cblight__Value__c, null, LINE_FONT, currencyFormat);
							cIdx++;
						});
						_setCell(lineRow.getCell(cIdx), line.cblight__Value__c, null, BOLD_FONT, currencyFormat, null, LEFT_BORDER);
						rowIdx++;
					});
				});
			}
			if (cluster.childClusters && cluster.childClusters.length > 0) {
				cluster.childClusters.forEach(cl => parseClusterContent(cl));
			}
		};
		parseClusterContent(globalCluster);
	} catch (e) {
		_message('error', 'Excel Backup : Get Budget Details Error : ' + e);
	}
};
/**
 * @return spaces before titles
 */
const getTitleIndent = (lvl) => {
	let r = '';
	for (let i = 0; i < lvl; i++) r += '  ';
	return r;
};
/**
 * Method makes links from budget summary to budget lines
 */
const addHyperLinks = (blSheet) => {
	try {
		let summaryTitles = [], idx = 0;
		let isSummary = true;
		for (let i = 7; i <= blSheet.actualRowCount; i++) {
			let cell = blSheet.getCell(`A${i}`);
			if (!cell.value) continue;
			if (cell.value === 'Budget Details') {
				isSummary = false;
				continue;
			}
			if (isSummary) {
				summaryTitles.push(cell);
				continue;
			}
			if (cell.font.bold) {
				if (idx < summaryTitles.length) {
					summaryTitles[idx].value = {text: summaryTitles[idx].value, hyperlink: `#Budget!A${i}`};
					idx++;
				}
			}
		}
	} catch (e) {
		_message('error', 'Excel Backup : Add Hyperlinks Error : ' + e);
	}
};

export {
	getBudgetSheet
};