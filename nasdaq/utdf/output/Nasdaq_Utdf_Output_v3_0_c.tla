--------------------- MODULE Nasdaq_Utdf_Output_v3_0_c ---------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Output v3.0.c                                                  *)
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
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
(* Trade Report Message Shortform Message: 58 bytes                        *)
(***************************************************************************)

TradeReportMessageShortformMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolShort                      : Sample(5),
      tradeId                          : Sample(8),
      tradePriceShort                  : Sample(2),
      tradeVolumeShort                 : Sample(2),
      saleCondition                    : Sample(4),
      tradeThroughExemptFlag           : Sample(1),
      consolidatedPriceChangeIndicator : Sample(1),
      participantPriceChangeIndicator  : Sample(1) ]

EncodeTradeReportMessageShortformMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolShort
        \o message.tradeId
        \o message.tradePriceShort
        \o message.tradeVolumeShort
        \o message.saleCondition
        \o message.tradeThroughExemptFlag
        \o message.consolidatedPriceChangeIndicator
        \o message.participantPriceChangeIndicator

DecodeTradeReportMessageShortformMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timestamp2.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolShort.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceShort == ReadBytes(tradeId.rest, 2) IN IF ~tradePriceShort.ok THEN Fail ELSE
    LET tradeVolumeShort == ReadBytes(tradePriceShort.rest, 2) IN IF ~tradeVolumeShort.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(tradeVolumeShort.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(tradeThroughExemptFlag.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET participantPriceChangeIndicator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~participantPriceChangeIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolShort                      |-> symbolShort.value,
         tradeId                          |-> tradeId.value,
         tradePriceShort                  |-> tradePriceShort.value,
         tradeVolumeShort                 |-> tradeVolumeShort.value,
         saleCondition                    |-> saleCondition.value,
         tradeThroughExemptFlag           |-> tradeThroughExemptFlag.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         participantPriceChangeIndicator  |-> participantPriceChangeIndicator.value ], participantPriceChangeIndicator.rest)

ZeroTradeReportMessageShortformMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolShort                      |-> [i \in 1 .. 5 |-> 0],
      tradeId                          |-> [i \in 1 .. 8 |-> 0],
      tradePriceShort                  |-> [i \in 1 .. 2 |-> 0],
      tradeVolumeShort                 |-> [i \in 1 .. 2 |-> 0],
      saleCondition                    |-> [i \in 1 .. 4 |-> 0],
      tradeThroughExemptFlag           |-> [i \in 1 .. 1 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      participantPriceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message Shortform Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessageShortformMessage ==
    { ZeroTradeReportMessageShortformMessage }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.tradePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.tradeVolumeShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageShortformMessage EXCEPT !.participantPriceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message Longform Message: 74 bytes                         *)
(***************************************************************************)

TradeReportMessageLongformMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolLong                       : Sample(11),
      tradeId                          : Sample(8),
      tradePriceLong                   : Sample(8),
      tradeVolumeLong                  : Sample(4),
      saleCondition                    : Sample(4),
      tradeThroughExemptFlag           : Sample(1),
      sellersSaleDays                  : Sample(2),
      consolidatedPriceChangeIndicator : Sample(1),
      participantPriceChangeIndicator  : Sample(1) ]

EncodeTradeReportMessageLongformMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.tradePriceLong
        \o message.tradeVolumeLong
        \o message.saleCondition
        \o message.tradeThroughExemptFlag
        \o message.sellersSaleDays
        \o message.consolidatedPriceChangeIndicator
        \o message.participantPriceChangeIndicator

DecodeTradeReportMessageLongformMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceLong == ReadBytes(tradeId.rest, 8) IN IF ~tradePriceLong.ok THEN Fail ELSE
    LET tradeVolumeLong == ReadBytes(tradePriceLong.rest, 4) IN IF ~tradeVolumeLong.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(tradeVolumeLong.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeThroughExemptFlag.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET participantPriceChangeIndicator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~participantPriceChangeIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolLong                       |-> symbolLong.value,
         tradeId                          |-> tradeId.value,
         tradePriceLong                   |-> tradePriceLong.value,
         tradeVolumeLong                  |-> tradeVolumeLong.value,
         saleCondition                    |-> saleCondition.value,
         tradeThroughExemptFlag           |-> tradeThroughExemptFlag.value,
         sellersSaleDays                  |-> sellersSaleDays.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         participantPriceChangeIndicator  |-> participantPriceChangeIndicator.value ], participantPriceChangeIndicator.rest)

ZeroTradeReportMessageLongformMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      tradeId                          |-> [i \in 1 .. 8 |-> 0],
      tradePriceLong                   |-> [i \in 1 .. 8 |-> 0],
      tradeVolumeLong                  |-> [i \in 1 .. 4 |-> 0],
      saleCondition                    |-> [i \in 1 .. 4 |-> 0],
      tradeThroughExemptFlag           |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays                  |-> [i \in 1 .. 2 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      participantPriceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message Longform Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessageLongformMessage ==
    { ZeroTradeReportMessageLongformMessage }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.tradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.tradeVolumeLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageLongformMessage EXCEPT !.participantPriceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Error Message: 139 bytes                                   *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolLong                       : Sample(11),
      tradeCancellationType            : Sample(1),
      originalTradeId                  : Sample(8),
      originalTradePrice               : Sample(8),
      originalVolumeShort              : Sample(4),
      originalSaleCondition            : Sample(4),
      originalTradeThroughExemptFlag   : Sample(1),
      originalSellersSaleDays          : Sample(2),
      consolidatedHighPrice            : Sample(8),
      consolidatedLowPrice             : Sample(8),
      consolidatedLastPrice            : Sample(8),
      consolidatedVolume               : Sample(8),
      consolidatedPriceChangeIndicator : Sample(1),
      consolidatedLastPriceOriginator  : Sample(1),
      marketParticipantHighPrice       : Sample(8),
      marketParticipantLowPrice        : Sample(8),
      marketParticipantLastPrice       : Sample(8),
      marketParticipantVolume          : Sample(8) ]

EncodeTradeCancelErrorMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeCancellationType
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalVolumeShort
        \o message.originalSaleCondition
        \o message.originalTradeThroughExemptFlag
        \o message.originalSellersSaleDays
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedLastPrice
        \o message.consolidatedVolume
        \o message.consolidatedPriceChangeIndicator
        \o message.consolidatedLastPriceOriginator
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice
        \o message.marketParticipantLastPrice
        \o message.marketParticipantVolume

DecodeTradeCancelErrorMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeCancellationType == ReadBytes(symbolLong.rest, 1) IN IF ~tradeCancellationType.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(tradeCancellationType.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalVolumeShort == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalVolumeShort.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(originalVolumeShort.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradeThroughExemptFlag == ReadBytes(originalSaleCondition.rest, 1) IN IF ~originalTradeThroughExemptFlag.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeThroughExemptFlag.rest, 2) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(originalSellersSaleDays.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET consolidatedLastPriceOriginator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~consolidatedLastPriceOriginator.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(consolidatedLastPriceOriginator.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    LET marketParticipantLastPrice == ReadBytes(marketParticipantLowPrice.rest, 8) IN IF ~marketParticipantLastPrice.ok THEN Fail ELSE
    LET marketParticipantVolume == ReadBytes(marketParticipantLastPrice.rest, 8) IN IF ~marketParticipantVolume.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolLong                       |-> symbolLong.value,
         tradeCancellationType            |-> tradeCancellationType.value,
         originalTradeId                  |-> originalTradeId.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalVolumeShort              |-> originalVolumeShort.value,
         originalSaleCondition            |-> originalSaleCondition.value,
         originalTradeThroughExemptFlag   |-> originalTradeThroughExemptFlag.value,
         originalSellersSaleDays          |-> originalSellersSaleDays.value,
         consolidatedHighPrice            |-> consolidatedHighPrice.value,
         consolidatedLowPrice             |-> consolidatedLowPrice.value,
         consolidatedLastPrice            |-> consolidatedLastPrice.value,
         consolidatedVolume               |-> consolidatedVolume.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         consolidatedLastPriceOriginator  |-> consolidatedLastPriceOriginator.value,
         marketParticipantHighPrice       |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice        |-> marketParticipantLowPrice.value,
         marketParticipantLastPrice       |-> marketParticipantLastPrice.value,
         marketParticipantVolume          |-> marketParticipantVolume.value ], marketParticipantVolume.rest)

ZeroTradeCancelErrorMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      tradeCancellationType            |-> [i \in 1 .. 1 |-> 0],
      originalTradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 8 |-> 0],
      originalVolumeShort              |-> [i \in 1 .. 4 |-> 0],
      originalSaleCondition            |-> [i \in 1 .. 4 |-> 0],
      originalTradeThroughExemptFlag   |-> [i \in 1 .. 1 |-> 0],
      originalSellersSaleDays          |-> [i \in 1 .. 2 |-> 0],
      consolidatedHighPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice             |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume               |-> [i \in 1 .. 8 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPriceOriginator  |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice        |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLastPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantVolume          |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeCancellationType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLastPriceOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Correction Message: 165 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolLong                       : Sample(11),
      originalTradeId                  : Sample(8),
      originalTradePrice               : Sample(8),
      originalVolumeShort              : Sample(4),
      originalSaleCondition            : Sample(4),
      originalTradeThroughExemptFlag   : Sample(1),
      originalSellersSaleDays          : Sample(2),
      correctedTradeId                 : Sample(8),
      correctedTradePrice              : Sample(8),
      correctedVolumeShort             : Sample(4),
      correctedSaleCondition           : Sample(4),
      correctedTradeThroughExemptFlag  : Sample(1),
      correctedSellersSaleDays         : Sample(2),
      consolidatedHighPrice            : Sample(8),
      consolidatedLowPrice             : Sample(8),
      consolidatedLastPrice            : Sample(8),
      consolidatedVolume               : Sample(8),
      consolidatedPriceChangeIndicator : Sample(1),
      consolidatedLastPriceOriginator  : Sample(1),
      marketParticipantHighPrice       : Sample(8),
      marketParticipantLowPrice        : Sample(8),
      marketParticipantLastPrice       : Sample(8),
      marketParticipantVolume          : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalVolumeShort
        \o message.originalSaleCondition
        \o message.originalTradeThroughExemptFlag
        \o message.originalSellersSaleDays
        \o message.correctedTradeId
        \o message.correctedTradePrice
        \o message.correctedVolumeShort
        \o message.correctedSaleCondition
        \o message.correctedTradeThroughExemptFlag
        \o message.correctedSellersSaleDays
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedLastPrice
        \o message.consolidatedVolume
        \o message.consolidatedPriceChangeIndicator
        \o message.consolidatedLastPriceOriginator
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice
        \o message.marketParticipantLastPrice
        \o message.marketParticipantVolume

DecodeTradeCorrectionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolLong.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalVolumeShort == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalVolumeShort.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(originalVolumeShort.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradeThroughExemptFlag == ReadBytes(originalSaleCondition.rest, 1) IN IF ~originalTradeThroughExemptFlag.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeThroughExemptFlag.rest, 2) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET correctedTradeId == ReadBytes(originalSellersSaleDays.rest, 8) IN IF ~correctedTradeId.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeId.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedVolumeShort == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedVolumeShort.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(correctedVolumeShort.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradeThroughExemptFlag == ReadBytes(correctedSaleCondition.rest, 1) IN IF ~correctedTradeThroughExemptFlag.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedTradeThroughExemptFlag.rest, 2) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(correctedSellersSaleDays.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET consolidatedLastPriceOriginator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~consolidatedLastPriceOriginator.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(consolidatedLastPriceOriginator.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    LET marketParticipantLastPrice == ReadBytes(marketParticipantLowPrice.rest, 8) IN IF ~marketParticipantLastPrice.ok THEN Fail ELSE
    LET marketParticipantVolume == ReadBytes(marketParticipantLastPrice.rest, 8) IN IF ~marketParticipantVolume.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolLong                       |-> symbolLong.value,
         originalTradeId                  |-> originalTradeId.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalVolumeShort              |-> originalVolumeShort.value,
         originalSaleCondition            |-> originalSaleCondition.value,
         originalTradeThroughExemptFlag   |-> originalTradeThroughExemptFlag.value,
         originalSellersSaleDays          |-> originalSellersSaleDays.value,
         correctedTradeId                 |-> correctedTradeId.value,
         correctedTradePrice              |-> correctedTradePrice.value,
         correctedVolumeShort             |-> correctedVolumeShort.value,
         correctedSaleCondition           |-> correctedSaleCondition.value,
         correctedTradeThroughExemptFlag  |-> correctedTradeThroughExemptFlag.value,
         correctedSellersSaleDays         |-> correctedSellersSaleDays.value,
         consolidatedHighPrice            |-> consolidatedHighPrice.value,
         consolidatedLowPrice             |-> consolidatedLowPrice.value,
         consolidatedLastPrice            |-> consolidatedLastPrice.value,
         consolidatedVolume               |-> consolidatedVolume.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         consolidatedLastPriceOriginator  |-> consolidatedLastPriceOriginator.value,
         marketParticipantHighPrice       |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice        |-> marketParticipantLowPrice.value,
         marketParticipantLastPrice       |-> marketParticipantLastPrice.value,
         marketParticipantVolume          |-> marketParticipantVolume.value ], marketParticipantVolume.rest)

ZeroTradeCorrectionMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      originalTradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 8 |-> 0],
      originalVolumeShort              |-> [i \in 1 .. 4 |-> 0],
      originalSaleCondition            |-> [i \in 1 .. 4 |-> 0],
      originalTradeThroughExemptFlag   |-> [i \in 1 .. 1 |-> 0],
      originalSellersSaleDays          |-> [i \in 1 .. 2 |-> 0],
      correctedTradeId                 |-> [i \in 1 .. 8 |-> 0],
      correctedTradePrice              |-> [i \in 1 .. 8 |-> 0],
      correctedVolumeShort             |-> [i \in 1 .. 4 |-> 0],
      correctedSaleCondition           |-> [i \in 1 .. 4 |-> 0],
      correctedTradeThroughExemptFlag  |-> [i \in 1 .. 1 |-> 0],
      correctedSellersSaleDays         |-> [i \in 1 .. 2 |-> 0],
      consolidatedHighPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice             |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume               |-> [i \in 1 .. 8 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPriceOriginator  |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice        |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLastPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantVolume          |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLastPriceOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Prior Day As Of Trade Message: 81 bytes                                 *)
(***************************************************************************)

PriorDayAsOfTradeMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      timestamp2             : Sample(8),
      symbolLong             : Sample(11),
      tradeId                : Sample(8),
      tradePriceLong         : Sample(8),
      tradeVolumeLong        : Sample(4),
      saleCondition          : Sample(4),
      tradeThroughExemptFlag : Sample(1),
      sellersSaleDays        : Sample(2),
      asOfAction             : Sample(1),
      timestampOfTrade       : Sample(8) ]

EncodePriorDayAsOfTradeMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.tradePriceLong
        \o message.tradeVolumeLong
        \o message.saleCondition
        \o message.tradeThroughExemptFlag
        \o message.sellersSaleDays
        \o message.asOfAction
        \o message.timestampOfTrade

DecodePriorDayAsOfTradeMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceLong == ReadBytes(tradeId.rest, 8) IN IF ~tradePriceLong.ok THEN Fail ELSE
    LET tradeVolumeLong == ReadBytes(tradePriceLong.rest, 4) IN IF ~tradeVolumeLong.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(tradeVolumeLong.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeThroughExemptFlag.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET asOfAction == ReadBytes(sellersSaleDays.rest, 1) IN IF ~asOfAction.ok THEN Fail ELSE
    LET timestampOfTrade == ReadBytes(asOfAction.rest, 8) IN IF ~timestampOfTrade.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         timestamp2             |-> timestamp2.value,
         symbolLong             |-> symbolLong.value,
         tradeId                |-> tradeId.value,
         tradePriceLong         |-> tradePriceLong.value,
         tradeVolumeLong        |-> tradeVolumeLong.value,
         saleCondition          |-> saleCondition.value,
         tradeThroughExemptFlag |-> tradeThroughExemptFlag.value,
         sellersSaleDays        |-> sellersSaleDays.value,
         asOfAction             |-> asOfAction.value,
         timestampOfTrade       |-> timestampOfTrade.value ], timestampOfTrade.rest)

ZeroPriorDayAsOfTradeMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      timestamp2             |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradeId                |-> [i \in 1 .. 8 |-> 0],
      tradePriceLong         |-> [i \in 1 .. 8 |-> 0],
      tradeVolumeLong        |-> [i \in 1 .. 4 |-> 0],
      saleCondition          |-> [i \in 1 .. 4 |-> 0],
      tradeThroughExemptFlag |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays        |-> [i \in 1 .. 2 |-> 0],
      asOfAction             |-> [i \in 1 .. 1 |-> 0],
      timestampOfTrade       |-> [i \in 1 .. 8 |-> 0] ]

(* Prior Day As Of Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayAsOfTradeMessage ==
    { ZeroPriorDayAsOfTradeMessage }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradeVolumeLong = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.asOfAction = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.timestampOfTrade = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional Trade Report Message Shortform Message: 64 bytes             *)
(***************************************************************************)

FractionalTradeReportMessageShortformMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolShort                      : Sample(5),
      tradeId                          : Sample(8),
      tradePriceShort                  : Sample(2),
      tradeVolume                      : Sample(8),
      saleCondition                    : Sample(4),
      tradeThroughExemptFlag           : Sample(1),
      consolidatedPriceChangeIndicator : Sample(1),
      participantPriceChangeIndicator  : Sample(1) ]

EncodeFractionalTradeReportMessageShortformMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolShort
        \o message.tradeId
        \o message.tradePriceShort
        \o message.tradeVolume
        \o message.saleCondition
        \o message.tradeThroughExemptFlag
        \o message.consolidatedPriceChangeIndicator
        \o message.participantPriceChangeIndicator

DecodeFractionalTradeReportMessageShortformMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timestamp2.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolShort.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceShort == ReadBytes(tradeId.rest, 2) IN IF ~tradePriceShort.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePriceShort.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(tradeVolume.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(tradeThroughExemptFlag.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET participantPriceChangeIndicator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~participantPriceChangeIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolShort                      |-> symbolShort.value,
         tradeId                          |-> tradeId.value,
         tradePriceShort                  |-> tradePriceShort.value,
         tradeVolume                      |-> tradeVolume.value,
         saleCondition                    |-> saleCondition.value,
         tradeThroughExemptFlag           |-> tradeThroughExemptFlag.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         participantPriceChangeIndicator  |-> participantPriceChangeIndicator.value ], participantPriceChangeIndicator.rest)

ZeroFractionalTradeReportMessageShortformMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolShort                      |-> [i \in 1 .. 5 |-> 0],
      tradeId                          |-> [i \in 1 .. 8 |-> 0],
      tradePriceShort                  |-> [i \in 1 .. 2 |-> 0],
      tradeVolume                      |-> [i \in 1 .. 8 |-> 0],
      saleCondition                    |-> [i \in 1 .. 4 |-> 0],
      tradeThroughExemptFlag           |-> [i \in 1 .. 1 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      participantPriceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Trade Report Message Shortform Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeReportMessageShortformMessage ==
    { ZeroFractionalTradeReportMessageShortformMessage }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.tradePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageShortformMessage EXCEPT !.participantPriceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Trade Report Message Longform Message: 78 bytes              *)
(***************************************************************************)

FractionalTradeReportMessageLongformMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolLong                       : Sample(11),
      tradeId                          : Sample(8),
      tradePriceLong                   : Sample(8),
      tradeVolume                      : Sample(8),
      saleCondition                    : Sample(4),
      tradeThroughExemptFlag           : Sample(1),
      sellersSaleDays                  : Sample(2),
      consolidatedPriceChangeIndicator : Sample(1),
      participantPriceChangeIndicator  : Sample(1) ]

EncodeFractionalTradeReportMessageLongformMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.tradePriceLong
        \o message.tradeVolume
        \o message.saleCondition
        \o message.tradeThroughExemptFlag
        \o message.sellersSaleDays
        \o message.consolidatedPriceChangeIndicator
        \o message.participantPriceChangeIndicator

DecodeFractionalTradeReportMessageLongformMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceLong == ReadBytes(tradeId.rest, 8) IN IF ~tradePriceLong.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePriceLong.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(tradeVolume.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeThroughExemptFlag.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET participantPriceChangeIndicator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~participantPriceChangeIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolLong                       |-> symbolLong.value,
         tradeId                          |-> tradeId.value,
         tradePriceLong                   |-> tradePriceLong.value,
         tradeVolume                      |-> tradeVolume.value,
         saleCondition                    |-> saleCondition.value,
         tradeThroughExemptFlag           |-> tradeThroughExemptFlag.value,
         sellersSaleDays                  |-> sellersSaleDays.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         participantPriceChangeIndicator  |-> participantPriceChangeIndicator.value ], participantPriceChangeIndicator.rest)

ZeroFractionalTradeReportMessageLongformMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      tradeId                          |-> [i \in 1 .. 8 |-> 0],
      tradePriceLong                   |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                      |-> [i \in 1 .. 8 |-> 0],
      saleCondition                    |-> [i \in 1 .. 4 |-> 0],
      tradeThroughExemptFlag           |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays                  |-> [i \in 1 .. 2 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      participantPriceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Trade Report Message Longform Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeReportMessageLongformMessage ==
    { ZeroFractionalTradeReportMessageLongformMessage }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.tradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeReportMessageLongformMessage EXCEPT !.participantPriceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Trade Cancel Error Message: 143 bytes                        *)
(***************************************************************************)

FractionalTradeCancelErrorMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolLong                       : Sample(11),
      tradeCancellationType            : Sample(1),
      originalTradeId                  : Sample(8),
      originalTradePrice               : Sample(8),
      originalVolumeLong               : Sample(8),
      originalSaleCondition            : Sample(4),
      originalTradeThroughExemptFlag   : Sample(1),
      originalSellersSaleDays          : Sample(2),
      consolidatedHighPrice            : Sample(8),
      consolidatedLowPrice             : Sample(8),
      consolidatedLastPrice            : Sample(8),
      consolidatedVolume               : Sample(8),
      consolidatedPriceChangeIndicator : Sample(1),
      consolidatedLastPriceOriginator  : Sample(1),
      marketParticipantHighPrice       : Sample(8),
      marketParticipantLowPrice        : Sample(8),
      marketParticipantLastPrice       : Sample(8),
      marketParticipantVolume          : Sample(8) ]

EncodeFractionalTradeCancelErrorMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeCancellationType
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalVolumeLong
        \o message.originalSaleCondition
        \o message.originalTradeThroughExemptFlag
        \o message.originalSellersSaleDays
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedLastPrice
        \o message.consolidatedVolume
        \o message.consolidatedPriceChangeIndicator
        \o message.consolidatedLastPriceOriginator
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice
        \o message.marketParticipantLastPrice
        \o message.marketParticipantVolume

DecodeFractionalTradeCancelErrorMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeCancellationType == ReadBytes(symbolLong.rest, 1) IN IF ~tradeCancellationType.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(tradeCancellationType.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalVolumeLong == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalVolumeLong.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(originalVolumeLong.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradeThroughExemptFlag == ReadBytes(originalSaleCondition.rest, 1) IN IF ~originalTradeThroughExemptFlag.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeThroughExemptFlag.rest, 2) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(originalSellersSaleDays.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET consolidatedLastPriceOriginator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~consolidatedLastPriceOriginator.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(consolidatedLastPriceOriginator.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    LET marketParticipantLastPrice == ReadBytes(marketParticipantLowPrice.rest, 8) IN IF ~marketParticipantLastPrice.ok THEN Fail ELSE
    LET marketParticipantVolume == ReadBytes(marketParticipantLastPrice.rest, 8) IN IF ~marketParticipantVolume.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolLong                       |-> symbolLong.value,
         tradeCancellationType            |-> tradeCancellationType.value,
         originalTradeId                  |-> originalTradeId.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalVolumeLong               |-> originalVolumeLong.value,
         originalSaleCondition            |-> originalSaleCondition.value,
         originalTradeThroughExemptFlag   |-> originalTradeThroughExemptFlag.value,
         originalSellersSaleDays          |-> originalSellersSaleDays.value,
         consolidatedHighPrice            |-> consolidatedHighPrice.value,
         consolidatedLowPrice             |-> consolidatedLowPrice.value,
         consolidatedLastPrice            |-> consolidatedLastPrice.value,
         consolidatedVolume               |-> consolidatedVolume.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         consolidatedLastPriceOriginator  |-> consolidatedLastPriceOriginator.value,
         marketParticipantHighPrice       |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice        |-> marketParticipantLowPrice.value,
         marketParticipantLastPrice       |-> marketParticipantLastPrice.value,
         marketParticipantVolume          |-> marketParticipantVolume.value ], marketParticipantVolume.rest)

ZeroFractionalTradeCancelErrorMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      tradeCancellationType            |-> [i \in 1 .. 1 |-> 0],
      originalTradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 8 |-> 0],
      originalVolumeLong               |-> [i \in 1 .. 8 |-> 0],
      originalSaleCondition            |-> [i \in 1 .. 4 |-> 0],
      originalTradeThroughExemptFlag   |-> [i \in 1 .. 1 |-> 0],
      originalSellersSaleDays          |-> [i \in 1 .. 2 |-> 0],
      consolidatedHighPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice             |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume               |-> [i \in 1 .. 8 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPriceOriginator  |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice        |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLastPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantVolume          |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCancelErrorMessage ==
    { ZeroFractionalTradeCancelErrorMessage }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.tradeCancellationType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalVolumeLong = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedLastPriceOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.marketParticipantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.marketParticipantVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional Trade Correction Message: 173 bytes                          *)
(***************************************************************************)

FractionalTradeCorrectionMessage ==
    [ marketCenterOriginator           : Sample(1),
      subMarketCenterId                : Sample(1),
      sipTimestamp                     : Sample(8),
      timestamp1                       : Sample(8),
      participantToken                 : Sample(8),
      timestamp2                       : Sample(8),
      symbolLong                       : Sample(11),
      originalTradeId                  : Sample(8),
      originalTradePrice               : Sample(8),
      originalVolumeLong               : Sample(8),
      originalSaleCondition            : Sample(4),
      originalTradeThroughExemptFlag   : Sample(1),
      originalSellersSaleDays          : Sample(2),
      correctedTradeId                 : Sample(8),
      correctedTradePrice              : Sample(8),
      correctedVolumeLong              : Sample(8),
      correctedSaleCondition           : Sample(4),
      correctedTradeThroughExemptFlag  : Sample(1),
      correctedSellersSaleDays         : Sample(2),
      consolidatedHighPrice            : Sample(8),
      consolidatedLowPrice             : Sample(8),
      consolidatedLastPrice            : Sample(8),
      consolidatedVolume               : Sample(8),
      consolidatedPriceChangeIndicator : Sample(1),
      consolidatedLastPriceOriginator  : Sample(1),
      marketParticipantHighPrice       : Sample(8),
      marketParticipantLowPrice        : Sample(8),
      marketParticipantLastPrice       : Sample(8),
      marketParticipantVolume          : Sample(8) ]

EncodeFractionalTradeCorrectionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalVolumeLong
        \o message.originalSaleCondition
        \o message.originalTradeThroughExemptFlag
        \o message.originalSellersSaleDays
        \o message.correctedTradeId
        \o message.correctedTradePrice
        \o message.correctedVolumeLong
        \o message.correctedSaleCondition
        \o message.correctedTradeThroughExemptFlag
        \o message.correctedSellersSaleDays
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedLastPrice
        \o message.consolidatedVolume
        \o message.consolidatedPriceChangeIndicator
        \o message.consolidatedLastPriceOriginator
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice
        \o message.marketParticipantLastPrice
        \o message.marketParticipantVolume

DecodeFractionalTradeCorrectionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolLong.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalVolumeLong == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalVolumeLong.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(originalVolumeLong.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradeThroughExemptFlag == ReadBytes(originalSaleCondition.rest, 1) IN IF ~originalTradeThroughExemptFlag.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeThroughExemptFlag.rest, 2) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET correctedTradeId == ReadBytes(originalSellersSaleDays.rest, 8) IN IF ~correctedTradeId.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeId.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedVolumeLong == ReadBytes(correctedTradePrice.rest, 8) IN IF ~correctedVolumeLong.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(correctedVolumeLong.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradeThroughExemptFlag == ReadBytes(correctedSaleCondition.rest, 1) IN IF ~correctedTradeThroughExemptFlag.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedTradeThroughExemptFlag.rest, 2) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(correctedSellersSaleDays.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET consolidatedLastPriceOriginator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~consolidatedLastPriceOriginator.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(consolidatedLastPriceOriginator.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    LET marketParticipantLastPrice == ReadBytes(marketParticipantLowPrice.rest, 8) IN IF ~marketParticipantLastPrice.ok THEN Fail ELSE
    LET marketParticipantVolume == ReadBytes(marketParticipantLastPrice.rest, 8) IN IF ~marketParticipantVolume.ok THEN Fail ELSE
    Ok([ marketCenterOriginator           |-> marketCenterOriginator.value,
         subMarketCenterId                |-> subMarketCenterId.value,
         sipTimestamp                     |-> sipTimestamp.value,
         timestamp1                       |-> timestamp1.value,
         participantToken                 |-> participantToken.value,
         timestamp2                       |-> timestamp2.value,
         symbolLong                       |-> symbolLong.value,
         originalTradeId                  |-> originalTradeId.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalVolumeLong               |-> originalVolumeLong.value,
         originalSaleCondition            |-> originalSaleCondition.value,
         originalTradeThroughExemptFlag   |-> originalTradeThroughExemptFlag.value,
         originalSellersSaleDays          |-> originalSellersSaleDays.value,
         correctedTradeId                 |-> correctedTradeId.value,
         correctedTradePrice              |-> correctedTradePrice.value,
         correctedVolumeLong              |-> correctedVolumeLong.value,
         correctedSaleCondition           |-> correctedSaleCondition.value,
         correctedTradeThroughExemptFlag  |-> correctedTradeThroughExemptFlag.value,
         correctedSellersSaleDays         |-> correctedSellersSaleDays.value,
         consolidatedHighPrice            |-> consolidatedHighPrice.value,
         consolidatedLowPrice             |-> consolidatedLowPrice.value,
         consolidatedLastPrice            |-> consolidatedLastPrice.value,
         consolidatedVolume               |-> consolidatedVolume.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         consolidatedLastPriceOriginator  |-> consolidatedLastPriceOriginator.value,
         marketParticipantHighPrice       |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice        |-> marketParticipantLowPrice.value,
         marketParticipantLastPrice       |-> marketParticipantLastPrice.value,
         marketParticipantVolume          |-> marketParticipantVolume.value ], marketParticipantVolume.rest)

ZeroFractionalTradeCorrectionMessage ==
    [ marketCenterOriginator           |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                     |-> [i \in 1 .. 8 |-> 0],
      timestamp1                       |-> [i \in 1 .. 8 |-> 0],
      participantToken                 |-> [i \in 1 .. 8 |-> 0],
      timestamp2                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      originalTradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 8 |-> 0],
      originalVolumeLong               |-> [i \in 1 .. 8 |-> 0],
      originalSaleCondition            |-> [i \in 1 .. 4 |-> 0],
      originalTradeThroughExemptFlag   |-> [i \in 1 .. 1 |-> 0],
      originalSellersSaleDays          |-> [i \in 1 .. 2 |-> 0],
      correctedTradeId                 |-> [i \in 1 .. 8 |-> 0],
      correctedTradePrice              |-> [i \in 1 .. 8 |-> 0],
      correctedVolumeLong              |-> [i \in 1 .. 8 |-> 0],
      correctedSaleCondition           |-> [i \in 1 .. 4 |-> 0],
      correctedTradeThroughExemptFlag  |-> [i \in 1 .. 1 |-> 0],
      correctedSellersSaleDays         |-> [i \in 1 .. 2 |-> 0],
      consolidatedHighPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice             |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume               |-> [i \in 1 .. 8 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPriceOriginator  |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice        |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLastPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantVolume          |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCorrectionMessage ==
    { ZeroFractionalTradeCorrectionMessage }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalVolumeLong = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedTradeId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedVolumeLong = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedLastPriceOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.marketParticipantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.marketParticipantVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional As Of Trade Message: 85 bytes                                *)
(***************************************************************************)

FractionalAsOfTradeMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      timestamp2             : Sample(8),
      symbolLong             : Sample(11),
      tradeId                : Sample(8),
      tradePriceLong         : Sample(8),
      tradeVolume            : Sample(8),
      saleCondition          : Sample(4),
      tradeThroughExemptFlag : Sample(1),
      sellersSaleDays        : Sample(2),
      asOfAction             : Sample(1),
      timestampOfTrade       : Sample(8) ]

EncodeFractionalAsOfTradeMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.tradePriceLong
        \o message.tradeVolume
        \o message.saleCondition
        \o message.tradeThroughExemptFlag
        \o message.sellersSaleDays
        \o message.asOfAction
        \o message.timestampOfTrade

DecodeFractionalAsOfTradeMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceLong == ReadBytes(tradeId.rest, 8) IN IF ~tradePriceLong.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePriceLong.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(tradeVolume.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeThroughExemptFlag.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET asOfAction == ReadBytes(sellersSaleDays.rest, 1) IN IF ~asOfAction.ok THEN Fail ELSE
    LET timestampOfTrade == ReadBytes(asOfAction.rest, 8) IN IF ~timestampOfTrade.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         timestamp2             |-> timestamp2.value,
         symbolLong             |-> symbolLong.value,
         tradeId                |-> tradeId.value,
         tradePriceLong         |-> tradePriceLong.value,
         tradeVolume            |-> tradeVolume.value,
         saleCondition          |-> saleCondition.value,
         tradeThroughExemptFlag |-> tradeThroughExemptFlag.value,
         sellersSaleDays        |-> sellersSaleDays.value,
         asOfAction             |-> asOfAction.value,
         timestampOfTrade       |-> timestampOfTrade.value ], timestampOfTrade.rest)

ZeroFractionalAsOfTradeMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      timestamp2             |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradeId                |-> [i \in 1 .. 8 |-> 0],
      tradePriceLong         |-> [i \in 1 .. 8 |-> 0],
      tradeVolume            |-> [i \in 1 .. 8 |-> 0],
      saleCondition          |-> [i \in 1 .. 4 |-> 0],
      tradeThroughExemptFlag |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays        |-> [i \in 1 .. 2 |-> 0],
      asOfAction             |-> [i \in 1 .. 1 |-> 0],
      timestampOfTrade       |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional As Of Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalAsOfTradeMessage ==
    { ZeroFractionalAsOfTradeMessage }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.tradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.asOfAction = one] : one \in Sample(1) }
        \cup { [ZeroFractionalAsOfTradeMessage EXCEPT !.timestampOfTrade = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

TradeReportMessageShortformMessageCode == 65  \* "A"
TradeReportMessageLongformMessageCode == 87  \* "W"
TradeCancelErrorMessageCode == 90  \* "Z"
TradeCorrectionMessageCode == 89  \* "Y"
PriorDayAsOfTradeMessageCode == 72  \* "H"
FractionalTradeReportMessageShortformMessageCode == 77  \* "M"
FractionalTradeReportMessageLongformMessageCode == 78  \* "N"
FractionalTradeCancelErrorMessageCode == 79  \* "O"
FractionalTradeCorrectionMessageCode == 80  \* "P"
FractionalAsOfTradeMessageCode == 81  \* "Q"

TradeMessagePayload ==
    [ tag : {TradeReportMessageShortformMessageCode}, body : TradeReportMessageShortformMessage ]
        \cup [ tag : {TradeReportMessageLongformMessageCode}, body : TradeReportMessageLongformMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {PriorDayAsOfTradeMessageCode}, body : PriorDayAsOfTradeMessage ]
        \cup [ tag : {FractionalTradeReportMessageShortformMessageCode}, body : FractionalTradeReportMessageShortformMessage ]
        \cup [ tag : {FractionalTradeReportMessageLongformMessageCode}, body : FractionalTradeReportMessageLongformMessage ]
        \cup [ tag : {FractionalTradeCancelErrorMessageCode}, body : FractionalTradeCancelErrorMessage ]
        \cup [ tag : {FractionalTradeCorrectionMessageCode}, body : FractionalTradeCorrectionMessage ]
        \cup [ tag : {FractionalAsOfTradeMessageCode}, body : FractionalAsOfTradeMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = TradeReportMessageShortformMessageCode -> EncodeTradeReportMessageShortformMessage(message.body)
      [] message.tag = TradeReportMessageLongformMessageCode -> EncodeTradeReportMessageLongformMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = PriorDayAsOfTradeMessageCode -> EncodePriorDayAsOfTradeMessage(message.body)
      [] message.tag = FractionalTradeReportMessageShortformMessageCode -> EncodeFractionalTradeReportMessageShortformMessage(message.body)
      [] message.tag = FractionalTradeReportMessageLongformMessageCode -> EncodeFractionalTradeReportMessageLongformMessage(message.body)
      [] message.tag = FractionalTradeCancelErrorMessageCode -> EncodeFractionalTradeCancelErrorMessage(message.body)
      [] message.tag = FractionalTradeCorrectionMessageCode -> EncodeFractionalTradeCorrectionMessage(message.body)
      [] message.tag = FractionalAsOfTradeMessageCode -> EncodeFractionalAsOfTradeMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeReportMessageShortformMessageCode -> DecodeTradeReportMessageShortformMessage(bytes)
              [] tag = TradeReportMessageLongformMessageCode -> DecodeTradeReportMessageLongformMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = PriorDayAsOfTradeMessageCode -> DecodePriorDayAsOfTradeMessage(bytes)
              [] tag = FractionalTradeReportMessageShortformMessageCode -> DecodeFractionalTradeReportMessageShortformMessage(bytes)
              [] tag = FractionalTradeReportMessageLongformMessageCode -> DecodeFractionalTradeReportMessageLongformMessage(bytes)
              [] tag = FractionalTradeCancelErrorMessageCode -> DecodeFractionalTradeCancelErrorMessage(bytes)
              [] tag = FractionalTradeCorrectionMessageCode -> DecodeFractionalTradeCorrectionMessage(bytes)
              [] tag = FractionalAsOfTradeMessageCode -> DecodeFractionalAsOfTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> TradeReportMessageShortformMessageCode, body |-> ZeroTradeReportMessageShortformMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> TradeReportMessageShortformMessageCode, body |-> one] : one \in CheckedTradeReportMessageShortformMessage }
        \cup { [tag |-> TradeReportMessageLongformMessageCode, body |-> one] : one \in CheckedTradeReportMessageLongformMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> PriorDayAsOfTradeMessageCode, body |-> one] : one \in CheckedPriorDayAsOfTradeMessage }
        \cup { [tag |-> FractionalTradeReportMessageShortformMessageCode, body |-> one] : one \in CheckedFractionalTradeReportMessageShortformMessage }
        \cup { [tag |-> FractionalTradeReportMessageLongformMessageCode, body |-> one] : one \in CheckedFractionalTradeReportMessageLongformMessage }
        \cup { [tag |-> FractionalTradeCancelErrorMessageCode, body |-> one] : one \in CheckedFractionalTradeCancelErrorMessage }
        \cup { [tag |-> FractionalTradeCorrectionMessageCode, body |-> one] : one \in CheckedFractionalTradeCorrectionMessage }
        \cup { [tag |-> FractionalAsOfTradeMessageCode, body |-> one] : one \in CheckedFractionalAsOfTradeMessage }

(***************************************************************************)
(* Trade Message                                                           *)
(***************************************************************************)

TradeMessage ==
    [ tradeMessagePayload : TradeMessagePayload ]

EncodeTradeMessage(message) ==
    EncodeUIntBE(message.tradeMessagePayload.tag, 1)
        \o EncodeTradeMessagePayload(message.tradeMessagePayload)

DecodeTradeMessage(bytes) ==
    LET tradeMessageType == ReadUIntBE(bytes, 1) IN IF ~tradeMessageType.ok THEN Fail ELSE
    LET tradeMessagePayload == DecodeTradeMessagePayload(tradeMessageType.value, tradeMessageType.rest) IN IF ~tradeMessagePayload.ok THEN Fail ELSE
    Ok([ tradeMessagePayload |-> tradeMessagePayload.value ], tradeMessagePayload.rest)

ZeroTradeMessage ==
    [ tradeMessagePayload |-> ZeroTradeMessagePayload ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.tradeMessagePayload = one] : one \in CheckedTradeMessagePayload }

(***************************************************************************)
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      text                   : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o EncodeUIntBE(Len(message.text), 2)
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET textLength == ReadUIntBE(participantToken.rest, 2) IN IF ~textLength.ok THEN Fail ELSE
    LET text == ReadBytes(textLength.rest, textLength.value) IN IF ~text.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         text                   |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      text                   |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Cross Sro Trading Action Message: 56 bytes                              *)
(***************************************************************************)

CrossSroTradingActionMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      tradingActionCode           : Sample(1),
      tradingActionSequenceNumber : Sample(4),
      actionTime                  : Sample(8),
      reasonForTheTradingAction   : Sample(6) ]

EncodeCrossSroTradingActionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.tradingActionSequenceNumber
        \o message.actionTime
        \o message.reasonForTheTradingAction

DecodeCrossSroTradingActionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(tradingActionCode.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET actionTime == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET reasonForTheTradingAction == ReadBytes(actionTime.rest, 6) IN IF ~reasonForTheTradingAction.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionCode           |-> tradingActionCode.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         actionTime                  |-> actionTime.value,
         reasonForTheTradingAction   |-> reasonForTheTradingAction.value ], reasonForTheTradingAction.rest)

ZeroCrossSroTradingActionMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode           |-> [i \in 1 .. 1 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      actionTime                  |-> [i \in 1 .. 8 |-> 0],
      reasonForTheTradingAction   |-> [i \in 1 .. 6 |-> 0] ]

(* Cross Sro Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossSroTradingActionMessage ==
    { ZeroCrossSroTradingActionMessage }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.reasonForTheTradingAction = one] : one \in Sample(6) }

(***************************************************************************)
(* Market Center Trading Action Message: 47 bytes                          *)
(***************************************************************************)

MarketCenterTradingActionMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      symbolLong             : Sample(11),
      tradingActionCode      : Sample(1),
      actionTime             : Sample(8),
      marketCenterIdentifier : Sample(1) ]

EncodeMarketCenterTradingActionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.actionTime
        \o message.marketCenterIdentifier

DecodeMarketCenterTradingActionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET actionTime == ReadBytes(tradingActionCode.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET marketCenterIdentifier == ReadBytes(actionTime.rest, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         symbolLong             |-> symbolLong.value,
         tradingActionCode      |-> tradingActionCode.value,
         actionTime             |-> actionTime.value,
         marketCenterIdentifier |-> marketCenterIdentifier.value ], marketCenterIdentifier.rest)

ZeroMarketCenterTradingActionMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode      |-> [i \in 1 .. 1 |-> 0],
      actionTime             |-> [i \in 1 .. 8 |-> 0],
      marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0] ]

(* Market Center Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterTradingActionMessage ==
    { ZeroMarketCenterTradingActionMessage }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Symbol Directory Message: 87 bytes                                *)
(***************************************************************************)

IssueSymbolDirectoryMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      oldSymbol                   : Sample(11),
      issueName                   : Sample(30),
      issueType                   : Sample(1),
      issueSubtype                : Sample(2),
      marketTier                  : Sample(1),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      roundLotSize                : Sample(2),
      financialStatusIndicator    : Sample(1) ]

EncodeIssueSymbolDirectoryMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.oldSymbol
        \o message.issueName
        \o message.issueType
        \o message.issueSubtype
        \o message.marketTier
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.roundLotSize
        \o message.financialStatusIndicator

DecodeIssueSymbolDirectoryMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET oldSymbol == ReadBytes(symbolLong.rest, 11) IN IF ~oldSymbol.ok THEN Fail ELSE
    LET issueName == ReadBytes(oldSymbol.rest, 30) IN IF ~issueName.ok THEN Fail ELSE
    LET issueType == ReadBytes(issueName.rest, 1) IN IF ~issueType.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueType.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET marketTier == ReadBytes(issueSubtype.rest, 1) IN IF ~marketTier.ok THEN Fail ELSE
    LET authenticity == ReadBytes(marketTier.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(shortSaleThresholdIndicator.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         oldSymbol                   |-> oldSymbol.value,
         issueName                   |-> issueName.value,
         issueType                   |-> issueType.value,
         issueSubtype                |-> issueSubtype.value,
         marketTier                  |-> marketTier.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         financialStatusIndicator    |-> financialStatusIndicator.value ], financialStatusIndicator.rest)

ZeroIssueSymbolDirectoryMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      oldSymbol                   |-> [i \in 1 .. 11 |-> 0],
      issueName                   |-> [i \in 1 .. 30 |-> 0],
      issueType                   |-> [i \in 1 .. 1 |-> 0],
      issueSubtype                |-> [i \in 1 .. 2 |-> 0],
      marketTier                  |-> [i \in 1 .. 1 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 2 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueSymbolDirectoryMessage ==
    { ZeroIssueSymbolDirectoryMessage }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.oldSymbol = one] : one \in Sample(11) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueName = one] : one \in Sample(30) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueType = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueSubtype = one] : one \in Sample(2) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.marketTier = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 38 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      symbolLong             : Sample(11),
      regShoAction           : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(symbolLong.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         symbolLong             |-> symbolLong.value,
         regShoAction           |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      regShoAction           |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Limit Up Limit Down Price Band Message: 62 bytes                        *)
(***************************************************************************)

LimitUpLimitDownPriceBandMessage ==
    [ marketCenterOriginator     : Sample(1),
      subMarketCenterId          : Sample(1),
      sipTimestamp               : Sample(8),
      timestamp1                 : Sample(8),
      participantToken           : Sample(8),
      symbolLong                 : Sample(11),
      luldPriceBandIndicator     : Sample(1),
      luldPriceBandEffectiveTime : Sample(8),
      limitDownPrice             : Sample(8),
      limitUpPrice               : Sample(8) ]

EncodeLimitUpLimitDownPriceBandMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.luldPriceBandIndicator
        \o message.luldPriceBandEffectiveTime
        \o message.limitDownPrice
        \o message.limitUpPrice

DecodeLimitUpLimitDownPriceBandMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET luldPriceBandIndicator == ReadBytes(symbolLong.rest, 1) IN IF ~luldPriceBandIndicator.ok THEN Fail ELSE
    LET luldPriceBandEffectiveTime == ReadBytes(luldPriceBandIndicator.rest, 8) IN IF ~luldPriceBandEffectiveTime.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(luldPriceBandEffectiveTime.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator     |-> marketCenterOriginator.value,
         subMarketCenterId          |-> subMarketCenterId.value,
         sipTimestamp               |-> sipTimestamp.value,
         timestamp1                 |-> timestamp1.value,
         participantToken           |-> participantToken.value,
         symbolLong                 |-> symbolLong.value,
         luldPriceBandIndicator     |-> luldPriceBandIndicator.value,
         luldPriceBandEffectiveTime |-> luldPriceBandEffectiveTime.value,
         limitDownPrice             |-> limitDownPrice.value,
         limitUpPrice               |-> limitUpPrice.value ], limitUpPrice.rest)

ZeroLimitUpLimitDownPriceBandMessage ==
    [ marketCenterOriginator     |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId          |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp               |-> [i \in 1 .. 8 |-> 0],
      timestamp1                 |-> [i \in 1 .. 8 |-> 0],
      participantToken           |-> [i \in 1 .. 8 |-> 0],
      symbolLong                 |-> [i \in 1 .. 11 |-> 0],
      luldPriceBandIndicator     |-> [i \in 1 .. 1 |-> 0],
      luldPriceBandEffectiveTime |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice             |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice               |-> [i \in 1 .. 8 |-> 0] ]

(* Limit Up Limit Down Price Band Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitUpLimitDownPriceBandMessage ==
    { ZeroLimitUpLimitDownPriceBandMessage }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandEffectiveTime = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Message: 50 bytes             *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      mwcbLevel1             : Sample(8),
      mwcbLevel2             : Sample(8),
      mwcbLevel3             : Sample(8) ]

EncodeMarketWideCircuitBreakerDeclineLevelMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3

DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(participantToken.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         mwcbLevel1             |-> mwcbLevel1.value,
         mwcbLevel2             |-> mwcbLevel2.value,
         mwcbLevel3             |-> mwcbLevel3.value ], mwcbLevel3.rest)

ZeroMarketWideCircuitBreakerDeclineLevelMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel1             |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2             |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3             |-> [i \in 1 .. 8 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Status Message: 27 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ marketCenterOriginator   : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      timestamp1               : Sample(8),
      participantToken         : Sample(8),
      mwcbStatusLevelIndicator : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.mwcbStatusLevelIndicator

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET mwcbStatusLevelIndicator == ReadBytes(participantToken.rest, 1) IN IF ~mwcbStatusLevelIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator   |-> marketCenterOriginator.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         timestamp1               |-> timestamp1.value,
         participantToken         |-> participantToken.value,
         mwcbStatusLevelIndicator |-> mwcbStatusLevelIndicator.value ], mwcbStatusLevelIndicator.rest)

ZeroMarketWideCircuitBreakerStatusMessage ==
    [ marketCenterOriginator   |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      timestamp1               |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0],
      mwcbStatusLevelIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.mwcbStatusLevelIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Collar Message: 66 bytes                                        *)
(***************************************************************************)

AuctionCollarMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      tradingActionSequenceNumber : Sample(4),
      collarReferencePrice        : Sample(8),
      collarUpPrice               : Sample(8),
      collarDownPrice             : Sample(8),
      collarExtensionIndicator    : Sample(1) ]

EncodeAuctionCollarMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.tradingActionSequenceNumber
        \o message.collarReferencePrice
        \o message.collarUpPrice
        \o message.collarDownPrice
        \o message.collarExtensionIndicator

DecodeAuctionCollarMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(symbolLong.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET collarUpPrice == ReadBytes(collarReferencePrice.rest, 8) IN IF ~collarUpPrice.ok THEN Fail ELSE
    LET collarDownPrice == ReadBytes(collarUpPrice.rest, 8) IN IF ~collarDownPrice.ok THEN Fail ELSE
    LET collarExtensionIndicator == ReadBytes(collarDownPrice.rest, 1) IN IF ~collarExtensionIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         collarReferencePrice        |-> collarReferencePrice.value,
         collarUpPrice               |-> collarUpPrice.value,
         collarDownPrice             |-> collarDownPrice.value,
         collarExtensionIndicator    |-> collarExtensionIndicator.value ], collarExtensionIndicator.rest)

ZeroAuctionCollarMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      collarReferencePrice        |-> [i \in 1 .. 8 |-> 0],
      collarUpPrice               |-> [i \in 1 .. 8 |-> 0],
      collarDownPrice             |-> [i \in 1 .. 8 |-> 0],
      collarExtensionIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCollarMessage ==
    { ZeroAuctionCollarMessage }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarExtensionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Center Closing Price And Volume Summary: 34 bytes                *)
(***************************************************************************)

MarketCenterClosingPriceAndVolumeSummary ==
    [ marketCenterIdentifier     : Sample(1),
      marketCenterClosingPrice   : Sample(8),
      marketCenterVolume         : Sample(8),
      marketCenterCloseIndicator : Sample(1),
      marketParticipantHighPrice : Sample(8),
      marketParticipantLowPrice  : Sample(8) ]

EncodeMarketCenterClosingPriceAndVolumeSummary(message) ==
    message.marketCenterIdentifier
        \o message.marketCenterClosingPrice
        \o message.marketCenterVolume
        \o message.marketCenterCloseIndicator
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice

DecodeMarketCenterClosingPriceAndVolumeSummary(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET marketCenterClosingPrice == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~marketCenterClosingPrice.ok THEN Fail ELSE
    LET marketCenterVolume == ReadBytes(marketCenterClosingPrice.rest, 8) IN IF ~marketCenterVolume.ok THEN Fail ELSE
    LET marketCenterCloseIndicator == ReadBytes(marketCenterVolume.rest, 1) IN IF ~marketCenterCloseIndicator.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(marketCenterCloseIndicator.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier     |-> marketCenterIdentifier.value,
         marketCenterClosingPrice   |-> marketCenterClosingPrice.value,
         marketCenterVolume         |-> marketCenterVolume.value,
         marketCenterCloseIndicator |-> marketCenterCloseIndicator.value,
         marketParticipantHighPrice |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice  |-> marketParticipantLowPrice.value ], marketParticipantLowPrice.rest)

ZeroMarketCenterClosingPriceAndVolumeSummary ==
    [ marketCenterIdentifier     |-> [i \in 1 .. 1 |-> 0],
      marketCenterClosingPrice   |-> [i \in 1 .. 8 |-> 0],
      marketCenterVolume         |-> [i \in 1 .. 8 |-> 0],
      marketCenterCloseIndicator |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice  |-> [i \in 1 .. 8 |-> 0] ]

(* Market Center Closing Price And Volume Summary at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterClosingPriceAndVolumeSummary ==
    { ZeroMarketCenterClosingPriceAndVolumeSummary }
        \cup { [ZeroMarketCenterClosingPriceAndVolumeSummary EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterClosingPriceAndVolumeSummary EXCEPT !.marketCenterClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterClosingPriceAndVolumeSummary EXCEPT !.marketCenterVolume = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterClosingPriceAndVolumeSummary EXCEPT !.marketCenterCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterClosingPriceAndVolumeSummary EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterClosingPriceAndVolumeSummary EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }

(* A run of Market Center Closing Price And Volume Summary, written one after another *)
RECURSIVE EncodeMarketCenterClosingPriceAndVolumeSummaryList(_)
EncodeMarketCenterClosingPriceAndVolumeSummaryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketCenterClosingPriceAndVolumeSummary(Head(messages)) \o EncodeMarketCenterClosingPriceAndVolumeSummaryList(Tail(messages))

(* As many Market Center Closing Price And Volume Summary as the field that counts them says *)
RECURSIVE ReadMarketCenterClosingPriceAndVolumeSummaryList(_, _)
ReadMarketCenterClosingPriceAndVolumeSummaryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketCenterClosingPriceAndVolumeSummary(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketCenterClosingPriceAndVolumeSummaryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Center Closing Price And Volume Summary of each kind, for the lists that carry them *)
OneMarketCenterClosingPriceAndVolumeSummary == { ZeroMarketCenterClosingPriceAndVolumeSummary }

(***************************************************************************)
(* Closing Trade Summary Report Message                                    *)
(***************************************************************************)

ClosingTradeSummaryReportMessage ==
    [ marketCenterOriginator                   : Sample(1),
      subMarketCenterId                        : Sample(1),
      sipTimestamp                             : Sample(8),
      timestamp1                               : Sample(8),
      participantToken                         : Sample(8),
      symbolLong                               : Sample(11),
      dailyConsolidatedHighPrice               : Sample(8),
      dailyConsolidatedLowPrice                : Sample(8),
      dailyConsolidatedClosingPrice            : Sample(8),
      consolidatedLastPriceOriginator          : Sample(1),
      consolidatedVolume                       : Sample(8),
      tradingActionIndicator                   : Sample(1),
      marketCenterClosingPriceAndVolumeSummary : SampleLists(OneMarketCenterClosingPriceAndVolumeSummary) ]

EncodeClosingTradeSummaryReportMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.dailyConsolidatedHighPrice
        \o message.dailyConsolidatedLowPrice
        \o message.dailyConsolidatedClosingPrice
        \o message.consolidatedLastPriceOriginator
        \o message.consolidatedVolume
        \o message.tradingActionIndicator
        \o EncodeUIntBE(Len(message.marketCenterClosingPriceAndVolumeSummary), 2)
        \o EncodeMarketCenterClosingPriceAndVolumeSummaryList(message.marketCenterClosingPriceAndVolumeSummary)

DecodeClosingTradeSummaryReportMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET dailyConsolidatedHighPrice == ReadBytes(symbolLong.rest, 8) IN IF ~dailyConsolidatedHighPrice.ok THEN Fail ELSE
    LET dailyConsolidatedLowPrice == ReadBytes(dailyConsolidatedHighPrice.rest, 8) IN IF ~dailyConsolidatedLowPrice.ok THEN Fail ELSE
    LET dailyConsolidatedClosingPrice == ReadBytes(dailyConsolidatedLowPrice.rest, 8) IN IF ~dailyConsolidatedClosingPrice.ok THEN Fail ELSE
    LET consolidatedLastPriceOriginator == ReadBytes(dailyConsolidatedClosingPrice.rest, 1) IN IF ~consolidatedLastPriceOriginator.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPriceOriginator.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET tradingActionIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~tradingActionIndicator.ok THEN Fail ELSE
    LET numberOfMarketCenterAttachments == ReadUIntBE(tradingActionIndicator.rest, 2) IN IF ~numberOfMarketCenterAttachments.ok THEN Fail ELSE
    LET marketCenterClosingPriceAndVolumeSummary == ReadMarketCenterClosingPriceAndVolumeSummaryList(numberOfMarketCenterAttachments.rest, numberOfMarketCenterAttachments.value) IN IF ~marketCenterClosingPriceAndVolumeSummary.ok THEN Fail ELSE
    Ok([ marketCenterOriginator                   |-> marketCenterOriginator.value,
         subMarketCenterId                        |-> subMarketCenterId.value,
         sipTimestamp                             |-> sipTimestamp.value,
         timestamp1                               |-> timestamp1.value,
         participantToken                         |-> participantToken.value,
         symbolLong                               |-> symbolLong.value,
         dailyConsolidatedHighPrice               |-> dailyConsolidatedHighPrice.value,
         dailyConsolidatedLowPrice                |-> dailyConsolidatedLowPrice.value,
         dailyConsolidatedClosingPrice            |-> dailyConsolidatedClosingPrice.value,
         consolidatedLastPriceOriginator          |-> consolidatedLastPriceOriginator.value,
         consolidatedVolume                       |-> consolidatedVolume.value,
         tradingActionIndicator                   |-> tradingActionIndicator.value,
         marketCenterClosingPriceAndVolumeSummary |-> marketCenterClosingPriceAndVolumeSummary.value ], marketCenterClosingPriceAndVolumeSummary.rest)

ZeroClosingTradeSummaryReportMessage ==
    [ marketCenterOriginator                   |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                             |-> [i \in 1 .. 8 |-> 0],
      timestamp1                               |-> [i \in 1 .. 8 |-> 0],
      participantToken                         |-> [i \in 1 .. 8 |-> 0],
      symbolLong                               |-> [i \in 1 .. 11 |-> 0],
      dailyConsolidatedHighPrice               |-> [i \in 1 .. 8 |-> 0],
      dailyConsolidatedLowPrice                |-> [i \in 1 .. 8 |-> 0],
      dailyConsolidatedClosingPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPriceOriginator          |-> [i \in 1 .. 1 |-> 0],
      consolidatedVolume                       |-> [i \in 1 .. 8 |-> 0],
      tradingActionIndicator                   |-> [i \in 1 .. 1 |-> 0],
      marketCenterClosingPriceAndVolumeSummary |-> << >> ]

(* Closing Trade Summary Report Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingTradeSummaryReportMessage ==
    { ZeroClosingTradeSummaryReportMessage }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyConsolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyConsolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyConsolidatedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.consolidatedLastPriceOriginator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.tradingActionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.marketCenterClosingPriceAndVolumeSummary = one] : one \in SampleLists(OneMarketCenterClosingPriceAndVolumeSummary) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

GeneralAdministrativeMessageCode == 65  \* "A"
CrossSroTradingActionMessageCode == 72  \* "H"
MarketCenterTradingActionMessageCode == 75  \* "K"
IssueSymbolDirectoryMessageCode == 66  \* "B"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 86  \* "V"
LimitUpLimitDownPriceBandMessageCode == 80  \* "P"
MarketWideCircuitBreakerDeclineLevelMessageCode == 67  \* "C"
MarketWideCircuitBreakerStatusMessageCode == 68  \* "D"
AuctionCollarMessageCode == 69  \* "E"
ClosingTradeSummaryReportMessageCode == 85  \* "U"

AdministrativeMessagePayload ==
    [ tag : {GeneralAdministrativeMessageCode}, body : GeneralAdministrativeMessage ]
        \cup [ tag : {CrossSroTradingActionMessageCode}, body : CrossSroTradingActionMessage ]
        \cup [ tag : {MarketCenterTradingActionMessageCode}, body : MarketCenterTradingActionMessage ]
        \cup [ tag : {IssueSymbolDirectoryMessageCode}, body : IssueSymbolDirectoryMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {LimitUpLimitDownPriceBandMessageCode}, body : LimitUpLimitDownPriceBandMessage ]
        \cup [ tag : {MarketWideCircuitBreakerDeclineLevelMessageCode}, body : MarketWideCircuitBreakerDeclineLevelMessage ]
        \cup [ tag : {MarketWideCircuitBreakerStatusMessageCode}, body : MarketWideCircuitBreakerStatusMessage ]
        \cup [ tag : {AuctionCollarMessageCode}, body : AuctionCollarMessage ]
        \cup [ tag : {ClosingTradeSummaryReportMessageCode}, body : ClosingTradeSummaryReportMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = GeneralAdministrativeMessageCode -> EncodeGeneralAdministrativeMessage(message.body)
      [] message.tag = CrossSroTradingActionMessageCode -> EncodeCrossSroTradingActionMessage(message.body)
      [] message.tag = MarketCenterTradingActionMessageCode -> EncodeMarketCenterTradingActionMessage(message.body)
      [] message.tag = IssueSymbolDirectoryMessageCode -> EncodeIssueSymbolDirectoryMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = LimitUpLimitDownPriceBandMessageCode -> EncodeLimitUpLimitDownPriceBandMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerDeclineLevelMessageCode -> EncodeMarketWideCircuitBreakerDeclineLevelMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerStatusMessageCode -> EncodeMarketWideCircuitBreakerStatusMessage(message.body)
      [] message.tag = AuctionCollarMessageCode -> EncodeAuctionCollarMessage(message.body)
      [] message.tag = ClosingTradeSummaryReportMessageCode -> EncodeClosingTradeSummaryReportMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GeneralAdministrativeMessageCode -> DecodeGeneralAdministrativeMessage(bytes)
              [] tag = CrossSroTradingActionMessageCode -> DecodeCrossSroTradingActionMessage(bytes)
              [] tag = MarketCenterTradingActionMessageCode -> DecodeMarketCenterTradingActionMessage(bytes)
              [] tag = IssueSymbolDirectoryMessageCode -> DecodeIssueSymbolDirectoryMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = LimitUpLimitDownPriceBandMessageCode -> DecodeLimitUpLimitDownPriceBandMessage(bytes)
              [] tag = MarketWideCircuitBreakerDeclineLevelMessageCode -> DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes)
              [] tag = MarketWideCircuitBreakerStatusMessageCode -> DecodeMarketWideCircuitBreakerStatusMessage(bytes)
              [] tag = AuctionCollarMessageCode -> DecodeAuctionCollarMessage(bytes)
              [] tag = ClosingTradeSummaryReportMessageCode -> DecodeClosingTradeSummaryReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> GeneralAdministrativeMessageCode, body |-> ZeroGeneralAdministrativeMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> GeneralAdministrativeMessageCode, body |-> one] : one \in CheckedGeneralAdministrativeMessage }
        \cup { [tag |-> CrossSroTradingActionMessageCode, body |-> one] : one \in CheckedCrossSroTradingActionMessage }
        \cup { [tag |-> MarketCenterTradingActionMessageCode, body |-> one] : one \in CheckedMarketCenterTradingActionMessage }
        \cup { [tag |-> IssueSymbolDirectoryMessageCode, body |-> one] : one \in CheckedIssueSymbolDirectoryMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> LimitUpLimitDownPriceBandMessageCode, body |-> one] : one \in CheckedLimitUpLimitDownPriceBandMessage }
        \cup { [tag |-> MarketWideCircuitBreakerDeclineLevelMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [tag |-> MarketWideCircuitBreakerStatusMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerStatusMessage }
        \cup { [tag |-> AuctionCollarMessageCode, body |-> one] : one \in CheckedAuctionCollarMessage }
        \cup { [tag |-> ClosingTradeSummaryReportMessageCode, body |-> one] : one \in CheckedClosingTradeSummaryReportMessage }

(***************************************************************************)
(* Administrative Message                                                  *)
(***************************************************************************)

AdministrativeMessage ==
    [ administrativeMessagePayload : AdministrativeMessagePayload ]

EncodeAdministrativeMessage(message) ==
    EncodeUIntBE(message.administrativeMessagePayload.tag, 1)
        \o EncodeAdministrativeMessagePayload(message.administrativeMessagePayload)

DecodeAdministrativeMessage(bytes) ==
    LET administrativeMessageType == ReadUIntBE(bytes, 1) IN IF ~administrativeMessageType.ok THEN Fail ELSE
    LET administrativeMessagePayload == DecodeAdministrativeMessagePayload(administrativeMessageType.value, administrativeMessageType.rest) IN IF ~administrativeMessagePayload.ok THEN Fail ELSE
    Ok([ administrativeMessagePayload |-> administrativeMessagePayload.value ], administrativeMessagePayload.rest)

ZeroAdministrativeMessage ==
    [ administrativeMessagePayload |-> ZeroAdministrativeMessagePayload ]

(* Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeMessage ==
    { ZeroAdministrativeMessage }
        \cup { [ZeroAdministrativeMessage EXCEPT !.administrativeMessagePayload = one] : one \in CheckedAdministrativeMessagePayload }

(***************************************************************************)
(* Market Center Volume Group: 9 bytes                                     *)
(***************************************************************************)

MarketCenterVolumeGroup ==
    [ marketCenterIdentifier : Sample(1),
      marketCenterVolume     : Sample(8) ]

EncodeMarketCenterVolumeGroup(message) ==
    message.marketCenterIdentifier
        \o message.marketCenterVolume

DecodeMarketCenterVolumeGroup(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET marketCenterVolume == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~marketCenterVolume.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier |-> marketCenterIdentifier.value,
         marketCenterVolume     |-> marketCenterVolume.value ], marketCenterVolume.rest)

ZeroMarketCenterVolumeGroup ==
    [ marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      marketCenterVolume     |-> [i \in 1 .. 8 |-> 0] ]

(* Market Center Volume Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterVolumeGroup ==
    { ZeroMarketCenterVolumeGroup }
        \cup { [ZeroMarketCenterVolumeGroup EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterVolumeGroup EXCEPT !.marketCenterVolume = one] : one \in Sample(8) }

(* A run of Market Center Volume Group, written one after another *)
RECURSIVE EncodeMarketCenterVolumeGroupList(_)
EncodeMarketCenterVolumeGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketCenterVolumeGroup(Head(messages)) \o EncodeMarketCenterVolumeGroupList(Tail(messages))

(* As many Market Center Volume Group as the field that counts them says *)
RECURSIVE ReadMarketCenterVolumeGroupList(_, _)
ReadMarketCenterVolumeGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketCenterVolumeGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketCenterVolumeGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Center Volume Group of each kind, for the lists that carry them *)
OneMarketCenterVolumeGroup == { ZeroMarketCenterVolumeGroup }

(***************************************************************************)
(* Total Consolidated And Market Center Volume Message                     *)
(***************************************************************************)

TotalConsolidatedAndMarketCenterVolumeMessage ==
    [ marketCenterOriginator  : Sample(1),
      subMarketCenterId       : Sample(1),
      sipTimestamp            : Sample(8),
      timestamp1              : Sample(8),
      participantToken        : Sample(8),
      totalConsolidatedVolume : Sample(8),
      marketCenterVolumeGroup : SampleLists(OneMarketCenterVolumeGroup) ]

EncodeTotalConsolidatedAndMarketCenterVolumeMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.totalConsolidatedVolume
        \o EncodeUIntBE(Len(message.marketCenterVolumeGroup), 2)
        \o EncodeMarketCenterVolumeGroupList(message.marketCenterVolumeGroup)

DecodeTotalConsolidatedAndMarketCenterVolumeMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET totalConsolidatedVolume == ReadBytes(participantToken.rest, 8) IN IF ~totalConsolidatedVolume.ok THEN Fail ELSE
    LET numberOfMarketCenterAttachments == ReadUIntBE(totalConsolidatedVolume.rest, 2) IN IF ~numberOfMarketCenterAttachments.ok THEN Fail ELSE
    LET marketCenterVolumeGroup == ReadMarketCenterVolumeGroupList(numberOfMarketCenterAttachments.rest, numberOfMarketCenterAttachments.value) IN IF ~marketCenterVolumeGroup.ok THEN Fail ELSE
    Ok([ marketCenterOriginator  |-> marketCenterOriginator.value,
         subMarketCenterId       |-> subMarketCenterId.value,
         sipTimestamp            |-> sipTimestamp.value,
         timestamp1              |-> timestamp1.value,
         participantToken        |-> participantToken.value,
         totalConsolidatedVolume |-> totalConsolidatedVolume.value,
         marketCenterVolumeGroup |-> marketCenterVolumeGroup.value ], marketCenterVolumeGroup.rest)

ZeroTotalConsolidatedAndMarketCenterVolumeMessage ==
    [ marketCenterOriginator  |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId       |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp            |-> [i \in 1 .. 8 |-> 0],
      timestamp1              |-> [i \in 1 .. 8 |-> 0],
      participantToken        |-> [i \in 1 .. 8 |-> 0],
      totalConsolidatedVolume |-> [i \in 1 .. 8 |-> 0],
      marketCenterVolumeGroup |-> << >> ]

(* Total Consolidated And Market Center Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedTotalConsolidatedAndMarketCenterVolumeMessage ==
    { ZeroTotalConsolidatedAndMarketCenterVolumeMessage }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.totalConsolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.marketCenterVolumeGroup = one] : one \in SampleLists(OneMarketCenterVolumeGroup) }

(***************************************************************************)
(* Total Consolidated Volume Message Payload, selected by Total            *)
(* Consolidated Volume Message Type                                        *)
(***************************************************************************)

TotalConsolidatedAndMarketCenterVolumeMessageCode == 86  \* "V"

TotalConsolidatedVolumeMessagePayload ==
    [ tag : {TotalConsolidatedAndMarketCenterVolumeMessageCode}, body : TotalConsolidatedAndMarketCenterVolumeMessage ]

EncodeTotalConsolidatedVolumeMessagePayload(message) ==
    CASE message.tag = TotalConsolidatedAndMarketCenterVolumeMessageCode -> EncodeTotalConsolidatedAndMarketCenterVolumeMessage(message.body)

DecodeTotalConsolidatedVolumeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TotalConsolidatedAndMarketCenterVolumeMessageCode -> DecodeTotalConsolidatedAndMarketCenterVolumeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTotalConsolidatedVolumeMessagePayload == [tag |-> TotalConsolidatedAndMarketCenterVolumeMessageCode, body |-> ZeroTotalConsolidatedAndMarketCenterVolumeMessage]

(* Each Total Consolidated Volume Message Payload in turn, at the values the message it names is checked at *)
CheckedTotalConsolidatedVolumeMessagePayload ==
    { [tag |-> TotalConsolidatedAndMarketCenterVolumeMessageCode, body |-> one] : one \in CheckedTotalConsolidatedAndMarketCenterVolumeMessage }

(***************************************************************************)
(* Total Consolidated Volume Message                                       *)
(***************************************************************************)

TotalConsolidatedVolumeMessage ==
    [ totalConsolidatedVolumeMessagePayload : TotalConsolidatedVolumeMessagePayload ]

EncodeTotalConsolidatedVolumeMessage(message) ==
    EncodeUIntBE(message.totalConsolidatedVolumeMessagePayload.tag, 1)
        \o EncodeTotalConsolidatedVolumeMessagePayload(message.totalConsolidatedVolumeMessagePayload)

DecodeTotalConsolidatedVolumeMessage(bytes) ==
    LET totalConsolidatedVolumeMessageType == ReadUIntBE(bytes, 1) IN IF ~totalConsolidatedVolumeMessageType.ok THEN Fail ELSE
    LET totalConsolidatedVolumeMessagePayload == DecodeTotalConsolidatedVolumeMessagePayload(totalConsolidatedVolumeMessageType.value, totalConsolidatedVolumeMessageType.rest) IN IF ~totalConsolidatedVolumeMessagePayload.ok THEN Fail ELSE
    Ok([ totalConsolidatedVolumeMessagePayload |-> totalConsolidatedVolumeMessagePayload.value ], totalConsolidatedVolumeMessagePayload.rest)

ZeroTotalConsolidatedVolumeMessage ==
    [ totalConsolidatedVolumeMessagePayload |-> ZeroTotalConsolidatedVolumeMessagePayload ]

(* Total Consolidated Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedTotalConsolidatedVolumeMessage ==
    { ZeroTotalConsolidatedVolumeMessage }
        \cup { [ZeroTotalConsolidatedVolumeMessage EXCEPT !.totalConsolidatedVolumeMessagePayload = one] : one \in CheckedTotalConsolidatedVolumeMessagePayload }

(***************************************************************************)
(* Start Of Day Message: 26 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeStartOfDayMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroStartOfDayMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Message: 26 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfDayMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfDayMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Open Message: 26 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeMarketSessionOpenMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeMarketSessionOpenMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroMarketSessionOpenMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Close Message: 26 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeMarketSessionCloseMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeMarketSessionCloseMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroMarketSessionCloseMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Transmissions Message: 26 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfTransmissionsMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfTransmissionsMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfTransmissionsMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Trade Reporting Message: 26 bytes                                *)
(***************************************************************************)

EndOfTradeReportingMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfTradeReportingMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfTradeReportingMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfTradeReportingMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Trade Reporting Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTradeReportingMessage ==
    { ZeroEndOfTradeReportingMessage }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Consolidated Last Sale Eligibility Message: 26 bytes             *)
(***************************************************************************)

EndOfConsolidatedLastSaleEligibilityMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfConsolidatedLastSaleEligibilityMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfConsolidatedLastSaleEligibilityMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfConsolidatedLastSaleEligibilityMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Consolidated Last Sale Eligibility Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfConsolidatedLastSaleEligibilityMessage ==
    { ZeroEndOfConsolidatedLastSaleEligibilityMessage }
        \cup { [ZeroEndOfConsolidatedLastSaleEligibilityMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfConsolidatedLastSaleEligibilityMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfConsolidatedLastSaleEligibilityMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfConsolidatedLastSaleEligibilityMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfConsolidatedLastSaleEligibilityMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 73  \* "I"
EndOfDayMessageCode == 74  \* "J"
MarketSessionOpenMessageCode == 79  \* "O"
MarketSessionCloseMessageCode == 67  \* "C"
EndOfTransmissionsMessageCode == 90  \* "Z"
EndOfTradeReportingMessageCode == 88  \* "X"
EndOfConsolidatedLastSaleEligibilityMessageCode == 83  \* "S"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {MarketSessionOpenMessageCode}, body : MarketSessionOpenMessage ]
        \cup [ tag : {MarketSessionCloseMessageCode}, body : MarketSessionCloseMessage ]
        \cup [ tag : {EndOfTransmissionsMessageCode}, body : EndOfTransmissionsMessage ]
        \cup [ tag : {EndOfTradeReportingMessageCode}, body : EndOfTradeReportingMessage ]
        \cup [ tag : {EndOfConsolidatedLastSaleEligibilityMessageCode}, body : EndOfConsolidatedLastSaleEligibilityMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = MarketSessionOpenMessageCode -> EncodeMarketSessionOpenMessage(message.body)
      [] message.tag = MarketSessionCloseMessageCode -> EncodeMarketSessionCloseMessage(message.body)
      [] message.tag = EndOfTransmissionsMessageCode -> EncodeEndOfTransmissionsMessage(message.body)
      [] message.tag = EndOfTradeReportingMessageCode -> EncodeEndOfTradeReportingMessage(message.body)
      [] message.tag = EndOfConsolidatedLastSaleEligibilityMessageCode -> EncodeEndOfConsolidatedLastSaleEligibilityMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = MarketSessionOpenMessageCode -> DecodeMarketSessionOpenMessage(bytes)
              [] tag = MarketSessionCloseMessageCode -> DecodeMarketSessionCloseMessage(bytes)
              [] tag = EndOfTransmissionsMessageCode -> DecodeEndOfTransmissionsMessage(bytes)
              [] tag = EndOfTradeReportingMessageCode -> DecodeEndOfTradeReportingMessage(bytes)
              [] tag = EndOfConsolidatedLastSaleEligibilityMessageCode -> DecodeEndOfConsolidatedLastSaleEligibilityMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> MarketSessionOpenMessageCode, body |-> one] : one \in CheckedMarketSessionOpenMessage }
        \cup { [tag |-> MarketSessionCloseMessageCode, body |-> one] : one \in CheckedMarketSessionCloseMessage }
        \cup { [tag |-> EndOfTransmissionsMessageCode, body |-> one] : one \in CheckedEndOfTransmissionsMessage }
        \cup { [tag |-> EndOfTradeReportingMessageCode, body |-> one] : one \in CheckedEndOfTradeReportingMessage }
        \cup { [tag |-> EndOfConsolidatedLastSaleEligibilityMessageCode, body |-> one] : one \in CheckedEndOfConsolidatedLastSaleEligibilityMessage }

(***************************************************************************)
(* Control Message                                                         *)
(***************************************************************************)

ControlMessage ==
    [ controlMessagePayload : ControlMessagePayload ]

EncodeControlMessage(message) ==
    EncodeUIntBE(message.controlMessagePayload.tag, 1)
        \o EncodeControlMessagePayload(message.controlMessagePayload)

DecodeControlMessage(bytes) ==
    LET controlMessageType == ReadUIntBE(bytes, 1) IN IF ~controlMessageType.ok THEN Fail ELSE
    LET controlMessagePayload == DecodeControlMessagePayload(controlMessageType.value, controlMessageType.rest) IN IF ~controlMessagePayload.ok THEN Fail ELSE
    Ok([ controlMessagePayload |-> controlMessagePayload.value ], controlMessagePayload.rest)

ZeroControlMessage ==
    [ controlMessagePayload |-> ZeroControlMessagePayload ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.controlMessagePayload = one] : one \in CheckedControlMessagePayload }

(***************************************************************************)
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

TradeMessageCode == 84  \* "T"
AdministrativeMessageCode == 65  \* "A"
TotalConsolidatedVolumeMessageCode == 86  \* "V"
ControlMessageCode == 67  \* "C"

CategoryPayload ==
    [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {TotalConsolidatedVolumeMessageCode}, body : TotalConsolidatedVolumeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = TotalConsolidatedVolumeMessageCode -> EncodeTotalConsolidatedVolumeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = TotalConsolidatedVolumeMessageCode -> DecodeTotalConsolidatedVolumeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> TotalConsolidatedVolumeMessageCode, body |-> one] : one \in CheckedTotalConsolidatedVolumeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength   : 0 .. 255,
      version         : Sample(1),
      categoryPayload : CategoryPayload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.messageLength, 2)
        \o message.version
        \o EncodeUIntBE(message.categoryPayload.tag, 1)
        \o EncodeCategoryPayload(message.categoryPayload)

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntBE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET version == ReadBytes(messageLength.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(version.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, messageCategory.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ messageLength   |-> messageLength.value,
         version         |-> version.value,
         categoryPayload |-> categoryPayload.value ], categoryPayload.rest)

ZeroMessage ==
    [ messageLength   |-> 0,
      version         |-> [i \in 1 .. 1 |-> 0],
      categoryPayload |-> ZeroCategoryPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.categoryPayload = one] : one \in CheckedCategoryPayload }

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
    { [ZeroMessage EXCEPT !.categoryPayload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> TotalConsolidatedVolumeMessageCode, body |-> ZeroTotalConsolidatedVolumeMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Trade Report Message Shortform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessageShortformMessage ==
    \A message \in CheckedTradeReportMessageShortformMessage :
        LET read == DecodeTradeReportMessageShortformMessage(EncodeTradeReportMessageShortformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message Longform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessageLongformMessage ==
    \A message \in CheckedTradeReportMessageLongformMessage :
        LET read == DecodeTradeReportMessageLongformMessage(EncodeTradeReportMessageLongformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day As Of Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayAsOfTradeMessage ==
    \A message \in CheckedPriorDayAsOfTradeMessage :
        LET read == DecodePriorDayAsOfTradeMessage(EncodePriorDayAsOfTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Report Message Shortform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeReportMessageShortformMessage ==
    \A message \in CheckedFractionalTradeReportMessageShortformMessage :
        LET read == DecodeFractionalTradeReportMessageShortformMessage(EncodeFractionalTradeReportMessageShortformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Report Message Longform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeReportMessageLongformMessage ==
    \A message \in CheckedFractionalTradeReportMessageLongformMessage :
        LET read == DecodeFractionalTradeReportMessageLongformMessage(EncodeFractionalTradeReportMessageLongformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCancelErrorMessage ==
    \A message \in CheckedFractionalTradeCancelErrorMessage :
        LET read == DecodeFractionalTradeCancelErrorMessage(EncodeFractionalTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCorrectionMessage ==
    \A message \in CheckedFractionalTradeCorrectionMessage :
        LET read == DecodeFractionalTradeCorrectionMessage(EncodeFractionalTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional As Of Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalAsOfTradeMessage ==
    \A message \in CheckedFractionalAsOfTradeMessage :
        LET read == DecodeFractionalAsOfTradeMessage(EncodeFractionalAsOfTradeMessage(message))
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

(* Every General Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralAdministrativeMessage ==
    \A message \in CheckedGeneralAdministrativeMessage :
        LET read == DecodeGeneralAdministrativeMessage(EncodeGeneralAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Sro Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossSroTradingActionMessage ==
    \A message \in CheckedCrossSroTradingActionMessage :
        LET read == DecodeCrossSroTradingActionMessage(EncodeCrossSroTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterTradingActionMessage ==
    \A message \in CheckedMarketCenterTradingActionMessage :
        LET read == DecodeMarketCenterTradingActionMessage(EncodeMarketCenterTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueSymbolDirectoryMessage ==
    \A message \in CheckedIssueSymbolDirectoryMessage :
        LET read == DecodeIssueSymbolDirectoryMessage(EncodeIssueSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Up Limit Down Price Band Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitUpLimitDownPriceBandMessage ==
    \A message \in CheckedLimitUpLimitDownPriceBandMessage :
        LET read == DecodeLimitUpLimitDownPriceBandMessage(EncodeLimitUpLimitDownPriceBandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Decline Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerDeclineLevelMessage ==
    \A message \in CheckedMarketWideCircuitBreakerDeclineLevelMessage :
        LET read == DecodeMarketWideCircuitBreakerDeclineLevelMessage(EncodeMarketWideCircuitBreakerDeclineLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerStatusMessage ==
    \A message \in CheckedMarketWideCircuitBreakerStatusMessage :
        LET read == DecodeMarketWideCircuitBreakerStatusMessage(EncodeMarketWideCircuitBreakerStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Collar Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCollarMessage ==
    \A message \in CheckedAuctionCollarMessage :
        LET read == DecodeAuctionCollarMessage(EncodeAuctionCollarMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Closing Price And Volume Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterClosingPriceAndVolumeSummary ==
    \A message \in CheckedMarketCenterClosingPriceAndVolumeSummary :
        LET read == DecodeMarketCenterClosingPriceAndVolumeSummary(EncodeMarketCenterClosingPriceAndVolumeSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Trade Summary Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingTradeSummaryReportMessage ==
    \A message \in CheckedClosingTradeSummaryReportMessage :
        LET read == DecodeClosingTradeSummaryReportMessage(EncodeClosingTradeSummaryReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdministrativeMessage ==
    \A message \in CheckedAdministrativeMessage :
        LET read == DecodeAdministrativeMessage(EncodeAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Volume Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterVolumeGroup ==
    \A message \in CheckedMarketCenterVolumeGroup :
        LET read == DecodeMarketCenterVolumeGroup(EncodeMarketCenterVolumeGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Consolidated And Market Center Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalConsolidatedAndMarketCenterVolumeMessage ==
    \A message \in CheckedTotalConsolidatedAndMarketCenterVolumeMessage :
        LET read == DecodeTotalConsolidatedAndMarketCenterVolumeMessage(EncodeTotalConsolidatedAndMarketCenterVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Consolidated Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalConsolidatedVolumeMessage ==
    \A message \in CheckedTotalConsolidatedVolumeMessage :
        LET read == DecodeTotalConsolidatedVolumeMessage(EncodeTotalConsolidatedVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMessage ==
    \A message \in CheckedEndOfDayMessage :
        LET read == DecodeEndOfDayMessage(EncodeEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionOpenMessage ==
    \A message \in CheckedMarketSessionOpenMessage :
        LET read == DecodeMarketSessionOpenMessage(EncodeMarketSessionOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionCloseMessage ==
    \A message \in CheckedMarketSessionCloseMessage :
        LET read == DecodeMarketSessionCloseMessage(EncodeMarketSessionCloseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Transmissions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionsMessage ==
    \A message \in CheckedEndOfTransmissionsMessage :
        LET read == DecodeEndOfTransmissionsMessage(EncodeEndOfTransmissionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Trade Reporting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTradeReportingMessage ==
    \A message \in CheckedEndOfTradeReportingMessage :
        LET read == DecodeEndOfTradeReportingMessage(EncodeEndOfTradeReportingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Consolidated Last Sale Eligibility Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfConsolidatedLastSaleEligibilityMessage ==
    \A message \in CheckedEndOfConsolidatedLastSaleEligibilityMessage :
        LET read == DecodeEndOfConsolidatedLastSaleEligibilityMessage(EncodeEndOfConsolidatedLastSaleEligibilityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
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

(* A Trade Message Payload is selected by the Trade Message Type it is written under *)
SelectsTradeMessagePayload ==
    \A message \in CheckedTradeMessagePayload :
        LET read == DecodeTradeMessagePayload(message.tag, EncodeTradeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Administrative Message Payload is selected by the Administrative Message Type it is written under *)
SelectsAdministrativeMessagePayload ==
    \A message \in CheckedAdministrativeMessagePayload :
        LET read == DecodeAdministrativeMessagePayload(message.tag, EncodeAdministrativeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Total Consolidated Volume Message Payload is selected by the Total Consolidated Volume Message Type it is written under *)
SelectsTotalConsolidatedVolumeMessagePayload ==
    \A message \in CheckedTotalConsolidatedVolumeMessagePayload :
        LET read == DecodeTotalConsolidatedVolumeMessagePayload(message.tag, EncodeTotalConsolidatedVolumeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Control Message Payload is selected by the Control Message Type it is written under *)
SelectsControlMessagePayload ==
    \A message \in CheckedControlMessagePayload :
        LET read == DecodeControlMessagePayload(message.tag, EncodeControlMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Category Payload is selected by the Message Category it is written under *)
SelectsCategoryPayload ==
    \A message \in CheckedCategoryPayload :
        LET read == DecodeCategoryPayload(message.tag, EncodeCategoryPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
