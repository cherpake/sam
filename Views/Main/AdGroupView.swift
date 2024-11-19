//
//  AdGroupView.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI
import Combine

struct AdGroupView: View {
    var campaign: Campaign
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var showSorting: Bool = false
    @State private var showSKAG: Bool = false
    @State private var showUpdateByName: Bool = false
    
    @State var cancallables = [AnyCancellable]()
    
    @State var filter: String = ""
    let filterPublisher = PassthroughSubject<String, Never>()
    
    @State var statusFilter: StatusFilter = UserDefaults.standard.groupFilter
    @State var sorting: SortValue = UserDefaults.standard.groupSorting
    @State var order: SortOrder = UserDefaults.standard.groupOrdering
    @State var totals: SpendRow? = nil
    
    func fetch() {
        Task {
            viewModel.adGroups = try await SearchAds.instance.getAdGroups(campaign: campaign)
        }
    }
    
    func fetchTotals() {
        Task {
            guard let _ = viewModel.adGroups else { return }
            
            var conditions = [Condition]()
            if let filteredAdGroups = viewModel.adGroups?.filter(adGroupsFilter(_:)) {
                if viewModel.adGroups?.count != filteredAdGroups.count {
                    conditions.append(Condition(field: Fields.adGroupId, op: .inRange, values: filteredAdGroups
                        .compactMap({ $0.id })
                        .compactMap({ "\($0)" }))
                    )
                }
            }
            
            guard let report = try await SearchAds.instance.getAdGroupReport(
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
            viewModel.adGroupReport = report.reportingDataResponse
            if conditions.count > 0 {
                totals = report.reportingDataResponse.grandTotals?.total
            } else {
                totals = viewModel.report?.row.filter({ $0.metadata.campaignId == campaign.id }).first?.total
            }
        }
    }
    
    private func statusFilterLabels(statusFilter: StatusFilter) -> String {
        switch statusFilter {
        case .all:
            return "All"
        case .enabled:
            return "Running"
        case .disabled:
            return "Paused"
        }
    }
    
    private func adGroupsFilter(_ g: AdGroup) -> Bool {
        var result: Bool = true
        if filter.count > 0 {
            result = g.name.lowercased().contains(filter.lowercased())
        }
        if result {
            switch statusFilter {
            case .all:
                break; // no need to do anything
            case .enabled:
                result = g.status == .enabled
            case .disabled:
                result = g.status == .paused
            }
        }
        return result
    }
    
    var body: some View {
        VStack {
            if let adGroups = viewModel.adGroups {
                // Filters
                HStack {
                    #if os(iOS)
                    DatesRangeView(dateRange: $viewModel.dateRange)
                    Spacer()
                    #endif
                    
                    Menu() {
                        Button {
                            viewModel.selectedAdGroupsIds = Set(adGroups
                                .filter(adGroupsFilter(_:))
                                .compactMap({ $0.id })
                            )
                        } label: {
                            Image(systemName: "checkmark.square.fill")
                            Text("Select All")
                        }
                        Button {
                            viewModel.selectedAdGroupsIds = nil
                        } label: {
                            Image(systemName: "square")
                            Text("Deselect All")
                        }
                        Divider()
                        Button() {
                            changeStatus(status: .enabled)
                        } label: {
                            Image(systemName: "play.fill")
                            Text("Activate")
                        }
                        .disabled(viewModel.selectedAdGroupsIds?.count ?? 0 == 0)
                        Button() {
                            changeStatus(status: .paused)
                        } label: {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .disabled(viewModel.selectedAdGroupsIds?.count ?? 0 == 0)
//                        Divider()
//                        Button(role: .destructive) {
//                            if let selected = viewModel.selectedAdGroupsIds, selected.count > 0 {
//                                keywordsToRemove = viewModel.keywords?.filter({
//                                    guard let id = $0.id else { return false }
//                                    return viewModel.selectedKeywordIds?.contains(id) ?? false
//                                })
//                                showRemoveAlert = true
//                            }
//                        } label: {
//                            Image(systemName: "trash")
//                            Text("Remove")
//                        }
//                        .disabled(viewModel.selectedAdGroupsIds?.count ?? 0 == 0)
                        Divider()
                        Button() {
                            showUpdateByName = true
                        } label: {
                            Image(systemName: "pencil")
                            Text("Update by Name")
                        }
                        Button() {
                            showSKAG = true
                        } label: {
                            Image(systemName: "plus.circle")
                            Text("Create SKAG")
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
                        UserDefaults.standard.groupFilter = newValue
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
                
                List(adGroups
                    .filter(adGroupsFilter(_:))
                    .sorted(by: { a, b in
                        guard let at = viewModel.adGroupReport?.row.first(where: { $0.metadata.adGroupId == a.id })?.total else { return false }
                        guard let bt = viewModel.adGroupReport?.row.first(where: { $0.metadata.adGroupId == b.id })?.total else { return false }
                        return SortValue.sort(ac: a, a: at, bc: b, b: bt, order: order, value: sorting)
                    }), id: \.self, selection: $viewModel.selectedAdGroup) { adGroup in
                    NavigationLink(value: adGroup) {
                        AdGroupListItem(adGroup: adGroup) { adGroup in
                            if viewModel.selectedAdGroup == adGroup {
                                viewModel.selectedAdGroup = nil
                            }
                            viewModel.adGroups?.removeAll(where: { $0.id == adGroup.id })
                        }
                        .environmentObject(viewModel)
                    }
                }
                .refreshable {
                    fetch()
                }
                
                if let totals {
                    TotalsView(title: "Grand Totals", totals: totals)
                } else {
                    LoadingView()
                }
                
                if let keywords = viewModel.adGroups {
                    Divider()
                    HStack {
                        Spacer()
                        Text("\(keywords.filter(adGroupsFilter(_:)).count) ad groups")
                            .font(.footnote)
                            .padding(.bottom, 4.0)
                        Spacer()
                    }
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle(campaign.name)
        .listStyle(.plain)
        .sheet(isPresented: $showUpdateByName, onDismiss: {
            fetch()
        }, content: {
            NavigationStack {
//                UpdateAdGroupByNameView(campaign: campaign)
//                    .navigationTitle("Update by Name")
            }
        })
        .sheet(isPresented: $showSKAG, onDismiss: {
            fetch()
        }, content: {
            NavigationStack {
                SKAGView(campaign: campaign)
                    .navigationTitle("Add SKAG")
            }
        })
        .sheet(isPresented: $showSorting) {
            SortingView(selection: $sorting, order: $order)
                .onChange(of: sorting) { newValue in
                    UserDefaults.standard.groupSorting = newValue
                }
                .onChange(of: order) { newValue in
                    UserDefaults.standard.groupOrdering = newValue
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
            
            viewModel.$adGroups
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { dateRange in
                    fetchTotals()
                }
                .store(in: &cancallables)
        }
    }
}

extension AdGroupView {
    func update(adgroups: [AdGroup], update: AdGroupUpdate) async throws -> [AdGroup]? {
        return await withTaskGroup(of: AdGroup?.self) { taskGroup in
            for adgroup in adgroups {
                taskGroup.addTask {
                    do {
                        return try await SearchAds.instance.updateAdGroup(adGroup: adgroup, update: update)
                    } catch let error {
                        debugPrint("Error: \(error)")
                        return nil
                    }
                }
            }
         
            return await taskGroup.reduce(into: [AdGroup]()) { partialResult, adgroup in
                if let adgroup {
                    partialResult.append(adgroup)
                }
            }
        }
    }
    
    func changeStatus(status: Status) {
        guard let ids = viewModel.selectedAdGroupsIds else { return }
        guard let adgroups = viewModel.adGroups?.filter({
            if let id = $0.id {
                return ids.contains(id)
            } else {
                return false
            }
        }) else { return }

        Task {
            do {
                if let result = try await update(adgroups: adgroups, update: AdGroupUpdate(status: status)) {
                    for adgroup in result {
                        viewModel.adGroups?.replace(adgroups.filter({ $0.id == adgroup.id }), with: [adgroup])
                    }
                }
            } catch let error {
                debugPrint(" ERROR: \(error)")
            }
        }
    }
}
