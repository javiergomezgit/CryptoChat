//
//  SettingsViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/13/21.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    private var selectedSetting = Int()
    private var currentData = ""
    private var amountRows = 3
    private var userFirebase = Auth.auth().currentUser
    private var username = ""
    private var phoneNumber = ""
    private var verificationID: String?
    
    private var selectedColorMode = 0
    
    init(selectedSetting: Int) {
        self.selectedSetting = selectedSetting
        super.init(nibName: nil, bundle: nil)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let tableView: UITableView = {
        let table = UITableView()
        return table
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Update".localized(), style: .plain, target: self, action: #selector(updateTapped))
        
        view.addSubview(tableView)
        
        tableView.register(SettingsViewCell.self, forCellReuseIdentifier: SettingsViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        guard let phoneNumber = UserDefaults.standard.value(forKey: "phoneNumber") as? String else {
            return
        }
        
        if let colorMode = UserDefaults.standard.value(forKey: "dark_mode") as? Bool  {
            if colorMode {
                selectedColorMode = 1
            } else {
                selectedColorMode = 2
            }
        }
        
        self.username = username
        self.phoneNumber = phoneNumber
        
        
        switch selectedSetting {
        case 0:
            amountRows = 2
            currentData = username
        case 1:
            amountRows = 2
            currentData = phoneNumber
        case 2:
            self.navigationItem.rightBarButtonItem = nil
        default:
            print ("change something else")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    @objc private func updateTapped(){
        switch selectedSetting {
        case 0:
            changeUsername()
        case 1:
            changePhoneNumber()
        case 2:
            print ("change password")
        //            changePassword()
        case 4:
            print ("change password")
        //            changePhoneNumber()
        default:
            print ("change something else")
        }
    }
    
    private func changeUsername() {
        let cellUsername = tableView.cellForRow(at: [0,1]) as! SettingsViewCell
        
        if !cellUsername.dataTextField.text!.isEmpty {
            var newUsername = cellUsername.dataTextField.text!.lowercased()
            newUsername = newUsername.cleanUsername
            
            guard let currentUser = userFirebase else {
                return
            }
            
            DatabaseMng.shared.lookUniqueUsers(with: newUsername) { [self] foundUser in
                guard let exists = foundUser else {
                    return
                }
                if exists {
                    self.present(ShowAlert.alertsCredentials(type: .usernameExists, error: newUsername), animated: true)
                } else {
                    DatabaseMng.shared.updateUsername(newUsername: newUsername, userID: currentUser.uid) { success in
                        if success {
                            UserDefaults.standard.setValue(newUsername, forKey: "username")
                            
                            let alert = UIAlertController(title: "Success".localized(), message: "Username Successfully Updated".localized(), preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                                self.navigationController?.popToRootViewController(animated: true)
                            }))
                            self.present(alert, animated: true, completion: nil)
                            
                        } else {
                            self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: "Something went wrong, try again later"), animated: true)
                        }
                    }
                }
            }
        }
    }
    
    private func changePhoneNumber(){
        let cellPhoneNumber = tableView.cellForRow(at: [0,1]) as! SettingsViewCell
        if !cellPhoneNumber.dataTextField.text!.isEmpty {
            
            guard let newPhoneNumber = cellPhoneNumber.dataTextField.text?.lowercased().cleanPhoneNumber, newPhoneNumber.count == 10 else {
                self.present(ShowAlert.alertsCredentials(type: .phoneNumber, error: "Phone number has to be 10 digits".localized()), animated: true)
                return
            }
            
            if !newPhoneNumber.isNumber {
                self.present(ShowAlert.alertsCredentials(type: .phoneNumber, error: "Phone number has to be 10 digits".localized()), animated: true)
                return
            }
            
            guard let userID = userFirebase?.uid else {
                return
            }
            DatabaseMng.shared.lookUniquePhoneNUmber(with: newPhoneNumber) { foundNumber in
                guard let exists = foundNumber else {
                    return
                }
                if exists {
                    self.present(ShowAlert.alertsCredentials(type: .simpleError, error: "\(newPhoneNumber) Already exists".localized()), animated: true)
                } else {
                    
                    PhoneAuthProvider.provider().verifyPhoneNumber("+1\(newPhoneNumber)", uiDelegate: nil) { (verificationId, error) in
                        
                        if let error = error {
                            print (error)
                            return
                        }
                        self.verificationID = verificationId
                        
                        var userIdTextField: UITextField?
                        let dialogMessage = UIAlertController(title: "Code for New phone number".localized(), message: "Please provide the code on your text messages".localized(), preferredStyle: .alert)
                        
                        let save = UIAlertAction(title: "Save".localized(), style: .default, handler: { (action) in
                            
                            if !(userIdTextField?.text!.isEmpty)! {
                                let code = userIdTextField?.text
                                
                                let credential = PhoneAuthProvider.provider().credential(withVerificationID: self.verificationID!, verificationCode: code!)
                                
                                Auth.auth().currentUser?.updatePhoneNumber(credential, completion: { (error) in
                                    
                                    if let error = error {
                                        print (error)
                                        return
                                    }
                                    
                                    DatabaseMng.shared.updatePhoneNumber(userID: userID, phoneNumber: newPhoneNumber) { success in
                                        if success == true {
                                            
                                            UserDefaults.standard.setValue(newPhoneNumber, forKey:"phoneNumber")
                                            
                                            let alert = UIAlertController(title: "Success".localized(), message: "Phone Number Successfully Updated".localized(), preferredStyle: UIAlertController.Style.alert)
                                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                                                self.navigationController?.popToRootViewController(animated: true)
                                            }))
                                            self.present(alert, animated: true, completion: nil)
                                            
                                        } else {
                                            self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: "Something went wrong, try again later"), animated: true)
                                        }
                                    }
                                })
                            }
                        })
                        
                        let cancel = UIAlertAction(title: "Cancel".localized(), style: .destructive) { (action)  in
                            //self.navigationController?.popToRootViewController(animated: true)
                        }
                        dialogMessage.addAction(save)
                        dialogMessage.addAction(cancel)
                        
                        dialogMessage.addTextField { (textField) -> Void in
                            userIdTextField = textField
                            userIdTextField?.keyboardType = .numberPad
                            userIdTextField?.placeholder = "123456"
                        }
                        self.present(dialogMessage, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    private func changeEmail() {
        let cellEmail = tableView.cellForRow(at: [0,1]) as! SettingsViewCell
        let cellConfirmEmail = tableView.cellForRow(at: [0,2]) as! SettingsViewCell
        
        if cellEmail.dataTextField.text?.lowercased() == cellConfirmEmail.dataTextField.text?.lowercased() {
            guard let currentUser = userFirebase else {
                return
            }
            if !cellEmail.dataTextField.text!.isEmpty {
                let newEmail = cellEmail.dataTextField.text!.lowercased()
                DatabaseMng.shared.updateEmail(user: currentUser, newEmail: newEmail, username: self.username) { error in
                    if error != nil {
                        self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: error?.localizedDescription), animated: true)
                    } else {
                        //self.email = newEmail
                        self.currentData = newEmail
                        UserDefaults.standard.setValue(newEmail, forKey: "emailAddress")
                        cellEmail.dataTextField.text = ""
                        cellConfirmEmail.dataTextField.text = ""
                        self.tableView.reloadData()
                        self.present(ShowAlert.alertsCredentials(type: .firebaseSuccess, error: "Email Successfully Updated".localized()), animated: true)
                    }
                }
            }
        } else {
            self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Emails don't match".localized()), animated: true)
        }
    }
    
    private func changePassword() {
        let cellPassword = tableView.cellForRow(at: [0,1]) as! SettingsViewCell
        let cellConfirmPassword = tableView.cellForRow(at: [0,2]) as! SettingsViewCell
        
        if cellPassword.dataTextField.text?.lowercased() == cellConfirmPassword.dataTextField.text?.lowercased() {
            guard let currentUser = userFirebase else {
                return
            }
            if !cellPassword.dataTextField.text!.isEmpty {
                let newPassword = cellPassword.dataTextField.text!
                DatabaseMng.shared.updatePassword(user: currentUser, newPassword: newPassword) { error in
                    if error != nil {
                        self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: error?.localizedDescription), animated: true)
                    } else {
                        cellPassword.dataTextField.text = ""
                        self.tableView.reloadData()
                        self.present(ShowAlert.alertsCredentials(type: .firebaseSuccess, error: "Password Successfully Updated".localized()), animated: true)
                    }
                }
            }
        } else {
            self.present(ShowAlert.alertsCredentials(type: .wrongCredentials, error: "Passwords don't match"), animated: true)
        }
    }
}


extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amountRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsViewCell.identifier, for: indexPath) as! SettingsViewCell
        cell.selectionStyle = .none
        
        
        switch selectedSetting {
        case 0:
            if indexPath.row == 0 {
                if !currentData.isNumber {
                    let current = "Current".localized()
                    cell.configure(username: "\(current): \(currentData)")
                    cell.dataTextField.isHidden = true
                }
            }
            if indexPath.row == 1 {
                cell.dataTextField.placeholder = "New".localized()
            }
        case 1:
            if indexPath.row == 0 {
                let current = "Current".localized()
                cell.configure(username: "\(current): \(currentData)")
                cell.dataTextField.isHidden = true
            }
            if indexPath.row == 1 {
                cell.dataTextField.keyboardType = .numberPad
                cell.dataTextField.placeholder = "New".localized()
                
            }
        case 2:
            cell.dataTextField.isHidden = true
            cell.accessoryType = .none
            
            if indexPath.row == 0 {
                cell.configure(username: "System")
            }
            if indexPath.row == 1 {
                cell.configure(username: "Dark Mode")
            }
            if indexPath.row == 2 {
                cell.configure(username: "Light Mode")
            }
        case 4:
            print ("some")
        default:
            print ("change something else")
        }
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if selectedSetting == 2 {
            
            tableView.reloadData()
            
            if let cell = tableView.cellForRow(at: indexPath as IndexPath) {

                if indexPath.row == 0 {
                    cell.accessoryType = .checkmark
                    UserDefaults.standard.removeObject(forKey: "dark_mode")
                    UserDefaults.standard.synchronize()
                    self.defineColorMode()
                }
                if indexPath.row == 1 {
                    cell.accessoryType = .checkmark
                    UserDefaults.standard.set(true, forKey: "dark_mode")
                    self.defineColorMode()
                    //dark
                }
                if indexPath.row == 2 {
                    cell.accessoryType = .checkmark
                    //light
                    UserDefaults.standard.set(false, forKey: "dark_mode")
                    self.defineColorMode()
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            
        }

    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }
}


