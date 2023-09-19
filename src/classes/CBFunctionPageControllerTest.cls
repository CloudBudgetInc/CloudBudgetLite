/** 
Created by Aleksei Volkov on 08/09/2022.
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

This test class covers the CBFunctionPageController, CBFunctionSelector classes
 */
@isTest
public class CBFunctionPageControllerTest {
    
    @isTest
    public static void testGetFunctionSOServer() {
        List<CBFunction__c> funcList = CBDataFactoryTest.createFunctions(1);
        Map<String, List<CBSO>> actualMap = CBFunctionPageController.getFunctionSOServer();
        System.assert(!actualMap.isEmpty(), 'map is empty');
    }

    @isTest
    public static void testGetFunctionsServer() {
        List<CBFunction__c> funcList = CBDataFactoryTest.createFunctions(1);
        List<CBFunction__c> actualList = CBFunctionPageController.getFunctionsServer('Variable');
        System.assertEquals(funcList.size(), actualList.size(), 'lists are not equals');
    }

    @isTest
    public static void testSaveFunctionServer() {
        User adminUser = CBTestService.createAdminUser();
        System.runAs(adminUser) {
            List<CBAccount__c> acnts = CBDataFactoryTest.createAccounts(1);
            List<CBDivision__c> divs = CBDataFactoryTest.createDivisions(1);
            CBFunction__c func = new CBFunction__c(Name = 'Test Function');
            func.CBAccount__c = acnts[0].Id;
            func.CBDivision__c = divs[0].Id;
            CBFunctionPageController.saveFunctionServer(func);
            List<CBFunction__c> actualList = [SELECT Id FROM cblight__CBFunction__c];
            System.assert(actualList.size() == 1, 'list is not equals 1');
        }
    }
}