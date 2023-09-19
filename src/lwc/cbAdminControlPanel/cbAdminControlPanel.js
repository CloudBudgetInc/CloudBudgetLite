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
import getOrgVariableServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableServer";
import getOrgVariableStructureServer from "@salesforce/apex/CBOrgVariableSelector.getOrgVariableStructureServer";
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
	@track showMappingReport = false;
	@track trialDataProfiles = [{label: 'Default', value: 'default'}];
	ANALYTIC_TYPES = ['accounts', 'divisions', 'periods', 'variables1', 'variables2', 'variables3', 'variables4', 'variables5'];

	connectedCallback() {

	}

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