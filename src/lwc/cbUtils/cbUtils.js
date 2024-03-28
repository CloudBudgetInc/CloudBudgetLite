import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getCustomPermissionsServer from "@salesforce/apex/CBCustomPermissionService.getCustomPermissionsServer";
import getIdToNamesAndFieldLabelsMap
	from '@salesforce/apex/CBFilterManagerPageController.getIdToNamesAndFieldLabelsMapServer';
import LightningConfirm from 'lightning/confirm';
import LightningPrompt from 'lightning/prompt';

const FAKE_STR = `fake-id`;
let timerStartValue = 0;
let timerEndValue = 0;

const _generateFakeId = () => FAKE_STR + Math.random();

const _deleteFakeId = (arg) => {
	[].concat(arg).forEach(l => {
		if (!_isInvalid(l.Id) && l.Id.startsWith(FAKE_STR)) {
			delete l.Id;
		}
	});
};

const _isFakeId = (Id) => _isInvalid(Id) ? false : Id.startsWith(FAKE_STR);
/**
 * Right align in LWC input works just after this
 */
const _applyDecStyle = () => {
	const inputAlignCenter = document.createElement('style');
	inputAlignCenter.innerText = `.dec input{ text-align: right!important; padding-left: 3px!important; padding-right: 3px!important }`;
	document.body.appendChild(inputAlignCenter);
};

/**
 * Method to put comments in a browser console
 * @param  message console log text
 * @param  color console log color
 */
const _cl = (message, color) => {
	try {
		message = typeof message === `object` ? message.toString() : message;
		console.log(
			`%c🌩️ ${message}`,
			`color:${color}; font: 1 Tahoma; font-size: 1.2em; font-weight: bolder; padding: 2px;`
		);
	} catch (e) {
		console.error(e);
	}
};

/**
 * Salesforce alert
 * @param type = error || warning || success || info
 * @param message = "BLM : Some Error"
 * @param title = "Toast Header" (not mandatory)
 * EXAMPLE:    _message('error', `Reporting : Generate Report Lines Error: ${e}`, 'Error');
 */
const _message = (type, message, title) => {
	try {
		dispatchEvent(new ShowToastEvent({
			title: type === 'error' ? `Error` : (title ? title : `Note`),
			message: message,
			variant: type,
			mode: type === 'success' || type === 'info' ? 'dismissible' : 'sticky'
		}));
	} catch (e) {
		alert('Message Error : ' + e);
	}
};

const _isInvalid = (t) => {
	return (t === undefined || !t || t === 'undefined' || t === 'null');
};

const _isInvalidNumber = (t) => {
	return (t === undefined || t === null || t === "" || isNaN(t));
};

const _reduceErrors = (errors) => {
	if (!Array.isArray(errors)) {
		errors = [errors];
	}

	return (
		errors
			// Remove null/undefined items
			.filter((error) => !!error)
			// Extract an error message
			.map((error) => {
				// UI API read errors
				if (Array.isArray(error.body)) {
					return error.body.map((e) => e.message);
				}
				// Page level errors
				else if (
					error?.body?.pageErrors &&
					error.body.pageErrors.length > 0
				) {
					return error.body.pageErrors.map((e) => e.message);
				}
				// Field level errors
				else if (
					error?.body?.fieldErrors &&
					Object.keys(error.body.fieldErrors).length > 0
				) {
					const fieldErrors = [];
					Object.values(error.body.fieldErrors).forEach(
						(errorArray) => {
							fieldErrors.push(
								...errorArray.map((e) => e.message)
							);
						}
					);
					return fieldErrors;
				}
				// UI API DML page level errors
				else if (
					error?.body?.output?.errors &&
					error.body.output.errors.length > 0
				) {
					return error.body.output.errors.map((e) => e.message);
				}
				// UI API DML field level errors
				else if (
					error?.body?.output?.fieldErrors &&
					Object.keys(error.body.output.fieldErrors).length > 0
				) {
					const fieldErrors = [];
					Object.values(error.body.output.fieldErrors).forEach(
						(errorArray) => {
							fieldErrors.push(
								...errorArray.map((e) => e.message)
							);
						}
					);
					return fieldErrors;
				}
				// UI API DML, Apex and network errors
				else if (error.body && typeof error.body.message === 'string') {
					return error.body.message;
				}
				// JS errors
				else if (typeof error.message === 'string') {
					return error.message;
				}
				// Unknown error shape so try HTTP status text
				return error.statusText;
			})
			// Flatten
			.reduce((prev, curr) => prev.concat(curr), [])
			// Remove empty strings
			.filter((message) => !!message)
	);
};

const _getCopy = (t, deleteId) => {
	if (_isInvalid(t)) return null;
	let r = JSON.parse(JSON.stringify(t));
	if (deleteId) {
		[].concat(r).forEach(l => delete l.Id);
	}
	return r;
};

/**
 * Method to put server error in toast
 * @param {*} reason reason
 * @param {*} error error
 */
const _parseServerError = (reason, error) => {
	try {
		const event = new ShowToastEvent({
			title: reason ? reason : "Unknown",
			message: parseErrorMessage(error),
			variant: "error",
			mode: "sticky"
		});
		dispatchEvent(event);
	} catch (e) {
		alert('Parse Server Error : ' + e);
	}
};

/**
 * Method parse two types of SF errors
 * @param error server error object
 */
const parseErrorMessage = (error) => {
	let message = 'Unknown';
	if (!error || !error.body) return message;
	if (error?.body.message) {
		message = "Status: " + error.status +
			"\nMessage: " + error?.body.message +
			"\nStack: " + error?.body.stackTrace;
	} else if (error?.body.pageErrors) {
		message = "Status: " + error.body.pageErrors[0].statusCode +
			"\nMessage: " + error.body.pageErrors[0].message;
		if (message.includes('Locked')) message = 'Record is Locked';
	}
	return message;
};

const _getCustomPermissions = async () => {
	return await getCustomPermissionsServer().catch(e => _parseServerError('BLM : Get custom permissions error : ', e));
};

const _validateFormula = (formula, maxIndex, isReport) => {
	try {
		if (!formula || formula.length === 0) return 'Please type in some formula';
		if ((formula.includes('# ') || (/#$/.test(formula)))) return 'Specify an index right after the # sign. No space';
		if ((formula.split("#").length - 1) < 1) return 'Formula must contain at least one # character';
		const extraSymbols = formula.match(/[^\._\d\-\+\s\/\*\#\(\)]/g);
		if (extraSymbols) return `Formula must not contain extra characters ${JSON.stringify(extraSymbols)}`;
		if (/[+|-|*|\\]$/.test(formula)) return 'Math sign cannot be the last one in the formula';
		if (formula.split("(").length !== formula.split(")").length) return 'The number of open and close brackets does not match';
		if (/#\d\d\d/.test(formula)) return 'Formula must not contain three-digit or more indices';
		if (!isReport) {
			const re = new RegExp(`#[${maxIndex + 1}-9]`, 'g');
			if (re.test(formula)) return `Formula index cannot exceed ${maxIndex}`;
			if (/#\d\d/.test(formula)) return 'Formula must not contain two-digit or more indices';
		}
	} catch (e) {
		alert(e);
	}
};

const _selectWholeValue = (event) => {
	event.target.selectionStart = 0;
	event.target.selectionEnd = 99;
};


/**
 * Method is using for generation an Excel file cell (exceljs lib)
 */
const _setCell = (cell, value, fill, font, numFmt, alignment, border) => {
	cell.value = value;
	cell.fill = fill;
	cell.font = font;
	cell.numFmt = numFmt;
	cell.alignment = alignment;
	cell.border = border;
};

/**
 * Method to popup a SF confirm window
 * @param message "Are you sure you want to ...."
 * @param label header may be undefined
 * @param theme  success || info || warning || error
 */
const _confirm = async (message, label, theme) => {
	const config = {
		message,
		label,
		variant: label ? 'header' : 'headerless',
		theme: theme ? theme : 'info'
	};
	return await LightningConfirm.open(config);
};

/**
 * Method to popup a SF prompt window
 * @param message "Type a new name"
 * @param defaultValue "Something default"
 * @param label header may be undefined
 * @param theme  success || info || warning || error
 */
const _prompt = async (message, defaultValue, label, theme) => {
	const config = {
		message,
		defaultValue,
		label,
		variant: label ? 'header' : 'headerless',
		theme: theme ? theme : 'info'
	};
	return await LightningPrompt.open(config);
};

/**
	 * Method assigns formatted string to {formattedRequestString}
	 * Checking if a string is an ID inside the server's getIdToNamesMap method
	 * @param str Filter string
	 */
const _formatRequestString = async (str, sobjectType) => {
	let result = {showFormattedString:false, formattedRequestString:''};
	try {
		if (!_isInvalid(str)) {
			let Ids = str.match(new RegExp('\'(.*?)\'', 'g'));
			if (!Ids || Ids.length === 0) {
				result.formattedRequestString = str;
				localStorage.removeItem('formattedRequestString');
				localStorage.setItem('formattedRequestString', str);
				result.showFormattedString = true;
				return result;
			}
			Ids.forEach((id, i) => Ids[i] = id.replaceAll('\'', ''));
			let resultMap = await getIdToNamesAndFieldLabelsMap({Ids, sObjectName: sobjectType})
			.catch((error) => alert("Filter Manager : Format Request String Callback Error: " + JSON.stringify(error)));
			for (let key in resultMap) {
				str = str.replaceAll(key, resultMap[key]);
			}
			localStorage.removeItem('formattedRequestString');
			localStorage.setItem('formattedRequestString', str);
			result.formattedRequestString = str;
			result.showFormattedString = true;

		} else {
			result.formattedRequestString = '';
			result.showFormattedString = false;
		}
	} catch (e) {
		alert('Filter Manager : Format Request String Error: ' + e);
	}
	return result;
}

export {
	_generateFakeId,
	_isFakeId,
	_deleteFakeId,
	_applyDecStyle,
	_cl,
	_confirm,
	_message,
	_isInvalid,
	_isInvalidNumber,
	_prompt,
	_reduceErrors,
	_getCopy,
	_parseServerError,
	_validateFormula,
	_selectWholeValue,
	_setCell, // exceljs function
	_getCustomPermissions, // async
	_formatRequestString // async
};