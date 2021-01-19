import UIKit

@IBDesignable class CardView: UIView {
    
    @IBInspectable var cornerradious: CGFloat = 2
    
    @IBInspectable var shadowOffSetWidth: CGFloat = 0
    
    @IBInspectable var shadowOffSetHeight: CGFloat = 3
    
    @IBInspectable var shadowColor: UIColor = UIColor.black
    
    @IBInspectable var shadowOpacity: CGFloat = 0.1
    
    override func layoutSubviews() {
        layer.cornerRadius = cornerradious
        
        layer.shadowColor = shadowColor.cgColor
        
        layer.shadowOffset = CGSize(width: shadowOffSetWidth, height: shadowOffSetHeight)
        
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerradious)
        
        layer.shadowPath = shadowPath.cgPath
        
        layer.shadowOpacity = Float(shadowOpacity)
    }
    
    
}
