/** 
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
public with sharing class CBModelingRuleGroupDomain extends fflib_SObjectDomain {
	public CBModelingRuleGroupDomain(List<CBModelingRuleGroup__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBModelingRuleGroupDomain(sObjectList);
		}
	}


	public override void onBeforeDelete() {
		cleanUp((List<CBModelingRuleGroup__c>) Records);
	}

	/**
		This method deletes all related child records of modeling rule groups that are being deleted. 
		Also it deletes all records that were produced by deleted modeling rule group
	 */
	private static void cleanUp(List<CBModelingRuleGroup__c> records) {
		Set<String> modRuleGroupIdSet = new Set<String>();
		Set<String> searchSet = new Set<String>();
		for (CBModelingRuleGroup__c record : records) {
			modRuleGroupIdSet.add(record.Id);
		}
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { 
				CBModelingRule__c.SObjectType, 
				CBCube__c.SObjectType, 
				CBAmount__c.SObjectType, 
				CBBudgetLine__c.SObjectType, 
				CBTransaction__c.SObjectType 
			}
		);
		uow.registerDeleted([
			SELECT Id
			FROM CBModelingRule__c
			WHERE CBModelingRuleGroup__c IN :modRuleGroupIdSet
			WITH SECURITY_ENFORCED
		]);
		for (String id : modRuleGroupIdSet) {
			id += '%';
			searchSet.add(id);
		}
		uow.registerDeleted([SELECT Id FROM CBCube__c WHERE CBKey__c LIKE:searchSet WITH SECURITY_ENFORCED]);
		uow.registerDeleted([SELECT Id FROM CBAmount__c WHERE CBKey__c LIKE:searchSet WITH SECURITY_ENFORCED]);
		uow.registerDeleted([SELECT Id FROM CBBudgetLine__c WHERE CBKey__c LIKE:searchSet WITH SECURITY_ENFORCED]);
		uow.registerDeleted([SELECT Id FROM CBTransaction__c WHERE CBKey__c LIKE:searchSet WITH SECURITY_ENFORCED]);
		uow.commitWork();
	}
}