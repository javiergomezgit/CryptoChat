//
//  ChatsViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/1/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
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
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Chats"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
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
    
    override func viewDidAppear(_ animated: Bool) {
        let chatsLaunched = UserDefaults.standard.value(forKey: "chatsLaunched")
        if chatsLaunched == nil {
            //Means it's new launched
            UserDefaults.standard.set(true, forKey: "chatsLaunched")
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

        self.defineColorMode()
        
        getAllChats()
    }
    
    private func getAllChats() {
        
        if self.tabBarController?.selectedIndex == 1 {
            UIApplication.shared.applicationIconBadgeNumber = 0
            self.tabBarItem.badgeValue = nil
        }
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }

        UserDatabaseController.shared.getAllChats(for: userID, completion: { [weak self] result in
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
                self!.updateUI()
            }
        })
    }

    
    @objc private func didTapNewChat() {
        let vc = ChatFriendViewController()
        vc.completion = { friendSelected in
            
            let friend = friendSelected
            
            let vc = ChatViewController(with: friend.usernameFriend, friendID: friend.idFriend, chatID: friend.chatID, friendPhotoURL: friend.photoURLFriend, isContact: friend.isContact)
            vc.isNewConversation = false
            vc.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.pushViewController(vc, animated: true)            
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
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
        let friendPhotoURL = model.imageURL
        let isContact = model.isContact
        let isNewChat = false
        let chatID = model.chatID
                        
        let vc = ChatViewController(with: usernameFriend, friendID: friendID, chatID: chatID, friendPhotoURL: friendPhotoURL, isContact: isContact)
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
            UserDatabaseController.shared.clearChat(chatID: chat.chatID) { success in
                if success {
                    let alert = UIAlertController(title: "Cleared", message: "The chat has been erased", preferredStyle: UIAlertController.Style.alert)
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
