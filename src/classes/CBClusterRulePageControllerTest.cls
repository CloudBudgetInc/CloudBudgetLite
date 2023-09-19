/** 
Created by Aleksei Volkov on 06/23/2022.
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

This test class covers the CBClusterRuleSelector class
 */
@isTest
public class CBClusterRulePageControllerTest {
    
    @isTest
    public static void testGetClusterRules() {
        List<CBClusterRule__c> clRules = CBDataFactoryTest.createClusterRules(1);
        String recordId = clRules[0].Id;
        CBClusterRule__c actualClusterRule = CBClusterRulePageController.getCBClusterRuleServer(recordId);
        System.assertEquals(clRules[0].Id, actualClusterRule.Id, 'IDs are not equals');
    }

    @isTest
    public static void testSaveClusterLevelsToServer() {
        List<CBClusterRule__c> clRules = CBDataFactoryTest.createClusterRulesWithoutInsertToDB(1);
        CBClusterRulePageController.saveClusterLevelsToServer(clRules[0]);
        List<CBClusterRule__c> actualList = [SELECT Name FROM cblight__CBClusterRule__c];
        System.assertEquals(clRules[0].Name, actualList[0].Name, 'names are not equals');
    }

    @isTest
    public static void testDeleteClusterRuleFromServer() {
        List<CBClusterRule__c> clRules = CBDataFactoryTest.createClusterRules(1);
        CBClusterRulePageController.deleteClusterRuleFromServer(clRules[0]);
        List<CBClusterRule__c> actualList = [SELECT Name FROM cblight__CBClusterRule__c];
        System.assertEquals(0, actualList.size(), 'size is not equals zero');
    }

    @isTest
    public static void testGetBLFieldsSOServer() {
        List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(1);
        List<CBSO> actualList = CBClusterRulePageController.getBLFieldsSOServer();
        System.assert(!actualList.isEmpty(), 'list not empty');
    }
}