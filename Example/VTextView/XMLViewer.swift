import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit

class XMLViewer: UIViewController {
    
    lazy var textView: UITextView = UITextView(frame: .zero)
    
    let disposeBag = DisposeBag()
    
    init(_ text: String) {
        super.init(nibName: nil, bundle: nil)
        self.textView.text = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(textView)
        textView.font = UIFont.systemFont(ofSize: 15.0)
        textView.snp.makeConstraints({ make in
            make.edges.equalTo(self.view.safeArea.edges)
        })
    }
}
