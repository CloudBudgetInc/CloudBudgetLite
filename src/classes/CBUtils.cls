/**
Created by Alex JR on 10/23/2021.
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
public with sharing class CBUtils {

	private static String COMA = ',';
	private static Set<String> EXCLUDED_FIELDS = new Set<String>{
			'createddate', 'createdbyid', 'lastmodifieddate', 'systemmodstamp', 'lastvieweddate',
			'lastreferenceddate', 'isdeleted', 'lastmodifiedbyid', 'laststagechangedate', 'lastamountchangedhistoryid', 'lastclosedatechangedhistoryid'
	};
	private String result = '';
	private Map<String, String> params;
	public CBUtils(Map<String, String> params) {
		this.params = params;
	}

	/**
   * @param sObjectName 'CBobj__c'
   * @param additionalSelect additional SELECT fields
   * @return 'Field__c, Field2__c FROM CBObj__c' ....
   */
	public static String getAllSObjectFields(String sObjectName, String additionalSelect) {
		List<String> resultStrList = new List<String>();

		for (String s : getRefinedListOfSObject(sObjectName)) {
			if (resultStrList.size() > 0) {
				resultStrList.add(COMA);
			}
			resultStrList.add(s);
		}
		if (!String.isBlank(additionalSelect)) {
			resultStrList.add(COMA);
			resultStrList.add(additionalSelect);
		}
		resultStrList.add('FROM');
		resultStrList.add(sObjectName);
		return String.join(resultStrList, ' ');
	}

	/**
	 * Function move a record to the recent list
	 */
	@AuraEnabled
	public static void makeItemRecentServer(String recordId) {
		if (recordId == null) {
			return;
		}

		Schema.SObjectType sType = ((Id) recordId).getSObjectType();
		CBSobjectSelector sObjectSelector = new CBSobjectSelector(sType, false)
				.selectFieldsByNames(new List<String>{
						'Id'
				})
				.setFilter(' Id = \'' + recordId + '\' ');
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
				sType
		});
		uow.registerDirty(sObjectSelector.getSobjects());
		uow.commitWork();
	}

	/**
	 * @param sObjectName SObject type name (example cblight__CBModelingRule__c)
	 *
	 * @return Map<String, String> key - fieldName (cb4__Type__c), value - fieldLabel (Type)
	 */
	public static Map<String, String> getFieldLabelsForSObject(String sObjectName) {
		Map<String, String> resultMap = new Map<String, String>();
		for (SObjectField field : getSchemaFieldMap(sObjectName).values()) {
			DescribeFieldResult fieldDesc = field.getDescribe();
			resultMap.put(fieldDesc.getName(), fieldDesc.getLabel());
		}
		return resultMap;
	}

	/**
	 * @param sObjectName SObject type name (example cblight__CBModelingRule__c)
	 *
	 * @return Map<String, Schema.SObjectField> - key : fieldname (lowercase), value : field describe obj
	 */
	public static Map<String, Schema.SObjectField> getSchemaFieldMap(String sObjectName) {
		Map<String, Schema.SObjectField> result = new Map<String, Schema.SObjectField>();

		Schema.SObjectType st = Schema.getGlobalDescribe().get(sObjectName);
		if (st != null) {
			result = st.getDescribe().fields.getMap();
		} else {
			CBLogService.setLog('EXCEPTION', 'CBUtils getSchemaFieldMap ' + sObjectName + ' map', 'No SObjectType was found', null);
			CBLogService.insertLog();
		}
		return result;
	}

	/**
	 * @param sObjectName example 'cblight__CBCube__c'
	 *
	 * @return a list of SObject fields refined form rarely used
	 */
	public static List<String> getRefinedListOfSObject(String sObjectName) {
		List<String> refinedListOfFields = new List<String>();
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(sObjectName)
				.getDescribe().fields.getMap();
		for (String fieldName : objectFields.keySet()) {
			if (EXCLUDED_FIELDS.contains(fieldName)) {
				continue;
			}
			refinedListOfFields.add(fieldName);
		}
		return refinedListOfFields;
	}

	/**
	 * @param idSet Set<Id>: Set of Ids for converting to Set<String>
	 *
	 * @return Set<String>
	 */
	public static Set<String> setIdToSetString(Set<Id> idSet) {
		return idSet == null ? new Set<String>() : new Set<String>((List<String>) new List<Id>(idSet));
	}

	/**
	 * Example:  ' CBModelingRule__c IN ' + CBUtils.getFormattedINQuery(recordIdSet)
	 * @param s set of Ids or some strings for WHERE clause
	 * @return a string like "('xxxx', 'xxxx', 'xxxx' )" for a WHERE clause like 'WHERE Id IN ('xxxx', 'xxxx', 'xxxx' )'
	 */
	public static String getFormattedINQuery(Set<String> s) {
		return s.size() > 0 ? '(\'' + String.join(new List<String>(s), '\', \'') + '\') ' : '';
	}

	/**
	 * Example:  ' CBModelingRule__c IN ' + CBUtils.getFormattedINQuery(recordIdSet)
	 * @param s set of Ids or some strings for WHERE clause
	 * @return a string like "('xxxx', 'xxxx', 'xxxx' )" for a WHERE clause like 'WHERE Id IN ('xxxx', 'xxxx', 'xxxx' )'
	 */
	public static String getFormattedINQuery(Set<Id> s) {
		return s.size() > 0 ? '(\'' + String.join(new List<String>(setIdToSetString(s)), '\', \'') + '\') ' : '';
	}

	/**
	 * The method generates SOQL WHERE query from the page parameters
	 * The first condition is without 'AND'
	 *
	 * @param key (String): page filter key
	 * @param field (String): sObject fields
	 *
	 * @return CBUtils: current object
	 *
	 */
	/*public CBUtils addFilterStr(String key, String field) {
		String val = this.params.get(key);
		if (String.isBlank(val) || (val == 'null')) {
			return this;
		}
		this.result +=
				(this.result.equals('') ? '' : ' AND ') +
						field +
						' = \'' +
						val +
						'\' ';
		return this;
	}*/

	public CBUtils addFilterStr(String keyField) {
		return addFilterStr(keyField, '');
	}

	public CBUtils addFilterStr(String keyField, String parentField) {
		String val = this.params.get(keyField);
		keyField = refineStr(keyField);
		parentField = refineStr(parentField);
		val = refineStr(val);
		if (String.isBlank(val) || (val == 'null')) {
			return this;
		}
		this.result += (this.result.equals('') ? '' : ' AND ') + parentField + keyField + ' = \'' + val + '\' ';
		return this;
	}

	/**
	 * @return String: result SOQL string
	 */
	public String getResult() {
		return this.result;
	}

	/**
	 * @param s
	 *
	 * @return string for database queries with escaped single quotes
	 */
	public static String refineStr(String s) {
		return s == null ? null : String.escapeSingleQuotes(s);
	}

	/**
* @param childObjName (String): sObject name. Example: cblight__CBCube__c
* @param childLookupFieldName (String): sObject lookup field name. Example: cblight__Fund__c
*
* @return string relation name. Example: cblight__CBCubes__r
* @Lookup to User , Group is not supported
*/
	public static String getRelationNameByChildLookup(String childObjName, String childLookupFieldName) {
		if (String.isBlank(childObjName) || String.isBlank(childLookupFieldName)) {
			return null;
		}
		SObjectType childObjType = ((SObject) Type.forName(childObjName).newInstance()).getSObjectType();
		if (childObjType == null) {
			return null;
		}
		SObjectField childLookupField = childObjType.getDescribe().fields.getMap().get(childLookupFieldName);
		if (childLookupField == null) {
			return null;
		}
		String lookupReferenceObjectName;
		for (Schema.SObjectType reference : childLookupField.getDescribe().getReferenceTo()) {
			lookupReferenceObjectName = reference.getDescribe().getName();
			if (String.isBlank(lookupReferenceObjectName)) {
				continue;
			}
			SObjectType lookupObjType = ((SObject) Type.forName(lookupReferenceObjectName).newInstance()).getSObjectType();
			if (lookupObjType == null) {
				continue;
			}
			for (ChildRelationship relation : lookupObjType.getDescribe().getChildRelationships()) {
				if (relation.getChildSObject() == childObjType && relation.getField() == childLookupField) {
					return relation.getRelationshipName();
				}
			}
		}
		return null;
	}
	/**

	* @param parentObjName (String): sObject name
	* @param childObjName (String): sObject name
	*
	* @return string First relation name
	* @Lookup to User , Group is not supported
	*/
	public static String getRelationName(String parentObjName, String childObjName) {
		SObjectType childObjType = ((SObject) Type.forName(childObjName).newInstance()).getSObjectType();
		if (childObjType == null) {
			return null;
		}
		SObjectType parentObjType = ((SObject) Type.forName(parentObjName).newInstance()).getSObjectType();
		if (parentObjType == null) {
			return null;
		}
		for (ChildRelationship relation : parentObjType.getDescribe().getChildRelationships()) {
			if (relation.getChildSObject() == childObjType) {
				return relation.getRelationshipName();
			}
		}
		return null;
	}

	/**

	* @param parentObjName (String): sObject name
	* @param childObjName (String): sObject name
	*	
	* @return string Lookup Field Name for First relation 
	* @Lookup to User , Group is not supported
	*/
	public static String getLookupFieldName(String parentObjName, String childObjName) {
		SObjectType childObjType = ((SObject) Type.forName(childObjName).newInstance()).getSObjectType();
		if (childObjType == null) {
			return null;
		}
		SObjectType parentObjType = ((SObject) Type.forName(parentObjName).newInstance()).getSObjectType();
		if (parentObjType == null) {
			return null;
		}
		for (ChildRelationship relation : parentObjType.getDescribe().getChildRelationships()) {
			if (relation.getChildSObject() == childObjType) {
				return relation.getField().getDescribe().getName();
			}
		}
		return null;
	}

	/**
	*
	* @return List of Standart and Custom sObjet Names with isCreateable privilege
	* @(Standart object must have at list 1 associated record types ) .
	*/
	@AuraEnabled
	public static List<String> getObjectNameStringListServer() {
		List<String> result = new List<String>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Set<String> standardObjects = new Set<String>();
		Set<String> customObjects = new Set<String>();
		for (Schema.SObjectType st : gd.values()) {
			Schema.DescribeSObjectResult dsr = st.getDescribe();
			if (!dsr.isCreateable()) {
				continue;
			}
			if (!dsr.isCustom() && dsr.getRecordTypeInfos().size() > 0) {
				standardObjects.add(dsr.getName());
			} else if (dsr.isCustom()) {
				customObjects.add(dsr.getName());
			}
		}
		result.addAll(new List<String>(customObjects));
		result.addAll(new List<String>(standardObjects));
		return result;
	}

	private static final Set<String> IGNORED_FIELDS = new Set<String>{
			'IsDeleted', 'CreatedDate', 'LastModifiedDate', 'CreatedById', 'LastModifiedById',
			'SystemModstamp', 'LastActivityDate', 'LastViewedDate', 'LastReferencedDate'
	};

	/**
	* Method returns all the fields from needed sObject in for of SO list
	 * @param objectName (String): sObject name
	 * @return List<Object> Object field list
	 */
	@AuraEnabled
	public static List<CBSO> getObjectFieldsSO(String objectName) {
		List<CBSO> result = new List<CBSO>();
		Schema.DescribeSObjectResult[] descResult;
		try {
			descResult = Schema.describeSObjects(new List<String>{
					objectName
			});
		} catch (System.InvalidParameterValueException e) {
			CBLogService.setLog(e, 'CBUtils getObjectFieldsSO ' + objectName);
			CBLogService.insertLog();
			return result;
		}
		Map<String, Schema.SObjectField> descResultFields = descResult[0].fields.getMap();
		for (Schema.SObjectField sf : descResultFields.values()) {
			Schema.DescribeFieldResult dfr = sf.getDescribe();
			if (IGNORED_FIELDS.contains(dfr.getName())) {
				continue;
			}
			List<SObjectType> relations = dfr.getReferenceTo();
			String relSobject;
			if (relations != null && relations.size() > 0) {
				relSobject = relations[0].getDescribe().getName();
			}
			result.add(new CBSO(dfr.getName(), dfr.getLabel(), castTypeToString(dfr.getType()), relSobject));
		}
		result.sort();
		return result;
	}

	/**
	 * Key - sObject Name , value - (key - sObjectField, value - field type)
	 */
	public static Map<String, Map<String, String>> fieldNameToFieldTypeMap { get; set; }

	/**
	 * @param sObjectName the name of the needed sObject. For example "cblight__CBBudgetLine__c"
	 *
	 * @return key - field name, value - field type
	 */
	public static void fillInFieldNameToTypeMap(String sObjectName) {
		if (fieldNameToFieldTypeMap == null) {
			fieldNameToFieldTypeMap = new Map<String, Map<String, String>>();
		}
		if (fieldNameToFieldTypeMap.get(sObjectName) != null) {
			return; // prevent doubling
		}
		Map<String, String> r = new Map<String, String>();
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
		Schema.DisplayType type;
		String name, typeName;
		for (Schema.SObjectField t : objectFields.values()) {
			name = t.getDescribe().getName();
			if (EXCLUDED_FIELDS.contains(name.toLowerCase())) {
				continue;
			}
			type = t.getDescribe().getType();
			typeName = castTypeToString(type);
			r.put(name, typeName);
		}
		fieldNameToFieldTypeMap.put(sObjectName, r);
	}

	public static String getFieldType(String sObjectType, String fieldName) {
		return fieldNameToFieldTypeMap.get(sObjectType).get(fieldName);
	}

	public static Integer getNumberOfRecords(String sObjectName, String filter) {
		try {
			return new CBSobjectSelector(sObjectName, false).countSobjects(filter);
		} catch (Exception e) { // sometimes desired record type may be deleted or unavailable
			return -1;
		}
	}

	/**
	 * @param objectAPIName example: "cblight__CBAccount"
	 *
	 * @return object label example: "CB Account"
	 */
	public static String getObjectLabelFromObjectAPIName(String objectAPIName) {
		try {
			return Schema.getGlobalDescribe().get(objectAPIName).getDescribe().getLabel();
		} catch (Exception e) { // sometimes source of result record may be deleted or unavailable
			return 'N/A';
		}
	}

	/**
	 * @param s the base sObject
	 * @param f the field of the base sObject
	 *
	 * @return the value of the field
	 */
	public static Object getField(SObject s, String f) {
		try {
			return s.get(f);
		} catch (Exception e) {
			throw new CBException(e, 'U->F');
		}

	}
	/**
	* Method puts value to SObject field
	 * @param s - base sObject
	 * @param f - target field
	 * @param v - value
	 */
	public static void putField(SObject s, String f, Object v) {
		try {
			if (s == null) {
				throw new CBException(null, 'Case: SObject can not be null');
			}
			if (f == null) {
				throw new CBException(null, 'Case: Field can not be null');
			}
			s.put(f, v);
		} catch (Exception e) {
			throw new CBException(e, 'CBUtils putField: ' + e.getMessage());
		}
	}

	/**
     * The method returns the value of obj from its field named f
     * @param f field name (for instance: cb4__obj1__r.cb4__obj1__c)
     * @param obj source obj
     *
     * @return the value of obj field
     */
	public static String getFieldValue(String f, SObject obj) {
		if (f == null || f == '') {
			return '';
		}
		List<String> t = f.split('\\.');
		Integer s = t.size();
		try {
			if (s == 1) {
				return (String) obj.get(f);
			} else if (s == 2) {
				return (String) obj.getSobject(t[0]).get(t[1]);
			} else if (s == 3) {
				return (String) obj.getSobject(t[0]).getSobject(t[1]).get(t[2]);
			} else if (s == 4) {
				return (String) obj.getSobject(t[0]).getSobject(t[1]).getSobject(t[2]).get(t[3]);
			}
		} catch (Exception e) {
			return '';
		}
		return '';
	}

	//////// PRIVATE METHODS ////////////
	private static String castTypeToString(Schema.DisplayType inputType) {
		switch on inputType {
			when ID {
				return 'ID';
			}
			when REFERENCE {
				return 'REFERENCE';
			}
			when STRING {
				return 'STRING';
			}
			when TEXTAREA {
				return 'TEXTAREA';
			}
			when BOOLEAN {
				return 'CHECKBOX';
			}
			when PICKLIST {
				return 'PICKLIST';
			}
			When INTEGER {
				return 'INTEGER';
			}
			When CURRENCY {
				return 'CURRENCY';
			}
			When DOUBLE {
				return 'DOUBLE';
			}
			When LONG {
				return 'LONG';
			}
			When DATE {
				return 'DATE';
			}
			When DATETIME {
				return 'DATETIME';
			}
			when else {
				return null;
			}
		}
	}
	//////// PRIVATE METHODS ////////////
}