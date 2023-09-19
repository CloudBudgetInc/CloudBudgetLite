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


public with sharing class CBWelcomeSelector extends fflib_SObjectSelector {

	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBWelcome__c.Id,
				CBWelcome__c.Name,
				CBWelcome__c.cblight__Content__c,
				CBWelcome__c.cblight__Description__c,
				CBWelcome__c.cblight__Icon__c,
				CBWelcome__c.cblight__Header__c,
				CBWelcome__c.cblight__Parent__c,
				CBWelcome__c.cblight__Type__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBWelcome__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	/**
	 * @param recordId CBWelcome record Id
	 *
	 * @return
	 */
	public CBWelcome__c getWelcomeById(String recordId) {
		if (recordId == null) {
			return null;
		}
		return getWelcomeByFilter('Id = \'' + recordId + '\'')[0];
	}

	/**
	 * @param recordId CBWelcome record Id
	 *
	 * @return
	 */
	public CBWelcome__c getWelcomeByName(String name) {
		try {
			if (name == null) {
				return null;
			}
			return getWelcomeByFilter('Name = \'' + name + '\'')[0];
		} catch (Exception e) {
			throw new CBException(e, 'The database does not contain Welcome with such a name');
		}
	}

	/**
	 * @param filter - part of SOQL query
	 *
	 * @return
	 */
	public List<CBWelcome__c> getWelcomeByFilter(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		new CBWelcomeSelector().addQueryFactorySubSelect(query, 'cblight__CBWelcomes__r');
		return Database.query(query.toSOQL());
	}

}