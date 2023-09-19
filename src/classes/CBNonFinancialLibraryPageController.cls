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


public with sharing class CBNonFinancialLibraryPageController {

	@AuraEnabled
	public static CBNonFinancialLibrary__c getNonFinLibraryServer(String recordId) {
		return new CBNonFinancialLibrarySelector().getNonFinancialLibrariesByFilter('Id = \'' + recordId + '\'', null)[0];
	}

	@AuraEnabled
	public static List<CBPeriod__c> getAllPeriodsServer() {
		return new CBPeriodSelector().getPeriods(null);
	}

	@AuraEnabled
	public static void saveNonFinancialLibServer(CBNonFinancialLibrary__c library, List<CBNonFinancialItem__c> items) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialLibrary__c.SObjectType, CBNonFinancialItem__c.SObjectType
				}
		);
		uow.registerUpsert(library);

		if (items != null) {
			for (CBNonFinancialItem__c item : items) {
				uow.registerDirty(item, CBNonFinancialItem__c.NonFinancialLibrary__c, library);
			}
		}
		uow.commitWork();
	}

	/**
	 * The method updates nfl items
	 *
	 * @param items each item must have a parent id
	 */
	@AuraEnabled
	public static void updateNonFinancialItemsServer(List<CBNonFinancialItem__c> items) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialItem__c.SObjectType
				}
		);
		uow.registerUpsert(items);
		uow.commitWork();
	}
}