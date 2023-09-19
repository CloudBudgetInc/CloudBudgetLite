import {api, LightningElement, track} from "lwc";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {_generateFakeId, _isInvalid, _cl} from 'c/cbUtils';
import getIdToNamesAndFieldLabelsMap
	from '@salesforce/apex/CBFilterManagerPageController.getIdToNamesAndFieldLabelsMapServer';
import getAllSObjectFormulaFieldsList
	from '@salesforce/apex/CBFilterManagerPageController.getAllSObjectFormulaFieldsListServer';

export default class CbFilterManager extends LightningElement {
	relationSO = [
		{label: 'Equal', value: '='},
		{label: 'Not equal', value: '!='},
		{label: 'More', value: '>'},
		{label: 'Less', value: '<'},
		{label: 'Equal Or Less', value: '>='},
		{label: 'Equal Or More', value: '<='},
		{label: 'Like', value: 'LIKE'},
	];
	lookupRelationSO = [
		{label: 'Equal', value: '='},
		{label: 'Not equal', value: '!='},
		{label: 'Equal null', value: '= NULL'},
		{label: 'Not equal null', value: '!= NULL'}
	];
	radioSO = [
		{label: 'AND', value: 'AND'},
		{label: 'OR', value: 'OR'},
		{label: 'CUSTOM', value: 'CUSTOM'}
	];
	// TODO Extension in case of some strange field will appear: recordEditFormTypes = ['STRING', 'ID', 'DOUBLE', 'CURRENCY', 'INTEGER', 'REFERENCE', 'PICKLIST', 'DATE', 'CHECKBOX'];
	userEditFormTypes = ['Group', 'User'];

	@api baseRequestString = ''; // base SOQL filter string for the component initialization
	@api fieldsAvailable = {}; // list of SO sObject fields
	@api filterTitle = {}; // Header of filter lines
	@api sobjectType = ''; // type of sObject to be filtered
	@api usersAndQueues = []; // list of SO
	@track formulaFields = []; // list of Formula fields of SObject
	@track renderFilter = false;
	@track resultRequestString = '';
	@track formattedRequestString = ''; // formatted query string to display to the user
	@track showFormattedString = false;
	@track renderComplexCondition = false;
	@track filterLines = [];
	@track radioOption = 'AND';
	@track customCondition = '';
	@track deletebtnpressed = false;

	/**
	 * doInit or so
	 */
	connectedCallback() {
		this.resultRequestString = this.baseRequestString;
		this.formatRequestString(this.baseRequestString);
		this.getFormulaFieldsList();
	}

	/**
	 *  Method gets the list of formula fields from the server
	 */
	getFormulaFieldsList() {
		getAllSObjectFormulaFieldsList({sObjectName: this.sobjectType})
			.then(resultFieldsList => {
				this.formulaFields = resultFieldsList;
			}).catch(error => alert("Filter Manager : Get Formula Fields List Callback Error: " + JSON.stringify(error)));
	}

	/**
	 * Method assigns formatted string to {formattedRequestString}
	 * Checking if a string is an ID inside the server's getIdToNamesMap method
	 * @param str Filter string
	 */
	formatRequestString(str) {
		try {
			if (!_isInvalid(str)) {
				let Ids = str.match(new RegExp('\'(.*?)\'', 'g'));
				if (!Ids || Ids.length === 0) {
					this.formattedRequestString = str;
					localStorage.removeItem('formattedRequestString');
					localStorage.setItem('formattedRequestString', str);
					this.showFormattedString = true;
					return null;
				}
				Ids.forEach((id, i) => Ids[i] = id.replaceAll('\'', ''));
				getIdToNamesAndFieldLabelsMap({Ids, sObjectName: this.sobjectType})
					.then((resultMap) => {
						for (let key in resultMap) {
							str = str.replaceAll(key, resultMap[key]);
						}
						localStorage.removeItem('formattedRequestString');
						localStorage.setItem('formattedRequestString', str);
						this.formattedRequestString = str;
						this.showFormattedString = true;
					})
					.catch((error) => alert("Filter Manager : Format Request String Callback Error: " + JSON.stringify(error)));
			} else {
				this.formattedRequestString = '';
				this.showFormattedString = false;
			}
		} catch (e) {
			alert('Filter Manager : Format Request String Error: ' + e);
		}
	}

	//////// FILTER LINES /////////
	/**
	 * Method for adding a new filter line to the filter list of lines
	 */
	addFilterLine() {
		let filterLines = this.filterLines;
		filterLines.push({field: 'Name', relation: '=', value: null});
		this.updateFilterLineExtraFields(this.filterLines, this.fieldsAvailable);
		this.filterLines = filterLines;
		this.deletebtnpressed = false;
	}

	/**
	 * Scrolls to bottom after new filter line adding
	 */
	renderedCallback() {
		if (this.renderFilter && !this.deletebtnpressed) {
			const container = this.template.querySelector('[data-id="filterLinesContainer"]');
			container.scrollTop = container.scrollHeight;
			this.deletebtnpressed = false;
		}
	}


	////////// HANDLERS //////////////
	/**
	 * Handler of changes made with filter lines (field and relations only)
	 */
	handleFilterFieldOrRelationChange(event) {
		try {
			const selectedLine = this.filterLines.find(l => l.key === event.target.name); // line where changes were run
			const soType = event.target.label.toLowerCase(); // type od dropdown that run the event
			if (soType === 'field') { // if the first dropdown "field" was changed reset all other dropdown
				selectedLine.value = null;
				selectedLine.relation = '=';
			}
			if(event.target.value === '= NULL'){
				selectedLine.value = '= NULL';
				selectedLine.hideValues = true;
			} else if (event.target.value === '!= NULL'){
				selectedLine.value = '!= NULL';
				selectedLine.hideValues = true;
			} else {
				selectedLine[soType] = event.target.value;
				selectedLine.hideValues = false;
				selectedLine.value = '';
			}
			this.updateFilterLineExtraFields(this.filterLines, this.fieldsAvailable);
		} catch (e) {
			alert('Filter Manager : Handle Filter Field Or Relation Change Error: ' + e);
		}
	}

	/**
	 * Handler of changes made with filter lines (values only)
	 */
	handleFilterValueChange(event) {
		try {
			const selectedLine = this.filterLines.find(l => l.key === event.target.name);
			selectedLine.value = event.target.value;
		} catch (e) {
			alert('Filter Manager : Handle Filter Value Change Error: ' + e);
		}
	}

	/**
	 * Handler of changes 'AND', 'OR', 'CUSTOM' modes
	 */
	handleRadioChange(event) {
		this.radioOption = event.target.value;
		this.renderComplexCondition = this.radioOption === 'CUSTOM';
	}

	/**
	 * Handler to set custom condition string for 'CUSTOM' mode
	 */
	handleCustomCondition(event) {
		this.customCondition = event.target.value;
	}

	/**
	 * Delete handler for the filter row delete button
	 */
	deleteFilterRow(event) {
		this.deletebtnpressed = true;
		this.filterLines = this.filterLines.filter(l => l.key !== event.target.name);
		this.updateFilterLineExtraFields(this.filterLines, this.fieldsAvailable);
	}

	////////// HANDLERS //////////////
	///////// SERVICE METHODS ///////
	/**
	 * Method generates Request string from lines
	 */
	generateRequestWhereString() {
		try {
			let r = '';
			this.filterLines.forEach((item) => {
				if (['STRING', 'ID', 'REFERENCE', 'PICKLIST'].includes(item.type)) {
					if (item.value === '= NULL') {
						item.relation = '=';
						item.value = 'null';
					} else if (item.value === '!= NULL'){
						item.relation = '!=';
						item.value = 'null';
					} else {
						item.value = `'${item.value}'`;
					}
				}
				if (['DATE'].includes(item.type)) {
					item.value = `${item.value}`;
				}
			});

			if (this.radioOption === 'AND' || this.radioOption === 'OR') {
				this.filterLines.forEach(l => {
					if (r.length > 1) r += this.radioOption;
					r += ` ${l.field} ${l.relation} ${l.value} `;
				});
			} else { // complex condition
				r = this.customCondition;
				for (let index = 1; index < 100; index++) {
					r = r.replace(index, `^${index}^`);
				}
				this.filterLines.forEach((item, index) => {
					let key = `^${index + 1}^`;
					let value = `${item.field} ${item.relation} ${item.value}`;
					r = r.replace(key, value);
				});
			}
			this.resultRequestString = r;
			this.formatRequestString(r);
			this.passResultStringToParent();
		} catch (e) {
			alert('Filter Manager : Generate Request Where String Error: ' + e);
		}
		// TODO back result
	}

	/**
	 * Method returns result query string to parent component
	 */
	passResultStringToParent() {
		const e = new CustomEvent("resultrequeststringchanged", {
			detail: {
				result: this.resultRequestString,
				title: this.filterTitle
			}
		});
		this.dispatchEvent(e);
	}

	/**
	 * Method prepares filter lines from the request SOQL string
	 */
	showFilter() {
		try {
			this.renderFilter = true;
			if (_isInvalid(this.resultRequestString)) this.resultRequestString = '';
			this.filterLines = this.parseFilterLines(this.resultRequestString);
			this.filterLines.forEach((item) => {
				if (item.value === 'null' && item.relation === '=') {
						item.relation = '= NULL';
						item.value = '= NULL';
						item.hideValues = true;
				} else if (item.value === 'null' && item.relation === '!=') {
						item.relation = '!= NULL';
						item.value = '!= NULL';
						item.hideValues = true;
				}
			});
			this.filterLines = this.updateFilterLineExtraFields(this.filterLines, this.fieldsAvailable);
			this.radioOption = this.detectCondition(this.resultRequestString);
			if (this.radioOption === 'CUSTOM') {
				this.customCondition = this.generateComplexCondition(this.resultRequestString);
			}
			this.renderComplexCondition = this.radioOption === 'CUSTOM';
		} catch (e) {
			alert('Filter Manager : Show Filter Error : ' + e);
		}
	}

	/**
	 * The method converts lines to SOQL request string
	 */
	applyFilter() {
		if (this.radioOption === 'CUSTOM') {
			let message = this.validateComplexConditionParentheses(this.customCondition);
			if (!message) message = this.validateComplexConditionLongitude(this.filterLines, this.customCondition);
			if (!message) message = this.validateComplexConditionNumberDoubling(this.customCondition);
			if (!message) message = this.validateComplexConditionExtraSymbols(this.customCondition);
			if (message) {
				this.errorMessage(message);
				return;
			}
		}
		this.renderFilter = false;
		this.generateRequestWhereString();
	}

	/**
	 * Handler for the 'Close' button to close the Filter modal dialog
	 */
	cancelFilter() {
		this.renderFilter = false;
	}

	/**
	 * first time after init filter line generator
	 * index, key and type are in the updateFilterLineExtraFields ()
	 */
	parseFilterLines(query) {
		try {
			if (_isInvalid(query) || query.length < 2) return [];
			let res = query.replace(/[\(\)]/g, "").split(/\s+/), lines = [], line, part = '';
			res.forEach((str, index) => {
				if (str.length === 0) return;
				if (str.startsWith('\'') && !str.endsWith('\'')) {
					part += str;
					return;
				} else if (!str.startsWith('\'') && str.endsWith('\'')) {
					str = part + ' ' + str;
					part = '';
				} else if (part.length > 0) {
					part += ' ' + str;
					return;
				}
				if (['AND', 'OR'].includes(str)) {
					return;
				}
				if (line === undefined) {
					line = {};
					line.field = str;
					lines.push(line);
					return;
				}
				if (['=', '!=', '>', '>=', '<', '<=', 'like', 'contains', 'ends', 'starts'].includes(str.toLowerCase())) {
					line.relation = str;
					return;
				}
				str = str.replace(/^'/, '').replace(/'$/, ''); // replace firs and last '
				if (line.relation === 'LIKE') { // specify Like
					if (str.startsWith('%') && str.endsWith('%')) {
						line.relation = 'contains';
					} else if (str.startsWith('%')) {
						line.relation = 'ends';
					} else if (str.endsWith('%')) {
						line.relation = 'starts';
					}
				}
				line.value = str.replace(/^%/g, '').replace(/$%/g, ''); // replace firs and last %
				line = undefined;
			});
			return lines;
		} catch (e) {
			alert('Filter Manager : Parse Filter Lines Error: ' + e);
		}
	}

	/**
	 * returns type of complex relation of the SOQL request line
	 */
	detectCondition(query) {
		if (/ AND /.test(query) && / OR /.test(query)) return 'CUSTOM';
		if (/ AND /.test(query)) return 'AND';
		if (/ OR /.test(query)) return 'OR';
		return 'AND';
	}

	/**
	 * 1 AND (2 OR 3)
	 */
	generateComplexCondition(query) {
		let res = query.split(/ AND | OR |\)|\(/g), counter = 1;
		try {
			res.forEach(str => {
				if (str === '' || str === ' ' || str === '  ') return; // only spaces
				query = query.replace(str, ` ${counter++} `);
			});
		} catch (e) {
			alert('Filter Manager : Complex Condition Error:' + e);
		}
		return query;
	}

	updateFilterLineExtraFields(filterLines, fieldListSO) {
		filterLines.forEach((item, index) => {
			item.index = index + 1;
			if (item.key === undefined) item.key = _generateFakeId();
			const neededSO = fieldListSO.find(so => item.field === so.value);
			item.type = neededSO.type;
			item.detail = neededSO.detail;
			item.label = neededSO.label;
			item.usersEditForm = item.recordEditForm = item.isFormula = false;
			if (this.userEditFormTypes.includes(item.detail)) {
				item.usersEditForm = true;
			} else {
				item.recordEditForm = true;
			}
			if (!item.usersEditForm && this.formulaFields.includes(item.field)) {
				item.recordEditForm = false;
				item.isFormula = true;
				item.inputType = item.type === 'DATE' || item.type === 'DATETIME' ? 'date' : 'text';
			}
			if (item.hideValues) {
				item.usersEditForm = false;
				item.recordEditForm = false;
				item.isFormula = false;
			}
			item.showLookupRelation = ['PICKLIST', 'REFERENCE', 'CHECKBOX'].includes(item.type); // list of relations
		});
		return filterLines;
	}

	///////// SERVICE METHODS ///////


	//////// MESSAGES ///////////
	errorMessage(message) {
		const event = new ShowToastEvent({
			title: 'Note!',
			message,
			variant: 'warning'
		});
		this.dispatchEvent(event);
	}

	infoMessage(message) {
		const event = new ShowToastEvent({
			title: 'Hint',
			message,
			variant: 'info'
		});
		this.dispatchEvent(event);
	}

	//////// MESSAGES ///////////

	//////// VALIDATIONS ////////
	validateComplexConditionParentheses(condition) {
		let chars = condition.split(''),
			stack = [],
			open = ['{', '(', '['],
			close = ['}', ')', ']'],
			closeIndex,
			openIndex;
		for (let i = 0, len = chars.length; i < len; i++) {
			openIndex = open.indexOf(chars[i]);
			if (openIndex !== -1) {
				stack.push(openIndex);
				continue;
			}
			closeIndex = close.indexOf(chars[i]);
			if (closeIndex !== -1) {
				openIndex = stack.pop();
				if (closeIndex !== openIndex) {
					return 'Please check the brackets';
				}
			}
		}
		return stack.length === 0 ? null : 'Please check the brackets';
	}

	validateComplexConditionLongitude(filterLines, condition) {
		for (let i = 1; i < 4; i++) {
			if (!condition.includes(i)) {
				return 'Custom condition must have 1-3 condition';
			}
		}
		let maximumNumber = 0;
		for (let i = 1; i < 100; i++) {
			if (condition.includes(i)) maximumNumber = i;
		}
		let numberOfLines = filterLines.length;
		return maximumNumber === numberOfLines ? null : 'The condition does not match the number of lines';
	}

	validateComplexConditionNumberDoubling(condition) {
		for (let i = 1; i < 50; i++) {
			if ((condition.match(new RegExp(i, "g")) || []).length > 1) return `Number ${i} occurs several times`;
		}
		return null;
	}

	validateComplexConditionExtraSymbols(condition) {
		let rest = condition
			.replace(/[0-9]/g, '')
			.replace(/AND/g, '')
			.replace(/OR/g, '')
			.replace(/\(/g, '')
			.replace(/ /g, '')
			.replace(/\)/g, '');
		return rest === '' ? null : `Extra symbols detected "${rest}"`;
	}

	//////// VALIDATIONS ////////


}