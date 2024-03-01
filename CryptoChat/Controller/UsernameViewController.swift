//
//  UsernameViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/9/21.
//


import UIKit
import FirebaseAuth
import JGProgressHUD


class UsernameViewController: UIViewController {

   
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var saveImageButton: UIButton!
    @IBOutlet weak var buttonPlus: UIImageView!
    
    var username = ""
    var imageChanged = false
    let spinner = JGProgressHUD()
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField.delegate = self
//        self.hideKeyboardWhenTappedAround()
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        usernameField.becomeFirstResponder()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(presentPhotoAction))
        profileImageView.addGestureRecognizer(gesture)
        
        usernameField.addRoundedShadow(usernameField)
        continueButton.roundButton(continueButton)
        saveImageButton.roundButton(saveImageButton)
        profileImageView.cornersImage(circleImage: false, border: true, roundedCorner: 8)

    }
    
//    @objc func keyboardWillShow(notification: NSNotification) {
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            if self.view.frame.origin.y == 0 {
//                self.view.frame.origin.y -= keyboardSize.height - 100
//            }
//        }
//    }
//    @objc func keyboardWillHide(notification: NSNotification) {
//        if self.view.frame.origin.y != 0 {
//            self.view.frame.origin.y = 0
//        }
//    }
    
    @IBAction func continuePressed(_ sender: Any) {
        guard let username = usernameField.text, !username.isEmpty else {
            print ("username or email wrong")
            present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Error, try again".localized()), animated: true)
            return
        }
        
        self.username = username.lowercased().cleanUsername
        spinner.show(in: view)
        verifyUniqueUser(username: self.username)
    }
    
    @IBAction func imageButtonPressed(_ sender: Any) {
        usernameLabel.text = "Username".localized()
        descriptionLabel.text = "You can change it later".localized()
            profileImageView.isHidden = true
        buttonPlus.isHidden = true
            saveImageButton.isHidden = true
            usernameField.isHidden = false
            continueButton.isHidden = false
    }
    
    private func verifyUniqueUser(username: String) {
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        DatabaseMng.shared.lookUniqueUsers(with: username) { exists in
            
            if exists != nil {
                if exists! {
                    DispatchQueue.main.async {
                        self.spinner.dismiss()
                    }
                    self.present(ShowAlert.alertsCredentials(type: .usernameExists, error: "Username already exists".localized()), animated: true)
                    
                } else {
                    DatabaseMng.shared.updateUsername(newUsername: username, userID: userID) { success in
                        if success {
                               var data: Data?
                            if self.imageChanged {
                                guard let image = self.profileImageView.image, let dataImage = image.pngData() else {
                                    return
                                }
                                data = dataImage
                            } else {
                                guard let firstLetter = username.first?.lowercased() else { return }
                                
                                if let image = UIImage(named: "\(firstLetter)") {
                                    guard let dataImage = image.pngData() else {
                                        return
                                    }
                                    data = dataImage
                                } else {
                                    let image = UIImage(named: "#")
                                    guard let dataImage = image!.pngData() else {
                                        return
                                    }
                                    data = dataImage
                                }
                            }
                            
                            let fileName = "\(userID)_profile.png"
                            StorageMng.shared.uploadProfilePhoto(with: data!, fileName: fileName) { result in
                                switch result {
                                case .success (let downloadURL) :
                                    print (downloadURL)
                                    
                                    UserDefaults.standard.setValue(downloadURL, forKey: "profilePhotoURL")

                                    DispatchQueue.main.async {
                                        self.spinner.dismiss()
                                    }
                                    
                                    self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)

                                case .failure(let error) :
                                    self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                                    print ("storage error \(error)")
                                }
                            }
                        } else {
                            self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Error, try again".localized()), animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
    }
    
}

extension UsernameViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            guard let username = usernameField.text, !username.isEmpty else {
                present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Error, try again".localized()), animated: true)
                return false
            }
            
            self.username = username.lowercased()
            verifyUniqueUser(username: username)
        }
        return true
    }
}


extension UsernameViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard  let selectedImage = info[.editedImage] as? UIImage else {
            return
        }
        imageChanged = true
        self.profileImageView.image = selectedImage
    }
    
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
        let actionSheet = UIAlertController(title: "Profile Photo".localized(), message: "Attach a photo for your profile".localized(), preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Camera".localized(), style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Gallery".localized(), style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
}


