//
//  ProtobufDecoderStackTests.swift
//  NIOProtobufTests
//
//  Created by Jim Dovey on 3/14/19.
//

import XCTest
import NIO
@testable import NIOProtobuf

class ProtobufDecoderStackTests: XCTestCase {
    var channel: EmbeddedChannel!
    var decoder: ProtobufDecoder<Test_Test>!
    var framer: VarintFrameDecoder!

    override func setUp() {
        self.channel = EmbeddedChannel()
        self.decoder = ProtobufDecoder<Test_Test>()
        self.framer = VarintFrameDecoder()

        let decodeHandler = ByteToMessageHandler(self.decoder)
        let frameHandler = ByteToMessageHandler(self.framer)
        try? self.channel.pipeline.addHandlers(frameHandler, decodeHandler).wait()
    }

    override func tearDown() {
        self.decoder = nil
        self.framer = nil
        _ = try? self.channel.finish()
    }

    func testSingleMessage() throws {
        var message = Test_Test()
        message.stringValue = "This is a test."
        message.integerValue = 302_201

        let messageBytes = try message.serializedData()

        var buffer = self.channel.allocator.buffer(capacity: messageBytes.count + 9)
        buffer.writeVarint(messageBytes.count)
        buffer.writeBytes(messageBytes)

        XCTAssertTrue(try self.channel.writeInbound(buffer))

        let output: Test_Test! = try self.channel.readInbound()
        XCTAssertNotNil(output)
        XCTAssertEqual(message, output)
    }

    func testMultipleMessages() throws {
        var message = Test_Test()
        message.stringValue = "This is a test."
        message.integerValue = 302_201

        let messageBytes1 = try message.serializedData()

        message.stringValue = "This is also a test."
        message.integerValue = .max

        let messageBytes2 = try message.serializedData()

        var buffer = self.channel.allocator.buffer(capacity: messageBytes1.count + messageBytes2.count + 18)
        buffer.writeVarint(messageBytes1.count)
        buffer.writeBytes(messageBytes1)
        buffer.writeVarint(messageBytes2.count)
        buffer.writeBytes(messageBytes2)

        XCTAssertTrue(try self.channel.writeInbound(buffer))

        var output: Test_Test! = try self.channel.readInbound()
        XCTAssertNotNil(output)
        XCTAssertEqual(output.stringValue, "This is a test.")
        XCTAssertEqual(output.integerValue, 302_201)

        output = try self.channel.readInbound()
        XCTAssertNotNil(output)
        XCTAssertEqual(output.stringValue, "This is also a test.")
        XCTAssertEqual(output.integerValue, .max)
    }

}
