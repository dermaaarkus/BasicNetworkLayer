import XCTest

@testable import BasicNetworkLayer

class ResourceTests: XCTestCase {
    
    // MARK: init url
    
    func testInitURL() {
        let resource = Resource<Data>(url: URL(string: "https://test.de")!,
                                      parse: { $0 })
        
        XCTAssertEqual(resource.url, URL(string: "https://test.de")!,
                       "resource url should be 'https://test.de', but is \(resource.url.absoluteString)")
    }
    
    func testInitParse() {
        let resource = Resource<Data>(url: URL(string: "https://test.de")!,
                                      parse: { $0 })
        let data = Data(capacity: 0)
        
        XCTAssertEqual(try resource.parse(data), data,
                       "resource parse should return equal data, but doesnt")
    }
    
    // MARK: init base url
    
    func testInitBaseURL() {
        let resource = Resource<Data>(baseURL: URL(string: "https://test.de")!,
                                      path: "/path",
                                      queryItems: [URLQueryItem(name: "test", value: "1")],
                                      parse: { $0 })
        
        XCTAssertEqual(resource?.url.absoluteString, "https://test.de/path?test=1",
                       "resource url should be 'https://test.de/path?test=1', but is \(String(describing: resource?.url.absoluteString))")
    }
    
    func testInitBaseURLInvalidPath() {
        let resource = Resource<Data>(baseURL: URL(string: "https://test.de")!,
                                      path: "//path",
                                      queryItems: [URLQueryItem(name: "test", value: "1")],
                                      parse: { $0 })
        
        XCTAssertNil(resource, "resource should be 'nil', but is \(String(describing: resource))")
    }
}
