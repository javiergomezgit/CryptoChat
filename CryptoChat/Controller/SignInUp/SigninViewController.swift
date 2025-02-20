//
//  SigninViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 11/27/24.
//

import UIKit
import SafariServices
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit

class SigninViewController: UIViewController {
    
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var phoneNumberButton: UIButton!
    
    fileprivate var currentNonce: String?
    public var logout = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailButton.roundButton(corner: 4)
        phoneNumberButton.roundButton(corner: 4)
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
    
    @IBAction func appleButtonPressed(_ sender: UIButton) {
        handleLoginWithAppleID()
    }
    
}


extension SigninViewController {
    
    @objc func handleLoginWithAppleID() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        controller.delegate = self
        controller.presentationContextProvider = self
        
        controller.performRequests()
    }
    
    @objc func logoutt() {
        logout = true
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        controller.delegate = self
        controller.presentationContextProvider = self
        
        controller.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

extension SigninViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Invalid credential type: \(String(describing: authorization.credential.debugDescription))")
            return
        }
        
        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleIDToken = appleCredential.identityToken else {
            print("Unable to fetch identity token")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
        }
        
        if (logout == true) {
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
            else {
                print("Unable to retrieve AppleIDCredential")
                return
            }
            
            guard let _ = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleAuthCode = appleIDCredential.authorizationCode else {
                print("Unable to fetch authorization code")
                return
            }
            
            guard let authCodeString = String(data: appleAuthCode, encoding: .utf8) else {
                print("Unable to serialize auth code string from data: \(appleAuthCode.debugDescription)")
                return
            }
            
            Task {
                do {
                    try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
                    //                    try await user?.delete()
                    //                  self.updateUI()
                } catch {
                    print (error)
                }
            }
            
        } else {
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleCredential.fullName)
                                                    
                Auth.auth().signIn(with: credential) { result, error in
                    if error == nil {
                        let newUser = result?.additionalUserInfo?.isNewUser
                        
                        if !newUser! {
                            let userID = Auth.auth().currentUser!.uid
                            UserDatabaseController.shared.getInitialInfo(userID: userID) { userLocalInformation in
                                if userLocalInformation != nil {
                                    UserDefaults.standard.setValue(userLocalInformation?.username, forKey: "username")
                                    UserDefaults.standard.setValue(userLocalInformation?.phoneNumber, forKey: "phoneNumber")
                                    UserDefaults.standard.setValue(userLocalInformation?.isPrivate, forKey: "isPrivate")
                                    UserDefaults.standard.setValue(userLocalInformation?.profilePhotoURL, forKey: "profilePhotoURL")
                                    UserDefaults.standard.setValue(userLocalInformation?.generalPasscode, forKey: "general_passcode")
                                    UserDefaults.standard.setValue(false, forKey: "unlocked")
                                    print ("Obtained initial information")
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
                                        print ("Initial information is empty / nil")
                                    } catch {
                                        self.present(ShowAlert.alert(type: .simpleError, error: "Error creating your account"), animated: true)
                                        print ("error loging out")
                                    }
                                }
                            }
                        } else {
                            self.createUser(appleUser: appleCredential)
                        }
                    } else {
                        //                    self.spinner.dismiss()
                        self.present(ShowAlert.alert(type: .simpleError, error: "Error creating your account"), animated: true)
                    }
                }
        }
    }
    
    private func createUser(appleUser: ASAuthorizationAppleIDCredential) {
        
        let user = Auth.auth().currentUser!
        guard let email = Auth.auth().currentUser?.email else {
            print ("failed writing user information in DB ")
            self.present(ShowAlert.alert(type: nil, error: "Error saving your profile with Apple ID, try again with different method"), animated: true)
            return
        }
        let name = appleUser.fullName?.givenName ?? email
        let lastName = appleUser.fullName?.familyName ?? ""
        
        guard let image = UIImage(named: "#") else {
            return
        }
        
        guard let dataImage = image.pngData() else {
            return
        }
        
        let data = dataImage
        let fileName = "\(user.uid)_profile.png"
        
        StorageDatabaseController.shared.uploadProfilePhoto(with: data, fileName: fileName) { result in
            switch result {
            case .success (let downloadURL) :
                print (downloadURL)
                
                let usernameWithoutDomain = email.split(separator: "@").first!.lowercased()
                let randomNumber = Int.random(in: 1000...9999)
                let username = "\(usernameWithoutDomain)_\(randomNumber)"
                
                let user = UserInformation(idUser: user.uid, fullname: "\(name) \(lastName)", username: username, emailAddress: email, phoneNumber: "", profileImageUrl: downloadURL)
                
                UserDatabaseController.shared.createNewUser(with: user, signUpMethod: .appleID) { success in
                    if success{
                        UserDefaults.standard.set(username, forKey: "username")
                        UserDefaults.standard.set("", forKey: "phoneNumber")
                        UserDefaults.standard.set(false, forKey: "isPrivate")
                        UserDefaults.standard.set(false, forKey: "unlocked")
                        UserDefaults.standard.set("0000", forKey: "general_passcode")
                        UserDefaults.standard.set(downloadURL, forKey: "profilePhotoURL")
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "UsernameViewController") as! UsernameViewController
                        
                        vc.modalPresentationStyle = .fullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        
                        vc.username = username
                        vc.newUser = true
                        vc.methodSignup = 1
                        
                        self.show(vc, sender: nil)
                    } else {
                        self.present(ShowAlert.alert(type: nil, error: "Error saving your profile, try again"), animated: true)
                    }
                }
            case .failure(let error) :
                print ("storage error \(error)")
            }
        }
    }
    
    private func signout(userID: String){
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userID) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid.
                break
            case .revoked:
                // The Apple ID credential is revoked.
                break
            case .notFound:
                // No credential was found, so show the sign-in UI.
                break
            default:
                break
            }
        }
        
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
}


extension SigninViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
