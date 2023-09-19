/** 
Created by Aleksei Volkov on 06/28/2022.
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

This test class covers the CBLogSelector, CBLogPageController classes
 */
@isTest
public class CBLogPageControllerTest {

    @isTest
    public static void testGetLogsServer() {
        List<CBLog__c> expectedLogList = CBDataFactoryTest.createLogs(10);
        List<CBLog__c> actualList = CBLogPageController.getLogsServer('Name LIKE \'%' + 'Test' + '%\'', 10);
        System.assertEquals(expectedLogList.size(), actualList.size(), 'lists are not equals');
    }
   
    @isTest
    public static void testGetSelectedLogServer() {
        List<CBLog__c> logList = CBDataFactoryTest.createLogs(10);
        CBLog__c log = logList[0];
        CBLog__c actualLog = CBLogPageController.getSelectedLogServer(log.Id);
        System.assertEquals(log.Id, actualLog.Id, 'IDs are not equals');
    }

    @isTest
    public static void testGetSelectedLogServerByNullId() {
        CBLog__c actualLog = CBLogPageController.getSelectedLogServer(null);
        System.assertEquals(null, actualLog, 'not null');
    }

    @isTest
    public static void testGetLogDetailsServer() {
        List<CBLog__c> logList = CBDataFactoryTest.createLogs(1);
        CBLog__c log = logList[0];
        CBLog__c actualLog = CBLogPageController.getLogDetailsServer('Name LIKE \'%' + 'Test' + '%\'');
        System.assertEquals(log.Id, actualLog.Id, 'IDs are not equals');
    }

    @isTest
    public static void testGetLogFilteredBy() {
        List<CBLog__c> expectedLogList = CBDataFactoryTest.createLogs(10);
        List<CBLog__c> actualList = new CBLogSelector().getLogFilteredBy('Name LIKE \'%' + 'Test' + '%\'');
        System.assertEquals(expectedLogList.size(), actualList.size(), 'lists are not equals');
    }

    @isTest
    public static void testGetListOfLogFieldsSOServer() {
        List<CBLog__c> expectedLogList = CBDataFactoryTest.createLogs(10);
        List<CBSO> actualList = CBLogPageController.getListOfLogFieldsSOServer();
        System.assert(!actualList.isEmpty(), 'list is empty');
    }
}