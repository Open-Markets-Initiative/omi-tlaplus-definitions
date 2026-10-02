-------------------- MODULE PsxEquities_Bbo_v2_0_2013_1 --------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Best Bid And Offer v2.0.2013                                   *)
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
(* Note: a Count of 0 marks Heartbeat and carries no Message.              *)
(*                                                                         *)
(* Note: a Count of 0 marks End Of Session and carries no Message.         *)
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
    [ stock                       : Sample(8),
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
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
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
(* Stock Trading Action Message: 27 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ stock               : Sample(8),
      securityClass       : Sample(1),
      currentTradingState : Sample(1),
      reason              : Sample(4),
      trackingId          : Sample(13) ]

EncodeStockTradingActionMessage(message) ==
    message.stock
        \o message.securityClass
        \o message.currentTradingState
        \o message.reason
        \o message.trackingId

DecodeStockTradingActionMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET securityClass == ReadBytes(stock.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(securityClass.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(currentTradingState.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    LET trackingId == ReadBytes(reason.rest, 13) IN IF ~trackingId.ok THEN Fail ELSE
    Ok([ stock               |-> stock.value,
         securityClass       |-> securityClass.value,
         currentTradingState |-> currentTradingState.value,
         reason              |-> reason.value,
         trackingId          |-> trackingId.value ], trackingId.rest)

ZeroStockTradingActionMessage ==
    [ stock               |-> [i \in 1 .. 8 |-> 0],
      securityClass       |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0],
      trackingId          |-> [i \in 1 .. 13 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.trackingId = one] : one \in Sample(13) }

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
(* Mwcb Decline Level Message: 36 bytes                                    *)
(***************************************************************************)

MwcbDeclineLevelMessage ==
    [ level1 : Sample(12),
      level2 : Sample(12),
      level3 : Sample(12) ]

EncodeMwcbDeclineLevelMessage(message) ==
    message.level1
        \o message.level2
        \o message.level3

DecodeMwcbDeclineLevelMessage(bytes) ==
    LET level1 == ReadBytes(bytes, 12) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 12) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 12) IN IF ~level3.ok THEN Fail ELSE
    Ok([ level1 |-> level1.value,
         level2 |-> level2.value,
         level3 |-> level3.value ], level3.rest)

ZeroMwcbDeclineLevelMessage ==
    [ level1 |-> [i \in 1 .. 12 |-> 0],
      level2 |-> [i \in 1 .. 12 |-> 0],
      level3 |-> [i \in 1 .. 12 |-> 0] ]

(* Mwcb Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbDeclineLevelMessage ==
    { ZeroMwcbDeclineLevelMessage }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level1 = one] : one \in Sample(12) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level2 = one] : one \in Sample(12) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level3 = one] : one \in Sample(12) }

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
(* Quotation Message: 60 bytes                                             *)
(***************************************************************************)

QuotationMessage ==
    [ stock             : Sample(8),
      securityClass     : Sample(1),
      psxBestBidPrice   : Sample(10),
      psxBestBidSize    : Sample(9),
      psxBestOfferPrice : Sample(10),
      psxBestOfferSize  : Sample(9),
      trackingId        : Sample(13) ]

EncodeQuotationMessage(message) ==
    message.stock
        \o message.securityClass
        \o message.psxBestBidPrice
        \o message.psxBestBidSize
        \o message.psxBestOfferPrice
        \o message.psxBestOfferSize
        \o message.trackingId

DecodeQuotationMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET securityClass == ReadBytes(stock.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET psxBestBidPrice == ReadBytes(securityClass.rest, 10) IN IF ~psxBestBidPrice.ok THEN Fail ELSE
    LET psxBestBidSize == ReadBytes(psxBestBidPrice.rest, 9) IN IF ~psxBestBidSize.ok THEN Fail ELSE
    LET psxBestOfferPrice == ReadBytes(psxBestBidSize.rest, 10) IN IF ~psxBestOfferPrice.ok THEN Fail ELSE
    LET psxBestOfferSize == ReadBytes(psxBestOfferPrice.rest, 9) IN IF ~psxBestOfferSize.ok THEN Fail ELSE
    LET trackingId == ReadBytes(psxBestOfferSize.rest, 13) IN IF ~trackingId.ok THEN Fail ELSE
    Ok([ stock             |-> stock.value,
         securityClass     |-> securityClass.value,
         psxBestBidPrice   |-> psxBestBidPrice.value,
         psxBestBidSize    |-> psxBestBidSize.value,
         psxBestOfferPrice |-> psxBestOfferPrice.value,
         psxBestOfferSize  |-> psxBestOfferSize.value,
         trackingId        |-> trackingId.value ], trackingId.rest)

ZeroQuotationMessage ==
    [ stock             |-> [i \in 1 .. 8 |-> 0],
      securityClass     |-> [i \in 1 .. 1 |-> 0],
      psxBestBidPrice   |-> [i \in 1 .. 10 |-> 0],
      psxBestBidSize    |-> [i \in 1 .. 9 |-> 0],
      psxBestOfferPrice |-> [i \in 1 .. 10 |-> 0],
      psxBestOfferSize  |-> [i \in 1 .. 9 |-> 0],
      trackingId        |-> [i \in 1 .. 13 |-> 0] ]

(* Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedQuotationMessage ==
    { ZeroQuotationMessage }
        \cup { [ZeroQuotationMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroQuotationMessage EXCEPT !.psxBestBidPrice = one] : one \in Sample(10) }
        \cup { [ZeroQuotationMessage EXCEPT !.psxBestBidSize = one] : one \in Sample(9) }
        \cup { [ZeroQuotationMessage EXCEPT !.psxBestOfferPrice = one] : one \in Sample(10) }
        \cup { [ZeroQuotationMessage EXCEPT !.psxBestOfferSize = one] : one \in Sample(9) }
        \cup { [ZeroQuotationMessage EXCEPT !.trackingId = one] : one \in Sample(13) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 89  \* "Y"
MwcbDeclineLevelMessageCode == 86  \* "V"
MwcbStatusMessageCode == 87  \* "W"
QuotationMessageCode == 81  \* "Q"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {MwcbDeclineLevelMessageCode}, body : MwcbDeclineLevelMessage ]
        \cup [ tag : {MwcbStatusMessageCode}, body : MwcbStatusMessage ]
        \cup [ tag : {QuotationMessageCode}, body : QuotationMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = MwcbDeclineLevelMessageCode -> EncodeMwcbDeclineLevelMessage(message.body)
      [] message.tag = MwcbStatusMessageCode -> EncodeMwcbStatusMessage(message.body)
      [] message.tag = QuotationMessageCode -> EncodeQuotationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = MwcbDeclineLevelMessageCode -> DecodeMwcbDeclineLevelMessage(bytes)
              [] tag = MwcbStatusMessageCode -> DecodeMwcbStatusMessage(bytes)
              [] tag = QuotationMessageCode -> DecodeQuotationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> MwcbDeclineLevelMessageCode, body |-> one] : one \in CheckedMwcbDeclineLevelMessage }
        \cup { [tag |-> MwcbStatusMessageCode, body |-> one] : one \in CheckedMwcbStatusMessage }
        \cup { [tag |-> QuotationMessageCode, body |-> one] : one \in CheckedQuotationMessage }

(***************************************************************************)
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ timestamp : Sample(8),
      payload   : Payload ]

EncodeMessageBody(message) ==
    message.timestamp
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Length counts the bytes it frames, so it is written from them *)
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
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbDeclineLevelMessageCode, body |-> ZeroMwcbDeclineLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbStatusMessageCode, body |-> ZeroMwcbStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuotationMessageCode, body |-> ZeroQuotationMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session  : Sample(10),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntLE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session  |-> session.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ session  |-> [i \in 1 .. 10 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
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

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
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

(* Every Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotationMessage ==
    \A message \in CheckedQuotationMessage :
        LET read == DecodeQuotationMessage(EncodeQuotationMessage(message))
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

(* Length is written from the bytes it frames *)
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
