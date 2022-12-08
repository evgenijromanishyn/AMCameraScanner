//
//  StripeCardScanBundleLocator.swift
//  StripeCardScan
//
//  Created by Sam King on 11/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// :nodoc:
final class AMCameraScannerBundle: BundleLocatorProtocol {
    static let internalClass: AnyClass = AMCameraScannerBundle.self
    static let bundleName = "AMCameraScannerBundle"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = AMCameraScannerBundle.computeResourcesBundle()
}
