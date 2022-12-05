//
//  File.swift
//  
//
//  Created by Evgeniy Romanishin on 29.11.2022.
//

import UIKit

public extension AMCameraScanner {

    var closeButtonTitle: String? {
        get {
            closeButton.titleLabel?.text
        } set {
            closeButton.setTitle(newValue, for: .normal)
        }
    }

    var closeButtonImage: UIImage? {
        get {
            closeButton.imageView?.image
        } set {
            closeButton.setImage(newValue, for: .normal)
        }
    }

    var scanDescription: String? {
        get {
            descriptionText.text
        } set {
            descriptionText.text = newValue
        }
    }
}
