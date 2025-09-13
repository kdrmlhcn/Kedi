//
//  RCTransactionDetailActivityResponse.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 2/7/24.
//

import Foundation

struct RCTransactionDetailActivityResponse: Decodable {
    
    var events: [RCTransactionDetailEvent]?
    var appUserId: String?
    
    enum CodingKeys: String, CodingKey {
        case events
        case subscriber
    }
    
    enum SubscriberCodingKeys: String, CodingKey {
        case appUserId = "app_user_id"
    }
    
    init(
        events: [RCTransactionDetailEvent]? = nil,
        appUserId: String? = nil
    ) {
        self.events = events
        self.appUserId = appUserId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bodyContainer = try container.nestedContainer(keyedBy: SubscriberCodingKeys.self, forKey: .subscriber)
        
        events = try container.decodeIfPresent([RCTransactionDetailEvent].self, forKey: .events)
        appUserId = try bodyContainer.decodeIfPresent(String.self, forKey: .appUserId)
    }
}

struct RCTransactionDetailEvent: Decodable {
    
    var type: String?
    var price: Double?
    var currency: String?
    var priceInPurchasedCurrency: Double?
    var eventTimestampMs: Int?
    var purchasedAtMs: Int?
    var expirationAtMs: Int?
    var productId: String?
    var newProductId: String?
    var offerCode: String?
    var cancelReason: String?
    var periodType: String?
    var isTrialConversion: Bool?
    var transferredFrom: [String]?
    var transferredTo: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case body
    }
    
    enum BodyCodingKeys: String, CodingKey {
        case price
        case currency
        case priceInPurchasedCurrency = "price_in_purchased_currency"
        case eventTimestampMs = "event_timestamp_ms"
        case purchasedAtMs = "purchased_at_ms"
        case expirationAtMs = "expiration_at_ms"
        case productId = "product_id"
        case newProductId = "new_product_id"
        case offerCode = "offer_code"
        case cancelReason = "cancel_reason"
        case periodType = "period_type"
        case isTrialConversion = "is_trial_conversion"
        case transferredFrom = "transferred_from"
        case transferredTo = "transferred_to"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bodyContainer = try container.nestedContainer(keyedBy: BodyCodingKeys.self, forKey: .body)
        
        type = try container.decodeIfPresent(String.self, forKey: .type)
        price = try bodyContainer.decodeIfPresent(Double.self, forKey: .price)
        currency = try bodyContainer.decodeIfPresent(String.self, forKey: .currency)
        priceInPurchasedCurrency = try bodyContainer.decodeIfPresent(Double.self, forKey: .priceInPurchasedCurrency)
        eventTimestampMs = try bodyContainer.decodeIfPresent(Int.self, forKey: .eventTimestampMs)
        purchasedAtMs = try bodyContainer.decodeIfPresent(Int.self, forKey: .purchasedAtMs)
        expirationAtMs = try bodyContainer.decodeIfPresent(Int.self, forKey: .expirationAtMs)
        productId = try bodyContainer.decodeIfPresent(String.self, forKey: .productId)
        newProductId = try bodyContainer.decodeIfPresent(String.self, forKey: .newProductId)
        offerCode = try bodyContainer.decodeIfPresent(String.self, forKey: .offerCode)
        cancelReason = try bodyContainer.decodeIfPresent(String.self, forKey: .cancelReason)
        periodType = try bodyContainer.decodeIfPresent(String.self, forKey: .periodType)
        isTrialConversion = try bodyContainer.decodeIfPresent(Bool.self, forKey: .isTrialConversion)
        transferredFrom = try bodyContainer.decodeIfPresent([String].self, forKey: .transferredFrom)
        transferredTo = try bodyContainer.decodeIfPresent([String].self, forKey: .transferredTo)
    }
}

extension RCTransactionDetailActivityResponse {
    
    static let stub: Self = {
        let string = #"""
        {
            "aliases": [
                {
                    "alias": "alias001",
                    "at": "2024-02-15T19:50:08Z",
                    "event": "subscriber_alias"
                }
            ],
            "events": [
                {
                    "body": {
                        "app_id": "app001",
                        "app_user_id": "app_user001",
                        "country_code": "TR",
                        "currency": "TRY",
                        "entitlement_ids": [
                            "supporter"
                        ],
                        "environment": "PRODUCTION",
                        "event_timestamp_ms": 1705350714054,
                        "expiration_at_ms": 1708029108000,
                        "is_family_share": false,
                        "offer_code": "offer_code",
                        "period_type": "NORMAL",
                        "price": 99.99,
                        "price_in_purchased_currency": 2.99,
                        "product_id": "kedi.supporter.monthly",
                        "purchased_at_ms": 1705350708000,
                        "store": "APP_STORE",
                        "takehome_percentage": 0.85,
                        "transaction_id": "transaction001"
                    },
                    "type": "PURCHASES_INITIAL_PURCHASE",
                    "uuid": "uuid001"
                }
            ],
            "subscriber": {
                "app_user_id": "$RCAnonymousID:app_user001",
                "first_seen": 1705348159472,
                "last_seen": 1705348208003
            }
        }
        """#
        return (try? JSONDecoder.default.decode(Self.self, from: .init(string.utf8))) ?? .init()
    }()
}

extension RCTransactionDetailEvent {
    
    static let stub: Self = (RCTransactionDetailActivityResponse.stub.events?.first)!
}
