//
//  AppDelegate.swift
//  QingDict-Result
//
//  Created by Ying on 12/7/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa
import WebKit

@NSApplicationMain
class ResultAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate
{

	@IBOutlet weak var window: ResultWindow!
	
	var timeWindowShown: CFAbsoluteTime = 0

	func applicationDidFinishLaunching(aNotification: NSNotification)
	{
		if Process.arguments.count < 2
		{
			NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
			return;
		}
		
		let keyword = Process.arguments[1];
		
		if let encoded = keyword.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
		{
			let url = "http://dict.youdao.com/search?q=\(encoded)";

			self.window!.loadUrl(url);
			self.window!.title = keyword;

			performSelector(Selector("followCursor"), withObject: nil, afterDelay: 0);
		}else
		{
			NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
		}
	}
	
	/*func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!)
	{
		print("webView didFinishLoadForFrame: \(frame) *  \(sender.mainFrame)")
		
		window.starBtn.hidden = false;
		
		//FIXME: youdao.com始终不成立???
		//if frame == webView.mainFrame
		if !transExtracted
		{
			injectJsCss(); //由于有时候mainFrame可能很长时间无法加载完。。。so，无奈允许执行N次
		}
		
		webView.hidden = false;
	}
	
	func loadUrl(url: String)
	{
		webView.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: url)!));
	}
	
	//todo: customizations
	func injectJsCss()
	{
		//js
		webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ads').remove();" +										                           "document.getElementById('topImgAd').remove();" +
													   "window.scrollTo(115,92)");
		//自动发音
		/*webView.stringByEvaluatingJavaScriptFromString("setTimeout(function(){" +
				"var prons = document.getElementsByClassName('pronounce');" +
				"if(prons.length > 0){ prons[prons.length -1].children[1].click(); }" +
				"}, 50)");*/
		
		//提取释义
		let trans = webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('trans-container')[0].children[0].innerText.trim()");
		if trans.characters.count > 0
		{
			transExtracted = true;
			
			NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:AddWordEntry", object: "QingDict-Result", userInfo: ["word": word, "trans": trans], deliverImmediately: true)
		}
		print(trans)

		//css
		let doc = webView.mainFrameDocument;
		let styleElem = doc.createElement("style");
		styleElem.setAttribute("type", value: "text/css")
		
		let cssText = doc.createTextNode("body{ background:#fefefe!important; }" +
									     "#wordbook, .c-subtopbar, #ads, #topImgAd{display:none!important;}" +
									     "#custheme{background:transparent!important;}"
										);
		styleElem.appendChild(cssText)
		
		let headElem = doc.getElementsByTagName("head").item(0);
		headElem.appendChild(styleElem);
	}*/
	
	//NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:AddWordEntry", object: "self", userInfo: ["word": str, "trans": "你好"], deliverImmediately: true)

	
	func followCursor()
	{
		print("followCursor");
		let winSize = self.window!.frame.size;
		let cursorPos = NSEvent.mouseLocation();
		self.window!.setFrame(NSRect(x: cursorPos.x + 8, y: cursorPos.y - 8 - winSize.height,
			width: winSize.width, height: winSize.height),
			display: false);
		
		self.window!.makeKeyAndOrderFront(nil);
		
		timeWindowShown = CFAbsoluteTimeGetCurrent()
		//NSApp.activateIgnoringOtherApps(true);
	}
	
	func windowDidResignKey(notification: NSNotification)
	{
		print("windowDidResignKey");
		
		if CFAbsoluteTimeGetCurrent() - timeWindowShown > 0.5
		{
			NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
		}
		
		print("not time")
		self.window!.makeKeyAndOrderFront(nil);
	}
	
	deinit
	{
		print("AppDelegate.deinit");
	}

}

