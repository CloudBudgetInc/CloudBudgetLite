/**
 * Created by Alex JR on 7/26/2023.
 */

trigger CBTaskTrigger on CBTask__c (after update) {

	if (Trigger.isAfter && Trigger.isUpdate) {
		CBEventService.publishEvent('Task Updated');
	}

}