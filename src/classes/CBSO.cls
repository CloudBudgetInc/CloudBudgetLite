/** Select Option wrapper class  */
public class CBSO implements Comparable {
	@AuraEnabled
	public String label { get; set; }

	@AuraEnabled
	public String value { get; set; }

	@AuraEnabled
	public Boolean disabled { get; set; }

	@AuraEnabled
	public String type { get; set; }

	@AuraEnabled
	public String detail { get; set; }

	public CBSO(String value, String label) {
		this.label = label;
		this.value = value;
		this.disabled = false;
	}

	public CBSO(String value, String label, Boolean disabled) {
		this.label = label;
		this.value = value;
		this.disabled = disabled;
	}

	public CBSO(String value, String label, String type) {
		this.label = label;
		this.value = value;
		this.type = type;
	}

	public CBSO(String value, String label, String type, String detail) {
		this.label = label;
		this.value = value;
		this.type = type;
		this.detail = detail;
	}

	/**
	 * Special comparator to specify comparing rule for List<CBSO>
	 */
	public Integer compareTo(Object objToCompare) {
		CBSO so = (CBSO) objToCompare;
		if (label == so.label) return 0;
		return label > so.label ? 1 : -1;
	}
}