/** 
Copyright (c) 2021, CloudBudget, Inc.
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
public with sharing class CBMapBaseAnalyticController {

	private static Map<String, cblight__CBAccountType__c> typeMap {
		get {
			if (typeMap == null) {
				typeMap = new Map<String, cblight__CBAccountType__c>();
				for (cblight__CBAccountType__c tp : [SELECT Id, Name FROM cblight__CBAccountType__c WITH SECURITY_ENFORCED]) {
					typeMap.put(tp.Name, tp);
				}
			}
			return typeMap;
		}
		set;
	}
	private static Map<String, cblight__CBSubAccount__c> subtypeMap {
		get {
			if (subtypeMap == null) {
				subTypeMap = new Map<String, cblight__CBSubAccount__c>();
				for (cblight__CBSubAccount__c sub : [SELECT Id, Name FROM cblight__CBSubAccount__c WITH SECURITY_ENFORCED]) {
					subTypeMap.put(sub.Name, sub);
				}
			}
			return subtypeMap;
		}
		set;
	}

	public static void mapPeriodAnalytics(String SObjectName, String startField, String additionalFilter) {
		/*List<SObject> CBSobjects = new List<SObject>();
		additionalFilter = additionalFilter == null ? '' : ' WHERE ' + additionalFilter;
		String CBTypeName = CBUtils.getTypeSObjectName(CBType);
		String q = 'SELECT Id, Name FROM ' + SObjectName + additionalFilter + ' ORDER BY Name';
		System.debug(q);
		for (SObject obj : Database.query(q)) {
			Type CBSObjectType = Type.forName(CBTypeName);
			SObject CBRecord = (SObject) CBSObjectType.newInstance();
			CBRecord.put('Name', obj.get('Name'));
			CBRecord.put('cblight__ExtId__c', obj.Id);
			CBSobjects.add(CBRecord);
		}
		System.debug(CBSobjects.size());
		System.debug(CBSobjects);
		insert CBSobjects;*/
	}

	public static void mapAccountAnalytics(String SObjectName, String typeField, String subtypeField, String additionalFilter) {
		List<CBAccount__c> cbAccounts = new List<CBAccount__c>();
		List<String> selectList = new List<String>{
				'Id', 'Name', typeField, subtypeField
		};
		CBSobjectSelector sobjSel = new CBSobjectSelector(SObjectName, false)
				.selectFieldsByNames(selectList)
				.setFilter(additionalFilter)
				.setOrder('Name', true);
		List<SObject> externalAccounts = sobjSel.getSobjects();
		upsertTypeAndSubtype(externalAccounts, typeField, subtypeField);
		typeMap = null;
		subtypeMap = null;
		for (SObject obj : sobjSel.getSobjects()) {
			CBAccount__c cbAccount = new CBAccount__c();
			CBAccountType__c typeObj = typeMap.get((String) obj.get(typeField));
			CBSubAccount__c subtypeObj = subtypeMap.get((String) obj.get(subtypeField));
			cbAccount.Name = (String) obj.get('Name');
			cbAccount.CBSubAccount__c = (Id) subtypeObj.Id;
			cbAccount.CBAccountType__c = (Id) typeObj.Id;
			cbAccounts.add(cbAccount);
		}
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBAccount__c.SObjectType }
		);
		uow.registerUpsert(cbAccounts);
		uow.commitWork();
	}

	// TODO Make this method out of mapAccountAnalytics logic
	private static void upsertTypeAndSubtype(List<SObject> externalAccounts, String typeField, String subtypeField) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBAccountType__c.SObjectType, CBSubAccount__c.SObjectType }
		);
		for (SObject obj : externalAccounts) {
			String typeName = (String) obj.get(typeField);
			if (typeMap.get(typeName) != null) {
				continue; // duplication protection
			}
			CBAccountType__c newType = new CBAccountType__c();
			newType.Name = (String) obj.get(typeField);
			newType.Sign__c = '+'; // TODO - creation types should be from the interface
			typeMap.put(typeName, newType);
		}
		for (SObject obj : externalAccounts) {
			String subtypeName = (String) obj.get(subtypeField);
			if (subtypeMap.get(subtypeName) != null) {
				continue; // duplication protection
			}
			CBSubAccount__c newSubtype = new CBSubAccount__c();
			newSubtype.Name = (String) obj.get(subtypeField);
			subtypeMap.put(subtypeName, newSubtype);
		}
		uow.registerUpsert(typeMap.values());
		uow.registerUpsert(subtypeMap.values());
		uow.commitWork();
	}


}