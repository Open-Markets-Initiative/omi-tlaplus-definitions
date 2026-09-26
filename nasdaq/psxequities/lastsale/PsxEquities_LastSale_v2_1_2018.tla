------------------ MODULE PsxEquities_LastSale_v2_1_2018 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Last Sale v2.1.2018                                            *)
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
(* Trade Report Message: 32 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ marketCenterIdentifier      : Sample(1),
      issueSymbol                 : Sample(8),
      securityClass               : Sample(1),
      tradeControlNumber          : Sample(10),
      tradePrice                  : Sample(4),
      tradeSize                   : Sample(4),
      saleConditionModifierLevel1 : Sample(1),
      saleConditionModifierLevel2 : Sample(1),
      saleConditionModifierLevel3 : Sample(1),
      saleConditionModifierLevel4 : Sample(1) ]

EncodeTradeReportMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.tradePrice
        \o message.tradeSize
        \o message.saleConditionModifierLevel1
        \o message.saleConditionModifierLevel2
        \o message.saleConditionModifierLevel3
        \o message.saleConditionModifierLevel4

DecodeTradeReportMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeControlNumber.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET saleConditionModifierLevel1 == ReadBytes(tradeSize.rest, 1) IN IF ~saleConditionModifierLevel1.ok THEN Fail ELSE
    LET saleConditionModifierLevel2 == ReadBytes(saleConditionModifierLevel1.rest, 1) IN IF ~saleConditionModifierLevel2.ok THEN Fail ELSE
    LET saleConditionModifierLevel3 == ReadBytes(saleConditionModifierLevel2.rest, 1) IN IF ~saleConditionModifierLevel3.ok THEN Fail ELSE
    LET saleConditionModifierLevel4 == ReadBytes(saleConditionModifierLevel3.rest, 1) IN IF ~saleConditionModifierLevel4.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier      |-> marketCenterIdentifier.value,
         issueSymbol                 |-> issueSymbol.value,
         securityClass               |-> securityClass.value,
         tradeControlNumber          |-> tradeControlNumber.value,
         tradePrice                  |-> tradePrice.value,
         tradeSize                   |-> tradeSize.value,
         saleConditionModifierLevel1 |-> saleConditionModifierLevel1.value,
         saleConditionModifierLevel2 |-> saleConditionModifierLevel2.value,
         saleConditionModifierLevel3 |-> saleConditionModifierLevel3.value,
         saleConditionModifierLevel4 |-> saleConditionModifierLevel4.value ], saleConditionModifierLevel4.rest)

ZeroTradeReportMessage ==
    [ marketCenterIdentifier      |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                 |-> [i \in 1 .. 8 |-> 0],
      securityClass               |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber          |-> [i \in 1 .. 10 |-> 0],
      tradePrice                  |-> [i \in 1 .. 4 |-> 0],
      tradeSize                   |-> [i \in 1 .. 4 |-> 0],
      saleConditionModifierLevel1 |-> [i \in 1 .. 1 |-> 0],
      saleConditionModifierLevel2 |-> [i \in 1 .. 1 |-> 0],
      saleConditionModifierLevel3 |-> [i \in 1 .. 1 |-> 0],
      saleConditionModifierLevel4 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifierLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifierLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifierLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifierLevel4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Next Shares Trade Report Message: 36 bytes                              *)
(***************************************************************************)

NextSharesTradeReportMessage ==
    [ marketCenterIdentifier      : Sample(1),
      nextSharesSymbol            : Sample(8),
      securityClass               : Sample(1),
      tradeControlNumber          : Sample(10),
      proxyPrice                  : Sample(4),
      tradeSize                   : Sample(4),
      navPremiumDiscountAmount    : Sample(4),
      saleConditionModifierLevel1 : Sample(1),
      saleConditionModifierLevel2 : Sample(1),
      saleConditionModifierLevel3 : Sample(1),
      saleConditionModifierLevel4 : Sample(1) ]

EncodeNextSharesTradeReportMessage(message) ==
    message.marketCenterIdentifier
        \o message.nextSharesSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.proxyPrice
        \o message.tradeSize
        \o message.navPremiumDiscountAmount
        \o message.saleConditionModifierLevel1
        \o message.saleConditionModifierLevel2
        \o message.saleConditionModifierLevel3
        \o message.saleConditionModifierLevel4

DecodeNextSharesTradeReportMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET nextSharesSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~nextSharesSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(nextSharesSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET proxyPrice == ReadBytes(tradeControlNumber.rest, 4) IN IF ~proxyPrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(proxyPrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET navPremiumDiscountAmount == ReadBytes(tradeSize.rest, 4) IN IF ~navPremiumDiscountAmount.ok THEN Fail ELSE
    LET saleConditionModifierLevel1 == ReadBytes(navPremiumDiscountAmount.rest, 1) IN IF ~saleConditionModifierLevel1.ok THEN Fail ELSE
    LET saleConditionModifierLevel2 == ReadBytes(saleConditionModifierLevel1.rest, 1) IN IF ~saleConditionModifierLevel2.ok THEN Fail ELSE
    LET saleConditionModifierLevel3 == ReadBytes(saleConditionModifierLevel2.rest, 1) IN IF ~saleConditionModifierLevel3.ok THEN Fail ELSE
    LET saleConditionModifierLevel4 == ReadBytes(saleConditionModifierLevel3.rest, 1) IN IF ~saleConditionModifierLevel4.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier      |-> marketCenterIdentifier.value,
         nextSharesSymbol            |-> nextSharesSymbol.value,
         securityClass               |-> securityClass.value,
         tradeControlNumber          |-> tradeControlNumber.value,
         proxyPrice                  |-> proxyPrice.value,
         tradeSize                   |-> tradeSize.value,
         navPremiumDiscountAmount    |-> navPremiumDiscountAmount.value,
         saleConditionModifierLevel1 |-> saleConditionModifierLevel1.value,
         saleConditionModifierLevel2 |-> saleConditionModifierLevel2.value,
         saleConditionModifierLevel3 |-> saleConditionModifierLevel3.value,
         saleConditionModifierLevel4 |-> saleConditionModifierLevel4.value ], saleConditionModifierLevel4.rest)

ZeroNextSharesTradeReportMessage ==
    [ marketCenterIdentifier      |-> [i \in 1 .. 1 |-> 0],
      nextSharesSymbol            |-> [i \in 1 .. 8 |-> 0],
      securityClass               |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber          |-> [i \in 1 .. 10 |-> 0],
      proxyPrice                  |-> [i \in 1 .. 4 |-> 0],
      tradeSize                   |-> [i \in 1 .. 4 |-> 0],
      navPremiumDiscountAmount    |-> [i \in 1 .. 4 |-> 0],
      saleConditionModifierLevel1 |-> [i \in 1 .. 1 |-> 0],
      saleConditionModifierLevel2 |-> [i \in 1 .. 1 |-> 0],
      saleConditionModifierLevel3 |-> [i \in 1 .. 1 |-> 0],
      saleConditionModifierLevel4 |-> [i \in 1 .. 1 |-> 0] ]

(* Next Shares Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedNextSharesTradeReportMessage ==
    { ZeroNextSharesTradeReportMessage }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.nextSharesSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.proxyPrice = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.navPremiumDiscountAmount = one] : one \in Sample(4) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.saleConditionModifierLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.saleConditionModifierLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.saleConditionModifierLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroNextSharesTradeReportMessage EXCEPT !.saleConditionModifierLevel4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Error Message: 32 bytes                                    *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ marketCenterIdentifier        : Sample(1),
      issueSymbol                   : Sample(8),
      securityClass                 : Sample(1),
      originalTradeControlNumber    : Sample(10),
      originalTradePrice            : Sample(4),
      originalTradeSize             : Sample(4),
      originalSaleConditionModifier : Sample(4) ]

EncodeTradeCancelErrorMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.originalSaleConditionModifier

DecodeTradeCancelErrorMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == ReadBytes(originalTradeSize.rest, 4) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
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
      originalTradePrice            |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize             |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSaleConditionModifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Cancel Error For Next Shares Message: 36 bytes                    *)
(***************************************************************************)

TradeCancelErrorForNextSharesMessage ==
    [ marketCenterIdentifier           : Sample(1),
      issueSymbol                      : Sample(8),
      securityClass                    : Sample(1),
      originalTradeControlNumber       : Sample(10),
      originalTradePrice               : Sample(4),
      originalNavPremiumDiscountAmount : Sample(4),
      originalTradeSize                : Sample(4),
      originalSaleConditionModifier    : Sample(4) ]

EncodeTradeCancelErrorForNextSharesMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalNavPremiumDiscountAmount
        \o message.originalTradeSize
        \o message.originalSaleConditionModifier

DecodeTradeCancelErrorForNextSharesMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalNavPremiumDiscountAmount == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalNavPremiumDiscountAmount.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalNavPremiumDiscountAmount.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == ReadBytes(originalTradeSize.rest, 4) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier           |-> marketCenterIdentifier.value,
         issueSymbol                      |-> issueSymbol.value,
         securityClass                    |-> securityClass.value,
         originalTradeControlNumber       |-> originalTradeControlNumber.value,
         originalTradePrice               |-> originalTradePrice.value,
         originalNavPremiumDiscountAmount |-> originalNavPremiumDiscountAmount.value,
         originalTradeSize                |-> originalTradeSize.value,
         originalSaleConditionModifier    |-> originalSaleConditionModifier.value ], originalSaleConditionModifier.rest)

ZeroTradeCancelErrorForNextSharesMessage ==
    [ marketCenterIdentifier           |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                      |-> [i \in 1 .. 8 |-> 0],
      securityClass                    |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber       |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice               |-> [i \in 1 .. 4 |-> 0],
      originalNavPremiumDiscountAmount |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize                |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier    |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Error For Next Shares Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorForNextSharesMessage ==
    { ZeroTradeCancelErrorForNextSharesMessage }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.originalTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.originalNavPremiumDiscountAmount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorForNextSharesMessage EXCEPT !.originalSaleConditionModifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Correction Message: 54 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ marketCenterIdentifier         : Sample(1),
      issueSymbol                    : Sample(8),
      securityClass                  : Sample(1),
      originalTradeControlNumber     : Sample(10),
      originalTradePrice             : Sample(4),
      originalTradeSize              : Sample(4),
      originalSaleConditionModifier  : Sample(4),
      correctedTradeControlNumber    : Sample(10),
      correctedTradePrice            : Sample(4),
      correctedTradeSize             : Sample(4),
      correctedSaleConditionModifier : Sample(4) ]

EncodeTradeCorrectionMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.originalSaleConditionModifier
        \o message.correctedTradeControlNumber
        \o message.correctedTradePrice
        \o message.correctedTradeSize
        \o message.correctedSaleConditionModifier

DecodeTradeCorrectionMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == ReadBytes(originalTradeSize.rest, 4) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeControlNumber.rest, 4) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == ReadBytes(correctedTradeSize.rest, 4) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
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
      originalTradePrice             |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize              |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier  |-> [i \in 1 .. 4 |-> 0],
      correctedTradeControlNumber    |-> [i \in 1 .. 10 |-> 0],
      correctedTradePrice            |-> [i \in 1 .. 4 |-> 0],
      correctedTradeSize             |-> [i \in 1 .. 4 |-> 0],
      correctedSaleConditionModifier |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleConditionModifier = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Correction For Next Shares Message: 62 bytes                      *)
(***************************************************************************)

TradeCorrectionForNextSharesMessage ==
    [ marketCenterIdentifier            : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePrice                : Sample(4),
      originalNavPremiumDiscountAmount  : Sample(4),
      originalTradeSize                 : Sample(4),
      originalSaleConditionModifier     : Sample(4),
      correctedTradeControlNumber       : Sample(10),
      correctedTradePrice               : Sample(4),
      correctedNavPremiumDiscountAmount : Sample(4),
      correctedTradeSize                : Sample(4),
      correctedSaleConditionModifier    : Sample(4) ]

EncodeTradeCorrectionForNextSharesMessage(message) ==
    message.marketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalNavPremiumDiscountAmount
        \o message.originalTradeSize
        \o message.originalSaleConditionModifier
        \o message.correctedTradeControlNumber
        \o message.correctedTradePrice
        \o message.correctedNavPremiumDiscountAmount
        \o message.correctedTradeSize
        \o message.correctedSaleConditionModifier

DecodeTradeCorrectionForNextSharesMessage(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 4) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalNavPremiumDiscountAmount == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalNavPremiumDiscountAmount.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalNavPremiumDiscountAmount.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == ReadBytes(originalTradeSize.rest, 4) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeControlNumber.rest, 4) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedNavPremiumDiscountAmount == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedNavPremiumDiscountAmount.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedNavPremiumDiscountAmount.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == ReadBytes(correctedTradeSize.rest, 4) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier            |-> marketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePrice                |-> originalTradePrice.value,
         originalNavPremiumDiscountAmount  |-> originalNavPremiumDiscountAmount.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         correctedTradeControlNumber       |-> correctedTradeControlNumber.value,
         correctedTradePrice               |-> correctedTradePrice.value,
         correctedNavPremiumDiscountAmount |-> correctedNavPremiumDiscountAmount.value,
         correctedTradeSize                |-> correctedTradeSize.value,
         correctedSaleConditionModifier    |-> correctedSaleConditionModifier.value ], correctedSaleConditionModifier.rest)

ZeroTradeCorrectionForNextSharesMessage ==
    [ marketCenterIdentifier            |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice                |-> [i \in 1 .. 4 |-> 0],
      originalNavPremiumDiscountAmount  |-> [i \in 1 .. 4 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 4 |-> 0],
      originalSaleConditionModifier     |-> [i \in 1 .. 4 |-> 0],
      correctedTradeControlNumber       |-> [i \in 1 .. 10 |-> 0],
      correctedTradePrice               |-> [i \in 1 .. 4 |-> 0],
      correctedNavPremiumDiscountAmount |-> [i \in 1 .. 4 |-> 0],
      correctedTradeSize                |-> [i \in 1 .. 4 |-> 0],
      correctedSaleConditionModifier    |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Correction For Next Shares Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionForNextSharesMessage ==
    { ZeroTradeCorrectionForNextSharesMessage }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.originalTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.originalNavPremiumDiscountAmount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.originalSaleConditionModifier = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.correctedNavPremiumDiscountAmount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionForNextSharesMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Action Message: 14 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ issueSymbol         : Sample(8),
      securityClass       : Sample(1),
      currentTradingState : Sample(1),
      tradingActionReason : Sample(4) ]

EncodeTradingActionMessage(message) ==
    message.issueSymbol
        \o message.securityClass
        \o message.currentTradingState
        \o message.tradingActionReason

DecodeTradingActionMessage(bytes) ==
    LET issueSymbol == ReadBytes(bytes, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(securityClass.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    LET tradingActionReason == ReadBytes(currentTradingState.rest, 4) IN IF ~tradingActionReason.ok THEN Fail ELSE
    Ok([ issueSymbol         |-> issueSymbol.value,
         securityClass       |-> securityClass.value,
         currentTradingState |-> currentTradingState.value,
         tradingActionReason |-> tradingActionReason.value ], tradingActionReason.rest)

ZeroTradingActionMessage ==
    [ issueSymbol         |-> [i \in 1 .. 8 |-> 0],
      securityClass       |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0],
      tradingActionReason |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionMessage EXCEPT !.tradingActionReason = one] : one \in Sample(4) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 9 bytes     *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ stock        : Sample(8),
      regShoAction : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.stock
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stock.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ stock        |-> stock.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ stock        |-> [i \in 1 .. 8 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 28 bytes                                       *)
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
      inverseIndicator            : Sample(1) ]

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
         inverseIndicator            |-> inverseIndicator.value ], inverseIndicator.rest)

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
      inverseIndicator            |-> [i \in 1 .. 1 |-> 0] ]

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
(* Mwcb Breach Message: 1 bytes                                            *)
(***************************************************************************)

MwcbBreachMessage ==
    [ breachedLevel : Sample(1) ]

EncodeMwcbBreachMessage(message) ==
    message.breachedLevel

DecodeMwcbBreachMessage(bytes) ==
    LET breachedLevel == ReadBytes(bytes, 1) IN IF ~breachedLevel.ok THEN Fail ELSE
    Ok([ breachedLevel |-> breachedLevel.value ], breachedLevel.rest)

ZeroMwcbBreachMessage ==
    [ breachedLevel |-> [i \in 1 .. 1 |-> 0] ]

(* Mwcb Breach Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbBreachMessage ==
    { ZeroMwcbBreachMessage }
        \cup { [ZeroMwcbBreachMessage EXCEPT !.breachedLevel = one] : one \in Sample(1) }

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
NextSharesTradeReportMessageCode == 77  \* "M"
TradeCancelErrorMessageCode == 88  \* "X"
TradeCancelErrorForNextSharesMessageCode == 79  \* "O"
TradeCorrectionMessageCode == 67  \* "C"
TradeCorrectionForNextSharesMessageCode == 90  \* "Z"
TradingActionMessageCode == 72  \* "H"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 89  \* "Y"
StockDirectoryMessageCode == 82  \* "R"
MwcbDeclineLevelMessageCode == 86  \* "V"
MwcbBreachMessageCode == 87  \* "W"
OperationalHaltMessageCode == 104  \* "h"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {NextSharesTradeReportMessageCode}, body : NextSharesTradeReportMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCancelErrorForNextSharesMessageCode}, body : TradeCancelErrorForNextSharesMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {TradeCorrectionForNextSharesMessageCode}, body : TradeCorrectionForNextSharesMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {MwcbDeclineLevelMessageCode}, body : MwcbDeclineLevelMessage ]
        \cup [ tag : {MwcbBreachMessageCode}, body : MwcbBreachMessage ]
        \cup [ tag : {OperationalHaltMessageCode}, body : OperationalHaltMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = NextSharesTradeReportMessageCode -> EncodeNextSharesTradeReportMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCancelErrorForNextSharesMessageCode -> EncodeTradeCancelErrorForNextSharesMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = TradeCorrectionForNextSharesMessageCode -> EncodeTradeCorrectionForNextSharesMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = MwcbDeclineLevelMessageCode -> EncodeMwcbDeclineLevelMessage(message.body)
      [] message.tag = MwcbBreachMessageCode -> EncodeMwcbBreachMessage(message.body)
      [] message.tag = OperationalHaltMessageCode -> EncodeOperationalHaltMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = NextSharesTradeReportMessageCode -> DecodeNextSharesTradeReportMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCancelErrorForNextSharesMessageCode -> DecodeTradeCancelErrorForNextSharesMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = TradeCorrectionForNextSharesMessageCode -> DecodeTradeCorrectionForNextSharesMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = MwcbDeclineLevelMessageCode -> DecodeMwcbDeclineLevelMessage(bytes)
              [] tag = MwcbBreachMessageCode -> DecodeMwcbBreachMessage(bytes)
              [] tag = OperationalHaltMessageCode -> DecodeOperationalHaltMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> NextSharesTradeReportMessageCode, body |-> one] : one \in CheckedNextSharesTradeReportMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCancelErrorForNextSharesMessageCode, body |-> one] : one \in CheckedTradeCancelErrorForNextSharesMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> TradeCorrectionForNextSharesMessageCode, body |-> one] : one \in CheckedTradeCorrectionForNextSharesMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> MwcbDeclineLevelMessageCode, body |-> one] : one \in CheckedMwcbDeclineLevelMessage }
        \cup { [tag |-> MwcbBreachMessageCode, body |-> one] : one \in CheckedMwcbBreachMessage }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> NextSharesTradeReportMessageCode, body |-> ZeroNextSharesTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelErrorMessageCode, body |-> ZeroTradeCancelErrorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelErrorForNextSharesMessageCode, body |-> ZeroTradeCancelErrorForNextSharesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionForNextSharesMessageCode, body |-> ZeroTradeCorrectionForNextSharesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbDeclineLevelMessageCode, body |-> ZeroMwcbDeclineLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbBreachMessageCode, body |-> ZeroMwcbBreachMessage]],
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

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
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

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Error For Next Shares Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorForNextSharesMessage ==
    \A message \in CheckedTradeCancelErrorForNextSharesMessage :
        LET read == DecodeTradeCancelErrorForNextSharesMessage(EncodeTradeCancelErrorForNextSharesMessage(message))
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

(* Every Trade Correction For Next Shares Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionForNextSharesMessage ==
    \A message \in CheckedTradeCorrectionForNextSharesMessage :
        LET read == DecodeTradeCorrectionForNextSharesMessage(EncodeTradeCorrectionForNextSharesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionMessage ==
    \A message \in CheckedTradingActionMessage :
        LET read == DecodeTradingActionMessage(EncodeTradingActionMessage(message))
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

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
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

(* Every Mwcb Breach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbBreachMessage ==
    \A message \in CheckedMwcbBreachMessage :
        LET read == DecodeMwcbBreachMessage(EncodeMwcbBreachMessage(message))
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
