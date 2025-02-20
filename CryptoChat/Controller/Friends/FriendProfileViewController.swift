//
//  FriendProfileViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 1/7/25.
//

import UIKit
import FirebaseAuth
//import SDWebImage
import Nuke
import NukeExtensions
import AVKit


class FriendProfileViewController: UIViewController {
    
    @IBOutlet weak var friendProfileImageView: UIImageView!
    @IBOutlet weak var friendPhoneNumberLabel: UILabel!
    @IBOutlet weak var friendUsernameLabel: UILabel!
    @IBOutlet weak var viewFriend: UIView!
    @IBOutlet weak var openChatButton: UIButton!
    @IBOutlet weak var makeCallButton: UIButton!
    @IBOutlet weak var blockFriendButton: UIButton!
    @IBOutlet weak var clearChatButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var coverMediaView: UIView!
    @IBOutlet weak var saveInAlbumSwitch: UISwitch!
    
    public var friend = Friend(idFriend: "", blocked: false, chatID: "", friendsSince: "", isContact: false, phoneNumberFriend: "", photoURLFriend: "", usernameFriend: "")
    private var currentPasscode = ""
    private var currentUserID = ""
    private var passcodeSender = ""
    public var statusUserFriend = status.currentAndSenderSame
    private var sender = PushNotificationSender()
    private var friendURL = ""
    private var sharedMediaURLs = [String]()
    private var saveInAlbum = false
    
    enum status {
        case currentAndSenderSame
//        case receiverAccepting
        case isContact
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch statusUserFriend {
        case .currentAndSenderSame:
            currentAndSenderSame()
        case .isContact:
            isContact()
            loadSharedMedia()
        }
        
        self.hideKeyboardWhenTappedAround()
        
        guard let currentUserid = Auth.auth().currentUser?.uid else {
            return
        }
        self.currentUserID = currentUserid
        
        UserDatabaseController.shared.getEncryptPass(chatID: friend.chatID) { password in
            if password != nil {
                self.passcodeSender = password!
            }
        }
        
        navigationItem.leftBarButtonItem?.tintColor = .white
        navigationItem.backBarButtonItem?.tintColor = .red
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.font : UIFont(name: "Futura", size: 20)!
        ]
        
        UserDatabaseController.shared.getPhoneWithID(userID: friend.idFriend) { phoneNumber in
            self.friendPhoneNumberLabel.text = phoneNumber
        }
        
        friendUsernameLabel.text = friend.usernameFriend
        
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(viewPhotoFriend))
        friendProfileImageView.addGestureRecognizer(gesture)
        
        createButtonViews()
        
        if friend.friendsSince.isEmpty {
            openChatButton.isEnabled = false
        }
        
        collectionView.register(FriendMediaViewCell.nib, forCellWithReuseIdentifier: FriendMediaViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        UserDatabaseController.shared.changeSaveInAlbum(userID: currentUserID, friendID: friend.idFriend,  changeSetting: false) { isSaveInAlbum in
            self.saveInAlbumSwitch.isOn = isSaveInAlbum
        }

    }
    
    @IBAction func saveInAlbumChanged(_ sender: UISwitch) {
        print("The switch is \(sender.isOn ? "ON" : "OFF")")
        UserDatabaseController.shared.changeSaveInAlbum(userID: currentUserID, friendID: friend.idFriend, changeSetting: true) { isSaveInAlbum in
            UserDefaults.standard.setValue(isSaveInAlbum, forKey: "isSaveInAlbum")
        }
    }
    
    @IBAction func unlockMedia(_ sender: Any) {
        FaceDetectionViewController.shared.authenticationBiometricID { [self] success, error in
            if success == true {
                
                self.coverMediaView.isHidden = true
                
            } else {
                
                self.coverMediaView.isHidden = false
                
                let alert = UIAlertController(title: "Error", message: "Not matching face, possible security bridge", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                    self.navigationController?.popToRootViewController(animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        
    }
    
    
    private func loadSharedMedia(){
        
        let itemSize = UIScreen.main.bounds.width/3 - 2
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        collectionView.collectionViewLayout = layout
        
        
        let path = "messages/\(friend.chatID)"
        
        StorageDatabaseController.shared.downloadSharedMediaURLs(path: path) { result in
            switch result {
            case .success(let urlStrings):
                
                print (urlStrings)
                self.sharedMediaURLs = urlStrings
                self.collectionView.reloadData()
            case .failure(let error):
                print (error)
                
            }
        }
    }
    
    private func createButtonViews() {
//        openChatButton.roundButton(openChatButton)
//        makeCallButton.roundButton(makeCallButton)
//        blockFriendButton.roundButton(blockFriendButton)
//        acceptFriendButton.roundButton(acceptFriendButton)
//        rejectFriendButton.roundButton(rejectFriendButton)
//        cancelRequestButton.roundButton(cancelRequestButton)
//        clearChatButton.roundButton(clearChatButton)
        openChatButton.roundButton(corner: 2)
        makeCallButton.roundButton(corner: 2)
        blockFriendButton.roundButton(corner: 2)
        clearChatButton.roundButton(corner: 2)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 100
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    @objc private func viewPhotoFriend() {
        if let url = URL(string: self.friendURL) {
            let vc = PhotoViewController(with: url)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func currentAndSenderSame() {
//        viewRequestFriend.isHidden = true
        viewFriend.isHidden = true
    }

    private func receiverAccepting() {
//        viewSender.isHidden = true
//        viewRequestFriend.isHidden = false
        viewFriend.isHidden = true
        
        getInitialMessage()
    }

    private func isContact(){
//        viewSender.isHidden = true
//        viewRequestFriend.isHidden = true
        viewFriend.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

        createFriendProfileImage()
    }

    private func getInitialMessage() {
        UserDatabaseController.shared.getInitialMessage(with: friend.chatID) { message, passwordEncrypt in
            if message != nil && passwordEncrypt != nil {
                DispatchQueue.main.async {
//                    self.friendMessageLabel!.text = message
                    self.passcodeSender = passwordEncrypt!
                }
            }
        }
    }
    
    func createFriendProfileImage() {
        
        friendProfileImageView.contentMode = .scaleAspectFill

        //TODO: remove url from database
        let path = "profile_images/\(friend.idFriend)_profile.png"
        StorageDatabaseController.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                self!.friendURL = url.absoluteString
                DispatchQueue.main.async {
//                    self!.friendProfileImageView.sd_setImage(with: url, completed: nil)
                    NukeExtensions.loadImage(with: url, into: self!.friendProfileImageView)
                }
            case .failure(let error):
                print (error)
            }
        })
    }
    
    @IBAction func acceptFriendTapped(_ sender: Any) {
        
        let randomPasscode = Int.random(in: 1000..<9999)
        currentPasscode = String(randomPasscode)
        
        createChat()
    }
    
    private func createChat() {
        let passwordEncryption = "\(passcodeSender)\(currentPasscode)"
        
        let date = Date()
        
        let encryptText = "hello back" //Encryption.shared.encryptDecrypt(oldMessage: "Hello back", encryptedPassword: passwordEncryption, messageID: dateString, encrypt: true)
        
        guard let currentUsername = UserDefaults.standard.value(forKey: "username") as? String else {
            print ("error finding username")
            return
        }
        
        guard let currentPhotoURL = UserDefaults.standard.value(forKey: "profilePhotoURL") as? String else {
            print ("error finding profile url")
            return
        }
        
        let selfSender = Sender(photoURL: currentPhotoURL, senderId: currentUserID, displayName: currentUsername)
        
        let message = Message(sender: selfSender,
                              messageId: createMessageId()!,
                              sentDate: date,
                              kind: .text(encryptText))
        
        UserDatabaseController.shared.sendChat(to: friend.chatID, usernameFriend: friend.usernameFriend, friendID: friend.idFriend, previewMessage: "Hello Back", firstMessage: message, friendPhotoURL: friend.photoURLFriend, passwordEncrypt: passwordEncryption, isContact: true) { [self] success in
            if success {
                    self.statusUserFriend = .isContact
                    
                    self.isContact()
                    
                    UserDatabaseController.shared.obtainToken(friendID: self.friend.idFriend) { token in
                        if !token.isEmpty {
                            self.sender.sendPushNotification(to: token, title: currentUsername, body: "Your contact accepted the request", typeNotification: "acceptNotification", chatFriend: nil)
                        }
                    }
                    self.navigationController!.popToRootViewController(animated: true)
            }
        }
        
    }
    
    @IBAction func openChatTapped(_ sender: Any) {
        let vc = ChatViewController(with: friend.usernameFriend, friendID: friend.idFriend, chatID: friend.chatID, friendPhotoURL: friend.photoURLFriend, isContact: friend.isContact)
        vc.title = friend.usernameFriend
        vc.isNewConversation = false
        
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func makeCallTapped(_ sender: Any) {
        let phoneNumber = friend.phoneNumberFriend
        let url: NSURL = NSURL(string: "tel://\(phoneNumber)")!
        UIApplication.shared.open(url as URL)
    }
    
    @IBAction func clearChatTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Clear Chat", message: "Are you sure you want to erase chat", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Clear", style: .default, handler: { (action: UIAlertAction!) in
            UserDatabaseController.shared.clearChat(chatID: self.friend.chatID) { success in
                if success {
                    print ("Erased")
                    self.navigationController!.popToRootViewController(animated: true)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "No!", style: .destructive, handler: { (action: UIAlertAction!) in
            alert .dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
        
//        DatabaseMng.shared.clearChat(chatID: friend.chatID) { success in
//            if success {
//                let alert = UIAlertController(title: "Done", message: "Cleared", preferredStyle: UIAlertController.Style.alert)
//                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
//                    self.navigationController?.popToRootViewController(animated: true)
//                }))
//                self.present(alert, animated: true, completion: nil)
//            }
//        }
    }
    
    @IBAction func blockFriendTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Block Contact", message: "Are you sure you want to block contact", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Block", style: .default, handler: { (action: UIAlertAction!) in
            UserDatabaseController.shared.blockFriend(chatID: self.friend.chatID , currentID: self.currentUserID, friendID: self.friend.idFriend, friendUsername: self.friend.usernameFriend, completion: { success in
                if success {
                    print ("Blocked")
                    self.navigationController!.popToRootViewController(animated: true)
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "No!", style: .destructive, handler: { (action: UIAlertAction!) in
            alert .dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
        
        
//        DatabaseMng.shared.blockFriend(chatID: friend.chatID , currentID: currentUserID, friendID: friend.idFriend, friendUsername: friend.usernameFriend, completion: { success in
//            if success {
//                let alert = UIAlertController(title: "Done", message: "Blocked", preferredStyle: UIAlertController.Style.alert)
//                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
//                    self.navigationController?.popToRootViewController(animated: true)
//                }))
//                self.present(alert, animated: true, completion: nil)
//            }
//        })
    }
    
    @IBAction func cancelRequestTapped(_ sender: Any) {
        UserDatabaseController.shared.deleteFriend(chatID: friend.chatID) { success in
            print (success)
        }
        
        self.navigationController!.popToRootViewController(animated: true)
    }
      
    //Create message ID (friend ID + current user ID + date)
    private func createMessageId() -> String? {
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let idUser = currentUserID
        let idFriend = friend.idFriend
        
        let newIdentifier = "\(idFriend)_\(idUser)+\(dateString)"
        return newIdentifier
    }
    
    @IBAction func rejectFriendTapped(_ sender: Any) {
        UserDatabaseController.shared.deleteFriend(chatID: friend.chatID) { success in
            print (success)
        }
        
        self.navigationController!.popToRootViewController(animated: true)
    }
    

}


extension FriendProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sharedMediaURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let url = sharedMediaURLs[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FriendMediaViewCell.identifier, for: indexPath) as! FriendMediaViewCell
        
//        cell.layer.borderColor = UIColor.black.cgColor
//        cell.layer.borderWidth = 1
//        cell.layer.cornerRadius = 8
        
        cell.configure(with: url)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let cell = collectionView.cellForItem(at: indexPath) as! FriendMediaViewCell
        let media = cell.urlLabel.text
        
        let url = URL(string: media!)
        
        if media!.contains(".png") {
            let vc = PhotoViewController(with: url!)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: url!)
            present(vc, animated: true) {
                vc.player!.play()
            }
        }
        
    }
    
    
    // change background color when user touches cell
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.backgroundColor = UIColor.red
    }

    // change background color back when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.backgroundColor = UIColor.cyan
    }
    
    
}
