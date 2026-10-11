-------------------- MODULE ArcaOptions_DeepFeed_v1_3_a --------------------
(***************************************************************************)
(* New York Stock Exchange Deep Feed v1.3.a                                *)
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
(* Outright Market Depth Buy Message: 44 bytes                             *)
(***************************************************************************)

OutrightMarketDepthBuyMessage ==
    [ sourceTime                : Sample(4),
      sourceNs                  : Sample(4),
      seriesIndex               : Sample(4),
      symbolSeqNum              : Sample(4),
      firstLevelPrice           : Sample(4),
      secondLevelPrice          : Sample(4),
      thirdLevelPrice           : Sample(4),
      firstLevelVolume          : Sample(2),
      secondLevelVolume         : Sample(2),
      thirdLevelVolume          : Sample(2),
      quoteCondition            : Sample(1),
      reserved1                 : Sample(1),
      firstLevelCustomerVolume  : Sample(2),
      secondLevelCustomerVolume : Sample(2),
      thirdLevelCustomerVolume  : Sample(2),
      reserved2                 : Sample(2) ]

EncodeOutrightMarketDepthBuyMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.firstLevelPrice
        \o message.secondLevelPrice
        \o message.thirdLevelPrice
        \o message.firstLevelVolume
        \o message.secondLevelVolume
        \o message.thirdLevelVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.firstLevelCustomerVolume
        \o message.secondLevelCustomerVolume
        \o message.thirdLevelCustomerVolume
        \o message.reserved2

DecodeOutrightMarketDepthBuyMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET firstLevelPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~firstLevelPrice.ok THEN Fail ELSE
    LET secondLevelPrice == ReadBytes(firstLevelPrice.rest, 4) IN IF ~secondLevelPrice.ok THEN Fail ELSE
    LET thirdLevelPrice == ReadBytes(secondLevelPrice.rest, 4) IN IF ~thirdLevelPrice.ok THEN Fail ELSE
    LET firstLevelVolume == ReadBytes(thirdLevelPrice.rest, 2) IN IF ~firstLevelVolume.ok THEN Fail ELSE
    LET secondLevelVolume == ReadBytes(firstLevelVolume.rest, 2) IN IF ~secondLevelVolume.ok THEN Fail ELSE
    LET thirdLevelVolume == ReadBytes(secondLevelVolume.rest, 2) IN IF ~thirdLevelVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(thirdLevelVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET firstLevelCustomerVolume == ReadBytes(reserved1.rest, 2) IN IF ~firstLevelCustomerVolume.ok THEN Fail ELSE
    LET secondLevelCustomerVolume == ReadBytes(firstLevelCustomerVolume.rest, 2) IN IF ~secondLevelCustomerVolume.ok THEN Fail ELSE
    LET thirdLevelCustomerVolume == ReadBytes(secondLevelCustomerVolume.rest, 2) IN IF ~thirdLevelCustomerVolume.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdLevelCustomerVolume.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime                |-> sourceTime.value,
         sourceNs                  |-> sourceNs.value,
         seriesIndex               |-> seriesIndex.value,
         symbolSeqNum              |-> symbolSeqNum.value,
         firstLevelPrice           |-> firstLevelPrice.value,
         secondLevelPrice          |-> secondLevelPrice.value,
         thirdLevelPrice           |-> thirdLevelPrice.value,
         firstLevelVolume          |-> firstLevelVolume.value,
         secondLevelVolume         |-> secondLevelVolume.value,
         thirdLevelVolume          |-> thirdLevelVolume.value,
         quoteCondition            |-> quoteCondition.value,
         reserved1                 |-> reserved1.value,
         firstLevelCustomerVolume  |-> firstLevelCustomerVolume.value,
         secondLevelCustomerVolume |-> secondLevelCustomerVolume.value,
         thirdLevelCustomerVolume  |-> thirdLevelCustomerVolume.value,
         reserved2                 |-> reserved2.value ], reserved2.rest)

ZeroOutrightMarketDepthBuyMessage ==
    [ sourceTime                |-> [i \in 1 .. 4 |-> 0],
      sourceNs                  |-> [i \in 1 .. 4 |-> 0],
      seriesIndex               |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firstLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      secondLevelPrice          |-> [i \in 1 .. 4 |-> 0],
      thirdLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      firstLevelVolume          |-> [i \in 1 .. 2 |-> 0],
      secondLevelVolume         |-> [i \in 1 .. 2 |-> 0],
      thirdLevelVolume          |-> [i \in 1 .. 2 |-> 0],
      quoteCondition            |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      firstLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      secondLevelCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      thirdLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      reserved2                 |-> [i \in 1 .. 2 |-> 0] ]

(* Outright Market Depth Buy Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightMarketDepthBuyMessage ==
    { ZeroOutrightMarketDepthBuyMessage }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.firstLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.secondLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.thirdLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.firstLevelVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.secondLevelVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.thirdLevelVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.firstLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.secondLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.thirdLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthBuyMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Outright Market Depth Sell Message: 44 bytes                            *)
(***************************************************************************)

OutrightMarketDepthSellMessage ==
    [ sourceTime                : Sample(4),
      sourceNs                  : Sample(4),
      seriesIndex               : Sample(4),
      symbolSeqNum              : Sample(4),
      firstLevelPrice           : Sample(4),
      secondLevelPrice          : Sample(4),
      thirdLevelPrice           : Sample(4),
      firstVolume               : Sample(2),
      secondVolume              : Sample(2),
      thirdVolume               : Sample(2),
      quoteCondition            : Sample(1),
      reserved1                 : Sample(1),
      firstLevelCustomerVolume  : Sample(2),
      secondLevelCustomerVolume : Sample(2),
      thirdLevelCustomerVolume  : Sample(2),
      reserved2                 : Sample(2) ]

EncodeOutrightMarketDepthSellMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.firstLevelPrice
        \o message.secondLevelPrice
        \o message.thirdLevelPrice
        \o message.firstVolume
        \o message.secondVolume
        \o message.thirdVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.firstLevelCustomerVolume
        \o message.secondLevelCustomerVolume
        \o message.thirdLevelCustomerVolume
        \o message.reserved2

DecodeOutrightMarketDepthSellMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET firstLevelPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~firstLevelPrice.ok THEN Fail ELSE
    LET secondLevelPrice == ReadBytes(firstLevelPrice.rest, 4) IN IF ~secondLevelPrice.ok THEN Fail ELSE
    LET thirdLevelPrice == ReadBytes(secondLevelPrice.rest, 4) IN IF ~thirdLevelPrice.ok THEN Fail ELSE
    LET firstVolume == ReadBytes(thirdLevelPrice.rest, 2) IN IF ~firstVolume.ok THEN Fail ELSE
    LET secondVolume == ReadBytes(firstVolume.rest, 2) IN IF ~secondVolume.ok THEN Fail ELSE
    LET thirdVolume == ReadBytes(secondVolume.rest, 2) IN IF ~thirdVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(thirdVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET firstLevelCustomerVolume == ReadBytes(reserved1.rest, 2) IN IF ~firstLevelCustomerVolume.ok THEN Fail ELSE
    LET secondLevelCustomerVolume == ReadBytes(firstLevelCustomerVolume.rest, 2) IN IF ~secondLevelCustomerVolume.ok THEN Fail ELSE
    LET thirdLevelCustomerVolume == ReadBytes(secondLevelCustomerVolume.rest, 2) IN IF ~thirdLevelCustomerVolume.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdLevelCustomerVolume.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime                |-> sourceTime.value,
         sourceNs                  |-> sourceNs.value,
         seriesIndex               |-> seriesIndex.value,
         symbolSeqNum              |-> symbolSeqNum.value,
         firstLevelPrice           |-> firstLevelPrice.value,
         secondLevelPrice          |-> secondLevelPrice.value,
         thirdLevelPrice           |-> thirdLevelPrice.value,
         firstVolume               |-> firstVolume.value,
         secondVolume              |-> secondVolume.value,
         thirdVolume               |-> thirdVolume.value,
         quoteCondition            |-> quoteCondition.value,
         reserved1                 |-> reserved1.value,
         firstLevelCustomerVolume  |-> firstLevelCustomerVolume.value,
         secondLevelCustomerVolume |-> secondLevelCustomerVolume.value,
         thirdLevelCustomerVolume  |-> thirdLevelCustomerVolume.value,
         reserved2                 |-> reserved2.value ], reserved2.rest)

ZeroOutrightMarketDepthSellMessage ==
    [ sourceTime                |-> [i \in 1 .. 4 |-> 0],
      sourceNs                  |-> [i \in 1 .. 4 |-> 0],
      seriesIndex               |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firstLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      secondLevelPrice          |-> [i \in 1 .. 4 |-> 0],
      thirdLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      firstVolume               |-> [i \in 1 .. 2 |-> 0],
      secondVolume              |-> [i \in 1 .. 2 |-> 0],
      thirdVolume               |-> [i \in 1 .. 2 |-> 0],
      quoteCondition            |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      firstLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      secondLevelCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      thirdLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      reserved2                 |-> [i \in 1 .. 2 |-> 0] ]

(* Outright Market Depth Sell Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightMarketDepthSellMessage ==
    { ZeroOutrightMarketDepthSellMessage }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.firstLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.secondLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.thirdLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.firstVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.secondVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.thirdVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.firstLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.secondLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.thirdLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightMarketDepthSellMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Underlying Status Message: 20 bytes                                     *)
(***************************************************************************)

UnderlyingStatusMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      underlyingIndex  : Sample(4),
      underlyingSeqNum : Sample(4),
      securityStatus   : Sample(1),
      haltCondition    : Sample(1),
      reserved2        : Sample(2) ]

EncodeUnderlyingStatusMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.underlyingIndex
        \o message.underlyingSeqNum
        \o message.securityStatus
        \o message.haltCondition
        \o message.reserved2

DecodeUnderlyingStatusMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET underlyingIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~underlyingIndex.ok THEN Fail ELSE
    LET underlyingSeqNum == ReadBytes(underlyingIndex.rest, 4) IN IF ~underlyingSeqNum.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(underlyingSeqNum.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltCondition == ReadBytes(securityStatus.rest, 1) IN IF ~haltCondition.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(haltCondition.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         underlyingIndex  |-> underlyingIndex.value,
         underlyingSeqNum |-> underlyingSeqNum.value,
         securityStatus   |-> securityStatus.value,
         haltCondition    |-> haltCondition.value,
         reserved2        |-> reserved2.value ], reserved2.rest)

ZeroUnderlyingStatusMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      underlyingIndex  |-> [i \in 1 .. 4 |-> 0],
      underlyingSeqNum |-> [i \in 1 .. 4 |-> 0],
      securityStatus   |-> [i \in 1 .. 1 |-> 0],
      haltCondition    |-> [i \in 1 .. 1 |-> 0],
      reserved2        |-> [i \in 1 .. 2 |-> 0] ]

(* Underlying Status Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingStatusMessage ==
    { ZeroUnderlyingStatusMessage }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.underlyingIndex = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.underlyingSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.haltCondition = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Outright Series Status Message: 20 bytes                                *)
(***************************************************************************)

OutrightSeriesStatusMessage ==
    [ sourceTime     : Sample(4),
      sourceTimeNs   : Sample(4),
      seriesIndex    : Sample(4),
      symbolSeqNum   : Sample(4),
      securityStatus : Sample(1),
      haltCondition  : Sample(1),
      reserved2      : Sample(2) ]

EncodeOutrightSeriesStatusMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.securityStatus
        \o message.haltCondition
        \o message.reserved2

DecodeOutrightSeriesStatusMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(symbolSeqNum.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltCondition == ReadBytes(securityStatus.rest, 1) IN IF ~haltCondition.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(haltCondition.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime     |-> sourceTime.value,
         sourceTimeNs   |-> sourceTimeNs.value,
         seriesIndex    |-> seriesIndex.value,
         symbolSeqNum   |-> symbolSeqNum.value,
         securityStatus |-> securityStatus.value,
         haltCondition  |-> haltCondition.value,
         reserved2      |-> reserved2.value ], reserved2.rest)

ZeroOutrightSeriesStatusMessage ==
    [ sourceTime     |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs   |-> [i \in 1 .. 4 |-> 0],
      seriesIndex    |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum   |-> [i \in 1 .. 4 |-> 0],
      securityStatus |-> [i \in 1 .. 1 |-> 0],
      haltCondition  |-> [i \in 1 .. 1 |-> 0],
      reserved2      |-> [i \in 1 .. 2 |-> 0] ]

(* Outright Series Status Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightSeriesStatusMessage ==
    { ZeroOutrightSeriesStatusMessage }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.haltCondition = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Refresh Outright Market Depth Buy Message: 44 bytes                     *)
(***************************************************************************)

RefreshOutrightMarketDepthBuyMessage ==
    [ sourceTime                : Sample(4),
      sourceNs                  : Sample(4),
      seriesIndex               : Sample(4),
      symbolSeqNum              : Sample(4),
      firstLevelPrice           : Sample(4),
      secondLevelPrice          : Sample(4),
      thirdLevelPrice           : Sample(4),
      firstVolume               : Sample(2),
      secondVolume              : Sample(2),
      thirdVolume               : Sample(2),
      quoteCondition            : Sample(1),
      reserved1                 : Sample(1),
      firstLevelCustomerVolume  : Sample(2),
      secondLevelCustomerVolume : Sample(2),
      thirdLevelCustomerVolume  : Sample(2),
      reserved2                 : Sample(2) ]

EncodeRefreshOutrightMarketDepthBuyMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.firstLevelPrice
        \o message.secondLevelPrice
        \o message.thirdLevelPrice
        \o message.firstVolume
        \o message.secondVolume
        \o message.thirdVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.firstLevelCustomerVolume
        \o message.secondLevelCustomerVolume
        \o message.thirdLevelCustomerVolume
        \o message.reserved2

DecodeRefreshOutrightMarketDepthBuyMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET firstLevelPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~firstLevelPrice.ok THEN Fail ELSE
    LET secondLevelPrice == ReadBytes(firstLevelPrice.rest, 4) IN IF ~secondLevelPrice.ok THEN Fail ELSE
    LET thirdLevelPrice == ReadBytes(secondLevelPrice.rest, 4) IN IF ~thirdLevelPrice.ok THEN Fail ELSE
    LET firstVolume == ReadBytes(thirdLevelPrice.rest, 2) IN IF ~firstVolume.ok THEN Fail ELSE
    LET secondVolume == ReadBytes(firstVolume.rest, 2) IN IF ~secondVolume.ok THEN Fail ELSE
    LET thirdVolume == ReadBytes(secondVolume.rest, 2) IN IF ~thirdVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(thirdVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET firstLevelCustomerVolume == ReadBytes(reserved1.rest, 2) IN IF ~firstLevelCustomerVolume.ok THEN Fail ELSE
    LET secondLevelCustomerVolume == ReadBytes(firstLevelCustomerVolume.rest, 2) IN IF ~secondLevelCustomerVolume.ok THEN Fail ELSE
    LET thirdLevelCustomerVolume == ReadBytes(secondLevelCustomerVolume.rest, 2) IN IF ~thirdLevelCustomerVolume.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdLevelCustomerVolume.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime                |-> sourceTime.value,
         sourceNs                  |-> sourceNs.value,
         seriesIndex               |-> seriesIndex.value,
         symbolSeqNum              |-> symbolSeqNum.value,
         firstLevelPrice           |-> firstLevelPrice.value,
         secondLevelPrice          |-> secondLevelPrice.value,
         thirdLevelPrice           |-> thirdLevelPrice.value,
         firstVolume               |-> firstVolume.value,
         secondVolume              |-> secondVolume.value,
         thirdVolume               |-> thirdVolume.value,
         quoteCondition            |-> quoteCondition.value,
         reserved1                 |-> reserved1.value,
         firstLevelCustomerVolume  |-> firstLevelCustomerVolume.value,
         secondLevelCustomerVolume |-> secondLevelCustomerVolume.value,
         thirdLevelCustomerVolume  |-> thirdLevelCustomerVolume.value,
         reserved2                 |-> reserved2.value ], reserved2.rest)

ZeroRefreshOutrightMarketDepthBuyMessage ==
    [ sourceTime                |-> [i \in 1 .. 4 |-> 0],
      sourceNs                  |-> [i \in 1 .. 4 |-> 0],
      seriesIndex               |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firstLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      secondLevelPrice          |-> [i \in 1 .. 4 |-> 0],
      thirdLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      firstVolume               |-> [i \in 1 .. 2 |-> 0],
      secondVolume              |-> [i \in 1 .. 2 |-> 0],
      thirdVolume               |-> [i \in 1 .. 2 |-> 0],
      quoteCondition            |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      firstLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      secondLevelCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      thirdLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      reserved2                 |-> [i \in 1 .. 2 |-> 0] ]

(* Refresh Outright Market Depth Buy Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshOutrightMarketDepthBuyMessage ==
    { ZeroRefreshOutrightMarketDepthBuyMessage }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.firstLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.secondLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.thirdLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.firstVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.secondVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.thirdVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.firstLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.secondLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.thirdLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthBuyMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Refresh Outright Market Depth Sell Message: 44 bytes                    *)
(***************************************************************************)

RefreshOutrightMarketDepthSellMessage ==
    [ sourceTime                : Sample(4),
      sourceTimeNs              : Sample(4),
      seriesIndex               : Sample(4),
      symbolSeqNum              : Sample(4),
      firstLevelPrice           : Sample(4),
      secondLevelPrice          : Sample(4),
      thirdLevelPrice           : Sample(4),
      firstVolume               : Sample(2),
      secondVolume              : Sample(2),
      thirdVolume               : Sample(2),
      quoteCondition            : Sample(1),
      reserved1                 : Sample(1),
      firstLevelCustomerVolume  : Sample(2),
      secondLevelCustomerVolume : Sample(2),
      thirdLevelCustomerVolume  : Sample(2),
      reserved2                 : Sample(2) ]

EncodeRefreshOutrightMarketDepthSellMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.firstLevelPrice
        \o message.secondLevelPrice
        \o message.thirdLevelPrice
        \o message.firstVolume
        \o message.secondVolume
        \o message.thirdVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.firstLevelCustomerVolume
        \o message.secondLevelCustomerVolume
        \o message.thirdLevelCustomerVolume
        \o message.reserved2

DecodeRefreshOutrightMarketDepthSellMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET firstLevelPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~firstLevelPrice.ok THEN Fail ELSE
    LET secondLevelPrice == ReadBytes(firstLevelPrice.rest, 4) IN IF ~secondLevelPrice.ok THEN Fail ELSE
    LET thirdLevelPrice == ReadBytes(secondLevelPrice.rest, 4) IN IF ~thirdLevelPrice.ok THEN Fail ELSE
    LET firstVolume == ReadBytes(thirdLevelPrice.rest, 2) IN IF ~firstVolume.ok THEN Fail ELSE
    LET secondVolume == ReadBytes(firstVolume.rest, 2) IN IF ~secondVolume.ok THEN Fail ELSE
    LET thirdVolume == ReadBytes(secondVolume.rest, 2) IN IF ~thirdVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(thirdVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET firstLevelCustomerVolume == ReadBytes(reserved1.rest, 2) IN IF ~firstLevelCustomerVolume.ok THEN Fail ELSE
    LET secondLevelCustomerVolume == ReadBytes(firstLevelCustomerVolume.rest, 2) IN IF ~secondLevelCustomerVolume.ok THEN Fail ELSE
    LET thirdLevelCustomerVolume == ReadBytes(secondLevelCustomerVolume.rest, 2) IN IF ~thirdLevelCustomerVolume.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdLevelCustomerVolume.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime                |-> sourceTime.value,
         sourceTimeNs              |-> sourceTimeNs.value,
         seriesIndex               |-> seriesIndex.value,
         symbolSeqNum              |-> symbolSeqNum.value,
         firstLevelPrice           |-> firstLevelPrice.value,
         secondLevelPrice          |-> secondLevelPrice.value,
         thirdLevelPrice           |-> thirdLevelPrice.value,
         firstVolume               |-> firstVolume.value,
         secondVolume              |-> secondVolume.value,
         thirdVolume               |-> thirdVolume.value,
         quoteCondition            |-> quoteCondition.value,
         reserved1                 |-> reserved1.value,
         firstLevelCustomerVolume  |-> firstLevelCustomerVolume.value,
         secondLevelCustomerVolume |-> secondLevelCustomerVolume.value,
         thirdLevelCustomerVolume  |-> thirdLevelCustomerVolume.value,
         reserved2                 |-> reserved2.value ], reserved2.rest)

ZeroRefreshOutrightMarketDepthSellMessage ==
    [ sourceTime                |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs              |-> [i \in 1 .. 4 |-> 0],
      seriesIndex               |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firstLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      secondLevelPrice          |-> [i \in 1 .. 4 |-> 0],
      thirdLevelPrice           |-> [i \in 1 .. 4 |-> 0],
      firstVolume               |-> [i \in 1 .. 2 |-> 0],
      secondVolume              |-> [i \in 1 .. 2 |-> 0],
      thirdVolume               |-> [i \in 1 .. 2 |-> 0],
      quoteCondition            |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      firstLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      secondLevelCustomerVolume |-> [i \in 1 .. 2 |-> 0],
      thirdLevelCustomerVolume  |-> [i \in 1 .. 2 |-> 0],
      reserved2                 |-> [i \in 1 .. 2 |-> 0] ]

(* Refresh Outright Market Depth Sell Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshOutrightMarketDepthSellMessage ==
    { ZeroRefreshOutrightMarketDepthSellMessage }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.firstLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.secondLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.thirdLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.firstVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.secondVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.thirdVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.firstLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.secondLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.thirdLevelCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightMarketDepthSellMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Underlying Index Mapping Message: 24 bytes                              *)
(***************************************************************************)

UnderlyingIndexMappingMessage ==
    [ underlyingIndex  : Sample(4),
      underlyingSymbol : Sample(11),
      channelId        : Sample(1),
      marketId         : Sample(2),
      systemId         : Sample(1),
      exchangeCode     : Sample(1),
      priceScaleCode   : Sample(1),
      securityType     : Sample(1),
      priceResolution  : Sample(1),
      reserved1        : Sample(1) ]

EncodeUnderlyingIndexMappingMessage(message) ==
    message.underlyingIndex
        \o message.underlyingSymbol
        \o message.channelId
        \o message.marketId
        \o message.systemId
        \o message.exchangeCode
        \o message.priceScaleCode
        \o message.securityType
        \o message.priceResolution
        \o message.reserved1

DecodeUnderlyingIndexMappingMessage(bytes) ==
    LET underlyingIndex == ReadBytes(bytes, 4) IN IF ~underlyingIndex.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(underlyingIndex.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET channelId == ReadBytes(underlyingSymbol.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET marketId == ReadBytes(channelId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET systemId == ReadBytes(marketId.rest, 1) IN IF ~systemId.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(systemId.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(exchangeCode.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(priceScaleCode.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET priceResolution == ReadBytes(securityType.rest, 1) IN IF ~priceResolution.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(priceResolution.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ underlyingIndex  |-> underlyingIndex.value,
         underlyingSymbol |-> underlyingSymbol.value,
         channelId        |-> channelId.value,
         marketId         |-> marketId.value,
         systemId         |-> systemId.value,
         exchangeCode     |-> exchangeCode.value,
         priceScaleCode   |-> priceScaleCode.value,
         securityType     |-> securityType.value,
         priceResolution  |-> priceResolution.value,
         reserved1        |-> reserved1.value ], reserved1.rest)

ZeroUnderlyingIndexMappingMessage ==
    [ underlyingIndex  |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      channelId        |-> [i \in 1 .. 1 |-> 0],
      marketId         |-> [i \in 1 .. 2 |-> 0],
      systemId         |-> [i \in 1 .. 1 |-> 0],
      exchangeCode     |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode   |-> [i \in 1 .. 1 |-> 0],
      securityType     |-> [i \in 1 .. 1 |-> 0],
      priceResolution  |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Index Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingIndexMappingMessage ==
    { ZeroUnderlyingIndexMappingMessage }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.underlyingIndex = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.systemId = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.priceResolution = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingIndexMappingMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Index Mapping Message: 56 bytes                                  *)
(***************************************************************************)

SeriesIndexMappingMessage ==
    [ seriesIndex        : Sample(4),
      channelId          : Sample(1),
      reservedA1         : Sample(1),
      marketId           : Sample(2),
      systemId           : Sample(1),
      reservedB1         : Sample(1),
      streamId           : Sample(2),
      underlyingIndex    : Sample(4),
      contractMultiplier : Sample(2),
      maturityDate       : Sample(6),
      putOrCall          : Sample(1),
      strikePrice        : Sample(10),
      priceScaleCode     : Sample(1),
      underlyingSymbol   : Sample(11),
      optionSymbolRoot   : Sample(5),
      groupId            : Sample(4) ]

EncodeSeriesIndexMappingMessage(message) ==
    message.seriesIndex
        \o message.channelId
        \o message.reservedA1
        \o message.marketId
        \o message.systemId
        \o message.reservedB1
        \o message.streamId
        \o message.underlyingIndex
        \o message.contractMultiplier
        \o message.maturityDate
        \o message.putOrCall
        \o message.strikePrice
        \o message.priceScaleCode
        \o message.underlyingSymbol
        \o message.optionSymbolRoot
        \o message.groupId

DecodeSeriesIndexMappingMessage(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET channelId == ReadBytes(seriesIndex.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET reservedA1 == ReadBytes(channelId.rest, 1) IN IF ~reservedA1.ok THEN Fail ELSE
    LET marketId == ReadBytes(reservedA1.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET systemId == ReadBytes(marketId.rest, 1) IN IF ~systemId.ok THEN Fail ELSE
    LET reservedB1 == ReadBytes(systemId.rest, 1) IN IF ~reservedB1.ok THEN Fail ELSE
    LET streamId == ReadBytes(reservedB1.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET underlyingIndex == ReadBytes(streamId.rest, 4) IN IF ~underlyingIndex.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(underlyingIndex.rest, 2) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(contractMultiplier.rest, 6) IN IF ~maturityDate.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(maturityDate.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 10) IN IF ~strikePrice.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(strikePrice.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(priceScaleCode.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET optionSymbolRoot == ReadBytes(underlyingSymbol.rest, 5) IN IF ~optionSymbolRoot.ok THEN Fail ELSE
    LET groupId == ReadBytes(optionSymbolRoot.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    Ok([ seriesIndex        |-> seriesIndex.value,
         channelId          |-> channelId.value,
         reservedA1         |-> reservedA1.value,
         marketId           |-> marketId.value,
         systemId           |-> systemId.value,
         reservedB1         |-> reservedB1.value,
         streamId           |-> streamId.value,
         underlyingIndex    |-> underlyingIndex.value,
         contractMultiplier |-> contractMultiplier.value,
         maturityDate       |-> maturityDate.value,
         putOrCall          |-> putOrCall.value,
         strikePrice        |-> strikePrice.value,
         priceScaleCode     |-> priceScaleCode.value,
         underlyingSymbol   |-> underlyingSymbol.value,
         optionSymbolRoot   |-> optionSymbolRoot.value,
         groupId            |-> groupId.value ], groupId.rest)

ZeroSeriesIndexMappingMessage ==
    [ seriesIndex        |-> [i \in 1 .. 4 |-> 0],
      channelId          |-> [i \in 1 .. 1 |-> 0],
      reservedA1         |-> [i \in 1 .. 1 |-> 0],
      marketId           |-> [i \in 1 .. 2 |-> 0],
      systemId           |-> [i \in 1 .. 1 |-> 0],
      reservedB1         |-> [i \in 1 .. 1 |-> 0],
      streamId           |-> [i \in 1 .. 2 |-> 0],
      underlyingIndex    |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier |-> [i \in 1 .. 2 |-> 0],
      maturityDate       |-> [i \in 1 .. 6 |-> 0],
      putOrCall          |-> [i \in 1 .. 1 |-> 0],
      strikePrice        |-> [i \in 1 .. 10 |-> 0],
      priceScaleCode     |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol   |-> [i \in 1 .. 11 |-> 0],
      optionSymbolRoot   |-> [i \in 1 .. 5 |-> 0],
      groupId            |-> [i \in 1 .. 4 |-> 0] ]

(* Series Index Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesIndexMappingMessage ==
    { ZeroSeriesIndexMappingMessage }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.reservedA1 = one] : one \in Sample(1) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.systemId = one] : one \in Sample(1) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.reservedB1 = one] : one \in Sample(1) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.underlyingIndex = one] : one \in Sample(4) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.contractMultiplier = one] : one \in Sample(2) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.maturityDate = one] : one \in Sample(6) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.strikePrice = one] : one \in Sample(10) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.optionSymbolRoot = one] : one \in Sample(5) }
        \cup { [ZeroSeriesIndexMappingMessage EXCEPT !.groupId = one] : one \in Sample(4) }

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

OutrightMarketDepthBuyMessageCode == 403  \* 0x193
OutrightMarketDepthSellMessageCode == 405  \* 0x195
UnderlyingStatusMessageCode == 419  \* 0x1a3
OutrightSeriesStatusMessageCode == 421  \* 0x1a5
RefreshOutrightMarketDepthBuyMessageCode == 503  \* 0x1f7
RefreshOutrightMarketDepthSellMessageCode == 505  \* 0x1f9
UnderlyingIndexMappingMessageCode == 435  \* 0x1b3
SeriesIndexMappingMessageCode == 437  \* 0x1b5
StreamIdMessageCode == 455  \* 0x1c7
SequenceNumberResetMessageCode == 1  \* 0x01

Payload ==
    [ tag : {OutrightMarketDepthBuyMessageCode}, body : OutrightMarketDepthBuyMessage ]
        \cup [ tag : {OutrightMarketDepthSellMessageCode}, body : OutrightMarketDepthSellMessage ]
        \cup [ tag : {UnderlyingStatusMessageCode}, body : UnderlyingStatusMessage ]
        \cup [ tag : {OutrightSeriesStatusMessageCode}, body : OutrightSeriesStatusMessage ]
        \cup [ tag : {RefreshOutrightMarketDepthBuyMessageCode}, body : RefreshOutrightMarketDepthBuyMessage ]
        \cup [ tag : {RefreshOutrightMarketDepthSellMessageCode}, body : RefreshOutrightMarketDepthSellMessage ]
        \cup [ tag : {UnderlyingIndexMappingMessageCode}, body : UnderlyingIndexMappingMessage ]
        \cup [ tag : {SeriesIndexMappingMessageCode}, body : SeriesIndexMappingMessage ]
        \cup [ tag : {StreamIdMessageCode}, body : StreamIdMessage ]
        \cup [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]

EncodePayload(message) ==
    CASE message.tag = OutrightMarketDepthBuyMessageCode -> EncodeOutrightMarketDepthBuyMessage(message.body)
      [] message.tag = OutrightMarketDepthSellMessageCode -> EncodeOutrightMarketDepthSellMessage(message.body)
      [] message.tag = UnderlyingStatusMessageCode -> EncodeUnderlyingStatusMessage(message.body)
      [] message.tag = OutrightSeriesStatusMessageCode -> EncodeOutrightSeriesStatusMessage(message.body)
      [] message.tag = RefreshOutrightMarketDepthBuyMessageCode -> EncodeRefreshOutrightMarketDepthBuyMessage(message.body)
      [] message.tag = RefreshOutrightMarketDepthSellMessageCode -> EncodeRefreshOutrightMarketDepthSellMessage(message.body)
      [] message.tag = UnderlyingIndexMappingMessageCode -> EncodeUnderlyingIndexMappingMessage(message.body)
      [] message.tag = SeriesIndexMappingMessageCode -> EncodeSeriesIndexMappingMessage(message.body)
      [] message.tag = StreamIdMessageCode -> EncodeStreamIdMessage(message.body)
      [] message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OutrightMarketDepthBuyMessageCode -> DecodeOutrightMarketDepthBuyMessage(bytes)
              [] tag = OutrightMarketDepthSellMessageCode -> DecodeOutrightMarketDepthSellMessage(bytes)
              [] tag = UnderlyingStatusMessageCode -> DecodeUnderlyingStatusMessage(bytes)
              [] tag = OutrightSeriesStatusMessageCode -> DecodeOutrightSeriesStatusMessage(bytes)
              [] tag = RefreshOutrightMarketDepthBuyMessageCode -> DecodeRefreshOutrightMarketDepthBuyMessage(bytes)
              [] tag = RefreshOutrightMarketDepthSellMessageCode -> DecodeRefreshOutrightMarketDepthSellMessage(bytes)
              [] tag = UnderlyingIndexMappingMessageCode -> DecodeUnderlyingIndexMappingMessage(bytes)
              [] tag = SeriesIndexMappingMessageCode -> DecodeSeriesIndexMappingMessage(bytes)
              [] tag = StreamIdMessageCode -> DecodeStreamIdMessage(bytes)
              [] tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OutrightMarketDepthBuyMessageCode, body |-> ZeroOutrightMarketDepthBuyMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OutrightMarketDepthBuyMessageCode, body |-> one] : one \in CheckedOutrightMarketDepthBuyMessage }
        \cup { [tag |-> OutrightMarketDepthSellMessageCode, body |-> one] : one \in CheckedOutrightMarketDepthSellMessage }
        \cup { [tag |-> UnderlyingStatusMessageCode, body |-> one] : one \in CheckedUnderlyingStatusMessage }
        \cup { [tag |-> OutrightSeriesStatusMessageCode, body |-> one] : one \in CheckedOutrightSeriesStatusMessage }
        \cup { [tag |-> RefreshOutrightMarketDepthBuyMessageCode, body |-> one] : one \in CheckedRefreshOutrightMarketDepthBuyMessage }
        \cup { [tag |-> RefreshOutrightMarketDepthSellMessageCode, body |-> one] : one \in CheckedRefreshOutrightMarketDepthSellMessage }
        \cup { [tag |-> UnderlyingIndexMappingMessageCode, body |-> one] : one \in CheckedUnderlyingIndexMappingMessage }
        \cup { [tag |-> SeriesIndexMappingMessageCode, body |-> one] : one \in CheckedSeriesIndexMappingMessage }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> OutrightMarketDepthBuyMessageCode, body |-> ZeroOutrightMarketDepthBuyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightMarketDepthSellMessageCode, body |-> ZeroOutrightMarketDepthSellMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnderlyingStatusMessageCode, body |-> ZeroUnderlyingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightSeriesStatusMessageCode, body |-> ZeroOutrightSeriesStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshOutrightMarketDepthBuyMessageCode, body |-> ZeroRefreshOutrightMarketDepthBuyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshOutrightMarketDepthSellMessageCode, body |-> ZeroRefreshOutrightMarketDepthSellMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnderlyingIndexMappingMessageCode, body |-> ZeroUnderlyingIndexMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SeriesIndexMappingMessageCode, body |-> ZeroSeriesIndexMappingMessage]],
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

(* Every Outright Market Depth Buy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightMarketDepthBuyMessage ==
    \A message \in CheckedOutrightMarketDepthBuyMessage :
        LET read == DecodeOutrightMarketDepthBuyMessage(EncodeOutrightMarketDepthBuyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Market Depth Sell Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightMarketDepthSellMessage ==
    \A message \in CheckedOutrightMarketDepthSellMessage :
        LET read == DecodeOutrightMarketDepthSellMessage(EncodeOutrightMarketDepthSellMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingStatusMessage ==
    \A message \in CheckedUnderlyingStatusMessage :
        LET read == DecodeUnderlyingStatusMessage(EncodeUnderlyingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Series Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightSeriesStatusMessage ==
    \A message \in CheckedOutrightSeriesStatusMessage :
        LET read == DecodeOutrightSeriesStatusMessage(EncodeOutrightSeriesStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Outright Market Depth Buy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshOutrightMarketDepthBuyMessage ==
    \A message \in CheckedRefreshOutrightMarketDepthBuyMessage :
        LET read == DecodeRefreshOutrightMarketDepthBuyMessage(EncodeRefreshOutrightMarketDepthBuyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Outright Market Depth Sell Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshOutrightMarketDepthSellMessage ==
    \A message \in CheckedRefreshOutrightMarketDepthSellMessage :
        LET read == DecodeRefreshOutrightMarketDepthSellMessage(EncodeRefreshOutrightMarketDepthSellMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Index Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingIndexMappingMessage ==
    \A message \in CheckedUnderlyingIndexMappingMessage :
        LET read == DecodeUnderlyingIndexMappingMessage(EncodeUnderlyingIndexMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Index Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesIndexMappingMessage ==
    \A message \in CheckedSeriesIndexMappingMessage :
        LET read == DecodeSeriesIndexMappingMessage(EncodeSeriesIndexMappingMessage(message))
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
