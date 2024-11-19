//
//  CampainView.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI
import Combine

struct CampaignView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State var filter: String = ""
    @State var statusFilter: StatusFilter = UserDefaults.standard.campaignFilter
    @State var sorting: SortValue = UserDefaults.standard.campaignSorting
    @State var order: SortOrder = UserDefaults.standard.campaignOrdering
    
    @State private var showSorting: Bool = false
    #if os(iOS)
    @State private var showSettings: Bool = false
    #endif
    @State var showOnboarding: Bool = false
    @State var didShowOnboarding: Bool = false
    @State var cancallables = [AnyCancellable]()
    
    func fetch() {
        Task {
//            viewModel.campaigns = try await SearchAds.instance.getCampaigns()
        }
    }
    
    private func campaignFilter(_ c: Campaign) -> Bool {
        var result: Bool = true
        if filter.count > 0 {
            result = c.name.lowercased().contains(filter.lowercased())
        }
        if result {
            switch statusFilter {
            case .all:
                break; // no need to do anything
            case .enabled:
                result = c.status == .enabled
            case .disabled:
                result = c.status == .paused
            }
        }
        return result
    }
    
    var body: some View {
        Group {
            if let campaigns = viewModel.campaigns {
                VStack {
                    HStack {
                        DatesRangeView(dateRange: $viewModel.dateRange)
                        Spacer()
                        Picker("", selection: $viewModel.allKeywords) {
                            Text("Ad Groups")
                                .tag(false)
                            Text("All Keywords")
                                .tag(true)
                        }
                        .pickerStyle(.menu)
                        .padding()
                        Spacer()
                        FilterSortView(statusFilter: $statusFilter) {
                            showSorting = true
                        }
                        .onChange(of: statusFilter) { newValue in
                            UserDefaults.standard.campaignFilter = newValue
                            fetch()
                        }
                    }
                    #if os(iOS)
                    .padding([.leading, .trailing])
                    #else
                    .padding()
                    #endif
                    
                    HStack {
                        ZStack {
                            TextField("Search", text: $filter)
                                .submitLabel(.done)
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
                    
                    List(campaigns
                        .filter(campaignFilter(_:))
                        .sorted(by: { a, b in
                            guard let at = viewModel.report?.row.first(where: { $0.metadata.campaignId == a.id })?.total else { return false }
                            guard let bt = viewModel.report?.row.first(where: { $0.metadata.campaignId == b.id })?.total else { return false }
                            return SortValue.sort(ac: a, a: at, bc: b, b: bt, order: order, value: sorting)
                        }),
                         id: \.self,
                         selection: $viewModel.selectedCampaign)
                    { campaign in
                        NavigationLink(value: campaign) {
                            CampaignListItem(
                                campaign: campaign,
                                onUpdate: { update in
                                    Task {
                                        do {
                                            let _ = try await self.update(campaign: campaign, update: update)
                                        } catch let error {
                                            debugPrint(" UPDATE error: \(error)")
                                        }
                                    }
                                }, onRemove: {
                                    Task {
                                        do {
                                            try await SearchAds.instance.deleteCampaign(campaign: campaign)
                                            viewModel.campaigns?.removeAll(where: { $0.id == campaign.id })
                                            if viewModel.selectedCampaign == campaign {
                                                viewModel.selectedCampaign = nil
                                            }
                                        } catch let error {
                                            debugPrint(" DELETE error: \(error)")
                                        }
                                    }
                                })
                            .environmentObject(viewModel)
                        }
                    }
                    .refreshable {
                        fetch()
                    }
                    .navigationTitle(Text("Campaigns"))
                    .listStyle(.plain)
                    
                    if let totals = $viewModel.report.wrappedValue?.grandTotals?.total {
                        TotalsView(title: "Grand Totals", totals: totals)
                    } else {
                        LoadingView()
                    }
                    
                    if let campaigns = viewModel.campaigns {
                        Divider()
                        HStack {
                            Spacer()
                            Text("\(campaigns.filter(campaignFilter(_:)).count) campaigns")
                                .font(.footnote)
                                .padding(.bottom, 4.0)
                            Spacer()
                        }
                    }
                }
            } else {
                // This solves the issue with double nav bar item!
                VStack {
                    Spacer()
                    LoadingView()
                        .environmentObject(viewModel)
                    Spacer()
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(viewModel)
            }
        }
        #endif
        .sheet(isPresented: $showSorting) {
            SortingView(selection: $sorting, order: $order)
                .onChange(of: sorting) { newValue in
                    UserDefaults.standard.campaignSorting = newValue
                }
                .onChange(of: order) { newValue in
                    UserDefaults.standard.campaignOrdering = newValue
                }
        }
        .sheet(isPresented: $showOnboarding) {
            NavigationStack {
                OnboardingView()
                    .environmentObject(viewModel)
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        #endif
        .onAppear {
            if UserDefaults.standard.clientId == nil, UserDefaults.standard.clientSecret == nil {
                if !didShowOnboarding {
                    showOnboarding = true
                    didShowOnboarding = true
                }
            }
            
            SearchAds.instance.$token
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { token in
                    fetch()
                }
                .store(in: &cancallables)
            viewModel.$orgId
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { orgId in
                    fetch()
                }
                .store(in: &cancallables)
            viewModel.$dateRange
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { dateRange in
                    fetchTotals()
                }
                .store(in: &cancallables)
            viewModel.$campaigns
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { dateRange in
                    fetchTotals()
                }
                .store(in: &cancallables)
        }
    }
}

#warning("Make refreshable on Mac")
struct MainView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @ViewBuilder func adGroupsView() -> some View {
        if let campaign = viewModel.selectedCampaign {
            AdGroupView(
                campaign: campaign
            )
            .id(campaign.id)
            .environmentObject(viewModel)
            .onChange(of: viewModel.selectedCampaign) { newValue in
                // When chaning selected campaign - we should stop showing keywords for last selection
                viewModel.selectedAdGroup = nil
            }
        } else {
            Spacer()
        }
    }
    
    @ViewBuilder func allKeywordsView() -> some View {
        if let campaign = viewModel.selectedCampaign {
            AllKeywordsView(campaign: campaign)
                .id(campaign.id)
                .environmentObject(viewModel)
        } else {
            Spacer()
        }
    }
    
    @ViewBuilder func keywordsView() -> some View {
        if let adGroup = viewModel.selectedAdGroup {
            KeywordsView(adGroup: adGroup)
                .id(adGroup.id)
        } else {
            Spacer()
        }
    }
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack {
            if viewModel.allKeywords {
                NavigationSplitView {
                    CampaignView()
                        .environmentObject(viewModel)
                        #if os(macOS)
                        .navigationSplitViewColumnWidth(min: 400, ideal: 400)
                        #endif
                } detail: {
                    allKeywordsView()
//                    // On Mac its doubling toolbar items!
//                    #if os(iOS)
//                        .toolbar {
//                            ToolbarItemGroup(placement: .principal) {
//                                Picker("", selection: $viewModel.allKeywords) {
//                                    Text("Ad Groups")
//                                        .tag(false)
//                                    Text("All Keywords")
//                                        .tag(true)
//                                }
//                                .pickerStyle(.segmented)
//                                .padding()
//                            }
//                        }
//                    #endif
                }
                
                
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    CampaignView()
                        .environmentObject(viewModel)
                        #if os(macOS)
                        .navigationSplitViewColumnWidth(min: 400, ideal: 400)
                        #endif
                } content: {
                    adGroupsView()
                        #if os(macOS)
                        .navigationSplitViewColumnWidth(min: 400, ideal: 400)
                        #endif
//                        .toolbar {
//                            ToolbarItemGroup(placement: .principal) {
//                                Picker("", selection: $viewModel.allKeywords) {
//                                    Text("Ad Groups")
//                                        .tag(false)
//                                    Text("All Keywords")
//                                        .tag(true)
//                                }
//                                .pickerStyle(.segmented)
//                                .padding()
//                            }
//                        }
                } detail: {
                    keywordsView()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(viewModel)
            }
        }
        
//#elseif os(macOS)
//        NavigationSplitView {
//            CampaignView()
//                .environmentObject(viewModel)
//        } detail: {
//            if viewModel.allKeywords {
//                allKeywordsView()
//            } else {
//                NavigationSplitView {
//                    adGroupsView()
//                } detail: {
//                    keywordsView()
//                }
//            }
//        }
//        .toolbar {
//            ToolbarItem {
//                Picker("", selection: $viewModel.allKeywords) {
//                    Text("Ad Groups")
//                        .tag(false)
//                    Text("All Keywords")
//                        .tag(true)
//                }
//                .pickerStyle(.segmented)
//                .padding()
//            }
//        }
//#endif
    }
}
    
extension CampaignView {
    
    func update(campaign: Campaign, update: CampaignUpdate) async throws -> Campaign? {
        if let campaign = try await SearchAds.instance.updateCampaign(
            campaign: campaign,
            update: UpdateCampaignRequest(
                campaign: update,
                clearGeoTargetingOnCountryOrRegionChange: false)) {
            if let old = viewModel.campaigns?.filter({ $0.id == campaign.id }) {
                viewModel.campaigns?.replace(old, with: [campaign])
            }
            
            // Restore selection
            if campaign.id == viewModel.selectedCampaign?.id {
                viewModel.selectedCampaign = campaign
            }
        }
        return campaign
    }
    
    func asyncFetchTotals(completion: (() -> Void)? = nil) async throws {
        guard let _ = viewModel.campaigns else { return }
        
//        var conditions = [Condition]()
//        if let filteredCampaings = viewModel.campaigns?.filter(campaignFilter(_:)) {
//            if viewModel.campaigns?.count != filteredCampaings.count {
//                conditions.append(Condition(field: Fields.campaignId, op: .inRange, values: filteredCampaings
//                    .compactMap({ $0.id })
//                    .compactMap({ "\($0)" }))
//                )
//            }
//        }
//        
//        guard let report = try await SearchAds.instance.getCampaignReport(
//            report: ReportingRequest(
//                startTime: .init(date: viewModel.dateRange.startDate()),
//                endTime: .init(date: viewModel.dateRange.endDate()),
//                selector: ReportSelector(
//                    conditions: conditions,
//                    orderBy: [
//                        .init(field: .campaignId, sortOrder: .ascending)
//                    ],
//                    pagination: Pagination(offset: 0, limit: 1000)),
//                returnGrandTotals: true,
//                returnRowTotals: true,
//                timeZone: .ortz)) else { return }
//        
//        DispatchQueue.main.async {
//            viewModel.report = report.reportingDataResponse
//            // Update if we just fetched it
//            if viewModel.dateRange.interval == .days && viewModel.dateRange.value == 0 {
//                viewModel.todaysReport = report.reportingDataResponse
//            } else {
//                viewModel.fetchTodaysTotals()
//            }
//            completion?()
//        }
    }
    
    func fetchTotals(completion: (() -> Void)? = nil) {
        Task {
            try? await asyncFetchTotals(completion: completion)
        }
    }
    
}
