/** 
Copyright (c) 2022, CloudBudget, Inc.
Alex JR  9/6/2022
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


public with sharing class CBNonFinancialLibrarySelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBNonFinancialLibrary__c.Description__c,
				CBNonFinancialLibrary__c.Id,
				CBNonFinancialLibrary__c.Index__c,
				CBNonFinancialLibrary__c.Layer__c,
				CBNonFinancialLibrary__c.LayerTitle__c,
				CBNonFinancialLibrary__c.Name,
				CBNonFinancialLibrary__c.SingleValue__c,
				CBNonFinancialLibrary__c.Type__c,
				CBNonFinancialLibrary__c.Unit__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBNonFinancialLibrary__c.sObjectType;
	}

	public CBNonFinancialLibrarySelector() {
		this.qFactory = newQueryFactory();
	}
	
	private fflib_QueryFactory qFactory;

	/**
	 * @param limitCount if not null and > 0 causes a LIMIT clause to be added to the resulting query.
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBNonFinancialLibrarySelector setLimit(Integer limitCount) {
		if (limitCount != null && limitCount > 0) {
			qFactory.setLimit(limitCount);
		}
		return this;
	}

	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBNonFinancialLibrarySelector setOrder(String fieldNames, Boolean ascending) {
		if (fieldNames != null && !String.isBlank(fieldNames)) {
			fflib_QueryFactory.SortOrder so = fflib_QueryFactory.SortOrder.ASCENDING;
			if (ascending != null && !ascending) {
				so = fflib_QueryFactory.SortOrder.DESCENDING;
			}
			qFactory.setOrdering(fieldNames, so);
		}
		return this;
	}

	public List<CBNonFinancialLibrary__c> getNonFinancialLibrariesByFilter(String libFilter, String itemFilter) {
		if (String.isNotBlank(libFilter)) {
			this.qFactory.setCondition(libFilter);
		}
		List<String> itemFields = new List<String>{
				'cblight__Value__c', 'cblight__CBPeriod__c', 'cblight__PeriodName__c', 'cblight__CBBudgetYear__c', 'Id', 'cblight__CBBudgetYearSet__c'
		};
		fflib_QueryFactory itemsQuery = this.qFactory
				.subSelectQuery('cblight__NonFinancialItems__r')
				.selectFields(itemFields)
				.setOrdering('cblight__CBPeriod__r.cblight__Start__c', fflib_QueryFactory.SortOrder.ASCENDING);
		if (!String.isBlank(itemFilter)) {
			itemsQuery.setCondition(itemFilter);
		}
		return Database.query(this.qFactory.toSOQL());
	}
}