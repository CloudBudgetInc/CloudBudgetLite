public with sharing class CBSOService {
	private static final String SELECT_STR = 'SELECT Id, ';
	private static final String FROM_STR = ' FROM ';
	private static final String WHERE_STR = ' WHERE ';
	private static final String ORDER_STR = ' ORDER BY ';
	private static final Integer LIMIT_INT = 10000;
	private static final String LIMIT_STR = ' LIMIT ' + String.valueOf(LIMIT_INT);
	private Map<String, List<CBSO>> result = new Map<String, List<CBSO>>();
	/**
	 * @param pageKeyOfSO 'divisionSO' - page map key
	 * @param objectName 'Option' - name of a dimension
	 * @param fields 'Name,cblight__Index__c'
	 * @param splitter ':'
	 * @param filter 'OwnerId != null'
	 * @param sortBy 'Name,cb4_ORDER_STRNumber__c'
	 *
	 * @return
	 */
	public CBSOService addSOList(String pageKeyOfSO, String objectName, List<String> fields, String splitter, String filter, String sortBy) {
		result.put(pageKeyOfSO, getSO(objectName, fields, splitter, filter, sortBy));
		return this;
	}

	/**
	 *
	 * @param objectName 'Division__c' or so
	 * @param fields 'Code__c', 'Name'
	 * @param splitter ':' or '-'
	 * @param filter ' Value__c > 0 '
	 * @return
	 */
	public static List<CBSO> getSO(String objectName, List<String> fields, String splitter, String filter, String sortBy) {
		List<CBSO> r = new List<CBSO>();
		filter = filter == null ? '' : filter;
		splitter = splitter == null ? '' : splitter;
		sortBy = (sortBy == null ? ' Name ' : sortBy);
		CBSobjectSelector sobjSel = new CBSobjectSelector(objectName, false).selectFieldsByNames(new String[]{'Id'}).selectFieldsByNames(fields).setFilter(filter).setOrder(sortBy, null).setLimit(LIMIT_INT);
		String q = sobjSel.getStringQuery(null);
		List<Sobject> sList = sobjSel.getSobjects();
		
		try {
			for (sObject t : sList) {
				r.add(new CBSO(t.Id, getTitle(t, fields, splitter)));
			}
		} catch (Exception e) {
			System.debug(q);
			System.debug('SO ERROR: ' + e);
			throw e;
		}
		return r;
	}

	public Map<String, List<CBSO>> getResult() {
		return result;
	}

	////// PRIVATE METHODS ////////
	private static String getTitle(sObject t, List<String> fields, String splitter) {
		String r = '', val;
		for (String f : fields) {
			val = (String) t.get(f);
			if (val == null) {
				continue;
			}
			if (!r.equals('')) {
				r += splitter;
			}
			r += val;
		}
		return r;
	}
}