public extension EditFlow {
    func toggleHidden() {
        if output.asksBeforeHiding {
            state.prompt.show(.hide)
        } else {
            continueHiding()
        }
    }

    func continueHiding() {
        if output.isChanged {
            state.prompt.show(.hideChanges)
        } else {
            setHidden(!output.isHidden)
        }
    }

    @discardableResult
    func setHidden(_ isHidden: Bool) -> Task<Void, Never> {
        Task {
            await saveHidden(isHidden)
        }
    }

    @discardableResult
    func saveTogglingHidden() -> Task<Void, Never> {
        Task {
            await run { source in
                guard
                    let saved = await store(in: source),
                    !source.keepsOpen(after: saved)
                else {
                    return
                }

                await toggleHidden(after: saved, in: source)
            }
        }
    }
}

private extension EditFlow {
    func saveHidden(_ isHidden: Bool) async {
        guard output.isEditing else {
            return
        }

        await run { source in
            do {
                try await source.storeHidden(isHidden)
                state.outcome.send(Outcome(isHidden: isHidden))
            } catch {
                showHideFailure(error, in: source)
            }
        }
    }

    func toggleHidden(
        after saved: Saved,
        in source: any EditFlowSource<Saved>
    ) async {
        guard source.isEditing else {
            finish(saved: saved)
            return
        }

        let isHidden = !source.isHidden

        do {
            try await source.storeHidden(isHidden)
            state.outcome.send(Outcome(saved: saved, isHidden: isHidden))
        } catch {
            showHideFailure(error, in: source)
            state.outcome.send(Outcome(saved: saved, closes: false))
        }
    }

    func showHideFailure(
        _ error: any Error,
        in source: any EditFlowSource<Saved>
    ) {
        let message = source.hideFailedMessage(for: error)
        source.state.errorNotice.show(message, for: error)
    }
}
