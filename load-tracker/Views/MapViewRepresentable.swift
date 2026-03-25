import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    let routePoints: [RoutePoint]
    let staySpots: [StaySpot]
    @Binding var centerOnUser: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateOverlays(on: mapView, with: routePoints)
        context.coordinator.updateAnnotations(on: mapView, with: staySpots)
        if centerOnUser {
            mapView.userTrackingMode = .follow
            DispatchQueue.main.async { centerOnUser = false }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        private var currentLOD: DouglasPeucker.SimplifiedRoute?
        private var lastZoomSpan: Double = 0

        func updateOverlays(on mapView: MKMapView, with points: [RoutePoint]) {
            mapView.removeOverlays(mapView.overlays)
            guard !points.isEmpty else { return }

            currentLOD = DouglasPeucker.precomputeLOD(from: points)
            let coords = selectLOD(for: mapView.region.span)
            addPolylineOverlays(to: mapView, points: points, coords: coords)
        }

        func updateAnnotations(on mapView: MKMapView, with staySpots: [StaySpot]) {
            let existing = mapView.annotations.compactMap { $0 as? StaySpotAnnotation }
            mapView.removeAnnotations(existing)

            let annotations = staySpots.map { StaySpotAnnotation(staySpot: $0) }
            mapView.addAnnotations(annotations)
        }

        private func selectLOD(for span: MKCoordinateSpan) -> [CLLocationCoordinate2D] {
            guard let lod = currentLOD else { return [] }
            let zoomSpan = max(span.latitudeDelta, span.longitudeDelta)
            if zoomSpan < 0.005 { return lod.full }
            if zoomSpan < 0.05 { return lod.medium }
            return lod.coarse
        }

        private func addPolylineOverlays(to mapView: MKMapView, points: [RoutePoint], coords: [CLLocationCoordinate2D]) {
            guard !coords.isEmpty else { return }
            // Split into segments by accuracy
            var normalSegment: [CLLocationCoordinate2D] = []
            var lowAccSegment: [CLLocationCoordinate2D] = []

            for (i, point) in points.enumerated() {
                guard i < coords.count else { break }
                let coord = coords[i < coords.count ? i : coords.count - 1]
                if point.isLowAccuracy {
                    if !normalSegment.isEmpty {
                        let polyline = MKPolyline(coordinates: normalSegment, count: normalSegment.count)
                        polyline.title = "normal"
                        mapView.addOverlay(polyline)
                        normalSegment = [coord]
                    }
                    lowAccSegment.append(coord)
                } else {
                    if !lowAccSegment.isEmpty {
                        let polyline = MKPolyline(coordinates: lowAccSegment, count: lowAccSegment.count)
                        polyline.title = "lowAccuracy"
                        mapView.addOverlay(polyline)
                        lowAccSegment = [coord]
                    }
                    normalSegment.append(coord)
                }
            }
            if normalSegment.count > 1 {
                let polyline = MKPolyline(coordinates: normalSegment, count: normalSegment.count)
                polyline.title = "normal"
                mapView.addOverlay(polyline)
            }
            if lowAccSegment.count > 1 {
                let polyline = MKPolyline(coordinates: lowAccSegment, count: lowAccSegment.count)
                polyline.title = "lowAccuracy"
                mapView.addOverlay(polyline)
            }
        }

        // MARK: - MKMapViewDelegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            if polyline.title == "lowAccuracy" {
                renderer.strokeColor = .appDust
                renderer.lineWidth = 2
                renderer.lineDashPattern = [8, 4]
            } else {
                renderer.strokeColor = .appAmber
                renderer.lineWidth = 4
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let stayAnnotation = annotation as? StaySpotAnnotation else { return nil }
            let id = "StaySpot"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: stayAnnotation, reuseIdentifier: id)
            view.annotation = stayAnnotation
            view.markerTintColor = .appAmber
            view.glyphImage = UIImage(systemName: "mappin.circle.fill")
            view.canShowCallout = true
            return view
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard let lod = currentLOD else { return }
            let zoomSpan = max(mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta)
            let oldLevel: Int = lastZoomSpan < 0.005 ? 0 : (lastZoomSpan < 0.05 ? 1 : 2)
            let newLevel: Int = zoomSpan < 0.005 ? 0 : (zoomSpan < 0.05 ? 1 : 2)
            lastZoomSpan = zoomSpan
            if oldLevel != newLevel {
                mapView.removeOverlays(mapView.overlays)
                let coords = selectLOD(for: mapView.region.span)
                guard !coords.isEmpty else { return }
                var allCoords = coords
                let polyline = MKPolyline(coordinates: &allCoords, count: allCoords.count)
                mapView.addOverlay(polyline)
            }
        }
    }
}

// MARK: - StaySpotAnnotation

class StaySpotAnnotation: NSObject, MKAnnotation {
    let staySpot: StaySpot
    var coordinate: CLLocationCoordinate2D { staySpot.coordinate }
    var title: String? { staySpot.formattedDuration }
    var subtitle: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let arrived = formatter.string(from: staySpot.arrivedAt)
        let departed = staySpot.departedAt.map { formatter.string(from: $0) } ?? "滞在中"
        return "\(arrived) → \(departed)"
    }

    init(staySpot: StaySpot) {
        self.staySpot = staySpot
    }
}
