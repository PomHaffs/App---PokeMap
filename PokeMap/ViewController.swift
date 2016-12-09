//
//  ViewController.swift
//  PokeMap
//
//  Created by Tomas-William Haffenden on 25/11/16.
//  Copyright © 2016 PomHaffs. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!

//Use this to ensure map will only cente when requested not every update
    var mapHasCenteredOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
//This links to GeoFire etc...
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)

//ADDED for picker view
        pokePicker.dataSource = self
        pokePicker.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    
//This is the check that we have been granted permission to use geolocation by user, if not permission is requested.
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

//User says YES/NO then we run to find location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }

//2000x2000 refers to how it zooms when finding center
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
//Allows map to center the first time you press not everytime
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }

//This allows us to define the image that is used for center, not just blue dot
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView?
//need this for dequeue below
        let annoIdentifier = "Pokemon"
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAnno
            annotationView?.annotation = annotation
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
         
//this is linked to self.title in pokeAnnotation and will not work without title being declared
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
        
        }
        
        return annotationView
    }
    
//Select pokemon from list and store it to a location .setLocation is geoFire method
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
       
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
//Display sightings on map from GeoFire databse (withRadius is in KM), pokemonNumber is the uniquekey in DB needed to grab coordinates
    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(GFEventType.keyEntered, with: {
            (key, location) in
           
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                //Adds to map
                self.mapView.addAnnotation(anno)
            }
        })
    }
 
//This is showing the Pokemon on the map
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingsOnMap(location: loc)
    }
   
//allow for travel directions to be linked - placemarking for start and end are required.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnnotation {
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }
    

//CHANGES added IBoutlet fo picker
    @IBAction func SpotRandomPokemon(_ sender: Any) {
        pokePicker.isHidden = false
 
        //MOVED to below function in a effort to finished task.
//        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
//        
//        let rand = arc4random_uniform(151) + 1
//        
//        createSighting(forLocation: loc, withPokemon: Int(rand))
        
    }
    
//ADDED to link picker view
    @IBOutlet weak var pokePicker: UIPickerView!
    
//ADDED to adhire to requirements of UIPickerViewDataSource and Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pokemon.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pokemon[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        var pokeIndex = pokemon.index(of: "\(pokemon[row])")
        pokeIndex = Int(pokeIndex!) + 1
        
        createSighting(forLocation: loc, withPokemon: pokeIndex!)
        
        pokePicker.isHidden = true
    }
    
}

























