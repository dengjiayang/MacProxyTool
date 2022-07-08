//
//  main.swift
//  MacProxyTool
//
//  Created by emerson on 2022/4/26.
//

import Foundation
import Cocoa

autoreleasepool {() ->() in
    let application = NSApplication.shared
    let appDelegate = AppDelegate()
    application.delegate = appDelegate
    application.run()
}
