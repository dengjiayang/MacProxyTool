//
//  ViewController.swift
//  MacProxyTool
//
//  Created by emerson on 2022/4/26.
//

import Cocoa

class ViewController: NSViewController {
    
    var textField : NSTextField?
    
    override open func loadView() {
        let view = NSView(frame: NSMakeRect(0, 0, 500, 300))
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField = NSTextField(frame: NSMakeRect(50, 200, 200, 50))
        view.addSubview(textField!)
        textField?.textColor = NSColor.yellow
        textField?.stringValue = "无StoryBoard测试"
        textField?.isEditable = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

