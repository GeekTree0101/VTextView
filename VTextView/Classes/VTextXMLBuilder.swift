import Foundation
import UIKit

internal struct VTextXMLBuilder {
    
    static let shared = VTextXMLBuilder()
    
    internal func parseToXML(typingManager: VTextManager,
                    internalAttributedString: NSMutableAttributedString,
                    packageTag: String?) -> String {
        let range = NSRange.init(location: 0, length: internalAttributedString.length)
        var output: String = ""
        
        internalAttributedString
            .enumerateAttributes(in: range,
                                 options: [], using: { attrs, subRange, _ in
                                    
                                    let filteredText = internalAttributedString
                                        .attributedSubstring(from: subRange).string
                                        .replacingOccurrences(of: "\n", with: "\\n")
                                    
                                    guard let tags = attrs[VTextManager.managerKey] as? [String],
                                        case let contexts = typingManager.contexts.filter({ tags.contains($0.key) }),
                                        !filteredText.isEmpty else { return }
                                    
                                    let open = contexts
                                        .map({ self.convertToXMLTag($0,
                                                                    typingManager: typingManager,
                                                                    attributes: attrs,
                                                                    isOpen: true)
                                        })
                                        .joined()
                                    
                                    let close = contexts
                                        .reversed()
                                        .map({ self.convertToXMLTag($0,
                                                                    typingManager: typingManager,
                                                                    attributes: attrs,
                                                                    isOpen: false)
                                        })
                                        .joined()
                                    
                                    output += [open, filteredText, close].joined()
            })
        
        // combined char must be squeeze about </tag><tag> due to blank attribute char
        let squeezTargetTags: [String] =
            typingManager.contexts.map({ "</\($0.xmlTag)><\($0.xmlTag)>" })
        for targetTag in squeezTargetTags {
            output = output.replacingOccurrences(of: targetTag, with: "")
        }
        
        if let packageTag = packageTag {
            return "<\(packageTag)>" + output + "</\(packageTag)>"
        } else {
            return output
        }
    }
    
    private func convertToXMLTag(_ context: VTypingContext,
                                 typingManager: VTextManager,
                                 attributes: [NSAttributedString.Key: Any],
                                 isOpen: Bool) -> String {
        var tags: [String] = [context.xmlTag]
        if let xmlAttribute: String = typingManager.parserDelegate
            .customXMLTagAttribute(context: context,
                                   attributes: attributes) {
            tags.append(xmlAttribute)
        }
        let xmlTag = tags.joined(separator: " ")
        return isOpen ? "<\(xmlTag)>": "</\(xmlTag)>"
    }
}
