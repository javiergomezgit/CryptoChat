//
//  LoginViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/1/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class LoginViewController: UIViewController {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    var username = ""
    var email = ""
    var password = ""
//    var isPrivate = false
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField.delegate = self
        passwordField.delegate = self
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func loginPressed(_ sender: UIButton?) {
        login()
    }
    
    @IBAction func forgotPassPressed(_ sender: UIButton) {
        guard let email = usernameField.text, !email.isEmpty else {
            present(ShowAlert.alertsCredentials(type: .firebaseError, error: "Type your email"), animated: true)
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if error == nil {
                self.present(ShowAlert.alertsCredentials(type: .firebaseSuccess, error: "We sent you an email with a link."), animated: true)
            } else {
                let errorD = error?.localizedDescription
                self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: errorD), animated: true)
            }
        }
    }
    
    private func login(){
        if verifiedCredentials() {
            //spinner.show(in: view)
            
            if email.isEmpty {
                //obtain email with username
                DatabaseMng.shared.searchForUsernames(with: username, emailToLook: "") { [self] userFound, isPrivate  in
                    if userFound != nil {
                        Auth.auth().signIn(withEmail: userFound!, password: self.password) { result, error in
                            DispatchQueue.main.async {
                                self.spinner.dismiss()
                            }
                            if error == nil {
                                self.usernameField.text = ""
                                self.passwordField.text = ""
                                UserDefaults.standard.set(self.username, forKey: "username")
                                UserDefaults.standard.set(userFound, forKey: "emailAddress")
                                UserDefaults.standard.set(isPrivate, forKey: "isPrivate")
                                self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                                print (self.username)
                                print (result?.user.uid as Any)
                            } else {
                                DispatchQueue.main.async {
                                    self.spinner.dismiss()
                                }
                                self.username = ""
                                self.email = ""
                                self.passwordField.text = ""
                                let error = error!.localizedDescription
                                self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: error), animated: true)
                            }
                        }
                    } else {
                        self.present(ShowAlert.alertsCredentials(type: .usernameNotFound, error: nil), animated: true)
                    }
                }
            } else {
                Auth.auth().signIn(withEmail: self.email, password: self.password) { result, error in
                    
                    if error == nil {
                        DispatchQueue.main.async {
                            self.spinner.dismiss()
                        }
                        // DatabaseMng.shared.searchForUsernames(with: "", emailToLook: self.email) { [self] userFound in
                        DatabaseMng.shared.searchForUsernames(with: "", emailToLook: (result?.user.uid)!) { [self] userFound, isPrivate  in
                            usernameField.text = ""
                            passwordField.text = ""
                            UserDefaults.standard.set(userFound, forKey: "username")
                            UserDefaults.standard.set(self.email, forKey: "emailAddress")
                            UserDefaults.standard.set(isPrivate, forKey: "isPrivate")
                            //self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                            self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true, completion: nil)
                            print (result?.user.uid as Any)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.spinner.dismiss()
                        }
                        self.username = ""
                        self.email = ""
                        self.passwordField.text = ""
                        let error = error!.localizedDescription
                        self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: error), animated: true)
                    }
                }
            }
        }
    }
    
    private func verifiedCredentials() -> Bool {
        guard let username = usernameField.text, !username.isEmpty else {
            present(ShowAlert.alertsCredentials(type: .usernameEmpty, error: nil), animated: true)
            return false
        }
        guard let password = passwordField.text, !password.isEmpty else {
            present(ShowAlert.alertsCredentials(type: .wrongPassword, error: nil), animated: true)
            return false
        }
        
        if username.contains("@"){
            self.email = username
            self.password = password
        } else {
            self.username = username
            self.password = password
        }
        return true
    }
    
    @IBAction func gotoRegisterViewController(_ sender: Any) {
        self.present(GoTo.controller(nameController: "RegisterViewController", nameStoryboard: "Main"), animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            self.login()
        }
        return true
    }
}
