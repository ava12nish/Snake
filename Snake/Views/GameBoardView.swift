import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let boardSize = calculateBoardSize(geometrySize: geometry.size)
            
            Canvas { context, size in
                let cellWidth = boardSize.width / CGFloat(viewModel.columns)
                let cellHeight = boardSize.height / CGFloat(viewModel.rows)
                let cellSize = min(cellWidth, cellHeight)
                
                // Centering offsets
                let offsetX = (size.width - (cellSize * CGFloat(viewModel.columns))) / 2
                let offsetY = (size.height - (cellSize * CGFloat(viewModel.rows))) / 2
                
                // 1. Draw Grid Lines if enabled
                if viewModel.showGridLines {
                    context.stroke(
                        Path { path in
                            // Horizontal lines
                            for row in 0...viewModel.rows {
                                let y = offsetY + CGFloat(row) * cellSize
                                path.move(to: CGPoint(x: offsetX, y: y))
                                path.addLine(to: CGPoint(x: offsetX + CGFloat(viewModel.columns) * cellSize, y: y))
                            }
                            
                            // Vertical lines
                            for col in 0...viewModel.columns {
                                let x = offsetX + CGFloat(col) * cellSize
                                path.move(to: CGPoint(x: x, y: offsetY))
                                path.addLine(to: CGPoint(x: x, y: offsetY + CGFloat(viewModel.rows) * cellSize))
                            }
                        },
                        with: .color(viewModel.currentTheme.gridLineColor.opacity(0.4)),
                        lineWidth: 1
                    )
                }
                
                // 2. Draw Obstacles (Obstacles Mode)
                for obstacle in viewModel.obstacles {
                    let rect = CGRect(
                        x: offsetX + CGFloat(obstacle.x) * cellSize + 1.5,
                        y: offsetY + CGFloat(obstacle.y) * cellSize + 1.5,
                        width: cellSize - 3,
                        height: cellSize - 3
                    )
                    let path = Path(roundedRect: rect, cornerRadius: 4)
                    
                    // Draw outer border and inner fill
                    context.fill(path, with: .color(viewModel.currentTheme.obstacleColor))
                    context.stroke(path, with: .color(.black.opacity(0.4)), lineWidth: 1.5)
                }
                
                // 3. Draw Normal Food
                let foodRect = CGRect(
                    x: offsetX + CGFloat(viewModel.normalFood.x) * cellSize + 2,
                    y: offsetY + CGFloat(viewModel.normalFood.y) * cellSize + 2,
                    width: cellSize - 4,
                    height: cellSize - 4
                )
                let foodPath = Path(ellipseIn: foodRect)
                
                // Add soft glow to food
                context.fill(foodPath, with: .color(viewModel.currentTheme.foodColor))
                
                // 4. Draw Special Food (with pulsing effect if active)
                if let special = viewModel.specialFood {
                    let pulseFactor: CGFloat = viewModel.specialFoodTimeRemaining % 2 == 0 ? 1.0 : 0.8
                    let padding = ((cellSize - 4) * (1.0 - pulseFactor)) / 2
                    
                    let specialRect = CGRect(
                        x: offsetX + CGFloat(special.x) * cellSize + 2 + padding,
                        y: offsetY + CGFloat(special.y) * cellSize + 2 + padding,
                        width: (cellSize - 4) * pulseFactor,
                        height: (cellSize - 4) * pulseFactor
                    )
                    let specialPath = Path(ellipseIn: specialRect)
                    
                    context.fill(specialPath, with: .color(viewModel.currentTheme.specialFoodColor))
                    
                    // Inner star/circle details
                    let innerRect = specialRect.insetBy(dx: specialRect.width * 0.25, dy: specialRect.height * 0.25)
                    context.fill(Path(ellipseIn: innerRect), with: .color(.white))
                }
                
                // 5. Draw Snake
                let customColorHex = StorageService.shared.customSnakeColorHex
                let snakePrimaryColor = customColorHex != nil ? Color(hex: customColorHex!) : viewModel.currentTheme.primaryColor
                let snakeSecondaryColor = viewModel.currentTheme.secondaryColor
                
                for (index, segment) in viewModel.snake.enumerated() {
                    let rect = CGRect(
                        x: offsetX + CGFloat(segment.x) * cellSize + 1,
                        y: offsetY + CGFloat(segment.y) * cellSize + 1,
                        width: cellSize - 2,
                        height: cellSize - 2
                    )
                    
                    if index == 0 {
                        // Snake Head
                        let headPath = Path(roundedRect: rect, cornerRadius: cellSize * 0.4)
                        context.fill(headPath, with: .color(snakePrimaryColor))
                        
                        // Draw Eyes looking in current direction
                        drawEyes(
                            context: context,
                            rect: rect,
                            direction: viewModel.direction,
                            cellSize: cellSize
                        )
                    } else {
                        // Snake Body segments (interpolate color towards tail for cool gradient effect!)
                        let fraction = Double(index) / Double(max(viewModel.snake.count - 1, 1))
                        let bodyColor = lerpColor(from: snakePrimaryColor, to: snakeSecondaryColor, fraction: fraction)
                        
                        let bodyPath = Path(roundedRect: rect, cornerRadius: cellSize * 0.25)
                        context.fill(bodyPath, with: .color(bodyColor))
                    }
                }
            }
            .frame(width: boardSize.width, height: boardSize.height)
            .background(viewModel.currentTheme.boardColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.currentTheme.primaryColor.opacity(0.3), lineWidth: 2)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // Calculates a perfect square/aspect-ratio-locked game board size within the container
    private func calculateBoardSize(geometrySize: CGSize) -> CGSize {
        let maxCols = CGFloat(viewModel.columns)
        let maxRows = CGFloat(viewModel.rows)
        let targetAspect = maxCols / maxRows
        
        let containerAspect = geometrySize.width / geometrySize.height
        
        if containerAspect > targetAspect {
            // Container is wider than aspect ratio: height is limiting factor
            let height = geometrySize.height
            let width = height * targetAspect
            return CGSize(width: width, height: height)
        } else {
            // Container is taller than aspect ratio: width is limiting factor
            let width = geometrySize.width
            let height = width / targetAspect
            return CGSize(width: width, height: height)
        }
    }
    
    private func drawEyes(context: GraphicsContext, rect: CGRect, direction: Direction, cellSize: CGFloat) {
        let eyeSize = cellSize * 0.18
        var leftEye = CGPoint.zero
        var rightEye = CGPoint.zero
        
        switch direction {
        case .up:
            leftEye = CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.25)
            rightEye = CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.25)
        case .down:
            leftEye = CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.75)
            rightEye = CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.75)
        case .left:
            leftEye = CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.25)
            rightEye = CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.75)
        case .right:
            leftEye = CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.25)
            rightEye = CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.75)
        }
        
        // Draw white outer eyes
        let leftPath = Path(ellipseIn: CGRect(x: leftEye.x - eyeSize/2, y: leftEye.y - eyeSize/2, width: eyeSize, height: eyeSize))
        let rightPath = Path(ellipseIn: CGRect(x: rightEye.x - eyeSize/2, y: rightEye.y - eyeSize/2, width: eyeSize, height: eyeSize))
        
        context.fill(leftPath, with: .color(.white))
        context.fill(rightPath, with: .color(.white))
        
        // Pupils (black, slightly smaller)
        let pupilSize = eyeSize * 0.5
        let leftPupil = Path(ellipseIn: CGRect(x: leftEye.x - pupilSize/2, y: leftEye.y - pupilSize/2, width: pupilSize, height: pupilSize))
        let rightPupil = Path(ellipseIn: CGRect(x: rightEye.x - pupilSize/2, y: rightEye.y - pupilSize/2, width: pupilSize, height: pupilSize))
        
        context.fill(leftPupil, with: .color(.black))
        context.fill(rightPupil, with: .color(.black))
    }
    
    // Linear color interpolation helper
    private func lerpColor(from color1: Color, to color2: Color, fraction: Double) -> Color {
        // Resolve actual CGColors
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = Double(r1) + fraction * Double(r2 - r1)
        let g = Double(g1) + fraction * Double(g2 - g1)
        let b = Double(b1) + fraction * Double(b2 - b1)
        let a = Double(a1) + fraction * Double(a2 - a1)
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
