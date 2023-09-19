import {api, LightningElement, track} from 'lwc';
import {_message} from 'c/cbUtils';
import {addHeader} from './cbExcelBackupHeader';
import {getBudgetSheet} from './cbExcelBackupBudget';
import {getPivotSheet} from './cbExcelBackupPivot';
import exceljs from '@salesforce/resourceUrl/exceljs';
import {loadScript} from 'lightning/platformResourceLoader';


export default class CbExcelBackup extends LightningElement {

	@api summaryData;
	@api globalCluster;
	@track showSpinner = false;

	connectedCallback() {

	}

	/**
	 * The method exceljs from static resource
	 */
	renderedCallback() {
		Promise.all([
			loadScript(this, exceljs),
		]).catch(function (e) {
			_message(`error`, `BLME : Excel Backup load library ${e}`);
		});
	}

	/**
	 * The main method to generate na Excel file
	 */
	generateExcelFile = async () => {
		try {
			this.showSpinner = true;
			let fileName = 'Budget Lines ' + new Date().toLocaleString('en-US');
			fileName = prompt('Name to be used for the file', fileName);
			if (!fileName || fileName.length < 1) {
				this.showSpinner = false;
				return;
			}
			let workbook = new ExcelJS.Workbook();
			let blSheet = workbook.addWorksheet('Budget', {views: [{state: 'frozen', ySplit: 5, xSplit: 0}]});
			let pivotSheet = workbook.addWorksheet('Pivot', {views: [{state: 'frozen', ySplit: 1, xSplit: 0}]});

			addHeader(blSheet);
			getBudgetSheet(blSheet, this.summaryData, this.globalCluster);
			getPivotSheet(pivotSheet, this.summaryData, this.globalCluster);

			let data = await workbook.xlsx.writeBuffer();
			const blob = new Blob([data], {type: 'application/octet-stream'});
			let downloadLink = document.createElement("a");
			downloadLink.href = window.URL.createObjectURL(blob);
			downloadLink.target = '_blank';
			downloadLink.download = fileName + '.xlsx';
			downloadLink.click();
			this.showSpinner = false;
		} catch (e) {
			_message('error', 'BLME : Excel Backup Generate a File Error : ' + e);
			this.showSpinner = false;
		}
	};
}