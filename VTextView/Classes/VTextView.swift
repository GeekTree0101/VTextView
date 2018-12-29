import UIKit
import Foundation

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
        var styler = stylers.filter({ $0.key == defaultKey }).first
        styler?.isEnable = true
        textStorage.currentTypingAttribute = styler?.typingAttributes ?? [:]
        self.currentTypingAttribute = styler?.typingAttributes ?? [:]
        self.stylers = stylers
        self.defaultStyler = styler
        super.init(frame: .zero, textContainer: textContainer)
        super.delegate = self
        self.autocorrectionType = .no
    }
    
    public func setTypingAttribute(key: String) {
        guard let targetStyler = self.stylers.filter({ $0.key == key }).first else {
            return
        }
        self.internalTextStorage?.setAttributes(targetStyler.typingAttributes,
                                                range: self.selectedRange)
        self.currentTypingAttribute = targetStyler.typingAttributes
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
