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

public with sharing class CBModelingRuleDomain extends fflib_SObjectDomain {
	public CBModelingRuleDomain(List<CBModelingRule__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBModelingRuleDomain(sObjectList);
		}
	}

	public override void onAfterInsert() {
		updateTaskQueue((List<CBModelingRule__c>) Records);
	}

	public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
		updateTaskQueue((List<CBModelingRule__c>) Records);
	}


	/**
	 * Prevent duplicating
	 */
	@TestVisible
	private static void updateTaskQueue(List<CBModelingRule__c> records) {
		Set<Id> modelingRuleGroupIds = new Set<Id>();
		for (CBModelingRule__c mr : records) {
			modelingRuleGroupIds.add(mr.CBModelingRuleGroup__c);
		}
		String filter = ' Id IN ' + CBUtils.getFormattedINQuery(modelingRuleGroupIds);
		List<CBModelingRuleGroup__c> mrgList = new CBModelingRuleGroupSelector().getAllModelingRuleGroups(filter);
		CBModelingRulePageController.updateTaskQueueInBulk(mrgList);
	}
}