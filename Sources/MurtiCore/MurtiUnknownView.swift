import SwiftUI

/// The Null-Object fallback: a safe placeholder for an unregistered component
/// type, so an unknown or forward-incompatible node degrades gracefully rather
/// than crashing. Blank in release; a subtle marker in debug builds.
struct MurtiUnknownView: View {
    let type: String

    var body: some View {
        #if DEBUG
        Text("⚠︎ unknown: \(type)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.4)))
            .accessibilityHidden(true)
        #else
        EmptyView()
        #endif
    }
}
