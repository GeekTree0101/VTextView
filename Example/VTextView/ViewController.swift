import UIKit
import VTextView
import SnapKit
import RxSwift
import RxCocoa
import BonMot

class ViewController: UIViewController {
    
    // Convenience VTextStyler key enum
    enum TypingScope: String {
        case normal
        case bold
        case italic
        case heading
        case quote
        case link
    }
    
    // Create VTextView
    lazy var textView = VTextView(manager: manager)
    
    let controlView = TypingControlView(frame: .zero)
    let disposeBag = DisposeBag()
    
    lazy var manager: VTextManager = {
        let manager = VTextManager([.init(TypingScope.normal.rawValue,
                                            xmlTag: "p"),
                                      .init(TypingScope.bold.rawValue,
                                            xmlTag: "b"),
                                      .init(TypingScope.italic.rawValue,
                                            xmlTag: "i"),
                                      .init(TypingScope.link.rawValue,
                                            xmlTag: "a",
                                            isTouchEvent: true),
                                      .init(TypingScope.heading.rawValue,
                                            xmlTag: "h2",
                                            isBlockStyle: true),
                                      .init(TypingScope.quote.rawValue,
                                            xmlTag: "blockquote",
                                            isBlockStyle: true)],
                                     defaultKey: TypingScope.normal.rawValue)
        manager.typingDelegate = self
        manager.parserDelegate = self
        manager.accessoryDelegate = self
        return manager
    }()
    
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
        self.observeKeyboardEvent()
        
        // test
        guard let path = Bundle.main.path(forResource: "content", ofType: "xml"),
            case let pathURL = URL(fileURLWithPath: path),
            let data = try? Data(contentsOf: pathURL),
            let content = String(data: data, encoding: .utf8) else { return }
        self.textView.applyXML(content)
        
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem.init(title: "Build",
                                 style: .plain,
                                 target: self,
                                 action: #selector(build))
    }
    
    private func initEvent() {
        
        controlView.dismissControlView.rx.tap.subscribe(onNext: { [weak self] _ in
            _ = self?.textView.resignFirstResponder()
        }).disposed(by: disposeBag)
    }
}

extension ViewController: VTextAccessoryDelegate {
    
    enum AccessoryScope: String {
        
        case userTag = "@(\\w*[0-9A-Za-z])"
        case hashTag = "#(\\w*[0-9A-Za-zㄱ-ㅎ가-힣])"
        
        var regex: NSRegularExpression {
            return try! NSRegularExpression(pattern: self.rawValue, options: [])
        }
        
        var style: StringStyle? {
            switch self {
            case .userTag:
                return .init([.color(UIColor.init(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0))])
            case .hashTag:
                return .init([.color(UIColor.init(red: 0.2, green: 0.3, blue: 0.7, alpha: 1.0))])
            }
        }
    }
    
    func accessoryWithAttribute() -> [NSRegularExpression : StringStyle?] {
        return [AccessoryScope.userTag.regex: AccessoryScope.userTag.style,
                AccessoryScope.hashTag.regex: AccessoryScope.hashTag.style]
    }
    
    func handleTouchEvent(_ target: NSRegularExpression, value: Any) {
        guard let target = AccessoryScope(rawValue: target.pattern) else { return }
        
        switch target {
        case .userTag:
            guard let username = value as? String else {
                return
            }
            let toast = UIAlertController(title: "You did tap username: \(username)",
                message: nil,
                preferredStyle: .alert)
            toast.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(toast, animated: true, completion: nil)
        case .hashTag:
            guard let tag = value as? String else {
                return
            }
            let toast = UIAlertController(title: "You did tap hashTag: \(tag)",
                message: nil,
                preferredStyle: .alert)
            toast.addAction(.init(title: "OK", style: .cancel, handler: nil))
            self.present(toast, animated: true, completion: nil)
        }
    }
    
    func detectLength(_ target: NSRegularExpression) -> Int? {
        guard let target = AccessoryScope(rawValue: target.pattern) else { return nil }
        
        switch target {
        case .userTag:
            return 15 // username maxium length is 15
        case .hashTag:
            return 10 // hashTag maxium length is 10
        }
    }
    
    func handleLink(_ url: URL) {
        UIApplication.shared.openURL(url)
    }
}

extension ViewController: VTextParserDelegate {
    
    func customXMLTagAttribute(context: VTypingContext,
                               attributes: [NSAttributedString.Key : Any]) -> String? {
        
        if context.key == TypingScope.link.rawValue,
            let link = attributes[.link] as? URL {
            return "href=\"\(link)\""
        }
        
        return nil
    }
    
    
    func mutatingAttribute(key: String,
                           attributes: [String : String],
                           currentStyle: StringStyle) -> StringStyle? {
        guard let currentKey = TypingScope(rawValue: key) else { return nil }
        
        switch currentKey {
        case .link:
            if let urlString = attributes["href"],
                let url = URL(string: urlString) {
                return currentStyle.byAdding(.link(url))
            }
            return nil
        default:
            return nil
        }
    }
}

extension ViewController: VTextTypingDelegate {
    
    func typingAttributes(key: String) -> StringStyle {
        guard let scope = TypingScope.init(rawValue: key) else {
            return .init([.font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        }
        
        switch scope {
        case .bold:
            return .init([.emphasis(.bold),
                          .font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        case .italic:
            return .init([.emphasis(.italic),
                          .font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        case .heading:
            return .init([.font(UIFont.systemFont(ofSize: 30, weight: .medium)),
                          .color(.black)])
        case .quote:
            return .init([.font(UIFont.systemFont(ofSize: 20)),
                          .color(.gray),
                          .firstLineHeadIndent(19.0),
                          .headIndent(19.0)])
        case .link:
            return .init([.font(UIFont.systemFont(ofSize: 15)),
                          .color(.black),
                          .underline(.single, .black)])
        case .normal:
            return .init([.font(UIFont.systemFont(ofSize: 15)),
                          .color(.black)])
        }
    }
    
    func bindEvents(_ manager: VTextManager) {
        manager.bindControlEvent(controlView.boldControlView,
                                 key: TypingScope.bold.rawValue)
        manager.bindControlEvent(controlView.italicControlView,
                                 key: TypingScope.italic.rawValue)
        manager.bindControlEvent(controlView.headingControlView,
                                 key: TypingScope.heading.rawValue)
        manager.bindControlEvent(controlView.quoteControlView,
                                 key: TypingScope.quote.rawValue)
    }
    
    func enableKeys(_ inActiveKey: String) -> [String]? {
        guard let key = TypingScope(rawValue: inActiveKey) else { return nil }
        
        switch key {
        case .heading, .quote:
            return [TypingScope.bold.rawValue,
                    TypingScope.italic.rawValue,
                    TypingScope.normal.rawValue]
        default:
            return nil
        }
    }
    
    func disableKeys(_ activeKey: String) -> [String]? {
        guard let key = TypingScope(rawValue: activeKey) else { return nil }
        
        switch key {
        case .heading, .quote:
            return [TypingScope.bold.rawValue,
                    TypingScope.italic.rawValue,
                    TypingScope.normal.rawValue]
        default:
            return nil
        }
    }
    
    func inactiveKeys(_ activeKey: String) -> [String]? {
        guard let key = TypingScope(rawValue: activeKey) else { return nil }
        
        switch key {
        case .heading:
            return [TypingScope.quote.rawValue]
        case .quote:
            return [TypingScope.heading.rawValue]
        default:
            return nil
        }
    }
    
    func activeKeys(_ inactiveKey: String) -> [String]? {
        return nil
    }
}

extension ViewController {
    
    @objc func build() {
        
        guard let output = self.textView.buildToXML(packageTag: "content") else {
            return
        }
        let vc = XMLViewer.init(output)
        self.navigationController?.pushViewController(vc, animated: true)
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
            make.leading.equalToSuperview().inset(5.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(5.0)
        })
    }
    
    private func observeKeyboardEvent() {
        // keyboard
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        textView.snp.remakeConstraints({ make in
            make.top.equalTo(self.view.safeArea.top)
            make.trailing.leading.equalToSuperview()
            make.bottom.equalTo(self.view.safeArea.bottom).inset(keyboardSize.height)
        })
        
        controlView.snp.remakeConstraints({ make in
            make.leading.equalToSuperview().inset(5.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(5.0 + keyboardSize.height)
        })
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        
        textView.snp.remakeConstraints({ make in
            make.top.equalTo(self.view.safeArea.top)
            make.trailing.leading.equalToSuperview()
            make.bottom.equalTo(self.view.safeArea.bottom)
        })
        
        controlView.snp.remakeConstraints({ make in
            make.leading.equalToSuperview().inset(5.0)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(5.0)
        })
    }
}
