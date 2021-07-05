//
//  HowToTableViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 7/4/21.
//

import UIKit

class HowToTableViewController: UITableViewController {
    @IBOutlet weak var howToEnterTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UIGestureRecognizer(target: self, action: #selector(self.tapFunction(sender:)))
        
        howToEnterTimeLabel.isUserInteractionEnabled = true
        howToEnterTimeLabel.addGestureRecognizer(tap)
    }
    
    @objc func tapFunction(sender: UITapGestureRecognizer) {
        print("tap working")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath == [0, 0] {
            let index = IndexPath(row: NSNotFound, section: 1)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 1] {
            let index = IndexPath(row: NSNotFound, section: 2)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 2] {
            let index = IndexPath(row: NSNotFound, section: 3)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
        else if indexPath == [0, 3] {
            let index = IndexPath(row: NSNotFound, section: 4)
            tableView.scrollToRow(at: index, at: .top, animated: true)
        }
    }
  
}
