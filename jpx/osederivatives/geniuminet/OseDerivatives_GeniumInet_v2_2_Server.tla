--------------- MODULE OseDerivatives_GeniumInet_v2_2_Server ---------------
(***************************************************************************)
(* Japan Exchange Group Genium Inet v2.2                                   *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Seconds Message: 4 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ second : Sample(4) ]

EncodeSecondsMessage(message) ==
    message.second

DecodeSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* Series Information Basic Message: 128 bytes                             *)
(***************************************************************************)

SeriesInformationBasicMessage ==
    [ nanoseconds                    : Sample(4),
      orderBookId                    : Sample(4),
      symbol                         : Sample(32),
      longName                       : Sample(32),
      reserved12                     : Sample(12),
      financialProduct               : Sample(1),
      tradingCurrency                : Sample(3),
      numberOfDecimalsInPrice        : Sample(2),
      numberOfDecimalsInNominalValue : Sample(2),
      oddLotSize                     : Sample(4),
      roundLotSize                   : Sample(4),
      blockLotSize                   : Sample(4),
      nominalValue                   : Sample(8),
      numberOfLegs                   : Sample(1),
      underlyingOrderBookId          : Sample(4),
      strikePrice                    : Sample(4),
      expirationDate                 : Sample(4),
      numberOfDecimalsInStrikePrice  : Sample(2),
      putOrCall                      : Sample(1) ]

EncodeSeriesInformationBasicMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.symbol
        \o message.longName
        \o message.reserved12
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.numberOfDecimalsInPrice
        \o message.numberOfDecimalsInNominalValue
        \o message.oddLotSize
        \o message.roundLotSize
        \o message.blockLotSize
        \o message.nominalValue
        \o message.numberOfLegs
        \o message.underlyingOrderBookId
        \o message.strikePrice
        \o message.expirationDate
        \o message.numberOfDecimalsInStrikePrice
        \o message.putOrCall

DecodeSeriesInformationBasicMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(longName.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(reserved12.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET numberOfDecimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~numberOfDecimalsInPrice.ok THEN Fail ELSE
    LET numberOfDecimalsInNominalValue == ReadBytes(numberOfDecimalsInPrice.rest, 2) IN IF ~numberOfDecimalsInNominalValue.ok THEN Fail ELSE
    LET oddLotSize == ReadBytes(numberOfDecimalsInNominalValue.rest, 4) IN IF ~oddLotSize.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(oddLotSize.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(roundLotSize.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(blockLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(nominalValue.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET underlyingOrderBookId == ReadBytes(numberOfLegs.rest, 4) IN IF ~underlyingOrderBookId.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlyingOrderBookId.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET numberOfDecimalsInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~numberOfDecimalsInStrikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(numberOfDecimalsInStrikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    Ok([ nanoseconds                    |-> nanoseconds.value,
         orderBookId                    |-> orderBookId.value,
         symbol                         |-> symbol.value,
         longName                       |-> longName.value,
         reserved12                     |-> reserved12.value,
         financialProduct               |-> financialProduct.value,
         tradingCurrency                |-> tradingCurrency.value,
         numberOfDecimalsInPrice        |-> numberOfDecimalsInPrice.value,
         numberOfDecimalsInNominalValue |-> numberOfDecimalsInNominalValue.value,
         oddLotSize                     |-> oddLotSize.value,
         roundLotSize                   |-> roundLotSize.value,
         blockLotSize                   |-> blockLotSize.value,
         nominalValue                   |-> nominalValue.value,
         numberOfLegs                   |-> numberOfLegs.value,
         underlyingOrderBookId          |-> underlyingOrderBookId.value,
         strikePrice                    |-> strikePrice.value,
         expirationDate                 |-> expirationDate.value,
         numberOfDecimalsInStrikePrice  |-> numberOfDecimalsInStrikePrice.value,
         putOrCall                      |-> putOrCall.value ], putOrCall.rest)

ZeroSeriesInformationBasicMessage ==
    [ nanoseconds                    |-> [i \in 1 .. 4 |-> 0],
      orderBookId                    |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 32 |-> 0],
      longName                       |-> [i \in 1 .. 32 |-> 0],
      reserved12                     |-> [i \in 1 .. 12 |-> 0],
      financialProduct               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                |-> [i \in 1 .. 3 |-> 0],
      numberOfDecimalsInPrice        |-> [i \in 1 .. 2 |-> 0],
      numberOfDecimalsInNominalValue |-> [i \in 1 .. 2 |-> 0],
      oddLotSize                     |-> [i \in 1 .. 4 |-> 0],
      roundLotSize                   |-> [i \in 1 .. 4 |-> 0],
      blockLotSize                   |-> [i \in 1 .. 4 |-> 0],
      nominalValue                   |-> [i \in 1 .. 8 |-> 0],
      numberOfLegs                   |-> [i \in 1 .. 1 |-> 0],
      underlyingOrderBookId          |-> [i \in 1 .. 4 |-> 0],
      strikePrice                    |-> [i \in 1 .. 4 |-> 0],
      expirationDate                 |-> [i \in 1 .. 4 |-> 0],
      numberOfDecimalsInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      putOrCall                      |-> [i \in 1 .. 1 |-> 0] ]

(* Series Information Basic Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesInformationBasicMessage ==
    { ZeroSeriesInformationBasicMessage }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.numberOfLegs = one] : one \in Sample(1) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.underlyingOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.numberOfDecimalsInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroSeriesInformationBasicMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Information Basic Combination Message: 17 bytes                  *)
(***************************************************************************)

SeriesInformationBasicCombinationMessage ==
    [ nanoseconds            : Sample(4),
      combinationOrderBookId : Sample(4),
      legOrderBookId         : Sample(4),
      legSide                : Sample(1),
      legRatio               : Sample(4) ]

EncodeSeriesInformationBasicCombinationMessage(message) ==
    message.nanoseconds
        \o message.combinationOrderBookId
        \o message.legOrderBookId
        \o message.legSide
        \o message.legRatio

DecodeSeriesInformationBasicCombinationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET combinationOrderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~combinationOrderBookId.ok THEN Fail ELSE
    LET legOrderBookId == ReadBytes(combinationOrderBookId.rest, 4) IN IF ~legOrderBookId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legOrderBookId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ nanoseconds            |-> nanoseconds.value,
         combinationOrderBookId |-> combinationOrderBookId.value,
         legOrderBookId         |-> legOrderBookId.value,
         legSide                |-> legSide.value,
         legRatio               |-> legRatio.value ], legRatio.rest)

ZeroSeriesInformationBasicCombinationMessage ==
    [ nanoseconds            |-> [i \in 1 .. 4 |-> 0],
      combinationOrderBookId |-> [i \in 1 .. 4 |-> 0],
      legOrderBookId         |-> [i \in 1 .. 4 |-> 0],
      legSide                |-> [i \in 1 .. 1 |-> 0],
      legRatio               |-> [i \in 1 .. 4 |-> 0] ]

(* Series Information Basic Combination Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesInformationBasicCombinationMessage ==
    { ZeroSeriesInformationBasicCombinationMessage }
        \cup { [ZeroSeriesInformationBasicCombinationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicCombinationMessage EXCEPT !.combinationOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicCombinationMessage EXCEPT !.legOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesInformationBasicCombinationMessage EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroSeriesInformationBasicCombinationMessage EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Tick Size Data Message: 24 bytes                                        *)
(***************************************************************************)

TickSizeDataMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      tickSize    : Sample(8),
      priceFrom   : Sample(4),
      priceTo     : Sample(4) ]

EncodeTickSizeDataMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.tickSize
        \o message.priceFrom
        \o message.priceTo

DecodeTickSizeDataMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(orderBookId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET priceFrom == ReadBytes(tickSize.rest, 4) IN IF ~priceFrom.ok THEN Fail ELSE
    LET priceTo == ReadBytes(priceFrom.rest, 4) IN IF ~priceTo.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         tickSize    |-> tickSize.value,
         priceFrom   |-> priceFrom.value,
         priceTo     |-> priceTo.value ], priceTo.rest)

ZeroTickSizeDataMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      tickSize    |-> [i \in 1 .. 8 |-> 0],
      priceFrom   |-> [i \in 1 .. 4 |-> 0],
      priceTo     |-> [i \in 1 .. 4 |-> 0] ]

(* Tick Size Data Message at zero, then each field in turn at the values it is checked at *)
CheckedTickSizeDataMessage ==
    { ZeroTickSizeDataMessage }
        \cup { [ZeroTickSizeDataMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeDataMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeDataMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeDataMessage EXCEPT !.priceFrom = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeDataMessage EXCEPT !.priceTo = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Data Message: 5 bytes                                      *)
(***************************************************************************)

SystemEventDataMessage ==
    [ nanoseconds : Sample(4),
      eventCode   : Sample(1) ]

EncodeSystemEventDataMessage(message) ==
    message.nanoseconds
        \o message.eventCode

DecodeSystemEventDataMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventDataMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventDataMessage ==
    { ZeroSystemEventDataMessage }
        \cup { [ZeroSystemEventDataMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventDataMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Status Data Message: 28 bytes                                   *)
(***************************************************************************)

TradingStatusDataMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      stateName   : Sample(20) ]

EncodeTradingStatusDataMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.stateName

DecodeTradingStatusDataMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET stateName == ReadBytes(orderBookId.rest, 20) IN IF ~stateName.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         stateName   |-> stateName.value ], stateName.rest)

ZeroTradingStatusDataMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      stateName   |-> [i \in 1 .. 20 |-> 0] ]

(* Trading Status Data Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusDataMessage ==
    { ZeroTradingStatusDataMessage }
        \cup { [ZeroTradingStatusDataMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusDataMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusDataMessage EXCEPT !.stateName = one] : one \in Sample(20) }

(***************************************************************************)
(* New Order Message: 36 bytes                                             *)
(***************************************************************************)

NewOrderMessage ==
    [ nanoseconds       : Sample(4),
      orderId           : Sample(8),
      orderBookId       : Sample(4),
      side              : Sample(1),
      orderBookPosition : Sample(4),
      quantity          : Sample(8),
      price             : Sample(4),
      orderAttributes   : Sample(2),
      lotType           : Sample(1) ]

EncodeNewOrderMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType

DecodeNewOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(side.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET lotType == ReadBytes(orderAttributes.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         orderId           |-> orderId.value,
         orderBookId       |-> orderBookId.value,
         side              |-> side.value,
         orderBookPosition |-> orderBookPosition.value,
         quantity          |-> quantity.value,
         price             |-> price.value,
         orderAttributes   |-> orderAttributes.value,
         lotType           |-> lotType.value ], lotType.rest)

ZeroNewOrderMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      orderAttributes   |-> [i \in 1 .. 2 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderMessage EXCEPT !.lotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Notice Message: 51 bytes                                      *)
(***************************************************************************)

ExecutionNoticeMessage ==
    [ nanoseconds      : Sample(4),
      orderId          : Sample(8),
      orderBookId      : Sample(4),
      side             : Sample(1),
      executedQuantity : Sample(8),
      matchId          : Sample(8),
      comboGroupId     : Sample(4),
      reserved7A       : Sample(7),
      reserved7B       : Sample(7) ]

EncodeExecutionNoticeMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.comboGroupId
        \o message.reserved7A
        \o message.reserved7B

DecodeExecutionNoticeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET reserved7A == ReadBytes(comboGroupId.rest, 7) IN IF ~reserved7A.ok THEN Fail ELSE
    LET reserved7B == ReadBytes(reserved7A.rest, 7) IN IF ~reserved7B.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderId          |-> orderId.value,
         orderBookId      |-> orderBookId.value,
         side             |-> side.value,
         executedQuantity |-> executedQuantity.value,
         matchId          |-> matchId.value,
         comboGroupId     |-> comboGroupId.value,
         reserved7A       |-> reserved7A.value,
         reserved7B       |-> reserved7B.value ], reserved7B.rest)

ZeroExecutionNoticeMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      orderBookId      |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      matchId          |-> [i \in 1 .. 8 |-> 0],
      comboGroupId     |-> [i \in 1 .. 4 |-> 0],
      reserved7A       |-> [i \in 1 .. 7 |-> 0],
      reserved7B       |-> [i \in 1 .. 7 |-> 0] ]

(* Execution Notice Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNoticeMessage ==
    { ZeroExecutionNoticeMessage }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.reserved7A = one] : one \in Sample(7) }
        \cup { [ZeroExecutionNoticeMessage EXCEPT !.reserved7B = one] : one \in Sample(7) }

(***************************************************************************)
(* Execution Notice With Trade Information Message: 57 bytes               *)
(***************************************************************************)

ExecutionNoticeWithTradeInformationMessage ==
    [ nanoseconds      : Sample(4),
      orderId          : Sample(8),
      orderBookId      : Sample(4),
      side             : Sample(1),
      executedQuantity : Sample(8),
      matchId          : Sample(8),
      comboGroupId     : Sample(4),
      reserved7A       : Sample(7),
      reserved7B       : Sample(7),
      tradePrice       : Sample(4),
      occurredAtCross  : Sample(1),
      printable        : Sample(1) ]

EncodeExecutionNoticeWithTradeInformationMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.comboGroupId
        \o message.reserved7A
        \o message.reserved7B
        \o message.tradePrice
        \o message.occurredAtCross
        \o message.printable

DecodeExecutionNoticeWithTradeInformationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET reserved7A == ReadBytes(comboGroupId.rest, 7) IN IF ~reserved7A.ok THEN Fail ELSE
    LET reserved7B == ReadBytes(reserved7A.rest, 7) IN IF ~reserved7B.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(reserved7B.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(tradePrice.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    LET printable == ReadBytes(occurredAtCross.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderId          |-> orderId.value,
         orderBookId      |-> orderBookId.value,
         side             |-> side.value,
         executedQuantity |-> executedQuantity.value,
         matchId          |-> matchId.value,
         comboGroupId     |-> comboGroupId.value,
         reserved7A       |-> reserved7A.value,
         reserved7B       |-> reserved7B.value,
         tradePrice       |-> tradePrice.value,
         occurredAtCross  |-> occurredAtCross.value,
         printable        |-> printable.value ], printable.rest)

ZeroExecutionNoticeWithTradeInformationMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      orderBookId      |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      matchId          |-> [i \in 1 .. 8 |-> 0],
      comboGroupId     |-> [i \in 1 .. 4 |-> 0],
      reserved7A       |-> [i \in 1 .. 7 |-> 0],
      reserved7B       |-> [i \in 1 .. 7 |-> 0],
      tradePrice       |-> [i \in 1 .. 4 |-> 0],
      occurredAtCross  |-> [i \in 1 .. 1 |-> 0],
      printable        |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Notice With Trade Information Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNoticeWithTradeInformationMessage ==
    { ZeroExecutionNoticeWithTradeInformationMessage }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.reserved7A = one] : one \in Sample(7) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.reserved7B = one] : one \in Sample(7) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.occurredAtCross = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNoticeWithTradeInformationMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Deleted Order Message: 17 bytes                                         *)
(***************************************************************************)

DeletedOrderMessage ==
    [ nanoseconds : Sample(4),
      orderId     : Sample(8),
      orderBookId : Sample(4),
      side        : Sample(1) ]

EncodeDeletedOrderMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side

DecodeDeletedOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderId     |-> orderId.value,
         orderBookId |-> orderBookId.value,
         side        |-> side.value ], side.rest)

ZeroDeletedOrderMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0] ]

(* Deleted Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeletedOrderMessage ==
    { ZeroDeletedOrderMessage }
        \cup { [ZeroDeletedOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroDeletedOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeletedOrderMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroDeletedOrderMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Ep Message: 52 bytes                                                    *)
(***************************************************************************)

EpMessage ==
    [ nanoseconds                            : Sample(4),
      orderBookId                            : Sample(4),
      availableBidQuantityAtEquilibriumPrice : Sample(8),
      availableAskQuantityAtEquilibriumPrice : Sample(8),
      equilibriumPrice                       : Sample(4),
      reserved4A                             : Sample(4),
      reserved4B                             : Sample(4),
      reserved8A                             : Sample(8),
      reserved8B                             : Sample(8) ]

EncodeEpMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.availableBidQuantityAtEquilibriumPrice
        \o message.availableAskQuantityAtEquilibriumPrice
        \o message.equilibriumPrice
        \o message.reserved4A
        \o message.reserved4B
        \o message.reserved8A
        \o message.reserved8B

DecodeEpMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET availableBidQuantityAtEquilibriumPrice == ReadBytes(orderBookId.rest, 8) IN IF ~availableBidQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET availableAskQuantityAtEquilibriumPrice == ReadBytes(availableBidQuantityAtEquilibriumPrice.rest, 8) IN IF ~availableAskQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(availableAskQuantityAtEquilibriumPrice.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET reserved4A == ReadBytes(equilibriumPrice.rest, 4) IN IF ~reserved4A.ok THEN Fail ELSE
    LET reserved4B == ReadBytes(reserved4A.rest, 4) IN IF ~reserved4B.ok THEN Fail ELSE
    LET reserved8A == ReadBytes(reserved4B.rest, 8) IN IF ~reserved8A.ok THEN Fail ELSE
    LET reserved8B == ReadBytes(reserved8A.rest, 8) IN IF ~reserved8B.ok THEN Fail ELSE
    Ok([ nanoseconds                            |-> nanoseconds.value,
         orderBookId                            |-> orderBookId.value,
         availableBidQuantityAtEquilibriumPrice |-> availableBidQuantityAtEquilibriumPrice.value,
         availableAskQuantityAtEquilibriumPrice |-> availableAskQuantityAtEquilibriumPrice.value,
         equilibriumPrice                       |-> equilibriumPrice.value,
         reserved4A                             |-> reserved4A.value,
         reserved4B                             |-> reserved4B.value,
         reserved8A                             |-> reserved8A.value,
         reserved8B                             |-> reserved8B.value ], reserved8B.rest)

ZeroEpMessage ==
    [ nanoseconds                            |-> [i \in 1 .. 4 |-> 0],
      orderBookId                            |-> [i \in 1 .. 4 |-> 0],
      availableBidQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      availableAskQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      equilibriumPrice                       |-> [i \in 1 .. 4 |-> 0],
      reserved4A                             |-> [i \in 1 .. 4 |-> 0],
      reserved4B                             |-> [i \in 1 .. 4 |-> 0],
      reserved8A                             |-> [i \in 1 .. 8 |-> 0],
      reserved8B                             |-> [i \in 1 .. 8 |-> 0] ]

(* Ep Message at zero, then each field in turn at the values it is checked at *)
CheckedEpMessage ==
    { ZeroEpMessage }
        \cup { [ZeroEpMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEpMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEpMessage EXCEPT !.availableBidQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEpMessage EXCEPT !.availableAskQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEpMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEpMessage EXCEPT !.reserved4A = one] : one \in Sample(4) }
        \cup { [ZeroEpMessage EXCEPT !.reserved4B = one] : one \in Sample(4) }
        \cup { [ZeroEpMessage EXCEPT !.reserved8A = one] : one \in Sample(8) }
        \cup { [ZeroEpMessage EXCEPT !.reserved8B = one] : one \in Sample(8) }

(***************************************************************************)
(* Snapshot Completion Message: 20 bytes                                   *)
(***************************************************************************)

SnapshotCompletionMessage ==
    [ sequence : Sample(20) ]

EncodeSnapshotCompletionMessage(message) ==
    message.sequence

DecodeSnapshotCompletionMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 20) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value ], sequence.rest)

ZeroSnapshotCompletionMessage ==
    [ sequence |-> [i \in 1 .. 20 |-> 0] ]

(* Snapshot Completion Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotCompletionMessage ==
    { ZeroSnapshotCompletionMessage }
        \cup { [ZeroSnapshotCompletionMessage EXCEPT !.sequence = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
SeriesInformationBasicMessageCode == 82  \* "R"
SeriesInformationBasicCombinationMessageCode == 77  \* "M"
TickSizeDataMessageCode == 76  \* "L"
SystemEventDataMessageCode == 83  \* "S"
TradingStatusDataMessageCode == 79  \* "O"
NewOrderMessageCode == 65  \* "A"
ExecutionNoticeMessageCode == 69  \* "E"
ExecutionNoticeWithTradeInformationMessageCode == 67  \* "C"
DeletedOrderMessageCode == 68  \* "D"
EpMessageCode == 90  \* "Z"
SnapshotCompletionMessageCode == 71  \* "G"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {SeriesInformationBasicMessageCode}, body : SeriesInformationBasicMessage ]
        \cup [ tag : {SeriesInformationBasicCombinationMessageCode}, body : SeriesInformationBasicCombinationMessage ]
        \cup [ tag : {TickSizeDataMessageCode}, body : TickSizeDataMessage ]
        \cup [ tag : {SystemEventDataMessageCode}, body : SystemEventDataMessage ]
        \cup [ tag : {TradingStatusDataMessageCode}, body : TradingStatusDataMessage ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {ExecutionNoticeMessageCode}, body : ExecutionNoticeMessage ]
        \cup [ tag : {ExecutionNoticeWithTradeInformationMessageCode}, body : ExecutionNoticeWithTradeInformationMessage ]
        \cup [ tag : {DeletedOrderMessageCode}, body : DeletedOrderMessage ]
        \cup [ tag : {EpMessageCode}, body : EpMessage ]
        \cup [ tag : {SnapshotCompletionMessageCode}, body : SnapshotCompletionMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = SeriesInformationBasicMessageCode -> EncodeSeriesInformationBasicMessage(message.body)
      [] message.tag = SeriesInformationBasicCombinationMessageCode -> EncodeSeriesInformationBasicCombinationMessage(message.body)
      [] message.tag = TickSizeDataMessageCode -> EncodeTickSizeDataMessage(message.body)
      [] message.tag = SystemEventDataMessageCode -> EncodeSystemEventDataMessage(message.body)
      [] message.tag = TradingStatusDataMessageCode -> EncodeTradingStatusDataMessage(message.body)
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = ExecutionNoticeMessageCode -> EncodeExecutionNoticeMessage(message.body)
      [] message.tag = ExecutionNoticeWithTradeInformationMessageCode -> EncodeExecutionNoticeWithTradeInformationMessage(message.body)
      [] message.tag = DeletedOrderMessageCode -> EncodeDeletedOrderMessage(message.body)
      [] message.tag = EpMessageCode -> EncodeEpMessage(message.body)
      [] message.tag = SnapshotCompletionMessageCode -> EncodeSnapshotCompletionMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = SeriesInformationBasicMessageCode -> DecodeSeriesInformationBasicMessage(bytes)
              [] tag = SeriesInformationBasicCombinationMessageCode -> DecodeSeriesInformationBasicCombinationMessage(bytes)
              [] tag = TickSizeDataMessageCode -> DecodeTickSizeDataMessage(bytes)
              [] tag = SystemEventDataMessageCode -> DecodeSystemEventDataMessage(bytes)
              [] tag = TradingStatusDataMessageCode -> DecodeTradingStatusDataMessage(bytes)
              [] tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = ExecutionNoticeMessageCode -> DecodeExecutionNoticeMessage(bytes)
              [] tag = ExecutionNoticeWithTradeInformationMessageCode -> DecodeExecutionNoticeWithTradeInformationMessage(bytes)
              [] tag = DeletedOrderMessageCode -> DecodeDeletedOrderMessage(bytes)
              [] tag = EpMessageCode -> DecodeEpMessage(bytes)
              [] tag = SnapshotCompletionMessageCode -> DecodeSnapshotCompletionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> SeriesInformationBasicMessageCode, body |-> one] : one \in CheckedSeriesInformationBasicMessage }
        \cup { [tag |-> SeriesInformationBasicCombinationMessageCode, body |-> one] : one \in CheckedSeriesInformationBasicCombinationMessage }
        \cup { [tag |-> TickSizeDataMessageCode, body |-> one] : one \in CheckedTickSizeDataMessage }
        \cup { [tag |-> SystemEventDataMessageCode, body |-> one] : one \in CheckedSystemEventDataMessage }
        \cup { [tag |-> TradingStatusDataMessageCode, body |-> one] : one \in CheckedTradingStatusDataMessage }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> ExecutionNoticeMessageCode, body |-> one] : one \in CheckedExecutionNoticeMessage }
        \cup { [tag |-> ExecutionNoticeWithTradeInformationMessageCode, body |-> one] : one \in CheckedExecutionNoticeWithTradeInformationMessage }
        \cup { [tag |-> DeletedOrderMessageCode, body |-> one] : one \in CheckedDeletedOrderMessage }
        \cup { [tag |-> EpMessageCode, body |-> one] : one \in CheckedEpMessage }
        \cup { [tag |-> SnapshotCompletionMessageCode, body |-> one] : one \in CheckedSnapshotCompletionMessage }

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Information Basic Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesInformationBasicMessage ==
    \A message \in CheckedSeriesInformationBasicMessage :
        LET read == DecodeSeriesInformationBasicMessage(EncodeSeriesInformationBasicMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Information Basic Combination Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesInformationBasicCombinationMessage ==
    \A message \in CheckedSeriesInformationBasicCombinationMessage :
        LET read == DecodeSeriesInformationBasicCombinationMessage(EncodeSeriesInformationBasicCombinationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Size Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickSizeDataMessage ==
    \A message \in CheckedTickSizeDataMessage :
        LET read == DecodeTickSizeDataMessage(EncodeTickSizeDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventDataMessage ==
    \A message \in CheckedSystemEventDataMessage :
        LET read == DecodeSystemEventDataMessage(EncodeSystemEventDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusDataMessage ==
    \A message \in CheckedTradingStatusDataMessage :
        LET read == DecodeTradingStatusDataMessage(EncodeTradingStatusDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Notice Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNoticeMessage ==
    \A message \in CheckedExecutionNoticeMessage :
        LET read == DecodeExecutionNoticeMessage(EncodeExecutionNoticeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Notice With Trade Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNoticeWithTradeInformationMessage ==
    \A message \in CheckedExecutionNoticeWithTradeInformationMessage :
        LET read == DecodeExecutionNoticeWithTradeInformationMessage(EncodeExecutionNoticeWithTradeInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deleted Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeletedOrderMessage ==
    \A message \in CheckedDeletedOrderMessage :
        LET read == DecodeDeletedOrderMessage(EncodeDeletedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ep Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEpMessage ==
    \A message \in CheckedEpMessage :
        LET read == DecodeEpMessage(EncodeEpMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Completion Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotCompletionMessage ==
    \A message \in CheckedSnapshotCompletionMessage :
        LET read == DecodeSnapshotCompletionMessage(EncodeSnapshotCompletionMessage(message))
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
