//
//  AppDelegate.swift
//  FlipPad
//
//  Created by Alex on 21.01.2020.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import UIKit
import CrashReporter

@objc enum FileError: Int, LocalizedError {
    case iCloudDriveDocumentsNotAvailable
    case localStorageNotAvailable
    case documentsNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .iCloudDriveDocumentsNotAvailable:
            return "iCloud Drive not available"
        case .localStorageNotAvailable:
            return "Local Storage not available"
        case .documentsNotAvailable:
            return "Document (either Local or iCloud) not available"
        }
    }
}

var appDelegate = UIApplication.shared.delegate as! AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var crashReporter: PLCrashReporter?
    
    var window: UIWindow? // iOS 12 support
    
    private(set) lazy var docsController: FBDocumentsController? = {
        return FBDocumentsController()
    }()
    
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    @objc var startupError: Error?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.setupDefaultPrefs()
        IAPManager.sharedSecret = "d68c2ff8b12847388045e0dc846b512d"
        IAPManager.setup()
        _ = FeatureManager.shared
        _ = RecentlyManager.shared
        
        // Folders Setup
        do {
            try self.createDocumentsFolder()
        } catch {
            print("🔥 createDocumentsFolder")
            self.startupError = error
        }
        
        do {
            try self.createICloudDocumentsFolder()
        } catch {
            print("🔥 createICloudDocumentsFolder")
            self.startupError = error
        }
        
        do {
            try self.makeInitialCloudBackup()
        } catch {
            print("🔥 makeInitialCloudBackup")
            self.startupError = error
        }
        
        do {
            try self.moveFilesToActualFolder()
        } catch {
            print("🔥 moveFilesToActualFolder")
            //            self.startupError = error
        }
        
        self.prepareOnboardingFiles()
        self.handleLaunchCount()
        
        
        // App Menu
        if #available(iOS 13, *) {
            MenuAssembler.state = .empty
        } else {
            // Fallback on earlier versions
        }
        
        // App Window
        if #available(iOS 13, *) {
            // window management is handled by the DocumentsSceneDelegate
        } else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = CheckVersionVC()
            self.window?.makeKeyAndVisible()
        }
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        // PLCrashReporter: enabling in-process crash reporting will conflict with any attached debuggers.
//        if !isDebugging() {
//            setupCrashReporter()
//        }
//
//        checkCollectedCrashes()
        
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        guard let scene_controller = self.docsController?.currentSceneController else {
            return
        }
        scene_controller.drawingView.saveChanges()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if #available(iOS 13, *) {
            // state management is handled by the DocumentsSceneDelegate
        } else {
            guard let scene_controller = self.docsController?.currentSceneController else {
                return
            }
            if scene_controller.state == .playing {
                scene_controller.pauseScene(self)
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        guard let scene_controller = self.docsController?.currentSceneController else {
            return
        }
        self.backgroundTask = application.beginBackgroundTask(withName: nil, expirationHandler: {
            if let bgTask = self.backgroundTask {
                application.endBackgroundTask(bgTask)
            }
            self.backgroundTask = .invalid
        })
        
        DispatchQueue.global(qos: .default).async {
            if let bgTask = self.backgroundTask {
                application.endBackgroundTask(bgTask)
            }
            self.backgroundTask = .invalid
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .landscape
    }
    
    
    // MARK: - UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    // MARK: - Files & Backups
    
    // Creating Local / iCloud Documents folders
    
    private func createDocumentsFolder() throws {
        guard let documentsUrl = URL.documents else {
            throw FileError.documentsNotAvailable
        }
        if !FileManager.default.fileExists(atPath: documentsUrl.path) {
            try FileManager.default.createDirectory(at: documentsUrl, withIntermediateDirectories: true, attributes: nil)
        }
    }
    private func createICloudDocumentsFolder() throws {
        guard let iCloudDocUrl = URL.iCloudDocStorage else {
            throw FileError.iCloudDriveDocumentsNotAvailable
        }
        if !FileManager.default.fileExists(atPath: iCloudDocUrl.path) {
            try FileManager.default.createDirectory(at: iCloudDocUrl, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // Moving files to currently selected Documents folder
    
    @objc func moveFilesToActualFolder() throws {
        guard let iCloudDocStorage = URL.iCloudDocStorage else {
            throw FileError.iCloudDriveDocumentsNotAvailable
        }
        guard let localDocStorage = URL.localDocStorage else {
            throw FileError.localStorageNotAvailable
        }
        
        let oldStorage = SettingsBundleHelper.storageType == .local ? iCloudDocStorage : localDocStorage
        let newStorage = SettingsBundleHelper.storageType == .local ? localDocStorage : iCloudDocStorage
        
        let oldStorageFiles = try FileManager.default.contentsOfDirectory(at: oldStorage, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        for file in oldStorageFiles {
            guard file.pathExtension == kDGC || file.pathExtension == kDCFB else {
                continue
            }
            let newFileUrl = newStorage.appendingPathComponent(file.lastPathComponent)
            if FileManager.default.fileExists(atPath: newFileUrl.path) {
                try FileManager.default.removeItem(atPath: newFileUrl.path)
            }
            try FileManager.default.moveItem(atPath: file.path, toPath: newFileUrl.path)
        }
    }
    
    // Backups
    
    private func makeInitialCloudBackup() throws {
        guard let iCloudUrl = URL.iCloudDriveDocuments else {
            throw FileError.iCloudDriveDocumentsNotAvailable
        }
        guard let documentsUrl = URL.documents else {
            throw FileError.documentsNotAvailable
        }
        
        // Creating BACKUPS directory
        let backupsRootDirectory = iCloudUrl.appendingPathComponent("Backups", isDirectory: true)
        guard !FileManager.default.fileExists(atPath: backupsRootDirectory.path) else {
            return
        }
        try FileManager.default.createDirectory(at: backupsRootDirectory, withIntermediateDirectories: true, attributes: nil)
        // Copying all files
        let fileList = try FileManager.default.contentsOfDirectory(atPath: documentsUrl.path)
        print(fileList)
        for filename in fileList.filter({ $0.hasSuffix("dcfb") }) {
            let sourcePath = "\(documentsUrl.path)/\(filename)"
            let destinationPath = "\(backupsRootDirectory.path)/\(filename)"
            do {
                try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
            } catch {
                print("Initial backup error copying file from", sourcePath, "to", destinationPath, ":", error.localizedDescription)
            }
        }
        print("Created Initial backup to", backupsRootDirectory.path)
    }
    
    // Call before file modification
    @objc func makeIncrementalCloudBackupForDocument(atPath documentPath: String) {
        guard SettingsBundleHelper.iCloudBackupsEnabled else {
            return
        }
        guard let iCloudUrl = URL.iCloudDriveDocuments else {
            return
        }
        let filename = (documentPath as NSString).lastPathComponent
        let backupDestinationPath = iCloudUrl.appendingPathComponent("Backups", isDirectory: true).appendingPathComponent(filename).path
        
        do {
            try FileManager.default.copyItem(atPath: documentPath, toPath: backupDestinationPath)
            print("Created backup of", documentPath, "to", backupDestinationPath)
        } catch {
            print("Error creating Incremental backup:", error.localizedDescription)
        }
    }
    
    // Onboarding files
    
    func prepareOnboardingFiles() {
        guard let onboardingUrl = URL.localDocStorage?.appendingPathComponent("Onboarding") else {
            return
        }
        if !FileManager.default.fileExists(atPath: onboardingUrl.path) {
            try? FileManager.default.createDirectory(at: onboardingUrl, withIntermediateDirectories: true, attributes: nil)
            for number in 1...16 {
                if let from = Bundle.main.url(forResource: String(number), withExtension: "pdf") {
                    let to = onboardingUrl.appendingPathComponent(from.lastPathComponent)
                    try? FileManager.default.copyItem(at: from, to: to)
                }
            }
        }
    }
    
    func handleLaunchCount() {
        let kLaunchCount = "LaunchCount"
        let count = (UserDefaults.standard.value(forKey: kLaunchCount) as? Int) ?? 0
        UserDefaults.standard.setValue(count + 1, forKey: kLaunchCount)
        print("Launched", count + 1, "time")
    }
    
    // MARK: -
    
#if targetEnvironment(macCatalyst)
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        builder.remove(menu: .format)
        builder.remove(menu: .edit)
        
        switch MenuAssembler.state {
        case .def:
            MenuAssembler.buildMenuWith(builder: builder, isDisabled: true)
            MenuAssembler.buildStandartMenuWith(builder: builder, isDisabled: false)
        case .edit:
            MenuAssembler.buildMenuWith(builder: builder, isDisabled: true)
            MenuAssembler.buildStandartMenuWith(builder: builder, isDisabled: true)
        case .editSelected:
            MenuAssembler.buildMenuWith(builder: builder, isDisabled: false)
            MenuAssembler.buildStandartMenuWith(builder: builder, isDisabled: true)
        case .drawing:
            MenuAssembler.buildXsheetMenuWith(builder: builder, isDisabled: false)
            MenuAssembler.buildZoomMenu(with: builder)
            MenuAssembler.buildImportMenu(with: builder)
        case .empty:
            MenuAssembler.buildMenuWith(builder: builder, isDisabled: true, isEditDisabled: true)
            MenuAssembler.buildStandartMenuWith(builder: builder, isDisabled: true)
        }
    }
#endif
    
    @objc func newScene() {
        if self.docsController?.presentedViewController != nil {
            self.closeDocument()
        }
        self.docsController?.showSettings(nil)
    }
    
    @objc func editMode() {
        if self.docsController?.isEditing == false {
#if targetEnvironment(macCatalyst)
            self.docsController?.startEditing(nil)
#else
            self.docsController?.isEditing = true
            self.docsController?.replaceToolbar(with: self.docsController?.editingToolbar)
            self.docsController?.currentToolbar.rf_enableButtons(withTags: [kDoneButtonTag])
            if #available(iOS 13, *) {
                MenuAssembler.state = .edit
            } else {
                // Fallback on earlier versions
            }
#endif
        } else {
#if targetEnvironment(macCatalyst)
            self.docsController?.finishEditing(nil)
#else
            self.docsController?.isEditing = false
            self.docsController?.deselectAll()
            self.docsController?.replaceToolbar(with: self.docsController?.mainToolbar)
            if #available(iOS 13, *) {
                MenuAssembler.state = .def
            } else {
                // Fallback on earlier versions
            }
#endif
        }
        if #available(iOS 13, *) {
            MenuAssembler.rebuild()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func renameAction() {
        guard let _ = self.docsController?.collectionView.indexPathsForSelectedItems?.last else {
            return
        }
        self.docsController?.renameDocument(nil)
    }
    
    @objc func deleteAction() {
        self.docsController?.deleteDocument(nil)
    }
    
    @objc func share() {
        self.docsController?.shareDocument(nil)
    }
    
    @objc func importAction() {
        self.docsController?.importDocument(nil)
    }
    
    @objc func setXsheetLeading() {
        SettingsBundleHelper.xsheetLocation = .leading
#if targetEnvironment(macCatalyst)
        MenuAssembler.rebuild()
#endif
    }
    
    @objc func setXsheetTrailing() {
        SettingsBundleHelper.xsheetLocation = .trailing
#if targetEnvironment(macCatalyst)
        MenuAssembler.rebuild()
#endif
    }
    
    @available(iOS 13.0, *)
    @objc func openRecent(_ sender: Any?) {
        let recentlyPaths = RecentlyManager.shared.recentlyPaths()
        guard
            let command = sender as? UICommand,
            let index = command.propertyList as? Int,
            0 <= index && index < recentlyPaths.count
        else {
            return
        }
        let path = recentlyPaths[index]
        NotificationCenter.default.post(name: NSNotification.Name(kOpenRecently), object: nil, userInfo: ["path": path])
    }
    
    @available(iOS 13.0, *)
    @objc func clearRecent(_ sender: Any?) {
        RecentlyManager.shared.clear()
        MenuAssembler.rebuild()
    }
    
    func setupDefaultPrefs() {
        if (UserDefaults.standard.object(forKey: SettingsBundleHelper.SettingsBundleKeys.iCloudBackups) == nil) {
            UserDefaults.standard.set(true, forKey: SettingsBundleHelper.SettingsBundleKeys.iCloudBackups)
        }
        
        let minBrushWidths = [
            "Ink": kMinBrushSize,
            "Pencil": kMinBrushSize,
            "Chalk": kMinBrushSize
        ]
        let maxBrushWidths = [
            "Ink": kMaxBrushSize,
            "Pencil": kMaxBrushSize,
            "Chalk": kMaxBrushSize
        ]
        
        UserDefaults.standard.register(defaults: [
            kCurrentBrushPrefKey: "Ink",
            kCurrentColorPrefKey: "0 0 0",
            kMinimumLineWidthsPrefKey: minBrushWidths,
            kMaximumLineWidthsPrefKey: maxBrushWidths,
            kBrushHardnessKey: 5.5,
            kBrushSmoothingKey: 0,
            kCurrentEraserWidthPrefKey: 10.0,
            kCurrentEraserHardnessPrefKey: 0.0,
            kLightboxEnabledPrefKey: true,
            kLightboxBackgroundDisplayPrefKey: true,
            kLightboxPreviousFramesPrefKey: 2,
            kCurrentAlphaPrefKey: 1,
            kCurrentFramesPerSecondPrefKey: 24,
            kCurrentResolutionPrefKey: "800 x 600",
            kUseThreshold: false,
            kThreshold: 0
        ])
        
        SettingsBundleHelper.editModeDevice = false
        SettingsBundleHelper.resolutionsCheatVisible = false
    }
    
    @objc func closeDocument(animated: Bool = true) {
        self.docsController?.closeCurrentDocument(animated: animated)
    }
    
    // MARK: - Get visible ViewController

    func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {

        var rootVC = rootViewController
        if rootVC == nil { rootVC = UIApplication.shared.keyWindow?.rootViewController }

        if rootVC?.presentedViewController == nil { return rootVC }

        if let presented = rootVC?.presentedViewController {
            if presented.isKind(of: UINavigationController.self) {
                let navigationController = presented as! UINavigationController
                return navigationController.viewControllers.last!
            }

            if presented.isKind(of: UITabBarController.self) {
                let tabBarController = presented as! UITabBarController
                return tabBarController.selectedViewController!
            }

            return getVisibleViewController(presented)
        }
        return nil
    }

}


// MARK: - Crash report handling

extension AppDelegate {
    func isDebugging() -> Bool {
        var info = kinfo_proc()
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    func setupCrashReporter() {
        let config = PLCrashReporterConfig(signalHandlerType: .mach, symbolicationStrategy: .all)
        self.crashReporter = PLCrashReporter(configuration: config)
        
        do {
            try self.crashReporter?.enableAndReturnError()
        } catch {
            print(error)
        }
    }
    
    func checkCollectedCrashes() {
        guard let crashReporter = self.crashReporter else { return }
        
        do {
            let data = try crashReporter.loadPendingCrashReportDataAndReturnError()
            
            let report = try PLCrashReport(data: data)
            let text = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS)
            
            NSLog(text ?? "unknown crash")
            
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("crashReport_\(Date())")
                .appendingPathExtension("crash")
            
            FileManager.default.createFile(atPath: url.path , contents: text?.data(using: .utf8), attributes: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let alert = UIAlertController(title: "Crash", message: text, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Share crash report", style: .default, handler: { [weak self] _ in

                    let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    share.popoverPresentationController?.sourceView = alert.view
                    share.popoverPresentationController?.permittedArrowDirections = .any
                    share.popoverPresentationController?.canOverlapSourceViewRect = true
                    share.completionWithItemsHandler = { _, _, _, _ in
                        try? FileManager.default.removeItem(at: url)
                        crashReporter.purgePendingCrashReport()
                    }
                    self?.getVisibleViewController(nil)?.present(share, animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
                                
                self.getVisibleViewController(nil)?.present(alert, animated: true)

            }
            
        } catch {
            print(error)
        }
    }
}

