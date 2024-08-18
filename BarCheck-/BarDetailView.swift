//
//  BarDetailView.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 10/31/23.
//
import MapKit
import SwiftUI

struct BarDetailView: View {
    @Binding var mapSelection: MKMapItem?
    @Binding var show: Bool
    @State private var lookAroundScene: MKLookAroundScene?
    @Binding var getDirections: Bool
    var body: some View {
        VStack{
            HStack{
                VStack(alignment: .leading){
                    Text(mapSelection?.placemark.name ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(mapSelection?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                        .padding(.trailing)
                }
                Spacer()
                
                Button {
                    show.toggle()
                    mapSelection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray, Color(.systemGray6))
                }
            }
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding()
            }else{
                ContentUnavailableView("No preview available", systemImage: "eye.slash")
            }
            HStack(spacing:24){
                Button {
                    if let mapSelection{
                        mapSelection.openInMaps()
                    }
                } label: {
                    Text("Open in Maps")
                        .font(.headline)
                        .foregroundColor(.colorWhite)
                        .frame(width: 170, height: 48)
                        .background(.accent)
                        .cornerRadius(12)
                }
                Button {
                        getDirections = true
                        show = false
                } label: {
                    Text("Get Directions")
                        .font(.headline)
                        .foregroundColor(.colorWhite)
                        .frame(width: 170, height: 48)
                        .background(.backgroundCyan)
                        .cornerRadius(12)
                }
                
            }
            .padding(.horizontal)
        }
        .onAppear {
            fetchLookAroundPreview()
        }
        .onChange(of: mapSelection) { oldValue, newValue in
            fetchLookAroundPreview()
        }
        .padding()
    }
}

extension BarDetailView {
    func fetchLookAroundPreview() {
        if let mapSelection {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScene = try? await request.scene
            }
        }
    }
}

#Preview {
    BarDetailView(mapSelection: .constant(nil), show: .constant(false), getDirections: .constant(false))
}
