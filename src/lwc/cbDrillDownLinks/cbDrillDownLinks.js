import {api, LightningElement, track} from 'lwc';
import getLinksServer from "@salesforce/apex/CBReportingDrillDownPageController.getLinksServer";
import {_parseServerError} from 'c/cbUtils';


export default class CbDrillDownLinks extends LightningElement {

	@api ids;
	@track links = [];
	@track showTable = false;
	DEFAULT_NAME = 'Source';


	connectedCallback() {
		if (!this.ids || this.ids.length === 0) return;
		this.getLinks();
	}

	/**
	 * list of any type records related to DD
	 */
	getLinks() {
		this.showTable = false;
		getLinksServer({objectIds: this.ids})
			.then(objects => { // it can be any type sObjects
				objects.forEach(o => {
					o.link = '/' + o.Id;
					o.Name = this.isId(o.Name) ? this.DEFAULT_NAME : o.Name;
				});
				this.links = objects;
				this.showTable = true;
			})
			.catch(e => _parseServerError('DrillDown Links : Get Links Error', e));
	}

	/**
	 * Method detects if record name is ID
	 * @param str
	 * @returns {boolean}
	 */
	isId = (str) => { // TODO: Make something smarter
		return (str.length === 15 || str.length === 18) && str.startsWith('a') && str.includes('000');
	};
}