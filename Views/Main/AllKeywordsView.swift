//
//  KeywordsView.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI
import Combine

struct AllKeywordsView: View {
    var campaign: Campaign
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State var cancallables = [AnyCancellable]()
    
    @State private var showUpdateMaxCPT: Bool = false
    @State private var showRemoveAlert: Bool = false
    @State private var showSorting: Bool = false
    @State private var keywordsToRemove: [Keyword]? = nil
    
    @State var filter: String = ""
    let filterPublisher = PassthroughSubject<String, Never>()
    
    @State var statusFilter: StatusFilter = UserDefaults.standard.keywordFilter
    @State var sorting: SortValue = UserDefaults.standard.keywordSorting
    @State var order: SortOrder = UserDefaults.standard.keywordOrdering
    @State var totals: SpendRow? = nil
    
    func fetch() {
        Task {
            viewModel.adGroups = try await SearchAds.instance.getAdGroups(campaign: campaign)
            viewModel.keywords = try await SearchAds.instance.getKeywords(campaign: campaign)
        }
    }
    
    func fetchTotals() {
        Task {
            guard let _ = viewModel.keywords else { return }
            
            var conditions = [Condition]()
            if let filteredKeywords = viewModel.keywords?.filter(keywordsFilter(_:)) {
                if viewModel.keywords?.count != filteredKeywords.count {
                    conditions.append(Condition(field: Fields.keywordId, op: .inRange, values: filteredKeywords
                        .compactMap({ $0.id })
                        .compactMap({ "\($0)" }))
                    )
                }
            }
            
            guard let report = try await SearchAds.instance.getKeywordsReport(
                campaign: campaign,
                report: ReportingRequest(
                    startTime: .init(date: viewModel.dateRange.startDate()),
                    endTime: .init(date: viewModel.dateRange.endDate()),
                    selector: ReportSelector(
                        conditions: conditions,
                        orderBy: [
                            .init(field: .adGroupId, sortOrder: .ascending)
                        ],
                        pagination: Pagination(offset: 0, limit: 1000)),
                    returnGrandTotals: true,
                    returnRowTotals: true,
                    timeZone: .ortz)) else { return }
            viewModel.keywordsReport = report.reportingDataResponse
            if conditions.count > 0 {
                totals = report.reportingDataResponse.grandTotals?.total
            } else {
                totals = viewModel.report?.row.filter({ $0.metadata.campaignId == campaign.id }).first?.total
            }
        }
    }
    
    private func keywordsFilter(_ k: Keyword) -> Bool {
        var result: Bool = true
        
        // Filter out deleted keywords
        if k.deleted == true {
            return false
        }
        
        if filter.count > 0 {
            let text = k.text.lowercased()
            let filter = filter.lowercased()
            
            if filter.hasPrefix("[") {
                result = k.matchType == .exact && "[\(text)]".hasPrefix(filter)
            } else if filter.hasSuffix("]") {
                result = k.matchType == .exact && "[\(text)]".hasSuffix(filter)
            } else {
                result = text.contains(filter)
            }
        }
        if result {
            switch statusFilter {
            case .all:
                break; // no need to do anything
            case .enabled:
                result = k.status == .active && viewModel.adGroups?.filter({ $0.id == k.adGroupId }).first?.status == .enabled
            case .disabled:
                result = k.status == .paused || viewModel.adGroups?.filter({ $0.id == k.adGroupId }).first?.status != .enabled
            }
        }
        return result
    }
    
    var body: some View {
        Group {
            if let keywords = viewModel.keywords {
                // Filters
                HStack {
                    #if os(iOS)
                    DatesRangeView(dateRange: $viewModel.dateRange)
                    Spacer()
                    #endif
                    
                    Menu() {
                        Button {
                            viewModel.selectedKeywordIds = Set(keywords
                                .filter(keywordsFilter(_:))
                                .compactMap({ $0.id })
                            )
                        } label: {
                            Image(systemName: "checkmark.square.fill")
                            Text("Select All")
                        }
                        Button {
                            viewModel.selectedKeywordIds = nil
                        } label: {
                            Image(systemName: "square")
                            Text("Deselect All")
                        }
                        Divider()
                        Button() {
                            changeStatus(status: .active)
                        } label: {
                            Image(systemName: "play.fill")
                            Text("Activate")
                        }
                        .disabled(viewModel.selectedKeywordIds?.count ?? 0 == 0)
                        Button() {
                            changeStatus(status: .paused)
                        } label: {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .disabled(viewModel.selectedKeywordIds?.count ?? 0 == 0)
                        Divider()
                        Button(role: .destructive) {
                            if let selected = viewModel.selectedKeywordIds, selected.count > 0 {
                                guard let keywords = viewModel.keywords?.filter({
                                    if let id = $0.id {
                                        return selected.contains(id)
                                    } else {
                                        return false
                                    }
                                }) else { return }
                                
                                keywordsToRemove = keywords
                                showRemoveAlert = true
                            }
                        } label: {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .disabled(viewModel.selectedKeywordIds?.count ?? 0 == 0)
                        Divider()
                        Button() {
                            showUpdateMaxCPT = true
                        } label: {
                            Image(systemName: "dollarsign.circle")
                            Text("Edit Max CPT Bid")
                        }
                        .disabled(viewModel.selectedKeywordIds?.count ?? 0 == 0)
                        Divider()
                        Button() {
                            var value: String = ""
                            if let selected = viewModel.selectedKeywordIds, selected.count > 0 {
                                if let filtered = viewModel.keywords?
                                    .filter({
                                        guard let id = $0.id else { return false }
                                        return selected.contains(id)
                                    }) {
                                    value = filtered.compactMap({ $0.text }).joined(separator: "\n")
                                }
                            } else {
                                if let v = viewModel.keywords?.compactMap({ $0.text }).joined(separator: "\n") {
                                    value = v
                                }
                            }
                            
                            guard value != "" else { return }
                            
                            #if os(macOS)
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([.string], owner: nil)
                            pasteboard.setString(value, forType: .string)
                            #else
                            UIPasteboard.general.string = value
                            #endif
                        } label: {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Keyword(s)")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                        Text("Actions")
                    }
                    .fixedSize(horizontal: true, vertical: true)
                    
                    Spacer()
                    FilterSortView(statusFilter: $statusFilter) {
                        showSorting = true
                    }
                    .onChange(of: statusFilter) { newValue in
                        UserDefaults.standard.keywordFilter = newValue
                        fetchTotals()
                    }
                }
                #if os(iOS)
                    .padding([.leading, .trailing])
                    #else
                    .padding()
                    #endif
                
                HStack {
                    // Search
                    ZStack {
                        TextField("Search", text: $filter)
                            .submitLabel(.done)
                            .onChange(of: filter, perform: { value in
                                filterPublisher.send(value)
                            })
                            .onReceive(filterPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main), perform: { _ in
                                fetchTotals()
                            })
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .padding(.trailing, 3.0)
                                .disabled(filter.count == 0)
                                .foregroundColor(filter.count == 0 ? Color.secondary.opacity(0.5) : Color.secondary)
                                .onTapGesture {
                                    filter = ""
                                }
                        }
                    }
                    Button {
                        fetch()
                    } label: {
                        Image(systemName: "gobackward")
                    }
                    .keyboardShortcut("r")
                }
                #if os(iOS)
                    .padding([.leading, .trailing])
                    #else
                    .padding()
                    #endif
                
                VStack {
                    List(keywords
                        .filter(keywordsFilter(_:))
                        .sorted(by: { a, b in
                            guard let at = viewModel.keywordsReport?.row.first(where: { $0.metadata.keywordId == a.id })?.total else { return false }
                            guard let bt = viewModel.keywordsReport?.row.first(where: { $0.metadata.keywordId == b.id })?.total else { return false }
                            return SortValue.sort(ac: a, a: at, bc: b, b: bt, order: order, value: sorting)
                        }), id: \.self) { keyword in
                            KeywordListItem(keyword: keyword, onDelete: { keyword in
                                keywordsToRemove = [keyword]
                                showRemoveAlert = true
                            }, onUpdate: { update in
                                Task {
                                    try await self.update(keywords: [keyword], updates: [KeywordUpdateObject(keyword: keyword, update: update)])
                                }
                            })
                            .environmentObject(viewModel)
                        }
                        .refreshable {
                            fetch()
                        }
                
                    if let totals {
                        TotalsView(title: "Grand Totals", totals: totals)
                    } else {
                        LoadingView()
                    }
                    
                    if let keywords = viewModel.keywords {
                        Divider()
                        HStack {
                            Spacer()
                            Text("\(keywords.filter(keywordsFilter(_:)).count) keywords")
                                .font(.footnote)
                                .padding(.bottom, 4.0)
                            Spacer()
                        }
                    }
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle(campaign.name)
        .listStyle(.plain)
        .alert(isPresented: $showRemoveAlert) {
            Alert(
                title: Text("Remove"),
                message: Text("Are you sure you want to remove selected keywords?"),
                primaryButton: .cancel({
                    showRemoveAlert = false
                }),
                secondaryButton: .destructive(Text("Remove"), action: {
                    if let keywordsToRemove {
                        delete(keywords: keywordsToRemove)
                    }
                }))
        }
        .sheet(isPresented: $showUpdateMaxCPT) {
            if let bid = viewModel.keywords?.first?.bidAmount {
                NavigationStack {
                    MoneyView(money: Money(amount: bid.amount, currency: bid.currency), title: "Edit Max CPT Bid") { amount, isOn in
                        guard let ids = viewModel.selectedKeywordIds else { return }
                        guard let keywords = viewModel.keywords?.filter({
                            if let id = $0.id {
                                return ids.contains(id)
                            } else {
                                return false
                            }
                        }) else { return }
                        let updates = keywords.compactMap({ KeywordUpdateObject(keyword: $0, update: KeywordUpdate(id: $0.id!, bidAmount: Money(amount: amount, currency: bid.currency))) })
                        
                        Task {
                            do {
                                let _ = try await update(keywords: keywords, updates: updates)
                            } catch let error {
                                debugPrint(" ERROR: \(error)")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSorting) {
            SortingView(selection: $sorting, order: $order)
                .onChange(of: sorting) { newValue in
                    UserDefaults.standard.keywordSorting = newValue
                }
                .onChange(of: order) { newValue in
                    UserDefaults.standard.keywordOrdering = newValue
                }
        }
        .onAppear {
            fetch()
            
            // Data range change
            viewModel.$dateRange
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { dateRange in
                    fetchTotals()
                }
                .store(in: &cancallables)
            
            viewModel.$keywords
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { dateRange in
                    fetchTotals()
                }
                .store(in: &cancallables)
        }
        .onDisappear {
            viewModel.selectedKeywordIds = nil
        }
    }
}

extension AllKeywordsView {
    func update(keywords: [Keyword], updates: [KeywordUpdateObject]) async throws -> [Keyword]? {
        let adGroupIds = keywords.compactMap({ $0.adGroupId })
        
        guard let adGroups = viewModel.adGroups?.filter({
            if let id = $0.id, adGroupIds.contains(id) {
                return true
            } else {
                return false
            }
        }) else { return nil }
        
        guard let result = try await SearchAds.instance.updateKeywords(
            orgId: viewModel.orgId,
            adGroups: adGroups,
            updates: updates
        ) else { return nil }
        for keyword in result {
            viewModel.keywords?.replace(keywords.filter({ $0.id == keyword.id }), with: [keyword])
        }
        
        return result
    }
    
    func changeStatus(status: Status) {
        guard let ids = viewModel.selectedKeywordIds else { return }
        guard let keywords = viewModel.keywords?.filter({
            if let id = $0.id {
                return ids.contains(id)
            } else {
                return false
            }
        }) else { return }
        
        let updates = keywords.compactMap({ KeywordUpdateObject(keyword: $0, update: KeywordUpdate(id: $0.id!, status: status)) })
        
        Task {
            do {
                let _ = try await update(keywords: keywords, updates: updates)
            } catch let error {
                debugPrint(" ERROR: \(error)")
            }
        }
    }
    
    func delete(keywords: [Keyword]) {
        Task {
            do {
                guard let adGroups = viewModel.adGroups else { return }                
                let _ = try await SearchAds.instance.deleteKeywords(
                    adGroups: adGroups,
                    keywords: keywords
                )
                DispatchQueue.main.async {
                    viewModel.keywords?.removeAll(where: { keywords.contains($0) })
                }
            } catch let error {
                debugPrint(" DELETE error \(error)")
            }
        }
    }
}
