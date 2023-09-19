import getBudgetLineServer from '@salesforce/apex/CBBudgetLinePageController.getAllocatedBudgetLinesServer';
import saveAllocatedBudgetLinesServer from '@salesforce/apex/CBBudgetLinePageController.saveAllocatedBudgetLinesServer';
import {_deleteFakeId, _generateFakeId, _getCopy, _message, _parseServerError, _cl} from "c/cbUtils";

let context; // this from parent
const EXTRA_FIELDS_IN_BUDGET_LINE = ['cblight__CBAmounts__r', 'idx', 'yearlyTotal', 'percent', 'Owner', 'LastModifiedById', 'cblight__ParentBudgetLine__r', 'cblight__CBAccountSign__c', 'cblight__Index__c'];

/**
 * The method splits periods by BY for TAB TITLES
 */
const getAllocatedBudgetLines = (_this) => {
	context = _this;
	try {
		getBudgetLineServer({parentBudgetLineId: context.budgetLine.Id})
			.then(allocatedBudgetLines => {
				context.budgetLine.cblight__ChildrenBudgetLines__r = allocatedBudgetLines;
				indexAllocatedBudgetLines();
				disableAmounts();
				calculateChildrenTotal();
				recalculatePercent();
				generateAllocationSummary();
				context.showAllocation = true;
			})
			.catch(e => _parseServerError('BLM Allocation: Get Allocated Budget Lines Callback Error', e))
	} catch (e) {
		_message('BLM Allocation: Get Allocated Budget Lines Error ' + e);
	}
};
/**
 * This method disables amounts from editing if budget line is formula
 */
const disableAmounts = () => {
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
		if (line.cblight__isFormulaBudgetLine__c) {
			line.cblight__CBAmounts__r.forEach(a => a.disabled = true);
			line.percentDisabled = true;
		}
	});
};

/**
 * This method populates index to each allocated line
 */
const indexAllocatedBudgetLines = () => {
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach((line, i) => line.idx = ` #${i + 1} `);
};

/**
 * This method recalculates allocated BL amounts after cvCompleteAssistant
 */
const recalculateAllocationLine = (event, _this) => {
	context = _this;
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
		if (event.detail.amounts[0].cblight__CBBudgetLine__c == line.Id) {
			line.cblight__Value__c = 0;
			event.detail.amounts.forEach(a => {
				line.cblight__CBAmounts__r.forEach(amount => {
					if (amount.Id == a.Id ) {
						amount.cblight__Value__c = a.cblight__Value__c;
						line.cblight__Value__c += parseInt(a.cblight__Value__c, 10);
					}
				});
			});
		}
	});
	calculateChildrenTotal();
	recalculatePercent();
	generateAllocationSummary();
}



/**
 * This method calculates total of each allocated budget line
 */
const calculateChildrenTotal = () => {
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
		let childBYTotal = 0;
		line.cblight__CBAmounts__r.forEach(amount => {
			childBYTotal += +amount.cblight__Value__c;
		});
		line.yearlyTotal = childBYTotal;
	});
};

/**
 * This method recalculates percents for each allocated line
 */
const recalculatePercent = () => {
	let totalBLTotal = 0;
	context.budgetLine.amountObject.wholeAmounts.forEach(amount => totalBLTotal += +amount.cblight__Value__c);
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
		let childTotal = 0;
		line.cblight__CBAmounts__r.forEach(amount => {
			childTotal += +amount.cblight__Value__c;
		});
		line.percent = childTotal === 0 ? 0 : Math.round(childTotal / totalBLTotal * 100) / 100;
	})
};

/**
 * This method generates summary total line for allocated lines
 */
const generateAllocationSummary = () => {
	if (!context.budgetLine.cblight__ChildrenBudgetLines__r || context.budgetLine.cblight__ChildrenBudgetLines__r.length === 0) return;
	const allocationSummary = {
		cblight__CBAmounts__r: [],
		Name: 'Allocation Summary',
		yearlyTotal: 0,
		percent: 0,
		ready: true
	};
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
		line.cblight__CBAmounts__r.forEach((amount, idx) => {
			let summaryCell = allocationSummary.cblight__CBAmounts__r[idx];
			if (!summaryCell) {
				summaryCell = {cblight__Value__c: 0};
				allocationSummary.cblight__CBAmounts__r[idx] = summaryCell;
			}
			summaryCell.cblight__Value__c += +amount.cblight__Value__c;
			allocationSummary.yearlyTotal += +amount.cblight__Value__c;

		});
		allocationSummary.percent += +line.percent;
	});
	context.allocationSummary = allocationSummary;
};

/////// HANDLERS ////////////////
/**
 * Method updates amounts of allocated budget lines and recalculates percent and totals
 */
const handleAllocatedBudgetLine = (event) => {
	try {
		const recordId = event.target.dataset.id;
		const value = event.target.value ? event.target.value : 0;
		const field = event.target.dataset.field;
		if (field) {
			const bl = context.budgetLine.cblight__ChildrenBudgetLines__r.find(bl => bl.Id === recordId);
			if (value != 0) {
				bl[field] = value;
				return null;
			}
			bl[field] = '';
		}
		context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
			line.cblight__CBAmounts__r.forEach(amount => {
				if (amount.Id === recordId) {
					amount.cblight__Value__c = value;
				}
			})
		});
		
		recalculatePercent();
		generateAllocationSummary();
	} catch (e) {
		_message('error', 'BLM: Allocation : Handle Allocated BL Error : ' + e);
	}
};
/**
 * Method recalculates amounts in subline according to its percents
 */
const handleAllocatedPercent = (event) => {
	const budgetLineId = event.target.name;
	const percent = event.target.value;
	const allocatedBL = context.budgetLine.cblight__ChildrenBudgetLines__r.find(line => line.Id === budgetLineId);
	allocatedBL.percent = percent;
	context.budgetLine.amountObject.wholeAmounts.forEach((amount, idx) => {
		allocatedBL.cblight__CBAmounts__r[idx].cblight__Value__c = amount.cblight__Value__c * percent;
	});
	calculateChildrenTotal();
	recalculatePercent();
	generateAllocationSummary();
};
/**
 * This method saves allocated budget lines
 */
const saveAllocatedBudgetLines = () => {
	const budgetLines = context.budgetLine.cblight__ChildrenBudgetLines__r;
	if (!budgetLines) return null;
	let amounts = [];
	budgetLines.forEach(bl => {
		_deleteFakeId(bl);
		_deleteFakeId(bl.cblight__CBAmounts__r);
		amounts.push(bl.cblight__CBAmounts__r);
		EXTRA_FIELDS_IN_BUDGET_LINE.forEach(f => delete bl[f]);
	});
	saveAllocatedBudgetLinesServer({budgetLines, amounts})
		.then(() => _message('success', 'Saved'))
		.catch(e => _parseServerError('BLM: Save Allocated Budgets Error : ', e));
};

/**
 * This method adds a new allocated budget line
 */
const addAllocatedBudgetLine = () => {
	try {
		const newAllocatedBudgetLine = _getCopy(context.budgetLine, true);
		delete newAllocatedBudgetLine.amountObject;
		newAllocatedBudgetLine.Name += ' Allocated';
		newAllocatedBudgetLine.cblight__isAllocation__c = false;
		newAllocatedBudgetLine.cblight__ParentBudgetLine__c = context.budgetLine.Id;
		newAllocatedBudgetLine.Id = _generateFakeId();
		newAllocatedBudgetLine.cblight__CBAmounts__r = _getCopy(context.budgetLine.amountObject.wholeAmounts, true);
		newAllocatedBudgetLine.cblight__CBAmounts__r.forEach(amount => {
			amount.cblight__CBBudgetLine__c = newAllocatedBudgetLine.Id;
		});
		newAllocatedBudgetLine.cblight__CBAmounts__r.forEach(a => a.Id = _generateFakeId());
		context.budgetLine.cblight__ChildrenBudgetLines__r.push(newAllocatedBudgetLine);
		indexAllocatedBudgetLines();
		calculateChildrenTotal();
		recalculatePercent();
		generateAllocationSummary();
	} catch (e) {
		_message('error', 'BLM : Allocation : Add Allocated BL Error : ' + e);
	}
};

/**
 * Bottom up mode populates parent budget line from allocated lines
 */
const fillInBudgetLineFromAllocation = () => {
	try {
		let budgetLineAmounts = context.budgetLine.amountObject.wholeAmounts;
		budgetLineAmounts.forEach(bla => bla.cblight__Value__c = 0);
		context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
			line.cblight__CBAmounts__r.forEach((a, i) => {
				budgetLineAmounts[i].cblight__Value__c += +a.cblight__Value__c;
			});
		});
		context.budgetLine.amountObject.calculateYearlyTotal();
		calculateChildrenTotal();
		recalculatePercent();
		generateAllocationSummary();
	} catch (e) {
		_message('error', 'BLM : Allocation : Fill In Budget Line From Allocated Lines Error : ' + e);
	}
};
/**
 * This method recalculates amounts in sublines according the source line
 */
const fillInAllocatedAmounts = () => {
	try {
		const displayedAmounts = context.budgetLine.amountObject.wholeAmounts;
		context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
			displayedAmounts.forEach((amount, idx) => {
				line.cblight__CBAmounts__r[idx].cblight__Value__c = amount.cblight__Value__c * line.percent;
			});
		});
		calculateChildrenTotal();
		generateAllocationSummary();
	} catch (e) {
		_message('error', 'BLM : Allocation : Fill In Allocated Amounts Error : ' + e);
	}
};



/**
 * This method deletes allocated budget line
 */
const deleteAllocatedLine = (blId) => {
	const updatedAllocationList = [];
	context.budgetLine.cblight__ChildrenBudgetLines__r.forEach(line => {
		if (line.Id === blId) return null;
		updatedAllocationList.push(line);
	});
	context.budgetLine.cblight__ChildrenBudgetLines__r = updatedAllocationList;
};
/////// HANDLERS ////////////////

export {
	getAllocatedBudgetLines,
	handleAllocatedBudgetLine,
	handleAllocatedPercent,
	saveAllocatedBudgetLines,
	addAllocatedBudgetLine,
	deleteAllocatedLine,
	fillInBudgetLineFromAllocation,
	fillInAllocatedAmounts,
	recalculateAllocationLine
};