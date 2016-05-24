//
//  ResultWindowControler.swift
//  QingDict
//
//  Created by Ying on 12/3/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa
import WebKit


//TODO: refactor some logic to controller
class ResultWindow : NSPanel, WebFrameLoadDelegate
{
	@IBOutlet var titlebarAccCtrl: NSTitlebarAccessoryViewController!
	@IBOutlet var starPopoverCtrl: StarViewController!
	
	@IBOutlet weak var starBtn: NSButton!
	@IBOutlet var animWindow: NSPanel!
	@IBOutlet weak var animWindowText: NSTextField!
	@IBOutlet weak var webView: WebView!
	@IBOutlet weak var indicator: NSProgressIndicator!
	
	var word: String!
	var trans: String? = nil
	var pron: String? = nil
	
	var shouldAutoStar = false
	
	private var _qingDictStatusItemFrame: NSRect? = nil
	
	deinit
	{
		NSDistributedNotificationCenter.defaultCenter().removeObserver(self, name: "QingDict:StatusItemFrame", object: nil);
	}
	

	var stared: Bool
	{
		didSet
		{
			if starBtn != nil
			{
				starBtn.state = stared ? NSOnState : NSOffState
			}
		}
	}
	
	override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool)
	{
		stared = false

		super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer:flag)
		
		level = Int(CGWindowLevelForKey(.UtilityWindowLevelKey));
		
	}
	
	override func awakeFromNib()
	{
		titlebarAccCtrl.layoutAttribute = NSLayoutAttribute.Right;
		self.addTitlebarAccessoryViewController(titlebarAccCtrl);
		
		self.contentView!.wantsLayer = true;
		self.contentView!.layer?.backgroundColor = CGColorCreateGenericRGB(1, 1,1, 1)
		
		animWindow.contentView?.wantsLayer = true;
		animWindow.contentView?.layer?.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 0.3);
		animWindow.contentView?.layer?.cornerRadius = 9.5;
		animWindow.backgroundColor = NSColor.clearColor();
		animWindow.ignoresMouseEvents = true;
		animWindow.level = Int(CGWindowLevelForKey(CGWindowLevelKey.AssistiveTechHighWindowLevelKey));
		
		self.starPopoverCtrl.onConfirmStar = handleConfirmStar
		self.starPopoverCtrl.onDeleteStar = handleDeleteStar
		
		indicator.startAnimation(nil)
		
		NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ResultWindow.HandleDistNoti_GotStatusItemFrame(_:)), name: "QingDict:StatusItemFrame", object: nil, suspensionBehavior: NSNotificationSuspensionBehavior.DeliverImmediately)
		
		self.webView.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 9_0 like Mac OS X) AppleWebKit/601.1.16 (KHTML, like Gecko) Version/8.0 Mobile/13A171a Safari/600.1.4";
	}
	
	func HandleDistNoti_GotStatusItemFrame(noti: NSNotification)
	{
		Swift.print("ResultWindow.HandleDistNoti_GotStatusItemFrame")

		if let dict = noti.userInfo  as? [String: String]
		{
			if let rectStr = dict["frame"]
			{
				_qingDictStatusItemFrame = NSRectFromString(rectStr)
				Swift.print("HandleDistNoti_GotStatusItemFrame: \(_qingDictStatusItemFrame)")
			}
		}
	}
	
	private func postStarNoti()
	{
		NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:AddWordEntry", object: "QingDict-Result", userInfo: ["word": self.word, "trans": self.trans ?? ""], deliverImmediately: true)
	}
	
	private func handleConfirmStar(sender: StarViewController)
	{
		self.word = sender.txtWord.stringValue
		self.trans = sender.txtTrans.stringValue
		self.pron = sender.txtPron.stringValue
		
		animWindowText.stringValue = sender.txtWord.stringValue;
		let from = sender.txtWord.window!.convertRectToScreen(sender.txtWord.convertRect(sender.txtWord.bounds, toView: nil));
		animWindow.setFrame(NSRect(origin: CGPoint(x:from.origin.x - 4, y:from.origin.y - 1), size: self.animWindowText.frame.size), display: true)
		animWindow.orderFront(nil)
		
		stared = true;
		
		performSelector(#selector(ResultWindow.animateAnimWindow), withObject: nil, afterDelay: 0.1);
		
		postStarNoti()
	}
	
	private func handleDeleteStar(sender: StarViewController)
	{
		stared = false;
		NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:RemoveWordEntry", object: "QingDict-Result", userInfo: ["word": self.word], deliverImmediately: true)
		
	}
	
	func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!)
	{
		Swift.print("webView didFinishLoadForFrame: \(frame) *  \(sender.mainFrame)")
		
		indicator.stopAnimation(nil)
		indicator.hidden = true;
		
		starBtn.hidden = false;
		
		//FIXME: youdao.com始终不成立???
		//HACK: 用户可能将页面跳转到其他地方。始终尝试提起
		//if frame == webView.mainFrame
		//if trans == nil
		//{
			injectJsCss(); //由于有时候mainFrame可能很长时间无法加载完。。。so，无奈允许执行N次
		//}
		
		webView.hidden = false;
	}
	
	func loadUrl(url: String)
	{
		webView.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: url)!));
	}
	
	//TODO: customizations
	func injectJsCss()
	{
		//js
		//webView.stringByEvaluatingJavaScriptFromString("window.scrollTo(0,120)");
		
		//自动发音
		/*webView.stringByEvaluatingJavaScriptFromString("setTimeout(function(){" +
		"var prons = document.getElementsByClassName('pronounce');" +
		"if(prons.length > 0){ prons[prons.length -1].children[1].click(); }" +
		"}, 50)");*/
		
		//提取查询的单词
		let word = webView.stringByEvaluatingJavaScriptFromString("document.querySelector('#ec h2 span').innerText.trim()");
		if word.characters.count > 0
		{
			self.word = word
			Swift.print("ResultWindow.injectJsCss: extracted word: \(word)")
		}else
		{
			self.word = nil
			shouldAutoStar = false
			return;
		}
		
		//提取释义
		let trans = webView.stringByEvaluatingJavaScriptFromString("document.querySelector('#ec ul').innerText.trim()");
		if trans.characters.count > 0
		{
			self.trans = trans
			//Swift.print(trans)

		}else
		{
			self.trans = nil
			shouldAutoStar = false
			return;
		}
		
		//提取音标
		let pron = webView.stringByEvaluatingJavaScriptFromString("document.querySelector('#ec .phonetic').innerText");
		if pron.characters.count > 0
		{
			self.pron = pron;
		}else
		{
			self.pron = nil
		}
		
		if shouldAutoStar
		{
			postStarNoti()
			shouldAutoStar = false
		}
		
		//css
		let doc = webView.mainFrameDocument;
		let styleElem = doc.createElement("style");
		styleElem.setAttribute("type", value: "text/css")
		
		let cssText = doc.createTextNode("body{ background:#fff!important; font-family: 'PingFang SC'!important;} #ec>h2>span { font-family:serif; font-weight:100; font-size:24px; padding:0.5em 0 } #ec>h2>div{ font-size:12px !important; color:gray; } #bd{background:white;} #dictNav, .amend{ display:none; }");
		styleElem.appendChild(cssText)
		
		let headElem = doc.getElementsByTagName("head").item(0);
		headElem.appendChild(styleElem);
	}
 
	@IBAction func star(sender: AnyObject)
	{
		let btn =  sender as! NSButton;

		if starPopoverCtrl.shown
		{
			starPopoverCtrl.close();
		}
		else if self.word != nil
		{
			//TODO: temp
			starPopoverCtrl.txtWord.stringValue = self.word;
			starPopoverCtrl.txtTrans.stringValue = self.trans ?? ""
			starPopoverCtrl.txtPron.stringValue = self.pron ?? ""
			
			starPopoverCtrl.showRelativeToRect(btn.frame, ofView: btn, preferredEdge: NSRectEdge.MinY);
			
			
			//查询statusItem的位置
			NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:QueryStatusItemFrame", object: "QingDict-Result", userInfo: nil, deliverImmediately: true)
		}
		
		btn.state = stared ? NSOnState : NSOffState

	}
	
	func animateAnimWindow()
	{
		if _qingDictStatusItemFrame != nil
		{
			animWindow.setFrame(_qingDictStatusItemFrame!, display: true, animate: true);
		}

		animWindow.contentView?.animator().alphaValue = 0
		animWindow.performSelector(#selector(NSWindow.orderOut(_:)), withObject: nil, afterDelay: 1);
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override var canBecomeKeyWindow: Bool { return true }
	
	override var canBecomeMainWindow: Bool { return true }
	
}


class StarViewController : NSViewController, NSTextFieldDelegate
{
	@IBOutlet var popOver: NSPopover!
	
	@IBOutlet weak var txtWord: NSTextField!
	@IBOutlet weak var txtPron: NSTextField!
	@IBOutlet weak var txtTrans: NSTextField!

	var onConfirmStar: ((StarViewController)->())? = nil;
	var onDeleteStar: ((StarViewController)->())? = nil;
	
	
	func showRelativeToRect(rect: NSRect, ofView: NSView, preferredEdge: NSRectEdge)
	{
		popOver.showRelativeToRect(rect, ofView: ofView, preferredEdge: preferredEdge);
	}
	
	func close()
	{
		popOver.close()
	}
	
	var shown: Bool
	{
		return popOver.shown
	}
	
	override func viewDidAppear()
	{
		txtTrans.becomeFirstResponder();
		//txtWord.hidden = false;

	}
	
	@IBAction func confirmStar(sender: AnyObject)
	{
		popOver.close();
		
		onConfirmStar?(self);
	}
	
	@IBAction func deleteStar(sender: AnyObject)
	{
		close()
		onDeleteStar?(self);
	}
		
	func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool
	{
		var result = false
		
		if commandSelector == #selector(NSResponder.insertNewline(_:))
		{
			// new line action:
			// always insert a line-break character and don’t cause the receiver to end editing
			textView.insertNewlineIgnoringFieldEditor(nil)
			result = true
		}
		
		return result;
	}
	
	/*func animateAnimWindow()
	{
		animWindow.setFrame(NSRect(origin: CGPoint(x:1000, y:900 - animWindow.frame.height), size: animWindow.frame.size), display: true, animate: true);
	}*/
	
}
