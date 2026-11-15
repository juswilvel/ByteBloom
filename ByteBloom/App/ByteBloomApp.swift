import SwiftUI

@main
struct ByteBloomApp: App {
    @State private var model = BloomModel()

    var body: some Scene {
        Window("ByteBloom", id: "main") {
            ContentView(model: model)
        }
        .defaultSize(width: 1000, height: 850)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Choose a File…", action: model.chooseFile)
                    .keyboardShortcut("o").disabled(!model.canImport)
                Button("Export PNG…", action: model.chooseExport)
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(model.result == nil || model.isBusy || model.isPanelPresented)
            }
        }
    }
}
