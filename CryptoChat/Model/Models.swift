//
//  Models.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/1/21.
//

import UIKit
import Contacts
import MessageKit


struct UserInformation {
    let idUser: String
    let username: String
    //let emailAddress: String
    let phoneNumber: String
    let profileImageUrl: String
}


struct Chat {
    let chatID: String
    let username: String
    let latestMessage: String
    let date: String
    let isRead: Bool
    let imageURL: String
    let userID: String
    let isFriend: Bool
    let messageID: String
}


struct PreviewChat {
    let messageID: String
    let chatID: String
    let currentUsername: String
    let friendUsername: String
    let latestMessage: String
    let date: String
    let isRead: Bool
    let currentImageURL: String
    let friendImageURL: String
    let currentID: String
    let friendID: String
    let isFriend: Bool
}

struct Friend {
    let idFriend: String
    let blocked: Bool
    let chatID: String
    let friendsSince: String
    let isFriend: Bool
    let phoneNumberFriend: String
    let photoURLFriend: String
    let usernameFriend: String
}

struct ContactNumber {
    let firstName: String
    let lastName: String
    let profilePhoto: Data?
    let phoneNumber: String?
    let labelNumber: String?
}


struct SearchResult {
    let usernameFriend: String
    let friendID: String
}


struct UserLocalInformation {
    let phoneNumber: String
    let username: String
    let isPrivate: Bool
    let profilePhotoURL: String
    let generalPasscode: String
}

