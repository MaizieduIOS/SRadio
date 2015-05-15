//
//  HttpController.swift
//  TestRadio
//
//  Created by Wentao on 15/5/11.
//  Copyright (c) 2015年 Wentao. All rights reserved.
//

import UIKit
import Alamofire

protocol HttpProtocol{
    
    func didRecieveResults(results:NSDictionary)
    
}

class SRNetworkTool:NSObject{
    
    var delegate:HttpProtocol?
    
    func search(url:String){
        //两种做法：原生+Alamofire
//        var nsUrl:NSURL = NSURL(string: url)!
//        var request:NSURLRequest = NSURLRequest(URL: nsUrl)
//        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
//            (response, data, error) -> Void in
//            println(data)
//            var jsonResult:NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
//            self.delegate?.didRecieveResults(jsonResult)
//        })
        Alamofire.request(.GET, url, parameters: nil, encoding: ParameterEncoding.URL).responseJSON(options: NSJSONReadingOptions.AllowFragments) { (request, response, json, error) -> Void in
            self.delegate?.didRecieveResults(json as! NSDictionary)
        }
    }
}
