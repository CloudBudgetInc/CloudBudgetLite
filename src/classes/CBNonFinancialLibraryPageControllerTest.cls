/** 
Created by Aleksei Volkov on 08/17/2022.
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

This test class covers the CBNonFinancialLibraryPageController, CBNonFinancialItemSelector classes
 */
@IsTest
public class CBNonFinancialLibraryPageControllerTest {
    
    @IsTest
    public static void testGetNonFinLibraryServer() {
        List<CBNonFinancialLibrary__c> nflList = CBDataFactoryTest.createNonFinancialLibraries(1);
        CBNonFinancialLibrary__c actualNFL = CBNonFinancialLibraryPageController.getNonFinLibraryServer(nflList[0].Id);
        System.assertEquals(nflList[0].Id, actualNFL.Id, 'IDs are not equals');
    }

    @IsTest
    public static void testGetAllPeriodsServer() {
        List<CBPeriod__c> expectedPeriods = CBDataFactoryTest.createPeriods(3);
        List<CBPeriod__c> actualPeriods = CBNonFinancialLibraryPageController.getAllPeriodsServer();
        Assert.areEqual(expectedPeriods.size(), actualPeriods.size(), 'The number of periods is not the same');
    }

    @IsTest
    public static void testSaveNonFinancialLibServer() {
        List<CBLayer__c> layers = CBDataFactoryTest.createLayers(1);
        CBNonFinancialLibrary__c nfl = new CBNonFinancialLibrary__c(Name = 'Test NFL', Layer__c = layers[0].Id);
        CBDataFactoryTest.createPeriods(1);
        CBNonFinancialLibraryPageController.saveNonFinancialLibServer(nfl, null);
        List<CBNonFinancialItem__c> relatedItems = [SELECT Id, NonFinancialLibrary__c FROM cblight__CBNonFinancialItem__c WHERE NonFinancialLibrary__c =: nfl.Id];
        CBNonFinancialLibraryPageController.saveNonFinancialLibServer(nfl, relatedItems);

        Assert.areEqual(nfl.Id, relatedItems[0].NonFinancialLibrary__c, 'IDs are not equals');
    }

    @IsTest
    public static void testGetNonFinancialItemsByFilter() {
        Integer periodsNum = 4;
        CBDataFactoryTest.createPeriods(periodsNum);
        List<CBLayer__c> layers = CBDataFactoryTest.createLayers(1);
        CBNonFinancialLibrary__c nfl = new CBNonFinancialLibrary__c(Name = 'Test NFL', Layer__c = layers[0].Id);
        CBNonFinancialLibraryPageController.saveNonFinancialLibServer(nfl, null);
        String filter = 'NonFinancialLibrary__c = \'' + nfl.Id + '\'';
        List<CBNonFinancialItem__c> actualNFIList = new CBNonFinancialItemSelector().getNonFinancialItemsByFilter(filter);

        Assert.areEqual(periodsNum, actualNFIList.size(), 'The number of NFL items not equal to the number of periods');
        Assert.areEqual(nfl.Id, actualNFIList[0].NonFinancialLibrary__c, 'Items are not related to current NFL');
    }

}