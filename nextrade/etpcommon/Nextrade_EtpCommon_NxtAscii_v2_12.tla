----------------- MODULE Nextrade_EtpCommon_NxtAscii_v2_12 -----------------
(***************************************************************************)
(* Nextrade Nextrade Etp Market Data Common v2.12                          *)
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
(* Securities Quote Mm Lp Quotes Included 10 Level Message: 825 bytes      *)
(***************************************************************************)

SecuritiesQuoteMmLpQuotesIncluded10LevelMessage ==
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
      lpAskLevel1Volume                              : Sample(12),
      lpBidLevel1Volume                              : Sample(12),
      askLevel2Price                                 : Sample(11),
      bidLevel2Price                                 : Sample(11),
      askLevel2Volume                                : Sample(12),
      bidLevel2Volume                                : Sample(12),
      lpAskLevel2Volume                              : Sample(12),
      lpBidLevel2Volume                              : Sample(12),
      askLevel3Price                                 : Sample(11),
      bidLevel3Price                                 : Sample(11),
      askLevel3Volume                                : Sample(12),
      bidLevel3Volume                                : Sample(12),
      lpAskLevel3Volume                              : Sample(12),
      lpBidLevel3Volume                              : Sample(12),
      askLevel4Price                                 : Sample(11),
      bidLevel4Price                                 : Sample(11),
      askLevel4Volume                                : Sample(12),
      bidLevel4Volume                                : Sample(12),
      lpAskLevel4Volume                              : Sample(12),
      lpBidLevel4Volume                              : Sample(12),
      askLevel5Price                                 : Sample(11),
      bidLevel5Price                                 : Sample(11),
      askLevel5Volume                                : Sample(12),
      bidLevel5Volume                                : Sample(12),
      lpAskLevel5Volume                              : Sample(12),
      lpBidLevel5Volume                              : Sample(12),
      askLevel6Price                                 : Sample(11),
      bidLevel6Price                                 : Sample(11),
      askLevel6Volume                                : Sample(12),
      bidLevel6Volume                                : Sample(12),
      lpAskLevel6Volume                              : Sample(12),
      lpBidLevel6Volume                              : Sample(12),
      askLevel7Price                                 : Sample(11),
      bidLevel7Price                                 : Sample(11),
      askLevel7Volume                                : Sample(12),
      bidLevel7Volume                                : Sample(12),
      lpAskLevel7Volume                              : Sample(12),
      lpBidLevel7Volume                              : Sample(12),
      askLevel8Price                                 : Sample(11),
      bidLevel8Price                                 : Sample(11),
      askLevel8Volume                                : Sample(12),
      bidLevel8Volume                                : Sample(12),
      lpAskLevel8Volume                              : Sample(12),
      lpBidLevel8Volume                              : Sample(12),
      askLevel9Price                                 : Sample(11),
      bidLevel9Price                                 : Sample(11),
      askLevel9Volume                                : Sample(12),
      bidLevel9Volume                                : Sample(12),
      lpAskLevel9Volume                              : Sample(12),
      lpBidLevel9Volume                              : Sample(12),
      askLevel10Price                                : Sample(11),
      bidLevel10Price                                : Sample(11),
      askLevel10Volume                               : Sample(12),
      bidLevel10Volume                               : Sample(12),
      lpAskLevel10Volume                             : Sample(12),
      lpBidLevel10Volume                             : Sample(12),
      totalAskVolume                                 : Sample(12),
      totalBidVolume                                 : Sample(12),
      estimatedTradingPrice                          : Sample(11),
      estimatedTradingVolume                         : Sample(12),
      midPrice                                       : Sample(11),
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice : Sample(12),
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice : Sample(12),
      endKeyword                                     : Sample(1) ]

EncodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(message) ==
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
        \o message.lpAskLevel1Volume
        \o message.lpBidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.lpAskLevel2Volume
        \o message.lpBidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.lpAskLevel3Volume
        \o message.lpBidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.lpAskLevel4Volume
        \o message.lpBidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.lpAskLevel5Volume
        \o message.lpBidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.lpAskLevel6Volume
        \o message.lpBidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.lpAskLevel7Volume
        \o message.lpBidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.lpAskLevel8Volume
        \o message.lpBidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.lpAskLevel9Volume
        \o message.lpBidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.lpAskLevel10Volume
        \o message.lpBidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.midPrice
        \o message.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice
        \o message.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice
        \o message.endKeyword

DecodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(bytes) ==
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
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 12) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 12) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 12) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 12) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 12) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 12) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 12) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 12) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 12) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 12) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 12) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 12) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 12) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 12) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 12) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 12) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 12) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 12) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
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
         lpAskLevel1Volume                              |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume                              |-> lpBidLevel1Volume.value,
         askLevel2Price                                 |-> askLevel2Price.value,
         bidLevel2Price                                 |-> bidLevel2Price.value,
         askLevel2Volume                                |-> askLevel2Volume.value,
         bidLevel2Volume                                |-> bidLevel2Volume.value,
         lpAskLevel2Volume                              |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume                              |-> lpBidLevel2Volume.value,
         askLevel3Price                                 |-> askLevel3Price.value,
         bidLevel3Price                                 |-> bidLevel3Price.value,
         askLevel3Volume                                |-> askLevel3Volume.value,
         bidLevel3Volume                                |-> bidLevel3Volume.value,
         lpAskLevel3Volume                              |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume                              |-> lpBidLevel3Volume.value,
         askLevel4Price                                 |-> askLevel4Price.value,
         bidLevel4Price                                 |-> bidLevel4Price.value,
         askLevel4Volume                                |-> askLevel4Volume.value,
         bidLevel4Volume                                |-> bidLevel4Volume.value,
         lpAskLevel4Volume                              |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume                              |-> lpBidLevel4Volume.value,
         askLevel5Price                                 |-> askLevel5Price.value,
         bidLevel5Price                                 |-> bidLevel5Price.value,
         askLevel5Volume                                |-> askLevel5Volume.value,
         bidLevel5Volume                                |-> bidLevel5Volume.value,
         lpAskLevel5Volume                              |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume                              |-> lpBidLevel5Volume.value,
         askLevel6Price                                 |-> askLevel6Price.value,
         bidLevel6Price                                 |-> bidLevel6Price.value,
         askLevel6Volume                                |-> askLevel6Volume.value,
         bidLevel6Volume                                |-> bidLevel6Volume.value,
         lpAskLevel6Volume                              |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume                              |-> lpBidLevel6Volume.value,
         askLevel7Price                                 |-> askLevel7Price.value,
         bidLevel7Price                                 |-> bidLevel7Price.value,
         askLevel7Volume                                |-> askLevel7Volume.value,
         bidLevel7Volume                                |-> bidLevel7Volume.value,
         lpAskLevel7Volume                              |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume                              |-> lpBidLevel7Volume.value,
         askLevel8Price                                 |-> askLevel8Price.value,
         bidLevel8Price                                 |-> bidLevel8Price.value,
         askLevel8Volume                                |-> askLevel8Volume.value,
         bidLevel8Volume                                |-> bidLevel8Volume.value,
         lpAskLevel8Volume                              |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume                              |-> lpBidLevel8Volume.value,
         askLevel9Price                                 |-> askLevel9Price.value,
         bidLevel9Price                                 |-> bidLevel9Price.value,
         askLevel9Volume                                |-> askLevel9Volume.value,
         bidLevel9Volume                                |-> bidLevel9Volume.value,
         lpAskLevel9Volume                              |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume                              |-> lpBidLevel9Volume.value,
         askLevel10Price                                |-> askLevel10Price.value,
         bidLevel10Price                                |-> bidLevel10Price.value,
         askLevel10Volume                               |-> askLevel10Volume.value,
         bidLevel10Volume                               |-> bidLevel10Volume.value,
         lpAskLevel10Volume                             |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume                             |-> lpBidLevel10Volume.value,
         totalAskVolume                                 |-> totalAskVolume.value,
         totalBidVolume                                 |-> totalBidVolume.value,
         estimatedTradingPrice                          |-> estimatedTradingPrice.value,
         estimatedTradingVolume                         |-> estimatedTradingVolume.value,
         midPrice                                       |-> midPrice.value,
         totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.value,
         totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.value,
         endKeyword                                     |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage ==
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
      lpAskLevel1Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price                                |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price                                |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume                               |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume                               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume                             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume                             |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                                 |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                                 |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice                          |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume                         |-> [i \in 1 .. 12 |-> 0],
      midPrice                                       |-> [i \in 1 .. 11 |-> 0],
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> [i \in 1 .. 12 |-> 0],
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> [i \in 1 .. 12 |-> 0],
      endKeyword                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Quote Mm Lp Quotes Included 10 Level Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesQuoteMmLpQuotesIncluded10LevelMessage ==
    { ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.midPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
(* Equities Snapshot Mm Lp Quotes Included 10 Level Message: 930 bytes     *)
(***************************************************************************)

EquitiesSnapshotMmLpQuotesIncluded10LevelMessage ==
    [ boardId                                        : Sample(2),
      sessionId                                      : Sample(2),
      isinCode                                       : Sample(12),
      aDesignatedNumberForAnIssueFromKrx             : Sample(6),
      priceChangeAgainstPreviousDay                  : Sample(1),
      aPriceChangeAgainstThePreviousDay              : Sample(11),
      upperLimitPrice                                : Sample(11),
      lowerLimitPrice                                : Sample(11),
      currentPrice                                   : Sample(11),
      openingPrice                                   : Sample(11),
      todaysHigh                                     : Sample(11),
      todaysLow                                      : Sample(11),
      accumulatedTradingVolume                       : Sample(12),
      accumulatedTradingValue                        : Sample(22),
      finalAskBidTypeCode                            : Sample(1),
      askLevel1Price                                 : Sample(11),
      bidLevel1Price                                 : Sample(11),
      askLevel1Volume                                : Sample(12),
      bidLevel1Volume                                : Sample(12),
      lpAskLevel1Volume                              : Sample(12),
      lpBidLevel1Volume                              : Sample(12),
      askLevel2Price                                 : Sample(11),
      bidLevel2Price                                 : Sample(11),
      askLevel2Volume                                : Sample(12),
      bidLevel2Volume                                : Sample(12),
      lpAskLevel2Volume                              : Sample(12),
      lpBidLevel2Volume                              : Sample(12),
      askLevel3Price                                 : Sample(11),
      bidLevel3Price                                 : Sample(11),
      askLevel3Volume                                : Sample(12),
      bidLevel3Volume                                : Sample(12),
      lpAskLevel3Volume                              : Sample(12),
      lpBidLevel3Volume                              : Sample(12),
      askLevel4Price                                 : Sample(11),
      bidLevel4Price                                 : Sample(11),
      askLevel4Volume                                : Sample(12),
      bidLevel4Volume                                : Sample(12),
      lpAskLevel4Volume                              : Sample(12),
      lpBidLevel4Volume                              : Sample(12),
      askLevel5Price                                 : Sample(11),
      bidLevel5Price                                 : Sample(11),
      askLevel5Volume                                : Sample(12),
      bidLevel5Volume                                : Sample(12),
      lpAskLevel5Volume                              : Sample(12),
      lpBidLevel5Volume                              : Sample(12),
      askLevel6Price                                 : Sample(11),
      bidLevel6Price                                 : Sample(11),
      askLevel6Volume                                : Sample(12),
      bidLevel6Volume                                : Sample(12),
      lpAskLevel6Volume                              : Sample(12),
      lpBidLevel6Volume                              : Sample(12),
      askLevel7Price                                 : Sample(11),
      bidLevel7Price                                 : Sample(11),
      askLevel7Volume                                : Sample(12),
      bidLevel7Volume                                : Sample(12),
      lpAskLevel7Volume                              : Sample(12),
      lpBidLevel7Volume                              : Sample(12),
      askLevel8Price                                 : Sample(11),
      bidLevel8Price                                 : Sample(11),
      askLevel8Volume                                : Sample(12),
      bidLevel8Volume                                : Sample(12),
      lpAskLevel8Volume                              : Sample(12),
      lpBidLevel8Volume                              : Sample(12),
      askLevel9Price                                 : Sample(11),
      bidLevel9Price                                 : Sample(11),
      askLevel9Volume                                : Sample(12),
      bidLevel9Volume                                : Sample(12),
      lpAskLevel9Volume                              : Sample(12),
      lpBidLevel9Volume                              : Sample(12),
      askLevel10Price                                : Sample(11),
      bidLevel10Price                                : Sample(11),
      askLevel10Volume                               : Sample(12),
      bidLevel10Volume                               : Sample(12),
      lpAskLevel10Volume                             : Sample(12),
      lpBidLevel10Volume                             : Sample(12),
      totalAskVolume                                 : Sample(12),
      totalBidVolume                                 : Sample(12),
      estimatedTradingPrice                          : Sample(11),
      estimatedTradingVolume                         : Sample(12),
      closingPriceTypeCode                           : Sample(1),
      tradingHalt                                    : Sample(1),
      knockOutElwTypeCode                            : Sample(1),
      knockOutElwTriggeringTime                      : Sample(9),
      midPrice                                       : Sample(11),
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice : Sample(12),
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice : Sample(12),
      endKeyword                                     : Sample(1) ]

EncodeEquitiesSnapshotMmLpQuotesIncluded10LevelMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.currentPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.lpAskLevel1Volume
        \o message.lpBidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.lpAskLevel2Volume
        \o message.lpBidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.lpAskLevel3Volume
        \o message.lpBidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.lpAskLevel4Volume
        \o message.lpBidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.lpAskLevel5Volume
        \o message.lpBidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.lpAskLevel6Volume
        \o message.lpBidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.lpAskLevel7Volume
        \o message.lpBidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.lpAskLevel8Volume
        \o message.lpBidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.lpAskLevel9Volume
        \o message.lpBidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.lpAskLevel10Volume
        \o message.lpBidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.closingPriceTypeCode
        \o message.tradingHalt
        \o message.knockOutElwTypeCode
        \o message.knockOutElwTriggeringTime
        \o message.midPrice
        \o message.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice
        \o message.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice
        \o message.endKeyword

DecodeEquitiesSnapshotMmLpQuotesIncluded10LevelMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET currentPrice == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~currentPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(currentPrice.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(finalAskBidTypeCode.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 12) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 12) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 12) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 12) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 12) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 12) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 12) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 12) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 12) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 12) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 12) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 12) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 12) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 12) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 12) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 12) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 12) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 12) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(closingPriceTypeCode.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET knockOutElwTypeCode == ReadBytes(tradingHalt.rest, 1) IN IF ~knockOutElwTypeCode.ok THEN Fail ELSE
    LET knockOutElwTriggeringTime == ReadBytes(knockOutElwTypeCode.rest, 9) IN IF ~knockOutElwTriggeringTime.ok THEN Fail ELSE
    LET midPrice == ReadBytes(knockOutElwTriggeringTime.rest, 11) IN IF ~midPrice.ok THEN Fail ELSE
    LET totalMidPriceAskVolumeTotalAskVolumeOnMidPrice == ReadBytes(midPrice.rest, 12) IN IF ~totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.ok THEN Fail ELSE
    LET totalMidPriceBidVolumeTotalBidVolumeOnMidPrice == ReadBytes(totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.rest, 12) IN IF ~totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                                        |-> boardId.value,
         sessionId                                      |-> sessionId.value,
         isinCode                                       |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx             |-> aDesignatedNumberForAnIssueFromKrx.value,
         priceChangeAgainstPreviousDay                  |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay              |-> aPriceChangeAgainstThePreviousDay.value,
         upperLimitPrice                                |-> upperLimitPrice.value,
         lowerLimitPrice                                |-> lowerLimitPrice.value,
         currentPrice                                   |-> currentPrice.value,
         openingPrice                                   |-> openingPrice.value,
         todaysHigh                                     |-> todaysHigh.value,
         todaysLow                                      |-> todaysLow.value,
         accumulatedTradingVolume                       |-> accumulatedTradingVolume.value,
         accumulatedTradingValue                        |-> accumulatedTradingValue.value,
         finalAskBidTypeCode                            |-> finalAskBidTypeCode.value,
         askLevel1Price                                 |-> askLevel1Price.value,
         bidLevel1Price                                 |-> bidLevel1Price.value,
         askLevel1Volume                                |-> askLevel1Volume.value,
         bidLevel1Volume                                |-> bidLevel1Volume.value,
         lpAskLevel1Volume                              |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume                              |-> lpBidLevel1Volume.value,
         askLevel2Price                                 |-> askLevel2Price.value,
         bidLevel2Price                                 |-> bidLevel2Price.value,
         askLevel2Volume                                |-> askLevel2Volume.value,
         bidLevel2Volume                                |-> bidLevel2Volume.value,
         lpAskLevel2Volume                              |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume                              |-> lpBidLevel2Volume.value,
         askLevel3Price                                 |-> askLevel3Price.value,
         bidLevel3Price                                 |-> bidLevel3Price.value,
         askLevel3Volume                                |-> askLevel3Volume.value,
         bidLevel3Volume                                |-> bidLevel3Volume.value,
         lpAskLevel3Volume                              |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume                              |-> lpBidLevel3Volume.value,
         askLevel4Price                                 |-> askLevel4Price.value,
         bidLevel4Price                                 |-> bidLevel4Price.value,
         askLevel4Volume                                |-> askLevel4Volume.value,
         bidLevel4Volume                                |-> bidLevel4Volume.value,
         lpAskLevel4Volume                              |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume                              |-> lpBidLevel4Volume.value,
         askLevel5Price                                 |-> askLevel5Price.value,
         bidLevel5Price                                 |-> bidLevel5Price.value,
         askLevel5Volume                                |-> askLevel5Volume.value,
         bidLevel5Volume                                |-> bidLevel5Volume.value,
         lpAskLevel5Volume                              |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume                              |-> lpBidLevel5Volume.value,
         askLevel6Price                                 |-> askLevel6Price.value,
         bidLevel6Price                                 |-> bidLevel6Price.value,
         askLevel6Volume                                |-> askLevel6Volume.value,
         bidLevel6Volume                                |-> bidLevel6Volume.value,
         lpAskLevel6Volume                              |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume                              |-> lpBidLevel6Volume.value,
         askLevel7Price                                 |-> askLevel7Price.value,
         bidLevel7Price                                 |-> bidLevel7Price.value,
         askLevel7Volume                                |-> askLevel7Volume.value,
         bidLevel7Volume                                |-> bidLevel7Volume.value,
         lpAskLevel7Volume                              |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume                              |-> lpBidLevel7Volume.value,
         askLevel8Price                                 |-> askLevel8Price.value,
         bidLevel8Price                                 |-> bidLevel8Price.value,
         askLevel8Volume                                |-> askLevel8Volume.value,
         bidLevel8Volume                                |-> bidLevel8Volume.value,
         lpAskLevel8Volume                              |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume                              |-> lpBidLevel8Volume.value,
         askLevel9Price                                 |-> askLevel9Price.value,
         bidLevel9Price                                 |-> bidLevel9Price.value,
         askLevel9Volume                                |-> askLevel9Volume.value,
         bidLevel9Volume                                |-> bidLevel9Volume.value,
         lpAskLevel9Volume                              |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume                              |-> lpBidLevel9Volume.value,
         askLevel10Price                                |-> askLevel10Price.value,
         bidLevel10Price                                |-> bidLevel10Price.value,
         askLevel10Volume                               |-> askLevel10Volume.value,
         bidLevel10Volume                               |-> bidLevel10Volume.value,
         lpAskLevel10Volume                             |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume                             |-> lpBidLevel10Volume.value,
         totalAskVolume                                 |-> totalAskVolume.value,
         totalBidVolume                                 |-> totalBidVolume.value,
         estimatedTradingPrice                          |-> estimatedTradingPrice.value,
         estimatedTradingVolume                         |-> estimatedTradingVolume.value,
         closingPriceTypeCode                           |-> closingPriceTypeCode.value,
         tradingHalt                                    |-> tradingHalt.value,
         knockOutElwTypeCode                            |-> knockOutElwTypeCode.value,
         knockOutElwTriggeringTime                      |-> knockOutElwTriggeringTime.value,
         midPrice                                       |-> midPrice.value,
         totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.value,
         totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.value,
         endKeyword                                     |-> endKeyword.value ], endKeyword.rest)

ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage ==
    [ boardId                                        |-> [i \in 1 .. 2 |-> 0],
      sessionId                                      |-> [i \in 1 .. 2 |-> 0],
      isinCode                                       |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx             |-> [i \in 1 .. 6 |-> 0],
      priceChangeAgainstPreviousDay                  |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay              |-> [i \in 1 .. 11 |-> 0],
      upperLimitPrice                                |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                                |-> [i \in 1 .. 11 |-> 0],
      currentPrice                                   |-> [i \in 1 .. 11 |-> 0],
      openingPrice                                   |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                                     |-> [i \in 1 .. 11 |-> 0],
      todaysLow                                      |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume                       |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue                        |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode                            |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel1Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                                 |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                                 |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume                                |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume                                |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume                              |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume                              |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price                                |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price                                |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume                               |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume                               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume                             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume                             |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                                 |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                                 |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice                          |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume                         |-> [i \in 1 .. 12 |-> 0],
      closingPriceTypeCode                           |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                                    |-> [i \in 1 .. 1 |-> 0],
      knockOutElwTypeCode                            |-> [i \in 1 .. 1 |-> 0],
      knockOutElwTriggeringTime                      |-> [i \in 1 .. 9 |-> 0],
      midPrice                                       |-> [i \in 1 .. 11 |-> 0],
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> [i \in 1 .. 12 |-> 0],
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> [i \in 1 .. 12 |-> 0],
      endKeyword                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Equities Snapshot Mm Lp Quotes Included 10 Level Message at zero, then each field in turn at the values it is checked at *)
CheckedEquitiesSnapshotMmLpQuotesIncluded10LevelMessage ==
    { ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.currentPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.knockOutElwTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.knockOutElwTriggeringTime = one] : one \in Sample(9) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.midPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Activities Per Commodities Message: 79 bytes                   *)
(***************************************************************************)

InvestorActivitiesPerCommoditiesMessage ==
    [ calculationTime             : Sample(6),
      investorCode                : Sample(4),
      accumulatedAskTradingVolume : Sample(12),
      accumulatedAskTradingValue  : Sample(22),
      accumulatedBidTradingVolume : Sample(12),
      accumulatedBidTradingValue  : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeInvestorActivitiesPerCommoditiesMessage(message) ==
    message.calculationTime
        \o message.investorCode
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.endKeyword

DecodeInvestorActivitiesPerCommoditiesMessage(bytes) ==
    LET calculationTime == ReadBytes(bytes, 6) IN IF ~calculationTime.ok THEN Fail ELSE
    LET investorCode == ReadBytes(calculationTime.rest, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(investorCode.rest, 12) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 12) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedBidTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ calculationTime             |-> calculationTime.value,
         investorCode                |-> investorCode.value,
         accumulatedAskTradingVolume |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue  |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue  |-> accumulatedBidTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroInvestorActivitiesPerCommoditiesMessage ==
    [ calculationTime             |-> [i \in 1 .. 6 |-> 0],
      investorCode                |-> [i \in 1 .. 4 |-> 0],
      accumulatedAskTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingValue  |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedBidTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Investor Activities Per Commodities Message at zero, then each field in turn at the values it is checked at *)
CheckedInvestorActivitiesPerCommoditiesMessage ==
    { ZeroInvestorActivitiesPerCommoditiesMessage }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.calculationTime = one] : one \in Sample(6) }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroInvestorActivitiesPerCommoditiesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etp Constituents Message: 204 bytes                                     *)
(***************************************************************************)

EtpConstituentsMessage ==
    [ messageSequenceNumber               : Sample(8),
      indexCalculationInstitutionTypeCode : Sample(2),
      indexMarketClassificationId         : Sample(6),
      indexSequenceNumber                 : Sample(3),
      indexLeverageInverseTypeCode        : Sample(2),
      indexName                           : Sample(80),
      indexNameInEn                       : Sample(80),
      indexAssetClassificationId1         : Sample(6),
      indexAssetClassificationId2         : Sample(6),
      indexId                             : Sample(6),
      filler4                             : Sample(4),
      endKeyword                          : Sample(1) ]

EncodeEtpConstituentsMessage(message) ==
    message.messageSequenceNumber
        \o message.indexCalculationInstitutionTypeCode
        \o message.indexMarketClassificationId
        \o message.indexSequenceNumber
        \o message.indexLeverageInverseTypeCode
        \o message.indexName
        \o message.indexNameInEn
        \o message.indexAssetClassificationId1
        \o message.indexAssetClassificationId2
        \o message.indexId
        \o message.filler4
        \o message.endKeyword

DecodeEtpConstituentsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET indexCalculationInstitutionTypeCode == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~indexCalculationInstitutionTypeCode.ok THEN Fail ELSE
    LET indexMarketClassificationId == ReadBytes(indexCalculationInstitutionTypeCode.rest, 6) IN IF ~indexMarketClassificationId.ok THEN Fail ELSE
    LET indexSequenceNumber == ReadBytes(indexMarketClassificationId.rest, 3) IN IF ~indexSequenceNumber.ok THEN Fail ELSE
    LET indexLeverageInverseTypeCode == ReadBytes(indexSequenceNumber.rest, 2) IN IF ~indexLeverageInverseTypeCode.ok THEN Fail ELSE
    LET indexName == ReadBytes(indexLeverageInverseTypeCode.rest, 80) IN IF ~indexName.ok THEN Fail ELSE
    LET indexNameInEn == ReadBytes(indexName.rest, 80) IN IF ~indexNameInEn.ok THEN Fail ELSE
    LET indexAssetClassificationId1 == ReadBytes(indexNameInEn.rest, 6) IN IF ~indexAssetClassificationId1.ok THEN Fail ELSE
    LET indexAssetClassificationId2 == ReadBytes(indexAssetClassificationId1.rest, 6) IN IF ~indexAssetClassificationId2.ok THEN Fail ELSE
    LET indexId == ReadBytes(indexAssetClassificationId2.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(indexId.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber               |-> messageSequenceNumber.value,
         indexCalculationInstitutionTypeCode |-> indexCalculationInstitutionTypeCode.value,
         indexMarketClassificationId         |-> indexMarketClassificationId.value,
         indexSequenceNumber                 |-> indexSequenceNumber.value,
         indexLeverageInverseTypeCode        |-> indexLeverageInverseTypeCode.value,
         indexName                           |-> indexName.value,
         indexNameInEn                       |-> indexNameInEn.value,
         indexAssetClassificationId1         |-> indexAssetClassificationId1.value,
         indexAssetClassificationId2         |-> indexAssetClassificationId2.value,
         indexId                             |-> indexId.value,
         filler4                             |-> filler4.value,
         endKeyword                          |-> endKeyword.value ], endKeyword.rest)

ZeroEtpConstituentsMessage ==
    [ messageSequenceNumber               |-> [i \in 1 .. 8 |-> 0],
      indexCalculationInstitutionTypeCode |-> [i \in 1 .. 2 |-> 0],
      indexMarketClassificationId         |-> [i \in 1 .. 6 |-> 0],
      indexSequenceNumber                 |-> [i \in 1 .. 3 |-> 0],
      indexLeverageInverseTypeCode        |-> [i \in 1 .. 2 |-> 0],
      indexName                           |-> [i \in 1 .. 80 |-> 0],
      indexNameInEn                       |-> [i \in 1 .. 80 |-> 0],
      indexAssetClassificationId1         |-> [i \in 1 .. 6 |-> 0],
      indexAssetClassificationId2         |-> [i \in 1 .. 6 |-> 0],
      indexId                             |-> [i \in 1 .. 6 |-> 0],
      filler4                             |-> [i \in 1 .. 4 |-> 0],
      endKeyword                          |-> [i \in 1 .. 1 |-> 0] ]

(* Etp Constituents Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpConstituentsMessage ==
    { ZeroEtpConstituentsMessage }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexCalculationInstitutionTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexMarketClassificationId = one] : one \in Sample(6) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexSequenceNumber = one] : one \in Sample(3) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexLeverageInverseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexName = one] : one \in Sample(80) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexNameInEn = one] : one \in Sample(80) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexAssetClassificationId1 = one] : one \in Sample(6) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexAssetClassificationId2 = one] : one \in Sample(6) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroEtpConstituentsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Mm Lp Information Message: 217 bytes                                    *)
(***************************************************************************)

MmLpInformationMessage ==
    [ messageSequenceNumber                  : Sample(8),
      isinCode                               : Sample(12),
      marketParticipantNumber                : Sample(5),
      boardId                                : Sample(2),
      marketMakingLpTypeCode                 : Sample(1),
      lpStartDate                            : Sample(8),
      lpEndDate                              : Sample(8),
      minimumOrderVolume                     : Sample(11),
      maximumVolumeOfMultipleOrder           : Sample(11),
      bidAskSpreadUnitCode                   : Sample(1),
      mainMarketBidAskSpreadValue            : Sample(22),
      spreadMultipleForMarketHolidays        : Sample(11),
      anObligatoryTimeIntervalToPlaceAnOrder : Sample(6),
      minimumAskPrice                        : Sample(22),
      maximumBidPrice                        : Sample(22),
      minimumOrderPrice                      : Sample(22),
      maximumOrderPrice                      : Sample(22),
      extendedMarketBidAskSpreadValue        : Sample(22),
      endKeyword                             : Sample(1) ]

EncodeMmLpInformationMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.marketParticipantNumber
        \o message.boardId
        \o message.marketMakingLpTypeCode
        \o message.lpStartDate
        \o message.lpEndDate
        \o message.minimumOrderVolume
        \o message.maximumVolumeOfMultipleOrder
        \o message.bidAskSpreadUnitCode
        \o message.mainMarketBidAskSpreadValue
        \o message.spreadMultipleForMarketHolidays
        \o message.anObligatoryTimeIntervalToPlaceAnOrder
        \o message.minimumAskPrice
        \o message.maximumBidPrice
        \o message.minimumOrderPrice
        \o message.maximumOrderPrice
        \o message.extendedMarketBidAskSpreadValue
        \o message.endKeyword

DecodeMmLpInformationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET marketParticipantNumber == ReadBytes(isinCode.rest, 5) IN IF ~marketParticipantNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(marketParticipantNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET marketMakingLpTypeCode == ReadBytes(boardId.rest, 1) IN IF ~marketMakingLpTypeCode.ok THEN Fail ELSE
    LET lpStartDate == ReadBytes(marketMakingLpTypeCode.rest, 8) IN IF ~lpStartDate.ok THEN Fail ELSE
    LET lpEndDate == ReadBytes(lpStartDate.rest, 8) IN IF ~lpEndDate.ok THEN Fail ELSE
    LET minimumOrderVolume == ReadBytes(lpEndDate.rest, 11) IN IF ~minimumOrderVolume.ok THEN Fail ELSE
    LET maximumVolumeOfMultipleOrder == ReadBytes(minimumOrderVolume.rest, 11) IN IF ~maximumVolumeOfMultipleOrder.ok THEN Fail ELSE
    LET bidAskSpreadUnitCode == ReadBytes(maximumVolumeOfMultipleOrder.rest, 1) IN IF ~bidAskSpreadUnitCode.ok THEN Fail ELSE
    LET mainMarketBidAskSpreadValue == ReadBytes(bidAskSpreadUnitCode.rest, 22) IN IF ~mainMarketBidAskSpreadValue.ok THEN Fail ELSE
    LET spreadMultipleForMarketHolidays == ReadBytes(mainMarketBidAskSpreadValue.rest, 11) IN IF ~spreadMultipleForMarketHolidays.ok THEN Fail ELSE
    LET anObligatoryTimeIntervalToPlaceAnOrder == ReadBytes(spreadMultipleForMarketHolidays.rest, 6) IN IF ~anObligatoryTimeIntervalToPlaceAnOrder.ok THEN Fail ELSE
    LET minimumAskPrice == ReadBytes(anObligatoryTimeIntervalToPlaceAnOrder.rest, 22) IN IF ~minimumAskPrice.ok THEN Fail ELSE
    LET maximumBidPrice == ReadBytes(minimumAskPrice.rest, 22) IN IF ~maximumBidPrice.ok THEN Fail ELSE
    LET minimumOrderPrice == ReadBytes(maximumBidPrice.rest, 22) IN IF ~minimumOrderPrice.ok THEN Fail ELSE
    LET maximumOrderPrice == ReadBytes(minimumOrderPrice.rest, 22) IN IF ~maximumOrderPrice.ok THEN Fail ELSE
    LET extendedMarketBidAskSpreadValue == ReadBytes(maximumOrderPrice.rest, 22) IN IF ~extendedMarketBidAskSpreadValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(extendedMarketBidAskSpreadValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                  |-> messageSequenceNumber.value,
         isinCode                               |-> isinCode.value,
         marketParticipantNumber                |-> marketParticipantNumber.value,
         boardId                                |-> boardId.value,
         marketMakingLpTypeCode                 |-> marketMakingLpTypeCode.value,
         lpStartDate                            |-> lpStartDate.value,
         lpEndDate                              |-> lpEndDate.value,
         minimumOrderVolume                     |-> minimumOrderVolume.value,
         maximumVolumeOfMultipleOrder           |-> maximumVolumeOfMultipleOrder.value,
         bidAskSpreadUnitCode                   |-> bidAskSpreadUnitCode.value,
         mainMarketBidAskSpreadValue            |-> mainMarketBidAskSpreadValue.value,
         spreadMultipleForMarketHolidays        |-> spreadMultipleForMarketHolidays.value,
         anObligatoryTimeIntervalToPlaceAnOrder |-> anObligatoryTimeIntervalToPlaceAnOrder.value,
         minimumAskPrice                        |-> minimumAskPrice.value,
         maximumBidPrice                        |-> maximumBidPrice.value,
         minimumOrderPrice                      |-> minimumOrderPrice.value,
         maximumOrderPrice                      |-> maximumOrderPrice.value,
         extendedMarketBidAskSpreadValue        |-> extendedMarketBidAskSpreadValue.value,
         endKeyword                             |-> endKeyword.value ], endKeyword.rest)

ZeroMmLpInformationMessage ==
    [ messageSequenceNumber                  |-> [i \in 1 .. 8 |-> 0],
      isinCode                               |-> [i \in 1 .. 12 |-> 0],
      marketParticipantNumber                |-> [i \in 1 .. 5 |-> 0],
      boardId                                |-> [i \in 1 .. 2 |-> 0],
      marketMakingLpTypeCode                 |-> [i \in 1 .. 1 |-> 0],
      lpStartDate                            |-> [i \in 1 .. 8 |-> 0],
      lpEndDate                              |-> [i \in 1 .. 8 |-> 0],
      minimumOrderVolume                     |-> [i \in 1 .. 11 |-> 0],
      maximumVolumeOfMultipleOrder           |-> [i \in 1 .. 11 |-> 0],
      bidAskSpreadUnitCode                   |-> [i \in 1 .. 1 |-> 0],
      mainMarketBidAskSpreadValue            |-> [i \in 1 .. 22 |-> 0],
      spreadMultipleForMarketHolidays        |-> [i \in 1 .. 11 |-> 0],
      anObligatoryTimeIntervalToPlaceAnOrder |-> [i \in 1 .. 6 |-> 0],
      minimumAskPrice                        |-> [i \in 1 .. 22 |-> 0],
      maximumBidPrice                        |-> [i \in 1 .. 22 |-> 0],
      minimumOrderPrice                      |-> [i \in 1 .. 22 |-> 0],
      maximumOrderPrice                      |-> [i \in 1 .. 22 |-> 0],
      extendedMarketBidAskSpreadValue        |-> [i \in 1 .. 22 |-> 0],
      endKeyword                             |-> [i \in 1 .. 1 |-> 0] ]

(* Mm Lp Information Message at zero, then each field in turn at the values it is checked at *)
CheckedMmLpInformationMessage ==
    { ZeroMmLpInformationMessage }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.marketParticipantNumber = one] : one \in Sample(5) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.marketMakingLpTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.lpStartDate = one] : one \in Sample(8) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.lpEndDate = one] : one \in Sample(8) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.minimumOrderVolume = one] : one \in Sample(11) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.maximumVolumeOfMultipleOrder = one] : one \in Sample(11) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.bidAskSpreadUnitCode = one] : one \in Sample(1) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.mainMarketBidAskSpreadValue = one] : one \in Sample(22) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.spreadMultipleForMarketHolidays = one] : one \in Sample(11) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.anObligatoryTimeIntervalToPlaceAnOrder = one] : one \in Sample(6) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.minimumAskPrice = one] : one \in Sample(22) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.maximumBidPrice = one] : one \in Sample(22) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.minimumOrderPrice = one] : one \in Sample(22) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.maximumOrderPrice = one] : one \in Sample(22) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.extendedMarketBidAskSpreadValue = one] : one \in Sample(22) }
        \cup { [ZeroMmLpInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Operation Schedule Message: 78 bytes                             *)
(***************************************************************************)

MarketOperationScheduleMessage ==
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

EncodeMarketOperationScheduleMessage(message) ==
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

DecodeMarketOperationScheduleMessage(bytes) ==
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

ZeroMarketOperationScheduleMessage ==
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

(* Market Operation Schedule Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOperationScheduleMessage ==
    { ZeroMarketOperationScheduleMessage }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.sessionStartEndCode = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.isinCodeOfACommonStock = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.tradingHaltTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.stepApplied = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.priceLimitRangeExpansionForBaseIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.expectedTimeOfExpandingPriceLimitRange = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Member Firm Imposing Lifting Sanctions Message: 41 bytes                *)
(***************************************************************************)

MemberFirmImposingLiftingSanctionsMessage ==
    [ isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      disclosingDataTypeCode             : Sample(3),
      disclosureTime                     : Sample(9),
      memberNumber                       : Sample(5),
      memberFirmTrustPrincipalTypeCode   : Sample(5),
      endKeyword                         : Sample(1) ]

EncodeMemberFirmImposingLiftingSanctionsMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.disclosingDataTypeCode
        \o message.disclosureTime
        \o message.memberNumber
        \o message.memberFirmTrustPrincipalTypeCode
        \o message.endKeyword

DecodeMemberFirmImposingLiftingSanctionsMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET disclosingDataTypeCode == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 3) IN IF ~disclosingDataTypeCode.ok THEN Fail ELSE
    LET disclosureTime == ReadBytes(disclosingDataTypeCode.rest, 9) IN IF ~disclosureTime.ok THEN Fail ELSE
    LET memberNumber == ReadBytes(disclosureTime.rest, 5) IN IF ~memberNumber.ok THEN Fail ELSE
    LET memberFirmTrustPrincipalTypeCode == ReadBytes(memberNumber.rest, 5) IN IF ~memberFirmTrustPrincipalTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(memberFirmTrustPrincipalTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         disclosingDataTypeCode             |-> disclosingDataTypeCode.value,
         disclosureTime                     |-> disclosureTime.value,
         memberNumber                       |-> memberNumber.value,
         memberFirmTrustPrincipalTypeCode   |-> memberFirmTrustPrincipalTypeCode.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroMemberFirmImposingLiftingSanctionsMessage ==
    [ isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      disclosingDataTypeCode             |-> [i \in 1 .. 3 |-> 0],
      disclosureTime                     |-> [i \in 1 .. 9 |-> 0],
      memberNumber                       |-> [i \in 1 .. 5 |-> 0],
      memberFirmTrustPrincipalTypeCode   |-> [i \in 1 .. 5 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Member Firm Imposing Lifting Sanctions Message at zero, then each field in turn at the values it is checked at *)
CheckedMemberFirmImposingLiftingSanctionsMessage ==
    { ZeroMemberFirmImposingLiftingSanctionsMessage }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.disclosingDataTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.disclosureTime = one] : one \in Sample(9) }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.memberNumber = one] : one \in Sample(5) }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.memberFirmTrustPrincipalTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroMemberFirmImposingLiftingSanctionsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Five Traders Activities Message: 409 bytes                          *)
(***************************************************************************)

TopFiveTradersActivitiesMessage ==
    [ isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      memberNumber1ForAsk                : Sample(5),
      askTradingVolume1                  : Sample(12),
      askTradingValue1                   : Sample(22),
      memberNumber1ForBid                : Sample(5),
      bidTradingVolume1                  : Sample(12),
      bidTradingValue1                   : Sample(22),
      memberNumber2ForAsk                : Sample(5),
      askTradingVolume2                  : Sample(12),
      askTradingValue2                   : Sample(22),
      memberNumber2ForBid                : Sample(5),
      bidTradingVolume2                  : Sample(12),
      bidTradingValue2                   : Sample(22),
      memberNumber3ForAsk                : Sample(5),
      askTradingVolume3                  : Sample(12),
      askTradingValue3                   : Sample(22),
      memberNumber3ForBid                : Sample(5),
      bidTradingVolume3                  : Sample(12),
      bidTradingValue3                   : Sample(22),
      memberNumber4ForAsk                : Sample(5),
      askTradingVolume4                  : Sample(12),
      askTradingValue4                   : Sample(22),
      memberNumber4ForBid                : Sample(5),
      bidTradingVolume4                  : Sample(12),
      bidTradingValue4                   : Sample(22),
      memberNumber5ForAsk                : Sample(5),
      askTradingVolume5                  : Sample(12),
      askTradingValue5                   : Sample(22),
      memberNumber5ForBid                : Sample(5),
      bidTradingVolume5                  : Sample(12),
      bidTradingValue5                   : Sample(22),
      endKeyword                         : Sample(1) ]

EncodeTopFiveTradersActivitiesMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.memberNumber1ForAsk
        \o message.askTradingVolume1
        \o message.askTradingValue1
        \o message.memberNumber1ForBid
        \o message.bidTradingVolume1
        \o message.bidTradingValue1
        \o message.memberNumber2ForAsk
        \o message.askTradingVolume2
        \o message.askTradingValue2
        \o message.memberNumber2ForBid
        \o message.bidTradingVolume2
        \o message.bidTradingValue2
        \o message.memberNumber3ForAsk
        \o message.askTradingVolume3
        \o message.askTradingValue3
        \o message.memberNumber3ForBid
        \o message.bidTradingVolume3
        \o message.bidTradingValue3
        \o message.memberNumber4ForAsk
        \o message.askTradingVolume4
        \o message.askTradingValue4
        \o message.memberNumber4ForBid
        \o message.bidTradingVolume4
        \o message.bidTradingValue4
        \o message.memberNumber5ForAsk
        \o message.askTradingVolume5
        \o message.askTradingValue5
        \o message.memberNumber5ForBid
        \o message.bidTradingVolume5
        \o message.bidTradingValue5
        \o message.endKeyword

DecodeTopFiveTradersActivitiesMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET memberNumber1ForAsk == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 5) IN IF ~memberNumber1ForAsk.ok THEN Fail ELSE
    LET askTradingVolume1 == ReadBytes(memberNumber1ForAsk.rest, 12) IN IF ~askTradingVolume1.ok THEN Fail ELSE
    LET askTradingValue1 == ReadBytes(askTradingVolume1.rest, 22) IN IF ~askTradingValue1.ok THEN Fail ELSE
    LET memberNumber1ForBid == ReadBytes(askTradingValue1.rest, 5) IN IF ~memberNumber1ForBid.ok THEN Fail ELSE
    LET bidTradingVolume1 == ReadBytes(memberNumber1ForBid.rest, 12) IN IF ~bidTradingVolume1.ok THEN Fail ELSE
    LET bidTradingValue1 == ReadBytes(bidTradingVolume1.rest, 22) IN IF ~bidTradingValue1.ok THEN Fail ELSE
    LET memberNumber2ForAsk == ReadBytes(bidTradingValue1.rest, 5) IN IF ~memberNumber2ForAsk.ok THEN Fail ELSE
    LET askTradingVolume2 == ReadBytes(memberNumber2ForAsk.rest, 12) IN IF ~askTradingVolume2.ok THEN Fail ELSE
    LET askTradingValue2 == ReadBytes(askTradingVolume2.rest, 22) IN IF ~askTradingValue2.ok THEN Fail ELSE
    LET memberNumber2ForBid == ReadBytes(askTradingValue2.rest, 5) IN IF ~memberNumber2ForBid.ok THEN Fail ELSE
    LET bidTradingVolume2 == ReadBytes(memberNumber2ForBid.rest, 12) IN IF ~bidTradingVolume2.ok THEN Fail ELSE
    LET bidTradingValue2 == ReadBytes(bidTradingVolume2.rest, 22) IN IF ~bidTradingValue2.ok THEN Fail ELSE
    LET memberNumber3ForAsk == ReadBytes(bidTradingValue2.rest, 5) IN IF ~memberNumber3ForAsk.ok THEN Fail ELSE
    LET askTradingVolume3 == ReadBytes(memberNumber3ForAsk.rest, 12) IN IF ~askTradingVolume3.ok THEN Fail ELSE
    LET askTradingValue3 == ReadBytes(askTradingVolume3.rest, 22) IN IF ~askTradingValue3.ok THEN Fail ELSE
    LET memberNumber3ForBid == ReadBytes(askTradingValue3.rest, 5) IN IF ~memberNumber3ForBid.ok THEN Fail ELSE
    LET bidTradingVolume3 == ReadBytes(memberNumber3ForBid.rest, 12) IN IF ~bidTradingVolume3.ok THEN Fail ELSE
    LET bidTradingValue3 == ReadBytes(bidTradingVolume3.rest, 22) IN IF ~bidTradingValue3.ok THEN Fail ELSE
    LET memberNumber4ForAsk == ReadBytes(bidTradingValue3.rest, 5) IN IF ~memberNumber4ForAsk.ok THEN Fail ELSE
    LET askTradingVolume4 == ReadBytes(memberNumber4ForAsk.rest, 12) IN IF ~askTradingVolume4.ok THEN Fail ELSE
    LET askTradingValue4 == ReadBytes(askTradingVolume4.rest, 22) IN IF ~askTradingValue4.ok THEN Fail ELSE
    LET memberNumber4ForBid == ReadBytes(askTradingValue4.rest, 5) IN IF ~memberNumber4ForBid.ok THEN Fail ELSE
    LET bidTradingVolume4 == ReadBytes(memberNumber4ForBid.rest, 12) IN IF ~bidTradingVolume4.ok THEN Fail ELSE
    LET bidTradingValue4 == ReadBytes(bidTradingVolume4.rest, 22) IN IF ~bidTradingValue4.ok THEN Fail ELSE
    LET memberNumber5ForAsk == ReadBytes(bidTradingValue4.rest, 5) IN IF ~memberNumber5ForAsk.ok THEN Fail ELSE
    LET askTradingVolume5 == ReadBytes(memberNumber5ForAsk.rest, 12) IN IF ~askTradingVolume5.ok THEN Fail ELSE
    LET askTradingValue5 == ReadBytes(askTradingVolume5.rest, 22) IN IF ~askTradingValue5.ok THEN Fail ELSE
    LET memberNumber5ForBid == ReadBytes(askTradingValue5.rest, 5) IN IF ~memberNumber5ForBid.ok THEN Fail ELSE
    LET bidTradingVolume5 == ReadBytes(memberNumber5ForBid.rest, 12) IN IF ~bidTradingVolume5.ok THEN Fail ELSE
    LET bidTradingValue5 == ReadBytes(bidTradingVolume5.rest, 22) IN IF ~bidTradingValue5.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidTradingValue5.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         memberNumber1ForAsk                |-> memberNumber1ForAsk.value,
         askTradingVolume1                  |-> askTradingVolume1.value,
         askTradingValue1                   |-> askTradingValue1.value,
         memberNumber1ForBid                |-> memberNumber1ForBid.value,
         bidTradingVolume1                  |-> bidTradingVolume1.value,
         bidTradingValue1                   |-> bidTradingValue1.value,
         memberNumber2ForAsk                |-> memberNumber2ForAsk.value,
         askTradingVolume2                  |-> askTradingVolume2.value,
         askTradingValue2                   |-> askTradingValue2.value,
         memberNumber2ForBid                |-> memberNumber2ForBid.value,
         bidTradingVolume2                  |-> bidTradingVolume2.value,
         bidTradingValue2                   |-> bidTradingValue2.value,
         memberNumber3ForAsk                |-> memberNumber3ForAsk.value,
         askTradingVolume3                  |-> askTradingVolume3.value,
         askTradingValue3                   |-> askTradingValue3.value,
         memberNumber3ForBid                |-> memberNumber3ForBid.value,
         bidTradingVolume3                  |-> bidTradingVolume3.value,
         bidTradingValue3                   |-> bidTradingValue3.value,
         memberNumber4ForAsk                |-> memberNumber4ForAsk.value,
         askTradingVolume4                  |-> askTradingVolume4.value,
         askTradingValue4                   |-> askTradingValue4.value,
         memberNumber4ForBid                |-> memberNumber4ForBid.value,
         bidTradingVolume4                  |-> bidTradingVolume4.value,
         bidTradingValue4                   |-> bidTradingValue4.value,
         memberNumber5ForAsk                |-> memberNumber5ForAsk.value,
         askTradingVolume5                  |-> askTradingVolume5.value,
         askTradingValue5                   |-> askTradingValue5.value,
         memberNumber5ForBid                |-> memberNumber5ForBid.value,
         bidTradingVolume5                  |-> bidTradingVolume5.value,
         bidTradingValue5                   |-> bidTradingValue5.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroTopFiveTradersActivitiesMessage ==
    [ isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      memberNumber1ForAsk                |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume1                  |-> [i \in 1 .. 12 |-> 0],
      askTradingValue1                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber1ForBid                |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume1                  |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue1                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber2ForAsk                |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume2                  |-> [i \in 1 .. 12 |-> 0],
      askTradingValue2                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber2ForBid                |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume2                  |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue2                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber3ForAsk                |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume3                  |-> [i \in 1 .. 12 |-> 0],
      askTradingValue3                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber3ForBid                |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume3                  |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue3                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber4ForAsk                |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume4                  |-> [i \in 1 .. 12 |-> 0],
      askTradingValue4                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber4ForBid                |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume4                  |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue4                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber5ForAsk                |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume5                  |-> [i \in 1 .. 12 |-> 0],
      askTradingValue5                   |-> [i \in 1 .. 22 |-> 0],
      memberNumber5ForBid                |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume5                  |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue5                   |-> [i \in 1 .. 22 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Top Five Traders Activities Message at zero, then each field in turn at the values it is checked at *)
CheckedTopFiveTradersActivitiesMessage ==
    { ZeroTopFiveTradersActivitiesMessage }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber1ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume1 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue1 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber1ForBid = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume1 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue1 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber2ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume2 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue2 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber2ForBid = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume2 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue2 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber3ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume3 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue3 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber3ForBid = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume3 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue3 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber4ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume4 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue4 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber4ForBid = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume4 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue4 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber5ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume5 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue5 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.memberNumber5ForBid = one] : one \in Sample(5) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume5 = one] : one \in Sample(12) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue5 = one] : one \in Sample(22) }
        \cup { [ZeroTopFiveTradersActivitiesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Equities Batch Data Message: 649 bytes                                  *)
(***************************************************************************)

EquitiesBatchDataMessage ==
    [ messageSequenceNumber                                  : Sample(8),
      totalNumberOfInstrumentsOfTheContract                  : Sample(6),
      businessDate                                           : Sample(8),
      isinCode                                               : Sample(12),
      aDesignatedNumberForAnIssueFromKrx                     : Sample(6),
      abbreviatedIssueCode                                   : Sample(9),
      abbreviatedIssueName                                   : Sample(40),
      abbreviatedIssueNameInEn                               : Sample(40),
      groupNumber                                            : Sample(5),
      marketOperationProductId                               : Sample(3),
      securityGroupId                                        : Sample(2),
      unitTrading                                            : Sample(1),
      rightsTypeCode                                         : Sample(2),
      parValueTypeCode                                       : Sample(2),
      anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice : Sample(1),
      reevaluationReasonCode                                 : Sample(2),
      basePriceChange                                        : Sample(1),
      randomEndTriggerCode                                   : Sample(1),
      marketAlert                                            : Sample(1),
      marketAlertTypeCode                                    : Sample(2),
      koreaCorporateGovernanceStockPriceIndexKogi            : Sample(1),
      issueForAdministration                                 : Sample(1),
      unfaithfulDisclosure                                   : Sample(1),
      backDoorListing                                        : Sample(1),
      tradingHalt                                            : Sample(1),
      industryId                                             : Sample(10),
      smallMediumSizedBusiness                               : Sample(1),
      sectionTypeCode                                        : Sample(1),
      investmentInstitutionTypeCode                          : Sample(1),
      basePrice                                              : Sample(11),
      yesterdaysClosingPriceTypeCodeKrx                      : Sample(1),
      yesterdaysClosingPriceKrx                              : Sample(11),
      yesterdaysAccumulatedTradingAmount                     : Sample(12),
      yesterdaysAccumulatedTradingValue                      : Sample(22),
      upperLimitPrice                                        : Sample(11),
      lowerLimitPrice                                        : Sample(11),
      substitutePriceOfSecurities                            : Sample(11),
      parValue                                               : Sample(11),
      issuingPrice                                           : Sample(11),
      listingDate                                            : Sample(8),
      numberOfListedShares                                   : Sample(16),
      liquidationTrade                                       : Sample(1),
      theEstablishmentDate                                   : Sample(8),
      maturityDate                                           : Sample(8),
      exercisingPeriod                                       : Sample(8),
      expirationDateForRight                                 : Sample(8),
      exercisePriceOfElwOrBw                                 : Sample(13),
      capital                                                : Sample(22),
      creditOrderPossibility                                 : Sample(1),
      limitOrderPermissionTypeCode                           : Sample(5),
      marketPriceOrderPermissionTypeCode                     : Sample(5),
      conditionedOrderPermissionTypeCode                     : Sample(5),
      bestFavorableOrderPermissionTypeCode                   : Sample(5),
      firstBestOrderPermissionType                           : Sample(5),
      midPriceOrderPermissionTypeCode                        : Sample(5),
      stopLimitPriceOrderPermissionTypeCode                  : Sample(5),
      capitalIncreaseTypeCode                                : Sample(2),
      otherStockTypeCode                                     : Sample(1),
      nationalStock                                          : Sample(1),
      appraisedPrice                                         : Sample(11),
      lowestOrderPrice                                       : Sample(11),
      highestOrderPrice                                      : Sample(11),
      unitOfVolumeInMainBoard                                : Sample(11),
      lotSizeAfterHoursTrading                               : Sample(11),
      reiTsTypeCode                                          : Sample(1),
      targetStockIsinCode                                    : Sample(12),
      currencyIsoCode                                        : Sample(3),
      countryCode                                            : Sample(3),
      marketMakingPossibility                                : Sample(1),
      closingPriceTradingPossibilityInTheAfterHours          : Sample(1),
      closingPriceTradingInThePreOpeningMarket               : Sample(1),
      blockTradingInThePreOpeningMarket                      : Sample(1),
      basketTradingInThePreOpeningMarket                     : Sample(1),
      announcementOfEstimatedTradingPrice                    : Sample(1),
      shortSelling                                           : Sample(1),
      etfTrackingDifference                                  : Sample(13),
      regs                                                   : Sample(1),
      spac                                                   : Sample(1),
      taxTypeCode                                            : Sample(1),
      appraisalRatioOfSubstitutePrice                        : Sample(13),
      investmentCautionIssue                                 : Sample(1),
      delistingDate                                          : Sample(8),
      shortTermOverheatIssueTypeCode                         : Sample(1),
      etfReplicationMethodsTypeCode                          : Sample(1),
      expirationDate                                         : Sample(8),
      distributionTypeCode                                   : Sample(2),
      calculationOfRedemptionPriceStartDate                  : Sample(8),
      calculationOfRedemptionPriceEndDate                    : Sample(8),
      etpProductTypeCode                                     : Sample(1),
      indexCalculationInstitutionTypeCode                    : Sample(2),
      indexMarketClassificationId                            : Sample(6),
      indexSequenceNumber                                    : Sample(3),
      trackingIndexLeverageInverseTypeCode                   : Sample(2),
      referenceIndexLeverageInverseTypeCode                  : Sample(2),
      indexAssetClassificationId1                            : Sample(6),
      indexAssetClassificationId2                            : Sample(6),
      ipoUnderwriterMemberNumber                             : Sample(5),
      lpOrder                                                : Sample(1),
      lowLiquidity                                           : Sample(1),
      abnormalRise                                           : Sample(1),
      upperLimitQuantity                                     : Sample(23),
      investmentPrecautionIssue                              : Sample(1),
      preferredStocksWithLesserShares                        : Sample(1),
      spacMerger                                             : Sample(1),
      segmentTypeCode                                        : Sample(1),
      afterMarketPossibility                                 : Sample(1),
      choiceOnCompetitiveTrading                             : Sample(1),
      limitOnCompetitiveTradingVolume                        : Sample(1),
      occurrenceOfReasonsProhibitingCompetitiveTrading       : Sample(1),
      approvalOnCompetitiveTrading                           : Sample(1),
      approvalOnNegotiationTrading                           : Sample(1),
      yesterdaysClosingPriceTypeCodeNxt                      : Sample(1),
      yesterdaysClosingPriceNxt                              : Sample(11),
      competitionBoardTradePermissionCode                    : Sample(5),
      negotiationPossibleOrNotBeforeMainMarket               : Sample(1),
      endKeyword                                             : Sample(1) ]

EncodeEquitiesBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.abbreviatedIssueCode
        \o message.abbreviatedIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.groupNumber
        \o message.marketOperationProductId
        \o message.securityGroupId
        \o message.unitTrading
        \o message.rightsTypeCode
        \o message.parValueTypeCode
        \o message.anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice
        \o message.reevaluationReasonCode
        \o message.basePriceChange
        \o message.randomEndTriggerCode
        \o message.marketAlert
        \o message.marketAlertTypeCode
        \o message.koreaCorporateGovernanceStockPriceIndexKogi
        \o message.issueForAdministration
        \o message.unfaithfulDisclosure
        \o message.backDoorListing
        \o message.tradingHalt
        \o message.industryId
        \o message.smallMediumSizedBusiness
        \o message.sectionTypeCode
        \o message.investmentInstitutionTypeCode
        \o message.basePrice
        \o message.yesterdaysClosingPriceTypeCodeKrx
        \o message.yesterdaysClosingPriceKrx
        \o message.yesterdaysAccumulatedTradingAmount
        \o message.yesterdaysAccumulatedTradingValue
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.substitutePriceOfSecurities
        \o message.parValue
        \o message.issuingPrice
        \o message.listingDate
        \o message.numberOfListedShares
        \o message.liquidationTrade
        \o message.theEstablishmentDate
        \o message.maturityDate
        \o message.exercisingPeriod
        \o message.expirationDateForRight
        \o message.exercisePriceOfElwOrBw
        \o message.capital
        \o message.creditOrderPossibility
        \o message.limitOrderPermissionTypeCode
        \o message.marketPriceOrderPermissionTypeCode
        \o message.conditionedOrderPermissionTypeCode
        \o message.bestFavorableOrderPermissionTypeCode
        \o message.firstBestOrderPermissionType
        \o message.midPriceOrderPermissionTypeCode
        \o message.stopLimitPriceOrderPermissionTypeCode
        \o message.capitalIncreaseTypeCode
        \o message.otherStockTypeCode
        \o message.nationalStock
        \o message.appraisedPrice
        \o message.lowestOrderPrice
        \o message.highestOrderPrice
        \o message.unitOfVolumeInMainBoard
        \o message.lotSizeAfterHoursTrading
        \o message.reiTsTypeCode
        \o message.targetStockIsinCode
        \o message.currencyIsoCode
        \o message.countryCode
        \o message.marketMakingPossibility
        \o message.closingPriceTradingPossibilityInTheAfterHours
        \o message.closingPriceTradingInThePreOpeningMarket
        \o message.blockTradingInThePreOpeningMarket
        \o message.basketTradingInThePreOpeningMarket
        \o message.announcementOfEstimatedTradingPrice
        \o message.shortSelling
        \o message.etfTrackingDifference
        \o message.regs
        \o message.spac
        \o message.taxTypeCode
        \o message.appraisalRatioOfSubstitutePrice
        \o message.investmentCautionIssue
        \o message.delistingDate
        \o message.shortTermOverheatIssueTypeCode
        \o message.etfReplicationMethodsTypeCode
        \o message.expirationDate
        \o message.distributionTypeCode
        \o message.calculationOfRedemptionPriceStartDate
        \o message.calculationOfRedemptionPriceEndDate
        \o message.etpProductTypeCode
        \o message.indexCalculationInstitutionTypeCode
        \o message.indexMarketClassificationId
        \o message.indexSequenceNumber
        \o message.trackingIndexLeverageInverseTypeCode
        \o message.referenceIndexLeverageInverseTypeCode
        \o message.indexAssetClassificationId1
        \o message.indexAssetClassificationId2
        \o message.ipoUnderwriterMemberNumber
        \o message.lpOrder
        \o message.lowLiquidity
        \o message.abnormalRise
        \o message.upperLimitQuantity
        \o message.investmentPrecautionIssue
        \o message.preferredStocksWithLesserShares
        \o message.spacMerger
        \o message.segmentTypeCode
        \o message.afterMarketPossibility
        \o message.choiceOnCompetitiveTrading
        \o message.limitOnCompetitiveTradingVolume
        \o message.occurrenceOfReasonsProhibitingCompetitiveTrading
        \o message.approvalOnCompetitiveTrading
        \o message.approvalOnNegotiationTrading
        \o message.yesterdaysClosingPriceTypeCodeNxt
        \o message.yesterdaysClosingPriceNxt
        \o message.competitionBoardTradePermissionCode
        \o message.negotiationPossibleOrNotBeforeMainMarket
        \o message.endKeyword

DecodeEquitiesBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(abbreviatedIssueCode.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(abbreviatedIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET groupNumber == ReadBytes(abbreviatedIssueNameInEn.rest, 5) IN IF ~groupNumber.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(groupNumber.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET securityGroupId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET unitTrading == ReadBytes(securityGroupId.rest, 1) IN IF ~unitTrading.ok THEN Fail ELSE
    LET rightsTypeCode == ReadBytes(unitTrading.rest, 2) IN IF ~rightsTypeCode.ok THEN Fail ELSE
    LET parValueTypeCode == ReadBytes(rightsTypeCode.rest, 2) IN IF ~parValueTypeCode.ok THEN Fail ELSE
    LET anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice == ReadBytes(parValueTypeCode.rest, 1) IN IF ~anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.ok THEN Fail ELSE
    LET reevaluationReasonCode == ReadBytes(anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.rest, 2) IN IF ~reevaluationReasonCode.ok THEN Fail ELSE
    LET basePriceChange == ReadBytes(reevaluationReasonCode.rest, 1) IN IF ~basePriceChange.ok THEN Fail ELSE
    LET randomEndTriggerCode == ReadBytes(basePriceChange.rest, 1) IN IF ~randomEndTriggerCode.ok THEN Fail ELSE
    LET marketAlert == ReadBytes(randomEndTriggerCode.rest, 1) IN IF ~marketAlert.ok THEN Fail ELSE
    LET marketAlertTypeCode == ReadBytes(marketAlert.rest, 2) IN IF ~marketAlertTypeCode.ok THEN Fail ELSE
    LET koreaCorporateGovernanceStockPriceIndexKogi == ReadBytes(marketAlertTypeCode.rest, 1) IN IF ~koreaCorporateGovernanceStockPriceIndexKogi.ok THEN Fail ELSE
    LET issueForAdministration == ReadBytes(koreaCorporateGovernanceStockPriceIndexKogi.rest, 1) IN IF ~issueForAdministration.ok THEN Fail ELSE
    LET unfaithfulDisclosure == ReadBytes(issueForAdministration.rest, 1) IN IF ~unfaithfulDisclosure.ok THEN Fail ELSE
    LET backDoorListing == ReadBytes(unfaithfulDisclosure.rest, 1) IN IF ~backDoorListing.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(backDoorListing.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET industryId == ReadBytes(tradingHalt.rest, 10) IN IF ~industryId.ok THEN Fail ELSE
    LET smallMediumSizedBusiness == ReadBytes(industryId.rest, 1) IN IF ~smallMediumSizedBusiness.ok THEN Fail ELSE
    LET sectionTypeCode == ReadBytes(smallMediumSizedBusiness.rest, 1) IN IF ~sectionTypeCode.ok THEN Fail ELSE
    LET investmentInstitutionTypeCode == ReadBytes(sectionTypeCode.rest, 1) IN IF ~investmentInstitutionTypeCode.ok THEN Fail ELSE
    LET basePrice == ReadBytes(investmentInstitutionTypeCode.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET yesterdaysClosingPriceTypeCodeKrx == ReadBytes(basePrice.rest, 1) IN IF ~yesterdaysClosingPriceTypeCodeKrx.ok THEN Fail ELSE
    LET yesterdaysClosingPriceKrx == ReadBytes(yesterdaysClosingPriceTypeCodeKrx.rest, 11) IN IF ~yesterdaysClosingPriceKrx.ok THEN Fail ELSE
    LET yesterdaysAccumulatedTradingAmount == ReadBytes(yesterdaysClosingPriceKrx.rest, 12) IN IF ~yesterdaysAccumulatedTradingAmount.ok THEN Fail ELSE
    LET yesterdaysAccumulatedTradingValue == ReadBytes(yesterdaysAccumulatedTradingAmount.rest, 22) IN IF ~yesterdaysAccumulatedTradingValue.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(yesterdaysAccumulatedTradingValue.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET substitutePriceOfSecurities == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~substitutePriceOfSecurities.ok THEN Fail ELSE
    LET parValue == ReadBytes(substitutePriceOfSecurities.rest, 11) IN IF ~parValue.ok THEN Fail ELSE
    LET issuingPrice == ReadBytes(parValue.rest, 11) IN IF ~issuingPrice.ok THEN Fail ELSE
    LET listingDate == ReadBytes(issuingPrice.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET numberOfListedShares == ReadBytes(listingDate.rest, 16) IN IF ~numberOfListedShares.ok THEN Fail ELSE
    LET liquidationTrade == ReadBytes(numberOfListedShares.rest, 1) IN IF ~liquidationTrade.ok THEN Fail ELSE
    LET theEstablishmentDate == ReadBytes(liquidationTrade.rest, 8) IN IF ~theEstablishmentDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(theEstablishmentDate.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET exercisingPeriod == ReadBytes(maturityDate.rest, 8) IN IF ~exercisingPeriod.ok THEN Fail ELSE
    LET expirationDateForRight == ReadBytes(exercisingPeriod.rest, 8) IN IF ~expirationDateForRight.ok THEN Fail ELSE
    LET exercisePriceOfElwOrBw == ReadBytes(expirationDateForRight.rest, 13) IN IF ~exercisePriceOfElwOrBw.ok THEN Fail ELSE
    LET capital == ReadBytes(exercisePriceOfElwOrBw.rest, 22) IN IF ~capital.ok THEN Fail ELSE
    LET creditOrderPossibility == ReadBytes(capital.rest, 1) IN IF ~creditOrderPossibility.ok THEN Fail ELSE
    LET limitOrderPermissionTypeCode == ReadBytes(creditOrderPossibility.rest, 5) IN IF ~limitOrderPermissionTypeCode.ok THEN Fail ELSE
    LET marketPriceOrderPermissionTypeCode == ReadBytes(limitOrderPermissionTypeCode.rest, 5) IN IF ~marketPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET conditionedOrderPermissionTypeCode == ReadBytes(marketPriceOrderPermissionTypeCode.rest, 5) IN IF ~conditionedOrderPermissionTypeCode.ok THEN Fail ELSE
    LET bestFavorableOrderPermissionTypeCode == ReadBytes(conditionedOrderPermissionTypeCode.rest, 5) IN IF ~bestFavorableOrderPermissionTypeCode.ok THEN Fail ELSE
    LET firstBestOrderPermissionType == ReadBytes(bestFavorableOrderPermissionTypeCode.rest, 5) IN IF ~firstBestOrderPermissionType.ok THEN Fail ELSE
    LET midPriceOrderPermissionTypeCode == ReadBytes(firstBestOrderPermissionType.rest, 5) IN IF ~midPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET stopLimitPriceOrderPermissionTypeCode == ReadBytes(midPriceOrderPermissionTypeCode.rest, 5) IN IF ~stopLimitPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET capitalIncreaseTypeCode == ReadBytes(stopLimitPriceOrderPermissionTypeCode.rest, 2) IN IF ~capitalIncreaseTypeCode.ok THEN Fail ELSE
    LET otherStockTypeCode == ReadBytes(capitalIncreaseTypeCode.rest, 1) IN IF ~otherStockTypeCode.ok THEN Fail ELSE
    LET nationalStock == ReadBytes(otherStockTypeCode.rest, 1) IN IF ~nationalStock.ok THEN Fail ELSE
    LET appraisedPrice == ReadBytes(nationalStock.rest, 11) IN IF ~appraisedPrice.ok THEN Fail ELSE
    LET lowestOrderPrice == ReadBytes(appraisedPrice.rest, 11) IN IF ~lowestOrderPrice.ok THEN Fail ELSE
    LET highestOrderPrice == ReadBytes(lowestOrderPrice.rest, 11) IN IF ~highestOrderPrice.ok THEN Fail ELSE
    LET unitOfVolumeInMainBoard == ReadBytes(highestOrderPrice.rest, 11) IN IF ~unitOfVolumeInMainBoard.ok THEN Fail ELSE
    LET lotSizeAfterHoursTrading == ReadBytes(unitOfVolumeInMainBoard.rest, 11) IN IF ~lotSizeAfterHoursTrading.ok THEN Fail ELSE
    LET reiTsTypeCode == ReadBytes(lotSizeAfterHoursTrading.rest, 1) IN IF ~reiTsTypeCode.ok THEN Fail ELSE
    LET targetStockIsinCode == ReadBytes(reiTsTypeCode.rest, 12) IN IF ~targetStockIsinCode.ok THEN Fail ELSE
    LET currencyIsoCode == ReadBytes(targetStockIsinCode.rest, 3) IN IF ~currencyIsoCode.ok THEN Fail ELSE
    LET countryCode == ReadBytes(currencyIsoCode.rest, 3) IN IF ~countryCode.ok THEN Fail ELSE
    LET marketMakingPossibility == ReadBytes(countryCode.rest, 1) IN IF ~marketMakingPossibility.ok THEN Fail ELSE
    LET closingPriceTradingPossibilityInTheAfterHours == ReadBytes(marketMakingPossibility.rest, 1) IN IF ~closingPriceTradingPossibilityInTheAfterHours.ok THEN Fail ELSE
    LET closingPriceTradingInThePreOpeningMarket == ReadBytes(closingPriceTradingPossibilityInTheAfterHours.rest, 1) IN IF ~closingPriceTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET blockTradingInThePreOpeningMarket == ReadBytes(closingPriceTradingInThePreOpeningMarket.rest, 1) IN IF ~blockTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET basketTradingInThePreOpeningMarket == ReadBytes(blockTradingInThePreOpeningMarket.rest, 1) IN IF ~basketTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET announcementOfEstimatedTradingPrice == ReadBytes(basketTradingInThePreOpeningMarket.rest, 1) IN IF ~announcementOfEstimatedTradingPrice.ok THEN Fail ELSE
    LET shortSelling == ReadBytes(announcementOfEstimatedTradingPrice.rest, 1) IN IF ~shortSelling.ok THEN Fail ELSE
    LET etfTrackingDifference == ReadBytes(shortSelling.rest, 13) IN IF ~etfTrackingDifference.ok THEN Fail ELSE
    LET regs == ReadBytes(etfTrackingDifference.rest, 1) IN IF ~regs.ok THEN Fail ELSE
    LET spac == ReadBytes(regs.rest, 1) IN IF ~spac.ok THEN Fail ELSE
    LET taxTypeCode == ReadBytes(spac.rest, 1) IN IF ~taxTypeCode.ok THEN Fail ELSE
    LET appraisalRatioOfSubstitutePrice == ReadBytes(taxTypeCode.rest, 13) IN IF ~appraisalRatioOfSubstitutePrice.ok THEN Fail ELSE
    LET investmentCautionIssue == ReadBytes(appraisalRatioOfSubstitutePrice.rest, 1) IN IF ~investmentCautionIssue.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(investmentCautionIssue.rest, 8) IN IF ~delistingDate.ok THEN Fail ELSE
    LET shortTermOverheatIssueTypeCode == ReadBytes(delistingDate.rest, 1) IN IF ~shortTermOverheatIssueTypeCode.ok THEN Fail ELSE
    LET etfReplicationMethodsTypeCode == ReadBytes(shortTermOverheatIssueTypeCode.rest, 1) IN IF ~etfReplicationMethodsTypeCode.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(etfReplicationMethodsTypeCode.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET distributionTypeCode == ReadBytes(expirationDate.rest, 2) IN IF ~distributionTypeCode.ok THEN Fail ELSE
    LET calculationOfRedemptionPriceStartDate == ReadBytes(distributionTypeCode.rest, 8) IN IF ~calculationOfRedemptionPriceStartDate.ok THEN Fail ELSE
    LET calculationOfRedemptionPriceEndDate == ReadBytes(calculationOfRedemptionPriceStartDate.rest, 8) IN IF ~calculationOfRedemptionPriceEndDate.ok THEN Fail ELSE
    LET etpProductTypeCode == ReadBytes(calculationOfRedemptionPriceEndDate.rest, 1) IN IF ~etpProductTypeCode.ok THEN Fail ELSE
    LET indexCalculationInstitutionTypeCode == ReadBytes(etpProductTypeCode.rest, 2) IN IF ~indexCalculationInstitutionTypeCode.ok THEN Fail ELSE
    LET indexMarketClassificationId == ReadBytes(indexCalculationInstitutionTypeCode.rest, 6) IN IF ~indexMarketClassificationId.ok THEN Fail ELSE
    LET indexSequenceNumber == ReadBytes(indexMarketClassificationId.rest, 3) IN IF ~indexSequenceNumber.ok THEN Fail ELSE
    LET trackingIndexLeverageInverseTypeCode == ReadBytes(indexSequenceNumber.rest, 2) IN IF ~trackingIndexLeverageInverseTypeCode.ok THEN Fail ELSE
    LET referenceIndexLeverageInverseTypeCode == ReadBytes(trackingIndexLeverageInverseTypeCode.rest, 2) IN IF ~referenceIndexLeverageInverseTypeCode.ok THEN Fail ELSE
    LET indexAssetClassificationId1 == ReadBytes(referenceIndexLeverageInverseTypeCode.rest, 6) IN IF ~indexAssetClassificationId1.ok THEN Fail ELSE
    LET indexAssetClassificationId2 == ReadBytes(indexAssetClassificationId1.rest, 6) IN IF ~indexAssetClassificationId2.ok THEN Fail ELSE
    LET ipoUnderwriterMemberNumber == ReadBytes(indexAssetClassificationId2.rest, 5) IN IF ~ipoUnderwriterMemberNumber.ok THEN Fail ELSE
    LET lpOrder == ReadBytes(ipoUnderwriterMemberNumber.rest, 1) IN IF ~lpOrder.ok THEN Fail ELSE
    LET lowLiquidity == ReadBytes(lpOrder.rest, 1) IN IF ~lowLiquidity.ok THEN Fail ELSE
    LET abnormalRise == ReadBytes(lowLiquidity.rest, 1) IN IF ~abnormalRise.ok THEN Fail ELSE
    LET upperLimitQuantity == ReadBytes(abnormalRise.rest, 23) IN IF ~upperLimitQuantity.ok THEN Fail ELSE
    LET investmentPrecautionIssue == ReadBytes(upperLimitQuantity.rest, 1) IN IF ~investmentPrecautionIssue.ok THEN Fail ELSE
    LET preferredStocksWithLesserShares == ReadBytes(investmentPrecautionIssue.rest, 1) IN IF ~preferredStocksWithLesserShares.ok THEN Fail ELSE
    LET spacMerger == ReadBytes(preferredStocksWithLesserShares.rest, 1) IN IF ~spacMerger.ok THEN Fail ELSE
    LET segmentTypeCode == ReadBytes(spacMerger.rest, 1) IN IF ~segmentTypeCode.ok THEN Fail ELSE
    LET afterMarketPossibility == ReadBytes(segmentTypeCode.rest, 1) IN IF ~afterMarketPossibility.ok THEN Fail ELSE
    LET choiceOnCompetitiveTrading == ReadBytes(afterMarketPossibility.rest, 1) IN IF ~choiceOnCompetitiveTrading.ok THEN Fail ELSE
    LET limitOnCompetitiveTradingVolume == ReadBytes(choiceOnCompetitiveTrading.rest, 1) IN IF ~limitOnCompetitiveTradingVolume.ok THEN Fail ELSE
    LET occurrenceOfReasonsProhibitingCompetitiveTrading == ReadBytes(limitOnCompetitiveTradingVolume.rest, 1) IN IF ~occurrenceOfReasonsProhibitingCompetitiveTrading.ok THEN Fail ELSE
    LET approvalOnCompetitiveTrading == ReadBytes(occurrenceOfReasonsProhibitingCompetitiveTrading.rest, 1) IN IF ~approvalOnCompetitiveTrading.ok THEN Fail ELSE
    LET approvalOnNegotiationTrading == ReadBytes(approvalOnCompetitiveTrading.rest, 1) IN IF ~approvalOnNegotiationTrading.ok THEN Fail ELSE
    LET yesterdaysClosingPriceTypeCodeNxt == ReadBytes(approvalOnNegotiationTrading.rest, 1) IN IF ~yesterdaysClosingPriceTypeCodeNxt.ok THEN Fail ELSE
    LET yesterdaysClosingPriceNxt == ReadBytes(yesterdaysClosingPriceTypeCodeNxt.rest, 11) IN IF ~yesterdaysClosingPriceNxt.ok THEN Fail ELSE
    LET competitionBoardTradePermissionCode == ReadBytes(yesterdaysClosingPriceNxt.rest, 5) IN IF ~competitionBoardTradePermissionCode.ok THEN Fail ELSE
    LET negotiationPossibleOrNotBeforeMainMarket == ReadBytes(competitionBoardTradePermissionCode.rest, 1) IN IF ~negotiationPossibleOrNotBeforeMainMarket.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(negotiationPossibleOrNotBeforeMainMarket.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                  |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract                  |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                                           |-> businessDate.value,
         isinCode                                               |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx                     |-> aDesignatedNumberForAnIssueFromKrx.value,
         abbreviatedIssueCode                                   |-> abbreviatedIssueCode.value,
         abbreviatedIssueName                                   |-> abbreviatedIssueName.value,
         abbreviatedIssueNameInEn                               |-> abbreviatedIssueNameInEn.value,
         groupNumber                                            |-> groupNumber.value,
         marketOperationProductId                               |-> marketOperationProductId.value,
         securityGroupId                                        |-> securityGroupId.value,
         unitTrading                                            |-> unitTrading.value,
         rightsTypeCode                                         |-> rightsTypeCode.value,
         parValueTypeCode                                       |-> parValueTypeCode.value,
         anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.value,
         reevaluationReasonCode                                 |-> reevaluationReasonCode.value,
         basePriceChange                                        |-> basePriceChange.value,
         randomEndTriggerCode                                   |-> randomEndTriggerCode.value,
         marketAlert                                            |-> marketAlert.value,
         marketAlertTypeCode                                    |-> marketAlertTypeCode.value,
         koreaCorporateGovernanceStockPriceIndexKogi            |-> koreaCorporateGovernanceStockPriceIndexKogi.value,
         issueForAdministration                                 |-> issueForAdministration.value,
         unfaithfulDisclosure                                   |-> unfaithfulDisclosure.value,
         backDoorListing                                        |-> backDoorListing.value,
         tradingHalt                                            |-> tradingHalt.value,
         industryId                                             |-> industryId.value,
         smallMediumSizedBusiness                               |-> smallMediumSizedBusiness.value,
         sectionTypeCode                                        |-> sectionTypeCode.value,
         investmentInstitutionTypeCode                          |-> investmentInstitutionTypeCode.value,
         basePrice                                              |-> basePrice.value,
         yesterdaysClosingPriceTypeCodeKrx                      |-> yesterdaysClosingPriceTypeCodeKrx.value,
         yesterdaysClosingPriceKrx                              |-> yesterdaysClosingPriceKrx.value,
         yesterdaysAccumulatedTradingAmount                     |-> yesterdaysAccumulatedTradingAmount.value,
         yesterdaysAccumulatedTradingValue                      |-> yesterdaysAccumulatedTradingValue.value,
         upperLimitPrice                                        |-> upperLimitPrice.value,
         lowerLimitPrice                                        |-> lowerLimitPrice.value,
         substitutePriceOfSecurities                            |-> substitutePriceOfSecurities.value,
         parValue                                               |-> parValue.value,
         issuingPrice                                           |-> issuingPrice.value,
         listingDate                                            |-> listingDate.value,
         numberOfListedShares                                   |-> numberOfListedShares.value,
         liquidationTrade                                       |-> liquidationTrade.value,
         theEstablishmentDate                                   |-> theEstablishmentDate.value,
         maturityDate                                           |-> maturityDate.value,
         exercisingPeriod                                       |-> exercisingPeriod.value,
         expirationDateForRight                                 |-> expirationDateForRight.value,
         exercisePriceOfElwOrBw                                 |-> exercisePriceOfElwOrBw.value,
         capital                                                |-> capital.value,
         creditOrderPossibility                                 |-> creditOrderPossibility.value,
         limitOrderPermissionTypeCode                           |-> limitOrderPermissionTypeCode.value,
         marketPriceOrderPermissionTypeCode                     |-> marketPriceOrderPermissionTypeCode.value,
         conditionedOrderPermissionTypeCode                     |-> conditionedOrderPermissionTypeCode.value,
         bestFavorableOrderPermissionTypeCode                   |-> bestFavorableOrderPermissionTypeCode.value,
         firstBestOrderPermissionType                           |-> firstBestOrderPermissionType.value,
         midPriceOrderPermissionTypeCode                        |-> midPriceOrderPermissionTypeCode.value,
         stopLimitPriceOrderPermissionTypeCode                  |-> stopLimitPriceOrderPermissionTypeCode.value,
         capitalIncreaseTypeCode                                |-> capitalIncreaseTypeCode.value,
         otherStockTypeCode                                     |-> otherStockTypeCode.value,
         nationalStock                                          |-> nationalStock.value,
         appraisedPrice                                         |-> appraisedPrice.value,
         lowestOrderPrice                                       |-> lowestOrderPrice.value,
         highestOrderPrice                                      |-> highestOrderPrice.value,
         unitOfVolumeInMainBoard                                |-> unitOfVolumeInMainBoard.value,
         lotSizeAfterHoursTrading                               |-> lotSizeAfterHoursTrading.value,
         reiTsTypeCode                                          |-> reiTsTypeCode.value,
         targetStockIsinCode                                    |-> targetStockIsinCode.value,
         currencyIsoCode                                        |-> currencyIsoCode.value,
         countryCode                                            |-> countryCode.value,
         marketMakingPossibility                                |-> marketMakingPossibility.value,
         closingPriceTradingPossibilityInTheAfterHours          |-> closingPriceTradingPossibilityInTheAfterHours.value,
         closingPriceTradingInThePreOpeningMarket               |-> closingPriceTradingInThePreOpeningMarket.value,
         blockTradingInThePreOpeningMarket                      |-> blockTradingInThePreOpeningMarket.value,
         basketTradingInThePreOpeningMarket                     |-> basketTradingInThePreOpeningMarket.value,
         announcementOfEstimatedTradingPrice                    |-> announcementOfEstimatedTradingPrice.value,
         shortSelling                                           |-> shortSelling.value,
         etfTrackingDifference                                  |-> etfTrackingDifference.value,
         regs                                                   |-> regs.value,
         spac                                                   |-> spac.value,
         taxTypeCode                                            |-> taxTypeCode.value,
         appraisalRatioOfSubstitutePrice                        |-> appraisalRatioOfSubstitutePrice.value,
         investmentCautionIssue                                 |-> investmentCautionIssue.value,
         delistingDate                                          |-> delistingDate.value,
         shortTermOverheatIssueTypeCode                         |-> shortTermOverheatIssueTypeCode.value,
         etfReplicationMethodsTypeCode                          |-> etfReplicationMethodsTypeCode.value,
         expirationDate                                         |-> expirationDate.value,
         distributionTypeCode                                   |-> distributionTypeCode.value,
         calculationOfRedemptionPriceStartDate                  |-> calculationOfRedemptionPriceStartDate.value,
         calculationOfRedemptionPriceEndDate                    |-> calculationOfRedemptionPriceEndDate.value,
         etpProductTypeCode                                     |-> etpProductTypeCode.value,
         indexCalculationInstitutionTypeCode                    |-> indexCalculationInstitutionTypeCode.value,
         indexMarketClassificationId                            |-> indexMarketClassificationId.value,
         indexSequenceNumber                                    |-> indexSequenceNumber.value,
         trackingIndexLeverageInverseTypeCode                   |-> trackingIndexLeverageInverseTypeCode.value,
         referenceIndexLeverageInverseTypeCode                  |-> referenceIndexLeverageInverseTypeCode.value,
         indexAssetClassificationId1                            |-> indexAssetClassificationId1.value,
         indexAssetClassificationId2                            |-> indexAssetClassificationId2.value,
         ipoUnderwriterMemberNumber                             |-> ipoUnderwriterMemberNumber.value,
         lpOrder                                                |-> lpOrder.value,
         lowLiquidity                                           |-> lowLiquidity.value,
         abnormalRise                                           |-> abnormalRise.value,
         upperLimitQuantity                                     |-> upperLimitQuantity.value,
         investmentPrecautionIssue                              |-> investmentPrecautionIssue.value,
         preferredStocksWithLesserShares                        |-> preferredStocksWithLesserShares.value,
         spacMerger                                             |-> spacMerger.value,
         segmentTypeCode                                        |-> segmentTypeCode.value,
         afterMarketPossibility                                 |-> afterMarketPossibility.value,
         choiceOnCompetitiveTrading                             |-> choiceOnCompetitiveTrading.value,
         limitOnCompetitiveTradingVolume                        |-> limitOnCompetitiveTradingVolume.value,
         occurrenceOfReasonsProhibitingCompetitiveTrading       |-> occurrenceOfReasonsProhibitingCompetitiveTrading.value,
         approvalOnCompetitiveTrading                           |-> approvalOnCompetitiveTrading.value,
         approvalOnNegotiationTrading                           |-> approvalOnNegotiationTrading.value,
         yesterdaysClosingPriceTypeCodeNxt                      |-> yesterdaysClosingPriceTypeCodeNxt.value,
         yesterdaysClosingPriceNxt                              |-> yesterdaysClosingPriceNxt.value,
         competitionBoardTradePermissionCode                    |-> competitionBoardTradePermissionCode.value,
         negotiationPossibleOrNotBeforeMainMarket               |-> negotiationPossibleOrNotBeforeMainMarket.value,
         endKeyword                                             |-> endKeyword.value ], endKeyword.rest)

ZeroEquitiesBatchDataMessage ==
    [ messageSequenceNumber                                  |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract                  |-> [i \in 1 .. 6 |-> 0],
      businessDate                                           |-> [i \in 1 .. 8 |-> 0],
      isinCode                                               |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx                     |-> [i \in 1 .. 6 |-> 0],
      abbreviatedIssueCode                                   |-> [i \in 1 .. 9 |-> 0],
      abbreviatedIssueName                                   |-> [i \in 1 .. 40 |-> 0],
      abbreviatedIssueNameInEn                               |-> [i \in 1 .. 40 |-> 0],
      groupNumber                                            |-> [i \in 1 .. 5 |-> 0],
      marketOperationProductId                               |-> [i \in 1 .. 3 |-> 0],
      securityGroupId                                        |-> [i \in 1 .. 2 |-> 0],
      unitTrading                                            |-> [i \in 1 .. 1 |-> 0],
      rightsTypeCode                                         |-> [i \in 1 .. 2 |-> 0],
      parValueTypeCode                                       |-> [i \in 1 .. 2 |-> 0],
      anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> [i \in 1 .. 1 |-> 0],
      reevaluationReasonCode                                 |-> [i \in 1 .. 2 |-> 0],
      basePriceChange                                        |-> [i \in 1 .. 1 |-> 0],
      randomEndTriggerCode                                   |-> [i \in 1 .. 1 |-> 0],
      marketAlert                                            |-> [i \in 1 .. 1 |-> 0],
      marketAlertTypeCode                                    |-> [i \in 1 .. 2 |-> 0],
      koreaCorporateGovernanceStockPriceIndexKogi            |-> [i \in 1 .. 1 |-> 0],
      issueForAdministration                                 |-> [i \in 1 .. 1 |-> 0],
      unfaithfulDisclosure                                   |-> [i \in 1 .. 1 |-> 0],
      backDoorListing                                        |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                                            |-> [i \in 1 .. 1 |-> 0],
      industryId                                             |-> [i \in 1 .. 10 |-> 0],
      smallMediumSizedBusiness                               |-> [i \in 1 .. 1 |-> 0],
      sectionTypeCode                                        |-> [i \in 1 .. 1 |-> 0],
      investmentInstitutionTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      basePrice                                              |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPriceTypeCodeKrx                      |-> [i \in 1 .. 1 |-> 0],
      yesterdaysClosingPriceKrx                              |-> [i \in 1 .. 11 |-> 0],
      yesterdaysAccumulatedTradingAmount                     |-> [i \in 1 .. 12 |-> 0],
      yesterdaysAccumulatedTradingValue                      |-> [i \in 1 .. 22 |-> 0],
      upperLimitPrice                                        |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                                        |-> [i \in 1 .. 11 |-> 0],
      substitutePriceOfSecurities                            |-> [i \in 1 .. 11 |-> 0],
      parValue                                               |-> [i \in 1 .. 11 |-> 0],
      issuingPrice                                           |-> [i \in 1 .. 11 |-> 0],
      listingDate                                            |-> [i \in 1 .. 8 |-> 0],
      numberOfListedShares                                   |-> [i \in 1 .. 16 |-> 0],
      liquidationTrade                                       |-> [i \in 1 .. 1 |-> 0],
      theEstablishmentDate                                   |-> [i \in 1 .. 8 |-> 0],
      maturityDate                                           |-> [i \in 1 .. 8 |-> 0],
      exercisingPeriod                                       |-> [i \in 1 .. 8 |-> 0],
      expirationDateForRight                                 |-> [i \in 1 .. 8 |-> 0],
      exercisePriceOfElwOrBw                                 |-> [i \in 1 .. 13 |-> 0],
      capital                                                |-> [i \in 1 .. 22 |-> 0],
      creditOrderPossibility                                 |-> [i \in 1 .. 1 |-> 0],
      limitOrderPermissionTypeCode                           |-> [i \in 1 .. 5 |-> 0],
      marketPriceOrderPermissionTypeCode                     |-> [i \in 1 .. 5 |-> 0],
      conditionedOrderPermissionTypeCode                     |-> [i \in 1 .. 5 |-> 0],
      bestFavorableOrderPermissionTypeCode                   |-> [i \in 1 .. 5 |-> 0],
      firstBestOrderPermissionType                           |-> [i \in 1 .. 5 |-> 0],
      midPriceOrderPermissionTypeCode                        |-> [i \in 1 .. 5 |-> 0],
      stopLimitPriceOrderPermissionTypeCode                  |-> [i \in 1 .. 5 |-> 0],
      capitalIncreaseTypeCode                                |-> [i \in 1 .. 2 |-> 0],
      otherStockTypeCode                                     |-> [i \in 1 .. 1 |-> 0],
      nationalStock                                          |-> [i \in 1 .. 1 |-> 0],
      appraisedPrice                                         |-> [i \in 1 .. 11 |-> 0],
      lowestOrderPrice                                       |-> [i \in 1 .. 11 |-> 0],
      highestOrderPrice                                      |-> [i \in 1 .. 11 |-> 0],
      unitOfVolumeInMainBoard                                |-> [i \in 1 .. 11 |-> 0],
      lotSizeAfterHoursTrading                               |-> [i \in 1 .. 11 |-> 0],
      reiTsTypeCode                                          |-> [i \in 1 .. 1 |-> 0],
      targetStockIsinCode                                    |-> [i \in 1 .. 12 |-> 0],
      currencyIsoCode                                        |-> [i \in 1 .. 3 |-> 0],
      countryCode                                            |-> [i \in 1 .. 3 |-> 0],
      marketMakingPossibility                                |-> [i \in 1 .. 1 |-> 0],
      closingPriceTradingPossibilityInTheAfterHours          |-> [i \in 1 .. 1 |-> 0],
      closingPriceTradingInThePreOpeningMarket               |-> [i \in 1 .. 1 |-> 0],
      blockTradingInThePreOpeningMarket                      |-> [i \in 1 .. 1 |-> 0],
      basketTradingInThePreOpeningMarket                     |-> [i \in 1 .. 1 |-> 0],
      announcementOfEstimatedTradingPrice                    |-> [i \in 1 .. 1 |-> 0],
      shortSelling                                           |-> [i \in 1 .. 1 |-> 0],
      etfTrackingDifference                                  |-> [i \in 1 .. 13 |-> 0],
      regs                                                   |-> [i \in 1 .. 1 |-> 0],
      spac                                                   |-> [i \in 1 .. 1 |-> 0],
      taxTypeCode                                            |-> [i \in 1 .. 1 |-> 0],
      appraisalRatioOfSubstitutePrice                        |-> [i \in 1 .. 13 |-> 0],
      investmentCautionIssue                                 |-> [i \in 1 .. 1 |-> 0],
      delistingDate                                          |-> [i \in 1 .. 8 |-> 0],
      shortTermOverheatIssueTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      etfReplicationMethodsTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      expirationDate                                         |-> [i \in 1 .. 8 |-> 0],
      distributionTypeCode                                   |-> [i \in 1 .. 2 |-> 0],
      calculationOfRedemptionPriceStartDate                  |-> [i \in 1 .. 8 |-> 0],
      calculationOfRedemptionPriceEndDate                    |-> [i \in 1 .. 8 |-> 0],
      etpProductTypeCode                                     |-> [i \in 1 .. 1 |-> 0],
      indexCalculationInstitutionTypeCode                    |-> [i \in 1 .. 2 |-> 0],
      indexMarketClassificationId                            |-> [i \in 1 .. 6 |-> 0],
      indexSequenceNumber                                    |-> [i \in 1 .. 3 |-> 0],
      trackingIndexLeverageInverseTypeCode                   |-> [i \in 1 .. 2 |-> 0],
      referenceIndexLeverageInverseTypeCode                  |-> [i \in 1 .. 2 |-> 0],
      indexAssetClassificationId1                            |-> [i \in 1 .. 6 |-> 0],
      indexAssetClassificationId2                            |-> [i \in 1 .. 6 |-> 0],
      ipoUnderwriterMemberNumber                             |-> [i \in 1 .. 5 |-> 0],
      lpOrder                                                |-> [i \in 1 .. 1 |-> 0],
      lowLiquidity                                           |-> [i \in 1 .. 1 |-> 0],
      abnormalRise                                           |-> [i \in 1 .. 1 |-> 0],
      upperLimitQuantity                                     |-> [i \in 1 .. 23 |-> 0],
      investmentPrecautionIssue                              |-> [i \in 1 .. 1 |-> 0],
      preferredStocksWithLesserShares                        |-> [i \in 1 .. 1 |-> 0],
      spacMerger                                             |-> [i \in 1 .. 1 |-> 0],
      segmentTypeCode                                        |-> [i \in 1 .. 1 |-> 0],
      afterMarketPossibility                                 |-> [i \in 1 .. 1 |-> 0],
      choiceOnCompetitiveTrading                             |-> [i \in 1 .. 1 |-> 0],
      limitOnCompetitiveTradingVolume                        |-> [i \in 1 .. 1 |-> 0],
      occurrenceOfReasonsProhibitingCompetitiveTrading       |-> [i \in 1 .. 1 |-> 0],
      approvalOnCompetitiveTrading                           |-> [i \in 1 .. 1 |-> 0],
      approvalOnNegotiationTrading                           |-> [i \in 1 .. 1 |-> 0],
      yesterdaysClosingPriceTypeCodeNxt                      |-> [i \in 1 .. 1 |-> 0],
      yesterdaysClosingPriceNxt                              |-> [i \in 1 .. 11 |-> 0],
      competitionBoardTradePermissionCode                    |-> [i \in 1 .. 5 |-> 0],
      negotiationPossibleOrNotBeforeMainMarket               |-> [i \in 1 .. 1 |-> 0],
      endKeyword                                             |-> [i \in 1 .. 1 |-> 0] ]

(* Equities Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedEquitiesBatchDataMessage ==
    { ZeroEquitiesBatchDataMessage }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.groupNumber = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.securityGroupId = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.unitTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.rightsTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.parValueTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.reevaluationReasonCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.basePriceChange = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.randomEndTriggerCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.marketAlert = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.marketAlertTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.koreaCorporateGovernanceStockPriceIndexKogi = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.issueForAdministration = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.unfaithfulDisclosure = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.backDoorListing = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.industryId = one] : one \in Sample(10) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.smallMediumSizedBusiness = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.sectionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.investmentInstitutionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.yesterdaysClosingPriceTypeCodeKrx = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.yesterdaysClosingPriceKrx = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.yesterdaysAccumulatedTradingAmount = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.yesterdaysAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.substitutePriceOfSecurities = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.parValue = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.issuingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.numberOfListedShares = one] : one \in Sample(16) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.liquidationTrade = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.theEstablishmentDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.exercisingPeriod = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.expirationDateForRight = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.exercisePriceOfElwOrBw = one] : one \in Sample(13) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.capital = one] : one \in Sample(22) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.creditOrderPossibility = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.limitOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.marketPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.conditionedOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.bestFavorableOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.firstBestOrderPermissionType = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.midPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.stopLimitPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.capitalIncreaseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.otherStockTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.nationalStock = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.appraisedPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.lowestOrderPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.highestOrderPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.unitOfVolumeInMainBoard = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.lotSizeAfterHoursTrading = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.reiTsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.targetStockIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.currencyIsoCode = one] : one \in Sample(3) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.countryCode = one] : one \in Sample(3) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.marketMakingPossibility = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.closingPriceTradingPossibilityInTheAfterHours = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.closingPriceTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.blockTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.basketTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.announcementOfEstimatedTradingPrice = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.shortSelling = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.etfTrackingDifference = one] : one \in Sample(13) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.regs = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.spac = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.taxTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.appraisalRatioOfSubstitutePrice = one] : one \in Sample(13) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.investmentCautionIssue = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.delistingDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.shortTermOverheatIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.etfReplicationMethodsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.distributionTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.calculationOfRedemptionPriceStartDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.calculationOfRedemptionPriceEndDate = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.etpProductTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.indexCalculationInstitutionTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.indexMarketClassificationId = one] : one \in Sample(6) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.indexSequenceNumber = one] : one \in Sample(3) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.trackingIndexLeverageInverseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.referenceIndexLeverageInverseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.indexAssetClassificationId1 = one] : one \in Sample(6) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.indexAssetClassificationId2 = one] : one \in Sample(6) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.ipoUnderwriterMemberNumber = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.lpOrder = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.lowLiquidity = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.abnormalRise = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.upperLimitQuantity = one] : one \in Sample(23) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.investmentPrecautionIssue = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.preferredStocksWithLesserShares = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.spacMerger = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.segmentTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.afterMarketPossibility = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.choiceOnCompetitiveTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.limitOnCompetitiveTradingVolume = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.occurrenceOfReasonsProhibitingCompetitiveTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.approvalOnCompetitiveTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.approvalOnNegotiationTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.yesterdaysClosingPriceTypeCodeNxt = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.yesterdaysClosingPriceNxt = one] : one \in Sample(11) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.competitionBoardTradePermissionCode = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.negotiationPossibleOrNotBeforeMainMarket = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Member Information Message: 202 bytes                                   *)
(***************************************************************************)

MemberInformationMessage ==
    [ messageSequenceNumber                     : Sample(8),
      businessDate                              : Sample(8),
      marketParticipantNumber                   : Sample(5),
      nameOfAMarketParticipantInKr              : Sample(80),
      nameOfAMarketParticipantInEn              : Sample(80),
      anAbbreviatedNameOfAMarketParticipantInKr : Sample(20),
      endKeyword                                : Sample(1) ]

EncodeMemberInformationMessage(message) ==
    message.messageSequenceNumber
        \o message.businessDate
        \o message.marketParticipantNumber
        \o message.nameOfAMarketParticipantInKr
        \o message.nameOfAMarketParticipantInEn
        \o message.anAbbreviatedNameOfAMarketParticipantInKr
        \o message.endKeyword

DecodeMemberInformationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET businessDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET marketParticipantNumber == ReadBytes(businessDate.rest, 5) IN IF ~marketParticipantNumber.ok THEN Fail ELSE
    LET nameOfAMarketParticipantInKr == ReadBytes(marketParticipantNumber.rest, 80) IN IF ~nameOfAMarketParticipantInKr.ok THEN Fail ELSE
    LET nameOfAMarketParticipantInEn == ReadBytes(nameOfAMarketParticipantInKr.rest, 80) IN IF ~nameOfAMarketParticipantInEn.ok THEN Fail ELSE
    LET anAbbreviatedNameOfAMarketParticipantInKr == ReadBytes(nameOfAMarketParticipantInEn.rest, 20) IN IF ~anAbbreviatedNameOfAMarketParticipantInKr.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(anAbbreviatedNameOfAMarketParticipantInKr.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                     |-> messageSequenceNumber.value,
         businessDate                              |-> businessDate.value,
         marketParticipantNumber                   |-> marketParticipantNumber.value,
         nameOfAMarketParticipantInKr              |-> nameOfAMarketParticipantInKr.value,
         nameOfAMarketParticipantInEn              |-> nameOfAMarketParticipantInEn.value,
         anAbbreviatedNameOfAMarketParticipantInKr |-> anAbbreviatedNameOfAMarketParticipantInKr.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroMemberInformationMessage ==
    [ messageSequenceNumber                     |-> [i \in 1 .. 8 |-> 0],
      businessDate                              |-> [i \in 1 .. 8 |-> 0],
      marketParticipantNumber                   |-> [i \in 1 .. 5 |-> 0],
      nameOfAMarketParticipantInKr              |-> [i \in 1 .. 80 |-> 0],
      nameOfAMarketParticipantInEn              |-> [i \in 1 .. 80 |-> 0],
      anAbbreviatedNameOfAMarketParticipantInKr |-> [i \in 1 .. 20 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* Member Information Message at zero, then each field in turn at the values it is checked at *)
CheckedMemberInformationMessage ==
    { ZeroMemberInformationMessage }
        \cup { [ZeroMemberInformationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMemberInformationMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroMemberInformationMessage EXCEPT !.marketParticipantNumber = one] : one \in Sample(5) }
        \cup { [ZeroMemberInformationMessage EXCEPT !.nameOfAMarketParticipantInKr = one] : one \in Sample(80) }
        \cup { [ZeroMemberInformationMessage EXCEPT !.nameOfAMarketParticipantInEn = one] : one \in Sample(80) }
        \cup { [ZeroMemberInformationMessage EXCEPT !.anAbbreviatedNameOfAMarketParticipantInKr = one] : one \in Sample(20) }
        \cup { [ZeroMemberInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Event Message: 43 bytes                                           *)
(***************************************************************************)

IssueEventMessage ==
    [ messageSequenceNumber : Sample(8),
      isinCode              : Sample(12),
      eventTypeCode         : Sample(2),
      eventReasonCode       : Sample(4),
      eventStartDate        : Sample(8),
      eventEndDate          : Sample(8),
      endKeyword            : Sample(1) ]

EncodeIssueEventMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.eventTypeCode
        \o message.eventReasonCode
        \o message.eventStartDate
        \o message.eventEndDate
        \o message.endKeyword

DecodeIssueEventMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET eventTypeCode == ReadBytes(isinCode.rest, 2) IN IF ~eventTypeCode.ok THEN Fail ELSE
    LET eventReasonCode == ReadBytes(eventTypeCode.rest, 4) IN IF ~eventReasonCode.ok THEN Fail ELSE
    LET eventStartDate == ReadBytes(eventReasonCode.rest, 8) IN IF ~eventStartDate.ok THEN Fail ELSE
    LET eventEndDate == ReadBytes(eventStartDate.rest, 8) IN IF ~eventEndDate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(eventEndDate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber |-> messageSequenceNumber.value,
         isinCode              |-> isinCode.value,
         eventTypeCode         |-> eventTypeCode.value,
         eventReasonCode       |-> eventReasonCode.value,
         eventStartDate        |-> eventStartDate.value,
         eventEndDate          |-> eventEndDate.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroIssueEventMessage ==
    [ messageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      isinCode              |-> [i \in 1 .. 12 |-> 0],
      eventTypeCode         |-> [i \in 1 .. 2 |-> 0],
      eventReasonCode       |-> [i \in 1 .. 4 |-> 0],
      eventStartDate        |-> [i \in 1 .. 8 |-> 0],
      eventEndDate          |-> [i \in 1 .. 8 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Event Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueEventMessage ==
    { ZeroIssueEventMessage }
        \cup { [ZeroIssueEventMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroIssueEventMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventReasonCode = one] : one \in Sample(4) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventStartDate = one] : one \in Sample(8) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventEndDate = one] : one \in Sample(8) }
        \cup { [ZeroIssueEventMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Block Basket Trade Data Message: 55 bytes                               *)
(***************************************************************************)

BlockBasketTradeDataMessage ==
    [ boardId                            : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      accumulatedTradingVolume           : Sample(12),
      accumulatedTradingValue            : Sample(22),
      endKeyword                         : Sample(1) ]

EncodeBlockBasketTradeDataMessage(message) ==
    message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.endKeyword

DecodeBlockBasketTradeDataMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                            |-> boardId.value,
         isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         accumulatedTradingVolume           |-> accumulatedTradingVolume.value,
         accumulatedTradingValue            |-> accumulatedTradingValue.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroBlockBasketTradeDataMessage ==
    [ boardId                            |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      accumulatedTradingVolume           |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue            |-> [i \in 1 .. 22 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Block Basket Trade Data Message at zero, then each field in turn at the values it is checked at *)
CheckedBlockBasketTradeDataMessage ==
    { ZeroBlockBasketTradeDataMessage }
        \cup { [ZeroBlockBasketTradeDataMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroBlockBasketTradeDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBlockBasketTradeDataMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroBlockBasketTradeDataMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroBlockBasketTradeDataMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroBlockBasketTradeDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Activities Per An Issue Eod Message: 91 bytes                  *)
(***************************************************************************)

InvestorActivitiesPerAnIssueEodMessage ==
    [ isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(6),
      investorCode                       : Sample(4),
      accumulatedAskTradingVolume        : Sample(12),
      accumulatedAskTradingValue         : Sample(22),
      accumulatedBidTradingVolume        : Sample(12),
      accumulatedBidTradingValue         : Sample(22),
      endKeyword                         : Sample(1) ]

EncodeInvestorActivitiesPerAnIssueEodMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.investorCode
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.endKeyword

DecodeInvestorActivitiesPerAnIssueEodMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET investorCode == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(investorCode.rest, 12) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 12) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedBidTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         investorCode                       |-> investorCode.value,
         accumulatedAskTradingVolume        |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue         |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume        |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue         |-> accumulatedBidTradingValue.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroInvestorActivitiesPerAnIssueEodMessage ==
    [ isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 6 |-> 0],
      investorCode                       |-> [i \in 1 .. 4 |-> 0],
      accumulatedAskTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingValue         |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      accumulatedBidTradingValue         |-> [i \in 1 .. 22 |-> 0],
      endKeyword                         |-> [i \in 1 .. 1 |-> 0] ]

(* Investor Activities Per An Issue Eod Message at zero, then each field in turn at the values it is checked at *)
CheckedInvestorActivitiesPerAnIssueEodMessage ==
    { ZeroInvestorActivitiesPerAnIssueEodMessage }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(6) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroInvestorActivitiesPerAnIssueEodMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Short Selling Message: 115 bytes                                        *)
(***************************************************************************)

ShortSellingMessage ==
    [ isinCode                                            : Sample(12),
      coveredShortSellingTradingVolume                    : Sample(12),
      coveredShortSellingTradingValue                     : Sample(22),
      uptickRuleAppliedCoveredShortSellingTradingVolume   : Sample(12),
      uptickRuleAppliedCoveredShortSellingTradingValue    : Sample(22),
      uptickRuleUnappliedCoveredShortSellingTradingVolume : Sample(12),
      uptickRuleUnappliedCoveredShortSellingTradingValue  : Sample(22),
      endKeyword                                          : Sample(1) ]

EncodeShortSellingMessage(message) ==
    message.isinCode
        \o message.coveredShortSellingTradingVolume
        \o message.coveredShortSellingTradingValue
        \o message.uptickRuleAppliedCoveredShortSellingTradingVolume
        \o message.uptickRuleAppliedCoveredShortSellingTradingValue
        \o message.uptickRuleUnappliedCoveredShortSellingTradingVolume
        \o message.uptickRuleUnappliedCoveredShortSellingTradingValue
        \o message.endKeyword

DecodeShortSellingMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET coveredShortSellingTradingVolume == ReadBytes(isinCode.rest, 12) IN IF ~coveredShortSellingTradingVolume.ok THEN Fail ELSE
    LET coveredShortSellingTradingValue == ReadBytes(coveredShortSellingTradingVolume.rest, 22) IN IF ~coveredShortSellingTradingValue.ok THEN Fail ELSE
    LET uptickRuleAppliedCoveredShortSellingTradingVolume == ReadBytes(coveredShortSellingTradingValue.rest, 12) IN IF ~uptickRuleAppliedCoveredShortSellingTradingVolume.ok THEN Fail ELSE
    LET uptickRuleAppliedCoveredShortSellingTradingValue == ReadBytes(uptickRuleAppliedCoveredShortSellingTradingVolume.rest, 22) IN IF ~uptickRuleAppliedCoveredShortSellingTradingValue.ok THEN Fail ELSE
    LET uptickRuleUnappliedCoveredShortSellingTradingVolume == ReadBytes(uptickRuleAppliedCoveredShortSellingTradingValue.rest, 12) IN IF ~uptickRuleUnappliedCoveredShortSellingTradingVolume.ok THEN Fail ELSE
    LET uptickRuleUnappliedCoveredShortSellingTradingValue == ReadBytes(uptickRuleUnappliedCoveredShortSellingTradingVolume.rest, 22) IN IF ~uptickRuleUnappliedCoveredShortSellingTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(uptickRuleUnappliedCoveredShortSellingTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                                            |-> isinCode.value,
         coveredShortSellingTradingVolume                    |-> coveredShortSellingTradingVolume.value,
         coveredShortSellingTradingValue                     |-> coveredShortSellingTradingValue.value,
         uptickRuleAppliedCoveredShortSellingTradingVolume   |-> uptickRuleAppliedCoveredShortSellingTradingVolume.value,
         uptickRuleAppliedCoveredShortSellingTradingValue    |-> uptickRuleAppliedCoveredShortSellingTradingValue.value,
         uptickRuleUnappliedCoveredShortSellingTradingVolume |-> uptickRuleUnappliedCoveredShortSellingTradingVolume.value,
         uptickRuleUnappliedCoveredShortSellingTradingValue  |-> uptickRuleUnappliedCoveredShortSellingTradingValue.value,
         endKeyword                                          |-> endKeyword.value ], endKeyword.rest)

ZeroShortSellingMessage ==
    [ isinCode                                            |-> [i \in 1 .. 12 |-> 0],
      coveredShortSellingTradingVolume                    |-> [i \in 1 .. 12 |-> 0],
      coveredShortSellingTradingValue                     |-> [i \in 1 .. 22 |-> 0],
      uptickRuleAppliedCoveredShortSellingTradingVolume   |-> [i \in 1 .. 12 |-> 0],
      uptickRuleAppliedCoveredShortSellingTradingValue    |-> [i \in 1 .. 22 |-> 0],
      uptickRuleUnappliedCoveredShortSellingTradingVolume |-> [i \in 1 .. 12 |-> 0],
      uptickRuleUnappliedCoveredShortSellingTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                                          |-> [i \in 1 .. 1 |-> 0] ]

(* Short Selling Message at zero, then each field in turn at the values it is checked at *)
CheckedShortSellingMessage ==
    { ZeroShortSellingMessage }
        \cup { [ZeroShortSellingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroShortSellingMessage EXCEPT !.coveredShortSellingTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroShortSellingMessage EXCEPT !.coveredShortSellingTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroShortSellingMessage EXCEPT !.uptickRuleAppliedCoveredShortSellingTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroShortSellingMessage EXCEPT !.uptickRuleAppliedCoveredShortSellingTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroShortSellingMessage EXCEPT !.uptickRuleUnappliedCoveredShortSellingTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroShortSellingMessage EXCEPT !.uptickRuleUnappliedCoveredShortSellingTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroShortSellingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Brokers Acitity Information Message: 86 bytes                           *)
(***************************************************************************)

BrokersAcitityInformationMessage ==
    [ isinCode                    : Sample(12),
      memberNumber                : Sample(5),
      accumulatedAskTradingVolume : Sample(12),
      accumulatedAskTradingValue  : Sample(22),
      accumulatedBidTradingVolume : Sample(12),
      accumulatedBidTradingValue  : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeBrokersAcitityInformationMessage(message) ==
    message.isinCode
        \o message.memberNumber
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.endKeyword

DecodeBrokersAcitityInformationMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET memberNumber == ReadBytes(isinCode.rest, 5) IN IF ~memberNumber.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(memberNumber.rest, 12) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 12) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedBidTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         memberNumber                |-> memberNumber.value,
         accumulatedAskTradingVolume |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue  |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue  |-> accumulatedBidTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroBrokersAcitityInformationMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      memberNumber                |-> [i \in 1 .. 5 |-> 0],
      accumulatedAskTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingValue  |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedBidTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Brokers Acitity Information Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokersAcitityInformationMessage ==
    { ZeroBrokersAcitityInformationMessage }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.memberNumber = one] : one \in Sample(5) }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroBrokersAcitityInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Activity By Session Per An Issue Message: 120 bytes             *)
(***************************************************************************)

TradingActivityBySessionPerAnIssueMessage ==
    [ isinCode                                        : Sample(12),
      totalNumberOfTradableIssuesOnCompetitiveTrading : Sample(5),
      preMarketAccumulatedTradingVolume               : Sample(12),
      preMarketAccumulatedTradingValue                : Sample(22),
      mainMarketAccumulatedTradingVolume              : Sample(12),
      mainMarketAccumulatedTradingValue               : Sample(22),
      afterMarketAccumulatedTradingVolume             : Sample(12),
      afterMarketAccumulatedTradingValue              : Sample(22),
      endKeyword                                      : Sample(1) ]

EncodeTradingActivityBySessionPerAnIssueMessage(message) ==
    message.isinCode
        \o message.totalNumberOfTradableIssuesOnCompetitiveTrading
        \o message.preMarketAccumulatedTradingVolume
        \o message.preMarketAccumulatedTradingValue
        \o message.mainMarketAccumulatedTradingVolume
        \o message.mainMarketAccumulatedTradingValue
        \o message.afterMarketAccumulatedTradingVolume
        \o message.afterMarketAccumulatedTradingValue
        \o message.endKeyword

DecodeTradingActivityBySessionPerAnIssueMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET totalNumberOfTradableIssuesOnCompetitiveTrading == ReadBytes(isinCode.rest, 5) IN IF ~totalNumberOfTradableIssuesOnCompetitiveTrading.ok THEN Fail ELSE
    LET preMarketAccumulatedTradingVolume == ReadBytes(totalNumberOfTradableIssuesOnCompetitiveTrading.rest, 12) IN IF ~preMarketAccumulatedTradingVolume.ok THEN Fail ELSE
    LET preMarketAccumulatedTradingValue == ReadBytes(preMarketAccumulatedTradingVolume.rest, 22) IN IF ~preMarketAccumulatedTradingValue.ok THEN Fail ELSE
    LET mainMarketAccumulatedTradingVolume == ReadBytes(preMarketAccumulatedTradingValue.rest, 12) IN IF ~mainMarketAccumulatedTradingVolume.ok THEN Fail ELSE
    LET mainMarketAccumulatedTradingValue == ReadBytes(mainMarketAccumulatedTradingVolume.rest, 22) IN IF ~mainMarketAccumulatedTradingValue.ok THEN Fail ELSE
    LET afterMarketAccumulatedTradingVolume == ReadBytes(mainMarketAccumulatedTradingValue.rest, 12) IN IF ~afterMarketAccumulatedTradingVolume.ok THEN Fail ELSE
    LET afterMarketAccumulatedTradingValue == ReadBytes(afterMarketAccumulatedTradingVolume.rest, 22) IN IF ~afterMarketAccumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(afterMarketAccumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                                        |-> isinCode.value,
         totalNumberOfTradableIssuesOnCompetitiveTrading |-> totalNumberOfTradableIssuesOnCompetitiveTrading.value,
         preMarketAccumulatedTradingVolume               |-> preMarketAccumulatedTradingVolume.value,
         preMarketAccumulatedTradingValue                |-> preMarketAccumulatedTradingValue.value,
         mainMarketAccumulatedTradingVolume              |-> mainMarketAccumulatedTradingVolume.value,
         mainMarketAccumulatedTradingValue               |-> mainMarketAccumulatedTradingValue.value,
         afterMarketAccumulatedTradingVolume             |-> afterMarketAccumulatedTradingVolume.value,
         afterMarketAccumulatedTradingValue              |-> afterMarketAccumulatedTradingValue.value,
         endKeyword                                      |-> endKeyword.value ], endKeyword.rest)

ZeroTradingActivityBySessionPerAnIssueMessage ==
    [ isinCode                                        |-> [i \in 1 .. 12 |-> 0],
      totalNumberOfTradableIssuesOnCompetitiveTrading |-> [i \in 1 .. 5 |-> 0],
      preMarketAccumulatedTradingVolume               |-> [i \in 1 .. 12 |-> 0],
      preMarketAccumulatedTradingValue                |-> [i \in 1 .. 22 |-> 0],
      mainMarketAccumulatedTradingVolume              |-> [i \in 1 .. 12 |-> 0],
      mainMarketAccumulatedTradingValue               |-> [i \in 1 .. 22 |-> 0],
      afterMarketAccumulatedTradingVolume             |-> [i \in 1 .. 12 |-> 0],
      afterMarketAccumulatedTradingValue              |-> [i \in 1 .. 22 |-> 0],
      endKeyword                                      |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Activity By Session Per An Issue Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActivityBySessionPerAnIssueMessage ==
    { ZeroTradingActivityBySessionPerAnIssueMessage }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.totalNumberOfTradableIssuesOnCompetitiveTrading = one] : one \in Sample(5) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.preMarketAccumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.preMarketAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.mainMarketAccumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.mainMarketAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.afterMarketAccumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.afterMarketAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroTradingActivityBySessionPerAnIssueMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by TR Code                                            *)
(***************************************************************************)

PollingDataMessageCode == <<73, 50, 53, 48, 48>>  \* "I2500"
SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode == <<66, 55, 53, 51, 83>>  \* "B753S"
SecuritiesOrderFilledMessageCode == <<65, 51, 53, 51, 83>>  \* "A353S"
MarketOperationTsMessageCode == <<65, 55, 53, 51, 83>>  \* "A753S"
IssueClosingMessageCode == <<65, 54, 53, 51, 83>>  \* "A653S"
TriggeringRemovingViMessageCode == <<82, 56, 53, 51, 83>>  \* "R853S"
ClosingPriceTradingQuoteMessageCode == <<69, 49, 53, 51, 83>>  \* "E153S"
EquitiesSnapshotMmLpQuotesIncluded10LevelMessageCode == <<66, 50, 53, 51, 83>>  \* "B253S"
InvestorActivitiesPerCommoditiesMessageCode == <<73, 67, 53, 51, 83>>  \* "IC53S"
EtpConstituentsMessageCode == <<86, 54, 53, 48, 83>>  \* "V650S"
EtpConstituentsMessageCode2 == <<69, 65, 53, 48, 83>>  \* "EA50S"
MmLpInformationMessageCode == <<73, 55, 53, 51, 83>>  \* "I753S"
MmLpInformationMessageCode2 == <<69, 66, 53, 51, 83>>  \* "EB53S"
MarketOperationScheduleMessageCode == <<77, 52, 53, 51, 83>>  \* "M453S"
MemberFirmImposingLiftingSanctionsMessageCode == <<82, 51, 53, 48, 83>>  \* "R350S"
TopFiveTradersActivitiesMessageCode == <<66, 57, 53, 51, 83>>  \* "B953S"
EquitiesBatchDataMessageCode == <<65, 48, 53, 51, 83>>  \* "A053S"
EquitiesBatchDataMessageCode2 == <<69, 48, 53, 51, 83>>  \* "E053S"
MemberInformationMessageCode == <<77, 57, 53, 48, 83>>  \* "M950S"
MemberInformationMessageCode2 == <<69, 56, 53, 48, 83>>  \* "E850S"
IssueEventMessageCode == <<73, 54, 53, 51, 83>>  \* "I653S"
IssueEventMessageCode2 == <<69, 54, 53, 51, 83>>  \* "E653S"
BlockBasketTradeDataMessageCode == <<67, 52, 53, 51, 83>>  \* "C453S"
InvestorActivitiesPerAnIssueEodMessageCode == <<67, 49, 53, 51, 83>>  \* "C153S"
ShortSellingMessageCode == <<73, 56, 53, 51, 83>>  \* "I853S"
BrokersAcitityInformationMessageCode == <<69, 50, 53, 51, 83>>  \* "E253S"
TradingActivityBySessionPerAnIssueMessageCode == <<69, 51, 53, 51, 83>>  \* "E353S"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode}, body : SecuritiesQuoteMmLpQuotesIncluded10LevelMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {MarketOperationTsMessageCode}, body : MarketOperationTsMessage ]
        \cup [ tag : {IssueClosingMessageCode}, body : IssueClosingMessage ]
        \cup [ tag : {TriggeringRemovingViMessageCode}, body : TriggeringRemovingViMessage ]
        \cup [ tag : {ClosingPriceTradingQuoteMessageCode}, body : ClosingPriceTradingQuoteMessage ]
        \cup [ tag : {EquitiesSnapshotMmLpQuotesIncluded10LevelMessageCode}, body : EquitiesSnapshotMmLpQuotesIncluded10LevelMessage ]
        \cup [ tag : {InvestorActivitiesPerCommoditiesMessageCode}, body : InvestorActivitiesPerCommoditiesMessage ]
        \cup [ tag : {EtpConstituentsMessageCode}, body : EtpConstituentsMessage ]
        \cup [ tag : {EtpConstituentsMessageCode2}, body : EtpConstituentsMessage ]
        \cup [ tag : {MmLpInformationMessageCode}, body : MmLpInformationMessage ]
        \cup [ tag : {MmLpInformationMessageCode2}, body : MmLpInformationMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MemberFirmImposingLiftingSanctionsMessageCode}, body : MemberFirmImposingLiftingSanctionsMessage ]
        \cup [ tag : {TopFiveTradersActivitiesMessageCode}, body : TopFiveTradersActivitiesMessage ]
        \cup [ tag : {EquitiesBatchDataMessageCode}, body : EquitiesBatchDataMessage ]
        \cup [ tag : {EquitiesBatchDataMessageCode2}, body : EquitiesBatchDataMessage ]
        \cup [ tag : {MemberInformationMessageCode}, body : MemberInformationMessage ]
        \cup [ tag : {MemberInformationMessageCode2}, body : MemberInformationMessage ]
        \cup [ tag : {IssueEventMessageCode}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode2}, body : IssueEventMessage ]
        \cup [ tag : {BlockBasketTradeDataMessageCode}, body : BlockBasketTradeDataMessage ]
        \cup [ tag : {InvestorActivitiesPerAnIssueEodMessageCode}, body : InvestorActivitiesPerAnIssueEodMessage ]
        \cup [ tag : {ShortSellingMessageCode}, body : ShortSellingMessage ]
        \cup [ tag : {BrokersAcitityInformationMessageCode}, body : BrokersAcitityInformationMessage ]
        \cup [ tag : {TradingActivityBySessionPerAnIssueMessageCode}, body : TradingActivityBySessionPerAnIssueMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode -> EncodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = IssueClosingMessageCode -> EncodeIssueClosingMessage(message.body)
      [] message.tag = TriggeringRemovingViMessageCode -> EncodeTriggeringRemovingViMessage(message.body)
      [] message.tag = ClosingPriceTradingQuoteMessageCode -> EncodeClosingPriceTradingQuoteMessage(message.body)
      [] message.tag = EquitiesSnapshotMmLpQuotesIncluded10LevelMessageCode -> EncodeEquitiesSnapshotMmLpQuotesIncluded10LevelMessage(message.body)
      [] message.tag = InvestorActivitiesPerCommoditiesMessageCode -> EncodeInvestorActivitiesPerCommoditiesMessage(message.body)
      [] message.tag = EtpConstituentsMessageCode -> EncodeEtpConstituentsMessage(message.body)
      [] message.tag = EtpConstituentsMessageCode2 -> EncodeEtpConstituentsMessage(message.body)
      [] message.tag = MmLpInformationMessageCode -> EncodeMmLpInformationMessage(message.body)
      [] message.tag = MmLpInformationMessageCode2 -> EncodeMmLpInformationMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MemberFirmImposingLiftingSanctionsMessageCode -> EncodeMemberFirmImposingLiftingSanctionsMessage(message.body)
      [] message.tag = TopFiveTradersActivitiesMessageCode -> EncodeTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = EquitiesBatchDataMessageCode -> EncodeEquitiesBatchDataMessage(message.body)
      [] message.tag = EquitiesBatchDataMessageCode2 -> EncodeEquitiesBatchDataMessage(message.body)
      [] message.tag = MemberInformationMessageCode -> EncodeMemberInformationMessage(message.body)
      [] message.tag = MemberInformationMessageCode2 -> EncodeMemberInformationMessage(message.body)
      [] message.tag = IssueEventMessageCode -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode2 -> EncodeIssueEventMessage(message.body)
      [] message.tag = BlockBasketTradeDataMessageCode -> EncodeBlockBasketTradeDataMessage(message.body)
      [] message.tag = InvestorActivitiesPerAnIssueEodMessageCode -> EncodeInvestorActivitiesPerAnIssueEodMessage(message.body)
      [] message.tag = ShortSellingMessageCode -> EncodeShortSellingMessage(message.body)
      [] message.tag = BrokersAcitityInformationMessageCode -> EncodeBrokersAcitityInformationMessage(message.body)
      [] message.tag = TradingActivityBySessionPerAnIssueMessageCode -> EncodeTradingActivityBySessionPerAnIssueMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = PollingDataMessageCode -> DecodePollingDataMessage(bytes)
              [] tag = SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode -> DecodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = MarketOperationTsMessageCode -> DecodeMarketOperationTsMessage(bytes)
              [] tag = IssueClosingMessageCode -> DecodeIssueClosingMessage(bytes)
              [] tag = TriggeringRemovingViMessageCode -> DecodeTriggeringRemovingViMessage(bytes)
              [] tag = ClosingPriceTradingQuoteMessageCode -> DecodeClosingPriceTradingQuoteMessage(bytes)
              [] tag = EquitiesSnapshotMmLpQuotesIncluded10LevelMessageCode -> DecodeEquitiesSnapshotMmLpQuotesIncluded10LevelMessage(bytes)
              [] tag = InvestorActivitiesPerCommoditiesMessageCode -> DecodeInvestorActivitiesPerCommoditiesMessage(bytes)
              [] tag = EtpConstituentsMessageCode -> DecodeEtpConstituentsMessage(bytes)
              [] tag = EtpConstituentsMessageCode2 -> DecodeEtpConstituentsMessage(bytes)
              [] tag = MmLpInformationMessageCode -> DecodeMmLpInformationMessage(bytes)
              [] tag = MmLpInformationMessageCode2 -> DecodeMmLpInformationMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MemberFirmImposingLiftingSanctionsMessageCode -> DecodeMemberFirmImposingLiftingSanctionsMessage(bytes)
              [] tag = TopFiveTradersActivitiesMessageCode -> DecodeTopFiveTradersActivitiesMessage(bytes)
              [] tag = EquitiesBatchDataMessageCode -> DecodeEquitiesBatchDataMessage(bytes)
              [] tag = EquitiesBatchDataMessageCode2 -> DecodeEquitiesBatchDataMessage(bytes)
              [] tag = MemberInformationMessageCode -> DecodeMemberInformationMessage(bytes)
              [] tag = MemberInformationMessageCode2 -> DecodeMemberInformationMessage(bytes)
              [] tag = IssueEventMessageCode -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode2 -> DecodeIssueEventMessage(bytes)
              [] tag = BlockBasketTradeDataMessageCode -> DecodeBlockBasketTradeDataMessage(bytes)
              [] tag = InvestorActivitiesPerAnIssueEodMessageCode -> DecodeInvestorActivitiesPerAnIssueEodMessage(bytes)
              [] tag = ShortSellingMessageCode -> DecodeShortSellingMessage(bytes)
              [] tag = BrokersAcitityInformationMessageCode -> DecodeBrokersAcitityInformationMessage(bytes)
              [] tag = TradingActivityBySessionPerAnIssueMessageCode -> DecodeTradingActivityBySessionPerAnIssueMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> PollingDataMessageCode, body |-> ZeroPollingDataMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> PollingDataMessageCode, body |-> one] : one \in CheckedPollingDataMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode, body |-> one] : one \in CheckedSecuritiesQuoteMmLpQuotesIncluded10LevelMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> MarketOperationTsMessageCode, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> IssueClosingMessageCode, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> TriggeringRemovingViMessageCode, body |-> one] : one \in CheckedTriggeringRemovingViMessage }
        \cup { [tag |-> ClosingPriceTradingQuoteMessageCode, body |-> one] : one \in CheckedClosingPriceTradingQuoteMessage }
        \cup { [tag |-> EquitiesSnapshotMmLpQuotesIncluded10LevelMessageCode, body |-> one] : one \in CheckedEquitiesSnapshotMmLpQuotesIncluded10LevelMessage }
        \cup { [tag |-> InvestorActivitiesPerCommoditiesMessageCode, body |-> one] : one \in CheckedInvestorActivitiesPerCommoditiesMessage }
        \cup { [tag |-> EtpConstituentsMessageCode, body |-> one] : one \in CheckedEtpConstituentsMessage }
        \cup { [tag |-> EtpConstituentsMessageCode2, body |-> one] : one \in CheckedEtpConstituentsMessage }
        \cup { [tag |-> MmLpInformationMessageCode, body |-> one] : one \in CheckedMmLpInformationMessage }
        \cup { [tag |-> MmLpInformationMessageCode2, body |-> one] : one \in CheckedMmLpInformationMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MemberFirmImposingLiftingSanctionsMessageCode, body |-> one] : one \in CheckedMemberFirmImposingLiftingSanctionsMessage }
        \cup { [tag |-> TopFiveTradersActivitiesMessageCode, body |-> one] : one \in CheckedTopFiveTradersActivitiesMessage }
        \cup { [tag |-> EquitiesBatchDataMessageCode, body |-> one] : one \in CheckedEquitiesBatchDataMessage }
        \cup { [tag |-> EquitiesBatchDataMessageCode2, body |-> one] : one \in CheckedEquitiesBatchDataMessage }
        \cup { [tag |-> MemberInformationMessageCode, body |-> one] : one \in CheckedMemberInformationMessage }
        \cup { [tag |-> MemberInformationMessageCode2, body |-> one] : one \in CheckedMemberInformationMessage }
        \cup { [tag |-> IssueEventMessageCode, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode2, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> BlockBasketTradeDataMessageCode, body |-> one] : one \in CheckedBlockBasketTradeDataMessage }
        \cup { [tag |-> InvestorActivitiesPerAnIssueEodMessageCode, body |-> one] : one \in CheckedInvestorActivitiesPerAnIssueEodMessage }
        \cup { [tag |-> ShortSellingMessageCode, body |-> one] : one \in CheckedShortSellingMessage }
        \cup { [tag |-> BrokersAcitityInformationMessageCode, body |-> one] : one \in CheckedBrokersAcitityInformationMessage }
        \cup { [tag |-> TradingActivityBySessionPerAnIssueMessageCode, body |-> one] : one \in CheckedTradingActivityBySessionPerAnIssueMessage }

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
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode, body |-> ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> TriggeringRemovingViMessageCode, body |-> ZeroTriggeringRemovingViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> ClosingPriceTradingQuoteMessageCode, body |-> ZeroClosingPriceTradingQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquitiesSnapshotMmLpQuotesIncluded10LevelMessageCode, body |-> ZeroEquitiesSnapshotMmLpQuotesIncluded10LevelMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> InvestorActivitiesPerCommoditiesMessageCode, body |-> ZeroInvestorActivitiesPerCommoditiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpConstituentsMessageCode, body |-> ZeroEtpConstituentsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpConstituentsMessageCode2, body |-> ZeroEtpConstituentsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MmLpInformationMessageCode, body |-> ZeroMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MmLpInformationMessageCode2, body |-> ZeroMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmImposingLiftingSanctionsMessageCode, body |-> ZeroMemberFirmImposingLiftingSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> TopFiveTradersActivitiesMessageCode, body |-> ZeroTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquitiesBatchDataMessageCode, body |-> ZeroEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquitiesBatchDataMessageCode2, body |-> ZeroEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberInformationMessageCode, body |-> ZeroMemberInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberInformationMessageCode2, body |-> ZeroMemberInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode2, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BlockBasketTradeDataMessageCode, body |-> ZeroBlockBasketTradeDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> InvestorActivitiesPerAnIssueEodMessageCode, body |-> ZeroInvestorActivitiesPerAnIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> ShortSellingMessageCode, body |-> ZeroShortSellingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BrokersAcitityInformationMessageCode, body |-> ZeroBrokersAcitityInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> TradingActivityBySessionPerAnIssueMessageCode, body |-> ZeroTradingActivityBySessionPerAnIssueMessage]] }

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

(* Every Securities Quote Mm Lp Quotes Included 10 Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesQuoteMmLpQuotesIncluded10LevelMessage ==
    \A message \in CheckedSecuritiesQuoteMmLpQuotesIncluded10LevelMessage :
        LET read == DecodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(EncodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(message))
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

(* Every Equities Snapshot Mm Lp Quotes Included 10 Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquitiesSnapshotMmLpQuotesIncluded10LevelMessage ==
    \A message \in CheckedEquitiesSnapshotMmLpQuotesIncluded10LevelMessage :
        LET read == DecodeEquitiesSnapshotMmLpQuotesIncluded10LevelMessage(EncodeEquitiesSnapshotMmLpQuotesIncluded10LevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Activities Per Commodities Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorActivitiesPerCommoditiesMessage ==
    \A message \in CheckedInvestorActivitiesPerCommoditiesMessage :
        LET read == DecodeInvestorActivitiesPerCommoditiesMessage(EncodeInvestorActivitiesPerCommoditiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Constituents Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpConstituentsMessage ==
    \A message \in CheckedEtpConstituentsMessage :
        LET read == DecodeEtpConstituentsMessage(EncodeEtpConstituentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Lp Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmLpInformationMessage ==
    \A message \in CheckedMmLpInformationMessage :
        LET read == DecodeMmLpInformationMessage(EncodeMmLpInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Operation Schedule Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOperationScheduleMessage ==
    \A message \in CheckedMarketOperationScheduleMessage :
        LET read == DecodeMarketOperationScheduleMessage(EncodeMarketOperationScheduleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Member Firm Imposing Lifting Sanctions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMemberFirmImposingLiftingSanctionsMessage ==
    \A message \in CheckedMemberFirmImposingLiftingSanctionsMessage :
        LET read == DecodeMemberFirmImposingLiftingSanctionsMessage(EncodeMemberFirmImposingLiftingSanctionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Five Traders Activities Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopFiveTradersActivitiesMessage ==
    \A message \in CheckedTopFiveTradersActivitiesMessage :
        LET read == DecodeTopFiveTradersActivitiesMessage(EncodeTopFiveTradersActivitiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equities Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquitiesBatchDataMessage ==
    \A message \in CheckedEquitiesBatchDataMessage :
        LET read == DecodeEquitiesBatchDataMessage(EncodeEquitiesBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Member Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMemberInformationMessage ==
    \A message \in CheckedMemberInformationMessage :
        LET read == DecodeMemberInformationMessage(EncodeMemberInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueEventMessage ==
    \A message \in CheckedIssueEventMessage :
        LET read == DecodeIssueEventMessage(EncodeIssueEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Block Basket Trade Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockBasketTradeDataMessage ==
    \A message \in CheckedBlockBasketTradeDataMessage :
        LET read == DecodeBlockBasketTradeDataMessage(EncodeBlockBasketTradeDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Activities Per An Issue Eod Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorActivitiesPerAnIssueEodMessage ==
    \A message \in CheckedInvestorActivitiesPerAnIssueEodMessage :
        LET read == DecodeInvestorActivitiesPerAnIssueEodMessage(EncodeInvestorActivitiesPerAnIssueEodMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Selling Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSellingMessage ==
    \A message \in CheckedShortSellingMessage :
        LET read == DecodeShortSellingMessage(EncodeShortSellingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Brokers Acitity Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokersAcitityInformationMessage ==
    \A message \in CheckedBrokersAcitityInformationMessage :
        LET read == DecodeBrokersAcitityInformationMessage(EncodeBrokersAcitityInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Activity By Session Per An Issue Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActivityBySessionPerAnIssueMessage ==
    \A message \in CheckedTradingActivityBySessionPerAnIssueMessage :
        LET read == DecodeTradingActivityBySessionPerAnIssueMessage(EncodeTradingActivityBySessionPerAnIssueMessage(message))
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
