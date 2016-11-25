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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!

//USe this to ensure map will only cente when requested not every update
    var mapHasCenteredOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        //This links to
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
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
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
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

    //CHANGE ME WHEN DOING EXTRA
    @IBAction func SpotRandomPokemon(_ sender: Any) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(151) + 1
        
        createSighting(forLocation: loc, withPokemon: Int(rand))
        
        
    }
    
    
    
    
    
}

























