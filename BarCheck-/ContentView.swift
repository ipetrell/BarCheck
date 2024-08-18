//
//  ContentView.swift
//  BarCheck_
//
//  Created by Isaac Petrella on 10/17/23.
//

import SwiftUI
import Firebase
import GoogleSignIn
import GoogleSignInSwift
import MapKit

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    @State private var cameraPosition: MapCameraPosition = .region(.userRegion)
    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State private var mapSelection: MKMapItem?
    @State private var showDetails = false
    @State private var getDirections = false
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    

    
    func searchNightlifeLocations() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "bars"
        request.region = .userRegion
        let searchResults = try? await MKLocalSearch(request: request).start()
        self.results = searchResults?.mapItems ?? []
    }
    
    var body: some View {
        TabView {
            if logStatus {
                ListBarPage()
                    .tabItem{
                        Label("Search Reviews", systemImage: "magnifyingglass")
                    }
                BarMap()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                BookmarkPage()
                    .tabItem{
                        Label("Bookmarked", systemImage: "bookmark.fill")
                    }
                LogoutPage(logStatus: $logStatus)
                    .tabItem{
                        Label("Profile", systemImage: "person")
                    }
            } else {
                Login()
            }
        }
    }
    
//    @ViewBuilder
//    func LogoutPage() -> some View {
//        ZStack{
//            Color(.backgroundCyan)
//            VStack{
//                Button("Log Out"){
//                    
//                    try? Auth.auth().signOut()
//                    GIDSignIn.sharedInstance.signOut()
//                    withAnimation(.easeInOut){
//                        logStatus = false
//                    }
//                }.frame(width: 170, height: 48)
//                    .background(.colorWhite)
//                    .cornerRadius(12)
//            }
//            
//        }
//    }
    
    @ViewBuilder
    func BarMap() -> some View{
        NavigationView{
            
            Map(position: $cameraPosition, selection: $mapSelection){
                Annotation("My Location", coordinate: .userLocation){
                    ZStack{
                        Circle()
                            .frame(width:32, height: 32)
                            .foregroundStyle(.blue.opacity(0.25))
                        Circle()
                            .frame(width:20, height: 20)
                            .foregroundStyle(.colorWhite)
                        Circle()
                            .frame(width:12, height: 12)
                            .foregroundStyle(.blue)
                    }
                }
                ForEach(results, id: \.self) {item in
                    if routeDisplaying {
                        if item == routeDestination {
                            let placemark = item.placemark
                            Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                        }
                    } else {
                        let placemark = item.placemark
                        Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                    }
                }
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.accent, lineWidth: 6)
                }
                
            }
            
            .overlay(alignment: .top){
                TextField("Search for a bar...", text: $searchText)
                    .font(.subheadline)
                    .padding(10)
                    .background(.colorWhite)
                    .padding()
                    .shadow(radius: 10)
            }
            .onAppear {
                Task{
                    await searchNightlifeLocations()
                }
            }
            .onSubmit(of: .text){
                Task { await searchPlaces()
                }
            }
            .onChange(of: getDirections, { oldValue, newValue in
                if newValue {
                    fetchRoute()
                }
            })
            .onChange(of: mapSelection, {oldValue, newValue in
                showDetails = newValue != nil
            })
            .sheet(isPresented: $showDetails, content: {
                BarDetailView(mapSelection: $mapSelection, show: $showDetails, getDirections: $getDirections)
                    .presentationDetents([.height(350)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(350)))
                    .presentationCornerRadius(12)
            })
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
            }
            
        
        }
    }
}
extension ContentView {
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = .userRegion
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
        self.results = results?.mapItems.filter { mapItem in
                    return mapItem.pointOfInterestCategory == .nightlife
                } ?? []
            }
    
    
    func fetchRoute() {
        if let mapSelection {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: .userLocation))
            request.destination = mapSelection
            
            Task {
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first
                routeDestination = mapSelection
                
                withAnimation(.snappy){
                    routeDisplaying = true
                    showDetails = false
                    
                    if let rect = route?.polyline.boundingMapRect, routeDisplaying {
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
    }
}
extension CLLocationCoordinate2D {
    static var userLocation: CLLocationCoordinate2D {
        return .init(latitude: 42.8943, longitude: -78.8736)
    }
}


extension MKCoordinateRegion{
    static var userRegion: MKCoordinateRegion {
        return .init(center: .userLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookmarkViewModel()) 
    }
}
