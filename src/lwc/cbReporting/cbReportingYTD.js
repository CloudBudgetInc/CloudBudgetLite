/**
 * Library for calculation YTD values
 */
const getReportLinesWithYTDValues = (reportLines, reportColumns) => {
	if (!reportColumns.some(col => col.needYTD)) {
		console.log('No YTD needed');
		return reportLines; // if nobody needs YTD
	}
	const lastAmountMap = {};
	const calculateReportLineYTD = (rl) => {
		for (let i = 0; i < rl.reportCells.length; i++) {
			const col = reportColumns[i];
			if (!col.needYTD) {
				continue;
			}
			const cell = rl.reportCells[i];
			const curAmount = cell.value;
			const masterColumnId = col.masterColumnId || col.columnId;
			const accumulatedAmount = lastAmountMap[masterColumnId] || 0;
			cell.value = lastAmountMap[masterColumnId] = accumulatedAmount + curAmount;
		}
	};
	reportLines.forEach(calculateReportLineYTD);
	return reportLines;
};


export {getReportLinesWithYTDValues};