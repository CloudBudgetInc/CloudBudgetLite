/**
Created by Alex Pigarev on 08/05/2022.
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
public inherited sharing class CBFilesUploaderPageController {

	/**
	 * @param idParent (Id): Record Id to which files will be attached
	 * @param strFileName (String): file name
	 * @param base64Data (String): file content encoded as a valid component of a Uniform Resource Identifier (URI)
	 *
	 * @return ContentVersion: saved file data
	 */
	@AuraEnabled
	public static ContentVersion saveFileServer(Id idParent, String strFileName, String base64Data) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { ContentVersion.SObjectType }
		);

		// Decoding base64Data
		base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

		// inserting file
		ContentVersion cv = new ContentVersion();
		cv.Title = strFileName;
		cv.PathOnClient = '/' + strFileName;
		cv.FirstPublishLocationId = idParent;
		cv.VersionData = EncodingUtil.base64Decode(base64Data);
		cv.IsMajorVersion = true;
		uow.registerNew(cv);
		uow.commitWork();
		return cv;
	}

	/**
	 * @param idParent (Id): Record Id to which files are attached
	 *
	 * @return List<ContentVersion>: list of attached files
	 */
	@AuraEnabled
	public static List<ContentVersion> getRelatedFilesServer(Id idParent) {
		List<Id> lstConDocs = new List<Id>();
		for (ContentDocumentLink cntLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :idParent WITH SECURITY_ENFORCED]) {
			lstConDocs.add(cntLink.ContentDocumentId);
		}
		if (!lstConDocs.isEmpty()) {
			return [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :lstConDocs WITH SECURITY_ENFORCED];
		} else {
			return null;
		}
	}

	/**
	 * @param fileId (Id): Id of the selected attached file
	 */
	@AuraEnabled
	public static void deleteFileServer(String fileId) {
		fileId = CBUtils.refineStr(fileId);
		Schema.SObjectType sobjectType = ((Id) fileId).getSObjectType();
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { sobjectType }
		);
		CBSobjectSelector sObjectSelector = new CBSobjectSelector(sobjectType, false).selectFieldsByNames(new List<String>{'Id'});
		uow.registerDeleted(sObjectSelector.getSobjects('Id = \'' + fileId + '\'')[0]);
		uow.commitWork();
	}
}