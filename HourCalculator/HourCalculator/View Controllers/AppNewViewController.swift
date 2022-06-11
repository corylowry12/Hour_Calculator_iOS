//
//  AppNewViewController.swift
//  HourCalculator
//
//  Created by Cory Lowry on 3/26/22.
//

import Foundation
import UIKit

class AppNewsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let refreshControl = UIRefreshControl()
    
    var updateBodyArray = [String]()
    var updateDateArray = [String]()
    var updateTitleArray = [String]()
    
    var testflightUpdateBodyArray = [String]()
    var testflightUpdateDateArray = [String]()
    var testflightUpdateTitleArray = [String]()
    
    var expandedArray = [IndexPath]()
    
    var knownIssuesTitleArray = [String]()
    
    var roadMapTitleArray = [String]()
    
    var appUpdateBool = false
    var testflightUpdateBool = false
    var knownIssuesBool = false
    var roadMapBool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.reloadData()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
           refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
           tableView.addSubview(refreshControl)
        
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...")
        
        if appUpdateBool {
            changeRows(indexPathRow: [0,0])
        }
        if testflightUpdateBool {
            changeRows(indexPathRow: [1,0])
        }
        if knownIssuesBool {
            changeRows(indexPathRow: [2, 0])
        }
        if roadMapBool {
            changeRows(indexPathRow: [3, 0])
        }
        
        updateBodyArray.removeAll()
        updateDateArray.removeAll()
        updateTitleArray.removeAll()
        
        testflightUpdateBodyArray.removeAll()
        testflightUpdateDateArray.removeAll()
        testflightUpdateTitleArray.removeAll()
        
        knownIssuesTitleArray.removeAll()
        
        roadMapTitleArray.removeAll()
        
       fetchData()
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        let alert = UIAlertController(title: "Updating data", message: "Please wait...", preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10,y: 5,width: 50, height: 50)) as UIActivityIndicatorView
            loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating();

            alert.view.addSubview(loadingIndicator)

        present(alert, animated: true, completion: { [self] in
            updateBodyArray.removeAll()
            updateDateArray.removeAll()
            updateTitleArray.removeAll()
            
            testflightUpdateBodyArray.removeAll()
            testflightUpdateDateArray.removeAll()
            testflightUpdateTitleArray.removeAll()
            
            knownIssuesTitleArray.removeAll()
            
            roadMapTitleArray.removeAll()
            fetchData()
            self.dismiss(animated: true)
            tableView.reloadData()
        })
        
       // fetchData()
        //tableView.reloadData()
    
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !appUpdateBool {
            return 1
        }
        else if section == 0 && appUpdateBool {
            return updateTitleArray.count + 1
        }
        else if section == 1 && !testflightUpdateBool {
            return 1
        }
        else if section == 1 && testflightUpdateBool {
            return testflightUpdateTitleArray.count + 1
        }
        else if section == 2 && !knownIssuesBool {
            return 1
        }
        else if section == 2 && knownIssuesBool {
            return knownIssuesTitleArray.count + 1
        }
        else if section == 3 && !roadMapBool {
            return 1
        }
        else if section == 3 && roadMapBool {
            return roadMapTitleArray.count + 1
        }
        
        
        return 0
    }
    
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contentCell = tableView.dequeueReusableCell(withIdentifier: "appNewsCell") as! AppNewsTableViewCell
        let contentCell2 = tableView.dequeueReusableCell(withIdentifier: "appNewsCell2") as! AppNewsTableViewCell2
        let cellHeader = tableView.dequeueReusableCell(withIdentifier: "appAddCell") as! AppNewsTableViewHeaderCell
        
        if indexPath.section == 0 && !appUpdateBool{
            
        cellHeader.headerLabel.text = "Updates"
            return cellHeader
        }
        else if indexPath.section == 0 && appUpdateBool {
            if indexPath.row == 0 {
            cellHeader.headerLabel.text = "Updates"
                return cellHeader
            }
            else if indexPath.row > 0 {
                contentCell.titleLabel.text = updateTitleArray[indexPath.row - 1]
                contentCell.contentLabel.text = updateBodyArray[indexPath.row - 1]
                
                contentCell.dateLabel.text = updateDateArray[indexPath.row - 1]
                    return contentCell
            }
        }
        else if indexPath.section == 1 && !testflightUpdateBool {
            cellHeader.headerLabel.text = "TestFlight"
            return cellHeader
        }
        else if indexPath.section == 1 && testflightUpdateBool {
            if indexPath.row == 0 {
            cellHeader.headerLabel.text = "TestFlight"
                return cellHeader
            }
            else if indexPath.row > 0 {
                contentCell.titleLabel.text = testflightUpdateTitleArray[indexPath.row - 1]
                contentCell.contentLabel.text = testflightUpdateBodyArray[indexPath.row - 1]
                contentCell.dateLabel.text = testflightUpdateDateArray[indexPath.row - 1]
                    return contentCell
            }
        }
        
        else if indexPath.section == 2 && !knownIssuesBool {
            cellHeader.headerLabel.text = "Known Issues"
            return cellHeader
        }
        else if indexPath.section == 2 && knownIssuesBool {
            if indexPath.row == 0 {
            cellHeader.headerLabel.text = "Known Issues"
                return cellHeader
            }
            else if indexPath.row > 0 {
                
                contentCell2.bodyLabel.text = knownIssuesTitleArray[indexPath.row - 1]
                    return contentCell2
            }
        }
        
        else if indexPath.section == 3 && !roadMapBool {
            cellHeader.headerLabel.text = "Upcoming Features"
            return cellHeader
        }
        else if indexPath.section == 3 && roadMapBool {
            if indexPath.row == 0 {
            cellHeader.headerLabel.text = "Upcoming Features"
                return cellHeader
            }
            else if indexPath.row > 0 {
                contentCell2.bodyLabel.text = roadMapTitleArray[indexPath.row - 1]
                    return contentCell2
            }
        }
        let cell = UITableViewCell()
        cell.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    func changeRows(indexPathRow: IndexPath) {
        
        if indexPathRow == [0, 0] {
            appUpdateBool = !appUpdateBool
           
            tableView.beginUpdates()
            let tableViewHeaderCell = tableView.cellForRow(at: [0,0]) as! AppNewsTableViewHeaderCell
            if appUpdateBool {
                
                if updateTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.up")
              
            for i in 1...updateTitleArray.count {
                
                let indexPathInsert = IndexPath(row: i, section: 0)
                tableView.insertRows(at: [indexPathInsert], with: .fade)
            }
                }
            }
            else {
                if updateTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.down")
                for i in (1...updateTitleArray.count).reversed() {
                    
                    let indexPathInsert = IndexPath(row: i, section: 0)
                    tableView.deleteRows(at: [indexPathInsert], with: .fade)
                }
            }
            }
            tableView.endUpdates()
        }
        else if indexPathRow == [1, 0] {
            testflightUpdateBool = !testflightUpdateBool
         
            tableView.beginUpdates()
            let tableViewHeaderCell = tableView.cellForRow(at: [1,0]) as! AppNewsTableViewHeaderCell
            if testflightUpdateBool {
                
                if testflightUpdateTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.up")
            for i in 1...testflightUpdateTitleArray.count {
                
                let indexPathInsert = IndexPath(row: i, section: 1)
                tableView.insertRows(at: [indexPathInsert], with: .fade)
            }
            }
            }
            else {
                if testflightUpdateTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.down")
                for i in (1...testflightUpdateTitleArray.count).reversed() {
                    
                    let indexPathInsert = IndexPath(row: i, section: 1)
                    tableView.deleteRows(at: [indexPathInsert], with: .fade)
                }
            }
            }
            tableView.endUpdates()
        }
        
        else if indexPathRow == [2, 0] {
            knownIssuesBool = !knownIssuesBool
            
            tableView.beginUpdates()
            let tableViewHeaderCell = tableView.cellForRow(at: [2,0]) as! AppNewsTableViewHeaderCell
            if knownIssuesBool {
                if knownIssuesTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.up")
            for i in 1...knownIssuesTitleArray.count {
                
                let indexPathInsert = IndexPath(row: i, section: 2)
                tableView.insertRows(at: [indexPathInsert], with: .fade)
            }
            }
            }
            else {
                if knownIssuesTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.down")
                for i in (1...knownIssuesTitleArray.count) {
                    
                    let indexPathInsert = IndexPath(row: i, section: 2)
                    tableView.deleteRows(at: [indexPathInsert], with: .fade)
                }
            }
            }
            tableView.endUpdates()
        }
        
        else if indexPathRow == [3, 0] {
            roadMapBool = !roadMapBool
            tableView.beginUpdates()
            let tableViewHeaderCell = tableView.cellForRow(at: [3,0]) as! AppNewsTableViewHeaderCell
            if roadMapBool {
                if roadMapTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.up")
            for i in 1...roadMapTitleArray.count {
                
                let indexPathInsert = IndexPath(row: i, section: 3)
                tableView.insertRows(at: [indexPathInsert], with: .fade)
            }
            }
            }
            else {
                if roadMapTitleArray.count > 0 {
                tableViewHeaderCell.chevronImage.image = UIImage(systemName: "chevron.down")
                for i in (1...roadMapTitleArray.count) {
                    
                    let indexPathInsert = IndexPath(row: i, section: 3)
                    tableView.deleteRows(at: [indexPathInsert], with: .fade)
                }
            }
            }
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
      
        changeRows(indexPathRow: indexPath)
       
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
        return UITableView.automaticDimension
    }
    
    func fetchData() {
    
        guard let url = URL(string: "https://raw.githubusercontent.com/corylowry12/update_json_ios/main/update_json.json") else {return}
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let dataResponse = data,
                  error == nil else {
            DispatchQueue.main.async { [self] in
                  print(error?.localizedDescription ?? "Response Error")
                
                    refreshControl.endRefreshing()
                
            let alert = UIAlertController(title: "Error", message: "There was an error fetching the latest app news, check your connection", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: {_ in
                self.refreshControl.endRefreshing()
                self.fetchData()
                    alert.dismiss(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Go Back", style: .cancel, handler: {_ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
            }
                  return }
            do {
                
                if let json = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String: Any] {
                    if let updates = json["update"] as? Array<Dictionary<String, String>> {
                        for update in updates {
                            print("title", update["title"]!)
                            print("title", update["date"]!)
                            print("title", update["body"]!)
                            self.updateTitleArray.append(update["title"]!)
                            self.updateDateArray.append(update["date"]!)
                            self.updateBodyArray.append(update["body"]!)
                            
                        }
                    }
                    
                    if let testflights = json["testflight"] as? Array<Dictionary<String, String>> {
                        for testflight in testflights {
                            self.testflightUpdateTitleArray.append(testflight["title"]!)
                            self.testflightUpdateDateArray.append(testflight["date"]!)
                            self.testflightUpdateBodyArray.append(testflight["body"]!)
                            
                        }
                    }
                    
                    if let knownIssues = json["known issues"] as? Array<Dictionary<String, String>> {
                        for knownIssue in knownIssues {
                            self.knownIssuesTitleArray.append(knownIssue["title"]!)
                            
                        }
                    }
                    
                    if let roadmaps = json["roadmap"] as? Array<Dictionary<String, String>> {
                        for roadmap in roadmaps {
                            self.roadMapTitleArray.append(roadmap["title"]!)
                            
                        }
                    }
                }
                         
                     } catch let error as NSError {
                         print("Failed to load: \(error.localizedDescription)")
                     }
        }
        tableView.reloadData()
        task.resume()
        tableView.reloadData()
        }
        
    }


