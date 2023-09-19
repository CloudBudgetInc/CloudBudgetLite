/** 
Created by Valerii Krykun on 12/06/2022.
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

This job works for zeroing amounts. For correct operation, you need to select Source Parent - CB Amount and select the period in the filter that you need to be zero.
 */

public with sharing class CBModelingRuleZeroingAmountsBatch implements Database.Batchable<sObject> {

	public String modelingRuleId;
	private CBModelingRule__c modelingRule {
		get {
			if (modelingRule == null) {
				modelingRule = new CBModelingRuleSelector().getModelingRuleById(modelingRuleId);
			}
			return modelingRule;
		}
		set;
	}

	private List<cblight__CBModelingLine__c> modelingLine {
		get {
			if (modelingLine == null) {
				modelingLine = new CBModelingLineSelector().getModelingLinesByRule(modelingRuleId);
			}
			return modelingLine;
		}
		set;
	}

	public CBModelingRuleZeroingAmountsBatch(String modelingRuleId) {
		this.modelingRuleId = modelingRuleId;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		String query;
		try {
			CBModelingRuleSourceSelector selector = new CBModelingRuleSourceSelector(modelingRule, null);
			query = selector.getSourceDataQuery();
			CBLogService.setLog('BATCH', 'CBModelingRuleZeroingAmountsBatch', 'Start method', null);
			CBLogService.addLogDetail('CBModelingRuleZeroingAmountsBatch','QUERY =' + query, null);
			CBLogService.insertLog();
			return Database.getQueryLocator(query);
		} catch (Exception e) {
			CBLogService.setLog(e, 'MRB->start:');
			CBLogService.insertLog();
			throw new CBException(e, 'MRB->start:' + query);
		}
	}

	public void execute(Database.BatchableContext BC, List<SObject> resultRecordList) {
		if (modelingRule == null) throw new CBException('MRB:E:Modeling rule is null');
		try {
			String style;
			for (cblight__CBModelingLine__c ml : modelingLine) {
				style = ml.Default__c;
			}
			for (SObject obj : resultRecordList) {
				if((Decimal) obj.get('cblight__Value__c') > 0 || (Decimal) obj.get('cblight__Value__c') == null || (Decimal) obj.get('cblight__Value__c') < 0) {
					obj.put('cblight__Value__c', 0.0);
				}
				obj.put('CBStyle__c', style);
			}
			if (resultRecordList.size() > 0) {
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
						new List<SObjectType>{
								resultRecordList[0].getSObjectType()
						}
				);
				uow.registerDirty(resultRecordList);
				uow.commitWork();
			}
			CBLogService.setLog('BATCH', 'CBModelingRuleZeroingAmountsBatch', 'Execute method', null);
			CBLogService.addLogDetail('BatchableContext','BatchableContext =' + resultRecordList, null);
			CBLogService.insertLog();
		} catch (Exception e) {
			CBLogService.setLog(e, 'MRB->execute:');
			CBLogService.insertLog();
			throw new CBException(e, 'MRB->execute:' + BC);
		}
	}

	public void finish(Database.BatchableContext BC) {
		CBTaskDispatcherService.runNextTask();
	}
}