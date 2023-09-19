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


public with sharing class CBCubeSelector extends fflib_SObjectSelector {

	private fflib_QueryFactory qFactory = newQueryFactory();
	/**
	 * Use the setCubeAdditionalFields method
	 * Specify the list of needed Cube fields before using the selector methods
	 */
	public Set<String> additionalFields {
		get {
			if (additionalFields == null) {
				additionalFields = new Set<String>();
			}
			return additionalFields;
		}
		set;
	}

	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBCube__c.Id,
				CBCube__c.Name,
				CBCube__c.Budget__c,
				CBCube__c.Actual__c,
				CBCube__c.cblight__CBPeriod__c,
				CBCube__c.cblight__CBKey__c,
				CBCube__c.cblight__Sign__c,
				CBCube__c.cblight__CBDivision__c,
				CBCube__c.cblight__CBBudgetYear__c,
				CBCube__c.cblight__CBAccount__c,
				CBCube__c.DrillDownIds__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBCube__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'cblight__CBDivision__r.Name, cblight__CBAccount__r.cblight__CBAccountType__r.cblight__OrderNumber__c, ' +
				' cblight__CBAccount__r.Name, cblight__CBVariable1__r.Name ';
	}

	/**
	 * @param fieldSet set of additional CBCube sObject fields that need to be selected
	 * @return current selector object
	 */
	public CBCubeSelector setCubeAdditionalFields(Set<String> fieldSet) {
		additionalFields = fieldSet;
		return this;
	}

	/**
	 * Method set all locally created fields to the SELECT clause
	 * @return instance of CBCubeSelector
	 */
	public CBCubeSelector setAllExtraCBCubeFields() {
		for (String field : CBUtils.getRefinedListOfSObject('cblight__CBCube__c')) {
			additionalFields.add(field);
		}
		for (CBSO cubeSO : CBUtils.getObjectFieldsSO('cblight__CBCube__c')) {
			if (cubeSO.type == 'REFERENCE') {
				additionalFields.add(cubeSO.value.replace('__c', '__r.Name'));
			}
		}
		return this;
	}

	/**
	 * @param limitCounter if not null and > 0 causes a LIMIT clause to be added to the resulting query.
	 *
	 * @return instance of CBCubeSelector
	 */
	public CBCubeSelector setLimit(Integer limitCounter) {
		if (limitCounter != null && limitCounter > 0) {
			qFactory.setLimit(limitCounter);
		}
		return this;
	}

	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBCubeSelector
	 */
	public CBCubeSelector setFilter(String filter) {
		for (String field : additionalFields) {
			qFactory.selectField(field);
		}
		if (!String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return this;
	}

	/**
	 * @return List<CBCube__c>: List of the records
	 */
	public List<CBCube__c> query() {
		return Database.query(qFactory.toSOQL());
	}

}