//
//  GooglePlacesService.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 11/9/23.
//

import Foundation

struct PlacesResponse: Codable {
    struct Result: Codable {
        var name: String
        var vicinity: String
    }
    
    var results: [Result]
}

class GooglePlacesService {
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchBarsNearby(location: String, completion: @escaping (Result<[Bar], Error>) -> Void) {
        print("Fetching bars for location: \(location)")
        guard let url = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=&radius=5000&type=bar&key=\(apiKey)") else {
            completion(.failure(NSError(domain: "com.IsaacPetrella.BarCheck-", code: 1, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                do {
                    let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
                    print("API Response: \(response)")
                    let bars = response.results.map { Bar(name: $0.name, address: $0.vicinity) }
                    completion(.success(bars))
                } catch {
                    print("Error decoding API response: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
