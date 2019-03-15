//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftProtobuf open source project
//
// Copyright (c) 2019 Circuit Dragon, Ltd.
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
import NIO
import SwiftProtobuf
@testable import NIOProtobuf

class ProtobufEncoderTests: XCTestCase {
    var channel: EmbeddedChannel!
    var encoder: ProtobufEncoder<Test_Test>!
    var handler: MessageToByteHandler<ProtobufEncoder<Test_Test>>!

    override func setUp() {
        self.channel = EmbeddedChannel()
        self.encoder = ProtobufEncoder<Test_Test>()
        self.handler = MessageToByteHandler(self.encoder)
        try? self.channel.pipeline.addHandler(self.handler).wait()
    }

    override func tearDown() {
        self.encoder = nil
        self.handler = nil
        _ = try? self.channel.finish()
    }

    func testProtobufEncoding() throws {
        var message = Test_Test()
        message.stringValue = "This is a test string."
        message.integerValue = Int32(UInt16.max)

        // Writing a whole message, should get encoded and flushed immediately.
        XCTAssertTrue(try self.channel.writeOutbound(message))

        // Should have a blob of data coming out the other side.
        var output: ByteBuffer? = try self.channel.readOutbound()
        XCTAssertNotNil(output)

        // Read as Data type since that's what SwiftProtobuf uses.
        guard let data = output!.readData(length: output!.readableBytes) else {
            XCTFail("Unable to get Data version of our output bytes!")
            return
        }

        // Should be parseable now
        var decoded: Test_Test! = nil
        XCTAssertNoThrow(decoded = try Test_Test(serializedData: data))

        XCTAssertEqual(message, decoded)
    }

}
