//
//  MainToolBarService.swift
//  FlipPad
//
//  Created by Alex on 3/2/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
@objc class ToolBarService: NSObject {
    
    @objc static func mainToolBar(_ delegate: NSToolbarDelegate) -> NSToolbar {
        let toolBar = NSToolbar(identifier: "mainToolBar")
        toolBar.displayMode = .default
        toolBar.delegate = delegate
        return toolBar
    }
    
    @objc static func editToolBar(_ delegate: NSToolbarDelegate) -> NSToolbar {
        let toolBar = NSToolbar(identifier: "editToolBar")
        toolBar.displayMode = .default
        toolBar.delegate = delegate
        return toolBar
    }
    
    @objc static func drawingToolBar(_ delegate: NSToolbarDelegate) -> NSToolbar {
        let toolBar = NSToolbar(identifier: "drawingToolBar")
        toolBar.displayMode = .default
        toolBar.delegate = delegate
        toolBar.centeredItemIdentifier = NSToolbarItem.Identifier(rawValue: "TitleItem")
        return toolBar
    }
    
}
#endif
