//
//  SDPhotosHelper.swift
//  FlipPad
//
//  Created by Alex on 17.12.2019.
//  Copyright © 2019 DigiCel, Inc. All rights reserved.
//

import UIKit
import Photos

@objc public class SDPhotosHelper: NSObject {
    
    //MARK:- Constants
    
    static let assetNotFoundError : NSError = NSError(domain: "SDPhotosHelper", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Asset with given identifier not found"])
    static let assetCreationFailure = NSError(domain: "SDPhotosHelper", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Asset could not be added from the given source"])
    static let albumNotFoundError : NSError = NSError(domain: "SDPhotosHelper", code: 1003, userInfo: [NSLocalizedDescriptionKey : "Album with given name was not found"])
    
    
    //MARK:- Methods
    
    @objc public static func createAlbum(withTitle title:String,
                                   onResult result:@escaping(Bool,Error?)->Void) {
        
        guard self.getAlbum(withName: title) == nil else {
            result(true,nil)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
        }) { (didSucceed, error) in
            OperationQueue.main.addOperation({
                didSucceed ? result(didSucceed,nil) : result(false,error)
            })
        }
    }
    
    //MARK:- Image Utilities
    
    @objc public static func addNewImage(_ image:UIImage,
                                   toAlbum albumName:String,
                                   onSuccess success:@escaping(String)->Void,
                                   onFailure failure:@escaping(Error?)->Void) {
        
        guard let album = self.getAlbum(withName: albumName) else {
            failure(SDPhotosHelper.albumNotFoundError)
            return
        }
        
        var localIdentifier = String()
        PHPhotoLibrary.shared().performChanges({
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let assetCreationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let placeHolder = assetCreationRequest.placeholderForCreatedAsset
            albumChangeRequest?.addAssets([placeHolder!] as NSArray)
            if placeHolder != nil {
                localIdentifier = (placeHolder?.localIdentifier)!
            }
        }) { (didSucceed, error) in
            OperationQueue.main.addOperation({
                didSucceed ? success(localIdentifier) : failure(error)
            })
        }
    }
    
    @objc public static func addNewImage(withFileUrl fileUrl:URL,
                                   toAlbum albumName:String,
                                   onSuccess success:@escaping(String)->Void,
                                   onFailure failure:@escaping(Error?)->Void)  {
        
        if let image = UIImage(contentsOfFile: fileUrl.path) {
            self.addNewImage(image, toAlbum: albumName, onSuccess: { (localIdentifier) in
                success(localIdentifier)
            }, onFailure: { (error) in
                failure(error)
            })
        } else {
            failure(SDPhotosHelper.assetCreationFailure)
        }
    }
    
    @objc public static func getImage(withIdentifier identifier:String,
                                fromAlbum album:String,
                                onSuccess success:@escaping(UIImage?)->Void,
                                onFailure failure:@escaping(Error?)->Void)  {
        
        if let asset = self.getAsset(fromAlbum: album, withLocalIdentifier: identifier) {
            let imageManager = PHImageManager.default()
            imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { (image, info) in
                OperationQueue.main.addOperation({
                    success(image)
                })
            }
        } else {
            OperationQueue.main.addOperation({
                failure(SDPhotosHelper.assetNotFoundError)
            })
        }
    }
    
    //MARK:- Video Utilities
    
    @objc public static func addNewVideo(withFileUrl fileUrl:URL,
                                   inAlbum albumName:String,
                                   onSuccess success:@escaping(String)->Void,
                                   onFailure failure:@escaping(Error?)->Void) {
        
        guard let album = self.getAlbum(withName: albumName) else {
            failure(SDPhotosHelper.albumNotFoundError)
            return
        }
        
        var localIdentifier = String()
        PHPhotoLibrary.shared().performChanges({
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            if let assetCreationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileUrl) {
                let placeHolder = assetCreationRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
                if placeHolder != nil {
                    localIdentifier = (placeHolder?.localIdentifier)!
                }
            }
            else {
                failure(SDPhotosHelper.assetCreationFailure)
            }
        })
        { (didSucceed, error) in
            OperationQueue.main.addOperation({
                didSucceed ? success(localIdentifier) : failure(error)
            })
        }
    }
    
    @objc public static func getVideoFileURL(withLocalIdentifier identifier:String,
                                       fromAlbum album: String,
                                       onSuccess success:@escaping(URL)->Void,
                                       onFailure failure:@escaping(Error)->Void)  {
        
        guard let asset = self.getAsset(fromAlbum: album, withLocalIdentifier: identifier) else {
            failure(SDPhotosHelper.assetNotFoundError)
            return
        }
        if asset.mediaType == PHAssetMediaType.video {
            let options = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (avAsset, avAudioMix, info) in
                let urlAsset = avAsset as! AVURLAsset
                OperationQueue.main.addOperation({
                    success(urlAsset.url)
                })
            })
        } else {
            OperationQueue.main.addOperation({
                failure(SDPhotosHelper.assetNotFoundError)
            })
        }
    }
    
    //MARK:- Private helper methods
    
    fileprivate static func getAsset(fromAlbum album:String,
                                     withLocalIdentifier localIdentifier:String) -> PHAsset? {
        /*The below code is commented due to a bug from Apple :
         https://forums.developer.apple.com/thread/17498
         let fetchOptions = PHFetchOptions()
         fetchOptions.predicate = NSPredicate(format: "title = %@", album)
         */
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier],
                                              options: nil)
        guard fetchResult.count > 0 else {
            return nil
        }
        return fetchResult.firstObject
    }
    
    fileprivate static func getAlbum(withName name:String) -> PHAssetCollection? {
        let assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        guard assetCollection.count > 0 else {
            return nil
        }
        var desiredAlbum:PHAssetCollection? = nil
        assetCollection.enumerateObjects({ (assetCollection, index, stop) in
            if let album  = assetCollection as PHAssetCollection? {
                if album.localizedTitle == name {
                    desiredAlbum = album
                    stop.pointee = true
                }
            }
        })
        return desiredAlbum
    }
    
    @objc public static func requestPermissions(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        }
    }
    
}
