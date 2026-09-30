---------------------- MODULE Nasdaq_Utdf_Output_v1_5 ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Output v1.5                                                    *)
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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo ==
    { ZeroMessageInfo }
        \cup { [ZeroMessageInfo EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Sale Condition: 4 bytes                                                 *)
(***************************************************************************)

SaleCondition ==
    [ level1 : Sample(1),
      level2 : Sample(1),
      level3 : Sample(1),
      level4 : Sample(1) ]

EncodeSaleCondition(message) ==
    message.level1
        \o message.level2
        \o message.level3
        \o message.level4

DecodeSaleCondition(bytes) ==
    LET level1 == ReadBytes(bytes, 1) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 1) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 1) IN IF ~level3.ok THEN Fail ELSE
    LET level4 == ReadBytes(level3.rest, 1) IN IF ~level4.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value,
         level4 |-> level4.value ], level4.rest)

ZeroSaleCondition ==
    [ level1 |-> [i \in 1 .. 1 |-> 0],
      level2 |-> [i \in 1 .. 1 |-> 0],
      level3 |-> [i \in 1 .. 1 |-> 0],
      level4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition ==
    { ZeroSaleCondition }
        \cup { [ZeroSaleCondition EXCEPT !.level1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition EXCEPT !.level2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition EXCEPT !.level3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition EXCEPT !.level4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message Short Form Message: 58 bytes                       *)
(***************************************************************************)

TradeReportMessageShortFormMessage ==
    [ messageInfo                      : MessageInfo,
      finraTimestamp                   : Sample(8),
      symbolShort                      : Sample(5),
      tradeId                          : Sample(8),
      tradePriceShort                  : Sample(2),
      tradeVolumeShort                 : Sample(2),
      saleCondition                    : SaleCondition,
      tradeThroughExemptFlag           : Sample(1),
      consolidatedPriceChangeIndicator : Sample(1),
      participantPriceChangeIndicator  : Sample(1) ]

EncodeTradeReportMessageShortFormMessage(message) ==
    EncodeMessageInfo(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolShort
        \o message.tradeId
        \o message.tradePriceShort
        \o message.tradeVolumeShort
        \o EncodeSaleCondition(message.saleCondition)
        \o message.tradeThroughExemptFlag
        \o message.consolidatedPriceChangeIndicator
        \o message.participantPriceChangeIndicator

DecodeTradeReportMessageShortFormMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(finraTimestamp.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolShort.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePriceShort == ReadBytes(tradeId.rest, 2) IN IF ~tradePriceShort.ok THEN Fail ELSE
    LET tradeVolumeShort == ReadBytes(tradePriceShort.rest, 2) IN IF ~tradeVolumeShort.ok THEN Fail ELSE
    LET saleCondition == DecodeSaleCondition(tradeVolumeShort.rest) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(tradeThroughExemptFlag.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET participantPriceChangeIndicator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~participantPriceChangeIndicator.ok THEN Fail ELSE
    Ok([ messageInfo                      |-> messageInfo.value,
         finraTimestamp                   |-> finraTimestamp.value,
         symbolShort                      |-> symbolShort.value,
         tradeId                          |-> tradeId.value,
         tradePriceShort                  |-> tradePriceShort.value,
         tradeVolumeShort                 |-> tradeVolumeShort.value,
         saleCondition                    |-> saleCondition.value,
         tradeThroughExemptFlag           |-> tradeThroughExemptFlag.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         participantPriceChangeIndicator  |-> participantPriceChangeIndicator.value ], participantPriceChangeIndicator.rest)

ZeroTradeReportMessageShortFormMessage ==
    [ messageInfo                      |-> ZeroMessageInfo,
      finraTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      symbolShort                      |-> [i \in 1 .. 5 |-> 0],
      tradeId                          |-> [i \in 1 .. 8 |-> 0],
      tradePriceShort                  |-> [i \in 1 .. 2 |-> 0],
      tradeVolumeShort                 |-> [i \in 1 .. 2 |-> 0],
      saleCondition                    |-> ZeroSaleCondition,
      tradeThroughExemptFlag           |-> [i \in 1 .. 1 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      participantPriceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessageShortFormMessage ==
    { ZeroTradeReportMessageShortFormMessage }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.tradePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.tradeVolumeShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.saleCondition = one] : one \in CheckedSaleCondition }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageShortFormMessage EXCEPT !.participantPriceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo2 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo2(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo2(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo2 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo2 ==
    { ZeroMessageInfo2 }
        \cup { [ZeroMessageInfo2 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo2 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo2 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo2 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo2 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Sale Condition: 4 bytes                                                 *)
(***************************************************************************)

SaleCondition2 ==
    [ level1 : Sample(1),
      level2 : Sample(1),
      level3 : Sample(1),
      level4 : Sample(1) ]

EncodeSaleCondition2(message) ==
    message.level1
        \o message.level2
        \o message.level3
        \o message.level4

DecodeSaleCondition2(bytes) ==
    LET level1 == ReadBytes(bytes, 1) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 1) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 1) IN IF ~level3.ok THEN Fail ELSE
    LET level4 == ReadBytes(level3.rest, 1) IN IF ~level4.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value,
         level4 |-> level4.value ], level4.rest)

ZeroSaleCondition2 ==
    [ level1 |-> [i \in 1 .. 1 |-> 0],
      level2 |-> [i \in 1 .. 1 |-> 0],
      level3 |-> [i \in 1 .. 1 |-> 0],
      level4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition2 ==
    { ZeroSaleCondition2 }
        \cup { [ZeroSaleCondition2 EXCEPT !.level1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition2 EXCEPT !.level2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition2 EXCEPT !.level3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition2 EXCEPT !.level4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message Long Form Message: 74 bytes                        *)
(***************************************************************************)

TradeReportMessageLongFormMessage ==
    [ messageInfo                      : MessageInfo2,
      finraTimestamp                   : Sample(8),
      symbolLong                       : Sample(11),
      tradeId                          : Sample(8),
      tradePrice                       : Sample(8),
      tradeVolume                      : Sample(4),
      saleCondition                    : SaleCondition2,
      tradeThroughExemptFlag           : Sample(1),
      sellersSaleDays                  : Sample(2),
      consolidatedPriceChangeIndicator : Sample(1),
      participantPriceChangeIndicator  : Sample(1) ]

EncodeTradeReportMessageLongFormMessage(message) ==
    EncodeMessageInfo2(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolLong
        \o message.tradeId
        \o message.tradePrice
        \o message.tradeVolume
        \o EncodeSaleCondition2(message.saleCondition)
        \o message.tradeThroughExemptFlag
        \o message.sellersSaleDays
        \o message.consolidatedPriceChangeIndicator
        \o message.participantPriceChangeIndicator

DecodeTradeReportMessageLongFormMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo2(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(finraTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeId.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET saleCondition == DecodeSaleCondition2(tradeVolume.rest) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeThroughExemptFlag.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET participantPriceChangeIndicator == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~participantPriceChangeIndicator.ok THEN Fail ELSE
    Ok([ messageInfo                      |-> messageInfo.value,
         finraTimestamp                   |-> finraTimestamp.value,
         symbolLong                       |-> symbolLong.value,
         tradeId                          |-> tradeId.value,
         tradePrice                       |-> tradePrice.value,
         tradeVolume                      |-> tradeVolume.value,
         saleCondition                    |-> saleCondition.value,
         tradeThroughExemptFlag           |-> tradeThroughExemptFlag.value,
         sellersSaleDays                  |-> sellersSaleDays.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         participantPriceChangeIndicator  |-> participantPriceChangeIndicator.value ], participantPriceChangeIndicator.rest)

ZeroTradeReportMessageLongFormMessage ==
    [ messageInfo                      |-> ZeroMessageInfo2,
      finraTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      tradeId                          |-> [i \in 1 .. 8 |-> 0],
      tradePrice                       |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                      |-> [i \in 1 .. 4 |-> 0],
      saleCondition                    |-> ZeroSaleCondition2,
      tradeThroughExemptFlag           |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays                  |-> [i \in 1 .. 2 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      participantPriceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessageLongFormMessage ==
    { ZeroTradeReportMessageLongFormMessage }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo2 }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.saleCondition = one] : one \in CheckedSaleCondition2 }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessageLongFormMessage EXCEPT !.participantPriceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo3 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo3(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo3(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo3 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo3 ==
    { ZeroMessageInfo3 }
        \cup { [ZeroMessageInfo3 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo3 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo3 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo3 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo3 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition: 4 bytes                                        *)
(***************************************************************************)

OriginalSaleCondition ==
    [ level1 : Sample(1),
      level2 : Sample(1),
      level3 : Sample(1),
      level4 : Sample(1) ]

EncodeOriginalSaleCondition(message) ==
    message.level1
        \o message.level2
        \o message.level3
        \o message.level4

DecodeOriginalSaleCondition(bytes) ==
    LET level1 == ReadBytes(bytes, 1) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 1) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 1) IN IF ~level3.ok THEN Fail ELSE
    LET level4 == ReadBytes(level3.rest, 1) IN IF ~level4.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value,
         level4 |-> level4.value ], level4.rest)

ZeroOriginalSaleCondition ==
    [ level1 |-> [i \in 1 .. 1 |-> 0],
      level2 |-> [i \in 1 .. 1 |-> 0],
      level3 |-> [i \in 1 .. 1 |-> 0],
      level4 |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleCondition ==
    { ZeroOriginalSaleCondition }
        \cup { [ZeroOriginalSaleCondition EXCEPT !.level1 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleCondition EXCEPT !.level2 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleCondition EXCEPT !.level3 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleCondition EXCEPT !.level4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Error Message: 139 bytes                                   *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ messageInfo                      : MessageInfo3,
      finraTimestamp                   : Sample(8),
      symbolLong                       : Sample(11),
      tradeCancellationType            : Sample(1),
      originalTradeId                  : Sample(8),
      originalTradePrice               : Sample(8),
      originalVolume                   : Sample(4),
      originalSaleCondition            : OriginalSaleCondition,
      originalTradeThroughExemptFlag   : Sample(1),
      originalSellersSaleDays          : Sample(2),
      consolidatedHighPrice            : Sample(8),
      consolidatedLowPrice             : Sample(8),
      consolidatedLastPrice            : Sample(8),
      consolidatedVolume               : Sample(8),
      consolidatedPriceChangeIndicator : Sample(1),
      marketCenterOriginatorId         : Sample(1),
      marketParticipantHighPrice       : Sample(8),
      marketParticipantLowPrice        : Sample(8),
      marketParticipantLastPrice       : Sample(8),
      marketParticipantVolume          : Sample(8) ]

EncodeTradeCancelErrorMessage(message) ==
    EncodeMessageInfo3(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolLong
        \o message.tradeCancellationType
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalVolume
        \o EncodeOriginalSaleCondition(message.originalSaleCondition)
        \o message.originalTradeThroughExemptFlag
        \o message.originalSellersSaleDays
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedLastPrice
        \o message.consolidatedVolume
        \o message.consolidatedPriceChangeIndicator
        \o message.marketCenterOriginatorId
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice
        \o message.marketParticipantLastPrice
        \o message.marketParticipantVolume

DecodeTradeCancelErrorMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo3(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(finraTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeCancellationType == ReadBytes(symbolLong.rest, 1) IN IF ~tradeCancellationType.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(tradeCancellationType.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET originalSaleCondition == DecodeOriginalSaleCondition(originalVolume.rest) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradeThroughExemptFlag == ReadBytes(originalSaleCondition.rest, 1) IN IF ~originalTradeThroughExemptFlag.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeThroughExemptFlag.rest, 2) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(originalSellersSaleDays.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(marketCenterOriginatorId.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    LET marketParticipantLastPrice == ReadBytes(marketParticipantLowPrice.rest, 8) IN IF ~marketParticipantLastPrice.ok THEN Fail ELSE
    LET marketParticipantVolume == ReadBytes(marketParticipantLastPrice.rest, 8) IN IF ~marketParticipantVolume.ok THEN Fail ELSE
    Ok([ messageInfo                      |-> messageInfo.value,
         finraTimestamp                   |-> finraTimestamp.value,
         symbolLong                       |-> symbolLong.value,
         tradeCancellationType            |-> tradeCancellationType.value,
         originalTradeId                  |-> originalTradeId.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalVolume                   |-> originalVolume.value,
         originalSaleCondition            |-> originalSaleCondition.value,
         originalTradeThroughExemptFlag   |-> originalTradeThroughExemptFlag.value,
         originalSellersSaleDays          |-> originalSellersSaleDays.value,
         consolidatedHighPrice            |-> consolidatedHighPrice.value,
         consolidatedLowPrice             |-> consolidatedLowPrice.value,
         consolidatedLastPrice            |-> consolidatedLastPrice.value,
         consolidatedVolume               |-> consolidatedVolume.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         marketCenterOriginatorId         |-> marketCenterOriginatorId.value,
         marketParticipantHighPrice       |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice        |-> marketParticipantLowPrice.value,
         marketParticipantLastPrice       |-> marketParticipantLastPrice.value,
         marketParticipantVolume          |-> marketParticipantVolume.value ], marketParticipantVolume.rest)

ZeroTradeCancelErrorMessage ==
    [ messageInfo                      |-> ZeroMessageInfo3,
      finraTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      tradeCancellationType            |-> [i \in 1 .. 1 |-> 0],
      originalTradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 8 |-> 0],
      originalVolume                   |-> [i \in 1 .. 4 |-> 0],
      originalSaleCondition            |-> ZeroOriginalSaleCondition,
      originalTradeThroughExemptFlag   |-> [i \in 1 .. 1 |-> 0],
      originalSellersSaleDays          |-> [i \in 1 .. 2 |-> 0],
      consolidatedHighPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice             |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume               |-> [i \in 1 .. 8 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      marketCenterOriginatorId         |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice        |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLastPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantVolume          |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo3 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeCancellationType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSaleCondition = one] : one \in CheckedOriginalSaleCondition }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketParticipantVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo4 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo4(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo4(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo4 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo4 ==
    { ZeroMessageInfo4 }
        \cup { [ZeroMessageInfo4 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo4 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo4 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo4 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo4 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition: 4 bytes                                        *)
(***************************************************************************)

OriginalSaleCondition2 ==
    [ level1 : Sample(1),
      level2 : Sample(1),
      level3 : Sample(1),
      level4 : Sample(1) ]

EncodeOriginalSaleCondition2(message) ==
    message.level1
        \o message.level2
        \o message.level3
        \o message.level4

DecodeOriginalSaleCondition2(bytes) ==
    LET level1 == ReadBytes(bytes, 1) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 1) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 1) IN IF ~level3.ok THEN Fail ELSE
    LET level4 == ReadBytes(level3.rest, 1) IN IF ~level4.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value,
         level4 |-> level4.value ], level4.rest)

ZeroOriginalSaleCondition2 ==
    [ level1 |-> [i \in 1 .. 1 |-> 0],
      level2 |-> [i \in 1 .. 1 |-> 0],
      level3 |-> [i \in 1 .. 1 |-> 0],
      level4 |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleCondition2 ==
    { ZeroOriginalSaleCondition2 }
        \cup { [ZeroOriginalSaleCondition2 EXCEPT !.level1 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleCondition2 EXCEPT !.level2 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleCondition2 EXCEPT !.level3 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleCondition2 EXCEPT !.level4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Corrected Sale Condition: 4 bytes                                       *)
(***************************************************************************)

CorrectedSaleCondition ==
    [ level1 : Sample(1),
      level2 : Sample(1),
      level3 : Sample(1),
      level4 : Sample(1) ]

EncodeCorrectedSaleCondition(message) ==
    message.level1
        \o message.level2
        \o message.level3
        \o message.level4

DecodeCorrectedSaleCondition(bytes) ==
    LET level1 == ReadBytes(bytes, 1) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 1) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 1) IN IF ~level3.ok THEN Fail ELSE
    LET level4 == ReadBytes(level3.rest, 1) IN IF ~level4.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value,
         level4 |-> level4.value ], level4.rest)

ZeroCorrectedSaleCondition ==
    [ level1 |-> [i \in 1 .. 1 |-> 0],
      level2 |-> [i \in 1 .. 1 |-> 0],
      level3 |-> [i \in 1 .. 1 |-> 0],
      level4 |-> [i \in 1 .. 1 |-> 0] ]

(* Corrected Sale Condition at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedSaleCondition ==
    { ZeroCorrectedSaleCondition }
        \cup { [ZeroCorrectedSaleCondition EXCEPT !.level1 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleCondition EXCEPT !.level2 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleCondition EXCEPT !.level3 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleCondition EXCEPT !.level4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 165 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ messageInfo                      : MessageInfo4,
      finraTimestamp                   : Sample(8),
      symbolLong                       : Sample(11),
      originalTradeId                  : Sample(8),
      originalTradePrice               : Sample(8),
      originalVolume                   : Sample(4),
      originalSaleCondition            : OriginalSaleCondition2,
      originalTradeThroughExemptFlag   : Sample(1),
      originalSellersSaleDays          : Sample(2),
      correctedTradeId                 : Sample(8),
      correctedTradePrice              : Sample(8),
      correctedVolume                  : Sample(4),
      correctedSaleCondition           : CorrectedSaleCondition,
      correctedTradeThroughExemptFlag  : Sample(1),
      correctedSellersSaleDays         : Sample(2),
      consolidatedHighPrice            : Sample(8),
      consolidatedLowPrice             : Sample(8),
      consolidatedLastPrice            : Sample(8),
      consolidatedVolume               : Sample(8),
      consolidatedPriceChangeIndicator : Sample(1),
      marketCenterOriginatorId         : Sample(1),
      marketParticipantHighPrice       : Sample(8),
      marketParticipantLowPrice        : Sample(8),
      marketParticipantLastPrice       : Sample(8),
      marketParticipantVolume          : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    EncodeMessageInfo4(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolLong
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalVolume
        \o EncodeOriginalSaleCondition2(message.originalSaleCondition)
        \o message.originalTradeThroughExemptFlag
        \o message.originalSellersSaleDays
        \o message.correctedTradeId
        \o message.correctedTradePrice
        \o message.correctedVolume
        \o EncodeCorrectedSaleCondition(message.correctedSaleCondition)
        \o message.correctedTradeThroughExemptFlag
        \o message.correctedSellersSaleDays
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedLastPrice
        \o message.consolidatedVolume
        \o message.consolidatedPriceChangeIndicator
        \o message.marketCenterOriginatorId
        \o message.marketParticipantHighPrice
        \o message.marketParticipantLowPrice
        \o message.marketParticipantLastPrice
        \o message.marketParticipantVolume

DecodeTradeCorrectionMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo4(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(finraTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolLong.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET originalSaleCondition == DecodeOriginalSaleCondition2(originalVolume.rest) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradeThroughExemptFlag == ReadBytes(originalSaleCondition.rest, 1) IN IF ~originalTradeThroughExemptFlag.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeThroughExemptFlag.rest, 2) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET correctedTradeId == ReadBytes(originalSellersSaleDays.rest, 8) IN IF ~correctedTradeId.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeId.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedVolume == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedVolume.ok THEN Fail ELSE
    LET correctedSaleCondition == DecodeCorrectedSaleCondition(correctedVolume.rest) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradeThroughExemptFlag == ReadBytes(correctedSaleCondition.rest, 1) IN IF ~correctedTradeThroughExemptFlag.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedTradeThroughExemptFlag.rest, 2) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(correctedSellersSaleDays.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedPriceChangeIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~consolidatedPriceChangeIndicator.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(consolidatedPriceChangeIndicator.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET marketParticipantHighPrice == ReadBytes(marketCenterOriginatorId.rest, 8) IN IF ~marketParticipantHighPrice.ok THEN Fail ELSE
    LET marketParticipantLowPrice == ReadBytes(marketParticipantHighPrice.rest, 8) IN IF ~marketParticipantLowPrice.ok THEN Fail ELSE
    LET marketParticipantLastPrice == ReadBytes(marketParticipantLowPrice.rest, 8) IN IF ~marketParticipantLastPrice.ok THEN Fail ELSE
    LET marketParticipantVolume == ReadBytes(marketParticipantLastPrice.rest, 8) IN IF ~marketParticipantVolume.ok THEN Fail ELSE
    Ok([ messageInfo                      |-> messageInfo.value,
         finraTimestamp                   |-> finraTimestamp.value,
         symbolLong                       |-> symbolLong.value,
         originalTradeId                  |-> originalTradeId.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalVolume                   |-> originalVolume.value,
         originalSaleCondition            |-> originalSaleCondition.value,
         originalTradeThroughExemptFlag   |-> originalTradeThroughExemptFlag.value,
         originalSellersSaleDays          |-> originalSellersSaleDays.value,
         correctedTradeId                 |-> correctedTradeId.value,
         correctedTradePrice              |-> correctedTradePrice.value,
         correctedVolume                  |-> correctedVolume.value,
         correctedSaleCondition           |-> correctedSaleCondition.value,
         correctedTradeThroughExemptFlag  |-> correctedTradeThroughExemptFlag.value,
         correctedSellersSaleDays         |-> correctedSellersSaleDays.value,
         consolidatedHighPrice            |-> consolidatedHighPrice.value,
         consolidatedLowPrice             |-> consolidatedLowPrice.value,
         consolidatedLastPrice            |-> consolidatedLastPrice.value,
         consolidatedVolume               |-> consolidatedVolume.value,
         consolidatedPriceChangeIndicator |-> consolidatedPriceChangeIndicator.value,
         marketCenterOriginatorId         |-> marketCenterOriginatorId.value,
         marketParticipantHighPrice       |-> marketParticipantHighPrice.value,
         marketParticipantLowPrice        |-> marketParticipantLowPrice.value,
         marketParticipantLastPrice       |-> marketParticipantLastPrice.value,
         marketParticipantVolume          |-> marketParticipantVolume.value ], marketParticipantVolume.rest)

ZeroTradeCorrectionMessage ==
    [ messageInfo                      |-> ZeroMessageInfo4,
      finraTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      symbolLong                       |-> [i \in 1 .. 11 |-> 0],
      originalTradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 8 |-> 0],
      originalVolume                   |-> [i \in 1 .. 4 |-> 0],
      originalSaleCondition            |-> ZeroOriginalSaleCondition2,
      originalTradeThroughExemptFlag   |-> [i \in 1 .. 1 |-> 0],
      originalSellersSaleDays          |-> [i \in 1 .. 2 |-> 0],
      correctedTradeId                 |-> [i \in 1 .. 8 |-> 0],
      correctedTradePrice              |-> [i \in 1 .. 8 |-> 0],
      correctedVolume                  |-> [i \in 1 .. 4 |-> 0],
      correctedSaleCondition           |-> ZeroCorrectedSaleCondition,
      correctedTradeThroughExemptFlag  |-> [i \in 1 .. 1 |-> 0],
      correctedSellersSaleDays         |-> [i \in 1 .. 2 |-> 0],
      consolidatedHighPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice             |-> [i \in 1 .. 8 |-> 0],
      consolidatedLastPrice            |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume               |-> [i \in 1 .. 8 |-> 0],
      consolidatedPriceChangeIndicator |-> [i \in 1 .. 1 |-> 0],
      marketCenterOriginatorId         |-> [i \in 1 .. 1 |-> 0],
      marketParticipantHighPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLowPrice        |-> [i \in 1 .. 8 |-> 0],
      marketParticipantLastPrice       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantVolume          |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo4 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in CheckedOriginalSaleCondition2 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in CheckedCorrectedSaleCondition }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedPriceChangeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketParticipantVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo5 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo5(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo5(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo5 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo5 ==
    { ZeroMessageInfo5 }
        \cup { [ZeroMessageInfo5 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo5 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo5 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo5 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo5 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Sale Condition: 4 bytes                                                 *)
(***************************************************************************)

SaleCondition3 ==
    [ level1 : Sample(1),
      level2 : Sample(1),
      level3 : Sample(1),
      level4 : Sample(1) ]

EncodeSaleCondition3(message) ==
    message.level1
        \o message.level2
        \o message.level3
        \o message.level4

DecodeSaleCondition3(bytes) ==
    LET level1 == ReadBytes(bytes, 1) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 1) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 1) IN IF ~level3.ok THEN Fail ELSE
    LET level4 == ReadBytes(level3.rest, 1) IN IF ~level4.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value,
         level4 |-> level4.value ], level4.rest)

ZeroSaleCondition3 ==
    [ level1 |-> [i \in 1 .. 1 |-> 0],
      level2 |-> [i \in 1 .. 1 |-> 0],
      level3 |-> [i \in 1 .. 1 |-> 0],
      level4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition3 ==
    { ZeroSaleCondition3 }
        \cup { [ZeroSaleCondition3 EXCEPT !.level1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition3 EXCEPT !.level2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition3 EXCEPT !.level3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition3 EXCEPT !.level4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day As Of Trade Message: 81 bytes                                 *)
(***************************************************************************)

PriorDayAsOfTradeMessage ==
    [ messageInfo            : MessageInfo5,
      finraTimestamp         : Sample(8),
      symbolLong             : Sample(11),
      tradeId                : Sample(8),
      tradePrice             : Sample(8),
      tradeVolume            : Sample(4),
      saleCondition          : SaleCondition3,
      tradeThroughExemptFlag : Sample(1),
      sellersSaleDays        : Sample(2),
      asOfAction             : Sample(1),
      timestampOfTrade       : Sample(8) ]

EncodePriorDayAsOfTradeMessage(message) ==
    EncodeMessageInfo5(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolLong
        \o message.tradeId
        \o message.tradePrice
        \o message.tradeVolume
        \o EncodeSaleCondition3(message.saleCondition)
        \o message.tradeThroughExemptFlag
        \o message.sellersSaleDays
        \o message.asOfAction
        \o message.timestampOfTrade

DecodePriorDayAsOfTradeMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo5(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(finraTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeId.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET saleCondition == DecodeSaleCondition3(tradeVolume.rest) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradeThroughExemptFlag == ReadBytes(saleCondition.rest, 1) IN IF ~tradeThroughExemptFlag.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeThroughExemptFlag.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET asOfAction == ReadBytes(sellersSaleDays.rest, 1) IN IF ~asOfAction.ok THEN Fail ELSE
    LET timestampOfTrade == ReadBytes(asOfAction.rest, 8) IN IF ~timestampOfTrade.ok THEN Fail ELSE
    Ok([ messageInfo            |-> messageInfo.value,
         finraTimestamp         |-> finraTimestamp.value,
         symbolLong             |-> symbolLong.value,
         tradeId                |-> tradeId.value,
         tradePrice             |-> tradePrice.value,
         tradeVolume            |-> tradeVolume.value,
         saleCondition          |-> saleCondition.value,
         tradeThroughExemptFlag |-> tradeThroughExemptFlag.value,
         sellersSaleDays        |-> sellersSaleDays.value,
         asOfAction             |-> asOfAction.value,
         timestampOfTrade       |-> timestampOfTrade.value ], timestampOfTrade.rest)

ZeroPriorDayAsOfTradeMessage ==
    [ messageInfo            |-> ZeroMessageInfo5,
      finraTimestamp         |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradeId                |-> [i \in 1 .. 8 |-> 0],
      tradePrice             |-> [i \in 1 .. 8 |-> 0],
      tradeVolume            |-> [i \in 1 .. 4 |-> 0],
      saleCondition          |-> ZeroSaleCondition3,
      tradeThroughExemptFlag |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays        |-> [i \in 1 .. 2 |-> 0],
      asOfAction             |-> [i \in 1 .. 1 |-> 0],
      timestampOfTrade       |-> [i \in 1 .. 8 |-> 0] ]

(* Prior Day As Of Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayAsOfTradeMessage ==
    { ZeroPriorDayAsOfTradeMessage }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo5 }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.saleCondition = one] : one \in CheckedSaleCondition3 }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.tradeThroughExemptFlag = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.asOfAction = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayAsOfTradeMessage EXCEPT !.timestampOfTrade = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

TradeReportMessageShortFormMessageCode == 65  \* "A"
TradeReportMessageLongFormMessageCode == 87  \* "W"
TradeCancelErrorMessageCode == 90  \* "Z"
TradeCorrectionMessageCode == 89  \* "Y"
PriorDayAsOfTradeMessageCode == 72  \* "H"

TradeMessagePayload ==
    [ tag : {TradeReportMessageShortFormMessageCode}, body : TradeReportMessageShortFormMessage ]
        \cup [ tag : {TradeReportMessageLongFormMessageCode}, body : TradeReportMessageLongFormMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {PriorDayAsOfTradeMessageCode}, body : PriorDayAsOfTradeMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = TradeReportMessageShortFormMessageCode -> EncodeTradeReportMessageShortFormMessage(message.body)
      [] message.tag = TradeReportMessageLongFormMessageCode -> EncodeTradeReportMessageLongFormMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = PriorDayAsOfTradeMessageCode -> EncodePriorDayAsOfTradeMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeReportMessageShortFormMessageCode -> DecodeTradeReportMessageShortFormMessage(bytes)
              [] tag = TradeReportMessageLongFormMessageCode -> DecodeTradeReportMessageLongFormMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = PriorDayAsOfTradeMessageCode -> DecodePriorDayAsOfTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> TradeReportMessageShortFormMessageCode, body |-> ZeroTradeReportMessageShortFormMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> TradeReportMessageShortFormMessageCode, body |-> one] : one \in CheckedTradeReportMessageShortFormMessage }
        \cup { [tag |-> TradeReportMessageLongFormMessageCode, body |-> one] : one \in CheckedTradeReportMessageLongFormMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> PriorDayAsOfTradeMessageCode, body |-> one] : one \in CheckedPriorDayAsOfTradeMessage }

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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo6 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo6(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo6(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo6 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo6 ==
    { ZeroMessageInfo6 }
        \cup { [ZeroMessageInfo6 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo6 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo6 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo6 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo6 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ messageInfo : MessageInfo6,
      text        : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    EncodeMessageInfo6(message.messageInfo)
        \o EncodeUIntBE(Len(message.text), 2)
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo6(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET textLength == ReadUIntBE(messageInfo.rest, 2) IN IF ~textLength.ok THEN Fail ELSE
    LET text == ReadBytes(textLength.rest, textLength.value) IN IF ~text.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value,
         text        |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ messageInfo |-> ZeroMessageInfo6,
      text        |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo6 }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo7 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo7(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo7(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo7 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo7 ==
    { ZeroMessageInfo7 }
        \cup { [ZeroMessageInfo7 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo7 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo7 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo7 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo7 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Cross Sro Trading Action Message: 56 bytes                              *)
(***************************************************************************)

CrossSroTradingActionMessage ==
    [ messageInfo                 : MessageInfo7,
      symbolLong                  : Sample(11),
      tradingActionCode           : Sample(1),
      tradingActionSequenceNumber : Sample(4),
      actionTimestamp             : Sample(8),
      tradingActionReason         : Sample(6) ]

EncodeCrossSroTradingActionMessage(message) ==
    EncodeMessageInfo7(message.messageInfo)
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.tradingActionSequenceNumber
        \o message.actionTimestamp
        \o message.tradingActionReason

DecodeCrossSroTradingActionMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo7(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(tradingActionCode.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET actionTimestamp == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~actionTimestamp.ok THEN Fail ELSE
    LET tradingActionReason == ReadBytes(actionTimestamp.rest, 6) IN IF ~tradingActionReason.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionCode           |-> tradingActionCode.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         actionTimestamp             |-> actionTimestamp.value,
         tradingActionReason         |-> tradingActionReason.value ], tradingActionReason.rest)

ZeroCrossSroTradingActionMessage ==
    [ messageInfo                 |-> ZeroMessageInfo7,
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode           |-> [i \in 1 .. 1 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      actionTimestamp             |-> [i \in 1 .. 8 |-> 0],
      tradingActionReason         |-> [i \in 1 .. 6 |-> 0] ]

(* Cross Sro Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossSroTradingActionMessage ==
    { ZeroCrossSroTradingActionMessage }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo7 }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.actionTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionReason = one] : one \in Sample(6) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo8 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo8(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo8(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo8 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo8 ==
    { ZeroMessageInfo8 }
        \cup { [ZeroMessageInfo8 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo8 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo8 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo8 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo8 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Center Trading Action Message: 47 bytes                          *)
(***************************************************************************)

MarketCenterTradingActionMessage ==
    [ messageInfo            : MessageInfo8,
      symbolLong             : Sample(11),
      tradingActionCode      : Sample(1),
      actionTimestamp        : Sample(8),
      marketCenterIdentifier : Sample(1) ]

EncodeMarketCenterTradingActionMessage(message) ==
    EncodeMessageInfo8(message.messageInfo)
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.actionTimestamp
        \o message.marketCenterIdentifier

DecodeMarketCenterTradingActionMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo8(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET actionTimestamp == ReadBytes(tradingActionCode.rest, 8) IN IF ~actionTimestamp.ok THEN Fail ELSE
    LET marketCenterIdentifier == ReadBytes(actionTimestamp.rest, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    Ok([ messageInfo            |-> messageInfo.value,
         symbolLong             |-> symbolLong.value,
         tradingActionCode      |-> tradingActionCode.value,
         actionTimestamp        |-> actionTimestamp.value,
         marketCenterIdentifier |-> marketCenterIdentifier.value ], marketCenterIdentifier.rest)

ZeroMarketCenterTradingActionMessage ==
    [ messageInfo            |-> ZeroMessageInfo8,
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode      |-> [i \in 1 .. 1 |-> 0],
      actionTimestamp        |-> [i \in 1 .. 8 |-> 0],
      marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0] ]

(* Market Center Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterTradingActionMessage ==
    { ZeroMarketCenterTradingActionMessage }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo8 }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.actionTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo9 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo9(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo9(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo9 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo9 ==
    { ZeroMessageInfo9 }
        \cup { [ZeroMessageInfo9 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo9 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo9 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo9 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo9 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Issue Symbol Directory Message: 87 bytes                                *)
(***************************************************************************)

IssueSymbolDirectoryMessage ==
    [ messageInfo                 : MessageInfo9,
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
    EncodeMessageInfo9(message.messageInfo)
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
    LET messageInfo == DecodeMessageInfo9(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET oldSymbol == ReadBytes(symbolLong.rest, 11) IN IF ~oldSymbol.ok THEN Fail ELSE
    LET issueName == ReadBytes(oldSymbol.rest, 30) IN IF ~issueName.ok THEN Fail ELSE
    LET issueType == ReadBytes(issueName.rest, 1) IN IF ~issueType.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueType.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET marketTier == ReadBytes(issueSubtype.rest, 1) IN IF ~marketTier.ok THEN Fail ELSE
    LET authenticity == ReadBytes(marketTier.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(shortSaleThresholdIndicator.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
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
    [ messageInfo                 |-> ZeroMessageInfo9,
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
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo9 }
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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo10 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo10(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo10(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo10 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo10 ==
    { ZeroMessageInfo10 }
        \cup { [ZeroMessageInfo10 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo10 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo10 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo10 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo10 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Regulation Sho Short Sale Price Test Restricted Indicator Message: 32   *)
(* bytes                                                                   *)
(***************************************************************************)

RegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ messageInfo  : MessageInfo10,
      symbolShort  : Sample(5),
      regShoAction : Sample(1) ]

EncodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    EncodeMessageInfo10(message.messageInfo)
        \o message.symbolShort
        \o message.regShoAction

DecodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo10(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(messageInfo.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(symbolShort.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ messageInfo  |-> messageInfo.value,
         symbolShort  |-> symbolShort.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ messageInfo  |-> ZeroMessageInfo10,
      symbolShort  |-> [i \in 1 .. 5 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Regulation Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo10 }
        \cup { [ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo11 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo11(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo11(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo11 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo11 ==
    { ZeroMessageInfo11 }
        \cup { [ZeroMessageInfo11 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo11 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo11 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo11 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo11 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Limit Up Limit Down Price Band Message: 62 bytes                        *)
(***************************************************************************)

LimitUpLimitDownPriceBandMessage ==
    [ messageInfo            : MessageInfo11,
      symbolLong             : Sample(11),
      luldPriceBandIndicator : Sample(1),
      luldTimestamp          : Sample(8),
      limitDownPrice         : Sample(8),
      limitUpPrice           : Sample(8) ]

EncodeLimitUpLimitDownPriceBandMessage(message) ==
    EncodeMessageInfo11(message.messageInfo)
        \o message.symbolLong
        \o message.luldPriceBandIndicator
        \o message.luldTimestamp
        \o message.limitDownPrice
        \o message.limitUpPrice

DecodeLimitUpLimitDownPriceBandMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo11(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET luldPriceBandIndicator == ReadBytes(symbolLong.rest, 1) IN IF ~luldPriceBandIndicator.ok THEN Fail ELSE
    LET luldTimestamp == ReadBytes(luldPriceBandIndicator.rest, 8) IN IF ~luldTimestamp.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(luldTimestamp.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    Ok([ messageInfo            |-> messageInfo.value,
         symbolLong             |-> symbolLong.value,
         luldPriceBandIndicator |-> luldPriceBandIndicator.value,
         luldTimestamp          |-> luldTimestamp.value,
         limitDownPrice         |-> limitDownPrice.value,
         limitUpPrice           |-> limitUpPrice.value ], limitUpPrice.rest)

ZeroLimitUpLimitDownPriceBandMessage ==
    [ messageInfo            |-> ZeroMessageInfo11,
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      luldPriceBandIndicator |-> [i \in 1 .. 1 |-> 0],
      luldTimestamp          |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice         |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice           |-> [i \in 1 .. 8 |-> 0] ]

(* Limit Up Limit Down Price Band Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitUpLimitDownPriceBandMessage ==
    { ZeroLimitUpLimitDownPriceBandMessage }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo11 }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo12 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo12(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo12(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo12 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo12 ==
    { ZeroMessageInfo12 }
        \cup { [ZeroMessageInfo12 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo12 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo12 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo12 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo12 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Message: 50 bytes             *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelMessage ==
    [ messageInfo : MessageInfo12,
      mwcbLevel1  : Sample(8),
      mwcbLevel2  : Sample(8),
      mwcbLevel3  : Sample(8) ]

EncodeMarketWideCircuitBreakerDeclineLevelMessage(message) ==
    EncodeMessageInfo12(message.messageInfo)
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3

DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo12(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(messageInfo.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value,
         mwcbLevel1  |-> mwcbLevel1.value,
         mwcbLevel2  |-> mwcbLevel2.value,
         mwcbLevel3  |-> mwcbLevel3.value ], mwcbLevel3.rest)

ZeroMarketWideCircuitBreakerDeclineLevelMessage ==
    [ messageInfo |-> ZeroMessageInfo12,
      mwcbLevel1  |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2  |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3  |-> [i \in 1 .. 8 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo12 }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo13 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo13(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo13(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo13 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo13 ==
    { ZeroMessageInfo13 }
        \cup { [ZeroMessageInfo13 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo13 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo13 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo13 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo13 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Status Message: 27 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ messageInfo              : MessageInfo13,
      mwcbStatusLevelIndicator : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    EncodeMessageInfo13(message.messageInfo)
        \o message.mwcbStatusLevelIndicator

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo13(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET mwcbStatusLevelIndicator == ReadBytes(messageInfo.rest, 1) IN IF ~mwcbStatusLevelIndicator.ok THEN Fail ELSE
    Ok([ messageInfo              |-> messageInfo.value,
         mwcbStatusLevelIndicator |-> mwcbStatusLevelIndicator.value ], mwcbStatusLevelIndicator.rest)

ZeroMarketWideCircuitBreakerStatusMessage ==
    [ messageInfo              |-> ZeroMessageInfo13,
      mwcbStatusLevelIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo13 }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.mwcbStatusLevelIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo14 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo14(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo14(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo14 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo14 ==
    { ZeroMessageInfo14 }
        \cup { [ZeroMessageInfo14 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo14 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo14 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo14 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo14 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Collar Message: 66 bytes                                        *)
(***************************************************************************)

AuctionCollarMessage ==
    [ messageInfo                 : MessageInfo14,
      symbolLong                  : Sample(11),
      tradingActionSequenceNumber : Sample(4),
      collarReferencePrice        : Sample(8),
      collarUpPrice               : Sample(8),
      collarDownPrice             : Sample(8),
      collarExtensionIndicator    : Sample(1) ]

EncodeAuctionCollarMessage(message) ==
    EncodeMessageInfo14(message.messageInfo)
        \o message.symbolLong
        \o message.tradingActionSequenceNumber
        \o message.collarReferencePrice
        \o message.collarUpPrice
        \o message.collarDownPrice
        \o message.collarExtensionIndicator

DecodeAuctionCollarMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo14(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(symbolLong.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET collarUpPrice == ReadBytes(collarReferencePrice.rest, 8) IN IF ~collarUpPrice.ok THEN Fail ELSE
    LET collarDownPrice == ReadBytes(collarUpPrice.rest, 8) IN IF ~collarDownPrice.ok THEN Fail ELSE
    LET collarExtensionIndicator == ReadBytes(collarDownPrice.rest, 1) IN IF ~collarExtensionIndicator.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         collarReferencePrice        |-> collarReferencePrice.value,
         collarUpPrice               |-> collarUpPrice.value,
         collarDownPrice             |-> collarDownPrice.value,
         collarExtensionIndicator    |-> collarExtensionIndicator.value ], collarExtensionIndicator.rest)

ZeroAuctionCollarMessage ==
    [ messageInfo                 |-> ZeroMessageInfo14,
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      collarReferencePrice        |-> [i \in 1 .. 8 |-> 0],
      collarUpPrice               |-> [i \in 1 .. 8 |-> 0],
      collarDownPrice             |-> [i \in 1 .. 8 |-> 0],
      collarExtensionIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCollarMessage ==
    { ZeroAuctionCollarMessage }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo14 }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarExtensionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo15 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo15(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo15(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo15 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo15 ==
    { ZeroMessageInfo15 }
        \cup { [ZeroMessageInfo15 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo15 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo15 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo15 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo15 EXCEPT !.participantToken = one] : one \in Sample(8) }

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
    [ messageInfo                              : MessageInfo15,
      symbolLong                               : Sample(11),
      dailyConsolidatedHighPrice               : Sample(8),
      dailyConsolidatedLowPrice                : Sample(8),
      dailyConsolidatedClosingPrice            : Sample(8),
      marketCenterOriginatorId                 : Sample(1),
      consolidatedVolume                       : Sample(8),
      tradingActionIndicator                   : Sample(1),
      marketCenterClosingPriceAndVolumeSummary : SampleLists(OneMarketCenterClosingPriceAndVolumeSummary) ]

EncodeClosingTradeSummaryReportMessage(message) ==
    EncodeMessageInfo15(message.messageInfo)
        \o message.symbolLong
        \o message.dailyConsolidatedHighPrice
        \o message.dailyConsolidatedLowPrice
        \o message.dailyConsolidatedClosingPrice
        \o message.marketCenterOriginatorId
        \o message.consolidatedVolume
        \o message.tradingActionIndicator
        \o EncodeUIntBE(Len(message.marketCenterClosingPriceAndVolumeSummary), 2)
        \o EncodeMarketCenterClosingPriceAndVolumeSummaryList(message.marketCenterClosingPriceAndVolumeSummary)

DecodeClosingTradeSummaryReportMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo15(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET dailyConsolidatedHighPrice == ReadBytes(symbolLong.rest, 8) IN IF ~dailyConsolidatedHighPrice.ok THEN Fail ELSE
    LET dailyConsolidatedLowPrice == ReadBytes(dailyConsolidatedHighPrice.rest, 8) IN IF ~dailyConsolidatedLowPrice.ok THEN Fail ELSE
    LET dailyConsolidatedClosingPrice == ReadBytes(dailyConsolidatedLowPrice.rest, 8) IN IF ~dailyConsolidatedClosingPrice.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(dailyConsolidatedClosingPrice.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(marketCenterOriginatorId.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET tradingActionIndicator == ReadBytes(consolidatedVolume.rest, 1) IN IF ~tradingActionIndicator.ok THEN Fail ELSE
    LET numberOfMarketCenterSummaries == ReadUIntBE(tradingActionIndicator.rest, 2) IN IF ~numberOfMarketCenterSummaries.ok THEN Fail ELSE
    LET marketCenterClosingPriceAndVolumeSummary == ReadMarketCenterClosingPriceAndVolumeSummaryList(numberOfMarketCenterSummaries.rest, numberOfMarketCenterSummaries.value) IN IF ~marketCenterClosingPriceAndVolumeSummary.ok THEN Fail ELSE
    Ok([ messageInfo                              |-> messageInfo.value,
         symbolLong                               |-> symbolLong.value,
         dailyConsolidatedHighPrice               |-> dailyConsolidatedHighPrice.value,
         dailyConsolidatedLowPrice                |-> dailyConsolidatedLowPrice.value,
         dailyConsolidatedClosingPrice            |-> dailyConsolidatedClosingPrice.value,
         marketCenterOriginatorId                 |-> marketCenterOriginatorId.value,
         consolidatedVolume                       |-> consolidatedVolume.value,
         tradingActionIndicator                   |-> tradingActionIndicator.value,
         marketCenterClosingPriceAndVolumeSummary |-> marketCenterClosingPriceAndVolumeSummary.value ], marketCenterClosingPriceAndVolumeSummary.rest)

ZeroClosingTradeSummaryReportMessage ==
    [ messageInfo                              |-> ZeroMessageInfo15,
      symbolLong                               |-> [i \in 1 .. 11 |-> 0],
      dailyConsolidatedHighPrice               |-> [i \in 1 .. 8 |-> 0],
      dailyConsolidatedLowPrice                |-> [i \in 1 .. 8 |-> 0],
      dailyConsolidatedClosingPrice            |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId                 |-> [i \in 1 .. 1 |-> 0],
      consolidatedVolume                       |-> [i \in 1 .. 8 |-> 0],
      tradingActionIndicator                   |-> [i \in 1 .. 1 |-> 0],
      marketCenterClosingPriceAndVolumeSummary |-> << >> ]

(* Closing Trade Summary Report Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingTradeSummaryReportMessage ==
    { ZeroClosingTradeSummaryReportMessage }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo15 }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyConsolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyConsolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyConsolidatedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
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
RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode == 86  \* "V"
LimitUpLimitDownPriceBandMessageCode == 80  \* "P"
MarketWideCircuitBreakerDeclineLevelMessageCode == 67  \* "C"
MarketWideCircuitBreakerStatusMessageCode == 68  \* "D"
AuctionCollarMessageCode == 69  \* "E"
ClosingTradeSummaryReportMessageCode == 90  \* "Z"

AdministrativeMessagePayload ==
    [ tag : {GeneralAdministrativeMessageCode}, body : GeneralAdministrativeMessage ]
        \cup [ tag : {CrossSroTradingActionMessageCode}, body : CrossSroTradingActionMessage ]
        \cup [ tag : {MarketCenterTradingActionMessageCode}, body : MarketCenterTradingActionMessage ]
        \cup [ tag : {IssueSymbolDirectoryMessageCode}, body : IssueSymbolDirectoryMessage ]
        \cup [ tag : {RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegulationShoShortSalePriceTestRestrictedIndicatorMessage ]
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
      [] message.tag = RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
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
              [] tag = RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
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
        \cup { [tag |-> RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegulationShoShortSalePriceTestRestrictedIndicatorMessage }
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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo16 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo16(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo16(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo16 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo16 ==
    { ZeroMessageInfo16 }
        \cup { [ZeroMessageInfo16 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo16 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo16 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo16 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo16 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Center Volume Attachment: 9 bytes                                *)
(***************************************************************************)

MarketCenterVolumeAttachment ==
    [ marketCenterIdentifier    : Sample(1),
      currentMarketCenterVolume : Sample(8) ]

EncodeMarketCenterVolumeAttachment(message) ==
    message.marketCenterIdentifier
        \o message.currentMarketCenterVolume

DecodeMarketCenterVolumeAttachment(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET currentMarketCenterVolume == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~currentMarketCenterVolume.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier    |-> marketCenterIdentifier.value,
         currentMarketCenterVolume |-> currentMarketCenterVolume.value ], currentMarketCenterVolume.rest)

ZeroMarketCenterVolumeAttachment ==
    [ marketCenterIdentifier    |-> [i \in 1 .. 1 |-> 0],
      currentMarketCenterVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Market Center Volume Attachment at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterVolumeAttachment ==
    { ZeroMarketCenterVolumeAttachment }
        \cup { [ZeroMarketCenterVolumeAttachment EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterVolumeAttachment EXCEPT !.currentMarketCenterVolume = one] : one \in Sample(8) }

(* A run of Market Center Volume Attachment, written one after another *)
RECURSIVE EncodeMarketCenterVolumeAttachmentList(_)
EncodeMarketCenterVolumeAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketCenterVolumeAttachment(Head(messages)) \o EncodeMarketCenterVolumeAttachmentList(Tail(messages))

(* As many Market Center Volume Attachment as the field that counts them says *)
RECURSIVE ReadMarketCenterVolumeAttachmentList(_, _)
ReadMarketCenterVolumeAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketCenterVolumeAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketCenterVolumeAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Center Volume Attachment of each kind, for the lists that carry them *)
OneMarketCenterVolumeAttachment == { ZeroMarketCenterVolumeAttachment }

(***************************************************************************)
(* Total Consolidated And Market Center Volume Message                     *)
(***************************************************************************)

TotalConsolidatedAndMarketCenterVolumeMessage ==
    [ messageInfo                  : MessageInfo16,
      totalConsolidatedVolume      : Sample(8),
      marketCenterVolumeAttachment : SampleLists(OneMarketCenterVolumeAttachment) ]

EncodeTotalConsolidatedAndMarketCenterVolumeMessage(message) ==
    EncodeMessageInfo16(message.messageInfo)
        \o message.totalConsolidatedVolume
        \o EncodeUIntBE(Len(message.marketCenterVolumeAttachment), 2)
        \o EncodeMarketCenterVolumeAttachmentList(message.marketCenterVolumeAttachment)

DecodeTotalConsolidatedAndMarketCenterVolumeMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo16(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET totalConsolidatedVolume == ReadBytes(messageInfo.rest, 8) IN IF ~totalConsolidatedVolume.ok THEN Fail ELSE
    LET numberOfMarketCenterVolumes == ReadUIntBE(totalConsolidatedVolume.rest, 2) IN IF ~numberOfMarketCenterVolumes.ok THEN Fail ELSE
    LET marketCenterVolumeAttachment == ReadMarketCenterVolumeAttachmentList(numberOfMarketCenterVolumes.rest, numberOfMarketCenterVolumes.value) IN IF ~marketCenterVolumeAttachment.ok THEN Fail ELSE
    Ok([ messageInfo                  |-> messageInfo.value,
         totalConsolidatedVolume      |-> totalConsolidatedVolume.value,
         marketCenterVolumeAttachment |-> marketCenterVolumeAttachment.value ], marketCenterVolumeAttachment.rest)

ZeroTotalConsolidatedAndMarketCenterVolumeMessage ==
    [ messageInfo                  |-> ZeroMessageInfo16,
      totalConsolidatedVolume      |-> [i \in 1 .. 8 |-> 0],
      marketCenterVolumeAttachment |-> << >> ]

(* Total Consolidated And Market Center Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedTotalConsolidatedAndMarketCenterVolumeMessage ==
    { ZeroTotalConsolidatedAndMarketCenterVolumeMessage }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo16 }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.totalConsolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTotalConsolidatedAndMarketCenterVolumeMessage EXCEPT !.marketCenterVolumeAttachment = one] : one \in SampleLists(OneMarketCenterVolumeAttachment) }

(***************************************************************************)
(* Volume Message Payload, selected by Volume Message Type                 *)
(***************************************************************************)

TotalConsolidatedAndMarketCenterVolumeMessageCode == 77  \* "M"

VolumeMessagePayload ==
    [ tag : {TotalConsolidatedAndMarketCenterVolumeMessageCode}, body : TotalConsolidatedAndMarketCenterVolumeMessage ]

EncodeVolumeMessagePayload(message) ==
    CASE message.tag = TotalConsolidatedAndMarketCenterVolumeMessageCode -> EncodeTotalConsolidatedAndMarketCenterVolumeMessage(message.body)

DecodeVolumeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TotalConsolidatedAndMarketCenterVolumeMessageCode -> DecodeTotalConsolidatedAndMarketCenterVolumeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroVolumeMessagePayload == [tag |-> TotalConsolidatedAndMarketCenterVolumeMessageCode, body |-> ZeroTotalConsolidatedAndMarketCenterVolumeMessage]

(* Each Volume Message Payload in turn, at the values the message it names is checked at *)
CheckedVolumeMessagePayload ==
    { [tag |-> TotalConsolidatedAndMarketCenterVolumeMessageCode, body |-> one] : one \in CheckedTotalConsolidatedAndMarketCenterVolumeMessage }

(***************************************************************************)
(* Volume Message                                                          *)
(***************************************************************************)

VolumeMessage ==
    [ volumeMessagePayload : VolumeMessagePayload ]

EncodeVolumeMessage(message) ==
    EncodeUIntBE(message.volumeMessagePayload.tag, 1)
        \o EncodeVolumeMessagePayload(message.volumeMessagePayload)

DecodeVolumeMessage(bytes) ==
    LET volumeMessageType == ReadUIntBE(bytes, 1) IN IF ~volumeMessageType.ok THEN Fail ELSE
    LET volumeMessagePayload == DecodeVolumeMessagePayload(volumeMessageType.value, volumeMessageType.rest) IN IF ~volumeMessagePayload.ok THEN Fail ELSE
    Ok([ volumeMessagePayload |-> volumeMessagePayload.value ], volumeMessagePayload.rest)

ZeroVolumeMessage ==
    [ volumeMessagePayload |-> ZeroVolumeMessagePayload ]

(* Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedVolumeMessage ==
    { ZeroVolumeMessage }
        \cup { [ZeroVolumeMessage EXCEPT !.volumeMessagePayload = one] : one \in CheckedVolumeMessagePayload }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo17 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo17(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo17(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo17 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo17 ==
    { ZeroMessageInfo17 }
        \cup { [ZeroMessageInfo17 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo17 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo17 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo17 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo17 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Start Of Day Message: 26 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ messageInfo : MessageInfo17 ]

EncodeStartOfDayMessage(message) ==
    EncodeMessageInfo17(message.messageInfo)

DecodeStartOfDayMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo17(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroStartOfDayMessage ==
    [ messageInfo |-> ZeroMessageInfo17 ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo17 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo18 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo18(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo18(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo18 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo18 ==
    { ZeroMessageInfo18 }
        \cup { [ZeroMessageInfo18 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo18 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo18 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo18 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo18 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Message: 26 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ messageInfo : MessageInfo18 ]

EncodeEndOfDayMessage(message) ==
    EncodeMessageInfo18(message.messageInfo)

DecodeEndOfDayMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo18(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroEndOfDayMessage ==
    [ messageInfo |-> ZeroMessageInfo18 ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo18 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo19 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo19(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo19(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo19 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo19 ==
    { ZeroMessageInfo19 }
        \cup { [ZeroMessageInfo19 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo19 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo19 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo19 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo19 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Open Message: 26 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ messageInfo : MessageInfo19 ]

EncodeMarketSessionOpenMessage(message) ==
    EncodeMessageInfo19(message.messageInfo)

DecodeMarketSessionOpenMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo19(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroMarketSessionOpenMessage ==
    [ messageInfo |-> ZeroMessageInfo19 ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo19 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo20 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo20(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo20(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo20 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo20 ==
    { ZeroMessageInfo20 }
        \cup { [ZeroMessageInfo20 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo20 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo20 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo20 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo20 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Close Message: 26 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ messageInfo : MessageInfo20 ]

EncodeMarketSessionCloseMessage(message) ==
    EncodeMessageInfo20(message.messageInfo)

DecodeMarketSessionCloseMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo20(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroMarketSessionCloseMessage ==
    [ messageInfo |-> ZeroMessageInfo20 ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo20 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo21 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo21(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo21(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo21 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo21 ==
    { ZeroMessageInfo21 }
        \cup { [ZeroMessageInfo21 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo21 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo21 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo21 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo21 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Transmissions Message: 26 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ messageInfo : MessageInfo21 ]

EncodeEndOfTransmissionsMessage(message) ==
    EncodeMessageInfo21(message.messageInfo)

DecodeEndOfTransmissionsMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo21(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroEndOfTransmissionsMessage ==
    [ messageInfo |-> ZeroMessageInfo21 ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo21 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo22 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo22(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo22(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo22 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo22 ==
    { ZeroMessageInfo22 }
        \cup { [ZeroMessageInfo22 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo22 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo22 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo22 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo22 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Trade Reporting Message: 26 bytes                                *)
(***************************************************************************)

EndOfTradeReportingMessage ==
    [ messageInfo : MessageInfo22 ]

EncodeEndOfTradeReportingMessage(message) ==
    EncodeMessageInfo22(message.messageInfo)

DecodeEndOfTradeReportingMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo22(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroEndOfTradeReportingMessage ==
    [ messageInfo |-> ZeroMessageInfo22 ]

(* End Of Trade Reporting Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTradeReportingMessage ==
    { ZeroEndOfTradeReportingMessage }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo22 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo23 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo23(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo23(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo23 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo23 ==
    { ZeroMessageInfo23 }
        \cup { [ZeroMessageInfo23 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo23 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo23 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo23 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo23 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Consolidated Last Sale Eligibility: 26 bytes                     *)
(***************************************************************************)

EndOfConsolidatedLastSaleEligibility ==
    [ messageInfo : MessageInfo23 ]

EncodeEndOfConsolidatedLastSaleEligibility(message) ==
    EncodeMessageInfo23(message.messageInfo)

DecodeEndOfConsolidatedLastSaleEligibility(bytes) ==
    LET messageInfo == DecodeMessageInfo23(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroEndOfConsolidatedLastSaleEligibility ==
    [ messageInfo |-> ZeroMessageInfo23 ]

(* End Of Consolidated Last Sale Eligibility at zero, then each field in turn at the values it is checked at *)
CheckedEndOfConsolidatedLastSaleEligibility ==
    { ZeroEndOfConsolidatedLastSaleEligibility }
        \cup { [ZeroEndOfConsolidatedLastSaleEligibility EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo23 }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 73  \* "I"
EndOfDayMessageCode == 74  \* "J"
MarketSessionOpenMessageCode == 79  \* "O"
MarketSessionCloseMessageCode == 67  \* "C"
EndOfTransmissionsMessageCode == 90  \* "Z"
EndOfTradeReportingMessageCode == 88  \* "X"
EndOfConsolidatedLastSaleEligibilityCode == 83  \* "S"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {MarketSessionOpenMessageCode}, body : MarketSessionOpenMessage ]
        \cup [ tag : {MarketSessionCloseMessageCode}, body : MarketSessionCloseMessage ]
        \cup [ tag : {EndOfTransmissionsMessageCode}, body : EndOfTransmissionsMessage ]
        \cup [ tag : {EndOfTradeReportingMessageCode}, body : EndOfTradeReportingMessage ]
        \cup [ tag : {EndOfConsolidatedLastSaleEligibilityCode}, body : EndOfConsolidatedLastSaleEligibility ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = MarketSessionOpenMessageCode -> EncodeMarketSessionOpenMessage(message.body)
      [] message.tag = MarketSessionCloseMessageCode -> EncodeMarketSessionCloseMessage(message.body)
      [] message.tag = EndOfTransmissionsMessageCode -> EncodeEndOfTransmissionsMessage(message.body)
      [] message.tag = EndOfTradeReportingMessageCode -> EncodeEndOfTradeReportingMessage(message.body)
      [] message.tag = EndOfConsolidatedLastSaleEligibilityCode -> EncodeEndOfConsolidatedLastSaleEligibility(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = MarketSessionOpenMessageCode -> DecodeMarketSessionOpenMessage(bytes)
              [] tag = MarketSessionCloseMessageCode -> DecodeMarketSessionCloseMessage(bytes)
              [] tag = EndOfTransmissionsMessageCode -> DecodeEndOfTransmissionsMessage(bytes)
              [] tag = EndOfTradeReportingMessageCode -> DecodeEndOfTradeReportingMessage(bytes)
              [] tag = EndOfConsolidatedLastSaleEligibilityCode -> DecodeEndOfConsolidatedLastSaleEligibility(bytes)
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
        \cup { [tag |-> EndOfConsolidatedLastSaleEligibilityCode, body |-> one] : one \in CheckedEndOfConsolidatedLastSaleEligibility }

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
(* Payload, selected by Message Category                                   *)
(***************************************************************************)

TradeMessageCode == 84  \* "T"
AdministrativeMessageCode == 65  \* "A"
VolumeMessageCode == 86  \* "V"
ControlMessageCode == 67  \* "C"

Payload ==
    [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {VolumeMessageCode}, body : VolumeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = VolumeMessageCode -> EncodeVolumeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = VolumeMessageCode -> DecodeVolumeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> VolumeMessageCode, body |-> one] : one \in CheckedVolumeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ version : Sample(1),
      payload : Payload ]

EncodeMessageBody(message) ==
    message.version
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(version.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET payload == DecodePayload(messageCategory.value, messageCategory.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ version |-> version.value,
         payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ version |-> [i \in 1 .. 1 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(1) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> VolumeMessageCode, body |-> ZeroVolumeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session  : Sample(10),
      sequence : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntBE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session  |-> session.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ session  |-> [i \in 1 .. 10 |-> 0],
      sequence |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(8) }
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo ==
    \A message \in CheckedMessageInfo :
        LET read == DecodeMessageInfo(EncodeMessageInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition ==
    \A message \in CheckedSaleCondition :
        LET read == DecodeSaleCondition(EncodeSaleCondition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessageShortFormMessage ==
    \A message \in CheckedTradeReportMessageShortFormMessage :
        LET read == DecodeTradeReportMessageShortFormMessage(EncodeTradeReportMessageShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo2 ==
    \A message \in CheckedMessageInfo2 :
        LET read == DecodeMessageInfo2(EncodeMessageInfo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition2 ==
    \A message \in CheckedSaleCondition2 :
        LET read == DecodeSaleCondition2(EncodeSaleCondition2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessageLongFormMessage ==
    \A message \in CheckedTradeReportMessageLongFormMessage :
        LET read == DecodeTradeReportMessageLongFormMessage(EncodeTradeReportMessageLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo3 ==
    \A message \in CheckedMessageInfo3 :
        LET read == DecodeMessageInfo3(EncodeMessageInfo3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Sale Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleCondition ==
    \A message \in CheckedOriginalSaleCondition :
        LET read == DecodeOriginalSaleCondition(EncodeOriginalSaleCondition(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo4 ==
    \A message \in CheckedMessageInfo4 :
        LET read == DecodeMessageInfo4(EncodeMessageInfo4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Sale Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleCondition2 ==
    \A message \in CheckedOriginalSaleCondition2 :
        LET read == DecodeOriginalSaleCondition2(EncodeOriginalSaleCondition2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Sale Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedSaleCondition ==
    \A message \in CheckedCorrectedSaleCondition :
        LET read == DecodeCorrectedSaleCondition(EncodeCorrectedSaleCondition(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo5 ==
    \A message \in CheckedMessageInfo5 :
        LET read == DecodeMessageInfo5(EncodeMessageInfo5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition3 ==
    \A message \in CheckedSaleCondition3 :
        LET read == DecodeSaleCondition3(EncodeSaleCondition3(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo6 ==
    \A message \in CheckedMessageInfo6 :
        LET read == DecodeMessageInfo6(EncodeMessageInfo6(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo7 ==
    \A message \in CheckedMessageInfo7 :
        LET read == DecodeMessageInfo7(EncodeMessageInfo7(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo8 ==
    \A message \in CheckedMessageInfo8 :
        LET read == DecodeMessageInfo8(EncodeMessageInfo8(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo9 ==
    \A message \in CheckedMessageInfo9 :
        LET read == DecodeMessageInfo9(EncodeMessageInfo9(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo10 ==
    \A message \in CheckedMessageInfo10 :
        LET read == DecodeMessageInfo10(EncodeMessageInfo10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regulation Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegulationShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo11 ==
    \A message \in CheckedMessageInfo11 :
        LET read == DecodeMessageInfo11(EncodeMessageInfo11(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo12 ==
    \A message \in CheckedMessageInfo12 :
        LET read == DecodeMessageInfo12(EncodeMessageInfo12(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo13 ==
    \A message \in CheckedMessageInfo13 :
        LET read == DecodeMessageInfo13(EncodeMessageInfo13(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo14 ==
    \A message \in CheckedMessageInfo14 :
        LET read == DecodeMessageInfo14(EncodeMessageInfo14(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo15 ==
    \A message \in CheckedMessageInfo15 :
        LET read == DecodeMessageInfo15(EncodeMessageInfo15(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo16 ==
    \A message \in CheckedMessageInfo16 :
        LET read == DecodeMessageInfo16(EncodeMessageInfo16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Volume Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterVolumeAttachment ==
    \A message \in CheckedMarketCenterVolumeAttachment :
        LET read == DecodeMarketCenterVolumeAttachment(EncodeMarketCenterVolumeAttachment(message))
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

(* Every Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVolumeMessage ==
    \A message \in CheckedVolumeMessage :
        LET read == DecodeVolumeMessage(EncodeVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo17 ==
    \A message \in CheckedMessageInfo17 :
        LET read == DecodeMessageInfo17(EncodeMessageInfo17(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo18 ==
    \A message \in CheckedMessageInfo18 :
        LET read == DecodeMessageInfo18(EncodeMessageInfo18(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo19 ==
    \A message \in CheckedMessageInfo19 :
        LET read == DecodeMessageInfo19(EncodeMessageInfo19(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo20 ==
    \A message \in CheckedMessageInfo20 :
        LET read == DecodeMessageInfo20(EncodeMessageInfo20(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo21 ==
    \A message \in CheckedMessageInfo21 :
        LET read == DecodeMessageInfo21(EncodeMessageInfo21(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo22 ==
    \A message \in CheckedMessageInfo22 :
        LET read == DecodeMessageInfo22(EncodeMessageInfo22(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo23 ==
    \A message \in CheckedMessageInfo23 :
        LET read == DecodeMessageInfo23(EncodeMessageInfo23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Consolidated Last Sale Eligibility decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfConsolidatedLastSaleEligibility ==
    \A message \in CheckedEndOfConsolidatedLastSaleEligibility :
        LET read == DecodeEndOfConsolidatedLastSaleEligibility(EncodeEndOfConsolidatedLastSaleEligibility(message))
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

(* A Volume Message Payload is selected by the Volume Message Type it is written under *)
SelectsVolumeMessagePayload ==
    \A message \in CheckedVolumeMessagePayload :
        LET read == DecodeVolumeMessagePayload(message.tag, EncodeVolumeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Control Message Payload is selected by the Control Message Type it is written under *)
SelectsControlMessagePayload ==
    \A message \in CheckedControlMessagePayload :
        LET read == DecodeControlMessagePayload(message.tag, EncodeControlMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Category it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
