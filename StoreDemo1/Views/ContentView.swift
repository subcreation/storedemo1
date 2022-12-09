//
//  ContentView.swift
//  StoreDemo1
//
//  Created by Nathanael Roberton on 12/6/22.
//

import StoreKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    
    @State var currentSubscription: Product?
    @State var status: Product.SubscriptionInfo.Status?
    
    var body: some View {
        Group {
            if let currentSubscription = currentSubscription {
                Section("My Subscription") {
                    VStack(alignment: .leading) {
                        Text(currentSubscription.displayName)
                            .bold()
                        Text(currentSubscription.description)
                    }
                }
            }
        }
        .onAppear {
            Task {
                // When this view appears, get the latest subscription status.
                await updateSubscriptionStatus()
            }
        }
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
