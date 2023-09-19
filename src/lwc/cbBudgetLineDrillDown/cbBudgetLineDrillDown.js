import {api, LightningElement, track} from "lwc";
import getLinksServer from "@salesforce/apex/CBBudgetLinePageController.getDrillDownLinksServer";
import {_message, _parseServerError, _cl} from 'c/cbUtils';

export default class CbBudgetLineDrillDown extends LightningElement {

	@track showSpinner = false;
	@track columnList = [];
	@track drillDownList = [];
	@track showContent = false;
	@track showLinks = false;
	@api parameters = ''; // list of DD Ids


	connectedCallback() {
		if (!this.parameters || this.parameters.length === 0) return;
		if (Array.isArray(this.parameters)) this.parameters = this.parameters.join(',');
		this.getLinks();
	}

	/**
	 * Method gets data for DrillDown
	 */
	getLinks() {
		this.showSpinner = true;
		this.showContent = false;
		this.drillDownList = [];
		//"a0D17000007aSjcEAE","a0F1700000JT4x9EAD"
		if (!this.parameters || this.parameters.length < 2) {
			this.showSpinner = false;
			return null;
		}
		getLinksServer({objectIds: this.parameters.split(',')})
			.then(links => {
				if (!links || links.length === 0) return;
				this.setSourceData(links);
				this.showContent = true;
			})
			.catch(e => _parseServerError("BLM : Drill Down : Get Drill Down Data Error: ", e))
			.finally(() => this.showSpinner = false)
	}

	/**
	 * Method creates column headers for DD
	 */
	setSourceData = (links) => {
		const columnsMap = {};
		const columnTitle = (field) => field.replace('cblight__', '').replace('__c', '').replace('_', ' ');

		links.forEach(obj => {

			for (let f of Object.keys(obj)) {
				if (f === 'Id' || f === 'Name') continue;
				if (f === 'Amount') {
					obj.cblight__Value__c = obj[f];
					delete obj[f];
					f = 'cblight__Value__c';
				}
				columnsMap[f] = columnTitle(f);
			}
		});

		this.columnList = Object.values(columnsMap);
		this.setSourceValues(links, Object.keys(columnsMap));
	};

	/**
	 * Method manages amounts in each DD Line
	 */
	setSourceValues = (links, fieldsList) => {
		try {
			const isDate = (date) => !date && date.length > 0 && date.includes('-') && date.includes(':');
			const isId = (idString) => ((idString.length === 15 || idString.length === 18)) && idString.includes('0000');

			links.forEach(l => {
				const values = [];

				fieldsList.forEach(col => {
					const v = l[col] === 0 || l[col] ? l[col] : '';
					const valueIsDate = isDate(v);
					const valueIsText = !valueIsDate && isNaN(v);
					values.push({val: v, isDate: valueIsDate, isCurrency: !isNaN(v), isText: valueIsText});
				});
				l.Name = isId(l.Name) ? 'Source' : l.Name.substring(0, 30);
				l.values = values;
				l.link = '/' + l.Id;
			});

			this.drillDownList = links;
		} catch (e) {
			_message('error', 'DD : Update Values Error : ' + e);
		}
	};

}