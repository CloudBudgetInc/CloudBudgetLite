import {api, LightningElement, track} from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJS';
import {loadScript} from 'lightning/platformResourceLoader';

export default class CbChart extends LightningElement {
	@api chartConfig;

	@track isChartJsInitialized;
	@track chartPlaceHolder = `To remove this placeholder, go to SETUP, open "Session Settings"and check "Use Lightning Web Security for Lightning web components" under "Lightning Web Security" and Save`;
	@track showPlaceHolder = false;
	@track showChart = true;

	renderedCallback() {
		if (this.isChartJsInitialized) {
			return;
		}
		Promise.all([loadScript(this, chartjs)])
			.then(() => {
				this.isChartJsInitialized = true;
				const ctx = this.template.querySelector('canvas.barChart').getContext('2d');
				this.chart = new window.Chart(ctx, JSON.parse(JSON.stringify(this.chartConfig)));
			})
			.catch(e => {
				this.showPlaceHolder = true;
				this.showChart = false;
			});
	}
}