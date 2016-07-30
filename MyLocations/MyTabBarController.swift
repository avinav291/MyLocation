import UIKit

class MyTabBarController: UITabBarController {
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .lightContent
  }
  
  override func childViewControllerForStatusBarStyle() -> UIViewController? {
    return nil
  }
}
