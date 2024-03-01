//
//  StorageMng.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/2/21.
//

import Foundation
import FirebaseStorage
import UIKit
//import Nuke

final class StorageMng {
    static let shared = StorageMng()
    private let storage = Storage.storage().reference()
    
    let cache = NSCache<NSString, UIImage>()
    
    public typealias UploadProfileCompletion = (Result<String, Error>) -> Void
    
    ///Upload photo to storage
    public func uploadProfilePhoto(with data: Data, fileName: String, completion: @escaping UploadProfileCompletion) {
        storage.child("profile_images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("profile_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetURL))
                    return
                }
                
                let urlString = url.absoluteString
                print (urlString)
                completion(.success(urlString))
            })
        })
    }
    
    
    ///Upload photo to storage
    public func uploadMessagePhoto(with data: Data, fileName: String, pathOfFile: String, completion: @escaping UploadProfileCompletion) {
        
        storage.child("messages/\(pathOfFile)/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("messages/\(pathOfFile)/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetURL))
                    return
                }
                
                let urlString = url.absoluteString
                print (urlString)
                completion(.success(urlString))
            })
        })
    }
    
    ///Download Imge
    public func downloadImage(for path: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let reference = storage.child(path)
    
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetURL))
                return
            }
            //completion(.success(url))
            if let image = self.cache.object(forKey: url.absoluteString as NSString) {
                completion(.success(image))
            } else {
                let dataTask = URLSession.shared.dataTask(with: url) { data, responseURL, error in
                    var downloadedImage:UIImage?
                    
                    if let data = data {
                        downloadedImage = UIImage(data: data)
                    }
                    if downloadedImage != nil {
                        self.cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
                    }
                    DispatchQueue.main.async {
                        completion(.success(downloadedImage!))
                    }
                }
                dataTask.resume()
            }
        }
    }
    
    ///Get URL for an image
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
    
        reference.downloadURL { url, error in
            print (url as Any)
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetURL))
                return
            }
            completion(.success(url))
        }
    }
    
    public func downloadSharedMediaURLs(path: String, completion: @escaping (Result<[String], Error>) -> Void) {
        
        let reference = storage.child(path)
        
        var sharedMediaURLStrings = [String]()
        reference.listAll { result, error in
            if error == nil {
                let urls = result!.items
                
                for url in urls {
                    let urlString = url.fullPath
                    sharedMediaURLStrings.append(urlString)
                }
                let sortedSharedMediaURLStrings = sharedMediaURLStrings.sorted {
                    $0  > $1
                }
                
                completion(.success(sortedSharedMediaURLStrings))
                

            } else {
                completion(.failure(StorageErrors.failedToGetURL))
            }
            
        }
        
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetURL
    }
}
