import {LightningElement, track} from 'lwc';
import getTaskQueuesServer from "@salesforce/apex/CBAdminControlPanelPageController.getTaskQueuesServer";
import getCronTriggersServer from "@salesforce/apex/CBAdminControlPanelPageController.getCronTriggersServer";
import saveScheduledJobServer from "@salesforce/apex/CBAdminControlPanelPageController.saveScheduledJobServer";
import getPublicGroupSOServer from "@salesforce/apex/CBAdminControlPanelPageController.getPublicGroupSOServer";
import runTaskQueueServer from "@salesforce/apex/CBAdminControlPanelPageController.runTaskQueueServer";
import deleteScheduledJobServer from "@salesforce/apex/CBAdminControlPanelPageController.deleteScheduledJobServer";
import getAuditTrailsServer from "@salesforce/apex/CBAdminControlPanelPageController.getAuditTrailsServer";
import getObjectStatisticServer from "@salesforce/apex/CBAdminControlPanelPageController.getObjectStatisticServer";
import getOrgLimitsServer from "@salesforce/apex/CBAdminControlPanelPageController.getOrgLimitsServer";
import generateTrialDataServer from "@salesforce/apex/CBAdminControlPanelPageController.generateTrialDataServer";
import syncMappedAnalyticsServer from "@salesforce/apex/CBAdminControlPanelPageController.syncMappedAnalyticsServer";
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import getLiteDashboardIdServer from "@salesforce/apex/CBAdminControlPanelPageController.getLiteDashboardIdServer";
import getOrgVariableStructureServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableStructureServer";
import getHomeChartDefaultParamsServer
	from "@salesforce/apex/CBAdminControlPanelPageController.getHomeChartDefaultParamsServer";
import getBaseBudgetForChartServer
	from "@salesforce/apex/CBAdminControlPanelPageController.getBaseBudgetForChartServer";
import getInvoiceDataForChartServer
	from "@salesforce/apex/CBAdminControlPanelPageController.getInvoiceDataForChartServer";
import generateTrialNonFinLibsDataServer
	from "@salesforce/apex/CBAdminControlPanelPageController.generateTrialNonFinLibsDataServer";
import {_cl, _message, _parseServerError} from 'c/cbUtils';
import {NavigationMixin} from 'lightning/navigation';

export default class CbAdminControlPanel extends NavigationMixin(LightningElement) {

	@track displayChildrenClusters = false; // render children clusters if needed
	@track statusData = [];
	@track taskQueues = []; // list of queue
	@track cronTriggers = []; // list of Cron Triggers
	@track auditTrails = [];
	@track openedSections = ['scheduled', 'queues'];
	@track statisticRows = [];
	@track showNewJobModal = false;
	@track showSpinner = false;
	@track storage = {};
	@track showChart = false;
	@track chartConfig = {};
	@track selectedTaskQueue = {};
	@track selectOptions = {'publicGroupSO': []};
	@track orgSettings = [];
	@track lockButton = false;
	@track reportType = 'account';
	@track orgVariable;
	@track dashboardId;
	@track params = {};
	@track showMappingReport = false;
	@track trialDataProfiles = [{label: 'Default', value: 'default'}];
	@track accTypeSO;
	ANALYTIC_TYPES = ['accounts', 'divisions', 'periods', 'variables1', 'variables2', 'variables3', 'variables4', 'variables5'];

	@track showHomeChart = false;
	@track homePageLineChartConfig;
	@track homePageBarChartConfig;

	async connectedCallback() {
		const orgVariable = await getOrgVariableServer().catch(e => _parseServerError('Admin Panel : Get Org Settings Error : ', e));
		for (let i = 1; i <= 5; i++) if (orgVariable[`cblight__CBVariable${i}Label__c`] !== `CB Variable ${i}`) orgVariable[`displayVar${i}`] = true;
		this.orgVariable = orgVariable;
		this.dashboardId = await getLiteDashboardIdServer();
		this.getDataForChart().then(r => {
		});
	};

	getDataForChart = async () => {
		try {
			this.showHomeChart = false;
			this.showSpinner = true;
			let params = this.params;
			if (!params || !params.cblight__CBBudgetYear__c) {
				params = await getHomeChartDefaultParamsServer();
				this.accTypeSO = [{label: params.plusType, value: '+'}, {label: params.minusType, value: '-'}];
				this.params = params;
			}
			const arBaseBudget = await getBaseBudgetForChartServer({params});
			const arInvoices = await getInvoiceDataForChartServer({params});

			this.generateDataForLineChart(arBaseBudget, arInvoices);
			this.generateDataForBarChart(arBaseBudget, arInvoices);

			this.showHomeChart = true;
			this.showSpinner = false;
		} catch (e) {
			_parseServerError('Get Chart Data Error ', e);
			this.showSpinner = false;
		}
	};

	generateDataForLineChart = (arBaseBudget, arInvoices) => {
		const labels = [];
		arBaseBudget.forEach(a => { // months
			if (labels.includes(a.period)) return;
			labels.push(a.period);
		});

		const colorMap = ['rgb(75, 192, 192)', 'rgb(104,153,192)', 'rgb(116,108,192)', 'rgb(192,97,158)', 'rgb(116,108,152)'];

		const datasetObject = {};
		arBaseBudget.forEach(a => { // months
			a.scName = a.scName ? a.scName : 'Budget';
			let dSet = datasetObject[a.scName];
			if (!dSet) {
				dSet = {
					label: a.scName,
					data: [],
					borderDash: [10, 5],
					fill: false,
					borderColor: colorMap[Object.keys(datasetObject).length],
					tension: 0.1
				};
				datasetObject[a.scName] = dSet;
			}
			dSet.data.push(a.value);
		});

		const datasets = [...Object.values(datasetObject),
			{
				label: 'Invoiced',
				data: arInvoices.map(a => a.value),
				fill: false,
				borderColor: 'rgb(192,155,156)',
				tension: 0.1
			}
		];

		this.homePageLineChartConfig = {
			type: 'line',
			data: {
				labels,
				datasets
			},
		};
	};

	generateDataForBarChart = (arBaseBudget, arInvoices) => {

		const labels = ['Type'];

		const colorMap = ['rgb(75, 192, 192)', 'rgb(104,153,192)', 'rgb(116,108,192)', 'rgb(192,97,158)', 'rgb(116,108,152)'];

		const datasetObject = {};
		arBaseBudget.forEach(a => {
			a.scName = a.scName ? a.scName : 'Budget';
			datasetObject[a.scName] = datasetObject[a.scName] ? a.value + datasetObject[a.scName] : a.value;
		});

		const datasets = [];

		let colorIndex = 0;
		for (const [key, value] of Object.entries(datasetObject)) {
			datasets.push({
				label: key,
				data: [value],
				borderColor: colorMap[colorIndex],
				backgroundColor: colorMap[colorIndex],
			});
			colorIndex++;
		}

		datasets.push({
			label: 'Invoiced',
			data: [arInvoices.reduce((r, item) => r + +item.value, 0)],
			borderColor: 'rgb(192,155,156)',
			backgroundColor: 'rgb(192,155,156)',
		});

		this.homePageBarChartConfig = {
			type: 'bar',
			data: {
				labels,
				datasets
			},
		};
	};

	handleHomeChartFilter = (event) => {
		console.log(event.target.name);
		console.log(event.target.value);
		this.params[event.target.name] = event.target.value;
	};

	/**
	 * This method runs the task queue to sync analytics
	 */
	syncMappedAnalytics = () => {
		syncMappedAnalyticsServer()
			.then(r => {
				if (r === 'success') {
					_message('success', 'Run');
				} else {
					_message('info', r);
				}
			})
			.catch(e => _parseServerError('HCP : Sync Error ', e));
	};

	////////////   ORGANIZATION STATISTIC   /////////////////
	async getStatistic() {
		this.statisticRows = [];
		this.chartConfig = {};
		this.showChart = false;
		for (const type of this.ANALYTIC_TYPES) {
			try {
				this.statisticRows.push(await getObjectStatisticServer({type}).catch(e => _parseServerError('Get Statistic Error:', e)));
			} catch (e) {
				_message('error', 'Get statistic error: ' + e);
			}
		}
		this.getOrgLimitsData();
	}

	renderMappingReport = (event) => {
		this.reportType = event.target.value;
		if (!this.reportType) return null;
		this.showMappingReport = true;
	};

	closeMappingReport = () => {
		this.showMappingReport = false;
	};

	/**
	 * The method takes org storage data and convert them to chart
	 */
	getOrgLimitsData = () => {
		getOrgLimitsServer()
			.then(rows => {
				if (!rows) return;
				try {
					const chartData = {
						labels: [
							'Free Space',
							'Used Space'
						],
						datasets: [{
							label: 'Org Storage',
							data: [rows[0].lim - rows[0].value, rows[0].value],
							backgroundColor: [
								'rgb(134,255,161)',
								'rgb(235,213,200)'
							],
							hoverOffset: 4
						}]
					};

					this.chartConfig = {
						type: 'doughnut',
						data: chartData
					};
					console.log('data => ', JSON.stringify(this.chartConfig));
					this.showChart = true;
				} catch (e) {
					_message('error', 'Admin Panel : Get Org Limits Error : ' + e);
				}
			})
			.catch(e => {
				_parseServerError('Admin Control Panel : Chart Error ', e)
			});
	};

	redirectToListView(event) {
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: event.target.value,
				actionName: 'list'
			},
			state: {
				filterName: 'Recent'
			}
		}).then(url => {
			window.open(url, "_blank");
		});
	}

	////////////   ORGANIZATION STATISTIC   /////////////////

	////////////   SCHEDULED QUEUE PANEL   /////////////////
	updateScheduledJobsPanel() {
		this.showSpinner = true;
		this.taskQueues = [];
		this.cronTriggers = [];
		this.getTaskQueues();
		this.getPublicGroupSO();
	}

	getPublicGroupSO() {
		getPublicGroupSOServer()
			.then(pgSO => {
				this.selectOptions.publicGroupSO = pgSO;
			})
			.catch(e => _parseServerError('Admin Control Panel : Get Public Group SO Error', e));
	}

	getTaskQueues() {
		getTaskQueuesServer()
			.then(taskQueues => {
				this.taskQueues = taskQueues;
				this.getCronTriggers();
			})
			.catch(e => _parseServerError("Admin Control Panel : Get Task Queue Error", e))
	}

	getCronTriggers() {
		getCronTriggersServer()
			.then(cronTriggers => {
				const TQNameList = this.taskQueues.map(tq => tq.Name);
				cronTriggers.forEach(ct => ct.isCB = TQNameList.includes(ct.CronJobDetail.Name));
				this.cronTriggers = cronTriggers;
			})
			.catch(e => _parseServerError("Admin Control Panel : Get Cron Triggers Error", e))
			.finally(() => this.showSpinner = false);
	}

	setNewScheduledJob(event) {
		try {
			this.selectedTaskQueue = this.taskQueues.find(tq => tq.Name === event.target.value);
			this.selectedTaskQueue.runTime = '01:00:00.000Z';
			this.toggleNewJobModal();
		} catch (e) {
			_message('error', 'Admin Control Panel : Set New Scheduled Job Error: ' + e, 'Error');
		}
	}

	handleTQSetupChange(event) {
		this.selectedTaskQueue[event.target.name] = event.target.value;
	}

	/**
	 * The method saves desired jobs to list of scheduled jobs
	 */
	saveNewScheduledJob() {
		const timeArray = this.selectedTaskQueue.runTime.split(':');
		const jobName = this.selectedTaskQueue.Name, hours = timeArray[0], minutes = timeArray[1];
		this.showSpinner = true;
		this.toggleNewJobModal();
		saveScheduledJobServer({jobName, hours, minutes})
			.then(() => {
				_message('success', 'Created');
				this.updateScheduledJobsPanel();
			})
			.catch(e => {
				_parseServerError("Admin Control Panel : Save New Scheduled Job Error", e);
				this.showSpinner = false;
			})
	}

	/**
	 * The method deletes scheduled job
	 */
	deleteScheduledJob(event) {
		if (!confirm('Are you sure?')) {
			return null;
		}
		this.showSpinner = true;
		deleteScheduledJobServer({ctId: event.target.value})
			.then(() => {
				_message('success', 'Deleted');
				this.updateScheduledJobsPanel();
			})
			.catch(e => {
				_parseServerError("Admin Control Panel : Delete Scheduled Job Error", e);
				this.showSpinner = false;
			})
	}

	/**
	 * The method runs selected task queue manually
	 */
	runTaskQueueManually(event) {
		if (!confirm('Are you sure?')) {
			return null;
		}
		this.showSpinner = true;
		runTaskQueueServer({taskQueueId: event.target.value})
			.then((result) => {
				if (result === 'success') {
					_message(result, 'Task Queue Run');
				} else {
					_message('warning', result);
				}
			})
			.catch(e => _parseServerError("Admin Control Panel : Run Task Queue Error", e))
			.finally(() => this.showSpinner = false);
	}

	toggleNewJobModal() {
		this.showNewJobModal = !this.showNewJobModal;
	}

	redirectTo = (event) => {
		let cmpName = event.target.dataset.name;
		let config;
		if (cmpName.includes('Dash')) {
			config = {
				type: 'standard__recordPage',
				attributes: {
					recordId: this.dashboardId,
					objectApiName: 'Dashboard',
					actionName: 'view'
				}
			}
		} else if (cmpName.includes('Budget') || cmpName.includes('Style')) {
			config = {
				type: 'standard__webPage',
				attributes: {
					url: cmpName
				}
			};
		} else {
			config = {
				type: 'standard__objectPage',
				attributes: {
					objectApiName: cmpName,
					actionName: 'list'
				},
				state: {
					filterName: 'Recent'
				}
			}
		}

		this[NavigationMixin.Navigate](config);
		//alert(moduleName);
		/*this[NavigationMixin.GenerateUrl]().then(url => {
			window.open(url, "_blank");
		});*/
	};

	////////////   SCHEDULED QUEUE PANEL   /////////////////

	/////////// AUDIT TRAIL   ///////////
	updateAuditTrialsPanel() {
		this.showSpinner = true;
		this.auditTrails = [];
		this.getAuditTrails();
	}

	/**
	 * The method takes all org events
	 */
	getAuditTrails() {
		getAuditTrailsServer()
			.then(auditTrails => {
				this.auditTrails = auditTrails;
			})
			.catch(e => _parseServerError("Admin Control Panel : Audit Trail Error", e))
			.finally(() => this.showSpinner = false);
	}

	/////////// AUDIT TRAIL   ///////////

	///////////  TRIAL DATA  ////////////
	updateTrialDataPanel = () => {

	};

	generateTrialData = () => {
		try {
			this.showSpinner = this.lockButton = true;
			generateTrialDataServer()
				.then(resp => _message(resp.includes('ERROR') ? 'error' : 'info', resp))
				.catch(e => _parseServerError('Admin Panel : Generate Trial Data Error : ', e))
				.finally(() => {
					this.showSpinner = false;
					this.lockButton = false;
				})
		} catch (e) {
			_message('error', 'Admin Panel : Generate Trial Data Error : ' + e);
		}
	};

	generateTrialNonFinLibData = () => {
		try {
			this.showSpinner = this.lockButton = true;
			generateTrialNonFinLibsDataServer()
				.then(resp => _message(resp.includes('ERROR') ? 'error' : 'info', resp))
				.catch(e => _parseServerError('Admin Panel : Generate Trial Non Fin Libs Data Error : ', e))
				.finally(() => {
					this.showSpinner = false;
					this.lockButton = false;
				})
		} catch (e) {
			_message('error', 'Admin Panel :  Generate Trial Non Fin Libs Data Error : ' + e);
		}
	};
	///////////  TRIAL DATA  ////////////

	///////////  ORG SETTINGS ///////////
	updateOrgSettingsPanel = async () => {
		try {
			const EXCLUDED = ['OwnerId', 'Id', 'cblight__Description__c', 'Name'];
			this.showSpinner = true;
			let orgVariableStructure = await getOrgVariableStructureServer().catch(e => _parseServerError('Admin Panel : Get Org Settings Structure Error : ', e));
			const orgVariable = await getOrgVariableServer().catch(e => _parseServerError('Admin Panel : Get Org Settings Error : ', e));
			const r = [];
			orgVariableStructure.forEach(so => {
				if (EXCLUDED.includes(so.value)) return;
				so.isToggle = so.type === 'CHECKBOX';
				so.isNumber = so.type === 'DOUBLE';
				so.isDate = so.type === 'DATE';
				so.isText = so.type === 'STRING';
				so.field = so.value;
				so.value = orgVariable[so.value];
				r.push(so);
			});
			this.orgSettings = r;
			_cl(JSON.stringify(this.orgSettings), 'red');
			this.showSpinner = false;
		} catch (e) {
			_message('error', 'Admin Panel :  Get Org Settings Error : ' + e);
		}
	};

	///////////  ORG SETTINGS ///////////

	constructor() {
		super();
		this.addEventListener("closeInitWizardReport", this.closeMappingReport);
	}


}