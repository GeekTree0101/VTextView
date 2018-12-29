import UIKit
import Foundation

final internal class VTextStorage: NSTextStorage, NSTextStorageDelegate {
    
    enum TypingStatus {
        
        case typing // Insert new single character as keyboard
        case remove // Remove character as keyboard
        case install // Directly set attributedString at storage
        case none // unknown or default status
    }
    
    internal var status: TypingStatus = .none
    private var stylers: [VTextStyler] = []
    
    private var internalAttributedString: NSMutableAttributedString = NSMutableAttributedString()
    
    override var string: String {
        return self.internalAttributedString.string
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:]
    
    convenience init(stylers: [VTextStyler]) {
        self.init()
        self.stylers = stylers
        self.delegate = self
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func attributes(at location: Int,
                             effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard self.internalAttributedString.length > location else { return [:] }
        return internalAttributedString.attributes(at: location, effectiveRange: range)
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        guard internalAttributedString.length > range.location else { return }
        
        switch status {
        case .typing, .install:
            break
        default:
            return
        }
        
        self.beginEditing()
        self.internalAttributedString.setAttributes(attrs, range: range)
        self.edited(.editedAttributes, range: range, changeInLength: 0)
        self.endEditing()
    }
    
    public func replaceAttributesIfNeeds(_ textView: UITextView) {
        guard textView.selectedRange.length > 1 else { return }
        self.status = .install
        self.setAttributes(self.currentTypingAttribute,
                           range: textView.selectedRange)
    }
    
    override func processEditing() {
        switch status {
        case .typing:
            self.internalAttributedString.setAttributes(self.currentTypingAttribute,
                                                        range: self.editedRange)
        default:
            break
        }
        
        super.processEditing()
    }
    
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {
        self.status = .none
    }
    
    override func setAttributedString(_ attrString: NSAttributedString) {
        self.status = .install
        super.setAttributedString(attrString)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        if self.status != .install {
            self.status = str.isEmpty ? .remove: .typing
        }
        
        self.beginEditing()
        self.internalAttributedString.replaceCharacters(in: range, with: str)
        self.edited(.editedCharacters,
                    range: range,
                    changeInLength: str.count - range.length)
        self.endEditing()
    }
    
    internal func currentLocationAttributes(_ textView: VTextView) -> [NSAttributedString.Key : Any]? {
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
    
    internal func parseToXML(packageTag: String?) -> String {
        let range = NSRange.init(location: 0, length: self.internalAttributedString.length)
        var output: String = ""
        
        self.internalAttributedString
            .enumerateAttributes(in: range,
                                 options: [], using: { attrs, subRange, _ in
                                    
                                    output += self.stylers.map({
                                        $0.buildXML(self.internalAttributedString,
                                                    attrs: attrs,
                                                    range: subRange)
                                        
                                    }).reduce("", { result, item -> String in
                                        return result + (item ?? "")
                                    })
            })
        
        // combined char must be squeeze about </tag><tag> due to blank attribute char
        let squeezTargetTags: [String] = self.stylers.map({ "</\($0.xmlTag)><\($0.xmlTag)>" })
        for targetTag in squeezTargetTags {
            output = output.replacingOccurrences(of: targetTag, with: "")
        }
        
        if let packageTag = packageTag {
            return "<\(packageTag)>" + output + "</\(packageTag)>"
        } else {
            return output
        }
    }
    
    internal func xmlToStorage(_ string: String) {
        _ = VTextXMLParser(string, stylers: self.stylers, complateHandler: { attr in
            self.setAttributedString(attr)
        })
    }
}
