//
//  AppDelegate.swift
//  AppDimmerLoginHelper
//
//  Created by apple on 2022/09/17.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == "com.lihaoyun6.QDelayer"
        }

        if !isRunning {
            var url = Bundle.main.bundleURL
            for _ in 1...4 {
                url = url.deletingLastPathComponent()
            }
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

