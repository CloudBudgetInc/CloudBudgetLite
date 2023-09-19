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
 */
public with sharing class CBBudgetLineSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBBudgetLine__c.Id,
				CBBudgetLine__c.Name,
				CBBudgetLine__c.CBBudgetYear__c,
				CBBudgetLine__c.CBDivision__c,
				CBBudgetLine__c.CBAccount__c,
				CBBudgetLine__c.CBAccountType__c,
				CBBudgetLine__c.CBAccountSign__c,
				CBBudgetLine__c.CBScenario__c,
				CBBudgetLine__c.CBSubAccountName__c,
				CBBudgetLine__c.CBVariable1__c,
				CBBudgetLine__c.CBVariable2__c,
				CBBudgetLine__c.CBVariable3__c,
				CBBudgetLine__c.CBVariable4__c,
				CBBudgetLine__c.CBVariable5__c,
				CBBudgetLine__c.Description__c,
				CBBudgetLine__c.DrillDownIds__c,
				CBBudgetLine__c.isAllocation__c,
				CBBudgetLine__c.isFormulaBudgetLine__c,
				CBBudgetLine__c.isTopdown__c,
				CBBudgetLine__c.Lock__c,
				CBBudgetLine__c.ParentBudgetLine__c,
				CBBudgetLine__c.NFL1__c,
				CBBudgetLine__c.NFL2__c,
				CBBudgetLine__c.NFL3__c,
				CBBudgetLine__c.NFL4__c,
				CBBudgetLine__c.NFL5__c,
				CBBudgetLine__c.NFLFormula__c,
				CBBudgetLine__c.WarningMessage__c,
				CBBudgetLine__c.Status__c,
				CBBudgetLine__c.Value__c
		};
	}

	private static final String DEFAULT_ORDER = 'cblight__CBAccount__r.cblight__CBAccountType__r.cblight__OrderNumber__c, CreatedDate';

	public CBBudgetLineSelector(Boolean includeSelectorFields) {
		this.qFactory = newQueryFactory(includeSelectorFields);
	}

	public CBBudgetLineSelector() {
		this.qFactory = newQueryFactory();
	}

	private fflib_QueryFactory qFactory;

	public Schema.SObjectType getSObjectType() {
		return CBBudgetLine__c.sObjectType;
	}

	public override String getOrderBy() {
		CBOrgVariable__c orgVar = CBOrgVariableSelector.getOrgVariableServer();
		String customSorting;
		if (orgVar != null && orgVar.cblight__BudgetLinesOrder__c != null) {
			customSorting = orgVar.cblight__BudgetLinesOrder__c.replace(';', ', ');
		}
		return customSorting == null ? DEFAULT_ORDER : customSorting;
	}

	/**
 * @param fieldNames the List of field API names to select.
 *
 * @return instance of CBBudgetLineSelector
 */
	public CBBudgetLineSelector selectFieldsByNames(List<String> fieldNames) {
		qFactory.selectFields(fieldNames);
		return this;
	}

	/**
	 * @param limitCount if not null and > 0 causes a LIMIT clause to be added to the resulting query.
	 *
	 * @return instance of CBBudgetLineSelector
	 */
	public CBBudgetLineSelector setLimit(Integer limitCount) {
		if (limitCount != null && limitCount > 0) {
			qFactory.setLimit(limitCount);
		}
		return this;
	}

	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBBudgetLineSelector
	 */
	public CBBudgetLineSelector setFilter(String filter) {
		if (!String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return this;
	}
	/**
	 * @return List<CBBudgetLine__c>: List of the records
	 */
	public List<CBBudgetLine__c> query() {
		return Database.query(qFactory.toSOQL());
	}

	/**
	 * The main method to get list of budget lines
	 *
	 * @param filter
	 *
	 * @return list of budget lines
	 */
	public List<CBBudgetLine__c> getBudgetLines(String filter) {
		Integer i = 1;
		while (i <= 5) {
			qFactory.selectField('cblight__NFL' + String.valueof(i) + '__r.cblight__Layer__r.Name');
			i++;
		}
		qFactory.selectField('Owner.Name');
		if (CBMultiCurrencyService.multiCurrencyEnabled) {
			qFactory.selectField('CurrencyIsoCode');
		}
		for (String fName : getListOfAnalyticNames()) {
			qFactory.selectField(fName);
		}
		setFilter(filter);
		new CBAmountSelector().addQueryFactorySubSelect(qFactory, 'cblight__CBAmounts__r'); // get budget line children
		return Database.query(qFactory.toSOQL());
	}

	public List<CBBudgetLine__c> getBudgetLinesByFilter(String blFilter, String amountFilter) {
		fflib_QueryFactory query = newQueryFactory();
		query.selectField('Owner.Name');

		for (String fName : getListOfAnalyticNames()) {
			query.selectField(fName);
		}
		if (!String.isBlank(blFilter)) {
			query.setCondition(blFilter);
		}
		List<String> amountFields = new List<String>{
				'cblight__CBBudgetYear__c', 'cblight__Value__c', 'cblight__CBPeriod__c', 'Id', 'cblight__CBStyleName__c'
		};
		fflib_QueryFactory amountQuery = query
				.subSelectQuery('cblight__CBAmounts__r')
				.selectFields(amountFields)
				.setOrdering('cblight__CBPeriod__r.cblight__Start__c', fflib_QueryFactory.SortOrder.ASCENDING);
		if (!String.isBlank(amountFilter)) {
			amountQuery.setCondition(amountFilter);
		}
		List<CBBudgetLine__c> r = new List<CBBudgetLine__c>();
		for (CBBudgetLine__c bl : Database.query(query.toSOQL())) {
			r.add(bl);
		}
		return r;
	}

	/**
	 *
	 *
	 * @return list of fields with names
	 */
	private static List<String> getListOfAnalyticNames() {
		Schema.DescribeSObjectResult classObj = CBBudgetLine__c.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> classFields = classObj.fields.getMap();
		List<String> r = new List<String>();
		String name;
		DisplayType type;
		for (Schema.sObjectField fieldName : classFields.values()) {
			name = fieldName.getDescribe().getName();
			type = fieldName.getDescribe().getType();
			if (type == DisplayType.REFERENCE) {
				r.add(name.replace('__c', '__r.Name'));
			}
			r.add(name);
		}
		return r;
	}

	/**
	 * @param blIdsSet set of needed BL Ids
	 *
	 * @return list of budget lines needed for approval process with needed fields
	 */
	public List<CBBudgetLine__c> getBudgetLinesForApproving(Set<String> blIdsSet) {
		String filter = ' Id IN ' + CBUtils.getFormattedINQuery(blIdsSet);
		List<String> approvingFields = new List<String>{
				'Owner.Name', 'OwnerId', 'cblight__ParentBudgetLine__c',
				'cblight__APHaveAccessToAhead__c', 'cblight__APHaveAccessToAhead__r.Name',
				'cblight__APHaveAccessToBack__c', 'cblight__APHaveAccessToBack__r.Name',
				'cblight__APNextStatusName__c', 'cblight__APPreviousStatusName__c',
				'cblight__APAheadTrigger__c', 'cblight__APBackTrigger__c'
		};
		fflib_QueryFactory query = newQueryFactory();
		query.selectFields(approvingFields).setCondition(filter);
		return Database.query(query.toSOQL());
	}
	/**
	 * @return list of 5 recently opened budget lines
	 */
	public List<CBBudgetLine__c> getRecentBudgetLines() {
		String filter = ' LastModifiedById = \'' + UserInfo.getUserId() + '\'  ';
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(filter).setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING).setLimit(5);
		return Database.query(query.toSOQL());
	}
}