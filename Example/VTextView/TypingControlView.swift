import Foundation
import UIKit
import SnapKit

class TypingControlView: UIView {
    
    lazy var boldControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.setTitle("B", for: .normal)
        button.setTitle("B", for: .selected)
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.setTitleColor(UIColor.blue, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25.0).bold()
        button.backgroundColor = .clear
        
        button.clipsToBounds = true
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var italicControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.setTitle("i", for: .normal)
        button.setTitle("i", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25.0).boldItalics()
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.setTitleColor(UIColor.blue, for: .selected)
        
        button.clipsToBounds = true
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var headingControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.setTitle("H", for: .normal)
        button.setTitle("H", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25.0).bold()
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.setTitleColor(UIColor.blue, for: .selected)
        button.backgroundColor = .clear
        
        button.clipsToBounds = true
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var quoteControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.setTitle("Q", for: .normal)
        button.setTitle("Q", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25.0).bold()
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.setTitleColor(UIColor.blue, for: .selected)
        button.backgroundColor = .clear
        
        button.clipsToBounds = true
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var dismissControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.setTitle("X", for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25.0).bold()
        
        button.clipsToBounds = true
        button.backgroundColor = .clear
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return button
    }()
    
    lazy var controlStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: controlSubContentViews)
        view.spacing = 20.0
        view.axis = .horizontal
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var controlSubContentViews: [UIView] = [boldControlView,
                                                 italicControlView,
                                                 quoteControlView,
                                                 headingControlView,
                                                 dismissControlView]
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(controlStackView)
        
        controlStackView.snp.makeConstraints({ make in
            make.edges.equalToSuperview().inset(30.0)
        })
        
        for view in controlSubContentViews {
            view.snp.makeConstraints({ make in
                make.size.equalTo(CGSize(width: 40.0, height: 40.0))
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
