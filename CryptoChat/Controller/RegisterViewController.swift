//
//  RegisterViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 6/30/21.
//

import UIKit
import Firebase
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var verifyPasswordField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    private var email = ""
    private var password = ""
    private var username = ""
    private var profileImageUrl = ""
    private var imageChanged = false
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        
        setupImageProfile()
    }
    
    private func setupImageProfile() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(presentPhotoAction))
        profileImageView.addGestureRecognizer(gesture)
    }
    
    @IBAction func registerPressed(_ sender: UIButton) {
        if verifiedCredentials() {
            spinner.show(in: view)
            verifyUniqueUser()
        }
    }
    
    private func createUser() {
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            if error == nil {
                guard let id = result?.user.uid else {
                    return
                }
                
                var data: Data?
                if strongSelf.imageChanged {
                    guard let image = strongSelf.profileImageView.image, let dataImage = image.pngData() else {
                        return
                    }
                    data = dataImage
                } else {
                    guard let firstLetter = strongSelf.username.first?.lowercased() else {
                        return
                    }
                    
                    
                    let largeFont = UIFont.systemFont(ofSize: 60)
                    let configuration = UIImage.SymbolConfiguration(font: largeFont)
                    
                    guard let image = UIImage(systemName: "\(firstLetter).circle.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysOriginal) else {
                        return
                    }
                    
                    let imageColored = image.withTintColor(UIColor(named: firstLetter)!)
                    
                    guard let dataImage = imageColored.pngData() else {
                        return
                    }
                    
                    data = dataImage
                }
                
                let fileName = "\(id)_profile.png"
                
                StorageMng.shared.uploadProfilePhoto(with: data!, fileName: fileName) { result in
                    switch result {
                    case .success (let downloadURL) :
                        print (downloadURL)
//                        let user = UserInformation(idUser: id, username: strongSelf.username, emailAddress: strongSelf.email, phoneNumber: "000", profileImageUrl: downloadURL)
                        
//                        DatabaseMng.shared.createNewUser(with: user) { success in
//                            if success{
//                                self!.usernameField.text = ""
//                                self!.emailField.text = ""
//                                self!.passwordField.text = ""
//                                self!.verifyPasswordField.text = ""
//                                self!.profileImageView.image = UIImage(systemName: "person.circle.fill")
//
//                                UserDefaults.standard.set(strongSelf.username, forKey: "username")
//                                UserDefaults.standard.set(strongSelf.email, forKey: "emailAddress")
//                                UserDefaults.standard.set(false, forKey: "isPrivate")
//
//
//                                strongSelf.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true, completion: nil)
//                            } else {
//                                strongSelf.present(ShowAlert.alertsCredentials(type: nil, error: "Error saving your profile image"), animated: true)
//                            }
//                        }
                    case .failure(let error) :
                        print ("storage error \(error)")
                    }
                }
            } else {
                let error = error!.localizedDescription
                print (error)
                strongSelf.present(ShowAlert.alertsCredentials(type: .firebaseError, error: error), animated: true)
            }
        }
    }
    
    private func verifyUniqueUser() {
        DatabaseMng.shared.lookUniqueUsers(with: username) { [self] exists in
            guard let foundSomething = exists else {
                return
            }
            
            if foundSomething {
                spinner.dismiss()
                self.present(ShowAlert.alertsCredentials(type: .usernameExists, error: self.username), animated: true)
            } else {
                self.createUser()
            }
        }
    }
    
    private func verifiedCredentials() -> Bool {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let username = usernameField.text, !email.isEmpty, !username.isEmpty else {
            print ("username or email wrong")
            present(ShowAlert.alertsCredentials(type: .wrongEmail, error: "Usernam or Email"), animated: true)
            return false
        }
        
        guard let password = passwordField.text, !password.isEmpty, password.count >= 6 else {
            print ("menor to 6")
            present(ShowAlert.alertsCredentials(type: .wrongPassword, error: ""), animated: true)
            return false
        }
        
        guard let verifyPassword = verifyPasswordField.text, password == verifyPassword else {
            print ("no matching")
            present(ShowAlert.alertsCredentials(type: .wrongMatching, error: ""), animated: true)
            return false
        }
        
        self.email = email.lowercased()
        self.username = username
        self.password = password
        
        return true
    }
    
    
    @IBAction func gotoLoginViewController(_ sender: Any) {
        present(GoTo.controller(nameController: "LoginViewController", nameStoryboard: "Main"), animated: true)
    }
    
}


extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            verifyPasswordField.becomeFirstResponder()
        } else if textField == verifyPasswordField {
            createUser()
        }
        return true
    }
}


extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
        let actionSheet = UIAlertController(title: "Profile Photo", message: "Select ...", preferredStyle: .actionSheet)
        
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
