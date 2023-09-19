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
public with sharing class CBReportColumnSelector extends fflib_SObjectSelector {

	private fflib_QueryFactory qFactory = newQueryFactory();

	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBReportColumn__c.Id,
				CBReportColumn__c.Name,
				CBReportColumn__c.Color__c,
				CBReportColumn__c.Formula__c,
				CBReportColumn__c.ValueField__c,
				CBReportColumn__c.Type__c,
				CBReportColumn__c.MasterColumn__c,
				CBReportColumn__c.NeedYTD__c,
				CBReportColumn__c.isHidden__c,
				CBReportColumn__c.OrderNumber__c,
				CBReportColumn__c.CBPeriod__c,
				CBReportColumn__c.CBStyle__c,
				CBReportColumn__c.Unit__c,
				CBReportColumn__c.CBReport__c
		};
	}

	public override String getOrderBy() {
		return 'cblight__OrderNumber__c';
	}

	public Schema.SObjectType getSObjectType() {
		return CBReportColumn__c.sObjectType;
	}

	/**
	 * @param limitCounter if not null and > 0 causes a LIMIT clause to be added to the resulting query.
	 *
	 * @return instance of CBReportColumnSelector
	 */
	public CBReportColumnSelector setLimit(Integer limitCounter){
		if(limitCounter != null && limitCounter > 0) {
			qFactory.setLimit(limitCounter);
		}
		return this;
	}

	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBReportColumnSelector
	 */
	public CBReportColumnSelector setFilter(String filter){
		if (!String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return this;
	}

	public List<CBReportColumn__c> getReportColumnsByReportId(String reportId) {
		if (String.isBlank(reportId)) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.selectField('cblight__CBPeriod__r.Name');
		query.selectField('cblight__CBStyle__r.Name');
		query.setCondition(' cblight__CBReport__c = \'' + reportId + '\' ');
		return Database.query(query.toSOQL());
	}

	/**
	 * @return List<CBReportColumn__c>: List of the records
	 */
	public List<CBReportColumn__c> query() {
		return Database.query(qFactory.toSOQL());
	}
}