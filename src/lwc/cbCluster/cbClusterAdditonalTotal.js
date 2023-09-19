import {_getCopy, _message} from 'c/cbUtils';

let context;

/**
 * Method generates additional lines to cluster total
 */
const generateAdditionalTotals = (_this) => {
	try {
		context = _this;
		const addedTotalsMap = {};
		const subClusters = context.currentCluster.subClusters;
		for (let i = 0; i < subClusters.length; i++) {
			let sc = subClusters[i];
			let addedTL = addedTotalsMap[sc.key];
			if (!addedTL) {
				const copyLine = _getCopy(sc.totalLine);
				copyLine.formatter = "currency";
				copyLine.name = sc.key;
				copyLine.sign = sc.totalLine.cblight__CBAccountSign__c;
				addedTotalsMap[sc.key] = copyLine;
			} else {
				const amounts = sc.totalLine.cblight__CBAmounts__r;
				for (let j = 0; j < amounts.length; j++) {
					addedTL.cblight__CBAmounts__r[j].cblight__Value__c += +amounts[j].cblight__Value__c;
				}
			}
		}
		let additionalTotalLines = Object.values(addedTotalsMap);
		generatePercentAdditionalTotal(additionalTotalLines);
		context.additionalTotalLines = additionalTotalLines;
		context.isAdditionalTotalsOpen = true;
	} catch (e) {
		_message('error', 'Cluster : Generate Additional Totals : ' + e);
	}
};

/**
 * If additional total has more than two lines - percent line should be calculated
 */
const generatePercentAdditionalTotal = (additionalTotalLines) => {
	try {
		if (additionalTotalLines.length < 2) return null;
		let signTotals = {};
		additionalTotalLines.forEach(atl => {
			let signTotalLine = signTotals[atl.sign];
			if (!signTotalLine) {
				signTotals[atl.sign] = _getCopy(atl);
			} else {
				for (let i = 0; i < atl.cblight__CBAmounts__r.length; i++) {
					signTotalLine.cblight__CBAmounts__r[i].cblight__Value__c += +atl.cblight__CBAmounts__r[i].cblight__Value__c;
				}
				signTotalLine.yearlyTotal += +atl.yearlyTotal;
			}
		});

		signTotals = Object.values(signTotals);
		if (signTotals.length < 2) return null;
		const diffTotalLine = {cblight__CBAmounts__r: [], formatter: "percent"};
		for (let i = 0; i < signTotals[0].cblight__CBAmounts__r.length; i++) {
			diffTotalLine.cblight__CBAmounts__r[i] = {};
			const firstAmount = signTotals[0].cblight__CBAmounts__r[i].cblight__Value__c,
				secondAmount = signTotals[1].cblight__CBAmounts__r[i].cblight__Value__c;
			diffTotalLine.cblight__CBAmounts__r[i].cblight__Value__c = firstAmount === 0 ? '0' : secondAmount / firstAmount;
		}
		diffTotalLine.yearlyTotal = signTotals[0].yearlyTotal === 0 ? 0 : signTotals[1].yearlyTotal / signTotals[0].yearlyTotal;
		diffTotalLine.name = 'Difference';
		additionalTotalLines.push(diffTotalLine);
	} catch (e) {
		_message('error', 'Generate Percent Additional Total Error : ' + e);
	}
};

const hideAdditionalTotal = () => {
	context.isAdditionalTotalsOpen = false;
	context.additionalTotalLines = null;
};

const displayAdditionalTotalSignIfNeeded = (_this) => {
	context = _this;
	if (!context.currentCluster.subClusters || context.currentCluster.subClusters.length < 2) return null;
	context.isAdditionalTotalsNeeded = true;
};

export {
	generateAdditionalTotals, displayAdditionalTotalSignIfNeeded, hideAdditionalTotal
};