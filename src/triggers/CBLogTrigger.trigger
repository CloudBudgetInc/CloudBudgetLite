/**
 * Created by Alex JR on 2/20/2023.
 */

trigger CBLogTrigger on CBLog__c (after insert) {

	for (CBLog__c log : Trigger.new) {
		CBEventService.publishEvent(log);
	}

}