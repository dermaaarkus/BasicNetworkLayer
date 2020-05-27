//
//  Resource.swift
//  NetworkService
//
//  Created by Markus on 04.03.20.
//  Copyright © 2020 Kersten Broich. All rights reserved.
//

import Foundation

public class Resource<M> {
    public let parse: (Data) throws -> M
    public let url: URL
    
    public init?(baseURL: URL, path: String, queryItems: [URLQueryItem], parse: @escaping (Data) throws -> M) {
        var components = URLComponents()
        components.path = path
        components.queryItems = queryItems
        
        guard let url = components.url(relativeTo: baseURL) else {
            return nil
        }
        
        self.url = url
        self.parse = parse
    }
    
    public init(url: URL, parse: @escaping (Data) throws -> M) {
        self.url = url
        self.parse = parse
    }
}
