//
//  LogoutPage.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 2/25/24.
//
import Foundation
import SwiftUI
import Firebase
import GoogleSignIn
import CoreLocation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct LogoutPage: View {
    @Binding var logStatus: Bool
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @State private var reviewsCount: Int = 0
    
    var body: some View {
        ZStack {
            Color(.backgroundCyan).edgesIgnoringSafeArea(.top)
            
            VStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                    .padding(.top, 100)
                
                // Display user stats
                VStack(spacing: 20) {
                    Text("Your Activity")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                        .padding([.top, .bottom], 8)
                    Text("Reviews written: \(reviewsCount)")
                        .foregroundColor(.white)
                        .font(.title3)
                        .bold()
                    Text("Bars bookmarked: \(bookmarkViewModel.bookmarkedBars.count)")
                        .foregroundColor(.white)
                        .font(.title3)
                        .bold()
                   
                    }
                    .shadow(radius: 30)
                    .padding(.all, 20)
                    .background(Color.accent)
                    .cornerRadius(20)
                    
                Spacer()
                
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        try? Auth.auth().signOut()
                        GIDSignIn.sharedInstance.signOut()
                        withAnimation(.easeInOut) {
                            logStatus = false
                        }
                    }) {
                        Image(systemName: "arrow.right.square.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .foregroundColor(.accent)
                            .padding()
                    }
                }
                .padding(.top, 44)
                Spacer()
            }
        }
        .onAppear {
            fetchUserReviewsCount { count in
                reviewsCount = count
            }
        }
    }
    
    func fetchUserReviewsCount(completion: @escaping (Int) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(0)
            return
        }
        let db = Firestore.firestore()
        db.collection("BarCheckReviews").whereField("userId", isEqualTo: userId).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(0)
            } else {
                let count = querySnapshot?.documents.count ?? 0
                completion(count)
            }
        }
    }
}
struct LogoutPage_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookmarkViewModel())
    }
}
