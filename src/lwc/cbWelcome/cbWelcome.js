import {api, LightningElement, track} from "lwc";
import {_message, _parseServerError} from 'c/cbUtils';
import {NavigationMixin} from "lightning/navigation";
import getWelcomeServer from "@salesforce/apex/CBWelcomePageController.getWelcomeServer";

export default class CbWelcome extends NavigationMixin(LightningElement) {
	@api name; // welcome name
	@track welcome = {}; // welcome object
	@track showWelcome = false;
	@track showStartMode = true;
	@track selectedLine = {};

	connectedCallback() {
		this.getWelcome();
	}

	/**
	 * The method gets a welcome record with children
	 */
	getWelcome = () => {
		getWelcomeServer({recordName: this.name})
			.then(result => {
				this.welcome = result;
				this.showWelcome = true;
				this.showStartMode = true;
				setTimeout(() => {
					try {
						this.template.querySelectorAll(".mainContent")[0].innerHTML = this.welcome.cblight__Content__c;
					} catch (e) {
						_message('error', 'W : ST Show main message error : ' + e);
					}
				}, 100);
			})
			.catch(e => _parseServerError("W : Get Welcome Error : ", e));
	};

	/**
	 * Details mode
	 */
	showMessage = (event) => {
		try {
			this.selectedLine = this.welcome.cblight__CBWelcomes__r.find(item => item.Id === event.currentTarget.dataset.id);
			this.showStartMode = false;
			setTimeout(() => {
				try {
					this.template.querySelectorAll(".custom")[0].innerHTML = this.selectedLine.cblight__Content__c;
				} catch (e) {
					_message('error', 'W : ST Show message error : ' + e);
				}
			}, 100);
		} catch (e) {
			_message('error', 'W : Show message error : ' + e);
		}
	};

	/**
	 * Back to welcome home
	 */
	backToStartMode = () => {
		this.showWelcome = false;
		this.getWelcome();
	};

	redirectToCB = () => {
		const config = {
			type: 'standard__webPage',
			attributes: {
				url: 'http://cloudbudget.com'
			}
		};
		this[NavigationMixin.Navigate](config);
	};

	/**
	 * External event to close welcome modal window
	 */
	closeWelcome = () => {
		this.dispatchEvent(new CustomEvent("closeWelcome", {bubbles: true, composed: true}));
	}
}