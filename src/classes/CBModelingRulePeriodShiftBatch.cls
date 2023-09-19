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

This job works after the main generation job. It uses period delay to update newly created records with a new periods
 */

public with sharing class CBModelingRulePeriodShiftBatch implements Database.Batchable<sObject> {

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

	public CBModelingRulePeriodShiftBatch(String modelingRuleId) {
		this.modelingRuleId = modelingRuleId;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		String q = 'SELECT cblight__CBPeriod__c FROM ';
		if (modelingRule.cblight__MultilevelResult__c) {
			q += modelingRule.ResultRecordChildType__c;
			String parentFieldName = modelingRule.ResultRecordParentType__c.replace('__c', '__r');
			q += ' WHERE ' + parentFieldName + '.CBKey__c LIKE \'' + modelingRule.CBModelingRuleGroup__c + '%\'';
		} else {
			q += modelingRule.ResultRecordParentType__c;
			q += ' WHERE CBKey__c LIKE \'' + modelingRule.CBModelingRuleGroup__c + '%\' WITH SECURITY_ENFORCED';
		}

		try {
			/*CBLogService.setLog('OTHER', 'Shift periods batch for ' + modelingRule.Name, 'Query: ' + q, null);
			CBLogService.insertLog();*/
			return Database.getQueryLocator(q);
		} catch (Exception e) {
			throw new CBException(e, 'MRB->start:' + q);
		}
	}

	public void execute(Database.BatchableContext BC, List<SObject> resultRecordList) {
		if (modelingRule == null) throw new CBException('MRB:E:Modeling rule is null');
		CBModelingRuleMappingService.modelingRule = modelingRule;
		Map<String, String> shiftedPeriodsMap = CBModelingRuleMappingService.shiftedPeriodsMap;
		CBModelingRuleService service = new CBModelingRuleService(modelingRule);
		service.shiftResultPeriods(resultRecordList, shiftedPeriodsMap);
		if (resultRecordList.size() > 0) {
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
					new List<SObjectType>{
							resultRecordList[0].getSObjectType()
					}
			);
			uow.registerDirty(resultRecordList);
			uow.commitWork();
		}
	}

	public void finish(Database.BatchableContext BC) {
		CBTaskDispatcherService.runNextTask();
	}

}