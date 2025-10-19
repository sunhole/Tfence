//
//  ContentView.swift
//  Tfence
//
//  Created by vision on 10/19/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// MARK: - Location Manager (CoreLocation Logic)
// 위치 정보와 관련된 모든 로직을 처리하는 클래스
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // UI에 바인딩될 위치 및 거리 정보
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var distanceToTarget: CLLocationDistance = 0.0
    
    // 목표 지점: 강남역
    let targetLocation = CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
    let regionRadius: CLLocationDistance = 500 // 500미터 반경

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 1. 위치 정보 권한 요청
        self.locationManager.requestAlwaysAuthorization()
        
        // 2. 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한이 허용되었습니다.")
            }
        }
    }
    
    // 위치 추적 시작
    func startTracking() {
        self.locationManager.startUpdatingLocation()
        setupGeofence()
    }

    // CLLocationManagerDelegate 메소드: 위치가 업데이트될 때마다 호출됨
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            
            // ✅ Objective-C 클래스 호출!
            // 브릿징 헤더를 통해 Objective-C 코드를 Swift에서 직접 사용할 수 있습니다.
            self.distanceToTarget = DistanceCalculator.distanceBetween(self.targetLocation, to: location.coordinate)
        }
    }
    
    // 지오펜스 설정
    private func setupGeofence() {
        let region = CLCircularRegion(center: targetLocation, radius: regionRadius, identifier: "GangnamStation")
        region.notifyOnEntry = true
        region.notifyOnExit = false
        locationManager.startMonitoring(for: region)
    }
    
    // 지오펜스 영역에 진입했을 때 호출됨
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(title: "T-Fence 알림", body: "목표 지점 500m 이내에 접근했습니다!")
    }
    
    // 로컬 알림 전송
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startTracking()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 정보를 가져오는데 실패했습니다: \(error.localizedDescription)")
    }
}


// MARK: - MapView (MKMapView Wrapper)
// UIKit의 MKMapView를 SwiftUI에서 사용할 수 있도록 래핑하는 뷰
struct MapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    let targetLocation: CLLocationCoordinate2D
    let regionRadius: CLLocationDistance

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // 목표 지점에 핀 추가
        let annotation = MKPointAnnotation()
        annotation.coordinate = targetLocation
        annotation.title = "목표 지점"
        mapView.addAnnotation(annotation)
        
        // 목표 지점 주위에 원(경보 구역) 추가
        let circle = MKCircle(center: targetLocation, radius: regionRadius)
        mapView.addOverlay(circle)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let userLocation = userLocation {
            // 사용자와 목표 지점을 모두 포함하는 지역으로 지도 이동
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            uiView.setRegion(region, animated: true)
            uiView.showsUserLocation = true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // MKCircle 오버레이를 어떻게 그릴지 정의
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circleOverlay)
                circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
                circleRenderer.strokeColor = .blue
                circleRenderer.lineWidth = 1
                return circleRenderer
            }
            return MKOverlayRenderer()
        }
    }
}


// MARK: - ContentView (Main UI)

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack(alignment: .top) {
            // 지도 뷰
            MapView(
                userLocation: $locationManager.userLocation,
                targetLocation: locationManager.targetLocation,
                regionRadius: locationManager.regionRadius
            )
            .edgesIgnoringSafeArea(.all)

            // 상단 정보 패널
            VStack(spacing: 8) {
                Text("목표 지점까지의 거리")
                    .font(.headline)
                
                Text(String(format: "%.2f km", locationManager.distanceToTarget / 1000))
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top)
        }
        .onAppear {
            // 뷰가 나타날 때 위치 추적 시작
            locationManager.startTracking()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
