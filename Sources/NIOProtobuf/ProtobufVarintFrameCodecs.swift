//
//  ProtobufVarintFrameDecoder.swift
//  NIOProtobuf
//
//  Created by Jim Dovey on 3/13/19.
//

import NIO
import SwiftProtobuf

public class ProtobufVarintFrameDecoder: ByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer

    private var messageLength: Int? = nil

    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        // If we don't have a length, we need to read one
        if self.messageLength == nil {
            self.messageLength = buffer.readVarint()
        }
        guard let length = self.messageLength else {
            // Not enough bytes to read the message length. Ask for more.
            return .needMoreData
        }

        // See if we can read this amount of data.
        guard let messageBytes = buffer.readSlice(length: length) else {
            // not enough bytes in the buffer to satisfy the read. Ask for more.
            return .needMoreData
        }

        // We don't need the length now.
        self.messageLength = nil

        // The message's bytes up the pipeline to the next handler.
        context.fireChannelRead(self.wrapInboundOut(messageBytes))

        // We can keep going if you have more data.
        return .continue
    }

    public func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return try decode(context: context, buffer: &buffer)
    }
}

public class ProtobufVarintLengthFieldPrepender: MessageToByteEncoder {
    public typealias OutboundIn = ByteBuffer

    public func encode(data: ByteBuffer, out: inout ByteBuffer) throws {
        let bodyLen = out.readableBytes
        out.writeVarint(bodyLen)
        out.writeBytes(data.readableBytesView)
    }
}
