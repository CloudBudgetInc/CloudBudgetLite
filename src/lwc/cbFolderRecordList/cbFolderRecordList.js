import { LightningElement, api } from "lwc";
import { _generateFakeId, _isInvalid, _getCopy, _cl } from "c/cbUtils";
import getRecordsOfFolderServer from "@salesforce/apex/CBFolderController.getRecordsOfFolderServer";

export default class CbFolderRecordList extends LightningElement {
	showSpinner = false;
	@api folderType;
	folderIdValue;
	@api get folderId() {
		return this.folderIdValue;
	}
	set folderId(value) {
		this.folderIdValue = value;
		this.doInit();
	}
	recordList = [];

	async doInit() {
		this.showSpinner = true;
		const recordListJSON = await getRecordsOfFolderServer({folderType:this.folderType, folderId:this.folderId}).catch((e) => {
			_parseServerError("Folder Records List : Get Records of Folder Error : ", e);
		});
		if (recordListJSON) {
			let recordList = JSON.parse(recordListJSON);
			recordList.forEach((item, index) => {
				item.index = (index + 1) + '. ';
			});
			this.recordList = recordList;
		}
		this.showSpinner = false;
	}
}