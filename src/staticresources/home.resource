[app_flexipage-header_header-host]{ 
    display: none;
}

.slds-page-header.flexipageHeader { 
    display: none;
}

//////////////

*{ margin: 0; padding: 0;}

body {
	/*To hide the horizontal scroller appearing during the animation*/
	overflow: hidden;
}

.clouds{
	padding: 130px 0;
	background: #c9dbe9;
	background: -webkit-linear-gradient(top, #c9dbe9 0%, #fff 100%);
	background: -linear-gradient(top, #c9dbe9 0%, #fff 100%);
	background: -moz-linear-gradient(top, #c9dbe9 0%, #fff 100%);
}

/*Time to finalise the cloud shape*/
.cloud {
	width: 200px; height: 60px;
	background: #fff;
	
	border-radius: 200px;
	-moz-border-radius: 200px;
	-webkit-border-radius: 200px;
	
	position: relative; 
}

.cloud:before, .cloud:after {
	content: '';
	position: absolute; 
	background: #fff;
	width: 100px; height: 80px;
	position: absolute; top: -15px; left: 10px;
	
	border-radius: 100px;
	-moz-border-radius: 100px;
	-webkit-border-radius: 100px;
	
	-webkit-transform: rotate(30deg);
	transform: rotate(30deg);
	-moz-transform: rotate(30deg);
}

.cloud:after {
	width: 120px; height: 120px;
	top: -55px; left: auto; right: 15px;
}

/*Time to animate*/
.x1 {
	-webkit-animation: moveclouds 35s linear infinite;
	-moz-animation: moveclouds 35s linear infinite;
	-o-animation: moveclouds 35s linear infinite;
    opacity: 0.6; /*opacity proportional to the size*/
}

/*variable speed, opacity, and position of clouds for realistic effect*/
.x2 {
	left: 200px;
	-webkit-transform: scale(0.6);
	-moz-transform: scale(0.6);
	transform: scale(0.6);
	opacity: 0.5; /*opacity proportional to the size*/
	
	/*Speed will also be proportional to the size and opacity*/
	/*More the speed. Less the time in 's' = seconds*/
	-webkit-animation: moveclouds 40s linear infinite;
	-moz-animation: moveclouds 40s linear infinite;
	-o-animation: moveclouds 40s linear infinite;
}

.x3 {
	left: -250px; top: -200px;
	
	-webkit-transform: scale(0.8);
	-moz-transform: scale(0.8);
	transform: scale(0.8);
	opacity: 0.4; /*opacity proportional to the size*/
	
	-webkit-animation: moveclouds 45s linear infinite;
	-moz-animation: moveclouds 45s linear infinite;
	-o-animation: moveclouds 45s linear infinite;
}

.x4 {
	left: 470px; top: -250px;
	
	-webkit-transform: scale(0.75);
	-moz-transform: scale(0.75);
	transform: scale(0.75);
	opacity: 0.3; /*opacity proportional to the size*/
	
	-webkit-animation: moveclouds 50s linear infinite;
	-moz-animation: moveclouds 50s linear infinite;
	-o-animation: moveclouds 50s linear infinite;
}

.x5 {
	left: -150px; top: -150px;
	
	-webkit-transform: scale(0.8);
	-moz-transform: scale(0.8);
	transform: scale(0.8);
	opacity: 0.2; /*opacity proportional to the size*/
	
	-webkit-animation: moveclouds 60s linear infinite;
	-moz-animation: moveclouds 60s linear infinite;
	-o-animation: moveclouds 60s linear infinite;
}

@-webkit-keyframes moveclouds {
	0% {margin-left: 1200px;}
	100% {margin-left: -300px;}
}
@-moz-keyframes moveclouds {
	0% {margin-left: 1200px;}
	100% {margin-left: -300px;}
}
@-o-keyframes moveclouds {
	0% {margin-left: 1200px;}
	100% {margin-left: -300px;}
}
