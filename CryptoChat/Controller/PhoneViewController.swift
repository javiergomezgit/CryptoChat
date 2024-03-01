//
//  PhoneViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/1/21.
//


import UIKit
import Firebase
import JGProgressHUD
import SafariServices


class PhoneViewController: UIViewController {
    
    @IBOutlet weak var countryCodeField: UITextField!
    @IBOutlet var phoneField: UITextField!
    @IBOutlet var codeField: UITextField!
    @IBOutlet var sendCodeButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var selectedCountry: UIButton!
    
    
    var verificationID = ""
    var newUser = false
    var userID = ""
    var phoneNumber = ""
    var countryCode = ""
    var countryList = CountryList()
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeField.isHidden = true
        registerButton.isHidden = true
        
        phoneField.delegate = self
        countryList.delegate = self
                        
        countryCodeField.addRoundedShadow(countryCodeField)
        phoneField.addRoundedShadow(phoneField)
        codeField.addRoundedShadow(codeField)
        
        sendCodeButton.roundButton(sendCodeButton)
        registerButton.roundButton(registerButton)
        
        phoneField.becomeFirstResponder()
        
        self.hideKeyboardWhenTappedAround()
    }
    
    private func verifyPhoneNumber() -> String? {
        guard let countryCode = countryCodeField.text, !countryCode.isEmpty else {
            present(ShowAlert.alertsCredentials(type: .countryCode, error: nil), animated: true)
            return nil
        }
        guard var phoneNum = phoneField.text?.cleanPhoneNumber, !phoneNum.isEmpty, phoneNum.count >= 10 else {
            present(ShowAlert.alertsCredentials(type: .phoneNumber, error: nil), animated: true)
            return nil
        }
        phoneNum = phoneNum.cleanPhoneNumber(stringPhoneToClean: phoneNum)
        
        self.phoneNumber = phoneNum
        self.countryCode = countryCode
        
        let number = "\(countryCode)\(phoneNum)"
        return number
    }
    
    @IBAction func handleCountryList(_ sender: Any) {
        let navController = UINavigationController(rootViewController: countryList)
        self.present(navController, animated: true, completion: nil)
    }
    
    @IBAction func sendCodePressed(_ sender: UIButton) {

        if let phoneNumber = verifyPhoneNumber() {
            sendCode(phoneNumber: phoneNumber)
            spinner.show(in: view)
        }
    }
    
    @IBAction func openTerms(_ sender: Any) {
        if let url = URL(string: "https://www.locknkey.app/terms-of-service/") {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }

    @IBAction func openPrivacy(_ sender: Any) {
        if let url = URL(string: "https://www.locknkey.app/privacy-policy/") {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }
      
    private func sendCode(phoneNumber: String){
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if error == nil  {
                self.verificationID = verificationID!
                self.phoneField.isHidden = true
                self.countryCodeField.isHidden = true
                self.sendCodeButton.isHidden = true
                self.selectedCountry.isHidden = true
                
                self.codeField.isHidden = false
                self.registerButton.isHidden = false
                self.label.text = "Check your text message for code verification".localized()
                self.codeField.becomeFirstResponder()
                
                DispatchQueue.main.async {
                    self.spinner.dismiss()
                }
            } else {
                self.spinner.dismiss()
                self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: "Format of country code or phone number are wrong".localized()), animated: true)
            }
            

        }
    }
    
    @IBAction func codeFieldChanged(_ sender: UITextField) {

        let text = sender.text
        if text?.count == 6 {
            registerButton.isEnabled = true
        } else {
            registerButton.isEnabled = false
        }
    }
    
    
    @IBAction func registerPressed(_ sender: UIButton) {
        
        spinner.show(in: view)
        
        let code = codeField.text
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code!)
        
        Auth.auth().signIn(with: credential) { result, error in
            
            if error == nil {
                let newUser = result?.additionalUserInfo?.isNewUser
                if !newUser! {
                    self.userID = Auth.auth().currentUser!.uid

                    DatabaseMng.shared.getInitialInfo(userID: self.userID) { userLocalInformation in
                        if userLocalInformation != nil {
                            UserDefaults.standard.setValue(userLocalInformation?.username, forKey: "username")
                            UserDefaults.standard.setValue(userLocalInformation?.phoneNumber, forKey: "phoneNumber")
                            UserDefaults.standard.setValue(userLocalInformation?.isPrivate, forKey: "isPrivate")
                            UserDefaults.standard.setValue(userLocalInformation?.profilePhotoURL, forKey: "profilePhotoURL")
                            UserDefaults.standard.setValue(userLocalInformation?.generalPasscode, forKey: "general_passcode")
                            UserDefaults.standard.setValue(false, forKey: "unlocked")

                            let pushManager = PushNotificationManager(userID: Auth.auth().currentUser!.uid)
                            pushManager.updateFirestorePushTokenIfNeeded()

                            self.spinner.dismiss()
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
                                
                                self.show(GoTo.controller(nameController: "PhoneViewController", nameStoryboard: "Main"), sender: self)
                                
                            } catch {
                                print ("error loging out")
                            }
                        }
                    }
                } else {
                    self.createUser()
                }
            } else {
                self.spinner.dismiss()
                self.present(ShowAlert.alertsCredentials(type: .firebaseError, error: "Wrong code, make sure to verify in your text messages (SMS)".localized()), animated: true)
            }
        }
    }
    
    private func createUser() {
        
        let userID = Auth.auth().currentUser!.uid
   
        guard let image = UIImage(named: "#") else {
            return
        }

        guard let dataImage = image.pngData() else {
            return
        }
        
        let data = dataImage
        let fileName = "\(userID)_profile.png"
        
        StorageMng.shared.uploadProfilePhoto(with: data, fileName: fileName) { result in
            switch result {
            case .success (let downloadURL) :
                print (downloadURL)
                let user = UserInformation(idUser: userID, username: self.phoneNumber, phoneNumber: self.phoneNumber, profileImageUrl: downloadURL)
                
                DatabaseMng.shared.createNewUser(with: user, countryCode: self.countryCode) { success in
                    if success{
                        UserDefaults.standard.set(self.phoneNumber, forKey: "username")
                        UserDefaults.standard.set(self.phoneNumber, forKey: "phoneNumber")
                        UserDefaults.standard.set(false, forKey: "isPrivate")
                        UserDefaults.standard.set(false, forKey: "unlocked")
                        UserDefaults.standard.set("0000", forKey: "general_passcode")
                        UserDefaults.standard.setValue(downloadURL, forKey: "profilePhotoURL")

                        let pushManager = PushNotificationManager(userID: Auth.auth().currentUser!.uid)
                        pushManager.updateFirestorePushTokenIfNeeded()
                        
                        self.spinner.dismiss()
                        self.show(GoTo.controller(nameController: "UsernameViewController", nameStoryboard: "Main"), sender: nil)
                        
                    } else {
                        self.present(ShowAlert.alertsCredentials(type: nil, error: "Error saving your profile, try again"), animated: true)
                    }
                }
            case .failure(let error) :
                print ("storage error \(error)")
            }
        }
    }
}

extension PhoneViewController: CountryListDelegate {
    func selectedCountry(country: Country) {
        
        phoneField.isEnabled = true
        countryCodeField.isEnabled = true
        sendCodeButton.isEnabled = true
        
        let countryName = country.name ?? ""
        let countryFlag = country.flag ?? ""
        print(country.countryCode)
        print(country.phoneExtension)
        
        selectedCountry.setTitle("\(countryFlag) \(countryName)", for: .normal)
        self.countryCode = "+" + country.phoneExtension
        countryCodeField.text = self.countryCode
    }
}

extension PhoneViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == phoneField {
            if let phoneNumber = verifyPhoneNumber() {
                sendCode(phoneNumber: phoneNumber)
            }
        }
        return true
    }
}
