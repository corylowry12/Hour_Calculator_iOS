//
//  ImageViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/25/21.
//

import Foundation
import UIKit
import CoreData

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var placeholderThumbnail: UIImage?
    var fullImageData: Data?
    var newImage: UIImage?
    var name: String?
    var index: Int = -1
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    lazy var gallery: [Gallery] = {
        guard index != -1 else { return [] }
        let fetchrequest = NSFetchRequest<Gallery>(entityName: "Gallery")
        fetchrequest.predicate = NSPredicate(format: "thumbnail != nil AND fullSize != nil")
        let sort = NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)
        fetchrequest.sortDescriptors = [sort]
        do {
            return try context.fetch(fetchrequest)
        } catch {
            print("Couldn't fetch data: \(error)")
            return []
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        
        if let titleName = name, !titleName.trimmingCharacters(in: .whitespaces).isEmpty {
            self.title = titleName
        } else {
            self.title = "Time Card Image"
        }
        
        setupDeleteButton()
        
        // 1. Immediately present thumbnail or existing image with zero delay
        if let immediateImage = newImage ?? placeholderThumbnail {
            imageView.image = immediateImage
        }
        
        // 2. Decode full-resolution image off the main thread
        loadFullImageAsynchronously()
        
        if index != -1 {
            setupSwipeGestures()
        }
    }
    
    private func setupDeleteButton() {
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(confirmDeleteImage)
        )
        deleteButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc private func confirmDeleteImage() {
        let alert = UIAlertController(
            title: "Delete Image",
            message: "Are you sure you want to permanently delete this image?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.performDeleteAndDismiss()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func performDeleteAndDismiss() {
        // Resolve target ID based on entry index or active session ID
        let targetID: Int
        if index != -1 && gallery.indices.contains(index) {
            targetID = Int(gallery[index].id_number)
        } else {
            targetID = userDefaults.integer(forKey: "id")
        }
        
        // 1. Remove Gallery entry
        let galFetch = NSFetchRequest<Gallery>(entityName: "Gallery")
        galFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        if let galleryItems = try? context.fetch(galFetch) {
            for gal in galleryItems {
                context.delete(gal)
            }
        }
        
        // 2. Clear image reference from TimeCardInfo entries
        let infoFetch = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
        infoFetch.predicate = NSPredicate(format: "id_number == %d", targetID)
        if let infoItems = try? context.fetch(infoFetch) {
            for info in infoItems {
                info.image = nil
            }
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        // 3. Post notification for parent views listening to sync
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        
        // 4. Return to previous view
        navigationController?.popViewController(animated: true)
    }
    
    private func loadFullImageAsynchronously() {
        guard let data = fullImageData else { return }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let decoded = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                UIView.transition(with: self.imageView, duration: 0.2, options: .transitionCrossDissolve) {
                    self.imageView.image = decoded
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func setupSwipeGestures() {
        let swipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(LeftSwipeAction(_:)))
        swipeGestureLeft.direction = .left
        imageView.addGestureRecognizer(swipeGestureLeft)
        
        let swipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(RightSwipeAction(_:)))
        swipeGestureRight.direction = .right
        imageView.addGestureRecognizer(swipeGestureRight)
    }
    
    @objc func RightSwipeAction(_ recognizer: UISwipeGestureRecognizer) {
        guard recognizer.direction == .right else { return }
        
        if gallery.indices.contains(index - 1) && gallery[index - 1].id_number != 0 {
            index -= 1
            loadGalleryImageAtIndex(index, translationX: -40)
        } else {
            flashErrorBackground()
        }
    }
    
    @objc func LeftSwipeAction(_ recognizer: UISwipeGestureRecognizer) {
        guard recognizer.direction == .left else { return }
        
        if gallery.indices.contains(index + 1) && gallery[index + 1].id_number != 0 {
            index += 1
            loadGalleryImageAtIndex(index, translationX: 40)
        } else {
            flashErrorBackground()
        }
    }
    
    private func loadGalleryImageAtIndex(_ targetIndex: Int, translationX: CGFloat) {
        let item = gallery[targetIndex]
        self.title = (item.name?.isEmpty == false) ? item.name : "Time Card Image"
        
        if let thumbData = item.thumbnail, let thumb = UIImage(data: thumbData) {
            self.imageView.image = thumb
        }
        
        self.imageView.transform = CGAffineTransform(translationX: translationX, y: 0)
        UIView.animate(withDuration: 0.25) {
            self.imageView.transform = .identity
        }
        
        if let fullData = item.fullSize {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let fullImage = UIImage(data: fullData) else { return }
                DispatchQueue.main.async {
                    if self?.index == targetIndex {
                        self?.imageView.image = fullImage
                    }
                }
            }
        }
    }
    
    private func flashErrorBackground() {
        let originalColor = view.backgroundColor
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.view.backgroundColor = originalColor
            }
        }
    }
}
