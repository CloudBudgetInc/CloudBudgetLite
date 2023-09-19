import { api, LightningElement, track } from "lwc";
import { _cl, _isInvalid, _message } from "c/cbUtils";

export default class CbModelingRuleLine extends LightningElement {
	@track sourceParentFieldSO = [];
	@track sourceChildFieldSO = [];
	@track resultParentFieldSO = [];
	@track resultChildFieldSO = [];

	get DefaultOptions() {
		return [
            { label: 'Specify Default', value: this.line.cblight__SpecifyDelfault__c },
            { label: 'Rachel', value: 'option2' },
        ];
	}
	
	get selectedFromSO() {
		let result = [{ value: "Parent", label: "Parent" }];
		try {
			if (this.modelingRule.cblight__SourceRecordChildType__c) {
				result.push({ value: "Child", label: "Child" });
			}
		} catch(e) {
			_message("error", "MRL : selectedFromSO Error " + e);
		}
		return result;
	}

	get selectedToSO() {
		let result = [{ value: "Parent", label: "Parent" }];
		try {
			if (this.modelingRule.cblight__ResultRecordChildType__c) {
				result.push({ value: "Child", label: "Child" });
			}
		} catch(e) {
			_message("error", "MRL : selectedToSO Error " + e);
		}
		return result;
	};

	@track showParentSource = true;
	@track showParentResult = true;
	@track resultSobjectTypeForDefault = "-";
	@track resultFromDisabled = false;
	@track showUserDropDownInDefaultSection = false;

	@api line = {}; // one line = one component
	@api modelingRule = {};
	@api usersAndQueues = []; // list of SO

	/**
	 * Map with source and result, parent and child field names
	 */
	@api
	get fieldMap() {}

	set fieldMap(value) {
		["sourceParentFieldSO", "sourceChildFieldSO", "resultParentFieldSO", "resultChildFieldSO"].forEach((f) => (this[f] = value[f]));
	}

	getSourceParentSelect(hasChild) {
		let result = [{ value: "Parent", label: "Parent" }];
		if (hasChild) {
			result.push({ value: "Child", label: "Child" });
		}
		return result;
	}

	/**
	 * DropDown with fields might show parent or child sObject fields depends on selected
	 */
	manageRenderingSObjectLists() {
		try {
			this.showParentSource = "Parent".includes(this.line.cblight__SourceFieldFrom__c);
			this.showParentResult = "Parent".includes(this.line.cblight__ResultFieldFrom__c);
			this.resultSobjectTypeForDefault = "Parent".includes(this.line.cblight__ResultFieldFrom__c)
				? this.modelingRule.cblight__ResultRecordParentType__c
				: this.modelingRule.cblight__ResultRecordChildType__c;
			const resultFields = this.showParentResult ? this.resultParentFieldSO : this.resultChildFieldSO;
			const selectedFieldSO = !_isInvalid(resultFields) ? resultFields.find((item) => item.value === this.line.cblight__ResultField__c) : null;
			if (!_isInvalid(selectedFieldSO)) {
				this.showUserDropDownInDefaultSection = selectedFieldSO.detail === "Group" || selectedFieldSO.detail === "User";
			} else {
				_message("warning", "Line " + this.line.index + " has an unassigned field, most likely due to the changed Source of Result sObjects. Please select a valid value");
			}
		} catch (e) {
			_message("error", "MRL : Manage Rendering SObject Lists Error " + e);
		}
	}

	/**
	 * Handle all changes in modeling line
	 */
	handleLineChanges(event) {
		try {
			let skipCheck = false,
				eraseDefault = false;
			let line = JSON.parse(JSON.stringify(this.line));
			["Name", "cblight__SourceFieldFrom__c", "cblight__ResultFieldFrom__c", "cblight__SourceField__c", "cblight__ResultField__c", "cblight__Default__c"].forEach((f) => {
				if (skipCheck) return;
				if (f.includes(event.target.name)) {
					line[f] = event.target.value;
					skipCheck = true;
					eraseDefault = ["cblight__ResultFieldFrom__c", "cblight__ResultField__c"].includes(event.target.name);
				}
			});
			if (["cblight__SpecifyDefault__c"].includes(event.target.name)) line[event.target.name] =  event.target.checked;
			
			if (eraseDefault) line.cblight__Default__c = null;
			this.line = line;
			this.updateLineType(); // specify type of field (REFERENCE, DECIMaL, STRING) and add the error message if needed
			this.sendLineToModelingRuleComponent();
			this.manageRenderingSObjectLists();
		} catch (e) {
			_message("error", "MRL : Handle Line Change Error " + e);
		}
	}

	/**
	 * Can be called from the parent component
	 */
	@api
	updateLineType() {
		try {
			let line = JSON.parse(JSON.stringify(this.line));
			const sourceType = this.getLineFieldType(line, true);
			const resultType = this.getLineFieldType(line, false);
			line.error = !_isInvalid(sourceType) && !_isInvalid(resultType) && sourceType === resultType ? null : "Types are not compatible";
			line.cblight__Type__c = resultType;
			this.line = line;
		} catch (e) {
			_message("error", "MRL : Update Line Type Error " + e);
		}
	}

	handleDefaultChanges(event) {
		try {
			let lineCopy = JSON.parse(JSON.stringify(this.line));
			lineCopy.cblight__Default__c = event.target.value;
			this.line = lineCopy;
			this.sendLineToModelingRuleComponent();
		} catch (e) {
			_message("error", "MRL : Handle Default Change Error " + e);
		}
	}

	/**
	 * Updates must be passed to the parent component
	 */
	sendLineToModelingRuleComponent() {
		this.dispatchEvent(new CustomEvent("passModelingRuleLine", { bubbles: true, composed: true, detail: this.line }));
	}

	deleteModelingLine() {
		if (!confirm("Are you sure?")) {
			return null;
		}
		this.dispatchEvent(
			new CustomEvent("deleteModelingRuleLine", {
				bubbles: true,
				composed: true,
				detail: this.line.Id
			})
		);
	}

	connectedCallback() {
		this.manageRenderingSObjectLists();
		document.title = "Modeling Rule Line";
	}

	/////// PRIVATE METHODS ///////
	/**
	 * @param line MRL
	 * @param isSource true if needed for the source line
	 * @return type of a field (REFERENCE, STRING, DECIMAL etc.)
	 */
	getLineFieldType(line, isSource) {
		try {
			let listSO;
			const searchField = isSource ? "cblight__SourceField__c" : "cblight__ResultField__c";
			if (isSource) {
				if (line.cblight__SourceFieldFrom__c === "Parent") {
					listSO = this.sourceParentFieldSO;
				} else {
					if (this.modelingRule.cblight__SourceRecordChildType__c) {
						listSO = this.sourceChildFieldSO;
					}
				}
			} else {
				if (line.cblight__ResultFieldFrom__c === "Parent") {
					listSO = this.resultParentFieldSO;
				} else {
					if (this.modelingRule.cblight__ResultRecordChildType__c) {
						listSO = this.resultChildFieldSO;
					}
				}
			}
			let selectedSO = { type: null };
			if (listSO) {
				const selectedSOFind = listSO.find((item) => line[searchField] === item.value);
				if (selectedSOFind) selectedSO = selectedSOFind;
			}
			return selectedSO.type;
		} catch (e) {
			_message("error", "MRL : Get Line Type Error : " + e);
		}
	}

	/////// PRIVATE METHODS ///////

	constructor() {
		super();

	}
}