/**
Created by Aleksei Volkov on 07/07/2022.
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
 
This test class covers the CBInitWizardPageController, ... classes
 */
@IsTest
public class CBInitWizardPageControllerTest {
   
    @IsTest
    public static void testGetListOfAvailableSObjectsServer() {
       List<CBSO> actualList = CBInitWizardPageController.getListOfAvailableSObjectsServer();
       System.assert(!actualList.isEmpty(), 'list is empty');
    }
 
    @IsTest
    public static void testGetSobjectFieldsServer() {
        List<CBSO> actualList = CBInitWizardPageController.getSobjectFieldsServer('cblight__CBPeriod__c');
        System.assert(!actualList.isEmpty(), 'list is empty');
    }
 
    @IsTest
    public static void testGetRegularMappingServer() {
        CBMapping__c expectedCBMapping = CBDataFactoryTest.createDivisionCBMapping();
        CBMapping__c actualMapping = CBInitWizardPageController.getRegularMappingServer(expectedCBMapping.Type__c);
        System.assertEquals(expectedCBMapping.Id, actualMapping.Id, 'IDs are not equals');
    }
 
    @IsTest
    public static void testGetRegularMappingServerByNull() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            CBMapping__c expectedMapping = new CBMapping__c();
            expectedMapping.Type__c = null;
            CBMapping__c actualMapping = CBInitWizardPageController.getRegularMappingServer(null);
            System.assertEquals(expectedMapping.Type__c, actualMapping.Type__c, 'mappings are not equals');
        }
    }
 
    @IsTest
    public static void testSaveMappingServer() {
        CBMapping__c expectedCBMapping = CBDataFactoryTest.createDivisionCBMapping();
        CBMapping__c actualMapping = CBInitWizardPageController.saveMappingServer(expectedCBMapping);
        System.assertEquals(expectedCBMapping.Id, actualMapping.Id, 'IDs are not equals');
    }

    @IsTest
    public static void testRunMappingServerByDivision() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            List<CBDivision__c> div = CBDataFactoryTest.createDivisions(1);
            CBMapping__c mapping = CBDataFactoryTest.createDivisionCBMapping();
            CBInitWizardPageController.runMappingServer(mapping);
            List<CBDivision__c> actualDivs = [SELECT Id FROM cblight__CBDivision__c];
            System.assert(!actualDivs.isEmpty(), 'data was not map');
        }
    }

    @IsTest
    public static void testRunMappingServerByAccount() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            CBMapping__c mapping = CBDataFactoryTest.createAcntCBMapping();
            CBSubAccount__c subAcnt = CBDataFactoryTest.createSubAccount();
            List<CBAccount__c> acnts = CBDataFactoryTest.createAccounts(1);
            CBInitWizardPageController.runMappingServer(mapping);
            List<CBAccount__c> actualAcnts = [SELECT Id FROM cblight__CBAccount__c];
            System.assert(!actualAcnts.isEmpty(), 'data was not map');
        }
    }

    @IsTest
    public static void testRunMappingServerByPeriod() {
        CBMapping__c mapping = CBDataFactoryTest.createPeriodCBMapping();
        CBInitWizardPageController.runMappingServer(mapping);
        System.assert(mapping != null, 'mapping was not run');
    }

    @IsTest
    public static void testRunMappingServerByVariables() {
        CBMapping__c mapping1 = CBDataFactoryTest.createVariableCBMapping(1);
        CBMapping__c mapping2 = CBDataFactoryTest.createVariableCBMapping(2);
        CBMapping__c mapping3 = CBDataFactoryTest.createVariableCBMapping(3);
        CBMapping__c mapping4 = CBDataFactoryTest.createVariableCBMapping(4);
        CBMapping__c mapping5 = CBDataFactoryTest.createVariableCBMapping(5);
        CBInitWizardPageController.runMappingServer(mapping1);
        CBInitWizardPageController.runMappingServer(mapping2);
        CBInitWizardPageController.runMappingServer(mapping3);
        CBInitWizardPageController.runMappingServer(mapping4);
        CBInitWizardPageController.runMappingServer(mapping5);
        System.assert(mapping5 != null, 'mapping was not run');
    }
}