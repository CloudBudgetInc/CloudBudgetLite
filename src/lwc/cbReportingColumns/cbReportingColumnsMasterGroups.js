import {_generateFakeId, _getCopy} from 'c/cbUtils';

const FORMULA_COLUMNS_EXTRA_FIELDS = ['cblight__CBPeriod__c', 'cblight__ValueField__c'];
/**
 * @param columns indexed columns. Starts from 1
 */
const enumerateColumns = (columns) => {
	columns.forEach((col, idx) => col.cblight__OrderNumber__c = idx + 1);
};
/**
 * @param columns existing report columns
 * @param periodsAll list of all CBPeriods in cblight__Start__c order
 * @param needQuarters true if it is quarter mode
 * @param styles list of CBStyles
 * @returns *[] of autogenerated simple columns
 */
const getClonedMasterGroup = (columns, periodsAll, needQuarters, styles) => {
	try {
		const linkedPeriodMap = getLinkedPeriodMap(periodsAll);
		let masterColumns = columns.filter(c => c.cblight__Type__c === 'Master');
		let updatedColumns = [...masterColumns];
		let columnGroup = getColumnGroupCopy(masterColumns, true); // first group in the next iteration is master columns
		for (let i = 0; i < 11; i++) { // TODO Check quarter mode
			columnGroup = getColumnGroupCopy(columnGroup, false);
			columnGroup.forEach(col => {
				if (col.cblight__CBPeriod__c === undefined) return null; // formula fields
				col.cblight__CBPeriod__c = linkedPeriodMap[col.cblight__CBPeriod__c]; // set the next period
			});
			updatedColumns = [...updatedColumns, ...columnGroup];
		}
		enumerateColumns(updatedColumns);
		updatedColumns = addQuarterColumns(masterColumns, updatedColumns, needQuarters);
		updatedColumns = addTotalColumns(masterColumns, updatedColumns, needQuarters);
		updatedColumns = addStyles(updatedColumns, styles);
		enumerateColumns(updatedColumns);
		return updatedColumns;
	} catch (e) {
		alert('Clone Master Group Error ' + e);
	}
};

const addQuarterColumns = (masterColumns, allColumns, needQuarters) => {
	try {
		if (!needQuarters) {
			return allColumns;
		}
		const groupSize = masterColumns.length * 3;
		let splitByQuarters = allColumns.reduce((res, column, idx) => {
			let subGroup = res[Math.floor(idx / groupSize)];
			if (subGroup === undefined) {
				subGroup = [];
				res.push(subGroup);
			}
			subGroup.push(column);
			return res;
		}, []);
		splitByQuarters = splitByQuarters.map((oneQuarterColumns, qIdx) => {
			let updatedQuarterColumns = [...oneQuarterColumns], newQuarterColumn;
			masterColumns.forEach(mCol => {
				const formula = [];
				oneQuarterColumns.forEach((c, i) => {
					if (c.Id === mCol.Id || c.cblight__MasterColumn__c === mCol.Id) {
						formula.push(`#${c.cblight__OrderNumber__c}`);
					}
				});
				newQuarterColumn = _getCopy(mCol, true);
				newQuarterColumn.Name = `Q${qIdx + 1} ${newQuarterColumn.Name}`;
				newQuarterColumn.cblight__Type__c = 'Simple';
				newQuarterColumn.isQuarter = true;
				newQuarterColumn.cblight__MasterColumn__c = mCol.Id;
				newQuarterColumn.cblight__Formula__c = formula.join(' + ');
				FORMULA_COLUMNS_EXTRA_FIELDS.forEach(f => delete newQuarterColumn[f]);
				updatedQuarterColumns.push(newQuarterColumn);
			});
			return updatedQuarterColumns;
		});
		return splitByQuarters.reduce((res, currGroup) => [...res, ...currGroup], []);
	} catch (e) {
		alert('Add Quarter Columns Error: ' + e);
	}
};

/**
 * Budget Year total columns with formulas made automatically from the master columns
 */
const addTotalColumns = (masterColumns, allColumns, needQuarters) => {
	try {
		let totalColumns = [];
		masterColumns.forEach(mCol => {
			let formula = [];
			allColumns.forEach((c, i) => {
				console.log('c.cblight__MasterColumn__c = ' + c.cblight__MasterColumn__c + ' AND mCol.Id= ' + mCol.Id);
				if (c.Id === mCol.Id || c.cblight__MasterColumn__c === mCol.Id) {
					/*if ((needQuarters && c.isQuarter) || !needQuarters) {
						formula.push(`#${i + 1}`);
					}*/

					formula.push(`#${i + 1}`);

				}
			});
			let newTotalColumn = _getCopy(mCol, true);
			newTotalColumn.Name = newTotalColumn.Name + ' Total';
			newTotalColumn.cblight__Type__c = 'Simple';
			newTotalColumn.isTotal = true;
			newTotalColumn.Id = _generateFakeId();
			newTotalColumn.cblight__MasterColumn__c = mCol.Id;
			newTotalColumn.cblight__Formula__c = formula.join(' + ');
			FORMULA_COLUMNS_EXTRA_FIELDS.forEach(f => delete newTotalColumn[f]);
			totalColumns.push(newTotalColumn);
		});
		return [...allColumns, ...totalColumns];
	} catch (e) {
		alert('Get Total Columns Error:' + e);
	}
};

/**
 * The method creates copy of the master group columns
 */
const getColumnGroupCopy = (baseColumns, isMaster) => {
	try {
		const r = [];
		baseColumns.forEach(mCol => {
			const newCol = _getCopy(mCol, true);
			newCol.Id = _generateFakeId();
			newCol.cblight__MasterColumn__c = isMaster ? mCol.Id : newCol.cblight__MasterColumn__c;
			newCol.cblight__Type__c = 'Simple';
			r.push(newCol);
		});
		return r;
	} catch (e) {
		alert('Get Column Group Copy Error: ' + e);
	}
};

const addStyles = (updatedColumns, styles) => {
	try {
		const totalStyle = styles.find(s => s.Name === 'Total Column');
		const quarterStyle = styles.find(s => s.Name === 'Quarter Column');
		return updatedColumns.map(col => {
			if (col.isTotal) {
				col.cblight__CBStyle__c = totalStyle ? totalStyle.Id : '';
			} else if (col.isQuarter) {
				col.cblight__CBStyle__c = quarterStyle ? quarterStyle.Id : '';
			}
			return col;
		});
	} catch (e) {
		alert('Reporting Columns Master Groups : Add Styles Error : ' + e);
	}
};

/**
 * Map where key is Period Id and value is the next period Id
 */
const getLinkedPeriodMap = (allPeriods) => {
	try {
		let linkedMap = {};
		allPeriods.forEach((item, idx) => {
			if (idx + 1 === allPeriods.length) return null;
			linkedMap[item.Id] = allPeriods[idx + 1].Id;
		});
		return linkedMap;
	} catch (e) {
		alert('Get Linked Period Map Error: ' + e);
	}
};

//////////////////// PRIVATE METHODS ////////////////////

export {getClonedMasterGroup, enumerateColumns};