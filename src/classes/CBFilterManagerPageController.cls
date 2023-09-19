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

The util class for common functions
 */

public with sharing class CBFilterManagerPageController {

	/**
	 * @param Ids List of any SObjects Ids (Limit is 100 SObject Types). It can be 1000 Ids for 1 SObject Type, or 100 Ids for 100 different SObject Types.
	 * @param sObjectName SObject type name (example cblight__CBModelingRule__c)
	 *
	 * @return Map<String,String> , stores Name of records by their Ids and field labels by their name
	 */
	@AuraEnabled
	public static Map<String, String> getIdToNamesAndFieldLabelsMapServer(List<String> Ids, String sObjectName) {
		Map<String, String> resultMap = new Map<String, String>();
		try {
			if (!Ids.isEmpty()) {
				resultMap.putAll(getIdToNamesMapServer(Ids));
			}
			if (sObjectName != null) {
				resultMap.putAll(CBUtils.getFieldLabelsForSObject(sObjectName));
			}
			return resultMap;
		} catch (Exception e) {
			return resultMap;
		}
	}

	/**
	 * @param sObjectName SObject type name (example cblight__CBModelingRule__c)
	 *
	 * @return List of Formula fields of SObject
	 */
	@AuraEnabled
	public static List<String> getAllSObjectFormulaFieldsListServer(String sObjectName) {
		List<String> formulaFieldNames = new List<String>();
		for (SObjectField field : CBUtils.getSchemaFieldMap(sObjectName).values()) {
			DescribeFieldResult fieldDesc = field.getDescribe();
			if (fieldDesc.isCalculated()) {
				formulaFieldNames.add(fieldDesc.getName());
			}
		}
		return formulaFieldNames;
	}

	/**
	 * @param Ids List of any SObjects Ids (Limit is 100 SObject Types). It can be 1000 Ids for 1 SObject Type, or 100 Ids for 100 different SObject Types.
	 *
	 * @return Map<String,String> , stores Name of records by their Ids
	 */
	@AuraEnabled
	public static Map<String, String> getIdToNamesMapServer(List<String> Ids) {
		Set<String> sIds = new Set<String>(Ids);
		Map<String, String> resultMap = new Map<String, String>();
		return resultMap;
	}
}