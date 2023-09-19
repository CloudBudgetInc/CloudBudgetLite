import {api, LightningElement, track} from 'lwc';
import {_getCopy, _message, _parseServerError} from 'c/cbUtils';
import getRecentBudgetLinesServer from "@salesforce/apex/CBBudgetLinePageController.getRecentBudgetLinesServer";

export default class CbRecentRecords extends LightningElement {

	@track recentRecords = [];
	@api openRecord;

	connectedCallback() {
		this.updateListOfRecentRecords();
	};

	/**
	 * Method gets a lis of 5 opened budget lines
	 */
	updateListOfRecentRecords = () => {
		getRecentBudgetLinesServer()
			.then(records => this.recentRecords = _getCopy(records))
			.catch(e => _parseServerError('RR : Get Recent records error : ', e));
	};
	/**
	 * Handler for menu items
	 */
	open = (event) => {
		try {
			this.openRecord(event.target.value);
		} catch (e) {
			_message('error', 'RR : Open BL Error : ' + e);
		}
	};
}