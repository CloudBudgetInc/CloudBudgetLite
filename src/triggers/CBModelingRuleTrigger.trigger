/**
 * Created by Alex JR on 8/16/2022.
 */

trigger CBModelingRuleTrigger on CBModelingRule__c (before insert, before update, before delete, after insert, after update, after delete) {
	fflib_SObjectDomain.triggerHandler(CBModelingRuleDomain.class);
}