/**
Created by Valerii Krykun on 03/21/2022.
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

public with sharing class CBTaskQueueSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBTaskQueue__c.CreatedById,
				CBTaskQueue__c.CreatedDate,
				CBTaskQueue__c.LastModifiedDate,
				CBTaskQueue__c.RelatedTo__c,
				CBTaskQueue__c.LastModifiedById,
				CBTaskQueue__c.OwnerId,
				CBTaskQueue__c.Name,
				CBTaskQueue__c.cblight__Description__c,
				CBTaskQueue__c.cblight__Status__c,
				CBTaskQueue__c.Id
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBTaskQueue__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBTaskQueue__c>: List of the records order by selected filter
	 */
	public List<CBTaskQueue__c> getTaskQueueRecords(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		query.selectField('Owner.Name');
		new CBTaskSelector().addQueryFactorySubSelect(query, 'cblight__CB_Tasks__r');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param rId (String): filter value
	 *
	 * @return CBTaskQueue__c: Record selected by Id
	 */
	public CBTaskQueue__c getTaskQueueRecordById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\'');
		List<CBTaskQueue__c>taskQueues = Database.query(query.toSOQL());
		return (taskQueues.isEmpty()) ? null : taskQueues[0];
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBTaskQueue__c>: List of the records with CB_Tasks__r children
	 */
	public CBTaskQueue__c getTaskQueueWithTaskChildren(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		query.selectField('Id');
		query.setLimit(1);
		for (String fName : getListOfAdditionalAnalytics()) {
			query.selectField(fName);
		}
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		new CBTaskSelector().addQueryFactorySubSelect(query, 'cblight__CB_Tasks__r');
		List<CBTaskQueue__c> taskQueues = Database.query(query.toSOQL());
		return taskQueues.size() > 0 ? taskQueues[0] : null;
	}
	private static List<String> getListOfAdditionalAnalytics() {
		Schema.DescribeSObjectResult classObj = CBTaskQueue__c.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> classFields = classObj.fields.getMap();
		List<String> r = new List<String>();
		String name;
		for (Schema.sObjectField fieldName : classFields.values()) {
			name = fieldName.getDescribe().getName();
			if (name.contains('CL_')) {
				r.add(name);
				name = name.replace('__c', '__r.Id');
				r.add(name);
			}
		}
		return r;
	}
}