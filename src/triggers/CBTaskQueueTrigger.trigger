/**
 * Created by Alex JR on 8/16/2022.
 */

trigger CBTaskQueueTrigger on CBTaskQueue__c (before insert, before update, before delete, after insert, after update, after delete) {
	fflib_SObjectDomain.triggerHandler(CBTaskQueueDomain.class);
}