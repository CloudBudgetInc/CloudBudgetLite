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

public with sharing class CBOrgVariableDomain extends fflib_SObjectDomain  {
	public CBOrgVariableDomain(List<CBOrgVariable__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBOrgVariableDomain(sObjectList);
		}
	}
	public override void onBeforeInsert() {
		alreadyExistsValidation((List<CBOrgVariable__c>) Records);
		allocationOrMultiyearValidation((List<CBOrgVariable__c>) Records);
	}
	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		allocationOrMultiyearValidation((List<CBOrgVariable__c>) Records);
	}
	public override void onBeforeDelete() {
		undeletableValidation((Map<Id, CBOrgVariable__c>) ExistingRecords);
	}
	/**
	 * Prevent duplicating
	 */
	@TestVisible
	private static void alreadyExistsValidation(List<CBOrgVariable__c> records) {
		/*if ([SELECT Id FROM CBOrgVariable__c WITH SECURITY_ENFORCED LIMIT 1].size() > 0) {
			for (CBOrgVariable__c s : records) {
				s.addError('There can be only one org variable object');
			}
		}*/
	}
	/**
	 * Prevent save org variable with allocation and multi year lines at the same time
	 */
	@TestVisible
	private static void allocationOrMultiyearValidation(List<CBOrgVariable__c> records) {
		/*for (CBOrgVariable__c s : records) {
			if (s.cblight__AllocationIsUsing__c && s.cblight__BudgetLineIsMultiYear__c) {
				s.addError('There can be only Allocation or Multiyear Lines');
			}
		}*/
	}
	/**
	 * Prevent deleting
	 */
	@TestVisible
	private static void undeletableValidation(Map<Id, CBOrgVariable__c> existingRecords) {
		/*for (CBOrgVariable__c s : existingRecords.values()) {
			if (s.cblight__AllocationIsUsing__c && s.cblight__BudgetLineIsMultiYear__c) {
				s.addError('There can be only Allocation or Multiyear Lines');
			}
		}*/
	}
}