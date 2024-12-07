//
//  KeywordsView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 02/11/2024.
//
import SwiftUI

struct KeywordsViewItem: Identifiable, Equatable, Hashable {
    var id: String
    var campaignId: Int64
    var adGroupId: Int64
    var name: String
    var exact: Bool
    var installs: Int
    var spend: Float
    var bid: Float
    var cpt: Float
    var currency: String
    var status: Status
    var campaignStatus: Status?
    var adGroupStatus: Status?
    var combinedStatus: String
}

struct KeywordsView: View {
    @EnvironmentObject var viewModel: MainAppModel
    
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
#else
    private let isCompact = false
#endif
    
    @State private var filter: StatusFilter = UserDefaults.standard.keywordFilter
    @State private var filterByName: String = ""
    @State private var sortOrder = [KeyPathComparator(\KeywordsViewItem.spend, order: .reverse)]
    
    enum KeywordsModal: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case updateBid
    }
    
    @State private var modalView: KeywordsModal? = nil
    
    private func filter(row: KeywordsViewItem) -> Bool {
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
    
    @State private var keywords = [KeywordsViewItem]()
    
    func loadKeywords() {
        keywords = viewModel
            .keywordsReport?
            .row
            .compactMap { row in
                if
                    let id = row.metadata.keywordId,
                    let campaignId = row.metadata.campaignId,
                    let adGroupId = row.metadata.adGroupId,
                    let name = row.metadata.keyword,
                    let spend = Float(row.total.localSpend.amount),
                    let bid = Float(row.metadata.bidAmount?.amount ?? "0.00"),
                    let cpt = Float(row.total.avgCPT.amount),
                    let status = row.metadata.keywordStatus // Need also campaign status!
                {
                    let cs = viewModel.campaingsReport?.row.first(where: { $0.metadata.campaignId == row.metadata.campaignId })?.metadata.campaignStatus
                    let ags = viewModel.adGroupsReport?.row.first(where: { $0.metadata.adGroupId == row.metadata.adGroupId })?.metadata.adGroupStatus
                    return KeywordsViewItem(
                        id: "\(id)",
                        campaignId: campaignId,
                        adGroupId: adGroupId,
                        name: name,
                        exact: row.metadata.matchType == .exact,
                        installs: row.total.totalInstalls,
                        spend: spend,
                        bid: bid,
                        cpt: cpt,
                        currency: row.total.localSpend.currency,
                        status: status,
                        campaignStatus: cs,
                        adGroupStatus: ags,
                        combinedStatus: "\(cs?.rawValue ?? "unknown"):\(ags?.rawValue ?? "unknown"):\(status.rawValue)"
                    )
                } else {
                    return nil
                }
            } ?? []
        keywords.sort(using: sortOrder)
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
            
            Table(keywords.filter(filter(row:)) as [KeywordsViewItem], selection: $viewModel.keywordSelection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { row in
                    VStack(alignment: .leading) {
                        if row.exact {
                            Text("[\(row.name)]")
                        } else {
                            Text(row.name)
                        }
                        
                        if isCompact {
                            HStack {
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
                                    Text("Spend:")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text(row.spend.formatted(.currency(code: row.currency)))
                                        .monospaced()
                                }
                                
                                HDivider()
                                VStack {
                                    Text("Avg. CPT:")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text(row.cpt.formatted(.currency(code: row.currency)))
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
                                StatusView(campaign: row.campaignStatus, adGroup: row.adGroupStatus, keyword: row.status)
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
                TableColumn("Avg. CPT", value: \.cpt) { row in
                    Text(row.cpt.formatted(.currency(code: row.currency)))
                        .monospaced()
                }
                TableColumn("Bid", value: \.bid) { row in
                    Text(row.bid.formatted(.currency(code: row.currency)))
                        .monospaced()
                }
                TableColumn("Status", value: \.combinedStatus) { row in
                    StatusView(campaign: row.campaignStatus, adGroup: row.adGroupStatus, keyword: row.status)
                }
            }
            .refreshable(action: {
                do {
                    try await viewModel.updateKeywordsReport()
                } catch {
                    
                }
            })
            .contextMenu(forSelectionType: KeywordsViewItem.ID.self, menu: { selected in
                VStack {
                    Button() {
                        let keywords = self.keywords.filter({ selected.contains($0.id) })
                        Task {
                            try await viewModel.changeKeywordStatus(keywords: keywords, status: .active)
                        }
                    } label: {
                        Image(systemName: "play.fill")
                        Text("Activate")
                    }
                    Button() {
                        let keywords = self.keywords.filter({ selected.contains($0.id) })
                        Task {
                            try await viewModel.changeKeywordStatus(keywords: keywords, status: .paused)
                        }
                    } label: {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    Divider()
                }
                VStack {
                    Button() {
                        let keywords: [String] = self.keywords
                            .filter({ selected.contains($0.id) })
                            .compactMap({ "\($0.adGroupId)" })
                        
                        let adGroups: [AdGroupsViewItem] = viewModel
                            .adGroupViewItems()
                            .filter({ keywords.contains($0.id) })
                        
                        Task {
                            try await viewModel.changeAdGroups(adGroups: adGroups, update: AdGroupUpdate(status: .enabled))
                        }
                    } label: {
                        Image(systemName: "play.fill")
                        Text("Activate Parent AdGroup")
                    }
                    Button() {
                        let keywords: [String] = self.keywords
                            .filter({ selected.contains($0.id) })
                            .compactMap({ "\($0.adGroupId)" })
                        
                        let adGroups: [AdGroupsViewItem] = viewModel
                            .adGroupViewItems()
                            .filter({ keywords.contains($0.id) })
                        
                        Task {
                            try await viewModel.changeAdGroups(adGroups: adGroups, update: AdGroupUpdate(status: .paused))
                        }
                    } label: {
                        Image(systemName: "pause.fill")
                        Text("Pause Parent AdGroup")
                    }
                    Divider()
                }
                VStack {
                    Button() {
                        modalView = .updateBid
                    } label: {
                        Image(systemName: "dollarsign.circle")
                        Text("Edit Max CPT Bid")
                    }
                    Divider()
                }
                VStack {
                    Button() {
                        let ids = Array(selected).joined(separator: "\n")
#if os(macOS)
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        pasteboard.setString(ids, forType: .string)
#else
                        UIPasteboard.general.string = ids
#endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Keyword Id")
                    }
                    Divider()
                }
                VStack {
                    Button() {
                        // TODO: add warning! + implement
                    } label: {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                }
            }, primaryAction: nil)
            .onChange(of: sortOrder) {
                keywords.sort(using: sortOrder)
            }
            .onChange(of: filter) {
                UserDefaults.standard.groupFilter = filter
            }
            
            if let total = viewModel.keywordsReport?.grandTotals?.total {
                GrandTotalView(totals: total, count: keywords.filter(filter(row:)).count, type: "Keywords")
            }
        }
        .sheet(item: $modalView, content: { modal in
            switch modal {
            case .updateBid:
                NavigationStack {
                    updateView()
                }
                .presentationDetents([.medium, .large])
            }
        })
        .onAppear {
            loadKeywords()
        }
        .onDisappear(perform: {
            
        })
        .onChange(of: viewModel.keywordsReportUpdate) {
            loadKeywords()
        }
        .onChange(of: filterByName) {
            applyFilter()
        }
        .onChange(of: filter) {
            applyFilter()
        }
    }
    
    // Why this a func and not inside the view?
    // Cause otherwise SwiftUI captures the values before they are initiated!
    private func updateView() -> some View {
        MoneyView(money: defaultBid(),
                  title: "Edit Max CPT Bid",
                  update: { amount, isOn in
            await updateBid(amount: amount, isOn: isOn)
        })
    }
    
    private func updateBid(amount: String, isOn: Bool) async -> Void {
        do {
            let keywords = self.keywords.filter({ viewModel.keywordSelection.contains($0.id) })
            let bid = defaultBid()
            try await viewModel.changeKeywordBid(keywords: keywords, bid: Money(amount: amount, currency: bid.currency))
        } catch let error {
            debugPrint(error)
        }
    }
    
    private func defaultBid() -> Money {
        if let amount = keywords.first?.bid {
            return Money(amount: String(amount), currency: "USD")
        } else {
            return Money(amount: "1.00", currency: "USD")
        }
    }
    
    private func applyFilter() {
        if filterByName.count > 0 || filter != .all {
            viewModel.keywordsFilter = keywords.filter(filter(row:)).compactMap({ $0.id })
        } else {
            viewModel.keywordsFilter = [String]()
        }
    }
}
