import {LightningElement, track} from 'lwc';
import {_message, _parseServerError} from 'c/cbUtils';
import getLogsServer from "@salesforce/apex/CBLogPageController.getLogsServer";
import getLogDetailsServer from "@salesforce/apex/CBLogPageController.getLogDetailsServer";
import getListOfLogFieldsSOServer from "@salesforce/apex/CBLogPageController.getListOfLogFieldsSOServer";

export default class CbLog extends LightningElement {
	@track filteredLogs = [];
	@track logDetail = [];
	@track isModalOpen = false;
	@track resultRequestString = '';
	@track usersAndQueues = [];
	@track logFieldsSO = [];
	rowId;

	connectedCallback() {
		this.getFilteredLogs();
		this.getListOfCBLogFields();
		document.title = 'Logs';
	}

	handleRowAction(event) {
		this.logDetail = [];
		this.rowId = event.target.dataset.id;
		this.openModal();
		this.getLogDetail(this.rowId);
	}

	/**
	 * The method returns the list of CBLog
	 */
	getFilteredLogs = async (filter) => {
		await getLogsServer({filter: filter})
			.then(result => {
				if (!result) {
					_message('info', 'The list of logs is empty', 'No Objects');
					return null;
				}
				this.filteredLogs = result;
			})
			.catch(e => _parseServerError('LOG : Get FilteredLogs Callback Error: ', e));
	};

	/**
	 * The method returns the list of CBLog Details
	 */
	getLogDetail() {
		getLogDetailsServer({filter: 'Id = \'' + this.rowId + '\''})
			.then(result => {
				if (!result) {
					alert('No Objects');
					return null;
				}
				for (let key in result.cblight__CBLogDetails__r) {
					this.logDetail.push(result.cblight__CBLogDetails__r[key])
				}
			})
			.catch(e => _parseServerError("LOG : Get Log Details Server Callback Error: ", e));
	}

	openModal() {
		this.isModalOpen = true;
	}

	closeModal() {
		this.isModalOpen = false;
	}

	submitDetails() {
		this.isModalOpen = false;
	}

	setNewFilterString(event) {
		this.resultRequestString = event.detail.result.length > 0 ? event.detail.result : '';
		this.getFilteredLogs(this.resultRequestString);
	}

	/**
	 * The method returns the list of CBLog fields
	 */
	getListOfCBLogFields() {
		getListOfLogFieldsSOServer()
			.then(logFieldsSO => this.logFieldsSO = logFieldsSO)
			.catch(e => _parseServerError('LOG : Get List Of Log Fields SO Server Error : ', e))
	}
}