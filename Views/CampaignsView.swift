//
//  CampaignsVie3w.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 02/11/2024.
//

import SwiftUI

struct CampaignViewItem: Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var installs: Int
    var spend: Float
    var budget: Float
    var currency: String
    var status: Status
    var countriesOrRegions: [String]
}

struct CampaignsView: View {
    @EnvironmentObject var viewModel: MainAppModel
        
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
    private let isCompact = false
    #endif
    
    @State private var filter: StatusFilter = UserDefaults.standard.campaignFilter
    @State private var filterByName: String = ""
    @State private var sortOrder = [KeyPathComparator(\CampaignViewItem.spend, order: .reverse)]
    
    enum CampaignsModal: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case countries
    }
    
    @State private var modalView: CampaignsModal? = nil
    
    private func filter(row: CampaignViewItem) -> Bool {
        var status: Bool = true
        
        switch filter {
        case .all:
            status = true
        case .enabled:
            status = row.status != .paused
        case .disabled:
            status = row.status == .paused
        }
        
        if filterByName.count > 0 {
            status = status && row.name.lowercased().contains(filterByName.lowercased())
        }
        
        return status
    }
    
    @State private var campaigns = [CampaignViewItem]()
    
    func loadCampaigns() {
        campaigns = viewModel
            .campaingsReport?
            .row
            .compactMap { row in
                if
                    let id = row.metadata.campaignId,
                    let name = row.metadata.campaignName,
                    let spend = Float(row.total.localSpend.amount),
                    let budget = Float(row.metadata.dailyBudget?.amount ?? "0"),
                    let status = row.metadata.campaignStatus,
                    let countriesOrRegions = row.metadata.countriesOrRegions
                {
                    return CampaignViewItem(
                        id: "\(id)",
                        name: name,
                        installs: row.total.totalInstalls,
                        spend: spend,
                        budget: budget,
                        currency: row.total.localSpend.currency,
                        status: status,
                        countriesOrRegions: countriesOrRegions
                    )
                } else {
                    return nil
                }
            } ?? []
        campaigns.sort(using: sortOrder)
    }
    
    @ViewBuilder
    func headerView() -> some View {
        HStack {
            TextField("Filter", text: $filterByName)
                .clearButton(text: $filterByName)
            
            Spacer()
            
            Picker("", selection: $filter) {
                Text("All")
                    .tag(StatusFilter.all)
                Text("Running")
                    .tag(StatusFilter.enabled)
                Text("Paused")
                    .tag(StatusFilter.disabled)
            }
            .pickerStyle(.menu)
            .fixedSize()
            
            Spacer()
            
            Button {
                viewModel.updateReports()
            } label: {
                Image(systemName: "arrow.trianglehead.clockwise")
            }
        }
        .padding([.top, .leading, .trailing])
    }
    
    var body: some View {
        VStack {
            headerView()
            
            Table(campaigns.filter(filter(row:)) as [CampaignViewItem], selection: $viewModel.campaignSelection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { row in
                    VStack(alignment: .leading) {
                        Text(row.name)
                        HStack {
                            if isCompact {
                                VStack {
                                    Text("Spend:")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text(row.spend.formatted(.currency(code: row.currency)))
                                        .monospaced()
                                }
                                HDivider()
                                VStack {
                                    Text("Installs:")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text("\(row.installs)")
                                        .monospaced()
                                }
                                HDivider()
                                VStack {
                                    Text("Budget:")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text(row.budget.formatted(.currency(code: row.currency)))
                                        .monospaced()
                                }
                                Spacer()
                                StatusView(campaign: row.status)
                            }
                        }
                    }
                }
                TableColumn("Installs", value: \.installs) { row in
                    Text("\(row.installs)")
                        .monospaced()
                }
                TableColumn("Spend", value: \.spend) { row in
                    Text(row.spend.formatted(.currency(code: row.currency)))
                        .monospaced()
                }
                TableColumn("Budget", value: \.budget) { row in
                    Text(row.budget.formatted(.currency(code: row.currency)))
                        .monospaced()
                }
                TableColumn("Status", value: \.status.rawValue) { row in
                    StatusView(campaign: row.status)
                }
            }
            .refreshable(action: {
                do {
                    try await viewModel.updateCampaingsReport()
                } catch {
                    
                }
            })
            .contextMenu(forSelectionType: CampaignViewItem.ID.self, menu: { selected in
                Button() {
                    Task {
                        guard let campaign = self.campaigns.first(where: { selected.contains($0.id) }) else { return }
                        try await viewModel.changeCampaign(
                            campaign: campaign,
                            update: UpdateCampaignRequest(campaign: CampaignUpdate(status: .enabled),
                                                          clearGeoTargetingOnCountryOrRegionChange: false))
                    }
                } label: {
                    Image(systemName: "play.fill")
                    Text("Activate")
                }
                Button() {
                    Task {
                        guard let campaign = self.campaigns.first(where: { selected.contains($0.id) }) else { return }
                        try await viewModel.changeCampaign(
                            campaign: campaign,
                            update: UpdateCampaignRequest(campaign: CampaignUpdate(status: .paused),
                                                          clearGeoTargetingOnCountryOrRegionChange: false))
                    }
                } label: {
                    Image(systemName: "pause.fill")
                    Text("Pause")
                }
                Divider()
                Button() {
                    self.viewModel.campaignSelection = selected.first
                    self.modalView = .countries
                } label: {
                    Image(systemName: "globe")
                    Text("Countries")
                }
                Divider()
                Button() {
                    guard let id = selected.first else { return }
                    #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(id, forType: .string)
                    #else
                    UIPasteboard.general.string = id
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Campaign Id")
                }
            }, primaryAction: nil)
            .onChange(of: sortOrder) {
                campaigns.sort(using: sortOrder)
            }
            .onChange(of: filter) {
                UserDefaults.standard.campaignFilter = filter
            }
            .onChange(of: viewModel.campaignSelection) {
                guard let selected = viewModel.campaignSelection else { return }
                if let cid = Int64(selected) {
                    viewModel.selectedCampaignId = cid
                }
                #if os(iOS)
                viewModel.path.append("adgroups")
                #endif
            }
            
            if let total = viewModel.campaingsReport?.grandTotals?.total {
                GrandTotalView(totals: total, count: campaigns.filter(filter(row:)).count, type: "Campaigns")
            }
        }
        .sheet(item: $modalView, content: { modal in
            if let campaign = self.campaigns.first(where: { $0.id == viewModel.campaignSelection }) {
                switch modal {
                case .countries:
                    NavigationStack {
                        CountriesView(countryCodes: campaign.countriesOrRegions, update: { updated in
                            Task {
                                try await viewModel.changeCampaign(
                                    campaign: campaign,
                                    update: UpdateCampaignRequest(campaign: CampaignUpdate(countriesOrRegions: updated),
                                                                  clearGeoTargetingOnCountryOrRegionChange: false))
                            }
                        })
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        })
        .onAppear {
            loadCampaigns()
            #if os(iOS)
            viewModel.campaignSelection = nil
            viewModel.path = NavigationPath()
            #endif
        }
        .onChange(of: viewModel.campaingsReportUpdated) {
            loadCampaigns()
        }
    }
}
