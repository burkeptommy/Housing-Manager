import UIKit

extension UIView {
    func subviews<T: UIView>(ofType type: T.Type) -> [T] {
        var result: [T] = []
        for subview in subviews {
            if let typed = subview as? T { result.append(typed) }
            result.append(contentsOf: subview.subviews(ofType: type))
        }
        return result
    }
}
