public protocol Draft {
    associatedtype Problem: Error

    var problems: [Problem] { get }
}

extension Draft {
    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
