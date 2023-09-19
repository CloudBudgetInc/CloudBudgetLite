/**
 Created by Vlad L on 01/16/2023.
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

 This class provides methods for CBBExcelMirror component
 */
public with sharing class CBExcelMirrorPageController {
	/**
	 * Delete specified list of Ids
	 */
	@AuraEnabled
	public static void deleteBudgetLinesServer(Id[] budgetLineIds) {
		Set<Id> blIdSet = new Set<Id>(budgetLineIds);
		List<CBBudgetLine__c> recordList = [SELECT Id FROM CBBudgetLine__c WHERE Id IN:blIdSet WITH SECURITY_ENFORCED];
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBBudgetLine__c.SObjectType }
		);
		uow.registerDeleted(recordList);
		uow.commitWork();
	}

	/**
	 * @return Map<String, List<CBSO>>: List of available selectoptions for Excel Service Page
	 */
	@AuraEnabled
	public static Map<String, List<CBSO>> getSelectOptionsServer() {
		Map<String, List<CBSO>> r = new CBSOService()
				.addSOList('divisionSO', 'cblight__CBDivision__c', new List<String>{
						'Name'
				}, null, null,'Name')
				.addSOList('AccountTypeSO', 'cblight__CBAccountType__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.addSOList('AccountSO', 'cblight__CBAccount__c', new List<String>{
					'cblight__CBAccountType__c','Name'
				},' ', null,'Name')
				.addSOList('Var1SO', 'cblight__CBVariable1__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.addSOList('Var2SO', 'cblight__CBVariable2__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.addSOList('Var3SO', 'cblight__CBVariable3__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.addSOList('Var4SO', 'cblight__CBVariable4__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.addSOList('Var5SO', 'cblight__CBVariable5__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.addSOList('FuncSO', 'cblight__CBFunction__c', new List<String>{
					'Title__c'
				}, null, null, 'Name')
				.addSOList('LayerSO', 'cblight__CBLayer__c', new List<String>{
					'Name'
				}, null, null, 'Name')
				.getResult();

		return r;
	}


	/**
	 * The method saves Budget Lines , amounts, NFL Lines and items
	 * @param budgetLines
	 */
	@AuraEnabled
	public static String saveBudgetLinesWithNFLForExcelServer(List<CBExcelMirrorService.BLWrapper> budgetLines, String byId) {
			return new CBExcelMirrorService().saveBudgetLinesWithNFL(byId, budgetLines, null);
	}

	/**
	 * @param idsFromExcel String : List of BL Ids
	 *
	 * @return List<CBBudgetLine__c>: List of available budget lines
	 */
	@AuraEnabled
	public static List<CBBudgetLine__c> getBLForExcelServer(Id[] idsFromExcel) {
		if (idsFromExcel ==null || (idsFromExcel.size()==0)) {
			return new List<CBBudgetLine__c> ();
		}
		String BLFilter = CBExcelMirrorService.getFilterByBudgetLineIdsForExcel(idsFromExcel);
		return new CBBudgetLineSelector().getBudgetLinesByFilter(BLFilter, '');
	}

	/**
	 * @param listOfNFLId String : List of NFL Id
	 *
	 * @return List<CBNonFinancialLibrary__c>: List of NFL
	 */
	@AuraEnabled
	public static List<CBNonFinancialLibrary__c> getListOfNFL(Id[] listOfNFLId, String idOfBudgetYear) {
		if (listOfNFLId ==null || (listOfNFLId.size()==0)) {
			return new List<CBNonFinancialLibrary__c> ();
		}
		String NFLFilter = CBExcelMirrorService.getFilterByBudgetLineIdsForExcel(listOfNFLId);
		return new CBNonFinancialLibrarySelector().getNonFinancialLibrariesByFilter(NFLFilter, 'cblight__CBBudgetYear__c=\''+idOfBudgetYear.left(15) +'\'');
	}

}