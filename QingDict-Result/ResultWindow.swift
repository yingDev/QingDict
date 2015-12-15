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
	
	var word: String!
	var trans: String? = nil
	var pron: String? = nil
	
	//TODO: impl
	var stared: Bool = false;
	//var wordEntry: WordEntry?;
	
	override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool)
	{
		
		super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, `defer`: flag)
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
		
		starBtn.state = NSOnState;
		
		stared = true;
		
		performSelector(Selector("animateAnimWindow"), withObject: nil, afterDelay: 0.1);
		
		NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:AddWordEntry", object: "QingDict-Result", userInfo: ["word": self.word, "trans": self.trans ?? ""], deliverImmediately: true)
	}
	
	private func handleDeleteStar(sender: StarViewController)
	{
		starBtn.state = NSOffState;
		stared = false;
	}
	
	func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!)
	{
		Swift.print("webView didFinishLoadForFrame: \(frame) *  \(sender.mainFrame)")
		
		starBtn.hidden = false;
		
		//FIXME: youdao.com始终不成立???
		//if frame == webView.mainFrame
		if trans == nil
		{
			injectJsCss(); //由于有时候mainFrame可能很长时间无法加载完。。。so，无奈允许执行N次
		}
		
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
		webView.stringByEvaluatingJavaScriptFromString("document.getElementById('ads').remove();" +										                           "document.getElementById('topImgAd').remove();" +
			"window.scrollTo(115,92)");
		//自动发音
		/*webView.stringByEvaluatingJavaScriptFromString("setTimeout(function(){" +
		"var prons = document.getElementsByClassName('pronounce');" +
		"if(prons.length > 0){ prons[prons.length -1].children[1].click(); }" +
		"}, 50)");*/
		
		//提取查询的单词
		let word = webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('keyword')[0].innerText.trim()");
		if word.characters.count > 0
		{
			self.word = word
		}
		
		//提取释义
		let trans = webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('trans-container')[0].children[0].innerText.trim()");
		if trans.characters.count > 0
		{
			self.trans = trans
			Swift.print(trans)

		}
		
		//提取音标
		let pron = webView.stringByEvaluatingJavaScriptFromString("/\\[.*\\]/g.exec(document.getElementsByClassName('pronounce')[1].innerText)[0]");
		if pron.characters.count > 0
		{
			self.pron = pron;
		}
		
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
	}
 
	//todo： 实现自定义的按钮，用于正确处理验证
	@IBAction func star(sender: AnyObject)
	{
		let btn =  sender as! NSButton;
		
		if starPopoverCtrl.shown
		{
			starPopoverCtrl.close();
			btn.state = stared ? NSOnState : NSOffState;
		}
		else if self.word != nil
		{
			//TODO: temp
			starPopoverCtrl.txtWord.stringValue = self.word;
			starPopoverCtrl.txtTrans.stringValue = self.trans ?? ""
			starPopoverCtrl.txtPron.stringValue = self.pron ?? ""
			
			starPopoverCtrl.showRelativeToRect(btn.frame, ofView: btn, preferredEdge: NSRectEdge.MinY);
			
			btn.state = NSOnState;
		}
		
	}
	
	func animateAnimWindow()
	{
		animWindow.setFrame(NSRect(origin: CGPoint(x:990, y:900 - animWindow.frame.height), size: animWindow.frame.size), display: true, animate: true);
		animWindow.contentView?.animator().alphaValue = 0
		animWindow.performSelector(Selector("orderOut:"), withObject: nil, afterDelay: 0.3);
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override var canBecomeKeyWindow: Bool { return true }
	
	override var canBecomeMainWindow: Bool { return true }
	
	deinit
	{
		Swift.print("ResultWindow.deinit")
	}
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
		/*animWindowText.stringValue = txtWord.stringValue;
		//txtWord.hidden = true;
		
		//animWindow.backgroundColor = NSColor.clearColor()
		animWindow.ignoresMouseEvents = true;
		animWindow.level = Int(CGWindowLevelForKey(CGWindowLevelKey.AssistiveTechHighWindowLevelKey));
		
		let winFrame = txtWord.window!.frame;
		let textFrame = animWindowText.frame;
		
		let from = txtWord.window!.convertRectToScreen(NSRect(x: winFrame.width/2 - textFrame.width/2, y: -textFrame.height, width: textFrame.width, height: textFrame.height));//txtWord.convertRect(txtWord.bounds, toView: nil));
		
		animWindow.setFrame(from, display: false);
		animWindow.orderFront(nil)*/

		popOver.close();
		
		//performSelector(Selector("animateAnimWindow"), withObject: nil, afterDelay: 0.25);

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
		
		if commandSelector == Selector("insertNewline:")
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
