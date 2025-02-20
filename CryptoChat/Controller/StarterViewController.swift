//
//  StarterViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 11/11/24.
//

import UIKit
import FirebaseAuth
import Lottie

class StarterViewController: UIViewController {
    
    @IBOutlet weak var viewAnimation: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoLabel: UILabel!
    
    let animationView = LottieAnimationView(name: "animation-lock")

    override func viewWillAppear(_ animated: Bool) {
        
        createAnimationLogo()
    }
    
    func isFirstLaunched() -> Bool {
        let isFirstLaunched = UserDefaults.standard.value(forKey: "firstLaunchingLaunch")
        if isFirstLaunched == nil {
            //Means it's new - Never LAUNCHED
            UserDefaults.standard.set(false, forKey: "firstLaunchingLaunch")
            UserDefaults.standard.synchronize()
            return true
        } else {
            return false
        }
    }
    
    enum ProgressKeyFrames: CGFloat {

      case start = 5
      case end = 60
      case complete = 75
      
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Starter"
             
    }
    
    private func createAnimationLogo() {
        // Load animation to AnimationView
        animationView.frame = viewAnimation.bounds//CGRect(x: 0, y: 0, width: 200, height: 200)
        animationView.contentMode = .scaleAspectFit

        // Add animationView as subview
        viewAnimation.addSubview(animationView)

        // Play the animation
        animationView.play()
        
        animationView.animationSpeed = 1.5
        animationView.loopMode = .loop
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            if isFirstLaunched() {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingViewController
                
                nextViewController.modalPresentationStyle = .fullScreen
                nextViewController.modalTransitionStyle = .crossDissolve
                self.present(nextViewController, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { timer in
                        self.signedUser()
                    })
                }
            }
        } else {
            print("Internet Connection not Available!")
            
            let refreshAlert = UIAlertController(title: "Internet connection", message: "You will need internet for using this app", preferredStyle: UIAlertController.Style.alert)

            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                exit(0);
            }))
            present(refreshAlert, animated: true, completion: nil)
        }
    }
    
    //ChEck what information user has if nothing then request for info
    private func signedUser() {
        //Do condition if user is NOT logged in
        if Auth.auth().currentUser?.uid != nil {
            UserDatabaseController.shared.getInitialInfo(userID: Auth.auth().currentUser!.uid) { userLocalInformation in
                if userLocalInformation != nil {
                    UserDefaults.standard.setValue(userLocalInformation?.username, forKey: "username")
                    UserDefaults.standard.setValue(userLocalInformation?.phoneNumber, forKey: "phoneNumber")
                    UserDefaults.standard.setValue(userLocalInformation?.isPrivate, forKey: "isPrivate")
                    UserDefaults.standard.setValue(userLocalInformation?.profilePhotoURL, forKey: "profilePhotoURL")
                    UserDefaults.standard.setValue(userLocalInformation?.generalPasscode, forKey: "general_passcode")
                    
                    let pushManager = PushNotificationManager(userID: Auth.auth().currentUser!.uid)
                    pushManager.updateFirestorePushTokenIfNeeded()
                    
                    self.animationView.stop()
                    self.show(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), sender: nil)
                } else {
                    do {
                        try Auth.auth().signOut()
                        
                        UserDefaults.standard.removeObject(forKey: "username")
                        UserDefaults.standard.removeObject(forKey: "phoneNumber")
                        UserDefaults.standard.removeObject(forKey: "isPrivate")
                        UserDefaults.standard.removeObject(forKey: "profilePhotoURL")
                        UserDefaults.standard.removeObject(forKey: "general_passcode")
                        UserDefaults.standard.synchronize()
                        
                        self.animationView.stop()
                        self.show(GoTo.controller(nameController: "SigninViewController", nameStoryboard: "Main"), sender: self)
                        
                    } catch {
                        print ("error loging out")
                    }
                }
            }
        } else { //If user is logged IN then go directily to the main controller
            self.animationView.stop()
            self.show(GoTo.controller(nameController: "SigninViewController", nameStoryboard: "Main"), sender: self)
        }
    }
    
}

extension StarterViewController {
    
    public static func createLocalUrl(forImageNamed name: String) -> URL? {
        
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name)")
        
        guard fileManager.fileExists(atPath: url.path) else {
            guard
                let image = UIImage(named: name),
                let data = image.pngData()
            else { return nil }
            
            fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
            return url
        }
        
        return url
    }
    
}




