
import UIKit

@objc enum State: Int {
    case def = 0
    case edit
    case editSelected
    case drawing
    case empty
}

@available(iOS 13.0, *)
@objc class MenuAssembler: NSObject {
        
    @objc static var state: State = .def
    
    static var builder: UIMenuBuilder!
    
    @objc static func buildStandartMenuWith(builder: UIMenuBuilder, isDisabled: Bool) {
        self.builder = builder
        builder.insertChild(defaultMenu(isDisabled), atStartOfMenu: .file)
        buildRecentlyPaths(with: builder, after: .open)
    }
    
    @objc static func buildMenuWith(builder: UIMenuBuilder, isDisabled: Bool, isEditDisabled: Bool = false) {
        self.builder = builder
        builder.insertChild(edit(isDisabled, isEditDisabled: isEditDisabled), atStartOfMenu: .file)
    }
    
    @objc static func buildXsheetMenuWith(builder: UIMenuBuilder, isDisabled: Bool) {
        self.builder = builder
        builder.insertChild(xsheet(isDisabled), atStartOfMenu: .view)
    }
    
    @objc static func buildZoomMenu(with builder: UIMenuBuilder) {
        self.builder = builder
        let zoom = UIMenu(
            title: "Zoom",
            identifier: .zoom
        )
        let zoom75 = UICommand(
            title: "Zoom 75%",
            action: #selector(FBSceneController.zoom75),
            propertyList: "zoom75"
        )
        let zoom100 = UICommand(
            title: "Zoom 100%",
            action: #selector(FBSceneController.zoom100),
            propertyList: "zoom100"
        )
        let zoom200 = UICommand(
            title: "Zoom 200%",
            action: #selector(FBSceneController.zoom200),
            propertyList: "zoom200"
        )
        let zoomFill = UICommand(
            title: "Zoom To Full Screen",
            action: #selector(FBSceneController.zoomToFill),
            propertyList: "zoomFill"
        )
        let zoomFit = UICommand(
            title: "Zoom To Fit",
            action: #selector(FBSceneController.zoomToFit),
            propertyList: "zoomFit"
        )
        let zoomInline = UIMenu(
            identifier: .zoomInline,
            options: .displayInline,
            children: [
                zoom75,
                zoom100,
                zoom200,
                zoomFill,
                zoomFit
            ]
        )
        builder.insertChild(zoom, atEndOfMenu: .view)
        builder.insertChild(zoomInline, atStartOfMenu: .zoom)
    }
    
    @objc static func buildImportMenu(with builder: UIMenuBuilder) {
        builder.insertChild(defaultMenu(false), atStartOfMenu: .file)
        let importMenu = UIMenu(
            title: "Import...",
            identifier: .importMenu
        )
        let audio = UICommand(
            title: "Audio...",
            action: #selector(FBSceneController.importAudio),
            propertyList: "audio"
        )
        let images = UICommand(
            title: "Images...",
            action: #selector(FBSceneController.importImage),
            propertyList: "images"
        )
        let movie = UICommand(
            title: "Movie...",
            action: #selector(FBSceneController.importVideo),
            propertyList: "movie"
        )
        let importMenuInline = UIMenu(
            identifier: .importMenuInline,
            options: .displayInline,
            children: [
                audio,
                images,
                movie
            ]
        )
        builder.insertSibling(importMenu, afterMenu: .open)
        builder.insertChild(importMenuInline, atStartOfMenu: .importMenu)
        let exportMenu = UIMenu(
            title: "Export",
            identifier: .exportMenu,
            options: .displayInline,
            children: [
                UIKeyCommand(
                    title: "Export",
                    action: #selector(FBSceneController.makeExport),
                    input: "E",
                    propertyList: "export"
                )
            ]
        )
        builder.insertSibling(exportMenu, beforeMenu: .close)
        buildRecentlyPaths(with: builder, after: .exportMenu)
    }
    
    static func defaultMenu(_ isDisabled: Bool) -> UIMenu {
        let openCommand = UIKeyCommand(
            title: "New scene",
            action: #selector(AppDelegate.newScene),
            input: "N",
            modifierFlags: .command
        )
        let importCommand = UIKeyCommand(
            title: "Open scene",
            action: #selector(AppDelegate.importAction),
            input: "O",
            modifierFlags: .command
        )
        if isDisabled {
            importCommand.attributes = .disabled
            openCommand.attributes = .disabled
        }
        let openMenu = UIMenu(
            identifier: .open,
            options: .displayInline,
            children: [
                openCommand,
                importCommand
            ]
        )
        return openMenu
    }
    
    static func edit(_ isDisabled: Bool, isEditDisabled: Bool) -> UIMenu {
        let editCommand = UIKeyCommand(title: "Edit", action: #selector(AppDelegate.editMode), input: "E", modifierFlags: .command)
        
        let renameCommand = UIKeyCommand(title: "Rename",  action: #selector(AppDelegate.renameAction), input: "R", modifierFlags: .command)
        let deleteCommand = UIKeyCommand(title: "Delete", action: #selector(AppDelegate.deleteAction), input: "D", modifierFlags: [.command, .shift])
        let exportCommand = UIKeyCommand(title: "Export", action: #selector(AppDelegate.share), input: "E", modifierFlags: [.command, .shift])
        
        if isDisabled {
            if isEditDisabled {
                editCommand.attributes = .disabled
            }
            renameCommand.attributes = .disabled
            deleteCommand.attributes = .disabled
            exportCommand.attributes = .disabled
        }
        
        let openMenu = UIMenu(title: "ee", image: nil, options: .displayInline, children: [editCommand,
                                                                                           renameCommand,
                                                                                           deleteCommand,
                                                                                           exportCommand])
        return openMenu
    }
    
    static func xsheet(_ isDisabled: Bool) -> UIMenu {
        let leadingCommand = UIKeyCommand(title: "Left",  action: #selector(AppDelegate.setXsheetLeading), input: "X", modifierFlags: .command)
        let trailingCommand = UIKeyCommand(title: "Right", action: #selector(AppDelegate.setXsheetTrailing), input: "X", modifierFlags: [.command, .shift])
        
        switch SettingsBundleHelper.xsheetLocation {
        case .trailing:
            trailingCommand.attributes = .disabled
        case .leading:
            leadingCommand.attributes = .disabled
        }
        
        let xsheetMenu = UIMenu(title: "XSheet Location", image: nil, options: UIMenu.Options(), children: isDisabled ? [] : [leadingCommand, trailingCommand])
        
        return xsheetMenu
    }
    
    private static func createRecently(with recentlyPaths: [String]) -> [UIMenuElement] {
        if recentlyPaths.isEmpty {
            let empty = UICommand(
                title: "Empty",
                action: #selector(AppDelegate.openRecent(_:)),
                propertyList: -1
            )
            empty.attributes = .disabled
            return [
                empty
            ]
        }
        var result = [UIMenuElement]()
        for i in 0..<recentlyPaths.count {
            let recentlyPath = recentlyPaths[i]
            let url = URL(fileURLWithPath: recentlyPath)
            let command = UICommand(
                title: url.lastPathComponent,
                action: #selector(AppDelegate.openRecent(_:)),
                propertyList: i
            )
            result.append(command)
        }
        return result
    }
    
    @objc static func rebuild() {
        builder.system.setNeedsRevalidate()
        builder.system.setNeedsRebuild()
    }
    
    // MARK: -
    
    private static func buildRecentlyPaths(with builder: UIMenuBuilder, after: UIMenu.Identifier) {
        if #available(iOS 14.0, *) {
            builder.remove(menu: .openRecent)
        }
        let recently = UIMenu(
            title: "Open recently",
            identifier: .recently
        )
        let recentlyPaths = RecentlyManager.shared.recentlyPaths()
        let children = createRecently(with: recentlyPaths)
        let recentlyInline = UIMenu(
            identifier: .recenlyInline,
            options: .displayInline,
            children: children
        )
        builder.insertSibling(recently, afterMenu: after)
        builder.insertChild(recentlyInline, atStartOfMenu: .recently)
        if !recentlyPaths.isEmpty {
            let clear = UICommand(
                title: "Clear",
                action: #selector(AppDelegate.clearRecent(_:)),
                propertyList: "clear"
            )
            let clearRecentlyInline = UIMenu(
                identifier: .clearRecentlyInline,
                options: .displayInline,
                children: [
                    clear
                ]
            )
            builder.insertChild(clearRecentlyInline, atEndOfMenu: .recently)
        }
    }
}

@available(iOS 13.0, *)
extension UIMenu.Identifier {
    
    static var open: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.open")
    }
    
    static var zoom: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.zoom")
    }
    
    static var zoomInline: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.zoomInline")
    }
    
    static var importMenu: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.importMenu")
    }
    
    static var importMenuInline: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.importMenuInline")
    }
    
    static var exportMenu: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.exportMenu")
    }
    
    static var recently: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.recently")
    }
    
    static var recenlyInline: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.recenlyInline")
    }
    
    static var clearRecentlyInline: UIMenu.Identifier {
        return UIMenu.Identifier("com.flippad.menu.clearRecentlyInline")
    }
}
