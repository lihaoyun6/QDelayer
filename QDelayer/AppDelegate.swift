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
    
    var timer: Timer?
    var HUD: NSWindow?
    var keydown = false
    var foundHelper = false
    var anima = UserDefaults.standard.bool(forKey: "anima")
    var disable = UserDefaults.standard.bool(forKey: "disable")
    var whiteMode = UserDefaults.standard.bool(forKey: "whiteMode")
    var delay = (UserDefaults.standard.object(forKey: "delay") ?? 1) as! Int
    var blackList = (UserDefaults.standard.array(forKey: "blackList") ?? []) as! [String]
    var statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let menu = NSMenu()
    let text = NSTextField()
    let label = "按住 ⌘Q 退出当前程序".local
    let QuitKey = HotKey(key: .q, modifiers: [.command])
    let helperBundleName = "com.lihaoyun6.QDelayerLoginHelper"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //获取自启代理状态
        foundHelper = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == helperBundleName }
        
        menuIcon()
        menuWillOpen(menu)
        initHUD()
        if disable { QuitKey.isPaused = true } else { QuitKey.isPaused = false }
        
        QuitKey.keyDownHandler = {
            if self.disable { return }
            let fApp = self.getAppName(NSWorkspace.shared.frontmostApplication?.bundleURL)
            if (self.whiteMode && !self.blackList.contains(fApp)) || (!self.whiteMode && self.blackList.contains(fApp)) {
                NSWorkspace.shared.frontmostApplication?.terminate()
                return
            }
            self.keydown = true
            self.text.stringValue = self.label
            if self.anima { self.text.stringValue = "⬜️ " + self.label + " ⬜️" }
            self.HUD?.makeKeyAndOrderFront(self)
            Thread.detachNewThread {
                let range = self.delay*100
                for i in 1...range {
                    if !self.keydown { return }
                    if self.anima {
                        switch(i){
                        case _ where i <= Int(Double(range)*0.25):
                            DispatchQueue.main.async(execute: {self.text.stringValue = "⬜️ " + self.label + " ⬜️"})
                        case _ where i <= Int(Double(range)*0.50):
                            DispatchQueue.main.async(execute: {self.text.stringValue = "◻️ " + self.label + " ◻️"})
                        case _ where i <= Int(Double(range)*0.75):
                            DispatchQueue.main.async(execute: {self.text.stringValue = "◽️ " + self.label + " ◽️"})
                        case _ where i <= Int(Double(range)*0.98):
                            DispatchQueue.main.async(execute: {self.text.stringValue = "▫️ " + self.label + " ▫️"})
                        default:
                            DispatchQueue.main.async(execute: {self.text.stringValue = self.label})
                        }
                    }
                    if i >= range {
                        NSWorkspace.shared.frontmostApplication?.terminate()
                        DispatchQueue.main.async(execute: { self.HUD?.close() })
                    }
                    usleep(10000)
                }
            }
        }
        QuitKey.keyUpHandler = {
            self.keydown = false
            self.HUD?.close()
        }
    
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
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
        menu.autoenablesItems = false
        let Switch = menu.addItem(withTitle: "\(fApp): \(getEnableText(fApp))", action: #selector(addToList(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.setSubmenu(options, for: menu.addItem(withTitle: "偏好设置...".local, action: nil, keyEquivalent: ""))
        options.addItem(withTitle: "登录时启动".local, action: #selector(setRunAtLogin(_:)), keyEquivalent: "").state = state(foundHelper)
        options.addItem(NSMenuItem.separator())
        options.addItem(withTitle: "倒计时动画".local, action: #selector(setAnima(_:)), keyEquivalent: "").state = state(anima)
        options.addItem(withTitle: "白名单模式".local, action: #selector(setWhiteMode(_:)), keyEquivalent: "").state = state(whiteMode)
        options.setSubmenu(choose, for: options.addItem(withTitle: "等待时长...".local, action: nil, keyEquivalent: ""))
        choose.addItem(withTitle: "1s", action: #selector(setDelay(_:)), keyEquivalent: "").state = state(delay == 1)
        choose.addItem(withTitle: "2s", action: #selector(setDelay(_:)), keyEquivalent: "").state = state(delay == 2)
        choose.addItem(withTitle: "3s", action: #selector(setDelay(_:)), keyEquivalent: "").state = state(delay == 3)
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
        if disable { QuitKey.isPaused = true } else { QuitKey.isPaused = false }
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
    
    func initHUD() {
        let screen = self.getScreenWithMouse()
        let w = screen?.frame.width ?? 0
        let h = screen?.frame.height ?? 0
        let textFont = NSFont.boldSystemFont(ofSize: 40.0)
        let cell = NSCell(textCell: "⬜️ " + label + " ⬜️")
        cell.font = textFont
        let textW = cell.cellSize.width+50
        
        HUD = NSWindow(contentRect: .init(origin: .zero, size: .init(width: 0, height: 0)), styleMask: .titled, backing: .buffered, defer: false)
        HUD?.setFrame(NSMakeRect((w-textW)/2, (h-100)/2, textW, 100), display: true)
        HUD?.isReleasedWhenClosed = false
        HUD?.level = .statusBar
        HUD?.isOpaque = false
        HUD?.hasShadow = false
        HUD?.ignoresMouseEvents = true
        HUD?.titlebarAppearsTransparent = true
        HUD?.collectionBehavior = [.transient, .ignoresCycle]
        HUD?.backgroundColor = NSColor(white: 0.0, alpha: 0.6)
        
        text.stringValue = label
        text.isEditable = false
        text.isSelectable = false
        text.isBezeled = false
        text.textColor = .white
        text.alignment = .center
        text.font = textFont
        text.frame = NSMakeRect(0, -24, textW, 100)
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

}

