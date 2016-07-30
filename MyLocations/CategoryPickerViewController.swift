import UIKit

class CategoryPickerViewController: UITableViewController {
  var selectedCategoryName = ""
  
  let categories = [
    "No Category",
    "Apple Store",
    "Bar",
    "Bookstore",
    "Club",
    "Grocery Store",
    "Historic Building",
    "House",
    "Icecream Vendor",
    "Landmark",
    "Park"]
  
  var selectedIndexPath = NSIndexPath()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    for i in 0..<categories.count {
      if categories[i] == selectedCategoryName {
        selectedIndexPath = NSIndexPath(row: i, section: 0)
//        selectedIndexPath = NSIndexPath(forRow: i, inSection: 0)
        break
      }
    }
    
    tableView.backgroundColor = UIColor.black()
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .white
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "PickedCategory" {
      let cell = sender as! UITableViewCell
      if let indexPath = tableView.indexPath(for: cell) {
        selectedCategoryName = categories[indexPath.row]
      }
    }
  }
    
  // MARK: - UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return categories.count
  }
  
   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
    
    let categoryName = categories[indexPath.row]
    cell.textLabel!.text = categoryName
    
    if categoryName == selectedCategoryName {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
    
    return cell
  }
  
  // MARK: - UITableViewDelegate
  
   func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row != selectedIndexPath.row {
      if let newCell = tableView.cellForRow(at: indexPath as IndexPath) {
        newCell.accessoryType = .checkmark
      }

      if let oldCell = tableView.cellForRow(at: selectedIndexPath as IndexPath) {
        oldCell.accessoryType = .none
      }

      selectedIndexPath = indexPath
    }
  }

   func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    cell.backgroundColor = UIColor.black()
    
    if let textLabel = cell.textLabel {
      textLabel.textColor = UIColor.white()
      textLabel.highlightedTextColor = textLabel.textColor
    }
    
    let selectionView = UIView(frame: CGRect.zero)
    selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
    cell.selectedBackgroundView = selectionView
  }
}
