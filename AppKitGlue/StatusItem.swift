//
//  StatusItem.swift
//  AppKitGlue
//
//  Created by Evgeny Cherpak on 12/08/2020.
//

import Foundation
import AppKit
import Security

enum StatusItemDisplayType: Int {
    case avgCPA
    case avgCPT
    case localSpend
    case impressions
    case installs
    case latOffInstalls
    case latOnInstalls
    case newDownloads
    case redownloads
    case taps
    case conversionRate
    case ttr
}

@objcMembers class StatusItemManager: NSObject {
    
    private lazy var menu: NSMenu = {
        let menu = NSMenu(title: "SAM - SearchAds Monitor")
        menu.autoenablesItems = false
        menu.addItem(NSMenuItem(title: "SAM - SearchAds Monitor", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Ver: \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Spend", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.localSpend.rawValue
            item.state = .on
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Avg. CPA", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.avgCPA.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Avg. CPT", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.avgCPT.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Installs", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.installs.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("New Downloads", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.newDownloads.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Redownloads", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.redownloads.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("LAT Off Installs", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.latOffInstalls.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("LAT On Installs", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.latOnInstalls.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Impressions", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.impressions.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Taps", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.taps.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("Conversion Rate", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.conversionRate.rawValue
            return item
        }())
        menu.addItem({
            let item = NSMenuItem(title: NSLocalizedString("TTR", comment: ""), action: #selector(self.setDisplayType(_:)), keyEquivalent: "")
            item.tag = StatusItemDisplayType.ttr.rawValue
            return item
        }())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Show", comment: ""), action: #selector(self.showWindow(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Hide", comment: ""), action: #selector(self.hideWindow(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(self.quit(_:)), keyEquivalent: ""))
        
        menu.items.forEach {
            $0.isEnabled = $0.action != nil
            $0.target = self
        }
        return menu
    }()
    
    private lazy var statusBarItem: NSStatusItem = {
        // NOTE: have to include it in the app as it loads it from there for now
        let image = NSImage(systemSymbolName: "chart.pie", accessibilityDescription: "Chart Pie")
        image?.isTemplate = true

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.toolTip = "SAM - SearchAds Monitor"
        item.button?.title = "Loading"
//        item.button?.font = NSFont(name: "SFDisplay-Light", size: 12.0)
        item.button?.imagePosition = .imageLeft
        item.button?.image = image
        return item
    }()
    
    var timer: Timer? = nil
    var displayType: StatusItemDisplayType = .localSpend {
        didSet {
            display()
        }
    }
    var report: Network.ReportingDataResponse? = nil {
        didSet {
            display()
        }
    }
    
    override init() {
        super.init()
        self.statusBarItem.menu = self.menu
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.windows.forEach { window in
                window.delegate = self
//                let close = window.standardWindowButton(.closeButton)
//                let zoom = window.standardWindowButton(.zoomButton)
//                close?.isEnabled = false
//                zoom?.isEnabled = false
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // NOTE: wrap in NSNumber otherwise Int is fucked up when passed from 'iOS' code
    func setOrgId(_ orgId: NSNumber) {
        debugPrint("Setting orgId: \(orgId)")
        Network.instance.orgId = orgId.intValue
    }
    
    func setIdentity(_ identity: SecIdentity) {
        debugPrint("Setting identity: \(identity)")
        Network.instance.connectionIdentity = identity
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1 * 60, repeats: true, block: { [weak self] (timer) in
            self?.fetch()
        })
        self.timer?.fire()
    }
    
    func fetch() {
        Network.instance.getCampaignsReport { [weak self] (report, error) in
            self?.report = report
            // Send notification with report data to view controller to update
            if let reportData = report?.toJSONRepresentation {
                NotificationCenter.default.post(name: .backgroundRefreshTodayData, object: self, userInfo: ["report":reportData])
            }
        }
    }
    
    func display() {
        guard let total = report?.grandTotals.total else { return }
        switch displayType {
        case .avgCPA:
            self.statusBarItem.button?.title = "\(total.avgCPA.amount)\(total.avgCPA.currency)"
        case .avgCPT:
            self.statusBarItem.button?.title =  "\(total.avgCPT.amount)\(total.avgCPT.currency)"
        case .conversionRate:
            self.statusBarItem.button?.title =  String(format: "%.2f", total.conversionRate)
        case .impressions:
            self.statusBarItem.button?.title = "\(total.impressions)"
        case .installs:
            self.statusBarItem.button?.title = "\(total.installs)"
        case .latOffInstalls:
            self.statusBarItem.button?.title = "\(total.latOffInstalls)"
        case .latOnInstalls:
            self.statusBarItem.button?.title = "\(total.latOnInstalls)"
        case .localSpend:
            self.statusBarItem.button?.title = "\(total.localSpend.amount)\(total.localSpend.currency)"
        case .newDownloads:
            self.statusBarItem.button?.title = "\(total.newDownloads)"
        case .redownloads:
            self.statusBarItem.button?.title = "\(total.redownloads)"
        case .taps:
            self.statusBarItem.button?.title = "\(total.taps)"
        case .ttr:
            self.statusBarItem.button?.title = String(format: "%.2f", total.ttr)
        }
    }
    
    func setDisplayType(_ sender: NSMenuItem) {
        debugPrint("Set display type")
        guard let displayType = StatusItemDisplayType(rawValue: sender.tag) else { return }
        self.displayType = displayType
        self.menu.items.forEach { (item) in
            item.state = item.tag == sender.tag ? .on : .off
        }
        
        // fetch if we don't have data to display
        if report == nil {
            fetch()
        }
    }
    
    func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }

}

extension StatusItemManager: NSWindowDelegate {
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
        return false
    }
    
    func showWindow(_ sender: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func hideWindow(_ sender: NSWindow) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.hide(nil)
    }
    
}
