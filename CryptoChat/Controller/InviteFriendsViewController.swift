//
//  InviteFriendsViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 10/12/21.
//

import UIKit
import ContactsUI
import PhoneNumberKit
import MessageUI
import FirebaseAuth
import SwiftUI


class InviteFriendsViewController: UIViewController {
    
    var contactsList = [ContactNumber]()
    var phones = [String]()
    var phonesAsUsers = [String]()
    var foundFriends = [String]()
    var currentUsername = ""
    
    var selectedRows = [IndexPath]()


    private let tableView: UITableView = {
        let table = UITableView()
        table.register(InviteFriendsViewCell.self, forCellReuseIdentifier: InviteFriendsViewCell.identifier)
        return table
    }()
    private let buttonInvite: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(named: "mainOrange")
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.setTitle("Invite", for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(inviteFriendsSMS), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.backgroundColor = .systemBackground
        title = "Invite my contacts"
        
               
        let shareButton = UIButton()
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.addTarget(self, action: #selector(inviteIndividual(sender:)), for: .touchUpInside)
        let shareButtonItem = UIBarButtonItem.init(customView: shareButton)

        navigationItem.rightBarButtonItem = shareButtonItem
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .done, target: self, action: #selector(didTapDismiss))


        let widthButton = view.frame.width * 0.6
        buttonInvite.frame = CGRect(x: (view.frame.width - widthButton) / 2, y: view.frame.height - 80, width: widthButton, height: 50)
        
        tableView.frame = CGRect(x: 0, y: (navigationController?.navigationBar.frame.height)! + 5, width: view.frame.width, height: view.frame.height - (buttonInvite.frame.height + 40 + (navigationController?.navigationBar.frame.height)!))
        tableView.tableFooterView = UIView(frame: .zero)
        
        
        guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
            return
        }
        self.currentUsername = username
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()

    }

    @objc private func didTapDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func inviteIndividual(sender:UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        //let image = UIGraphicsGetImageFromCurrentImageContext()
        guard let image = UIImage(named: "QRCode") else {
            return
        }
        UIGraphicsEndImageContext()
        
        let textToShare = "Get Lock & Key 🔐 to know what privacy is, download it here: "
        let usernameText = "\nMy username is: \(currentUsername)"
        
        if let myWebsite = URL(string: "https://apps.apple.com/us/app/lock-key/id1579179734") {
            let objectsToShare = [textToShare, myWebsite, usernameText, image] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil )
            
            //Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.addSubview(buttonInvite)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        tableView.allowsSelection = false
        
        syncContacts()
    }
    
    @objc func syncContacts() { //-> [String] {
        
        contactsList.removeAll()
        
        var contactsListNoSorted = [ContactNumber]()
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
                
        let keys = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactPhoneNumbersKey,
                        CNContactEmailAddressesKey,
                        CNContactImageDataKey
                ] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            try contactStore.enumerateContacts(with: request){
                    (contact, stop) in
                // Array containing all unified contacts from everywhere
                contacts.append(contact)
                
                for phoneNumber in contact.phoneNumbers {
                    let number = phoneNumber.value
                    let label = phoneNumber.label
                    
//                    if let number = phoneNumber.value as? CNPhoneNumber, let label = phoneNumber.label {
                    let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label ?? "")
                        
                        let phoneNumber = number.stringValue
                        let contactUser = ContactNumber(firstName: contact.givenName, lastName: contact.familyName, profilePhoto: contact.imageData, phoneNumber: phoneNumber, labelNumber: localizedLabel)
                        contactsListNoSorted.append(contactUser)
//                    }
                }
                
                self.contactsList = contactsListNoSorted.sorted {
                    $0.firstName < $1.firstName
                }
            }
            print (contacts)
            self.tableView.reloadData()
        } catch {
            print("unable to fetch contacts")
        }
    }
    
    @objc private func inviteFriendsSMS() {
        
        print (selectedRows)
        
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            
            let urlAppStore = "https://apps.apple.com/us/app/lock-key/id1579179734"
            
            controller.recipients = self.phones
            controller.body = "Get Lock & Key 🔐 to know what privacy is\n\(urlAppStore).\nSearch for my username: \(currentUsername)"
            controller.messageComposeDelegate = self
            
            
            self.present(controller, animated: true) {
                DatabaseMng.shared.searchForIDsWithPhones(phoneNumbers: self.phonesAsUsers) { resultFriends in
                    
                    guard let ids = resultFriends else {
                        return
                    }
                    
                    self.foundFriends = ids
                    print ("Chose these: \(self.phones)")
                }              
            }
        } else {
            present(ShowAlert.alertsCredentials(type:.simpleError, error: "There was an error, try again later"), animated: true)
        }
    }
    
    private func inviteFriendsDB(){
        
        for friendID in self.foundFriends {
            print (friendID)
        }
        self.tableView.reloadData()
    }
}


extension InviteFriendsViewController: UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate {
   
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {

        self.dismiss(animated: true) {
            self.dismiss(animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contactsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = contactsList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: InviteFriendsViewCell.identifier, for: indexPath) as! InviteFriendsViewCell
        
        cell.configure(with: model)
        
        if let buttonCheckmark = cell.contentView.viewWithTag(2) as? UIButton {
            buttonCheckmark.addTarget(self, action: #selector(checkboxClicked(_ :)), for: .touchUpInside)
            buttonCheckmark.isSelected = false
                        
            if selectedRows.contains(indexPath) {
                          buttonCheckmark.isSelected = true
            }
        }
        
                
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
       
        return cell
    }
    
    @objc func checkboxClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        let point = sender.convert(CGPoint.zero, to: tableView)
        guard let indxPath = tableView.indexPathForRow(at: point) else {
            return
        }
        
        let model = contactsList[indxPath.row] //new
        let phoneNumberFull = model.phoneNumber! //new
        
        if selectedRows.contains(indxPath) {
            selectedRows.remove(at: selectedRows.firstIndex(of: indxPath)!)
                if let index = phones.firstIndex(of: model.phoneNumber!) { //new
                    print (index)
                    phones.remove(at: index)
                }
        } else {
            selectedRows.append(indxPath)
            
            //new
                let phoneNumberKit = PhoneNumberKit()
                var phoneNumberNoCountry = "" //to get possible username based on phone number (no country code)
                do {
                    let phoneNumber = phoneNumberFull
                    let phone = try phoneNumberKit.parse(phoneNumber)
                    phoneNumberNoCountry = String(describing: phone.nationalNumber)
//                            let countryCode = String(describing: phone.countryCode)
//                            let fullNumber = String(describing: phone.numberString)

                    self.phonesAsUsers.append(phoneNumberNoCountry)
                } catch {
                    print ("Error while parsing")
                }
            
            phones.append(phoneNumberFull)
        }
        tableView.reloadRows(at: [indxPath], with: .automatic)
    }
    
        
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        let model = contactsList[indexPath.row]
//        let phoneNumberFull = model.phoneNumber!
//
//        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
//            if cell.accessoryType == .checkmark {
//                cell.accessoryType = .none
//
//                if let index = phones.firstIndex(of: model.phoneNumber!) {
//                    print (index)
//                    phones.remove(at: index)
//                }
//
//            } else {
//                cell.accessoryType = .checkmark
//
//                let phoneNumberKit = PhoneNumberKit()
//                var phoneNumberNoCountry = "" //to get possible username based on phone number (no country code)
//                do {
//                    let phoneNumber = phoneNumberFull
//                    let phone = try phoneNumberKit.parse(phoneNumber)
//                    phoneNumberNoCountry = String(describing: phone.nationalNumber)
////                            let countryCode = String(describing: phone.countryCode)
////                            let fullNumber = String(describing: phone.numberString)
//
//                    self.phonesAsUsers.append(phoneNumberNoCountry)
//                } catch {
//                    print ("Error while parsing")
//                }
//
//                phones.append(model.phoneNumber!)
//            }
//        }
//    }
    
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        tableView.cellForRow(at: indexPath)?.accessoryType = .none
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    

    
}

