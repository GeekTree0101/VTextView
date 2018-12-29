import Foundation
import UIKit

class TypingControlView: UIView {
    
    lazy var boldControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.system)
        button.setTitle("Bold", for: .normal)
        button.setTitle("Bold", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white, for: .selected)
        button.setBackgroundImage(UIImage.backgroundImage(withColor: .gray), for: .normal)
        button.setBackgroundImage(UIImage.backgroundImage(withColor: .blue), for: .selected)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 10.0
        button.clipsToBounds = true
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var dismissControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.system)
        button.setTitle("Dismiss", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setBackgroundImage(UIImage.backgroundImage(withColor: .red), for: .normal)
        button.layer.cornerRadius = 10.0
        button.clipsToBounds = true
        button.backgroundColor = .clear
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var controlStackView: UIStackView = {
        let view = UIStackView.init(arrangedSubviews: [boldControlView, dismissControlView])
        view.spacing = 20.0
        view.axis = .horizontal
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(controlStackView)
        
        self.layer.cornerRadius = 20.0
        controlStackView.snp.makeConstraints({ make in
            make.edges.equalToSuperview().inset(20.0)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
