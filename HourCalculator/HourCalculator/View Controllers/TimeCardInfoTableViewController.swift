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
        
        let userDefaults = UserDefaults.standard
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        if userDefaults.integer(forKey: "accent") == 0 {
            label.textColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            label.textColor = UIColor(rgb: 0x7841c4)
            
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            label.textColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            label.textColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            label.textColor = UIColor(rgb: 0xc41d1d)
        }
        
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
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var image : UIImage!
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        if timeCards[userDefaults.integer(forKey:"index")].name == nil || timeCards[userDefaults.integer(forKey:"index")].name?.trimmingCharacters(in: .whitespaces) == "" ||  timeCards[userDefaults.integer(forKey:"index")].name == "Unknown" {
            textField.text = "Unknown"
            self.navigationItem.title = "Time Card Info"
        }
        else {
            textField.text = timeCards[userDefaults.integer(forKey:"index")].name
            self.navigationItem.title = timeCards[userDefaults.integer(forKey:"index")].name
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
            previousButton.backgroundColor = UIColor(rgb: 0x26A69A)
            nextButton.backgroundColor = UIColor(rgb: 0x26A69A)
        }
        else if userDefaults.integer(forKey: "accent") == 1 {
            textField.backgroundColor = UIColor(rgb: 0x7841c4)
            previousButton.backgroundColor = UIColor(rgb: 0x7841c4)
            nextButton.backgroundColor = UIColor(rgb: 0x7841c4)
        }
        else if userDefaults.integer(forKey: "accent") == 2 {
            textField.backgroundColor = UIColor(rgb: 0x347deb)
            previousButton.backgroundColor = UIColor(rgb: 0x347deb)
            nextButton.backgroundColor = UIColor(rgb: 0x347deb)
        }
        else if userDefaults.integer(forKey: "accent") == 3 {
            textField.backgroundColor = UIColor(rgb: 0xfc783a)
            previousButton.backgroundColor = UIColor(rgb: 0xfc783a)
            nextButton.backgroundColor = UIColor(rgb: 0xfc783a)
        }
        else if userDefaults.integer(forKey: "accent") == 4 {
            textField.backgroundColor = UIColor(rgb: 0xc41d1d)
            previousButton.backgroundColor = UIColor(rgb: 0xc41d1d)
            nextButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        }
        else if userDefaults.integer(forKey: "accent") == 5 {
            if userDefaults.integer(forKey: "accentRandom") == 0 {
                textField.backgroundColor = UIColor(rgb: 0x26A69A)
                previousButton.backgroundColor = UIColor(rgb: 0x26A69A)
                nextButton.backgroundColor = UIColor(rgb: 0x26A69A)
            }
            else if userDefaults.integer(forKey: "accentRandom") == 1 {
                textField.backgroundColor = UIColor(rgb: 0x7841c4)
                previousButton.backgroundColor = UIColor(rgb: 0x7841c4)
                nextButton.backgroundColor = UIColor(rgb: 0x7841c4)
            }
            else if userDefaults.integer(forKey: "accentRandom") == 2 {
                textField.backgroundColor = UIColor(rgb: 0x347deb)
                previousButton.backgroundColor = UIColor(rgb: 0x347deb)
                nextButton.backgroundColor = UIColor(rgb: 0x347deb)
            }
            else if userDefaults.integer(forKey: "accentRandom") == 3 {
                textField.backgroundColor = UIColor(rgb: 0xfc783a)
                previousButton.backgroundColor = UIColor(rgb: 0xfc783a)
                nextButton.backgroundColor = UIColor(rgb: 0xfc783a)
            }
            else if userDefaults.integer(forKey: "accentRandom") == 4 {
                textField.backgroundColor = UIColor(rgb: 0xc41d1d)
                previousButton.backgroundColor = UIColor(rgb: 0xc41d1d)
                nextButton.backgroundColor = UIColor(rgb: 0xc41d1d)
            }
        }
        
        textField.tintColor = UIColor.systemGray2
        view.backgroundColor = tableView.backgroundColor
        
        imageView.layoutIfNeeded()
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(tapRecognizer)
        
            if timeCard[timeCard.count - 1].image != nil {
                DispatchQueue.main.async { [self] in
                    let resized = self.resizeImage(image: UIImage(data: timeCard[timeCard.count - 1].image!)!, targetSize: CGSize(width: imageView.frame.width, height: imageView.frame.height))
                    
                    UIView.transition(with: self.imageView,
                                      duration: 1.0,
                                      options: [.allowAnimatedContent, .transitionCrossDissolve],
                                      animations: { [self] in
                                        imageView.image = resized
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
        label.text = "There is currently no image stored for this entry"
        imageView.image = UIImage.imageWithLabel(label: label)
    }
    
    @objc func imageTapped() {
        
       // if timeCard.indices.contains(timeCard.count - 1) {
            if timeCard[timeCard.count - 1].image != nil {
                let alert = UIAlertController(title: "Choose", message: "What would you like to do?", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "View Image", style: .default, handler: { [self] _ in
                    
                    image = UIImage(data: timeCard[timeCard.count - 1].image!)
                    performSegue(withIdentifier: "viewImage", sender: nil)
                }))
                alert.addAction(UIAlertAction(title: "Go To Gallery", style: .default, handler: { _ in
                    self.performSegue(withIdentifier: "gallery", sender: self)
                }))
                alert.addAction(UIAlertAction(title: "Choose a new image", style: .default, handler: { _ in
                    let alert = UIAlertController(title: "Choose a new image", message: "What would you like to do?", preferredStyle: .actionSheet)
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
                alert.addAction(UIAlertAction(title: "Remove Image", style: .destructive, handler: { [self] _ in
                    
                    UIView.transition(with: self.imageView,
                                      duration: 1.0,
                                      options: [.allowAnimatedContent, .transitionCrossDissolve],
                                      animations: { [self] in
                                        setImageView()
                                      },
                                      completion: nil)
                    timeCard[timeCard.count - 1].image = nil
                    if gallery.count > 0 {
                        if gallery[0].thumbnail != nil {
                            gallery[0].thumbnail = nil
                        }
                        if gallery[0].date != nil {
                            gallery[0].date = nil
                        }
                        if gallery[0].fullSize != nil {
                            gallery[0].fullSize = nil
                        }
                    }
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        //}
        else {
            let alert = UIAlertController(title: "Choose a new image", message: "What would you like to do?", preferredStyle: .actionSheet)
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        cameraIsBeingUsed = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        let jpegData = image?.jpegData(compressionQuality: 1.0)
        //if timeCard.indices.contains(timeCard.count - 1) {
            
            UIView.transition(with: self.imageView,
                              duration: 1.0,
                              options: [.allowAnimatedContent, .transitionCrossDissolve],
                              animations: { [self] in
                                imageView.image = image
                              },
                              completion: nil)
            
            //DispatchQueue.main.async { [self] in
        /*if timeCard.indices.contains(timeCard.count - 1) {
            print("is it empty")
        }
        else {
            let timeCard = TimeCardInfo(context: context)
            timeCard.image = jpegData
            timeCard.id_number = Int32(userDefaults.integer(forKey: "id"))
        }*/
      
            
                timeCard[timeCard.count - 1].image = jpegData
            
        
        
               if gallery.count > 0 {
                    gallery[0].thumbnail = resizeImage(image: UIImage(data: jpegData!)!, targetSize: CGSize(width: 156, height: 156)).jpegData(compressionQuality: 1.0)
                    gallery[0].fullSize = jpegData
                    let today = Date()
                    let formatter1 = DateFormatter()
                    formatter1.dateFormat = "MM/dd/yyyy hh:mm a"
                    let dateFormatted = formatter1.string(from: today)
                    
                    gallery[0].date = dateFormatted
                }
               else if gallery.count == 0 {
                    let galleryContext = Gallery(context: self.context)
                    galleryContext.id_number = Int32(userDefaults.integer(forKey: "id"))
                    
                    gallery[0].thumbnail = resizeImage(image: UIImage(data: jpegData!)!, targetSize: CGSize(width: 124, height: 128)).jpegData(compressionQuality: 1.0)
                    gallery[0].fullSize = jpegData
                    let today = Date()
                    let formatter1 = DateFormatter()
                    formatter1.dateFormat = "MM/dd/yyyy hh:mm a"
                    let dateFormatted = formatter1.string(from: today)
                    
                    gallery[0].date = dateFormatted
                }
        //}
           /* else {
                UIView.transition(with: self.imageView,
                                  duration: 1.0,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: { [self] in
                                    imageView.backgroundColor = UIColor.red
                                    let label = UILabel(frame: CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height))
                                    label.text = "There was an error"
                                    imageView.image = UIImage.imageWithLabel(label: label)
                                  },
                                  completion: { _ in
                                    UIView.transition(with: self.imageView,
                                                      duration: 5.0,
                                                      options: [.allowAnimatedContent, .transitionCrossDissolve],
                                                      animations: { [self] in
                                                        imageView.backgroundColor = UIColor.clear
                                                        setImageView()
                                                      },
                                                      completion: nil)
                                  })
            }*/
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            if cameraIsBeingUsed == true && userDefaults.integer(forKey: "saveImages") == 0 {
                UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
                cameraIsBeingUsed = false
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
            gallery[0].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        else if sender.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = nil
            timeCardInfo[timeCardInfo.count - 1].name = sender.text?.trimmingCharacters(in: .whitespaces)
            gallery[0].name = sender.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hourItems = timeCard[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCardCell", for: indexPath) as! TimeCardInfoTableViewCell
        
        let inTime = hourItems.intime
        let outTime = hourItems.outtime
        let totalHours = hourItems.total_hours
        let date = hourItems.date
        
        cell.inTimeLabel.text = "In Time: \(inTime ?? "Unknown")"
        cell.outTimeLabel.text = "Out Time: \(outTime ?? "Unknown")"
        cell.totalHoursLabel.text = "Total Hours: \(totalHours ?? "Unknown")"
        cell.dateLabel.text = "Date: \(date ?? "Unknown")"
        
        return cell
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        if textField.text != "" && textField.text != nil {
            timeCards[userDefaults.integer(forKey: "index")].name = textField.text
            timeCardInfo[timeCardInfo.count - 1].name = textField.text?.trimmingCharacters(in: .whitespaces)
            gallery[0].name = textField.text?.trimmingCharacters(in: .whitespaces)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
        }
        else if textField.text?.trimmingCharacters(in: .whitespaces) == ""{
            timeCards[userDefaults.integer(forKey: "index")].name = nil
            timeCardInfo[timeCardInfo.count - 1].name = nil
            gallery[0].name = nil
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
        
        print("hello world")
        return range.location < 16
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        
        //if timeCard.indices.contains(timeCard.count - 1) {
        if timeCard[timeCard.count - 1].image != nil {
            let alert = UIAlertController(title: "Warning", message: "There is already an image stored. What would you like to do?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "View Image", style: .default, handler: { [self] _ in
                
                image = UIImage(data: timeCard[timeCard.count - 1].image!)
                performSegue(withIdentifier: "viewImage", sender: nil)
                
            }))
            alert.addAction(UIAlertAction(title: "Go To Gallery", style: .default, handler: { _ in
                self.performSegue(withIdentifier: "gallery", sender: self)
            }))
            alert.addAction(UIAlertAction(title: "Choose a new image", style: .default, handler: { _ in
                let alert = UIAlertController(title: "Choose a new image", message: "What would you like to do?", preferredStyle: .actionSheet)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { _ in
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.delegate = self;
                        imagePickerController.sourceType = .camera
                        DispatchQueue.main.async {
                            self.present(imagePickerController, animated: true, completion: nil)
                        }
                        self.cameraIsBeingUsed = true
                    }))
                }
                alert.addAction(UIAlertAction(title: "Choose a photo", style: .default, handler: { _ in
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self;
                    imagePickerController.sourceType = .photoLibrary
                    DispatchQueue.main.async {
                        self.present(imagePickerController, animated: true, completion: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Remove Image", style: .destructive, handler: { [self] _ in
                
                UIView.transition(with: self.imageView,
                                  duration: 1.0,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: { [self] in
                                    setImageView()
                                  },
                                  completion: nil)
                timeCard[timeCard.count - 1].image = nil
                gallery[0].thumbnail = nil
                gallery[0].date = nil
                gallery[0].fullSize = nil
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
       // }
        }
        else {
            let alert = UIAlertController(title: "Choose", message: "What would you like to do?", preferredStyle: .actionSheet)
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
    @IBAction func previousButton(_ sender: UIButton) {
        
        if (timeCards.count - 1) >= userDefaults.integer(forKey: "index") && userDefaults.integer(forKey: "index") > 0 && timeCards[userDefaults.integer(forKey: "index") - 1].id_number != 0 {
            
            UIButton.animate(withDuration: 0.05,
                             animations: { [self] in
                                sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                                previousButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
                                previousButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
                                previousButton.layer.shadowOpacity = 0.0
                                previousButton.layer.shadowRadius = 0.0
                                previousButton.layer.masksToBounds = false
                             },
                             completion: { finish in
                                UIButton.animate(withDuration: 0.05, animations: { [self] in
                                    sender.transform = CGAffineTransform.identity
                                    previousButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75).cgColor
                                    previousButton.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
                                    previousButton.layer.shadowOpacity = 1.0
                                    previousButton.layer.shadowRadius = 5.0
                                    previousButton.layer.masksToBounds = false
                                })
                             })
            
            let id = timeCards[userDefaults.integer(forKey: "index") - 1].id_number
            userDefaults.setValue(id, forKey: "id")
            userDefaults.setValue(userDefaults.integer(forKey:"index") - 1, forKey: "index")
            UIView.transition(with: tableView, duration: 0.50, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: { [self] in
                self.tableView.reloadData()
                
                if timeCards[userDefaults.integer(forKey:"index")].name == nil || timeCards[userDefaults.integer(forKey:"index")].name?.trimmingCharacters(in: .whitespaces) == "" ||  timeCards[userDefaults.integer(forKey:"index")].name == "Unknown" {
                    textField.text = "Unknown"
                    self.navigationItem.title = "Time Card Info"
                }
                else {
                    textField.text = timeCards[userDefaults.integer(forKey:"index")].name
                    self.navigationItem.title = timeCards[userDefaults.integer(forKey:"index")].name
                }
                
                let total = round(Double(timeCards[userDefaults.integer(forKey:"index")].total) * 100.0) / 100.0
                UIView.transition(with: totalHoursLabel, duration: 0.50, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: { [self] in
                    totalHoursLabel.text = "Total Hours: \(total)"
                }, completion: nil)
                
                UIView.transition(with: weekOfLabel, duration: 0.50, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: { [self] in
                    
                    if timeCards[userDefaults.value(forKey: "index") as! Int].numberBeingExported == 1 {
                        weekOfLabel.text = "Day Of: \(timeCards[userDefaults.integer(forKey:"index")].week ?? "Unknown")"
                    }
                    else {
                        weekOfLabel.text = "Week Of: \(timeCards[userDefaults.integer(forKey:"index")].week ?? "Unknown")"
                    }
                }, completion: nil)
                
            }, completion: nil)
            
            //if timeCard.indices.contains(timeCard.count - 1) {
            if timeCard[timeCard.count - 1].image != nil {
                DispatchQueue.main.async { [self] in
                    
                    UIView.transition(with: self.imageView,
                                      duration: 0.50,
                                      options: [.allowAnimatedContent, .transitionCrossDissolve],
                                      animations: { [self] in
                                        imageView.image = UIImage(data: timeCard[timeCard.count - 1].image!)
                                      },
                                      completion: nil)
                }
          // }
            }
            else {
                UIView.transition(with: self.imageView,
                                  duration: 0.50,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: { [self] in
                                    setImageView()
                                  },
                                  completion: nil)
            }
        }
        else {
            print("hello world \(userDefaults.integer(forKey: "index"))")
            print("hello world \(timeCards.count - 1)")
            
            UIButton.animate(withDuration: 0.30,
                             animations: {
                                sender.backgroundColor = UIColor.red
                             },
                             completion: { finish in
                                UIButton.animate(withDuration: 0.30,
                                                 animations: { [self] in
                                                    if userDefaults.integer(forKey: "accent") == 0 {
                                                        previousButton.backgroundColor = UIColor(rgb: 0x26A69A)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 1 {
                                                        previousButton.backgroundColor = UIColor(rgb: 0x7841c4)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 2 {
                                                        
                                                        previousButton.backgroundColor = UIColor(rgb: 0x347deb)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 3 {
                                                        
                                                        previousButton.backgroundColor = UIColor(rgb: 0xfc783a)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 4 {
                                                        
                                                        previousButton.backgroundColor = UIColor(rgb: 0xc41d1d)
                                                    }
                                    else if userDefaults.integer(forKey: "accent") == 5 {
                                        if userDefaults.integer(forKey: "accentRandom") == 0 {
                                            previousButton.backgroundColor = UIColor(rgb: 0x26A69A)
                        
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 1 {
                                            previousButton.backgroundColor = UIColor(rgb: 0x7841c4)
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 2 {
                                            previousButton.backgroundColor = UIColor(rgb: 0x347deb)
                                            
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 3 {
                                            previousButton.backgroundColor = UIColor(rgb: 0xfc783a)
                                           
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 4 {
                                            previousButton.backgroundColor = UIColor(rgb: 0xc41d1d)
                                            
                                        }
                                    }
                                                 },
                                                 completion: nil)
                             })
        }
    }
    @IBAction func nextButton(_ sender: UIButton) {
        
        //if (timeCards.count - 1) > userDefaults.integer(forKey: "index") && (timeCardInfo.count - 1) >= (userDefaults.integer(forKey: "index") + 1) {
        if (timeCards.count - 1) >= userDefaults.integer(forKey: "index") + 1 && userDefaults.integer(forKey: "index") < timeCards.count - 1 && timeCards[userDefaults.integer(forKey: "index") + 1].id_number != 0 {
            
            UIButton.animate(withDuration: 0.05,
                             animations: { [self] in
                                sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                                nextButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
                                nextButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
                                nextButton.layer.shadowOpacity = 0.0
                                nextButton.layer.shadowRadius = 0.0
                                nextButton.layer.masksToBounds = false
                             },
                             completion: { finish in
                                UIButton.animate(withDuration: 0.05, animations: { [self] in
                                    sender.transform = CGAffineTransform.identity
                                    nextButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75).cgColor
                                    nextButton.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
                                    nextButton.layer.shadowOpacity = 1.0
                                    nextButton.layer.shadowRadius = 5.0
                                    nextButton.layer.masksToBounds = false
                                })
                             })
            
            print("index is \(userDefaults.integer(forKey: "index"))")
            let id = timeCards[userDefaults.integer(forKey: "index") + 1].id_number
            userDefaults.setValue(id, forKey: "id")
            userDefaults.setValue(userDefaults.integer(forKey:"index") + 1, forKey: "index")
            UIView.transition(with: tableView, duration: 0.50, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: { [self] in
                
                tableView.reloadData()
                
                if timeCards[userDefaults.integer(forKey:"index")].name == nil || timeCards[userDefaults.integer(forKey:"index")].name?.trimmingCharacters(in: .whitespaces) == "" ||  timeCards[userDefaults.integer(forKey:"index")].name == "Unknown" {
                    textField.text = "Unknown"
                    self.navigationItem.title = "Time Card Info"
                }
                else {
                    textField.text = timeCards[userDefaults.integer(forKey:"index")].name
                    self.navigationItem.title = timeCards[userDefaults.integer(forKey:"index")].name
                }
                
                let total = round(Double(timeCards[userDefaults.integer(forKey:"index")].total) * 100.0) / 100.0
                UIView.transition(with: totalHoursLabel, duration: 0.50, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: { [self] in
                    totalHoursLabel.text = "Total Hours: \(total)"
                }, completion: nil)
                
                UIView.transition(with: weekOfLabel, duration: 0.50, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations: { [self] in
                    
                    if timeCards[userDefaults.value(forKey: "index") as! Int].numberBeingExported == 1 {
                        weekOfLabel.text = "Day Of: \(timeCards[userDefaults.integer(forKey:"index")].week ?? "Unknown")"
                    }
                    else {
                        weekOfLabel.text = "Week Of: \(timeCards[userDefaults.integer(forKey:"index")].week ?? "Unknown")"
                    }
                }, completion: nil)
            }, completion: nil)
            
           // if timeCard.indices.contains(timeCard.count - 1) {
            if timeCard[timeCard.count - 1].image != nil {
                DispatchQueue.main.async { [self] in
                    
                    UIView.transition(with: self.imageView,
                                      duration: 0.50,
                                      options: [.allowAnimatedContent, .transitionCrossDissolve],
                                      animations: { [self] in
                                        imageView.image = UIImage(data: timeCard[timeCard.count - 1].image!)
                                      },
                                      completion: nil)
                }
          // }
            }
            else {
                UIView.transition(with: self.imageView,
                                  duration: 0.50,
                                  options: [.allowAnimatedContent, .transitionCrossDissolve],
                                  animations: { [self] in
                                    setImageView()
                                  },
                                  completion: nil)
            }
        }
        else {
            print("hello world \(userDefaults.integer(forKey: "index"))")
            print("hello world \(timeCards.count - 1)")
            
            UIButton.animate(withDuration: 0.30,
                             animations: {
                                sender.backgroundColor = UIColor.red
                             },
                             completion: { finish in
                                UIButton.animate(withDuration: 0.30,
                                                 animations: { [self] in
                                                    if userDefaults.integer(forKey: "accent") == 0 {
                                                        nextButton.backgroundColor = UIColor(rgb: 0x26A69A)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 1 {
                                                        nextButton.backgroundColor = UIColor(rgb: 0x7841c4)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 2 {
                                                        
                                                        nextButton.backgroundColor = UIColor(rgb: 0x347deb)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 3 {
                                                        
                                                        nextButton.backgroundColor = UIColor(rgb: 0xfc783a)
                                                    }
                                                    else if userDefaults.integer(forKey: "accent") == 4 {
                                                        
                                                        nextButton.backgroundColor = UIColor(rgb: 0xc41d1d)
                                                    }
                                    else if userDefaults.integer(forKey: "accent") == 5 {
                                        if userDefaults.integer(forKey: "accentRandom") == 0 {
                                            nextButton.backgroundColor = UIColor(rgb: 0x26A69A)
                        
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 1 {
                                            nextButton.backgroundColor = UIColor(rgb: 0x7841c4)
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 2 {
                                            nextButton.backgroundColor = UIColor(rgb: 0x347deb)
                                            
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 3 {
                                            nextButton.backgroundColor = UIColor(rgb: 0xfc783a)
                                           
                                        }
                                        else if userDefaults.integer(forKey: "accentRandom") == 4 {
                                            nextButton.backgroundColor = UIColor(rgb: 0xc41d1d)
                                            
                                        }
                                    }
                                                 },
                                                 completion: nil)
                             })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage" {
            let dvc = segue.destination as! ImageViewController
            dvc.newImage = image
            dvc.name = textField.text
            dvc.index = -1
        }
    }
}
