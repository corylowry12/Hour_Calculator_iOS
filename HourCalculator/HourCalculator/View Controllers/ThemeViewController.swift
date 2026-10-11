//
//  ThemeViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 6/26/21.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

class ThemeViewController: UITableViewController {
    
    var window: UIWindow?
    @IBOutlet weak var tintImageView: UIImageView!
    @IBOutlet weak var purpleImageView: UIImageView!
    @IBOutlet weak var turquoiseImageView: UIImageView!
    @IBOutlet weak var orangeImageView: UIImageView!
    @IBOutlet weak var redImageView: UIImageView!
    @IBOutlet weak var randomImageView: UIImageView!
    
    let userDefaults = UserDefaults.standard
    
    private var targetWindow: UIWindow? {
        if let window = view.window { return window }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .singleLine
        
        tintImageView.layer.cornerRadius = tintImageView.frame.size.width / 2
        purpleImageView.layer.cornerRadius = purpleImageView.frame.size.width / 2
        turquoiseImageView.layer.cornerRadius = turquoiseImageView.frame.size.width / 2
        orangeImageView.layer.cornerRadius = orangeImageView.frame.size.width / 2
        redImageView.layer.cornerRadius = redImageView.frame.size.width / 2
        randomImageView.layer.cornerRadius = randomImageView.frame.size.width / 2
        
        if userDefaults.value(forKey: "accent") == nil {
            userDefaults.set(0, forKey: "accent")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCheckmarks()
    }
    
    private func updateCheckmarks() {
        let storedTheme = userDefaults.integer(forKey: "theme")
        let storedAccent = userDefaults.integer(forKey: "accent")
        
        // Section 0: Theme Selection
        for row in 0..<tableView.numberOfRows(inSection: 0) {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
            cell?.accessoryType = (row == storedTheme) ? .checkmark : .none
        }
        
        // Section 1: Accent Color
        for row in 0..<tableView.numberOfRows(inSection: 1) {
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 1))
            cell?.accessoryType = (row == storedAccent) ? .checkmark : .none
        }
    }
    
    private func applyThemeTransition(targetStyle: UIUserInterfaceStyle) {
        guard let currentWindow = targetWindow else {
            view.window?.overrideUserInterfaceStyle = targetStyle
            return
        }
        
        guard let snapshot = currentWindow.snapshotView(afterScreenUpdates: false) else {
            currentWindow.overrideUserInterfaceStyle = targetStyle
            return
        }
        
        currentWindow.addSubview(snapshot)
        currentWindow.overrideUserInterfaceStyle = targetStyle
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: [.curveEaseInOut], animations: {
            snapshot.alpha = 0.0
        }) { _ in
            snapshot.removeFromSuperview()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect immediately so separator lines are never suppressed
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            userDefaults.set(indexPath.row, forKey: "theme")
            
            for row in 0..<tableView.numberOfRows(inSection: 0) {
                tableView.cellForRow(at: IndexPath(row: row, section: 0))?.accessoryType = (row == indexPath.row) ? .checkmark : .none
            }
            
            let targetStyle: UIUserInterfaceStyle
            switch indexPath.row {
            case 0: targetStyle = .light
            case 1: targetStyle = .dark
            default: targetStyle = .unspecified
            }
            
            applyThemeTransition(targetStyle: targetStyle)
        }
        else if indexPath.section == 1 {
            userDefaults.set(indexPath.row, forKey: "accent")
            
            for row in 0..<tableView.numberOfRows(inSection: 1) {
                tableView.cellForRow(at: IndexPath(row: row, section: 1))?.accessoryType = (row == indexPath.row) ? .checkmark : .none
            }
            
            let accentColor: UIColor
            var iconName: String? = nil
            
            switch indexPath.row {
            case 0:
                accentColor = UIColor(rgb: 0x26A69A)
            case 1:
                accentColor = UIColor(rgb: 0x7841c4)
                iconName = "purple_logo"
            case 2:
                accentColor = UIColor(rgb: 0x347deb)
                iconName = "blue_logo"
            case 3:
                accentColor = UIColor(rgb: 0xfc783a)
                iconName = "orange_logo"
            case 4:
                accentColor = UIColor(rgb: 0xc41d1d)
                iconName = "red_logo"
            default:
                var number = Int32.random(in: 0...4)
                while number == Int32(userDefaults.integer(forKey: "accentRandom")) {
                    number = Int32.random(in: 0...4)
                }
                userDefaults.set(number, forKey: "accentRandom")
                
                switch number {
                case 0: accentColor = UIColor(rgb: 0x26A69A)
                case 1: accentColor = UIColor(rgb: 0x7841c4)
                case 2: accentColor = UIColor(rgb: 0x347deb)
                case 3: accentColor = UIColor(rgb: 0xfc783a)
                default: accentColor = UIColor(rgb: 0xc41d1d)
                }
            }
            
            changeIcon(iconName)
            
            UIView.animate(withDuration: 0.25) {
                self.targetWindow?.tintColor = accentColor
            }
        }
    }
    
    func changeIcon(_ iconName: String?) {
        if UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons {
            typealias SetAlternateIconName = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
            let selectorString = "_setAlternateIconName:completionHandler:"
            let selector = NSSelectorFromString(selectorString)
            let imp = UIApplication.shared.method(for: selector)
            let method = unsafeBitCast(imp, to: SetAlternateIconName.self)
            method(UIApplication.shared, selector, iconName as NSString?, { _ in })
        }
    }
}
