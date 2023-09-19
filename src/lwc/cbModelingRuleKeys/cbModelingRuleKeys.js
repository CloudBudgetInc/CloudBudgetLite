import {api, LightningElement} from "lwc";
import {_message} from "c/cbUtils";

export default class cbModelingRuleKeys extends LightningElement {
	modelingRuleStorage;

	@api get modelingRule() {
		return this.modelingRuleStorage;
	}

	set modelingRule(rule) {
		this.modelingRuleStorage = rule;
		this.doInit();
	}

	fieldMapStorage;

	@api get fieldMap() {
		return this.fieldMapStorage;
	}

	set fieldMap(map) {
		this.fieldMapStorage = map;
		this.doInit();
	}

	showDialog = false;

	options = [];
	values = [];

	/**
	 *
	 * this function prepares lists of selected and available options from modeling rule
	 */
	doInit() {
		if (!this.modelingRule || !this.fieldMap) return;
		try {
			const modelingRule = this.modelingRule;
			const fieldMap = this.fieldMap;
			let selectedFields = [];
			let availableFields = [];
			if (modelingRule.cblight__KeyFields__c) {
				selectedFields = modelingRule.cblight__KeyFields__c.split(",");
			}
			Object.keys(fieldMap).forEach(key => {
				if (key.includes("result")) {
					const isParent = key.includes("Parent");
					fieldMap[key].forEach(field => {
						const newItem = {
							label: isParent ? field.label + " (Parent)" : field.label + " (Child)",
							value: field.value
						};
						availableFields.push(newItem);
					});
				}
			});
			this.options = availableFields;
			this.values = selectedFields;
		} catch (e) {
			_message('error', 'MRK : Keys Init Error: ' + e);
			console.error(e);
		}
	}

	/**
	 *
	 * @param {*} event event from multiselect
	 */
	handleChange(event) {
		const selectedOptionsList = event.detail.value;
		this.values = selectedOptionsList;
		const evt = new CustomEvent("keyschanged", {detail: {keys: selectedOptionsList.join(",")}});
		this.dispatchEvent(evt);
	}

	switchDialog() {
		this.showDialog = !this.showDialog;
	}
}