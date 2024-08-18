//
//  BookmarkViewModel.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 2/12/24.
//

import Foundation
import SwiftUI

class BookmarkViewModel: ObservableObject {
    @Published var bookmarkedBars: [PlaceWithRating] = []
    
    func addBookmark(bar: PlaceWithRating) {
        if !bookmarkedBars.contains(where: { $0.id == bar.id }) {
            bookmarkedBars.append(bar)
        }
    }
    
    func removeBookmark(barId: String) {
        bookmarkedBars.removeAll { $0.id == barId }
    }
    
    func isBookmarked(barId: String) -> Bool {
        bookmarkedBars.contains { $0.id == barId }
    }
}


