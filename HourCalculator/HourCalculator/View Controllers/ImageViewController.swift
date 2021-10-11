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
    
    var newImage: UIImage!
    var name: String!
    var index: Int!
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if name != nil {
            self.title = name
        }
        else {
            self.title = "Unknown"
        }
        
        if index != -1 {
            let swipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.LeftSwipeAction(_:)))
            swipeGestureLeft.direction = .left
            self.imageView.addGestureRecognizer(swipeGestureLeft)
            
            let swipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(self.RightSwipeAction(_:)))
            swipeGestureRight.direction = .right
            self.imageView.addGestureRecognizer(swipeGestureRight)
        }
        
        DispatchQueue.main.async { [self] in
            
            imageView.image = newImage
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.isUserInteractionEnabled = true
        
    }
    
    @objc func RightSwipeAction( _ recognizer : UISwipeGestureRecognizer){
        
        if recognizer.direction == .right{
            var frame = imageView.frame
            print("Right Swiped")
            if (gallery.count - 1) >= index && index > 0 && gallery[index - 1].id_number != 0 {
                frame.origin.x += 400.0
                index = index - 1
                print("swiped right")
                if gallery[index].fullSize == gallery[index + 1].fullSize {
                    imageView.image = nil
                    imageView.image = UIImage(data: gallery[index].fullSize!)
                }
                else {
                    imageView.image = UIImage(data: gallery[index].fullSize!)
                }
                
                if gallery[index].name != nil {
                    self.title = gallery[index].name
                }
                else {
                    self.title = "Unknown"
                }
                
                UIView.animate(withDuration: 0.50) {
                    self.imageView.frame = frame
                }
                
                let swipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(self.RightSwipeAction(_:)))
                swipeGestureRight.direction = .right
                self.imageView.addGestureRecognizer(swipeGestureRight)
            }
            
            else {
                let backgroundColor = view.backgroundColor
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.backgroundColor = UIColor.red
                },
                completion: {_ in
                    UIView.animate(withDuration: 0.5, animations: {
                        self.view.backgroundColor = backgroundColor
                    },
                    completion: nil)
                })
            }
        }
    }
    
    @objc func LeftSwipeAction( _ recognizer : UISwipeGestureRecognizer){
        
        var frame = imageView.frame
        
        if recognizer.direction == .left {
            print("Left Swiped")
            
            if (gallery.count - 1) > index && gallery[index + 1].id_number != 0 {
                frame.origin.x -= 400.0
                index = index + 1
                
                if gallery[index].fullSize == gallery[index - 1].fullSize {
                    imageView.image = nil
                    imageView.image = UIImage(data: gallery[index].fullSize!)
                }
                else {
                    imageView.image = UIImage(data: gallery[index].fullSize!)
                }
                
                UIView.animate(withDuration: 0.50) {
                    self.imageView.frame = frame
                }
                
                if gallery[index].name != nil {
                    self.title = gallery[index].name
                }
                else {
                    self.title = "Unknown"
                }
                
                let swipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.LeftSwipeAction(_:)))
                swipeGestureLeft.direction = .left
                self.imageView.addGestureRecognizer(swipeGestureLeft)
            }
            
            else {
                let backgroundColor = view.backgroundColor
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.backgroundColor = UIColor.red
                },
                completion: {_ in
                    UIView.animate(withDuration: 0.5, animations: {
                        self.view.backgroundColor = backgroundColor
                    },
                    completion: nil)
                })
            }
        }
    }
}
