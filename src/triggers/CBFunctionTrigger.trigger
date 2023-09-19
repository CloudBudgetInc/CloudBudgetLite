/**
 * Created by Alex JR on 7/25/2022.
 */

trigger CBFunctionTrigger on CBFunction__c (before insert, before update, before delete, after insert, after update, after delete) {
	fflib_SObjectDomain.triggerHandler(CBFunctionDomain.class);
}