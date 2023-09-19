/** 
Created by Valerii Krykun on 03/21/2022.
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

Selector for the Log sObject
 */
public with sharing class CBLogSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			CBLog__c.Id,
			CBLog__c.Name,
			CBLog__c.cblight__Action__c,
			CBLog__c.CreatedById,
			CBLog__c.CreatedDate,
			CBLog__c.cblight__Description__c,
			CBLog__c.cblight__JobId__c,
			CBLog__c.LastModifiedById,
			CBLog__c.OwnerId,
			CBLog__c.cblight__Parent__c,
			CBLog__c.cblight__Reason__c,
			CBLog__c.cblight__Source__c,
			CBLog__c.cblight__Status__c,
			CBLog__c.cblight__Type__c,
			CBLog__c.cblight__LogNumber__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBLog__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'CreatedDate DESC';
	}
	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBLog__c>: List of the records order by selected filter
	 */
	public List<CBLog__c> getLogFilteredBy(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		query.selectField('Owner.Name');
		query.setLimit(200);
		return Database.query(query.toSOQL());
	}

	/**
	 * @param filter (String): filter value
	 * 
	 * @param limitCount (integer): limit records
	 *
	 * @return List<CBLog__c>: List of the records order by selected filter
	 */
	public List<CBLog__c> getLogFilteredBy(String filter, integer limitCount) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		query.selectField('Owner.Name');
		query.setLimit(limitCount);
		return Database.query(query.toSOQL());
	}
	/**
	 * @param rId (String): filter value
	 *
	 * @return CBLog__c: Record selected by Id
	 */
	public CBLog__c getLogById(String rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(rId)) {
			query.setCondition('Id = \'' + rId + '\'');
		}
		query.selectField('Owner.Name');
		return Database.query(query.toSOQL());
	}
		/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBLog__c>: List of the records with CBLogDetail childs
	 */
	public CBLog__c getLogWithLogDetail(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		query.selectField('Id');
		query.setLimit(1);
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		query.selectField('Owner.Name');
		new CBLogDetailSelector().addQueryFactorySubSelect(query, 'cblight__CBLogDetails__r');
		return Database.query(query.toSOQL());
	}
}