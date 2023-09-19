import {api, LightningElement, track} from "lwc";
import {_getCopy, _isInvalid, _message} from "c/cbUtils";

export default class CBBudgetLines extends LightningElement {
	// sfdx force:source:deploy -m LightningComponentBundle
	@track lines = [];
	@track totalLine = {};
	@track name = "N/A";
	@track styleName = "";
	@track styleClass = "shadow slds-m-bottom_xxx-small ";
	@track showSubClusterTotalLine = true; // if subCluster is single in a cluster, total line is hidden

	@api
	get subCluster() {
	}

	set subCluster(value) {
		this.lines = value.lines;
		this.name = value.key;
		this.totalLine = value.totalLine;
		this.showSubClusterTotalLine = value.showSubClusterTotalLine !== false;
	}

	connectedCallback() {
		this.getAccTypeStyleName(this.name);
	}

	/**
	 * Method gets style name for subcluster
	 */
	getAccTypeStyleName = (name) => {
		try {
			let accTypeObj = JSON.parse(localStorage.getItem("accTypeObj"));
			for (let i = 0; i < accTypeObj.length; i++) {
				let a = accTypeObj[i];
				if (a.Name == name && !_isInvalid(a.cblight__CBStyle__r)) {
					this.styleName = a.cblight__CBStyle__r.Name.replace(/ /g, "");
					this.setColor();
					break;
				}
			}
		} catch (e) {
			_message("error", `SubCluster : Style Name Error ${e}`);
		}
	};

	setColor() {
		this.styleClass += this.styleName;
	}

	/**
	 * This method adds a new budget line
	 */
	addNewBudgetLine() {
		try {
			if (localStorage.getItem('newLinesDisabled') === 'true') {
				_message('info', 'You reached the limit on the number of budget lines for the CloudBudget Lite version. ' +
					'Please contact CloudBudget to get the unlimited version');
				return;
			}
			let clusterRule = JSON.parse(localStorage.getItem("CBClusterRule"));
			let line = _getCopy(this.lines[this.lines.length - 1], true);
			let newBlParameters = {
				cblight__CBBudgetYear__c: line.cblight__CBBudgetYear__c,
				cblight__CBBudgetYear__r: line.cblight__CBBudgetYear__r
			};
			for (let i = 1; i <= 10; i++) {
				for (const [key, value] of Object.entries(line)) {
					if (key === clusterRule[`cblight__Level${i}__c`]) {
						const arr = [[key, value]];
						const obj = Object.fromEntries(arr);
						newBlParameters = Object.assign(newBlParameters, obj);
					}
				}
			}
			localStorage.setItem('newBlParameters', JSON.stringify(newBlParameters));
			this.openLine();
		} catch (e) {
			_message("error", "BLM : Subcluster : Add New BL Error : " + e);
		}
	}

	/**
	 * Method pass event to budget line manager that opens needed budget line in dialog window
	 */
	openLine = () => {
		try {
			this.dispatchEvent(new CustomEvent('openBudgetLineModal', {
				bubbles: true,
				composed: true,
				detail: ""
			}));
		} catch (e) {
			_message('error', `Budget Line : Open Line Error : ${e}`);
		}
	};
}