//
//  Store.swift
//  StoreDemo1
//
//  Created by Nathanael Roberton on 12/6/22.
//

import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreError: Error {
    case failedVerification
}

//Define our app's subscription tiers by level of service, in ascending order.
public enum SubscriptionTier: Int, Comparable {
    case none = 0
    case idea = 1
    case visual = 2

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class Store: ObservableObject {
    
    @Published private(set) var subscriptions: [Product]
    
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    
    var updateListenerTask: Task<Void, Error>? = nil

    private let productIdToEmoji: [String: String]
    
    init() {
        if let path = Bundle.main.path(forResource: "Projects", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: path) {
            productIdToEmoji = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String:String]) ?? [:]
        } else {
            productIdToEmoji = [:]
        }
        
        // Initialize subscriptions
        subscriptions = []
        
        // Start transaction listener
        updateListenerTask = listenForTransactions()
        
        // request subscription asynchronously to fill them
        // ...
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through all existing transactions (besides a purchase).
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Deliver products to the user.
                    await self.updateCustomerProductStatus()
                }
            }
        }
    }
    
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the WS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified. Return unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedSubscriptions: [Product] = []
        
        // Iterate througha all the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                // Check whether the transaction is verified. If it isn't, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                // Get subscription product from the store
                if transaction.productType == .autoRenewable {
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                }
            } catch {
                print()
            }
        }
    }
}
