import {_cl, _generateFakeId} from 'c/cbUtils';
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
		if (!rl.isHeader) {
			rl.Id = _generateFakeId();
			for (let i = 0; i < rl.reportCells.length; i++) {
				const col = reportColumns[i];
				const cell = rl.reportCells[i];
				const curAmount = cell.value;
				const columnType =  cell.field;
				const accumulatedAmount = lastAmountMap[rl.Id + columnType] || 0;
				lastAmountMap[rl.Id + columnType] = accumulatedAmount + curAmount;
				
				if (!col.needYTD) {
					continue;
				}
				cell.value = col.class == 'QuarterColumn' || col.class == 'TotalColumn' ? cell.value : lastAmountMap[rl.Id + columnType];
			}
		}
		
	};
	reportLines.forEach(calculateReportLineYTD);
	return reportLines;
};


export {getReportLinesWithYTDValues};