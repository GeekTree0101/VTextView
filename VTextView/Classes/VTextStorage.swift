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
    internal var typingManager: VTypingManager?
    
    private var internalAttributedString: NSMutableAttributedString = NSMutableAttributedString()
    
    override var string: String {
        return self.internalAttributedString.string
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:]
    
    convenience init(typingManager: VTypingManager) {
        self.init()
        self.typingManager = typingManager
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
    
    enum CurrentLocationScope {
        case isLast([NSAttributedString.Key : Any], String)
        case attribute([NSAttributedString.Key : Any])
    }
    
    internal func currentLocationAttributes(_ textView: VTextView) -> CurrentLocationScope {
        guard self.internalAttributedString.length - textView.selectedRange.location > 1 else {
            return .isLast(typingManager?.defaultAttribute ?? [:], typingManager?.defaultKey ?? "")
        }
        
        let currentAttributes =
            self.attributes(at: textView.selectedRange.location,
                            effectiveRange: nil)
        guard !currentAttributes.isEmpty else {
            return .attribute(typingManager?.defaultAttribute ?? [:])
        }
        return .attribute(currentAttributes)
    }
    
    public func paragraphStyleRange(_ textView: VTextView) -> NSRange {
        return NSString(string: self.internalAttributedString.string)
            .paragraphRange(for: textView.selectedRange)
    }
}

extension VTextStorage {
    
    internal func parseToXML(packageTag: String?) -> String {
        let range = NSRange.init(location: 0, length: self.internalAttributedString.length)
        var output: String = ""
        
        self.internalAttributedString
            .enumerateAttributes(in: range,
                                 options: [], using: { attrs, subRange, _ in
                                    
                                    let filteredText = self.internalAttributedString
                                        .attributedSubstring(from: subRange).string
                                        .replacingOccurrences(of: "\n", with: "\\n")

                                    guard let tags = attrs[VTypingManager.managerKey] as? [String],
                                        let contexts = typingManager?.contexts.filter({ tags.contains($0.key) }),
                                        !filteredText.isEmpty else { return }
                                    
                                    let open = contexts.map({ $0.xmlTag })
                                        .map({ "<\($0)>" })
                                        .joined()
                                    
                                    let close = contexts.map({ $0.xmlTag })
                                        .reversed()
                                        .map({ "</\($0)>" })
                                        .joined()
                                    
                                    output += [open, filteredText, close].joined()
            })
        
        // combined char must be squeeze about </tag><tag> due to blank attribute char
        let squeezTargetTags: [String] =
            self.typingManager?.contexts.map({ "</\($0.xmlTag)><\($0.xmlTag)>" }) ?? []
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
        guard let manager = self.typingManager else { return }
        _ = VTextXMLParser(string, manager: manager, complateHandler: { attr in
            self.setAttributedString(attr)
        })
    }
}
