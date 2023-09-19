/**
 Created by Alex JR on 08/18/2022.
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

 This test class covers the CBFolderController class
 */
@isTest
public class CBFolderControllerTest {
	@isTest
	public static void testGetFoldersByTypeServer() {
		String type = 'Modeling Rule';
		String folderName = 'Modeling Rule';
		CBFolder__c folder = new CBFolder__c(FolderType__c = type, Name = folderName);
		insert folder;
		List<CBFolder__c> folderList = CBFolderController.getFoldersByTypeServer(type);
		System.assertEquals(1, folderList.size(), 'size is not equals count');
		System.assertEquals(folderName, folderList[0].Name, 'Name dont match');
	}
	@isTest
	public static void testGetFolderByNameServer() {
		String type = 'Modeling Rule';
		String folderName = 'Modeling Rule';
		CBFolder__c folder = new CBFolder__c(FolderType__c = type, Name = folderName);
		insert folder;
		CBFolder__c actualFolder = CBFolderController.getFolderByNameServer(folderName);
		System.assertEquals(folder.Name, actualFolder.Name, 'Name dont match');
	}
	@isTest
	public static void testGetRecordsOfFolderServerNotNull() {
		List<CBModelingRuleGroup__c> mrgListNull = CBDataFactoryTest.createModelingRuleGroups(2);
		List<CBModelingRuleGroup__c> mrgListNotNull = CBDataFactoryTest.createModelingRuleGroups(3);
		String type = 'Modeling Rule';
		String folderName = 'Modeling Rule';
		CBFolder__c folder = new CBFolder__c(FolderType__c = type, Name = folderName);
		insert folder;
		for (CBModelingRuleGroup__c mrg : mrgListNotNull) {
			mrg.CBFolder__c = folder.Id;
		}
		update mrgListNotNull;
		String folderRecordsString = CBFolderController.getRecordsOfFolderServer(folder.Id, type);
		List<CBModelingRuleGroup__c> folderRecords = (List<CBModelingRuleGroup__c>) JSON.deserialize(folderRecordsString, List<CBModelingRuleGroup__c>.class);
		
		System.assertEquals(folderRecords.size(), mrgListNotNull.size(), 'size dont match');
	}

	@isTest
	public static void testGetRecordsOfFolderServerNull() {
		List<CBModelingRuleGroup__c> mrgListNull = CBDataFactoryTest.createModelingRuleGroups(2);
		String type = 'Modeling Rule';
		String folderName = 'Modeling Rule';
		CBFolder__c folder = new CBFolder__c(FolderType__c = type, Name = folderName);
		insert folder;
		String folderRecordsString = CBFolderController.getRecordsOfFolderServer(null, type);
		List<CBModelingRuleGroup__c> folderRecords = (List<CBModelingRuleGroup__c>) JSON.deserialize(folderRecordsString, List<CBModelingRuleGroup__c>.class);
		
		System.assertEquals(folderRecords.size(), mrgListNull.size(), 'size dont match');
	}
	@isTest
	public static void testGetRecordsOfFolderServerNullString() {
		List<CBModelingRuleGroup__c> mrgListNull = CBDataFactoryTest.createModelingRuleGroups(2);
		String type = 'Modeling Rule';
		String folderName = 'Modeling Rule';
		CBFolder__c folder = new CBFolder__c(FolderType__c = type, Name = folderName);
		insert folder;
		String folderRecordsString = CBFolderController.getRecordsOfFolderServer('null', type);
		List<CBModelingRuleGroup__c> folderRecords = (List<CBModelingRuleGroup__c>) JSON.deserialize(folderRecordsString, List<CBModelingRuleGroup__c>.class);
		
		System.assertEquals(folderRecords.size(), mrgListNull.size(), 'size dont match');
	}
	@isTest
	public static void testDeleteFolderServer() {
		String type = 'Modeling Rule';
		String folderName = 'Modeling Rule';
		CBFolder__c folder = new CBFolder__c(FolderType__c = type, Name = folderName);
		insert folder;
		CBFolderController.deleteFolderServer(folder.Id);
		CBFolder__c actualFolder = CBFolderController.getFolderByNameServer(folderName);
		System.assertEquals(null, actualFolder, 'folder not deleted');
	}
}