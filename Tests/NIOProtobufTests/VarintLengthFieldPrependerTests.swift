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
@testable import NIOProtobuf

class VarintLengthFieldPrependerTests: XCTestCase {
    private var channel: EmbeddedChannel!
    private var prepender: VarintLengthFieldPrepender!
    private var handler: MessageToByteHandler<VarintLengthFieldPrepender>!

    override func setUp() {
        self.channel = EmbeddedChannel()
        self.prepender = VarintLengthFieldPrepender()
        self.handler = MessageToByteHandler(self.prepender)
        try? self.channel.pipeline.addHandler(self.handler).wait()
    }

    override func tearDown() {
        self.prepender = nil
        self.handler = nil
        _ = try? self.channel.finish()
    }

    func testPrefixesBuffersAsExpected() throws {
        let str1 = "one", str2 = "two", str3 = "three", str4 = String(repeating: "A", count: 512)
        var buffer = self.channel.allocator.buffer(capacity: 550)

        // First string, three bytes.
        buffer.writeString(str1)
        XCTAssertEqual(3, buffer.readableBytes)

        XCTAssertTrue(try self.channel.writeOutbound(buffer).isFull)

        var output: ByteBuffer? = try self.channel.readOutbound()
        XCTAssertEqual(4, output?.readableBytes)
        XCTAssertEqual(3, output?.readVarint())
        XCTAssertEqual(str1, output?.readString(length: 3))

        // Second string: also three bytes.
        buffer.clear()
        buffer.writeString(str2)
        XCTAssertEqual(3, buffer.readableBytes)

        XCTAssertTrue(try self.channel.writeOutbound(buffer).isFull)

        output = try self.channel.readOutbound()
        XCTAssertEqual(4, output?.readableBytes)
        XCTAssertEqual(3, output?.readVarint())
        XCTAssertEqual(str2, output?.readString(length: 3))

        // Third string: five bytes.
        buffer.clear()
        buffer.writeString(str3)
        XCTAssertEqual(5, buffer.readableBytes)

        XCTAssertTrue(try self.channel.writeOutbound(buffer).isFull)

        output = try self.channel.readOutbound()
        XCTAssertEqual(6, output?.readableBytes)
        XCTAssertEqual(5, output?.readVarint())
        XCTAssertEqual(str3, output?.readString(length: 5))

        // Fourth string: 512 bytes.
        buffer.clear()
        buffer.writeString(str4)
        XCTAssertEqual(512, buffer.readableBytes)

        XCTAssertTrue(try self.channel.writeOutbound(buffer).isFull)

        output = try self.channel.readOutbound()
        XCTAssertEqual(514, output?.readableBytes)
        XCTAssertEqual(512, output?.readVarint())
        XCTAssertEqual(str4, output?.readString(length: 512))
    }

}
