//
//  ChatFriendViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 9/28/21.
//

import UIKit
import Nuke
import NukeExtensions

class ChatFriendViewCell: UITableViewCell {

    static let identifier = "ChatFriendViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        //imageView.image = UIImage(systemName: "person.crop.circle.fill")
        return imageView
    }()
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 14,
                                     y: 10,
                                     width: 40,
                                     height: 40)
        usernameLabel.frame = CGRect(x: userImageView.frame.maxX + 10,
                                     y: (contentView.frame.height / 2) - 20,
                                     width: contentView.frame.width - 20 - userImageView.frame.size.width,
                                     height: 40)
    }
    

    public func configure(with model: Friend) {
        self.usernameLabel.text = model.usernameFriend
        let path = "profile_images/\(model.idFriend)_profile.png"
        StorageDatabaseController.shared.downloadURL(for: path, completion: { [weak self] result in
            print (result)
            switch result {
            case .success(let url):
                
                let options = ImageLoadingOptions(
                    placeholder: UIImage(named: "person.crop.circle.fill"),
                    transition: .fadeIn(duration: 0.13)
                )
                NukeExtensions.loadImage(with: url, options: options, into: self!.userImageView)
                
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
    }
}
