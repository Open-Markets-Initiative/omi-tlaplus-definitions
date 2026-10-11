-------------------- MODULE ArcaOptions_TopFeed_v1_3_a ---------------------
(***************************************************************************)
(* New York Stock Exchange Top Feed v1.3.a                                 *)
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
(* Outright Quote Message: 36 bytes                                        *)
(***************************************************************************)

OutrightQuoteMessage ==
    [ sourceTime        : Sample(4),
      sourceTimeNs      : Sample(4),
      seriesIndex       : Sample(4),
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

EncodeOutrightQuoteMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
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

DecodeOutrightQuoteMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
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
         seriesIndex       |-> seriesIndex.value,
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

ZeroOutrightQuoteMessage ==
    [ sourceTime        |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs      |-> [i \in 1 .. 4 |-> 0],
      seriesIndex       |-> [i \in 1 .. 4 |-> 0],
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

(* Outright Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightQuoteMessage ==
    { ZeroOutrightQuoteMessage }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.askVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.bidVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.askCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.bidCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightQuoteMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Outright Trade Message: 32 bytes                                        *)
(***************************************************************************)

OutrightTradeMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      seriesIndex  : Sample(4),
      symbolSeqNum : Sample(4),
      tradeId      : Sample(4),
      price        : Sample(4),
      volume4      : Sample(4),
      tradeCond1   : Sample(1),
      tradeCond2   : Sample(1),
      reserved2    : Sample(2) ]

EncodeOutrightTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.volume4
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.reserved2

DecodeOutrightTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume4 == ReadBytes(price.rest, 4) IN IF ~volume4.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume4.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(tradeCond2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         seriesIndex  |-> seriesIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         volume4      |-> volume4.value,
         tradeCond1   |-> tradeCond1.value,
         tradeCond2   |-> tradeCond2.value,
         reserved2    |-> reserved2.value ], reserved2.rest)

ZeroOutrightTradeMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      volume4      |-> [i \in 1 .. 4 |-> 0],
      tradeCond1   |-> [i \in 1 .. 1 |-> 0],
      tradeCond2   |-> [i \in 1 .. 1 |-> 0],
      reserved2    |-> [i \in 1 .. 2 |-> 0] ]

(* Outright Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightTradeMessage ==
    { ZeroOutrightTradeMessage }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.volume4 = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightTradeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Outright Trade Cancel Message: 20 bytes                                 *)
(***************************************************************************)

OutrightTradeCancelMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      seriesIndex     : Sample(4),
      symbolSeqNum    : Sample(4),
      originalTradeId : Sample(4) ]

EncodeOutrightTradeCancelMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.originalTradeId

DecodeOutrightTradeCancelMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         seriesIndex     |-> seriesIndex.value,
         symbolSeqNum    |-> symbolSeqNum.value,
         originalTradeId |-> originalTradeId.value ], originalTradeId.rest)

ZeroOutrightTradeCancelMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      seriesIndex     |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum    |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 4 |-> 0] ]

(* Outright Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightTradeCancelMessage ==
    { ZeroOutrightTradeCancelMessage }
        \cup { [ZeroOutrightTradeCancelMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCancelMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCancelMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCancelMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCancelMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Outright Trade Correction Message: 36 bytes                             *)
(***************************************************************************)

OutrightTradeCorrectionMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      seriesIndex     : Sample(4),
      symbolSeqNum    : Sample(4),
      originalTradeId : Sample(4),
      tradeId         : Sample(4),
      price           : Sample(4),
      volume4         : Sample(4),
      tradeCond1      : Sample(1),
      tradeCond2      : Sample(1),
      reserved2       : Sample(2) ]

EncodeOutrightTradeCorrectionMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.originalTradeId
        \o message.tradeId
        \o message.price
        \o message.volume4
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.reserved2

DecodeOutrightTradeCorrectionMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(originalTradeId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume4 == ReadBytes(price.rest, 4) IN IF ~volume4.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume4.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(tradeCond2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         seriesIndex     |-> seriesIndex.value,
         symbolSeqNum    |-> symbolSeqNum.value,
         originalTradeId |-> originalTradeId.value,
         tradeId         |-> tradeId.value,
         price           |-> price.value,
         volume4         |-> volume4.value,
         tradeCond1      |-> tradeCond1.value,
         tradeCond2      |-> tradeCond2.value,
         reserved2       |-> reserved2.value ], reserved2.rest)

ZeroOutrightTradeCorrectionMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      seriesIndex     |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum    |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 4 |-> 0],
      tradeId         |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      volume4         |-> [i \in 1 .. 4 |-> 0],
      tradeCond1      |-> [i \in 1 .. 1 |-> 0],
      tradeCond2      |-> [i \in 1 .. 1 |-> 0],
      reserved2       |-> [i \in 1 .. 2 |-> 0] ]

(* Outright Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightTradeCorrectionMessage ==
    { ZeroOutrightTradeCorrectionMessage }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.volume4 = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightTradeCorrectionMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Outright Imbalance Message: 32 bytes                                    *)
(***************************************************************************)

OutrightImbalanceMessage ==
    [ sourceTime          : Sample(4),
      sourceTimeNs        : Sample(4),
      seriesIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      referencePrice      : Sample(4),
      pairedQty           : Sample(2),
      totalImbalanceQty   : Sample(2),
      marketImbalanceQty  : Sample(2),
      auctionType         : Sample(1),
      imbalanceSide       : Sample(1),
      marketImbalanceSide : Sample(1),
      reserved3           : Sample(3) ]

EncodeOutrightImbalanceMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.referencePrice
        \o message.pairedQty
        \o message.totalImbalanceQty
        \o message.marketImbalanceQty
        \o message.auctionType
        \o message.imbalanceSide
        \o message.marketImbalanceSide
        \o message.reserved3

DecodeOutrightImbalanceMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET pairedQty == ReadBytes(referencePrice.rest, 2) IN IF ~pairedQty.ok THEN Fail ELSE
    LET totalImbalanceQty == ReadBytes(pairedQty.rest, 2) IN IF ~totalImbalanceQty.ok THEN Fail ELSE
    LET marketImbalanceQty == ReadBytes(totalImbalanceQty.rest, 2) IN IF ~marketImbalanceQty.ok THEN Fail ELSE
    LET auctionType == ReadBytes(marketImbalanceQty.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(auctionType.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET marketImbalanceSide == ReadBytes(imbalanceSide.rest, 1) IN IF ~marketImbalanceSide.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(marketImbalanceSide.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ sourceTime          |-> sourceTime.value,
         sourceTimeNs        |-> sourceTimeNs.value,
         seriesIndex         |-> seriesIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         referencePrice      |-> referencePrice.value,
         pairedQty           |-> pairedQty.value,
         totalImbalanceQty   |-> totalImbalanceQty.value,
         marketImbalanceQty  |-> marketImbalanceQty.value,
         auctionType         |-> auctionType.value,
         imbalanceSide       |-> imbalanceSide.value,
         marketImbalanceSide |-> marketImbalanceSide.value,
         reserved3           |-> reserved3.value ], reserved3.rest)

ZeroOutrightImbalanceMessage ==
    [ sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      seriesIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      referencePrice      |-> [i \in 1 .. 4 |-> 0],
      pairedQty           |-> [i \in 1 .. 2 |-> 0],
      totalImbalanceQty   |-> [i \in 1 .. 2 |-> 0],
      marketImbalanceQty  |-> [i \in 1 .. 2 |-> 0],
      auctionType         |-> [i \in 1 .. 1 |-> 0],
      imbalanceSide       |-> [i \in 1 .. 1 |-> 0],
      marketImbalanceSide |-> [i \in 1 .. 1 |-> 0],
      reserved3           |-> [i \in 1 .. 3 |-> 0] ]

(* Outright Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightImbalanceMessage ==
    { ZeroOutrightImbalanceMessage }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.pairedQty = one] : one \in Sample(2) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.totalImbalanceQty = one] : one \in Sample(2) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.marketImbalanceQty = one] : one \in Sample(2) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.marketImbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroOutrightImbalanceMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Outright Crossing Rfq Message: 24 bytes                                 *)
(***************************************************************************)

OutrightCrossingRfqMessage ==
    [ sourceTime   : Sample(4),
      sourceNs     : Sample(4),
      seriesIndex  : Sample(4),
      symbolSeqNum : Sample(4),
      side         : Sample(1),
      reserved1    : Sample(1),
      volume2      : Sample(2),
      price        : Sample(4) ]

EncodeOutrightCrossingRfqMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.side
        \o message.reserved1
        \o message.volume2
        \o message.price

DecodeOutrightCrossingRfqMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSeqNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(side.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET volume2 == ReadBytes(reserved1.rest, 2) IN IF ~volume2.ok THEN Fail ELSE
    LET price == ReadBytes(volume2.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceNs     |-> sourceNs.value,
         seriesIndex  |-> seriesIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         side         |-> side.value,
         reserved1    |-> reserved1.value,
         volume2      |-> volume2.value,
         price        |-> price.value ], price.rest)

ZeroOutrightCrossingRfqMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceNs     |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      volume2      |-> [i \in 1 .. 2 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0] ]

(* Outright Crossing Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightCrossingRfqMessage ==
    { ZeroOutrightCrossingRfqMessage }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.volume2 = one] : one \in Sample(2) }
        \cup { [ZeroOutrightCrossingRfqMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Outright Bold Rfq Message: 28 bytes                                     *)
(***************************************************************************)

OutrightBoldRfqMessage ==
    [ sourceTime   : Sample(4),
      sourceNs     : Sample(4),
      seriesIndex  : Sample(4),
      symbolSeqNum : Sample(4),
      side         : Sample(1),
      capacity     : Sample(1),
      contracts    : Sample(2),
      price        : Sample(4),
      participant  : Sample(4) ]

EncodeOutrightBoldRfqMessage(message) ==
    message.sourceTime
        \o message.sourceNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.side
        \o message.capacity
        \o message.contracts
        \o message.price
        \o message.participant

DecodeOutrightBoldRfqMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSeqNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadBytes(side.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET contracts == ReadBytes(capacity.rest, 2) IN IF ~contracts.ok THEN Fail ELSE
    LET price == ReadBytes(contracts.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET participant == ReadBytes(price.rest, 4) IN IF ~participant.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceNs     |-> sourceNs.value,
         seriesIndex  |-> seriesIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         side         |-> side.value,
         capacity     |-> capacity.value,
         contracts    |-> contracts.value,
         price        |-> price.value,
         participant  |-> participant.value ], participant.rest)

ZeroOutrightBoldRfqMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceNs     |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      capacity     |-> [i \in 1 .. 1 |-> 0],
      contracts    |-> [i \in 1 .. 2 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      participant  |-> [i \in 1 .. 4 |-> 0] ]

(* Outright Bold Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightBoldRfqMessage ==
    { ZeroOutrightBoldRfqMessage }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.sourceNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.contracts = one] : one \in Sample(2) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOutrightBoldRfqMessage EXCEPT !.participant = one] : one \in Sample(4) }

(***************************************************************************)
(* Outright Summary Message: 36 bytes                                      *)
(***************************************************************************)

OutrightSummaryMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      seriesIndex  : Sample(4),
      symbolSeqNum : Sample(4),
      highPrice    : Sample(4),
      lowPrice     : Sample(4),
      open         : Sample(4),
      close        : Sample(4),
      totalVolume  : Sample(4) ]

EncodeOutrightSummaryMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.highPrice
        \o message.lowPrice
        \o message.open
        \o message.close
        \o message.totalVolume

DecodeOutrightSummaryMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET highPrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET open == ReadBytes(lowPrice.rest, 4) IN IF ~open.ok THEN Fail ELSE
    LET close == ReadBytes(open.rest, 4) IN IF ~close.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(close.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         seriesIndex  |-> seriesIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         highPrice    |-> highPrice.value,
         lowPrice     |-> lowPrice.value,
         open         |-> open.value,
         close        |-> close.value,
         totalVolume  |-> totalVolume.value ], totalVolume.rest)

ZeroOutrightSummaryMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      highPrice    |-> [i \in 1 .. 4 |-> 0],
      lowPrice     |-> [i \in 1 .. 4 |-> 0],
      open         |-> [i \in 1 .. 4 |-> 0],
      close        |-> [i \in 1 .. 4 |-> 0],
      totalVolume  |-> [i \in 1 .. 4 |-> 0] ]

(* Outright Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightSummaryMessage ==
    { ZeroOutrightSummaryMessage }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.open = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.close = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }

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
(* Refresh Outright Quote Message: 36 bytes                                *)
(***************************************************************************)

RefreshOutrightQuoteMessage ==
    [ sourceTime        : Sample(4),
      sourceTimeNs      : Sample(4),
      seriesIndex       : Sample(4),
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

EncodeRefreshOutrightQuoteMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
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

DecodeRefreshOutrightQuoteMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
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
         seriesIndex       |-> seriesIndex.value,
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

ZeroRefreshOutrightQuoteMessage ==
    [ sourceTime        |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs      |-> [i \in 1 .. 4 |-> 0],
      seriesIndex       |-> [i \in 1 .. 4 |-> 0],
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

(* Refresh Outright Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshOutrightQuoteMessage ==
    { ZeroRefreshOutrightQuoteMessage }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.askVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.bidVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.askCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.bidCustomerVolume = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightQuoteMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Refresh Outright Trade Message: 32 bytes                                *)
(***************************************************************************)

RefreshOutrightTradeMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      seriesIndex  : Sample(4),
      symbolSeqNum : Sample(4),
      tradeId      : Sample(4),
      price        : Sample(4),
      volume4      : Sample(4),
      tradeCond1   : Sample(1),
      tradeCond2   : Sample(1),
      reserved2    : Sample(2) ]

EncodeRefreshOutrightTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.volume4
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.reserved2

DecodeRefreshOutrightTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume4 == ReadBytes(price.rest, 4) IN IF ~volume4.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume4.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(tradeCond2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         seriesIndex  |-> seriesIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         volume4      |-> volume4.value,
         tradeCond1   |-> tradeCond1.value,
         tradeCond2   |-> tradeCond2.value,
         reserved2    |-> reserved2.value ], reserved2.rest)

ZeroRefreshOutrightTradeMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      volume4      |-> [i \in 1 .. 4 |-> 0],
      tradeCond1   |-> [i \in 1 .. 1 |-> 0],
      tradeCond2   |-> [i \in 1 .. 1 |-> 0],
      reserved2    |-> [i \in 1 .. 2 |-> 0] ]

(* Refresh Outright Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshOutrightTradeMessage ==
    { ZeroRefreshOutrightTradeMessage }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.volume4 = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightTradeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Refresh Outright Imbalance Message: 32 bytes                            *)
(***************************************************************************)

RefreshOutrightImbalanceMessage ==
    [ sourceTime          : Sample(4),
      sourceTimeNs        : Sample(4),
      seriesIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      referencePrice      : Sample(4),
      pairedQty           : Sample(2),
      totalImbalanceQty   : Sample(2),
      marketImbalanceQty  : Sample(2),
      auctionType         : Sample(1),
      imbalanceSide       : Sample(1),
      marketImbalanceSide : Sample(1),
      reserved3           : Sample(3) ]

EncodeRefreshOutrightImbalanceMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.symbolSeqNum
        \o message.referencePrice
        \o message.pairedQty
        \o message.totalImbalanceQty
        \o message.marketImbalanceQty
        \o message.auctionType
        \o message.imbalanceSide
        \o message.marketImbalanceSide
        \o message.reserved3

DecodeRefreshOutrightImbalanceMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET pairedQty == ReadBytes(referencePrice.rest, 2) IN IF ~pairedQty.ok THEN Fail ELSE
    LET totalImbalanceQty == ReadBytes(pairedQty.rest, 2) IN IF ~totalImbalanceQty.ok THEN Fail ELSE
    LET marketImbalanceQty == ReadBytes(totalImbalanceQty.rest, 2) IN IF ~marketImbalanceQty.ok THEN Fail ELSE
    LET auctionType == ReadBytes(marketImbalanceQty.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(auctionType.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET marketImbalanceSide == ReadBytes(imbalanceSide.rest, 1) IN IF ~marketImbalanceSide.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(marketImbalanceSide.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ sourceTime          |-> sourceTime.value,
         sourceTimeNs        |-> sourceTimeNs.value,
         seriesIndex         |-> seriesIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         referencePrice      |-> referencePrice.value,
         pairedQty           |-> pairedQty.value,
         totalImbalanceQty   |-> totalImbalanceQty.value,
         marketImbalanceQty  |-> marketImbalanceQty.value,
         auctionType         |-> auctionType.value,
         imbalanceSide       |-> imbalanceSide.value,
         marketImbalanceSide |-> marketImbalanceSide.value,
         reserved3           |-> reserved3.value ], reserved3.rest)

ZeroRefreshOutrightImbalanceMessage ==
    [ sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      seriesIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      referencePrice      |-> [i \in 1 .. 4 |-> 0],
      pairedQty           |-> [i \in 1 .. 2 |-> 0],
      totalImbalanceQty   |-> [i \in 1 .. 2 |-> 0],
      marketImbalanceQty  |-> [i \in 1 .. 2 |-> 0],
      auctionType         |-> [i \in 1 .. 1 |-> 0],
      imbalanceSide       |-> [i \in 1 .. 1 |-> 0],
      marketImbalanceSide |-> [i \in 1 .. 1 |-> 0],
      reserved3           |-> [i \in 1 .. 3 |-> 0] ]

(* Refresh Outright Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshOutrightImbalanceMessage ==
    { ZeroRefreshOutrightImbalanceMessage }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.pairedQty = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.totalImbalanceQty = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.marketImbalanceQty = one] : one \in Sample(2) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.marketImbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroRefreshOutrightImbalanceMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

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

OutrightQuoteMessageCode == 401  \* 0x191
OutrightTradeMessageCode == 407  \* 0x197
OutrightTradeCancelMessageCode == 409  \* 0x199
OutrightTradeCorrectionMessageCode == 411  \* 0x19b
OutrightImbalanceMessageCode == 413  \* 0x19d
OutrightCrossingRfqMessageCode == 415  \* 0x19f
OutrightBoldRfqMessageCode == 471  \* 0x1d7
OutrightSummaryMessageCode == 417  \* 0x1a1
UnderlyingStatusMessageCode == 419  \* 0x1a3
OutrightSeriesStatusMessageCode == 421  \* 0x1a5
RefreshOutrightQuoteMessageCode == 501  \* 0x1f5
RefreshOutrightTradeMessageCode == 507  \* 0x1fb
RefreshOutrightImbalanceMessageCode == 509  \* 0x1fd
UnderlyingIndexMappingMessageCode == 435  \* 0x1b3
SeriesIndexMappingMessageCode == 437  \* 0x1b5
StreamIdMessageCode == 455  \* 0x1c7
SequenceNumberResetMessageCode == 1  \* 0x01

Payload ==
    [ tag : {OutrightQuoteMessageCode}, body : OutrightQuoteMessage ]
        \cup [ tag : {OutrightTradeMessageCode}, body : OutrightTradeMessage ]
        \cup [ tag : {OutrightTradeCancelMessageCode}, body : OutrightTradeCancelMessage ]
        \cup [ tag : {OutrightTradeCorrectionMessageCode}, body : OutrightTradeCorrectionMessage ]
        \cup [ tag : {OutrightImbalanceMessageCode}, body : OutrightImbalanceMessage ]
        \cup [ tag : {OutrightCrossingRfqMessageCode}, body : OutrightCrossingRfqMessage ]
        \cup [ tag : {OutrightBoldRfqMessageCode}, body : OutrightBoldRfqMessage ]
        \cup [ tag : {OutrightSummaryMessageCode}, body : OutrightSummaryMessage ]
        \cup [ tag : {UnderlyingStatusMessageCode}, body : UnderlyingStatusMessage ]
        \cup [ tag : {OutrightSeriesStatusMessageCode}, body : OutrightSeriesStatusMessage ]
        \cup [ tag : {RefreshOutrightQuoteMessageCode}, body : RefreshOutrightQuoteMessage ]
        \cup [ tag : {RefreshOutrightTradeMessageCode}, body : RefreshOutrightTradeMessage ]
        \cup [ tag : {RefreshOutrightImbalanceMessageCode}, body : RefreshOutrightImbalanceMessage ]
        \cup [ tag : {UnderlyingIndexMappingMessageCode}, body : UnderlyingIndexMappingMessage ]
        \cup [ tag : {SeriesIndexMappingMessageCode}, body : SeriesIndexMappingMessage ]
        \cup [ tag : {StreamIdMessageCode}, body : StreamIdMessage ]
        \cup [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]

EncodePayload(message) ==
    CASE message.tag = OutrightQuoteMessageCode -> EncodeOutrightQuoteMessage(message.body)
      [] message.tag = OutrightTradeMessageCode -> EncodeOutrightTradeMessage(message.body)
      [] message.tag = OutrightTradeCancelMessageCode -> EncodeOutrightTradeCancelMessage(message.body)
      [] message.tag = OutrightTradeCorrectionMessageCode -> EncodeOutrightTradeCorrectionMessage(message.body)
      [] message.tag = OutrightImbalanceMessageCode -> EncodeOutrightImbalanceMessage(message.body)
      [] message.tag = OutrightCrossingRfqMessageCode -> EncodeOutrightCrossingRfqMessage(message.body)
      [] message.tag = OutrightBoldRfqMessageCode -> EncodeOutrightBoldRfqMessage(message.body)
      [] message.tag = OutrightSummaryMessageCode -> EncodeOutrightSummaryMessage(message.body)
      [] message.tag = UnderlyingStatusMessageCode -> EncodeUnderlyingStatusMessage(message.body)
      [] message.tag = OutrightSeriesStatusMessageCode -> EncodeOutrightSeriesStatusMessage(message.body)
      [] message.tag = RefreshOutrightQuoteMessageCode -> EncodeRefreshOutrightQuoteMessage(message.body)
      [] message.tag = RefreshOutrightTradeMessageCode -> EncodeRefreshOutrightTradeMessage(message.body)
      [] message.tag = RefreshOutrightImbalanceMessageCode -> EncodeRefreshOutrightImbalanceMessage(message.body)
      [] message.tag = UnderlyingIndexMappingMessageCode -> EncodeUnderlyingIndexMappingMessage(message.body)
      [] message.tag = SeriesIndexMappingMessageCode -> EncodeSeriesIndexMappingMessage(message.body)
      [] message.tag = StreamIdMessageCode -> EncodeStreamIdMessage(message.body)
      [] message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OutrightQuoteMessageCode -> DecodeOutrightQuoteMessage(bytes)
              [] tag = OutrightTradeMessageCode -> DecodeOutrightTradeMessage(bytes)
              [] tag = OutrightTradeCancelMessageCode -> DecodeOutrightTradeCancelMessage(bytes)
              [] tag = OutrightTradeCorrectionMessageCode -> DecodeOutrightTradeCorrectionMessage(bytes)
              [] tag = OutrightImbalanceMessageCode -> DecodeOutrightImbalanceMessage(bytes)
              [] tag = OutrightCrossingRfqMessageCode -> DecodeOutrightCrossingRfqMessage(bytes)
              [] tag = OutrightBoldRfqMessageCode -> DecodeOutrightBoldRfqMessage(bytes)
              [] tag = OutrightSummaryMessageCode -> DecodeOutrightSummaryMessage(bytes)
              [] tag = UnderlyingStatusMessageCode -> DecodeUnderlyingStatusMessage(bytes)
              [] tag = OutrightSeriesStatusMessageCode -> DecodeOutrightSeriesStatusMessage(bytes)
              [] tag = RefreshOutrightQuoteMessageCode -> DecodeRefreshOutrightQuoteMessage(bytes)
              [] tag = RefreshOutrightTradeMessageCode -> DecodeRefreshOutrightTradeMessage(bytes)
              [] tag = RefreshOutrightImbalanceMessageCode -> DecodeRefreshOutrightImbalanceMessage(bytes)
              [] tag = UnderlyingIndexMappingMessageCode -> DecodeUnderlyingIndexMappingMessage(bytes)
              [] tag = SeriesIndexMappingMessageCode -> DecodeSeriesIndexMappingMessage(bytes)
              [] tag = StreamIdMessageCode -> DecodeStreamIdMessage(bytes)
              [] tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OutrightQuoteMessageCode, body |-> ZeroOutrightQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OutrightQuoteMessageCode, body |-> one] : one \in CheckedOutrightQuoteMessage }
        \cup { [tag |-> OutrightTradeMessageCode, body |-> one] : one \in CheckedOutrightTradeMessage }
        \cup { [tag |-> OutrightTradeCancelMessageCode, body |-> one] : one \in CheckedOutrightTradeCancelMessage }
        \cup { [tag |-> OutrightTradeCorrectionMessageCode, body |-> one] : one \in CheckedOutrightTradeCorrectionMessage }
        \cup { [tag |-> OutrightImbalanceMessageCode, body |-> one] : one \in CheckedOutrightImbalanceMessage }
        \cup { [tag |-> OutrightCrossingRfqMessageCode, body |-> one] : one \in CheckedOutrightCrossingRfqMessage }
        \cup { [tag |-> OutrightBoldRfqMessageCode, body |-> one] : one \in CheckedOutrightBoldRfqMessage }
        \cup { [tag |-> OutrightSummaryMessageCode, body |-> one] : one \in CheckedOutrightSummaryMessage }
        \cup { [tag |-> UnderlyingStatusMessageCode, body |-> one] : one \in CheckedUnderlyingStatusMessage }
        \cup { [tag |-> OutrightSeriesStatusMessageCode, body |-> one] : one \in CheckedOutrightSeriesStatusMessage }
        \cup { [tag |-> RefreshOutrightQuoteMessageCode, body |-> one] : one \in CheckedRefreshOutrightQuoteMessage }
        \cup { [tag |-> RefreshOutrightTradeMessageCode, body |-> one] : one \in CheckedRefreshOutrightTradeMessage }
        \cup { [tag |-> RefreshOutrightImbalanceMessageCode, body |-> one] : one \in CheckedRefreshOutrightImbalanceMessage }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> OutrightQuoteMessageCode, body |-> ZeroOutrightQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightTradeMessageCode, body |-> ZeroOutrightTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightTradeCancelMessageCode, body |-> ZeroOutrightTradeCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightTradeCorrectionMessageCode, body |-> ZeroOutrightTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightImbalanceMessageCode, body |-> ZeroOutrightImbalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightCrossingRfqMessageCode, body |-> ZeroOutrightCrossingRfqMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightBoldRfqMessageCode, body |-> ZeroOutrightBoldRfqMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightSummaryMessageCode, body |-> ZeroOutrightSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnderlyingStatusMessageCode, body |-> ZeroUnderlyingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightSeriesStatusMessageCode, body |-> ZeroOutrightSeriesStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshOutrightQuoteMessageCode, body |-> ZeroRefreshOutrightQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshOutrightTradeMessageCode, body |-> ZeroRefreshOutrightTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshOutrightImbalanceMessageCode, body |-> ZeroRefreshOutrightImbalanceMessage]],
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

(* Every Outright Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightQuoteMessage ==
    \A message \in CheckedOutrightQuoteMessage :
        LET read == DecodeOutrightQuoteMessage(EncodeOutrightQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightTradeMessage ==
    \A message \in CheckedOutrightTradeMessage :
        LET read == DecodeOutrightTradeMessage(EncodeOutrightTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightTradeCancelMessage ==
    \A message \in CheckedOutrightTradeCancelMessage :
        LET read == DecodeOutrightTradeCancelMessage(EncodeOutrightTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightTradeCorrectionMessage ==
    \A message \in CheckedOutrightTradeCorrectionMessage :
        LET read == DecodeOutrightTradeCorrectionMessage(EncodeOutrightTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightImbalanceMessage ==
    \A message \in CheckedOutrightImbalanceMessage :
        LET read == DecodeOutrightImbalanceMessage(EncodeOutrightImbalanceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Crossing Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightCrossingRfqMessage ==
    \A message \in CheckedOutrightCrossingRfqMessage :
        LET read == DecodeOutrightCrossingRfqMessage(EncodeOutrightCrossingRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Bold Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightBoldRfqMessage ==
    \A message \in CheckedOutrightBoldRfqMessage :
        LET read == DecodeOutrightBoldRfqMessage(EncodeOutrightBoldRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightSummaryMessage ==
    \A message \in CheckedOutrightSummaryMessage :
        LET read == DecodeOutrightSummaryMessage(EncodeOutrightSummaryMessage(message))
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

(* Every Refresh Outright Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshOutrightQuoteMessage ==
    \A message \in CheckedRefreshOutrightQuoteMessage :
        LET read == DecodeRefreshOutrightQuoteMessage(EncodeRefreshOutrightQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Outright Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshOutrightTradeMessage ==
    \A message \in CheckedRefreshOutrightTradeMessage :
        LET read == DecodeRefreshOutrightTradeMessage(EncodeRefreshOutrightTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Outright Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshOutrightImbalanceMessage ==
    \A message \in CheckedRefreshOutrightImbalanceMessage :
        LET read == DecodeRefreshOutrightImbalanceMessage(EncodeRefreshOutrightImbalanceMessage(message))
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
