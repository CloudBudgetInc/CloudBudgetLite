/** 
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

 */
public with sharing class CBModelingRuleDefaultValueService {

	/**
	 * The method detects the name of sObject in lookup using the base sObject name and its field
	 *
	 * @param sObjectName the name of the base sObject like AcctSeed__Financial_Cube__c
	 * @param sObjectField the name of its field like AcctSeed__GL_Account_Variable_1__c
	 *
	 * @return list of available records to take an Id for Modeling Rule default line
	 */
	public static List<CBSO> getDefaultValueOptions(String sObjectName, String sObjectField) {
		List<CBSO> r = new List<CBSO>();
		SObjectType childObjType = ((SObject) Type.forName(sObjectName).newInstance()).getSObjectType();
		SObjectField childLookupField = childObjType.getDescribe().fields.getMap().get(sObjectField);
		Schema.SObjectType sObjectType = childLookupField.getDescribe().getReferenceTo()[0];
		String sObjectTypeString = String.valueOf(sObjectType);
		CBSobjectSelector sobjSel = new CBSobjectSelector(SObjectName, false)
				.selectFieldsByNames(new List<String>{'Id', 'Name'})
				.setOrder('Name', null);
		List<SObject> sList = sobjSel.getSobjects();
		for (sObject s : sList) {
			r.add(new CBSO(s.Id, (String) s.get('Name')));
		}
		return r;
	}

}