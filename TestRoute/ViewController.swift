//
//  ViewController.swift
//  TestRoute
//
//  Created by Alik Nigay on 16.05.2022.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    private var annotationArray = [MKPointAnnotation]()
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    let addButton: UIButton = {
        let addButton = UIButton()
        addButton.setTitle("Add", for: .normal)
        addButton.setTitleColor(UIColor.systemBlue, for: .normal)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        return addButton
    }()
    
    let routeButton: UIButton = {
        let routeButton = UIButton()
        routeButton.setImage(UIImage(systemName: "arrow.triangle.swap"), for: .normal)
        routeButton.setTitle("Route", for: .normal)
        routeButton.setTitleColor(UIColor.systemBlue, for: .normal)
        routeButton.translatesAutoresizingMaskIntoConstraints = false
        routeButton.isEnabled = false
        return routeButton
    }()
    
    let resetButton: UIButton = {
        let resetButton = UIButton()
        resetButton.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(UIColor.systemBlue, for: .normal)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.isEnabled = false
        return resetButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTargetForButton()
        setupUIView()
        mapView.delegate = self
    }
    
    @objc func addButtonPressed() {
        showAlert(title: "Add", placeholder: "Enter address") { text in
            self.setupPlacemark(addressPlace: text)
        }
    }
    
    @objc func routeButtonPressed() {
        for index in 0...annotationArray.count - 2 {
            createDirectionRequest(start: annotationArray[index].coordinate, destination: annotationArray[index + 1].coordinate)
        }
        mapView.showAnnotations(annotationArray, animated: true)
    }
    
    @objc func resetButtonPressed() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        annotationArray.removeAll()
        stateButtons(state: true)
    }
    
    private func setupPlacemark(addressPlace: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressPlace) { [self] placemarks, error in
            guard let placemarks = placemarks else {
                print(error?.localizedDescription ?? "No error description")
                showError(title: "Ошибка", message: "Сервер недоступен. Попробуйте добавить адрес еще раз")
                return
            }
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = addressPlace
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            annotationArray.append(annotation)
            
            if annotationArray.count > 2 {
                stateButtons(state: true)
            }
            
            mapView.showAnnotations(annotationArray, animated: true)
        }
    }
    
    private func createDirectionRequest(start: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let startLocation = MKPlacemark(coordinate: start)
        let destinationLocation = MKPlacemark(coordinate: destination)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
        direction.calculate { response, error in
            guard let response = response else {
                print(error?.localizedDescription ?? "No Error description")
                self.showError(title: "Ошибка", message: "Маршрут недоступен")
                return
            }
            
            var minRoute = response.routes[0]
            
            for route in response.routes {
                minRoute = route.distance < minRoute.distance ? route : minRoute
            }
            
            self.mapView.addOverlay(minRoute.polyline)
        }
    }
    
    private func setupTargetForButton() {
        addButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        routeButton.addTarget(self, action: #selector(routeButtonPressed), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonPressed), for: .touchUpInside)
    }

    private func setupUIView() {
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50),
            addButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -10),
            addButton.heightAnchor.constraint(equalToConstant: 70),
            addButton.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        view.addSubview(routeButton)
        NSLayoutConstraint.activate([
            routeButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -30),
            routeButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 10),
            routeButton.heightAnchor.constraint(equalToConstant: 70),
            routeButton.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        view.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50),
            resetButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 10),
            resetButton.heightAnchor.constraint(equalToConstant: 70),
            resetButton.widthAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func stateButtons(state: Bool) {
        routeButton.isEnabled = state
        resetButton.isEnabled = state
    }
}

//MARK: - Alert Controllers
extension ViewController {
    private func showAlert(title: String, placeholder: String, completion: @escaping(String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let searchButton = UIAlertAction(title: "Search", style: .default) { action in
            guard let text = alert.textFields?.first?.text else { return }
            completion(text)
        }
        let okButton = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addTextField { textField in
            textField.placeholder = placeholder
        }
        alert.addAction(searchButton)
        alert.addAction(okButton)
        present(alert, animated: true)
    }
    
    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

//MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        return render
    }
}

