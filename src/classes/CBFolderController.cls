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

 */
public with sharing class CBFolderController {
	private static final Map<String, SobjectType> STMAP = new Map<String, SobjectType>{
		'Modeling Rule' => CBModelingRuleGroup__c.SobjectType,
		'Calculation Rule' => CBCalculationRule__c.SobjectType,
		'Report' => CBReport__c.SobjectType
	};

	@AuraEnabled
	public static List<CBFolder__c> getFoldersByTypeServer(String type) {
		try {
			type = CBUtils.refineStr(type);
			return new CBSobjectSelector(CBFolder__c.sObjectType).getSobjects('FolderType__c = \'' + type + '\'');
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	@AuraEnabled
	public static CBFolder__c getFolderByNameServer(String folderName) {
		folderName = CBUtils.refineStr(folderName);
		List<CBFolder__c> folderList = (List<CBFolder__c>) new CBSobjectSelector(CBFolder__c.sObjectType).getSobjects('Name = \'' + folderName + '\'');
		if (folderList.size() > 0) {
			return folderList[0];
		} else {
			return null;
		}
	}
	@AuraEnabled
	public static CBFolder__c getFolderByIdServer(String folderId) {
		List<CBFolder__c> folderList = (List<CBFolder__c>) new CBSobjectSelector(CBFolder__c.sObjectType).getSobjects('Id = \'' + folderId + '\'');
		if (folderList.size() > 0) {
			return folderList[0];
		} else {
			return null;
		}
	}

	@AuraEnabled
	public static String getRecordsOfFolderServer(String folderId, String folderType) {
		String result;
		folderType = CBUtils.refineStr(folderType);
		SobjectType st = STMAP.get(folderType);
		String filter = '';
		if (folderId != null && folderId != 'null') {
			filter = 'CBFolder__c = \'' + folderId + '\'';
		} else {
			filter = 'CBFolder__c = null';
		}
		if (st != null) {
			result = JSON.serialize(new CBSobjectSelector(st).getSobjects(filter));
		}
		return result;
	}

	@AuraEnabled
	public static void deleteFolderServer(Id folderId) {
		CBFolder__c folder = getFolderByIdServer(folderId);
		if (folder != null) {
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ CBFolder__c.SObjectType });
			uow.registerDeleted(folder);
			uow.commitWork();
		}
	}
}