/** 
Created by Aleksei Volkov on 06/21/2022.
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

@description This test class covers the CBAccountSelector class
 */
@isTest
public class CBAccountSelectorTest {
    
    @isTest
    public static void testGetAccountRecords() {
        List<CBAccount__c> expectedList = CBDataFactoryTest.createAccounts(1);
        CBAccountSelector accSel = new CBAccountSelector();
        List<CBAccount__c> actualList = accSel.getAccountRecords('Name = \'Test acnt 0\'');
        System.assertEquals(expectedList.size(), actualList.size(), 'size not the same');
    }

    @isTest
    public static void testGetAccountRecordById() {
        List<CBAccount__c> expectedList = CBDataFactoryTest.createAccounts(1);
        CBAccountSelector accSel = new CBAccountSelector();
        CBAccount__c actualAccount = accSel.getAccountRecordById(expectedList[0].Id);
        System.assertEquals(expectedList[0].Id, actualAccount.Id, 'ids not equals');
    }

    @isTest
    public static void testGetAccountRecordByNullId() {
        CBAccountSelector accSel = new CBAccountSelector();
        CBAccount__c actualAccount = accSel.getAccountRecordById(null);
        System.assertEquals(null, actualAccount, 'acc not null');
    }

    @isTest
    public static void testGetAccountRecordsByExtId() {
        List<CBAccount__c> expectedList = CBDataFactoryTest.createAccounts(5);
        Set<String> setExtIds = new Set<String>();
        for(CBAccount__c item : expectedList){
        setExtIds.add(item.ExtId__c);
        }
        CBAccountSelector accSel = new CBAccountSelector();
        List<CBAccount__c> actualAccounts = accSel.getAccountRecordsByExtId(setExtIds);
        System.assertEquals(expectedList.size(), actualAccounts.size(), 'size not equals');
    }

    @isTest
    public static void testGetAccountRecordsByNullExtId() {
        CBAccountSelector accSel = new CBAccountSelector();
        List<CBAccount__c> actualAccounts = accSel.getAccountRecordsByExtId(null);
        System.assertEquals(null, actualAccounts, 'acc not null');
    }
}