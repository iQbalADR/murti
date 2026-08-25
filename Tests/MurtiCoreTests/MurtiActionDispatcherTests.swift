import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("MurtiActionDispatcher")
struct MurtiActionDispatcherTests {

    /// Captures host effects so tests can assert what a command drove.
    @MainActor
    final class Recorder {
        var navigatedTo: String?
        var navParams: [String: MurtiValue] = [:]
        var dismissed = false
        var refreshed = false
        var openedLink: String?

        var navigator: MurtiNavigator {
            MurtiNavigator(
                navigate: { self.navigatedTo = $0; self.navParams = $1 },
                dismiss: { self.dismissed = true },
                refresh: { self.refreshed = true },
                openLink: { self.openedLink = $0 }
            )
        }
    }

    struct MockNetwork: MurtiNetworkClient {
        var response: Data?
        var fail = false
        func perform(_ request: NamedRequest, params: [String: MurtiValue]) async throws -> Data {
            if fail { throw MurtiError.network(status: 500) }
            return response ?? Data()
        }
    }

    @Test func navigatePassesScreenAndParams() async {
        let recorder = Recorder()
        let dispatcher = MurtiActionDispatcher(navigator: recorder.navigator)
        await dispatcher.dispatch(
            MurtiActionSpec(type: .navigate, screen: "detail", params: ["id": .string("7")]),
            data: DataContext()
        )
        #expect(recorder.navigatedTo == "detail")
        #expect(recorder.navParams["id"] == .string("7"))
    }

    @Test func dismissRefreshAndOpenLink() async {
        let recorder = Recorder()
        let dispatcher = MurtiActionDispatcher(navigator: recorder.navigator)
        await dispatcher.dispatch(MurtiActionSpec(type: .dismiss), data: DataContext())
        await dispatcher.dispatch(MurtiActionSpec(type: .refresh), data: DataContext())
        await dispatcher.dispatch(MurtiActionSpec(type: .openURL, link: "helpCenter"), data: DataContext())
        #expect(recorder.dismissed)
        #expect(recorder.refreshed)
        #expect(recorder.openedLink == "helpCenter")
    }

    @Test func apiMergesResponseThenRunsOnSuccess() async {
        let recorder = Recorder()
        let network = MockNetwork(response: Data(#"{ "amount": 100 }"#.utf8))
        let dispatcher = MurtiActionDispatcher(network: network, navigator: recorder.navigator)
        let data = DataContext()
        await dispatcher.dispatch(
            MurtiActionSpec(
                type: .api, request: "getAccountBalance",
                onSuccess: MurtiActionSpec(type: .navigate, screen: "balanceDetail")
            ),
            data: data
        )
        #expect(data.value(forKeyPath: "getAccountBalance.amount") == .number(100))
        #expect(recorder.navigatedTo == "balanceDetail")
    }

    @Test func apiFailureRunsOnError() async {
        let recorder = Recorder()
        let dispatcher = MurtiActionDispatcher(network: MockNetwork(fail: true), navigator: recorder.navigator)
        await dispatcher.dispatch(
            MurtiActionSpec(type: .api, request: "x", onError: MurtiActionSpec(type: .refresh)),
            data: DataContext()
        )
        #expect(recorder.refreshed)
    }

    @Test func defaultClientMakesEveryRequestFailClosed() async {
        let recorder = Recorder()
        let dispatcher = MurtiActionDispatcher(navigator: recorder.navigator)   // NoNetworkClient
        await dispatcher.dispatch(
            MurtiActionSpec(type: .api, request: "anything", onError: MurtiActionSpec(type: .dismiss)),
            data: DataContext()
        )
        #expect(recorder.dismissed)
    }
}
