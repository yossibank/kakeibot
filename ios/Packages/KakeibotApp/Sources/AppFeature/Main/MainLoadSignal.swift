import SwiftUI

struct MainLoadSignal: View {
    let isLoaded: () -> Bool
    let onLoad: () -> Void

    var body: some View {
        let isLoaded = isLoaded()

        Color.clear
            .onChange(of: isLoaded, initial: true) {
                if isLoaded {
                    onLoad()
                }
            }
    }
}
