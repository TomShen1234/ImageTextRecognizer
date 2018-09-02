//
//  ViewController.swift
//  ImageTextRecognizer
//
//  Created by Tom Shen on 5/14/16.
//  Copyright © 2016 Tom and Jerry. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation
import ImageIO

let FrameViewTag: Int = 1000
let NavigationBarTag: Int = 1001
let ToolBarTag: Int = 1002

func degreesToRadian(_ degrees: CGFloat) -> CGFloat {
    return degrees * CGFloat.pi / 180
}

class ViewController: UIViewController {
    var captureSession = AVCaptureSession()
    var photoOutput: AVCapturePhotoOutput!
    var captureDevice: AVCaptureDevice?
    var telephotoCaptureDevice: AVCaptureDevice?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet var telephotoButton: UIBarButtonItem!
    @IBOutlet var mainNavigationItem: UINavigationItem!
    
    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var resultTextView: UITextView!
    @IBOutlet var translationResultTextView: UITextView!
    @IBOutlet var recognizeButton: UIBarButtonItem!
    @IBOutlet var resetFrameButton: UIBarButtonItem!
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var loadingLabel: UILabel!
    
    @IBOutlet var flashButton: UIBarButtonItem!
    
    var flashOn: Bool = false
    
    var loaded = false
    
    var loading = false
    
    // Fix a glitch where frame view is added twice after camera failed to load on first try
    var frameViewAdded = false
    
    let recognitionQueue = OperationQueue()
    
    var noTextFound: Bool?
    
    var wideangle: Bool = true
    
    // Landscape tweaking variables
    var landscapeCameraViewBounds: CGRect? = nil
    var landscapeCameraPreviewLayerBounds: CGRect? = nil
    var portraitCameraViewBounds: CGRect? = nil
    var portraitCameraPreviewLayerBounds: CGRect? = nil
    var startedInLandscape: Bool = false
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        recognizeButton.isEnabled = false
        resetFrameButton.isEnabled = false
        
        flashButton.image = UIImage(named: "NoFlash")
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidResume), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(enableTranslationToggled), name: settingsViewControllerTranslationToggleDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(translationLanguageChanged), name: settingsViewControllerTranslateLanguageChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(captureSessionInterruptionBegan(_:)), name: Notification.Name.AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(captureSessionInterruptionDidEnd), name: Notification.Name.AVCaptureSessionInterruptionEnded, object: nil)
        
        resultTextView.layer.borderColor = UIColor(red: 1, green: 190.0/255.0, blue: 0, alpha: 1).cgColor
        resultTextView.layer.borderWidth = 3.0
        
        translationResultTextView.layer.borderColor = UIColor.blue.cgColor
        translationResultTextView.layer.borderWidth = 3.0
        
        noTextFound = false
        
        setupCaptureSession()
        
        // Smart Invert
        if #available(iOS 11.0, *) {
            view.accessibilityIgnoresInvertColors = true
            cameraView.accessibilityIgnoresInvertColors = true
            navigationController?.view.accessibilityIgnoresInvertColors = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if IOS_SIMULATOR
            // Don't begin session if on simulator
        #else
            loadCamera()
        #endif
    }
    
    func setupCaptureSession() {
        #if IOS_SIMULATOR
            // Disable the recognize button and don't setup camera if on simulator
            recognizeButton.isEnabled = false
        #else
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            telephotoCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInTelephotoCamera, for: AVMediaType.video, position: .back)
            
            //let identifier = UIDevice.current.identifier()
            //if identifier != "iPhone9,2" && identifier != "iPhone9,4" {
            if telephotoCaptureDevice == nil {
                var items = self.mainNavigationItem.leftBarButtonItems
                let index = items?.index(of: self.telephotoButton)
                items?.remove(at: index!)
                self.mainNavigationItem.leftBarButtonItems = items
            } else {
                telephotoButton.action = #selector(telephotoPressed)
            }
            
            if (self.captureDevice?.hasTorch)! == false {
                var items = self.mainNavigationItem.leftBarButtonItems
                let index = items?.index(of: self.flashButton)
                items?.remove(at: index!)
                self.mainNavigationItem.leftBarButtonItems = items
            }
            
            // Test Code
            //cameraView.backgroundColor = UIColor.blue
            
            self.photoOutput = AVCapturePhotoOutput()
            
            self.captureSession.addOutput(self.photoOutput)
            
            do {
                try self.captureSession.addInput(AVCaptureDeviceInput(device: self.captureDevice!))
            } catch let error {
                print("\(error)")
            }
        #endif
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSettings" {
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                let destinationController = segue.destination
                destinationController.popoverPresentationController?.backgroundColor = UIColor(red: 20/0xFF, green: 20/0xFF, blue: 20/0xFF, alpha: 1.0)
            }
        }
    }
    
    @objc func enableTranslationToggled() {
        let translationEnabled = UserDefaults.standard.bool(forKey: "translation_enabled")
        if translationEnabled {
            if resultTextView.superview != nil {
                if !noTextFound! {
                    translationResultTextView.frame = self.resultTextView.frame
                    translationResultTextView.frame.origin.y += self.resultTextView.frame.size.height
                    translationResultTextView.text = NSLocalizedString("Translating...", comment: "Translating Text")
                    view.addSubview(translationResultTextView)
                    translateText(resultTextView.text)
                }
            }
        } else {
            translationResultTextView.removeFromSuperview()
        }
    }
    
    @objc func translationLanguageChanged() {
        let translationEnabled = UserDefaults.standard.bool(forKey: "translation_enabled")
        if translationEnabled {
            if resultTextView.superview != nil {
                if !noTextFound! {
                    // MARK: to decide whether to add this or not
                    //translationResultTextView.text = "Translating..."
                    //translateText(resultTextView.text)
                }
            }
        }
    }
    
    // MARK: Camera Settings
    
    @objc func telephotoPressed() {
        UISelectionFeedbackGenerator().selectionChanged()
        
        // Turn off flash
        telephotoButton.isEnabled = false
        if flashOn {
            toggleFlash(self)
        }
        /*
        let blurEffect = UIBlurEffect(style: .regular)
        let visualEffectView = UIVisualEffectView()
        visualEffectView.frame = cameraView.bounds
        */
        // Take a snapshot so that the view won't be black
        let snapshotView = cameraView.snapshotView(afterScreenUpdates: true)!
        cameraView.addSubview(snapshotView)
        
        spinner.startAnimating()
        /*
        cameraView.addSubview(visualEffectView)
        
        UIView.animate(withDuration: 0.6) {
            visualEffectView.effect = blurEffect
        }
        
        // Delayed so that the blur can be added
        delay(0.01) {
            self.toggleTelephoto()
            UIView.animate(withDuration: 0.7, animations: {
                visualEffectView.effect = nil
            }, completion: { _ in
                visualEffectView.removeFromSuperview()
            })
            delay(0.3) {
                UIView.animate(withDuration: 0.2, animations: {
                    snapshotView.alpha = 0
                }, completion: { _ in
                    snapshotView.removeFromSuperview()
                    
                    // Re-enable the telephoto button after this animation
                    self.telephotoButton.isEnabled = true
                })
            }
        }
 */
        toggleTelephoto()
        UIView.animate(withDuration: 0.7, animations: {
            snapshotView.alpha = 0
        }, completion: { _ in
            snapshotView.removeFromSuperview()
            
            // Re-enable the telephoto button after this animation
            self.telephotoButton.isEnabled = true
            
            self.spinner.stopAnimating()
        })
    }
    
    func toggleTelephoto() {
        captureSession.beginConfiguration()
        if wideangle {
            telephotoButton.title = "2x"
            let currentInput = captureSession.inputs[0]
            captureSession.removeInput(currentInput )
            
            let newInput = try! AVCaptureDeviceInput(device: telephotoCaptureDevice!)
            captureSession.addInput(newInput)
        } else {
            telephotoButton.title = "1x"
            let currentInput = captureSession.inputs[0]
            captureSession.removeInput(currentInput )
            
            let newInput = try! AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(newInput)
        }
        wideangle = !wideangle
        
        captureSession.commitConfiguration()
    }
    
    @objc func applicationDidResume() {
        #if IOS_SIMULATOR
        // Skip this method on simulator
        #else
            if loaded == false {
                cameraView.gestureRecognizers = []
                loadCamera()
            }
            
            if captureDevice?.isTorchModeSupported(AVCaptureDevice.TorchMode.on) == true {
                flashOn = false
                flashButton.image = UIImage(named: "NoFlash")
                let success = toggleTorch(false)
                if !success {
                    flashOn = true
                    flashButton.image = UIImage(named: "Flash")
                }
            }
        #endif
    }
    
    func loadCamera() {
        if loaded == false || loading == false {
            loading = true
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                DispatchQueue.main.async(execute: {
                    self.captureSession.sessionPreset = AVCaptureSession.Preset.high
                    if(self.captureDevice != nil){
                        if granted {
                            self.beginSession()
                        } else {
                            self.loadingLabel.text = NSLocalizedString("CAMEA_PERMISSION_ERROR", comment: "Camera Permission Error")
                            self.loadingLabel.sizeToFit()
                            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openSettings))
                            tapRecognizer.numberOfTapsRequired = 1
                            self.cameraView.addGestureRecognizer(tapRecognizer)
                            
                            // Haptics for iPhone 7 and 7 Plus
                            let hapticGenerator = UINotificationFeedbackGenerator()
                            hapticGenerator.notificationOccurred(.error)
                            
                            self.flashButton.isEnabled = false
                            self.telephotoButton.isEnabled = false
                        }
                    }
                })
            })
        }
    }
    
    @objc func openSettings() {
        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    func beginSession() {
        if loaded == false || loading == false  {
            spinner.startAnimating()
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                DispatchQueue.main.async {
                    // MARK: Initialize camera and rotation
                    // Resize camera view for iPads so camera preview fills up screen
                    if UI_USER_INTERFACE_IDIOM() == .pad {
                        let currentOrientation = UIApplication.shared.statusBarOrientation
                        
                        if currentOrientation == .portrait {
                            self.cameraView.bounds.size.height *= 1.45
                        } else {
                            self.cameraView.bounds.size.width *= 1.45
                        }
                        
                        // Set video orientation for iPad
                        let videoOrientation = AVCaptureVideoOrientation(ui: currentOrientation)
                        self.cameraPreviewLayer.connection?.videoOrientation = videoOrientation
                    }
                    
                    self.cameraPreviewLayer.frame = self.cameraView.layer.frame
                    
                    // Slightly lower camera preview layer on iPhone X
                    let screenBounds = UIScreen.main.bounds
                    if screenBounds.width == 1125 / 3 || screenBounds.height == 2436 / 3 {
                        self.cameraPreviewLayer.frame.origin.y += 15
                    }
                    
                    self.cameraView.layer.addSublayer(self.cameraPreviewLayer)
                    self.captureSession.startRunning()
                    
                    self.loadingLabel.removeFromSuperview()
                    self.addFrameView()
                    
                    self.recognizeButton.isEnabled = true
                    self.resetFrameButton.isEnabled = true
                    self.spinner.stopAnimating()
                    
                    // Haptics for iPhone 7 and later
                    let hapticGenerator = UINotificationFeedbackGenerator()
                    hapticGenerator.notificationOccurred(.success)
                    
                    // Test Code
                    //self.cameraPreviewLayer.backgroundColor = UIColor.blue.cgColor
                    
                    // Save orientation state for iPad
                    if UI_USER_INTERFACE_IDIOM() == .pad {
                        let currentOrientation = UIApplication.shared.statusBarOrientation
                        
                        if currentOrientation == .landscapeLeft || currentOrientation == .landscapeRight {
                            // Started in landscape
                            self.startedInLandscape = true
                            self.landscapeCameraViewBounds = self.cameraView.bounds
                            self.landscapeCameraPreviewLayerBounds = self.cameraPreviewLayer.bounds
                        } else {
                            // Started in portrait
                            self.portraitCameraViewBounds = self.cameraView.bounds
                            self.portraitCameraPreviewLayerBounds = self.cameraPreviewLayer.bounds
                        }
                    }
                    
                    // Set loaded to true
                    self.loaded = true
                }
            }
        }
    }
    
    func toggleTorch(_ on: Bool) -> Bool {
        captureSession.beginConfiguration()
        let currentCaptureDevice = wideangle ? captureDevice : telephotoCaptureDevice
        do {
            try currentCaptureDevice?.lockForConfiguration()
        } catch {
            return false
        }
        currentCaptureDevice?.torchMode = (on == true) ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
        currentCaptureDevice?.unlockForConfiguration()
        captureSession.commitConfiguration()
        return true
    }

    func addFrameView() {
        guard frameViewAdded == false else { return }
        frameViewAdded = true
        
        let frameView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 150, height: 55)))
        frameView.center = cameraView.center
        frameView.backgroundColor = UIColor.clear
        frameView.layer.borderColor = UIColor.white.cgColor
        frameView.layer.borderWidth = 5.0
        frameView.layer.cornerRadius = 15.0
        frameView.tag = FrameViewTag
        view.addSubview(frameView)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panRecognizer.maximumNumberOfTouches = 1
        frameView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        frameView.addGestureRecognizer(pinchRecognizer)
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        // Dismiss keyboard
        resultTextView.resignFirstResponder()
        
        let translation = sender.translation(in: view)
        sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: view)
        
        let frameView = view.viewWithTag(FrameViewTag)!
        frameView.layer.borderColor = UIColor.white.cgColor
        frameView.layer.borderWidth = 5.0
        
        self.resultTextView.center.x = frameView.center.x
        self.resultTextView.frame.origin.y = frameView.frame.origin.y + frameView.frame.size.height
        self.translationResultTextView.frame = self.resultTextView.frame
        self.translationResultTextView.frame.origin.y += self.resultTextView.frame.size.height
    }
    
    @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
        // Dismiss keyboard
        resultTextView.resignFirstResponder()
        
        guard sender.state == .began || sender.state == .changed else {
            return
        }
        
        guard sender.numberOfTouches > 1 else {
            return
        }
    
        let frameView = view.viewWithTag(FrameViewTag)!
        let locationOne: CGPoint = sender.location(ofTouch: 0, in: view)
        let locationTwo: CGPoint = sender.location(ofTouch: 1, in: view)
        let slope: Double
        
        if locationOne.x == locationTwo.x {
            slope = 1000.0
        } else if locationOne.y == locationTwo.y {
            slope = 0.0
        } else {
            slope = Double(locationTwo.y - locationOne.y) / Double(locationTwo.x - locationOne.x)
        }
        
        let absSlope = abs(slope)
        
        if absSlope < 0.5 {
            // Horizontal Pinch
            frameView.bounds.size.width *= sender.scale
        } else if absSlope > 1.7 {
            // Vertical Pinch
            frameView.bounds.size.height *= sender.scale
        } else {
            // Diagonal Pinch
            sender.view!.frame.size = CGSize(width: sender.view!.frame.size.width * sender.scale, height: sender.view!.frame.size.height * sender.scale)
        }
        sender.scale = 1
        
        if frameView.bounds.size.width > 250 {
            frameView.bounds.size.width = 250
        }
        
        if frameView.bounds.size.height > 250 {
            frameView.bounds.size.height = 250
        }
        
//        print("\(frameView.bounds.size.width)")
//        print("\(frameView.bounds.size.height)")
        
        self.resultTextView.center.x = frameView.center.x
        self.resultTextView.frame.origin.y = frameView.frame.origin.y + frameView.frame.size.height
        self.translationResultTextView.frame = self.resultTextView.frame
        self.translationResultTextView.frame.origin.y += self.resultTextView.frame.size.height
    }

    @IBAction func resetFrame(_ sender: AnyObject) {
        UIView.animate(withDuration: 1, animations: {
            let frameView = self.view.viewWithTag(FrameViewTag)!
            frameView.frame.size = CGSize(width: 150, height: 55)
            frameView.center = self.cameraView.center
            frameView.layer.borderColor = UIColor.white.cgColor
            frameView.layer.borderWidth = 5.0
            
            self.resultTextView.alpha = 0
            self.translationResultTextView.alpha = 0
        }, completion: { (finished) in
            self.resultTextView.removeFromSuperview()
            self.translationResultTextView.removeFromSuperview()
            self.resultTextView.alpha = 1
            self.translationResultTextView.alpha = 1
        })
    }
    
    #if IOS_SIMULATOR
    // We will ignore this if built for simulator
    #else
    @IBAction func recognizeItem(_ sender: AnyObject) {
        UISelectionFeedbackGenerator().selectionChanged()
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func recognizeImage(_ image: UIImage) {
        spinner.startAnimating()
        resetFrameButton.isEnabled = false
        recognizeButton.isEnabled = false
        settingsButton.isEnabled = false
        
        translationResultTextView.removeFromSuperview()
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let tesseractLang = UserDefaults.standard.string(forKey: "tesseract_language_code")!
            
            //print(tesseractLang)
            
            let engineMode: G8OCREngineMode
            
            switch tesseractLang {
            case "ara":
                engineMode = .cubeOnly
            case "eng", "fra", "ita", "spa":
                engineMode = .tesseractCubeCombined
            default:
                engineMode = .tesseractOnly
            }
            
            let tesseract = G8Tesseract(language: tesseractLang, engineMode: engineMode)
            tesseract?.pageSegmentationMode = .auto
            tesseract?.maximumRecognitionTime = 60.0
            tesseract?.image = image.grayscale()
            tesseract?.recognize()
            DispatchQueue.main.async {
                let resultText = tesseract?.recognizedText
                
                // Remove newlines and spaces from string for comparison below
                let trimmedString = resultText!.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                
                if trimmedString.count == 0 {
                    self.resultTextView.text = "No texts found."
                    self.noTextFound = true
                    
                    // Haptics for iPhone 7 and 7 Plus
                    let hapticGenerator = UINotificationFeedbackGenerator()
                    hapticGenerator.notificationOccurred(.error)
                } else {
                    // Haptics for iPhone 7 and 7 Plus
                    let hapticGenerator = UINotificationFeedbackGenerator()
                    hapticGenerator.notificationOccurred(.success)
                    self.resultTextView.text = trimmedString
                }
                
                let translationEnabled = UserDefaults.standard.bool(forKey: "translation_enabled")
                if translationEnabled == true {
                    if trimmedString.count > 0 {
                        self.noTextFound = false
                        self.resultTextView.isEditable = true
                        self.translationResultTextView.frame = self.resultTextView.frame
                        self.translationResultTextView.frame.origin.y += self.resultTextView.frame.size.height
                        self.translationResultTextView.text = NSLocalizedString("Translating...", comment: "Translating Text")
                        self.view.addSubview(self.translationResultTextView)
                        self.translateText(trimmedString)
                        
                    } else {
                        self.resultTextView.isEditable = true
                        self.spinner.stopAnimating()
                        self.resetFrameButton.isEnabled = true
                        self.recognizeButton.isEnabled = true
                        self.settingsButton.isEnabled = true
                    }
                } else {
                    self.spinner.stopAnimating()
                    self.resetFrameButton.isEnabled = true
                    self.recognizeButton.isEnabled = true
                    self.settingsButton.isEnabled = true
                }
            }
        }
    }
    #endif
    
    func translateText(_ text: String) {
        if (text as NSString).length <= 50 {
            let provider = UserDefaults.standard.object(forKey: "translation_provider") as! String
            if provider == "microsoft" {
                //translateUsingMicrosoft(text)
                translationResultTextView.text = "Microsoft Translate removed from app. Google translate is turned on automatically... Translating again in 5 seconds..."
                UserDefaults.standard.set("google", forKey: "translation_provider")
                delay(5) {
                    self.translateWithGoogle(text)
                }
            } else {
                translateWithGoogle(text)
            }
        } else {
            translationResultTextView.text = "Text to translate can not be over 50 characters"
            self.resultTextView.isEditable = true
            self.spinner.stopAnimating()
            self.resetFrameButton.isEnabled = true
            self.recognizeButton.isEnabled = true
            self.settingsButton.isEnabled = true
            // Haptics for iPhone 7 and 7 Plus
            let hapticGenerator = UINotificationFeedbackGenerator()
            hapticGenerator.notificationOccurred(.warning)
        }
    }
    
    func translateWithGoogle(_ text: String) {
        let customAllowedSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnioqrstuvwxyz0123456789_!*'();:@$,#[]+=/")
        
        let input = text.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
        
        let fromLangCodeTesseract = UserDefaults.standard.string(forKey: "tesseract_language_code")
        let fromLangCode = self.tesseractLangCodeToGoogleTranslatorLangCode(fromLangCodeTesseract)
        
        let toLangCode = UserDefaults.standard.string(forKey: "microsoft_language_code")
        let googleToLangCode = microsoftLangCodeToGoogle(toLangCode)
        
        //let googleAPIURL = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(fromLangCode)&tl=\(googleToLangCode)&dt=t&q=\(input!)"
        
        let googleAPIURL = "https://translate.googleapis.com/translate_a/single"
        //let googleAPIURL = "https://192.168.100.1/translate_a/single"
        let params = "client=gtx&sl=\(fromLangCode)&tl=\(googleToLangCode)&dt=t&q=\(input!)&ie=UTF-8&oe=UTF-8"
        
        //print(googleAPIURL+"?"+params)
        
        let requestURL = URL(string: googleAPIURL)!
        
        //print(requestURL)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        var request = URLRequest(url: requestURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        //request.addValue("text/json; charset=utf-8", forHTTPHeaderField:"Content-Type")
        
        request.httpMethod = "POST"
        
        let data = params.data(using: .utf8)
        request.httpBody = data
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("FAIL 25: \(String(describing: error))")
                let errorInfo = ["error": (error?.localizedDescription)!]
                self.networkFail(25, errorInfo)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("FAIL 26: Unknown Error")
                self.networkFail(26)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("FAIL 27: Unexpected status code: \(httpResponse.statusCode)")
                self.networkFail(27)
                return
            }
            
            guard let result = data else {
                print("FAIL 28: No token data")
                self.networkFail(28)
                return
            }
            
            DispatchQueue.main.async {
                let dataString = String(data: result, encoding: String.Encoding.utf8)
                print(dataString!)
                
                let serializedData: Any?
                do {
                    serializedData = try JSONSerialization.jsonObject(with: result, options: .mutableContainers)
                } catch {
                    print("FAIL 29: Can not serialize data")
                    self.networkFail(29)
                    return
                }
                
                let serializedArray1: [Any] = serializedData as! [Any]
                let serializedArray2: [Any] = serializedArray1[0] as! [Any]
                
                var resultString: String = ""
                
                for textArray in serializedArray2 {
                    let string = (textArray as! [Any])[0] as! String
                    resultString += string
                }
                
                self.finishTranslation(resultString)
            }
        }
        
        task.resume()

//        let test = try! String(contentsOf: requestURL
//        print(test)
    }
    
    func translateUsingMicrosoft(_ text: String) {
        var microsoftClientID = "TextRecognizer"
        var microsoftClientSecret = "SA8y8Ffz3/k78lowlYf9u6TNEHmZdUhTcuFJQe1IZUg="
        var microsoftGrantType = "client_credentials"
        var scope = "http://api.microsofttranslator.com"
        let customAllowedSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnioqrstuvwxyz0123456789_!*'();:@$,#[]+=/").inverted
        
        microsoftClientID = microsoftClientID.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
        microsoftClientSecret = microsoftClientSecret.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
        microsoftGrantType = microsoftGrantType.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
        scope = scope.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
        
        let authHeader = "client_id=\(microsoftClientID)&client_secret=\(microsoftClientSecret)&grant_type=\(microsoftGrantType)&scope=\(scope)"
        
        var request = URLRequest(url: URL(string: "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13")!, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        let data = authHeader.data(using: String.Encoding.utf8)
        request.httpBody = data
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                print("FAIL 1: \(String(describing: error))")
                let errorInfo = ["error": (error?.localizedDescription)!]
                self.networkFail(1, errorInfo)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("FAIL 2: Unknown Error")
                self.networkFail(2)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("FAIL 3: Unexpected status code: \(httpResponse.statusCode)")
                self.networkFail(3)
                return
            }
            
            guard let token = data else {
                print("FAIL 4: No token data")
                self.networkFail(4)
                return
            }
            
            DispatchQueue.main.async {
                let serializedData: AnyObject?
                do {
                    serializedData = try JSONSerialization.jsonObject(with: token, options: .mutableContainers) as AnyObject
                } catch {
                    print("FAIL 5: Can not serialize token data")
                    self.networkFail(5)
                    return
                }
                
                guard serializedData is NSDictionary else {
                    print("FAIL 6: Serialized data is not dictionary")
                    self.networkFail(6)
                    return
                }
                
                let dictionary = serializedData as! NSDictionary
                
                let accessToken = dictionary["access_token"] as! String
                let finalToken = "Bearer " + accessToken
                
                let fromLangCodeTesseract = UserDefaults.standard.string(forKey: "tesseract_language_code")
                let fromLangCodeMicrosoft = self.tesseractLangCodeToMicrosoftTranslatorLangCode(fromLangCodeTesseract)
                
                let toLangCode = UserDefaults.standard.string(forKey: "microsoft_language_code")
                
                let customAllowedSet: CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnioqrstuvwxyz0123456789_!*'();:@$,#[]+=/")
                
                let textEscaped = text.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
                
                let escapedFromLangCode = fromLangCodeMicrosoft.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
                let escapedToLangCode = toLangCode!.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
                
                let URLString = "http://api.microsofttranslator.com/v2/Http.svc/Translate?text=\(textEscaped!)&from=\(escapedFromLangCode!)&to=\(escapedToLangCode!)"
                var request = URLRequest(url: URL(string: URLString)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
                request.addValue(finalToken, forHTTPHeaderField: "Authorization")
                
                let session = URLSession.shared
                let task = session.dataTask(with: request, completionHandler: { data, response, error in
                    guard error == nil else {
                        print("FAIL 7: \(String(describing: error)) (2)")
                        let errorInfo = ["error": (error?.localizedDescription)!]
                        self.networkFail(7, errorInfo)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("FAIL 8: Unknown Error (2)")
                        self.networkFail(8)
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        print("FAIL 9: Unexpected status code: \(httpResponse.statusCode)")
                        self.networkFail(9)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                        let resultString = result.strippingMarkers()
                        self.finishTranslation(resultString!)
                    }
                })
                task.resume()
            }
        })
        task.resume()
    }
    
    func finishTranslation(_ result: String) {
        self.translationResultTextView.text = result
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.spinner.stopAnimating()
        self.resetFrameButton.isEnabled = true
        self.recognizeButton.isEnabled = true
        self.settingsButton.isEnabled = true
        
        // Haptics for iPhone 7 and 7 Plus
        let hapticGenerator = UINotificationFeedbackGenerator()
        hapticGenerator.notificationOccurred(.success)
    }
    
    func networkFail(_ code: Int!, _ info: [String: String]? = nil) {
        DispatchQueue.main.async(execute: {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            // Haptics for iPhone 7 and 7 Plus
            let hapticGenerator = UINotificationFeedbackGenerator()
            hapticGenerator.notificationOccurred(.error)
            
            let messageBase = NSLocalizedString("Can not translate.", comment: "Translation Error Message: Can not translate.")
            
            var message: String! = ""
            
            switch code {
            case 1, 7:
                let errorString = (info?["error"])!
                message = "\(errorString)"
            case 2, 3, 5, 6, 8, 9:
                message = NSLocalizedString("Internal error.", comment: "Translation Error Message: Internal Error.")
            default:
                message = ""
            }
            
            self.translationResultTextView.text = "\(messageBase) \(message!) (\(code!))"
            
            self.spinner.stopAnimating()
            self.resetFrameButton.isEnabled = true
            self.recognizeButton.isEnabled = true
            self.settingsButton.isEnabled = true
        })
    }
    
    @IBAction func toggleFlash(_ sender: AnyObject) {
        UISelectionFeedbackGenerator().selectionChanged()
        if flashOn {
            flashOn = false
            flashButton.image = UIImage(named: "NoFlash")
            let success = toggleTorch(false)
            if !success {
                flashOn = true
                flashButton.image = UIImage(named: "Flash")
            }
        } else {
            flashOn = true
            flashButton.image = UIImage(named: "Flash")
            let success = toggleTorch(true)
            if !success {
                flashOn = false
                flashButton.image = UIImage(named: "NoFlash")
            }
        }
    }
    
    // MARK: Rotation (Not used in this version)
    // TODO: Fix landscape
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return .all
        } else {
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    // MARK: Rotation
    var rotationSnapshotView: UIView = UIView()
    var rotationVEView = UIVisualEffectView()
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            //captureSession.stopRunning()
            
            let blurEffect = UIBlurEffect(style: .regular)
            rotationVEView = UIVisualEffectView()
            rotationVEView.frame = cameraView.bounds
            
            // Take a snapshot so that the view won't be black
            rotationSnapshotView = cameraView.snapshotView(afterScreenUpdates: true)!
            cameraView.addSubview(rotationSnapshotView)
            
            cameraView.addSubview(rotationVEView)
            
            UIView.animate(withDuration: 0.2) {
                self.rotationVEView.effect = blurEffect
                self.rotationSnapshotView.bounds.size *= 2
                self.rotationVEView.bounds.size *= 2
            }
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            //view.viewWithTag(FrameViewTag)?.removeFromSuperview()
            resetFrame(self)
            
            let newOrientation = AVCaptureVideoOrientation(ui: UIApplication.shared.statusBarOrientation)
            cameraPreviewLayer?.connection?.videoOrientation = newOrientation
            for connection in photoOutput.connections {
                connection.videoOrientation = newOrientation
            }
            self.cameraPreviewLayer.frame = self.cameraView.layer.frame
            
            cameraView.backgroundColor = .red
            
            rotationSnapshotView.removeFromSuperview()
            UIView.animate(withDuration: 0.1, animations: {
                self.rotationVEView.effect = nil
            }, completion: { _ in
                self.rotationVEView.removeFromSuperview()
            })
            
            /*
            //captureSession = AVCaptureSession()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                DispatchQueue.main.async(execute: {
                    //self.captureSession.sessionPreset = AVCaptureSession.Preset.high
                    if(self.captureDevice != nil){
                        if granted {
                            self.loaded = false
                            self.loading = false
                            self.beginSession()
                        }
                    }
                })
            })
            */
            // Test Code
            //cameraPreviewLayer.backgroundColor = UIColor.red.cgColor
        }
    }
    
    @objc func captureSessionInterruptionBegan(_ notification: NSNotification) {
        // Reusing rotationVEView here
        let blurEffect = UIBlurEffect(style: .regular)
        rotationVEView = UIVisualEffectView()
        rotationVEView.frame = cameraView.bounds
        
        recognizeButton.isEnabled = false
        resetFrameButton.isEnabled = false
        flashButton.isEnabled = false
        
        let frameView = self.view.viewWithTag(FrameViewTag)
        
        frameView?.gestureRecognizers = []
        
        cameraView.addSubview(rotationVEView)
        UIView.animate(withDuration: 0.3) {
            self.rotationVEView.effect = blurEffect
        }
    }
    
    @objc func captureSessionInterruptionDidEnd() {
        UIView.animate(withDuration: 0.1, animations: {
            self.rotationVEView.effect = nil
        }, completion: { _ in
            self.rotationVEView.removeFromSuperview()
            
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
            panRecognizer.maximumNumberOfTouches = 1
            
            let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
            
            let frameView = self.view.viewWithTag(FrameViewTag)
            frameView?.gestureRecognizers = [panRecognizer, pinchRecognizer]
            
            self.recognizeButton.isEnabled = true
            self.resetFrameButton.isEnabled = true
            self.flashButton.isEnabled = true
        })
    }
}

extension ViewController: UIBarPositioningDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}

// Extension for exporting translation code
extension ViewController {
    func tesseractLangCodeToMicrosoftTranslatorLangCode(_ tesseractLangCode: String!) -> String {
        let result: String
        switch tesseractLangCode {
            case "eng": result = "en"
            case "chi_sim": result = "zh-CHS"
            case "fra": result = "fr"
            case "kor": result = "ko"
            case "jpn": result = "ja"
            case "deu-frak": result = "de"
            case "spa": result = "es"
            case "ita": result = "it"
            case "ara": result = "ar"
            case "ind": result = "id"
            case "vie": result = "vi"
            case "mal": result = "ms"
            case "tha": result = "th"
            default: fatalError("Unknown Tesseract Language Code")
        }
        return result
    }
    
    func tesseractLangCodeToGoogleTranslatorLangCode(_ tesseractLangCode: String!) -> String {
        let result: String
        switch tesseractLangCode {
        case "eng": result = "en"
        case "chi_sim": result = "zh-CN"
        case "fra": result = "fr"
        case "kor": result = "ko"
        case "jpn": result = "ja"
        case "deu-frak": result = "de"
        case "spa": result = "es"
        case "ita": result = "it"
        case "ara": result = "ar"
        case "ind": result = "id"
        case "vie": result = "vi"
        case "mal": result = "ms"
        case "tha": result = "th"
        default: fatalError("Unknown Tesseract Language Code")
        }
        return result
    }
    
    func microsoftLangCodeToGoogle(_ inputCode: String!) -> String {
        if (inputCode == "zh-CHS") {
            return "zh-CN"
        }
        return inputCode
    }
}

extension UIImage {
    func croppedImage(_ rect: CGRect) -> UIImage {
        let origin = CGPoint(x: -rect.origin.x, y: -rect.origin.y)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        draw(at: origin)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func drawPathWithRect(_ rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(at: CGPoint.zero)
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(25)
        context?.stroke(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func scale(_ maxDimension: CGFloat) -> UIImage {
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if size.width > size.height {
            scaleFactor = size.height / size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = size.width / size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    
}

#if IOS_SIMULATOR
#else
extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            
            let frameView = self.view.viewWithTag(FrameViewTag)!
            self.resultTextView.center.x = frameView.center.x
            self.resultTextView.frame.origin.y = frameView.frame.origin.y + frameView.frame.size.height
            self.view.addSubview(self.resultTextView)
            self.resultTextView.text = "Can not take image: \(error.localizedDescription)"
        } else {
            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                let resultImage = UIImage(data: dataImage)!
                
                let selectedFrame = self.view.viewWithTag(FrameViewTag)!.frame
                
                let viewSize = self.view.bounds.size
                let imageSize = resultImage.size
                
                let dimensionChange = CGSize(width: imageSize.width / viewSize.width, height: imageSize.height / viewSize.height)
                // TODO: Fix Crop Frame for landscape
                let cropFrame = CGRect(x: selectedFrame.origin.x * dimensionChange.width, y: selectedFrame.origin.y * dimensionChange.height, width: selectedFrame.width * dimensionChange.width, height: selectedFrame.height * dimensionChange.height)
                
                let croppedImage = resultImage.croppedImage(cropFrame)
                
                DispatchQueue.main.async {
                    self.resultTextView.removeFromSuperview()
                    
                    self.resultTextView.isEditable = false
                    
                    let frameView = self.view.viewWithTag(FrameViewTag)!
                    self.resultTextView.center.x = frameView.center.x
                    self.resultTextView.frame.origin.y = frameView.frame.origin.y + frameView.frame.size.height
                    self.view.addSubview(self.resultTextView)
                    self.resultTextView.text = NSLocalizedString("Recognizing...", comment: "Recognizing Text")
                    
                    self.recognizeImage(croppedImage)
                    
                    // Test display image
                    //let imageView = UIImageView(image: croppedImage)
                    //imageView.center = self.cameraView.center
                    //self.cameraView.addSubview(imageView)
                    
                    // Test Code
                    //self.translateText("Hello World!")
                }
            }
        }
        
    }
}
#endif

extension ViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if noTextFound == true {
            resultTextView.text = ""
            noTextFound = false
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: {
            let frameView = self.view.viewWithTag(FrameViewTag)!
            
            frameView.frame.origin.y = self.view.frame.size.height / 8
            
            self.resultTextView.center.x = frameView.center.x
            self.resultTextView.frame.origin.y = frameView.frame.origin.y + frameView.frame.size.height
            self.translationResultTextView.frame = self.resultTextView.frame
            self.translationResultTextView.frame.origin.y += self.resultTextView.frame.size.height
        }, completion: nil)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text as NSString).length > 0 {
            translateText(textView.text)
        } else {
            translationResultTextView.removeFromSuperview()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
}

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .landscapeLeft:        return .landscapeLeft
            case .landscapeRight:       return .landscapeRight
            case .portrait:             return .portrait
            case .portraitUpsideDown:   return .portraitUpsideDown
            }
        }
    }
    
    init(ui: UIInterfaceOrientation) {
        switch ui {
        case .landscapeRight:       self = .landscapeRight
        case .landscapeLeft:        self = .landscapeLeft
        case .portrait:             self = .portrait
        case .portraitUpsideDown:   self = .portraitUpsideDown
        default:                    self = .portrait
        }
    }
}
