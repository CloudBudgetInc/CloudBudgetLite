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


public with sharing class CBModelingRuleMassUpdateBatch implements Database.Batchable<sObject> {

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
	// TODO combine such variables in service or map classes during refactoring
	private List<cblight__CBModelingLine__c> modelingLines {
		get {
			if (modelingLines == null) {
				modelingLines = new CBModelingLineSelector().getModelingLinesByRule(modelingRuleId);
			}
			return modelingLines;
		}
		set;
	}

	public CBModelingRuleMassUpdateBatch(String modelingRuleId) {
		this.modelingRuleId = modelingRuleId;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		String query;
		try {
			CBModelingRuleSourceSelector selector = new CBModelingRuleSourceSelector(modelingRule, null);
			query = selector.getSourceDataQuery();
			CBLogService.setLog('BATCH', 'CBModelingRuleMassUpdateBatch', 'Job started', null);
			CBLogService.addLogDetail('CBModelingRuleMassUpdateBatch', 'QUERY =' + query, null);
			CBLogService.insertLog();
			return Database.getQueryLocator(query);
		} catch (Exception e) {
			CBLogService.setLog(e, 'MRB->start:');
			CBLogService.insertLog();
			throw new CBException(e, 'MRB->start:' + query);
		}
	}

	public void execute(Database.BatchableContext BC, List<SObject> sourceRecordList) { // source records
		if (modelingRule == null) throw new CBException('MRB:E:Modeling rule is null');
		try {
			for (sObject obj : sourceRecordList) {
				updateRecord(obj);
			}
			if (sourceRecordList.size() > 0) {
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
						new List<SObjectType>{
							sourceRecordList[0].getSObjectType()
						}
				);
				uow.registerDirty(sourceRecordList);
				uow.commitWork();
			}
			logBatch(BC.getJobId());
		} catch (Exception e) {
			CBLogService.setLog(e, 'MRB->execute:');
			CBLogService.insertLog();
			throw new CBException(e, 'MRB->execute:' + BC);
		}
	}

	private void logBatch(String jobId) {
		List<AsyncApexJob> jobs = [SELECT TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE Id = :jobId];
		if (jobs.size() > 0) {
			AsyncApexJob j = jobs[0];
			CBLogService.setLog('OTHER', 'Current job status', 'Job #' + (j.JobItemsProcessed + 1) + ' from ' + j.TotalJobItems + ' is in progress', null);
			CBLogService.insertLog();
		}
	}
	/**
	 * Method is trying to replace current values in source object with the default values from modeling rule lines
	 * @param obj
	 */
	private void updateRecord(sObject obj) {
		for (CBModelingLine__c mrl : modelingLines) {
			if (mrl.SourceFieldFrom__c == 'Child') continue; // for parent mapping lines only
			if (mrl.Type__c == 'CURRENCY' || mrl.Type__c == 'DOUBLE') {
				obj.put(mrl.SourceField__c, Decimal.valueOf(mrl.Default__c));
			} else {
				obj.put(mrl.SourceField__c, mrl.Default__c);
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
		CBTaskDispatcherService.runNextTask();
	}


}