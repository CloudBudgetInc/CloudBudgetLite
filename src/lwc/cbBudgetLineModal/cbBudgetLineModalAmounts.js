/**displayedAmounts
 * Library for populating and managing amount and NFL lines to budget line
 */
import {_generateFakeId, _message} from 'c/cbUtils';

let context; // this from parent
/**
 * All lines stores in special class called Amounts. This method populated Amounts object to display on the screen
 */
const getProcessedAmounts = (_this) => {
	try {
		context = _this;
		const amountObject = new Amounts(context.budgetLine.cblight__CBAmounts__r, context.displayGroupId);
		amountObject.wholeAmounts = amountObject.addLostPeriodItemsToSelectedBY(amountObject.wholeAmounts, context.budgetLine.Id);
		amountObject.setNFLibs();
		amountObject.wholeNFLibs.forEach(itemArray => {
			amountObject.displayedNFLibs.push(amountObject.setDisplayedItems(itemArray));
		});
		if (amountObject.displayedNFLibs.length > 0) {
			amountObject.calculateAmountsFromNFLibs();
		}
		amountObject.calculateYearlyTotal();
		amountObject.disableAmounts();
		return amountObject;
	} catch (e) {
		_message('error', 'BLM Amounts: Get Processed Amounts Error: ' + e);
	}
};

/**
 * Special class to manage amounts
 * @param amounts
 * @param displayGroupId
 * @constructor
 */
function Amounts(amounts, displayGroupId) {
	this.title = 'test';
	this.titles = [];
	this.displayGroupId = displayGroupId;
	this.wholeAmounts = amounts; // all currency budget line amounts
	//this.displayedAmounts = []; // [{},{}] // main currency amounts for the budget line displayed in selected BY
	this.wholeNFLibs = []; // [[{},{}],[{},{}]]
	this.displayedNFLibs = []; // [[{},{}],[{},{}]]

	/**
	 * Budget line amounts split by budget year
	 * This function filters only needed amounts that must be displayed
	 */
	this.setDisplayedItems = (wholeList) => {
		try {
			if (!wholeList) return null;
			return wholeList.filter(a => displayGroupId.startsWith(a.cblight__CBBudgetYear__c) || displayGroupId.startsWith(a.cblight__CBBudgetYearSet__c));
		} catch (e) {
			_message('error', 'BLM Utils: Set Display Items Error ' + e);
		}
	};

	/**
	 * This function adds new items if list is not full
	 */
	this.addLostPeriodItemsToSelectedBY = (listOfItems, parentId) => {
		try {
			let updatedList = []; // result array
			if (context.periods.length === listOfItems.length) return listOfItems; // list does not have lost periods
			context.periods.forEach(period => {
				let item = listOfItems.find(i => i.cblight__CBPeriod__c === period.Id);
				if (!item && (displayGroupId.startsWith(period.cblight__CBBudgetYear__c) || displayGroupId.startsWith(period.cblight__CBBudgetYearSet__c))) {
					item = {
						cblight__Value__c: 0,
						cblight__CBPeriod__c: period.Id,
						cblight__CBBudgetYear__c: period.cblight__CBBudgetYear__c,
						cblight__CBBudgetYearSet__c: period.cblight__CBBudgetYearSet__c,
						cblight__PeriodName__c: period.Name,
						cblight__CBBudgetLine__c: parentId, // in case id it is CBAmount
						cblight__NonFinancialLibrary__c: parentId, // in case id it is NFL Item
						Id: _generateFakeId()
					};
				}
				if (!item) return null;
				updatedList.push(item);
			});
			return updatedList;
		} catch (e) {
			_message('error', 'BLM Utils: Add Lost Period Items Error ' + e);
		}
	};

	/**
	 * The method takes data from NFL libraries and populates to Amount object
	 */
	this.setNFLibs = () => {
		try {
			this.titles = ['Result'];
			[1, 2, 3, 4, 5].forEach(index => {
				const NFLId = context.budgetLine[`cblight__NFL${index}__c`];
				if (NFLId) {
					this.titles.push(context.budgetLine[`cblight__NFLTitle${index}__c`]);
					let NFLLine = getSelectedLine(NFLId);
					if (NFLLine) {
						passUnitToEachItem(NFLLine);
						this.wholeNFLibs.push(NFLLine.cblight__NonFinancialItems__r);
					}
				}
			});
		} catch (e) {
			_message('error', 'BLM Amounts : Set NFL Libs Error: ' + e);
		}
	};

	/**
	 * Calculating yearly total for the budget line
	 */
	this.calculateYearlyTotal = () => {
		try {
			let total = 0;
			this.wholeAmounts.forEach(amount => total += amount.cblight__Value__c ? +amount.cblight__Value__c : 0);
			context.budgetLine.yearlyTotal = total;
		} catch (e) {
			_message('error', 'BLM Amounts : Calculate Yearly Total Error: ' + e);
		}
	};

	this.disableAmounts = () => {
		try {
			const disabledByBL = context.budgetLine.cblight__isFormulaBudgetLine__c || context.budgetLine.cblight__Lock__c === 'Editing';
			this.wholeAmounts.forEach(amount => amount.disabled = disabledByBL || amount.cblight__CBStyleName__c);
		} catch (e) {
			_message('error', 'BLM Amounts : Disable Amounts Error: ' + e);
		}
	};

	/**
	 * Calculating the main total of the budget line
	 */
	this.getGlobalBLTotal = () => {
		try {
			let total = 0;
			this.wholeAmounts.forEach(amount => total += amount.cblight__Value__c ? +amount.cblight__Value__c : 0);
			return +total;
		} catch (e) {
			_message('error', 'BLM Amounts : Calculate Global Total Error: ' + e);
		}
	};

	/**
	 * Calculating amounts from NFL libs for budget line with "formula" type
	 */
	this.calculateAmountsFromNFLibs = () => {
		try {
			if (!context.budgetLine.cblight__isFormulaBudgetLine__c) {
				return null;
			}
			const {cblight__NFLFormula__c} = context.budgetLine;
			for (let i = 0; i < this.wholeAmounts.length; i++) { // iterate over amounts. i = index of amount (0 ... 11)
				try {
					let valueFormula = cblight__NFLFormula__c;
					for (let k = 1; k <= 5; k++) {
						const nflKey = `#${k}`;
						if (!valueFormula.includes(nflKey)) {
							continue;
						}
						const nflLine = this.displayedNFLibs[k - 1];
						const nflValue = nflLine ? nflLine[i].cblight__Value__c : 0;
						valueFormula = valueFormula.replace(new RegExp(nflKey, 'g'), nflValue);
					}
					let calculatedValue = Function("return " + valueFormula)();
					calculatedValue = calculatedValue.toFixed(2);
					let value = parseFloat(calculatedValue);
					if (!isFinite(value)) {
						value = 0;
						_message('warning', 'Please do not allow empty cells and division by zero. Review the formula or values included in the calculation');
					}
					this.wholeAmounts[i].cblight__Value__c = value;
				} catch (e) {
					_message('error', 'BLM Amounts : Calculate Amounts Iteration Error : ' + e);
				}
			}
		} catch (e) {
			_message('error', 'BLM Amounts : Calculate Formula Amounts Error : ' + e);
		}
	};

	/**
	 *
	 * @param amountId id of needed amount
	 * @param value new value of this amount
	 */
	this.applyNewValue = (amountId, value) => {
		try {
			let wholeDisplayedAmounts = [];
			if (this.displayedNFLibs && this.displayedNFLibs.length > 0) {
				this.displayedNFLibs.forEach(nflArray => {
					wholeDisplayedAmounts = [...wholeDisplayedAmounts, ...nflArray];
				})
			}
			wholeDisplayedAmounts = [...wholeDisplayedAmounts, ...this.wholeAmounts];
			let amount = wholeDisplayedAmounts.find(amount => amount.Id === amountId);
			amount.cblight__Value__c = parseFloat(value);

			let nflMapItem;
			Object.keys(context.NFLMap).forEach(key => {
				const NFL = context.NFLMap[key];
				NFL.cblight__NonFinancialItems__r.forEach(item => {
					if (item.Id === amountId) {
						nflMapItem = item;
					}
				});
			});
		} catch (e) {
			_message('error', 'BLM Amounts : Apply New Value Error : ' + e);
		}
	};
}

const passUnitToEachItem = NFLLine => {
	try {
		if (!NFLLine || !NFLLine.cblight__NonFinancialItems__r) return;
		NFLLine.cblight__NonFinancialItems__r.forEach(a => {
			switch (NFLLine.cblight__Unit__c) {
				case 'items':
					a.isItem = true;
					break;
				case 'percent':
					a.isPercent = true;
					break;
				case 'currency':
					a.isCurrency = true;
					break;
				default:
					a.isItem = true;
			}
		});
	} catch (e) {
		_message('error', 'BLM Amount : Pass Unit to Each Amount Issue Error: ' + e);
	}
};

/**
 * Utility method to get needed NFL from NFL catalog
 */
const getSelectedLine = lineId => {
	try {
		return context.NFLMap[lineId];
	} catch (e) {
		_message('error', 'BLM Amounts : Get Selected Line Error : ' + e);
	}
};


export {getProcessedAmounts};