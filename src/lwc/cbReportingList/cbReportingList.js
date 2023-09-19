import {LightningElement, track} from "lwc";
import {NavigationMixin} from 'lightning/navigation';
import getAllReportsServer from "@salesforce/apex/CBReportingPageController.getAllReportsServer";

export default class CbReportingList extends NavigationMixin(LightningElement) {

	@track showSpinner = false;
	@track reportList;

	connectedCallback() {
		this.getAllReports();
	}

	getAllReports() {
		this.showSpinner = true;
		getAllReportsServer()
			.then(result => this.reportList = result)
			.catch(error => alert("Get All Reports Error: " + JSON.stringify(error)))
			.finally(() => this.showSpinner = false)
	}

	openReport(event) {
		try {
			let reportId = event.target.value;
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: reportId,
					objectApiName: 'ObjectApiName',
					actionName: 'view'
				}
			});
		} catch (e) {
			alert('Open Report Error: ' + e)
		}
	}

	deleteReport(event) {

	}
}