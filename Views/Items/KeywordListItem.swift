//
//  KeywordListItem.swift
//  sam
//
//  Created by Evgeny Cherpak on 04/03/2023.
//

import SwiftUI
import Combine

struct KeywordListItem: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State var keyword: Keyword
    
    var onDelete: (Keyword) -> Void
    var onUpdate: (KeywordUpdate) -> Void
    
    @State var cancallable = [AnyCancellable]()
    @State var totals: SpendRow?
    
    @State private var showUpdateMaxCPT: Bool = false
    
    var body: some View {
        HStack {
            Toggle(isOn: Binding(get: {
                return viewModel.selectedKeywordIds?.contains(keyword.id ?? 0) ?? false
            }, set: { v, t in
                if v {
                    if viewModel.selectedKeywordIds == nil {
                        viewModel.selectedKeywordIds = Set<Int64>()
                    }
                    viewModel.selectedKeywordIds?.insert(keyword.id ?? 0)
                } else {
                    viewModel.selectedKeywordIds?.remove(keyword.id ?? 0)
                }
            })) {
                
            }
            .toggleStyle(.checkboxStyle)
            
            if let keyword = viewModel.keywords?.first(where: { $0.id == keyword.id }) {
                VStack(alignment: .leading) {
                    if keyword.matchType == .broad {
                        Text(keyword.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("[\(keyword.text)]")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    let money = keyword.bidAmount
                    Text("Max CPT Bid: \(Float(money.amount)!.formatted(.currency(code: money.currency)))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: true, vertical: true)
                }
                Spacer()
                Group {
                    if let totals {
                        TotalsView(title: keyword.text, totals: totals, mode: .comapct)
                            .fixedSize(horizontal: true, vertical: true)
                    } else {
                        LoadingView()
                            .fixedSize(horizontal: true, vertical: true)
                            .padding()
                    }
                }
                StatusView(
                    campaign: viewModel.selectedCampaign?.status,
                    adGroup: viewModel.adGroups?.filter({ $0.id == keyword.adGroupId }).first?.status,
                    keyword: keyword.status
                )
            }
        }
        .contextMenu {
            Button() {
                Task {
                    guard let id = keyword.id else { return }
                    onUpdate(KeywordUpdate(id: id, status: .active))
                }
            } label: {
                Image(systemName: "play.fill")
                Text("Activate")
            }
            Button() {
                Task {
                    guard let id = keyword.id else { return }
                    onUpdate(KeywordUpdate(id: id, status: .paused))
                }
            } label: {
                Image(systemName: "pause.fill")
                Text("Pause")
            }
            Button() {
                Task {
                    guard let adGroup = viewModel.adGroups?.filter({ $0.id == keyword.adGroupId }).first else { return }
                    do {
                        if let updatedAdGroup = try await SearchAds.instance.updateAdGroup(adGroup: adGroup, update: AdGroupUpdate(status: Status.paused)) {
                            viewModel.adGroups?.replace([adGroup], with: [updatedAdGroup])
                        }
                    } catch let error {
                        debugPrint("error: \(error)")
                    }
                }
            } label: {
                Image(systemName: "pause.fill")
                Text("Pause AdGroup")
            }
            Divider()
            Button(role: .destructive) {
                onDelete(keyword)
            } label: {
                Image(systemName: "trash")
                Text("Remove")
            }
            Divider()
            Button() {
                showUpdateMaxCPT = true
            } label: {
                Image(systemName: "dollarsign.circle")
                Text("Edit Max CPT Bid")
            }
            if let id = keyword.id {
                Divider()
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
                    Text("Copy Keyword Id")
                }
            }
        }
        .sheet(isPresented: $showUpdateMaxCPT) {
            let money = keyword.bidAmount
            NavigationStack {
                MoneyView(money: money, title: "Edit Max CPT Bid") { amount, isOn in
                    Task {
                        guard let id = keyword.id else { return }
                        onUpdate(KeywordUpdate(id: id, bidAmount: Money(amount: amount, currency: money.currency)))
                    }
                }
            }
        }
        .onAppear {
            viewModel.$keywordsReport
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .sink { report in
                    totals = report?.row.filter({ $0.metadata.keywordId == keyword.id }).first?.total
                }
                .store(in: &cancallable)
        }
    }
}
