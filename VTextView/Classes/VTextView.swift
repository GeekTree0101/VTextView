import UIKit
import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: VTextView {
    
    public func toggleStatus(key: String) -> Binder<Void> {
        return Binder(base) { view, _ in
            guard let styler = view.targetStyler(key) else { return }
            
            if styler.isEnableRelay.value {
                view.disableTypingAttribute(key: key)
            } else {
                view.enableTypingAttribute(key: key)
            }
        }
    }
}

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
    
    private let stylers: [VTextStyler]
    private let defaultStyler: VTextStyler?
    
    public required init(stylers: [VTextStyler], defaultKey: String) {
        let textContainer = NSTextContainer(size: .zero)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = VTextStorage(stylers: stylers)
        textStorage.addLayoutManager(layoutManager)
        let styler = stylers.filter({ $0.key == defaultKey }).first
        styler?.isEnableRelay.accept(true)
        textStorage.currentTypingAttribute = styler?.typingAttributes ?? [:]
        self.currentTypingAttribute = styler?.typingAttributes ?? [:]
        self.stylers = stylers
        self.defaultStyler = styler
        super.init(frame: .zero, textContainer: textContainer)
        super.delegate = self
        self.autocorrectionType = .no
    }
    
    public func enableTypingAttribute(key: String) {
        
        for styler in stylers {
            if styler.key == key {
                styler.isEnableRelay.accept(true)
            } else {
                styler.isEnableRelay.accept(false)
            }
        }
        
        self.setTypingAttributeIfNeeds()
    }
    
    public func targetStyler(_ key: String) -> VTextStyler? {
        return self.stylers.filter({ $0.key == key }).first
    }
    
    public func disableTypingAttribute(key: String) {
        guard let targetStyler = self.stylers.filter({ $0.key == key }).first else {
            return
        }
        targetStyler.isEnableRelay.accept(false)
        
        self.setTypingAttributeIfNeeds()
    }
    
    private func setTypingAttributeIfNeeds() {
        
        guard let targetStyler =
            self.stylers.filter({ $0.isEnableRelay.value }).first ?? defaultStyler else { return }
        
        // bold -> others should be disable
        
        self.internalTextStorage?.setAttributes(targetStyler.typingAttributes,
                                                range: self.selectedRange)
        self.currentTypingAttribute = targetStyler.typingAttributes
        
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
