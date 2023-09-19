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
public with sharing class CBAmountDomain extends fflib_SObjectDomain {
	public CBAmountDomain(List<CBAmount__c> sObjectList) {
		super(sObjectList);
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBAmountDomain(sObjectList);
		}
	}

	public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
		//updateBudgetLineSumValues(existingRecords.values());
		//TODO this method works then budget line is saving only. It runs budget line trigger twice and slower the system.
	}

	public override void onBeforeInsert() {
		CBMultiCurrencyService.assignCBBudgetLineISOCodeToCBAmounts((List<CBAmount__c>) Records);
	}

	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		CBMultiCurrencyService.assignCBBudgetLineISOCodeToCBAmounts((List<CBAmount__c>) Records);
	}

	////// PRIVATE METHODS ////////////
	/**
	 * Method recalculates total cblight__Value__c in a budget line
	 * @param amounts
	 */
	private static void updateBudgetLineSumValues(List<CBAmount__c> amounts) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBBudgetLine__c.SObjectType
				}
		);
		Set<String> budgetLineIdSet = new Set<String>();
		for (CBAmount__c amount : amounts) {
			budgetLineIdSet.add(amount.CBBudgetLine__c);
		}
		String f = ' Id IN ' + CBUtils.getFormattedINQuery(budgetLineIdSet);
		List<CBBudgetLine__c> budgetLines = new CBBudgetLineSelector().getBudgetLines(f);
		for (CBBudgetLine__c bl : budgetLines) {
			Decimal sum = 0;
			for (CBAmount__c amount : bl.CBAmounts__r) {
				sum += amount.Value__c;
			}
			bl.Value__c = sum;
			uow.registerUpsert(bl);
		}
		uow.commitWork();
	}
	////// PRIVATE METHODS ////////////
}