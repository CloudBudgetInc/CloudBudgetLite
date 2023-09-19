trigger CBEventTrigger on CBEvent__e (after insert) {
	/*for (CBEvent__e event : Trigger.New) {
		insert new cblight__CBLog__c (cblight__Type__c = 'EXCEPTION', Description__c = event.Description__c);
	}*/
}