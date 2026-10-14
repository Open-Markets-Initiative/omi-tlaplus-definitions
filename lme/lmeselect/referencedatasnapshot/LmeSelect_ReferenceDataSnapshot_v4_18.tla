--------------- MODULE LmeSelect_ReferenceDataSnapshot_v4_18 ---------------
(***************************************************************************)
(* The London Metal Exchange LMEsource ReferenceData Refresh v4.18         *)
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
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Contract Definition Message: 134 bytes                                  *)
(***************************************************************************)

ContractDefinitionMessage ==
    [ tradingVenue            : Sample(2),
      contractCode            : Sample(12),
      name                    : Sample(64),
      contractType            : Sample(1),
      productCode             : Sample(2),
      underlyingType          : Sample(1),
      underlyingContractCode  : Sample(12),
      tradingCurrency         : Sample(3),
      settlementType          : Sample(1),
      settlementPricingMethod : Sample(1),
      exerciseStyle           : Sample(1),
      lotUnit                 : Sample(20),
      lotSize                 : Sample(8),
      lotSizeType             : Sample(1),
      contractPriceType       : Sample(1),
      firstTradingDate        : Sample(4) ]

EncodeContractDefinitionMessage(message) ==
    message.tradingVenue
        \o message.contractCode
        \o message.name
        \o message.contractType
        \o message.productCode
        \o message.underlyingType
        \o message.underlyingContractCode
        \o message.tradingCurrency
        \o message.settlementType
        \o message.settlementPricingMethod
        \o message.exerciseStyle
        \o message.lotUnit
        \o message.lotSize
        \o message.lotSizeType
        \o message.contractPriceType
        \o message.firstTradingDate

DecodeContractDefinitionMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET contractCode == ReadBytes(tradingVenue.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET name == ReadBytes(contractCode.rest, 64) IN IF ~name.ok THEN Fail ELSE
    LET contractType == ReadBytes(name.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET productCode == ReadBytes(contractType.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(productCode.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET underlyingContractCode == ReadBytes(underlyingType.rest, 12) IN IF ~underlyingContractCode.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(underlyingContractCode.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET settlementType == ReadBytes(tradingCurrency.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlementPricingMethod == ReadBytes(settlementType.rest, 1) IN IF ~settlementPricingMethod.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(settlementPricingMethod.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET lotUnit == ReadBytes(exerciseStyle.rest, 20) IN IF ~lotUnit.ok THEN Fail ELSE
    LET lotSize == ReadBytes(lotUnit.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeType == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeType.ok THEN Fail ELSE
    LET contractPriceType == ReadBytes(lotSizeType.rest, 1) IN IF ~contractPriceType.ok THEN Fail ELSE
    LET firstTradingDate == ReadBytes(contractPriceType.rest, 4) IN IF ~firstTradingDate.ok THEN Fail ELSE
    Ok([ tradingVenue            |-> tradingVenue.value,
         contractCode            |-> contractCode.value,
         name                    |-> name.value,
         contractType            |-> contractType.value,
         productCode             |-> productCode.value,
         underlyingType          |-> underlyingType.value,
         underlyingContractCode  |-> underlyingContractCode.value,
         tradingCurrency         |-> tradingCurrency.value,
         settlementType          |-> settlementType.value,
         settlementPricingMethod |-> settlementPricingMethod.value,
         exerciseStyle           |-> exerciseStyle.value,
         lotUnit                 |-> lotUnit.value,
         lotSize                 |-> lotSize.value,
         lotSizeType             |-> lotSizeType.value,
         contractPriceType       |-> contractPriceType.value,
         firstTradingDate        |-> firstTradingDate.value ], firstTradingDate.rest)

ZeroContractDefinitionMessage ==
    [ tradingVenue            |-> [i \in 1 .. 2 |-> 0],
      contractCode            |-> [i \in 1 .. 12 |-> 0],
      name                    |-> [i \in 1 .. 64 |-> 0],
      contractType            |-> [i \in 1 .. 1 |-> 0],
      productCode             |-> [i \in 1 .. 2 |-> 0],
      underlyingType          |-> [i \in 1 .. 1 |-> 0],
      underlyingContractCode  |-> [i \in 1 .. 12 |-> 0],
      tradingCurrency         |-> [i \in 1 .. 3 |-> 0],
      settlementType          |-> [i \in 1 .. 1 |-> 0],
      settlementPricingMethod |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle           |-> [i \in 1 .. 1 |-> 0],
      lotUnit                 |-> [i \in 1 .. 20 |-> 0],
      lotSize                 |-> [i \in 1 .. 8 |-> 0],
      lotSizeType             |-> [i \in 1 .. 1 |-> 0],
      contractPriceType       |-> [i \in 1 .. 1 |-> 0],
      firstTradingDate        |-> [i \in 1 .. 4 |-> 0] ]

(* Contract Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedContractDefinitionMessage ==
    { ZeroContractDefinitionMessage }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.name = one] : one \in Sample(64) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.underlyingContractCode = one] : one \in Sample(12) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.settlementPricingMethod = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.lotUnit = one] : one \in Sample(20) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.lotSizeType = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.contractPriceType = one] : one \in Sample(1) }
        \cup { [ZeroContractDefinitionMessage EXCEPT !.firstTradingDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Outright Definition Message: 121 bytes                                  *)
(***************************************************************************)

OutrightDefinitionMessage ==
    [ tradingVenue               : Sample(2),
      tradableInstrumentId       : Sample(8),
      mergedTradableInstrumentId : Sample(8),
      linkedTradableInstrumentId : Sample(8),
      productCode                : Sample(2),
      contractType               : Sample(1),
      tradingCurrency            : Sample(3),
      contractCode               : Sample(12),
      expiryDate                 : Sample(4),
      promptType                 : Sample(1),
      strikePrice                : Sample(8),
      optionType                 : Sample(1),
      exerciseStyle              : Sample(1),
      promptDateLabel            : Sample(6),
      priceCode                  : Sample(2),
      isin                       : Sample(12),
      cfiCode                    : Sample(6),
      marketCode                 : Sample(4),
      marketSegmentCode          : Sample(12),
      tickSizeId                 : Sample(4),
      lotSize                    : Sample(8),
      lotSizeType                : Sample(1),
      lastTradingDate            : Sample(4),
      settlementType             : Sample(1),
      settlementPricingMethod    : Sample(1),
      underlyingType             : Sample(1) ]

EncodeOutrightDefinitionMessage(message) ==
    message.tradingVenue
        \o message.tradableInstrumentId
        \o message.mergedTradableInstrumentId
        \o message.linkedTradableInstrumentId
        \o message.productCode
        \o message.contractType
        \o message.tradingCurrency
        \o message.contractCode
        \o message.expiryDate
        \o message.promptType
        \o message.strikePrice
        \o message.optionType
        \o message.exerciseStyle
        \o message.promptDateLabel
        \o message.priceCode
        \o message.isin
        \o message.cfiCode
        \o message.marketCode
        \o message.marketSegmentCode
        \o message.tickSizeId
        \o message.lotSize
        \o message.lotSizeType
        \o message.lastTradingDate
        \o message.settlementType
        \o message.settlementPricingMethod
        \o message.underlyingType

DecodeOutrightDefinitionMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(tradingVenue.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET mergedTradableInstrumentId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~mergedTradableInstrumentId.ok THEN Fail ELSE
    LET linkedTradableInstrumentId == ReadBytes(mergedTradableInstrumentId.rest, 8) IN IF ~linkedTradableInstrumentId.ok THEN Fail ELSE
    LET productCode == ReadBytes(linkedTradableInstrumentId.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET contractType == ReadBytes(productCode.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(contractType.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET contractCode == ReadBytes(tradingCurrency.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(contractCode.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET promptType == ReadBytes(expiryDate.rest, 1) IN IF ~promptType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(promptType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(optionType.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET promptDateLabel == ReadBytes(exerciseStyle.rest, 6) IN IF ~promptDateLabel.ok THEN Fail ELSE
    LET priceCode == ReadBytes(promptDateLabel.rest, 2) IN IF ~priceCode.ok THEN Fail ELSE
    LET isin == ReadBytes(priceCode.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(isin.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET marketCode == ReadBytes(cfiCode.rest, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET marketSegmentCode == ReadBytes(marketCode.rest, 12) IN IF ~marketSegmentCode.ok THEN Fail ELSE
    LET tickSizeId == ReadBytes(marketSegmentCode.rest, 4) IN IF ~tickSizeId.ok THEN Fail ELSE
    LET lotSize == ReadBytes(tickSizeId.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeType == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeType.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(lotSizeType.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET settlementType == ReadBytes(lastTradingDate.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlementPricingMethod == ReadBytes(settlementType.rest, 1) IN IF ~settlementPricingMethod.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(settlementPricingMethod.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    Ok([ tradingVenue               |-> tradingVenue.value,
         tradableInstrumentId       |-> tradableInstrumentId.value,
         mergedTradableInstrumentId |-> mergedTradableInstrumentId.value,
         linkedTradableInstrumentId |-> linkedTradableInstrumentId.value,
         productCode                |-> productCode.value,
         contractType               |-> contractType.value,
         tradingCurrency            |-> tradingCurrency.value,
         contractCode               |-> contractCode.value,
         expiryDate                 |-> expiryDate.value,
         promptType                 |-> promptType.value,
         strikePrice                |-> strikePrice.value,
         optionType                 |-> optionType.value,
         exerciseStyle              |-> exerciseStyle.value,
         promptDateLabel            |-> promptDateLabel.value,
         priceCode                  |-> priceCode.value,
         isin                       |-> isin.value,
         cfiCode                    |-> cfiCode.value,
         marketCode                 |-> marketCode.value,
         marketSegmentCode          |-> marketSegmentCode.value,
         tickSizeId                 |-> tickSizeId.value,
         lotSize                    |-> lotSize.value,
         lotSizeType                |-> lotSizeType.value,
         lastTradingDate            |-> lastTradingDate.value,
         settlementType             |-> settlementType.value,
         settlementPricingMethod    |-> settlementPricingMethod.value,
         underlyingType             |-> underlyingType.value ], underlyingType.rest)

ZeroOutrightDefinitionMessage ==
    [ tradingVenue               |-> [i \in 1 .. 2 |-> 0],
      tradableInstrumentId       |-> [i \in 1 .. 8 |-> 0],
      mergedTradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      linkedTradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      productCode                |-> [i \in 1 .. 2 |-> 0],
      contractType               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency            |-> [i \in 1 .. 3 |-> 0],
      contractCode               |-> [i \in 1 .. 12 |-> 0],
      expiryDate                 |-> [i \in 1 .. 4 |-> 0],
      promptType                 |-> [i \in 1 .. 1 |-> 0],
      strikePrice                |-> [i \in 1 .. 8 |-> 0],
      optionType                 |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle              |-> [i \in 1 .. 1 |-> 0],
      promptDateLabel            |-> [i \in 1 .. 6 |-> 0],
      priceCode                  |-> [i \in 1 .. 2 |-> 0],
      isin                       |-> [i \in 1 .. 12 |-> 0],
      cfiCode                    |-> [i \in 1 .. 6 |-> 0],
      marketCode                 |-> [i \in 1 .. 4 |-> 0],
      marketSegmentCode          |-> [i \in 1 .. 12 |-> 0],
      tickSizeId                 |-> [i \in 1 .. 4 |-> 0],
      lotSize                    |-> [i \in 1 .. 8 |-> 0],
      lotSizeType                |-> [i \in 1 .. 1 |-> 0],
      lastTradingDate            |-> [i \in 1 .. 4 |-> 0],
      settlementType             |-> [i \in 1 .. 1 |-> 0],
      settlementPricingMethod    |-> [i \in 1 .. 1 |-> 0],
      underlyingType             |-> [i \in 1 .. 1 |-> 0] ]

(* Outright Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightDefinitionMessage ==
    { ZeroOutrightDefinitionMessage }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.mergedTradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.linkedTradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.promptType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.promptDateLabel = one] : one \in Sample(6) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.priceCode = one] : one \in Sample(2) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.marketSegmentCode = one] : one \in Sample(12) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.tickSizeId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.lotSizeType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.settlementPricingMethod = one] : one \in Sample(1) }
        \cup { [ZeroOutrightDefinitionMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Legs: 29 bytes                                                 *)
(***************************************************************************)

StrategyLegs ==
    [ legNumber               : Sample(4),
      legBuySell              : Sample(1),
      legRatio                : Sample(8),
      legDeltaHedgePrice      : Sample(8),
      legTradableInstrumentId : Sample(8) ]

EncodeStrategyLegs(message) ==
    message.legNumber
        \o message.legBuySell
        \o message.legRatio
        \o message.legDeltaHedgePrice
        \o message.legTradableInstrumentId

DecodeStrategyLegs(bytes) ==
    LET legNumber == ReadBytes(bytes, 4) IN IF ~legNumber.ok THEN Fail ELSE
    LET legBuySell == ReadBytes(legNumber.rest, 1) IN IF ~legBuySell.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legBuySell.rest, 8) IN IF ~legRatio.ok THEN Fail ELSE
    LET legDeltaHedgePrice == ReadBytes(legRatio.rest, 8) IN IF ~legDeltaHedgePrice.ok THEN Fail ELSE
    LET legTradableInstrumentId == ReadBytes(legDeltaHedgePrice.rest, 8) IN IF ~legTradableInstrumentId.ok THEN Fail ELSE
    Ok([ legNumber               |-> legNumber.value,
         legBuySell              |-> legBuySell.value,
         legRatio                |-> legRatio.value,
         legDeltaHedgePrice      |-> legDeltaHedgePrice.value,
         legTradableInstrumentId |-> legTradableInstrumentId.value ], legTradableInstrumentId.rest)

ZeroStrategyLegs ==
    [ legNumber               |-> [i \in 1 .. 4 |-> 0],
      legBuySell              |-> [i \in 1 .. 1 |-> 0],
      legRatio                |-> [i \in 1 .. 8 |-> 0],
      legDeltaHedgePrice      |-> [i \in 1 .. 8 |-> 0],
      legTradableInstrumentId |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Legs at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLegs ==
    { ZeroStrategyLegs }
        \cup { [ZeroStrategyLegs EXCEPT !.legNumber = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLegs EXCEPT !.legBuySell = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLegs EXCEPT !.legRatio = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLegs EXCEPT !.legDeltaHedgePrice = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLegs EXCEPT !.legTradableInstrumentId = one] : one \in Sample(8) }

(* A run of Strategy Legs, written one after another *)
RECURSIVE EncodeStrategyLegsList(_)
EncodeStrategyLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyLegs(Head(messages)) \o EncodeStrategyLegsList(Tail(messages))

(* As many Strategy Legs as the field that counts them says *)
RECURSIVE ReadStrategyLegsList(_, _)
ReadStrategyLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Legs of each kind, for the lists that carry them *)
OneStrategyLegs == { ZeroStrategyLegs }

(***************************************************************************)
(* Strategy Definition Message                                             *)
(***************************************************************************)

StrategyDefinitionMessage ==
    [ tradingVenue               : Sample(2),
      tradableInstrumentId       : Sample(8),
      mergedTradableInstrumentId : Sample(8),
      productCode                : Sample(2),
      contractType               : Sample(1),
      tradingCurrency            : Sample(3),
      strategyTypeCode           : Sample(4),
      contractCode               : Sample(12),
      exerciseStyle              : Sample(1),
      priceCode                  : Sample(2),
      marketCode                 : Sample(4),
      marketSegmentCode          : Sample(12),
      tickSizeId                 : Sample(4),
      lotSize                    : Sample(8),
      lotSizeType                : Sample(1),
      lastTradingDate            : Sample(4),
      settlementType             : Sample(1),
      settlementPricingMethod    : Sample(1),
      underlyingType             : Sample(1),
      strategyLegs               : SampleLists(OneStrategyLegs) ]

EncodeStrategyDefinitionMessage(message) ==
    message.tradingVenue
        \o message.tradableInstrumentId
        \o message.mergedTradableInstrumentId
        \o message.productCode
        \o message.contractType
        \o message.tradingCurrency
        \o message.strategyTypeCode
        \o message.contractCode
        \o message.exerciseStyle
        \o message.priceCode
        \o message.marketCode
        \o message.marketSegmentCode
        \o message.tickSizeId
        \o message.lotSize
        \o message.lotSizeType
        \o message.lastTradingDate
        \o message.settlementType
        \o message.settlementPricingMethod
        \o message.underlyingType
        \o EncodeUIntLE(Len(message.strategyLegs), 4)
        \o EncodeStrategyLegsList(message.strategyLegs)

DecodeStrategyDefinitionMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(tradingVenue.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET mergedTradableInstrumentId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~mergedTradableInstrumentId.ok THEN Fail ELSE
    LET productCode == ReadBytes(mergedTradableInstrumentId.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET contractType == ReadBytes(productCode.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(contractType.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET strategyTypeCode == ReadBytes(tradingCurrency.rest, 4) IN IF ~strategyTypeCode.ok THEN Fail ELSE
    LET contractCode == ReadBytes(strategyTypeCode.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(contractCode.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET priceCode == ReadBytes(exerciseStyle.rest, 2) IN IF ~priceCode.ok THEN Fail ELSE
    LET marketCode == ReadBytes(priceCode.rest, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET marketSegmentCode == ReadBytes(marketCode.rest, 12) IN IF ~marketSegmentCode.ok THEN Fail ELSE
    LET tickSizeId == ReadBytes(marketSegmentCode.rest, 4) IN IF ~tickSizeId.ok THEN Fail ELSE
    LET lotSize == ReadBytes(tickSizeId.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeType == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeType.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(lotSizeType.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET settlementType == ReadBytes(lastTradingDate.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlementPricingMethod == ReadBytes(settlementType.rest, 1) IN IF ~settlementPricingMethod.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(settlementPricingMethod.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET strategyLegCount == ReadUIntLE(underlyingType.rest, 4) IN IF ~strategyLegCount.ok THEN Fail ELSE
    LET strategyLegs == ReadStrategyLegsList(strategyLegCount.rest, strategyLegCount.value) IN IF ~strategyLegs.ok THEN Fail ELSE
    Ok([ tradingVenue               |-> tradingVenue.value,
         tradableInstrumentId       |-> tradableInstrumentId.value,
         mergedTradableInstrumentId |-> mergedTradableInstrumentId.value,
         productCode                |-> productCode.value,
         contractType               |-> contractType.value,
         tradingCurrency            |-> tradingCurrency.value,
         strategyTypeCode           |-> strategyTypeCode.value,
         contractCode               |-> contractCode.value,
         exerciseStyle              |-> exerciseStyle.value,
         priceCode                  |-> priceCode.value,
         marketCode                 |-> marketCode.value,
         marketSegmentCode          |-> marketSegmentCode.value,
         tickSizeId                 |-> tickSizeId.value,
         lotSize                    |-> lotSize.value,
         lotSizeType                |-> lotSizeType.value,
         lastTradingDate            |-> lastTradingDate.value,
         settlementType             |-> settlementType.value,
         settlementPricingMethod    |-> settlementPricingMethod.value,
         underlyingType             |-> underlyingType.value,
         strategyLegs               |-> strategyLegs.value ], strategyLegs.rest)

ZeroStrategyDefinitionMessage ==
    [ tradingVenue               |-> [i \in 1 .. 2 |-> 0],
      tradableInstrumentId       |-> [i \in 1 .. 8 |-> 0],
      mergedTradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      productCode                |-> [i \in 1 .. 2 |-> 0],
      contractType               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency            |-> [i \in 1 .. 3 |-> 0],
      strategyTypeCode           |-> [i \in 1 .. 4 |-> 0],
      contractCode               |-> [i \in 1 .. 12 |-> 0],
      exerciseStyle              |-> [i \in 1 .. 1 |-> 0],
      priceCode                  |-> [i \in 1 .. 2 |-> 0],
      marketCode                 |-> [i \in 1 .. 4 |-> 0],
      marketSegmentCode          |-> [i \in 1 .. 12 |-> 0],
      tickSizeId                 |-> [i \in 1 .. 4 |-> 0],
      lotSize                    |-> [i \in 1 .. 8 |-> 0],
      lotSizeType                |-> [i \in 1 .. 1 |-> 0],
      lastTradingDate            |-> [i \in 1 .. 4 |-> 0],
      settlementType             |-> [i \in 1 .. 1 |-> 0],
      settlementPricingMethod    |-> [i \in 1 .. 1 |-> 0],
      underlyingType             |-> [i \in 1 .. 1 |-> 0],
      strategyLegs               |-> << >> ]

(* Strategy Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyDefinitionMessage ==
    { ZeroStrategyDefinitionMessage }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.mergedTradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.strategyTypeCode = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.priceCode = one] : one \in Sample(2) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.marketSegmentCode = one] : one \in Sample(12) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.tickSizeId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.lotSizeType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.settlementPricingMethod = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDefinitionMessage EXCEPT !.strategyLegs = one] : one \in SampleLists(OneStrategyLegs) }

(***************************************************************************)
(* Price Limits Message: 32 bytes                                          *)
(***************************************************************************)

PriceLimitsMessage ==
    [ tradableInstrumentId : Sample(8),
      upperPriceLimit      : Sample(8),
      lowerPriceLimit      : Sample(8),
      transactionTime      : Sample(8) ]

EncodePriceLimitsMessage(message) ==
    message.tradableInstrumentId
        \o message.upperPriceLimit
        \o message.lowerPriceLimit
        \o message.transactionTime

DecodePriceLimitsMessage(bytes) ==
    LET tradableInstrumentId == ReadBytes(bytes, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET upperPriceLimit == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~upperPriceLimit.ok THEN Fail ELSE
    LET lowerPriceLimit == ReadBytes(upperPriceLimit.rest, 8) IN IF ~lowerPriceLimit.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(lowerPriceLimit.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    Ok([ tradableInstrumentId |-> tradableInstrumentId.value,
         upperPriceLimit      |-> upperPriceLimit.value,
         lowerPriceLimit      |-> lowerPriceLimit.value,
         transactionTime      |-> transactionTime.value ], transactionTime.rest)

ZeroPriceLimitsMessage ==
    [ tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      upperPriceLimit      |-> [i \in 1 .. 8 |-> 0],
      lowerPriceLimit      |-> [i \in 1 .. 8 |-> 0],
      transactionTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Price Limits Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceLimitsMessage ==
    { ZeroPriceLimitsMessage }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.upperPriceLimit = one] : one \in Sample(8) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.lowerPriceLimit = one] : one \in Sample(8) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Statistics End Of Day Message: 50 bytes                           *)
(***************************************************************************)

TradeStatisticsEndOfDayMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8),
      openPrice            : Sample(8),
      tradeHigh            : Sample(8),
      tradeLow             : Sample(8),
      closingPrice         : Sample(8) ]

EncodeTradeStatisticsEndOfDayMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.openPrice
        \o message.tradeHigh
        \o message.tradeLow
        \o message.closingPrice

DecodeTradeStatisticsEndOfDayMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET openPrice == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET tradeHigh == ReadBytes(openPrice.rest, 8) IN IF ~tradeHigh.ok THEN Fail ELSE
    LET tradeLow == ReadBytes(tradeHigh.rest, 8) IN IF ~tradeLow.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(tradeLow.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         openPrice            |-> openPrice.value,
         tradeHigh            |-> tradeHigh.value,
         tradeLow             |-> tradeLow.value,
         closingPrice         |-> closingPrice.value ], closingPrice.rest)

ZeroTradeStatisticsEndOfDayMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      openPrice            |-> [i \in 1 .. 8 |-> 0],
      tradeHigh            |-> [i \in 1 .. 8 |-> 0],
      tradeLow             |-> [i \in 1 .. 8 |-> 0],
      closingPrice         |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Statistics End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeStatisticsEndOfDayMessage ==
    { ZeroTradeStatisticsEndOfDayMessage }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.tradeHigh = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.tradeLow = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsEndOfDayMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Refresh Complete Message: 4 bytes                                       *)
(***************************************************************************)

RefreshCompleteMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeRefreshCompleteMessage(message) ==
    message.lastSeqNum

DecodeRefreshCompleteMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroRefreshCompleteMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Refresh Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshCompleteMessage ==
    { ZeroRefreshCompleteMessage }
        \cup { [ZeroRefreshCompleteMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
ContractDefinitionMessageCode == 300  \* 0x12c
OutrightDefinitionMessageCode == 301  \* 0x12d
StrategyDefinitionMessageCode == 302  \* 0x12e
PriceLimitsMessageCode == 305  \* 0x131
TradeStatisticsEndOfDayMessageCode == 351  \* 0x15f
RefreshCompleteMessageCode == 203  \* 0xcb

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {ContractDefinitionMessageCode}, body : ContractDefinitionMessage ]
        \cup [ tag : {OutrightDefinitionMessageCode}, body : OutrightDefinitionMessage ]
        \cup [ tag : {StrategyDefinitionMessageCode}, body : StrategyDefinitionMessage ]
        \cup [ tag : {PriceLimitsMessageCode}, body : PriceLimitsMessage ]
        \cup [ tag : {TradeStatisticsEndOfDayMessageCode}, body : TradeStatisticsEndOfDayMessage ]
        \cup [ tag : {RefreshCompleteMessageCode}, body : RefreshCompleteMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = ContractDefinitionMessageCode -> EncodeContractDefinitionMessage(message.body)
      [] message.tag = OutrightDefinitionMessageCode -> EncodeOutrightDefinitionMessage(message.body)
      [] message.tag = StrategyDefinitionMessageCode -> EncodeStrategyDefinitionMessage(message.body)
      [] message.tag = PriceLimitsMessageCode -> EncodePriceLimitsMessage(message.body)
      [] message.tag = TradeStatisticsEndOfDayMessageCode -> EncodeTradeStatisticsEndOfDayMessage(message.body)
      [] message.tag = RefreshCompleteMessageCode -> EncodeRefreshCompleteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = ContractDefinitionMessageCode -> DecodeContractDefinitionMessage(bytes)
              [] tag = OutrightDefinitionMessageCode -> DecodeOutrightDefinitionMessage(bytes)
              [] tag = StrategyDefinitionMessageCode -> DecodeStrategyDefinitionMessage(bytes)
              [] tag = PriceLimitsMessageCode -> DecodePriceLimitsMessage(bytes)
              [] tag = TradeStatisticsEndOfDayMessageCode -> DecodeTradeStatisticsEndOfDayMessage(bytes)
              [] tag = RefreshCompleteMessageCode -> DecodeRefreshCompleteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> ContractDefinitionMessageCode, body |-> one] : one \in CheckedContractDefinitionMessage }
        \cup { [tag |-> OutrightDefinitionMessageCode, body |-> one] : one \in CheckedOutrightDefinitionMessage }
        \cup { [tag |-> StrategyDefinitionMessageCode, body |-> one] : one \in CheckedStrategyDefinitionMessage }
        \cup { [tag |-> PriceLimitsMessageCode, body |-> one] : one \in CheckedPriceLimitsMessage }
        \cup { [tag |-> TradeStatisticsEndOfDayMessageCode, body |-> one] : one \in CheckedTradeStatisticsEndOfDayMessage }
        \cup { [tag |-> RefreshCompleteMessageCode, body |-> one] : one \in CheckedRefreshCompleteMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ msgSize : 0 .. 255,
      payload : Payload ]

EncodeMessage(message) ==
    EncodeUIntLE(message.msgSize, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET msgSize == ReadUIntLE(bytes, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgType == ReadUIntLE(msgSize.rest, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSize |-> msgSize.value,
         payload |-> payload.value ], payload.rest)

ZeroMessage ==
    [ msgSize |-> 0,
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.msgSize = one] : one \in {0, 1, 255} }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ContractDefinitionMessageCode, body |-> ZeroContractDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightDefinitionMessageCode, body |-> ZeroOutrightDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyDefinitionMessageCode, body |-> ZeroStrategyDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceLimitsMessageCode, body |-> ZeroPriceLimitsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeStatisticsEndOfDayMessageCode, body |-> ZeroTradeStatisticsEndOfDayMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshCompleteMessageCode, body |-> ZeroRefreshCompleteMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, msgCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDefinitionMessage ==
    \A message \in CheckedContractDefinitionMessage :
        LET read == DecodeContractDefinitionMessage(EncodeContractDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightDefinitionMessage ==
    \A message \in CheckedOutrightDefinitionMessage :
        LET read == DecodeOutrightDefinitionMessage(EncodeOutrightDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyLegs ==
    \A message \in CheckedStrategyLegs :
        LET read == DecodeStrategyLegs(EncodeStrategyLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyDefinitionMessage ==
    \A message \in CheckedStrategyDefinitionMessage :
        LET read == DecodeStrategyDefinitionMessage(EncodeStrategyDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Limits Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLimitsMessage ==
    \A message \in CheckedPriceLimitsMessage :
        LET read == DecodePriceLimitsMessage(EncodePriceLimitsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Statistics End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeStatisticsEndOfDayMessage ==
    \A message \in CheckedTradeStatisticsEndOfDayMessage :
        LET read == DecodeTradeStatisticsEndOfDayMessage(EncodeTradeStatisticsEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshCompleteMessage ==
    \A message \in CheckedRefreshCompleteMessage :
        LET read == DecodeRefreshCompleteMessage(EncodeRefreshCompleteMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
