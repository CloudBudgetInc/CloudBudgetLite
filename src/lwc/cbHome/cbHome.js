import {LightningElement, track} from 'lwc';

import home from '@salesforce/resourceUrl/home';
import getPackageVersionServer from "@salesforce/apex/CBAdminControlPanelPageController.getPackageVersionServer";
import {loadStyle} from "lightning/platformResourceLoader";
import logo from "@salesforce/resourceUrl/cblogo";

export default class CbHome extends LightningElement {

	@track cblogo = logo;
	@track params = {};
	@track packageVersion = 0;

	connectedCallback() {
		this.getPackageVersion();
		loadStyle(this, home)
			.then(() => {
			});
	}


	getPackageVersion = () => {
		console.log('Get pacj num');
		getPackageVersionServer()
			.then(num => {
				console.log('Res = ' + num);
				this.packageVersion = num;
			})
			.catch(() => {
				console.log('ERRORO');
				this.packageVersion = 'demo org'
			})
	};
}