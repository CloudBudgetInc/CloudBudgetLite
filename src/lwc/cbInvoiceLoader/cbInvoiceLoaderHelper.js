import {_getCopy, _message} from "c/cbUtils";

const TITLE_ROW_INDEX = 4;
const PL_ACCOUNTS = ['4', '5', '6', '7', '8', '9'];
let context;

const convertFileToObjects = (_this, rawFileData) => {
	try {
		context = _this;
		let columnFieldsArray, totalNumber = 0, balanceNumber = 0, currentAccountIdx;
		rawFileData.split(/\r?\n/).forEach((line, idx) => { // split by rows
			if (idx < TITLE_ROW_INDEX) return; // first columns without useful info
			if (idx === TITLE_ROW_INDEX) {
				columnFieldsArray = line.split(',').map(f => f.trim());
				return null;
			}
			if (line.length < 2) return null; // empty rows

			let lineParts = splitByComa(line);
			if (!lineParts[1]) { // Title row
				lineParts[0] = lineParts[0].trim();
				if (lineParts[0].startsWith('Total') || isNaN(lineParts[0].split(' ')[0][0])) return null;
				currentAccountIdx = lineParts[0].split(' ')[0];
				return null;
			}
			totalNumber++;
			const lineObj = columnFieldsArray.reduce((obj, field, idx) => {
				obj[field] = lineParts[idx];
				return obj;
			}, {});
			lineObj.Account = currentAccountIdx;
			lineObj.sourceIndex = idx + 1; // index of a row in file
			context.fileLines.push(lineObj);
		});
		context.report.push('Total number of lines in the file: ' + totalNumber);
		context.report.push('Number of the balance transactions: ' + balanceNumber);
	} catch (e) {
		_message('error', 'Actual Loader : Convert File to Object Error : ' + e);
	}
};

const convertFileLinesToCBTransactions = () => {
	console.log('**************************************************************************************************************************************');
	let brokenLine = -1;
	try {
		const accountMap = getAccountMap();
		const departmentMap = getDepartmentNameList();
		const periodMap = getPeriodMap();
		const byMap = getBYMap();
		let invalidClasses = {}, invalidAccounts = {}, invalidPeriods = {};
		context.fileLines.forEach(line => {
			try {
				brokenLine = line.sourceIndex;
				const transaction = {}; // new transaction

				transaction.cblight__Value__c = parseFloat(line['Amount']);
				if (transaction.cblight__Value__c === undefined || isNaN(transaction.cblight__Value__c)) {
					console.error('☹ INVALID AMOUNT: "' + line['Amount'] + '" from the file line #' + line.sourceIndex);
					transaction.class = 'error';
				}
				if (transaction.cblight__Value__c >= -0.5 && transaction.cblight__Value__c <= 0.5) {
					console.error('☹ AMOUNT IS OUT OF LIMIT: "' + line['Amount'] + '" line #' + line.sourceIndex);
					return null;
				}

				const datePeriodStart = moveDateToStartOfMonth(line);
				//let dateX = line['Date'].split('/'); // 01 - 24 - 2022
				//transaction.TransactionDate__c = `${dateX[2]}-${dateX[0]}-${dateX[1]}`;
				transaction.TransactionDate__c = getDateInDatabaseFormat(line['Date']);

				let period = periodMap[datePeriodStart.slice(0, 7)];
				if (period) {
					transaction.cblight__CBPeriod__c = period.Id;
					transaction.cblight__CBPeriodName__c = period.Name;
				} else {
					//_message('warning', 'Invalid Period : ' + JSON.stringify(line));
					invalidPeriods[datePeriodStart.slice(0, 7)] = true;
					console.error('INVALID PERIOD: ' + datePeriodStart.slice(0, 7) + ' from the file line #' + line.sourceIndex);
					transaction.class = 'error';
					//throw new Error('BROKEN PERIOD ' + line['Date']);
				}

				let account = accountMap[line['Account']];
				if (account) {
					transaction.cblight__CBAccount__c = account.Id;
					transaction.cblight__CBAccountName__c = account.Name;
				} else {
					invalidAccounts[line['Account']] = true;
					console.error('☹ INVALID ACCOUNT: "' + line['Account'] + '" from the file line #' + line.sourceIndex);
					transaction.cblight__CBAccountName__c = line['Account'];
					transaction.class = 'error';
				}

				let className = line['Class'], department;
				Object.keys(departmentMap).forEach(cn => {
					if (department) return;
					if (className.includes(cn)) department = departmentMap[cn];
				});
				if (department) {
					transaction.cblight__CBDivision__c = department.Id;
					transaction.cblight__CBDivisionName__c = department.Name;
				} else {
					invalidClasses[line['Class']] = true;
					console.error('☹ INVALID CLASS: "' + line['Class'] + '" from the file line #' + line.sourceIndex);
					transaction.cblight__CBDivisionName__c = line['Class'];
					transaction.class = 'error';
				}

				let budgetYear = byMap[line['Date'].slice(6)];
				if (budgetYear) {
					transaction.cblight__CBBudgetYear__c = budgetYear;
				}

				transaction.sourceIndex = line.sourceIndex;
				transaction.Description__c = line['Memo/Description'];
				transaction.Name = line['Name'];

				//console.log(JSON.stringify(transaction));
				context.cbTransactions.push(transaction);
			} catch (e) {
				console.error(e);
				return null;
			}
		});
		console.error('INVALID CLASSES: ' + Object.keys(invalidClasses));
		console.error('INVALID ACCOUNTS: ' + Object.keys(invalidAccounts));
		console.error('INVALID Periods: ' + Object.keys(invalidPeriods));

	} catch (e) {
		_message('error', 'Actual Loader : LINE:' + brokenLine + ' : Convert File Lines to CB Transactions Error : ' + e);
	}
};

const sortErrorTransactionsFirst = () => {
	try {
		context.cbTransactions = context.cbTransactions.sort((a, b) => a.class === b.class ? 0 : (a.class ? -1 : 1));
	} catch (e) {
		_message('error', 'Sorting Report Lines Error : ' + e);
	}
};
const indexReportLines = () => {
	try {
		context.cbTransactions.forEach((t, i) => t.idx = i + 1);
	} catch (e) {
		_message('error', 'Index Report Lines Error : ' + e);
	}
};

const checkDuplicates = () => {
	try {
		const trMap = {};
		context.cbTransactions.forEach(t => {
			const trKey = t.cblight__CBDivision__c + t.cblight__CBAccount__c + t.cblight__Value__c + t.VendorId__c + t.TransactionDate__c;
			const theSameTr = trMap[trKey];
			if (theSameTr) {
				t.class = theSameTr.class = 'error';
				t.comment = 'Duplicate of line ' + theSameTr.sourceIndex;
				theSameTr.comment = 'Duplicate of line ' + t.sourceIndex;
			}
			trMap[trKey] = t;
		});
	} catch (e) {
		_message('error', 'Actual Loader : Check Duplicates Error : ' + e);
	}

};

const digitSlashPattern = /[^0-9/]/g;
const moveDateToStartOfMonth = (line) => {
	let dateStr = line['Date'];
	try {
		dateStr = dateStr.replace(digitSlashPattern, "");
		dateStr = dateStr.split('/');
		return formatDate(new Date(parseInt(dateStr[2]), parseInt(dateStr[0]) - 1, 1));
	} catch (e) {
		_message('error', `Actual Loader : Move Data to Start Month (${dateStr}) in line #${line.sourceIndex} Error : ${e}`);
	}
};

const moveDateToStartOfQuarter = (dateStr) => {
	try {
		return dateStr.replace('-02', '-01').replace('-03', '-01')
			.replace('-05', '-04').replace('-06', '-04')
			.replace('-08', '-07').replace('-09', '-07')
			.replace('-11', '-10').replace('-12', '-10');
	} catch (e) {
		_message('error', 'Actual Loader : Move Data to Start Q (' + dateStr + ') Error : ' + e);
	}
};


const getAccountMap = () => {
	return context.accounts.reduce((r, acc) => {
		r[acc.Name.split(' ')[0]] = acc;
		return r;
	}, {});
};

const getDepartmentNameList = () => {
	return context.departments.reduce((r, div) => {
		r[div.Name] = div;
		return r;
	}, {});
};

const getBYMap = () => {
	return context.periods.reduce((r, period) => {
		r[period.cblight__CBBudgetYear__r.Name] = period.cblight__CBBudgetYear__c;
		return r;
	}, {});
};

const getPeriodMap = () => {
	return context.periods.reduce((r, period) => {
		r[period.cblight__Start__c.substring(0, period.cblight__Start__c.length - 3)] = period;
		return r;
	}, {});
};

const generateReport = () => {
	context.report.push(`Number of transactions: ${context.cbTransactions.length} `);
	const linesWithError = context.cbTransactions.reduce((r, line) => {
		if (line.class === 'error') r++;
		return r;
	}, 0);
	context.report.push(`Transactions with an error: ${linesWithError} `);
	context.report = _getCopy(context.report);
};

const generateTotalLine = () => {
	context.totalLine = {cblight__Value__c: 0, idx: '', Name: 'TOTAL'};
	context.cbTransactions.forEach(t => {
		context.totalLine.cblight__Value__c += +t.cblight__Value__c;
	});
};

/////////////////// PRIVATE METHODS ////////////////
const splitByComa = (line) => {
	try {
		let insideQuote = false, r = [], v = [];
		line.split('').forEach(function (character) {
			if (character === '"') {
				insideQuote = !insideQuote;
			} else {
				if (character === "," && !insideQuote) {
					r.push(v.join(''));
					v = [];
				} else {
					v.push(character);
				}
			}
		});
		r.push(v.join(''));
		return r;
	} catch (e) {
		_message('error', 'Actual Loader : Split by Coma Error : ' + e);
	}
};
const formatDate = (date) => {
	let month = '' + (date.getMonth() + 1), day = '01', year = date.getFullYear();
	if (month.length < 2) month = `0${month}`;
	return [year, month, day].join('-');
};
const setManagedAmount = (line, transaction) => {
	let amountStr = line['USD Amount'];
	amountStr = amountStr.trim().replace(/,/g, "");
	if (amountStr.includes('(')) amountStr = amountStr.replace('(', '-').replace(')', '');
	amountStr = amountStr === '-' ? 0 : amountStr;
	let r = parseFloat(amountStr);
	if (r === undefined || Number.isNaN(r)) {
		transaction.class = 'error';
		transaction.comment = 'Wrong amount';
		r = 'ERROR';
	}
	transaction.cblight__Value__c = r;
};
const populateTransactionWith = (type, map, line, field, transaction) => {
	let value = field === 'Subaccount' ? line[field].split('-')[1] : line[field];
	let record = map[value];
	if (!record) record = {Id: 'N/A', Name: `⚠️ No Such ${type} in the System mapped to "${line[field]}"`, error: true};
	transaction[`cblight__CB${type}__c`] = record.Id;
	transaction[`cblight__CB${type}Name__c`] = record.Name;
	if (record.error) {
		transaction.class = 'error';
		transaction.comment = 'Wrong ' + type;
	}
};

function convertExcelDateToJSDate(excelDate) {
	try {
		if (!excelDate) return null;
		let utc_days = Math.floor(excelDate - 25569);
		let utc_value = utc_days * 86400;
		let date_info = new Date(utc_value * 1000);
		let fractional_day = excelDate - Math.floor(excelDate) + 0.0000001;
		let total_seconds = Math.floor(86400 * fractional_day);
		let seconds = total_seconds % 60;
		total_seconds -= seconds;
		let hours = Math.floor(total_seconds / (60 * 60));
		let minutes = Math.floor(total_seconds / 60) % 60;
		let date = new Date(date_info.getFullYear(), date_info.getMonth(), date_info.getDate(), hours, minutes, seconds);
		let month = '' + (date.getMonth() + 1), day = '' + date.getDate(), year = date.getFullYear();
		if (month.length < 2) month = `0${month}`;
		if (day.length < 2) day = `0${day}`;
		return [year, month, day].join('-');
	} catch (e) {
		_message('error', 'Actual Loader : Convert Excel Date to JS Date Error : ' + e);
	}
};

const getDateInDatabaseFormat = (dateString) => {
	const dateParts = dateString.split('/');
	const day = dateParts[1].padStart(2, '0');
	const month = dateParts[0].padStart(2, '0');
	const year = dateParts[2];
	return `${year}-${month}-${day}`;
};

/////////////////// PRIVATE METHODS ////////////////

export {
	convertFileToObjects,
	convertFileLinesToCBTransactions,
	generateReport,
	generateTotalLine,
	sortErrorTransactionsFirst,
	indexReportLines,
	checkDuplicates
}