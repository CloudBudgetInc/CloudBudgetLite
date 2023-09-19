/**
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

public with sharing class CBMetadataService {

	/**
	 * @param resultSObjectName <b>Required.</b> The Name of the SObject in which the field of type "Lookup" will be added.
	 * @param sourceSObjectName <b>Required.</b> The Name of the SObject for which the field of type "Lookup" will be created in the <b>resultSObject</b>.
	 * @param lookupFieldName   The Name of the created Lookup field. (If <b>NULL</b> then the <b>sourceSObjectName</b> is used).
	 * @param lookupFieldLabel  The Label of the created Lookup field.(If <b>NULL</b> then the <b>sourceSObjectName</b> is used).
	 */
	/*public static void createLookupField(String resultSObjectName, String sourceSObjectName, String lookupFieldName, String lookupFieldLabel) {
		if (String.isBlank(resultSObjectName) || String.isBlank(sourceSObjectName)) throw new CBMetadataServiceException('Missing required arguments');
		lookupFieldName = String.isBlank(lookupFieldName) ? sourceSObjectName : lookupFieldName;
		lookupFieldLabel = String.isBlank(lookupFieldLabel) ? sourceSObjectName : lookupFieldName;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField customField = new MetadataService.CustomField();
		customField.fullName = resultSObjectName + '.' + lookupFieldName + '__c';
		customField.label = lookupFieldLabel;
		customField.type_x = 'Lookup';
		customField.relationshipLabel = lookupFieldLabel + 's';
		customField.relationshipName = lookupFieldLabel + 's';
		customField.referenceTo = sourceSObjectName;
		List<MetadataService.SaveResult> results =
				service.createMetadata(
						new MetadataService.Metadata[]{
								customField
						});
		handleSaveResults(results[0]);
	}*/

	/**
	 * @param SObjectName <b>Required.</b> The Name of the SObject in which the formula field will be added.
	 * @param fieldName   <b>Required.</b> The Name of the created formula field.
	 * @param fieldLabel  The Label of the created formula field.(If <b>NULL</b> then the <b>fieldName</b> is used).
	 * @param fieldType   <b>Required.</b> (Checkbox, Date, Date/Time, Number, Percent, Text, Time)
	 * @param formula     <b>Required.</b> exmp. "TODAY()"
	 */
	/*public static void createFormulaField(String SObjectName, String fieldName, String fieldLabel, String fieldType, String formula) {
		if (String.isBlank(SObjectName) || String.isBlank(fieldName) || String.isBlank(fieldType) || String.isBlank(formula)) throw new CBMetadataServiceException('Missing required arguments');
		fieldLabel = String.isBlank(fieldLabel) ? fieldName : fieldLabel;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField customField = new MetadataService.CustomField();
		customField.fullName = SObjectName + '.' + fieldName + '__c';
		customField.label = fieldLabel;
		customField.type_x = fieldType;
		customField.formula = formula;
		List<MetadataService.SaveResult> results =
				service.createMetadata(
						new MetadataService.Metadata[]{
								customField
						});
		handleSaveResults(results[0]);
	}*/

	/**
	 * @param SObjectName <b>Required.</b> The Name of the SObject in which the text field will be added.
	 * @param fieldName   <b>Required.</b> The Name of the created text field.
	 * @param fieldLabel  The Label of the created text field. (If <b>NULL</b> then the <b>fieldName</b> is used).
	 * @param length      <b>Required.</b> Integer (Should not be <b>NULL</b> and <b>not equals 0</b>)
	 */
	/*public static void createTextField(String SObjectName, String fieldName, String fieldLabel, Integer length) {
		if (String.isBlank(SObjectName) || String.isBlank(fieldName) || length == null || length == 0) throw new CBMetadataServiceException('Missing required arguments');
		fieldLabel = String.isBlank(fieldLabel) ? fieldName : fieldLabel;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField customField = new MetadataService.CustomField();
		customField.fullName = SObjectName + '.' + fieldName + '__c';
		customField.label = fieldLabel;
		customField.type_x = 'Text';
		customField.length = length;
		List<MetadataService.SaveResult> results =
				service.createMetadata(
						new MetadataService.Metadata[]{
								customField
						});
		handleSaveResults(results[0]);
	}*/

	/**
	 * @param SObjectName <b>Required.</b> The Name of the SObject in which the text field will be added.
	 * @param fieldName   <b>Required.</b> The Name of the created text field.
	 * @param fieldLabel  The Label of the created text field. (If <b>NULL</b> then the <b>fieldName</b> is used).
	 * @param length      <b>Required.</b> Integer (Should not be <b>NULL</b> and <b>not equals 0</b>)
	 */
	/*public static void createLongTextAreaField(String SObjectName, String fieldName, String fieldLabel, Integer length) {
		if (String.isBlank(SObjectName) || String.isBlank(fieldName) || length == null || length == 0) throw new CBMetadataServiceException('Missing required arguments');
		fieldLabel = String.isBlank(fieldLabel) ? fieldName : fieldLabel;
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField customField = new MetadataService.CustomField();
		customField.fullName = SObjectName + '.' + fieldName + '__c';
		customField.label = fieldLabel;
		customField.type_x = 'LongTextArea';
		customField.length = length;
		customField.visibleLines = 3;
		List<MetadataService.SaveResult> results =
				service.createMetadata(
						new MetadataService.Metadata[]{
								customField
						});
		handleSaveResults(results[0]);
	}

	/**
	 * @param SObjectName <b>Required.</b> The Name of the SObject.
	 * @param fieldName   <b>Required.</b> The Name of the field to delete.
	 */
	/*public static void deleteField(String SObjectName, String fieldName) {
		if (String.isBlank(SObjectName) || String.isBlank(fieldName)) throw new CBMetadataServiceException('Missing required arguments');
		MetadataService.MetadataPort service = createService();
		List<MetadataService.DeleteResult> results =
				service.deleteMetadata(
						'CustomField', new String[]{
								SObjectName + '.' + fieldName + '__c'
						});
		handleDeleteResults(results[0]);
	}*/

	/*public static MetadataService.MetadataPort createService() {
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
		return service;
	}

	public class CBMetadataServiceException extends Exception {
	}*/
	/**
	 * Example helper method to interpret a SaveResult, throws an exception if errors are found
	 **/
	/*public static void handleSaveResults(MetadataService.SaveResult saveResult) {
		// Nothing to see?
		if (saveResult == null || saveResult.success) {
			return;
		}
		// Construct error message and throw an exception
		if (saveResult.errors != null) {
			List<String> messages = new List<String>();
			messages.add(
					(saveResult.errors.size() == 1 ? 'Error ' : 'Errors ') +
							'Occurred processing component ' + saveResult.fullName + '.');
			for (MetadataService.Error error : saveResult.errors)
				messages.add(
						error.message + ' (' + error.statusCode + ').' +
								(error.fields != null && error.fields.size() > 0 ?
										' Fields ' + String.join(error.fields, ',') + '.' : ''));
			if (messages.size() > 0)
				throw new CBMetadataServiceException(String.join(messages, ' '));
		}
		if (!saveResult.success)
			throw new CBMetadataServiceException('Request failed with no specified error.');
	}*/

	/**
	 * Example helper method to interpret a SaveResult, throws an exception if errors are found
	 **/
	/*public static void handleDeleteResults(MetadataService.DeleteResult deleteResult) {
		// Nothing to see?
		if (deleteResult == null || deleteResult.success)
			return;
		// Construct error message and throw an exception
		if (deleteResult.errors != null) {
			List<String> messages = new List<String>();
			messages.add(
					(deleteResult.errors.size() == 1 ? 'Error ' : 'Errors ') +
							'occurred processing component ' + deleteResult.fullName + '.');
			for (MetadataService.Error error : deleteResult.errors)
				messages.add(
						error.message + ' (' + error.statusCode + ').' +
								(error.fields != null && error.fields.size() > 0 ?
										' Fields ' + String.join(error.fields, ',') + '.' : ''));
			if (messages.size() > 0)
				throw new CBMetadataServiceException(String.join(messages, ' '));
		}
		if (!deleteResult.success)
			throw new CBMetadataServiceException('Request failed with no specified error.');
	}*/

	/**
	 * Example helper method to interpret a UpsertResult, throws an exception if errors are found
	 **/
	/*public static void handleUpsertResults(MetadataService.UpsertResult upsertResult) {
		// Nothing to see?
		if (upsertResult == null || upsertResult.success)
			return;
		// Construct error message and throw an exception
		if (upsertResult.errors != null) {
			List<String> messages = new List<String>();
			messages.add(
					(upsertResult.errors.size() == 1 ? 'Error ' : 'Errors ') +
							'Occurred processing component ' + upsertResult.fullName + '.');
			for (MetadataService.Error error : upsertResult.errors)
				messages.add(
						error.message + ' (' + error.statusCode + ').' +
								(error.fields != null && error.fields.size() > 0 ?
										' Fields ' + String.join(error.fields, ',') + '.' : ''));
			if (messages.size() > 0)
				throw new CBMetadataServiceException(String.join(messages, ' '));
		}
		if (!upsertResult.success)
			throw new CBMetadataServiceException('Request failed with no specified error.');
	}*/
}