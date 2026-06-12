import OSLog

enum LumiereLogCategory: String, CaseIterable {
    case clipboardMonitor = "ClipboardMonitor"
    case coreML = "CoreML"
    case imageProcessing = "ImageProcessing"
    case annotation = "Annotation"
    case ui = "UI"
}

enum LumiereLogger {
    static let subsystem = "com.lumiere.app"

    #if DEBUG
    static let defaultMessageLevel: OSLogType = .debug
    #else
    static let defaultMessageLevel: OSLogType = .info
    #endif

    static func logger(for category: LumiereLogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    static let clipboardMonitor = logger(for: .clipboardMonitor)
    static let coreML = logger(for: .coreML)
    static let imageProcessing = logger(for: .imageProcessing)
    static let annotation = logger(for: .annotation)
    static let ui = logger(for: .ui)
}
