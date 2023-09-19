/**
 * Created by Aleksei Volkov on 07/29/2022.
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
 * This test class covers the CBReportingPageController, ReportDomain, CBReportSelector
 * CBReportingDrillDownPageController, CBReportConfigurationSelector classes
 */
@isTest
public class CBReportingPageControllerTest {

	@isTest
	public static void testGetAllReportsServer() {
		List<CBReport__c> expectedReports = CBDataFactoryTest.createReports(10);
		List<CBReport__c> actualReports = CBReportingPageController.getAllReportsServer('Name LIKE \'%' + 'Test' + '%\'');
		System.assertEquals(expectedReports.size(), actualReports.size(), 'lists are not equals');
	}

	@isTest
	public static void testGetReportWithConfigurationsAndColumnsServer() {
		List<CBReport__c> expectedReports = CBDataFactoryTest.createReports(10);
		CBReport__c actualReport = CBReportingPageController.getReportWithConfigurationsAndColumnsServer(expectedReports[0].Id);
		System.assertEquals(expectedReports[0].Id, actualReport.Id, 'reports are not equals');
	}

	@isTest
	public static void testGetListOfCubeFieldsSOServer() {
		CBCube__c cube = CBDataFactoryTest.createCBCube();
		List<CBSO> actualList = CBReportingPageController.getListOfCubeFieldsSOServer();
		System.assert(!actualList.isEmpty(), 'list is empty');
	}

	@isTest
	public static void testSaveReportServer() {
		CBReport__c testReport = new CBReport__c(Name = 'Test Report');
		testReport.Mode__c = 'Auto';
		CBReportingPageController.saveReportServer(testReport);
		List<CBReport__c> actualReports = [SELECT Id, Name FROM cblight__CBReport__c];
		System.assert(actualReports.size() == 1, 'list is empty');
	}

	@IsTest
	public static void testDeleteReportConfiguration() {
		List<CBReportConfiguration__c> createdReportConfigs = CBDataFactoryTest.createReportConfigurations(5);
		Id reportId = createdReportConfigs[0].CBReport__c;
		List<CBReportConfiguration__c> resultReportConfigs;

		if (!createdReportConfigs.isEmpty()) {
			CBReportingPageController.deleteReportConfigByConfigSOServer(createdReportConfigs[0]);
			resultReportConfigs = [SELECT Id, CBReport__c FROM CBReportConfiguration__c WHERE CBReport__c = :reportId];
		}
		Assert.areEqual(createdReportConfigs.size(), resultReportConfigs.size() + 1);
	}

	@isTest
	public static void testGetReportDataServer() {
		List<CBReportConfiguration__c> reportConfs = CBDataFactoryTest.createReportConfigurations(1);
		List<CBCube__c> actualList = CBReportingPageController.getReportDataServer(reportConfs[0].Id);
		System.assert(!actualList.isEmpty(), 'list is empty');
	}

	@isTest
	public static void testGetStaticDataServer() {
		List<CBReportColumn__c> reportColumns = CBDataFactoryTest.createReportColumns(10);
		List<CBStyle__c> expectedStyles = [SELECT Id FROM cblight__CBStyle__c];
		Map<String, Object> actualMap = CBReportingPageController.getStaticDataServer();
		List<CBStyle__c> actualStyles = (List<CBStyle__c>) actualMap.get('styles');
		System.assertEquals(expectedStyles[0].Id, actualStyles[0].Id, 'lists are not equals');
	}

	@isTest
	public static void testSaveConfigurationServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBReportConfiguration__c> reportConfs = CBDataFactoryTest.createReportConfigurations(1);
			CBReportConfiguration__c actualReportConf = CBReportingPageController.saveConfigurationServer(reportConfs[0]);
			System.assertEquals(reportConfs[0].Id, actualReportConf.Id, 'configurations are not equals');
		}
	}

	// Testing ReportDomain class
	@isTest
	public static void testOnBeforeDelete() {
		List<CBReportConfiguration__c> reportConfs = CBDataFactoryTest.createReportConfigurations(1);
		List<CBReport__c> expectedReports = [SELECT Id FROM cblight__CBReport__c];
		new CBReportDomain(expectedReports).onBeforeDelete();
		List<CBReportConfiguration__c> actualReports = [SELECT Id FROM cblight__CBReportConfiguration__c];
		System.assert(actualReports.isEmpty(), 'report was not deleted');
	}

	// Test CBReportingDrillDownPageController class
	@isTest
	public static void testGetDrillDownDataServer() {
		List<CBReportConfiguration__c> reportConfs = CBDataFactoryTest.createReportConfigurations(1);
		List<CBPeriod__c> periods = [Select Id FROM cblight__CBPeriod__c];
		List<CBDivision__c> divs = [Select Id FROM cblight__CBDivision__c];
		List<Object> objList = new List<Object>();
		objList.add(divs[0].Id);
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('periodId', periods[0].Id);
		parameters.put('configId', reportConfs[0].Id);
		parameters.put('keys', objList);
		List<CBCube__c> actualList = CBReportingDrillDownPageController.getDrillDownDataServer(parameters);
		System.assert(!actualList.isEmpty(), 'list is empty');
	}
}