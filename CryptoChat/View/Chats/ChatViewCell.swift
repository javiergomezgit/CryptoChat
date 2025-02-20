//
//  ChatViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/13/21.
//

import UIKit
//import SDWebImage
import Nuke
import NukeExtensions

class ChatViewCell: UITableViewCell {
    
    static let identifier = "ChatViewCell"
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
        
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var isReadImageView: UIImageView!
  
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.cornersImage(circleImage: true, border: false, roundedCorner: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView!.image = nil
    }
    
    public func configure(with model: Chat) {
        self.usernameLabel.text = model.username.lowercased()
        self.userMessageLabel.text = model.latestMessage
        
        let dateString = model.date
        
        //        let dateFormatter = DateFormatter()
        //        dateFormatter.timeStyle = .long
        //        dateFormatter.dateStyle = .medium
        //        let date = dateFormatter.date(from: dateString)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let showDate = formatter.date(from: dateString)
        
        
        let timeToLive: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours
        if Date().timeIntervalSince(showDate!) < timeToLive {
            formatter.dateFormat = "hh:mm a"
        } else {
            formatter.dateFormat = "d/M/yy"
        }
        let goodDate = formatter.string(from: showDate!)
        
        self.dateLabel.text = goodDate
        
        
        let sender = model.messageID.components(separatedBy: "_")
        if sender[0] != model.userID {
            if !model.isRead {
                let image = UIImage(systemName: "circle.dashed.inset.fill")
                self.isReadImageView.image = image
                self.isReadImageView.tintColor = .systemBlue
                self.isReadImageView.isHidden = false
            } else {
                let image = UIImage(systemName: "circle")
                self.isReadImageView.image = image
                self.isReadImageView.isHidden = true
            }
        } else {
            let image = UIImage(systemName: "circle")
            self.isReadImageView.image = image
            self.isReadImageView.isHidden = true
        }
        
        let path = "profile_images/\(model.userID)_profile.png"
        
        StorageDatabaseController.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                print (url.absoluteString)
                let options = ImageLoadingOptions(
                    transition: .fadeIn(duration: 0.3),
                    failureImage: UIImage(named: "person.crop.circle.fill"),
                    failureImageTransition: .none)
                NukeExtensions.loadImage(with: url, options: options, into: self!.userImageView)
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
    }
}
