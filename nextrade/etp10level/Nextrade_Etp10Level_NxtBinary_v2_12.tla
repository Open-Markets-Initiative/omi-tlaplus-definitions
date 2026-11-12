---------------- MODULE Nextrade_Etp10Level_NxtBinary_v2_12 ----------------
(***************************************************************************)
(* Nextrade Nextrade Etp Market Data 10 Level v2.12                        *)
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
(* Polling Data Message: 8 bytes                                           *)
(***************************************************************************)

PollingDataMessage ==
    [ currentTime1MinuteInterval : Sample(4),
      endKeyword                 : Sample(4) ]

EncodePollingDataMessage(message) ==
    message.currentTime1MinuteInterval
        \o message.endKeyword

DecodePollingDataMessage(bytes) ==
    LET currentTime1MinuteInterval == ReadBytes(bytes, 4) IN IF ~currentTime1MinuteInterval.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(currentTime1MinuteInterval.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ currentTime1MinuteInterval |-> currentTime1MinuteInterval.value,
         endKeyword                 |-> endKeyword.value ], endKeyword.rest)

ZeroPollingDataMessage ==
    [ currentTime1MinuteInterval |-> [i \in 1 .. 4 |-> 0],
      endKeyword                 |-> [i \in 1 .. 4 |-> 0] ]

(* Polling Data Message at zero, then each field in turn at the values it is checked at *)
CheckedPollingDataMessage ==
    { ZeroPollingDataMessage }
        \cup { [ZeroPollingDataMessage EXCEPT !.currentTime1MinuteInterval = one] : one \in Sample(4) }
        \cup { [ZeroPollingDataMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

(***************************************************************************)
(* Securities Quote Mm Lp Quotes Included 10 Level Message: 576 bytes      *)
(***************************************************************************)

SecuritiesQuoteMmLpQuotesIncluded10LevelMessage ==
    [ messageSequenceNumber                          : Sample(4),
      boardId                                        : Sample(2),
      sessionId                                      : Sample(2),
      isinCode                                       : Sample(12),
      aDesignatedNumberForAnIssueFromKrx             : Sample(4),
      processingTimeOfTradingSystem                  : Sample(12),
      askLevel1Price                                 : Sample(8),
      bidLevel1Price                                 : Sample(8),
      askLevel1Volume                                : Sample(8),
      bidLevel1Volume                                : Sample(8),
      lpAskLevel1Volume                              : Sample(8),
      lpBidLevel1Volume                              : Sample(8),
      askLevel2Price                                 : Sample(8),
      bidLevel2Price                                 : Sample(8),
      askLevel2Volume                                : Sample(8),
      bidLevel2Volume                                : Sample(8),
      lpAskLevel2Volume                              : Sample(8),
      lpBidLevel2Volume                              : Sample(8),
      askLevel3Price                                 : Sample(8),
      bidLevel3Price                                 : Sample(8),
      askLevel3Volume                                : Sample(8),
      bidLevel3Volume                                : Sample(8),
      lpAskLevel3Volume                              : Sample(8),
      lpBidLevel3Volume                              : Sample(8),
      askLevel4Price                                 : Sample(8),
      bidLevel4Price                                 : Sample(8),
      askLevel4Volume                                : Sample(8),
      bidLevel4Volume                                : Sample(8),
      lpAskLevel4Volume                              : Sample(8),
      lpBidLevel4Volume                              : Sample(8),
      askLevel5Price                                 : Sample(8),
      bidLevel5Price                                 : Sample(8),
      askLevel5Volume                                : Sample(8),
      bidLevel5Volume                                : Sample(8),
      lpAskLevel5Volume                              : Sample(8),
      lpBidLevel5Volume                              : Sample(8),
      askLevel6Price                                 : Sample(8),
      bidLevel6Price                                 : Sample(8),
      askLevel6Volume                                : Sample(8),
      bidLevel6Volume                                : Sample(8),
      lpAskLevel6Volume                              : Sample(8),
      lpBidLevel6Volume                              : Sample(8),
      askLevel7Price                                 : Sample(8),
      bidLevel7Price                                 : Sample(8),
      askLevel7Volume                                : Sample(8),
      bidLevel7Volume                                : Sample(8),
      lpAskLevel7Volume                              : Sample(8),
      lpBidLevel7Volume                              : Sample(8),
      askLevel8Price                                 : Sample(8),
      bidLevel8Price                                 : Sample(8),
      askLevel8Volume                                : Sample(8),
      bidLevel8Volume                                : Sample(8),
      lpAskLevel8Volume                              : Sample(8),
      lpBidLevel8Volume                              : Sample(8),
      askLevel9Price                                 : Sample(8),
      bidLevel9Price                                 : Sample(8),
      askLevel9Volume                                : Sample(8),
      bidLevel9Volume                                : Sample(8),
      lpAskLevel9Volume                              : Sample(8),
      lpBidLevel9Volume                              : Sample(8),
      askLevel10Price                                : Sample(8),
      bidLevel10Price                                : Sample(8),
      askLevel10Volume                               : Sample(8),
      bidLevel10Volume                               : Sample(8),
      lpAskLevel10Volume                             : Sample(8),
      lpBidLevel10Volume                             : Sample(8),
      totalAskVolume                                 : Sample(8),
      totalBidVolume                                 : Sample(8),
      estimatedTradingPrice                          : Sample(8),
      estimatedTradingVolume                         : Sample(8),
      midPrice                                       : Sample(8),
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice : Sample(8),
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice : Sample(8),
      endKeyword                                     : Sample(4) ]

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
    LET messageSequenceNumber == ReadBytes(bytes, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 4) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 8) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 8) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 8) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 8) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 8) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 8) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 8) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 8) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 8) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 8) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 8) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 8) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 8) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 8) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 8) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 8) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 8) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 8) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 8) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 8) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 8) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 8) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 8) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 8) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 8) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 8) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 8) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 8) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 8) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 8) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 8) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 8) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 8) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 8) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 8) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 8) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 8) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 8) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 8) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 8) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 8) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 8) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 8) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 8) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 8) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 8) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 8) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 8) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 8) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 8) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 8) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 8) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 8) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 8) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 8) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 8) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 8) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 8) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 8) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 8) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 8) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 8) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 8) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 8) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET midPrice == ReadBytes(estimatedTradingVolume.rest, 8) IN IF ~midPrice.ok THEN Fail ELSE
    LET totalMidPriceAskVolumeTotalAskVolumeOnMidPrice == ReadBytes(midPrice.rest, 8) IN IF ~totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.ok THEN Fail ELSE
    LET totalMidPriceBidVolumeTotalBidVolumeOnMidPrice == ReadBytes(totalMidPriceAskVolumeTotalAskVolumeOnMidPrice.rest, 8) IN IF ~totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalMidPriceBidVolumeTotalBidVolumeOnMidPrice.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
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
    [ messageSequenceNumber                          |-> [i \in 1 .. 4 |-> 0],
      boardId                                        |-> [i \in 1 .. 2 |-> 0],
      sessionId                                      |-> [i \in 1 .. 2 |-> 0],
      isinCode                                       |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx             |-> [i \in 1 .. 4 |-> 0],
      processingTimeOfTradingSystem                  |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel1Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel1Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel1Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel1Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel1Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel2Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel2Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel2Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel2Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel2Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel2Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel3Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel3Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel3Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel3Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel3Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel3Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel4Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel4Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel4Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel4Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel4Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel4Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel5Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel5Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel5Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel5Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel5Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel5Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel6Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel6Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel6Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel6Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel6Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel6Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel7Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel7Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel7Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel7Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel7Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel7Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel8Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel8Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel8Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel8Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel8Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel8Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel9Price                                 |-> [i \in 1 .. 8 |-> 0],
      bidLevel9Price                                 |-> [i \in 1 .. 8 |-> 0],
      askLevel9Volume                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel9Volume                                |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel9Volume                              |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel9Volume                              |-> [i \in 1 .. 8 |-> 0],
      askLevel10Price                                |-> [i \in 1 .. 8 |-> 0],
      bidLevel10Price                                |-> [i \in 1 .. 8 |-> 0],
      askLevel10Volume                               |-> [i \in 1 .. 8 |-> 0],
      bidLevel10Volume                               |-> [i \in 1 .. 8 |-> 0],
      lpAskLevel10Volume                             |-> [i \in 1 .. 8 |-> 0],
      lpBidLevel10Volume                             |-> [i \in 1 .. 8 |-> 0],
      totalAskVolume                                 |-> [i \in 1 .. 8 |-> 0],
      totalBidVolume                                 |-> [i \in 1 .. 8 |-> 0],
      estimatedTradingPrice                          |-> [i \in 1 .. 8 |-> 0],
      estimatedTradingVolume                         |-> [i \in 1 .. 8 |-> 0],
      midPrice                                       |-> [i \in 1 .. 8 |-> 0],
      totalMidPriceAskVolumeTotalAskVolumeOnMidPrice |-> [i \in 1 .. 8 |-> 0],
      totalMidPriceBidVolumeTotalBidVolumeOnMidPrice |-> [i \in 1 .. 8 |-> 0],
      endKeyword                                     |-> [i \in 1 .. 4 |-> 0] ]

(* Securities Quote Mm Lp Quotes Included 10 Level Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesQuoteMmLpQuotesIncluded10LevelMessage ==
    { ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel1Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel2Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel3Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel4Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel5Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel6Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel7Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel8Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel9Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel10Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalAskVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalBidVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.midPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalMidPriceAskVolumeTotalAskVolumeOnMidPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.totalMidPriceBidVolumeTotalBidVolumeOnMidPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpQuotesIncluded10LevelMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

(***************************************************************************)
(* Securities Order Filled Message: 138 bytes                              *)
(***************************************************************************)

SecuritiesOrderFilledMessage ==
    [ messageSequenceNumber              : Sample(4),
      boardId                            : Sample(2),
      sessionId                          : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(4),
      processingTimeOfTradingSystem      : Sample(12),
      priceChangeAgainstPreviousDay      : Sample(1),
      aPriceChangeAgainstThePreviousDay  : Sample(8),
      tradingPrice                       : Sample(8),
      tradingVolume                      : Sample(8),
      openingPrice                       : Sample(8),
      todaysHigh                         : Sample(8),
      todaysLow                          : Sample(8),
      accumulatedTradingVolume           : Sample(8),
      accumulatedTradingValue            : Sample(16),
      finalAskBidTypeCode                : Sample(1),
      lpHoldingQuantity                  : Sample(8),
      theBestAsk                         : Sample(8),
      theBestBid                         : Sample(8),
      endKeyword                         : Sample(4) ]

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
    LET messageSequenceNumber == ReadBytes(bytes, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 4) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(processingTimeOfTradingSystem.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 8) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 8) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 8) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(tradingVolume.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 8) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 8) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 8) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 16) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET lpHoldingQuantity == ReadBytes(finalAskBidTypeCode.rest, 8) IN IF ~lpHoldingQuantity.ok THEN Fail ELSE
    LET theBestAsk == ReadBytes(lpHoldingQuantity.rest, 8) IN IF ~theBestAsk.ok THEN Fail ELSE
    LET theBestBid == ReadBytes(theBestAsk.rest, 8) IN IF ~theBestBid.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(theBestBid.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
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
    [ messageSequenceNumber              |-> [i \in 1 .. 4 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      sessionId                          |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 4 |-> 0],
      processingTimeOfTradingSystem      |-> [i \in 1 .. 12 |-> 0],
      priceChangeAgainstPreviousDay      |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay  |-> [i \in 1 .. 8 |-> 0],
      tradingPrice                       |-> [i \in 1 .. 8 |-> 0],
      tradingVolume                      |-> [i \in 1 .. 8 |-> 0],
      openingPrice                       |-> [i \in 1 .. 8 |-> 0],
      todaysHigh                         |-> [i \in 1 .. 8 |-> 0],
      todaysLow                          |-> [i \in 1 .. 8 |-> 0],
      accumulatedTradingVolume           |-> [i \in 1 .. 8 |-> 0],
      accumulatedTradingValue            |-> [i \in 1 .. 16 |-> 0],
      finalAskBidTypeCode                |-> [i \in 1 .. 1 |-> 0],
      lpHoldingQuantity                  |-> [i \in 1 .. 8 |-> 0],
      theBestAsk                         |-> [i \in 1 .. 8 |-> 0],
      theBestBid                         |-> [i \in 1 .. 8 |-> 0],
      endKeyword                         |-> [i \in 1 .. 4 |-> 0] ]

(* Securities Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesOrderFilledMessage ==
    { ZeroSecuritiesOrderFilledMessage }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(16) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.lpHoldingQuantity = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.theBestAsk = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.theBestBid = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Operation Ts Message: 59 bytes                                   *)
(***************************************************************************)

MarketOperationTsMessage ==
    [ messageSequenceNumber              : Sample(4),
      boardId                            : Sample(2),
      sessionId                          : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(4),
      processingTimeOfTradingSystem      : Sample(12),
      boardEventId                       : Sample(3),
      startTimeOfABoardEvent             : Sample(9),
      boardEventGroupCode                : Sample(4),
      tradingHaltReasonCode              : Sample(3),
      endKeyword                         : Sample(4) ]

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
    LET messageSequenceNumber == ReadBytes(bytes, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 4) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 4) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(tradingHaltReasonCode.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
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
    [ messageSequenceNumber              |-> [i \in 1 .. 4 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      sessionId                          |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 4 |-> 0],
      processingTimeOfTradingSystem      |-> [i \in 1 .. 12 |-> 0],
      boardEventId                       |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent             |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode                |-> [i \in 1 .. 4 |-> 0],
      tradingHaltReasonCode              |-> [i \in 1 .. 3 |-> 0],
      endKeyword                         |-> [i \in 1 .. 4 |-> 0] ]

(* Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOperationTsMessage ==
    { ZeroMarketOperationTsMessage }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(4) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(4) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

(***************************************************************************)
(* Issue Closing Message: 83 bytes                                         *)
(***************************************************************************)

IssueClosingMessage ==
    [ messageSequenceNumber                                    : Sample(4),
      boardId                                                  : Sample(2),
      isinCode                                                 : Sample(12),
      aDesignatedNumberForAnIssueFromKrx                       : Sample(4),
      closingPrice                                             : Sample(8),
      closingPriceTypeCode                                     : Sample(1),
      upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession : Sample(8),
      lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession : Sample(8),
      closingPriceWeightedStockPriceAverage                    : Sample(8),
      closingPriceBasePriceOfBuyIn                             : Sample(8),
      closingPriceUpperLimitOfBuyIn                            : Sample(8),
      closingPriceLowerLimitOfBuyIn                            : Sample(8),
      endKeyword                                               : Sample(4) ]

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
    LET messageSequenceNumber == ReadBytes(bytes, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 4) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession == ReadBytes(closingPriceTypeCode.rest, 8) IN IF ~upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.ok THEN Fail ELSE
    LET lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession == ReadBytes(upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.rest, 8) IN IF ~lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.ok THEN Fail ELSE
    LET closingPriceWeightedStockPriceAverage == ReadBytes(lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession.rest, 8) IN IF ~closingPriceWeightedStockPriceAverage.ok THEN Fail ELSE
    LET closingPriceBasePriceOfBuyIn == ReadBytes(closingPriceWeightedStockPriceAverage.rest, 8) IN IF ~closingPriceBasePriceOfBuyIn.ok THEN Fail ELSE
    LET closingPriceUpperLimitOfBuyIn == ReadBytes(closingPriceBasePriceOfBuyIn.rest, 8) IN IF ~closingPriceUpperLimitOfBuyIn.ok THEN Fail ELSE
    LET closingPriceLowerLimitOfBuyIn == ReadBytes(closingPriceUpperLimitOfBuyIn.rest, 8) IN IF ~closingPriceLowerLimitOfBuyIn.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceLowerLimitOfBuyIn.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
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
    [ messageSequenceNumber                                    |-> [i \in 1 .. 4 |-> 0],
      boardId                                                  |-> [i \in 1 .. 2 |-> 0],
      isinCode                                                 |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx                       |-> [i \in 1 .. 4 |-> 0],
      closingPrice                                             |-> [i \in 1 .. 8 |-> 0],
      closingPriceTypeCode                                     |-> [i \in 1 .. 1 |-> 0],
      upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession |-> [i \in 1 .. 8 |-> 0],
      lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession |-> [i \in 1 .. 8 |-> 0],
      closingPriceWeightedStockPriceAverage                    |-> [i \in 1 .. 8 |-> 0],
      closingPriceBasePriceOfBuyIn                             |-> [i \in 1 .. 8 |-> 0],
      closingPriceUpperLimitOfBuyIn                            |-> [i \in 1 .. 8 |-> 0],
      closingPriceLowerLimitOfBuyIn                            |-> [i \in 1 .. 8 |-> 0],
      endKeyword                                               |-> [i \in 1 .. 4 |-> 0] ]

(* Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueClosingMessage ==
    { ZeroIssueClosingMessage }
        \cup { [ZeroIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(4) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.upperLimitPriceOnTheSinglePriceTradeInTheOffHoursSession = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.lowerLimitPriceOnTheSinglePriceTradeInTheOffHoursSession = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceWeightedStockPriceAverage = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceBasePriceOfBuyIn = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceUpperLimitOfBuyIn = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceLowerLimitOfBuyIn = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

(***************************************************************************)
(* Triggering Removing Vi Message: 89 bytes                                *)
(***************************************************************************)

TriggeringRemovingViMessage ==
    [ messageSequenceNumber              : Sample(4),
      boardId                            : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(4),
      processingTimeOfTradingSystem      : Sample(12),
      theTimeEndingVi                    : Sample(9),
      viStatusCode                       : Sample(1),
      viTypeCode                         : Sample(1),
      aBasePriceToTriggerStaticVi        : Sample(8),
      aBasePriceToTriggerDynamicVi       : Sample(8),
      viTriggeringPrice                  : Sample(8),
      disparateRatioToTriggerStaticVi    : Sample(8),
      disparateRatioToTriggerDynamicVi   : Sample(8),
      endKeyword                         : Sample(4) ]

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
    LET messageSequenceNumber == ReadBytes(bytes, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 4) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET theTimeEndingVi == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~theTimeEndingVi.ok THEN Fail ELSE
    LET viStatusCode == ReadBytes(theTimeEndingVi.rest, 1) IN IF ~viStatusCode.ok THEN Fail ELSE
    LET viTypeCode == ReadBytes(viStatusCode.rest, 1) IN IF ~viTypeCode.ok THEN Fail ELSE
    LET aBasePriceToTriggerStaticVi == ReadBytes(viTypeCode.rest, 8) IN IF ~aBasePriceToTriggerStaticVi.ok THEN Fail ELSE
    LET aBasePriceToTriggerDynamicVi == ReadBytes(aBasePriceToTriggerStaticVi.rest, 8) IN IF ~aBasePriceToTriggerDynamicVi.ok THEN Fail ELSE
    LET viTriggeringPrice == ReadBytes(aBasePriceToTriggerDynamicVi.rest, 8) IN IF ~viTriggeringPrice.ok THEN Fail ELSE
    LET disparateRatioToTriggerStaticVi == ReadBytes(viTriggeringPrice.rest, 8) IN IF ~disparateRatioToTriggerStaticVi.ok THEN Fail ELSE
    LET disparateRatioToTriggerDynamicVi == ReadBytes(disparateRatioToTriggerStaticVi.rest, 8) IN IF ~disparateRatioToTriggerDynamicVi.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(disparateRatioToTriggerDynamicVi.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
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
    [ messageSequenceNumber              |-> [i \in 1 .. 4 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 4 |-> 0],
      processingTimeOfTradingSystem      |-> [i \in 1 .. 12 |-> 0],
      theTimeEndingVi                    |-> [i \in 1 .. 9 |-> 0],
      viStatusCode                       |-> [i \in 1 .. 1 |-> 0],
      viTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      aBasePriceToTriggerStaticVi        |-> [i \in 1 .. 8 |-> 0],
      aBasePriceToTriggerDynamicVi       |-> [i \in 1 .. 8 |-> 0],
      viTriggeringPrice                  |-> [i \in 1 .. 8 |-> 0],
      disparateRatioToTriggerStaticVi    |-> [i \in 1 .. 8 |-> 0],
      disparateRatioToTriggerDynamicVi   |-> [i \in 1 .. 8 |-> 0],
      endKeyword                         |-> [i \in 1 .. 4 |-> 0] ]

(* Triggering Removing Vi Message at zero, then each field in turn at the values it is checked at *)
CheckedTriggeringRemovingViMessage ==
    { ZeroTriggeringRemovingViMessage }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(4) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.theTimeEndingVi = one] : one \in Sample(9) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.viStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.viTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.aBasePriceToTriggerStaticVi = one] : one \in Sample(8) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.aBasePriceToTriggerDynamicVi = one] : one \in Sample(8) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.viTriggeringPrice = one] : one \in Sample(8) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.disparateRatioToTriggerStaticVi = one] : one \in Sample(8) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.disparateRatioToTriggerDynamicVi = one] : one \in Sample(8) }
        \cup { [ZeroTriggeringRemovingViMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

(***************************************************************************)
(* Closing Price Trading Quote Message: 42 bytes                           *)
(***************************************************************************)

ClosingPriceTradingQuoteMessage ==
    [ messageSequenceNumber              : Sample(4),
      boardId                            : Sample(2),
      isinCode                           : Sample(12),
      aDesignatedNumberForAnIssueFromKrx : Sample(4),
      totalAskVolume                     : Sample(8),
      totalBidVolume                     : Sample(8),
      endKeyword                         : Sample(4) ]

EncodeClosingPriceTradingQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssueFromKrx
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.endKeyword

DecodeClosingPriceTradingQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssueFromKrx == ReadBytes(isinCode.rest, 4) IN IF ~aDesignatedNumberForAnIssueFromKrx.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(aDesignatedNumberForAnIssueFromKrx.rest, 8) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 8) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalBidVolume.rest, 4) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber              |-> messageSequenceNumber.value,
         boardId                            |-> boardId.value,
         isinCode                           |-> isinCode.value,
         aDesignatedNumberForAnIssueFromKrx |-> aDesignatedNumberForAnIssueFromKrx.value,
         totalAskVolume                     |-> totalAskVolume.value,
         totalBidVolume                     |-> totalBidVolume.value,
         endKeyword                         |-> endKeyword.value ], endKeyword.rest)

ZeroClosingPriceTradingQuoteMessage ==
    [ messageSequenceNumber              |-> [i \in 1 .. 4 |-> 0],
      boardId                            |-> [i \in 1 .. 2 |-> 0],
      isinCode                           |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssueFromKrx |-> [i \in 1 .. 4 |-> 0],
      totalAskVolume                     |-> [i \in 1 .. 8 |-> 0],
      totalBidVolume                     |-> [i \in 1 .. 8 |-> 0],
      endKeyword                         |-> [i \in 1 .. 4 |-> 0] ]

(* Closing Price Trading Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingPriceTradingQuoteMessage ==
    { ZeroClosingPriceTradingQuoteMessage }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.aDesignatedNumberForAnIssueFromKrx = one] : one \in Sample(4) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(8) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(8) }
        \cup { [ZeroClosingPriceTradingQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(4) }

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

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode}, body : SecuritiesQuoteMmLpQuotesIncluded10LevelMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {MarketOperationTsMessageCode}, body : MarketOperationTsMessage ]
        \cup [ tag : {IssueClosingMessageCode}, body : IssueClosingMessage ]
        \cup [ tag : {TriggeringRemovingViMessageCode}, body : TriggeringRemovingViMessage ]
        \cup [ tag : {ClosingPriceTradingQuoteMessageCode}, body : ClosingPriceTradingQuoteMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode -> EncodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = IssueClosingMessageCode -> EncodeIssueClosingMessage(message.body)
      [] message.tag = TriggeringRemovingViMessageCode -> EncodeTriggeringRemovingViMessage(message.body)
      [] message.tag = ClosingPriceTradingQuoteMessageCode -> EncodeClosingPriceTradingQuoteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = PollingDataMessageCode -> DecodePollingDataMessage(bytes)
              [] tag = SecuritiesQuoteMmLpQuotesIncluded10LevelMessageCode -> DecodeSecuritiesQuoteMmLpQuotesIncluded10LevelMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = MarketOperationTsMessageCode -> DecodeMarketOperationTsMessage(bytes)
              [] tag = IssueClosingMessageCode -> DecodeIssueClosingMessage(bytes)
              [] tag = TriggeringRemovingViMessageCode -> DecodeTriggeringRemovingViMessage(bytes)
              [] tag = ClosingPriceTradingQuoteMessageCode -> DecodeClosingPriceTradingQuoteMessage(bytes)
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
      [ZeroPacket EXCEPT !.payload = [tag |-> ClosingPriceTradingQuoteMessageCode, body |-> ZeroClosingPriceTradingQuoteMessage]] }

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
