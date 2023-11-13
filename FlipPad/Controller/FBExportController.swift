//
//  FBExportController.swift
//  FlipPad
//
//  Created by Alex on 01.04.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit
import Foundation

class FBExportController: UIViewController {
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    @objc weak var xSheetController: FBXsheetController?
    @objc weak var sceneController: FBSceneController?
    
    @IBOutlet weak var movieButton: RadioButton!
    @IBOutlet weak var framesButton: RadioButton!
    
    @IBOutlet weak var rangeContainerStackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var selectAllCheckbox: CheckBox!
    @IBOutlet weak var includeSoundtrackCheckbox: CheckBox!
    
    @IBOutlet weak var startFrameField: UITextField!
    @IBOutlet weak var endFrameField: UITextField!
    @IBOutlet weak var startLevelField: UITextField!
    @IBOutlet weak var endLevelField: UITextField!
    
    @IBOutlet weak var scrollViewYConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewXConstraint: NSLayoutConstraint!
    
    var presentingVC: UIViewController {
        return self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieButton.isChecked = true
        selectAllCheckbox.isChecked = true
        includeSoundtrackCheckbox.isChecked = true
        
        if #available(iOS 13.0, *) {
            startFrameField.overrideUserInterfaceStyle = .light
            endFrameField.overrideUserInterfaceStyle = .light
            startLevelField.overrideUserInterfaceStyle = .light
            endLevelField.overrideUserInterfaceStyle = .light
        }
        
        selectAll()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFramwWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private var shadowLayer: CAShapeLayer!
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if shadowLayer == nil {
            shadowLayer = CAShapeLayer()
            
            shadowLayer.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 10.0).cgPath
            shadowLayer.fillColor = UIColor(red: 230.0 / 256.0, green: 230.0 / 256.0, blue: 230.0 / 256.0, alpha: 1.0).cgColor
            
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowPath = shadowLayer.path
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            shadowLayer.shadowRadius = 36

            contentView.layer.insertSublayer(shadowLayer, at: 0)
        }
    }
    
    @objc func setOffset(x: CGFloat, y: CGFloat) {
        scrollViewXConstraint.constant = x
        scrollViewYConstraint.constant = y
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    
    @IBAction func selectMovie() {
        framesButton.isChecked = !movieButton.isChecked
        includeSoundtrackCheckbox.isHidden = false
    }
    
    @IBAction func selectFrames() {
        movieButton.isChecked = !framesButton.isChecked
        includeSoundtrackCheckbox.isHidden = true
    }
    
    @IBAction func selectAll() {
        if selectAllCheckbox.isChecked {
            guard let document = sceneController?.document.storage else {
                return
            }
            startFrameField.text = "1"
            startLevelField.text = "0"
            endFrameField.text = String(document.numberOfRows)
            endLevelField.text = String(document.numberOfColumns - 1)
            
            /*
            includeSoundtrackCheckbox.isEnabled = true
             */
            rangeContainerStackView.layer.opacity = 0.5
            rangeContainerStackView.isUserInteractionEnabled = false
        } else {
            /*
            includeSoundtrackCheckbox.isEnabled = false
            includeSoundtrackCheckbox.isChecked = false
             */
            rangeContainerStackView.layer.opacity = 1.0
            rangeContainerStackView.isUserInteractionEnabled = true
        }
    }
    
    private func getFrameRange() -> Range<Int>? {
        let fromFrame = Int(startFrameField.text ?? "0") ?? 0
        let toFrame = Int(endFrameField.text ?? "0") ?? 0
        guard fromFrame > 0 else { return nil }
        return Range(uncheckedBounds: (fromFrame, toFrame + 1))
    }
    
    private func getLevelRange() -> Range<Int>? {
        let fromLevel = Int(startLevelField.text ?? "0") ?? 0
        let toLevel = Int(endLevelField.text ?? "0") ?? 0
        guard fromLevel >= 0 else { return nil }
        return Range(uncheckedBounds: (fromLevel + 1, toLevel + 1 + 1))
    }
    
    @IBAction func export() {
        guard let fRange = getFrameRange(),
              let lRange = getLevelRange() else { return }
        
        if movieButton.isChecked {
            self.exportMovie(framesRange: fRange, levelsRange: lRange, withAudio: includeSoundtrackCheckbox.isChecked)
        } else {
            self.exportFramesFrom(framesRange: fRange, levelsRange: lRange)
        }
    }
    
    @IBAction func pressShareButton(_ sender: UIButton) {
        guard let fRange = getFrameRange(),
              let lRange = getLevelRange() else { return }
        
        if movieButton.isChecked {
            self.shareMovie(framesRange: fRange, levelsRange: lRange, withAudio: includeSoundtrackCheckbox.isChecked)
        } else {
            self.shareFramesFrom(framesRange: fRange, levelsRange: lRange)
        }
    }
    
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Notifications
    
    @objc func keyboardWillShow(notification: NSNotification) {
        updateConstraints(notification: notification)
    }
    
    @objc func keyboardFramwWillChange(notification: NSNotification) {
        updateConstraints(notification: notification)
    }
    
    func updateConstraints(notification: NSNotification) {
        #if !targetEnvironment(macCatalyst)
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            var bottomInset: CGFloat = 0.0
            if #available(iOS 11.0, *) {
                bottomInset = view.safeAreaInsets.bottom
            }
            
            scrollViewYConstraint.constant = max(keyboardSize.height - bottomInset, 54.0)
            view.layoutIfNeeded()
        }
        #endif
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollViewYConstraint.constant = 0.0
        view.layoutIfNeeded()
    }
    
    // MARK: - Export
    
    private func showError(_ error: Error) {
        let presentErrorAlert = { [weak self] in
            let alert = UIAlertController(title: "Export Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
        
        if let presented = presentedViewController {
            presented.dismiss(animated: true, completion: presentErrorAlert)
        } else {
            presentErrorAlert()
        }
    }
    
    private func showInfo(_ info: String, withCompletion completion: (() -> Void)?, presentationCompletion: (() -> Void)?, on: UIViewController?) {
        
        let presentSuccessAlert = {
            let alert = UIAlertController(title: info, message: nil, preferredStyle: .alert)
            if let completion = completion {
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                    completion()
                }))
            }
            on?.present(alert, animated: true, completion: presentationCompletion)
        }
        
        if let presented = on?.presentedViewController {
            presented.dismiss(animated: true, completion: presentSuccessAlert)
        } else {
            presentSuccessAlert()
        }
    }
    
    private func prepareMovie(framesRange: Range<Int>, levelsRange: Range<Int>, withAudio: Bool, completion: @escaping (_ movie: URL?) -> Void) {
        guard let sceneController = self.sceneController, let document = sceneController.document, let docsFolder = URL.localDocStorage?.path, let filename = ((URL(fileURLWithPath: document.filePath).lastPathComponent as NSString).deletingPathExtension as NSString).appendingPathExtension("mov") else {
            completion(nil)
            return
        }
        
        self.showInfo("Preparing Movie..", withCompletion: nil, presentationCompletion: { [weak self] in
            if let compositedImgURLs = self?.writeFrameImagesForExportFrom(frameRange: framesRange, levelRange: levelsRange) {
                guard let firstImgURL = compositedImgURLs.first, let firstImgData = try? Data(contentsOf: firstImgURL), let firstImg = UIImage(data: firstImgData) else {
                    completion(nil)
                    return
                }
                let imgSize = firstImg.size
                
                let videoPath = docsFolder + "/" + "TempVideo.mov"
                let exportPath = docsFolder + "/" + filename
                
                if FileManager.default.fileExists(atPath: videoPath) {
                    try? FileManager.default.removeItem(atPath: videoPath)
                }
                if FileManager.default.fileExists(atPath: exportPath) {
                    try? FileManager.default.removeItem(atPath: exportPath)
                }
                
                let soundData: Data? = document.soundData()
                
                if let soundData = soundData, withAudio {
                    FBMovieExporter.writeImages(asMovie: compositedImgURLs, toPath: videoPath, size: imgSize, duration: 1, fps: document.fps()) { [weak self] (error) in
                    
                        if let error = error {
                            DispatchQueue.main.async {
                                self?.showError(error)
                            }
                        }
                        
                        let timePerFrame = 1.0 / Double(document.fps())
                        let soundStartTime = Double(document.soundOffset()) * timePerFrame
                        
                        FBMovieExporter.addAudioData(soundData, forVideo: videoPath, atTime: soundStartTime, toPath: exportPath) { (error) in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self?.showError(error)
                                }
                                completion(URL(fileURLWithPath: exportPath))
                            }
                        }
                    }
                } else {
                    FBMovieExporter.writeImages(asMovie: compositedImgURLs, toPath: exportPath, size: imgSize, duration: 1, fps: document.fps()) { [weak self] (error) in
                        DispatchQueue.main.async {
                            if let error = error {
                                self?.showError(error)
                            }
                            completion(URL(fileURLWithPath: exportPath))
                        }
                    }
                }
            } else {
                self?.showInfo("Export Movie Failed", withCompletion: {
                    completion(nil)
                    self?.dismiss(animated: true, completion: nil)
                }, presentationCompletion: nil, on: self?.presentingVC)
            }
        }, on: self)
    }
    
    private func prepare(framesRange: Range<Int>, levelsRange: Range<Int>, completion: @escaping (_ frames: [URL]?) -> Void) {
        self.showInfo("Preparing Frames..", withCompletion: nil, presentationCompletion: { [weak self] in
            DispatchQueue.global().async {
                if let imageURLs = self?.writeFrameImagesForExportFrom(frameRange: framesRange, levelRange: levelsRange) {
                    DispatchQueue.main.async {
                        completion(imageURLs)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showInfo("Export Frames Failed", withCompletion: {
                            self?.dismiss(animated: true, completion: nil)
                        }, presentationCompletion: nil, on: self?.presentingVC)
                    }
                }
            }
        }, on: self)
    }
    
    private func exportMovie(framesRange: Range<Int>, levelsRange: Range<Int>, withAudio: Bool) {
        self.prepareMovie(framesRange: framesRange, levelsRange: levelsRange, withAudio: withAudio) { [weak self] movie in
            guard let url = movie else { return }
            self?.exportItems([ url ], withCompletion: { success in
                self?.showInfo(success ? "Export Movie Completed" : "Export Movie Cancelled", withCompletion: {
                    self?.dismiss(animated: true, completion: nil)
                }, presentationCompletion: nil, on: self?.presentingVC)
            })
        }
    }

    private func exportFramesFrom(framesRange: Range<Int>, levelsRange: Range<Int>) {
        self.prepare(framesRange: framesRange, levelsRange: levelsRange) { [weak self] frames in
            guard let urls = frames else { return }
            self?.exportItems(urls, withCompletion: { success in
                self?.showInfo(success ? "Export Frames Completed" : "Export Frames Cancelled", withCompletion: {
                    self?.dismiss(animated: true, completion: nil)
                }, presentationCompletion: nil, on: self?.presentingVC)
            })
        }
    }
    
    private func shareFramesFrom(framesRange: Range<Int>, levelsRange: Range<Int>) {
        self.prepare(framesRange: framesRange, levelsRange: levelsRange) { [weak self] frames in
            guard let self = self,
                  let urls = frames else { return }
            let vc = UIActivityViewController(activityItems: urls, applicationActivities: [])
            if UIDevice.current.userInterfaceIdiom == .pad {
                vc.modalPresentationStyle = .popover
                if let popover = vc.popoverPresentationController {
                    popover.sourceView = self.contentView
                    popover.sourceRect = self.contentView.bounds
                    popover.permittedArrowDirections = .down
                }
            }
            self.dismiss(animated: true, completion: nil)
            self.present(vc, animated: true)
        }
    }
    
    private func shareMovie(framesRange: Range<Int>, levelsRange: Range<Int>, withAudio: Bool) {
        self.prepareMovie(framesRange: framesRange, levelsRange: levelsRange, withAudio: withAudio) { [weak self] movie in
            guard let self = self,
                  let url = movie else { return }
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
            if UIDevice.current.userInterfaceIdiom == .pad {
                vc.modalPresentationStyle = .popover
                if let popover = vc.popoverPresentationController {
                    popover.sourceView = self.contentView
                    popover.sourceRect = self.contentView.bounds
                    popover.permittedArrowDirections = .down
                }
            }
            self.dismiss(animated: true, completion: nil)
            self.present(vc, animated: true)
        }
    }

    private var exportCompletion: ((Bool) -> Void)?
    
    private func exportItems(_ items: [URL], withCompletion completion: @escaping (Bool) -> Void) {
        let presentActivityController = { [weak self] in
            guard let self = self else {
                return
            }
#if targetEnvironment(macCatalyst)
            self.exportCompletion = completion
            let exportController = UIDocumentPickerViewController(urls: items, in: .exportToService)
            exportController.delegate = self
            self.present(exportController, animated: true, completion: nil)
#else
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityController.completionWithItemsHandler = { (_, success, _, _) in
                completion(success)
            }
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityController.modalPresentationStyle = .popover
                if let popover = activityController.popoverPresentationController {
                    popover.sourceView = self.contentView
                    popover.sourceRect = self.contentView.bounds
                    popover.permittedArrowDirections = .down
                }
            }
            self.present(activityController, animated: true, completion: nil)
#endif
        }
        if let presented = presentedViewController {
            presented.dismiss(animated: true, completion: presentActivityController)
        } else {
            presentActivityController()
        }
    }
    
    // MARK: - Images composition
    
    private func writeFrameImagesForExportFrom(frameRange: Range<Int>, levelRange: Range<Int>) -> [URL]? {
        guard let document = sceneController?.document, let storage: FBXsheetStorage = document.storage else {
            return nil
        }
        var imageURLs = [URL]()
        
        let first_img = storage.firstValidCell()?.pencilImage ?? storage.firstValidCell()?.paintImage
        let img_size: CGSize = first_img?.size ?? document.cachedSceneDimensions
        
        var lastPaintImages = Array<CGImage?>.init(repeating: nil, count: levelRange.upperBound)
        var lastPencilImages = Array<CGImage?>.init(repeating: nil, count: levelRange.upperBound)
        
        for row in frameRange {
            autoreleasepool {
                
                UIGraphicsBeginImageContext(img_size)
                let context = UIGraphicsGetCurrentContext()
                
                let flipVertical: CGAffineTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: img_size.height)
                context?.concatenate(flipVertical)
                
                UIColor.white.setFill()
                context?.fill(CGRect(origin: .zero, size: img_size))
                
                for col in levelRange {
                    let levelIndex = col - 1
                    guard !document.database.isLevelHidden(at: levelIndex) else {
                        continue
                    }
                    
                    if let cel = storage.cellAt(row: row, column: col), !cel.isEmpty() {
                        // Paint
                        if let paintImage = cel.paintImage?.cgImage {
                            context?.draw(paintImage, in: CGRect(origin: .zero, size: img_size))
                            lastPaintImages[col] = paintImage
                        } else {
                            if let lastPaintImage = lastPaintImages[col] {
                                context?.draw(lastPaintImage, in: CGRect(origin: .zero, size: img_size))
                            }
                        }
                        // Pencil
                        if let pencilImage = cel.pencilImage?.cgImage {
                            context?.draw(pencilImage, in: CGRect(origin: .zero, size: img_size))
                            lastPencilImages[col] = pencilImage
                        } else {
                            if let lastPencilImage = lastPencilImages[col] {
                                context?.draw(lastPencilImage, in: CGRect(origin: .zero, size: img_size))
                            }
                        }
                    } else {
                        // Previous images
                        if let lastPaintImage = lastPaintImages[col] {
                            context?.draw(lastPaintImage, in: CGRect(origin: .zero, size: img_size))
                        }
                        if let lastPencilImage = lastPencilImages[col] {
                            context?.draw(lastPencilImage, in: CGRect(origin: .zero, size: img_size))
                        }
                    }
                }
                
                let newImg = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                
                
                
                let jpegData = newImg.jpegData(compressionQuality: 0.5)
                let tempPath = NSTemporaryDirectory() + "/frame_\(row).jpg"
                let tempImgUrl = URL(fileURLWithPath: tempPath)
                
                do {
                    try jpegData?.write(to: tempImgUrl)
                    imageURLs.append(tempImgUrl)
                } catch {
                    print("🔥 Frame write error:", error)
                }
                
                if (row % 10) == 0 {
                    DispatchQueue.main.async {
                        if let alert = self.presentedViewController {
                            alert.title = "Exporting.. (\(row)/\(frameRange.upperBound - frameRange.lowerBound + 1))"
                        }
                    }
                }
            }
        }
        
        return imageURLs
    }

    @IBAction func editingChanged(_ sender: UITextField) {
        selectAllCheckbox.isChecked = false
    }
}

extension FBExportController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        exportCompletion?(true)
        exportCompletion = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        exportCompletion?(false)
        exportCompletion = nil
    }
}
