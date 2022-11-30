//
//  File.swift
//  
//
//  Created by Evgeniy Romanishin on 30.11.2022.
//

import Foundation

extension String {
    var digitsAndSpace: Bool { self.reduce(true) { $0 && (($1 >= "0" && $1 <= "9") || $1 == " ") } }
}
