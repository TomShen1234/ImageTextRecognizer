//
//  MainAboutViewController.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 8/3/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

import UIKit

class MainAboutViewController: AboutViewController {

    @IBOutlet var versionLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        versionLabel?.text = "\(version) (\(buildNumber))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
