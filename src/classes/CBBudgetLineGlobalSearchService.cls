/** 
Copyright (c) 2022, CloudBudget, Inc.
Created by Alex L on 06/07/2023.
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
public with sharing class CBBudgetLineGlobalSearchService {

	/**
	 * @param searchString any text
	 *
	 * @return list of budget lines that have searchString in some field
	 */
	@AuraEnabled
	public static List<CBBudgetLine__c> getBudgetLinesBySearchServer(String searchString) {
		String whereFilter = getTextFilterBudgetLineQuery(searchString);
		if (whereFilter == null) return new List<CBBudgetLine__c>();
		return new CBBudgetLineSelector().getBudgetLines(whereFilter);
	}

	/**
	 * @param searchString
	 *
	 * @return query for BL Selector
	 */
	public static String getTextFilterBudgetLineQuery(String searchString) {
		String whereFilter = isNumber(searchString) ? getRequestForDecimals(searchString) : getRequestForStrings(searchString);
		List<CBAmount__c> amounts = new CBAmountSelector().getAmountsRecordsByFilter(whereFilter);
		if (amounts.size() == 0) return null;
		Set<Id> blIds = new Set<Id>();
		for (CBAmount__c am : amounts) {
			blIds.add(am.cblight__CBBudgetLine__c);
		}
		return ' ID IN ' + CBUtils.getFormattedINQuery(blIds);
	}

	/**
	 * @param searchString is searchString is decimal
	 */
	private static String getRequestForDecimals(String searchString) {
		Decimal searchDecimal = Decimal.valueOf(searchString);
		return ' cblight__CBBudgetLine__r.cblight__Value__c = ' + searchDecimal + ' OR cblight__Value__c = ' + searchDecimal;
	}

	/**
	 * @param searchString is searchString is text
	 */
	private static String getRequestForStrings(String searchString) {
		List<String> checkedBLFields = new List<String>{
				'Name', 'cblight__Description__c', 'cblight__CBAccount__r.Name', 'cblight__CBDivision__r.Name',
				'cblight__CBVariable1__r.Name', 'cblight__CBVariable2__r.Name', 'cblight__CBVariable3__r.Name', 'cblight__CBVariable4__r.Name', 'cblight__CBVariable5__r.Name'
		};
		List<String> r = new List<String>();
		for (String s : checkedBLFields) {
			String operator = r.size() > 0 ? ' OR ' : '';
			r.add(operator + 'cblight__CBBudgetLine__r.' + s + ' LIKE \'%' + searchString + '%\' ');
		}
		return String.join(r, '');
	}

	private static Boolean isNumber(String searchString) {
		try {
			Decimal.valueOf(searchString);
			return true;
		} catch (Exception e) {
			return false;
		}
	}

}