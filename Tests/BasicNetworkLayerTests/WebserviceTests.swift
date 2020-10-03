import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import BasicNetworkLayer

class WebserviceTests: XCTestCase {

    enum TestError: Swift.Error {
        case fail
    }
    
    func testLoadResourceWithDataError() {
        let funcName = "testLoadResourceWithOtherError"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(error: Webservice.Error.data)
        }
        
        Webservice.shared.load(resource: resource) {
            do {
                _ = try $0.get()
                XCTFail("should throw error")
            } catch Webservice.Error.data {
                expectation.fulfill()
            } catch {
                XCTFail("error should be Webservice.Error.data")
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testLoadResourceWithOtherError() {
        let funcName = "testLoadResourceWithOtherError"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(error: TestError.fail)
        }
        
        Webservice.shared.load(resource: resource) {
            do {
                _ = try $0.get()
                XCTFail("should throw error")
            } catch Webservice.Error.other(TestError.fail) {
                expectation.fulfill()
            } catch {
                XCTFail("error should be Webservice.Error.other(TestError.fail)")
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testLoadResourceWithUnauthorizedError() {
        let funcName = "testLoadResourceWithUnauthorizedError"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 401, headers: nil)
        }
        
        Webservice.shared.load(resource: resource) {
            switch $0 {
            case .success:
                XCTFail("expected failure")
            case .failure(let error):
                switch error {
                case .httpStatusCode(let statusCode):
                    XCTAssertEqual(statusCode, 401)
                default:
                    XCTFail("expected error with status code '401'")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testLoadResourceWithServerError() {
        let funcName = "testLoadResourceWithServerError"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
        
        Webservice.shared.load(resource: resource) {
            switch $0 {
            case .success:
                XCTFail("expected failure")
            case .failure(let error):
                switch error {
                case .httpStatusCode(let statusCode):
                    XCTAssertEqual(statusCode, 500)
                default:
                    XCTFail("expected error with status code '500'")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testLoadResourceFailParsing() {
        let funcName = "testLoadResourceFailParsing"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { _ in throw TestError.fail })
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        
        Webservice.shared.load(resource: resource) {
            do {
                _ = try $0.get()
                XCTFail("should throw error")
            } catch Webservice.Error.parsed(TestError.fail) {
                expectation.fulfill()
            } catch {
                XCTFail("error should be Webservice.Error.parsed(TestError.fail)")
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testLoadResourceWithEmptyData() {
        let funcName = "testLoadResourceWithEmptyData"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        
        Webservice.shared.load(resource: resource) {
            switch $0 {
            case .success(let data):
                XCTAssertTrue(data.isEmpty, "data should be empty")
                expectation.fulfill()
            case .failure:
                XCTFail("expected success")
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testLoadResourceCancel() {
        let funcName = "testLoadResourceCancel"
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let cancelToken = CancelToken()
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil).requestTime(0, responseTime: 1)
        }
        
        Webservice.shared.load(resource: resource, token: cancelToken) {
            switch $0 {
            case .success:
                XCTFail("expected failure")
            case .failure:
                expectation.fulfill()
            }
        }
        
        cancelToken.cancel()
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: Webservice session
    
    func testDeallocateWebserviceCancelsRequest() {
        let funcName = "testDeallocateWebserviceCancelsRequest"
        var webservice: Webservice? = Webservice()
        let resource = Resource(url: URL(string: "https://apple.com/\(funcName)")!, parse: { $0 })
        let cancelToken = CancelToken()
        let expectation = XCTestExpectation(description: funcName)
        
        stub(condition: isPath("/\(funcName)")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil).requestTime(0, responseTime: 1)
        }
        
        webservice?.load(resource: resource, token: cancelToken) {
            switch $0 {
            case .success:
                XCTFail("expected failure")
            case .failure:
                expectation.fulfill()
            }
        }
        
        webservice = nil // dealloc webservice
        
        wait(for: [expectation], timeout: 0.1)
    }
}
