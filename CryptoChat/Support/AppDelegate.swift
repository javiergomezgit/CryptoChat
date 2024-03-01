//
//  AppDelegate.swift
//  CryptoChat
//
//  Created by Javier Gomez on 6/30/21.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseAnalytics
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var pushPermission: UNAuthorizationStatus?
            
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
    
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        if let userID = FirebaseAuth.Auth.auth().currentUser?.uid {
            let dateString = ChatViewController.dateFormatter.string(from: Date())
            let database = Database.database().reference()
            database.child("users/\(userID)").child("online_date").setValue(dateString)
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            database.child("users/\(userID)").child("version_app").setValue(appVersion)
            
            let pushManager = PushNotificationManager(userID: userID)
            pushManager.updateFirestorePushTokenIfNeeded()
        }
        
       
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            
            case .notDetermined:
                print ("not determined")
            case .denied:
                UserDefaults.standard.setValue(false, forKey: "allow_notification")
            case .authorized:
                UserDefaults.standard.setValue(true, forKey: "allow_notification")
            case .provisional:
                print ("provisional")
            case .ephemeral:
                print ("ephemeral")
            @unknown default:
                print ("unknown default")
            }
        }
        return true
    }

    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) { //execute when app is open
        print (userInfo)
        let user = userInfo["friend_id"]
        print (user as Any)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        activeAppNotification(notification)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //enters if app is out and off
        backgroundNotification(response.notification)
        completionHandler()
    }
    
    private func activeAppNotification(_ notification: UNNotification){
        let userInfo = notification.request.content.userInfo
        let typeNotification = userInfo["type_notification"] as? String

        UIApplication.shared.applicationIconBadgeNumber = 0
        
        switch typeNotification {
        case "requestNotification" :
            NotificationCenter.default.post(name: Notification.Name("friendsTableChanged"), object: nil)
            guard let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
            
            if let vc = window.presentedViewController as? UITabBarController {
                print ("TabBar selected: \(vc.selectedIndex)")
                if let tabItems = vc.tabBar.items {
                    let tabItem = tabItems[0]
                    tabItem.badgeValue = "?"
                }
            }
        case "acceptNotification":
            NotificationCenter.default.post(name: Notification.Name("friendsTableChanged"), object: nil)
            guard let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
            
            if let vc = window.presentedViewController as? UITabBarController {
                print ("TabBar selected: \(vc.selectedIndex)")
                if let tabItems = vc.tabBar.items {
                    let tabItem = tabItems[0]
                    tabItem.badgeValue = "✓"
                    tabItem.badgeColor = .systemBlue
                }
            }
        case  "messageNotification":
            NotificationCenter.default.post(name: Notification.Name("new_message"), object: nil)
        default:
            print ("other notification")
        }
    }
    
    private func backgroundNotification(_ notification: UNNotification) {

        let userInfo = notification.request.content.userInfo
        let typeNotification = userInfo["type_notification"] as? String
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        switch typeNotification {
        case "requestNotification" :
            NotificationCenter.default.post(name: Notification.Name("friendsTableChanged"), object: nil)
            guard let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
            
            if let vc = window.presentedViewController as? UITabBarController {
                print ("TabBar selected: \(vc.selectedIndex)")
                if let tabItems = vc.tabBar.items {
                    let tabItem = tabItems[0]
                    tabItem.badgeValue = "?"
                }
                vc.selectedIndex = 0
            }
        case "acceptNotification":
            NotificationCenter.default.post(name: Notification.Name("friendsTableChanged"), object: nil)
            guard let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
            
            if let vc = window.presentedViewController as? UITabBarController {
                print ("TabBar selected: \(vc.selectedIndex)")
                if let tabItems = vc.tabBar.items {
                    let tabItem = tabItems[0]
                    tabItem.badgeValue = "✓"
                    tabItem.badgeColor = .systemBlue
                }
                vc.selectedIndex = 1
            }
        case  "messageNotification":
            guard let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
            
            if let vc = window.presentedViewController as? UITabBarController {
                print ("TabBar selected: \(vc.selectedIndex)")
                if let tabItems = vc.tabBar.items {
                    let tabItem = tabItems[1]
                    tabItem.badgeValue = " "
                    tabItem.badgeColor = .systemRed.withAlphaComponent(0.7)
                }
                vc.selectedIndex = 1
            }
            NotificationCenter.default.post(name: Notification.Name("new_message"), object: nil)
        default:
            print ("something else")
        }
    }
    
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let tokenDict = ["token": fcmToken ?? ""]
        
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: tokenDict)
    }
}
