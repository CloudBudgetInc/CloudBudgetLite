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
public with sharing class CBBudgetLineDomain extends fflib_SObjectDomain {
	public CBBudgetLineDomain(List<CBBudgetLine__c> sObjectList) {
		super(sObjectList);
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBBudgetLineDomain(sObjectList);
		}
	}

	public override void onBeforeDelete() {
		if (CBLockService.recordsLockedForDeleting((List<CBBudgetLine__c>) Records)) throw new CBException(null, 'Record is Locked');
		deleteExtraCBAmounts((List<CBBudgetLine__c>) Records);
	}

	public override void onAfterDelete() {
		deleteExtraCustomNFLibs((List<CBBudgetLine__c>) ExistingRecords.values());
	}

	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		if (CBLockService.recordsLockedForEditing((List<CBBudgetLine__c>) Records, (List<CBBudgetLine__c>) existingRecords.values())) {
			CBLogService.setLog('BL Domain', 'ERROR', 'Record is locked');
			CBLogService.insertLog();
			throw new CBException(null, 'Record is Locked');
		}
	}

	/**
	 * Method deletes orphan CB Amounts without a budget line
	 */
	private void deleteExtraCBAmounts(List<CBBudgetLine__c> budgetLines) {
		Set<Id> blIdSet = new Set<Id>();
		for (CBBudgetLine__c bl : budgetLines) {
			blIdSet.add(bl.Id);
		}
		List<CBAmount__c> recordList = [SELECT Id FROM CBAmount__c WHERE CBBudgetLine__c IN:blIdSet WITH SECURITY_ENFORCED];
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBAmount__c.SObjectType
				}
		);
		uow.registerDeleted(recordList);
		uow.commitWork();
	}
	/**
	 * Method deletes orphan custom CB Non Fin Libs without a budget line
	 */
	private void deleteExtraCustomNFLibs(List<CBBudgetLine__c> budgetLines) {
		Set<Id> blIdSet = new Set<Id>();
		for (CBBudgetLine__c bl : budgetLines) {
			if (bl.NFL1__c != null) blIdSet.add(bl.NFL1__c);
			if (bl.NFL2__c != null) blIdSet.add(bl.NFL2__c);
			if (bl.NFL3__c != null) blIdSet.add(bl.NFL3__c);
			if (bl.NFL4__c != null) blIdSet.add(bl.NFL4__c);
			if (bl.NFL5__c != null) blIdSet.add(bl.NFL5__c);
		}
		List<CBNonFinancialLibrary__c> recordList = [SELECT Id FROM CBNonFinancialLibrary__c WHERE Type__c = 'Custom' AND Id IN:blIdSet WITH SECURITY_ENFORCED];
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialLibrary__c.SObjectType
				}
		);
		uow.registerDeleted(recordList);
		uow.commitWork();
	}


}