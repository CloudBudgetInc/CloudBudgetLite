import {api, LightningElement} from 'lwc';
import {_reduceErrors} from 'c/cbUtils';
import noDataIllustration from './templates/noDataIllustration.html';
import inlineMessage from './templates/inlineMessage.html';

export default class CbErrorPanel extends LightningElement {
	/** Single or array of LDS errors */
	@api errors;
	/** Generic / user-friendly message */
	@api friendlyMessage = 'Error retrieving data';
	/** Type of error message **/
	@api type;

	viewDetails = false;

	get errorMessages() {
		return _reduceErrors(this.errors);
	}

	handleShowDetailsClick() {
		this.viewDetails = !this.viewDetails;
	}

	render() {
		if (this.type === 'inlineMessage') return inlineMessage;
		return noDataIllustration;
	}

}