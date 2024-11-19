//
//  TextEditView.swift
//  sam
//
//  Created by Evgeny Cherpak on 04/03/2023.
//

import SwiftUI

struct TextEditView: View {
    
    
    var text: Binding<String>
    
    @FocusState var focused: Bool
    
    var body: some View {
        TextEditor(text: text)
            #if os(iOS)
            .autocapitalization(.none)
            #endif
            .disableAutocorrection(true)
            .focused($focused)
            .padding()
            .onAppear {
                focused = true
            }
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        #if os(iOS)
                        if let value = UIPasteboard.general.string {
                            text.wrappedValue = value
                        }
                        #else
                        if let value = NSPasteboard.general.string(forType: .string) {
                            text.wrappedValue = value
                        }
                        #endif
                    } label: {
                        Text("Paste")
                    }
                }
            }
    }
}
