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
 *
 * Each calculation Rule creates separate Task Order and run one by one in a row
 * One job is for one Calculation rule
 * The job iterates over Budget lines that mach the CR filter condition
 *
 */
public with sharing class CBCalculationRuleBatch implements Database.Batchable<SObject>, Database.Stateful {

	private cblight__CBCalculationRule__c cr;
	private cblight__CBNonFinancialLibrary__c NFL;
	private String baseLayerId { // NFL Layer to store base amounts
		get {
			List<cblight__CBLayer__c> layers = [SELECT Id FROM cblight__CBLayer__c WHERE Name = :CBCalculationRuleService.BASE_LAYER_NAME WITH SECURITY_ENFORCED];
			if (layers.isEmpty()) {
				throw new CBException(null, 'No Base Layer found');
			}
			return layers[0].Id;
		}
		set;
	}
	private String varLayerId { // NFL Layer to store base amounts
		get {
			List<cblight__CBLayer__c> layers = [SELECT Id FROM cblight__CBLayer__c WHERE Name = :CBCalculationRuleService.VAR_LAYER_NAME WITH SECURITY_ENFORCED];
			if (layers.isEmpty()) {
				throw new CBException(null, 'No Var Layer found');
			}
			return layers[0].Id;
		}
		set;
	}

	private Map<Id, cblight__CBAmount__c> periodIdToAmountMap = new Map<Id, CBAmount__c>();
	private cblight__CBBudgetLine__c sourceLine;

	public CBCalculationRuleBatch(String crId) {
		this.cr = new CBCalculationRuleSelector().getCalculationRules('Id = \'' + crId + '\'')[0];
		if (this.cr.cblight__NFL1__c != null) {
			this.NFL = new CBNonFinancialLibrarySelector().getNonFinancialLibrariesByFilter('Id = \'' + this.cr.cblight__NFL1__c + '\'', null)[0];
		}
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String q = getQueryString();
		try {
			return Database.getQueryLocator(q);
		} catch (Exception e) {
			// STUB PURPOSE ONLY - DO NOT DELETE
			return Database.getQueryLocator('SELECT Id FROM cblight__CBLog__c WHERE Id = NULL WITH SECURITY_ENFORCED');
		}
	}

	/**
	 * @param BC
	 * @param sourceBudgetLines
	 */
	public void execute(Database.BatchableContext BC, List<cblight__CBBudgetLine__c> sourceBudgetLines) {

		if (cr == null) {
			throw new CBException(null, 'No Calculation Rule found');
		}

		switch on cr.Mode__c {
			when 'one-to-one' {
				List<CBCalculationRuleWrapper> wrappers = new List<CBCalculationRuleWrapper>();
				for (cblight__CBBudgetLine__c bl : sourceBudgetLines) {
					if (cr.cblight__CBAllocationTerms__r.size() == 0) {
						wrappers.add(new CBCalculationRuleWrapper(bl, cr, NFL, baseLayerId, varLayerId, null));
					} else {
						wrappers.addAll(CBCalculationRuleService.getBudgetLinesAllocatedByBudgetYears(bl, cr));
					}
				}
				if (wrappers.size() == 0) return ;
				CBCalculationRuleWrapper.insertResultBudgetLines(wrappers);
			}
			when 'many-to-one' {
				CBCalculationRuleWrapper.calcAmountsForGroupedBudgetLine(sourceBudgetLines, periodIdToAmountMap);
				if (this.sourceLine == null) {
					this.sourceLine = sourceBudgetLines[0]; // first budget line in a pack becomes a container for whole source budget lines
				}
			}
		}

	}


	/**
	 * The method inserts result BL if current calcrule mode is many-to-one and runs next task.
	 *
	 * @param BC
	 */
	public void finish(Database.BatchableContext BC) {
		if (cr.Mode__c == 'many-to-one') {
			CBCalculationRuleWrapper.insertResultBudgetLines(new List<CBCalculationRuleWrapper>{
					new CBCalculationRuleWrapper(sourceLine, cr, NFL, baseLayerId, varLayerId, periodIdToAmountMap.values())
			});
		}
		CBTaskDispatcherService.runNextTask();
	}

	/**
	 * @return a soql query to get budget lines fit the current calculation rule
	 */
	public String getQueryString() {
		String blFields = 'SELECT cblight__CBBudgetYear__c,cblight__CBDivision__c,cblight__CBAccount__c,cblight__CBScenario__c,' +
				'cblight__CBVariable1__c,cblight__CBVariable2__c,cblight__CBVariable3__c,cblight__CBVariable4__c,cblight__CBVariable5__c,';
		String subQuery = ' (SELECT cblight__CBPeriod__c,cblight__Value__c FROM cblight__CBAmounts__r ' +
				(cr.cblight__SourceChildFilter__c == null ? '' : ' WHERE ' + cr.cblight__SourceChildFilter__c) +
				') ';
		String fr = ' FROM cblight__CBBudgetLine__c ';
		String blFilter = cr.cblight__SourceParentFilter__c == null ? '' : ' WHERE ' + cr.cblight__SourceParentFilter__c;
		return blFields + subQuery + fr + blFilter;
	}

}