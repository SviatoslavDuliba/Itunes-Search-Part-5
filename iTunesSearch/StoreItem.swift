
import Foundation
import UIKit
//MARK: - Properties
struct SearchResponse: Codable {
    let results: [StoreItem]
}

struct StoreItem: Codable, Hashable {
    let name: String
    let artist: String
    var kind: String
    var description: String
    var artworkURL: URL
    let trackId: Int?
    let collectionId: Int?
    
    enum CodingKeys: String, CodingKey {
        case name = "trackName"
        case artist = "artistName"
        case kind
        case description = "longDescription"
        case artworkURL = "artworkUrl100"
        case trackId
        case collectionId
    }
    
    enum AdditionalKeys: String, CodingKey {
        case description = "shortDescription"
        case collectionName = "collectionName"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.artist = try container.decode(String.self, forKey: .artist)
        self.kind = (try? container.decode(String.self, forKey: .kind)) ?? ""
        self.artworkURL = try container.decode(URL.self, forKey: .artworkURL)
        self.trackId = try? container.decode(Int.self, forKey: .trackId)
        self.collectionId = try? container.decode(Int.self, forKey: .collectionId)
        
        let additionalContainer = try decoder.container(keyedBy: AdditionalKeys.self)
        
        self.name = (try? container.decode(String.self, forKey: .name)) ?? (try? additionalContainer.decode(String.self, forKey: .collectionName)) ?? "--"
        self.description = (try? container.decode(String.self, forKey: .description)) ?? (try? additionalContainer.decode(String.self, forKey: .description)) ?? "--"
    }
}
//MARK: - Function
func createSectionedSnapshot(from items: [StoreItem]) ->
   NSDiffableDataSourceSnapshot<String, StoreItem> {
    let movies = items.filter { $0.kind == "feature-movie" }
    let music = items.filter { $0.kind == "song" || $0.kind == "album" }
    let apps = items.filter { $0.kind == "software" }
    let books = items.filter { $0.kind == "ebook" }

    let grouped: [(SearchScope, [StoreItem])] = [
        (.movies, movies),
        (.music, music),
        (.apps, apps),
        (.books, books)
    ]

    var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
    grouped.forEach { (scope, items) in
        if items.count > 0 {
            snapshot.appendSections([scope.title])
            snapshot.appendItems(items, toSection: scope.title)
        }
    }

    return snapshot
}


