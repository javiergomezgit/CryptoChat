//
//  InviteFriendsViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 10/12/21.
//

import UIKit

class InviteFriendsViewCell: UITableViewCell {

    static let identifier = "InviteFriendsViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(phoneLabel)
        contentView.addSubview(checkmarkButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
//        imageView.backgroundColor = .blue
        return imageView
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
//        label.backgroundColor = .cyan
        return label
    }()
    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
//        label.backgroundColor = .green
        return label
    }()
    private let checkmarkButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Checkmark"), for: .selected)
        button.setImage(UIImage(named: "Checkmarkempty"), for: .normal)
        button.tag = 2
//        button.backgroundColor = .yellow
        return button
    }()
   
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 40,
                                     height: 40)
        nameLabel.frame = CGRect(x: userImageView.frame.maxX + 10,
                                 y: 5,
                                 width: contentView.frame.width - userImageView.frame.size.width - 70,
                                 height: 20)
        phoneLabel.frame = CGRect(x: userImageView.frame.maxX + 10,
                                  y: 30,
                                  width: contentView.frame.width - userImageView.frame.size.width - 70,
                                  height: 20)
        checkmarkButton.frame = CGRect(x: phoneLabel.frame.maxX + 5,
                                       y: 15,
                                       width: 25,
                                       height: 25)
    }
    
    public func configure(with model: ContactNumber) {
        guard let phone = model.phoneNumber, let labelNumber = model.labelNumber else {
            return
        }
        
        self.nameLabel.text = "\(model.firstName) \(model.lastName)"
        self.phoneLabel.text = "\(labelNumber): \(phone)"
        
//        if model.profilePhoto != nil {
//            let image = UIImage(data: model.profilePhoto!)
//            self.userImageView.image = image
//        }
        
    }
}

