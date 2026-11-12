------------ MODULE Koscom_MdcsRealtime_NightDerivatives_v2_018 ------------
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Night Derivatives v2.018                 *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Packet fills its datagram with as many messages as the bytes      *)
(* hold, so it is read as a run of them.                                   *)
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
(* Polling Data Message: 5 bytes                                           *)
(***************************************************************************)

PollingDataMessage ==
    [ currentTime1MinuteInterval : Sample(4),
      endKeyword                 : Sample(1) ]

EncodePollingDataMessage(message) ==
    message.currentTime1MinuteInterval
        \o message.endKeyword

DecodePollingDataMessage(bytes) ==
    LET currentTime1MinuteInterval == ReadBytes(bytes, 4) IN IF ~currentTime1MinuteInterval.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(currentTime1MinuteInterval.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ currentTime1MinuteInterval |-> currentTime1MinuteInterval.value,
         endKeyword                 |-> endKeyword.value ], endKeyword.rest)

ZeroPollingDataMessage ==
    [ currentTime1MinuteInterval |-> [i \in 1 .. 4 |-> 0],
      endKeyword                 |-> [i \in 1 .. 1 |-> 0] ]

(* Polling Data Message at zero, then each field in turn at the values it is checked at *)
CheckedPollingDataMessage ==
    { ZeroPollingDataMessage }
        \cup { [ZeroPollingDataMessage EXCEPT !.currentTime1MinuteInterval = one] : one \in Sample(4) }
        \cup { [ZeroPollingDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Quote Five Levels Message: 319 bytes                        *)
(***************************************************************************)

DerivativesQuoteFiveLevelsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      askLevel1Price                : Sample(9),
      bidLevel1Price                : Sample(9),
      askLevel1Volume               : Sample(9),
      bidLevel1Volume               : Sample(9),
      askLevel1OrderCounts          : Sample(5),
      bidLevel1OrderCounts          : Sample(5),
      askLevel2Price                : Sample(9),
      bidLevel2Price                : Sample(9),
      askLevel2Volume               : Sample(9),
      bidLevel2Volume               : Sample(9),
      askLevel2OrderCounts          : Sample(5),
      bidLevel2OrderCounts          : Sample(5),
      askLevel3Price                : Sample(9),
      bidLevel3Price                : Sample(9),
      askLevel3Volume               : Sample(9),
      bidLevel3Volume               : Sample(9),
      askLevel3OrderCounts          : Sample(5),
      bidLevel3OrderCounts          : Sample(5),
      askLevel4Price                : Sample(9),
      bidLevel4Price                : Sample(9),
      askLevel4Volume               : Sample(9),
      bidLevel4Volume               : Sample(9),
      askLevel4OrderCounts          : Sample(5),
      bidLevel4OrderCounts          : Sample(5),
      askLevel5Price                : Sample(9),
      bidLevel5Price                : Sample(9),
      askLevel5Volume               : Sample(9),
      bidLevel5Volume               : Sample(9),
      askLevel5OrderCounts          : Sample(5),
      bidLevel5OrderCounts          : Sample(5),
      askTotalVolume                : Sample(9),
      bidTotalVolume                : Sample(9),
      askPriceValidCounts           : Sample(5),
      bidPriceValidCounts           : Sample(5),
      estimatedTradingPrice         : Sample(9),
      estimatedTradingVolume        : Sample(9),
      endKeyword                    : Sample(1) ]

EncodeDerivativesQuoteFiveLevelsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeDerivativesQuoteFiveLevelsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(bidPriceValidCounts.rest, 9) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 9) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel1OrderCounts          |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts          |-> bidLevel1OrderCounts.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel2OrderCounts          |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts          |-> bidLevel2OrderCounts.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel3OrderCounts          |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts          |-> bidLevel3OrderCounts.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel4OrderCounts          |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts          |-> bidLevel4OrderCounts.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         askLevel5OrderCounts          |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts          |-> bidLevel5OrderCounts.value,
         askTotalVolume                |-> askTotalVolume.value,
         bidTotalVolume                |-> bidTotalVolume.value,
         askPriceValidCounts           |-> askPriceValidCounts.value,
         bidPriceValidCounts           |-> bidPriceValidCounts.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesQuoteFiveLevelsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 9 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 9 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Quote Five Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesQuoteFiveLevelsMessage ==
    { ZeroDerivativesQuoteFiveLevelsMessage }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteFiveLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Quote Ten Levels Message: 549 bytes                         *)
(***************************************************************************)

DerivativesQuoteTenLevelsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      askLevel1Price                : Sample(9),
      bidLevel1Price                : Sample(9),
      askLevel1Volume               : Sample(9),
      bidLevel1Volume               : Sample(9),
      askLevel1OrderCounts          : Sample(5),
      bidLevel1OrderCounts          : Sample(5),
      askLevel2Price                : Sample(9),
      bidLevel2Price                : Sample(9),
      askLevel2Volume               : Sample(9),
      bidLevel2Volume               : Sample(9),
      askLevel2OrderCounts          : Sample(5),
      bidLevel2OrderCounts          : Sample(5),
      askLevel3Price                : Sample(9),
      bidLevel3Price                : Sample(9),
      askLevel3Volume               : Sample(9),
      bidLevel3Volume               : Sample(9),
      askLevel3OrderCounts          : Sample(5),
      bidLevel3OrderCounts          : Sample(5),
      askLevel4Price                : Sample(9),
      bidLevel4Price                : Sample(9),
      askLevel4Volume               : Sample(9),
      bidLevel4Volume               : Sample(9),
      askLevel4OrderCounts          : Sample(5),
      bidLevel4OrderCounts          : Sample(5),
      askLevel5Price                : Sample(9),
      bidLevel5Price                : Sample(9),
      askLevel5Volume               : Sample(9),
      bidLevel5Volume               : Sample(9),
      askLevel5OrderCounts          : Sample(5),
      bidLevel5OrderCounts          : Sample(5),
      askLevel6Price                : Sample(9),
      bidLevel6Price                : Sample(9),
      askLevel6Volume               : Sample(9),
      bidLevel6Volume               : Sample(9),
      askLevel6OrderCounts          : Sample(5),
      bidLevel6OrderCounts          : Sample(5),
      askLevel7Price                : Sample(9),
      bidLevel7Price                : Sample(9),
      askLevel7Volume               : Sample(9),
      bidLevel7Volume               : Sample(9),
      askLevel7OrderCounts          : Sample(5),
      bidLevel7OrderCounts          : Sample(5),
      askLevel8Price                : Sample(9),
      bidLevel8Price                : Sample(9),
      askLevel8Volume               : Sample(9),
      bidLevel8Volume               : Sample(9),
      askLevel8OrderCounts          : Sample(5),
      bidLevel8OrderCounts          : Sample(5),
      askLevel9Price                : Sample(9),
      bidLevel9Price                : Sample(9),
      askLevel9Volume               : Sample(9),
      bidLevel9Volume               : Sample(9),
      askLevel9OrderCounts          : Sample(5),
      bidLevel9OrderCounts          : Sample(5),
      askLevel10Price               : Sample(9),
      bidLevel10Price               : Sample(9),
      askLevel10Volume              : Sample(9),
      bidLevel10Volume              : Sample(9),
      askLevel10OrderCounts         : Sample(5),
      bidLevel10OrderCounts         : Sample(5),
      askTotalVolume                : Sample(9),
      bidTotalVolume                : Sample(9),
      askPriceValidCounts           : Sample(5),
      bidPriceValidCounts           : Sample(5),
      estimatedTradingPrice         : Sample(9),
      estimatedTradingVolume        : Sample(9),
      endKeyword                    : Sample(1) ]

EncodeDerivativesQuoteTenLevelsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel6OrderCounts
        \o message.bidLevel6OrderCounts
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel7OrderCounts
        \o message.bidLevel7OrderCounts
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel8OrderCounts
        \o message.bidLevel8OrderCounts
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel9OrderCounts
        \o message.bidLevel9OrderCounts
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.askLevel10OrderCounts
        \o message.bidLevel10OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeDerivativesQuoteTenLevelsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 9) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 9) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 9) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel6OrderCounts == ReadBytes(bidLevel6Volume.rest, 5) IN IF ~askLevel6OrderCounts.ok THEN Fail ELSE
    LET bidLevel6OrderCounts == ReadBytes(askLevel6OrderCounts.rest, 5) IN IF ~bidLevel6OrderCounts.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6OrderCounts.rest, 9) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 9) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 9) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 9) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel7OrderCounts == ReadBytes(bidLevel7Volume.rest, 5) IN IF ~askLevel7OrderCounts.ok THEN Fail ELSE
    LET bidLevel7OrderCounts == ReadBytes(askLevel7OrderCounts.rest, 5) IN IF ~bidLevel7OrderCounts.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7OrderCounts.rest, 9) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 9) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 9) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 9) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel8OrderCounts == ReadBytes(bidLevel8Volume.rest, 5) IN IF ~askLevel8OrderCounts.ok THEN Fail ELSE
    LET bidLevel8OrderCounts == ReadBytes(askLevel8OrderCounts.rest, 5) IN IF ~bidLevel8OrderCounts.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8OrderCounts.rest, 9) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 9) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 9) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 9) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel9OrderCounts == ReadBytes(bidLevel9Volume.rest, 5) IN IF ~askLevel9OrderCounts.ok THEN Fail ELSE
    LET bidLevel9OrderCounts == ReadBytes(askLevel9OrderCounts.rest, 5) IN IF ~bidLevel9OrderCounts.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9OrderCounts.rest, 9) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 9) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 9) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 9) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET askLevel10OrderCounts == ReadBytes(bidLevel10Volume.rest, 5) IN IF ~askLevel10OrderCounts.ok THEN Fail ELSE
    LET bidLevel10OrderCounts == ReadBytes(askLevel10OrderCounts.rest, 5) IN IF ~bidLevel10OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel10OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(bidPriceValidCounts.rest, 9) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 9) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel1OrderCounts          |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts          |-> bidLevel1OrderCounts.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel2OrderCounts          |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts          |-> bidLevel2OrderCounts.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel3OrderCounts          |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts          |-> bidLevel3OrderCounts.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel4OrderCounts          |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts          |-> bidLevel4OrderCounts.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         askLevel5OrderCounts          |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts          |-> bidLevel5OrderCounts.value,
         askLevel6Price                |-> askLevel6Price.value,
         bidLevel6Price                |-> bidLevel6Price.value,
         askLevel6Volume               |-> askLevel6Volume.value,
         bidLevel6Volume               |-> bidLevel6Volume.value,
         askLevel6OrderCounts          |-> askLevel6OrderCounts.value,
         bidLevel6OrderCounts          |-> bidLevel6OrderCounts.value,
         askLevel7Price                |-> askLevel7Price.value,
         bidLevel7Price                |-> bidLevel7Price.value,
         askLevel7Volume               |-> askLevel7Volume.value,
         bidLevel7Volume               |-> bidLevel7Volume.value,
         askLevel7OrderCounts          |-> askLevel7OrderCounts.value,
         bidLevel7OrderCounts          |-> bidLevel7OrderCounts.value,
         askLevel8Price                |-> askLevel8Price.value,
         bidLevel8Price                |-> bidLevel8Price.value,
         askLevel8Volume               |-> askLevel8Volume.value,
         bidLevel8Volume               |-> bidLevel8Volume.value,
         askLevel8OrderCounts          |-> askLevel8OrderCounts.value,
         bidLevel8OrderCounts          |-> bidLevel8OrderCounts.value,
         askLevel9Price                |-> askLevel9Price.value,
         bidLevel9Price                |-> bidLevel9Price.value,
         askLevel9Volume               |-> askLevel9Volume.value,
         bidLevel9Volume               |-> bidLevel9Volume.value,
         askLevel9OrderCounts          |-> askLevel9OrderCounts.value,
         bidLevel9OrderCounts          |-> bidLevel9OrderCounts.value,
         askLevel10Price               |-> askLevel10Price.value,
         bidLevel10Price               |-> bidLevel10Price.value,
         askLevel10Volume              |-> askLevel10Volume.value,
         bidLevel10Volume              |-> bidLevel10Volume.value,
         askLevel10OrderCounts         |-> askLevel10OrderCounts.value,
         bidLevel10OrderCounts         |-> bidLevel10OrderCounts.value,
         askTotalVolume                |-> askTotalVolume.value,
         bidTotalVolume                |-> bidTotalVolume.value,
         askPriceValidCounts           |-> askPriceValidCounts.value,
         bidPriceValidCounts           |-> bidPriceValidCounts.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesQuoteTenLevelsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel6Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel6Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel6OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel6OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel7Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel7Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel7OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel7OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel8Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel8Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel8OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel8OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel9Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel9Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel9OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel9OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel10Price               |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Price               |-> [i \in 1 .. 9 |-> 0],
      askLevel10Volume              |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Volume              |-> [i \in 1 .. 9 |-> 0],
      askLevel10OrderCounts         |-> [i \in 1 .. 5 |-> 0],
      bidLevel10OrderCounts         |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 9 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 9 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Quote Ten Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesQuoteTenLevelsMessage ==
    { ZeroDerivativesQuoteTenLevelsMessage }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuoteTenLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Snapshot Five Levels Message: 416 bytes                     *)
(***************************************************************************)

DerivativesSnapshotFiveLevelsMessage ==
    [ boardId                          : Sample(2),
      sessionId                        : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      upperLimitPrice                  : Sample(9),
      lowerLimitPrice                  : Sample(9),
      tradingPrice                     : Sample(9),
      nearbyMonthContractTradingPrice  : Sample(9),
      distantMonthContractTradingPrice : Sample(9),
      openingPrice                     : Sample(9),
      todaysHigh                       : Sample(9),
      todaysLow                        : Sample(9),
      openInterest                     : Sample(10),
      accumulatedTradingVolume         : Sample(12),
      accumulatedTradingValue          : Sample(22),
      finalAskBidTypeCode              : Sample(1),
      askLevel1Price                   : Sample(9),
      bidLevel1Price                   : Sample(9),
      askLevel1Volume                  : Sample(9),
      bidLevel1Volume                  : Sample(9),
      askLevel1OrderCounts             : Sample(5),
      bidLevel1OrderCounts             : Sample(5),
      askLevel2Price                   : Sample(9),
      bidLevel2Price                   : Sample(9),
      askLevel2Volume                  : Sample(9),
      bidLevel2Volume                  : Sample(9),
      askLevel2OrderCounts             : Sample(5),
      bidLevel2OrderCounts             : Sample(5),
      askLevel3Price                   : Sample(9),
      bidLevel3Price                   : Sample(9),
      askLevel3Volume                  : Sample(9),
      bidLevel3Volume                  : Sample(9),
      askLevel3OrderCounts             : Sample(5),
      bidLevel3OrderCounts             : Sample(5),
      askLevel4Price                   : Sample(9),
      bidLevel4Price                   : Sample(9),
      askLevel4Volume                  : Sample(9),
      bidLevel4Volume                  : Sample(9),
      askLevel4OrderCounts             : Sample(5),
      bidLevel4OrderCounts             : Sample(5),
      askLevel5Price                   : Sample(9),
      bidLevel5Price                   : Sample(9),
      askLevel5Volume                  : Sample(9),
      bidLevel5Volume                  : Sample(9),
      askLevel5OrderCounts             : Sample(5),
      bidLevel5OrderCounts             : Sample(5),
      askTotalVolume                   : Sample(9),
      bidTotalVolume                   : Sample(9),
      askPriceValidCounts              : Sample(5),
      bidPriceValidCounts              : Sample(5),
      estimatedTradingPrice            : Sample(9),
      estimatedTradingVolume           : Sample(9),
      endKeyword                       : Sample(1) ]

EncodeDerivativesSnapshotFiveLevelsMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.tradingPrice
        \o message.nearbyMonthContractTradingPrice
        \o message.distantMonthContractTradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.openInterest
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeDerivativesSnapshotFiveLevelsMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 9) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(lowerLimitPrice.rest, 9) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET nearbyMonthContractTradingPrice == ReadBytes(tradingPrice.rest, 9) IN IF ~nearbyMonthContractTradingPrice.ok THEN Fail ELSE
    LET distantMonthContractTradingPrice == ReadBytes(nearbyMonthContractTradingPrice.rest, 9) IN IF ~distantMonthContractTradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(distantMonthContractTradingPrice.rest, 9) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 9) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 9) IN IF ~todaysLow.ok THEN Fail ELSE
    LET openInterest == ReadBytes(todaysLow.rest, 10) IN IF ~openInterest.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(openInterest.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(finalAskBidTypeCode.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(bidPriceValidCounts.rest, 9) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 9) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                          |-> boardId.value,
         sessionId                        |-> sessionId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         upperLimitPrice                  |-> upperLimitPrice.value,
         lowerLimitPrice                  |-> lowerLimitPrice.value,
         tradingPrice                     |-> tradingPrice.value,
         nearbyMonthContractTradingPrice  |-> nearbyMonthContractTradingPrice.value,
         distantMonthContractTradingPrice |-> distantMonthContractTradingPrice.value,
         openingPrice                     |-> openingPrice.value,
         todaysHigh                       |-> todaysHigh.value,
         todaysLow                        |-> todaysLow.value,
         openInterest                     |-> openInterest.value,
         accumulatedTradingVolume         |-> accumulatedTradingVolume.value,
         accumulatedTradingValue          |-> accumulatedTradingValue.value,
         finalAskBidTypeCode              |-> finalAskBidTypeCode.value,
         askLevel1Price                   |-> askLevel1Price.value,
         bidLevel1Price                   |-> bidLevel1Price.value,
         askLevel1Volume                  |-> askLevel1Volume.value,
         bidLevel1Volume                  |-> bidLevel1Volume.value,
         askLevel1OrderCounts             |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts             |-> bidLevel1OrderCounts.value,
         askLevel2Price                   |-> askLevel2Price.value,
         bidLevel2Price                   |-> bidLevel2Price.value,
         askLevel2Volume                  |-> askLevel2Volume.value,
         bidLevel2Volume                  |-> bidLevel2Volume.value,
         askLevel2OrderCounts             |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts             |-> bidLevel2OrderCounts.value,
         askLevel3Price                   |-> askLevel3Price.value,
         bidLevel3Price                   |-> bidLevel3Price.value,
         askLevel3Volume                  |-> askLevel3Volume.value,
         bidLevel3Volume                  |-> bidLevel3Volume.value,
         askLevel3OrderCounts             |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts             |-> bidLevel3OrderCounts.value,
         askLevel4Price                   |-> askLevel4Price.value,
         bidLevel4Price                   |-> bidLevel4Price.value,
         askLevel4Volume                  |-> askLevel4Volume.value,
         bidLevel4Volume                  |-> bidLevel4Volume.value,
         askLevel4OrderCounts             |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts             |-> bidLevel4OrderCounts.value,
         askLevel5Price                   |-> askLevel5Price.value,
         bidLevel5Price                   |-> bidLevel5Price.value,
         askLevel5Volume                  |-> askLevel5Volume.value,
         bidLevel5Volume                  |-> bidLevel5Volume.value,
         askLevel5OrderCounts             |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts             |-> bidLevel5OrderCounts.value,
         askTotalVolume                   |-> askTotalVolume.value,
         bidTotalVolume                   |-> bidTotalVolume.value,
         askPriceValidCounts              |-> askPriceValidCounts.value,
         bidPriceValidCounts              |-> bidPriceValidCounts.value,
         estimatedTradingPrice            |-> estimatedTradingPrice.value,
         estimatedTradingVolume           |-> estimatedTradingVolume.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesSnapshotFiveLevelsMessage ==
    [ boardId                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                        |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      upperLimitPrice                  |-> [i \in 1 .. 9 |-> 0],
      lowerLimitPrice                  |-> [i \in 1 .. 9 |-> 0],
      tradingPrice                     |-> [i \in 1 .. 9 |-> 0],
      nearbyMonthContractTradingPrice  |-> [i \in 1 .. 9 |-> 0],
      distantMonthContractTradingPrice |-> [i \in 1 .. 9 |-> 0],
      openingPrice                     |-> [i \in 1 .. 9 |-> 0],
      todaysHigh                       |-> [i \in 1 .. 9 |-> 0],
      todaysLow                        |-> [i \in 1 .. 9 |-> 0],
      openInterest                     |-> [i \in 1 .. 10 |-> 0],
      accumulatedTradingVolume         |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue          |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode              |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      estimatedTradingPrice            |-> [i \in 1 .. 9 |-> 0],
      estimatedTradingVolume           |-> [i \in 1 .. 9 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Snapshot Five Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesSnapshotFiveLevelsMessage ==
    { ZeroDerivativesSnapshotFiveLevelsMessage }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.tradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.nearbyMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.distantMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.openingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.todaysHigh = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.todaysLow = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.openInterest = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotFiveLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Snapshot Ten Levels Message: 646 bytes                      *)
(***************************************************************************)

DerivativesSnapshotTenLevelsMessage ==
    [ boardId                          : Sample(2),
      sessionId                        : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      upperLimitPrice                  : Sample(9),
      lowerLimitPrice                  : Sample(9),
      tradingPrice                     : Sample(9),
      nearbyMonthContractTradingPrice  : Sample(9),
      distantMonthContractTradingPrice : Sample(9),
      openingPrice                     : Sample(9),
      todaysHigh                       : Sample(9),
      todaysLow                        : Sample(9),
      openInterest                     : Sample(10),
      accumulatedTradingVolume         : Sample(12),
      accumulatedTradingValue          : Sample(22),
      finalAskBidTypeCode              : Sample(1),
      askLevel1Price                   : Sample(9),
      bidLevel1Price                   : Sample(9),
      askLevel1Volume                  : Sample(9),
      bidLevel1Volume                  : Sample(9),
      askLevel1OrderCounts             : Sample(5),
      bidLevel1OrderCounts             : Sample(5),
      askLevel2Price                   : Sample(9),
      bidLevel2Price                   : Sample(9),
      askLevel2Volume                  : Sample(9),
      bidLevel2Volume                  : Sample(9),
      askLevel2OrderCounts             : Sample(5),
      bidLevel2OrderCounts             : Sample(5),
      askLevel3Price                   : Sample(9),
      bidLevel3Price                   : Sample(9),
      askLevel3Volume                  : Sample(9),
      bidLevel3Volume                  : Sample(9),
      askLevel3OrderCounts             : Sample(5),
      bidLevel3OrderCounts             : Sample(5),
      askLevel4Price                   : Sample(9),
      bidLevel4Price                   : Sample(9),
      askLevel4Volume                  : Sample(9),
      bidLevel4Volume                  : Sample(9),
      askLevel4OrderCounts             : Sample(5),
      bidLevel4OrderCounts             : Sample(5),
      askLevel5Price                   : Sample(9),
      bidLevel5Price                   : Sample(9),
      askLevel5Volume                  : Sample(9),
      bidLevel5Volume                  : Sample(9),
      askLevel5OrderCounts             : Sample(5),
      bidLevel5OrderCounts             : Sample(5),
      askLevel6Price                   : Sample(9),
      bidLevel6Price                   : Sample(9),
      askLevel6Volume                  : Sample(9),
      bidLevel6Volume                  : Sample(9),
      askLevel6OrderCounts             : Sample(5),
      bidLevel6OrderCounts             : Sample(5),
      askLevel7Price                   : Sample(9),
      bidLevel7Price                   : Sample(9),
      askLevel7Volume                  : Sample(9),
      bidLevel7Volume                  : Sample(9),
      askLevel7OrderCounts             : Sample(5),
      bidLevel7OrderCounts             : Sample(5),
      askLevel8Price                   : Sample(9),
      bidLevel8Price                   : Sample(9),
      askLevel8Volume                  : Sample(9),
      bidLevel8Volume                  : Sample(9),
      askLevel8OrderCounts             : Sample(5),
      bidLevel8OrderCounts             : Sample(5),
      askLevel9Price                   : Sample(9),
      bidLevel9Price                   : Sample(9),
      askLevel9Volume                  : Sample(9),
      bidLevel9Volume                  : Sample(9),
      askLevel9OrderCounts             : Sample(5),
      bidLevel9OrderCounts             : Sample(5),
      askLevel10Price                  : Sample(9),
      bidLevel10Price                  : Sample(9),
      askLevel10Volume                 : Sample(9),
      bidLevel10Volume                 : Sample(9),
      askLevel10OrderCounts            : Sample(5),
      bidLevel10OrderCounts            : Sample(5),
      askTotalVolume                   : Sample(9),
      bidTotalVolume                   : Sample(9),
      askPriceValidCounts              : Sample(5),
      bidPriceValidCounts              : Sample(5),
      estimatedTradingPrice            : Sample(9),
      estimatedTradingVolume           : Sample(9),
      endKeyword                       : Sample(1) ]

EncodeDerivativesSnapshotTenLevelsMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.tradingPrice
        \o message.nearbyMonthContractTradingPrice
        \o message.distantMonthContractTradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.openInterest
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel6OrderCounts
        \o message.bidLevel6OrderCounts
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel7OrderCounts
        \o message.bidLevel7OrderCounts
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel8OrderCounts
        \o message.bidLevel8OrderCounts
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel9OrderCounts
        \o message.bidLevel9OrderCounts
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.askLevel10OrderCounts
        \o message.bidLevel10OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeDerivativesSnapshotTenLevelsMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 9) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(lowerLimitPrice.rest, 9) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET nearbyMonthContractTradingPrice == ReadBytes(tradingPrice.rest, 9) IN IF ~nearbyMonthContractTradingPrice.ok THEN Fail ELSE
    LET distantMonthContractTradingPrice == ReadBytes(nearbyMonthContractTradingPrice.rest, 9) IN IF ~distantMonthContractTradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(distantMonthContractTradingPrice.rest, 9) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 9) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 9) IN IF ~todaysLow.ok THEN Fail ELSE
    LET openInterest == ReadBytes(todaysLow.rest, 10) IN IF ~openInterest.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(openInterest.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(finalAskBidTypeCode.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 9) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 9) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 9) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel6OrderCounts == ReadBytes(bidLevel6Volume.rest, 5) IN IF ~askLevel6OrderCounts.ok THEN Fail ELSE
    LET bidLevel6OrderCounts == ReadBytes(askLevel6OrderCounts.rest, 5) IN IF ~bidLevel6OrderCounts.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6OrderCounts.rest, 9) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 9) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 9) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 9) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel7OrderCounts == ReadBytes(bidLevel7Volume.rest, 5) IN IF ~askLevel7OrderCounts.ok THEN Fail ELSE
    LET bidLevel7OrderCounts == ReadBytes(askLevel7OrderCounts.rest, 5) IN IF ~bidLevel7OrderCounts.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7OrderCounts.rest, 9) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 9) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 9) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 9) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel8OrderCounts == ReadBytes(bidLevel8Volume.rest, 5) IN IF ~askLevel8OrderCounts.ok THEN Fail ELSE
    LET bidLevel8OrderCounts == ReadBytes(askLevel8OrderCounts.rest, 5) IN IF ~bidLevel8OrderCounts.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8OrderCounts.rest, 9) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 9) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 9) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 9) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel9OrderCounts == ReadBytes(bidLevel9Volume.rest, 5) IN IF ~askLevel9OrderCounts.ok THEN Fail ELSE
    LET bidLevel9OrderCounts == ReadBytes(askLevel9OrderCounts.rest, 5) IN IF ~bidLevel9OrderCounts.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9OrderCounts.rest, 9) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 9) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 9) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 9) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET askLevel10OrderCounts == ReadBytes(bidLevel10Volume.rest, 5) IN IF ~askLevel10OrderCounts.ok THEN Fail ELSE
    LET bidLevel10OrderCounts == ReadBytes(askLevel10OrderCounts.rest, 5) IN IF ~bidLevel10OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel10OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(bidPriceValidCounts.rest, 9) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 9) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                          |-> boardId.value,
         sessionId                        |-> sessionId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         upperLimitPrice                  |-> upperLimitPrice.value,
         lowerLimitPrice                  |-> lowerLimitPrice.value,
         tradingPrice                     |-> tradingPrice.value,
         nearbyMonthContractTradingPrice  |-> nearbyMonthContractTradingPrice.value,
         distantMonthContractTradingPrice |-> distantMonthContractTradingPrice.value,
         openingPrice                     |-> openingPrice.value,
         todaysHigh                       |-> todaysHigh.value,
         todaysLow                        |-> todaysLow.value,
         openInterest                     |-> openInterest.value,
         accumulatedTradingVolume         |-> accumulatedTradingVolume.value,
         accumulatedTradingValue          |-> accumulatedTradingValue.value,
         finalAskBidTypeCode              |-> finalAskBidTypeCode.value,
         askLevel1Price                   |-> askLevel1Price.value,
         bidLevel1Price                   |-> bidLevel1Price.value,
         askLevel1Volume                  |-> askLevel1Volume.value,
         bidLevel1Volume                  |-> bidLevel1Volume.value,
         askLevel1OrderCounts             |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts             |-> bidLevel1OrderCounts.value,
         askLevel2Price                   |-> askLevel2Price.value,
         bidLevel2Price                   |-> bidLevel2Price.value,
         askLevel2Volume                  |-> askLevel2Volume.value,
         bidLevel2Volume                  |-> bidLevel2Volume.value,
         askLevel2OrderCounts             |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts             |-> bidLevel2OrderCounts.value,
         askLevel3Price                   |-> askLevel3Price.value,
         bidLevel3Price                   |-> bidLevel3Price.value,
         askLevel3Volume                  |-> askLevel3Volume.value,
         bidLevel3Volume                  |-> bidLevel3Volume.value,
         askLevel3OrderCounts             |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts             |-> bidLevel3OrderCounts.value,
         askLevel4Price                   |-> askLevel4Price.value,
         bidLevel4Price                   |-> bidLevel4Price.value,
         askLevel4Volume                  |-> askLevel4Volume.value,
         bidLevel4Volume                  |-> bidLevel4Volume.value,
         askLevel4OrderCounts             |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts             |-> bidLevel4OrderCounts.value,
         askLevel5Price                   |-> askLevel5Price.value,
         bidLevel5Price                   |-> bidLevel5Price.value,
         askLevel5Volume                  |-> askLevel5Volume.value,
         bidLevel5Volume                  |-> bidLevel5Volume.value,
         askLevel5OrderCounts             |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts             |-> bidLevel5OrderCounts.value,
         askLevel6Price                   |-> askLevel6Price.value,
         bidLevel6Price                   |-> bidLevel6Price.value,
         askLevel6Volume                  |-> askLevel6Volume.value,
         bidLevel6Volume                  |-> bidLevel6Volume.value,
         askLevel6OrderCounts             |-> askLevel6OrderCounts.value,
         bidLevel6OrderCounts             |-> bidLevel6OrderCounts.value,
         askLevel7Price                   |-> askLevel7Price.value,
         bidLevel7Price                   |-> bidLevel7Price.value,
         askLevel7Volume                  |-> askLevel7Volume.value,
         bidLevel7Volume                  |-> bidLevel7Volume.value,
         askLevel7OrderCounts             |-> askLevel7OrderCounts.value,
         bidLevel7OrderCounts             |-> bidLevel7OrderCounts.value,
         askLevel8Price                   |-> askLevel8Price.value,
         bidLevel8Price                   |-> bidLevel8Price.value,
         askLevel8Volume                  |-> askLevel8Volume.value,
         bidLevel8Volume                  |-> bidLevel8Volume.value,
         askLevel8OrderCounts             |-> askLevel8OrderCounts.value,
         bidLevel8OrderCounts             |-> bidLevel8OrderCounts.value,
         askLevel9Price                   |-> askLevel9Price.value,
         bidLevel9Price                   |-> bidLevel9Price.value,
         askLevel9Volume                  |-> askLevel9Volume.value,
         bidLevel9Volume                  |-> bidLevel9Volume.value,
         askLevel9OrderCounts             |-> askLevel9OrderCounts.value,
         bidLevel9OrderCounts             |-> bidLevel9OrderCounts.value,
         askLevel10Price                  |-> askLevel10Price.value,
         bidLevel10Price                  |-> bidLevel10Price.value,
         askLevel10Volume                 |-> askLevel10Volume.value,
         bidLevel10Volume                 |-> bidLevel10Volume.value,
         askLevel10OrderCounts            |-> askLevel10OrderCounts.value,
         bidLevel10OrderCounts            |-> bidLevel10OrderCounts.value,
         askTotalVolume                   |-> askTotalVolume.value,
         bidTotalVolume                   |-> bidTotalVolume.value,
         askPriceValidCounts              |-> askPriceValidCounts.value,
         bidPriceValidCounts              |-> bidPriceValidCounts.value,
         estimatedTradingPrice            |-> estimatedTradingPrice.value,
         estimatedTradingVolume           |-> estimatedTradingVolume.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesSnapshotTenLevelsMessage ==
    [ boardId                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                        |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      upperLimitPrice                  |-> [i \in 1 .. 9 |-> 0],
      lowerLimitPrice                  |-> [i \in 1 .. 9 |-> 0],
      tradingPrice                     |-> [i \in 1 .. 9 |-> 0],
      nearbyMonthContractTradingPrice  |-> [i \in 1 .. 9 |-> 0],
      distantMonthContractTradingPrice |-> [i \in 1 .. 9 |-> 0],
      openingPrice                     |-> [i \in 1 .. 9 |-> 0],
      todaysHigh                       |-> [i \in 1 .. 9 |-> 0],
      todaysLow                        |-> [i \in 1 .. 9 |-> 0],
      openInterest                     |-> [i \in 1 .. 10 |-> 0],
      accumulatedTradingVolume         |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue          |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode              |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel6Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel6Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel6OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel6OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel7Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel7Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel7OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel7OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel8Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel8Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel8OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel8OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel9Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel9Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel9OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel9OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel10Price                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Price                  |-> [i \in 1 .. 9 |-> 0],
      askLevel10Volume                 |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Volume                 |-> [i \in 1 .. 9 |-> 0],
      askLevel10OrderCounts            |-> [i \in 1 .. 5 |-> 0],
      bidLevel10OrderCounts            |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      estimatedTradingPrice            |-> [i \in 1 .. 9 |-> 0],
      estimatedTradingVolume           |-> [i \in 1 .. 9 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Snapshot Ten Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesSnapshotTenLevelsMessage ==
    { ZeroDerivativesSnapshotTenLevelsMessage }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.tradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.nearbyMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.distantMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.openingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.todaysHigh = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.todaysLow = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.openInterest = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesSnapshotTenLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Order Filled Message: 168 bytes                             *)
(***************************************************************************)

DerivativesOrderFilledMessage ==
    [ messageSequenceNumber            : Sample(8),
      boardId                          : Sample(2),
      sessionId                        : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      processingTimeOfTradingSystem    : Sample(12),
      tradingPrice                     : Sample(9),
      tradingVolume                    : Sample(9),
      nearbyMonthContractTradingPrice  : Sample(9),
      distantMonthContractTradingPrice : Sample(9),
      openingPrice                     : Sample(9),
      todaysHigh                       : Sample(9),
      todaysLow                        : Sample(9),
      previousPrice                    : Sample(9),
      accumulatedTradingVolume         : Sample(12),
      accumulatedTradingValue          : Sample(22),
      finalAskBidTypeCode              : Sample(1),
      upperLimitOfDynamicPriceRange    : Sample(9),
      lowerLimitOfDynamicPriceRange    : Sample(9),
      endKeyword                       : Sample(1) ]

EncodeDerivativesOrderFilledMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.nearbyMonthContractTradingPrice
        \o message.distantMonthContractTradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.upperLimitOfDynamicPriceRange
        \o message.lowerLimitOfDynamicPriceRange
        \o message.endKeyword

DecodeDerivativesOrderFilledMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 9) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET nearbyMonthContractTradingPrice == ReadBytes(tradingVolume.rest, 9) IN IF ~nearbyMonthContractTradingPrice.ok THEN Fail ELSE
    LET distantMonthContractTradingPrice == ReadBytes(nearbyMonthContractTradingPrice.rest, 9) IN IF ~distantMonthContractTradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(distantMonthContractTradingPrice.rest, 9) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 9) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 9) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 9) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET upperLimitOfDynamicPriceRange == ReadBytes(finalAskBidTypeCode.rest, 9) IN IF ~upperLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET lowerLimitOfDynamicPriceRange == ReadBytes(upperLimitOfDynamicPriceRange.rest, 9) IN IF ~lowerLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(lowerLimitOfDynamicPriceRange.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber            |-> messageSequenceNumber.value,
         boardId                          |-> boardId.value,
         sessionId                        |-> sessionId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem    |-> processingTimeOfTradingSystem.value,
         tradingPrice                     |-> tradingPrice.value,
         tradingVolume                    |-> tradingVolume.value,
         nearbyMonthContractTradingPrice  |-> nearbyMonthContractTradingPrice.value,
         distantMonthContractTradingPrice |-> distantMonthContractTradingPrice.value,
         openingPrice                     |-> openingPrice.value,
         todaysHigh                       |-> todaysHigh.value,
         todaysLow                        |-> todaysLow.value,
         previousPrice                    |-> previousPrice.value,
         accumulatedTradingVolume         |-> accumulatedTradingVolume.value,
         accumulatedTradingValue          |-> accumulatedTradingValue.value,
         finalAskBidTypeCode              |-> finalAskBidTypeCode.value,
         upperLimitOfDynamicPriceRange    |-> upperLimitOfDynamicPriceRange.value,
         lowerLimitOfDynamicPriceRange    |-> lowerLimitOfDynamicPriceRange.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesOrderFilledMessage ==
    [ messageSequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      boardId                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                        |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem    |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                     |-> [i \in 1 .. 9 |-> 0],
      tradingVolume                    |-> [i \in 1 .. 9 |-> 0],
      nearbyMonthContractTradingPrice  |-> [i \in 1 .. 9 |-> 0],
      distantMonthContractTradingPrice |-> [i \in 1 .. 9 |-> 0],
      openingPrice                     |-> [i \in 1 .. 9 |-> 0],
      todaysHigh                       |-> [i \in 1 .. 9 |-> 0],
      todaysLow                        |-> [i \in 1 .. 9 |-> 0],
      previousPrice                    |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolume         |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue          |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode              |-> [i \in 1 .. 1 |-> 0],
      upperLimitOfDynamicPriceRange    |-> [i \in 1 .. 9 |-> 0],
      lowerLimitOfDynamicPriceRange    |-> [i \in 1 .. 9 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesOrderFilledMessage ==
    { ZeroDerivativesOrderFilledMessage }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.nearbyMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.distantMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.openingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.previousPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.upperLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.lowerLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Order Filled Plus Quote Five Levels Message: 426 bytes      *)
(***************************************************************************)

DerivativesOrderFilledPlusQuoteFiveLevelsMessage ==
    [ messageSequenceNumber            : Sample(8),
      boardId                          : Sample(2),
      sessionId                        : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      processingTimeOfTradingSystem    : Sample(12),
      tradingPrice                     : Sample(9),
      tradingVolume                    : Sample(9),
      nearbyMonthContractTradingPrice  : Sample(9),
      distantMonthContractTradingPrice : Sample(9),
      openingPrice                     : Sample(9),
      todaysHigh                       : Sample(9),
      todaysLow                        : Sample(9),
      previousPrice                    : Sample(9),
      accumulatedTradingVolume         : Sample(12),
      accumulatedTradingValue          : Sample(22),
      finalAskBidTypeCode              : Sample(1),
      upperLimitOfDynamicPriceRange    : Sample(9),
      lowerLimitOfDynamicPriceRange    : Sample(9),
      askLevel1Price                   : Sample(9),
      bidLevel1Price                   : Sample(9),
      askLevel1Volume                  : Sample(9),
      bidLevel1Volume                  : Sample(9),
      askLevel1OrderCounts             : Sample(5),
      bidLevel1OrderCounts             : Sample(5),
      askLevel2Price                   : Sample(9),
      bidLevel2Price                   : Sample(9),
      askLevel2Volume                  : Sample(9),
      bidLevel2Volume                  : Sample(9),
      askLevel2OrderCounts             : Sample(5),
      bidLevel2OrderCounts             : Sample(5),
      askLevel3Price                   : Sample(9),
      bidLevel3Price                   : Sample(9),
      askLevel3Volume                  : Sample(9),
      bidLevel3Volume                  : Sample(9),
      askLevel3OrderCounts             : Sample(5),
      bidLevel3OrderCounts             : Sample(5),
      askLevel4Price                   : Sample(9),
      bidLevel4Price                   : Sample(9),
      askLevel4Volume                  : Sample(9),
      bidLevel4Volume                  : Sample(9),
      askLevel4OrderCounts             : Sample(5),
      bidLevel4OrderCounts             : Sample(5),
      askLevel5Price                   : Sample(9),
      bidLevel5Price                   : Sample(9),
      askLevel5Volume                  : Sample(9),
      bidLevel5Volume                  : Sample(9),
      askLevel5OrderCounts             : Sample(5),
      bidLevel5OrderCounts             : Sample(5),
      askTotalVolume                   : Sample(9),
      bidTotalVolume                   : Sample(9),
      askPriceValidCounts              : Sample(5),
      bidPriceValidCounts              : Sample(5),
      endKeyword                       : Sample(1) ]

EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.nearbyMonthContractTradingPrice
        \o message.distantMonthContractTradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.upperLimitOfDynamicPriceRange
        \o message.lowerLimitOfDynamicPriceRange
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.endKeyword

DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 9) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET nearbyMonthContractTradingPrice == ReadBytes(tradingVolume.rest, 9) IN IF ~nearbyMonthContractTradingPrice.ok THEN Fail ELSE
    LET distantMonthContractTradingPrice == ReadBytes(nearbyMonthContractTradingPrice.rest, 9) IN IF ~distantMonthContractTradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(distantMonthContractTradingPrice.rest, 9) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 9) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 9) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 9) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET upperLimitOfDynamicPriceRange == ReadBytes(finalAskBidTypeCode.rest, 9) IN IF ~upperLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET lowerLimitOfDynamicPriceRange == ReadBytes(upperLimitOfDynamicPriceRange.rest, 9) IN IF ~lowerLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(lowerLimitOfDynamicPriceRange.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidPriceValidCounts.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber            |-> messageSequenceNumber.value,
         boardId                          |-> boardId.value,
         sessionId                        |-> sessionId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem    |-> processingTimeOfTradingSystem.value,
         tradingPrice                     |-> tradingPrice.value,
         tradingVolume                    |-> tradingVolume.value,
         nearbyMonthContractTradingPrice  |-> nearbyMonthContractTradingPrice.value,
         distantMonthContractTradingPrice |-> distantMonthContractTradingPrice.value,
         openingPrice                     |-> openingPrice.value,
         todaysHigh                       |-> todaysHigh.value,
         todaysLow                        |-> todaysLow.value,
         previousPrice                    |-> previousPrice.value,
         accumulatedTradingVolume         |-> accumulatedTradingVolume.value,
         accumulatedTradingValue          |-> accumulatedTradingValue.value,
         finalAskBidTypeCode              |-> finalAskBidTypeCode.value,
         upperLimitOfDynamicPriceRange    |-> upperLimitOfDynamicPriceRange.value,
         lowerLimitOfDynamicPriceRange    |-> lowerLimitOfDynamicPriceRange.value,
         askLevel1Price                   |-> askLevel1Price.value,
         bidLevel1Price                   |-> bidLevel1Price.value,
         askLevel1Volume                  |-> askLevel1Volume.value,
         bidLevel1Volume                  |-> bidLevel1Volume.value,
         askLevel1OrderCounts             |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts             |-> bidLevel1OrderCounts.value,
         askLevel2Price                   |-> askLevel2Price.value,
         bidLevel2Price                   |-> bidLevel2Price.value,
         askLevel2Volume                  |-> askLevel2Volume.value,
         bidLevel2Volume                  |-> bidLevel2Volume.value,
         askLevel2OrderCounts             |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts             |-> bidLevel2OrderCounts.value,
         askLevel3Price                   |-> askLevel3Price.value,
         bidLevel3Price                   |-> bidLevel3Price.value,
         askLevel3Volume                  |-> askLevel3Volume.value,
         bidLevel3Volume                  |-> bidLevel3Volume.value,
         askLevel3OrderCounts             |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts             |-> bidLevel3OrderCounts.value,
         askLevel4Price                   |-> askLevel4Price.value,
         bidLevel4Price                   |-> bidLevel4Price.value,
         askLevel4Volume                  |-> askLevel4Volume.value,
         bidLevel4Volume                  |-> bidLevel4Volume.value,
         askLevel4OrderCounts             |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts             |-> bidLevel4OrderCounts.value,
         askLevel5Price                   |-> askLevel5Price.value,
         bidLevel5Price                   |-> bidLevel5Price.value,
         askLevel5Volume                  |-> askLevel5Volume.value,
         bidLevel5Volume                  |-> bidLevel5Volume.value,
         askLevel5OrderCounts             |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts             |-> bidLevel5OrderCounts.value,
         askTotalVolume                   |-> askTotalVolume.value,
         bidTotalVolume                   |-> bidTotalVolume.value,
         askPriceValidCounts              |-> askPriceValidCounts.value,
         bidPriceValidCounts              |-> bidPriceValidCounts.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage ==
    [ messageSequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      boardId                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                        |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem    |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                     |-> [i \in 1 .. 9 |-> 0],
      tradingVolume                    |-> [i \in 1 .. 9 |-> 0],
      nearbyMonthContractTradingPrice  |-> [i \in 1 .. 9 |-> 0],
      distantMonthContractTradingPrice |-> [i \in 1 .. 9 |-> 0],
      openingPrice                     |-> [i \in 1 .. 9 |-> 0],
      todaysHigh                       |-> [i \in 1 .. 9 |-> 0],
      todaysLow                        |-> [i \in 1 .. 9 |-> 0],
      previousPrice                    |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolume         |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue          |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode              |-> [i \in 1 .. 1 |-> 0],
      upperLimitOfDynamicPriceRange    |-> [i \in 1 .. 9 |-> 0],
      lowerLimitOfDynamicPriceRange    |-> [i \in 1 .. 9 |-> 0],
      askLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Order Filled Plus Quote Five Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage ==
    { ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.tradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.tradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.nearbyMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.distantMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.openingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.todaysHigh = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.todaysLow = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.previousPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.upperLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.lowerLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Order Filled Plus Quote Ten Levels Message: 656 bytes       *)
(***************************************************************************)

DerivativesOrderFilledPlusQuoteTenLevelsMessage ==
    [ messageSequenceNumber            : Sample(8),
      boardId                          : Sample(2),
      sessionId                        : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      processingTimeOfTradingSystem    : Sample(12),
      tradingPrice                     : Sample(9),
      tradingVolume                    : Sample(9),
      nearbyMonthContractTradingPrice  : Sample(9),
      distantMonthContractTradingPrice : Sample(9),
      openingPrice                     : Sample(9),
      todaysHigh                       : Sample(9),
      todaysLow                        : Sample(9),
      previousPrice                    : Sample(9),
      accumulatedTradingVolume         : Sample(12),
      accumulatedTradingValue          : Sample(22),
      finalAskBidTypeCode              : Sample(1),
      upperLimitOfDynamicPriceRange    : Sample(9),
      lowerLimitOfDynamicPriceRange    : Sample(9),
      askLevel1Price                   : Sample(9),
      bidLevel1Price                   : Sample(9),
      askLevel1Volume                  : Sample(9),
      bidLevel1Volume                  : Sample(9),
      askLevel1OrderCounts             : Sample(5),
      bidLevel1OrderCounts             : Sample(5),
      askLevel2Price                   : Sample(9),
      bidLevel2Price                   : Sample(9),
      askLevel2Volume                  : Sample(9),
      bidLevel2Volume                  : Sample(9),
      askLevel2OrderCounts             : Sample(5),
      bidLevel2OrderCounts             : Sample(5),
      askLevel3Price                   : Sample(9),
      bidLevel3Price                   : Sample(9),
      askLevel3Volume                  : Sample(9),
      bidLevel3Volume                  : Sample(9),
      askLevel3OrderCounts             : Sample(5),
      bidLevel3OrderCounts             : Sample(5),
      askLevel4Price                   : Sample(9),
      bidLevel4Price                   : Sample(9),
      askLevel4Volume                  : Sample(9),
      bidLevel4Volume                  : Sample(9),
      askLevel4OrderCounts             : Sample(5),
      bidLevel4OrderCounts             : Sample(5),
      askLevel5Price                   : Sample(9),
      bidLevel5Price                   : Sample(9),
      askLevel5Volume                  : Sample(9),
      bidLevel5Volume                  : Sample(9),
      askLevel5OrderCounts             : Sample(5),
      bidLevel5OrderCounts             : Sample(5),
      askLevel6Price                   : Sample(9),
      bidLevel6Price                   : Sample(9),
      askLevel6Volume                  : Sample(9),
      bidLevel6Volume                  : Sample(9),
      askLevel6OrderCounts             : Sample(5),
      bidLevel6OrderCounts             : Sample(5),
      askLevel7Price                   : Sample(9),
      bidLevel7Price                   : Sample(9),
      askLevel7Volume                  : Sample(9),
      bidLevel7Volume                  : Sample(9),
      askLevel7OrderCounts             : Sample(5),
      bidLevel7OrderCounts             : Sample(5),
      askLevel8Price                   : Sample(9),
      bidLevel8Price                   : Sample(9),
      askLevel8Volume                  : Sample(9),
      bidLevel8Volume                  : Sample(9),
      askLevel8OrderCounts             : Sample(5),
      bidLevel8OrderCounts             : Sample(5),
      askLevel9Price                   : Sample(9),
      bidLevel9Price                   : Sample(9),
      askLevel9Volume                  : Sample(9),
      bidLevel9Volume                  : Sample(9),
      askLevel9OrderCounts             : Sample(5),
      bidLevel9OrderCounts             : Sample(5),
      askLevel10Price                  : Sample(9),
      bidLevel10Price                  : Sample(9),
      askLevel10Volume                 : Sample(9),
      bidLevel10Volume                 : Sample(9),
      askLevel10OrderCounts            : Sample(5),
      bidLevel10OrderCounts            : Sample(5),
      askTotalVolume                   : Sample(9),
      bidTotalVolume                   : Sample(9),
      askPriceValidCounts              : Sample(5),
      bidPriceValidCounts              : Sample(5),
      endKeyword                       : Sample(1) ]

EncodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.nearbyMonthContractTradingPrice
        \o message.distantMonthContractTradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.upperLimitOfDynamicPriceRange
        \o message.lowerLimitOfDynamicPriceRange
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel6OrderCounts
        \o message.bidLevel6OrderCounts
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel7OrderCounts
        \o message.bidLevel7OrderCounts
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel8OrderCounts
        \o message.bidLevel8OrderCounts
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel9OrderCounts
        \o message.bidLevel9OrderCounts
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.askLevel10OrderCounts
        \o message.bidLevel10OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.endKeyword

DecodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 9) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET nearbyMonthContractTradingPrice == ReadBytes(tradingVolume.rest, 9) IN IF ~nearbyMonthContractTradingPrice.ok THEN Fail ELSE
    LET distantMonthContractTradingPrice == ReadBytes(nearbyMonthContractTradingPrice.rest, 9) IN IF ~distantMonthContractTradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(distantMonthContractTradingPrice.rest, 9) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 9) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 9) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 9) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET upperLimitOfDynamicPriceRange == ReadBytes(finalAskBidTypeCode.rest, 9) IN IF ~upperLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET lowerLimitOfDynamicPriceRange == ReadBytes(upperLimitOfDynamicPriceRange.rest, 9) IN IF ~lowerLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(lowerLimitOfDynamicPriceRange.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 9) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 9) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 9) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel6OrderCounts == ReadBytes(bidLevel6Volume.rest, 5) IN IF ~askLevel6OrderCounts.ok THEN Fail ELSE
    LET bidLevel6OrderCounts == ReadBytes(askLevel6OrderCounts.rest, 5) IN IF ~bidLevel6OrderCounts.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6OrderCounts.rest, 9) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 9) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 9) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 9) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel7OrderCounts == ReadBytes(bidLevel7Volume.rest, 5) IN IF ~askLevel7OrderCounts.ok THEN Fail ELSE
    LET bidLevel7OrderCounts == ReadBytes(askLevel7OrderCounts.rest, 5) IN IF ~bidLevel7OrderCounts.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7OrderCounts.rest, 9) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 9) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 9) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 9) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel8OrderCounts == ReadBytes(bidLevel8Volume.rest, 5) IN IF ~askLevel8OrderCounts.ok THEN Fail ELSE
    LET bidLevel8OrderCounts == ReadBytes(askLevel8OrderCounts.rest, 5) IN IF ~bidLevel8OrderCounts.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8OrderCounts.rest, 9) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 9) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 9) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 9) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel9OrderCounts == ReadBytes(bidLevel9Volume.rest, 5) IN IF ~askLevel9OrderCounts.ok THEN Fail ELSE
    LET bidLevel9OrderCounts == ReadBytes(askLevel9OrderCounts.rest, 5) IN IF ~bidLevel9OrderCounts.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9OrderCounts.rest, 9) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 9) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 9) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 9) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET askLevel10OrderCounts == ReadBytes(bidLevel10Volume.rest, 5) IN IF ~askLevel10OrderCounts.ok THEN Fail ELSE
    LET bidLevel10OrderCounts == ReadBytes(askLevel10OrderCounts.rest, 5) IN IF ~bidLevel10OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel10OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidPriceValidCounts.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber            |-> messageSequenceNumber.value,
         boardId                          |-> boardId.value,
         sessionId                        |-> sessionId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem    |-> processingTimeOfTradingSystem.value,
         tradingPrice                     |-> tradingPrice.value,
         tradingVolume                    |-> tradingVolume.value,
         nearbyMonthContractTradingPrice  |-> nearbyMonthContractTradingPrice.value,
         distantMonthContractTradingPrice |-> distantMonthContractTradingPrice.value,
         openingPrice                     |-> openingPrice.value,
         todaysHigh                       |-> todaysHigh.value,
         todaysLow                        |-> todaysLow.value,
         previousPrice                    |-> previousPrice.value,
         accumulatedTradingVolume         |-> accumulatedTradingVolume.value,
         accumulatedTradingValue          |-> accumulatedTradingValue.value,
         finalAskBidTypeCode              |-> finalAskBidTypeCode.value,
         upperLimitOfDynamicPriceRange    |-> upperLimitOfDynamicPriceRange.value,
         lowerLimitOfDynamicPriceRange    |-> lowerLimitOfDynamicPriceRange.value,
         askLevel1Price                   |-> askLevel1Price.value,
         bidLevel1Price                   |-> bidLevel1Price.value,
         askLevel1Volume                  |-> askLevel1Volume.value,
         bidLevel1Volume                  |-> bidLevel1Volume.value,
         askLevel1OrderCounts             |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts             |-> bidLevel1OrderCounts.value,
         askLevel2Price                   |-> askLevel2Price.value,
         bidLevel2Price                   |-> bidLevel2Price.value,
         askLevel2Volume                  |-> askLevel2Volume.value,
         bidLevel2Volume                  |-> bidLevel2Volume.value,
         askLevel2OrderCounts             |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts             |-> bidLevel2OrderCounts.value,
         askLevel3Price                   |-> askLevel3Price.value,
         bidLevel3Price                   |-> bidLevel3Price.value,
         askLevel3Volume                  |-> askLevel3Volume.value,
         bidLevel3Volume                  |-> bidLevel3Volume.value,
         askLevel3OrderCounts             |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts             |-> bidLevel3OrderCounts.value,
         askLevel4Price                   |-> askLevel4Price.value,
         bidLevel4Price                   |-> bidLevel4Price.value,
         askLevel4Volume                  |-> askLevel4Volume.value,
         bidLevel4Volume                  |-> bidLevel4Volume.value,
         askLevel4OrderCounts             |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts             |-> bidLevel4OrderCounts.value,
         askLevel5Price                   |-> askLevel5Price.value,
         bidLevel5Price                   |-> bidLevel5Price.value,
         askLevel5Volume                  |-> askLevel5Volume.value,
         bidLevel5Volume                  |-> bidLevel5Volume.value,
         askLevel5OrderCounts             |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts             |-> bidLevel5OrderCounts.value,
         askLevel6Price                   |-> askLevel6Price.value,
         bidLevel6Price                   |-> bidLevel6Price.value,
         askLevel6Volume                  |-> askLevel6Volume.value,
         bidLevel6Volume                  |-> bidLevel6Volume.value,
         askLevel6OrderCounts             |-> askLevel6OrderCounts.value,
         bidLevel6OrderCounts             |-> bidLevel6OrderCounts.value,
         askLevel7Price                   |-> askLevel7Price.value,
         bidLevel7Price                   |-> bidLevel7Price.value,
         askLevel7Volume                  |-> askLevel7Volume.value,
         bidLevel7Volume                  |-> bidLevel7Volume.value,
         askLevel7OrderCounts             |-> askLevel7OrderCounts.value,
         bidLevel7OrderCounts             |-> bidLevel7OrderCounts.value,
         askLevel8Price                   |-> askLevel8Price.value,
         bidLevel8Price                   |-> bidLevel8Price.value,
         askLevel8Volume                  |-> askLevel8Volume.value,
         bidLevel8Volume                  |-> bidLevel8Volume.value,
         askLevel8OrderCounts             |-> askLevel8OrderCounts.value,
         bidLevel8OrderCounts             |-> bidLevel8OrderCounts.value,
         askLevel9Price                   |-> askLevel9Price.value,
         bidLevel9Price                   |-> bidLevel9Price.value,
         askLevel9Volume                  |-> askLevel9Volume.value,
         bidLevel9Volume                  |-> bidLevel9Volume.value,
         askLevel9OrderCounts             |-> askLevel9OrderCounts.value,
         bidLevel9OrderCounts             |-> bidLevel9OrderCounts.value,
         askLevel10Price                  |-> askLevel10Price.value,
         bidLevel10Price                  |-> bidLevel10Price.value,
         askLevel10Volume                 |-> askLevel10Volume.value,
         bidLevel10Volume                 |-> bidLevel10Volume.value,
         askLevel10OrderCounts            |-> askLevel10OrderCounts.value,
         bidLevel10OrderCounts            |-> bidLevel10OrderCounts.value,
         askTotalVolume                   |-> askTotalVolume.value,
         bidTotalVolume                   |-> bidTotalVolume.value,
         askPriceValidCounts              |-> askPriceValidCounts.value,
         bidPriceValidCounts              |-> bidPriceValidCounts.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage ==
    [ messageSequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      boardId                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                        |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem    |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                     |-> [i \in 1 .. 9 |-> 0],
      tradingVolume                    |-> [i \in 1 .. 9 |-> 0],
      nearbyMonthContractTradingPrice  |-> [i \in 1 .. 9 |-> 0],
      distantMonthContractTradingPrice |-> [i \in 1 .. 9 |-> 0],
      openingPrice                     |-> [i \in 1 .. 9 |-> 0],
      todaysHigh                       |-> [i \in 1 .. 9 |-> 0],
      todaysLow                        |-> [i \in 1 .. 9 |-> 0],
      previousPrice                    |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolume         |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue          |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode              |-> [i \in 1 .. 1 |-> 0],
      upperLimitOfDynamicPriceRange    |-> [i \in 1 .. 9 |-> 0],
      lowerLimitOfDynamicPriceRange    |-> [i \in 1 .. 9 |-> 0],
      askLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel6Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel6Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel6OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel6OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel7Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel7Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel7OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel7OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel8Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel8Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel8OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel8OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel9Price                   |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Price                   |-> [i \in 1 .. 9 |-> 0],
      askLevel9Volume                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Volume                  |-> [i \in 1 .. 9 |-> 0],
      askLevel9OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      bidLevel9OrderCounts             |-> [i \in 1 .. 5 |-> 0],
      askLevel10Price                  |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Price                  |-> [i \in 1 .. 9 |-> 0],
      askLevel10Volume                 |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Volume                 |-> [i \in 1 .. 9 |-> 0],
      askLevel10OrderCounts            |-> [i \in 1 .. 5 |-> 0],
      bidLevel10OrderCounts            |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                   |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts              |-> [i \in 1 .. 5 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Order Filled Plus Quote Ten Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesOrderFilledPlusQuoteTenLevelsMessage ==
    { ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.tradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.tradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.nearbyMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.distantMonthContractTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.openingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.todaysHigh = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.todaysLow = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.previousPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.upperLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.lowerLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Market Operation Ts Plus Quote Five Levels Message: 354     *)
(* bytes                                                                   *)
(***************************************************************************)

DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      upperLimitOfDynamicPriceRange : Sample(9),
      lowerLimitOfDynamicPriceRange : Sample(9),
      askLevel1Price                : Sample(9),
      bidLevel1Price                : Sample(9),
      askLevel1Volume               : Sample(9),
      bidLevel1Volume               : Sample(9),
      askLevel1OrderCounts          : Sample(5),
      bidLevel1OrderCounts          : Sample(5),
      askLevel2Price                : Sample(9),
      bidLevel2Price                : Sample(9),
      askLevel2Volume               : Sample(9),
      bidLevel2Volume               : Sample(9),
      askLevel2OrderCounts          : Sample(5),
      bidLevel2OrderCounts          : Sample(5),
      askLevel3Price                : Sample(9),
      bidLevel3Price                : Sample(9),
      askLevel3Volume               : Sample(9),
      bidLevel3Volume               : Sample(9),
      askLevel3OrderCounts          : Sample(5),
      bidLevel3OrderCounts          : Sample(5),
      askLevel4Price                : Sample(9),
      bidLevel4Price                : Sample(9),
      askLevel4Volume               : Sample(9),
      bidLevel4Volume               : Sample(9),
      askLevel4OrderCounts          : Sample(5),
      bidLevel4OrderCounts          : Sample(5),
      askLevel5Price                : Sample(9),
      bidLevel5Price                : Sample(9),
      askLevel5Volume               : Sample(9),
      bidLevel5Volume               : Sample(9),
      askLevel5OrderCounts          : Sample(5),
      bidLevel5OrderCounts          : Sample(5),
      askTotalVolume                : Sample(9),
      bidTotalVolume                : Sample(9),
      askPriceValidCounts           : Sample(5),
      bidPriceValidCounts           : Sample(5),
      estimatedTradingPrice         : Sample(9),
      estimatedTradingVolume        : Sample(9),
      endKeyword                    : Sample(1) ]

EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.upperLimitOfDynamicPriceRange
        \o message.lowerLimitOfDynamicPriceRange
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET upperLimitOfDynamicPriceRange == ReadBytes(boardEventGroupCode.rest, 9) IN IF ~upperLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET lowerLimitOfDynamicPriceRange == ReadBytes(upperLimitOfDynamicPriceRange.rest, 9) IN IF ~lowerLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(lowerLimitOfDynamicPriceRange.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(bidPriceValidCounts.rest, 9) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 9) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         upperLimitOfDynamicPriceRange |-> upperLimitOfDynamicPriceRange.value,
         lowerLimitOfDynamicPriceRange |-> lowerLimitOfDynamicPriceRange.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel1OrderCounts          |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts          |-> bidLevel1OrderCounts.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel2OrderCounts          |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts          |-> bidLevel2OrderCounts.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel3OrderCounts          |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts          |-> bidLevel3OrderCounts.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel4OrderCounts          |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts          |-> bidLevel4OrderCounts.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         askLevel5OrderCounts          |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts          |-> bidLevel5OrderCounts.value,
         askTotalVolume                |-> askTotalVolume.value,
         bidTotalVolume                |-> bidTotalVolume.value,
         askPriceValidCounts           |-> askPriceValidCounts.value,
         bidPriceValidCounts           |-> bidPriceValidCounts.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      upperLimitOfDynamicPriceRange |-> [i \in 1 .. 9 |-> 0],
      lowerLimitOfDynamicPriceRange |-> [i \in 1 .. 9 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 9 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 9 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Market Operation Ts Plus Quote Five Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ==
    { ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.upperLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.lowerLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Market Operation Ts Plus Quote Ten Levels Message: 584      *)
(* bytes                                                                   *)
(***************************************************************************)

DerivativesMarketOperationTsPlusQuoteTenLevelsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      upperLimitOfDynamicPriceRange : Sample(9),
      lowerLimitOfDynamicPriceRange : Sample(9),
      askLevel1Price                : Sample(9),
      bidLevel1Price                : Sample(9),
      askLevel1Volume               : Sample(9),
      bidLevel1Volume               : Sample(9),
      askLevel1OrderCounts          : Sample(5),
      bidLevel1OrderCounts          : Sample(5),
      askLevel2Price                : Sample(9),
      bidLevel2Price                : Sample(9),
      askLevel2Volume               : Sample(9),
      bidLevel2Volume               : Sample(9),
      askLevel2OrderCounts          : Sample(5),
      bidLevel2OrderCounts          : Sample(5),
      askLevel3Price                : Sample(9),
      bidLevel3Price                : Sample(9),
      askLevel3Volume               : Sample(9),
      bidLevel3Volume               : Sample(9),
      askLevel3OrderCounts          : Sample(5),
      bidLevel3OrderCounts          : Sample(5),
      askLevel4Price                : Sample(9),
      bidLevel4Price                : Sample(9),
      askLevel4Volume               : Sample(9),
      bidLevel4Volume               : Sample(9),
      askLevel4OrderCounts          : Sample(5),
      bidLevel4OrderCounts          : Sample(5),
      askLevel5Price                : Sample(9),
      bidLevel5Price                : Sample(9),
      askLevel5Volume               : Sample(9),
      bidLevel5Volume               : Sample(9),
      askLevel5OrderCounts          : Sample(5),
      bidLevel5OrderCounts          : Sample(5),
      askLevel6Price                : Sample(9),
      bidLevel6Price                : Sample(9),
      askLevel6Volume               : Sample(9),
      bidLevel6Volume               : Sample(9),
      askLevel6OrderCounts          : Sample(5),
      bidLevel6OrderCounts          : Sample(5),
      askLevel7Price                : Sample(9),
      bidLevel7Price                : Sample(9),
      askLevel7Volume               : Sample(9),
      bidLevel7Volume               : Sample(9),
      askLevel7OrderCounts          : Sample(5),
      bidLevel7OrderCounts          : Sample(5),
      askLevel8Price                : Sample(9),
      bidLevel8Price                : Sample(9),
      askLevel8Volume               : Sample(9),
      bidLevel8Volume               : Sample(9),
      askLevel8OrderCounts          : Sample(5),
      bidLevel8OrderCounts          : Sample(5),
      askLevel9Price                : Sample(9),
      bidLevel9Price                : Sample(9),
      askLevel9Volume               : Sample(9),
      bidLevel9Volume               : Sample(9),
      askLevel9OrderCounts          : Sample(5),
      bidLevel9OrderCounts          : Sample(5),
      askLevel10Price               : Sample(9),
      bidLevel10Price               : Sample(9),
      askLevel10Volume              : Sample(9),
      bidLevel10Volume              : Sample(9),
      askLevel10OrderCounts         : Sample(5),
      bidLevel10OrderCounts         : Sample(5),
      askTotalVolume                : Sample(9),
      bidTotalVolume                : Sample(9),
      askPriceValidCounts           : Sample(5),
      bidPriceValidCounts           : Sample(5),
      estimatedTradingPrice         : Sample(9),
      estimatedTradingVolume        : Sample(9),
      endKeyword                    : Sample(1) ]

EncodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.upperLimitOfDynamicPriceRange
        \o message.lowerLimitOfDynamicPriceRange
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel1OrderCounts
        \o message.bidLevel1OrderCounts
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel2OrderCounts
        \o message.bidLevel2OrderCounts
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel3OrderCounts
        \o message.bidLevel3OrderCounts
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel4OrderCounts
        \o message.bidLevel4OrderCounts
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel5OrderCounts
        \o message.bidLevel5OrderCounts
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel6OrderCounts
        \o message.bidLevel6OrderCounts
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel7OrderCounts
        \o message.bidLevel7OrderCounts
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel8OrderCounts
        \o message.bidLevel8OrderCounts
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel9OrderCounts
        \o message.bidLevel9OrderCounts
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.askLevel10OrderCounts
        \o message.bidLevel10OrderCounts
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.askPriceValidCounts
        \o message.bidPriceValidCounts
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET upperLimitOfDynamicPriceRange == ReadBytes(boardEventGroupCode.rest, 9) IN IF ~upperLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET lowerLimitOfDynamicPriceRange == ReadBytes(upperLimitOfDynamicPriceRange.rest, 9) IN IF ~lowerLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(lowerLimitOfDynamicPriceRange.rest, 9) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 9) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 9) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 9) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel1OrderCounts == ReadBytes(bidLevel1Volume.rest, 5) IN IF ~askLevel1OrderCounts.ok THEN Fail ELSE
    LET bidLevel1OrderCounts == ReadBytes(askLevel1OrderCounts.rest, 5) IN IF ~bidLevel1OrderCounts.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1OrderCounts.rest, 9) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 9) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 9) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 9) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel2OrderCounts == ReadBytes(bidLevel2Volume.rest, 5) IN IF ~askLevel2OrderCounts.ok THEN Fail ELSE
    LET bidLevel2OrderCounts == ReadBytes(askLevel2OrderCounts.rest, 5) IN IF ~bidLevel2OrderCounts.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2OrderCounts.rest, 9) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 9) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 9) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 9) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel3OrderCounts == ReadBytes(bidLevel3Volume.rest, 5) IN IF ~askLevel3OrderCounts.ok THEN Fail ELSE
    LET bidLevel3OrderCounts == ReadBytes(askLevel3OrderCounts.rest, 5) IN IF ~bidLevel3OrderCounts.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3OrderCounts.rest, 9) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 9) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 9) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 9) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel4OrderCounts == ReadBytes(bidLevel4Volume.rest, 5) IN IF ~askLevel4OrderCounts.ok THEN Fail ELSE
    LET bidLevel4OrderCounts == ReadBytes(askLevel4OrderCounts.rest, 5) IN IF ~bidLevel4OrderCounts.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4OrderCounts.rest, 9) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 9) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 9) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 9) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel5OrderCounts == ReadBytes(bidLevel5Volume.rest, 5) IN IF ~askLevel5OrderCounts.ok THEN Fail ELSE
    LET bidLevel5OrderCounts == ReadBytes(askLevel5OrderCounts.rest, 5) IN IF ~bidLevel5OrderCounts.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(bidLevel5OrderCounts.rest, 9) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 9) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 9) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 9) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel6OrderCounts == ReadBytes(bidLevel6Volume.rest, 5) IN IF ~askLevel6OrderCounts.ok THEN Fail ELSE
    LET bidLevel6OrderCounts == ReadBytes(askLevel6OrderCounts.rest, 5) IN IF ~bidLevel6OrderCounts.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6OrderCounts.rest, 9) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 9) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 9) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 9) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel7OrderCounts == ReadBytes(bidLevel7Volume.rest, 5) IN IF ~askLevel7OrderCounts.ok THEN Fail ELSE
    LET bidLevel7OrderCounts == ReadBytes(askLevel7OrderCounts.rest, 5) IN IF ~bidLevel7OrderCounts.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7OrderCounts.rest, 9) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 9) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 9) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 9) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel8OrderCounts == ReadBytes(bidLevel8Volume.rest, 5) IN IF ~askLevel8OrderCounts.ok THEN Fail ELSE
    LET bidLevel8OrderCounts == ReadBytes(askLevel8OrderCounts.rest, 5) IN IF ~bidLevel8OrderCounts.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8OrderCounts.rest, 9) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 9) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 9) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 9) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel9OrderCounts == ReadBytes(bidLevel9Volume.rest, 5) IN IF ~askLevel9OrderCounts.ok THEN Fail ELSE
    LET bidLevel9OrderCounts == ReadBytes(askLevel9OrderCounts.rest, 5) IN IF ~bidLevel9OrderCounts.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9OrderCounts.rest, 9) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 9) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 9) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 9) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET askLevel10OrderCounts == ReadBytes(bidLevel10Volume.rest, 5) IN IF ~askLevel10OrderCounts.ok THEN Fail ELSE
    LET bidLevel10OrderCounts == ReadBytes(askLevel10OrderCounts.rest, 5) IN IF ~bidLevel10OrderCounts.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(bidLevel10OrderCounts.rest, 9) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 9) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET askPriceValidCounts == ReadBytes(bidTotalVolume.rest, 5) IN IF ~askPriceValidCounts.ok THEN Fail ELSE
    LET bidPriceValidCounts == ReadBytes(askPriceValidCounts.rest, 5) IN IF ~bidPriceValidCounts.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(bidPriceValidCounts.rest, 9) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 9) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         upperLimitOfDynamicPriceRange |-> upperLimitOfDynamicPriceRange.value,
         lowerLimitOfDynamicPriceRange |-> lowerLimitOfDynamicPriceRange.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel1OrderCounts          |-> askLevel1OrderCounts.value,
         bidLevel1OrderCounts          |-> bidLevel1OrderCounts.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel2OrderCounts          |-> askLevel2OrderCounts.value,
         bidLevel2OrderCounts          |-> bidLevel2OrderCounts.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel3OrderCounts          |-> askLevel3OrderCounts.value,
         bidLevel3OrderCounts          |-> bidLevel3OrderCounts.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel4OrderCounts          |-> askLevel4OrderCounts.value,
         bidLevel4OrderCounts          |-> bidLevel4OrderCounts.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         askLevel5OrderCounts          |-> askLevel5OrderCounts.value,
         bidLevel5OrderCounts          |-> bidLevel5OrderCounts.value,
         askLevel6Price                |-> askLevel6Price.value,
         bidLevel6Price                |-> bidLevel6Price.value,
         askLevel6Volume               |-> askLevel6Volume.value,
         bidLevel6Volume               |-> bidLevel6Volume.value,
         askLevel6OrderCounts          |-> askLevel6OrderCounts.value,
         bidLevel6OrderCounts          |-> bidLevel6OrderCounts.value,
         askLevel7Price                |-> askLevel7Price.value,
         bidLevel7Price                |-> bidLevel7Price.value,
         askLevel7Volume               |-> askLevel7Volume.value,
         bidLevel7Volume               |-> bidLevel7Volume.value,
         askLevel7OrderCounts          |-> askLevel7OrderCounts.value,
         bidLevel7OrderCounts          |-> bidLevel7OrderCounts.value,
         askLevel8Price                |-> askLevel8Price.value,
         bidLevel8Price                |-> bidLevel8Price.value,
         askLevel8Volume               |-> askLevel8Volume.value,
         bidLevel8Volume               |-> bidLevel8Volume.value,
         askLevel8OrderCounts          |-> askLevel8OrderCounts.value,
         bidLevel8OrderCounts          |-> bidLevel8OrderCounts.value,
         askLevel9Price                |-> askLevel9Price.value,
         bidLevel9Price                |-> bidLevel9Price.value,
         askLevel9Volume               |-> askLevel9Volume.value,
         bidLevel9Volume               |-> bidLevel9Volume.value,
         askLevel9OrderCounts          |-> askLevel9OrderCounts.value,
         bidLevel9OrderCounts          |-> bidLevel9OrderCounts.value,
         askLevel10Price               |-> askLevel10Price.value,
         bidLevel10Price               |-> bidLevel10Price.value,
         askLevel10Volume              |-> askLevel10Volume.value,
         bidLevel10Volume              |-> bidLevel10Volume.value,
         askLevel10OrderCounts         |-> askLevel10OrderCounts.value,
         bidLevel10OrderCounts         |-> bidLevel10OrderCounts.value,
         askTotalVolume                |-> askTotalVolume.value,
         bidTotalVolume                |-> bidTotalVolume.value,
         askPriceValidCounts           |-> askPriceValidCounts.value,
         bidPriceValidCounts           |-> bidPriceValidCounts.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      upperLimitOfDynamicPriceRange |-> [i \in 1 .. 9 |-> 0],
      lowerLimitOfDynamicPriceRange |-> [i \in 1 .. 9 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel1OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel2OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel3OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel4OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel5OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel6Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel6Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel6Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel6OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel6OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel7Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel7Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel7Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel7OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel7OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel8Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel8Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel8Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel8OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel8OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel9Price                |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Price                |-> [i \in 1 .. 9 |-> 0],
      askLevel9Volume               |-> [i \in 1 .. 9 |-> 0],
      bidLevel9Volume               |-> [i \in 1 .. 9 |-> 0],
      askLevel9OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      bidLevel9OrderCounts          |-> [i \in 1 .. 5 |-> 0],
      askLevel10Price               |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Price               |-> [i \in 1 .. 9 |-> 0],
      askLevel10Volume              |-> [i \in 1 .. 9 |-> 0],
      bidLevel10Volume              |-> [i \in 1 .. 9 |-> 0],
      askLevel10OrderCounts         |-> [i \in 1 .. 5 |-> 0],
      bidLevel10OrderCounts         |-> [i \in 1 .. 5 |-> 0],
      askTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      bidTotalVolume                |-> [i \in 1 .. 9 |-> 0],
      askPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      bidPriceValidCounts           |-> [i \in 1 .. 5 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 9 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 9 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Market Operation Ts Plus Quote Ten Levels Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesMarketOperationTsPlusQuoteTenLevelsMessage ==
    { ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.upperLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.lowerLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel1OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel2OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel3OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel4OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel5OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel6OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel7OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel8OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel9OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidLevel10OrderCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.askPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.bidPriceValidCounts = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Negotiated Trade Message: 56 bytes                          *)
(***************************************************************************)

DerivativesNegotiatedTradeMessage ==
    [ isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      totalAccumulatedTradingVolume : Sample(15),
      totalAccumulatedTradingValue  : Sample(22),
      endKeyword                    : Sample(1) ]

EncodeDerivativesNegotiatedTradeMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.totalAccumulatedTradingVolume
        \o message.totalAccumulatedTradingValue
        \o message.endKeyword

DecodeDerivativesNegotiatedTradeMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET totalAccumulatedTradingVolume == ReadBytes(aDesignatedNumberForAnIssue.rest, 15) IN IF ~totalAccumulatedTradingVolume.ok THEN Fail ELSE
    LET totalAccumulatedTradingValue == ReadBytes(totalAccumulatedTradingVolume.rest, 22) IN IF ~totalAccumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalAccumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         totalAccumulatedTradingVolume |-> totalAccumulatedTradingVolume.value,
         totalAccumulatedTradingValue  |-> totalAccumulatedTradingValue.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesNegotiatedTradeMessage ==
    [ isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      totalAccumulatedTradingVolume |-> [i \in 1 .. 15 |-> 0],
      totalAccumulatedTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Negotiated Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesNegotiatedTradeMessage ==
    { ZeroDerivativesNegotiatedTradeMessage }
        \cup { [ZeroDerivativesNegotiatedTradeMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesNegotiatedTradeMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesNegotiatedTradeMessage EXCEPT !.totalAccumulatedTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroDerivativesNegotiatedTradeMessage EXCEPT !.totalAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesNegotiatedTradeMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Market Operation Ts Message: 63 bytes                       *)
(***************************************************************************)

DerivativesMarketOperationTsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      tradingHaltReasonCode         : Sample(3),
      endKeyword                    : Sample(1) ]

EncodeDerivativesMarketOperationTsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.tradingHaltReasonCode
        \o message.endKeyword

DecodeDerivativesMarketOperationTsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         tradingHaltReasonCode         |-> tradingHaltReasonCode.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesMarketOperationTsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      tradingHaltReasonCode         |-> [i \in 1 .. 3 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesMarketOperationTsMessage ==
    { ZeroDerivativesMarketOperationTsMessage }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Issue Closing Message: 73 bytes                             *)
(***************************************************************************)

DerivativesIssueClosingMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      closingPrice                : Sample(9),
      closingPriceTypeCode        : Sample(1),
      accumulatedTradingVolume    : Sample(12),
      accumulatedTradingValue     : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeDerivativesIssueClosingMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.closingPrice
        \o message.closingPriceTypeCode
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.endKeyword

DecodeDerivativesIssueClosingMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(closingPriceTypeCode.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         closingPrice                |-> closingPrice.value,
         closingPriceTypeCode        |-> closingPriceTypeCode.value,
         accumulatedTradingVolume    |-> accumulatedTradingVolume.value,
         accumulatedTradingValue     |-> accumulatedTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesIssueClosingMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      closingPrice                |-> [i \in 1 .. 9 |-> 0],
      closingPriceTypeCode        |-> [i \in 1 .. 1 |-> 0],
      accumulatedTradingVolume    |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue     |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesIssueClosingMessage ==
    { ZeroDerivativesIssueClosingMessage }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.closingPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Market Operation Schedule Message: 78 bytes                 *)
(***************************************************************************)

DerivativesMarketOperationScheduleMessage ==
    [ marketOperationProductId                     : Sample(3),
      boardId                                      : Sample(2),
      boardEventId                                 : Sample(3),
      startTimeOfABoardEvent                       : Sample(9),
      boardEventGroupCode                          : Sample(5),
      sessionStartEndCode                          : Sample(2),
      sessionId                                    : Sample(2),
      isinCode                                     : Sample(12),
      isinCodeOfACommonStock                       : Sample(12),
      productId                                    : Sample(11),
      tradingHaltReasonCode                        : Sample(3),
      tradingHaltTypeCode                          : Sample(1),
      stepApplied                                  : Sample(2),
      priceLimitRangeExpansionForBaseIssueTypeCode : Sample(1),
      expectedTimeOfExpandingPriceLimitRange       : Sample(9),
      endKeyword                                   : Sample(1) ]

EncodeDerivativesMarketOperationScheduleMessage(message) ==
    message.marketOperationProductId
        \o message.boardId
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.sessionStartEndCode
        \o message.sessionId
        \o message.isinCode
        \o message.isinCodeOfACommonStock
        \o message.productId
        \o message.tradingHaltReasonCode
        \o message.tradingHaltTypeCode
        \o message.stepApplied
        \o message.priceLimitRangeExpansionForBaseIssueTypeCode
        \o message.expectedTimeOfExpandingPriceLimitRange
        \o message.endKeyword

DecodeDerivativesMarketOperationScheduleMessage(bytes) ==
    LET marketOperationProductId == ReadBytes(bytes, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET boardId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(boardId.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET sessionStartEndCode == ReadBytes(boardEventGroupCode.rest, 2) IN IF ~sessionStartEndCode.ok THEN Fail ELSE
    LET sessionId == ReadBytes(sessionStartEndCode.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET isinCodeOfACommonStock == ReadBytes(isinCode.rest, 12) IN IF ~isinCodeOfACommonStock.ok THEN Fail ELSE
    LET productId == ReadBytes(isinCodeOfACommonStock.rest, 11) IN IF ~productId.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(productId.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET tradingHaltTypeCode == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~tradingHaltTypeCode.ok THEN Fail ELSE
    LET stepApplied == ReadBytes(tradingHaltTypeCode.rest, 2) IN IF ~stepApplied.ok THEN Fail ELSE
    LET priceLimitRangeExpansionForBaseIssueTypeCode == ReadBytes(stepApplied.rest, 1) IN IF ~priceLimitRangeExpansionForBaseIssueTypeCode.ok THEN Fail ELSE
    LET expectedTimeOfExpandingPriceLimitRange == ReadBytes(priceLimitRangeExpansionForBaseIssueTypeCode.rest, 9) IN IF ~expectedTimeOfExpandingPriceLimitRange.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(expectedTimeOfExpandingPriceLimitRange.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ marketOperationProductId                     |-> marketOperationProductId.value,
         boardId                                      |-> boardId.value,
         boardEventId                                 |-> boardEventId.value,
         startTimeOfABoardEvent                       |-> startTimeOfABoardEvent.value,
         boardEventGroupCode                          |-> boardEventGroupCode.value,
         sessionStartEndCode                          |-> sessionStartEndCode.value,
         sessionId                                    |-> sessionId.value,
         isinCode                                     |-> isinCode.value,
         isinCodeOfACommonStock                       |-> isinCodeOfACommonStock.value,
         productId                                    |-> productId.value,
         tradingHaltReasonCode                        |-> tradingHaltReasonCode.value,
         tradingHaltTypeCode                          |-> tradingHaltTypeCode.value,
         stepApplied                                  |-> stepApplied.value,
         priceLimitRangeExpansionForBaseIssueTypeCode |-> priceLimitRangeExpansionForBaseIssueTypeCode.value,
         expectedTimeOfExpandingPriceLimitRange       |-> expectedTimeOfExpandingPriceLimitRange.value,
         endKeyword                                   |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesMarketOperationScheduleMessage ==
    [ marketOperationProductId                     |-> [i \in 1 .. 3 |-> 0],
      boardId                                      |-> [i \in 1 .. 2 |-> 0],
      boardEventId                                 |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent                       |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode                          |-> [i \in 1 .. 5 |-> 0],
      sessionStartEndCode                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                                    |-> [i \in 1 .. 2 |-> 0],
      isinCode                                     |-> [i \in 1 .. 12 |-> 0],
      isinCodeOfACommonStock                       |-> [i \in 1 .. 12 |-> 0],
      productId                                    |-> [i \in 1 .. 11 |-> 0],
      tradingHaltReasonCode                        |-> [i \in 1 .. 3 |-> 0],
      tradingHaltTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      stepApplied                                  |-> [i \in 1 .. 2 |-> 0],
      priceLimitRangeExpansionForBaseIssueTypeCode |-> [i \in 1 .. 1 |-> 0],
      expectedTimeOfExpandingPriceLimitRange       |-> [i \in 1 .. 9 |-> 0],
      endKeyword                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Market Operation Schedule Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesMarketOperationScheduleMessage ==
    { ZeroDerivativesMarketOperationScheduleMessage }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.sessionStartEndCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.isinCodeOfACommonStock = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.tradingHaltTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.stepApplied = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.priceLimitRangeExpansionForBaseIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.expectedTimeOfExpandingPriceLimitRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesMarketOperationScheduleMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Dynamic Upper Lower Limit Message: 60 bytes                 *)
(***************************************************************************)

DerivativesDynamicUpperLowerLimitMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      dynamicPriceLimitTypeCode     : Sample(1),
      upperLimitOfDynamicPriceRange : Sample(9),
      lowerLimitOfDynamicPriceRange : Sample(9),
      endKeyword                    : Sample(1) ]

EncodeDerivativesDynamicUpperLowerLimitMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.dynamicPriceLimitTypeCode
        \o message.upperLimitOfDynamicPriceRange
        \o message.lowerLimitOfDynamicPriceRange
        \o message.endKeyword

DecodeDerivativesDynamicUpperLowerLimitMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET dynamicPriceLimitTypeCode == ReadBytes(processingTimeOfTradingSystem.rest, 1) IN IF ~dynamicPriceLimitTypeCode.ok THEN Fail ELSE
    LET upperLimitOfDynamicPriceRange == ReadBytes(dynamicPriceLimitTypeCode.rest, 9) IN IF ~upperLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET lowerLimitOfDynamicPriceRange == ReadBytes(upperLimitOfDynamicPriceRange.rest, 9) IN IF ~lowerLimitOfDynamicPriceRange.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(lowerLimitOfDynamicPriceRange.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         dynamicPriceLimitTypeCode     |-> dynamicPriceLimitTypeCode.value,
         upperLimitOfDynamicPriceRange |-> upperLimitOfDynamicPriceRange.value,
         lowerLimitOfDynamicPriceRange |-> lowerLimitOfDynamicPriceRange.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesDynamicUpperLowerLimitMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      dynamicPriceLimitTypeCode     |-> [i \in 1 .. 1 |-> 0],
      upperLimitOfDynamicPriceRange |-> [i \in 1 .. 9 |-> 0],
      lowerLimitOfDynamicPriceRange |-> [i \in 1 .. 9 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Dynamic Upper Lower Limit Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesDynamicUpperLowerLimitMessage ==
    { ZeroDerivativesDynamicUpperLowerLimitMessage }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.dynamicPriceLimitTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.upperLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.lowerLimitOfDynamicPriceRange = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesDynamicUpperLowerLimitMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Price Limit Range Increase Message: 60 bytes                *)
(***************************************************************************)

DerivativesPriceLimitRangeIncreaseMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      theTimeImposingAPriceLimit    : Sample(9),
      priceLimitExpansionUpperLimit : Sample(2),
      priceLimitExpansionLowerLimit : Sample(2),
      upperLimitPrice               : Sample(9),
      lowerLimitPrice               : Sample(9),
      endKeyword                    : Sample(1) ]

EncodeDerivativesPriceLimitRangeIncreaseMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.theTimeImposingAPriceLimit
        \o message.priceLimitExpansionUpperLimit
        \o message.priceLimitExpansionLowerLimit
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.endKeyword

DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET theTimeImposingAPriceLimit == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~theTimeImposingAPriceLimit.ok THEN Fail ELSE
    LET priceLimitExpansionUpperLimit == ReadBytes(theTimeImposingAPriceLimit.rest, 2) IN IF ~priceLimitExpansionUpperLimit.ok THEN Fail ELSE
    LET priceLimitExpansionLowerLimit == ReadBytes(priceLimitExpansionUpperLimit.rest, 2) IN IF ~priceLimitExpansionLowerLimit.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(priceLimitExpansionLowerLimit.rest, 9) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 9) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(lowerLimitPrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         theTimeImposingAPriceLimit    |-> theTimeImposingAPriceLimit.value,
         priceLimitExpansionUpperLimit |-> priceLimitExpansionUpperLimit.value,
         priceLimitExpansionLowerLimit |-> priceLimitExpansionLowerLimit.value,
         upperLimitPrice               |-> upperLimitPrice.value,
         lowerLimitPrice               |-> lowerLimitPrice.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesPriceLimitRangeIncreaseMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      theTimeImposingAPriceLimit    |-> [i \in 1 .. 9 |-> 0],
      priceLimitExpansionUpperLimit |-> [i \in 1 .. 2 |-> 0],
      priceLimitExpansionLowerLimit |-> [i \in 1 .. 2 |-> 0],
      upperLimitPrice               |-> [i \in 1 .. 9 |-> 0],
      lowerLimitPrice               |-> [i \in 1 .. 9 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Price Limit Range Increase Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesPriceLimitRangeIncreaseMessage ==
    { ZeroDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.theTimeImposingAPriceLimit = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.priceLimitExpansionUpperLimit = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.priceLimitExpansionLowerLimit = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesPriceLimitRangeIncreaseMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Quantity Allocation Message: 40 bytes                       *)
(***************************************************************************)

DerivativesQuantityAllocationMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      startEndOfAllocation        : Sample(1),
      allocationTypeCode          : Sample(1),
      timeWhenAllocationEnded     : Sample(9),
      endKeyword                  : Sample(1) ]

EncodeDerivativesQuantityAllocationMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.startEndOfAllocation
        \o message.allocationTypeCode
        \o message.timeWhenAllocationEnded
        \o message.endKeyword

DecodeDerivativesQuantityAllocationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET startEndOfAllocation == ReadBytes(aDesignatedNumberForAnIssue.rest, 1) IN IF ~startEndOfAllocation.ok THEN Fail ELSE
    LET allocationTypeCode == ReadBytes(startEndOfAllocation.rest, 1) IN IF ~allocationTypeCode.ok THEN Fail ELSE
    LET timeWhenAllocationEnded == ReadBytes(allocationTypeCode.rest, 9) IN IF ~timeWhenAllocationEnded.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(timeWhenAllocationEnded.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         startEndOfAllocation        |-> startEndOfAllocation.value,
         allocationTypeCode          |-> allocationTypeCode.value,
         timeWhenAllocationEnded     |-> timeWhenAllocationEnded.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesQuantityAllocationMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      startEndOfAllocation        |-> [i \in 1 .. 1 |-> 0],
      allocationTypeCode          |-> [i \in 1 .. 1 |-> 0],
      timeWhenAllocationEnded     |-> [i \in 1 .. 9 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Quantity Allocation Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesQuantityAllocationMessage ==
    { ZeroDerivativesQuantityAllocationMessage }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.startEndOfAllocation = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.allocationTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.timeWhenAllocationEnded = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesQuantityAllocationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Group Order Acceptance Halt Message: 28 bytes               *)
(***************************************************************************)

DerivativesGroupOrderAcceptanceHaltMessage ==
    [ marketId                 : Sample(3),
      meGroupNumber            : Sample(5),
      boardId                  : Sample(2),
      boardEventId             : Sample(3),
      boardEventGroupCode      : Sample(5),
      boardEventProcessingTime : Sample(9),
      endKeyword               : Sample(1) ]

EncodeDerivativesGroupOrderAcceptanceHaltMessage(message) ==
    message.marketId
        \o message.meGroupNumber
        \o message.boardId
        \o message.boardEventId
        \o message.boardEventGroupCode
        \o message.boardEventProcessingTime
        \o message.endKeyword

DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 3) IN IF ~marketId.ok THEN Fail ELSE
    LET meGroupNumber == ReadBytes(marketId.rest, 5) IN IF ~meGroupNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(meGroupNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(boardId.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(boardEventId.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET boardEventProcessingTime == ReadBytes(boardEventGroupCode.rest, 9) IN IF ~boardEventProcessingTime.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(boardEventProcessingTime.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ marketId                 |-> marketId.value,
         meGroupNumber            |-> meGroupNumber.value,
         boardId                  |-> boardId.value,
         boardEventId             |-> boardEventId.value,
         boardEventGroupCode      |-> boardEventGroupCode.value,
         boardEventProcessingTime |-> boardEventProcessingTime.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesGroupOrderAcceptanceHaltMessage ==
    [ marketId                 |-> [i \in 1 .. 3 |-> 0],
      meGroupNumber            |-> [i \in 1 .. 5 |-> 0],
      boardId                  |-> [i \in 1 .. 2 |-> 0],
      boardEventId             |-> [i \in 1 .. 3 |-> 0],
      boardEventGroupCode      |-> [i \in 1 .. 5 |-> 0],
      boardEventProcessingTime |-> [i \in 1 .. 9 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Group Order Acceptance Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesGroupOrderAcceptanceHaltMessage ==
    { ZeroDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.marketId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.meGroupNumber = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.boardEventProcessingTime = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesGroupOrderAcceptanceHaltMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Batch Data Message: 1313 bytes                              *)
(***************************************************************************)

DerivativesBatchDataMessage ==
    [ messageSequenceNumber                                  : Sample(8),
      totalNumberOfInstrumentsOfTheContract                  : Sample(6),
      businessDate                                           : Sample(8),
      isinCode                                               : Sample(12),
      aDesignatedNumberForAnIssue                            : Sample(6),
      futuresOptionsTypeCode                                 : Sample(1),
      productId                                              : Sample(11),
      abbreviatedIssueCode                                   : Sample(9),
      issueName                                              : Sample(80),
      abbreviatedIssueName                                   : Sample(40),
      englishIssueName                                       : Sample(80),
      abbreviatedIssueNameInEn                               : Sample(40),
      marketOperationProductId                               : Sample(3),
      listingDate                                            : Sample(8),
      delistingDate                                          : Sample(8),
      spreadTypeCode                                         : Sample(1),
      paymentMethods                                         : Sample(1),
      directionOfPriceLimitExpansionTypeCode                 : Sample(1),
      finalStageOfPriceLimitExpansion                        : Sample(3),
      upperPriceLimit1StStage                                : Sample(11),
      upperPriceLimit2NdStage                                : Sample(11),
      upperPriceLimit3RdStage                                : Sample(11),
      lowerPriceLimit1StStage                                : Sample(11),
      lowerPriceLimit2NdStage                                : Sample(11),
      lowerPriceLimit3RdStage                                : Sample(11),
      basePrice                                              : Sample(11),
      underlyingAssetId                                      : Sample(3),
      rightsExecutionTypeCode                                : Sample(1),
      spreadCompositionCode                                  : Sample(2),
      spreadIssueIsin1                                       : Sample(12),
      spreadIssueIsin2                                       : Sample(12),
      lastTradingDate                                        : Sample(8),
      lastPaymentDate                                        : Sample(8),
      sequenceNumberForDeliveryMonth                         : Sample(3),
      expirationDate                                         : Sample(8),
      exercisePrice                                          : Sample(18),
      basePriceAdjustmentTypeCode                            : Sample(1),
      tradingUnit                                            : Sample(22),
      tradingMultiplier                                      : Sample(22),
      typeOfLiquidityProvidingLp                             : Sample(1),
      listingTypeCode                                        : Sample(1),
      atm                                                    : Sample(11),
      adjustmentReasonCode                                   : Sample(2),
      isinOfUnderlyingAsset                                  : Sample(12),
      closingPriceOfUnderlyingAsset                          : Sample(11),
      remainingDays                                          : Sample(8),
      adjustedBasePrice                                      : Sample(18),
      basePriceTypeCode                                      : Sample(2),
      basePriceForTradingTypeCode                            : Sample(1),
      previousDaysAdjustedClosingPrice                       : Sample(18),
      blockTradingTypeCode                                   : Sample(1),
      previousDaysBpmm                                       : Sample(23),
      basePriceOfClearingMarginsTypeCode                     : Sample(2),
      theoreticalSettlementPrice                             : Sample(16),
      baseTheoreticalPrice                                   : Sample(16),
      previousDaysSettlementPrice                            : Sample(18),
      tradingHalt                                            : Sample(1),
      futuresCircuitBreakersUpperLimitPrice                  : Sample(11),
      futuresCircuitBreakersLowerLimitPrice                  : Sample(11),
      exercisePriceForDisplayingNotForTrading                : Sample(18),
      atmTypeCode                                            : Sample(1),
      lastTradingDay                                         : Sample(1),
      dividendValueForSettlementPrice                        : Sample(16),
      yesterdaysClosingPrice                                 : Sample(11),
      yesterdaysClosingPriceTypeCode                         : Sample(1),
      previousDaysOpeningPrice                               : Sample(11),
      previousDaysHighPrice                                  : Sample(11),
      previousDaysLowPrice                                   : Sample(11),
      theFirstTradingDate                                    : Sample(8),
      theLastTradingTime                                     : Sample(9),
      settlementPriceTypeCode                                : Sample(2),
      disparateRatio                                         : Sample(13),
      previousDaysOpenInterest                               : Sample(12),
      previousDaysBestAsk                                    : Sample(11),
      previousDaysBestBid                                    : Sample(11),
      impliedVolatility                                      : Sample(11),
      theHighestPremiumOfTheLifetime                         : Sample(11),
      theLowestPremiumOfTheLifetime                          : Sample(11),
      theHighestPremiumInAYear                               : Sample(11),
      theLowestPremiumInAYear                                : Sample(11),
      theDateOfTheHighestPremiumOfTheLifetime                : Sample(8),
      theDateOfTheLowestPremiumOfTheLifetime                 : Sample(8),
      theDateOfTheHighestPremiumInAYear                      : Sample(8),
      theDateOfTheLowestPremiumInAYear                       : Sample(8),
      numberOfListingDaysPerYear                             : Sample(8),
      numberOfTradingDaysPerMonth                            : Sample(8),
      numberOfTradingDaysPerYear                             : Sample(8),
      numberOfPreviousDaysTrading                            : Sample(15),
      yesterdaysAccumulatedTradingAmount                     : Sample(12),
      yesterdaysAccumulatedTradingValue                      : Sample(22),
      previousDaysTotalAccumulatedTradingVolume              : Sample(15),
      previousDaysTotalAccumulatedTradingValue               : Sample(22),
      interestRate                                           : Sample(11),
      openInterestLimitQuantity                              : Sample(15),
      underlyingAssetProductId                               : Sample(4),
      offsetRateOfAssetGroup                                 : Sample(11),
      limitOrderPermissionTypeCode                           : Sample(5),
      marketPriceOrderPermissionTypeCode                     : Sample(5),
      conditionedOrderPermissionTypeCode                     : Sample(5),
      bestFavorableOrderPermissionTypeCode                   : Sample(5),
      efpTradingItem                                         : Sample(1),
      flexTradingItem                                        : Sample(1),
      efpTradingVolume                                       : Sample(12),
      efpTradingValue                                        : Sample(22),
      marketHolidays                                         : Sample(1),
      limitationOfDynamicPrice                               : Sample(1),
      gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue : Sample(11),
      gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue : Sample(11),
      underlyingAssetMarketId                                : Sample(3),
      upperLimitQuantity                                     : Sample(23),
      lowerLimitQuantity                                     : Sample(23),
      upperLimitQuantityForBlockTrade                        : Sample(23),
      lowerLimitQuantityForBlockTrade                        : Sample(23),
      baseProductId                                          : Sample(11),
      subsidiaryProductId                                    : Sample(11),
      numberOfIssuesForBaseProduct                           : Sample(6),
      numberOfIssuesForSubsidiaryProduct                     : Sample(6),
      settlementWeek                                         : Sample(2),
      suspendedStocks                                        : Sample(1),
      designationDateForSuspendedStocks                      : Sample(8),
      endKeyword                                             : Sample(1) ]

EncodeDerivativesBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.futuresOptionsTypeCode
        \o message.productId
        \o message.abbreviatedIssueCode
        \o message.issueName
        \o message.abbreviatedIssueName
        \o message.englishIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.marketOperationProductId
        \o message.listingDate
        \o message.delistingDate
        \o message.spreadTypeCode
        \o message.paymentMethods
        \o message.directionOfPriceLimitExpansionTypeCode
        \o message.finalStageOfPriceLimitExpansion
        \o message.upperPriceLimit1StStage
        \o message.upperPriceLimit2NdStage
        \o message.upperPriceLimit3RdStage
        \o message.lowerPriceLimit1StStage
        \o message.lowerPriceLimit2NdStage
        \o message.lowerPriceLimit3RdStage
        \o message.basePrice
        \o message.underlyingAssetId
        \o message.rightsExecutionTypeCode
        \o message.spreadCompositionCode
        \o message.spreadIssueIsin1
        \o message.spreadIssueIsin2
        \o message.lastTradingDate
        \o message.lastPaymentDate
        \o message.sequenceNumberForDeliveryMonth
        \o message.expirationDate
        \o message.exercisePrice
        \o message.basePriceAdjustmentTypeCode
        \o message.tradingUnit
        \o message.tradingMultiplier
        \o message.typeOfLiquidityProvidingLp
        \o message.listingTypeCode
        \o message.atm
        \o message.adjustmentReasonCode
        \o message.isinOfUnderlyingAsset
        \o message.closingPriceOfUnderlyingAsset
        \o message.remainingDays
        \o message.adjustedBasePrice
        \o message.basePriceTypeCode
        \o message.basePriceForTradingTypeCode
        \o message.previousDaysAdjustedClosingPrice
        \o message.blockTradingTypeCode
        \o message.previousDaysBpmm
        \o message.basePriceOfClearingMarginsTypeCode
        \o message.theoreticalSettlementPrice
        \o message.baseTheoreticalPrice
        \o message.previousDaysSettlementPrice
        \o message.tradingHalt
        \o message.futuresCircuitBreakersUpperLimitPrice
        \o message.futuresCircuitBreakersLowerLimitPrice
        \o message.exercisePriceForDisplayingNotForTrading
        \o message.atmTypeCode
        \o message.lastTradingDay
        \o message.dividendValueForSettlementPrice
        \o message.yesterdaysClosingPrice
        \o message.yesterdaysClosingPriceTypeCode
        \o message.previousDaysOpeningPrice
        \o message.previousDaysHighPrice
        \o message.previousDaysLowPrice
        \o message.theFirstTradingDate
        \o message.theLastTradingTime
        \o message.settlementPriceTypeCode
        \o message.disparateRatio
        \o message.previousDaysOpenInterest
        \o message.previousDaysBestAsk
        \o message.previousDaysBestBid
        \o message.impliedVolatility
        \o message.theHighestPremiumOfTheLifetime
        \o message.theLowestPremiumOfTheLifetime
        \o message.theHighestPremiumInAYear
        \o message.theLowestPremiumInAYear
        \o message.theDateOfTheHighestPremiumOfTheLifetime
        \o message.theDateOfTheLowestPremiumOfTheLifetime
        \o message.theDateOfTheHighestPremiumInAYear
        \o message.theDateOfTheLowestPremiumInAYear
        \o message.numberOfListingDaysPerYear
        \o message.numberOfTradingDaysPerMonth
        \o message.numberOfTradingDaysPerYear
        \o message.numberOfPreviousDaysTrading
        \o message.yesterdaysAccumulatedTradingAmount
        \o message.yesterdaysAccumulatedTradingValue
        \o message.previousDaysTotalAccumulatedTradingVolume
        \o message.previousDaysTotalAccumulatedTradingValue
        \o message.interestRate
        \o message.openInterestLimitQuantity
        \o message.underlyingAssetProductId
        \o message.offsetRateOfAssetGroup
        \o message.limitOrderPermissionTypeCode
        \o message.marketPriceOrderPermissionTypeCode
        \o message.conditionedOrderPermissionTypeCode
        \o message.bestFavorableOrderPermissionTypeCode
        \o message.efpTradingItem
        \o message.flexTradingItem
        \o message.efpTradingVolume
        \o message.efpTradingValue
        \o message.marketHolidays
        \o message.limitationOfDynamicPrice
        \o message.gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue
        \o message.gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue
        \o message.underlyingAssetMarketId
        \o message.upperLimitQuantity
        \o message.lowerLimitQuantity
        \o message.upperLimitQuantityForBlockTrade
        \o message.lowerLimitQuantityForBlockTrade
        \o message.baseProductId
        \o message.subsidiaryProductId
        \o message.numberOfIssuesForBaseProduct
        \o message.numberOfIssuesForSubsidiaryProduct
        \o message.settlementWeek
        \o message.suspendedStocks
        \o message.designationDateForSuspendedStocks
        \o message.endKeyword

DecodeDerivativesBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET futuresOptionsTypeCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 1) IN IF ~futuresOptionsTypeCode.ok THEN Fail ELSE
    LET productId == ReadBytes(futuresOptionsTypeCode.rest, 11) IN IF ~productId.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(productId.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET issueName == ReadBytes(abbreviatedIssueCode.rest, 80) IN IF ~issueName.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(issueName.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET englishIssueName == ReadBytes(abbreviatedIssueName.rest, 80) IN IF ~englishIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(englishIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(abbreviatedIssueNameInEn.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET listingDate == ReadBytes(marketOperationProductId.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(listingDate.rest, 8) IN IF ~delistingDate.ok THEN Fail ELSE
    LET spreadTypeCode == ReadBytes(delistingDate.rest, 1) IN IF ~spreadTypeCode.ok THEN Fail ELSE
    LET paymentMethods == ReadBytes(spreadTypeCode.rest, 1) IN IF ~paymentMethods.ok THEN Fail ELSE
    LET directionOfPriceLimitExpansionTypeCode == ReadBytes(paymentMethods.rest, 1) IN IF ~directionOfPriceLimitExpansionTypeCode.ok THEN Fail ELSE
    LET finalStageOfPriceLimitExpansion == ReadBytes(directionOfPriceLimitExpansionTypeCode.rest, 3) IN IF ~finalStageOfPriceLimitExpansion.ok THEN Fail ELSE
    LET upperPriceLimit1StStage == ReadBytes(finalStageOfPriceLimitExpansion.rest, 11) IN IF ~upperPriceLimit1StStage.ok THEN Fail ELSE
    LET upperPriceLimit2NdStage == ReadBytes(upperPriceLimit1StStage.rest, 11) IN IF ~upperPriceLimit2NdStage.ok THEN Fail ELSE
    LET upperPriceLimit3RdStage == ReadBytes(upperPriceLimit2NdStage.rest, 11) IN IF ~upperPriceLimit3RdStage.ok THEN Fail ELSE
    LET lowerPriceLimit1StStage == ReadBytes(upperPriceLimit3RdStage.rest, 11) IN IF ~lowerPriceLimit1StStage.ok THEN Fail ELSE
    LET lowerPriceLimit2NdStage == ReadBytes(lowerPriceLimit1StStage.rest, 11) IN IF ~lowerPriceLimit2NdStage.ok THEN Fail ELSE
    LET lowerPriceLimit3RdStage == ReadBytes(lowerPriceLimit2NdStage.rest, 11) IN IF ~lowerPriceLimit3RdStage.ok THEN Fail ELSE
    LET basePrice == ReadBytes(lowerPriceLimit3RdStage.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET underlyingAssetId == ReadBytes(basePrice.rest, 3) IN IF ~underlyingAssetId.ok THEN Fail ELSE
    LET rightsExecutionTypeCode == ReadBytes(underlyingAssetId.rest, 1) IN IF ~rightsExecutionTypeCode.ok THEN Fail ELSE
    LET spreadCompositionCode == ReadBytes(rightsExecutionTypeCode.rest, 2) IN IF ~spreadCompositionCode.ok THEN Fail ELSE
    LET spreadIssueIsin1 == ReadBytes(spreadCompositionCode.rest, 12) IN IF ~spreadIssueIsin1.ok THEN Fail ELSE
    LET spreadIssueIsin2 == ReadBytes(spreadIssueIsin1.rest, 12) IN IF ~spreadIssueIsin2.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(spreadIssueIsin2.rest, 8) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET lastPaymentDate == ReadBytes(lastTradingDate.rest, 8) IN IF ~lastPaymentDate.ok THEN Fail ELSE
    LET sequenceNumberForDeliveryMonth == ReadBytes(lastPaymentDate.rest, 3) IN IF ~sequenceNumberForDeliveryMonth.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(sequenceNumberForDeliveryMonth.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET exercisePrice == ReadBytes(expirationDate.rest, 18) IN IF ~exercisePrice.ok THEN Fail ELSE
    LET basePriceAdjustmentTypeCode == ReadBytes(exercisePrice.rest, 1) IN IF ~basePriceAdjustmentTypeCode.ok THEN Fail ELSE
    LET tradingUnit == ReadBytes(basePriceAdjustmentTypeCode.rest, 22) IN IF ~tradingUnit.ok THEN Fail ELSE
    LET tradingMultiplier == ReadBytes(tradingUnit.rest, 22) IN IF ~tradingMultiplier.ok THEN Fail ELSE
    LET typeOfLiquidityProvidingLp == ReadBytes(tradingMultiplier.rest, 1) IN IF ~typeOfLiquidityProvidingLp.ok THEN Fail ELSE
    LET listingTypeCode == ReadBytes(typeOfLiquidityProvidingLp.rest, 1) IN IF ~listingTypeCode.ok THEN Fail ELSE
    LET atm == ReadBytes(listingTypeCode.rest, 11) IN IF ~atm.ok THEN Fail ELSE
    LET adjustmentReasonCode == ReadBytes(atm.rest, 2) IN IF ~adjustmentReasonCode.ok THEN Fail ELSE
    LET isinOfUnderlyingAsset == ReadBytes(adjustmentReasonCode.rest, 12) IN IF ~isinOfUnderlyingAsset.ok THEN Fail ELSE
    LET closingPriceOfUnderlyingAsset == ReadBytes(isinOfUnderlyingAsset.rest, 11) IN IF ~closingPriceOfUnderlyingAsset.ok THEN Fail ELSE
    LET remainingDays == ReadBytes(closingPriceOfUnderlyingAsset.rest, 8) IN IF ~remainingDays.ok THEN Fail ELSE
    LET adjustedBasePrice == ReadBytes(remainingDays.rest, 18) IN IF ~adjustedBasePrice.ok THEN Fail ELSE
    LET basePriceTypeCode == ReadBytes(adjustedBasePrice.rest, 2) IN IF ~basePriceTypeCode.ok THEN Fail ELSE
    LET basePriceForTradingTypeCode == ReadBytes(basePriceTypeCode.rest, 1) IN IF ~basePriceForTradingTypeCode.ok THEN Fail ELSE
    LET previousDaysAdjustedClosingPrice == ReadBytes(basePriceForTradingTypeCode.rest, 18) IN IF ~previousDaysAdjustedClosingPrice.ok THEN Fail ELSE
    LET blockTradingTypeCode == ReadBytes(previousDaysAdjustedClosingPrice.rest, 1) IN IF ~blockTradingTypeCode.ok THEN Fail ELSE
    LET previousDaysBpmm == ReadBytes(blockTradingTypeCode.rest, 23) IN IF ~previousDaysBpmm.ok THEN Fail ELSE
    LET basePriceOfClearingMarginsTypeCode == ReadBytes(previousDaysBpmm.rest, 2) IN IF ~basePriceOfClearingMarginsTypeCode.ok THEN Fail ELSE
    LET theoreticalSettlementPrice == ReadBytes(basePriceOfClearingMarginsTypeCode.rest, 16) IN IF ~theoreticalSettlementPrice.ok THEN Fail ELSE
    LET baseTheoreticalPrice == ReadBytes(theoreticalSettlementPrice.rest, 16) IN IF ~baseTheoreticalPrice.ok THEN Fail ELSE
    LET previousDaysSettlementPrice == ReadBytes(baseTheoreticalPrice.rest, 18) IN IF ~previousDaysSettlementPrice.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(previousDaysSettlementPrice.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET futuresCircuitBreakersUpperLimitPrice == ReadBytes(tradingHalt.rest, 11) IN IF ~futuresCircuitBreakersUpperLimitPrice.ok THEN Fail ELSE
    LET futuresCircuitBreakersLowerLimitPrice == ReadBytes(futuresCircuitBreakersUpperLimitPrice.rest, 11) IN IF ~futuresCircuitBreakersLowerLimitPrice.ok THEN Fail ELSE
    LET exercisePriceForDisplayingNotForTrading == ReadBytes(futuresCircuitBreakersLowerLimitPrice.rest, 18) IN IF ~exercisePriceForDisplayingNotForTrading.ok THEN Fail ELSE
    LET atmTypeCode == ReadBytes(exercisePriceForDisplayingNotForTrading.rest, 1) IN IF ~atmTypeCode.ok THEN Fail ELSE
    LET lastTradingDay == ReadBytes(atmTypeCode.rest, 1) IN IF ~lastTradingDay.ok THEN Fail ELSE
    LET dividendValueForSettlementPrice == ReadBytes(lastTradingDay.rest, 16) IN IF ~dividendValueForSettlementPrice.ok THEN Fail ELSE
    LET yesterdaysClosingPrice == ReadBytes(dividendValueForSettlementPrice.rest, 11) IN IF ~yesterdaysClosingPrice.ok THEN Fail ELSE
    LET yesterdaysClosingPriceTypeCode == ReadBytes(yesterdaysClosingPrice.rest, 1) IN IF ~yesterdaysClosingPriceTypeCode.ok THEN Fail ELSE
    LET previousDaysOpeningPrice == ReadBytes(yesterdaysClosingPriceTypeCode.rest, 11) IN IF ~previousDaysOpeningPrice.ok THEN Fail ELSE
    LET previousDaysHighPrice == ReadBytes(previousDaysOpeningPrice.rest, 11) IN IF ~previousDaysHighPrice.ok THEN Fail ELSE
    LET previousDaysLowPrice == ReadBytes(previousDaysHighPrice.rest, 11) IN IF ~previousDaysLowPrice.ok THEN Fail ELSE
    LET theFirstTradingDate == ReadBytes(previousDaysLowPrice.rest, 8) IN IF ~theFirstTradingDate.ok THEN Fail ELSE
    LET theLastTradingTime == ReadBytes(theFirstTradingDate.rest, 9) IN IF ~theLastTradingTime.ok THEN Fail ELSE
    LET settlementPriceTypeCode == ReadBytes(theLastTradingTime.rest, 2) IN IF ~settlementPriceTypeCode.ok THEN Fail ELSE
    LET disparateRatio == ReadBytes(settlementPriceTypeCode.rest, 13) IN IF ~disparateRatio.ok THEN Fail ELSE
    LET previousDaysOpenInterest == ReadBytes(disparateRatio.rest, 12) IN IF ~previousDaysOpenInterest.ok THEN Fail ELSE
    LET previousDaysBestAsk == ReadBytes(previousDaysOpenInterest.rest, 11) IN IF ~previousDaysBestAsk.ok THEN Fail ELSE
    LET previousDaysBestBid == ReadBytes(previousDaysBestAsk.rest, 11) IN IF ~previousDaysBestBid.ok THEN Fail ELSE
    LET impliedVolatility == ReadBytes(previousDaysBestBid.rest, 11) IN IF ~impliedVolatility.ok THEN Fail ELSE
    LET theHighestPremiumOfTheLifetime == ReadBytes(impliedVolatility.rest, 11) IN IF ~theHighestPremiumOfTheLifetime.ok THEN Fail ELSE
    LET theLowestPremiumOfTheLifetime == ReadBytes(theHighestPremiumOfTheLifetime.rest, 11) IN IF ~theLowestPremiumOfTheLifetime.ok THEN Fail ELSE
    LET theHighestPremiumInAYear == ReadBytes(theLowestPremiumOfTheLifetime.rest, 11) IN IF ~theHighestPremiumInAYear.ok THEN Fail ELSE
    LET theLowestPremiumInAYear == ReadBytes(theHighestPremiumInAYear.rest, 11) IN IF ~theLowestPremiumInAYear.ok THEN Fail ELSE
    LET theDateOfTheHighestPremiumOfTheLifetime == ReadBytes(theLowestPremiumInAYear.rest, 8) IN IF ~theDateOfTheHighestPremiumOfTheLifetime.ok THEN Fail ELSE
    LET theDateOfTheLowestPremiumOfTheLifetime == ReadBytes(theDateOfTheHighestPremiumOfTheLifetime.rest, 8) IN IF ~theDateOfTheLowestPremiumOfTheLifetime.ok THEN Fail ELSE
    LET theDateOfTheHighestPremiumInAYear == ReadBytes(theDateOfTheLowestPremiumOfTheLifetime.rest, 8) IN IF ~theDateOfTheHighestPremiumInAYear.ok THEN Fail ELSE
    LET theDateOfTheLowestPremiumInAYear == ReadBytes(theDateOfTheHighestPremiumInAYear.rest, 8) IN IF ~theDateOfTheLowestPremiumInAYear.ok THEN Fail ELSE
    LET numberOfListingDaysPerYear == ReadBytes(theDateOfTheLowestPremiumInAYear.rest, 8) IN IF ~numberOfListingDaysPerYear.ok THEN Fail ELSE
    LET numberOfTradingDaysPerMonth == ReadBytes(numberOfListingDaysPerYear.rest, 8) IN IF ~numberOfTradingDaysPerMonth.ok THEN Fail ELSE
    LET numberOfTradingDaysPerYear == ReadBytes(numberOfTradingDaysPerMonth.rest, 8) IN IF ~numberOfTradingDaysPerYear.ok THEN Fail ELSE
    LET numberOfPreviousDaysTrading == ReadBytes(numberOfTradingDaysPerYear.rest, 15) IN IF ~numberOfPreviousDaysTrading.ok THEN Fail ELSE
    LET yesterdaysAccumulatedTradingAmount == ReadBytes(numberOfPreviousDaysTrading.rest, 12) IN IF ~yesterdaysAccumulatedTradingAmount.ok THEN Fail ELSE
    LET yesterdaysAccumulatedTradingValue == ReadBytes(yesterdaysAccumulatedTradingAmount.rest, 22) IN IF ~yesterdaysAccumulatedTradingValue.ok THEN Fail ELSE
    LET previousDaysTotalAccumulatedTradingVolume == ReadBytes(yesterdaysAccumulatedTradingValue.rest, 15) IN IF ~previousDaysTotalAccumulatedTradingVolume.ok THEN Fail ELSE
    LET previousDaysTotalAccumulatedTradingValue == ReadBytes(previousDaysTotalAccumulatedTradingVolume.rest, 22) IN IF ~previousDaysTotalAccumulatedTradingValue.ok THEN Fail ELSE
    LET interestRate == ReadBytes(previousDaysTotalAccumulatedTradingValue.rest, 11) IN IF ~interestRate.ok THEN Fail ELSE
    LET openInterestLimitQuantity == ReadBytes(interestRate.rest, 15) IN IF ~openInterestLimitQuantity.ok THEN Fail ELSE
    LET underlyingAssetProductId == ReadBytes(openInterestLimitQuantity.rest, 4) IN IF ~underlyingAssetProductId.ok THEN Fail ELSE
    LET offsetRateOfAssetGroup == ReadBytes(underlyingAssetProductId.rest, 11) IN IF ~offsetRateOfAssetGroup.ok THEN Fail ELSE
    LET limitOrderPermissionTypeCode == ReadBytes(offsetRateOfAssetGroup.rest, 5) IN IF ~limitOrderPermissionTypeCode.ok THEN Fail ELSE
    LET marketPriceOrderPermissionTypeCode == ReadBytes(limitOrderPermissionTypeCode.rest, 5) IN IF ~marketPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET conditionedOrderPermissionTypeCode == ReadBytes(marketPriceOrderPermissionTypeCode.rest, 5) IN IF ~conditionedOrderPermissionTypeCode.ok THEN Fail ELSE
    LET bestFavorableOrderPermissionTypeCode == ReadBytes(conditionedOrderPermissionTypeCode.rest, 5) IN IF ~bestFavorableOrderPermissionTypeCode.ok THEN Fail ELSE
    LET efpTradingItem == ReadBytes(bestFavorableOrderPermissionTypeCode.rest, 1) IN IF ~efpTradingItem.ok THEN Fail ELSE
    LET flexTradingItem == ReadBytes(efpTradingItem.rest, 1) IN IF ~flexTradingItem.ok THEN Fail ELSE
    LET efpTradingVolume == ReadBytes(flexTradingItem.rest, 12) IN IF ~efpTradingVolume.ok THEN Fail ELSE
    LET efpTradingValue == ReadBytes(efpTradingVolume.rest, 22) IN IF ~efpTradingValue.ok THEN Fail ELSE
    LET marketHolidays == ReadBytes(efpTradingValue.rest, 1) IN IF ~marketHolidays.ok THEN Fail ELSE
    LET limitationOfDynamicPrice == ReadBytes(marketHolidays.rest, 1) IN IF ~limitationOfDynamicPrice.ok THEN Fail ELSE
    LET gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue == ReadBytes(limitationOfDynamicPrice.rest, 11) IN IF ~gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue.ok THEN Fail ELSE
    LET gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue == ReadBytes(gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue.rest, 11) IN IF ~gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue.ok THEN Fail ELSE
    LET underlyingAssetMarketId == ReadBytes(gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue.rest, 3) IN IF ~underlyingAssetMarketId.ok THEN Fail ELSE
    LET upperLimitQuantity == ReadBytes(underlyingAssetMarketId.rest, 23) IN IF ~upperLimitQuantity.ok THEN Fail ELSE
    LET lowerLimitQuantity == ReadBytes(upperLimitQuantity.rest, 23) IN IF ~lowerLimitQuantity.ok THEN Fail ELSE
    LET upperLimitQuantityForBlockTrade == ReadBytes(lowerLimitQuantity.rest, 23) IN IF ~upperLimitQuantityForBlockTrade.ok THEN Fail ELSE
    LET lowerLimitQuantityForBlockTrade == ReadBytes(upperLimitQuantityForBlockTrade.rest, 23) IN IF ~lowerLimitQuantityForBlockTrade.ok THEN Fail ELSE
    LET baseProductId == ReadBytes(lowerLimitQuantityForBlockTrade.rest, 11) IN IF ~baseProductId.ok THEN Fail ELSE
    LET subsidiaryProductId == ReadBytes(baseProductId.rest, 11) IN IF ~subsidiaryProductId.ok THEN Fail ELSE
    LET numberOfIssuesForBaseProduct == ReadBytes(subsidiaryProductId.rest, 6) IN IF ~numberOfIssuesForBaseProduct.ok THEN Fail ELSE
    LET numberOfIssuesForSubsidiaryProduct == ReadBytes(numberOfIssuesForBaseProduct.rest, 6) IN IF ~numberOfIssuesForSubsidiaryProduct.ok THEN Fail ELSE
    LET settlementWeek == ReadBytes(numberOfIssuesForSubsidiaryProduct.rest, 2) IN IF ~settlementWeek.ok THEN Fail ELSE
    LET suspendedStocks == ReadBytes(settlementWeek.rest, 1) IN IF ~suspendedStocks.ok THEN Fail ELSE
    LET designationDateForSuspendedStocks == ReadBytes(suspendedStocks.rest, 8) IN IF ~designationDateForSuspendedStocks.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(designationDateForSuspendedStocks.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                  |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract                  |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                                           |-> businessDate.value,
         isinCode                                               |-> isinCode.value,
         aDesignatedNumberForAnIssue                            |-> aDesignatedNumberForAnIssue.value,
         futuresOptionsTypeCode                                 |-> futuresOptionsTypeCode.value,
         productId                                              |-> productId.value,
         abbreviatedIssueCode                                   |-> abbreviatedIssueCode.value,
         issueName                                              |-> issueName.value,
         abbreviatedIssueName                                   |-> abbreviatedIssueName.value,
         englishIssueName                                       |-> englishIssueName.value,
         abbreviatedIssueNameInEn                               |-> abbreviatedIssueNameInEn.value,
         marketOperationProductId                               |-> marketOperationProductId.value,
         listingDate                                            |-> listingDate.value,
         delistingDate                                          |-> delistingDate.value,
         spreadTypeCode                                         |-> spreadTypeCode.value,
         paymentMethods                                         |-> paymentMethods.value,
         directionOfPriceLimitExpansionTypeCode                 |-> directionOfPriceLimitExpansionTypeCode.value,
         finalStageOfPriceLimitExpansion                        |-> finalStageOfPriceLimitExpansion.value,
         upperPriceLimit1StStage                                |-> upperPriceLimit1StStage.value,
         upperPriceLimit2NdStage                                |-> upperPriceLimit2NdStage.value,
         upperPriceLimit3RdStage                                |-> upperPriceLimit3RdStage.value,
         lowerPriceLimit1StStage                                |-> lowerPriceLimit1StStage.value,
         lowerPriceLimit2NdStage                                |-> lowerPriceLimit2NdStage.value,
         lowerPriceLimit3RdStage                                |-> lowerPriceLimit3RdStage.value,
         basePrice                                              |-> basePrice.value,
         underlyingAssetId                                      |-> underlyingAssetId.value,
         rightsExecutionTypeCode                                |-> rightsExecutionTypeCode.value,
         spreadCompositionCode                                  |-> spreadCompositionCode.value,
         spreadIssueIsin1                                       |-> spreadIssueIsin1.value,
         spreadIssueIsin2                                       |-> spreadIssueIsin2.value,
         lastTradingDate                                        |-> lastTradingDate.value,
         lastPaymentDate                                        |-> lastPaymentDate.value,
         sequenceNumberForDeliveryMonth                         |-> sequenceNumberForDeliveryMonth.value,
         expirationDate                                         |-> expirationDate.value,
         exercisePrice                                          |-> exercisePrice.value,
         basePriceAdjustmentTypeCode                            |-> basePriceAdjustmentTypeCode.value,
         tradingUnit                                            |-> tradingUnit.value,
         tradingMultiplier                                      |-> tradingMultiplier.value,
         typeOfLiquidityProvidingLp                             |-> typeOfLiquidityProvidingLp.value,
         listingTypeCode                                        |-> listingTypeCode.value,
         atm                                                    |-> atm.value,
         adjustmentReasonCode                                   |-> adjustmentReasonCode.value,
         isinOfUnderlyingAsset                                  |-> isinOfUnderlyingAsset.value,
         closingPriceOfUnderlyingAsset                          |-> closingPriceOfUnderlyingAsset.value,
         remainingDays                                          |-> remainingDays.value,
         adjustedBasePrice                                      |-> adjustedBasePrice.value,
         basePriceTypeCode                                      |-> basePriceTypeCode.value,
         basePriceForTradingTypeCode                            |-> basePriceForTradingTypeCode.value,
         previousDaysAdjustedClosingPrice                       |-> previousDaysAdjustedClosingPrice.value,
         blockTradingTypeCode                                   |-> blockTradingTypeCode.value,
         previousDaysBpmm                                       |-> previousDaysBpmm.value,
         basePriceOfClearingMarginsTypeCode                     |-> basePriceOfClearingMarginsTypeCode.value,
         theoreticalSettlementPrice                             |-> theoreticalSettlementPrice.value,
         baseTheoreticalPrice                                   |-> baseTheoreticalPrice.value,
         previousDaysSettlementPrice                            |-> previousDaysSettlementPrice.value,
         tradingHalt                                            |-> tradingHalt.value,
         futuresCircuitBreakersUpperLimitPrice                  |-> futuresCircuitBreakersUpperLimitPrice.value,
         futuresCircuitBreakersLowerLimitPrice                  |-> futuresCircuitBreakersLowerLimitPrice.value,
         exercisePriceForDisplayingNotForTrading                |-> exercisePriceForDisplayingNotForTrading.value,
         atmTypeCode                                            |-> atmTypeCode.value,
         lastTradingDay                                         |-> lastTradingDay.value,
         dividendValueForSettlementPrice                        |-> dividendValueForSettlementPrice.value,
         yesterdaysClosingPrice                                 |-> yesterdaysClosingPrice.value,
         yesterdaysClosingPriceTypeCode                         |-> yesterdaysClosingPriceTypeCode.value,
         previousDaysOpeningPrice                               |-> previousDaysOpeningPrice.value,
         previousDaysHighPrice                                  |-> previousDaysHighPrice.value,
         previousDaysLowPrice                                   |-> previousDaysLowPrice.value,
         theFirstTradingDate                                    |-> theFirstTradingDate.value,
         theLastTradingTime                                     |-> theLastTradingTime.value,
         settlementPriceTypeCode                                |-> settlementPriceTypeCode.value,
         disparateRatio                                         |-> disparateRatio.value,
         previousDaysOpenInterest                               |-> previousDaysOpenInterest.value,
         previousDaysBestAsk                                    |-> previousDaysBestAsk.value,
         previousDaysBestBid                                    |-> previousDaysBestBid.value,
         impliedVolatility                                      |-> impliedVolatility.value,
         theHighestPremiumOfTheLifetime                         |-> theHighestPremiumOfTheLifetime.value,
         theLowestPremiumOfTheLifetime                          |-> theLowestPremiumOfTheLifetime.value,
         theHighestPremiumInAYear                               |-> theHighestPremiumInAYear.value,
         theLowestPremiumInAYear                                |-> theLowestPremiumInAYear.value,
         theDateOfTheHighestPremiumOfTheLifetime                |-> theDateOfTheHighestPremiumOfTheLifetime.value,
         theDateOfTheLowestPremiumOfTheLifetime                 |-> theDateOfTheLowestPremiumOfTheLifetime.value,
         theDateOfTheHighestPremiumInAYear                      |-> theDateOfTheHighestPremiumInAYear.value,
         theDateOfTheLowestPremiumInAYear                       |-> theDateOfTheLowestPremiumInAYear.value,
         numberOfListingDaysPerYear                             |-> numberOfListingDaysPerYear.value,
         numberOfTradingDaysPerMonth                            |-> numberOfTradingDaysPerMonth.value,
         numberOfTradingDaysPerYear                             |-> numberOfTradingDaysPerYear.value,
         numberOfPreviousDaysTrading                            |-> numberOfPreviousDaysTrading.value,
         yesterdaysAccumulatedTradingAmount                     |-> yesterdaysAccumulatedTradingAmount.value,
         yesterdaysAccumulatedTradingValue                      |-> yesterdaysAccumulatedTradingValue.value,
         previousDaysTotalAccumulatedTradingVolume              |-> previousDaysTotalAccumulatedTradingVolume.value,
         previousDaysTotalAccumulatedTradingValue               |-> previousDaysTotalAccumulatedTradingValue.value,
         interestRate                                           |-> interestRate.value,
         openInterestLimitQuantity                              |-> openInterestLimitQuantity.value,
         underlyingAssetProductId                               |-> underlyingAssetProductId.value,
         offsetRateOfAssetGroup                                 |-> offsetRateOfAssetGroup.value,
         limitOrderPermissionTypeCode                           |-> limitOrderPermissionTypeCode.value,
         marketPriceOrderPermissionTypeCode                     |-> marketPriceOrderPermissionTypeCode.value,
         conditionedOrderPermissionTypeCode                     |-> conditionedOrderPermissionTypeCode.value,
         bestFavorableOrderPermissionTypeCode                   |-> bestFavorableOrderPermissionTypeCode.value,
         efpTradingItem                                         |-> efpTradingItem.value,
         flexTradingItem                                        |-> flexTradingItem.value,
         efpTradingVolume                                       |-> efpTradingVolume.value,
         efpTradingValue                                        |-> efpTradingValue.value,
         marketHolidays                                         |-> marketHolidays.value,
         limitationOfDynamicPrice                               |-> limitationOfDynamicPrice.value,
         gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue |-> gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue.value,
         gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue |-> gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue.value,
         underlyingAssetMarketId                                |-> underlyingAssetMarketId.value,
         upperLimitQuantity                                     |-> upperLimitQuantity.value,
         lowerLimitQuantity                                     |-> lowerLimitQuantity.value,
         upperLimitQuantityForBlockTrade                        |-> upperLimitQuantityForBlockTrade.value,
         lowerLimitQuantityForBlockTrade                        |-> lowerLimitQuantityForBlockTrade.value,
         baseProductId                                          |-> baseProductId.value,
         subsidiaryProductId                                    |-> subsidiaryProductId.value,
         numberOfIssuesForBaseProduct                           |-> numberOfIssuesForBaseProduct.value,
         numberOfIssuesForSubsidiaryProduct                     |-> numberOfIssuesForSubsidiaryProduct.value,
         settlementWeek                                         |-> settlementWeek.value,
         suspendedStocks                                        |-> suspendedStocks.value,
         designationDateForSuspendedStocks                      |-> designationDateForSuspendedStocks.value,
         endKeyword                                             |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesBatchDataMessage ==
    [ messageSequenceNumber                                  |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract                  |-> [i \in 1 .. 6 |-> 0],
      businessDate                                           |-> [i \in 1 .. 8 |-> 0],
      isinCode                                               |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue                            |-> [i \in 1 .. 6 |-> 0],
      futuresOptionsTypeCode                                 |-> [i \in 1 .. 1 |-> 0],
      productId                                              |-> [i \in 1 .. 11 |-> 0],
      abbreviatedIssueCode                                   |-> [i \in 1 .. 9 |-> 0],
      issueName                                              |-> [i \in 1 .. 80 |-> 0],
      abbreviatedIssueName                                   |-> [i \in 1 .. 40 |-> 0],
      englishIssueName                                       |-> [i \in 1 .. 80 |-> 0],
      abbreviatedIssueNameInEn                               |-> [i \in 1 .. 40 |-> 0],
      marketOperationProductId                               |-> [i \in 1 .. 3 |-> 0],
      listingDate                                            |-> [i \in 1 .. 8 |-> 0],
      delistingDate                                          |-> [i \in 1 .. 8 |-> 0],
      spreadTypeCode                                         |-> [i \in 1 .. 1 |-> 0],
      paymentMethods                                         |-> [i \in 1 .. 1 |-> 0],
      directionOfPriceLimitExpansionTypeCode                 |-> [i \in 1 .. 1 |-> 0],
      finalStageOfPriceLimitExpansion                        |-> [i \in 1 .. 3 |-> 0],
      upperPriceLimit1StStage                                |-> [i \in 1 .. 11 |-> 0],
      upperPriceLimit2NdStage                                |-> [i \in 1 .. 11 |-> 0],
      upperPriceLimit3RdStage                                |-> [i \in 1 .. 11 |-> 0],
      lowerPriceLimit1StStage                                |-> [i \in 1 .. 11 |-> 0],
      lowerPriceLimit2NdStage                                |-> [i \in 1 .. 11 |-> 0],
      lowerPriceLimit3RdStage                                |-> [i \in 1 .. 11 |-> 0],
      basePrice                                              |-> [i \in 1 .. 11 |-> 0],
      underlyingAssetId                                      |-> [i \in 1 .. 3 |-> 0],
      rightsExecutionTypeCode                                |-> [i \in 1 .. 1 |-> 0],
      spreadCompositionCode                                  |-> [i \in 1 .. 2 |-> 0],
      spreadIssueIsin1                                       |-> [i \in 1 .. 12 |-> 0],
      spreadIssueIsin2                                       |-> [i \in 1 .. 12 |-> 0],
      lastTradingDate                                        |-> [i \in 1 .. 8 |-> 0],
      lastPaymentDate                                        |-> [i \in 1 .. 8 |-> 0],
      sequenceNumberForDeliveryMonth                         |-> [i \in 1 .. 3 |-> 0],
      expirationDate                                         |-> [i \in 1 .. 8 |-> 0],
      exercisePrice                                          |-> [i \in 1 .. 18 |-> 0],
      basePriceAdjustmentTypeCode                            |-> [i \in 1 .. 1 |-> 0],
      tradingUnit                                            |-> [i \in 1 .. 22 |-> 0],
      tradingMultiplier                                      |-> [i \in 1 .. 22 |-> 0],
      typeOfLiquidityProvidingLp                             |-> [i \in 1 .. 1 |-> 0],
      listingTypeCode                                        |-> [i \in 1 .. 1 |-> 0],
      atm                                                    |-> [i \in 1 .. 11 |-> 0],
      adjustmentReasonCode                                   |-> [i \in 1 .. 2 |-> 0],
      isinOfUnderlyingAsset                                  |-> [i \in 1 .. 12 |-> 0],
      closingPriceOfUnderlyingAsset                          |-> [i \in 1 .. 11 |-> 0],
      remainingDays                                          |-> [i \in 1 .. 8 |-> 0],
      adjustedBasePrice                                      |-> [i \in 1 .. 18 |-> 0],
      basePriceTypeCode                                      |-> [i \in 1 .. 2 |-> 0],
      basePriceForTradingTypeCode                            |-> [i \in 1 .. 1 |-> 0],
      previousDaysAdjustedClosingPrice                       |-> [i \in 1 .. 18 |-> 0],
      blockTradingTypeCode                                   |-> [i \in 1 .. 1 |-> 0],
      previousDaysBpmm                                       |-> [i \in 1 .. 23 |-> 0],
      basePriceOfClearingMarginsTypeCode                     |-> [i \in 1 .. 2 |-> 0],
      theoreticalSettlementPrice                             |-> [i \in 1 .. 16 |-> 0],
      baseTheoreticalPrice                                   |-> [i \in 1 .. 16 |-> 0],
      previousDaysSettlementPrice                            |-> [i \in 1 .. 18 |-> 0],
      tradingHalt                                            |-> [i \in 1 .. 1 |-> 0],
      futuresCircuitBreakersUpperLimitPrice                  |-> [i \in 1 .. 11 |-> 0],
      futuresCircuitBreakersLowerLimitPrice                  |-> [i \in 1 .. 11 |-> 0],
      exercisePriceForDisplayingNotForTrading                |-> [i \in 1 .. 18 |-> 0],
      atmTypeCode                                            |-> [i \in 1 .. 1 |-> 0],
      lastTradingDay                                         |-> [i \in 1 .. 1 |-> 0],
      dividendValueForSettlementPrice                        |-> [i \in 1 .. 16 |-> 0],
      yesterdaysClosingPrice                                 |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPriceTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      previousDaysOpeningPrice                               |-> [i \in 1 .. 11 |-> 0],
      previousDaysHighPrice                                  |-> [i \in 1 .. 11 |-> 0],
      previousDaysLowPrice                                   |-> [i \in 1 .. 11 |-> 0],
      theFirstTradingDate                                    |-> [i \in 1 .. 8 |-> 0],
      theLastTradingTime                                     |-> [i \in 1 .. 9 |-> 0],
      settlementPriceTypeCode                                |-> [i \in 1 .. 2 |-> 0],
      disparateRatio                                         |-> [i \in 1 .. 13 |-> 0],
      previousDaysOpenInterest                               |-> [i \in 1 .. 12 |-> 0],
      previousDaysBestAsk                                    |-> [i \in 1 .. 11 |-> 0],
      previousDaysBestBid                                    |-> [i \in 1 .. 11 |-> 0],
      impliedVolatility                                      |-> [i \in 1 .. 11 |-> 0],
      theHighestPremiumOfTheLifetime                         |-> [i \in 1 .. 11 |-> 0],
      theLowestPremiumOfTheLifetime                          |-> [i \in 1 .. 11 |-> 0],
      theHighestPremiumInAYear                               |-> [i \in 1 .. 11 |-> 0],
      theLowestPremiumInAYear                                |-> [i \in 1 .. 11 |-> 0],
      theDateOfTheHighestPremiumOfTheLifetime                |-> [i \in 1 .. 8 |-> 0],
      theDateOfTheLowestPremiumOfTheLifetime                 |-> [i \in 1 .. 8 |-> 0],
      theDateOfTheHighestPremiumInAYear                      |-> [i \in 1 .. 8 |-> 0],
      theDateOfTheLowestPremiumInAYear                       |-> [i \in 1 .. 8 |-> 0],
      numberOfListingDaysPerYear                             |-> [i \in 1 .. 8 |-> 0],
      numberOfTradingDaysPerMonth                            |-> [i \in 1 .. 8 |-> 0],
      numberOfTradingDaysPerYear                             |-> [i \in 1 .. 8 |-> 0],
      numberOfPreviousDaysTrading                            |-> [i \in 1 .. 15 |-> 0],
      yesterdaysAccumulatedTradingAmount                     |-> [i \in 1 .. 12 |-> 0],
      yesterdaysAccumulatedTradingValue                      |-> [i \in 1 .. 22 |-> 0],
      previousDaysTotalAccumulatedTradingVolume              |-> [i \in 1 .. 15 |-> 0],
      previousDaysTotalAccumulatedTradingValue               |-> [i \in 1 .. 22 |-> 0],
      interestRate                                           |-> [i \in 1 .. 11 |-> 0],
      openInterestLimitQuantity                              |-> [i \in 1 .. 15 |-> 0],
      underlyingAssetProductId                               |-> [i \in 1 .. 4 |-> 0],
      offsetRateOfAssetGroup                                 |-> [i \in 1 .. 11 |-> 0],
      limitOrderPermissionTypeCode                           |-> [i \in 1 .. 5 |-> 0],
      marketPriceOrderPermissionTypeCode                     |-> [i \in 1 .. 5 |-> 0],
      conditionedOrderPermissionTypeCode                     |-> [i \in 1 .. 5 |-> 0],
      bestFavorableOrderPermissionTypeCode                   |-> [i \in 1 .. 5 |-> 0],
      efpTradingItem                                         |-> [i \in 1 .. 1 |-> 0],
      flexTradingItem                                        |-> [i \in 1 .. 1 |-> 0],
      efpTradingVolume                                       |-> [i \in 1 .. 12 |-> 0],
      efpTradingValue                                        |-> [i \in 1 .. 22 |-> 0],
      marketHolidays                                         |-> [i \in 1 .. 1 |-> 0],
      limitationOfDynamicPrice                               |-> [i \in 1 .. 1 |-> 0],
      gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue |-> [i \in 1 .. 11 |-> 0],
      gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue |-> [i \in 1 .. 11 |-> 0],
      underlyingAssetMarketId                                |-> [i \in 1 .. 3 |-> 0],
      upperLimitQuantity                                     |-> [i \in 1 .. 23 |-> 0],
      lowerLimitQuantity                                     |-> [i \in 1 .. 23 |-> 0],
      upperLimitQuantityForBlockTrade                        |-> [i \in 1 .. 23 |-> 0],
      lowerLimitQuantityForBlockTrade                        |-> [i \in 1 .. 23 |-> 0],
      baseProductId                                          |-> [i \in 1 .. 11 |-> 0],
      subsidiaryProductId                                    |-> [i \in 1 .. 11 |-> 0],
      numberOfIssuesForBaseProduct                           |-> [i \in 1 .. 6 |-> 0],
      numberOfIssuesForSubsidiaryProduct                     |-> [i \in 1 .. 6 |-> 0],
      settlementWeek                                         |-> [i \in 1 .. 2 |-> 0],
      suspendedStocks                                        |-> [i \in 1 .. 1 |-> 0],
      designationDateForSuspendedStocks                      |-> [i \in 1 .. 8 |-> 0],
      endKeyword                                             |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesBatchDataMessage ==
    { ZeroDerivativesBatchDataMessage }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.futuresOptionsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.issueName = one] : one \in Sample(80) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.englishIssueName = one] : one \in Sample(80) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.delistingDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.spreadTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.paymentMethods = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.directionOfPriceLimitExpansionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.finalStageOfPriceLimitExpansion = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.upperPriceLimit1StStage = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.upperPriceLimit2NdStage = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.upperPriceLimit3RdStage = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lowerPriceLimit1StStage = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lowerPriceLimit2NdStage = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lowerPriceLimit3RdStage = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.underlyingAssetId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.rightsExecutionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.spreadCompositionCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.spreadIssueIsin1 = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.spreadIssueIsin2 = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lastTradingDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lastPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.sequenceNumberForDeliveryMonth = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.exercisePrice = one] : one \in Sample(18) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.basePriceAdjustmentTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.tradingUnit = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.tradingMultiplier = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.typeOfLiquidityProvidingLp = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.listingTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.atm = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.adjustmentReasonCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.isinOfUnderlyingAsset = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.closingPriceOfUnderlyingAsset = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.remainingDays = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.adjustedBasePrice = one] : one \in Sample(18) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.basePriceTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.basePriceForTradingTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysAdjustedClosingPrice = one] : one \in Sample(18) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.blockTradingTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysBpmm = one] : one \in Sample(23) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.basePriceOfClearingMarginsTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theoreticalSettlementPrice = one] : one \in Sample(16) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.baseTheoreticalPrice = one] : one \in Sample(16) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysSettlementPrice = one] : one \in Sample(18) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.futuresCircuitBreakersUpperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.futuresCircuitBreakersLowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.exercisePriceForDisplayingNotForTrading = one] : one \in Sample(18) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.atmTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lastTradingDay = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.dividendValueForSettlementPrice = one] : one \in Sample(16) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.yesterdaysClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.yesterdaysClosingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysOpeningPrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysHighPrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysLowPrice = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theFirstTradingDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theLastTradingTime = one] : one \in Sample(9) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.settlementPriceTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.disparateRatio = one] : one \in Sample(13) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysOpenInterest = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysBestAsk = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysBestBid = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.impliedVolatility = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theHighestPremiumOfTheLifetime = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theLowestPremiumOfTheLifetime = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theHighestPremiumInAYear = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theLowestPremiumInAYear = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theDateOfTheHighestPremiumOfTheLifetime = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theDateOfTheLowestPremiumOfTheLifetime = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theDateOfTheHighestPremiumInAYear = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.theDateOfTheLowestPremiumInAYear = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.numberOfListingDaysPerYear = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.numberOfTradingDaysPerMonth = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.numberOfTradingDaysPerYear = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.numberOfPreviousDaysTrading = one] : one \in Sample(15) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.yesterdaysAccumulatedTradingAmount = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.yesterdaysAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysTotalAccumulatedTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.previousDaysTotalAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.interestRate = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.openInterestLimitQuantity = one] : one \in Sample(15) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.underlyingAssetProductId = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.offsetRateOfAssetGroup = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.limitOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.marketPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.conditionedOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.bestFavorableOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.efpTradingItem = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.flexTradingItem = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.efpTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.efpTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.marketHolidays = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.limitationOfDynamicPrice = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.gapBetweenUpperLimitPriceOfDynamicPriceAndTradingValue = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.gapBetweenLowerLimitPriceOfDynamicPriceAndTradingValue = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.underlyingAssetMarketId = one] : one \in Sample(3) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.upperLimitQuantity = one] : one \in Sample(23) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lowerLimitQuantity = one] : one \in Sample(23) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.upperLimitQuantityForBlockTrade = one] : one \in Sample(23) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.lowerLimitQuantityForBlockTrade = one] : one \in Sample(23) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.baseProductId = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.subsidiaryProductId = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.numberOfIssuesForBaseProduct = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.numberOfIssuesForSubsidiaryProduct = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.settlementWeek = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.suspendedStocks = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.designationDateForSuspendedStocks = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Equity Derivatives Adjustment Details Message: 151 bytes                *)
(***************************************************************************)

EquityDerivativesAdjustmentDetailsMessage ==
    [ messageSequenceNumber                                          : Sample(8),
      businessDate                                                   : Sample(8),
      isinCode                                                       : Sample(12),
      denominatorCoefficientOfAdjustment                             : Sample(18),
      numeratorAdjustmentOfCoefficient                               : Sample(18),
      tradingMultiplierBeforeAdjustment                              : Sample(22),
      tradingMultiplierAfterAdjustmentEquityOptions10                : Sample(22),
      exercisePriceBeforeAdjustment                                  : Sample(18),
      exercisePriceAfterAdjustment                                   : Sample(18),
      adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted : Sample(6),
      endKeyword                                                     : Sample(1) ]

EncodeEquityDerivativesAdjustmentDetailsMessage(message) ==
    message.messageSequenceNumber
        \o message.businessDate
        \o message.isinCode
        \o message.denominatorCoefficientOfAdjustment
        \o message.numeratorAdjustmentOfCoefficient
        \o message.tradingMultiplierBeforeAdjustment
        \o message.tradingMultiplierAfterAdjustmentEquityOptions10
        \o message.exercisePriceBeforeAdjustment
        \o message.exercisePriceAfterAdjustment
        \o message.adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted
        \o message.endKeyword

DecodeEquityDerivativesAdjustmentDetailsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET businessDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET denominatorCoefficientOfAdjustment == ReadBytes(isinCode.rest, 18) IN IF ~denominatorCoefficientOfAdjustment.ok THEN Fail ELSE
    LET numeratorAdjustmentOfCoefficient == ReadBytes(denominatorCoefficientOfAdjustment.rest, 18) IN IF ~numeratorAdjustmentOfCoefficient.ok THEN Fail ELSE
    LET tradingMultiplierBeforeAdjustment == ReadBytes(numeratorAdjustmentOfCoefficient.rest, 22) IN IF ~tradingMultiplierBeforeAdjustment.ok THEN Fail ELSE
    LET tradingMultiplierAfterAdjustmentEquityOptions10 == ReadBytes(tradingMultiplierBeforeAdjustment.rest, 22) IN IF ~tradingMultiplierAfterAdjustmentEquityOptions10.ok THEN Fail ELSE
    LET exercisePriceBeforeAdjustment == ReadBytes(tradingMultiplierAfterAdjustmentEquityOptions10.rest, 18) IN IF ~exercisePriceBeforeAdjustment.ok THEN Fail ELSE
    LET exercisePriceAfterAdjustment == ReadBytes(exercisePriceBeforeAdjustment.rest, 18) IN IF ~exercisePriceAfterAdjustment.ok THEN Fail ELSE
    LET adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted == ReadBytes(exercisePriceAfterAdjustment.rest, 6) IN IF ~adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                          |-> messageSequenceNumber.value,
         businessDate                                                   |-> businessDate.value,
         isinCode                                                       |-> isinCode.value,
         denominatorCoefficientOfAdjustment                             |-> denominatorCoefficientOfAdjustment.value,
         numeratorAdjustmentOfCoefficient                               |-> numeratorAdjustmentOfCoefficient.value,
         tradingMultiplierBeforeAdjustment                              |-> tradingMultiplierBeforeAdjustment.value,
         tradingMultiplierAfterAdjustmentEquityOptions10                |-> tradingMultiplierAfterAdjustmentEquityOptions10.value,
         exercisePriceBeforeAdjustment                                  |-> exercisePriceBeforeAdjustment.value,
         exercisePriceAfterAdjustment                                   |-> exercisePriceAfterAdjustment.value,
         adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted |-> adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted.value,
         endKeyword                                                     |-> endKeyword.value ], endKeyword.rest)

ZeroEquityDerivativesAdjustmentDetailsMessage ==
    [ messageSequenceNumber                                          |-> [i \in 1 .. 8 |-> 0],
      businessDate                                                   |-> [i \in 1 .. 8 |-> 0],
      isinCode                                                       |-> [i \in 1 .. 12 |-> 0],
      denominatorCoefficientOfAdjustment                             |-> [i \in 1 .. 18 |-> 0],
      numeratorAdjustmentOfCoefficient                               |-> [i \in 1 .. 18 |-> 0],
      tradingMultiplierBeforeAdjustment                              |-> [i \in 1 .. 22 |-> 0],
      tradingMultiplierAfterAdjustmentEquityOptions10                |-> [i \in 1 .. 22 |-> 0],
      exercisePriceBeforeAdjustment                                  |-> [i \in 1 .. 18 |-> 0],
      exercisePriceAfterAdjustment                                   |-> [i \in 1 .. 18 |-> 0],
      adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted |-> [i \in 1 .. 6 |-> 0],
      endKeyword                                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Equity Derivatives Adjustment Details Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityDerivativesAdjustmentDetailsMessage ==
    { ZeroEquityDerivativesAdjustmentDetailsMessage }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.denominatorCoefficientOfAdjustment = one] : one \in Sample(18) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.numeratorAdjustmentOfCoefficient = one] : one \in Sample(18) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.tradingMultiplierBeforeAdjustment = one] : one \in Sample(22) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.tradingMultiplierAfterAdjustmentEquityOptions10 = one] : one \in Sample(22) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.exercisePriceBeforeAdjustment = one] : one \in Sample(18) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.exercisePriceAfterAdjustment = one] : one \in Sample(18) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.adjustmentCoefficientOfOpenIntetestVolumesThatHaveBeenAdjusted = one] : one \in Sample(6) }
        \cup { [ZeroEquityDerivativesAdjustmentDetailsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Commodity Futures Settlement Reference Ktb Message: 66 bytes            *)
(***************************************************************************)

CommodityFuturesSettlementReferenceKtbMessage ==
    [ messageSequenceNumber     : Sample(8),
      applicationDate           : Sample(8),
      underlyingAssetId         : Sample(3),
      ktbIsin                   : Sample(12),
      isinOfBaseIssueForPayment : Sample(12),
      conversionFactor          : Sample(22),
      endKeyword                : Sample(1) ]

EncodeCommodityFuturesSettlementReferenceKtbMessage(message) ==
    message.messageSequenceNumber
        \o message.applicationDate
        \o message.underlyingAssetId
        \o message.ktbIsin
        \o message.isinOfBaseIssueForPayment
        \o message.conversionFactor
        \o message.endKeyword

DecodeCommodityFuturesSettlementReferenceKtbMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET applicationDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~applicationDate.ok THEN Fail ELSE
    LET underlyingAssetId == ReadBytes(applicationDate.rest, 3) IN IF ~underlyingAssetId.ok THEN Fail ELSE
    LET ktbIsin == ReadBytes(underlyingAssetId.rest, 12) IN IF ~ktbIsin.ok THEN Fail ELSE
    LET isinOfBaseIssueForPayment == ReadBytes(ktbIsin.rest, 12) IN IF ~isinOfBaseIssueForPayment.ok THEN Fail ELSE
    LET conversionFactor == ReadBytes(isinOfBaseIssueForPayment.rest, 22) IN IF ~conversionFactor.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(conversionFactor.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber     |-> messageSequenceNumber.value,
         applicationDate           |-> applicationDate.value,
         underlyingAssetId         |-> underlyingAssetId.value,
         ktbIsin                   |-> ktbIsin.value,
         isinOfBaseIssueForPayment |-> isinOfBaseIssueForPayment.value,
         conversionFactor          |-> conversionFactor.value,
         endKeyword                |-> endKeyword.value ], endKeyword.rest)

ZeroCommodityFuturesSettlementReferenceKtbMessage ==
    [ messageSequenceNumber     |-> [i \in 1 .. 8 |-> 0],
      applicationDate           |-> [i \in 1 .. 8 |-> 0],
      underlyingAssetId         |-> [i \in 1 .. 3 |-> 0],
      ktbIsin                   |-> [i \in 1 .. 12 |-> 0],
      isinOfBaseIssueForPayment |-> [i \in 1 .. 12 |-> 0],
      conversionFactor          |-> [i \in 1 .. 22 |-> 0],
      endKeyword                |-> [i \in 1 .. 1 |-> 0] ]

(* Commodity Futures Settlement Reference Ktb Message at zero, then each field in turn at the values it is checked at *)
CheckedCommodityFuturesSettlementReferenceKtbMessage ==
    { ZeroCommodityFuturesSettlementReferenceKtbMessage }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.applicationDate = one] : one \in Sample(8) }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.underlyingAssetId = one] : one \in Sample(3) }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.ktbIsin = one] : one \in Sample(12) }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.isinOfBaseIssueForPayment = one] : one \in Sample(12) }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.conversionFactor = one] : one \in Sample(22) }
        \cup { [ZeroCommodityFuturesSettlementReferenceKtbMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Investor Activities Message: 161 bytes                      *)
(***************************************************************************)

DerivativesInvestorActivitiesMessage ==
    [ date                      : Sample(8),
      calculationTimeActivities : Sample(6),
      transactionStatusTypeCode : Sample(2),
      productId                 : Sample(11),
      futuresOptionsTypeCode    : Sample(1),
      investorCode              : Sample(4),
      bidTradingVolume          : Sample(10),
      askTradingVolume          : Sample(10),
      bidTradingValue           : Sample(22),
      askTradingValue           : Sample(22),
      spreadBidTradingVolume    : Sample(10),
      spreadAskTradingVolume    : Sample(10),
      spreadBidTradingValue     : Sample(22),
      spreadAskTradingValue     : Sample(22),
      endKeyword                : Sample(1) ]

EncodeDerivativesInvestorActivitiesMessage(message) ==
    message.date
        \o message.calculationTimeActivities
        \o message.transactionStatusTypeCode
        \o message.productId
        \o message.futuresOptionsTypeCode
        \o message.investorCode
        \o message.bidTradingVolume
        \o message.askTradingVolume
        \o message.bidTradingValue
        \o message.askTradingValue
        \o message.spreadBidTradingVolume
        \o message.spreadAskTradingVolume
        \o message.spreadBidTradingValue
        \o message.spreadAskTradingValue
        \o message.endKeyword

DecodeDerivativesInvestorActivitiesMessage(bytes) ==
    LET date == ReadBytes(bytes, 8) IN IF ~date.ok THEN Fail ELSE
    LET calculationTimeActivities == ReadBytes(date.rest, 6) IN IF ~calculationTimeActivities.ok THEN Fail ELSE
    LET transactionStatusTypeCode == ReadBytes(calculationTimeActivities.rest, 2) IN IF ~transactionStatusTypeCode.ok THEN Fail ELSE
    LET productId == ReadBytes(transactionStatusTypeCode.rest, 11) IN IF ~productId.ok THEN Fail ELSE
    LET futuresOptionsTypeCode == ReadBytes(productId.rest, 1) IN IF ~futuresOptionsTypeCode.ok THEN Fail ELSE
    LET investorCode == ReadBytes(futuresOptionsTypeCode.rest, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET bidTradingVolume == ReadBytes(investorCode.rest, 10) IN IF ~bidTradingVolume.ok THEN Fail ELSE
    LET askTradingVolume == ReadBytes(bidTradingVolume.rest, 10) IN IF ~askTradingVolume.ok THEN Fail ELSE
    LET bidTradingValue == ReadBytes(askTradingVolume.rest, 22) IN IF ~bidTradingValue.ok THEN Fail ELSE
    LET askTradingValue == ReadBytes(bidTradingValue.rest, 22) IN IF ~askTradingValue.ok THEN Fail ELSE
    LET spreadBidTradingVolume == ReadBytes(askTradingValue.rest, 10) IN IF ~spreadBidTradingVolume.ok THEN Fail ELSE
    LET spreadAskTradingVolume == ReadBytes(spreadBidTradingVolume.rest, 10) IN IF ~spreadAskTradingVolume.ok THEN Fail ELSE
    LET spreadBidTradingValue == ReadBytes(spreadAskTradingVolume.rest, 22) IN IF ~spreadBidTradingValue.ok THEN Fail ELSE
    LET spreadAskTradingValue == ReadBytes(spreadBidTradingValue.rest, 22) IN IF ~spreadAskTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(spreadAskTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ date                      |-> date.value,
         calculationTimeActivities |-> calculationTimeActivities.value,
         transactionStatusTypeCode |-> transactionStatusTypeCode.value,
         productId                 |-> productId.value,
         futuresOptionsTypeCode    |-> futuresOptionsTypeCode.value,
         investorCode              |-> investorCode.value,
         bidTradingVolume          |-> bidTradingVolume.value,
         askTradingVolume          |-> askTradingVolume.value,
         bidTradingValue           |-> bidTradingValue.value,
         askTradingValue           |-> askTradingValue.value,
         spreadBidTradingVolume    |-> spreadBidTradingVolume.value,
         spreadAskTradingVolume    |-> spreadAskTradingVolume.value,
         spreadBidTradingValue     |-> spreadBidTradingValue.value,
         spreadAskTradingValue     |-> spreadAskTradingValue.value,
         endKeyword                |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesInvestorActivitiesMessage ==
    [ date                      |-> [i \in 1 .. 8 |-> 0],
      calculationTimeActivities |-> [i \in 1 .. 6 |-> 0],
      transactionStatusTypeCode |-> [i \in 1 .. 2 |-> 0],
      productId                 |-> [i \in 1 .. 11 |-> 0],
      futuresOptionsTypeCode    |-> [i \in 1 .. 1 |-> 0],
      investorCode              |-> [i \in 1 .. 4 |-> 0],
      bidTradingVolume          |-> [i \in 1 .. 10 |-> 0],
      askTradingVolume          |-> [i \in 1 .. 10 |-> 0],
      bidTradingValue           |-> [i \in 1 .. 22 |-> 0],
      askTradingValue           |-> [i \in 1 .. 22 |-> 0],
      spreadBidTradingVolume    |-> [i \in 1 .. 10 |-> 0],
      spreadAskTradingVolume    |-> [i \in 1 .. 10 |-> 0],
      spreadBidTradingValue     |-> [i \in 1 .. 22 |-> 0],
      spreadAskTradingValue     |-> [i \in 1 .. 22 |-> 0],
      endKeyword                |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Investor Activities Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesInvestorActivitiesMessage ==
    { ZeroDerivativesInvestorActivitiesMessage }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.calculationTimeActivities = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.transactionStatusTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.futuresOptionsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.bidTradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.askTradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.bidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.askTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.spreadBidTradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.spreadAskTradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.spreadBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.spreadAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroDerivativesInvestorActivitiesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivatives Open Interest Message: 39 bytes                             *)
(***************************************************************************)

DerivativesOpenInterestMessage ==
    [ isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      openInterestTypeCode        : Sample(2),
      tradingDate                 : Sample(8),
      openInterest                : Sample(10),
      endKeyword                  : Sample(1) ]

EncodeDerivativesOpenInterestMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.openInterestTypeCode
        \o message.tradingDate
        \o message.openInterest
        \o message.endKeyword

DecodeDerivativesOpenInterestMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET openInterestTypeCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 2) IN IF ~openInterestTypeCode.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(openInterestTypeCode.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET openInterest == ReadBytes(tradingDate.rest, 10) IN IF ~openInterest.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(openInterest.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         openInterestTypeCode        |-> openInterestTypeCode.value,
         tradingDate                 |-> tradingDate.value,
         openInterest                |-> openInterest.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroDerivativesOpenInterestMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      openInterestTypeCode        |-> [i \in 1 .. 2 |-> 0],
      tradingDate                 |-> [i \in 1 .. 8 |-> 0],
      openInterest                |-> [i \in 1 .. 10 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesOpenInterestMessage ==
    { ZeroDerivativesOpenInterestMessage }
        \cup { [ZeroDerivativesOpenInterestMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroDerivativesOpenInterestMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroDerivativesOpenInterestMessage EXCEPT !.openInterestTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroDerivativesOpenInterestMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(10) }
        \cup { [ZeroDerivativesOpenInterestMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Futures Settled Price Message: 58 bytes                                 *)
(***************************************************************************)

FuturesSettledPriceMessage ==
    [ isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      settlementPrice             : Sample(18),
      settlementPriceTypeCode     : Sample(2),
      theLastSettlementPrice      : Sample(18),
      lastSettlementPriceTypeCode : Sample(1),
      endKeyword                  : Sample(1) ]

EncodeFuturesSettledPriceMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.settlementPrice
        \o message.settlementPriceTypeCode
        \o message.theLastSettlementPrice
        \o message.lastSettlementPriceTypeCode
        \o message.endKeyword

DecodeFuturesSettledPriceMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 18) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceTypeCode == ReadBytes(settlementPrice.rest, 2) IN IF ~settlementPriceTypeCode.ok THEN Fail ELSE
    LET theLastSettlementPrice == ReadBytes(settlementPriceTypeCode.rest, 18) IN IF ~theLastSettlementPrice.ok THEN Fail ELSE
    LET lastSettlementPriceTypeCode == ReadBytes(theLastSettlementPrice.rest, 1) IN IF ~lastSettlementPriceTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(lastSettlementPriceTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         settlementPrice             |-> settlementPrice.value,
         settlementPriceTypeCode     |-> settlementPriceTypeCode.value,
         theLastSettlementPrice      |-> theLastSettlementPrice.value,
         lastSettlementPriceTypeCode |-> lastSettlementPriceTypeCode.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroFuturesSettledPriceMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      settlementPrice             |-> [i \in 1 .. 18 |-> 0],
      settlementPriceTypeCode     |-> [i \in 1 .. 2 |-> 0],
      theLastSettlementPrice      |-> [i \in 1 .. 18 |-> 0],
      lastSettlementPriceTypeCode |-> [i \in 1 .. 1 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Settled Price Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesSettledPriceMessage ==
    { ZeroFuturesSettledPriceMessage }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.settlementPrice = one] : one \in Sample(18) }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.settlementPriceTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.theLastSettlementPrice = one] : one \in Sample(18) }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.lastSettlementPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSettledPriceMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Base Price Of Clearing Margins Message: 58 bytes                *)
(***************************************************************************)

OptionsBasePriceOfClearingMarginsMessage ==
    [ isinCode                                         : Sample(12),
      aDesignatedNumberForAnIssue                      : Sample(6),
      basePriceOfClearingMargins                       : Sample(18),
      basePriceOfClearingMarginsTypeCode               : Sample(2),
      settlementPriceAfterExercisingAnOption           : Sample(18),
      typeCodeOfSettlementPriceAfterExercisingAnOption : Sample(1),
      endKeyword                                       : Sample(1) ]

EncodeOptionsBasePriceOfClearingMarginsMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.basePriceOfClearingMargins
        \o message.basePriceOfClearingMarginsTypeCode
        \o message.settlementPriceAfterExercisingAnOption
        \o message.typeCodeOfSettlementPriceAfterExercisingAnOption
        \o message.endKeyword

DecodeOptionsBasePriceOfClearingMarginsMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET basePriceOfClearingMargins == ReadBytes(aDesignatedNumberForAnIssue.rest, 18) IN IF ~basePriceOfClearingMargins.ok THEN Fail ELSE
    LET basePriceOfClearingMarginsTypeCode == ReadBytes(basePriceOfClearingMargins.rest, 2) IN IF ~basePriceOfClearingMarginsTypeCode.ok THEN Fail ELSE
    LET settlementPriceAfterExercisingAnOption == ReadBytes(basePriceOfClearingMarginsTypeCode.rest, 18) IN IF ~settlementPriceAfterExercisingAnOption.ok THEN Fail ELSE
    LET typeCodeOfSettlementPriceAfterExercisingAnOption == ReadBytes(settlementPriceAfterExercisingAnOption.rest, 1) IN IF ~typeCodeOfSettlementPriceAfterExercisingAnOption.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(typeCodeOfSettlementPriceAfterExercisingAnOption.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                                         |-> isinCode.value,
         aDesignatedNumberForAnIssue                      |-> aDesignatedNumberForAnIssue.value,
         basePriceOfClearingMargins                       |-> basePriceOfClearingMargins.value,
         basePriceOfClearingMarginsTypeCode               |-> basePriceOfClearingMarginsTypeCode.value,
         settlementPriceAfterExercisingAnOption           |-> settlementPriceAfterExercisingAnOption.value,
         typeCodeOfSettlementPriceAfterExercisingAnOption |-> typeCodeOfSettlementPriceAfterExercisingAnOption.value,
         endKeyword                                       |-> endKeyword.value ], endKeyword.rest)

ZeroOptionsBasePriceOfClearingMarginsMessage ==
    [ isinCode                                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue                      |-> [i \in 1 .. 6 |-> 0],
      basePriceOfClearingMargins                       |-> [i \in 1 .. 18 |-> 0],
      basePriceOfClearingMarginsTypeCode               |-> [i \in 1 .. 2 |-> 0],
      settlementPriceAfterExercisingAnOption           |-> [i \in 1 .. 18 |-> 0],
      typeCodeOfSettlementPriceAfterExercisingAnOption |-> [i \in 1 .. 1 |-> 0],
      endKeyword                                       |-> [i \in 1 .. 1 |-> 0] ]

(* Options Base Price Of Clearing Margins Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsBasePriceOfClearingMarginsMessage ==
    { ZeroOptionsBasePriceOfClearingMarginsMessage }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.basePriceOfClearingMargins = one] : one \in Sample(18) }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.basePriceOfClearingMarginsTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.settlementPriceAfterExercisingAnOption = one] : one \in Sample(18) }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.typeCodeOfSettlementPriceAfterExercisingAnOption = one] : one \in Sample(1) }
        \cup { [ZeroOptionsBasePriceOfClearingMarginsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Implied Volatility Message: 45 bytes                            *)
(***************************************************************************)

OptionsImpliedVolatilityMessage ==
    [ callAveragedImpliedVolatility   : Sample(11),
      putAveragedImpliedVolatility    : Sample(11),
      representativeImpliedVolatility : Sample(11),
      historicalVolatility90Days      : Sample(11),
      endKeyword                      : Sample(1) ]

EncodeOptionsImpliedVolatilityMessage(message) ==
    message.callAveragedImpliedVolatility
        \o message.putAveragedImpliedVolatility
        \o message.representativeImpliedVolatility
        \o message.historicalVolatility90Days
        \o message.endKeyword

DecodeOptionsImpliedVolatilityMessage(bytes) ==
    LET callAveragedImpliedVolatility == ReadBytes(bytes, 11) IN IF ~callAveragedImpliedVolatility.ok THEN Fail ELSE
    LET putAveragedImpliedVolatility == ReadBytes(callAveragedImpliedVolatility.rest, 11) IN IF ~putAveragedImpliedVolatility.ok THEN Fail ELSE
    LET representativeImpliedVolatility == ReadBytes(putAveragedImpliedVolatility.rest, 11) IN IF ~representativeImpliedVolatility.ok THEN Fail ELSE
    LET historicalVolatility90Days == ReadBytes(representativeImpliedVolatility.rest, 11) IN IF ~historicalVolatility90Days.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(historicalVolatility90Days.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ callAveragedImpliedVolatility   |-> callAveragedImpliedVolatility.value,
         putAveragedImpliedVolatility    |-> putAveragedImpliedVolatility.value,
         representativeImpliedVolatility |-> representativeImpliedVolatility.value,
         historicalVolatility90Days      |-> historicalVolatility90Days.value,
         endKeyword                      |-> endKeyword.value ], endKeyword.rest)

ZeroOptionsImpliedVolatilityMessage ==
    [ callAveragedImpliedVolatility   |-> [i \in 1 .. 11 |-> 0],
      putAveragedImpliedVolatility    |-> [i \in 1 .. 11 |-> 0],
      representativeImpliedVolatility |-> [i \in 1 .. 11 |-> 0],
      historicalVolatility90Days      |-> [i \in 1 .. 11 |-> 0],
      endKeyword                      |-> [i \in 1 .. 1 |-> 0] ]

(* Options Implied Volatility Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsImpliedVolatilityMessage ==
    { ZeroOptionsImpliedVolatilityMessage }
        \cup { [ZeroOptionsImpliedVolatilityMessage EXCEPT !.callAveragedImpliedVolatility = one] : one \in Sample(11) }
        \cup { [ZeroOptionsImpliedVolatilityMessage EXCEPT !.putAveragedImpliedVolatility = one] : one \in Sample(11) }
        \cup { [ZeroOptionsImpliedVolatilityMessage EXCEPT !.representativeImpliedVolatility = one] : one \in Sample(11) }
        \cup { [ZeroOptionsImpliedVolatilityMessage EXCEPT !.historicalVolatility90Days = one] : one \in Sample(11) }
        \cup { [ZeroOptionsImpliedVolatilityMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Sensitivity Message: 140 bytes                                  *)
(***************************************************************************)

OptionsSensitivityMessage ==
    [ isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      calculatingDate             : Sample(8),
      calculationTimeSensitivity  : Sample(9),
      impliedVolatilityTypeCode   : Sample(1),
      underlyingAssetId           : Sample(3),
      sensitivityDelta            : Sample(20),
      sensitivityTheta            : Sample(20),
      sensitivityVega             : Sample(20),
      sensitivityGamma            : Sample(20),
      sensitivityRho              : Sample(20),
      endKeyword                  : Sample(1) ]

EncodeOptionsSensitivityMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.calculatingDate
        \o message.calculationTimeSensitivity
        \o message.impliedVolatilityTypeCode
        \o message.underlyingAssetId
        \o message.sensitivityDelta
        \o message.sensitivityTheta
        \o message.sensitivityVega
        \o message.sensitivityGamma
        \o message.sensitivityRho
        \o message.endKeyword

DecodeOptionsSensitivityMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET calculatingDate == ReadBytes(aDesignatedNumberForAnIssue.rest, 8) IN IF ~calculatingDate.ok THEN Fail ELSE
    LET calculationTimeSensitivity == ReadBytes(calculatingDate.rest, 9) IN IF ~calculationTimeSensitivity.ok THEN Fail ELSE
    LET impliedVolatilityTypeCode == ReadBytes(calculationTimeSensitivity.rest, 1) IN IF ~impliedVolatilityTypeCode.ok THEN Fail ELSE
    LET underlyingAssetId == ReadBytes(impliedVolatilityTypeCode.rest, 3) IN IF ~underlyingAssetId.ok THEN Fail ELSE
    LET sensitivityDelta == ReadBytes(underlyingAssetId.rest, 20) IN IF ~sensitivityDelta.ok THEN Fail ELSE
    LET sensitivityTheta == ReadBytes(sensitivityDelta.rest, 20) IN IF ~sensitivityTheta.ok THEN Fail ELSE
    LET sensitivityVega == ReadBytes(sensitivityTheta.rest, 20) IN IF ~sensitivityVega.ok THEN Fail ELSE
    LET sensitivityGamma == ReadBytes(sensitivityVega.rest, 20) IN IF ~sensitivityGamma.ok THEN Fail ELSE
    LET sensitivityRho == ReadBytes(sensitivityGamma.rest, 20) IN IF ~sensitivityRho.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(sensitivityRho.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         calculatingDate             |-> calculatingDate.value,
         calculationTimeSensitivity  |-> calculationTimeSensitivity.value,
         impliedVolatilityTypeCode   |-> impliedVolatilityTypeCode.value,
         underlyingAssetId           |-> underlyingAssetId.value,
         sensitivityDelta            |-> sensitivityDelta.value,
         sensitivityTheta            |-> sensitivityTheta.value,
         sensitivityVega             |-> sensitivityVega.value,
         sensitivityGamma            |-> sensitivityGamma.value,
         sensitivityRho              |-> sensitivityRho.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroOptionsSensitivityMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      calculatingDate             |-> [i \in 1 .. 8 |-> 0],
      calculationTimeSensitivity  |-> [i \in 1 .. 9 |-> 0],
      impliedVolatilityTypeCode   |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetId           |-> [i \in 1 .. 3 |-> 0],
      sensitivityDelta            |-> [i \in 1 .. 20 |-> 0],
      sensitivityTheta            |-> [i \in 1 .. 20 |-> 0],
      sensitivityVega             |-> [i \in 1 .. 20 |-> 0],
      sensitivityGamma            |-> [i \in 1 .. 20 |-> 0],
      sensitivityRho              |-> [i \in 1 .. 20 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Options Sensitivity Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsSensitivityMessage ==
    { ZeroOptionsSensitivityMessage }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.calculatingDate = one] : one \in Sample(8) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.calculationTimeSensitivity = one] : one \in Sample(9) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.impliedVolatilityTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.underlyingAssetId = one] : one \in Sample(3) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.sensitivityDelta = one] : one \in Sample(20) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.sensitivityTheta = one] : one \in Sample(20) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.sensitivityVega = one] : one \in Sample(20) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.sensitivityGamma = one] : one \in Sample(20) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.sensitivityRho = one] : one \in Sample(20) }
        \cup { [ZeroOptionsSensitivityMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Commodity Futures Spot Settlement Reference Message: 55 bytes           *)
(***************************************************************************)

CommodityFuturesSpotSettlementReferenceMessage ==
    [ bisAnnouncementDate         : Sample(8),
      bisAnnouncementTime         : Sample(6),
      underlyingAssetId           : Sample(3),
      bisYieldRatio               : Sample(9),
      isinOfBaseIssueForPayment   : Sample(12),
      ktbIsin                     : Sample(12),
      bisTimeOfInputtingYieldRate : Sample(4),
      endKeyword                  : Sample(1) ]

EncodeCommodityFuturesSpotSettlementReferenceMessage(message) ==
    message.bisAnnouncementDate
        \o message.bisAnnouncementTime
        \o message.underlyingAssetId
        \o message.bisYieldRatio
        \o message.isinOfBaseIssueForPayment
        \o message.ktbIsin
        \o message.bisTimeOfInputtingYieldRate
        \o message.endKeyword

DecodeCommodityFuturesSpotSettlementReferenceMessage(bytes) ==
    LET bisAnnouncementDate == ReadBytes(bytes, 8) IN IF ~bisAnnouncementDate.ok THEN Fail ELSE
    LET bisAnnouncementTime == ReadBytes(bisAnnouncementDate.rest, 6) IN IF ~bisAnnouncementTime.ok THEN Fail ELSE
    LET underlyingAssetId == ReadBytes(bisAnnouncementTime.rest, 3) IN IF ~underlyingAssetId.ok THEN Fail ELSE
    LET bisYieldRatio == ReadBytes(underlyingAssetId.rest, 9) IN IF ~bisYieldRatio.ok THEN Fail ELSE
    LET isinOfBaseIssueForPayment == ReadBytes(bisYieldRatio.rest, 12) IN IF ~isinOfBaseIssueForPayment.ok THEN Fail ELSE
    LET ktbIsin == ReadBytes(isinOfBaseIssueForPayment.rest, 12) IN IF ~ktbIsin.ok THEN Fail ELSE
    LET bisTimeOfInputtingYieldRate == ReadBytes(ktbIsin.rest, 4) IN IF ~bisTimeOfInputtingYieldRate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bisTimeOfInputtingYieldRate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ bisAnnouncementDate         |-> bisAnnouncementDate.value,
         bisAnnouncementTime         |-> bisAnnouncementTime.value,
         underlyingAssetId           |-> underlyingAssetId.value,
         bisYieldRatio               |-> bisYieldRatio.value,
         isinOfBaseIssueForPayment   |-> isinOfBaseIssueForPayment.value,
         ktbIsin                     |-> ktbIsin.value,
         bisTimeOfInputtingYieldRate |-> bisTimeOfInputtingYieldRate.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroCommodityFuturesSpotSettlementReferenceMessage ==
    [ bisAnnouncementDate         |-> [i \in 1 .. 8 |-> 0],
      bisAnnouncementTime         |-> [i \in 1 .. 6 |-> 0],
      underlyingAssetId           |-> [i \in 1 .. 3 |-> 0],
      bisYieldRatio               |-> [i \in 1 .. 9 |-> 0],
      isinOfBaseIssueForPayment   |-> [i \in 1 .. 12 |-> 0],
      ktbIsin                     |-> [i \in 1 .. 12 |-> 0],
      bisTimeOfInputtingYieldRate |-> [i \in 1 .. 4 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Commodity Futures Spot Settlement Reference Message at zero, then each field in turn at the values it is checked at *)
CheckedCommodityFuturesSpotSettlementReferenceMessage ==
    { ZeroCommodityFuturesSpotSettlementReferenceMessage }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.bisAnnouncementDate = one] : one \in Sample(8) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.bisAnnouncementTime = one] : one \in Sample(6) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.underlyingAssetId = one] : one \in Sample(3) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.bisYieldRatio = one] : one \in Sample(9) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.isinOfBaseIssueForPayment = one] : one \in Sample(12) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.ktbIsin = one] : one \in Sample(12) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.bisTimeOfInputtingYieldRate = one] : one \in Sample(4) }
        \cup { [ZeroCommodityFuturesSpotSettlementReferenceMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Daily Disclosed Rfr Message: 82 bytes                                   *)
(***************************************************************************)

DailyDisclosedRfrMessage ==
    [ baseDate            : Sample(8),
      disclosureType      : Sample(2),
      disclosureDate      : Sample(14),
      rfr                 : Sample(9),
      indexedInterestRate : Sample(12),
      interestRate30Day   : Sample(12),
      interestRate90Day   : Sample(12),
      interestRate180Day  : Sample(12),
      endKeyword          : Sample(1) ]

EncodeDailyDisclosedRfrMessage(message) ==
    message.baseDate
        \o message.disclosureType
        \o message.disclosureDate
        \o message.rfr
        \o message.indexedInterestRate
        \o message.interestRate30Day
        \o message.interestRate90Day
        \o message.interestRate180Day
        \o message.endKeyword

DecodeDailyDisclosedRfrMessage(bytes) ==
    LET baseDate == ReadBytes(bytes, 8) IN IF ~baseDate.ok THEN Fail ELSE
    LET disclosureType == ReadBytes(baseDate.rest, 2) IN IF ~disclosureType.ok THEN Fail ELSE
    LET disclosureDate == ReadBytes(disclosureType.rest, 14) IN IF ~disclosureDate.ok THEN Fail ELSE
    LET rfr == ReadBytes(disclosureDate.rest, 9) IN IF ~rfr.ok THEN Fail ELSE
    LET indexedInterestRate == ReadBytes(rfr.rest, 12) IN IF ~indexedInterestRate.ok THEN Fail ELSE
    LET interestRate30Day == ReadBytes(indexedInterestRate.rest, 12) IN IF ~interestRate30Day.ok THEN Fail ELSE
    LET interestRate90Day == ReadBytes(interestRate30Day.rest, 12) IN IF ~interestRate90Day.ok THEN Fail ELSE
    LET interestRate180Day == ReadBytes(interestRate90Day.rest, 12) IN IF ~interestRate180Day.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(interestRate180Day.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ baseDate            |-> baseDate.value,
         disclosureType      |-> disclosureType.value,
         disclosureDate      |-> disclosureDate.value,
         rfr                 |-> rfr.value,
         indexedInterestRate |-> indexedInterestRate.value,
         interestRate30Day   |-> interestRate30Day.value,
         interestRate90Day   |-> interestRate90Day.value,
         interestRate180Day  |-> interestRate180Day.value,
         endKeyword          |-> endKeyword.value ], endKeyword.rest)

ZeroDailyDisclosedRfrMessage ==
    [ baseDate            |-> [i \in 1 .. 8 |-> 0],
      disclosureType      |-> [i \in 1 .. 2 |-> 0],
      disclosureDate      |-> [i \in 1 .. 14 |-> 0],
      rfr                 |-> [i \in 1 .. 9 |-> 0],
      indexedInterestRate |-> [i \in 1 .. 12 |-> 0],
      interestRate30Day   |-> [i \in 1 .. 12 |-> 0],
      interestRate90Day   |-> [i \in 1 .. 12 |-> 0],
      interestRate180Day  |-> [i \in 1 .. 12 |-> 0],
      endKeyword          |-> [i \in 1 .. 1 |-> 0] ]

(* Daily Disclosed Rfr Message at zero, then each field in turn at the values it is checked at *)
CheckedDailyDisclosedRfrMessage ==
    { ZeroDailyDisclosedRfrMessage }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.baseDate = one] : one \in Sample(8) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.disclosureType = one] : one \in Sample(2) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.disclosureDate = one] : one \in Sample(14) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.rfr = one] : one \in Sample(9) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.indexedInterestRate = one] : one \in Sample(12) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.interestRate30Day = one] : one \in Sample(12) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.interestRate90Day = one] : one \in Sample(12) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.interestRate180Day = one] : one \in Sample(12) }
        \cup { [ZeroDailyDisclosedRfrMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Tr Code                                            *)
(***************************************************************************)

PollingDataMessageCode == <<73, 50, 48, 48, 48>>  \* "I2000"
DerivativesQuoteFiveLevelsMessageCode == <<66, 54, 48, 49, 86>>  \* "B601V"
DerivativesQuoteFiveLevelsMessageCode2 == <<66, 54, 48, 50, 86>>  \* "B602V"
DerivativesQuoteFiveLevelsMessageCode3 == <<66, 54, 48, 51, 86>>  \* "B603V"
DerivativesQuoteFiveLevelsMessageCode4 == <<66, 54, 48, 54, 86>>  \* "B606V"
DerivativesQuoteFiveLevelsMessageCode5 == <<66, 54, 48, 55, 86>>  \* "B607V"
DerivativesQuoteFiveLevelsMessageCode6 == <<66, 54, 48, 56, 86>>  \* "B608V"
DerivativesQuoteFiveLevelsMessageCode7 == <<66, 54, 48, 57, 86>>  \* "B609V"
DerivativesQuoteFiveLevelsMessageCode8 == <<66, 54, 49, 48, 86>>  \* "B610V"
DerivativesQuoteFiveLevelsMessageCode9 == <<66, 54, 49, 49, 86>>  \* "B611V"
DerivativesQuoteFiveLevelsMessageCode10 == <<66, 54, 49, 50, 86>>  \* "B612V"
DerivativesQuoteFiveLevelsMessageCode11 == <<66, 54, 49, 51, 86>>  \* "B613V"
DerivativesQuoteFiveLevelsMessageCode12 == <<66, 54, 49, 53, 86>>  \* "B615V"
DerivativesQuoteFiveLevelsMessageCode13 == <<66, 54, 49, 54, 86>>  \* "B616V"
DerivativesQuoteFiveLevelsMessageCode14 == <<66, 54, 49, 55, 86>>  \* "B617V"
DerivativesQuoteTenLevelsMessageCode == <<66, 54, 48, 52, 86>>  \* "B604V"
DerivativesQuoteTenLevelsMessageCode2 == <<66, 54, 48, 53, 86>>  \* "B605V"
DerivativesQuoteTenLevelsMessageCode3 == <<66, 54, 49, 56, 86>>  \* "B618V"
DerivativesSnapshotFiveLevelsMessageCode == <<66, 50, 48, 49, 86>>  \* "B201V"
DerivativesSnapshotFiveLevelsMessageCode2 == <<66, 50, 48, 50, 86>>  \* "B202V"
DerivativesSnapshotFiveLevelsMessageCode3 == <<66, 50, 48, 51, 86>>  \* "B203V"
DerivativesSnapshotFiveLevelsMessageCode4 == <<66, 50, 48, 54, 86>>  \* "B206V"
DerivativesSnapshotFiveLevelsMessageCode5 == <<66, 50, 48, 55, 86>>  \* "B207V"
DerivativesSnapshotFiveLevelsMessageCode6 == <<66, 50, 48, 56, 86>>  \* "B208V"
DerivativesSnapshotFiveLevelsMessageCode7 == <<66, 50, 48, 57, 86>>  \* "B209V"
DerivativesSnapshotFiveLevelsMessageCode8 == <<66, 50, 49, 48, 86>>  \* "B210V"
DerivativesSnapshotFiveLevelsMessageCode9 == <<66, 50, 49, 49, 86>>  \* "B211V"
DerivativesSnapshotFiveLevelsMessageCode10 == <<66, 50, 49, 50, 86>>  \* "B212V"
DerivativesSnapshotFiveLevelsMessageCode11 == <<66, 50, 49, 51, 86>>  \* "B213V"
DerivativesSnapshotFiveLevelsMessageCode12 == <<66, 50, 49, 53, 86>>  \* "B215V"
DerivativesSnapshotFiveLevelsMessageCode13 == <<66, 50, 49, 54, 86>>  \* "B216V"
DerivativesSnapshotFiveLevelsMessageCode14 == <<66, 50, 49, 55, 86>>  \* "B217V"
DerivativesSnapshotTenLevelsMessageCode == <<66, 50, 48, 52, 86>>  \* "B204V"
DerivativesSnapshotTenLevelsMessageCode2 == <<66, 50, 48, 53, 86>>  \* "B205V"
DerivativesSnapshotTenLevelsMessageCode3 == <<66, 50, 49, 56, 86>>  \* "B218V"
DerivativesOrderFilledMessageCode == <<65, 51, 48, 49, 86>>  \* "A301V"
DerivativesOrderFilledMessageCode2 == <<65, 51, 48, 50, 86>>  \* "A302V"
DerivativesOrderFilledMessageCode3 == <<65, 51, 48, 51, 86>>  \* "A303V"
DerivativesOrderFilledMessageCode4 == <<65, 51, 48, 52, 86>>  \* "A304V"
DerivativesOrderFilledMessageCode5 == <<65, 51, 48, 53, 86>>  \* "A305V"
DerivativesOrderFilledMessageCode6 == <<65, 51, 48, 54, 86>>  \* "A306V"
DerivativesOrderFilledMessageCode7 == <<65, 51, 48, 55, 86>>  \* "A307V"
DerivativesOrderFilledMessageCode8 == <<65, 51, 48, 56, 86>>  \* "A308V"
DerivativesOrderFilledMessageCode9 == <<65, 51, 48, 57, 86>>  \* "A309V"
DerivativesOrderFilledMessageCode10 == <<65, 51, 49, 48, 86>>  \* "A310V"
DerivativesOrderFilledMessageCode11 == <<65, 51, 49, 49, 86>>  \* "A311V"
DerivativesOrderFilledMessageCode12 == <<65, 51, 49, 50, 86>>  \* "A312V"
DerivativesOrderFilledMessageCode13 == <<65, 51, 49, 51, 86>>  \* "A313V"
DerivativesOrderFilledMessageCode14 == <<65, 51, 49, 53, 86>>  \* "A315V"
DerivativesOrderFilledMessageCode15 == <<65, 51, 49, 54, 86>>  \* "A316V"
DerivativesOrderFilledMessageCode16 == <<65, 51, 49, 55, 86>>  \* "A317V"
DerivativesOrderFilledMessageCode17 == <<65, 51, 49, 56, 86>>  \* "A318V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode == <<71, 55, 48, 49, 86>>  \* "G701V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode2 == <<71, 55, 48, 50, 86>>  \* "G702V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode3 == <<71, 55, 48, 51, 86>>  \* "G703V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode4 == <<71, 55, 48, 54, 86>>  \* "G706V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode5 == <<71, 55, 48, 55, 86>>  \* "G707V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode6 == <<71, 55, 48, 56, 86>>  \* "G708V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode7 == <<71, 55, 48, 57, 86>>  \* "G709V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode8 == <<71, 55, 49, 48, 86>>  \* "G710V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode9 == <<71, 55, 49, 49, 86>>  \* "G711V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode10 == <<71, 55, 49, 50, 86>>  \* "G712V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode11 == <<71, 55, 49, 51, 86>>  \* "G713V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode12 == <<71, 55, 49, 53, 86>>  \* "G715V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode13 == <<71, 55, 49, 54, 86>>  \* "G716V"
DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode14 == <<71, 55, 49, 55, 86>>  \* "G717V"
DerivativesOrderFilledPlusQuoteTenLevelsMessageCode == <<71, 55, 48, 52, 86>>  \* "G704V"
DerivativesOrderFilledPlusQuoteTenLevelsMessageCode2 == <<71, 55, 48, 53, 86>>  \* "G705V"
DerivativesOrderFilledPlusQuoteTenLevelsMessageCode3 == <<71, 55, 49, 56, 86>>  \* "G718V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode == <<82, 49, 48, 49, 86>>  \* "R101V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode2 == <<82, 49, 48, 50, 86>>  \* "R102V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode3 == <<82, 49, 48, 51, 86>>  \* "R103V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode4 == <<82, 49, 48, 54, 86>>  \* "R106V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode5 == <<82, 49, 48, 55, 86>>  \* "R107V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode6 == <<82, 49, 48, 56, 86>>  \* "R108V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode7 == <<82, 49, 48, 57, 86>>  \* "R109V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode8 == <<82, 49, 49, 48, 86>>  \* "R110V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode9 == <<82, 49, 49, 49, 86>>  \* "R111V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode10 == <<82, 49, 49, 50, 86>>  \* "R112V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode11 == <<82, 49, 49, 51, 86>>  \* "R113V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode12 == <<82, 49, 49, 53, 86>>  \* "R115V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode13 == <<82, 49, 49, 54, 86>>  \* "R116V"
DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode14 == <<82, 49, 49, 55, 86>>  \* "R117V"
DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode == <<82, 49, 48, 52, 86>>  \* "R104V"
DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode2 == <<82, 49, 48, 53, 86>>  \* "R105V"
DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode3 == <<82, 49, 49, 56, 86>>  \* "R118V"
DerivativesNegotiatedTradeMessageCode == <<67, 52, 48, 49, 86>>  \* "C401V"
DerivativesNegotiatedTradeMessageCode2 == <<67, 52, 48, 50, 86>>  \* "C402V"
DerivativesNegotiatedTradeMessageCode3 == <<67, 52, 48, 51, 86>>  \* "C403V"
DerivativesNegotiatedTradeMessageCode4 == <<67, 52, 48, 52, 86>>  \* "C404V"
DerivativesNegotiatedTradeMessageCode5 == <<67, 52, 48, 53, 86>>  \* "C405V"
DerivativesNegotiatedTradeMessageCode6 == <<67, 52, 48, 54, 86>>  \* "C406V"
DerivativesNegotiatedTradeMessageCode7 == <<67, 52, 48, 55, 86>>  \* "C407V"
DerivativesNegotiatedTradeMessageCode8 == <<67, 52, 48, 56, 86>>  \* "C408V"
DerivativesNegotiatedTradeMessageCode9 == <<67, 52, 48, 57, 86>>  \* "C409V"
DerivativesNegotiatedTradeMessageCode10 == <<67, 52, 49, 48, 86>>  \* "C410V"
DerivativesNegotiatedTradeMessageCode11 == <<67, 52, 49, 49, 86>>  \* "C411V"
DerivativesNegotiatedTradeMessageCode12 == <<67, 52, 49, 50, 86>>  \* "C412V"
DerivativesNegotiatedTradeMessageCode13 == <<67, 52, 49, 51, 86>>  \* "C413V"
DerivativesNegotiatedTradeMessageCode14 == <<67, 52, 49, 53, 86>>  \* "C415V"
DerivativesNegotiatedTradeMessageCode15 == <<67, 52, 49, 54, 86>>  \* "C416V"
DerivativesNegotiatedTradeMessageCode16 == <<67, 52, 49, 55, 86>>  \* "C417V"
DerivativesNegotiatedTradeMessageCode17 == <<67, 52, 49, 56, 86>>  \* "C418V"
DerivativesMarketOperationTsMessageCode == <<65, 55, 48, 49, 83>>  \* "A701S"
DerivativesMarketOperationTsMessageCode2 == <<65, 55, 48, 50, 83>>  \* "A702S"
DerivativesMarketOperationTsMessageCode3 == <<65, 55, 48, 51, 83>>  \* "A703S"
DerivativesMarketOperationTsMessageCode4 == <<65, 55, 48, 52, 83>>  \* "A704S"
DerivativesMarketOperationTsMessageCode5 == <<65, 55, 48, 53, 83>>  \* "A705S"
DerivativesMarketOperationTsMessageCode6 == <<65, 55, 48, 49, 81>>  \* "A701Q"
DerivativesMarketOperationTsMessageCode7 == <<65, 55, 48, 49, 88>>  \* "A701X"
DerivativesMarketOperationTsMessageCode8 == <<65, 55, 48, 49, 66>>  \* "A701B"
DerivativesMarketOperationTsMessageCode9 == <<65, 55, 48, 49, 77>>  \* "A701M"
DerivativesMarketOperationTsMessageCode10 == <<65, 55, 48, 49, 75>>  \* "A701K"
DerivativesMarketOperationTsMessageCode11 == <<65, 55, 48, 49, 82>>  \* "A701R"
DerivativesMarketOperationTsMessageCode12 == <<65, 55, 48, 49, 86>>  \* "A701V"
DerivativesMarketOperationTsMessageCode13 == <<65, 55, 48, 50, 86>>  \* "A702V"
DerivativesMarketOperationTsMessageCode14 == <<65, 55, 48, 51, 86>>  \* "A703V"
DerivativesMarketOperationTsMessageCode15 == <<65, 55, 48, 52, 86>>  \* "A704V"
DerivativesMarketOperationTsMessageCode16 == <<65, 55, 48, 53, 86>>  \* "A705V"
DerivativesMarketOperationTsMessageCode17 == <<65, 55, 48, 54, 86>>  \* "A706V"
DerivativesMarketOperationTsMessageCode18 == <<65, 55, 48, 55, 86>>  \* "A707V"
DerivativesMarketOperationTsMessageCode19 == <<65, 55, 48, 56, 86>>  \* "A708V"
DerivativesMarketOperationTsMessageCode20 == <<65, 55, 48, 57, 86>>  \* "A709V"
DerivativesMarketOperationTsMessageCode21 == <<65, 55, 49, 48, 86>>  \* "A710V"
DerivativesMarketOperationTsMessageCode22 == <<65, 55, 49, 49, 86>>  \* "A711V"
DerivativesMarketOperationTsMessageCode23 == <<65, 55, 49, 50, 86>>  \* "A712V"
DerivativesMarketOperationTsMessageCode24 == <<65, 55, 49, 51, 86>>  \* "A713V"
DerivativesMarketOperationTsMessageCode25 == <<65, 55, 49, 53, 86>>  \* "A715V"
DerivativesMarketOperationTsMessageCode26 == <<65, 55, 49, 54, 86>>  \* "A716V"
DerivativesMarketOperationTsMessageCode27 == <<65, 55, 49, 55, 86>>  \* "A717V"
DerivativesMarketOperationTsMessageCode28 == <<65, 55, 49, 56, 86>>  \* "A718V"
DerivativesMarketOperationTsMessageCode29 == <<65, 55, 48, 49, 71>>  \* "A701G"
DerivativesMarketOperationTsMessageCode30 == <<65, 55, 48, 49, 69>>  \* "A701E"
DerivativesIssueClosingMessageCode == <<65, 54, 48, 49, 86>>  \* "A601V"
DerivativesIssueClosingMessageCode2 == <<65, 54, 48, 50, 86>>  \* "A602V"
DerivativesIssueClosingMessageCode3 == <<65, 54, 48, 51, 86>>  \* "A603V"
DerivativesIssueClosingMessageCode4 == <<65, 54, 48, 52, 86>>  \* "A604V"
DerivativesIssueClosingMessageCode5 == <<65, 54, 48, 53, 86>>  \* "A605V"
DerivativesIssueClosingMessageCode6 == <<65, 54, 48, 54, 86>>  \* "A606V"
DerivativesIssueClosingMessageCode7 == <<65, 54, 48, 55, 86>>  \* "A607V"
DerivativesIssueClosingMessageCode8 == <<65, 54, 48, 56, 86>>  \* "A608V"
DerivativesIssueClosingMessageCode9 == <<65, 54, 48, 57, 86>>  \* "A609V"
DerivativesIssueClosingMessageCode10 == <<65, 54, 49, 48, 86>>  \* "A610V"
DerivativesIssueClosingMessageCode11 == <<65, 54, 49, 49, 86>>  \* "A611V"
DerivativesIssueClosingMessageCode12 == <<65, 54, 49, 50, 86>>  \* "A612V"
DerivativesIssueClosingMessageCode13 == <<65, 54, 49, 51, 86>>  \* "A613V"
DerivativesIssueClosingMessageCode14 == <<65, 54, 49, 53, 86>>  \* "A615V"
DerivativesIssueClosingMessageCode15 == <<65, 54, 49, 54, 86>>  \* "A616V"
DerivativesIssueClosingMessageCode16 == <<65, 54, 49, 55, 86>>  \* "A617V"
DerivativesIssueClosingMessageCode17 == <<65, 54, 49, 56, 86>>  \* "A618V"
DerivativesMarketOperationScheduleMessageCode == <<77, 52, 48, 49, 83>>  \* "M401S"
DerivativesMarketOperationScheduleMessageCode2 == <<77, 52, 48, 50, 83>>  \* "M402S"
DerivativesMarketOperationScheduleMessageCode3 == <<77, 52, 48, 51, 83>>  \* "M403S"
DerivativesMarketOperationScheduleMessageCode4 == <<77, 52, 48, 52, 83>>  \* "M404S"
DerivativesMarketOperationScheduleMessageCode5 == <<77, 52, 48, 53, 83>>  \* "M405S"
DerivativesMarketOperationScheduleMessageCode6 == <<77, 52, 48, 49, 81>>  \* "M401Q"
DerivativesMarketOperationScheduleMessageCode7 == <<77, 52, 48, 49, 88>>  \* "M401X"
DerivativesMarketOperationScheduleMessageCode8 == <<77, 52, 48, 49, 66>>  \* "M401B"
DerivativesMarketOperationScheduleMessageCode9 == <<77, 52, 48, 49, 77>>  \* "M401M"
DerivativesMarketOperationScheduleMessageCode10 == <<77, 52, 48, 49, 75>>  \* "M401K"
DerivativesMarketOperationScheduleMessageCode11 == <<77, 52, 48, 49, 82>>  \* "M401R"
DerivativesMarketOperationScheduleMessageCode12 == <<77, 52, 48, 49, 86>>  \* "M401V"
DerivativesMarketOperationScheduleMessageCode13 == <<77, 52, 48, 50, 86>>  \* "M402V"
DerivativesMarketOperationScheduleMessageCode14 == <<77, 52, 48, 51, 86>>  \* "M403V"
DerivativesMarketOperationScheduleMessageCode15 == <<77, 52, 48, 52, 86>>  \* "M404V"
DerivativesMarketOperationScheduleMessageCode16 == <<77, 52, 48, 53, 86>>  \* "M405V"
DerivativesMarketOperationScheduleMessageCode17 == <<77, 52, 48, 54, 86>>  \* "M406V"
DerivativesMarketOperationScheduleMessageCode18 == <<77, 52, 48, 55, 86>>  \* "M407V"
DerivativesMarketOperationScheduleMessageCode19 == <<77, 52, 48, 56, 86>>  \* "M408V"
DerivativesMarketOperationScheduleMessageCode20 == <<77, 52, 48, 57, 86>>  \* "M409V"
DerivativesMarketOperationScheduleMessageCode21 == <<77, 52, 49, 48, 86>>  \* "M410V"
DerivativesMarketOperationScheduleMessageCode22 == <<77, 52, 49, 49, 86>>  \* "M411V"
DerivativesMarketOperationScheduleMessageCode23 == <<77, 52, 49, 50, 86>>  \* "M412V"
DerivativesMarketOperationScheduleMessageCode24 == <<77, 52, 49, 51, 86>>  \* "M413V"
DerivativesMarketOperationScheduleMessageCode25 == <<77, 52, 49, 53, 86>>  \* "M415V"
DerivativesMarketOperationScheduleMessageCode26 == <<77, 52, 49, 54, 86>>  \* "M416V"
DerivativesMarketOperationScheduleMessageCode27 == <<77, 52, 49, 55, 86>>  \* "M417V"
DerivativesMarketOperationScheduleMessageCode28 == <<77, 52, 49, 56, 86>>  \* "M418V"
DerivativesMarketOperationScheduleMessageCode29 == <<77, 52, 48, 49, 71>>  \* "M401G"
DerivativesMarketOperationScheduleMessageCode30 == <<77, 52, 48, 49, 69>>  \* "M401E"
DerivativesDynamicUpperLowerLimitMessageCode == <<81, 50, 48, 49, 86>>  \* "Q201V"
DerivativesDynamicUpperLowerLimitMessageCode2 == <<81, 50, 48, 50, 86>>  \* "Q202V"
DerivativesDynamicUpperLowerLimitMessageCode3 == <<81, 50, 48, 51, 86>>  \* "Q203V"
DerivativesDynamicUpperLowerLimitMessageCode4 == <<81, 50, 48, 52, 86>>  \* "Q204V"
DerivativesDynamicUpperLowerLimitMessageCode5 == <<81, 50, 48, 54, 86>>  \* "Q206V"
DerivativesDynamicUpperLowerLimitMessageCode6 == <<81, 50, 48, 56, 86>>  \* "Q208V"
DerivativesDynamicUpperLowerLimitMessageCode7 == <<81, 50, 48, 57, 86>>  \* "Q209V"
DerivativesDynamicUpperLowerLimitMessageCode8 == <<81, 50, 49, 48, 86>>  \* "Q210V"
DerivativesDynamicUpperLowerLimitMessageCode9 == <<81, 50, 49, 49, 86>>  \* "Q211V"
DerivativesDynamicUpperLowerLimitMessageCode10 == <<81, 50, 49, 50, 86>>  \* "Q212V"
DerivativesDynamicUpperLowerLimitMessageCode11 == <<81, 50, 49, 54, 86>>  \* "Q216V"
DerivativesDynamicUpperLowerLimitMessageCode12 == <<81, 50, 49, 55, 86>>  \* "Q217V"
DerivativesPriceLimitRangeIncreaseMessageCode == <<86, 49, 48, 49, 86>>  \* "V101V"
DerivativesPriceLimitRangeIncreaseMessageCode2 == <<86, 49, 48, 50, 86>>  \* "V102V"
DerivativesPriceLimitRangeIncreaseMessageCode3 == <<86, 49, 48, 51, 86>>  \* "V103V"
DerivativesPriceLimitRangeIncreaseMessageCode4 == <<86, 49, 48, 52, 86>>  \* "V104V"
DerivativesPriceLimitRangeIncreaseMessageCode5 == <<86, 49, 48, 53, 86>>  \* "V105V"
DerivativesPriceLimitRangeIncreaseMessageCode6 == <<86, 49, 48, 56, 86>>  \* "V108V"
DerivativesPriceLimitRangeIncreaseMessageCode7 == <<86, 49, 48, 57, 86>>  \* "V109V"
DerivativesPriceLimitRangeIncreaseMessageCode8 == <<86, 49, 49, 49, 86>>  \* "V111V"
DerivativesPriceLimitRangeIncreaseMessageCode9 == <<86, 49, 49, 50, 86>>  \* "V112V"
DerivativesPriceLimitRangeIncreaseMessageCode10 == <<86, 49, 49, 51, 86>>  \* "V113V"
DerivativesPriceLimitRangeIncreaseMessageCode11 == <<86, 49, 49, 53, 86>>  \* "V115V"
DerivativesPriceLimitRangeIncreaseMessageCode12 == <<86, 49, 49, 54, 86>>  \* "V116V"
DerivativesPriceLimitRangeIncreaseMessageCode13 == <<86, 49, 49, 55, 86>>  \* "V117V"
DerivativesPriceLimitRangeIncreaseMessageCode14 == <<86, 49, 49, 56, 86>>  \* "V118V"
DerivativesQuantityAllocationMessageCode == <<79, 54, 48, 49, 83>>  \* "O601S"
DerivativesQuantityAllocationMessageCode2 == <<79, 54, 48, 51, 83>>  \* "O603S"
DerivativesQuantityAllocationMessageCode3 == <<79, 54, 48, 52, 83>>  \* "O604S"
DerivativesQuantityAllocationMessageCode4 == <<79, 54, 48, 53, 83>>  \* "O605S"
DerivativesQuantityAllocationMessageCode5 == <<79, 54, 48, 49, 81>>  \* "O601Q"
DerivativesQuantityAllocationMessageCode6 == <<79, 54, 48, 49, 88>>  \* "O601X"
DerivativesQuantityAllocationMessageCode7 == <<79, 54, 48, 49, 86>>  \* "O601V"
DerivativesQuantityAllocationMessageCode8 == <<79, 54, 48, 50, 86>>  \* "O602V"
DerivativesQuantityAllocationMessageCode9 == <<79, 54, 48, 51, 86>>  \* "O603V"
DerivativesQuantityAllocationMessageCode10 == <<79, 54, 48, 52, 86>>  \* "O604V"
DerivativesQuantityAllocationMessageCode11 == <<79, 54, 48, 53, 86>>  \* "O605V"
DerivativesQuantityAllocationMessageCode12 == <<79, 54, 48, 54, 86>>  \* "O606V"
DerivativesQuantityAllocationMessageCode13 == <<79, 54, 48, 55, 86>>  \* "O607V"
DerivativesQuantityAllocationMessageCode14 == <<79, 54, 48, 56, 86>>  \* "O608V"
DerivativesQuantityAllocationMessageCode15 == <<79, 54, 48, 57, 86>>  \* "O609V"
DerivativesQuantityAllocationMessageCode16 == <<79, 54, 49, 48, 86>>  \* "O610V"
DerivativesQuantityAllocationMessageCode17 == <<79, 54, 49, 49, 86>>  \* "O611V"
DerivativesQuantityAllocationMessageCode18 == <<79, 54, 49, 50, 86>>  \* "O612V"
DerivativesQuantityAllocationMessageCode19 == <<79, 54, 49, 51, 86>>  \* "O613V"
DerivativesQuantityAllocationMessageCode20 == <<79, 54, 49, 53, 86>>  \* "O615V"
DerivativesQuantityAllocationMessageCode21 == <<79, 54, 49, 54, 86>>  \* "O616V"
DerivativesQuantityAllocationMessageCode22 == <<79, 54, 49, 55, 86>>  \* "O617V"
DerivativesQuantityAllocationMessageCode23 == <<79, 54, 49, 56, 86>>  \* "O618V"
DerivativesGroupOrderAcceptanceHaltMessageCode == <<73, 70, 48, 49, 83>>  \* "IF01S"
DerivativesGroupOrderAcceptanceHaltMessageCode2 == <<73, 70, 48, 50, 83>>  \* "IF02S"
DerivativesGroupOrderAcceptanceHaltMessageCode3 == <<73, 70, 48, 51, 83>>  \* "IF03S"
DerivativesGroupOrderAcceptanceHaltMessageCode4 == <<73, 70, 48, 52, 83>>  \* "IF04S"
DerivativesGroupOrderAcceptanceHaltMessageCode5 == <<73, 70, 48, 53, 83>>  \* "IF05S"
DerivativesGroupOrderAcceptanceHaltMessageCode6 == <<73, 70, 48, 49, 81>>  \* "IF01Q"
DerivativesGroupOrderAcceptanceHaltMessageCode7 == <<73, 70, 48, 49, 86>>  \* "IF01V"
DerivativesGroupOrderAcceptanceHaltMessageCode8 == <<73, 70, 48, 50, 86>>  \* "IF02V"
DerivativesGroupOrderAcceptanceHaltMessageCode9 == <<73, 70, 48, 51, 86>>  \* "IF03V"
DerivativesGroupOrderAcceptanceHaltMessageCode10 == <<73, 70, 48, 52, 86>>  \* "IF04V"
DerivativesGroupOrderAcceptanceHaltMessageCode11 == <<73, 70, 48, 53, 86>>  \* "IF05V"
DerivativesGroupOrderAcceptanceHaltMessageCode12 == <<73, 70, 48, 54, 86>>  \* "IF06V"
DerivativesGroupOrderAcceptanceHaltMessageCode13 == <<73, 70, 48, 55, 86>>  \* "IF07V"
DerivativesGroupOrderAcceptanceHaltMessageCode14 == <<73, 70, 48, 56, 86>>  \* "IF08V"
DerivativesGroupOrderAcceptanceHaltMessageCode15 == <<73, 70, 48, 57, 86>>  \* "IF09V"
DerivativesGroupOrderAcceptanceHaltMessageCode16 == <<73, 70, 49, 48, 86>>  \* "IF10V"
DerivativesGroupOrderAcceptanceHaltMessageCode17 == <<73, 70, 49, 49, 86>>  \* "IF11V"
DerivativesGroupOrderAcceptanceHaltMessageCode18 == <<73, 70, 49, 50, 86>>  \* "IF12V"
DerivativesGroupOrderAcceptanceHaltMessageCode19 == <<73, 70, 49, 51, 86>>  \* "IF13V"
DerivativesGroupOrderAcceptanceHaltMessageCode20 == <<73, 70, 49, 53, 86>>  \* "IF15V"
DerivativesGroupOrderAcceptanceHaltMessageCode21 == <<73, 70, 49, 54, 86>>  \* "IF16V"
DerivativesGroupOrderAcceptanceHaltMessageCode22 == <<73, 70, 49, 55, 86>>  \* "IF17V"
DerivativesGroupOrderAcceptanceHaltMessageCode23 == <<73, 70, 49, 56, 86>>  \* "IF18V"
DerivativesBatchDataMessageCode == <<65, 48, 48, 49, 86>>  \* "A001V"
DerivativesBatchDataMessageCode2 == <<65, 48, 48, 50, 86>>  \* "A002V"
DerivativesBatchDataMessageCode3 == <<65, 48, 48, 51, 86>>  \* "A003V"
DerivativesBatchDataMessageCode4 == <<65, 48, 48, 52, 86>>  \* "A004V"
DerivativesBatchDataMessageCode5 == <<65, 48, 48, 53, 86>>  \* "A005V"
DerivativesBatchDataMessageCode6 == <<65, 48, 48, 54, 86>>  \* "A006V"
DerivativesBatchDataMessageCode7 == <<65, 48, 48, 55, 86>>  \* "A007V"
DerivativesBatchDataMessageCode8 == <<65, 48, 48, 56, 86>>  \* "A008V"
DerivativesBatchDataMessageCode9 == <<65, 48, 48, 57, 86>>  \* "A009V"
DerivativesBatchDataMessageCode10 == <<65, 48, 49, 48, 86>>  \* "A010V"
DerivativesBatchDataMessageCode11 == <<65, 48, 49, 49, 86>>  \* "A011V"
DerivativesBatchDataMessageCode12 == <<65, 48, 49, 50, 86>>  \* "A012V"
DerivativesBatchDataMessageCode13 == <<65, 48, 49, 51, 86>>  \* "A013V"
DerivativesBatchDataMessageCode14 == <<65, 48, 49, 53, 86>>  \* "A015V"
DerivativesBatchDataMessageCode15 == <<65, 48, 49, 54, 86>>  \* "A016V"
DerivativesBatchDataMessageCode16 == <<65, 48, 49, 55, 86>>  \* "A017V"
DerivativesBatchDataMessageCode17 == <<65, 48, 49, 56, 86>>  \* "A018V"
EquityDerivativesAdjustmentDetailsMessageCode == <<72, 52, 48, 52, 86>>  \* "H404V"
EquityDerivativesAdjustmentDetailsMessageCode2 == <<72, 52, 48, 53, 86>>  \* "H405V"
EquityDerivativesAdjustmentDetailsMessageCode3 == <<72, 52, 49, 56, 86>>  \* "H418V"
CommodityFuturesSettlementReferenceKtbMessageCode == <<72, 54, 48, 54, 86>>  \* "H606V"
DerivativesInvestorActivitiesMessageCode == <<72, 49, 48, 49, 86>>  \* "H101V"
DerivativesInvestorActivitiesMessageCode2 == <<72, 49, 48, 50, 86>>  \* "H102V"
DerivativesInvestorActivitiesMessageCode3 == <<72, 49, 48, 51, 86>>  \* "H103V"
DerivativesInvestorActivitiesMessageCode4 == <<72, 49, 48, 52, 86>>  \* "H104V"
DerivativesInvestorActivitiesMessageCode5 == <<72, 49, 48, 53, 86>>  \* "H105V"
DerivativesInvestorActivitiesMessageCode6 == <<72, 49, 48, 54, 86>>  \* "H106V"
DerivativesInvestorActivitiesMessageCode7 == <<72, 49, 48, 55, 86>>  \* "H107V"
DerivativesInvestorActivitiesMessageCode8 == <<72, 49, 48, 56, 86>>  \* "H108V"
DerivativesInvestorActivitiesMessageCode9 == <<72, 49, 48, 57, 86>>  \* "H109V"
DerivativesInvestorActivitiesMessageCode10 == <<72, 49, 49, 48, 86>>  \* "H110V"
DerivativesInvestorActivitiesMessageCode11 == <<72, 49, 49, 49, 86>>  \* "H111V"
DerivativesInvestorActivitiesMessageCode12 == <<72, 49, 49, 50, 86>>  \* "H112V"
DerivativesInvestorActivitiesMessageCode13 == <<72, 49, 49, 51, 86>>  \* "H113V"
DerivativesInvestorActivitiesMessageCode14 == <<72, 49, 49, 53, 86>>  \* "H115V"
DerivativesInvestorActivitiesMessageCode15 == <<72, 49, 49, 54, 86>>  \* "H116V"
DerivativesInvestorActivitiesMessageCode16 == <<72, 49, 49, 55, 86>>  \* "H117V"
DerivativesInvestorActivitiesMessageCode17 == <<72, 49, 49, 56, 86>>  \* "H118V"
DerivativesOpenInterestMessageCode == <<72, 50, 48, 49, 86>>  \* "H201V"
DerivativesOpenInterestMessageCode2 == <<72, 50, 48, 50, 86>>  \* "H202V"
DerivativesOpenInterestMessageCode3 == <<72, 50, 48, 51, 86>>  \* "H203V"
DerivativesOpenInterestMessageCode4 == <<72, 50, 48, 52, 86>>  \* "H204V"
DerivativesOpenInterestMessageCode5 == <<72, 50, 48, 53, 86>>  \* "H205V"
DerivativesOpenInterestMessageCode6 == <<72, 50, 48, 54, 86>>  \* "H206V"
DerivativesOpenInterestMessageCode7 == <<72, 50, 48, 55, 86>>  \* "H207V"
DerivativesOpenInterestMessageCode8 == <<72, 50, 48, 56, 86>>  \* "H208V"
DerivativesOpenInterestMessageCode9 == <<72, 50, 48, 57, 86>>  \* "H209V"
DerivativesOpenInterestMessageCode10 == <<72, 50, 49, 48, 86>>  \* "H210V"
DerivativesOpenInterestMessageCode11 == <<72, 50, 49, 49, 86>>  \* "H211V"
DerivativesOpenInterestMessageCode12 == <<72, 50, 49, 50, 86>>  \* "H212V"
DerivativesOpenInterestMessageCode13 == <<72, 50, 49, 51, 86>>  \* "H213V"
DerivativesOpenInterestMessageCode14 == <<72, 50, 49, 53, 86>>  \* "H215V"
DerivativesOpenInterestMessageCode15 == <<72, 50, 49, 54, 86>>  \* "H216V"
DerivativesOpenInterestMessageCode16 == <<72, 50, 49, 55, 86>>  \* "H217V"
DerivativesOpenInterestMessageCode17 == <<72, 50, 49, 56, 86>>  \* "H218V"
FuturesSettledPriceMessageCode == <<72, 51, 48, 49, 86>>  \* "H301V"
FuturesSettledPriceMessageCode2 == <<72, 51, 48, 50, 86>>  \* "H302V"
FuturesSettledPriceMessageCode3 == <<72, 51, 48, 52, 86>>  \* "H304V"
FuturesSettledPriceMessageCode4 == <<72, 51, 48, 54, 86>>  \* "H306V"
FuturesSettledPriceMessageCode5 == <<72, 51, 48, 56, 86>>  \* "H308V"
FuturesSettledPriceMessageCode6 == <<72, 51, 48, 57, 86>>  \* "H309V"
FuturesSettledPriceMessageCode7 == <<72, 51, 49, 48, 86>>  \* "H310V"
FuturesSettledPriceMessageCode8 == <<72, 51, 49, 49, 86>>  \* "H311V"
FuturesSettledPriceMessageCode9 == <<72, 51, 49, 51, 86>>  \* "H313V"
OptionsBasePriceOfClearingMarginsMessageCode == <<73, 68, 48, 51, 86>>  \* "ID03V"
OptionsBasePriceOfClearingMarginsMessageCode2 == <<73, 68, 48, 53, 86>>  \* "ID05V"
OptionsBasePriceOfClearingMarginsMessageCode3 == <<73, 68, 48, 55, 86>>  \* "ID07V"
OptionsBasePriceOfClearingMarginsMessageCode4 == <<73, 68, 49, 50, 86>>  \* "ID12V"
OptionsBasePriceOfClearingMarginsMessageCode5 == <<73, 68, 49, 53, 86>>  \* "ID15V"
OptionsBasePriceOfClearingMarginsMessageCode6 == <<73, 68, 49, 54, 86>>  \* "ID16V"
OptionsBasePriceOfClearingMarginsMessageCode7 == <<73, 68, 49, 55, 86>>  \* "ID17V"
OptionsBasePriceOfClearingMarginsMessageCode8 == <<73, 68, 49, 56, 86>>  \* "ID18V"
OptionsImpliedVolatilityMessageCode == <<80, 49, 48, 51, 86>>  \* "P103V"
OptionsImpliedVolatilityMessageCode2 == <<80, 49, 49, 50, 86>>  \* "P112V"
OptionsImpliedVolatilityMessageCode3 == <<80, 49, 49, 53, 86>>  \* "P115V"
OptionsImpliedVolatilityMessageCode4 == <<80, 49, 49, 54, 86>>  \* "P116V"
OptionsImpliedVolatilityMessageCode5 == <<80, 49, 49, 55, 86>>  \* "P117V"
OptionsSensitivityMessageCode == <<78, 55, 48, 51, 86>>  \* "N703V"
OptionsSensitivityMessageCode2 == <<78, 55, 48, 53, 86>>  \* "N705V"
OptionsSensitivityMessageCode3 == <<78, 55, 48, 55, 86>>  \* "N707V"
OptionsSensitivityMessageCode4 == <<78, 55, 49, 50, 86>>  \* "N712V"
OptionsSensitivityMessageCode5 == <<78, 55, 49, 53, 86>>  \* "N715V"
OptionsSensitivityMessageCode6 == <<78, 55, 49, 54, 86>>  \* "N716V"
OptionsSensitivityMessageCode7 == <<78, 55, 49, 55, 86>>  \* "N717V"
OptionsSensitivityMessageCode8 == <<78, 55, 49, 56, 86>>  \* "N718V"
CommodityFuturesSpotSettlementReferenceMessageCode == <<72, 53, 48, 54, 86>>  \* "H506V"
CommodityFuturesSpotSettlementReferenceMessageCode2 == <<72, 53, 57, 57, 86>>  \* "H599V"
DailyDisclosedRfrMessageCode == <<72, 65, 48, 54, 86>>  \* "HA06V"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode2}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode3}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode4}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode5}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode6}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode7}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode8}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode9}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode10}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode11}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode12}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode13}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteFiveLevelsMessageCode14}, body : DerivativesQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesQuoteTenLevelsMessageCode}, body : DerivativesQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesQuoteTenLevelsMessageCode2}, body : DerivativesQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesQuoteTenLevelsMessageCode3}, body : DerivativesQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode2}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode3}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode4}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode5}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode6}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode7}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode8}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode9}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode10}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode11}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode12}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode13}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotFiveLevelsMessageCode14}, body : DerivativesSnapshotFiveLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotTenLevelsMessageCode}, body : DerivativesSnapshotTenLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotTenLevelsMessageCode2}, body : DerivativesSnapshotTenLevelsMessage ]
        \cup [ tag : {DerivativesSnapshotTenLevelsMessageCode3}, body : DerivativesSnapshotTenLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode2}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode3}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode4}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode5}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode6}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode7}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode8}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode9}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode10}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode11}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode12}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode13}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode14}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode15}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode16}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledMessageCode17}, body : DerivativesOrderFilledMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode2}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode3}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode4}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode5}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode6}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode7}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode8}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode9}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode10}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode11}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode12}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode13}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode14}, body : DerivativesOrderFilledPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteTenLevelsMessageCode}, body : DerivativesOrderFilledPlusQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteTenLevelsMessageCode2}, body : DerivativesOrderFilledPlusQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesOrderFilledPlusQuoteTenLevelsMessageCode3}, body : DerivativesOrderFilledPlusQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode2}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode3}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode4}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode5}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode6}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode7}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode8}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode9}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode10}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode11}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode12}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode13}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode14}, body : DerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode}, body : DerivativesMarketOperationTsPlusQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode2}, body : DerivativesMarketOperationTsPlusQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode3}, body : DerivativesMarketOperationTsPlusQuoteTenLevelsMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode2}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode3}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode4}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode5}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode6}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode7}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode8}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode9}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode10}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode11}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode12}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode13}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode14}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode15}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode16}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesNegotiatedTradeMessageCode17}, body : DerivativesNegotiatedTradeMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode2}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode3}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode4}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode5}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode6}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode7}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode8}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode9}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode10}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode11}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode12}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode13}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode14}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode15}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode16}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode17}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode18}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode19}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode20}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode21}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode22}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode23}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode24}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode25}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode26}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode27}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode28}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode29}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesMarketOperationTsMessageCode30}, body : DerivativesMarketOperationTsMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode2}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode3}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode4}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode5}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode6}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode7}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode8}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode9}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode10}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode11}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode12}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode13}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode14}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode15}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode16}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesIssueClosingMessageCode17}, body : DerivativesIssueClosingMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode2}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode3}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode4}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode5}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode6}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode7}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode8}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode9}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode10}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode11}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode12}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode13}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode14}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode15}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode16}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode17}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode18}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode19}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode20}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode21}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode22}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode23}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode24}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode25}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode26}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode27}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode28}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode29}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesMarketOperationScheduleMessageCode30}, body : DerivativesMarketOperationScheduleMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode2}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode3}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode4}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode5}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode6}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode7}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode8}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode9}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode10}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode11}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesDynamicUpperLowerLimitMessageCode12}, body : DerivativesDynamicUpperLowerLimitMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode2}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode3}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode4}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode5}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode6}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode7}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode8}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode9}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode10}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode11}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode12}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode13}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesPriceLimitRangeIncreaseMessageCode14}, body : DerivativesPriceLimitRangeIncreaseMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode2}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode3}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode4}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode5}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode6}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode7}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode8}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode9}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode10}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode11}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode12}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode13}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode14}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode15}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode16}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode17}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode18}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode19}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode20}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode21}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode22}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesQuantityAllocationMessageCode23}, body : DerivativesQuantityAllocationMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode2}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode3}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode4}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode5}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode6}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode7}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode8}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode9}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode10}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode11}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode12}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode13}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode14}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode15}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode16}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode17}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode18}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode19}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode20}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode21}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode22}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesGroupOrderAcceptanceHaltMessageCode23}, body : DerivativesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode2}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode3}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode4}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode5}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode6}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode7}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode8}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode9}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode10}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode11}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode12}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode13}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode14}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode15}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode16}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {DerivativesBatchDataMessageCode17}, body : DerivativesBatchDataMessage ]
        \cup [ tag : {EquityDerivativesAdjustmentDetailsMessageCode}, body : EquityDerivativesAdjustmentDetailsMessage ]
        \cup [ tag : {EquityDerivativesAdjustmentDetailsMessageCode2}, body : EquityDerivativesAdjustmentDetailsMessage ]
        \cup [ tag : {EquityDerivativesAdjustmentDetailsMessageCode3}, body : EquityDerivativesAdjustmentDetailsMessage ]
        \cup [ tag : {CommodityFuturesSettlementReferenceKtbMessageCode}, body : CommodityFuturesSettlementReferenceKtbMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode2}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode3}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode4}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode5}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode6}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode7}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode8}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode9}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode10}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode11}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode12}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode13}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode14}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode15}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode16}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesInvestorActivitiesMessageCode17}, body : DerivativesInvestorActivitiesMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode2}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode3}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode4}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode5}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode6}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode7}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode8}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode9}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode10}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode11}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode12}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode13}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode14}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode15}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode16}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {DerivativesOpenInterestMessageCode17}, body : DerivativesOpenInterestMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode2}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode3}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode4}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode5}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode6}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode7}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode8}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {FuturesSettledPriceMessageCode9}, body : FuturesSettledPriceMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode2}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode3}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode4}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode5}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode6}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode7}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsBasePriceOfClearingMarginsMessageCode8}, body : OptionsBasePriceOfClearingMarginsMessage ]
        \cup [ tag : {OptionsImpliedVolatilityMessageCode}, body : OptionsImpliedVolatilityMessage ]
        \cup [ tag : {OptionsImpliedVolatilityMessageCode2}, body : OptionsImpliedVolatilityMessage ]
        \cup [ tag : {OptionsImpliedVolatilityMessageCode3}, body : OptionsImpliedVolatilityMessage ]
        \cup [ tag : {OptionsImpliedVolatilityMessageCode4}, body : OptionsImpliedVolatilityMessage ]
        \cup [ tag : {OptionsImpliedVolatilityMessageCode5}, body : OptionsImpliedVolatilityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode2}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode3}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode4}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode5}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode6}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode7}, body : OptionsSensitivityMessage ]
        \cup [ tag : {OptionsSensitivityMessageCode8}, body : OptionsSensitivityMessage ]
        \cup [ tag : {CommodityFuturesSpotSettlementReferenceMessageCode}, body : CommodityFuturesSpotSettlementReferenceMessage ]
        \cup [ tag : {CommodityFuturesSpotSettlementReferenceMessageCode2}, body : CommodityFuturesSpotSettlementReferenceMessage ]
        \cup [ tag : {DailyDisclosedRfrMessageCode}, body : DailyDisclosedRfrMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode2 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode3 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode4 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode5 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode6 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode7 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode8 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode9 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode10 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode11 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode12 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode13 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteFiveLevelsMessageCode14 -> EncodeDerivativesQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteTenLevelsMessageCode -> EncodeDerivativesQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteTenLevelsMessageCode2 -> EncodeDerivativesQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesQuoteTenLevelsMessageCode3 -> EncodeDerivativesQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode2 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode3 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode4 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode5 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode6 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode7 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode8 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode9 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode10 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode11 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode12 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode13 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotFiveLevelsMessageCode14 -> EncodeDerivativesSnapshotFiveLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotTenLevelsMessageCode -> EncodeDerivativesSnapshotTenLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotTenLevelsMessageCode2 -> EncodeDerivativesSnapshotTenLevelsMessage(message.body)
      [] message.tag = DerivativesSnapshotTenLevelsMessageCode3 -> EncodeDerivativesSnapshotTenLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode2 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode3 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode4 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode5 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode6 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode7 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode8 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode9 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode10 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode11 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode12 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode13 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode14 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode15 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode16 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledMessageCode17 -> EncodeDerivativesOrderFilledMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode2 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode3 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode4 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode5 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode6 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode7 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode8 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode9 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode10 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode11 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode12 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode13 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode14 -> EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteTenLevelsMessageCode -> EncodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteTenLevelsMessageCode2 -> EncodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesOrderFilledPlusQuoteTenLevelsMessageCode3 -> EncodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode2 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode3 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode4 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode5 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode6 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode7 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode8 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode9 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode10 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode11 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode12 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode13 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode14 -> EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode -> EncodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode2 -> EncodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode3 -> EncodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode2 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode3 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode4 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode5 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode6 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode7 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode8 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode9 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode10 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode11 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode12 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode13 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode14 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode15 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode16 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesNegotiatedTradeMessageCode17 -> EncodeDerivativesNegotiatedTradeMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode2 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode3 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode4 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode5 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode6 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode7 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode8 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode9 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode10 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode11 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode12 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode13 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode14 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode15 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode16 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode17 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode18 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode19 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode20 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode21 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode22 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode23 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode24 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode25 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode26 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode27 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode28 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode29 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesMarketOperationTsMessageCode30 -> EncodeDerivativesMarketOperationTsMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode2 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode3 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode4 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode5 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode6 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode7 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode8 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode9 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode10 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode11 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode12 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode13 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode14 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode15 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode16 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesIssueClosingMessageCode17 -> EncodeDerivativesIssueClosingMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode2 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode3 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode4 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode5 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode6 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode7 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode8 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode9 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode10 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode11 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode12 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode13 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode14 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode15 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode16 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode17 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode18 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode19 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode20 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode21 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode22 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode23 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode24 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode25 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode26 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode27 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode28 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode29 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesMarketOperationScheduleMessageCode30 -> EncodeDerivativesMarketOperationScheduleMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode2 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode3 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode4 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode5 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode6 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode7 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode8 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode9 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode10 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode11 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesDynamicUpperLowerLimitMessageCode12 -> EncodeDerivativesDynamicUpperLowerLimitMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode2 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode3 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode4 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode5 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode6 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode7 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode8 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode9 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode10 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode11 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode12 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode13 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesPriceLimitRangeIncreaseMessageCode14 -> EncodeDerivativesPriceLimitRangeIncreaseMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode2 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode3 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode4 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode5 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode6 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode7 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode8 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode9 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode10 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode11 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode12 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode13 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode14 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode15 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode16 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode17 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode18 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode19 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode20 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode21 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode22 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesQuantityAllocationMessageCode23 -> EncodeDerivativesQuantityAllocationMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode2 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode3 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode4 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode5 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode6 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode7 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode8 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode9 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode10 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode11 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode12 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode13 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode14 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode15 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode16 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode17 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode18 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode19 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode20 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode21 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode22 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesGroupOrderAcceptanceHaltMessageCode23 -> EncodeDerivativesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode2 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode3 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode4 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode5 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode6 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode7 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode8 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode9 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode10 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode11 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode12 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode13 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode14 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode15 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode16 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = DerivativesBatchDataMessageCode17 -> EncodeDerivativesBatchDataMessage(message.body)
      [] message.tag = EquityDerivativesAdjustmentDetailsMessageCode -> EncodeEquityDerivativesAdjustmentDetailsMessage(message.body)
      [] message.tag = EquityDerivativesAdjustmentDetailsMessageCode2 -> EncodeEquityDerivativesAdjustmentDetailsMessage(message.body)
      [] message.tag = EquityDerivativesAdjustmentDetailsMessageCode3 -> EncodeEquityDerivativesAdjustmentDetailsMessage(message.body)
      [] message.tag = CommodityFuturesSettlementReferenceKtbMessageCode -> EncodeCommodityFuturesSettlementReferenceKtbMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode2 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode3 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode4 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode5 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode6 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode7 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode8 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode9 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode10 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode11 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode12 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode13 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode14 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode15 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode16 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesInvestorActivitiesMessageCode17 -> EncodeDerivativesInvestorActivitiesMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode2 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode3 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode4 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode5 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode6 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode7 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode8 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode9 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode10 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode11 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode12 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode13 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode14 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode15 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode16 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = DerivativesOpenInterestMessageCode17 -> EncodeDerivativesOpenInterestMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode2 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode3 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode4 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode5 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode6 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode7 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode8 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = FuturesSettledPriceMessageCode9 -> EncodeFuturesSettledPriceMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode2 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode3 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode4 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode5 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode6 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode7 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsBasePriceOfClearingMarginsMessageCode8 -> EncodeOptionsBasePriceOfClearingMarginsMessage(message.body)
      [] message.tag = OptionsImpliedVolatilityMessageCode -> EncodeOptionsImpliedVolatilityMessage(message.body)
      [] message.tag = OptionsImpliedVolatilityMessageCode2 -> EncodeOptionsImpliedVolatilityMessage(message.body)
      [] message.tag = OptionsImpliedVolatilityMessageCode3 -> EncodeOptionsImpliedVolatilityMessage(message.body)
      [] message.tag = OptionsImpliedVolatilityMessageCode4 -> EncodeOptionsImpliedVolatilityMessage(message.body)
      [] message.tag = OptionsImpliedVolatilityMessageCode5 -> EncodeOptionsImpliedVolatilityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode2 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode3 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode4 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode5 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode6 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode7 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = OptionsSensitivityMessageCode8 -> EncodeOptionsSensitivityMessage(message.body)
      [] message.tag = CommodityFuturesSpotSettlementReferenceMessageCode -> EncodeCommodityFuturesSpotSettlementReferenceMessage(message.body)
      [] message.tag = CommodityFuturesSpotSettlementReferenceMessageCode2 -> EncodeCommodityFuturesSpotSettlementReferenceMessage(message.body)
      [] message.tag = DailyDisclosedRfrMessageCode -> EncodeDailyDisclosedRfrMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = PollingDataMessageCode -> DecodePollingDataMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode2 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode3 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode4 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode5 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode6 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode7 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode8 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode9 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode10 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode11 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode12 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode13 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteFiveLevelsMessageCode14 -> DecodeDerivativesQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesQuoteTenLevelsMessageCode -> DecodeDerivativesQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesQuoteTenLevelsMessageCode2 -> DecodeDerivativesQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesQuoteTenLevelsMessageCode3 -> DecodeDerivativesQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode2 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode3 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode4 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode5 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode6 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode7 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode8 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode9 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode10 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode11 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode12 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode13 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotFiveLevelsMessageCode14 -> DecodeDerivativesSnapshotFiveLevelsMessage(bytes)
              [] tag = DerivativesSnapshotTenLevelsMessageCode -> DecodeDerivativesSnapshotTenLevelsMessage(bytes)
              [] tag = DerivativesSnapshotTenLevelsMessageCode2 -> DecodeDerivativesSnapshotTenLevelsMessage(bytes)
              [] tag = DerivativesSnapshotTenLevelsMessageCode3 -> DecodeDerivativesSnapshotTenLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode2 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode3 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode4 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode5 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode6 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode7 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode8 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode9 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode10 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode11 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode12 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode13 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode14 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode15 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode16 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledMessageCode17 -> DecodeDerivativesOrderFilledMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode2 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode3 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode4 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode5 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode6 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode7 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode8 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode9 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode10 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode11 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode12 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode13 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode14 -> DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteTenLevelsMessageCode -> DecodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteTenLevelsMessageCode2 -> DecodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesOrderFilledPlusQuoteTenLevelsMessageCode3 -> DecodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode2 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode3 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode4 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode5 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode6 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode7 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode8 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode9 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode10 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode11 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode12 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode13 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode14 -> DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode -> DecodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode2 -> DecodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode3 -> DecodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode2 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode3 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode4 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode5 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode6 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode7 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode8 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode9 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode10 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode11 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode12 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode13 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode14 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode15 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode16 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesNegotiatedTradeMessageCode17 -> DecodeDerivativesNegotiatedTradeMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode2 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode3 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode4 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode5 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode6 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode7 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode8 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode9 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode10 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode11 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode12 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode13 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode14 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode15 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode16 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode17 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode18 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode19 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode20 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode21 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode22 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode23 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode24 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode25 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode26 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode27 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode28 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode29 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesMarketOperationTsMessageCode30 -> DecodeDerivativesMarketOperationTsMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode2 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode3 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode4 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode5 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode6 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode7 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode8 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode9 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode10 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode11 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode12 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode13 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode14 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode15 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode16 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesIssueClosingMessageCode17 -> DecodeDerivativesIssueClosingMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode2 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode3 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode4 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode5 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode6 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode7 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode8 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode9 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode10 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode11 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode12 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode13 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode14 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode15 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode16 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode17 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode18 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode19 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode20 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode21 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode22 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode23 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode24 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode25 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode26 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode27 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode28 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode29 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesMarketOperationScheduleMessageCode30 -> DecodeDerivativesMarketOperationScheduleMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode2 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode3 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode4 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode5 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode6 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode7 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode8 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode9 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode10 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode11 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesDynamicUpperLowerLimitMessageCode12 -> DecodeDerivativesDynamicUpperLowerLimitMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode2 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode3 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode4 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode5 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode6 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode7 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode8 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode9 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode10 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode11 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode12 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode13 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesPriceLimitRangeIncreaseMessageCode14 -> DecodeDerivativesPriceLimitRangeIncreaseMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode2 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode3 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode4 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode5 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode6 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode7 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode8 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode9 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode10 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode11 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode12 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode13 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode14 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode15 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode16 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode17 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode18 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode19 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode20 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode21 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode22 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesQuantityAllocationMessageCode23 -> DecodeDerivativesQuantityAllocationMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode2 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode3 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode4 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode5 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode6 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode7 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode8 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode9 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode10 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode11 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode12 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode13 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode14 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode15 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode16 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode17 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode18 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode19 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode20 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode21 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode22 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesGroupOrderAcceptanceHaltMessageCode23 -> DecodeDerivativesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode2 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode3 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode4 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode5 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode6 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode7 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode8 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode9 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode10 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode11 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode12 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode13 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode14 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode15 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode16 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = DerivativesBatchDataMessageCode17 -> DecodeDerivativesBatchDataMessage(bytes)
              [] tag = EquityDerivativesAdjustmentDetailsMessageCode -> DecodeEquityDerivativesAdjustmentDetailsMessage(bytes)
              [] tag = EquityDerivativesAdjustmentDetailsMessageCode2 -> DecodeEquityDerivativesAdjustmentDetailsMessage(bytes)
              [] tag = EquityDerivativesAdjustmentDetailsMessageCode3 -> DecodeEquityDerivativesAdjustmentDetailsMessage(bytes)
              [] tag = CommodityFuturesSettlementReferenceKtbMessageCode -> DecodeCommodityFuturesSettlementReferenceKtbMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode2 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode3 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode4 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode5 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode6 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode7 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode8 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode9 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode10 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode11 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode12 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode13 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode14 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode15 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode16 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesInvestorActivitiesMessageCode17 -> DecodeDerivativesInvestorActivitiesMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode2 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode3 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode4 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode5 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode6 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode7 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode8 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode9 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode10 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode11 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode12 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode13 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode14 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode15 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode16 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = DerivativesOpenInterestMessageCode17 -> DecodeDerivativesOpenInterestMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode2 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode3 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode4 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode5 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode6 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode7 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode8 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = FuturesSettledPriceMessageCode9 -> DecodeFuturesSettledPriceMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode2 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode3 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode4 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode5 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode6 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode7 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsBasePriceOfClearingMarginsMessageCode8 -> DecodeOptionsBasePriceOfClearingMarginsMessage(bytes)
              [] tag = OptionsImpliedVolatilityMessageCode -> DecodeOptionsImpliedVolatilityMessage(bytes)
              [] tag = OptionsImpliedVolatilityMessageCode2 -> DecodeOptionsImpliedVolatilityMessage(bytes)
              [] tag = OptionsImpliedVolatilityMessageCode3 -> DecodeOptionsImpliedVolatilityMessage(bytes)
              [] tag = OptionsImpliedVolatilityMessageCode4 -> DecodeOptionsImpliedVolatilityMessage(bytes)
              [] tag = OptionsImpliedVolatilityMessageCode5 -> DecodeOptionsImpliedVolatilityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode2 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode3 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode4 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode5 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode6 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode7 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = OptionsSensitivityMessageCode8 -> DecodeOptionsSensitivityMessage(bytes)
              [] tag = CommodityFuturesSpotSettlementReferenceMessageCode -> DecodeCommodityFuturesSpotSettlementReferenceMessage(bytes)
              [] tag = CommodityFuturesSpotSettlementReferenceMessageCode2 -> DecodeCommodityFuturesSpotSettlementReferenceMessage(bytes)
              [] tag = DailyDisclosedRfrMessageCode -> DecodeDailyDisclosedRfrMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> PollingDataMessageCode, body |-> ZeroPollingDataMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> PollingDataMessageCode, body |-> one] : one \in CheckedPollingDataMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode4, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode5, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode6, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode7, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode8, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode9, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode10, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode11, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode12, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode13, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteFiveLevelsMessageCode14, body |-> one] : one \in CheckedDerivativesQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesQuoteTenLevelsMessageCode, body |-> one] : one \in CheckedDerivativesQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesQuoteTenLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesQuoteTenLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode4, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode5, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode6, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode7, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode8, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode9, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode10, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode11, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode12, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode13, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotFiveLevelsMessageCode14, body |-> one] : one \in CheckedDerivativesSnapshotFiveLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotTenLevelsMessageCode, body |-> one] : one \in CheckedDerivativesSnapshotTenLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotTenLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesSnapshotTenLevelsMessage }
        \cup { [tag |-> DerivativesSnapshotTenLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesSnapshotTenLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode2, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode3, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode4, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode5, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode6, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode7, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode8, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode9, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode10, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode11, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode12, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode13, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode14, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode15, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode16, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledMessageCode17, body |-> one] : one \in CheckedDerivativesOrderFilledMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode4, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode5, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode6, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode7, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode8, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode9, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode10, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode11, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode12, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode13, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode14, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteTenLevelsMessageCode, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteTenLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesOrderFilledPlusQuoteTenLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesOrderFilledPlusQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode4, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode5, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode6, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode7, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode8, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode9, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode10, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode11, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode12, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode13, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode14, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode2, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode3, body |-> one] : one \in CheckedDerivativesMarketOperationTsPlusQuoteTenLevelsMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode2, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode3, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode4, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode5, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode6, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode7, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode8, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode9, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode10, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode11, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode12, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode13, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode14, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode15, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode16, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesNegotiatedTradeMessageCode17, body |-> one] : one \in CheckedDerivativesNegotiatedTradeMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode2, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode3, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode4, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode5, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode6, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode7, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode8, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode9, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode10, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode11, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode12, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode13, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode14, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode15, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode16, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode17, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode18, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode19, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode20, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode21, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode22, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode23, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode24, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode25, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode26, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode27, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode28, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode29, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesMarketOperationTsMessageCode30, body |-> one] : one \in CheckedDerivativesMarketOperationTsMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode2, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode3, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode4, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode5, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode6, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode7, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode8, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode9, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode10, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode11, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode12, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode13, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode14, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode15, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode16, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesIssueClosingMessageCode17, body |-> one] : one \in CheckedDerivativesIssueClosingMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode2, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode3, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode4, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode5, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode6, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode7, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode8, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode9, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode10, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode11, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode12, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode13, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode14, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode15, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode16, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode17, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode18, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode19, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode20, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode21, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode22, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode23, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode24, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode25, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode26, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode27, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode28, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode29, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesMarketOperationScheduleMessageCode30, body |-> one] : one \in CheckedDerivativesMarketOperationScheduleMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode2, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode3, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode4, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode5, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode6, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode7, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode8, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode9, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode10, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode11, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesDynamicUpperLowerLimitMessageCode12, body |-> one] : one \in CheckedDerivativesDynamicUpperLowerLimitMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode2, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode3, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode4, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode5, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode6, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode7, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode8, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode9, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode10, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode11, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode12, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode13, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode14, body |-> one] : one \in CheckedDerivativesPriceLimitRangeIncreaseMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode2, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode3, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode4, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode5, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode6, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode7, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode8, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode9, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode10, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode11, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode12, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode13, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode14, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode15, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode16, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode17, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode18, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode19, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode20, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode21, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode22, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesQuantityAllocationMessageCode23, body |-> one] : one \in CheckedDerivativesQuantityAllocationMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode2, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode3, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode4, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode5, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode6, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode7, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode8, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode9, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode10, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode11, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode12, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode13, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode14, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode15, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode16, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode17, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode18, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode19, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode20, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode21, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode22, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode23, body |-> one] : one \in CheckedDerivativesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode2, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode3, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode4, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode5, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode6, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode7, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode8, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode9, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode10, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode11, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode12, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode13, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode14, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode15, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode16, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> DerivativesBatchDataMessageCode17, body |-> one] : one \in CheckedDerivativesBatchDataMessage }
        \cup { [tag |-> EquityDerivativesAdjustmentDetailsMessageCode, body |-> one] : one \in CheckedEquityDerivativesAdjustmentDetailsMessage }
        \cup { [tag |-> EquityDerivativesAdjustmentDetailsMessageCode2, body |-> one] : one \in CheckedEquityDerivativesAdjustmentDetailsMessage }
        \cup { [tag |-> EquityDerivativesAdjustmentDetailsMessageCode3, body |-> one] : one \in CheckedEquityDerivativesAdjustmentDetailsMessage }
        \cup { [tag |-> CommodityFuturesSettlementReferenceKtbMessageCode, body |-> one] : one \in CheckedCommodityFuturesSettlementReferenceKtbMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode2, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode3, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode4, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode5, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode6, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode7, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode8, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode9, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode10, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode11, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode12, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode13, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode14, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode15, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode16, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesInvestorActivitiesMessageCode17, body |-> one] : one \in CheckedDerivativesInvestorActivitiesMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode2, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode3, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode4, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode5, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode6, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode7, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode8, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode9, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode10, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode11, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode12, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode13, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode14, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode15, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode16, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> DerivativesOpenInterestMessageCode17, body |-> one] : one \in CheckedDerivativesOpenInterestMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode2, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode3, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode4, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode5, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode6, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode7, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode8, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> FuturesSettledPriceMessageCode9, body |-> one] : one \in CheckedFuturesSettledPriceMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode2, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode3, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode4, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode5, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode6, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode7, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsBasePriceOfClearingMarginsMessageCode8, body |-> one] : one \in CheckedOptionsBasePriceOfClearingMarginsMessage }
        \cup { [tag |-> OptionsImpliedVolatilityMessageCode, body |-> one] : one \in CheckedOptionsImpliedVolatilityMessage }
        \cup { [tag |-> OptionsImpliedVolatilityMessageCode2, body |-> one] : one \in CheckedOptionsImpliedVolatilityMessage }
        \cup { [tag |-> OptionsImpliedVolatilityMessageCode3, body |-> one] : one \in CheckedOptionsImpliedVolatilityMessage }
        \cup { [tag |-> OptionsImpliedVolatilityMessageCode4, body |-> one] : one \in CheckedOptionsImpliedVolatilityMessage }
        \cup { [tag |-> OptionsImpliedVolatilityMessageCode5, body |-> one] : one \in CheckedOptionsImpliedVolatilityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode2, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode3, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode4, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode5, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode6, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode7, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> OptionsSensitivityMessageCode8, body |-> one] : one \in CheckedOptionsSensitivityMessage }
        \cup { [tag |-> CommodityFuturesSpotSettlementReferenceMessageCode, body |-> one] : one \in CheckedCommodityFuturesSpotSettlementReferenceMessage }
        \cup { [tag |-> CommodityFuturesSpotSettlementReferenceMessageCode2, body |-> one] : one \in CheckedCommodityFuturesSpotSettlementReferenceMessage }
        \cup { [tag |-> DailyDisclosedRfrMessageCode, body |-> one] : one \in CheckedDailyDisclosedRfrMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ payload : Payload ]

EncodePacket(message) ==
    message.payload.tag
        \o EncodePayload(message.payload)

DecodePacket(bytes) ==
    LET trCode == ReadBytes(bytes, 5) IN IF ~trCode.ok THEN Fail ELSE
    LET payload == DecodePayload(trCode.value, trCode.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

ZeroPacket ==
    [ payload |-> ZeroPayload ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Packet, written one after another *)
RECURSIVE EncodePacketList(_)
EncodePacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePacket(Head(messages)) \o EncodePacketList(Tail(messages))

(* As many Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadPacketAll(_)
ReadPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodePacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Packet of each kind, for the lists that carry them *)
OnePacket ==
    { [ZeroPacket EXCEPT !.payload = [tag |-> PollingDataMessageCode, body |-> ZeroPollingDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode2, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode3, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode4, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode5, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode6, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode7, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode8, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode9, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode10, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode11, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode12, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode13, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteFiveLevelsMessageCode14, body |-> ZeroDerivativesQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteTenLevelsMessageCode, body |-> ZeroDerivativesQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteTenLevelsMessageCode2, body |-> ZeroDerivativesQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuoteTenLevelsMessageCode3, body |-> ZeroDerivativesQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode2, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode3, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode4, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode5, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode6, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode7, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode8, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode9, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode10, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode11, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode12, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode13, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotFiveLevelsMessageCode14, body |-> ZeroDerivativesSnapshotFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotTenLevelsMessageCode, body |-> ZeroDerivativesSnapshotTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotTenLevelsMessageCode2, body |-> ZeroDerivativesSnapshotTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesSnapshotTenLevelsMessageCode3, body |-> ZeroDerivativesSnapshotTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode2, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode3, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode4, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode5, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode6, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode7, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode8, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode9, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode10, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode11, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode12, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode13, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode14, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode15, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode16, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledMessageCode17, body |-> ZeroDerivativesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode2, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode3, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode4, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode5, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode6, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode7, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode8, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode9, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode10, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode11, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode12, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode13, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteFiveLevelsMessageCode14, body |-> ZeroDerivativesOrderFilledPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteTenLevelsMessageCode, body |-> ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteTenLevelsMessageCode2, body |-> ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOrderFilledPlusQuoteTenLevelsMessageCode3, body |-> ZeroDerivativesOrderFilledPlusQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode2, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode3, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode4, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode5, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode6, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode7, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode8, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode9, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode10, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode11, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode12, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode13, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteFiveLevelsMessageCode14, body |-> ZeroDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode, body |-> ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode2, body |-> ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsPlusQuoteTenLevelsMessageCode3, body |-> ZeroDerivativesMarketOperationTsPlusQuoteTenLevelsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode2, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode3, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode4, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode5, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode6, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode7, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode8, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode9, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode10, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode11, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode12, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode13, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode14, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode15, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode16, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesNegotiatedTradeMessageCode17, body |-> ZeroDerivativesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode2, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode3, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode4, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode5, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode6, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode7, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode8, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode9, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode10, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode11, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode12, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode13, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode14, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode15, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode16, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode17, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode18, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode19, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode20, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode21, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode22, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode23, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode24, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode25, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode26, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode27, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode28, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode29, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationTsMessageCode30, body |-> ZeroDerivativesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode2, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode3, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode4, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode5, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode6, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode7, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode8, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode9, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode10, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode11, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode12, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode13, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode14, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode15, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode16, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesIssueClosingMessageCode17, body |-> ZeroDerivativesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode2, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode3, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode4, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode5, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode6, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode7, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode8, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode9, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode10, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode11, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode12, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode13, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode14, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode15, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode16, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode17, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode18, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode19, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode20, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode21, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode22, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode23, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode24, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode25, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode26, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode27, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode28, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode29, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesMarketOperationScheduleMessageCode30, body |-> ZeroDerivativesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode2, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode3, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode4, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode5, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode6, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode7, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode8, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode9, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode10, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode11, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesDynamicUpperLowerLimitMessageCode12, body |-> ZeroDerivativesDynamicUpperLowerLimitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode2, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode3, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode4, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode5, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode6, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode7, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode8, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode9, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode10, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode11, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode12, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode13, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesPriceLimitRangeIncreaseMessageCode14, body |-> ZeroDerivativesPriceLimitRangeIncreaseMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode2, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode3, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode4, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode5, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode6, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode7, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode8, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode9, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode10, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode11, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode12, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode13, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode14, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode15, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode16, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode17, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode18, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode19, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode20, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode21, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode22, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesQuantityAllocationMessageCode23, body |-> ZeroDerivativesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode2, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode3, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode4, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode5, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode6, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode7, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode8, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode9, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode10, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode11, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode12, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode13, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode14, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode15, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode16, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode17, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode18, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode19, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode20, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode21, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode22, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesGroupOrderAcceptanceHaltMessageCode23, body |-> ZeroDerivativesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode2, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode3, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode4, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode5, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode6, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode7, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode8, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode9, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode10, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode11, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode12, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode13, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode14, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode15, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode16, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesBatchDataMessageCode17, body |-> ZeroDerivativesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesAdjustmentDetailsMessageCode, body |-> ZeroEquityDerivativesAdjustmentDetailsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesAdjustmentDetailsMessageCode2, body |-> ZeroEquityDerivativesAdjustmentDetailsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesAdjustmentDetailsMessageCode3, body |-> ZeroEquityDerivativesAdjustmentDetailsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> CommodityFuturesSettlementReferenceKtbMessageCode, body |-> ZeroCommodityFuturesSettlementReferenceKtbMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode2, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode3, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode4, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode5, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode6, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode7, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode8, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode9, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode10, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode11, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode12, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode13, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode14, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode15, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode16, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesInvestorActivitiesMessageCode17, body |-> ZeroDerivativesInvestorActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode2, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode3, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode4, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode5, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode6, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode7, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode8, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode9, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode10, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode11, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode12, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode13, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode14, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode15, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode16, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DerivativesOpenInterestMessageCode17, body |-> ZeroDerivativesOpenInterestMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode2, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode3, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode4, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode5, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode6, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode7, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode8, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> FuturesSettledPriceMessageCode9, body |-> ZeroFuturesSettledPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode2, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode3, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode4, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode5, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode6, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode7, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsBasePriceOfClearingMarginsMessageCode8, body |-> ZeroOptionsBasePriceOfClearingMarginsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsImpliedVolatilityMessageCode, body |-> ZeroOptionsImpliedVolatilityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsImpliedVolatilityMessageCode2, body |-> ZeroOptionsImpliedVolatilityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsImpliedVolatilityMessageCode3, body |-> ZeroOptionsImpliedVolatilityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsImpliedVolatilityMessageCode4, body |-> ZeroOptionsImpliedVolatilityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsImpliedVolatilityMessageCode5, body |-> ZeroOptionsImpliedVolatilityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode2, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode3, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode4, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode5, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode6, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode7, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OptionsSensitivityMessageCode8, body |-> ZeroOptionsSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> CommodityFuturesSpotSettlementReferenceMessageCode, body |-> ZeroCommodityFuturesSpotSettlementReferenceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> CommodityFuturesSpotSettlementReferenceMessageCode2, body |-> ZeroCommodityFuturesSpotSettlementReferenceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DailyDisclosedRfrMessageCode, body |-> ZeroDailyDisclosedRfrMessage]] }

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

(* Every Polling Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPollingDataMessage ==
    \A message \in CheckedPollingDataMessage :
        LET read == DecodePollingDataMessage(EncodePollingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Quote Five Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesQuoteFiveLevelsMessage ==
    \A message \in CheckedDerivativesQuoteFiveLevelsMessage :
        LET read == DecodeDerivativesQuoteFiveLevelsMessage(EncodeDerivativesQuoteFiveLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Quote Ten Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesQuoteTenLevelsMessage ==
    \A message \in CheckedDerivativesQuoteTenLevelsMessage :
        LET read == DecodeDerivativesQuoteTenLevelsMessage(EncodeDerivativesQuoteTenLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Snapshot Five Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesSnapshotFiveLevelsMessage ==
    \A message \in CheckedDerivativesSnapshotFiveLevelsMessage :
        LET read == DecodeDerivativesSnapshotFiveLevelsMessage(EncodeDerivativesSnapshotFiveLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Snapshot Ten Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesSnapshotTenLevelsMessage ==
    \A message \in CheckedDerivativesSnapshotTenLevelsMessage :
        LET read == DecodeDerivativesSnapshotTenLevelsMessage(EncodeDerivativesSnapshotTenLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesOrderFilledMessage ==
    \A message \in CheckedDerivativesOrderFilledMessage :
        LET read == DecodeDerivativesOrderFilledMessage(EncodeDerivativesOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Order Filled Plus Quote Five Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesOrderFilledPlusQuoteFiveLevelsMessage ==
    \A message \in CheckedDerivativesOrderFilledPlusQuoteFiveLevelsMessage :
        LET read == DecodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(EncodeDerivativesOrderFilledPlusQuoteFiveLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Order Filled Plus Quote Ten Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesOrderFilledPlusQuoteTenLevelsMessage ==
    \A message \in CheckedDerivativesOrderFilledPlusQuoteTenLevelsMessage :
        LET read == DecodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(EncodeDerivativesOrderFilledPlusQuoteTenLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Market Operation Ts Plus Quote Five Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage ==
    \A message \in CheckedDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage :
        LET read == DecodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(EncodeDerivativesMarketOperationTsPlusQuoteFiveLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Market Operation Ts Plus Quote Ten Levels Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesMarketOperationTsPlusQuoteTenLevelsMessage ==
    \A message \in CheckedDerivativesMarketOperationTsPlusQuoteTenLevelsMessage :
        LET read == DecodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(EncodeDerivativesMarketOperationTsPlusQuoteTenLevelsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Negotiated Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesNegotiatedTradeMessage ==
    \A message \in CheckedDerivativesNegotiatedTradeMessage :
        LET read == DecodeDerivativesNegotiatedTradeMessage(EncodeDerivativesNegotiatedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Market Operation Ts Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesMarketOperationTsMessage ==
    \A message \in CheckedDerivativesMarketOperationTsMessage :
        LET read == DecodeDerivativesMarketOperationTsMessage(EncodeDerivativesMarketOperationTsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesIssueClosingMessage ==
    \A message \in CheckedDerivativesIssueClosingMessage :
        LET read == DecodeDerivativesIssueClosingMessage(EncodeDerivativesIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Market Operation Schedule Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesMarketOperationScheduleMessage ==
    \A message \in CheckedDerivativesMarketOperationScheduleMessage :
        LET read == DecodeDerivativesMarketOperationScheduleMessage(EncodeDerivativesMarketOperationScheduleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Dynamic Upper Lower Limit Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesDynamicUpperLowerLimitMessage ==
    \A message \in CheckedDerivativesDynamicUpperLowerLimitMessage :
        LET read == DecodeDerivativesDynamicUpperLowerLimitMessage(EncodeDerivativesDynamicUpperLowerLimitMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Price Limit Range Increase Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesPriceLimitRangeIncreaseMessage ==
    \A message \in CheckedDerivativesPriceLimitRangeIncreaseMessage :
        LET read == DecodeDerivativesPriceLimitRangeIncreaseMessage(EncodeDerivativesPriceLimitRangeIncreaseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Quantity Allocation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesQuantityAllocationMessage ==
    \A message \in CheckedDerivativesQuantityAllocationMessage :
        LET read == DecodeDerivativesQuantityAllocationMessage(EncodeDerivativesQuantityAllocationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Group Order Acceptance Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesGroupOrderAcceptanceHaltMessage ==
    \A message \in CheckedDerivativesGroupOrderAcceptanceHaltMessage :
        LET read == DecodeDerivativesGroupOrderAcceptanceHaltMessage(EncodeDerivativesGroupOrderAcceptanceHaltMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesBatchDataMessage ==
    \A message \in CheckedDerivativesBatchDataMessage :
        LET read == DecodeDerivativesBatchDataMessage(EncodeDerivativesBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity Derivatives Adjustment Details Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityDerivativesAdjustmentDetailsMessage ==
    \A message \in CheckedEquityDerivativesAdjustmentDetailsMessage :
        LET read == DecodeEquityDerivativesAdjustmentDetailsMessage(EncodeEquityDerivativesAdjustmentDetailsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Commodity Futures Settlement Reference Ktb Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCommodityFuturesSettlementReferenceKtbMessage ==
    \A message \in CheckedCommodityFuturesSettlementReferenceKtbMessage :
        LET read == DecodeCommodityFuturesSettlementReferenceKtbMessage(EncodeCommodityFuturesSettlementReferenceKtbMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Investor Activities Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesInvestorActivitiesMessage ==
    \A message \in CheckedDerivativesInvestorActivitiesMessage :
        LET read == DecodeDerivativesInvestorActivitiesMessage(EncodeDerivativesInvestorActivitiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivatives Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesOpenInterestMessage ==
    \A message \in CheckedDerivativesOpenInterestMessage :
        LET read == DecodeDerivativesOpenInterestMessage(EncodeDerivativesOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Settled Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesSettledPriceMessage ==
    \A message \in CheckedFuturesSettledPriceMessage :
        LET read == DecodeFuturesSettledPriceMessage(EncodeFuturesSettledPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Base Price Of Clearing Margins Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsBasePriceOfClearingMarginsMessage ==
    \A message \in CheckedOptionsBasePriceOfClearingMarginsMessage :
        LET read == DecodeOptionsBasePriceOfClearingMarginsMessage(EncodeOptionsBasePriceOfClearingMarginsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Implied Volatility Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsImpliedVolatilityMessage ==
    \A message \in CheckedOptionsImpliedVolatilityMessage :
        LET read == DecodeOptionsImpliedVolatilityMessage(EncodeOptionsImpliedVolatilityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Sensitivity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsSensitivityMessage ==
    \A message \in CheckedOptionsSensitivityMessage :
        LET read == DecodeOptionsSensitivityMessage(EncodeOptionsSensitivityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Commodity Futures Spot Settlement Reference Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCommodityFuturesSpotSettlementReferenceMessage ==
    \A message \in CheckedCommodityFuturesSpotSettlementReferenceMessage :
        LET read == DecodeCommodityFuturesSpotSettlementReferenceMessage(EncodeCommodityFuturesSpotSettlementReferenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Daily Disclosed Rfr Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDailyDisclosedRfrMessage ==
    \A message \in CheckedDailyDisclosedRfrMessage :
        LET read == DecodeDailyDisclosedRfrMessage(EncodeDailyDisclosedRfrMessage(message))
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

(* A Payload is selected by the Tr Code it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
