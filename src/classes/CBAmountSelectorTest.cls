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

This test class covers the CBAmountSelector, CBAmountDomain classes
 */
@IsTest
public class CBAmountSelectorTest {
    
    @IsTest
    public static void testGetAmountsRecords() {
        List<CBAmount__c> expectedAmounts = CBDataFactoryTest.createAmounts(1);
        CBAmountSelector amntSel = new CBAmountSelector();
        List<CBAmount__c> actualList = amntSel.getAmountsRecords();
        System.assertEquals(expectedAmounts.size(), actualList.size(), 'lists are not equals');
    }

    @IsTest
    public static void testGetAmountsRecordsByFilter() {
        List<CBAmount__c> expectedAmounts = CBDataFactoryTest.createAmounts(3);
        CBAmountSelector amntSel = new CBAmountSelector();
        List<CBAmount__c> actualList = amntSel.getAmountsRecordsByFilter('Name LIKE \'%' + 'Test' + '%\'');
        System.assertEquals(expectedAmounts.size(), actualList.size(), 'lists are not equals');
    }

    @IsTest
    public static void testgetAmountsByFilter() {
        List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
        List<CBBudgetLine__c> expectedListBL = [SELECT Id FROM cblight__CBBudgetLine__c];
        CBAmountSelector amntSel = new CBAmountSelector();
        List<CBBudgetLine__c> actualList = amntSel.getAmountsByFilter('Name LIKE \'%' + 'Test' + '%\'');
        System.assertEquals(expectedListBL.size(), actualList.size(), 'lists are not equals');
    }

    @IsTest
    public static void testgetAmountsByFilterAndLimit() {
        List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
        List<CBBudgetLine__c> expectedListBL = [SELECT Id FROM cblight__CBBudgetLine__c];
        CBAmountSelector amntSel = new CBAmountSelector();
        List<CBBudgetLine__c> actualList = amntSel.getAmountsByFilter('Name LIKE \'%' + 'Test' + '%\'', 2);
        System.assertEquals(expectedListBL.size(), actualList.size(), 'lists are not equals');
    }

}