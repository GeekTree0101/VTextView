import Foundation
import SnapKit
import UIKit

extension UIView {
    
    var safeArea: ConstraintBasicAttributesDSL {
        
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        return self.snp
    }
}
