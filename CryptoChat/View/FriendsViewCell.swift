//
//  RequestViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/22/21.
//


import UIKit
//import SDWebImage
import Nuke
import NukeExtensions

class FriendsViewCell: UITableViewCell {

    static let identifier = "FriendsViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(isFriendImageView)
        contentView.addSubview(friendSinceLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 19
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .cyan.withAlphaComponent(0.7)
//        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        return imageView
    }()
    public let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        //label.backgroundColor = .green
        return label
    }()
    private let friendSinceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .light)
        label.tintColor = .lightGray
        label.numberOfLines = 0
        //label.backgroundColor = .cyan
        return label
    }()
    private let isFriendImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        //imageView.image = UIImage(systemName: "person.fill.questionmark")
        imageView.tintColor = .systemOrange
        imageView.isHidden = true
        //imageView.backgroundColor = .yellow
        return imageView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let widthCell = contentView.frame.width
        let heightCell = contentView.frame.height
        
        userImageView.frame = CGRect(x: 15,
                                     y: (heightCell/2) - 20,
                                     width: 38,
                                     height:38)
        usernameLabel.frame = CGRect(x: userImageView.frame.maxX + 15,
                                     y: 3, //(heightCell / 2) - (heightCell * 0.22),
                                     width: widthCell * 0.6,
                                     height: heightCell * 0.5)
        
        friendSinceLabel.frame = CGRect(x: userImageView.frame.maxX + 15,
                                        y: usernameLabel.frame.maxY - 5, //(heightCell / 2),
                                width: widthCell * 0.6,
                                height: heightCell * 0.45)
        
        isFriendImageView.frame = CGRect(x: widthCell - (widthCell * 0.2),
                                     y: (heightCell / 2) - (heightCell * 0.22) ,
                                     width: widthCell * 0.2,
                                     height: heightCell * 0.35)
        

    }

    
    public func configure(with model: Friend) {
        self.usernameLabel.text = model.usernameFriend
        
        if !model.isFriend {
            isFriendImageView.isHidden = false
        } else {
            isFriendImageView.isHidden = true
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let showDate = formatter.date(from: model.friendsSince)
        
//        print (Locale.current.languageCode)
//        print (Locale.current.description)
//        print (Locale.current.identifier) //works
//        print (Locale.current.regionCode)
//        print (Locale.preferredLanguages[0])
//        print (TimeZone.current)
        
        if Locale.preferredLanguages[0] == "en" {
            formatter.dateFormat = "MMM d, yyyy"
            let result = formatter.string(from: showDate!)
            self.friendSinceLabel.text = result
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            let result = formatter.string(from: showDate!)
            self.friendSinceLabel.text = result
        }
        let path = "profile_images/\(model.idFriend)_profile.png"
        
        StorageMng.shared.downloadURL(for: path, completion: { [weak self] result in

            switch result {
            case .success(let url):
                let options = ImageLoadingOptions(
//                    placeholder: UIImage(named: "person.crop.circle.fill"),
                    transition: .fadeIn(duration: 0.3),
                    failureImage: UIImage(named: "person.crop.circle.fill"),
                    failureImageTransition: .none)
//                    tintColors: .init(success: .blue, failure: .red, placeholder: .orange))

                NukeExtensions.loadImage(with: url, options: options, into: self!.userImageView)

            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
        
    }

}

