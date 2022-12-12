//
//  ProductDetailView.swift
//  StoreDemo1
//
//  Created by Nathanael Roberton on 12/12/22.
//

import Foundation
import SwiftUI
import StoreKit

struct ProductDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var store: Store
    @State private var isFuelStoreShowing = false
    
    @State private var carOffsetX: CGFloat = 0
    @State private var isCarHidden = false
    @State private var showSpeed = false

    let product: Product
    
    var emoji: String {
        return store.emoji(for: product.id)
    }
    
    var body: some View {
        ZStack {
            Group {
                VStack {
                    Text(showSpeed ? "\(emoji)💨" : emoji)
                        .font(.system(size: 120))
                        .padding(.bottom, 20)
                        .offset(x: carOffsetX, y: 0)
                        .opacity(isCarHidden ? 0.0 : 1.0)
                    Text(product.description)
                        .padding()
                    Spacer()
                }
            }
            .blur(radius: isFuelStoreShowing ? 10 : 0)
            .contentShape(Rectangle())
        }
        .navigationTitle(product.displayName)
    }
}

extension Date {
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: self)
    }
}
