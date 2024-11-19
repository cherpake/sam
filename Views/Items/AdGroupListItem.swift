//
//  AdGroupListItem.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/03/2023.
//

import SwiftUI
import Combine

struct AdGroupListItem: View {
    enum AlertType {
        case none
        case remove
        case searchMatch
    }
    
    @EnvironmentObject var viewModel: ViewModel
    @State var cancallable = [AnyCancellable]()
    @State var totals: SpendRow?

    @State var adGroup: AdGroup
    @State private var showAlert: Bool = false
    @State private var showRanameAlert: Bool = false
    @State private var alertType: AlertType = .none
    @State private var showUpdateMaxCPT: Bool = false
    @State private var showUpdateCPAGoal: Bool = false
    @State private var name: String = "" // it's here for renaming
    
    var onRemove: (AdGroup) -> Void
    
    var body: some View {
        HStack {
            Toggle(isOn: Binding(get: {
                return viewModel.selectedAdGroupsIds?.contains(adGroup.id ?? 0) ?? false
            }, set: { v, t in
                if v {
                    if viewModel.selectedAdGroupsIds == nil {
                        viewModel.selectedAdGroupsIds = Set<Int64>()
                    }
                    viewModel.selectedAdGroupsIds?.insert(adGroup.id ?? 0)
                } else {
                    viewModel.selectedAdGroupsIds?.remove(adGroup.id ?? 0)
                }
            })) {
                
            }
            .toggleStyle(.checkboxStyle)
            
            VStack(alignment: .leading) {
                Text(adGroup.name)
                    .bold()
                
                Text("Bid: \(Float(adGroup.defaultBidAmount.amount)!.formatted(.currency(code: adGroup.defaultBidAmount.currency)))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: true)
                
                if let money = adGroup.cpaGoal {
                    Text("CPA Goal: \(Float(money.amount)!.formatted(.currency(code: money.currency)))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: true, vertical: true)
                }
                if adGroup.automatedKeywordsOptIn {
                    Text("Search Match")
                        .font(.footnote)
                        .bold()
                        .foregroundColor(.red)
                }
            }
            Spacer()
            Group {
                if let totals {
                    TotalsView(title: adGroup.name, totals: totals, mode: .comapct)
                        .fixedSize(horizontal: true, vertical: true)
                } else {
                    LoadingView()
                        .fixedSize(horizontal: true, vertical: true)
                        .padding()
                }
            }
            StatusView(campaign: viewModel.selectedCampaign?.status, adGroup: adGroup.status)
        }
        .contextMenu {
            Button() {
                Task {
                    guard let updated = await update(update: AdGroupUpdate(
                        cpaGoal: adGroup.cpaGoal,
                        status: .enabled
                    )) else { return }
                    self.adGroup = updated
                }
            } label: {
                Image(systemName: "play.fill")
                Text("Activate")
            }
            Button() {
                Task {
                    guard let updated = await update(update: AdGroupUpdate(
                        cpaGoal: adGroup.cpaGoal,
                        status: .paused
                    )) else { return }
                    self.adGroup = updated
                }
            } label: {
                Image(systemName: "pause.fill")
                Text("Pause")
            }
            Divider()
            Button(role: .destructive) {
                self.alertType = .remove
                self.showAlert = true
            } label: {
                Image(systemName: "trash")
                Text("Remove")
            }
            Divider()
            Button() {
                self.showUpdateMaxCPT = true
            } label: {
                Image(systemName: "dollarsign.circle")
                Text("Edit Default Max CPT Bid")
            }
            Button() {
                self.showUpdateCPAGoal = true
            } label: {
                Image(systemName: "dollarsign.circle")
                Text("Edit CPA Goal")
            }
            Divider()
            Button() {
                self.alertType = .searchMatch
                self.showAlert = true
            } label: {
                Image(systemName: "exclamationmark.icloud.fill")
                Text("Edit Search Match")
            }
            Group {
                Divider()
                Button() {
                    self.name = adGroup.name
                    self.showRanameAlert = true
                } label: {
                    Image(systemName: "textformat.abc")
                    Text("Rename")
                }
            }
            Divider()
            if let id = adGroup.id {
                Button() {
                    #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString("\(id)", forType: .string)
                    #else
                    UIPasteboard.general.string = "\(id)"
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Group Id")
                }
            }
        }
        .sheet(isPresented: $showUpdateMaxCPT) {
            let money = adGroup.defaultBidAmount
            NavigationStack {
                MoneyView(money: money, title: "Edit Default Max CPT Bid") { amount, isOn in
                    Task {
                        guard let updated = await update(
                            update: AdGroupUpdate(
                                cpaGoal: adGroup.cpaGoal, // must always include this if we not changing it
                                defaultBidAmount: Money(
                                    amount: amount,
                                    currency: money.currency
                                )
                            )
                        ) else { return }
                        self.adGroup = updated
                    }
                }
            }
        }
        .sheet(isPresented: $showUpdateCPAGoal) {
            #warning("we assume we always have defaultBidAmount")
            let money = adGroup.cpaGoal ?? Money(amount: "0.0", currency: adGroup.defaultBidAmount.currency)
            NavigationStack {
                MoneyView(money: money, title: "Edit CPA Goal", optional: true) { amount, isOn in
                    Task {
                        guard let updated = await update(
                            update: AdGroupUpdate(
                                cpaGoal: isOn ? Money(
                                    amount: amount,
                                    currency: money.currency
                                ) : nil
                            )
                        ) else { return }
                        self.adGroup = updated
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .searchMatch:
                return Alert(
                    title: Text(adGroup.name),
                    message: adGroup.automatedKeywordsOptIn ? Text("Are you sure you want to turn off Search Match?") : Text("Are you sure you want to turn on Search Match?"),
                    primaryButton: .cancel({
                        showAlert = false
                    }),
                    secondaryButton: .destructive(adGroup.automatedKeywordsOptIn ? Text("Turn Off") : Text("Turn On"), action: {
                        Task {
                            guard let updated = await update(
                                update: AdGroupUpdate(
                                    automatedKeywordsOptIn: adGroup.automatedKeywordsOptIn ? false : true,
                                    cpaGoal: adGroup.cpaGoal // must always include this if we not changing it
                                )
                            ) else { return }
                            self.adGroup = updated
                        }
                    }))
            case .remove:
                return Alert(
                    title: Text(adGroup.name),
                    message: Text("Are you sure you want to remove this ad group?"),
                    primaryButton: .cancel({
                        showAlert = false
                    }),
                    secondaryButton: .destructive(Text("Remove"), action: {
                        Task {
                            do {
                                try await SearchAds.instance.deleteAdGroup(adGroup: adGroup)
                                onRemove(adGroup)
                            } catch let error {
                                debugPrint(" DELETE error: \(error)")
                            }
                        }
                    }))
            case .none:
                return Alert(title: Text(""))
            }
        }
        .alert("Raname", isPresented: $showRanameAlert) {
            TextField("Enter new name", text: $name)
            Button("OK") {
                Task {
                    guard let updated = await update(update: AdGroupUpdate(
                        cpaGoal: adGroup.cpaGoal,
                        name: name
                    )) else { return }
                    self.adGroup = updated
                }
            }
            Button("Cancel") {
                showAlert = false
            }
        } message: {
            Text("Rename \(adGroup.name)")
        }
        .onAppear {
            viewModel.$adGroupReport
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { report in
                    totals = report?.row.filter({ $0.metadata.adGroupId == adGroup.id }).first?.total
                }
                .store(in: &cancallable)
        }
    }
}

extension AdGroupListItem {
    func update(update: AdGroupUpdate) async -> AdGroup? {
        do {
            if let updated = try await SearchAds.instance.updateAdGroup(
                adGroup: adGroup,
                update: update
            ) {
                viewModel.adGroups?.replace([adGroup], with: [updated])
                return updated
            }
            return nil
        } catch let error {
            debugPrint(" UPDATE error: \(error)")
            return nil
        }
    }
}
