//
//  StorageDatabaseController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/4/24.
//

import FirebaseStorage
import UIKit

final class StorageDatabaseController {
    static let shared = StorageDatabaseController()
    private let storage = Storage.storage().reference()
    
    public typealias UploadProfileCompletion = (Result<String, Error>) -> Void
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetURL
    }
    
    //MARK: Upload photo to storage
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
    
    //MARK: Get URL for an image
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
    
}
