//
//  StoreItemTableViewDiffableDataSource.swift
//  iTunesSearch
//
//  Created by Duliba Sviatoslav on 24.05.2022.
//

import Foundation
import UIKit

@MainActor
class StoreItemTableViewDiffableDataSource: UITableViewDiffableDataSource<String, StoreItem> {
    
    override func tableView(_ tableView: UITableView,
       titleForHeaderInSection section: Int) -> String? {
        return snapshot().sectionIdentifiers[section]
    }
}
