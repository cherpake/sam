//
//  AdGroupsView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 02/11/2024.
//
import SwiftUI

struct AdGroupsViewItem: Identifiable, Equatable, Hashable {
    var id: String
    var campaignId: Int64
    var name: String
    var installs: Int
    var spend: Float
    var bid: Float
    var currency: String
    var status: Status
    var campaignStatus: Status?
}

struct AdGroupsView: View {
    @EnvironmentObject var viewModel: MainAppModel
        
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
    private let isCompact = false
    #endif
    
    @State private var filter: StatusFilter = UserDefaults.standard.groupFilter
    @State private var filterByName: String = ""
    @State private var sortOrder = [KeyPathComparator(\AdGroupsViewItem.spend, order: .reverse)]
    
    enum AdGroupModal: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case updateByName
        case createSKAG
    }
    
    @State private var modalView: AdGroupModal? = nil
    
    private func filter(row: AdGroupsViewItem) -> Bool {
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
    
    @State private var adGroups = [AdGroupsViewItem]()
    
    func loadAdGroups() {
        adGroups = viewModel.adGroupViewItems()
        adGroups.sort(using: sortOrder)
    }
    
    @ViewBuilder
    func headerView() -> some View {
        HStack {
            Menu {
                Button {
                    modalView = .updateByName
                } label: {
                    Text("Update by Name")
                }
                Button {
                    modalView = .createSKAG
                } label: {
                    Text("Create SKAG")
                }
            } label: {
                Image(systemName: "line.3.horizontal.circle.fill")
            }
            .fixedSize()
            
            Spacer()
            
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
            
            Table(adGroups.filter(filter(row:)) as [AdGroupsViewItem], selection: $viewModel.adGroupSelection, sortOrder: $sortOrder) {
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
                                    Text("Bid:")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text(row.bid.formatted(.currency(code: row.currency)))
                                        .monospaced()
                                }
                                Spacer()
                                StatusView(campaign: row.campaignStatus, adGroup: row.status)
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
                TableColumn("Default Bid", value: \.bid) { row in
                    Text(row.bid.formatted(.currency(code: row.currency)))
                        .monospaced()
                }
                TableColumn("Status", value: \.status.rawValue) { row in
                    StatusView(campaign: row.campaignStatus, adGroup: row.status)
                }
            }
            .refreshable(action: {
                do {
                    try await viewModel.updateAdGroupsReport()
                } catch {
                    
                }
            })
            .contextMenu(forSelectionType: CampaignViewItem.ID.self, menu: { selected in
                Button() {
                    let adGroups = self.adGroups.filter({ selected.contains($0.id) })
                    Task {
                        try await viewModel.changeAdGroups(adGroups: adGroups, update: AdGroupUpdate(status: .enabled))
                    }
                } label: {
                    Image(systemName: "play.fill")
                    Text("Activate")
                }
                Button() {
                    let adGroups = self.adGroups.filter({ selected.contains($0.id) })
                    Task {
                        try await viewModel.changeAdGroups(adGroups: adGroups, update: AdGroupUpdate(status: .paused))
                    }
                } label: {
                    Image(systemName: "pause.fill")
                    Text("Pause")
                }
                Divider()
                Button() {
                    Task {
                        let adGroups = self.adGroups.filter({ selected.contains($0.id) })
                        try await viewModel.delete(adGroups: adGroups)
                    }
                } label: {
                    Image(systemName: "trash")
                    Text("Delete")
                }
            })
            .onChange(of: sortOrder) {
                adGroups.sort(using: sortOrder)
            }
            .onChange(of: filter) {
                UserDefaults.standard.groupFilter = filter
            }
            .onChange(of: viewModel.adGroupSelection) {
                guard let selected = viewModel.adGroupSelection.first else { return }
                if let gid = Int64(selected) {
                    viewModel.selectedAdGroupId = gid
                }
                #if os(iOS)
                viewModel.path.append("keywords")
                #endif
            }
            
            if let total = viewModel.adGroupsReport?.grandTotals?.total {
                GrandTotalView(totals: total, count: adGroups.filter(filter(row:)).count, type: "Ad Groups")
            }
        }
        .sheet(item: $modalView, content: { modal in
            switch modal {
            case .updateByName:
                NavigationStack {
                    UpdateAdGroupByNameView(adGroups: $adGroups)
                }
                .presentationDetents([.medium, .large])
            case .createSKAG:
                NavigationStack {
                    SKAGView()
                        .environmentObject(viewModel)
                }
                .presentationDetents([.medium, .large])
            }
        })
        .onAppear {
            loadAdGroups()
            #if os(iOS)
            viewModel.adGroupSelection = Set<AdGroupsViewItem.ID>()
            #endif
        }
        .onChange(of: viewModel.adGroupsReportUpdate) {
            loadAdGroups()
        }
        .onChange(of: filterByName) {
            applyFilter()
        }
        .onChange(of: filter) {
            applyFilter()
        }
    }
    
    private func applyFilter() {
        if filterByName.count > 0 || filter != .all {
            viewModel.adGroupsFilter = adGroups.filter(filter(row:)).compactMap({ $0.id })
        } else {
            viewModel.adGroupsFilter = [String]()
        }
    }
}
