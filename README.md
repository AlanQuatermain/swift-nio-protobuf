# NIOProtobuf

This library contains some useful tools for anyone using Protobuf encoded messages in their [swift-nio](https://github.com/apple/swift-nio) stack.
If not for the dependency on [SwiftProtobuf](https://github.com/apple/swift-protobuf) and thus [Foundation](https://developer.apple.com/documentation/foundation),
this would likely just be a pull request for [swift-nio-extras](https://github.com/apple/swift-nio-extras). As it is, I'm happy to keep it here.

The functionality here was inspired by [the protobuf codecs in Netty](https://github.com/netty/netty/tree/d7fa7be67fb3cd5020ab89b64b311ff3dc7c82bb/codec/src/main/java/io/netty/handler/codec/protobuf).

## Using NIOProtobuf

    dependencies: [
        .package(url: "https://github.com/AlanQuatermain/swift-nio-protobuf.git", .upToNextMinor(from: "0.1.0")),
    ],

## Contents

- [`VarintFrameDecoder` and `VarintLengthFieldPrepender`](Sources/NIOProtobuf/ProtobufVarintFrameCodecs.swift): Implements VarInt64-based 
    length encoding of messages from up/down the stack. Anything passed to the prepender will be prepended with its length, varint-encoded.
    The decoder will read varints and accumulate the appropriate number of bytes from its own input, passing each slice to the next handler
    once all bytes have arrived.
- [`ProtobufDecoder` and `ProtobufEncoder`](Sources/NIOProtobuf/ProtobufCodecs.swift): An encoder/decoder pair that encoder or decode a
    protobuf message type specified as a generic parameter. Note that both will send all input bytes into the SwiftProtobuf encoder/decoder.
    It is anticipated that you'll want to chain these together to parse or generate standard varint32-delimited protobuf streams.
