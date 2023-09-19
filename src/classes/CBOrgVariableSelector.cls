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


public with sharing class CBOrgVariableSelector {

	/**
	 * This method does not use FF libs because the fields will not be known in advance
	 *
	 * @return single CBOrgVariable object (current org settings) with all custom fields
	 */
	@AuraEnabled
	public static CBOrgVariable__c getOrgVariableServer() {
		List<String> fieldNames = CBUtils.getRefinedListOfSObject('cblight__CBOrgVariable__c');
		List<SObject> orgVars = new CBSobjectSelector('cblight__CBOrgVariable__c', false).selectFieldsByNames(fieldNames).getSobjects();
		return orgVars.isEmpty()? null: (CBOrgVariable__c) orgVars[0];
	}

	@AuraEnabled
	public static List<CBSO> getOrgVariableStructureServer() {
		return cblight.CBUtils.getObjectFieldsSO('cblight__CBOrgVariable__c');
	}

}