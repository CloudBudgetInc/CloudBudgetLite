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


public with sharing class CBFormulaService {

	private static final List<String> FORMULA_KEYS = new List<String>{
			'#1', '#2', '#3', '#4', '#5'
	};

	/**
	 * The method takes source amount, source NFL amounts and a formula to recalculate source amounts
	 *
	 * @param sourceAmounts base amounts that need to be recalculated
	 * @param sourceLines NFL lines that take part in to calculation
	 * @param formula formula in calculation
	 *
	 * @return
	 */
	public static List<CBAmount__c> calculateFormulaTotals(List<CBAmount__c> sourceAmounts, List<List<CBNonFinancialItem__c>> sourceLines, String formula) {

		Map<Id, List<CBNonFinancialItem__c>> periodIdItemsMap = new Map<Id, List<CBNonFinancialItem__c>>();
		Map<Id, CBAmount__c> periodIdAmountMap = new Map<Id, CBAmount__c>();
		for (CBAmount__c a : sourceAmounts) {
			periodIdItemsMap.put(a.CBPeriod__c, new List<CBNonFinancialItem__c>()); // initialization
			periodIdAmountMap.put(a.CBPeriod__c, a);
		}

		populatePeriodIdItemsMap(sourceLines, periodIdItemsMap);
		updateAmounts(periodIdItemsMap, periodIdAmountMap, formula);

		return sourceAmounts;
	}


	/**
	 * The method shoves NFL items to map split by period id
	 *
	 * @param sourceLines list of NFL libs
	 * @param periodIdItemsMap empty map for populating
	 */
	@TestVisible
	private static void populatePeriodIdItemsMap(List<List<CBNonFinancialItem__c>> sourceLines, Map<Id, List<CBNonFinancialItem__c>> periodIdItemsMap) {
		Map<Id, CBNonFinancialItem__c> periodNFLMap;
		for (List<CBNonFinancialItem__c> line : sourceLines) { // iteration over NFL lines
			periodNFLMap = new Map<Id, CBNonFinancialItem__c>();
			for (CBNonFinancialItem__c item : line) {
				periodNFLMap.put(item.CBPeriod__c, item);
			}
			for (Id periodId : periodIdItemsMap.keySet()) {
				CBNonFinancialItem__c item = periodNFLMap.get(periodId);
				if (item == null) throw new CBException('No NFL for needed period');
				periodIdItemsMap.get(periodId).add(item);
			}
		}
	}


	/**
	 * The method calculates amount values for each period
	 *
	 * @param periodIdItemsMap key is period Id, value - is list on NFL items
	 * @param periodIdAmountMap key is period id, value is base amount
	 * @param formula formula relation
	 */
	@TestVisible
	private static void updateAmounts(Map<Id, List<CBNonFinancialItem__c>> periodIdItemsMap, Map<Id, CBAmount__c> periodIdAmountMap, String formula) {
		List<String> formulaArray = formula.split(' '), formulaClone, tmp;
		String key, equation;
		List<CBNonFinancialItem__c> items;
		Decimal amount, calculatedValue;

		for (Id periodId : periodIdItemsMap.keySet()) {
			items = periodIdItemsMap.get(periodId);
			formulaClone = formulaArray.clone();
			for (Integer i = 0; i < FORMULA_KEYS.size(); i++) {
				key = FORMULA_KEYS[i];
				if (!formulaClone.contains(key)) {
					continue;
				}
				amount = items[i].Value__c;
				tmp = new List<String>();
				for (String part : formulaClone) {
					tmp.add(part.equals(key) ? String.valueOf(amount) : part);
				}
				formulaClone = tmp;
			}
			equation = String.join(formulaClone, '');
			calculatedValue = CBMathService.calculateEquation(equation);
			periodIdAmountMap.get(periodId).Value__c = calculatedValue;
		}
	}

}