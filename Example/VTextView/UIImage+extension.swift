import UIKit

extension UIImage {
    
    static func backgroundImage(withColor color: UIColor) -> UIImage? {
        return self.backgroundImage(withColor: color, size: CGSize(width: 1, height: 1))
    }
    
    static func backgroundImage(withColor color: UIColor, size: CGSize) -> UIImage? {
        var rect: CGRect = .zero
        rect.size = size
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

