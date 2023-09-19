/** 
Created by Alex JR 2022.
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

This test class covers the CBCalculationRulePageController class
 */
@isTest
public class CBCalculationRulePageControllerTest {

	@isTest
	public static void testGetCalculationRules() {
		CBCalculationRule__c testCR = CBDataFactoryTest.createCalculationRule(null);
		List<CBCalculationRule__c> testCRs = CBCalculationRulePageController.getCalculationRulesServer(null);
		Map<String, Object> r = CBCalculationRulePageController.getSingleCalculationRuleServer(testCR.Id);
		System.assert(testCRs.size() > 0, 'list is empty');
	}

	@isTest
	public static void testGetSelectOptions() {
		Map<String, List<CBSO>> r = CBCalculationRulePageController.getSelectOptionsServer();
		System.assert(r.size() > 0, 'map is empty');
	}

	@isTest
	public static void testSaveAndDeleteCalculationRule() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			cblight__CBCalculationRule__c cr = new cblight__CBCalculationRule__c(Name = 'Test 2', Value__c = 7);
			String crId = CBCalculationRulePageController.saveCalculationRuleServer(cr);
			System.assert(!String.isEmpty(crId), 'string is empty');
			CBCalculationRulePageController.deleteCalculationRuleServer(crId);
		}
	}

	@isTest
	public static void testCheckSourceData() {
		CBDataFactoryTest.createBudgetLines(1);
		Map<String, String> report = CBCalculationRulePageController.checkSourceBudgetLineServer(null, null);
		System.assert(report.size() > 0, 'report is empty');
	}

	@IsTest
	public static void testGetNFLibrary() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			CBDataFactoryTest.createPeriods(1);
			List<CBNonFinancialLibrary__c> nfl = CBDataFactoryTest.createNonFinancialLibraries(1);
			List<CBNonFinancialItem__c> items = CBCalculationRulePageController.getNFLAmountsServer(nfl[0].Id);

			Assert.isTrue(items.size() > 0, 'items list is empty');
		}
	}


}