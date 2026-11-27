import Core
import DesignSystem
import FeatureModels
import SwiftUI
import UIKit

extension EntrySheet {
    var showsVoiceButton: Bool {
        voice.input.isAvailable && model.output.showsVoice
    }

    var voiceCard: some View {
        EntryVoiceCard(
            flow: voice,
            model: model,
            today: today,
            onCancel: cancelVoice,
            onFinish: {
                voice.perform {
                    await $0.finish()
                }
            },
            onOpenSettings: openVoiceSettings
        )
    }

    func voiceNoticeLayer(bottom: CGFloat) -> some View {
        VStack {
            Spacer(minLength: 0)

            if let notice = voice.state.notices.result.current {
                EntryVoiceNotice(notice: notice) {
                    withAnimation(.snappy) {
                        voice.undoLast(in: model)
                    }
                } onClose: {
                    withAnimation(.snappy) {
                        voice.clearNotice()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: voice.state.notices.result.current)
    }

    func startVoice() {
        voice.perform {
            await $0.start(for: model, today: today) {
                model.showSelectedCategory()
            }
        }
    }

    func cancelVoice() {
        guard voice.state.step != .denied else {
            voice.closeDenied()
            return
        }

        voice.perform {
            await $0.cancel()
        }
    }
}

private extension EntrySheet {
    func openVoiceSettings() {
        voice.closeDenied()

        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
