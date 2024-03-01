//
//  ChatViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/15/21.
//

import UIKit
import MessageKit
import FirebaseAuth
import InputBarAccessoryView
import Nuke
import NukeExtensions
import AVKit
import MobileCoreServices
import JGProgressHUD
import AMPopTip
import YPImagePicker
import LinkPresentation

class ChatViewController: MessagesViewController {
    
    private var userID: String?
    private var senderPhotoURL: String?
    private var senderUsername: String?
    
    private let chatID: String?
    private var passcodeChat: String?
    public var isNewConversation = false
    
    private var isFriend: Bool?
    private let friendID: String?
    private let usernameFriend: String?
    private let friendPhotoURL: String?
    
    private var messages = [Message]()
    private var encryptedMessage = true
    private var decryptedMessages = [Message]()
    private var passwordEncryption = ""
    private var sender = PushNotificationSender()
    private var friendToken = ""
    private let spinner = JGProgressHUD()
    
    private var friendSince = ""
    private var phoneNumber = ""
    
    private var unlockFaceID = true
    private var autolockTime = 0
    private var passcodeOn = true
    
    private var selfSender: Sender? {
        let currentUsername = self.senderUsername
        
        if senderPhotoURL != nil {
            return Sender(photoURL: senderPhotoURL!, senderId: userID!, displayName: currentUsername!)
        } else {
            return Sender(photoURL: "", senderId: userID!, displayName: currentUsername!)
            
        }
    }
    
    init(with usernameFriend: String?, friendID: String?, chatID: String?, friendPhotoURL: String?, isFriend: Bool?) {
        self.usernameFriend = usernameFriend
        self.friendID = friendID
        self.isFriend = isFriend
        self.chatID = chatID
        self.friendPhotoURL = friendPhotoURL
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.show(in: view)
        
        guard let currentUsername = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        self.senderUsername = currentUsername
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        maintainPositionOnKeyboardFrameChanged = false
        scrollsToLastItemOnKeyboardBeginsEditing = true
        messageInputBar.inputTextView.tintColor = .red
        messageInputBar.sendButton.setTitleColor(.systemBlue, for: .normal)
        messageInputBar.sendButton.title = "Send".localized()
        messageInputBar.delegate = self
        messagesCollectionView.contentInset.top = 8
        
        self.navigationController?.navigationBar.barTintColor = UIColor(named: "lightBackground")
        
        let rightBUttonImage = UIImage(systemName: "lock.fill")!.withRenderingMode(.alwaysTemplate)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightBUttonImage, style: .plain, target: self, action: #selector(didTapUnlock))
        navigationItem.rightBarButtonItem!.tintColor = UIColor.label
        
        if !isFriend! {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        loadingsDatabase()
        
        self.title = usernameFriend?.uppercased()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.createTopBar()
        }

        
        self.showMessageTimestampOnSwipeLeft = true
        
        setupInputBar()
        
        let isFirstLaunched = UserDefaults.standard.value(forKey: "chatLaunched")
        if isFirstLaunched == nil {
            //Means it's new launched
            let locationPop4 = CGRect(x: view.frame.width - 60, y: 0, width: 100, height: 100)
            let messageToDisplay4 = "Unlock to reveal the messages".localized()
            showFirstTimeNotification(messageToDisplay: messageToDisplay4, location: locationPop4, timeDelay: 1, direction: .down)
            UserDefaults.standard.set(false, forKey: "chatLaunched")
        }
        
    }
    
    func showFirstTimeNotification(messageToDisplay: String, location: CGRect, timeDelay: Int, direction: PopTipDirection) {
        let popTip = PopTip()
        popTip.delayIn = TimeInterval(timeDelay)
        popTip.actionAnimation = .bounce(2)
        
        let positionPoptip = location
        popTip.show(text: messageToDisplay, direction: direction, maxWidth: 150, in: view, from: positionPoptip)
        popTip.bubbleColor = .systemBlue
        popTip.shouldDismissOnTap = true
        popTip.tapHandler = { popTip in
            print("tapped")
            //NO MORE new notification
        }
        
        popTip.dismissHandler = { popTip in
            print("dismissed")
        }
        
        popTip.tapOutsideHandler = { _ in
            print("tap outside")
        }
    }
    
    private func setupInputBar() {
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large)
        
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 25, height: 28), animated: false)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: largeConfig), for: .normal)
        button.tintColor = UIColor(named: "mainOrange")
        button.onTouchUpInside { [weak self] _ in
            //self?.photoVideoInputActionSheet()
            if !self!.isNewConversation {
                self!.showPicker()
            }
        }
        
        //        let buttonMic = InputBarButtonItem()
        //        buttonMic.setSize(CGSize(width: 25, height: 25), animated: false)
        //        buttonMic.setImage(UIImage(systemName: "mic.fill", withConfiguration: largeConfig), for: .normal)
        //        buttonMic.tintColor = UIColor(named: "mainOrange")
        //                buttonMic.onTouchUpInside { [weak self] _ in
        //                    self?.photoVideoInputActionSheet()
        //                }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: true)
        
        DispatchQueue.main.async {
            self.spinner.dismiss()
        }
    }
    
    @objc func clickOnButton() {
        
        if !friendPhotoURL!.isEmpty {
            if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                let friend = Friend(idFriend: friendID!, blocked: false, chatID: chatID!, friendsSince: "", isFriend: isFriend!, phoneNumberFriend: "", photoURLFriend: friendPhotoURL!, usernameFriend: usernameFriend!)
                
                vc.title = friend.usernameFriend.uppercased()
                vc.statusUserFriend = .isFriend
                vc.friend = friend
                self.show(vc, sender: self)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()
        
        if let unlock = UserDefaults.standard.value(forKey: "unlockFaceID") as? Bool  {
            unlockFaceID = unlock
        } else { unlockFaceID = false }
        
        if let autolock = UserDefaults.standard.value(forKey: "autolockTime") as? Int {
            autolockTime = autolock
        } else { autolockTime = 0 }
        
        if let passcode = UserDefaults.standard.value(forKey: "passcodeOn") as? Bool {
            passcodeOn = passcode
        } else { passcodeOn = true }
        
        if !passcodeOn {
            let rightBUttonImage = UIImage(systemName: "lock.open")!.withRenderingMode(.alwaysTemplate)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightBUttonImage, style: .plain, target: self, action: #selector(didTapUnlock))
            navigationItem.rightBarButtonItem!.tintColor = .blue
            
            self.encryptedMessage = false
            if let conversationId = chatID {
                listenForMessages(chatID: conversationId, shouldScrollToBottom: true)
            }
        }
        
        self.navigationController?.navigationBar.barTintColor = UIColor(named: "mainOrange")
        self.navigationController?.navigationBar.tintColor = UIColor.label
    }
    
    private func createTopBar(){
        
        let url = URL(string: self.friendPhotoURL!)
        var imageFriend = UIImage()
        
        let heightOfTopBar = self.navigationController!.navigationBar.frame.size.height - 5
        let button =  UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: heightOfTopBar, height: heightOfTopBar)
        UIGraphicsBeginImageContextWithOptions(button.frame.size, false, CGFloat(heightOfTopBar) )
        let rect = CGRect(x: 0, y: 0, width: button.frame.size.width, height: button.frame.size.height)
        UIBezierPath(roundedRect: rect, cornerRadius: rect.width/2).addClip()
        
        NukeExtensions.loadImage(with: url, into: button.imageView!) { result in
            switch result {
                
            case .success(let imageResponse):
                imageFriend = imageResponse.image
                imageFriend.draw(in: rect)
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                button.setImage(newImage, for: .normal)
            case .failure(let error):
                print (error)
                let emptyImage = UIImage(systemName: "person.circle.fill")
                emptyImage?.draw(in: rect)
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                button.setImage(newImage, for: .normal)
            }
        }
        
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.clickOnButton), for: .touchUpInside)
        self.navigationItem.titleView = button
    }
    
    private func loadingsDatabase() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return  }
        userID = currentUserID
        
        let filename = "profile_images/\(userID!)_profile.png"
        StorageMng.shared.downloadURL(for: filename) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.senderPhotoURL = url.absoluteString
                }
            case .failure(let error):
                print ("fail  \(error)")
            }
        }
        
        DatabaseMng.shared.getEncryptPass(chatID: chatID!) { password in
            if password != nil {
                self.passwordEncryption = password!
            }
        }
        
        DatabaseMng.shared.obtainToken(friendID: friendID!) { token in
            if !token.isEmpty {
                self.friendToken = token
            }
        }
        
        self.phoneNumber = (UserDefaults.standard.value(forKey: "phoneNumber") as? String)!
        
    }
    
    @objc private func didTapUnlock() {
        
        if self.encryptedMessage {
            if unlockFaceID {
                FaceDetectionViewController.shared.authenticationBiometricID { [self] success, error in
                    if success == true {
                        let rightBUttonImage = UIImage(systemName: "lock.open")!.withRenderingMode(.alwaysTemplate)
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightBUttonImage, style: .plain, target: self, action: #selector(didTapUnlock))
                        navigationItem.rightBarButtonItem!.tintColor = .blue
                        
                        self.encryptedMessage = false
                        if let conversationId = chatID {
                            listenForMessages(chatID: conversationId, shouldScrollToBottom: true)
                        }
                    } else {
                        print (error?.localizedDescription as Any)
                        let alert = UIAlertController(title: "Error", message: "Not matching face, possible security bridge".localized(), preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        alert.addAction(UIAlertAction(title: "Settings".localized(), style: .default, handler: { _ in
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                let vc = storyboard.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
                vc.statusOfPasscode = .verifyPasscode
                vc.completion = { [self] success in
                    if success == true {
                        let rightBUttonImage = UIImage(systemName: "lock.open")!.withRenderingMode(.alwaysTemplate)
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightBUttonImage, style: .plain, target: self, action: #selector(didTapUnlock))
                        navigationItem.rightBarButtonItem!.tintColor = .blue
                        
                        self.encryptedMessage = false
                        if let conversationId = chatID {
                            listenForMessages(chatID: conversationId, shouldScrollToBottom: true)
                        }
                    } else {
                        let alert = UIAlertController(title: "Error", message: "Not matching face, possible security bridge".localized(), preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        alert.addAction(UIAlertAction(title: "Settings".localized(), style: .default, handler: { _ in
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            let rightBUttonImage = UIImage(systemName: "lock.fill")!.withRenderingMode(.alwaysTemplate)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightBUttonImage, style: .plain, target: self, action: #selector(self.didTapUnlock))
            self.navigationItem.rightBarButtonItem!.tintColor = UIColor.label
            
            self.encryptedMessage = true
            if let conversationId = self.chatID {
                self.listenForMessages(chatID: conversationId, shouldScrollToBottom: true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.barTintColor = UIColor(named: "mainOrange")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = chatID {
            listenForMessages(chatID: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func listenForMessages(chatID: String, shouldScrollToBottom: Bool) {
        
        let encrypted = self.encryptedMessage
        
        DatabaseMng.shared.getAllMessagesForConversations(with: chatID, encryptedText: encrypted, completion: { result in
            switch result {
                
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self.messages = messages
                
                DispatchQueue.main.async {
                    
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self.messagesCollectionView.scrollToLastItem()
                    }
                    
                    self.spinner.dismiss()
                }
            case .failure(let error):
                print ("failed getting message \(error)")
            }
        })
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func showPicker() {
        
        var config = YPImagePickerConfiguration()
        
        /* Set this to true if you want to force the camera output to be a squared image. Defaults to true */
        config.onlySquareImagesFromCamera = false
        config.showsPhotoFilters = false
        
        /* Ex: cappedTo:1024 will make sure images from the library or the camera will be
         resized to fit in a 1024x1024 box. Defaults to original image size. */
        config.targetImageSize = .cappedTo(size: 1200)
        
        config.library.mediaType = .photoAndVideo
        config.usesFrontCamera = true
        config.shouldSaveNewPicturesToAlbum = false
        config.startOnScreen = .photo
        config.screens = [.video, .photo, .library]
        /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
        config.showsCrop = .rectangle(ratio: (1/1))
        config.wordings.libraryTitle = "Gallery".localized()
        config.wordings.cameraTitle = "Photo Camera".localized()
        config.wordings.videoTitle = "Video Camera"
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
                self.spinner.show(in: self.view)
                //                self.updateImageProfile(image: photo.image)
                
                guard let image = photo.modifiedImage, let imageData = image.pngData() else {
                    return
                }
                
                guard var filename = self.createMessageId()?.replacingOccurrences(of: " ", with: "-") else {
                    return
                }
                filename = "\(filename).png"
                
                guard let path = self.chatID else {
                    return
                }
                
                StorageMng.shared.uploadMessagePhoto(with: imageData, fileName: filename, pathOfFile: path) { result in
                    switch result {
                    case .success(let urlString):
                        
                        let messageId = self.createMessageId()
                        //let dat = Date()
                        //let date = Self.dateFormatter.string(from: dat)
                        
                        guard let url = URL(string: urlString) else {
                            return
                        }
                        
                        guard let placeholder = UIImage(systemName: "photo") else {
                            return
                        }
                        
                        let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                        
                        let message = Message(sender: self.selfSender!,
                                              messageId: messageId!,
                                              sentDate: Date(),
                                              kind: .photo(media))
                        DatabaseMng.shared.sendChat(to: self.chatID!, usernameFriend: self.usernameFriend!, friendID: self.friendID!, firstMessage: message, friendPhotoURL: self.friendPhotoURL!, passwordEncrypt: self.passwordEncryption, isFriend: true, receiverAccepted: true) { success in
                            
                            if success {
                                print ("sent image")
                                DispatchQueue.main.async {
                                    self.spinner.dismiss()
                                }
                                
                            } else {
                                print ("something went wrong")
                            }
                        }
                        
                    case .failure(let error):
                        print (error)
                    }
                }
                
                
                
                // self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
            } else if let video = items.singleVideo {
                self.spinner.show(in: self.view)
                
                let videp = try! Data(contentsOf: video.url)
                
                guard var filename = self.createMessageId()?.replacingOccurrences(of: " ", with: "-") else {
                    return
                }
                
                filename = "\(filename).mov"
                
                guard let path = self.chatID else {
                    return
                }
                StorageMng.shared.uploadMessagePhoto(with: videp, fileName: filename, pathOfFile: path) { result in
                    switch result {
                    case .success(let urlString):
                        
                        let messageId = self.createMessageId()
                        //let dat = Date()
                        //let date = Self.dateFormatter.string(from: dat)
                        
                        guard let url = URL(string: urlString) else {
                            return
                        }
                        
                        guard let placeholder = UIImage(systemName: "video") else {
                            return
                        }
                        
                        let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                        
                        let message = Message(sender: self.selfSender!,
                                              messageId: messageId!,
                                              sentDate: Date(),
                                              kind: .video(media))
                        
                        DatabaseMng.shared.sendChat(to: self.chatID!, usernameFriend: self.usernameFriend!, friendID: self.friendID!, firstMessage: message, friendPhotoURL: self.friendPhotoURL!, passwordEncrypt: self.passwordEncryption, isFriend: true, receiverAccepted: true) { success in
                            
                            if success {
                                print ("sent image")
                                DispatchQueue.main.async {
                                    self.spinner.dismiss()
                                }
                            } else {
                                print ("something went wrong")
                            }
                        }
                    case .failure(let error):
                        print (error)
                    }
                }
                
                
                // self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
            }
            
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
        
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    //NOT USED FUNCTION (Fetch preview for links)
    func fetchPreview(urlString: String) -> LPLinkView {
        let linkView = LPLinkView()
        if var url = URL(string: urlString) {
            let urlScheme = url.scheme
            if urlScheme == nil {
                url = URL(string: "http://\(urlString)")!
            }
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metaData, error in
                guard let data = metaData, error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    linkView.metadata = data
                    
                    let so = linkView.metadata
                    dump(so)
                }
            }
        }
        return linkView
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        spinner.show(in: view)
        
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let messageId = createMessageId(), let selfSender = self.selfSender, let idFriend = self.friendID else {
            return
        }
        
        guard let usernameToSend = usernameFriend else {
            return
        }
        
        if isNewConversation == false {
            //Send every message after the first 2 messages on conversation. (Encrypted)
            if isFriend == true {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                
                guard let conversationId = chatID else {
                    return
                }
                
                if passwordEncryption.isEmpty {
                    let randomPasscode = Int.random(in: 10000000..<99999999)
                    passwordEncryption = String(randomPasscode)
                }
                let date = Date()
                let dateString = Self.dateFormatter.string(from: date)
                
                var message: Message
                var encryptedText = ""
                
                if text.isValidURL {
                    encryptedText = Encryption.shared.encryptDecrypt(oldMessage: text.lowercased(), encryptedPassword: passwordEncryption, messageID: dateString, encrypt: true)
                    message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: date,
                                      kind: .attributedText(NSAttributedString(string: encryptedText)))
                } else {
                    encryptedText = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: passwordEncryption, messageID: dateString, encrypt: true)
                    message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: date,
                                      kind: .text(encryptedText))
                }
                
                DatabaseMng.shared.sendChat(to: conversationId, usernameFriend: usernameToSend, friendID: friendID!, firstMessage: message, friendPhotoURL: friendPhotoURL!, passwordEncrypt: passwordEncryption, isFriend: true, receiverAccepted: false) { [self] success in
                    if success {
                        //send notification
                        let chat = Chat(chatID: chatID!, username: usernameFriend!, latestMessage: encryptedText, date: dateString, isRead: false, imageURL: friendPhotoURL!, userID: friendID!, isFriend: isFriend!, messageID: messageId)
                        
                        self.sender.sendPushNotification(to: self.friendToken, title: self.senderUsername!, body: encryptedText, typeNotification: "messageNotification", chatFriend: chat)
                        
                        print ("message")
                        inputBar.inputTextView.text = ""
                    }
                }
            } else {
                //Execute when receiver approves conversation, transform the first 2 message. (Decrypted)
                
                let randomPasscode = Int.random(in: 1000..<9999)
                let passcodeString = String(randomPasscode)
                
                guard let conversationId = self.chatID else {
                    return
                }
                
                self.passwordEncryption = "\(self.passwordEncryption)\(passcodeString)"
                
                let date = Date()
                let dateString = Self.dateFormatter.string(from: date)
                
                let encryptText = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: self.passwordEncryption, messageID: dateString, encrypt: true)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: date,
                                      kind: .text(encryptText))
                DatabaseMng.shared.sendChat(to: conversationId, usernameFriend: usernameToSend, friendID: self.friendID!, firstMessage: message, friendPhotoURL: self.friendPhotoURL!, passwordEncrypt: self.passwordEncryption, isFriend: true, receiverAccepted: true) { success in
                    if success {
                        print ("need to send is_friend to database")
                        self.isFriend = true
                        self.isNewConversation = false
                        
                        inputBar.inputTextView.text = ""
                        self.becomeFirstResponder()
                        
                        DatabaseMng.shared.encryptInitialMessage(chatID: conversationId, passwordEncrypt: self.passwordEncryption, friendUsername: self.usernameFriend!, currentUsername: selfSender.displayName) { success in
                            print ("deleted the first 2 msgs")
                        }
                    }
                }
            }
        } else {
            
            //Execute when it's a new conversation - Sender requesting to chat. (Decrypted)
            let chatID = "\(idFriend)+\(selfSender.senderId)"
            let friendID = self.friendID
            let friendPhotoURL = self.friendPhotoURL
            
            if !self.isFriend! {
                
                let randomPasscode = Int.random(in: 1000..<9999)
                let passcodeString = String(randomPasscode)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .text(text))
                DatabaseMng.shared.createNewChat(usernameFriend: usernameToSend, friendID: friendID!, firstMessage: message, friendPhotoURL: friendPhotoURL!, passwordEncrypt: passcodeString, chatID: chatID) { success in
                    inputBar.inputTextView.text = ""
                    if success {
                        guard let sender = self.senderUsername else {
                            return
                        }
                        let body = "You have a new request from".localized()
                        self.sender.sendPushNotification(
                            to: self.friendToken,
                            title: "New Friend Request".localized(),
                            body: "\(body) \(sender)",
                            typeNotification: "requestNotification",
                            chatFriend: nil)
                        
                        let alert = UIAlertController(title: "Request".localized(), message: "We sent a request for chatting".localized(), preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                //new conversation but already friend
                let date = Date()
                let dateString = Self.dateFormatter.string(from: date)
                
                var passCode = ""
                for _ in 0...7{
                    let number = Int.random(in: 0..<9)
                    passCode = "\(passCode)\(String(number))"
                }
                self.passwordEncryption = passCode
                
                let encryptedText = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: passCode, messageID: dateString, encrypt: true)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: date,
                                      kind: .text(encryptedText))
                
                DatabaseMng.shared.sendChat(to: chatID, usernameFriend: usernameToSend, friendID: friendID!, firstMessage: message, friendPhotoURL: friendPhotoURL!, passwordEncrypt: passwordEncryption, isFriend: true, receiverAccepted: false) { [self] success in
                    if success {
                        //send notification
                        let chat = Chat(chatID: chatID, username: usernameFriend!, latestMessage: encryptedText, date: dateString, isRead: false, imageURL: friendPhotoURL!, userID: friendID!, isFriend: isFriend!, messageID: messageId)
                        
                        self.sender.sendPushNotification(to: self.friendToken, title: self.senderUsername!, body: encryptedText, typeNotification: "messageNotification", chatFriend: chat)
                        inputBar.inputTextView.text = ""
                        self.listenForMessages(chatID: chatID, shouldScrollToBottom: true)
                    }
                }
            }
        }
    }
    
    
    
    private func askForPassword(completion: @escaping(String) -> Void) {
        var userIdTextField: UITextField?
        
        let dialogMessage = UIAlertController(title: "Password for a new conversation".localized(), message: "Please provide a 4 numbers passcode".localized(), preferredStyle: .alert)
        var verifiedPasscode = ""
        
        let save = UIAlertAction(title: "Save".localized(), style: .default, handler: { (action) in
            if !(userIdTextField?.text!.isEmpty)! && userIdTextField?.text?.count == 4 {
                let passcode = userIdTextField?.text
                
                if let passToNumber = Int(passcode!) {
                    verifiedPasscode = String(passToNumber)
                    completion(verifiedPasscode)
                }
            } else {
                completion(verifiedPasscode)
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .default) { (action)  in
            self.navigationController?.popToRootViewController(animated: true)
        }
        dialogMessage.addAction(save)
        dialogMessage.addAction(cancel)
        
        dialogMessage.addTextField { (textField) -> Void in
            userIdTextField = textField
            userIdTextField?.keyboardType = .numberPad
            userIdTextField?.placeholder = "1234"
        }
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    //Create message ID (friend ID + current user ID + date)
    private func createMessageId() -> String? {
        let dateString = Self.dateFormatter.string(from: Date())
        
        guard let idUser = userID, let idFriend = friendID else { return nil }
        
        let newIdentifier = "\(idFriend)_\(idUser)+\(dateString)"
        return newIdentifier
    }
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        //        formatter.dateStyle = .medium
        //        formatter.timeStyle = .long
        //        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return formatter
    }()
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        guard let sender = selfSender else {
            fatalError("Self sender is nil")
        }
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        //        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarPosition(AvatarPosition(horizontal: .cellLeading, vertical: .messageBottom))
        //        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarPosition(AvatarPosition(horizontal: .cellTrailing, vertical: .messageBottom))
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.photoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.photoMessageSizeCalculator.incomingAvatarSize = .zero
            layout.videoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.videoMessageSizeCalculator.incomingAvatarSize = .zero
            layout.attributedTextMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.attributedTextMessageSizeCalculator.incomingAvatarSize = .zero
            
            layout.setMessageIncomingMessagePadding(UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 50))
            layout.setMessageOutgoingMessagePadding(UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 5))
            
            
            layout.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)))
            layout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)))
            
        }
        return messages[indexPath.section]
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            print (media)
            guard let imageURL = media.url else {
                return
            }
            NukeExtensions.loadImage(with: imageURL, into: imageView)
            //            imageView.sd_setImage(with: imageURL, completed: nil)
        case .video(let media):
            //TODO: Display video controller on message
            print ("chosing video \(media)")
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        if !self.encryptedMessage {
            
            guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
                return
            }
            let message = messages[indexPath.section]
            
            switch message.kind {
            case .photo(let media):
                print (media)
                guard let imageURL = media.url else {
                    return
                }
                
                let vc = PhotoViewController(with: imageURL)
                self.navigationController?.pushViewController(vc, animated: true)
            case .video(let media):
                print ("chosing video")
                guard let videoURL = media.url else {
                    return
                }
                
                let vc = AVPlayerViewController()
                vc.player = AVPlayer(url: videoURL)
                present(vc, animated: true) {
                    vc.player!.play()
                }
                
            default:
                break
            }
        }
        
    }
    
    
    //    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    //        let textAttribute = NSAttributedString(
    //            string: MessageKitDateFormatter.shared.string(from: message.sentDate),
    //            attributes: [
    //                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
    //                NSAttributedString.Key.foregroundColor: UIColor.darkGray
    //            ])
    //
    //        return textAttribute
    //    }
    
    //    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    //        return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    //    }
    //    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    //        return 10
    //    }
    //    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    //        return 10
    //    }
    //    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    //        return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1), NSAttributedString.Key.foregroundColor: UIColor.blue])
    //    }
    //    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    //        return 15
    //    }
    
    
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let string = "\(MessageKitDateFormatter.shared.string(from: message.sentDate)) ✓"
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 17
    }
    
    
    func messageTimestampLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let messageDate = message.sentDate
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let dateString = formatter.string(from: messageDate)
        return NSAttributedString(string: dateString, attributes: [.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
        
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        //left sender : right receiver
        return isFromCurrentSender(message: message) ? UIColor(named: "bubbleFriendUser")! : UIColor(named: "bubbleCurrentUser")!
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
        
        //Show image of friend photo for each avatar user
        //        if message.sender.senderId == userID {
        //            let url = URL(string: self.friendPhotoURL!)
        //            SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
        //                avatarView.image = image
        //            }
        //        } else {
        //            let url = URL(string: self.senderPhotoURL!)
        //            SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
        //                avatarView.image = image
        //            }
        //        }
        //        avatarView.backgroundColor = .white
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        switch message.kind {
        case .text(_):
            print ("text")
        case .photo(_):
            print ("photo")
        case .video(_):
            print ("video")
        case .linkPreview(_):
            print ("link")
        default:
            print ("anything else")
        }
        
        //to make bubble with tail
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        //        let outline: UIColor = isFromCurrentSender(message: message) ? UIColor.systemOrange.withAlphaComponent(0.5): UIColor.systemTeal.withAlphaComponent(0.5)
        //        return .bubbleTailOutline(outline, corner, .curved)
        return .bubbleTail(corner, .curved)
    }
    
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        var colorText = UIColor()
        
        switch message.kind {
        case .text(let msg):
            print (msg)
            colorText = isFromCurrentSender(message: message) ? UIColor(named: "textBubbleFriendUser")! : UIColor(named: "textBubbleCurrentUser")!
        case .attributedText(let attr):
            print (attr)
        case .photo(_):
            print ("photo")
        case .video(_):
            print ("video")
        case .linkPreview(_):
            print ("link")
        default:
            print ("any other type Text Color function")
        }
        
        return colorText
    }
    
}

extension ChatViewController: MessageCellDelegate {
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
            print("Failed to identify message when audio cell receive tap gesture")
            return
        }
        print (message)
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
        print(cell)
        guard let cellText = cell as? TextMessageCell else { return }
        guard let message = cellText.messageLabel.text else { return }
        
        if message.isValidURL {
            if var url = URL(string: message) {
                
                let urlScheme = url.scheme
                if urlScheme == nil {
                    url = URL(string: "http://\(message)")!
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: {
                    (success) in
                    print("Open \(url): \(success)")
                })
            }
        }
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print ("messages top")
    }
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributted_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}


struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Sender: SenderType {
    public  var photoURL: String
    public  var senderId: String
    public  var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}
