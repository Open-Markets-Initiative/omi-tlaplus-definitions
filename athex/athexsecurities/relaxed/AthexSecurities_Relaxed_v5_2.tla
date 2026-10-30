------------------- MODULE AthexSecurities_Relaxed_v5_2 --------------------
(***************************************************************************)
(* Athens Exchange Group Athens Exchange Securities Market Relaxed Channel *)
(* v5.2                                                                    *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Apa Post Trade Message: 699 bytes                                       *)
(***************************************************************************)

ApaPostTradeMessage ==
    [ reportStatus                           : Sample(4),
      tradingDateAndTime                     : Sample(20),
      tradeIdIndicator                       : Sample(1),
      tradeId                                : Sample(52),
      venue                                  : Sample(4),
      transactionToBeCleared                 : Sample(1),
      priceNotation                          : Sample(4),
      price                                  : Sample(18),
      priceCurrency                          : Sample(3),
      quantity                               : Sample(18),
      quantityCurrency                       : Sample(3),
      notationOfTheQuantityInMeasurementUnit : Sample(25),
      quantityInMeasurementUnit              : Sample(18),
      notionalAmount                         : Sample(18),
      notionalCurrency                       : Sample(3),
      instrumentIdType                       : Sample(4),
      instrumentId                           : Sample(12),
      instrumentFullName                     : Sample(350),
      instrumentClassification               : Sample(6),
      priceMultiplier                        : Sample(18),
      underlyingInstrumentCode               : Sample(12),
      underlyingIndexName                    : Sample(25),
      termOfTheUnderlyingIndex               : Sample(7),
      optionType                             : Sample(4),
      strikePrice                            : Sample(18),
      strikePriceCurrency                    : Sample(3),
      strikePriceNotation                    : Sample(4),
      optionExerciseStyle                    : Sample(4),
      maturityDate                           : Sample(8),
      expiryDate                             : Sample(8),
      deliveryType                           : Sample(4),
      typeEmissionAllowance                  : Sample(4),
      otcPostTradeIndicator                  : Sample(4),
      deferralIndicator                      : Sample(1),
      lmtf                                   : Sample(1),
      fulf                                   : Sample(1),
      datf                                   : Sample(1),
      fula                                   : Sample(1),
      volo                                   : Sample(1),
      fulv                                   : Sample(1),
      fwaf                                   : Sample(1),
      fulj                                   : Sample(1),
      idaf                                   : Sample(1),
      volw                                   : Sample(1),
      coaf                                   : Sample(1) ]

EncodeApaPostTradeMessage(message) ==
    message.reportStatus
        \o message.tradingDateAndTime
        \o message.tradeIdIndicator
        \o message.tradeId
        \o message.venue
        \o message.transactionToBeCleared
        \o message.priceNotation
        \o message.price
        \o message.priceCurrency
        \o message.quantity
        \o message.quantityCurrency
        \o message.notationOfTheQuantityInMeasurementUnit
        \o message.quantityInMeasurementUnit
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.instrumentIdType
        \o message.instrumentId
        \o message.instrumentFullName
        \o message.instrumentClassification
        \o message.priceMultiplier
        \o message.underlyingInstrumentCode
        \o message.underlyingIndexName
        \o message.termOfTheUnderlyingIndex
        \o message.optionType
        \o message.strikePrice
        \o message.strikePriceCurrency
        \o message.strikePriceNotation
        \o message.optionExerciseStyle
        \o message.maturityDate
        \o message.expiryDate
        \o message.deliveryType
        \o message.typeEmissionAllowance
        \o message.otcPostTradeIndicator
        \o message.deferralIndicator
        \o message.lmtf
        \o message.fulf
        \o message.datf
        \o message.fula
        \o message.volo
        \o message.fulv
        \o message.fwaf
        \o message.fulj
        \o message.idaf
        \o message.volw
        \o message.coaf

DecodeApaPostTradeMessage(bytes) ==
    LET reportStatus == ReadBytes(bytes, 4) IN IF ~reportStatus.ok THEN Fail ELSE
    LET tradingDateAndTime == ReadBytes(reportStatus.rest, 20) IN IF ~tradingDateAndTime.ok THEN Fail ELSE
    LET tradeIdIndicator == ReadBytes(tradingDateAndTime.rest, 1) IN IF ~tradeIdIndicator.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeIdIndicator.rest, 52) IN IF ~tradeId.ok THEN Fail ELSE
    LET venue == ReadBytes(tradeId.rest, 4) IN IF ~venue.ok THEN Fail ELSE
    LET transactionToBeCleared == ReadBytes(venue.rest, 1) IN IF ~transactionToBeCleared.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(transactionToBeCleared.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET price == ReadBytes(priceNotation.rest, 18) IN IF ~price.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(price.rest, 3) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET quantity == ReadBytes(priceCurrency.rest, 18) IN IF ~quantity.ok THEN Fail ELSE
    LET quantityCurrency == ReadBytes(quantity.rest, 3) IN IF ~quantityCurrency.ok THEN Fail ELSE
    LET notationOfTheQuantityInMeasurementUnit == ReadBytes(quantityCurrency.rest, 25) IN IF ~notationOfTheQuantityInMeasurementUnit.ok THEN Fail ELSE
    LET quantityInMeasurementUnit == ReadBytes(notationOfTheQuantityInMeasurementUnit.rest, 18) IN IF ~quantityInMeasurementUnit.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(quantityInMeasurementUnit.rest, 18) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET instrumentIdType == ReadBytes(notionalCurrency.rest, 4) IN IF ~instrumentIdType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentIdType.rest, 12) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentFullName == ReadBytes(instrumentId.rest, 350) IN IF ~instrumentFullName.ok THEN Fail ELSE
    LET instrumentClassification == ReadBytes(instrumentFullName.rest, 6) IN IF ~instrumentClassification.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(instrumentClassification.rest, 18) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET underlyingInstrumentCode == ReadBytes(priceMultiplier.rest, 12) IN IF ~underlyingInstrumentCode.ok THEN Fail ELSE
    LET underlyingIndexName == ReadBytes(underlyingInstrumentCode.rest, 25) IN IF ~underlyingIndexName.ok THEN Fail ELSE
    LET termOfTheUnderlyingIndex == ReadBytes(underlyingIndexName.rest, 7) IN IF ~termOfTheUnderlyingIndex.ok THEN Fail ELSE
    LET optionType == ReadBytes(termOfTheUnderlyingIndex.rest, 4) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 18) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(strikePrice.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET strikePriceNotation == ReadBytes(strikePriceCurrency.rest, 4) IN IF ~strikePriceNotation.ok THEN Fail ELSE
    LET optionExerciseStyle == ReadBytes(strikePriceNotation.rest, 4) IN IF ~optionExerciseStyle.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(optionExerciseStyle.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(maturityDate.rest, 8) IN IF ~expiryDate.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(expiryDate.rest, 4) IN IF ~deliveryType.ok THEN Fail ELSE
    LET typeEmissionAllowance == ReadBytes(deliveryType.rest, 4) IN IF ~typeEmissionAllowance.ok THEN Fail ELSE
    LET otcPostTradeIndicator == ReadBytes(typeEmissionAllowance.rest, 4) IN IF ~otcPostTradeIndicator.ok THEN Fail ELSE
    LET deferralIndicator == ReadBytes(otcPostTradeIndicator.rest, 1) IN IF ~deferralIndicator.ok THEN Fail ELSE
    LET lmtf == ReadBytes(deferralIndicator.rest, 1) IN IF ~lmtf.ok THEN Fail ELSE
    LET fulf == ReadBytes(lmtf.rest, 1) IN IF ~fulf.ok THEN Fail ELSE
    LET datf == ReadBytes(fulf.rest, 1) IN IF ~datf.ok THEN Fail ELSE
    LET fula == ReadBytes(datf.rest, 1) IN IF ~fula.ok THEN Fail ELSE
    LET volo == ReadBytes(fula.rest, 1) IN IF ~volo.ok THEN Fail ELSE
    LET fulv == ReadBytes(volo.rest, 1) IN IF ~fulv.ok THEN Fail ELSE
    LET fwaf == ReadBytes(fulv.rest, 1) IN IF ~fwaf.ok THEN Fail ELSE
    LET fulj == ReadBytes(fwaf.rest, 1) IN IF ~fulj.ok THEN Fail ELSE
    LET idaf == ReadBytes(fulj.rest, 1) IN IF ~idaf.ok THEN Fail ELSE
    LET volw == ReadBytes(idaf.rest, 1) IN IF ~volw.ok THEN Fail ELSE
    LET coaf == ReadBytes(volw.rest, 1) IN IF ~coaf.ok THEN Fail ELSE
    Ok([ reportStatus                           |-> reportStatus.value,
         tradingDateAndTime                     |-> tradingDateAndTime.value,
         tradeIdIndicator                       |-> tradeIdIndicator.value,
         tradeId                                |-> tradeId.value,
         venue                                  |-> venue.value,
         transactionToBeCleared                 |-> transactionToBeCleared.value,
         priceNotation                          |-> priceNotation.value,
         price                                  |-> price.value,
         priceCurrency                          |-> priceCurrency.value,
         quantity                               |-> quantity.value,
         quantityCurrency                       |-> quantityCurrency.value,
         notationOfTheQuantityInMeasurementUnit |-> notationOfTheQuantityInMeasurementUnit.value,
         quantityInMeasurementUnit              |-> quantityInMeasurementUnit.value,
         notionalAmount                         |-> notionalAmount.value,
         notionalCurrency                       |-> notionalCurrency.value,
         instrumentIdType                       |-> instrumentIdType.value,
         instrumentId                           |-> instrumentId.value,
         instrumentFullName                     |-> instrumentFullName.value,
         instrumentClassification               |-> instrumentClassification.value,
         priceMultiplier                        |-> priceMultiplier.value,
         underlyingInstrumentCode               |-> underlyingInstrumentCode.value,
         underlyingIndexName                    |-> underlyingIndexName.value,
         termOfTheUnderlyingIndex               |-> termOfTheUnderlyingIndex.value,
         optionType                             |-> optionType.value,
         strikePrice                            |-> strikePrice.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         strikePriceNotation                    |-> strikePriceNotation.value,
         optionExerciseStyle                    |-> optionExerciseStyle.value,
         maturityDate                           |-> maturityDate.value,
         expiryDate                             |-> expiryDate.value,
         deliveryType                           |-> deliveryType.value,
         typeEmissionAllowance                  |-> typeEmissionAllowance.value,
         otcPostTradeIndicator                  |-> otcPostTradeIndicator.value,
         deferralIndicator                      |-> deferralIndicator.value,
         lmtf                                   |-> lmtf.value,
         fulf                                   |-> fulf.value,
         datf                                   |-> datf.value,
         fula                                   |-> fula.value,
         volo                                   |-> volo.value,
         fulv                                   |-> fulv.value,
         fwaf                                   |-> fwaf.value,
         fulj                                   |-> fulj.value,
         idaf                                   |-> idaf.value,
         volw                                   |-> volw.value,
         coaf                                   |-> coaf.value ], coaf.rest)

ZeroApaPostTradeMessage ==
    [ reportStatus                           |-> [i \in 1 .. 4 |-> 0],
      tradingDateAndTime                     |-> [i \in 1 .. 20 |-> 0],
      tradeIdIndicator                       |-> [i \in 1 .. 1 |-> 0],
      tradeId                                |-> [i \in 1 .. 52 |-> 0],
      venue                                  |-> [i \in 1 .. 4 |-> 0],
      transactionToBeCleared                 |-> [i \in 1 .. 1 |-> 0],
      priceNotation                          |-> [i \in 1 .. 4 |-> 0],
      price                                  |-> [i \in 1 .. 18 |-> 0],
      priceCurrency                          |-> [i \in 1 .. 3 |-> 0],
      quantity                               |-> [i \in 1 .. 18 |-> 0],
      quantityCurrency                       |-> [i \in 1 .. 3 |-> 0],
      notationOfTheQuantityInMeasurementUnit |-> [i \in 1 .. 25 |-> 0],
      quantityInMeasurementUnit              |-> [i \in 1 .. 18 |-> 0],
      notionalAmount                         |-> [i \in 1 .. 18 |-> 0],
      notionalCurrency                       |-> [i \in 1 .. 3 |-> 0],
      instrumentIdType                       |-> [i \in 1 .. 4 |-> 0],
      instrumentId                           |-> [i \in 1 .. 12 |-> 0],
      instrumentFullName                     |-> [i \in 1 .. 350 |-> 0],
      instrumentClassification               |-> [i \in 1 .. 6 |-> 0],
      priceMultiplier                        |-> [i \in 1 .. 18 |-> 0],
      underlyingInstrumentCode               |-> [i \in 1 .. 12 |-> 0],
      underlyingIndexName                    |-> [i \in 1 .. 25 |-> 0],
      termOfTheUnderlyingIndex               |-> [i \in 1 .. 7 |-> 0],
      optionType                             |-> [i \in 1 .. 4 |-> 0],
      strikePrice                            |-> [i \in 1 .. 18 |-> 0],
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      strikePriceNotation                    |-> [i \in 1 .. 4 |-> 0],
      optionExerciseStyle                    |-> [i \in 1 .. 4 |-> 0],
      maturityDate                           |-> [i \in 1 .. 8 |-> 0],
      expiryDate                             |-> [i \in 1 .. 8 |-> 0],
      deliveryType                           |-> [i \in 1 .. 4 |-> 0],
      typeEmissionAllowance                  |-> [i \in 1 .. 4 |-> 0],
      otcPostTradeIndicator                  |-> [i \in 1 .. 4 |-> 0],
      deferralIndicator                      |-> [i \in 1 .. 1 |-> 0],
      lmtf                                   |-> [i \in 1 .. 1 |-> 0],
      fulf                                   |-> [i \in 1 .. 1 |-> 0],
      datf                                   |-> [i \in 1 .. 1 |-> 0],
      fula                                   |-> [i \in 1 .. 1 |-> 0],
      volo                                   |-> [i \in 1 .. 1 |-> 0],
      fulv                                   |-> [i \in 1 .. 1 |-> 0],
      fwaf                                   |-> [i \in 1 .. 1 |-> 0],
      fulj                                   |-> [i \in 1 .. 1 |-> 0],
      idaf                                   |-> [i \in 1 .. 1 |-> 0],
      volw                                   |-> [i \in 1 .. 1 |-> 0],
      coaf                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Apa Post Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedApaPostTradeMessage ==
    { ZeroApaPostTradeMessage }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.reportStatus = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.tradingDateAndTime = one] : one \in Sample(20) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.tradeIdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.tradeId = one] : one \in Sample(52) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.venue = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.transactionToBeCleared = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.price = one] : one \in Sample(18) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.priceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.quantity = one] : one \in Sample(18) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.quantityCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.notationOfTheQuantityInMeasurementUnit = one] : one \in Sample(25) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.quantityInMeasurementUnit = one] : one \in Sample(18) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.notionalAmount = one] : one \in Sample(18) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.instrumentIdType = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(12) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.instrumentFullName = one] : one \in Sample(350) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.instrumentClassification = one] : one \in Sample(6) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.priceMultiplier = one] : one \in Sample(18) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.underlyingInstrumentCode = one] : one \in Sample(12) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.underlyingIndexName = one] : one \in Sample(25) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.termOfTheUnderlyingIndex = one] : one \in Sample(7) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.optionType = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(18) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.strikePriceNotation = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.optionExerciseStyle = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.expiryDate = one] : one \in Sample(8) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.deliveryType = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.typeEmissionAllowance = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.otcPostTradeIndicator = one] : one \in Sample(4) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.deferralIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.lmtf = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.fulf = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.datf = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.fula = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.volo = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.fulv = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.fwaf = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.fulj = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.idaf = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.volw = one] : one \in Sample(1) }
        \cup { [ZeroApaPostTradeMessage EXCEPT !.coaf = one] : one \in Sample(1) }

(***************************************************************************)
(* Apa Pre Trade Message: 699 bytes                                        *)
(***************************************************************************)

ApaPreTradeMessage ==
    [ reportStatus                           : Sample(4),
      quoteType                              : Sample(1),
      quoteId                                : Sample(52),
      eventTime                              : Sample(20),
      quoteLiquidity                         : Sample(1),
      venueMic                               : Sample(4),
      submittingEntityIdentificationCode     : Sample(20),
      priceNotation                          : Sample(4),
      price                                  : Sample(18),
      priceCurrency                          : Sample(3),
      quantity                               : Sample(18),
      quantityCurrency                       : Sample(3),
      notationOfTheQuantityInMeasurementUnit : Sample(25),
      quantityInMeasurementUnit              : Sample(18),
      notionalAmount                         : Sample(18),
      notionalCurrency                       : Sample(3),
      instrumentIdType                       : Sample(4),
      instrumentId                           : Sample(12),
      instrumentFullName                     : Sample(350),
      instrumentClassification               : Sample(6),
      priceMultiplier                        : Sample(18),
      underlyingInstrumentCode               : Sample(12),
      underlyingIndexName                    : Sample(25),
      termOfTheUnderlyingIndex               : Sample(7),
      optionType                             : Sample(4),
      strikePrice                            : Sample(18),
      strikePriceCurrency                    : Sample(3),
      strikePriceNotation                    : Sample(4),
      optionExerciseStyle                    : Sample(4),
      maturityDate                           : Sample(8),
      expiryDate                             : Sample(8),
      deliveryType                           : Sample(4) ]

EncodeApaPreTradeMessage(message) ==
    message.reportStatus
        \o message.quoteType
        \o message.quoteId
        \o message.eventTime
        \o message.quoteLiquidity
        \o message.venueMic
        \o message.submittingEntityIdentificationCode
        \o message.priceNotation
        \o message.price
        \o message.priceCurrency
        \o message.quantity
        \o message.quantityCurrency
        \o message.notationOfTheQuantityInMeasurementUnit
        \o message.quantityInMeasurementUnit
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.instrumentIdType
        \o message.instrumentId
        \o message.instrumentFullName
        \o message.instrumentClassification
        \o message.priceMultiplier
        \o message.underlyingInstrumentCode
        \o message.underlyingIndexName
        \o message.termOfTheUnderlyingIndex
        \o message.optionType
        \o message.strikePrice
        \o message.strikePriceCurrency
        \o message.strikePriceNotation
        \o message.optionExerciseStyle
        \o message.maturityDate
        \o message.expiryDate
        \o message.deliveryType

DecodeApaPreTradeMessage(bytes) ==
    LET reportStatus == ReadBytes(bytes, 4) IN IF ~reportStatus.ok THEN Fail ELSE
    LET quoteType == ReadBytes(reportStatus.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET quoteId == ReadBytes(quoteType.rest, 52) IN IF ~quoteId.ok THEN Fail ELSE
    LET eventTime == ReadBytes(quoteId.rest, 20) IN IF ~eventTime.ok THEN Fail ELSE
    LET quoteLiquidity == ReadBytes(eventTime.rest, 1) IN IF ~quoteLiquidity.ok THEN Fail ELSE
    LET venueMic == ReadBytes(quoteLiquidity.rest, 4) IN IF ~venueMic.ok THEN Fail ELSE
    LET submittingEntityIdentificationCode == ReadBytes(venueMic.rest, 20) IN IF ~submittingEntityIdentificationCode.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(submittingEntityIdentificationCode.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET price == ReadBytes(priceNotation.rest, 18) IN IF ~price.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(price.rest, 3) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET quantity == ReadBytes(priceCurrency.rest, 18) IN IF ~quantity.ok THEN Fail ELSE
    LET quantityCurrency == ReadBytes(quantity.rest, 3) IN IF ~quantityCurrency.ok THEN Fail ELSE
    LET notationOfTheQuantityInMeasurementUnit == ReadBytes(quantityCurrency.rest, 25) IN IF ~notationOfTheQuantityInMeasurementUnit.ok THEN Fail ELSE
    LET quantityInMeasurementUnit == ReadBytes(notationOfTheQuantityInMeasurementUnit.rest, 18) IN IF ~quantityInMeasurementUnit.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(quantityInMeasurementUnit.rest, 18) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET instrumentIdType == ReadBytes(notionalCurrency.rest, 4) IN IF ~instrumentIdType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentIdType.rest, 12) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentFullName == ReadBytes(instrumentId.rest, 350) IN IF ~instrumentFullName.ok THEN Fail ELSE
    LET instrumentClassification == ReadBytes(instrumentFullName.rest, 6) IN IF ~instrumentClassification.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(instrumentClassification.rest, 18) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET underlyingInstrumentCode == ReadBytes(priceMultiplier.rest, 12) IN IF ~underlyingInstrumentCode.ok THEN Fail ELSE
    LET underlyingIndexName == ReadBytes(underlyingInstrumentCode.rest, 25) IN IF ~underlyingIndexName.ok THEN Fail ELSE
    LET termOfTheUnderlyingIndex == ReadBytes(underlyingIndexName.rest, 7) IN IF ~termOfTheUnderlyingIndex.ok THEN Fail ELSE
    LET optionType == ReadBytes(termOfTheUnderlyingIndex.rest, 4) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 18) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(strikePrice.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET strikePriceNotation == ReadBytes(strikePriceCurrency.rest, 4) IN IF ~strikePriceNotation.ok THEN Fail ELSE
    LET optionExerciseStyle == ReadBytes(strikePriceNotation.rest, 4) IN IF ~optionExerciseStyle.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(optionExerciseStyle.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(maturityDate.rest, 8) IN IF ~expiryDate.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(expiryDate.rest, 4) IN IF ~deliveryType.ok THEN Fail ELSE
    Ok([ reportStatus                           |-> reportStatus.value,
         quoteType                              |-> quoteType.value,
         quoteId                                |-> quoteId.value,
         eventTime                              |-> eventTime.value,
         quoteLiquidity                         |-> quoteLiquidity.value,
         venueMic                               |-> venueMic.value,
         submittingEntityIdentificationCode     |-> submittingEntityIdentificationCode.value,
         priceNotation                          |-> priceNotation.value,
         price                                  |-> price.value,
         priceCurrency                          |-> priceCurrency.value,
         quantity                               |-> quantity.value,
         quantityCurrency                       |-> quantityCurrency.value,
         notationOfTheQuantityInMeasurementUnit |-> notationOfTheQuantityInMeasurementUnit.value,
         quantityInMeasurementUnit              |-> quantityInMeasurementUnit.value,
         notionalAmount                         |-> notionalAmount.value,
         notionalCurrency                       |-> notionalCurrency.value,
         instrumentIdType                       |-> instrumentIdType.value,
         instrumentId                           |-> instrumentId.value,
         instrumentFullName                     |-> instrumentFullName.value,
         instrumentClassification               |-> instrumentClassification.value,
         priceMultiplier                        |-> priceMultiplier.value,
         underlyingInstrumentCode               |-> underlyingInstrumentCode.value,
         underlyingIndexName                    |-> underlyingIndexName.value,
         termOfTheUnderlyingIndex               |-> termOfTheUnderlyingIndex.value,
         optionType                             |-> optionType.value,
         strikePrice                            |-> strikePrice.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         strikePriceNotation                    |-> strikePriceNotation.value,
         optionExerciseStyle                    |-> optionExerciseStyle.value,
         maturityDate                           |-> maturityDate.value,
         expiryDate                             |-> expiryDate.value,
         deliveryType                           |-> deliveryType.value ], deliveryType.rest)

ZeroApaPreTradeMessage ==
    [ reportStatus                           |-> [i \in 1 .. 4 |-> 0],
      quoteType                              |-> [i \in 1 .. 1 |-> 0],
      quoteId                                |-> [i \in 1 .. 52 |-> 0],
      eventTime                              |-> [i \in 1 .. 20 |-> 0],
      quoteLiquidity                         |-> [i \in 1 .. 1 |-> 0],
      venueMic                               |-> [i \in 1 .. 4 |-> 0],
      submittingEntityIdentificationCode     |-> [i \in 1 .. 20 |-> 0],
      priceNotation                          |-> [i \in 1 .. 4 |-> 0],
      price                                  |-> [i \in 1 .. 18 |-> 0],
      priceCurrency                          |-> [i \in 1 .. 3 |-> 0],
      quantity                               |-> [i \in 1 .. 18 |-> 0],
      quantityCurrency                       |-> [i \in 1 .. 3 |-> 0],
      notationOfTheQuantityInMeasurementUnit |-> [i \in 1 .. 25 |-> 0],
      quantityInMeasurementUnit              |-> [i \in 1 .. 18 |-> 0],
      notionalAmount                         |-> [i \in 1 .. 18 |-> 0],
      notionalCurrency                       |-> [i \in 1 .. 3 |-> 0],
      instrumentIdType                       |-> [i \in 1 .. 4 |-> 0],
      instrumentId                           |-> [i \in 1 .. 12 |-> 0],
      instrumentFullName                     |-> [i \in 1 .. 350 |-> 0],
      instrumentClassification               |-> [i \in 1 .. 6 |-> 0],
      priceMultiplier                        |-> [i \in 1 .. 18 |-> 0],
      underlyingInstrumentCode               |-> [i \in 1 .. 12 |-> 0],
      underlyingIndexName                    |-> [i \in 1 .. 25 |-> 0],
      termOfTheUnderlyingIndex               |-> [i \in 1 .. 7 |-> 0],
      optionType                             |-> [i \in 1 .. 4 |-> 0],
      strikePrice                            |-> [i \in 1 .. 18 |-> 0],
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      strikePriceNotation                    |-> [i \in 1 .. 4 |-> 0],
      optionExerciseStyle                    |-> [i \in 1 .. 4 |-> 0],
      maturityDate                           |-> [i \in 1 .. 8 |-> 0],
      expiryDate                             |-> [i \in 1 .. 8 |-> 0],
      deliveryType                           |-> [i \in 1 .. 4 |-> 0] ]

(* Apa Pre Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedApaPreTradeMessage ==
    { ZeroApaPreTradeMessage }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.reportStatus = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.quoteId = one] : one \in Sample(52) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.eventTime = one] : one \in Sample(20) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.quoteLiquidity = one] : one \in Sample(1) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.venueMic = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.submittingEntityIdentificationCode = one] : one \in Sample(20) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.price = one] : one \in Sample(18) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.priceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.quantity = one] : one \in Sample(18) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.quantityCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.notationOfTheQuantityInMeasurementUnit = one] : one \in Sample(25) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.quantityInMeasurementUnit = one] : one \in Sample(18) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.notionalAmount = one] : one \in Sample(18) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.instrumentIdType = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(12) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.instrumentFullName = one] : one \in Sample(350) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.instrumentClassification = one] : one \in Sample(6) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.priceMultiplier = one] : one \in Sample(18) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.underlyingInstrumentCode = one] : one \in Sample(12) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.underlyingIndexName = one] : one \in Sample(25) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.termOfTheUnderlyingIndex = one] : one \in Sample(7) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.optionType = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(18) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.strikePriceNotation = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.optionExerciseStyle = one] : one \in Sample(4) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.expiryDate = one] : one \in Sample(8) }
        \cup { [ZeroApaPreTradeMessage EXCEPT !.deliveryType = one] : one \in Sample(4) }

(***************************************************************************)
(* Message Text, selected by Message Category                              *)
(***************************************************************************)

ApaPostTradeMessageCode == 85  \* "U"
ApaPreTradeMessageCode == 86  \* "V"

MessageText ==
    [ tag : {ApaPostTradeMessageCode}, body : ApaPostTradeMessage ]
        \cup [ tag : {ApaPreTradeMessageCode}, body : ApaPreTradeMessage ]

EncodeMessageText(message) ==
    CASE message.tag = ApaPostTradeMessageCode -> EncodeApaPostTradeMessage(message.body)
      [] message.tag = ApaPreTradeMessageCode -> EncodeApaPreTradeMessage(message.body)

DecodeMessageText(tag, bytes) ==
    LET read ==
            CASE tag = ApaPostTradeMessageCode -> DecodeApaPostTradeMessage(bytes)
              [] tag = ApaPreTradeMessageCode -> DecodeApaPreTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageText == [tag |-> ApaPostTradeMessageCode, body |-> ZeroApaPostTradeMessage]

(* Each Message Text in turn, at the values the message it names is checked at *)
CheckedMessageText ==
    { [tag |-> ApaPostTradeMessageCode, body |-> one] : one \in CheckedApaPostTradeMessage }
        \cup { [tag |-> ApaPreTradeMessageCode, body |-> one] : one \in CheckedApaPreTradeMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ soh                   : Sample(1),
      vendorIdentifier      : Sample(2),
      messageSubcategory    : Sample(1),
      venueId               : Sample(4),
      messageSequenceNumber : Sample(7),
      publicationTimestamp  : Sample(20),
      messageText           : MessageText,
      etx                   : Sample(1),
      lrc                   : Sample(1) ]

EncodePacket(message) ==
    message.soh
        \o message.vendorIdentifier
        \o EncodeUIntBE(message.messageText.tag, 1)
        \o message.messageSubcategory
        \o message.venueId
        \o message.messageSequenceNumber
        \o message.publicationTimestamp
        \o EncodeMessageText(message.messageText)
        \o message.etx
        \o message.lrc

DecodePacket(bytes) ==
    LET soh == ReadBytes(bytes, 1) IN IF ~soh.ok THEN Fail ELSE
    LET vendorIdentifier == ReadBytes(soh.rest, 2) IN IF ~vendorIdentifier.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(vendorIdentifier.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET messageSubcategory == ReadBytes(messageCategory.rest, 1) IN IF ~messageSubcategory.ok THEN Fail ELSE
    LET venueId == ReadBytes(messageSubcategory.rest, 4) IN IF ~venueId.ok THEN Fail ELSE
    LET messageSequenceNumber == ReadBytes(venueId.rest, 7) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET publicationTimestamp == ReadBytes(messageSequenceNumber.rest, 20) IN IF ~publicationTimestamp.ok THEN Fail ELSE
    LET messageText == DecodeMessageText(messageCategory.value, publicationTimestamp.rest) IN IF ~messageText.ok THEN Fail ELSE
    LET etx == ReadBytes(messageText.rest, 1) IN IF ~etx.ok THEN Fail ELSE
    LET lrc == ReadBytes(etx.rest, 1) IN IF ~lrc.ok THEN Fail ELSE
    Ok([ soh                   |-> soh.value,
         vendorIdentifier      |-> vendorIdentifier.value,
         messageSubcategory    |-> messageSubcategory.value,
         venueId               |-> venueId.value,
         messageSequenceNumber |-> messageSequenceNumber.value,
         publicationTimestamp  |-> publicationTimestamp.value,
         messageText           |-> messageText.value,
         etx                   |-> etx.value,
         lrc                   |-> lrc.value ], lrc.rest)

ZeroPacket ==
    [ soh                   |-> [i \in 1 .. 1 |-> 0],
      vendorIdentifier      |-> [i \in 1 .. 2 |-> 0],
      messageSubcategory    |-> [i \in 1 .. 1 |-> 0],
      venueId               |-> [i \in 1 .. 4 |-> 0],
      messageSequenceNumber |-> [i \in 1 .. 7 |-> 0],
      publicationTimestamp  |-> [i \in 1 .. 20 |-> 0],
      messageText           |-> ZeroMessageText,
      etx                   |-> [i \in 1 .. 1 |-> 0],
      lrc                   |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.soh = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.vendorIdentifier = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.messageSubcategory = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.venueId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.messageSequenceNumber = one] : one \in Sample(7) }
        \cup { [ZeroPacket EXCEPT !.publicationTimestamp = one] : one \in Sample(20) }
        \cup { [ZeroPacket EXCEPT !.messageText = one] : one \in CheckedMessageText }
        \cup { [ZeroPacket EXCEPT !.etx = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.lrc = one] : one \in Sample(1) }

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

(* Every Apa Post Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApaPostTradeMessage ==
    \A message \in CheckedApaPostTradeMessage :
        LET read == DecodeApaPostTradeMessage(EncodeApaPostTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Apa Pre Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApaPreTradeMessage ==
    \A message \in CheckedApaPreTradeMessage :
        LET read == DecodeApaPreTradeMessage(EncodeApaPreTradeMessage(message))
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

(* A Message Text is selected by the Message Category it is written under *)
SelectsMessageText ==
    \A message \in CheckedMessageText :
        LET read == DecodeMessageText(message.tag, EncodeMessageText(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
