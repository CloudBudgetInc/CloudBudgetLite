/** 
Copyright (c) 2022, CloudBudget, Inc.
All rights reserved.
Alex JR 13/6/2022
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


public with sharing class CBGanttPageController {

	@AuraEnabled
	public static List<CBBudgetLine__c> getBudgetLinesServer(Map<String, String> params) {
		if (params == null) {
			return null;
		}
		String BLFilter = params.get('complexFilter');
		if (String.isBlank(BLFilter)) {
			BLFilter = new CBUtils(params)
					.addFilterStr('divisionId', 'cblight__CBDivision__c')
					.addFilterStr('accountId', 'cblight__CBAccount__c')
					.addFilterStr('variable1Id', 'cblight__CBVariable1__c')
					.addFilterStr('variable2Id', 'cblight__CBVariable2__c')
					.addFilterStr('variable3Id', 'cblight__CBVariable3__c')
					.addFilterStr('variable4Id', 'cblight__CBVariable4__c')
					.addFilterStr('variable5Id', 'cblight__CBVariable5__c')
					.getResult();
		}
		return new CBBudgetLineSelector().getBudgetLinesByFilter(BLFilter, null);
	}

	@AuraEnabled
	public static List<cblight__CBPeriod__c> getPeriodsServer() {
		return new CBPeriodSelector().getPeriods(null);
	}


	@AuraEnabled
	public static Map<String, List<CBSO>> getSelectOptionsServer() {
		return CBBudgetLinePageController.getSelectOptionsServer();
	}


}