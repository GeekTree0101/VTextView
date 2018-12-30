import Foundation
import UIKit
import RxSwift
import RxCocoa
import BonMot

public protocol VTypingManagerDelegate: class {
    
    func bindEvents(_ manager: VTypingManager)
    func attributes(activeKeys: [String]) -> StringStyle
    func updateStatus(currentKey: String,
                      isActive: Bool,
                      prevActivedKeys: [String]) -> VTypingManager.StatusManageContext?
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
    
    public init(_ key: String, xmlTag: String) {
        self.key = key
        self.xmlTag = xmlTag
    }
}

extension Reactive where Base: VTypingManager {
    
    public func didTap(_ key: String) -> Binder<Void> {
        return Binder(base) { manager, _ in
            manager.didTapTargetKey(key)
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

public class VTypingManager: NSObject {
    
    public struct StatusManageContext {
        
        public var active: [String] = []
        public var inactive: [String] = []
        public var disable: [String] = []
        
        public init() {
            
        }
    }
    
    internal static let managerKey: NSAttributedString.Key =
        .init(rawValue: "VTypingManager.key")
    
    public weak var delegate: VTypingManagerDelegate! {
        didSet {
            self.eventDisposeBag = DisposeBag()
            self.delegate?.bindEvents(self)
        }
    }
    internal let currentAttributesRelay = PublishRelay<[NSAttributedString.Key: Any]>()
    internal let contexts: [VTypingContext]
    
    // control select / non-select relay
    internal let activeContextsRelay = PublishRelay<Set<String>>()
    internal let inactiveContextsRelay = PublishRelay<Set<String>>()
    
    // control enable / disable relay
    internal let enableContextsRelay = PublishRelay<Set<String>>()
    internal let disableContextsRelay = PublishRelay<Set<String>>()
    
    private let defaultKey: String
    private var eventDisposeBag = DisposeBag()
    
    public var allXMLTags: [String] {
        return contexts.map({ $0.xmlTag })
    }
    
    public var allKeys: [String] {
        return contexts.map({ $0.key })
    }
    
    public var defaultAttribute: [NSAttributedString.Key: Any]! {
        guard let delegate = self.delegate else {
            fatalError("Please inherit VTypingManagerDelegate!")
        }
        return delegate.attributes(activeKeys: [defaultKey]).attributes
    }
    
    public init(_ contexts: [VTypingContext], defaultKey: String) {
        self.contexts = contexts
        self.defaultKey = defaultKey
        super.init()
    }
    
    public func didTapTargetKey(_ key: String) {
        guard let delegate = self.delegate else {
            fatalError("Please inherit VTypingManagerDelegate!")
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
        
        let prevActivedKeys = contexts
            .filter({ $0.key != key })
            .filter({ $0.currentStatusRelay.value == .active })
            .map({ $0.key })
        
        guard let manageContext =
            delegate.updateStatus(currentKey: key,
                                  isActive: isActive,
                                  prevActivedKeys: prevActivedKeys) else { return }
        
        for context in contexts {
            if manageContext.active.contains(context.key) {
                context.currentStatusRelay.accept(.active)
            } else if manageContext.inactive.contains(context.key) {
                context.currentStatusRelay.accept(.inactive)
            } else if manageContext.disable.contains(context.key) {
                context.currentStatusRelay.accept(.disable)
            }
        }
        
        self.activeContextsRelay.accept(.init(manageContext.active))
        self.inactiveContextsRelay.accept(.init(manageContext.inactive))
        self.disableContextsRelay.accept(.init(manageContext.disable))
        self.enableContextsRelay.accept(.init(manageContext.inactive))
        
        let currentActiveKeys = contexts
            .filter({ $0.currentStatusRelay.value == .active })
            .map({ $0.key })
        
        var currentAttributes = delegate.attributes(activeKeys: currentActiveKeys).attributes
        currentAttributes[VTypingManager.managerKey] = currentActiveKeys as Any
        self.currentAttributesRelay.accept(currentAttributes)
    }
    
    /**
     Bind UIControl Event with VTypingMAnager
     
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
}
