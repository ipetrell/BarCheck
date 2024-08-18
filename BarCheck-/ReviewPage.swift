//
//  ReviewPage.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 11/19/23.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Firebase
import FirebaseFirestoreSwift

struct BarReview: Identifiable, Decodable {
    @DocumentID var id: String?
    var userId: String
    var rating: Double
    var reviewText: String
    var goodForWatchingSportsRating: Double
    var musicRating: Double
    var bestDaytoGo: String
    
}

struct ReviewPage: View {
    @State private var rating = 3.0
    @State private var review = ""
    @State private var goodForWatchingSportsRating = 3.0
    @State private var musicRating = 3.0
    @State private var bestDaytoGo = 3.0
    @State private var barReviews: [BarReview] = []
    var barName: String
    var barId: String
    @State private var isWritingReview = false

    var body: some View {
        NavigationView {
            VStack {
                if let averageRating = calculateAverageRating() {
                    Text("Overall Rating: \(averageRating, specifier: "%.1f")")
                        .foregroundColor(.black)
                    HStack{
                        if let averageSportsRating = calculateAverageSportsRating() {
                            Image(systemName: "sportscourt")
                                .foregroundColor(.orange)
                                .imageScale(.large)
                            Text("\(averageSportsRating, specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                        if let averageMusicRating = calculateAverageMusicRating() {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.green)
                                .imageScale(.large)
                            Text("\(averageMusicRating, specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                        if let modeBestDayToGo = calculateModeForBestDayToGo() {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                            Text("\(modeBestDayToGo)")
                                .foregroundColor(.black)
                        }
                    }
                }
                List(barReviews) { review in
                    VStack(alignment: .center) {
                        Text("Rating: \(review.rating, specifier: "%.1f")")
                            .foregroundColor(.black)
                        Text("\(review.reviewText)")
                        HStack {
                            Image(systemName: "sportscourt")
                                .foregroundColor(.orange)
                            Text("Watching Sports Rating: \(review.goodForWatchingSportsRating, specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.green)
                            Text("Music Loudness Rating: \(review.musicRating,specifier: "%.1f")")
                                .foregroundColor(.black)
                        }
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text("Best Day to Go: \(review.bestDaytoGo)")
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .foregroundColor(.accentColor)
                    .background(Color.backgroundCyan.opacity(0.2))
                    .cornerRadius(8)

                }
                .navigationBarTitle(Text("Reviews for \(barName)"), displayMode: .inline)
                
                Button("Write a Review") {
                    isWritingReview.toggle()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.backgroundCyan)
                .cornerRadius(8)
                .fullScreenCover(isPresented: $isWritingReview) {
                    // Full-screen review submission view
                    WriteReviewView(barName: barName, barId: barId, isWritingReview: $isWritingReview)
                }
            }
            .padding()
            .onAppear {
                // Fetch reviews for the current bar when the view appears
                fetchReviewsForBar()
            }
            .onChange(of: isWritingReview) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    fetchReviewsForBar()
                }
            }
        }
    }
    private func calculateAverageRating() -> Double? {
        guard !barReviews.isEmpty else {
            return nil
        }

        let totalRating = barReviews.reduce(into: 0.0) { accumulator, review in
            accumulator += review.rating
        }

        return totalRating / Double(barReviews.count)
    }
    
    private func calculateAverageSportsRating() -> Double? {
        guard !barReviews.isEmpty else {
            return nil
        }

        let totalRating = barReviews.reduce(into: 0.0) { accumulator, review in
            accumulator += review.goodForWatchingSportsRating
        }

        return totalRating / Double(barReviews.count)
    }
    private func calculateAverageMusicRating() -> Double? {
        guard !barReviews.isEmpty else {
            return nil
        }

        let totalRating = barReviews.reduce(into: 0.0) { accumulator, review in
            accumulator += review.musicRating
        }

        return totalRating / Double(barReviews.count)
    }
    private func calculateModeForBestDayToGo() -> String? {
        guard !barReviews.isEmpty else {
            return nil
        }

        let counts = barReviews.reduce(into: [:]) { counts, review in
            counts[review.bestDaytoGo, default: 0] += 1
        }

        if let (value, count) = counts.max(by: { $0.1 < $1.1 }) {
            return "\(value) (\(count) reviews)"
        }

        return nil
    }
    func fetchUserReviewsCount(completion: @escaping (Int) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(0)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("BarCheckReviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching user's reviews: \(error.localizedDescription)")
                    completion(0)
                } else {
                    let count = querySnapshot?.documents.count ?? 0
                    completion(count)
                }
        }
    }
    // Function to fetch reviews for the current bar
    func fetchReviewsForBar() {
        let db = Firestore.firestore()
        db.collection("BarCheckReviews")
            .whereField("barId", isEqualTo: barId)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error.localizedDescription)")
                } else {
                    self.barReviews = querySnapshot?.documents.compactMap { document in
                        do {
                            let review = try document.data(as: BarReview.self)
                            return review
                        } catch {
                            print("Error decoding review: \(error.localizedDescription)")
                            return nil
                        }
                    } ?? []
                    
                }
            }
    }
}
struct RatingView: View {
    @Binding var rating: Double
    let maximumRating: Int

    var body: some View {
        HStack {
            ForEach(Array(1..<maximumRating + 1), id: \.self) { number in
                Image(systemName: number <= Int(rating) ? "star.fill" : "star")
                    .foregroundColor(number <= Int(rating) ? .accentColor : .gray)
                    .onTapGesture {
                        rating = Double(number)
                    }
            }
        }
    }
}

struct WriteReviewView: View {
    @State private var rating = 3.0
    @State private var review = ""
    var barName: String
    var barId: String
    @Binding var isWritingReview: Bool
    @State private var showingAlert = false
    @State private var goodForWatchingSportsRating = 3.0 // New field
    @State private var musicRating = 3.0 // New field
    @State private var bestDaytoGo = "Monday" // New field
    
    
    var body: some View {
        VStack (alignment: .center){
            HStack {
                Spacer()
                Button("Cancel"){isWritingReview.toggle()
                }
                .padding()
            }
            Text("Reviewing \(barName)")
                .font(.title)
                .padding()
            
            Text("Rating:")
            RatingView(rating: $rating, maximumRating: 5)
                .padding()
            
            Text("Review")
            TextEditor(text: $review)
                .border(Color.gray, width: 0.5)
            
            Text("Good for Watching Sports Rating:")
            Slider(value: $goodForWatchingSportsRating, in: 1...5, step: 1)
            Text("Music Loudness Rating:")
            Slider(value: $musicRating, in: 1...5, step: 1)
            
            // Add a picker for the new field here...
            Text("Best Day to Go:")
            Picker("Best Day to Go", selection: $bestDaytoGo) {
                ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Button("Submit Review") {
                let db = Firestore.firestore()
                db.collection("BarCheckReviews").addDocument(data: [
                    "barId": barId,
                    "rating": rating,
                    "reviewText": review,
                    "userId": Auth.auth().currentUser?.uid ?? "defaultUserID",
                    "goodForWatchingSportsRating": goodForWatchingSportsRating, // New field
                    "musicRating": musicRating, // New field
                    "bestDaytoGo": bestDaytoGo // New field
                ]) { error in
                    if let error = error {
                        print("Error adding review: \(error.localizedDescription)")
                    } else {
                        print("Review successfully added")
                        isWritingReview.toggle()
                    }
                }
                // Submit the review
                print("Submitted review: \(review), \(rating) stars")
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.backgroundCyan)
            .cornerRadius(8)
        }
        .padding()
    }
}

struct View3_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookmarkViewModel()) // This is the added line
    }
}
