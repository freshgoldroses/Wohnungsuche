//
//  StartStopButton.swift
//  DetectChanges
//
//  Created by Yuriy Gudimov on 31.03.2023.
//

import UIKit

enum ImageState: String {
    case stop = "stop"
    case play = "play"
}

class StartStopButton: UIButton {
    var isOn = false
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        switchOff()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        layer.cornerRadius = 10
        layer.borderWidth = 1
    }
    
    func switchOn() {
        layer.borderColor = Colour.brandBlue.setColor?.cgColor
        backgroundColor = Colour.brandDark.setColor
        isOn = true
        switchImage(to: .play, color: Colour.brandBlue.setColor)
    }
    
    func switchOff() {
        layer.borderColor = Colour.brandDark.setColor?.cgColor
        backgroundColor = Colour.brandBlue.setColor
        isOn = false
        switchImage(to: .stop, color: Colour.brandDark.setColor)
    }
    
    private func switchImage(to imageState: ImageState, color: UIColor?) {
        guard let color = color else { return }
        let imageSize = CGSize(width: 40, height: 35)
        let imageRenderer = UIGraphicsImageRenderer(size: imageSize)
        let image = imageRenderer.image { context in
            let imageBounds = CGRect(origin: .zero, size: imageSize)
            UIImage(systemName: imageState.rawValue)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
                .draw(in: imageBounds)
        }
        setImage(image, for: .normal)
    }
}

