/**
 * Created by Max on 5/4/22.

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

This PageController is for CBBudgetYear__c and CBPeriod__c
*/

public with sharing class CBPeriodPageController {

	/**
	  *  Method to get list of BY from Server
	  */
	@AuraEnabled
	public static List<CBBudgetYear__c> getBudgetYearsFromServer() {
		return new CBBudgetYearSelector().getBudgetYears(null);
	}

	/**
	  *  Method to get list of Periods from Server
	  */
	@AuraEnabled
	public static List<CBPeriod__c> getPeriodsFromServer() {
		return new CBPeriodSelector().getPeriods(null);
	}

	/**
	 * Method to upsert BY and Periods
	 * @param byRecord created or updated record
	 *@param periodRecords - list of created peridos
	 *Method sets changes in Period Details to Server 
	 */
	@AuraEnabled
	public static void saveBYandPeriodToServer(CBBudgetYear__c byRecord, List<CBPeriod__c> periodRecords) {
		if (byRecord != null) {
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType> { CBBudgetYear__c.SObjectType, CBPeriod__c.SObjectType }
			);
			uow.registerUpsert(byRecord);
			if (periodRecords != null) {
				for (CBPeriod__c period : periodRecords) {
					if (period.Id == null) {
						uow.registerNew(period, CBPeriod__c.CBBudgetYear__c, byRecord);
					} else {
						uow.registerDirty(period, CBPeriod__c.CBBudgetYear__c, byRecord);
					}
				}
			}
			uow.commitWork();
		}
	}
}