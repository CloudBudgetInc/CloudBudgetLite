/** 
Created by Aleksei Volkov on 08/01/2022.
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

This test class covers the CBVariableSelector class
 */
@IsTest
public class CBVariableSelectorTest {
    
    @isTest
    public static void testSetIndex1() {
        CBVariableSelector varSel = new CBVariableSelector().setIndex(1);
        Schema.SObjectType sType = varSel.getSObjectType();
        System.assertEquals(CBVariable1__c.sObjectType, sType, 'types are not equals');
    }

    @isTest
    public static void testSetIndex2() {
        CBVariableSelector varSel = new CBVariableSelector().setIndex(2);
        Schema.SObjectType sType = varSel.getSObjectType();
        System.assertEquals(CBVariable2__c.sObjectType, sType, 'types are not equals');
    }

    @isTest
    public static void testSetIndex3() {
        CBVariableSelector varSel = new CBVariableSelector().setIndex(3);
        Schema.SObjectType sType = varSel.getSObjectType();
        System.assertEquals(CBVariable3__c.sObjectType, sType, 'types are not equals');
    }

    @isTest
    public static void testSetIndex4() {
        CBVariableSelector varSel = new CBVariableSelector().setIndex(4);
        Schema.SObjectType sType = varSel.getSObjectType();
        System.assertEquals(CBVariable4__c.sObjectType, sType, 'types are not equals');
    }

    @isTest
    public static void testSetIndex5() {
        CBVariableSelector varSel = new CBVariableSelector().setIndex(5);
        Schema.SObjectType sType = varSel.getSObjectType();
        System.assertEquals(CBVariable5__c.sObjectType, sType, 'types are not equals');
    }

    @isTest
    public static void testgetAllVariables() {
        CBVariable1__c var1 = CBDataFactoryTest.createVariable1();
        CBVariableSelector varSel = new CBVariableSelector().setIndex(1);
        List<CBVariableSelector.VariableWrapper> actualList = varSel.getAllVariables();
        System.assert(!actualList.isEmpty(), 'list is empty');
    }
}