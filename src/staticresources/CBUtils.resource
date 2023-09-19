//CBUtils.js

let timerStartValue = 0;
let timerEndValue = 0;

const runTimer = () => {
	timerValue = performance.now();
	timerEndValue = 0;
}

const stopTimer = () => {
	timerEndValue = performance.now()
}

const getPerfomanceResult = () => {
	return timerEndValue - timerStartValue;
}
