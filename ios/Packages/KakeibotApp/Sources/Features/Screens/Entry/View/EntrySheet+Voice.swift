import Core
import DesignSystem
import SwiftUI
import UIKit

extension EntrySheet {
    var showsVoiceButton: Bool {
        voice.isAvailable && model.showsVoice
    }

    var voiceLevels: [Double]? {
        voice.step == .listening ? voice.levels : nil
    }

    var voiceCard: some View {
        EntryVoiceCard(
            flow: voice,
            model: model,
            today: today,
            onCancel: cancelVoice,
            onFinish: {
                Task {
                    await voice.finish()
                }
            },
            onOpenSettings: openVoiceSettings
        )
    }

    func voiceButton(showsTitle: Bool) -> some View {
        EntryVoiceButton(
            showsTitle: showsTitle,
            glows: model.isLoaded && !model.voiceHintShown,
            onGlowed: {
                Task {
                    await model.markVoiceHintShown()
                }
            },
            action: startVoice
        )
    }

    func voiceNoticeLayer(bottom: CGFloat) -> some View {
        VStack {
            Spacer(minLength: 0)

            if let notice = voice.notice {
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
        .animation(.snappy, value: voice.notice)
    }

    func startVoice() {
        Task {
            await voice.start(for: model, today: today) {
                setEnteringAmount(false)
            }
        }
    }

    func cancelVoice() {
        guard voice.step != .denied else {
            voice.closeDenied()
            return
        }

        Task {
            await voice.cancel()
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
