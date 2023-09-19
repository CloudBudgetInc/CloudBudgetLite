public with sharing class CBSobjectSelector extends fflib_SObjectSelector {
	private Schema.SObjectType sObjectType1;

	public CBSobjectSelector(Schema.SObjectType sObjectType) {
		this.sObjectType1 = sObjectType;
		this.qFactory = newQueryFactory();
	}
	public CBSobjectSelector(Schema.SObjectType sObjectType, Boolean includeSelectorFields) {
		this.sObjectType1 = sObjectType;
		this.qFactory = newQueryFactory(includeSelectorFields);
	}

	public CBSobjectSelector(String sObjectTypeString) {
		this.sObjectType1 = Schema.getGlobalDescribe().get(sObjectTypeString);
		this.qFactory = newQueryFactory();
	}
	public CBSobjectSelector(String sObjectTypeString, Boolean includeSelectorFields) {
		this.sObjectType1 = Schema.getGlobalDescribe().get(sObjectTypeString);
		this.qFactory = newQueryFactory(includeSelectorFields);
	}

	public List<Schema.SObjectField> getSObjectFieldList() {
		return this.sObjectType1.getDescribe().fields.getMap().values();
	}

	private fflib_QueryFactory qFactory;

	public Schema.SObjectType getSObjectType() {
		return this.sObjectType1;
	}

	/**
	 * @param limitCount if not null and > 0 causes a LIMIT clause to be added to the resulting query.
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBSobjectSelector setLimit(Integer limitCount) {
		if (limitCount != null && limitCount > 0) {
			qFactory.setLimit(limitCount);
		}
		return this;
	}

	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBSobjectSelector setFilter(String filter) {
		if (filter != null && !String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return this;
	}
	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBSobjectSelector setOrder(String fieldNames, Boolean ascending) {
		if (fieldNames != null && !String.isBlank(fieldNames)) {
			fflib_QueryFactory.SortOrder so = fflib_QueryFactory.SortOrder.ASCENDING;
			if (ascending != null && !ascending) {
				so = fflib_QueryFactory.SortOrder.DESCENDING;
			}
			qFactory.setOrdering(fieldNames, so);
		}
		return this;
	}

	/**
	 * @param fields the set of {@link Schema.SObjectField}s to select.
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBSobjectSelector selectFields(Set<Schema.SObjectField> fields) {
		qFactory.selectFields(fields);
		return this;
	}
	/**
	 * @param fieldNames the List of field API names to select.
	 *
	 * @return instance of CBSobjectSelector
	 */
	public CBSobjectSelector selectFieldsByNames(List<String> fieldNames) {
		qFactory.selectFields(fieldNames);
		return this;
	}

	/**
	 * @return List<SObject>: List of the records
	 */
	public List<SObject> getSobjects() {
		return Database.query(qFactory.toSOQL());
	}

	/**
	 * The main method to get list of sObjects
	 *
	 * @param filter
	 *
	 * @return list of sObjects
	 */
	public List<SObject> getSobjects(String filter) {
		if (filter != null && !String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return Database.query(qFactory.toSOQL());
	}

	/**
	 * method to count records
	 *
	 * @param filter
	 *
	 * @return number of sObjects
	 */
	public Integer countSobjects(String filter) {
			fflib_QueryFactory query = newQueryFactory(false);
			if (filter != null && !String.isBlank(filter)) {
				query.setCondition(filter);
			}
			return Database.countQuery(query.toSOQLOnlyCount());
	}

	/**
	 * Returns string query for SObject
	 *
	 * @param filter
	 *
	 * @return SOQL query as String
	 */
	public String getStringQuery(String filter) {
		if (filter != null && !String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return qFactory.toSOQL();
	}
}