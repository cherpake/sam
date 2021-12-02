//
//  TimeZoneViewController.swift
//  Sam
//
//  Created by Evgeny Cherpak on 05/08/2020.
//

import Foundation
import Static

class TimeZoneViewController: TableViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Time Zone", comment: "")
        
        tableView.backgroundColor = .black
        tableView.rowHeight = 50.0
        tableView.separatorStyle = .none
        
        navigationController?.navigationBar.prefersLargeTitles = true

        loadData()
    }
    
    func loadData() {
        var sections = [Section]()
       
        sections.append(Section(rows: [
            Row(text: NSLocalizedString("UTC", comment: ""),
                selection: { [weak self] in
                    Settings.instace.timeZone = .UTC
                    self?.loadData()
                },
                accessory: Settings.instace.timeZone == .UTC ? .checkmark : .none,
                cellClass: TableViewCell.self),
            Row(text: Settings.instace.ACLS?.timeZone ?? "",
                selection: { [weak self] in
                    Settings.instace.timeZone = .ORTZ
                    self?.loadData()
                },
                accessory: Settings.instace.timeZone == .ORTZ ? .checkmark : .none,
                cellClass: TableViewCell.self),
        ]))
        
        self.dataSource.sections = sections
    }
    
}
