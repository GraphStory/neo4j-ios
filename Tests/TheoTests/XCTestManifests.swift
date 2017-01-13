import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Theo_000_RequestTests.allTests)
    ]
}
#endif
