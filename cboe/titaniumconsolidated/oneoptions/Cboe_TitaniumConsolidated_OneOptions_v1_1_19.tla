----------- MODULE Cboe_TitaniumConsolidated_OneOptions_v1_1_19 ------------
(***************************************************************************)
(* Chicago Board Options Exchange One Options v1.1.19                      *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
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
(* Short Symbol Summary Message: 41 bytes                                  *)
(***************************************************************************)

ShortSymbolSummaryMessage ==
    [ lastUpdateTimestamp               : Sample(8),
      symbol                            : Sample(8),
      cboeCumulativeExecutedVolumeShort : Sample(4),
      consolidatedBestBidPriceShort     : Sample(4),
      consolidatedBestBidQuantityShort  : Sample(4),
      consolidatedBestAskPriceShort     : Sample(4),
      consolidatedBestAskQuantityShort  : Sample(4),
      reserved5                         : Sample(5) ]

EncodeShortSymbolSummaryMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbol
        \o message.cboeCumulativeExecutedVolumeShort
        \o message.consolidatedBestBidPriceShort
        \o message.consolidatedBestBidQuantityShort
        \o message.consolidatedBestAskPriceShort
        \o message.consolidatedBestAskQuantityShort
        \o message.reserved5

DecodeShortSymbolSummaryMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolumeShort == ReadBytes(symbol.rest, 4) IN IF ~cboeCumulativeExecutedVolumeShort.ok THEN Fail ELSE
    LET consolidatedBestBidPriceShort == ReadBytes(cboeCumulativeExecutedVolumeShort.rest, 4) IN IF ~consolidatedBestBidPriceShort.ok THEN Fail ELSE
    LET consolidatedBestBidQuantityShort == ReadBytes(consolidatedBestBidPriceShort.rest, 4) IN IF ~consolidatedBestBidQuantityShort.ok THEN Fail ELSE
    LET consolidatedBestAskPriceShort == ReadBytes(consolidatedBestBidQuantityShort.rest, 4) IN IF ~consolidatedBestAskPriceShort.ok THEN Fail ELSE
    LET consolidatedBestAskQuantityShort == ReadBytes(consolidatedBestAskPriceShort.rest, 4) IN IF ~consolidatedBestAskQuantityShort.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(consolidatedBestAskQuantityShort.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp               |-> lastUpdateTimestamp.value,
         symbol                            |-> symbol.value,
         cboeCumulativeExecutedVolumeShort |-> cboeCumulativeExecutedVolumeShort.value,
         consolidatedBestBidPriceShort     |-> consolidatedBestBidPriceShort.value,
         consolidatedBestBidQuantityShort  |-> consolidatedBestBidQuantityShort.value,
         consolidatedBestAskPriceShort     |-> consolidatedBestAskPriceShort.value,
         consolidatedBestAskQuantityShort  |-> consolidatedBestAskQuantityShort.value,
         reserved5                         |-> reserved5.value ], reserved5.rest)

ZeroShortSymbolSummaryMessage ==
    [ lastUpdateTimestamp               |-> [i \in 1 .. 8 |-> 0],
      symbol                            |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolumeShort |-> [i \in 1 .. 4 |-> 0],
      consolidatedBestBidPriceShort     |-> [i \in 1 .. 4 |-> 0],
      consolidatedBestBidQuantityShort  |-> [i \in 1 .. 4 |-> 0],
      consolidatedBestAskPriceShort     |-> [i \in 1 .. 4 |-> 0],
      consolidatedBestAskQuantityShort  |-> [i \in 1 .. 4 |-> 0],
      reserved5                         |-> [i \in 1 .. 5 |-> 0] ]

(* Short Symbol Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedShortSymbolSummaryMessage ==
    { ZeroShortSymbolSummaryMessage }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.cboeCumulativeExecutedVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.consolidatedBestBidPriceShort = one] : one \in Sample(4) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.consolidatedBestBidQuantityShort = one] : one \in Sample(4) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.consolidatedBestAskPriceShort = one] : one \in Sample(4) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.consolidatedBestAskQuantityShort = one] : one \in Sample(4) }
        \cup { [ZeroShortSymbolSummaryMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Long Symbol Summary Message: 65 bytes                                   *)
(***************************************************************************)

LongSymbolSummaryMessage ==
    [ lastUpdateTimestamp              : Sample(8),
      symbol                           : Sample(8),
      cboeCumulativeExecutedVolumeLong : Sample(8),
      consolidatedBestBidPriceLong     : Sample(8),
      consolidatedBestBidQuantityLong  : Sample(8),
      consolidatedBestAskPriceLong     : Sample(8),
      consolidatedBestAskQuantityLong  : Sample(8),
      reserved9                        : Sample(9) ]

EncodeLongSymbolSummaryMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbol
        \o message.cboeCumulativeExecutedVolumeLong
        \o message.consolidatedBestBidPriceLong
        \o message.consolidatedBestBidQuantityLong
        \o message.consolidatedBestAskPriceLong
        \o message.consolidatedBestAskQuantityLong
        \o message.reserved9

DecodeLongSymbolSummaryMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolumeLong == ReadBytes(symbol.rest, 8) IN IF ~cboeCumulativeExecutedVolumeLong.ok THEN Fail ELSE
    LET consolidatedBestBidPriceLong == ReadBytes(cboeCumulativeExecutedVolumeLong.rest, 8) IN IF ~consolidatedBestBidPriceLong.ok THEN Fail ELSE
    LET consolidatedBestBidQuantityLong == ReadBytes(consolidatedBestBidPriceLong.rest, 8) IN IF ~consolidatedBestBidQuantityLong.ok THEN Fail ELSE
    LET consolidatedBestAskPriceLong == ReadBytes(consolidatedBestBidQuantityLong.rest, 8) IN IF ~consolidatedBestAskPriceLong.ok THEN Fail ELSE
    LET consolidatedBestAskQuantityLong == ReadBytes(consolidatedBestAskPriceLong.rest, 8) IN IF ~consolidatedBestAskQuantityLong.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(consolidatedBestAskQuantityLong.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp              |-> lastUpdateTimestamp.value,
         symbol                           |-> symbol.value,
         cboeCumulativeExecutedVolumeLong |-> cboeCumulativeExecutedVolumeLong.value,
         consolidatedBestBidPriceLong     |-> consolidatedBestBidPriceLong.value,
         consolidatedBestBidQuantityLong  |-> consolidatedBestBidQuantityLong.value,
         consolidatedBestAskPriceLong     |-> consolidatedBestAskPriceLong.value,
         consolidatedBestAskQuantityLong  |-> consolidatedBestAskQuantityLong.value,
         reserved9                        |-> reserved9.value ], reserved9.rest)

ZeroLongSymbolSummaryMessage ==
    [ lastUpdateTimestamp              |-> [i \in 1 .. 8 |-> 0],
      symbol                           |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolumeLong |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestBidPriceLong     |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestBidQuantityLong  |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestAskPriceLong     |-> [i \in 1 .. 8 |-> 0],
      consolidatedBestAskQuantityLong  |-> [i \in 1 .. 8 |-> 0],
      reserved9                        |-> [i \in 1 .. 9 |-> 0] ]

(* Long Symbol Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolSummaryMessage ==
    { ZeroLongSymbolSummaryMessage }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.cboeCumulativeExecutedVolumeLong = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.consolidatedBestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.consolidatedBestBidQuantityLong = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.consolidatedBestAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.consolidatedBestAskQuantityLong = one] : one \in Sample(8) }
        \cup { [ZeroLongSymbolSummaryMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }

(***************************************************************************)
(* Best Quote Update Message: 33 bytes                                     *)
(***************************************************************************)

BestQuoteUpdateMessage ==
    [ lastUpdateTimestamp        : Sample(8),
      symbol                     : Sample(8),
      sideIndicator              : Sample(1),
      consolidatedBestQuotePrice : Sample(8),
      consolidatedQuoteQuantity  : Sample(8) ]

EncodeBestQuoteUpdateMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbol
        \o message.sideIndicator
        \o message.consolidatedBestQuotePrice
        \o message.consolidatedQuoteQuantity

DecodeBestQuoteUpdateMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(symbol.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET consolidatedBestQuotePrice == ReadBytes(sideIndicator.rest, 8) IN IF ~consolidatedBestQuotePrice.ok THEN Fail ELSE
    LET consolidatedQuoteQuantity == ReadBytes(consolidatedBestQuotePrice.rest, 8) IN IF ~consolidatedQuoteQuantity.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp        |-> lastUpdateTimestamp.value,
         symbol                     |-> symbol.value,
         sideIndicator              |-> sideIndicator.value,
         consolidatedBestQuotePrice |-> consolidatedBestQuotePrice.value,
         consolidatedQuoteQuantity  |-> consolidatedQuoteQuantity.value ], consolidatedQuoteQuantity.rest)

ZeroBestQuoteUpdateMessage ==
    [ lastUpdateTimestamp        |-> [i \in 1 .. 8 |-> 0],
      symbol                     |-> [i \in 1 .. 8 |-> 0],
      sideIndicator              |-> [i \in 1 .. 1 |-> 0],
      consolidatedBestQuotePrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedQuoteQuantity  |-> [i \in 1 .. 8 |-> 0] ]

(* Best Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedBestQuoteUpdateMessage ==
    { ZeroBestQuoteUpdateMessage }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.consolidatedBestQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteUpdateMessage EXCEPT !.consolidatedQuoteQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Cboe Market Status Message: 11 bytes                                    *)
(***************************************************************************)

CboeMarketStatusMessage ==
    [ timestamp    : Sample(8),
      marketCenter : Sample(1),
      marketStatus : Sample(1),
      reserved1    : Sample(1) ]

EncodeCboeMarketStatusMessage(message) ==
    message.timestamp
        \o message.marketCenter
        \o message.marketStatus
        \o message.reserved1

DecodeCboeMarketStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(timestamp.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketStatus == ReadBytes(marketCenter.rest, 1) IN IF ~marketStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(marketStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         marketCenter |-> marketCenter.value,
         marketStatus |-> marketStatus.value,
         reserved1    |-> reserved1.value ], reserved1.rest)

ZeroCboeMarketStatusMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      marketCenter |-> [i \in 1 .. 1 |-> 0],
      marketStatus |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0] ]

(* Cboe Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedCboeMarketStatusMessage ==
    { ZeroCboeMarketStatusMessage }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.marketStatus = one] : one \in Sample(1) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 58 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ transactionTime                  : Sample(8),
      symbol                           : Sample(8),
      marketCenter                     : Sample(1),
      marketCenterExecutionId          : Sample(8),
      lastPrice                        : Sample(8),
      lastQuantity                     : Sample(8),
      cboeCumulativeExecutedVolumeLong : Sample(8),
      tradeCondition                   : Sample(1),
      reserved8                        : Sample(8) ]

EncodeTradeMessage(message) ==
    message.transactionTime
        \o message.symbol
        \o message.marketCenter
        \o message.marketCenterExecutionId
        \o message.lastPrice
        \o message.lastQuantity
        \o message.cboeCumulativeExecutedVolumeLong
        \o message.tradeCondition
        \o message.reserved8

DecodeTradeMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(transactionTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbol.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketCenterExecutionId == ReadBytes(marketCenter.rest, 8) IN IF ~marketCenterExecutionId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(marketCenterExecutionId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastQuantity == ReadBytes(lastPrice.rest, 8) IN IF ~lastQuantity.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolumeLong == ReadBytes(lastQuantity.rest, 8) IN IF ~cboeCumulativeExecutedVolumeLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(cboeCumulativeExecutedVolumeLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(tradeCondition.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ transactionTime                  |-> transactionTime.value,
         symbol                           |-> symbol.value,
         marketCenter                     |-> marketCenter.value,
         marketCenterExecutionId          |-> marketCenterExecutionId.value,
         lastPrice                        |-> lastPrice.value,
         lastQuantity                     |-> lastQuantity.value,
         cboeCumulativeExecutedVolumeLong |-> cboeCumulativeExecutedVolumeLong.value,
         tradeCondition                   |-> tradeCondition.value,
         reserved8                        |-> reserved8.value ], reserved8.rest)

ZeroTradeMessage ==
    [ transactionTime                  |-> [i \in 1 .. 8 |-> 0],
      symbol                           |-> [i \in 1 .. 8 |-> 0],
      marketCenter                     |-> [i \in 1 .. 1 |-> 0],
      marketCenterExecutionId          |-> [i \in 1 .. 8 |-> 0],
      lastPrice                        |-> [i \in 1 .. 8 |-> 0],
      lastQuantity                     |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolumeLong |-> [i \in 1 .. 8 |-> 0],
      tradeCondition                   |-> [i \in 1 .. 1 |-> 0],
      reserved8                        |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.marketCenterExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.lastQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.cboeCumulativeExecutedVolumeLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Break Message: 42 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ transactionTime                  : Sample(8),
      symbol                           : Sample(8),
      marketCenter                     : Sample(1),
      marketCenterExecutionId          : Sample(8),
      cboeCumulativeExecutedVolumeLong : Sample(8),
      reserved9                        : Sample(9) ]

EncodeTradeBreakMessage(message) ==
    message.transactionTime
        \o message.symbol
        \o message.marketCenter
        \o message.marketCenterExecutionId
        \o message.cboeCumulativeExecutedVolumeLong
        \o message.reserved9

DecodeTradeBreakMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(transactionTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbol.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET marketCenterExecutionId == ReadBytes(marketCenter.rest, 8) IN IF ~marketCenterExecutionId.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolumeLong == ReadBytes(marketCenterExecutionId.rest, 8) IN IF ~cboeCumulativeExecutedVolumeLong.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(cboeCumulativeExecutedVolumeLong.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    Ok([ transactionTime                  |-> transactionTime.value,
         symbol                           |-> symbol.value,
         marketCenter                     |-> marketCenter.value,
         marketCenterExecutionId          |-> marketCenterExecutionId.value,
         cboeCumulativeExecutedVolumeLong |-> cboeCumulativeExecutedVolumeLong.value,
         reserved9                        |-> reserved9.value ], reserved9.rest)

ZeroTradeBreakMessage ==
    [ transactionTime                  |-> [i \in 1 .. 8 |-> 0],
      symbol                           |-> [i \in 1 .. 8 |-> 0],
      marketCenter                     |-> [i \in 1 .. 1 |-> 0],
      marketCenterExecutionId          |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolumeLong |-> [i \in 1 .. 8 |-> 0],
      reserved9                        |-> [i \in 1 .. 9 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.marketCenterExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.cboeCumulativeExecutedVolumeLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }

(***************************************************************************)
(* Trading Status Message: 19 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timestamp    : Sample(8),
      symbol       : Sample(8),
      marketCenter : Sample(1),
      haltStatus   : Sample(1),
      reserved1    : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.marketCenter
        \o message.haltStatus
        \o message.reserved1

DecodeTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET marketCenter == ReadBytes(symbol.rest, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET haltStatus == ReadBytes(marketCenter.rest, 1) IN IF ~haltStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(haltStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         symbol       |-> symbol.value,
         marketCenter |-> marketCenter.value,
         haltStatus   |-> haltStatus.value,
         reserved1    |-> reserved1.value ], reserved1.rest)

ZeroTradingStatusMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 8 |-> 0],
      marketCenter |-> [i \in 1 .. 1 |-> 0],
      haltStatus   |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

ShortSymbolSummaryMessageCode == 164  \* 0xa4
LongSymbolSummaryMessageCode == 163  \* 0xa3
BestQuoteUpdateMessageCode == 165  \* 0xa5
CboeMarketStatusMessageCode == 166  \* 0xa6
TradeMessageCode == 169  \* 0xa9
TradeBreakMessageCode == 170  \* 0xaa
TradingStatusMessageCode == 171  \* 0xab

Payload ==
    [ tag : {ShortSymbolSummaryMessageCode}, body : ShortSymbolSummaryMessage ]
        \cup [ tag : {LongSymbolSummaryMessageCode}, body : LongSymbolSummaryMessage ]
        \cup [ tag : {BestQuoteUpdateMessageCode}, body : BestQuoteUpdateMessage ]
        \cup [ tag : {CboeMarketStatusMessageCode}, body : CboeMarketStatusMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = ShortSymbolSummaryMessageCode -> EncodeShortSymbolSummaryMessage(message.body)
      [] message.tag = LongSymbolSummaryMessageCode -> EncodeLongSymbolSummaryMessage(message.body)
      [] message.tag = BestQuoteUpdateMessageCode -> EncodeBestQuoteUpdateMessage(message.body)
      [] message.tag = CboeMarketStatusMessageCode -> EncodeCboeMarketStatusMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ShortSymbolSummaryMessageCode -> DecodeShortSymbolSummaryMessage(bytes)
              [] tag = LongSymbolSummaryMessageCode -> DecodeLongSymbolSummaryMessage(bytes)
              [] tag = BestQuoteUpdateMessageCode -> DecodeBestQuoteUpdateMessage(bytes)
              [] tag = CboeMarketStatusMessageCode -> DecodeCboeMarketStatusMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ShortSymbolSummaryMessageCode, body |-> ZeroShortSymbolSummaryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ShortSymbolSummaryMessageCode, body |-> one] : one \in CheckedShortSymbolSummaryMessage }
        \cup { [tag |-> LongSymbolSummaryMessageCode, body |-> one] : one \in CheckedLongSymbolSummaryMessage }
        \cup { [tag |-> BestQuoteUpdateMessageCode, body |-> one] : one \in CheckedBestQuoteUpdateMessage }
        \cup { [tag |-> CboeMarketStatusMessageCode, body |-> one] : one \in CheckedCboeMarketStatusMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> ShortSymbolSummaryMessageCode, body |-> ZeroShortSymbolSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongSymbolSummaryMessageCode, body |-> ZeroLongSymbolSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BestQuoteUpdateMessageCode, body |-> ZeroBestQuoteUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CboeMarketStatusMessageCode, body |-> ZeroCboeMarketStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]] }

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
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
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

(* Every Short Symbol Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSymbolSummaryMessage ==
    \A message \in CheckedShortSymbolSummaryMessage :
        LET read == DecodeShortSymbolSummaryMessage(EncodeShortSymbolSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolSummaryMessage ==
    \A message \in CheckedLongSymbolSummaryMessage :
        LET read == DecodeLongSymbolSummaryMessage(EncodeLongSymbolSummaryMessage(message))
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

(* Every Cboe Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCboeMarketStatusMessage ==
    \A message \in CheckedCboeMarketStatusMessage :
        LET read == DecodeCboeMarketStatusMessage(EncodeCboeMarketStatusMessage(message))
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

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
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

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
