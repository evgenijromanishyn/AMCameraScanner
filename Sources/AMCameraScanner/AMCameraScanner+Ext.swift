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

    var torchButtonTitle: String? {
        get {
            torchButton.titleLabel?.text
        } set {
            torchButton.setTitle(newValue, for: .normal)
        }
    }

    var torchButtonImage: UIImage? {
        get {
            torchButton.imageView?.image
        } set {
            torchButton.setImage(newValue, for: .normal)
        }
    }

}
