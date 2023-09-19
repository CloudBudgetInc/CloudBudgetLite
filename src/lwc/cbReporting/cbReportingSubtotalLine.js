/**
 * This lib is for custom report row
 * TODO Redo this code baser on CBRow__c objects
 *
 */
const task = {
	after: '02:Expense  Total',
	legend: ['01:Income  Total', '02:Expense  Total'],
	formula: '#0 + #1',
	title: 'Gross Profit',
	styleClass: "TotalLineLvlGlobal"
};



const addSubtotalLine = (reportLines) => {
	try {
		reportLines.forEach(rl => console.log(JSON.stringify(rl)));
		let subLine = JSON.parse(JSON.stringify(reportLines[0]));//
		subLine.class = task.styleClass;
		subLine.reportCells.forEach(c => {
			c.value = 0;
			c.class = task.styleClass;
		});
		subLine.labels[1] = ''; // TODO erase
		subLine.labels[0] = task.title;
		let reportLineObject = foundFormulaReportLines(reportLines);
		subLine = populateSubLine(subLine, reportLineObject);
		if (!subLine) return reportLines;

		return putSubLineIntoThePlace(reportLines, subLine);
	} catch (e) {
		return reportLines;
	}
};

const populateSubLine = (subLine, reportLineObject) => {
	try {
		let source0 = reportLineObject[task.legend[0]];
		let source1 = reportLineObject[task.legend[1]];
		if (!source0 || !source1) return null;
		const fromCurrencyFormat = (value) => value.replace(/[^\d.-]/g, '');
		subLine.reportCells.forEach((c, i) => {
			let formulaEval = task.formula;
			let val0 = source0.reportCells[i].value;
			let val1 = source1.reportCells[i].value;
			val0 = fromCurrencyFormat(val0);
			val1 = fromCurrencyFormat(val1);
			formulaEval = formulaEval.replace('#0', val0).replace('#1', val1);
			let result = eval(formulaEval);
			subLine.reportCells[i].value = parseFloat(result);
		});
		return subLine;
	} catch (e) {
		alert('Populate Subline Error: ' + e);
	}
};

const putSubLineIntoThePlace = (reportLines, subLine) => {
	try {
		let updatedReportLines = [];
		reportLines.forEach(rl => {
			updatedReportLines.push(rl);
			if (rl.labels[0] === task.after) {
				updatedReportLines.push(subLine);
			}
		});
		return updatedReportLines;
	} catch (e) {
		alert('Put Subline Error: ' + e);
	}
};


const foundFormulaReportLines = (reportLines) => {
	try {
		let reportLineObject = {};
		reportLines.forEach(rl => {
			if (task.legend.includes(rl.labels[0])) {
				reportLineObject[rl.labels[0]] = rl;
			}
		});
		return reportLineObject;
	} catch (e) {
		alert('foundFormulaReportLines Error ' + e);
	}
};

export {addSubtotalLine};