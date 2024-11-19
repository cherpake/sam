//
//  MainAppView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 01/11/2024.
//

import SwiftUI
import CryptoKit

struct MainAppView: View {
    @EnvironmentObject var viewModel: MainAppModel
        
    enum MainModal: String, Identifiable {
        var id: String {
            return self.rawValue
        }
        case settings
    }
    
    @State private var modalView: MainModal? = nil
    
    var body: some View {
#if os(macOS)
        VStack {
            switch viewModel.viewMode {
            case .normal:
                NavigationSplitView {
                    CampaignsView()
                        .environmentObject(viewModel)
                } content: {
                    AdGroupsView()
                        .environmentObject(viewModel)
                } detail: {
                    KeywordsView()
                        .environmentObject(viewModel)
                }
            case .allKeywords:
                NavigationSplitView {
                    CampaignsView()
                        .environmentObject(viewModel)
                } detail: {
                    KeywordsView()
                        .environmentObject(viewModel)
                }
            }
        }
        .sheet(item: $modalView, content: { modal in
            switch modal {
            case .settings:
                SettingsView()
                    .environmentObject(viewModel)
            }
        })
        .onAppear {
            // Check if we have credentials
            // if not show settings!
            guard
                let _ = UserDefaults.standard.orgId,
                let _ = UserDefaults.standard.clientId,
                let _ = UserDefaults.standard.clientSecret
            else {
                // Check if we have private & public keys
                // and if not - generate them here
                if UserDefaults.standard.privateKey == nil || UserDefaults.standard.publicKey == nil {
                    let privateKey = P256.Signing.PrivateKey()
                    UserDefaults.standard.privateKey = privateKey.pemRepresentation
                    UserDefaults.standard.publicKey = privateKey.publicKey.pemRepresentation
                }
                
                modalView = .settings
                return
            }
            
            Task {
                try await viewModel.updateCampaingsReport()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                DatesRangeView(dateRange: $viewModel.dateRange)
                Menu {
                    Text("View Mode:")
                    Button {
                        viewModel.changeMode(.normal)
                    } label: {
                        if !UserDefaults.standard.showAllKeywords {
                            Image(systemName: "checkmark")
                        }
                        Text("Normal")
                    }
                    Button {
                        viewModel.changeMode(.allKeywords)
                    } label: {
                        if UserDefaults.standard.showAllKeywords {
                            Image(systemName: "checkmark")
                        }
                        Text("All Keywords")
                    }
                    Divider()
                    Button {
                        modalView = .settings
                    } label: {
                        Text("Settings")
                    }
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
#else
        NavigationStack(path: $viewModel.path) {
            VStack {
                CampaignsView()
                    .navigationTitle("SearchAds Manager")
                    .onAppear {
                        Task {
                            try await viewModel.updateCampaingsReport()
                        }
                    }
            }
            .navigationDestination(for: String.self, destination: { route in
                switch route {
                case "adgroups":
                    AdGroupsView()
                case "keywords":
                    KeywordsView()
                default:
                    EmptyView()
                }
            })
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    DatesRangeView(dateRange: $viewModel.dateRange)
                    Menu {
                        Text("View Mode:")
                        Button {
                            viewModel.changeMode(.normal)
                        } label: {
                            if !UserDefaults.standard.showAllKeywords {
                                Image(systemName: "checkmark")
                            }
                            Text("Normal")
                        }
                        Button {
                            viewModel.changeMode(.allKeywords)
                        } label: {
                            if UserDefaults.standard.showAllKeywords {
                                Image(systemName: "checkmark")
                            }
                            Text("All Keywords")
                        }
                        Divider()
                        Button {
                            showSettings = true
                        } label: {
                            Text("Settings")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
#endif
    }
}
