import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController {
  var managedObjectContext: NSManagedObjectContext!

  lazy var fetchedResultsController: NSFetchedResultsController = {
    let fetchRequest = NSFetchRequest(entityName: "Location")
    let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedObjectContext)
    fetchRequest.entity = entity
    
    let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
    let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
    
    fetchRequest.fetchBatchSize = 20
    
    let fetchedResultsController = NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: self.managedObjectContext,
      sectionNameKeyPath: "category",
      cacheName: "Locations")
    
    fetchedResultsController.delegate = self
    return fetchedResultsController
  }()

  deinit {
    fetchedResultsController.delegate = nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    performFetch()
    navigationItem.rightBarButtonItem = editButtonItem()

    tableView.backgroundColor = UIColor.black()
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .white
  }
  
  func performFetch() {
    do {
      try fetchedResultsController.performFetch()
    } catch {
      fatalCoreDataError(error: error)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "EditLocation" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsViewController
      controller.managedObjectContext = managedObjectContext
      
      if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
        let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
        controller.locationToEdit = location
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
   func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedResultsController.sections!.count
  }
  
   override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.name.uppercaseString
  }
  
   override func tableView(_ tableView: UITableView,numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.numberOfObjects
  }
  
   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath as IndexPath) as! LocationCell

    let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
    cell.configureForLocation(location)
    
    return cell
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .delete {
      let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
      location.removePhotoFile()
      managedObjectContext.deleteObject(location)
      
      do {
        try managedObjectContext.save()
      } catch {
        fatalCoreDataError(error)
      }
    }
  }
  
  // MARK: - UITableViewDelegate
  
  override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14, width: 300, height: 14)
    let label = UILabel(frame: labelRect)
    label.font = UIFont.boldSystemFont(ofSize: 11)
    
    label.text = tableView.dataSource!.tableView!(tableView, titleForHeaderInSection: section)
    
    label.textColor = UIColor(white: 1.0, alpha: 0.4)
    label.backgroundColor = UIColor.clear()
    
    let separatorRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 0.5, width: tableView.bounds.size.width - 15, height: 0.5)
    let separator = UIView(frame: separatorRect)
    separator.backgroundColor = tableView.separatorColor
    
    let viewRect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight)
    let view = UIView(frame: viewRect)
    view.backgroundColor = UIColor(white: 0, alpha: 0.85)
    view.addSubview(label)
    view.addSubview(separator)
    return view
  }
}

extension LocationsViewController: NSFetchedResultsControllerDelegate {
  
  private func controllerWillChangeContent(controller: NSFetchedResultsController<AnyObject>) {
    print("*** controllerWillChangeContent")
    tableView.beginUpdates()
  }
  
  func controller(controller: NSFetchedResultsController<AnyObject>, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .insert:
      print("*** NSFetchedResultsChangeInsert (object)")
      tableView.insertRows(at: [newIndexPath! as IndexPath], with: .fade)
      
    case .delete:
      print("*** NSFetchedResultsChangeDelete (object)")
      tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
      
    case .update:
      print("*** NSFetchedResultsChangeUpdate (object)")
      if let cell = tableView.cellForRow(at: indexPath! as IndexPath) as? LocationCell {
        let location = controller.objectAtIndexPath(indexPath!) as! Location
        cell.configureForLocation(location)
      }
    case .move:
      print("*** NSFetchedResultsChangeMove (object)")
      tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
      tableView.insertRows(at: [newIndexPath! as IndexPath], with: .fade)
    }
  }
  
  func controller(controller: NSFetchedResultsController<AnyObject>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .insert:
      print("*** NSFetchedResultsChangeInsert (section)")
      tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
      
    case .delete:
      print("*** NSFetchedResultsChangeDelete (section)")
      tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
      
    case .update:
      print("*** NSFetchedResultsChangeUpdate (section)")
      
    case .move:
      print("*** NSFetchedResultsChangeMove (section)")
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController<AnyObject>) {
    print("*** controllerDidChangeContent")
    tableView.endUpdates()
  }
}
