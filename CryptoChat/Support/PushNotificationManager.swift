//
//  PushNotificationManager.swift
//  CryptoChat
//
//  Created by Javier Gomez on 8/18/21.
//

import Firebase
import FirebaseFirestore
import FirebaseMessaging
import FirebaseDatabase
import UIKit
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    let userID: String
    init(userID: String) {
        self.userID = userID
        super.init()
    }

    func registerForPushNotifications() {
//        if #available(iOS 10.0, *) {
//            // For iOS 10 display notification (sent via APNS)
//            UNUserNotificationCenter.current().delegate = self
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })
//            // For iOS 10 data message (sent via FCM)te
//            Messaging.messaging().delegate = self
//        } else {
//            let settings: UIUserNotificationSettings =
//                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            UIApplication.shared.registerUserNotificationSettings(settings)
//        }
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { success, _ in
            guard success else {
                return
            }
            UserDefaults.standard.setValue(true, forKey: "allow_notification")
            UserDefaults.standard.synchronize()
            print("success APNS registration")
        }

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        updateFirestorePushTokenIfNeeded()
    }

    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken {

            let database = Database.database().reference()
            database.child("users_table").child(userID).setValue(["fcmToken": token])
            
            UserDefaults.standard.setValue(token, forKey: "fcmToken")
        
        }
    }


    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingDelegate) {
        print(remoteMessage )

    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFirestorePushTokenIfNeeded()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
    }
}
