//
//  GalleryCollectionViewViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/23/21.
//

import UIKit
import CoreData

class GalleryCollectionViewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var index : Int!
    
    var arrayIndex = [Int]()
    
    var imageViewHidden = true
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var gallery: [Gallery] {
        
        do {
            let fetchrequest = NSFetchRequest<Gallery>(entityName: "Gallery")
            fetchrequest.predicate = NSPredicate(format: "thumbnail != nil")
            fetchrequest.predicate = NSPredicate(format: "fullSize != nil")
            let sort = NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)
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
            
            if !arrayIndex.contains(indexPath!.row) {
                arrayIndex.append(indexPath!.row)
            }
            
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
        collectionView!.reloadData()
        collectionView!.collectionViewLayout.invalidateLayout()
        collectionView!.layoutSubviews()
        
        noImagesStoredBackground()
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        imageViewHidden = true
        if #available(iOS 14.0, *) {
            collectionView.isEditing = false
        }
    }
   
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let padding: CGFloat =  160
            let collectionViewSize = collectionView.frame.size.width - padding
            
            return CGSize(width: collectionViewSize/3, height: 350)
        }
        else {
            let padding: CGFloat =  80
            let collectionViewSize = collectionView.frame.size.width - padding
            
            return CGSize(width: collectionViewSize/2, height: 170)
        }
        return CGSize(width: (collectionView.frame.size.width - 80)/2, height: 170)
        }*/

    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if #available(iOS 14.0, *) {
            if collectionView.isEditing == true {
                
                if arrayIndex.contains(indexPath.row) {
                    arrayIndex = arrayIndex.filter { $0 != indexPath.row }
                }
                
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
                
                if !arrayIndex.contains(indexPath.row) {
                    arrayIndex.append(indexPath.row)
                }
                
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
                index = indexPath.row
                performSegue(withIdentifier: "viewImage", sender: nil)
            }
        } else {
            index = indexPath.row
            performSegue(withIdentifier: "viewImage", sender: nil)
        }
    
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gallery.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let galleryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as! GalleryCollectionViewCell
        
        if arrayIndex.contains(indexPath.row) {
            galleryCell.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            galleryCell.backgroundColor = .systemGray2
            galleryCell.checkMark.image = UIImage(systemName: "checkmark.seal.fill")
        }
        else {
            galleryCell.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            galleryCell.backgroundColor = .systemGray5
            galleryCell.checkMark.image = UIImage(systemName: "checkmark.seal")
        }
        
        
        if imageViewHidden == true {
            galleryCell.checkMark.isHidden = true
        }
        else {
            galleryCell.checkMark.isHidden = false
        }
        
            if gallery[indexPath.row].thumbnail != nil && gallery[indexPath.row].fullSize != nil {
                
                //galleryCell.layer.shadowColor = UIColor.black.cgColor
                //galleryCell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                //galleryCell.layer.shadowRadius = 4.0
                //galleryCell.layer.shadowOpacity = 0.75
                //galleryCell.layer.shadowPath = UIBezierPath(roundedRect: galleryCell.bounds, cornerRadius: 10).cgPath
                
                galleryCell.galleryImage.image = UIImage(data: gallery[indexPath.row].thumbnail!)
                galleryCell.galleryImage.contentMode = .scaleAspectFill
                galleryCell.galleryImage.layer.borderWidth = 3
                galleryCell.galleryImage.layer.borderColor = setBorderColor().cgColor
                if gallery[indexPath.row].name == nil || gallery[indexPath.row].name == "" {
                    galleryCell.nameLabel.text = "Unknown"
                }
                else {
                    galleryCell.nameLabel.text = gallery[indexPath.row].name
                }
            }
            else {
                galleryCell.isHidden = true
                galleryCell.layer.borderColor = UIColor.white.cgColor
            }
        return galleryCell
    }
    
    func setBorderColor() -> UIColor {
        return UserDefaults().colorForKey(key: "accentColor")!
    }
    
    @IBAction func shareButton(_ sender: UIBarButtonItem) {
        
        var alert = UIAlertController()
        if UIDevice.current.userInterfaceIdiom == .pad {
        alert = UIAlertController(title: "Share", message: "What would you like to share?", preferredStyle: .actionSheet)
            let popover = alert.popoverPresentationController
            popover!.sourceView = self.view
            popover?.barButtonItem = sender as UIBarButtonItem
        }
        else {
            alert = UIAlertController(title: "Share", message: "What would you like to share?", preferredStyle: .actionSheet)
        }
        var images: String!
        var names: String!
        if collectionView.indexPathsForSelectedItems?.count == 1 {
            images = "Image"
            names = "Name"
        }
        else {
            images = "Images"
            names = "Names"
        }
        if collectionView.indexPathsForSelectedItems?.count == 1 {
        alert.addAction(UIAlertAction(title: "Image and Name", style: .default, handler: { [self] _ in
            
            var names = ""
            var images : UIImage!
        
        // set up activity view controller
       
        for i in collectionView.indexPathsForSelectedItems! {
            images = UIImage(data: gallery[i.row].fullSize!)
            
            let name = gallery[i.row].name
            if name == nil {
                  
                    names.append("Unknown")
            
            }
            else {
               
                    names = gallery[i.row].name!
            }
            
        }
            
            let activityViewController = UIActivityViewController(activityItems: [images!, names], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
     
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
        activityViewController.completionWithItemsHandler = { [self]
            (activity, success, items, error) in
            if #available(iOS 14.0, *) {
                collectionView.isEditing = false
            }
            imageViewHidden = false
            arrayIndex.removeAll()
            shareButton.isEnabled = false
            for i in (0...gallery.count - 1).reversed() {
                self.collectionView.layoutIfNeeded()
                if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? GalleryCollectionViewCell {
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
        }))
        }
        alert.addAction(UIAlertAction(title: images, style: .default, handler: { [self] _ in
            var images = [UIImage]()
            
            // set up activity view controller
            
            for i in collectionView.indexPathsForSelectedItems! {
                images.append(UIImage(data: gallery[i.row].fullSize!)!)
               
            }
            
            let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
            
            activityViewController.completionWithItemsHandler = { [self]
                (activity, success, items, error) in
                if #available(iOS 14.0, *) {
                    collectionView.isEditing = false
                }
                imageViewHidden = false
                arrayIndex.removeAll()
                shareButton.isEnabled = false
                for i in (0...gallery.count - 1).reversed() {
                    self.collectionView.layoutIfNeeded()
                    if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? GalleryCollectionViewCell {
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
        }))
        alert.addAction(UIAlertAction(title: names, style: .default, handler: { [self] _ in
            
            var names = ""
            
            // set up activity view controller
            var x = 0
            for i in collectionView.indexPathsForSelectedItems! {
                let name = gallery[i.row].name
                if name == nil {
                    if x >= 1 {
                        names = names + ", Unknown"
                    }
                    else {
                        names = names + "Unknown"
                    }
                }
                else {
                    if x >= 1 {
                        names = names + ", \(gallery[i.row].name!)"
                    }
                    else {
                        names = names + gallery[i.row].name!
                    }
                }
                x += 1
            }
    
            let item : [Any] = [names as Any]
            
            let activityViewController = UIActivityViewController(activityItems: item, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
         
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
            
            activityViewController.completionWithItemsHandler = { [self]
                (activity, success, items, error) in
                if #available(iOS 14.0, *) {
                    collectionView.isEditing = false
                }
                imageViewHidden = false
                arrayIndex.removeAll()
                shareButton.isEnabled = false
                for i in (0...gallery.count - 1).reversed() {
                    self.collectionView.layoutIfNeeded()
                    if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? GalleryCollectionViewCell {
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
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [self] _ in
            if #available(iOS 14.0, *) {
                collectionView.isEditing = false
            }
            imageViewHidden = false
            arrayIndex.removeAll()
            shareButton.isEnabled = false
            for i in (0...gallery.count - 1).reversed() {
                self.collectionView.layoutIfNeeded()
                if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? GalleryCollectionViewCell {
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
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage" {
            let dvc = segue.destination as! ImageViewController
            
            dvc.newImage = UIImage(data: gallery[index].fullSize!)
            dvc.name = gallery[index].name
            dvc.index = index
        }
    }
}
