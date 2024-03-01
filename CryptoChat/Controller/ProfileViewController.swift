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
import SmileLock
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

struct SettingsSwitchOptions {
    let titleSetting: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    var isOn: Bool
    let handler: (() -> Void)
}

struct SettingsOptions {
    let titleSetting: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
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
    
    var models = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        models.append(
            Section(title: "Account".localized(), options: [
                .staticCell(model: SettingsOptions(titleSetting: "Change Username".localized(), icon: UIImage(systemName: "person.crop.circle.badge.exclamationmark"), iconBackgroundColor: .systemOrange, handler: {
                    let vc = SettingsViewController(selectedSetting: 0)
                    vc.navigationItem.largeTitleDisplayMode = .always
                    self.navigationController!.pushViewController(vc, animated: true)
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Phone Number".localized(), icon: UIImage(systemName: "phone.fill"), iconBackgroundColor: .systemBlue, handler: {
                    let vc = SettingsViewController(selectedSetting: 1)
                    vc.navigationItem.largeTitleDisplayMode = .always
                    self.navigationController!.pushViewController(vc, animated: true)
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Blocked Users".localized(), icon: UIImage(systemName: "nosign"), iconBackgroundColor: .orange, handler: {
                    let vc = self.storyboard?.instantiateViewController(identifier: "BlockedViewController") as! BlockedViewController
                    vc.title = "Blocked Users".localized()
                    vc.modalPresentationStyle = .formSheet
                    self.present(vc, animated: true, completion: nil)
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Delete Account".localized(), icon: UIImage(systemName: "xmark.square"), iconBackgroundColor: .red, handler: {
                    self.deleteAccount()
                }))
            ]
                   )
        )
        
        models.append(
            Section(title: "Security & Privacy".localized(), options: [
                .staticCell(model: SettingsOptions(titleSetting: "General Passcode".localized(), icon: UIImage(systemName: "lock"), iconBackgroundColor: .systemBlue, handler: {
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
                .staticCell(model:  SettingsOptions(titleSetting: "Private".localized(), icon: UIImage(named: "doc.text.magnifyingglass"), iconBackgroundColor: .systemOrange, handler: {
                    print ("chose username")
                    self.changeToPrivate(isOn: self.isPrivate)
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "Auto Lock".localized(), icon: UIImage(systemName: "lock.rotation"), iconBackgroundColor: .red, handler: {
                    let vc = self.storyboard?.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
                    vc.statusOfPasscode = .verifyPasscode
                    vc.completion = { success in
                        if success {
                            let vc = self.storyboard?.instantiateViewController(identifier: "AutoLockController") as! AutoLockController
                            vc.title = "Auto Lock".localized()
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
            Section(title: "Settings".localized(), options: [
                .staticCell(model: SettingsOptions(titleSetting: "Allow Notifications".localized(), icon: UIImage(systemName: "bell"), iconBackgroundColor: .lightGray, handler: {
                    self.allowNotifications()
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Color Theme".localized(), icon: UIImage(named: "paintbrush"), iconBackgroundColor: .systemBlue, handler: {
                    let vc = SettingsViewController(selectedSetting: 2)
                    vc.navigationItem.largeTitleDisplayMode = .always
                    self.navigationController!.pushViewController(vc, animated: true)
                }))
            ]
                   )
        )
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        models.append(
            Section(title: "Others".localized(), options: [
                .staticCell(model: SettingsOptions(titleSetting: "Contact us".localized(), icon: UIImage(systemName: "envelope.open"), iconBackgroundColor: .systemBlue, handler: {
                    if let url = URL(string: "https://www.locknkey.app/contact/") {
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    }
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "Buy me a coffee".localized(), icon: UIImage(named: "bitcoinsign.circle"), iconBackgroundColor: .brown, handler: {
                    if let url = URL(string: "https://www.locknkey.app/buy-me-a-coffee/") {
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    }
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "Privacy Policy".localized(), icon: UIImage(systemName: "doc.plaintext"), iconBackgroundColor: .lightGray, handler: {
                    if let url = URL(string: "https://www.locknkey.app/privacy-policy/") {
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    }
                })),
                .staticCell(model:  SettingsOptions(titleSetting: "v \(appVersion!)", icon: UIImage(systemName: "list.number"), iconBackgroundColor: .lightGray, handler: {
                    print ("chose version")
                })),
                .staticCell(model: SettingsOptions(titleSetting: "Logout".localized(), icon: UIImage(systemName: "hand.raised"), iconBackgroundColor: .darkGray, handler: {
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
        config.wordings.libraryTitle = "Gallery".localized()
        config.wordings.cameraTitle = "Camera".localized()
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
        
//        loadInfo()
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
        
        StorageMng.shared.downloadURL(for: filename) { [weak self] result in
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
        let alert = UIAlertController(title: "Loging Out".localized(), message: "Are you sure you want to log out?".localized(), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout".localized(), style: .destructive, handler: { _ in
            
            do {
                try Auth.auth().signOut()
                //                UserDefaults.standard.removeObject(forKey: "username")
                //                UserDefaults.standard.removeObject(forKey: "phoneNumber")
                //                UserDefaults.standard.removeObject(forKey: "isPrivate")
                //                UserDefaults.standard.removeObject(forKey: "profilePhotoURL")
                //                UserDefaults.standard.removeObject(forKey: "allow_notification")
                //                UserDefaults.standard.removeObject(forKey: "general_passcode")
                //                UserDefaults.standard.removeObject(forKey: "unlocked")
                //                UserDefaults.standard.removeObject(forKey: "passcodeOn")
                //                UserDefaults.standard.removeObject(forKey: "unlockFaceID")
                //                UserDefaults.standard.removeObject(forKey: "autolockTime")
                //                UserDefaults.standard.synchronize()
                //For erasing all the userdefaults
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
                
                let database = Database.database().reference()
                database.child("users_table").child(self.userID).removeValue()
                UIApplication.shared.applicationIconBadgeNumber = 0
                
                self.tabBarController?.tabBar.isHidden = true
                self.navigationController?.navigationBar.isHidden = true
                
                self.show(GoTo.controller(nameController: "StarterViewController", nameStoryboard: "Main"), sender: self)
                
                
            } catch {
                self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Something went wrong, try again later"), animated: true)
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func deleteAccount() {
        let alert = UIAlertController(title: "Delete Account".localized(), message: "Are you sure you want to delete your account?".localized(), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: { _ in
            
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
                                    self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Something went wrong, try again later"), animated: true)
                                }
                            })
                        }
                    }
                }
            }
            
            vc.modalPresentationStyle = .formSheet
            self.present(vc, animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
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
        
        StorageMng.shared.uploadProfilePhoto(with: data, fileName: fileName) { result in
            switch result {
            case .success (let downloadURL) :
                print (downloadURL)
                self.spinner.dismiss()
//                self.imageProfile.sd_setImage(with: URL(string: downloadURL), completed: nil)
//                NukeExtensions.loadImage(with: downloadURL, into: self.imageProfile)
                self.imageProfile.image = image
                
            case .failure(let error) :
                self.present(ShowAlert.alertsCredentials(type: nil, error: "Error saving your profile image"), animated: true)
                print ("storage error \(error)")
            }
        }
    }
    
    private func allowNotifications(){
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                let requestAuthorization = PushNotificationManager(userID: self.userID)
                requestAuthorization.registerForPushNotifications()
            } else if  settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Change Settings".localized(), message: "To change your notifications you have to go to settings".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Take me".localized(), style: .default, handler: { _ in
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .destructive, handler: nil))
                    self.present(alert, animated: true)
                }
            } else if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Change Settings".localized(), message: "To change your notifications you have to go to settings".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Take me".localized(), style: .default, handler: { _ in
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .destructive, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
}


extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        models.count
    }
    //
    //    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    //        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60))
    //
    //        if traitCollection.userInterfaceStyle == .light {
    //            view.backgroundColor =  UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
    //        } else {
    //            view.backgroundColor =  UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1.0)
    //        }
    
    //        let lbl = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.width - 15, height: 40))
    //        lbl.font = UIFont.systemFont(ofSize: 18)
    //        lbl.text = data[section].settingName
    //        view.addSubview(lbl)
    //        return view
    //    }
    
    
    
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
            if indexPath.section == 1 && modelCell.titleSetting == "Private".localized() {
                let switchView = UISwitch(frame: .zero)
                switchView.setOn(false, animated: true)
                switchView.tag = indexPath.row // for detect which row switch Changed
                switchView.addTarget(self, action: #selector(self.changeToPrivate), for: .valueChanged)
                cell.accessoryView = switchView
            }
            return cell
        default:
            print ("some other cell type")
            return cell
        }
    }
    
    
    @objc func changeToPrivate(isOn: Bool){
//    @objc func changeToPrivate(isOn: Bool){
//        print("table row switch Changed \(sender.tag)")
//        print("The switch is \(sender.isOn ? "ON" : "OFF")")
        
        var isPrivate = false
        if isOn {
            print ("turning on the switch")
            isPrivate = true
        } else {
            isPrivate = false
        }
        
        DatabaseMng.shared.changePrivacy(userID: userID, privacy: isPrivate) { error in
            if error != nil {
                self.present(ShowAlert.alertsCredentials(type: .simpleError, error: "Update your phone number first. Friends will find you through your number"), animated: true)
                UserDefaults.standard.setValue(false, forKey: "isPrivate")
                self.isPrivate = false
                print ("COULDN't change in database")
            } else {
                UserDefaults.standard.setValue(isPrivate, forKey: "isPrivate")
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
