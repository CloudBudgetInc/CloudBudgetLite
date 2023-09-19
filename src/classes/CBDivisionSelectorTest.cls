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

This test class covers the CBDivisionSelector class
 */
@isTest
public class CBDivisionSelectorTest {
    
    @isTest
    public static void testGetDivisionRecords() {
        List<CBDivision__c> expectedDivisions = CBDataFactoryTest.createDivisions(2);
        CBDivisionSelector divSel = new CBDivisionSelector();
        List<CBDivision__c> actualList = divSel.getDivisionRecords('Name LIKE \'%' + 'Test' + '%\'');
        System.assertEquals(expectedDivisions.size(), actualList.size(), 'lists are not equals');
    }

    @isTest
    public static void testGetDivisionRecordById() {
        List<CBDivision__c> expectedDivisions = CBDataFactoryTest.createDivisions(1);
        CBDivisionSelector divSel = new CBDivisionSelector();
        CBDivision__c actualDiv = divSel.getDivisionRecordById(expectedDivisions[0].Id);
        System.assertEquals(expectedDivisions[0].Id, actualDiv.Id, 'IDs are not equals');
    }

    @isTest
    public static void testGetDivisionRecordByNullId() {
        CBDivisionSelector divSel = new CBDivisionSelector();
        CBDivision__c actualDiv = divSel.getDivisionRecordById(null);
        System.assertEquals(null, actualDiv, 'not null');
    }

    @isTest
    public static void testGetDivisionRecordByExtId() {
        List<CBDivision__c> expectedDivisions = CBDataFactoryTest.createDivisions(10);
        Set<String> extIds = new Set<String>();
        for(CBDivision__c item : expectedDivisions){
            extIds.add(item.ExtId__c);
        }
        CBDivisionSelector divSel = new CBDivisionSelector();
        List<CBDivision__c> actualDiv = divSel.getDivisionRecordByExtId(extIds);
        System.assertEquals(expectedDivisions.size(), actualDiv.size(), 'lists are not equals');
    }

    @isTest
    public static void testGetDivisionRecordByNullExtId() {
        CBDivisionSelector divSel = new CBDivisionSelector();
        List<CBDivision__c> actualDiv = divSel.getDivisionRecordByExtId(null);
        System.assertEquals(null, actualDiv, 'not null');
    }
}