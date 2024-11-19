//
//  MoneyView.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI

struct MoneyView: View {
    var money: Money
    var title: String
    var optional: Bool = false
    var update: (String, Bool) async -> Void

    @State private var amount: String = "0.0"
    @State private var isOn: Bool = true
    @State private var showSpinner: Bool = false
    
    @FocusState private var focusField: Bool
    @Environment(\.dismiss) var dismiss
    
    @ViewBuilder func osSpecificTextFeild() -> some View {
        TextField(title, text: $amount)
        .focused($focusField)
        #if !os(macOS)
        .keyboardType(.decimalPad)
        #endif
    }
    
    @ViewBuilder func cancelButton() -> some View {
        Button("Cancel", role: .cancel) {
            dismiss()
        }
    }
    
    @ViewBuilder func updateButton() -> some View {
        Button() {
            self.showSpinner = true
            Task {
                await update(String(amount), isOn)
                DispatchQueue.main.async {
                    self.showSpinner = false
                    dismiss()
                }
            }
        } label: {
            Text("Update")
                .bold()
        }
        .disabled(Float(amount) ?? 0.0 == 0.0)
    }
    
    var body: some View {
        VStack {
            if optional {
                Toggle(isOn: $isOn) {
                    Text("On")
                }
            }
            HStack {
                Text(money.currency)
                    .foregroundColor(.gray)
                osSpecificTextFeild()
                    .disabled(!isOn)
            }
            .padding()
            Spacer()
        }
        .padding()
        #if !os(macOS)
        .navigationBarTitle(title)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                cancelButton()
            }
            ToolbarItem(placement: .primaryAction) {
                updateButton()
            }
        }
        .overlay(content: {
            if showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        })
        .onAppear {
            amount = money.amount
            isOn = Float(amount) ?? 0.0 > 0.0
            focusField = true
        }
    }
}
