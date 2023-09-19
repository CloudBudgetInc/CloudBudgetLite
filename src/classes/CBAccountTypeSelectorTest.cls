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

@description This test class covers the CBAccountTypeSelector class
 */
@isTest
public class CBAccountTypeSelectorTest {
    
    @isTest
    public static void testGetAccountTypeRecords() {
        List<CBAccountType__c> acntTypes = CBDataFactoryTest.createAccountTypes(2);
        CBAccountTypeSelector acntTypeSel = new CBAccountTypeSelector();
        List<CBAccountType__c> actualList = acntTypeSel.getAccountTypeRecords();
        System.assertEquals(acntTypes.size(), actualList.size(), 'size not equals');
    }

    @isTest
    public static void testGetAccountTypeRecordsByFilter() {
        List<CBAccountType__c> acntTypes = CBDataFactoryTest.createAccountTypes(2);
        CBAccountTypeSelector acntTypeSel = new CBAccountTypeSelector();
        List<CBAccountType__c> actualList = acntTypeSel.getAccountTypeRecordsByFilter('Name LIKE \'%' + 'Test Account Type' + '%\'');
        System.assertEquals(acntTypes.size(), actualList.size(), 'size not equals');
    }

    @isTest
    public static void testGetAccountTypeRecordById() {
        List<CBAccountType__c> acntTypes = CBDataFactoryTest.createAccountTypes(1);
        CBAccountTypeSelector acntTypeSel = new CBAccountTypeSelector();
        CBAccountType__c actualAcntType = acntTypeSel.getAccountTypeRecordById(acntTypes[0].Id);
        System.assertEquals(acntTypes[0].Id, actualAcntType.Id, 'id not equals');
    }

    @isTest
    public static void testGetAccountTypeRecordByNullId() {
        CBAccountTypeSelector acntTypeSel = new CBAccountTypeSelector();
        CBAccountType__c actualAcntType = acntTypeSel.getAccountTypeRecordById(null);
        System.assertEquals(null, actualAcntType, 'type not null');
    }
}