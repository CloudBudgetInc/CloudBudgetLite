import { api, LightningElement, track } from "lwc";
import exceljs from "@salesforce/resourceUrl/exceljs";
import { loadScript } from "lightning/platformResourceLoader";
import workbook from "@salesforce/resourceUrl/writeExcel";
import { _message, _cl, _setCell } from "c/cbUtils";

/**
 * DOCUMENTATION FOR THIS SHIT: https://www.npmjs.com/package/write-excel-file
 */

export default class cbReportingExcel extends LightningElement {
	@track styles = [];
	styleMap = {};
	BORDER = {
		top: { style: "thin" },
		left: { style: "thin" },
		bottom: { style: "thin" },
		right: { style: "thin" }
	};
	get frozenFill() {
		return {
			type: "pattern",
			pattern: "solid",
			fgColor: { argb: this.getStyleBackgroundColor("ReportFrozenColumns").substring(1) }
		};
	}
	excelDataValue;
	@api
	get excelData() {
		return this.excelDataValue;
	}

	set excelData(value) {
		this.styles = JSON.parse(localStorage.getItem("cbstyles"));
		this.excelDataValue = value;
		if (value) {
			if (value.report.cblight__oneColumnMode__c) {
				this.reportGroupColumns = value.reportSingleColumn;
			} else {
				this.reportGroupColumns = value.reportGroupColumns;
			}
			if (value.reportColumns) {
				this.reportColumns = value.reportColumns;
			}
			if (value.reportLines) {
				this.reportLines = value.reportLines;
			}
			if (value.report) {
				this.fileName = value.report.Name + ".xlsx";
				this.description = value.report.cblight__Description__c;
				this.singleColumn = value.report.cblight__oneColumnMode__c;
			}
		}
	}

	librariesLoaded = false;
	@track reportGroupColumns = [];
	@track reportColumns = [];
	@track reportLines = [];
	@track fileName = "_.xlsx";
	description;
	singleColumn;

	getStyleByName(styleName) {
		let style = this.styles.find((style) => {
			return style.Name.replaceAll(' ', '') === styleName;
		});
		return style;
	}

	getStyleBackgroundColor(styleName) {
		const style = this.getStyleByName(styleName);
		return style ? style.cblight__BackgroundColor__c : "#FFFFFF";
	}
	getFontWeight(styleName) {
		const style = this.getStyleByName(styleName);
		return style ? style.cblight__FontWeight__c : "normal";
	}

	renderedCallback() {
		if (this.librariesLoaded) return;
		this.librariesLoaded = true;
		Promise.all([loadScript(this, exceljs)]).catch(function (e) {
			_message(`error`, `BLME : Excel Backup load library ${e}`);
		});
	}

	///////////////NEW LIB SECTION BELOW///////////////

	/**
	 * The main method to generate na Excel file
	 */
	generateExcelFile = async () => {
		try {
			let currentRowNumber = 1;
			this.showSpinner = true;
			let fileName = this.fileName;
			fileName = prompt("Name to be used for the file", fileName);
			if (!fileName || fileName.length < 1) {
				this.showSpinner = false;
				return;
			}
			let workbook = new ExcelJS.Workbook();
			let reportSheet = workbook.addWorksheet("Report", { views: [{ state: "frozen", ySplit: 0, xSplit: 0 }] });
			currentRowNumber = this.addDescrRows(reportSheet, currentRowNumber);
			currentRowNumber = this.addHeaderRow(reportSheet, currentRowNumber);
			currentRowNumber = this.addReportRows(reportSheet, currentRowNumber);
			
			let data = await workbook.xlsx.writeBuffer();
			const blob = new Blob([data], { type: "application/octet-stream" });
			let downloadLink = document.createElement("a");
			downloadLink.href = window.URL.createObjectURL(blob);
			downloadLink.target = "_blank";
			downloadLink.download = fileName + ".xlsx";
			downloadLink.click();
			this.showSpinner = false;
		} catch (e) {
			_message("error", "Reporting Excel generateExcelFile error: " + e);
			this.showSpinner = false;
		}
	};
	addDescrRows(reportSheet, currentRowNumber) {
		try {
			if (this.description) {
				let descrRows = [["Description:"]];
				const descrList = this.description.split("\n");
				if (descrList) {
					descrList.forEach((item) => {
						descrRows.push([item]);
					});
				}
				descrRows.forEach((row) => {
					reportSheet.addRow(row);
					currentRowNumber++;
				});
				currentRowNumber++;
			}
		} catch (e) {
			_message("error", "Reporting Excel addDescrRows error: " + e);
		}
		reportSheet.getRow(1).getCell(1).font = { bold: true };
		return currentRowNumber;
	}

	addHeaderRow(reportSheet, currentRowNumber) {
		try {

			const styleMap = {};
			const firstRow = reportSheet.getRow(currentRowNumber);
			let globalIndex = 1;
			this.reportGroupColumns.forEach((column) => {
				reportSheet.getColumn(globalIndex).width = 30;
				_setCell(firstRow.getCell(globalIndex++), column.label, this.frozenFill, { bold: true }, null, null, this.BORDER);
			});
			this.reportColumns.forEach((column) => {
				reportSheet.getColumn(globalIndex).width = 20;
				if (column.class) {
					styleMap[globalIndex] = {};
					styleMap[globalIndex].bgColor = this.getStyleBackgroundColor(column.class.replaceAll(' ', ''));
					styleMap[globalIndex].bold = this.getFontWeight(column.class.replaceAll(' ', '')) === "bold";
				}
				const colTitle = column.periodName ? `${column.title} ${column.periodName}` : column.title;
				_setCell(firstRow.getCell(globalIndex++), colTitle, this.frozenFill, { bold: true }, null, {horizontal: 'right'}, this.BORDER);
			});
			this.styleMap = styleMap;
		} catch (e) {
			_message("error", "Reporting Excel addHeaderRow error: " + e);
		}
		return ++currentRowNumber;
	}

	addReportRows(reportSheet, currentRowNumber) {
		try {
			this.reportLines.forEach((reportLine) => {
				let totalLineFill;
				let totalLineFont;
				if (reportLine.class) {
					totalLineFont = { bold: this.getFontWeight(reportLine.class.replaceAll(' ', '')) === "bold" };
					totalLineFill = {
						type: "pattern",
						pattern: "solid",
						fgColor: { argb: this.getStyleBackgroundColor(reportLine.class.replaceAll(' ', '')).substring(1) }
					};
				}
				if (reportLine.labels && reportLine.reportCells) {
					const lineRow = reportSheet.getRow(currentRowNumber);
					let globalIndex = 1;

					if(this.singleColumn) {
						_setCell(lineRow.getCell(globalIndex++), reportLine.analyticsColumns[0].label, this.frozenFill, { bold: true }, null, null, this.BORDER);
					} else {
						reportLine.labels.forEach((label) => {
							_setCell(lineRow.getCell(globalIndex++), label, this.frozenFill, { bold: true }, null, null, this.BORDER);
						});
					}
					reportLine.reportCells.forEach((cell) => {
						const totalColumnFill = {
							type: "pattern",
							pattern: "solid",
							fgColor: { argb: this.styleMap[globalIndex] ? this.styleMap[globalIndex].bgColor.substring(1) : "FFFFFF" }
						};
						const font = { bold: this.styleMap[globalIndex] ? this.styleMap[globalIndex].bold : false };
						_setCell(
							lineRow.getCell(globalIndex++),
							cell.value,
							totalLineFill ? totalLineFill : totalColumnFill,
							totalLineFont ? totalLineFont : font,
							null,
							{horizontal: 'right'},
							this.BORDER
						);
					});
					currentRowNumber++;
				}
			});
		} catch (e) {
			_message("error", "Reporting Excel addReportRows error: " + e);
		}
		return ++currentRowNumber;
	}
}