import SwiftUI

@main
struct SteamControllerTesterApp: App {
    @State private var model = ControllerModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
