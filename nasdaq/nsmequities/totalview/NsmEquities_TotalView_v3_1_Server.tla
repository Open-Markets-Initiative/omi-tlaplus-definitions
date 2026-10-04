----------------- MODULE NsmEquities_TotalView_v3_1_Server -----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) TotalView Itch v3.1                                            *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ text : Sample(1) ]

EncodeDebugPacket(message) ==
    message.text

DecodeDebugPacket(bytes) ==
    LET text == ReadBytes(bytes, 1) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugPacket ==
    [ text |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.text = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 18 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

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
(* Seconds Message: 5 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ second : Sample(5) ]

EncodeSecondsMessage(message) ==
    message.second

DecodeSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 5) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroSecondsMessage ==
    [ second |-> [i \in 1 .. 5 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.second = one] : one \in Sample(5) }

(***************************************************************************)
(* Milliseconds Message: 3 bytes                                           *)
(***************************************************************************)

MillisecondsMessage ==
    [ millisecond : Sample(3) ]

EncodeMillisecondsMessage(message) ==
    message.millisecond

DecodeMillisecondsMessage(bytes) ==
    LET millisecond == ReadBytes(bytes, 3) IN IF ~millisecond.ok THEN Fail ELSE
    Ok([ millisecond |-> millisecond.value ], millisecond.rest)

ZeroMillisecondsMessage ==
    [ millisecond |-> [i \in 1 .. 3 |-> 0] ]

(* Milliseconds Message at zero, then each field in turn at the values it is checked at *)
CheckedMillisecondsMessage ==
    { ZeroMillisecondsMessage }
        \cup { [ZeroMillisecondsMessage EXCEPT !.millisecond = one] : one \in Sample(3) }

(***************************************************************************)
(* System Event Message: 1 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET eventCode == ReadBytes(bytes, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 15 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ stockAlpha6              : Sample(6),
      marketCategory           : Sample(1),
      financialStatusIndicator : Sample(1),
      roundLotSize             : Sample(6),
      roundLotsOnly            : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.stockAlpha6
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly

DecodeStockDirectoryMessage(bytes) ==
    LET stockAlpha6 == ReadBytes(bytes, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stockAlpha6.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 6) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    Ok([ stockAlpha6              |-> stockAlpha6.value,
         marketCategory           |-> marketCategory.value,
         financialStatusIndicator |-> financialStatusIndicator.value,
         roundLotSize             |-> roundLotSize.value,
         roundLotsOnly            |-> roundLotsOnly.value ], roundLotsOnly.rest)

ZeroStockDirectoryMessage ==
    [ stockAlpha6              |-> [i \in 1 .. 6 |-> 0],
      marketCategory           |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator |-> [i \in 1 .. 1 |-> 0],
      roundLotSize             |-> [i \in 1 .. 6 |-> 0],
      roundLotsOnly            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 12 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ stockAlpha6  : Sample(6),
      tradingState : Sample(1),
      reserved1    : Sample(1),
      reason       : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.stockAlpha6
        \o message.tradingState
        \o message.reserved1
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET stockAlpha6 == ReadBytes(bytes, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stockAlpha6.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingState.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reason == ReadBytes(reserved1.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ stockAlpha6  |-> stockAlpha6.value,
         tradingState |-> tradingState.value,
         reserved1    |-> reserved1.value,
         reason       |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ stockAlpha6  |-> [i \in 1 .. 6 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      reason       |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Participant Position Message: 13 bytes                           *)
(***************************************************************************)

MarketParticipantPositionMessage ==
    [ mpid                   : Sample(4),
      stockAlphanumeric6     : Sample(6),
      primaryMarketMaker     : Sample(1),
      marketMakerMode        : Sample(1),
      marketParticipantState : Sample(1) ]

EncodeMarketParticipantPositionMessage(message) ==
    message.mpid
        \o message.stockAlphanumeric6
        \o message.primaryMarketMaker
        \o message.marketMakerMode
        \o message.marketParticipantState

DecodeMarketParticipantPositionMessage(bytes) ==
    LET mpid == ReadBytes(bytes, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET stockAlphanumeric6 == ReadBytes(mpid.rest, 6) IN IF ~stockAlphanumeric6.ok THEN Fail ELSE
    LET primaryMarketMaker == ReadBytes(stockAlphanumeric6.rest, 1) IN IF ~primaryMarketMaker.ok THEN Fail ELSE
    LET marketMakerMode == ReadBytes(primaryMarketMaker.rest, 1) IN IF ~marketMakerMode.ok THEN Fail ELSE
    LET marketParticipantState == ReadBytes(marketMakerMode.rest, 1) IN IF ~marketParticipantState.ok THEN Fail ELSE
    Ok([ mpid                   |-> mpid.value,
         stockAlphanumeric6     |-> stockAlphanumeric6.value,
         primaryMarketMaker     |-> primaryMarketMaker.value,
         marketMakerMode        |-> marketMakerMode.value,
         marketParticipantState |-> marketParticipantState.value ], marketParticipantState.rest)

ZeroMarketParticipantPositionMessage ==
    [ mpid                   |-> [i \in 1 .. 4 |-> 0],
      stockAlphanumeric6     |-> [i \in 1 .. 6 |-> 0],
      primaryMarketMaker     |-> [i \in 1 .. 1 |-> 0],
      marketMakerMode        |-> [i \in 1 .. 1 |-> 0],
      marketParticipantState |-> [i \in 1 .. 1 |-> 0] ]

(* Market Participant Position Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketParticipantPositionMessage ==
    { ZeroMarketParticipantPositionMessage }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.stockAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.primaryMarketMaker = one] : one \in Sample(1) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.marketMakerMode = one] : one \in Sample(1) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.marketParticipantState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 35 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ orderReferenceNumber : Sample(12),
      side                 : Sample(1),
      sharesNumeric6       : Sample(6),
      stockAlpha6          : Sample(6),
      price                : Sample(10) ]

EncodeAddOrderMessage(message) ==
    message.orderReferenceNumber
        \o message.side
        \o message.sharesNumeric6
        \o message.stockAlpha6
        \o message.price

DecodeAddOrderMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesNumeric6 == ReadBytes(side.rest, 6) IN IF ~sharesNumeric6.ok THEN Fail ELSE
    LET stockAlpha6 == ReadBytes(sharesNumeric6.rest, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET price == ReadBytes(stockAlpha6.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         sharesNumeric6       |-> sharesNumeric6.value,
         stockAlpha6          |-> stockAlpha6.value,
         price                |-> price.value ], price.rest)

ZeroAddOrderMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      sharesNumeric6       |-> [i \in 1 .. 6 |-> 0],
      stockAlpha6          |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.sharesNumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(10) }

(***************************************************************************)
(* Add Order With Mpid Message: 39 bytes                                   *)
(***************************************************************************)

AddOrderWithMpidMessage ==
    [ orderReferenceNumber : Sample(12),
      side                 : Sample(1),
      sharesNumeric6       : Sample(6),
      stockAlpha6          : Sample(6),
      price                : Sample(10),
      attribution          : Sample(4) ]

EncodeAddOrderWithMpidMessage(message) ==
    message.orderReferenceNumber
        \o message.side
        \o message.sharesNumeric6
        \o message.stockAlpha6
        \o message.price
        \o message.attribution

DecodeAddOrderWithMpidMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesNumeric6 == ReadBytes(side.rest, 6) IN IF ~sharesNumeric6.ok THEN Fail ELSE
    LET stockAlpha6 == ReadBytes(sharesNumeric6.rest, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET price == ReadBytes(stockAlpha6.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 4) IN IF ~attribution.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         sharesNumeric6       |-> sharesNumeric6.value,
         stockAlpha6          |-> stockAlpha6.value,
         price                |-> price.value,
         attribution          |-> attribution.value ], attribution.rest)

ZeroAddOrderWithMpidMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      sharesNumeric6       |-> [i \in 1 .. 6 |-> 0],
      stockAlpha6          |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      attribution          |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order With Mpid Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderWithMpidMessage ==
    { ZeroAddOrderWithMpidMessage }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.sharesNumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.attribution = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 30 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ orderReferenceNumber : Sample(12),
      executedShares       : Sample(6),
      matchNumber          : Sample(12) ]

EncodeOrderExecutedMessage(message) ==
    message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber

DecodeOrderExecutedMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      executedShares       |-> [i \in 1 .. 6 |-> 0],
      matchNumber          |-> [i \in 1 .. 12 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Executed With Price Message: 41 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ orderReferenceNumber : Sample(12),
      executedShares       : Sample(6),
      matchNumber          : Sample(12),
      printable            : Sample(1),
      executionPrice       : Sample(10) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber
        \o message.printable
        \o message.executionPrice

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(printable.rest, 10) IN IF ~executionPrice.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         executionPrice       |-> executionPrice.value ], executionPrice.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      executedShares       |-> [i \in 1 .. 6 |-> 0],
      matchNumber          |-> [i \in 1 .. 12 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      executionPrice       |-> [i \in 1 .. 10 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedShares = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(10) }

(***************************************************************************)
(* Order Cancel Message: 18 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ orderReferenceNumber : Sample(12),
      canceledShares       : Sample(6) ]

EncodeOrderCancelMessage(message) ==
    message.orderReferenceNumber
        \o message.canceledShares

DecodeOrderCancelMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET canceledShares == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~canceledShares.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         canceledShares       |-> canceledShares.value ], canceledShares.rest)

ZeroOrderCancelMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      canceledShares       |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledShares = one] : one \in Sample(6) }

(***************************************************************************)
(* Order Delete Message: 12 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ orderReferenceNumber : Sample(12) ]

EncodeOrderDeleteMessage(message) ==
    message.orderReferenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Replace Message: 40 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ originalOrderReferenceNumber : Sample(12),
      newOrderReferenceNumber      : Sample(12),
      sharesNumeric6               : Sample(6),
      price                        : Sample(10) ]

EncodeOrderReplaceMessage(message) ==
    message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.sharesNumeric6
        \o message.price

DecodeOrderReplaceMessage(bytes) ==
    LET originalOrderReferenceNumber == ReadBytes(bytes, 12) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 12) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET sharesNumeric6 == ReadBytes(newOrderReferenceNumber.rest, 6) IN IF ~sharesNumeric6.ok THEN Fail ELSE
    LET price == ReadBytes(sharesNumeric6.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         sharesNumeric6               |-> sharesNumeric6.value,
         price                        |-> price.value ], price.rest)

ZeroOrderReplaceMessage ==
    [ originalOrderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 12 |-> 0],
      sharesNumeric6               |-> [i \in 1 .. 6 |-> 0],
      price                        |-> [i \in 1 .. 10 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.sharesNumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(10) }

(***************************************************************************)
(* Trade Message: 47 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ orderReferenceNumber : Sample(12),
      side                 : Sample(1),
      sharesNumeric6       : Sample(6),
      stockAlpha6          : Sample(6),
      price                : Sample(10),
      matchNumber          : Sample(12) ]

EncodeTradeMessage(message) ==
    message.orderReferenceNumber
        \o message.side
        \o message.sharesNumeric6
        \o message.stockAlpha6
        \o message.price
        \o message.matchNumber

DecodeTradeMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesNumeric6 == ReadBytes(side.rest, 6) IN IF ~sharesNumeric6.ok THEN Fail ELSE
    LET stockAlpha6 == ReadBytes(sharesNumeric6.rest, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET price == ReadBytes(stockAlpha6.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(price.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         sharesNumeric6       |-> sharesNumeric6.value,
         stockAlpha6          |-> stockAlpha6.value,
         price                |-> price.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroTradeMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      sharesNumeric6       |-> [i \in 1 .. 6 |-> 0],
      stockAlpha6          |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      matchNumber          |-> [i \in 1 .. 12 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.sharesNumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }

(***************************************************************************)
(* Cross Trade Message: 38 bytes                                           *)
(***************************************************************************)

CrossTradeMessage ==
    [ sharesNumeric9 : Sample(9),
      stockAlpha6    : Sample(6),
      crossPrice     : Sample(10),
      matchNumber    : Sample(12),
      crossType      : Sample(1) ]

EncodeCrossTradeMessage(message) ==
    message.sharesNumeric9
        \o message.stockAlpha6
        \o message.crossPrice
        \o message.matchNumber
        \o message.crossType

DecodeCrossTradeMessage(bytes) ==
    LET sharesNumeric9 == ReadBytes(bytes, 9) IN IF ~sharesNumeric9.ok THEN Fail ELSE
    LET stockAlpha6 == ReadBytes(sharesNumeric9.rest, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET crossPrice == ReadBytes(stockAlpha6.rest, 10) IN IF ~crossPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossPrice.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    Ok([ sharesNumeric9 |-> sharesNumeric9.value,
         stockAlpha6    |-> stockAlpha6.value,
         crossPrice     |-> crossPrice.value,
         matchNumber    |-> matchNumber.value,
         crossType      |-> crossType.value ], crossType.rest)

ZeroCrossTradeMessage ==
    [ sharesNumeric9 |-> [i \in 1 .. 9 |-> 0],
      stockAlpha6    |-> [i \in 1 .. 6 |-> 0],
      crossPrice     |-> [i \in 1 .. 10 |-> 0],
      matchNumber    |-> [i \in 1 .. 12 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossTradeMessage ==
    { ZeroCrossTradeMessage }
        \cup { [ZeroCrossTradeMessage EXCEPT !.sharesNumeric9 = one] : one \in Sample(9) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossPrice = one] : one \in Sample(10) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Trade Message: 12 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ matchNumber : Sample(12) ]

EncodeBrokenTradeMessage(message) ==
    message.matchNumber

DecodeBrokenTradeMessage(bytes) ==
    LET matchNumber == ReadBytes(bytes, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeMessage ==
    [ matchNumber |-> [i \in 1 .. 12 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }

(***************************************************************************)
(* Net Order Imbalance Indicator Message: 57 bytes                         *)
(***************************************************************************)

NetOrderImbalanceIndicatorMessage ==
    [ pairedShares            : Sample(9),
      imbalanceShares         : Sample(9),
      imbalanceDirection      : Sample(1),
      stockAlpha6             : Sample(6),
      farPrice                : Sample(10),
      nearPrice               : Sample(10),
      currentReferencePrice   : Sample(10),
      crossType               : Sample(1),
      priceVariationIndicator : Sample(1) ]

EncodeNetOrderImbalanceIndicatorMessage(message) ==
    message.pairedShares
        \o message.imbalanceShares
        \o message.imbalanceDirection
        \o message.stockAlpha6
        \o message.farPrice
        \o message.nearPrice
        \o message.currentReferencePrice
        \o message.crossType
        \o message.priceVariationIndicator

DecodeNetOrderImbalanceIndicatorMessage(bytes) ==
    LET pairedShares == ReadBytes(bytes, 9) IN IF ~pairedShares.ok THEN Fail ELSE
    LET imbalanceShares == ReadBytes(pairedShares.rest, 9) IN IF ~imbalanceShares.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceShares.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET stockAlpha6 == ReadBytes(imbalanceDirection.rest, 6) IN IF ~stockAlpha6.ok THEN Fail ELSE
    LET farPrice == ReadBytes(stockAlpha6.rest, 10) IN IF ~farPrice.ok THEN Fail ELSE
    LET nearPrice == ReadBytes(farPrice.rest, 10) IN IF ~nearPrice.ok THEN Fail ELSE
    LET currentReferencePrice == ReadBytes(nearPrice.rest, 10) IN IF ~currentReferencePrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(currentReferencePrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceVariationIndicator == ReadBytes(crossType.rest, 1) IN IF ~priceVariationIndicator.ok THEN Fail ELSE
    Ok([ pairedShares            |-> pairedShares.value,
         imbalanceShares         |-> imbalanceShares.value,
         imbalanceDirection      |-> imbalanceDirection.value,
         stockAlpha6             |-> stockAlpha6.value,
         farPrice                |-> farPrice.value,
         nearPrice               |-> nearPrice.value,
         currentReferencePrice   |-> currentReferencePrice.value,
         crossType               |-> crossType.value,
         priceVariationIndicator |-> priceVariationIndicator.value ], priceVariationIndicator.rest)

ZeroNetOrderImbalanceIndicatorMessage ==
    [ pairedShares            |-> [i \in 1 .. 9 |-> 0],
      imbalanceShares         |-> [i \in 1 .. 9 |-> 0],
      imbalanceDirection      |-> [i \in 1 .. 1 |-> 0],
      stockAlpha6             |-> [i \in 1 .. 6 |-> 0],
      farPrice                |-> [i \in 1 .. 10 |-> 0],
      nearPrice               |-> [i \in 1 .. 10 |-> 0],
      currentReferencePrice   |-> [i \in 1 .. 10 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      priceVariationIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Net Order Imbalance Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedNetOrderImbalanceIndicatorMessage ==
    { ZeroNetOrderImbalanceIndicatorMessage }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.pairedShares = one] : one \in Sample(9) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceShares = one] : one \in Sample(9) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.stockAlpha6 = one] : one \in Sample(6) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.farPrice = one] : one \in Sample(10) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.nearPrice = one] : one \in Sample(10) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.currentReferencePrice = one] : one \in Sample(10) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.priceVariationIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Message Type                             *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
MillisecondsMessageCode == 77  \* "M"
SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
MarketParticipantPositionMessageCode == 76  \* "L"
AddOrderMessageCode == 65  \* "A"
AddOrderWithMpidMessageCode == 70  \* "F"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderCancelMessageCode == 88  \* "X"
OrderDeleteMessageCode == 68  \* "D"
OrderReplaceMessageCode == 85  \* "U"
TradeMessageCode == 80  \* "P"
CrossTradeMessageCode == 81  \* "Q"
BrokenTradeMessageCode == 66  \* "B"
NetOrderImbalanceIndicatorMessageCode == 73  \* "I"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {MillisecondsMessageCode}, body : MillisecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {MarketParticipantPositionMessageCode}, body : MarketParticipantPositionMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddOrderWithMpidMessageCode}, body : AddOrderWithMpidMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {CrossTradeMessageCode}, body : CrossTradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {NetOrderImbalanceIndicatorMessageCode}, body : NetOrderImbalanceIndicatorMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = MillisecondsMessageCode -> EncodeMillisecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = MarketParticipantPositionMessageCode -> EncodeMarketParticipantPositionMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddOrderWithMpidMessageCode -> EncodeAddOrderWithMpidMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = CrossTradeMessageCode -> EncodeCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = NetOrderImbalanceIndicatorMessageCode -> EncodeNetOrderImbalanceIndicatorMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = MillisecondsMessageCode -> DecodeMillisecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = MarketParticipantPositionMessageCode -> DecodeMarketParticipantPositionMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddOrderWithMpidMessageCode -> DecodeAddOrderWithMpidMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = CrossTradeMessageCode -> DecodeCrossTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = NetOrderImbalanceIndicatorMessageCode -> DecodeNetOrderImbalanceIndicatorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> MillisecondsMessageCode, body |-> one] : one \in CheckedMillisecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> MarketParticipantPositionMessageCode, body |-> one] : one \in CheckedMarketParticipantPositionMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddOrderWithMpidMessageCode, body |-> one] : one \in CheckedAddOrderWithMpidMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> CrossTradeMessageCode, body |-> one] : one \in CheckedCrossTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> NetOrderImbalanceIndicatorMessageCode, body |-> one] : one \in CheckedNetOrderImbalanceIndicatorMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(messageType.value, messageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
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

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverPayload : ServerPayload,
      soupLf        : Sample(1) ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)
        \o message.soupLf

DecodeServerPacket(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    LET soupLf == ReadBytes(serverPayload.rest, 1) IN IF ~soupLf.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value,
         soupLf        |-> soupLf.value ], soupLf.rest)

ZeroServerPacket ==
    [ serverPayload |-> ZeroServerPayload,
      soupLf        |-> [i \in 1 .. 1 |-> 0] ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }
        \cup { [ZeroServerPacket EXCEPT !.soupLf = one] : one \in Sample(1) }

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Milliseconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMillisecondsMessage ==
    \A message \in CheckedMillisecondsMessage :
        LET read == DecodeMillisecondsMessage(EncodeMillisecondsMessage(message))
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

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Participant Position Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketParticipantPositionMessage ==
    \A message \in CheckedMarketParticipantPositionMessage :
        LET read == DecodeMarketParticipantPositionMessage(EncodeMarketParticipantPositionMessage(message))
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

(* Every Add Order With Mpid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderWithMpidMessage ==
    \A message \in CheckedAddOrderWithMpidMessage :
        LET read == DecodeAddOrderWithMpidMessage(EncodeAddOrderWithMpidMessage(message))
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

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossTradeMessage ==
    \A message \in CheckedCrossTradeMessage :
        LET read == DecodeCrossTradeMessage(EncodeCrossTradeMessage(message))
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

(* Every Net Order Imbalance Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNetOrderImbalanceIndicatorMessage ==
    \A message \in CheckedNetOrderImbalanceIndicatorMessage :
        LET read == DecodeNetOrderImbalanceIndicatorMessage(EncodeNetOrderImbalanceIndicatorMessage(message))
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

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
