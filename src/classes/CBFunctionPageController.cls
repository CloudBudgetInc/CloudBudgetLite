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
public with sharing class CBFunctionPageController {

	/**
	 * @return list of available functions
	 */
	@AuraEnabled
	public static Map<String, List<CBSO>> getFunctionSOServer() {
		Map<String, List<CBSO>> r = new CBSOService()
				.addSOList('functionSO', 'cblight__CBFunction__c', new List<String>{
						'Name'
				}, null, null, 'Name')
				.getResult();
		return r;
	}

	@AuraEnabled
	public static List<CBFunction__c> getFunctionsServer(String type) {
		return new CBFunctionSelector().getFunctions('cblight__Type__c = \'' + type + '\'');
	}

	@AuraEnabled
	public static List<CBFunction__c> getFunctionByIdServer(String funcId) {
		if (funcId!=null && funcId instanceOf Id) {
			return new CBFunctionSelector().getFunctions('Id = \'' + funcId + '\'');
		} else {
			return new List<CBFunction__c>();
		}
	}

	@AuraEnabled
	public static void saveFunctionServer(CBFunction__c newFunction) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBFunction__c.SObjectType }
		);
		uow.registerNew(newFunction);
		uow.commitWork();
	}

	/**
	 * Delete one Function by Id
	 */
	@AuraEnabled
	public static void deleteFunctionServer(Id functionId) {
		List<CBFunction__c> recordList = [SELECT Id FROM CBFunction__c WHERE Id = :functionId WITH SECURITY_ENFORCED];
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBFunction__c.SObjectType }
		);
		uow.registerDeleted(recordList);
		uow.commitWork();
	}
}