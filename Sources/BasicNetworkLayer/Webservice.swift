//
//  Webservice.swift
//  NetworkService
//
//  Created by Markus on 04.03.20.
//  Copyright © 2020 Kersten Broich. All rights reserved.
//

import Foundation

public extension Webservice {
    enum Error: Swift.Error {
        case parsed(Swift.Error)
        case data
        case httpStatusCode(Int)
        case other(Swift.Error)
    }
}

public final class Webservice {
    public static let shared = Webservice()
    
    private var session: URLSession
    
    public convenience init() {
        let session = URLSession(configuration: .default,
                          delegate: nil,
                          delegateQueue: nil)
        
        self.init(session: session)
    }
    
    public init(session: URLSession) {
        self.session = session
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    public func load<M>(resource: Resource<M>, token: CancelToken? = nil, completionHandler: @escaping (Result<M, Error>) -> Void) {
        let request = URLRequest(url: resource.url)
        let parse = resource.parse
        
        return load(request: request, parsingHandler: parse, token: token, completionHandler: completionHandler)
    }
    
    public func load<M>(request: URLRequest, parsingHandler: @escaping (Data) throws -> M, token: CancelToken? = nil, completionHandler: @escaping (Result<M, Webservice.Error>) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                if let error = error as? Webservice.Error {
                    completionHandler(.failure(error))
                } else {
                    completionHandler(.failure(.other(error)))
                }
                
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200..<400).contains(httpResponse.statusCode) == false {
                completionHandler(.failure(.httpStatusCode(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                assertionFailure("data should never be nil without describing error object")
                completionHandler(.failure(.data))
                return
            }
            
            do {
                let result = try parsingHandler(data)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(.parsed(error)))
            }
        }
        
        token?.handler = {
            task.cancel()
        }
        
        task.resume()
    }
}
