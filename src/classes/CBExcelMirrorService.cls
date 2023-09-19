/**
 Created by Vlad L on 09/20/2022.
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

 This class provides methods for CBExcelMirror component
 */


public with sharing class CBExcelMirrorService {
    public Static Boolean blockAfterInsertNFLTRigger=false;
	public Static String byId;
	/**
	 * The method attach items to NFL
	 *
	 * @param nfl
	 * @param items
	 * @param uow
	 */
	public void attachItemsToNFL(cblight__CBNonFinancialLibrary__c nfl,List<cblight__CBNonFinancialItem__c> items,fflib_ISObjectUnitOfWork uow){
		uow.registerUpsert(nfl);
		for (cblight__CBNonFinancialItem__c item : items){
			uow.registerUpsert(item);
			uow.registerRelationship(item, cblight__CBNonFinancialItem__c.cblight__NonFinancialLibrary__c, nfl);
		}
		return;
	}

	/**
	 * The method attach NFL to Budget Line
	 *
	 * @param budgetLine
	 * @param nfl
	 * @param relatedToField
	 * @param uow
	 */
	public void attachNFlToBL(CBBudgetLine__c budgetLine,cblight__CBNonFinancialLibrary__c nfl,Schema.sObjectField relatedToField,fflib_ISObjectUnitOfWork uow){
		uow.registerRelationship(budgetLine,  relatedToField , nfl);
		return;
	}

	public class BLWrapper{
		@AuraEnabled
		public CBBudgetLine__c budgetLine {get;set;}
		@AuraEnabled
		public List<CBAmount__c> amounts {get;set;}
		@AuraEnabled
		public CBNonFinancialLibrary__c nfl1 {get;set;}
		@AuraEnabled
		public CBNonFinancialLibrary__c nfl2 {get;set;}
		@AuraEnabled
		public List<CBNonFinancialItem__c> nfl1Items {get;set;}
		@AuraEnabled
		public List<CBNonFinancialItem__c> nfl2Items {get;set;}
	}

	/**
	 * The method saves Budget Lines , amounts, NFL Lines and items
	 * @param List BLWrapper
	 * @param uow
	 */
	public String saveBudgetLinesWithNFL (String byId, List<BLWrapper> wrapperList,fflib_ISObjectUnitOfWork uow){
		if (wrapperList==null) {return 'Case 1';}
		if (wrapperList.size()==0) {return 'Case 2';}
		CBExcelMirrorService.blockAfterInsertNFLTRigger=true;
		CBExcelMirrorService.byId = byId;
		if (uow == null){
			uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{ cblight__CBNonFinancialLibrary__c.sObjectType,
				cblight__CBBudgetLine__c.sObjectType, cblight__CBAmount__c.sObjectType,cblight__CBNonFinancialItem__c.sObjectType });
		}
		for(BLWrapper wrapper:wrapperList){
			if (wrapper.nfl1Items !=null && wrapper.nfl1 != null) {attachItemsToNFL(wrapper.nfl1,wrapper.nfl1Items,uow);}
			if (wrapper.nfl2Items !=null && wrapper.nfl2 != null) {attachItemsToNFL(wrapper.nfl2,wrapper.nfl2Items,uow);}
			uow.registerUpsert(wrapper.budgetLine);
			if (wrapper.nfl1 !=null) {attachNFlToBL(wrapper.budgetLine,wrapper.nfl1,cblight__CBBudgetLine__c.cblight__NFL1__c,uow);}
			if (wrapper.nfl2 !=null) {attachNFlToBL(wrapper.budgetLine,wrapper.nfl2,cblight__CBBudgetLine__c.cblight__NFL2__c,uow);}
			for (CBAmount__c amount : wrapper.amounts){
				uow.registerUpsert(amount);
				uow.registerRelationship(amount, cblight__CBAmount__c.cblight__CBBudgetLine__c, wrapper.budgetLine);
			}
		}
		uow.commitWork();
		return 'Ok';
	}

	/**
	 * The method generate part of query
	 *
	 * @param param String List of bl Ids separated by :
	 *
	 * @return part of SOQL query filtering only BL by List of Ids
	 */
	public static String getFilterByBudgetLineIdsForExcel(Id[] params) {
		try {
			Set<Id> blIdSet = new Set<Id>();
			for (Id oneId : params) {
				blIdSet.add(oneId);
			}
			String filter= blIdSet.size() > 0 ? ' Id IN ' + CBUtils.getFormattedINQuery(blIdSet) : '';
			return filter;
		} catch (Exception e) {
			return '';
		}
	}

}