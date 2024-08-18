//
//  ListBarPage.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 11/8/23.
//
import Foundation
import Firebase
import SwiftUI
import CoreLocation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Place: Identifiable, Decodable {
    var id: String
    var displayName: DisplayName
    var address: String?
    
    struct DisplayName: Decodable {
        var text: String
        var languageCode: String
    }
}
struct Filter {
    var name: String
    var isChecked: Bool
}

struct PlaceWithRating: Identifiable {
    var id: String { place.id }
    var place: Place
    var averageRating: Double?
    var averageSportsRating: Double?
    var averageMusicRating: Double?
    var modeBestDayToGo: String?
    var filterValue: Double?
    var isBookmarked: Bool = false
}

struct ListBarPage: View {
    @State private var zipCode = ""
    @State private var placesWithRatings: [PlaceWithRating] = []
    @State private var filters: [Filter] = [
        Filter(name: "Overall", isChecked: true),
        Filter(name: "Sports", isChecked: false),
        Filter(name: "Music", isChecked: false),
        Filter(name: "Monday", isChecked: false),
        Filter(name: "Tuesday", isChecked: false),
        Filter(name: "Wednesday", isChecked: false),
        Filter(name: "Thursday", isChecked: false),
        Filter(name: "Friday", isChecked: false),
        Filter(name: "Saturday", isChecked: false),
        Filter(name: "Sunday", isChecked: false),
    ]
    private func toggleBookmark(for placeId: String) {
        if let placeWithRating = placesWithRatings.first(where: { $0.id == placeId }) {
            if bookmarkViewModel.isBookmarked(barId: placeId) {
                bookmarkViewModel.removeBookmark(barId: placeId)
            } else {
                bookmarkViewModel.addBookmark(bar: placeWithRating)
            }
        }
    }
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    
    var body: some View {
        ZStack{
            //Color(.backgroundCyan).edgesIgnoringSafeArea(.all)
           
            NavigationView {
                VStack {
                    TextField("Enter Zip Code", text: $zipCode)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    let columns = 5
                    
                    VStack {
                        ForEach(0..<(filters.count / columns), id: \.self) { row in
                            HStack {
                                ForEach(0..<columns, id: \.self) { col in
                                    let index = row * columns + col
                                    if index < filters.count {
                                        Button(action: {
                                            for filterIndex in filters.indices {
                                                filters[filterIndex].isChecked = (filterIndex == index)
                                            }
                                            sortPlacesWithRatings()
                                        }) {
                                            HStack {
                                                Text(filters[index].name)
                                            }
                                            .shadow(radius: 20)
                                            .font(.system(size:16.5))
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 3)
                                            .background(filters[index].isChecked ? Color.accentColor : Color(white: 0.95))
                                            .foregroundColor(filters[index].isChecked ? Color.white : Color.accentColor)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    
                    Button("Search") {
                        getCoordinatesForZipCode()
                    }
                    .padding()
                    .foregroundColor(.colorWhite)
                    .font(.title3)
                    .bold()
                    .shadow(radius: 20)
                    .background(Color.accentColor)
                    .cornerRadius(8)

                    List(placesWithRatings) { placeWithRating in
                        NavigationLink(destination: ReviewPage(barName: placeWithRating.place.displayName.text, barId: placeWithRating.id)) {
                            VStack(alignment: .leading) {
                                Text(placeWithRating.place.displayName.text)
                                    .font(.headline)
                                if let averageRating = placeWithRating.averageRating,
                                   let averageSportsRating = placeWithRating.averageSportsRating,
                                   let averageMusicRating = placeWithRating.averageMusicRating,
                                   let modeBestDayToGo = placeWithRating.modeBestDayToGo {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.accent)
                                        Text("\(averageRating, specifier: "%.1f")")
                                            .foregroundColor(.black)
                                        Image(systemName: "sportscourt")
                                            .foregroundColor(.orange)
                                        Text("\(averageSportsRating, specifier: "%.1f")")
                                            .foregroundColor(.black)
                                        Image(systemName: "speaker.wave.2")
                                            .foregroundColor(.green)
                                        Text("\(averageMusicRating, specifier: "%.1f")")
                                            .foregroundColor(.black)
                                        
                                        
                                    }
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.gray)
                                        Text("\(modeBestDayToGo)")
                                            .foregroundColor(.black)
                                    }
                                } else {
                                    Text("No ratings yet!")
                                        .foregroundColor(.black)
                                }
                            }
                            Button(action: {
                                toggleBookmark(for: placeWithRating.id)
                            }) {
                                Image(systemName: placeWithRating.isBookmarked ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(placeWithRating.isBookmarked ? .yellow : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .navigationBarTitle(Text("Bars Found Near \(zipCode)"), displayMode: .inline)
                    }
                }
                .background(Color.backgroundCyan.edgesIgnoringSafeArea(.top))
            }
        }
    }
    
    func fetchReviewsForBar(barId: String, completion: @escaping ([BarReview]) -> ()) {
        let db = Firestore.firestore()
        db.collection("BarCheckReviews")
            .whereField("barId", isEqualTo: barId)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error.localizedDescription)")
                    completion([])
                } else {
                    let barReviews = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: BarReview.self)
                    } ?? []
                    
                    completion(barReviews)
                }
            }
    }
    private func sortPlacesWithRatings() {
        for filter in filters {
            if filter.isChecked {
                switch filter.name {
                case "Overall":
                    placesWithRatings.sort { ($0.averageRating ?? 0) > ($1.averageRating ?? 0) }
                case "Sports":
                    placesWithRatings.sort { ($0.averageSportsRating ?? 0) > ($1.averageSportsRating ?? 0) }
                case "Music":
                    placesWithRatings.sort { ($0.averageMusicRating ?? 0) > ($1.averageMusicRating ?? 0) }
                default:
                    let selectedDay = filter.name
                    placesWithRatings.sort { (place1, place2) in
                        let place1BestDay = place1.modeBestDayToGo?.split(separator: " ").first ?? ""
                        let place2BestDay = place2.modeBestDayToGo?.split(separator: " ").first ?? ""

                        if place1BestDay == selectedDay {
                            if place2BestDay != selectedDay {
                                return true
                            } else {
                                // Both have the same best day. Sort by rating.
                                return (place1.averageRating ?? 0) > (place2.averageRating ?? 0)
                            }
                        }
                        return false
                    }
                }
            }
        }
    }
    private func calculateAverageRating(reviews: [BarReview]) -> Double? {
        guard !reviews.isEmpty else {
            return nil
        }
        
        let totalRating = reviews.reduce(into: 0.0) { accumulator, review in
            accumulator += review.rating
        }
        
        return totalRating / Double(reviews.count)
    }
    private func calculateAverageSportsRating(reviews: [BarReview]) -> Double? {
        guard !reviews.isEmpty else {
            return nil
        }

        let totalRating = reviews.reduce(into: 0.0) { accumulator, review in
            accumulator += review.goodForWatchingSportsRating
        }

        return totalRating / Double(reviews.count)
    }
    private func calculateAverageMusicRating(reviews: [BarReview]) -> Double? {
        guard !reviews.isEmpty else {
            return nil
        }

        let totalRating = reviews.reduce(into: 0.0) { accumulator, review in
            accumulator += review.musicRating
        }

        return totalRating / Double(reviews.count)
    }
    private func calculateModeForBestDayToGo(reviews: [BarReview]) -> String? {
        guard !reviews.isEmpty else {
            return nil
        }

        let counts = reviews.reduce(into: [:]) { counts, review in
            counts[review.bestDaytoGo, default: 0] += 1
        }

        if let (value, count) = counts.max(by: { $0.1 < $1.1 }) {
            return "\(value) (\(count) reviews)"
        }

        return nil
    }

    func getCoordinatesForZipCode() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zipCode) { placemarks, error in
            guard let location = placemarks?.first?.location?.coordinate else {
                print("Error converting zip code to coordinates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            
            searchNearbyPlaces(latitude: location.latitude, longitude: location.longitude)
        }
    }
    
    func searchNearbyPlaces(latitude: Double, longitude: Double) {
        placesWithRatings.removeAll()
        let apiUrl = "https://places.googleapis.com/v1/places:searchNearby"
        
        let parameters: [String: Any] = [
            "includedTypes": ["bar", "night_club"],
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": latitude,
                        "longitude": longitude
                    ],
                    "radius": 500.0
                ]
            ]
        ]
        
        guard let url = URL(string: apiUrl) else {
            return
        }
        
        print("Latitude = \(latitude)")
        print("Longitude = \(longitude)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("AIzaSyBV16YYfsusan5Hz7J5344nlQnKlQtSt8A", forHTTPHeaderField: "X-Goog-Api-Key")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
        } catch {
            print("Error encoding parameters: \(error.localizedDescription)")
            return
        }
        
        request.addValue("places.displayName,places.id", forHTTPHeaderField: "X-Goog-FieldMask")
        request.addValue("places.*", forHTTPHeaderField: "X-Goog-FieldMask")
        
        URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(Response.self, from: data)
                DispatchQueue.main.async {
                    for place in response.places {
                        fetchReviewsForBar(barId: place.id) { reviews in
                            let averageRating = calculateAverageRating(reviews: reviews)
                            let averageSportsRating = calculateAverageSportsRating(reviews: reviews)
                            let averageMusicRating = calculateAverageMusicRating(reviews: reviews)
                            let modeBestDayToGo = calculateModeForBestDayToGo(reviews: reviews)
                            print("Best Day to Go for \(place.id): \(modeBestDayToGo ?? "No Data")")
                            placesWithRatings.append(PlaceWithRating(place: place, averageRating: averageRating,averageSportsRating: averageSportsRating, averageMusicRating: averageMusicRating, modeBestDayToGo: modeBestDayToGo))
                            
                           // placesWithRatings.sort { ($0.averageRating ?? -1) > ($1.averageRating ?? -1) }

                            
                            
                        }
                    }
                }
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
                print("Response String: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }.resume()
    }
}

struct Response: Decodable {
    var places: [Place]
    
    enum CodingKeys: String, CodingKey {
        case places
    }
}
struct View2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookmarkViewModel())
    }
}
