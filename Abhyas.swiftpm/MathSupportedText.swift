import SwiftUI

/// Renders text with LaTeX math support
/// Usage: MathSupportedText("The equation is: $$ x^2 + y^2 = z^2 $$")
/// Inline math: $...$
/// Display math: $$...$$
struct MathSupportedText: View {
    let text: String
    @Environment(\.font) var font
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        let parts = parseMathSegments(text)
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(parts.indices, id: \.self) { index in
                let part = parts[index]
                
                switch part {
                case .text(let str):
                    Text(str)
                        .lineLimit(nil)
                
                case .inlineMath(let latex):
                    HStack(spacing: 0) {
                        Text("\\(\(latex)\\)")
                            .italic()
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(nil)
                    }
                
                case .displayMath(let latex):
                    VStack(alignment: .center, spacing: 8) {
                        Text("\\[\(latex)\\]")
                            .italic()
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(nil)
                            .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    // MARK: - Math Segment Parsing
    
    private enum MathSegment {
        case text(String)
        case inlineMath(String)
        case displayMath(String)
    }
    
    private func parseMathSegments(_ input: String) -> [MathSegment] {
        var segments: [MathSegment] = []
        var currentIndex = input.startIndex
        
        while currentIndex < input.endIndex {
            // Check for display math $$ first
            if input[currentIndex...].starts(with: "$$") {
                let startIndex = currentIndex
                currentIndex = input.index(currentIndex, offsetBy: 2)
                
                // Find closing $$
                if let closingRange = input[currentIndex...].range(of: "$$") {
                    let mathContent = String(input[currentIndex..<closingRange.lowerBound])
                    segments.append(.displayMath(mathContent))
                    currentIndex = closingRange.upperBound
                } else {
                    // No closing $$, treat as text
                    currentIndex = input.index(startIndex, offsetBy: 1)
                }
            }
            // Check for inline math $
            else if input[currentIndex] == "$" {
                let startIndex = currentIndex
                currentIndex = input.index(currentIndex, offsetBy: 1)
                
                // Find closing $
                if let closingRange = input[currentIndex...].range(of: "$") {
                    let mathContent = String(input[currentIndex..<closingRange.lowerBound])
                    // Ignore empty math or single characters that look accidental
                    if mathContent.count > 1 {
                        segments.append(.inlineMath(mathContent))
                        currentIndex = closingRange.upperBound
                    } else {
                        // Treat as regular text
                        currentIndex = closingRange.upperBound
                    }
                } else {
                    // No closing $, treat as text
                    currentIndex = input.index(startIndex, offsetBy: 1)
                }
            }
            // Regular text
            else {
                let nextMathIndex = findNextMath(in: input, startingFrom: currentIndex)
                let endIndex = nextMathIndex ?? input.endIndex
                
                let textContent = String(input[currentIndex..<endIndex])
                if !textContent.isEmpty {
                    segments.append(.text(textContent))
                }
                
                currentIndex = endIndex
            }
        }
        
        // If no segments were created, return the original text as plain text
        if segments.isEmpty && !input.isEmpty {
            segments.append(.text(input))
        }
        
        return segments
    }
    
    private func findNextMath(in text: String, startingFrom index: String.Index) -> String.Index? {
        let remaining = text[index...]
        
        if let inlineRange = remaining.range(of: "$") {
            return inlineRange.lowerBound
        }
        
        return nil
    }
}
