import {LightningElement, track} from 'lwc';
import getNonFinancialLibrariesServer from "@salesforce/apex/CBBudgetLinePageController.getNonFinancialLibrariesServer";
import getBudgetLinesServer from "@salesforce/apex/CBBudgetLinePageController.getBudgetLinesServer";
import {_applyDecStyle} from 'c/cbUtils';

/**
 * PROTOTYPE
 */

export default class CbBudgetLineDialog extends LightningElement {

	@track periods;
	@track sourceCatalog = [];
	@track activeSections = [];
	@track budgetLine = {lines: [], yearlyTotal: 0, Name: 'Test'}; //
	@track legendList = [{letter: 'A'}, {letter: 'B'}, {letter: 'C'}, {letter: 'D'}, {letter: 'E'}];
	@track formula = '';
	@track complexLine = {Name: 'Test', yearlyTotal: 0, lines: [], show: false};


	/**
	 * LWC DoInit
	 */
	connectedCallback() {
		this.getNonFinancialLibs();
		this.getBudgetLines();
		_applyDecStyle();
	}

	getNonFinancialLibs() {
		getNonFinancialLibrariesServer()
			.then(nonFinancialLibs => {
				let sourceGroupMap = {};
				nonFinancialLibs.forEach(fl => {
					let sourceGroup = sourceGroupMap[fl.cblight__LayerTitle__c];
					if (!sourceGroup) {
						sourceGroup = new SourceGroup();
						sourceGroup.title = fl.cblight__LayerTitle__c;
						sourceGroupMap[fl.cblight__LayerTitle__c] = sourceGroup;
					}
					fl.title = fl.Name;
					fl.title += fl.cblight__Description__c ? ' (' + fl.cblight__Description__c + ') ' : '';
					sourceGroup.lines.push(fl);
					this.activeSections.push(fl.cblight__LayerTitle__c);
				});
				let sourceGroupArray = Object.values(sourceGroupMap);
				this.sourceCatalog = [...this.sourceCatalog, ...sourceGroupArray];
			})
			.catch((e) => alert("Get Non Financial Libs Error: " + e));
	}

	getBudgetLines() {
		getBudgetLinesServer({params: {test: 'test'}})
			.then(budgetLines => {
				let sourceGroup = new SourceGroup();
				sourceGroup.title = 'Budget Lines';
				budgetLines.forEach(bl => {
					bl.cblight__NonFinancialItems__r = bl.cblight__CBAmounts__r;
					bl.title = bl.Name;
					bl.title += bl.cblight__Description__c ? ' (' + bl.cblight__Description__c + ') ' : '';
				});
				sourceGroup.lines = budgetLines;
				this.sourceCatalog.push(sourceGroup);
				this.activeSections.push('Budget Lines');
			})
			.catch((e) => alert("Get Non Financial Libs Error: " + e));
	}

	getSelectedLine(lineId) {
		let selectedLine;
		this.sourceCatalog.forEach(c => {
			c.lines.forEach(l => {
				if (l.Id === lineId) {
					selectedLine = l;
				}
			})
		});
		return selectedLine;
	}

	/**
	 * Handler
	 */
	passToLegend(event) {
		let legendList = JSON.parse(JSON.stringify(this.legendList));
		let selectedLine = JSON.parse(JSON.stringify(this.getSelectedLine(event.target.value)));
		let type = event.target.name;

		let stop = false;
		legendList.forEach(legend => {
			if (stop) return null;
			if (!legend.Id) {
				stop = true;
				selectedLine.title = selectedLine.Name + ' (' + type + ') ';
				legend.Id = selectedLine.Id;
				legend.title = selectedLine.Name + ' (' + type + ') ';
				legend.line = selectedLine;
			}
		});
		this.legendList = legendList;
	}

	changeFormula(event) {
		this.formula = event.target.value;
	}

	applyFormula() {
		try {
			const letters = ['A', 'B', 'C', 'D', 'E'], legendMap = {};
			let complexLine = {lines: [], Name: 'General', show: true};
			this.legendList.forEach(l => {
				legendMap[l.letter] = l.line;
			});
			let totalLine = {Name: 'Total', title: 'Total', cblight__NonFinancialItems__r: [], yearlyTotal: 0};
			letters.forEach(letter => {
				const line = legendMap[letter];
				if (line) {
					complexLine.lines.push(line);
				}
			});

			for (let i = 0; i < 12; i++) {
				let valueFormula = this.formula;
				letters.forEach(letter => {
					const line = legendMap[letter];
					if (!line) return null;
					const amount = line.cblight__NonFinancialItems__r[i];
					valueFormula = valueFormula.replace(letter, amount.cblight__Value__c);
				});
				let totalValue = parseFloat(eval(valueFormula).toFixed(2));
				totalLine.cblight__NonFinancialItems__r[i] = {cblight__Value__c: totalValue};
				totalLine.yearlyTotal += totalValue;
			}
			complexLine.lines.push(totalLine);
			complexLine.yearlyTotal = totalLine.yearlyTotal;
			this.complexLine = complexLine;
			console.log(this.complexLine);
		} catch (e) {
			alert('ERROR: ' + e);
		}
	}

	resetData() {
		this.complexLine = {Name: 'Test', yearlyTotal: 0, lines: [], show: false};
		this.legendList = [{letter: 'A'}, {letter: 'B'}, {letter: 'C'}, {letter: 'D'}, {letter: 'E'}];
		this.formula = ''
	}
}


/**
 * Service class to store group of budget lines with the common status
 */
function SourceGroup() {
	this.lines = [];
	this.title = '';
}