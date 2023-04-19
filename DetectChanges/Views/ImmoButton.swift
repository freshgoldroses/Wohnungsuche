//
//  ImmoButton.swift
//  DetectChanges
//
//  Created by Yuriy Gudimov on 15.03.2023.
//

import UIKit

@IBDesignable
class ImmoButton: CustomButton {
    
    override func setup() {
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = Colour.brandDark.setColor?.cgColor
        setTitle("🔗", for: .normal)
        
        let normalBackgroundColor = imageWithColor(Colour.brandBlue.setColor ?? .clear)
        setBackgroundImage(normalBackgroundColor, for: .normal)
        
        let highlightedBackgroundColor = imageWithColor(Colour.brandDark.setColor ?? .clear)
        setBackgroundImage(highlightedBackgroundColor, for: .highlighted)
    }
}
