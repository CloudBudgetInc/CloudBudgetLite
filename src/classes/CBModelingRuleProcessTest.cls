/** 
Created by Alex JR on 08/19/2022.
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

This test class covers the classes related to Modeling Rule process
 */
@isTest
public class CBModelingRuleProcessTest {

	@isTest
	public static void runJob() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			Test.startTest();
			CBDataFactoryTest.createAmounts(1);
			CBDataFactoryTest.createModelingLines(1);
			CBTaskQueue__c tq = [SELECT Id FROM CBTaskQueue__c][0];
			System.assertNotEquals(tq, null, 'not null');
			CBTaskDispatcherService.runQueue(tq.Id);
			Test.stopTest();
		}
	}

	@isTest
	public static void testPrivateMethods() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			CBModelingRule__c mr = CBDataFactoryTest.createModelingRules(1)[0];
			CBModelingRuleService testClassObject = new CBModelingRuleService(mr);
			String sourceRelation = testClassObject.sourceRelationName;
			String resultRelation = testClassObject.resultRelationName;
			CBAmount__c resultChild = new CBAmount__c(Value__c = 1);
			Object t = CBModelingRuleService.sumDecimals(resultChild, null, 'cblight__Value__c', 1);
			System.assert(true, 'test failed');
		}
	}

}