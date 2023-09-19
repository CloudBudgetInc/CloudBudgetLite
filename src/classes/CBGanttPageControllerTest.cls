/**
Created by Aleksei Volkov on 07/11/2022.
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
 
This test class covers the CBGanttPageController class
 */
@isTest
public class CBGanttPageControllerTest {

    @isTest
    public static void testGetBudgetLinesServer() {
        Map<String, String> params = new Map<String, String>();
        List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(3);
        List<CBBudgetLine__c> actualList = CBGanttPageController.getBudgetLinesServer(params);
        System.assertEquals(blList.size(), actualList.size(), 'lists are not equals');
    }

    @isTest
    public static void testGetPeriodsServer() {
        List<cblight__CBPeriod__c> expectedPeriods = CBDataFactoryTest.createPeriods(2);
        List<cblight__CBPeriod__c> actualPeriods = CBGanttPageController.getPeriodsServer();
        System.assertEquals(expectedPeriods.size(), actualPeriods.size(), 'lists are not equals');
    }

    @isTest
    public static void testGetSelectOptionsServer() {
        CBBudgetYear__c byTest = CBDataFactoryTest.createBY();
        CBSO bySO = new CBSO(byTest.Id, byTest.Name);
        Map<String, List<CBSO>> actualMap = CBGanttPageController.getSelectOptionsServer();
        System.assertEquals(bySO.value, actualMap.get('budgetYearSO')[0].value, 'values are not equals');
    }

}