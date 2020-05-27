//
//  CancelToken.swift
//  NetworkService
//
//  Created by Markus on 04.03.20.
//  Copyright © 2020 Kersten Broich. All rights reserved.
//

import Foundation

public final class CancelToken {
    public var handler: (() -> Void)?
    
    public func cancel() {
        handler?()
    }
}
