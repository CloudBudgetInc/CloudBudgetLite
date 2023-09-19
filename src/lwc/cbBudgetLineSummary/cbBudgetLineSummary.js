import {api, LightningElement, track} from "lwc";
import {_applyDecStyle, _getCopy, _message, _cl} from "c/cbUtils";
import {generateTopdown} from "./cbBudgetLineSummaryTopdown";

export default class CbBudgetLine extends LightningElement {
	@api globalCluster = {};

	@api
	get topdownBudgetLines() {

	}

	set topdownBudgetLines(topdownList) {
		this.showTopdownToggle = topdownList && topdownList.length > 0 && localStorage.getItem('selectedApproach') !== 'topdown';
		this.tdBudgetLines = topdownList;
	}

	@api clusterRule = [];
	@api selectedBudgetYearPeriods = []; // DO NOT REMOVE IT
	@track tableData = [];
	@track originalTableData = [];
	@track tdBudgetLines = [];
	SPACE = '  ';
	@track isOpen = false;
	storageKey = 'budgetSummary';
	FIELDS_TO_REMOVE = ['cblight__isAllocation__c', 'CreatedById', 'LastModifiedById'];
	@track topdownOn = false;
	@track showTopdownToggle = false;
	OVER_SIZE_MESSAGE = 'The amount of data is too large to display the summary table. Try using a less detailed cluster rule or a data filter. Click ok to continue or click no if you want to continue the page loading';
	@track overSizeMode = false;
	@track overSizeAsked = false;

	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		this.doInit();
	}

	doInit = async () => {
		this.generateTableData();
		this.openSummary();
		_applyDecStyle();
		this.setBlSummaryStyles();
	};

	/**
	 * Method turns on or turns off topdown mode in summary
	 */
	toggleTopdown = () => {
		if (this.topdownOn) {
			this.tableData = this.originalTableData;
		} else {
			this.originalTableData = _getCopy(this.tableData);
			generateTopdown(this);
		}
		this.topdownOn = !this.topdownOn;
		localStorage.setItem('topdownOn', this.topdownOn.toString());
	};

	generateTableData = () => {
		try {
			this.tableData = [];
			const orgVariable = JSON.parse(localStorage.getItem("orgVariable"));
			const maxDisplayedLines = orgVariable.cblight__MaxNumberOfDisplayedLines__c;
			const setRowsFromCluster = (cluster, level) => {
				if (this.overSizeMode) return;
				const {totalLine, name, fullKey, childClusters} = cluster;
				const filteredTotalLine = Object.entries(totalLine)
					.filter(([field]) => !this.FIELDS_TO_REMOVE.includes(field))
					.reduce((acc, [field, value]) => ({...acc, [field]: value}), {});
				const indentedName = `${this.SPACE.repeat(level)}${name}`;
				const updatedTotalLine = {...filteredTotalLine, name: indentedName, level, fullKey};
				this.tableData.push(updatedTotalLine);
				if (this.tableData.length > maxDisplayedLines) {
					if (!this.overSizeAsked && confirm(this.OVER_SIZE_MESSAGE)) {
						this.overSizeAsked = true;
						this.overSizeMode = true;
					}
				}
				childClusters.forEach((cl) => setRowsFromCluster(cl, level + 1));
			};
			setRowsFromCluster(this.globalCluster, 0);
			this.indexLines(this.tableData);
		} catch (e) {
			_message("error", `Budget Line Summary: generate Table DataError: ${e}`);
		}
	};

	/**
	 * The method recalculate BLM Summary
	 */
	@api 
	recalculateBlmSummary = () => {
		this.doInit();
	};

	/**
	 * Method manages behavior of budget summary
	 */
	toggleOpenSummary = () => {
		try {
			this.isOpen = !this.isOpen;
			if (this.isOpen) {
				localStorage.setItem(this.storageKey, 'true');
			} else {
				delete localStorage.removeItem(this.storageKey);
			}
		} catch (e) {
			_message('error', 'Budget Summary : Handle Open/Close Error: ' + e);
		}
	};

	/**
	 * The method opens last state of accordions
	 */
	openSummary = () => {
		try {
			if (localStorage.getItem("showAll") === "true") {
				this.isOpen = true;
			} else {
				this.isOpen = localStorage.getItem(this.storageKey) === "true";
			}
		} catch (e) {
			_message("error", "Budget Summary : Open/Close Error: " + ee);
		}
	};

	setBlSummaryStyles() {
		try {
			const orgVariable = JSON.parse(localStorage.getItem('orgVariable'));
			if (!orgVariable) return;
			const summaryStyle = `slds-p-around_xxx-small `;
			for (let i = 0; i < this.tableData.length; i++) {
				const line = this.tableData[i];
				line.style = line.level === 0 ? [`summaryLine${orgVariable.cblight__DisplayBLMNavigation__c} ` + summaryStyle] : summaryStyle;
				const levelStyleClass = orgVariable[`cblight__BudgetLineLvl${line.level}Style__c`];
				if (levelStyleClass) {
					line.style += this.getStyleName(levelStyleClass);
				}
			}
		} catch (error) {
			_message('error', `BL Summary: set BL Summary Styles Error ${error}`);
		}
	}

	/**
	 * Method set style class for BL Summary
	 */
	getStyleName(Id) {
		let styles = JSON.parse(localStorage.getItem("cbstyles"));
		if (!styles) return "";
		return styles.find(style => style.Id === Id).Name.replace(/ /g, "");
	}

	/**
	 * On double click in summary this method hide all sections and open just needed
	 */
	openSelectedSection = (event) => {
		try {
			const selectedClusterKey = event.target.dataset.label;
			const parentChildSectionMap = {};
			const wholeSectionKeys = [];
			const setParentKeys = (cluster) => {
				for (let i = 0; i < cluster.childClusters.length; i++) {
					const childCluster = cluster.childClusters[i];
					wholeSectionKeys.push(childCluster.fullKey);
					parentChildSectionMap[childCluster.fullKey] = cluster.fullKey ? cluster.fullKey : '';
					setParentKeys(childCluster);
				}
			};
			setParentKeys(this.globalCluster);
			this.hideAllSections(wholeSectionKeys);
			this.showSelectedSections(selectedClusterKey, parentChildSectionMap);
			if (localStorage.getItem('showAll') === 'true') {
				localStorage.setItem('showAll', 'false');
			}
			this.refreshTable();
			localStorage.removeItem('budgetSummary');
		} catch (error) {
			_message('error', `Summary: Open Needed Section: ${error}`);
		}
	};


	hideAllSections = (wholeSectionKeys) => {
		wholeSectionKeys.forEach(k => localStorage.removeItem(`openedSections${k}`));
	};

	/**
	 *
	 * @param selectedClusterKey cluster keys that need to be open
	 * @param parentChildSectionMap mapping where key is section fullKey and value is parent fullKey
	 */
	showSelectedSections = (selectedClusterKey, parentChildSectionMap) => {
		let search = true, tmpKey = selectedClusterKey;
		let openedSections = [tmpKey];
		while (search) {
			const parentKey = parentChildSectionMap[tmpKey];
			if (parentKey === undefined) {
				search = false;
			} else {
				openedSections.push(parentKey);
				tmpKey = parentKey;
			}
		}
		openedSections.forEach(k => localStorage.setItem(`openedSections${k}`, 'true'));
	};


	/**
	 * Method refresh the base table in the parent component
	 */
	refreshTable = () => {
		this.dispatchEvent(new CustomEvent('refreshTable', {
			bubbles: true,
			composed: true,
			detail: '_'
		}))
	};

	/**
	 * Method add index to list
	 */
	indexLines = (table) => {
		let indexArray = [0];
		let s = '.';
		for (let i = 0; i < table.length; i++) {
			const line = table[i];
			indexArray = indexArray.slice(0, line.level);
			if (indexArray.length < line.level) {
				indexArray[line.level - 1] = 1;
			} else {
				++indexArray[line.level - 1];
			}
			line.name = indexArray.join(s) + ' ' + line.name;
		}
	};
}