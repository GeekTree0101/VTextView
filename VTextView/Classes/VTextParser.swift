import UIKit
import Foundation
import BonMot

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
        
        let mutableXMLString: String = xmlString.replacingOccurrences(of: "\\n", with: "\n")
        
        // build rules
        let xmlRules = manager.contexts.map({ context -> XMLStyleRule in
            return self.buildXMLStyleRule(context.xmlTag, key: context.key)
        })
        
        do {
            let attrText = try NSAttributedString.composed(ofXML: mutableXMLString, rules: xmlRules)
            self.complateHandler(attrText)
        } catch {
            fatalError("Parse Error: \(mutableXMLString)")
        }
    }
    
    internal func buildXMLStyleRule(_ xmlTag: String, key: String) -> XMLStyleRule {
        var attrs = manager.delegate.attributes(activeKeys: [key])
        attrs.add(extraAttributes: [VTypingManager.managerKey: [key]])
        return XMLStyleRule.style(xmlTag, attrs)
    }
}
