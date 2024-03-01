//
//  DatabaseMng.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/2/21.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import MessageKit
import AVKit

final class DatabaseMng {
    static let shared = DatabaseMng()
    private let database = Database.database().reference()
    
    
    //MARK: - USERS HANDLERS
    //Create new user in real time database -> Returning boolean value
    public func createNewUser(with user: UserInformation, countryCode: String, completion: @escaping(Bool) -> Void) {
        
        let userElement: [String: Any] = [
            "country_code" : countryCode,
            "general_passcode" : "0000",
            "username" : user.username,
            "profile_image_url" : user.profileImageUrl,
            "private" : false
        ]
        //Set values on users collection
        database.child("users").child(user.idUser).setValue(userElement, withCompletionBlock: { error, _ in
            guard error == nil else {
                print ("failed writing user information in DB ")
                completion(false)
                return
            }
        })
        
        //Set values on usernames collection
        let usernameElement : [String: Any] = [
            "phone_number" : user.phoneNumber,
            "private" : false,
            "username" : user.username
        ]
        database.child("usernames").child(user.idUser).setValue(usernameElement, withCompletionBlock: { error, _ in
            guard error == nil else {
                print ("failed writing user in usernames in DB ")
                completion(false)
                return
            }
        })
        
        completion(true)
    }
    
    //Look up for a unique username -> Returning a boolean value
    public func lookUniqueUsers(with usernameToLookup: String, completion: @escaping(Bool?) -> Void) {
        database.child("usernames").observeSingleEvent(of: .value) { snapshot in
            guard let usernames = snapshot.value as? [String: [String: Any]] else {
                completion(nil)
                return
            }
            var foundUser: Bool?
            
            for username in usernames {
                if username.value["username"] as? String == usernameToLookup {
                    foundUser = true
                    break
                } else {
                    foundUser = false
                }
            }
            completion(foundUser)
        }
    }
    
    //Look up for a unique phone number -> Returning a boolean value
    public func lookUniquePhoneNUmber(with numberToLookup: String, completion: @escaping(Bool?) -> Void) {
        database.child("usernames").observeSingleEvent(of: .value) { snapshot in
            guard let users = snapshot.value as? [String: [String: Any]] else {
                completion(nil)
                return
            }
            var foundPhoneNumber: Bool?
            
            for user in users {
                if user.value["phone_number"] as? String == numberToLookup {
                    foundPhoneNumber = true
                    break
                } else {
                    foundPhoneNumber = false
                }
            }
            completion(foundPhoneNumber)
        }
    }
    
    //Search for a user, input username or email -> Returning user's email
    public func searchForUsernames(with username: String, emailToLook: String, completion: @escaping(String?, Bool?) -> Void) {
        var lookForUsername = true
        if username == "" {
            lookForUsername = false
        }
        
        database.child("usernames").observeSingleEvent(of: .value) { snapshot in
            guard let usernames = snapshot.value as? [String: [String: Any]] else {
                return
            }
            
            var userFound: String?
            var isPrivate: Bool?
            for usernameValue in usernames {
                if lookForUsername {
                    if usernameValue.value["username"] as! String == username {
                        userFound = usernameValue.key
                        isPrivate = usernameValue.value["private"] as? Bool
                        break
                    }
                } else {
                    if usernameValue.key == emailToLook {
                        userFound = usernameValue.value["username"] as? String //as! string
                        isPrivate = usernameValue.value["private"] as? Bool
                        completion(userFound, isPrivate!)
                        break
                    }
                }
            }
            if userFound != nil {
                self.getEmailWithID(userID: userFound!) { emailFound in
                    completion(emailFound, isPrivate!)
                }
            } else {
                completion(userFound, isPrivate)
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
    
    //Get email, input userID -> Returning user's email
    public func getEmailWithID(userID: String, completion: @escaping(String) -> Void) {
        
        database.child("users").child(userID).observeSingleEvent(of: .value) { snapshot in
            guard let userInformation = snapshot.value as? [String: Any] else {
                return
            }
            guard let email = userInformation["email_address"] as? String else {
                return
            }
            completion(email)
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
    
    
    
    //Update username - input old/new username and user ID -> Returning a boolean value
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
            UserDefaults.standard.set(newUsername, forKey: "username")
            UserDefaults.standard.synchronize()
            completion(true)
        })
    }
    
    //Update phone number
    public func updatePhoneNumber(userID: String, phoneNumber: String, completion: @escaping(Bool?) -> Void) {
        database.child("usernames/\(userID)/phone_number").setValue(phoneNumber) { error, _ in
            if error == nil {
                completion(true)
            }
            completion(nil)
        }
    }
    
    //Update email - input user of type Firebase and new email -> Returning an optional error type
    public func updateEmail(user: User, newEmail: String, username: String, completion: @escaping(Error?) -> Void) {
        user.updateEmail(to: newEmail) { error in
            if let error = error {
                completion(error)
            } else {
                print ("updated email")
                self.database.child("users").child(user.uid).child("email_address").setValue(newEmail)
                UserDefaults.standard.setValue(newEmail, forKey: "emailAddress")
                UserDefaults.standard.synchronize()
                completion(nil)
            }
        }
    }
    
    //Update password - input user of type Firebase and new password -> Returning an optional error type
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
    
    //Get all users -> Returning array of dictionaries
    public func  getAllUsers(completion: @escaping (Result<[String: String], Error>) -> Void) {
        database.child("usernames").observeSingleEvent(of: .value, with: { snapshot in
            guard let values = snapshot.value as? [String: [String: Any]] else {
                //completion(.failure(DatabaseError.failedToFetch))
                return
            }
            var users = [String: String]()
            for value in values {
                
                var isBlocked = false
                if let blockeds = value.value["blocked"] as? [String: String] {
                    for blocked in blockeds {
                        if blocked.key == Auth.auth().currentUser?.uid {
                            isBlocked = true
                            break
                        }
                    }
                }
                
                if !isBlocked {
                    if value.value["private"] as? Bool  == false {
                        users[value.key] = value.value["username"] as? String
                    }
                }
            }
            print (users)
            completion(.success(users))
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
                        let isFriend = friend.value["is_friend"] as? Bool
                        let phoneNumberFriend = friend.value["phone_number"] as? String
                        let friendsSince = friend.value["friends_since"] as? String
                        let photoURLFriend = friend.value["photo_url"] as? String
                        let username = friend.value["username"] as? String
                        let chatID = friend.value["chat_id"] as? String
                        friends.append(Friend(idFriend: id, blocked: blocked!, chatID: chatID!, friendsSince: friendsSince!, isFriend: isFriend!, phoneNumberFriend: phoneNumberFriend!, photoURLFriend: photoURLFriend!, usernameFriend: username!))
                    }
                }
            }
            let sortedFriends = friends.sorted {
                $0.usernameFriend < $1.usernameFriend
            }
            completion(.success(sortedFriends))
        })
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
                let isFriend = friend.value["is_friend"] as? Bool
                
                if blocked == false && isFriend == true {//!blocked! {
                    let id = friend.key
                    let isFriend = friend.value["is_friend"] as? Bool
                    let phoneNumberFriend = friend.value["phone_number"] as? String
                    let friendsSince = friend.value["friends_since"] as? String
                    let photoURLFriend = friend.value["photo_url"] as? String
                    let username = friend.value["username"] as? String
                    let chatID = friend.value["chat_id"] as? String
                    friends.append(Friend(idFriend: id, blocked: blocked!, chatID: chatID!, friendsSince: friendsSince!, isFriend: isFriend!, phoneNumberFriend: phoneNumberFriend!, photoURLFriend: photoURLFriend!, usernameFriend: username!))
                }
            }
            let sortedFriends = friends.sorted {
                $0.usernameFriend < $1.usernameFriend
            }
            completion(.success(sortedFriends))
        })
    }
    
    //Change privacy for specific user
    public func changePrivacy(userID: String, privacy: Bool, completion: @escaping (Error?) -> Void) {
        database.child("usernames/\(userID)/phone_number").observeSingleEvent(of: .value) { [self] snapshot in
            let value = snapshot.value as! String
            if value.count == 10 {
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
            } else {
                completion(DatabaseError.wrongPhoneNumber)
            }
        }
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
    
    public func downloadGeneralPasscode(userID: String, completion: @escaping (String?, Error?) -> Void) {
        
        database.child("users/\(userID)/general_passcode").observeSingleEvent(of: .value) { snapshot in
            guard let passcode = snapshot.value as? String else {
                completion(nil, DatabaseError.failedToFetch)
                return
            }
            
            completion(passcode, nil)
        }
    }
    
    public func updateGeneralPasscode(userID: String, newPasscode: String, completion: @escaping (Error?) -> Void) {
        
        database.child("users/\(userID)/general_passcode").setValue(newPasscode) { error, _ in
            if error == nil {
                completion(nil)
            }
            completion(error)
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
    
    
    //MARK: - CHATS HANDLERS / Creating messages
    ///Send a new chat -input username, friendID, friendPhotoURL and a chat of type Message -> Returning a boolean value
    public func createNewChat(usernameFriend: String, friendID: String, firstMessage: Message, friendPhotoURL: String, passwordEncrypt: String, chatID: String, completion: @escaping(Bool) -> Void) {
        guard let senderInfo = firstMessage.sender as? Sender else {
            return
        }
        
        guard let currentPhoneNumber = UserDefaults.standard.value(forKey: "phoneNumber") as? String else {
            return
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        getPhoneWithID(userID: friendID) { phoneNumber in
            guard let phoneNumberFriend = phoneNumber else {
                return
            }
            
            if !phoneNumberFriend.isEmpty {
                
                let newChat: [String: Any] = [
                    "date": dateString,
                    "is_read" : false,
                    "password_encryption" : passwordEncrypt,
                    "text" : message,
                    "type_content" : "text"
                ]
                
                let newChatArray: [String: Any] = [
                    firstMessage.messageId : newChat
                ]
                //Create a new common chat on the collection chats - will be available for both users
                let ref = self.database.child("chats/\(chatID)/messages")
                ref.setValue(newChatArray) { [self] error, _ in
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
                        latestMessage: message,
                        date: dateString,
                        isRead: false,
                        currentImageURL: senderInfo.photoURL,
                        friendImageURL: friendPhotoURL,
                        currentID: senderInfo.senderId,
                        friendID: friendID,
                        isFriend: false)
                    
                    createPreviewsChat(chats: previewChats, messageID: firstMessage.messageId) { createdPreviews in
                        if createdPreviews {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                }
                
                let toDelete : [String: String] = [
                    "receiver" : "",
                    "sender" : firstMessage.messageId
                ]
                
                let settingsValues : [String: Any] = [
                    "is_friend" : false,
                    "password_encryption" : passwordEncrypt,
                    "receiver_id" : friendID,
                    "sender_id" : senderInfo.senderId,
                    "to_delete" : toDelete
                ]
                
                let myNewFriend: [String: Any] = [
                    "blocked" : false,
                    "chat_id" : chatID,
                    "friends_since" : dateString,
                    "is_friend" : false,
                    "phone_number" : phoneNumberFriend,
                    "photo_url" : friendPhotoURL,
                    "username" : usernameFriend
                ]
                self.database.child("users/\(senderInfo.senderId)/my_friends/\(friendID)").setValue(myNewFriend)
                
                let newFriend: [String: Any] = [
                    "blocked" : false,
                    "chat_id" : chatID,
                    "friends_since" : dateString,
                    "is_friend" : false,
                    "phone_number" : currentPhoneNumber,
                    "photo_url" : senderInfo.photoURL,
                    "username" : senderInfo.displayName
                ]
                self.database.child("users/\(friendID)/my_friends/\(senderInfo.senderId)").setValue(newFriend)
                
                self.database.child("chats/\(chatID)/settings").setValue(settingsValues)
                
                self.database.child("users/\(senderInfo.senderId)/blocked/\(friendID)").removeValue { error, _ in
                    if error == nil {
                        self.database.child("usernames/\(senderInfo.senderId)/blocked/\(friendID)").removeValue()
                    }
                }
                
            }
        }
    }
    
    
    
    ///Send a new chat -input username, friendID, friendPhotoURL and a chat of type Message -> Returning a boolean value
    public func sendChat(to chatID: String, usernameFriend: String, friendID: String, firstMessage: Message, friendPhotoURL: String, passwordEncrypt: String, isFriend: Bool, receiverAccepted: Bool, completion: @escaping(Bool) -> Void) {
        guard let senderInfo = firstMessage.sender as? Sender else {
            return
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        var typeContent = ""
        var latestMessage = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
            typeContent = "text"
            latestMessage = message
        case .attributedText(let messageAttr):
            print ("entered attributed text")
            typeContent = "attrText"
            latestMessage = messageAttr.string
            message = messageAttr.string
            break
        case .photo(let mediaItem):
            guard let url = mediaItem.url?.absoluteString else {
                return
            }
            message = url
            typeContent = "photo"
            latestMessage = "Photo Encrypted"
            break
        case .video(let mediaItem):
            guard let url = mediaItem.url?.absoluteString else {
                return
            }
            message = url
            typeContent = "video"
            latestMessage = "Video Encrypted"
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
        case .linkPreview(_):
            print ("entered link")
            break
        case .custom(_):
            print ("entered custom ")
            break
        }
        
        let newChat: [String: Any] = [
            "date": dateString,
            "is_read" : false,
            "password_encryption" : passwordEncrypt,
            "type_content" : typeContent,
            "text" : message,
        ]
        
        database.child("chats/\(chatID)/settings/is_friend").setValue(isFriend)
        database.child("chats/\(chatID)/settings/password_encryption").setValue(passwordEncrypt)
        
        if receiverAccepted {
            database.child("chats/\(chatID)/settings/to_delete/receiver").setValue(firstMessage.messageId)
        }
        
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
                latestMessage: latestMessage,
                date: dateString,
                isRead: false,
                currentImageURL: senderInfo.photoURL,
                friendImageURL: friendPhotoURL,
                currentID: senderInfo.senderId,
                friendID: friendID,
                isFriend: isFriend)
            
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
            isFriend: chats.isFriend)
        
        let currentPreviewChat: [String:Any] = [
            "message_id" : messageID,
            "username_friend" : previewChats.friendUsername,
            "date" : previewChats.date,
            "photo_url" : previewChats.friendImageURL,
            "is_read" : previewChats.isRead,
            "latest_message" : previewChats.latestMessage,
            "friend_id" : previewChats.friendID,
            "is_friend" : previewChats.isFriend
        ]
        
        let friendPreviewChat: [String:Any] = [
            "message_id" : messageID,
            "username_friend" : previewChats.currentUsername,
            "date" : previewChats.date,
            "photo_url" : previewChats.currentImageURL,
            "is_read" : previewChats.isRead,
            "latest_message" : previewChats.latestMessage,
            "friend_id" : previewChats.currentID,
            "is_friend" : previewChats.isFriend
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
    
    ///Delete the sent request / approved request messages
    public func encryptInitialMessage(chatID: String, passwordEncrypt: String, friendUsername: String, currentUsername: String, completion: @escaping(Bool) -> Void) {
        database.child("chats/\(chatID)/settings/to_delete").observeSingleEvent(of: .value) { snapshot in
            guard let messages = snapshot.value as? [String: String] else {
                completion(false)
                return
            }
            
            guard let msgID = messages["sender"] else { //let msg2 = messages["sender"] else {
                completion(false)
                return
            }
            
            let dateString = msgID.split(separator: "+")
            let idDate = String(dateString[1])
            
            let encryptedText = Encryption.shared.encryptDecrypt(oldMessage: "Hi & Bye? 😶‍🌫️", encryptedPassword: passwordEncrypt, messageID: idDate, encrypt: true)
            self.database.child("chats/\(chatID)/messages/\(msgID)/text").setValue(encryptedText)
            
            let userID = chatID.split(separator: "+")
            self.database.child("users/\(userID[0])/my_chats/\(chatID)/latest_message").setValue("Hi & Bye 😶‍🌫️")
            self.database.child("users/\(userID[1])/my_chats/\(chatID)/latest_message").setValue("Hi & Bye 😶‍🌫️")
            
            self.database.child("users/\(userID[0])/my_friends/\(userID[1])/is_friend").setValue(true)
            self.database.child("users/\(userID[1])/my_friends/\(userID[0])/is_friend").setValue(true)
            
            
            completion(true)
            
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
                
                guard let isFriend = chatDictionary["is_friend"] as? Bool  else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                if isFriend {
                    let chatID = value.key
                    let usernameFriend = chatDictionary["username_friend"] as? String
                    let date = chatDictionary["date"] as? String
                    let photoURL = chatDictionary["photo_url"] as? String
                    let isRead = chatDictionary["is_read"] as? Bool
                    let latestMessage = chatDictionary["latest_message"] as? String
                    let friendID = chatDictionary["friend_id"] as? String
                    let messageID = chatDictionary["message_id"] as? String
                    
                    let myChat = Chat(chatID: chatID, username: usernameFriend!, latestMessage: latestMessage!, date: date!, isRead: isRead!, imageURL: photoURL!, userID: friendID!, isFriend: isFriend, messageID: messageID!)
                    myChats.append(myChat)
                }
            }
            print (myChats)
            completion(.success(myChats))
        })
    }
    
    public func searchForChatID(currentUserID: String, friendID: String, completion: @escaping(String?, Bool?) -> Void) {
        
        database.child("users/\(currentUserID)/my_friends").observe(.value, with: { snapshot in
            
            guard let friends = snapshot.value as? [String: [String: Any]] else {
                completion(nil, nil)
                return
            }
            
            var chatID = String()
            var isFriend = Bool()
            for friend in friends {
                if friend.key == friendID {
                    let friendValues = friend.value
                    chatID = (friendValues["chat_id"] as? String)!
                    isFriend = (friendValues["is_friend"] as? Bool)!
                    break
                }
            }
            completion(chatID, isFriend)
        })
    }
    
    ///Verify if is friend (approved to chat)
    public func isFriend(chatID: String, completion: @escaping (Bool) -> Void) {
        database.child("chats/\(chatID)/settings").observeSingleEvent(of: .value) { snapshot in
            guard let settings = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            let isFriend = settings["is_friend"] as? Bool
            completion(isFriend!)
        }
    }
    public func isFriendCheckID(friendID: String, currentID: String, completion: @escaping (Bool) -> Void) {
        database.child("users/\(currentID)/my_friends").observeSingleEvent(of: .value) { snapshot in
            guard let friends = snapshot.value as? [String: [String: Any]] else {
                completion(false)
                return
            }
            var isFriend = false
            for friend in friends {
                if friend.key == friendID {
                    if friend.value["is_friend"] as? Bool != nil {
                        isFriend = (friend.value["is_friend"] as? Bool)!
                        break
                    }
                }
            }
            completion(isFriend)
        }
    }
    
    ///Get all messages for specific user
    public func getAllMessagesForConversations(with chatID: String, encryptedText: Bool, completion: @escaping (Result<[Message], Error>) -> Void) {
        
        if !encryptedText {
            getEncryptPass(chatID: chatID) { password in
                guard let encryptedPassword = password else {
                    return
                }
                
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
                            if type_content == "photo" {
                                guard let imageURL = URL(string: text), let placeHolder = UIImage(systemName: "photo") else {
                                    return
                                }
                                
                                let media = Media(url: imageURL, image: nil, placeholderImage: placeHolder, size: CGSize(width: screenWidth - 80, height: screenWidth - 80))
                                
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
                                let msgLink = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: encryptedPassword, messageID: dateString, encrypt: false)
                                let attributes: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.preferredFont(forTextStyle: .body),
                                    .foregroundColor: colorText,
                                    .underlineStyle: NSUnderlineStyle.single.rawValue
                                ]
                                
                                let msg = NSAttributedString(string: msgLink, attributes: attributes)
                                kind = .attributedText(msg)
                            } else {
                                let msg = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: encryptedPassword, messageID: dateString, encrypt: false)
                                kind = .text(msg)
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
        } else {
            
            self.database.child("chats/\(chatID)/messages").observe(.value, with: { snapshot in
                
                guard let values = snapshot.value as? [String: [String: Any]] else {
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
                              //let isRead = valueDictionary["is_read"] as? Bool,
                              let date = ChatViewController.dateFormatter.date(from: dateString) else {
                            return
                        }
                        
                        let senderId = messageId.components(separatedBy: "_")
                        
                        var kind: MessageKind?
                        
                        if type_content == "photo" {
                            guard let imageURL = StarterViewController.createLocalUrl(forImageNamed: "logoClosed.png"), let placeHolder = UIImage(systemName: "photo") else {
                                return
                            }
                            
                            let media = Media(url: imageURL, image: nil, placeholderImage: placeHolder, size: CGSize(width: 35, height: 35))
                            kind = .photo(media)
                        } else if type_content == "video" {
                            guard let videoURL = StarterViewController.createLocalUrl(forImageNamed: "video-locked-icon"), let placeHolder = UIImage(systemName: "video") else {
                                return
                            }
                            
                            let media = Media(url: videoURL, image: nil, placeholderImage: placeHolder, size: CGSize(width: 35, height: 35))
                            kind = .photo(media)
                            
                        } else {
                            kind = .text(text)
                            
                        }
                        
                        guard let finalKind = kind else {
                            return
                        }
                        
                        let sender = Sender(photoURL: "", senderId: senderId[0], displayName: "")
                        let message = Message(
                            sender: sender,
                            messageId: messageId,
                            sentDate: date,
                            kind: finalKind)
                        
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
    
    ///Fetching the already read conversations
    //    public func isRead(for userID: String, in chatID: String, isRead: Bool, completion: @escaping(Bool?) -> Void) {
    //        database.child("users/\(userID)/my_chats/\(chatID)/is_read").setValue(isRead) { error, _ in
    //            if error == nil {
    //                completion(true)
    //            } else {
    //                return
    //            }
    //        }
    //
    //    }
    
    public enum DatabaseError: Error {
        case failedToFetch
        case wrongPhoneNumber
    }
    
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
    
    //Get phone number, input userID -> Returning user's email
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
    
    public func clearChat(chatID: String, completion: @escaping(Bool) -> Void) {
        database.child("chats/\(chatID)").removeValue { error, _ in
            if error == nil {
                let user = chatID.components(separatedBy: "+")
                let user1 = user[0]
                let user2 = user[1]
                
                self.database.child("users/\(user1)/my_chats/\(chatID)").removeValue()
                self.database.child("users/\(user2)/my_chats/\(chatID)").removeValue()
                completion(true)
                
            }
        }
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
    
    
    
}


