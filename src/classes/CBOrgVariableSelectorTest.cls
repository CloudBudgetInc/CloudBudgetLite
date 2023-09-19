/** 
Created by Aleksei Volkov on 08/10/2022.
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

This test class covers the CBOrgVariableSelector class
 */
@isTest
public class CBOrgVariableSelectorTest {
    
    @isTest
    public static void testGetOrgVariableServer() {
        CBOrgVariable__c orgVar = CBDataFactoryTest.createOrgVariable();
        CBOrgVariable__c actualOrgVar = CBOrgVariableSelector.getOrgVariableServer();
        System.assertEquals(orgVar.Id, actualOrgVar.Id, 'Ids are not equals');
    }

    @isTest
    public static void testGetOrgVariableStructureServer() {
        CBOrgVariable__c orgVar = CBDataFactoryTest.createOrgVariable();
        List<CBSO> actualList = CBOrgVariableSelector.getOrgVariableStructureServer();
        System.assert(!actualList.isEmpty(), 'list is empty');
    }

    @isTest
    public static void testDelete() {
        CBOrgVariable__c expectedVar = CBDataFactoryTest.createOrgVariable();
        try{
            delete expectedVar;
        }catch(Exception e){
            CBOrgVariable__c actualVar = [SELECT Id FROM cblight__CBOrgVariable__c WHERE Id = :expectedVar.Id];
            System.assertEquals(expectedVar.Id, actualVar.Id, 'IDs are not equals');
        }
    }
}