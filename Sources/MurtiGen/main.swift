import Foundation
import MurtiBuilder

// Author your screens here. Loop over data to emit lists — that is the templating.
let screens: [Screen] = [
    Screen("home") {
        VStack(spacing: 12, alignment: .leading) {
            Text("Welcome, {{user.name}}", style: .title)
            Button("Get started", action: .navigate("onboarding"))
        }
    }
]

let output = URL(filePath: CommandLine.arguments.dropFirst().first ?? "Generated")
try ScreenBundle(screens: screens).write(to: output)
print("Wrote \(screens.count) screen(s) to \(output.path)")
