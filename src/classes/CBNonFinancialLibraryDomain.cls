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

public with sharing class CBNonFinancialLibraryDomain extends fflib_SObjectDomain {

	public CBNonFinancialLibraryDomain(List<CBNonFinancialLibrary__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBNonFinancialLibraryDomain(sObjectList);
		}
	}

	public override void onAfterInsert() {
		createRelatedNFLsItems((List<CBNonFinancialLibrary__c>) Records);
	}

	public override void onBeforeDelete() {
		checkRelatedRecords ((List<CBNonFinancialLibrary__c>) Records);
		deleteNFLsRelatedItems((List<CBNonFinancialLibrary__c>) Records);
	}

	/**
	 * This method checks on related records, prevents NFL from being deleted if it has related record and alert a message with details.
	 *
	 * @param nFLs - List of NFLs
	 */
	private static void checkRelatedRecords(List<CBNonFinancialLibrary__c> nFLs) {
		Set<Id>nFLIdSet = (new Map<Id, SObject>(nFLs)).keySet();
		String formattedIds = CBUtils.getFormattedINQuery(nFLIdSet);

		String errorMessage = 'You cannot delete NFL that has related ';
		String functionMessage = checkRelatedFunctions(formattedIds);
		if (functionMessage != null) {
			nFLs[0].addError(errorMessage + functionMessage);
		}
	}

	/**
	 * This method gets all related Functions and return a message if it has.
	 *
	 * @param formattedIds - String of formatted Ids as a Set
	 *
	 * @return - string message if has related Functions or null if not
	 */

	private static String checkRelatedFunctions(String formattedIds) {
		String filter = 'NFL1__c IN ' + formattedIds;
		for (Integer i = 2; i < 5; i++) {
			filter += ' OR NFL' + i + '__c IN ' + formattedIds;
		}
		List<CBFunction__c> functions = new CBFunctionSelector().getFunctions(filter);
		return functions.isEmpty() ? null : 'Function: ' + functions[0].Title__c;
	}

	/**
	 * This method creates related NFL Items
	 *
	 * @param nFLs -List of NFLs
	 */
	private static void createRelatedNFLsItems(List<CBNonFinancialLibrary__c> nFLs) {
		List<CBPeriod__c> periods = new CBPeriodSelector().getPeriods(CBExcelMirrorService.blockAfterInsertNFLTRigger ? 'cblight__CBBudgetYear__c!=\'' + CBExcelMirrorService.byId + '\'' : null);
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
			CBNonFinancialItem__c.SObjectType
		});
		for (CBNonFinancialLibrary__c nfl : nFLs) {
			for (CBPeriod__c p : periods) {
				uow.registerNew(new CBNonFinancialItem__c(Value__c = 0, CBPeriod__c = p.Id, NonFinancialLibrary__c = nfl.Id));
			}
		}
		uow.commitWork();
	}

	/**
	 * This method deletes related NFL Items
	 *
	 * @param nFLs -List of NFLs
	 */
	private static void deleteNFLsRelatedItems(List<CBNonFinancialLibrary__c> nFLs) {

		Set<String> nflIds = new Set<String>();
		for (CBNonFinancialLibrary__c nfl : nFLs) {
			nflIds.add(nfl.Id);
		}
		String filter = ' NonFinancialLibrary__c IN ' + CBUtils.getFormattedINQuery(nflIds);
		List <CBNonFinancialItem__c> nfliList = new CBNonFinancialItemSelector().getNonFinancialItemsByFilter(filter);
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
			CBNonFinancialItem__c.SObjectType
		});
		uow.registerDeleted(nfliList);
		uow.commitWork();
	}


}