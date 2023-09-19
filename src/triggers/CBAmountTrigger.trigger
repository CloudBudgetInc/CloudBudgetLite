/**
 * Created by Alex JR on 3/22/2022.
 */

trigger CBAmountTrigger on CBAmount__c (before insert, before update, before delete, after insert, after update, after delete) {
	fflib_SObjectDomain.triggerHandler(CBAmountDomain.class);
}