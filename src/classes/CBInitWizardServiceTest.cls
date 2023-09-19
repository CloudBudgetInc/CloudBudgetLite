/**
Created by Aleksei Volkov on 07/26/2022.
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
 
This test class covers the CBInitWizardService class
 */
@IsTest
public class CBInitWizardServiceTest {
    
    @IsTest
    public static void testTdoMappingAccounts() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            CBMapping__c mapping = CBDataFactoryTest.createAcntCBMapping();
            CBSubAccount__c subAcnt = CBDataFactoryTest.createSubAccount();
            List<CBAccount__c> acnts = CBDataFactoryTest.createAccounts(1);
            List<SObject> listOfSourceAccounts = new List<SObject>();
            listOfSourceAccounts.add(acnts[0]);
            new CBInitWizardService.CBMapAccounts().doMapping(listOfSourceAccounts);
            CBAccount__c actualAcnt = [SELECT Id, ExtId__c FROM cblight__CBAccount__c WHERE cblight__ExtId__c = :acnts[0].Id];
            System.assertEquals(acnts[0].Id, actualAcnt.ExtId__c, 'data was not map');
        }
    }

    @IsTest
    public static void testTdoMappingDivisions() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            List<CBDivision__c> divisions = CBDataFactoryTest.createDivisions(1);
            CBMapping__c mapping = CBDataFactoryTest.createDivisionCBMapping();
            List<sObject> listOfSourceDivisions = new List<sObject>();
            listOfSourceDivisions.add(divisions[0]);
            new CBInitWizardService.CBMapDivisions().doMapping(listOfSourceDivisions);
            CBDivision__c actualDiv = [SELECT Id, ExtId__c FROM cblight__CBDivision__c WHERE cblight__ExtId__c = :divisions[0].Id];
            System.assertEquals(divisions[0].Id, actualDiv.ExtId__c, 'data was not map');
        }
    }

    @IsTest
    public static void testTdoMappingPeriods() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            CBDataFactoryTest.createOrgVariable();
            List<CBPeriod__c> periods = CBDataFactoryTest.createPeriodsWithoutInsertToDB(1);
            CBMapping__c mapping = CBDataFactoryTest.createPeriodCBMapping();
            List<sObject> listOfSourcePeriods = new List<sObject>();
            listOfSourcePeriods.add(periods[0]);
            new CBInitWizardService.CBMapPeriods().doMapping(listOfSourcePeriods);
            List<CBPeriod__c> actualPeriods = [SELECT Id FROM cblight__CbPeriod__c];
            System.assert(!actualPeriods.isEmpty(), 'data was not map');
        }
    }

    @IsTest
    public static void testdoMappingVariables() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            CBMapping__c mapping = CBDataFactoryTest.createVariableCBMapping(1);
            CBVariable1__c var1 = CBDataFactoryTest.createVariable1();
            List<sObject> listOfSourceVariables = new List<sObject>();
            listOfSourceVariables.add(var1);
            new CBInitWizardService.CBMapVariables(1).doMapping(listOfSourceVariables);
            CBVariable1__c actualVar = [SELECT Id, ExtId__c FROM cblight__CBVariable1__c WHERE cblight__ExtId__c = :var1.Id];
            System.assertEquals(var1.Id, actualVar.ExtId__c, 'data was not map');
        }
    }
}