------------------- MODULE BmvMarketData_Product40_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 40 v1.1               *)
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
(* Catalog For Instruments Belonging To The Local And Global Stock Market  *)
(* Message: 111 bytes                                                      *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    [ instrumentNumber     : Sample(4),
      valueType            : Sample(2),
      issuer               : Sample(7),
      series               : Sample(6),
      lastPrice            : Sample(8),
      wap                  : Sample(8),
      closingPrice         : Sample(8),
      referenceDate        : Sample(8),
      reference            : Sample(2),
      currentCoupon        : Sample(2),
      marketability        : Sample(2),
      numericMarketability : Sample(4),
      isin                 : Sample(12),
      market               : Sample(1),
      sharesOutstanding    : Sample(8),
      blocksAmount         : Sample(8),
      exchange             : Sample(1),
      filler               : Sample(20) ]

EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message) ==
    message.instrumentNumber
        \o message.valueType
        \o message.issuer
        \o message.series
        \o message.lastPrice
        \o message.wap
        \o message.closingPrice
        \o message.referenceDate
        \o message.reference
        \o message.currentCoupon
        \o message.marketability
        \o message.numericMarketability
        \o message.isin
        \o message.market
        \o message.sharesOutstanding
        \o message.blocksAmount
        \o message.exchange
        \o message.filler

DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET valueType == ReadBytes(instrumentNumber.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET issuer == ReadBytes(valueType.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(series.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET wap == ReadBytes(lastPrice.rest, 8) IN IF ~wap.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(wap.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(closingPrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 2) IN IF ~reference.ok THEN Fail ELSE
    LET currentCoupon == ReadBytes(reference.rest, 2) IN IF ~currentCoupon.ok THEN Fail ELSE
    LET marketability == ReadBytes(currentCoupon.rest, 2) IN IF ~marketability.ok THEN Fail ELSE
    LET numericMarketability == ReadBytes(marketability.rest, 4) IN IF ~numericMarketability.ok THEN Fail ELSE
    LET isin == ReadBytes(numericMarketability.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET market == ReadBytes(isin.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sharesOutstanding == ReadBytes(market.rest, 8) IN IF ~sharesOutstanding.ok THEN Fail ELSE
    LET blocksAmount == ReadBytes(sharesOutstanding.rest, 8) IN IF ~blocksAmount.ok THEN Fail ELSE
    LET exchange == ReadBytes(blocksAmount.rest, 1) IN IF ~exchange.ok THEN Fail ELSE
    LET filler == ReadBytes(exchange.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber     |-> instrumentNumber.value,
         valueType            |-> valueType.value,
         issuer               |-> issuer.value,
         series               |-> series.value,
         lastPrice            |-> lastPrice.value,
         wap                  |-> wap.value,
         closingPrice         |-> closingPrice.value,
         referenceDate        |-> referenceDate.value,
         reference            |-> reference.value,
         currentCoupon        |-> currentCoupon.value,
         marketability        |-> marketability.value,
         numericMarketability |-> numericMarketability.value,
         isin                 |-> isin.value,
         market               |-> market.value,
         sharesOutstanding    |-> sharesOutstanding.value,
         blocksAmount         |-> blocksAmount.value,
         exchange             |-> exchange.value,
         filler               |-> filler.value ], filler.rest)

ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    [ instrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      valueType            |-> [i \in 1 .. 2 |-> 0],
      issuer               |-> [i \in 1 .. 7 |-> 0],
      series               |-> [i \in 1 .. 6 |-> 0],
      lastPrice            |-> [i \in 1 .. 8 |-> 0],
      wap                  |-> [i \in 1 .. 8 |-> 0],
      closingPrice         |-> [i \in 1 .. 8 |-> 0],
      referenceDate        |-> [i \in 1 .. 8 |-> 0],
      reference            |-> [i \in 1 .. 2 |-> 0],
      currentCoupon        |-> [i \in 1 .. 2 |-> 0],
      marketability        |-> [i \in 1 .. 2 |-> 0],
      numericMarketability |-> [i \in 1 .. 4 |-> 0],
      isin                 |-> [i \in 1 .. 12 |-> 0],
      market               |-> [i \in 1 .. 1 |-> 0],
      sharesOutstanding    |-> [i \in 1 .. 8 |-> 0],
      blocksAmount         |-> [i \in 1 .. 8 |-> 0],
      exchange             |-> [i \in 1 .. 1 |-> 0],
      filler               |-> [i \in 1 .. 20 |-> 0] ]

(* Catalog For Instruments Belonging To The Local And Global Stock Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    { ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.wap = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.reference = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.currentCoupon = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.marketability = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.numericMarketability = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.sharesOutstanding = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.blocksAmount = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.exchange = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Catalog Of Instruments That Belong To The Debt Metals And Money Market  *)
(* Message: 124 bytes                                                      *)
(***************************************************************************)

CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage ==
    [ instrumentNumber     : Sample(4),
      valueType            : Sample(2),
      issuer               : Sample(7),
      issue                : Sample(6),
      issueDate            : Sample(8),
      maturityDate         : Sample(8),
      referencePricerate   : Sample(8),
      referenceDate        : Sample(8),
      reference            : Sample(2),
      termDays             : Sample(2),
      currentCoupon        : Sample(2),
      isin                 : Sample(12),
      market               : Sample(1),
      currentNominalValue  : Sample(8),
      originalNominalValue : Sample(8),
      outstandingShares    : Sample(8),
      amountPlaced         : Sample(8),
      operatePriceRate     : Sample(1),
      exchange             : Sample(1),
      filler               : Sample(20) ]

EncodeCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage(message) ==
    message.instrumentNumber
        \o message.valueType
        \o message.issuer
        \o message.issue
        \o message.issueDate
        \o message.maturityDate
        \o message.referencePricerate
        \o message.referenceDate
        \o message.reference
        \o message.termDays
        \o message.currentCoupon
        \o message.isin
        \o message.market
        \o message.currentNominalValue
        \o message.originalNominalValue
        \o message.outstandingShares
        \o message.amountPlaced
        \o message.operatePriceRate
        \o message.exchange
        \o message.filler

DecodeCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET valueType == ReadBytes(instrumentNumber.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET issuer == ReadBytes(valueType.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET issue == ReadBytes(issuer.rest, 6) IN IF ~issue.ok THEN Fail ELSE
    LET issueDate == ReadBytes(issue.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(issueDate.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET referencePricerate == ReadBytes(maturityDate.rest, 8) IN IF ~referencePricerate.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePricerate.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 2) IN IF ~reference.ok THEN Fail ELSE
    LET termDays == ReadBytes(reference.rest, 2) IN IF ~termDays.ok THEN Fail ELSE
    LET currentCoupon == ReadBytes(termDays.rest, 2) IN IF ~currentCoupon.ok THEN Fail ELSE
    LET isin == ReadBytes(currentCoupon.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET market == ReadBytes(isin.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET currentNominalValue == ReadBytes(market.rest, 8) IN IF ~currentNominalValue.ok THEN Fail ELSE
    LET originalNominalValue == ReadBytes(currentNominalValue.rest, 8) IN IF ~originalNominalValue.ok THEN Fail ELSE
    LET outstandingShares == ReadBytes(originalNominalValue.rest, 8) IN IF ~outstandingShares.ok THEN Fail ELSE
    LET amountPlaced == ReadBytes(outstandingShares.rest, 8) IN IF ~amountPlaced.ok THEN Fail ELSE
    LET operatePriceRate == ReadBytes(amountPlaced.rest, 1) IN IF ~operatePriceRate.ok THEN Fail ELSE
    LET exchange == ReadBytes(operatePriceRate.rest, 1) IN IF ~exchange.ok THEN Fail ELSE
    LET filler == ReadBytes(exchange.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber     |-> instrumentNumber.value,
         valueType            |-> valueType.value,
         issuer               |-> issuer.value,
         issue                |-> issue.value,
         issueDate            |-> issueDate.value,
         maturityDate         |-> maturityDate.value,
         referencePricerate   |-> referencePricerate.value,
         referenceDate        |-> referenceDate.value,
         reference            |-> reference.value,
         termDays             |-> termDays.value,
         currentCoupon        |-> currentCoupon.value,
         isin                 |-> isin.value,
         market               |-> market.value,
         currentNominalValue  |-> currentNominalValue.value,
         originalNominalValue |-> originalNominalValue.value,
         outstandingShares    |-> outstandingShares.value,
         amountPlaced         |-> amountPlaced.value,
         operatePriceRate     |-> operatePriceRate.value,
         exchange             |-> exchange.value,
         filler               |-> filler.value ], filler.rest)

ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage ==
    [ instrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      valueType            |-> [i \in 1 .. 2 |-> 0],
      issuer               |-> [i \in 1 .. 7 |-> 0],
      issue                |-> [i \in 1 .. 6 |-> 0],
      issueDate            |-> [i \in 1 .. 8 |-> 0],
      maturityDate         |-> [i \in 1 .. 8 |-> 0],
      referencePricerate   |-> [i \in 1 .. 8 |-> 0],
      referenceDate        |-> [i \in 1 .. 8 |-> 0],
      reference            |-> [i \in 1 .. 2 |-> 0],
      termDays             |-> [i \in 1 .. 2 |-> 0],
      currentCoupon        |-> [i \in 1 .. 2 |-> 0],
      isin                 |-> [i \in 1 .. 12 |-> 0],
      market               |-> [i \in 1 .. 1 |-> 0],
      currentNominalValue  |-> [i \in 1 .. 8 |-> 0],
      originalNominalValue |-> [i \in 1 .. 8 |-> 0],
      outstandingShares    |-> [i \in 1 .. 8 |-> 0],
      amountPlaced         |-> [i \in 1 .. 8 |-> 0],
      operatePriceRate     |-> [i \in 1 .. 1 |-> 0],
      exchange             |-> [i \in 1 .. 1 |-> 0],
      filler               |-> [i \in 1 .. 20 |-> 0] ]

(* Catalog Of Instruments That Belong To The Debt Metals And Money Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage ==
    { ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.issue = one] : one \in Sample(6) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.referencePricerate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.reference = one] : one \in Sample(2) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.termDays = one] : one \in Sample(2) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.currentCoupon = one] : one \in Sample(2) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.currentNominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.originalNominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.outstandingShares = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.amountPlaced = one] : one \in Sample(8) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.operatePriceRate = one] : one \in Sample(1) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.exchange = one] : one \in Sample(1) }
        \cup { [ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Catalog For Instruments Belonging To The Capital Warrants Market        *)
(* Message: 87 bytes                                                       *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    [ instrumentNumber : Sample(4),
      valueType        : Sample(2),
      issuer           : Sample(7),
      series           : Sample(6),
      warrantType      : Sample(1),
      maturityDate     : Sample(8),
      exercisePrice    : Sample(8),
      referencePrice   : Sample(8),
      referenceDate    : Sample(8),
      reference        : Sample(2),
      isin             : Sample(12),
      exchange         : Sample(1),
      filler           : Sample(20) ]

EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message) ==
    message.instrumentNumber
        \o message.valueType
        \o message.issuer
        \o message.series
        \o message.warrantType
        \o message.maturityDate
        \o message.exercisePrice
        \o message.referencePrice
        \o message.referenceDate
        \o message.reference
        \o message.isin
        \o message.exchange
        \o message.filler

DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET valueType == ReadBytes(instrumentNumber.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET issuer == ReadBytes(valueType.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET warrantType == ReadBytes(series.rest, 1) IN IF ~warrantType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(warrantType.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET exercisePrice == ReadBytes(maturityDate.rest, 8) IN IF ~exercisePrice.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(exercisePrice.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 2) IN IF ~reference.ok THEN Fail ELSE
    LET isin == ReadBytes(reference.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET exchange == ReadBytes(isin.rest, 1) IN IF ~exchange.ok THEN Fail ELSE
    LET filler == ReadBytes(exchange.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         valueType        |-> valueType.value,
         issuer           |-> issuer.value,
         series           |-> series.value,
         warrantType      |-> warrantType.value,
         maturityDate     |-> maturityDate.value,
         exercisePrice    |-> exercisePrice.value,
         referencePrice   |-> referencePrice.value,
         referenceDate    |-> referenceDate.value,
         reference        |-> reference.value,
         isin             |-> isin.value,
         exchange         |-> exchange.value,
         filler           |-> filler.value ], filler.rest)

ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      valueType        |-> [i \in 1 .. 2 |-> 0],
      issuer           |-> [i \in 1 .. 7 |-> 0],
      series           |-> [i \in 1 .. 6 |-> 0],
      warrantType      |-> [i \in 1 .. 1 |-> 0],
      maturityDate     |-> [i \in 1 .. 8 |-> 0],
      exercisePrice    |-> [i \in 1 .. 8 |-> 0],
      referencePrice   |-> [i \in 1 .. 8 |-> 0],
      referenceDate    |-> [i \in 1 .. 8 |-> 0],
      reference        |-> [i \in 1 .. 2 |-> 0],
      isin             |-> [i \in 1 .. 12 |-> 0],
      exchange         |-> [i \in 1 .. 1 |-> 0],
      filler           |-> [i \in 1 .. 20 |-> 0] ]

(* Catalog For Instruments Belonging To The Capital Warrants Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    { ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.warrantType = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.exercisePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.reference = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.exchange = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Options Futures And Swaps Derivatives Market Instruments Catalog        *)
(* Message: 113 bytes                                                      *)
(***************************************************************************)

OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage ==
    [ instrumentNumber        : Sample(4),
      valueType               : Sample(2),
      class                   : Sample(7),
      maturity                : Sample(6),
      optionType              : Sample(1),
      exercisePrice           : Sample(8),
      bid                     : Sample(8),
      priorDaySettlementPrice : Sample(8),
      lastDayOfOperation      : Sample(8),
      maturityDate            : Sample(8),
      openContracts           : Sample(4),
      contractSize            : Sample(4),
      productCode             : Sample(12),
      dailyMaturity           : Sample(1),
      keyExercisePrice        : Sample(6),
      cfiCode                 : Sample(6),
      filler                  : Sample(20) ]

EncodeOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage(message) ==
    message.instrumentNumber
        \o message.valueType
        \o message.class
        \o message.maturity
        \o message.optionType
        \o message.exercisePrice
        \o message.bid
        \o message.priorDaySettlementPrice
        \o message.lastDayOfOperation
        \o message.maturityDate
        \o message.openContracts
        \o message.contractSize
        \o message.productCode
        \o message.dailyMaturity
        \o message.keyExercisePrice
        \o message.cfiCode
        \o message.filler

DecodeOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET valueType == ReadBytes(instrumentNumber.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET class == ReadBytes(valueType.rest, 7) IN IF ~class.ok THEN Fail ELSE
    LET maturity == ReadBytes(class.rest, 6) IN IF ~maturity.ok THEN Fail ELSE
    LET optionType == ReadBytes(maturity.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET exercisePrice == ReadBytes(optionType.rest, 8) IN IF ~exercisePrice.ok THEN Fail ELSE
    LET bid == ReadBytes(exercisePrice.rest, 8) IN IF ~bid.ok THEN Fail ELSE
    LET priorDaySettlementPrice == ReadBytes(bid.rest, 8) IN IF ~priorDaySettlementPrice.ok THEN Fail ELSE
    LET lastDayOfOperation == ReadBytes(priorDaySettlementPrice.rest, 8) IN IF ~lastDayOfOperation.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(lastDayOfOperation.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openContracts == ReadBytes(maturityDate.rest, 4) IN IF ~openContracts.ok THEN Fail ELSE
    LET contractSize == ReadBytes(openContracts.rest, 4) IN IF ~contractSize.ok THEN Fail ELSE
    LET productCode == ReadBytes(contractSize.rest, 12) IN IF ~productCode.ok THEN Fail ELSE
    LET dailyMaturity == ReadBytes(productCode.rest, 1) IN IF ~dailyMaturity.ok THEN Fail ELSE
    LET keyExercisePrice == ReadBytes(dailyMaturity.rest, 6) IN IF ~keyExercisePrice.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(keyExercisePrice.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET filler == ReadBytes(cfiCode.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber        |-> instrumentNumber.value,
         valueType               |-> valueType.value,
         class                   |-> class.value,
         maturity                |-> maturity.value,
         optionType              |-> optionType.value,
         exercisePrice           |-> exercisePrice.value,
         bid                     |-> bid.value,
         priorDaySettlementPrice |-> priorDaySettlementPrice.value,
         lastDayOfOperation      |-> lastDayOfOperation.value,
         maturityDate            |-> maturityDate.value,
         openContracts           |-> openContracts.value,
         contractSize            |-> contractSize.value,
         productCode             |-> productCode.value,
         dailyMaturity           |-> dailyMaturity.value,
         keyExercisePrice        |-> keyExercisePrice.value,
         cfiCode                 |-> cfiCode.value,
         filler                  |-> filler.value ], filler.rest)

ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage ==
    [ instrumentNumber        |-> [i \in 1 .. 4 |-> 0],
      valueType               |-> [i \in 1 .. 2 |-> 0],
      class                   |-> [i \in 1 .. 7 |-> 0],
      maturity                |-> [i \in 1 .. 6 |-> 0],
      optionType              |-> [i \in 1 .. 1 |-> 0],
      exercisePrice           |-> [i \in 1 .. 8 |-> 0],
      bid                     |-> [i \in 1 .. 8 |-> 0],
      priorDaySettlementPrice |-> [i \in 1 .. 8 |-> 0],
      lastDayOfOperation      |-> [i \in 1 .. 8 |-> 0],
      maturityDate            |-> [i \in 1 .. 8 |-> 0],
      openContracts           |-> [i \in 1 .. 4 |-> 0],
      contractSize            |-> [i \in 1 .. 4 |-> 0],
      productCode             |-> [i \in 1 .. 12 |-> 0],
      dailyMaturity           |-> [i \in 1 .. 1 |-> 0],
      keyExercisePrice        |-> [i \in 1 .. 6 |-> 0],
      cfiCode                 |-> [i \in 1 .. 6 |-> 0],
      filler                  |-> [i \in 1 .. 20 |-> 0] ]

(* Options Futures And Swaps Derivatives Market Instruments Catalog Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage ==
    { ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.class = one] : one \in Sample(7) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.maturity = one] : one \in Sample(6) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.exercisePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.bid = one] : one \in Sample(8) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.priorDaySettlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.lastDayOfOperation = one] : one \in Sample(8) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.openContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.contractSize = one] : one \in Sample(4) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.productCode = one] : one \in Sample(12) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.dailyMaturity = one] : one \in Sample(1) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.keyExercisePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To Capital Tracs Message: 101    *)
(* bytes                                                                   *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    [ tracNumber           : Sample(4),
      tracName             : Sample(8),
      underlyingIssuer     : Sample(7),
      underlyingSeries     : Sample(6),
      securities           : Sample(8),
      excludedSecurities   : Sample(8),
      price                : Sample(8),
      cashComponent        : Sample(8),
      excludedValue        : Sample(8),
      numberOfCertificates : Sample(8),
      theoreticalPrice     : Sample(8),
      filler               : Sample(20) ]

EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message) ==
    message.tracNumber
        \o message.tracName
        \o message.underlyingIssuer
        \o message.underlyingSeries
        \o message.securities
        \o message.excludedSecurities
        \o message.price
        \o message.cashComponent
        \o message.excludedValue
        \o message.numberOfCertificates
        \o message.theoreticalPrice
        \o message.filler

DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(bytes) ==
    LET tracNumber == ReadBytes(bytes, 4) IN IF ~tracNumber.ok THEN Fail ELSE
    LET tracName == ReadBytes(tracNumber.rest, 8) IN IF ~tracName.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(tracName.rest, 7) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET underlyingSeries == ReadBytes(underlyingIssuer.rest, 6) IN IF ~underlyingSeries.ok THEN Fail ELSE
    LET securities == ReadBytes(underlyingSeries.rest, 8) IN IF ~securities.ok THEN Fail ELSE
    LET excludedSecurities == ReadBytes(securities.rest, 8) IN IF ~excludedSecurities.ok THEN Fail ELSE
    LET price == ReadBytes(excludedSecurities.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cashComponent == ReadBytes(price.rest, 8) IN IF ~cashComponent.ok THEN Fail ELSE
    LET excludedValue == ReadBytes(cashComponent.rest, 8) IN IF ~excludedValue.ok THEN Fail ELSE
    LET numberOfCertificates == ReadBytes(excludedValue.rest, 8) IN IF ~numberOfCertificates.ok THEN Fail ELSE
    LET theoreticalPrice == ReadBytes(numberOfCertificates.rest, 8) IN IF ~theoreticalPrice.ok THEN Fail ELSE
    LET filler == ReadBytes(theoreticalPrice.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ tracNumber           |-> tracNumber.value,
         tracName             |-> tracName.value,
         underlyingIssuer     |-> underlyingIssuer.value,
         underlyingSeries     |-> underlyingSeries.value,
         securities           |-> securities.value,
         excludedSecurities   |-> excludedSecurities.value,
         price                |-> price.value,
         cashComponent        |-> cashComponent.value,
         excludedValue        |-> excludedValue.value,
         numberOfCertificates |-> numberOfCertificates.value,
         theoreticalPrice     |-> theoreticalPrice.value,
         filler               |-> filler.value ], filler.rest)

ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    [ tracNumber           |-> [i \in 1 .. 4 |-> 0],
      tracName             |-> [i \in 1 .. 8 |-> 0],
      underlyingIssuer     |-> [i \in 1 .. 7 |-> 0],
      underlyingSeries     |-> [i \in 1 .. 6 |-> 0],
      securities           |-> [i \in 1 .. 8 |-> 0],
      excludedSecurities   |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      cashComponent        |-> [i \in 1 .. 8 |-> 0],
      excludedValue        |-> [i \in 1 .. 8 |-> 0],
      numberOfCertificates |-> [i \in 1 .. 8 |-> 0],
      theoreticalPrice     |-> [i \in 1 .. 8 |-> 0],
      filler               |-> [i \in 1 .. 20 |-> 0] ]

(* Catalog Sent For Instruments Belonging To Capital Tracs Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.tracNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.tracName = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.underlyingIssuer = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.underlyingSeries = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.securities = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.excludedSecurities = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.cashComponent = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.excludedValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.numberOfCertificates = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.theoreticalPrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To Mutual Funds Message: 98      *)
(* bytes                                                                   *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    [ instrumentNumber : Sample(4),
      valueType        : Sample(2),
      issuer           : Sample(7),
      series           : Sample(6),
      sector           : Sample(1),
      subsector        : Sample(1),
      businessLine     : Sample(1),
      subLine          : Sample(1),
      operatingCompany : Sample(10),
      referencePrice   : Sample(8),
      referenceDate    : Sample(8),
      reference        : Sample(2),
      isin             : Sample(12),
      rating           : Sample(15),
      filler           : Sample(20) ]

EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message) ==
    message.instrumentNumber
        \o message.valueType
        \o message.issuer
        \o message.series
        \o message.sector
        \o message.subsector
        \o message.businessLine
        \o message.subLine
        \o message.operatingCompany
        \o message.referencePrice
        \o message.referenceDate
        \o message.reference
        \o message.isin
        \o message.rating
        \o message.filler

DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET valueType == ReadBytes(instrumentNumber.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET issuer == ReadBytes(valueType.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET sector == ReadBytes(series.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET subsector == ReadBytes(sector.rest, 1) IN IF ~subsector.ok THEN Fail ELSE
    LET businessLine == ReadBytes(subsector.rest, 1) IN IF ~businessLine.ok THEN Fail ELSE
    LET subLine == ReadBytes(businessLine.rest, 1) IN IF ~subLine.ok THEN Fail ELSE
    LET operatingCompany == ReadBytes(subLine.rest, 10) IN IF ~operatingCompany.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(operatingCompany.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 2) IN IF ~reference.ok THEN Fail ELSE
    LET isin == ReadBytes(reference.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET rating == ReadBytes(isin.rest, 15) IN IF ~rating.ok THEN Fail ELSE
    LET filler == ReadBytes(rating.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         valueType        |-> valueType.value,
         issuer           |-> issuer.value,
         series           |-> series.value,
         sector           |-> sector.value,
         subsector        |-> subsector.value,
         businessLine     |-> businessLine.value,
         subLine          |-> subLine.value,
         operatingCompany |-> operatingCompany.value,
         referencePrice   |-> referencePrice.value,
         referenceDate    |-> referenceDate.value,
         reference        |-> reference.value,
         isin             |-> isin.value,
         rating           |-> rating.value,
         filler           |-> filler.value ], filler.rest)

ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      valueType        |-> [i \in 1 .. 2 |-> 0],
      issuer           |-> [i \in 1 .. 7 |-> 0],
      series           |-> [i \in 1 .. 6 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      subsector        |-> [i \in 1 .. 1 |-> 0],
      businessLine     |-> [i \in 1 .. 1 |-> 0],
      subLine          |-> [i \in 1 .. 1 |-> 0],
      operatingCompany |-> [i \in 1 .. 10 |-> 0],
      referencePrice   |-> [i \in 1 .. 8 |-> 0],
      referenceDate    |-> [i \in 1 .. 8 |-> 0],
      reference        |-> [i \in 1 .. 2 |-> 0],
      isin             |-> [i \in 1 .. 12 |-> 0],
      rating           |-> [i \in 1 .. 15 |-> 0],
      filler           |-> [i \in 1 .. 20 |-> 0] ]

(* Catalog Sent For Instruments Belonging To Mutual Funds Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.subsector = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.businessLine = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.subLine = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.operatingCompany = one] : one \in Sample(10) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.reference = one] : one \in Sample(2) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.rating = one] : one \in Sample(15) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To The Strategy Derivative       *)
(* Market Message: 74 bytes                                                *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage ==
    [ instrumentNumber             : Sample(4),
      valueType                    : Sample(2),
      class                        : Sample(7),
      maturity                     : Sample(6),
      typeOfStrategy               : Sample(1),
      bid                          : Sample(8),
      lastDateOperation            : Sample(8),
      maturityDate                 : Sample(8),
      shortLegInstrumentIdentifier : Sample(4),
      longLegInstrumentsId         : Sample(4),
      frequency                    : Sample(1),
      numberOfMaturities           : Sample(1),
      filler                       : Sample(20) ]

EncodeCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage(message) ==
    message.instrumentNumber
        \o message.valueType
        \o message.class
        \o message.maturity
        \o message.typeOfStrategy
        \o message.bid
        \o message.lastDateOperation
        \o message.maturityDate
        \o message.shortLegInstrumentIdentifier
        \o message.longLegInstrumentsId
        \o message.frequency
        \o message.numberOfMaturities
        \o message.filler

DecodeCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET valueType == ReadBytes(instrumentNumber.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET class == ReadBytes(valueType.rest, 7) IN IF ~class.ok THEN Fail ELSE
    LET maturity == ReadBytes(class.rest, 6) IN IF ~maturity.ok THEN Fail ELSE
    LET typeOfStrategy == ReadBytes(maturity.rest, 1) IN IF ~typeOfStrategy.ok THEN Fail ELSE
    LET bid == ReadBytes(typeOfStrategy.rest, 8) IN IF ~bid.ok THEN Fail ELSE
    LET lastDateOperation == ReadBytes(bid.rest, 8) IN IF ~lastDateOperation.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(lastDateOperation.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET shortLegInstrumentIdentifier == ReadBytes(maturityDate.rest, 4) IN IF ~shortLegInstrumentIdentifier.ok THEN Fail ELSE
    LET longLegInstrumentsId == ReadBytes(shortLegInstrumentIdentifier.rest, 4) IN IF ~longLegInstrumentsId.ok THEN Fail ELSE
    LET frequency == ReadBytes(longLegInstrumentsId.rest, 1) IN IF ~frequency.ok THEN Fail ELSE
    LET numberOfMaturities == ReadBytes(frequency.rest, 1) IN IF ~numberOfMaturities.ok THEN Fail ELSE
    LET filler == ReadBytes(numberOfMaturities.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber             |-> instrumentNumber.value,
         valueType                    |-> valueType.value,
         class                        |-> class.value,
         maturity                     |-> maturity.value,
         typeOfStrategy               |-> typeOfStrategy.value,
         bid                          |-> bid.value,
         lastDateOperation            |-> lastDateOperation.value,
         maturityDate                 |-> maturityDate.value,
         shortLegInstrumentIdentifier |-> shortLegInstrumentIdentifier.value,
         longLegInstrumentsId         |-> longLegInstrumentsId.value,
         frequency                    |-> frequency.value,
         numberOfMaturities           |-> numberOfMaturities.value,
         filler                       |-> filler.value ], filler.rest)

ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage ==
    [ instrumentNumber             |-> [i \in 1 .. 4 |-> 0],
      valueType                    |-> [i \in 1 .. 2 |-> 0],
      class                        |-> [i \in 1 .. 7 |-> 0],
      maturity                     |-> [i \in 1 .. 6 |-> 0],
      typeOfStrategy               |-> [i \in 1 .. 1 |-> 0],
      bid                          |-> [i \in 1 .. 8 |-> 0],
      lastDateOperation            |-> [i \in 1 .. 8 |-> 0],
      maturityDate                 |-> [i \in 1 .. 8 |-> 0],
      shortLegInstrumentIdentifier |-> [i \in 1 .. 4 |-> 0],
      longLegInstrumentsId         |-> [i \in 1 .. 4 |-> 0],
      frequency                    |-> [i \in 1 .. 1 |-> 0],
      numberOfMaturities           |-> [i \in 1 .. 1 |-> 0],
      filler                       |-> [i \in 1 .. 20 |-> 0] ]

(* Catalog Sent For Instruments Belonging To The Strategy Derivative Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.class = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.maturity = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.typeOfStrategy = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.bid = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.lastDateOperation = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.shortLegInstrumentIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.longLegInstrumentsId = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.frequency = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.numberOfMaturities = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Underlying Value On Warrants Catalog Message: 63 bytes                  *)
(***************************************************************************)

UnderlyingValueOnWarrantsCatalogMessage ==
    [ instrumentNumber         : Sample(4),
      issuer                   : Sample(7),
      series                   : Sample(6),
      valueType                : Sample(2),
      underlyingIssuer         : Sample(7),
      underlyingSeries         : Sample(6),
      underlyingValueType      : Sample(2),
      numberOfRegisteredValues : Sample(8),
      exchange                 : Sample(1),
      filler                   : Sample(20) ]

EncodeUnderlyingValueOnWarrantsCatalogMessage(message) ==
    message.instrumentNumber
        \o message.issuer
        \o message.series
        \o message.valueType
        \o message.underlyingIssuer
        \o message.underlyingSeries
        \o message.underlyingValueType
        \o message.numberOfRegisteredValues
        \o message.exchange
        \o message.filler

DecodeUnderlyingValueOnWarrantsCatalogMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET issuer == ReadBytes(instrumentNumber.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET valueType == ReadBytes(series.rest, 2) IN IF ~valueType.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(valueType.rest, 7) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET underlyingSeries == ReadBytes(underlyingIssuer.rest, 6) IN IF ~underlyingSeries.ok THEN Fail ELSE
    LET underlyingValueType == ReadBytes(underlyingSeries.rest, 2) IN IF ~underlyingValueType.ok THEN Fail ELSE
    LET numberOfRegisteredValues == ReadBytes(underlyingValueType.rest, 8) IN IF ~numberOfRegisteredValues.ok THEN Fail ELSE
    LET exchange == ReadBytes(numberOfRegisteredValues.rest, 1) IN IF ~exchange.ok THEN Fail ELSE
    LET filler == ReadBytes(exchange.rest, 20) IN IF ~filler.ok THEN Fail ELSE
    Ok([ instrumentNumber         |-> instrumentNumber.value,
         issuer                   |-> issuer.value,
         series                   |-> series.value,
         valueType                |-> valueType.value,
         underlyingIssuer         |-> underlyingIssuer.value,
         underlyingSeries         |-> underlyingSeries.value,
         underlyingValueType      |-> underlyingValueType.value,
         numberOfRegisteredValues |-> numberOfRegisteredValues.value,
         exchange                 |-> exchange.value,
         filler                   |-> filler.value ], filler.rest)

ZeroUnderlyingValueOnWarrantsCatalogMessage ==
    [ instrumentNumber         |-> [i \in 1 .. 4 |-> 0],
      issuer                   |-> [i \in 1 .. 7 |-> 0],
      series                   |-> [i \in 1 .. 6 |-> 0],
      valueType                |-> [i \in 1 .. 2 |-> 0],
      underlyingIssuer         |-> [i \in 1 .. 7 |-> 0],
      underlyingSeries         |-> [i \in 1 .. 6 |-> 0],
      underlyingValueType      |-> [i \in 1 .. 2 |-> 0],
      numberOfRegisteredValues |-> [i \in 1 .. 8 |-> 0],
      exchange                 |-> [i \in 1 .. 1 |-> 0],
      filler                   |-> [i \in 1 .. 20 |-> 0] ]

(* Underlying Value On Warrants Catalog Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingValueOnWarrantsCatalogMessage ==
    { ZeroUnderlyingValueOnWarrantsCatalogMessage }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.valueType = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.underlyingIssuer = one] : one \in Sample(7) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.underlyingSeries = one] : one \in Sample(6) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.underlyingValueType = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.numberOfRegisteredValues = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.exchange = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueOnWarrantsCatalogMessage EXCEPT !.filler = one] : one \in Sample(20) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode == 25441  \* 0x6361
CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessageCode == 25442  \* 0x6362
CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode == 25443  \* 0x6363
OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessageCode == 25444  \* 0x6364
CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode == 25445  \* 0x6365
CatalogSentForInstrumentsBelongingToMutualFundsMessageCode == 25446  \* 0x6366
CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessageCode == 25447  \* 0x6367
UnderlyingValueOnWarrantsCatalogMessageCode == 25465  \* 0x6379

Payload ==
    [ tag : {CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode}, body : CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ]
        \cup [ tag : {CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessageCode}, body : CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage ]
        \cup [ tag : {CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode}, body : CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ]
        \cup [ tag : {OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessageCode}, body : OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode}, body : CatalogSentForInstrumentsBelongingToCapitalTracsMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToMutualFundsMessageCode}, body : CatalogSentForInstrumentsBelongingToMutualFundsMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessageCode}, body : CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage ]
        \cup [ tag : {UnderlyingValueOnWarrantsCatalogMessageCode}, body : UnderlyingValueOnWarrantsCatalogMessage ]

EncodePayload(message) ==
    CASE message.tag = CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode -> EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message.body)
      [] message.tag = CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessageCode -> EncodeCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage(message.body)
      [] message.tag = CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode -> EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message.body)
      [] message.tag = OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessageCode -> EncodeOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode -> EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToMutualFundsMessageCode -> EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessageCode -> EncodeCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage(message.body)
      [] message.tag = UnderlyingValueOnWarrantsCatalogMessageCode -> EncodeUnderlyingValueOnWarrantsCatalogMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode -> DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(bytes)
              [] tag = CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessageCode -> DecodeCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage(bytes)
              [] tag = CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode -> DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(bytes)
              [] tag = OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessageCode -> DecodeOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode -> DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToMutualFundsMessageCode -> DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessageCode -> DecodeCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage(bytes)
              [] tag = UnderlyingValueOnWarrantsCatalogMessageCode -> DecodeUnderlyingValueOnWarrantsCatalogMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> one] : one \in CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage }
        \cup { [tag |-> CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessageCode, body |-> one] : one \in CheckedCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage }
        \cup { [tag |-> CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode, body |-> one] : one \in CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage }
        \cup { [tag |-> OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessageCode, body |-> one] : one \in CheckedOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToMutualFundsMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage }
        \cup { [tag |-> UnderlyingValueOnWarrantsCatalogMessageCode, body |-> one] : one \in CheckedUnderlyingValueOnWarrantsCatalogMessage }

(***************************************************************************)
(* Message Block, framed by Message Length                                 *)
(***************************************************************************)

MessageBlock ==
    [ payload : Payload ]

EncodeMessageBlockBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessageBlock(message) ==
    LET body == EncodeMessageBlockBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBlockBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessageCode, body |-> ZeroCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessageCode, body |-> ZeroOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToMutualFundsMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> UnderlyingValueOnWarrantsCatalogMessageCode, body |-> ZeroUnderlyingValueOnWarrantsCatalogMessage]] }

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

(* Every Catalog For Instruments Belonging To The Local And Global Stock Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    \A message \in CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage :
        LET read == DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog Of Instruments That Belong To The Debt Metals And Money Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage ==
    \A message \in CheckedCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage :
        LET read == DecodeCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage(EncodeCatalogOfInstrumentsThatBelongToTheDebtMetalsAndMoneyMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog For Instruments Belonging To The Capital Warrants Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    \A message \in CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage :
        LET read == DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Futures And Swaps Derivatives Market Instruments Catalog Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage ==
    \A message \in CheckedOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage :
        LET read == DecodeOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage(EncodeOptionsFuturesAndSwapsDerivativesMarketInstrumentsCatalogMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog Sent For Instruments Belonging To Capital Tracs Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    \A message \in CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage :
        LET read == DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog Sent For Instruments Belonging To Mutual Funds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    \A message \in CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage :
        LET read == DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog Sent For Instruments Belonging To The Strategy Derivative Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage ==
    \A message \in CheckedCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage :
        LET read == DecodeCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage(EncodeCatalogSentForInstrumentsBelongingToTheStrategyDerivativeMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Value On Warrants Catalog Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingValueOnWarrantsCatalogMessage ==
    \A message \in CheckedUnderlyingValueOnWarrantsCatalogMessage :
        LET read == DecodeUnderlyingValueOnWarrantsCatalogMessage(EncodeUnderlyingValueOnWarrantsCatalogMessage(message))
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
