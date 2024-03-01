//
//  BlockedViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 9/15/21.
//

import UIKit
//import SDWebImage
import Nuke
import NukeExtensions

class BlockedViewCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendLabel: UILabel!
    @IBOutlet weak var unblockedButton: UIButton!
        
    static let identifier = "BlockedViewCell"
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    public func configure(with model: SearchResult) {

        print (model.friendID)
        print (model.usernameFriend)
        
        unblockedButton.setTitle("Unblock".localized(), for: .normal)
        unblockedButton.setTitleColor(.label, for: .normal)

        friendLabel.text = model.usernameFriend
        
        let path = "profile_images/\(model.friendID)_profile.png"
        StorageMng.shared.downloadURL(for: path, completion: { [weak self] result in
            print (result)
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
//                    self?.friendImageView.sd_setImage(with: url, completed: nil)
                    NukeExtensions.loadImage(with: url, into: self!.friendImageView)
                    self?.friendImageView.cornersImage(circleImage: true, border: false, roundedCorner: 10)

                }
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
        
    }
    
}
