import { LightningElement, api } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {_message, _parseServerError, _cl} from "c/cbUtils";
import getFilteredNFLServer from '@salesforce/apex/CBNFLSelectorPageController.getFilteredNFLServer';
import getLatestNFLServer from '@salesforce/apex/CBNFLSelectorPageController.getLatestNFLServer';
import { passEditableToNFLItems } from 'c/cbBudgetLineModal';

export default class CbNflSelector extends NavigationMixin(LightningElement)  {
	showSpinner = false;
	MIN_NUMBER_OF_CHARS_FOR_SEARCH = 3;
	NUMBER_OF_NFL_TO_LOAD = 10;
	loadButtonMessage = 'Load latest ' + this.NUMBER_OF_NFL_TO_LOAD + ' NFL\'s';
	amountOfNFLToLoad;
	listToShow = [];
	filterString;
	@api layer;

	connectedCallback() {
		this.doInit();
	}

	doInit() {
		let orgVariable = JSON.parse(localStorage.getItem('orgVariable'));
		if (orgVariable) {
			if (orgVariable.cblight__NFLDefaultListSize__c && !isNaN(orgVariable.cblight__NFLDefaultListSize__c)) {
				this.NUMBER_OF_NFL_TO_LOAD = orgVariable.cblight__NFLDefaultListSize__c;
			}
		}
		this.listToShow = this.getFreshList();
	}
	/**
	 * loads latest NFL's
	 */
	@api loadLatestNFL() {
		this.showSpinner = true;
		const layer = this.layer;
		const amount = this.NUMBER_OF_NFL_TO_LOAD;

		getLatestNFLServer({layer, amount}).then((latestList) => {
			if (latestList.length === 0) {
				_message('success', 'No NFL\'s to load');
			}
			this.listToShow = [...this.getFreshList(), ...latestList];
		}).catch((e) => {
			_parseServerError("NFL Selector search error : ", e);
		}).finally(() => {
			this.showSpinner = false;
		});
	}

	/**
	 * 
	 * @returns returns empty list with custom NFL
	 */
	getFreshList() {
		let listToShow = [];
		listToShow.push({ // CUSTOM NFL as the first item in the list
			Id: this.layer.Id,
			cblight__Unit__c: this.layer.cblight__Unit__c,
			Name: 'Custom NFL',
			cblight__LayerTitle__c: this.layer.Name
		});
		return listToShow;
	}

	/**
	 * if entered filter string is bigger or equals then expected - returns list of the filtered objects
	 * @param {*} event event from changed filter
	 */
	handleFilterChange = (event) => {
		const filterString = event.target.value;
		const layer = this.layer;
		if (filterString.length >= this.MIN_NUMBER_OF_CHARS_FOR_SEARCH) {
			this.showSpinner = true;
			getFilteredNFLServer({filterString, layer})
				.then((listToShow) => {
					try {
						passEditableToNFLItems(listToShow);
					} catch(e) {
						console.error(e);
					}
					this.listToShow = [...this.getFreshList(), ...listToShow];
				})
				.catch(e => _parseServerError("NFL Selector search error : ", e))
				.finally(() => this.showSpinner = false);
		}
	};

	/**
	 * redirects to selected NFL
	 * @param {*} event 
	 */
	redirectToNFL(event) {
		try {
			this[NavigationMixin.GenerateUrl]({
				type: 'standard__recordPage',
				attributes: {
					recordId: event.target.value,
					objectApiName: 'cblight__CBNonFinancialLibrary__c',
					actionName: 'view'
				}
			}).then(url => {
				window.open(url, "_blank");
			});
		} catch (e) {
			_message('error', 'BLM : Redirect to NFL Error : ' + e);
		}
	}

	passToLegend(event) {
		const label = event.target.label;
		const line = JSON.stringify(event.target.value);
		const layer = this.layer;
		const detail = {line, label, layer};
		const evt = new CustomEvent("lineclicked", {detail: detail});
		this.dispatchEvent(evt);
	}

	drag(event) {
		try {
			const line = JSON.stringify(event.target.value);
			const detail = {line};
			const evt = new CustomEvent("linedragged", {detail: detail});
			this.dispatchEvent(evt);
		} catch(e) {
			_message('error', 'drag Error : ' + e);
		}
	}
}