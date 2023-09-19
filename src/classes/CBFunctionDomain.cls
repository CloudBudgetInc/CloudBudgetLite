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

public with sharing class CBFunctionDomain extends fflib_SObjectDomain {
	public CBFunctionDomain(List<CBFunction__c> sObjectList) {
		super(sObjectList);
	}
	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBFunctionDomain(sObjectList);
		}
	}
	public override void onAfterInsert() {
		updateFunctionsTitle((List<CBFunction__c>) Records);
	}

	/**
	 * Prevent duplicating
	 */
	@TestVisible
	private static void updateFunctionsTitle(List<CBFunction__c> records) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType>{
				CBFunction__c.SObjectType
			}
		);
		Set<Id> functionIds = new Set<Id>();
		for (CBFunction__c f : records) {
			if (String.isEmpty(f.Title__c)) {
				functionIds.add(f.Id);
			}
		}
		for (CBFunction__c f : [
				SELECT CBDivision__r.Name, CBAccount__r.Name, Index__c, Type__c,
						NFL1__c, NFL2__c, NFL3__c, NFL4__c, NFL5__c, NFLFormula__c,
						CBVariable1__c,CBVariable2__c,CBVariable3__c,CBVariable4__c,CBVariable5__c,
						CBVariable1__r.Name,CBVariable2__r.Name,CBVariable3__r.Name,CBVariable4__r.Name,CBVariable5__r.Name
				FROM CBFunction__c
				WHERE Id IN:functionIds
				WITH SECURITY_ENFORCED
		]) {
			if (f.Type__c == 'Variable') {
				f.Title__c = '#' + f.Index__c + '/'
						+ (f.CBDivision__c == null ? '' : '/' + f.CBDivision__r.Name)
						+ (f.CBAccount__c == null ? '' : '/' + f.CBAccount__r.Name)
						+ (f.CBVariable1__c == null ? '' : '/' + f.CBVariable1__r.Name)
						+ (f.CBVariable2__c == null ? '' : '/' + f.CBVariable2__r.Name)
						+ (f.CBVariable3__c == null ? '' : '/' + f.CBVariable3__r.Name)
						+ (f.CBVariable4__c == null ? '' : '/' + f.CBVariable4__r.Name)
						+ (f.CBVariable5__c == null ? '' : '/' + f.CBVariable5__r.Name);
			}
			if (f.Type__c == 'NFL') {
				f.Title__c = '#' + f.Index__c + '/' + f.NFLFormula__c;
			}
			uow.registerDirty(f);
		}
		uow.commitWork();
	}
}