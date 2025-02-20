//
//  UsernameViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/4/24.
//

import UIKit
import FirebaseAuth
//import JGProgressHUD

class UsernameViewController: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    var username = ""
    var newUser = true
    var methodSignup = 0
    var imageChanged = false
    var userID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(presentPhotoAction))
        profileImageView.addGestureRecognizer(gesture)
        profileImageView.cornersImage(circleImage: false, border: true, roundedCorner: 8)
        
        guard let userID = Auth.auth().currentUser?.uid else {
            exit (0)
        }
        self.userID = userID
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        usernameField.text = username
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        guard let username = usernameField.text, !username.isEmpty else {
            present(ShowAlert.alert(type: .simpleAlert, error: "Username can't be empty"), animated: true)
            return
        }
        
        self.username = username.lowercased().cleanUsername
        //spinner.show(in: view)
        verifyUniqueUser(username: self.username)
    }
    
    private func verifyUniqueUser(username: String) {
        
        UserDatabaseController.shared.lookUniqueUsers(with: username) { foundUsername, foundUserID in
            if foundUserID == self.userID {
                //Username that was found is the same of the current user
                UserDatabaseController.shared.updateUsername(newUsername: username, userID: self.userID) { success in
                    if success {
                        UserDefaults.standard.set(username, forKey: "username")
                        UserDefaults.standard.synchronize()
                        self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                    } else {
                        self.present(ShowAlert.alert(type: .wrongCredentials, error: "Error, try again later"), animated: true)
                    }
                }
            } else {
                //Username that was found is from another user
                if foundUsername != nil {
                    print ("exists")
                    self.present(ShowAlert.alert(type: .usernameExists, error: "Username already exists"), animated: true)
                } else {
                    UserDatabaseController.shared.updateUsername(newUsername: username, userID: self.userID) { success in
                        if success {
                            UserDefaults.standard.set(username, forKey: "username")
                            UserDefaults.standard.synchronize()
                            self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                        } else {
                            self.present(ShowAlert.alert(type: .wrongCredentials, error: "Error, try again later"), animated: true)
                        }
                    }
                }
            }
        }
    }
    
    func updateImageProfile() {
        var data: Data?
        let fileName = "\(userID)_profile.png"
        
        guard let image = self.profileImageView.image, let dataImage = image.pngData() else {
            return
        }
        data = dataImage
        
        StorageDatabaseController.shared.uploadProfilePhoto(with: data!, fileName: fileName) { result in
            switch result {
            case .success (let downloadURL) :
                print (downloadURL)
                
                //                UserDefaults.standard.setValue(downloadURL, forKey: "profilePhotoURL")
                
                //                                    DispatchQueue.main.async {
                //                                        self.spinner.dismiss()
                //                                    }
                
                //                self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                
            case .failure(let error) :
                //                self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                let image = UIImage(named: "#")
                self.profileImageView.image = image
                
                DispatchQueue.main.async {
                    self.present(ShowAlert.alert(type: .simpleError, error: String(error.localizedDescription)), animated: true)
                }
                print ("storage error \(error)")
            }
        }
    }
}




extension UsernameViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.editedImage] as? UIImage else {
            return
        }
        
        let alertController = UIAlertController(title: "Confirm", message: "Do you want to save this photo?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.imageChanged = true
            self.profileImageView.image = selectedImage
            self.updateImageProfile()
            picker.dismiss(animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
            self.imageChanged = true
            picker.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        // Present the alert
        picker.present(alertController, animated: true, completion: nil)
        
    }
    
    /*
     picker.dismiss(animated: true, completion: nil)
     guard  let selectedImage = info[.editedImage] as? UIImage else {
     return
     }
     imageChanged = true
     self.profileImageView.image = selectedImage
     */
    
    func presentCamera() {
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    @objc func presentPhotoAction() {
        let actionSheet = UIAlertController(title: "Profile Photo", message: "Attach a photo for your profile", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
}


