//
//  AutoLockController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 11/1/21.
//

import UIKit

struct SecurityLock {
    let passcodeOff: Bool
    let unlockWithFaceID: Bool
    let autoLockTime: Int
}

class AutoLockController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
   
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var autoLockLabel: UILabel!
    @IBOutlet weak var turnPasscodeSwitch: UISwitch!
    @IBOutlet weak var unlockWithFaceIDSwitch: UISwitch!
    
    var pickerData: [String] = [String]()
    var securityLock: SecurityLock?

    override func viewWillAppear(_ animated: Bool) {
        loadInfo()
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.picker.delegate = self
        self.picker.dataSource = self
        
        pickerData = ["Instant", "1 minute", "2 minutes", "10 minutes", "1 hour", "1 day", "Never"]
        
        let securityLockSaved = UserDefaults.standard.value(forKey: "passcodeOn")
        
        if securityLockSaved == nil {
            UserDefaults.standard.set(true, forKey: "passcodeOn")
            UserDefaults.standard.set(true, forKey: "unlockFaceID")
            UserDefaults.standard.set(0, forKey: "autolockTime")
            self.securityLock = SecurityLock(passcodeOff: false, unlockWithFaceID: true, autoLockTime: 0)
            print ("empty users")
        } else {
            let passcodeOn = UserDefaults.standard.value(forKey: "passcodeOn") as! Bool
            let unlockFaceID = UserDefaults.standard.value(forKey: "unlockFaceID") as! Bool
            let autolockTime  = UserDefaults.standard.value(forKey: "autolockTime") as! Int
            self.securityLock = SecurityLock(passcodeOff: passcodeOn, unlockWithFaceID: unlockFaceID, autoLockTime: autolockTime)
            print ("not empty usersdefault")
        }
    }
    
    private func loadInfo(){
        if securityLock != nil {
            turnPasscodeSwitch.isOn = securityLock!.passcodeOff
            unlockWithFaceIDSwitch.isOn = securityLock!.unlockWithFaceID
            picker.selectRow(securityLock!.autoLockTime, inComponent: 0, animated: true)
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedTime = row
        UserDefaults.standard.set(selectedTime, forKey: "autolockTime")
    }
    
    @IBAction func changePasscodeTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(identifier: "PasscodeViewController") as! PasscodeViewController
        vc.statusOfPasscode = .changePasscode
        vc.completion = { success in
            if success {
                print ("success")
            }
        }
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func turnPasscodeChanged(_ sender: Any) {
        let turnOff = turnPasscodeSwitch.isOn
        UserDefaults.standard.set(turnOff, forKey: "passcodeOn")
    }
    
    @IBAction func unlockFaceIDChanged(_ sender: Any) {
        let unlock = unlockWithFaceIDSwitch.isOn
        UserDefaults.standard.set(unlock, forKey: "unlockFaceID")
    }
    
}
