/**
 * Created by Valerii Krykun on 5/06/2023.
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
public class CBStyleDomain extends fflib_SObjectDomain {

	public CBStyleDomain(List<cblight__CBStyle__c> sObjectList) {
		super(sObjectList);
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new CBStyleDomain(sObjectList);
		}
	}

	public override void onBeforeInsert() {
		checkForDuplicateItems((List<cblight__CBStyle__c>) Records);
	}

	public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
		checkForDuplicateItems((List<cblight__CBStyle__c>) Records);
	}

	/**
	 * The method checks for duplicate style names
	 *
	 * @param items (List<cblight__CBStyle__c>): list of styles to check for duplicates
	 */
	private static void checkForDuplicateItems(List<cblight__CBStyle__c> items) {
		List<cblight__CBStyle__c> existingStyles = new CBStyleSelector().getStylesRecordsByFilter(null);
		Map<String, cblight__CBStyle__c> existingStyleMap = new Map<String, cblight__CBStyle__c>();
		for (cblight__CBStyle__c existingStyle : existingStyles) {
			existingStyleMap.put(existingStyle.Name, existingStyle);
		}

		/*for (cblight__CBStyle__c style : items) {
			if (existingStyleMap.containsKey(style.Name) && existingStyleMap.get(style.Name).Id != style.Id) {
				style.addError('Please choose another name as the style you selected already exists.');
			}
		}*/
	}
}