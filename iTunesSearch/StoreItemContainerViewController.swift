
import UIKit

@MainActor
class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    //MARK: - Outlets
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    //MARK: - Properties
    let searchController = UISearchController()
    let storeItemController = StoreItemController()

    var tableViewDataSource: StoreItemTableViewDiffableDataSource!
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    
    var itemsSnapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
    var selectedSearchScope: SearchScope {
        
        let selectedIndex =
           searchController.searchBar.selectedScopeButtonIndex
        let searchScope = SearchScope.allCases[selectedIndex]
    
        return searchScope
    }
    
    var searchTask: Task<Void, Never>? = nil
    var tableViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    var collectionViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    weak var collectionViewController: StoreItemCollectionViewController?
    //MARK: - Live cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map {$0.title}
    }
    //MARK: - Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        }
        
        if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
            collectionViewController.configureCollectionViewLayout(for:
                                                                        selectedSearchScope)
            configureCollectionViewDataSource(collectionViewController.collectionView)
            
            self.collectionViewController = collectionViewController
        }
    }
    
    func configureTableViewDataSource(_ tableView: UITableView) {
        tableViewDataSource = StoreItemTableViewDiffableDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
            self.tableViewImageLoadTasks[indexPath]?.cancel()
            self.tableViewImageLoadTasks[indexPath] = Task {
                await cell.configure(for: item, storeItemController: self.storeItemController)
                self.tableViewImageLoadTasks[indexPath] = nil
            }
            return cell
        })
    }
    
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        
        collectionViewDataSource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: "Header",
                                            withReuseIdentifier:StoreItemCollectionViewSectionHeader.reuseIdentifier,
                                            for: indexPath) as! StoreItemCollectionViewSectionHeader
            let title = self.itemsSnapshot.sectionIdentifiers[indexPath.section]
            headerView.setTitle(title)
            
            return headerView
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchMatchingItems), object: nil)
        perform(#selector(fetchMatchingItems), with: nil, afterDelay: 0.3)
    }
                
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    @objc func fetchMatchingItems() {
        
        itemsSnapshot.deleteAllItems()
        
        let searchTerm = searchController.searchBar.text ?? ""
        let searchScopes: [SearchScope]
        if selectedSearchScope == .all {
            searchScopes = [.movies, .music, .apps, .books]
        } else {
            searchScopes = [selectedSearchScope]
        }
        collectionViewImageLoadTasks.values.forEach { task in task.cancel() }
        collectionViewImageLoadTasks = [:]
        tableViewImageLoadTasks.values.forEach { task in task.cancel() }
        tableViewImageLoadTasks = [:]
        
        searchTask?.cancel()
        searchTask = Task {
            if !searchTerm.isEmpty {
                
                searchTask = Task {
                    if !searchTerm.isEmpty {
                        do {
                            try await
                            fetchAndHandleItemsForSearchScopes(searchScopes,
                                                               withSearchTerm: searchTerm)
                        } catch  let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                        } catch {
                            print (error)
                        }
                        } else {
                            await self.tableViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
                            await self.collectionViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
                        }
                        searchTask = nil
                }
            }
        }
    }
    
    func handleFetchedItems(_ items: [StoreItem]) async {
        
        let currentSnapshotItems = snapshot.itemIdentifiers
        let updatedSnapshot = createSectionedSnapshot(from: currentSnapshotItems + items)
        snapshot = updatedSnapshot
        
        collectionViewController?.configureCollectionViewLayout(for: selectedSearchScope)
        
        await tableViewDataSource.apply(itemsSnapshot,
           animatingDifferences: true)
        await collectionViewDataSource.apply(itemsSnapshot,
           animatingDifferences: true)
    }
    
    func fetchAndHandleItemsForSearchScopes(_ searchScopes:
    [SearchScope], withSearchTerm searchTerm: String)
    async throws
    {
        try await withThrowingTaskGroup(of: (SearchScope,
                                             [StoreItem]).self) { group in
            for searchScope in searchScopes { group.addTask {
                try Task.checkCancellation()
                let query = [
                    "term": searchTerm,
                    "media": searchScope.mediaType,
                    "lang": "en_us",
                    "limit": "50"]
                return (searchScope, try await
                        self.storeItemController.fetchItems(matching: query))
                }
            }
            
            for try await (SearchScope, items) in group {
                try Task.checkCancellation()
                if searchTerm == self.searchController.searchBar.text &&
                    (self.searchController.searchBar.text != nil) &&
                    (self.selectedSearchScope == .all || SearchScope == self.selectedSearchScope) {
                    await handleFetchedItems(items)
                }
            }
        }
    }
}
