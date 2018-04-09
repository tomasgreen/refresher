//
//  ViewController.swift
//  Refresher
//
//  Created by Tomas Green on 2017-11-30.
//  Copyright © 2017 Tomas Green. All rights reserved.
//

import UIKit
import Refresher

class People : Decodable {
    var name:String
    var email:String
    var phone:String
    var avatar:URL
}

class PersonTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel:UILabel?
    @IBOutlet var infoLabel:UILabel?
    @IBOutlet var avatar:UIImageView?
}
extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}
class ViewController: UITableViewController {
    var searchController = UISearchController(searchResultsController: nil)
    var items = [People]()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.searchController = searchController
        self.navigationItem.searchController?.searchBar.searchBarStyle = .minimal
        self.navigationItem.searchController?.searchBar.tintColor = UIColor.white
        self.tableView.addRefresherWithAction {
            self.download()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
        cell.nameLabel?.text = items[indexPath.row].name
        cell.infoLabel?.text = items[indexPath.row].email
        return cell
    }
    func download() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (timer) in
            self.tableView.endRefreshing()
        }
        /*return
        guard let url = URL(string:"http://192.168.1.103:8080") else {
            return
        }
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, rsponse, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.items = []
                    self.refresh?.endRefreshing()
                    self.tableView.reloadData()
                }
                return
            }
            do {
                let result = try JSONDecoder().decode([People].self, from: data)
                if let p = result.first {
                    
                }
                DispatchQueue.main.async {
                    self.items = result
                    self.refresh?.endRefreshing()
                    self.tableView.reloadData()
                }
            } catch {
                print(error)
            }
        })
        task.resume()*/
    }
    func download(url:URL, indexPath:IndexPath) {
        
    }
    @IBAction func refresh(sender:Any?) {
        self.tableView.beginRefreshing()
    }
}

