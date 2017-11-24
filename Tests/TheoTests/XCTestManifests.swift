import XCTest

#if !os(macOS) && !os(iOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Theo_000_BoltClientTests.allTests),
    ]
}
#endif
