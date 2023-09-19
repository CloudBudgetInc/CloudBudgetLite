/**
 Created by Alex JR on 08/18/2022.
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

 This test class covers the CBFormulaService class
 */
@IsTest
public class CBFormulaServiceTest {

	@IsTest
	public static void calculateFormulaTotals() {
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1); // initial value is 1000
		List<CBNonFinancialLibrary__c> libs = CBDataFactoryTest.createNonFinancialLibraries(1);
		List<CBNonFinancialItem__c> nflItems = [SELECT Id, NonFinancialLibrary__c, Value__c, CBPeriod__c FROM CBNonFinancialItem__c WHERE NonFinancialLibrary__c IN: libs];
		nflItems[0].Value__c = amounts[0].Value__c;
		List<List<CBNonFinancialItem__c>> itemsInList = new List<List<CBNonFinancialItem__c>>{
				nflItems, nflItems, nflItems
		};
		amounts = CBFormulaService.calculateFormulaTotals(amounts, itemsInList, ' #1 * ( #2 + #3 ) ');

		Assert.areEqual(amounts[0].Value__c, 2000000, 'values are not equals');
	}

}