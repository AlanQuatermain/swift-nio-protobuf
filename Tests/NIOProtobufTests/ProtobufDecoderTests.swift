//
//  ProtobufDecoderTests.swift
//  NIOProtobufTests
//
//  Created by Jim Dovey on 3/14/19.
//

import XCTest
import NIO
import SwiftProtobuf
@testable import NIOProtobuf

class ProtobufDecoderTests: XCTestCase {
    var channel: EmbeddedChannel!
    var decoder: ProtobufDecoder<Test_Test>!
    var handler: ByteToMessageHandler<ProtobufDecoder<Test_Test>>!

    override func setUp() {
        self.channel = EmbeddedChannel()
        self.decoder = ProtobufDecoder<Test_Test>()
        self.handler = ByteToMessageHandler(self.decoder)
        try? self.channel.pipeline.addHandler(self.handler).wait()
    }

    override func tearDown() {
        self.decoder = nil
        self.handler = nil
        _ = try? self.channel.finish()
    }

    func testSingleMessageBuffer() throws {
        var message = Test_Test()
        message.stringValue = "This is a test."
        message.integerValue = 102_839

        guard let data = try? message.serializedData() else {
            XCTFail("Failed to serialize test message")
            return
        }

        var buffer = self.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)

        // Feed in this data in one go.
        XCTAssertTrue(try self.channel.writeInbound(buffer))

        // We should get a decoded message out the other end.
        let output: Test_Test! = try self.channel.readInbound()
        XCTAssertNotNil(output)
        XCTAssertEqual(message, output)
    }

    func testSplitMessageBuffer() throws {
        var message = Test_Test()
        message.stringValue = "This is a test."
        message.integerValue = 102_839

        guard let data = try? message.serializedData() else {
            XCTFail("Failed to serialize test message")
            return
        }

        var buffer = self.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)

        // Feed in this data in two chunks.
        XCTAssertFalse(try self.channel.writeInbound(buffer.readSlice(length: buffer.readableBytes/2)!))
        XCTAssertNil(try self.channel.readInbound())    // nothing output yet...
        XCTAssertTrue(try self.channel.writeInbound(buffer))

        // We should get a decoded message out the other end.
        let output: Test_Test! = try self.channel.readInbound()
        XCTAssertNotNil(output)
        XCTAssertEqual(message, output)
    }

}
