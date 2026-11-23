import Foundation
import WidgetKit

protocol WidgetFallbackEntry: TimelineEntry, Sendable {
    static func empty(at date: Date) -> Self
    static func sample(at date: Date) -> Self
}
