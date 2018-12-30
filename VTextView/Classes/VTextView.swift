import UIKit
import Foundation
import RxSwift
import RxCocoa

open class VTextView: UITextView, UITextViewDelegate {
    
    private var internalTextStorage: VTextStorage? {
        return self.textStorage as? VTextStorage
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] {
        didSet {
            self.typingAttributes = currentTypingAttribute
            self.internalTextStorage?.currentTypingAttribute = currentTypingAttribute
        }
    }
    
    let disposeBag = DisposeBag()
    
    public required init(manager: VTypingManager) {
        let textContainer = NSTextContainer(size: .zero)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = VTextStorage(typingManager: manager)
        textStorage.addLayoutManager(layoutManager)
        self.currentTypingAttribute = manager.defaultAttribute
        super.init(frame: .zero, textContainer: textContainer)
        super.delegate = self
        self.autocorrectionType = .no
        
        manager.currentAttributesRelay.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] attr in
                self?.setTypingAttributeIfNeeds(attr)
            }).disposed(by: disposeBag)
    }
    
    private func setTypingAttributeIfNeeds(_ attr: [NSAttributedString.Key: Any]) {
        self.internalTextStorage?.setAttributes(attr,
                                                range: self.selectedRange)
        self.currentTypingAttribute = attr
        
        self.internalTextStorage?.replaceAttributesIfNeeds(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let attributes = self.internalTextStorage?
            .currentLocationAttributes(self) else { return }
        self.currentTypingAttribute = attributes
        guard let keys = attributes[VTypingManager.managerKey] as? [String],
            let anyFirstKey = keys.first else { return }
        self.internalTextStorage?.typingManager?.didTapTargetKey(anyFirstKey)
    }
    
    public func buildToXML(packageTag: String?) -> String? {
        return self.internalTextStorage?.parseToXML(packageTag: packageTag)
    }
    
    public func applyXML(_ xmlString: String) {
        self.internalTextStorage?.xmlToStorage(xmlString)
    }
    
    override open func endEditing(_ force: Bool) -> Bool {
        self.internalTextStorage?.status = .none
        return super.endEditing(force)
    }
    
    override open func resignFirstResponder() -> Bool {
        self.internalTextStorage?.status = .none
        return super.resignFirstResponder()
    }
    
}
