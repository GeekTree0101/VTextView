import UIKit
import Foundation
import BonMot

public struct VTextXMLParserContext {
    
    let keys: [String]
    let xmlTags: [String]
    var convenienceXMLIdentifier: String {
        return xmlTags.joined(separator: "-")
    }
    
    public init(keys: [String], manager: VTypingManager) {
        self.keys = keys
        self.xmlTags = manager.getXMLTags(keys) ?? []
    }
    
    internal func buildXMLStyleRule(_ manager: VTypingManager) -> XMLStyleRule? {
        var attrs = manager.delegate.attributes(activeKeys: self.keys)
        attrs[VTypingManager.managerKey] = self.keys
        let parts = StringStyle.Part.extraAttributes(attrs)
        return XMLStyleRule.style(convenienceXMLIdentifier, .init(parts))
    }
    
    internal func replaceConvenienceXMLIdentifiers(_ string: String) -> String {
        let open = xmlTags.map({ "<\($0)>" }).joined()
        let close = xmlTags.reversed().map({ "</\($0)>" }).joined()
        let reverseOpen = xmlTags.reversed().map({ "<\($0)>" }).joined()
        let reverseClose = xmlTags.map({ "</\($0)>" }).joined()
        
        return string
            .replacingOccurrences(of: open, with: "<\(convenienceXMLIdentifier)>")
            .replacingOccurrences(of: close, with: "</\(convenienceXMLIdentifier)>")
            .replacingOccurrences(of: reverseOpen, with: "<\(convenienceXMLIdentifier)>")
            .replacingOccurrences(of: reverseClose, with: "</\(convenienceXMLIdentifier)>")
    }
}

internal class VTextXMLParser: NSObject {
    
    private let manager: VTypingManager
    private var mutableAttributedText: NSMutableAttributedString = .init()
    public var complateHandler: (NSAttributedString) -> Void
    
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
        
        var mutableXMLString: String = xmlString.replacingOccurrences(of: "\\n", with: "\n")
        
        // build rules
        var rules = manager.allKeys.map({
            VTextXMLParserContext(keys: [$0], manager: manager)
        })
        
        if let exceptionRules = self.manager.delegate?.exceptionXMLParserBuildRule() {
            rules.append(contentsOf: exceptionRules)
        }
        
        // convert formatted xml string for conveniecne  parsing
        for rule in rules {
            mutableXMLString = rule.replaceConvenienceXMLIdentifiers(mutableXMLString)
        }
        
        let xmlRules: [XMLStyleRule] = rules
            .map({ $0.buildXMLStyleRule(manager) })
            .filter({ $0 != nil })
            .map({ $0! })
        
        do {
            let attrText = try NSAttributedString.composed(ofXML: mutableXMLString, rules: xmlRules)
            self.complateHandler(attrText)
        } catch {
            fatalError("Parse Error: \(mutableXMLString)")
        }
    }
}
