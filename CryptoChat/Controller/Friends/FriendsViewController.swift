//
//  FriendsViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 1/7/25.
//

import UIKit
import MessageUI
import FirebaseAuth
import ContactsUI
import FanMenu
import Macaw
import SwiftUI


class FriendsViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyViewFriends: UIView!
    @IBOutlet weak var fanMenu: FanMenu!
    
    let refreshControl = UIRefreshControl()
    
    private var friends = [Friend]()
    private var friendPhotoURL = ""
    private var chats = [Chat]()
    private var currentUserID: String?
    var friendsDictionary = [String: [Friend]]()
    var friendSectionTitles = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.selectedIndex = 1
        
        tableView.register(FriendsViewCell.self, forCellReuseIdentifier: FriendsViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
     
        tableView.sectionIndexColor = .label
        tableView.sectionIndexBackgroundColor = .systemBackground
        tableView.sectionIndexTrackingBackgroundColor = UIColor(named: "mainOrange")

        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refreshTable), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        self.hideKeyboardWhenTappedAround()
        
        definesPresentationContext = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshTable),
            name: NSNotification.Name ("friendsTableChanged"),
            object: nil)
        
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        self.currentUserID = userID
        
        setupButtons()
    }
    
    private func setupButtons(){
        let mainImage = UIImage(systemName: "plus")
        fanMenu.button = FanMenuButton(id: "main", image: mainImage, color: Color(val: 0xFCC629))
        
        
        fanMenu.menuRadius = 90.0 // distance between button and items
        fanMenu.duration = 0.10 // animation duration
        fanMenu.delay = 0.01 // menu opening delay
        fanMenu.menuBackground = .orangeRed.with(a: 0.1)
        
        fanMenu.items = [
            FanMenuButton(
                id: "invite_contacts",
                image: UIImage(named: "inviteContacts"),
                color: Color(val: 0x5D9B96).with(a: 0.6)
            ),
            FanMenuButton(
                id: "add_users",
                image: UIImage(named: "searchUsers"),
                color: Color(val: 0x5D9B96).with(a: 0.6)
            ),
            FanMenuButton(
                id: "noid",
                image: "visa",
                color: .white.with(a: 0)
            )
        ]
        
        fanMenu.onItemDidClick = { button in
            let selectedButton = button.id
            switch selectedButton {
            case "invite_contacts" :
                self.didTapInvite()
            case "add_users":
                self.didTapAddContact()
            case "main":
                print("pressed menu")
            default:
                print ("chose wrong button")
            }
        }
        fanMenu.interval = (4.5, 0.0 * .pi)
    }
    
    @objc func refreshTable(notification: NSNotification) {
        self.getAllFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

        self.getAllFriends()
    }
    
    private func getAllFriends() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        UserDatabaseController.shared.getAllFriends(userID: userID) { result in
            
            self.friends.removeAll()
            self.friendsDictionary.removeAll()
            self.friendSectionTitles.removeAll()
            
            self.refreshControl.endRefreshing()
            
            switch result {
            case .success(let gotFriends):
                if gotFriends.isEmpty {
                    self.emptyViewFriends.isHidden = false
                } else {
                    self.emptyViewFriends.isHidden = true
                }
                self.friends = gotFriends
                
                for friend in gotFriends {
                    let friendKey = String(friend.usernameFriend.prefix(1))
                    if var friendValues = self.friendsDictionary[friendKey] {
                        friendValues.append(friend)
                        self.friendsDictionary[friendKey] = friendValues
                    } else {
                        self.friendsDictionary[friendKey] = [friend]
                    }
                }
                
                var sortedLetters = [String]()
                var sortedNumbers = [String]()
                for friendKey in self.friendsDictionary.keys {
                    let key = friendKey.first
                                       
                    if !key!.isNumber {
                        sortedLetters.append(friendKey)
                    } else {
                        sortedNumbers.append(friendKey)
                    }
                }
                
                sortedLetters = sortedLetters.sorted(by: { $0 < $1 })
                sortedNumbers = sortedNumbers.sorted(by: { $0 < $1 })
                let temp = sortedLetters + sortedNumbers
                
                self.friendSectionTitles = temp
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure(let error):
                if self.friends.isEmpty {
                    self.emptyViewFriends.isHidden = false
                } else {
                    self.emptyViewFriends.isHidden = true
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                print (error)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let friendsLaunched = UserDefaults.standard.value(forKey: "friendsLaunched")
        if friendsLaunched == nil {
            //Means it's new launched
            UserDefaults.standard.set(true, forKey: "friendsLaunched")
        }
    }
    
    @objc func didTapInvite() {
        let vc = InviteFriendsViewController()
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    @objc func didTapAddContact() {

        let vc = SearchFriendViewController()
        if self.friends.isEmpty {
            vc.noContactsYet = true
        } else {
            vc.noContactsYet = false
        }

        vc.completion = { friendSelected, friendPhotoURL, isContact, chatID in
            print (friendSelected)
            self.friendPhotoURL = friendPhotoURL
            let vc = ChatViewController(with: friendSelected.usernameFriend, friendID: friendSelected.friendID, chatID: chatID, friendPhotoURL: friendPhotoURL, isContact: isContact)
            vc.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return friendSectionTitles.count
    }
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return friendSectionTitles
    }
    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return friendSectionTitles[section].uppercased()
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor.label.withAlphaComponent(0.05)
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.label.withAlphaComponent(0.8)
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let friendKey = friendSectionTitles[section]
        if let friendValues = friendsDictionary[friendKey] {
            return friendValues.count
        }
        
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendsViewCell.identifier, for: indexPath) as! FriendsViewCell
        
        let friendKey = friendSectionTitles[indexPath.section]
        if let friendValues = friendsDictionary[friendKey] {
            cell.configure(with: friendValues[indexPath.row])
        }
        return cell
    }
    override func viewWillDisappear(_ animated: Bool) {
        if let tabItems = tabBarController?.tabBar.items {
            let tabItem = tabItems[0]
            if tabItem.badgeValue != nil {
                tabItem.badgeValue = nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let friendKey = friendSectionTitles[indexPath.section]
        
        if let friendValues = friendsDictionary[friendKey] {
            let model = friendValues[indexPath.row]
            let vc = ChatViewController(with:model.usernameFriend, friendID: model.idFriend, chatID: model.chatID, friendPhotoURL: model.photoURLFriend, isContact: true)
            vc.title = model.usernameFriend
            vc.isNewConversation = false
            vc.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
}

