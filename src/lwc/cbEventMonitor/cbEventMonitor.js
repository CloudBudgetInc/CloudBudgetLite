import {api, LightningElement, track} from "lwc";
import {onError, subscribe} from 'lightning/empApi';
import {_getCopy, _message} from "c/cbUtils";

export default class CbJobMonitor extends LightningElement {

	@track eventStack = [];
	@track showMonitor = false;
	@track status = {isProgress: false, isDone: false, isError: false};
	MAX_SIZE = 10;

	subscription = {};
	@api channelName = '/event/cblight__CBEvent__e';

	connectedCallback() {
		this.registerErrorListener();
		this.handleSubscribe();
	}

	reset = () => {
		this.status = {isProgress: false, isDone: false, isError: false};
		this.eventStack = [];
		this.showMonitor = false;
	};

	// Handles subscribe button click
	handleSubscribe = () => {
		// Callback invoked whenever a new event message is received
		const _this = this;
		const messageCallback = function (response) {
			let obj = _getCopy(response);
			let objData = obj.data.payload;
			if (!objData.cblight__Description__c || !objData.cblight__Status__c) return null;
			let eventStack = _getCopy(_this.eventStack);
			let currentDate = new Date();

			let status = {isProgress: false, isDone: false, isError: false};
			status.isDone = objData.cblight__Status__c === 'DONE';
			status.isProgress = objData.cblight__Status__c === 'PROGRESS';
			status.isError = objData.cblight__Status__c === 'ERROR';
			_this.status = status;

			let newEvent = {
				date: currentDate.getDate() + "/"
					+ (currentDate.getMonth() + 1) + "/"
					+ currentDate.getFullYear() + " @ "
					+ currentDate.getHours() + ":"
					+ currentDate.getMinutes() + ":"
					+ currentDate.getSeconds(),
				message: objData.cblight__Description__c,
				class: objData.cblight__Status__c
			};
			if (eventStack.length >= _this.MAX_SIZE) eventStack.shift();
			eventStack.push(newEvent);
			_this.eventStack = eventStack;
			_this.showMonitor = true;
			if (status.isDone) _message('success', objData.cblight__Description__c);
			//if (status.isProgress) _message('info', objData.cblight__Description__c);
			if (status.isError) _message('error', objData.cblight__Description__c);

		};

		// Invoke subscribe method of empApi. Pass reference to messageCallback
		subscribe(this.channelName, -1, messageCallback)
			.then(response => {
				// Response contains the subscription information on subscribe call
				console.log('Subscription request sent to: ', JSON.stringify(response.channel));
				this.subscription = response;
			});
	};

	//handle Error
	registerErrorListener = () => {
		onError(error => {
			console.log('Received error from server: ', JSON.stringify(error));
		});
	};

	/**
	 * this function redirects to apex jobs page in the new window
	 */
	redirectToApexJobs() {
		let win = window.open('/apexpages/setup/listAsyncApexJobs.apexp', '_blank');
		win.focus();
	};

}