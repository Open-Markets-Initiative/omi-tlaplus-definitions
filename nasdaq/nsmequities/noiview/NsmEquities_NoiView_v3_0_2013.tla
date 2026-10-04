------------------- MODULE NsmEquities_NoiView_v3_0_2013 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Net Order Imbalance View v3.0.2013                             *)
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
(* Stock Directory Message: 31 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ stockAlphanumeric8          : Sample(8),
      marketCategory              : Sample(1),
      financialStatusIndicator    : Sample(1),
      roundLotSize                : Sample(6),
      roundLotsOnly               : Sample(1),
      issueClassification         : Sample(1),
      issueSubType                : Sample(2),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      ipoFlag                     : Sample(1),
      luldReferencePriceTier      : Sample(1),
      etpFlag                     : Sample(1),
      etpLeverageFactor           : Sample(5),
      inverseIndicator            : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.stockAlphanumeric8
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
    LET stockAlphanumeric8 == ReadBytes(bytes, 8) IN IF ~stockAlphanumeric8.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stockAlphanumeric8.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 6) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    LET issueClassification == ReadBytes(roundLotsOnly.rest, 1) IN IF ~issueClassification.ok THEN Fail ELSE
    LET issueSubType == ReadBytes(issueClassification.rest, 2) IN IF ~issueSubType.ok THEN Fail ELSE
    LET authenticity == ReadBytes(issueSubType.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET ipoFlag == ReadBytes(shortSaleThresholdIndicator.rest, 1) IN IF ~ipoFlag.ok THEN Fail ELSE
    LET luldReferencePriceTier == ReadBytes(ipoFlag.rest, 1) IN IF ~luldReferencePriceTier.ok THEN Fail ELSE
    LET etpFlag == ReadBytes(luldReferencePriceTier.rest, 1) IN IF ~etpFlag.ok THEN Fail ELSE
    LET etpLeverageFactor == ReadBytes(etpFlag.rest, 5) IN IF ~etpLeverageFactor.ok THEN Fail ELSE
    LET inverseIndicator == ReadBytes(etpLeverageFactor.rest, 1) IN IF ~inverseIndicator.ok THEN Fail ELSE
    Ok([ stockAlphanumeric8          |-> stockAlphanumeric8.value,
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
    [ stockAlphanumeric8          |-> [i \in 1 .. 8 |-> 0],
      marketCategory              |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 6 |-> 0],
      roundLotsOnly               |-> [i \in 1 .. 1 |-> 0],
      issueClassification         |-> [i \in 1 .. 1 |-> 0],
      issueSubType                |-> [i \in 1 .. 2 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      ipoFlag                     |-> [i \in 1 .. 1 |-> 0],
      luldReferencePriceTier      |-> [i \in 1 .. 1 |-> 0],
      etpFlag                     |-> [i \in 1 .. 1 |-> 0],
      etpLeverageFactor           |-> [i \in 1 .. 5 |-> 0],
      inverseIndicator            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stockAlphanumeric8 = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueClassification = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueSubType = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.ipoFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.luldReferencePriceTier = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpLeverageFactor = one] : one \in Sample(5) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.inverseIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 26 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ stockAlphanumeric8  : Sample(8),
      currentTradingState : Sample(1),
      reason              : Sample(4),
      trackingId          : Sample(13) ]

EncodeStockTradingActionMessage(message) ==
    message.stockAlphanumeric8
        \o message.currentTradingState
        \o message.reason
        \o message.trackingId

DecodeStockTradingActionMessage(bytes) ==
    LET stockAlphanumeric8 == ReadBytes(bytes, 8) IN IF ~stockAlphanumeric8.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(stockAlphanumeric8.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(currentTradingState.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    LET trackingId == ReadBytes(reason.rest, 13) IN IF ~trackingId.ok THEN Fail ELSE
    Ok([ stockAlphanumeric8  |-> stockAlphanumeric8.value,
         currentTradingState |-> currentTradingState.value,
         reason              |-> reason.value,
         trackingId          |-> trackingId.value ], trackingId.rest)

ZeroStockTradingActionMessage ==
    [ stockAlphanumeric8  |-> [i \in 1 .. 8 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0],
      trackingId          |-> [i \in 1 .. 13 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stockAlphanumeric8 = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.trackingId = one] : one \in Sample(13) }

(***************************************************************************)
(* Reg Sho Restriction Message: 9 bytes                                    *)
(***************************************************************************)

RegShoRestrictionMessage ==
    [ stockAlpha8  : Sample(8),
      regShoAction : Sample(1) ]

EncodeRegShoRestrictionMessage(message) ==
    message.stockAlpha8
        \o message.regShoAction

DecodeRegShoRestrictionMessage(bytes) ==
    LET stockAlpha8 == ReadBytes(bytes, 8) IN IF ~stockAlpha8.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stockAlpha8.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ stockAlpha8  |-> stockAlpha8.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoRestrictionMessage ==
    [ stockAlpha8  |-> [i \in 1 .. 8 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoRestrictionMessage ==
    { ZeroRegShoRestrictionMessage }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.stockAlpha8 = one] : one \in Sample(8) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Noii Message: 59 bytes                                                  *)
(***************************************************************************)

NoiiMessage ==
    [ pairedShares            : Sample(9),
      imbalanceShares         : Sample(9),
      imbalanceDirection      : Sample(1),
      stockAlpha8             : Sample(8),
      farPrice                : Sample(10),
      nearPrice               : Sample(10),
      currentReferencePrice   : Sample(10),
      crossType               : Sample(1),
      priceVariationIndicator : Sample(1) ]

EncodeNoiiMessage(message) ==
    message.pairedShares
        \o message.imbalanceShares
        \o message.imbalanceDirection
        \o message.stockAlpha8
        \o message.farPrice
        \o message.nearPrice
        \o message.currentReferencePrice
        \o message.crossType
        \o message.priceVariationIndicator

DecodeNoiiMessage(bytes) ==
    LET pairedShares == ReadBytes(bytes, 9) IN IF ~pairedShares.ok THEN Fail ELSE
    LET imbalanceShares == ReadBytes(pairedShares.rest, 9) IN IF ~imbalanceShares.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceShares.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET stockAlpha8 == ReadBytes(imbalanceDirection.rest, 8) IN IF ~stockAlpha8.ok THEN Fail ELSE
    LET farPrice == ReadBytes(stockAlpha8.rest, 10) IN IF ~farPrice.ok THEN Fail ELSE
    LET nearPrice == ReadBytes(farPrice.rest, 10) IN IF ~nearPrice.ok THEN Fail ELSE
    LET currentReferencePrice == ReadBytes(nearPrice.rest, 10) IN IF ~currentReferencePrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(currentReferencePrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceVariationIndicator == ReadBytes(crossType.rest, 1) IN IF ~priceVariationIndicator.ok THEN Fail ELSE
    Ok([ pairedShares            |-> pairedShares.value,
         imbalanceShares         |-> imbalanceShares.value,
         imbalanceDirection      |-> imbalanceDirection.value,
         stockAlpha8             |-> stockAlpha8.value,
         farPrice                |-> farPrice.value,
         nearPrice               |-> nearPrice.value,
         currentReferencePrice   |-> currentReferencePrice.value,
         crossType               |-> crossType.value,
         priceVariationIndicator |-> priceVariationIndicator.value ], priceVariationIndicator.rest)

ZeroNoiiMessage ==
    [ pairedShares            |-> [i \in 1 .. 9 |-> 0],
      imbalanceShares         |-> [i \in 1 .. 9 |-> 0],
      imbalanceDirection      |-> [i \in 1 .. 1 |-> 0],
      stockAlpha8             |-> [i \in 1 .. 8 |-> 0],
      farPrice                |-> [i \in 1 .. 10 |-> 0],
      nearPrice               |-> [i \in 1 .. 10 |-> 0],
      currentReferencePrice   |-> [i \in 1 .. 10 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      priceVariationIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Noii Message at zero, then each field in turn at the values it is checked at *)
CheckedNoiiMessage ==
    { ZeroNoiiMessage }
        \cup { [ZeroNoiiMessage EXCEPT !.pairedShares = one] : one \in Sample(9) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalanceShares = one] : one \in Sample(9) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.stockAlpha8 = one] : one \in Sample(8) }
        \cup { [ZeroNoiiMessage EXCEPT !.farPrice = one] : one \in Sample(10) }
        \cup { [ZeroNoiiMessage EXCEPT !.nearPrice = one] : one \in Sample(10) }
        \cup { [ZeroNoiiMessage EXCEPT !.currentReferencePrice = one] : one \in Sample(10) }
        \cup { [ZeroNoiiMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.priceVariationIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Cross Trade Message: 53 bytes                                           *)
(***************************************************************************)

CrossTradeMessage ==
    [ shares      : Sample(9),
      stockAlpha8 : Sample(8),
      crossPrice  : Sample(10),
      matchNumber : Sample(12),
      crossType   : Sample(1),
      trackingId  : Sample(13) ]

EncodeCrossTradeMessage(message) ==
    message.shares
        \o message.stockAlpha8
        \o message.crossPrice
        \o message.matchNumber
        \o message.crossType
        \o message.trackingId

DecodeCrossTradeMessage(bytes) ==
    LET shares == ReadBytes(bytes, 9) IN IF ~shares.ok THEN Fail ELSE
    LET stockAlpha8 == ReadBytes(shares.rest, 8) IN IF ~stockAlpha8.ok THEN Fail ELSE
    LET crossPrice == ReadBytes(stockAlpha8.rest, 10) IN IF ~crossPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossPrice.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET trackingId == ReadBytes(crossType.rest, 13) IN IF ~trackingId.ok THEN Fail ELSE
    Ok([ shares      |-> shares.value,
         stockAlpha8 |-> stockAlpha8.value,
         crossPrice  |-> crossPrice.value,
         matchNumber |-> matchNumber.value,
         crossType   |-> crossType.value,
         trackingId  |-> trackingId.value ], trackingId.rest)

ZeroCrossTradeMessage ==
    [ shares      |-> [i \in 1 .. 9 |-> 0],
      stockAlpha8 |-> [i \in 1 .. 8 |-> 0],
      crossPrice  |-> [i \in 1 .. 10 |-> 0],
      matchNumber |-> [i \in 1 .. 12 |-> 0],
      crossType   |-> [i \in 1 .. 1 |-> 0],
      trackingId  |-> [i \in 1 .. 13 |-> 0] ]

(* Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossTradeMessage ==
    { ZeroCrossTradeMessage }
        \cup { [ZeroCrossTradeMessage EXCEPT !.shares = one] : one \in Sample(9) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.stockAlpha8 = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossPrice = one] : one \in Sample(10) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.trackingId = one] : one \in Sample(13) }

(***************************************************************************)
(* Ipo Quoting Period Update Message: 25 bytes                             *)
(***************************************************************************)

IpoQuotingPeriodUpdateMessage ==
    [ stockAlphanumeric8           : Sample(8),
      ipoQuotationReleaseTime      : Sample(6),
      ipoQuotationReleaseQualifier : Sample(1),
      ipoPrice                     : Sample(10) ]

EncodeIpoQuotingPeriodUpdateMessage(message) ==
    message.stockAlphanumeric8
        \o message.ipoQuotationReleaseTime
        \o message.ipoQuotationReleaseQualifier
        \o message.ipoPrice

DecodeIpoQuotingPeriodUpdateMessage(bytes) ==
    LET stockAlphanumeric8 == ReadBytes(bytes, 8) IN IF ~stockAlphanumeric8.ok THEN Fail ELSE
    LET ipoQuotationReleaseTime == ReadBytes(stockAlphanumeric8.rest, 6) IN IF ~ipoQuotationReleaseTime.ok THEN Fail ELSE
    LET ipoQuotationReleaseQualifier == ReadBytes(ipoQuotationReleaseTime.rest, 1) IN IF ~ipoQuotationReleaseQualifier.ok THEN Fail ELSE
    LET ipoPrice == ReadBytes(ipoQuotationReleaseQualifier.rest, 10) IN IF ~ipoPrice.ok THEN Fail ELSE
    Ok([ stockAlphanumeric8           |-> stockAlphanumeric8.value,
         ipoQuotationReleaseTime      |-> ipoQuotationReleaseTime.value,
         ipoQuotationReleaseQualifier |-> ipoQuotationReleaseQualifier.value,
         ipoPrice                     |-> ipoPrice.value ], ipoPrice.rest)

ZeroIpoQuotingPeriodUpdateMessage ==
    [ stockAlphanumeric8           |-> [i \in 1 .. 8 |-> 0],
      ipoQuotationReleaseTime      |-> [i \in 1 .. 6 |-> 0],
      ipoQuotationReleaseQualifier |-> [i \in 1 .. 1 |-> 0],
      ipoPrice                     |-> [i \in 1 .. 10 |-> 0] ]

(* Ipo Quoting Period Update Message at zero, then each field in turn at the values it is checked at *)
CheckedIpoQuotingPeriodUpdateMessage ==
    { ZeroIpoQuotingPeriodUpdateMessage }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.stockAlphanumeric8 = one] : one \in Sample(8) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseTime = one] : one \in Sample(6) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseQualifier = one] : one \in Sample(1) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoPrice = one] : one \in Sample(10) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
RegShoRestrictionMessageCode == 89  \* "Y"
NoiiMessageCode == 73  \* "I"
CrossTradeMessageCode == 81  \* "Q"
IpoQuotingPeriodUpdateMessageCode == 75  \* "K"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoRestrictionMessageCode}, body : RegShoRestrictionMessage ]
        \cup [ tag : {NoiiMessageCode}, body : NoiiMessage ]
        \cup [ tag : {CrossTradeMessageCode}, body : CrossTradeMessage ]
        \cup [ tag : {IpoQuotingPeriodUpdateMessageCode}, body : IpoQuotingPeriodUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoRestrictionMessageCode -> EncodeRegShoRestrictionMessage(message.body)
      [] message.tag = NoiiMessageCode -> EncodeNoiiMessage(message.body)
      [] message.tag = CrossTradeMessageCode -> EncodeCrossTradeMessage(message.body)
      [] message.tag = IpoQuotingPeriodUpdateMessageCode -> EncodeIpoQuotingPeriodUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoRestrictionMessageCode -> DecodeRegShoRestrictionMessage(bytes)
              [] tag = NoiiMessageCode -> DecodeNoiiMessage(bytes)
              [] tag = CrossTradeMessageCode -> DecodeCrossTradeMessage(bytes)
              [] tag = IpoQuotingPeriodUpdateMessageCode -> DecodeIpoQuotingPeriodUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoRestrictionMessageCode, body |-> one] : one \in CheckedRegShoRestrictionMessage }
        \cup { [tag |-> NoiiMessageCode, body |-> one] : one \in CheckedNoiiMessage }
        \cup { [tag |-> CrossTradeMessageCode, body |-> one] : one \in CheckedCrossTradeMessage }
        \cup { [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> one] : one \in CheckedIpoQuotingPeriodUpdateMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionMessageCode, body |-> ZeroStockTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoRestrictionMessageCode, body |-> ZeroRegShoRestrictionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NoiiMessageCode, body |-> ZeroNoiiMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CrossTradeMessageCode, body |-> ZeroCrossTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> ZeroIpoQuotingPeriodUpdateMessage]] }

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

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
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

(* Every Reg Sho Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoRestrictionMessage ==
    \A message \in CheckedRegShoRestrictionMessage :
        LET read == DecodeRegShoRestrictionMessage(EncodeRegShoRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Noii Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNoiiMessage ==
    \A message \in CheckedNoiiMessage :
        LET read == DecodeNoiiMessage(EncodeNoiiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossTradeMessage ==
    \A message \in CheckedCrossTradeMessage :
        LET read == DecodeCrossTradeMessage(EncodeCrossTradeMessage(message))
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
