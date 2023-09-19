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

This test class covers the CBRevisionPageController, CBRevisionSelector classes
 */
@isTest
public class CBRevisionPageControllerTest {

@isTest
public static void testGetBudgetLineHistoryByParentId() {
    List<CBBudgetLine__c> lines = CBDataFactoryTest.createBudgetLines(1);
    cblight__CBBudgetLine__History history = new cblight__CBBudgetLine__History(Field = 'Name', parentId = lines[0].Id);
    insert history;
    List<cblight__CBBudgetLine__History> historyList = CBRevisionPageController.getBudgetLineHistoryByParentId(lines[0].Id);

    Assert.areEqual(lines[0].Id, historyList[0].ParentId, 'Ids are not equals');
}

@isTest
public static void testGetAmountHistoryByParentId() {
    List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
    cblight__CBAmount__History history = new cblight__CBAmount__History(Field = 'Name', parentId = amounts[0].Id);
    insert history;
    List<cblight__CBAmount__History> amountHistory = CBRevisionPageController.getAmountHistoryByParentId(amounts[0].CBBudgetLine__c);

    Assert.areEqual(amounts[0].Id, amountHistory[0].ParentId, 'Ids are not equals');
}

@isTest
public static void testGetRevisionByFilter() {
    List<CBRevision__c> expectedRevns = CBDataFactoryTest.createRevisions(1);
    List<CBRevision__c> actualRevns = new CBRevisionSelector().getRevisionByFilter('Name LIKE \'%' + 'Test' + '%\'');

    Assert.areEqual(expectedRevns.size(), actualRevns.size(), 'lists are not equals');
}

}