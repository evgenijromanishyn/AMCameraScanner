//
//  File.swift
//  
//
//  Created by Evgeniy Romanishin on 30.11.2022.
//

import Foundation

extension String {
    var digitsAndSpace: Bool {
        let digits = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let intValue = Int(digits) else { return false }
        return "\(intValue)".count >= 4
        //self.reduce(true) { $0 && (($1 >= "0" && $1 <= "9") || $1 == " ") }
    }
}
