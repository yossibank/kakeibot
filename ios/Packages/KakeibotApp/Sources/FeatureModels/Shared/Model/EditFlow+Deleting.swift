public extension EditFlow {
    @discardableResult
    func delete() -> Task<Void, Never> {
        Task {
            await remove()
        }
    }
}

private extension EditFlow {
    func remove() async {
        guard output.isEditing else {
            return
        }

        await run { source in
            do {
                let deletion = try await source.remove()
                state.outcome.send(Outcome(deletion: deletion))
            } catch {
                showDeleteFailure(error, in: source)
            }
        }
    }

    func showDeleteFailure(
        _ error: any Error,
        in source: any EditFlowSource<Saved>
    ) {
        let message = source.deleteFailedMessage(for: error)
        source.state.errorNotice.show(message, for: error)
    }
}
