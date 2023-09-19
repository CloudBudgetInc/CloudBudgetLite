/**
 * Created by Alex JR on 1/17/2022.
 */

public interface CBMappingInterface {

	Boolean recordNumberIsOutOfLimit();
	/**
	 * @return the base soql request string
	 */
	String getSourceRequestString();
	/**
	 * Process of mapping in a batch or in a class
	 * @param scope
	 */
	void doMapping(List<sObject> scope);
	void finishMapping();
}