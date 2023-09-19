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

public with sharing class CBNonFinancialItemService {

	/**
	 * This method creates new NFL Items to all NFLs after new periods created.
	 *
	 * @param periods - list of newly created periods
	 */
	public static void insertNFLItemsByPeriods(List<CBPeriod__c> periods) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialItem__c.SObjectType
				}
		);
		List<CBNonFinancialLibrary__c> nFLs = new CBNonFinancialLibrarySelector().getNonFinancialLibrariesByFilter(null, null);
		for (CBNonFinancialLibrary__c nFL : nFLs) {
			for (CBPeriod__c period : periods) {
				uow.registerNew(new CBNonFinancialItem__c(NonFinancialLibrary__c = nFL.Id, CBPeriod__c = period.Id, Value__c = 0));
			}
		}
		uow.commitWork();
	}

}