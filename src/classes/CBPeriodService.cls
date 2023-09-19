/**
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

The service class BudgetYear__c and CBPeriod__c
*/
public with sharing class CBPeriodService {
	private static Map<String, CBBudgetYear__c> yearStartToBudgetYear {
		get {
			if (yearStartToBudgetYear == null) {
				yearStartToBudgetYear = new Map<String, CBBudgetYear__c>();
				for (CBBudgetYear__c y : new CBBudgetYearSelector().getBudgetYears(null)) {
					yearStartToBudgetYear.put('' + y.Start__c.year(), y);
				}
			}
			return yearStartToBudgetYear;
		}
		set;
	}
	private static Map<String, CBPeriod__c> monthStartToPeriod {
		get {
			if (monthStartToPeriod == null) {
				monthStartToPeriod = new Map<String, CBPeriod__c>();
				for (CBPeriod__c p : new CBPeriodSelector().getPeriods(null)) {
					monthStartToPeriod.put('' + p.Start__c.year() + '' + p.Start__c.month(), p);
				}
			}
			return monthStartToPeriod;
		}
		set;
	}
	/**
	 * @param bfy (CBBudgetYear__c): page filter key
	 * @param shift (Integer): shift number year
	 * @return CBBudgetYear__c shifted BudgetYear
	 */
	public static CBBudgetYear__c shiftBudgetYear(CBBudgetYear__c bfy, Integer shift) {
		if (bfy.Start__c == null) {
			return null;
		}
		String newBudgetYearStart = '' + (bfy.Start__c.year() + shift);
		return yearStartToBudgetYear.get(newBudgetYearStart);
	}

	/**
	 * @param period (CBPeriod__c):
	 * @param shift (Integer): shift number year
	 * @return CBPeriod__c shifted period
	 */
	public static CBPeriod__c shiftPeriod(CBPeriod__c period, Integer shift) {
		if (period.Start__c == null) {
			return null;
		}
		String newPeriodMonthStart = '' + (period.Start__c.year() + shift) + period.Start__c.month();
		return monthStartToPeriod.get(newPeriodMonthStart);
	}
}