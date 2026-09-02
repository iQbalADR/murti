import SwiftUI
import UIKit
import MurtiCore

extension MurtiComponentFactory {
    /// Built-ins, with `image` overridden so a `url` loads a real photo and a missing
    /// named asset shows a labelled placeholder (a Figma export references layer
    /// names, not bundled assets) instead of a blank with console noise.
    static var preview: MurtiComponentFactory {
        withBuiltins.register("image") { node, _ in
            SDUIImage(
                systemName: node.string("systemName"),
                name: node.string("name"),
                url: node.string("url"),
                width: node.value("width")?.doubleValue.map { CGFloat($0) },
                height: node.value("height")?.doubleValue.map { CGFloat($0) },
                cornerRadius: node.value("cornerRadius")?.doubleValue.map { CGFloat($0) } ?? 0
            )
        }
    }
}

/// Renders an `image` node. A `url` loads a real photo; an SF Symbol or bundled
/// asset also work; a missing named asset falls back to a labelled placeholder.
struct SDUIImage: View {
    let systemName: String
    let name: String
    let url: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0

    var body: some View {
        content
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var content: some View {
        if !systemName.isEmpty {
            Image(systemName: systemName).resizable().aspectRatio(contentMode: .fit)
        } else if let embedded = Self.decodeDataURI(url) {
            Image(uiImage: embedded).resizable().aspectRatio(contentMode: .fill)
        } else if !url.isEmpty, let link = URL(string: url) {
            AsyncImage(url: link) { phase in
                switch phase {
                case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                case .empty: placeholder.overlay(ProgressView())
                case .failure: placeholder
                @unknown default: placeholder
                }
            }
        } else if !name.isEmpty, let asset = UIImage(named: name) {
            Image(uiImage: asset).resizable().aspectRatio(contentMode: .fill)
        } else {
            placeholder.overlay(
                Text(name.isEmpty ? "image" : name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(4)
            )
        }
    }

    private var placeholder: some View {
        Rectangle().fill(Color.secondary.opacity(0.12))
    }

    /// Decode a `data:image/…;base64,…` URL (the plugin's embedded pixels).
    private static func decodeDataURI(_ string: String) -> UIImage? {
        guard string.hasPrefix("data:"), let comma = string.firstIndex(of: ",") else { return nil }
        guard let data = Data(base64Encoded: String(string[string.index(after: comma)...])) else { return nil }
        return UIImage(data: data)
    }
}
