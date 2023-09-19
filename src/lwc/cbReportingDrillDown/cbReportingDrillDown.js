import {api, LightningElement, track} from "lwc";
import getAllReportsServer from "@salesforce/apex/CBReportingDrillDownPageController.getDrillDownDataServer";
import {_message, _parseServerError, _cl} from 'c/cbUtils';

export default class CbReportingDrillDown extends LightningElement {

	@track showSpinner = false;
	@track drillDownList = [];
	@track showContent = false;
	@track showLinks = false;
	@api parameters = {};


	connectedCallback() {
		this.getDrillDownData();
	}

	/**
	 * Method gets data for DrillDown
	 */
	getDrillDownData() {
		this.showSpinner = true;
		this.showContent = false;
		this.drillDownList = [];
		//{"periodId":"a0D17000007aSjcEAE","configId":"a0F1700000JT4x9EAD","keys":["Expense","a071700000FvOLQAA3"]}
		getAllReportsServer({parameters: this.parameters})
			.then(reports => {
				let totalLine = this.calculateTotalCube(reports);
				this.drillDownList = this.getUnitFormattedAndIndexedReportLines([...reports, totalLine]);
				this.setDrillDownSourceIds(reports);
				this.showContent = true;
			})
			.catch(e => _parseServerError("Drill Down : Get Drill Down Data Error: ", e))
			.finally(() => this.showSpinner = false)
	}

	calculateTotalCube(cubeList) {
		return cubeList.reduce((totalCube, cube) => {
			totalCube.cblight__Budget__c += +cube.cblight__Budget__c;
			totalCube.cblight__Actual__c += +cube.cblight__Actual__c;
			cube.class = 'dec';
			return totalCube;
		}, {cblight__Budget__c: 0, cblight__Actual__c: 0, class: 'totalLineDec', Name: 'TOTAL'});
	}

	/**
	 * The method passes event to the parent component forcing to close the current modal window
	 */
	closeModalWindow() {
		this.dispatchEvent(new CustomEvent('closeDrillDown', {bubbles: true, composed: true}));
	}

	getUnitFormattedAndIndexedReportLines = (cubeList) => {
		try {
			const currencyFormat = new Intl.NumberFormat('en-US', {
				style: 'currency',
				currency: 'USD',
			});
			const percentFormat = new Intl.NumberFormat("en-US", {
				style: 'percent',
				minimumFractionDigits: 2,
				maximumFractionDigits: 2
			});

			cubeList.forEach(cube => {
				cube.cblight__Budget__c = currencyFormat.format(+cube.cblight__Budget__c);
				cube.cblight__Actual__c = currencyFormat.format(+cube.cblight__Actual__c);
				cube.link = '/' + cube.Id;
			});
			return cubeList;
		} catch (e) {
			_message('error', 'DrillDown get formatted lines Error : ' + e);
		}
	};

	/**
	 * This method adds links to source records to drill down list
	 * @param cubeList
	 */
	setDrillDownSourceIds = (cubeList) => {
		cubeList.forEach(cube => cube.ddSourceIds = cube.cblight__DrillDownIds__c ? cube.cblight__DrillDownIds__c.split(',') : []);
		this.showLinks = true;
	};

}