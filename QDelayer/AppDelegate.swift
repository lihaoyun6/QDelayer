//
//  AppDelegate.swift
//  QDelayer
//
//  Created by apple on 2022/9/16.
//

import Cocoa
import HotKey
import ServiceManagement

//扩展本地化字符串功能
extension String {
    var local: String { return NSLocalizedString(self, comment: "") }
}

//扩展Bundle类
extension Bundle {
    var name: String? {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String { if name != "" { return name } }
        return object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    var fApp = ""
    var count = 0
    var timer: Timer?
    var HUD: NSWindow?
    var keydown = false
    var foundHelper = false
    var anima = UserDefaults.standard.bool(forKey: "anima")
    var disable = UserDefaults.standard.bool(forKey: "disable")
    var doubleQ = UserDefaults.standard.bool(forKey: "doubleQ")
    var blockCmdW = UserDefaults.standard.bool(forKey: "blockCmdW")
    var whiteMode = UserDefaults.standard.bool(forKey: "whiteMode")
    var delay = (UserDefaults.standard.object(forKey: "delay") ?? 50) as! Int
    var delayW = (UserDefaults.standard.object(forKey: "delayW") ?? 400000) as! Int
    var blackList = (UserDefaults.standard.array(forKey: "blackList") ?? []) as! [String]
    var statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let menu = NSMenu()
    let text = NSTextField()
    let labelQ = "按住 ⌘Q 退出当前程序".local
    let labelQD = "再次按下 ⌘Q 退出程序".local
    let labelWD = "再次按下 ⌘W 关闭窗口".local
    let textFont = NSFont.boldSystemFont(ofSize: 40.0)
    let QuitKey = HotKey(key: .q, modifiers: [.command])
    let CloseKey = HotKey(key: .w, modifiers: [.command])
    let helperBundleName = "com.lihaoyun6.QDelayerLoginHelper"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //启动时暂停快捷键
        QuitKey.isPaused = true
        CloseKey.isPaused = true
        
        //获取自启代理状态
        foundHelper = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == helperBundleName }
        
        //初始化
        menuIcon()
        menuWillOpen(menu)
        initHUD()

        //转换参数, 保持旧版兼容性
        if delay < 50 { delay = 50 }
        //选择性开启快捷键
        if !disable { QuitKey.isPaused = false; if blockCmdW {CloseKey.isPaused = false}; startTimer() }

        QuitKey.keyDownHandler = {
            self.keydown = true
            self.count += 1
            //let fApp = self.getAppName(NSWorkspace.shared.frontmostApplication?.bundleURL)
            //if (self.whiteMode && !self.blackList.contains(fApp)) || (!self.whiteMode && self.blackList.contains(fApp)) {
            //    NSWorkspace.shared.frontmostApplication?.terminate()
            //    return
            //}
            self.text.stringValue = self.labelQ
            if self.anima { self.text.stringValue = "⬜️ " + self.labelQ + " ⬜️" }
            if self.doubleQ { self.text.stringValue = self.labelQD }
            
            self.setTextWidth(self.text.stringValue)
            self.HUD?.makeKeyAndOrderFront(self)
            
            Thread.detachNewThread {
                if self.doubleQ {
                    self.stopTimer()
                    self.QuitKey.isPaused = true
                    usleep(UInt32(self.delayW))
                    self.QuitKey.isPaused = false
                    DispatchQueue.main.async(execute: { self.HUD?.close() })
                    self.startTimer()
                }else{
                    let range = self.delay
                    for i in 1...range-10 {
                        if !self.keydown { return }
                        if self.anima {
                            switch(i){
                            case _ where i <= Int(Double(range)*0.25):
                                self.updateLabel("⬜️ " + self.labelQ + " ⬜️")
                            case _ where i <= Int(Double(range)*0.50):
                                self.updateLabel("◻️ " + self.labelQ + " ◻️")
                            case _ where i <= Int(Double(range)*0.75):
                                self.updateLabel("◽️ " + self.labelQ + " ◽️")
                            case _ where i <= Int(Double(range)*0.98):
                                self.updateLabel("▫️ " + self.labelQ + " ▫️")
                            default:
                                self.updateLabel(self.labelQ)
                            }
                        }
                        if i >= range-10 {
                            NSWorkspace.shared.frontmostApplication?.terminate()
                            DispatchQueue.main.async(execute: { self.HUD?.close() })
                        }
                        usleep(10000)
                    }
                }
            }
        }
        QuitKey.keyUpHandler = {
            self.keydown = false
            if !self.doubleQ { self.HUD?.close() }
        }
        
        CloseKey.keyDownHandler = {
            self.count += 1
            self.text.stringValue = self.labelWD
            self.setTextWidth(self.text.stringValue)
            self.HUD?.makeKeyAndOrderFront(self)
            
            Thread.detachNewThread {
                self.stopTimer()
                self.CloseKey.isPaused = true
                usleep(UInt32(self.delayW))
                self.CloseKey.isPaused = false
                DispatchQueue.main.async(execute: { self.HUD?.close() })
                self.startTimer()
            }
        }
    
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer(timeInterval: 0.1, repeats: true, block: {timer in self.loopFireHandler(timer)})
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    @objc func loopFireHandler(_ timer: Timer?) -> Void {
        fApp = getAppName(NSWorkspace.shared.frontmostApplication?.bundleURL)
        if whiteMode {
            if !blackList.contains(fApp) {
                if !QuitKey.isPaused { QuitKey.isPaused = true }
                if !CloseKey.isPaused { CloseKey.isPaused = true }
            }else{
                if QuitKey.isPaused { QuitKey.isPaused = false }
                if CloseKey.isPaused && blockCmdW { CloseKey.isPaused = false }
            }
        }else{
            if blackList.contains(fApp) {
                if !QuitKey.isPaused { QuitKey.isPaused = true }
                if !CloseKey.isPaused { CloseKey.isPaused = true }
            }else{
                if QuitKey.isPaused { QuitKey.isPaused = false }
                if CloseKey.isPaused && blockCmdW { CloseKey.isPaused = false }
            }
        }
    }

    //初始化菜单栏按钮
    func menuIcon(){
        if let button = statusItem.button {
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.image = NSImage(named:NSImage.Name("MenuBarIcon\(NSNumber(value: !disable).intValue)"))
        }
    }
    
    //菜单栏按钮左右键响应
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            setDisable()
        } else {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        }
    }
    
    //生成主菜单
    func menuWillOpen(_ menu: NSMenu) {
        let fApp = getAppName(NSWorkspace.shared.frontmostApplication?.bundleURL)
        let options = NSMenu()
        let choose = NSMenu()
        menu.removeAllItems()
        menu.delegate = self
        //choose.autoenablesItems = false
        let Switch = menu.addItem(withTitle: "\(fApp): \(getEnableText(fApp))", action: #selector(addToList(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: String(format: "已拦截 %d 次".local, count), action: nil, keyEquivalent: "")
        menu.setSubmenu(options, for: menu.addItem(withTitle: "偏好设置...".local, action: nil, keyEquivalent: ""))
        options.addItem(withTitle: "登录时启动".local, action: #selector(setRunAtLogin(_:)), keyEquivalent: "").state = state(foundHelper)
        options.addItem(NSMenuItem.separator())
        options.addItem(withTitle: "白名单模式".local, action: #selector(setWhiteMode(_:)), keyEquivalent: "").state = state(whiteMode)
        options.addItem(withTitle: "倒计时动画".local, action: #selector(setAnima(_:)), keyEquivalent: "").state = state(anima)
        options.addItem(withTitle: "拦截 ⌘W 键".local, action: #selector(setCmdW(_:)), keyEquivalent: "").state = state(blockCmdW)
        options.addItem(withTitle: "双击代替长按".local, action: #selector(setDoubleQ(_:)), keyEquivalent: "").state = state(doubleQ)
        options.addItem(NSMenuItem.separator())
        options.setSubmenu(choose, for: options.addItem(withTitle: "延时设置...".local, action: nil, keyEquivalent: ""))
        if !doubleQ {
            choose.addItem(withTitle: "长按延时:".local, action: nil, keyEquivalent: "").target = self
            //choose.addItem(withTitle: "1s        2s        3s        4s", action: nil, keyEquivalent: "").isEnabled = false
            choose.addItem(withTitle: "0.5s    1.0s    1.5s    2.0s", action: nil, keyEquivalent: "").isEnabled = false
            let menuSliderItem = NSMenuItem()
            let menuSlider = NSSlider.init(frame: NSRect(x: 16, y: 0, width: choose.size.width-30, height: 32))
            let view = NSView.init(frame: NSRect(x: 0, y: 0, width: choose.size.width, height: 32))
            view.addSubview(menuSlider)
            menuSlider.sliderType = NSSlider.SliderType.linear
            menuSlider.isContinuous = true
            menuSlider.action = #selector(sliderValueChanged(_:))
            menuSlider.minValue = 50
            menuSlider.maxValue = 200
            menuSlider.intValue = Int32(delay)
            menuSlider.numberOfTickMarks = 4
            menuSlider.allowsTickMarkValuesOnly = true
            menuSliderItem.view = view
            choose.addItem(menuSliderItem)
        }
        if blockCmdW || doubleQ {
            choose.addItem(NSMenuItem.separator())
            choose.addItem(withTitle: "双击间隔:".local, action: nil, keyEquivalent: "")
            choose.addItem(withTitle: "0.4s    0.6s    0.8s    1.0s", action: nil, keyEquivalent: "").isEnabled = false
            let menuSliderItem = NSMenuItem()
            let menuSlider = NSSlider.init(frame: NSRect(x: 16, y: 0, width: choose.size.width-30, height: 32))
            let view = NSView.init(frame: NSRect(x: 0, y: 0, width: choose.size.width, height: 32))
            view.addSubview(menuSlider)
            menuSlider.sliderType = NSSlider.SliderType.linear
            menuSlider.isContinuous = true
            menuSlider.action = #selector(sliderValueChanged(_:))
            menuSlider.minValue = 400000
            menuSlider.maxValue = 1000000
            menuSlider.intValue = Int32(delayW)
            menuSlider.numberOfTickMarks = 4
            menuSlider.allowsTickMarkValuesOnly = true
            menuSliderItem.view = view
            choose.addItem(menuSliderItem)
        }
        menu.addItem(withTitle: "关于 QDelayer".local, action: #selector(aboutDialog(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出".local, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        Switch.isEnabled = !disable
        Switch.state = state(!blackList.contains(fApp))
        if whiteMode { Switch.state = state(blackList.contains(fApp)) }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
    
    //总开关
    func setDisable() {
        disable.toggle()
        statusItem.button?.image = NSImage(named:NSImage.Name("MenuBarIcon\(NSNumber(value: !disable).intValue)"))
        UserDefaults.standard.set(disable, forKey: "disable")
        if disable { stopTimer(); QuitKey.isPaused = true; CloseKey.isPaused = true } else { QuitKey.isPaused = false; if blockCmdW {CloseKey.isPaused = false}; startTimer() }
    }
    
    //将Bool值转换为NSControl.StateValue
    func state(_ input: Bool) -> NSControl.StateValue {
        if input { return NSControl.StateValue.on }
        return NSControl.StateValue.off
    }
    
    //获取App名称
    func getAppName(_ appUrl: URL?) -> String {
        if appUrl?.absoluteString == nil { return "" }
        return Bundle(url: appUrl!)?.name ?? ""
    }
    
    //获取提示字符串
    func getEnableText(_ name: String) -> String {
        if (whiteMode && blackList.contains(name)) || (!whiteMode && !blackList.contains(name)) { return "已启用".local }
        return "未启用".local
    }
    
    //添加到黑名单
    @objc func addToList(_ sender: NSMenuItem) {
        let fApp = getAppName(NSWorkspace.shared.frontmostApplication?.bundleURL)
        if fApp != "" {
            if !blackList.contains(fApp){
                blackList.append(fApp)
            } else {
                blackList = blackList.filter{$0 != fApp}
            }
            UserDefaults.standard.set(blackList, forKey: "blackList")
        }
    }
    
    func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
        return screenWithMouse
    }
    
    //响应滑块事件
    @objc func sliderValueChanged(_ sender: Any) {
        guard let slider = sender as? NSSlider,
              let event = NSApplication.shared.currentEvent else { return }
        switch event.type {
        case .leftMouseUp, .rightMouseUp:
            let value = slider.intValue
            if value < 400000 {
                delay = Int(value)
                UserDefaults.standard.set(delay, forKey: "delay")
            }else{
                delayW = Int(value)
                UserDefaults.standard.set(delayW, forKey: "delayW")
            }
        default:
            break
        }
    }
    
    func initHUD() {
        HUD = NSWindow(contentRect: .init(origin: .zero, size: .init(width: 0, height: 0)), styleMask: .titled, backing: .buffered, defer: false)
        //HUD?.setFrame(NSMakeRect((w-textW)/2, (h-100)/2, textW, 100), display: true)
        HUD?.isReleasedWhenClosed = false
        HUD?.level = .statusBar
        HUD?.isOpaque = false
        HUD?.hasShadow = false
        HUD?.ignoresMouseEvents = true
        HUD?.titlebarAppearsTransparent = true
        HUD?.collectionBehavior = [.transient, .ignoresCycle]
        HUD?.backgroundColor = NSColor(white: 0.0, alpha: 0.6)
        
        text.stringValue = labelQ
        text.isEditable = false
        text.isSelectable = false
        text.isBezeled = false
        text.textColor = .white
        text.alignment = .center
        text.font = textFont
        //text.frame = NSMakeRect(0, -24, textW, 100)
        //NSFont(name: "Menlo", size: 40)
        text.backgroundColor = NSColor.clear
        text.drawsBackground = false
        HUD?.contentView?.addSubview(text)
    }
    
    //显示关于窗口
    @objc func aboutDialog(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(self)
    }
    
    //设置"登录时启动"
    @objc func setRunAtLogin(_ sender: NSMenuItem) {
        foundHelper.toggle()
        SMLoginItemSetEnabled(helperBundleName as CFString, foundHelper)
    }
    
    //设置倒计时动画
    @objc func setAnima(_ sender: NSMenuItem) {
        anima.toggle()
        UserDefaults.standard.set(anima, forKey: "anima")
    }
    
    //设置延时
    @objc func setDelay(_ sender: NSMenuItem) {
        delay = Int(sender.title.replacingOccurrences(of: "s", with: "")) ?? 1
        UserDefaults.standard.set(delay, forKey: "delay")
    }
    
    //设置白名单模式
    @objc func setWhiteMode(_ sender: NSMenuItem) {
        whiteMode.toggle()
        UserDefaults.standard.set(whiteMode, forKey: "whiteMode")
    }
    
    //设置双击模式
    @objc func setDoubleQ(_ sender: NSMenuItem) {
        doubleQ.toggle()
        UserDefaults.standard.set(doubleQ, forKey: "doubleQ")
    }
    
    //设置双击模式
    @objc func setCmdW(_ sender: NSMenuItem) {
        blockCmdW.toggle()
        UserDefaults.standard.set(blockCmdW, forKey: "blockCmdW")
        if blockCmdW { CloseKey.isPaused = false } else { CloseKey.isPaused = true }
    }
      
    
    func setTextWidth(_ txt: String) {
        let cell = NSCell(textCell: txt)
        cell.font = textFont
        let textWidth = cell.cellSize.width + 60
        let screen = self.getScreenWithMouse()
        let w = screen?.frame.width ?? 0
        let h = screen?.frame.height ?? 0
        let x = screen?.frame.minX ?? 0
        let y = screen?.frame.minY ?? 0
        let bound = NSMakeRect((w-textWidth)/2+x, (h-100)/2+y, textWidth, 100)
        HUD?.setFrame(bound, display: true)
        text.frame = NSMakeRect(0, -24, textWidth, 100)
    }
    
    func updateLabel(_ txt: String) {
        DispatchQueue.main.async(execute: {self.text.stringValue = txt})
    }
}

