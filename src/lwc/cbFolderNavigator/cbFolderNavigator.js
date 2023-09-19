import { LightningElement, api } from "lwc";
import getFoldersByTypeServer from "@salesforce/apex/CBFolderController.getFoldersByTypeServer";
import deleteFolderServer from "@salesforce/apex/CBFolderController.deleteFolderServer";
import { _generateFakeId, _message, _isInvalid, _getCopy, _cl } from "c/cbUtils";

export default class CbFolderNavigator extends LightningElement {
	rootFolderName = "ROOT FOLDER";
	numberOfRecordsInFolder = 0;
	@api type;
	selectedValue = null;
	get selected() {
		return this.selectedValue;
	}
	set selected(value) {
		this.selectedValue = value;
	}
	treeList = [];
	rawList;
	pathList = [];
	pathMap = {};

	showSpinner = false;
	showDialog = false;

	connectedCallback() {
		this.doInit();
	}

	async doInit() {
		this.showSpinner = true;
		let rawList = await getFoldersByTypeServer({ type: this.type }).catch((e) => {
			_parseServerError("Folder Navigator : Get Folders Error : ", e);
		});
		this.rawList = rawList;
		let selected = localStorage.getItem(this.type + " Folder");
		if (!selected || selected === 'undefined' || selected === 'null') {
			selected = null;
		}
		this.selected = selected;
		this.sendEvent();
		this.pathMap = {};
		this.treeList = [{ label: this.rootFolderName, name: null, expanded: true, items: this.convertRawFolderList(rawList, null, 0).items }];
		this.formPath();
		this.showSpinner = false;
	}

	formPath() {
		let resultList = [{ label: this.rootFolderName, value: null }];
		Object.values(this.pathMap).forEach((pathItem) => {
			resultList.push({ label: pathItem.label, value: pathItem.name });
		});
		this.pathList = resultList;
	}

	convertRawFolderList(list, parentElement, lvl) {
		let result = { active: false, items: [] };
		const parentId = parentElement ? parentElement.Id : undefined;
		if (parentId === this.selected) {
			result.active = true;
		}
		if (list && list.length > 0) {
			let i = list.length;
			while (i--) {
				const element = list[i];
				if (element.cblight__CBFolder__c === parentId) {
					const item = {
						label: element.Name,
						name: element.Id,
						expanded: true,
						items: []
					};
					let list2 = list.filter((el) => {
						return element.Id !== el.Id;
					});
					let innerResult = this.convertRawFolderList(list2, element, lvl + 1);
					item.items = innerResult.items;
					item.expanded = true;
					result.items.push(item);
					if (innerResult.active) {
						result.active = true;
						let pathMapCopy = _getCopy(this.pathMap);
						pathMapCopy[lvl] = {label:item.label, name:item.name};
						this.pathMap = pathMapCopy;
					}
				}
			}
		}
		return result;
	}

	handleSelect(event) {
		console.log(event);
		const name = event.detail.name;
		this.selected = name;
	}

	selectFolder() {
		localStorage.setItem(this.type + " Folder", this.selected);
		this.closeWindow();
		this.doInit();
	}

	sendEvent() {
		this.dispatchEvent(new CustomEvent("folderselected", { detail: { selected: this.selected } }));
	}

	pathFolderSelected(event) {
		console.log(event);
		try {
			let folderId = event.target.dataset.value;
			if (!folderId || folderId === 'undefined') {
				folderId = null;
			}
			this.selected = folderId;
			localStorage.setItem(this.type + " Folder", this.selected);
			this.selectFolder();
		} catch(e) {
			alert(e);
		}

	}

	async deleteFolder() {
		if (this.selected === "null" || this.selected === null) {
			_message("error", "You can't delete root folder!");
			return;
		}
		if (!confirm("Are you sure you want to delete selected folder? All child folders and records (if any exists) will be moved to the root folder.")) {
			return;
		}
		this.showSpinner = true;
		await deleteFolderServer({ folderId: this.selected }).catch((e) => {
			_parseServerError("Folder Navigator :Delete Folder Error : ", e);
		});
		_message('success', 'Deleted');
		this.selected = null;
		localStorage.setItem(this.type + " Folder", this.selected);
		this.doInit();
	}

	openWindow() {
		this.showDialog = true;
	}

	closeWindow() {
		this.showDialog = false;
	}
}