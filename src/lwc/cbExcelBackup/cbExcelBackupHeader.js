import {_message, _setCell} from 'c/cbUtils';

let FIRST_ROW_FILL = {
	type: 'pattern',
	pattern: 'solid',
	fgColor: {argb: 'CACACA'}
};
let FIRST_ROW_FONT = {
	name: 'Arial Black',
	family: 2,
	size: 25
};

let SECOND_ROW_FILL = {
	type: 'pattern',
	pattern: 'solid',
	fgColor: {argb: 'CACACA'}
};
let SECOND_ROW_FONT = {
	name: 'Arial Black',
	family: 2,
	size: 14
};
let PAGE_INFO_ROW_FONT = {
	name: 'Arial Black',
	family: 2,
	size: 8
};
let PAGE_INFO_ROW_FILL = {
	type: 'pattern',
	pattern: 'solid',
	fgColor: {argb: '999999'}
};
/**
 * Method generates additional lines to cluster total
 */
const addHeader = (blSheet) => {
	try {
		const firstColumn = blSheet.getColumn(1);
		firstColumn.width = 40;
		for (let i = 2; i < 50; i++) blSheet.getColumn(i).width = 12;

		const firstRow = blSheet.getRow(1);
		firstRow.height = 30;
		firstRow.fill = FIRST_ROW_FILL;
		firstRow.font = FIRST_ROW_FONT;
		_setCell(firstRow.getCell(1), 'CLOUDBUDGET 3.0', FIRST_ROW_FILL, FIRST_ROW_FONT);

		const secondRow = blSheet.getRow(2);
		secondRow.fill = SECOND_ROW_FILL;
		secondRow.font = SECOND_ROW_FONT;
		_setCell(secondRow.getCell(1), 'Budget Manager', SECOND_ROW_FILL, SECOND_ROW_FONT);

		const pageInfoRow = blSheet.getRow(3);
		pageInfoRow.fill = PAGE_INFO_ROW_FILL;
		pageInfoRow.font = PAGE_INFO_ROW_FONT;
		pageInfoRow.height = 10;
		let labels = localStorage.getItem('displayedList');
		if (labels) {
			labels = JSON.parse(labels);
			let i = 2;
			labels.forEach(l => {
				_setCell(pageInfoRow.getCell(i), l.key + ':' + l.value, PAGE_INFO_ROW_FILL, PAGE_INFO_ROW_FONT);
				i += 3;
			});
		}
	} catch (e) {
		_message('error', 'Excel Backup : Add Header Error : ' + e);
	}
};

export {
	addHeader
};