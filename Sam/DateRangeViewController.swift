//
//  TimeZoneViewController.swift
//  Sam
//
//  Created by Evgeny Cherpak on 05/08/2020.
//

import UIKit

protocol DateRangeViewControllerProtocol: NSObjectProtocol {
    func didSelectDateRange(from: Date, to: Date, viewController: UIViewController)
    func didCancelDateRangeSelection(viewController: UIViewController)
}

class DateRangeViewController: UIViewController {
    
    weak var delegate: DateRangeViewControllerProtocol?
    
    private var from: UIDatePicker!
    private var to: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        title = NSLocalizedString("Date Range", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.done(_:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel(_:)))
        navigationController?.navigationBar.prefersLargeTitles = true

        let fromLabel = UILabel(frame: .zero)
        fromLabel.text = NSLocalizedString("From:", comment: "")
        fromLabel.font = UIFont(name: "Avenir-Medium", size: 16.0)
        fromLabel.textColor = .white
        
        let toLabel = UILabel(frame: .zero)
        toLabel.text = NSLocalizedString("To:", comment: "")
        toLabel.font = UIFont(name: "Avenir-Medium", size: 16.0)
        toLabel.textColor = .white

        from = UIDatePicker()
        from.tag = 1
        from.datePickerMode = .date
        from.date = Date()
        from.maximumDate = Date()
        
        to = UIDatePicker()
        to.tag = 2
        to.datePickerMode = .date
        to.date = Date()
        to.maximumDate = Date()
        
        let stack = UIStackView(arrangedSubviews: [fromLabel, from, toLabel, to])
        stack.axis = .vertical
        stack.spacing = 10.0
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let spacer = UIView(frame: .zero)
        spacer.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(spacer)
        view.addSubview(stack)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[stack]-|", options: [], metrics: nil, views: ["stack": stack]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spacer]-20-[stack]", options: [], metrics: nil, views: ["stack": stack, "spacer": spacer]))
    }
    
    
    @objc func done(_ sender: Any) {
        self.delegate?.didSelectDateRange(from: from.date, to: to.date, viewController: self)
    }
    
    @objc func cancel(_ sender: Any) {
        self.delegate?.didCancelDateRangeSelection(viewController: self)
    }
    
}
