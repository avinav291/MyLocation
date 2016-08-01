import Foundation
import Dispatch

func afterDelay(seconds: Double, closure: () -> ()) {
  let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
  dispatch_after(when, dispatch_get_main_queue(), closure)
}

let applicationDocumentsDirectory: String = {
  let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
  return paths[0]
}()
