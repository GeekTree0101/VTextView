import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds) // create UIwindow
        if let window = window {
            let navController = UINavigationController.init(rootViewController: ViewController())
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
        
        return true
    }

}

