//
//  TransactionDetailHistoryItem.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 2/6/24.
//

import SwiftUI

struct TransactionDetailHistoryItem: Identifiable, Hashable {
    
    let id = UUID()
    var type: TransactionDetailHistoryType
    var date: Date?
    var timestamp: TimeInterval?
    var offerCode: String?
    var priceInUsd: Double?
    
    var dateFormatted: String {
        guard let date else {
            return "Unknown"
        }
        return "\(date.formatted(.relative(presentation: .named)).capitalizedSentence) (\(date.formatted(date: .abbreviated, time: .shortened)))"
    }
    
    init?(data: RCSubscriberHistory) {
//        let price = (data.priceInPurchasedCurrency ?? 0) != 0 ? (data.priceInPurchasedCurrency ?? 0) : (data.priceInUsd ?? 0)
//        let currency = (data.priceInPurchasedCurrency ?? 0) != 0 ? (data.currency ?? "USD") : "USD"
        
        switch data.event {
        case "installation":
            type = .installation
        case "subscriber_alias":
            type = .subscriberAlias(alias: data.alias ?? "n/a")
        case "last_seen":
            type = .lastSeen
//        case "cancellation":
//            type = .cancellation(
//                price: price,
//                currency: currency,
//                productIdentifier: data.product ?? "n/a"
//            )
//        case "purchase":
//            type = .initialPurchase(
//                price: price,
//                currency: currency,
//                productIdentifier: data.product ?? "n/a"
//            )
//        case "renewal":
//            type = .renewal(
//                price: price,
//                currency: currency,
//                productIdentifier: data.product ?? "n/a"
//            )
//        case "trial_start":
//            type = .trial(
//                price: price,
//                currency: currency,
//                productIdentifier: data.product ?? "n/a"
//            )
//        case "trial_conversion":
//            type = .conversion(
//                price: price,
//                currency: currency,
//                productIdentifier: data.product ?? "n/a"
//            )
//        case "refund":
//            type = .refund(
//                price: price,
//                currency: currency,
//                productIdentifier: data.product ?? "n/a"
//            )
        default:
            return nil
        }
        
        date = data.at?.format(to: .iso8601WithoutMilliseconds)
        timestamp = date?.timeIntervalSince1970
    }
    
    init(data: RCTransactionDetailEvent, appUserId: String) {
        let price = (data.priceInPurchasedCurrency ?? 0) != 0 ? (data.priceInPurchasedCurrency ?? 0) : (data.price ?? 0)
        let currency = (data.priceInPurchasedCurrency ?? 0) != 0 ? (data.currency ?? "USD") : "USD"
        
        switch data.type {
        case "PURCHASES_INITIAL_PURCHASE":
            if data.periodType == "TRIAL" {
                type = .trial(
                    price: price,
                    currency: currency,
                    productIdentifier: data.productId ?? "n/a"
                )
            } else { // NORMAL
                type = .initialPurchase(
                    price: price,
                    currency: currency,
                    productIdentifier: data.productId ?? "n/a"
                )
            }
        case "PURCHASES_NON_RENEWING_PURCHASE":
            type = .oneTimePurchase(
                price: price,
                currency: currency,
                productIdentifier: data.productId ?? "n/a"
            )
        case "PURCHASES_RENEWAL":
            if data.isTrialConversion ?? false {
                type = .conversion(
                    price: price,
                    currency: currency,
                    productIdentifier: data.productId ?? "n/a"
                )
            } else {
                type = .renewal(
                    price: price,
                    currency: currency,
                    productIdentifier: data.productId ?? "n/a"
                )
            }
        case "PURCHASES_CANCELLATION":
            if data.cancelReason == "CUSTOMER_SUPPORT" {
                type = .refund(
                    price: price,
                    currency: currency,
                    productIdentifier: data.productId ?? "n/a"
                )
            } else { // UNSUBSCRIBE
                type = .unsubscription(
                    price: price,
                    currency: currency,
                    productIdentifier: data.productId ?? "n/a"
                )
            }
        case "PURCHASES_UNCANCELLATION":
            type = .resubscription(
                price: price,
                currency: currency,
                productIdentifier: data.productId ?? "n/a"
            )
        case "PURCHASES_EXPIRATION":
            type = .expiration(
                price: price,
                currency: currency,
                productIdentifier: data.productId ?? "n/a"
            )
        case "PURCHASES_PRODUCT_CHANGE":
            type = .productChange(
                productIdentifier: data.newProductId ?? "n/a"
            )
        case "PURCHASES_TRANSFER":
            let isFrom = data.transferredFrom?.contains(appUserId) ?? false
            let id: String
            
            if isFrom {
                if (data.transferredTo?.count ?? 0) > 1 {
                    id = data.transferredTo?.first(where: { !$0.contains("RCAnonymousID") }) ?? "n/a"
                } else {
                    id = data.transferredTo?.first ?? "n/a"
                }
            } else {
                if (data.transferredFrom?.count ?? 0) > 1 {
                    id = data.transferredFrom?.first(where: { !$0.contains("RCAnonymousID") }) ?? "n/a"
                } else {
                    id = data.transferredFrom?.first ?? "n/a"
                }
            }
            
            type = .transfer(isFrom: isFrom, id: id)
            
        case "PURCHASES_BILLING_ISSUE":
            type = .billingIssue(
                price: price,
                currency: currency,
                productIdentifier: data.productId ?? "n/a"
            )
        default:
            type = .unknown(type: data.type)
        }
        
        if let timestamp = data.eventTimestampMs {
            date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
            self.timestamp = date?.timeIntervalSince1970
        }
        
        offerCode = data.offerCode
        priceInUsd = data.price
    }
}

enum TransactionDetailHistoryType: Hashable {
    
    case installation
    case subscriberAlias(alias: String)
    case lastSeen
    case productChange(productIdentifier: String)
    case transfer(isFrom: Bool, id: String)
    
    case initialPurchase(price: Double, currency: String, productIdentifier: String)
    case oneTimePurchase(price: Double, currency: String, productIdentifier: String)
    case renewal(price: Double, currency: String, productIdentifier: String)
    case trial(price: Double, currency: String, productIdentifier: String)
    case conversion(price: Double, currency: String, productIdentifier: String)
    case resubscription(price: Double, currency: String, productIdentifier: String)
    case unsubscription(price: Double, currency: String, productIdentifier: String)
    case expiration(price: Double, currency: String, productIdentifier: String)
    case billingIssue(price: Double, currency: String, productIdentifier: String)
    case refund(price: Double, currency: String, productIdentifier: String)
    
    case unknown(type: String?)
    
    var text: String {
        switch self {
        case .installation: "Installation"
        case .subscriberAlias: "Subscriber Alias"
        case .lastSeen: "Last Seen"
        case .productChange: "Product Change"
        case .transfer(let isFrom, _): isFrom ? "Transferred to Another User" : "Transferred from Another User"
        
        case .initialPurchase: "New Subscription"
        case .oneTimePurchase: "One-Time Purchase"
        case .renewal: "Renewal"
        case .trial: "Trial"
        case .conversion: "Conversion"
        case .resubscription: "Resubscription"
        case .unsubscription: "Unsubscription"
        case .expiration: "Expiration"
        case .billingIssue: "Billing Issue"
        case .refund: "Refund"
            
        case .unknown(let type): type ?? "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .installation: .primary
        case .subscriberAlias: .primary
        case .lastSeen: .primary
        case .productChange: .primary
        case .transfer: .primary
        
        case .initialPurchase: .blue
        case .oneTimePurchase: .purple
        case .renewal: .green
        case .trial: .orange
        case .conversion: .blue
        case .resubscription: .green
        case .unsubscription: .yellow
        case .expiration: .red
        case .billingIssue: .red
        case .refund: .red
            
        case .unknown: .primary
        }
    }
    
    var transactionType: TransactionType? {
        switch self {
        case .initialPurchase: .initialPurchase
        case .oneTimePurchase: .oneTimePurchase
        case .renewal: .renewal
        case .trial: .trial
        case .conversion: .conversion
        case .refund: .refund
        default: nil
        }
    }
}
