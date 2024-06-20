//
//  WishKit.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 2/9/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

#if canImport(UIKit)
    import UIKit
#endif

import Combine
import SwiftUI
import WishKitShared

public enum WishKit {
    private static var subscribers: Set<AnyCancellable> = []

    static var apiKey = "my-fancy-api-key"

    static var user = User()

    public static var theme = Theme()

    public static var config = Configuration()

    #if canImport(UIKit) && !os(visionOS)
        /// (UIKit) The WishList viewcontroller.
        public static var viewController: UIViewController {
            UIHostingController(rootView: WishlistViewIOS(closeAction: {}, wishModel: WishModel()))
        }
    #endif

    /// (SwiftUI) The WishList view.

    public static func view(closeAction: @escaping () -> Void) -> some View {
        #if os(macOS) || os(visionOS)
            return WishlistContainer(wishModel: WishModel())
        #else
            return WishlistViewIOS(closeAction: closeAction, wishModel: WishModel())
        #endif
    }

    public static var view: some View {
        #if os(macOS) || os(visionOS)
            return WishlistContainer(wishModel: WishModel())
        #else
        return WishlistViewIOS(closeAction: {}, wishModel: WishModel())
        #endif
    }

    public static func configure(with apiKey: String) {
        WishKit.apiKey = apiKey
    }
}

// MARK: - Payment Model

class RoundUp: NSDecimalNumberBehaviors {
    func scale() -> Int16 {
        return 0
    }

    func exceptionDuringOperation(_ operation: Selector, error: NSDecimalNumber.CalculationError, leftOperand: NSDecimalNumber, rightOperand: NSDecimalNumber?) -> NSDecimalNumber? {
        return 0
    }

    func roundingMode() -> NSDecimalNumber.RoundingMode {
        .up
    }
}

public struct Payment {
    let amount: Int

    // MARK: - Weekly

    /// Accepts a price expressed in `Decimal` e.g: 2.99 or 11.49
    public static func weekly(_ amount: Decimal) -> Payment {
        let amount = NSDecimalNumber(decimal: amount * 100).intValue
        let amountPerMonth = amount * 4
        return Payment(amount: amountPerMonth)
    }

    // MARK: - Monthly

    /// Accepts a price expressed in `Decimal` e.g: 6.99 or 19.49
    public static func monthly(_ amount: Decimal) -> Payment {
        let amount = NSDecimalNumber(decimal: amount * 100).intValue
        return Payment(amount: amount)
    }

    // MARK: - Yearly

    /// Accepts a price expressed in `Decimal` e.g: 6.99 or 19.49
    public static func yearly(_ amount: Decimal) -> Payment {
        let amountPerMonth = NSDecimalNumber(decimal: (amount * 100) / 12).rounding(accordingToBehavior: RoundUp()).intValue
        return Payment(amount: amountPerMonth)
    }
}

// MARK: - Update User Logic

public extension WishKit {
    static func updateUser(customID: String) {
        user.customID = customID
        sendUserToBackend()
    }

    static func updateUser(email: String) {
        user.email = email
        sendUserToBackend()
    }

    static func updateUser(name: String) {
        user.name = name
        sendUserToBackend()
    }

    static func updateUser(payment: Payment) {
        user.payment = payment
        sendUserToBackend()
    }

    internal static func sendUserToBackend() {
        Task {
            let request = user.createRequest()
            _ = await UserApi.updateUser(userRequest: request)
        }
    }
}
