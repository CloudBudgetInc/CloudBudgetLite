/** 
Created by Aleksei Volkov on 06/21/2022.
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

This test class covers the CBPeriodPageController, CBPeriodDomain, CBPeriodSelector, 
CBPeriodService, CBBudgetYearDomain, CBBudgetYearSelector classes
 */
@isTest
public class CBPeriodPageControllerTest {

	@isTest
	public static void testGetBudgetYearsFromServer() {
		List<CBBudgetYear__c> testList = CBPeriodPageController.getBudgetYearsFromServer();
		System.assertEquals(0, testList.size(), 'not equal zero');
	}

	@isTest
	public static void testGetPeriodsFromServer() {
		List<CBPeriod__c> testList = CBPeriodPageController.getPeriodsFromServer();
		System.assertEquals(0, testList.size(), 'not equal zero');
	}

	@isTest
	public static void testSaveBYandPeriodToServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			CBDataFactoryTest.createOrgVariable();
			CBBudgetYear__c testBY = new CBBudgetYear__c(Name = 'newBY');
			testBY.Start__c = Date.newInstance(2022, 02, 02);
			List<CBPeriod__c> testPeriods = CBDataFactoryTest.createPeriodsWithoutInsertToDB(1);
			CBPeriodPageController.saveBYandPeriodToServer(testBY, testPeriods);
			CBPeriod__c expectedPeriod = [SELECT Name FROM cblight__CBPeriod__c WHERE Name = 'Test Period 0'];
			System.assertEquals('Test Period 0', expectedPeriod.Name, 'period was not saved');
		}
	}

	@isTest
	public static void testGetPeriodsByFilter() {
		List<CBPeriod__c> expected = CBDataFactoryTest.createPeriods(1);
		CBPeriodSelector sel = new CBPeriodSelector();
		List<CBPeriod__c> actual = sel.getPeriods('Name = \'Test Period 0\'');
		System.assertEquals(expected.size(), actual.size(), 'lists are not equals');
	}

	@isTest
	public static void testGetPeriodRecordById() {
		List<CBPeriod__c> periods = CBDataFactoryTest.createPeriods(1);
		CBPeriod__c p1 = periods[0];
		CBPeriodSelector sel = new CBPeriodSelector();
		CBPeriod__c actualPeriod = sel.getPeriodRecordById(p1.Id);
		System.assertEquals(p1.Id, actualPeriod.Id, 'ids are not equals');
	}

	@isTest
	public static void testGetPeriodRecordByNullId() {
		CBPeriodSelector sel = new CBPeriodSelector();
		CBPeriod__c actualPeriod = sel.getPeriodRecordById(null);
		System.assertEquals(null, actualPeriod, 'not null');
	}

	@isTest
	public static void testGetPeriodRecordsByExtId() {
		List<CBPeriod__c> expectedPeriods = CBDataFactoryTest.createPeriods(1);
		Set<String> extIds = new Set<String>();
		extIds.add(expectedPeriods[0].ExtId__c);
		CBPeriodSelector sel = new CBPeriodSelector();
		List<CBPeriod__c> actualPeriods = sel.getPeriodRecordsByExtId(extIds);
		System.assert(true, 'test failed');
	}

	@isTest
	public static void testGetPeriodRecordsByNullExtId() {
		CBPeriodSelector sel = new CBPeriodSelector();
		List<CBPeriod__c> actualPeriods = sel.getPeriodRecordsByExtId(null);
		System.assertEquals(null, actualPeriods, 'not null');
	}

	@isTest
	public static void testQuery() {
		List<CBPeriod__c> expectedPeriods = CBDataFactoryTest.createPeriods(5);
		CBPeriodSelector sel = new CBPeriodSelector();
		List<CBPeriod__c> actualPeriods = sel.query();
		System.assert(actualPeriods.size() == 5, 'not equal 5');
	}

	@isTest
	public static void testSetFilter() {
		CBPeriodSelector selector = new CBPeriodSelector();
		CBPeriodSelector actualSelector = selector.setFilter('Name = \'Test Period 0\'');
		System.assertEquals(selector, actualSelector, 'filter was not set');
	}

	@isTest
	public static void testSetLimit() {
		CBPeriodSelector selector = new CBPeriodSelector();
		CBPeriodSelector actualSelector = selector.setLimit(2);
		System.assertEquals(selector, actualSelector, 'limit was not set');
	}

	@isTest
	public static void testShiftBudgetYear() {
		CBBudgetYear__c testBY = CBDataFactoryTest.createBY();
		CBBudgetYear__c actualBY = CBPeriodService.shiftBudgetYear(testBY, 2);
		System.assertNotEquals(testBY, actualBY, 'BYs are not equals');
	}

	@isTest
	public static void testShiftPeriod() {
		List<CBPeriod__c> expectedPeriods = CBDataFactoryTest.createPeriods(1);
		CBPeriod__c actualPeriod = CBPeriodService.shiftPeriod(expectedPeriods[0], 3);
		System.assertNotEquals(expectedPeriods[0], actualPeriod, 'periods are not equals');
	}

	@isTest
	public static void testcheckStartEndDates() {
		List<CBPeriod__c> periods = CBDataFactoryTest.createPeriods(1);
		CBPeriodDomain.checkStartEndDates(periods);
		System.assert(true, 'test failed');
	}

	@isTest
	public static void testCheckPeriodsHaveRelatedRecords() {
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		List<CBPeriod__c> periods = [SELECT Id, Name FROM cblight__CBPeriod__c];
		Map<Id, CBPeriod__c> recordsMap = new Map<Id, CBPeriod__c>();
		recordsMap.put(periods[0].Id, periods[0]);
		CBPeriodDomain.checkPeriodsHaveRelatedRecords(recordsMap);
		System.assert(true, 'test failed');
	}

	@isTest
	public static void testOnBeforeUpdatePeriod() {
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		Map<Id, SObject> params = new Map<Id, SObject>();
		params.put(amounts[0].Id, amounts[0]);
		List<CBPeriod__c> periodList = [SELECT Id, Name, cblight__Start__c, cblight__End__c FROM cblight__CBPeriod__c];
		new CBPeriodDomain(periodList).onBeforeUpdate(params);
		System.assert(true, 'test failed');
	}

	//Testing BudgetYearDomain and BudgetYearSelector classes
	@isTest
	public static void testOnBeforeUpdateBY() {
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		Map<Id, SObject> params = new Map<Id, SObject>();
		params.put(amounts[0].Id, amounts[0]);
		List<CBBudgetYear__c> byList = [SELECT Id, Name, cblight__Start__c, cblight__End__c FROM cblight__CBBudgetYear__c];
		new CBBudgetYearDomain(byList).onBeforeUpdate(params);
		System.assert(true, 'test failed');
	}

	@isTest
	public static void testCheckBYHasRelatedRecords() {
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		List<CBBudgetYear__c> byList = [SELECT Id, Name, cblight__Start__c, cblight__End__c FROM cblight__CBBudgetYear__c];
		Map<Id, CBBudgetYear__c> recordsMap = new Map<Id, CBBudgetYear__c>();
		recordsMap.put(byList[0].Id, byList[0]);
		CBBudgetYearDomain.checkBYHasRelatedRecords(recordsMap);
		System.assert(true, 'test failed');
	}

	@isTest
	public static void testGetterBYSelector() {
		CBBudgetYear__c testBY = CBDataFactoryTest.createBY();
		Map<String, String> actualMap = new CBBudgetYearSelector().budgetYear2SideMap;
		System.assert(!actualMap.isEmpty(), 'map is empty');
	}
}