//
//  File.swift
//  
//
//  Created by Evgeniy Romanishin on 09.12.2022.
//

import UIKit

extension UIImage {

    private static func localImage(_ name: String) -> UIImage? {
        UIImage(named: name, in: AMCameraScannerBundle.computeResourcesBundle(), with: nil)
    }

    static var chevronLeft: UIImage? { localImage("chevronLeft") }
    static var galleryIcon: UIImage? { localImage("galleryIcon") }
    static var flashOn: UIImage? { localImage("flashOn") }
    static var flashOff: UIImage? { localImage("flashOff") }
}
