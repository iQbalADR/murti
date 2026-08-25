import Foundation

/// The host-effect bridge. Navigation, dismissal, refresh, and link-opening are
/// UI concerns the app owns — commands call these closures rather than reaching
/// into a `NavigationStack` from the core. Every handler defaults to a no-op, so
/// it is trivial to wire partially (and to assert against in tests).
///
/// `navigate`'s params seed the target screen's fresh `DataContext` on the host
/// side — that is the first step of the data-context lifecycle.
@MainActor
public struct MurtiNavigator {
    public var navigate: (_ screen: String, _ params: [String: MurtiValue]) -> Void
    public var dismiss: () -> Void
    public var refresh: () -> Void
    public var openLink: (_ named: String) -> Void

    public init(
        navigate: @escaping (_ screen: String, _ params: [String: MurtiValue]) -> Void = { _, _ in },
        dismiss: @escaping () -> Void = {},
        refresh: @escaping () -> Void = {},
        openLink: @escaping (_ named: String) -> Void = { _ in }
    ) {
        self.navigate = navigate
        self.dismiss = dismiss
        self.refresh = refresh
        self.openLink = openLink
    }
}
