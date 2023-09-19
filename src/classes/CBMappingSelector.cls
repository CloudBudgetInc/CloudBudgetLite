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

CBMapping__c - special sObject to map CB sObjects with another objects to sync them

 */

public with sharing class CBMappingSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBMapping__c.Id,
				CBMapping__c.Name,
				CBMapping__c.Type__c, // account, period, department etc.
				CBMapping__c.SourceType__c,
				CBMapping__c.SourceFilter__c, //cblight__ExtId__c != '55'
				CBMapping__c.SpecialFilter__c,
				CBMapping__c.SourceSubtype__c,
				CBMapping__c.SourceSObject__c, // FF1__c for example
				CBMapping__c.ResultSObject__c, // CBVariable1__c for example
				CBMapping__c.ResultType__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBMapping__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	public List<CBMapping__c> getMappingRecords(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		return Database.query(query.toSOQL());
	}

	public CBMapping__c getMappingRecordById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\' ');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param typeName (account || division || other...)
	 *
	 * @return CBMapping__c object
	 */
	public CBMapping__c getMappingRecordByType(String typeName) {
		if (typeName == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition('cblight__Type__c = \'' + typeName + '\' ');
		query.selectField('cblight__SourceName__c');
		List<CBMapping__c> r = Database.query(query.toSOQL());
		return r != null && r.size() > 0 ? r[0] : null;
	}
}