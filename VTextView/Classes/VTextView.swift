import UIKit
import Foundation
import RxSwift
import RxCocoa
import BonMot

open class VTextView: UITextView, UITextViewDelegate {
    
    private var internalTextStorage: VTextStorage? {
        return self.textStorage as? VTextStorage
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:] {
        didSet {
            self.typingAttributes = currentTypingAttribute
            self.internalTextStorage?.currentTypingAttribute = currentTypingAttribute
        }
    }
    
    public var isEnableTouchEvent: Bool = false
    let disposeBag = DisposeBag()
    
    public required init(manager: VTextManager) {
        let textContainer = NSTextContainer(size: .zero)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = VTextStorage(typingManager: manager)
        textStorage.addLayoutManager(layoutManager)
        super.init(frame: .zero, textContainer: textContainer)
        super.delegate = self
        self.isEnableTouchEvent = !self.isEditable
        
        manager.currentAttributesRelay.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] attr in
                self?.setTypingAttributeIfNeeds(attr, isBlock: false)
            }).disposed(by: disposeBag)
        
        manager.blockAttributeRelay.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] attr in
                self?.setTypingAttributeIfNeeds(attr, isBlock: true)
            }).disposed(by: disposeBag)
    }
    
    private func setTypingAttributeIfNeeds(_ attr: [NSAttributedString.Key: Any], isBlock: Bool) {
    
        if isBlock, let range = internalTextStorage?.paragraphStyleRange(self) {
            self.internalTextStorage?.status = .install
            self.internalTextStorage?.setAttributes(attr, range: range)
        } else {
            self.internalTextStorage?.setAttributes(attr,
                                                    range: self.selectedRange)
        }
        
        self.currentTypingAttribute = attr
        self.internalTextStorage?.replaceAttributesIfNeeds(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if self.currentTypingAttribute.isEmpty {
            self.currentTypingAttribute =
                internalTextStorage?
                    .typingManager?
                    .defaultAttribute ?? [:]
        }
        return true
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        self.internalTextStorage?.updateCurrentLocationAttributesIfNeeds(self)
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
