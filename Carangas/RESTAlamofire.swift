//
//  RESTAlamofire.swift
//  Carangas
//
//  Created by aluno on 16/09/20.
//  Copyright © 2020 Eric Brito. All rights reserved.
//

import Foundation
import Alamofire

class RESTAlamofire {
    
    // URL principal do servidor que obtem os dados dos carros cadastrados la
    private static let basePath = "https://carangas.herokuapp.com/cars"
    
    private static let urlFipe = "https://fipeapi.appspot.com/api/1/carros/marcas.json"
    
    
    // session criada automaticamente e disponivel para reusar
    private static let session = URLSession(configuration: configuration)
    
    
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Content-Type":"application/json"]
        config.timeoutIntervalForRequest = 15.0
        config.httpMaximumConnectionsPerHost = 5
        return config
    }()
    
    class func loadCars(onComplete: @escaping ([Car]) -> Void, onError: @escaping (CarError) -> Void) {
        
        AF.request(self.basePath).response { response in
            do {
                if response.data == nil {
                    onError(.noData)
                }
            
                if let error = response.error {
                    if error.isSessionTaskError || error.isInvalidURLError {
                        onError(.url)
                        return
                    }
                    
                    if error._code == NSURLErrorTimedOut {
                        onError(.noResponse)
                    }else if error._code != 200 {
                        onError(.responseStatusCode(code: error._code))
                    }
                    
                }
                let cars = try JSONDecoder().decode([Car].self, from: response.data!)
                onComplete(cars)
            }catch is DecodingError {
                onError(.invalidJSON)
            }catch {
                onError(.taskError(error: error))
            }
            
        }
        
//        guard let url = URL(string: basePath) else {
//            onError(.url)
//            return
//        }
        
//        let dataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
//            // usamos uma closure para receber as respostas, ou seja, estamos em um processo
//            // em background que será assincrono
//
//            // 1
//            if error == nil {
//                // 2
//                guard let response = response as? HTTPURLResponse else {
//                    onError(.noResponse)
//                    return
//                }
//                if response.statusCode == 200 {
//
//                    // servidor respondeu com sucesso :)
//                    // 3
//                    // obter o valor de data
//                    guard let data = data else {
//                        onError(.noData)
//                        return
//                    }
//
//                    do {
//
//                        let cars = try JSONDecoder().decode([Car].self, from: data)
//                        // pronto para reter dados
//
//                        onComplete(cars)
//
//                    } catch {
//                        // algum erro ocorreu com os dados
//                        onError(.invalidJSON)
//                    }
//
//
//                } else {
//                    onError(.responseStatusCode(code: response.statusCode))
//                }
//
//            } else {
//                onError(.taskError(error: error!))
//            }
//
//        }
//
//        // start request
//        dataTask.resume()
    }
    
    
    class func save(car: Car, onComplete: @escaping (Bool) -> Void, onError: @escaping (CarError) -> Void ) {
        applyOperation(car: car, operation: .save, onComplete: onComplete, onError: onError)
    }
            
    class func update(car: Car, onComplete: @escaping (Bool) -> Void , onError: @escaping (CarError) -> Void ) {
        applyOperation(car: car, operation: .update, onComplete: onComplete, onError: onError )
    }
    
    class func delete(car: Car, onComplete: @escaping (Bool) -> Void, onError: @escaping (CarError) -> Void ) {
        applyOperation(car: car, operation: .delete, onComplete: onComplete, onError: onError )
    }
    
    
    private class func applyOperation(car: Car, operation: RESTOperation , onComplete: @escaping (Bool) -> Void, onError: @escaping (CarError) -> Void ) {
        
        // o endpoint do servidor para update é: URL/id
        let urlString = basePath + "/" + (car._id ?? "")
        
        guard let url = URL(string: urlString) else {
            onComplete(false)
            return
        }
        var request = URLRequest(url: url)
        
        switch operation {
        case .delete:
            request.httpMethod = HTTPMethod.delete.rawValue
        case .save:
            request.httpMethod = HTTPMethod.post.rawValue
        case .update:
            request.httpMethod = HTTPMethod.put.rawValue
        }
       
        
        // transformar objeto para um JSON, processo contrario do decoder -> Encoder
        guard let json = try? JSONEncoder().encode(car) else {
            onComplete(false)
            return
        }
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        AF.request(request).validate().responseJSON{ response in
            
            guard let responseFinal = response.response else {
                onError(.noResponse)
                return
            }
            
            if responseFinal.statusCode == 200 {
                onComplete(true)
            }else{
                onError(.responseStatusCode(code: response.response!.statusCode))
            }
            
        }
        
//        let dataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//            if error == nil {
//                // verificar e desembrulhar em uma unica vez
//                guard let response = response as? HTTPURLResponse, response.statusCode == 200, let _ = data else {
//                    onComplete(false)
//                    return
//                }
//
//                // ok
//                onComplete(true)
//
//            } else {
//                onComplete(false)
//            }
//        }
//
//        dataTask.resume()
    }
    
    
    // o metodo pode retornar um array de nil se tiver algum erro
    class func loadBrands(onComplete: @escaping ([Brand]?) -> Void, onError: @escaping (CarError) -> Void) {
        
        // URL TABELA FIPE
        
        guard let url = URL(string: urlFipe) else {
            onComplete(nil)
            return
        }
        
        AF.request(url,method: .get).validate().response { response in
            do {
                if response.data == nil {
                    onError(.noData)
                }
            
                if let error = response.error {
                    if error.isSessionTaskError || error.isInvalidURLError {
                        onError(.url)
                        return
                    }
                    
                    if error._code == NSURLErrorTimedOut {
                        onError(.noResponse)
                    }else if error._code != 200 {
                        onError(.responseStatusCode(code: error._code))
                    }
                }
                let brands = try JSONDecoder().decode([Brand].self, from: response.data!)
                onComplete(brands)
            }catch is DecodingError {
                onError(.invalidJSON)
            }catch {
                onError(.taskError(error: error))
            }
            
        }
        
        
        // tarefa criada, mas nao processada
//        let dataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
//            if error == nil {
//                guard let response = response as? HTTPURLResponse else {
//                    onComplete(nil)
//                    return
//                }
//                if response.statusCode == 200 {
//                    // obter o valor de data
//                    guard let data = data else {
//                        onComplete(nil)
//                        return
//                    }
//                    do {
//                      let brands = try JSONDecoder().decode([Brand].self, from: data)
//                        onComplete(brands)
//                    } catch {
//                        // algum erro ocorreu com os dados
//                        onComplete(nil)
//                    }
//                } else {
//                    onComplete(nil)
//                }
//            } else {
//                onComplete(nil)
//            }
//        }
//        // start request
//        dataTask.resume()
    }
    
    
    
} // fim da classe REST
