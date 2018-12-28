import UIKit
import Foundation

public protocol VTextAttribute {
    
    var attributes: [NSAttributedString.Key: Any] { get }
    var defaultAttribute: [NSAttributedString.Key: Any] { get }
}

open class VTextView: UITextView, UITextViewDelegate {
    
    private var internalTextStorage: VTextStorage? {
        return self.textStorage as? VTextStorage
    }
    
    private var currentTypingAttribute: [NSAttributedString.Key: Any] {
        didSet {
            self.typingAttributes = currentTypingAttribute
            self.internalTextStorage?.currentTypingAttribute = currentTypingAttribute
        }
    }
    
    public required init(typingStyle: VTextAttribute) {
        
        let textContainer = NSTextContainer(size: .zero)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = VTextStorage.init()
        textStorage.addLayoutManager(layoutManager)
        textStorage.currentTypingAttribute = typingStyle.defaultAttribute
        self.currentTypingAttribute = typingStyle.defaultAttribute
        super.init(frame: .zero, textContainer: textContainer)
        super.delegate = self
        self.autocorrectionType = .no
    }
    
    public func setTypingAttribute(_ typingStyle: VTextAttribute) {
        self.internalTextStorage?.setAttributes(typingStyle.attributes,
                                                range: self.selectedRange)
        self.currentTypingAttribute = typingStyle.attributes
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
       return true
    }
}


final internal class VTextStorage: NSTextStorage {
    
    private var internalAttributedString: NSMutableAttributedString = NSMutableAttributedString()
    
    override var string: String {
        return self.internalAttributedString.string
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:]
    
    override func attributes(at location: Int,
                             effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return internalAttributedString.attributes(at: location, effectiveRange: range)
    }
    
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        guard internalAttributedString.length > range.location else {
            return
        }
        
        self.beginEditing()
        self.internalAttributedString.setAttributes(attrs, range: range)
        self.edited(.editedAttributes, range: range, changeInLength: 0)
        self.endEditing()
    }
    
    override func processEditing() {
        self.internalAttributedString.setAttributes(self.currentTypingAttribute,
                                                    range: self.editedRange)
        super.processEditing()
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        self.beginEditing()
        self.internalAttributedString.replaceCharacters(in: range, with: str)
        self.edited(.editedCharacters,
                    range: range,
                    changeInLength: str.count - range.length)
        self.endEditing()
    }
}
