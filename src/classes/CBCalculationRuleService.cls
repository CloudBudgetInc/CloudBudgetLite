/**
 * Copyright (c) 2022, CloudBudget, Inc.
 * Alex JR 12/28/2022
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * Neither the name of the CloudBudget, Inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
public with sharing class CBCalculationRuleService {

	private static final String DELETE_CLASS = 'CBCalculationRuleJobDeletingProcess';
	private static final String GENERATE_CLASS = 'CBCalculationRuleJobProcess';
	public static final String BASE_LAYER_NAME = 'Base';
	public static final String VAR_LAYER_NAME = 'Var';
	public static final String PERIOD_LIMIT_ERROR = ' period limit. Please change the Calc Rule settings or create necessary periods';

	/**
	 * Method deletes old Task Queue and creates a new to recalculate calculation rules
	 */
	public static void updateCRTaskQueue() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTaskQueue__c.SObjectType, CBTask__c.SObjectType
				}
		);
		List<CBTaskQueue__c> tql = (List<CBTaskQueue__c>) new CBSobjectSelector('cblight__CBTaskQueue__c', false).selectFieldsByNames(new List<String>{
				'Id'
		}).getSobjects('RelatedTo__c = \'Calculation Rules\'');
		uow.registerDeleted(tql); // delete obsolete task queue

		cblight__CBTaskQueue__c task = new cblight__CBTaskQueue__c(Name = 'Calculation Rule Process', cblight__RelatedTo__c = 'Calculation Rules', cblight__Status__c = 'Idle');
		uow.registerNew(task); // insert queue
		Integer i = 0;
		for (cblight__CBCalculationRule__c cr : new CBCalculationRuleSelector().getCalculationRules('')) { // task for each calculation rule
			uow.registerNew(new CBTask__c(Name = cr.Name, Parameter1__c = cr.Id, cblight__ClassName__c = DELETE_CLASS, cblight__OrderNumber__c = ++i), CBTask__c.CBTaskQueue__c, task);
			uow.registerNew(new CBTask__c(Name = cr.Name, Parameter1__c = cr.Id, cblight__ClassName__c = GENERATE_CLASS, cblight__OrderNumber__c = ++i), CBTask__c.CBTaskQueue__c, task);
		}
		uow.commitWork();
	}

	/**
	 * @param blFilter source budget lines filter
	 * @param amountFilter source BL amounts lines filter
	 *
	 * @return small report with the source budget lines statistic
	 */
	public static Map<String, String> checkSourceBudgetLine(String blFilter, String amountFilter) {
		List<CBBudgetLine__c> bll = new CBBudgetLineSelector().getBudgetLinesByFilter(blFilter, amountFilter);
		Integer blSize = 0, amountSize = 0, blWithoutAmounts = 0;
		Decimal totalValue = 0;
		for (cblight__CBBudgetLine__c bl : bll) {
			blSize++;
			if (bl.cblight__CBAmounts__r.size() == 0) {
				blWithoutAmounts++;
			} else {
				amountSize += bl.cblight__CBAmounts__r.size();
				for (cblight__CBAmount__c a : bl.cblight__CBAmounts__r) {
					totalValue += a.cblight__Value__c;
				}
			}
		}
		Map<String, String> r = new Map<String, String>();
		r.put('Source amounts that match the filter:', 'Number: ' + amountSize + '. Value Total: $' + totalValue);
		r.put('Source budget lines that match the filter:', 'Number: ' + blSize + '. BL Without Amounts: ' + blWithoutAmounts);
		return r;
	}

	/**
	 * The method checks and inserts needed for Calculation rule layers
	 */
	public static void generateNeededLayers() {
		List<CBLayer__c> existedLayers = [SELECT Id,Name FROM CBLayer__c WHERE Name = :BASE_LAYER_NAME OR Name = :VAR_LAYER_NAME WITH SECURITY_ENFORCED];
		if (existedLayers.size() == 2) {return;}
		Boolean baseNeeded = true;
		Boolean varNeeded = true;
		for (CBLayer__c layer : existedLayers) {
			if (BASE_LAYER_NAME.equals(layer.Name)) {baseNeeded = false;}
			if (VAR_LAYER_NAME.equals(layer.Name)) {varNeeded = false;}
		}
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
			CBLayer__c.SObjectType
		});
		if (baseNeeded) {
			uow.registerNew(new CBLayer__c(Name = BASE_LAYER_NAME));
		}
		if (varNeeded) {
			uow.registerNew(new CBLayer__c(Name = VAR_LAYER_NAME));
		}
		uow.commitWork();

	}

	/**
	 * Method process budget line with amounts and Allocation Terms
	 * @param bl - source budget line
	 * @param cr - current calculation rule
	 * @return list of wrappers to insert
	 */
	public static List<CBCalculationRuleWrapper> getBudgetLinesAllocatedByBudgetYears(CBBudgetLine__c sourceBL, cblight__CBCalculationRule__c cr) {
		List<CBAllocationTerm__c> aTerms = cr.cblight__CBAllocationTerms__r;
		List<CBAmount__c> sourceAmounts = sourceBL.cblight__CBAmounts__r;
		CBCalculationRuleWrapper w = new CBCalculationRuleWrapper(sourceBL, cr);
		Map<String, CBAmount__c> resultAmountsMap = new Map<String, CBAmount__c>(); // key is periodId
		try {
			for (CBAmount__c sa : sourceAmounts) {
				if (sa.Value__c == 0) continue;
				Integer sourceAmountIdx = CBPeriodSelector.periodIdIdxMap.get(sa.CBPeriod__c);
				for (CBAllocationTerm__c at : aTerms) {
					String newPeriodId = CBPeriodSelector.idxPeriodIdMap.get(sourceAmountIdx + getMonthEquivalent(at));
					if (newPeriodId == null) throw new CBException(null, '"' + cr.Name + '"' + PERIOD_LIMIT_ERROR);
					CBAmount__c resAmount = resultAmountsMap.get(newPeriodId);
					if (resAmount == null) {
						resAmount = new CBAmount__c(CBPeriod__c = newPeriodId, Value__c = 0);
						resultAmountsMap.put(newPeriodId, resAmount);
					}
					resAmount.Value__c += at.Part__c * sa.Value__c / 100;
				}
			}
		} catch (Exception e) {
			CBLogService.setLog(e, 'Allocation job status');
			CBLogService.insertLog();
			return new List<CBCalculationRuleWrapper>();
		}
		w.resultBLAmounts = resultAmountsMap.values();
		return separateWrapperByBudgetYear(sourceBL, cr, w);
	}
	/**
	 * @param at allocation term
	 * @return number of months to shift period
	 */
	private static Integer getMonthEquivalent(CBAllocationTerm__c at) {
		if (at.Shift__c == null || at.Shift__c == 0) return 0;
		if (at.PeriodUnit__c == null || at.PeriodUnit__c == 'Month') return at.Shift__c.intValue();
		if (at.PeriodUnit__c == 'Day') return (at.Shift__c / (365 / 12)).intValue();
		if (at.PeriodUnit__c == 'Week') return (at.Shift__c / 4).intValue();
		if (at.PeriodUnit__c == 'Quarter') return (at.Shift__c * 3).intValue();
		if (at.PeriodUnit__c == 'Year') return (at.Shift__c * 12).intValue();
		return 0;
	}
	/**
	 * @param sourceBL source for calculation
	 * @param cr calculation rules
	 * @param w created wrapper for the source budget line budget year
	 *
	 * @return one or more wrappers. One for the one budget year
	 */
	private static List<CBCalculationRuleWrapper> separateWrapperByBudgetYear(CBBudgetLine__c sourceBL, cblight__CBCalculationRule__c cr, CBCalculationRuleWrapper w) {
		List<CBCalculationRuleWrapper> r = new List<CBCalculationRuleWrapper>();
		Map<String, List<CBAmount__c>> byAmountMap = new Map<String, List<CBAmount__c>>();
		for (CBAmount__c a : w.resultBLAmounts) {
			String byId = CBPeriodSelector.periodIdBudgetYearIdMap.get(a.CBPeriod__c);
			List<CBAmount__c> amountOfBudgetYearGroup = byAmountMap.get(byId);
			if (amountOfBudgetYearGroup == null) {
				amountOfBudgetYearGroup = new List<CBAmount__c>();
				byAmountMap.put(byId, amountOfBudgetYearGroup);
			}
			amountOfBudgetYearGroup.add(a);
		}
		if (byAmountMap.size() < 2) { // all amounts are inside one BY
			r.add(w);
			return r;
		}
		for (String byId : byAmountMap.keySet()) {
			List<CBAmount__c> amountOfBudgetYearGroup = byAmountMap.get(byId);
			CBCalculationRuleWrapper wrapper = byId == w.resultBL.CBBudgetYear__c ? w : new CBCalculationRuleWrapper(sourceBL, cr);
			wrapper.resultBL.CBBudgetYear__c = byId;
			wrapper.resultBLAmounts = amountOfBudgetYearGroup;
			r.add(wrapper);
		}
		return r;
	}


}