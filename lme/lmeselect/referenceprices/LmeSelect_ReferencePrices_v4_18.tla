------------------ MODULE LmeSelect_ReferencePrices_v4_18 ------------------
(***************************************************************************)
(* The London Metal Exchange LMEsource ReferencePrices v4.18               *)
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
(* Reference Price Message: 94 bytes                                       *)
(***************************************************************************)

ReferencePriceMessage ==
    [ timeOfEvent            : Sample(8),
      referencePriceCategory : Sample(1),
      referencePriceType     : Sample(32),
      priceStatus            : Sample(12),
      businessDate           : Sample(4),
      instrumentId           : Sample(8),
      productCode            : Sample(2),
      currencyCode           : Sample(3),
      bid                    : Sample(8),
      price                  : Sample(8),
      ask                    : Sample(8) ]

EncodeReferencePriceMessage(message) ==
    message.timeOfEvent
        \o message.referencePriceCategory
        \o message.referencePriceType
        \o message.priceStatus
        \o message.businessDate
        \o message.instrumentId
        \o message.productCode
        \o message.currencyCode
        \o message.bid
        \o message.price
        \o message.ask

DecodeReferencePriceMessage(bytes) ==
    LET timeOfEvent == ReadBytes(bytes, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET referencePriceCategory == ReadBytes(timeOfEvent.rest, 1) IN IF ~referencePriceCategory.ok THEN Fail ELSE
    LET referencePriceType == ReadBytes(referencePriceCategory.rest, 32) IN IF ~referencePriceType.ok THEN Fail ELSE
    LET priceStatus == ReadBytes(referencePriceType.rest, 12) IN IF ~priceStatus.ok THEN Fail ELSE
    LET businessDate == ReadBytes(priceStatus.rest, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(businessDate.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET productCode == ReadBytes(instrumentId.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(productCode.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET bid == ReadBytes(currencyCode.rest, 8) IN IF ~bid.ok THEN Fail ELSE
    LET price == ReadBytes(bid.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ask == ReadBytes(price.rest, 8) IN IF ~ask.ok THEN Fail ELSE
    Ok([ timeOfEvent            |-> timeOfEvent.value,
         referencePriceCategory |-> referencePriceCategory.value,
         referencePriceType     |-> referencePriceType.value,
         priceStatus            |-> priceStatus.value,
         businessDate           |-> businessDate.value,
         instrumentId           |-> instrumentId.value,
         productCode            |-> productCode.value,
         currencyCode           |-> currencyCode.value,
         bid                    |-> bid.value,
         price                  |-> price.value,
         ask                    |-> ask.value ], ask.rest)

ZeroReferencePriceMessage ==
    [ timeOfEvent            |-> [i \in 1 .. 8 |-> 0],
      referencePriceCategory |-> [i \in 1 .. 1 |-> 0],
      referencePriceType     |-> [i \in 1 .. 32 |-> 0],
      priceStatus            |-> [i \in 1 .. 12 |-> 0],
      businessDate           |-> [i \in 1 .. 4 |-> 0],
      instrumentId           |-> [i \in 1 .. 8 |-> 0],
      productCode            |-> [i \in 1 .. 2 |-> 0],
      currencyCode           |-> [i \in 1 .. 3 |-> 0],
      bid                    |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ask                    |-> [i \in 1 .. 8 |-> 0] ]

(* Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceMessage ==
    { ZeroReferencePriceMessage }
        \cup { [ZeroReferencePriceMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.referencePriceCategory = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.referencePriceType = one] : one \in Sample(32) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.priceStatus = one] : one \in Sample(12) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.bid = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.ask = one] : one \in Sample(8) }

(***************************************************************************)
(* Curve Prices: 28 bytes                                                  *)
(***************************************************************************)

CurvePrices ==
    [ price            : Sample(8),
      promptDate1      : Sample(4),
      promptDateLabel1 : Sample(6),
      promptDate2      : Sample(4),
      promptDateLabel2 : Sample(6) ]

EncodeCurvePrices(message) ==
    message.price
        \o message.promptDate1
        \o message.promptDateLabel1
        \o message.promptDate2
        \o message.promptDateLabel2

DecodeCurvePrices(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET promptDate1 == ReadBytes(price.rest, 4) IN IF ~promptDate1.ok THEN Fail ELSE
    LET promptDateLabel1 == ReadBytes(promptDate1.rest, 6) IN IF ~promptDateLabel1.ok THEN Fail ELSE
    LET promptDate2 == ReadBytes(promptDateLabel1.rest, 4) IN IF ~promptDate2.ok THEN Fail ELSE
    LET promptDateLabel2 == ReadBytes(promptDate2.rest, 6) IN IF ~promptDateLabel2.ok THEN Fail ELSE
    Ok([ price            |-> price.value,
         promptDate1      |-> promptDate1.value,
         promptDateLabel1 |-> promptDateLabel1.value,
         promptDate2      |-> promptDate2.value,
         promptDateLabel2 |-> promptDateLabel2.value ], promptDateLabel2.rest)

ZeroCurvePrices ==
    [ price            |-> [i \in 1 .. 8 |-> 0],
      promptDate1      |-> [i \in 1 .. 4 |-> 0],
      promptDateLabel1 |-> [i \in 1 .. 6 |-> 0],
      promptDate2      |-> [i \in 1 .. 4 |-> 0],
      promptDateLabel2 |-> [i \in 1 .. 6 |-> 0] ]

(* Curve Prices at zero, then each field in turn at the values it is checked at *)
CheckedCurvePrices ==
    { ZeroCurvePrices }
        \cup { [ZeroCurvePrices EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCurvePrices EXCEPT !.promptDate1 = one] : one \in Sample(4) }
        \cup { [ZeroCurvePrices EXCEPT !.promptDateLabel1 = one] : one \in Sample(6) }
        \cup { [ZeroCurvePrices EXCEPT !.promptDate2 = one] : one \in Sample(4) }
        \cup { [ZeroCurvePrices EXCEPT !.promptDateLabel2 = one] : one \in Sample(6) }

(* A run of Curve Prices, written one after another *)
RECURSIVE EncodeCurvePricesList(_)
EncodeCurvePricesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCurvePrices(Head(messages)) \o EncodeCurvePricesList(Tail(messages))

(* As many Curve Prices as the field that counts them says *)
RECURSIVE ReadCurvePricesList(_, _)
ReadCurvePricesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCurvePrices(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCurvePricesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Curve Prices of each kind, for the lists that carry them *)
OneCurvePrices == { ZeroCurvePrices }

(***************************************************************************)
(* Reference Forward Curve Price Message                                   *)
(***************************************************************************)

ReferenceForwardCurvePriceMessage ==
    [ timeOfEvent      : Sample(8),
      businessDate     : Sample(4),
      productCode      : Sample(2),
      priceStatus      : Sample(12),
      currencyCode     : Sample(3),
      remainingRecords : Sample(2),
      curvePrices      : SampleLists(OneCurvePrices) ]

EncodeReferenceForwardCurvePriceMessage(message) ==
    message.timeOfEvent
        \o message.businessDate
        \o message.productCode
        \o message.priceStatus
        \o message.currencyCode
        \o message.remainingRecords
        \o EncodeUIntLE(Len(message.curvePrices), 2)
        \o EncodeCurvePricesList(message.curvePrices)

DecodeReferenceForwardCurvePriceMessage(bytes) ==
    LET timeOfEvent == ReadBytes(bytes, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET businessDate == ReadBytes(timeOfEvent.rest, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET productCode == ReadBytes(businessDate.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET priceStatus == ReadBytes(productCode.rest, 12) IN IF ~priceStatus.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(priceStatus.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET remainingRecords == ReadBytes(currencyCode.rest, 2) IN IF ~remainingRecords.ok THEN Fail ELSE
    LET recordCount == ReadUIntLE(remainingRecords.rest, 2) IN IF ~recordCount.ok THEN Fail ELSE
    LET curvePrices == ReadCurvePricesList(recordCount.rest, recordCount.value) IN IF ~curvePrices.ok THEN Fail ELSE
    Ok([ timeOfEvent      |-> timeOfEvent.value,
         businessDate     |-> businessDate.value,
         productCode      |-> productCode.value,
         priceStatus      |-> priceStatus.value,
         currencyCode     |-> currencyCode.value,
         remainingRecords |-> remainingRecords.value,
         curvePrices      |-> curvePrices.value ], curvePrices.rest)

ZeroReferenceForwardCurvePriceMessage ==
    [ timeOfEvent      |-> [i \in 1 .. 8 |-> 0],
      businessDate     |-> [i \in 1 .. 4 |-> 0],
      productCode      |-> [i \in 1 .. 2 |-> 0],
      priceStatus      |-> [i \in 1 .. 12 |-> 0],
      currencyCode     |-> [i \in 1 .. 3 |-> 0],
      remainingRecords |-> [i \in 1 .. 2 |-> 0],
      curvePrices      |-> << >> ]

(* Reference Forward Curve Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferenceForwardCurvePriceMessage ==
    { ZeroReferenceForwardCurvePriceMessage }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.priceStatus = one] : one \in Sample(12) }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.remainingRecords = one] : one \in Sample(2) }
        \cup { [ZeroReferenceForwardCurvePriceMessage EXCEPT !.curvePrices = one] : one \in SampleLists(OneCurvePrices) }

(***************************************************************************)
(* Reference Fx Rate Message: 25 bytes                                     *)
(***************************************************************************)

ReferenceFxRateMessage ==
    [ fxRateCategory     : Sample(1),
      fxRateType         : Sample(2),
      businessDate       : Sample(4),
      maturityDate       : Sample(4),
      baseCurrencyCode   : Sample(3),
      targetCurrencyCode : Sample(3),
      conversionRate     : Sample(8) ]

EncodeReferenceFxRateMessage(message) ==
    message.fxRateCategory
        \o message.fxRateType
        \o message.businessDate
        \o message.maturityDate
        \o message.baseCurrencyCode
        \o message.targetCurrencyCode
        \o message.conversionRate

DecodeReferenceFxRateMessage(bytes) ==
    LET fxRateCategory == ReadBytes(bytes, 1) IN IF ~fxRateCategory.ok THEN Fail ELSE
    LET fxRateType == ReadBytes(fxRateCategory.rest, 2) IN IF ~fxRateType.ok THEN Fail ELSE
    LET businessDate == ReadBytes(fxRateType.rest, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(businessDate.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET baseCurrencyCode == ReadBytes(maturityDate.rest, 3) IN IF ~baseCurrencyCode.ok THEN Fail ELSE
    LET targetCurrencyCode == ReadBytes(baseCurrencyCode.rest, 3) IN IF ~targetCurrencyCode.ok THEN Fail ELSE
    LET conversionRate == ReadBytes(targetCurrencyCode.rest, 8) IN IF ~conversionRate.ok THEN Fail ELSE
    Ok([ fxRateCategory     |-> fxRateCategory.value,
         fxRateType         |-> fxRateType.value,
         businessDate       |-> businessDate.value,
         maturityDate       |-> maturityDate.value,
         baseCurrencyCode   |-> baseCurrencyCode.value,
         targetCurrencyCode |-> targetCurrencyCode.value,
         conversionRate     |-> conversionRate.value ], conversionRate.rest)

ZeroReferenceFxRateMessage ==
    [ fxRateCategory     |-> [i \in 1 .. 1 |-> 0],
      fxRateType         |-> [i \in 1 .. 2 |-> 0],
      businessDate       |-> [i \in 1 .. 4 |-> 0],
      maturityDate       |-> [i \in 1 .. 4 |-> 0],
      baseCurrencyCode   |-> [i \in 1 .. 3 |-> 0],
      targetCurrencyCode |-> [i \in 1 .. 3 |-> 0],
      conversionRate     |-> [i \in 1 .. 8 |-> 0] ]

(* Reference Fx Rate Message at zero, then each field in turn at the values it is checked at *)
CheckedReferenceFxRateMessage ==
    { ZeroReferenceFxRateMessage }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.fxRateCategory = one] : one \in Sample(1) }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.fxRateType = one] : one \in Sample(2) }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.baseCurrencyCode = one] : one \in Sample(3) }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.targetCurrencyCode = one] : one \in Sample(3) }
        \cup { [ZeroReferenceFxRateMessage EXCEPT !.conversionRate = one] : one \in Sample(8) }

(***************************************************************************)
(* Volatility Points: 50 bytes                                             *)
(***************************************************************************)

VolatilityPoints ==
    [ surfaceDomain  : Sample(1),
      delta          : Sample(8),
      strikePrice    : Sample(8),
      atm            : Sample(1),
      callVolatility : Sample(8),
      putVolatility  : Sample(8),
      callPremium    : Sample(8),
      putPremium     : Sample(8) ]

EncodeVolatilityPoints(message) ==
    message.surfaceDomain
        \o message.delta
        \o message.strikePrice
        \o message.atm
        \o message.callVolatility
        \o message.putVolatility
        \o message.callPremium
        \o message.putPremium

DecodeVolatilityPoints(bytes) ==
    LET surfaceDomain == ReadBytes(bytes, 1) IN IF ~surfaceDomain.ok THEN Fail ELSE
    LET delta == ReadBytes(surfaceDomain.rest, 8) IN IF ~delta.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(delta.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET atm == ReadBytes(strikePrice.rest, 1) IN IF ~atm.ok THEN Fail ELSE
    LET callVolatility == ReadBytes(atm.rest, 8) IN IF ~callVolatility.ok THEN Fail ELSE
    LET putVolatility == ReadBytes(callVolatility.rest, 8) IN IF ~putVolatility.ok THEN Fail ELSE
    LET callPremium == ReadBytes(putVolatility.rest, 8) IN IF ~callPremium.ok THEN Fail ELSE
    LET putPremium == ReadBytes(callPremium.rest, 8) IN IF ~putPremium.ok THEN Fail ELSE
    Ok([ surfaceDomain  |-> surfaceDomain.value,
         delta          |-> delta.value,
         strikePrice    |-> strikePrice.value,
         atm            |-> atm.value,
         callVolatility |-> callVolatility.value,
         putVolatility  |-> putVolatility.value,
         callPremium    |-> callPremium.value,
         putPremium     |-> putPremium.value ], putPremium.rest)

ZeroVolatilityPoints ==
    [ surfaceDomain  |-> [i \in 1 .. 1 |-> 0],
      delta          |-> [i \in 1 .. 8 |-> 0],
      strikePrice    |-> [i \in 1 .. 8 |-> 0],
      atm            |-> [i \in 1 .. 1 |-> 0],
      callVolatility |-> [i \in 1 .. 8 |-> 0],
      putVolatility  |-> [i \in 1 .. 8 |-> 0],
      callPremium    |-> [i \in 1 .. 8 |-> 0],
      putPremium     |-> [i \in 1 .. 8 |-> 0] ]

(* Volatility Points at zero, then each field in turn at the values it is checked at *)
CheckedVolatilityPoints ==
    { ZeroVolatilityPoints }
        \cup { [ZeroVolatilityPoints EXCEPT !.surfaceDomain = one] : one \in Sample(1) }
        \cup { [ZeroVolatilityPoints EXCEPT !.delta = one] : one \in Sample(8) }
        \cup { [ZeroVolatilityPoints EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroVolatilityPoints EXCEPT !.atm = one] : one \in Sample(1) }
        \cup { [ZeroVolatilityPoints EXCEPT !.callVolatility = one] : one \in Sample(8) }
        \cup { [ZeroVolatilityPoints EXCEPT !.putVolatility = one] : one \in Sample(8) }
        \cup { [ZeroVolatilityPoints EXCEPT !.callPremium = one] : one \in Sample(8) }
        \cup { [ZeroVolatilityPoints EXCEPT !.putPremium = one] : one \in Sample(8) }

(* A run of Volatility Points, written one after another *)
RECURSIVE EncodeVolatilityPointsList(_)
EncodeVolatilityPointsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeVolatilityPoints(Head(messages)) \o EncodeVolatilityPointsList(Tail(messages))

(* As many Volatility Points as the field that counts them says *)
RECURSIVE ReadVolatilityPointsList(_, _)
ReadVolatilityPointsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeVolatilityPoints(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadVolatilityPointsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Volatility Points of each kind, for the lists that carry them *)
OneVolatilityPoints == { ZeroVolatilityPoints }

(***************************************************************************)
(* Reference Volatility Price Message                                      *)
(***************************************************************************)

ReferenceVolatilityPriceMessage ==
    [ timeOfEvent      : Sample(8),
      businessDate     : Sample(4),
      contractCode     : Sample(12),
      expiryDate       : Sample(4),
      remainingRecords : Sample(2),
      volatilityPoints : SampleLists(OneVolatilityPoints) ]

EncodeReferenceVolatilityPriceMessage(message) ==
    message.timeOfEvent
        \o message.businessDate
        \o message.contractCode
        \o message.expiryDate
        \o message.remainingRecords
        \o EncodeUIntLE(Len(message.volatilityPoints), 2)
        \o EncodeVolatilityPointsList(message.volatilityPoints)

DecodeReferenceVolatilityPriceMessage(bytes) ==
    LET timeOfEvent == ReadBytes(bytes, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET businessDate == ReadBytes(timeOfEvent.rest, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET contractCode == ReadBytes(businessDate.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(contractCode.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET remainingRecords == ReadBytes(expiryDate.rest, 2) IN IF ~remainingRecords.ok THEN Fail ELSE
    LET recordCount == ReadUIntLE(remainingRecords.rest, 2) IN IF ~recordCount.ok THEN Fail ELSE
    LET volatilityPoints == ReadVolatilityPointsList(recordCount.rest, recordCount.value) IN IF ~volatilityPoints.ok THEN Fail ELSE
    Ok([ timeOfEvent      |-> timeOfEvent.value,
         businessDate     |-> businessDate.value,
         contractCode     |-> contractCode.value,
         expiryDate       |-> expiryDate.value,
         remainingRecords |-> remainingRecords.value,
         volatilityPoints |-> volatilityPoints.value ], volatilityPoints.rest)

ZeroReferenceVolatilityPriceMessage ==
    [ timeOfEvent      |-> [i \in 1 .. 8 |-> 0],
      businessDate     |-> [i \in 1 .. 4 |-> 0],
      contractCode     |-> [i \in 1 .. 12 |-> 0],
      expiryDate       |-> [i \in 1 .. 4 |-> 0],
      remainingRecords |-> [i \in 1 .. 2 |-> 0],
      volatilityPoints |-> << >> ]

(* Reference Volatility Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferenceVolatilityPriceMessage ==
    { ZeroReferenceVolatilityPriceMessage }
        \cup { [ZeroReferenceVolatilityPriceMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroReferenceVolatilityPriceMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroReferenceVolatilityPriceMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroReferenceVolatilityPriceMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroReferenceVolatilityPriceMessage EXCEPT !.remainingRecords = one] : one \in Sample(2) }
        \cup { [ZeroReferenceVolatilityPriceMessage EXCEPT !.volatilityPoints = one] : one \in SampleLists(OneVolatilityPoints) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
ReferencePriceMessageCode == 401  \* 0x191
ReferenceForwardCurvePriceMessageCode == 402  \* 0x192
ReferenceFxRateMessageCode == 403  \* 0x193
ReferenceVolatilityPriceMessageCode == 404  \* 0x194

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {ReferencePriceMessageCode}, body : ReferencePriceMessage ]
        \cup [ tag : {ReferenceForwardCurvePriceMessageCode}, body : ReferenceForwardCurvePriceMessage ]
        \cup [ tag : {ReferenceFxRateMessageCode}, body : ReferenceFxRateMessage ]
        \cup [ tag : {ReferenceVolatilityPriceMessageCode}, body : ReferenceVolatilityPriceMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = ReferencePriceMessageCode -> EncodeReferencePriceMessage(message.body)
      [] message.tag = ReferenceForwardCurvePriceMessageCode -> EncodeReferenceForwardCurvePriceMessage(message.body)
      [] message.tag = ReferenceFxRateMessageCode -> EncodeReferenceFxRateMessage(message.body)
      [] message.tag = ReferenceVolatilityPriceMessageCode -> EncodeReferenceVolatilityPriceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = ReferencePriceMessageCode -> DecodeReferencePriceMessage(bytes)
              [] tag = ReferenceForwardCurvePriceMessageCode -> DecodeReferenceForwardCurvePriceMessage(bytes)
              [] tag = ReferenceFxRateMessageCode -> DecodeReferenceFxRateMessage(bytes)
              [] tag = ReferenceVolatilityPriceMessageCode -> DecodeReferenceVolatilityPriceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> ReferencePriceMessageCode, body |-> one] : one \in CheckedReferencePriceMessage }
        \cup { [tag |-> ReferenceForwardCurvePriceMessageCode, body |-> one] : one \in CheckedReferenceForwardCurvePriceMessage }
        \cup { [tag |-> ReferenceFxRateMessageCode, body |-> one] : one \in CheckedReferenceFxRateMessage }
        \cup { [tag |-> ReferenceVolatilityPriceMessageCode, body |-> one] : one \in CheckedReferenceVolatilityPriceMessage }

(***************************************************************************)
(* Messages                                                                *)
(***************************************************************************)

Messages ==
    [ msgSize : 0 .. 255,
      payload : Payload ]

EncodeMessages(message) ==
    EncodeUIntLE(message.msgSize, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

DecodeMessages(bytes) ==
    LET msgSize == ReadUIntLE(bytes, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgType == ReadUIntLE(msgSize.rest, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSize |-> msgSize.value,
         payload |-> payload.value ], payload.rest)

ZeroMessages ==
    [ msgSize |-> 0,
      payload |-> ZeroPayload ]

(* Messages at zero, then each field in turn at the values it is checked at *)
CheckedMessages ==
    { ZeroMessages }
        \cup { [ZeroMessages EXCEPT !.msgSize = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessages EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Messages, written one after another *)
RECURSIVE EncodeMessagesList(_)
EncodeMessagesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessages(Head(messages)) \o EncodeMessagesList(Tail(messages))

(* As many Messages as the field that counts them says *)
RECURSIVE ReadMessagesList(_, _)
ReadMessagesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessages(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessagesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Messages of each kind, for the lists that carry them *)
OneMessages ==
    { [ZeroMessages EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> ReferencePriceMessageCode, body |-> ZeroReferencePriceMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> ReferenceForwardCurvePriceMessageCode, body |-> ZeroReferenceForwardCurvePriceMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> ReferenceFxRateMessageCode, body |-> ZeroReferenceFxRateMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> ReferenceVolatilityPriceMessageCode, body |-> ZeroReferenceVolatilityPriceMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      messages : SampleLists(OneMessages) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.messages), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessagesList(message.messages)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET messages == ReadMessagesList(sendTime.rest, msgCount.value) IN IF ~messages.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         messages |-> messages.value ], messages.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      messages |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messages = one] : one \in SampleLists(OneMessages) }

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

(* Every Reference Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceMessage ==
    \A message \in CheckedReferencePriceMessage :
        LET read == DecodeReferencePriceMessage(EncodeReferencePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Curve Prices decodes back to what was encoded, and leaves nothing over *)
RoundTripCurvePrices ==
    \A message \in CheckedCurvePrices :
        LET read == DecodeCurvePrices(EncodeCurvePrices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Forward Curve Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferenceForwardCurvePriceMessage ==
    \A message \in CheckedReferenceForwardCurvePriceMessage :
        LET read == DecodeReferenceForwardCurvePriceMessage(EncodeReferenceForwardCurvePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Fx Rate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferenceFxRateMessage ==
    \A message \in CheckedReferenceFxRateMessage :
        LET read == DecodeReferenceFxRateMessage(EncodeReferenceFxRateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Volatility Points decodes back to what was encoded, and leaves nothing over *)
RoundTripVolatilityPoints ==
    \A message \in CheckedVolatilityPoints :
        LET read == DecodeVolatilityPoints(EncodeVolatilityPoints(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Volatility Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferenceVolatilityPriceMessage ==
    \A message \in CheckedReferenceVolatilityPriceMessage :
        LET read == DecodeReferenceVolatilityPriceMessage(EncodeReferenceVolatilityPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Messages decodes back to what was encoded, and leaves nothing over *)
RoundTripMessages ==
    \A message \in CheckedMessages :
        LET read == DecodeMessages(EncodeMessages(message))
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
