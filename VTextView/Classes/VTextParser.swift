import UIKit
import Foundation

internal class VTextXMLParser: NSObject, XMLParserDelegate {
    
    private let stylers: [VTextStyler]
    private var currentStyler: VTextStyler?
    private var mutableAttributedText: NSMutableAttributedString = .init()
    public var complateHandler: (NSAttributedString) -> Void
    
    init(_ xmlString: String,
         stylers: [VTextStyler],
         complateHandler: @escaping (NSAttributedString) -> Void) {
        
        self.stylers = stylers
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
        self.currentStyler = self.stylers.filter({ $0.xmlTag == elementName }).first
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let styler = self.currentStyler, !string.isEmpty else { return }
        let filteredString = string.replacingOccurrences(of: "\\n", with: "\n")
        let attrText = NSAttributedString(string: filteredString,
                                          attributes: styler.typingAttributes)
        mutableAttributedText.append(attrText)
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        self.currentStyler = nil
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        self.complateHandler(self.mutableAttributedText)
    }
}
