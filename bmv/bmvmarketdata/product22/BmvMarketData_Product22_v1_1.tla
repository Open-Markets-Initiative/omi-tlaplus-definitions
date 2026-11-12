------------------- MODULE BmvMarketData_Product22_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 22 v1.1               *)
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
(* License: MIT No Attribution                                             *)
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
(* Events System Message: 22 bytes                                         *)
(***************************************************************************)

EventsSystemMessage ==
    [ instrumentNumber : Sample(4),
      eventCode        : Sample(1),
      market           : Sample(1),
      sendingTime      : Sample(8),
      endingTime       : Sample(8) ]

EncodeEventsSystemMessage(message) ==
    message.instrumentNumber
        \o message.eventCode
        \o message.market
        \o message.sendingTime
        \o message.endingTime

DecodeEventsSystemMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET eventCode == ReadBytes(instrumentNumber.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET market == ReadBytes(eventCode.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(market.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET endingTime == ReadBytes(sendingTime.rest, 8) IN IF ~endingTime.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         eventCode        |-> eventCode.value,
         market           |-> market.value,
         sendingTime      |-> sendingTime.value,
         endingTime       |-> endingTime.value ], endingTime.rest)

ZeroEventsSystemMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      eventCode        |-> [i \in 1 .. 1 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sendingTime      |-> [i \in 1 .. 8 |-> 0],
      endingTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Events System Message at zero, then each field in turn at the values it is checked at *)
CheckedEventsSystemMessage ==
    { ZeroEventsSystemMessage }
        \cup { [ZeroEventsSystemMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.endingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Dollar Buy Sell Message: 38 bytes                                       *)
(***************************************************************************)

DollarBuySellMessage ==
    [ postureDate : Sample(8),
      currency    : Sample(5),
      dollarSide  : Sample(1),
      buy         : Sample(8),
      sell        : Sample(8),
      lastDeal    : Sample(8) ]

EncodeDollarBuySellMessage(message) ==
    message.postureDate
        \o message.currency
        \o message.dollarSide
        \o message.buy
        \o message.sell
        \o message.lastDeal

DecodeDollarBuySellMessage(bytes) ==
    LET postureDate == ReadBytes(bytes, 8) IN IF ~postureDate.ok THEN Fail ELSE
    LET currency == ReadBytes(postureDate.rest, 5) IN IF ~currency.ok THEN Fail ELSE
    LET dollarSide == ReadBytes(currency.rest, 1) IN IF ~dollarSide.ok THEN Fail ELSE
    LET buy == ReadBytes(dollarSide.rest, 8) IN IF ~buy.ok THEN Fail ELSE
    LET sell == ReadBytes(buy.rest, 8) IN IF ~sell.ok THEN Fail ELSE
    LET lastDeal == ReadBytes(sell.rest, 8) IN IF ~lastDeal.ok THEN Fail ELSE
    Ok([ postureDate |-> postureDate.value,
         currency    |-> currency.value,
         dollarSide  |-> dollarSide.value,
         buy         |-> buy.value,
         sell        |-> sell.value,
         lastDeal    |-> lastDeal.value ], lastDeal.rest)

ZeroDollarBuySellMessage ==
    [ postureDate |-> [i \in 1 .. 8 |-> 0],
      currency    |-> [i \in 1 .. 5 |-> 0],
      dollarSide  |-> [i \in 1 .. 1 |-> 0],
      buy         |-> [i \in 1 .. 8 |-> 0],
      sell        |-> [i \in 1 .. 8 |-> 0],
      lastDeal    |-> [i \in 1 .. 8 |-> 0] ]

(* Dollar Buy Sell Message at zero, then each field in turn at the values it is checked at *)
CheckedDollarBuySellMessage ==
    { ZeroDollarBuySellMessage }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.postureDate = one] : one \in Sample(8) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.currency = one] : one \in Sample(5) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.dollarSide = one] : one \in Sample(1) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.buy = one] : one \in Sample(8) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.sell = one] : one \in Sample(8) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.lastDeal = one] : one \in Sample(8) }

(***************************************************************************)
(* Short Sales Balances Per Instrument Message: 44 bytes                   *)
(***************************************************************************)

ShortSalesBalancesPerInstrumentMessage ==
    [ instrumentNumber : Sample(4),
      date             : Sample(8),
      previousBalance  : Sample(8),
      amountTraded     : Sample(8),
      buybacks         : Sample(8),
      currentBalance   : Sample(8) ]

EncodeShortSalesBalancesPerInstrumentMessage(message) ==
    message.instrumentNumber
        \o message.date
        \o message.previousBalance
        \o message.amountTraded
        \o message.buybacks
        \o message.currentBalance

DecodeShortSalesBalancesPerInstrumentMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET date == ReadBytes(instrumentNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET previousBalance == ReadBytes(date.rest, 8) IN IF ~previousBalance.ok THEN Fail ELSE
    LET amountTraded == ReadBytes(previousBalance.rest, 8) IN IF ~amountTraded.ok THEN Fail ELSE
    LET buybacks == ReadBytes(amountTraded.rest, 8) IN IF ~buybacks.ok THEN Fail ELSE
    LET currentBalance == ReadBytes(buybacks.rest, 8) IN IF ~currentBalance.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         date             |-> date.value,
         previousBalance  |-> previousBalance.value,
         amountTraded     |-> amountTraded.value,
         buybacks         |-> buybacks.value,
         currentBalance   |-> currentBalance.value ], currentBalance.rest)

ZeroShortSalesBalancesPerInstrumentMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      date             |-> [i \in 1 .. 8 |-> 0],
      previousBalance  |-> [i \in 1 .. 8 |-> 0],
      amountTraded     |-> [i \in 1 .. 8 |-> 0],
      buybacks         |-> [i \in 1 .. 8 |-> 0],
      currentBalance   |-> [i \in 1 .. 8 |-> 0] ]

(* Short Sales Balances Per Instrument Message at zero, then each field in turn at the values it is checked at *)
CheckedShortSalesBalancesPerInstrumentMessage ==
    { ZeroShortSalesBalancesPerInstrumentMessage }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.previousBalance = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.amountTraded = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.buybacks = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.currentBalance = one] : one \in Sample(8) }

(***************************************************************************)
(* Capital Market Multiples Message: 130 bytes                             *)
(***************************************************************************)

CapitalMarketMultiplesMessage ==
    [ instrumentId     : Sample(4),
      multipleType     : Sample(1),
      registryNumber   : Sample(1),
      sector           : Sample(1),
      subsector        : Sample(1),
      businessLine     : Sample(1),
      subLine          : Sample(1),
      pflepaMultiple   : Sample(8),
      pfepaMultiple    : Sample(8),
      veUaiidaMultiple : Sample(8),
      pU               : Sample(8),
      pVl              : Sample(8),
      f1PUnoc          : Sample(8),
      f2PUnoc          : Sample(8),
      f1PUe            : Sample(8),
      f2PUe            : Sample(8),
      f1VeUaiida       : Sample(8),
      f2VeUaiida       : Sample(8),
      f1PU             : Sample(8),
      f2PU             : Sample(8),
      f1PVl            : Sample(8),
      f2PVl            : Sample(8) ]

EncodeCapitalMarketMultiplesMessage(message) ==
    message.instrumentId
        \o message.multipleType
        \o message.registryNumber
        \o message.sector
        \o message.subsector
        \o message.businessLine
        \o message.subLine
        \o message.pflepaMultiple
        \o message.pfepaMultiple
        \o message.veUaiidaMultiple
        \o message.pU
        \o message.pVl
        \o message.f1PUnoc
        \o message.f2PUnoc
        \o message.f1PUe
        \o message.f2PUe
        \o message.f1VeUaiida
        \o message.f2VeUaiida
        \o message.f1PU
        \o message.f2PU
        \o message.f1PVl
        \o message.f2PVl

DecodeCapitalMarketMultiplesMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET multipleType == ReadBytes(instrumentId.rest, 1) IN IF ~multipleType.ok THEN Fail ELSE
    LET registryNumber == ReadBytes(multipleType.rest, 1) IN IF ~registryNumber.ok THEN Fail ELSE
    LET sector == ReadBytes(registryNumber.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET subsector == ReadBytes(sector.rest, 1) IN IF ~subsector.ok THEN Fail ELSE
    LET businessLine == ReadBytes(subsector.rest, 1) IN IF ~businessLine.ok THEN Fail ELSE
    LET subLine == ReadBytes(businessLine.rest, 1) IN IF ~subLine.ok THEN Fail ELSE
    LET pflepaMultiple == ReadBytes(subLine.rest, 8) IN IF ~pflepaMultiple.ok THEN Fail ELSE
    LET pfepaMultiple == ReadBytes(pflepaMultiple.rest, 8) IN IF ~pfepaMultiple.ok THEN Fail ELSE
    LET veUaiidaMultiple == ReadBytes(pfepaMultiple.rest, 8) IN IF ~veUaiidaMultiple.ok THEN Fail ELSE
    LET pU == ReadBytes(veUaiidaMultiple.rest, 8) IN IF ~pU.ok THEN Fail ELSE
    LET pVl == ReadBytes(pU.rest, 8) IN IF ~pVl.ok THEN Fail ELSE
    LET f1PUnoc == ReadBytes(pVl.rest, 8) IN IF ~f1PUnoc.ok THEN Fail ELSE
    LET f2PUnoc == ReadBytes(f1PUnoc.rest, 8) IN IF ~f2PUnoc.ok THEN Fail ELSE
    LET f1PUe == ReadBytes(f2PUnoc.rest, 8) IN IF ~f1PUe.ok THEN Fail ELSE
    LET f2PUe == ReadBytes(f1PUe.rest, 8) IN IF ~f2PUe.ok THEN Fail ELSE
    LET f1VeUaiida == ReadBytes(f2PUe.rest, 8) IN IF ~f1VeUaiida.ok THEN Fail ELSE
    LET f2VeUaiida == ReadBytes(f1VeUaiida.rest, 8) IN IF ~f2VeUaiida.ok THEN Fail ELSE
    LET f1PU == ReadBytes(f2VeUaiida.rest, 8) IN IF ~f1PU.ok THEN Fail ELSE
    LET f2PU == ReadBytes(f1PU.rest, 8) IN IF ~f2PU.ok THEN Fail ELSE
    LET f1PVl == ReadBytes(f2PU.rest, 8) IN IF ~f1PVl.ok THEN Fail ELSE
    LET f2PVl == ReadBytes(f1PVl.rest, 8) IN IF ~f2PVl.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         multipleType     |-> multipleType.value,
         registryNumber   |-> registryNumber.value,
         sector           |-> sector.value,
         subsector        |-> subsector.value,
         businessLine     |-> businessLine.value,
         subLine          |-> subLine.value,
         pflepaMultiple   |-> pflepaMultiple.value,
         pfepaMultiple    |-> pfepaMultiple.value,
         veUaiidaMultiple |-> veUaiidaMultiple.value,
         pU               |-> pU.value,
         pVl              |-> pVl.value,
         f1PUnoc          |-> f1PUnoc.value,
         f2PUnoc          |-> f2PUnoc.value,
         f1PUe            |-> f1PUe.value,
         f2PUe            |-> f2PUe.value,
         f1VeUaiida       |-> f1VeUaiida.value,
         f2VeUaiida       |-> f2VeUaiida.value,
         f1PU             |-> f1PU.value,
         f2PU             |-> f2PU.value,
         f1PVl            |-> f1PVl.value,
         f2PVl            |-> f2PVl.value ], f2PVl.rest)

ZeroCapitalMarketMultiplesMessage ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      multipleType     |-> [i \in 1 .. 1 |-> 0],
      registryNumber   |-> [i \in 1 .. 1 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      subsector        |-> [i \in 1 .. 1 |-> 0],
      businessLine     |-> [i \in 1 .. 1 |-> 0],
      subLine          |-> [i \in 1 .. 1 |-> 0],
      pflepaMultiple   |-> [i \in 1 .. 8 |-> 0],
      pfepaMultiple    |-> [i \in 1 .. 8 |-> 0],
      veUaiidaMultiple |-> [i \in 1 .. 8 |-> 0],
      pU               |-> [i \in 1 .. 8 |-> 0],
      pVl              |-> [i \in 1 .. 8 |-> 0],
      f1PUnoc          |-> [i \in 1 .. 8 |-> 0],
      f2PUnoc          |-> [i \in 1 .. 8 |-> 0],
      f1PUe            |-> [i \in 1 .. 8 |-> 0],
      f2PUe            |-> [i \in 1 .. 8 |-> 0],
      f1VeUaiida       |-> [i \in 1 .. 8 |-> 0],
      f2VeUaiida       |-> [i \in 1 .. 8 |-> 0],
      f1PU             |-> [i \in 1 .. 8 |-> 0],
      f2PU             |-> [i \in 1 .. 8 |-> 0],
      f1PVl            |-> [i \in 1 .. 8 |-> 0],
      f2PVl            |-> [i \in 1 .. 8 |-> 0] ]

(* Capital Market Multiples Message at zero, then each field in turn at the values it is checked at *)
CheckedCapitalMarketMultiplesMessage ==
    { ZeroCapitalMarketMultiplesMessage }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.multipleType = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.registryNumber = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.subsector = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.businessLine = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.subLine = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pflepaMultiple = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pfepaMultiple = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.veUaiidaMultiple = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pU = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pVl = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PUnoc = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PUnoc = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PUe = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PUe = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1VeUaiida = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2VeUaiida = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PU = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PU = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PVl = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PVl = one] : one \in Sample(8) }

(***************************************************************************)
(* Capitalization Rules Message: 39 bytes                                  *)
(***************************************************************************)

CapitalizationRulesMessage ==
    [ instrumentNumber           : Sample(4),
      dateIndicators             : Sample(8),
      bursatilityIndices         : Sample(4),
      bursatilityIndicesSign     : Sample(1),
      betaCoefficient            : Sample(8),
      betaCoefficientSign        : Sample(1),
      correlationCoefficient     : Sample(8),
      correlationCoefficientSign : Sample(1),
      deltaDifference            : Sample(4) ]

EncodeCapitalizationRulesMessage(message) ==
    message.instrumentNumber
        \o message.dateIndicators
        \o message.bursatilityIndices
        \o message.bursatilityIndicesSign
        \o message.betaCoefficient
        \o message.betaCoefficientSign
        \o message.correlationCoefficient
        \o message.correlationCoefficientSign
        \o message.deltaDifference

DecodeCapitalizationRulesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET dateIndicators == ReadBytes(instrumentNumber.rest, 8) IN IF ~dateIndicators.ok THEN Fail ELSE
    LET bursatilityIndices == ReadBytes(dateIndicators.rest, 4) IN IF ~bursatilityIndices.ok THEN Fail ELSE
    LET bursatilityIndicesSign == ReadBytes(bursatilityIndices.rest, 1) IN IF ~bursatilityIndicesSign.ok THEN Fail ELSE
    LET betaCoefficient == ReadBytes(bursatilityIndicesSign.rest, 8) IN IF ~betaCoefficient.ok THEN Fail ELSE
    LET betaCoefficientSign == ReadBytes(betaCoefficient.rest, 1) IN IF ~betaCoefficientSign.ok THEN Fail ELSE
    LET correlationCoefficient == ReadBytes(betaCoefficientSign.rest, 8) IN IF ~correlationCoefficient.ok THEN Fail ELSE
    LET correlationCoefficientSign == ReadBytes(correlationCoefficient.rest, 1) IN IF ~correlationCoefficientSign.ok THEN Fail ELSE
    LET deltaDifference == ReadBytes(correlationCoefficientSign.rest, 4) IN IF ~deltaDifference.ok THEN Fail ELSE
    Ok([ instrumentNumber           |-> instrumentNumber.value,
         dateIndicators             |-> dateIndicators.value,
         bursatilityIndices         |-> bursatilityIndices.value,
         bursatilityIndicesSign     |-> bursatilityIndicesSign.value,
         betaCoefficient            |-> betaCoefficient.value,
         betaCoefficientSign        |-> betaCoefficientSign.value,
         correlationCoefficient     |-> correlationCoefficient.value,
         correlationCoefficientSign |-> correlationCoefficientSign.value,
         deltaDifference            |-> deltaDifference.value ], deltaDifference.rest)

ZeroCapitalizationRulesMessage ==
    [ instrumentNumber           |-> [i \in 1 .. 4 |-> 0],
      dateIndicators             |-> [i \in 1 .. 8 |-> 0],
      bursatilityIndices         |-> [i \in 1 .. 4 |-> 0],
      bursatilityIndicesSign     |-> [i \in 1 .. 1 |-> 0],
      betaCoefficient            |-> [i \in 1 .. 8 |-> 0],
      betaCoefficientSign        |-> [i \in 1 .. 1 |-> 0],
      correlationCoefficient     |-> [i \in 1 .. 8 |-> 0],
      correlationCoefficientSign |-> [i \in 1 .. 1 |-> 0],
      deltaDifference            |-> [i \in 1 .. 4 |-> 0] ]

(* Capitalization Rules Message at zero, then each field in turn at the values it is checked at *)
CheckedCapitalizationRulesMessage ==
    { ZeroCapitalizationRulesMessage }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.dateIndicators = one] : one \in Sample(8) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.bursatilityIndices = one] : one \in Sample(4) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.bursatilityIndicesSign = one] : one \in Sample(1) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.betaCoefficient = one] : one \in Sample(8) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.betaCoefficientSign = one] : one \in Sample(1) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.correlationCoefficient = one] : one \in Sample(8) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.correlationCoefficientSign = one] : one \in Sample(1) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.deltaDifference = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

EventsSystemMessageCode == 83  \* 0x53
DollarBuySellMessageCode == 114  \* 0x72
ShortSalesBalancesPerInstrumentMessageCode == 115  \* 0x73
CapitalMarketMultiplesMessageCode == 116  \* 0x74
CapitalizationRulesMessageCode == 122  \* 0x7a

Payload ==
    [ tag : {EventsSystemMessageCode}, body : EventsSystemMessage ]
        \cup [ tag : {DollarBuySellMessageCode}, body : DollarBuySellMessage ]
        \cup [ tag : {ShortSalesBalancesPerInstrumentMessageCode}, body : ShortSalesBalancesPerInstrumentMessage ]
        \cup [ tag : {CapitalMarketMultiplesMessageCode}, body : CapitalMarketMultiplesMessage ]
        \cup [ tag : {CapitalizationRulesMessageCode}, body : CapitalizationRulesMessage ]

EncodePayload(message) ==
    CASE message.tag = EventsSystemMessageCode -> EncodeEventsSystemMessage(message.body)
      [] message.tag = DollarBuySellMessageCode -> EncodeDollarBuySellMessage(message.body)
      [] message.tag = ShortSalesBalancesPerInstrumentMessageCode -> EncodeShortSalesBalancesPerInstrumentMessage(message.body)
      [] message.tag = CapitalMarketMultiplesMessageCode -> EncodeCapitalMarketMultiplesMessage(message.body)
      [] message.tag = CapitalizationRulesMessageCode -> EncodeCapitalizationRulesMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = EventsSystemMessageCode -> DecodeEventsSystemMessage(bytes)
              [] tag = DollarBuySellMessageCode -> DecodeDollarBuySellMessage(bytes)
              [] tag = ShortSalesBalancesPerInstrumentMessageCode -> DecodeShortSalesBalancesPerInstrumentMessage(bytes)
              [] tag = CapitalMarketMultiplesMessageCode -> DecodeCapitalMarketMultiplesMessage(bytes)
              [] tag = CapitalizationRulesMessageCode -> DecodeCapitalizationRulesMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> EventsSystemMessageCode, body |-> one] : one \in CheckedEventsSystemMessage }
        \cup { [tag |-> DollarBuySellMessageCode, body |-> one] : one \in CheckedDollarBuySellMessage }
        \cup { [tag |-> ShortSalesBalancesPerInstrumentMessageCode, body |-> one] : one \in CheckedShortSalesBalancesPerInstrumentMessage }
        \cup { [tag |-> CapitalMarketMultiplesMessageCode, body |-> one] : one \in CheckedCapitalMarketMultiplesMessage }
        \cup { [tag |-> CapitalizationRulesMessageCode, body |-> one] : one \in CheckedCapitalizationRulesMessage }

(***************************************************************************)
(* Message Block, framed by Message Length                                 *)
(***************************************************************************)

MessageBlock ==
    [ payload : Payload ]

EncodeMessageBlockBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessageBlock(message) ==
    LET body == EncodeMessageBlockBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBlockBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessageBlock(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBlockBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessageBlock ==
    [ payload |-> ZeroPayload ]

(* Message Block at zero, then each field in turn at the values it is checked at *)
CheckedMessageBlock ==
    { ZeroMessageBlock }
        \cup { [ZeroMessageBlock EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message Block, written one after another *)
RECURSIVE EncodeMessageBlockList(_)
EncodeMessageBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessageBlock(Head(messages)) \o EncodeMessageBlockList(Tail(messages))

(* As many Message Block as the field that counts them says *)
RECURSIVE ReadMessageBlockList(_, _)
ReadMessageBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessageBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message Block of each kind, for the lists that carry them *)
OneMessageBlock ==
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DollarBuySellMessageCode, body |-> ZeroDollarBuySellMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ShortSalesBalancesPerInstrumentMessageCode, body |-> ZeroShortSalesBalancesPerInstrumentMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CapitalMarketMultiplesMessageCode, body |-> ZeroCapitalMarketMultiplesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CapitalizationRulesMessageCode, body |-> ZeroCapitalizationRulesMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      session         : Sample(1),
      sequenceNumber  : Sample(4),
      datetime        : Sample(8),
      messageBlock    : SampleLists(OneMessageBlock) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntBE(Len(message.messageBlock), 1)
        \o message.marketDataGroup
        \o message.session
        \o message.sequenceNumber
        \o message.datetime
        \o EncodeMessageBlockList(message.messageBlock)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET totalMessages == ReadUIntBE(length.rest, 1) IN IF ~totalMessages.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(totalMessages.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET session == ReadBytes(marketDataGroup.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET datetime == ReadBytes(sequenceNumber.rest, 8) IN IF ~datetime.ok THEN Fail ELSE
    LET messageBlock == ReadMessageBlockList(datetime.rest, totalMessages.value) IN IF ~messageBlock.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         session         |-> session.value,
         sequenceNumber  |-> sequenceNumber.value,
         datetime        |-> datetime.value,
         messageBlock    |-> messageBlock.value ], messageBlock.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      session         |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      datetime        |-> [i \in 1 .. 8 |-> 0],
      messageBlock    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.datetime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messageBlock = one] : one \in SampleLists(OneMessageBlock) }

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

(* Every Events System Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsSystemMessage ==
    \A message \in CheckedEventsSystemMessage :
        LET read == DecodeEventsSystemMessage(EncodeEventsSystemMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dollar Buy Sell Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDollarBuySellMessage ==
    \A message \in CheckedDollarBuySellMessage :
        LET read == DecodeDollarBuySellMessage(EncodeDollarBuySellMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Sales Balances Per Instrument Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSalesBalancesPerInstrumentMessage ==
    \A message \in CheckedShortSalesBalancesPerInstrumentMessage :
        LET read == DecodeShortSalesBalancesPerInstrumentMessage(EncodeShortSalesBalancesPerInstrumentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Capital Market Multiples Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCapitalMarketMultiplesMessage ==
    \A message \in CheckedCapitalMarketMultiplesMessage :
        LET read == DecodeCapitalMarketMultiplesMessage(EncodeCapitalMarketMultiplesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Capitalization Rules Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCapitalizationRulesMessage ==
    \A message \in CheckedCapitalizationRulesMessage :
        LET read == DecodeCapitalizationRulesMessage(EncodeCapitalizationRulesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Block decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET read == DecodeMessageBlock(EncodeMessageBlock(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET bytes == EncodeMessageBlock(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
