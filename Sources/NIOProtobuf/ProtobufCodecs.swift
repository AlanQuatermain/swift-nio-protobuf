//
//  ProtobufDecoder.swift
//  NIOProtobuf
//
//  Created by Jim Dovey on 3/13/19.
//

import NIO
import SwiftProtobuf
import Foundation
import NIOFoundationCompat

public class ProtobufDecoder<T: Message>: ByteToMessageDecoder {
    public typealias InboundOut = T

    let extensionMap: ExtensionMap?
    let decodingOptions: BinaryDecodingOptions

    init(extensionMap: ExtensionMap? = nil, options: BinaryDecodingOptions = BinaryDecodingOptions()) {
        self.extensionMap = extensionMap
        self.decodingOptions = options
    }

    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        do {
            let message = try buffer.withUnsafeMutableReadableBytes { bufPtr -> T in
                let data = Data(bytesNoCopy: bufPtr.baseAddress!, count: bufPtr.count, deallocator: .none)
                return try T(serializedData: data, extensions: self.extensionMap, options: self.decodingOptions)
            }
            context.fireChannelRead(NIOAny(message))
            // don't forget to consume the bytes in the buffer
            buffer.moveReaderIndex(forwardBy: buffer.readableBytes)
        } catch BinaryDecodingError.truncated {
            return .needMoreData
        }
        return .continue
    }

    public func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return try decode(context: context, buffer: &buffer)
    }
}

public class ProtobufEncoder<T: Message>: MessageToByteEncoder {
    public typealias OutboundIn = T

    public func encode(data: T, out: inout ByteBuffer) throws {
        out.writeBytes(try data.serializedData())
    }
}

public class ProtobufLengthPrefixedEncoder<T: Message>: MessageToByteEncoder {
    public typealias OutboundIn = T

    public func encode(data: T, out: inout ByteBuffer) throws {
        let bytes = try data.serializedData()
        out.writeVarint(bytes.count)
        out.writeBytes(bytes)
    }
}
