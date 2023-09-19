/** 
Created by Aleksei Volkov on 07/27/2022.
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

This test class covers the CBModelingLineSelector class
 */
@isTest
public class CBModelingLineSelectorTest {
    
    @isTest
    public static void testGetModelingLineById() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(1);
            List<CBModelingLine__c> actualList = new CBModelingLineSelector().getModelingLineById(modLines[0].Id);
            System.assertEquals(modLines.size(), 2, 'size is not equals 2');
        }
    }

    @isTest
    public static void testGetModelingLinesByRuleSet() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(5);
            Set<String> rIds = new Set<String>();
            rIds.add(modLines[0].CBModelingRule__c);
            List<CBModelingLine__c> actualList = new CBModelingLineSelector().getModelingLinesByRuleSet(rIds);
            System.assertEquals(modLines.size(), actualList.size(), 'lists are not equals');
        }
    }

    @isTest
    public static void testGetGlobalModelingLinesByModelingRule() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(5);
            List<CBModelingLine__c> actualList = new CBModelingLineSelector().getGlobalModelingLinesByModelingRule(modLines[0].CBModelingRule__c);
            System.assertEquals(modLines.size(), actualList.size(), 'lists are not equals');
        }
    }
}