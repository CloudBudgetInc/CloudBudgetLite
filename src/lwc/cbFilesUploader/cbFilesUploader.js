import {api, LightningElement, track} from 'lwc';
import saveFileServer from '@salesforce/apex/CBFilesUploaderPageController.saveFileServer';
import relatedFilesServer from '@salesforce/apex/CBFilesUploaderPageController.getRelatedFilesServer';
import deleteFileServer from '@salesforce/apex/CBFilesUploaderPageController.deleteFileServer';
import {_cl, _parseServerError, _isInvalid, _message} from 'c/cbUtils';
import {NavigationMixin} from "lightning/navigation";

export default class cbFilesUploader extends NavigationMixin(LightningElement) {

	@api recordId;
	@track showSpinner = false;
	@track relatedFiles;
	@track isComponentVisible = false;
	file = {};
	fileReader;
	fileContents;
	content;

	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		this.checkDataForRunComponent();
	}

	/**
	 * Method check is the data valid to run component and display on page
	 * @returns {boolean} : true - display component on page and run other methods
	 */
	checkDataForRunComponent() {
		if (!_isInvalid(this.recordId)) {
			this.isComponentVisible = true;
			this.getRelatedFiles();
		}
	}

	/**
	 * Get only one file at once
	 */
	handleGetFile(event) {
		
		
		if (event.target.files.length > 0) {
			this.file = event.target.files[0];
			if (this.file.size >= 3000000) {
				_message('warning', 'The file size cannot exceed 3 MB');
				return null;
			}
		}
		this.prepareFileReader();
	}

	/**
	 * File Reader preparing
	 */
	prepareFileReader() {
		this.showSpinner = true;
		this.fileReader = new FileReader();

		this.fileReader.onloadend = (() => {
			this.fileContents = this.fileReader.result;
			let base64 = 'base64,';
			this.content = this.fileContents.indexOf(base64) + base64.length;
			this.fileContents = this.fileContents.substring(this.content);

			this.saveFile();
		});

		this.fileReader.readAsDataURL(this.file);
	}

	/**
	 * Insert the selected file to the DB
	 */
	saveFile() {
		saveFileServer({
			idParent: this.recordId,
			strFileName: this.file.name,
			base64Data: encodeURIComponent(this.fileContents)
		})
			.then(() => {
				_message('success', 'File Successfully Uploaded!');
				this.getRelatedFiles();
			})
			.catch(error => _parseServerError('An error occurred while uploading file', error))
			.finally(() => this.showSpinner = false);
	}

	/**
	 * Getting related files of the current record
	 */
	getRelatedFiles() {
		relatedFilesServer({idParent: this.recordId})
			.then(result => {
				this.relatedFiles = result;
			})
			.catch(error => _parseServerError('An error occurred while downloading the related files list.', error));
	}

	/**
	 * Starting the preview mode to see more details about the file.
	 * In preview mode you can download file
	 */
	previewHandler(event) {
		this[NavigationMixin.Navigate]({
			type: 'standard__namedPage',
			attributes: {
				pageName: 'filePreview'
			},
			state: {
				selectedRecordId: event.target.dataset.id
			}
		})
	}

	/**
	 * Delete the selected file from the DB
	 */
	deleteFile(event) {
		if (!confirm('Do you really want to delete file?')) {
			return null;
		}
		this.showSpinner = true;
		deleteFileServer({fileId: event.target.value})
			.then(() => {
				this.getRelatedFiles();
				_message('info', 'File deleted.');
			})
			.catch(error => _parseServerError('An error occurred while file deleting.', error))
			.finally(() => this.showSpinner = false);
	}

}