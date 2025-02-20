//
//  PushNotificationSender.swift
//  CryptoChat
//
//  Created by Javier Gomez on 8/18/21.
//

import UIKit
import FirebaseAuth
import UserNotifications
import SwiftJWT


struct GoogleJWTClaims: Claims {
    let iss: String  // Client Email from the service account
    let scope: String  // OAuth scope
    let aud: String  // Google's token endpoint
    let exp: Date  // Expiry time (1 hour max)
    let iat: Date  // Issued at time
}

class PushNotificationSender {
    
    var userID = ""
    
    func sendPushNotification(to token: String, title: String, body: String, typeNotification: String, chatFriend: Chat?) {
        
        let urlString = "https://fcm.googleapis.com/v1/projects/lnk-chats/messages:send"
        let url = NSURL(string: urlString)!
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        self.userID = userID
        
        let allowNotification = UserDefaults.standard.value(forKey: "allow_notification") as? Bool
        if allowNotification == nil {
            
            verifyIfAllowNotification()
            
        }
        
        var chat = chatFriend
        if chat == nil {
            chat = Chat(chatID: "", username: "", latestMessage: "", date: "", isRead: false, imageURL: "", userID: "", isContact: true, messageID: "")
        }
        
        let isFriendString = String(chat!.isContact)
        let isReadString = String(chat!.isRead)
        let paramString: [String: Any] = [
            "message": [
                "token": token,
                "notification": [
                    "title": title,
                    "body": body,
                ],
                "data": [
                    "type_notification": typeNotification,
                    "chat_id": chat!.chatID,
                    "username": chat!.username,
                    "image_url": chat!.imageURL,
                    "is_friend": isFriendString,
                    "message_id": chat!.messageID,
                    "friend_id": userID,
                    "is_read": isReadString
                ],
                "apns": [
                    "payload": [
                        "aps": [
                            "sound": "default",
                            "badge": 1
                        ]
                    ]
                ]
            ]
        ]
        
        
        getFirebaseAccessToken { accessToken in
            if let token = accessToken {
                print("Bearer Token: \(token)")
                
                let request = NSMutableURLRequest(url: url as URL)
                request.httpMethod = "POST"
                request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue( "Bearer \(token)", forHTTPHeaderField: "Authorization")
                let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
                    do {
                        if let jsonData = data {
                            
                            if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] {
                                NSLog("Received data:\n\(jsonDataDict))")
                            }
                        }
                    } catch let err as NSError {
                        print(err.debugDescription)
                    }
                }
                task.resume()
                
            } else {
                print("Failed to obtain access token.")
            }
        }
    }
    
    func createJWT(clientEmail: String, privateKey: String, scope: String) -> String? {
        let currentTime = Date()
        let expirationTime = currentTime.addingTimeInterval(3600)  // Token valid for 1 hour
        
        let claims = GoogleJWTClaims(
            iss: clientEmail,
            scope: scope,
            aud: "https://oauth2.googleapis.com/token",
            exp: expirationTime,
            iat: currentTime
        )
        
        var jwt = JWT(claims: claims)
        
        do {
            let jwtSigner = JWTSigner.rs256(privateKey: privateKey.data(using: .utf8)!)
            let signedJWT = try jwt.sign(using: jwtSigner)
            return signedJWT
        } catch {
            print("Error signing JWT: \(error)")
            return nil
        }
    }
    
    
    func getFirebaseAccessToken(completion: @escaping (String?) -> Void) {
        guard let filePath = Bundle.main.path(forResource: "lnk-chats-edc6767c8fec", ofType: "json") else {
            print("Service account JSON file not found")
            completion(nil)
            return
        }
        
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let clientEmail = json?["client_email"] as? String,
                  let privateKey = json?["private_key"] as? String else {
                print("Invalid service account JSON")
                completion(nil)
                return
            }
            
            let scope = "https://www.googleapis.com/auth/cloud-platform"
            guard let jwt = createJWT(clientEmail: clientEmail, privateKey: privateKey, scope: scope) else {
                print("Failed to generate JWT")
                completion(nil)
                return
            }
            
            let tokenURL = "https://oauth2.googleapis.com/token"
            var request = URLRequest(url: URL(string: tokenURL)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            let bodyString = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
            request.httpBody = bodyString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching token: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = jsonResponse["access_token"] as? String {
                    completion(accessToken)
                } else {
                    print("Failed to parse access token")
                    completion(nil)
                }
            }
            task.resume()
            
        } catch {
            print("Error loading service account JSON: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    private func verifyIfAllowNotification(){
        
        let alert = UIAlertController(title: "Allow Notifications", message: "Do you want us to let you know when your friends reply back?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Let me know!", style: .default, handler: { _ in
            let requestAuthorization = PushNotificationManager(userID: self.userID)
            requestAuthorization.registerForPushNotifications()
            
            UserDefaults.standard.setValue(true, forKey: "allow_notification")
        }))
        
        alert.addAction(UIAlertAction(title: "No!", style: .cancel, handler: { _ in
            UserDefaults.standard.setValue(false, forKey: "allow_notification")
        }))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            var vc = keyWindow.rootViewController?.presentedViewController
            
            if let tabBarController = vc as? UITabBarController {
                vc = tabBarController.selectedViewController
            }
            vc?.present(alert, animated: true, completion: nil)
        }
    }
}
