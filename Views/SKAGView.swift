//
//  SKAGView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 03/03/2024.
//

import SwiftUI

struct SKAGView: View {
    @EnvironmentObject var viewModel: MainAppModel
    
    var currency: String = "USD"
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var keywords: String = ""
    @State private var showSpinner: Bool = false
    
    @State private var amount: String = "0.5"
    @State private var goal: String = "0.0"
    @State private var exact: Bool = true
    
    @ViewBuilder func osSpecificTextFeild(textBinding: Binding<String>) -> some View {
        TextField("Bid Amount", text: textBinding)
        #if !os(macOS)
        .keyboardType(.decimalPad)
        #endif
    }
    
    var body: some View {
        ZStack {
            #if os(macOS)
            // This makes the window bigger
            Spacer()
                .frame(width: 500, height: 500)
            #endif
            
            VStack {
                HStack {
                    osSpecificTextFeild(textBinding: $amount)
                    Text(currency)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Goal")
                        .foregroundColor(.gray)
                    osSpecificTextFeild(textBinding: $goal)
                    Text(currency)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Toggle(isOn: $exact) {
                        Text("Exact")
                    }
                    .toggleStyle(.checkboxStyle)
                }
                
                TextEditView(text: $keywords)
                    .frame(maxWidth: .greatestFiniteMagnitude)
                    .border(Color.black.opacity(0.5))
                    
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
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    add()
                }
            }
        }
    }
    
    func add() {
        guard
            let campaign = viewModel.campaignSelection,
            let campaignId = Int64(campaign),
            let orgId = UserDefaults.standard.orgId
        else {
            // TODO: show alert
            return
        }
        
        showSpinner = true
        
        Task {
            defer {
                DispatchQueue.main.async {
                    showSpinner = false
                    dismiss()
                }
            }
            
            // Keywords
            let array = keywords
                .replacingOccurrences(of: "\n", with: ",")
                .split(separator: ",", omittingEmptySubsequences: true)
                .compactMap({ s in
                    return s.trimmingCharacters(in: .whitespacesAndNewlines)
                })
            
            let amount = Money(amount: amount, currency: currency)
            var goalAmount: Money? = nil
            if let goalValue = Int(goal), goalValue > 0 {
                goalAmount = Money(amount: goal, currency: currency)
            }
            
            for s in array {
                do {
                    guard let adGroup = try await SearchAds.instance.createAdGroup(
                        campaignId: campaignId,
                        adGroup: AdGroup(
                            automatedKeywordsOptIn: false,
                            campaignId: campaignId,
                            cpaGoal: goalAmount,
                            defaultBidAmount: amount,
                            name: s,
                            orgId: orgId,
                            pricingModel: "CPC",
                            status: Status.enabled,
                            startTime: .init(
                                date: Date(),
                                includeTime: true
                            )
                        )
                    ) else { continue }
                    
                    guard let id = adGroup.id else { continue }
                    
                    let _ = try await SearchAds.instance.addKeywords(
                        adGroup: adGroup,
                        keywords: [
                            Keyword(
                                adGroupId: id,
                                bidAmount: amount,
                                matchType: exact ? .exact : .broad,
                                text: s
                            )
                        ]
                    )
                } catch let error {
                    debugPrint(error)
                }
            }
        }
    }
}
