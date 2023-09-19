/**
 Created by Alex JR on 10/23/2021.
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

 The page to save sobjects related to budget line
 */
public with sharing class CBBudgetLineService {


	/**
	 * The method saves Budget Line and amounts
	 *
	 * @param budgetLine
	 * @param amounts
	 * @param uow
	 */
	public void saveBudgetLine(CBBudgetLine__c budgetLine, List<CBAmount__c> amounts, fflib_SObjectUnitOfWork uow) {
		if (uow == null) {
			uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
					CBNonFinancialLibrary__c.SObjectType, cblight__CBBudgetLine__c.sObjectType, cblight__CBAmount__c.sObjectType, CBNonFinancialItem__c.SObjectType
			});
		}
		uow.registerUpsert(budgetLine);
		checkNewlyCreatedNFLibs(budgetLine, uow);

		for (CBAmount__c amount : amounts) {
			if (amount.Id == null) {
				uow.registerNew(amount, cblight__CBAmount__c.cblight__CBBudgetLine__c, budgetLine);
			} else {
				uow.registerDirty(amount, cblight__CBAmount__c.cblight__CBBudgetLine__c, budgetLine);
			}
		}
		uow.commitWork();
	}
	/**
	 * Method converts layout Id to a new custom NFL for budget line
	 * @param budgetLine
	 */
	private static void checkNewlyCreatedNFLibs(CBBudgetLine__c budgetLine, fflib_SObjectUnitOfWork uow) {
		try {
			Map<Integer, CBNonFinancialLibrary__c> nflMap = new Map<Integer, CBNonFinancialLibrary__c>();
			for (Integer idx = 1; idx <= 5; idx++) { // iterate over bl cblight__NFL idx __c
				Id variableId = (Id) budgetLine.get('cblight__NFL' + idx + '__c');
				if (variableId == null) {
					continue;
				}
				String sobjectType = variableId.getSObjectType().getDescribe().getName(); // it can by NFL or Layer Id
				if (variableId.getSObjectType().getDescribe().getName() == 'cblight__CBLayer__c') {
					nflMap.put(idx, new CBNonFinancialLibrary__c(Layer__c = variableId, Name = 'Custom', Type__c = 'Custom'));
				}
			}
			if (nflMap.size() > 0) {
				uow.registerNew(nflMap.values());
				//insert nflMap.values();
				for (Integer idx = 1; idx <= 5; idx++) {
					CBNonFinancialLibrary__c lib = nflMap.get(idx); // take new custom NFL from the map
					if (lib == null) {
						continue;
					}
					Schema.SObjectField field = CBBudgetLine__c.SobjectType.getDescribe().fields.getMap().get('cblight__NFL' + idx + '__c');
					if (budgetLine.Id == null) {
						uow.registerRelationship(budgetLine, field, lib);
					} else {
						uow.registerDirty(budgetLine, field, lib);
					}
					//budgetLine.put('cblight__NFL' + idx + '__c', lib.Id); // put Id of the new NFL to budget line lookups
				}
			}
		} catch (Exception e) {
			throw new CBException(e, 'Created NFLibs Error');
		}
	}

	/**
	 * The method saves bunch of budget lines
	 *
	 * @param budgetLines - budget lines
	 * @param amounts - amounts of the budget lines
	 */
	public static void saveBudgetLinesInScope(List<CBBudgetLine__c> budgetLines, List<List<CBAmount__c>> amounts) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBBudgetLine__c.SObjectType, CBAmount__c.SObjectType
				}
		);
		uow.registerUpsert(budgetLines);
		List<CBAmount__c> amountsToUpsert = new List<CBAmount__c>();
		for (Integer i = 0; i < amounts.size(); i++) {
			List<CBAmount__c> blAmounts = amounts[i];
			for (CBAmount__c a : blAmounts) {
				if (a.Id == null) {
					uow.registerNew(a, CBAmount__c.CBBudgetLine__c, budgetLines[i]);
				} else {
					uow.registerDirty(a, CBAmount__c.CBBudgetLine__c, budgetLines[i]);
				}
			}
		}
		uow.commitWork();
	}

	public static void recalculateBudgetLineValues() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBBudgetLine__c.SObjectType
				}
		);
		for (AggregateResult ar : [SELECT SUM(Value__c) sumValue, cblight__CBBudgetLine__c blId FROM CBAmount__c WITH SECURITY_ENFORCED GROUP BY cblight__CBBudgetLine__c]) {
			uow.registerDirty(new CBBudgetLine__c(Id = (String) ar.get('blId'), Value__c = (Decimal) ar.get('sumValue')));
		}
		uow.commitWork();
	}

}