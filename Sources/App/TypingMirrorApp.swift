import SwiftData
import SwiftUI
import TypingMirrorKit

@main
struct TypingMirrorApp: App {
    @State private var model: AppModel
    private let container: ModelContainer

    init() {
        // A failure here means the on-disk store is unreadable; falling back to
        // memory keeps the app usable rather than dead on launch.
        let container = (try? StoreFactory.container())
            ?? (try! StoreFactory.container(inMemory: true))
        self.container = container
        _model = State(initialValue: AppModel(store: SessionStore(modelContainer: container)))
    }

    var body: some Scene {
        WindowGroup("TypingMirror") {
            RootView()
                .environment(model)
                .frame(minWidth: Tk.L.windowMinWidth, minHeight: Tk.L.windowMinHeight)
                .preferredColorScheme(.dark)
        }
        .windowResizability(.contentMinSize)
        .modelContainer(container)
    }
}
