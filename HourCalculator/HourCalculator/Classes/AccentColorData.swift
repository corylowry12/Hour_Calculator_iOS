//
//  AccentColorData.swift
//  HourCalculator
//
//  Created by Cory Lowry on 4/2/23.
//

import Foundation
import UIKit

class AccentColorData {
    
    func setColor(color: String) {
        UserDefaults.standard.set(color, forKey: "accentColor")
    }
    
    func getColor() -> String {
        return UserDefaults.standard.string(forKey: "accentColor") ?? ""
    }
}

extension UserDefaults {
 func colorForKey(key: String) -> UIColor? {
     var color: UIColor? = UIColor.systemTeal
  if let colorData = data(forKey: key) {
      color = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
  }
  return color
 }

 func setColor(color: UIColor?, forKey key: String) {
  var colorData: NSData?
   if let color = color {
    colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
  }
  set(colorData, forKey: key)
 }

}
