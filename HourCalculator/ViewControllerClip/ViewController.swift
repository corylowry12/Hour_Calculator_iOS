//
//  ViewController.swift
//  ViewControllerClip
//
//  Created by Cory Lowry on 7/4/21.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var inTimeDatePicker: UIDatePicker!
    @IBOutlet var outTimeDatePicker: UIDatePicker!
    @IBOutlet var calculateButtonClip: UIButton!
    @IBOutlet var outputLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    var inHour : Int = 0
    var inMinute : Int = 0
    
    @IBAction func inTimeChanged(_ sender: Any) {
        
        let date = inTimeDatePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
    }
    
    var outHour : Int = 0
    var outMinute : Int = 0
    
    @IBAction func outTimeChanged(_ sender: Any) {
        
        let outDate = outTimeDatePicker.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
    }
    @IBAction func calculateButtonPress(_ sender: Any) {
        
        AMtoPM()
    }
    
    func AMtoPM() {
        let date = inTimeDatePicker.date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        inHour = components.hour!
        inMinute = components.minute!
        
        let outDate = outTimeDatePicker.date
        let componentsOut = Calendar.current.dateComponents([.hour, .minute], from: outDate)
        
        outHour = componentsOut.hour!
        outMinute = componentsOut.minute!
        
        let minutesDifference = outMinute - inMinute
        let hoursDifference = outHour - inHour
        
        if hoursDifference < 0 {
           outputLabel.text = "In time can not be greater than out time"
       }
        else if minutesDifference < 0 {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = String(round(minutesDecimal * 100) / 100.00)
            let minutesInverted = Double(minutesRounded)! * -1
            print(minutesInverted)
            //let minutesFormatted = String(minutesInverted).dropFirst(2)
            print(minutesInverted)
            let minutes2 = 1.0 - Double(round(minutesInverted * 100) / 100.00)
            let minutes3 = round(minutes2 * 100) / 100.00
            print(minutes3)
            let minutes = String(minutes3).dropFirst(2)
            print(minutes)
            let hours = hoursDifference - 1
            if hours < 0 {
                outputLabel.text = "In time can not be greater than out time"
            }
            else {
                outputLabel.text = "Total Hours: \(hours).\(minutes)"

                }
            }
        else {
            let minutesDecimal : Double = Double(minutesDifference) / 60.00
            let minutesRounded = round(minutesDecimal * 100) / 100.00
            let minutesFormatted = String(minutesRounded).dropFirst(2)
            
            outputLabel.text = "Total Hours: \(hoursDifference).\(minutesFormatted)"
    }
    
}
}
