//
//  ViewController.swift
//  iSpend-iOS
//
//  Created by Srdjan Tubin on 21.09.19.
//  Copyright © 2019 serj. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var tfUsername: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var btnLogin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tfUsername.delegate = self
        tfPassword.delegate = self
    }
    
    @IBAction func login(_ sender: Any) {
        doLogin { result in
            switch result {
            case .success(let response):
                print(response)
                self.showMessage(title: "iSpend Login Success", message: response)
            case .failure(let error):
                print(error.localizedDescription)
                self.showMessage(title: "iSpend Login Error", message: error.localizedDescription)
            }
        }
    }
    
    func doLogin(completion: @escaping (Result<String, Error>) -> Void) {
        let username = tfUsername.text!
        let password = tfPassword.text!
        if (username == "" || password == "") {
            showMessage(title: "iSpend Login", message: "Error! Credentials empty.")
            return
        }
        
        let url = URL(string: "http://www.serjspends.de/users/login")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "username": username,
            "password": password
        ]
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString!)")
            
            DispatchQueue.main.async {
                completion(.success(responseString!))
            }
        }.resume()
    }
    
    func showMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tfUsername.resignFirstResponder()
        tfPassword.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //labelField.text = inputTextField.text
    }
}

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
