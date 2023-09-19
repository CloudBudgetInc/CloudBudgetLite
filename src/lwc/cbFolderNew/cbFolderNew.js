import { LightningElement, api } from "lwc";
import CB_FOLDER_OBJECT from '@salesforce/schema/CBFolder__c';
import NAME_FIELD from '@salesforce/schema/CBFolder__c.Name';
import TYPE_FIELD from '@salesforce/schema/CBFolder__c.FolderType__c';
import PARENT_FOLDER_FIELD from '@salesforce/schema/CBFolder__c.CBFolder__c';
import { _parseServerError, _generateFakeId, _isInvalid, _getCopy, _cl, _message } from "c/cbUtils";

export default class CbFolderNew extends LightningElement {
	folderObject = CB_FOLDER_OBJECT;
	nameField = NAME_FIELD;
	typeField = TYPE_FIELD;
	parentFolderField = PARENT_FOLDER_FIELD;


	@api folderType;

	@api  parentFolderId;

	showDialog = false;
	showSpinner = false;

	openWindow() {
		this.showDialog = true;
	}
	closeWindow() {
		this.showDialog = false;
	}

	handleSuccess() {
		this.showDialog = false;
		this.dispatchEvent(new CustomEvent("folderadded"));
	}
}