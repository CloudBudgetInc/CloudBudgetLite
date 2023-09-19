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

public with sharing class CBClusterRulePageController {
	/**
	 * @param recordId Cluster Rule Id
	 *
	 * @return needed Object Cluster Rule
	 */
	@AuraEnabled
	public static CBClusterRule__c getCBClusterRuleServer(String recordId) {
		return new CBClusterRuleSelector().getClusterRules(recordId)[0];
	}

	/**
	 * @param sObjectName example 'cblight__CBBudgetLine__c'
	 *
	 * @return a list of SObject fields refined form rarely used
	 */
	@AuraEnabled
	public static List<CBSO> getBLFieldsSOServer() {

		return new List<CBSO>(CBUtils.getObjectFieldsSO('cblight__CBBudgetLine__c'));
	}

	/**
	 * @param CRRecord record to update
	 *
	 */
	@AuraEnabled
	public static void saveClusterLevelsToServer(CBClusterRule__c CRRecord) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBClusterRule__c.SObjectType }
		);
		uow.registerUpsert(CRRecord);
		uow.commitWork();
	}

	/**
	 * @param CRRecord example 'cblight__CBBudgetLine__c'
	 *
	 */
	@AuraEnabled
	public static void deleteClusterRuleFromServer(CBClusterRule__c CRRecord) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBClusterRule__c.SObjectType }
		);
		uow.registerDeleted(CRRecord);
		uow.commitWork();
	}
}