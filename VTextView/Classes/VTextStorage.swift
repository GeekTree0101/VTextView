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
    internal var typingManager: VTextManager?
    
    private var internalAttributedString: NSMutableAttributedString = NSMutableAttributedString()
    private var prevLocation: Int = 0
    
    override var string: String {
        return self.internalAttributedString.string
    }
    
    internal var currentTypingAttribute: [NSAttributedString.Key: Any] = [:]
    
    convenience init(typingManager: VTextManager) {
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
    
    override func fixAttributes(in range: NSRange) {
        self.replaceAccessoryAttributeIfNeed(range)
        super.fixAttributes(in: range)
    }
    
    private func replaceAccessoryAttributeIfNeed(_ range: NSRange) {
        
        guard let attrs = self.typingManager?.accessoryDelegate?.accessoryWithAttribute(),
            !attrs.isEmpty else {
                return
        }
        
        for attr in attrs {
            
            let targetRange: NSRange
            
            switch status {
            case .typing:
                let detectLength: Int
                if range.length > 1 {
                    detectLength = range.length
                } else {
                    detectLength =
                        self.typingManager?
                            .accessoryDelegate?
                            .detectLength(attr.key) ?? 1
                }
                
                targetRange = NSRange(location: max(0, range.location - detectLength),
                                      length: range.length + detectLength)
            case .install:
                targetRange = range
            default:
                return
            }
            
            let matchs = attr.key.matches(in: self.internalAttributedString.string,
                                          options: [],
                                          range: targetRange)
            
            for match in matchs {
                let matchRange = match.range
                let str = self.internalAttributedString.string
                let start = str.index(str.startIndex, offsetBy: matchRange.location)
                let end = str.index(str.startIndex, offsetBy: matchRange.location + matchRange.length)
                let range = start ..< end
                
                self.internalAttributedString.addAttribute(NSAttributedString.Key(attr.key.pattern),
                                                           value: str[range] as Any,
                                                           range: matchRange)
                if let attributes = attr.value?.attributes {
                    self.internalAttributedString.addAttributes(attributes, range: matchRange)
                }
            }
        }
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
    
    internal func updateCurrentLocationAttributesIfNeeds(_ textView: VTextView) {
        
        self.triggerTouchEventIfNeeds(textView)
        
        if textView.selectedRange.length < 1,
            self.isFlyToTargetLocationWithoutTyping(textView) {
            
            let currentAttributes =
                self.attributes(at: max(0, textView.selectedRange.location - 1),
                                effectiveRange: nil)
            
            if let keys = currentAttributes[VTextManager.managerKey] as? [String]  {
                textView.currentTypingAttribute =
                    self.typingManager?.fetchActiveAttribute(keys) ?? [:]
            } else {
                textView.currentTypingAttribute =
                    self.typingManager?.resetStatus() ?? [:]
                self.typingManager?.updateCurrentAttribute(typingManager?.defaultKey ?? "")
            }
        }
        
        self.prevLocation = textView.selectedRange.location
    }
    
    internal func triggerTouchEventIfNeeds(_ textView: VTextView) {
        guard self.isFlyToTargetLocationWithoutTyping(textView),
            textView.selectedRange.length < 1,
            let attrs = self.typingManager?
            .accessoryDelegate
            .accessoryWithAttribute(),
            !attrs.isEmpty else { return }
        
        let currentAttributes =
            self.attributes(at: max(0, textView.selectedRange.location - 1),
                            effectiveRange: nil)
        
        if let url = currentAttributes[NSAttributedString.Key.link] as? URL {
            self.typingManager?.accessoryDelegate.handleLink(url)
            return
        }
        
        for attr in attrs {
            let key = NSAttributedString.Key(attr.key.pattern)
            if let value = currentAttributes[key] {
                self.typingManager?.accessoryDelegate
                    .handleTouchEvent(attr.key, value: value)
                return
            }
        }
    }
    
    private func isFlyToTargetLocationWithoutTyping(_ textView: VTextView) -> Bool {
        return abs(textView.selectedRange.location - self.prevLocation) > 1
    }
    
    public func paragraphStyleRange(_ textView: VTextView) -> NSRange {
        return NSString(string: self.internalAttributedString.string)
            .paragraphRange(for: textView.selectedRange)
    }
}

extension VTextStorage {
    
    internal func parseToXML(packageTag: String?) -> String {
        guard let manager = typingManager else { return "" }
        return VTextXMLBuilder.shared.parseToXML(typingManager: manager,
                                                 internalAttributedString: internalAttributedString,
                                                 packageTag: packageTag)
    }
    
    internal func xmlToStorage(_ string: String) {
        guard let manager = self.typingManager else { return }
        _ = VTextXMLParser(string, manager: manager, complateHandler: { attr in
            self.setAttributedString(attr)
        })
    }
}
