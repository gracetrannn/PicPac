//
//  DocumentsSceneDelegate.swift
//  FlipPad
//
//  Created by Alex on 01.03.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

@available(iOS 13.0, *)
class DocumentsSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var shouldRestore = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 1200.0, height: 860.0)
        
        window?.rootViewController = CheckVersionVC()//(UIApplication.shared.delegate as! AppDelegate).docsController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let scene_controller = appDelegate.docsController?.currentSceneController else {
            return
        }
        if scene_controller.state == .playing {
            scene_controller.pauseScene(self)
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if shouldRestore {
            shouldRestore = false
            appDelegate.docsController?.restoreDocument()
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        shouldRestore = appDelegate.docsController?.currentSceneController != nil
        appDelegate.closeDocument(animated: false)
    }
}
