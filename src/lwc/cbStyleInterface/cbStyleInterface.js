import { LightningElement, track} from "lwc";
import { _cl, _isInvalid, _message, _parseServerError } from "c/cbUtils";
import saveStyleServer from "@salesforce/apex/CBStyleService.saveStyleServer";
import deleteStyleServer from "@salesforce/apex/CBStyleService.deleteStyleServer";
import getSelectedStyleServer from "@salesforce/apex/CBStylePageController.getSelectedStyleServer";
import getStylesServer from "@salesforce/apex/CBStylePageController.getStylesServer";

export default class CbStyleInterface extends LightningElement {
	@track showSpinner = false;
	@track style = [];
	@track styleList = [];
	@track isModalOpen = false;
	@track isCloneSaveNewDeleteButtonActive = false;
	styleFields = ["Name", "cblight__Color__c", "cblight__BackgroundColor__c", "cblight__FontWeight__c", "cblight__Font__c", "cblight__State__c"];
	fontWeights = [
		{ label: "Normal", value: "normal" },
		{ label: "Bold", value: "bold" },
		{ label: "Lighter", value: "lighter" }
	];
	fontFamilys = [
		{ label: "Sans-serif", value: "sans-serif" },
		{ label: "Arial", value: "Arial" },
		{ label: "Helvetica", value: "Helvetica" },
		{ label: "Roboto", value: "Roboto" },
		{ label: "Open Sans", value: "Open Sans" }
	];
	state = [
		{ label: "Enable input", value: "auto" },
		{ label: "Disable input", value: "none" }
	];

	connectedCallback() {
		this.getStyles();
		document.title = "Style Setup";
	}

	/**
	 * Method get Styles list
	 */
	getStyles() {
		try {
			getStylesServer()
				.then((styleList) => {
					if (_isInvalid(styleList)) {
						alert("No Objects");
						return null;
					}
					styleList.forEach((style) => (style.cssName = style.Name.replace(/ /g, "")));
					this.styleList = styleList;
					this.addIndexToList();
					this.applyStyles();
				})
				.catch((e) => {
					alert("styleList callback Error: " + JSON.stringify(e));
				});
		} catch (e) {
			alert("styleList Error: " + JSON.stringify(e));
		}
	}

	/**
	 * Method get Style by Id
	 */
	getSelectedStyle(rId) {
		try {
			getSelectedStyleServer({ rId })
				.then((selectedStyle) => {
					if (_isInvalid(selectedStyle)) {
						alert("No Objects");
						return null;
					}
					if (this.styleFields.some((field) => _isInvalid(selectedStyle[field]))) {
						this.addDefaultValuesToStyle();
					}
					this.style = selectedStyle;
					this.style.styleСSSName = selectedStyle["Name"].replace(/ /g, "");
					this.isModalOpen = true;
					this.isCloneSaveNewDeleteButtonActive = true;
				})
				.catch((e) => {
					alert("getSelectedStyle callback Error: " + e);
				});
		} catch (e) {
			alert("getSelectedStyle Error: " + JSON.stringify(e));
		}
	}

	/**
	 * Method save Style to server
	 */
	saveStyle(action) {
		const style = this.style;
		if (this.styleFields.some((field) => _isInvalid(style[field]))) {
			_message('warning', 'Fill in the fields', 'Note!');
			return null;
		}
		if (style.Name.match(/[^a-zA-Z0-9 ]/g)) {
			_message('warning', 'Special characters are not allowed in the style name', 'Note!');
			return null;
		}
		for (const item of this.styleList) {
			const nameExists = item.Name === style.Name;
			const idInvalid = _isInvalid(style.Id);
			if (nameExists && idInvalid) {
			  _message('warning', 'The style with this name already exists, please enter a different name', 'Note!');
			  return null;
			}
			if (nameExists && item.Id !== style.Id) {
			  _message('warning', 'The style with this name already exists, please enter a different name', 'Note!');
			  return null;
			}
		}
		this.showSpinner = true;
		saveStyleServer({ style })
			.then(Id => {
				this.getStyles();
				if (action === "new") {
					this.addDefaultValuesToStyle();
					this.style.styleСSSName = "";
					_message("success", "Style Saved Successfully, Сreate New ");
					return null;
				}
				this.getSelectedStyle(Id);
				_message("success", "Style Saved Successfully");
			})
			.catch((error) => {
				_parseServerError('Style Interface : save Style ', error);
			})
			.finally(() => this.showSpinner = false);
	}

	/**
	 * Method handle input change
	 */
	handleChange(event) {
		try {
			this.styleFields.forEach((item) => {
				if (item === event.target.dataset.id) {
					this.style[item] = event.target.value;
				}
			});
		} catch (e) {
			alert("handleChange Error: " + e);
		}
	}

	/**
	 * Method apply css to html
	 */
	applyStyles() {
		try {
			let styleArray = this.styleList;
			let styleCSS = document.createElement("style");
			styleCSS.type = "text/css";
			styleCSS.innerHTML = styleArray.reduce((str, style) => {
				str = str + "." + style.Name.replace(/ /g, "") + " " + style.cblight__CSS__c + " ";
				return str;
			}, "");
			document.getElementsByTagName("head")[0].appendChild(styleCSS);
		} catch (e) {
			alert("styleCSS ERROR: " + JSON.stringify(e));
		}
	}

	toggleModal() {
		this.isModalOpen = !this.isModalOpen;
		if(!this.isModalOpen) {
			this.style = {};
			this.isCloneSaveNewDeleteButtonActive = false;
		}
	}

	/**
	 * Method opens style in modal window
	 */
	openStyle(event) {
		const rId = event.target.dataset.id;
		rId ? this.getSelectedStyle(rId) : this.addDefaultValuesToStyle();
		this.toggleModal();
	}

	/**
	 * Method delete style in modal window
	 */
	deleteStyle() {
		try {
			const styleId = this.style.Id;
			if (_isInvalid(styleId)) {
				this.toggleModal();
				return null;
			}
			if (!confirm("Do you want to delete style?")) return null;
			deleteStyleServer({ styleId })
				.then(() => {
					this.getStyles();
					_message("info", "Style deleted");
					this.toggleModal();
				})
				.catch((e) => _parseServerError("CB Style Interface : deleteStyleServer callback Error: ", e));
		} catch (e) {
			alert("deleteStyleServer Error: " + JSON.stringify(e));
		}
	}

	/**
	 * Method clone style in modal window
	 */
	cloneStyle() {
		try {
			this.style.Name = this.style.Name + " Cloned";
			delete this.style.Id;
			this.saveStyle();
		} catch (e) {
			alert("cloneStyle Error: " + e);
		}
	}

	/**
	 * Method save/new style in modal window
	 */
	saveNewStyle() {
		try {
			this.saveStyle("new");
		} catch (e) {
			alert("Save/New Style Error: " + e);
		}
	}

	/**
	 * Method add index field to list
	 */
	addIndexToList() {
		this.styleList.forEach((s, i) => (s.index = i + 1));
	}

	/**
	 * Method add default fields to style
	 */
	addDefaultValuesToStyle() {
		this.style = {
			Name: 'New',
			cblight__Color__c: "#000000",
			cblight__BackgroundColor__c: "#FFFFFF",
			cblight__FontWeight__c: "normal",
			cblight__Font__c: "sans-serif",
			cblight__State__c: "auto" 
		};
	}
}