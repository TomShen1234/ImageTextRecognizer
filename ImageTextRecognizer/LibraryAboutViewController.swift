//
//  LibraryAboutViewController.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 8/3/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

import UIKit

class LibraryAboutViewController: AboutViewController {
    @IBOutlet var tesseractLabel: UILabel?
    @IBOutlet var msTranslatorLabel: UILabel?
    @IBOutlet var googleLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tesseractLabel?.text = "Tesseract OCR iOS:\nThe MIT License (MIT)\nCopyright (c) 2014 Daniele Galiotto"
        
        msTranslatorLabel?.text = "Translation service uses Microsoft Translator API. Under Microsoft Cognitive Services Terms."
        
        googleLabel?.text = "Translation"
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
