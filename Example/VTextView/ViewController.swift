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
    
    let defaultStyle: VTextStyler =
        .init(TypingScope.normal.rawValue,
              attributes: [.font: UIFont.systemFont(ofSize: 15),
                           .foregroundColor: UIColor.black],
              xmlTag: "p")
    
    let boldStyle: VTextStyler =
        .init(TypingScope.bold.rawValue,
              attributes: [.font: UIFont.systemFont(ofSize: 15).bold(),
                           .foregroundColor: UIColor.black],
              xmlTag: "b")
    
    let italicStyle: VTextStyler =
        .init(TypingScope.italic.rawValue,
              attributes: [.font: UIFont.systemFont(ofSize: 15).italics(),
                           .foregroundColor: UIColor.black],
              xmlTag: "i")
    
    let headingStyle: VTextStyler =
        .init(TypingScope.heading.rawValue,
              attributes: [.font: UIFont.systemFont(ofSize: 30, weight: .medium),
                           .foregroundColor: UIColor.black],
              xmlTag: "h2")
    
    let quoteStyle: VTextStyler =
        .init(TypingScope.quote.rawValue,
              attributes: [.font: UIFont.systemFont(ofSize: 20),
                           .foregroundColor: UIColor.gray],
              xmlTag: "blockquote")
    
    
    lazy var stylers: [VTextStyler] = [defaultStyle, boldStyle, italicStyle, headingStyle, quoteStyle]
    
    // Create VTextView
    lazy var textView = VTextView(stylers: self.stylers,
                                  defaultKey: TypingScope.normal.rawValue)
    
    let controlView = TypingControlView(frame: .zero)
    let disposeBag = DisposeBag()
    
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
    }
    
    private func initEvent() {
        
        controlView.boldControlView.rx.tap
            .bind(to: textView.rx.toggleStatus(key: TypingScope.bold.rawValue))
            .disposed(by: disposeBag)
        
        controlView.italicControlView.rx.tap
            .bind(to: textView.rx.toggleStatus(key: TypingScope.italic.rawValue))
            .disposed(by: disposeBag)
        
        controlView.headingControlView.rx.tap
            .bind(to: textView.rx.toggleStatus(key: TypingScope.heading.rawValue))
            .disposed(by: disposeBag)
        
        controlView.quoteControlView.rx.tap
            .bind(to: textView.rx.toggleStatus(key: TypingScope.quote.rawValue))
            .disposed(by: disposeBag)
        
        boldStyle.isEnableRelay
            .bind(to: controlView.boldControlView.rx.isSelected)
            .disposed(by: disposeBag)
        
        italicStyle.isEnableRelay
            .bind(to: controlView.italicControlView.rx.isSelected)
            .disposed(by: disposeBag)
        
        headingStyle.isEnableRelay
            .bind(to: controlView.headingControlView.rx.isSelected)
            .disposed(by: disposeBag)
        
        quoteStyle.isEnableRelay
            .bind(to: controlView.quoteControlView.rx.isSelected)
            .disposed(by: disposeBag)
        
        controlView.dismissControlView.rx.tap.subscribe(onNext: { [weak self] _ in
            _ = self?.textView.resignFirstResponder()
            print("DEBUG* \(self?.textView.buildToXML(packageTag: "content") ?? "" )")
        }).disposed(by: disposeBag)
    }
}

extension ViewController {
    
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
