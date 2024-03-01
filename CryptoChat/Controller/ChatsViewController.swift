//
//  ChatsViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/1/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import AMPopTip
import FanMenu
import Macaw

enum EnviromentMode {
    case darkMode
    case lightMode
    case systemMode
}

class ChatsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var fanMenu: FanMenu!

    
    let refreshControl = UIRefreshControl()
    private var chats = [Chat]()
    private var filteredChats = [Chat]()
    private var searchController = UISearchController()
    
    private var alreadyChatting = [String]()
    private var loginObserver: NSObjectProtocol?
    private var friendPhotoURL: String?
    private var currentUserID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        title = "Chats"
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Chats".localized()
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh".localized())
        refreshControl.addTarget(self, action: #selector(self.refreshTable), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.refreshTable),
            name: Notification.Name("new_message"), // UIDevice.batteryLevelDidChangeNotification,
            object: nil)
        
        verifyGeneralPasscode()
     
        spinner.show(in: view)
        
        tableView.register(ChatViewCell.nib, forCellReuseIdentifier: ChatViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView(frame: .zero)
        //navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapNewChat))
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        self.currentUserID = userID
    
        emptyView.isHidden = true
        
        setupButtons()
    }
    
    private func setupButtons(){
        let mainImage = UIImage(systemName: "square.and.pencil")
        fanMenu.button = FanMenuButton(id: "main", image: mainImage, color: Color(val: 0xFCC629))
        
        // distance between button and items
        fanMenu.menuRadius = 90.0

        // animation duration
        fanMenu.duration = 0.10

        // menu opening delay
        fanMenu.delay = 0.01

        // menu background color
        fanMenu.menuBackground = .orangeRed.with(a: 0.1)
        
        // call before animation
        fanMenu.onItemDidClick = { button in
            if self.fanMenu.isOpen {
                self.fanMenu.close()
            }
            self.didTapNewChat()
        }
        // call after animation
        fanMenu.onItemWillClick = { button in
            print("ItemWillClick: \(button.id)")
        }
        fanMenu.interval = (4.5, 0.0 * .pi)
    }
    
//    private func createBarButtonLargeTitle() {
//                let rightButton = UIButton()
//                let configuration = UIImage.SymbolConfiguration(pointSize: 23, weight: .regular)
//                let image = UIImage(systemName: "square.and.pencil", withConfiguration: configuration)
//                rightButton.setImage(image, for: .normal)
//                rightButton.setTitleColor(.label, for: .normal)
//                rightButton.addTarget(self, action: #selector(didTapNewChat), for: .touchUpInside)
//                navigationController?.navigationBar.addSubview(rightButton)
//                rightButton.tag = 1
//                rightButton.frame = CGRect(x: self.view.frame.width, y: 0, width: 30, height: 30)
//
//                let targetView = self.navigationController?.navigationBar
//
//                let trailingContraint = NSLayoutConstraint(
//                    item: rightButton,
//                    attribute: .trailingMargin,
//                    relatedBy: .equal,
//                    toItem: targetView,
//                    attribute: .trailingMargin,
//                    multiplier: 1.0, constant: -18)
//
//                let topConstraint = NSLayoutConstraint(
//                    item: rightButton,
//                    attribute: .top,
//                    relatedBy: .equal,
//                    toItem: targetView,
//                    attribute: .top,
//                    multiplier: 1.0,
//                    constant: 50)
//
//                rightButton.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([trailingContraint, topConstraint])
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        let chatsLaunched = UserDefaults.standard.value(forKey: "chatsLaunched")
        if chatsLaunched == nil {
            //Means it's new launched
            UserDefaults.standard.set(true, forKey: "chatsLaunched")
            showFirstTimeNotification()
        }
    }
    
    private func verifyGeneralPasscode(){

        if let unlocked = UserDefaults.standard.value(forKey: "unlocked") as? Bool  {
            if !unlocked {
                if (UserDefaults.standard.value(forKey: "general_passcode") as? String)!.count == 4 {
                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                    let vc = storyboard.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
                    vc.statusOfPasscode = .settingPasscode
                    vc.completion = { success in
                        if success {
                            print ("succeessssss")
                        }
                    }
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                } else {
                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                    let vc = storyboard.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
                    vc.statusOfPasscode = .verifyPasscode
                    vc.completion = { success in
                        if success {
                            print ("succeessssss")
                        }
                    }
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
    }

    @objc func refreshTable(notification: NSNotification) {
        getAllChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tabItems = tabBarController?.tabBar.items {
            let tabItem = tabItems[1]
            if tabItem.badgeValue != nil {
                tabItem.badgeValue = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        UserDefaults.standard.removeObject(forKey: "dark_mode")
//        UserDefaults.standard.synchronize()

        self.defineColorMode()
        
        getAllChats()
    }
    
    private func getAllChats() {
        
        if self.tabBarController?.selectedIndex == 1 {
            UIApplication.shared.applicationIconBadgeNumber = 0
            self.tabBarItem.badgeValue = nil
        }

//        if let vc = window.presentedViewController as? UITabBarController {
//            print ("TabBar selected: \(vc.selectedIndex)")
//            if let tabItems = vc.tabBar.items {
//                let tabItem = tabItems[0]
//                tabItem.badgeValue = "✓"
//                tabItem.badgeColor = .systemBlue
//            }
//        }
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }

        DatabaseMng.shared.getAllChats(for: userID, completion: { [weak self] result in
            print (result)
            
            self?.filteredChats.removeAll()
            self?.chats.removeAll()
            self!.refreshControl.endRefreshing()
            
            switch result {
            case .success(let unsortedChats):
                guard !unsortedChats.isEmpty else {
                    self?.tableView.reloadData()
                    self?.spinner.dismiss()
                    return
                }
                let chats = unsortedChats.sorted {
                    $0.date > $1.date
                }

                self?.chats = chats
                self?.filteredChats = chats
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.spinner.dismiss()
                }
                self!.updateUI()
            case.failure(let error):
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.spinner.dismiss()
                }
                print ("failed getting chats \(error)")
                self?.userHasFriends()
                self!.updateUI()
            }
        })
    }
    
    private func userHasFriends(){
        DatabaseMng.shared.getAllFriends(userID: currentUserID!) { result in
         
            switch result {
            case .success(let gotFriends):
                if gotFriends.isEmpty {
                    self.fanMenu.isHidden = true
                } else {
                    self.fanMenu.isHidden = false
                }
            case .failure(_):
                self.fanMenu.isHidden = true
            }
        }
    }
    
    @objc private func didTapNewChat() {
        let vc = ChatFriendViewController()
        vc.completion = { friendSelected in
            
            let friend = friendSelected
            
            let vc = ChatViewController(with: friend.usernameFriend, friendID: friend.idFriend, chatID: friend.chatID, friendPhotoURL: friend.photoURLFriend, isFriend: friend.isFriend)
            vc.isNewConversation = false
            vc.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.pushViewController(vc, animated: true)            
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
        
        
//        let vc = NewChatViewController()
//        vc.completion = { [weak self] resultSelected, resultPhotoURL, isFriend in
//            print (resultSelected)
//            self?.friendPhotoURL = resultPhotoURL
//
//            var isNewConversation = true
//            var id = ""
//            var isFriend = isFriend
//
//            if isFriend {
//                guard let chats = self?.chats else {
//                    return
//                }
//                if !chats.isEmpty {
//                    for chat in chats {
//                        if chat.username == resultSelected.usernameFriend {
//                            let senderID = chat.chatID.split(separator: "+")
//
//                            if chat.isFriend == true {
//                                isNewConversation = false
//                                id = chat.chatID
//                                isFriend = chat.isFriend
//                            } else if senderID[1] == self!.currentUserID! {
//                                isNewConversation = true
//                                isFriend = chat.isFriend
//                            }
//                            id = chat.chatID
//                        }
//                    }
//                }
//            }
//            self?.createChat(result: resultSelected, selectedPhotoURL: resultPhotoURL, isNewConverstation: isNewConversation, chatID: id, isFriend: isFriend)
//        }
//        let navVC = UINavigationController(rootViewController: vc)
//        present(navVC, animated: true)
    }
    
    private func createChat(result: SearchResult, selectedPhotoURL: String, isNewConverstation: Bool, chatID: String?, isFriend: Bool) {
        
        let usernameFriend = result.usernameFriend
        let friendID = result.friendID
        
        let vc = ChatViewController(with: usernameFriend, friendID: friendID, chatID: chatID, friendPhotoURL: selectedPhotoURL, isFriend: isFriend)
        vc.isNewConversation = isNewConverstation
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showFirstTimeNotification() {
        
        let popTip = PopTip()
        popTip.delayIn = TimeInterval(4)
        popTip.actionAnimation = .bounce(2)
        popTip.bubbleColor = .systemBlue
        popTip.show(text: "Send messages to your contacts".localized(), direction: .up, maxWidth: 150, in: view, from: CGRect(x: view.frame.size.width - 100, y: view.frame.size.height - 165, width: 100, height: 100))

      
        popTip.dismissHandler = { _ in
            let popTip = PopTip()
            popTip.actionAnimation = .bounce(2)
            popTip.show(text: "Your messages will be here".localized(), direction: .up, maxWidth: 150, in: self.view, from: CGRect(x: self.view.frame.midX - 50, y: self.view.frame.size.height - 100, width: 100, height: 100))
            popTip.bubbleColor = .systemBlue
            popTip.shouldDismissOnTap = true
            
            
            popTip.dismissHandler = { _ in
                let popTip = PopTip()
                popTip.actionAnimation = .bounce(2)
                popTip.show(text: "Your contacts will be here".localized(), direction: .up, maxWidth: 150, in: self.view, from: CGRect(x: self.view.frame.minX, y: self.view.frame.size.height - 100, width: 90, height: 100))
                popTip.bubbleColor = .systemBlue
                popTip.shouldDismissOnTap = true
            }
        }
       
        popTip.tapHandler = { popTip in
          print("tapped")
            //NO MORE new notification
        }
        popTip.tapOutsideHandler = { _ in
          print("tap outside")
        }
    }
    
    func updateUI() {
        if self.chats.isEmpty {
            self.emptyView.isHidden = false
            self.searchController.searchBar.isHidden = true
        } else {
            self.emptyView.isHidden = true
            self.searchController.searchBar.isHidden = false
        }
    }
}


extension ChatsViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredChats = searchText.isEmpty ? chats : chats.filter({ chat in
            return chat.username.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        
        tableView.reloadData()
    }
}


extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = filteredChats[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatViewCell.identifier, for: indexPath) as! ChatViewCell
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let model = filteredChats[indexPath.row]
        
        let usernameFriend = model.username
        let friendID = model.userID
        var chatID = ""
        let friendPhotoURL = model.imageURL
        let isFriend = model.isFriend
        var isNewChat = false
                
        let senderID = model.chatID.split(separator: "+")
        
        if isFriend == true {
            chatID = model.chatID
            isNewChat = false
        } else if senderID[1] == self.currentUserID! {
            isNewChat = true
        }
        chatID = model.chatID
        
        let vc = ChatViewController(with: usernameFriend, friendID: friendID, chatID: chatID, friendPhotoURL: friendPhotoURL, isFriend: isFriend)
        vc.title = model.username
        vc.isNewConversation = isNewChat
        
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        print (model)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            filteredChats.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            let chat = chats[indexPath.row]
            DatabaseMng.shared.clearChat(chatID: chat.chatID) { success in
                if success {
                    let alert = UIAlertController(title: "Cleared", message: "The chat has been erased".localized(), preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
                        self.navigationController?.popToRootViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
