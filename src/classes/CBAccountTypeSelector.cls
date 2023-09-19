/** 
Created by Valerii Krykun on 05/12/2022.
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

public with sharing class CBAccountTypeSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			CBAccountType__c.CreatedById,
			CBAccountType__c.ExtId__c,
			CBAccountType__c.Index__c,
			CBAccountType__c.LastModifiedById,
			CBAccountType__c.OwnerId,
			CBAccountType__c.Name,
			CBAccountType__c.Id,
			CBAccountType__c.Sign__c,
			CBAccountType__c.CBStyle__c,
			CBAccountType__c.OrderNumber__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBAccountType__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	/**
	 * @return List<CBAccountType__c>: List of the records
	 */
	public List<CBAccountType__c> getAccountTypeRecords() {
		fflib_QueryFactory query = newQueryFactory();
		return Database.query(query.toSOQL());
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBAccountType__c>: List of the records order by selected filter
	 */
	public List<CBAccountType__c> getAccountTypeRecordsByFilter(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		query.selectField('CBStyle__r.Name');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param rId (Id): record Id
	 *
	 * @return CBAccountType__c: Record selected by Id
	 */
	public CBAccountType__c getAccountTypeRecordById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\'');
		return Database.query(query.toSOQL());
	}
}