/**
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

 Selector for the ModelingRule sObject
 */
public with sharing class CBModelingRuleSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBModelingRule__c.CBModelingRuleGroup__c,
				CBModelingRule__c.ComplexFilterCondition__c,
				CBModelingRule__c.Description__c,
				CBModelingRule__c.Id,
				CBModelingRule__c.KeyFields__c,
				CBModelingRule__c.Mode__c,
				CBModelingRule__c.MultilevelResult__c,
				CBModelingRule__c.MultilevelSource__c,
				CBModelingRule__c.Name,
				CBModelingRule__c.cblight__PeriodShift__c,
				CBModelingRule__c.SourceChildFilter__c,
				CBModelingRule__c.SourceParentFilter__c,
				CBModelingRule__c.ResultChildFilter__c,
				CBModelingRule__c.ResultParentFilter__c,
				CBModelingRule__c.ResultRecordParentType__c,
				CBModelingRule__c.ResultRecordChildType__c,
				CBModelingRule__c.SourceRecordParentType__c,
				CBModelingRule__c.SourceRecordChildType__c,
				CBModelingRule__c.StoreDrillDown__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBModelingRule__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}
	/**
	 * @param recordId id of needed Modeling Rule
	 * @return modeling rule with list of its modeling lines
	 */
	public CBModelingRule__c getModelingRuleById(String recordId) {
		if (recordId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(recordId)) {
			query.setCondition('Id = \'' + recordId + '\'');
		}
		new CBModelingLineSelector().addQueryFactorySubSelect(query, 'cblight__CBModelingLines__r');
		return Database.query(query.toSOQL());
	}
	/**
	 * @param recordId (String): id of needed Modeling Rule Group
	 *
	 * @return List<CBModelingRule__c>: List of the Rules records order by Modeling Rule Group
	 */
	public List<CBModelingRule__c> getModelingRulesByGroupId(String recordId) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(recordId)) {
			query.setCondition('cblight__CBModelingRuleGroup__c = \'' + recordId + '\'');
		}
		new CBModelingLineSelector().addQueryFactorySubSelect(query, 'cblight__CBModelingLines__r');
		return Database.query(query.toSOQL());
	}
	/**
	 * @param recordIdSet (Set<String>): Set of record Id
	 *
	 * @return List<CBModelingRule__c: List of the Rules records order by Group Set Id
	 */
	public List<CBModelingRule__c> getModelingRulesByGroupSet(Set<String> recordIdSet) {
		fflib_QueryFactory query = newQueryFactory();
		if (recordIdSet.size() > 0) {
			query.setCondition('cblight__CBModelingRuleGroup__c IN ' + CBUtils.getFormattedINQuery(recordIdSet));
		}
		return Database.query(query.toSOQL());
	}
}