//
//  ContentView.swift
//  StoreDemo1
//
//  Created by Nathanael Roberton on 12/6/22.
//

import StoreKit
import SwiftUI

struct ContentView: View {
    @StateObject var store: Store = Store()
    
    @State var currentSubscription: Product?
    @State var status: Product.SubscriptionInfo.Status?
    
    var availableSubscriptions: [Product] {
        store.subscriptions.filter { $0.id != currentSubscription?.id }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Subscription") {
                    if !store.purchasedSubscriptions.isEmpty {
                        ForEach(store.purchasedSubscriptions) { product in
                            NavigationLink {
                                ProductDetailView(product: product)
                            } label: {
                                ListCellView(product: product, purchasingEnabled: false)
                            }
                        }
                        
                    } else {
                        if let subscriptionGroupStatus = store.subscriptionGroupStatus {
                            if subscriptionGroupStatus == .expired || subscriptionGroupStatus == .revoked {
                                Text("Welcome Back! \nHead over to the shop to get started!")
                            } else if subscriptionGroupStatus == .inBillingRetryPeriod {
                                //The best practice for subscriptions in the billing retry state is to provide a deep link
                                //from your app to https://apps.apple.com/account/billing.
                                Text("Please verify your billing details.")
                            }
                        } else {
                            Text("You don't own any subscriptions. \nHead over to the shop to get started!")
                        }
                    }
                }
                
                NavigationLink {
                    StoreView()
                } label: {
                    Label("Shop", systemImage: "cart")
                }
                .foregroundColor(.white)
                .listRowBackground(Color.blue)
            }
            .navigationTitle("StoreKit Demo")
        }
        .environmentObject(store)
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        do {
            guard let product = store.subscriptions.first,
                  let statuses = try await product.subscription?.status else {
                return
            }
            
            var highestStatus: Product.SubscriptionInfo.Status? = nil
            var highestProduct: Product? = nil
            
            // Iterate through statuses to find the highest level of service that isn't expired (which they may have through Family Sharing)
            for status in statuses {
                switch status.state {
                case .expired, .revoked:
                    continue
                default:
                    let renewalInfo = try store.checkVerified(status.renewalInfo)

                    //Find the first subscription product that matches the subscription status renewal info by comparing the product IDs.
                    guard let newSubscription = store.subscriptions.first(where: { $0.id == renewalInfo.currentProductID }) else {
                        continue
                    }

                    guard let currentProduct = highestProduct else {
                        highestStatus = status
                        highestProduct = newSubscription
                        continue
                    }

                    let highestTier = store.tier(for: currentProduct.id)
                    let newTier = store.tier(for: renewalInfo.currentProductID)

                    if newTier > highestTier {
                        highestStatus = status
                        highestProduct = newSubscription
                    }
                }
            }

            status = highestStatus
            currentSubscription = highestProduct
        } catch {
            print("Could not update subscription status \(error)")
        }
    }
}
