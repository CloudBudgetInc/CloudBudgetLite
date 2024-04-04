import getStylesForAccountTypesServer from "@salesforce/apex/CBBudgetLinePageController.getStylesForAccountTypesServer";
import getStylesRecordsServer from "@salesforce/apex/CBBudgetLinePageController.getStylesRecordsServer";
import {_message, _parseServerError, _cl} from "c/cbUtils";

/**
 * Method get Styles list
 */
const setStyles = async () => {
	try {
		await getStylesForAccountTypesServer()
			.then((styleList) => {
				if (!styleList) {
					return null;
				}
				styleList.forEach((style) => (style.cssName = style.Name.replace(/ /g, "")));
				applyStyles(styleList);
			})
			.catch((e) => _parseServerError("BLM : StylesList callback Error: ", e));
	} catch (e) {
		_message('error', "stylesList Error: " + e);
	}
};

/**
 * Method gets full List of the Styles for Cluster Rules
 */
const setStylesForClusters = async () => {
	await getStylesRecordsServer()
		.then(styles => {
			if (!styles) return null;
			localStorage.setItem('cbstyles', JSON.stringify(styles));
			applyStyles(styles);
		})
		.catch(e => _parseServerError('BL Manager : get Styles Records Server Error', e));
};

/**
 * Method apply css to html
 */
const applyStyles = (stylesList) => {
	try {
		_cl(JSON.stringify(stylesList));
		let styleArray = stylesList;
		let styleCSS = document.createElement("style");
		styleCSS.type = "text/css";
		styleCSS.innerHTML = styleArray.reduce((str, style) => {
			str = str + "." + style.Name.replace(/ /g, "") + " " + style.cblight__CSS__c + " ";
			return str;
		}, "");
		document.getElementsByTagName("head")[0].appendChild(styleCSS);

		var clusterSplitLine = document.createElement('style');
		const css = stylesList.find(style => style.Name === "Cluster Split Line");
		if (!css) return;
		clusterSplitLine.innerHTML =
			'.clusterSplitLine {' +
			'border-bottom: 1px dotted ' + css.cblight__BackgroundColor__c + ' !important;' +
			'}';
		document.getElementsByTagName("head")[0].appendChild(clusterSplitLine);
	} catch (e) {
		_message('error', "applyStyles ERROR: " + e);
	}
};

export {setStyles, setStylesForClusters};