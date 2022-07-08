//
//  AppDelegate.swift
//  MacProxyTool
//
//  Created by emerson on 2022/4/26.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate{
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 点击外部区域，关闭窗口
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown,.rightMouseDown] ){ [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarIcon"))
            button.action = #selector(togglePopover(_:))
        }
        
        popover.contentViewController = PopMenuViewController.initController()
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}

class VerticallyCenteredTextFieldCell: NSTextFieldCell {

    override func drawingRect(forBounds theRect: NSRect) -> NSRect {
        var newRect:NSRect = super.drawingRect(forBounds: theRect)
        let textSize:NSSize = self.cellSize(forBounds: theRect)
        let heightDelta:CGFloat = newRect.size.height - textSize.height
        if heightDelta > 0 {
            newRect.size.height = textSize.height
            newRect.origin.y += heightDelta * 0.5
        }
        return newRect
    }
}
