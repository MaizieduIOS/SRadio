//
//  SRChannelTableViewController.swift
//  TestRadio
//
//  Created by Wentao on 15/5/13.
//  Copyright (c) 2015年 Wentao. All rights reserved.
//

import UIKit
import KGFloatingDrawer

class SRChannelTableViewController: UITableViewController, HttpProtocol {

    var delegate:SRChannelProtocol?
    
    var channelList:[NSDictionary] = [NSDictionary]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let mNetWorkTool : SRNetworkTool = SRNetworkTool()
    private let mChannelListUrl : String = "http://www.douban.com/j/app/radio/channels"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.mNetWorkTool.delegate = self
        self.mNetWorkTool.search(self.mChannelListUrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channelList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "reuse")
        // Configure the cell...
        cell.textLabel?.text = self.channelList[indexPath.row].objectForKey("name") as? String
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).drawerViewController.closeDrawer(KGDrawerSide.Right, animated: true) { (finished) -> Void in
            
        }
        var dic = self.channelList[indexPath.row]
        
        self.delegate?.onChannelChange(self.channelList[indexPath.row].objectForKey("channel_id") as! String)
    }

    func didRecieveResults(results: NSDictionary) {
        if results["channels"] != nil {
            self.channelList = results["channels"] as! [NSDictionary]
            self.tableView.reloadData()
        }
    }
}
