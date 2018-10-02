function openLink(_url,_str){
	var openF = window.confirm(_str);
	if(openF){
		window.open(_url);
		return true;
	}else{
		return false;
	}
}
window.fbAsyncInit = function() {
	FB.init({
		appId            : '104878893409907',
		autoLogAppEvents : true,
		xfbml            : true,
		version          : 'v2.9'
	});
	FB.AppEvents.logPageView();
};

(function(d, s, id){
	var js, fjs = d.getElementsByTagName(s)[0];
	if (d.getElementById(id)) {return;}
	js = d.createElement(s); js.id = id;
	js.src = "//connect.facebook.net/en_US/sdk.js";
	fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
