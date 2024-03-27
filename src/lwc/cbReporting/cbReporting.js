import {api, LightningElement, track} from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getReportWithConfigurationsAndColumnsServer
	from "@salesforce/apex/CBReportingPageController.getReportWithConfigurationsAndColumnsServer";
import getReportDataServer from "@salesforce/apex/CBReportingPageController.getReportDataServer";
import getListOfCubeFieldsSOServer from "@salesforce/apex/CBReportingPageController.getListOfCubeFieldsSOServer";
import saveReportServer from "@salesforce/apex/CBReportingPageController.saveReportServer";
import saveConfigurationServer from "@salesforce/apex/CBReportingPageController.saveConfigurationServer";
import saveAllConfigurationsServer from "@salesforce/apex/CBReportingPageController.saveAllConfigurationsServer";
import saveColumnsServer from "@salesforce/apex/CBReportColumnPageController.saveColumnsServer";
import deleteReportConfigByConfigSOServer
	from "@salesforce/apex/CBReportingPageController.deleteReportConfigByConfigSOServer";
import getStaticDataServer from "@salesforce/apex/CBReportingPageController.getStaticDataServer";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import {_deleteFakeId, _generateFakeId, _getCopy, _isFakeId, _isInvalid, _message, _parseServerError, _cl} from 'c/cbUtils';
//import { manageCustomLookupFields, generateGlobalStructure, calculateBudgetLineTotal } from './cbBudgetLineManagerHelper';
import {generateReportColumns} from './cbReportingColumns';
import {manageMultiCurrency} from './cbReportingMultiCurrency';
import {generateReportLines} from './cbReportingLines';
import getStylesRecordsServer from "@salesforce/apex/CBBudgetLinePageController.getStylesRecordsServer";

export default class CbReporting extends  NavigationMixin(LightningElement) {
	@api  recordId;
	@api configuration;

	@track showSpinner = false;
	@track editReportMode = false;
	@track showReportConfiguration = false;
	@track showReportColumns = false;
	@track showDrillDown = false;
	@track showExcelButton = false;
	@track showConfigContext = false;
	@track report = {}; 	// CBReport
	@track reportData = []; // CBCube list
	@track cubeFieldsSO = [];
	@track usersAndQueues = [];
	@track subtotalsList = [];
	@track configuration = {};
	@track configurationSO = [];
	@track displayUnitSO = [
		{'label': 'Whole Units', 'value': 'Whole Units'},
		{'label': 'Thousands', 'value': 'Thousands'},
		{'label': 'Millions', 'value': 'Millions'}
	];
	@track DDParams = '';
	@track currencyCode = 'USD';
	@track BYIsQuarter = false;
	@track staticData = {}; // periodMap object is key - budget year, value: list of periods
	isConfigurationChanged = false;


	////// REPORT TABLE DATA /////
	@track reportGroupColumns = []; // left text columns
	@track reportColumns = []; 		// digital columns
	@track reportLines = [];
	@track orgVariable = {};
	@track reportSingleColumn = [];

	////// REPORT TABLE DATA /////

	constructor() {
		super();
		this.addEventListener('closeReportColumns', this.closeReportColumns);
		this.addEventListener('closeDrillDown', this.closeDrillDown);
		this.addEventListener('updateReportAfterSavingColumns', this.updateFullReport);
	}

	/**
	 * Do init
	 */
	async connectedCallback() {
		document.title = 'Report';
		this.showSpinner = true;
		this.getStaticData(); // run just once
		await this.getOrgVariable();
		await this.getListOfCBCubeFields(); //-> getReportWithConfigurationsAndColumns ->	this.getReportData();
	}

	get mainTableHeight() {
		return `height: ${document.documentElement.clientHeight - 178}px;`
	}

	/**
	 * The method gets the list of available items from group and set them as the list of subtotals.
	 */
	setSubtotals = () => {
		if (!this.configuration.cblight__Grouping__c) return null;
		let subtotals = [{label: 'None', value: 0}];
		this.configuration.cblight__Grouping__c.forEach((g, index) => {
			const cubeField = this.cubeFieldsSO.find(({value}) => value === g);
			if (cubeField) subtotals.push({label: cubeField.label, value: index + 1});
		});
		this.subtotalsList = subtotals;
	}

	/**
	 * Org variables for rendering
	 */
	getOrgVariable = async () => {
		await getOrgVariableServer()
			.then(variable => this.orgVariable = variable)
			.catch(e => _parseServerError('Reporting : Org Variables Error : ', e))
	};

	/**
	 * The main method to get report configuration
	 */
	getReportWithConfigurationsAndColumns = async () => {
		this.reportLines = this.reportGroupColumns = this.reportColumns = [];
		await getReportWithConfigurationsAndColumnsServer({reportId: this.recordId})
			.then(async reportStructure => {
				await this.manageReportStructure(reportStructure);
			})
			.catch(e => _message('error', "Reporting : Get Report Error: ", e))
	};

	/**
	 * The cache method to get a list of CBCube fields
	 */
	getStaticData() {
		getStaticDataServer()
			.then(staticData => {
				this.staticData = staticData;
				this.applyStyles();
			})
			.catch(e => _message('error', "Reporting : Get Static Data Error: ", e))
	}

	/**
	 * The method returns the list of CBCube fields
	 */
	getListOfCBCubeFields = async () => {
		try {
			const cubeFieldsSO = await getListOfCubeFieldsSOServer();
			const labelMap = {};
			for (const f of Object.keys(this.orgVariable)) {
				if (f.includes('Label')) {
					labelMap[f.replace('Label', '')] = this.orgVariable[f];
				}
			}
			for (const so of cubeFieldsSO) {
				so.label = labelMap[so.value] ? labelMap[so.value] : so.label;
			}
			this.cubeFieldsSO = _getCopy(cubeFieldsSO);
			await this.getReportWithConfigurationsAndColumns(); // -> this.getReportData();
		} catch (e) {
			_message('error', "Get List of CBCube Fields Error: ", e);
		}
	};

	/**
	 * The main method to get the list of CBCubes__c as a source data for the report
	 */
	getReportData = async () => {
		try {
			_deleteFakeId(this.configuration);
			let reportData = await getReportDataServer({configurationId: this.configuration.Id});
			this.showExcelButton = true;
			this.reportData = reportData;
			if (!this.reportData || this.reportData.length === 0) {
				_message('info', 'No Data');
				return null;
			}
			this.reportData = await manageMultiCurrency(this.reportData);
			if (this.reportData[0].CurrencyIsoCode) this.currencyCode = this.reportData[0].CurrencyIsoCode;
			const byId = this.reportData[0].cblight__CBBudgetYear__c;
			await this.generateReportGroupColumns();
			await generateReportColumns(byId, this);
			await generateReportLines(this);
			await this.removeHiddenColumns();
			await this.setStylesToAnalyticsColumns();
			await this.setStylesToAnalyticsColumnsGradient();
		} catch (e) {
			_message('error', 'Reporting : Get Report Data Callback Function Error : ' + e);
			_parseServerError("Reporting : Get Report Data Callback Error: ", e);
		} finally {
			this.showSpinner = false;
		}
	};

	/**
	 * Method removes hidden columns and cells
	 */
	removeHiddenColumns() {
		if (!this.reportColumns.some(col => col.isHidden)) {
			return;
		}
		this.reportColumns = this.reportColumns.filter(({isHidden}) => isHidden === false);
		this.reportLines.forEach(line => {
			line.reportCells = line.reportCells.filter(({isHidden}) => isHidden === false);
		});
	}

	/**
	 * Method saves current report
	 */
	saveReport() {
		this.showSpinner = true;
		this.editReportMode = false;
		let report = {Id: this.report.Id, Name: this.report.Name, cblight__Description__c: this.report.cblight__Description__c};
		saveReportServer({report})
			.catch(e => _parseServerError("Reporting : Save Report Error: ", e))
			.finally(() => this.showSpinner = false)
	}

	/**
	 * Method clone current report
	 */
	cloneReport = () => {
		if (!confirm("Do you want to clone current report with configurations and columns?")) {
			return null;
		}
		this.showSpinner = true;
		let report = { Name: this.report.Name + " Cloned",	cblight__Description__c: this.report.cblight__Description__c, 
			cblight__Mode__c: this.report.cblight__Mode__c, cblight__needOnlyTotal__c : this.report.cblight__needOnlyTotal__c,
			cblight__needQuarterTotals__c: this.report.cblight__needQuarterTotals__c};
		report.Name = report.Name.slice(0, 80);
		saveReportServer({ report })
			.then(async (result) => {
				this.recordId = result.Id;
				_message("success", "Report Cloned");
				if (this.report.cblight__CBReportConfigurations__r && this.report.cblight__CBReportConfigurations__r.length > 0) {
					await this.cloneAllConfigurations();
				}
				if (this.report.cblight__CBReportColumns__r && this.report.cblight__CBReportColumns__r.length > 0) {
					await this.cloneReportColumns(result);
				}
				this.navigateToRecordPage();
			})
			.catch((e) =>
				_parseServerError("Reporting : Clone Report Error: ", e)
			);
	};

	/**
	 * Method clone All Configurations
	 */
	cloneAllConfigurations() {
		let configList = this.report.cblight__CBReportConfigurations__r;
		configList.forEach((config) => {
			config.cblight__CBReport__c = this.recordId;
			delete config.Id;
			if (typeof config.cblight__Grouping__c === "object") {
				config.cblight__Grouping__c = JSON.stringify(config.cblight__Grouping__c);
			}
		});
		saveAllConfigurationsServer({ configList })
			.then(() => {
				_message("success", "Configurations Cloned");
			})
			.catch((e) => {
				_parseServerError("Reporting : Save Configurations Error: ", e);
			});
	}

	/**
	 * Method clone All Columns
	 */
	cloneReportColumns(report) {
		let columns = this.report.cblight__CBReportColumns__r;
		columns.forEach((column) => {
			delete column.Id;
			column.cblight__CBReport__c = report.Id;
			delete column.cblight__CBStyle__r;
		});

		saveColumnsServer({ report, columns })
			.then((result) => {
				_message("success", "Report Columns Cloned");
			})
			.catch((e) => {
				_parseServerError("Reporting : Save Report Columns Error: ", e);
			});
	}
	
	/**
	 * Method navigates to the clonned CB Report
	 */
	navigateToRecordPage() {
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: this.recordId,
				objectApiName: "cblight__CBReport__c",
				actionName: "view",
			},
		});
	}

	/**
	 * The method sets configuration to the report list of configurations by Id
	 * @param configId - configurationId
	 */
	setConfigurationById(configId) {
		try {
			let config = this.report.cblight__CBReportConfigurations__r.find(({Id}) => Id === configId);
			if (config.cblight__Grouping__c && typeof config.cblight__Grouping__c != "object") {
				config.cblight__Grouping__c = JSON.parse(config.cblight__Grouping__c);
			}
			this.configuration = config;
		} catch (e) {
			_message('error', `setConfigurationById: ${configId} error: ` + e, 'Reporting:');
		}
	}

	////////////////// HANDLERS //////////////////

	handleConfiguratorEvents = (event, manual) => {
		let eventName = event ? event.target.name : manual.name;
		let eventValue = event ? event.target.value : manual.value;

		try {
			if (eventName === 'handleChangeConfig') {
				if (this.isConfigurationChanged && !confirm(this.getConfirmMessage('ifNotSaved'))) {
					this.showConfigContext = false;
					setTimeout(() => {
						this.showConfigContext = true;
					}, 10);
					return null;
				}
				this.isConfigurationChanged = false;
				this.showConfigContext = false;

				setTimeout(() => {
					this.setConfigurationById(eventValue);
					this.setSubtotals();
					this.showConfigContext = true;
				}, 10);

			} else {
				this.isConfigurationChanged = true;

				if (eventName === 'cblight__DisplayUnits__c') {
					this.configuration[eventName] = event.target.value;
					this.configuration = _getCopy(this.configuration);
					return null;
				}

				if (eventName === 'cblight__SubtotalNumber__c') {
					eventValue = parseInt(eventValue);
				}
				if (event && event.detail.result) { // TODO add to the filter component name field returning
					eventName = 'cblight__Filter__c';
					eventValue = event.detail.result;
				}

				let copy = _getCopy(this.configuration);
				copy[eventName] = eventValue;
				this.configuration = copy;

				if (eventName === 'cblight__Grouping__c') {
					this.setSubtotals();
					const groupSize = this.configuration.cblight__Grouping__c.length;
					const num = groupSize > 1 ? groupSize - 1 : 0;
					this.handleConfiguratorEvents(null, {name: 'cblight__SubtotalNumber__c', value: num});
				}
			}
		} catch (e) {
			_message('error', `handleConfiguratorEvents: ${eventName} error: ` + e, 'Reporting:');
		}
	};

	handleReportEvents(event) {
		let eventName = event.target.name;
		let eventValue = event.target.value;

		if (eventName === 'handleChangeConfigAndUpdateReport') {
			this.setConfigurationById(eventValue);
			this.updateFullReport();

		} else {
			let report = _getCopy(this.report);
			report[eventName] = eventValue;
			this.report = report;
		}
	}

	/**
	 * Update full report
	 */
	updateFullReport = () => {
		this.showExcelButton = false;
		this.showSpinner = true;
		this.reportGroupColumns = []; // left text columns
		this.reportColumns = []; 		// digital columns
		this.reportLines = [];
		this.getReportWithConfigurationsAndColumns(); // this.getReportData();
	};

	editReport() {
		this.editReportMode = true;
	}

	////////////////// HANDLERS //////////////////

	//////////// REPORT CONFIGURATION ////////////
	/**
	 * The method creates new configuration from existing with unique name
	 */
	cloneConfiguration() {
		if (this.isConfigurationChanged && !confirm(this.getConfirmMessage('ifNotSaved'))) return null;
		if (!confirm(this.getConfirmMessage('confirmAction', 'clone'))) return null;

		try {
			const report = _getCopy(this.report);
			const newConfig = _getCopy(this.configuration, true);
			let so = _getCopy(this.configurationSO);

			newConfig.Id = _generateFakeId();
			newConfig.Name = this.generateConfigCopyName(this.configuration.Name);

			so.push({value: newConfig.Id, label: newConfig.Name});

			this.report = report;
			this.configurationSO = so;
			this.configuration = newConfig;
			this.saveConfiguration();

			_message('success', 'Configuration cloned');
		} catch (e) {
			_message('error', 'Configuration cloned error: ' + e);
		}
	};

	/**
	 * The method generates unique name for cloned configuration
	 * @param currentName - name that will be cloned
	 * @returns unique name
	 */
	generateConfigCopyName(currentName) {
		const configs = this.report.cblight__CBReportConfigurations__r;
		currentName = 'Copy ' + currentName.slice(0, 70);
		let configWithDuplicateName = this.getConfigWithDuplicateName(configs, currentName);

		let counter = 0;
		while (configWithDuplicateName) {
			if (counter > 100) break; // the fuse on recursion
			currentName = currentName.replace(/Copy\(\d\)|Copy\(\d\d\)|Copy/, `Copy(${++counter})`);
			configWithDuplicateName = this.getConfigWithDuplicateName(configs, currentName);
		}
		return currentName;
	}

	/**
	 * The method that returns config if it has duplicate name
	 * @param configs - list of configs
	 * @param newName - name that check on match
	 * @returns {*} - config with the same name
	 */
	getConfigWithDuplicateName(configs, newName) {
		return configs.find(({Name}) => Name === newName);
	}

	validateConfiguration() {
		let message;
		if (!this.configuration.cblight__Grouping__c || this.configuration.cblight__Grouping__c.length === 0) {
			message = 'Please select at least one field to group';
		}
		return message;
	};

	/**
	 * Save current selected configuration
	 */
	async saveConfiguration() {
		const warningMessage = this.validateConfiguration();
		if (warningMessage) {
			_message('warning', warningMessage, 'Guideline');
			return null;
		}

		const report = _getCopy(this.report);
		let configs;
		if (report.cblight__CBReportConfigurations__r) {
			configs = report.cblight__CBReportConfigurations__r;
			const configWithDuplicateName = this.getConfigWithDuplicateName(configs, this.configuration.Name);
			if (configWithDuplicateName && this.configuration.Id !== configWithDuplicateName.Id) {
				_message('warning', 'Current configuration name is already exist, please create another.');
				return null;
			}
		}
		this.isConfigurationChanged = false;
		this.showSpinner = true;
		let configuration = _getCopy(this.configuration);
		const oldConfigId = configuration.Id;
		_deleteFakeId(configuration);
		configuration.cblight__CBReport__c = this.recordId;
		if (configuration.cblight__Grouping__c) {
			configuration.cblight__Grouping__c = JSON.stringify(configuration.cblight__Grouping__c);
		}
		if (!this.configuration.cblight__CBReport__c) this.configuration.cblight__CBReport__c = this.recordId;

		const soItem = this.configurationSO.find(({value}) => value === this.configuration.Id);
		if (!soItem) return null;
		soItem.label = this.configuration.Name;
		this.configurationSO = _getCopy(this.configurationSO);

		await saveConfigurationServer({configuration})
			.then(savedConfiguration => {
				savedConfiguration.cblight__Grouping__c = JSON.parse(savedConfiguration.cblight__Grouping__c);
				this.configuration = savedConfiguration;

				const soItem = this.configurationSO.find(({label}) => label === savedConfiguration.Name);
				soItem.value = savedConfiguration.Id;
				this.configurationSO = _getCopy(this.configurationSO);

				if (!configs) {
					report.cblight__CBReportConfigurations__r = [this.configuration];
				} else {
					configs = configs.filter(({Id}) => Id !== oldConfigId);
					configs.push(savedConfiguration);
					report.cblight__CBReportConfigurations__r = configs;
				}
				this.report = report;
				_message('success', 'Configuration Saved', 'Success');
			})
			.catch(e => _parseServerError("Reporting : Save Configuration Error: ", e))
			.finally(() => this.showSpinner = false);
	};

	/**
	 * The method makes the validation and delete the current configuration
	 */
	deleteConfiguration = async () => {
		try {
			if (this.report.cblight__CBReportConfigurations__r.length === 1) {
				_message('info', 'The report must have at least one configuration, you cannot delete the last one.');
				return null;
			}
			if (!confirm(this.getConfirmMessage('confirmAction', 'delete'))) return null;
			this.showConfigContext = false;
			this.isConfigurationChanged = false;

			const configurationId = this.configuration.Id;
			const configToDelete = _getCopy(this.configuration);
			const report = _getCopy(this.report);
			let configs = report.cblight__CBReportConfigurations__r;
			let so = _getCopy(this.configurationSO);

			configs = configs.filter(({Id}) => Id !== configurationId);
			report.cblight__CBReportConfigurations__r = configs;
			this.configurationSO = so.filter(({value}) => value !== configurationId);
			this.report = report;
			this.configuration = configs[0];
			if (this.configuration.cblight__Grouping__c && typeof this.configuration.cblight__Grouping__c != "object") {
				this.configuration.cblight__Grouping__c = JSON.parse(this.configuration.cblight__Grouping__c);
			}
			this.setSubtotals();

			if (!_isFakeId(configurationId)) {
				deleteReportConfigByConfigSOServer({configuration: configToDelete}).then(() => {
					_message('info', 'Configuration deleted');
					this.showConfigContext = true;
				});
			}
		} catch (e) {
			_parseServerError("Reporting : Delete Configuration Callback Error: ", e);
		} finally {
			this.showSpinner = false;
		}
	};

	/**
	 * Handler of the header Configuration button. Opens the configuration panel
	 */
	displayReportConfiguration() {
		this.showReportConfiguration = true;
		this.showConfigContext = true;
		this.setSubtotals();
		this.showSpinner = false;
	}

	/**
	 * Handler of the close Configuration button. Closes the configuration panel
	 */
	async hideReportConfiguration() {
		if (this.isConfigurationChanged) {
			this.showSpinner = true;
			await this.saveConfiguration();
		}

		this.showReportConfiguration = false;
		this.isConfigurationChanged = false;

		if (!this.reportColumns || !this.reportColumns.length) {
			this.displayReportColumns();
		} else {
			this.updateFullReport();
		}
	}

	get excelData() {
		return {
			reportGroupColumns: this.reportGroupColumns,
			reportColumns: this.reportColumns,
			reportLines: this.reportLines,
			report: this.report,
			reportSingleColumn: this.reportSingleColumn
		};
	}

	set excelData(value) {
	}

//////////// REPORT CONFIGURATION ////////////

//////////// COLUMN CONFIGURATION ////////////
	displayReportColumns() {
		this.showReportColumns = true;
	}

	closeReportColumns = () => {
		this.showReportColumns = false;
	};

	closeDrillDown = () => {
		this.showDrillDown = false;
	};

//////////// COLUMN CONFIGURATION ////////////

//////////// PRIVATE METHODS /////////////////
	/**
	 * The method allocates report settings
	 * @param result is the report and its configurations with columns
	 */
	manageReportStructure = async (result) => {
		try {
			let configs = result.cblight__CBReportConfigurations__r;
			if (!configs || configs.length === 0) {
				_message('warning', 'Please create a report configuration', 'Guideline');
				this.configuration = this.getNewConfigurationObject();
				this.configurationSO = [{label: this.configuration.Name, value: this.configuration.Id}];
				this.report = result; ///////// TODO
				this.displayReportConfiguration();
				this.showSpinner = false;
				return null;
			}

			let config = !this.configuration || Object.keys(this.configuration).length === 0 ? configs[0] : configs.find(c => c.Id === this.configuration.Id);

			let configurationSO = [];
			if (!_isInvalid(result.cblight__CBReportConfigurations__r)) {
				configurationSO = result.cblight__CBReportConfigurations__r.map(conf => ({
					value: conf.Id, label: conf.Name
				}));
			}
			if (!_isInvalid(config.cblight__Grouping__c)) {
				config.cblight__Grouping__c = JSON.parse(config.cblight__Grouping__c);
			}

			this.report = result;
			this.configuration = config;
			this.configurationSO = configurationSO;

			await this.getReportData();
		} catch (e) {
			_message('error', 'Reporting : Manage Report Structure Error: ' + e);
		}
	};

	/**
	 * The method returns the new configuration object
	 * @returns {{Id: *, cblight__SubtotalNumber__c: number, Name: string}}
	 */
	getNewConfigurationObject() {
		return {
			Name: "General", Id: _generateFakeId(), cblight__SubtotalNumber__c: 1
		};
	};

	/**
	 * The method generates left text columns of report (JUST HEADER TITLES)
	 */
	generateReportGroupColumns() {
		try {
			const reportGroupColumns = [];
			const cubeFieldsSO = _getCopy(this.cubeFieldsSO);
			const groups = this.configuration.cblight__Grouping__c;
			const def = "width:180px;";
			if (this.report.cblight__oneColumnMode__c) {
				const reportSingleColumn = [];
				const key = groups[groups.length - 1];
				const neededSO = cubeFieldsSO.find(so => so.value === key);
				const width = localStorage.getItem(`col${key}`) ? `width:${localStorage.getItem(`col${key}`)};` : def;
				reportSingleColumn.push({
					label: neededSO.label,
					isFirst: true,
					fieldName: key,
					colWidth: width,
					class: 'slds-cell-fixed analyticHeader col' + key
				});
				this.reportSingleColumn = reportSingleColumn;
			}
			for (let i = 0; i < groups.length; i++) {
				const key = groups[i];
				const neededSO = cubeFieldsSO.find(so => so.value === key);
				const width = localStorage.getItem(`col${key}`) ? `width:${localStorage.getItem(`col${key}`)};` : def;
				reportGroupColumns.push({
					label: neededSO.label,
					isFirst: i === 0,
					fieldName: key,
					colWidth: width,
					class: 'slds-cell-fixed analyticHeader col' + key
				});
			}
			this.reportGroupColumns = reportGroupColumns;
		} catch (e) {
			_message('error', 'Reporting : Generate Report Group Columns Error: ' + e);
		}
	};

//////////// PRIVATE METHODS /////////////////

	/**
	 * Prepare data and run Drill Down
	 */
	showCellDrillDown(event) {
		try {
			let DDKeys = event.currentTarget.dataset.item.split('&'); // first argument is row index, second is cell index
			let reportLine = this.reportLines[DDKeys[0]];
			let cell = this.reportLines[DDKeys[0]].reportCells.find(cell => {
				let parts = cell.drillDownKey.split('&');
				return parts[1] === DDKeys[1];
			});

			if (cell.isTotal) {
				_message('info', 'Drilldown cannot be generated for totals.');
				return;
			}
			const headerDetails = this.reportGroupColumns.map((groupName, idx) => `${groupName.label} : ${reportLine.labels[idx]}`);
			this.DDParams = {
				periodId: cell.periodId, configId: this.configuration.Id, keys: reportLine.keys, headerDetails
			};
			this.showDrillDown = true;
		} catch (e) {
			_message('error', 'Reporting : DD Error: ' + e);
		}
	}

	/**
	 * Styles application method.
	 */
	applyStyles() {

	}

	/**
	 * Analytics columns styles application method
	 */
	setStylesToAnalyticsColumns() {
		this.reportLines.forEach(line => {
			let analyticsColumns = [];
			
			if (this.report.cblight__oneColumnMode__c) {
				const lastIndex = line.labels.length - 1;
				const lastLabel = line.labels[lastIndex];

				if(line.isTotal) {
					line.labels.forEach((label) => {
						const trimmedLabel = label.trim();
						
						if (trimmedLabel.length > 0) {
							const totalAlreadyAdded = analyticsColumns.some(column => column.label === trimmedLabel);
							if (!totalAlreadyAdded) {
								analyticsColumns.push({
									label: trimmedLabel,
									class: `frozen-col slds-truncate ${line.class}`
								});
							}
						}
					});
				} else {
					if (lastLabel.length > 0) {
						analyticsColumns.push({
							label: lastLabel,
							class: `frozen-col slds-truncate ReportFrozenColumnsGradient`
						});
					} 
				}
			} else {
				line.labels.forEach((label, i) => {
					analyticsColumns.push({
						label: label, class: `frozen-col frozen-col-num${i + 2} slds-truncate ReportFrozenColumnsGradient`
					});
				});
			}
			line.analyticsColumns = analyticsColumns;
		});
	};

	/**
	 * Method get styles from server, set local storage cbstyles and converting Report Frozen Columns style for Reporting
	 */
	setStylesToAnalyticsColumnsGradient = async () => {
		await getStylesRecordsServer()
			.then(styles => {
				if (!styles) return null;
				localStorage.removeItem('cbstyles');
				localStorage.setItem('cbstyles', JSON.stringify(styles));
				let style = styles.find(style => style.Name === 'Report Frozen Columns');
				if (!style) return null;
				const brightness = 1.01;
				const color = this.getLighterRGBAFromHex(style.cblight__BackgroundColor__c, brightness);
				const linearColor = this.linearGradient(style.cblight__BackgroundColor__c, color);
				this.applyStylesGradient(styles, linearColor);
			})
			.catch(e => _parseServerError('Reporting : get Styles Records Server Error', e));
	};

	/**
	 * Method convert hex and color to linear-gradient css
	 */
	linearGradient = (hex, color) => {
		const rgbValues = hex
			.replace(/^#?([a-f\d])([a-f\d])([a-f\d])$/i, (m, r, g, b) => '#' + r + r + g + g + b + b)
			.substring(1)
			.match(/.{2}/g)
			.map(x => parseInt(x, 16));

		return `linear-gradient(180deg, rgba(${rgbValues.join(', ')},1) 0%, ${color} 50%, rgba(${rgbValues.join(', ')},1) 100%)`;
	};

	/**
	 * Method convert hex to lighter version in rgba
	 */
	getLighterRGBAFromHex(hex, brightness) {
		const sanitizedHex = hex.replace('#', '');
		const r = parseInt(sanitizedHex.slice(0, 2), 16);
		const g = parseInt(sanitizedHex.slice(2, 4), 16);
		const b = parseInt(sanitizedHex.slice(4, 6), 16);

		const adjustedR = Math.round(r + (255 - r) * brightness * 0.2);
		const adjustedG = Math.round(g + (255 - g) * brightness * 0.2);
		const adjustedB = Math.round(b + (255 - b) * brightness * 0.2);

		return `rgba(${adjustedR}, ${adjustedG}, ${adjustedB}, 1)`;
	}

	/**
	 * Method apply CSS to HTML for all styles and new generated Report Frozen Columns style
	 */
	applyStylesGradient(styles, linearColor) {
		try {
			let styleCS = document.createElement("style");
			styleCS.type = "text/css";
			styleCS.innerHTML = styles.reduce((str, style) => {
				str = str + "." + style.Name.replace(/ /g, "") + " " + style.cblight__CSS__c + " ";
				return str;
			}, "");
			document.getElementsByTagName("head")[0].appendChild(styleCS);
			let styleCSS = document.createElement('style');
			styleCSS.type = 'text/css';
			styleCSS.innerHTML = '.ReportFrozenColumnsGradient {' + 'background:' + linearColor + ' !important;' + '}';
			document.getElementsByTagName("head")[0].appendChild(styleCSS);
		} catch (e) {
			alert("cb Reporting : applyStyles ERROR: " + JSON.stringify(e));
		}
	}

	/**
	 * The method return confirmation message
	 * @param type - type of message
	 * @param action - action
	 * @returns {*}
	 */
	getConfirmMessage(type, action) {
		if (!action) action = 'this action';
		const confirmMessage = {
			ifNotSaved: `Perform ${action} without saving the current configuration?`,
			confirmAction: `Are you sure you want to ${action} the current configuration?`
		};
		return confirmMessage[type];
	}

	//////////////////// RESIZABLE COLUMNS /////////////////////////
	tableOuterDivScrolled(event) {
		this._tableViewInnerDiv = this.template.querySelector(".tableViewInnerDiv");
		if (this._tableViewInnerDiv) {
			if (!this._tableViewInnerDivOffsetWidth || this._tableViewInnerDivOffsetWidth === 0) {
				this._tableViewInnerDivOffsetWidth = this._tableViewInnerDiv.offsetWidth;
			}
			this._tableViewInnerDiv.style = 'width:' + (event.currentTarget.scrollLeft + this._tableViewInnerDivOffsetWidth) + "px;" + this.tableBodyStyle;
		}
	}

	//***************** RESIZABLE COLUMNS *************************************/
	/**
	 * Mouse is over column
	 */
	handleMouseUp(e) {
		this._tableThColumn = undefined;
		this._tableThInnerDiv = undefined;
		this._pageX = undefined;
		this._tableThWidth = undefined;
	}

	/**
	 * Mouse left resizable column
	 */
	handleMouseDown(e) {
		try {
			if (!this._initWidths) {
				this._initWidths = [];
				let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
				tableThs.forEach(th => {
					this._initWidths.push(th.style.width);
				});
			}
			this._tableThColumn = e.target.parentElement;
			this._tableThInnerDiv = e.target.parentElement;
			while (this._tableThColumn.tagName !== "TH") {
				this._tableThColumn = this._tableThColumn.parentNode;
			}
			while (!this._tableThInnerDiv.className.includes("slds-cell-fixed")) {
				this._tableThInnerDiv = this._tableThInnerDiv.parentNode;
			}
			this._tableThInnerDiv.className.split(' ').forEach(cl => {
				if (cl.startsWith('col')) {
					this._colIdx = cl;
				}
			});
			this._pageX = e.pageX;
			this._padding = this.paddingDiff(this._tableThColumn);
			this._tableThWidth = this._tableThColumn.offsetWidth - this._padding;
		} catch (e) {
			alert(e);
		}
	}

	/**
	 * Size of column changed if mouse is moving
	 */
	handleMouseMove(e) {
		if (this._tableThColumn && this._tableThColumn.tagName === "TH") {
			this._diffX = e.pageX - this._pageX;
			this.template.querySelector("table").style.width = (this.template.querySelector("table") - (this._diffX)) + 'px';
			this._tableThColumn.style.width = (this._tableThWidth + this._diffX) + 'px';
			this._tableThInnerDiv.style.width = this._tableThColumn.style.width;
			localStorage.setItem(this._colIdx, this._tableThColumn.style.width);
			let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
			let tableBodyRows = this.template.querySelectorAll("table tbody tr");
			let tableBodyTds = this.template.querySelectorAll("table tbody .dv-dynamic-width");
			tableBodyRows.forEach(row => {
				let rowTds = row.querySelectorAll(".dv-dynamic-width");
				rowTds.forEach((td, ind) => {
					rowTds[ind].style.width = tableThs[ind].style.width;
				});
			});
		}
	}

	/**
	 * Auto resize columns on double click
	 */
	handleDBClickResizable() {
		let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
		let tableBodyRows = this.template.querySelectorAll("table tbody tr");
		tableThs.forEach((th, ind) => {
			th.style.width = this._initWidths[ind];
			th.querySelector(".slds-cell-fixed").style.width = this._initWidths[ind];
		});
		tableBodyRows.forEach(row => {
			let rowTds = row.querySelectorAll(".dv-dynamic-width");
			rowTds.forEach((td, ind) => {
				rowTds[ind].style.width = this._initWidths[ind];
			});
		});
	}

	paddingDiff(col) {
		if (this.getStyleVal(col, 'box-sizing') === 'border-box') return 0;
		this._padLeft = this.getStyleVal(col, 'padding-left');
		this._padRight = this.getStyleVal(col, 'padding-right');
		return (parseInt(this._padLeft, 10) + parseInt(this._padRight, 10));
	}

	getStyleVal(elm, css) {
		return (window.getComputedStyle(elm, null).getPropertyValue(css))
	}

	//////////////////// RESIZABLE COLUMNS /////////////////////////


	///////////////////// DRUG & DROP ///////////////////////
	dragStart(event) {
		event.target.classList.add('drag');
	}

	dragOver(event) {
		event.preventDefault();
		return false;
	}

	/**
	 * put dropped element into a new position
	 */
	dropElement(event) {
		try {
			event.stopPropagation();
			const dragElementOrderLabel = this.template.querySelector('.drag').textContent;
			const dropElementOrderLabel = event.target.textContent;// indexOfDroppedElement of line that dropped
			if (dragElementOrderLabel === dropElementOrderLabel) { // the same column, replacing is not needed
				return false
			}
			let dragElementOrderField;
			let dropElementOrderField;
			this.reportGroupColumns.forEach(column => {
				if (dragElementOrderLabel === column.label) dragElementOrderField = column.fieldName;
				if (dropElementOrderLabel === column.label) dropElementOrderField = column.fieldName;
			});
			this.showSpinner = true;
			this.configuration.cblight__Grouping__c = JSON.stringify(this.replaceGrouping(this.configuration.cblight__Grouping__c, dropElementOrderField, dragElementOrderField));
			saveConfigurationServer({configuration: this.configuration})
				.then(() => this.connectedCallback())
				.catch(e => _parseServerError('Reporting : Save Configuration Error: ', e));

			this.template.querySelectorAll('.draggableLine').forEach(element => element.classList.remove('drag'));
		} catch (e) {
			_message('error', e);
		}
	};

	/**
	 *
	 * @param array source of grouping
	 * @param searchString field that must to be replaced
	 * @param replacementString field that must to take previous field position
	 * @return {*}
	 */
	replaceGrouping(array, searchString, replacementString) {
		const index = array.indexOf(searchString);
		array = array.filter(c => c !== replacementString);
		array.splice(index, 0, replacementString);
		return array;
	}

	///////////////////// DRUG & DROP ///////////////////////

}