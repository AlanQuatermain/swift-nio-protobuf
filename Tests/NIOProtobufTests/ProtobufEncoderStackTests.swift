//
//  ProtobufEncoderStackTests.swift
//  NIOProtobufTests
//
//  Created by Jim Dovey on 3/14/19.
//

import XCTest
import NIO
@testable import NIOProtobuf

class ProtobufEncoderStackTests: XCTestCase {
    var channel: EmbeddedChannel!
    var encoder: ProtobufEncoder<Test_Test>!
    var prepender: VarintLengthFieldPrepender!

    override func setUp() {
        self.channel = EmbeddedChannel()
        self.encoder = ProtobufEncoder<Test_Test>()
        self.prepender = VarintLengthFieldPrepender()

        let encodeHandler = MessageToByteHandler(self.encoder)
        let prependHandler = MessageToByteHandler(self.prepender)
        try? self.channel.pipeline.addHandlers(prependHandler, encodeHandler).wait()
    }

    override func tearDown() {
        self.encoder = nil
        self.prepender = nil
        _ = try? self.channel.finish()
    }

    func testSingleMessage() throws {
        var message = Test_Test()
        message.stringValue = "This is a test."
        message.integerValue = 2_049_920

        XCTAssertTrue(try self.channel.writeOutbound(message))

        var buffer: ByteBuffer! = try self.channel.readOutbound()
        XCTAssertNotNil(buffer)

        // Read a varint length.
        let length: Int! = buffer.readVarint()
        XCTAssertNotNil(length)
        XCTAssertEqual(length, buffer.readableBytes)

        // get readable bytes as Data and try to deserialize
        let data: Data! = buffer.readData(length: length)
        XCTAssertNotNil(data)

        var decoded = Test_Test()
        XCTAssertNoThrow(try decoded.merge(serializedData: data))

        XCTAssertEqual(message, decoded)
    }

    func testMultipleMessages() throws {
        var message = Test_Test()
        message.stringValue = "This is the first message."
        message.integerValue = 1

        XCTAssertTrue(try self.channel.writeOutbound(message))

        message.stringValue = "This is the second message."
        message.integerValue = 2

        XCTAssertTrue(try self.channel.writeOutbound(message))

        // Pull out data blob.
        var buffer: ByteBuffer! = try self.channel.readOutbound()
        XCTAssertNotNil(buffer)

        // Decode first message.
        var length: Int! = buffer.readVarint()
        XCTAssertNotNil(length)
        XCTAssertEqual(length, buffer.readableBytes)

        var data: Data! = buffer.readData(length: length)
        XCTAssertNotNil(data)

        // Now the next buffer
        buffer = try self.channel.readOutbound()
        XCTAssertNotNil(buffer)

        var decoded = Test_Test()
        XCTAssertNoThrow(try decoded.merge(serializedData: data))
        XCTAssertEqual(decoded.stringValue, "This is the first message.")
        XCTAssertEqual(decoded.integerValue, 1)

        length = buffer.readVarint()
        XCTAssertNotNil(length)
        XCTAssertEqual(length, buffer.readableBytes)

        data = buffer.readData(length: length)
        XCTAssertNotNil(data)

        XCTAssertNoThrow(try decoded.merge(serializedData: data))
        XCTAssertEqual(decoded.stringValue, "This is the second message.")
        XCTAssertEqual(decoded.integerValue, 2)
    }

}
