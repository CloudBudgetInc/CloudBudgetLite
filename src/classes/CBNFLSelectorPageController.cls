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
public with sharing class CBNFLSelectorPageController {

	/**
	 * returns list of NFL by string name filter and layer
	 * 
	 */
	@AuraEnabled
	public static List<CBNonFinancialLibrary__c> getFilteredNFLServer(String filterString, CBLayer__c layer) {
		filterString = CBUtils.refineStr(filterString);
		String filter = 'cblight__Type__c != \'Custom\' AND cblight__Layer__c = \'' + layer.Id + '\' AND Name LIKE \'%' + filterString + '%\'';
		return new CBNonFinancialLibrarySelector().setLimit(100).getNonFinancialLibrariesByFilter(filter, null);
	}
	/**
	 * returns list of layers
	 */
	@AuraEnabled
	public static List<CBLayer__c> getLayersServer(){
		try {
			return (List<CBLayer__c>) new CBSobjectSelector(CBLayer__c.sObjectType, false)
			.selectFields(new Set<Schema.SObjectField>{CBLayer__c.Id, CBLayer__c.Name, CBLayer__c.Unit__c})
			.getSobjects();
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * returns list of latest NFLs by layer and integer limit
	 */
	@AuraEnabled
	public static List<CBNonFinancialLibrary__c> getLatestNFLServer(CBLayer__c layer, Integer amount){
		try {
			if (layer == null || amount == null) {
				return null;
			}
			String filter = 'cblight__Type__c != \'Custom\' AND cblight__Layer__c = \'' + layer.Id + '\'';
			CBNonFinancialLibrarySelector sel = new CBNonFinancialLibrarySelector().setLimit(amount);
			return sel.getNonFinancialLibrariesByFilter(filter, null);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}