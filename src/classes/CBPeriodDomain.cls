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

public class CBPeriodDomain extends fflib_SObjectDomain {

	/**
	 * Full map of periods in CB Base
	 */
	public static Map <Id, cblight__CBPeriod__c> periodMap {
		get {
			if (periodMap == null) {
				Map<Id, cblight__CBPeriod__c> pMap = new Map<Id, cblight__CBPeriod__c>(new CBPeriodSelector().getPeriods(null));
				periodMap = pMap;
			}
			return periodMap;
		}
		set;
	}

	public CBPeriodDomain(List<CBPeriod__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBPeriodDomain(sObjectList);
		}
	}

	public override void onBeforeInsert() {
		checkStartEndDates((List<CBPeriod__c>) Records);
	}

	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		checkStartEndDates((List<CBPeriod__c>) Records);
	}

	public override void onBeforeDelete() {
		checkPeriodsHaveRelatedRecords((Map<Id, CBPeriod__c>) ExistingRecords);
	}


	public override void onAfterInsert() {
		CBNonFinancialItemService.insertNFLItemsByPeriods((List<CBPeriod__c>) Records);
	}

	/**
	 * @param records (List<CBPeriod__c>): list of periods from trigger to check their validity in terms of dates
	 */
	@TestVisible
	private static void checkStartEndDates(List<CBPeriod__c> records) {
		for (CBPeriod__c newPeriod : records) {
			for (CBPeriod__c existingPeriod : periodMap.values()) {
				if (((newPeriod.Start__c >= existingPeriod.Start__c && newPeriod.Start__c <= existingPeriod.End__c) &&
						(newPeriod.Id != existingPeriod.Id)) ||
						((newPeriod.End__c >= existingPeriod.Start__c && newPeriod.End__c <= existingPeriod.End__c)) &&
						(newPeriod.Id != existingPeriod.Id)) {
					newPeriod.addError(System.Label.cb_new_cbperiod_invalid_dates);
				}
			}
		}
	}

	/**
	 * @param recordsMap (Map<Id,CBPeriod__c>): map of CB Periods to check if there are any related CB Amounts, CB Cubes or CB Report Columns
	 */
	@TestVisible
	private static void checkPeriodsHaveRelatedRecords(Map<Id, CBPeriod__c> recordsMap) {
		String formattedPeriodIds = CBUtils.getFormattedINQuery(recordsMap.keySet());
		Boolean isRelated = new CBAmountSelector().getAmountsByFilter('cblight__CBPeriod__c IN' + formattedPeriodIds, 1).size() == 1;
		isRelated = isRelated ? true : new CBCubeSelector().setFilter('cblight__CBPeriod__c IN' + formattedPeriodIds).setLimit(1).query().size() == 1;
		isRelated = isRelated ? true : new CBReportColumnSelector().setFilter('cblight__CBPeriod__c IN' + formattedPeriodIds).setLimit(1).query().size() == 1;
		if (isRelated) {
			for (CBPeriod__c period : recordsMap.values()) {
				period.addError(String.format(System.Label.cb_ondelete_cbperiod_has_related_records, new List<String>{
						period.Name
				}));
			}
		}
	}


}