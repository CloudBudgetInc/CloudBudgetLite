/**
 * Created by Valerii Krykun on 04/14/2022.
 * Copyright (c) 2022, CloudBudget, Inc.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * Neither the name of the CloudBudget, Inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
public with sharing class CBStyleSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                CBStyle__c.Id,
                CBStyle__c.Name,
                CBStyle__c.CSS__c,
                CBStyle__c.Color__c,
                CBStyle__c.BackgroundColor__c,
                CBStyle__c.Font__c,
                CBStyle__c.FontWeight__c,
                CBStyle__c.State__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return CBStyle__c.sObjectType;
    }

    /**
     * @return List<CBStyle__c>: List of the records
     */
    public List<CBStyle__c> getStyles() {
        fflib_QueryFactory query = newQueryFactory();
        return Database.query(query.toSOQL());
    }

    /**
     * @param rId (String): style id
     *
     * @return CBStyle__c: Record selected by Id
     */
    public CBStyle__c getStyleById(String rId) {
        if (rId == null) {
            return null;
        }
        fflib_QueryFactory query = newQueryFactory();
        if (!String.isBlank(rId)) {
            query.setCondition('Id = \'' + rId + '\'');
        }
        return Database.query(query.toSOQL());
    }
    /**
     * @return CBStyle__c: CBStyle__c map list
     */
    public Map<String, String> getStylesMap() {
        fflib_QueryFactory query = newQueryFactory();
        List<CBStyle__c> styles = Database.query(query.toSOQL());
        Map<String, String> r = new Map<String, String>();
        for (CBStyle__c st : styles) {
            r.put(st.Name, st.Id);
        }
        return r;
    }

    /**
     * @param filter (String): filter value
     *
     * @return List<CBStyle__c>: List of records by filter
     */
    public List<CBStyle__c> getStylesRecordsByFilter(String filter) {
        fflib_QueryFactory query = newQueryFactory();
        if (!String.isBlank(filter)) {
            query.setCondition(filter);
        }
        return Database.query(query.toSOQL());
    }

    /**
     * @return CBStyle__c: Record selected for account type
     */
    public List<CBStyle__c> getStylesForAccountTypes() {
        Set<String> externalIds = new Set<String>();
        List<CBStyle__c> r = new List<CBStyle__c>();
        for (CBAccountType__c obj : new CBAccountTypeSelector().getAccountTypeRecords()) {
            if (obj != null) externalIds.add(obj.cblight__CBStyle__c);
        }
        if (externalIds.isEmpty()) return null;
        for (CBStyle__c p : new CBStyleSelector().getStylesRecordsByFilter(' Id IN ' + CBUtils.getFormattedINQuery(externalIds))) {
            r.add(p);
        }
        return r;
    }

    /**
     * @return CBStyle__c: Record selected for amounts
     */
    public List<CBStyle__c> getStylesForAmounts() {
        Set<String> externalIds = new Set<String>();
        List<CBStyle__c> r = new List<CBStyle__c>();
        for (CBAmount__c obj : new CBAmountSelector().getAmountsRecords()) {
            externalIds.add(obj.CBStyle__c);
        }
        if (externalIds == null || externalIds.size() == 0) {
            return null;
        }
        for (CBStyle__c p : new CBStyleSelector().getStylesRecordsByFilter(' Id IN' + CBUtils.getFormattedINQuery(externalIds))) {
            r.add(p);
        }
        return r;
    }
    
        public List<List<Object>> getStylesAndAccountTypeByFilter(String filter) {
        fflib_QueryFactory query = newQueryFactory();
        if (!String.isBlank(filter)) {
            query.setCondition(filter);
        }
        List<CBStyle__c> styleRecords = (List<CBStyle__c>) Database.query(query.toSOQL());
        
        List<CBAccountType__c> accountTypeRecords = new CBAccountTypeSelector().getAccountTypeRecordsByFilter(null);
        
        List<List<Object>> result = new List<List<Object>>();
        result.add(new List<CBStyle__c>(styleRecords));
        result.add(new List<CBAccountType__c>(accountTypeRecords));
        
        return result;
    }
}