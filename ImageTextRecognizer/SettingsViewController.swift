//
//  SettingsViewController.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 7/3/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

import UIKit

enum CodeType {
    case tesseract
    case translate
}

class SettingsViewController: UITableViewController {
    @IBOutlet var enableTranslationSwitch: UISwitch!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSwitch), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func updateSwitch() {
        enableTranslationSwitch.isOn = UserDefaults.standard.bool(forKey: "translation_enabled")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //tableView.backgroundColor = UIColor.black
        //tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        //tableView.indicatorStyle = .white
        
        // Remove done button for iPad
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            self.navigationItem.rightBarButtonItem = nil 
        }
        
        updateSwitch()
        
        // Smart Invert
        if #available(iOS 11.0, *) {
            tableView.accessibilityIgnoresInvertColors = true
            navigationController?.view.accessibilityIgnoresInvertColors = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update recognition language table
        var selectedLang = UserDefaults.standard.string(forKey: "tesseract_language_code")!
        var indexToSelect = indexForLanguage(selectedLang)
        var selectedIndexPath = IndexPath(row: indexToSelect, section: 1)
        var tableCell = tableView(tableView, cellForRowAt: selectedIndexPath)
        tableCell.accessoryType = .checkmark
        
        // Update translate language table
        if UserDefaults.standard.bool(forKey: "translation_enabled") == true {
            selectedLang = UserDefaults.standard.string(forKey: "microsoft_language_code")!
            indexToSelect = indexForLanguage(selectedLang)
            selectedIndexPath = IndexPath(row: indexToSelect, section: 2)
            tableCell = tableView(tableView, cellForRowAt: selectedIndexPath)
            tableCell.accessoryType = .checkmark
        }
    }
    
    @IBAction func done(_ sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchValueChanged(_ sender: AnyObject) {
        let switchControl = sender as! UISwitch
        UserDefaults.standard.set(switchControl.isOn, forKey: "translation_enabled")
        
        let notification = Notification(name: settingsViewControllerTranslationToggleDidChangeNotification)
        NotificationCenter.default.post(notification)
        
        if switchControl.isOn == false {
            tableView.reloadData()
        } else {
            tableView.reloadData()
            let selectedLang = UserDefaults.standard.string(forKey: "microsoft_language_code")!
            let indexToSelect = indexForLanguage(selectedLang)
            let selectedIndexPath = IndexPath(row: indexToSelect, section: 2)
            let tableCell = tableView(tableView, cellForRowAt: selectedIndexPath)
            tableCell.accessoryType = .checkmark
        }
    }

    // MARK: - Table view data source and delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath as NSIndexPath).section > 0 && (indexPath as NSIndexPath).section < 3 {
            let totalCells = tableView.numberOfRows(inSection: (indexPath as NSIndexPath).section)
            for i in 0..<totalCells {
                let newIndexPath = IndexPath(row: i, section: (indexPath as NSIndexPath).section)
                let cell = self.tableView(tableView, cellForRowAt: newIndexPath)
                cell.accessoryType = UITableViewCell.AccessoryType.none
            }
            let cell = self.tableView(tableView, cellForRowAt: indexPath)
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
            
            if (indexPath as NSIndexPath).section == 1 {
                let languageCode = processLanguage((indexPath as NSIndexPath).row, codeType: CodeType.tesseract)
                UserDefaults.standard.set(languageCode, forKey: "tesseract_language_code")
            } else if (indexPath as NSIndexPath).section == 2 {
                let languageCode = processLanguage((indexPath as NSIndexPath).row, codeType: CodeType.translate)
                UserDefaults.standard.set(languageCode, forKey: "microsoft_language_code")
                let notification = Notification(name: settingsViewControllerTranslateLanguageChangeNotification)
                NotificationCenter.default.post(notification)
            }
        }
    }
    
    func processLanguage(_ index: Int, codeType: CodeType) -> String {
        let language: String
        switch index {
            case 0: language = (codeType == .tesseract) ? "eng" : "en"
            case 1: language = (codeType == .tesseract) ? "chi_sim" : "zh-CHS"
            case 2: language = (codeType == .tesseract) ? "fra" : "fr"
            case 3: language = (codeType == .tesseract) ? "kor" : "ko"
            case 4: language = (codeType == .tesseract) ? "jpn" : "ja"
            case 5: language = (codeType == .tesseract) ? "deu-frak" : "de"
            case 6: language = (codeType == .tesseract) ? "spa" : "es"
            case 7: language = (codeType == .tesseract) ? "ita" : "it"
            case 8: language = (codeType == .tesseract) ? "ara" : "ar"
            case 9: language = (codeType == .tesseract) ? "ind" : "id"
            case 10: language = (codeType == .tesseract) ? "vie" : "vi"
            case 11: language = (codeType == .tesseract) ? "mal" : "ms"
            case 12: language = (codeType == .tesseract) ? "tha" : "th"
            default: fatalError("Unknown Index")
        }
        return language
    }
    
    func indexForLanguage(_ langCode: String) -> Int {
        let index: Int
        switch langCode {
            case "eng", "en": index = 0
            case "chi_sim", "zh-CHS": index = 1
            case "fra", "fr": index = 2
            case "kor", "ko": index = 3
            case "jpn", "ja": index = 4
            case "deu-frak", "de": index = 5
            case "spa", "es": index = 6
            case "ita", "it": index = 7
            case "ara", "ar": index = 8
            case "ind", "id": index = 9
            case "vie", "vi": index = 10
            case "mal", "ms": index = 11
            case "tha", "th": index = 12
            default: fatalError("Unknown Language Code")
        }
        return index
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            // Use to hide 3rd section when translation is disabled
            if UserDefaults.standard.bool(forKey: "translation_enabled") {
                return super.tableView(tableView, numberOfRowsInSection: section)
            } else {
                return 0
            }
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 {
            // Use to hide 3rd section when translation is disabled
            if UserDefaults.standard.bool(forKey: "translation_enabled") {
                return super.tableView(tableView, heightForHeaderInSection: section)
            } else {
                return 0.1
            }
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 {
            // Use to hide 3rd section when translation is disabled
            if UserDefaults.standard.bool(forKey: "translation_enabled") {
                return super.tableView(tableView, titleForHeaderInSection: section)
            } else {
                return ""
            }
        } else {
            return super.tableView(tableView, titleForHeaderInSection: section)
        }
    }
    
    /*
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 {
            view.tintColor = UIColor.black
            
            let headerView = view as! UITableViewHeaderFooterView
            headerView.textLabel?.textColor = UIColor.white
        } else {
            view.tintColor = UIColor.darkGray
            
            let headerView = view as! UITableViewHeaderFooterView
            headerView.textLabel?.textColor = UIColor.white
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if (indexPath as NSIndexPath).section > 0 {
            cell.textLabel?.textColor = UIColor.white
            cell.contentView.backgroundColor = UIColor.black
            cell.textLabel?.backgroundColor = UIColor.clear
            
            let view = UIView(frame: CGRect.zero)
            view.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
            cell.selectedBackgroundView = view
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.black
    }*/
}
