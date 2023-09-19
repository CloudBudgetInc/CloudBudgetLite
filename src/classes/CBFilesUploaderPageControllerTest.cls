/** 
Created by Aleksei Volkov on 08/16/2022.
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

This test class covers the CBFilesUploaderPageController class
 */
@isTest
public class CBFilesUploaderPageControllerTest {
   
    @isTest
    public static void testSaveFileServer() {
        List<CBBudgetLine__c> bLines = CBDataFactoryTest.createBudgetLines(1);
        ContentVersion cvActual = CBFilesUploaderPageController.saveFileServer(bLines[0].Id, 'strFileName',  'base64Data');
        List<ContentVersion> actualList = [SELECT Id From ContentVersion];
        System.assert(!actualList.isEmpty(), 'list is empty');
    }

    @isTest
    public static void testGetRelatedFilesServer() {
        ContentVersion cv = CBDataFactoryTest.createContentVersion();
        List<ContentVersion> actualList = CBFilesUploaderPageController.getRelatedFilesServer(cv.FirstPublishLocationId);
        System.assert(!actualList.isEmpty(), 'list is empty');
    }

    @isTest
    public static void testDeleteFileServer() {
        ContentVersion cv = CBDataFactoryTest.createContentVersion();
        List<ContentVersion> expectedList = [SELECT Id, Title, ContentDocumentId From ContentVersion];
        CBFilesUploaderPageController.deleteFileServer(expectedList[0].ContentDocumentId);
        List<ContentVersion> actualList = [SELECT Id From ContentVersion];
        System.assert(actualList.isEmpty(), 'not deleted');
    }
}