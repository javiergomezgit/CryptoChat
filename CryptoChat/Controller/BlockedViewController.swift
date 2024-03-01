//
//  BlockedViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 9/15/21.
//

import UIKit
import FirebaseAuth

class BlockedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    var currentUserID = ""
    private var friends = [SearchResult]()
    private var filteredFriends = [SearchResult]()
    @IBOutlet weak var emptyViewBlocked: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(BlockedViewCell.nib, forCellReuseIdentifier: BlockedViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh".localized())
        refreshControl.addTarget(self, action: #selector(self.refreshTable), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Contacts".localized()
        navigationItem.searchController = searchController
        definesPresentationContext = true
                
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        self.currentUserID = userID
    }
    
    @objc func refreshTable(notification: NSNotification) {
        self.getBlockedFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

        getBlockedFriends()
    }
    
    private func getBlockedFriends() {
        
        self.friends.removeAll()
        self.filteredFriends.removeAll()
        
        DatabaseMng.shared.getBlockedUsers(userID: currentUserID) { blockedFriends in
            if blockedFriends != nil {
                self.emptyViewBlocked.isHidden = true
                self.friends = blockedFriends!.sorted {
                    $0.usernameFriend > $1.usernameFriend
                }
                self.filteredFriends = self.friends
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                self.emptyViewBlocked.isHidden = false
            }
        }
    }
    
    @objc private func unlockedTapped(sender: UIButton) {
        let buttonNumber = sender.tag
        let friendToUnlock = filteredFriends[buttonNumber]

        let alert = UIAlertController(title: "Unblock".localized(), message: "Are you sure you want to unblock this user?".localized(), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Unblock".localized(), style: .destructive, handler: { _ in
            DatabaseMng.shared.unblockFriend(currentID: self.currentUserID, friendID: friendToUnlock.friendID) { success in
                if success {
                    self.getBlockedFriends()
                } else {
                    print ("there was a mistake")
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(alert, animated: true)
    
    }
   
}

extension BlockedViewController: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
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
}


extension BlockedViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = filteredFriends[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockedViewCell.identifier, for: indexPath) as! BlockedViewCell
        
        cell.unblockedButton.addTarget(self, action: #selector(unlockedTapped(sender:)), for: .touchUpInside)
        cell.unblockedButton.tag = indexPath.row
        
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //cell.contentView.backgroundColor = UIColor.black
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
}
