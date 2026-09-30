---------------- MODULE NsmEquities_TotalView_v4_0_f_Server ----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) TotalView Itch v4.0.f                                          *)
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
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

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
(* Timestamp Message: 4 bytes                                              *)
(***************************************************************************)

TimestampMessage ==
    [ second : Sample(4) ]

EncodeTimestampMessage(message) ==
    message.second

DecodeTimestampMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimestampMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp Message at zero, then each field in turn at the values it is checked at *)
CheckedTimestampMessage ==
    { ZeroTimestampMessage }
        \cup { [ZeroTimestampMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 5 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 17 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ nanoseconds              : Sample(4),
      stock                    : Sample(6),
      marketCategory           : Sample(1),
      financialStatusIndicator : Sample(1),
      roundLotSize             : Sample(4),
      roundLotsOnly            : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.nanoseconds
        \o message.stock
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly

DecodeStockDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET stock == ReadBytes(nanoseconds.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    Ok([ nanoseconds              |-> nanoseconds.value,
         stock                    |-> stock.value,
         marketCategory           |-> marketCategory.value,
         financialStatusIndicator |-> financialStatusIndicator.value,
         roundLotSize             |-> roundLotSize.value,
         roundLotsOnly            |-> roundLotsOnly.value ], roundLotsOnly.rest)

ZeroStockDirectoryMessage ==
    [ nanoseconds              |-> [i \in 1 .. 4 |-> 0],
      stock                    |-> [i \in 1 .. 6 |-> 0],
      marketCategory           |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator |-> [i \in 1 .. 1 |-> 0],
      roundLotSize             |-> [i \in 1 .. 4 |-> 0],
      roundLotsOnly            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 16 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ nanoseconds  : Sample(4),
      stock        : Sample(6),
      tradingState : Sample(1),
      reserved     : Sample(1),
      reason       : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.nanoseconds
        \o message.stock
        \o message.tradingState
        \o message.reserved
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET stock == ReadBytes(nanoseconds.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stock.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingState.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET reason == ReadBytes(reserved.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         stock        |-> stock.value,
         tradingState |-> tradingState.value,
         reserved     |-> reserved.value,
         reason       |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      stock        |-> [i \in 1 .. 6 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0],
      reserved     |-> [i \in 1 .. 1 |-> 0],
      reason       |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Participant Position Message: 17 bytes                           *)
(***************************************************************************)

MarketParticipantPositionMessage ==
    [ nanoseconds            : Sample(4),
      mpid                   : Sample(4),
      stock                  : Sample(6),
      primaryMarketMaker     : Sample(1),
      marketMakerMode        : Sample(1),
      marketParticipantState : Sample(1) ]

EncodeMarketParticipantPositionMessage(message) ==
    message.nanoseconds
        \o message.mpid
        \o message.stock
        \o message.primaryMarketMaker
        \o message.marketMakerMode
        \o message.marketParticipantState

DecodeMarketParticipantPositionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET mpid == ReadBytes(nanoseconds.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET stock == ReadBytes(mpid.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET primaryMarketMaker == ReadBytes(stock.rest, 1) IN IF ~primaryMarketMaker.ok THEN Fail ELSE
    LET marketMakerMode == ReadBytes(primaryMarketMaker.rest, 1) IN IF ~marketMakerMode.ok THEN Fail ELSE
    LET marketParticipantState == ReadBytes(marketMakerMode.rest, 1) IN IF ~marketParticipantState.ok THEN Fail ELSE
    Ok([ nanoseconds            |-> nanoseconds.value,
         mpid                   |-> mpid.value,
         stock                  |-> stock.value,
         primaryMarketMaker     |-> primaryMarketMaker.value,
         marketMakerMode        |-> marketMakerMode.value,
         marketParticipantState |-> marketParticipantState.value ], marketParticipantState.rest)

ZeroMarketParticipantPositionMessage ==
    [ nanoseconds            |-> [i \in 1 .. 4 |-> 0],
      mpid                   |-> [i \in 1 .. 4 |-> 0],
      stock                  |-> [i \in 1 .. 6 |-> 0],
      primaryMarketMaker     |-> [i \in 1 .. 1 |-> 0],
      marketMakerMode        |-> [i \in 1 .. 1 |-> 0],
      marketParticipantState |-> [i \in 1 .. 1 |-> 0] ]

(* Market Participant Position Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketParticipantPositionMessage ==
    { ZeroMarketParticipantPositionMessage }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.primaryMarketMaker = one] : one \in Sample(1) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.marketMakerMode = one] : one \in Sample(1) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.marketParticipantState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 28 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8),
      side                 : Sample(1),
      shares               : Sample(4),
      stock                : Sample(6),
      price                : Sample(4),
      display              : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber
        \o message.side
        \o message.shares
        \o message.stock
        \o message.price
        \o message.display

DecodeAddOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET display == ReadBytes(price.rest, 1) IN IF ~display.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         display              |-> display.value ], display.rest)

ZeroAddOrderMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      display              |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.display = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order With Mpid Message: 31 bytes                                   *)
(***************************************************************************)

AddOrderWithMpidMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8),
      side                 : Sample(1),
      shares               : Sample(4),
      stock                : Sample(6),
      price                : Sample(4),
      attribution          : Sample(4) ]

EncodeAddOrderWithMpidMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber
        \o message.side
        \o message.shares
        \o message.stock
        \o message.price
        \o message.attribution

DecodeAddOrderWithMpidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 4) IN IF ~attribution.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         attribution          |-> attribution.value ], attribution.rest)

ZeroAddOrderWithMpidMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      attribution          |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order With Mpid Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderWithMpidMessage ==
    { ZeroAddOrderWithMpidMessage }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidMessage EXCEPT !.attribution = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 24 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8),
      executedShares       : Sample(4),
      matchNumber          : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber

DecodeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed With Price Message: 29 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8),
      executedShares       : Sample(4),
      matchNumber          : Sample(8),
      printable            : Sample(1),
      executionPrice       : Sample(4) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber
        \o message.printable
        \o message.executionPrice

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(printable.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         executionPrice       |-> executionPrice.value ], executionPrice.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      executionPrice       |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 16 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8),
      canceledShares       : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber
        \o message.canceledShares

DecodeOrderCancelMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET canceledShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~canceledShares.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         canceledShares       |-> canceledShares.value ], canceledShares.rest)

ZeroOrderCancelMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      canceledShares       |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledShares = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Delete Message: 12 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Replace Message: 29 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ nanoseconds                  : Sample(4),
      originalOrderReferenceNumber : Sample(8),
      newOrderReferenceNumber      : Sample(8),
      shares                       : Sample(4),
      price                        : Sample(4),
      display                      : Sample(1) ]

EncodeOrderReplaceMessage(message) ==
    message.nanoseconds
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.shares
        \o message.price
        \o message.display

DecodeOrderReplaceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 8) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET shares == ReadBytes(newOrderReferenceNumber.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET display == ReadBytes(price.rest, 1) IN IF ~display.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         shares                       |-> shares.value,
         price                        |-> price.value,
         display                      |-> display.value ], display.rest)

ZeroOrderReplaceMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      shares                       |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 4 |-> 0],
      display                      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.display = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Display Message: 12 bytes                                         *)
(***************************************************************************)

OrderDisplayMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8) ]

EncodeOrderDisplayMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber

DecodeOrderDisplayMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDisplayMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Display Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDisplayMessage ==
    { ZeroOrderDisplayMessage }
        \cup { [ZeroOrderDisplayMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDisplayMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 35 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanoseconds          : Sample(4),
      orderReferenceNumber : Sample(8),
      side                 : Sample(1),
      shares               : Sample(4),
      stock                : Sample(6),
      price                : Sample(4),
      matchNumber          : Sample(8) ]

EncodeTradeMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumber
        \o message.side
        \o message.shares
        \o message.stock
        \o message.price
        \o message.matchNumber

DecodeTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(price.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroTradeMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Cross Trade Message: 31 bytes                                           *)
(***************************************************************************)

CrossTradeMessage ==
    [ nanoseconds : Sample(4),
      crossShares : Sample(8),
      stock       : Sample(6),
      crossPrice  : Sample(4),
      matchNumber : Sample(8),
      crossType   : Sample(1) ]

EncodeCrossTradeMessage(message) ==
    message.nanoseconds
        \o message.crossShares
        \o message.stock
        \o message.crossPrice
        \o message.matchNumber
        \o message.crossType

DecodeCrossTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET crossShares == ReadBytes(nanoseconds.rest, 8) IN IF ~crossShares.ok THEN Fail ELSE
    LET stock == ReadBytes(crossShares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET crossPrice == ReadBytes(stock.rest, 4) IN IF ~crossPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossPrice.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         crossShares |-> crossShares.value,
         stock       |-> stock.value,
         crossPrice  |-> crossPrice.value,
         matchNumber |-> matchNumber.value,
         crossType   |-> crossType.value ], crossType.rest)

ZeroCrossTradeMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      crossShares |-> [i \in 1 .. 8 |-> 0],
      stock       |-> [i \in 1 .. 6 |-> 0],
      crossPrice  |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 8 |-> 0],
      crossType   |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossTradeMessage ==
    { ZeroCrossTradeMessage }
        \cup { [ZeroCrossTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossShares = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossPrice = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Trade Message: 12 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ nanoseconds : Sample(4),
      matchNumber : Sample(8) ]

EncodeBrokenTradeMessage(message) ==
    message.nanoseconds
        \o message.matchNumber

DecodeBrokenTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Net Order Imbalance Indicator Message: 41 bytes                         *)
(***************************************************************************)

NetOrderImbalanceIndicatorMessage ==
    [ nanoseconds             : Sample(4),
      pairedShares            : Sample(8),
      imbalanceShares         : Sample(8),
      imbalanceDirection      : Sample(1),
      stock                   : Sample(6),
      farPrice                : Sample(4),
      nearPrice               : Sample(4),
      currentReferencePrice   : Sample(4),
      crossType               : Sample(1),
      priceVariationIndicator : Sample(1) ]

EncodeNetOrderImbalanceIndicatorMessage(message) ==
    message.nanoseconds
        \o message.pairedShares
        \o message.imbalanceShares
        \o message.imbalanceDirection
        \o message.stock
        \o message.farPrice
        \o message.nearPrice
        \o message.currentReferencePrice
        \o message.crossType
        \o message.priceVariationIndicator

DecodeNetOrderImbalanceIndicatorMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET pairedShares == ReadBytes(nanoseconds.rest, 8) IN IF ~pairedShares.ok THEN Fail ELSE
    LET imbalanceShares == ReadBytes(pairedShares.rest, 8) IN IF ~imbalanceShares.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceShares.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET stock == ReadBytes(imbalanceDirection.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET farPrice == ReadBytes(stock.rest, 4) IN IF ~farPrice.ok THEN Fail ELSE
    LET nearPrice == ReadBytes(farPrice.rest, 4) IN IF ~nearPrice.ok THEN Fail ELSE
    LET currentReferencePrice == ReadBytes(nearPrice.rest, 4) IN IF ~currentReferencePrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(currentReferencePrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceVariationIndicator == ReadBytes(crossType.rest, 1) IN IF ~priceVariationIndicator.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         pairedShares            |-> pairedShares.value,
         imbalanceShares         |-> imbalanceShares.value,
         imbalanceDirection      |-> imbalanceDirection.value,
         stock                   |-> stock.value,
         farPrice                |-> farPrice.value,
         nearPrice               |-> nearPrice.value,
         currentReferencePrice   |-> currentReferencePrice.value,
         crossType               |-> crossType.value,
         priceVariationIndicator |-> priceVariationIndicator.value ], priceVariationIndicator.rest)

ZeroNetOrderImbalanceIndicatorMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      pairedShares            |-> [i \in 1 .. 8 |-> 0],
      imbalanceShares         |-> [i \in 1 .. 8 |-> 0],
      imbalanceDirection      |-> [i \in 1 .. 1 |-> 0],
      stock                   |-> [i \in 1 .. 6 |-> 0],
      farPrice                |-> [i \in 1 .. 4 |-> 0],
      nearPrice               |-> [i \in 1 .. 4 |-> 0],
      currentReferencePrice   |-> [i \in 1 .. 4 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      priceVariationIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Net Order Imbalance Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedNetOrderImbalanceIndicatorMessage ==
    { ZeroNetOrderImbalanceIndicatorMessage }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.pairedShares = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceShares = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.farPrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.nearPrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.currentReferencePrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.priceVariationIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

TimestampMessageCode == 84  \* "T"
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
OrderDisplayMessageCode == 86  \* "V"
TradeMessageCode == 80  \* "P"
CrossTradeMessageCode == 81  \* "Q"
BrokenTradeMessageCode == 66  \* "B"
NetOrderImbalanceIndicatorMessageCode == 73  \* "I"

SequencedMessage ==
    [ tag : {TimestampMessageCode}, body : TimestampMessage ]
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
        \cup [ tag : {OrderDisplayMessageCode}, body : OrderDisplayMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {CrossTradeMessageCode}, body : CrossTradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {NetOrderImbalanceIndicatorMessageCode}, body : NetOrderImbalanceIndicatorMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = TimestampMessageCode -> EncodeTimestampMessage(message.body)
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
      [] message.tag = OrderDisplayMessageCode -> EncodeOrderDisplayMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = CrossTradeMessageCode -> EncodeCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = NetOrderImbalanceIndicatorMessageCode -> EncodeNetOrderImbalanceIndicatorMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = TimestampMessageCode -> DecodeTimestampMessage(bytes)
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
              [] tag = OrderDisplayMessageCode -> DecodeOrderDisplayMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = CrossTradeMessageCode -> DecodeCrossTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = NetOrderImbalanceIndicatorMessageCode -> DecodeNetOrderImbalanceIndicatorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> TimestampMessageCode, body |-> ZeroTimestampMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> TimestampMessageCode, body |-> one] : one \in CheckedTimestampMessage }
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
        \cup { [tag |-> OrderDisplayMessageCode, body |-> one] : one \in CheckedOrderDisplayMessage }
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

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
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

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

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
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Order Display Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDisplayMessage ==
    \A message \in CheckedOrderDisplayMessage :
        LET read == DecodeOrderDisplayMessage(EncodeOrderDisplayMessage(message))
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

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
