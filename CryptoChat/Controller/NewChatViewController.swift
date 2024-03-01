//
//  NewChatViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/15/21.
//

import UIKit
import JGProgressHUD
import FirebaseAuth

class NewChatViewController: UIViewController {
    
    public var completion: ((SearchResult, String, Bool) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    private var users = [String: String]()
    private var hasFetched = false
    private var results = [SearchResult]()
    private var currentUsername = ""
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for users".localized()
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
        label.text = "No results".localized()
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .done, target: self, action: #selector(didTapDismiss))
        
        searchBar.becomeFirstResponder()
        
    }
    
    @objc private func didTapDismiss() {
        dismiss(animated: true, completion: nil)
    }
}


extension NewChatViewController: UITableViewDelegate, UITableViewDataSource {
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
        
        
        let path = "profile_images/\(targerUserData.friendID)_profile.png"
        StorageMng.shared.downloadURL(for: path, completion: { [weak self] result in
            print (result)
            switch result {
            case .success(let url):
                DatabaseMng.shared.isFriendCheckID(friendID: targerUserData.friendID, currentID: Auth.auth().currentUser!.uid) { isFriend in
                    self!.dismiss(animated: true, completion: { [weak self] in
                        self?.completion?(targerUserData, url.absoluteString, isFriend)
                    })
                }
            case .failure(let error):
                print ("error getting url \(error)")
            }
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}

extension NewChatViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
       
        if text.isNumber && text.count >= 10 {
            self.searchNumbers(query: text)
        } else {
            self.searchUsers(query: text)
        }
    }
    
    func searchNumbers(query: String) {
        DatabaseMng.shared.getAllPrivateUsers(phoneNumberToLook: query, completion: { userFound in
            if userFound != nil {
                if userFound?.usernameFriend != self.currentUsername{
                    self.hasFetched = true
                    //self.users = userFound!
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
            DatabaseMng.shared.getAllUsers (completion: { [weak self] result  in
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

