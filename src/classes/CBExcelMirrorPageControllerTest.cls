/** 
Created by Vlad on 01/20/2023.
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

This test class covers the CBExcelMirrorPageController, CBBudgetLineExcelService
 */

@isTest
public with sharing class CBExcelMirrorPageControllerTest {

	@isTest
	public static void testGetBLForExcelServer() {
		CBDataFactoryTest.createAmounts(2);
		List<CBBudgetLine__c> budgetLines1 = [SELECT Id, NFL1__c, NFL2__c, NFL3__c, NFL4__c, NFL5__c FROM cblight__CBBudgetLine__c];
		List<Id> blIdList = new List<Id>();
		blIdList.add(budgetLines1[0].Id);
		list<CBBudgetLine__c> budgetLines2 =  CBExcelMirrorPageController.getBLForExcelServer(blIdList);
		System.assertEquals(budgetLines1.size(),budgetLines2.size());
		CBExcelMirrorPageController.deleteBudgetLinesServer(blIdList);
	}

	@isTest
	public static void testSaveBudgetLinesWithNFLForExcelServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(2);
			List<CBBudgetLine__c> budgetLines = [SELECT Id, NFL1__c, NFL2__c, NFL3__c, NFL4__c, NFL5__c, cblight__CBBudgetYear__c FROM cblight__CBBudgetLine__c];
			List<CBNonFinancialLibrary__c> nfls1 =  CBDataFactoryTest.createNonFinancialLibraries(1);
			List<CBNonFinancialItem__c> items = [SELECT Id, Name, cblight__CBPeriod__c, cblight__NonFinancialLibrary__c, cblight__Value__c 
			FROM cblight__CBNonFinancialItem__c where cblight__NonFinancialLibrary__c= :nfls1[0].Id];
			CBExcelMirrorService.BLWrapper testBLWrapper = new CBExcelMirrorService.BLWrapper();
			testBLWrapper.amounts = amounts;
			testBLWrapper.budgetLine = budgetLines[0];
			testBLWrapper.nfl1 = nfls1[0];
			testBLWrapper.nfl1Items = items;
			testBLWrapper.nfl2 = null;
			testBLWrapper.nfl2Items = null;
			List<CBExcelMirrorService.BLWrapper> listOfWrappers = new List<CBExcelMirrorService.BLWrapper>();
			listOfWrappers.add(testBLWrapper);
			String s = CBExcelMirrorPageController.saveBudgetLinesWithNFLForExcelServer(listOfWrappers,testBLWrapper.budgetLine.cblight__CBBudgetYear__c);
			System.assertEquals(s,'Ok');
			List<Id> listIdOfNFL = new List<Id>();
			listIdOfNFL.add(nfls1[0].Id);
			List<CBNonFinancialLibrary__c> listOfNFL = CBExcelMirrorPageController.getListOfNFL(listIdOfNFL,testBLWrapper.budgetLine.cblight__CBBudgetYear__c);
		}
	}

	@isTest
	public static void testGetSelectOptionsServer() {
		List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(1);
		Map<String, List<CBSO>> actualMap = CBExcelMirrorPageController.getSelectOptionsServer();
		System.assert(!actualMap.isEmpty());
	}
	
}