import {api, LightningElement, track} from 'lwc';
import {_getCopy, _message, _parseServerError, _cl} from 'c/cbUtils';
import getAllocationTermsServer from "@salesforce/apex/CBAllocationTermPageController.getAllocationTermsServer";
import saveAllocationTermsServer from "@salesforce/apex/CBAllocationTermPageController.saveAllocationTermsServer";
import deleteAllocationTermsServer from "@salesforce/apex/CBAllocationTermPageController.deleteAllocationTermsServer";

export default class CbAllocationTerm extends LightningElement {
	@track allocationTerms = [];
	@track showSpinner = false;
	@track validationMessages = [];
	@track periodUnitSO = [
		{label: 'Month', value: 'Month'},
		{label: 'Day', value: 'Day'},
		{label: 'Week', value: 'Week'},
		{label: 'Quarter', value: 'Quarter'},
		{label: 'Year', value: 'Year'}];
	@api crId = 'a058D0000014ZqJQAU';


	connectedCallback() {
		this.getAllocationTerms();
	}

	/**
	 * Method gets list of functions form database to create SO list
	 */
	getAllocationTerms = () => {
		this.showSpinner = true;
		getAllocationTermsServer({crId: this.crId})
			.then(allocationTerms => {
				if (allocationTerms) {
					allocationTerms = _getCopy(allocationTerms);
					allocationTerms.forEach((at, i) => at.idx = i + 1);
				}
				this.allocationTerms = allocationTerms;
				this.sendAllocationTermsToCalcRuleDialog(allocationTerms);
				this.validateAllocTerms();
			})
			.catch(e => _parseServerError("AT : Get Allocation Terms Error: ", e))
			.finally(() => this.showSpinner = false)
	};
	/**
	 * Handler for changing allocation terms
	 */
	handleChange = (event) => {
		const allocTerm = this.allocationTerms.find(at => at.Id === event.target.label);
		allocTerm[event.target.name] = event.target.value;
		this.saveAllocationTerm(allocTerm);
	};
	/**
	 * Handler for the button to add a new Allocation Term
	 */
	addNewAllocTerm = () => {
		this.showSpinner = true;
		this.saveAllocationTerm(null, true);
	};
	/**
	 * Method saves allocation term after changing
	 */
	saveAllocationTerm = (allocTerm, rerenderNeeded) => {
		allocTerm = allocTerm ? allocTerm : this.getNewAllocTerm();
		saveAllocationTermsServer({aTerms: [allocTerm]})
			.then(() => {
				if (rerenderNeeded) this.getAllocationTerms();
				this.validateAllocTerms();
			})
			.catch(e => _parseServerError('AT : Save Allocation Term Error : ', e))
	};
	/**
	 * Method deletes selected allocation term
	 */
	deleteAllocationTerm = (event) => {
		this.showSpinner = true;
		deleteAllocationTermsServer({aTermId: event.target.value})
			.then(() => {
				_message('success', 'Deleted');
				this.getAllocationTerms();
			})
			.catch(e => _parseServerError('AT : Deleting Error : ', e))
	};
	/**
	 * Method returns a new default allocation terms
	 */
	getNewAllocTerm = () => {
		const preDefUnit = this.allocationTerms && this.allocationTerms.length > 0 ? this.allocationTerms[0].cblight__PeriodUnit__c : 'Month';
		return {
			Name: 'New',
			cblight__Part__c: 0,
			cblight__Shift__c: 0,
			cblight__PeriodUnit__c: preDefUnit,
			cblight__CBCalculationRule__c: this.crId
		};
	};
	/**
	 * Method Validates allocation terms
	 */
	validateAllocTerms = () => {
		const SHIFT_DOUBLING = 'Note! Two or more lines with the same shift';
		const PART_TOTAL = 'Note! The sum of the parts is not equal to 100%';
		const vm = [];
		if (this.allocationTerms && this.allocationTerms.length > 0) {
			const shiftSet = {};
			let partTotal = 0;
			this.allocationTerms.forEach(at => {
				if (at.cblight__Shift__c && at.cblight__Shift__c !== 0 && shiftSet[at.cblight__Shift__c]) vm.push(SHIFT_DOUBLING);
				shiftSet[at.cblight__Shift__c] = true;
				if (at.cblight__Part__c) partTotal += +at.cblight__Part__c;
			});
			if (partTotal > 102 || partTotal < 98) vm.push(PART_TOTAL);
		}
		this.validationMessages = vm;
	};

	/**
	 * Method sends updated AT to tthe CRD
	 */
	sendAllocationTermsToCalcRuleDialog = (allocationTerms) => {
		this.dispatchEvent(new CustomEvent('updateAllocationTerms', {
			bubbles: true,
			composed: true,
			detail: {AllocationTerms : allocationTerms}
		}))
	};

}