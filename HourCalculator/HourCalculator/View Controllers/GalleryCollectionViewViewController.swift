//
//  GalleryCollectionViewViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/23/21.
//

import Foundation
import UIKit
import CoreData

class GalleryCollectionViewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var imageViewHidden = true
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var gallery: [Gallery] {
        
        do {
            let fetchrequest = NSFetchRequest<Gallery>(entityName: "Gallery")
            fetchrequest.predicate = NSPredicate(format: "thumbnail != nil")
            fetchrequest.predicate = NSPredicate(format: "fullSize != nil")
            let sort = NSSortDescriptor(key: #keyPath(Gallery.date), ascending: true)
            fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [Gallery]()
        
    }
    
    func noImagesStoredBackground() {
        if gallery.count == 0 {
            
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
    
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        let p = longPressGesture.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: p)
        if indexPath == nil {
            print("Long press failed")
        }
        else if longPressGesture.state == UIGestureRecognizer.State.began {
            if #available(iOS 14.0, *) {
                collectionView.isEditing = true
            }
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            imageViewHidden = false
            let cell = collectionView.cellForItem(at: indexPath!) as! GalleryCollectionViewCell
            
            imageViewHidden = false
            shareButton.isEnabled = true
            for i in 0...gallery.count - 1 {
                
                if let cell = collectionView.cellForItem(at: [0, i] as IndexPath) as? GalleryCollectionViewCell {
                    cell.checkMark.isHidden = false
                }
            }
            UIButton.animate(withDuration: 0.05,
                             animations: {
                                cell.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                                cell.backgroundColor = .systemGray2
                                cell.checkMark.image = UIImage(systemName: "checkmark.seal.fill")
                             },
                             completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.allowsSelection = true
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
        collectionView.reloadData()
        print("hello world: \(gallery.count)")
        
        noImagesStoredBackground()
    }
    
    private var finishedLoadingInitialTableCells = false
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if gallery.count > 0 {
            DispatchQueue.main.async {
    
                    cell.alpha = 0
                    
                    UIView.animate(withDuration: 1.0, delay: 0.0, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: {
                        cell.transform = CGAffineTransform(translationX: 0, y: 0)
                        cell.alpha = 1
                    }, completion: nil)
                }
            }
        }
    
    let newImageView = UIImageView()
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if #available(iOS 14.0, *) {
            if collectionView.isEditing == true {
                let cell = collectionView.cellForItem(at: indexPath) as! GalleryCollectionViewCell
                UIButton.animate(withDuration: 0.05,
                                 animations: {
                                    cell.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                                    cell.backgroundColor = .systemGray5
                                    cell.checkMark.image = UIImage(systemName: "checkmark.seal")
                                 },
                                 completion: nil)
            }
        }
        if collectionView.indexPathsForSelectedItems == [] {
            if #available(iOS 14.0, *) {
                collectionView.isEditing = false
            }
            for i in 0...gallery.count - 1 {
                
                if let cell = collectionView.cellForItem(at: [0, i] as IndexPath) as? GalleryCollectionViewCell {
                    cell.checkMark.isHidden = true
                }
            }
            shareButton.isEnabled = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if #available(iOS 14.0, *) {
            if collectionView.isEditing == true {
                let cell = collectionView.cellForItem(at: indexPath) as! GalleryCollectionViewCell
                UIButton.animate(withDuration: 0.05,
                                 animations: {
                                    cell.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                                    cell.backgroundColor = .systemGray2
                                    cell.checkMark.image = UIImage(systemName: "checkmark.seal.fill")
                                    cell.isSelected = true
                                 },
                                 completion: nil)
            }
            else {
                newImageView.isUserInteractionEnabled = true
                self.newImageView.frame = UIScreen.main.bounds
                let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage))
                newImageView.addGestureRecognizer(tap)
                self.view.addSubview(newImageView)
                self.newImageView.contentMode = .scaleAspectFit
                UIView.transition(with: view,
                                  duration: 0.50,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: { [self] in
                                    //let resized = self.resizeImage(image: UIImage(data: timeCard[timeCard.count - 1].image!)!, targetSize: CGSize(width:  newImageView.frame.width, height: newImageView.frame.height))
                                    
                                    newImageView.image = UIImage(data: gallery[indexPath.row].fullSize!)
                                    
                                    self.newImageView.backgroundColor = .black
                                    self.navigationController?.isNavigationBarHidden = true
                                    self.tabBarController?.tabBar.isHidden = true
                                  },
                                  completion: nil)
                print("the index is \(indexPath.row)")
            }
        }
    }
    
    @objc func dismissFullScreenImage() {
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        newImageView.removeFromSuperview()
        newImageView.image = nil
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gallery.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as! GalleryCollectionViewCell
        
        if gallery[indexPath.row].thumbnail != nil && gallery[indexPath.row].fullSize != nil {
            let galleryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as! GalleryCollectionViewCell
            
            if imageViewHidden == true {
                galleryCell.checkMark.isHidden = true
            }
            else {
                galleryCell.checkMark.isHidden = false
            }
            
            galleryCell.layer.cornerRadius = 10
            
                galleryCell.backgroundColor = UIColor.systemGray5
            
            galleryCell.layer.shadowColor = UIColor.black.cgColor
            galleryCell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            galleryCell.layer.shadowRadius = 6.0
            galleryCell.layer.shadowOpacity = 0.75
            galleryCell.layer.masksToBounds = false
            galleryCell.layer.shadowPath = UIBezierPath(roundedRect: galleryCell.bounds, cornerRadius: 10).cgPath
            
            galleryCell.galleryImage.image = UIImage(data: gallery[indexPath.row].thumbnail!)
            if gallery[indexPath.row].name == nil {
                galleryCell.nameLabel.text = "Unknown"
            }
            else {
                galleryCell.nameLabel.text = gallery[indexPath.row].name
            }
            return galleryCell
        }
        else {
            cell.isHidden = true
            cell.layer.borderColor = UIColor.white.cgColor
        }
        
        return cell
    }
    @IBAction func shareButton(_ sender: UIBarButtonItem) {
        
        var images = [UIImage]()
        
        // set up activity view controller
        
        for i in collectionView.indexPathsForSelectedItems! {
            images.append(UIImage(data: gallery[i.row].fullSize!)!)
            print("is is equal to: \(i)")
            
        }
        let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
        activityViewController.completionWithItemsHandler = { [self]
            (activity, success, items, error) in
            for i in 0...gallery.count - 1 {
                let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as! GalleryCollectionViewCell
                UIButton.animate(withDuration: 0.05,
                                 animations: {
                                    cell.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                                    cell.backgroundColor = .systemGray5
                                    cell.checkMark.image = UIImage(systemName: "checkmark.seal")
                                    cell.checkMark.isHidden = true
                                 },
                                 completion: nil)
            }
                }
    }
}
