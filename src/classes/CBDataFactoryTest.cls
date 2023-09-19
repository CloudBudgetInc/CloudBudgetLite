/**
 * Created by Aleksei Volkov on 06/20/2022.
 * Copyright (c) 2022, CloudBudget, Inc.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * Neither the name of the CloudBudget, Inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * <p/>
 * The util class for test
 */
@isTest
public class CBDataFactoryTest {

	public static List<CBPeriod__c> createPeriods(Integer numPeriods) {
		createOrgVariable();
		List<CBPeriod__c> periods = new List<CBPeriod__c>();
		CBPeriod__c testPeriod;
		CBBudgetYear__c budgetYear = CBDataFactoryTest.createBY();
		for (Integer i = 0; i < numPeriods; i++) {
			testPeriod = new CBPeriod__c(Name = 'Test Period ' + i);
			testPeriod.CBBudgetYear__c = budgetYear.Id;
			testPeriod.Start__c = budgetYear.Start__c;
			testPeriod.End__c = Date.today();
			testPeriod.ExtId__c = 'ExtIdPeiod' + i;
			periods.add(testPeriod);
		}
		upsert periods;
		return periods;
	}

	public static CBBudgetYear__c createBY() {
		createOrgVariable();
		List<CBBudgetYear__c> listBY = [SELECT Id, Start__c FROM cblight__CBBudgetYear__c WHERE Name = 'testBY'];
		if (listBY.size() == 0) {
			CBBudgetYear__c testBY = new CBBudgetYear__c(Name = 'testBY');
			testBY.Start__c = Date.newInstance(2022, 02, 02);
			testBY.ExtId__c = 'ExtIdBY';
			upsert testBY;
			return testBY;
		}
		return listBY[0];
	}

	public static List<CBPeriod__c> createPeriodsWithoutInsertToDB(Integer numPeriods) {
		List<CBPeriod__c> periods = new List<CBPeriod__c>();
		CBPeriod__c testPeriod;
		CBBudgetYear__c testBY = new CBBudgetYear__c(Name = 'testBY');
		testBY.Start__c = Date.newInstance(2022, 02, 02);
		for (Integer i = 0; i < numPeriods; i++) {
			testPeriod = new CBPeriod__c(Name = 'Test Period ' + i);
			testPeriod.CBBudgetYear__c = testBY.Id;
			testPeriod.Start__c = testBY.Start__c;
			testPeriod.End__c = Date.today();
			testPeriod.ExtId__c = 'ExtIdPeiod' + i;
			periods.add(testPeriod);
		}
		return periods;
	}

	public static List<CBAccount__c> createAccounts(Integer numAccounts) {
		List<CBAccount__c> acntList = new List<CBAccount__c>();
		List<CBAccountType__c> acntTypes = CBDataFactoryTest.createAccountTypes(1);
		CBSubAccount__c subAcnt = CBDataFactoryTest.createSubAccount();
		for (Integer i = 0; i < numAccounts; i++) {
			CBAccount__c acnt = new CBAccount__c(Name = 'Test acnt ' + i);
			acnt.CBAccountType__c = acntTypes[0].Id;
			acnt.CBSubAccount__c = subAcnt.Id;
			acntList.add(acnt);
		}
		upsert acntList;
		return acntList;
	}

	public static List<CBAccountType__c> createAccountTypes(Integer num) {
		List<CBAccountType__c> acntTypes = new List<CBAccountType__c>();
		List<CBStyle__c> styles = CBDataFactoryTest.createStyles(num, 'Account Type ');
		for (Integer i = 0; i < num; i++) {
			CBAccountType__c acntType = new CBAccountType__c(Name = 'Test Account Type ' + i);
			acntType.CBStyle__c = styles[i].Id;
			acntType.Sign__c = '+';
			acntType.ExtId__c = 'ExtId' + i;
			acntTypes.add(acntType);
		}
		upsert acntTypes;
		return acntTypes;
	}

	public static CBSubAccount__c createSubAccount() {
		CBSubAccount__c subAcnt = new CBSubAccount__c(Name = 'Test SubAccount');
		subAcnt.ExtId__c = 'ExtId';
		upsert subAcnt;
		return subAcnt;
	}

	public static List<CBAmount__c> createAmounts(Integer numAmounts) {
		List<CBAmount__c> amounts = new List<CBAmount__c>();
		List<CBBudgetLine__c> listBL = CBDataFactoryTest.createBudgetLines(1);
		List<CBStyle__c> styles = [SELECT Id FROM CBStyle__c WHERE Name LIKE '%Amount%'];
		if (styles.isEmpty()) {
			styles = CBDataFactoryTest.createStyles(numAmounts, 'Amount');
		}
		List<CBPeriod__c> periods = [SELECT Id FROM CBPeriod__c];
		for (Integer i = 0; i < numAmounts; i++) {
			CBAmount__c amount = new CBAmount__c(Name = 'Test Amount ' + i);
			amount.CBPeriod__c = periods[0].Id;
			amount.CBBudgetLine__c = listBL[0].Id;
			amount.Value__c = 1000;
			amount.CBStyle__c = styles[0].Id;
			amounts.add(amount);
		}
		upsert amounts;
		return amounts;
	}

	public static List<CBBudgetLine__c> createBudgetLines(Integer numBL) {
		List<CBBudgetLine__c> listBL = new List<CBBudgetLine__c>();
		List<CBPeriod__c> periods = CBDataFactoryTest.createPeriods(1);
		List<CBDivision__c> div = CBDataFactoryTest.createDivisions(1);
		List<CBAccount__c> acnts = CBDataFactoryTest.createAccounts(1);
		CBVariable1__c var1 = CBDataFactoryTest.createVariable1();
		CBVariable2__c var2 = CBDataFactoryTest.createVariable2();
		CBVariable3__c var3 = CBDataFactoryTest.createVariable3();
		for (Integer i = 0; i < numBL; i++) {
			CBBudgetLine__c budgetLine = new CBBudgetLine__c(Name = 'Test BL ' + i);
			budgetLine.CBBudgetYear__c = periods[0].CBBudgetYear__c;
			budgetLine.CBDivision__c = div[0].Id;
			budgetLine.CBAccount__c = acnts[0].Id;
			budgetLine.CBVariable1__c = var1.Id;
			budgetLine.CBVariable2__c = var2.Id;
			budgetLine.CBVariable3__c = var3.Id;
			listBL.add(budgetLine);
		}
		upsert listBL;
		return listBL;
	}

	public static CBVariable1__c createVariable1() {
		CBVariable1__c var1 = new CBVariable1__c();
		var1.Code__c = '1';
		insert var1;
		return var1;
	}

	public static CBVariable2__c createVariable2() {
		CBVariable2__c var2 = new CBVariable2__c();
		insert var2;
		return var2;
	}

	public static CBVariable3__c createVariable3() {
		CBVariable3__c var3 = new CBVariable3__c();
		insert var3;
		return var3;
	}

	public static CBVariable4__c createVariable4() {
		CBVariable4__c var4 = new CBVariable4__c();
		insert var4;
		return var4;
	}

	public static CBVariable5__c createVariable5() {
		CBVariable5__c var5 = new CBVariable5__c();
		insert var5;
		return var5;
	}

	public static List<CBNonFinancialLibrary__c> createNonFinancialLibraries(Integer numNFL) {
		List<CBNonFinancialLibrary__c> listNFL = new List<CBNonFinancialLibrary__c>();
		List<CBLayer__c> layers = CBDataFactoryTest.createLayers(1);
		for (Integer i = 0; i < numNFL; i++) {
			CBNonFinancialLibrary__c nfl = new CBNonFinancialLibrary__c(Name = 'Test NFL ' + i);
			nfl.Layer__c = layers[0].Id;
			listNFL.add(nfl);
		}
		upsert listNFL;
		return listNFL;
	}

	public static CBCube__c createCBCube() {
		CBCube__c testCube = new CBCube__c();
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		List<CBPeriod__c> periods = [SELECT Id, Name, cblight__CBBudgetYear__c, Start__c, End__c FROM cblight__CBPeriod__c];
		List<CBDivision__c> divs = [SELECT Id, Name FROM cblight__CBDivision__c];
		List<CBAccount__c> acnts = [SELECT Id, Name FROM cblight__CBAccount__c];
		testCube.CBPeriod__c = periods[0].Id;
		testCube.CBBudgetYear__c = periods[0].CBBudgetYear__c;
		testCube.CBDivision__c = divs[0].Id;
		testCube.CBAccount__c = acnts[0].Id;
		upsert testCube;
		return testCube;
	}

	public static CBInvoice__c createInvoice() {
		CBInvoice__c testInvoice = new CBInvoice__c(Name = 'Test Invoice');
		List<CBPeriod__c> periods = [SELECT Id, Name, cblight__CBBudgetYear__c, Start__c, End__c FROM cblight__CBPeriod__c];
		List<CBDivision__c> divs = [SELECT Id, Name FROM cblight__CBDivision__c];
		List<CBAccount__c> acnts = [SELECT Id, Name FROM cblight__CBAccount__c];
		testInvoice.CBPeriod__c = periods[0].Id;
		testInvoice.CBDivision__c = divs[0].Id;
		testInvoice.CBAccount__c = acnts[0].Id;
		insert testInvoice;
		insert new CBInvoiceLine__c(Amount__c = 11, CBInvoice__c = testInvoice.Id);
		return [
				SELECT Id, Name, (SELECT Id, Amount__c FROM CBInvoiceLines__r), Total__c, CBPeriod__c, CBDivision__c, CBAccount__c
				FROM CBInvoice__c
				WHERE Name = 'Test Invoice'
				LIMIT 1
		][0];
	}

	public static List<CBClusterRule__c> createClusterRules(Integer numClRules) {
		List<CBClusterRule__c> clRules = new List<CBClusterRule__c>();
		for (Integer i = 0; i < numClRules; i++) {
			CBClusterRule__c clRule = new CBClusterRule__c();
			clRule.Name = 'Test Clucter Rule ' + i;
			clRule.Level1__c = 'division';
			clRules.add(clRule);
		}
		upsert clRules;
		return clRules;
	}

	public static List<CBClusterRule__c> createClusterRulesWithoutInsertToDB(Integer numClRules) {
		List<CBClusterRule__c> clRules = new List<CBClusterRule__c>();
		for (Integer i = 0; i < numClRules; i++) {
			CBClusterRule__c clRule = new CBClusterRule__c();
			clRule.Name = 'Test Clucter Rule ' + i;
			clRule.Level1__c = 'division';
			clRules.add(clRule);
		}
		return clRules;
	}

	public static List<CBDivision__c> createDivisions(Integer numDivision) {
		List<CBDivision__c> divisions = new List<CBDivision__c>();
		for (Integer i = 0; i < numDivision; i++) {
			CBDivision__c testDivision = new CBDivision__c();
			testDivision.Name = 'Test Division ' + i;
			testDivision.ExtId__c = 'div' + i;
			divisions.add(testDivision);
		}
		upsert divisions;
		return divisions;
	}

	public static List<CBStyle__c> createStyles(Integer numStyles, String uniqName) {
		List<CBStyle__c> styles = new List<CBStyle__c>();

		for (Integer i = 0; i < numStyles; i++) {
			CBStyle__c testStyle = new CBStyle__c(Name = uniqName + ': ' + i);
			styles.add(testStyle);
		}
		upsert styles;
		return styles;
	}

	public static List<CBTask__c> createTasks(Integer numTask) {
		List<CBModelingLine__c> modRuleLines = CBDataFactoryTest.createModelingLines(1);
		List<CBTask__c> taskList = new List<CBTask__c>();
		List<CBTaskQueue__c> taskQueueList = CBDataFactoryTest.createTaskQueues(1);
		for (Integer i = 0; i < numTask; i++) {
			CBTask__c testTask = new CBTask__c();
			testTask.Name = 'Test Task ' + i;
			testTask.CBTaskQueue__c = taskQueueList[0].Id;
			testTask.ClassName__c = 'CBModelingRuleJobProcess';
			testTask.Parameter1__c = modRuleLines[0].CBModelingRule__c;
			testTask.Parameter2__c = null;
			taskList.add(testTask);
		}
		upsert taskList;
		return taskList;
	}

	public static List<CBTaskQueue__c> createTaskQueues(Integer numQueue) {
		List<CBTaskQueue__c> taskQueueList = new List<CBTaskQueue__c>();
		for (Integer i = 0; i < numQueue; i++) {
			CBTaskQueue__c testTaskQueue = new CBTaskQueue__c(Name = 'Test Task Queue' + i);
			testTaskQueue.Status__c = 'Idle';
			taskQueueList.add(testTaskQueue);
		}
		upsert taskQueueList;
		return taskQueueList;
	}

	public static List<CBLog__c> createLogs(Integer numLog) {
		List<CBLog__c> logs = new List<CBLog__c>();
		for (Integer i = 0; i < numLog; i++) {
			CBLog__c log = new CBLog__c();
			log.Name = 'Test Log ' + i;
			logs.add(log);
		}
		upsert logs;
		return logs;
	}

	public static CBEvent__e createEvent() {
		CBEvent__e event = new CBEvent__e();
		event.Description__c = 'test event';
		insert event;
		return event;
	}

	public static CBMapping__c createDivisionCBMapping() {
		CBMapping__c cbMapping = new CBMapping__c();
		cbMapping.Name = 'Test Division CBMapping';
		cbMapping.Type__c = 'divisions';
		cbMapping.SourceSObject__c = 'cblight__CBDivision__c';
		cbMapping.SourceFilter__c = 'Name LIKE \'%' + 'Test' + '%\'';
		cbMapping.ResultSObject__c = 'cblight__CBDivision__c';
		cbMapping.ResultType__c = 'Id';
		cbMapping.SourceType__c = 'Id';
		insert cbMapping;
		return cbMapping;
	}

	public static CBMapping__c createPeriodCBMapping() {
		CBMapping__c cbMapping = new CBMapping__c();
		cbMapping.Name = 'Test Period CBMapping';
		cbMapping.Type__c = 'periods';
		cbMapping.SourceSObject__c = 'cblight__CBBudgetYear__c';
		cbMapping.SourceFilter__c = 'Name LIKE \'%' + 'Test' + '%\'';
		cbMapping.ResultSObject__c = 'CBPeriod__c';
		cbMapping.ResultType__c = 'CBPeriod__c';
		cbMapping.SourceType__c = 'Start__c';
		cbMapping.SourceSubtype__c = 'ExtId__c';
		insert cbMapping;
		return cbMapping;
	}

	public static CBMapping__c createAcntCBMapping() {
		CBMapping__c cbMapping = new CBMapping__c();
		cbMapping.Name = 'Test Acnt CBMapping';
		cbMapping.Type__c = 'accounts';
		cbMapping.SourceSObject__c = 'cblight__CBAccount__c';
		cbMapping.SourceFilter__c = 'Name LIKE \'%' + 'Test' + '%\'';
		cbMapping.ResultSObject__c = 'CBAccount__c';
		cbMapping.ResultType__c = 'accounts';
		cbMapping.SourceType__c = 'CBAccountType__c';
		cbMapping.SourceSubtype__c = 'CBSubAccount__c';
		insert cbMapping;
		return cbMapping;
	}

	public static CBMapping__c createVariableCBMapping(Integer num) {
		CBMapping__c cbMapping = new CBMapping__c();
		cbMapping.Name = 'Test Variable CBMapping';
		cbMapping.Type__c = 'variables' + num;
		cbMapping.SourceSObject__c = 'cblight__CBVariable' + num + '__c';
		cbMapping.SourceType__c = 'Id';
		insert cbMapping;
		return cbMapping;
	}

	public static List<CBLayer__c> createLayers(Integer numLayer) {
		List<CBLayer__c> layers = new List<CBLayer__c>();
		for (Integer i = 0; i < numLayer; i++) {
			CBLayer__c layer = new CBLayer__c();
			layer.Name = 'Test Layer ' + i;
			layers.add(layer);
		}
		upsert layers;
		return layers;
	}

	public static List<CBModelingRuleGroup__c> createModelingRuleGroups(Integer numModRGr) {
		List<CBModelingRuleGroup__c> modelingRuleGroups = new List<CBModelingRuleGroup__c>();
		for (Integer i = 0; i < numModRGr; i++) {
			CBModelingRuleGroup__c modRuleGr = new CBModelingRuleGroup__c();
			modRuleGr.Label__c = 'Test Modeling Rule Group' + i;
			modRuleGr.DeleteOldResults__c = true;
			modelingRuleGroups.add(modRuleGr);
		}
		upsert modelingRuleGroups;
		return modelingRuleGroups;
	}

	public static List<CBModelingRule__c> createModelingRules(Integer numModRule) {
		List<CBModelingRule__c> modelingRules = new List<CBModelingRule__c>();
		List<CBModelingRuleGroup__c> modelingRuleGroups = CBDataFactoryTest.createModelingRuleGroups(numModRule);
		for (Integer i = 0; i < numModRule; i++) {
			CBModelingRule__c modRule = new CBModelingRule__c();
			modRule.Name = 'Test Modeling Rule ' + i;
			modRule.CBModelingRuleGroup__c = modelingRuleGroups[i].Id;
			modRule.Mode__c = 'General';
			modRule.PeriodShift__c = 1;
			modRule.ResultRecordParentType__c = 'cblight__CBCube__c';
			modRule.SourceRecordParentType__c = 'cblight__CBBudgetLine__c';
			modRule.SourceRecordChildType__c = 'cblight__CBAmount__c';
			modRule.KeyFields__c = 'CBAmount__c, CBBudgetLine__c, CBCube__c, CBPeriod__c';
			modRule.SourceParentFilter__c = 'Name LIKE \'%' + 'Test' + '%\'';
			modelingRules.add(modRule);
		}
		upsert modelingRules;
		return modelingRules;
	}

	public static List<CBModelingLine__c> createModelingLines(Integer numModLine) {
		List<CBModelingLine__c> modelingLines = new List<CBModelingLine__c>();
		List<CBModelingRule__c> modelingRules = CBDataFactoryTest.createModelingRules(1);
		for (Integer i = 0; i < numModLine; i++) {
			CBModelingLine__c modLine = new CBModelingLine__c();
			modLine.Name = 'Period';
			modLine.CBModelingRule__c = modelingRules[0].Id;
			modLine.ResultFieldFrom__c = 'Parent';
			modLine.ResultField__c = 'cblight__CBPeriod__c';
			modLine.SourceField__c = 'cblight__CBPeriod__c';
			modLine.SourceFieldFrom__c = 'Child';
			modLine.isGlobal__c = true;
			modLine.SourceObjectType__c = 'cblight__CBBudgetLine__c';
			modLine.ResultObjectType__c = 'cblight__CBCube__c';
			modLine.Type__c = 'REFERENCE';
			modelingLines.add(modLine);
		}
		for (Integer i = 0; i < numModLine; i++) {
			CBModelingLine__c modLine = new CBModelingLine__c();
			modLine.Name = 'Division';
			modLine.CBModelingRule__c = modelingRules[0].Id;
			modLine.ResultFieldFrom__c = 'Parent';
			modLine.ResultField__c = 'CBDivision__c';
			modLine.SourceField__c = 'CBDivision__c';
			modLine.SourceFieldFrom__c = 'Parent';
			modLine.isGlobal__c = true;
			modLine.SourceObjectType__c = 'cblight__CBBudgetLine__c';
			modLine.ResultObjectType__c = 'cblight__CBCube__c';
			modLine.Type__c = 'REFERENCE';
			modelingLines.add(modLine);
		}
		upsert modelingLines;
		return modelingLines;
	}

	public static List<CBReport__c> createReports(Integer numRep) {
		List<CBReport__c> reports = new List<CBReport__c>();
		for (Integer i = 0; i < numRep; i++) {
			CBReport__c testReport = new CBReport__c(Name = 'Test Report ' + i);
			testReport.Mode__c = 'Auto';
			reports.add(testReport);
		}
		upsert reports;
		return reports;
	}

	public static List<CBReportColumn__c> createReportColumns(Integer numColumns) {
		List<CBReportColumn__c> reportColumns = new List<CBReportColumn__c>();
		List<CBReport__c> reports = CBDataFactoryTest.createReports(1);
		List<CBPeriod__c> periods = CBDataFactoryTest.createPeriods(1);
		List<CBStyle__c> styles = CBDataFactoryTest.createStyles(1, 'Report Column');
		for (Integer i = 0; i < numColumns; i++) {
			CBReportColumn__c testColumn = new CBReportColumn__c(Name = 'Test Column ' + i);
			testColumn.CBReport__c = reports[0].Id;
			testColumn.FontStyle__c = 'Normal';
			testColumn.Type__c = 'Master';
			testColumn.CBPeriod__c = periods[0].Id;
			testColumn.CBStyle__c = styles[0].Id;
			reportColumns.add(testColumn);
		}
		upsert reportColumns;
		return reportColumns;
	}

	public static List<CBReportConfiguration__c> createReportConfigurations(Integer numRepConf) {
		List<CBReportConfiguration__c> reportConfs = new List<CBReportConfiguration__c>();
		List<CBReport__c> reports = CBDataFactoryTest.createReports(1);
		CBCube__c cube = CBDataFactoryTest.createCBCube();
		for (Integer i = 0; i < numRepConf; i++) {
			CBReportConfiguration__c testReportConfiguration = new CBReportConfiguration__c(Name = 'Test Report Configuration' + i);
			testReportConfiguration.CBReport__c = reports[0].Id;
			testReportConfiguration.Filter__c = 'cblight__CBBudgetYear__c = \'' + cube.CBBudgetYear__c + '\' ';
			testReportConfiguration.SubtotalNumber__c = 1;
			testReportConfiguration.Grouping__c = '["cblight__CBDivision__c"]';
			reportConfs.add(testReportConfiguration);
		}
		upsert reportConfs;
		return reportConfs;
	}

	public static List<CBRevision__c> createRevisions(Integer numRevs) {
		List<CBRevision__c> revisions = new List<CBRevision__c>();
		List<CBDivision__c> divs = CBDataFactoryTest.createDivisions(1);
		for (Integer i = 0; i < numRevs; i++) {
			CBRevision__c revision = new CBRevision__c(Name = 'Test Revision ' + i);
			revision.Parent__c = divs[0].Id;
			revisions.add(revision);
		}
		upsert revisions;
		return revisions;
	}

	public static List<CBLogDetail__c> createLogDetails(Integer numLogDetails) {
		List<CBLogDetail__c> logDetails = new List<CBLogDetail__c>();
		for (Integer i = 0; i < numLogDetails; i++) {
			CBLogDetail__c logDetail = new CBLogDetail__c(Name = 'Test Log Detail ' + i);
			logDetails.add(logDetail);
		}
		upsert logDetails;
		return logDetails;
	}

	public static CBWelcome__c createCBWelcome() {
		CBWelcome__c welcome = new CBWelcome__c(Name = 'Test Welcome');
		welcome.Type__c = 'Simple';
		insert welcome;
		return welcome;
	}

	public static CBOrgVariable__c createOrgVariable() {
		try {
			CBOrgVariable__c orgVar = new CBOrgVariable__c(Name = 'Test OrgVariable', PeriodValidationEnabled__c = true);
			insert orgVar;
			return orgVar;
		} catch (Exception e) {
			return CBOrgVariableSelector.getOrgVariableServer();
		}
	}

	public static cblight__CBCalculationRule__c createCalculationRule(String mode) {
		cblight__CBCalculationRule__c calculationRule = new cblight__CBCalculationRule__c(Name = 'Test', cblight__Formula__c = '$1 * $2', cblight__Value__c = 1, Mode__c = mode == null ? 'one-to-one' : mode);
		insert calculationRule;
		return calculationRule;
	}

	public static List<CBFunction__c> createFunctions(Integer numFunctions) {
		List<CBFunction__c> functions = new List<CBFunction__c>();
		List<CBAccount__c> acnts = CBDataFactoryTest.createAccounts(1);
		List<CBDivision__c> divs = CBDataFactoryTest.createDivisions(1);
		for (Integer i = 0; i < numFunctions; i++) {
			CBFunction__c func = new CBFunction__c(Name = 'Test Function ' + i);
			func.CBAccount__c = acnts[0].Id;
			func.CBDivision__c = divs[0].Id;
			functions.add(func);
		}
		upsert functions;
		return functions;
	}

	public static ContentVersion createContentVersion() {
		List<CBBudgetLine__c> bLines = CBDataFactoryTest.createBudgetLines(1);
		ContentVersion cv = new ContentVersion();
		cv.Title = 'strFileName';
		cv.PathOnClient = '/strFileName';
		cv.FirstPublishLocationId = bLines[0].Id;
		cv.VersionData = EncodingUtil.base64Decode('base64Data');
		cv.IsMajorVersion = true;
		insert cv;
		return cv;
	}

}