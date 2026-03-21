import Foundation

protocol StaySpotDetectionServiceProtocol {
    func detectSpots(in points: [RoutePoint]) -> [StaySpot]
    mutating func updateOpenCluster(with point: RoutePoint) -> StaySpot?
    mutating func reset()
}
