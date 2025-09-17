//
//  TransactionDetailScreen.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 2/6/24.
//

import SwiftUI

struct TransactionDetailScreen: View {
    
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @StateObject var viewModel: TransactionDetailViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var isPresented = false
    
    var body: some View {
        makeBody()
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.systemGroupedBackground)
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .safeClose) {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        BrowserUtility.openUrlOutsideApp(urlString: "https://app.revenuecat.com/customers/\(viewModel.projectId)/\(viewModel.subscriberId)")
                    } label: {
                        Image(systemName: "arrow.up.forward")
                    }
                }
            }
    }
    
    @ViewBuilder
    private func makeBody() -> some View {
        switch viewModel.state {
        case .empty:
            ContentUnavailableView(
                "No Data",
                systemImage: "xmark.circle"
            )
            
        case .error(let error):
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(error.displayableLocalizedDescription)
            )
            
        case .loading,
                .data:
            List {
                if let items = viewModel.detailItems {
                    Section {
                        ForEach(items) { item in
                            TransactionDetailInfoItemView(item: item)
                        }
                    } header: {
                        Text("Details")
                    }
                }
                
                if purchaseManager.state == .data,
                   purchaseManager.meSubscriptionType == .normal {
                    Section {
                        BecomeSupporterView(
                            title: "Become a Supporter!",
                            subtitle: "Support indie development",
                            isActive: true
                        )
                    }
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                    .listSectionSpacing(.compact)
                }
                
                if let items = viewModel.entitlementItems {
                    Section {
                        ForEach(items) { item in
                            TransactionDetailEntitlementItemView(item: item)
                        }
                    } header: {
                        Text("Entitlements")
                    }
                }
                
                if let items = viewModel.insightItems {
                    Section {
                        ForEach(items) { item in
                            TransactionDetailInsightItemView(item: item)
                        }
                    } header: {
                        Label("Insights", systemImage: "sparkles")
                    }
                }
                
                if let items = viewModel.attributeItems {
                    Section {
                        ForEach(items) { item in
                            TransactionDetailInfoItemView(item: item)
                        }
                    } header: {
                        Text("Attributes")
                    }
                }
                
                if let items = viewModel.historyItems {
                    Section {
                        ForEach(items) { item in
                            TransactionDetailHistoryItemView(item: item)
                        }
                    } header: {
                        Text("History")
                    }
                }
            }
            .redacted(reason: viewModel.state == .loading ? .placeholder : [])
            .disabled(viewModel.state == .loading)
        }
    }
}

#Preview {
    TransactionDetailScreen(viewModel: .init(projectId: "", subscriberId: ""))
}
