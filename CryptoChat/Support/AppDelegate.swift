//
//  AppDelegate.swift
//  CryptoChat
//
//  Created by Javier Gomez on 11/10/24.
//

import UIKit
import CoreData
import Firebase
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
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
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                    UNUserNotificationCenter.current().delegate = self
                }
            } else {
                print("Notification permission denied")
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //execute when app is open
        print (userInfo)
        let user = userInfo["friend_id"]
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("this will return '32 bytes' in iOS 13+ rather than the token \(tokenString)")
        
        Messaging.messaging().apnsToken = deviceToken
        
//        Messaging.messaging().token { token, error in
//            if let error = error {
//                print("Error fetching FCM registration token: \(error)")
//            } else if let token = token {
//                print("FCM registration token: \(token)")
//                print (token.description)
//            }
//        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "CryptoChat")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Notification received when app is open
        activeAppNotification(notification)
        completionHandler([.list, .banner, .sound])
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //Enters if app is out or present -> execute when tapped notification
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
                    let tabItem = tabItems[0]
                    tabItem.badgeValue = "1"
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
