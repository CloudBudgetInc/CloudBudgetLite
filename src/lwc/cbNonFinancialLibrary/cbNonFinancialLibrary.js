import {api, LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getNonFinLibraryServer from "@salesforce/apex/CBNonFinancialLibraryPageController.getNonFinLibraryServer";
import getPeriodsServer from "@salesforce/apex/CBNonFinancialLibraryPageController.getAllPeriodsServer";
import saveNonFinancialLibServer from "@salesforce/apex/CBNonFinancialLibraryPageController.saveNonFinancialLibServer";
import {_applyDecStyle, _deleteFakeId, _generateFakeId, _getCopy, _message, _parseServerError, _cl} from 'c/cbUtils';

export default class CbNonFinancialLibrary extends LightningElement {

	@api recordId; // render children clusters if needed
	@track library = {}; // selected library
	@track BYLines = []; // lines under library
	@track BYLinesStorage = []; // js class copy of rendered BYLines to prevent rerender after each change
	@track originalItems = []; // original NFL items to compare them with changed before save
	@track showSpinner = false;
	@track showCompleteAssistant = false;
	@track inputTypeRender = {}; // render rule to display one of input type

	connectedCallback() {
		this.getExistingPeriods();
		_applyDecStyle();
	}

	/**
	 * Method gets existing periods form server to generate lines for each budget year
	 */
	getExistingPeriods() {
		getPeriodsServer()
			.then(periods => {
				if (!periods || periods.length === 0) {
					this.runToast('Warning', 'Setup periods for the org before creating a non-financial lib', 'warning');
					return null;
				}
				this.getNonFinancialLib();
				this.BYLines = this.generateBYLines(periods);
			})
			.catch(e => alert('GET LIB ERROR ' + e))
	}

	/**
	 * Method takes selected Non Fin Lib from server
	 */
	getNonFinancialLib() {
		getNonFinLibraryServer({recordId: this.recordId})
			.then(lib => {
				this.library = lib;
				this.setInputTypeRender();
				this.originalItems = lib.cblight__NonFinancialItems__r;
				this.updateBYLinesWithItems();
				this.BYLinesStorage = _getCopy(this.BYLines);
				this.showCompleteAssistant = true;
			})
			.catch(e => _parseServerError('NFL : Get Lib Error :  ', e))
	}

	/**
	 * Method manages that type of data inputs must display
	 */
	setInputTypeRender() {
		this.inputTypeRender.isItems = this.library.cblight__Unit__c === 'items';
		this.inputTypeRender.isCurrency = this.library.cblight__Unit__c === 'currency';
		this.inputTypeRender.isPercent = this.library.cblight__Unit__c === 'percent';
	}

	/**
	 * The method populates items to BYLines
	 */
	updateBYLinesWithItems() {
		try {
			const itemMap = !this.library.cblight__NonFinancialItems__r ? {} : this.library.cblight__NonFinancialItems__r.reduce((map, item) => {
				map[item.cblight__CBPeriod__c] = item;
				return map;
			}, {});
			let BYLines = _getCopy(this.BYLines);
			BYLines.forEach(BYLine => {
				BYLine.items = [];
				BYLine.periods.forEach(period => {
					let item = itemMap[period.Id];
					if (!item) {
						item = {
							cblight__CBPeriod__c: period.Id,
							cblight__Value__c: 0,
							cblight__NonFinancialLibrary__c: this.library.Id,
							Id: _generateFakeId()
						};
					}
					item.cblight__PeriodName__c = period.Name;
					BYLine.items.push(_getCopy(item));
				})
			});
			this.BYLines = BYLines;
		} catch (e) {
			_message('error', 'NFL : Update BY Lines With Items Error: ' + e);
		}
	}

	/**
	 * Service method generates lines for each budget year
	 */
	generateBYLines(periods) {
		try {
			const BYLineMap = {};
			periods.forEach(p => {
				let BYL = BYLineMap[p.cblight__CBBudgetYear__c];
				if (!BYL) {
					BYL = new BYLine(p.cblight__CBBudgetYear__r);
					BYLineMap[p.cblight__CBBudgetYear__c] = BYL;
				}
				BYL.periods.push(p);
			});
			return Object.values(BYLineMap);
		} catch (e) {
			_message('error', 'NFL : Generate BY Lines Error: ' + e);
		}
	}

	/**
	 * Method saves current Non Fin Lib
	 */
	saveNonFinancialLib() {
		this.showSpinner = true;
		let items = [];
		this.BYLinesStorage.forEach(BYLine => _deleteFakeId(BYLine.items));
		this.BYLinesStorage.forEach(BYLine => items = [...items, ...BYLine.items]);
		const revisionDescriptionArray = this.getRevisionDescription(items);
		saveNonFinancialLibServer({library: this.library, items})
			.then(() => {
				this.runToast('Success', 'Saved', 'success');
				this.getExistingPeriods();
			})
			.catch(e => _parseServerError('NFL : Save Non Financial Lib Error: ', e))
			.finally(() => this.showSpinner = false);
	}

	/**
	 * The method returns description for revision
	 */
	getRevisionDescription(items) {
		try {
			if (!this.originalItems || this.originalItems.length === 0) {
				return ['Non-financial library created'];
			}
			let r = [];
			items.forEach(newItem => {
				const oldItem = this.originalItems.find(i => i.Id === newItem.Id);
				if (!oldItem) {
					r.push(`${newItem.cblight__PeriodName__c}:${newItem.cblight__Value__c} `);
					return null;
				}
				if (+newItem.cblight__Value__c !== +oldItem.cblight__Value__c) {
					r.push(`In "${newItem.cblight__PeriodName__c}" amount ${oldItem.cblight__Value__c} changed to ${newItem.cblight__Value__c}`);
				}
			});
			r = r.length === 0 ? ['No changes'] : r;
			return r;
		} catch (e) {
			_message('error', 'NFL : Get Revision Description Error: ' + e);
		}
	}

	/**
	 * Handler onchange event for library inputs
	 */
	handleLibChange(event) {
		try {
			this.library[event.target.name] = event.target.value;
		} catch (e) {
			_message('error', 'NFL : Handle Library Change Error: ' + e);
		}
	}


	/**
	 * Handler onchange event for amounts input
	 */
	handleAmountChange(event) {
		try {
			const itemId = event.target.name;
			this.BYLinesStorage.forEach(BYLine => {
				BYLine.items.forEach(item => {
					if (item.Id === itemId) {
						item.cblight__Value__c = +(event.target.value) ? event.target.value : 0;
					}
				})
			});
		} catch (e) {
			_message('error', 'NFL : Handle Amount Change Error: ' + e);
		}
	}

	/**
	 * The method receives data from the CompleteAssistant component and apply them
	 */
	applyCompleteAmounts = (event) => {
		try {
			let BYLinesStorage = _getCopy(this.BYLinesStorage);
			BYLinesStorage.forEach(BYLine => {
				BYLine.items.forEach(i => {
					const updatedItem = event.detail.amounts.find(a => a.Id === i.Id);
					i.cblight__Value__c = updatedItem ? updatedItem.cblight__Value__c : i.cblight__Value__c;
				});
			});
			this.BYLinesStorage = BYLinesStorage;
			this.showSpinner = true;
			this.saveNonFinancialLib();
		} catch (e) {
			_message('error', 'NFL : Apply Complete Amounts Error : ' + e);
		}
	};

	/**
	 * Method runs a toast
	 */
	runToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({
			title,
			message,
			variant
		}));
	}

	constructor() {
		super();
		this.addEventListener('restoreData', this.restoreData); // Listener from the Revision component
	}

	/**
	 * Setting single value from input
	 */
	setSingleValue(event) {
		this.library.cblight__SingleValue__c = +event.target.value;
	}

	/**
	 *Setting single value from input to all items
	 */
	populateItemsWithSingleValue() {
		try {
			this.BYLines.forEach(BYLine => {
				BYLine.items.forEach(item => item.cblight__Value__c = this.library.cblight__SingleValue__c);
			});
			this.BYLinesStorage = _getCopy(this.BYLines);
		} catch (e) {
			_message('error', 'NFL : Error Filling All Amounts: ' + e);
		}
	}

	/**
	 * External method form the Restore Data component
	 */
	restoreData = (event) => {
		try {
			this.library.cblight__NonFinancialItems__r = JSON.parse(event.detail);
			this.updateBYLinesWithItems();
			this.BYLinesStorage = _getCopy(this.BYLines);
		} catch (e) {
			_message('error', 'NFL : Restore NFL Data Error: ' + e);
		}
	};
}

/**
 * Wrapper for a line
 */
function BYLine(budgetYear) {
	this.BY = budgetYear;
	this.periods = [];
	this.items = [];
}