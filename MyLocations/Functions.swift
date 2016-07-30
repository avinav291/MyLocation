import Foundation
import Dispatch

func afterDelay(seconds: Double, closure: () -> ()) {
  let when = DispatchTime.now(dispatch_time_t(DispatchTime.now), Int64(seconds * Double(NSEC_PER_SEC)))
  when.after(when: DispatchQueue.main(), execute: closure)
}

let applicationDocumentsDirectory: String = {
  let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
  return paths[0]
}()
