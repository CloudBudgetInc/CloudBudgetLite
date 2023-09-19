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

Controller for the helping component in Init Wizard to compare native and source sObjects
 */

public with sharing class CBInitWizardReportPageController {

	public static Integer coincideCounter = 0;

	/**
	 * @param mappingType is type of mapping "accounts"
	 * @return wrappers to make a report
	 */
	@AuraEnabled
	public static List<CBInitWizardReportPageController.CBMappingReportWrapper> getRelatedRecordsServer(String mappingType, Boolean needDetails) {
		if (needDetails == null) needDetails = false;
		CBMapping__c mapping = new CBMappingSelector().getMappingRecordByType(mappingType);
		List<CBMappingReportWrapper> resultList = new List<CBInitWizardReportPageController.CBMappingReportWrapper>();
		if (String.isEmpty(mapping.ResultSObject__c) || String.isEmpty(mapping.SourceSObject__c)) { // mapping was not set up
			CBMappingReportWrapper stub = new CBMappingReportWrapper();
			stub.comment = 'Mapping is not configured for this analytic';
			resultList.add(stub);
			return resultList;
		}
		CBMappingInterface mappingObject = new CBInitWizardService.CBMapGeneral(mappingType);
		String extKey;
		Map<String, SObject> cbRecordsMap = new Map<String, SObject>();
		List<SObject> sl = new CBSobjectSelector(mapping.ResultSObject__c, false).setLimit(25000).setOrder('Name', true).selectFieldsByNames(new List<String>{'Id', 'Name', 'cblight__ExtId__c'}).getSobjects('');
		for (SObject cbObject : sl) {
			extKey = (String) cbObject.get('cblight__ExtId__c');
			if(String.isEmpty(extKey)) continue;
			if (cbRecordsMap.containsKey(extKey)) {
				setDoubledCBRecordReportLine(cbObject, resultList);
			}
			cbRecordsMap.put(extKey, cbObject);
		}
		for (SObject sourceObject : Database.query(mappingObject.getSourceRequestString())) {
			SObject CBObject = CBRecordsMap.remove(sourceObject.Id);
			compareSourceWithCBRecordAndAddReportLine(sourceObject, CBObject, resultList, needDetails);
		}
		if (cbRecordsMap.size() > 0) {
			for (SObject cbObject : cbRecordsMap.values()) {
				setExtraCBRecordReportLine(cbObject, resultList);
			}
		}
		if (!needDetails) resultList = addFirstLine(resultList);
		return resultList;
	}


	private static void compareSourceWithCBRecordAndAddReportLine(SObject sourceObject, SObject CBObject, List<CBMappingReportWrapper> resultList, Boolean needDetails) {
		try {
			String sourceObjectName = (String) sourceObject.get('Name');
			String cbObjectName = CBObject == null ? null : (String) CBObject.get('Name');

			CBMappingReportWrapper newWrapper = new CBMappingReportWrapper();
			newWrapper.extId = sourceObject.Id;
			newWrapper.extName = sourceObjectName;
			if (CBObject == null) { // if CB side does not have needed record
				newWrapper.comment = 'Missed on the CB side';
				newWrapper.CBName = 'N/A';
				resultList.add(newWrapper);
				return;
			}
			if (sourceObjectName != cbObjectName) { // is source name and CB record name differ
				newWrapper.CBId = CBObject.Id;
				newWrapper.CBName = cbObjectName;
				newWrapper.comment = 'Source name different from the CB name';
				resultList.add(newWrapper);
				return;
			}
			if (needDetails) {
				newWrapper.extName = sourceObjectName;
				newWrapper.comment = 'Ok';
				newWrapper.CBId = CBObject.Id;
				newWrapper.CBName = sourceObjectName;
				newWrapper.styleClass = 'success';
				resultList.add(newWrapper);
			}
			coincideCounter++; // all right counter
		} catch (Exception e) {
			throw new CBException(e, 'compareSourceWithCBRecordAndAddReportLine error');
		}
	}

	private static void setDoubledCBRecordReportLine(SObject cbObject, List<CBMappingReportWrapper> resultList) {
		CBMappingReportWrapper newWrapper = new CBMappingReportWrapper();
		newWrapper.CBId = cbObject.Id;
		newWrapper.CBName = (String) cbObject.get('Name');
		newWrapper.extName = 'N/A';
		newWrapper.comment = 'Two or more CB records have the same external Id';
		resultList.add(newWrapper);
	}
	private static void setExtraCBRecordReportLine(SObject cbObject, List<CBMappingReportWrapper> resultList) {
		CBMappingReportWrapper newWrapper = new CBMappingReportWrapper();
		newWrapper.CBId = cbObject.Id;
		newWrapper.CBName = (String) cbObject.get('Name');
		newWrapper.extName = 'N/A';
		newWrapper.comment = 'CB side record only';
		resultList.add(newWrapper);
	}

	private static List<CBMappingReportWrapper> addFirstLine(List<CBMappingReportWrapper> resultList) {
		CBMappingReportWrapper firstLine = new CBMappingReportWrapper();
		firstLine.comment = 'The number of matching records is ' + coincideCounter;
		firstLine.styleClass = coincideCounter == 0 ? 'warning' : 'success';
		firstLine.extName = coincideCounter + ' source record(s)';
		firstLine.CBName = coincideCounter + ' CloudBudget record(s)';
		List<CBMappingReportWrapper> tmp = new List<CBMappingReportWrapper>();
		tmp.add(firstLine);
		tmp.addAll(resultList);
		return tmp;
	}

	public class CBMappingReportWrapper {
		public CBMappingReportWrapper() {
			CBName = extName = comment = '-';
			styleClass = 'warning';
		}

		@AuraEnabled
		public String CBId { get; set; }

		@AuraEnabled
		public String CBName { get; set; }

		@AuraEnabled
		public String extId { get; set; }

		@AuraEnabled
		public String extName { get; set; }

		@AuraEnabled
		public String comment { get; set; }

		@AuraEnabled
		public String styleClass { get; set; }
	}

}