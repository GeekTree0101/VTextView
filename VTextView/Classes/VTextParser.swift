import UIKit
import Foundation

internal class VTextXMLParser: NSObject, XMLParserDelegate {
    
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
        
        guard let xmlData = xmlString.data(using: .utf8) else { return }
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        self.currentContext = self.contexts.filter({ $0.xmlTag == elementName }).first
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let context = self.currentContext,
            !string.isEmpty,
            var attributes = manager.delegate?.attributes(activeKeys: [context.key]) else { return }
        let filteredString = string.replacingOccurrences(of: "\\n", with: "\n")
        attributes[VTypingManager.managerKey] = [context.key] as Any
        let attrText = NSAttributedString(string: filteredString,
                                          attributes: attributes)
        mutableAttributedText.append(attrText)
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        self.currentContext = nil
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        self.complateHandler(self.mutableAttributedText)
    }
}
