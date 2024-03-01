//
//  PushNotificationSender.swift
//  CryptoChat
//
//  Created by Javier Gomez on 8/18/21.
//

import UIKit
import FirebaseAuth

class PushNotificationSender {
    
    var userID = ""
    
    func sendPushNotification(to token: String, title: String, body: String, typeNotification: String, chatFriend: Chat?) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
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
            chat = Chat(chatID: "", username: "", latestMessage: "", date: "", isRead: false, imageURL: "", userID: "", isFriend: true, messageID: "")
        }
        
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "badge" : 1, "sound": "default"],
                                           "data" : [
                                            "type_notification" : typeNotification,
                                            "chat_id" : chat!.chatID,
                                            "username" : chat!.username, //friends username should send
                                            "image_url" : chat!.imageURL, //friends url
                                            "is_friend" : chat!.isFriend,
                                            "message_id" : chat!.messageID,
                                            "friend_id" : userID,
                                            "is_read" : chat!.isRead
                                           ]
        ]
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAA1iYny2I:APA91bGhFXS99PB0Rz_QiXtgYf7dE7wbpd04TyQWXtFK6uPG6XQWRlXxUwZULDC6JD82yr1vh83c42z2KbpuH1omw8C6dpu7oPpFh0oFCj0FCI7t-2Eqb3TkEe1-RuvL1R4o8frGiC3g", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
    private func verifyIfAllowNotification(){
        
        let alert = UIAlertController(title: "Allow Notifications".localized(), message: "Do you want us to let you know when your friends reply back?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Let me know!".localized(), style: .default, handler: { _ in
            let requestAuthorization = PushNotificationManager(userID: self.userID)
            requestAuthorization.registerForPushNotifications()
            
            UserDefaults.standard.setValue(true, forKey: "allow_notification")
        }))
        
        alert.addAction(UIAlertAction(title: "No!", style: .cancel, handler: { _ in
            UserDefaults.standard.setValue(false, forKey: "allow_notification")
        }))
        
        var vc = UIApplication.shared.windows.first?.rootViewController?.presentedViewController
        if let tabBarController = vc as? UITabBarController {
            vc = tabBarController.selectedViewController
        }
        vc?.present(alert, animated: true, completion: nil)
    }
    
}
