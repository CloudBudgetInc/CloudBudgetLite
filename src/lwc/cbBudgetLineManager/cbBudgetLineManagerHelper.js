import {_getCopy, _message} from "c/cbUtils";

const CLUSTER_NAME_DEFAULT = "Other";
const fieldsNeedToBeDeletedFromAmountObject = ["Id", "cblight__CBBudgetLine__c", "cblight__CBPeriod__c"];
const fieldsNeedToBeDeletedFromTotalLine = [
	"Id",
	"Name",
	"OwnerId",
	"cblight__CBAccount__c",
	"cblight__CBAccountType__c",
	"cblight__CBBudgetYear__c",
	"cblight__CBDivision__c",
	"cblight__CBSubAccountName__c",
	"Owner"
];
const fieldsNeedToBeAddedLabels = {
	cblight__CBAccount__r: 'cblight__CBAccountLabel__c',
	cblight__CBBudgetYear__r: 'cblight__CBBudgetYearLabel__c',
	cblight__CBDivision__r: 'cblight__CBDivisionLabel__c',
	cblight__CBVariable1__r: 'cblight__CBVariable1Label__c',
	cblight__CBVariable2__r: 'cblight__CBVariable2Label__c',
	cblight__CBVariable3__r: 'cblight__CBVariable3Label__c',
	cblight__CBVariable4__r: 'cblight__CBVariable4Label__c',
	cblight__CBVariable5__r: 'cblight__CBVariable5Label__c',
	Owner: 'Owner'
};

let context; // this of the main JS class

/**
 * Separate class for SubCluster
 */
function SubCluster(key) {
	this.key = key; // subCluster unique name
	this.lines = [];
	this.totalLine = {}; // subCluster total lines
	this.calculateSubClusterTotalLine = () => {
		// SubCluster calculates its own amounts
		try {
			this.totalLine = _getCopy(this.lines[0]);// clone amounts from the first line
			let totalAmounts = this.totalLine.cblight__CBAmounts__r;
			nullifyAmounts(totalAmounts, this.totalLine);
			for (let i = 0; i < this.lines.length; i++) {
				let line = this.lines[i];
				let amounts = line.cblight__CBAmounts__r;

				for (let j = 0; j < amounts.length; j++) {
					let amount = amounts[j];
					totalAmounts[j].cblight__Value__c += +amount.cblight__Value__c;
				}
			}
			calculateBudgetLineTotal(this.totalLine);
		} catch (e) {
			_message('error', `Calculate SubCluster Total Line Error: ${e}`);
		}
	}
}

/**
 * Special class for Cluster
 */
function Cluster(key, level, clusterRule, name) {
	this.key = key; // cluster unique name
	this.fullKey = ''; // key with full list of ids+
	this.name = name;
	this.subClusters = []; // two or more subClusters
	this.totalLine = {cblight__CBAmounts__r: []}; // cluster total lines
	this.childClusters = []; // subsidiary clusters
	this.level = level;
	this.clusterRule = clusterRule;

	this.putLineToSubCluster = (line) => {
		const lineType = line.cblight__CBAccountType__c;
		let subCluster = this.subClusters.find((sc) => sc.key === lineType);// Find the subcluster corresponding to the line type
		if (!subCluster) {// If subcluster doesn't exist, create it and add it to the parent cluster's subclusters
			subCluster = new SubCluster(lineType);
			this.subClusters.push(subCluster);
		}
		subCluster.lines.push(line);// Add the line to the subcluster
	};

	this.putLineToChildCluster = (line) => {
		try {
			const field = this.clusterRule[`cblight__Level${this.level + 1}__c`];
			const clusterKey = line[field] ?? CLUSTER_NAME_DEFAULT;
			const analytic = line[`${field.replace("__c", "__r")}`];
			const clusterName = analytic?.Name || this.addTypeToName(field, clusterKey);
			let cluster = this.childClusters.find(cl => cl.key === clusterKey);
			if (!cluster) {
				cluster = new Cluster(clusterKey, this.level + 1, this.clusterRule, clusterName);
				this.childClusters.push(cluster);
			}
			const subField = this.clusterRule[`cblight__Level${this.level + 2}__c`];
			if (!subField) {
				cluster.putLineToSubCluster(line);
			} else {
				cluster.putLineToChildCluster(line);
			}
		} catch (e) {
			_message('error', `BLM : Pass Line To Child Cluster Error : ${e.lineNumber} --> ${e}`);
		}
	};
	this.addTypeToName = (field, clusterName) => {
		let fieldData = context.SObjectFieldsData.find(({value}) => value === field);

		return (fieldData ? fieldData.label : "") + ': ' + clusterName;
	};
	this.calculateTotalLines = () => {
		try {
			if (this.childClusters.length === 0) {
				for (let i = 0; i < this.subClusters.length; i++) {
					const subCluster = this.subClusters[i];
					subCluster.calculateSubClusterTotalLine();
				}
				this.calculateClusterTotalLineFromSubClusters();
			} else {
				for (let i = 0; i < this.childClusters.length; i++) {
					const cluster = this.childClusters[i];
					cluster.calculateTotalLines();
				}
				this.calculateClusterTotalLineFromChildrenClusters();
			}
		} catch (e) {
			_message('error', `BLM Helper : Calculate Total Lines Error: ${e} ${e.lineNumber}`);
		}
	};
	this.generateFullKes = (parentTail) => {
		try {
			if (this.childClusters.length > 0) {
				for (let i = 0; i < this.childClusters.length; i++) {
					const childCluster = this.childClusters[i];
					childCluster.fullKey = parentTail + childCluster.key;
					childCluster.generateFullKes(childCluster.fullKey);
				}
			}
		} catch (e) {
			_message('error', `BLM Helper : Generate Full Keys Error: ${e}`);
		}
	};
	this.calculateClusterTotalLineFromSubClusters = () => {
		try {
			this.totalLine = JSON.parse(JSON.stringify(this.subClusters[0].totalLine));
			let totals = this.totalLine.cblight__CBAmounts__r,
				i,
				num = this.totalLine.cblight__CBAmounts__r.length;
			nullifyAmounts(totals, this.totalLine);
			if (this.subClusters && this.subClusters.length === 1) this.subClusters[0].showSubClusterTotalLine = false;
			for (const subCluster of this.subClusters) {
				const subClusterTotals = subCluster.totalLine.cblight__CBAmounts__r;
				const sum = subCluster.totalLine.cblight__CBAccountSign__c === "+";
				for (i = 0; i < num; i++) {
					totals[i].cblight__Value__c += sum ? +subClusterTotals[i].cblight__Value__c : 0 - subClusterTotals[i].cblight__Value__c;
				}
			}
			calculateBudgetLineTotal(this.totalLine); // calculate right total
		} catch (e) {
			_message('error', `BLM : Calculate Cluster Total Line From SubClusters Error: ${e}`);
		}
	};
	this.calculateClusterTotalLineFromChildrenClusters = () => {
		try {
			const firstChildTotalLine = this.childClusters[0].totalLine;
			this.totalLine = JSON.parse(JSON.stringify(firstChildTotalLine));
			const totals = this.totalLine.cblight__CBAmounts__r;
			const num = totals.length;
			nullifyAmounts(totals, this.totalLine);

			for (let i = 0; i < num; i++) {
				let sum = 0;
				for (let j = 0; j < this.childClusters.length; j++) {
					const childTotalLine = this.childClusters[j].totalLine;
					const childTotalAmounts = childTotalLine.cblight__CBAmounts__r;
					sum += parseFloat(childTotalAmounts[i].cblight__Value__c);
				}
				totals[i].cblight__Value__c = +sum.toFixed(2);
			}

			calculateBudgetLineTotal(this.totalLine);
		} catch (e) {
			_message('error', `BLM: Calculate Cluster Total Line From Children Clusters Error: ${e}`);
		}
	};
	/**
	 * The method finds needed cluster using its key
	 */
	this.getSubCluster = (clusterKey) => {
		let queue = [...this.childClusters];
		while (queue.length > 0) {
			const currentCluster = queue.shift();
			if (currentCluster.fullKey === clusterKey) return currentCluster;
			if (currentCluster.childClusters.length > 0) queue.push(...currentCluster.childClusters);
		}
		return null;
	};
	/**
	 * @param budgetLineIds is link to empty array
	 * @returns list of all included budget line Ids
	 */
	this.getAllBudgetLineIds = (budgetLineIds) => {
		for (let i = 0; i < this.subClusters.length; i++) {
			const sc = this.subClusters[i];
			for (let j = 0; j < sc.lines.length; j++) {
				const line = sc.lines[j];
				budgetLineIds.push(line.Id);
			}
		}
		for (let i = 0; i < this.childClusters.length; i++) {
			const cc = this.childClusters[i];
			cc.getAllBudgetLineIds(budgetLineIds);
		}
	};
	this.calculateNumberOfLevels = () => {
		let numberOfLevels = -1;
		const setMaxLevel = (cluster) => {
			numberOfLevels = Math.max(numberOfLevels, cluster.level);
			cluster.childClusters.forEach(cl => setMaxLevel(cl));
		};
		setMaxLevel(this);
		localStorage.setItem('numberOfLevels', numberOfLevels.toString());
	};
	/**
	 * The method sorts clusters and subClusters alphabetically
	 */
	this.sortClustersAlphabetically = () => {
		try {
			this.childClusters = getObjectsSortedBySortField(this.childClusters, `name`);
			this.subClusters = getObjectsSortedBySortField(this.subClusters, `key`);
			this.childClusters.forEach(cc => cc.sortClustersAlphabetically());
		} catch (e) {
			_message('error', 'BLM : Sort Clusters Error : ' + e);
		}
	}
}

/**
 * Method sorts list of objects alphabetically
 * @param objects list of objects
 * @param sortField field by which that objects must be sorted
 */
const getObjectsSortedBySortField = (objects, sortField) => {
	return objects.sort((a, b) => (a[sortField] < b[sortField]) ? -1 : (a[sortField] > b[sortField]) ? 1 : 0);
};

/**
 * The main method to form global cluster structure
 */
const generateGlobalStructure = (_this) => {
	try {
		context = _this;
		const globalCluster = new Cluster("global", 0, context.clusterRule, "Consolidated");
		for (let i = 0; i < context.budgetLines.length; i++) {
			const line = context.budgetLines[i];
			calculateBudgetLineTotal(line);
			globalCluster.putLineToChildCluster(line);
		}
		globalCluster.generateFullKes('#');
		globalCluster.calculateTotalLines();
		globalCluster.sortClustersAlphabetically();
		indexLines(globalCluster);
		globalCluster.calculateNumberOfLevels();
		let isDetailMode = localStorage.getItem('isDetailMode');
		if (isDetailMode === 'true') {
			addOrgVarLabelsToLines(context.budgetLines);
		}
		return globalCluster;
	} catch (e) {
		_message('error', "BLM : Generate Structure Object Error: " + e);
	}
};

/**
 * Method add index field to list
 */
const indexLines = (globalCluster) => {
	let index = 0;
	const updateLineIndex = (cluster) => {
		if (cluster.subClusters && cluster.subClusters.length > 0) {
			for (const subCluster of cluster.subClusters) {
				for (const line of subCluster.lines) line.idx = ++index;
			}
		} else {
			for (const childCluster of cluster.childClusters) {
				updateLineIndex(childCluster);
			}
		}
	};
	updateLineIndex(globalCluster);
};


const nullifyAmounts = (amounts, line) => {
	for (const amount of amounts) {
		amount.cblight__Value__c = 0;
		for (const f of fieldsNeedToBeDeletedFromAmountObject) delete amount[f];
	}
	for (const f of fieldsNeedToBeDeletedFromTotalLine) delete line[f];
	line.cblight__Value__c = 0;
};

/**
 * The method calculates right total column
 * @param {*} line with amounts located in array cblight__CBAmounts__r
 * @returns line with calculated cblight__Value__c field
 */
const calculateBudgetLineTotal = (line) => {
	try {
		line.yearlyTotal = 0; // right total of the line for the budget year
		let globalTotal = 0; // right total of the line for whole years
		const budgetYearId = localStorage.getItem("cblight__CBBudgetYear__c");
		for (let i = 0; i < line.cblight__CBAmounts__r.length; i++) {
			const a = line.cblight__CBAmounts__r[i];
			if (budgetYearId.startsWith(a.cblight__CBBudgetYear__c)) {
				line.yearlyTotal += +a.cblight__Value__c;
			}
			globalTotal += +a.cblight__Value__c;
		}
		line.cblight__Value__c = globalTotal;
		return line;
	} catch (e) {
		_message('error', `BLM Helper : Calculate BudgetLine Total Error: ${e}`);
		_message('error', `BLM Helper : Wrong Line is : ${line.Name + ' (' + line.Id + ')'}`);
	}
};

/**
 * Method add orgVariable labels to lines
 */
const addOrgVarLabelsToLines = (lines) => {
	try {
		let orgVariable = JSON.parse(localStorage.getItem('orgVariable'));
		for (let i = 0; i < lines.length; i++) {
			let line = lines[i];
			let lineDetails = [];
			for (const key in fieldsNeedToBeAddedLabels) {
				let mapValue = line[key];
				if (key === 'Owner') {
					if (mapValue) mapValue.orgVariableLabel = 'User';
				} else {
					if (mapValue) mapValue.orgVariableLabel = orgVariable[fieldsNeedToBeAddedLabels[key]];
				}
				if (mapValue) {
					let labelText = `${mapValue.orgVariableLabel}: ${mapValue.Name}`;
					lineDetails.push(labelText.slice(0, 35));
				}
			}
			line.details = lineDetails;
		}
	} catch (e) {
		_message("error", `BLM Helper: add Org Var Labels To Lines Error ${e}`);
	}
};

export {generateGlobalStructure, calculateBudgetLineTotal};