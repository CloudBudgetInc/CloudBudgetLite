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


public with sharing class CBReportingPageController {

	private static final Set<String> CUBE_ADDITIONAL_FIELDS = new Set<String>{
			'cblight__CBAccount__r.Name', 'cblight__CBDivision__r.Name', 'cblight__CBBudgetYear__r.Name', 'cblight__CBPeriod__r.Name'
	};


	/////////////////   LIST OF REPORTS METHODS //////////////
	/**
	 * @param filter folder of report or search string
	 *
	 * @return full list of reports
	 */
	@AuraEnabled
	public static List<CBReport__c> getAllReportsServer(String filter) {
		return new CBReportSelector().getReportByFilter(filter);
	}
	/////////////////   LIST OF REPORTS METHODS //////////////

	/////////////////   SINGLE REPORT METHODS //////////////
	/**
	 * @param reportId selected report Id
	 *
	 * @return report with its columns
	 */
	@AuraEnabled
	public static CBReport__c getReportWithConfigurationsAndColumnsServer(String reportId) {
		return new CBReportSelector().getReportWithConfigurationsAndColumnsById(reportId);
	}

	/**
	 * @return list of CBCube fields for the configuration filter
	 */
	@AuraEnabled
	public static List<CBSO> getListOfCubeFieldsSOServer() {
		return CBUtils.getObjectFieldsSO('cblight__CBCube__c');
	}

	@AuraEnabled
	public static CBReportConfiguration__c saveConfigurationServer(CBReportConfiguration__c configuration) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBReportConfiguration__c.SObjectType
				}
		);
		uow.registerUpsert(configuration);
		uow.commitWork();
		return configuration;
	}

	@AuraEnabled
	public static void saveAllConfigurationsServer(List<CBReportConfiguration__c> configList) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBReportConfiguration__c.SObjectType
				}
		);
		uow.registerUpsert(configList);
		uow.commitWork();
	}

	@AuraEnabled
	public static CBReport__c saveReportServer(CBReport__c report) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBReport__c.SObjectType
				}
		);
		uow.registerUpsert(report);
		uow.commitWork();
		return getReportWithConfigurationsAndColumnsServer(report.Id);
	}

	/**
	 * The method delete report configuration
	 *
	 * @param configuration - CBReportConfiguration__c
	 */
	@AuraEnabled
	public static void deleteReportConfigByConfigSOServer(CBReportConfiguration__c configuration) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBReportConfiguration__c.SObjectType
				}
		);
		uow.registerDeleted(configuration);
		uow.commitWork();
	}

	/**
	 * @param configurationId - String
	 *
	 * @return list of CBCube__c as source data for the report
	 */
	@AuraEnabled
	public static List<CBCube__c> getReportDataServer(String configurationId) {
		/* CBLightCubeRefreshTriggerService.refreshAllCBCubes(); */
		CBReportConfiguration__c configuration = new CBReportConfigurationSelector().getReportConfigurationById(configurationId);
		if (CBMultiCurrencyService.multiCurrencyEnabled) CUBE_ADDITIONAL_FIELDS.add('CurrencyIsoCode');
		List<CBCube__c> result = new CBCubeSelector()
				.setCubeAdditionalFields(CUBE_ADDITIONAL_FIELDS)
				.setAllExtraCBCubeFields()
				.setFilter(configuration.Filter__c)
				.query();
		return result;
	}

	/**
	 * Different static data to help generate a report
	 * The CBReportColumnPageController has the same method
	 *
	 * @return - Map<String, Object>
	 */
	@AuraEnabled
	public static Map<String, Object> getStaticDataServer() {
		Map<String, Object> r = new Map<String, Object>();

		Map<String, List<CBPeriod__c>> periodMap = new Map<String, List<CBPeriod__c>>();
		for (CBPeriod__c p : new CBPeriodSelector().getPeriods(null)) {
			List<CBPeriod__c> periodList = periodMap.get(p.CBBudgetYear__c);
			if (periodList == null) {
				periodList = new List<CBPeriod__c>();
				periodMap.put(p.CBBudgetYear__c, periodList);
			}
			periodList.add(p);
		}
		r.put('periodMap', periodMap);
		r.put('styles', new CBStyleSelector().getStyles());

		return r;
	}

	/////////////////   SINGLE REPORT METHODS //////////////


}