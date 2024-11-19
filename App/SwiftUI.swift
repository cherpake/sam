//
//  Extensions.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 07/11/2024.
//
import SwiftUI

struct ClearButton: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            HStack {
                Spacer()
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 10)
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

extension View {
    func clearButton(text: Binding<String>) -> some View {
        modifier(ClearButton(text: text))
    }
}
