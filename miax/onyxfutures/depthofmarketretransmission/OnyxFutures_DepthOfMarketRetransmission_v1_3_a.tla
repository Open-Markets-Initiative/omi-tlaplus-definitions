---------- MODULE OnyxFutures_DepthOfMarketRetransmission_v1_3_a -----------
(***************************************************************************)
(* Miami International Holdings Depth Of Market Retransmission v1.3.a      *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Sesm Packet *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Refresh Response fills what is left of the frame Sesm Packet      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Unsequenced Data Packet fills what is left of the frame Sesm      *)
(* Packet Length states, which is what it is read from.                    *)
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
(* Simple Instrument Definition Message: 138 bytes                         *)
(***************************************************************************)

SimpleInstrumentDefinitionMessage ==
    [ timestamp                     : Sample(8),
      instrumentId                  : Sample(4),
      underlyingAssetType           : Sample(1),
      underlyingAssetAlphanumeric4  : Sample(4),
      productGroupCodeAlphanumeric6 : Sample(6),
      exchange                      : Sample(4),
      instrumentIdSource            : Sample(1),
      instrumentType                : Sample(1),
      instrumentListingStatus       : Sample(1),
      reserved3                     : Sample(3),
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
      contractDate                  : Sample(4),
      maturityDate                  : Sample(2),
      valuationDate                 : Sample(2),
      firstTradeDate                : Sample(2),
      lastTradeDate                 : Sample(2),
      firstNoticeDate               : Sample(2),
      lastNoticeDate                : Sample(2),
      firstDeliveryDate             : Sample(2),
      lastDeliveryDate              : Sample(2),
      optionStrikePrice             : Sample(8),
      optionStrikeCurrency          : Sample(1),
      optionType                    : Sample(1),
      optionExpirationType          : Sample(1),
      underlyingFutureInstrumentId  : Sample(4) ]

EncodeSimpleInstrumentDefinitionMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.underlyingAssetType
        \o message.underlyingAssetAlphanumeric4
        \o message.productGroupCodeAlphanumeric6
        \o message.exchange
        \o message.instrumentIdSource
        \o message.instrumentType
        \o message.instrumentListingStatus
        \o message.reserved3
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
        \o message.contractDate
        \o message.maturityDate
        \o message.valuationDate
        \o message.firstTradeDate
        \o message.lastTradeDate
        \o message.firstNoticeDate
        \o message.lastNoticeDate
        \o message.firstDeliveryDate
        \o message.lastDeliveryDate
        \o message.optionStrikePrice
        \o message.optionStrikeCurrency
        \o message.optionType
        \o message.optionExpirationType
        \o message.underlyingFutureInstrumentId

DecodeSimpleInstrumentDefinitionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAssetAlphanumeric4 == ReadBytes(underlyingAssetType.rest, 4) IN IF ~underlyingAssetAlphanumeric4.ok THEN Fail ELSE
    LET productGroupCodeAlphanumeric6 == ReadBytes(underlyingAssetAlphanumeric4.rest, 6) IN IF ~productGroupCodeAlphanumeric6.ok THEN Fail ELSE
    LET exchange == ReadBytes(productGroupCodeAlphanumeric6.rest, 4) IN IF ~exchange.ok THEN Fail ELSE
    LET instrumentIdSource == ReadBytes(exchange.rest, 1) IN IF ~instrumentIdSource.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIdSource.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentListingStatus == ReadBytes(instrumentType.rest, 1) IN IF ~instrumentListingStatus.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(instrumentListingStatus.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    LET currency == ReadBytes(reserved3.rest, 1) IN IF ~currency.ok THEN Fail ELSE
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
    LET contractDate == ReadBytes(tradingCollarVariation.rest, 4) IN IF ~contractDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(contractDate.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET valuationDate == ReadBytes(maturityDate.rest, 2) IN IF ~valuationDate.ok THEN Fail ELSE
    LET firstTradeDate == ReadBytes(valuationDate.rest, 2) IN IF ~firstTradeDate.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(firstTradeDate.rest, 2) IN IF ~lastTradeDate.ok THEN Fail ELSE
    LET firstNoticeDate == ReadBytes(lastTradeDate.rest, 2) IN IF ~firstNoticeDate.ok THEN Fail ELSE
    LET lastNoticeDate == ReadBytes(firstNoticeDate.rest, 2) IN IF ~lastNoticeDate.ok THEN Fail ELSE
    LET firstDeliveryDate == ReadBytes(lastNoticeDate.rest, 2) IN IF ~firstDeliveryDate.ok THEN Fail ELSE
    LET lastDeliveryDate == ReadBytes(firstDeliveryDate.rest, 2) IN IF ~lastDeliveryDate.ok THEN Fail ELSE
    LET optionStrikePrice == ReadBytes(lastDeliveryDate.rest, 8) IN IF ~optionStrikePrice.ok THEN Fail ELSE
    LET optionStrikeCurrency == ReadBytes(optionStrikePrice.rest, 1) IN IF ~optionStrikeCurrency.ok THEN Fail ELSE
    LET optionType == ReadBytes(optionStrikeCurrency.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET optionExpirationType == ReadBytes(optionType.rest, 1) IN IF ~optionExpirationType.ok THEN Fail ELSE
    LET underlyingFutureInstrumentId == ReadBytes(optionExpirationType.rest, 4) IN IF ~underlyingFutureInstrumentId.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         instrumentId                  |-> instrumentId.value,
         underlyingAssetType           |-> underlyingAssetType.value,
         underlyingAssetAlphanumeric4  |-> underlyingAssetAlphanumeric4.value,
         productGroupCodeAlphanumeric6 |-> productGroupCodeAlphanumeric6.value,
         exchange                      |-> exchange.value,
         instrumentIdSource            |-> instrumentIdSource.value,
         instrumentType                |-> instrumentType.value,
         instrumentListingStatus       |-> instrumentListingStatus.value,
         reserved3                     |-> reserved3.value,
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
         contractDate                  |-> contractDate.value,
         maturityDate                  |-> maturityDate.value,
         valuationDate                 |-> valuationDate.value,
         firstTradeDate                |-> firstTradeDate.value,
         lastTradeDate                 |-> lastTradeDate.value,
         firstNoticeDate               |-> firstNoticeDate.value,
         lastNoticeDate                |-> lastNoticeDate.value,
         firstDeliveryDate             |-> firstDeliveryDate.value,
         lastDeliveryDate              |-> lastDeliveryDate.value,
         optionStrikePrice             |-> optionStrikePrice.value,
         optionStrikeCurrency          |-> optionStrikeCurrency.value,
         optionType                    |-> optionType.value,
         optionExpirationType          |-> optionExpirationType.value,
         underlyingFutureInstrumentId  |-> underlyingFutureInstrumentId.value ], underlyingFutureInstrumentId.rest)

ZeroSimpleInstrumentDefinitionMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType           |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetAlphanumeric4  |-> [i \in 1 .. 4 |-> 0],
      productGroupCodeAlphanumeric6 |-> [i \in 1 .. 6 |-> 0],
      exchange                      |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource            |-> [i \in 1 .. 1 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      instrumentListingStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved3                     |-> [i \in 1 .. 3 |-> 0],
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
      contractDate                  |-> [i \in 1 .. 4 |-> 0],
      maturityDate                  |-> [i \in 1 .. 2 |-> 0],
      valuationDate                 |-> [i \in 1 .. 2 |-> 0],
      firstTradeDate                |-> [i \in 1 .. 2 |-> 0],
      lastTradeDate                 |-> [i \in 1 .. 2 |-> 0],
      firstNoticeDate               |-> [i \in 1 .. 2 |-> 0],
      lastNoticeDate                |-> [i \in 1 .. 2 |-> 0],
      firstDeliveryDate             |-> [i \in 1 .. 2 |-> 0],
      lastDeliveryDate              |-> [i \in 1 .. 2 |-> 0],
      optionStrikePrice             |-> [i \in 1 .. 8 |-> 0],
      optionStrikeCurrency          |-> [i \in 1 .. 1 |-> 0],
      optionType                    |-> [i \in 1 .. 1 |-> 0],
      optionExpirationType          |-> [i \in 1 .. 1 |-> 0],
      underlyingFutureInstrumentId  |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleInstrumentDefinitionMessage ==
    { ZeroSimpleInstrumentDefinitionMessage }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.underlyingAssetAlphanumeric4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.productGroupCodeAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.instrumentListingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }
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
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.contractDate = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.valuationDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.firstTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.lastTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.firstNoticeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.lastNoticeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.firstDeliveryDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.lastDeliveryDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.optionStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.optionStrikeCurrency = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.optionExpirationType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage EXCEPT !.underlyingFutureInstrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Leg: 42 bytes                                                *)
(***************************************************************************)

InstrumentLeg ==
    [ instrumentId    : Sample(4),
      legRatioAndSide : Sample(4),
      maturityDate    : Sample(2),
      reserved32      : Sample(32) ]

EncodeInstrumentLeg(message) ==
    message.instrumentId
        \o message.legRatioAndSide
        \o message.maturityDate
        \o message.reserved32

DecodeInstrumentLeg(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legRatioAndSide == ReadBytes(instrumentId.rest, 4) IN IF ~legRatioAndSide.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(legRatioAndSide.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(maturityDate.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ instrumentId    |-> instrumentId.value,
         legRatioAndSide |-> legRatioAndSide.value,
         maturityDate    |-> maturityDate.value,
         reserved32      |-> reserved32.value ], reserved32.rest)

ZeroInstrumentLeg ==
    [ instrumentId    |-> [i \in 1 .. 4 |-> 0],
      legRatioAndSide |-> [i \in 1 .. 4 |-> 0],
      maturityDate    |-> [i \in 1 .. 2 |-> 0],
      reserved32      |-> [i \in 1 .. 32 |-> 0] ]

(* Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentLeg ==
    { ZeroInstrumentLeg }
        \cup { [ZeroInstrumentLeg EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg EXCEPT !.legRatioAndSide = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentLeg EXCEPT !.reserved32 = one] : one \in Sample(32) }

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
    [ timestamp                      : Sample(8),
      instrumentId                   : Sample(4),
      underlyingAssetType            : Sample(1),
      underlyingAssetAlphanumeric9   : Sample(9),
      productGroupCodeAlphanumeric13 : Sample(13),
      spreadType                     : Sample(1),
      exchange                       : Sample(4),
      instrumentIdSource             : Sample(1),
      instrumentType                 : Sample(1),
      currency                       : Sample(1),
      settlementCurrency             : Sample(1),
      matchAlgorithm                 : Sample(1),
      minimumSize                    : Sample(4),
      maximumSize                    : Sample(4),
      tick                           : Sample(8),
      unitOfMeasure                  : Sample(5),
      unitOfMeasureQuantity          : Sample(4),
      settlementPrice                : Sample(8),
      settlementPriceTypeCalcMethod  : Sample(1),
      tradingCollarVariationType     : Sample(1),
      tradingCollarVariation         : Sample(8),
      instrumentListingStatus        : Sample(1),
      firstTradeDate                 : Sample(2),
      reserved64                     : Sample(64),
      instrumentLeg                  : SampleLists(OneInstrumentLeg) ]

EncodeComplexInstrumentDefinitionMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.underlyingAssetType
        \o message.underlyingAssetAlphanumeric9
        \o message.productGroupCodeAlphanumeric13
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
        \o message.settlementPrice
        \o message.settlementPriceTypeCalcMethod
        \o message.tradingCollarVariationType
        \o message.tradingCollarVariation
        \o message.instrumentListingStatus
        \o message.firstTradeDate
        \o message.reserved64
        \o EncodeUIntLE(Len(message.instrumentLeg), 1)
        \o EncodeInstrumentLegList(message.instrumentLeg)

DecodeComplexInstrumentDefinitionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAssetAlphanumeric9 == ReadBytes(underlyingAssetType.rest, 9) IN IF ~underlyingAssetAlphanumeric9.ok THEN Fail ELSE
    LET productGroupCodeAlphanumeric13 == ReadBytes(underlyingAssetAlphanumeric9.rest, 13) IN IF ~productGroupCodeAlphanumeric13.ok THEN Fail ELSE
    LET spreadType == ReadBytes(productGroupCodeAlphanumeric13.rest, 1) IN IF ~spreadType.ok THEN Fail ELSE
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
    LET settlementPrice == ReadBytes(unitOfMeasureQuantity.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceTypeCalcMethod == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceTypeCalcMethod.ok THEN Fail ELSE
    LET tradingCollarVariationType == ReadBytes(settlementPriceTypeCalcMethod.rest, 1) IN IF ~tradingCollarVariationType.ok THEN Fail ELSE
    LET tradingCollarVariation == ReadBytes(tradingCollarVariationType.rest, 8) IN IF ~tradingCollarVariation.ok THEN Fail ELSE
    LET instrumentListingStatus == ReadBytes(tradingCollarVariation.rest, 1) IN IF ~instrumentListingStatus.ok THEN Fail ELSE
    LET firstTradeDate == ReadBytes(instrumentListingStatus.rest, 2) IN IF ~firstTradeDate.ok THEN Fail ELSE
    LET reserved64 == ReadBytes(firstTradeDate.rest, 64) IN IF ~reserved64.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(reserved64.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET instrumentLeg == ReadInstrumentLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~instrumentLeg.ok THEN Fail ELSE
    Ok([ timestamp                      |-> timestamp.value,
         instrumentId                   |-> instrumentId.value,
         underlyingAssetType            |-> underlyingAssetType.value,
         underlyingAssetAlphanumeric9   |-> underlyingAssetAlphanumeric9.value,
         productGroupCodeAlphanumeric13 |-> productGroupCodeAlphanumeric13.value,
         spreadType                     |-> spreadType.value,
         exchange                       |-> exchange.value,
         instrumentIdSource             |-> instrumentIdSource.value,
         instrumentType                 |-> instrumentType.value,
         currency                       |-> currency.value,
         settlementCurrency             |-> settlementCurrency.value,
         matchAlgorithm                 |-> matchAlgorithm.value,
         minimumSize                    |-> minimumSize.value,
         maximumSize                    |-> maximumSize.value,
         tick                           |-> tick.value,
         unitOfMeasure                  |-> unitOfMeasure.value,
         unitOfMeasureQuantity          |-> unitOfMeasureQuantity.value,
         settlementPrice                |-> settlementPrice.value,
         settlementPriceTypeCalcMethod  |-> settlementPriceTypeCalcMethod.value,
         tradingCollarVariationType     |-> tradingCollarVariationType.value,
         tradingCollarVariation         |-> tradingCollarVariation.value,
         instrumentListingStatus        |-> instrumentListingStatus.value,
         firstTradeDate                 |-> firstTradeDate.value,
         reserved64                     |-> reserved64.value,
         instrumentLeg                  |-> instrumentLeg.value ], instrumentLeg.rest)

ZeroComplexInstrumentDefinitionMessage ==
    [ timestamp                      |-> [i \in 1 .. 8 |-> 0],
      instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType            |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetAlphanumeric9   |-> [i \in 1 .. 9 |-> 0],
      productGroupCodeAlphanumeric13 |-> [i \in 1 .. 13 |-> 0],
      spreadType                     |-> [i \in 1 .. 1 |-> 0],
      exchange                       |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource             |-> [i \in 1 .. 1 |-> 0],
      instrumentType                 |-> [i \in 1 .. 1 |-> 0],
      currency                       |-> [i \in 1 .. 1 |-> 0],
      settlementCurrency             |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm                 |-> [i \in 1 .. 1 |-> 0],
      minimumSize                    |-> [i \in 1 .. 4 |-> 0],
      maximumSize                    |-> [i \in 1 .. 4 |-> 0],
      tick                           |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure                  |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureQuantity          |-> [i \in 1 .. 4 |-> 0],
      settlementPrice                |-> [i \in 1 .. 8 |-> 0],
      settlementPriceTypeCalcMethod  |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariationType     |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariation         |-> [i \in 1 .. 8 |-> 0],
      instrumentListingStatus        |-> [i \in 1 .. 1 |-> 0],
      firstTradeDate                 |-> [i \in 1 .. 2 |-> 0],
      reserved64                     |-> [i \in 1 .. 64 |-> 0],
      instrumentLeg                  |-> << >> ]

(* Complex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionMessage ==
    { ZeroComplexInstrumentDefinitionMessage }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.underlyingAssetAlphanumeric9 = one] : one \in Sample(9) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.productGroupCodeAlphanumeric13 = one] : one \in Sample(13) }
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
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.settlementPriceTypeCalcMethod = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.instrumentListingStatus = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.firstTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.reserved64 = one] : one \in Sample(64) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.instrumentLeg = one] : one \in SampleLists(OneInstrumentLeg) }

(***************************************************************************)
(* Deprecated Instrument Leg: 20 bytes                                     *)
(***************************************************************************)

DeprecatedInstrumentLeg ==
    [ instrumentId    : Sample(4),
      legRatioAndSide : Sample(4),
      reserved4       : Sample(4),
      maturityDate    : Sample(2),
      reserved6       : Sample(6) ]

EncodeDeprecatedInstrumentLeg(message) ==
    message.instrumentId
        \o message.legRatioAndSide
        \o message.reserved4
        \o message.maturityDate
        \o message.reserved6

DecodeDeprecatedInstrumentLeg(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legRatioAndSide == ReadBytes(instrumentId.rest, 4) IN IF ~legRatioAndSide.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(legRatioAndSide.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(reserved4.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(maturityDate.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    Ok([ instrumentId    |-> instrumentId.value,
         legRatioAndSide |-> legRatioAndSide.value,
         reserved4       |-> reserved4.value,
         maturityDate    |-> maturityDate.value,
         reserved6       |-> reserved6.value ], reserved6.rest)

ZeroDeprecatedInstrumentLeg ==
    [ instrumentId    |-> [i \in 1 .. 4 |-> 0],
      legRatioAndSide |-> [i \in 1 .. 4 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0],
      maturityDate    |-> [i \in 1 .. 2 |-> 0],
      reserved6       |-> [i \in 1 .. 6 |-> 0] ]

(* Deprecated Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedInstrumentLeg ==
    { ZeroDeprecatedInstrumentLeg }
        \cup { [ZeroDeprecatedInstrumentLeg EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedInstrumentLeg EXCEPT !.legRatioAndSide = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedInstrumentLeg EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedInstrumentLeg EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedInstrumentLeg EXCEPT !.reserved6 = one] : one \in Sample(6) }

(* A run of Deprecated Instrument Leg, written one after another *)
RECURSIVE EncodeDeprecatedInstrumentLegList(_)
EncodeDeprecatedInstrumentLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDeprecatedInstrumentLeg(Head(messages)) \o EncodeDeprecatedInstrumentLegList(Tail(messages))

(* As many Deprecated Instrument Leg as the field that counts them says *)
RECURSIVE ReadDeprecatedInstrumentLegList(_, _)
ReadDeprecatedInstrumentLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDeprecatedInstrumentLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDeprecatedInstrumentLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Deprecated Instrument Leg of each kind, for the lists that carry them *)
OneDeprecatedInstrumentLeg == { ZeroDeprecatedInstrumentLeg }

(***************************************************************************)
(* Complex Instrument Definition Deprecated Message                        *)
(***************************************************************************)

ComplexInstrumentDefinitionDeprecatedMessage ==
    [ timestamp                             : Sample(8),
      instrumentIdFormerlyKnownAsStrategyId : Sample(4),
      underlyingAssetType                   : Sample(1),
      underlyingAssetAlphanumeric4          : Sample(4),
      productGroupCodeAlphanumeric6         : Sample(6),
      spreadType                            : Sample(1),
      exchange                              : Sample(4),
      instrumentIdSource                    : Sample(1),
      instrumentType                        : Sample(1),
      currency                              : Sample(1),
      settlementCurrency                    : Sample(1),
      matchAlgorithm                        : Sample(1),
      minimumSize                           : Sample(4),
      maximumSize                           : Sample(4),
      tick                                  : Sample(8),
      unitOfMeasure                         : Sample(5),
      unitOfMeasureQuantity                 : Sample(4),
      tradingCollarVariationType            : Sample(1),
      tradingCollarVariation                : Sample(8),
      reserved16                            : Sample(16),
      deprecatedInstrumentLeg               : SampleLists(OneDeprecatedInstrumentLeg) ]

EncodeComplexInstrumentDefinitionDeprecatedMessage(message) ==
    message.timestamp
        \o message.instrumentIdFormerlyKnownAsStrategyId
        \o message.underlyingAssetType
        \o message.underlyingAssetAlphanumeric4
        \o message.productGroupCodeAlphanumeric6
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
        \o EncodeUIntLE(Len(message.deprecatedInstrumentLeg), 1)
        \o EncodeDeprecatedInstrumentLegList(message.deprecatedInstrumentLeg)

DecodeComplexInstrumentDefinitionDeprecatedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentIdFormerlyKnownAsStrategyId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentIdFormerlyKnownAsStrategyId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentIdFormerlyKnownAsStrategyId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAssetAlphanumeric4 == ReadBytes(underlyingAssetType.rest, 4) IN IF ~underlyingAssetAlphanumeric4.ok THEN Fail ELSE
    LET productGroupCodeAlphanumeric6 == ReadBytes(underlyingAssetAlphanumeric4.rest, 6) IN IF ~productGroupCodeAlphanumeric6.ok THEN Fail ELSE
    LET spreadType == ReadBytes(productGroupCodeAlphanumeric6.rest, 1) IN IF ~spreadType.ok THEN Fail ELSE
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
    LET deprecatedInstrumentLeg == ReadDeprecatedInstrumentLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~deprecatedInstrumentLeg.ok THEN Fail ELSE
    Ok([ timestamp                             |-> timestamp.value,
         instrumentIdFormerlyKnownAsStrategyId |-> instrumentIdFormerlyKnownAsStrategyId.value,
         underlyingAssetType                   |-> underlyingAssetType.value,
         underlyingAssetAlphanumeric4          |-> underlyingAssetAlphanumeric4.value,
         productGroupCodeAlphanumeric6         |-> productGroupCodeAlphanumeric6.value,
         spreadType                            |-> spreadType.value,
         exchange                              |-> exchange.value,
         instrumentIdSource                    |-> instrumentIdSource.value,
         instrumentType                        |-> instrumentType.value,
         currency                              |-> currency.value,
         settlementCurrency                    |-> settlementCurrency.value,
         matchAlgorithm                        |-> matchAlgorithm.value,
         minimumSize                           |-> minimumSize.value,
         maximumSize                           |-> maximumSize.value,
         tick                                  |-> tick.value,
         unitOfMeasure                         |-> unitOfMeasure.value,
         unitOfMeasureQuantity                 |-> unitOfMeasureQuantity.value,
         tradingCollarVariationType            |-> tradingCollarVariationType.value,
         tradingCollarVariation                |-> tradingCollarVariation.value,
         reserved16                            |-> reserved16.value,
         deprecatedInstrumentLeg               |-> deprecatedInstrumentLeg.value ], deprecatedInstrumentLeg.rest)

ZeroComplexInstrumentDefinitionDeprecatedMessage ==
    [ timestamp                             |-> [i \in 1 .. 8 |-> 0],
      instrumentIdFormerlyKnownAsStrategyId |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType                   |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetAlphanumeric4          |-> [i \in 1 .. 4 |-> 0],
      productGroupCodeAlphanumeric6         |-> [i \in 1 .. 6 |-> 0],
      spreadType                            |-> [i \in 1 .. 1 |-> 0],
      exchange                              |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource                    |-> [i \in 1 .. 1 |-> 0],
      instrumentType                        |-> [i \in 1 .. 1 |-> 0],
      currency                              |-> [i \in 1 .. 1 |-> 0],
      settlementCurrency                    |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm                        |-> [i \in 1 .. 1 |-> 0],
      minimumSize                           |-> [i \in 1 .. 4 |-> 0],
      maximumSize                           |-> [i \in 1 .. 4 |-> 0],
      tick                                  |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure                         |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureQuantity                 |-> [i \in 1 .. 4 |-> 0],
      tradingCollarVariationType            |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariation                |-> [i \in 1 .. 8 |-> 0],
      reserved16                            |-> [i \in 1 .. 16 |-> 0],
      deprecatedInstrumentLeg               |-> << >> ]

(* Complex Instrument Definition Deprecated Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionDeprecatedMessage ==
    { ZeroComplexInstrumentDefinitionDeprecatedMessage }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.instrumentIdFormerlyKnownAsStrategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.underlyingAssetAlphanumeric4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.productGroupCodeAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.spreadType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.settlementCurrency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.minimumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.maximumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.tick = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.unitOfMeasureQuantity = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage EXCEPT !.deprecatedInstrumentLeg = one] : one \in SampleLists(OneDeprecatedInstrumentLeg) }

(***************************************************************************)
(* System State Message: 18 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ timestamp    : Sample(8),
      doMVersion   : Sample(8),
      sessionId    : Sample(1),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.timestamp
        \o message.doMVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET doMVersion == ReadBytes(timestamp.rest, 8) IN IF ~doMVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(doMVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         doMVersion   |-> doMVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      doMVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.doMVersion = one] : one \in Sample(8) }
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
(* Anticipated Opening Price Message: 25 bytes                             *)
(***************************************************************************)

AnticipatedOpeningPriceMessage ==
    [ timestamp               : Sample(8),
      instrumentId            : Sample(4),
      anticipatedOpeningPrice : Sample(8),
      openingMatchQuantity    : Sample(4),
      instrumentType          : Sample(1) ]

EncodeAnticipatedOpeningPriceMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.anticipatedOpeningPrice
        \o message.openingMatchQuantity
        \o message.instrumentType

DecodeAnticipatedOpeningPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET anticipatedOpeningPrice == ReadBytes(instrumentId.rest, 8) IN IF ~anticipatedOpeningPrice.ok THEN Fail ELSE
    LET openingMatchQuantity == ReadBytes(anticipatedOpeningPrice.rest, 4) IN IF ~openingMatchQuantity.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(openingMatchQuantity.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         instrumentId            |-> instrumentId.value,
         anticipatedOpeningPrice |-> anticipatedOpeningPrice.value,
         openingMatchQuantity    |-> openingMatchQuantity.value,
         instrumentType          |-> instrumentType.value ], instrumentType.rest)

ZeroAnticipatedOpeningPriceMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      anticipatedOpeningPrice |-> [i \in 1 .. 8 |-> 0],
      openingMatchQuantity    |-> [i \in 1 .. 4 |-> 0],
      instrumentType          |-> [i \in 1 .. 1 |-> 0] ]

(* Anticipated Opening Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAnticipatedOpeningPriceMessage ==
    { ZeroAnticipatedOpeningPriceMessage }
        \cup { [ZeroAnticipatedOpeningPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAnticipatedOpeningPriceMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAnticipatedOpeningPriceMessage EXCEPT !.anticipatedOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnticipatedOpeningPriceMessage EXCEPT !.openingMatchQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAnticipatedOpeningPriceMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Settlement Price Update Message: 24 bytes                               *)
(***************************************************************************)

SettlementPriceUpdateMessage ==
    [ timestamp                     : Sample(8),
      tradeDate                     : Sample(2),
      instrumentId                  : Sample(4),
      settlementPrice               : Sample(8),
      settlementPriceType           : Sample(1),
      settlementPriceTypeCalcMethod : Sample(1) ]

EncodeSettlementPriceUpdateMessage(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.settlementPrice
        \o message.settlementPriceType
        \o message.settlementPriceTypeCalcMethod

DecodeSettlementPriceUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(instrumentId.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceType == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceType.ok THEN Fail ELSE
    LET settlementPriceTypeCalcMethod == ReadBytes(settlementPriceType.rest, 1) IN IF ~settlementPriceTypeCalcMethod.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         tradeDate                     |-> tradeDate.value,
         instrumentId                  |-> instrumentId.value,
         settlementPrice               |-> settlementPrice.value,
         settlementPriceType           |-> settlementPriceType.value,
         settlementPriceTypeCalcMethod |-> settlementPriceTypeCalcMethod.value ], settlementPriceTypeCalcMethod.rest)

ZeroSettlementPriceUpdateMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      tradeDate                     |-> [i \in 1 .. 2 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      settlementPrice               |-> [i \in 1 .. 8 |-> 0],
      settlementPriceType           |-> [i \in 1 .. 1 |-> 0],
      settlementPriceTypeCalcMethod |-> [i \in 1 .. 1 |-> 0] ]

(* Settlement Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementPriceUpdateMessage ==
    { ZeroSettlementPriceUpdateMessage }
        \cup { [ZeroSettlementPriceUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceUpdateMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSettlementPriceUpdateMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSettlementPriceUpdateMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceUpdateMessage EXCEPT !.settlementPriceType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPriceUpdateMessage EXCEPT !.settlementPriceTypeCalcMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Open Interest Update Message: 18 bytes                                  *)
(***************************************************************************)

OpenInterestUpdateMessage ==
    [ timestamp            : Sample(8),
      tradeDate            : Sample(2),
      instrumentId         : Sample(4),
      openInterestQuantity : Sample(4) ]

EncodeOpenInterestUpdateMessage(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.openInterestQuantity

DecodeOpenInterestUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET openInterestQuantity == ReadBytes(instrumentId.rest, 4) IN IF ~openInterestQuantity.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         tradeDate            |-> tradeDate.value,
         instrumentId         |-> instrumentId.value,
         openInterestQuantity |-> openInterestQuantity.value ], openInterestQuantity.rest)

ZeroOpenInterestUpdateMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      openInterestQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestUpdateMessage ==
    { ZeroOpenInterestUpdateMessage }
        \cup { [ZeroOpenInterestUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestUpdateMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterestUpdateMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestUpdateMessage EXCEPT !.openInterestQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Total Volume Update Message: 18 bytes                                   *)
(***************************************************************************)

TotalVolumeUpdateMessage ==
    [ timestamp    : Sample(8),
      tradeDate    : Sample(2),
      instrumentId : Sample(4),
      totalVolume  : Sample(4) ]

EncodeTotalVolumeUpdateMessage(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.totalVolume

DecodeTotalVolumeUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(instrumentId.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         tradeDate    |-> tradeDate.value,
         instrumentId |-> instrumentId.value,
         totalVolume  |-> totalVolume.value ], totalVolume.rest)

ZeroTotalVolumeUpdateMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      tradeDate    |-> [i \in 1 .. 2 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      totalVolume  |-> [i \in 1 .. 4 |-> 0] ]

(* Total Volume Update Message at zero, then each field in turn at the values it is checked at *)
CheckedTotalVolumeUpdateMessage ==
    { ZeroTotalVolumeUpdateMessage }
        \cup { [ZeroTotalVolumeUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTotalVolumeUpdateMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTotalVolumeUpdateMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTotalVolumeUpdateMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Clear Message: 12 bytes                                      *)
(***************************************************************************)

InstrumentClearMessage ==
    [ timestamp    : Sample(8),
      instrumentId : Sample(4) ]

EncodeInstrumentClearMessage(message) ==
    message.timestamp
        \o message.instrumentId

DecodeInstrumentClearMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         instrumentId |-> instrumentId.value ], instrumentId.rest)

ZeroInstrumentClearMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentClearMessage ==
    { ZeroInstrumentClearMessage }
        \cup { [ZeroInstrumentClearMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentClearMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Message: 35 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timestamp      : Sample(8),
      instrumentId   : Sample(4),
      orderType      : Sample(1),
      orderId        : Sample(8),
      orderSide      : Sample(1),
      price          : Sample(8),
      size           : Sample(4),
      instrumentType : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.orderType
        \o message.orderId
        \o message.orderSide
        \o message.price
        \o message.size
        \o message.instrumentType

DecodeAddOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderType == ReadBytes(instrumentId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET price == ReadBytes(orderSide.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(size.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         orderType      |-> orderType.value,
         orderId        |-> orderId.value,
         orderSide      |-> orderSide.value,
         price          |-> price.value,
         size           |-> size.value,
         instrumentType |-> instrumentType.value ], instrumentType.rest)

ZeroAddOrderMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      orderType      |-> [i \in 1 .. 1 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Message: 34 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ timestamp      : Sample(8),
      instrumentId   : Sample(4),
      orderId        : Sample(8),
      price          : Sample(8),
      sizeFlags      : Sample(4),
      orderSide      : Sample(1),
      instrumentType : Sample(1) ]

EncodeModifyOrderMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.orderId
        \o message.price
        \o message.sizeFlags
        \o message.orderSide
        \o message.instrumentType

DecodeModifyOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET sizeFlags == ReadBytes(price.rest, 4) IN IF ~sizeFlags.ok THEN Fail ELSE
    LET orderSide == ReadBytes(sizeFlags.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(orderSide.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         orderId        |-> orderId.value,
         price          |-> price.value,
         sizeFlags      |-> sizeFlags.value,
         orderSide      |-> orderSide.value,
         instrumentType |-> instrumentType.value ], instrumentType.rest)

ZeroModifyOrderMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      sizeFlags      |-> [i \in 1 .. 4 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.sizeFlags = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 22 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ timestamp      : Sample(8),
      instrumentId   : Sample(4),
      orderId        : Sample(8),
      orderSide      : Sample(1),
      instrumentType : Sample(1) ]

EncodeDeleteOrderMessage(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.orderId
        \o message.orderSide
        \o message.instrumentType

DecodeDeleteOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(orderSide.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         orderId        |-> orderId.value,
         orderSide      |-> orderSide.value,
         instrumentType |-> instrumentType.value ], instrumentType.rest)

ZeroDeleteOrderMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Message: 62 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ timestamp        : Sample(8),
      tradeDate        : Sample(2),
      instrumentId     : Sample(4),
      buyOrderId       : Sample(8),
      sellOrderId      : Sample(8),
      aggressorSide    : Sample(1),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      tradeType        : Sample(1),
      complexTradeId   : Sample(8),
      instrumentType   : Sample(1) ]

EncodeOrderExecutionMessage(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.aggressorSide
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size
        \o message.tradeType
        \o message.complexTradeId
        \o message.instrumentType

DecodeOrderExecutionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(sellOrderId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET tradeId == ReadBytes(aggressorSide.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET tradeType == ReadBytes(size.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET complexTradeId == ReadBytes(tradeType.rest, 8) IN IF ~complexTradeId.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(complexTradeId.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         tradeDate        |-> tradeDate.value,
         instrumentId     |-> instrumentId.value,
         buyOrderId       |-> buyOrderId.value,
         sellOrderId      |-> sellOrderId.value,
         aggressorSide    |-> aggressorSide.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value,
         tradeType        |-> tradeType.value,
         complexTradeId   |-> complexTradeId.value,
         instrumentType   |-> instrumentType.value ], instrumentType.rest)

ZeroOrderExecutionMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      buyOrderId       |-> [i \in 1 .. 8 |-> 0],
      sellOrderId      |-> [i \in 1 .. 8 |-> 0],
      aggressorSide    |-> [i \in 1 .. 1 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      tradeType        |-> [i \in 1 .. 1 |-> 0],
      complexTradeId   |-> [i \in 1 .. 8 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.complexTradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 36 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ timestamp        : Sample(8),
      tradeDate        : Sample(2),
      instrumentId     : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      instrumentType   : Sample(1) ]

EncodeTradeCancelMessage(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size
        \o message.instrumentType

DecodeTradeCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(size.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         tradeDate        |-> tradeDate.value,
         instrumentId     |-> instrumentId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value,
         instrumentType   |-> instrumentType.value ], instrumentType.rest)

ZeroTradeCancelMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0] ]

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
        \cup { [ZeroTradeCancelMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SimpleInstrumentDefinitionMessageCode == 1  \* 0x01
ComplexInstrumentDefinitionMessageCode == 17  \* 0x11
ComplexInstrumentDefinitionDeprecatedMessageCode == 2  \* 0x02
SystemStateMessageCode == 3  \* 0x03
InstrumentTradingStatusNotificationMessageCode == 4  \* 0x04
AnticipatedOpeningPriceMessageCode == 5  \* 0x05
SettlementPriceUpdateMessageCode == 6  \* 0x06
OpenInterestUpdateMessageCode == 7  \* 0x07
TotalVolumeUpdateMessageCode == 8  \* 0x08
InstrumentClearMessageCode == 9  \* 0x09
AddOrderMessageCode == 10  \* 0x0a
ModifyOrderMessageCode == 11  \* 0x0b
DeleteOrderMessageCode == 12  \* 0x0c
OrderExecutionMessageCode == 13  \* 0x0d
TradeCancelMessageCode == 14  \* 0x0e

Data ==
    [ tag : {SimpleInstrumentDefinitionMessageCode}, body : SimpleInstrumentDefinitionMessage ]
        \cup [ tag : {ComplexInstrumentDefinitionMessageCode}, body : ComplexInstrumentDefinitionMessage ]
        \cup [ tag : {ComplexInstrumentDefinitionDeprecatedMessageCode}, body : ComplexInstrumentDefinitionDeprecatedMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {InstrumentTradingStatusNotificationMessageCode}, body : InstrumentTradingStatusNotificationMessage ]
        \cup [ tag : {AnticipatedOpeningPriceMessageCode}, body : AnticipatedOpeningPriceMessage ]
        \cup [ tag : {SettlementPriceUpdateMessageCode}, body : SettlementPriceUpdateMessage ]
        \cup [ tag : {OpenInterestUpdateMessageCode}, body : OpenInterestUpdateMessage ]
        \cup [ tag : {TotalVolumeUpdateMessageCode}, body : TotalVolumeUpdateMessage ]
        \cup [ tag : {InstrumentClearMessageCode}, body : InstrumentClearMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]

EncodeData(message) ==
    CASE message.tag = SimpleInstrumentDefinitionMessageCode -> EncodeSimpleInstrumentDefinitionMessage(message.body)
      [] message.tag = ComplexInstrumentDefinitionMessageCode -> EncodeComplexInstrumentDefinitionMessage(message.body)
      [] message.tag = ComplexInstrumentDefinitionDeprecatedMessageCode -> EncodeComplexInstrumentDefinitionDeprecatedMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = InstrumentTradingStatusNotificationMessageCode -> EncodeInstrumentTradingStatusNotificationMessage(message.body)
      [] message.tag = AnticipatedOpeningPriceMessageCode -> EncodeAnticipatedOpeningPriceMessage(message.body)
      [] message.tag = SettlementPriceUpdateMessageCode -> EncodeSettlementPriceUpdateMessage(message.body)
      [] message.tag = OpenInterestUpdateMessageCode -> EncodeOpenInterestUpdateMessage(message.body)
      [] message.tag = TotalVolumeUpdateMessageCode -> EncodeTotalVolumeUpdateMessage(message.body)
      [] message.tag = InstrumentClearMessageCode -> EncodeInstrumentClearMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SimpleInstrumentDefinitionMessageCode -> DecodeSimpleInstrumentDefinitionMessage(bytes)
              [] tag = ComplexInstrumentDefinitionMessageCode -> DecodeComplexInstrumentDefinitionMessage(bytes)
              [] tag = ComplexInstrumentDefinitionDeprecatedMessageCode -> DecodeComplexInstrumentDefinitionDeprecatedMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = InstrumentTradingStatusNotificationMessageCode -> DecodeInstrumentTradingStatusNotificationMessage(bytes)
              [] tag = AnticipatedOpeningPriceMessageCode -> DecodeAnticipatedOpeningPriceMessage(bytes)
              [] tag = SettlementPriceUpdateMessageCode -> DecodeSettlementPriceUpdateMessage(bytes)
              [] tag = OpenInterestUpdateMessageCode -> DecodeOpenInterestUpdateMessage(bytes)
              [] tag = TotalVolumeUpdateMessageCode -> DecodeTotalVolumeUpdateMessage(bytes)
              [] tag = InstrumentClearMessageCode -> DecodeInstrumentClearMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SimpleInstrumentDefinitionMessageCode, body |-> ZeroSimpleInstrumentDefinitionMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SimpleInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedSimpleInstrumentDefinitionMessage }
        \cup { [tag |-> ComplexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedComplexInstrumentDefinitionMessage }
        \cup { [tag |-> ComplexInstrumentDefinitionDeprecatedMessageCode, body |-> one] : one \in CheckedComplexInstrumentDefinitionDeprecatedMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> InstrumentTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedInstrumentTradingStatusNotificationMessage }
        \cup { [tag |-> AnticipatedOpeningPriceMessageCode, body |-> one] : one \in CheckedAnticipatedOpeningPriceMessage }
        \cup { [tag |-> SettlementPriceUpdateMessageCode, body |-> one] : one \in CheckedSettlementPriceUpdateMessage }
        \cup { [tag |-> OpenInterestUpdateMessageCode, body |-> one] : one \in CheckedOpenInterestUpdateMessage }
        \cup { [tag |-> TotalVolumeUpdateMessageCode, body |-> one] : one \in CheckedTotalVolumeUpdateMessage }
        \cup { [tag |-> InstrumentClearMessageCode, body |-> one] : one \in CheckedInstrumentClearMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber : Sample(8),
      data           : Data ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(sequenceNumber.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         data           |-> data.value ], data.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      data           |-> ZeroData ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Refresh Request: 1 bytes                                                *)
(***************************************************************************)

RefreshRequest ==
    [ refreshMessageType : Sample(1) ]

EncodeRefreshRequest(message) ==
    message.refreshMessageType

DecodeRefreshRequest(bytes) ==
    LET refreshMessageType == ReadBytes(bytes, 1) IN IF ~refreshMessageType.ok THEN Fail ELSE
    Ok([ refreshMessageType |-> refreshMessageType.value ], refreshMessageType.rest)

ZeroRefreshRequest ==
    [ refreshMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* Refresh Request at zero, then each field in turn at the values it is checked at *)
CheckedRefreshRequest ==
    { ZeroRefreshRequest }
        \cup { [ZeroRefreshRequest EXCEPT !.refreshMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Instrument Definition Message: 138 bytes                         *)
(***************************************************************************)

SimpleInstrumentDefinitionMessage2 ==
    [ timestamp                     : Sample(8),
      instrumentId                  : Sample(4),
      underlyingAssetType           : Sample(1),
      underlyingAssetAlphanumeric4  : Sample(4),
      productGroupCodeAlphanumeric6 : Sample(6),
      exchange                      : Sample(4),
      instrumentIdSource            : Sample(1),
      instrumentType                : Sample(1),
      instrumentListingStatus       : Sample(1),
      reserved3                     : Sample(3),
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
      contractDate                  : Sample(4),
      maturityDate                  : Sample(2),
      valuationDate                 : Sample(2),
      firstTradeDate                : Sample(2),
      lastTradeDate                 : Sample(2),
      firstNoticeDate               : Sample(2),
      lastNoticeDate                : Sample(2),
      firstDeliveryDate             : Sample(2),
      lastDeliveryDate              : Sample(2),
      optionStrikePrice             : Sample(8),
      optionStrikeCurrency          : Sample(1),
      optionType                    : Sample(1),
      optionExpirationType          : Sample(1),
      underlyingFutureInstrumentId  : Sample(4) ]

EncodeSimpleInstrumentDefinitionMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.underlyingAssetType
        \o message.underlyingAssetAlphanumeric4
        \o message.productGroupCodeAlphanumeric6
        \o message.exchange
        \o message.instrumentIdSource
        \o message.instrumentType
        \o message.instrumentListingStatus
        \o message.reserved3
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
        \o message.contractDate
        \o message.maturityDate
        \o message.valuationDate
        \o message.firstTradeDate
        \o message.lastTradeDate
        \o message.firstNoticeDate
        \o message.lastNoticeDate
        \o message.firstDeliveryDate
        \o message.lastDeliveryDate
        \o message.optionStrikePrice
        \o message.optionStrikeCurrency
        \o message.optionType
        \o message.optionExpirationType
        \o message.underlyingFutureInstrumentId

DecodeSimpleInstrumentDefinitionMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAssetAlphanumeric4 == ReadBytes(underlyingAssetType.rest, 4) IN IF ~underlyingAssetAlphanumeric4.ok THEN Fail ELSE
    LET productGroupCodeAlphanumeric6 == ReadBytes(underlyingAssetAlphanumeric4.rest, 6) IN IF ~productGroupCodeAlphanumeric6.ok THEN Fail ELSE
    LET exchange == ReadBytes(productGroupCodeAlphanumeric6.rest, 4) IN IF ~exchange.ok THEN Fail ELSE
    LET instrumentIdSource == ReadBytes(exchange.rest, 1) IN IF ~instrumentIdSource.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIdSource.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentListingStatus == ReadBytes(instrumentType.rest, 1) IN IF ~instrumentListingStatus.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(instrumentListingStatus.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    LET currency == ReadBytes(reserved3.rest, 1) IN IF ~currency.ok THEN Fail ELSE
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
    LET contractDate == ReadBytes(tradingCollarVariation.rest, 4) IN IF ~contractDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(contractDate.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET valuationDate == ReadBytes(maturityDate.rest, 2) IN IF ~valuationDate.ok THEN Fail ELSE
    LET firstTradeDate == ReadBytes(valuationDate.rest, 2) IN IF ~firstTradeDate.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(firstTradeDate.rest, 2) IN IF ~lastTradeDate.ok THEN Fail ELSE
    LET firstNoticeDate == ReadBytes(lastTradeDate.rest, 2) IN IF ~firstNoticeDate.ok THEN Fail ELSE
    LET lastNoticeDate == ReadBytes(firstNoticeDate.rest, 2) IN IF ~lastNoticeDate.ok THEN Fail ELSE
    LET firstDeliveryDate == ReadBytes(lastNoticeDate.rest, 2) IN IF ~firstDeliveryDate.ok THEN Fail ELSE
    LET lastDeliveryDate == ReadBytes(firstDeliveryDate.rest, 2) IN IF ~lastDeliveryDate.ok THEN Fail ELSE
    LET optionStrikePrice == ReadBytes(lastDeliveryDate.rest, 8) IN IF ~optionStrikePrice.ok THEN Fail ELSE
    LET optionStrikeCurrency == ReadBytes(optionStrikePrice.rest, 1) IN IF ~optionStrikeCurrency.ok THEN Fail ELSE
    LET optionType == ReadBytes(optionStrikeCurrency.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET optionExpirationType == ReadBytes(optionType.rest, 1) IN IF ~optionExpirationType.ok THEN Fail ELSE
    LET underlyingFutureInstrumentId == ReadBytes(optionExpirationType.rest, 4) IN IF ~underlyingFutureInstrumentId.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         instrumentId                  |-> instrumentId.value,
         underlyingAssetType           |-> underlyingAssetType.value,
         underlyingAssetAlphanumeric4  |-> underlyingAssetAlphanumeric4.value,
         productGroupCodeAlphanumeric6 |-> productGroupCodeAlphanumeric6.value,
         exchange                      |-> exchange.value,
         instrumentIdSource            |-> instrumentIdSource.value,
         instrumentType                |-> instrumentType.value,
         instrumentListingStatus       |-> instrumentListingStatus.value,
         reserved3                     |-> reserved3.value,
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
         contractDate                  |-> contractDate.value,
         maturityDate                  |-> maturityDate.value,
         valuationDate                 |-> valuationDate.value,
         firstTradeDate                |-> firstTradeDate.value,
         lastTradeDate                 |-> lastTradeDate.value,
         firstNoticeDate               |-> firstNoticeDate.value,
         lastNoticeDate                |-> lastNoticeDate.value,
         firstDeliveryDate             |-> firstDeliveryDate.value,
         lastDeliveryDate              |-> lastDeliveryDate.value,
         optionStrikePrice             |-> optionStrikePrice.value,
         optionStrikeCurrency          |-> optionStrikeCurrency.value,
         optionType                    |-> optionType.value,
         optionExpirationType          |-> optionExpirationType.value,
         underlyingFutureInstrumentId  |-> underlyingFutureInstrumentId.value ], underlyingFutureInstrumentId.rest)

ZeroSimpleInstrumentDefinitionMessage2 ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType           |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetAlphanumeric4  |-> [i \in 1 .. 4 |-> 0],
      productGroupCodeAlphanumeric6 |-> [i \in 1 .. 6 |-> 0],
      exchange                      |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource            |-> [i \in 1 .. 1 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      instrumentListingStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved3                     |-> [i \in 1 .. 3 |-> 0],
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
      contractDate                  |-> [i \in 1 .. 4 |-> 0],
      maturityDate                  |-> [i \in 1 .. 2 |-> 0],
      valuationDate                 |-> [i \in 1 .. 2 |-> 0],
      firstTradeDate                |-> [i \in 1 .. 2 |-> 0],
      lastTradeDate                 |-> [i \in 1 .. 2 |-> 0],
      firstNoticeDate               |-> [i \in 1 .. 2 |-> 0],
      lastNoticeDate                |-> [i \in 1 .. 2 |-> 0],
      firstDeliveryDate             |-> [i \in 1 .. 2 |-> 0],
      lastDeliveryDate              |-> [i \in 1 .. 2 |-> 0],
      optionStrikePrice             |-> [i \in 1 .. 8 |-> 0],
      optionStrikeCurrency          |-> [i \in 1 .. 1 |-> 0],
      optionType                    |-> [i \in 1 .. 1 |-> 0],
      optionExpirationType          |-> [i \in 1 .. 1 |-> 0],
      underlyingFutureInstrumentId  |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleInstrumentDefinitionMessage2 ==
    { ZeroSimpleInstrumentDefinitionMessage2 }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.underlyingAssetAlphanumeric4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.productGroupCodeAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.instrumentListingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.reserved3 = one] : one \in Sample(3) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.settlementCurrency = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.minimumSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.maximumSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.tick = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.unitOfMeasureQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.settlementPriceTypeCalcMethod = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.openInterestQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.contractDate = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.valuationDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.firstTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.lastTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.firstNoticeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.lastNoticeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.firstDeliveryDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.lastDeliveryDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.optionStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.optionStrikeCurrency = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.optionExpirationType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDefinitionMessage2 EXCEPT !.underlyingFutureInstrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Leg: 42 bytes                                                *)
(***************************************************************************)

InstrumentLeg2 ==
    [ instrumentId    : Sample(4),
      legRatioAndSide : Sample(4),
      maturityDate    : Sample(2),
      reserved32      : Sample(32) ]

EncodeInstrumentLeg2(message) ==
    message.instrumentId
        \o message.legRatioAndSide
        \o message.maturityDate
        \o message.reserved32

DecodeInstrumentLeg2(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legRatioAndSide == ReadBytes(instrumentId.rest, 4) IN IF ~legRatioAndSide.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(legRatioAndSide.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(maturityDate.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ instrumentId    |-> instrumentId.value,
         legRatioAndSide |-> legRatioAndSide.value,
         maturityDate    |-> maturityDate.value,
         reserved32      |-> reserved32.value ], reserved32.rest)

ZeroInstrumentLeg2 ==
    [ instrumentId    |-> [i \in 1 .. 4 |-> 0],
      legRatioAndSide |-> [i \in 1 .. 4 |-> 0],
      maturityDate    |-> [i \in 1 .. 2 |-> 0],
      reserved32      |-> [i \in 1 .. 32 |-> 0] ]

(* Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentLeg2 ==
    { ZeroInstrumentLeg2 }
        \cup { [ZeroInstrumentLeg2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg2 EXCEPT !.legRatioAndSide = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentLeg2 EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentLeg2 EXCEPT !.reserved32 = one] : one \in Sample(32) }

(* A run of Instrument Leg, written one after another *)
RECURSIVE EncodeInstrumentLeg2List(_)
EncodeInstrumentLeg2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentLeg2(Head(messages)) \o EncodeInstrumentLeg2List(Tail(messages))

(* As many Instrument Leg as the field that counts them says *)
RECURSIVE ReadInstrumentLeg2List(_, _)
ReadInstrumentLeg2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentLeg2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentLeg2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Leg of each kind, for the lists that carry them *)
OneInstrumentLeg2 == { ZeroInstrumentLeg2 }

(***************************************************************************)
(* Complex Instrument Definition Message                                   *)
(***************************************************************************)

ComplexInstrumentDefinitionMessage2 ==
    [ timestamp                      : Sample(8),
      instrumentId                   : Sample(4),
      underlyingAssetType            : Sample(1),
      underlyingAssetAlphanumeric9   : Sample(9),
      productGroupCodeAlphanumeric13 : Sample(13),
      spreadType                     : Sample(1),
      exchange                       : Sample(4),
      instrumentIdSource             : Sample(1),
      instrumentType                 : Sample(1),
      currency                       : Sample(1),
      settlementCurrency             : Sample(1),
      matchAlgorithm                 : Sample(1),
      minimumSize                    : Sample(4),
      maximumSize                    : Sample(4),
      tick                           : Sample(8),
      unitOfMeasure                  : Sample(5),
      unitOfMeasureQuantity          : Sample(4),
      settlementPrice                : Sample(8),
      settlementPriceTypeCalcMethod  : Sample(1),
      tradingCollarVariationType     : Sample(1),
      tradingCollarVariation         : Sample(8),
      instrumentListingStatus        : Sample(1),
      firstTradeDate                 : Sample(2),
      reserved64                     : Sample(64),
      instrumentLeg                  : SampleLists(OneInstrumentLeg2) ]

EncodeComplexInstrumentDefinitionMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.underlyingAssetType
        \o message.underlyingAssetAlphanumeric9
        \o message.productGroupCodeAlphanumeric13
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
        \o message.settlementPrice
        \o message.settlementPriceTypeCalcMethod
        \o message.tradingCollarVariationType
        \o message.tradingCollarVariation
        \o message.instrumentListingStatus
        \o message.firstTradeDate
        \o message.reserved64
        \o EncodeUIntLE(Len(message.instrumentLeg), 1)
        \o EncodeInstrumentLeg2List(message.instrumentLeg)

DecodeComplexInstrumentDefinitionMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAssetAlphanumeric9 == ReadBytes(underlyingAssetType.rest, 9) IN IF ~underlyingAssetAlphanumeric9.ok THEN Fail ELSE
    LET productGroupCodeAlphanumeric13 == ReadBytes(underlyingAssetAlphanumeric9.rest, 13) IN IF ~productGroupCodeAlphanumeric13.ok THEN Fail ELSE
    LET spreadType == ReadBytes(productGroupCodeAlphanumeric13.rest, 1) IN IF ~spreadType.ok THEN Fail ELSE
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
    LET settlementPrice == ReadBytes(unitOfMeasureQuantity.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceTypeCalcMethod == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceTypeCalcMethod.ok THEN Fail ELSE
    LET tradingCollarVariationType == ReadBytes(settlementPriceTypeCalcMethod.rest, 1) IN IF ~tradingCollarVariationType.ok THEN Fail ELSE
    LET tradingCollarVariation == ReadBytes(tradingCollarVariationType.rest, 8) IN IF ~tradingCollarVariation.ok THEN Fail ELSE
    LET instrumentListingStatus == ReadBytes(tradingCollarVariation.rest, 1) IN IF ~instrumentListingStatus.ok THEN Fail ELSE
    LET firstTradeDate == ReadBytes(instrumentListingStatus.rest, 2) IN IF ~firstTradeDate.ok THEN Fail ELSE
    LET reserved64 == ReadBytes(firstTradeDate.rest, 64) IN IF ~reserved64.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(reserved64.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET instrumentLeg == ReadInstrumentLeg2List(numberOfLegs.rest, numberOfLegs.value) IN IF ~instrumentLeg.ok THEN Fail ELSE
    Ok([ timestamp                      |-> timestamp.value,
         instrumentId                   |-> instrumentId.value,
         underlyingAssetType            |-> underlyingAssetType.value,
         underlyingAssetAlphanumeric9   |-> underlyingAssetAlphanumeric9.value,
         productGroupCodeAlphanumeric13 |-> productGroupCodeAlphanumeric13.value,
         spreadType                     |-> spreadType.value,
         exchange                       |-> exchange.value,
         instrumentIdSource             |-> instrumentIdSource.value,
         instrumentType                 |-> instrumentType.value,
         currency                       |-> currency.value,
         settlementCurrency             |-> settlementCurrency.value,
         matchAlgorithm                 |-> matchAlgorithm.value,
         minimumSize                    |-> minimumSize.value,
         maximumSize                    |-> maximumSize.value,
         tick                           |-> tick.value,
         unitOfMeasure                  |-> unitOfMeasure.value,
         unitOfMeasureQuantity          |-> unitOfMeasureQuantity.value,
         settlementPrice                |-> settlementPrice.value,
         settlementPriceTypeCalcMethod  |-> settlementPriceTypeCalcMethod.value,
         tradingCollarVariationType     |-> tradingCollarVariationType.value,
         tradingCollarVariation         |-> tradingCollarVariation.value,
         instrumentListingStatus        |-> instrumentListingStatus.value,
         firstTradeDate                 |-> firstTradeDate.value,
         reserved64                     |-> reserved64.value,
         instrumentLeg                  |-> instrumentLeg.value ], instrumentLeg.rest)

ZeroComplexInstrumentDefinitionMessage2 ==
    [ timestamp                      |-> [i \in 1 .. 8 |-> 0],
      instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType            |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetAlphanumeric9   |-> [i \in 1 .. 9 |-> 0],
      productGroupCodeAlphanumeric13 |-> [i \in 1 .. 13 |-> 0],
      spreadType                     |-> [i \in 1 .. 1 |-> 0],
      exchange                       |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource             |-> [i \in 1 .. 1 |-> 0],
      instrumentType                 |-> [i \in 1 .. 1 |-> 0],
      currency                       |-> [i \in 1 .. 1 |-> 0],
      settlementCurrency             |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm                 |-> [i \in 1 .. 1 |-> 0],
      minimumSize                    |-> [i \in 1 .. 4 |-> 0],
      maximumSize                    |-> [i \in 1 .. 4 |-> 0],
      tick                           |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure                  |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureQuantity          |-> [i \in 1 .. 4 |-> 0],
      settlementPrice                |-> [i \in 1 .. 8 |-> 0],
      settlementPriceTypeCalcMethod  |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariationType     |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariation         |-> [i \in 1 .. 8 |-> 0],
      instrumentListingStatus        |-> [i \in 1 .. 1 |-> 0],
      firstTradeDate                 |-> [i \in 1 .. 2 |-> 0],
      reserved64                     |-> [i \in 1 .. 64 |-> 0],
      instrumentLeg                  |-> << >> ]

(* Complex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionMessage2 ==
    { ZeroComplexInstrumentDefinitionMessage2 }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.underlyingAssetAlphanumeric9 = one] : one \in Sample(9) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.productGroupCodeAlphanumeric13 = one] : one \in Sample(13) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.spreadType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.settlementCurrency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.minimumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.maximumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.tick = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.unitOfMeasureQuantity = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.settlementPriceTypeCalcMethod = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.instrumentListingStatus = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.firstTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.reserved64 = one] : one \in Sample(64) }
        \cup { [ZeroComplexInstrumentDefinitionMessage2 EXCEPT !.instrumentLeg = one] : one \in SampleLists(OneInstrumentLeg2) }

(***************************************************************************)
(* Deprecated Instrument Leg: 20 bytes                                     *)
(***************************************************************************)

DeprecatedInstrumentLeg2 ==
    [ instrumentId    : Sample(4),
      legRatioAndSide : Sample(4),
      reserved4       : Sample(4),
      maturityDate    : Sample(2),
      reserved6       : Sample(6) ]

EncodeDeprecatedInstrumentLeg2(message) ==
    message.instrumentId
        \o message.legRatioAndSide
        \o message.reserved4
        \o message.maturityDate
        \o message.reserved6

DecodeDeprecatedInstrumentLeg2(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legRatioAndSide == ReadBytes(instrumentId.rest, 4) IN IF ~legRatioAndSide.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(legRatioAndSide.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(reserved4.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(maturityDate.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    Ok([ instrumentId    |-> instrumentId.value,
         legRatioAndSide |-> legRatioAndSide.value,
         reserved4       |-> reserved4.value,
         maturityDate    |-> maturityDate.value,
         reserved6       |-> reserved6.value ], reserved6.rest)

ZeroDeprecatedInstrumentLeg2 ==
    [ instrumentId    |-> [i \in 1 .. 4 |-> 0],
      legRatioAndSide |-> [i \in 1 .. 4 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0],
      maturityDate    |-> [i \in 1 .. 2 |-> 0],
      reserved6       |-> [i \in 1 .. 6 |-> 0] ]

(* Deprecated Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedInstrumentLeg2 ==
    { ZeroDeprecatedInstrumentLeg2 }
        \cup { [ZeroDeprecatedInstrumentLeg2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedInstrumentLeg2 EXCEPT !.legRatioAndSide = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedInstrumentLeg2 EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedInstrumentLeg2 EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedInstrumentLeg2 EXCEPT !.reserved6 = one] : one \in Sample(6) }

(* A run of Deprecated Instrument Leg, written one after another *)
RECURSIVE EncodeDeprecatedInstrumentLeg2List(_)
EncodeDeprecatedInstrumentLeg2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDeprecatedInstrumentLeg2(Head(messages)) \o EncodeDeprecatedInstrumentLeg2List(Tail(messages))

(* As many Deprecated Instrument Leg as the field that counts them says *)
RECURSIVE ReadDeprecatedInstrumentLeg2List(_, _)
ReadDeprecatedInstrumentLeg2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDeprecatedInstrumentLeg2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDeprecatedInstrumentLeg2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Deprecated Instrument Leg of each kind, for the lists that carry them *)
OneDeprecatedInstrumentLeg2 == { ZeroDeprecatedInstrumentLeg2 }

(***************************************************************************)
(* Complex Instrument Definition Deprecated Message                        *)
(***************************************************************************)

ComplexInstrumentDefinitionDeprecatedMessage2 ==
    [ timestamp                             : Sample(8),
      instrumentIdFormerlyKnownAsStrategyId : Sample(4),
      underlyingAssetType                   : Sample(1),
      underlyingAssetAlphanumeric4          : Sample(4),
      productGroupCodeAlphanumeric6         : Sample(6),
      spreadType                            : Sample(1),
      exchange                              : Sample(4),
      instrumentIdSource                    : Sample(1),
      instrumentType                        : Sample(1),
      currency                              : Sample(1),
      settlementCurrency                    : Sample(1),
      matchAlgorithm                        : Sample(1),
      minimumSize                           : Sample(4),
      maximumSize                           : Sample(4),
      tick                                  : Sample(8),
      unitOfMeasure                         : Sample(5),
      unitOfMeasureQuantity                 : Sample(4),
      tradingCollarVariationType            : Sample(1),
      tradingCollarVariation                : Sample(8),
      reserved16                            : Sample(16),
      deprecatedInstrumentLeg               : SampleLists(OneDeprecatedInstrumentLeg2) ]

EncodeComplexInstrumentDefinitionDeprecatedMessage2(message) ==
    message.timestamp
        \o message.instrumentIdFormerlyKnownAsStrategyId
        \o message.underlyingAssetType
        \o message.underlyingAssetAlphanumeric4
        \o message.productGroupCodeAlphanumeric6
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
        \o EncodeUIntLE(Len(message.deprecatedInstrumentLeg), 1)
        \o EncodeDeprecatedInstrumentLeg2List(message.deprecatedInstrumentLeg)

DecodeComplexInstrumentDefinitionDeprecatedMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentIdFormerlyKnownAsStrategyId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentIdFormerlyKnownAsStrategyId.ok THEN Fail ELSE
    LET underlyingAssetType == ReadBytes(instrumentIdFormerlyKnownAsStrategyId.rest, 1) IN IF ~underlyingAssetType.ok THEN Fail ELSE
    LET underlyingAssetAlphanumeric4 == ReadBytes(underlyingAssetType.rest, 4) IN IF ~underlyingAssetAlphanumeric4.ok THEN Fail ELSE
    LET productGroupCodeAlphanumeric6 == ReadBytes(underlyingAssetAlphanumeric4.rest, 6) IN IF ~productGroupCodeAlphanumeric6.ok THEN Fail ELSE
    LET spreadType == ReadBytes(productGroupCodeAlphanumeric6.rest, 1) IN IF ~spreadType.ok THEN Fail ELSE
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
    LET deprecatedInstrumentLeg == ReadDeprecatedInstrumentLeg2List(numberOfLegs.rest, numberOfLegs.value) IN IF ~deprecatedInstrumentLeg.ok THEN Fail ELSE
    Ok([ timestamp                             |-> timestamp.value,
         instrumentIdFormerlyKnownAsStrategyId |-> instrumentIdFormerlyKnownAsStrategyId.value,
         underlyingAssetType                   |-> underlyingAssetType.value,
         underlyingAssetAlphanumeric4          |-> underlyingAssetAlphanumeric4.value,
         productGroupCodeAlphanumeric6         |-> productGroupCodeAlphanumeric6.value,
         spreadType                            |-> spreadType.value,
         exchange                              |-> exchange.value,
         instrumentIdSource                    |-> instrumentIdSource.value,
         instrumentType                        |-> instrumentType.value,
         currency                              |-> currency.value,
         settlementCurrency                    |-> settlementCurrency.value,
         matchAlgorithm                        |-> matchAlgorithm.value,
         minimumSize                           |-> minimumSize.value,
         maximumSize                           |-> maximumSize.value,
         tick                                  |-> tick.value,
         unitOfMeasure                         |-> unitOfMeasure.value,
         unitOfMeasureQuantity                 |-> unitOfMeasureQuantity.value,
         tradingCollarVariationType            |-> tradingCollarVariationType.value,
         tradingCollarVariation                |-> tradingCollarVariation.value,
         reserved16                            |-> reserved16.value,
         deprecatedInstrumentLeg               |-> deprecatedInstrumentLeg.value ], deprecatedInstrumentLeg.rest)

ZeroComplexInstrumentDefinitionDeprecatedMessage2 ==
    [ timestamp                             |-> [i \in 1 .. 8 |-> 0],
      instrumentIdFormerlyKnownAsStrategyId |-> [i \in 1 .. 4 |-> 0],
      underlyingAssetType                   |-> [i \in 1 .. 1 |-> 0],
      underlyingAssetAlphanumeric4          |-> [i \in 1 .. 4 |-> 0],
      productGroupCodeAlphanumeric6         |-> [i \in 1 .. 6 |-> 0],
      spreadType                            |-> [i \in 1 .. 1 |-> 0],
      exchange                              |-> [i \in 1 .. 4 |-> 0],
      instrumentIdSource                    |-> [i \in 1 .. 1 |-> 0],
      instrumentType                        |-> [i \in 1 .. 1 |-> 0],
      currency                              |-> [i \in 1 .. 1 |-> 0],
      settlementCurrency                    |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm                        |-> [i \in 1 .. 1 |-> 0],
      minimumSize                           |-> [i \in 1 .. 4 |-> 0],
      maximumSize                           |-> [i \in 1 .. 4 |-> 0],
      tick                                  |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure                         |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureQuantity                 |-> [i \in 1 .. 4 |-> 0],
      tradingCollarVariationType            |-> [i \in 1 .. 1 |-> 0],
      tradingCollarVariation                |-> [i \in 1 .. 8 |-> 0],
      reserved16                            |-> [i \in 1 .. 16 |-> 0],
      deprecatedInstrumentLeg               |-> << >> ]

(* Complex Instrument Definition Deprecated Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionDeprecatedMessage2 ==
    { ZeroComplexInstrumentDefinitionDeprecatedMessage2 }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.instrumentIdFormerlyKnownAsStrategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.underlyingAssetType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.underlyingAssetAlphanumeric4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.productGroupCodeAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.spreadType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.exchange = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.instrumentIdSource = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.settlementCurrency = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.minimumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.maximumSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.tick = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.unitOfMeasureQuantity = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.tradingCollarVariationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.tradingCollarVariation = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroComplexInstrumentDefinitionDeprecatedMessage2 EXCEPT !.deprecatedInstrumentLeg = one] : one \in SampleLists(OneDeprecatedInstrumentLeg2) }

(***************************************************************************)
(* System State Message: 18 bytes                                          *)
(***************************************************************************)

SystemStateMessage2 ==
    [ timestamp    : Sample(8),
      doMVersion   : Sample(8),
      sessionId    : Sample(1),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage2(message) ==
    message.timestamp
        \o message.doMVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET doMVersion == ReadBytes(timestamp.rest, 8) IN IF ~doMVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(doMVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         doMVersion   |-> doMVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage2 ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      doMVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage2 ==
    { ZeroSystemStateMessage2 }
        \cup { [ZeroSystemStateMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage2 EXCEPT !.doMVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage2 EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateMessage2 EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Trading Status Notification Message: 14 bytes                *)
(***************************************************************************)

InstrumentTradingStatusNotificationMessage2 ==
    [ timestamp     : Sample(8),
      instrumentId  : Sample(4),
      tradingStatus : Sample(1),
      marketState   : Sample(1) ]

EncodeInstrumentTradingStatusNotificationMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.tradingStatus
        \o message.marketState

DecodeInstrumentTradingStatusNotificationMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(instrumentId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketState == ReadBytes(tradingStatus.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         instrumentId  |-> instrumentId.value,
         tradingStatus |-> tradingStatus.value,
         marketState   |-> marketState.value ], marketState.rest)

ZeroInstrumentTradingStatusNotificationMessage2 ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketState   |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentTradingStatusNotificationMessage2 ==
    { ZeroInstrumentTradingStatusNotificationMessage2 }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage2 EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentTradingStatusNotificationMessage2 EXCEPT !.marketState = one] : one \in Sample(1) }

(***************************************************************************)
(* Anticipated Opening Price Message: 25 bytes                             *)
(***************************************************************************)

AnticipatedOpeningPriceMessage2 ==
    [ timestamp               : Sample(8),
      instrumentId            : Sample(4),
      anticipatedOpeningPrice : Sample(8),
      openingMatchQuantity    : Sample(4),
      instrumentType          : Sample(1) ]

EncodeAnticipatedOpeningPriceMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.anticipatedOpeningPrice
        \o message.openingMatchQuantity
        \o message.instrumentType

DecodeAnticipatedOpeningPriceMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET anticipatedOpeningPrice == ReadBytes(instrumentId.rest, 8) IN IF ~anticipatedOpeningPrice.ok THEN Fail ELSE
    LET openingMatchQuantity == ReadBytes(anticipatedOpeningPrice.rest, 4) IN IF ~openingMatchQuantity.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(openingMatchQuantity.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         instrumentId            |-> instrumentId.value,
         anticipatedOpeningPrice |-> anticipatedOpeningPrice.value,
         openingMatchQuantity    |-> openingMatchQuantity.value,
         instrumentType          |-> instrumentType.value ], instrumentType.rest)

ZeroAnticipatedOpeningPriceMessage2 ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      anticipatedOpeningPrice |-> [i \in 1 .. 8 |-> 0],
      openingMatchQuantity    |-> [i \in 1 .. 4 |-> 0],
      instrumentType          |-> [i \in 1 .. 1 |-> 0] ]

(* Anticipated Opening Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAnticipatedOpeningPriceMessage2 ==
    { ZeroAnticipatedOpeningPriceMessage2 }
        \cup { [ZeroAnticipatedOpeningPriceMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAnticipatedOpeningPriceMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAnticipatedOpeningPriceMessage2 EXCEPT !.anticipatedOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnticipatedOpeningPriceMessage2 EXCEPT !.openingMatchQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAnticipatedOpeningPriceMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Settlement Price Update Message: 24 bytes                               *)
(***************************************************************************)

SettlementPriceUpdateMessage2 ==
    [ timestamp                     : Sample(8),
      tradeDate                     : Sample(2),
      instrumentId                  : Sample(4),
      settlementPrice               : Sample(8),
      settlementPriceType           : Sample(1),
      settlementPriceTypeCalcMethod : Sample(1) ]

EncodeSettlementPriceUpdateMessage2(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.settlementPrice
        \o message.settlementPriceType
        \o message.settlementPriceTypeCalcMethod

DecodeSettlementPriceUpdateMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(instrumentId.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceType == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceType.ok THEN Fail ELSE
    LET settlementPriceTypeCalcMethod == ReadBytes(settlementPriceType.rest, 1) IN IF ~settlementPriceTypeCalcMethod.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         tradeDate                     |-> tradeDate.value,
         instrumentId                  |-> instrumentId.value,
         settlementPrice               |-> settlementPrice.value,
         settlementPriceType           |-> settlementPriceType.value,
         settlementPriceTypeCalcMethod |-> settlementPriceTypeCalcMethod.value ], settlementPriceTypeCalcMethod.rest)

ZeroSettlementPriceUpdateMessage2 ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      tradeDate                     |-> [i \in 1 .. 2 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      settlementPrice               |-> [i \in 1 .. 8 |-> 0],
      settlementPriceType           |-> [i \in 1 .. 1 |-> 0],
      settlementPriceTypeCalcMethod |-> [i \in 1 .. 1 |-> 0] ]

(* Settlement Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementPriceUpdateMessage2 ==
    { ZeroSettlementPriceUpdateMessage2 }
        \cup { [ZeroSettlementPriceUpdateMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceUpdateMessage2 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSettlementPriceUpdateMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSettlementPriceUpdateMessage2 EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceUpdateMessage2 EXCEPT !.settlementPriceType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPriceUpdateMessage2 EXCEPT !.settlementPriceTypeCalcMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Open Interest Update Message: 18 bytes                                  *)
(***************************************************************************)

OpenInterestUpdateMessage2 ==
    [ timestamp            : Sample(8),
      tradeDate            : Sample(2),
      instrumentId         : Sample(4),
      openInterestQuantity : Sample(4) ]

EncodeOpenInterestUpdateMessage2(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.openInterestQuantity

DecodeOpenInterestUpdateMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET openInterestQuantity == ReadBytes(instrumentId.rest, 4) IN IF ~openInterestQuantity.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         tradeDate            |-> tradeDate.value,
         instrumentId         |-> instrumentId.value,
         openInterestQuantity |-> openInterestQuantity.value ], openInterestQuantity.rest)

ZeroOpenInterestUpdateMessage2 ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      openInterestQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestUpdateMessage2 ==
    { ZeroOpenInterestUpdateMessage2 }
        \cup { [ZeroOpenInterestUpdateMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestUpdateMessage2 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterestUpdateMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestUpdateMessage2 EXCEPT !.openInterestQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Total Volume Update Message: 18 bytes                                   *)
(***************************************************************************)

TotalVolumeUpdateMessage2 ==
    [ timestamp    : Sample(8),
      tradeDate    : Sample(2),
      instrumentId : Sample(4),
      totalVolume  : Sample(4) ]

EncodeTotalVolumeUpdateMessage2(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.totalVolume

DecodeTotalVolumeUpdateMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(instrumentId.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         tradeDate    |-> tradeDate.value,
         instrumentId |-> instrumentId.value,
         totalVolume  |-> totalVolume.value ], totalVolume.rest)

ZeroTotalVolumeUpdateMessage2 ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      tradeDate    |-> [i \in 1 .. 2 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      totalVolume  |-> [i \in 1 .. 4 |-> 0] ]

(* Total Volume Update Message at zero, then each field in turn at the values it is checked at *)
CheckedTotalVolumeUpdateMessage2 ==
    { ZeroTotalVolumeUpdateMessage2 }
        \cup { [ZeroTotalVolumeUpdateMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTotalVolumeUpdateMessage2 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTotalVolumeUpdateMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTotalVolumeUpdateMessage2 EXCEPT !.totalVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Clear Message: 12 bytes                                      *)
(***************************************************************************)

InstrumentClearMessage2 ==
    [ timestamp    : Sample(8),
      instrumentId : Sample(4) ]

EncodeInstrumentClearMessage2(message) ==
    message.timestamp
        \o message.instrumentId

DecodeInstrumentClearMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         instrumentId |-> instrumentId.value ], instrumentId.rest)

ZeroInstrumentClearMessage2 ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentClearMessage2 ==
    { ZeroInstrumentClearMessage2 }
        \cup { [ZeroInstrumentClearMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentClearMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Message: 35 bytes                                             *)
(***************************************************************************)

AddOrderMessage2 ==
    [ timestamp      : Sample(8),
      instrumentId   : Sample(4),
      orderType      : Sample(1),
      orderId        : Sample(8),
      orderSide      : Sample(1),
      price          : Sample(8),
      size           : Sample(4),
      instrumentType : Sample(1) ]

EncodeAddOrderMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.orderType
        \o message.orderId
        \o message.orderSide
        \o message.price
        \o message.size
        \o message.instrumentType

DecodeAddOrderMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderType == ReadBytes(instrumentId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET price == ReadBytes(orderSide.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(size.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         orderType      |-> orderType.value,
         orderId        |-> orderId.value,
         orderSide      |-> orderSide.value,
         price          |-> price.value,
         size           |-> size.value,
         instrumentType |-> instrumentType.value ], instrumentType.rest)

ZeroAddOrderMessage2 ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      orderType      |-> [i \in 1 .. 1 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage2 ==
    { ZeroAddOrderMessage2 }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Message: 34 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage2 ==
    [ timestamp      : Sample(8),
      instrumentId   : Sample(4),
      orderId        : Sample(8),
      price          : Sample(8),
      sizeFlags      : Sample(4),
      orderSide      : Sample(1),
      instrumentType : Sample(1) ]

EncodeModifyOrderMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.orderId
        \o message.price
        \o message.sizeFlags
        \o message.orderSide
        \o message.instrumentType

DecodeModifyOrderMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET sizeFlags == ReadBytes(price.rest, 4) IN IF ~sizeFlags.ok THEN Fail ELSE
    LET orderSide == ReadBytes(sizeFlags.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(orderSide.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         orderId        |-> orderId.value,
         price          |-> price.value,
         sizeFlags      |-> sizeFlags.value,
         orderSide      |-> orderSide.value,
         instrumentType |-> instrumentType.value ], instrumentType.rest)

ZeroModifyOrderMessage2 ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      sizeFlags      |-> [i \in 1 .. 4 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage2 ==
    { ZeroModifyOrderMessage2 }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.sizeFlags = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 22 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage2 ==
    [ timestamp      : Sample(8),
      instrumentId   : Sample(4),
      orderId        : Sample(8),
      orderSide      : Sample(1),
      instrumentType : Sample(1) ]

EncodeDeleteOrderMessage2(message) ==
    message.timestamp
        \o message.instrumentId
        \o message.orderId
        \o message.orderSide
        \o message.instrumentType

DecodeDeleteOrderMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(orderSide.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         orderId        |-> orderId.value,
         orderSide      |-> orderSide.value,
         instrumentType |-> instrumentType.value ], instrumentType.rest)

ZeroDeleteOrderMessage2 ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage2 ==
    { ZeroDeleteOrderMessage2 }
        \cup { [ZeroDeleteOrderMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage2 EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Message: 62 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage2 ==
    [ timestamp        : Sample(8),
      tradeDate        : Sample(2),
      instrumentId     : Sample(4),
      buyOrderId       : Sample(8),
      sellOrderId      : Sample(8),
      aggressorSide    : Sample(1),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      tradeType        : Sample(1),
      complexTradeId   : Sample(8),
      instrumentType   : Sample(1) ]

EncodeOrderExecutionMessage2(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.aggressorSide
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size
        \o message.tradeType
        \o message.complexTradeId
        \o message.instrumentType

DecodeOrderExecutionMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(sellOrderId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET tradeId == ReadBytes(aggressorSide.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET tradeType == ReadBytes(size.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET complexTradeId == ReadBytes(tradeType.rest, 8) IN IF ~complexTradeId.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(complexTradeId.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         tradeDate        |-> tradeDate.value,
         instrumentId     |-> instrumentId.value,
         buyOrderId       |-> buyOrderId.value,
         sellOrderId      |-> sellOrderId.value,
         aggressorSide    |-> aggressorSide.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value,
         tradeType        |-> tradeType.value,
         complexTradeId   |-> complexTradeId.value,
         instrumentType   |-> instrumentType.value ], instrumentType.rest)

ZeroOrderExecutionMessage2 ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      buyOrderId       |-> [i \in 1 .. 8 |-> 0],
      sellOrderId      |-> [i \in 1 .. 8 |-> 0],
      aggressorSide    |-> [i \in 1 .. 1 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      tradeType        |-> [i \in 1 .. 1 |-> 0],
      complexTradeId   |-> [i \in 1 .. 8 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage2 ==
    { ZeroOrderExecutionMessage2 }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.complexTradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 36 bytes                                          *)
(***************************************************************************)

TradeCancelMessage2 ==
    [ timestamp        : Sample(8),
      tradeDate        : Sample(2),
      instrumentId     : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      instrumentType   : Sample(1) ]

EncodeTradeCancelMessage2(message) ==
    message.timestamp
        \o message.tradeDate
        \o message.instrumentId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size
        \o message.instrumentType

DecodeTradeCancelMessage2(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timestamp.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(size.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         tradeDate        |-> tradeDate.value,
         instrumentId     |-> instrumentId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value,
         instrumentType   |-> instrumentType.value ], instrumentType.rest)

ZeroTradeCancelMessage2 ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage2 ==
    { ZeroTradeCancelMessage2 }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage2 EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SimpleInstrumentDefinitionMessageCode2 == 1  \* 0x01
ComplexInstrumentDefinitionMessageCode2 == 17  \* 0x11
ComplexInstrumentDefinitionDeprecatedMessageCode2 == 2  \* 0x02
SystemStateMessageCode2 == 3  \* 0x03
InstrumentTradingStatusNotificationMessageCode2 == 4  \* 0x04
AnticipatedOpeningPriceMessageCode2 == 5  \* 0x05
SettlementPriceUpdateMessageCode2 == 6  \* 0x06
OpenInterestUpdateMessageCode2 == 7  \* 0x07
TotalVolumeUpdateMessageCode2 == 8  \* 0x08
InstrumentClearMessageCode2 == 9  \* 0x09
AddOrderMessageCode2 == 10  \* 0x0a
ModifyOrderMessageCode2 == 11  \* 0x0b
DeleteOrderMessageCode2 == 12  \* 0x0c
OrderExecutionMessageCode2 == 13  \* 0x0d
TradeCancelMessageCode2 == 14  \* 0x0e

Data2 ==
    [ tag : {SimpleInstrumentDefinitionMessageCode2}, body : SimpleInstrumentDefinitionMessage2 ]
        \cup [ tag : {ComplexInstrumentDefinitionMessageCode2}, body : ComplexInstrumentDefinitionMessage2 ]
        \cup [ tag : {ComplexInstrumentDefinitionDeprecatedMessageCode2}, body : ComplexInstrumentDefinitionDeprecatedMessage2 ]
        \cup [ tag : {SystemStateMessageCode2}, body : SystemStateMessage2 ]
        \cup [ tag : {InstrumentTradingStatusNotificationMessageCode2}, body : InstrumentTradingStatusNotificationMessage2 ]
        \cup [ tag : {AnticipatedOpeningPriceMessageCode2}, body : AnticipatedOpeningPriceMessage2 ]
        \cup [ tag : {SettlementPriceUpdateMessageCode2}, body : SettlementPriceUpdateMessage2 ]
        \cup [ tag : {OpenInterestUpdateMessageCode2}, body : OpenInterestUpdateMessage2 ]
        \cup [ tag : {TotalVolumeUpdateMessageCode2}, body : TotalVolumeUpdateMessage2 ]
        \cup [ tag : {InstrumentClearMessageCode2}, body : InstrumentClearMessage2 ]
        \cup [ tag : {AddOrderMessageCode2}, body : AddOrderMessage2 ]
        \cup [ tag : {ModifyOrderMessageCode2}, body : ModifyOrderMessage2 ]
        \cup [ tag : {DeleteOrderMessageCode2}, body : DeleteOrderMessage2 ]
        \cup [ tag : {OrderExecutionMessageCode2}, body : OrderExecutionMessage2 ]
        \cup [ tag : {TradeCancelMessageCode2}, body : TradeCancelMessage2 ]

EncodeData2(message) ==
    CASE message.tag = SimpleInstrumentDefinitionMessageCode2 -> EncodeSimpleInstrumentDefinitionMessage2(message.body)
      [] message.tag = ComplexInstrumentDefinitionMessageCode2 -> EncodeComplexInstrumentDefinitionMessage2(message.body)
      [] message.tag = ComplexInstrumentDefinitionDeprecatedMessageCode2 -> EncodeComplexInstrumentDefinitionDeprecatedMessage2(message.body)
      [] message.tag = SystemStateMessageCode2 -> EncodeSystemStateMessage2(message.body)
      [] message.tag = InstrumentTradingStatusNotificationMessageCode2 -> EncodeInstrumentTradingStatusNotificationMessage2(message.body)
      [] message.tag = AnticipatedOpeningPriceMessageCode2 -> EncodeAnticipatedOpeningPriceMessage2(message.body)
      [] message.tag = SettlementPriceUpdateMessageCode2 -> EncodeSettlementPriceUpdateMessage2(message.body)
      [] message.tag = OpenInterestUpdateMessageCode2 -> EncodeOpenInterestUpdateMessage2(message.body)
      [] message.tag = TotalVolumeUpdateMessageCode2 -> EncodeTotalVolumeUpdateMessage2(message.body)
      [] message.tag = InstrumentClearMessageCode2 -> EncodeInstrumentClearMessage2(message.body)
      [] message.tag = AddOrderMessageCode2 -> EncodeAddOrderMessage2(message.body)
      [] message.tag = ModifyOrderMessageCode2 -> EncodeModifyOrderMessage2(message.body)
      [] message.tag = DeleteOrderMessageCode2 -> EncodeDeleteOrderMessage2(message.body)
      [] message.tag = OrderExecutionMessageCode2 -> EncodeOrderExecutionMessage2(message.body)
      [] message.tag = TradeCancelMessageCode2 -> EncodeTradeCancelMessage2(message.body)

DecodeData2(tag, bytes) ==
    LET read ==
            CASE tag = SimpleInstrumentDefinitionMessageCode2 -> DecodeSimpleInstrumentDefinitionMessage2(bytes)
              [] tag = ComplexInstrumentDefinitionMessageCode2 -> DecodeComplexInstrumentDefinitionMessage2(bytes)
              [] tag = ComplexInstrumentDefinitionDeprecatedMessageCode2 -> DecodeComplexInstrumentDefinitionDeprecatedMessage2(bytes)
              [] tag = SystemStateMessageCode2 -> DecodeSystemStateMessage2(bytes)
              [] tag = InstrumentTradingStatusNotificationMessageCode2 -> DecodeInstrumentTradingStatusNotificationMessage2(bytes)
              [] tag = AnticipatedOpeningPriceMessageCode2 -> DecodeAnticipatedOpeningPriceMessage2(bytes)
              [] tag = SettlementPriceUpdateMessageCode2 -> DecodeSettlementPriceUpdateMessage2(bytes)
              [] tag = OpenInterestUpdateMessageCode2 -> DecodeOpenInterestUpdateMessage2(bytes)
              [] tag = TotalVolumeUpdateMessageCode2 -> DecodeTotalVolumeUpdateMessage2(bytes)
              [] tag = InstrumentClearMessageCode2 -> DecodeInstrumentClearMessage2(bytes)
              [] tag = AddOrderMessageCode2 -> DecodeAddOrderMessage2(bytes)
              [] tag = ModifyOrderMessageCode2 -> DecodeModifyOrderMessage2(bytes)
              [] tag = DeleteOrderMessageCode2 -> DecodeDeleteOrderMessage2(bytes)
              [] tag = OrderExecutionMessageCode2 -> DecodeOrderExecutionMessage2(bytes)
              [] tag = TradeCancelMessageCode2 -> DecodeTradeCancelMessage2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData2 == [tag |-> SimpleInstrumentDefinitionMessageCode2, body |-> ZeroSimpleInstrumentDefinitionMessage2]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData2 ==
    { [tag |-> SimpleInstrumentDefinitionMessageCode2, body |-> one] : one \in CheckedSimpleInstrumentDefinitionMessage2 }
        \cup { [tag |-> ComplexInstrumentDefinitionMessageCode2, body |-> one] : one \in CheckedComplexInstrumentDefinitionMessage2 }
        \cup { [tag |-> ComplexInstrumentDefinitionDeprecatedMessageCode2, body |-> one] : one \in CheckedComplexInstrumentDefinitionDeprecatedMessage2 }
        \cup { [tag |-> SystemStateMessageCode2, body |-> one] : one \in CheckedSystemStateMessage2 }
        \cup { [tag |-> InstrumentTradingStatusNotificationMessageCode2, body |-> one] : one \in CheckedInstrumentTradingStatusNotificationMessage2 }
        \cup { [tag |-> AnticipatedOpeningPriceMessageCode2, body |-> one] : one \in CheckedAnticipatedOpeningPriceMessage2 }
        \cup { [tag |-> SettlementPriceUpdateMessageCode2, body |-> one] : one \in CheckedSettlementPriceUpdateMessage2 }
        \cup { [tag |-> OpenInterestUpdateMessageCode2, body |-> one] : one \in CheckedOpenInterestUpdateMessage2 }
        \cup { [tag |-> TotalVolumeUpdateMessageCode2, body |-> one] : one \in CheckedTotalVolumeUpdateMessage2 }
        \cup { [tag |-> InstrumentClearMessageCode2, body |-> one] : one \in CheckedInstrumentClearMessage2 }
        \cup { [tag |-> AddOrderMessageCode2, body |-> one] : one \in CheckedAddOrderMessage2 }
        \cup { [tag |-> ModifyOrderMessageCode2, body |-> one] : one \in CheckedModifyOrderMessage2 }
        \cup { [tag |-> DeleteOrderMessageCode2, body |-> one] : one \in CheckedDeleteOrderMessage2 }
        \cup { [tag |-> OrderExecutionMessageCode2, body |-> one] : one \in CheckedOrderExecutionMessage2 }
        \cup { [tag |-> TradeCancelMessageCode2, body |-> one] : one \in CheckedTradeCancelMessage2 }

(***************************************************************************)
(* Refresh Response                                                        *)
(***************************************************************************)

RefreshResponse ==
    [ sequenceNumber : Sample(8),
      data           : Data2 ]

EncodeRefreshResponse(message) ==
    message.sequenceNumber
        \o EncodeUIntBE(message.data.tag, 1)
        \o EncodeData2(message.data)

DecodeRefreshResponse(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(sequenceNumber.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData2(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         data           |-> data.value ], data.rest)

ZeroRefreshResponse ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      data           |-> ZeroData2 ]

(* Refresh Response at zero, then each field in turn at the values it is checked at *)
CheckedRefreshResponse ==
    { ZeroRefreshResponse }
        \cup { [ZeroRefreshResponse EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRefreshResponse EXCEPT !.data = one] : one \in CheckedData2 }

(***************************************************************************)
(* End Of Refresh: 1 bytes                                                 *)
(***************************************************************************)

EndOfRefresh ==
    [ refreshMessageType : Sample(1) ]

EncodeEndOfRefresh(message) ==
    message.refreshMessageType

DecodeEndOfRefresh(bytes) ==
    LET refreshMessageType == ReadBytes(bytes, 1) IN IF ~refreshMessageType.ok THEN Fail ELSE
    Ok([ refreshMessageType |-> refreshMessageType.value ], refreshMessageType.rest)

ZeroEndOfRefresh ==
    [ refreshMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* End Of Refresh at zero, then each field in turn at the values it is checked at *)
CheckedEndOfRefresh ==
    { ZeroEndOfRefresh }
        \cup { [ZeroEndOfRefresh EXCEPT !.refreshMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* Refresh Payload, selected by Refresh Type                               *)
(***************************************************************************)

RefreshRequestCode == 82  \* "R"
RefreshResponseCode == 114  \* "r"
EndOfRefreshCode == 69  \* "E"

RefreshPayload ==
    [ tag : {RefreshRequestCode}, body : RefreshRequest ]
        \cup [ tag : {RefreshResponseCode}, body : RefreshResponse ]
        \cup [ tag : {EndOfRefreshCode}, body : EndOfRefresh ]

EncodeRefreshPayload(message) ==
    CASE message.tag = RefreshRequestCode -> EncodeRefreshRequest(message.body)
      [] message.tag = RefreshResponseCode -> EncodeRefreshResponse(message.body)
      [] message.tag = EndOfRefreshCode -> EncodeEndOfRefresh(message.body)

DecodeRefreshPayload(tag, bytes) ==
    LET read ==
            CASE tag = RefreshRequestCode -> DecodeRefreshRequest(bytes)
              [] tag = RefreshResponseCode -> DecodeRefreshResponse(bytes)
              [] tag = EndOfRefreshCode -> DecodeEndOfRefresh(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroRefreshPayload == [tag |-> RefreshRequestCode, body |-> ZeroRefreshRequest]

(* Each Refresh Payload in turn, at the values the message it names is checked at *)
CheckedRefreshPayload ==
    { [tag |-> RefreshRequestCode, body |-> one] : one \in CheckedRefreshRequest }
        \cup { [tag |-> RefreshResponseCode, body |-> one] : one \in CheckedRefreshResponse }
        \cup { [tag |-> EndOfRefreshCode, body |-> one] : one \in CheckedEndOfRefresh }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ refreshPayload : RefreshPayload ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.refreshPayload.tag, 1)
        \o EncodeRefreshPayload(message.refreshPayload)

DecodeUnsequencedDataPacket(bytes) ==
    LET refreshType == ReadUIntBE(bytes, 1) IN IF ~refreshType.ok THEN Fail ELSE
    LET refreshPayload == DecodeRefreshPayload(refreshType.value, refreshType.rest) IN IF ~refreshPayload.ok THEN Fail ELSE
    Ok([ refreshPayload |-> refreshPayload.value ], refreshPayload.rest)

ZeroUnsequencedDataPacket ==
    [ refreshPayload |-> ZeroRefreshPayload ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.refreshPayload = one] : one \in CheckedRefreshPayload }

(***************************************************************************)
(* Login Request: 35 bytes                                                 *)
(***************************************************************************)

LoginRequest ==
    [ sesmVersion             : Sample(5),
      username                : Sample(5),
      computerId              : Sample(8),
      applicationProtocol     : Sample(8),
      requestedSession        : Sample(1),
      requestedSequenceNumber : Sample(8) ]

EncodeLoginRequest(message) ==
    message.sesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequest(bytes) ==
    LET sesmVersion == ReadBytes(bytes, 5) IN IF ~sesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(sesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(applicationProtocol.rest, 1) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ sesmVersion             |-> sesmVersion.value,
         username                |-> username.value,
         computerId              |-> computerId.value,
         applicationProtocol     |-> applicationProtocol.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequest ==
    [ sesmVersion             |-> [i \in 1 .. 5 |-> 0],
      username                |-> [i \in 1 .. 5 |-> 0],
      computerId              |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol     |-> [i \in 1 .. 8 |-> 0],
      requestedSession        |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.sesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSession = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response: 10 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ loginStatus           : Sample(1),
      sessionId             : Sample(1),
      highestSequenceNumber : Sample(8) ]

EncodeLoginResponse(message) ==
    message.loginStatus
        \o message.sessionId
        \o message.highestSequenceNumber

DecodeLoginResponse(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET sessionId == ReadBytes(loginStatus.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ loginStatus           |-> loginStatus.value,
         sessionId             |-> sessionId.value,
         highestSequenceNumber |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroLoginResponse ==
    [ loginStatus           |-> [i \in 1 .. 1 |-> 0],
      sessionId             |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Retransmission Request: 16 bytes                                        *)
(***************************************************************************)

RetransmissionRequest ==
    [ startSequenceNumber : Sample(8),
      endSequenceNumber   : Sample(8) ]

EncodeRetransmissionRequest(message) ==
    message.startSequenceNumber
        \o message.endSequenceNumber

DecodeRetransmissionRequest(bytes) ==
    LET startSequenceNumber == ReadBytes(bytes, 8) IN IF ~startSequenceNumber.ok THEN Fail ELSE
    LET endSequenceNumber == ReadBytes(startSequenceNumber.rest, 8) IN IF ~endSequenceNumber.ok THEN Fail ELSE
    Ok([ startSequenceNumber |-> startSequenceNumber.value,
         endSequenceNumber   |-> endSequenceNumber.value ], endSequenceNumber.rest)

ZeroRetransmissionRequest ==
    [ startSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      endSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Retransmission Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequest ==
    { ZeroRetransmissionRequest }
        \cup { [ZeroRetransmissionRequest EXCEPT !.startSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequest EXCEPT !.endSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Request                                                          *)
(***************************************************************************)

LogoutRequest ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeLogoutRequest(message) ==
    message.logoutReason
        \o message.logoutText

DecodeLogoutRequest(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroLogoutRequest ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Goodbye Packet                                                          *)
(***************************************************************************)

GoodbyePacket ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.logoutReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Sesm Payload, selected by Sesm Packet Type                              *)
(***************************************************************************)

SequencedDataPacketCode == 83  \* "S"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 76  \* "L"
LoginResponseCode == 82  \* "R"
SynchronizationCompleteCode == 67  \* "C"
RetransmissionRequestCode == 65  \* "A"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
EndOfSessionCode == 69  \* "E"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"

SesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]

EncodeSesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> << >>
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>

DecodeSesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSesmPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Sesm Payload in turn, at the values the message it names is checked at *)
CheckedSesmPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Sesm Tcp Packet, framed by Sesm Packet Length                           *)
(***************************************************************************)

SesmTcpPacket ==
    [ sesmPayload : SesmPayload ]

EncodeSesmTcpPacketBody(message) ==
    EncodeUIntBE(message.sesmPayload.tag, 1)
        \o EncodeSesmPayload(message.sesmPayload)

(* Sesm Packet Length counts the bytes it frames, so it is written from them *)
EncodeSesmTcpPacket(message) ==
    LET body == EncodeSesmTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeSesmTcpPacketBody(bytes) ==
    LET sesmPacketType == ReadUIntBE(bytes, 1) IN IF ~sesmPacketType.ok THEN Fail ELSE
    LET sesmPayload == DecodeSesmPayload(sesmPacketType.value, sesmPacketType.rest) IN IF ~sesmPayload.ok THEN Fail ELSE
    Ok([ sesmPayload |-> sesmPayload.value ], sesmPayload.rest)

DecodeSesmTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeSesmTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSesmTcpPacket ==
    [ sesmPayload |-> ZeroSesmPayload ]

(* Sesm Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedSesmTcpPacket ==
    { ZeroSesmTcpPacket }
        \cup { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = one] : one \in CheckedSesmPayload }

(* A run of Sesm Tcp Packet, written one after another *)
RECURSIVE EncodeSesmTcpPacketList(_)
EncodeSesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSesmTcpPacket(Head(messages)) \o EncodeSesmTcpPacketList(Tail(messages))

(* As many Sesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSesmTcpPacketAll(_)
ReadSesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sesm Tcp Packet of each kind, for the lists that carry them *)
OneSesmTcpPacket ==
    { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sesmTcpPacket : SampleLists(OneSesmTcpPacket) ]

EncodePacket(message) ==
    EncodeSesmTcpPacketList(message.sesmTcpPacket)

DecodePacket(bytes) ==
    LET sesmTcpPacket == ReadSesmTcpPacketAll(bytes) IN IF ~sesmTcpPacket.ok THEN Fail ELSE
    Ok([ sesmTcpPacket |-> sesmTcpPacket.value ], sesmTcpPacket.rest)

ZeroPacket ==
    [ sesmTcpPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sesmTcpPacket = one] : one \in SampleLists(OneSesmTcpPacket) }

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

(* Every Deprecated Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedInstrumentLeg ==
    \A message \in CheckedDeprecatedInstrumentLeg :
        LET read == DecodeDeprecatedInstrumentLeg(EncodeDeprecatedInstrumentLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Definition Deprecated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDefinitionDeprecatedMessage ==
    \A message \in CheckedComplexInstrumentDefinitionDeprecatedMessage :
        LET read == DecodeComplexInstrumentDefinitionDeprecatedMessage(EncodeComplexInstrumentDefinitionDeprecatedMessage(message))
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

(* Every Anticipated Opening Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnticipatedOpeningPriceMessage ==
    \A message \in CheckedAnticipatedOpeningPriceMessage :
        LET read == DecodeAnticipatedOpeningPriceMessage(EncodeAnticipatedOpeningPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementPriceUpdateMessage ==
    \A message \in CheckedSettlementPriceUpdateMessage :
        LET read == DecodeSettlementPriceUpdateMessage(EncodeSettlementPriceUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestUpdateMessage ==
    \A message \in CheckedOpenInterestUpdateMessage :
        LET read == DecodeOpenInterestUpdateMessage(EncodeOpenInterestUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Volume Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalVolumeUpdateMessage ==
    \A message \in CheckedTotalVolumeUpdateMessage :
        LET read == DecodeTotalVolumeUpdateMessage(EncodeTotalVolumeUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentClearMessage ==
    \A message \in CheckedInstrumentClearMessage :
        LET read == DecodeInstrumentClearMessage(EncodeInstrumentClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
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

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshRequest ==
    \A message \in CheckedRefreshRequest :
        LET read == DecodeRefreshRequest(EncodeRefreshRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleInstrumentDefinitionMessage2 ==
    \A message \in CheckedSimpleInstrumentDefinitionMessage2 :
        LET read == DecodeSimpleInstrumentDefinitionMessage2(EncodeSimpleInstrumentDefinitionMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentLeg2 ==
    \A message \in CheckedInstrumentLeg2 :
        LET read == DecodeInstrumentLeg2(EncodeInstrumentLeg2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDefinitionMessage2 ==
    \A message \in CheckedComplexInstrumentDefinitionMessage2 :
        LET read == DecodeComplexInstrumentDefinitionMessage2(EncodeComplexInstrumentDefinitionMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedInstrumentLeg2 ==
    \A message \in CheckedDeprecatedInstrumentLeg2 :
        LET read == DecodeDeprecatedInstrumentLeg2(EncodeDeprecatedInstrumentLeg2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Definition Deprecated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDefinitionDeprecatedMessage2 ==
    \A message \in CheckedComplexInstrumentDefinitionDeprecatedMessage2 :
        LET read == DecodeComplexInstrumentDefinitionDeprecatedMessage2(EncodeComplexInstrumentDefinitionDeprecatedMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage2 ==
    \A message \in CheckedSystemStateMessage2 :
        LET read == DecodeSystemStateMessage2(EncodeSystemStateMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Trading Status Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentTradingStatusNotificationMessage2 ==
    \A message \in CheckedInstrumentTradingStatusNotificationMessage2 :
        LET read == DecodeInstrumentTradingStatusNotificationMessage2(EncodeInstrumentTradingStatusNotificationMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Anticipated Opening Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnticipatedOpeningPriceMessage2 ==
    \A message \in CheckedAnticipatedOpeningPriceMessage2 :
        LET read == DecodeAnticipatedOpeningPriceMessage2(EncodeAnticipatedOpeningPriceMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementPriceUpdateMessage2 ==
    \A message \in CheckedSettlementPriceUpdateMessage2 :
        LET read == DecodeSettlementPriceUpdateMessage2(EncodeSettlementPriceUpdateMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestUpdateMessage2 ==
    \A message \in CheckedOpenInterestUpdateMessage2 :
        LET read == DecodeOpenInterestUpdateMessage2(EncodeOpenInterestUpdateMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Volume Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalVolumeUpdateMessage2 ==
    \A message \in CheckedTotalVolumeUpdateMessage2 :
        LET read == DecodeTotalVolumeUpdateMessage2(EncodeTotalVolumeUpdateMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentClearMessage2 ==
    \A message \in CheckedInstrumentClearMessage2 :
        LET read == DecodeInstrumentClearMessage2(EncodeInstrumentClearMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage2 ==
    \A message \in CheckedAddOrderMessage2 :
        LET read == DecodeAddOrderMessage2(EncodeAddOrderMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage2 ==
    \A message \in CheckedModifyOrderMessage2 :
        LET read == DecodeModifyOrderMessage2(EncodeModifyOrderMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage2 ==
    \A message \in CheckedDeleteOrderMessage2 :
        LET read == DecodeDeleteOrderMessage2(EncodeDeleteOrderMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage2 ==
    \A message \in CheckedOrderExecutionMessage2 :
        LET read == DecodeOrderExecutionMessage2(EncodeOrderExecutionMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage2 ==
    \A message \in CheckedTradeCancelMessage2 :
        LET read == DecodeTradeCancelMessage2(EncodeTradeCancelMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Response decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshResponse ==
    \A message \in CheckedRefreshResponse :
        LET read == DecodeRefreshResponse(EncodeRefreshResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Refresh decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfRefresh ==
    \A message \in CheckedEndOfRefresh :
        LET read == DecodeEndOfRefresh(EncodeEndOfRefresh(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequest ==
    \A message \in CheckedRetransmissionRequest :
        LET read == DecodeRetransmissionRequest(EncodeRetransmissionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Goodbye Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripGoodbyePacket ==
    \A message \in CheckedGoodbyePacket :
        LET read == DecodeGoodbyePacket(EncodeGoodbyePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sesm Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET read == DecodeSesmTcpPacket(EncodeSesmTcpPacket(message))
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

(* A Data is selected by the Message Type it is written under *)
SelectsData2 ==
    \A message \in CheckedData2 :
        LET read == DecodeData2(message.tag, EncodeData2(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Refresh Payload is selected by the Refresh Type it is written under *)
SelectsRefreshPayload ==
    \A message \in CheckedRefreshPayload :
        LET read == DecodeRefreshPayload(message.tag, EncodeRefreshPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sesm Payload is selected by the Sesm Packet Type it is written under *)
SelectsSesmPayload ==
    \A message \in CheckedSesmPayload :
        LET read == DecodeSesmPayload(message.tag, EncodeSesmPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Sesm Packet Length is written from the bytes it frames *)
FramesSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET bytes == EncodeSesmTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
