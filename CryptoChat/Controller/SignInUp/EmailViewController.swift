//
//  EmailViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 11/26/24.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    var newUser = false
    
    
    override func viewWillAppear(_ animated: Bool) {
        continueButton.roundButton(corner: 4)
    }
    
    override func viewDidLoad() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        passwordTextField.enablePasswordToggle()
        confirmPasswordTextField.enablePasswordToggle()
        
        self.hideKeyboardWhenTappedAround()
        
    }
    
    @IBAction func emailTypedTextfield(_ sender: UITextField) {
        if emailTextField.text?.isEmpty == false {
            if emailTextField.text?.isEmail == true {
                passwordTextField.isHidden = false
                isNewUserFirebase()
            } else {
                passwordTextField.isHidden = true
                confirmPasswordTextField.isHidden = true
                present(ShowAlert.alert(type: .simpleError, error: "Make sure to type a valid e-mail"), animated: true)
            }
        }
    }
    
    @IBAction func passwordTypedTextField(_ sender: UITextField) {
        
        if newUser == true {
            if passwordTextField.text?.isEmpty == false {
                if passwordTextField.text?.isValidPassword == true {
                    confirmPasswordTextField.isHidden = false
                } else {
                    present(ShowAlert.alert(type: .simpleError, error: "Make sure to use a safe password (at least 8 characters, one uppercase, one lowercase, one number)"), animated: true)
                    confirmPasswordTextField.isHidden = true
                }
            }
        } else {
            if passwordTextField.text?.isEmpty == false {
                signInUserFirebase()
            }
        }
    }
    
    @IBAction func confirmPasswordTypedTextField(_ sender: UITextField) {
        if passwordTextField.text?.isEmpty == false {
            if passwordTextField.text == confirmPasswordTextField.text {
                //create user firebase
                continueButton.isEnabled = true
            } else {
                continueButton.isEnabled = false
                present(ShowAlert.alert(type: .paswordsNotMatching, error: nil), animated: true)
                
            }
        }
    }
    
    func isNewUserFirebase() {
        //search in database if is new user
        UserDatabaseController.shared.searchEmailExists(with: emailTextField.text!) { exists in
            if exists == true {
                self.newUser = false
                self.confirmPasswordTextField.isHidden = true
                self.continueButton.isEnabled = true
            } else {
                self.newUser = true
                self.confirmPasswordTextField.isHidden = false
                self.continueButton.isEnabled = false
            }
        }
    }
    
    
    func createUserFirebase() {
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { result, error in
            if let error {
                print("Error creating user: \(error.localizedDescription)")
            } else {
                print ("User created successfully")
                
                let usernameWithoutDomain = result!.user.email!.split(separator: "@").first!.lowercased()
                let randomNumber = Int.random(in: 1000...9999)
                let username = "\(usernameWithoutDomain)_\(randomNumber)"
                
                let newUser = UserInformation(idUser: result!.user.uid, fullname: "", username: username, emailAddress: result!.user.email, phoneNumber: "", profileImageUrl: nil)
                
                UserDatabaseController.shared.createNewUser(with: newUser, signUpMethod: .email) { createdUser in
                    if createdUser == true {
                        print ("User created successfully")
                        print ("User created successfully")
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "UsernameViewController") as! UsernameViewController
                        
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        
                        vc.username = username
                        vc.newUser = true
                        vc.methodSignup = 3
                        
                        self.show(vc, sender: nil)
                    } else {
                        print("Error creating user")
                    }
                }
                //alert user of signed in and go to the next screen
//                self.present(ShowAlert.alert(type: .simpleError, error: "Signedup success go to the next screen, temporal dialog control"), animated: true)
            }
        }
    }
    
    func signInUserFirebase(){
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { result, error in
            if  let error {
                print("Error signing in user: \(error.localizedDescription)")
                self.present(ShowAlert.alert(type: .simpleError, error: error.localizedDescription), animated: true)
            } else {
                print ("User signed in successfully")
                print (result!.additionalUserInfo!)
                print (result!.user)
                self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
            }
        }
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        if newUser == true {
            createUserFirebase()
            continueButton.isEnabled = false
        } else {
            signInUserFirebase()
            continueButton.isEnabled = false
        }
    }
    
    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        if emailTextField.text?.isEmpty == true && emailTextField.text?.isEmail == false {
            let alert = ShowAlert.alert(type: .simpleError, error: "Please enter a valid email")
            present(alert, animated: true)
        } else {
            forgotPassword()
        }
    }
    
    func forgotPassword(){
        Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { error in
            if let error {
                print("Error sending password reset email: \(error.localizedDescription)")
                self.present(ShowAlert.alert(type: .simpleError, error: error.localizedDescription), animated: true)
            } else {
                print("Password reset email sent successfully")
                self.present(ShowAlert.alert(type: .simpleAlert, error: "If the email is in our data base, we've sent you an email to reset your password"), animated: true)
            }
        }
    }
}


extension EmailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

