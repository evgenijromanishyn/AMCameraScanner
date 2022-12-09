//
//  File.swift
//  
//
//  Created by Evgeniy Romanishin on 29.11.2022.
//

import UIKit

public extension AMCameraScanner {

    var scanDescription: String? {
        get { descriptionText.text }
        set { descriptionText.text = newValue }
    }
}
