import {api, LightningElement, track} from 'lwc';
import getRelatedRecordsServer from '@salesforce/apex/CBInitWizardReportPageController.getRelatedRecordsServer';
import {_message, _parseServerError} from 'c/cbUtils';

export default class CbInitWizardReport extends LightningElement {
	@api mappingType = '';
	@track reportLines = [];
	@track showSpinner = false;
	@track needDetails = false;

	connectedCallback() {
		this.getListOfAvailableSObjects();
	}

	getListOfAvailableSObjects = () => {
		this.showSpinner = true;
		this.reportLines = [];
		const {mappingType, needDetails} = this;
		getRelatedRecordsServer({mappingType, needDetails})
			.then(reportData => {
				try {
					if (reportData.length > 0) {
						reportData.forEach((line, idx) => {
							line.idx = idx + 1;
							if (line.extId) line.extId = '/' + line.extId;
							if (line.CBId) line.CBId = '/' + line.CBId;
							line.isSuccess = line.styleClass === 'success';
							line.isWarning = line.styleClass === 'warning';
						})
					}
					this.reportLines = reportData.slice(0, 100);
				} catch (e) {
					_message('error', 'Init Wizard Report : Get List of Available SObjects Error : ' + e);
				}
			})
			.catch(e => _parseServerError('Init Wizard Report : Get List of Available SObjects Error : ', e))
			.finally(() => this.showSpinner = false);
	};

	toggleDetails = () => {
		this.needDetails = !this.needDetails;
		this.getListOfAvailableSObjects();
	};

	closeReport = () => {
		this.dispatchEvent(new CustomEvent('closeInitWizardReport', {
			bubbles: true,
			composed: true,
			detail: this.line
		}));
	};

}