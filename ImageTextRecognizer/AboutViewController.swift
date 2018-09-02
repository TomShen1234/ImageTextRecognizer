//
//  AboutViewController.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 8/3/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
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
    }

}
