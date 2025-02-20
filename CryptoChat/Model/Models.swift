//
//  Models.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/4/24.
//

import UIKit
import Contacts
import MessageKit

struct UserLocalInformation {
    let phoneNumber: String
    let username: String
    let isPrivate: Bool
    let profilePhotoURL: String
    let generalPasscode: String
}

struct UserInformation {
    let idUser: String
    let fullname: String?
    let username: String?
    let emailAddress: String?
    let phoneNumber: String?
    let profileImageUrl: String?
}

struct SearchResult {
    let usernameFriend: String
    let friendID: String
}

struct Chat {
    let chatID: String
    let username: String
    let latestMessage: String
    let date: String
    let isRead: Bool
    let imageURL: String
    let userID: String
    let isContact: Bool
    let messageID: String
}

struct Friend {
    let idFriend: String
    let blocked: Bool
    let chatID: String
    let friendsSince: String
    let isContact: Bool
    let phoneNumberFriend: String
    let photoURLFriend: String
    let usernameFriend: String
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
    let isContact: Bool
}

struct ContactNumber {
    let firstName: String
    let lastName: String
    let profilePhoto: Data?
    let phoneNumber: String?
    let labelNumber: String?
}
