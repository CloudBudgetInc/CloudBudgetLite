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


public with sharing class CBReportConfigurationSelector extends fflib_SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                CBReportConfiguration__c.Id,
                CBReportConfiguration__c.Name,
                CBReportConfiguration__c.Description__c,
                CBReportConfiguration__c.DisplayUnits__c,
                CBReportConfiguration__c.Filter__c,
                CBReportConfiguration__c.CBReport__c,
                CBReportConfiguration__c.SubtotalNumber__c,
                CBReportConfiguration__c.cblight__FloatPointCell__c,
                CBReportConfiguration__c.Grouping__c // list of CBCube fields split by a coma
        };
    }

    public Schema.SObjectType getSObjectType() {
        return CBReportConfiguration__c.sObjectType;
    }

    public CBReportConfiguration__c getReportConfigurationById(String confId) {
        if (confId == null) return null;
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id = \'' + confId + '\'');
        query.setLimit(1);
        return Database.query(query.toSOQL());
    }

}