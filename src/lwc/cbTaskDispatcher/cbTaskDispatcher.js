import {api, LightningElement, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import runQueueServer from '@salesforce/apex/CBTaskDispatcherPageController.runQueueServer';
import validateQueueServer from '@salesforce/apex/CBTaskDispatcherPageController.validateQueueServer';
import getQueueStatisticServer from '@salesforce/apex/CBTaskDispatcherPageController.getQueueStatisticServer';
import resetTaskQueueServer from '@salesforce/apex/CBTaskDispatcherPageController.resetTaskQueueServer';
import {_isInvalid, _message} from 'c/cbUtils';

export default class CbTaskDispatcher extends LightningElement {

	@api recordId;
	@track messages;
	@track logs;

	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		this.getStatisticQueue();
		document.title = 'Task Dispatcher';
	}

	/**
	 * this function runs opened queue
	 */
	runQueue() {
		try {
			let taskQueueId = this.recordId;
			runQueueServer({taskQueueId})
				.then(() => {
					const event = new ShowToastEvent({
						title: 'Run Queue',
						message: 'Success',
						variant: 'success',
						mode: 'dismissable'
					});
					this.dispatchEvent(event);
					setTimeout(() => {
						this.getStatisticQueue();
					}, 2000);

				})
				.catch(error => {
					alert('error = ' + JSON.stringify(error));
				});
		} catch (e) {
			alert("Run Queue Error:" + e);
		}
	}

	/**
	 * this function validates the queue on server using ancient magic
	 */
	validateQueue() {
		let taskQueueId = this.recordId;
		validateQueueServer({taskQueueId})
			.then(result => {
				this.messages = result;
				if (_isInvalid(result) || result.length < 1) {
					const event = new ShowToastEvent({
						title: 'Task Queue is valid',
						message: 'Success',
						variant: 'success',
						mode: 'dismissable'
					});
					this.dispatchEvent(event);
				}

			})
			.catch(e => alert('Validate Queue Error: ' + JSON.stringify(e)));
	}

	/**
	 * this function gets the statistic for current queue
	 */
	getStatisticQueue() {
		let taskQueueId = this.recordId;
		getQueueStatisticServer({taskQueueId})
			.then(result => {
				this.logs = result;
			})
			.catch(e => alert('Validation Error: ' + e));
	}

	/**
	 * this function redirects to apex jobs page in the new window
	 */
	redirectToApexJobs() {
		let win = window.open('/apexpages/setup/listAsyncApexJobs.apexp', '_blank');
		win.focus();
	};

	/**
	 * Method resets the task queue and its tasks
	 */
	resetTaskQueue = () => {
		resetTaskQueueServer({taskQueueId: this.recordId})
			.then(() => {
				_message('success', 'Done');
				location.reload();
			});
	};
}