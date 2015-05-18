//
//  SRPlayerViewController.swift
//  TestRadio
//
//  Created by Wentao on 15/5/11.
//  Copyright (c) 2015年 Wentao. All rights reserved.
//

import UIKit
import KGFloatingDrawer
import Alamofire

struct PlayStatus {
    static let PLAYING:Int  = 0
    static let PAUSE:Int    = 1
    static let STOP:Int     = 2
}

struct SRNotifications {
    static let ApplicationEnterBackgroundNotification   =   "ApplicationEnterBackgroundNotification"
}

protocol SRChannelProtocol {
    func onChannelChange(id:String)
}

class SRPlayerViewController: UIViewController, HttpProtocol, SRChannelProtocol, UITableViewDataSource{

    @IBOutlet weak var mMainBGImageView: UIImageView!
    @IBOutlet weak var mAlbumImageView: SRImageView!
    @IBOutlet weak var mTitleLabel: UILabel!
    @IBOutlet weak var mPreBtn: UIButton!
    @IBOutlet weak var mPlayBtn: UIButton!
    @IBOutlet weak var mNextBtn: UIButton!
    @IBOutlet weak var mTimeBar: UILabel!
    @IBOutlet weak var mPlayProgressBar: UIProgressView!
    @IBOutlet weak var mArtist: UILabel!
    @IBOutlet weak var mTitleView: UIView!
    @IBOutlet weak var mLrcTable: UITableView!
    
    private var mNeedImage: UIImageView!
    
    private var mOriginTransform : CGAffineTransform?
    private var mSongsArray : [NSDictionary] = [NSDictionary]()
    private var mPhotoArray = Dictionary<String, UIImage>()
    private let mNetWorkTool : SRNetworkTool = SRNetworkTool()
    
    private let mSongListUrl : String = "http://www.douban.com/j/app/radio/people?app_name=radio_desktop_win&version=100&type=n&channel="
    private let mLyricUrl : String = "http://geci.me/api/lyric/"
//    private let mLyricUrl : String = "http://mp3.baidu.com/dev/api/?tn=getinfo&ct=0&word=小苹果&ie=utf-8&format=json"
    
    private var mCurrentSongIndex = 0
    private var mUpdateTimer : NSTimer?
    private var mPlayingStatus : Int = PlayStatus.STOP
    
    private var mLRCDictinary : [String : String] = [String : String]()
    private var mTimeArray : [String] = [String]()
    private var mIsLRCPrepared : Bool = false
    private var mLineNumber : Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var screenBounds = UIScreen.mainScreen().bounds
        self.mNeedImage = UIImageView(frame: CGRectMake((screenBounds.width - 96) / 2 + 96 * 0.25, 45, 96, 153))
        self.mNeedImage.image = UIImage(named: "cm2_play_needle_play-ip6")
        self.view.addSubview(self.mNeedImage)
        self.view.bringSubviewToFront(self.mTitleView)
        self.mOriginTransform = self.mNeedImage.transform
        self.setAnchorPoint(CGPointMake(0.25, 0.16), forView: self.mNeedImage)
        self.rotateNeedle(false)
        
        self.mLrcTable.userInteractionEnabled = false
        self.mLrcTable.backgroundView = nil
        self.mLrcTable.backgroundView = UIView()
        self.mLrcTable.backgroundView?.backgroundColor = UIColor.clearColor()
        self.mLrcTable.backgroundColor = UIColor.clearColor()
        self.mLrcTable.dataSource = self
        
        var glassEffect = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        glassEffect.frame = UIScreen.mainScreen().bounds
        glassEffect.alpha = 1.0

        self.mMainBGImageView.addSubview(glassEffect)
        
        KVNProgress.setConfiguration(KVNProgressConfiguration.defaultConfiguration())
        
        self.mNetWorkTool.delegate = self
        self.mNetWorkTool.search(self.mSongListUrl + "1")
    }
    
    override func viewDidAppear(animated: Bool) {
        KVNProgress.showWithStatus("Loading...")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button Click Actions
    @IBAction func onPreClicked(sender: AnyObject) {
        
    }
    
    @IBAction func onPlayClicked(sender: AnyObject) {
        switch self.mPlayingStatus {
        case PlayStatus.STOP:
            self.playMusic(self.mSongsArray[self.mCurrentSongIndex])
            self.mPlayBtn.setImage(UIImage(named: "cm2_play_btn_pause"), forState: UIControlState.Normal)
            break
        case PlayStatus.PLAYING:
            self.pause()
            self.mPlayBtn.setImage(UIImage(named: "cm2_play_btn_pause"), forState: UIControlState.Normal)
            break
        case PlayStatus.PAUSE:
            self.resume()
            self.mPlayBtn.setImage(UIImage(named: "cm2_lay_icn_topplay"), forState: UIControlState.Normal)
            break
        default:
            break
        }
    }
    
    @IBAction func onNextClicked(sender: AnyObject) {
        self.playNext()
    }
    
    @IBAction func onMenuClicked(sender: AnyObject) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).drawerViewController.toggleDrawer(KGDrawerSide.Right, animated: true) { (finished) -> Void in
        }
    }
    
    // MARK: - Data Request
    func didRecieveResults(results: NSDictionary) {
        KVNProgress.dismiss()
        if(results["song"] != nil && self.mSongsArray.count == 0){
            self.mSongsArray = results["song"] as! [NSDictionary]
            self.setupMusicInfo(self.mSongsArray[0])
            //Load Image
            let imgUrl:String = self.mSongsArray[0].valueForKey("picture") as! String
            loadImage(imgUrl)
            loadLRC(self.mSongsArray[0].valueForKey("title") as! String, artist: self.mSongsArray[0].valueForKey("artist") as! String)
        } else if results["song"] != nil && self.mSongsArray.count > 0 {
            println(self.mSongsArray)
            self.mSongsArray += results["song"] as! [NSDictionary]
        } else {
            KVNProgress.showErrorWithStatus("加载音乐失败")
        }
        
        println("song count: \(self.mSongsArray.count)\n------------")
        for i in 0..<self.mSongsArray.count {
            println(self.mSongsArray[i].objectForKey("title") as! String)
        }
        println("------------")
    }
    
    func loadImage(url:String){
//        let image = self.mPhotoArray[url]
//        if image == nil {
            let imgURL:NSURL = NSURL(string: url)!
            let request:NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
                (response, data, error) -> Void  in
                let img = UIImage(data: data)
                self.mMainBGImageView.image = img
                self.mAlbumImageView.setAlbumImage(img!)
                self.mPhotoArray[url] = img
            })
//        }else{
//            self.mMainBGImageView.image = image
//            self.mAlbumImageView.image = image
//        }
    }
    
    // MARK: - Play Control
    func setupMusicInfo(songDic:NSDictionary) {
        mUpdateTimer?.invalidate()
        mTimeBar.text = "00:00 / 00:00"
        mTitleLabel.text = songDic.valueForKey("title") as? String
        mArtist.text = songDic.valueForKey("artist") as? String
    }
    
    func playMusic(songDic:NSDictionary) {
        //Clear View
        self.setupMusicInfo(songDic)
        
        let imgUrl:String = songDic.valueForKey("picture") as! String
        self.loadImage(imgUrl)
        
        //Play Music
        AFSoundManager.sharedManager().startStreamingRemoteAudioFromURL(songDic.valueForKey("url") as! String, andBlock: { (percentage, elapsedTime, timeRemaining, error, finished) -> Void in
            if error != nil {
                println(error)
            } else {
                if finished {
                    
                } else {
                    self.mPlayProgressBar.setProgress(CFloat(percentage) * 0.01, animated: true)

                    func generateString(time:CGFloat) -> String {
                        if !time.isNaN {
                            let all:Int = Int(time)
                            let m:Int = all%60
                            let f:Int = Int(all/60)
                            var time:String = ""
                            //小时
                            if f<10{
                                time = "0\(f):"
                            }else{
                                time = "\(f):"
                            }
                            // 分钟
                            if m<10{
                                time += "0\(m)"
                            }else{
                                time += "\(m)"
                            }
                            return time
                        } else {
                            return "00:00"
                        }
                    }
                    self.mTimeBar.text = generateString(elapsedTime) + " / " + generateString(timeRemaining)
                    
                    if self.mIsLRCPrepared {
                        self.updateLRC(elapsedTime)
                    }
                }
            }
        })
        
        self.mAlbumImageView.startRoatating()
        self.rotateNeedle(true)
        
        self.mPlayingStatus = PlayStatus.PLAYING
    }
    
//    func generateString(timer:CGFloat) -> String {
//        
//        return time
//    }
    
    func pause() {
        self.mAlbumImageView.pauseRotate()
        self.rotateNeedle(false)
        
        AFSoundManager.sharedManager().pause()
        
        self.mPlayingStatus = PlayStatus.PAUSE
    }
    
    func resume() {
        self.mAlbumImageView.resumeRotate()
        self.rotateNeedle(true)
        
        AFSoundManager.sharedManager().resume()
        
        self.mPlayingStatus = PlayStatus.PLAYING
    }
    
    func playNext() {
        if self.mCurrentSongIndex + 1 == self.mSongsArray.count {
//            self.mNetWorkTool.search(self.mSongListUrl + "1")
            KVNProgress.showWithStatus("Loading...")
        } else if self.mCurrentSongIndex + 2 == self.mSongsArray.count {
            self.mNetWorkTool.search(self.mSongListUrl + "1")
        }
        
        if ++self.mCurrentSongIndex < self.mSongsArray.count {
            var song = self.mSongsArray[self.mCurrentSongIndex]
            self.playMusic(song)
            //Load Image
            let imgUrl:String = song.valueForKey("picture") as! String
            loadImage(imgUrl)
            loadLRC(song.valueForKey("title") as! String, artist: song.valueForKey("artist") as! String)
        }
        
    }
    
    func musicFinished(notification:NSNotification) {
        playNext()
    }
    
    // MARK: - Animate
    func rotateNeedle(isPlaying : Bool) {
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            if !isPlaying {
                self.mNeedImage.transform = CGAffineTransformMakeRotation(-CGFloat(M_PI / 6))
            } else {
                self.mNeedImage.transform = self.mOriginTransform!
            }
            }) { (finished) -> Void in
        }
    }
    
    private func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
    
    // MARK: - Channel Delegate
    func onChannelChange(id: String) {
        //Stop Play
        AFSoundManager.sharedManager().stop()
        self.mPlayingStatus = PlayStatus.STOP
        self.mSongsArray.removeAll(keepCapacity: false)
        
        //Clear View
        self.mAlbumImageView.stopRotate()
        self.rotateNeedle(false)
        
        //Load Data
        KVNProgress.showWithStatus("Loading...")
        self.mNetWorkTool.search(self.mSongListUrl + id)
    }
    
    //MARK: - LRC Operation
    func loadLRC(name:String, artist:String) {
        self.mIsLRCPrepared = false
        let url = self.mLyricUrl + name + "/" + artist
        Alamofire.request(.GET, url.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!, parameters: nil, encoding: ParameterEncoding.JSON).responseJSON(options: NSJSONReadingOptions.AllowFragments) { (_, _, json, _) -> Void in
            if json != nil && json?.objectForKey("count") as! Int  > 0 {
                let lrcUrl = (json?.objectForKey("result") as! [NSDictionary])[0].objectForKey("lrc") as! String
                let tempArrA = lrcUrl.componentsSeparatedByString("/")
                var lrcPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]  as! String) + "/" + tempArrA[tempArrA.count - 1]
                
                if NSFileManager.defaultManager().fileExistsAtPath(lrcPath) {
                    self .prepareLRC(lrcPath)
                } else {
                    let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
                    Alamofire.download(.GET, lrcUrl, destination).response({ (_, response, data, error) -> Void in
                        println(data)
                        if error == nil {
                            self .prepareLRC(lrcPath)
                        } else {
                            KVNProgress.showErrorWithStatus("歌词下载失败")
                        }
                    })
                }
            } else {
//                self.mLrcLabel.text = "此歌曲暂无歌词"
            }
        }
    }
    
    func prepareLRC(lrcPath:String) {
        //load lrc
        var contentStr = NSString(contentsOfFile: lrcPath, encoding: NSUTF8StringEncoding, error: nil)
        
        var lrcArray = contentStr?.componentsSeparatedByString("\n") as! [String]
        
        self.mLRCDictinary = [String : String]()
        self.mTimeArray = [String]()
        
        for line in lrcArray {
            var lineArr = line.componentsSeparatedByString("]") as [String]
            if count(lineArr[0]) > 8 {
                var str1 = (line as NSString).substringWithRange(NSRange(location: 3,length: 1))
                var str2 = (line as NSString).substringWithRange(NSRange(location: 6,length: 1))
                if str1 == ":" && str2 == "." {
                    var lrcStr = lineArr[1]
                    var timeStr = (lineArr[0] as NSString).substringWithRange(NSRange(location: 1, length: 5))
                    self.mLRCDictinary[timeStr] = lrcStr
                    self.mTimeArray.append(timeStr)
                    
                }
            }
        }
        println("lrc load finished!")
        self.mIsLRCPrepared = true
        self.mLrcTable.reloadData()
    }
    
    func updateLRC(currentTime:CGFloat) {
        for i in 0..<self.mLRCDictinary.count {
            var timeArr = self.mTimeArray[i].componentsSeparatedByString(":") as [String]
            var time = CGFloat(timeArr[0].toInt()!) * 60 + CGFloat(timeArr[1].toInt()!)
            if i + 1 < self.mTimeArray.count {
                var timeArr1 = self.mTimeArray[i + 1].componentsSeparatedByString(":") as [String]
                var time1 = CGFloat(timeArr1[0].toInt()!) * 60 + CGFloat(timeArr1[1].toInt()!)
                
                if currentTime > time && currentTime < time1 {
                    self.mLineNumber = i
                    self.mLrcTable.reloadData()
                    self.mLrcTable.selectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Middle)
                }
            }
        }
    }
    
    //MARK: - Table Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mTimeArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("lrcCell") as! SRLrcCell
        cell.mTitleLable.text = self.mLRCDictinary[self.mTimeArray[indexPath.row]]
        cell.backgroundColor = UIColor.clearColor()
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        cell.mTitleLable.numberOfLines = 0
        cell.mTitleLable.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        if self.mLineNumber == indexPath.row {
            cell.mTitleLable.font = UIFont.systemFontOfSize(14)
            cell.mTitleLable.textColor = UIColor.redColor()
        } else {
            cell.mTitleLable.font = UIFont.systemFontOfSize(12)
            cell.mTitleLable.textColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
