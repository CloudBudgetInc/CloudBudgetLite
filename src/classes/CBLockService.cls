/** 
Copyright (c) 2022, CloudBudget, Inc.
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

 */
public with sharing class CBLockService {

	private static String EDITING = 'Editing';
	private static String DELETING = 'Deleting';

	/**
	 * Method locks budget lines from editing only
	 * @param bLines a list of tested budget lines
	 * @return true if locked
	 */
	public static Boolean recordsLockedForEditing(List<cblight__CBBudgetLine__c> oldBLines, List<cblight__CBBudgetLine__c> newBLines) {
		Integer idx = oldBLines.size();
		for (Integer i = 0; i < idx; i++) {
			if (EDITING.equals(oldBLines[i].cblight__Lock__c) && EDITING.equals(newBLines[i].cblight__Lock__c)) return true;
		}
		return false;
	}
	/**
	 * Method locks budget lines from editing and deleting
	 * @param bLines a list of tested budget lines
	 * @return true if locked
	 */
	public static Boolean recordsLockedForDeleting(List<cblight__CBBudgetLine__c> bLines) {
		for (CBBudgetLine__c bl : bLines) {
			if (DELETING.equals(bl.Lock__c) || EDITING.equals(bl.Lock__c)) return true;
		}
		return false;
	}

}