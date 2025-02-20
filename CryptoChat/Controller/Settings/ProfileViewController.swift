//
//  ProfileViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/1/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
//import SDWebImage
import Nuke
import NukeExtensions
import Firebase
import FirebaseStorage
//import SmileLock
import SafariServices
import YPImagePicker
import CoreMIDI

struct Section {
    let title: String
    let options: [SettingsOptionsType]
}

enum SettingsOptionsType {
    case staticCell(model: SettingsOptions)
    case switchCell(model: SettingsSwitchOptions)
}

struct SettingsOptions {
    let titleSetting: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let handler: (() -> Void)
}

struct SettingsSwitchOptions {
    let titleSetting: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    var isOn: Bool
    let handler: (() -> Void)
}

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    
    var userID = ""
    var username = ""
    var phoneNumber = ""
    var profileImageURL: URL?
    var isPrivate = false
    private let spinner = JGProgressHUD(style: .dark)
    var allowNotification = false
    var models = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        models.append(
            Section(title: "Account", options: [
                .staticCell(model: SettingsOptions(titleSetting: "Change Username", icon: UIImage(systemName: "person.crop.circle.badge.exclamationmark"), iconBackgroundColor: .systemOrange, handler: {
                    let vc = SettingsViewController(selectedSetting: 0)
                    vc.navigationItem.largeTitleDisplayMode = .always
                    self.navigationController!.pushViewController(vc, animated: true)
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Phone Number", icon: UIImage(systemName: "phone.fill"), iconBackgroundColor: .systemBlue, handler: {
                    let vc = SettingsViewController(selectedSetting: 1)
                    vc.navigationItem.largeTitleDisplayMode = .always
                    self.navigationController!.pushViewController(vc, animated: true)
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Blocked Users", icon: UIImage(systemName: "nosign"), iconBackgroundColor: .orange, handler: {
                    let vc = self.storyboard?.instantiateViewController(identifier: "BlockedViewController") as! BlockedViewController
                    vc.title = "Blocked Users"
                    vc.modalPresentationStyle = .formSheet
                    self.present(vc, animated: true, completion: nil)
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Delete Account", icon: UIImage(systemName: "xmark.square"), iconBackgroundColor: .red, handler: {
                    self.deleteAccount()
                }))
            ]
            )
        )
        
        models.append(
            Section(title: "Security & Privacy", options: [
                .staticCell(model: SettingsOptions(titleSetting: "General Passcode", icon: UIImage(systemName: "lock"), iconBackgroundColor: .systemBlue, handler: {
                    let vc = self.storyboard?.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
                    vc.statusOfPasscode = .changePasscode
                    vc.completion = { success in
                        if success {
                            print ("success")
                        }
                    }
                    vc.modalPresentationStyle = .formSheet
                    self.present(vc, animated: true, completion: nil)
                })),
                //                .staticCell(model:  SettingsOptions(titleSetting: "Private", icon: UIImage(named: "doc.text.magnifyingglass"), iconBackgroundColor: .systemOrange, handler: {
                //                    print ("chose username")
                //                    self.changeToPrivate(isOn: self.isPrivate)
                //                })),
                    .switchCell(model: SettingsSwitchOptions(titleSetting: "Private", icon: UIImage(named: "doc.text.magnifyingglass"), iconBackgroundColor: .systemOrange, isOn: isPrivate, handler: {
                        print ("chose username")
                        self.changeToPrivate()
                    })),
                .staticCell(model:  SettingsOptions(titleSetting: "Auto Lock", icon: UIImage(systemName: "lock.rotation"), iconBackgroundColor: .red, handler: {
                    let vc = self.storyboard?.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
                    vc.statusOfPasscode = .verifyPasscode
                    vc.completion = { success in
                        if success {
                            let vc = self.storyboard?.instantiateViewController(identifier: "AutoLockController") as! AutoLockController
                            vc.title = "Auto Lock"
                            self.navigationController!.pushViewController(vc, animated: true)
                        }
                    }
                    vc.modalPresentationStyle = .formSheet
                    self.present(vc, animated: true, completion: nil)
                }))
            ]
            )
        )
        
        models.append(
            Section(title: "Settings", options: [
                .staticCell(model: SettingsOptions(titleSetting: "Allow Notifications", icon: UIImage(systemName: "bell"), iconBackgroundColor: .lightGray, handler: {
                    self.changeToAllowNotifications(isOn: self.allowNotification)
                    print ("chose allow notifications")
                })),
                //                .switchCell(model: SettingsSwitchOptions(titleSetting: "Allow Notifications", icon: UIImage(systemName: "bell"), iconBackgroundColor: .lightGray,  isOn: self.allowNotification, handler: {
                //                    self.changeToAllowNotifications(isOn: self.allowNotification)
                //                    print ("chose allow notifications")
                //                })),
                    .staticCell(model: SettingsOptions(titleSetting: "Color Theme", icon: UIImage(named: "paintbrush"), iconBackgroundColor: .systemBlue, handler: {
                        let vc = SettingsViewController(selectedSetting: 2)
                        vc.navigationItem.largeTitleDisplayMode = .always
                        self.navigationController!.pushViewController(vc, animated: true)
                    }))
            ]
            )
        )
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        models.append(
            Section(title: "Others", options: [
                .staticCell(model: SettingsOptions(titleSetting: "Contact us", icon: UIImage(systemName: "envelope.open"), iconBackgroundColor: .systemBlue, handler: {
                    if let url = URL(string: "https://www.locknkey.app/contact/") {
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    }
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "Buy me a coffee", icon: UIImage(named: "bitcoinsign.circle"), iconBackgroundColor: .brown, handler: {
                    if let url = URL(string: "https://www.locknkey.app/buy-me-a-coffee/") {
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    }
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "Privacy Policy", icon: UIImage(systemName: "doc.plaintext"), iconBackgroundColor: .lightGray, handler: {
                    if let url = URL(string: "https://www.locknkey.app/privacy-policy/") {
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    }
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "v \(appVersion!)", icon: UIImage(systemName: "list.number"), iconBackgroundColor: .lightGray, handler: {
                    print ("chose version")
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Logout", icon: UIImage(systemName: "hand.raised"), iconBackgroundColor: .darkGray, handler: {
                    self.logout()
                }))
            ]
            )
        )
        
        spinner.show(in: view)
        
        guard let id = Auth.auth().currentUser?.uid else {
            return
        }
        self.userID = id
        
        loadExtraFunctions()
        
    }
    
    private func loadExtraFunctions() {
        tableView.delegate = self
        tableView.dataSource = self
        self.hideKeyboardWhenTappedAround()
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(showPicker))
        imageProfile.addGestureRecognizer(gesture)
        
        loadInfo()
    }
    
    @objc func showPicker() {
        
        var config = YPImagePickerConfiguration()
        
        /* Set this to true if you want to force the  library output to be a squared image. Defaults to false */
        config.library.onlySquare = true
        
        /* Set this to true if you want to force the camera output to be a squared image. Defaults to true */
        config.onlySquareImagesFromCamera = true
        config.showsPhotoFilters = false
        
        /* Ex: cappedTo:1024 will make sure images from the library or the camera will be
         resized to fit in a 1024x1024 box. Defaults to original image size. */
        config.targetImageSize = .cappedTo(size: 1024)
        
        config.library.mediaType = .photo
        config.usesFrontCamera = true
        config.shouldSaveNewPicturesToAlbum = false
        config.startOnScreen = .library
        config.screens = [.photo, .library]
        /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
        config.showsCrop = .rectangle(ratio: (1/1))
        config.wordings.libraryTitle = "Gallery"
        config.wordings.cameraTitle = "Camera"
        config.hidesStatusBar = false
        config.hidesBottomBar = false
        config.isScrollToChangeModesEnabled = true
        config.library.maxNumberOfItems = 1
        config.library.defaultMultipleSelection = false
        config.library.skipSelectionsGallery = false
        
        let picker = YPImagePicker(configuration: config)
        
        picker.navigationBar.tintColor = .label
        picker.navigationBar.backgroundColor = .systemBackground
        picker.isNavigationBarHidden = false
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            
            if cancelled {
                picker.dismiss(animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
                return
            }
            
            if let photo = items.singlePhoto {
                //                print(photo.fromCamera) // Image source (camera or library)
                //                print(photo.image) // Final image selected by the user
                //                print(photo.originalImage) // original image selected by the user, unfiltered
                //                print(photo.modifiedImage) // Transformed image, can be nil
                //                print(photo.exifMeta) // Print exif meta data of original image.
                
                self.spinner.show(in: self.view)
                self.updateImageProfile(image: photo.image)
                
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
                
            }
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()
        
        loadInfo()
    }
    private func loadInfo(){
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        self.username = username
        
        guard let phone = UserDefaults.standard.value(forKey: "phoneNumber") as? String else {
            return
        }
        self.phoneNumber = phone
        
        guard let isPrivate = UserDefaults.standard.value(forKey: "isPrivate") as? Bool else {
            return
        }
        self.isPrivate = isPrivate
        //switchView.setOn(isPrivate, animated: true)

        let allowNotificationStored = UserDefaults.standard.value(forKey: "allow_notification") as? Bool
        if allowNotificationStored != nil && allowNotificationStored == false {
            self.allowNotification = false
        } else {
            self.allowNotification = true
        }
        
        
        if username.isNumber {
            usernameLabel.text = ""
        } else {
            usernameLabel.text = username.uppercased()
        }
        phoneNumberLabel.text = phone
        
        DispatchQueue.main.async {
            self.createProfileImage()
            self.spinner.dismiss()
        }
        
        self.tableView.reloadData()
    }
    
    func createProfileImage() {
        let filename = "profile_images/\(userID)_profile.png"
        print (filename)
        
        imageProfile.contentMode = .scaleAspectFill
        
        StorageDatabaseController.shared.downloadURL(for: filename) { [weak self] result in
            switch result {
            case .success(let url):
                //self?.downloadImage(url: url)
                self!.profileImageURL = url
                
                DispatchQueue.main.async {
//                    self?.imageProfile.sd_setImage(with: url, completed: nil)
                    NukeExtensions.loadImage(with: url, into: self!.imageProfile)
                }
            case .failure(let error):
                print ("fail  \(error)")
            }
        }
    }
    
    @objc private func logout(){
        let alert = UIAlertController(title: "Loging Out", message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            
            do {
                try Auth.auth().signOut()
                //For erasing all the userdefaults
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
                
                UserDefaults.standard.set(false, forKey: "firstLaunchingLaunch")
                UserDefaults.standard.synchronize()
                
                let database = Database.database().reference()
                database.child("users_table").child(self.userID).removeValue()
                UIApplication.shared.applicationIconBadgeNumber = 0
                
                self.tabBarController?.tabBar.isHidden = true
                self.navigationController?.navigationBar.isHidden = true
                
                self.show(GoTo.controller(nameController: "StarterViewController", nameStoryboard: "Main"), sender: self)
                
                
            } catch {
                self.present(ShowAlert.alert(type: .wrongCredentials, error: "Something went wrong, try again later"), animated: true)
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func deleteAccount() {
        let alert = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            
            let vc = self.storyboard?.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
            vc.statusOfPasscode = .verifyPasscode
            
            vc.completion = { success in
                if success {
                    
                    
                    let storage = Storage.storage()
                    let url = self.profileImageURL?.absoluteString
                    let storageRef = storage.reference(forURL: url!)
                    
                    //Removes image from storage
                    storageRef.delete { error in
                        if let error = error {
                            print(error)
                        } else {
                            Auth.auth().currentUser?.delete(completion: { error in
                                if error != nil {
                                    UserDefaults.standard.removeObject(forKey: "username")
                                    UserDefaults.standard.removeObject(forKey: "phoneNumber")
                                    UserDefaults.standard.removeObject(forKey: "isPrivate")
                                    UserDefaults.standard.removeObject(forKey: "profilePhotoURL")
                                    UserDefaults.standard.removeObject(forKey: "allow_notification")
                                    UserDefaults.standard.removeObject(forKey: "general_passcode")
                                    UserDefaults.standard.removeObject(forKey: "unlocked")
                                    UserDefaults.standard.synchronize()
                                    
                                    let database = Database.database().reference()
                                    database.child("users/\(self.userID)").removeValue()
                                    database.child("usernames/\(self.userID)").removeValue()
                                    database.child("users_table").child(self.userID).removeValue()
                                    
                                    UIApplication.shared.applicationIconBadgeNumber = 0
                                    
                                    self.tabBarController?.tabBar.isHidden = true
                                    self.navigationController?.navigationBar.isHidden = true
                                    
                                    self.show(GoTo.controller(nameController: "StarterViewController", nameStoryboard: "Main"), sender: self)
                                } else {
                                    print ("error loging out")
                                    self.present(ShowAlert.alert(type: .wrongCredentials, error: "Something went wrong, try again later"), animated: true)
                                }
                            })
                        }
                    }
                }
            }
            
            vc.modalPresentationStyle = .formSheet
            self.present(vc, animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        showPicker()
    }
    
    private func updateImageProfile(image: UIImage){
        
        guard  let data = image.pngData() else {
            return
        }
        let fileName = "\(userID)_profile.png"
        
        StorageDatabaseController.shared.uploadProfilePhoto(with: data, fileName: fileName) { result in
            switch result {
            case .success (let downloadURL) :
                print (downloadURL)
                self.spinner.dismiss()
//                self.imageProfile.sd_setImage(with: URL(string: downloadURL), completed: nil)
//                NukeExtensions.loadImage(with: downloadURL, into: self.imageProfile)
                self.imageProfile.image = image
                
            case .failure(let error) :
                self.present(ShowAlert.alert(type: nil, error: "Error saving your profile image"), animated: true)
                print ("storage error \(error)")
            }
        }
    }
}


extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        models.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section].options[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileViewCell", for: indexPath) as! ProfileViewCell
        
        switch model.self {
        case .staticCell(let modelCell) :
            cell.configure(with: modelCell)
            
            if indexPath.section == 0 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
                cell.accessoryView = nil
            }
            return cell
        case .switchCell(model: let modelCell) :
            cell.configureSwitch(with: modelCell)
            if indexPath.section == 1 && modelCell.titleSetting == "Private" {
                let switchView = UISwitch(frame: .zero)
                switchView.setOn(self.isPrivate, animated: true)
                switchView.tag = indexPath.row // for detect which row switch Changed
                switchView.addTarget(self, action: #selector(self.changeToPrivate), for: .valueChanged)
                cell.accessoryView = switchView
            }
            if indexPath.section == 2 && modelCell.titleSetting == "Allow Notifications" {
                let switchView = UISwitch(frame: .zero)
                switchView.setOn(self.allowNotification, animated: true)
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.changeToAllowNotifications), for: .valueChanged)
                cell.accessoryView = switchView
            }
            return cell
        }
    }
    

    
    @objc private func changeToAllowNotifications(isOn: Bool){
        
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings { settings in
            print (settings.authorizationStatus)
            if settings.authorizationStatus == .notDetermined {
                let requestAuthorization = PushNotificationManager(userID: self.userID)
                requestAuthorization.registerForPushNotifications()
                self.allowNotification = false
                
            } else if  settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Change Settings", message: "To change your notifications you have to go to settings", preferredStyle: .alert)
                    self.allowNotification = true
//                    UIApplication.shared.registerForRemoteNotifications() //Change to this instead of taking user to the system settings
                    alert.addAction(UIAlertAction(title: "Take me", style: .default, handler: { _ in
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
                    self.present(alert, animated: true)
                }
            } else if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Change Settings", message: "To change your notifications you have to go to settings", preferredStyle: .alert)
                    self.allowNotification = false
                    alert.addAction(UIAlertAction(title: "Take me", style: .default, handler: { _ in
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc func changeToPrivate(){
        
        var isPrivateTemp = false
        if self.isPrivate {
            isPrivateTemp = false
        } else {
            isPrivateTemp = true
        }
        
        UserDatabaseController.shared.changePrivacy(userID: userID, privacy: isPrivateTemp) { error in
            if error != nil {
                self.isPrivate = false
                self.present(ShowAlert.alert(type: .simpleError, error: "We couldn't change your privacy, try again later"), animated: true)
                UserDefaults.standard.set(false, forKey: "isPrivate")
                print ("COULDN't change in database")
            } else {
                self.isPrivate = isPrivateTemp
                UserDefaults.standard.set(self.isPrivate, forKey: "isPrivate")
//                UserDefaults.standard.synchronize()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.label.withAlphaComponent(0.7)
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        header.textLabel?.frame = header.bounds
        header.textLabel?.textAlignment = .center
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].options[indexPath.row]
        
        switch type.self {
        case .staticCell(let model) :
            model.handler()
        case .switchCell(_) :
            print ("switch")
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print ("tapped")
        print (indexPath.row)
    }
    
}
