import {_getCopy, _message} from "c/cbUtils";

let context; // this from parent
const FIT = 'fitTarget';
const LESS = 'lessTarget';
const OVER = 'overTarget';
let topdownTolerance = 3; // 3%
let orgVariable = {};

/**
 * Method updates summary budget lines with target lines
 */
const generateTopdown = (_this) => {
	context = _this;
	orgVariable = JSON.parse(localStorage.getItem('orgVariable'));
	topdownTolerance = orgVariable && orgVariable.cblight__TopdownTolerance__c ? orgVariable.cblight__TopdownTolerance__c : topdownTolerance;
	updateSummaryLinesWithKeys();
	createSummaryTopdownLines();
};

/**
 * Each summary line must have special key
 */
const updateSummaryLinesWithKeys = () => {
	try {
		context.tableData.forEach(line => line.tdKey = getGroupingKeyForLevel(line, line.level));
	} catch (e) {
		_message('error', 'Budget Summary : Update Summary With Keys Error : ' + e);
	}
};

/**
 * Method creates topdown lines inside the summary lines
 */
const createSummaryTopdownLines = () => {
	try {
		const groupingDeepness = getGroupingDeepness(); // numbers of grouping 1-5
		context.tdBudgetLines = _getCopy(context.tdBudgetLines);
		const topDownMap = context.tableData.reduce((r, line) => {
			r[line.tdKey] = line;
			return r;
		}, {});
		for (let i = 0; i <= groupingDeepness; i++) {
			context.tdBudgetLines.forEach(tdLine => {
				tdLine = _getCopy(tdLine);
				const tdKey = getGroupingKeyForLevel(tdLine, i);
				let summaryLine = topDownMap[tdKey];
				if (!summaryLine) {
					summaryLine = {name: tdLine.Name, cblight__CBAmounts__r: getListOfEmptyAmounts(tdLine), yearlyTotal: 0};
					topDownMap[tdKey] = summaryLine;
				}
				let topDownAmounts = summaryLine.topDownAmounts;
				if (!topDownAmounts) {
					summaryLine.topDownAmounts = tdLine.cblight__CBAmounts__r;
				} else {
					summaryLine.topDownAmounts = sumUpAmounts(summaryLine.topDownAmounts, tdLine.cblight__CBAmounts__r);
				}
			});
		}
		let updatedTableData = Object.values(topDownMap);
		calculateTopdownTotalAndUpdateStyle(updatedTableData);
		context.tableData = updatedTableData;
	} catch (e) {
		_message('error', 'Budget Summary : Create Summary Topdown Error : ' + e);
	}
};

/**
 * Method returns a list of amounts with zeros
 */
const getListOfEmptyAmounts = (tdLine) => {
	const emptyAmounts = _getCopy(tdLine.cblight__CBAmounts__r);
	emptyAmounts.forEach(a => a.cblight__Value__c = 0);
	return emptyAmounts;
};

/**
 * Method sums amounts from two lines and back the first line
 */
const sumUpAmounts = (lines1, lines2) => {
	try {
		lines1.forEach((a, i) => a.cblight__Value__c += lines2[i].cblight__Value__c);
		return lines1;
	} catch (e) {
		_message('error', 'Budget Summary : Sum Amounts Error : ' + e);
	}
};

/**
 *
 * @param line source line
 * @param level grouping level 0, 1, 2, 3 ....
 * @returns {string} key of record
 */
const getGroupingKeyForLevel = (line, level) => {
	try {
		let key = '';
		for (let i = 1; i <= level; i++) {
			const clRuleAnalytic = context.clusterRule[`cblight__Level${i}__c`];
			if (clRuleAnalytic) {
				let analytic = line[clRuleAnalytic];
				if (analytic) {
					key += analytic;
					continue;
				}
				analytic = line[clRuleAnalytic.replace('__c', '__r')];
				if (analytic) {
					key += analytic.Id;
					continue;
				}
				key += 'N/A';
			}
		}
		return key;
	} catch (e) {
		_message('error', 'Budget Summary : Get Grouping Key Error : ' + e);
	}
};

/**
 * Max deepness of a cluster rule
 */
const getGroupingDeepness = () => {
	try {
		for (let i = 1; i <= 5; i++) {
			if (!context.clusterRule[`cblight__Level${i}__c`]) {
				return --i;
			}
		}
		return 5;
	} catch (e) {
		_message('error', 'Budget Summary : Get Grouping Deepness Error : ' + e);
	}
};

/**
 * Method calculates right totals and set styles for each amount
 */
const calculateTopdownTotalAndUpdateStyle = (updatedTableData) => {
	try {
		updatedTableData.forEach(line => { //iteration over table rows
			if (line.topDownAmounts) {
				line.topDownTotal = 0;
				line.topDownAmounts.forEach(a => line.topDownTotal += +a.cblight__Value__c);
				let r = getAmountStyleAndHelpText(line.yearlyTotal, line.topDownTotal);
				line.totalClass = r.class;
				line.helpText = r.helpText;
				line.topDownAmounts.forEach((tda, i) => {
					r = getAmountStyleAndHelpText(line.cblight__CBAmounts__r[i].cblight__Value__c, tda.cblight__Value__c);
					tda.class = r.class; // background color of a cell
					tda.helpText = r.helpText;
				})
			}
		})
	} catch (e) {
		_message('error', 'Summary : Calculate Topdown Total and Set Styles Error : ' + e);
	}
};

/**
 * Method adds style and text of hint to each topdown amount
 * @param amount
 * @param targetAmount
 */
const getAmountStyleAndHelpText = (amount, targetAmount) => {
	try {
		const coefficient = 1 + topdownTolerance / 100;
		let difference = getCurrencyFormat(Math.abs(amount - targetAmount));
		let percent = getPercentFormat(amount, targetAmount);
		if (amount * coefficient > targetAmount && amount / coefficient < targetAmount) {
			return {
				class: FIT,
				helpText: `Value fits the target by ${percent}. The difference is ${difference}.`
			};
		}
		if (amount > targetAmount) {
			return {
				class: OVER,
				helpText: `Value exceed the target by ${percent}. The difference is ${difference}. `
			};
		}
		if (amount < targetAmount) {
			return {
				class: LESS,
				helpText: `Value is less than target by ${percent}. The difference is ${difference}`
			};
		}
	} catch (e) {
		_message('error', 'Summary : Get Amount Class Error : ' + e);
	}
};

/**
 * Service method TODO: Move to utils
 */
const getCurrencyFormat = (value) => {
	return parseFloat(value.toFixed(2)).toLocaleString('en-US', {
		style: 'currency',
		currency: 'USD',
	});
};

const getPercentFormat = (amount, targetAmount) => {
	let smaller, bigger;
	if (amount > targetAmount) {
		smaller = targetAmount;
		bigger = amount;
	} else {
		smaller = amount;
		bigger = targetAmount;
	}
	return bigger === 0 ? `100%` : (Math.abs((1 - (smaller / bigger)) * 100)).toFixed(2) + '%';
};


export {
	generateTopdown
};