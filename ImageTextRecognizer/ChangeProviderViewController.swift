//
//  ChangeProviderViewController.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 4/4/17.
//  Copyright © 2017 Tom and Jerry. All rights reserved.
//

import UIKit

class ChangeProviderViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let current = UserDefaults.standard.object(forKey: "translation_provider") as! String
        let indexForCell = (current == "microsoft") ? 1 : 0
        let indexPath = IndexPath(row: indexForCell, section: 0)
        let cell = tableView(tableView, cellForRowAt: indexPath)
        cell.accessoryType = .checkmark
        
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.textColor = UIColor.white
        cell.contentView.backgroundColor = UIColor.black
        cell.textLabel?.backgroundColor = UIColor.clear
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.backgroundColor = UIColor.clear
        
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
        cell.selectedBackgroundView = view
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.black
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        if row == 0 {
            UserDefaults.standard.set("google", forKey: "translation_provider")
            //print("google")
        } else {
            UserDefaults.standard.set("microsoft", forKey: "translation_provider")
            //print("microsoft")
        }
        
        navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
