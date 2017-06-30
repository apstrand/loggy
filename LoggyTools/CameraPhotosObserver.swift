//
//  CameraPhotosObserver.swift
//  LoggyTools
//
//  Created by Peter Strand on 2017-06-30.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation
import Photos

public class CameraPhotosObserver {
  
  public typealias Callback = (CLLocation, Date?) -> Void
  
  let callback : Callback
  public init(_ cb : @escaping Callback) {
    self.callback = cb
    self.photoObserver = PhotoObserver(self)
    PHPhotoLibrary.shared().register(self.photoObserver!)
    
    fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
    
    fetchResult?.enumerateObjects( {
      obj, ix, stop in
      self.allPhotos.append(PHAsset.fetchAssets(in: obj, options: nil))
    })
  }
  var fetchResult : PHFetchResult<PHAssetCollection>!
  var allPhotos: [PHFetchResult<PHAsset>] = []
  var photoObserver : PHPhotoLibraryChangeObserver?
  var alreadyProcessed : Set<String> = []
  
  class PhotoObserver : NSObject, PHPhotoLibraryChangeObserver {
    let parent : CameraPhotosObserver
    init(_ p : CameraPhotosObserver) {
      parent = p
    }
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
      //      print("Photo change \(changeInstance)")
      
      
      //      let changes = changeInstance.changeDetails(for: parent.fetchResult)
      //      print(" details: \(changes)")
      
      var allNew : [PHAsset] = []
      for ix in 0..<parent.allPhotos.count {
        let obj = parent.allPhotos[ix]
        if let changes = changeInstance.changeDetails(for: obj) {
          allNew.append(contentsOf: changes.insertedObjects)
          parent.allPhotos[ix] = changes.fetchResultAfterChanges
        }
      }
      
      DispatchQueue.main.sync {
        for asset in allNew {
          if !parent.alreadyProcessed.contains(asset.localIdentifier) {
            print(" new: \(asset.localIdentifier)")
            if let location = asset.location {
              parent.callback(location, asset.creationDate)
            }
            parent.alreadyProcessed.insert(asset.localIdentifier)
          } else {
            print(" old: \(asset.localIdentifier)")
          }
        }
      }
      
    }
    
  }
  
}
