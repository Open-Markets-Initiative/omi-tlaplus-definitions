------------------ MODULE OnyxFutures_TopOfMarket_v1_0_b -------------------
(***************************************************************************)
(* Miami International Holdings Top Of Market v1.0.b                       *)
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
(* Note: Application Message fills what is left of the frame Packet Length *)
(* states, which is what it is read from.                                  *)
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
(* Simple Instrument Definition Message: 119 bytes                         *)
(***************************************************************************)

SimpleInstrumentDefinitionMessage ==
    [ timestamp                     : Sample(8),
      instrumentId                  : Sample(4),
      underlyingAssetType           : Sample(1),
      underlyingAsset               : Sample(4),
      productGroupCode              : Sample(6),
      exchange                      : Sample(4),
      instrumentIdSource            : Sample(1),
      instrumentType                : Sample(1),
      maturityMonthYear             : Sample(4),
      currency                      : Sample(1),
      settlementCurrency            : Sample(1),
      matchAlgorithm                : Sample(1),
      minimumSize                   : Sample(4),
      maximumSize                   : Sample(4),
      tick                          : Sample(8),
      unitOfMeasure                 : Sample(5),
      unitOfMeasureQuantity         : Sample(4),
      settlementPrice               : Sample(8),
      settlementPriceTypeCalcMethod : Sample(1),
      totalVolume                   : Sample(4),
      openInterestQuantity          : Sample(4),
      highLimitPrice                : Sample(8),
      lowLimitPrice                 : Sample(8),
      tradingCollarVariationType    : Sample(1),
      tradingCollarVariation        : Sample(8),
      reserved16                    : Sample(16) ]

EncodeSimpleInstrumentDefinitionMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.underlyingAssetType
        \o message.underlyingAsset
        \o message.productGroupCode
        \o message.exchange
        \o message.instrumentIdSource
        \o message.instrumentType
        \o message.maturityMonthYear
        \o message.currency
        \o message.settlementCurrency
        \o message.matchAlgorithm
        \o message.minimumSize
        \o message.maximumSize
        \o message.tick
        \o message.unitOfMeasure
        \o message.unitOfMeasureQuantity
        \o message.settlementPrice
        \o message.settlementPriceTypeCalcMethod
        \o message.totalVolume
        \o message.openInterestQuantity
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.tradingCollarVariationType
        \o message.tradingCollarVariation
        \o message.reserved16

DecodeSimpleInstrumentDefinitionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAsset == ReadBytes(underlyingAssetType.rest, 4) IN IF ~underlyingAsset.ok THEN Fail ELSE
    LET productGroupCode == ReadBytes(underlyingAsset.rest, 6) IN IF ~productGroupCode.ok THEN Fail ELSE
    LET exchange == ReadBytes(productGroupCode.rest, 4) IN IF ~exchange.ok THEN Fail ELSE
    LET instrumentIdSource == ReadBytes(exchange.rest, 1) IN IF ~instrumentIdSource.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIdSource.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(instrumentType.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET currency == ReadBytes(maturityMonthYear.rest, 1) IN IF ~currency.ok THEN Fail ELSE
    LET settlementCurrency == ReadBytes(currency.rest, 1) IN IF ~settlementCurrency.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(settlementCurrency.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minimumSize == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minimumSize.ok THEN Fail ELSE
    LET maximumSize == ReadBytes(minimumSize.rest, 4) IN IF ~maximumSize.ok THEN Fail ELSE
    LET tick == ReadBytes(maximumSize.rest, 8) IN IF ~tick.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(tick.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureQuantity == ReadBytes(unitOfMeasure.rest, 4) IN IF ~unitOfMeasureQuantity.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(unitOfMeasureQuantity.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceTypeCalcMethod == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceTypeCalcMethod.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(settlementPriceTypeCalcMethod.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET openInterestQuantity == ReadBytes(totalVolume.rest, 4) IN IF ~openInterestQuantity.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(openInterestQuantity.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET tradingCollarVariationType == ReadBytes(lowLimitPrice.rest, 1) IN IF ~tradingCollarVariationType.ok THEN Fail ELSE
    LET tradingCollarVariation == ReadBytes(tradingCollarVariationType.rest, 8) IN IF ~tradingCollarVariation.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(tradingCollarVariation.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         instrumentId                  |-> instrumentId.value,
         underlyingAssetType           |-> underlyingAssetType.value,
         underlyingAsset               |-> underlyingAsset.value,
         productGroupCode              |-> productGroupCode.value,
         exchange                      |-> exchange.value,
         instrumentIdSource            |-> instrumentIdSource.value,
         instrumentType                |-> instrumentType.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         currency                      |-> currency.value,
         settlementCurrency            |-> settlementCurrency.value,
         matchAlgorithm                |-> matchAlgorithm.value,
         minimumSize                   |-> minimumSize.value,
         maximumSize                   |-> maximumSize.value,
         tick                          |-> tick.value,
         unitOfMeasure                 |-> unitOfMeasure.value,
         unitOfMeasureQuantity         |-> unitOfMeasureQuantity.value,
         settlementPrice               |-> settlementPrice.value,
         settlementPriceTypeCalcMethod |-> settlementPriceTypeCalcMethod.value,
         totalVolume                   |-> totalVolume.value,
         openInterestQuantity          |-> openInterestQuantity.value,
         highLimitPrice                |-> highLimitPrice.value,
         lowLimitPrice                 |-> lowLimitPrice.value,
         tradingCollarVariationType    |-> tradingCollarVariationType.value,
         tradingCollarVariation        |-> tradingCollarVariation.value,
         reserved16                    |-> reserved16.value ], reserved16.rest)

ZeroSimpleInstrumentDefinitionMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType           |-> [i \in 1 .. 1 |-> 0],
      underlyingAsset               |-> [i \in 1 .. 4 |-> 0],
      productGroupCode              |-> [i \in 1 .. 6 |-> 0],
      exchange                      |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource            |-> [i \in 1 .. 1 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      maturityMonthYear             |-> [i \in 1 .. 4 |-> 0],
      currency                      |-> [i \in 1 .. 1 |-> 0],
      settlementCurrency            |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm                |-> [i \in 1 .. 1 |-> 0],
      minimumSize                   |-> [i \in 1 .. 4 |-> 0],
      maximumSize                   |-> [i \in 1 .. 4 |-> 0],
      tick                          |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure                 |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureQuantity         |-> [i \in 1 .. 4 |-> 0],
      settlementPrice               |-> [i \in 1 .. 8 |-> 0],
      settlementPriceTypeCalcMethod |-> [i \in 1 .. 1 |-> 0],
      totalVolume                   |-> [i \in 1 .. 4 |-> 0],
      openInterestQuantity          |-> [i \in 1 .. 4 |-> 0],
      highLimitPrice                |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice                 |-> [i \in 1 .. 8 |-> 0],
      tradingCollarVariationType    |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariation        |-> [i \in 1 .. 8 |-> 0],
      reserved16                    |-> [i \in 1 .. 16 |-> 0] ]

(* Simple Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleInstrumentDefinitionMessage ==
    { ZeroSimpleInstrumentDefinitionMessage }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.underlyingAsset = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.productGroupCode = one] : one \in Sample(6) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.settlementCurrency = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.minimumSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.maximumSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.tick = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.unitOfMeasureQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.settlementPriceTypeCalcMethod = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.openInterestQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Instrument Leg: 20 bytes                                                *)
(***************************************************************************)

InstrumentLeg ==
    [ instrumentId      : Sample(4),
      legRatioAndSide   : Sample(4),
      maturityMonthYear : Sample(4),
      reserved8         : Sample(8) ]

EncodeInstrumentLeg(message) ==
    message.instrumentId
        \o message.legRatioAndSide
        \o message.maturityMonthYear
        \o message.reserved8

DecodeInstrumentLeg(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legRatioAndSide == ReadBytes(instrumentId.rest, 4) IN IF ~legRatioAndSide.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(legRatioAndSide.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(maturityMonthYear.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ instrumentId      |-> instrumentId.value,
         legRatioAndSide   |-> legRatioAndSide.value,
         maturityMonthYear |-> maturityMonthYear.value,
         reserved8         |-> reserved8.value ], reserved8.rest)

ZeroInstrumentLeg ==
    [ instrumentId      |-> [i \in 1 .. 4 |-> 0],
      legRatioAndSide   |-> [i \in 1 .. 4 |-> 0],
      maturityMonthYear |-> [i \in 1 .. 4 |-> 0],
      reserved8         |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentLeg ==
    { ZeroInstrumentLeg }
        \cup { [ZeroInstrumentLeg EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg EXCEPT !.legRatioAndSide = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Instrument Leg, written one after another *)
RECURSIVE EncodeInstrumentLegList(_)
EncodeInstrumentLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentLeg(Head(messages)) \o EncodeInstrumentLegList(Tail(messages))

(* As many Instrument Leg as the field that counts them says *)
RECURSIVE ReadInstrumentLegList(_, _)
ReadInstrumentLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Leg of each kind, for the lists that carry them *)
OneInstrumentLeg == { ZeroInstrumentLeg }

(***************************************************************************)
(* Complex Instrument Definition Message                                   *)
(***************************************************************************)

ComplexInstrumentDefinitionMessage ==
    [ timestamp                  : Sample(8),
      strategyId                 : Sample(4),
      underlyingAssetType        : Sample(1),
      underlyingAsset            : Sample(4),
      productGroupCode           : Sample(6),
      spreadType                 : Sample(1),
      exchange                   : Sample(4),
      instrumentIdSource         : Sample(1),
      instrumentType             : Sample(1),
      currency                   : Sample(1),
      settlementCurrency         : Sample(1),
      matchAlgorithm             : Sample(1),
      minimumSize                : Sample(4),
      maximumSize                : Sample(4),
      tick                       : Sample(8),
      unitOfMeasure              : Sample(5),
      unitOfMeasureQuantity      : Sample(4),
      tradingCollarVariationType : Sample(1),
      tradingCollarVariation     : Sample(8),
      reserved16                 : Sample(16),
      instrumentLeg              : SampleLists(OneInstrumentLeg) ]

EncodeComplexInstrumentDefinitionMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.underlyingAssetType
        \o message.underlyingAsset
        \o message.productGroupCode
        \o message.spreadType
        \o message.exchange
        \o message.instrumentIdSource
        \o message.instrumentType
        \o message.currency
        \o message.settlementCurrency
        \o message.matchAlgorithm
        \o message.minimumSize
        \o message.maximumSize
        \o message.tick
        \o message.unitOfMeasure
        \o message.unitOfMeasureQuantity
        \o message.tradingCollarVariationType
        \o message.tradingCollarVariation
        \o message.reserved16
        \o EncodeUIntLE(Len(message.instrumentLeg), 1)
        \o EncodeInstrumentLegList(message.instrumentLeg)

DecodeComplexInstrumentDefinitionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(strategyId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAsset == ReadBytes(underlyingAssetType.rest, 4) IN IF ~underlyingAsset.ok THEN Fail ELSE
    LET productGroupCode == ReadBytes(underlyingAsset.rest, 6) IN IF ~productGroupCode.ok THEN Fail ELSE
    LET spreadType == ReadBytes(productGroupCode.rest, 1) IN IF ~spreadType.ok THEN Fail ELSE
    LET exchange == ReadBytes(spreadType.rest, 4) IN IF ~exchange.ok THEN Fail ELSE
    LET instrumentIdSource == ReadBytes(exchange.rest, 1) IN IF ~instrumentIdSource.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIdSource.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET currency == ReadBytes(instrumentType.rest, 1) IN IF ~currency.ok THEN Fail ELSE
    LET settlementCurrency == ReadBytes(currency.rest, 1) IN IF ~settlementCurrency.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(settlementCurrency.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minimumSize == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minimumSize.ok THEN Fail ELSE
    LET maximumSize == ReadBytes(minimumSize.rest, 4) IN IF ~maximumSize.ok THEN Fail ELSE
    LET tick == ReadBytes(maximumSize.rest, 8) IN IF ~tick.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(tick.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureQuantity == ReadBytes(unitOfMeasure.rest, 4) IN IF ~unitOfMeasureQuantity.ok THEN Fail ELSE
    LET tradingCollarVariationType == ReadBytes(unitOfMeasureQuantity.rest, 1) IN IF ~tradingCollarVariationType.ok THEN Fail ELSE
    LET tradingCollarVariation == ReadBytes(tradingCollarVariationType.rest, 8) IN IF ~tradingCollarVariation.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(tradingCollarVariation.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(reserved16.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET instrumentLeg == ReadInstrumentLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~instrumentLeg.ok THEN Fail ELSE
    Ok([ timestamp                  |-> timestamp.value,
         strategyId                 |-> strategyId.value,
         underlyingAssetType        |-> underlyingAssetType.value,
         underlyingAsset            |-> underlyingAsset.value,
         productGroupCode           |-> productGroupCode.value,
         spreadType                 |-> spreadType.value,
         exchange                   |-> exchange.value,
         instrumentIdSource         |-> instrumentIdSource.value,
         instrumentType             |-> instrumentType.value,
         currency                   |-> currency.value,
         settlementCurrency         |-> settlementCurrency.value,
         matchAlgorithm             |-> matchAlgorithm.value,
         minimumSize                |-> minimumSize.value,
         maximumSize                |-> maximumSize.value,
         tick                       |-> tick.value,
         unitOfMeasure              |-> unitOfMeasure.value,
         unitOfMeasureQuantity      |-> unitOfMeasureQuantity.value,
         tradingCollarVariationType |-> tradingCollarVariationType.value,
         tradingCollarVariation     |-> tradingCollarVariation.value,
         reserved16                 |-> reserved16.value,
         instrumentLeg              |-> instrumentLeg.value ], instrumentLeg.rest)

ZeroComplexInstrumentDefinitionMessage ==
    [ timestamp                  |-> [i \in 1 .. 8 |-> 0],
      strategyId                 |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType        |-> [i \in 1 .. 1 |-> 0],
      underlyingAsset            |-> [i \in 1 .. 4 |-> 0],
      productGroupCode           |-> [i \in 1 .. 6 |-> 0],
      spreadType                 |-> [i \in 1 .. 1 |-> 0],
      exchange                   |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource         |-> [i \in 1 .. 1 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      currency                   |-> [i \in 1 .. 1 |-> 0],
      settlementCurrency         |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm             |-> [i \in 1 .. 1 |-> 0],
      minimumSize                |-> [i \in 1 .. 4 |-> 0],
      maximumSize                |-> [i \in 1 .. 4 |-> 0],
      tick                       |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure              |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureQuantity      |-> [i \in 1 .. 4 |-> 0],
      tradingCollarVariationType |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariation     |-> [i \in 1 .. 8 |-> 0],
      reserved16                 |-> [i \in 1 .. 16 |-> 0],
      instrumentLeg              |-> << >> ]

(* Complex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionMessage ==
    { ZeroComplexInstrumentDefinitionMessage }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.underlyingAsset = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.productGroupCode = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.spreadType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.settlementCurrency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.minimumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.maximumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.tick = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.unitOfMeasureQuantity = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.instrumentLeg = one] : one \in SampleLists(OneInstrumentLeg) }

(***************************************************************************)
(* System State Message: 18 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ timestamp    : Sample(8),
      tomVersion   : Sample(8),
      sessionId    : Sample(1),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.timestamp
        \o message.tomVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tomVersion == ReadBytes(timestamp.rest, 8) IN IF ~tomVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(tomVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         tomVersion   |-> tomVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      tomVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.tomVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Trading Status Notification Message: 14 bytes                *)
(***************************************************************************)

InstrumentTradingStatusNotificationMessage ==
    [ timestamp     : Sample(8),
      instrumentId  : Sample(4),
      tradingStatus : Sample(1),
      marketState   : Sample(1) ]

EncodeInstrumentTradingStatusNotificationMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.tradingStatus
        \o message.marketState

DecodeInstrumentTradingStatusNotificationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(instrumentId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketState == ReadBytes(tradingStatus.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         instrumentId  |-> instrumentId.value,
         tradingStatus |-> tradingStatus.value,
         marketState   |-> marketState.value ], marketState.rest)

ZeroInstrumentTradingStatusNotificationMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketState   |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentTradingStatusNotificationMessage ==
    { ZeroInstrumentTradingStatusNotificationMessage }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage EXCEPT !.marketState = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Bid And Offer Message: 36 bytes                                    *)
(***************************************************************************)

BestBidAndOfferMessage ==
    [ timestamp    : Sample(8),
      instrumentId : Sample(4),
      mbbPrice     : Sample(8),
      mbbSize      : Sample(4),
      mboPrice     : Sample(8),
      mboSize      : Sample(4) ]

EncodeBestBidAndOfferMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.mbbPrice
        \o message.mbbSize
        \o message.mboPrice
        \o message.mboSize

DecodeBestBidAndOfferMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET mbbPrice == ReadBytes(instrumentId.rest, 8) IN IF ~mbbPrice.ok THEN Fail ELSE
    LET mbbSize == ReadBytes(mbbPrice.rest, 4) IN IF ~mbbSize.ok THEN Fail ELSE
    LET mboPrice == ReadBytes(mbbSize.rest, 8) IN IF ~mboPrice.ok THEN Fail ELSE
    LET mboSize == ReadBytes(mboPrice.rest, 4) IN IF ~mboSize.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         instrumentId |-> instrumentId.value,
         mbbPrice     |-> mbbPrice.value,
         mbbSize      |-> mbbSize.value,
         mboPrice     |-> mboPrice.value,
         mboSize      |-> mboSize.value ], mboSize.rest)

ZeroBestBidAndOfferMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      mbbPrice     |-> [i \in 1 .. 8 |-> 0],
      mbbSize      |-> [i \in 1 .. 4 |-> 0],
      mboPrice     |-> [i \in 1 .. 8 |-> 0],
      mboSize      |-> [i \in 1 .. 4 |-> 0] ]

(* Best Bid And Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidAndOfferMessage ==
    { ZeroBestBidAndOfferMessage }
        \cup { [ZeroBestBidAndOfferMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAndOfferMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndOfferMessage EXCEPT !.mbbPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAndOfferMessage EXCEPT !.mbbSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndOfferMessage EXCEPT !.mboPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAndOfferMessage EXCEPT !.mboSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Last Sale Message: 32 bytes                                             *)
(***************************************************************************)

LastSaleMessage ==
    [ timestamp    : Sample(8),
      instrumentId : Sample(4),
      tradeId      : Sample(8),
      price        : Sample(8),
      size         : Sample(4) ]

EncodeLastSaleMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.tradeId
        \o message.price
        \o message.size

DecodeLastSaleMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         instrumentId |-> instrumentId.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         size         |-> size.value ], size.rest)

ZeroLastSaleMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      size         |-> [i \in 1 .. 4 |-> 0] ]

(* Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedLastSaleMessage ==
    { ZeroLastSaleMessage }
        \cup { [ZeroLastSaleMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.size = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Cancel Message: 35 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ timestamp        : Sample(8),
      tradeDate        : Sample(2),
      instrumentId     : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4) ]

EncodeTradeCancelMessage(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size

DecodeTradeCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         tradeDate        |-> tradeDate.value,
         instrumentId     |-> instrumentId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value ], size.rest)

ZeroTradeCancelMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.size = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SimpleInstrumentDefinitionMessageCode == 1  \* 0x01
ComplexInstrumentDefinitionMessageCode == 2  \* 0x02
SystemStateMessageCode == 3  \* 0x03
InstrumentTradingStatusNotificationMessageCode == 4  \* 0x04
BestBidAndOfferMessageCode == 15  \* 0x0f
LastSaleMessageCode == 16  \* 0x10
TradeCancelMessageCode == 14  \* 0x0e

Data ==
    [ tag : {SimpleInstrumentDefinitionMessageCode}, body : SimpleInstrumentDefinitionMessage ]
        \cup [ tag : {ComplexInstrumentDefinitionMessageCode}, body : ComplexInstrumentDefinitionMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {InstrumentTradingStatusNotificationMessageCode}, body : InstrumentTradingStatusNotificationMessage ]
        \cup [ tag : {BestBidAndOfferMessageCode}, body : BestBidAndOfferMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]

EncodeData(message) ==
    CASE message.tag = SimpleInstrumentDefinitionMessageCode -> EncodeSimpleInstrumentDefinitionMessage(message.body)
      [] message.tag = ComplexInstrumentDefinitionMessageCode -> EncodeComplexInstrumentDefinitionMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = InstrumentTradingStatusNotificationMessageCode -> EncodeInstrumentTradingStatusNotificationMessage(message.body)
      [] message.tag = BestBidAndOfferMessageCode -> EncodeBestBidAndOfferMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SimpleInstrumentDefinitionMessageCode -> DecodeSimpleInstrumentDefinitionMessage(bytes)
              [] tag = ComplexInstrumentDefinitionMessageCode -> DecodeComplexInstrumentDefinitionMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = InstrumentTradingStatusNotificationMessageCode -> DecodeInstrumentTradingStatusNotificationMessage(bytes)
              [] tag = BestBidAndOfferMessageCode -> DecodeBestBidAndOfferMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SimpleInstrumentDefinitionMessageCode, body |-> ZeroSimpleInstrumentDefinitionMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SimpleInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedSimpleInstrumentDefinitionMessage }
        \cup { [tag |-> ComplexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedComplexInstrumentDefinitionMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> InstrumentTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedInstrumentTradingStatusNotificationMessage }
        \cup { [tag |-> BestBidAndOfferMessageCode, body |-> one] : one \in CheckedBestBidAndOfferMessage }
        \cup { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }

(***************************************************************************)
(* Application Message                                                     *)
(***************************************************************************)

ApplicationMessage ==
    [ data : Data ]

EncodeApplicationMessage(message) ==
    EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeApplicationMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroApplicationMessage ==
    [ data |-> ZeroData ]

(* Application Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationMessage ==
    { ZeroApplicationMessage }
        \cup { [ZeroApplicationMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Payload, selected by Packet Type                                        *)
(***************************************************************************)

ApplicationMessageCode == 3  \* 0x03
HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02

Payload ==
    [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]
        \cup [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)
      [] message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }
        \cup { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Mach Message, framed by Packet Length                                   *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o message.sessionNumber
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeMachMessage(message) ==
    LET body == EncodeMachMessageBody(message)
    IN  message.sequenceNumber \o EncodeUIntLE(Len(body) + 10, 2) \o body

DecodeMachMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 10 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET packetType == ReadUIntBE(framed, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET sessionNumber == ReadBytes(packetType.rest, 1) IN IF ~sessionNumber.ok THEN Fail ELSE
    LET payload == DecodePayload(packetType.value, sessionNumber.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         sessionNumber  |-> sessionNumber.value,
         payload        |-> payload.value ], beyond)

ZeroMachMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sessionNumber  |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Mach Message at zero, then each field in turn at the values it is checked at *)
CheckedMachMessage ==
    { ZeroMachMessage }
        \cup { [ZeroMachMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMachMessage EXCEPT !.sessionNumber = one] : one \in Sample(1) }
        \cup { [ZeroMachMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodePacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodePacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroPacket ==
    [ machMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every Simple Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleInstrumentDefinitionMessage ==
    \A message \in CheckedSimpleInstrumentDefinitionMessage :
        LET read == DecodeSimpleInstrumentDefinitionMessage(EncodeSimpleInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentLeg ==
    \A message \in CheckedInstrumentLeg :
        LET read == DecodeInstrumentLeg(EncodeInstrumentLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDefinitionMessage ==
    \A message \in CheckedComplexInstrumentDefinitionMessage :
        LET read == DecodeComplexInstrumentDefinitionMessage(EncodeComplexInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage ==
    \A message \in CheckedSystemStateMessage :
        LET read == DecodeSystemStateMessage(EncodeSystemStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Trading Status Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentTradingStatusNotificationMessage ==
    \A message \in CheckedInstrumentTradingStatusNotificationMessage :
        LET read == DecodeInstrumentTradingStatusNotificationMessage(EncodeInstrumentTradingStatusNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid And Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidAndOfferMessage ==
    \A message \in CheckedBestBidAndOfferMessage :
        LET read == DecodeBestBidAndOfferMessage(EncodeBestBidAndOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastSaleMessage ==
    \A message \in CheckedLastSaleMessage :
        LET read == DecodeLastSaleMessage(EncodeLastSaleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationMessage ==
    \A message \in CheckedApplicationMessage :
        LET read == DecodeApplicationMessage(EncodeApplicationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
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

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET read == DecodeData(message.tag, EncodeData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
