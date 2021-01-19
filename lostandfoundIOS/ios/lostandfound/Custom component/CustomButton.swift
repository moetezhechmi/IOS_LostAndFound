import Foundation
import UIKit

@IBDesignable class RoundButton: UIButton {
    
    @IBInspectable var shadowOffSetWidth: CGFloat = 0
    
    @IBInspectable var shadowOffSetHeight: CGFloat = 3
    
    @IBInspectable var shadowColor: UIColor = UIColor.black
    
    @IBInspectable var shadowOpacity: CGFloat = 0.1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override func prepareForInterfaceBuilder() {
        sharedInit()
    }
    
    func sharedInit() {
        // Common logic goes here
        refreshCorners(value: cornerRadius)
    }
    
    func refreshCorners(value: CGFloat) {
        layer.cornerRadius = value
        
        layer.shadowColor = shadowColor.cgColor
        
        layer.shadowOffset = CGSize(width: shadowOffSetWidth, height: shadowOffSetHeight)
        
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: value)
        
        layer.shadowPath = shadowPath.cgPath
        
        layer.shadowOpacity = Float(shadowOpacity)
        
        layer.masksToBounds = false
    }
    
    @IBInspectable var cornerRadius: CGFloat = 20 {
        didSet {
            refreshCorners(value: cornerRadius)
        }
    }
    
}
