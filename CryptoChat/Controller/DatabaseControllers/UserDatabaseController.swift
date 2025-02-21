//
//  UserDatabaseController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/4/24.
//

import FirebaseDatabase
import FirebaseAuth
import MessageKit
import Foundation
import AVKit
import UIKit

final class UserDatabaseController {
    
    static let shared = UserDatabaseController()
    private let database = Database.database().reference()
    
    public enum DatabaseError: Error {
        case failedToFetch
        case wrongPhoneNumber
    }
    
    //MARK: Get phone number, input userID -> Returning UserLocalInformation value
    public func getInitialInfo(userID: String, completion: @escaping(UserLocalInformation?) -> Void) {
        
        database.child("usernames").child(userID).observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }
            
            guard let phone = userData["phone_number"] as? String, let isPrivate = userData["private"] as? Bool, let username = userData["username"] as? String else {
                completion(nil)
                return
            }
            
            self.database.child("users/\(userID)/profile_image_url").observeSingleEvent(of: .value) { snap in
                guard let profileURL = snap.value as? String else {
                    completion(nil)
                    return
                }
                
                self.database.child("users/\(userID)/general_passcode").observeSingleEvent(of: .value) { snapshot in
                    
                    guard let generalPasscode = snapshot.value as? String else {
                        completion(nil)
                        return
                    }
                    
                    let userInfo = UserLocalInformation(phoneNumber: phone, username: username, isPrivate: isPrivate, profilePhotoURL: profileURL, generalPasscode: generalPasscode)
                    completion (userInfo)
                }
                
            }
        }
    }
    
    enum SignpUpMethod {
        case appleID //method 1
        case email //method 2
        case phoneNumber //method 3
    }
    //MARK: Create new user in DB -> Returning boolean value
    public func createNewUser(with user: UserInformation, signUpMethod: SignpUpMethod, completion: @escaping(Bool) -> Void) {
        guard let image = UIImage(named: "#") else {
            return
        }
        
        guard let dataImage = image.pngData() else {
            return
        }
        
        let data = dataImage
        let fileName = "\(user.idUser)_profile.png"
        
        StorageDatabaseController.shared.uploadProfilePhoto(with: data, fileName: fileName) { result in
            
            switch result {
            case .success(let url):
                
                var methodSignedUp = 0
                
                switch signUpMethod {
                case .appleID:
                    print ("apple id")
                    methodSignedUp = 1
                case .email:
                    print ("email")
                    methodSignedUp = 2
                case .phoneNumber:
                    print ("phone number")
                    methodSignedUp = 3
                }
                
                let userPublicElement : [String: Any] = [
                    "phone_number" : user.phoneNumber!,
                    "private" : false,
                    "username" : user.username!,
                    "email" : user.emailAddress!,
                    "methodSignedUp" : methodSignedUp
                ]
                
                let userPrivateElement : [String: Any] = [
                    "email" : user.emailAddress!,
                    "fullName" : user.fullname!,
                    "general_passcode" : "0000",
                    "phoneNumber" : user.phoneNumber!,
                    "username" : user.username!,
                    "profile_image_url" : url,
                    "private" : false
                ]
                
                
                //Set values on users collection
                self.database.child("users").child(user.idUser).setValue(userPrivateElement, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        print ("failed writing user information in DB ")
                        completion(false)
                        return
                    }
                })
                
                self.database.child("usernames").child(user.idUser).setValue(userPublicElement, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        print ("failed writing usernames in DB ")
                        completion(false)
                        return
                    }
                })
                
                
                completion(true)
            case .failure(let error):
                print("failed uploading profile photo \(error)")
                completion(false)
            }
        }
    }
    
    //MARK: Search email exists -> Returning boolean value
    public func searchEmailExists(with emailToSearch: String, completion: @escaping(Bool) -> Void) {
        database.child("usernames").observeSingleEvent(of: .value) { snapshot in
            if let emails = snapshot.value as? [String: [String: Any]] {
                
                var userFound: Bool = false
                
                for email in emails {
                    if email.value["email"] as? String == emailToSearch {
                        print ("found")
                        userFound = true
                        break
                    } else {
                        userFound = false
                    }
                }
                completion(userFound)
            }
        }
    }
    
    
    //MARK: Search phone number exists -> Returning boolean value
    //    public func searchPhoneNumberExists(with phoneNumberToSearch: String, completion: @escaping(Bool) -> Void) {
    //        database.child("userlook").observeSingleEvent(of: .value) { snapshot in
    //            if let phoneNumbers = snapshot.value as? [String: String] {
    //
    //                var userFound: Bool = false
    //
    //                for phoneNumber in phoneNumbers {
    //                    if phoneNumber.key == phoneNumberToSearch {
    //                        //Found email
    //                        print ("found")
    //                        userFound = true
    //                        break
    //                    }
    //                }
    //                completion(userFound)
    //            }
    //        }
    //    }
    
    //MARK: Look up for a unique username -> Returning a boolean value
    public func lookUniqueUsers(with usernameToLookup: String, completion: @escaping(String?, String?) -> Void) {
        
        database.child("usernames").observeSingleEvent(of: .value) { snapshot in
            
            guard let usernames = snapshot.value as? [String: [String: Any]] else {
                completion(nil, nil)
                return
            }
            
            for (userID, userData) in usernames {
                if let userDict = userData as? [String: Any], let foundUsername = userDict["username"] as? String, foundUsername == usernameToLookup {
                    completion(foundUsername, userID)
                    return // Exit the function early once a match is found
                }
            }
            completion(nil, nil)
        }
    }
    
    //MARK: Update username - input old/new username and user ID -> Returning a boolean value
    public func updateUsername(newUsername: String, userID: String, completion: @escaping(Bool) -> Void) {
        //Set new value (username) on current user's collection
        database.child("users").child(userID).child("username").setValue(newUsername, withCompletionBlock: { error, _ in
            guard error == nil else {
                print ("failed writing user information in DB ")
                completion(false)
                return
            }
            
            //Deleting and creating a new username on the common list of usernames
            self.database.child("usernames").child("\(userID)/username").setValue(newUsername, withCompletionBlock: { error, _ in
                guard error == nil else {
                    print ("failed writing user in usernames in DB ")
                    completion(false)
                    return
                }
            })
            //            UserDefaults.standard.set(newUsername, forKey: "username")
            //            UserDefaults.standard.synchronize()
            completion(true)
        })
    }
    
    //MARK: Update email - input user of type Firebase and new email -> Returning an optional error type
    public func updateEmail(user: User, newEmail: String, username: String, completion: @escaping(Error?) -> Void) {
        //        user.updateEmail(to: newEmail) { error in
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            if let error = error {
                completion(error)
            } else {
                print ("updated email")
                self.database.child("users").child(user.uid).child("email").setValue(newEmail)
                self.database.child("usernames").child(user.uid).child("email").setValue(newEmail)
                UserDefaults.standard.setValue(newEmail, forKey: "emailAddress")
                UserDefaults.standard.synchronize()
                completion(nil)
            }
        }
    }
    
    //MARK: Update password - input user of type Firebase and new password -> Returning an optional error type
    public func updatePassword(user: User, newPassword: String, completion: @escaping(Error?) -> Void) {
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(error)
            } else {
                print ("updated password")
                completion(nil)
            }
        }
    }
    
    
    //MARK: Get blocked users - input SearchResult with username -> returning user or void
    public func  getBlockedUsers(userID: String, completion: @escaping ([SearchResult]?) -> Void) {
        database.child("usernames/\(userID)/blocked").observeSingleEvent(of: .value, with: { snapshot in
            guard let values = snapshot.value as? [String: String] else {
                completion(nil)
                return
            }
            var users = [SearchResult]()
            for value in values {
                let user = SearchResult(usernameFriend: value.value, friendID: value.key)
                users.append(user)
            }
            
            let sortedUsers = users.sorted {
                $0.usernameFriend < $1.usernameFriend
            }
            
            completion(sortedUsers)
        })
    }
    
    
    //MARK: - Unblock friend - input friend id -> returning success
    public func unblockFriend(currentID: String, friendID: String, completion: @escaping(Bool) -> Void) {
        database.child("usernames/\(currentID)/blocked/\(friendID)").removeValue { error, _ in
            if error == nil {
                self.database.child("users/\(currentID)/my_friends/\(friendID)/blocked").setValue(false)
                self.database.child("users/\(currentID)/my_friends/\(friendID)/is_friend").setValue(true)
                self.database.child("users/\(friendID)/my_friends/\(currentID)/blocked").setValue(false)
                self.database.child("users/\(friendID)/my_friends/\(currentID)/is_friend").setValue(true)
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    
    //Download general passcode
    public func downloadGeneralPasscode(userID: String, completion: @escaping (String?, Error?) -> Void) {
        database.child("users/\(userID)/general_passcode").observeSingleEvent(of: .value) { snapshot in
            guard let passcode = snapshot.value as? String else {
                completion(nil, DatabaseError.failedToFetch)
                return
            }
            completion(passcode, nil)
        }
    }
    
    //Update general passcode
    public func updateGeneralPasscode(userID: String, newPasscode: String, completion: @escaping (Error?) -> Void) {
        database.child("users/\(userID)/general_passcode").setValue(newPasscode) { error, _ in
            if error == nil {
                completion(nil)
            }
            completion(error)
        }
    }
    
    //Change privacy for specific user
    public func changePrivacy(userID: String, privacy: Bool, completion: @escaping (Error?) -> Void) {
        database.child("users/\(userID)/private").setValue(privacy) { error, _ in
            if error == nil {
                self.database.child("usernames/\(userID)/private").setValue(privacy) { error, _ in
                    if error == nil {
                        completion(nil)
                    }
                    completion(error)
                }
            }
            completion(error)
        }
    }
    
    //MARK: - CHATS HANDLERS / Fetching messages
    ///Fetches all my chats of type Chat -> Returning an array Chat
    public func getAllChats(for userID: String, completion: @escaping(Result<[Chat], Error>) -> Void) {
        
        database.child("users/\(userID)/my_chats").observe(.value, with: { snapshot in
            
            guard let values = snapshot.value as? [String: [String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var myChats = [Chat]()
            for value in values {
                let chatDictionary = value.value
                
                let chatID = value.key
                let usernameFriend = chatDictionary["username_friend"] as? String
                let date = chatDictionary["date"] as? String
                let photoURL = chatDictionary["photo_url"] as? String
                let isRead = chatDictionary["is_read"] as? Bool
                let isContact = chatDictionary["is_friend"] as? Bool
                let latestMessage = chatDictionary["latest_message"] as? String
                let friendID = chatDictionary["friend_id"] as? String
                let messageID = chatDictionary["message_id"] as? String
                
                if usernameFriend != nil {
                    let myChat = Chat(chatID: chatID, username: usernameFriend!, latestMessage: latestMessage!, date: date!, isRead: isRead!, imageURL: photoURL!, userID: friendID!, isContact: isContact!, messageID: messageID!)
                    myChats.append(myChat)
                    print (myChat)
                }
            }
            completion(.success(myChats))
        })
        
    }
    
    
    //Get all my friends -> Returning array of dictionaries
    public func  getAllFriends(userID: String, completion: @escaping (Result<[Friend], Error>) -> Void) {
        database.child("users/\(userID)/my_friends").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var friends = [Friend]()
            for friend in value {
                
                let blocked = friend.value["blocked"] as? Bool
                if blocked != nil {
                    if !blocked! {
                        let id = friend.key
                        let isContact = friend.value["is_friend"] as? Bool
                        let phoneNumberFriend = friend.value["phone_number"] as? String ?? ""
                        let friendsSince = friend.value["friends_since"] as? String
                        let photoURLFriend = friend.value["photo_url"] as? String
                        let username = friend.value["username"] as? String
                        let chatID = friend.value["chat_id"] as? String
                        friends.append(Friend(idFriend: id, blocked: blocked!, chatID: chatID!, friendsSince: friendsSince!, isContact: isContact!, phoneNumberFriend: phoneNumberFriend, photoURLFriend: photoURLFriend!, usernameFriend: username!))
                    }
                }
            }
            let sortedFriends = friends.sorted {
                $0.usernameFriend < $1.usernameFriend
            }
            completion(.success(sortedFriends))
        })
    }
    
    ///Get the common password between both users for encryption/decryption
    public func getEncryptPass(chatID: String, completion: @escaping(String?) -> Void) {
        database.child("chats/\(chatID)/settings/password_encryption").observeSingleEvent(of: .value) { snapshot in
            print (snapshot)
            guard let pass = snapshot.value as? String else {
                return
            }
            completion(pass)
        }
    }
    
    //Clear delete conversation
    public func clearChat(chatID: String, completion: @escaping(Bool) -> Void) {
        database.child("chats/\(chatID)").removeValue { error, _ in
            if error == nil {
                let user = chatID.components(separatedBy: "+")
                let user1 = user[0]
                let user2 = user[1]
                
                self.database.child("users/\(user1)/my_chats/\(chatID)").removeValue()
                self.database.child("users/\(user2)/my_chats/\(chatID)").removeValue()
                
                let randomPasscode1st = Int.random(in: 1000..<9999)
                let randomPasscode2nd = Int.random(in: 1000..<9999)
                let passcodeString = "\(randomPasscode1st)\(randomPasscode2nd)"
                
                let settingsValues : [String: Any] = [
                    "is_friend" : true,
                    "password_encryption" : passcodeString,
                    "receiver_id" : user2,
                    "sender_id" : user1
                ]
                
                self.database.child("chats/\(chatID)/settings").setValue(settingsValues)
                
                completion(true)
                
            }
        }
    }
    
    public func obtainToken(friendID: String, completion: @escaping(String) -> Void) {
        database.child("users_table/\(friendID)/fcmToken").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? String else {
                completion("")
                return
            }
            
            let token = value
            completion(token)
        }
    }
    
    
    
    ///Get all messages for specific user
    public func getAllMessagesForConversations(with chatID: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        
            getEncryptPass(chatID: chatID) { password in
            
                self.database.child("chats/\(chatID)/messages").observe(.value, with: { snapshot in
                    
                    guard let values = snapshot.value as? [String: [String: Any]] else {
                        //completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    
                    var messages: [Message] = []
                    
                    let users = chatID.components(separatedBy: "+")
                    
                    self.database.child("users/\(users[0])/my_chats/\(chatID)/is_read").setValue(true)
                    self.database.child("users/\(users[1])/my_chats/\(chatID)/is_read").setValue(true)
                    
                    for value in values {
                        if !value.value.isEmpty {
                            let valueDictionary = value.value
                            let messageId = value.key
                            guard let text = valueDictionary["text"] as? String,
                                  let dateString = valueDictionary["date"] as? String,
                                  let type_content = valueDictionary["type_content"] as? String,
                                  //                                  let isRead = valueDictionary["is_read"] as? Bool,
                                  let date = ChatViewController.dateFormatter.date(from: dateString) else {
                                return
                            }
                            
                            let senderId = messageId.components(separatedBy: "_")
                            
                            let screenSize: CGRect = UIScreen.main.bounds
                            let screenWidth = screenSize.width
                            var kind: MessageKind?
                            if type_content == "text" {
                                let msg = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: password!, messageID: dateString, encrypt: false)
                                kind = .text(msg)
                                
                            } else if type_content == "photo" {
                                guard let imageURL = URL(string: text), let placeHolder = UIImage(systemName: "photo") else {
                                    return
                                }
                                
                                let media = Media(url: imageURL, image: nil, placeholderImage: placeHolder, size: CGSize(width: 150, height: 150))
                                
                                kind = .photo(media)
                                
                            } else if type_content == "video" {
                                guard let videoURL = URL(string: text), let placeHolder = UIImage(systemName: "video") else {
                                    return
                                }
                                
                                var image = UIImage()
                                
                                let asset = AVAsset(url: videoURL)
                                let assetImgGenerate = AVAssetImageGenerator(asset: asset)
                                assetImgGenerate.appliesPreferredTrackTransform = true
                                
                                let time = CMTimeMake(value: 2, timescale: 1)
                                
                                do {
                                    let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                                    image = UIImage(cgImage: img)
                                } catch let error{
                                    print("Error :: ", error)
                                }
                                
                                let media = Media(url: videoURL, image: image, placeholderImage: placeHolder, size: CGSize(width: 100, height: 100))
                                kind = .video(media)
                                
                            } else if type_content == "attrText" {
                                var colorText = UIColor.systemOrange
                                if senderId[0] == Auth.auth().currentUser?.uid {
                                    //friend text
                                    colorText = UIColor(named: "textBubbleFriendUser")!
                                } else {
                                    //current user
                                    colorText = UIColor(named: "textBubbleCurrentUser")!
                                }
                                //                                let msgLink = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: encryptedPassword, messageID: dateString, encrypt: false)
                                //temporal text without encryption
                                let msgLink = text
                                
                                let attributes: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.preferredFont(forTextStyle: .body),
                                    .foregroundColor: colorText,
                                    .underlineStyle: NSUnderlineStyle.single.rawValue
                                ]
                                
                                let msg = NSAttributedString(string: msgLink, attributes: attributes)
                                kind = .attributedText(msg)
                            } else if type_content == "linkPreview" {
                                
                                let url = URL(string: text)!
                                
                                let colorText = UIColor.systemOrange
                                let attributes: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.preferredFont(forTextStyle: .body),
                                    .foregroundColor: colorText,
                                    .underlineStyle: NSUnderlineStyle.single.rawValue
                                ]
                                
                                let msgAttr = NSAttributedString(string: text, attributes: attributes)

                                let linkPreview = LinkPreview(text: text,
                                                              attributedText: msgAttr,
                                                              url: url,
                                                              title: "test",
                                                              teaser: " ",
                                                              thumbnailImage: UIImage(systemName: "photo")!
                                )
                                
//                                let linkText: NSAttributedString = NSAttributedString(string: text, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
                                kind = .linkPreview(linkPreview)
                            }
                            
                            guard let finalKind = kind else {
                                return
                            }
                            
                            let sender = Sender(photoURL: "", senderId: senderId[0], displayName: "")
                            let message = Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
                            
                            messages.append(message)
                        }
                    }
                    
                    let sortedMessages = messages.sorted {
                        $0.sentDate < $1.sentDate
                    }
                    completion(.success(sortedMessages))
                })
            }
    }
    
    struct LinkPreview: LinkItem {
        var text: String?
        var attributedText: NSAttributedString?
        var url: URL
        var title: String?
        var teaser: String
        var thumbnailImage: UIImage
    }
    
    ///Send a new chat -input username, friendID, friendPhotoURL and a chat of type Message -> Returning a boolean value
    public func sendChat(to chatID: String, usernameFriend: String, friendID: String, previewMessage: String, firstMessage: Message, friendPhotoURL: String, passwordEncrypt: String, isContact: Bool, completion: @escaping(Bool) -> Void) {
        guard let senderInfo = firstMessage.sender as? Sender else {
            return
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        var typeContent = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
            typeContent = "text"
        case .attributedText(let messageAttr):
            print ("entered attributed text")
            typeContent = "attrText"
            message = messageAttr.string
            break
        case .photo(let mediaItem):
            guard let url = mediaItem.url?.absoluteString else {
                return
            }
            message = url
            typeContent = "photo"
            break
        case .video(let mediaItem):
            guard let url = mediaItem.url?.absoluteString else {
                return
            }
            message = url
            typeContent = "video"
        case .location(_):
            print ("entered location")
            break
        case .emoji(_):
            break
        case .audio(_):
            print ("entered audio")
            break
        case .contact(_):
            print ("entered contact")
            break
        case .linkPreview(let messageLink):
            print ("entered link")
            //TODO: Detect links and get a preview
            print (messageLink)
            message = messageLink.text!
            typeContent = "linkPreview"
            break
        case .custom(_):
            print ("entered custom ")
            break
        }
        
        let newChat: [String: Any] = [
            "date": dateString,
            "is_read" : false,
//            "password_encryption" : passwordEncrypt,
            "type_content" : typeContent,
            "text" : message,
        ]
        
        //Create a new common chat on the collection chats - will be available for both users
        let ref = database.child("chats/\(chatID)/messages/\(firstMessage.messageId)")
        
        ref.setValue(newChat) { [self] error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            //Create previews chat for current user
            let previewChats = PreviewChat(
                messageID: firstMessage.messageId,
                chatID: chatID,
                currentUsername: senderInfo.displayName,
                friendUsername: usernameFriend,
                latestMessage: previewMessage,
                date: dateString,
                isRead: false,
                currentImageURL: senderInfo.photoURL,
                friendImageURL: friendPhotoURL,
                currentID: senderInfo.senderId,
                friendID: friendID,
                isContact: isContact)
            
            createPreviewsChat(chats: previewChats, messageID: firstMessage.messageId) { createdPreviews in
                if createdPreviews {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    
    ///Create previews of the chats for current user and friend
    func createPreviewsChat(chats: PreviewChat, messageID: String, completion: @escaping(Bool) -> Void) {
        let previewChats = PreviewChat(
            messageID: messageID,
            chatID: chats.chatID,
            currentUsername: chats.currentUsername,
            friendUsername: chats.friendUsername,
            latestMessage: chats.latestMessage,
            date: chats.date,
            isRead: false,
            currentImageURL: chats.currentImageURL,
            friendImageURL: chats.friendImageURL,
            currentID: chats.currentID,
            friendID: chats.friendID,
            isContact: chats.isContact)
        
        let currentPreviewChat: [String:Any] = [
            "message_id" : messageID,
            "username_friend" : previewChats.friendUsername,
            "date" : previewChats.date,
            "photo_url" : previewChats.friendImageURL,
            "is_read" : previewChats.isRead,
            "latest_message" : previewChats.latestMessage,
            "friend_id" : previewChats.friendID,
            "is_friend" : previewChats.isContact
        ]
        
        let friendPreviewChat: [String:Any] = [
            "message_id" : messageID,
            "username_friend" : previewChats.currentUsername,
            "date" : previewChats.date,
            "photo_url" : previewChats.currentImageURL,
            "is_read" : previewChats.isRead,
            "latest_message" : previewChats.latestMessage,
            "friend_id" : previewChats.currentID,
            "is_friend" : previewChats.isContact
        ]
        
        database.child("users/\(previewChats.currentID)/my_chats").child(previewChats.chatID).setValue(currentPreviewChat) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            self.database.child("users/\(previewChats.friendID)/my_chats").child(previewChats.chatID).setValue(friendPreviewChat) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }
    
    
    //Get phone number, input userID -> Returning user's email
    public func getPhoneWithID(userID: String, completion: @escaping(String?) -> Void) {
        
        database.child("usernames").child(userID).child("phone_number").observeSingleEvent(of: .value) { snapshot in
            guard let phone = snapshot.value as? String else {
                completion(nil)
                return
            }
            completion(phone)
        }
    }
    
    //Get all my friends chats -> Returning array of dictionaries
    public func  getAllFriendsChats(userID: String, completion: @escaping (Result<[Friend], Error>) -> Void) {
        database.child("users/\(userID)/my_friends").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var friends = [Friend]()
            for friend in value {
                let blocked = friend.value["blocked"] as? Bool
                let isContact = friend.value["is_friend"] as? Bool
                
                if blocked == false && isContact == true {//!blocked! {
                    let id = friend.key
                    let isContact = friend.value["is_friend"] as? Bool
                    let phoneNumberFriend = friend.value["phone_number"] as? String ?? ""
                    let friendsSince = friend.value["friends_since"] as? String
                    let photoURLFriend = friend.value["photo_url"] as? String
                    let username = friend.value["username"] as? String
                    let chatID = friend.value["chat_id"] as? String
                    friends.append(Friend(idFriend: id, blocked: blocked!, chatID: chatID!, friendsSince: friendsSince!, isContact: isContact!, phoneNumberFriend: phoneNumberFriend, photoURLFriend: photoURLFriend!, usernameFriend: username!))
                }
            }
            let sortedFriends = friends.sorted {
                $0.usernameFriend < $1.usernameFriend
            }
            completion(.success(sortedFriends))
        })
    }
    
    //Change if saving in album
    public func changeSaveInAlbum(userID: String, friendID: String, changeSetting: Bool, completion: @escaping (Bool) -> Void) {
        database.child("users/\(userID)/my_friends/\(friendID)/save_in_album").observeSingleEvent(of: .value) { snapshot in
            var changeValue = false
            if let value = snapshot.value as? Bool {
                if changeSetting {
                    if !value {
                        changeValue = true
                    }
                    self.database.child("users/\(userID)/my_friends/\(friendID)/save_in_album").setValue(changeValue)
                    completion(changeValue)
                } else {
                    completion(value)
                }
            } else {
                self.database.child("users/\(userID)/my_friends/\(friendID)/save_in_album").setValue(changeValue)
                completion(changeValue)
            }
        }
    }
    
    public func getInitialMessage(with chatID: String, completion: @escaping (String?, String?) -> Void) {
        self.database.child("chats/\(chatID)/messages").observe(.value, with: { snapshot in
            
            guard let values = snapshot.value as? [String: [String: Any]] else {
                completion(nil, nil)
                return
            }
            
            guard let message = values.first?.value["text"] as? String, let passwordEncryption = values.first?.value["password_encryption"] as? String else {
                completion(nil, nil)
                return
            }
            completion(message, passwordEncryption)
        })
    }
    
    public func blockFriend(chatID: String, currentID: String, friendID: String, friendUsername: String, completion: @escaping(Bool) -> Void) {
        
        database.child("usernames/\(currentID)/blocked/\(friendID)").setValue(friendUsername) { error, _ in
            if error == nil {
                
                //self.database.child("usernames/\(currentID)/blocked/\(friendID)").setValue(friendUsername)
                
                self.clearChat(chatID: chatID) { success in
                    if success {
                        
                        self.database.child("users/\(currentID)/my_friends/\(friendID)/blocked").setValue(true)
                        self.database.child("users/\(currentID)/my_friends/\(friendID)/is_friend").setValue(false)
                        self.database.child("users/\(friendID)/my_friends/\(currentID)/blocked").setValue(true)
                        self.database.child("users/\(friendID)/my_friends/\(currentID)/is_friend").setValue(false)
                        completion(success)
                    }
                }
            }
        }
    }
    
    public func deleteFriend(chatID: String, completion: @escaping(Bool) -> Void) {
        
        database.child("chats/\(chatID)").removeValue { error, _ in
            print (error as Any)
        }
        
        let user = chatID.components(separatedBy: "+")
        
        let user1 = user[0]
        let user2 = user[1]
        
        database.child("users/\(user1)/my_chats/\(chatID)").removeValue { error, _ in
            print (error as Any)
        }
        database.child("users/\(user1)/my_friends/\(user2)").removeValue { error, _ in
            print (error as Any)
        }
        
        database.child("users/\(user2)/my_chats/\(chatID)").removeValue { error, _ in
            print (error as Any)
        }
        database.child("users/\(user2)/my_friends/\(user1)").removeValue { error, _ in
            print (error as Any)
        }
    }
    
    
    public func searchForChatID(currentUserID: String, friendID: String, completion: @escaping(String?) -> Void) {
        
        let mergedChatID1 = currentUserID + "+" + friendID
        let mergedChatID2 = friendID + "+" + currentUserID
        
        database.child("users/\(currentUserID)/my_chats").observe(.value, with: { snapshot in
            
            guard let myChats = snapshot.value as? [String: [String: Any]] else {
                completion(nil)
                return
            }
            var chatID = ""
            for myChat in myChats {
                if myChat.key == mergedChatID1 || myChat.key == mergedChatID2 {
                    chatID = myChat.key
                    completion(chatID)
                    break
                }
            }
            if chatID == "" {
                completion(nil)
            }
        })
    }
    
    
    //Get all users -> Returning array of dictionaries
    public func  getAllUsers(currentUserID: String, userToSearch: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        
        getAllFriends(userID: currentUserID) { result in
            switch result {
            case .success(let gotFriends):
                
                self.database.child("usernames").observeSingleEvent(of: .value, with: { snapshot in
                    guard let values = snapshot.value as? [String: [String: Any]] else {
                        //completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    var users = [String: String]()
                    var maxUsersToShow = 0
                    
                    for value in values {
                        var isBlocked = false
                        if value.value[currentUserID] as? String == "blocked" {
                            isBlocked = true
                        }
                        
                        if isBlocked == false && value.value["private"] as? Bool == false {
                            let friendUsername = value.value["username"] as? String
                            
                            if friendUsername != "" && friendUsername != nil {
                                if friendUsername!.hasPrefix(userToSearch.lowercased()) && maxUsersToShow <= 10 {
                                    var isFriend = false
                                    
                                    for friend in gotFriends {
                                        if friendUsername == friend.usernameFriend {
                                            isFriend = true
                                            break
                                        }
                                    }
                                    
                                    if isFriend == false {
                                        maxUsersToShow += 1
                                        users[value.key] = friendUsername
                                    }
                                    
                                } else if maxUsersToShow == 10 {
                                    break
                                    
                                }
                            }
                        }
                    }
                    print (users)
                    completion(.success(users))
                })
            case .failure(let error):
                print (error)
            }
        }
    }
    
    //Get all users when user dont have any contact -> Returning array of dictionaries
    public func  getAllUsersNoContactsYet(currentUserID: String, userToSearch: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        
        self.database.child("usernames").observeSingleEvent(of: .value, with: { snapshot in
            guard let values = snapshot.value as? [String: [String: Any]] else {
                //completion(.failure(DatabaseError.failedToFetch))
                return
            }
            var users = [String: String]()
            var maxUsersToShow = 0
            
            for value in values {
                var isBlocked = false
                
                if value.value[currentUserID] as? String == "blocked" {
                    isBlocked = true
                }
                
                if isBlocked == false && value.value["private"] as? Bool == false {
                    
                    let friendUsername = value.value["username"] as? String
                    
                    if friendUsername != "" && friendUsername != nil {
                        if friendUsername!.hasPrefix(userToSearch.lowercased()) {
                            
                            if users[value.key] != currentUserID {
                                maxUsersToShow += 1
                                users[value.key] = friendUsername
                            }
                            
                        }
                        
                        if maxUsersToShow == 9 {
                            break
                        }
                    }
                }
            }
            
            print (users)
            completion(.success(users))
        })
        
}
    
    
    //Get all users by email -> Returning array of dictionaries
    public func  searchUserByEmail(currentUserID: String, emailToSearch: String, completion: @escaping (SearchResult?) -> Void) {
        database.child("usernames").observeSingleEvent(of: .value, with: { snapshot in
            
            guard let values = snapshot.value as? [String: [String: Any]] else {
                completion(nil)
                return
            }
            for value in values {
                var isBlocked = false
                if value.value[currentUserID] as? String == "blocked" {
                    isBlocked = true
                }
                
                if isBlocked == false && value.value["private"] as? Bool == false {
                    if value.value["email"] as? String == emailToSearch {
                        let usernameFound = value.value["username"] as? String
                        let friendID = value.key
                        let users = SearchResult(usernameFriend: usernameFound!, friendID: friendID)
                        print (users)
                        completion(users)
                    }
                }
            }
            completion(nil)
        })
    }
    
    
    //Get all users -> Returning array of dictionaries
    public func  getAllPrivateUsers(phoneNumberToLook: String, completion: @escaping (SearchResult?) -> Void) {
        database.child("usernames").observeSingleEvent(of: .value, with: { snapshot in
            guard let usernames = snapshot.value as? [String: [String: Any]] else {
                completion(nil)
                return
            }
            
            var users: SearchResult?
            var isBlocked = false
            for user in usernames {
                if user.value["phone_number"] as? String == phoneNumberToLook {
                    if let blockeds = user.value["blocked"] as? [String: String] {
                        for blocked in blockeds {
                            if blocked.key == Auth.auth().currentUser?.uid {
                                isBlocked = true
                                break
                            }
                        }
                    }
                    if !isBlocked {
                        let usernameFriend = user.value["username"] as? String
                        let friendID = user.key
                        users = SearchResult(usernameFriend: usernameFriend!, friendID: friendID)
                        completion(users)
                        break
                    }
                }
            }
            completion(users)
        })
    }
    
    public func addNewContact(friendID: String, currectUsername: String, currentID: String, currentPhotoURL: String, chatID: String, friendPhotoURL: String, usernameFriend: String, completion: @escaping (Bool) -> Void) {
        
        let date = Date()
        let dateString = ChatViewController.dateFormatter.string(from: date)
        
        let randomPasscode1st = Int.random(in: 1000..<9999)
        let randomPasscode2nd = Int.random(in: 1000..<9999)
        let passcodeString = "\(randomPasscode1st)\(randomPasscode2nd)"
        
        
        let myNewFriend: [String: Any] = [
            "blocked" : false,
            "chat_id" : chatID,
            "friends_since" : dateString,
            "is_friend" : true,
            "photo_url" : friendPhotoURL,
            "username" : usernameFriend
        ]
        
        let newFriend: [String: Any] = [
            "blocked" : false,
            "chat_id" : chatID,
            "friends_since" : dateString,
            "is_friend" : true,
            "photo_url" : currentPhotoURL,
            "username" : currectUsername
        ]
        
        var newContact: [String: Any] = [
            "blocked" : false,
            "chat_id" : chatID,
            "friends_since" : dateString,
            "is_friend" : true,
            "photo_url" : friendPhotoURL,
            "username" : usernameFriend,
            "friendID" : friendID
        ]
        
        let settingsValues : [String: Any] = [
            "is_friend" : true,
            "password_encryption" : passcodeString,
            "receiver_id" : friendID,
            "sender_id" : currentID
        ]
        
        database.child("users/\(friendID)/my_friends/\(currentID)").setValue(newFriend)
        database.child("users/\(currentID)/my_friends/\(friendID)").setValue(myNewFriend)
        
        database.child("chats/\(chatID)/settings").setValue(settingsValues)
        
        database.child("users/\(currentID)/my_friends/\(friendID)").setValue(newContact) { error, ref in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
                completion(false)
            } else {
                print("added document\(ref)")
                newContact["friendID"] = currentID
                newContact["username"] = currectUsername
                self.database.child("users/\(friendID)/my_friends/\(currentID)").setValue(newContact)
                
                completion(true)
            }
        }
    }
    
    

    //Search for a user, input phone number -> Returning username and isPrivate
    public func searchForIDsWithPhones(phoneNumbers: [String], completion: @escaping([String]?) -> Void) {
        
        database.child("usernames").observeSingleEvent(of: .value) { snapshot in
            guard let usernames = snapshot.value as? [String: Any] else {
                return
            }
            
            var friendIDs = [String]()
            for phoneNumber in phoneNumbers {
                for username in usernames {
                    let friendValues = username.value as? [String: Any]
                    let phoneNumberDB = friendValues!["phone_number"] as? String
                    if phoneNumberDB == phoneNumber {
                        let friendId = username.key
                        friendIDs.append(friendId)
                        break
                    }
                }
            }
            completion (friendIDs)
        }
    }
}

