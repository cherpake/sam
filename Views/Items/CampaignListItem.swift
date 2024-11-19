//
//  CampaignListItem.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/03/2023.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

#warning("Modernize alerts")
#warning("Duplication")
struct CampaignListItem: View {
    @EnvironmentObject var viewModel: ViewModel
    @State var cancallable = [AnyCancellable]()
    @State var totals: SpendRow?
    
    var campaign: Campaign
    @State private var showUpdateDailyBudget: Bool = false
    @State private var showUpdateCountries: Bool = false
    @State private var showRemoveAlert: Bool = false
    @State private var showRanameAlert: Bool = false
    @State private var name: String = "" // it's here for renaming
    
    var onUpdate: (CampaignUpdate) -> Void
    var onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(campaign.name)
                    .bold()
                if let dailyBudgetAmount = campaign.dailyBudgetAmount {
                    Text("Budget: \(Float(dailyBudgetAmount.amount)!.formatted(.currency(code: dailyBudgetAmount.currency)))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: true, vertical: true)
                }
            }
            Spacer()
            Group {
                if let totals {
                    TotalsView(title: campaign.name, totals: totals, mode: .comapct)
                        .fixedSize(horizontal: true, vertical: true)
                } else {
                    LoadingView()
                        .fixedSize(horizontal: true, vertical: true)
                        .padding()
                }
            }
            StatusView(campaign: campaign.status)
        }
        .contextMenu {
            Button() {
                onUpdate(CampaignUpdate(status: .enabled))
            } label: {
                Image(systemName: "play.fill")
                Text("Activate")
            }
            Button() {
                onUpdate(CampaignUpdate(status: .paused))
            } label: {
                Image(systemName: "pause.fill")
                Text("Pause")
            }
            Divider()
            Button(role: .destructive) {
                self.showRemoveAlert = true
            } label: {
                Image(systemName: "trash")
                Text("Remove")
            }
            Divider()
            Button() {
                self.showUpdateDailyBudget = true
            } label: {
                Image(systemName: "dollarsign.circle")
                Text("Edit Daily Budget")
            }
            Button() {
                self.showUpdateCountries = true
            } label: {
                Image(systemName: "globe")
                Text("Edit Countries")
            }
            Divider()
            Button() {
                self.name = campaign.name
                self.showRanameAlert = true
            } label: {
                Image(systemName: "textformat.abc")
                Text("Rename")
            }
            Divider()
            Button() {
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([.string], owner: nil)
                pasteboard.setString("\(campaign.id)", forType: .string)
                #else
                UIPasteboard.general.string = "\(campaign.id)"
                #endif
            } label: {
                Image(systemName: "doc.on.doc")
                Text("Copy Campaign Id")
            }
        }
        .sheet(isPresented: $showUpdateDailyBudget) {
            if let dailyBudgetAmount = campaign.dailyBudgetAmount {
                NavigationStack {
                    MoneyView(money: dailyBudgetAmount, title: "Edit Daily Budget") { amount, isOn in
                        onUpdate(CampaignUpdate(dailyBudgetAmount: Money(amount: amount, currency: dailyBudgetAmount.currency)))
                    }
                }
            }
        }
        .sheet(isPresented: $showUpdateCountries) {
            NavigationStack {
                CountriesView(countryCodes: campaign.countriesOrRegions) { countries in
                    onUpdate(CampaignUpdate(countriesOrRegions: countries))
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showRemoveAlert) {
            Alert(title: Text(campaign.name),
                  message: Text("Are you sure you want to remove this campaign?"),
                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Remove"), action: {
                onRemove()
            }))
        }
        .alert("Raname", isPresented: $showRanameAlert) {
            TextField("Enter new name", text: $name)
            Button("OK") {
                onUpdate(CampaignUpdate(name: name))
            }
            Button("Cancel") {
                showRanameAlert = false
            }
        } message: {
            Text("Rename \(campaign.name)")
        }
        .onAppear {
            viewModel.$report
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { report in
                    totals = report?.row.filter({ $0.metadata.campaignId == campaign.id }).first?.total
                }
                .store(in: &cancallable)
        }
    }
}
