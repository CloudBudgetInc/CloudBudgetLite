/**
Copyright (c) 10 2022, CloudBudget, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
 * Neither the name of the CloudBudget, Inc. nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

 */
import {api, LightningElement, track} from 'lwc';
import getInvoicesServer from '@salesforce/apex/CBInvoicePageController.getInvoicesServer';
import getAnalyticsMapServer from '@salesforce/apex/CBInvoicePageController.getAnalyticsMapServer';
import saveInvoiceWrappersServer from '@salesforce/apex/CBInvoicePageController.saveInvoiceWrappersServer';
import deleteInvoicesServer from '@salesforce/apex/CBInvoicePageController.deleteInvoicesServer';
import {_applyDecStyle, _confirm, _message, _parseServerError, _setCell} from "c/cbUtils";
import {loadScript} from 'lightning/platformResourceLoader';
import exceljs from '@salesforce/resourceUrl/exceljs';

export default class cbInvoiceLoader extends LightningElement {

	@api recordId;
	@track showSpinner = false;
	@track showUploadButton = true;
	@track invoices = [];
	@track analyticMap = {};
	@track logs = [];
	@track showSaveButton = false;
	@track disableSaveButton = false;

	file;
	@track analytics;
	SHEET_NAME = 'CB Invoices';

	connectedCallback() {
		_applyDecStyle();
	};

	renderedCallback() {
		Promise.all([
			loadScript(this, exceljs),
		]).catch(function (e) {
			_message(`error`, `File load library error ${e}`);
		});
	}

	/////// DOWNLOAD FILE ////////////////////////
	async downloadInvoicesFile() {
		this.showSpinner = true;
		try {
			const fileName = 'CB Invoices';
			let workbook = new ExcelJS.Workbook();
			let invoicesSheet = workbook.addWorksheet(this.SHEET_NAME, {
				views: [{
					state: 'frozen',
					ySplit: 1,
					xSplit: 0
				}]
			});

			await this.getAnalyticMap();
			await this.getInvoices();
			this.createInvoicesSheet(invoicesSheet);

			let data = await workbook.xlsx.writeBuffer();
			const blob = new Blob([data], {type: 'application/octet-stream'});
			let downloadLink = document.createElement("a");
			downloadLink.href = window.URL.createObjectURL(blob);
			downloadLink.target = '_blank';
			downloadLink.download = fileName + '.xlsx';
			downloadLink.click();
			this.showSpinner = false;
		} catch (e) {
			_message('error', 'Download File Error : ' + e);
			this.showSpinner = false;
		}
	};

	getAnalyticMap = async () => {
		try {
			await getAnalyticsMapServer()
				.then(analyticMap => this.analyticMap = analyticMap)
				.catch(e => _parseServerError('Get analytic map callback error', e));
		} catch (e) {
			_message('error', 'Get analytic map error : ' + e);
		}
	};
	getInvoices = async () => {
		try {
			await getInvoicesServer()
				.then(invoices => this.invoices = invoices)
				.catch(e => _parseServerError('Get list of invoices error', e));
		} catch (e) {
			_message('error', 'Get invoices error : ' + e);
		}
	};
	createInvoicesSheet = (invoiceSheet) => {
		[20, 10, 12, 12, 12, 12, 12, 12, 12, 12, 12, 20, 10, 18].forEach((width, idx) => invoiceSheet.getColumn(idx + 1).width = width);
		const HEADER_FONT = {'bold': true, 'size': 10, 'name': 'Calibri', 'family': 2, 'scheme': 'minor'};
		const headerRow = invoiceSheet.getRow(1);
		this.headerTitles.forEach((t, idx) => {
			const cell = headerRow.getCell(idx + 1);
			_setCell(cell, t.l, null, HEADER_FONT); //_setCell = (cell, value, fill, font, numFmt, alignment, border)
		});
		let rowCounter = 2;
		this.invoices.forEach(invoice => {

			if (!invoice.cblight__CBInvoiceLines__r) return;

			invoice.cblight__CBInvoiceLines__r.forEach(line => {
				try {
					const row = invoiceSheet.getRow(rowCounter++);
					const nameCell = row.getCell(1);
					const extIdCell = row.getCell(2);
					const divisionCell = row.getCell(3);
					const accountCell = row.getCell(4);
					const periodCell = row.getCell(5);
					const invoiceDateCell = row.getCell(6);
					const variable1Cell = row.getCell(7);
					const variable2Cell = row.getCell(8);
					const variable3Cell = row.getCell(9);
					const variable4Cell = row.getCell(10);
					const variable5Cell = row.getCell(11);
					const lineNameCell = row.getCell(12);
					const amountCell = row.getCell(13);
					const detailsCell = row.getCell(14);

					_setCell(nameCell, invoice.Name);
					if (invoice.cblight__ExtId__c) _setCell(extIdCell, invoice.cblight__ExtId__c);
					if (invoice.cblight__CBDivision__c) _setCell(divisionCell, this.analyticMap[invoice.cblight__CBDivision__c]);
					if (invoice.cblight__CBAccount__c) _setCell(accountCell, this.analyticMap[invoice.cblight__CBAccount__c]);
					if (invoice.cblight__CBPeriod__c) _setCell(periodCell, this.analyticMap[invoice.cblight__CBPeriod__c]);
					if (invoice.cblight__InvoiceDate__c) _setCell(invoiceDateCell, invoice.cblight__InvoiceDate__c);
					if (invoice.cblight__CBVariable1__c) _setCell(variable1Cell, this.analyticMap[invoice.cblight__CBVariable1__c]);
					if (invoice.cblight__CBVariable2__c) _setCell(variable2Cell, this.analyticMap[invoice.cblight__CBVariable2__c]);
					if (invoice.cblight__CBVariable3__c) _setCell(variable3Cell, this.analyticMap[invoice.cblight__CBVariable3__c]);
					if (invoice.cblight__CBVariable4__c) _setCell(variable4Cell, this.analyticMap[invoice.cblight__CBVariable4__c]);
					if (invoice.cblight__CBVariable5__c) _setCell(variable5Cell, this.analyticMap[invoice.cblight__CBVariable5__c]);
					if (line.Name) _setCell(lineNameCell, line.Name);
					if (line.cblight__Amount__c) _setCell(amountCell, line.cblight__Amount__c);
					if (line.cblight__Details__c) _setCell(detailsCell, line.cblight__Details__c);
				} catch (e) {
					_message('error', 'Row creation error : ', e);
				}
			});

		});
	};
	headerTitles = [
		{l: 'Name', idx: 1},
		{l: 'ExtId', idx: 2},
		{l: 'Division', idx: 3},
		{l: 'Account', idx: 4},
		{l: 'Period', idx: 5},
		{l: 'Invoice Date', idx: 6},
		{l: 'Variable 1', idx: 7},
		{l: 'Variable 2', idx: 8},
		{l: 'Variable 3', idx: 9},
		{l: 'Variable 4', idx: 10},
		{l: 'Variable 5', idx: 11},
		{l: 'Line Name', idx: 12},
		{l: 'Amount', idx: 13},
		{l: 'Details', idx: 14},
	];
	/////// DOWNLOAD FILE ////////////////////////


	/////// UPLOAD FILE //////////////////////////
	/**
	 * Method gets a file
	 */
	handleFilesUploading = (event) => {
		this.showSaveButton = false;
		let file = event.target.files[0];
		let blob = new Blob([file, {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}]);
		let fileReader = new FileReader();
		this.showSpinner = true;
		fileReader.onload = async event => {
			try {
				let workbook = new ExcelJS.Workbook();
				await workbook.xlsx.load(event.target.result);
				await this.readInvoices(workbook);
				this.showSpinner = false;
				this.showSaveButton = true;
			} catch (e) {
				_message('error', 'Parse File Error ' + e);
				this.showSpinner = false;
			}
		};
		fileReader.readAsArrayBuffer(blob);
	};

	readInvoices = async (workbook) => {
		try {
			await this.getAnalyticMap();
			this.invoices = [];
			const invoiceSheet = workbook.getWorksheet(this.SHEET_NAME);
			const colNumber = invoiceSheet.actualRowCount;

			const invoices = {}; // key is hash
			for (let i = 2; i <= colNumber; i++) {
				const row = invoiceSheet.getRow(i);

				const name = row.getCell(1).value;
				if (!name) continue;
				const extId = row.getCell(2).value;
				const divName = row.getCell(3).value;
				const accName = row.getCell(4).value;
				const periodName = row.getCell(5).value;
				const invoiceDate = row.getCell(6).value;
				const var1Name = row.getCell(7).value;
				const var2Name = row.getCell(8).value;
				const var3Name = row.getCell(9).value;
				const var4Name = row.getCell(10).value;
				const var5Name = row.getCell(11).value;
				const lineName = row.getCell(12).value;
				const amount = row.getCell(13).value;
				const details = row.getCell(14).value;
				const key = name + extId + divName + accName + periodName + invoiceDate + var1Name + var2Name + var3Name + var4Name + var5Name;

				let invoiceWrapper = invoices[key];
				if (!invoiceWrapper) {
					invoiceWrapper = {invoice: {}, lines: []};
					invoiceWrapper.invoice.Name = name;
					invoiceWrapper.invoice.cblight__ExtId__c = extId;
					invoiceWrapper.invoice.cblight__CBDivision__c = this.analyticMap[divName];
					invoiceWrapper.invoice.cblight__CBAccount__c = this.analyticMap[accName];
					invoiceWrapper.invoice.cblight__CBPeriod__c = this.analyticMap[periodName];
					invoiceWrapper.invoice.cblight__InvoiceDate__c = invoiceDate;
					if (var1Name) invoiceWrapper.invoice.cblight__CBVariable1__c = this.analyticMap[var1Name];
					if (var2Name) invoiceWrapper.invoice.cblight__CBVariable2__c = this.analyticMap[var2Name];
					if (var3Name) invoiceWrapper.invoice.cblight__CBVariable3__c = this.analyticMap[var3Name];
					if (var4Name) invoiceWrapper.invoice.cblight__CBVariable4__c = this.analyticMap[var4Name];
					if (var5Name) invoiceWrapper.invoice.cblight__CBVariable5__c = this.analyticMap[var5Name];
					invoices[key] = invoiceWrapper;
				}
				const line = {Name: lineName, cblight__Amount__c: amount, cblight__Details__c: details};
				invoiceWrapper.lines.push(line);
			}
			this.invoices = Object.values(invoices);
			_message('info', 'Invoices uploaded : ' + this.invoices.length);
		} catch (e) {
			_message('error', 'Read File Error ' + e);
		}
	};


	saveInvoices = async () => {
		this.showSpinner = true;
		await saveInvoiceWrappersServer({invoiceWrappers: this.invoices})
			.then(() => {
				_message('success', 'Saved');
				this.showSpinner = false;
				this.showSaveButton = false;
			})
			.catch(e => _parseServerError('Saving Error : ', e));
	};
	/////// UPLOAD FILE //////////////////////////

	deleteInvoices = async () => {
		const conf = await _confirm('Are you sure you want to delete CB Invoices?', 'Confirm');
		if (!conf) return null;
		this.showSpinner = true;
		await deleteInvoicesServer({invoiceWrappers: this.invoices})
			.then(() => {
				_message('success', 'Deleted');
				this.showSpinner = false;
			})
			.catch(e => _parseServerError('Saving Error : ', e));
	};

}