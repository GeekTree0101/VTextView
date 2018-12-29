import UIKit
import Foundation

public struct VTextStyler {
    
    internal static let stylerKey: NSAttributedString.Key =
        .init(rawValue: "VTextStyler.key")
    
    public var key: String
    public var isEnable: Bool = false
    public var attributes: [NSAttributedString.Key: Any]
    public var xmlTag: String
    
    public init(_ key: String, attributes: [NSAttributedString.Key: Any], xmlTag: String) {
        self.key = key
        self.attributes = attributes
        self.xmlTag = xmlTag
    }
    
    internal var typingAttributes: [NSAttributedString.Key: Any] {
        var mutableAttr: [NSAttributedString.Key: Any] = attributes
        mutableAttr[VTextStyler.stylerKey] = key
        return mutableAttr
    }
    
    internal func buildXML(_ attrText: NSAttributedString,
                           attrs: [NSAttributedString.Key: Any],
                           range: NSRange) -> String? {
        guard let targetKey = attrs[VTextStyler.stylerKey] as? String,
            targetKey == self.key,
            case let content = attrText
                .attributedSubstring(from: range).string,
            !content.isEmpty else { return nil }
        
        return "<\(xmlTag)>" + content + "</\(xmlTag)>"
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
    
    private var stylers: [VTextStyler]
    private let defaultStyler: VTextStyler?
    
    public required init(stylers: [VTextStyler], defaultKey: String) {
        
        let textContainer = NSTextContainer(size: .zero)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = VTextStorage.init()
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
    
    public func buildToXML() -> String? {
        return self.internalTextStorage?.parseToXML(self.stylers)
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

final internal class VTextStorage: NSTextStorage {
    
    enum TypingStatus {
        
        case typing
        case remove
        case none
    }
    
    internal var status: TypingStatus = .none
    
    private var internalAttributedString: NSMutableAttributedString = NSMutableAttributedString()
    
    override var string: String {
        return self.internalAttributedString.string
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:]
    
    override func attributes(at location: Int,
                             effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard self.internalAttributedString.length > location else { return [:] }
        return internalAttributedString.attributes(at: location, effectiveRange: range)
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        guard internalAttributedString.length > range.location, status == .typing else {
            return
        }
        
        self.beginEditing()
        self.internalAttributedString.setAttributes(attrs, range: range)
        self.edited(.editedAttributes, range: range, changeInLength: 0)
        self.endEditing()
    }
    
    override func processEditing() {
        if status == .typing {
            self.internalAttributedString.setAttributes(self.currentTypingAttribute,
                                                        range: self.editedRange)
        }
        
        super.processEditing()
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        self.status = str.isEmpty ? .remove: .typing
        self.beginEditing()
        self.internalAttributedString.replaceCharacters(in: range, with: str)
        self.edited(.editedCharacters,
                    range: range,
                    changeInLength: str.count - range.length)
        self.endEditing()
    }
    
    func currentLocationAttributes(_ textView: VTextView) -> [NSAttributedString.Key : Any]? {
        guard self.internalAttributedString.length - textView.selectedRange.location > 1 else {
            return nil
        }
        
        let currentAttributes =
            self.attributes(at: textView.selectedRange.location,
                            effectiveRange: nil)
        guard !currentAttributes.isEmpty else { return nil }
        return currentAttributes
    }
}

extension VTextStorage {
    
    internal func parseToXML(_ stylers: [VTextStyler]) -> String {
        let range = NSRange.init(location: 0, length: self.internalAttributedString.length)
        var output: String = ""
        
        self.internalAttributedString
            .enumerateAttributes(in: range,
                                 options: [], using: { attrs, subRange, _ in
                                    
                                    output += stylers.map({
                                        $0.buildXML(self.internalAttributedString,
                                                    attrs: attrs,
                                                    range: subRange)
                                        
                                    }).reduce("", { result, item -> String in
                                        return result + (item ?? "")
                                    })
            })
        
        let squeezTargetTags: [String] = stylers.map({ "</\($0.xmlTag)><\($0.xmlTag)>" })
        for targetTag in squeezTargetTags {
            output = output.replacingOccurrences(of: targetTag, with: "")
        }
        return output
    }
}
