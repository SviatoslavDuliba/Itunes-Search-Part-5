
import UIKit

class StoreItemCollectionViewController: UICollectionViewController {
    //MARK: - Live cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func configureCollectionViewLayout(for searchScope: SearchScope) {
            let itemSize = NSCollectionLayoutSize(widthDimension:
                                                        .fractionalWidth(1/3), heightDimension:
                                                        .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 8, leading: 5, bottom: 8, trailing: 5)
            let groupSize = NSCollectionLayoutSize(widthDimension:searchScope.groupWidthDimension,
                                                   heightDimension: .absolute(166))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                           subitem: item,
                                                           count: searchScope.groupItemCount)
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = searchScope.orthogonalScrollingBehavior
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(28))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                         elementKind: "Header",
                                                                         alignment: .topLeading)
            section.boundarySupplementaryItems = [headerItem]
            let layout = UICollectionViewCompositionalLayout(section: section)
            collectionView.collectionViewLayout = layout
        }
        
        collectionView.register(StoreItemCollectionViewSectionHeader.self,
                                forSupplementaryViewOfKind:"Header",
                                withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier)
    }
    
}
