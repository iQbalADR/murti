import Foundation

/// A single action (Command pattern): a self-contained unit that performs one
/// action type. The vocabulary is CLOSED — these types are internal and fixed, so
/// a payload can never express arbitrary behavior, only pick one of them.
@MainActor
protocol MurtiCommand {
    func execute(spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async
}
