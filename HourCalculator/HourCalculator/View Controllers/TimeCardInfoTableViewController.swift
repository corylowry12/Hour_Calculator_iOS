//
//  TimeCardInfoTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 8/6/21.
//

import Foundation
import UIKit
import CoreData
import GoogleMobileAds

extension UIImage {
    class func imageWithLabel(label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

class TimeCardInfoTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    lazy var bannerView: GADBannerView! = GADBannerView(adSize: kGADAdSizeBanner)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var weekOfLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let userDefaults = UserDefaults.standard
    
    var cameraIsBeingUsed = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var timeCards: [TimeCards] {
        
        do {
            var sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            let fetchrequest = NSFetchRequest<TimeCards>(entityName: "TimeCards")
            if userDefaults.integer(forKey: "timeCardsSort") == 0 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 1 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.week), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 2 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 3 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.total), ascending: false)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 4 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: true)
            }
            else if userDefaults.integer(forKey: "timeCardsSort") == 5 {
                sort = NSSortDescriptor(key: #keyPath(TimeCards.name), ascending: false)
            }
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCards]()
        
    }
    
    var timeCard: [TimeCardInfo] {
        
        do {
            let fetchrequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            let predicate = userDefaults.value(forKey: "id")
            fetchrequest.predicate = NSPredicate(format: "id_number == %@", predicate as! CVarArg)
            let sort = NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: false)
            fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCardInfo]()
        
    }
    
    var gallery: [Gallery] {
        
        do {
            let fetchrequest = NSFetchRequest<Gallery>(entityName: "Gallery")
            let predicate = userDefaults.value(forKey: "id")
            fetchrequest.predicate = NSPredicate(format: "id_number == %@", predicate as! CVarArg)
            let sort = NSSortDescriptor(key: #keyPath(Gallery.date), ascending: false)
            fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [Gallery]()
        
    }
    
    var timeCardInfo: [TimeCardInfo] {
        
        do {
            let fetchrequest = NSFetchRequest<TimeCardInfo>(entityName: "TimeCardInfo")
            //let sort = NSSortDescriptor(key: #keyPath(TimeCardInfo.date), ascending: false)
            //fetchrequest.sortDescriptors = [sort]
            
            return try context.fetch(fetchrequest)
            
        } catch {
            
            print("Couldn't fetch data")
            
        }
        
        return [TimeCardInfo]()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        textField.delegate = self
        
        addBannerViewToView(bannerView)
        
        bannerView.adUnitID = "ca-app-pub-4546055219731501/2396708566"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        previousButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75).cgColor
        previousButton.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        previousButton.layer.shadowOpacity = 1.0
        previousButton.layer.shadowRadius = 5.0
        previousButton.layer.masksToBounds = false
        
        nextButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75).cgColor
        nextButton.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        nextButton.layer.shadowOpacity = 1.0
        nextButton.layer.shadowRadius = 5.0
        nextButton.layer.masksToBounds = false
        
    }
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if userDefaults.string(forKey: "name") == nil || userDefaults.string(forKey: "name")?.trimmingCharacters(in: .whitespaces) == "" ||  userDefaults.string(forKey: "name") == "Unknown" {
            textField.text = "Unknown"
            self.navigationItem.title = "Time Card Info"
        }
        else {
            textField.text = userDefaults.string(forKey: "name")
            self.navigationItem.title = userDefaults.string(forKey: "name")
        }
        let total = round(Double(userDefaults.string(forKey: "total")!)! * 100.0) / 100.0
        totalHoursLabel.text = "Total Hours: \(total)"
        if timeCards[userDefaults.value(forKey: "index") as! Int].numberBeingExported == 1 {
            weekOfLabel.text = "Day Of: \(userDefaults.string(forKey: "week") ?? "Unknown")"
        }
        else {
            weekOfLabel.text = "Week Of: \(userDefaults.string(forKey: "week") ?? "Unknown")"
        }
        
        textField.clearButtonMode = .always
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        
        if userDefaults.integer(forKey: "accent") == 0 {
            textField.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            textField.backgroundColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            textField.backgroundColor = UIColor(rgb: 0x347deb)
            
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            textField.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            textField.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
        textField.tintColor = UIColor.systemGray2
        view.backgroundColor = tableView.backgroundColor
        
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(tapRecognizer)
        
        if timeCard[timeCard.count - 1].image != nil {
            DispatchQueue.main.async { [self] in
                //let resized = self.resizeImage(image: UIImage(data: timeCard[timeCard.count - 1].image!)!, targetSize: CGSize(width: imageView.frame.width, height: imageView.frame.height))
                
                UIView.transition(with: self.imageView,
                                  duration: 1.0,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: { [self] in
                                    imageView.image = UIImage(data: timeCard[timeCard.count - 1].image!)
                                  },
                                  completion: nil)
           }
        }
        else {
            setImageView()
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
    
    func setImageView() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height))
        label.text = "There is currently no\nimage stored for this entry"
        imageView.image = UIImage.imageWithLabel(label: label)
    }
    
    var newImageView = UIImageView()
    
    @objc func imageTapped() {
        
        if timeCard[timeCard.count - 1].image != nil {
            let alert = UIAlertController(title: "Choose", message: "What would you like to do?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "View Image", style: .default, handler: { [self] _ in
                newImageView.isUserInteractionEnabled = true
                self.newImageView.frame = UIScreen.main.bounds
                let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage))
                newImageView.addGestureRecognizer(tap)
                self.view.addSubview(newImageView)
                self.newImageView.contentMode = .scaleAspectFit
                UIView.transition(with: self.newImageView,
                                  duration: 0.50,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: {
                                        //let resized = self.resizeImage(image: UIImage(data: timeCard[timeCard.count - 1].image!)!, targetSize: CGSize(width:  newImageView.frame.width, height: newImageView.frame.height))
                                  
                                        newImageView.image = UIImage(data: timeCard[timeCard.count - 1].image!)
                    
                                        self.newImageView.backgroundColor = .black
                                        self.navigationController?.isNavigationBarHidden = true
                                        self.tabBarController?.tabBar.isHidden = true
                                  },
                                  completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Remove Image", style: .default, handler: { [self] _ in
                setImageView()
                timeCard[timeCard.count - 1].image = nil
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }))
            alert.addAction(UIAlertAction(title: "Choose a new image", style: .default, handler: { _ in
                let alert = UIAlertController(title: "Choose a new image", message: "What would you like to do?", preferredStyle: .alert)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { _ in
                        
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.delegate = self;
                        imagePickerController.sourceType = .camera
                        self.present(imagePickerController, animated: true, completion: nil)
                        self.cameraIsBeingUsed = true
                    }))
                }
                alert.addAction(UIAlertAction(title: "Choose a photo", style: .default, handler: { _ in
                    
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self;
                    imagePickerController.sourceType = .photoLibrary
                    self.present(imagePickerController, animated: true, completion: nil)
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Choose a new image", message: "What would you like to do?", preferredStyle: .alert)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { _ in
                    
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self;
                    imagePickerController.sourceType = .camera
                    self.present(imagePickerController, animated: true, completion: nil)
                    self.cameraIsBeingUsed = true
                }))
            }
            alert.addAction(UIAlertAction(title: "Choose a photo", style: .default, handler: { _ in
                
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self;
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func dismissFullScreenImage() {
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        newImageView.removeFromSuperview()
        newImageView.image = nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        cameraIsBeingUsed = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imageView.image = image
        
        //imageView.backgroundColor = UIColor.clear
        self.dismiss(animated: true, completion: nil)
        
        DispatchQueue.main.async { [self] in
            let jpegData = image?.jpegData(compressionQuality: 1.0)
            //let resize = resizeImage(image: UIImage(data: jpegData!)!, targetSize: CGSize(width: 1000, height: 1000))
        timeCard[timeCard.count - 1].image = jpegData
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
            if cameraIsBeingUsed == true {
                UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeCard.count
    }
    
    private var finishedLoadingInitialTableCells = false
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            
            var lastInitialDisplayableCell = false
            
            if timeCards.count > 0 && !finishedLoadingInitialTableCells {
                if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows,
                   let lastIndexPath = indexPathsForVisibleRows.last, lastIndexPath.row == indexPath.row {
                    lastInitialDisplayableCell = true
                }
            }
            
            if !finishedLoadingInitialTableCells {
                
                if lastInitialDisplayableCell {
                    finishedLoadingInitialTableCells = true
                }
                
                cell.transform = CGAffineTransform(translationX: 0, y: tableView.rowHeight/2)
                cell.alpha = 0
                
                UIView.animate(withDuration: 1.0, delay: 0.0, options: [.transitionCrossDissolve], animations: {
                    cell.transform = CGAffineTransform(translationX: 0, y: 0)
                    cell.alpha = 1
                }, completion: nil)
            }
    }
    
    @IBAction func textFieldClose(_ sender: UITextField) {
        if sender.text != "" && sender.text != nil {
            timeCards[userDefaults.integer(forKey: "index")].name = sender.text?.trimmingCharacters(in: .whitespaces)
            timeCardInfo[timeCardInfo.count - 1].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = nil
            timeCardInfo[timeCardInfo.count - 1].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hourItems = timeCard[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCardCell", for: indexPath) as! TimeCardInfoTableViewCell
            
            let inTime = hourItems.intime
            let outTime = hourItems.outtime
            let totalHours = hourItems.total_hours
            let date = hourItems.date!
            
            cell.inTimeLabel.text = "In Time: \(inTime ?? "Unknown")"
            cell.outTimeLabel.text = "Out Time: \(outTime ?? "Unknown")"
            cell.totalHoursLabel.text = "Total Hours: \(totalHours ?? "Unknown")"
            cell.dateLabel.text = "Date: \(date)"
        
        return cell
    }
    @IBAction func textFieldTextChanged(_ sender: UITextField) {
        
        if sender.text != "" && sender.text != nil {
            timeCards[userDefaults.integer(forKey: "index")].name = sender.text
            timeCardInfo[timeCardInfo.count - 1].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = nil
            timeCardInfo[timeCardInfo.count - 1].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        
        if timeCard[timeCard.count - 1].image != nil {
            let alert = UIAlertController(title: "Warning", message: "There is already an image stored. What would you like to do?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "View Image", style: .default, handler: { [self] _ in
    
                newImageView.isUserInteractionEnabled = true
                self.newImageView.frame = UIScreen.main.bounds
                let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage))
                newImageView.addGestureRecognizer(tap)
                self.view.addSubview(newImageView)
                self.newImageView.contentMode = .scaleAspectFit
                UIView.transition(with: self.newImageView,
                                  duration: 0.50,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: {
                                        //let resized = self.resizeImage(image: UIImage(data: timeCard[timeCard.count - 1].image!)!, targetSize: CGSize(width:  newImageView.frame.width, height: newImageView.frame.height))
                                  
                                        newImageView.image = UIImage(data: timeCard[timeCard.count - 1].image!)
                    
                                        self.newImageView.backgroundColor = .black
                                        self.navigationController?.isNavigationBarHidden = true
                                        self.tabBarController?.tabBar.isHidden = true
                                  },
                                  completion: nil)
                
            }))
            alert.addAction(UIAlertAction(title: "Remove Image", style: .default, handler: { [self] _ in
                setImageView()
                timeCard[timeCard.count - 1].image = nil
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }))
            alert.addAction(UIAlertAction(title: "Choose a new image", style: .default, handler: { _ in
                let alert = UIAlertController(title: "Choose a new image", message: "What would you like to do?", preferredStyle: .alert)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { _ in
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.delegate = self;
                        imagePickerController.sourceType = .camera
                        self.present(imagePickerController, animated: true, completion: nil)
                        self.cameraIsBeingUsed = true
                    }))
                }
                alert.addAction(UIAlertAction(title: "Choose a photo", style: .default, handler: { _ in
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self;
                    imagePickerController.sourceType = .photoLibrary
                    self.present(imagePickerController, animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Choose", message: "What would you like to do?", preferredStyle: .alert)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { _ in
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self;
                    imagePickerController.sourceType = .camera
                    self.present(imagePickerController, animated: true, completion: nil)
                    self.cameraIsBeingUsed = true
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Choose a photo", style: .default, handler: { _ in
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self;
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    func addBannerViewToView(_ bannerView: GADBannerView) {
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .bottom,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        addBannerViewToView(bannerView)
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
}
