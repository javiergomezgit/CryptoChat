//
//  NewChatViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/15/21.
//

import UIKit
import JGProgressHUD
import FirebaseAuth

class SearchFriendViewController: UIViewController {
    
    public var completion: ((SearchResult, String, Bool, String) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    private var users = [String: String]()
    private var hasFetched = false
    private var results = [SearchResult]()
    private var currentUsername = ""
    public var noContactsYet = false
    private var chatID = ""
    private var currentPhotoURL: URL?
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search by username email@domain.com or phone number"
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewChatViewCell.self, forCellReuseIdentifier: NewChatViewCell.identifier)
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No results"
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView(frame: .zero)
        
        noResultsLabel.frame = CGRect(x: view.frame.width/4, y: (view.frame.height - 200)/2, width: view.frame.width/2, height: 200)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        currentUsername = username
        
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        view.backgroundColor = .lightGray
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapDismiss))
        
        searchBar.becomeFirstResponder()
        
        let path = "profile_images/\(Auth.auth().currentUser!.uid)_profile.png"
        StorageDatabaseController.shared.downloadURL(for: path, completion: { result in
            print (result)
            switch result {
            case .success(let url):
                print("loaded")
                self.currentPhotoURL = url
            case .failure(let error):
                print("error \(error)")
            }
        })
    }
    
    @objc private func didTapDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func searchChatID(contactToAddID: String, contactToAddUsername: String, selectedUser: SearchResult){
        let myUserID = Auth.auth().currentUser?.uid
        
        let path = "profile_images/\(contactToAddID)_profile.png"
        StorageDatabaseController.shared.downloadURL(for: path, completion: { result in
            print (result)
            switch result {
            case .success(let url):
                
                UserDatabaseController.shared.searchForChatID(currentUserID: myUserID!, friendID: contactToAddID) { commonChatID in
                    var chatID = commonChatID
                    if commonChatID == nil {
                        chatID = "\(myUserID!)+\(contactToAddID)"
                        
                        UserDatabaseController.shared.addNewContact(friendID: contactToAddID, currectUsername: self.currentUsername, currentID: Auth.auth().currentUser!.uid, currentPhotoURL: self.currentPhotoURL!.absoluteString, chatID: chatID!, friendPhotoURL: url.absoluteString, usernameFriend: contactToAddUsername) { success in
                            self.dismiss(animated: true) {
                                if success == true {
                                    //Convert the serached user to a new contact
                                    let isContact = true
                                    self.completion!(selectedUser, url.absoluteString, isContact, chatID!)
                                } else {
                                    print ("error adding new contact")
                                }
                            }
                        }
                        
                    } else {
                        self.dismiss(animated: true, completion: {
                            self.completion?(selectedUser, url.absoluteString, true, chatID!)
                        })
                    }
                }
                
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
    }
}

extension SearchFriendViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewChatViewCell.identifier, for: indexPath) as! NewChatViewCell
        
        cell.configure(with: model)
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targerUserData = results[indexPath.row]
        print (targerUserData)
        searchChatID(contactToAddID: targerUserData.friendID, contactToAddUsername: targerUserData.usernameFriend, selectedUser: targerUserData)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}

extension SearchFriendViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        
        if text.isEmail {
            self.searchUsersByEmail(query: text.lowercased())
        } else if text.isNumber && text.count >= 10 {
            self.searchNumbers(query: text)
        } else {
            self.searchUsers(query: text.lowercased())
        }
    }
    
    func searchNumbers(query: String) {
        UserDatabaseController.shared.getAllPrivateUsers(phoneNumberToLook: query, completion: { userFound in
            if userFound != nil {
                if userFound?.usernameFriend != self.currentUsername{
                    self.hasFetched = true
                    self.results = [SearchResult(usernameFriend: (userFound?.usernameFriend)!, friendID: (userFound?.friendID)!)]
                }
            } else {
                
            }
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            self.updateUI()
        })
    }
    
    func searchUsers(query: String) {
        if hasFetched {
            filterUsers(with: query)
        } else {
            //MARK: Download url and if is contact once is selected and completion dismissing
            let userID = Auth.auth().currentUser?.uid
            guard let userID else { return }
            if noContactsYet == false {
                UserDatabaseController.shared.getAllUsers(currentUserID: userID, userToSearch: query, completion: { [weak self] result  in
                    switch result {
                    case .success(let userCollection):
                        self?.hasFetched = true
                        self?.users = userCollection
                        self?.filterUsers(with: query)
                    case .failure(let error):
                        print ("error \(error)")
                    }
                })
            }
            else {
                UserDatabaseController.shared.getAllUsersNoContactsYet(currentUserID: userID, userToSearch: query, completion: { [weak self] result in
                    switch result {
                    case .success(let userCollection):
                        self?.hasFetched = true
                        self?.users = userCollection
                        self?.filterUsers(with: query)
                    case .failure(let error):
                        print ("error \(error)")
                    }
                })
            }
        }
    }
    
    func searchUsersByEmail(query: String) {
        if hasFetched {
            filterUsers(with: query)
        } else {
            let userID = Auth.auth().currentUser?.uid
            guard let userID else { return }
            
            UserDatabaseController.shared.searchUserByEmail(currentUserID: userID, emailToSearch: query, completion: { [weak self] userFound in
                if userFound != nil {
                    if userFound?.usernameFriend != self?.currentUsername{
                        self?.hasFetched = true
                        self?.results = [SearchResult(usernameFriend: (userFound?.usernameFriend)!, friendID: (userFound?.friendID)!)]
                    }
                    DispatchQueue.main.async {
                        self?.spinner.dismiss()
                    }
                    self?.updateUI()
                }
            })
        }
    }
    
    func filterUsers(with term: String) {
        guard let currentUsername = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.spinner.dismiss()
        }
        
        var foundResults = [SearchResult]()
        
        for user in self.users {
            let usernameFriend = user.value
            let friendID = user.key
            
            if currentUsername != usernameFriend  {
                if usernameFriend.hasPrefix(term.lowercased()){
                    //Found similar term
                    foundResults.append(SearchResult(usernameFriend: usernameFriend, friendID: friendID))
                }
            }
        }
        
        self.results = foundResults
        updateUI()
    }
    
    func updateUI() {
        if self.results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

