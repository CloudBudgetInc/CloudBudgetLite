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

Selector for the ModelingLine sObject
 */
public with sharing class CBModelingLineSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBModelingLine__c.Id,
				CBModelingLine__c.Name,
				CBModelingLine__c.CBModelingRule__c,
				CBModelingLine__c.SourceField__c,
				CBModelingLine__c.SourceFieldFrom__c,
				CBModelingLine__c.ResultField__c,
				CBModelingLine__c.ResultFieldFrom__c,
				CBModelingLine__c.Default__c,
				CBModelingLine__c.SpecifyDefault__c,
				CBModelingLine__c.Type__c,
				CBModelingLine__c.isGlobal__c,
				CBModelingLine__c.SourceObjectType__c,
				CBModelingLine__c.ResultObjectType__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBModelingLine__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	public List<CBModelingLine__c> getModelingLineById(String recordId) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(recordId)) {
			query.setCondition('Id = \'' + recordId + '\'');
		}
		return Database.query(query.toSOQL());
	}

	public List<CBModelingLine__c> getModelingLinesByRule(String recordId) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(recordId)) {
			query.setCondition('cblight__CBModelingRule__c = \'' + recordId + '\'');
		}
		return Database.query(query.toSOQL());
	}

	public List<CBModelingLine__c> getModelingLinesByRuleSet(Set<String> recordIdSet) {
		fflib_QueryFactory query = newQueryFactory();
		if (recordIdSet.size() > 0) {
			query.setCondition(
					' cblight__CBModelingRule__c IN ' + CBUtils.getFormattedINQuery(recordIdSet)
			);
		}
		return Database.query(query.toSOQL());
	}

	public List<CBModelingLine__c> getGlobalModelingLinesByModelingRule(String mrId) {
		CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(mrId);
		fflib_QueryFactory query = newQueryFactory();
		String condition = ' cblight__isGlobal__c = true AND ' +
				'(cblight__SourceObjectType__c = \'' + mr.SourceRecordParentType__c + '\' OR cblight__SourceObjectType__c = \'' + mr.SourceRecordChildType__c + '\' ) ' +
				'AND ' +
				'(cblight__ResultObjectType__c = \'' + mr.ResultRecordParentType__c + '\' OR cblight__ResultObjectType__c = \'' + mr.ResultRecordChildType__c + '\' ) ';
		query.setCondition(condition);
		return Database.query(query.toSOQL());
	}
}