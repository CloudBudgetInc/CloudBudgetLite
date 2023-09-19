/**
Copyright (c) 2021, CloudBudget, Inc.
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

The service class of CBLog__c

* CBLog__c types:                                                                                              <br/>
*******************************                                                                                <br/>
* DEBUG - for debugging events                                                                                 <br/>
* DELETE                                                                                                       <br/>
* TRIGGER                                                                                                      <br/>
* EXCEPTION                                                                                                    <br/>
* OTHER                                                                                                        <br/>
* BACKUP 
*                                                                                                              <br/>
*                                                                                                              <br/>
* HOW TO USE IT:                                                                                               <br/>
******************************************************                                                         <br/>
* CBConsole.setLog('DELETE', 'Deleting', 'job report'); // init new log                                        <br/>
* CBConsole.addLog('->  CBDeleteBatch running'); // set some messages                                            <br/>
* CBConsole.addLog('@B->  CBalance query = ' + queryLocatorQueryString); // specify color of the message       <br/>
* CBConsole.insertLog();  // insert the log List                                                               <br/>
* @R - red color "@R Some Error" for example                                                                   <br/>
* @G - green color                                                                                             <br/>
* @B - blue color                                                                                              <br/>
*

*/
public with sharing class CBLog {

	public class LogWrapper {
		public String title = 'N/A';
		public String type = 'DEBUG';
		public Integer lineNumber;
		public String error;
		public String description;
		public String jobId;
		public String parent;
		public String status;
		public String procedure;
		List<String> content = new List<String>();

		public LogWrapper(String type, String title, String description) {
			type = CBUtils.refineStr(type);
			title = CBUtils.refineStr(title);
			description = CBUtils.refineStr(description);
			this.type = type;
			this.title = title;
			this.description = description;
			this.parent = null;
			this.jobId = null;
			this.status = 'SUCCESSFUL';
			this.procedure = null;
		}

		/**
		* Error constructor
		*
		* @param type
		* @param title
		* @param error
		* @param lineNumber
		*/
		public LogWrapper(String type, String title, String error, Integer lineNumber) {
			this.type = type;
			this.title = title;
			this.error = error;
			this.lineNumber = lineNumber;
		}

		public String getJSON() {
			Map<String, String> result = new Map<String, String>{
					'ln' => lineNumber == null ? '' : String.valueOf(lineNumber),
					'e' => error, 'd' => description, 'c' => JSON.serialize(content), 'j' => jobid, 'p' => parent
			};
			return JSON.serialize(result);
		}

	}
	private static LogWrapper logWrapper;


	/**
	* The method initiates new CBLog__c
	*
	* @param type of CBLog (look upper)
	* @param title of CBLog (some specific information)
	* @param description everything you need
	*/
	public static void setLog(String type, String title, String description) {
		title = CBUtils.refineStr(title);
		logWrapper = new LogWrapper(type, title, description);
	}

	/**
	* The method initiates new CBLog__c
	*
	* @param type of CBLog (look upper)
	* @param title of CBLog (some specific information)
	*/
	public static void setLog(Exception e, String title) {
		logWrapper = new LogWrapper('EXCEPTION', title, e.getMessage(), e.getLineNumber());
		logWrapper.status = 'UNSUCCESSFUL';
	}

	/**
	* @param s some String <br/>
	* @R - red color "@R Some Error" for example <br/>
	* @G - green color <br/>
	* @B - blue color <br/>
	*/
	public static void addLog(String s) {
		logWrapper.content.add(s);
	}

	public static void insertLog() {
		String tmpString = logWrapper.getJSON();
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBLog__c.SObjectType }
		);
		uow.registerNew(new CBLog__c(Type__c = logWrapper.type, Title__c = logWrapper.title,
		Description__c = tmpString, jobId__c = logWrapper.jobId, parent__c = logWrapper.parent,
		Action__c = logWrapper.procedure, Status__c = logWrapper.status));
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