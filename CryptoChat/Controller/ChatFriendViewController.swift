//
//  ChatFriendViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 9/28/21.
//

import UIKit
import JGProgressHUD
import FirebaseAuth

class ChatFriendViewController: UIViewController {

    public var completion: ((Friend) -> (Void))?

    private let spinner = JGProgressHUD(style: .dark)
    private var friends = [Friend]()
    private var filteredFriends = [Friend]()

    private var friendPhotoURL = ""
    private var chats = [Chat]()
    private var currentUserID: String?
    private var searchController = UISearchController()
    private var currentUsername = ""
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(ChatFriendViewCell.self, forCellReuseIdentifier: ChatFriendViewCell.identifier)
        return table
    }()
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView(frame: .zero)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        currentUsername = username
        
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)

        self.hideKeyboardWhenTappedAround()

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Contacts".localized()
        navigationItem.searchController = searchController
        definesPresentationContext = true
                
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .done, target: self, action: #selector(didTapDismiss))
        
    }
    
    @objc private func didTapDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

        self.getAllFriends()
    }
    
    private func getAllFriends() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        DatabaseMng.shared.getAllFriendsChats(userID: userID) { result in
            
            self.friends.removeAll()
            self.filteredFriends.removeAll()
            
            switch result {
            case .success(let gotFriends):
                if !gotFriends.isEmpty {
                    self.friends = gotFriends
                    self.filteredFriends = gotFriends
                    DispatchQueue.main.async {
                        self.updateUI()
                        self.tableView.reloadData()
                    }
                }
            case .failure(let error):
                print (error)
                DispatchQueue.main.async {
                    self.updateUI()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
}

extension ChatFriendViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatFriendViewCell.identifier, for: indexPath) as! ChatFriendViewCell
        
        let model = filteredFriends[indexPath.row]
        cell.configure(with: model)
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = filteredFriends[indexPath.row]
        
        self.dismiss(animated: true) {
            self.completion?(model)
        }
//
//        let vc = ChatViewController(with: usernameFriend, friendID: friendID, chatID: chatID, friendPhotoURL: friendPhotoURL, isFriend: isFriend)
//        vc.title = usernameFriend
//        vc.isNewConversation = isNewChat
//
//        vc.navigationItem.largeTitleDisplayMode = .never
//        navigationController?.pushViewController(vc, animated: true)
//        print (model)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}


extension ChatFriendViewController: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredFriends = searchText.isEmpty ? friends : friends.filter({ friend in
            return friend.usernameFriend.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
    
    func updateUI() {
        if self.friends.isEmpty {
            self.searchController.searchBar.isHidden = true

        } else {
            self.searchController.searchBar.isHidden = false
            self.tableView.reloadData()
        }
    }
}
