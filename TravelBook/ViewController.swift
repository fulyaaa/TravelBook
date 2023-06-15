//
//  ViewController.swift
//  TravelBook
//
//  Created by fulya akan on 14.06.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var anotationTitle = ""
    var anotationSubtitle = ""
    var anotationLatitude = Double()
    var anotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //bu protokollerden bazi fonk kullanacagimizi soyluyoruz
        mapView.delegate = self
        locationManager.delegate = self
        //lokasyonun kesinligi
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //kullanici izni istiyoruz
        locationManager.requestWhenInUseAuthorization()
        //kullanicinin yerinin almaya basliyoruz
        locationManager.startUpdatingLocation()
        
        //kullanici parmak etkilesimi
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(choosenLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            //CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String{
                            anotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                anotationSubtitle = subtitle
                                
                                if let subtitle = result.value(forKey: "subtitle") as? String{
                                    anotationSubtitle = subtitle
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        anotationLongitude = longitude
                                        
                                        let anotation = MKPointAnnotation()
                                        anotation.title = anotationTitle
                                        anotation.subtitle = anotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: anotationLatitude, longitude: anotationLongitude)
                                        anotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(anotation)
                                        nameText.text = anotationTitle
                                        commentText.text = anotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
            
        }else{
            //Add New Data
        }
        
    }
    
    @objc func choosenLocation(gestureRecognizer: UILongPressGestureRecognizer){
        
        //guncel durum, gesture recog.  basladi mi - state
        if gestureRecognizer.state == .began{
            
            //secilen koordinat
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            //koordinata ceviriliyor
            let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchCoordinates.latitude
            chosenLongitude = touchCoordinates.longitude
            
            //pin olusturma
            let annotatioin = MKPointAnnotation()
            annotatioin.coordinate = touchCoordinates
            annotatioin.title = nameText.text
            annotatioin.subtitle = commentText.text
            self.mapView.addAnnotation(annotatioin)
        }
            
    }
    
    
    //lokasyonu aldik, ne yapacagiz
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
        //enlem boylam olusturuyoruz, kendi loc alıyoruz
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        } else {
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: anotationLatitude, longitude: anotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.anotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                
                }
                
            }
            
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //coredataya ulasiyoruz
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("succes")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newPlace") , object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}

