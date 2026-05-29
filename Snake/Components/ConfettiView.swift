import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    var colors: [UIColor] = [
        .systemRed, .systemGreen, .systemBlue, .systemYellow,
        .systemOrange, .systemPink, .systemPurple, .systemTeal
    ]
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -20)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 5.0
            cell.lifetimeRange = 1.5
            cell.velocity = CGFloat.random(in: 120...240)
            cell.velocityRange = 50
            cell.emissionLongitude = .pi // pointing down
            cell.emissionRange = .pi / 4 // small spread
            cell.spin = CGFloat.random(in: 1...3)
            cell.spinRange = 2.0
            cell.scale = 0.12
            cell.scaleRange = 0.08
            cell.contents = createConfettiImage(color: color)?.cgImage
            
            // physics-like properties
            cell.yAcceleration = 180
            cell.xAcceleration = CGFloat.random(in: -20...20)
            
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func createConfettiImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 80, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        color.setFill()
        
        // Randomly draw rectangles, circles or capsules
        let shapeType = Int.random(in: 0...2)
        if shapeType == 0 {
            ctx.fill(CGRect(origin: .zero, size: size))
        } else if shapeType == 1 {
            ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        } else {
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10)
            path.fill()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
