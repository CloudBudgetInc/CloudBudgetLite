/** 
Created by Valerii Krykun on 03/22/2022.
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
public with sharing class CBLogService {
	public class LogWrapper {
		CBLog__c log;
		List<CBLogDetail__c> details;

		/**
		 * Log constructor
		 * @param type
		 * @param name
		 * @param description
		 * @param status
		 * @param source
		 */
		public LogWrapper(String type, String name, String description, String status, String source) {
			log = new CBLog__c(
					cblight__Type__c = type,
					Name = name,
					cblight__Description__c = description,
					cblight__Status__c = status,
					cblight__Source__c = source
			);
			details = new List<CBLogDetail__c>();
		}

		/**
		 * Error constructor
		 * @param type
		 * @param name
		 * @param status
		 * @param error
		 * @param lineNumber
		 */
		public LogWrapper(String type, String name, String status, String error, Integer lineNumber) {
			log = new CBLog__c(
					cblight__Type__c = type,
					Name = name,
					cblight__Status__c = status,
					cblight__Description__c = 'Line : ' + lineNumber + ' : ' + error
			);
			details = new List<CBLogDetail__c>();
		}
	}
	/////// EXTERNAL METHODS ///////
	/**
	 * Custom wrapper to log
	 */
	private static LogWrapper logWrapper;

	/**
	 * The method initiates new CBLog__c
	 * @param type of CBLog (look upper)
	 * @param name of CBLog (some specific information)
	 * @param description everything you need
	 * @param status of CBLog (some specific information)
	 * @param source of CBLog (some specific information)
	 */
	public static void setLog(String type, String name, String description, String source) {
		String status = 'PROGRESS';
		name = name.left(80);
		logWrapper = new LogWrapper(type, name, description, status, source);
	}

	/**
	 * The method initiates new CBLog__c
	 *
	 * @param type of CBLog (look upper)
	 * @param name of CBLog (some specific information)
	 */
	public static void setLog(Exception e, String name) {
		String status = 'ERROR';
		name = name.left(80);
		logWrapper = new LogWrapper('EXCEPTION', name, status, e.getMessage(), e.getLineNumber());
	}

	/**
	 * The method initiates new CBLog__c for custom cases
	 *
	 * @param type of CBLog (look upper)
	 * @param name of CBLog (some specific information)
	 */
	public static void setLog(String name, String status, String description) {
		name = name.left(80);
		logWrapper = new LogWrapper('CUSTOM', name, description, status, '');
	}

	/**
	 * The method initiates new CBLogDetail__c
	 *
	 * @param description of CBLogDetail__c (Description)
	 * @param name of CBLogDetail__c (some specific information)
	 * @param reason of CBLogDetail__c (some specific information)
	 */
	public static void addLogDetail(String name, String description, String reason) {
		logWrapper.details.add(
				new cblight__CBLogDetail__c(Name = name, cblight__Description__c = description, cblight__Reason__c = reason, cblight__Parent__c = null)
		);
	}
	/**
	 * The method insert to DB new CBLog__c and CBLogDetail__c
	 */
	public static void insertLog() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBLog__c.SObjectType, CBLogDetail__c.SObjectType }
		);
		if (logWrapper.log.Id != null) {
			uow.registerDirty(logWrapper.log);
		} else {
			uow.registerNew(logWrapper.log);
		}
		for (CBLogDetail__c t : logWrapper.details) {
			if (t.Id != null) {
				uow.registerDirty(t, CBLogDetail__c.cblight__Parent__c, logWrapper.log);
			} else {
				uow.registerNew(t, CBLogDetail__c.cblight__Parent__c, logWrapper.log);
			}
		}
		uow.commitWork();
	}

	/////////////////////// TEST ONLY //////////////////////
	public static void deleteLogs() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBLog__c.SObjectType }
		);
		uow.registerDeleted([SELECT Id FROM CBLog__c WITH SECURITY_ENFORCED]);
		uow.commitWork();
	}
	/////////////////////// TEST ONLY //////////////////////
}