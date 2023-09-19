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
public with sharing class CBMappingService {

	public static CBMapping__c upsertMapping(CBMapping__c mapping) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBMapping__c.SObjectType }
		);
		uow.registerUpsert(mapping);
		uow.commitWork();
		return mapping;
	}

	/**
	 * Class factory
	 *
	 * @param type "accounts" || "divisions" || "periods" ....
	 */
	public static CBMappingInterface getMappingClass(String type) {
		switch on type {
			when 'accounts' {
				return new CBInitWizardService.CBMapAccounts();
			}
			when 'divisions' {
				return new CBInitWizardService.CBMapDivisions();
			}
			when 'periods' {
				return new CBInitWizardService.CBMapPeriods();
			}
			when 'variables1' {
				return new CBInitWizardService.CBMapVariables(1);
			}
			when 'variables2' {
				return new CBInitWizardService.CBMapVariables(2);
			}
			when 'variables3' {
				return new CBInitWizardService.CBMapVariables(3);
			}
			when 'variables4' {
				return new CBInitWizardService.CBMapVariables(4);
			}
			when 'variables5' {
				return new CBInitWizardService.CBMapVariables(5);
			}
		}
		return null;
	}

}