import UIKit
import VTextView
import SnapKit

class ViewController: UIViewController {
    
    enum TypingScope: VTextAttribute {
        
        case normal
        case bold
        
        var attributes: [NSAttributedString.Key : Any] {
            switch self {
            case .normal:
                return [.font: UIFont.systemFont(ofSize: 15),
                        .foregroundColor: UIColor.black]
            case .bold:
                return [.font: UIFont.systemFont(ofSize: 15, weight: .bold),
                        .foregroundColor: UIColor.black]
            }
        }
        
        var defaultAttribute: [NSAttributedString.Key: Any] {
            return TypingScope.normal.attributes
        }
    }
    
    let textView = VTextView.init(typingAttributes: TypingScope.normal)
    let controlView = TypingControlView(frame: .zero)
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "Editor"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.initLayout()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func initLayout() {
        
        self.view.addSubview(textView)
        textView.snp.makeConstraints({ make in
            make.top.equalTo(self.view.safeArea.top)
            make.trailing.leading.equalToSuperview()
            make.bottom.equalTo(self.view.safeArea.bottom)
        })
        
        self.view.addSubview(controlView)
        controlView.snp.makeConstraints({ make in
            make.trailing.equalToSuperview().inset(15.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(40.0)
        })
        
        controlView.boldControlView.addTarget(self, action: #selector(didTapBold), for: .touchUpInside)
        controlView.dismissControlView.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
    }

    @objc func didTapBold() {
        if controlView.boldControlView.isSelected {
            controlView.boldControlView.isSelected = false
            self.textView.setTypingAttribute(TypingScope.normal)
        } else {
            controlView.boldControlView.isSelected = true
            self.textView.setTypingAttribute(TypingScope.bold)
        }
    }
    
    @objc func didTapDismiss() {
        self.textView.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        textView.snp.remakeConstraints({ make in
            make.top.equalTo(self.view.safeArea.top)
            make.trailing.leading.equalToSuperview()
            make.bottom.equalTo(self.view.safeArea.bottom).inset(keyboardSize.height)
        })
        
        controlView.snp.remakeConstraints({ make in
            make.trailing.equalToSuperview().inset(40.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(40.0 + keyboardSize.height)
        })
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        
        textView.snp.remakeConstraints({ make in
            make.top.equalTo(self.view.safeArea.top)
            make.trailing.leading.equalToSuperview()
            make.bottom.equalTo(self.view.safeArea.bottom)
        })
        
        controlView.snp.remakeConstraints({ make in
            make.trailing.equalToSuperview().inset(40.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(40.0)
        })
    }

}

class TypingControlView: UIView {
    
    lazy var boldControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.system)
        button.setTitle("Bold", for: .normal)
        button.setTitle("Bold", for: .selected)
        button.setTitleColor(UIColor.lightGray, for: .normal)
        button.setTitleColor(UIColor.white, for: .selected)
        button.backgroundColor = .lightGray
        return button
    }()
    
    lazy var dismissControlView: UIButton = {
        let button = UIButton.init(type: UIButton.ButtonType.system)
        button.setTitle("Dismiss", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = .red
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

extension UIView {
    
    var safeArea: ConstraintBasicAttributesDSL {
        
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        return self.snp
    }
}
