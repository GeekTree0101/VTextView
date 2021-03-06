import UIKit
import Foundation
import BonMot

internal class VTextXMLParser: NSObject {
    
    private let manager: VTextManager
    private var mutableAttributedText: NSMutableAttributedString = .init()
    internal var complateHandler: (NSAttributedString) -> Void
    
    private var contexts: [VTypingContext] {
        return manager.contexts
    }
    
    private var currentContext: VTypingContext?
    
    init(_ xmlString: String,
         manager: VTextManager,
         complateHandler: @escaping (NSAttributedString) -> Void) {
        self.manager = manager
        self.complateHandler = complateHandler
        super.init()
        let mutableXMLString: String = xmlString.replacingOccurrences(of: "\\n", with: "\n")
        let xmlRules = manager.contexts.map({ context -> XMLStyleRule in
            return self.buildXMLStyleRule(context.xmlTag, key: context.key)
        })
        let styleRule = VXMLStyleRule(rules: xmlRules, manager: manager)
        let attrText = mutableXMLString
            .styled(with: StringStyle(.xmlStyler(styleRule)))
        self.complateHandler(attrText)
    }
    
    internal func buildXMLStyleRule(_ xmlTag: String, key: String) -> XMLStyleRule {
        var attrs = manager.typingDelegate.typingAttributes(key: key)
        attrs.add(extraAttributes: [VTextManager.managerKey: [key]])
        return XMLStyleRule.style(xmlTag, attrs)
    }
}

internal struct VXMLStyleRule: XMLStyler {
    
    let rules: [XMLStyleRule]
    let manager: VTextManager
    
    public func style(forElement name: String,
                      attributes: [String: String],
                      currentStyle: StringStyle) -> StringStyle? {
        for rule in rules {
            switch rule {
            case let .style(string, style) where string == name:
                var mutatedStyle: StringStyle
                guard let key = manager.getKey(name) else { return style }
                if let delegate = manager.parserDelegate,
                    let targetStyle = delegate
                        .mutatingAttribute(key: key,
                                           attributes: attributes,
                                           currentStyle: style) {
                    mutatedStyle = targetStyle
                } else {
                    mutatedStyle = style
                }
                
                // *** Merge topStyle managerKey list with current key ***
                if let beforeKeys = currentStyle.attributes[VTextManager.managerKey] as? [String],
                    case var defaultFilteredKeys = beforeKeys.filter({ $0 != manager.defaultKey }),
                    !defaultFilteredKeys.contains(key) {
                    defaultFilteredKeys.append(key)
                    mutatedStyle.add(extraAttributes: [VTextManager.managerKey: defaultFilteredKeys])
                }
                
                return mutatedStyle
            default:
                break
            }
        }
        for rule in rules {
            if case let .styles(namedStyles) = rule {
                return namedStyles.style(forName: name)
            }
        }
        return nil
    }
    
    public func prefix(forElement name: String,
                       attributes: [String: String]) -> Composable? {
        for rule in rules {
            switch rule {
            case let .enter(string, composable) where string == name:
                return composable
            default: break
            }
        }
        return nil
    }
    
    public func suffix(forElement name: String) -> Composable? {
        for rule in rules {
            switch rule {
            case let .exit(string, composable) where string == name:
                return composable
            default: break
            }
        }
        return nil
    }
}
