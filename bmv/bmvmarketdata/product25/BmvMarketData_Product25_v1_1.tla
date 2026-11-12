------------------- MODULE BmvMarketData_Product25_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 25 v1.1               *)
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
(* Mutual Funds Trades Message: 53 bytes                                   *)
(***************************************************************************)

MutualFundsTradesMessage ==
    [ instrumentNumber       : Sample(4),
      origin                 : Sample(1),
      dateOfTheTrade         : Sample(8),
      price                  : Sample(8),
      bookValue              : Sample(8),
      numberOfSalesTrades    : Sample(4),
      salesVolume            : Sample(8),
      numberOfPurchaseTrades : Sample(4),
      purchaseVolume         : Sample(8) ]

EncodeMutualFundsTradesMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.dateOfTheTrade
        \o message.price
        \o message.bookValue
        \o message.numberOfSalesTrades
        \o message.salesVolume
        \o message.numberOfPurchaseTrades
        \o message.purchaseVolume

DecodeMutualFundsTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET dateOfTheTrade == ReadBytes(origin.rest, 8) IN IF ~dateOfTheTrade.ok THEN Fail ELSE
    LET price == ReadBytes(dateOfTheTrade.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET bookValue == ReadBytes(price.rest, 8) IN IF ~bookValue.ok THEN Fail ELSE
    LET numberOfSalesTrades == ReadBytes(bookValue.rest, 4) IN IF ~numberOfSalesTrades.ok THEN Fail ELSE
    LET salesVolume == ReadBytes(numberOfSalesTrades.rest, 8) IN IF ~salesVolume.ok THEN Fail ELSE
    LET numberOfPurchaseTrades == ReadBytes(salesVolume.rest, 4) IN IF ~numberOfPurchaseTrades.ok THEN Fail ELSE
    LET purchaseVolume == ReadBytes(numberOfPurchaseTrades.rest, 8) IN IF ~purchaseVolume.ok THEN Fail ELSE
    Ok([ instrumentNumber       |-> instrumentNumber.value,
         origin                 |-> origin.value,
         dateOfTheTrade         |-> dateOfTheTrade.value,
         price                  |-> price.value,
         bookValue              |-> bookValue.value,
         numberOfSalesTrades    |-> numberOfSalesTrades.value,
         salesVolume            |-> salesVolume.value,
         numberOfPurchaseTrades |-> numberOfPurchaseTrades.value,
         purchaseVolume         |-> purchaseVolume.value ], purchaseVolume.rest)

ZeroMutualFundsTradesMessage ==
    [ instrumentNumber       |-> [i \in 1 .. 4 |-> 0],
      origin                 |-> [i \in 1 .. 1 |-> 0],
      dateOfTheTrade         |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      bookValue              |-> [i \in 1 .. 8 |-> 0],
      numberOfSalesTrades    |-> [i \in 1 .. 4 |-> 0],
      salesVolume            |-> [i \in 1 .. 8 |-> 0],
      numberOfPurchaseTrades |-> [i \in 1 .. 4 |-> 0],
      purchaseVolume         |-> [i \in 1 .. 8 |-> 0] ]

(* Mutual Funds Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedMutualFundsTradesMessage ==
    { ZeroMutualFundsTradesMessage }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.dateOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.bookValue = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.numberOfSalesTrades = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.salesVolume = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.numberOfPurchaseTrades = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.purchaseVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Opening Of Continuous Auctions Message: 21 bytes                        *)
(***************************************************************************)

OpeningOfContinuousAuctionsMessage ==
    [ instrumentNumber          : Sample(4),
      origin                    : Sample(1),
      auctionSessionStartupTime : Sample(8),
      auctionSessionEndTime     : Sample(8) ]

EncodeOpeningOfContinuousAuctionsMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.auctionSessionStartupTime
        \o message.auctionSessionEndTime

DecodeOpeningOfContinuousAuctionsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET auctionSessionStartupTime == ReadBytes(origin.rest, 8) IN IF ~auctionSessionStartupTime.ok THEN Fail ELSE
    LET auctionSessionEndTime == ReadBytes(auctionSessionStartupTime.rest, 8) IN IF ~auctionSessionEndTime.ok THEN Fail ELSE
    Ok([ instrumentNumber          |-> instrumentNumber.value,
         origin                    |-> origin.value,
         auctionSessionStartupTime |-> auctionSessionStartupTime.value,
         auctionSessionEndTime     |-> auctionSessionEndTime.value ], auctionSessionEndTime.rest)

ZeroOpeningOfContinuousAuctionsMessage ==
    [ instrumentNumber          |-> [i \in 1 .. 4 |-> 0],
      origin                    |-> [i \in 1 .. 1 |-> 0],
      auctionSessionStartupTime |-> [i \in 1 .. 8 |-> 0],
      auctionSessionEndTime     |-> [i \in 1 .. 8 |-> 0] ]

(* Opening Of Continuous Auctions Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningOfContinuousAuctionsMessage ==
    { ZeroOpeningOfContinuousAuctionsMessage }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.auctionSessionStartupTime = one] : one \in Sample(8) }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.auctionSessionEndTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Existence Of Bids At Mid Price Message: 6 bytes                         *)
(***************************************************************************)

ExistenceOfBidsAtMidPriceMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      bidsExisting     : Sample(1) ]

EncodeExistenceOfBidsAtMidPriceMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.bidsExisting

DecodeExistenceOfBidsAtMidPriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET bidsExisting == ReadBytes(origin.rest, 1) IN IF ~bidsExisting.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         bidsExisting     |-> bidsExisting.value ], bidsExisting.rest)

ZeroExistenceOfBidsAtMidPriceMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      bidsExisting     |-> [i \in 1 .. 1 |-> 0] ]

(* Existence Of Bids At Mid Price Message at zero, then each field in turn at the values it is checked at *)
CheckedExistenceOfBidsAtMidPriceMessage ==
    { ZeroExistenceOfBidsAtMidPriceMessage }
        \cup { [ZeroExistenceOfBidsAtMidPriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroExistenceOfBidsAtMidPriceMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroExistenceOfBidsAtMidPriceMessage EXCEPT !.bidsExisting = one] : one \in Sample(1) }

(***************************************************************************)
(* Catalogue Of Debt And Metals Instruments Message: 103 bytes             *)
(***************************************************************************)

CatalogueOfDebtAndMetalsInstrumentsMessage ==
    [ numberOfTheInstrument : Sample(4),
      origin                : Sample(1),
      typeOfValue           : Sample(2),
      issuingCompany        : Sample(7),
      issuance              : Sample(6),
      dateOfIssuance        : Sample(8),
      dateOfMaturity        : Sample(8),
      priceRateOfReference  : Sample(8),
      dateOfReference       : Sample(8),
      reference             : Sample(1),
      termDays              : Sample(2),
      couponPeriod          : Sample(2),
      isin                  : Sample(12),
      market                : Sample(1),
      currentNominalValue   : Sample(8),
      originalNominalValue  : Sample(8),
      outstandingShares     : Sample(8),
      amountPlaced          : Sample(8),
      tradesRatePrice       : Sample(1) ]

EncodeCatalogueOfDebtAndMetalsInstrumentsMessage(message) ==
    message.numberOfTheInstrument
        \o message.origin
        \o message.typeOfValue
        \o message.issuingCompany
        \o message.issuance
        \o message.dateOfIssuance
        \o message.dateOfMaturity
        \o message.priceRateOfReference
        \o message.dateOfReference
        \o message.reference
        \o message.termDays
        \o message.couponPeriod
        \o message.isin
        \o message.market
        \o message.currentNominalValue
        \o message.originalNominalValue
        \o message.outstandingShares
        \o message.amountPlaced
        \o message.tradesRatePrice

DecodeCatalogueOfDebtAndMetalsInstrumentsMessage(bytes) ==
    LET numberOfTheInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheInstrument.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheInstrument.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET typeOfValue == ReadBytes(origin.rest, 2) IN IF ~typeOfValue.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(typeOfValue.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET issuance == ReadBytes(issuingCompany.rest, 6) IN IF ~issuance.ok THEN Fail ELSE
    LET dateOfIssuance == ReadBytes(issuance.rest, 8) IN IF ~dateOfIssuance.ok THEN Fail ELSE
    LET dateOfMaturity == ReadBytes(dateOfIssuance.rest, 8) IN IF ~dateOfMaturity.ok THEN Fail ELSE
    LET priceRateOfReference == ReadBytes(dateOfMaturity.rest, 8) IN IF ~priceRateOfReference.ok THEN Fail ELSE
    LET dateOfReference == ReadBytes(priceRateOfReference.rest, 8) IN IF ~dateOfReference.ok THEN Fail ELSE
    LET reference == ReadBytes(dateOfReference.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET termDays == ReadBytes(reference.rest, 2) IN IF ~termDays.ok THEN Fail ELSE
    LET couponPeriod == ReadBytes(termDays.rest, 2) IN IF ~couponPeriod.ok THEN Fail ELSE
    LET isin == ReadBytes(couponPeriod.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET market == ReadBytes(isin.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET currentNominalValue == ReadBytes(market.rest, 8) IN IF ~currentNominalValue.ok THEN Fail ELSE
    LET originalNominalValue == ReadBytes(currentNominalValue.rest, 8) IN IF ~originalNominalValue.ok THEN Fail ELSE
    LET outstandingShares == ReadBytes(originalNominalValue.rest, 8) IN IF ~outstandingShares.ok THEN Fail ELSE
    LET amountPlaced == ReadBytes(outstandingShares.rest, 8) IN IF ~amountPlaced.ok THEN Fail ELSE
    LET tradesRatePrice == ReadBytes(amountPlaced.rest, 1) IN IF ~tradesRatePrice.ok THEN Fail ELSE
    Ok([ numberOfTheInstrument |-> numberOfTheInstrument.value,
         origin                |-> origin.value,
         typeOfValue           |-> typeOfValue.value,
         issuingCompany        |-> issuingCompany.value,
         issuance              |-> issuance.value,
         dateOfIssuance        |-> dateOfIssuance.value,
         dateOfMaturity        |-> dateOfMaturity.value,
         priceRateOfReference  |-> priceRateOfReference.value,
         dateOfReference       |-> dateOfReference.value,
         reference             |-> reference.value,
         termDays              |-> termDays.value,
         couponPeriod          |-> couponPeriod.value,
         isin                  |-> isin.value,
         market                |-> market.value,
         currentNominalValue   |-> currentNominalValue.value,
         originalNominalValue  |-> originalNominalValue.value,
         outstandingShares     |-> outstandingShares.value,
         amountPlaced          |-> amountPlaced.value,
         tradesRatePrice       |-> tradesRatePrice.value ], tradesRatePrice.rest)

ZeroCatalogueOfDebtAndMetalsInstrumentsMessage ==
    [ numberOfTheInstrument |-> [i \in 1 .. 4 |-> 0],
      origin                |-> [i \in 1 .. 1 |-> 0],
      typeOfValue           |-> [i \in 1 .. 2 |-> 0],
      issuingCompany        |-> [i \in 1 .. 7 |-> 0],
      issuance              |-> [i \in 1 .. 6 |-> 0],
      dateOfIssuance        |-> [i \in 1 .. 8 |-> 0],
      dateOfMaturity        |-> [i \in 1 .. 8 |-> 0],
      priceRateOfReference  |-> [i \in 1 .. 8 |-> 0],
      dateOfReference       |-> [i \in 1 .. 8 |-> 0],
      reference             |-> [i \in 1 .. 1 |-> 0],
      termDays              |-> [i \in 1 .. 2 |-> 0],
      couponPeriod          |-> [i \in 1 .. 2 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0],
      market                |-> [i \in 1 .. 1 |-> 0],
      currentNominalValue   |-> [i \in 1 .. 8 |-> 0],
      originalNominalValue  |-> [i \in 1 .. 8 |-> 0],
      outstandingShares     |-> [i \in 1 .. 8 |-> 0],
      amountPlaced          |-> [i \in 1 .. 8 |-> 0],
      tradesRatePrice       |-> [i \in 1 .. 1 |-> 0] ]

(* Catalogue Of Debt And Metals Instruments Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogueOfDebtAndMetalsInstrumentsMessage ==
    { ZeroCatalogueOfDebtAndMetalsInstrumentsMessage }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.numberOfTheInstrument = one] : one \in Sample(4) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.typeOfValue = one] : one \in Sample(2) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.issuance = one] : one \in Sample(6) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.dateOfIssuance = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.dateOfMaturity = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.priceRateOfReference = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.dateOfReference = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.termDays = one] : one \in Sample(2) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.couponPeriod = one] : one \in Sample(2) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.currentNominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.originalNominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.outstandingShares = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.amountPlaced = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.tradesRatePrice = one] : one \in Sample(1) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To Mutual Funds Message: 78      *)
(* bytes                                                                   *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    [ numberOfTheInstrument : Sample(4),
      origin                : Sample(1),
      typeOfValue           : Sample(2),
      issuingCompany        : Sample(7),
      series                : Sample(6),
      sector                : Sample(1),
      subSector             : Sample(1),
      industry              : Sample(1),
      subIndustry           : Sample(1),
      tradingCompany        : Sample(10),
      referencePrice        : Sample(8),
      referenceDate         : Sample(8),
      reference             : Sample(1),
      isin                  : Sample(12),
      rating                : Sample(15) ]

EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message) ==
    message.numberOfTheInstrument
        \o message.origin
        \o message.typeOfValue
        \o message.issuingCompany
        \o message.series
        \o message.sector
        \o message.subSector
        \o message.industry
        \o message.subIndustry
        \o message.tradingCompany
        \o message.referencePrice
        \o message.referenceDate
        \o message.reference
        \o message.isin
        \o message.rating

DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(bytes) ==
    LET numberOfTheInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheInstrument.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheInstrument.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET typeOfValue == ReadBytes(origin.rest, 2) IN IF ~typeOfValue.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(typeOfValue.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET series == ReadBytes(issuingCompany.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET sector == ReadBytes(series.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET subSector == ReadBytes(sector.rest, 1) IN IF ~subSector.ok THEN Fail ELSE
    LET industry == ReadBytes(subSector.rest, 1) IN IF ~industry.ok THEN Fail ELSE
    LET subIndustry == ReadBytes(industry.rest, 1) IN IF ~subIndustry.ok THEN Fail ELSE
    LET tradingCompany == ReadBytes(subIndustry.rest, 10) IN IF ~tradingCompany.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(tradingCompany.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET isin == ReadBytes(reference.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET rating == ReadBytes(isin.rest, 15) IN IF ~rating.ok THEN Fail ELSE
    Ok([ numberOfTheInstrument |-> numberOfTheInstrument.value,
         origin                |-> origin.value,
         typeOfValue           |-> typeOfValue.value,
         issuingCompany        |-> issuingCompany.value,
         series                |-> series.value,
         sector                |-> sector.value,
         subSector             |-> subSector.value,
         industry              |-> industry.value,
         subIndustry           |-> subIndustry.value,
         tradingCompany        |-> tradingCompany.value,
         referencePrice        |-> referencePrice.value,
         referenceDate         |-> referenceDate.value,
         reference             |-> reference.value,
         isin                  |-> isin.value,
         rating                |-> rating.value ], rating.rest)

ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    [ numberOfTheInstrument |-> [i \in 1 .. 4 |-> 0],
      origin                |-> [i \in 1 .. 1 |-> 0],
      typeOfValue           |-> [i \in 1 .. 2 |-> 0],
      issuingCompany        |-> [i \in 1 .. 7 |-> 0],
      series                |-> [i \in 1 .. 6 |-> 0],
      sector                |-> [i \in 1 .. 1 |-> 0],
      subSector             |-> [i \in 1 .. 1 |-> 0],
      industry              |-> [i \in 1 .. 1 |-> 0],
      subIndustry           |-> [i \in 1 .. 1 |-> 0],
      tradingCompany        |-> [i \in 1 .. 10 |-> 0],
      referencePrice        |-> [i \in 1 .. 8 |-> 0],
      referenceDate         |-> [i \in 1 .. 8 |-> 0],
      reference             |-> [i \in 1 .. 1 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0],
      rating                |-> [i \in 1 .. 15 |-> 0] ]

(* Catalog Sent For Instruments Belonging To Mutual Funds Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.numberOfTheInstrument = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.typeOfValue = one] : one \in Sample(2) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.subSector = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.industry = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.subIndustry = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.tradingCompany = one] : one \in Sample(10) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.rating = one] : one \in Sample(15) }

(***************************************************************************)
(* Weighted Average Price Message: 21 bytes                                *)
(***************************************************************************)

WeightedAveragePriceMessage ==
    [ instrumentNumber     : Sample(4),
      origin               : Sample(1),
      weightedAveragePrice : Sample(8),
      volatility           : Sample(8) ]

EncodeWeightedAveragePriceMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.weightedAveragePrice
        \o message.volatility

DecodeWeightedAveragePriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET weightedAveragePrice == ReadBytes(origin.rest, 8) IN IF ~weightedAveragePrice.ok THEN Fail ELSE
    LET volatility == ReadBytes(weightedAveragePrice.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    Ok([ instrumentNumber     |-> instrumentNumber.value,
         origin               |-> origin.value,
         weightedAveragePrice |-> weightedAveragePrice.value,
         volatility           |-> volatility.value ], volatility.rest)

ZeroWeightedAveragePriceMessage ==
    [ instrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      origin               |-> [i \in 1 .. 1 |-> 0],
      weightedAveragePrice |-> [i \in 1 .. 8 |-> 0],
      volatility           |-> [i \in 1 .. 8 |-> 0] ]

(* Weighted Average Price Message at zero, then each field in turn at the values it is checked at *)
CheckedWeightedAveragePriceMessage ==
    { ZeroWeightedAveragePriceMessage }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.weightedAveragePrice = one] : one \in Sample(8) }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.volatility = one] : one \in Sample(8) }

(***************************************************************************)
(* System Events Message: 31 bytes                                         *)
(***************************************************************************)

SystemEventsMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      codeOfEvent      : Sample(1),
      market           : Sample(1),
      sendTime         : Sample(8),
      endTime          : Sample(8),
      group            : Sample(8) ]

EncodeSystemEventsMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.codeOfEvent
        \o message.market
        \o message.sendTime
        \o message.endTime
        \o message.group

DecodeSystemEventsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET codeOfEvent == ReadBytes(origin.rest, 1) IN IF ~codeOfEvent.ok THEN Fail ELSE
    LET market == ReadBytes(codeOfEvent.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sendTime == ReadBytes(market.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(sendTime.rest, 8) IN IF ~endTime.ok THEN Fail ELSE
    LET group == ReadBytes(endTime.rest, 8) IN IF ~group.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         codeOfEvent      |-> codeOfEvent.value,
         market           |-> market.value,
         sendTime         |-> sendTime.value,
         endTime          |-> endTime.value,
         group            |-> group.value ], group.rest)

ZeroSystemEventsMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      codeOfEvent      |-> [i \in 1 .. 1 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sendTime         |-> [i \in 1 .. 8 |-> 0],
      endTime          |-> [i \in 1 .. 8 |-> 0],
      group            |-> [i \in 1 .. 8 |-> 0] ]

(* System Events Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventsMessage ==
    { ZeroSystemEventsMessage }
        \cup { [ZeroSystemEventsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.codeOfEvent = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.endTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.group = one] : one \in Sample(8) }

(***************************************************************************)
(* Reference Price Message: 14 bytes                                       *)
(***************************************************************************)

ReferencePriceMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      price            : Sample(8),
      priceType        : Sample(1) ]

EncodeReferencePriceMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.price
        \o message.priceType

DecodeReferencePriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET price == ReadBytes(origin.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET priceType == ReadBytes(price.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         price            |-> price.value,
         priceType        |-> priceType.value ], priceType.rest)

ZeroReferencePriceMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      priceType        |-> [i \in 1 .. 1 |-> 0] ]

(* Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceMessage ==
    { ZeroReferencePriceMessage }
        \cup { [ZeroReferencePriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Changes In Status Message: 7 bytes                                      *)
(***************************************************************************)

ChangesInStatusMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      status           : Sample(1),
      reason           : Sample(1) ]

EncodeChangesInStatusMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.status
        \o message.reason

DecodeChangesInStatusMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET status == ReadBytes(origin.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reason == ReadBytes(status.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         status           |-> status.value,
         reason           |-> reason.value ], reason.rest)

ZeroChangesInStatusMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      status           |-> [i \in 1 .. 1 |-> 0],
      reason           |-> [i \in 1 .. 1 |-> 0] ]

(* Changes In Status Message at zero, then each field in turn at the values it is checked at *)
CheckedChangesInStatusMessage ==
    { ZeroChangesInStatusMessage }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Catalog For Instruments Belonging To The Capital Warrants Market        *)
(* Message: 66 bytes                                                       *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    [ numberOfTheInstrument : Sample(4),
      origin                : Sample(1),
      typeOfValue           : Sample(2),
      issuingCompany        : Sample(7),
      series                : Sample(6),
      typeOfWarrant         : Sample(1),
      dateOfMaturity        : Sample(8),
      priceOfExercise       : Sample(8),
      referencePrice        : Sample(8),
      referenceDate         : Sample(8),
      reference             : Sample(1),
      isin                  : Sample(12) ]

EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message) ==
    message.numberOfTheInstrument
        \o message.origin
        \o message.typeOfValue
        \o message.issuingCompany
        \o message.series
        \o message.typeOfWarrant
        \o message.dateOfMaturity
        \o message.priceOfExercise
        \o message.referencePrice
        \o message.referenceDate
        \o message.reference
        \o message.isin

DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(bytes) ==
    LET numberOfTheInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheInstrument.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheInstrument.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET typeOfValue == ReadBytes(origin.rest, 2) IN IF ~typeOfValue.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(typeOfValue.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET series == ReadBytes(issuingCompany.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET typeOfWarrant == ReadBytes(series.rest, 1) IN IF ~typeOfWarrant.ok THEN Fail ELSE
    LET dateOfMaturity == ReadBytes(typeOfWarrant.rest, 8) IN IF ~dateOfMaturity.ok THEN Fail ELSE
    LET priceOfExercise == ReadBytes(dateOfMaturity.rest, 8) IN IF ~priceOfExercise.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(priceOfExercise.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET isin == ReadBytes(reference.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    Ok([ numberOfTheInstrument |-> numberOfTheInstrument.value,
         origin                |-> origin.value,
         typeOfValue           |-> typeOfValue.value,
         issuingCompany        |-> issuingCompany.value,
         series                |-> series.value,
         typeOfWarrant         |-> typeOfWarrant.value,
         dateOfMaturity        |-> dateOfMaturity.value,
         priceOfExercise       |-> priceOfExercise.value,
         referencePrice        |-> referencePrice.value,
         referenceDate         |-> referenceDate.value,
         reference             |-> reference.value,
         isin                  |-> isin.value ], isin.rest)

ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    [ numberOfTheInstrument |-> [i \in 1 .. 4 |-> 0],
      origin                |-> [i \in 1 .. 1 |-> 0],
      typeOfValue           |-> [i \in 1 .. 2 |-> 0],
      issuingCompany        |-> [i \in 1 .. 7 |-> 0],
      series                |-> [i \in 1 .. 6 |-> 0],
      typeOfWarrant         |-> [i \in 1 .. 1 |-> 0],
      dateOfMaturity        |-> [i \in 1 .. 8 |-> 0],
      priceOfExercise       |-> [i \in 1 .. 8 |-> 0],
      referencePrice        |-> [i \in 1 .. 8 |-> 0],
      referenceDate         |-> [i \in 1 .. 8 |-> 0],
      reference             |-> [i \in 1 .. 1 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0] ]

(* Catalog For Instruments Belonging To The Capital Warrants Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    { ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.numberOfTheInstrument = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.typeOfValue = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.typeOfWarrant = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.dateOfMaturity = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.priceOfExercise = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To Capital Tracs Message: 82     *)
(* bytes                                                                   *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    [ numberOfTheTrac          : Sample(4),
      origin                   : Sample(1),
      nameOfTheTrac            : Sample(8),
      underlyingIssuingCompany : Sample(7),
      underlyingSeries         : Sample(6),
      securities               : Sample(8),
      excludedSecurities       : Sample(8),
      price                    : Sample(8),
      componentInCash          : Sample(8),
      excludedValue            : Sample(8),
      numberOfCertificates     : Sample(8),
      theoreticalPrice         : Sample(8) ]

EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message) ==
    message.numberOfTheTrac
        \o message.origin
        \o message.nameOfTheTrac
        \o message.underlyingIssuingCompany
        \o message.underlyingSeries
        \o message.securities
        \o message.excludedSecurities
        \o message.price
        \o message.componentInCash
        \o message.excludedValue
        \o message.numberOfCertificates
        \o message.theoreticalPrice

DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(bytes) ==
    LET numberOfTheTrac == ReadBytes(bytes, 4) IN IF ~numberOfTheTrac.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheTrac.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET nameOfTheTrac == ReadBytes(origin.rest, 8) IN IF ~nameOfTheTrac.ok THEN Fail ELSE
    LET underlyingIssuingCompany == ReadBytes(nameOfTheTrac.rest, 7) IN IF ~underlyingIssuingCompany.ok THEN Fail ELSE
    LET underlyingSeries == ReadBytes(underlyingIssuingCompany.rest, 6) IN IF ~underlyingSeries.ok THEN Fail ELSE
    LET securities == ReadBytes(underlyingSeries.rest, 8) IN IF ~securities.ok THEN Fail ELSE
    LET excludedSecurities == ReadBytes(securities.rest, 8) IN IF ~excludedSecurities.ok THEN Fail ELSE
    LET price == ReadBytes(excludedSecurities.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET componentInCash == ReadBytes(price.rest, 8) IN IF ~componentInCash.ok THEN Fail ELSE
    LET excludedValue == ReadBytes(componentInCash.rest, 8) IN IF ~excludedValue.ok THEN Fail ELSE
    LET numberOfCertificates == ReadBytes(excludedValue.rest, 8) IN IF ~numberOfCertificates.ok THEN Fail ELSE
    LET theoreticalPrice == ReadBytes(numberOfCertificates.rest, 8) IN IF ~theoreticalPrice.ok THEN Fail ELSE
    Ok([ numberOfTheTrac          |-> numberOfTheTrac.value,
         origin                   |-> origin.value,
         nameOfTheTrac            |-> nameOfTheTrac.value,
         underlyingIssuingCompany |-> underlyingIssuingCompany.value,
         underlyingSeries         |-> underlyingSeries.value,
         securities               |-> securities.value,
         excludedSecurities       |-> excludedSecurities.value,
         price                    |-> price.value,
         componentInCash          |-> componentInCash.value,
         excludedValue            |-> excludedValue.value,
         numberOfCertificates     |-> numberOfCertificates.value,
         theoreticalPrice         |-> theoreticalPrice.value ], theoreticalPrice.rest)

ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    [ numberOfTheTrac          |-> [i \in 1 .. 4 |-> 0],
      origin                   |-> [i \in 1 .. 1 |-> 0],
      nameOfTheTrac            |-> [i \in 1 .. 8 |-> 0],
      underlyingIssuingCompany |-> [i \in 1 .. 7 |-> 0],
      underlyingSeries         |-> [i \in 1 .. 6 |-> 0],
      securities               |-> [i \in 1 .. 8 |-> 0],
      excludedSecurities       |-> [i \in 1 .. 8 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      componentInCash          |-> [i \in 1 .. 8 |-> 0],
      excludedValue            |-> [i \in 1 .. 8 |-> 0],
      numberOfCertificates     |-> [i \in 1 .. 8 |-> 0],
      theoreticalPrice         |-> [i \in 1 .. 8 |-> 0] ]

(* Catalog Sent For Instruments Belonging To Capital Tracs Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.numberOfTheTrac = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.nameOfTheTrac = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.underlyingIssuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.underlyingSeries = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.securities = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.excludedSecurities = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.componentInCash = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.excludedValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.numberOfCertificates = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.theoreticalPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Consolidated Inav Message: 13 bytes                                     *)
(***************************************************************************)

ConsolidatedInavMessage ==
    [ numberOfTheTrac         : Sample(4),
      origin                  : Sample(1),
      currentTheoreticalPrice : Sample(8) ]

EncodeConsolidatedInavMessage(message) ==
    message.numberOfTheTrac
        \o message.origin
        \o message.currentTheoreticalPrice

DecodeConsolidatedInavMessage(bytes) ==
    LET numberOfTheTrac == ReadBytes(bytes, 4) IN IF ~numberOfTheTrac.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheTrac.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET currentTheoreticalPrice == ReadBytes(origin.rest, 8) IN IF ~currentTheoreticalPrice.ok THEN Fail ELSE
    Ok([ numberOfTheTrac         |-> numberOfTheTrac.value,
         origin                  |-> origin.value,
         currentTheoreticalPrice |-> currentTheoreticalPrice.value ], currentTheoreticalPrice.rest)

ZeroConsolidatedInavMessage ==
    [ numberOfTheTrac         |-> [i \in 1 .. 4 |-> 0],
      origin                  |-> [i \in 1 .. 1 |-> 0],
      currentTheoreticalPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Consolidated Inav Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedInavMessage ==
    { ZeroConsolidatedInavMessage }
        \cup { [ZeroConsolidatedInavMessage EXCEPT !.numberOfTheTrac = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedInavMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedInavMessage EXCEPT !.currentTheoreticalPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Catalog For Instruments Belonging To The Local And Global Stock Market  *)
(* Message: 73 bytes                                                       *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    [ mseInstrumentNumber     : Sample(4),
      valueOfType             : Sample(2),
      issuingCompany          : Sample(7),
      series                  : Sample(6),
      lastPrice               : Sample(8),
      pppWeightedAveragePrice : Sample(8),
      referenceDate           : Sample(8),
      reference               : Sample(1),
      couponInEffect          : Sample(2),
      marketability           : Sample(1),
      numericalMarketability  : Sample(4),
      isin                    : Sample(12),
      market                  : Sample(1),
      registeredValues        : Sample(8),
      exchange                : Sample(1) ]

EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message) ==
    message.mseInstrumentNumber
        \o message.valueOfType
        \o message.issuingCompany
        \o message.series
        \o message.lastPrice
        \o message.pppWeightedAveragePrice
        \o message.referenceDate
        \o message.reference
        \o message.couponInEffect
        \o message.marketability
        \o message.numericalMarketability
        \o message.isin
        \o message.market
        \o message.registeredValues
        \o message.exchange

DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(bytes) ==
    LET mseInstrumentNumber == ReadBytes(bytes, 4) IN IF ~mseInstrumentNumber.ok THEN Fail ELSE
    LET valueOfType == ReadBytes(mseInstrumentNumber.rest, 2) IN IF ~valueOfType.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(valueOfType.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET series == ReadBytes(issuingCompany.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(series.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET pppWeightedAveragePrice == ReadBytes(lastPrice.rest, 8) IN IF ~pppWeightedAveragePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(pppWeightedAveragePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET couponInEffect == ReadBytes(reference.rest, 2) IN IF ~couponInEffect.ok THEN Fail ELSE
    LET marketability == ReadBytes(couponInEffect.rest, 1) IN IF ~marketability.ok THEN Fail ELSE
    LET numericalMarketability == ReadBytes(marketability.rest, 4) IN IF ~numericalMarketability.ok THEN Fail ELSE
    LET isin == ReadBytes(numericalMarketability.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET market == ReadBytes(isin.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET registeredValues == ReadBytes(market.rest, 8) IN IF ~registeredValues.ok THEN Fail ELSE
    LET exchange == ReadBytes(registeredValues.rest, 1) IN IF ~exchange.ok THEN Fail ELSE
    Ok([ mseInstrumentNumber     |-> mseInstrumentNumber.value,
         valueOfType             |-> valueOfType.value,
         issuingCompany          |-> issuingCompany.value,
         series                  |-> series.value,
         lastPrice               |-> lastPrice.value,
         pppWeightedAveragePrice |-> pppWeightedAveragePrice.value,
         referenceDate           |-> referenceDate.value,
         reference               |-> reference.value,
         couponInEffect          |-> couponInEffect.value,
         marketability           |-> marketability.value,
         numericalMarketability  |-> numericalMarketability.value,
         isin                    |-> isin.value,
         market                  |-> market.value,
         registeredValues        |-> registeredValues.value,
         exchange                |-> exchange.value ], exchange.rest)

ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    [ mseInstrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      valueOfType             |-> [i \in 1 .. 2 |-> 0],
      issuingCompany          |-> [i \in 1 .. 7 |-> 0],
      series                  |-> [i \in 1 .. 6 |-> 0],
      lastPrice               |-> [i \in 1 .. 8 |-> 0],
      pppWeightedAveragePrice |-> [i \in 1 .. 8 |-> 0],
      referenceDate           |-> [i \in 1 .. 8 |-> 0],
      reference               |-> [i \in 1 .. 1 |-> 0],
      couponInEffect          |-> [i \in 1 .. 2 |-> 0],
      marketability           |-> [i \in 1 .. 1 |-> 0],
      numericalMarketability  |-> [i \in 1 .. 4 |-> 0],
      isin                    |-> [i \in 1 .. 12 |-> 0],
      market                  |-> [i \in 1 .. 1 |-> 0],
      registeredValues        |-> [i \in 1 .. 8 |-> 0],
      exchange                |-> [i \in 1 .. 1 |-> 0] ]

(* Catalog For Instruments Belonging To The Local And Global Stock Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    { ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.mseInstrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.valueOfType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.pppWeightedAveragePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.couponInEffect = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.marketability = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.numericalMarketability = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.registeredValues = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.exchange = one] : one \in Sample(1) }

(***************************************************************************)
(* Probable Price Of Allocation Message: 21 bytes                          *)
(***************************************************************************)

ProbablePriceOfAllocationMessage ==
    [ instrumentNumber          : Sample(4),
      origin                    : Sample(1),
      probablePriceOfAllocation : Sample(8),
      volume                    : Sample(8) ]

EncodeProbablePriceOfAllocationMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.probablePriceOfAllocation
        \o message.volume

DecodeProbablePriceOfAllocationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET probablePriceOfAllocation == ReadBytes(origin.rest, 8) IN IF ~probablePriceOfAllocation.ok THEN Fail ELSE
    LET volume == ReadBytes(probablePriceOfAllocation.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    Ok([ instrumentNumber          |-> instrumentNumber.value,
         origin                    |-> origin.value,
         probablePriceOfAllocation |-> probablePriceOfAllocation.value,
         volume                    |-> volume.value ], volume.rest)

ZeroProbablePriceOfAllocationMessage ==
    [ instrumentNumber          |-> [i \in 1 .. 4 |-> 0],
      origin                    |-> [i \in 1 .. 1 |-> 0],
      probablePriceOfAllocation |-> [i \in 1 .. 8 |-> 0],
      volume                    |-> [i \in 1 .. 8 |-> 0] ]

(* Probable Price Of Allocation Message at zero, then each field in turn at the values it is checked at *)
CheckedProbablePriceOfAllocationMessage ==
    { ZeroProbablePriceOfAllocationMessage }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.probablePriceOfAllocation = one] : one \in Sample(8) }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.volume = one] : one \in Sample(8) }

(***************************************************************************)
(* Relation Between Bmvbiva Instruments Message: 9 bytes                   *)
(***************************************************************************)

RelationBetweenBmvbivaInstrumentsMessage ==
    [ numberOfTheBmvInstrument : Sample(4),
      bivaInstrument           : Sample(4),
      typeOfTrading            : Sample(1) ]

EncodeRelationBetweenBmvbivaInstrumentsMessage(message) ==
    message.numberOfTheBmvInstrument
        \o message.bivaInstrument
        \o message.typeOfTrading

DecodeRelationBetweenBmvbivaInstrumentsMessage(bytes) ==
    LET numberOfTheBmvInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheBmvInstrument.ok THEN Fail ELSE
    LET bivaInstrument == ReadBytes(numberOfTheBmvInstrument.rest, 4) IN IF ~bivaInstrument.ok THEN Fail ELSE
    LET typeOfTrading == ReadBytes(bivaInstrument.rest, 1) IN IF ~typeOfTrading.ok THEN Fail ELSE
    Ok([ numberOfTheBmvInstrument |-> numberOfTheBmvInstrument.value,
         bivaInstrument           |-> bivaInstrument.value,
         typeOfTrading            |-> typeOfTrading.value ], typeOfTrading.rest)

ZeroRelationBetweenBmvbivaInstrumentsMessage ==
    [ numberOfTheBmvInstrument |-> [i \in 1 .. 4 |-> 0],
      bivaInstrument           |-> [i \in 1 .. 4 |-> 0],
      typeOfTrading            |-> [i \in 1 .. 1 |-> 0] ]

(* Relation Between Bmvbiva Instruments Message at zero, then each field in turn at the values it is checked at *)
CheckedRelationBetweenBmvbivaInstrumentsMessage ==
    { ZeroRelationBetweenBmvbivaInstrumentsMessage }
        \cup { [ZeroRelationBetweenBmvbivaInstrumentsMessage EXCEPT !.numberOfTheBmvInstrument = one] : one \in Sample(4) }
        \cup { [ZeroRelationBetweenBmvbivaInstrumentsMessage EXCEPT !.bivaInstrument = one] : one \in Sample(4) }
        \cup { [ZeroRelationBetweenBmvbivaInstrumentsMessage EXCEPT !.typeOfTrading = one] : one \in Sample(1) }

(***************************************************************************)
(* Equities Market Trades Message: 61 bytes                                *)
(***************************************************************************)

EquitiesMarketTradesMessage ==
    [ instrumentNumber            : Sample(4),
      origin                      : Sample(1),
      timeOfTheTrade              : Sample(8),
      volume                      : Sample(8),
      price                       : Sample(8),
      typeOfAgreement             : Sample(1),
      consecutiveNumberOfTheTrade : Sample(8),
      setsPrice                   : Sample(1),
      typeOfTrading               : Sample(1),
      amount                      : Sample(8),
      purchases                   : Sample(5),
      sells                       : Sample(5),
      settlement                  : Sample(1),
      auctionIndicator            : Sample(1),
      indicator                   : Sample(1) ]

EncodeEquitiesMarketTradesMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.timeOfTheTrade
        \o message.volume
        \o message.price
        \o message.typeOfAgreement
        \o message.consecutiveNumberOfTheTrade
        \o message.setsPrice
        \o message.typeOfTrading
        \o message.amount
        \o message.purchases
        \o message.sells
        \o message.settlement
        \o message.auctionIndicator
        \o message.indicator

DecodeEquitiesMarketTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET timeOfTheTrade == ReadBytes(origin.rest, 8) IN IF ~timeOfTheTrade.ok THEN Fail ELSE
    LET volume == ReadBytes(timeOfTheTrade.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET typeOfAgreement == ReadBytes(price.rest, 1) IN IF ~typeOfAgreement.ok THEN Fail ELSE
    LET consecutiveNumberOfTheTrade == ReadBytes(typeOfAgreement.rest, 8) IN IF ~consecutiveNumberOfTheTrade.ok THEN Fail ELSE
    LET setsPrice == ReadBytes(consecutiveNumberOfTheTrade.rest, 1) IN IF ~setsPrice.ok THEN Fail ELSE
    LET typeOfTrading == ReadBytes(setsPrice.rest, 1) IN IF ~typeOfTrading.ok THEN Fail ELSE
    LET amount == ReadBytes(typeOfTrading.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    LET purchases == ReadBytes(amount.rest, 5) IN IF ~purchases.ok THEN Fail ELSE
    LET sells == ReadBytes(purchases.rest, 5) IN IF ~sells.ok THEN Fail ELSE
    LET settlement == ReadBytes(sells.rest, 1) IN IF ~settlement.ok THEN Fail ELSE
    LET auctionIndicator == ReadBytes(settlement.rest, 1) IN IF ~auctionIndicator.ok THEN Fail ELSE
    LET indicator == ReadBytes(auctionIndicator.rest, 1) IN IF ~indicator.ok THEN Fail ELSE
    Ok([ instrumentNumber            |-> instrumentNumber.value,
         origin                      |-> origin.value,
         timeOfTheTrade              |-> timeOfTheTrade.value,
         volume                      |-> volume.value,
         price                       |-> price.value,
         typeOfAgreement             |-> typeOfAgreement.value,
         consecutiveNumberOfTheTrade |-> consecutiveNumberOfTheTrade.value,
         setsPrice                   |-> setsPrice.value,
         typeOfTrading               |-> typeOfTrading.value,
         amount                      |-> amount.value,
         purchases                   |-> purchases.value,
         sells                       |-> sells.value,
         settlement                  |-> settlement.value,
         auctionIndicator            |-> auctionIndicator.value,
         indicator                   |-> indicator.value ], indicator.rest)

ZeroEquitiesMarketTradesMessage ==
    [ instrumentNumber            |-> [i \in 1 .. 4 |-> 0],
      origin                      |-> [i \in 1 .. 1 |-> 0],
      timeOfTheTrade              |-> [i \in 1 .. 8 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      typeOfAgreement             |-> [i \in 1 .. 1 |-> 0],
      consecutiveNumberOfTheTrade |-> [i \in 1 .. 8 |-> 0],
      setsPrice                   |-> [i \in 1 .. 1 |-> 0],
      typeOfTrading               |-> [i \in 1 .. 1 |-> 0],
      amount                      |-> [i \in 1 .. 8 |-> 0],
      purchases                   |-> [i \in 1 .. 5 |-> 0],
      sells                       |-> [i \in 1 .. 5 |-> 0],
      settlement                  |-> [i \in 1 .. 1 |-> 0],
      auctionIndicator            |-> [i \in 1 .. 1 |-> 0],
      indicator                   |-> [i \in 1 .. 1 |-> 0] ]

(* Equities Market Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedEquitiesMarketTradesMessage ==
    { ZeroEquitiesMarketTradesMessage }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.timeOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.typeOfAgreement = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.consecutiveNumberOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.setsPrice = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.typeOfTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.amount = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.purchases = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.sells = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.settlement = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.auctionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.indicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Consolidated Trade Cancellation Message: 13 bytes                       *)
(***************************************************************************)

ConsolidatedTradeCancellationMessage ==
    [ instrumentNumber            : Sample(4),
      origin                      : Sample(1),
      consecutiveNumberOfTheTrade : Sample(8) ]

EncodeConsolidatedTradeCancellationMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.consecutiveNumberOfTheTrade

DecodeConsolidatedTradeCancellationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET consecutiveNumberOfTheTrade == ReadBytes(origin.rest, 8) IN IF ~consecutiveNumberOfTheTrade.ok THEN Fail ELSE
    Ok([ instrumentNumber            |-> instrumentNumber.value,
         origin                      |-> origin.value,
         consecutiveNumberOfTheTrade |-> consecutiveNumberOfTheTrade.value ], consecutiveNumberOfTheTrade.rest)

ZeroConsolidatedTradeCancellationMessage ==
    [ instrumentNumber            |-> [i \in 1 .. 4 |-> 0],
      origin                      |-> [i \in 1 .. 1 |-> 0],
      consecutiveNumberOfTheTrade |-> [i \in 1 .. 8 |-> 0] ]

(* Consolidated Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedTradeCancellationMessage ==
    { ZeroConsolidatedTradeCancellationMessage }
        \cup { [ZeroConsolidatedTradeCancellationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancellationMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeCancellationMessage EXCEPT !.consecutiveNumberOfTheTrade = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

MutualFundsTradesMessageCode == 40  \* 0x28
OpeningOfContinuousAuctionsMessageCode == 41  \* 0x29
ExistenceOfBidsAtMidPriceMessageCode == 44  \* 0x2c
CatalogueOfDebtAndMetalsInstrumentsMessageCode == 46  \* 0x2e
CatalogSentForInstrumentsBelongingToMutualFundsMessageCode == 48  \* 0x30
WeightedAveragePriceMessageCode == 54  \* 0x36
SystemEventsMessageCode == 55  \* 0x37
ReferencePriceMessageCode == 56  \* 0x38
ChangesInStatusMessageCode == 57  \* 0x39
CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode == 84  \* 0x54
CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode == 91  \* 0x5b
ConsolidatedInavMessageCode == 93  \* 0x5d
CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode == 104  \* 0x68
ProbablePriceOfAllocationMessageCode == 105  \* 0x69
RelationBetweenBmvbivaInstrumentsMessageCode == 106  \* 0x6a
EquitiesMarketTradesMessageCode == 112  \* 0x70
ConsolidatedTradeCancellationMessageCode == 113  \* 0x71

Payload ==
    [ tag : {MutualFundsTradesMessageCode}, body : MutualFundsTradesMessage ]
        \cup [ tag : {OpeningOfContinuousAuctionsMessageCode}, body : OpeningOfContinuousAuctionsMessage ]
        \cup [ tag : {ExistenceOfBidsAtMidPriceMessageCode}, body : ExistenceOfBidsAtMidPriceMessage ]
        \cup [ tag : {CatalogueOfDebtAndMetalsInstrumentsMessageCode}, body : CatalogueOfDebtAndMetalsInstrumentsMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToMutualFundsMessageCode}, body : CatalogSentForInstrumentsBelongingToMutualFundsMessage ]
        \cup [ tag : {WeightedAveragePriceMessageCode}, body : WeightedAveragePriceMessage ]
        \cup [ tag : {SystemEventsMessageCode}, body : SystemEventsMessage ]
        \cup [ tag : {ReferencePriceMessageCode}, body : ReferencePriceMessage ]
        \cup [ tag : {ChangesInStatusMessageCode}, body : ChangesInStatusMessage ]
        \cup [ tag : {CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode}, body : CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode}, body : CatalogSentForInstrumentsBelongingToCapitalTracsMessage ]
        \cup [ tag : {ConsolidatedInavMessageCode}, body : ConsolidatedInavMessage ]
        \cup [ tag : {CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode}, body : CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ]
        \cup [ tag : {ProbablePriceOfAllocationMessageCode}, body : ProbablePriceOfAllocationMessage ]
        \cup [ tag : {RelationBetweenBmvbivaInstrumentsMessageCode}, body : RelationBetweenBmvbivaInstrumentsMessage ]
        \cup [ tag : {EquitiesMarketTradesMessageCode}, body : EquitiesMarketTradesMessage ]
        \cup [ tag : {ConsolidatedTradeCancellationMessageCode}, body : ConsolidatedTradeCancellationMessage ]

EncodePayload(message) ==
    CASE message.tag = MutualFundsTradesMessageCode -> EncodeMutualFundsTradesMessage(message.body)
      [] message.tag = OpeningOfContinuousAuctionsMessageCode -> EncodeOpeningOfContinuousAuctionsMessage(message.body)
      [] message.tag = ExistenceOfBidsAtMidPriceMessageCode -> EncodeExistenceOfBidsAtMidPriceMessage(message.body)
      [] message.tag = CatalogueOfDebtAndMetalsInstrumentsMessageCode -> EncodeCatalogueOfDebtAndMetalsInstrumentsMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToMutualFundsMessageCode -> EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message.body)
      [] message.tag = WeightedAveragePriceMessageCode -> EncodeWeightedAveragePriceMessage(message.body)
      [] message.tag = SystemEventsMessageCode -> EncodeSystemEventsMessage(message.body)
      [] message.tag = ReferencePriceMessageCode -> EncodeReferencePriceMessage(message.body)
      [] message.tag = ChangesInStatusMessageCode -> EncodeChangesInStatusMessage(message.body)
      [] message.tag = CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode -> EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode -> EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message.body)
      [] message.tag = ConsolidatedInavMessageCode -> EncodeConsolidatedInavMessage(message.body)
      [] message.tag = CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode -> EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message.body)
      [] message.tag = ProbablePriceOfAllocationMessageCode -> EncodeProbablePriceOfAllocationMessage(message.body)
      [] message.tag = RelationBetweenBmvbivaInstrumentsMessageCode -> EncodeRelationBetweenBmvbivaInstrumentsMessage(message.body)
      [] message.tag = EquitiesMarketTradesMessageCode -> EncodeEquitiesMarketTradesMessage(message.body)
      [] message.tag = ConsolidatedTradeCancellationMessageCode -> EncodeConsolidatedTradeCancellationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MutualFundsTradesMessageCode -> DecodeMutualFundsTradesMessage(bytes)
              [] tag = OpeningOfContinuousAuctionsMessageCode -> DecodeOpeningOfContinuousAuctionsMessage(bytes)
              [] tag = ExistenceOfBidsAtMidPriceMessageCode -> DecodeExistenceOfBidsAtMidPriceMessage(bytes)
              [] tag = CatalogueOfDebtAndMetalsInstrumentsMessageCode -> DecodeCatalogueOfDebtAndMetalsInstrumentsMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToMutualFundsMessageCode -> DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(bytes)
              [] tag = WeightedAveragePriceMessageCode -> DecodeWeightedAveragePriceMessage(bytes)
              [] tag = SystemEventsMessageCode -> DecodeSystemEventsMessage(bytes)
              [] tag = ReferencePriceMessageCode -> DecodeReferencePriceMessage(bytes)
              [] tag = ChangesInStatusMessageCode -> DecodeChangesInStatusMessage(bytes)
              [] tag = CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode -> DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode -> DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(bytes)
              [] tag = ConsolidatedInavMessageCode -> DecodeConsolidatedInavMessage(bytes)
              [] tag = CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode -> DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(bytes)
              [] tag = ProbablePriceOfAllocationMessageCode -> DecodeProbablePriceOfAllocationMessage(bytes)
              [] tag = RelationBetweenBmvbivaInstrumentsMessageCode -> DecodeRelationBetweenBmvbivaInstrumentsMessage(bytes)
              [] tag = EquitiesMarketTradesMessageCode -> DecodeEquitiesMarketTradesMessage(bytes)
              [] tag = ConsolidatedTradeCancellationMessageCode -> DecodeConsolidatedTradeCancellationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MutualFundsTradesMessageCode, body |-> ZeroMutualFundsTradesMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MutualFundsTradesMessageCode, body |-> one] : one \in CheckedMutualFundsTradesMessage }
        \cup { [tag |-> OpeningOfContinuousAuctionsMessageCode, body |-> one] : one \in CheckedOpeningOfContinuousAuctionsMessage }
        \cup { [tag |-> ExistenceOfBidsAtMidPriceMessageCode, body |-> one] : one \in CheckedExistenceOfBidsAtMidPriceMessage }
        \cup { [tag |-> CatalogueOfDebtAndMetalsInstrumentsMessageCode, body |-> one] : one \in CheckedCatalogueOfDebtAndMetalsInstrumentsMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToMutualFundsMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage }
        \cup { [tag |-> WeightedAveragePriceMessageCode, body |-> one] : one \in CheckedWeightedAveragePriceMessage }
        \cup { [tag |-> SystemEventsMessageCode, body |-> one] : one \in CheckedSystemEventsMessage }
        \cup { [tag |-> ReferencePriceMessageCode, body |-> one] : one \in CheckedReferencePriceMessage }
        \cup { [tag |-> ChangesInStatusMessageCode, body |-> one] : one \in CheckedChangesInStatusMessage }
        \cup { [tag |-> CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode, body |-> one] : one \in CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage }
        \cup { [tag |-> ConsolidatedInavMessageCode, body |-> one] : one \in CheckedConsolidatedInavMessage }
        \cup { [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> one] : one \in CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage }
        \cup { [tag |-> ProbablePriceOfAllocationMessageCode, body |-> one] : one \in CheckedProbablePriceOfAllocationMessage }
        \cup { [tag |-> RelationBetweenBmvbivaInstrumentsMessageCode, body |-> one] : one \in CheckedRelationBetweenBmvbivaInstrumentsMessage }
        \cup { [tag |-> EquitiesMarketTradesMessageCode, body |-> one] : one \in CheckedEquitiesMarketTradesMessage }
        \cup { [tag |-> ConsolidatedTradeCancellationMessageCode, body |-> one] : one \in CheckedConsolidatedTradeCancellationMessage }

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
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> MutualFundsTradesMessageCode, body |-> ZeroMutualFundsTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OpeningOfContinuousAuctionsMessageCode, body |-> ZeroOpeningOfContinuousAuctionsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ExistenceOfBidsAtMidPriceMessageCode, body |-> ZeroExistenceOfBidsAtMidPriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogueOfDebtAndMetalsInstrumentsMessageCode, body |-> ZeroCatalogueOfDebtAndMetalsInstrumentsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToMutualFundsMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> WeightedAveragePriceMessageCode, body |-> ZeroWeightedAveragePriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> SystemEventsMessageCode, body |-> ZeroSystemEventsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ReferencePriceMessageCode, body |-> ZeroReferencePriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ChangesInStatusMessageCode, body |-> ZeroChangesInStatusMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ConsolidatedInavMessageCode, body |-> ZeroConsolidatedInavMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ProbablePriceOfAllocationMessageCode, body |-> ZeroProbablePriceOfAllocationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> RelationBetweenBmvbivaInstrumentsMessageCode, body |-> ZeroRelationBetweenBmvbivaInstrumentsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> EquitiesMarketTradesMessageCode, body |-> ZeroEquitiesMarketTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ConsolidatedTradeCancellationMessageCode, body |-> ZeroConsolidatedTradeCancellationMessage]] }

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

(* Every Mutual Funds Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMutualFundsTradesMessage ==
    \A message \in CheckedMutualFundsTradesMessage :
        LET read == DecodeMutualFundsTradesMessage(EncodeMutualFundsTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Of Continuous Auctions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningOfContinuousAuctionsMessage ==
    \A message \in CheckedOpeningOfContinuousAuctionsMessage :
        LET read == DecodeOpeningOfContinuousAuctionsMessage(EncodeOpeningOfContinuousAuctionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Existence Of Bids At Mid Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExistenceOfBidsAtMidPriceMessage ==
    \A message \in CheckedExistenceOfBidsAtMidPriceMessage :
        LET read == DecodeExistenceOfBidsAtMidPriceMessage(EncodeExistenceOfBidsAtMidPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalogue Of Debt And Metals Instruments Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogueOfDebtAndMetalsInstrumentsMessage ==
    \A message \in CheckedCatalogueOfDebtAndMetalsInstrumentsMessage :
        LET read == DecodeCatalogueOfDebtAndMetalsInstrumentsMessage(EncodeCatalogueOfDebtAndMetalsInstrumentsMessage(message))
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

(* Every Weighted Average Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedAveragePriceMessage ==
    \A message \in CheckedWeightedAveragePriceMessage :
        LET read == DecodeWeightedAveragePriceMessage(EncodeWeightedAveragePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Events Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventsMessage ==
    \A message \in CheckedSystemEventsMessage :
        LET read == DecodeSystemEventsMessage(EncodeSystemEventsMessage(message))
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

(* Every Changes In Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripChangesInStatusMessage ==
    \A message \in CheckedChangesInStatusMessage :
        LET read == DecodeChangesInStatusMessage(EncodeChangesInStatusMessage(message))
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

(* Every Catalog Sent For Instruments Belonging To Capital Tracs Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    \A message \in CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage :
        LET read == DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Inav Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedInavMessage ==
    \A message \in CheckedConsolidatedInavMessage :
        LET read == DecodeConsolidatedInavMessage(EncodeConsolidatedInavMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog For Instruments Belonging To The Local And Global Stock Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    \A message \in CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage :
        LET read == DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Probable Price Of Allocation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProbablePriceOfAllocationMessage ==
    \A message \in CheckedProbablePriceOfAllocationMessage :
        LET read == DecodeProbablePriceOfAllocationMessage(EncodeProbablePriceOfAllocationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Relation Between Bmvbiva Instruments Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRelationBetweenBmvbivaInstrumentsMessage ==
    \A message \in CheckedRelationBetweenBmvbivaInstrumentsMessage :
        LET read == DecodeRelationBetweenBmvbivaInstrumentsMessage(EncodeRelationBetweenBmvbivaInstrumentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equities Market Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquitiesMarketTradesMessage ==
    \A message \in CheckedEquitiesMarketTradesMessage :
        LET read == DecodeEquitiesMarketTradesMessage(EncodeEquitiesMarketTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedTradeCancellationMessage ==
    \A message \in CheckedConsolidatedTradeCancellationMessage :
        LET read == DecodeConsolidatedTradeCancellationMessage(EncodeConsolidatedTradeCancellationMessage(message))
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
