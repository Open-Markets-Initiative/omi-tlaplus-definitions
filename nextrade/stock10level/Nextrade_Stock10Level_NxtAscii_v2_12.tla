--------------- MODULE Nextrade_Stock10Level_NxtAscii_v2_12 ----------------
(***************************************************************************)
(* Nextrade Nextrade Stock Market Data 10 Level v2.12                      *)
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
(* Securities Quote 10 Level Message: 585 bytes                            *)
(***************************************************************************)

SecuritiesQuote10LevelMessage ==
    [ messageSequenceNumber                          : Sample(8),
      boardId                                        : Sample(2),
      sessionId                                      : Sample(2),
      isinCode                                       : Sample(12),
      aDesignatedNumberForAnIssueFromKrx             : Sample(6),
      processingTimeOfTradingSystem                  : Sample(12),
      askLevel1Price                                 : Sample(11),
      bidLevel1Price                                 : Sample(11),
      askLevel1Volume                                : Sample(12),
      bidLevel1Volume                                : Sample(12),
      askLevel2Price                                 : Sample(11),
      bidLevel2Price                                 : Sample(11),
      askLevel2Volume                                : Sample(12),
      bidLevel2Volume                                : Sample(12),
      askLevel3Price                                 : Sample(11),
      bidLevel3Price                                 : Sample(11),
      askLevel3Volume                                : Sample(12),
      bidLevel3Volume                                : Sample(12),
      askLevel4Price                                 : Sample(11),
      bidLevel4Price                                 : Sample(11),
      askLevel4Volume                                : Sample(12),
      bidLevel4Volume                                : Sample(12),
      askLevel5Price                                 : Sample(11),
      bidLevel5Price                                 : Sample(11),
      askLevel5Volume                                : Sample(12),
      bidLevel5Volume                                : Sample(12),
      askLevel6Price                                 : Sample(11),
      bidLevel6Price                                 : Sample(11),
      askLevel6Volume                                : Sample(12),
      bidLevel6Volume                                : Sample(12),
      askLevel7Price                                 : Sample(11),
      bidLevel7Price                                 : Sample(11),
      askLevel7Volume                                : Sample(12),
      bidLevel7Volume                                : Sample(12),
      askLevel8Price                                 : Sample(11),
      bidLevel8Price                                 : Sample(11),
      askLevel8Volume                                : Sample(12),
      bidLevel8Volume                                : Sample(12),
      askLevel9Price                                 : Sample(11),
      bidLevel9Price                                 : Sample(11),
      askLevel9Volume                                : Sample(12),
      bidLevel9Volume                                : Sample(12),
      askLevel10Price                                : Sample(11),
      bidLevel10Price                                : Sample(11),
      askLevel10Volume                               : Sample(12),
      bidLevel10Volume                               : Sample(12),
      totalAskVolume                                 : Sample(12),
      totalBidVolume                                 : Sample(12),
      estimatedTradingPrice                          : Sample(11),
      estimatedTradingVolume                         : Sample(12),
      midPrice                                       : Sample(11),
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice : Sample(12),
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice : Sample(12),
      endKeyword                                     : Sample(1) ]

EncodeSecuritiesQuote10LevelMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.midPrice
        \o message.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice
        \o message.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice
        \o message.endKeyword

DecodeSecuritiesQuote10LevelMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(bidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET midPrice == ReadBytes(estimatedTradingVolume.rest, 11) IN IF ~midPrice.ok THEN Fail ELSE
    LET totalMidPriceAskVolumeTotalAskVolumeOnMidPrice == ReadBytes(midPrice.rest, 12) IN IF ~totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.ok THEN Fail ELSE
    LET totalMidPriceBidVolumeTotalBidVolumeOnMidPrice == ReadBytes(totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.rest, 12) IN IF ~totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                          |-> messageSequenceNumber.value,
         boardId                                        |-> boardId.value,
         sessionId                                      |-> sessionId.value,
         isinCode                                       |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx             |-> aDesignatedNumberForAnIssueFromKrx.value,
         processingTimeOfTradingSystem                  |-> processingTimeOfTradingSystem.value,
         askLevel1Price                                 |-> askLevel1Price.value,
         bidLevel1Price                                 |-> bidLevel1Price.value,
         askLevel1Volume                                |-> askLevel1Volume.value,
         bidLevel1Volume                                |-> bidLevel1Volume.value,
         askLevel2Price                                 |-> askLevel2Price.value,
         bidLevel2Price                                 |-> bidLevel2Price.value,
         askLevel2Volume                                |-> askLevel2Volume.value,
         bidLevel2Volume                                |-> bidLevel2Volume.value,
         askLevel3Price                                 |-> askLevel3Price.value,
         bidLevel3Price                                 |-> bidLevel3Price.value,
         askLevel3Volume                                |-> askLevel3Volume.value,
         bidLevel3Volume                                |-> bidLevel3Volume.value,
         askLevel4Price                                 |-> askLevel4Price.value,
         bidLevel4Price                                 |-> bidLevel4Price.value,
         askLevel4Volume                                |-> askLevel4Volume.value,
         bidLevel4Volume                                |-> bidLevel4Volume.value,
         askLevel5Price                                 |-> askLevel5Price.value,
         bidLevel5Price                                 |-> bidLevel5Price.value,
         askLevel5Volume                                |-> askLevel5Volume.value,
         bidLevel5Volume                                |-> bidLevel5Volume.value,
         askLevel6Price                                 |-> askLevel6Price.value,
         bidLevel6Price                                 |-> bidLevel6Price.value,
         askLevel6Volume                                |-> askLevel6Volume.value,
         bidLevel6Volume                                |-> bidLevel6Volume.value,
         askLevel7Price                                 |-> askLevel7Price.value,
         bidLevel7Price                                 |-> bidLevel7Price.value,
         askLevel7Volume                                |-> askLevel7Volume.value,
         bidLevel7Volume                                |-> bidLevel7Volume.value,
         askLevel8Price                                 |-> askLevel8Price.value,
         bidLevel8Price                                 |-> bidLevel8Price.value,
         askLevel8Volume                                |-> askLevel8Volume.value,
         bidLevel8Volume                                |-> bidLevel8Volume.value,
         askLevel9Price                                 |-> askLevel9Price.value,
         bidLevel9Price                                 |-> bidLevel9Price.value,
         askLevel9Volume                                |-> askLevel9Volume.value,
         bidLevel9Volume                                |-> bidLevel9Volume.value,
         askLevel10Price                                |-> askLevel10Price.value,
         bidLevel10Price                                |-> bidLevel10Price.value,
         askLevel10Volume                               |-> askLevel10Volume.value,
         bidLevel10Volume                               |-> bidLevel10Volume.value,
         totalAskVolume                                 |-> totalAskVolume.value,
         totalBidVolume                                 |-> totalBidVolume.value,
         estimatedTradingPrice                          |-> estimatedTradingPrice.value,
         estimatedTradingVolume                         |-> estimatedTradingVolume.value,
         midPrice                                       |-> midPrice.value,
         totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.value,
         totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.value,
         endKeyword                                     |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesQuote10LevelMessage ==
    [ messageSequenceNumber                          |-> [i \in 1 .. 8 |-> 0],
      boardId                                        |-> [i \in 1 .. 2 |-> 0],
      sessionId                                      |-> [i \in 1 .. 2 |-> 0],
      isinCode                                       |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx             |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem                  |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume                                |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price                                |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price                                |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume                               |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume                               |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                                 |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                                 |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice                          |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume                         |-> [i \in 1 .. 12 |-> 0],
      midPrice                                       |-> [i \in 1 .. 11 |-> 0],
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> [i \in 1 .. 12 |-> 0],
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> [i \in 1 .. 12 |-> 0],
      endKeyword                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Quote 10 Level Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesQuote10LevelMessage ==
    { ZeroSecuritiesQuote10LevelMessage }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.midPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuote10LevelMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Order Filled Message: 181 bytes                              *)
(***************************************************************************)

SecuritiesOrderFilledMessage ==
    [ messageSequenceNumber              : Sample(8),
      boardId                            : Sample(2),
      sessionId                          : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      processingTimeOfTradingSystem      : Sample(12),
      priceChangeAgainstPreviousDay      : Sample(1),
      aPriceChangeAgainstThePreviousDay  : Sample(11),
      tradingPrice                       : Sample(11),
      tradingVolume                      : Sample(10),
      openingPrice                       : Sample(11),
      todaysHigh                         : Sample(11),
      todaysLow                          : Sample(11),
      accumulatedTradingVolume           : Sample(12),
      accumulatedTradingValue            : Sample(22),
      finalAskBidTypeCode                : Sample(1),
      lpHoldingQuantity                  : Sample(15),
      theBestAsk                         : Sample(11),
      theBestBid                         : Sample(11),
      endKeyword                         : Sample(1) ]

EncodeSecuritiesOrderFilledMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.processingTimeOfTradingSystem
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.lpHoldingQuantity
        \o message.theBestAsk
        \o message.theBestBid
        \o message.endKeyword

DecodeSecuritiesOrderFilledMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(processingTimeOfTradingSystem.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(tradingVolume.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET lpHoldingQuantity == ReadBytes(finalAskBidTypeCode.rest, 15) IN IF ~lpHoldingQuantity.ok THEN Fail ELSE
    LET theBestAsk == ReadBytes(lpHoldingQuantity.rest, 11) IN IF ~theBestAsk.ok THEN Fail ELSE
    LET theBestBid == ReadBytes(theBestAsk.rest, 11) IN IF ~theBestBid.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(theBestBid.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber              |-> messageSequenceNumber.value,
         boardId                            |-> boardId.value,
         sessionId                          |-> sessionId.value,
         isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         processingTimeOfTradingSystem      |-> processingTimeOfTradingSystem.value,
         priceChangeAgainstPreviousDay      |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay  |-> aPriceChangeAgainstThePreviousDay.value,
         tradingPrice                       |-> tradingPrice.value,
         tradingVolume                      |-> tradingVolume.value,
         openingPrice                       |-> openingPrice.value,
         todaysHigh                         |-> todaysHigh.value,
         todaysLow                          |-> todaysLow.value,
         accumulatedTradingVolume           |-> accumulatedTradingVolume.value,
         accumulatedTradingValue            |-> accumulatedTradingValue.value,
         finalAskBidTypeCode                |-> finalAskBidTypeCode.value,
         lpHoldingQuantity                  |-> lpHoldingQuantity.value,
         theBestAsk                         |-> theBestAsk.value,
         theBestBid                         |-> theBestBid.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesOrderFilledMessage ==
    [ messageSequenceNumber              |-> [i \in 1 .. 8 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      sessionId                          |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem      |-> [i \in 1 .. 12 |-> 0],
      priceChangeAgainstPreviousDay      |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay  |-> [i \in 1 .. 11 |-> 0],
      tradingPrice                       |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                      |-> [i \in 1 .. 10 |-> 0],
      openingPrice                       |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                         |-> [i \in 1 .. 11 |-> 0],
      todaysLow                          |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume           |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue            |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode                |-> [i \in 1 .. 1 |-> 0],
      lpHoldingQuantity                  |-> [i \in 1 .. 15 |-> 0],
      theBestAsk                         |-> [i \in 1 .. 11 |-> 0],
      theBestBid                         |-> [i \in 1 .. 11 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesOrderFilledMessage ==
    { ZeroSecuritiesOrderFilledMessage }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.lpHoldingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.theBestAsk = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.theBestBid = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Operation Ts Message: 63 bytes                                   *)
(***************************************************************************)

MarketOperationTsMessage ==
    [ messageSequenceNumber              : Sample(8),
      boardId                            : Sample(2),
      sessionId                          : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      processingTimeOfTradingSystem      : Sample(12),
      boardEventId                       : Sample(3),
      startTimeOfABoardEvent             : Sample(9),
      boardEventGroupCode                : Sample(5),
      tradingHaltReasonCode              : Sample(3),
      endKeyword                         : Sample(1) ]

EncodeMarketOperationTsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.tradingHaltReasonCode
        \o message.endKeyword

DecodeMarketOperationTsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber              |-> messageSequenceNumber.value,
         boardId                            |-> boardId.value,
         sessionId                          |-> sessionId.value,
         isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         processingTimeOfTradingSystem      |-> processingTimeOfTradingSystem.value,
         boardEventId                       |-> boardEventId.value,
         startTimeOfABoardEvent             |-> startTimeOfABoardEvent.value,
         boardEventGroupCode                |-> boardEventGroupCode.value,
         tradingHaltReasonCode              |-> tradingHaltReasonCode.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroMarketOperationTsMessage ==
    [ messageSequenceNumber              |-> [i \in 1 .. 8 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      sessionId                          |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem      |-> [i \in 1 .. 12 |-> 0],
      boardEventId                       |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent             |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode                |-> [i \in 1 .. 5 |-> 0],
      tradingHaltReasonCode              |-> [i \in 1 .. 3 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOperationTsMessage ==
    { ZeroMarketOperationTsMessage }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Closing Message: 107 bytes                                        *)
(***************************************************************************)

IssueClosingMessage ==
    [ messageSequenceNumber                                    : Sample(8),
      boardId                                                  : Sample(2),
      isinCode                                                 : Sample(12),
      aDesignatedNumberForAnIssueFromKrx                       : Sample(6),
      closingPrice                                             : Sample(11),
      closingPriceTypeCode                                     : Sample(1),
      upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession : Sample(11),
      lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession : Sample(11),
      closingPriceWeightedStockPriceAverage                    : Sample(11),
      closingPriceBasePriceOfBuyIn                             : Sample(11),
      closingPriceUpperLimitOfBuyIn                            : Sample(11),
      closingPriceLowerLimitOfBuyIn                            : Sample(11),
      endKeyword                                               : Sample(1) ]

EncodeIssueClosingMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.closingPrice
        \o message.closingPriceTypeCode
        \o message.upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession
        \o message.lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession
        \o message.closingPriceWeightedStockPriceAverage
        \o message.closingPriceBasePriceOfBuyIn
        \o message.closingPriceUpperLimitOfBuyIn
        \o message.closingPriceLowerLimitOfBuyIn
        \o message.endKeyword

DecodeIssueClosingMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 11) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession == ReadBytes(closingPriceTypeCode.rest, 11) IN IF ~upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.ok THEN Fail ELSE
    LET lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession == ReadBytes(upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.rest, 11) IN IF ~lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.ok THEN Fail ELSE
    LET closingPriceWeightedStockPriceAverage == ReadBytes(lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.rest, 11) IN IF ~closingPriceWeightedStockPriceAverage.ok THEN Fail ELSE
    LET closingPriceBasePriceOfBuyIn == ReadBytes(closingPriceWeightedStockPriceAverage.rest, 11) IN IF ~closingPriceBasePriceOfBuyIn.ok THEN Fail ELSE
    LET closingPriceUpperLimitOfBuyIn == ReadBytes(closingPriceBasePriceOfBuyIn.rest, 11) IN IF ~closingPriceUpperLimitOfBuyIn.ok THEN Fail ELSE
    LET closingPriceLowerLimitOfBuyIn == ReadBytes(closingPriceUpperLimitOfBuyIn.rest, 11) IN IF ~closingPriceLowerLimitOfBuyIn.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceLowerLimitOfBuyIn.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                    |-> messageSequenceNumber.value,
         boardId                                                  |-> boardId.value,
         isinCode                                                 |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx                       |-> aDesignatedNumberForAnIssueFromKrx.value,
         closingPrice                                             |-> closingPrice.value,
         closingPriceTypeCode                                     |-> closingPriceTypeCode.value,
         upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession |-> upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.value,
         lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession |-> lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.value,
         closingPriceWeightedStockPriceAverage                    |-> closingPriceWeightedStockPriceAverage.value,
         closingPriceBasePriceOfBuyIn                             |-> closingPriceBasePriceOfBuyIn.value,
         closingPriceUpperLimitOfBuyIn                            |-> closingPriceUpperLimitOfBuyIn.value,
         closingPriceLowerLimitOfBuyIn                            |-> closingPriceLowerLimitOfBuyIn.value,
         endKeyword                                               |-> endKeyword.value ], endKeyword.rest)

ZeroIssueClosingMessage ==
    [ messageSequenceNumber                                    |-> [i \in 1 .. 8 |-> 0],
      boardId                                                  |-> [i \in 1 .. 2 |-> 0],
      isinCode                                                 |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx                       |-> [i \in 1 .. 6 |-> 0],
      closingPrice                                             |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode                                     |-> [i \in 1 .. 1 |-> 0],
      upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession |-> [i \in 1 .. 11 |-> 0],
      closingPriceWeightedStockPriceAverage                    |-> [i \in 1 .. 11 |-> 0],
      closingPriceBasePriceOfBuyIn                             |-> [i \in 1 .. 11 |-> 0],
      closingPriceUpperLimitOfBuyIn                            |-> [i \in 1 .. 11 |-> 0],
      closingPriceLowerLimitOfBuyIn                            |-> [i \in 1 .. 11 |-> 0],
      endKeyword                                               |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueClosingMessage ==
    { ZeroIssueClosingMessage }
        \cup { [ZeroIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPrice = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceWeightedStockPriceAverage = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceBasePriceOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceUpperLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceLowerLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Triggering Removing Vi Message: 111 bytes                               *)
(***************************************************************************)

TriggeringRemovingViMessage ==
    [ messageSequenceNumber              : Sample(8),
      boardId                            : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      processingTimeOfTradingSystem      : Sample(12),
      theTimeEndingVi                    : Sample(9),
      viStatusCode                       : Sample(1),
      viTypeCode                         : Sample(1),
      aBasePriceToTriggerStaticVi        : Sample(11),
      aBasePriceToTriggerDynamicVi       : Sample(11),
      viTriggeringPrice                  : Sample(11),
      disparateRatioToTriggerStaticVi    : Sample(13),
      disparateRatioToTriggerDynamicVi   : Sample(13),
      endKeyword                         : Sample(1) ]

EncodeTriggeringRemovingViMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.processingTimeOfTradingSystem
        \o message.theTimeEndingVi
        \o message.viStatusCode
        \o message.viTypeCode
        \o message.aBasePriceToTriggerStaticVi
        \o message.aBasePriceToTriggerDynamicVi
        \o message.viTriggeringPrice
        \o message.disparateRatioToTriggerStaticVi
        \o message.disparateRatioToTriggerDynamicVi
        \o message.endKeyword

DecodeTriggeringRemovingViMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET theTimeEndingVi == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~theTimeEndingVi.ok THEN Fail ELSE
    LET viStatusCode == ReadBytes(theTimeEndingVi.rest, 1) IN IF ~viStatusCode.ok THEN Fail ELSE
    LET viTypeCode == ReadBytes(viStatusCode.rest, 1) IN IF ~viTypeCode.ok THEN Fail ELSE
    LET aBasePriceToTriggerStaticVi == ReadBytes(viTypeCode.rest, 11) IN IF ~aBasePriceToTriggerStaticVi.ok THEN Fail ELSE
    LET aBasePriceToTriggerDynamicVi == ReadBytes(aBasePriceToTriggerStaticVi.rest, 11) IN IF ~aBasePriceToTriggerDynamicVi.ok THEN Fail ELSE
    LET viTriggeringPrice == ReadBytes(aBasePriceToTriggerDynamicVi.rest, 11) IN IF ~viTriggeringPrice.ok THEN Fail ELSE
    LET disparateRatioToTriggerStaticVi == ReadBytes(viTriggeringPrice.rest, 13) IN IF ~disparateRatioToTriggerStaticVi.ok THEN Fail ELSE
    LET disparateRatioToTriggerDynamicVi == ReadBytes(disparateRatioToTriggerStaticVi.rest, 13) IN IF ~disparateRatioToTriggerDynamicVi.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(disparateRatioToTriggerDynamicVi.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber              |-> messageSequenceNumber.value,
         boardId                            |-> boardId.value,
         isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         processingTimeOfTradingSystem      |-> processingTimeOfTradingSystem.value,
         theTimeEndingVi                    |-> theTimeEndingVi.value,
         viStatusCode                       |-> viStatusCode.value,
         viTypeCode                         |-> viTypeCode.value,
         aBasePriceToTriggerStaticVi        |-> aBasePriceToTriggerStaticVi.value,
         aBasePriceToTriggerDynamicVi       |-> aBasePriceToTriggerDynamicVi.value,
         viTriggeringPrice                  |-> viTriggeringPrice.value,
         disparateRatioToTriggerStaticVi    |-> disparateRatioToTriggerStaticVi.value,
         disparateRatioToTriggerDynamicVi   |-> disparateRatioToTriggerDynamicVi.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroTriggeringRemovingViMessage ==
    [ messageSequenceNumber              |-> [i \in 1 .. 8 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem      |-> [i \in 1 .. 12 |-> 0],
      theTimeEndingVi                    |-> [i \in 1 .. 9 |-> 0],
      viStatusCode                       |-> [i \in 1 .. 1 |-> 0],
      viTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      aBasePriceToTriggerStaticVi        |-> [i \in 1 .. 11 |-> 0],
      aBasePriceToTriggerDynamicVi       |-> [i \in 1 .. 11 |-> 0],
      viTriggeringPrice                  |-> [i \in 1 .. 11 |-> 0],
      disparateRatioToTriggerStaticVi    |-> [i \in 1 .. 13 |-> 0],
      disparateRatioToTriggerDynamicVi   |-> [i \in 1 .. 13 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Triggering Removing Vi Message at zero, then each field in turn at the values it is checked at *)
CheckedTriggeringRemovingViMessage ==
    { ZeroTriggeringRemovingViMessage }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.theTimeEndingVi = one] : one \in Sample(9) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.viStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.viTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.aBasePriceToTriggerStaticVi = one] : one \in Sample(11) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.aBasePriceToTriggerDynamicVi = one] : one \in Sample(11) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.viTriggeringPrice = one] : one \in Sample(11) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.disparateRatioToTriggerStaticVi = one] : one \in Sample(13) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.disparateRatioToTriggerDynamicVi = one] : one \in Sample(13) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Closing Price Trading Quote Message: 53 bytes                           *)
(***************************************************************************)

ClosingPriceTradingQuoteMessage ==
    [ messageSequenceNumber              : Sample(8),
      boardId                            : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      totalAskVolume                     : Sample(12),
      totalBidVolume                     : Sample(12),
      endKeyword                         : Sample(1) ]

EncodeClosingPriceTradingQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.endKeyword

DecodeClosingPriceTradingQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalBidVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber              |-> messageSequenceNumber.value,
         boardId                            |-> boardId.value,
         isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         totalAskVolume                     |-> totalAskVolume.value,
         totalBidVolume                     |-> totalBidVolume.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroClosingPriceTradingQuoteMessage ==
    [ messageSequenceNumber              |-> [i \in 1 .. 8 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      totalAskVolume                     |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                     |-> [i \in 1 .. 12 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Closing Price Trading Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingPriceTradingQuoteMessage ==
    { ZeroClosingPriceTradingQuoteMessage }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by TR Code                                            *)
(***************************************************************************)

PollingDataMessageCode == <<73, 50, 53, 48, 48>>  \* "I2500"
SecuritiesQuote10LevelMessageCode == <<66, 54, 53, 49, 83>>  \* "B651S"
SecuritiesQuote10LevelMessageCode2 == <<66, 54, 53, 49, 81>>  \* "B651Q"
SecuritiesOrderFilledMessageCode == <<65, 51, 53, 49, 83>>  \* "A351S"
SecuritiesOrderFilledMessageCode2 == <<65, 51, 53, 49, 81>>  \* "A351Q"
MarketOperationTsMessageCode == <<65, 55, 53, 49, 83>>  \* "A751S"
MarketOperationTsMessageCode2 == <<65, 55, 53, 49, 81>>  \* "A751Q"
IssueClosingMessageCode == <<65, 54, 53, 49, 83>>  \* "A651S"
IssueClosingMessageCode2 == <<65, 54, 53, 49, 81>>  \* "A651Q"
TriggeringRemovingViMessageCode == <<82, 56, 53, 49, 83>>  \* "R851S"
TriggeringRemovingViMessageCode2 == <<82, 56, 53, 49, 81>>  \* "R851Q"
ClosingPriceTradingQuoteMessageCode == <<69, 49, 53, 49, 83>>  \* "E151S"
ClosingPriceTradingQuoteMessageCode2 == <<69, 49, 53, 49, 81>>  \* "E151Q"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {SecuritiesQuote10LevelMessageCode}, body : SecuritiesQuote10LevelMessage ]
        \cup [ tag : {SecuritiesQuote10LevelMessageCode2}, body : SecuritiesQuote10LevelMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode2}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {MarketOperationTsMessageCode}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode2}, body : MarketOperationTsMessage ]
        \cup [ tag : {IssueClosingMessageCode}, body : IssueClosingMessage ]
        \cup [ tag : {IssueClosingMessageCode2}, body : IssueClosingMessage ]
        \cup [ tag : {TriggeringRemovingViMessageCode}, body : TriggeringRemovingViMessage ]
        \cup [ tag : {TriggeringRemovingViMessageCode2}, body : TriggeringRemovingViMessage ]
        \cup [ tag : {ClosingPriceTradingQuoteMessageCode}, body : ClosingPriceTradingQuoteMessage ]
        \cup [ tag : {ClosingPriceTradingQuoteMessageCode2}, body : ClosingPriceTradingQuoteMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = SecuritiesQuote10LevelMessageCode -> EncodeSecuritiesQuote10LevelMessage(message.body)
      [] message.tag = SecuritiesQuote10LevelMessageCode2 -> EncodeSecuritiesQuote10LevelMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode2 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode2 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = IssueClosingMessageCode -> EncodeIssueClosingMessage(message.body)
      [] message.tag = IssueClosingMessageCode2 -> EncodeIssueClosingMessage(message.body)
      [] message.tag = TriggeringRemovingViMessageCode -> EncodeTriggeringRemovingViMessage(message.body)
      [] message.tag = TriggeringRemovingViMessageCode2 -> EncodeTriggeringRemovingViMessage(message.body)
      [] message.tag = ClosingPriceTradingQuoteMessageCode -> EncodeClosingPriceTradingQuoteMessage(message.body)
      [] message.tag = ClosingPriceTradingQuoteMessageCode2 -> EncodeClosingPriceTradingQuoteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = PollingDataMessageCode -> DecodePollingDataMessage(bytes)
              [] tag = SecuritiesQuote10LevelMessageCode -> DecodeSecuritiesQuote10LevelMessage(bytes)
              [] tag = SecuritiesQuote10LevelMessageCode2 -> DecodeSecuritiesQuote10LevelMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode2 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = MarketOperationTsMessageCode -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode2 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = IssueClosingMessageCode -> DecodeIssueClosingMessage(bytes)
              [] tag = IssueClosingMessageCode2 -> DecodeIssueClosingMessage(bytes)
              [] tag = TriggeringRemovingViMessageCode -> DecodeTriggeringRemovingViMessage(bytes)
              [] tag = TriggeringRemovingViMessageCode2 -> DecodeTriggeringRemovingViMessage(bytes)
              [] tag = ClosingPriceTradingQuoteMessageCode -> DecodeClosingPriceTradingQuoteMessage(bytes)
              [] tag = ClosingPriceTradingQuoteMessageCode2 -> DecodeClosingPriceTradingQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> PollingDataMessageCode, body |-> ZeroPollingDataMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> PollingDataMessageCode, body |-> one] : one \in CheckedPollingDataMessage }
        \cup { [tag |-> SecuritiesQuote10LevelMessageCode, body |-> one] : one \in CheckedSecuritiesQuote10LevelMessage }
        \cup { [tag |-> SecuritiesQuote10LevelMessageCode2, body |-> one] : one \in CheckedSecuritiesQuote10LevelMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode2, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> MarketOperationTsMessageCode, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode2, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> IssueClosingMessageCode, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> IssueClosingMessageCode2, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> TriggeringRemovingViMessageCode, body |-> one] : one \in CheckedTriggeringRemovingViMessage }
        \cup { [tag |-> TriggeringRemovingViMessageCode2, body |-> one] : one \in CheckedTriggeringRemovingViMessage }
        \cup { [tag |-> ClosingPriceTradingQuoteMessageCode, body |-> one] : one \in CheckedClosingPriceTradingQuoteMessage }
        \cup { [tag |-> ClosingPriceTradingQuoteMessageCode2, body |-> one] : one \in CheckedClosingPriceTradingQuoteMessage }

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
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuote10LevelMessageCode, body |-> ZeroSecuritiesQuote10LevelMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuote10LevelMessageCode2, body |-> ZeroSecuritiesQuote10LevelMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode2, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode2, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode2, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> TriggeringRemovingViMessageCode, body |-> ZeroTriggeringRemovingViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> TriggeringRemovingViMessageCode2, body |-> ZeroTriggeringRemovingViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> ClosingPriceTradingQuoteMessageCode, body |-> ZeroClosingPriceTradingQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> ClosingPriceTradingQuoteMessageCode2, body |-> ZeroClosingPriceTradingQuoteMessage]] }

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

(* Every Securities Quote 10 Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesQuote10LevelMessage ==
    \A message \in CheckedSecuritiesQuote10LevelMessage :
        LET read == DecodeSecuritiesQuote10LevelMessage(EncodeSecuritiesQuote10LevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesOrderFilledMessage ==
    \A message \in CheckedSecuritiesOrderFilledMessage :
        LET read == DecodeSecuritiesOrderFilledMessage(EncodeSecuritiesOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Operation Ts Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOperationTsMessage ==
    \A message \in CheckedMarketOperationTsMessage :
        LET read == DecodeMarketOperationTsMessage(EncodeMarketOperationTsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueClosingMessage ==
    \A message \in CheckedIssueClosingMessage :
        LET read == DecodeIssueClosingMessage(EncodeIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Triggering Removing Vi Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTriggeringRemovingViMessage ==
    \A message \in CheckedTriggeringRemovingViMessage :
        LET read == DecodeTriggeringRemovingViMessage(EncodeTriggeringRemovingViMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Price Trading Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingPriceTradingQuoteMessage ==
    \A message \in CheckedClosingPriceTradingQuoteMessage :
        LET read == DecodeClosingPriceTradingQuoteMessage(EncodeClosingPriceTradingQuoteMessage(message))
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

(* A Payload is selected by the TR Code it is written under *)
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
