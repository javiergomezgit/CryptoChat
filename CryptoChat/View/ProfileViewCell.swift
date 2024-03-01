//
//  ProfileViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/11/21.
//

import UIKit

class ProfileViewCell: UITableViewCell {
    
    @IBOutlet weak var iconContainer: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconImageView.contentMode = .scaleAspectFit
        
        iconContainer.clipsToBounds = true
        iconContainer.layer.cornerRadius = 8
        iconContainer.layer.masksToBounds = true
        
        label.numberOfLines = 1
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        label.text = nil
        iconContainer.backgroundColor = nil
        accessoryType = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    public func configure(with model: SettingsOptions) {
        label.text = model.titleSetting
        iconImageView.image = model.icon
        iconContainer.backgroundColor = model.iconBackgroundColor
    }
    
}
