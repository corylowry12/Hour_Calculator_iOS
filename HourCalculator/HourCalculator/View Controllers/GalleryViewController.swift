//
//  GalleryViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/21/21.
//

import Foundation
import UIKit
import CoreData

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var timeCardInfo: [TimeCardInfo] {
        
        do {
            let fetchrequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            //let predicate = userDefaults.value(forKey: "id")
            fetchrequest.predicate = NSPredicate(format: "image != nil")
            //let sort = NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: false)
            //fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCardInfo]()
        
    }
    
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        /*let p = longPressGesture.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: p)
        if indexPath == nil {
            print("Long press failed")
        }
        else if longPressGesture.state == UIGestureRecognizer.State.began {
            //let currentCell = collectionView.cellForItem(at: indexPath!) as! GalleryCollectionViewCell
            collectionView.cellForItem(at: indexPath!)?.isSelected = true
            //currentCell.backgroundColor = UIColor.systemGray2
            //currentCell.checkMarkImageView.isHidden = false
            //currentCell.checkMarkImageView.image = UIImage(systemName: "checkmark.seal.fill")
            
            if collectionView.indexPathsForSelectedItems != nil {
                shareButton.isEnabled = true
            }
            
            UIButton.animate(withDuration: 0.08,
                             animations: { [self] in
                                collectionView.cellForItem(at: indexPath!)!.transform = CGAffineTransform(scaleX: 0.975, y: 0.96)
                             },
                             completion: { finish in
                                UIButton.animate(withDuration: 0.08, animations: { [self] in
                                    collectionView.cellForItem(at: indexPath!)!.transform = CGAffineTransform.identity
                                })
                             })*/
        
        if (gestureRecognizer.state != .began) {
                return
            }

            let p = gestureRecognizer.location(in: collectionView)

            if let indexPath = collectionView?.indexPathForItem(at: p) {
                if #available(iOS 14.0, *) {
                    collectionView.isEditing = true
                }
                let currentCell = collectionView.cellForItem(at: indexPath) as! GalleryCollectionViewCell
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
                print("collection: \(collectionView.indexPathsForSelectedItems)")
                currentCell.backgroundColor = UIColor.systemGray2
                currentCell.checkMarkImageView.isHidden = false
                currentCell.checkMarkImageView.image = UIImage(systemName: "checkmark.seal.fill")
                
                UIButton.animate(withDuration: 0.08,
                                 animations: { [self] in
                                    collectionView.cellForItem(at: indexPath)!.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                                 },
                                 completion: nil)
            }
        
        if collectionView.indexPathsForSelectedItems != nil {
            shareButton.isEnabled = true
        }
        }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.allowsMultipleSelection = true
        if #available(iOS 14.0, *) {
            collectionView.allowsMultipleSelectionDuringEditing = true
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        shareButton.isEnabled = false
        
        noHoursStoredBackground()
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
            self.collectionView.reloadData()
        }, completion: nil)
    }
    
    func noHoursStoredBackground() {
        if timeCardInfo.count == 0 {
            
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.accessibilityFrame.size.width, height: self.accessibilityFrame.size.height))
            messageLabel.text = "There are currently no images stored"
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
            messageLabel.sizeToFit()
            self.collectionView.backgroundView = messageLabel;
            
        }
        else {
            collectionView.backgroundView = nil
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    private var finishedLoadingInitialTableCells = false
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        DispatchQueue.main.async { 
            
            cell.alpha = 0
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0)
                cell.alpha = 1
            }, completion: nil)
        }
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeCardInfo.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if #available(iOS 14.0, *) {
            if collectionView.isEditing == true {
                let currentCell = collectionView.cellForItem(at: indexPath) as! GalleryCollectionViewCell
                collectionView.cellForItem(at: indexPath)?.isSelected = true
                currentCell.backgroundColor = UIColor.systemGray2
                currentCell.checkMarkImageView.isHidden = false
                currentCell.checkMarkImageView.image = UIImage(systemName: "checkmark.seal.fill")
                
                UIButton.animate(withDuration: 0.08,
                                 animations: {
                                    collectionView.cellForItem(at: indexPath)!.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                                 },
                                 completion: nil)
                
                if collectionView.indexPathsForSelectedItems != nil {
                    shareButton.isEnabled = true
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let currentCell = collectionView.cellForItem(at: indexPath) as! GalleryCollectionViewCell
        collectionView.cellForItem(at: indexPath)?.isSelected = false
        currentCell.backgroundColor = UIColor.clear
        currentCell.checkMarkImageView.isHidden = true
        
        print("item clicked")
        
        UIButton.animate(withDuration: 0.08,
                         animations: {
                            collectionView.cellForItem(at: indexPath)!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                         },
                         completion: nil)
        
        if collectionView.indexPathsForSelectedItems == [] {
            shareButton.isEnabled = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionImageCell", for: indexPath) as! GalleryCollectionViewCell
        DispatchQueue.main.async { [self] in
            if timeCardInfo[indexPath.row].image != nil {
                let resized = self.resizeImage(image: UIImage(data: timeCardInfo[indexPath.row].image!)!, targetSize: CGSize(width: cell.imageView.frame.width, height: cell.imageView.frame.height))
                cell.imageView.image = resized
            }
            else {
                cell.isHidden = true
                cell.contentView.isHidden = true
            }
        }
        return cell
    }
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        
        let currentCell = collectionView.indexPathsForSelectedItems
        
        var images = [UIImage]()
        
        for i in currentCell! {
            let imageCell = collectionView.cellForItem(at: i) as! GalleryCollectionViewCell
            images.append(imageCell.imageView.image!)
        }
        
        print("images : \(images.count)")
        // set up activity view controller
        //let imageToShare = [ collectionView.indexPathsForSelectedItems ]
        let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
