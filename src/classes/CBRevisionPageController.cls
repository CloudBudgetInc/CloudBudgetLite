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


public with sharing class CBRevisionPageController {

	
	/**
	 * The method to get list of BL history
	 *
	 * @param parentId - BL Id
	 *
	 * @return list of BL History records
	 */
	@AuraEnabled
	public static List<cblight__CBBudgetLine__History> getBudgetLineHistoryByParentId(String parentId) {
		return new CBBudgetLineHistorySelector().getCBBudgetLineHistoryByFilter('ParentId = \'' + parentId + '\'');
	}

	/**
	 * The method to get list of amounts history
	 *
	 * @param budgetLineId - BL Id
	 *
	 * @return list of Amount History records or null
	 */
	@AuraEnabled
	public static List<cblight__CBAmount__History> getAmountHistoryByParentId(String budgetLineId) {
		List <cblight__CBAmount__c> amounts = [SELECT Id FROM cblight__CBAmount__c WHERE cblight__CBBudgetLine__c =: budgetLineId WITH SECURITY_ENFORCED];
		if (amounts.isEmpty()) return null;
			String parentId = '';
			for (cblight__CBAmount__c amount : amounts) {
				parentId = parentId + '\'' + amount.Id + '\',';
			}
			parentId = parentId.left(parentId.length()-1);
			return new CBAmountHistorySelector().getAmountHistoryByFilter('ParentId IN (' + parentId +')' );
	}


}