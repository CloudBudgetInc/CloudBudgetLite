import {api, LightningElement, track} from 'lwc';
import {_message, _cl} from 'c/cbUtils';
import {
	displayAdditionalTotalSignIfNeeded,
	generateAdditionalTotals,
	hideAdditionalTotal
} from './cbClusterAdditonalTotal';

export default class CbCluster extends LightningElement {

	@track displayChildrenClusters = false; // render children clusters if needed
	@track displaySubClusters = false; // render subclusters
	@track next; // next children clusters level
	@track currentCluster;
	@track totalLine;
	@track additionalTotalLines;
	@track globalClusterExternal;
	@track currentKey;
	@track styleClass = 'shadow ';
	@track clusterSplitLine = 'slds-p-top_small slds-p-bottom_small clusterSplitLine';
	@track isSectionOpen = false; // true if section is open
	@track isAdditionalTotalsNeeded = false; // true if additional totals section needed for the section
	@track isAdditionalTotalsOpen = false; // true if additional totals section is open
	@track showClusterTotal = true;

	@api level; // current cluster level
	storageKey = '';

	@api
	get clusterKey() {
	}; // key of the current cluster
	set clusterKey(value) {
		this.currentKey = value;
	}

	/**
	 * API field that receive general cluster object
	 */
	@api
	get globalCluster() {
	}

	set globalCluster(value) {
		try {
			this.level = +this.level;
			this.next = 1 + this.level;
			this.specifyCurrentCluster(value);
			this.totalLine = this.currentCluster.totalLine;
			this.globalClusterExternal = value;
			this.storageKey = `openedSections${this.currentCluster.fullKey}`;
		} catch (e) {
			_message('error', `Cluster : Set Global Cluster Error: ${e}`);
			_message('info', `Cluster : ${JSON.stringify(this.currentCluster)}`);
		}
	};

	connectedCallback() {
		this.setRenderingRule();
		this.setStyleClass();
		this.openNeededSections();
		displayAdditionalTotalSignIfNeeded(this);
	}

	/**
	 * Method finds the current cluster in the global
	 */
	specifyCurrentCluster = (globalCluster) => {
		try {
			let currentCluster = null;
    const { level, currentKey } = this;
	
    switch (level) {
        case 0:
            currentCluster = globalCluster;
            this.showClusterTotal = globalCluster.childClusters.length > 1;
            break;
        case 1:
            currentCluster = globalCluster.childClusters.find(cl => cl.fullKey === currentKey);
            break;
        default:
            let i = 2;
            let childClusters = globalCluster.childClusters;
            while (i <= level && childClusters.length > 0) {
                const nextChildClusters = [];
                for (const childCluster of childClusters) {
                    const match = childCluster.childClusters.find(cl => cl.fullKey === currentKey);
                    if (match) {
                        currentCluster = match;
                        break;
                    } else {
                        nextChildClusters.push(...childCluster.childClusters);
                    }
                }
                childClusters = nextChildClusters;
                i++;
            }
    }
    if (!currentCluster) {
        throw new Error('Section does not have a cluster');
    }
    this.currentCluster = currentCluster;
    this.setClusterStyles(level);

		} catch (e) {
			_message('error', `Cluster : Specify Current Cluster Error : ${e}`);
		}
	};

	/**
	 * The method specifies render for the current cluster
	 */
	setRenderingRule = () => {
		try {
			if (this.level === 0 || this.currentCluster.childClusters.length > 0) {
				this.displayChildrenClusters = true;
			} else {
				this.displaySubClusters = true;
			}
			this.isSectionOpen = localStorage.getItem(this.storageKey) === 'true';
		} catch (e) {
			_message('error', `Cluster : Set Rendering Rule Error : ${this.level} and ${this.currentKey} ERR -> ${e}`);
		}
	};

	setStyleClass = () => {
		this.styleClass += ` lvl${this.level}`;
	};

	showStatusWindow = () => {
		this.dispatchEvent(new CustomEvent('openStatusWindow', {
			bubbles: true,
			composed: true,
			detail: this.currentKey
		}));
	};

	/**
	 * The method opens last state of accordions
	 */
	openNeededSections = () => {
		try {
			if (localStorage.getItem('showAll') === 'true') {
				this.isSectionOpen = true;
			} else {
				const currentStorageKey = `openedSections${this.currentKey}`; // key for local storage
				this.openedSections = localStorage.getItem(currentStorageKey) ? localStorage.getItem(currentStorageKey).split(',') : [];
			}
		} catch (e) {
			_message('error', 'Cluster : Open Needed Section(s) Error: ' + e);
		}
	};

	/**
	 * Method manages behavior of budget lines accordions
	 */
	toggleOpenSection = () => {
		try {
			this.isSectionOpen = !this.isSectionOpen;
			if (this.isSectionOpen) {
				localStorage.setItem(this.storageKey, 'true');
			} else {
				delete localStorage.removeItem(this.storageKey);
			}
		} catch (e) {
			_message('error', 'Cluster : Toggle Open Section Error: ' + e);
		}
	};

	/**
	 * Method gets style name for subcluster
	 */
	setClusterStyles = (level) => {
		try {
			const styles = JSON.parse(localStorage.getItem('cbstyles'));
			const orgVariable = JSON.parse(localStorage.getItem('orgVariable'));
			if (!styles || !orgVariable) return;
			const clusterLevelStyleId = orgVariable[`cblight__BudgetLineLvl${level + 1}Style__c`];
			for (let i = 0; i < styles.length; i++) {
				if (styles[i].Id === clusterLevelStyleId) {
					this.styleClass += ` ${styles[i].Name.replace(/ /g, "")} `;
					break;
				}
			}
		} catch (e) {
			_message('error', `Cluster : set Cluster Styles Error ${e}`);
		}
	};

	generateAdditionalTotals = () => {
		generateAdditionalTotals(this);
	};

	hideAdditionalTotal = () => {
		hideAdditionalTotal();
	};


}