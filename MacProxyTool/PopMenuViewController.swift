//
//  PopMenuViewController.swift
//  MacProxyTool
//
//  Created by emerson on 2022/4/26.
//

import Cocoa
import ShellOut

var launchProxyStatus = false
var launchWhistleStatus = false
var clickWhistleCnt = 0
extension NSColor {
    convenience init(hex: String) {
        var hexString = hex
        if hex.starts(with: "#") {
            hexString = String(hex.dropFirst())
        }
        if let ui64 = UInt64(hexString, radix: 16) {
            self.init(hex: Int(ui64))
        } else {
            self.init(hex: 0)  // <--- black
        }
    }
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
}

typealias Task = (_ cancel: Bool) -> Void
/// 代码延迟运行
///
/// - Parameters:
///   - delayTime: 延时时间。比如：.seconds(5)、.milliseconds(500)
///   - qosClass: 要使用的全局QOS类（默认为 nil，表示主线程）
///   - task: 延迟运行的代码
/// - Returns: Task?
@discardableResult
func bk_delay(by delayTime: TimeInterval, qosClass: DispatchQoS.QoSClass? = nil, _ task: @escaping () -> Void) -> Task? {
    
    func dispatch_later(block: @escaping () -> Void) {
        let dispatchQueue = qosClass != nil ? DispatchQueue.global(qos: qosClass!) : .main
        dispatchQueue.asyncAfter(deadline: .now() + delayTime, execute: block)
    }
    
    var closure: (() -> Void)? = task
    var result: Task?
    
    let delayedClosure: Task = { cancel in
        if let internalClosure = closure {
            if !cancel {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    
    return result
    
}

/// 取消代码延时运行
func delayCancel(_ task: Task?) {
    task?(true)
}

var viewHeight = CGFloat(200)
var viewWidth = CGFloat(180)
var ipString = ""
var portString = ""
class PopMenuViewController: NSViewController {
    
    
    
    override open func loadView() {
        let view = NSView(frame: NSMakeRect(0, 0, viewWidth, viewHeight))
        self.view = view
        
    }

    
    var launchProxyImageView : NSImageView = {
        let imageView = NSImageView(frame: NSMakeRect(30,viewHeight / 2 + 35, 50, 50))
        imageView.image = NSImage(named: "proxy-off")
        imageView.isEditable = true
        imageView.allowsCutCopyPaste = false
        let tap = NSClickGestureRecognizer(target: self, action: #selector(launchProxy))
        let tapNap = NSClickGestureRecognizer(target: self, action: #selector(launchInput))
        
        tap.numberOfClicksRequired = 1
        tapNap.numberOfClicksRequired = 4
        
        imageView.addGestureRecognizer(tap)
        imageView.addGestureRecognizer(tapNap)
        
        return imageView
    }()
    
    var proxyTextField : NSTextField = {
        let textfield = NSTextField (frame: NSMakeRect(90, viewHeight / 2 + 35, 100, 50))
        textfield.cell = VerticallyCenteredTextFieldCell(textCell: "系统代理")
        textfield.isEditable = false
        textfield.backgroundColor = NSColor.clear
        return textfield
    }()
    
    var proxyStatusTextField : NSTextField = {
        let textfield = NSTextField (frame: NSMakeRect(90, viewHeight / 2 + 32, 100, 30))
        textfield.cell = VerticallyCenteredTextFieldCell(textCell: "成功状态")
        textfield.isEditable = false
        textfield.backgroundColor = NSColor.clear
        textfield.font = NSFont.init(name: "PingFangTC-Regular", size: 8)
        textfield.isHidden = true
        return textfield
    }()

    
    var launchWhistleImageView : NSImageView = {
        let imageView = NSImageView(frame: NSMakeRect(30, viewHeight / 2 - 25 , 50, 50))
        imageView.image = NSImage(named: "whistle-off")
        imageView.isEditable = true
        imageView.allowsCutCopyPaste = false
        let tap = NSClickGestureRecognizer(target: self, action: #selector(launchWhistle))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    var whistleTextField : NSTextField = {
        let textfield = NSTextField (frame: NSMakeRect(90, viewHeight / 2 - 25, 100, 50))
        textfield.cell = VerticallyCenteredTextFieldCell(textCell: "Whistle")
        textfield.isEditable = false
        textfield.backgroundColor = NSColor.clear
        return textfield
    }()
    
    var whistleStatusTextField : NSTextField = {
        let textfield = NSTextField (frame: NSMakeRect(90, viewHeight / 2 - 28, 80, 30))
        textfield.cell = VerticallyCenteredTextFieldCell(textCell: "成功状态")
        textfield.isEditable = false
        textfield.backgroundColor = NSColor.clear
        textfield.font = NSFont.init(name: "PingFangTC-Regular", size: 8)
        textfield.isHidden = true
        return textfield
    }()
    
    
    var inputIP01 : NSTextField = {
        let textField = NSTextField()
        textField.isBordered = true
        textField.backgroundColor = NSColor.clear
        textField.window?.makeFirstResponder(nil)
        textField.focusRingType = NSFocusRingType.init(rawValue: 1)!
        textField.placeholderString = "127"
        textField.frame = NSRect(x: 30, y: 40, width: 28, height: 20)
        textField.textColor = NSColor.white
        textField.font = NSFont.init(name: "Helvetica", size: 11)
        textField.isHidden = true
        textField.isEditable = true
        return textField
    }()
    var inputIP02 : NSTextField = {
        let textField = NSTextField()
        textField.isBordered = true
        textField.backgroundColor = NSColor.clear
        textField.window?.makeFirstResponder(nil)
        textField.focusRingType = NSFocusRingType.init(rawValue: 1)!
        textField.placeholderString = "127"
        textField.frame = NSRect(x: 60, y: 40, width: 28, height: 20)
        textField.textColor = NSColor.white
        textField.font = NSFont.init(name: "Helvetica", size: 11)
        textField.isHidden = true
        textField.isEditable = true
        return textField
    }()
    var inputIP03 : NSTextField = {
        let textField = NSTextField()
        textField.isBordered = true
        textField.backgroundColor = NSColor.clear
        textField.window?.makeFirstResponder(nil)
        textField.focusRingType = NSFocusRingType.init(rawValue: 1)!
        textField.placeholderString = "127"
        textField.frame = NSRect(x: 90, y: 40, width: 28, height: 20)
        textField.textColor = NSColor.white
        textField.font = NSFont.init(name: "Helvetica", size: 11)
        textField.isHidden = true
        textField.isEditable = true
        return textField
    }()
    var inputIP04 : NSTextField = {
        let textField = NSTextField()
        textField.isBordered = true
        textField.backgroundColor = NSColor.clear
        textField.window?.makeFirstResponder(nil)
        textField.focusRingType = NSFocusRingType.init(rawValue: 1)!
        textField.placeholderString = "127"
        textField.frame = NSRect(x: 120, y: 40, width: 28, height: 20)
        textField.textColor = NSColor.white
        textField.font = NSFont.init(name: "Helvetica", size: 11)
        textField.isHidden = true
        textField.isEditable = true
        return textField
    }()
    

    var inputPort : NSTextField = {
        let textField = NSTextField()
        textField.isBordered = true
        textField.backgroundColor = NSColor.clear
        textField.window?.makeFirstResponder(nil)
        textField.focusRingType = NSFocusRingType.init(rawValue: 1)!
        textField.placeholderString = "8899"
        textField.frame = NSRect(x: 30, y: 18, width: 60, height: 20)
        textField.textColor = NSColor.white
        textField.font = NSFont.init(name: "Helvetica", size: 11)
        textField.isHidden = true
        textField.isEditable = true
        return textField
    }()
    
    
    var helperView : NSView = {
        let view = NSView(frame: NSMakeRect(0, 0, viewWidth, viewHeight))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.9).cgColor
        view.isHidden = true
        return view
    }()
    
    var helperText : NSTextField = {
        let text = NSTextField(frame: NSMakeRect(5, 0, viewWidth - 5, viewHeight))
        text.isEditable = false
        text.isBordered = true
        text.window?.makeFirstResponder(nil)
        text.focusRingType = NSFocusRingType.init(rawValue: 1)!
        text.textColor = NSColor(hex: 0xffffff)
        text.font = NSFont.init(name: "PingFangTC", size: 11)
        text.cell = VerticallyCenteredTextFieldCell(textCell:
                                                        "1. 单击代理图标可开关代理；          2. 四次快速点击代理图标可自定义IP地址和端口号；                           3. Whistle因为内置终端问题暂无法解决Node.js的调用问题，故搁置；                                      4. 已知亮色模式下可能会有文字显示问题                                    5. Version:0.2.0；                      6. Q: friend@dengjiayang.cn"
        )
        return text
    }()
    
    
    var quitImageView : NSImageView = {
        let imageView = NSImageView(frame: NSMakeRect(viewWidth - 25 - 25, 5 , 15, 15))
        imageView.image = NSImage(named: "close")
        imageView.isEditable = false
        imageView.allowsCutCopyPaste = false
        let tap = NSClickGestureRecognizer(target: self, action: #selector(goQuit))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    var helperImageView : NSImageView = {
        let imageView = NSImageView(frame: NSMakeRect(viewWidth - 25, 5 , 15, 15))
        imageView.image = NSImage(named: "help")
        imageView.isEditable = false
        imageView.allowsCutCopyPaste = false
        let tap = NSClickGestureRecognizer(target: self, action: #selector(helperAction))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(launchProxyImageView)
        view.addSubview(proxyTextField)
        view.addSubview(proxyStatusTextField)
        
        view.addSubview(launchWhistleImageView)
        view.addSubview(whistleTextField)
        view.addSubview(whistleStatusTextField)
        
        view.addSubview(inputIP01)
        view.addSubview(inputIP02)
        view.addSubview(inputIP03)
        view.addSubview(inputIP04)
        view.addSubview(inputPort)
        
        
        view.addSubview(helperImageView)
        view.addSubview(quitImageView)
        
        view.addSubview(helperView)
        self.helperView.addSubview(self.helperText)
    }
    
    @objc func launchProxy() {
        launchProxyStatus = !launchProxyStatus
        var shellOutResult = (false,"null")
        if(!self.inputIP01.stringValue.isEmpty && !self.inputIP02.stringValue.isEmpty && !self.inputIP04.stringValue.isEmpty && !self.inputIP03.stringValue.isEmpty) {
            ipString = self.inputIP01.stringValue + "." + self.inputIP02.stringValue + "." + self.inputIP03.stringValue + "." + self.inputIP04.stringValue
        }
        
        portString = self.inputPort.stringValue
        print("这里是ip组成:\(ipString)")
        print("这里是port组成:\(portString)")
        if (launchProxyStatus) {
            self.launchProxyImageView.image = NSImage(named: "proxy-on")
            print("启动代理")
            if(!ipString.isEmpty && !portString.isEmpty) {
                shellOutResult = dealProxyCommandLine(networkStatus: "on", ipString: ipString, portString: portString)
            } else {
                shellOutResult = dealProxyCommandLine(networkStatus: "on", ipString: "", portString: "")
            }
        } else {
            self.launchProxyImageView.image = NSImage(named: "proxy-off")
            print("关闭代理")
            shellOutResult = dealProxyCommandLine(networkStatus: "off", ipString: "", portString: "")
        }
        if(shellOutResult.0 == true) {
            self.proxyStatusTextField.isHidden = false
            var noticeText = "代理打开成功"
            if(!ipString.isEmpty) {
                noticeText = "IP:Port 操作成功"
            }
            if(!launchProxyStatus) {
                noticeText = "代理关闭成功"
            }

            self.proxyStatusTextField.stringValue = noticeText
            bk_delay(by: 1) {
                self.proxyStatusTextField.isHidden = true
            }
        } else {
            self.proxyStatusTextField.isHidden = false
            self.proxyStatusTextField.stringValue = "操作失败"
            launchProxyStatus = false
            self.launchProxyImageView.image = NSImage(named: "proxy-off")
            bk_delay(by: 1) {
                self.proxyStatusTextField.isHidden = true
            }
        }
        print("命令行结果:", shellOutResult)
    }
    
    func inputHidden() {
        self.inputIP01.isHidden = false
        self.inputIP02.isHidden = false
        self.inputIP03.isHidden = false
        self.inputIP04.isHidden = false
        self.inputPort.isHidden = false
    }
    
    @objc func launchInput() {
        inputHidden()
        launchProxyStatus = false
        self.launchProxyImageView.image = NSImage(named: "proxy-off")
        self.proxyStatusTextField.stringValue = "自定义IP已启用"
    }
    
    
    @objc func launchWhistle() {
        clickWhistleCnt += 1
        print("版本号:\(NSApplication.version())")
        launchWhistleStatus = !launchWhistleStatus
        var shellOutResult = (false,"null")
        if (launchWhistleStatus) {
            self.launchWhistleImageView.image = NSImage(named: "whistle-on")
            print("启动")
            shellOutResult = dealWhistleCommandLine(whistleStatus: "start")
        } else {
            self.launchWhistleImageView.image = NSImage(named: "whistle-off")
            print("关闭")
            shellOutResult = dealWhistleCommandLine(whistleStatus: "stop")
        }
        if(shellOutResult.0 == true) {
            self.whistleStatusTextField.isHidden = false
            self.whistleStatusTextField.stringValue = "操作成功"
            bk_delay(by: 1) {
                self.whistleStatusTextField.isHidden = true
            }
        } else {
            self.whistleStatusTextField.isHidden = false
            self.whistleStatusTextField.stringValue = "暂未开放..."
            launchWhistleStatus = false
            self.launchWhistleImageView.image = NSImage(named: "whistle-off")
            bk_delay(by: 1) {
                self.whistleStatusTextField.isHidden = true
            }
        }
        if(clickWhistleCnt == 5) {
            self.whistleStatusTextField.stringValue = "点了\(clickWhistleCnt)次"
        } else if(clickWhistleCnt > 5) {
            self.whistleStatusTextField.stringValue = "求你别点了,\(clickWhistleCnt)次"
        }
        
        print("命令行结果:", shellOutResult)
    }
    
    @objc func goQuit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func helperAction() {
        self.helperView.isHidden = !self.helperView.isHidden
        self.helperView.window?.makeKeyAndOrderFront(nil)
        self.helperImageView.removeFromSuperview()
        if(self.helperView.isHidden) {
            self.view.addSubview(self.helperImageView)
        } else {
            self.helperView.addSubview(self.helperImageView)
            self.helperImageView.window?.makeFirstResponder(nil)
        }
    }
}

func dealProxyCommandLine(networkStatus:String, ipString:String, portString:String) -> (status:Bool, shellOutContent:String){
    var status = false
    var shellOutContent = ""
    do {
        
        let networkService = try shellOut(to:"networksetup -listallnetworkservices | grep 'Wi'")
        let startHTTPCommandString = "networksetup -setwebproxystate \(networkService) \(networkStatus)"
        let startHTTPSCommandString = "networksetup -setsecurewebproxystate \(networkService) \(networkStatus)"
        
        if(!ipString.isEmpty && !portString.isEmpty) {
            let configHTTPIPString = "networksetup -setwebproxy \(networkService) \(ipString) \(portString)"
            let configHTTPSIPString = "networksetup -setsecurewebproxy \(networkService) \(ipString) \(portString)"
            shellOutContent = try shellOut(to:[configHTTPIPString,configHTTPSIPString])
        }
        shellOutContent = try shellOut(to:[startHTTPCommandString,startHTTPSCommandString])
        status = true
    } catch {
        let error = error as! ShellOutError
        status = false
        print(error.message) // Prints STDERR
        print(error.output) // Prints STDOUT
    }
    return (status, shellOutContent)
}

func dealWhistleCommandLine(whistleStatus:String) -> (status:Bool, shellOutContent:String){
    var status = false
    let shellOutContent = ""
    
    let whistleService = runCommand("/usr/local/bin/node /usr/local/bin/w2 \(whistleStatus)", needAuthorize: false)
    status = whistleService.isSuccess

    return (status, shellOutContent)
}





extension PopMenuViewController {
    static func initController() -> PopMenuViewController {
        let viewcontroller = PopMenuViewController()
        return viewcontroller
    }
}

private func runCommand(_ command: String, needAuthorize: Bool) -> (isSuccess: Bool, executeResult: String?) {
    let scriptWithAuthorization = """
    do shell script "\(command)" with administrator privileges
    """
    
    let scriptWithoutAuthorization = """
    do shell script "\(command)"
    """
    
    let script = needAuthorize ? scriptWithAuthorization : scriptWithoutAuthorization
    let appleScript = NSAppleScript(source: script)
    
    var error: NSDictionary? = nil
    let result = appleScript!.executeAndReturnError(&error)
    if let error = error {
        print("执行 \(command)命令出错:")
        print(error)
        return (false, nil)
    }
    
    return (true, result.stringValue)
}

private func runCommandWithURL(_ command: URL, needAuthorize: Bool) -> (isSuccess: Bool, executeResult: String) {

    var message = "";
    do {
        // 这里的 URL 是 shell 脚本的路径
        let task = try NSUserAppleScriptTask.init(url: command)
        task.execute(withAppleEvent: nil) { (result, error) in
            message = result?.stringValue ?? ""
            // error.debugDescription 也是执行结果的一部分，有时候超时或执行 shell 本身返回错误，而我们又需要打印这些内容的时候，就需要用到它。
            print(message)
            message = message.count == 0 ? error.debugDescription : message
            
        }
    } catch {
        // 执行的相关错误
        print("运行\(command)文件出错:")
        print(error)
        return (false, "")
    }
    
    return (true, message)
}
