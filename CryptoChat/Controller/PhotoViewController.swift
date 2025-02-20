//
//  PhotoViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 1/7/25.
//

import UIKit
//import SDWebImage
import Nuke
import NukeExtensions

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    private let url: URL
    private var imageLoaded: UIImage?
    
    init(with url: URL) {
        self.url = url
        self.imageLoaded = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        //        imageView.clipsToBounds = false
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        
        
        scrollView.backgroundColor = .black
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        //scrollView.flashScrollIndicators()
        //scrollView.isPagingEnabled = true
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        
        return scrollView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        
        scrollView.delegate = self
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
//        self.imageView.sd_setImage(with: self.url, completed: { image, error, cache, url in
//            self.imageLoaded = image!
//        })
        
        NukeExtensions.loadImage(with: self.url, into: imageView) { result in
            switch result {
            case .success(let image):
                print (image)
                self.imageLoaded = image.image
            case .failure(let error):
                print (error)
            }
        }
        
        let rightBUttonImage = UIImage(systemName: "square.and.arrow.down.fill")!.withRenderingMode(.alwaysTemplate)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightBUttonImage, style: .plain, target: self, action: #selector(saveImage))
        navigationItem.rightBarButtonItem!.tintColor = UIColor.white
                                   
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()
        
        tabBarController?.tabBar.isHidden = true
        navigationController?.navigationBar.tintColor = .white
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
        
        navigationController?.navigationBar.tintColor = .systemBlue
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        imageView.frame = scrollView.bounds
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    
    @objc func saveImage(){
        UIImageWriteToSavedPhotosAlbum(imageLoaded!, self, #selector(saveError), nil)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        present(ShowAlert.alert(type:.firebaseSuccess, error: "Image Saved"), animated: true)
    }
    
}
