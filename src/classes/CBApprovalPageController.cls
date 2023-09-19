/** 
Copyright (c) 2022, CloudBudget, Inc.
Created by Alex JR on 30/05/2022.
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

Page Controller for Budget Line child component
 */

public with sharing class CBApprovalPageController {
	/**
	 * @param budgetLineIds list of budget line ids
	 *
	 * @return list of CBBudgetLines that need to be approved
	 */
	@AuraEnabled
	public static List<CBBudgetLine__c> getBudgetLinesForApproveServer(List<String> budgetLineIds) {
		if (budgetLineIds == null || budgetLineIds.size() == 0) {
			return null;
		}
		return new CBBudgetLineSelector().getBudgetLinesForApproving(new Set<String>(budgetLineIds));
	}

	/**
	 * @param budgetLineIds list of budget line ids
	 * @param isForward true if CBBudgetLines need to be move forward by approval process, false if revert
	 */
	@AuraEnabled
	public static void triggerStatusServer(List<String> budgetLineIds, Boolean isForward) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ CBBudgetLine__c.SObjectType });
		List<CBBudgetLine__c> bLines = new CBBudgetLineSelector().getBudgetLinesForApproving(new Set<String>(budgetLineIds));
		if (isForward) {
			for (CBBudgetLine__c line : bLines) {
				line.cblight__APAheadTrigger__c = line.cblight__APAheadTrigger__c == null ? true : !line.cblight__APAheadTrigger__c;
				uow.registerDirty(line);
			}
		} else {
			for (CBBudgetLine__c line : bLines) {
				line.cblight__APBackTrigger__c = line.cblight__APBackTrigger__c == null ? true : !line.cblight__APBackTrigger__c;
				uow.registerDirty(line);
			}
		}
		uow.commitWork();
	}

	/**
	 *
	 *
	 * @return List of available Users
	 */
	@AuraEnabled
	public static List<User> getUserServer() {
		Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1][0].IsSandbox;
		if (isSandbox) {
			List<User> userList = [SELECT Id, Name FROM User WHERE IsActive = TRUE WITH SECURITY_ENFORCED ORDER BY Name];
			return userList;
		}
		List<Id> userListId = new List<Id>();
		for (UserPackageLicense userPackageLicense : [
			SELECT UserId
			FROM UserPackageLicense
			WHERE PackageLicense.NamespacePrefix = 'cblight'
			WITH SECURITY_ENFORCED
		]) {
			userListId.add(userPackageLicense.UserId);
		}
		List<User> userList = [SELECT Id, Name FROM User WHERE Id IN :userListId WITH SECURITY_ENFORCED ORDER BY Name];
		return userList;
	}

	/**
	 * Send Notification to Budget Owner
	 */
	@AuraEnabled(cacheable=true)
	public static void sendEmailToController(String body, List<String> userIdList, String subject) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> userEmailList = new List<String>();
		for (User user : [SELECT email FROM User WHERE Id IN :userIdList WITH SECURITY_ENFORCED]) {
			userEmailList.add(user.email);
		}

		mail.setSubject(subject);
		mail.setToAddresses(userEmailList);
		mail.setHtmlBody('<h3>' + body + '</h3>');
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}
	/**
	 * Update budget lineusers
	 */
	@AuraEnabled
	public static void saveBLtoServer(List<CBBudgetLine__c> budgetLines) {
		if (budgetLines != null) {
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ CBBudgetLine__c.SObjectType });
			uow.registerUpsert(budgetLines);
			uow.commitWork();
		}
	}

	/**
	 * check if User is Not Admin
	 */
	@AuraEnabled
	public static Boolean checkIfUserNotAdminServer() {
		String userProfileName = [SELECT Name FROM profile WHERE id = :userinfo.getProfileId() WITH SECURITY_ENFORCED].Name;
		if (userProfileName != 'System Administrator') {
			return true;
		}
		return false;
	}
}