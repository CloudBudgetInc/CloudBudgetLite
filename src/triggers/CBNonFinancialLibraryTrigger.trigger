/**
 * Created by Alex JR on 7/29/2022.
 */

trigger CBNonFinancialLibraryTrigger on CBNonFinancialLibrary__c (before insert, before update, before delete, after insert, after update, after delete) {

	fflib_SObjectDomain.triggerHandler(CBNonFinancialLibraryDomain.class);
}