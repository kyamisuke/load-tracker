import Foundation
import CoreLocation

enum RecordingState: Equatable {
    case idle
    case recording
    case interrupted
}

protocol LocationTrackingServiceProtocol: ObservableObject {
    var state: RecordingState { get }
    var currentLocation: CLLocation? { get }
    func startRecording() async throws
    func stopRecording() async
}
