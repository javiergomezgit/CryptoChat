//
//  Encryption.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/19/21.
//

import Foundation
import UIKit
import LinkPresentation

//let oldMessage = "hola como estas, como te va, espero todo bien 😃"
//let pass = "12342434"
//let chatid = "Jul 28, 2021 at 6:56:03 AM PDT"

let dateInMexico = "16 Sep 2021 12:13:27 PDT"
let dateInUSA = "Sep 16, 2021 3:08:31 PM -0000"


//let formatter = DateFormatter()
//formatter.dateFormat = "MMM d, yyyy h:mm:ss a ZZZ"
//let showDate = formatter.date(from: dateInUSA)
//print (showDate)
//formatter.dateFormat = "MMM d, yyyy"
//let result = formatter.string(from: showDate!)
//print (result)
////mexico
//formatter.dateFormat = "d MMM, yyyy h:mm:ss a ZZZ"
//let resultspa = formatter.string(from: showDate!)
//print (resultspa)





/*
let entrypte = encryptPasscode(passcode: "123123", encrypt: true)
print (entrypte)

let decry = encryptPasscode(passcode: entrypte, encrypt: false)
print (decry)

private func encryptPasscode(passcode: String, encrypt: Bool) -> String {
    let encryptedNumbers: [Int: String] = [0:"5", 1:"#", 2:"@", 3:"(",4:"B",5:"J",6:"+",7:"!",8:"3",9:">"]
    let passcodeArray = Array(passcode)
    var split1 = ""
    var split2 = ""
    var newPasscode = ""
    
    if encrypt {
        var encryptedPass = [String]()
        for num in passcodeArray {
            let numToInt = num.wholeNumberValue
            encryptedPass.append(encryptedNumbers[numToInt!]!)
        }
              
        for (i, number) in encryptedPass.enumerated() {
            if i < 3 {
                split1 += String(number)
            } else {
                split2 += String(number)
            }
        }
        newPasscode = "\(split2)\(split1)"
    } else {
        var found = ""
        for char in passcodeArray {
            for dic in encryptedNumbers {
                if dic.value == String(char) {
                    found.append(String(dic.key))
                }
            }
        }
        
        for (i, number) in found.enumerated() {
            if i < 3 {
                split1 += String(number)
            } else {
                split2 += String(number)
            }
        }
        newPasscode = "\(split2)\(split1)"
    }
    return newPasscode
}
*/




//func removeSpecialCharsFromString(text: String) -> String {
//    let okayChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890_")
//    return text.filter {okayChars.contains($0) }
//}
//
//print (removeSpecialCharsFromString(text: oldMessage))



///Encryption

let oldMessage = "https://www.locknkey.app"
let pass = "80348470"
let chatid = "2021-10-07 21:31:53-0700"

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
let date = dateFormatter.date(from:chatid)!
print (date)

let formater = DateFormatter()
formater.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
let dateString = formater.string(from: date)
print (dateString)

//let decrp = encryptDecrypt(oldMessage: encryptedMessage, encryptedPassword: pass, messageID: chatid, encrypt: false)

let encry = encryptDecrypt(oldMessage: oldMessage, encryptedPassword: pass, messageID: chatid, encrypt: true)

func encryptDecrypt(oldMessage: String, encryptedPassword: String, messageID: String, encrypt: Bool) -> String {
    
    let oldMessageArray = oldMessage.unicodeScalars.map { $0.value }
    var newMessage = ""
    var idCount = 0
    
    let idsEncrypted = generateIDs(chatID: messageID)
    let password = encryptPassword(password: encryptedPassword)
    let lenghtMessageID = 10 //generateLengthID(lenghtMessage: 10)
    print (lenghtMessageID)
    
    for char in oldMessageArray {
        var id = 0
        
        if idCount < idsEncrypted.count - 1 {
            id = Int(idsEncrypted[idCount])
            idCount += 1
        } else {
            id = Int(idsEncrypted[idCount])
            idCount = 0
        }
        if encrypt == true {
            let encryptChar = Int(char) + idCount + id + password + lenghtMessageID
            let encryptCharToUnicode = UnicodeScalar(encryptChar)
            let character = Character(encryptCharToUnicode!)
            newMessage = newMessage + String(character)
        } else {
            let encryptChar = Int(char) - idCount - id - password - lenghtMessageID
            let encryptCharToUnicode = UnicodeScalar(encryptChar)
            let character = Character(encryptCharToUnicode!)
            newMessage = newMessage + String(character)
        }
    }
    print (newMessage)
    return newMessage
}

private func generateLengthID(lenghtMessage: Int) -> Int {
    
    var sumOfEachNumber = 0
    let numToString = String(lenghtMessage)
  
    for num in numToString {
        sumOfEachNumber += Int(String(num))!
    }
    
    return sumOfEachNumber
}

private func generateIDs(chatID: String) -> [Int] {
    let lengthString = chatID.count - 7
    
    var chatIDConverted = [UInt8]()
    for (i, character) in chatID.enumerated()  {
        if i == lengthString {
            break
        }
        let valueASCII = character.asciiValue
        chatIDConverted.append(valueASCII!)
    }
    
    var chatIDInverted = chatIDConverted
    chatIDInverted.reverse()
    
   // let chatIDConverted = chatID.unicodeScalars.map { $0.value }

    var idPhoneEncrypted = [Int]()
    for i in 0...lengthString - 1 {
        let sum = chatIDConverted[i] + chatIDInverted[i]
        
        idPhoneEncrypted.append(Int(sum))
    }
    
    return idPhoneEncrypted
}

private func encryptPassword(password: String) -> Int{
    var passwordEncrypted = 0
    
    for char in password {
        passwordEncrypted +=  Int(String(char))!
    }
    return passwordEncrypted
}

let decry = encryptDecrypt(oldMessage: encry, encryptedPassword: pass, messageID: chatid, encrypt: false)

print (encry)
print (decry)



//extension String {
//    var isValidURL: Bool {
//        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
//            // it is a link, if the match covers the whole string
//            return match.range.length == self.utf16.count
//        } else {
//            return false
//        }
//    }
//}
//
////let directionURL = "https://apple.news/ASs78wFm5S820_oYuAYHnzg"
//let directionURL = "htt://google.com/"
//
//print (directionURL.isValidURL)
//
//fetchPreview(something: directionURL)
//
//func fetchPreview(something: String){
//    guard let url = URL(string: something) else {
//        return
//    }
//
//    let linkPreview = LPLinkView()
//    let provider = LPMetadataProvider()
//    provider.startFetchingMetadata(for: url) { metaData, error in
//        guard let data = metaData, error == nil else {
//            return
//        }
//
//        linkPreview.metadata = data
//        print (linkPreview.metadata)
//    }
//}
