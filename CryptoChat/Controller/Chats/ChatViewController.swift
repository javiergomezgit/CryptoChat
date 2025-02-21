//
//  ChatViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/27/24.
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
import YPImagePicker
import LinkPresentation


class ChatViewController: MessagesViewController {
    
    private var userID: String?
    private var senderPhotoURL: String?
    private var senderUsername: String?
    
    private var chatID: String?
    private var passcodeChat: String?
    public var isNewConversation = false
    
    private var isContact: Bool?
    private let friendID: String?
    private let usernameFriend: String?
    private let friendPhotoURL: String?
    
    private var messages = [Message]()
    private var decryptedMessages = [Message]()
    private var passwordEncryption = ""
    private var sender = PushNotificationSender()
    private var friendToken = ""
    
    private var friendSince = ""
    private var phoneNumber = ""
    
    private var unlockFaceID = true
    private var autolockTime = 0
    private var passcodeOn = true
    
    private var saveMediaInDevice = true
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return formatter
    }()
    
    private var selfSender: Sender? {
        let currentUsername = self.senderUsername // self.usernameFriend
        
        if  senderPhotoURL != nil { //friendPhotoURL != nil {
            return Sender(photoURL: senderPhotoURL!, senderId: userID!, displayName: currentUsername!) //Sender(photoURL: friendPhotoURL!, senderId: friendID!, displayName: usernameFriend!)
        } else {
            return Sender(photoURL: "", senderId: userID!, displayName: currentUsername!)
            
        }
    }
    
    init(with usernameFriend: String?, friendID: String?, chatID: String?, friendPhotoURL: String?, isContact: Bool?) {
        self.usernameFriend = usernameFriend
        self.friendID = friendID
        self.isContact = isContact
        self.chatID = chatID
        self.friendPhotoURL = friendPhotoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        guard let currentUsername = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        self.senderUsername = currentUsername
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        maintainPositionOnInputBarHeightChanged = false
        scrollsToLastItemOnKeyboardBeginsEditing = true
        messageInputBar.inputTextView.tintColor = .red
        
        // Configure the send button
        messageInputBar.sendButton.setTitle(nil, for: .normal) // Explicitly remove the title
        let arrowImage = UIImage(systemName: "arrow.up.right.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 35))
            .withRenderingMode(.alwaysTemplate)
        messageInputBar.sendButton.setImage(arrowImage, for: .normal)
        messageInputBar.sendButton.tintColor = .systemBlue // Tint the arrow
        messageInputBar.delegate = self
        messagesCollectionView.contentInset.top = 8
        
        self.navigationController?.navigationBar.barTintColor = UIColor(named: "lightBackground")
        
        if !isContact! {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        loadingsDatabase()
        
        self.title = usernameFriend?.uppercased()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createTopBar()
        }
        
        
        self.showMessageTimestampOnSwipeLeft = true
        
        setupInputBar()
        
        let isFirstLaunched = UserDefaults.standard.value(forKey: "chatLaunched")
        if isFirstLaunched == nil {
            //Means it's new launched
            UserDefaults.standard.set(false, forKey: "chatLaunched")
        }
        
        let saveMediaInDeviceLocal = UserDefaults.standard.value(forKey: "saveMediaInDevice") as? Bool
        if saveMediaInDeviceLocal == nil{
            UserDefaults.standard.set(true, forKey: "saveMediaInDevice")
            UserDefaults.standard.synchronize()
            self.saveMediaInDevice = true
        } else if saveMediaInDeviceLocal == false {
            UserDefaults.standard.set(false, forKey: "saveMediaInDevice")
            UserDefaults.standard.synchronize()
            self.saveMediaInDevice = false
        } else {
            self.saveMediaInDevice = true
        }
    }
    
    private func setupInputBar() {
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large)
        
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 30, height: 28), animated: false)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: largeConfig), for: .normal)
        button.tintColor = UIColor(named: "greenAccent") // UIColor(named: "mainOrange")
        button.onTouchUpInside { [weak self] _ in
            if !self!.isNewConversation {
                self!.showPicker()
            }
        }
//
//            let buttonMic = InputBarButtonItem()
//            buttonMic.setSize(CGSize(width: 25, height: 25), animated: false)
//            buttonMic.setImage(UIImage(systemName: "mic.fill", withConfiguration: largeConfig), for: .normal)
//            buttonMic.tintColor = UIColor(named: "mainOrange")
//            buttonMic.onTouchUpInside { [weak self] _ in
//                print ("here")
//                // self?.photoVideoInputActionSheet()
//            }
//            
        messageInputBar.setLeftStackViewWidthConstant(to: 35, animated: true)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: true)
    }
    
    @objc func clickOnButton() {
        if !friendPhotoURL!.isEmpty {
            if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                let friend = Friend(idFriend: friendID!, blocked: false, chatID: chatID!, friendsSince: "", isContact: isContact!, phoneNumberFriend: "", photoURLFriend: friendPhotoURL!, usernameFriend: usernameFriend!)
                
                vc.title = friend.usernameFriend.uppercased()
                vc.statusUserFriend = .isContact
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
        
        let navigationHeightBar = self.navigationController?.navigationBar.frame.size.height ?? 10
        
        let heightOfTopBar = navigationHeightBar - 5
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
        let filename = "profile_images/\(currentUserID)_profile.png"
        StorageDatabaseController.shared.downloadURL(for: filename) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.senderPhotoURL = url.absoluteString
                }
            case .failure(let error):
                print ("fail  \(error)")
            }
        }
        
        UserDatabaseController.shared.getEncryptPass(chatID: self.chatID!) { password in
            if password != nil {
                self.passwordEncryption = password!
            }
        }
        
        UserDatabaseController.shared.obtainToken(friendID: self.friendID!) { token in
            if !token.isEmpty {
                self.friendToken = token
            }
        }
        
        self.phoneNumber = (UserDefaults.standard.value(forKey: "phoneNumber") as? String)!
        
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
                
        UserDatabaseController.shared.getAllMessagesForConversations(with: chatID, completion: { result in
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
        config.targetImageSize = .cappedTo(size: 1400)
        
        config.library.mediaType = .photoAndVideo
        config.usesFrontCamera = true
        if saveMediaInDevice {
            config.shouldSaveNewPicturesToAlbum = true
        } else {
            config.shouldSaveNewPicturesToAlbum = false
        }
        config.startOnScreen = .photo
        config.screens = [.video, .photo, .library]
        /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
        config.showsCrop = .none //.rectangle(ratio: (1/1))
        config.wordings.libraryTitle = "Gallery"
        config.wordings.cameraTitle = "Photo Camera"
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
                return
            }
            
            if let photo = items.singlePhoto {
                let image = photo.image
                guard let imageData = image.pngData() else {
                    print ("error converting image to data")
                    print (image)
                    return
                }
                
                guard var filename = self.createMessageId()?.replacingOccurrences(of: " ", with: "-") else {
                    return
                }
                filename = "\(filename).png"
                
                guard let path = self.chatID else {
                    return
                }
                
                StorageDatabaseController.shared.uploadMessagePhoto(with: imageData, fileName: filename, pathOfFile: path) { result in
                    switch result {
                    case .success(let urlString):
                        
                        let messageId = self.createMessageId()
                        
                        guard let url = URL(string: urlString) else {
                            return
                        }
                        guard let placeholder = UIImage(systemName: "photo") else {
                            return
                        }
                        
                        let media = Media(url: url, image: image, placeholderImage: placeholder, size: .zero)
                        
                        let message = Message(sender: self.selfSender!,
                                              messageId: messageId!,
                                              sentDate: Date(),
                                              kind: .photo(media))
                        UserDatabaseController.shared.sendChat(to: self.chatID!, usernameFriend: self.usernameFriend!, friendID: self.friendID!, previewMessage: "Photo Media", firstMessage: message, friendPhotoURL: self.friendPhotoURL!, passwordEncrypt: self.passwordEncryption, isContact: true) { success in
                            //image
                            if success {
                                print ("sent image")
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
                //                self.spinner.show(in: self.view)
                
                let videp = try! Data(contentsOf: video.url)
                
                guard var filename = self.createMessageId()?.replacingOccurrences(of: " ", with: "-") else {
                    return
                }
                
                filename = "\(filename).mov"
                
                guard let path = self.chatID else {
                    return
                }
                StorageDatabaseController.shared.uploadMessagePhoto(with: videp, fileName: filename, pathOfFile: path) { result in
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
                        
                        UserDatabaseController.shared.sendChat(to: self.chatID!, usernameFriend: self.usernameFriend!, friendID: self.friendID!, previewMessage: "Video Media", firstMessage: message, friendPhotoURL: self.friendPhotoURL!, passwordEncrypt: self.passwordEncryption, isContact: true) { success in
                            //image
                            if success {
                                print ("sent image")
                                DispatchQueue.main.async {
                                    //                                    self.spinner.dismiss()
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
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        //setupInputBar()
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //        spinner.show(in: view)
        
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let messageId = createMessageId(), let selfSender = self.selfSender else {
            return
        }
        
        guard let usernameToSend = usernameFriend else {
            return
        }
        
        let chatID = self.chatID
        let friendID = self.friendID
        let friendPhotoURL = self.friendPhotoURL
          
        let date = Date()
        let dateString = Self.dateFormatter.string(from: date)

        let encryptedText = Encryption.shared.encryptDecrypt(oldMessage: text, encryptedPassword: self.passwordEncryption, messageID: dateString, encrypt: true)
        
        var message: Message?
    
        //TODO: Detect and send message as a link
        if encryptedText.isValidURL {
            message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: date,
                              kind: .text(encryptedText))
            
        } else {
            message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: date,
                              kind: .text(encryptedText))
        }
              
        UserDatabaseController.shared.sendChat(to: chatID!, usernameFriend: usernameToSend, friendID: friendID!, previewMessage: text, firstMessage: message!, friendPhotoURL: friendPhotoURL!, passwordEncrypt: passwordEncryption, isContact: true) { [self] success in
            if success {
                //send notification
                let chat = Chat(chatID: chatID!, username: usernameFriend!, latestMessage: encryptedText, date: dateString, isRead: false, imageURL: friendPhotoURL!, userID: friendID!, isContact: isContact!, messageID: messageId)
                
                self.sender.sendPushNotification(to: self.friendToken, title: self.senderUsername!, body: text, typeNotification: "messageNotification", chatFriend: chat)
                inputBar.inputTextView.text = ""
                self.listenForMessages(chatID: chatID!, shouldScrollToBottom: true)
            }
        }
    }
    
    //Create message ID (friend ID + current user ID + date)
    private func createMessageId() -> String? {
        let dateString = Self.dateFormatter.string(from: Date())
        
        guard let idUser = userID, let idFriend = friendID else { return nil }
        
        let newIdentifier = "\(idFriend)_\(idUser)+\(dateString)"
        return newIdentifier
    }
    
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    var currentSender: any MessageKit.SenderType {
        guard let sender = selfSender else {
            fatalError("Self sender is nil")
        }
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
     
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
            
            layout.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))) //current user and should be right side
            layout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)))
            
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
        return isFromCurrentSender(message: message) ? UIColor(named: "bubbleCurrentUser")! : UIColor(named: "bubbleFriendUser")!
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
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
            colorText = isFromCurrentSender(message: message) ? UIColor(named: "textBubbleCurrentUser")! : UIColor(named: "textBubbleFriendUser")!
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
    
    func isFromCurrentSender(message: MessageType) -> Bool {
        //This makes the sender bubble in the right side
        return message.sender.senderId != selfSender?.senderId
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

struct LinkPreview: LinkItem {
    var text: String?
    var attributedText: NSAttributedString?
    var url: URL
    var title: String?
    var teaser: String
    var thumbnailImage: UIImage
}


