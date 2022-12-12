//
//  StoreView.swift
//  StoreDemo1
//
//  Created by Nathanael Roberton on 12/12/22.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            SubscriptionsView()

            Button("Restore Purchases", action: {
                Task {
                    //This call displays a system prompt that asks users to authenticate with their App Store credentials.
                    //Call this function only in response to an explicit user action, such as tapping a button.
                    try? await AppStore.sync()
                }
            })

        }
        .navigationTitle("Shop")
    }
}
