//
//  SettingsViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/13/21.
//

import UIKit

class SettingsViewCell: UITableViewCell {

    static let identifier = "SettingsViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(currentLabel)
        contentView.addSubview(dataTextField)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let currentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .bold)
        return label
    }()
    
    public let dataTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17, weight: .semibold)
        return textField
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        currentLabel.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 10, height: contentView.frame.height - 10)
        dataTextField.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 10, height: contentView.frame.height - 10)
    }
    
    public func configure(username: String) {
        self.currentLabel.text = username
    }

}
