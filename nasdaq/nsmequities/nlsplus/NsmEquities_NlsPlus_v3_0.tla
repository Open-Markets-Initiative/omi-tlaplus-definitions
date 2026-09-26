--------------------- MODULE NsmEquities_NlsPlus_v3_0 ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Last Sale Plus v3.0                                            *)
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
(* System Event Message: 1 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET eventCode == ReadBytes(bytes, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Sale Condition Modifier: 4 bytes                                        *)
(***************************************************************************)

SaleConditionModifier ==
    [ settlementType          : Sample(1),
      tradeThroughExemption   : Sample(1),
      extendedHoursOrSoldCode : Sample(1),
      specialSaleCondition    : Sample(1) ]

EncodeSaleConditionModifier(message) ==
    message.settlementType
        \o message.tradeThroughExemption
        \o message.extendedHoursOrSoldCode
        \o message.specialSaleCondition

DecodeSaleConditionModifier(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemption == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemption.ok THEN Fail ELSE
    LET extendedHoursOrSoldCode == ReadBytes(tradeThroughExemption.rest, 1) IN IF ~extendedHoursOrSoldCode.ok THEN Fail ELSE
    LET specialSaleCondition == ReadBytes(extendedHoursOrSoldCode.rest, 1) IN IF ~specialSaleCondition.ok THEN Fail ELSE
    Ok([ settlementType          |-> settlementType.value,
         tradeThroughExemption   |-> tradeThroughExemption.value,
         extendedHoursOrSoldCode |-> extendedHoursOrSoldCode.value,
         specialSaleCondition    |-> specialSaleCondition.value ], specialSaleCondition.rest)

ZeroSaleConditionModifier ==
    [ settlementType          |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      specialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditionModifier ==
    { ZeroSaleConditionModifier }
        \cup { [ZeroSaleConditionModifier EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier EXCEPT !.tradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier EXCEPT !.extendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier EXCEPT !.specialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message: 40 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      tradeControlNumber                : Sample(10),
      tradePrice                        : Sample(4),
      tradeSize                         : Sample(4),
      saleConditionModifier             : SaleConditionModifier,
      consolidatedVolume                : Sample(8) ]

EncodeTradeReportMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.tradePrice
        \o message.tradeSize
        \o EncodeSaleConditionModifier(message.saleConditionModifier)
        \o message.consolidatedVolume

DecodeTradeReportMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeControlNumber.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET saleConditionModifier == DecodeSaleConditionModifier(tradeSize.rest) IN IF ~saleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(saleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         tradeControlNumber                |-> tradeControlNumber.value,
         tradePrice                        |-> tradePrice.value,
         tradeSize                         |-> tradeSize.value,
         saleConditionModifier             |-> saleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroTradeReportMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber                |-> [i \in 1 .. 10 |-> 0],
      tradePrice                        |-> [i \in 1 .. 4 |-> 0],
      tradeSize                         |-> [i \in 1 .. 4 |-> 0],
      saleConditionModifier             |-> ZeroSaleConditionModifier,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifier = one] : one \in CheckedSaleConditionModifier }
        \cup { [ZeroTradeReportMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Sale Condition Modifier: 4 bytes                                        *)
(***************************************************************************)

SaleConditionModifier2 ==
    [ settlementType          : Sample(1),
      tradeThroughExemption   : Sample(1),
      extendedHoursOrSoldCode : Sample(1),
      specialSaleCondition    : Sample(1) ]

EncodeSaleConditionModifier2(message) ==
    message.settlementType
        \o message.tradeThroughExemption
        \o message.extendedHoursOrSoldCode
        \o message.specialSaleCondition

DecodeSaleConditionModifier2(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemption == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemption.ok THEN Fail ELSE
    LET extendedHoursOrSoldCode == ReadBytes(tradeThroughExemption.rest, 1) IN IF ~extendedHoursOrSoldCode.ok THEN Fail ELSE
    LET specialSaleCondition == ReadBytes(extendedHoursOrSoldCode.rest, 1) IN IF ~specialSaleCondition.ok THEN Fail ELSE
    Ok([ settlementType          |-> settlementType.value,
         tradeThroughExemption   |-> tradeThroughExemption.value,
         extendedHoursOrSoldCode |-> extendedHoursOrSoldCode.value,
         specialSaleCondition    |-> specialSaleCondition.value ], specialSaleCondition.rest)

ZeroSaleConditionModifier2 ==
    [ settlementType          |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      specialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditionModifier2 ==
    { ZeroSaleConditionModifier2 }
        \cup { [ZeroSaleConditionModifier2 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier2 EXCEPT !.tradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier2 EXCEPT !.extendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier2 EXCEPT !.specialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Form Trade Report Message: 44 bytes                                *)
(***************************************************************************)

LongFormTradeReportMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      tradeControlNumber                : Sample(10),
      tradePriceLong                    : Sample(8),
      tradeSize                         : Sample(4),
      saleConditionModifier             : SaleConditionModifier2,
      consolidatedVolume                : Sample(8) ]

EncodeLongFormTradeReportMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.tradePriceLong
        \o message.tradeSize
        \o EncodeSaleConditionModifier2(message.saleConditionModifier)
        \o message.consolidatedVolume

DecodeLongFormTradeReportMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET tradePriceLong == ReadBytes(tradeControlNumber.rest, 8) IN IF ~tradePriceLong.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePriceLong.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET saleConditionModifier == DecodeSaleConditionModifier2(tradeSize.rest) IN IF ~saleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(saleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         tradeControlNumber                |-> tradeControlNumber.value,
         tradePriceLong                    |-> tradePriceLong.value,
         tradeSize                         |-> tradeSize.value,
         saleConditionModifier             |-> saleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroLongFormTradeReportMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber                |-> [i \in 1 .. 10 |-> 0],
      tradePriceLong                    |-> [i \in 1 .. 8 |-> 0],
      tradeSize                         |-> [i \in 1 .. 4 |-> 0],
      saleConditionModifier             |-> ZeroSaleConditionModifier2,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Long Form Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormTradeReportMessage ==
    { ZeroLongFormTradeReportMessage }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.tradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.saleConditionModifier = one] : one \in CheckedSaleConditionModifier2 }
        \cup { [ZeroLongFormTradeReportMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Sale Condition Modifier: 4 bytes                                        *)
(***************************************************************************)

SaleConditionModifier3 ==
    [ settlementType          : Sample(1),
      tradeThroughExemption   : Sample(1),
      extendedHoursOrSoldCode : Sample(1),
      specialSaleCondition    : Sample(1) ]

EncodeSaleConditionModifier3(message) ==
    message.settlementType
        \o message.tradeThroughExemption
        \o message.extendedHoursOrSoldCode
        \o message.specialSaleCondition

DecodeSaleConditionModifier3(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemption == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemption.ok THEN Fail ELSE
    LET extendedHoursOrSoldCode == ReadBytes(tradeThroughExemption.rest, 1) IN IF ~extendedHoursOrSoldCode.ok THEN Fail ELSE
    LET specialSaleCondition == ReadBytes(extendedHoursOrSoldCode.rest, 1) IN IF ~specialSaleCondition.ok THEN Fail ELSE
    Ok([ settlementType          |-> settlementType.value,
         tradeThroughExemption   |-> tradeThroughExemption.value,
         extendedHoursOrSoldCode |-> extendedHoursOrSoldCode.value,
         specialSaleCondition    |-> specialSaleCondition.value ], specialSaleCondition.rest)

ZeroSaleConditionModifier3 ==
    [ settlementType          |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      specialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditionModifier3 ==
    { ZeroSaleConditionModifier3 }
        \cup { [ZeroSaleConditionModifier3 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier3 EXCEPT !.tradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier3 EXCEPT !.extendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier3 EXCEPT !.specialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Next Shares Trade Report Message: 44 bytes                              *)
(***************************************************************************)

NextSharesTradeReportMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      nextSharesSymbol                  : Sample(8),
      securityClass                     : Sample(1),
      tradeControlNumber                : Sample(10),
      proxyPrice                        : Sample(4),
      tradeSize                         : Sample(4),
      navOffsetAmount                   : Sample(4),
      saleConditionModifier             : SaleConditionModifier3,
      consolidatedVolume                : Sample(8) ]

EncodeNextSharesTradeReportMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.nextSharesSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.proxyPrice
        \o message.tradeSize
        \o message.navOffsetAmount
        \o EncodeSaleConditionModifier3(message.saleConditionModifier)
        \o message.consolidatedVolume

DecodeNextSharesTradeReportMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET nextSharesSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~nextSharesSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(nextSharesSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET proxyPrice == ReadBytes(tradeControlNumber.rest, 4) IN IF ~proxyPrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(proxyPrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET navOffsetAmount == ReadBytes(tradeSize.rest, 4) IN IF ~navOffsetAmount.ok THEN Fail ELSE
    LET saleConditionModifier == DecodeSaleConditionModifier3(navOffsetAmount.rest) IN IF ~saleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(saleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         nextSharesSymbol                  |-> nextSharesSymbol.value,
         securityClass                     |-> securityClass.value,
         tradeControlNumber                |-> tradeControlNumber.value,
         proxyPrice                        |-> proxyPrice.value,
         tradeSize                         |-> tradeSize.value,
         navOffsetAmount                   |-> navOffsetAmount.value,
         saleConditionModifier             |-> saleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroNextSharesTradeReportMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      nextSharesSymbol                  |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber                |-> [i \in 1 .. 10 |-> 0],
      proxyPrice                        |-> [i \in 1 .. 4 |-> 0],
      tradeSize                         |-> [i \in 1 .. 4 |-> 0],
      navOffsetAmount                   |-> [i \in 1 .. 4 |-> 0],
      saleConditionModifier             |-> ZeroSaleConditionModifier3,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Next Shares Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedNextSharesTradeReportMessage ==
    { ZeroNextSharesTradeReportMessage }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.nextSharesSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.proxyPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.navOffsetAmount = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.saleConditionModifier = one] : one \in CheckedSaleConditionModifier3 }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition Modifier: 4 bytes                               *)
(***************************************************************************)

OriginalSaleConditionModifier ==
    [ originalSettlementType          : Sample(1),
      originalTradeThroughExemption   : Sample(1),
      originalExtendedHoursOrSoldCode : Sample(1),
      originalSpecialSaleCondition    : Sample(1) ]

EncodeOriginalSaleConditionModifier(message) ==
    message.originalSettlementType
        \o message.originalTradeThroughExemption
        \o message.originalExtendedHoursOrSoldCode
        \o message.originalSpecialSaleCondition

DecodeOriginalSaleConditionModifier(bytes) ==
    LET originalSettlementType == ReadBytes(bytes, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalTradeThroughExemption == ReadBytes(originalSettlementType.rest, 1) IN IF ~originalTradeThroughExemption.ok THEN Fail ELSE
    LET originalExtendedHoursOrSoldCode == ReadBytes(originalTradeThroughExemption.rest, 1) IN IF ~originalExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET originalSpecialSaleCondition == ReadBytes(originalExtendedHoursOrSoldCode.rest, 1) IN IF ~originalSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ originalSettlementType          |-> originalSettlementType.value,
         originalTradeThroughExemption   |-> originalTradeThroughExemption.value,
         originalExtendedHoursOrSoldCode |-> originalExtendedHoursOrSoldCode.value,
         originalSpecialSaleCondition    |-> originalSpecialSaleCondition.value ], originalSpecialSaleCondition.rest)

ZeroOriginalSaleConditionModifier ==
    [ originalSettlementType          |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      originalExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      originalSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleConditionModifier ==
    { ZeroOriginalSaleConditionModifier }
        \cup { [ZeroOriginalSaleConditionModifier EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier EXCEPT !.originalTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier EXCEPT !.originalExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier EXCEPT !.originalSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Error Message: 40 bytes                                    *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePrice                : Sample(4),
      originalTradeSize                 : Sample(4),
      originalSaleConditionModifier     : OriginalSaleConditionModifier,
      consolidatedVolume                : Sample(8) ]

EncodeTradeCancelErrorMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier(message.originalSaleConditionModifier)
        \o message.consolidatedVolume

DecodeTradeCancelErrorMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(originalSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePrice                |-> originalTradePrice.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroTradeCancelErrorMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice                |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier     |-> ZeroOriginalSaleConditionModifier,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition Modifier: 4 bytes                               *)
(***************************************************************************)

OriginalSaleConditionModifier2 ==
    [ originalSettlementType          : Sample(1),
      originalTradeThroughExemption   : Sample(1),
      originalExtendedHoursOrSoldCode : Sample(1),
      originalSpecialSaleCondition    : Sample(1) ]

EncodeOriginalSaleConditionModifier2(message) ==
    message.originalSettlementType
        \o message.originalTradeThroughExemption
        \o message.originalExtendedHoursOrSoldCode
        \o message.originalSpecialSaleCondition

DecodeOriginalSaleConditionModifier2(bytes) ==
    LET originalSettlementType == ReadBytes(bytes, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalTradeThroughExemption == ReadBytes(originalSettlementType.rest, 1) IN IF ~originalTradeThroughExemption.ok THEN Fail ELSE
    LET originalExtendedHoursOrSoldCode == ReadBytes(originalTradeThroughExemption.rest, 1) IN IF ~originalExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET originalSpecialSaleCondition == ReadBytes(originalExtendedHoursOrSoldCode.rest, 1) IN IF ~originalSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ originalSettlementType          |-> originalSettlementType.value,
         originalTradeThroughExemption   |-> originalTradeThroughExemption.value,
         originalExtendedHoursOrSoldCode |-> originalExtendedHoursOrSoldCode.value,
         originalSpecialSaleCondition    |-> originalSpecialSaleCondition.value ], originalSpecialSaleCondition.rest)

ZeroOriginalSaleConditionModifier2 ==
    [ originalSettlementType          |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      originalExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      originalSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleConditionModifier2 ==
    { ZeroOriginalSaleConditionModifier2 }
        \cup { [ZeroOriginalSaleConditionModifier2 EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier2 EXCEPT !.originalTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier2 EXCEPT !.originalExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier2 EXCEPT !.originalSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Form Trade Cancel Error Message: 44 bytes                          *)
(***************************************************************************)

LongFormTradeCancelErrorMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePriceLong            : Sample(8),
      originalTradeSize                 : Sample(4),
      originalSaleConditionModifier     : OriginalSaleConditionModifier2,
      consolidatedVolume                : Sample(8) ]

EncodeLongFormTradeCancelErrorMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePriceLong
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier2(message.originalSaleConditionModifier)
        \o message.consolidatedVolume

DecodeLongFormTradeCancelErrorMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePriceLong == ReadBytes(originalTradeControlNumber.rest, 8) IN IF ~originalTradePriceLong.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePriceLong.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier2(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(originalSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePriceLong            |-> originalTradePriceLong.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroLongFormTradeCancelErrorMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePriceLong            |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier     |-> ZeroOriginalSaleConditionModifier2,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Long Form Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormTradeCancelErrorMessage ==
    { ZeroLongFormTradeCancelErrorMessage }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.originalTradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier2 }
        \cup { [ZeroLongFormTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition Modifier: 4 bytes                               *)
(***************************************************************************)

OriginalSaleConditionModifier3 ==
    [ originalSettlementType          : Sample(1),
      originalTradeThroughExemption   : Sample(1),
      originalExtendedHoursOrSoldCode : Sample(1),
      originalSpecialSaleCondition    : Sample(1) ]

EncodeOriginalSaleConditionModifier3(message) ==
    message.originalSettlementType
        \o message.originalTradeThroughExemption
        \o message.originalExtendedHoursOrSoldCode
        \o message.originalSpecialSaleCondition

DecodeOriginalSaleConditionModifier3(bytes) ==
    LET originalSettlementType == ReadBytes(bytes, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalTradeThroughExemption == ReadBytes(originalSettlementType.rest, 1) IN IF ~originalTradeThroughExemption.ok THEN Fail ELSE
    LET originalExtendedHoursOrSoldCode == ReadBytes(originalTradeThroughExemption.rest, 1) IN IF ~originalExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET originalSpecialSaleCondition == ReadBytes(originalExtendedHoursOrSoldCode.rest, 1) IN IF ~originalSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ originalSettlementType          |-> originalSettlementType.value,
         originalTradeThroughExemption   |-> originalTradeThroughExemption.value,
         originalExtendedHoursOrSoldCode |-> originalExtendedHoursOrSoldCode.value,
         originalSpecialSaleCondition    |-> originalSpecialSaleCondition.value ], originalSpecialSaleCondition.rest)

ZeroOriginalSaleConditionModifier3 ==
    [ originalSettlementType          |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      originalExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      originalSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleConditionModifier3 ==
    { ZeroOriginalSaleConditionModifier3 }
        \cup { [ZeroOriginalSaleConditionModifier3 EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier3 EXCEPT !.originalTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier3 EXCEPT !.originalExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier3 EXCEPT !.originalSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Next Shares Trade Cancel Error Message: 44 bytes                        *)
(***************************************************************************)

NextSharesTradeCancelErrorMessage ==
    [ marketCenter                  : Sample(1),
      issueSymbol                   : Sample(8),
      securityClass                 : Sample(1),
      originalTradeControlNumber    : Sample(10),
      originalProxyPrice            : Sample(4),
      originalNavOffsetAmount       : Sample(4),
      originalTradeSize             : Sample(4),
      originalSaleConditionModifier : OriginalSaleConditionModifier3,
      consolidatedVolume            : Sample(8) ]

EncodeNextSharesTradeCancelErrorMessage(message) ==
    message.marketCenter
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalProxyPrice
        \o message.originalNavOffsetAmount
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier3(message.originalSaleConditionModifier)
        \o message.consolidatedVolume

DecodeNextSharesTradeCancelErrorMessage(bytes) ==
    LET marketCenter == ReadBytes(bytes, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenter.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalProxyPrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalProxyPrice.ok THEN Fail ELSE
    LET originalNavOffsetAmount == ReadBytes(originalProxyPrice.rest, 4) IN IF ~originalNavOffsetAmount.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalNavOffsetAmount.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier3(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(originalSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ marketCenter                  |-> marketCenter.value,
         issueSymbol                   |-> issueSymbol.value,
         securityClass                 |-> securityClass.value,
         originalTradeControlNumber    |-> originalTradeControlNumber.value,
         originalProxyPrice            |-> originalProxyPrice.value,
         originalNavOffsetAmount       |-> originalNavOffsetAmount.value,
         originalTradeSize             |-> originalTradeSize.value,
         originalSaleConditionModifier |-> originalSaleConditionModifier.value,
         consolidatedVolume            |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroNextSharesTradeCancelErrorMessage ==
    [ marketCenter                  |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                   |-> [i \in 1 .. 8 |-> 0],
      securityClass                 |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber    |-> [i \in 1 .. 10 |-> 0],
      originalProxyPrice            |-> [i \in 1 .. 4 |-> 0],
      originalNavOffsetAmount       |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize             |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier |-> ZeroOriginalSaleConditionModifier3,
      consolidatedVolume            |-> [i \in 1 .. 8 |-> 0] ]

(* Next Shares Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedNextSharesTradeCancelErrorMessage ==
    { ZeroNextSharesTradeCancelErrorMessage }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.originalProxyPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.originalNavOffsetAmount = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier3 }
        \cup { [ZeroNextSharesTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition Modifier: 4 bytes                               *)
(***************************************************************************)

OriginalSaleConditionModifier4 ==
    [ originalSettlementType          : Sample(1),
      originalTradeThroughExemption   : Sample(1),
      originalExtendedHoursOrSoldCode : Sample(1),
      originalSpecialSaleCondition    : Sample(1) ]

EncodeOriginalSaleConditionModifier4(message) ==
    message.originalSettlementType
        \o message.originalTradeThroughExemption
        \o message.originalExtendedHoursOrSoldCode
        \o message.originalSpecialSaleCondition

DecodeOriginalSaleConditionModifier4(bytes) ==
    LET originalSettlementType == ReadBytes(bytes, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalTradeThroughExemption == ReadBytes(originalSettlementType.rest, 1) IN IF ~originalTradeThroughExemption.ok THEN Fail ELSE
    LET originalExtendedHoursOrSoldCode == ReadBytes(originalTradeThroughExemption.rest, 1) IN IF ~originalExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET originalSpecialSaleCondition == ReadBytes(originalExtendedHoursOrSoldCode.rest, 1) IN IF ~originalSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ originalSettlementType          |-> originalSettlementType.value,
         originalTradeThroughExemption   |-> originalTradeThroughExemption.value,
         originalExtendedHoursOrSoldCode |-> originalExtendedHoursOrSoldCode.value,
         originalSpecialSaleCondition    |-> originalSpecialSaleCondition.value ], originalSpecialSaleCondition.rest)

ZeroOriginalSaleConditionModifier4 ==
    [ originalSettlementType          |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      originalExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      originalSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleConditionModifier4 ==
    { ZeroOriginalSaleConditionModifier4 }
        \cup { [ZeroOriginalSaleConditionModifier4 EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier4 EXCEPT !.originalTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier4 EXCEPT !.originalExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier4 EXCEPT !.originalSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Corrected Sale Condition Modifier: 4 bytes                              *)
(***************************************************************************)

CorrectedSaleConditionModifier ==
    [ correctedSettlementType          : Sample(1),
      correctedTradeThroughExemption   : Sample(1),
      correctedExtendedHoursOrSoldCode : Sample(1),
      correctedSpecialSaleCondition    : Sample(1) ]

EncodeCorrectedSaleConditionModifier(message) ==
    message.correctedSettlementType
        \o message.correctedTradeThroughExemption
        \o message.correctedExtendedHoursOrSoldCode
        \o message.correctedSpecialSaleCondition

DecodeCorrectedSaleConditionModifier(bytes) ==
    LET correctedSettlementType == ReadBytes(bytes, 1) IN IF ~correctedSettlementType.ok THEN Fail ELSE
    LET correctedTradeThroughExemption == ReadBytes(correctedSettlementType.rest, 1) IN IF ~correctedTradeThroughExemption.ok THEN Fail ELSE
    LET correctedExtendedHoursOrSoldCode == ReadBytes(correctedTradeThroughExemption.rest, 1) IN IF ~correctedExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET correctedSpecialSaleCondition == ReadBytes(correctedExtendedHoursOrSoldCode.rest, 1) IN IF ~correctedSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ correctedSettlementType          |-> correctedSettlementType.value,
         correctedTradeThroughExemption   |-> correctedTradeThroughExemption.value,
         correctedExtendedHoursOrSoldCode |-> correctedExtendedHoursOrSoldCode.value,
         correctedSpecialSaleCondition    |-> correctedSpecialSaleCondition.value ], correctedSpecialSaleCondition.rest)

ZeroCorrectedSaleConditionModifier ==
    [ correctedSettlementType          |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      correctedExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      correctedSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Corrected Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedSaleConditionModifier ==
    { ZeroCorrectedSaleConditionModifier }
        \cup { [ZeroCorrectedSaleConditionModifier EXCEPT !.correctedSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier EXCEPT !.correctedTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier EXCEPT !.correctedExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier EXCEPT !.correctedSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 62 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePrice                : Sample(4),
      originalTradeSize                 : Sample(4),
      originalSaleConditionModifier     : OriginalSaleConditionModifier4,
      correctedTradeControlNumber       : Sample(10),
      correctedTradePrice               : Sample(4),
      correctedTradeSize                : Sample(4),
      correctedSaleConditionModifier    : CorrectedSaleConditionModifier,
      consolidatedVolume                : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier4(message.originalSaleConditionModifier)
        \o message.correctedTradeControlNumber
        \o message.correctedTradePrice
        \o message.correctedTradeSize
        \o EncodeCorrectedSaleConditionModifier(message.correctedSaleConditionModifier)
        \o message.consolidatedVolume

DecodeTradeCorrectionMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier4(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeControlNumber.rest, 4) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == DecodeCorrectedSaleConditionModifier(correctedTradeSize.rest) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(correctedSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePrice                |-> originalTradePrice.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         correctedTradeControlNumber       |-> correctedTradeControlNumber.value,
         correctedTradePrice               |-> correctedTradePrice.value,
         correctedTradeSize                |-> correctedTradeSize.value,
         correctedSaleConditionModifier    |-> correctedSaleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroTradeCorrectionMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice                |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier     |-> ZeroOriginalSaleConditionModifier4,
      correctedTradeControlNumber       |-> [i \in 1 .. 10 |-> 0],
      correctedTradePrice               |-> [i \in 1 .. 4 |-> 0],
      correctedTradeSize                |-> [i \in 1 .. 4 |-> 0],
      correctedSaleConditionModifier    |-> ZeroCorrectedSaleConditionModifier,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier4 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in CheckedCorrectedSaleConditionModifier }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition Modifier: 4 bytes                               *)
(***************************************************************************)

OriginalSaleConditionModifier5 ==
    [ originalSettlementType          : Sample(1),
      originalTradeThroughExemption   : Sample(1),
      originalExtendedHoursOrSoldCode : Sample(1),
      originalSpecialSaleCondition    : Sample(1) ]

EncodeOriginalSaleConditionModifier5(message) ==
    message.originalSettlementType
        \o message.originalTradeThroughExemption
        \o message.originalExtendedHoursOrSoldCode
        \o message.originalSpecialSaleCondition

DecodeOriginalSaleConditionModifier5(bytes) ==
    LET originalSettlementType == ReadBytes(bytes, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalTradeThroughExemption == ReadBytes(originalSettlementType.rest, 1) IN IF ~originalTradeThroughExemption.ok THEN Fail ELSE
    LET originalExtendedHoursOrSoldCode == ReadBytes(originalTradeThroughExemption.rest, 1) IN IF ~originalExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET originalSpecialSaleCondition == ReadBytes(originalExtendedHoursOrSoldCode.rest, 1) IN IF ~originalSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ originalSettlementType          |-> originalSettlementType.value,
         originalTradeThroughExemption   |-> originalTradeThroughExemption.value,
         originalExtendedHoursOrSoldCode |-> originalExtendedHoursOrSoldCode.value,
         originalSpecialSaleCondition    |-> originalSpecialSaleCondition.value ], originalSpecialSaleCondition.rest)

ZeroOriginalSaleConditionModifier5 ==
    [ originalSettlementType          |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      originalExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      originalSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleConditionModifier5 ==
    { ZeroOriginalSaleConditionModifier5 }
        \cup { [ZeroOriginalSaleConditionModifier5 EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier5 EXCEPT !.originalTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier5 EXCEPT !.originalExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier5 EXCEPT !.originalSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Corrected Sale Condition Modifier: 4 bytes                              *)
(***************************************************************************)

CorrectedSaleConditionModifier2 ==
    [ correctedSettlementType          : Sample(1),
      correctedTradeThroughExemption   : Sample(1),
      correctedExtendedHoursOrSoldCode : Sample(1),
      correctedSpecialSaleCondition    : Sample(1) ]

EncodeCorrectedSaleConditionModifier2(message) ==
    message.correctedSettlementType
        \o message.correctedTradeThroughExemption
        \o message.correctedExtendedHoursOrSoldCode
        \o message.correctedSpecialSaleCondition

DecodeCorrectedSaleConditionModifier2(bytes) ==
    LET correctedSettlementType == ReadBytes(bytes, 1) IN IF ~correctedSettlementType.ok THEN Fail ELSE
    LET correctedTradeThroughExemption == ReadBytes(correctedSettlementType.rest, 1) IN IF ~correctedTradeThroughExemption.ok THEN Fail ELSE
    LET correctedExtendedHoursOrSoldCode == ReadBytes(correctedTradeThroughExemption.rest, 1) IN IF ~correctedExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET correctedSpecialSaleCondition == ReadBytes(correctedExtendedHoursOrSoldCode.rest, 1) IN IF ~correctedSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ correctedSettlementType          |-> correctedSettlementType.value,
         correctedTradeThroughExemption   |-> correctedTradeThroughExemption.value,
         correctedExtendedHoursOrSoldCode |-> correctedExtendedHoursOrSoldCode.value,
         correctedSpecialSaleCondition    |-> correctedSpecialSaleCondition.value ], correctedSpecialSaleCondition.rest)

ZeroCorrectedSaleConditionModifier2 ==
    [ correctedSettlementType          |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      correctedExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      correctedSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Corrected Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedSaleConditionModifier2 ==
    { ZeroCorrectedSaleConditionModifier2 }
        \cup { [ZeroCorrectedSaleConditionModifier2 EXCEPT !.correctedSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier2 EXCEPT !.correctedTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier2 EXCEPT !.correctedExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier2 EXCEPT !.correctedSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Form Trade Correction Message: 70 bytes                            *)
(***************************************************************************)

LongFormTradeCorrectionMessage ==
    [ originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePriceLong            : Sample(8),
      originalTradeSize                 : Sample(4),
      originalSaleConditionModifier     : OriginalSaleConditionModifier5,
      correctedTradeControlNumber       : Sample(10),
      correctedTradePriceLong           : Sample(8),
      correctedTradeSize                : Sample(4),
      correctedSaleConditionModifier    : CorrectedSaleConditionModifier2,
      consolidatedVolume                : Sample(8) ]

EncodeLongFormTradeCorrectionMessage(message) ==
    message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePriceLong
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier5(message.originalSaleConditionModifier)
        \o message.correctedTradeControlNumber
        \o message.correctedTradePriceLong
        \o message.correctedTradeSize
        \o EncodeCorrectedSaleConditionModifier2(message.correctedSaleConditionModifier)
        \o message.consolidatedVolume

DecodeLongFormTradeCorrectionMessage(bytes) ==
    LET originatingMarketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePriceLong == ReadBytes(originalTradeControlNumber.rest, 8) IN IF ~originalTradePriceLong.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePriceLong.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier5(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedTradePriceLong == ReadBytes(correctedTradeControlNumber.rest, 8) IN IF ~correctedTradePriceLong.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePriceLong.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == DecodeCorrectedSaleConditionModifier2(correctedTradeSize.rest) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(correctedSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePriceLong            |-> originalTradePriceLong.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         correctedTradeControlNumber       |-> correctedTradeControlNumber.value,
         correctedTradePriceLong           |-> correctedTradePriceLong.value,
         correctedTradeSize                |-> correctedTradeSize.value,
         correctedSaleConditionModifier    |-> correctedSaleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroLongFormTradeCorrectionMessage ==
    [ originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePriceLong            |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier     |-> ZeroOriginalSaleConditionModifier5,
      correctedTradeControlNumber       |-> [i \in 1 .. 10 |-> 0],
      correctedTradePriceLong           |-> [i \in 1 .. 8 |-> 0],
      correctedTradeSize                |-> [i \in 1 .. 4 |-> 0],
      correctedSaleConditionModifier    |-> ZeroCorrectedSaleConditionModifier2,
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Long Form Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormTradeCorrectionMessage ==
    { ZeroLongFormTradeCorrectionMessage }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.originalTradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier5 }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.correctedTradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in CheckedCorrectedSaleConditionModifier2 }
        \cup { [ZeroLongFormTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Original Sale Condition Modifier: 4 bytes                               *)
(***************************************************************************)

OriginalSaleConditionModifier6 ==
    [ originalSettlementType          : Sample(1),
      originalTradeThroughExemption   : Sample(1),
      originalExtendedHoursOrSoldCode : Sample(1),
      originalSpecialSaleCondition    : Sample(1) ]

EncodeOriginalSaleConditionModifier6(message) ==
    message.originalSettlementType
        \o message.originalTradeThroughExemption
        \o message.originalExtendedHoursOrSoldCode
        \o message.originalSpecialSaleCondition

DecodeOriginalSaleConditionModifier6(bytes) ==
    LET originalSettlementType == ReadBytes(bytes, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalTradeThroughExemption == ReadBytes(originalSettlementType.rest, 1) IN IF ~originalTradeThroughExemption.ok THEN Fail ELSE
    LET originalExtendedHoursOrSoldCode == ReadBytes(originalTradeThroughExemption.rest, 1) IN IF ~originalExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET originalSpecialSaleCondition == ReadBytes(originalExtendedHoursOrSoldCode.rest, 1) IN IF ~originalSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ originalSettlementType          |-> originalSettlementType.value,
         originalTradeThroughExemption   |-> originalTradeThroughExemption.value,
         originalExtendedHoursOrSoldCode |-> originalExtendedHoursOrSoldCode.value,
         originalSpecialSaleCondition    |-> originalSpecialSaleCondition.value ], originalSpecialSaleCondition.rest)

ZeroOriginalSaleConditionModifier6 ==
    [ originalSettlementType          |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      originalExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      originalSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Original Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedOriginalSaleConditionModifier6 ==
    { ZeroOriginalSaleConditionModifier6 }
        \cup { [ZeroOriginalSaleConditionModifier6 EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier6 EXCEPT !.originalTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier6 EXCEPT !.originalExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroOriginalSaleConditionModifier6 EXCEPT !.originalSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Corrected Sale Condition Modifier: 4 bytes                              *)
(***************************************************************************)

CorrectedSaleConditionModifier3 ==
    [ correctedSettlementType          : Sample(1),
      correctedTradeThroughExemption   : Sample(1),
      correctedExtendedHoursOrSoldCode : Sample(1),
      correctedSpecialSaleCondition    : Sample(1) ]

EncodeCorrectedSaleConditionModifier3(message) ==
    message.correctedSettlementType
        \o message.correctedTradeThroughExemption
        \o message.correctedExtendedHoursOrSoldCode
        \o message.correctedSpecialSaleCondition

DecodeCorrectedSaleConditionModifier3(bytes) ==
    LET correctedSettlementType == ReadBytes(bytes, 1) IN IF ~correctedSettlementType.ok THEN Fail ELSE
    LET correctedTradeThroughExemption == ReadBytes(correctedSettlementType.rest, 1) IN IF ~correctedTradeThroughExemption.ok THEN Fail ELSE
    LET correctedExtendedHoursOrSoldCode == ReadBytes(correctedTradeThroughExemption.rest, 1) IN IF ~correctedExtendedHoursOrSoldCode.ok THEN Fail ELSE
    LET correctedSpecialSaleCondition == ReadBytes(correctedExtendedHoursOrSoldCode.rest, 1) IN IF ~correctedSpecialSaleCondition.ok THEN Fail ELSE
    Ok([ correctedSettlementType          |-> correctedSettlementType.value,
         correctedTradeThroughExemption   |-> correctedTradeThroughExemption.value,
         correctedExtendedHoursOrSoldCode |-> correctedExtendedHoursOrSoldCode.value,
         correctedSpecialSaleCondition    |-> correctedSpecialSaleCondition.value ], correctedSpecialSaleCondition.rest)

ZeroCorrectedSaleConditionModifier3 ==
    [ correctedSettlementType          |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemption   |-> [i \in 1 .. 1 |-> 0],
      correctedExtendedHoursOrSoldCode |-> [i \in 1 .. 1 |-> 0],
      correctedSpecialSaleCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Corrected Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedSaleConditionModifier3 ==
    { ZeroCorrectedSaleConditionModifier3 }
        \cup { [ZeroCorrectedSaleConditionModifier3 EXCEPT !.correctedSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier3 EXCEPT !.correctedTradeThroughExemption = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier3 EXCEPT !.correctedExtendedHoursOrSoldCode = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedSaleConditionModifier3 EXCEPT !.correctedSpecialSaleCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Next Shares Trade Correction Message: 70 bytes                          *)
(***************************************************************************)

NextSharesTradeCorrectionMessage ==
    [ marketCenter                   : Sample(1),
      issueSymbol                    : Sample(8),
      securityClass                  : Sample(1),
      originalTradeControlNumber     : Sample(10),
      originalProxyPrice             : Sample(4),
      originalNavOffsetAmount        : Sample(4),
      originalTradeSize              : Sample(4),
      originalSaleConditionModifier  : OriginalSaleConditionModifier6,
      correctedTradeControlNumber    : Sample(10),
      correctedProxyPrice            : Sample(4),
      correctedNavOffsetAmount       : Sample(4),
      correctedTradeSize             : Sample(4),
      correctedSaleConditionModifier : CorrectedSaleConditionModifier3,
      consolidatedVolume             : Sample(8) ]

EncodeNextSharesTradeCorrectionMessage(message) ==
    message.marketCenter
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalProxyPrice
        \o message.originalNavOffsetAmount
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier6(message.originalSaleConditionModifier)
        \o message.correctedTradeControlNumber
        \o message.correctedProxyPrice
        \o message.correctedNavOffsetAmount
        \o message.correctedTradeSize
        \o EncodeCorrectedSaleConditionModifier3(message.correctedSaleConditionModifier)
        \o message.consolidatedVolume

DecodeNextSharesTradeCorrectionMessage(bytes) ==
    LET marketCenter == ReadBytes(bytes, 1) IN IF ~marketCenter.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenter.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalProxyPrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalProxyPrice.ok THEN Fail ELSE
    LET originalNavOffsetAmount == ReadBytes(originalProxyPrice.rest, 4) IN IF ~originalNavOffsetAmount.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalNavOffsetAmount.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier6(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedProxyPrice == ReadBytes(correctedTradeControlNumber.rest, 4) IN IF ~correctedProxyPrice.ok THEN Fail ELSE
    LET correctedNavOffsetAmount == ReadBytes(correctedProxyPrice.rest, 4) IN IF ~correctedNavOffsetAmount.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedNavOffsetAmount.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == DecodeCorrectedSaleConditionModifier3(correctedTradeSize.rest) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(correctedSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ marketCenter                   |-> marketCenter.value,
         issueSymbol                    |-> issueSymbol.value,
         securityClass                  |-> securityClass.value,
         originalTradeControlNumber     |-> originalTradeControlNumber.value,
         originalProxyPrice             |-> originalProxyPrice.value,
         originalNavOffsetAmount        |-> originalNavOffsetAmount.value,
         originalTradeSize              |-> originalTradeSize.value,
         originalSaleConditionModifier  |-> originalSaleConditionModifier.value,
         correctedTradeControlNumber    |-> correctedTradeControlNumber.value,
         correctedProxyPrice            |-> correctedProxyPrice.value,
         correctedNavOffsetAmount       |-> correctedNavOffsetAmount.value,
         correctedTradeSize             |-> correctedTradeSize.value,
         correctedSaleConditionModifier |-> correctedSaleConditionModifier.value,
         consolidatedVolume             |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroNextSharesTradeCorrectionMessage ==
    [ marketCenter                   |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                    |-> [i \in 1 .. 8 |-> 0],
      securityClass                  |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber     |-> [i \in 1 .. 10 |-> 0],
      originalProxyPrice             |-> [i \in 1 .. 4 |-> 0],
      originalNavOffsetAmount        |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize              |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier  |-> ZeroOriginalSaleConditionModifier6,
      correctedTradeControlNumber    |-> [i \in 1 .. 10 |-> 0],
      correctedProxyPrice            |-> [i \in 1 .. 4 |-> 0],
      correctedNavOffsetAmount       |-> [i \in 1 .. 4 |-> 0],
      correctedTradeSize             |-> [i \in 1 .. 4 |-> 0],
      correctedSaleConditionModifier |-> ZeroCorrectedSaleConditionModifier3,
      consolidatedVolume             |-> [i \in 1 .. 8 |-> 0] ]

(* Next Shares Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedNextSharesTradeCorrectionMessage ==
    { ZeroNextSharesTradeCorrectionMessage }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.marketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.originalProxyPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.originalNavOffsetAmount = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier6 }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.correctedProxyPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.correctedNavOffsetAmount = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in CheckedCorrectedSaleConditionModifier3 }
        \cup { [ZeroNextSharesTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Stock Trading Action Message: 15 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ reserved            : Sample(1),
      issueSymbol         : Sample(8),
      securityClass       : Sample(1),
      currentTradingState : Sample(1),
      reason              : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.reserved
        \o message.issueSymbol
        \o message.securityClass
        \o message.currentTradingState
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET reserved == ReadBytes(bytes, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(reserved.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(securityClass.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(currentTradingState.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reserved            |-> reserved.value,
         issueSymbol         |-> issueSymbol.value,
         securityClass       |-> securityClass.value,
         currentTradingState |-> currentTradingState.value,
         reason              |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ reserved            |-> [i \in 1 .. 1 |-> 0],
      issueSymbol         |-> [i \in 1 .. 8 |-> 0],
      securityClass       |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Stock Directory Message: 40 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ stock                       : Sample(8),
      marketCategory              : Sample(1),
      financialStatusIndicator    : Sample(1),
      roundLotSize                : Sample(4),
      roundLotsOnly               : Sample(1),
      issueClassification         : Sample(1),
      issueSubType                : Sample(2),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      ipoFlag                     : Sample(1),
      luldReferencePriceTier      : Sample(1),
      etpFlag                     : Sample(1),
      etpLeverageFactor           : Sample(4),
      inverseIndicator            : Sample(1),
      bloombergId                 : Sample(12) ]

EncodeStockDirectoryMessage(message) ==
    message.stock
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly
        \o message.issueClassification
        \o message.issueSubType
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.ipoFlag
        \o message.luldReferencePriceTier
        \o message.etpFlag
        \o message.etpLeverageFactor
        \o message.inverseIndicator
        \o message.bloombergId

DecodeStockDirectoryMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    LET issueClassification == ReadBytes(roundLotsOnly.rest, 1) IN IF ~issueClassification.ok THEN Fail ELSE
    LET issueSubType == ReadBytes(issueClassification.rest, 2) IN IF ~issueSubType.ok THEN Fail ELSE
    LET authenticity == ReadBytes(issueSubType.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET ipoFlag == ReadBytes(shortSaleThresholdIndicator.rest, 1) IN IF ~ipoFlag.ok THEN Fail ELSE
    LET luldReferencePriceTier == ReadBytes(ipoFlag.rest, 1) IN IF ~luldReferencePriceTier.ok THEN Fail ELSE
    LET etpFlag == ReadBytes(luldReferencePriceTier.rest, 1) IN IF ~etpFlag.ok THEN Fail ELSE
    LET etpLeverageFactor == ReadBytes(etpFlag.rest, 4) IN IF ~etpLeverageFactor.ok THEN Fail ELSE
    LET inverseIndicator == ReadBytes(etpLeverageFactor.rest, 1) IN IF ~inverseIndicator.ok THEN Fail ELSE
    LET bloombergId == ReadBytes(inverseIndicator.rest, 12) IN IF ~bloombergId.ok THEN Fail ELSE
    Ok([ stock                       |-> stock.value,
         marketCategory              |-> marketCategory.value,
         financialStatusIndicator    |-> financialStatusIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         roundLotsOnly               |-> roundLotsOnly.value,
         issueClassification         |-> issueClassification.value,
         issueSubType                |-> issueSubType.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         ipoFlag                     |-> ipoFlag.value,
         luldReferencePriceTier      |-> luldReferencePriceTier.value,
         etpFlag                     |-> etpFlag.value,
         etpLeverageFactor           |-> etpLeverageFactor.value,
         inverseIndicator            |-> inverseIndicator.value,
         bloombergId                 |-> bloombergId.value ], bloombergId.rest)

ZeroStockDirectoryMessage ==
    [ stock                       |-> [i \in 1 .. 8 |-> 0],
      marketCategory              |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 4 |-> 0],
      roundLotsOnly               |-> [i \in 1 .. 1 |-> 0],
      issueClassification         |-> [i \in 1 .. 1 |-> 0],
      issueSubType                |-> [i \in 1 .. 2 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      ipoFlag                     |-> [i \in 1 .. 1 |-> 0],
      luldReferencePriceTier      |-> [i \in 1 .. 1 |-> 0],
      etpFlag                     |-> [i \in 1 .. 1 |-> 0],
      etpLeverageFactor           |-> [i \in 1 .. 4 |-> 0],
      inverseIndicator            |-> [i \in 1 .. 1 |-> 0],
      bloombergId                 |-> [i \in 1 .. 12 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueClassification = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueSubType = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.ipoFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.luldReferencePriceTier = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpLeverageFactor = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.inverseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.bloombergId = one] : one \in Sample(12) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 9 bytes     *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ issueSymbol  : Sample(8),
      regShoAction : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.issueSymbol
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(issueSymbol.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ issueSymbol  |-> issueSymbol.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ issueSymbol  |-> [i \in 1 .. 8 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Adjusted Closing Price Message: 13 bytes                                *)
(***************************************************************************)

AdjustedClosingPriceMessage ==
    [ issueSymbol          : Sample(8),
      securityClass        : Sample(1),
      adjustedClosingPrice : Sample(4) ]

EncodeAdjustedClosingPriceMessage(message) ==
    message.issueSymbol
        \o message.securityClass
        \o message.adjustedClosingPrice

DecodeAdjustedClosingPriceMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(securityClass.rest, 4) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    Ok([ issueSymbol          |-> issueSymbol.value,
         securityClass        |-> securityClass.value,
         adjustedClosingPrice |-> adjustedClosingPrice.value ], adjustedClosingPrice.rest)

ZeroAdjustedClosingPriceMessage ==
    [ issueSymbol          |-> [i \in 1 .. 8 |-> 0],
      securityClass        |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice |-> [i \in 1 .. 4 |-> 0] ]

(* Adjusted Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAdjustedClosingPriceMessage ==
    { ZeroAdjustedClosingPriceMessage }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.adjustedClosingPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Form Adjusted Closing Price Message: 17 bytes                      *)
(***************************************************************************)

LongFormAdjustedClosingPriceMessage ==
    [ issueSymbol              : Sample(8),
      securityClass            : Sample(1),
      adjustedClosingPriceLong : Sample(8) ]

EncodeLongFormAdjustedClosingPriceMessage(message) ==
    message.issueSymbol
        \o message.securityClass
        \o message.adjustedClosingPriceLong

DecodeLongFormAdjustedClosingPriceMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET adjustedClosingPriceLong == ReadBytes(securityClass.rest, 8) IN IF ~adjustedClosingPriceLong.ok THEN Fail ELSE
    Ok([ issueSymbol              |-> issueSymbol.value,
         securityClass            |-> securityClass.value,
         adjustedClosingPriceLong |-> adjustedClosingPriceLong.value ], adjustedClosingPriceLong.rest)

ZeroLongFormAdjustedClosingPriceMessage ==
    [ issueSymbol              |-> [i \in 1 .. 8 |-> 0],
      securityClass            |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPriceLong |-> [i \in 1 .. 8 |-> 0] ]

(* Long Form Adjusted Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormAdjustedClosingPriceMessage ==
    { ZeroLongFormAdjustedClosingPriceMessage }
        \cup { [ZeroLongFormAdjustedClosingPriceMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLongFormAdjustedClosingPriceMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroLongFormAdjustedClosingPriceMessage EXCEPT !.adjustedClosingPriceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Trade Summary Message: 33 bytes                              *)
(***************************************************************************)

EndOfDayTradeSummaryMessage ==
    [ issueSymbol              : Sample(8),
      marketCategory           : Sample(1),
      consolidatedHighPrice    : Sample(4),
      consolidatedLowPrice     : Sample(4),
      consolidatedClosingPrice : Sample(4),
      consolidatedVolume       : Sample(8),
      consolidatedOpenPrice    : Sample(4) ]

EncodeEndOfDayTradeSummaryMessage(message) ==
    message.issueSymbol
        \o message.marketCategory
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedClosingPrice
        \o message.consolidatedVolume
        \o message.consolidatedOpenPrice

DecodeEndOfDayTradeSummaryMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(issueSymbol.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(marketCategory.rest, 4) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 4) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedClosingPrice == ReadBytes(consolidatedLowPrice.rest, 4) IN IF ~consolidatedClosingPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedClosingPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedOpenPrice == ReadBytes(consolidatedVolume.rest, 4) IN IF ~consolidatedOpenPrice.ok THEN Fail ELSE
    Ok([ issueSymbol              |-> issueSymbol.value,
         marketCategory           |-> marketCategory.value,
         consolidatedHighPrice    |-> consolidatedHighPrice.value,
         consolidatedLowPrice     |-> consolidatedLowPrice.value,
         consolidatedClosingPrice |-> consolidatedClosingPrice.value,
         consolidatedVolume       |-> consolidatedVolume.value,
         consolidatedOpenPrice    |-> consolidatedOpenPrice.value ], consolidatedOpenPrice.rest)

ZeroEndOfDayTradeSummaryMessage ==
    [ issueSymbol              |-> [i \in 1 .. 8 |-> 0],
      marketCategory           |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighPrice    |-> [i \in 1 .. 4 |-> 0],
      consolidatedLowPrice     |-> [i \in 1 .. 4 |-> 0],
      consolidatedClosingPrice |-> [i \in 1 .. 4 |-> 0],
      consolidatedVolume       |-> [i \in 1 .. 8 |-> 0],
      consolidatedOpenPrice    |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Day Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayTradeSummaryMessage ==
    { ZeroEndOfDayTradeSummaryMessage }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedClosingPrice = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedOpenPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Form End Of Day Trade Summary Message: 49 bytes                    *)
(***************************************************************************)

LongFormEndOfDayTradeSummaryMessage ==
    [ issueSymbol                  : Sample(8),
      marketCategory               : Sample(1),
      consolidatedHighPriceLong    : Sample(8),
      consolidatedLowPriceLong     : Sample(8),
      consolidatedClosingPriceLong : Sample(8),
      consolidatedVolume           : Sample(8),
      consolidatedOpenPriceLong    : Sample(8) ]

EncodeLongFormEndOfDayTradeSummaryMessage(message) ==
    message.issueSymbol
        \o message.marketCategory
        \o message.consolidatedHighPriceLong
        \o message.consolidatedLowPriceLong
        \o message.consolidatedClosingPriceLong
        \o message.consolidatedVolume
        \o message.consolidatedOpenPriceLong

DecodeLongFormEndOfDayTradeSummaryMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(issueSymbol.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET consolidatedHighPriceLong == ReadBytes(marketCategory.rest, 8) IN IF ~consolidatedHighPriceLong.ok THEN Fail ELSE
    LET consolidatedLowPriceLong == ReadBytes(consolidatedHighPriceLong.rest, 8) IN IF ~consolidatedLowPriceLong.ok THEN Fail ELSE
    LET consolidatedClosingPriceLong == ReadBytes(consolidatedLowPriceLong.rest, 8) IN IF ~consolidatedClosingPriceLong.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedClosingPriceLong.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedOpenPriceLong == ReadBytes(consolidatedVolume.rest, 8) IN IF ~consolidatedOpenPriceLong.ok THEN Fail ELSE
    Ok([ issueSymbol                  |-> issueSymbol.value,
         marketCategory               |-> marketCategory.value,
         consolidatedHighPriceLong    |-> consolidatedHighPriceLong.value,
         consolidatedLowPriceLong     |-> consolidatedLowPriceLong.value,
         consolidatedClosingPriceLong |-> consolidatedClosingPriceLong.value,
         consolidatedVolume           |-> consolidatedVolume.value,
         consolidatedOpenPriceLong    |-> consolidatedOpenPriceLong.value ], consolidatedOpenPriceLong.rest)

ZeroLongFormEndOfDayTradeSummaryMessage ==
    [ issueSymbol                  |-> [i \in 1 .. 8 |-> 0],
      marketCategory               |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighPriceLong    |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPriceLong     |-> [i \in 1 .. 8 |-> 0],
      consolidatedClosingPriceLong |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume           |-> [i \in 1 .. 8 |-> 0],
      consolidatedOpenPriceLong    |-> [i \in 1 .. 8 |-> 0] ]

(* Long Form End Of Day Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormEndOfDayTradeSummaryMessage ==
    { ZeroLongFormEndOfDayTradeSummaryMessage }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.consolidatedHighPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.consolidatedLowPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.consolidatedClosingPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroLongFormEndOfDayTradeSummaryMessage EXCEPT !.consolidatedOpenPriceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Next Shares End Of Day Trade Summary Message: 49 bytes                  *)
(***************************************************************************)

NextSharesEndOfDayTradeSummaryMessage ==
    [ issueSymbol              : Sample(8),
      marketCategory           : Sample(1),
      consolidatedHighPrice    : Sample(4),
      navOffsetAmountHigh      : Sample(4),
      consolidatedLowPrice     : Sample(4),
      navOffsetAmountLow       : Sample(4),
      consolidatedClosingPrice : Sample(4),
      navOffsetAmountClosing   : Sample(4),
      consolidatedVolume       : Sample(8),
      consolidatedOpenPrice    : Sample(4),
      navOffsetAmountOpen      : Sample(4) ]

EncodeNextSharesEndOfDayTradeSummaryMessage(message) ==
    message.issueSymbol
        \o message.marketCategory
        \o message.consolidatedHighPrice
        \o message.navOffsetAmountHigh
        \o message.consolidatedLowPrice
        \o message.navOffsetAmountLow
        \o message.consolidatedClosingPrice
        \o message.navOffsetAmountClosing
        \o message.consolidatedVolume
        \o message.consolidatedOpenPrice
        \o message.navOffsetAmountOpen

DecodeNextSharesEndOfDayTradeSummaryMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(issueSymbol.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(marketCategory.rest, 4) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET navOffsetAmountHigh == ReadBytes(consolidatedHighPrice.rest, 4) IN IF ~navOffsetAmountHigh.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(navOffsetAmountHigh.rest, 4) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET navOffsetAmountLow == ReadBytes(consolidatedLowPrice.rest, 4) IN IF ~navOffsetAmountLow.ok THEN Fail ELSE
    LET consolidatedClosingPrice == ReadBytes(navOffsetAmountLow.rest, 4) IN IF ~consolidatedClosingPrice.ok THEN Fail ELSE
    LET navOffsetAmountClosing == ReadBytes(consolidatedClosingPrice.rest, 4) IN IF ~navOffsetAmountClosing.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(navOffsetAmountClosing.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedOpenPrice == ReadBytes(consolidatedVolume.rest, 4) IN IF ~consolidatedOpenPrice.ok THEN Fail ELSE
    LET navOffsetAmountOpen == ReadBytes(consolidatedOpenPrice.rest, 4) IN IF ~navOffsetAmountOpen.ok THEN Fail ELSE
    Ok([ issueSymbol              |-> issueSymbol.value,
         marketCategory           |-> marketCategory.value,
         consolidatedHighPrice    |-> consolidatedHighPrice.value,
         navOffsetAmountHigh      |-> navOffsetAmountHigh.value,
         consolidatedLowPrice     |-> consolidatedLowPrice.value,
         navOffsetAmountLow       |-> navOffsetAmountLow.value,
         consolidatedClosingPrice |-> consolidatedClosingPrice.value,
         navOffsetAmountClosing   |-> navOffsetAmountClosing.value,
         consolidatedVolume       |-> consolidatedVolume.value,
         consolidatedOpenPrice    |-> consolidatedOpenPrice.value,
         navOffsetAmountOpen      |-> navOffsetAmountOpen.value ], navOffsetAmountOpen.rest)

ZeroNextSharesEndOfDayTradeSummaryMessage ==
    [ issueSymbol              |-> [i \in 1 .. 8 |-> 0],
      marketCategory           |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighPrice    |-> [i \in 1 .. 4 |-> 0],
      navOffsetAmountHigh      |-> [i \in 1 .. 4 |-> 0],
      consolidatedLowPrice     |-> [i \in 1 .. 4 |-> 0],
      navOffsetAmountLow       |-> [i \in 1 .. 4 |-> 0],
      consolidatedClosingPrice |-> [i \in 1 .. 4 |-> 0],
      navOffsetAmountClosing   |-> [i \in 1 .. 4 |-> 0],
      consolidatedVolume       |-> [i \in 1 .. 8 |-> 0],
      consolidatedOpenPrice    |-> [i \in 1 .. 4 |-> 0],
      navOffsetAmountOpen      |-> [i \in 1 .. 4 |-> 0] ]

(* Next Shares End Of Day Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedNextSharesEndOfDayTradeSummaryMessage ==
    { ZeroNextSharesEndOfDayTradeSummaryMessage }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.navOffsetAmountHigh = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.navOffsetAmountLow = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.consolidatedClosingPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.navOffsetAmountClosing = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.consolidatedOpenPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesEndOfDayTradeSummaryMessage EXCEPT !.navOffsetAmountOpen = one] : one \in Sample(4) }

(***************************************************************************)
(* Ipo Information Message: 14 bytes                                       *)
(***************************************************************************)

IpoInformationMessage ==
    [ issueSymbol           : Sample(8),
      securityClass         : Sample(1),
      referenceForNetChange : Sample(1),
      referencePrice        : Sample(4) ]

EncodeIpoInformationMessage(message) ==
    message.issueSymbol
        \o message.securityClass
        \o message.referenceForNetChange
        \o message.referencePrice

DecodeIpoInformationMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET referenceForNetChange == ReadBytes(securityClass.rest, 1) IN IF ~referenceForNetChange.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(referenceForNetChange.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    Ok([ issueSymbol           |-> issueSymbol.value,
         securityClass         |-> securityClass.value,
         referenceForNetChange |-> referenceForNetChange.value,
         referencePrice        |-> referencePrice.value ], referencePrice.rest)

ZeroIpoInformationMessage ==
    [ issueSymbol           |-> [i \in 1 .. 8 |-> 0],
      securityClass         |-> [i \in 1 .. 1 |-> 0],
      referenceForNetChange |-> [i \in 1 .. 1 |-> 0],
      referencePrice        |-> [i \in 1 .. 4 |-> 0] ]

(* Ipo Information Message at zero, then each field in turn at the values it is checked at *)
CheckedIpoInformationMessage ==
    { ZeroIpoInformationMessage }
        \cup { [ZeroIpoInformationMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.referenceForNetChange = one] : one \in Sample(1) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Mwcb Decline Level Message: 24 bytes                                    *)
(***************************************************************************)

MwcbDeclineLevelMessage ==
    [ level1 : Sample(8),
      level2 : Sample(8),
      level3 : Sample(8) ]

EncodeMwcbDeclineLevelMessage(message) ==
    message.level1
        \o message.level2
        \o message.level3

DecodeMwcbDeclineLevelMessage(bytes) ==
    LET level1 == ReadBytes(bytes, 8) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 8) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 8) IN IF ~level3.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value ], level3.rest)

ZeroMwcbDeclineLevelMessage ==
    [ level1 |-> [i \in 1 .. 8 |-> 0],
      level2 |-> [i \in 1 .. 8 |-> 0],
      level3 |-> [i \in 1 .. 8 |-> 0] ]

(* Mwcb Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbDeclineLevelMessage ==
    { ZeroMwcbDeclineLevelMessage }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level1 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level2 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Mwcb Status Message: 1 bytes                                            *)
(***************************************************************************)

MwcbStatusMessage ==
    [ breachedLevel : Sample(1) ]

EncodeMwcbStatusMessage(message) ==
    message.breachedLevel

DecodeMwcbStatusMessage(bytes) ==
    LET breachedLevel == ReadBytes(bytes, 1) IN IF ~breachedLevel.ok THEN Fail ELSE
    Ok([ breachedLevel |-> breachedLevel.value ], breachedLevel.rest)

ZeroMwcbStatusMessage ==
    [ breachedLevel |-> [i \in 1 .. 1 |-> 0] ]

(* Mwcb Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbStatusMessage ==
    { ZeroMwcbStatusMessage }
        \cup { [ZeroMwcbStatusMessage EXCEPT !.breachedLevel = one] : one \in Sample(1) }

(***************************************************************************)
(* Ipo Quoting Period Update Message: 17 bytes                             *)
(***************************************************************************)

IpoQuotingPeriodUpdateMessage ==
    [ stock                        : Sample(8),
      ipoQuotationReleaseTime      : Sample(4),
      ipoQuotationReleaseQualifier : Sample(1),
      ipoPrice                     : Sample(4) ]

EncodeIpoQuotingPeriodUpdateMessage(message) ==
    message.stock
        \o message.ipoQuotationReleaseTime
        \o message.ipoQuotationReleaseQualifier
        \o message.ipoPrice

DecodeIpoQuotingPeriodUpdateMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET ipoQuotationReleaseTime == ReadBytes(stock.rest, 4) IN IF ~ipoQuotationReleaseTime.ok THEN Fail ELSE
    LET ipoQuotationReleaseQualifier == ReadBytes(ipoQuotationReleaseTime.rest, 1) IN IF ~ipoQuotationReleaseQualifier.ok THEN Fail ELSE
    LET ipoPrice == ReadBytes(ipoQuotationReleaseQualifier.rest, 4) IN IF ~ipoPrice.ok THEN Fail ELSE
    Ok([ stock                        |-> stock.value,
         ipoQuotationReleaseTime      |-> ipoQuotationReleaseTime.value,
         ipoQuotationReleaseQualifier |-> ipoQuotationReleaseQualifier.value,
         ipoPrice                     |-> ipoPrice.value ], ipoPrice.rest)

ZeroIpoQuotingPeriodUpdateMessage ==
    [ stock                        |-> [i \in 1 .. 8 |-> 0],
      ipoQuotationReleaseTime      |-> [i \in 1 .. 4 |-> 0],
      ipoQuotationReleaseQualifier |-> [i \in 1 .. 1 |-> 0],
      ipoPrice                     |-> [i \in 1 .. 4 |-> 0] ]

(* Ipo Quoting Period Update Message at zero, then each field in turn at the values it is checked at *)
CheckedIpoQuotingPeriodUpdateMessage ==
    { ZeroIpoQuotingPeriodUpdateMessage }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseTime = one] : one \in Sample(4) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseQualifier = one] : one \in Sample(1) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Operational Halt Message: 10 bytes                                      *)
(***************************************************************************)

OperationalHaltMessage ==
    [ stock                 : Sample(8),
      marketCode            : Sample(1),
      operationalHaltAction : Sample(1) ]

EncodeOperationalHaltMessage(message) ==
    message.stock
        \o message.marketCode
        \o message.operationalHaltAction

DecodeOperationalHaltMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCode == ReadBytes(stock.rest, 1) IN IF ~marketCode.ok THEN Fail ELSE
    LET operationalHaltAction == ReadBytes(marketCode.rest, 1) IN IF ~operationalHaltAction.ok THEN Fail ELSE
    Ok([ stock                 |-> stock.value,
         marketCode            |-> marketCode.value,
         operationalHaltAction |-> operationalHaltAction.value ], operationalHaltAction.rest)

ZeroOperationalHaltMessage ==
    [ stock                 |-> [i \in 1 .. 8 |-> 0],
      marketCode            |-> [i \in 1 .. 1 |-> 0],
      operationalHaltAction |-> [i \in 1 .. 1 |-> 0] ]

(* Operational Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedOperationalHaltMessage ==
    { ZeroOperationalHaltMessage }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.marketCode = one] : one \in Sample(1) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.operationalHaltAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
TradeReportMessageCode == 84  \* "T"
LongFormTradeReportMessageCode == 116  \* "t"
NextSharesTradeReportMessageCode == 77  \* "M"
TradeCancelErrorMessageCode == 88  \* "X"
LongFormTradeCancelErrorMessageCode == 120  \* "x"
NextSharesTradeCancelErrorMessageCode == 79  \* "O"
TradeCorrectionMessageCode == 67  \* "C"
LongFormTradeCorrectionMessageCode == 99  \* "c"
NextSharesTradeCorrectionMessageCode == 90  \* "Z"
StockTradingActionMessageCode == 72  \* "H"
StockDirectoryMessageCode == 82  \* "R"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 89  \* "Y"
AdjustedClosingPriceMessageCode == 71  \* "G"
LongFormAdjustedClosingPriceMessageCode == 103  \* "g"
EndOfDayTradeSummaryMessageCode == 74  \* "J"
LongFormEndOfDayTradeSummaryMessageCode == 106  \* "j"
NextSharesEndOfDayTradeSummaryMessageCode == 78  \* "N"
IpoInformationMessageCode == 73  \* "I"
MwcbDeclineLevelMessageCode == 86  \* "V"
MwcbStatusMessageCode == 87  \* "W"
IpoQuotingPeriodUpdateMessageCode == 75  \* "K"
OperationalHaltMessageCode == 104  \* "h"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {LongFormTradeReportMessageCode}, body : LongFormTradeReportMessage ]
        \cup [ tag : {NextSharesTradeReportMessageCode}, body : NextSharesTradeReportMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {LongFormTradeCancelErrorMessageCode}, body : LongFormTradeCancelErrorMessage ]
        \cup [ tag : {NextSharesTradeCancelErrorMessageCode}, body : NextSharesTradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {LongFormTradeCorrectionMessageCode}, body : LongFormTradeCorrectionMessage ]
        \cup [ tag : {NextSharesTradeCorrectionMessageCode}, body : NextSharesTradeCorrectionMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {AdjustedClosingPriceMessageCode}, body : AdjustedClosingPriceMessage ]
        \cup [ tag : {LongFormAdjustedClosingPriceMessageCode}, body : LongFormAdjustedClosingPriceMessage ]
        \cup [ tag : {EndOfDayTradeSummaryMessageCode}, body : EndOfDayTradeSummaryMessage ]
        \cup [ tag : {LongFormEndOfDayTradeSummaryMessageCode}, body : LongFormEndOfDayTradeSummaryMessage ]
        \cup [ tag : {NextSharesEndOfDayTradeSummaryMessageCode}, body : NextSharesEndOfDayTradeSummaryMessage ]
        \cup [ tag : {IpoInformationMessageCode}, body : IpoInformationMessage ]
        \cup [ tag : {MwcbDeclineLevelMessageCode}, body : MwcbDeclineLevelMessage ]
        \cup [ tag : {MwcbStatusMessageCode}, body : MwcbStatusMessage ]
        \cup [ tag : {IpoQuotingPeriodUpdateMessageCode}, body : IpoQuotingPeriodUpdateMessage ]
        \cup [ tag : {OperationalHaltMessageCode}, body : OperationalHaltMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = LongFormTradeReportMessageCode -> EncodeLongFormTradeReportMessage(message.body)
      [] message.tag = NextSharesTradeReportMessageCode -> EncodeNextSharesTradeReportMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = LongFormTradeCancelErrorMessageCode -> EncodeLongFormTradeCancelErrorMessage(message.body)
      [] message.tag = NextSharesTradeCancelErrorMessageCode -> EncodeNextSharesTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = LongFormTradeCorrectionMessageCode -> EncodeLongFormTradeCorrectionMessage(message.body)
      [] message.tag = NextSharesTradeCorrectionMessageCode -> EncodeNextSharesTradeCorrectionMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = AdjustedClosingPriceMessageCode -> EncodeAdjustedClosingPriceMessage(message.body)
      [] message.tag = LongFormAdjustedClosingPriceMessageCode -> EncodeLongFormAdjustedClosingPriceMessage(message.body)
      [] message.tag = EndOfDayTradeSummaryMessageCode -> EncodeEndOfDayTradeSummaryMessage(message.body)
      [] message.tag = LongFormEndOfDayTradeSummaryMessageCode -> EncodeLongFormEndOfDayTradeSummaryMessage(message.body)
      [] message.tag = NextSharesEndOfDayTradeSummaryMessageCode -> EncodeNextSharesEndOfDayTradeSummaryMessage(message.body)
      [] message.tag = IpoInformationMessageCode -> EncodeIpoInformationMessage(message.body)
      [] message.tag = MwcbDeclineLevelMessageCode -> EncodeMwcbDeclineLevelMessage(message.body)
      [] message.tag = MwcbStatusMessageCode -> EncodeMwcbStatusMessage(message.body)
      [] message.tag = IpoQuotingPeriodUpdateMessageCode -> EncodeIpoQuotingPeriodUpdateMessage(message.body)
      [] message.tag = OperationalHaltMessageCode -> EncodeOperationalHaltMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = LongFormTradeReportMessageCode -> DecodeLongFormTradeReportMessage(bytes)
              [] tag = NextSharesTradeReportMessageCode -> DecodeNextSharesTradeReportMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = LongFormTradeCancelErrorMessageCode -> DecodeLongFormTradeCancelErrorMessage(bytes)
              [] tag = NextSharesTradeCancelErrorMessageCode -> DecodeNextSharesTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = LongFormTradeCorrectionMessageCode -> DecodeLongFormTradeCorrectionMessage(bytes)
              [] tag = NextSharesTradeCorrectionMessageCode -> DecodeNextSharesTradeCorrectionMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = AdjustedClosingPriceMessageCode -> DecodeAdjustedClosingPriceMessage(bytes)
              [] tag = LongFormAdjustedClosingPriceMessageCode -> DecodeLongFormAdjustedClosingPriceMessage(bytes)
              [] tag = EndOfDayTradeSummaryMessageCode -> DecodeEndOfDayTradeSummaryMessage(bytes)
              [] tag = LongFormEndOfDayTradeSummaryMessageCode -> DecodeLongFormEndOfDayTradeSummaryMessage(bytes)
              [] tag = NextSharesEndOfDayTradeSummaryMessageCode -> DecodeNextSharesEndOfDayTradeSummaryMessage(bytes)
              [] tag = IpoInformationMessageCode -> DecodeIpoInformationMessage(bytes)
              [] tag = MwcbDeclineLevelMessageCode -> DecodeMwcbDeclineLevelMessage(bytes)
              [] tag = MwcbStatusMessageCode -> DecodeMwcbStatusMessage(bytes)
              [] tag = IpoQuotingPeriodUpdateMessageCode -> DecodeIpoQuotingPeriodUpdateMessage(bytes)
              [] tag = OperationalHaltMessageCode -> DecodeOperationalHaltMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> LongFormTradeReportMessageCode, body |-> one] : one \in CheckedLongFormTradeReportMessage }
        \cup { [tag |-> NextSharesTradeReportMessageCode, body |-> one] : one \in CheckedNextSharesTradeReportMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> LongFormTradeCancelErrorMessageCode, body |-> one] : one \in CheckedLongFormTradeCancelErrorMessage }
        \cup { [tag |-> NextSharesTradeCancelErrorMessageCode, body |-> one] : one \in CheckedNextSharesTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> LongFormTradeCorrectionMessageCode, body |-> one] : one \in CheckedLongFormTradeCorrectionMessage }
        \cup { [tag |-> NextSharesTradeCorrectionMessageCode, body |-> one] : one \in CheckedNextSharesTradeCorrectionMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> AdjustedClosingPriceMessageCode, body |-> one] : one \in CheckedAdjustedClosingPriceMessage }
        \cup { [tag |-> LongFormAdjustedClosingPriceMessageCode, body |-> one] : one \in CheckedLongFormAdjustedClosingPriceMessage }
        \cup { [tag |-> EndOfDayTradeSummaryMessageCode, body |-> one] : one \in CheckedEndOfDayTradeSummaryMessage }
        \cup { [tag |-> LongFormEndOfDayTradeSummaryMessageCode, body |-> one] : one \in CheckedLongFormEndOfDayTradeSummaryMessage }
        \cup { [tag |-> NextSharesEndOfDayTradeSummaryMessageCode, body |-> one] : one \in CheckedNextSharesEndOfDayTradeSummaryMessage }
        \cup { [tag |-> IpoInformationMessageCode, body |-> one] : one \in CheckedIpoInformationMessage }
        \cup { [tag |-> MwcbDeclineLevelMessageCode, body |-> one] : one \in CheckedMwcbDeclineLevelMessage }
        \cup { [tag |-> MwcbStatusMessageCode, body |-> one] : one \in CheckedMwcbStatusMessage }
        \cup { [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> one] : one \in CheckedIpoQuotingPeriodUpdateMessage }
        \cup { [tag |-> OperationalHaltMessageCode, body |-> one] : one \in CheckedOperationalHaltMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      payload        : Payload ]

EncodeMessageBody(message) ==
    message.trackingNumber
        \o message.timestamp
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         payload        |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      payload        |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormTradeReportMessageCode, body |-> ZeroLongFormTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NextSharesTradeReportMessageCode, body |-> ZeroNextSharesTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelErrorMessageCode, body |-> ZeroTradeCancelErrorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormTradeCancelErrorMessageCode, body |-> ZeroLongFormTradeCancelErrorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NextSharesTradeCancelErrorMessageCode, body |-> ZeroNextSharesTradeCancelErrorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormTradeCorrectionMessageCode, body |-> ZeroLongFormTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NextSharesTradeCorrectionMessageCode, body |-> ZeroNextSharesTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionMessageCode, body |-> ZeroStockTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdjustedClosingPriceMessageCode, body |-> ZeroAdjustedClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormAdjustedClosingPriceMessageCode, body |-> ZeroLongFormAdjustedClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDayTradeSummaryMessageCode, body |-> ZeroEndOfDayTradeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormEndOfDayTradeSummaryMessageCode, body |-> ZeroLongFormEndOfDayTradeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NextSharesEndOfDayTradeSummaryMessageCode, body |-> ZeroNextSharesEndOfDayTradeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IpoInformationMessageCode, body |-> ZeroIpoInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbDeclineLevelMessageCode, body |-> ZeroMwcbDeclineLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbStatusMessageCode, body |-> ZeroMwcbStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> ZeroIpoQuotingPeriodUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OperationalHaltMessageCode, body |-> ZeroOperationalHaltMessage]] }

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

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditionModifier ==
    \A message \in CheckedSaleConditionModifier :
        LET read == DecodeSaleConditionModifier(EncodeSaleConditionModifier(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditionModifier2 ==
    \A message \in CheckedSaleConditionModifier2 :
        LET read == DecodeSaleConditionModifier2(EncodeSaleConditionModifier2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormTradeReportMessage ==
    \A message \in CheckedLongFormTradeReportMessage :
        LET read == DecodeLongFormTradeReportMessage(EncodeLongFormTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditionModifier3 ==
    \A message \in CheckedSaleConditionModifier3 :
        LET read == DecodeSaleConditionModifier3(EncodeSaleConditionModifier3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Next Shares Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNextSharesTradeReportMessage ==
    \A message \in CheckedNextSharesTradeReportMessage :
        LET read == DecodeNextSharesTradeReportMessage(EncodeNextSharesTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleConditionModifier ==
    \A message \in CheckedOriginalSaleConditionModifier :
        LET read == DecodeOriginalSaleConditionModifier(EncodeOriginalSaleConditionModifier(message))
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

(* Every Original Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleConditionModifier2 ==
    \A message \in CheckedOriginalSaleConditionModifier2 :
        LET read == DecodeOriginalSaleConditionModifier2(EncodeOriginalSaleConditionModifier2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormTradeCancelErrorMessage ==
    \A message \in CheckedLongFormTradeCancelErrorMessage :
        LET read == DecodeLongFormTradeCancelErrorMessage(EncodeLongFormTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleConditionModifier3 ==
    \A message \in CheckedOriginalSaleConditionModifier3 :
        LET read == DecodeOriginalSaleConditionModifier3(EncodeOriginalSaleConditionModifier3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Next Shares Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNextSharesTradeCancelErrorMessage ==
    \A message \in CheckedNextSharesTradeCancelErrorMessage :
        LET read == DecodeNextSharesTradeCancelErrorMessage(EncodeNextSharesTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleConditionModifier4 ==
    \A message \in CheckedOriginalSaleConditionModifier4 :
        LET read == DecodeOriginalSaleConditionModifier4(EncodeOriginalSaleConditionModifier4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedSaleConditionModifier ==
    \A message \in CheckedCorrectedSaleConditionModifier :
        LET read == DecodeCorrectedSaleConditionModifier(EncodeCorrectedSaleConditionModifier(message))
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

(* Every Original Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleConditionModifier5 ==
    \A message \in CheckedOriginalSaleConditionModifier5 :
        LET read == DecodeOriginalSaleConditionModifier5(EncodeOriginalSaleConditionModifier5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedSaleConditionModifier2 ==
    \A message \in CheckedCorrectedSaleConditionModifier2 :
        LET read == DecodeCorrectedSaleConditionModifier2(EncodeCorrectedSaleConditionModifier2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormTradeCorrectionMessage ==
    \A message \in CheckedLongFormTradeCorrectionMessage :
        LET read == DecodeLongFormTradeCorrectionMessage(EncodeLongFormTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalSaleConditionModifier6 ==
    \A message \in CheckedOriginalSaleConditionModifier6 :
        LET read == DecodeOriginalSaleConditionModifier6(EncodeOriginalSaleConditionModifier6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedSaleConditionModifier3 ==
    \A message \in CheckedCorrectedSaleConditionModifier3 :
        LET read == DecodeCorrectedSaleConditionModifier3(EncodeCorrectedSaleConditionModifier3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Next Shares Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNextSharesTradeCorrectionMessage ==
    \A message \in CheckedNextSharesTradeCorrectionMessage :
        LET read == DecodeNextSharesTradeCorrectionMessage(EncodeNextSharesTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
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

(* Every Adjusted Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdjustedClosingPriceMessage ==
    \A message \in CheckedAdjustedClosingPriceMessage :
        LET read == DecodeAdjustedClosingPriceMessage(EncodeAdjustedClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form Adjusted Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormAdjustedClosingPriceMessage ==
    \A message \in CheckedLongFormAdjustedClosingPriceMessage :
        LET read == DecodeLongFormAdjustedClosingPriceMessage(EncodeLongFormAdjustedClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayTradeSummaryMessage ==
    \A message \in CheckedEndOfDayTradeSummaryMessage :
        LET read == DecodeEndOfDayTradeSummaryMessage(EncodeEndOfDayTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form End Of Day Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormEndOfDayTradeSummaryMessage ==
    \A message \in CheckedLongFormEndOfDayTradeSummaryMessage :
        LET read == DecodeLongFormEndOfDayTradeSummaryMessage(EncodeLongFormEndOfDayTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Next Shares End Of Day Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNextSharesEndOfDayTradeSummaryMessage ==
    \A message \in CheckedNextSharesEndOfDayTradeSummaryMessage :
        LET read == DecodeNextSharesEndOfDayTradeSummaryMessage(EncodeNextSharesEndOfDayTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ipo Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIpoInformationMessage ==
    \A message \in CheckedIpoInformationMessage :
        LET read == DecodeIpoInformationMessage(EncodeIpoInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mwcb Decline Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbDeclineLevelMessage ==
    \A message \in CheckedMwcbDeclineLevelMessage :
        LET read == DecodeMwcbDeclineLevelMessage(EncodeMwcbDeclineLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mwcb Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbStatusMessage ==
    \A message \in CheckedMwcbStatusMessage :
        LET read == DecodeMwcbStatusMessage(EncodeMwcbStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ipo Quoting Period Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIpoQuotingPeriodUpdateMessage ==
    \A message \in CheckedIpoQuotingPeriodUpdateMessage :
        LET read == DecodeIpoQuotingPeriodUpdateMessage(EncodeIpoQuotingPeriodUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Operational Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOperationalHaltMessage ==
    \A message \in CheckedOperationalHaltMessage :
        LET read == DecodeOperationalHaltMessage(EncodeOperationalHaltMessage(message))
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
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
