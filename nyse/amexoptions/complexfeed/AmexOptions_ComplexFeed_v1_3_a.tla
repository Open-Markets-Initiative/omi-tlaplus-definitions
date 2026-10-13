------------------ MODULE AmexOptions_ComplexFeed_v1_3_a -------------------
(***************************************************************************)
(* New York Stock Exchange Complex Feed v1.3.a                             *)
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
(* Send Time: 8 bytes                                                      *)
(***************************************************************************)

SendTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeSendTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeSendTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroSendTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Send Time at zero, then each field in turn at the values it is checked at *)
CheckedSendTime ==
    { ZeroSendTime }
        \cup { [ZeroSendTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSendTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Quote Message: 36 bytes                                         *)
(***************************************************************************)

ComplexQuoteMessage ==
    [ sourceTime        : Sample(4),
      sourceTimeNs      : Sample(4),
      complexIndex      : Sample(4),
      symbolSeqNum      : Sample(4),
      askPrice          : Sample(4),
      bidPrice          : Sample(4),
      askVolume         : Sample(2),
      bidVolume         : Sample(2),
      askCustomerVolume : Sample(2),
      bidCustomerVolume : Sample(2),
      quoteCondition    : Sample(1),
      reserved1         : Sample(1),
      reserved2         : Sample(2) ]

EncodeComplexQuoteMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.askPrice
        \o message.bidPrice
        \o message.askVolume
        \o message.bidVolume
        \o message.askCustomerVolume
        \o message.bidCustomerVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.reserved2

DecodeComplexQuoteMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET askPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askPrice.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askVolume == ReadBytes(bidPrice.rest, 2) IN IF ~askVolume.ok THEN Fail ELSE
    LET bidVolume == ReadBytes(askVolume.rest, 2) IN IF ~bidVolume.ok THEN Fail ELSE
    LET askCustomerVolume == ReadBytes(bidVolume.rest, 2) IN IF ~askCustomerVolume.ok THEN Fail ELSE
    LET bidCustomerVolume == ReadBytes(askCustomerVolume.rest, 2) IN IF ~bidCustomerVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(bidCustomerVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime        |-> sourceTime.value,
         sourceTimeNs      |-> sourceTimeNs.value,
         complexIndex      |-> complexIndex.value,
         symbolSeqNum      |-> symbolSeqNum.value,
         askPrice          |-> askPrice.value,
         bidPrice          |-> bidPrice.value,
         askVolume         |-> askVolume.value,
         bidVolume         |-> bidVolume.value,
         askCustomerVolume |-> askCustomerVolume.value,
         bidCustomerVolume |-> bidCustomerVolume.value,
         quoteCondition    |-> quoteCondition.value,
         reserved1         |-> reserved1.value,
         reserved2         |-> reserved2.value ], reserved2.rest)

ZeroComplexQuoteMessage ==
    [ sourceTime        |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs      |-> [i \in 1 .. 4 |-> 0],
      complexIndex      |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum      |-> [i \in 1 .. 4 |-> 0],
      askPrice          |-> [i \in 1 .. 4 |-> 0],
      bidPrice          |-> [i \in 1 .. 4 |-> 0],
      askVolume         |-> [i \in 1 .. 2 |-> 0],
      bidVolume         |-> [i \in 1 .. 2 |-> 0],
      askCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      bidCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      reserved1         |-> [i \in 1 .. 1 |-> 0],
      reserved2         |-> [i \in 1 .. 2 |-> 0] ]

(* Complex Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteMessage ==
    { ZeroComplexQuoteMessage }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.askVolume = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.bidVolume = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.askCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.bidCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Complex Trade Message: 32 bytes                                         *)
(***************************************************************************)

ComplexTradeMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      complexIndex : Sample(4),
      symbolSeqNum : Sample(4),
      tradeId      : Sample(4),
      price        : Sample(4),
      volume4      : Sample(4),
      tradeCond1   : Sample(1),
      tradeCond2   : Sample(1),
      reserved2    : Sample(2) ]

EncodeComplexTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.volume4
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.reserved2

DecodeComplexTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume4 == ReadBytes(price.rest, 4) IN IF ~volume4.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume4.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(tradeCond2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         complexIndex |-> complexIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         volume4      |-> volume4.value,
         tradeCond1   |-> tradeCond1.value,
         tradeCond2   |-> tradeCond2.value,
         reserved2    |-> reserved2.value ], reserved2.rest)

ZeroComplexTradeMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      complexIndex |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      volume4      |-> [i \in 1 .. 4 |-> 0],
      tradeCond1   |-> [i \in 1 .. 1 |-> 0],
      tradeCond2   |-> [i \in 1 .. 1 |-> 0],
      reserved2    |-> [i \in 1 .. 2 |-> 0] ]

(* Complex Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTradeMessage ==
    { ZeroComplexTradeMessage }
        \cup { [ZeroComplexTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.volume4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroComplexTradeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Complex Crossing Rfq Message: 24 bytes                                  *)
(***************************************************************************)

ComplexCrossingRfqMessage ==
    [ sourceTime   : Sample(4),
      sourceNs     : Sample(4),
      complexIndex : Sample(4),
      symbolSeqNum : Sample(4),
      side         : Sample(1),
      reserved1    : Sample(1),
      volume2      : Sample(2),
      price        : Sample(4) ]

EncodeComplexCrossingRfqMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.side
        \o message.reserved1
        \o message.volume2
        \o message.price

DecodeComplexCrossingRfqMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSeqNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(side.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET volume2 == ReadBytes(reserved1.rest, 2) IN IF ~volume2.ok THEN Fail ELSE
    LET price == ReadBytes(volume2.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceNs     |-> sourceNs.value,
         complexIndex |-> complexIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         side         |-> side.value,
         reserved1    |-> reserved1.value,
         volume2      |-> volume2.value,
         price        |-> price.value ], price.rest)

ZeroComplexCrossingRfqMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceNs     |-> [i \in 1 .. 4 |-> 0],
      complexIndex |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      volume2      |-> [i \in 1 .. 2 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Crossing Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexCrossingRfqMessage ==
    { ZeroComplexCrossingRfqMessage }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.volume2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexCrossingRfqMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Cube Rfq Message: 24 bytes                                      *)
(***************************************************************************)

ComplexCubeRfqMessage ==
    [ sourceTime   : Sample(4),
      sourceNs     : Sample(4),
      complexIndex : Sample(4),
      symbolSeqNum : Sample(4),
      side         : Sample(1),
      reserved1    : Sample(1),
      volume2      : Sample(2),
      price        : Sample(4) ]

EncodeComplexCubeRfqMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.side
        \o message.reserved1
        \o message.volume2
        \o message.price

DecodeComplexCubeRfqMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSeqNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(side.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET volume2 == ReadBytes(reserved1.rest, 2) IN IF ~volume2.ok THEN Fail ELSE
    LET price == ReadBytes(volume2.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceNs     |-> sourceNs.value,
         complexIndex |-> complexIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         side         |-> side.value,
         reserved1    |-> reserved1.value,
         volume2      |-> volume2.value,
         price        |-> price.value ], price.rest)

ZeroComplexCubeRfqMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceNs     |-> [i \in 1 .. 4 |-> 0],
      complexIndex |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      volume2      |-> [i \in 1 .. 2 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Cube Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexCubeRfqMessage ==
    { ZeroComplexCubeRfqMessage }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.volume2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexCubeRfqMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Status Message: 20 bytes                                        *)
(***************************************************************************)

ComplexStatusMessage ==
    [ sourceTime     : Sample(4),
      sourceTimeNs   : Sample(4),
      complexIndex   : Sample(4),
      symbolSeqNum   : Sample(4),
      securityStatus : Sample(1),
      haltCondition  : Sample(1),
      reserved2      : Sample(2) ]

EncodeComplexStatusMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.securityStatus
        \o message.haltCondition
        \o message.reserved2

DecodeComplexStatusMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(symbolSeqNum.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltCondition == ReadBytes(securityStatus.rest, 1) IN IF ~haltCondition.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(haltCondition.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime     |-> sourceTime.value,
         sourceTimeNs   |-> sourceTimeNs.value,
         complexIndex   |-> complexIndex.value,
         symbolSeqNum   |-> symbolSeqNum.value,
         securityStatus |-> securityStatus.value,
         haltCondition  |-> haltCondition.value,
         reserved2      |-> reserved2.value ], reserved2.rest)

ZeroComplexStatusMessage ==
    [ sourceTime     |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs   |-> [i \in 1 .. 4 |-> 0],
      complexIndex   |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum   |-> [i \in 1 .. 4 |-> 0],
      securityStatus |-> [i \in 1 .. 1 |-> 0],
      haltCondition  |-> [i \in 1 .. 1 |-> 0],
      reserved2      |-> [i \in 1 .. 2 |-> 0] ]

(* Complex Status Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStatusMessage ==
    { ZeroComplexStatusMessage }
        \cup { [ZeroComplexStatusMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroComplexStatusMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroComplexStatusMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexStatusMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroComplexStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroComplexStatusMessage EXCEPT !.haltCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Refresh Complex Quote Message: 36 bytes                                 *)
(***************************************************************************)

RefreshComplexQuoteMessage ==
    [ sourceTime        : Sample(4),
      sourceTimeNs      : Sample(4),
      complexIndex      : Sample(4),
      symbolSeqNum      : Sample(4),
      askPrice          : Sample(4),
      bidPrice          : Sample(4),
      askVolume         : Sample(2),
      bidVolume         : Sample(2),
      askCustomerVolume : Sample(2),
      bidCustomerVolume : Sample(2),
      quoteCondition    : Sample(1),
      reserved1         : Sample(1),
      reserved2         : Sample(2) ]

EncodeRefreshComplexQuoteMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.askPrice
        \o message.bidPrice
        \o message.askVolume
        \o message.bidVolume
        \o message.askCustomerVolume
        \o message.bidCustomerVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.reserved2

DecodeRefreshComplexQuoteMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET askPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askPrice.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askVolume == ReadBytes(bidPrice.rest, 2) IN IF ~askVolume.ok THEN Fail ELSE
    LET bidVolume == ReadBytes(askVolume.rest, 2) IN IF ~bidVolume.ok THEN Fail ELSE
    LET askCustomerVolume == ReadBytes(bidVolume.rest, 2) IN IF ~askCustomerVolume.ok THEN Fail ELSE
    LET bidCustomerVolume == ReadBytes(askCustomerVolume.rest, 2) IN IF ~bidCustomerVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(bidCustomerVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime        |-> sourceTime.value,
         sourceTimeNs      |-> sourceTimeNs.value,
         complexIndex      |-> complexIndex.value,
         symbolSeqNum      |-> symbolSeqNum.value,
         askPrice          |-> askPrice.value,
         bidPrice          |-> bidPrice.value,
         askVolume         |-> askVolume.value,
         bidVolume         |-> bidVolume.value,
         askCustomerVolume |-> askCustomerVolume.value,
         bidCustomerVolume |-> bidCustomerVolume.value,
         quoteCondition    |-> quoteCondition.value,
         reserved1         |-> reserved1.value,
         reserved2         |-> reserved2.value ], reserved2.rest)

ZeroRefreshComplexQuoteMessage ==
    [ sourceTime        |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs      |-> [i \in 1 .. 4 |-> 0],
      complexIndex      |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum      |-> [i \in 1 .. 4 |-> 0],
      askPrice          |-> [i \in 1 .. 4 |-> 0],
      bidPrice          |-> [i \in 1 .. 4 |-> 0],
      askVolume         |-> [i \in 1 .. 2 |-> 0],
      bidVolume         |-> [i \in 1 .. 2 |-> 0],
      askCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      bidCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      reserved1         |-> [i \in 1 .. 1 |-> 0],
      reserved2         |-> [i \in 1 .. 2 |-> 0] ]

(* Refresh Complex Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshComplexQuoteMessage ==
    { ZeroRefreshComplexQuoteMessage }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.askVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.bidVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.askCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.bidCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshComplexQuoteMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Refresh Complex Trade Message: 32 bytes                                 *)
(***************************************************************************)

RefreshComplexTradeMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      complexIndex : Sample(4),
      symbolSeqNum : Sample(4),
      tradeId      : Sample(4),
      price        : Sample(4),
      volume4      : Sample(4),
      tradeCond1   : Sample(1),
      tradeCond2   : Sample(1),
      reserved2    : Sample(2) ]

EncodeRefreshComplexTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.complexIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.volume4
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.reserved2

DecodeRefreshComplexTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET complexIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(complexIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume4 == ReadBytes(price.rest, 4) IN IF ~volume4.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume4.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(tradeCond2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         complexIndex |-> complexIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         volume4      |-> volume4.value,
         tradeCond1   |-> tradeCond1.value,
         tradeCond2   |-> tradeCond2.value,
         reserved2    |-> reserved2.value ], reserved2.rest)

ZeroRefreshComplexTradeMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      complexIndex |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      volume4      |-> [i \in 1 .. 4 |-> 0],
      tradeCond1   |-> [i \in 1 .. 1 |-> 0],
      tradeCond2   |-> [i \in 1 .. 1 |-> 0],
      reserved2    |-> [i \in 1 .. 2 |-> 0] ]

(* Refresh Complex Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshComplexTradeMessage ==
    { ZeroRefreshComplexTradeMessage }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.volume4 = one] : one \in Sample(4) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshComplexTradeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Leg Definition: 8 bytes                                                 *)
(***************************************************************************)

LegDefinition ==
    [ symbolIndex     : Sample(4),
      legRatioQty     : Sample(2),
      side            : Sample(1),
      legSecurityType : Sample(1) ]

EncodeLegDefinition(message) ==
    message.symbolIndex
        \o message.legRatioQty
        \o message.side
        \o message.legSecurityType

DecodeLegDefinition(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(symbolIndex.rest, 2) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET side == ReadBytes(legRatioQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(side.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ symbolIndex     |-> symbolIndex.value,
         legRatioQty     |-> legRatioQty.value,
         side            |-> side.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroLegDefinition ==
    [ symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      legRatioQty     |-> [i \in 1 .. 2 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Definition at zero, then each field in turn at the values it is checked at *)
CheckedLegDefinition ==
    { ZeroLegDefinition }
        \cup { [ZeroLegDefinition EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroLegDefinition EXCEPT !.legRatioQty = one] : one \in Sample(2) }
        \cup { [ZeroLegDefinition EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLegDefinition EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Leg Definition, written one after another *)
RECURSIVE EncodeLegDefinitionList(_)
EncodeLegDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegDefinition(Head(messages)) \o EncodeLegDefinitionList(Tail(messages))

(* As many Leg Definition as the field that counts them says *)
RECURSIVE ReadLegDefinitionList(_, _)
ReadLegDefinitionList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegDefinitionList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Definition of each kind, for the lists that carry them *)
OneLegDefinition == { ZeroLegDefinition }

(***************************************************************************)
(* Complex Symbol Definition Message                                       *)
(***************************************************************************)

ComplexSymbolDefinitionMessage ==
    [ complexIndex  : Sample(4),
      complexSymbol : Sample(21),
      channelId     : Sample(1),
      marketId      : Sample(2),
      systemId      : Sample(1),
      reserved1     : Sample(1),
      streamId      : Sample(2),
      reserved2     : Sample(2),
      legDefinition : SampleLists(OneLegDefinition) ]

EncodeComplexSymbolDefinitionMessage(message) ==
    message.complexIndex
        \o message.complexSymbol
        \o message.channelId
        \o message.marketId
        \o message.systemId
        \o message.reserved1
        \o message.streamId
        \o EncodeUIntLE(Len(message.legDefinition), 2)
        \o message.reserved2
        \o EncodeLegDefinitionList(message.legDefinition)

DecodeComplexSymbolDefinitionMessage(bytes) ==
    LET complexIndex == ReadBytes(bytes, 4) IN IF ~complexIndex.ok THEN Fail ELSE
    LET complexSymbol == ReadBytes(complexIndex.rest, 21) IN IF ~complexSymbol.ok THEN Fail ELSE
    LET channelId == ReadBytes(complexSymbol.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET marketId == ReadBytes(channelId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET systemId == ReadBytes(marketId.rest, 1) IN IF ~systemId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(systemId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET streamId == ReadBytes(reserved1.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET noOfLegs == ReadUIntLE(streamId.rest, 2) IN IF ~noOfLegs.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(noOfLegs.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET legDefinition == ReadLegDefinitionList(reserved2.rest, noOfLegs.value) IN IF ~legDefinition.ok THEN Fail ELSE
    Ok([ complexIndex  |-> complexIndex.value,
         complexSymbol |-> complexSymbol.value,
         channelId     |-> channelId.value,
         marketId      |-> marketId.value,
         systemId      |-> systemId.value,
         reserved1     |-> reserved1.value,
         streamId      |-> streamId.value,
         reserved2     |-> reserved2.value,
         legDefinition |-> legDefinition.value ], legDefinition.rest)

ZeroComplexSymbolDefinitionMessage ==
    [ complexIndex  |-> [i \in 1 .. 4 |-> 0],
      complexSymbol |-> [i \in 1 .. 21 |-> 0],
      channelId     |-> [i \in 1 .. 1 |-> 0],
      marketId      |-> [i \in 1 .. 2 |-> 0],
      systemId      |-> [i \in 1 .. 1 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0],
      streamId      |-> [i \in 1 .. 2 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0],
      legDefinition |-> << >> ]

(* Complex Symbol Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexSymbolDefinitionMessage ==
    { ZeroComplexSymbolDefinitionMessage }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.complexIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.complexSymbol = one] : one \in Sample(21) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.systemId = one] : one \in Sample(1) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexSymbolDefinitionMessage EXCEPT !.legDefinition = one] : one \in SampleLists(OneLegDefinition) }

(***************************************************************************)
(* Stream Id Message: 4 bytes                                              *)
(***************************************************************************)

StreamIdMessage ==
    [ streamId  : Sample(2),
      reserved2 : Sample(2) ]

EncodeStreamIdMessage(message) ==
    message.streamId
        \o message.reserved2

DecodeStreamIdMessage(bytes) ==
    LET streamId == ReadBytes(bytes, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(streamId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ streamId  |-> streamId.value,
         reserved2 |-> reserved2.value ], reserved2.rest)

ZeroStreamIdMessage ==
    [ streamId  |-> [i \in 1 .. 2 |-> 0],
      reserved2 |-> [i \in 1 .. 2 |-> 0] ]

(* Stream Id Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamIdMessage ==
    { ZeroStreamIdMessage }
        \cup { [ZeroStreamIdMessage EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroStreamIdMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Sequence Number Reset Message: 10 bytes                                 *)
(***************************************************************************)

SequenceNumberResetMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      productId    : Sample(1),
      channelId    : Sample(1) ]

EncodeSequenceNumberResetMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.productId
        \o message.channelId

DecodeSequenceNumberResetMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET productId == ReadBytes(sourceTimeNs.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         productId    |-> productId.value,
         channelId    |-> channelId.value ], channelId.rest)

ZeroSequenceNumberResetMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      productId    |-> [i \in 1 .. 1 |-> 0],
      channelId    |-> [i \in 1 .. 1 |-> 0] ]

(* Sequence Number Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceNumberResetMessage ==
    { ZeroSequenceNumberResetMessage }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.channelId = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

ComplexQuoteMessageCode == 423  \* 0x1a7
ComplexTradeMessageCode == 425  \* 0x1a9
ComplexCrossingRfqMessageCode == 429  \* 0x1ad
ComplexCubeRfqMessageCode == 472  \* 0x1d8
ComplexStatusMessageCode == 433  \* 0x1b1
RefreshComplexQuoteMessageCode == 511  \* 0x1ff
RefreshComplexTradeMessageCode == 513  \* 0x201
ComplexSymbolDefinitionMessageCode == 439  \* 0x1b7
StreamIdMessageCode == 455  \* 0x1c7
SequenceNumberResetMessageCode == 1  \* 0x01

Payload ==
    [ tag : {ComplexQuoteMessageCode}, body : ComplexQuoteMessage ]
        \cup [ tag : {ComplexTradeMessageCode}, body : ComplexTradeMessage ]
        \cup [ tag : {ComplexCrossingRfqMessageCode}, body : ComplexCrossingRfqMessage ]
        \cup [ tag : {ComplexCubeRfqMessageCode}, body : ComplexCubeRfqMessage ]
        \cup [ tag : {ComplexStatusMessageCode}, body : ComplexStatusMessage ]
        \cup [ tag : {RefreshComplexQuoteMessageCode}, body : RefreshComplexQuoteMessage ]
        \cup [ tag : {RefreshComplexTradeMessageCode}, body : RefreshComplexTradeMessage ]
        \cup [ tag : {ComplexSymbolDefinitionMessageCode}, body : ComplexSymbolDefinitionMessage ]
        \cup [ tag : {StreamIdMessageCode}, body : StreamIdMessage ]
        \cup [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]

EncodePayload(message) ==
    CASE message.tag = ComplexQuoteMessageCode -> EncodeComplexQuoteMessage(message.body)
      [] message.tag = ComplexTradeMessageCode -> EncodeComplexTradeMessage(message.body)
      [] message.tag = ComplexCrossingRfqMessageCode -> EncodeComplexCrossingRfqMessage(message.body)
      [] message.tag = ComplexCubeRfqMessageCode -> EncodeComplexCubeRfqMessage(message.body)
      [] message.tag = ComplexStatusMessageCode -> EncodeComplexStatusMessage(message.body)
      [] message.tag = RefreshComplexQuoteMessageCode -> EncodeRefreshComplexQuoteMessage(message.body)
      [] message.tag = RefreshComplexTradeMessageCode -> EncodeRefreshComplexTradeMessage(message.body)
      [] message.tag = ComplexSymbolDefinitionMessageCode -> EncodeComplexSymbolDefinitionMessage(message.body)
      [] message.tag = StreamIdMessageCode -> EncodeStreamIdMessage(message.body)
      [] message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ComplexQuoteMessageCode -> DecodeComplexQuoteMessage(bytes)
              [] tag = ComplexTradeMessageCode -> DecodeComplexTradeMessage(bytes)
              [] tag = ComplexCrossingRfqMessageCode -> DecodeComplexCrossingRfqMessage(bytes)
              [] tag = ComplexCubeRfqMessageCode -> DecodeComplexCubeRfqMessage(bytes)
              [] tag = ComplexStatusMessageCode -> DecodeComplexStatusMessage(bytes)
              [] tag = RefreshComplexQuoteMessageCode -> DecodeRefreshComplexQuoteMessage(bytes)
              [] tag = RefreshComplexTradeMessageCode -> DecodeRefreshComplexTradeMessage(bytes)
              [] tag = ComplexSymbolDefinitionMessageCode -> DecodeComplexSymbolDefinitionMessage(bytes)
              [] tag = StreamIdMessageCode -> DecodeStreamIdMessage(bytes)
              [] tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ComplexQuoteMessageCode, body |-> ZeroComplexQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ComplexQuoteMessageCode, body |-> one] : one \in CheckedComplexQuoteMessage }
        \cup { [tag |-> ComplexTradeMessageCode, body |-> one] : one \in CheckedComplexTradeMessage }
        \cup { [tag |-> ComplexCrossingRfqMessageCode, body |-> one] : one \in CheckedComplexCrossingRfqMessage }
        \cup { [tag |-> ComplexCubeRfqMessageCode, body |-> one] : one \in CheckedComplexCubeRfqMessage }
        \cup { [tag |-> ComplexStatusMessageCode, body |-> one] : one \in CheckedComplexStatusMessage }
        \cup { [tag |-> RefreshComplexQuoteMessageCode, body |-> one] : one \in CheckedRefreshComplexQuoteMessage }
        \cup { [tag |-> RefreshComplexTradeMessageCode, body |-> one] : one \in CheckedRefreshComplexTradeMessage }
        \cup { [tag |-> ComplexSymbolDefinitionMessageCode, body |-> one] : one \in CheckedComplexSymbolDefinitionMessage }
        \cup { [tag |-> StreamIdMessageCode, body |-> one] : one \in CheckedStreamIdMessage }
        \cup { [tag |-> SequenceNumberResetMessageCode, body |-> one] : one \in CheckedSequenceNumberResetMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> ComplexQuoteMessageCode, body |-> ZeroComplexQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexTradeMessageCode, body |-> ZeroComplexTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexCrossingRfqMessageCode, body |-> ZeroComplexCrossingRfqMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexCubeRfqMessageCode, body |-> ZeroComplexCubeRfqMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexStatusMessageCode, body |-> ZeroComplexStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshComplexQuoteMessageCode, body |-> ZeroRefreshComplexQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshComplexTradeMessageCode, body |-> ZeroRefreshComplexTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexSymbolDefinitionMessageCode, body |-> ZeroComplexSymbolDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StreamIdMessageCode, body |-> ZeroStreamIdMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetSize     : Sample(2),
      deliveryFlag   : Sample(1),
      sequenceNumber : Sample(4),
      sendTime       : SendTime,
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.packetSize
        \o message.deliveryFlag
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.sequenceNumber
        \o EncodeSendTime(message.sendTime)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetSize == ReadBytes(bytes, 2) IN IF ~packetSize.ok THEN Fail ELSE
    LET deliveryFlag == ReadBytes(packetSize.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(deliveryFlag.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageCount.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sendTime == DecodeSendTime(sequenceNumber.rest) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetSize     |-> packetSize.value,
         deliveryFlag   |-> deliveryFlag.value,
         sequenceNumber |-> sequenceNumber.value,
         sendTime       |-> sendTime.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ packetSize     |-> [i \in 1 .. 2 |-> 0],
      deliveryFlag   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime       |-> ZeroSendTime,
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.deliveryFlag = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in CheckedSendTime }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Send Time decodes back to what was encoded, and leaves nothing over *)
RoundTripSendTime ==
    \A message \in CheckedSendTime :
        LET read == DecodeSendTime(EncodeSendTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteMessage ==
    \A message \in CheckedComplexQuoteMessage :
        LET read == DecodeComplexQuoteMessage(EncodeComplexQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTradeMessage ==
    \A message \in CheckedComplexTradeMessage :
        LET read == DecodeComplexTradeMessage(EncodeComplexTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Crossing Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexCrossingRfqMessage ==
    \A message \in CheckedComplexCrossingRfqMessage :
        LET read == DecodeComplexCrossingRfqMessage(EncodeComplexCrossingRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Cube Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexCubeRfqMessage ==
    \A message \in CheckedComplexCubeRfqMessage :
        LET read == DecodeComplexCubeRfqMessage(EncodeComplexCubeRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStatusMessage ==
    \A message \in CheckedComplexStatusMessage :
        LET read == DecodeComplexStatusMessage(EncodeComplexStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complex Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshComplexQuoteMessage ==
    \A message \in CheckedRefreshComplexQuoteMessage :
        LET read == DecodeRefreshComplexQuoteMessage(EncodeRefreshComplexQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complex Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshComplexTradeMessage ==
    \A message \in CheckedRefreshComplexTradeMessage :
        LET read == DecodeRefreshComplexTradeMessage(EncodeRefreshComplexTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripLegDefinition ==
    \A message \in CheckedLegDefinition :
        LET read == DecodeLegDefinition(EncodeLegDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Symbol Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexSymbolDefinitionMessage ==
    \A message \in CheckedComplexSymbolDefinitionMessage :
        LET read == DecodeComplexSymbolDefinitionMessage(EncodeComplexSymbolDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamIdMessage ==
    \A message \in CheckedStreamIdMessage :
        LET read == DecodeStreamIdMessage(EncodeStreamIdMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Number Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceNumberResetMessage ==
    \A message \in CheckedSequenceNumberResetMessage :
        LET read == DecodeSequenceNumberResetMessage(EncodeSequenceNumberResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
