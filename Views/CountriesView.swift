//
//  CountriesView.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI

struct CountryListItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(country)
    }
    var country: CountryOrRegion
    var isOn: Bool
}

struct CountriesView: View {
    var countryCodes: [String]
    var update: ([String]) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State var loaded: Bool = false
    @State var allCountries = [CountryListItem]()
        
    @State var filter: String = ""
    @State var statusFilter: StatusFilter = UserDefaults.standard.countriesFilter {
        didSet {
            UserDefaults.standard.countriesFilter = self.statusFilter
        }
    }
    
    @ViewBuilder func cancelButton() -> some View {
        Button("Cancel", role: .cancel) {
            dismiss()
        }
    }
    
    @ViewBuilder func updateButton() -> some View {
        Button("Update") {
            update(allCountries.compactMap({
                return $0.isOn ? $0.country.countryOrRegion : nil
            }))
            dismiss()
        }
    }
    
    func fetch() {
        Task {
            if let allCountries = try await SearchAds.instance.getSupportedCountries() {
                self.allCountries = allCountries
                    .sorted(by: { a, b in
                        return a.displayName().compare(b.displayName(), options: .caseInsensitive) == .orderedAscending
                    })
                    .compactMap({ c in
                        return CountryListItem(country: c, isOn: countryCodes.contains(c.countryOrRegion))
                    })
                self.loaded = true
            }
        }
    }
    
    private func statusFilterLabels(statusFilter: StatusFilter) -> String {
        switch statusFilter {
        case .all:
            return "All"
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        }
    }
    func countryFilter(c: CountryListItem) -> Bool {
        var result: Bool = true
        if filter.count > 0 {
            result = c.country.displayName().lowercased().contains(filter.lowercased())
        }
        if result {
            switch statusFilter {
            case .all:
                break; // no need to do anything
            case .enabled:
                result = c.isOn
            case .disabled:
                result = !c.isOn
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            #if os(macOS)
            // This makes the window bigger
            Spacer()
                .frame(width: 500, height: 500)
            #endif
            Group {
                if loaded {
                    VStack {
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
                            Spacer()
                            Menu {
                                ForEach(StatusFilter.allCases, id: \.rawValue) { c in
                                    Button(statusFilterLabels(statusFilter: c)) {
                                        statusFilter = c
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease")
                                Text(statusFilterLabels(statusFilter: statusFilter))
                            }
                            .fixedSize(horizontal: true, vertical: true)
                            Spacer()
                            Menu() {
                                Button {
                                    allCountries
                                        .filter(countryFilter(c:))
                                        .forEach { c in
                                            if let index = allCountries.firstIndex(of: c) {
                                                allCountries[index].isOn = true
                                            }
                                        }
                                } label: {
                                    Image(systemName: "checkmark.square.fill")
                                    Text("Select All")
                                }
                                Button {
                                    allCountries
                                        .filter(countryFilter(c:))
                                        .forEach { c in
                                            if let index = allCountries.firstIndex(of: c) {
                                                allCountries[index].isOn = false
                                            }
                                        }
                                } label: {
                                    Image(systemName: "square")
                                    Text("Deselect All")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                Text("Actions")
                            }
                            .fixedSize(horizontal: true, vertical: true)
                        }
                        
                        List(allCountries.filter(countryFilter(c:)), id: \.self) { item in
                            Toggle(isOn: Binding(get: {
                                item.isOn
                            }, set: { v, t in
                                if let index = allCountries.firstIndex(of: item) {
                                    allCountries[index].isOn = v
                                }
                            })) {
                                HStack {
                                    Text(item.country.countryOrRegion.countryFlag())
                                    Text(item.country.displayName())
                                }
                            }
                            #if os(macOS)
                            .toggleStyle(.checkbox)
                            #endif
                        }
                        .refreshable {
                            fetch()
                        }
                        
                        Text("Enabled \(allCountries.filter({ $0.isOn }).count) out of \(allCountries.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                }
            }
        }
        .padding()
#if !os(macOS)
        .navigationBarTitle("Countries")
#endif
        .toolbar {
            ToolbarItem() {
                Button {
                    // TODO: implement by copying country codes to clipboard
                } label: {
                    Text("Copy")
                }
            }
            ToolbarItem() {
                Button {
                    // TODO: set county codes from clipboard + call fetch()
                } label: {
                    Text("Paste")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                cancelButton()
            }
            ToolbarItem(placement: .primaryAction) {
                updateButton()
            }
        }
        .onAppear {
            fetch()
        }
    }
}
