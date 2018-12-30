import UIKit
import VTextView
import SnapKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    // Convenience VTextStyler key enum
    enum TypingScope: String {
        case normal
        case bold
        case italic
        case heading
        case quote
    }
    
    // Create VTextView
    lazy var textView = VTextView(manager: typingManager)
    
    let controlView = TypingControlView(frame: .zero)
    let disposeBag = DisposeBag()
    
    lazy var typingManager: VTypingManager = {
        let manager = VTypingManager([.init(TypingScope.normal.rawValue, xmlTag: "p"),
                                      .init(TypingScope.bold.rawValue, xmlTag: "b"),
                                      .init(TypingScope.italic.rawValue, xmlTag: "i"),
                                      .init(TypingScope.heading.rawValue, xmlTag: "h2"),
                                      .init(TypingScope.quote.rawValue, xmlTag: "blockquote")],
                                     defaultKey: TypingScope.normal.rawValue)
        manager.delegate = self
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

extension ViewController: VTypingManagerDelegate {
    
    func exceptionXMLParserBuildRule() -> [VTextXMLParserContext]? {
   
        return [VTextXMLParserContext(keys: [TypingScope.italic.rawValue,
                                             TypingScope.bold.rawValue],
                                      manager: typingManager)]
    }
    
    func bindEvents(_ manager: VTypingManager) {
        
        manager.bindControlEvent(controlView.boldControlView,
                                 key: TypingScope.bold.rawValue)
        manager.bindControlEvent(controlView.italicControlView,
                                 key: TypingScope.italic.rawValue)
        manager.bindControlEvent(controlView.headingControlView,
                                 key: TypingScope.heading.rawValue)
        manager.bindControlEvent(controlView.quoteControlView,
                                 key: TypingScope.quote.rawValue)
    }
    
    func attributes(activeKeys: [String]) -> [NSAttributedString.Key : Any] {
        
        if activeKeys.contains(TypingScope.italic.rawValue),
            activeKeys.contains(TypingScope.bold.rawValue) {
            return [.font: UIFont.systemFont(ofSize: 15).boldItalics(),
                    .foregroundColor: UIColor.black]
        } else if activeKeys.contains(TypingScope.italic.rawValue) {
            return [.font: UIFont.systemFont(ofSize: 15).italics(),
                    .foregroundColor: UIColor.black]
        } else if activeKeys.contains(TypingScope.bold.rawValue) {
            return [.font: UIFont.systemFont(ofSize: 15).bold(),
                    .foregroundColor: UIColor.black]
        } else if activeKeys.contains(TypingScope.heading.rawValue) {
            return [.font: UIFont.systemFont(ofSize: 30, weight: .medium),
                    .foregroundColor: UIColor.black]
        } else if activeKeys.contains(TypingScope.quote.rawValue) {
            return [.font: UIFont.systemFont(ofSize: 20),
                    .foregroundColor: UIColor.gray]
        } else if activeKeys.contains(TypingScope.normal.rawValue) {
            return [.font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.black]
        } else {
            return [:]
        }
    }
    
    func updateStatus(currentKey: String,
                      isActive: Bool,
                      prevActivedKeys: [String]) -> VTypingManager.StatusManageContext? {
        guard let key = TypingScope(rawValue: currentKey) else { return nil }
        var context = VTypingManager.StatusManageContext()
        
        if isActive {
            context.active.append(key.rawValue)
            context.inactive.append(TypingScope.normal.rawValue)
        } else {
            context.inactive.append(key.rawValue)
        }
        
        switch key {
        case .bold:
            if prevActivedKeys.contains(TypingScope.italic.rawValue) {
                context.active.append(TypingScope.italic.rawValue)
            } else if !isActive {
                context.active.append(TypingScope.normal.rawValue)
            }
        case .italic:
            if prevActivedKeys.contains(TypingScope.bold.rawValue) {
                context.active.append(TypingScope.bold.rawValue)
            } else if !isActive {
                context.active.append(TypingScope.normal.rawValue)
            }
        case .heading:
            if isActive {
                context.disable.append(contentsOf: [TypingScope.bold.rawValue,
                                                    TypingScope.italic.rawValue])
                context.inactive.append(TypingScope.quote.rawValue)
            } else {
                context.inactive.append(contentsOf: [TypingScope.bold.rawValue,
                                                     TypingScope.italic.rawValue])
                context.active.append(TypingScope.normal.rawValue)
            }
        case .quote:
            if isActive {
                context.disable.append(contentsOf: [TypingScope.bold.rawValue,
                                                    TypingScope.italic.rawValue])
                context.inactive.append(TypingScope.heading.rawValue)
            } else {
                context.inactive.append(contentsOf: [TypingScope.bold.rawValue,
                                                     TypingScope.italic.rawValue])
                context.active.append(TypingScope.normal.rawValue)
            }
        default:
            context.inactive.append(contentsOf: [TypingScope.heading.rawValue,
                                                 TypingScope.quote.rawValue,
                                                 TypingScope.bold.rawValue,
                                                 TypingScope.italic.rawValue])
            context.active = [TypingScope.normal.rawValue]
            return context
        }
        
        return context
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
