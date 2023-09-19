import {api, LightningElement, track} from "lwc";
import {onError, subscribe} from 'lightning/empApi';
import getTaskQueuesServer from "@salesforce/apex/CBTaskDispatcherPageController.getTaskQueuesServer";
import saveTaskQueueAndTasksServer from "@salesforce/apex/CBTaskDispatcherPageController.saveTaskQueueAndTasksServer";
import deleteTaskQueueServer from "@salesforce/apex/CBTaskDispatcherPageController.deleteTaskQueueServer";
import resetTaskQueueServer from "@salesforce/apex/CBTaskDispatcherPageController.resetTaskQueueServer";
import getProcessClassesSOServer from "@salesforce/apex/CBTaskDispatcherPageController.getProcessClassesSOServer";
import {_getCopy, _message, _parseServerError} from 'c/cbUtils';
import {CbTaskQueueSetupMerge} from './cbTaskQueueSetupMerge';

export default class CbTaskQueueSetup extends LightningElement {
	@api recordId; // render clusters rule details if modified
	@track taskQueues = [];
	@track showSpinner = false;
	@track showContent = false;
	@track showTaskQueueDialog = false;
	@track showCombineDialog = false;
	@track selectedTaskQueue;
	@track selectedForCombiningTQ = [];
	@track classSO = [];
	taskQueueSetupMerge;
	subscription = {};
	@api channelName = '/event/cblight__CBEvent__e';

	get combineOptions() {
		return this.taskQueues.map(tq => {
			return {label: tq.Name, value: tq.Id};
		});
	}

	connectedCallback() {
		this.getTaskQueues();
		this.getClassNameSO();
		this.taskQueueSetupMerge = new CbTaskQueueSetupMerge(this);
		this.registerErrorListener();
		this.handleSubscribe();
	}

	getClassNameSO = () => {
		getProcessClassesSOServer()
			.then(so => this.classSO = so)
			.catch(e => _parseServerError("TQS : Get Task Queues Error: ", e))
	};

	/*
	 * getClusterRules method download  Cluster Rule from server
	 */
	getTaskQueues = (smoothRender) => {
		if (!smoothRender) {
			this.showContent = false;
			this.showSpinner = true;
			this.showCombineDialog = false;
		}
		getTaskQueuesServer()
			.then(taskQueues => {
				try {
					taskQueues.forEach(tq => tq.isActive = tq.cblight__Status__c === 'Active');
					taskQueues.forEach(tq => {
						if (!tq.cblight__CB_Tasks__r) return;
						tq.cblight__CB_Tasks__r.forEach(t => {
							t.isActive = t.cblight__Status__c === 'Active';
							t.isIdle = t.cblight__Status__c === 'Idle';
							t.isDone = t.cblight__Status__c === 'Done';
						})
					});
					this.taskQueues = taskQueues;
					this.showContent = true;
					if (this.selectedTaskQueue?.Id) this.editTaskQueue({target: {value: this.selectedTaskQueue.Id}});
				} catch (e) {
					_message('error', 'TQS : Get Task Order Callback Error : ' + e);
				}
			})
			.catch(e => _parseServerError("TQS : Get Task Queues Error: ", e))
			.finally(() => this.showSpinner = false);
	};

	/**
	 * Method adds a new task queue
	 */
	addTaskQueue = () => {
		console.clear();
		this.selectedTaskQueue = {
			cblight__CB_Tasks__r: [],
			Name: 'New'
		};
		this.saveTaskQueue(this.selectedTaskQueue);
	};

	/**
	 * Method adds a new task to the task queue dialog
	 */
	addTask = () => {
		if (!this.selectedTaskQueue.cblight__CB_Tasks__r) this.selectedTaskQueue.cblight__CB_Tasks__r = [];
		const newTask = {
			Name: 'New',
			cblight__OrderNumber__c: this.selectedTaskQueue.cblight__CB_Tasks__r.length + 1,
			cblight__CBTaskQueue__c: this.selectedTaskQueue.Id
		};
		this.selectedTaskQueue.cblight__CB_Tasks__r.push(newTask);
		this.saveTaskQueue(this.selectedTaskQueue);
	};

	/**
	 * Method finds and open selected task queue in a dialog window
	 */
	editTaskQueue = (event) => {
		try {
			this.selectedTaskQueue = this.taskQueues.find(tq => tq.Id === event.target.value);
			this.showTaskQueueDialog = true;
		} catch (e) {
			_message('error', "TQS : Edit Task Queue Error: " + e);
		}
	};

	/**
	 * Handle to change task queue
	 */
	handleChangeTQ = (event) => {
		this.selectedTaskQueue[event.target.name] = event.target.value;
	};

	/**
	 * Handle to change task in list of tasks
	 */
	handleChangeTask = (event) => {
		const {label, name, value} = event.target;
		const stq = _getCopy(this.selectedTaskQueue);
		stq.cblight__CB_Tasks__r.forEach(t => t[name] = t.Id === label ? value : t[name]);
		this.selectedTaskQueue = stq;
	};

	/**
	 * Method closes Task Queue dialog
	 */
	closeDialog = () => {
		this.selectedTaskQueue = null;
		this.showTaskQueueDialog = false;
	};

	/**
	 * Method can delete task queue or separate task
	 */
	deleteTaskQueue = (event) => {
		if (!confirm('Are you sure?')) return null;
		this.showSpinner = true;
		const tqId = event.target.value;
		deleteTaskQueueServer({tqId})
			.then(() => this.getTaskQueues())
			.catch(e => _parseServerError("TQS : Deleting Error: ", e))
	};

	/**
	 * Method moves task queues to initial status
	 */
	resetTaskQueue = (event) => {
		if (!confirm('Are you sure?')) return null;
		this.showSpinner = true;
		resetTaskQueueServer({taskQueueId: event.target.value})
			.then(() => this.connectedCallback())
			.catch(e => _parseServerError("TQS : Reset Task Queues Error: ", e))
	};

	/**
	 * Method saves opened task queue
	 */
	saveTaskQueue = (tq, tasks) => {
		this.showSpinner = true;
		if (!tasks) { // if task queue is not external
			tq = this.selectedTaskQueue;
			tasks = this.selectedTaskQueue.cblight__CB_Tasks__r;
		}
		tasks.forEach((tq, i) => tq.cblight__OrderNumber__c = i + 1);
		saveTaskQueueAndTasksServer({tq, tasks})
			.then(() => {
				this.getTaskQueues();
				_message('success', 'Saved');
			})
			.catch(e => _parseServerError('TQS : Saving Error', e));
	};

	///////////////////// DRUG & DROP ///////////////////////
	/**
	 * User took the task
	 */
	dragStart(event) {
		event.target.classList.add('drag');
	}

	dragOver(event) {
		event.preventDefault();
		return false;
	}

	/**
	 * put dropped element into a new position
	 */
	dropElement(event) {
		try {
			event.stopPropagation();
			const fromElementId = this.template.querySelector('.drag').dataset.param;
			const toElementId = event.target.dataset.param;
			if (!toElementId || fromElementId === toElementId) { // the same record
				return false
			}
			const updatedTasks = [];
			const neededIndex = this.selectedTaskQueue.cblight__CB_Tasks__r.findIndex(t => t.Id === toElementId);
			const fromElement = this.selectedTaskQueue.cblight__CB_Tasks__r.find(t => t.Id === fromElementId);
			this.selectedTaskQueue.cblight__CB_Tasks__r = this.selectedTaskQueue.cblight__CB_Tasks__r.filter(t => t.Id !== fromElementId);
			const pushLast = this.selectedTaskQueue.cblight__CB_Tasks__r.length === neededIndex;
			this.selectedTaskQueue.cblight__CB_Tasks__r.forEach((t, i) => {
				if (i === neededIndex) updatedTasks.push(fromElement);
				updatedTasks.push(t);
			});
			if (pushLast) updatedTasks.push(fromElement);
			this.selectedTaskQueue.cblight__CB_Tasks__r = updatedTasks;
			this.selectedTaskQueue = _getCopy(this.selectedTaskQueue);
			this.template.querySelectorAll('.draggableLine').forEach(element => element.classList.remove('drag'));
		} catch (e) {
			_message('error', e);
		}
	};

	///////////////////// DRUG & DROP ///////////////////////


	///////// MERGE DIALOG //////////////
	toggleCombineDialog = () => this.taskQueueSetupMerge.toggleCombineDialog();
	handleChangeCombineOptions = (event) => this.taskQueueSetupMerge.handleChangeCombineOptions(event);
	combineTaskQueues = () => this.taskQueueSetupMerge.combineTaskQueues();
	///////// MERGE DIALOG //////////////

	/////////  EVENT HANDLERS ///////////
	handleSubscribe = () => {
		// Callback invoked whenever a new event message is received
		const _this = this;
		const messageCallback = function (response) {
			let obj = _getCopy(response);
			let objData = obj.data.payload;
			if (objData.cblight__Description__c === 'Task Updated') {
				_this.getTaskQueues(true);
			}
		};

		// Invoke subscribe method of empApi. Pass reference to messageCallback
		subscribe(this.channelName, -1, messageCallback)
			.then(response => {
				console.log('Subscription request sent to: ', JSON.stringify(response.channel));
				this.subscription = response;
			});
	};
	//handle Error
	registerErrorListener = () => {
		onError(error => {
			console.error('Received error from server: ', JSON.stringify(error));
		});
	};
	/////////  EVENT HANDLERS ///////////


}