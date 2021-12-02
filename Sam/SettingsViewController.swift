//
//  SettingsViewController.swift
//  sam
//
//  Created by Evgeny Cherpak on 04/08/2020.
//

import UIKit
import Static
import SVProgressHUD
import Cemono
#if !targetEnvironment(macCatalyst)
import SafariServices
#endif

class SettingsViewController: TableViewController {
    
    class TableViewCell: UITableViewCell, Cell {
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value1, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            textLabel?.font = UIFont(name: "Avenir-Medium", size: 16.0)
            textLabel?.textColor = .white
            detailTextLabel?.font = UIFont(name: "Avenir-Light", size: 16.0)
            detailTextLabel?.textColor = UIColor.lightGray
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }
    
    class HintTableViewCell: UITableViewCell, Cell {
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            textLabel?.font = UIFont(name: "Avenir-Medium", size: 14.0)
            textLabel?.textColor = .lightGray
            textLabel?.textAlignment = .center
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Settings", comment: "")
        
        tableView.backgroundColor = .black
        tableView.rowHeight = 50.0
        tableView.separatorStyle = .none
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let facebook = CMButton(type: .custom)
        facebook.tintColor = UIColor.lightGray
        facebook.setImage(UIImage(named: "facebook_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        facebook.handler = { [weak self] in
            self?.openFacebook()
        }

        let twitter = CMButton(type: .custom)
        twitter.tintColor = UIColor.lightGray
        twitter.setImage(UIImage(named: "twitter_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        twitter.handler = { [weak self] in
            self?.openTwitter()
        }

        let web = CMButton(type: .custom)
        web.tintColor = UIColor.lightGray
        web.setImage(UIImage(named: "web_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        web.handler = { [weak self] in
            self?.openWebsite()
        }

        let socialButtons = [UIView(frame: .zero), facebook, twitter, web, UIView(frame: .zero)]
        socialButtons.forEach { $0.sizeToFit() }
        let social = UIStackView(arrangedSubviews: socialButtons)
        social.axis = .horizontal
        social.spacing = 20.0
        social.distribution = .fillEqually
        social.frame = CGRect(x: 0, y: 0, width: 90, height: 40)
        
        tableView.tableFooterView = social
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    func loadData() {
        var sections = [Section]()
        
        sections.append(Section(rows: [
            Row(text: NSLocalizedString("Load Certificate", comment: ""), selection: { [weak self] in
                self?.selectCertificate()
            },
                accessory: .disclosureIndicator,
                cellClass: TableViewCell.self)
        ]))
        
        if let acls = Settings.instace.ACLS {
            sections.append(Section(rows: [
                Row(text: NSLocalizedString("Name", comment: ""),
                    detailText: "\(acls.orgName)",
                    cellClass: TableViewCell.self),
                Row(text: NSLocalizedString("ID", comment: ""),
                    detailText: "\(acls.orgId)",
                    cellClass: TableViewCell.self),
                Row(text: NSLocalizedString("Time Zone", comment: ""),
                    detailText: "\(Settings.instace.timeZone == .UTC ? "UTC" : acls.timeZone)",
                    selection: { [weak self] in
                        let vc = TimeZoneViewController()
                        self?.navigationController?.pushViewController(vc, animated: true)
                    },
                    accessory: .disclosureIndicator,
                    cellClass: TableViewCell.self),
                Row(text: NSLocalizedString("Currency", comment: ""),
                    detailText: "\(acls.currency)",
                    cellClass: TableViewCell.self)
            ]))
        }
        
        sections.append(Section(rows: [
            Row(text: App.appVersion,
                cellClass: HintTableViewCell.self)
        ]))
        
        self.dataSource.sections = sections
    }
    
    func selectCertificate() {
        #warning("Limit to P12 files only")
        let vc = UIDocumentPickerViewController(documentTypes: ["com.cherpake.p12", "public.data"], in: .import)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
}

extension SettingsViewController {
    
    func openFacebook() {
        let url = URL(string: "fb://profile/320620854732554")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(URL(string: "https://www.cherpake.com/facebook")!, options: [:], completionHandler: nil)
        }
    }
    
    func openTwitter() {
        #if !targetEnvironment(macCatalyst)
        let possibleUrls = [
            "twitter://user?screen_name=cherpake",
            "tweetbot:///user_profile/cherpake",
            "twitterrific:///profile?screen_name=cherpake",
        ]
        var opened: Bool = false
        possibleUrls.forEach {
            if !opened {
                let url = URL(string: $0)!
                if UIApplication.shared.canOpenURL(url) {
                    opened = true
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        if !opened {
            UIApplication.shared.open(URL(string: "https://www.cherpake.com/twitter")!, options: [:], completionHandler: nil)
        }
        #else
        UIApplication.shared.open(URL(string: "https://www.cherpake.com/twitter")!, options: [:], completionHandler: nil)
        #endif
    }
   
    func openWebsite() {
        #if !targetEnvironment(macCatalyst)
        let vc = SFSafariViewController(url: URL(string: "https://www.cherpake.com")!)
        present(vc, animated: true, completion: nil)
        #else
        UIApplication.shared.open(URL(string: "https://www.cherpake.com")!, options: [:], completionHandler: nil)
        #endif
    }
    
}

extension SettingsViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Password", comment: ""),
                                      message: String.localizedStringWithFormat(NSLocalizedString("Please enter password for %@", comment: ""), (url.path as NSString).lastPathComponent),
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            guard let password = alert.textFields?.first?.text, password.count > 0 else { return }
            guard let data = try? Data(contentsOf: url) else { return }
            guard let _ = data.identity(password: password) else {
                SVProgressHUD.showError(withStatus: NSLocalizedString("Invalid file or password", comment: ""))
                return
            }
            debugPrint("Successfully loaded certificate from file with password")
            
            Settings.instace.certificateData = data
            Settings.instace.certificatePassword = password
            
            Network.instance.orgId = nil
            Network.instance.connectionIdentity = data.identity(password: password)
            
            SVProgressHUD.show()
            Network.instance.getACLS { [weak self] (data, error) in
                guard let self = self else { return }
                guard error == nil else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Failed to connect", comment: ""))
                    return
                }
                guard let _ = data.first else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Failed to connect", comment: ""))
                    return
                }
                
                SVProgressHUD.showSuccess(withStatus: nil)
                Network.instance.orgId = data.first?.orgId
                Settings.instace.ACLS = data.first
                self.loadData()
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
