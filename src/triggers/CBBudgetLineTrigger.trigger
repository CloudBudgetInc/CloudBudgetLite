trigger CBBudgetLineTrigger on cblight__CBBudgetLine__c(after delete, after insert, after update, before delete, before insert, before update ){
	fflib_SObjectDomain.triggerHandler(CBBudgetLineDomain.class );
}