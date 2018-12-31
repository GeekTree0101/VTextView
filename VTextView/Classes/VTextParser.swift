import UIKit
import Foundation
import BonMot

internal class VTextXMLParser: NSObject {
    
    private let manager: VTypingManager
    private var mutableAttributedText: NSMutableAttributedString = .init()
    internal var complateHandler: (NSAttributedString) -> Void
    
    private var contexts: [VTypingContext] {
        return manager.contexts
    }
    
    private var currentContext: VTypingContext?
    
    init(_ xmlString: String,
         manager: VTypingManager,
         complateHandler: @escaping (NSAttributedString) -> Void) {
        self.manager = manager
        self.complateHandler = complateHandler
        super.init()
        
        let mutableXMLString: String = xmlString.replacingOccurrences(of: "\\n", with: "\n")
        
        // build rules
        let xmlRules = manager.contexts.map({ context -> XMLStyleRule in
            return self.buildXMLStyleRule(context.xmlTag, key: context.key)
        })
        
        let styleRule = VXMLStyleRule(rules: xmlRules, manager: manager)
        let attrText = mutableXMLString
            .styled(with: StringStyle(.xmlStyler(styleRule)))
        self.complateHandler(attrText)
    }
    
    internal func buildXMLStyleRule(_ xmlTag: String, key: String) -> XMLStyleRule {
        var attrs = manager.delegate.attributes(activeKeys: [key])
        attrs.add(extraAttributes: [VTypingManager.managerKey: [key]])
        
        return XMLStyleRule.style(xmlTag, attrs)
    }
}

internal struct VXMLStyleRule: XMLStyler {
    
    let rules: [XMLStyleRule]
    let manager: VTypingManager
    
    public func style(forElement name: String,
                      attributes: [String: String],
                      currentStyle: StringStyle) -> StringStyle? {
        for rule in rules {
            switch rule {
            case let .style(string, style) where string == name:
                guard let key = manager.getKey(name),
                    let mutatedStyle = manager.delegate?
                        .mutatingAttribute(key: key,
                                           attributes: attributes,
                                           currentStyle: style) else { return style }
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
