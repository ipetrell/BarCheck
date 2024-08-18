//
//  View3.swift
//  BarCheck_
//
//  Created by Isaac Petrella on 10/17/23.
//

import SwiftUI

struct CustomTextField: View {
    var hint: String
    @Binding var text: String
    
    // MARK: View Properties
    @FocusState var isEnabled: Bool
    var contentType: UITextContentType = .telephoneNumber
    var body: some View{
        VStack(alignment: .leading, spacing: 15) {
            TextField(hint, text: $text)
                .keyboardType(.numberPad)
                .textContentType(contentType)
                .focused($isEnabled)
            ZStack(alignment: .leading) {
                    Rectangle()
                    .fill(.white.opacity(0.2))
                
                Rectangle()
                    .fill(.white)
                    .frame(width: isEnabled ? nil : 0, alignment: .leading)
                    .animation(.easeInOut(duration: 0.3), value: isEnabled)
            }
            .frame(height: 2)
        }
    }
}

#Preview {
    ContentView()
}
