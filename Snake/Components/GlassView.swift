import SwiftUI

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.08
    var borderColor: Color = Color.white.opacity(0.15)
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
                    .background(
                        VisualEffectBlur(style: .dark)
                            .cornerRadius(cornerRadius)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                borderColor,
                                borderColor.opacity(0.2),
                                Color.clear,
                                borderColor.opacity(0.1),
                                borderColor
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassStyle(cornerRadius: CGFloat = 16, opacity: Double = 0.08, borderColor: Color = Color.white.opacity(0.15)) -> some View {
        self.modifier(GlassModifier(cornerRadius: cornerRadius, opacity: opacity, borderColor: borderColor))
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterialDark
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

