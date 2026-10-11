--------------------- MODULE LinkAts_QuoteBook_v4_10_4 ---------------------
(***************************************************************************)
(* OTC Markets Group  v4.10.4                                              *)
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
(* Note: Packet Flag is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: a Messages of 0 marks Heartbeat Packet and carries no Message.    *)
(*                                                                         *)
(* Note: Security Flags is a bit field set, checked as its 1 byte rather   *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Quote Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Extended Quote Flags is a bit field set, checked as its 1 byte    *)
(* rather than bit by bit.                                                 *)
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
(* Start Of Spin Message: 17 bytes                                         *)
(***************************************************************************)

StartOfSpinMessage ==
    [ channelSeqNum      : Sample(4),
      spinType           : Sample(1),
      spinStartTimeMilli : Sample(8),
      spinLastSeqNum     : Sample(4) ]

EncodeStartOfSpinMessage(message) ==
    message.channelSeqNum
        \o message.spinType
        \o message.spinStartTimeMilli
        \o message.spinLastSeqNum

DecodeStartOfSpinMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET spinType == ReadBytes(channelSeqNum.rest, 1) IN IF ~spinType.ok THEN Fail ELSE
    LET spinStartTimeMilli == ReadBytes(spinType.rest, 8) IN IF ~spinStartTimeMilli.ok THEN Fail ELSE
    LET spinLastSeqNum == ReadBytes(spinStartTimeMilli.rest, 4) IN IF ~spinLastSeqNum.ok THEN Fail ELSE
    Ok([ channelSeqNum      |-> channelSeqNum.value,
         spinType           |-> spinType.value,
         spinStartTimeMilli |-> spinStartTimeMilli.value,
         spinLastSeqNum     |-> spinLastSeqNum.value ], spinLastSeqNum.rest)

ZeroStartOfSpinMessage ==
    [ channelSeqNum      |-> [i \in 1 .. 4 |-> 0],
      spinType           |-> [i \in 1 .. 1 |-> 0],
      spinStartTimeMilli |-> [i \in 1 .. 8 |-> 0],
      spinLastSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Start Of Spin Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfSpinMessage ==
    { ZeroStartOfSpinMessage }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.spinType = one] : one \in Sample(1) }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.spinStartTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.spinLastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Spin Message: 21 bytes                                           *)
(***************************************************************************)

EndOfSpinMessage ==
    [ channelSeqNum    : Sample(4),
      spinType         : Sample(1),
      spinMsgCt        : Sample(4),
      spinEndTimeMilli : Sample(8),
      spinLastSeqNum   : Sample(4) ]

EncodeEndOfSpinMessage(message) ==
    message.channelSeqNum
        \o message.spinType
        \o message.spinMsgCt
        \o message.spinEndTimeMilli
        \o message.spinLastSeqNum

DecodeEndOfSpinMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET spinType == ReadBytes(channelSeqNum.rest, 1) IN IF ~spinType.ok THEN Fail ELSE
    LET spinMsgCt == ReadBytes(spinType.rest, 4) IN IF ~spinMsgCt.ok THEN Fail ELSE
    LET spinEndTimeMilli == ReadBytes(spinMsgCt.rest, 8) IN IF ~spinEndTimeMilli.ok THEN Fail ELSE
    LET spinLastSeqNum == ReadBytes(spinEndTimeMilli.rest, 4) IN IF ~spinLastSeqNum.ok THEN Fail ELSE
    Ok([ channelSeqNum    |-> channelSeqNum.value,
         spinType         |-> spinType.value,
         spinMsgCt        |-> spinMsgCt.value,
         spinEndTimeMilli |-> spinEndTimeMilli.value,
         spinLastSeqNum   |-> spinLastSeqNum.value ], spinLastSeqNum.rest)

ZeroEndOfSpinMessage ==
    [ channelSeqNum    |-> [i \in 1 .. 4 |-> 0],
      spinType         |-> [i \in 1 .. 1 |-> 0],
      spinMsgCt        |-> [i \in 1 .. 4 |-> 0],
      spinEndTimeMilli |-> [i \in 1 .. 8 |-> 0],
      spinLastSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Spin Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSpinMessage ==
    { ZeroEndOfSpinMessage }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinType = one] : one \in Sample(1) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinMsgCt = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinEndTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinLastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Open Message: 20 bytes                                           *)
(***************************************************************************)

MarketOpenMessage ==
    [ channelSeqNum : Sample(4),
      marketOpen    : Sample(8),
      marketClose   : Sample(8) ]

EncodeMarketOpenMessage(message) ==
    message.channelSeqNum
        \o message.marketOpen
        \o message.marketClose

DecodeMarketOpenMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET marketOpen == ReadBytes(channelSeqNum.rest, 8) IN IF ~marketOpen.ok THEN Fail ELSE
    LET marketClose == ReadBytes(marketOpen.rest, 8) IN IF ~marketClose.ok THEN Fail ELSE
    Ok([ channelSeqNum |-> channelSeqNum.value,
         marketOpen    |-> marketOpen.value,
         marketClose   |-> marketClose.value ], marketClose.rest)

ZeroMarketOpenMessage ==
    [ channelSeqNum |-> [i \in 1 .. 4 |-> 0],
      marketOpen    |-> [i \in 1 .. 8 |-> 0],
      marketClose   |-> [i \in 1 .. 8 |-> 0] ]

(* Market Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOpenMessage ==
    { ZeroMarketOpenMessage }
        \cup { [ZeroMarketOpenMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketOpenMessage EXCEPT !.marketOpen = one] : one \in Sample(8) }
        \cup { [ZeroMarketOpenMessage EXCEPT !.marketClose = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Close Message: 16 bytes                                          *)
(***************************************************************************)

MarketCloseMessage ==
    [ channelSeqNum        : Sample(4),
      marketCloseTimeMilli : Sample(8),
      marketMsgCt          : Sample(4) ]

EncodeMarketCloseMessage(message) ==
    message.channelSeqNum
        \o message.marketCloseTimeMilli
        \o message.marketMsgCt

DecodeMarketCloseMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET marketCloseTimeMilli == ReadBytes(channelSeqNum.rest, 8) IN IF ~marketCloseTimeMilli.ok THEN Fail ELSE
    LET marketMsgCt == ReadBytes(marketCloseTimeMilli.rest, 4) IN IF ~marketMsgCt.ok THEN Fail ELSE
    Ok([ channelSeqNum        |-> channelSeqNum.value,
         marketCloseTimeMilli |-> marketCloseTimeMilli.value,
         marketMsgCt          |-> marketMsgCt.value ], marketMsgCt.rest)

ZeroMarketCloseMessage ==
    [ channelSeqNum        |-> [i \in 1 .. 4 |-> 0],
      marketCloseTimeMilli |-> [i \in 1 .. 8 |-> 0],
      marketMsgCt          |-> [i \in 1 .. 4 |-> 0] ]

(* Market Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCloseMessage ==
    { ZeroMarketCloseMessage }
        \cup { [ZeroMarketCloseMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketCloseMessage EXCEPT !.marketCloseTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroMarketCloseMessage EXCEPT !.marketMsgCt = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Message: 32 bytes                                              *)
(***************************************************************************)

SecurityMessage ==
    [ channelSeqNum   : Sample(4),
      symbol          : Sample(10),
      lastUpdateMilli : Sample(8),
      securityAction  : Sample(1),
      assetClass      : Sample(1),
      securityId      : Sample(4),
      securityFlags   : Sample(1),
      tier            : Sample(1),
      reportingStatus : Sample(1),
      securityStatus  : Sample(1) ]

EncodeSecurityMessage(message) ==
    message.channelSeqNum
        \o message.symbol
        \o message.lastUpdateMilli
        \o message.securityAction
        \o message.assetClass
        \o message.securityId
        \o message.securityFlags
        \o message.tier
        \o message.reportingStatus
        \o message.securityStatus

DecodeSecurityMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET symbol == ReadBytes(channelSeqNum.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET lastUpdateMilli == ReadBytes(symbol.rest, 8) IN IF ~lastUpdateMilli.ok THEN Fail ELSE
    LET securityAction == ReadBytes(lastUpdateMilli.rest, 1) IN IF ~securityAction.ok THEN Fail ELSE
    LET assetClass == ReadBytes(securityAction.rest, 1) IN IF ~assetClass.ok THEN Fail ELSE
    LET securityId == ReadBytes(assetClass.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityFlags == ReadBytes(securityId.rest, 1) IN IF ~securityFlags.ok THEN Fail ELSE
    LET tier == ReadBytes(securityFlags.rest, 1) IN IF ~tier.ok THEN Fail ELSE
    LET reportingStatus == ReadBytes(tier.rest, 1) IN IF ~reportingStatus.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(reportingStatus.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    Ok([ channelSeqNum   |-> channelSeqNum.value,
         symbol          |-> symbol.value,
         lastUpdateMilli |-> lastUpdateMilli.value,
         securityAction  |-> securityAction.value,
         assetClass      |-> assetClass.value,
         securityId      |-> securityId.value,
         securityFlags   |-> securityFlags.value,
         tier            |-> tier.value,
         reportingStatus |-> reportingStatus.value,
         securityStatus  |-> securityStatus.value ], securityStatus.rest)

ZeroSecurityMessage ==
    [ channelSeqNum   |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 10 |-> 0],
      lastUpdateMilli |-> [i \in 1 .. 8 |-> 0],
      securityAction  |-> [i \in 1 .. 1 |-> 0],
      assetClass      |-> [i \in 1 .. 1 |-> 0],
      securityId      |-> [i \in 1 .. 4 |-> 0],
      securityFlags   |-> [i \in 1 .. 1 |-> 0],
      tier            |-> [i \in 1 .. 1 |-> 0],
      reportingStatus |-> [i \in 1 .. 1 |-> 0],
      securityStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* Security Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityMessage ==
    { ZeroSecurityMessage }
        \cup { [ZeroSecurityMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSecurityMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecurityMessage EXCEPT !.lastUpdateMilli = one] : one \in Sample(8) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityAction = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.assetClass = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityFlags = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.tier = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.reportingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Message: 63 bytes                                                 *)
(***************************************************************************)

QuoteMessage ==
    [ channelSeqNum      : Sample(4),
      quoteId            : Sample(4),
      quoteAction        : Sample(1),
      quoteFlags         : Sample(1),
      securityId         : Sample(4),
      mpid               : Sample(4),
      askPrice           : Sample(8),
      askSize            : Sample(4),
      askQap             : Sample(1),
      askTimeMilli       : Sample(8),
      bidPrice           : Sample(8),
      bidSize            : Sample(4),
      bidQap             : Sample(1),
      bidTimeMilli       : Sample(8),
      quoteReferenceId   : Sample(2),
      extendedQuoteFlags : Sample(1) ]

EncodeQuoteMessage(message) ==
    message.channelSeqNum
        \o message.quoteId
        \o message.quoteAction
        \o message.quoteFlags
        \o message.securityId
        \o message.mpid
        \o message.askPrice
        \o message.askSize
        \o message.askQap
        \o message.askTimeMilli
        \o message.bidPrice
        \o message.bidSize
        \o message.bidQap
        \o message.bidTimeMilli
        \o message.quoteReferenceId
        \o message.extendedQuoteFlags

DecodeQuoteMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET quoteId == ReadBytes(channelSeqNum.rest, 4) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteAction == ReadBytes(quoteId.rest, 1) IN IF ~quoteAction.ok THEN Fail ELSE
    LET quoteFlags == ReadBytes(quoteAction.rest, 1) IN IF ~quoteFlags.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteFlags.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET mpid == ReadBytes(securityId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET askPrice == ReadBytes(mpid.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askQap == ReadBytes(askSize.rest, 1) IN IF ~askQap.ok THEN Fail ELSE
    LET askTimeMilli == ReadBytes(askQap.rest, 8) IN IF ~askTimeMilli.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askTimeMilli.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidQap == ReadBytes(bidSize.rest, 1) IN IF ~bidQap.ok THEN Fail ELSE
    LET bidTimeMilli == ReadBytes(bidQap.rest, 8) IN IF ~bidTimeMilli.ok THEN Fail ELSE
    LET quoteReferenceId == ReadBytes(bidTimeMilli.rest, 2) IN IF ~quoteReferenceId.ok THEN Fail ELSE
    LET extendedQuoteFlags == ReadBytes(quoteReferenceId.rest, 1) IN IF ~extendedQuoteFlags.ok THEN Fail ELSE
    Ok([ channelSeqNum      |-> channelSeqNum.value,
         quoteId            |-> quoteId.value,
         quoteAction        |-> quoteAction.value,
         quoteFlags         |-> quoteFlags.value,
         securityId         |-> securityId.value,
         mpid               |-> mpid.value,
         askPrice           |-> askPrice.value,
         askSize            |-> askSize.value,
         askQap             |-> askQap.value,
         askTimeMilli       |-> askTimeMilli.value,
         bidPrice           |-> bidPrice.value,
         bidSize            |-> bidSize.value,
         bidQap             |-> bidQap.value,
         bidTimeMilli       |-> bidTimeMilli.value,
         quoteReferenceId   |-> quoteReferenceId.value,
         extendedQuoteFlags |-> extendedQuoteFlags.value ], extendedQuoteFlags.rest)

ZeroQuoteMessage ==
    [ channelSeqNum      |-> [i \in 1 .. 4 |-> 0],
      quoteId            |-> [i \in 1 .. 4 |-> 0],
      quoteAction        |-> [i \in 1 .. 1 |-> 0],
      quoteFlags         |-> [i \in 1 .. 1 |-> 0],
      securityId         |-> [i \in 1 .. 4 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      askPrice           |-> [i \in 1 .. 8 |-> 0],
      askSize            |-> [i \in 1 .. 4 |-> 0],
      askQap             |-> [i \in 1 .. 1 |-> 0],
      askTimeMilli       |-> [i \in 1 .. 8 |-> 0],
      bidPrice           |-> [i \in 1 .. 8 |-> 0],
      bidSize            |-> [i \in 1 .. 4 |-> 0],
      bidQap             |-> [i \in 1 .. 1 |-> 0],
      bidTimeMilli       |-> [i \in 1 .. 8 |-> 0],
      quoteReferenceId   |-> [i \in 1 .. 2 |-> 0],
      extendedQuoteFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteAction = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.askQap = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.askTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidQap = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteReferenceId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteMessage EXCEPT !.extendedQuoteFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Update Message: 33 bytes                                          *)
(***************************************************************************)

QuoteUpdateMessage ==
    [ channelSeqNum      : Sample(4),
      quoteId            : Sample(4),
      quoteFlags         : Sample(1),
      price              : Sample(8),
      size               : Sample(4),
      qap                : Sample(1),
      quoteTimeMilli     : Sample(8),
      quoteReferenceId   : Sample(2),
      extendedQuoteFlags : Sample(1) ]

EncodeQuoteUpdateMessage(message) ==
    message.channelSeqNum
        \o message.quoteId
        \o message.quoteFlags
        \o message.price
        \o message.size
        \o message.qap
        \o message.quoteTimeMilli
        \o message.quoteReferenceId
        \o message.extendedQuoteFlags

DecodeQuoteUpdateMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET quoteId == ReadBytes(channelSeqNum.rest, 4) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteFlags == ReadBytes(quoteId.rest, 1) IN IF ~quoteFlags.ok THEN Fail ELSE
    LET price == ReadBytes(quoteFlags.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET qap == ReadBytes(size.rest, 1) IN IF ~qap.ok THEN Fail ELSE
    LET quoteTimeMilli == ReadBytes(qap.rest, 8) IN IF ~quoteTimeMilli.ok THEN Fail ELSE
    LET quoteReferenceId == ReadBytes(quoteTimeMilli.rest, 2) IN IF ~quoteReferenceId.ok THEN Fail ELSE
    LET extendedQuoteFlags == ReadBytes(quoteReferenceId.rest, 1) IN IF ~extendedQuoteFlags.ok THEN Fail ELSE
    Ok([ channelSeqNum      |-> channelSeqNum.value,
         quoteId            |-> quoteId.value,
         quoteFlags         |-> quoteFlags.value,
         price              |-> price.value,
         size               |-> size.value,
         qap                |-> qap.value,
         quoteTimeMilli     |-> quoteTimeMilli.value,
         quoteReferenceId   |-> quoteReferenceId.value,
         extendedQuoteFlags |-> extendedQuoteFlags.value ], extendedQuoteFlags.rest)

ZeroQuoteUpdateMessage ==
    [ channelSeqNum      |-> [i \in 1 .. 4 |-> 0],
      quoteId            |-> [i \in 1 .. 4 |-> 0],
      quoteFlags         |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      qap                |-> [i \in 1 .. 1 |-> 0],
      quoteTimeMilli     |-> [i \in 1 .. 8 |-> 0],
      quoteReferenceId   |-> [i \in 1 .. 2 |-> 0],
      extendedQuoteFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateMessage ==
    { ZeroQuoteUpdateMessage }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.qap = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteReferenceId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.extendedQuoteFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

StartOfSpinMessageCode == 11  \* 0x0b
EndOfSpinMessageCode == 12  \* 0x0c
MarketOpenMessageCode == 13  \* 0x0d
MarketCloseMessageCode == 14  \* 0x0e
SecurityMessageCode == 9  \* 0x09
QuoteMessageCode == 1  \* 0x01
QuoteUpdateMessageCode == 2  \* 0x02

Payload ==
    [ tag : {StartOfSpinMessageCode}, body : StartOfSpinMessage ]
        \cup [ tag : {EndOfSpinMessageCode}, body : EndOfSpinMessage ]
        \cup [ tag : {MarketOpenMessageCode}, body : MarketOpenMessage ]
        \cup [ tag : {MarketCloseMessageCode}, body : MarketCloseMessage ]
        \cup [ tag : {SecurityMessageCode}, body : SecurityMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {QuoteUpdateMessageCode}, body : QuoteUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = StartOfSpinMessageCode -> EncodeStartOfSpinMessage(message.body)
      [] message.tag = EndOfSpinMessageCode -> EncodeEndOfSpinMessage(message.body)
      [] message.tag = MarketOpenMessageCode -> EncodeMarketOpenMessage(message.body)
      [] message.tag = MarketCloseMessageCode -> EncodeMarketCloseMessage(message.body)
      [] message.tag = SecurityMessageCode -> EncodeSecurityMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = QuoteUpdateMessageCode -> EncodeQuoteUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfSpinMessageCode -> DecodeStartOfSpinMessage(bytes)
              [] tag = EndOfSpinMessageCode -> DecodeEndOfSpinMessage(bytes)
              [] tag = MarketOpenMessageCode -> DecodeMarketOpenMessage(bytes)
              [] tag = MarketCloseMessageCode -> DecodeMarketCloseMessage(bytes)
              [] tag = SecurityMessageCode -> DecodeSecurityMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = QuoteUpdateMessageCode -> DecodeQuoteUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> StartOfSpinMessageCode, body |-> ZeroStartOfSpinMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> StartOfSpinMessageCode, body |-> one] : one \in CheckedStartOfSpinMessage }
        \cup { [tag |-> EndOfSpinMessageCode, body |-> one] : one \in CheckedEndOfSpinMessage }
        \cup { [tag |-> MarketOpenMessageCode, body |-> one] : one \in CheckedMarketOpenMessage }
        \cup { [tag |-> MarketCloseMessageCode, body |-> one] : one \in CheckedMarketCloseMessage }
        \cup { [tag |-> SecurityMessageCode, body |-> one] : one \in CheckedSecurityMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> QuoteUpdateMessageCode, body |-> one] : one \in CheckedQuoteUpdateMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> StartOfSpinMessageCode, body |-> ZeroStartOfSpinMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSpinMessageCode, body |-> ZeroEndOfSpinMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketOpenMessageCode, body |-> ZeroMarketOpenMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketCloseMessageCode, body |-> ZeroMarketCloseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityMessageCode, body |-> ZeroSecurityMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteUpdateMessageCode, body |-> ZeroQuoteUpdateMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetSize  : Sample(2),
      seqNum      : Sample(4),
      packetFlag  : Sample(1),
      packetMilli : Sample(4),
      message     : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.packetSize
        \o message.seqNum
        \o message.packetFlag
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.packetMilli
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetSize == ReadBytes(bytes, 2) IN IF ~packetSize.ok THEN Fail ELSE
    LET seqNum == ReadBytes(packetSize.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET packetFlag == ReadBytes(seqNum.rest, 1) IN IF ~packetFlag.ok THEN Fail ELSE
    LET messages == ReadUIntBE(packetFlag.rest, 1) IN IF ~messages.ok THEN Fail ELSE
    LET packetMilli == ReadBytes(messages.rest, 4) IN IF ~packetMilli.ok THEN Fail ELSE
    LET message == ReadMessageList(packetMilli.rest, messages.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetSize  |-> packetSize.value,
         seqNum      |-> seqNum.value,
         packetFlag  |-> packetFlag.value,
         packetMilli |-> packetMilli.value,
         message     |-> message.value ], message.rest)

ZeroPacket ==
    [ packetSize  |-> [i \in 1 .. 2 |-> 0],
      seqNum      |-> [i \in 1 .. 4 |-> 0],
      packetFlag  |-> [i \in 1 .. 1 |-> 0],
      packetMilli |-> [i \in 1 .. 4 |-> 0],
      message     |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.packetFlag = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.packetMilli = one] : one \in Sample(4) }
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

(* Every Start Of Spin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfSpinMessage ==
    \A message \in CheckedStartOfSpinMessage :
        LET read == DecodeStartOfSpinMessage(EncodeStartOfSpinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Spin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSpinMessage ==
    \A message \in CheckedEndOfSpinMessage :
        LET read == DecodeEndOfSpinMessage(EncodeEndOfSpinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOpenMessage ==
    \A message \in CheckedMarketOpenMessage :
        LET read == DecodeMarketOpenMessage(EncodeMarketOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCloseMessage ==
    \A message \in CheckedMarketCloseMessage :
        LET read == DecodeMarketCloseMessage(EncodeMarketCloseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityMessage ==
    \A message \in CheckedSecurityMessage :
        LET read == DecodeSecurityMessage(EncodeSecurityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateMessage ==
    \A message \in CheckedQuoteUpdateMessage :
        LET read == DecodeQuoteUpdateMessage(EncodeQuoteUpdateMessage(message))
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
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
