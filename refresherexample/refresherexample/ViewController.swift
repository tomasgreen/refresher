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
    let name:String
    let email:String
    let phone:String
    let avatar:URL
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
    var refresh:Refresher?
    var items = [People]()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refresh = Refresher(scrollView: self.tableView,viewController: self, style: .scrollView)
        refresh?.didPullDown = {
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
                    DispatchQueue.main.async {
                        self.items = result
                        self.refresh?.endRefreshing()
                        self.tableView.reloadData()
                    }
                } catch {
                    print(error)
                }
            })
            task.resume()
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
    func download(url:URL, indexPath:IndexPath) {
        
    }
    @IBAction func refresh(sender:Any?) {
        self.refresh?.startRefreshing(force: true)
    }
}

