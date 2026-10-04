--------- MODULE NsmEquities_LastSaleTrfTradesFilterView_v2_0_2013 ---------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Last Sale Trf Trades FilterView v2.0.2013                      *)
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
(* Trade Report Message: 43 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ marketCenterIdentifier : Sample(1),
      issueSymbol            : Sample(8),
      securityClass          : Sample(1),
      tradeControlNumber     : Sample(10),
      tradePrice             : Sample(10),
      tradeSize              : Sample(9),
      saleConditionModifier  : SaleConditionModifier ]

EncodeTradeReportMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.tradePrice
        \o message.tradeSize
        \o EncodeSaleConditionModifier(message.saleConditionModifier)

DecodeTradeReportMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeControlNumber.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 9) IN IF ~tradeSize.ok THEN Fail ELSE
    LET saleConditionModifier == DecodeSaleConditionModifier(tradeSize.rest) IN IF ~saleConditionModifier.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier |-> marketCenterIdentifier.value,
         issueSymbol            |-> issueSymbol.value,
         securityClass          |-> securityClass.value,
         tradeControlNumber     |-> tradeControlNumber.value,
         tradePrice             |-> tradePrice.value,
         tradeSize              |-> tradeSize.value,
         saleConditionModifier  |-> saleConditionModifier.value ], saleConditionModifier.rest)

ZeroTradeReportMessage ==
    [ marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol            |-> [i \in 1 .. 8 |-> 0],
      securityClass          |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber     |-> [i \in 1 .. 10 |-> 0],
      tradePrice             |-> [i \in 1 .. 10 |-> 0],
      tradeSize              |-> [i \in 1 .. 9 |-> 0],
      saleConditionModifier  |-> ZeroSaleConditionModifier ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(9) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifier = one] : one \in CheckedSaleConditionModifier }

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
(* Trade Cancel Error Message: 43 bytes                                    *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ marketCenterIdentifier        : Sample(1),
      issueSymbol                   : Sample(8),
      securityClass                 : Sample(1),
      originalTradeControlNumber    : Sample(10),
      originalTradePrice            : Sample(10),
      originalTradeSize             : Sample(9),
      originalSaleConditionModifier : OriginalSaleConditionModifier ]

EncodeTradeCancelErrorMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier(message.originalSaleConditionModifier)

DecodeTradeCancelErrorMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 10) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 9) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier        |-> marketCenterIdentifier.value,
         issueSymbol                   |-> issueSymbol.value,
         securityClass                 |-> securityClass.value,
         originalTradeControlNumber    |-> originalTradeControlNumber.value,
         originalTradePrice            |-> originalTradePrice.value,
         originalTradeSize             |-> originalTradeSize.value,
         originalSaleConditionModifier |-> originalSaleConditionModifier.value ], originalSaleConditionModifier.rest)

ZeroTradeCancelErrorMessage ==
    [ marketCenterIdentifier        |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                   |-> [i \in 1 .. 8 |-> 0],
      securityClass                 |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber    |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice            |-> [i \in 1 .. 10 |-> 0],
      originalTradeSize             |-> [i \in 1 .. 9 |-> 0],
      originalSaleConditionModifier |-> ZeroOriginalSaleConditionModifier ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeSize = one] : one \in Sample(9) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier }

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
(* Trade Correction Message: 76 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ marketCenterIdentifier         : Sample(1),
      issueSymbol                    : Sample(8),
      securityClass                  : Sample(1),
      originalTradeControlNumber     : Sample(10),
      originalTradePrice             : Sample(10),
      originalTradeSize              : Sample(9),
      originalSaleConditionModifier  : OriginalSaleConditionModifier2,
      correctedTradeControlNumber    : Sample(10),
      correctedTradePrice            : Sample(10),
      correctedTradeSize             : Sample(9),
      correctedSaleConditionModifier : CorrectedSaleConditionModifier ]

EncodeTradeCorrectionMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o EncodeOriginalSaleConditionModifier2(message.originalSaleConditionModifier)
        \o message.correctedTradeControlNumber
        \o message.correctedTradePrice
        \o message.correctedTradeSize
        \o EncodeCorrectedSaleConditionModifier(message.correctedSaleConditionModifier)

DecodeTradeCorrectionMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 10) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 9) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == DecodeOriginalSaleConditionModifier2(originalTradeSize.rest) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeControlNumber.rest, 10) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 9) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == DecodeCorrectedSaleConditionModifier(correctedTradeSize.rest) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier         |-> marketCenterIdentifier.value,
         issueSymbol                    |-> issueSymbol.value,
         securityClass                  |-> securityClass.value,
         originalTradeControlNumber     |-> originalTradeControlNumber.value,
         originalTradePrice             |-> originalTradePrice.value,
         originalTradeSize              |-> originalTradeSize.value,
         originalSaleConditionModifier  |-> originalSaleConditionModifier.value,
         correctedTradeControlNumber    |-> correctedTradeControlNumber.value,
         correctedTradePrice            |-> correctedTradePrice.value,
         correctedTradeSize             |-> correctedTradeSize.value,
         correctedSaleConditionModifier |-> correctedSaleConditionModifier.value ], correctedSaleConditionModifier.rest)

ZeroTradeCorrectionMessage ==
    [ marketCenterIdentifier         |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                    |-> [i \in 1 .. 8 |-> 0],
      securityClass                  |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber     |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice             |-> [i \in 1 .. 10 |-> 0],
      originalTradeSize              |-> [i \in 1 .. 9 |-> 0],
      originalSaleConditionModifier  |-> ZeroOriginalSaleConditionModifier2,
      correctedTradeControlNumber    |-> [i \in 1 .. 10 |-> 0],
      correctedTradePrice            |-> [i \in 1 .. 10 |-> 0],
      correctedTradeSize             |-> [i \in 1 .. 9 |-> 0],
      correctedSaleConditionModifier |-> ZeroCorrectedSaleConditionModifier ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(9) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleConditionModifier = one] : one \in CheckedOriginalSaleConditionModifier2 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(9) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in CheckedCorrectedSaleConditionModifier }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
TradeReportMessageCode == 84  \* "T"
TradeCancelErrorMessageCode == 88  \* "X"
TradeCorrectionMessageCode == 67  \* "C"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ timestamp : Sample(8),
      payload   : Payload ]

EncodeMessageBody(message) ==
    message.timestamp
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         payload   |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      payload   |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelErrorMessageCode, body |-> ZeroTradeCancelErrorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(4),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
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
