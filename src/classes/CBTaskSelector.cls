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

public with sharing class CBTaskSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			CBTask__c.CreatedById,
			CBTask__c.CBTaskQueue__c,
			CBTask__c.ClassName__c,
			CBTask__c.LastModifiedById,
			CBTask__c.OwnerId,
			CBTask__c.Name,
			CBTask__c.Id,
			CBTask__c.OrderNumber__c,
			CBTask__c.Parameter1__c,
			CBTask__c.Parameter2__c,
			CBTask__c.QueueName__c,
			CBTask__c.Status__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBTask__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'cblight__OrderNumber__c';
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBTask__c>: List of the records order by selected filter
	 */
	public List<CBTask__c> getTaskRecords(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		return Database.query(query.toSOQL());
	}

	/**
	 * @param rId (Id): record Id
	 *
	 * @return CBTask__c: Record selected by Id
	 */
	public CBTask__c getTaskRecordById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\'');
		return Database.query(query.toSOQL());
	}
}