import XCTest

import NIOProtobufTests

var tests = [XCTestCaseEntry]()
tests += NIOProtobufTests.allTests()
XCTMain(tests)
