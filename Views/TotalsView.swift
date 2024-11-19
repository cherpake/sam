//
//  TotalsView.swift
//  sam
//
//  Created by Evgeny Cherpak on 02/03/2023.
//

import SwiftUI

struct DetailsTotalsView: View {
    @EnvironmentObject var viewModel: MainAppModel
    
    var totals: SpendRow
    var body: some View {
        GrandTotalView(totals: totals, count: viewModel.campaingsReport?.row.count ?? 0, type: "Campaigns", axis: .vertical)
    }
}
