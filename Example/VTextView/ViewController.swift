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
    
    let textView = VTextView(typingStyle: TypingScope.normal)
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
            make.trailing.equalToSuperview().inset(10.0)
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
            make.trailing.equalToSuperview().inset(10.0)
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
            make.trailing.equalToSuperview().inset(10.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(40.0)
        })
    }
    
}

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

extension UIView {
    
    var safeArea: ConstraintBasicAttributesDSL {
        
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        return self.snp
    }
}

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
