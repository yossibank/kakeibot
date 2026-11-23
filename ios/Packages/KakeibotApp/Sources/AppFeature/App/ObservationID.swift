struct ObservationID<Base: Hashable>: Hashable {
    let base: Base
    let round: Int
}
