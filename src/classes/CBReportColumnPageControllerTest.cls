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

This test class covers the CBReportColumnPageController, CBReportColumnSelector classes
 */
@isTEst
public class CBReportColumnPageControllerTest {
    
    @isTest
    public static void testGetReportColumnsServer() {
        List<CBReportColumn__c> expectedList = CBDataFactoryTest.createReportColumns(1);
        List<CBReportColumn__c> actualList = CBReportColumnPageController.getReportColumnsServer(expectedList[0].CBReport__c);
        System.assertEquals(expectedList[0].Id, actualList[0].Id, 'lists are not equals');
    }

    @isTest
    public static void testGetStaticDataServer() {
        CBCube__c cube = CBDataFactoryTest.createCBCube();
        Map<String, Object> actualMap = CBReportColumnPageController.getStaticDataServer();
        List<CBSO> periodSO = (List<CBSO>)actualMap.get('periodSO');
        System.assert(periodSO.size() > 0, 'list is empty');
    }

    @isTest
    public static void testSaveColumnsServer() {
        List<CBReportColumn__c> expectedList = CBDataFactoryTest.createReportColumns(1);
        List<CBReport__c> reports = [SELECT Id FROM cblight__CBReport__c];
        List<CBReportColumn__c> actualList = CBReportColumnPageController.saveColumnsServer(reports[0], expectedList);
        System.assertEquals(expectedList[0].Id, actualList[0].Id, 'lists are not equals');
    }

    @isTest
    public static void testDeleteColumnServer() {
        List<CBReportColumn__c> expectedList = CBDataFactoryTest.createReportColumns(100);
        List<String> ids = new List<String>();
        for(CBReportColumn__c temp: expectedList){
            ids.add(temp.Id);
        }
        CBReportColumnPageController.deleteColumnServer(ids);
        List<CBReportColumn__c> actualList = [SELECT Id FROM cblight__CBReportColumn__c];
        System.assert(actualList.isEmpty(), 'report column was not deleted');
    }

    @isTest
    public static void testSetLimit() {
        CBReportColumnSelector repColSel = new CBReportColumnSelector();
        CBReportColumnSelector actualObj = repColSel.setLimit(100);
        System.assertEquals(repColSel, actualObj, 'columns are not equals');
    }

    @isTest
    public static void testSetFilter() {
        CBReportColumnSelector repColSel = new CBReportColumnSelector();
        CBReportColumnSelector actualObj = repColSel.setFilter('Name LIKE \'%' + 'Test' + '%\'');
        System.assertEquals(repColSel, actualObj, 'columns are not equals');
    }

    @isTest
    public static void testQuery() {
        List<CBReportColumn__c> expectedList = CBDataFactoryTest.createReportColumns(100);
        List<CBReportColumn__c> actualList = new CBReportColumnSelector().query();
        System.assertEquals(expectedList.size(), actualList.size(), 'lists are not equals');
    }

    @isTest
    public static void testGetReportColumnsByReportNullId() {
        List<CBReportColumn__c> actualList = new CBReportColumnSelector().getReportColumnsByReportId(null);
        System.assertEquals(null, actualList, 'not null');
    }
}