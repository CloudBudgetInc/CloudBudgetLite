/** 
Copyright (c) 2022, CloudBudget, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
* Neither the name of the CloudBudget, Inc. nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

 */


public with sharing class CBAdminControlPanelPageController {

	/**
	 * @return full list of Task Queues
	 */
	@AuraEnabled
	public static List<CBTaskQueue__c> getTaskQueuesServer() {
		return new CBTaskQueueSelector().getTaskQueueRecords(null);
	}

	/**
	 * @return full list of Task Queues
	 */
	@AuraEnabled
	public static List<CronTrigger> getCronTriggersServer() {
		return [
				SELECT TimesTriggered, NextFireTime, State, CronExpression, CronJobDetail.Name
				FROM CronTrigger
				WITH SECURITY_ENFORCED
				LIMIT 10000
		];
	}

	@AuraEnabled
	public static String getLiteDashboardIdServer() {
		try {
			return [SELECT Id FROM Dashboard WHERE Title = 'CloudBudget Lite' WITH SECURITY_ENFORCED].Id;
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * 0 0 13 * * ?			Class runs every day at 1 PM.
	 * 0 0 22 ? * 6L			Class runs the last Friday of every month at 10 PM.
	 * 0 0 10 ? * MON-FRI		Class runs Monday through Friday at 10 AM.
	 * 0 0 20 * * ? 2010		Class runs every day at 8 PM during the year 2010.
	 *
	 * @param jobName
	 * @param hours
	 * @param minutes
	 */
	@AuraEnabled
	public static void saveScheduledJobServer(String jobName, Integer hours, Integer minutes) {
		if (String.isEmpty(jobName)) {
			return;
		}
		CBSchedulableTaskQueueService scheduledObject = new CBSchedulableTaskQueueService();
		// Seconds, Minutes, Hours, Day_of_month, Month, Day_of_week, Optional_year
		String sch = '0 ' + minutes + ' ' + hours + ' ? * MON-FRI';
		System.schedule(jobName, sch, scheduledObject);
	}

	@AuraEnabled
	public static void deleteScheduledJobServer(String ctId) {
		System.abortJob(ctId);
	}

	@AuraEnabled
	public static List<CBSO> getPublicGroupSOServer() {
		List<CBSO> r = new List<CBSO>();
		for (Group gr : [SELECT Id, Name FROM Group WHERE Type = 'Regular' WITH SECURITY_ENFORCED ORDER BY Name]) {
			r.add(new CBSO(gr.Id, gr.Name));
		}
		return r;
	}

	@AuraEnabled
	public static String runTaskQueueServer(String taskQueueId) {
		return CBTaskDispatcherService.runQueue(taskQueueId);
	}

	@AuraEnabled
	public static List<SObject> getAuditTrailsServer() {
		try {
			return Database.query(
					'SELECT Action, CreatedBy.Name, CreatedDate, Display, Section FROM SetupAuditTrail WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 200'
			);
		} catch (Exception e) {
			return null;
		}
	}

	@AuraEnabled
	public static List<ReportRow> getOrgLimitsServer() {
		try {
			List<ReportRow> r = new List<CBAdminControlPanelPageController.ReportRow>();
			Map<String, System.OrgLimit> limitsMap = OrgLimits.getMap();
			System.OrgLimit stLim = limitsMap.get('DataStorageMB');
			ReportRow storageLimit = new ReportRow('storage');
			storageLimit.lim = stLim.getLimit();
			storageLimit.value = stLim.getValue();
			r.add(storageLimit);
			return r;
		} catch (Exception e) {
			return null;
		}
	}

	@AuraEnabled
	public static String generateTrialDataServer() {
		try {
			CBInitialTestDataService.generateData();
			return 'Trial Data Generated';
		} catch (Exception e) {
			return 'ERROR: ' + e.getMessage();
		}
	}

	@AuraEnabled
	public static String generateTrialNonFinLibsDataServer() {
		try {
			CBNonFinancialLibraryService.generateLayersAndNonFinancialLibraries();
			return 'Trial Non Financial Libs Generated';
		} catch (Exception e) {
			return 'ERROR: ' + e.getMessage();
		}
	}

	@AuraEnabled
	public static ReportRow getObjectStatisticServer(String type) {
		ReportRow r = new ReportRow(type);
		List<CBMapping__c> mappingRules = new CBMappingSelector().getMappingRecords('cblight__Type__c = \'' + type + '\' ');
		if (mappingRules == null || mappingRules.size() == 0) return r;
		CBMapping__c mr = mappingRules[0];
		if (String.isEmpty(mr.SourceSObject__c) || String.isEmpty(mr.ResultSObject__c)) {
			return r;
		}
		r.sourceObjectAPIName = mr.SourceSObject__c;
		r.sourceObjectName = CBUtils.getObjectLabelFromObjectAPIName(mr.SourceSObject__c);
		r.resultObjectAPIName = mr.ResultSObject__c;
		r.type = type;
		String labelName = r.resultObjectAPIName.left(r.resultObjectAPIName.length() - 3);
		labelName = labelName + 'Label__c';
		CBOrgVariable__c orgVariable = CBOrgVariableSelector.getOrgVariableServer();
		r.resultObjectName = (String) orgVariable.get(labelName);
		r.filter = mr.SourceFilter__c;
		r.sourceNumberTotal = CBUtils.getNumberOfRecords(mr.SourceSObject__c, null);
		r.sourceNumber = CBUtils.getNumberOfRecords(mr.SourceSObject__c, mr.SourceFilter__c);
		r.resultNumber = CBUtils.getNumberOfRecords(mr.ResultSObject__c, null);
		if (r.sourceNumber > r.resultNumber) {
			r.warning = 'There are records that are not mapped to the CloudBudget side';
		}
		if (r.sourceNumber < r.resultNumber) {
			r.warning = 'CloudBudget has records that are not in the source side';
		}
		return r;
	}

	/**
	 * Default params for the Home chart
	 *
	 * @return params
	 */
	@AuraEnabled
	public static Map<String, String> getHomeChartDefaultParamsServer() {
		try {
			if ([SELECT COUNT() FROM CBCube__c WITH SECURITY_ENFORCED LIMIT 1] == 0) CBLightCubeRefreshTriggerService.refreshAllCBCubes();
			Map<String, String> params = new Map<String, String>();
			String byName = String.valueOf(System.today().year());
			params.put('cblight__CBBudgetYear__c', [SELECT Id FROM cblight__CBBudgetYear__c WHERE Name = :byName WITH SECURITY_ENFORCED][0].Id);
			List<cblight__CBScenario__c> scenarios = [SELECT Id FROM cblight__CBScenario__c WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1];
			if (scenarios.size() > 0) {
				params.put('cblight__CBScenario__c', scenarios[0].Id);
			}

			String plusType = '';
			String minusType = '';
			for (cblight__CBAccountType__c accType : [SELECT Name, cblight__Sign__c FROM cblight__CBAccountType__c WITH SECURITY_ENFORCED]) {
				if (accType.Sign__c == '+') plusType += plusType.length() > 1 ? ', ' + accType.Name : accType.Name;
				if (accType.Sign__c == '-') minusType += minusType.length() > 1 ? ', ' + accType.Name : accType.Name;
			}
			params.put('plusType', plusType);
			params.put('minusType', minusType);
			params.put('cblight__CBAccountSign__c', '+');

			return params;
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * @param params home page params
	 *
	 * @return aggregated data for the home chart (plan)
	 */
	@AuraEnabled
	public static List<AggregateResult> getBaseBudgetForChartServer(Map<String, String> params) {
		String sf = 'SELECT SUM(cblight__Value__c) value, MAX(cblight__CBPeriod__r.Name) period, MAX(cblight__CBBudgetLine__r.cblight__CBScenario__r.Name) scName FROM cblight__CBAmount__c ';
		String w = 'WHERE (cblight__Value__c > 10 OR cblight__Value__c < -10) AND ' + new CBUtils(params)
				.addFilterStr('cblight__CBBudgetYear__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBDivision__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBAccount__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBScenario__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBVariable1__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBVariable2__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBVariable3__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBVariable4__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBVariable5__c', 'cblight__CBBudgetLine__r.')
				.addFilterStr('cblight__CBAccountSign__c', 'cblight__CBBudgetLine__r.')
				.getResult();
		String go = 'GROUP BY cblight__CBPeriod__r.cblight__Start__c, cblight__CBBudgetLine__r.cblight__CBScenario__c ORDER BY cblight__CBPeriod__r.cblight__Start__c ';
		return Database.query(sf + w + go);
	}

	/**
 	* @param params home page params
 	*
	* @return aggregated data for the home chart (actual)
 	*/
	@AuraEnabled
	public static List<AggregateResult> getInvoiceDataForChartServer(Map<String, String> params) {
		String sf = 'SELECT SUM(cblight__Amount__c) value, MAX(cblight__CBInvoice__r.cblight__CBPeriod__r.Name) period FROM cblight__CBInvoiceLine__c  ';
		String w = 'WHERE (cblight__Amount__c > 10 OR cblight__Amount__c < -10) AND ' + new CBUtils(params)
				.addFilterStr('cblight__CBBudgetYear__c', 'cblight__CBInvoice__r.cblight__CBPeriod__r.')
				.addFilterStr('cblight__CBDivision__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBAccount__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBVariable1__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBVariable2__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBVariable3__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBVariable4__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBVariable5__c', 'cblight__CBInvoice__r.')
				.addFilterStr('cblight__CBAccountSign__c', 'cblight__CBInvoice__r.')
				.getResult();
		String go = 'GROUP BY cblight__CBInvoice__r.cblight__CBPeriod__r.cblight__Start__c ORDER BY cblight__CBInvoice__r.cblight__CBPeriod__r.cblight__Start__c ';
		return Database.query(sf + w + go);
	}

	/**
	 * @return current pack version
	 */
	@AuraEnabled
	public static Integer getPackageVersionServer() {
		try {
			return [
					SELECT MinorVersion
					FROM Publisher
					WHERE NamespacePrefix = 'cblight'
					ORDER BY MajorVersion DESC, MinorVersion DESC
					LIMIT 1
			][0].MinorVersion;
		} catch (Exception e) {
			return -1;
		}
	}

	/**
	 * Method runs mapping job
	 */
	@AuraEnabled
	public static String syncMappedAnalyticsServer() {
		CBTaskQueue__c tq = new CBTaskQueueSelector().getTaskQueueWithTaskChildren('Name = \'' + CBInitWizardPageController.MAPPING_TQ_NAME + '\'  ');
		if (tq == null) return 'There is no task queue for mapping';
		return CBTaskDispatcherService.runQueue(tq.Id);
	}

	public class ReportRow {
		public ReportRow(String type) {
			sourceObjectName = 'Source is not specified for ' + type;
		}
		@AuraEnabled
		public String sourceObjectAPIName { get; set; }
		@AuraEnabled
		public String sourceObjectName { get; set; }
		@AuraEnabled
		public String resultObjectAPIName { get; set; }
		@AuraEnabled
		public String resultObjectName { get; set; }
		@AuraEnabled
		public String filter { get; set; }
		@AuraEnabled
		public Integer sourceNumberTotal { get; set; }
		@AuraEnabled
		public Integer sourceNumber { get; set; }
		@AuraEnabled
		public Integer resultNumber { get; set; }
		@AuraEnabled
		public String warning { get; set; }


		@AuraEnabled
		public Integer lim { get; set; }
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public Integer value { get; set; }
	}


}