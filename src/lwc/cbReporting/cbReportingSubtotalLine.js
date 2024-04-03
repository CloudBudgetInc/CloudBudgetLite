import {_message} from "c/cbUtils";

let reportLines;
let subRowConfigs;

/*
JSON EXAMPLE '[
{
"after": "02:Expense  Total",
"legend": ["01:Income  Total", "02:Expense  Total"],
"formula": "#0 / #1 * -1",
"title": "Gross Margin",
"unit": "%",
"styleClass": "TotalLineLvlGlobal"
}
]'
*/

/**
 * Method uses a JSON string from a report configuration to add a new substring to the report
 */
const addCustomSubtotalLines = (rLines, subRows) => {
	if (!subRows) return rLines;
	subRowConfigs = JSON.parse(subRows);
	reportLines = rLines;
	subRowConfigs.forEach(subRowConfig => addSubtotalLine(subRowConfig));
	return reportLines;
};

/**
 * For each JSON object report can get a new subtotal line
 */
const addSubtotalLine = (subRowConfig) => {
	try {
		let subLine = JSON.parse(JSON.stringify(reportLines[0]));// new subline needed to insert
		subLine.class = subRowConfig.styleClass; // set style
		subLine.reportCells.forEach(c => { // nullify amounts
			c.value = 0;
			c.class = subRowConfig.styleClass;
			c.unit = subRowConfig.unit;
		});
		subLine.isTotal = true;
		subLine.labels[1] = ''; // TODO erase
		subLine.labels[0] = subRowConfig.title;
		let reportLineObject = findFormulaReportLines(subRowConfig); // find those two source lines
		subLine = populateSubLine(subLine, reportLineObject, subRowConfig); // populate amounts to subtotal line
		if (!subLine) return null;
		putSubLineIntoThePlace(subLine, subRowConfig);
	} catch (e) {
		_message('error', 'Add Subtotal Line Error ' + e);
		return reportLines;
	}
};

/**
 * Method returns {} with two source report lines, where key is the RL label
 */
const findFormulaReportLines = (subRowConfig) => {
	try {
		let reportLineObject = {};
		reportLines.forEach(rl => {
			const rlLabel = rl.labels[0];
			if (!subRowConfig.legend.includes(rlLabel)) return;
			reportLineObject[rlLabel] = rl;
		});
		return reportLineObject;
	} catch (e) {
		_message('error', 'Find Formula Report Lines Error ' + e);
	}
};

/**
 * The method populates values of subline
 */
const populateSubLine = (subLine, reportLineObject, subRowConfig) => {
	try {
		let source0 = reportLineObject[subRowConfig.legend[0]]; // first source report line
		let source1 = reportLineObject[subRowConfig.legend[1]]; // second source report line
		if (!source0 || !source1) return null;

		subLine.reportCells.forEach((c, i) => {
			try {
				let formulaEval = subRowConfig.formula;
				let val0 = source0.reportCells[i].value; // first source report line value
				let val1 = source1.reportCells[i].value; // second source report line value
				formulaEval = formulaEval.replace('#0', val0).replace('#1', val1);
				let result = eval(formulaEval);
				subLine.reportCells[i].value = parseFloat(result);
			} catch (e) {
				_message('error', 'Report Cell Calculation Error ' + e);
			}
		});
		return subLine;
	} catch (e) {
		_message('error', 'Populate Sublines Error: ' + e);
	}
};

/**
 *The method inserts a new subtotal line to the list of report lines
 */
const putSubLineIntoThePlace = (subLine, subRowConfig) => {
	try {
		let updatedReportLines = [];
		reportLines.forEach(rl => {
			updatedReportLines.push(rl);
			if (rl.labels[0] === subRowConfig.after) {
				updatedReportLines.push(subLine);
			}
		});
		reportLines = updatedReportLines;
	} catch (e) {
		_message('error', 'Put Subline Error: ' + e);
	}
};

export {addCustomSubtotalLines};