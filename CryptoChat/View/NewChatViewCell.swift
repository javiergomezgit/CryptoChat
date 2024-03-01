//
//  NewChatViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/15/21.
//

import UIKit
import Nuke
import NukeExtensions

class NewChatViewCell: UITableViewCell {
    
    static let identifier = "NewChatViewCell"
    
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
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        return imageView
    }()
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
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
    
    public func configure(with model: SearchResult) {
        self.usernameLabel.text = model.usernameFriend
        let path = "profile_images/\(model.friendID)_profile.png"
        StorageMng.shared.downloadURL(for: path, completion: { [weak self] result in
            print (result)
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    NukeExtensions.loadImage(with: url, into: self!.userImageView)
                    //Nuke.loadImage(with: url, into: self!.userImageView)
                    
//                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
    }
}
