------ MODULE Cboe_TitaniumConsolidated_MulticastOneEquities_v1_4_13 -------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast One Equities v1.4.13           *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: Adap Block is as many as Adap Blocks says, each of the one kind   *)
(* adapUpdate names by a field read ahead of them all, so they are read as *)
(* a choice between runs: the count is handed to it, and is varied with    *)
(* the run it counts.                                                      *)
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
(* Clear Quote Message: 17 bytes                                           *)
(***************************************************************************)

ClearQuoteMessage ==
    [ lastUpdateTimestamp : Sample(8),
      symbolShort         : Sample(8),
      marketCenter        : Sample(1) ]

EncodeClearQuoteMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolShort
        \o message.marketCenter

DecodeClearQuoteMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolShort.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp |-> lastUpdateTimestamp.value,
         symbolShort         |-> symbolShort.value,
         marketCenter        |-> marketCenter.value ], marketCenter.rest)

ZeroClearQuoteMessage ==
    [ lastUpdateTimestamp |-> [i \in 1 .. 8 |-> 0],
      symbolShort         |-> [i \in 1 .. 8 |-> 0],
      marketCenter        |-> [i \in 1 .. 1 |-> 0] ]

(* Clear Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedClearQuoteMessage ==
    { ZeroClearQuoteMessage }
        \cup { [ZeroClearQuoteMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClearQuoteMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroClearQuoteMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }

(***************************************************************************)
(* Expanded Clear Quote Message: 23 bytes                                  *)
(***************************************************************************)

ExpandedClearQuoteMessage ==
    [ lastUpdateTimestamp : Sample(8),
      symbolLong          : Sample(14),
      marketCenter        : Sample(1) ]

EncodeExpandedClearQuoteMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolLong
        \o message.marketCenter

DecodeExpandedClearQuoteMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(lastUpdateTimestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp |-> lastUpdateTimestamp.value,
         symbolLong          |-> symbolLong.value,
         marketCenter        |-> marketCenter.value ], marketCenter.rest)

ZeroExpandedClearQuoteMessage ==
    [ lastUpdateTimestamp |-> [i \in 1 .. 8 |-> 0],
      symbolLong          |-> [i \in 1 .. 14 |-> 0],
      marketCenter        |-> [i \in 1 .. 1 |-> 0] ]

(* Expanded Clear Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedClearQuoteMessage ==
    { ZeroExpandedClearQuoteMessage }
        \cup { [ZeroExpandedClearQuoteMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedClearQuoteMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedClearQuoteMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Symbol Summary Message: 65 bytes                             *)
(***************************************************************************)

FractionalSymbolSummaryMessage ==
    [ lastUpdateTimestamp          : Sample(8),
      symbolShort                  : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      consolidatedBestBidPrice     : Sample(8),
      consolidatedBestBidQuantity  : Sample(8),
      consolidatedBestAskPrice     : Sample(8),
      consolidatedBestAskQuantity  : Sample(8),
      nationalCumulativeVolume     : Sample(8),
      fractionalSymbolSummaryFlags : Sample(1) ]

EncodeFractionalSymbolSummaryMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolShort
        \o message.cboeCumulativeExecutedVolume
        \o message.consolidatedBestBidPrice
        \o message.consolidatedBestBidQuantity
        \o message.consolidatedBestAskPrice
        \o message.consolidatedBestAskQuantity
        \o message.nationalCumulativeVolume
        \o message.fractionalSymbolSummaryFlags

DecodeFractionalSymbolSummaryMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(symbolShort.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET consolidatedBestBidPrice == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~consolidatedBestBidPrice.ok THEN Fail ELSE
    LET consolidatedBestBidQuantity == ReadBytes(consolidatedBestBidPrice.rest, 8) IN IF ~consolidatedBestBidQuantity.ok THEN Fail ELSE
    LET consolidatedBestAskPrice == ReadBytes(consolidatedBestBidQuantity.rest, 8) IN IF ~consolidatedBestAskPrice.ok THEN Fail ELSE
    LET consolidatedBestAskQuantity == ReadBytes(consolidatedBestAskPrice.rest, 8) IN IF ~consolidatedBestAskQuantity.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(consolidatedBestAskQuantity.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    LET fractionalSymbolSummaryFlags == ReadBytes(nationalCumulativeVolume.rest, 1) IN IF ~fractionalSymbolSummaryFlags.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp          |-> lastUpdateTimestamp.value,
         symbolShort                  |-> symbolShort.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         consolidatedBestBidPrice     |-> consolidatedBestBidPrice.value,
         consolidatedBestBidQuantity  |-> consolidatedBestBidQuantity.value,
         consolidatedBestAskPrice     |-> consolidatedBestAskPrice.value,
         consolidatedBestAskQuantity  |-> consolidatedBestAskQuantity.value,
         nationalCumulativeVolume     |-> nationalCumulativeVolume.value,
         fractionalSymbolSummaryFlags |-> fractionalSymbolSummaryFlags.value ], fractionalSymbolSummaryFlags.rest)

ZeroFractionalSymbolSummaryMessage ==
    [ lastUpdateTimestamp          |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestBidPrice     |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestBidQuantity  |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestAskPrice     |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestAskQuantity  |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume     |-> [i \in 1 .. 8 |-> 0],
      fractionalSymbolSummaryFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Symbol Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalSymbolSummaryMessage ==
    { ZeroFractionalSymbolSummaryMessage }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestAskQuantity = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalSymbolSummaryMessage EXCEPT !.fractionalSymbolSummaryFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Expanded Fractional Symbol Summary Message: 71 bytes                    *)
(***************************************************************************)

ExpandedFractionalSymbolSummaryMessage ==
    [ lastUpdateTimestamp          : Sample(8),
      symbolLong                   : Sample(14),
      cboeCumulativeExecutedVolume : Sample(8),
      consolidatedBestBidPrice     : Sample(8),
      consolidatedBestBidQuantity  : Sample(8),
      consolidatedBestAskPrice     : Sample(8),
      consolidatedBestAskQuantity  : Sample(8),
      nationalCumulativeVolume     : Sample(8),
      reserved1                    : Sample(1) ]

EncodeExpandedFractionalSymbolSummaryMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolLong
        \o message.cboeCumulativeExecutedVolume
        \o message.consolidatedBestBidPrice
        \o message.consolidatedBestBidQuantity
        \o message.consolidatedBestAskPrice
        \o message.consolidatedBestAskQuantity
        \o message.nationalCumulativeVolume
        \o message.reserved1

DecodeExpandedFractionalSymbolSummaryMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(lastUpdateTimestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(symbolLong.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET consolidatedBestBidPrice == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~consolidatedBestBidPrice.ok THEN Fail ELSE
    LET consolidatedBestBidQuantity == ReadBytes(consolidatedBestBidPrice.rest, 8) IN IF ~consolidatedBestBidQuantity.ok THEN Fail ELSE
    LET consolidatedBestAskPrice == ReadBytes(consolidatedBestBidQuantity.rest, 8) IN IF ~consolidatedBestAskPrice.ok THEN Fail ELSE
    LET consolidatedBestAskQuantity == ReadBytes(consolidatedBestAskPrice.rest, 8) IN IF ~consolidatedBestAskQuantity.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(consolidatedBestAskQuantity.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(nationalCumulativeVolume.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp          |-> lastUpdateTimestamp.value,
         symbolLong                   |-> symbolLong.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         consolidatedBestBidPrice     |-> consolidatedBestBidPrice.value,
         consolidatedBestBidQuantity  |-> consolidatedBestBidQuantity.value,
         consolidatedBestAskPrice     |-> consolidatedBestAskPrice.value,
         consolidatedBestAskQuantity  |-> consolidatedBestAskQuantity.value,
         nationalCumulativeVolume     |-> nationalCumulativeVolume.value,
         reserved1                    |-> reserved1.value ], reserved1.rest)

ZeroExpandedFractionalSymbolSummaryMessage ==
    [ lastUpdateTimestamp          |-> [i \in 1 .. 8 |-> 0],
      symbolLong                   |-> [i \in 1 .. 14 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestBidPrice     |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestBidQuantity  |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestAskPrice     |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestAskQuantity  |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume     |-> [i \in 1 .. 8 |-> 0],
      reserved1                    |-> [i \in 1 .. 1 |-> 0] ]

(* Expanded Fractional Symbol Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedFractionalSymbolSummaryMessage ==
    { ZeroExpandedFractionalSymbolSummaryMessage }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.consolidatedBestAskQuantity = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalSymbolSummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Quote Update Message: 33 bytes                                     *)
(***************************************************************************)

BestQuoteUpdateMessage ==
    [ lastUpdateTimestamp        : Sample(8),
      symbolShort                : Sample(8),
      sideIndicator              : Sample(1),
      consolidatedBestQuotePrice : Sample(8),
      consolidatedQuoteQuantity  : Sample(8) ]

EncodeBestQuoteUpdateMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolShort
        \o message.sideIndicator
        \o message.consolidatedBestQuotePrice
        \o message.consolidatedQuoteQuantity

DecodeBestQuoteUpdateMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(symbolShort.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET consolidatedBestQuotePrice == ReadBytes(sideIndicator.rest, 8) IN IF ~consolidatedBestQuotePrice.ok THEN Fail ELSE
    LET consolidatedQuoteQuantity == ReadBytes(consolidatedBestQuotePrice.rest, 8) IN IF ~consolidatedQuoteQuantity.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp        |-> lastUpdateTimestamp.value,
         symbolShort                |-> symbolShort.value,
         sideIndicator              |-> sideIndicator.value,
         consolidatedBestQuotePrice |-> consolidatedBestQuotePrice.value,
         consolidatedQuoteQuantity  |-> consolidatedQuoteQuantity.value ], consolidatedQuoteQuantity.rest)

ZeroBestQuoteUpdateMessage ==
    [ lastUpdateTimestamp        |-> [i \in 1 .. 8 |-> 0],
      symbolShort                |-> [i \in 1 .. 8 |-> 0],
      sideIndicator              |-> [i \in 1 .. 1 |-> 0],
      consolidatedBestQuotePrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedQuoteQuantity  |-> [i \in 1 .. 8 |-> 0] ]

(* Best Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedBestQuoteUpdateMessage ==
    { ZeroBestQuoteUpdateMessage }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.consolidatedBestQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.consolidatedQuoteQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Expanded Best Quote Update Message: 39 bytes                            *)
(***************************************************************************)

ExpandedBestQuoteUpdateMessage ==
    [ lastUpdateTimestamp        : Sample(8),
      symbolLong                 : Sample(14),
      sideIndicator              : Sample(1),
      consolidatedBestQuotePrice : Sample(8),
      consolidatedQuoteQuantity  : Sample(8) ]

EncodeExpandedBestQuoteUpdateMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolLong
        \o message.sideIndicator
        \o message.consolidatedBestQuotePrice
        \o message.consolidatedQuoteQuantity

DecodeExpandedBestQuoteUpdateMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(lastUpdateTimestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(symbolLong.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET consolidatedBestQuotePrice == ReadBytes(sideIndicator.rest, 8) IN IF ~consolidatedBestQuotePrice.ok THEN Fail ELSE
    LET consolidatedQuoteQuantity == ReadBytes(consolidatedBestQuotePrice.rest, 8) IN IF ~consolidatedQuoteQuantity.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp        |-> lastUpdateTimestamp.value,
         symbolLong                 |-> symbolLong.value,
         sideIndicator              |-> sideIndicator.value,
         consolidatedBestQuotePrice |-> consolidatedBestQuotePrice.value,
         consolidatedQuoteQuantity  |-> consolidatedQuoteQuantity.value ], consolidatedQuoteQuantity.rest)

ZeroExpandedBestQuoteUpdateMessage ==
    [ lastUpdateTimestamp        |-> [i \in 1 .. 8 |-> 0],
      symbolLong                 |-> [i \in 1 .. 14 |-> 0],
      sideIndicator              |-> [i \in 1 .. 1 |-> 0],
      consolidatedBestQuotePrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedQuoteQuantity  |-> [i \in 1 .. 8 |-> 0] ]

(* Expanded Best Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedBestQuoteUpdateMessage ==
    { ZeroExpandedBestQuoteUpdateMessage }
        \cup { [ZeroExpandedBestQuoteUpdateMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedBestQuoteUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedBestQuoteUpdateMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExpandedBestQuoteUpdateMessage EXCEPT !.consolidatedBestQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedBestQuoteUpdateMessage EXCEPT !.consolidatedQuoteQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Cboe Market Status Message: 11 bytes                                    *)
(***************************************************************************)

CboeMarketStatusMessage ==
    [ timestamp        : Sample(8),
      marketCenter     : Sample(1),
      marketStatus     : Sample(1),
      sessionIndicator : Sample(1) ]

EncodeCboeMarketStatusMessage(message) ==
    message.timestamp
        \o message.marketCenter
        \o message.marketStatus
        \o message.sessionIndicator

DecodeCboeMarketStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(timestamp.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketStatus == ReadBytes(marketCenter.rest, 1) IN IF ~marketStatus.ok THEN Fail ELSE
    LET sessionIndicator == ReadBytes(marketStatus.rest, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         marketCenter     |-> marketCenter.value,
         marketStatus     |-> marketStatus.value,
         sessionIndicator |-> sessionIndicator.value ], sessionIndicator.rest)

ZeroCboeMarketStatusMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      marketCenter     |-> [i \in 1 .. 1 |-> 0],
      marketStatus     |-> [i \in 1 .. 1 |-> 0],
      sessionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Cboe Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedCboeMarketStatusMessage ==
    { ZeroCboeMarketStatusMessage }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.marketStatus = one] : one \in Sample(1) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Short Update Adap Block: 10 bytes                                       *)
(***************************************************************************)

ShortUpdateAdapBlock ==
    [ marketCenter  : Sample(1),
      side          : Sample(1),
      priceShort    : Sample(4),
      quantityShort : Sample(4) ]

EncodeShortUpdateAdapBlock(message) ==
    message.marketCenter
        \o message.side
        \o message.priceShort
        \o message.quantityShort

DecodeShortUpdateAdapBlock(bytes) ==
    LET marketCenter == ReadBytes(bytes, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET side == ReadBytes(marketCenter.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceShort == ReadBytes(side.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(priceShort.rest, 4) IN IF ~quantityShort.ok THEN Fail ELSE
    Ok([ marketCenter  |-> marketCenter.value,
         side          |-> side.value,
         priceShort    |-> priceShort.value,
         quantityShort |-> quantityShort.value ], quantityShort.rest)

ZeroShortUpdateAdapBlock ==
    [ marketCenter  |-> [i \in 1 .. 1 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      priceShort    |-> [i \in 1 .. 4 |-> 0],
      quantityShort |-> [i \in 1 .. 4 |-> 0] ]

(* Short Update Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedShortUpdateAdapBlock ==
    { ZeroShortUpdateAdapBlock }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.quantityShort = one] : one \in Sample(4) }

(* A run of Short Update Adap Block, written one after another *)
RECURSIVE EncodeShortUpdateAdapBlockList(_)
EncodeShortUpdateAdapBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeShortUpdateAdapBlock(Head(messages)) \o EncodeShortUpdateAdapBlockList(Tail(messages))

(* As many Short Update Adap Block as the field that counts them says *)
RECURSIVE ReadShortUpdateAdapBlockList(_, _)
ReadShortUpdateAdapBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeShortUpdateAdapBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadShortUpdateAdapBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Short Update Adap Block of each kind, for the lists that carry them *)
OneShortUpdateAdapBlock == { ZeroShortUpdateAdapBlock }

(***************************************************************************)
(* Long Update Adap Block: 18 bytes                                        *)
(***************************************************************************)

LongUpdateAdapBlock ==
    [ marketCenter : Sample(1),
      side         : Sample(1),
      priceLong    : Sample(8),
      quantityLong : Sample(8) ]

EncodeLongUpdateAdapBlock(message) ==
    message.marketCenter
        \o message.side
        \o message.priceLong
        \o message.quantityLong

DecodeLongUpdateAdapBlock(bytes) ==
    LET marketCenter == ReadBytes(bytes, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET side == ReadBytes(marketCenter.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(priceLong.rest, 8) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ marketCenter |-> marketCenter.value,
         side         |-> side.value,
         priceLong    |-> priceLong.value,
         quantityLong |-> quantityLong.value ], quantityLong.rest)

ZeroLongUpdateAdapBlock ==
    [ marketCenter |-> [i \in 1 .. 1 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 8 |-> 0] ]

(* Long Update Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedLongUpdateAdapBlock ==
    { ZeroLongUpdateAdapBlock }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.quantityLong = one] : one \in Sample(8) }

(* A run of Long Update Adap Block, written one after another *)
RECURSIVE EncodeLongUpdateAdapBlockList(_)
EncodeLongUpdateAdapBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongUpdateAdapBlock(Head(messages)) \o EncodeLongUpdateAdapBlockList(Tail(messages))

(* As many Long Update Adap Block as the field that counts them says *)
RECURSIVE ReadLongUpdateAdapBlockList(_, _)
ReadLongUpdateAdapBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongUpdateAdapBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongUpdateAdapBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Update Adap Block of each kind, for the lists that carry them *)
OneLongUpdateAdapBlock == { ZeroLongUpdateAdapBlock }

(***************************************************************************)
(* Adap Update, selected by Adap Block Size                                *)
(***************************************************************************)

ShortUpdateAdapBlockCode == 10  \* 0x0a
LongUpdateAdapBlockCode == 18  \* 0x12

AdapUpdate ==
    { [tag |-> ShortUpdateAdapBlockCode, body |-> one] : one \in SampleLists(OneShortUpdateAdapBlock) }
        \cup { [tag |-> LongUpdateAdapBlockCode, body |-> one] : one \in SampleLists(OneLongUpdateAdapBlock) }

EncodeAdapUpdate(message) ==
    CASE message.tag = ShortUpdateAdapBlockCode -> EncodeShortUpdateAdapBlockList(message.body)
      [] message.tag = LongUpdateAdapBlockCode -> EncodeLongUpdateAdapBlockList(message.body)

(* How many Short Update Adap Block a Adap Update holds, which is what Adap Blocks states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountAdapUpdate(choice, stated) ==
    CASE choice.tag = ShortUpdateAdapBlockCode -> Len(choice.body)
      [] choice.tag = LongUpdateAdapBlockCode -> Len(choice.body)

DecodeAdapUpdate(tag, count, bytes) ==
    LET read ==
            CASE tag = ShortUpdateAdapBlockCode -> ReadShortUpdateAdapBlockList(bytes, count)
              [] tag = LongUpdateAdapBlockCode -> ReadLongUpdateAdapBlockList(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdapUpdate == [tag |-> ShortUpdateAdapBlockCode, body |-> << >>]

(* Each Adap Update in turn, at the values the message it names is checked at *)
CheckedAdapUpdate ==
    { [tag |-> ShortUpdateAdapBlockCode, body |-> one] : one \in SampleLists(OneShortUpdateAdapBlock) }
        \cup { [tag |-> LongUpdateAdapBlockCode, body |-> one] : one \in SampleLists(OneLongUpdateAdapBlock) }

(***************************************************************************)
(* Adap Message                                                            *)
(***************************************************************************)

AdapMessage ==
    [ lastUpdateTimestamp : Sample(8),
      symbolShort         : Sample(8),
      adapFlags           : Sample(1),
      reserved1           : Sample(1),
      adapBlocks          : 0 .. 255,
      adapBlock           : AdapUpdate ]

EncodeAdapMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolShort
        \o message.adapFlags
        \o message.reserved1
        \o EncodeUIntBE(message.adapBlocks, 1)
        \o EncodeUIntBE(message.adapBlock.tag, 1)
        \o EncodeAdapUpdate(message.adapBlock)

DecodeAdapMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET adapFlags == ReadBytes(symbolShort.rest, 1) IN IF ~adapFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(adapFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET adapBlocks == ReadUIntBE(reserved1.rest, 1) IN IF ~adapBlocks.ok THEN Fail ELSE
    LET adapBlockSize == ReadUIntBE(adapBlocks.rest, 1) IN IF ~adapBlockSize.ok THEN Fail ELSE
    LET adapBlock == DecodeAdapUpdate(adapBlockSize.value, adapBlocks.value, adapBlockSize.rest) IN IF ~adapBlock.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp |-> lastUpdateTimestamp.value,
         symbolShort         |-> symbolShort.value,
         adapFlags           |-> adapFlags.value,
         reserved1           |-> reserved1.value,
         adapBlocks          |-> adapBlocks.value,
         adapBlock           |-> adapBlock.value ], adapBlock.rest)

ZeroAdapMessage ==
    [ lastUpdateTimestamp |-> [i \in 1 .. 8 |-> 0],
      symbolShort         |-> [i \in 1 .. 8 |-> 0],
      adapFlags           |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      adapBlocks          |-> 0,
      adapBlock           |-> ZeroAdapUpdate ]

(* Adap Message at zero, then each field in turn at the values it is checked at *)
(* Adap Blocks is varied with the Adap Update it counts, which is read as many as it says *)
CheckedAdapMessage ==
    { ZeroAdapMessage }
        \cup { [ZeroAdapMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAdapMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroAdapMessage EXCEPT !.adapFlags = one] : one \in Sample(1) }
        \cup { [ZeroAdapMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroAdapMessage EXCEPT !.adapBlocks = CountAdapUpdate(one, 0), !.adapBlock = one] : one \in CheckedAdapUpdate }

(***************************************************************************)
(* Short Update Adap Block: 10 bytes                                       *)
(***************************************************************************)

ShortUpdateAdapBlock2 ==
    [ marketCenter  : Sample(1),
      side          : Sample(1),
      priceShort    : Sample(4),
      quantityShort : Sample(4) ]

EncodeShortUpdateAdapBlock2(message) ==
    message.marketCenter
        \o message.side
        \o message.priceShort
        \o message.quantityShort

DecodeShortUpdateAdapBlock2(bytes) ==
    LET marketCenter == ReadBytes(bytes, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET side == ReadBytes(marketCenter.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceShort == ReadBytes(side.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(priceShort.rest, 4) IN IF ~quantityShort.ok THEN Fail ELSE
    Ok([ marketCenter  |-> marketCenter.value,
         side          |-> side.value,
         priceShort    |-> priceShort.value,
         quantityShort |-> quantityShort.value ], quantityShort.rest)

ZeroShortUpdateAdapBlock2 ==
    [ marketCenter  |-> [i \in 1 .. 1 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      priceShort    |-> [i \in 1 .. 4 |-> 0],
      quantityShort |-> [i \in 1 .. 4 |-> 0] ]

(* Short Update Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedShortUpdateAdapBlock2 ==
    { ZeroShortUpdateAdapBlock2 }
        \cup { [ZeroShortUpdateAdapBlock2 EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroShortUpdateAdapBlock2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroShortUpdateAdapBlock2 EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroShortUpdateAdapBlock2 EXCEPT !.quantityShort = one] : one \in Sample(4) }

(* A run of Short Update Adap Block, written one after another *)
RECURSIVE EncodeShortUpdateAdapBlock2List(_)
EncodeShortUpdateAdapBlock2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeShortUpdateAdapBlock2(Head(messages)) \o EncodeShortUpdateAdapBlock2List(Tail(messages))

(* As many Short Update Adap Block as the field that counts them says *)
RECURSIVE ReadShortUpdateAdapBlock2List(_, _)
ReadShortUpdateAdapBlock2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeShortUpdateAdapBlock2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadShortUpdateAdapBlock2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Short Update Adap Block of each kind, for the lists that carry them *)
OneShortUpdateAdapBlock2 == { ZeroShortUpdateAdapBlock2 }

(***************************************************************************)
(* Long Update Adap Block: 18 bytes                                        *)
(***************************************************************************)

LongUpdateAdapBlock2 ==
    [ marketCenter : Sample(1),
      side         : Sample(1),
      priceLong    : Sample(8),
      quantityLong : Sample(8) ]

EncodeLongUpdateAdapBlock2(message) ==
    message.marketCenter
        \o message.side
        \o message.priceLong
        \o message.quantityLong

DecodeLongUpdateAdapBlock2(bytes) ==
    LET marketCenter == ReadBytes(bytes, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET side == ReadBytes(marketCenter.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(priceLong.rest, 8) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ marketCenter |-> marketCenter.value,
         side         |-> side.value,
         priceLong    |-> priceLong.value,
         quantityLong |-> quantityLong.value ], quantityLong.rest)

ZeroLongUpdateAdapBlock2 ==
    [ marketCenter |-> [i \in 1 .. 1 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 8 |-> 0] ]

(* Long Update Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedLongUpdateAdapBlock2 ==
    { ZeroLongUpdateAdapBlock2 }
        \cup { [ZeroLongUpdateAdapBlock2 EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroLongUpdateAdapBlock2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLongUpdateAdapBlock2 EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongUpdateAdapBlock2 EXCEPT !.quantityLong = one] : one \in Sample(8) }

(* A run of Long Update Adap Block, written one after another *)
RECURSIVE EncodeLongUpdateAdapBlock2List(_)
EncodeLongUpdateAdapBlock2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongUpdateAdapBlock2(Head(messages)) \o EncodeLongUpdateAdapBlock2List(Tail(messages))

(* As many Long Update Adap Block as the field that counts them says *)
RECURSIVE ReadLongUpdateAdapBlock2List(_, _)
ReadLongUpdateAdapBlock2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongUpdateAdapBlock2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongUpdateAdapBlock2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Update Adap Block of each kind, for the lists that carry them *)
OneLongUpdateAdapBlock2 == { ZeroLongUpdateAdapBlock2 }

(***************************************************************************)
(* Adap Update, selected by Adap Block Size                                *)
(***************************************************************************)

ShortUpdateAdapBlockCode2 == 10  \* 0x0a
LongUpdateAdapBlockCode2 == 18  \* 0x12

AdapUpdate2 ==
    { [tag |-> ShortUpdateAdapBlockCode2, body |-> one] : one \in SampleLists(OneShortUpdateAdapBlock2) }
        \cup { [tag |-> LongUpdateAdapBlockCode2, body |-> one] : one \in SampleLists(OneLongUpdateAdapBlock2) }

EncodeAdapUpdate2(message) ==
    CASE message.tag = ShortUpdateAdapBlockCode2 -> EncodeShortUpdateAdapBlock2List(message.body)
      [] message.tag = LongUpdateAdapBlockCode2 -> EncodeLongUpdateAdapBlock2List(message.body)

(* How many Short Update Adap Block a Adap Update holds, which is what Adap Blocks states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountAdapUpdate2(choice, stated) ==
    CASE choice.tag = ShortUpdateAdapBlockCode2 -> Len(choice.body)
      [] choice.tag = LongUpdateAdapBlockCode2 -> Len(choice.body)

DecodeAdapUpdate2(tag, count, bytes) ==
    LET read ==
            CASE tag = ShortUpdateAdapBlockCode2 -> ReadShortUpdateAdapBlock2List(bytes, count)
              [] tag = LongUpdateAdapBlockCode2 -> ReadLongUpdateAdapBlock2List(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdapUpdate2 == [tag |-> ShortUpdateAdapBlockCode2, body |-> << >>]

(* Each Adap Update in turn, at the values the message it names is checked at *)
CheckedAdapUpdate2 ==
    { [tag |-> ShortUpdateAdapBlockCode2, body |-> one] : one \in SampleLists(OneShortUpdateAdapBlock2) }
        \cup { [tag |-> LongUpdateAdapBlockCode2, body |-> one] : one \in SampleLists(OneLongUpdateAdapBlock2) }

(***************************************************************************)
(* Expanded Adap Message                                                   *)
(***************************************************************************)

ExpandedAdapMessage ==
    [ lastUpdateTimestamp : Sample(8),
      symbolLong          : Sample(14),
      adapFlags           : Sample(1),
      reserved1           : Sample(1),
      adapBlocks          : 0 .. 255,
      adapBlock           : AdapUpdate2 ]

EncodeExpandedAdapMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbolLong
        \o message.adapFlags
        \o message.reserved1
        \o EncodeUIntBE(message.adapBlocks, 1)
        \o EncodeUIntBE(message.adapBlock.tag, 1)
        \o EncodeAdapUpdate2(message.adapBlock)

DecodeExpandedAdapMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(lastUpdateTimestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET adapFlags == ReadBytes(symbolLong.rest, 1) IN IF ~adapFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(adapFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET adapBlocks == ReadUIntBE(reserved1.rest, 1) IN IF ~adapBlocks.ok THEN Fail ELSE
    LET adapBlockSize == ReadUIntBE(adapBlocks.rest, 1) IN IF ~adapBlockSize.ok THEN Fail ELSE
    LET adapBlock == DecodeAdapUpdate2(adapBlockSize.value, adapBlocks.value, adapBlockSize.rest) IN IF ~adapBlock.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp |-> lastUpdateTimestamp.value,
         symbolLong          |-> symbolLong.value,
         adapFlags           |-> adapFlags.value,
         reserved1           |-> reserved1.value,
         adapBlocks          |-> adapBlocks.value,
         adapBlock           |-> adapBlock.value ], adapBlock.rest)

ZeroExpandedAdapMessage ==
    [ lastUpdateTimestamp |-> [i \in 1 .. 8 |-> 0],
      symbolLong          |-> [i \in 1 .. 14 |-> 0],
      adapFlags           |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      adapBlocks          |-> 0,
      adapBlock           |-> ZeroAdapUpdate2 ]

(* Expanded Adap Message at zero, then each field in turn at the values it is checked at *)
(* Adap Blocks is varied with the Adap Update it counts, which is read as many as it says *)
CheckedExpandedAdapMessage ==
    { ZeroExpandedAdapMessage }
        \cup { [ZeroExpandedAdapMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedAdapMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedAdapMessage EXCEPT !.adapFlags = one] : one \in Sample(1) }
        \cup { [ZeroExpandedAdapMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExpandedAdapMessage EXCEPT !.adapBlocks = CountAdapUpdate2(one, 0), !.adapBlock = one] : one \in CheckedAdapUpdate2 }

(***************************************************************************)
(* Rpi Message: 18 bytes                                                   *)
(***************************************************************************)

RpiMessage ==
    [ timestamp              : Sample(8),
      symbolShort            : Sample(8),
      marketCenter           : Sample(1),
      retailPriceImprovement : Sample(1) ]

EncodeRpiMessage(message) ==
    message.timestamp
        \o message.symbolShort
        \o message.marketCenter
        \o message.retailPriceImprovement

DecodeRpiMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolShort.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET retailPriceImprovement == ReadBytes(marketCenter.rest, 1) IN IF ~retailPriceImprovement.ok THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         symbolShort            |-> symbolShort.value,
         marketCenter           |-> marketCenter.value,
         retailPriceImprovement |-> retailPriceImprovement.value ], retailPriceImprovement.rest)

ZeroRpiMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      symbolShort            |-> [i \in 1 .. 8 |-> 0],
      marketCenter           |-> [i \in 1 .. 1 |-> 0],
      retailPriceImprovement |-> [i \in 1 .. 1 |-> 0] ]

(* Rpi Message at zero, then each field in turn at the values it is checked at *)
CheckedRpiMessage ==
    { ZeroRpiMessage }
        \cup { [ZeroRpiMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRpiMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroRpiMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroRpiMessage EXCEPT !.retailPriceImprovement = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Trade Message: 58 bytes                                      *)
(***************************************************************************)

FractionalTradeMessage ==
    [ transactionTime              : Sample(8),
      symbolShort                  : Sample(8),
      marketCenter                 : Sample(1),
      marketCenterExecutionId      : Sample(8),
      lastPrice                    : Sample(8),
      lastQuantity                 : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      nationalCumulativeVolume     : Sample(8),
      fractionalTradeFlags         : Sample(1) ]

EncodeFractionalTradeMessage(message) ==
    message.transactionTime
        \o message.symbolShort
        \o message.marketCenter
        \o message.marketCenterExecutionId
        \o message.lastPrice
        \o message.lastQuantity
        \o message.cboeCumulativeExecutedVolume
        \o message.nationalCumulativeVolume
        \o message.fractionalTradeFlags

DecodeFractionalTradeMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(transactionTime.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolShort.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketCenterExecutionId == ReadBytes(marketCenter.rest, 8) IN IF ~marketCenterExecutionId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(marketCenterExecutionId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastQuantity == ReadBytes(lastPrice.rest, 8) IN IF ~lastQuantity.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(lastQuantity.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    LET fractionalTradeFlags == ReadBytes(nationalCumulativeVolume.rest, 1) IN IF ~fractionalTradeFlags.ok THEN Fail ELSE
    Ok([ transactionTime              |-> transactionTime.value,
         symbolShort                  |-> symbolShort.value,
         marketCenter                 |-> marketCenter.value,
         marketCenterExecutionId      |-> marketCenterExecutionId.value,
         lastPrice                    |-> lastPrice.value,
         lastQuantity                 |-> lastQuantity.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         nationalCumulativeVolume     |-> nationalCumulativeVolume.value,
         fractionalTradeFlags         |-> fractionalTradeFlags.value ], fractionalTradeFlags.rest)

ZeroFractionalTradeMessage ==
    [ transactionTime              |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 8 |-> 0],
      marketCenter                 |-> [i \in 1 .. 1 |-> 0],
      marketCenterExecutionId      |-> [i \in 1 .. 8 |-> 0],
      lastPrice                    |-> [i \in 1 .. 8 |-> 0],
      lastQuantity                 |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume     |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeFlags         |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeMessage ==
    { ZeroFractionalTradeMessage }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.marketCenterExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.lastQuantity = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeMessage EXCEPT !.fractionalTradeFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Expanded Fractional Trade Message: 64 bytes                             *)
(***************************************************************************)

ExpandedFractionalTradeMessage ==
    [ transactionTime              : Sample(8),
      symbolLong                   : Sample(14),
      marketCenter                 : Sample(1),
      marketCenterExecutionId      : Sample(8),
      lastPrice                    : Sample(8),
      lastQuantity                 : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      nationalCumulativeVolume     : Sample(8),
      reserved1                    : Sample(1) ]

EncodeExpandedFractionalTradeMessage(message) ==
    message.transactionTime
        \o message.symbolLong
        \o message.marketCenter
        \o message.marketCenterExecutionId
        \o message.lastPrice
        \o message.lastQuantity
        \o message.cboeCumulativeExecutedVolume
        \o message.nationalCumulativeVolume
        \o message.reserved1

DecodeExpandedFractionalTradeMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(transactionTime.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketCenterExecutionId == ReadBytes(marketCenter.rest, 8) IN IF ~marketCenterExecutionId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(marketCenterExecutionId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastQuantity == ReadBytes(lastPrice.rest, 8) IN IF ~lastQuantity.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(lastQuantity.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(nationalCumulativeVolume.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ transactionTime              |-> transactionTime.value,
         symbolLong                   |-> symbolLong.value,
         marketCenter                 |-> marketCenter.value,
         marketCenterExecutionId      |-> marketCenterExecutionId.value,
         lastPrice                    |-> lastPrice.value,
         lastQuantity                 |-> lastQuantity.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         nationalCumulativeVolume     |-> nationalCumulativeVolume.value,
         reserved1                    |-> reserved1.value ], reserved1.rest)

ZeroExpandedFractionalTradeMessage ==
    [ transactionTime              |-> [i \in 1 .. 8 |-> 0],
      symbolLong                   |-> [i \in 1 .. 14 |-> 0],
      marketCenter                 |-> [i \in 1 .. 1 |-> 0],
      marketCenterExecutionId      |-> [i \in 1 .. 8 |-> 0],
      lastPrice                    |-> [i \in 1 .. 8 |-> 0],
      lastQuantity                 |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume     |-> [i \in 1 .. 8 |-> 0],
      reserved1                    |-> [i \in 1 .. 1 |-> 0] ]

(* Expanded Fractional Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedFractionalTradeMessage ==
    { ZeroExpandedFractionalTradeMessage }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.marketCenterExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.lastQuantity = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Trade Break Message: 42 bytes                                *)
(***************************************************************************)

FractionalTradeBreakMessage ==
    [ transactionTime              : Sample(8),
      symbolShort                  : Sample(8),
      marketCenter                 : Sample(1),
      marketCenterExecutionId      : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      nationalCumulativeVolume     : Sample(8),
      fractionalTradeBreakFlags    : Sample(1) ]

EncodeFractionalTradeBreakMessage(message) ==
    message.transactionTime
        \o message.symbolShort
        \o message.marketCenter
        \o message.marketCenterExecutionId
        \o message.cboeCumulativeExecutedVolume
        \o message.nationalCumulativeVolume
        \o message.fractionalTradeBreakFlags

DecodeFractionalTradeBreakMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(transactionTime.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolShort.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketCenterExecutionId == ReadBytes(marketCenter.rest, 8) IN IF ~marketCenterExecutionId.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(marketCenterExecutionId.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    LET fractionalTradeBreakFlags == ReadBytes(nationalCumulativeVolume.rest, 1) IN IF ~fractionalTradeBreakFlags.ok THEN Fail ELSE
    Ok([ transactionTime              |-> transactionTime.value,
         symbolShort                  |-> symbolShort.value,
         marketCenter                 |-> marketCenter.value,
         marketCenterExecutionId      |-> marketCenterExecutionId.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         nationalCumulativeVolume     |-> nationalCumulativeVolume.value,
         fractionalTradeBreakFlags    |-> fractionalTradeBreakFlags.value ], fractionalTradeBreakFlags.rest)

ZeroFractionalTradeBreakMessage ==
    [ transactionTime              |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 8 |-> 0],
      marketCenter                 |-> [i \in 1 .. 1 |-> 0],
      marketCenterExecutionId      |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume     |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeBreakFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeBreakMessage ==
    { ZeroFractionalTradeBreakMessage }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.marketCenterExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeBreakMessage EXCEPT !.fractionalTradeBreakFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Expanded Fractional Trade Break Message: 48 bytes                       *)
(***************************************************************************)

ExpandedFractionalTradeBreakMessage ==
    [ transactionTime              : Sample(8),
      symbolLong                   : Sample(14),
      marketCenter                 : Sample(1),
      marketCenterExecutionId      : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      nationalCumulativeVolume     : Sample(8),
      reserved1                    : Sample(1) ]

EncodeExpandedFractionalTradeBreakMessage(message) ==
    message.transactionTime
        \o message.symbolLong
        \o message.marketCenter
        \o message.marketCenterExecutionId
        \o message.cboeCumulativeExecutedVolume
        \o message.nationalCumulativeVolume
        \o message.reserved1

DecodeExpandedFractionalTradeBreakMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(transactionTime.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketCenterExecutionId == ReadBytes(marketCenter.rest, 8) IN IF ~marketCenterExecutionId.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(marketCenterExecutionId.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(nationalCumulativeVolume.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ transactionTime              |-> transactionTime.value,
         symbolLong                   |-> symbolLong.value,
         marketCenter                 |-> marketCenter.value,
         marketCenterExecutionId      |-> marketCenterExecutionId.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         nationalCumulativeVolume     |-> nationalCumulativeVolume.value,
         reserved1                    |-> reserved1.value ], reserved1.rest)

ZeroExpandedFractionalTradeBreakMessage ==
    [ transactionTime              |-> [i \in 1 .. 8 |-> 0],
      symbolLong                   |-> [i \in 1 .. 14 |-> 0],
      marketCenter                 |-> [i \in 1 .. 1 |-> 0],
      marketCenterExecutionId      |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume     |-> [i \in 1 .. 8 |-> 0],
      reserved1                    |-> [i \in 1 .. 1 |-> 0] ]

(* Expanded Fractional Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedFractionalTradeBreakMessage ==
    { ZeroExpandedFractionalTradeBreakMessage }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.marketCenterExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalTradeBreakMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Status Message: 19 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timestamp     : Sample(8),
      symbolShort   : Sample(8),
      marketCenter  : Sample(1),
      tradingStatus : Sample(1),
      regShoAction  : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbolShort
        \o message.marketCenter
        \o message.tradingStatus
        \o message.regShoAction

DecodeTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolShort.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(marketCenter.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(tradingStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbolShort   |-> symbolShort.value,
         marketCenter  |-> marketCenter.value,
         tradingStatus |-> tradingStatus.value,
         regShoAction  |-> regShoAction.value ], regShoAction.rest)

ZeroTradingStatusMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbolShort   |-> [i \in 1 .. 8 |-> 0],
      marketCenter  |-> [i \in 1 .. 1 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      regShoAction  |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Expanded Trading Status Message: 25 bytes                               *)
(***************************************************************************)

ExpandedTradingStatusMessage ==
    [ timestamp     : Sample(8),
      symbolLong    : Sample(14),
      marketCenter  : Sample(1),
      tradingStatus : Sample(1),
      regShoAction  : Sample(1) ]

EncodeExpandedTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbolLong
        \o message.marketCenter
        \o message.tradingStatus
        \o message.regShoAction

DecodeExpandedTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(marketCenter.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(tradingStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbolLong    |-> symbolLong.value,
         marketCenter  |-> marketCenter.value,
         tradingStatus |-> tradingStatus.value,
         regShoAction  |-> regShoAction.value ], regShoAction.rest)

ZeroExpandedTradingStatusMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbolLong    |-> [i \in 1 .. 14 |-> 0],
      marketCenter  |-> [i \in 1 .. 1 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      regShoAction  |-> [i \in 1 .. 1 |-> 0] ]

(* Expanded Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedTradingStatusMessage ==
    { ZeroExpandedTradingStatusMessage }
        \cup { [ZeroExpandedTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedTradingStatusMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedTradingStatusMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroExpandedTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroExpandedTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Opening Closing Price Message: 26 bytes                                 *)
(***************************************************************************)

OpeningClosingPriceMessage ==
    [ timestamp          : Sample(8),
      symbolShort        : Sample(8),
      marketCenter       : Sample(1),
      openCloseIndicator : Sample(1),
      priceLong          : Sample(8) ]

EncodeOpeningClosingPriceMessage(message) ==
    message.timestamp
        \o message.symbolShort
        \o message.marketCenter
        \o message.openCloseIndicator
        \o message.priceLong

DecodeOpeningClosingPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolShort.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(marketCenter.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET priceLong == ReadBytes(openCloseIndicator.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         symbolShort        |-> symbolShort.value,
         marketCenter       |-> marketCenter.value,
         openCloseIndicator |-> openCloseIndicator.value,
         priceLong          |-> priceLong.value ], priceLong.rest)

ZeroOpeningClosingPriceMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbolShort        |-> [i \in 1 .. 8 |-> 0],
      marketCenter       |-> [i \in 1 .. 1 |-> 0],
      openCloseIndicator |-> [i \in 1 .. 1 |-> 0],
      priceLong          |-> [i \in 1 .. 8 |-> 0] ]

(* Opening Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningClosingPriceMessage ==
    { ZeroOpeningClosingPriceMessage }
        \cup { [ZeroOpeningClosingPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOpeningClosingPriceMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroOpeningClosingPriceMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroOpeningClosingPriceMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOpeningClosingPriceMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Expanded Opening Closing Price Message: 32 bytes                        *)
(***************************************************************************)

ExpandedOpeningClosingPriceMessage ==
    [ timestamp          : Sample(8),
      symbolLong         : Sample(14),
      marketCenter       : Sample(1),
      openCloseIndicator : Sample(1),
      priceLong          : Sample(8) ]

EncodeExpandedOpeningClosingPriceMessage(message) ==
    message.timestamp
        \o message.symbolLong
        \o message.marketCenter
        \o message.openCloseIndicator
        \o message.priceLong

DecodeExpandedOpeningClosingPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(marketCenter.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET priceLong == ReadBytes(openCloseIndicator.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         symbolLong         |-> symbolLong.value,
         marketCenter       |-> marketCenter.value,
         openCloseIndicator |-> openCloseIndicator.value,
         priceLong          |-> priceLong.value ], priceLong.rest)

ZeroExpandedOpeningClosingPriceMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbolLong         |-> [i \in 1 .. 14 |-> 0],
      marketCenter       |-> [i \in 1 .. 1 |-> 0],
      openCloseIndicator |-> [i \in 1 .. 1 |-> 0],
      priceLong          |-> [i \in 1 .. 8 |-> 0] ]

(* Expanded Opening Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedOpeningClosingPriceMessage ==
    { ZeroExpandedOpeningClosingPriceMessage }
        \cup { [ZeroExpandedOpeningClosingPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedOpeningClosingPriceMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedOpeningClosingPriceMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroExpandedOpeningClosingPriceMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExpandedOpeningClosingPriceMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional End Of Day Summary Message: 57 bytes                         *)
(***************************************************************************)

FractionalEndOfDaySummaryMessage ==
    [ timestamp                : Sample(8),
      symbolShort              : Sample(8),
      dataSource               : Sample(1),
      openingPrice             : Sample(8),
      closingPrice             : Sample(8),
      highPrice                : Sample(8),
      lowPrice                 : Sample(8),
      nationalCumulativeVolume : Sample(8) ]

EncodeFractionalEndOfDaySummaryMessage(message) ==
    message.timestamp
        \o message.symbolShort
        \o message.dataSource
        \o message.openingPrice
        \o message.closingPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.nationalCumulativeVolume

DecodeFractionalEndOfDaySummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timestamp.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET dataSource == ReadBytes(symbolShort.rest, 1) IN IF ~dataSource.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(dataSource.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(openingPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(closingPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(lowPrice.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         symbolShort              |-> symbolShort.value,
         dataSource               |-> dataSource.value,
         openingPrice             |-> openingPrice.value,
         closingPrice             |-> closingPrice.value,
         highPrice                |-> highPrice.value,
         lowPrice                 |-> lowPrice.value,
         nationalCumulativeVolume |-> nationalCumulativeVolume.value ], nationalCumulativeVolume.rest)

ZeroFractionalEndOfDaySummaryMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      symbolShort              |-> [i \in 1 .. 8 |-> 0],
      dataSource               |-> [i \in 1 .. 1 |-> 0],
      openingPrice             |-> [i \in 1 .. 8 |-> 0],
      closingPrice             |-> [i \in 1 .. 8 |-> 0],
      highPrice                |-> [i \in 1 .. 8 |-> 0],
      lowPrice                 |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalEndOfDaySummaryMessage ==
    { ZeroFractionalEndOfDaySummaryMessage }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.dataSource = one] : one \in Sample(1) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalEndOfDaySummaryMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Expanded Fractional End Of Day Summary Message: 63 bytes                *)
(***************************************************************************)

ExpandedFractionalEndOfDaySummaryMessage ==
    [ timestamp                : Sample(8),
      symbolLong               : Sample(14),
      dataSource               : Sample(1),
      openingPrice             : Sample(8),
      closingPrice             : Sample(8),
      highPrice                : Sample(8),
      lowPrice                 : Sample(8),
      nationalCumulativeVolume : Sample(8) ]

EncodeExpandedFractionalEndOfDaySummaryMessage(message) ==
    message.timestamp
        \o message.symbolLong
        \o message.dataSource
        \o message.openingPrice
        \o message.closingPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.nationalCumulativeVolume

DecodeExpandedFractionalEndOfDaySummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp.rest, 14) IN IF ~symbolLong.ok THEN Fail ELSE
    LET dataSource == ReadBytes(symbolLong.rest, 1) IN IF ~dataSource.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(dataSource.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(openingPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(closingPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET nationalCumulativeVolume == ReadBytes(lowPrice.rest, 8) IN IF ~nationalCumulativeVolume.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         symbolLong               |-> symbolLong.value,
         dataSource               |-> dataSource.value,
         openingPrice             |-> openingPrice.value,
         closingPrice             |-> closingPrice.value,
         highPrice                |-> highPrice.value,
         lowPrice                 |-> lowPrice.value,
         nationalCumulativeVolume |-> nationalCumulativeVolume.value ], nationalCumulativeVolume.rest)

ZeroExpandedFractionalEndOfDaySummaryMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      symbolLong               |-> [i \in 1 .. 14 |-> 0],
      dataSource               |-> [i \in 1 .. 1 |-> 0],
      openingPrice             |-> [i \in 1 .. 8 |-> 0],
      closingPrice             |-> [i \in 1 .. 8 |-> 0],
      highPrice                |-> [i \in 1 .. 8 |-> 0],
      lowPrice                 |-> [i \in 1 .. 8 |-> 0],
      nationalCumulativeVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Expanded Fractional End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedFractionalEndOfDaySummaryMessage ==
    { ZeroExpandedFractionalEndOfDaySummaryMessage }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.symbolLong = one] : one \in Sample(14) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.dataSource = one] : one \in Sample(1) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroExpandedFractionalEndOfDaySummaryMessage EXCEPT !.nationalCumulativeVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

ClearQuoteMessageCode == 162  \* 0xa2
ExpandedClearQuoteMessageCode == 240  \* 0xf0
FractionalSymbolSummaryMessageCode == 231  \* 0xe7
ExpandedFractionalSymbolSummaryMessageCode == 235  \* 0xeb
BestQuoteUpdateMessageCode == 165  \* 0xa5
ExpandedBestQuoteUpdateMessageCode == 242  \* 0xf2
CboeMarketStatusMessageCode == 166  \* 0xa6
AdapMessageCode == 167  \* 0xa7
ExpandedAdapMessageCode == 243  \* 0xf3
RpiMessageCode == 168  \* 0xa8
FractionalTradeMessageCode == 232  \* 0xe8
ExpandedFractionalTradeMessageCode == 236  \* 0xec
FractionalTradeBreakMessageCode == 233  \* 0xe9
ExpandedFractionalTradeBreakMessageCode == 237  \* 0xed
TradingStatusMessageCode == 171  \* 0xab
ExpandedTradingStatusMessageCode == 246  \* 0xf6
OpeningClosingPriceMessageCode == 176  \* 0xb0
ExpandedOpeningClosingPriceMessageCode == 247  \* 0xf7
FractionalEndOfDaySummaryMessageCode == 234  \* 0xea
ExpandedFractionalEndOfDaySummaryMessageCode == 239  \* 0xef

Payload ==
    [ tag : {ClearQuoteMessageCode}, body : ClearQuoteMessage ]
        \cup [ tag : {ExpandedClearQuoteMessageCode}, body : ExpandedClearQuoteMessage ]
        \cup [ tag : {FractionalSymbolSummaryMessageCode}, body : FractionalSymbolSummaryMessage ]
        \cup [ tag : {ExpandedFractionalSymbolSummaryMessageCode}, body : ExpandedFractionalSymbolSummaryMessage ]
        \cup [ tag : {BestQuoteUpdateMessageCode}, body : BestQuoteUpdateMessage ]
        \cup [ tag : {ExpandedBestQuoteUpdateMessageCode}, body : ExpandedBestQuoteUpdateMessage ]
        \cup [ tag : {CboeMarketStatusMessageCode}, body : CboeMarketStatusMessage ]
        \cup [ tag : {AdapMessageCode}, body : AdapMessage ]
        \cup [ tag : {ExpandedAdapMessageCode}, body : ExpandedAdapMessage ]
        \cup [ tag : {RpiMessageCode}, body : RpiMessage ]
        \cup [ tag : {FractionalTradeMessageCode}, body : FractionalTradeMessage ]
        \cup [ tag : {ExpandedFractionalTradeMessageCode}, body : ExpandedFractionalTradeMessage ]
        \cup [ tag : {FractionalTradeBreakMessageCode}, body : FractionalTradeBreakMessage ]
        \cup [ tag : {ExpandedFractionalTradeBreakMessageCode}, body : ExpandedFractionalTradeBreakMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {ExpandedTradingStatusMessageCode}, body : ExpandedTradingStatusMessage ]
        \cup [ tag : {OpeningClosingPriceMessageCode}, body : OpeningClosingPriceMessage ]
        \cup [ tag : {ExpandedOpeningClosingPriceMessageCode}, body : ExpandedOpeningClosingPriceMessage ]
        \cup [ tag : {FractionalEndOfDaySummaryMessageCode}, body : FractionalEndOfDaySummaryMessage ]
        \cup [ tag : {ExpandedFractionalEndOfDaySummaryMessageCode}, body : ExpandedFractionalEndOfDaySummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = ClearQuoteMessageCode -> EncodeClearQuoteMessage(message.body)
      [] message.tag = ExpandedClearQuoteMessageCode -> EncodeExpandedClearQuoteMessage(message.body)
      [] message.tag = FractionalSymbolSummaryMessageCode -> EncodeFractionalSymbolSummaryMessage(message.body)
      [] message.tag = ExpandedFractionalSymbolSummaryMessageCode -> EncodeExpandedFractionalSymbolSummaryMessage(message.body)
      [] message.tag = BestQuoteUpdateMessageCode -> EncodeBestQuoteUpdateMessage(message.body)
      [] message.tag = ExpandedBestQuoteUpdateMessageCode -> EncodeExpandedBestQuoteUpdateMessage(message.body)
      [] message.tag = CboeMarketStatusMessageCode -> EncodeCboeMarketStatusMessage(message.body)
      [] message.tag = AdapMessageCode -> EncodeAdapMessage(message.body)
      [] message.tag = ExpandedAdapMessageCode -> EncodeExpandedAdapMessage(message.body)
      [] message.tag = RpiMessageCode -> EncodeRpiMessage(message.body)
      [] message.tag = FractionalTradeMessageCode -> EncodeFractionalTradeMessage(message.body)
      [] message.tag = ExpandedFractionalTradeMessageCode -> EncodeExpandedFractionalTradeMessage(message.body)
      [] message.tag = FractionalTradeBreakMessageCode -> EncodeFractionalTradeBreakMessage(message.body)
      [] message.tag = ExpandedFractionalTradeBreakMessageCode -> EncodeExpandedFractionalTradeBreakMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = ExpandedTradingStatusMessageCode -> EncodeExpandedTradingStatusMessage(message.body)
      [] message.tag = OpeningClosingPriceMessageCode -> EncodeOpeningClosingPriceMessage(message.body)
      [] message.tag = ExpandedOpeningClosingPriceMessageCode -> EncodeExpandedOpeningClosingPriceMessage(message.body)
      [] message.tag = FractionalEndOfDaySummaryMessageCode -> EncodeFractionalEndOfDaySummaryMessage(message.body)
      [] message.tag = ExpandedFractionalEndOfDaySummaryMessageCode -> EncodeExpandedFractionalEndOfDaySummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ClearQuoteMessageCode -> DecodeClearQuoteMessage(bytes)
              [] tag = ExpandedClearQuoteMessageCode -> DecodeExpandedClearQuoteMessage(bytes)
              [] tag = FractionalSymbolSummaryMessageCode -> DecodeFractionalSymbolSummaryMessage(bytes)
              [] tag = ExpandedFractionalSymbolSummaryMessageCode -> DecodeExpandedFractionalSymbolSummaryMessage(bytes)
              [] tag = BestQuoteUpdateMessageCode -> DecodeBestQuoteUpdateMessage(bytes)
              [] tag = ExpandedBestQuoteUpdateMessageCode -> DecodeExpandedBestQuoteUpdateMessage(bytes)
              [] tag = CboeMarketStatusMessageCode -> DecodeCboeMarketStatusMessage(bytes)
              [] tag = AdapMessageCode -> DecodeAdapMessage(bytes)
              [] tag = ExpandedAdapMessageCode -> DecodeExpandedAdapMessage(bytes)
              [] tag = RpiMessageCode -> DecodeRpiMessage(bytes)
              [] tag = FractionalTradeMessageCode -> DecodeFractionalTradeMessage(bytes)
              [] tag = ExpandedFractionalTradeMessageCode -> DecodeExpandedFractionalTradeMessage(bytes)
              [] tag = FractionalTradeBreakMessageCode -> DecodeFractionalTradeBreakMessage(bytes)
              [] tag = ExpandedFractionalTradeBreakMessageCode -> DecodeExpandedFractionalTradeBreakMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = ExpandedTradingStatusMessageCode -> DecodeExpandedTradingStatusMessage(bytes)
              [] tag = OpeningClosingPriceMessageCode -> DecodeOpeningClosingPriceMessage(bytes)
              [] tag = ExpandedOpeningClosingPriceMessageCode -> DecodeExpandedOpeningClosingPriceMessage(bytes)
              [] tag = FractionalEndOfDaySummaryMessageCode -> DecodeFractionalEndOfDaySummaryMessage(bytes)
              [] tag = ExpandedFractionalEndOfDaySummaryMessageCode -> DecodeExpandedFractionalEndOfDaySummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ClearQuoteMessageCode, body |-> ZeroClearQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ClearQuoteMessageCode, body |-> one] : one \in CheckedClearQuoteMessage }
        \cup { [tag |-> ExpandedClearQuoteMessageCode, body |-> one] : one \in CheckedExpandedClearQuoteMessage }
        \cup { [tag |-> FractionalSymbolSummaryMessageCode, body |-> one] : one \in CheckedFractionalSymbolSummaryMessage }
        \cup { [tag |-> ExpandedFractionalSymbolSummaryMessageCode, body |-> one] : one \in CheckedExpandedFractionalSymbolSummaryMessage }
        \cup { [tag |-> BestQuoteUpdateMessageCode, body |-> one] : one \in CheckedBestQuoteUpdateMessage }
        \cup { [tag |-> ExpandedBestQuoteUpdateMessageCode, body |-> one] : one \in CheckedExpandedBestQuoteUpdateMessage }
        \cup { [tag |-> CboeMarketStatusMessageCode, body |-> one] : one \in CheckedCboeMarketStatusMessage }
        \cup { [tag |-> AdapMessageCode, body |-> one] : one \in CheckedAdapMessage }
        \cup { [tag |-> ExpandedAdapMessageCode, body |-> one] : one \in CheckedExpandedAdapMessage }
        \cup { [tag |-> RpiMessageCode, body |-> one] : one \in CheckedRpiMessage }
        \cup { [tag |-> FractionalTradeMessageCode, body |-> one] : one \in CheckedFractionalTradeMessage }
        \cup { [tag |-> ExpandedFractionalTradeMessageCode, body |-> one] : one \in CheckedExpandedFractionalTradeMessage }
        \cup { [tag |-> FractionalTradeBreakMessageCode, body |-> one] : one \in CheckedFractionalTradeBreakMessage }
        \cup { [tag |-> ExpandedFractionalTradeBreakMessageCode, body |-> one] : one \in CheckedExpandedFractionalTradeBreakMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> ExpandedTradingStatusMessageCode, body |-> one] : one \in CheckedExpandedTradingStatusMessage }
        \cup { [tag |-> OpeningClosingPriceMessageCode, body |-> one] : one \in CheckedOpeningClosingPriceMessage }
        \cup { [tag |-> ExpandedOpeningClosingPriceMessageCode, body |-> one] : one \in CheckedExpandedOpeningClosingPriceMessage }
        \cup { [tag |-> FractionalEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedFractionalEndOfDaySummaryMessage }
        \cup { [tag |-> ExpandedFractionalEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedExpandedFractionalEndOfDaySummaryMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> ClearQuoteMessageCode, body |-> ZeroClearQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedClearQuoteMessageCode, body |-> ZeroExpandedClearQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FractionalSymbolSummaryMessageCode, body |-> ZeroFractionalSymbolSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedFractionalSymbolSummaryMessageCode, body |-> ZeroExpandedFractionalSymbolSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BestQuoteUpdateMessageCode, body |-> ZeroBestQuoteUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedBestQuoteUpdateMessageCode, body |-> ZeroExpandedBestQuoteUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CboeMarketStatusMessageCode, body |-> ZeroCboeMarketStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdapMessageCode, body |-> ZeroAdapMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedAdapMessageCode, body |-> ZeroExpandedAdapMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RpiMessageCode, body |-> ZeroRpiMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FractionalTradeMessageCode, body |-> ZeroFractionalTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedFractionalTradeMessageCode, body |-> ZeroExpandedFractionalTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FractionalTradeBreakMessageCode, body |-> ZeroFractionalTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedFractionalTradeBreakMessageCode, body |-> ZeroExpandedFractionalTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedTradingStatusMessageCode, body |-> ZeroExpandedTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpeningClosingPriceMessageCode, body |-> ZeroOpeningClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedOpeningClosingPriceMessageCode, body |-> ZeroExpandedOpeningClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FractionalEndOfDaySummaryMessageCode, body |-> ZeroFractionalEndOfDaySummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpandedFractionalEndOfDaySummaryMessageCode, body |-> ZeroExpandedFractionalEndOfDaySummaryMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Clear Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearQuoteMessage ==
    \A message \in CheckedClearQuoteMessage :
        LET read == DecodeClearQuoteMessage(EncodeClearQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Clear Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedClearQuoteMessage ==
    \A message \in CheckedExpandedClearQuoteMessage :
        LET read == DecodeExpandedClearQuoteMessage(EncodeExpandedClearQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Symbol Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalSymbolSummaryMessage ==
    \A message \in CheckedFractionalSymbolSummaryMessage :
        LET read == DecodeFractionalSymbolSummaryMessage(EncodeFractionalSymbolSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Fractional Symbol Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedFractionalSymbolSummaryMessage ==
    \A message \in CheckedExpandedFractionalSymbolSummaryMessage :
        LET read == DecodeExpandedFractionalSymbolSummaryMessage(EncodeExpandedFractionalSymbolSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestQuoteUpdateMessage ==
    \A message \in CheckedBestQuoteUpdateMessage :
        LET read == DecodeBestQuoteUpdateMessage(EncodeBestQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Best Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedBestQuoteUpdateMessage ==
    \A message \in CheckedExpandedBestQuoteUpdateMessage :
        LET read == DecodeExpandedBestQuoteUpdateMessage(EncodeExpandedBestQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cboe Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCboeMarketStatusMessage ==
    \A message \in CheckedCboeMarketStatusMessage :
        LET read == DecodeCboeMarketStatusMessage(EncodeCboeMarketStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Update Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripShortUpdateAdapBlock ==
    \A message \in CheckedShortUpdateAdapBlock :
        LET read == DecodeShortUpdateAdapBlock(EncodeShortUpdateAdapBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Update Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripLongUpdateAdapBlock ==
    \A message \in CheckedLongUpdateAdapBlock :
        LET read == DecodeLongUpdateAdapBlock(EncodeLongUpdateAdapBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Adap Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdapMessage ==
    \A message \in CheckedAdapMessage :
        LET read == DecodeAdapMessage(EncodeAdapMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Update Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripShortUpdateAdapBlock2 ==
    \A message \in CheckedShortUpdateAdapBlock2 :
        LET read == DecodeShortUpdateAdapBlock2(EncodeShortUpdateAdapBlock2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Update Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripLongUpdateAdapBlock2 ==
    \A message \in CheckedLongUpdateAdapBlock2 :
        LET read == DecodeLongUpdateAdapBlock2(EncodeLongUpdateAdapBlock2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Adap Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedAdapMessage ==
    \A message \in CheckedExpandedAdapMessage :
        LET read == DecodeExpandedAdapMessage(EncodeExpandedAdapMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rpi Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRpiMessage ==
    \A message \in CheckedRpiMessage :
        LET read == DecodeRpiMessage(EncodeRpiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeMessage ==
    \A message \in CheckedFractionalTradeMessage :
        LET read == DecodeFractionalTradeMessage(EncodeFractionalTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Fractional Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedFractionalTradeMessage ==
    \A message \in CheckedExpandedFractionalTradeMessage :
        LET read == DecodeExpandedFractionalTradeMessage(EncodeExpandedFractionalTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeBreakMessage ==
    \A message \in CheckedFractionalTradeBreakMessage :
        LET read == DecodeFractionalTradeBreakMessage(EncodeFractionalTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Fractional Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedFractionalTradeBreakMessage ==
    \A message \in CheckedExpandedFractionalTradeBreakMessage :
        LET read == DecodeExpandedFractionalTradeBreakMessage(EncodeExpandedFractionalTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedTradingStatusMessage ==
    \A message \in CheckedExpandedTradingStatusMessage :
        LET read == DecodeExpandedTradingStatusMessage(EncodeExpandedTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningClosingPriceMessage ==
    \A message \in CheckedOpeningClosingPriceMessage :
        LET read == DecodeOpeningClosingPriceMessage(EncodeOpeningClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Opening Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedOpeningClosingPriceMessage ==
    \A message \in CheckedExpandedOpeningClosingPriceMessage :
        LET read == DecodeExpandedOpeningClosingPriceMessage(EncodeExpandedOpeningClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalEndOfDaySummaryMessage ==
    \A message \in CheckedFractionalEndOfDaySummaryMessage :
        LET read == DecodeFractionalEndOfDaySummaryMessage(EncodeFractionalEndOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Fractional End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedFractionalEndOfDaySummaryMessage ==
    \A message \in CheckedExpandedFractionalEndOfDaySummaryMessage :
        LET read == DecodeExpandedFractionalEndOfDaySummaryMessage(EncodeExpandedFractionalEndOfDaySummaryMessage(message))
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

(* A Adap Update is selected by the Adap Block Size it is written under *)
SelectsAdapUpdate ==
    \A message \in CheckedAdapUpdate :
        LET sent == EncodeAdapUpdate(message)
            read == DecodeAdapUpdate(message.tag, CountAdapUpdate(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Adap Update is selected by the Adap Block Size it is written under *)
SelectsAdapUpdate2 ==
    \A message \in CheckedAdapUpdate2 :
        LET sent == EncodeAdapUpdate2(message)
            read == DecodeAdapUpdate2(message.tag, CountAdapUpdate2(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
