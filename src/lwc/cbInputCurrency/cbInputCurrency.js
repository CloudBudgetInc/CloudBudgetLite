import {api, LightningElement, track} from 'lwc';

export default class CbInputCurrency extends LightningElement {
	@track value = 0;
	@api currencyCode = 'USD'; // by default
	@api
	get val() {
		return value;
	}

	set val(v) {
		this.value = v;
		if (!this.FORMATTER) {
			this.FORMATTER = new Intl.NumberFormat('en-US', {
				style: 'currency',
				currency: this.currencyCode ? this.currencyCode : 'USD',
				minimumFractionDigits: 2,
			});
		}
		this.toCurrencyFormat();
	}

	@api label = '';
	@api name = '';
	@api variant = '';
	@api cl = 'dec';
	@api isBold = false;

	@api disabled = false;
	FORMATTER;
	CURRENCY_REGEXP = /[^\d.-]/g;
	isCurrencyFormat = false;

	connectedCallback() {
		if (this.isBold) this.cl = this.cl + ' bold';
		if (!this.label && this.label.length === 0) this.variant = "label-hidden";
	};

	/**
	 * The method converts value to a currency format. Example:  15  => "$15.00"
	 */
	toCurrencyFormat = () => {
		this.value = this.value ? this.value : 0;
		this.value = this.FORMATTER.format(this.value);
		this.isCurrencyFormat = true;
	};
	/**
	 * This method convert a currency format to a number. Example:  "$15.00"  => 15
	 */
	fromCurrencyFormat = () => {
		const cleanedAmountString = (this.value || "0").replace(this.CURRENCY_REGEXP, "");
		const parsedAmount = parseFloat(cleanedAmountString);
		this.value = isNaN(parsedAmount) ? "" : parsedAmount;
		this.isCurrencyFormat = false;
	};
	////// STANDARD EVENTS /////////
	onClick = (event) => {
		if (event) this.inclick(event);
	};
	onFocus = (event) => {
		if (event && this.infocus) this.infocus(event);
		setTimeout(this.fromCurrencyFormat, 10);
	};
	onBlur = (event) => {
		if (!this.isCurrencyFormat) {
			this.toCurrencyFormat();
		}
		if (event) this.inblur(event);
	};
	@api
	inblur;
	@api
	infocus;
	@api
	inclick;
	////// STANDARD EVENTS /////////
}