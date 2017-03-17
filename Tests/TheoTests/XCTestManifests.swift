import XCTest

#if !os(macOS) && !os(iOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        //testCase(Theo_000_RestRequestTests.allTests),
		testCase(Theo_001_BoltClientTests.allTests),
    ]
}
#endif
