import {_getCopy, _message} from "c/cbUtils";

export class CbTaskQueueSetupMerge {

	parent;

	constructor(context) {
		this.parent = context;
	}

	/**
	 * Method opens or closes the combine dialog
	 */
	toggleCombineDialog = () => {
		this.parent.showCombineDialog = !this.parent.showCombineDialog;
	};

	handleChangeCombineOptions = (event) => {
		this.parent.selectedForCombiningTQ = event.detail.value;
	};

	/**
	 * Method combines several Task queues in one record
	 */
	combineTaskQueues = () => {
		if (this.parent.selectedForCombiningTQ.length < 2) {
			_message('info', 'Select at least two Task Queues to combine');
			return null;
		}
		const selectedTaskQueues = this.parent.taskQueues.filter(tq => this.parent.selectedForCombiningTQ.includes(tq.Id));
		const combinedTasks = selectedTaskQueues.flatMap(tq => _getCopy(tq.cblight__CB_Tasks__r, true));
		const combinedTQ = {
			Name: 'Combined Task Queue',
			cblight__Status__c: 'Idle'
		};
		this.parent.saveTaskQueue(combinedTQ, combinedTasks);
	};


}