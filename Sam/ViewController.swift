//
//  ViewController.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/08/2020.
//

import UIKit
import StoreKit
import Static
import Cemono

class ViewController: TableViewController {
    
    class TableViewCell: UITableViewCell, Cell {
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value1, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            textLabel?.font = UIFont(name: "Avenir-Medium", size: 16.0)
            textLabel?.textColor = .white
            detailTextLabel?.font = UIFont.monospacedSystemFont(ofSize: 16.0, weight: .bold)
            detailTextLabel?.textColor = UIColor.systemBlue
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    private var reportData: Network.ReportingDataResponse? = nil {
        didSet {
            reloadData()
        }
    }
    
    private lazy var datePicker: UISegmentedControl = {
        let s = UISegmentedControl(items: [
            NSLocalizedString("Today", comment: ""),
            NSLocalizedString("Yesterday", comment: ""),
            NSLocalizedString("7 Days", comment: ""),
            NSLocalizedString("30 Days", comment: ""),
        ])
        s.selectedSegmentIndex = 0
        s.addTarget(self, action: #selector(self.changeDate(_:)), for: .valueChanged)
        return s
    }()
    
    private lazy var dateButton: UIButton = {
        let b = UIButton(type: .custom)
        b.frame = CGRect(x: 0, y: 0, width: 32.0, height: 32.0)
        b.setImage(UIImage(named: "Calendar")!.template, for: .normal)
        b.addTarget(self, action: #selector(self.setCustomDate(_:)), for: .touchUpInside)
        b.tintColor = UIColor.systemBlue
        b.layer.cornerRadius = 8.0
        b.layer.masksToBounds = true
        return b
    }()
    
    private var customDateStart: Date? = nil
    private var customDateEnd: Date? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let spacer1 = UIView(frame: CGRect(x: 0, y: 0, width: 10.0, height: 0.0))
        let spacer2 = UIView(frame: CGRect(x: 0, y: 0, width: 10.0, height: 0.0))
        let stack = UIStackView(arrangedSubviews: [spacer1, datePicker, dateButton, spacer2])
        stack.axis = .horizontal
        stack.spacing = 10.0
        stack.distribution = .fillProportionally
        stack.frame = CGRect(x: 0.0, y: 0, width: view.bounds.maxX, height: 32.0)
      
        title = NSLocalizedString("SearchAds Monitor", comment: "")
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(self.fetchData), for: .valueChanged)
        tableView.backgroundColor = .black
        tableView.rowHeight = 50.0
        tableView.separatorStyle = .none
        tableView.tableHeaderView = stack
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(self.showSettings(_:)))
        navigationItem.rightBarButtonItem = self.refreshButton
        
        NotificationCenter.default.addObserver(forName: .menuCommandSettings, object: nil, queue: .main) { [weak self] (notification) in
            self?.showSettings(nil)
        }
        NotificationCenter.default.addObserver(forName: .menuCommandRefresh, object: nil, queue: .main) { [weak self] (notification) in
            self?.fetchDataWith(completion: nil)
        }
        
        // NOTE: need this to show our empty message
        self.reloadData()

        guard let orgId = Settings.instace.ACLS?.orgId else { return }
        guard let cd = Settings.instace.certificateData,
              let cp = Settings.instace.certificatePassword,
              let identity = cd.identity(password: cp) else {
            return
        }
                
        // NOTE: Do this only if we have connection identity to connect with
        Network.instance.orgId = orgId
        Network.instance.connectionIdentity = identity
        self.fetchData()
        
        #if !DEBUG
        if let _ = Settings.instace.ACLS?.orgId {
            SKStoreReviewController.requestReview()
        }
        #endif
        
        NotificationCenter.default.addObserver(forName: .backgroundRefreshTodayData, object: nil, queue: .main) { [weak self] (notification) in
            debugPrint(notification)
            guard let self = self else { return }
            guard self.datePicker.selectedSegmentIndex == 0 else { return }
            guard let reportData = notification.userInfo?["report"] as? Data else { return }
            self.reportData = Network.ReportingDataResponse.fromJSONRepresentation(json: reportData)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addStatusBarItem()
    }
    
    private lazy var refreshButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.fetchData))
    }()

    // MARK: -
    
    private var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        f.locale = Locale.autoupdatingCurrent
        return f
    }()
    
    @objc func changeDate(_ sender: UISegmentedControl) {
        fetchData()
    }
    
    func updateTodayStats(completion: @escaping SuccessHandler) {
        guard datePicker.selectedSegmentIndex == 0 else {
            completion(false)
            return
        }
        fetchDataWith {
            completion(true)
        }
    }
    
    @objc func fetchData() {
        self.statusBarItem?.performSelector(onMainThread: NSSelectorFromString("fetch"), with: nil, waitUntilDone: false)
        fetchDataWith(completion: nil)
    }
    
    func fetchDataWith(completion: VoidHandler?) {
        var startDate: Date
        var endDate: Date
        
        let today = Date().startOfDay
        
        switch datePicker.selectedSegmentIndex {
        case 0: // today
            startDate = today.startOfDay
            endDate = today.endOfDay
        case 1: // yday
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        case 2: // last 7 days
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        case 3: // last 30 days
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: today)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        default:
            startDate = (customDateStart ?? today).startOfDay
            endDate = (customDateEnd ?? today).endOfDay
        }
        
        navigationItem.prompt = "\(dateFormatter.string(from: startDate)) — \(dateFormatter.string(from: endDate)) (\(Settings.instace.timeZone == .UTC ? "UTC" : (Settings.instace.ACLS?.timeZone ?? "")))"
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = UIColor.systemBlue
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        
        Network.instance.getCampaignsReport(start: startDate,
                                            end: endDate,
                                            timeZone: Settings.instace.timeZone,
                                            completionHandler: { [weak self] (data, error) in
            self?.navigationItem.rightBarButtonItem = self?.refreshButton
            self?.reportData = data
            self?.tableView.refreshControl?.endRefreshing()
                                                
            completion?()
        })
    }
    
    func reloadData() {
        guard let total = self.reportData?.grandTotals.total else {
            let label = CMLabel(frame: .zero)
            label.numberOfLines = 0
            label.text = NSLocalizedString("1. Create API Certificate.\n2. Convert PEM & KEY files to P12.\n3. Place it on iCloud drive.\n4. Load it from `Settings`.\n5. Refresh.", comment: "")
            label.textAlignment = .center
            label.textColor = UIColor.lightGray
            label.font = UIFont(name: "Avenir-Light", size: 16.0)
            label.textInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            
            tableView.backgroundView = label
            
            return
        }
        
        tableView.backgroundView?.removeFromSuperview()
        tableView.backgroundView = nil
        
        var rows = [Row]()
        
        rows.append(Row(text: NSLocalizedString("Spend", comment: ""),
                        detailText: "\(total.localSpend.amount)\(total.localSpend.currency)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Avg. CPA", comment: ""),
                        detailText: "\(total.avgCPA.amount)\(total.avgCPA.currency)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Avg. CPT", comment: ""),
                        detailText: "\(total.avgCPT.amount)\(total.avgCPT.currency)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Installs", comment: ""),
                        detailText: "\(total.installs)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("New Downloads", comment: ""),
                        detailText: "\(total.newDownloads)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Redownloads", comment: ""),
                        detailText: "\(total.redownloads)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("LAT Off Installs", comment: ""),
                        detailText: "\(total.latOffInstalls)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("LAT On Installs", comment: ""),
                        detailText: "\(total.latOnInstalls)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Impressions", comment: ""),
                        detailText: "\(total.impressions)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Taps", comment: ""),
                        detailText: "\(total.taps)",
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("Conversion Rate", comment: ""),
                        detailText: String(format: "%.2f", total.conversionRate),
                        cellClass: TableViewCell.self))
        rows.append(Row(text: NSLocalizedString("TTR", comment: ""),
                        detailText: String(format: "%.2f", total.ttr),
                        cellClass: TableViewCell.self))
                    
        self.dataSource.sections = [Section(rows: rows)]
    }
    
    @objc func showSettings(_ sender: Any?) {
        let vc = SettingsViewController(style: .grouped)
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissSettings(_:)))
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true, completion: nil)
    }
    
    @objc func dismissSettings(_ sender: Any) {
        if let _ = Settings.instace.ACLS {
            fetchData()
        }
        dismiss(animated: true)
    }
    
    @objc func setCustomDate(_ sender: Any) {
        datePicker.selectedSegmentIndex = -1
        let vc = DateRangeViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true, completion: nil)
    }

    #if !targetEnvironment(macCatalyst)
    override var keyCommands: [UIKeyCommand]? {
        return [
            {
                let c = UIKeyCommand(input: "R", modifierFlags: UIKeyModifierFlags.command, action: #selector(self.fetchData))
                c.title = NSLocalizedString("Refresh", comment: "")
                return c
            }(),
            {
                let c = UIKeyCommand(input: ",", modifierFlags: UIKeyModifierFlags.command, action: #selector(self.showSettings(_:)))
                c.title = NSLocalizedString("Settings", comment: "")
                return c
            }()
        ]
    }
    #endif
    
    var statusBarItem: NSObject?
}

extension ViewController: DateRangeViewControllerProtocol {
    
    func didSelectDateRange(from: Date, to: Date, viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
        customDateStart = from
        customDateEnd = to
        fetchData()
    }
    
    func didCancelDateRangeSelection(viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController {
    
    func addStatusBarItem() {
        #if targetEnvironment(macCatalyst)
        guard self.statusBarItem == nil else { return }
        guard let identity = Network.instance.connectionIdentity else { return }
        guard let orgId = Network.instance.orgId else { return }
        
        guard let plugInPath = Bundle.main.builtInPlugInsURL?.appendingPathComponent("AppKitGlue.bundle") else { return }
        guard let bundle = Bundle(url: plugInPath) else { return }
        guard bundle.load() else { return }
        guard let statusItemClass = bundle.principalClass as? NSObject.Type else { return }
        self.statusBarItem = statusItemClass.init()
        self.statusBarItem?.performSelector(onMainThread: NSSelectorFromString("setOrgId:"), with: NSNumber(integerLiteral: orgId), waitUntilDone: true)
        self.statusBarItem?.performSelector(onMainThread: NSSelectorFromString("setIdentity:"), with: identity, waitUntilDone: true)
        self.statusBarItem?.performSelector(onMainThread: NSSelectorFromString("start"), with: nil, waitUntilDone: false)
        debugPrint(self.statusBarItem)
        #endif
    }
    
}
