//
//  EditViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/25/21.
//

import UIKit
import CoreData

class EditViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var datePickerInTime: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    var data: Int!
    var selectedDate: Date = Date()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    var inHour: Int = 0
    var inMinute: Int = 0
    var outHour: Int = 0
    var outMinute: Int = 0
    
    var hourItems: [Hours] {
        do {
            var sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            let fetchrequest = NSFetchRequest<Hours>(entityName: "Hours")
            let sortChoice = userDefaults.integer(forKey: "historySort")
            
            if sortChoice == 0 {
                sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: false)
            } else if sortChoice == 1 {
                sort = NSSortDescriptor(key: #keyPath(Hours.date), ascending: true)
            } else if sortChoice == 2 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: true)
            } else if sortChoice == 3 {
                sort = NSSortDescriptor(key: #keyPath(Hours.totalHours), ascending: false)
            }
            
            fetchrequest.sortDescriptors = [sort]
            return try context.fetch(fetchrequest)
        } catch {
            print("Couldn't fetch data")
        }
        return [Hours]()
    }
    
    var hasUnsavedChanges: Bool {
        guard let data = data, data < hourItems.count else { return false }
        let storedItem = hourItems[data]
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let currentInTime = timeFormatter.string(from: datePickerInTime.date)
        let currentOutTime = timeFormatter.string(from: datePickerOutTime.date)
        let currentDate = dateFormatter.string(from: selectedDate)
        
        let inChanged = (currentInTime != storedItem.inTime)
        let outChanged = (currentOutTime != storedItem.outTime)
        let dateChanged = (currentDate != storedItem.date)
        
        return inChanged || outChanged || dateChanged
    }
    
    func updateModalPresentationState() {
        isModalInPresentation = hasUnsavedChanges
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let accent = userDefaults.integer(forKey: "accent")
        if accent == 0 {
            saveButton.backgroundColor = UIColor(rgb: 0x26A69A)
        } else if accent == 1 {
            saveButton.backgroundColor = UIColor(rgb: 0x7841c4)
        } else if accent == 2 {
            saveButton.backgroundColor = UIColor(rgb: 0x347deb)
        } else if accent == 3 {
            saveButton.backgroundColor = UIColor(rgb: 0xfc783a)
        } else if accent == 4 {
            saveButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        } else if accent == 5 {
            let randomAccent = userDefaults.integer(forKey: "accentRandom")
            if randomAccent == 0 {
                saveButton.backgroundColor = UIColor(rgb: 0x26A69A)
            } else if randomAccent == 1 {
                saveButton.backgroundColor = UIColor(rgb: 0x7841c4)
            } else if randomAccent == 2 {
                saveButton.backgroundColor = UIColor(rgb: 0x347deb)
            } else if randomAccent == 3 {
                saveButton.backgroundColor = UIColor(rgb: 0xfc783a)
            } else if randomAccent == 4 {
                saveButton.backgroundColor = UIColor(rgb: 0xc41d1d)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.presentationController?.delegate = self
        presentationController?.delegate = self
        
        guard let idString = userDefaults.string(forKey: "ID"),
              let index = Int(idString),
              index < hourItems.count else {
            return
        }
        
        data = index
        let currentItem = hourItems[data]
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        
        let storedDateFormatter = DateFormatter()
        storedDateFormatter.dateFormat = "MM/dd/yyyy"
        
        if let inString = currentItem.inTime, let parsedInDate = timeFormatter.date(from: inString) {
            datePickerInTime.date = parsedInDate
        }
        
        if let outString = currentItem.outTime, let parsedOutDate = timeFormatter.date(from: outString) {
            datePickerOutTime.date = parsedOutDate
        }
        
        if let dateString = currentItem.date, let parsedDate = storedDateFormatter.date(from: dateString) {
            selectedDate = parsedDate
        } else {
            let alert = UIAlertController(title: "Error", message: "There was an error loading the date. Please try again or re-enter the entry.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true, completion: nil)
            })
            self.present(alert, animated: true, completion: nil)
        }
        
        setupDateButton()
        updateModalPresentationState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("Update"), object: nil)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    private func setupDateButton() {
        dateButton.layer.cornerRadius = 8
        dateButton.layer.masksToBounds = true
        dateButton.backgroundColor = UIColor.systemGray5
        updateDateButtonTitle()
    }
    
    private func updateDateButtonTitle() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let title = formatter.string(from: selectedDate)
        
        if var config = dateButton.configuration {
            config.title = title
            dateButton.configuration = config
        } else {
            dateButton.setTitle(title, for: .normal)
        }
    }
    
    @IBAction func dateButtonTapped(_ sender: Any) {
        let alertVC = UIViewController()
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        alertVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        // 1. Transparent dismiss overlay behind calendar
        let dismissButton = UIButton(frame: alertVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissCalendarModal), for: .touchUpInside)
        alertVC.view.addSubview(dismissButton)
        
        // 2. Liquid Glass Container
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let glassContainer = UIVisualEffectView(effect: blurEffect)
        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.masksToBounds = true
        glassContainer.layer.borderWidth = 1.0
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(glassContainer)
        
        // 3. Inline Calendar Picker
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        picker.date = selectedDate
        picker.tintColor = saveButton.backgroundColor
        picker.backgroundColor = .clear
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.addTarget(self, action: #selector(inlineDateChanged(_:)), for: .valueChanged)
        glassContainer.contentView.addSubview(picker)
        
        // 4. Layout Constraints
        NSLayoutConstraint.activate([
            glassContainer.centerXAnchor.constraint(equalTo: alertVC.view.centerXAnchor),
            glassContainer.centerYAnchor.constraint(equalTo: alertVC.view.centerYAnchor),
            glassContainer.widthAnchor.constraint(equalToConstant: 335),
            
            picker.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor, constant: 12),
            picker.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor, constant: -12),
            picker.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 12),
            picker.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -12)
        ])
        
        present(alertVC, animated: true)
    }

    @objc private func inlineDateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        updateDateButtonTitle()
        updateModalPresentationState()
        dismiss(animated: true)
    }

    @objc private func dismissCalendarModal() {
        dismiss(animated: true)
    }
    
    @IBAction func inTimeValueChanged(_ sender: UIDatePicker) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: sender.date)
        inHour = components.hour ?? 0
        inMinute = components.minute ?? 0
        updateModalPresentationState()
    }
    
    @IBAction func outTimeValueChanged(_ sender: UIDatePicker) {
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: sender.date)
        outHour = componentsOut.hour ?? 0
        outMinute = componentsOut.minute ?? 0
        updateModalPresentationState()
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        if hasUnsavedChanges {
            let inComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerInTime.date)
            inHour = inComponents.hour ?? 0
            inMinute = inComponents.minute ?? 0
            
            let outComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerOutTime.date)
            outHour = outComponents.hour ?? 0
            outMinute = outComponents.minute ?? 0
            
            let hoursDifference = outHour - inHour
            
            if hoursDifference < 0 && (12...24).contains(inHour) && (0...12).contains(outHour) {
                self.PMtoAM()
            } else {
                self.save()
            }
        } else {
            dateLabel.text = "Can Not Save, No Values Were Changed"
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        if hasUnsavedChanges {
            promptPendingChanges()
        } else {
            userDefaults.removeObject(forKey: "ID")
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        }
    }

    private func promptPendingChanges() {
        let alert = UIAlertController(
            title: "Pending Changes",
            message: "You are trying to leave with pending changes. Would you like to save?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.save()
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        let hourToDelete = self.hourItems[data]
        let alert = UIAlertController(title: "Delete?", message: "Would you like to delete this hour?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.context.delete(hourToDelete)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            let doneAlert = UIAlertController(title: nil, message: "Entry Deleted   ✓", preferredStyle: .alert)
            doneAlert.view.tintColor = UIColor.black
            self.present(doneAlert, animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                doneAlert.dismiss(animated: true) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func PMtoAM() {
        let inComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerInTime.date)
        inHour = inComponents.hour ?? 0
        inMinute = inComponents.minute ?? 0
        
        let outComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerOutTime.date)
        outHour = outComponents.hour ?? 0
        outMinute = outComponents.minute ?? 0
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour + 24
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let inTimeDate = dateFormatter.string(from: datePickerInTime.date)
        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
        
        let dateFormatterForDateTaken = DateFormatter()
        dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
        let dateEntered = dateFormatterForDateTaken.string(from: selectedDate)
        
        let hoursToBeStored = hourItems[data]
        
        if minutesDifference < 0 {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = (Double(minutesRounded) ?? 0.0) * -1
            let minutes2 = 1.0 - (round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            let minutes = String(minutes3).dropFirst(2)
            let hours = hoursDifference - 1
            
            if hours < 0 {
                dateLabel.text = "In time can not be greater than out time"
                return
            }
            
            dateLabel.text = "Total Hours: \(hours).\(minutes)"
            hoursToBeStored.inTime = inTimeDate
            hoursToBeStored.outTime = outTimeDate
            hoursToBeStored.totalHours = "\(hours).\(minutes)"
            hoursToBeStored.date = dateEntered
        } else {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
            hoursToBeStored.inTime = inTimeDate
            hoursToBeStored.outTime = outTimeDate
            hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
            hoursToBeStored.date = dateEntered
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        updateModalPresentationState()
        
        if userDefaults.integer(forKey: "dismissEdit") == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func save() {
        let inComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerInTime.date)
        inHour = inComponents.hour ?? 0
        inMinute = inComponents.minute ?? 0
        
        let outComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerOutTime.date)
        outHour = outComponents.hour ?? 0
        outMinute = outComponents.minute ?? 0
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let inTimeDate = dateFormatter.string(from: datePickerInTime.date)
        let outTimeDate = dateFormatter.string(from: datePickerOutTime.date)
        
        let dateFormatterForDateTaken = DateFormatter()
        dateFormatterForDateTaken.dateFormat = "MM/dd/yyyy"
        let dateEntered = dateFormatterForDateTaken.string(from: selectedDate)
        
        let hoursToBeStored = hourItems[data]
        
        if hoursDifference < 0 {
            dateLabel.text = "In time can not be greater than out time"
            return
        } else if minutesDifference < 0 {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = (Double(minutesRounded) ?? 0.0) * -1
            let minutes2 = 1.0 - (round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            let minutes = String(minutes3).dropFirst(2)
            let hours = hoursDifference - 1
            
            if hours < 0 {
                dateLabel.text = "In time can not be greater than out time"
                return
            }
            
            dateLabel.text = "Total Hours: \(hours).\(minutes)"
            hoursToBeStored.inTime = inTimeDate
            hoursToBeStored.outTime = outTimeDate
            hoursToBeStored.totalHours = "\(hours).\(minutes)"
            hoursToBeStored.date = dateEntered
        } else {
            let minutesDecimal = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            dateLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
            hoursToBeStored.inTime = inTimeDate
            hoursToBeStored.outTime = outTimeDate
            hoursToBeStored.totalHours = "\(hoursDifference).\(minutesFormatted)"
            hoursToBeStored.date = dateEntered
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        updateModalPresentationState()
        
        if userDefaults.integer(forKey: "dismissEdit") == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        promptPendingChanges()
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        userDefaults.removeObject(forKey: "ID")
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
    }
}
