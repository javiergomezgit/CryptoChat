//
//  FriendMediaViewCell.swift
//  CryptoChat
//
//  Created by Javier Gomez on 9/9/21.
//

import UIKit
//import SDWebImage
import Nuke
import NukeExtensions
import AVFoundation

class FriendMediaViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imagePlayButton: UIImageView!
    @IBOutlet weak var urlLabel: UILabel!
    
    static let identifier = "FriendMediaViewCell"
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    public func configure(with urlString: String) {
        
        let path = urlString
        print (path)
        StorageMng.shared.downloadURL(for: path, completion: { [weak self] result in
            print (result)
            switch result {
            case .success(let url):
                self!.urlLabel.text = url.absoluteString

                DispatchQueue.main.async {
                    if url.absoluteString.contains(".png") {
                        self!.imagePlayButton.isHidden = true
                        NukeExtensions.loadImage(with: url, into: self!.imageView)
//                        self!.imageView.sd_setImage(with: url, completed: nil)
                    } else {
                        self!.getThumbnailFromUrl(url) { image in
                            self!.imageView.image = image
                            self!.imagePlayButton.isHidden = false
                        }
                    }
                }
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
        
        
    }
    

    
    func getThumbnailFromUrl(_ url: URL?, _ completion: @escaping ((_ image: UIImage?)->Void)) {
            DispatchQueue.main.async {
                let asset = AVAsset(url: url!)
                let assetImgGenerate = AVAssetImageGenerator(asset: asset)
                assetImgGenerate.appliesPreferredTrackTransform = true
                
                let time = CMTimeMake(value: 2, timescale: 1)
                do {
                    let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                    let thumbnail = UIImage(cgImage: img)
                    completion(thumbnail)
                } catch let error{
                    print("Error :: ", error)
                    completion(nil)
                }
            }
        }

}
