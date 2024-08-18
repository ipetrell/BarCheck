//
//  RecommendedBars.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 11/9/23.
//

import Foundation
import SwiftUI
import Firebase
import GoogleSignIn
import GoogleSignInSwift
import MapKit

struct BookmarkPage: View {
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    
    var body: some View {
        NavigationView{
            ZStack{
                Color(.backgroundCyan)
                VStack(spacing: 0) {
                    HStack {
                        Text("Bookmarked Bars")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.accent)
                            .padding()
                        Spacer()
                    }
                    .background(Color.backgroundCyan)
                    List(bookmarkViewModel.bookmarkedBars) { bar in
                        HStack {
                            NavigationLink(destination: ReviewPage(barName: bar.place.displayName.text, barId: bar.id)) {
                                VStack(alignment: .leading) {
                                    Text(bar.place.displayName.text)
                                        .font(.headline)
                                    if let averageRating = bar.averageRating,
                                       let averageSportsRating = bar.averageSportsRating,
                                       let averageMusicRating = bar.averageMusicRating,
                                       let modeBestDayToGo = bar.modeBestDayToGo {
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
                                            Text(modeBestDayToGo)
                                                .foregroundColor(.black)
                                        }
                                    } else {
                                        Text("No ratings yet!")
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer() // This pushes the button to the right
                            
                            Button(action: {
                                bookmarkViewModel.removeBookmark(barId: bar.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                // .navigationTitle("Bookmarked Bars")
            }
        }
    }
}

struct View_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookmarkViewModel())
    }
}
