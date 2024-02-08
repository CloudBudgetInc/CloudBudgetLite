/** 
Copyright (c) 2022, CloudBudget, Inc.
Alex JR 12/28/2022
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
public with sharing class CBCalculationRulePageController {

	/**
	 * @param params page filters
	 *
	 * @return list of all calculation rules
	 */
	@AuraEnabled
	public static List<CBCalculationRule__c> getCalculationRulesServer(String folderId) {
		folderId = CBUtils.refineStr(folderId);
		String filter = '';
		if (folderId != null && folderId != 'null') {
			filter = 'CBFolder__c = \'' + folderId + '\'';
		} else {
			filter = 'CBFolder__c = null';
		}
		return new CBCalculationRuleSelector().getCalculationRules(filter);
	}

	/**
	 * @param crId selected budget line Id
	 *
	 * @return needed calculation rule with needed fields
	 */
	@AuraEnabled
	public static Map<String, Object> getSingleCalculationRuleServer(String crId) {
		Map<String, Object> r = new Map<String, Object>();
		CBCalculationRule__c cr = new CBCalculationRuleSelector().getCalculationRules('Id = \'' + crId + '\'')[0];
		r.put('calculationRule', cr);
		return r;
	}

	/**
	 * @return fields of BL and amount sObjects
	 */
	@AuraEnabled
	public static Map<String, List<CBSO>> getSelectOptionsServer() {
		Map<String, List<CBSO>> r = new Map<String, List<CBSO>>();
		r.put('budgetLineFieldSO', CBUtils.getObjectFieldsSO('cblight__CBBudgetLine__c'));
		r.put('amountFieldSO', CBUtils.getObjectFieldsSO('cblight__CBAmount__c'));
		return r;
	}

	/**
	 * @param cr calculation rule to save
	 *
	 * @return calculation rule Id
	 */
	@AuraEnabled
	public static String saveCalculationRuleServer(cblight__CBCalculationRule__c cr) {
		Integer numberOfRules = [SELECT COUNT() FROM cblight__CBCalculationRule__c LIMIT 10];
		if (cr.Id == null && numberOfRules > 0) {
			throw new CBException(null, 'The limit for the Light version is one rule');
		}
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						cblight__CBCalculationRule__c.SObjectType
				}
		);
		uow.registerUpsert(cr);
		uow.commitWork();
		CBCalculationRuleService.updateCRTaskQueue();
		CBCalculationRuleService.generateNeededLayers();
		runRecalculation();
		return cr.Id;
	}

	private static void runRecalculation() {
		try {
			CBTaskQueue__c tq = [SELECT Id FROM CBTaskQueue__c WHERE Name = 'Calculation Rule Process'][0];
			CBTaskDispatcherService.runQueue(tq.Id);
		} catch (Exception e) {

		}
	}


	/**
	 * @param crId calculation rule Id need to be deleted
	 */
	@AuraEnabled
	public static void deleteCalculationRuleServer(String crId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
				CBAllocationTerm__c.SObjectType, CBCalculationRule__c.SObjectType
		});
		uow.registerDeleted(new CBSobjectSelector(CBAllocationTerm__c.SObjectType).getSobjects(' CBCalculationRule__c = \'' + crId + '\''));
		uow.registerDeleted(new CBCalculationRuleSelector().getCalculationRules(' Id = \'' + crId + '\''));
		uow.commitWork();
	}

	/**
	 * @param blFilter source budget lines filter
	 * @param amountFilter source BL amounts lines filter
	 *
	 * @return small report with the source budget lines statistic
	 */
	@AuraEnabled
	public static Map<String, String> checkSourceBudgetLineServer(String blFilter, String amountFilter) {
		return CBCalculationRuleService.checkSourceBudgetLine(blFilter, amountFilter);
	}

	/**
	 * @param NFLId Id of selected in a calculation rule NFL
	 *
	 * @return list of NFL Items to calculate amounts in an example
	 */
	@AuraEnabled
	public static List<CBNonFinancialItem__c> getNFLAmountsServer(String nflId) {
		return [SELECT cblight__Value__c FROM cblight__CBNonFinancialItem__c WHERE NonFinancialLibrary__c = :nflId WITH SECURITY_ENFORCED ORDER BY CBPeriod__r.Start__c LIMIT 12];
	}


}