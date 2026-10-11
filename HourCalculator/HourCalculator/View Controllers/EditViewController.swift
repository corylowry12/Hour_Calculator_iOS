//
//  EditViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/25/21.
//

import UIKit
import CoreData

class EditViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    // Cached static formatters to avoid re-allocating on every check
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "hh:mm a"
        return df
    }()
    
    private static let storedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        return df
    }()
    
    private static let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df
    }()
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var datePickerInTime: UIDatePicker!
    @IBOutlet weak var datePickerOutTime: UIDatePicker!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    // Pass the managed object directly rather than indexing via UserDefaults
    var currentHourItem: Hours?
    var selectedDate: Date = Date()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let userDefaults = UserDefaults.standard
    
    var inHour: Int = 0
    var inMinute: Int = 0
    var outHour: Int = 0
    var outMinute: Int = 0
    
    var hasUnsavedChanges: Bool {
        guard let item = currentHourItem else { return false }
        
        let currentInTime = Self.timeFormatter.string(from: datePickerInTime.date)
        let currentOutTime = Self.timeFormatter.string(from: datePickerOutTime.date)
        let currentDate = Self.storedDateFormatter.string(from: selectedDate)
        
        let inChanged = (currentInTime != item.inTime)
        let outChanged = (currentOutTime != item.outTime)
        let dateChanged = (currentDate != item.date)
        
        return inChanged || outChanged || dateChanged
    }
    
    func updateModalPresentationState() {
        isModalInPresentation = hasUnsavedChanges
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let accent = userDefaults.integer(forKey: "accent")
        switch accent {
        case 0: saveButton.backgroundColor = UIColor(rgb: 0x26A69A)
        case 1: saveButton.backgroundColor = UIColor(rgb: 0x7841c4)
        case 2: saveButton.backgroundColor = UIColor(rgb: 0x347deb)
        case 3: saveButton.backgroundColor = UIColor(rgb: 0xfc783a)
        case 4: saveButton.backgroundColor = UIColor(rgb: 0xc41d1d)
        default:
            let randomAccent = userDefaults.integer(forKey: "accentRandom")
            switch randomAccent {
            case 0: saveButton.backgroundColor = UIColor(rgb: 0x26A69A)
            case 1: saveButton.backgroundColor = UIColor(rgb: 0x7841c4)
            case 2: saveButton.backgroundColor = UIColor(rgb: 0x347deb)
            case 3: saveButton.backgroundColor = UIColor(rgb: 0xfc783a)
            default: saveButton.backgroundColor = UIColor(rgb: 0xc41d1d)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.presentationController?.delegate = self
        presentationController?.delegate = self
        
        guard let currentItem = currentHourItem else {
            dismiss(animated: true)
            return
        }
        
        if let inString = currentItem.inTime, let parsedInDate = Self.timeFormatter.date(from: inString) {
            datePickerInTime.date = parsedInDate
        }
        
        if let outString = currentItem.outTime, let parsedOutDate = Self.timeFormatter.date(from: outString) {
            datePickerOutTime.date = parsedOutDate
        }
        
        if let dateString = currentItem.date, let parsedDate = Self.storedDateFormatter.date(from: dateString) {
            selectedDate = parsedDate
        } else {
            selectedDate = Date()
        }
        
        setupDateButton()
        updateModalPresentationState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    private func setupDateButton() {
        dateButton.layer.cornerRadius = 8
        dateButton.layer.masksToBounds = true
        dateButton.backgroundColor = UIColor.systemGray5
        updateDateButtonTitle()
    }
    
    private func updateDateButtonTitle() {
        let title = Self.displayDateFormatter.string(from: selectedDate)
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
        
        let dismissButton = UIButton(frame: alertVC.view.bounds)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.addTarget(self, action: #selector(dismissCalendarModal), for: .touchUpInside)
        alertVC.view.addSubview(dismissButton)
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let glassContainer = UIVisualEffectView(effect: blurEffect)
        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.masksToBounds = true
        glassContainer.layer.borderWidth = 1.0
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(glassContainer)
        
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
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.save()
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        guard let hourToDelete = currentHourItem else { return }
        let alert = UIAlertController(title: "Delete?", message: "Would you like to delete this hour?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.context.delete(hourToDelete)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            let doneAlert = UIAlertController(title: nil, message: "Entry Deleted   ✓", preferredStyle: .alert)
            self.present(doneAlert, animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                doneAlert.dismiss(animated: true) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func PMtoAM() {
        guard let hoursToBeStored = currentHourItem else { return }
        
        let inComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerInTime.date)
        inHour = inComponents.hour ?? 0
        inMinute = inComponents.minute ?? 0
        
        let outComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerOutTime.date)
        outHour = outComponents.hour ?? 0
        outMinute = outComponents.minute ?? 0
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour + 24
        
        let inTimeDate = Self.timeFormatter.string(from: datePickerInTime.date)
        let outTimeDate = Self.timeFormatter.string(from: datePickerOutTime.date)
        let dateEntered = Self.storedDateFormatter.string(from: selectedDate)
        
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
        guard let hoursToBeStored = currentHourItem else { return }
        
        let inComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerInTime.date)
        inHour = inComponents.hour ?? 0
        inMinute = inComponents.minute ?? 0
        
        let outComponents = Calendar.current.dateComponents([.hour, .minute], from: datePickerOutTime.date)
        outHour = outComponents.hour ?? 0
        outMinute = outComponents.minute ?? 0
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour
        
        let inTimeDate = Self.timeFormatter.string(from: datePickerInTime.date)
        let outTimeDate = Self.timeFormatter.string(from: datePickerOutTime.date)
        let dateEntered = Self.storedDateFormatter.string(from: selectedDate)
        
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
        NotificationCenter.default.post(name: NSNotification.Name("Update"), object: nil)
    }
}
