import UIKit
import VTextView
import SnapKit

class ViewController: UIViewController {
    
    // Convenience VTextStyler key enum
    enum TypingScope: String {
        
        case normal
        case bold
    }
    
    // DEFINE Stylers
    let stylers: [VTextStyler] =
        [.init(TypingScope.normal.rawValue,
               attributes: [.font: UIFont.systemFont(ofSize: 15),
                            .foregroundColor: UIColor.black],
               xmlTag: "p"),
         .init(TypingScope.bold.rawValue,
               attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold),
                            .foregroundColor: UIColor.black],
               xmlTag: "b")]
    
    // Create VTextView
    lazy var textView = VTextView(stylers: self.stylers,
                                  defaultKey: TypingScope.normal.rawValue)
    
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
        self.initEvent()
        
        // test
        self.textView.applyXML("<content><p>plain\n</p><b>bold</b></content>")
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
    }
    
    private func initEvent() {
        // keyboard
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // control button
        controlView.boldControlView.addTarget(self, action: #selector(didTapBold), for: .touchUpInside)
        controlView.dismissControlView.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
    }
}

extension ViewController {
    
    @objc func didTapBold() {
        if controlView.boldControlView.isSelected {
            controlView.boldControlView.isSelected = false
            self.textView.setTypingAttribute(key: TypingScope.normal.rawValue)
        } else {
            controlView.boldControlView.isSelected = true
            self.textView.setTypingAttribute(key: TypingScope.bold.rawValue)
        }
    }
    
    @objc func didTapDismiss() {
        _ = self.textView.resignFirstResponder()
        print("DEBUG* \(self.textView.buildToXML(packageTag: "content") ?? "" )")
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
