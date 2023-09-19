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
Special service to convert currency rates
 */


public with sharing class CBMultiCurrencyService {

	/**
	 * True is the org is multiCurrency
	 */
	public static Boolean multiCurrencyEnabled = Schema.getGlobalDescribe().containsKey('CurrencyType');

	public static List<sObject> orgCurrencies {
		get {
			if (orgCurrencies == null) {
				try {
					orgCurrencies = Database.query('SELECT ISOCode, ConversionRate, IsCorporate FROM CurrencyType WHERE IsActive = TRUE');
				} catch (Exception e) {
					return null;
				}
			}
			return orgCurrencies;
		}
		set;
	}

	/**
	 * Retrieves a list of available currencies in the Salesforce org and returns them as CBSO objects.
	 *
	 * @return A List of CBSO objects, each containing the currency's ISO code, name, and corporate status.
	 */
	@AuraEnabled
	public static List<CBSO> getCurrencySOServer() {
		if (!multiCurrencyEnabled) return null;
		List<CBSO> currencySO = new List<CBSO>();
		for (sObject c : orgCurrencies) {
			currencySO.add(new CBSO((String) c.get('ISoCode'), (String) c.get('ISoCode'), String.valueOf(c.get('IsCorporate')), String.valueOf(c.get('ConversionRate'))));
		}
		return currencySO;
	}

	/**
	 * Method takes budget lines to convert rates
	 *
	 * @param BLines list of budget lines
	 * @param toHomeValue true if you need to convert company currency to user currency
	 */
	public static void updateBudgetLinesWithProperlyCurrency(List<CBBudgetLine__c> BLines, Boolean toHomeValue) {
		List<CBAmount__c> wholeAmounts = new List<CBAmount__c>();
		for (CBBudgetLine__c bl : BLines) {
			wholeAmounts.addAll(bl.CBAmounts__r);
		}
		convertBLAmountValues(wholeAmounts, toHomeValue);
	}

	/**
	 * Method takes bl amounts to convert rates
	 *
	 * @param amounts list of BL amounts
	 * @param toHomeValue true if you need to convert company currency to user currency
	 */
	public static void convertBLAmountValues(List<CBAmount__c> amounts, Boolean toHomeValue) {
		if (orgCurrencies.size() < 2) return;
		String userCurrency = UserInfo.getDefaultCurrency();
		String orgCurrency = getOrgCurrency();
		if (userCurrency.toLowerCase() == orgCurrency.toLowerCase()) return;
		Decimal rate = getCurrencyRate(userCurrency.toLowerCase());
		for (CBAmount__c a : amounts) {
			a.Value__c = toHomeValue ? rate * a.Value__c : a.Value__c / rate;
		}
	}
	@TestVisible
	private static String getOrgCurrency() {
		for (sObject ct : orgCurrencies) {
			if ((Boolean) ct.get('isCorporate')) return (String) ct.get('IsoCode');
		}
		return 'USD';
	}
	@TestVisible
	private static Decimal getCurrencyRate(String iso) {
		for (sObject ct : orgCurrencies) {
			if (iso == ((String) ct.get('ISOCode')).toLowerCase()) return (Decimal) ct.get('ConversionRate');
		}
		return 1;
	}

	/**
	 * This method takes a list of CBAmount__c records and queries their parent CBBudgetLine__c records to retrieve the
	 * ISOCode value for each record. It then assigns the retrieved ISOCode value to the corresponding CBAmount__c record.
	 *
	 * @param amountList The list of CBAmount__c records to update.
	 */
	public static void assignCBBudgetLineISOCodeToCBAmounts(List<CBAmount__c> amountList) {
		if (!multiCurrencyEnabled) return;
		// Get the parent record IDs from the child records
		Set<Id> parentIds = new Set<Id>();
		String f = 'CurrencyIsoCode';
		for (CBAmount__c amount : amountList) {
			parentIds.add(amount.CBBudgetLine__c);
		}
		// Query the parent records to get their ISOCode values
		String q = 'SELECT Id,CurrencyIsoCode FROM CBBudgetLine__c WHERE Id IN :parentIds WITH SECURITY_ENFORCED';
		Map<Id, CBBudgetLine__c> parentMap = new Map<Id, CBBudgetLine__c>((List<CBBudgetLine__c>) Database.query(q));
		// Assign the ISOCode value to each child record based on its parent record's value
		for (CBAmount__c amount : amountList) {
			CBBudgetLine__c parent = parentMap.get(amount.CBBudgetLine__c);
			if (parent != null) {
				amount.put(f, parent.get(f));
			}
		}
	}

}