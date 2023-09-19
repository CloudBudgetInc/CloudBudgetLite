/**
 * Catalog of CA functions
 */
const funcCatalog = {
	spread: (context) => context.exampleAmounts.forEach(a => {
		if (a.disabled) return;
		a[context.field] = context.baseAmount
	}),
	splitBY: (context) => {
		let BYTotal = 0;
		context.exampleAmounts.forEach(a => {
			if (a.disabled) return;
			a[context.field] = parseFloat((context.baseAmount / context.exampleAmounts.length).toFixed(2));
			BYTotal += +a[context.field];
		});
		context.exampleAmounts[0][context.field] += parseFloat((context.baseAmount - BYTotal).toFixed(2));
	},
	multiplyBy: (context) => context.exampleAmounts.forEach(a => {
		if (a.disabled) return;
		a[context.field] *= context.baseAmount
	}),
	add: (context) => context.exampleAmounts.forEach(a => {
		if (a.disabled) return;
		a[context.field] += +context.baseAmount
	}),
};

const calculateExampleTotal = (context) => {
	context.exampleTotal = 0;
	context.exampleAmounts.forEach(a => context.exampleTotal += +a[context.field]);
};

export {
	funcCatalog, calculateExampleTotal
};