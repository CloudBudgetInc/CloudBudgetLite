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

public class CBBudgetYearDomain extends fflib_SObjectDomain {

	/**
	 * Full map of by in CB Base
	 */
	public static Map <Id, cblight__CBBudgetYear__c> BYMap {
		get 	{
			if (BYMap == null) { 
				Map<Id, cblight__CBBudgetYear__c> budgetYearMap = new Map<Id, cblight__CBBudgetYear__c>(new CBBudgetYearSelector().getBudgetYears(null));
				
				BYMap = budgetYearMap;
			}
			return BYMap;
		}
		set;
	}

	public CBBudgetYearDomain(List<CBBudgetYear__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable{
		public fflib_SObjectDomain construct(List<SObject> sObjectList){
			return new CBBudgetYearDomain(sObjectList);
		}
	}

	public override void onBeforeInsert() {
		checkStartEndDates((List<CBBudgetYear__c>) Records);
	}

	
	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		checkStartEndDates((List<CBBudgetYear__c>) Records);
	}


	public override void onBeforeDelete(){
		checkBYHasRelatedRecords((Map<Id, CBBudgetYear__c>) ExistingRecords);
	}

	/**
	 * @param records (List<CBBudgetYear__c>): list of budgets years from trigger to check their validity in terms of dates
	 *
	 */
	private static void checkStartEndDates(List<CBBudgetYear__c> records) {
		for (CBBudgetYear__c newYear : records) {
			for (CBBudgetYear__c existingYear : BYMap.values()) {
				if (((newYear.Start__c >= existingYear.Start__c && newYear.Start__c <= existingYear.End__c) && 
				( newYear.Id  != existingYear.Id)) || 
				((newYear.End__c >= existingYear.Start__c && newYear.End__c <= existingYear.End__c)  &&
				 ( newYear.Id  != existingYear.Id))) {
					newYear.addError(System.Label.cb_new_cbbudgetyear_invalid_dates);
				}
			}
		}
	}

	
	/**
	 * @param recordsMap (Map<Id,CBBudgetYear__c>): map of CB Budget Years to check if there are any related CB Periods, CB Cubes or CB Budget Lines
	 *
	 */
	@TestVisible
	private static void checkBYHasRelatedRecords(Map<Id, CBBudgetYear__c> recordsMap) {
		String formattedBYIds = CBUtils.getFormattedINQuery(recordsMap.keySet());
		Boolean isRelated = new CBPeriodSelector().setFilter('cblight__CBBudgetYear__c IN' + formattedBYIds).setLimit(1).query().size() == 1;
		isRelated = isRelated ? true : new CBCubeSelector().setFilter('cblight__CBBudgetYear__c IN' + formattedBYIds).setLimit(1).query().size() == 1;
		isRelated = isRelated ? true : new CBBudgetLineSelector().setFilter('cblight__CBBudgetYear__c IN' + formattedBYIds).setLimit(1).query().size() == 1;
		if(isRelated) {
			for (CBBudgetYear__c budgetYear : recordsMap.values()) {
				budgetYear.addError(String.format(System.Label.cb_ondelete_cbbudgetyear_has_related_records, new List<String>{budgetYear.Name}));
			}
		}
	}

}