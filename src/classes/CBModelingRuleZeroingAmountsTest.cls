/** 
Created by Valerii Krykun on 12/14/2022.
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

This test class covers the classes related to CBModelingRuleZeroingAmountsProcess
 */
@isTest
public class CBModelingRuleZeroingAmountsTest {

    @isTest
	public static void runJob() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			Test.startTest();
			CBDataFactoryTest.createPeriods(12);
			CBDataFactoryTest.createAccounts(1);
			CBDataFactoryTest.createModelingLines(1);
			List<CBDivision__c> div = CBDataFactoryTest.createDivisions(1);
			CBModelingRule__c modelingRule = [SELECT CBModelingRuleGroup__c, Id FROM CBModelingRule__c][0];
			System.assert(modelingRule != null, 'MR is null');
			String accountId = [SELECT Id FROM CBAccount__c][0].Id;
			String periodId = [SELECT Id FROM CBPeriod__c ORDER BY Start__c][0].Id;
			insert new CBCube__c(CBPeriod__c = periodId, CBAccount__c = accountId, Budget__c = 1, CBKey__c = modelingRule.CBModelingRuleGroup__c + 'XXXXXXXXXXXXX', cblight__CBDivision__c = div[0].Id);
			new CBModelingRuleZeroingAmountsProcess().runProcess(modelingRule.Id, null);
			Test.stopTest();
		}
	}
}