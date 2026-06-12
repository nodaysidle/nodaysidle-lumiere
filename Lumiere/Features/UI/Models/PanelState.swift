import CoreGraphics

enum PanelState: Equatable, Sendable {
    case hidden
    case revealing(progress: CGFloat)
    case visible
    case dismissing(progress: CGFloat)

    var isVisible: Bool {
        switch self {
        case .visible:
            return true
        case .revealing(let progress):
            return progress > 0.5
        default:
            return false
        }
    }

    var progress: CGFloat {
        switch self {
        case .hidden:
            return 0
        case .revealing(let progress):
            return progress
        case .visible:
            return 1
        case .dismissing(let progress):
            return 1 - progress
        }
    }
}
