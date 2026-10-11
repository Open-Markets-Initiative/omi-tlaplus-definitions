--------------------- MODULE LinkAts_Multicast_v4_10_4 ---------------------
(***************************************************************************)
(* OTC Markets Group OTC Markets Multicast v4.10.4                         *)
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
(*                                                                         *)
(* Note: Extended Security Flags is a bit field set, checked as its 2      *)
(* bytes rather than bit by bit.                                           *)
(*                                                                         *)
(* Note: Trade Status is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
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
(* Inside Message: 56 bytes                                                *)
(***************************************************************************)

InsideMessage ==
    [ channelSeqNum  : Sample(4),
      insideId       : Sample(4),
      insideAction   : Sample(1),
      quoteFlags     : Sample(1),
      securityId     : Sample(4),
      askPrice       : Sample(8),
      askSize        : Sample(4),
      askTimeMilli   : Sample(8),
      bidPrice       : Sample(8),
      bidSize        : Sample(4),
      bidTimeMilli   : Sample(8),
      askNumPricedMp : Sample(1),
      bidNumPricedMp : Sample(1) ]

EncodeInsideMessage(message) ==
    message.channelSeqNum
        \o message.insideId
        \o message.insideAction
        \o message.quoteFlags
        \o message.securityId
        \o message.askPrice
        \o message.askSize
        \o message.askTimeMilli
        \o message.bidPrice
        \o message.bidSize
        \o message.bidTimeMilli
        \o message.askNumPricedMp
        \o message.bidNumPricedMp

DecodeInsideMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET insideId == ReadBytes(channelSeqNum.rest, 4) IN IF ~insideId.ok THEN Fail ELSE
    LET insideAction == ReadBytes(insideId.rest, 1) IN IF ~insideAction.ok THEN Fail ELSE
    LET quoteFlags == ReadBytes(insideAction.rest, 1) IN IF ~quoteFlags.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteFlags.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET askPrice == ReadBytes(securityId.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askTimeMilli == ReadBytes(askSize.rest, 8) IN IF ~askTimeMilli.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askTimeMilli.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidTimeMilli == ReadBytes(bidSize.rest, 8) IN IF ~bidTimeMilli.ok THEN Fail ELSE
    LET askNumPricedMp == ReadBytes(bidTimeMilli.rest, 1) IN IF ~askNumPricedMp.ok THEN Fail ELSE
    LET bidNumPricedMp == ReadBytes(askNumPricedMp.rest, 1) IN IF ~bidNumPricedMp.ok THEN Fail ELSE
    Ok([ channelSeqNum  |-> channelSeqNum.value,
         insideId       |-> insideId.value,
         insideAction   |-> insideAction.value,
         quoteFlags     |-> quoteFlags.value,
         securityId     |-> securityId.value,
         askPrice       |-> askPrice.value,
         askSize        |-> askSize.value,
         askTimeMilli   |-> askTimeMilli.value,
         bidPrice       |-> bidPrice.value,
         bidSize        |-> bidSize.value,
         bidTimeMilli   |-> bidTimeMilli.value,
         askNumPricedMp |-> askNumPricedMp.value,
         bidNumPricedMp |-> bidNumPricedMp.value ], bidNumPricedMp.rest)

ZeroInsideMessage ==
    [ channelSeqNum  |-> [i \in 1 .. 4 |-> 0],
      insideId       |-> [i \in 1 .. 4 |-> 0],
      insideAction   |-> [i \in 1 .. 1 |-> 0],
      quoteFlags     |-> [i \in 1 .. 1 |-> 0],
      securityId     |-> [i \in 1 .. 4 |-> 0],
      askPrice       |-> [i \in 1 .. 8 |-> 0],
      askSize        |-> [i \in 1 .. 4 |-> 0],
      askTimeMilli   |-> [i \in 1 .. 8 |-> 0],
      bidPrice       |-> [i \in 1 .. 8 |-> 0],
      bidSize        |-> [i \in 1 .. 4 |-> 0],
      bidTimeMilli   |-> [i \in 1 .. 8 |-> 0],
      askNumPricedMp |-> [i \in 1 .. 1 |-> 0],
      bidNumPricedMp |-> [i \in 1 .. 1 |-> 0] ]

(* Inside Message at zero, then each field in turn at the values it is checked at *)
CheckedInsideMessage ==
    { ZeroInsideMessage }
        \cup { [ZeroInsideMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInsideMessage EXCEPT !.insideId = one] : one \in Sample(4) }
        \cup { [ZeroInsideMessage EXCEPT !.insideAction = one] : one \in Sample(1) }
        \cup { [ZeroInsideMessage EXCEPT !.quoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroInsideMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroInsideMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroInsideMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroInsideMessage EXCEPT !.askTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroInsideMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroInsideMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroInsideMessage EXCEPT !.bidTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroInsideMessage EXCEPT !.askNumPricedMp = one] : one \in Sample(1) }
        \cup { [ZeroInsideMessage EXCEPT !.bidNumPricedMp = one] : one \in Sample(1) }

(***************************************************************************)
(* Inside Update Message: 30 bytes                                         *)
(***************************************************************************)

InsideUpdateMessage ==
    [ channelSeqNum   : Sample(4),
      insideId        : Sample(4),
      quoteFlags      : Sample(1),
      price           : Sample(8),
      size            : Sample(4),
      insideTimeMilli : Sample(8),
      numPricedMp     : Sample(1) ]

EncodeInsideUpdateMessage(message) ==
    message.channelSeqNum
        \o message.insideId
        \o message.quoteFlags
        \o message.price
        \o message.size
        \o message.insideTimeMilli
        \o message.numPricedMp

DecodeInsideUpdateMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET insideId == ReadBytes(channelSeqNum.rest, 4) IN IF ~insideId.ok THEN Fail ELSE
    LET quoteFlags == ReadBytes(insideId.rest, 1) IN IF ~quoteFlags.ok THEN Fail ELSE
    LET price == ReadBytes(quoteFlags.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET insideTimeMilli == ReadBytes(size.rest, 8) IN IF ~insideTimeMilli.ok THEN Fail ELSE
    LET numPricedMp == ReadBytes(insideTimeMilli.rest, 1) IN IF ~numPricedMp.ok THEN Fail ELSE
    Ok([ channelSeqNum   |-> channelSeqNum.value,
         insideId        |-> insideId.value,
         quoteFlags      |-> quoteFlags.value,
         price           |-> price.value,
         size            |-> size.value,
         insideTimeMilli |-> insideTimeMilli.value,
         numPricedMp     |-> numPricedMp.value ], numPricedMp.rest)

ZeroInsideUpdateMessage ==
    [ channelSeqNum   |-> [i \in 1 .. 4 |-> 0],
      insideId        |-> [i \in 1 .. 4 |-> 0],
      quoteFlags      |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      size            |-> [i \in 1 .. 4 |-> 0],
      insideTimeMilli |-> [i \in 1 .. 8 |-> 0],
      numPricedMp     |-> [i \in 1 .. 1 |-> 0] ]

(* Inside Update Message at zero, then each field in turn at the values it is checked at *)
CheckedInsideUpdateMessage ==
    { ZeroInsideUpdateMessage }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.insideId = one] : one \in Sample(4) }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.quoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.insideTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroInsideUpdateMessage EXCEPT !.numPricedMp = one] : one \in Sample(1) }

(***************************************************************************)
(* Reference Price Message: 54 bytes                                       *)
(***************************************************************************)

ReferencePriceMessage ==
    [ channelSeqNum        : Sample(4),
      referencePriceId     : Sample(4),
      referencePriceAction : Sample(1),
      quoteFlags           : Sample(1),
      securityId           : Sample(4),
      askPrice             : Sample(8),
      askSize              : Sample(4),
      askTimeMilli         : Sample(8),
      bidPrice             : Sample(8),
      bidSize              : Sample(4),
      bidTimeMilli         : Sample(8) ]

EncodeReferencePriceMessage(message) ==
    message.channelSeqNum
        \o message.referencePriceId
        \o message.referencePriceAction
        \o message.quoteFlags
        \o message.securityId
        \o message.askPrice
        \o message.askSize
        \o message.askTimeMilli
        \o message.bidPrice
        \o message.bidSize
        \o message.bidTimeMilli

DecodeReferencePriceMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET referencePriceId == ReadBytes(channelSeqNum.rest, 4) IN IF ~referencePriceId.ok THEN Fail ELSE
    LET referencePriceAction == ReadBytes(referencePriceId.rest, 1) IN IF ~referencePriceAction.ok THEN Fail ELSE
    LET quoteFlags == ReadBytes(referencePriceAction.rest, 1) IN IF ~quoteFlags.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteFlags.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET askPrice == ReadBytes(securityId.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askTimeMilli == ReadBytes(askSize.rest, 8) IN IF ~askTimeMilli.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askTimeMilli.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidTimeMilli == ReadBytes(bidSize.rest, 8) IN IF ~bidTimeMilli.ok THEN Fail ELSE
    Ok([ channelSeqNum        |-> channelSeqNum.value,
         referencePriceId     |-> referencePriceId.value,
         referencePriceAction |-> referencePriceAction.value,
         quoteFlags           |-> quoteFlags.value,
         securityId           |-> securityId.value,
         askPrice             |-> askPrice.value,
         askSize              |-> askSize.value,
         askTimeMilli         |-> askTimeMilli.value,
         bidPrice             |-> bidPrice.value,
         bidSize              |-> bidSize.value,
         bidTimeMilli         |-> bidTimeMilli.value ], bidTimeMilli.rest)

ZeroReferencePriceMessage ==
    [ channelSeqNum        |-> [i \in 1 .. 4 |-> 0],
      referencePriceId     |-> [i \in 1 .. 4 |-> 0],
      referencePriceAction |-> [i \in 1 .. 1 |-> 0],
      quoteFlags           |-> [i \in 1 .. 1 |-> 0],
      securityId           |-> [i \in 1 .. 4 |-> 0],
      askPrice             |-> [i \in 1 .. 8 |-> 0],
      askSize              |-> [i \in 1 .. 4 |-> 0],
      askTimeMilli         |-> [i \in 1 .. 8 |-> 0],
      bidPrice             |-> [i \in 1 .. 8 |-> 0],
      bidSize              |-> [i \in 1 .. 4 |-> 0],
      bidTimeMilli         |-> [i \in 1 .. 8 |-> 0] ]

(* Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceMessage ==
    { ZeroReferencePriceMessage }
        \cup { [ZeroReferencePriceMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.referencePriceId = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.referencePriceAction = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.quoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.askTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.bidTimeMilli = one] : one \in Sample(8) }

(***************************************************************************)
(* Reference Price Update Message: 29 bytes                                *)
(***************************************************************************)

ReferencePriceUpdateMessage ==
    [ channelSeqNum    : Sample(4),
      referencePriceId : Sample(4),
      quoteFlags       : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      timeMilli        : Sample(8) ]

EncodeReferencePriceUpdateMessage(message) ==
    message.channelSeqNum
        \o message.referencePriceId
        \o message.quoteFlags
        \o message.price
        \o message.size
        \o message.timeMilli

DecodeReferencePriceUpdateMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET referencePriceId == ReadBytes(channelSeqNum.rest, 4) IN IF ~referencePriceId.ok THEN Fail ELSE
    LET quoteFlags == ReadBytes(referencePriceId.rest, 1) IN IF ~quoteFlags.ok THEN Fail ELSE
    LET price == ReadBytes(quoteFlags.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET timeMilli == ReadBytes(size.rest, 8) IN IF ~timeMilli.ok THEN Fail ELSE
    Ok([ channelSeqNum    |-> channelSeqNum.value,
         referencePriceId |-> referencePriceId.value,
         quoteFlags       |-> quoteFlags.value,
         price            |-> price.value,
         size             |-> size.value,
         timeMilli        |-> timeMilli.value ], timeMilli.rest)

ZeroReferencePriceUpdateMessage ==
    [ channelSeqNum    |-> [i \in 1 .. 4 |-> 0],
      referencePriceId |-> [i \in 1 .. 4 |-> 0],
      quoteFlags       |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      timeMilli        |-> [i \in 1 .. 8 |-> 0] ]

(* Reference Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceUpdateMessage ==
    { ZeroReferencePriceUpdateMessage }
        \cup { [ZeroReferencePriceUpdateMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceUpdateMessage EXCEPT !.referencePriceId = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceUpdateMessage EXCEPT !.quoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceUpdateMessage EXCEPT !.timeMilli = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Detail                                                         *)
(***************************************************************************)

SecurityDetail ==
    [ securityDetailName : SampleBytes ]

EncodeSecurityDetail(message) ==
    EncodeUIntBE(Len(message.securityDetailName), 1)
        \o message.securityDetailName

DecodeSecurityDetail(bytes) ==
    LET securityDetailSize == ReadUIntBE(bytes, 1) IN IF ~securityDetailSize.ok THEN Fail ELSE
    LET securityDetailName == ReadBytes(securityDetailSize.rest, securityDetailSize.value) IN IF ~securityDetailName.ok THEN Fail ELSE
    Ok([ securityDetailName |-> securityDetailName.value ], securityDetailName.rest)

ZeroSecurityDetail ==
    [ securityDetailName |-> << >> ]

(* Security Detail at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDetail ==
    { ZeroSecurityDetail }
        \cup { [ZeroSecurityDetail EXCEPT !.securityDetailName = one] : one \in SampleBytes }

(***************************************************************************)
(* Issuer                                                                  *)
(***************************************************************************)

Issuer ==
    [ issuerName : SampleBytes ]

EncodeIssuer(message) ==
    EncodeUIntBE(Len(message.issuerName), 1)
        \o message.issuerName

DecodeIssuer(bytes) ==
    LET issuerSize == ReadUIntBE(bytes, 1) IN IF ~issuerSize.ok THEN Fail ELSE
    LET issuerName == ReadBytes(issuerSize.rest, issuerSize.value) IN IF ~issuerName.ok THEN Fail ELSE
    Ok([ issuerName |-> issuerName.value ], issuerName.rest)

ZeroIssuer ==
    [ issuerName |-> << >> ]

(* Issuer at zero, then each field in turn at the values it is checked at *)
CheckedIssuer ==
    { ZeroIssuer }
        \cup { [ZeroIssuer EXCEPT !.issuerName = one] : one \in SampleBytes }

(***************************************************************************)
(* Extended Security Message                                               *)
(***************************************************************************)

ExtendedSecurityMessage ==
    [ channelSeqNum         : Sample(4),
      symbol                : Sample(10),
      lastUpdateMilli       : Sample(8),
      securityAction        : Sample(1),
      otcIssuerId           : Sample(4),
      securityDesc          : Sample(25),
      shortName             : Sample(25),
      assetClass            : Sample(1),
      securityType          : Sample(5),
      primaryMarket         : Sample(3),
      securityId            : Sample(4),
      extendedSecurityFlags : Sample(2),
      tier                  : Sample(1),
      reportingStatus       : Sample(1),
      disclosureStatus      : Sample(1),
      securityStatus        : Sample(1),
      parValue              : Sample(8),
      coupon                : Sample(8),
      maturityDateMilli     : Sample(8),
      callableDateMilli     : Sample(8),
      adrRatio              : Sample(8),
      adrLevel              : Sample(15),
      securityDetail        : SecurityDetail,
      issuer                : Issuer,
      cusip                 : Sample(9) ]

EncodeExtendedSecurityMessage(message) ==
    message.channelSeqNum
        \o message.symbol
        \o message.lastUpdateMilli
        \o message.securityAction
        \o message.otcIssuerId
        \o message.securityDesc
        \o message.shortName
        \o message.assetClass
        \o message.securityType
        \o message.primaryMarket
        \o message.securityId
        \o message.extendedSecurityFlags
        \o message.tier
        \o message.reportingStatus
        \o message.disclosureStatus
        \o message.securityStatus
        \o message.parValue
        \o message.coupon
        \o message.maturityDateMilli
        \o message.callableDateMilli
        \o message.adrRatio
        \o message.adrLevel
        \o EncodeSecurityDetail(message.securityDetail)
        \o EncodeIssuer(message.issuer)
        \o message.cusip

DecodeExtendedSecurityMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET symbol == ReadBytes(channelSeqNum.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET lastUpdateMilli == ReadBytes(symbol.rest, 8) IN IF ~lastUpdateMilli.ok THEN Fail ELSE
    LET securityAction == ReadBytes(lastUpdateMilli.rest, 1) IN IF ~securityAction.ok THEN Fail ELSE
    LET otcIssuerId == ReadBytes(securityAction.rest, 4) IN IF ~otcIssuerId.ok THEN Fail ELSE
    LET securityDesc == ReadBytes(otcIssuerId.rest, 25) IN IF ~securityDesc.ok THEN Fail ELSE
    LET shortName == ReadBytes(securityDesc.rest, 25) IN IF ~shortName.ok THEN Fail ELSE
    LET assetClass == ReadBytes(shortName.rest, 1) IN IF ~assetClass.ok THEN Fail ELSE
    LET securityType == ReadBytes(assetClass.rest, 5) IN IF ~securityType.ok THEN Fail ELSE
    LET primaryMarket == ReadBytes(securityType.rest, 3) IN IF ~primaryMarket.ok THEN Fail ELSE
    LET securityId == ReadBytes(primaryMarket.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET extendedSecurityFlags == ReadBytes(securityId.rest, 2) IN IF ~extendedSecurityFlags.ok THEN Fail ELSE
    LET tier == ReadBytes(extendedSecurityFlags.rest, 1) IN IF ~tier.ok THEN Fail ELSE
    LET reportingStatus == ReadBytes(tier.rest, 1) IN IF ~reportingStatus.ok THEN Fail ELSE
    LET disclosureStatus == ReadBytes(reportingStatus.rest, 1) IN IF ~disclosureStatus.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(disclosureStatus.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET parValue == ReadBytes(securityStatus.rest, 8) IN IF ~parValue.ok THEN Fail ELSE
    LET coupon == ReadBytes(parValue.rest, 8) IN IF ~coupon.ok THEN Fail ELSE
    LET maturityDateMilli == ReadBytes(coupon.rest, 8) IN IF ~maturityDateMilli.ok THEN Fail ELSE
    LET callableDateMilli == ReadBytes(maturityDateMilli.rest, 8) IN IF ~callableDateMilli.ok THEN Fail ELSE
    LET adrRatio == ReadBytes(callableDateMilli.rest, 8) IN IF ~adrRatio.ok THEN Fail ELSE
    LET adrLevel == ReadBytes(adrRatio.rest, 15) IN IF ~adrLevel.ok THEN Fail ELSE
    LET securityDetail == DecodeSecurityDetail(adrLevel.rest) IN IF ~securityDetail.ok THEN Fail ELSE
    LET issuer == DecodeIssuer(securityDetail.rest) IN IF ~issuer.ok THEN Fail ELSE
    LET cusip == ReadBytes(issuer.rest, 9) IN IF ~cusip.ok THEN Fail ELSE
    Ok([ channelSeqNum         |-> channelSeqNum.value,
         symbol                |-> symbol.value,
         lastUpdateMilli       |-> lastUpdateMilli.value,
         securityAction        |-> securityAction.value,
         otcIssuerId           |-> otcIssuerId.value,
         securityDesc          |-> securityDesc.value,
         shortName             |-> shortName.value,
         assetClass            |-> assetClass.value,
         securityType          |-> securityType.value,
         primaryMarket         |-> primaryMarket.value,
         securityId            |-> securityId.value,
         extendedSecurityFlags |-> extendedSecurityFlags.value,
         tier                  |-> tier.value,
         reportingStatus       |-> reportingStatus.value,
         disclosureStatus      |-> disclosureStatus.value,
         securityStatus        |-> securityStatus.value,
         parValue              |-> parValue.value,
         coupon                |-> coupon.value,
         maturityDateMilli     |-> maturityDateMilli.value,
         callableDateMilli     |-> callableDateMilli.value,
         adrRatio              |-> adrRatio.value,
         adrLevel              |-> adrLevel.value,
         securityDetail        |-> securityDetail.value,
         issuer                |-> issuer.value,
         cusip                 |-> cusip.value ], cusip.rest)

ZeroExtendedSecurityMessage ==
    [ channelSeqNum         |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 10 |-> 0],
      lastUpdateMilli       |-> [i \in 1 .. 8 |-> 0],
      securityAction        |-> [i \in 1 .. 1 |-> 0],
      otcIssuerId           |-> [i \in 1 .. 4 |-> 0],
      securityDesc          |-> [i \in 1 .. 25 |-> 0],
      shortName             |-> [i \in 1 .. 25 |-> 0],
      assetClass            |-> [i \in 1 .. 1 |-> 0],
      securityType          |-> [i \in 1 .. 5 |-> 0],
      primaryMarket         |-> [i \in 1 .. 3 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      extendedSecurityFlags |-> [i \in 1 .. 2 |-> 0],
      tier                  |-> [i \in 1 .. 1 |-> 0],
      reportingStatus       |-> [i \in 1 .. 1 |-> 0],
      disclosureStatus      |-> [i \in 1 .. 1 |-> 0],
      securityStatus        |-> [i \in 1 .. 1 |-> 0],
      parValue              |-> [i \in 1 .. 8 |-> 0],
      coupon                |-> [i \in 1 .. 8 |-> 0],
      maturityDateMilli     |-> [i \in 1 .. 8 |-> 0],
      callableDateMilli     |-> [i \in 1 .. 8 |-> 0],
      adrRatio              |-> [i \in 1 .. 8 |-> 0],
      adrLevel              |-> [i \in 1 .. 15 |-> 0],
      securityDetail        |-> ZeroSecurityDetail,
      issuer                |-> ZeroIssuer,
      cusip                 |-> [i \in 1 .. 9 |-> 0] ]

(* Extended Security Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedSecurityMessage ==
    { ZeroExtendedSecurityMessage }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.lastUpdateMilli = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.securityAction = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.otcIssuerId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.securityDesc = one] : one \in Sample(25) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.shortName = one] : one \in Sample(25) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.assetClass = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.securityType = one] : one \in Sample(5) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.primaryMarket = one] : one \in Sample(3) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.extendedSecurityFlags = one] : one \in Sample(2) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.tier = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.reportingStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.disclosureStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.parValue = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.coupon = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.maturityDateMilli = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.callableDateMilli = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.adrRatio = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.adrLevel = one] : one \in Sample(15) }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.securityDetail = one] : one \in CheckedSecurityDetail }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.issuer = one] : one \in CheckedIssuer }
        \cup { [ZeroExtendedSecurityMessage EXCEPT !.cusip = one] : one \in Sample(9) }

(***************************************************************************)
(* Security Detail                                                         *)
(***************************************************************************)

SecurityDetail2 ==
    [ securityDetailName : SampleBytes ]

EncodeSecurityDetail2(message) ==
    EncodeUIntBE(Len(message.securityDetailName), 1)
        \o message.securityDetailName

DecodeSecurityDetail2(bytes) ==
    LET securityDetailSize == ReadUIntBE(bytes, 1) IN IF ~securityDetailSize.ok THEN Fail ELSE
    LET securityDetailName == ReadBytes(securityDetailSize.rest, securityDetailSize.value) IN IF ~securityDetailName.ok THEN Fail ELSE
    Ok([ securityDetailName |-> securityDetailName.value ], securityDetailName.rest)

ZeroSecurityDetail2 ==
    [ securityDetailName |-> << >> ]

(* Security Detail at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDetail2 ==
    { ZeroSecurityDetail2 }
        \cup { [ZeroSecurityDetail2 EXCEPT !.securityDetailName = one] : one \in SampleBytes }

(***************************************************************************)
(* Issuer                                                                  *)
(***************************************************************************)

Issuer2 ==
    [ issuerName : SampleBytes ]

EncodeIssuer2(message) ==
    EncodeUIntBE(Len(message.issuerName), 1)
        \o message.issuerName

DecodeIssuer2(bytes) ==
    LET issuerSize == ReadUIntBE(bytes, 1) IN IF ~issuerSize.ok THEN Fail ELSE
    LET issuerName == ReadBytes(issuerSize.rest, issuerSize.value) IN IF ~issuerName.ok THEN Fail ELSE
    Ok([ issuerName |-> issuerName.value ], issuerName.rest)

ZeroIssuer2 ==
    [ issuerName |-> << >> ]

(* Issuer at zero, then each field in turn at the values it is checked at *)
CheckedIssuer2 ==
    { ZeroIssuer2 }
        \cup { [ZeroIssuer2 EXCEPT !.issuerName = one] : one \in SampleBytes }

(***************************************************************************)
(* Extended Security No Cusip Message                                      *)
(***************************************************************************)

ExtendedSecurityNoCusipMessage ==
    [ channelSeqNum         : Sample(4),
      symbol                : Sample(10),
      lastUpdateMilli       : Sample(8),
      securityAction        : Sample(1),
      otcIssuerId           : Sample(4),
      securityDesc          : Sample(25),
      shortName             : Sample(25),
      assetClass            : Sample(1),
      securityType          : Sample(5),
      primaryMarket         : Sample(3),
      securityId            : Sample(4),
      extendedSecurityFlags : Sample(2),
      tier                  : Sample(1),
      reportingStatus       : Sample(1),
      disclosureStatus      : Sample(1),
      securityStatus        : Sample(1),
      parValue              : Sample(8),
      coupon                : Sample(8),
      maturityDateMilli     : Sample(8),
      callableDateMilli     : Sample(8),
      adrRatio              : Sample(8),
      adrLevel              : Sample(15),
      securityDetail        : SecurityDetail2,
      issuer                : Issuer2 ]

EncodeExtendedSecurityNoCusipMessage(message) ==
    message.channelSeqNum
        \o message.symbol
        \o message.lastUpdateMilli
        \o message.securityAction
        \o message.otcIssuerId
        \o message.securityDesc
        \o message.shortName
        \o message.assetClass
        \o message.securityType
        \o message.primaryMarket
        \o message.securityId
        \o message.extendedSecurityFlags
        \o message.tier
        \o message.reportingStatus
        \o message.disclosureStatus
        \o message.securityStatus
        \o message.parValue
        \o message.coupon
        \o message.maturityDateMilli
        \o message.callableDateMilli
        \o message.adrRatio
        \o message.adrLevel
        \o EncodeSecurityDetail2(message.securityDetail)
        \o EncodeIssuer2(message.issuer)

DecodeExtendedSecurityNoCusipMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET symbol == ReadBytes(channelSeqNum.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET lastUpdateMilli == ReadBytes(symbol.rest, 8) IN IF ~lastUpdateMilli.ok THEN Fail ELSE
    LET securityAction == ReadBytes(lastUpdateMilli.rest, 1) IN IF ~securityAction.ok THEN Fail ELSE
    LET otcIssuerId == ReadBytes(securityAction.rest, 4) IN IF ~otcIssuerId.ok THEN Fail ELSE
    LET securityDesc == ReadBytes(otcIssuerId.rest, 25) IN IF ~securityDesc.ok THEN Fail ELSE
    LET shortName == ReadBytes(securityDesc.rest, 25) IN IF ~shortName.ok THEN Fail ELSE
    LET assetClass == ReadBytes(shortName.rest, 1) IN IF ~assetClass.ok THEN Fail ELSE
    LET securityType == ReadBytes(assetClass.rest, 5) IN IF ~securityType.ok THEN Fail ELSE
    LET primaryMarket == ReadBytes(securityType.rest, 3) IN IF ~primaryMarket.ok THEN Fail ELSE
    LET securityId == ReadBytes(primaryMarket.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET extendedSecurityFlags == ReadBytes(securityId.rest, 2) IN IF ~extendedSecurityFlags.ok THEN Fail ELSE
    LET tier == ReadBytes(extendedSecurityFlags.rest, 1) IN IF ~tier.ok THEN Fail ELSE
    LET reportingStatus == ReadBytes(tier.rest, 1) IN IF ~reportingStatus.ok THEN Fail ELSE
    LET disclosureStatus == ReadBytes(reportingStatus.rest, 1) IN IF ~disclosureStatus.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(disclosureStatus.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET parValue == ReadBytes(securityStatus.rest, 8) IN IF ~parValue.ok THEN Fail ELSE
    LET coupon == ReadBytes(parValue.rest, 8) IN IF ~coupon.ok THEN Fail ELSE
    LET maturityDateMilli == ReadBytes(coupon.rest, 8) IN IF ~maturityDateMilli.ok THEN Fail ELSE
    LET callableDateMilli == ReadBytes(maturityDateMilli.rest, 8) IN IF ~callableDateMilli.ok THEN Fail ELSE
    LET adrRatio == ReadBytes(callableDateMilli.rest, 8) IN IF ~adrRatio.ok THEN Fail ELSE
    LET adrLevel == ReadBytes(adrRatio.rest, 15) IN IF ~adrLevel.ok THEN Fail ELSE
    LET securityDetail == DecodeSecurityDetail2(adrLevel.rest) IN IF ~securityDetail.ok THEN Fail ELSE
    LET issuer == DecodeIssuer2(securityDetail.rest) IN IF ~issuer.ok THEN Fail ELSE
    Ok([ channelSeqNum         |-> channelSeqNum.value,
         symbol                |-> symbol.value,
         lastUpdateMilli       |-> lastUpdateMilli.value,
         securityAction        |-> securityAction.value,
         otcIssuerId           |-> otcIssuerId.value,
         securityDesc          |-> securityDesc.value,
         shortName             |-> shortName.value,
         assetClass            |-> assetClass.value,
         securityType          |-> securityType.value,
         primaryMarket         |-> primaryMarket.value,
         securityId            |-> securityId.value,
         extendedSecurityFlags |-> extendedSecurityFlags.value,
         tier                  |-> tier.value,
         reportingStatus       |-> reportingStatus.value,
         disclosureStatus      |-> disclosureStatus.value,
         securityStatus        |-> securityStatus.value,
         parValue              |-> parValue.value,
         coupon                |-> coupon.value,
         maturityDateMilli     |-> maturityDateMilli.value,
         callableDateMilli     |-> callableDateMilli.value,
         adrRatio              |-> adrRatio.value,
         adrLevel              |-> adrLevel.value,
         securityDetail        |-> securityDetail.value,
         issuer                |-> issuer.value ], issuer.rest)

ZeroExtendedSecurityNoCusipMessage ==
    [ channelSeqNum         |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 10 |-> 0],
      lastUpdateMilli       |-> [i \in 1 .. 8 |-> 0],
      securityAction        |-> [i \in 1 .. 1 |-> 0],
      otcIssuerId           |-> [i \in 1 .. 4 |-> 0],
      securityDesc          |-> [i \in 1 .. 25 |-> 0],
      shortName             |-> [i \in 1 .. 25 |-> 0],
      assetClass            |-> [i \in 1 .. 1 |-> 0],
      securityType          |-> [i \in 1 .. 5 |-> 0],
      primaryMarket         |-> [i \in 1 .. 3 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      extendedSecurityFlags |-> [i \in 1 .. 2 |-> 0],
      tier                  |-> [i \in 1 .. 1 |-> 0],
      reportingStatus       |-> [i \in 1 .. 1 |-> 0],
      disclosureStatus      |-> [i \in 1 .. 1 |-> 0],
      securityStatus        |-> [i \in 1 .. 1 |-> 0],
      parValue              |-> [i \in 1 .. 8 |-> 0],
      coupon                |-> [i \in 1 .. 8 |-> 0],
      maturityDateMilli     |-> [i \in 1 .. 8 |-> 0],
      callableDateMilli     |-> [i \in 1 .. 8 |-> 0],
      adrRatio              |-> [i \in 1 .. 8 |-> 0],
      adrLevel              |-> [i \in 1 .. 15 |-> 0],
      securityDetail        |-> ZeroSecurityDetail2,
      issuer                |-> ZeroIssuer2 ]

(* Extended Security No Cusip Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedSecurityNoCusipMessage ==
    { ZeroExtendedSecurityNoCusipMessage }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.lastUpdateMilli = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.securityAction = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.otcIssuerId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.securityDesc = one] : one \in Sample(25) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.shortName = one] : one \in Sample(25) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.assetClass = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.securityType = one] : one \in Sample(5) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.primaryMarket = one] : one \in Sample(3) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.extendedSecurityFlags = one] : one \in Sample(2) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.tier = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.reportingStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.disclosureStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.parValue = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.coupon = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.maturityDateMilli = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.callableDateMilli = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.adrRatio = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.adrLevel = one] : one \in Sample(15) }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.securityDetail = one] : one \in CheckedSecurityDetail2 }
        \cup { [ZeroExtendedSecurityNoCusipMessage EXCEPT !.issuer = one] : one \in CheckedIssuer2 }

(***************************************************************************)
(* Trade Message: 43 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ channelSeqNum             : Sample(4),
      tradeIdUnsignedInteger4   : Sample(4),
      tradeAction               : Sample(1),
      tradeFlags                : Sample(1),
      securityId                : Sample(4),
      tradeStatus               : Sample(1),
      venue                     : Sample(3),
      deprecatedUtf85           : Sample(5),
      tradePrice                : Sample(8),
      tradeSizeUnsignedInteger4 : Sample(4),
      tradeTimeMilli            : Sample(8) ]

EncodeTradeMessage(message) ==
    message.channelSeqNum
        \o message.tradeIdUnsignedInteger4
        \o message.tradeAction
        \o message.tradeFlags
        \o message.securityId
        \o message.tradeStatus
        \o message.venue
        \o message.deprecatedUtf85
        \o message.tradePrice
        \o message.tradeSizeUnsignedInteger4
        \o message.tradeTimeMilli

DecodeTradeMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET tradeIdUnsignedInteger4 == ReadBytes(channelSeqNum.rest, 4) IN IF ~tradeIdUnsignedInteger4.ok THEN Fail ELSE
    LET tradeAction == ReadBytes(tradeIdUnsignedInteger4.rest, 1) IN IF ~tradeAction.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(tradeAction.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET securityId == ReadBytes(tradeFlags.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(securityId.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET venue == ReadBytes(tradeStatus.rest, 3) IN IF ~venue.ok THEN Fail ELSE
    LET deprecatedUtf85 == ReadBytes(venue.rest, 5) IN IF ~deprecatedUtf85.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(deprecatedUtf85.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSizeUnsignedInteger4 == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSizeUnsignedInteger4.ok THEN Fail ELSE
    LET tradeTimeMilli == ReadBytes(tradeSizeUnsignedInteger4.rest, 8) IN IF ~tradeTimeMilli.ok THEN Fail ELSE
    Ok([ channelSeqNum             |-> channelSeqNum.value,
         tradeIdUnsignedInteger4   |-> tradeIdUnsignedInteger4.value,
         tradeAction               |-> tradeAction.value,
         tradeFlags                |-> tradeFlags.value,
         securityId                |-> securityId.value,
         tradeStatus               |-> tradeStatus.value,
         venue                     |-> venue.value,
         deprecatedUtf85           |-> deprecatedUtf85.value,
         tradePrice                |-> tradePrice.value,
         tradeSizeUnsignedInteger4 |-> tradeSizeUnsignedInteger4.value,
         tradeTimeMilli            |-> tradeTimeMilli.value ], tradeTimeMilli.rest)

ZeroTradeMessage ==
    [ channelSeqNum             |-> [i \in 1 .. 4 |-> 0],
      tradeIdUnsignedInteger4   |-> [i \in 1 .. 4 |-> 0],
      tradeAction               |-> [i \in 1 .. 1 |-> 0],
      tradeFlags                |-> [i \in 1 .. 1 |-> 0],
      securityId                |-> [i \in 1 .. 4 |-> 0],
      tradeStatus               |-> [i \in 1 .. 1 |-> 0],
      venue                     |-> [i \in 1 .. 3 |-> 0],
      deprecatedUtf85           |-> [i \in 1 .. 5 |-> 0],
      tradePrice                |-> [i \in 1 .. 8 |-> 0],
      tradeSizeUnsignedInteger4 |-> [i \in 1 .. 4 |-> 0],
      tradeTimeMilli            |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeIdUnsignedInteger4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.venue = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.deprecatedUtf85 = one] : one \in Sample(5) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeSizeUnsignedInteger4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeTimeMilli = one] : one \in Sample(8) }

(***************************************************************************)
(* Extended Trade Message: 51 bytes                                        *)
(***************************************************************************)

ExtendedTradeMessage ==
    [ channelSeqNum             : Sample(4),
      tradeIdUnsignedInteger8   : Sample(8),
      tradeAction               : Sample(1),
      tradeFlags                : Sample(1),
      securityId                : Sample(4),
      tradeStatus               : Sample(1),
      venue                     : Sample(3),
      deprecatedUtf85           : Sample(5),
      tradePrice                : Sample(8),
      tradeSizeUnsignedInteger8 : Sample(8),
      tradeTimeMilli            : Sample(8) ]

EncodeExtendedTradeMessage(message) ==
    message.channelSeqNum
        \o message.tradeIdUnsignedInteger8
        \o message.tradeAction
        \o message.tradeFlags
        \o message.securityId
        \o message.tradeStatus
        \o message.venue
        \o message.deprecatedUtf85
        \o message.tradePrice
        \o message.tradeSizeUnsignedInteger8
        \o message.tradeTimeMilli

DecodeExtendedTradeMessage(bytes) ==
    LET channelSeqNum == ReadBytes(bytes, 4) IN IF ~channelSeqNum.ok THEN Fail ELSE
    LET tradeIdUnsignedInteger8 == ReadBytes(channelSeqNum.rest, 8) IN IF ~tradeIdUnsignedInteger8.ok THEN Fail ELSE
    LET tradeAction == ReadBytes(tradeIdUnsignedInteger8.rest, 1) IN IF ~tradeAction.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(tradeAction.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET securityId == ReadBytes(tradeFlags.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(securityId.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET venue == ReadBytes(tradeStatus.rest, 3) IN IF ~venue.ok THEN Fail ELSE
    LET deprecatedUtf85 == ReadBytes(venue.rest, 5) IN IF ~deprecatedUtf85.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(deprecatedUtf85.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSizeUnsignedInteger8 == ReadBytes(tradePrice.rest, 8) IN IF ~tradeSizeUnsignedInteger8.ok THEN Fail ELSE
    LET tradeTimeMilli == ReadBytes(tradeSizeUnsignedInteger8.rest, 8) IN IF ~tradeTimeMilli.ok THEN Fail ELSE
    Ok([ channelSeqNum             |-> channelSeqNum.value,
         tradeIdUnsignedInteger8   |-> tradeIdUnsignedInteger8.value,
         tradeAction               |-> tradeAction.value,
         tradeFlags                |-> tradeFlags.value,
         securityId                |-> securityId.value,
         tradeStatus               |-> tradeStatus.value,
         venue                     |-> venue.value,
         deprecatedUtf85           |-> deprecatedUtf85.value,
         tradePrice                |-> tradePrice.value,
         tradeSizeUnsignedInteger8 |-> tradeSizeUnsignedInteger8.value,
         tradeTimeMilli            |-> tradeTimeMilli.value ], tradeTimeMilli.rest)

ZeroExtendedTradeMessage ==
    [ channelSeqNum             |-> [i \in 1 .. 4 |-> 0],
      tradeIdUnsignedInteger8   |-> [i \in 1 .. 8 |-> 0],
      tradeAction               |-> [i \in 1 .. 1 |-> 0],
      tradeFlags                |-> [i \in 1 .. 1 |-> 0],
      securityId                |-> [i \in 1 .. 4 |-> 0],
      tradeStatus               |-> [i \in 1 .. 1 |-> 0],
      venue                     |-> [i \in 1 .. 3 |-> 0],
      deprecatedUtf85           |-> [i \in 1 .. 5 |-> 0],
      tradePrice                |-> [i \in 1 .. 8 |-> 0],
      tradeSizeUnsignedInteger8 |-> [i \in 1 .. 8 |-> 0],
      tradeTimeMilli            |-> [i \in 1 .. 8 |-> 0] ]

(* Extended Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedTradeMessage ==
    { ZeroExtendedTradeMessage }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.channelSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradeIdUnsignedInteger8 = one] : one \in Sample(8) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradeAction = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.venue = one] : one \in Sample(3) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.deprecatedUtf85 = one] : one \in Sample(5) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradeSizeUnsignedInteger8 = one] : one \in Sample(8) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.tradeTimeMilli = one] : one \in Sample(8) }

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
InsideMessageCode == 3  \* 0x03
InsideUpdateMessageCode == 4  \* 0x04
ReferencePriceMessageCode == 7  \* 0x07
ReferencePriceUpdateMessageCode == 8  \* 0x08
ExtendedSecurityMessageCode == 15  \* 0x0f
ExtendedSecurityNoCusipMessageCode == 16  \* 0x10
TradeMessageCode == 17  \* 0x11
ExtendedTradeMessageCode == 18  \* 0x12

Payload ==
    [ tag : {StartOfSpinMessageCode}, body : StartOfSpinMessage ]
        \cup [ tag : {EndOfSpinMessageCode}, body : EndOfSpinMessage ]
        \cup [ tag : {MarketOpenMessageCode}, body : MarketOpenMessage ]
        \cup [ tag : {MarketCloseMessageCode}, body : MarketCloseMessage ]
        \cup [ tag : {SecurityMessageCode}, body : SecurityMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {QuoteUpdateMessageCode}, body : QuoteUpdateMessage ]
        \cup [ tag : {InsideMessageCode}, body : InsideMessage ]
        \cup [ tag : {InsideUpdateMessageCode}, body : InsideUpdateMessage ]
        \cup [ tag : {ReferencePriceMessageCode}, body : ReferencePriceMessage ]
        \cup [ tag : {ReferencePriceUpdateMessageCode}, body : ReferencePriceUpdateMessage ]
        \cup [ tag : {ExtendedSecurityMessageCode}, body : ExtendedSecurityMessage ]
        \cup [ tag : {ExtendedSecurityNoCusipMessageCode}, body : ExtendedSecurityNoCusipMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {ExtendedTradeMessageCode}, body : ExtendedTradeMessage ]

EncodePayload(message) ==
    CASE message.tag = StartOfSpinMessageCode -> EncodeStartOfSpinMessage(message.body)
      [] message.tag = EndOfSpinMessageCode -> EncodeEndOfSpinMessage(message.body)
      [] message.tag = MarketOpenMessageCode -> EncodeMarketOpenMessage(message.body)
      [] message.tag = MarketCloseMessageCode -> EncodeMarketCloseMessage(message.body)
      [] message.tag = SecurityMessageCode -> EncodeSecurityMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = QuoteUpdateMessageCode -> EncodeQuoteUpdateMessage(message.body)
      [] message.tag = InsideMessageCode -> EncodeInsideMessage(message.body)
      [] message.tag = InsideUpdateMessageCode -> EncodeInsideUpdateMessage(message.body)
      [] message.tag = ReferencePriceMessageCode -> EncodeReferencePriceMessage(message.body)
      [] message.tag = ReferencePriceUpdateMessageCode -> EncodeReferencePriceUpdateMessage(message.body)
      [] message.tag = ExtendedSecurityMessageCode -> EncodeExtendedSecurityMessage(message.body)
      [] message.tag = ExtendedSecurityNoCusipMessageCode -> EncodeExtendedSecurityNoCusipMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = ExtendedTradeMessageCode -> EncodeExtendedTradeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfSpinMessageCode -> DecodeStartOfSpinMessage(bytes)
              [] tag = EndOfSpinMessageCode -> DecodeEndOfSpinMessage(bytes)
              [] tag = MarketOpenMessageCode -> DecodeMarketOpenMessage(bytes)
              [] tag = MarketCloseMessageCode -> DecodeMarketCloseMessage(bytes)
              [] tag = SecurityMessageCode -> DecodeSecurityMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = QuoteUpdateMessageCode -> DecodeQuoteUpdateMessage(bytes)
              [] tag = InsideMessageCode -> DecodeInsideMessage(bytes)
              [] tag = InsideUpdateMessageCode -> DecodeInsideUpdateMessage(bytes)
              [] tag = ReferencePriceMessageCode -> DecodeReferencePriceMessage(bytes)
              [] tag = ReferencePriceUpdateMessageCode -> DecodeReferencePriceUpdateMessage(bytes)
              [] tag = ExtendedSecurityMessageCode -> DecodeExtendedSecurityMessage(bytes)
              [] tag = ExtendedSecurityNoCusipMessageCode -> DecodeExtendedSecurityNoCusipMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = ExtendedTradeMessageCode -> DecodeExtendedTradeMessage(bytes)
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
        \cup { [tag |-> InsideMessageCode, body |-> one] : one \in CheckedInsideMessage }
        \cup { [tag |-> InsideUpdateMessageCode, body |-> one] : one \in CheckedInsideUpdateMessage }
        \cup { [tag |-> ReferencePriceMessageCode, body |-> one] : one \in CheckedReferencePriceMessage }
        \cup { [tag |-> ReferencePriceUpdateMessageCode, body |-> one] : one \in CheckedReferencePriceUpdateMessage }
        \cup { [tag |-> ExtendedSecurityMessageCode, body |-> one] : one \in CheckedExtendedSecurityMessage }
        \cup { [tag |-> ExtendedSecurityNoCusipMessageCode, body |-> one] : one \in CheckedExtendedSecurityNoCusipMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> ExtendedTradeMessageCode, body |-> one] : one \in CheckedExtendedTradeMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteUpdateMessageCode, body |-> ZeroQuoteUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InsideMessageCode, body |-> ZeroInsideMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InsideUpdateMessageCode, body |-> ZeroInsideUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReferencePriceMessageCode, body |-> ZeroReferencePriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReferencePriceUpdateMessageCode, body |-> ZeroReferencePriceUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedSecurityMessageCode, body |-> ZeroExtendedSecurityMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedSecurityNoCusipMessageCode, body |-> ZeroExtendedSecurityNoCusipMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedTradeMessageCode, body |-> ZeroExtendedTradeMessage]] }

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

(* Every Inside Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInsideMessage ==
    \A message \in CheckedInsideMessage :
        LET read == DecodeInsideMessage(EncodeInsideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inside Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInsideUpdateMessage ==
    \A message \in CheckedInsideUpdateMessage :
        LET read == DecodeInsideUpdateMessage(EncodeInsideUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceMessage ==
    \A message \in CheckedReferencePriceMessage :
        LET read == DecodeReferencePriceMessage(EncodeReferencePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceUpdateMessage ==
    \A message \in CheckedReferencePriceUpdateMessage :
        LET read == DecodeReferencePriceUpdateMessage(EncodeReferencePriceUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Detail decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDetail ==
    \A message \in CheckedSecurityDetail :
        LET read == DecodeSecurityDetail(EncodeSecurityDetail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issuer decodes back to what was encoded, and leaves nothing over *)
RoundTripIssuer ==
    \A message \in CheckedIssuer :
        LET read == DecodeIssuer(EncodeIssuer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Security Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedSecurityMessage ==
    \A message \in CheckedExtendedSecurityMessage :
        LET read == DecodeExtendedSecurityMessage(EncodeExtendedSecurityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Detail decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDetail2 ==
    \A message \in CheckedSecurityDetail2 :
        LET read == DecodeSecurityDetail2(EncodeSecurityDetail2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issuer decodes back to what was encoded, and leaves nothing over *)
RoundTripIssuer2 ==
    \A message \in CheckedIssuer2 :
        LET read == DecodeIssuer2(EncodeIssuer2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Security No Cusip Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedSecurityNoCusipMessage ==
    \A message \in CheckedExtendedSecurityNoCusipMessage :
        LET read == DecodeExtendedSecurityNoCusipMessage(EncodeExtendedSecurityNoCusipMessage(message))
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

(* Every Extended Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedTradeMessage ==
    \A message \in CheckedExtendedTradeMessage :
        LET read == DecodeExtendedTradeMessage(EncodeExtendedTradeMessage(message))
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
