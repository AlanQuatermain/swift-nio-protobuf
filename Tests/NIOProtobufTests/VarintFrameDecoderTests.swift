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

final class VarintFrameDecoderTests: XCTestCase {
    private var channel: EmbeddedChannel!
    private var decoder: VarintFrameDecoder!
    private var handler: ByteToMessageHandler<VarintFrameDecoder>!

    override func setUp() {
        self.channel = EmbeddedChannel()
        self.decoder = VarintFrameDecoder()
        self.handler = ByteToMessageHandler(self.decoder)
        try? self.channel.pipeline.addHandler(self.handler).wait()
    }

    override func tearDown() {
        self.decoder = nil
        self.handler = nil
        _ = try? self.channel.finish()
    }

    func testDecodingIndividualBytes() throws {
        let message = "abcdefghi"      // nine bytes, and we'll write a tenth momentarily

        var lengthBuf = self.channel.allocator.buffer(capacity: 1)
        lengthBuf.writeVarint(message.count + 1)

        // Write the length in one go (in this example, it's one byte).
        XCTAssertFalse(try self.channel.writeInbound(lengthBuf))

        // Now write the string bytes, one by one.
        try message.forEach {
            var buffer = self.channel.allocator.buffer(capacity: 1)
            buffer.writeString("\($0)")

            // Data should get buffered until we've written everything
            XCTAssertFalse(try self.channel.writeInbound(buffer))
        }

        // Add the tenth character and it should flush through.
        var buffer = self.channel.allocator.buffer(capacity: 1)
        buffer.writeStaticString("j")
        XCTAssertTrue(try self.channel.writeInbound(buffer))

        // Now we should have a buffer to read.
        var input: ByteBuffer!
        XCTAssertNoThrow(input = try self.channel.readInbound(as: ByteBuffer.self))
        XCTAssertNotNil(input)

        // Should be a ten-letter string in here
        guard let string = input.readString(length: 10) else {
            XCTFail("Unable to read ten-letter string from buffer '\(input!)'")
            return
        }
        XCTAssertEqual(string, "abcdefghij")
    }

    func testDecodingEntireFrame() throws {
        let message = String(repeating: "A", count: 1024)
        var buffer = self.channel.allocator.buffer(capacity: message.count + 9)
        buffer.writeVarint(message.count)
        XCTAssertEqual(buffer.readableBytes, 2)
        buffer.writeString(message)

        // Funnel this all in, and it should be consumed completely.
        XCTAssertTrue(try self.channel.writeInbound(buffer))

        var input: ByteBuffer? = try self.channel.readInbound()
        XCTAssertEqual(1024, input?.readableBytes)
        XCTAssertEqual(message, input?.readString(length: 1024))
    }

    func testEmptyBuffer() throws {
        var buffer = self.channel.allocator.buffer(capacity: 1)
        buffer.writeVarint(0)
        XCTAssertEqual(1, buffer.readableBytes)

        XCTAssertTrue(try self.channel.writeInbound(buffer))

        let input: ByteBuffer? = try self.channel.readInbound()
        XCTAssertEqual(0, input?.readableBytes)
    }
}
