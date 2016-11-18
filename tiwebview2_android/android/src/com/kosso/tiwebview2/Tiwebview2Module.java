/*

com.kosso.tiwebview2
===================================================
Attempting to add support for 'postMessage' communication between remote HTML and an app Ti.UI.webView wrapper.

@ Kosso : 2016

- Added : enablePostMessage method. Creates an 'Android' JavascriptInterface method 'postMessage'.

- In Remote HTML/JS use: 

`Android.postMessage(JSON.stringify({foo:'bar'}), '*');`

NB: The message needs to be stringified. 

- Titanium app JS use: eg: 
```
var webview2module - require('com.kosso.tiwebview2');

webview2module.addEventListener('message', function(e) {
  console.log("Android module message:");
  // NB: The message will be a JSON string, so will need parsing to an object.
  console.log(JSON.parse(e.message));
});
```

NB: For this to work, for some reason the webview needs a second load. (Probably easy to fix. Though I have no idea!)
So, create the Ti.UI.Webview first with 'html' set to blank (and no 'url'), then set the url in the webView's 'load' event.
At that time, also apply `webview2module.enablePostMessage(theNameOfYourTiWebView)`


*/


package com.kosso.tiwebview2;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;

import org.appcelerator.titanium.TiApplication;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.kroll.common.TiConfig;

import org.appcelerator.kroll.KrollDict;
import ti.modules.titanium.ui.WebViewProxy;
import ti.modules.titanium.ui.widget.webview.TiUIWebView;

import android.webkit.WebView;
import android.webkit.JavascriptInterface;

@Kroll.module(name="Tiwebview2", id="com.kosso.tiwebview2")
public class Tiwebview2Module extends KrollModule
{

	private static final String LCAT = "Tiwebview2Module";

	public Tiwebview2Module()
	{
		super();
	}

	@Kroll.onAppCreate
	public static void onAppCreate(TiApplication app)
	{
		Log.d(LCAT, "inside onAppCreate");
		// put module init code that needs to run when the application is created
	}
	
}

