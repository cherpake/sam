//
//  GrandTotalView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 04/11/2024.
//
import SwiftUI

struct HDivider: View {
    var body: some View {
        Rectangle()
            .frame(width: 1)
            .frame(maxHeight: 20.0)
            .foregroundStyle(.secondary)
    }
}

struct GrandTotalView: View {
    var totals: SpendRow
    var count: Int
    var type: String
    
    var axis: Axis = .horizontal
    
    @ViewBuilder
    func content() -> some View {
        VStack {
            Text(type)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("\(count)")
        }
        
        Spacer()
        
        if let spend = Float(totals.localSpend.amount) {
            VStack {
                Text("Spend:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(spend.formatted(.currency(code: totals.localSpend.currency)))
                    .monospaced()
            }
            
            HDivider()
        }
                    
        VStack {
            Text("Installs:")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("\(totals.totalInstalls)")
                .monospaced()
        }
                   
        HDivider()
        
        VStack {
            Text("Taps:")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("\(totals.taps)")
                .monospaced()
        }
                    
        if let avgCPT = Float(totals.avgCPT.amount) {
            HDivider()
            
            VStack {
                Text("Avg. CPT:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(avgCPT.formatted(.currency(code: totals.avgCPT.currency)))
                    .monospaced()
            }
        }
    }
    
    var body: some View {
        if axis == .horizontal {
            HStack {
                content()
            }
            .padding()
        } else {
            VStack {
                content()
            }
            .padding()
        }
    }
}
