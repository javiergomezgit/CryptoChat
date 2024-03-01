//
//  FriendsViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/22/21.
//


import UIKit
import MessageUI
import FirebaseAuth
import ContactsUI
import AMPopTip
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
    //    private var filteredFriends = [Friend]()
    
    private var friendPhotoURL = ""
    private var chats = [Chat]()
    private var currentUserID: String?
    //    private var searchController = UISearchController()
    
    //    var arrIndexSection : NSArray = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","#"]
    var friendsDictionary = [String: [Friend]]()
    var friendSectionTitles = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        title = "My Friends".localized()
        tabBarController?.selectedIndex = 1
        
        tableView.register(FriendsViewCell.self, forCellReuseIdentifier: FriendsViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
     
        tableView.sectionIndexColor = .label
        tableView.sectionIndexBackgroundColor = .systemBackground
        tableView.sectionIndexTrackingBackgroundColor = UIColor(named: "mainOrange")

        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh".localized())
        refreshControl.addTarget(self, action: #selector(self.refreshTable), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        self.hideKeyboardWhenTappedAround()
        
        //        searchController = UISearchController(searchResultsController: nil)
        //        searchController.searchResultsUpdater = self
        //        searchController.obscuresBackgroundDuringPresentation = false
        //        searchController.searchBar.placeholder = "Search Contacts".localized()
        //        navigationItem.searchController = searchController
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
        
        DatabaseMng.shared.getAllFriends(userID: userID) { result in
            
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

//                self.friendSectionTitles = [String](self.friendsDictionary.keys)
//                self.friendSectionTitles = self.friendSectionTitles.sorted(by: { $0 < $1 })
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .failure(let error):
                if self.friends.isEmpty {
                    self.emptyViewFriends.isHidden = false
                    //                    self.searchController.searchBar.isHidden = true
                    
                } else {
                    self.emptyViewFriends.isHidden = true
                    //                    self.searchController.searchBar.isHidden = true
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
            let locationPop = CGRect(x: view.frame.size.width - 95, y: view.frame.size.height - 185, width: 100, height: 100)
            let messageToDisplay = "Look for new contacts".localized()
            showFirstTimeNotification(messageToDisplay: messageToDisplay, location: locationPop, timeDelay: 4)
            UserDefaults.standard.set(true, forKey: "friendsLaunched")
        }
    }
    
    @objc func didTapInvite() {
        let vc = InviteFriendsViewController()
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    
    @objc func didTapAddContact() {
        let vc = NewChatViewController()
        vc.completion = { [weak self] resultSelected, resultPhotoURL, isFriend in
            print (resultSelected)
            self?.friendPhotoURL = resultPhotoURL
            
            var isNewConversation = true
            var id = ""
            var isFriend = isFriend
            
            if isFriend {
                DatabaseMng.shared.searchForChatID(currentUserID: self!.currentUserID!, friendID: resultSelected.friendID) { chatID, isFriendDB in
                    if chatID != nil {
                        id = chatID!
                        isNewConversation = false
                        if !isFriendDB! {
                            isFriend = false
                        }
                    }
                    self?.createChat(result: resultSelected, selectedPhotoURL: resultPhotoURL, isNewConverstation: isNewConversation, chatID: id, isFriend: isFriend)
                }
            } else {
                var acceptingFriend = Friend(idFriend: "", blocked: false, chatID: "", friendsSince: "", isFriend: false, phoneNumberFriend: "", photoURLFriend: "", usernameFriend: "")
                var senderCurrentSame = false
                for friend in self!.friends {
                    if friend.idFriend == resultSelected.friendID {
                        let senderID = friend.chatID.split(separator: "+")
                        if senderID[0] == friend.idFriend {
                            senderCurrentSame = true
                        }
                        acceptingFriend = friend
                        break
                    }
                }
                
                if senderCurrentSame {
                    if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                        vc.title = acceptingFriend.usernameFriend
                        vc.friend = acceptingFriend
                        vc.statusUserFriend = .currentAndSenderSame
                        self!.show(vc, sender: self)
                    }
                } else if !acceptingFriend.idFriend.isEmpty {
                    if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                        vc.title = acceptingFriend.usernameFriend
                        vc.statusUserFriend = .receiverAccepting
                        vc.friend = acceptingFriend
                        self!.show(vc, sender: self)
                    }
                } else {
                    self?.createChat(result: resultSelected, selectedPhotoURL: resultPhotoURL, isNewConverstation: isNewConversation, chatID: id, isFriend: isFriend)
                }
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createChat(result: SearchResult, selectedPhotoURL: String, isNewConverstation: Bool, chatID: String?, isFriend: Bool) {
        
        let usernameFriend = result.usernameFriend
        let friendID = result.friendID
        
        let vc = ChatViewController(with: usernameFriend, friendID: friendID, chatID: chatID, friendPhotoURL: selectedPhotoURL, isFriend: isFriend)
        vc.isNewConversation = isNewConverstation
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showFirstTimeNotification(messageToDisplay: String, location: CGRect, timeDelay: Int) {
        let popTip = PopTip()
        popTip.delayIn = TimeInterval(timeDelay)
        popTip.actionAnimation = .bounce(2)
        
        let positionPoptip = location
        popTip.show(text: messageToDisplay, direction: .left, maxWidth: 150, in: view, from: positionPoptip)
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
    
    
}

//extension FriendsViewController: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
//
//    func updateSearchResults(for searchController: UISearchController) {
//        let searchBar = searchController.searchBar
//        filterContentForSearchText(searchBar.text!)
//    }
//
//    func filterContentForSearchText(_ searchText: String) {
//        filteredFriends = searchText.isEmpty ? friends : friends.filter({ friend in
//            return friend.usernameFriend.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
//        })
//
//        tableView.reloadData()
//    }
//}

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
        //filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let model = filteredFriends[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendsViewCell.identifier, for: indexPath) as! FriendsViewCell
        
        let friendKey = friendSectionTitles[indexPath.section]
        if let friendValues = friendsDictionary[friendKey] {
            //cell.userImageView.image = UIImage(systemName: "person.crop.circle.fill")
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
            //            let model = filteredFriends[indexPath.row]
            let friendID = model.idFriend
            let isFriend = model.isFriend
            
            let senderID = model.chatID.split(separator: "+")
            
            if isFriend {
                if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                    vc.title = model.usernameFriend
                    vc.friend = model
                    vc.statusUserFriend = .isFriend
                    //                vc.modalPresentationStyle = .popover
                    //                vc.modalTransitionStyle = .crossDissolve
                    self.show(vc, sender: self)
                }
            } else {
                if senderID[0] == friendID {
                    //Means sender and current user are the same
                    if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                        vc.title = model.usernameFriend
                        vc.friend = model
                        vc.statusUserFriend = .currentAndSenderSame
                        
                        self.show(vc, sender: self)
                    }
                } else {
                    if let vc = UIStoryboard(name: "Friends", bundle: nil).instantiateViewController(identifier: "FriendProfileViewController") as? FriendProfileViewController {
                        vc.title = model.usernameFriend
                        vc.statusUserFriend = .receiverAccepting
                        vc.friend = model
                        self.show(vc, sender: self)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
}

