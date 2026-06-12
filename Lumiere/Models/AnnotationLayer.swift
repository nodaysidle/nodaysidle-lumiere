import Foundation

struct AnnotationLayer: Codable, Sendable {
    var annotations: [Annotation] = []
    var zOrder: [UUID] = []

    init(annotations: [Annotation] = []) {
        self.annotations = annotations
        self.zOrder = annotations.map { $0.id }
    }

    mutating func addAnnotation(_ annotation: Annotation) {
        annotations.append(annotation)
        zOrder.append(annotation.id)
    }

    mutating func removeAnnotation(id: UUID) {
        annotations.removeAll { $0.id == id }
        zOrder.removeAll { $0 == id }
    }

    mutating func moveAnnotation(id: UUID, toIndex: Int) {
        guard let currentIndex = zOrder.firstIndex(of: id) else { return }
        zOrder.remove(at: currentIndex)
        zOrder.insert(id, at: min(toIndex, zOrder.count))
    }

    mutating func replaceAll(with annotations: [Annotation]) {
        self.annotations = annotations
        zOrder = annotations.map(\.id)
    }

    func getAnnotationsInZOrder() -> [Annotation] {
        zOrder.compactMap { id in
            annotations.first { $0.id == id }
        }
    }
}
