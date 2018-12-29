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
                .attributedSubstring(from: range).string
                .replacingOccurrences(of: "\n", with: "\\n"),
            !content.isEmpty else { return nil }
        return "<\(xmlTag)>" + content + "</\(xmlTag)>"
    }
}
