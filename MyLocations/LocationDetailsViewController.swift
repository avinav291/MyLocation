import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()

class LocationDetailsViewController: UITableViewController{
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var addPhotoLabel: UILabel!
  
  var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  var placemark: CLPlacemark?

  var descriptionText = ""
  var categoryName = "No Category"
  var date = NSDate()
  var image: UIImage?
  
  var managedObjectContext: NSManagedObjectContext!
  var observer: AnyObject!

  var locationToEdit: Location? {
    didSet {
      if let location = locationToEdit {
        descriptionText = location.locationDescription
        categoryName = location.category
        date = location.date
        coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        placemark = location.placemark
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let location = locationToEdit {
      title = "Edit Location"
      if location.hasPhoto {
        if let image = location.photoImage {
          showImage(image: image)
        }
      }
    }
    
    descriptionTextView.text = descriptionText
    categoryLabel.text = categoryName
    
    latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
    longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
    
    if let placemark = placemark {
      addressLabel.text = stringFromPlacemark(placemark: placemark)
    } else {
      addressLabel.text = "No Address Found"
    }
    
    dateLabel.text = formatDate(date: date)

    let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector(("hideKeyboard:")))
    gestureRecognizer.cancelsTouchesInView = false
    tableView.addGestureRecognizer(gestureRecognizer)
    
    listenForBackgroundNotification()
    
    tableView.backgroundColor = UIColor.black()
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .white
    
    descriptionTextView.textColor = UIColor.white()
    descriptionTextView.backgroundColor = UIColor.black()
    
    addPhotoLabel.textColor = UIColor.white()
    addPhotoLabel.highlightedTextColor = addPhotoLabel.textColor
    
    addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
    addressLabel.highlightedTextColor = addressLabel.textColor
  }
  
  func hideKeyboard(gestureRecognizer: UIGestureRecognizer) {
    let point = gestureRecognizer.location(in: tableView)
    let indexPath = tableView.indexPathForRow(at: point)
    
    if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
      return
    }
    
    descriptionTextView.resignFirstResponder()
  }

  func listenForBackgroundNotification() {
    observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { [weak self] _ in
      
      if let strongSelf = self {
        if strongSelf.presentedViewController != nil {
          strongSelf.dismiss(animated: false, completion: nil)
        }
        strongSelf.descriptionTextView.resignFirstResponder()
      }
    }
  }
  
  deinit {
    print("*** deinit \(self)")
    NotificationCenter.default.removeObserver(observer)
  }

  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var line = ""
    line.addText(text: placemark.subThoroughfare)
    line.addText(text: placemark.thoroughfare, withSeparator: " ")
    line.addText(text: placemark.locality, withSeparator: ", ")
    line.addText(text: placemark.administrativeArea, withSeparator: ", ")
    line.addText(text: placemark.postalCode, withSeparator: " ")
    line.addText(text: placemark.country, withSeparator: ", ")
    return line
  }

  func formatDate(date: NSDate) -> String {
    return dateFormatter.string(from: date as Date)
  }

  func showImage(image: UIImage) {
    imageView.image = image
    imageView.isHidden = false
    imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
    addPhotoLabel.isHidden = true
  }
  
  @IBAction func done() {
    let hudView = HudView.hudInView(view: navigationController!.view, animated: true)

    let location: Location
    if let temp = locationToEdit {
      hudView.text = "Updated"
      location = temp
    } else {
      hudView.text = "Tagged"
      location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managedObjectContext) as! Location
      location.photoID = nil
    }
    
    location.locationDescription = descriptionTextView.text
    location.category = categoryName
    location.latitude = coordinate.latitude
    location.longitude = coordinate.longitude
    location.date = date
    location.placemark = placemark
    
    if let image = image {
      if !location.hasPhoto {
        location.photoID = Location.nextPhotoID()
      }
      if let data = UIImageJPEGRepresentation(image, 0.5) {
        do {
            
            try data.write(to: URL(string: location.photoPath)!, options: .atomic)
        } catch {
          print("Error writing file: \(error)")
        }
      }
    }
    
    do {
      try managedObjectContext.save()
    } catch {
      fatalCoreDataError(error: error)
    }

    afterDelay(seconds: 0.6) {
      self.dismiss(animated: true, completion: nil)
    }
  }
  
  @IBAction func cancel() {
    dismiss(animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "PickCategory" {
      let controller = segue.destinationViewController as! CategoryPickerViewController
      controller.selectedCategoryName = categoryName
    }
  }
  
  @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
    let controller = segue.sourceViewController as! CategoryPickerViewController
    categoryName = controller.selectedCategoryName
    categoryLabel.text = categoryName
  }
  
  // MARK: - UITableViewDelegate
  
   func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    switch (indexPath.section, indexPath.row) {
    case (0, 0):
      return 88
      
    case (1, _):
      return imageView.isHidden ? 44 : 280
      
    case (2, 2):
      addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
      addressLabel.sizeToFit()
      addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
      return addressLabel.frame.size.height + 20
      
    default:
      return 44
    }
  }
  
   func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    if indexPath.section == 0 || indexPath.section == 1 {
      return indexPath
    } else {
      return nil
    }
  }
  
   func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.section == 0 && indexPath.row == 0 {
      descriptionTextView.becomeFirstResponder()
    }
    else if indexPath.section == 1 && indexPath.row == 0 {
      tableView.deselectRow(at: indexPath as IndexPath, animated: true)
      pickPhoto()
    }
  }
  
   func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    cell.backgroundColor = UIColor.black()
    
    if let textLabel = cell.textLabel {
      textLabel.textColor = UIColor.white()
      textLabel.highlightedTextColor = textLabel.textColor
    }
    
    if let detailLabel = cell.detailTextLabel {
      detailLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
      detailLabel.highlightedTextColor = detailLabel.textColor
    }
    
    let selectionView = UIView(frame: CGRect.zero)
    selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
    cell.selectedBackgroundView = selectionView
    
    if indexPath.row == 2 {
      let addressLabel = cell.viewWithTag(100) as! UILabel
      addressLabel.textColor = UIColor.white()
      addressLabel.highlightedTextColor = addressLabel.textColor
    }
  }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func pickPhoto() {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      showPhotoMenu()
    } else {
      choosePhotoFromLibrary()
    }
  }
  
  func showPhotoMenu() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { _ in self.takePhotoWithCamera() })
    alertController.addAction(takePhotoAction)
    
    let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .default, handler: { _ in self.choosePhotoFromLibrary() })
    alertController.addAction(chooseFromLibraryAction)

    present(alertController, animated: true, completion: nil)
  }
  
  func takePhotoWithCamera() {
    let imagePicker = MyImagePickerController()
    imagePicker.sourceType = .camera
    imagePicker.delegate = self
    imagePicker.allowsEditing = true
    imagePicker.view.tintColor = view.tintColor
    present(imagePicker, animated: true, completion: nil)
  }
  
  func choosePhotoFromLibrary() {
    let imagePicker = MyImagePickerController()
    imagePicker.sourceType = .photoLibrary
    imagePicker.delegate = self
    imagePicker.allowsEditing = true
    imagePicker.view.tintColor = view.tintColor
    present(imagePicker, animated: true, completion: nil)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    image = info[UIImagePickerControllerEditedImage] as? UIImage
    
    if let image = image {
      showImage(image: image)
    }
    
    tableView.reloadData()
    dismiss(animated: true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
}
