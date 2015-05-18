//
//  SRImageView.swift
//  
//
//  Created by Wentao on 15/5/8.
//
//

import UIKit

class SRImageView: UIImageView {
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.width/2
        
//        var roundLayer =
    }
    
    func startRoatating() {
        let rotate = CABasicAnimation(keyPath: "transform.rotation")
        rotate.fromValue = 0.0
        rotate.toValue = M_PI * 2.0
        rotate.duration = 20
        rotate.repeatCount = MAXFLOAT
        
        self.layer.addAnimation(rotate, forKey: nil)
    }
    
    func setAlbumImage(image:UIImage) {
        let albumView = UIImageView(image: image)
        
        albumView.frame = CGRectMake(self.frame.size.width / 2 - 81, self.frame.size.height / 2 - 81, 162, 162)
        
        //custom albumView
        albumView.clipsToBounds = true
        albumView.layer.cornerRadius = albumView.frame.width/2.0
        
        
        self.addSubview(albumView)
    }
    
    func stopRotate() {
        self.layer.removeAllAnimations()
    }
    
    func pauseRotate() {
        let pausedTime = self.layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        self.layer.speed = 0.0
        self.layer.timeOffset = pausedTime
    }
    
    func resumeRotate() {
        let pauseTime = self.layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pauseTime
        layer.beginTime = timeSincePause
    }
}
