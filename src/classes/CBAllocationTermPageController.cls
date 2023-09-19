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
public with sharing class CBAllocationTermPageController {

	/**
	 * @param params page parameters
	 *
	 * @return list of Allocation Terms
	 */
	@AuraEnabled
	public static List<CBAllocationTerm__c> getAllocationTermsServer(String crId) {
		String f = ' CBCalculationRule__c =  \'' + crId + '\' ';
		return new CBAllocationTermSelector().getAllocationRuleTerms(f);
	}
	/**
	 * @param aTerms list of allocation terms that need to be saved
	 */
	@AuraEnabled
	public static void saveAllocationTermsServer(List<CBAllocationTerm__c> aTerms) {
		CBAllocationTermService.saveAllocationTerms(aTerms);
	}
	/**
	 * @param aTermId allocation term id that need to be deleted
	 */
	@AuraEnabled
	public static void deleteAllocationTermsServer(String aTermId) {
		Schema.SObjectType sType = ((Id) aTermId).getSobjectType();
		CBSobjectSelector sObjectSelector = new CBSobjectSelector(sType, false)
			.selectFieldsByNames(new List<String>{'Id'})
			.setFilter(' Id = \'' + aTermId + '\' ');
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
			sType
		});
		uow.registerDeleted(sObjectSelector.getSobjects());
		uow.commitWork();
	}

}