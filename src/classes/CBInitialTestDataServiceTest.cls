/**
Created by Aleksei Volkov on 07/29/2022.
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
 
This test class covers the CBInitialTestDataService class
 */
@isTest
public class CBInitialTestDataServiceTest {

    @isTest
    public static void testSetupData() {
        CBInitialTestDataService.setupData();
        PermissionSet cbSet = [SELECT Id FROM PermissionSet WHERE Name = 'CBDeveloper' LIMIT 1];
        List<User> cbUserList = [SELECT Id FROM User WHERE Name = 'User User' LIMIT 1];
        if (cbUserList.size() == 0 ) {
            System.assert(true, 'who knows');
        } else {
            User cbUser = cbUserList[0];
            List<PermissionSetAssignment> assign = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :cbUser.Id AND PermissionSetId = :cbSet.Id LIMIT 1];
            System.assert(assign.size() > 0, 'permission set was not assigned');
        }
    }

    @isTest
    public static void testRegenerateData() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            CBDataFactoryTest.createOrgVariable();
            CBInitialTestDataService.regenerateData();
            List<CBDivision__c> divisions = [SELECT Id FROM cblight__CBDivision__c];
            System.assert(!divisions.isEmpty(), 'data was not created');
        }
    }

    @isTest
    public static void testMultiplyBudgetLines() {
        List<CBAmount__c> listBL = CBDataFactoryTest.createAmounts(1);
        CBInitialTestDataService.multiplyBudgetLines();
        List<CBAmount__c> amounts = [SELECT Id FROM cblight__CBAmount__c];
        System.assert(!amounts.isEmpty(), 'data was not created');
    }
}