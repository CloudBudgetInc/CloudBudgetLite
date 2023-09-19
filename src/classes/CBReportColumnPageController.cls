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


public with sharing class CBReportColumnPageController {

	@AuraEnabled
	public static List<CBReportColumn__c> getReportColumnsServer(String reportId) {
		return new CBReportColumnSelector().getReportColumnsByReportId(reportId);
	}

	/**
	 * Static data for the report like Cube fields and other
	 * The CBReportPageController has the same method
	 */
	@AuraEnabled
	public static Map<String, Object> getStaticDataServer() {
		Map<String, Object> r = new Map<String, Object>();
		List<CBSO> fieldsWithDigitSO = new List<CBSO>();

		List<CBSO> allCubeSO = CBUtils.getObjectFieldsSO('cblight__CBCube__c');
		for (CBSO so : allCubeSO) {
			if (so.type == 'CURRENCY' || so.type == 'DOUBLE') {
				fieldsWithDigitSO.add(so);
			}
		}
		r.put('fieldsWithDigitSO', fieldsWithDigitSO);

		List<CBSO> periodSO = cblight.CBSOService.getSO('cblight__CBPeriod__c', new List<String>{
				'Name'
		}, null, null, 'cblight__Start__c');
		r.put('periodSO', periodSO);

		r.put('periodsAll', new CBPeriodSelector().getPeriods(null));

		return r;
	}

	/**
	 * The method saves report columns
	 *
	 * @param report truncated version of the report (object has just few fields)
	 * @param columns list of report columns
	 *
	 * @return
	 */
	@AuraEnabled
	public static List<CBReportColumn__c> saveColumnsServer(CBReport__c report, List<CBReportColumn__c> columns) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBReport__c.SObjectType, CBReportColumn__c.SObjectType }
		);
		uow.registerUpsert(report);
		for (CBReportColumn__c rc : columns) {
			uow.registerUpsert(rc);
			uow.registerRelationship(rc, CBReportColumn__c.CBReport__c, report);
		}
		uow.commitWork();
		return getReportColumnsServer(report.Id);
	}

	@AuraEnabled
	public static void deleteColumnServer(List<String> columnIds) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBReportColumn__c.SObjectType }
		);
		uow.registerDeleted(new CBSobjectSelector(CBReportColumn__c.SObjectType, false).selectFieldsByNames(new List<String>{'Id'}).getSobjects(' Id IN ' + CBUtils.getFormattedINQuery(new Set<String>(columnIds))));
		uow.commitWork();
	}

}