import Foundation
import UIKit
import RxSwift
import RxCocoa
import BonMot

public protocol VTextTypingDelegate: class {
    
    func bindEvents(_ manager: VTextManager)
    func typingAttributes(key: String) -> StringStyle
    func enableKeys(_ inActiveKey: String) -> [String]?
    func disableKeys(_ activeKey: String) -> [String]?
    func inactiveKeys(_ activeKey: String) -> [String]?
    func activeKeys(_ inactiveKey: String) -> [String]?
}

public protocol VTextParserDelegate: class {
    
    func mutatingAttribute(key: String,
                           attributes: [String: String],
                           currentStyle: StringStyle) -> StringStyle?
    func customXMLTagAttribute(context: VTypingContext,
                               attributes: [NSAttributedString.Key: Any]) -> String?
}

public protocol VTextAccessoryDelegate: class {
    
    func accessoryWithAttribute() -> [NSRegularExpression: StringStyle?]
    func detectLength(_ target: NSRegularExpression) -> Int?
    func handleTouchEvent(_ target: NSRegularExpression, value: Any)
    func handleLink(_ url: URL)
}

public struct VTypingContext {
    
    public enum Status {
        case disable
        case active
        case inactive
    }
    
    public var key: String
    public var currentStatusRelay = BehaviorRelay<Status>(value: .inactive)
    public var xmlTag: String
    public var isBlockStyle: Bool = false
    public var isTouchEvent: Bool = false
    
    public init(_ key: String,
                xmlTag: String,
                isBlockStyle: Bool = false,
                isTouchEvent: Bool = false) {
        self.key = key
        self.xmlTag = xmlTag
        self.isBlockStyle = isBlockStyle
        self.isTouchEvent = isTouchEvent
    }
}

extension Reactive where Base: VTextManager {
    
    public func didTap(_ key: String) -> Binder<Void> {
        return Binder(base) { manager, _ in
            manager.updateCurrentAttribute(key)
        }
    }
    
    public func isActive(_ key: String) -> Observable<Bool> {
        return base.activeContextsRelay
            .filter({ $0.contains(key) })
            .map { _ in return true }
    }
    
    public func isInActive(_ key: String) -> Observable<Bool> {
        return base.inactiveContextsRelay
            .filter({ $0.contains(key) })
            .map({ _ in return false })
    }
    
    public func isEnable(_ key: String) -> Observable<Bool> {
        return base.enableContextsRelay
            .filter({ $0.contains(key) })
            .map { _ in return true }
    }
    
    public func isDisable(_ key: String) -> Observable<Bool> {
        return base.disableContextsRelay
            .filter({ $0.contains(key) })
            .map({ _ in return false })
    }
}

public class VTextManager: NSObject {
    
    internal static let managerKey: NSAttributedString.Key =
        .init(rawValue: "VTextManager.key")
    
    public weak var typingDelegate: VTextTypingDelegate! {
        didSet {
            self.eventDisposeBag = DisposeBag()
            self.typingDelegate?.bindEvents(self)
        }
    }
    
    public weak var parserDelegate: VTextParserDelegate!
    public weak var accessoryDelegate: VTextAccessoryDelegate!
    
    internal let blockAttributeRelay = PublishRelay<[NSAttributedString.Key: Any]>()
    internal let currentAttributesRelay = PublishRelay<[NSAttributedString.Key: Any]>()
    internal let contexts: [VTypingContext]
    
    // control select / non-select relay
    internal let activeContextsRelay = PublishRelay<Set<String>>()
    internal let inactiveContextsRelay = PublishRelay<Set<String>>()
    
    // control enable / disable relay
    internal let enableContextsRelay = PublishRelay<Set<String>>()
    internal let disableContextsRelay = PublishRelay<Set<String>>()
    
    public let defaultKey: String
    private var eventDisposeBag = DisposeBag()
    
    public var allXMLTags: [String] {
        return contexts.map({ $0.xmlTag })
    }
    
    public var allKeys: [String] {
        return contexts.map({ $0.key })
    }
    
    public var defaultAttribute: [NSAttributedString.Key: Any]! {
        guard let delegate = self.typingDelegate else {
            fatalError("Please inherit VTextTypingDelegate!")
        }
        return delegate.typingAttributes(key: defaultKey).attributes
    }
    
    public init(_ contexts: [VTypingContext], defaultKey: String) {
        self.contexts = contexts
        self.defaultKey = defaultKey
        super.init()
    }
    
    public func fetchActiveAttribute(_ keys: [String]) -> [NSAttributedString.Key: Any] {
        guard case let defaultFilteredKey = keys.filter({ $0 != defaultKey }),
            !defaultFilteredKey.isEmpty else {
                return self.resetStatus()
        }
        
        for context in contexts {
            if defaultFilteredKey.contains(context.key) {
                context.currentStatusRelay.accept(.active)
            } else {
                context.currentStatusRelay.accept(.inactive)
            }
        }
        
        let targetKeys = contexts
            .filter({ $0.currentStatusRelay.value == .inactive })
            .map({ $0.key })
        
        self.activeContextsRelay.accept(.init(defaultFilteredKey))
        self.inactiveContextsRelay.accept(.init(targetKeys))
        self.enableContextsRelay.accept(.init(targetKeys))
        
        guard let delegate = self.typingDelegate else {
            fatalError("Please inherit VTextTypingDelegate!")
        }
        
        let typipngKeyDict: [NSAttributedString.Key: Any] =
            [VTextManager.managerKey: defaultFilteredKey as Any]
        let initialStyle = StringStyle([.extraAttributes(typipngKeyDict)])
        return defaultFilteredKey
            .map({ delegate.typingAttributes(key: $0) })
            .reduce(initialStyle, { result, item -> StringStyle in
                return result.byAdding(stringStyle: item)
            }).attributes
    }
    
    public func resetStatus() -> [NSAttributedString.Key: Any] {
        for context in contexts {
            if context.key == self.defaultKey {
                context.currentStatusRelay.accept(.active)
            } else {
                context.currentStatusRelay.accept(.inactive)
            }
        }
        
        let targetKeys = contexts
            .filter({ $0.currentStatusRelay.value == .inactive })
            .map({ $0.key })
        self.activeContextsRelay.accept(.init([defaultKey]))
        self.inactiveContextsRelay.accept(.init(targetKeys))
        self.enableContextsRelay.accept(.init(targetKeys))
        
        return self.defaultAttribute
    }
    
    public func updateCurrentAttribute(_ key: String) {
        guard let delegate = self.typingDelegate else {
            fatalError("Please inherit VTextTypingDelegate!")
        }
        
        guard let targetContext = contexts.filter({ $0.key == key }).first else {
            fatalError("Cannot find \(key) context!")
        }
        
        let isActive: Bool
        // toogle active/inactive status
        switch targetContext.currentStatusRelay.value {
        case .active:
            isActive = false
        case .inactive:
            isActive = true
        default:
            return // ignore
        }
        
        var activeKeys = contexts
            .filter({ $0.key != key })
            .filter({ $0.currentStatusRelay.value == .active })
            .map({ $0.key })
        
        var inactiveKeys: [String] = []
        var disableKeys: [String] = []
        
        if isActive {
            disableKeys.append(contentsOf: self.typingDelegate.disableKeys(key) ?? [])
            activeKeys.append(key)
            inactiveKeys.append(contentsOf: self.typingDelegate.inactiveKeys(key) ?? [])
        } else {
            inactiveKeys.append(contentsOf: self.typingDelegate.enableKeys(key) ?? [])
            inactiveKeys.append(key)
            activeKeys.append(contentsOf: self.typingDelegate.activeKeys(key) ?? [])
        }
        
        // safe manage keys filter
        activeKeys = activeKeys
            .filter({ !inactiveKeys.contains($0) })
            .filter({ !disableKeys.contains($0) })
        
        inactiveKeys = inactiveKeys
            .filter({ !disableKeys.contains($0) })
        
        // exception
        if activeKeys.isEmpty {
            activeKeys.append(defaultKey)
        }
        
        // apply status on context
        for context in contexts {
            if activeKeys.contains(context.key) {
                context.currentStatusRelay.accept(.active)
            } else if inactiveKeys.contains(context.key) {
                context.currentStatusRelay.accept(.inactive)
            } else if disableKeys.contains(context.key) {
                context.currentStatusRelay.accept(.disable)
            }
        }
        
        self.activeContextsRelay.accept(.init(activeKeys))
        self.inactiveContextsRelay.accept(.init(inactiveKeys))
        self.disableContextsRelay.accept(.init(disableKeys))
        self.enableContextsRelay.accept(.init(inactiveKeys))
        
        let currentActiveKeys = contexts
            .filter({ $0.currentStatusRelay.value == .active })
            .map({ $0.key })
        
        let typipngKeyDict: [NSAttributedString.Key: Any] =
            [VTextManager.managerKey: currentActiveKeys as Any]
        let initialStyle = StringStyle([.extraAttributes(typipngKeyDict)])
        
        let currentAttributes = currentActiveKeys
            .map({ delegate.typingAttributes(key: $0) })
            .reduce(initialStyle, { result, item -> StringStyle in
                return result.byAdding(stringStyle: item)
            }).attributes
        
        if targetContext.isBlockStyle {
            self.blockAttributeRelay.accept(currentAttributes)
        } else {
            self.currentAttributesRelay.accept(currentAttributes)
        }
    }
    
    /**
     Bind UIControl Event with VTextManager
     
     - parameters:
     - controlTarget: UIControl or UIControl subclass
     - key: typing context key
     
     - returns: void
     */
    public func bindControlEvent(_ target: UIControl, key: String) {
        
        target.rx.controlEvent(.touchUpInside)
            .bind(to: self.rx.didTap(key))
            .disposed(by: eventDisposeBag)
        
        self.rx.isActive(key)
            .bind(to: target.rx.isSelected)
            .disposed(by: eventDisposeBag)
        
        self.rx.isEnable(key)
            .bind(to: target.rx.isEnabled)
            .disposed(by: eventDisposeBag)
        
        self.rx.isInActive(key)
            .bind(to: target.rx.isSelected)
            .disposed(by: eventDisposeBag)
        
        self.rx.isDisable(key)
            .bind(to: target.rx.isEnabled)
            .disposed(by: eventDisposeBag)
        
    }
    
    public func getXMLTag(_ key: String) -> String? {
        return contexts.filter({ $0.key == key }).map({ $0.xmlTag }).first
    }
    
    public func getXMLTags(_ keys: [String]) -> [String]? {
        return contexts.filter({ keys.contains($0.key) }).map({ $0.xmlTag })
    }
    
    public func getKey(_ xmlTag: String) -> String? {
        return contexts.filter({ $0.xmlTag == xmlTag }).map({ $0.key }).first
    }
}
