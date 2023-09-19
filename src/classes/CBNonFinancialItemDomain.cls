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

public with sharing class CBNonFinancialItemDomain extends fflib_SObjectDomain {

	public CBNonFinancialItemDomain(List<CBNonFinancialItem__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBNonFinancialItemDomain(sObjectList);
		}
	}

	public override void onBeforeInsert() {
		checkForDuplicateItems((List<CBNonFinancialItem__c>) Records);
	}

	private static void checkForDuplicateItems(List<CBNonFinancialItem__c> items) {
		String query = '';
		Integer counter = 0;
		Integer size = items.size();
		String template = '(NonFinancialLibrary__c = \'\'{0}\'\' AND CBPeriod__c = \'\'{1}\'\')';

		for (CBNonFinancialItem__c item : items) {
			query += String.format(template, new List<String>{
					item.NonFinancialLibrary__c, item.CBPeriod__c
			}) + ((++counter < size) ? ' OR ' : '');
		}
		List<CBNonFinancialItem__c> existedItems = new CBNonFinancialItemSelector().getNonFinancialItemsByFilter(query);
		if (!existedItems.isEmpty()) items[0].addError('You are trying to create NFL item/s that already in the database.');
	}

}