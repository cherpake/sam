//
//  UpdateAdGroupByNameView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 20/10/2024.
//

import SwiftUI

struct UpdateAdGroupByNameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MainAppModel
    
    @Binding var adGroups: [AdGroupsViewItem]
    
    @State private var adGroupNames: String = ""
    @State private var showSpinner: Bool = false
    
    @State private var state: String = ""
    
    var body: some View {
        ZStack {
            #if os(macOS)
            // This makes the window bigger
            Spacer()
                .frame(width: 500, height: 500)
            #endif
            
            VStack {
                HStack {
                    Picker("State", selection: $state) {
                        Text("None").tag("")
                        Text("Enabled").tag("ENABLED")
                        Text("Paused").tag("PAUSED")
                    }
                }
                
                TextEditView(text: $adGroupNames)
                    .frame(maxWidth: .greatestFiniteMagnitude)
                    .border(Color.black.opacity(0.5))
                    .disabled(showSpinner)
            }
        }
        .padding()
        .overlay {
            if showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItemGroup() {
                Button("Update") {
                    Task {
                        try await update()
                    }
                }
            }
        }
    }

    func update() async throws {
        let names = adGroupNames
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",", omittingEmptySubsequences: true)
            .compactMap({ s in
                return s.trimmingCharacters(in: .whitespacesAndNewlines)
            })
        let updateAdGroups = adGroups.filter({ names.contains($0.name) })
        
        defer {
            DispatchQueue.main.async {
                showSpinner = false
                dismiss()
            }
        }
        
        guard
            let status = Status(rawValue: state),
            names.count > 0,
            updateAdGroups.count > 0
        else { return }
        
        DispatchQueue.main.async {
            
            showSpinner = true
        }
        
        try await viewModel.changeAdGroups(adGroups: updateAdGroups, update: AdGroupUpdate(status: status))
    }
}
