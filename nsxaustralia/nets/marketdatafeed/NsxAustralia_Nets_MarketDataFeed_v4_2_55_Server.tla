---------- MODULE NsxAustralia_Nets_MarketDataFeed_v4_2_55_Server ----------
(***************************************************************************)
(* Nation Stock Exchange of Australia NSX Market Data Feed v4.2.55         *)
(*                                                                         *)
(* Generated from the binary model. A field is the bytes it occupies; an   *)
(* integer is read only where a rule depends on one - a length, a count, a *)
(* message type - which are the dependencies the parse rules run on.       *)
(*                                                                         *)
(* TLC checks that every record decodes back to what was encoded, that a   *)
(* dispatch selects the message its type names, and that a derived length  *)
(* or count is written from what it describes.                             *)
(*                                                                         *)
(* Note: TLC evaluates integers in 32 bits, so a field wider than that has *)
(* no range it can enumerate; every field is checked as its bytes, which   *)
(* is exact at any width.                                                  *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: a Server Soup Bin Tcp Packet that ends the session is the last of *)
(* its Server Packet: nothing may follow it.                               *)
(***************************************************************************)
EXTENDS Integers, Sequences

(***************************************************************************)
(* Wire primitives                                                         *)
(***************************************************************************)

Byte == 0 .. 255

(* An unsigned integer, least significant byte first. Read only where a rule *)
(* depends on the value: a length, a count, a message type. *)
RECURSIVE DecodeUIntLE(_)
DecodeUIntLE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE Head(bytes) + 256 * DecodeUIntLE(Tail(bytes))

RECURSIVE EncodeUIntLE(_, _)
EncodeUIntLE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE <<value % 256>> \o EncodeUIntLE(value \div 256, width - 1)

(* The same, most significant byte first, which is how a big endian protocol writes it *)
RECURSIVE DecodeUIntBE(_)
DecodeUIntBE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeUIntBE(SubSeq(bytes, 1, Len(bytes) - 1)) * 256 + bytes[Len(bytes)]

RECURSIVE EncodeUIntBE(_, _)
EncodeUIntBE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeUIntBE(value \div 256, width - 1) \o <<value % 256>>

(***************************************************************************)
(* A decoder yields the value it read and the bytes left, or fails         *)
(***************************************************************************)

Fail == [ok |-> FALSE]
Ok(value, rest) == [ok |-> TRUE, value |-> value, rest |-> rest]

(* The bytes a field of this width occupies, kept as they lie *)
ReadBytes(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, width), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The bytes a field of no width of its own is checked at: none, one, and a short run *)
SampleBytes == { << >>, <<0>>, <<32, 255>> }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp Message: 8 bytes                                              *)
(***************************************************************************)

TimestampMessage ==
    [ nanosecond : Sample(8) ]

EncodeTimestampMessage(message) ==
    message.nanosecond

DecodeTimestampMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 8) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value ], nanosecond.rest)

ZeroTimestampMessage ==
    [ nanosecond |-> [i \in 1 .. 8 |-> 0] ]

(* Timestamp Message at zero, then each field in turn at the values it is checked at *)
CheckedTimestampMessage ==
    { ZeroTimestampMessage }
        \cup { [ZeroTimestampMessage EXCEPT !.nanosecond = one] : one \in Sample(8) }

(***************************************************************************)
(* System Event Message: 61 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp     : Sample(4),
      group         : Sample(20),
      product       : Sample(12),
      orderbook     : Sample(4),
      eventCode     : Sample(12),
      eventStatus   : Sample(1),
      scheduledTime : Sample(8) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.group
        \o message.product
        \o message.orderbook
        \o message.eventCode
        \o message.eventStatus
        \o message.scheduledTime

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET group == ReadBytes(timestamp.rest, 20) IN IF ~group.ok THEN Fail ELSE
    LET product == ReadBytes(group.rest, 12) IN IF ~product.ok THEN Fail ELSE
    LET orderbook == ReadBytes(product.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET eventCode == ReadBytes(orderbook.rest, 12) IN IF ~eventCode.ok THEN Fail ELSE
    LET eventStatus == ReadBytes(eventCode.rest, 1) IN IF ~eventStatus.ok THEN Fail ELSE
    LET scheduledTime == ReadBytes(eventStatus.rest, 8) IN IF ~scheduledTime.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         group         |-> group.value,
         product       |-> product.value,
         orderbook     |-> orderbook.value,
         eventCode     |-> eventCode.value,
         eventStatus   |-> eventStatus.value,
         scheduledTime |-> scheduledTime.value ], scheduledTime.rest)

ZeroSystemEventMessage ==
    [ timestamp     |-> [i \in 1 .. 4 |-> 0],
      group         |-> [i \in 1 .. 20 |-> 0],
      product       |-> [i \in 1 .. 12 |-> 0],
      orderbook     |-> [i \in 1 .. 4 |-> 0],
      eventCode     |-> [i \in 1 .. 12 |-> 0],
      eventStatus   |-> [i \in 1 .. 1 |-> 0],
      scheduledTime |-> [i \in 1 .. 8 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.group = one] : one \in Sample(20) }
        \cup { [ZeroSystemEventMessage EXCEPT !.product = one] : one \in Sample(12) }
        \cup { [ZeroSystemEventMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(12) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventStatus = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.scheduledTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Tick Size Message: 24 bytes                                       *)
(***************************************************************************)

PriceTickSizeMessage ==
    [ timestamp       : Sample(4),
      tickSizeTableId : Sample(4),
      tickSize        : Sample(8),
      priceStart      : Sample(8) ]

EncodePriceTickSizeMessage(message) ==
    message.timestamp
        \o message.tickSizeTableId
        \o message.tickSize
        \o message.priceStart

DecodePriceTickSizeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET tickSizeTableId == ReadBytes(timestamp.rest, 4) IN IF ~tickSizeTableId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(tickSizeTableId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET priceStart == ReadBytes(tickSize.rest, 8) IN IF ~priceStart.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         tickSizeTableId |-> tickSizeTableId.value,
         tickSize        |-> tickSize.value,
         priceStart      |-> priceStart.value ], priceStart.rest)

ZeroPriceTickSizeMessage ==
    [ timestamp       |-> [i \in 1 .. 4 |-> 0],
      tickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      tickSize        |-> [i \in 1 .. 8 |-> 0],
      priceStart      |-> [i \in 1 .. 8 |-> 0] ]

(* Price Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceTickSizeMessage ==
    { ZeroPriceTickSizeMessage }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.tickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceStart = one] : one \in Sample(8) }

(***************************************************************************)
(* Quantity Tick Size Message: 24 bytes                                    *)
(***************************************************************************)

QuantityTickSizeMessage ==
    [ timestamp       : Sample(4),
      tickSizeTableId : Sample(4),
      tickSize        : Sample(8),
      quantityStart   : Sample(8) ]

EncodeQuantityTickSizeMessage(message) ==
    message.timestamp
        \o message.tickSizeTableId
        \o message.tickSize
        \o message.quantityStart

DecodeQuantityTickSizeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET tickSizeTableId == ReadBytes(timestamp.rest, 4) IN IF ~tickSizeTableId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(tickSizeTableId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET quantityStart == ReadBytes(tickSize.rest, 8) IN IF ~quantityStart.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         tickSizeTableId |-> tickSizeTableId.value,
         tickSize        |-> tickSize.value,
         quantityStart   |-> quantityStart.value ], quantityStart.rest)

ZeroQuantityTickSizeMessage ==
    [ timestamp       |-> [i \in 1 .. 4 |-> 0],
      tickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      tickSize        |-> [i \in 1 .. 8 |-> 0],
      quantityStart   |-> [i \in 1 .. 8 |-> 0] ]

(* Quantity Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedQuantityTickSizeMessage ==
    { ZeroQuantityTickSizeMessage }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.tickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.quantityStart = one] : one \in Sample(8) }

(***************************************************************************)
(* Orderbook Directory Message: 320 bytes                                  *)
(***************************************************************************)

OrderbookDirectoryMessage ==
    [ timestamp               : Sample(4),
      orderbook               : Sample(4),
      isin                    : Sample(12),
      securityCode            : Sample(100),
      securityName            : Sample(100),
      currency                : Sample(3),
      board                   : Sample(20),
      product                 : Sample(12),
      minimumQuantity         : Sample(8),
      quantityTickSizeTableId : Sample(4),
      quantityDecimals        : Sample(4),
      priceTickSizeTableId    : Sample(4),
      priceDecimals           : Sample(4),
      listing                 : Sample(8),
      expiry                  : Sample(8),
      assetType               : Sample(1),
      settleDate              : Sample(4),
      referenceAlpha12        : Sample(12),
      remarks                 : Sample(8) ]

EncodeOrderbookDirectoryMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.isin
        \o message.securityCode
        \o message.securityName
        \o message.currency
        \o message.board
        \o message.product
        \o message.minimumQuantity
        \o message.quantityTickSizeTableId
        \o message.quantityDecimals
        \o message.priceTickSizeTableId
        \o message.priceDecimals
        \o message.listing
        \o message.expiry
        \o message.assetType
        \o message.settleDate
        \o message.referenceAlpha12
        \o message.remarks

DecodeOrderbookDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET isin == ReadBytes(orderbook.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET securityCode == ReadBytes(isin.rest, 100) IN IF ~securityCode.ok THEN Fail ELSE
    LET securityName == ReadBytes(securityCode.rest, 100) IN IF ~securityName.ok THEN Fail ELSE
    LET currency == ReadBytes(securityName.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET board == ReadBytes(currency.rest, 20) IN IF ~board.ok THEN Fail ELSE
    LET product == ReadBytes(board.rest, 12) IN IF ~product.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(product.rest, 8) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET quantityTickSizeTableId == ReadBytes(minimumQuantity.rest, 4) IN IF ~quantityTickSizeTableId.ok THEN Fail ELSE
    LET quantityDecimals == ReadBytes(quantityTickSizeTableId.rest, 4) IN IF ~quantityDecimals.ok THEN Fail ELSE
    LET priceTickSizeTableId == ReadBytes(quantityDecimals.rest, 4) IN IF ~priceTickSizeTableId.ok THEN Fail ELSE
    LET priceDecimals == ReadBytes(priceTickSizeTableId.rest, 4) IN IF ~priceDecimals.ok THEN Fail ELSE
    LET listing == ReadBytes(priceDecimals.rest, 8) IN IF ~listing.ok THEN Fail ELSE
    LET expiry == ReadBytes(listing.rest, 8) IN IF ~expiry.ok THEN Fail ELSE
    LET assetType == ReadBytes(expiry.rest, 1) IN IF ~assetType.ok THEN Fail ELSE
    LET settleDate == ReadBytes(assetType.rest, 4) IN IF ~settleDate.ok THEN Fail ELSE
    LET referenceAlpha12 == ReadBytes(settleDate.rest, 12) IN IF ~referenceAlpha12.ok THEN Fail ELSE
    LET remarks == ReadBytes(referenceAlpha12.rest, 8) IN IF ~remarks.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         orderbook               |-> orderbook.value,
         isin                    |-> isin.value,
         securityCode            |-> securityCode.value,
         securityName            |-> securityName.value,
         currency                |-> currency.value,
         board                   |-> board.value,
         product                 |-> product.value,
         minimumQuantity         |-> minimumQuantity.value,
         quantityTickSizeTableId |-> quantityTickSizeTableId.value,
         quantityDecimals        |-> quantityDecimals.value,
         priceTickSizeTableId    |-> priceTickSizeTableId.value,
         priceDecimals           |-> priceDecimals.value,
         listing                 |-> listing.value,
         expiry                  |-> expiry.value,
         assetType               |-> assetType.value,
         settleDate              |-> settleDate.value,
         referenceAlpha12        |-> referenceAlpha12.value,
         remarks                 |-> remarks.value ], remarks.rest)

ZeroOrderbookDirectoryMessage ==
    [ timestamp               |-> [i \in 1 .. 4 |-> 0],
      orderbook               |-> [i \in 1 .. 4 |-> 0],
      isin                    |-> [i \in 1 .. 12 |-> 0],
      securityCode            |-> [i \in 1 .. 100 |-> 0],
      securityName            |-> [i \in 1 .. 100 |-> 0],
      currency                |-> [i \in 1 .. 3 |-> 0],
      board                   |-> [i \in 1 .. 20 |-> 0],
      product                 |-> [i \in 1 .. 12 |-> 0],
      minimumQuantity         |-> [i \in 1 .. 8 |-> 0],
      quantityTickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      quantityDecimals        |-> [i \in 1 .. 4 |-> 0],
      priceTickSizeTableId    |-> [i \in 1 .. 4 |-> 0],
      priceDecimals           |-> [i \in 1 .. 4 |-> 0],
      listing                 |-> [i \in 1 .. 8 |-> 0],
      expiry                  |-> [i \in 1 .. 8 |-> 0],
      assetType               |-> [i \in 1 .. 1 |-> 0],
      settleDate              |-> [i \in 1 .. 4 |-> 0],
      referenceAlpha12        |-> [i \in 1 .. 12 |-> 0],
      remarks                 |-> [i \in 1 .. 8 |-> 0] ]

(* Orderbook Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookDirectoryMessage ==
    { ZeroOrderbookDirectoryMessage }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.securityCode = one] : one \in Sample(100) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.securityName = one] : one \in Sample(100) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.board = one] : one \in Sample(20) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.product = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.minimumQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quantityTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quantityDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.listing = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.expiry = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.assetType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.settleDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.referenceAlpha12 = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.remarks = one] : one \in Sample(8) }

(***************************************************************************)
(* Orderbook Trading Action Message: 10 bytes                              *)
(***************************************************************************)

OrderbookTradingActionMessage ==
    [ timestamp    : Sample(4),
      orderbook    : Sample(4),
      tradingState : Sample(1),
      reason       : Sample(1) ]

EncodeOrderbookTradingActionMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.tradingState
        \o message.reason

DecodeOrderbookTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET tradingState == ReadBytes(orderbook.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(tradingState.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         orderbook    |-> orderbook.value,
         tradingState |-> tradingState.value,
         reason       |-> reason.value ], reason.rest)

ZeroOrderbookTradingActionMessage ==
    [ timestamp    |-> [i \in 1 .. 4 |-> 0],
      orderbook    |-> [i \in 1 .. 4 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0],
      reason       |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookTradingActionMessage ==
    { ZeroOrderbookTradingActionMessage }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Orderbook Attribute Message: 18 bytes                                   *)
(***************************************************************************)

OrderbookAttributeMessage ==
    [ timestamp      : Sample(4),
      orderbook      : Sample(4),
      attributeValue : Sample(8),
      attributeType  : Sample(1),
      reason         : Sample(1) ]

EncodeOrderbookAttributeMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.attributeValue
        \o message.attributeType
        \o message.reason

DecodeOrderbookAttributeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET attributeValue == ReadBytes(orderbook.rest, 8) IN IF ~attributeValue.ok THEN Fail ELSE
    LET attributeType == ReadBytes(attributeValue.rest, 1) IN IF ~attributeType.ok THEN Fail ELSE
    LET reason == ReadBytes(attributeType.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         orderbook      |-> orderbook.value,
         attributeValue |-> attributeValue.value,
         attributeType  |-> attributeType.value,
         reason         |-> reason.value ], reason.rest)

ZeroOrderbookAttributeMessage ==
    [ timestamp      |-> [i \in 1 .. 4 |-> 0],
      orderbook      |-> [i \in 1 .. 4 |-> 0],
      attributeValue |-> [i \in 1 .. 8 |-> 0],
      attributeType  |-> [i \in 1 .. 1 |-> 0],
      reason         |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Attribute Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookAttributeMessage ==
    { ZeroOrderbookAttributeMessage }
        \cup { [ZeroOrderbookAttributeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookAttributeMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookAttributeMessage EXCEPT !.attributeValue = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookAttributeMessage EXCEPT !.attributeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookAttributeMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Firm Directory Message: 38 bytes                                        *)
(***************************************************************************)

FirmDirectoryMessage ==
    [ timestamp : Sample(4),
      firmId    : Sample(4),
      firmCode  : Sample(30) ]

EncodeFirmDirectoryMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.firmCode

DecodeFirmDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET firmCode == ReadBytes(firmId.rest, 30) IN IF ~firmCode.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         firmId    |-> firmId.value,
         firmCode  |-> firmCode.value ], firmCode.rest)

ZeroFirmDirectoryMessage ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0],
      firmId    |-> [i \in 1 .. 4 |-> 0],
      firmCode  |-> [i \in 1 .. 30 |-> 0] ]

(* Firm Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedFirmDirectoryMessage ==
    { ZeroFirmDirectoryMessage }
        \cup { [ZeroFirmDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroFirmDirectoryMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroFirmDirectoryMessage EXCEPT !.firmCode = one] : one \in Sample(30) }

(***************************************************************************)
(* Add Order Message: 37 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timestamp   : Sample(4),
      orderNumber : Sample(8),
      orderVerb   : Sample(1),
      quantity    : Sample(8),
      orderbook   : Sample(4),
      price       : Sample(8),
      firmId      : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.timestamp
        \o message.orderNumber
        \o message.orderVerb
        \o message.quantity
        \o message.orderbook
        \o message.price
        \o message.firmId

DecodeAddOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderVerb == ReadBytes(orderNumber.rest, 1) IN IF ~orderVerb.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderVerb.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(quantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET price == ReadBytes(orderbook.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET firmId == ReadBytes(price.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         orderNumber |-> orderNumber.value,
         orderVerb   |-> orderVerb.value,
         quantity    |-> quantity.value,
         orderbook   |-> orderbook.value,
         price       |-> price.value,
         firmId      |-> firmId.value ], firmId.rest)

ZeroAddOrderMessage ==
    [ timestamp   |-> [i \in 1 .. 4 |-> 0],
      orderNumber |-> [i \in 1 .. 8 |-> 0],
      orderVerb   |-> [i \in 1 .. 1 |-> 0],
      quantity    |-> [i \in 1 .. 8 |-> 0],
      orderbook   |-> [i \in 1 .. 4 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      firmId      |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderVerb = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.firmId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 33 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp        : Sample(4),
      orderNumber      : Sample(8),
      executedQuantity : Sample(8),
      matchNumber      : Sample(8),
      printable        : Sample(1),
      aggressorFirmId  : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.orderNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.printable
        \o message.aggressorFirmId

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderNumber.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET aggressorFirmId == ReadBytes(printable.rest, 4) IN IF ~aggressorFirmId.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderNumber      |-> orderNumber.value,
         executedQuantity |-> executedQuantity.value,
         matchNumber      |-> matchNumber.value,
         printable        |-> printable.value,
         aggressorFirmId  |-> aggressorFirmId.value ], aggressorFirmId.rest)

ZeroOrderExecutedMessage ==
    [ timestamp        |-> [i \in 1 .. 4 |-> 0],
      orderNumber      |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      matchNumber      |-> [i \in 1 .. 8 |-> 0],
      printable        |-> [i \in 1 .. 1 |-> 0],
      aggressorFirmId  |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.aggressorFirmId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Message: 37 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ timestamp        : Sample(4),
      orderNumber      : Sample(8),
      executedQuantity : Sample(8),
      matchNumber      : Sample(8),
      printable        : Sample(1),
      executionPrice   : Sample(8) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.timestamp
        \o message.orderNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.printable
        \o message.executionPrice

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderNumber.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(printable.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderNumber      |-> orderNumber.value,
         executedQuantity |-> executedQuantity.value,
         matchNumber      |-> matchNumber.value,
         printable        |-> printable.value,
         executionPrice   |-> executionPrice.value ], executionPrice.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ timestamp        |-> [i \in 1 .. 4 |-> 0],
      orderNumber      |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      matchNumber      |-> [i \in 1 .. 8 |-> 0],
      printable        |-> [i \in 1 .. 1 |-> 0],
      executionPrice   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Broken Trade Message: 13 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp   : Sample(4),
      matchNumber : Sample(8),
      reason      : Sample(1) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.matchNumber
        \o message.reason

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(timestamp.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET reason == ReadBytes(matchNumber.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         matchNumber |-> matchNumber.value,
         reason      |-> reason.value ], reason.rest)

ZeroBrokenTradeMessage ==
    [ timestamp   |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 8 |-> 0],
      reason      |-> [i \in 1 .. 1 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Delete Message: 12 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ timestamp   : Sample(4),
      orderNumber : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.timestamp
        \o message.orderNumber

DecodeOrderDeleteMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         orderNumber |-> orderNumber.value ], orderNumber.rest)

ZeroOrderDeleteMessage ==
    [ timestamp   |-> [i \in 1 .. 4 |-> 0],
      orderNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Replace Message: 36 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ timestamp           : Sample(4),
      originalOrderNumber : Sample(8),
      newOrderNumber      : Sample(8),
      quantity            : Sample(8),
      price               : Sample(8) ]

EncodeOrderReplaceMessage(message) ==
    message.timestamp
        \o message.originalOrderNumber
        \o message.newOrderNumber
        \o message.quantity
        \o message.price

DecodeOrderReplaceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalOrderNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalOrderNumber.ok THEN Fail ELSE
    LET newOrderNumber == ReadBytes(originalOrderNumber.rest, 8) IN IF ~newOrderNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(newOrderNumber.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         originalOrderNumber |-> originalOrderNumber.value,
         newOrderNumber      |-> newOrderNumber.value,
         quantity            |-> quantity.value,
         price               |-> price.value ], price.rest)

ZeroOrderReplaceMessage ==
    [ timestamp           |-> [i \in 1 .. 4 |-> 0],
      originalOrderNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderNumber      |-> [i \in 1 .. 8 |-> 0],
      quantity            |-> [i \in 1 .. 8 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Indicative Price Quantity Message: 57 bytes                             *)
(***************************************************************************)

IndicativePriceQuantityMessage ==
    [ timestamp                  : Sample(4),
      theoreticalOpeningQuantity : Sample(8),
      orderbook                  : Sample(4),
      bestBid                    : Sample(8),
      bestOffer                  : Sample(8),
      theoreticalOpeningPrice    : Sample(8),
      crossType                  : Sample(1),
      bestBidSize                : Sample(8),
      bestOfferSize              : Sample(8) ]

EncodeIndicativePriceQuantityMessage(message) ==
    message.timestamp
        \o message.theoreticalOpeningQuantity
        \o message.orderbook
        \o message.bestBid
        \o message.bestOffer
        \o message.theoreticalOpeningPrice
        \o message.crossType
        \o message.bestBidSize
        \o message.bestOfferSize

DecodeIndicativePriceQuantityMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET theoreticalOpeningQuantity == ReadBytes(timestamp.rest, 8) IN IF ~theoreticalOpeningQuantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(theoreticalOpeningQuantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET bestBid == ReadBytes(orderbook.rest, 8) IN IF ~bestBid.ok THEN Fail ELSE
    LET bestOffer == ReadBytes(bestBid.rest, 8) IN IF ~bestOffer.ok THEN Fail ELSE
    LET theoreticalOpeningPrice == ReadBytes(bestOffer.rest, 8) IN IF ~theoreticalOpeningPrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(theoreticalOpeningPrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(crossType.rest, 8) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestOfferSize == ReadBytes(bestBidSize.rest, 8) IN IF ~bestOfferSize.ok THEN Fail ELSE
    Ok([ timestamp                  |-> timestamp.value,
         theoreticalOpeningQuantity |-> theoreticalOpeningQuantity.value,
         orderbook                  |-> orderbook.value,
         bestBid                    |-> bestBid.value,
         bestOffer                  |-> bestOffer.value,
         theoreticalOpeningPrice    |-> theoreticalOpeningPrice.value,
         crossType                  |-> crossType.value,
         bestBidSize                |-> bestBidSize.value,
         bestOfferSize              |-> bestOfferSize.value ], bestOfferSize.rest)

ZeroIndicativePriceQuantityMessage ==
    [ timestamp                  |-> [i \in 1 .. 4 |-> 0],
      theoreticalOpeningQuantity |-> [i \in 1 .. 8 |-> 0],
      orderbook                  |-> [i \in 1 .. 4 |-> 0],
      bestBid                    |-> [i \in 1 .. 8 |-> 0],
      bestOffer                  |-> [i \in 1 .. 8 |-> 0],
      theoreticalOpeningPrice    |-> [i \in 1 .. 8 |-> 0],
      crossType                  |-> [i \in 1 .. 1 |-> 0],
      bestBidSize                |-> [i \in 1 .. 8 |-> 0],
      bestOfferSize              |-> [i \in 1 .. 8 |-> 0] ]

(* Indicative Price Quantity Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativePriceQuantityMessage ==
    { ZeroIndicativePriceQuantityMessage }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.theoreticalOpeningQuantity = one] : one \in Sample(8) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.bestBid = one] : one \in Sample(8) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.bestOffer = one] : one \in Sample(8) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.theoreticalOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.bestBidSize = one] : one \in Sample(8) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.bestOfferSize = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 43 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp        : Sample(4),
      executedQuantity : Sample(8),
      orderbook        : Sample(4),
      printable        : Sample(1),
      executionPrice   : Sample(8),
      matchNumber      : Sample(8),
      tradeIndicator   : Sample(1),
      buyFirmId        : Sample(4),
      sellFirmId       : Sample(4),
      tradeSource      : Sample(1) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.executedQuantity
        \o message.orderbook
        \o message.printable
        \o message.executionPrice
        \o message.matchNumber
        \o message.tradeIndicator
        \o message.buyFirmId
        \o message.sellFirmId
        \o message.tradeSource

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(timestamp.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(executedQuantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET printable == ReadBytes(orderbook.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(printable.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executionPrice.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET tradeIndicator == ReadBytes(matchNumber.rest, 1) IN IF ~tradeIndicator.ok THEN Fail ELSE
    LET buyFirmId == ReadBytes(tradeIndicator.rest, 4) IN IF ~buyFirmId.ok THEN Fail ELSE
    LET sellFirmId == ReadBytes(buyFirmId.rest, 4) IN IF ~sellFirmId.ok THEN Fail ELSE
    LET tradeSource == ReadBytes(sellFirmId.rest, 1) IN IF ~tradeSource.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         executedQuantity |-> executedQuantity.value,
         orderbook        |-> orderbook.value,
         printable        |-> printable.value,
         executionPrice   |-> executionPrice.value,
         matchNumber      |-> matchNumber.value,
         tradeIndicator   |-> tradeIndicator.value,
         buyFirmId        |-> buyFirmId.value,
         sellFirmId       |-> sellFirmId.value,
         tradeSource      |-> tradeSource.value ], tradeSource.rest)

ZeroTradeMessage ==
    [ timestamp        |-> [i \in 1 .. 4 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      orderbook        |-> [i \in 1 .. 4 |-> 0],
      printable        |-> [i \in 1 .. 1 |-> 0],
      executionPrice   |-> [i \in 1 .. 8 |-> 0],
      matchNumber      |-> [i \in 1 .. 8 |-> 0],
      tradeIndicator   |-> [i \in 1 .. 1 |-> 0],
      buyFirmId        |-> [i \in 1 .. 4 |-> 0],
      sellFirmId       |-> [i \in 1 .. 4 |-> 0],
      tradeSource      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.buyFirmId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.sellFirmId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeSource = one] : one \in Sample(1) }

(***************************************************************************)
(* News Message: 891 bytes                                                 *)
(***************************************************************************)

NewsMessage ==
    [ timestamp                      : Sample(4),
      orderbook                      : Sample(4),
      newsId                         : Sample(4),
      firmCode                       : Sample(30),
      title                          : Sample(81),
      referenceNullTerminatedChar256 : Sample(256),
      newsText                       : Sample(512) ]

EncodeNewsMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.newsId
        \o message.firmCode
        \o message.title
        \o message.referenceNullTerminatedChar256
        \o message.newsText

DecodeNewsMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET newsId == ReadBytes(orderbook.rest, 4) IN IF ~newsId.ok THEN Fail ELSE
    LET firmCode == ReadBytes(newsId.rest, 30) IN IF ~firmCode.ok THEN Fail ELSE
    LET title == ReadBytes(firmCode.rest, 81) IN IF ~title.ok THEN Fail ELSE
    LET referenceNullTerminatedChar256 == ReadBytes(title.rest, 256) IN IF ~referenceNullTerminatedChar256.ok THEN Fail ELSE
    LET newsText == ReadBytes(referenceNullTerminatedChar256.rest, 512) IN IF ~newsText.ok THEN Fail ELSE
    Ok([ timestamp                      |-> timestamp.value,
         orderbook                      |-> orderbook.value,
         newsId                         |-> newsId.value,
         firmCode                       |-> firmCode.value,
         title                          |-> title.value,
         referenceNullTerminatedChar256 |-> referenceNullTerminatedChar256.value,
         newsText                       |-> newsText.value ], newsText.rest)

ZeroNewsMessage ==
    [ timestamp                      |-> [i \in 1 .. 4 |-> 0],
      orderbook                      |-> [i \in 1 .. 4 |-> 0],
      newsId                         |-> [i \in 1 .. 4 |-> 0],
      firmCode                       |-> [i \in 1 .. 30 |-> 0],
      title                          |-> [i \in 1 .. 81 |-> 0],
      referenceNullTerminatedChar256 |-> [i \in 1 .. 256 |-> 0],
      newsText                       |-> [i \in 1 .. 512 |-> 0] ]

(* News Message at zero, then each field in turn at the values it is checked at *)
CheckedNewsMessage ==
    { ZeroNewsMessage }
        \cup { [ZeroNewsMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.newsId = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.firmCode = one] : one \in Sample(30) }
        \cup { [ZeroNewsMessage EXCEPT !.title = one] : one \in Sample(81) }
        \cup { [ZeroNewsMessage EXCEPT !.referenceNullTerminatedChar256 = one] : one \in Sample(256) }
        \cup { [ZeroNewsMessage EXCEPT !.newsText = one] : one \in Sample(512) }

(***************************************************************************)
(* Index Member Directory Message: 20 bytes                                *)
(***************************************************************************)

IndexMemberDirectoryMessage ==
    [ timestamp       : Sample(4),
      indexOrderbook  : Sample(4),
      memberOrderbook : Sample(4),
      weight          : Sample(8) ]

EncodeIndexMemberDirectoryMessage(message) ==
    message.timestamp
        \o message.indexOrderbook
        \o message.memberOrderbook
        \o message.weight

DecodeIndexMemberDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET indexOrderbook == ReadBytes(timestamp.rest, 4) IN IF ~indexOrderbook.ok THEN Fail ELSE
    LET memberOrderbook == ReadBytes(indexOrderbook.rest, 4) IN IF ~memberOrderbook.ok THEN Fail ELSE
    LET weight == ReadBytes(memberOrderbook.rest, 8) IN IF ~weight.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         indexOrderbook  |-> indexOrderbook.value,
         memberOrderbook |-> memberOrderbook.value,
         weight          |-> weight.value ], weight.rest)

ZeroIndexMemberDirectoryMessage ==
    [ timestamp       |-> [i \in 1 .. 4 |-> 0],
      indexOrderbook  |-> [i \in 1 .. 4 |-> 0],
      memberOrderbook |-> [i \in 1 .. 4 |-> 0],
      weight          |-> [i \in 1 .. 8 |-> 0] ]

(* Index Member Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMemberDirectoryMessage ==
    { ZeroIndexMemberDirectoryMessage }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.indexOrderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.memberOrderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.weight = one] : one \in Sample(8) }

(***************************************************************************)
(* Index Value Message: 16 bytes                                           *)
(***************************************************************************)

IndexValueMessage ==
    [ timestamp      : Sample(4),
      indexOrderbook : Sample(4),
      indexValue     : Sample(8) ]

EncodeIndexValueMessage(message) ==
    message.timestamp
        \o message.indexOrderbook
        \o message.indexValue

DecodeIndexValueMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET indexOrderbook == ReadBytes(timestamp.rest, 4) IN IF ~indexOrderbook.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indexOrderbook.rest, 8) IN IF ~indexValue.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         indexOrderbook |-> indexOrderbook.value,
         indexValue     |-> indexValue.value ], indexValue.rest)

ZeroIndexValueMessage ==
    [ timestamp      |-> [i \in 1 .. 4 |-> 0],
      indexOrderbook |-> [i \in 1 .. 4 |-> 0],
      indexValue     |-> [i \in 1 .. 8 |-> 0] ]

(* Index Value Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueMessage ==
    { ZeroIndexValueMessage }
        \cup { [ZeroIndexValueMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueMessage EXCEPT !.indexOrderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueMessage EXCEPT !.indexValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

TimestampMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
PriceTickSizeMessageCode == 76  \* "L"
QuantityTickSizeMessageCode == 77  \* "M"
OrderbookDirectoryMessageCode == 82  \* "R"
OrderbookTradingActionMessageCode == 72  \* "H"
OrderbookAttributeMessageCode == 88  \* "X"
FirmDirectoryMessageCode == 70  \* "F"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
BrokenTradeMessageCode == 66  \* "B"
OrderDeleteMessageCode == 68  \* "D"
OrderReplaceMessageCode == 85  \* "U"
IndicativePriceQuantityMessageCode == 73  \* "I"
TradeMessageCode == 80  \* "P"
NewsMessageCode == 78  \* "N"
IndexMemberDirectoryMessageCode == 89  \* "Y"
IndexValueMessageCode == 90  \* "Z"

SequencedMessage ==
    [ tag : {TimestampMessageCode}, body : TimestampMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {PriceTickSizeMessageCode}, body : PriceTickSizeMessage ]
        \cup [ tag : {QuantityTickSizeMessageCode}, body : QuantityTickSizeMessage ]
        \cup [ tag : {OrderbookDirectoryMessageCode}, body : OrderbookDirectoryMessage ]
        \cup [ tag : {OrderbookTradingActionMessageCode}, body : OrderbookTradingActionMessage ]
        \cup [ tag : {OrderbookAttributeMessageCode}, body : OrderbookAttributeMessage ]
        \cup [ tag : {FirmDirectoryMessageCode}, body : FirmDirectoryMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {IndicativePriceQuantityMessageCode}, body : IndicativePriceQuantityMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {IndexMemberDirectoryMessageCode}, body : IndexMemberDirectoryMessage ]
        \cup [ tag : {IndexValueMessageCode}, body : IndexValueMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = TimestampMessageCode -> EncodeTimestampMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = PriceTickSizeMessageCode -> EncodePriceTickSizeMessage(message.body)
      [] message.tag = QuantityTickSizeMessageCode -> EncodeQuantityTickSizeMessage(message.body)
      [] message.tag = OrderbookDirectoryMessageCode -> EncodeOrderbookDirectoryMessage(message.body)
      [] message.tag = OrderbookTradingActionMessageCode -> EncodeOrderbookTradingActionMessage(message.body)
      [] message.tag = OrderbookAttributeMessageCode -> EncodeOrderbookAttributeMessage(message.body)
      [] message.tag = FirmDirectoryMessageCode -> EncodeFirmDirectoryMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = IndicativePriceQuantityMessageCode -> EncodeIndicativePriceQuantityMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = IndexMemberDirectoryMessageCode -> EncodeIndexMemberDirectoryMessage(message.body)
      [] message.tag = IndexValueMessageCode -> EncodeIndexValueMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = TimestampMessageCode -> DecodeTimestampMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = PriceTickSizeMessageCode -> DecodePriceTickSizeMessage(bytes)
              [] tag = QuantityTickSizeMessageCode -> DecodeQuantityTickSizeMessage(bytes)
              [] tag = OrderbookDirectoryMessageCode -> DecodeOrderbookDirectoryMessage(bytes)
              [] tag = OrderbookTradingActionMessageCode -> DecodeOrderbookTradingActionMessage(bytes)
              [] tag = OrderbookAttributeMessageCode -> DecodeOrderbookAttributeMessage(bytes)
              [] tag = FirmDirectoryMessageCode -> DecodeFirmDirectoryMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = IndicativePriceQuantityMessageCode -> DecodeIndicativePriceQuantityMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = IndexMemberDirectoryMessageCode -> DecodeIndexMemberDirectoryMessage(bytes)
              [] tag = IndexValueMessageCode -> DecodeIndexValueMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> TimestampMessageCode, body |-> ZeroTimestampMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> TimestampMessageCode, body |-> one] : one \in CheckedTimestampMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> PriceTickSizeMessageCode, body |-> one] : one \in CheckedPriceTickSizeMessage }
        \cup { [tag |-> QuantityTickSizeMessageCode, body |-> one] : one \in CheckedQuantityTickSizeMessage }
        \cup { [tag |-> OrderbookDirectoryMessageCode, body |-> one] : one \in CheckedOrderbookDirectoryMessage }
        \cup { [tag |-> OrderbookTradingActionMessageCode, body |-> one] : one \in CheckedOrderbookTradingActionMessage }
        \cup { [tag |-> OrderbookAttributeMessageCode, body |-> one] : one \in CheckedOrderbookAttributeMessage }
        \cup { [tag |-> FirmDirectoryMessageCode, body |-> one] : one \in CheckedFirmDirectoryMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> IndicativePriceQuantityMessageCode, body |-> one] : one \in CheckedIndicativePriceQuantityMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> IndexMemberDirectoryMessageCode, body |-> one] : one \in CheckedIndexMemberDirectoryMessage }
        \cup { [tag |-> IndexValueMessageCode, body |-> one] : one \in CheckedIndexValueMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* Does a Server Soup Bin Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionServerSoupBinTcpPacket(message) == message.serverPayload.tag \in {EndOfSessionCode}

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionServerSoupBinTcpPacket(one.value) /\ one.rest # << >> THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(* The runs of Server Soup Bin Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleServerSoupBinTcpPacketLists ==
    { run \in SampleLists(OneServerSoupBinTcpPacket) \cup { <<one, other>> : one \in OneServerSoupBinTcpPacket, other \in OneServerSoupBinTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionServerSoupBinTcpPacket(run[at]) }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleServerSoupBinTcpPacketLists ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleServerSoupBinTcpPacketLists }

(***************************************************************************)
(* What TLC checks                                                         *)
(***************************************************************************)

(* An integer a rule depends on writes its width and reads back what was written *)
RoundTripUIntLE ==
    \A width \in 1 .. 3 :
        \A value \in {0, 1, 255, 256, 65535} :
            (value < 256 ^ width) =>
                /\ Len(EncodeUIntLE(value, width)) = width
                /\ DecodeUIntLE(EncodeUIntLE(value, width)) = value
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestampMessage ==
    \A message \in CheckedTimestampMessage :
        LET read == DecodeTimestampMessage(EncodeTimestampMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceTickSizeMessage ==
    \A message \in CheckedPriceTickSizeMessage :
        LET read == DecodePriceTickSizeMessage(EncodePriceTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantityTickSizeMessage ==
    \A message \in CheckedQuantityTickSizeMessage :
        LET read == DecodeQuantityTickSizeMessage(EncodeQuantityTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookDirectoryMessage ==
    \A message \in CheckedOrderbookDirectoryMessage :
        LET read == DecodeOrderbookDirectoryMessage(EncodeOrderbookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookTradingActionMessage ==
    \A message \in CheckedOrderbookTradingActionMessage :
        LET read == DecodeOrderbookTradingActionMessage(EncodeOrderbookTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Attribute Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookAttributeMessage ==
    \A message \in CheckedOrderbookAttributeMessage :
        LET read == DecodeOrderbookAttributeMessage(EncodeOrderbookAttributeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmDirectoryMessage ==
    \A message \in CheckedFirmDirectoryMessage :
        LET read == DecodeFirmDirectoryMessage(EncodeFirmDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceMessage ==
    \A message \in CheckedOrderReplaceMessage :
        LET read == DecodeOrderReplaceMessage(EncodeOrderReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indicative Price Quantity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativePriceQuantityMessage ==
    \A message \in CheckedIndicativePriceQuantityMessage :
        LET read == DecodeIndicativePriceQuantityMessage(EncodeIndicativePriceQuantityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMessage ==
    \A message \in CheckedNewsMessage :
        LET read == DecodeNewsMessage(EncodeNewsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Member Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMemberDirectoryMessage ==
    \A message \in CheckedIndexMemberDirectoryMessage :
        LET read == DecodeIndexMemberDirectoryMessage(EncodeIndexMemberDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueMessage ==
    \A message \in CheckedIndexValueMessage :
        LET read == DecodeIndexValueMessage(EncodeIndexValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

(* A Server Soup Bin Tcp Packet that ends the session is the last of its Server Packet: a run with one after it does not decode *)
EndsSessionLastServerSoupBinTcpPacket ==
    \A last \in { one \in OneServerSoupBinTcpPacket : EndsSessionServerSoupBinTcpPacket(one) } :
        \A after \in OneServerSoupBinTcpPacket :
            ~ReadServerSoupBinTcpPacketAll(EncodeServerSoupBinTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
