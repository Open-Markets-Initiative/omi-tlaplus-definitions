-------------------------- MODULE Tsx_Level1_v2_8 --------------------------
(***************************************************************************)
(* TMX Group Level 1 v2.8                                                  *)
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
(* Trade Message: 105 bytes                                                *)
(***************************************************************************)

TradeMessage ==
    [ symbol                 : Sample(12),
      volume                 : Sample(9),
      tradePrice             : Sample(11),
      buyerId                : Sample(3),
      sellerId               : Sample(3),
      tradeTimeStamp         : Sample(6),
      lastSale               : Sample(11),
      tradeId                : Sample(9),
      crossType              : Sample(1),
      moc                    : Sample(1),
      bypass                 : Sample(1),
      openingTrade           : Sample(1),
      settlementTerms        : Sample(1),
      tradingSystemTimeStamp : Sample(23),
      listingMarket          : Sample(1),
      productType            : Sample(1),
      tradeDate              : Sample(8),
      isMidOnly              : Sample(1),
      isDark                 : Sample(1),
      isConditional          : Sample(1) ]

EncodeTradeMessage(message) ==
    message.symbol
        \o message.volume
        \o message.tradePrice
        \o message.buyerId
        \o message.sellerId
        \o message.tradeTimeStamp
        \o message.lastSale
        \o message.tradeId
        \o message.crossType
        \o message.moc
        \o message.bypass
        \o message.openingTrade
        \o message.settlementTerms
        \o message.tradingSystemTimeStamp
        \o message.listingMarket
        \o message.productType
        \o message.tradeDate
        \o message.isMidOnly
        \o message.isDark
        \o message.isConditional

DecodeTradeMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 9) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 11) IN IF ~tradePrice.ok THEN Fail ELSE
    LET buyerId == ReadBytes(tradePrice.rest, 3) IN IF ~buyerId.ok THEN Fail ELSE
    LET sellerId == ReadBytes(buyerId.rest, 3) IN IF ~sellerId.ok THEN Fail ELSE
    LET tradeTimeStamp == ReadBytes(sellerId.rest, 6) IN IF ~tradeTimeStamp.ok THEN Fail ELSE
    LET lastSale == ReadBytes(tradeTimeStamp.rest, 11) IN IF ~lastSale.ok THEN Fail ELSE
    LET tradeId == ReadBytes(lastSale.rest, 9) IN IF ~tradeId.ok THEN Fail ELSE
    LET crossType == ReadBytes(tradeId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET moc == ReadBytes(crossType.rest, 1) IN IF ~moc.ok THEN Fail ELSE
    LET bypass == ReadBytes(moc.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(bypass.rest, 1) IN IF ~openingTrade.ok THEN Fail ELSE
    LET settlementTerms == ReadBytes(openingTrade.rest, 1) IN IF ~settlementTerms.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(settlementTerms.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(tradingSystemTimeStamp.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET productType == ReadBytes(listingMarket.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(productType.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET isMidOnly == ReadBytes(tradeDate.rest, 1) IN IF ~isMidOnly.ok THEN Fail ELSE
    LET isDark == ReadBytes(isMidOnly.rest, 1) IN IF ~isDark.ok THEN Fail ELSE
    LET isConditional == ReadBytes(isDark.rest, 1) IN IF ~isConditional.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         volume                 |-> volume.value,
         tradePrice             |-> tradePrice.value,
         buyerId                |-> buyerId.value,
         sellerId               |-> sellerId.value,
         tradeTimeStamp         |-> tradeTimeStamp.value,
         lastSale               |-> lastSale.value,
         tradeId                |-> tradeId.value,
         crossType              |-> crossType.value,
         moc                    |-> moc.value,
         bypass                 |-> bypass.value,
         openingTrade           |-> openingTrade.value,
         settlementTerms        |-> settlementTerms.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         listingMarket          |-> listingMarket.value,
         productType            |-> productType.value,
         tradeDate              |-> tradeDate.value,
         isMidOnly              |-> isMidOnly.value,
         isDark                 |-> isDark.value,
         isConditional          |-> isConditional.value ], isConditional.rest)

ZeroTradeMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      volume                 |-> [i \in 1 .. 9 |-> 0],
      tradePrice             |-> [i \in 1 .. 11 |-> 0],
      buyerId                |-> [i \in 1 .. 3 |-> 0],
      sellerId               |-> [i \in 1 .. 3 |-> 0],
      tradeTimeStamp         |-> [i \in 1 .. 6 |-> 0],
      lastSale               |-> [i \in 1 .. 11 |-> 0],
      tradeId                |-> [i \in 1 .. 9 |-> 0],
      crossType              |-> [i \in 1 .. 1 |-> 0],
      moc                    |-> [i \in 1 .. 1 |-> 0],
      bypass                 |-> [i \in 1 .. 1 |-> 0],
      openingTrade           |-> [i \in 1 .. 1 |-> 0],
      settlementTerms        |-> [i \in 1 .. 1 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      listingMarket          |-> [i \in 1 .. 1 |-> 0],
      productType            |-> [i \in 1 .. 1 |-> 0],
      tradeDate              |-> [i \in 1 .. 8 |-> 0],
      isMidOnly              |-> [i \in 1 .. 1 |-> 0],
      isDark                 |-> [i \in 1 .. 1 |-> 0],
      isConditional          |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.volume = one] : one \in Sample(9) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeMessage EXCEPT !.buyerId = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.sellerId = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeTimeStamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.lastSale = one] : one \in Sample(11) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(9) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.moc = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.openingTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.settlementTerms = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroTradeMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.isMidOnly = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.isDark = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.isConditional = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Status Message: 164 bytes                                        *)
(***************************************************************************)

SymbolStatusMessage ==
    [ symbol                 : Sample(12),
      tradingSystemTimeStamp : Sample(23),
      exchangeId             : Sample(3),
      cusip                  : Sample(12),
      boardLot               : Sample(9),
      currency               : Sample(1),
      faceValue              : Sample(9),
      lastSale               : Sample(11),
      mocEligible            : Sample(1),
      productType            : Sample(1),
      symbolName             : Sample(40),
      stockGroup             : Sample(2),
      stockState             : Sample(2),
      listingMarket          : Sample(1),
      buyMaximumQuantity     : Sample(9),
      buyMinimumQuantity     : Sample(9),
      sellMaximumQuantity    : Sample(9),
      sellMinimumQuantity    : Sample(9),
      testSymbol             : Sample(1) ]

EncodeSymbolStatusMessage(message) ==
    message.symbol
        \o message.tradingSystemTimeStamp
        \o message.exchangeId
        \o message.cusip
        \o message.boardLot
        \o message.currency
        \o message.faceValue
        \o message.lastSale
        \o message.mocEligible
        \o message.productType
        \o message.symbolName
        \o message.stockGroup
        \o message.stockState
        \o message.listingMarket
        \o message.buyMaximumQuantity
        \o message.buyMinimumQuantity
        \o message.sellMaximumQuantity
        \o message.sellMinimumQuantity
        \o message.testSymbol

DecodeSymbolStatusMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(symbol.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(tradingSystemTimeStamp.rest, 3) IN IF ~exchangeId.ok THEN Fail ELSE
    LET cusip == ReadBytes(exchangeId.rest, 12) IN IF ~cusip.ok THEN Fail ELSE
    LET boardLot == ReadBytes(cusip.rest, 9) IN IF ~boardLot.ok THEN Fail ELSE
    LET currency == ReadBytes(boardLot.rest, 1) IN IF ~currency.ok THEN Fail ELSE
    LET faceValue == ReadBytes(currency.rest, 9) IN IF ~faceValue.ok THEN Fail ELSE
    LET lastSale == ReadBytes(faceValue.rest, 11) IN IF ~lastSale.ok THEN Fail ELSE
    LET mocEligible == ReadBytes(lastSale.rest, 1) IN IF ~mocEligible.ok THEN Fail ELSE
    LET productType == ReadBytes(mocEligible.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET symbolName == ReadBytes(productType.rest, 40) IN IF ~symbolName.ok THEN Fail ELSE
    LET stockGroup == ReadBytes(symbolName.rest, 2) IN IF ~stockGroup.ok THEN Fail ELSE
    LET stockState == ReadBytes(stockGroup.rest, 2) IN IF ~stockState.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(stockState.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET buyMaximumQuantity == ReadBytes(listingMarket.rest, 9) IN IF ~buyMaximumQuantity.ok THEN Fail ELSE
    LET buyMinimumQuantity == ReadBytes(buyMaximumQuantity.rest, 9) IN IF ~buyMinimumQuantity.ok THEN Fail ELSE
    LET sellMaximumQuantity == ReadBytes(buyMinimumQuantity.rest, 9) IN IF ~sellMaximumQuantity.ok THEN Fail ELSE
    LET sellMinimumQuantity == ReadBytes(sellMaximumQuantity.rest, 9) IN IF ~sellMinimumQuantity.ok THEN Fail ELSE
    LET testSymbol == ReadBytes(sellMinimumQuantity.rest, 1) IN IF ~testSymbol.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         exchangeId             |-> exchangeId.value,
         cusip                  |-> cusip.value,
         boardLot               |-> boardLot.value,
         currency               |-> currency.value,
         faceValue              |-> faceValue.value,
         lastSale               |-> lastSale.value,
         mocEligible            |-> mocEligible.value,
         productType            |-> productType.value,
         symbolName             |-> symbolName.value,
         stockGroup             |-> stockGroup.value,
         stockState             |-> stockState.value,
         listingMarket          |-> listingMarket.value,
         buyMaximumQuantity     |-> buyMaximumQuantity.value,
         buyMinimumQuantity     |-> buyMinimumQuantity.value,
         sellMaximumQuantity    |-> sellMaximumQuantity.value,
         sellMinimumQuantity    |-> sellMinimumQuantity.value,
         testSymbol             |-> testSymbol.value ], testSymbol.rest)

ZeroSymbolStatusMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      exchangeId             |-> [i \in 1 .. 3 |-> 0],
      cusip                  |-> [i \in 1 .. 12 |-> 0],
      boardLot               |-> [i \in 1 .. 9 |-> 0],
      currency               |-> [i \in 1 .. 1 |-> 0],
      faceValue              |-> [i \in 1 .. 9 |-> 0],
      lastSale               |-> [i \in 1 .. 11 |-> 0],
      mocEligible            |-> [i \in 1 .. 1 |-> 0],
      productType            |-> [i \in 1 .. 1 |-> 0],
      symbolName             |-> [i \in 1 .. 40 |-> 0],
      stockGroup             |-> [i \in 1 .. 2 |-> 0],
      stockState             |-> [i \in 1 .. 2 |-> 0],
      listingMarket          |-> [i \in 1 .. 1 |-> 0],
      buyMaximumQuantity     |-> [i \in 1 .. 9 |-> 0],
      buyMinimumQuantity     |-> [i \in 1 .. 9 |-> 0],
      sellMaximumQuantity    |-> [i \in 1 .. 9 |-> 0],
      sellMinimumQuantity    |-> [i \in 1 .. 9 |-> 0],
      testSymbol             |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(3) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.cusip = one] : one \in Sample(12) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.boardLot = one] : one \in Sample(9) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.faceValue = one] : one \in Sample(9) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.lastSale = one] : one \in Sample(11) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.mocEligible = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbolName = one] : one \in Sample(40) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.stockGroup = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.stockState = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.buyMaximumQuantity = one] : one \in Sample(9) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.buyMinimumQuantity = one] : one \in Sample(9) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.sellMaximumQuantity = one] : one \in Sample(9) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.sellMinimumQuantity = one] : one \in Sample(9) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.testSymbol = one] : one \in Sample(1) }

(***************************************************************************)
(* Moc Imbalance Notification Message: 102 bytes                           *)
(***************************************************************************)

MocImbalanceNotificationMessage ==
    [ symbol                     : Sample(12),
      imbalanceSide              : Sample(1),
      imbalanceVolume            : Sample(9),
      imbalanceReferencePrice    : Sample(11),
      pairedVolume               : Sample(9),
      marketOrderImbalanceVolume : Sample(9),
      marketOrderImbalanceSide   : Sample(1),
      nearIndicativeClosingPrice : Sample(11),
      farIndicativeClosingPrice  : Sample(11),
      priceVariation             : Sample(5),
      tradingSystemTimeStamp     : Sample(23) ]

EncodeMocImbalanceNotificationMessage(message) ==
    message.symbol
        \o message.imbalanceSide
        \o message.imbalanceVolume
        \o message.imbalanceReferencePrice
        \o message.pairedVolume
        \o message.marketOrderImbalanceVolume
        \o message.marketOrderImbalanceSide
        \o message.nearIndicativeClosingPrice
        \o message.farIndicativeClosingPrice
        \o message.priceVariation
        \o message.tradingSystemTimeStamp

DecodeMocImbalanceNotificationMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(symbol.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(imbalanceSide.rest, 9) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET imbalanceReferencePrice == ReadBytes(imbalanceVolume.rest, 11) IN IF ~imbalanceReferencePrice.ok THEN Fail ELSE
    LET pairedVolume == ReadBytes(imbalanceReferencePrice.rest, 9) IN IF ~pairedVolume.ok THEN Fail ELSE
    LET marketOrderImbalanceVolume == ReadBytes(pairedVolume.rest, 9) IN IF ~marketOrderImbalanceVolume.ok THEN Fail ELSE
    LET marketOrderImbalanceSide == ReadBytes(marketOrderImbalanceVolume.rest, 1) IN IF ~marketOrderImbalanceSide.ok THEN Fail ELSE
    LET nearIndicativeClosingPrice == ReadBytes(marketOrderImbalanceSide.rest, 11) IN IF ~nearIndicativeClosingPrice.ok THEN Fail ELSE
    LET farIndicativeClosingPrice == ReadBytes(nearIndicativeClosingPrice.rest, 11) IN IF ~farIndicativeClosingPrice.ok THEN Fail ELSE
    LET priceVariation == ReadBytes(farIndicativeClosingPrice.rest, 5) IN IF ~priceVariation.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(priceVariation.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    Ok([ symbol                     |-> symbol.value,
         imbalanceSide              |-> imbalanceSide.value,
         imbalanceVolume            |-> imbalanceVolume.value,
         imbalanceReferencePrice    |-> imbalanceReferencePrice.value,
         pairedVolume               |-> pairedVolume.value,
         marketOrderImbalanceVolume |-> marketOrderImbalanceVolume.value,
         marketOrderImbalanceSide   |-> marketOrderImbalanceSide.value,
         nearIndicativeClosingPrice |-> nearIndicativeClosingPrice.value,
         farIndicativeClosingPrice  |-> farIndicativeClosingPrice.value,
         priceVariation             |-> priceVariation.value,
         tradingSystemTimeStamp     |-> tradingSystemTimeStamp.value ], tradingSystemTimeStamp.rest)

ZeroMocImbalanceNotificationMessage ==
    [ symbol                     |-> [i \in 1 .. 12 |-> 0],
      imbalanceSide              |-> [i \in 1 .. 1 |-> 0],
      imbalanceVolume            |-> [i \in 1 .. 9 |-> 0],
      imbalanceReferencePrice    |-> [i \in 1 .. 11 |-> 0],
      pairedVolume               |-> [i \in 1 .. 9 |-> 0],
      marketOrderImbalanceVolume |-> [i \in 1 .. 9 |-> 0],
      marketOrderImbalanceSide   |-> [i \in 1 .. 1 |-> 0],
      nearIndicativeClosingPrice |-> [i \in 1 .. 11 |-> 0],
      farIndicativeClosingPrice  |-> [i \in 1 .. 11 |-> 0],
      priceVariation             |-> [i \in 1 .. 5 |-> 0],
      tradingSystemTimeStamp     |-> [i \in 1 .. 23 |-> 0] ]

(* Moc Imbalance Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedMocImbalanceNotificationMessage ==
    { ZeroMocImbalanceNotificationMessage }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(9) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.imbalanceReferencePrice = one] : one \in Sample(11) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.pairedVolume = one] : one \in Sample(9) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.marketOrderImbalanceVolume = one] : one \in Sample(9) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.marketOrderImbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.nearIndicativeClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.farIndicativeClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.priceVariation = one] : one \in Sample(5) }
        \cup { [ZeroMocImbalanceNotificationMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }

(***************************************************************************)
(* Moc Price Movement Delay Message: 59 bytes                              *)
(***************************************************************************)

MocPriceMovementDelayMessage ==
    [ symbol                 : Sample(12),
      tradingSystemTimeStamp : Sample(23),
      stockState             : Sample(2),
      ccp                    : Sample(11),
      vwap                   : Sample(11) ]

EncodeMocPriceMovementDelayMessage(message) ==
    message.symbol
        \o message.tradingSystemTimeStamp
        \o message.stockState
        \o message.ccp
        \o message.vwap

DecodeMocPriceMovementDelayMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(symbol.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET stockState == ReadBytes(tradingSystemTimeStamp.rest, 2) IN IF ~stockState.ok THEN Fail ELSE
    LET ccp == ReadBytes(stockState.rest, 11) IN IF ~ccp.ok THEN Fail ELSE
    LET vwap == ReadBytes(ccp.rest, 11) IN IF ~vwap.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         stockState             |-> stockState.value,
         ccp                    |-> ccp.value,
         vwap                   |-> vwap.value ], vwap.rest)

ZeroMocPriceMovementDelayMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      stockState             |-> [i \in 1 .. 2 |-> 0],
      ccp                    |-> [i \in 1 .. 11 |-> 0],
      vwap                   |-> [i \in 1 .. 11 |-> 0] ]

(* Moc Price Movement Delay Message at zero, then each field in turn at the values it is checked at *)
CheckedMocPriceMovementDelayMessage ==
    { ZeroMocPriceMovementDelayMessage }
        \cup { [ZeroMocPriceMovementDelayMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroMocPriceMovementDelayMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroMocPriceMovementDelayMessage EXCEPT !.stockState = one] : one \in Sample(2) }
        \cup { [ZeroMocPriceMovementDelayMessage EXCEPT !.ccp = one] : one \in Sample(11) }
        \cup { [ZeroMocPriceMovementDelayMessage EXCEPT !.vwap = one] : one \in Sample(11) }

(***************************************************************************)
(* Stock State Message: 85 bytes                                           *)
(***************************************************************************)

StockStateMessage ==
    [ symbol                 : Sample(12),
      tradingSystemTimeStamp : Sample(23),
      comment                : Sample(40),
      stockState             : Sample(2),
      openingTime            : Sample(6),
      listingMarket          : Sample(1),
      productType            : Sample(1) ]

EncodeStockStateMessage(message) ==
    message.symbol
        \o message.tradingSystemTimeStamp
        \o message.comment
        \o message.stockState
        \o message.openingTime
        \o message.listingMarket
        \o message.productType

DecodeStockStateMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(symbol.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET comment == ReadBytes(tradingSystemTimeStamp.rest, 40) IN IF ~comment.ok THEN Fail ELSE
    LET stockState == ReadBytes(comment.rest, 2) IN IF ~stockState.ok THEN Fail ELSE
    LET openingTime == ReadBytes(stockState.rest, 6) IN IF ~openingTime.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(openingTime.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET productType == ReadBytes(listingMarket.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         comment                |-> comment.value,
         stockState             |-> stockState.value,
         openingTime            |-> openingTime.value,
         listingMarket          |-> listingMarket.value,
         productType            |-> productType.value ], productType.rest)

ZeroStockStateMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      comment                |-> [i \in 1 .. 40 |-> 0],
      stockState             |-> [i \in 1 .. 2 |-> 0],
      openingTime            |-> [i \in 1 .. 6 |-> 0],
      listingMarket          |-> [i \in 1 .. 1 |-> 0],
      productType            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock State Message at zero, then each field in turn at the values it is checked at *)
CheckedStockStateMessage ==
    { ZeroStockStateMessage }
        \cup { [ZeroStockStateMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroStockStateMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroStockStateMessage EXCEPT !.comment = one] : one \in Sample(40) }
        \cup { [ZeroStockStateMessage EXCEPT !.stockState = one] : one \in Sample(2) }
        \cup { [ZeroStockStateMessage EXCEPT !.openingTime = one] : one \in Sample(6) }
        \cup { [ZeroStockStateMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroStockStateMessage EXCEPT !.productType = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Message: 71 bytes                                                 *)
(***************************************************************************)

QuoteMessage ==
    [ symbol                 : Sample(12),
      bidPrice               : Sample(9),
      bidSize                : Sample(9),
      askPrice               : Sample(9),
      askSize                : Sample(9),
      tradingSystemTimeStamp : Sample(23) ]

EncodeQuoteMessage(message) ==
    message.symbol
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.tradingSystemTimeStamp

DecodeQuoteMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(symbol.rest, 9) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 9) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 9) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 9) IN IF ~askSize.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(askSize.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         bidPrice               |-> bidPrice.value,
         bidSize                |-> bidSize.value,
         askPrice               |-> askPrice.value,
         askSize                |-> askSize.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value ], tradingSystemTimeStamp.rest)

ZeroQuoteMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      bidPrice               |-> [i \in 1 .. 9 |-> 0],
      bidSize                |-> [i \in 1 .. 9 |-> 0],
      askPrice               |-> [i \in 1 .. 9 |-> 0],
      askSize                |-> [i \in 1 .. 9 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0] ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(9) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(9) }
        \cup { [ZeroQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(9) }
        \cup { [ZeroQuoteMessage EXCEPT !.askSize = one] : one \in Sample(9) }
        \cup { [ZeroQuoteMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }

(***************************************************************************)
(* General Message: 104 bytes                                              *)
(***************************************************************************)

GeneralMessage ==
    [ tradingSystemTimeStamp : Sample(23),
      bulletinIndicator      : Sample(1),
      messageText            : Sample(80) ]

EncodeGeneralMessage(message) ==
    message.tradingSystemTimeStamp
        \o message.bulletinIndicator
        \o message.messageText

DecodeGeneralMessage(bytes) ==
    LET tradingSystemTimeStamp == ReadBytes(bytes, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET bulletinIndicator == ReadBytes(tradingSystemTimeStamp.rest, 1) IN IF ~bulletinIndicator.ok THEN Fail ELSE
    LET messageText == ReadBytes(bulletinIndicator.rest, 80) IN IF ~messageText.ok THEN Fail ELSE
    Ok([ tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         bulletinIndicator      |-> bulletinIndicator.value,
         messageText            |-> messageText.value ], messageText.rest)

ZeroGeneralMessage ==
    [ tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      bulletinIndicator      |-> [i \in 1 .. 1 |-> 0],
      messageText            |-> [i \in 1 .. 80 |-> 0] ]

(* General Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralMessage ==
    { ZeroGeneralMessage }
        \cup { [ZeroGeneralMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroGeneralMessage EXCEPT !.bulletinIndicator = one] : one \in Sample(1) }
        \cup { [ZeroGeneralMessage EXCEPT !.messageText = one] : one \in Sample(80) }

(***************************************************************************)
(* Trade Cancellation Message: 97 bytes                                    *)
(***************************************************************************)

TradeCancellationMessage ==
    [ symbol                 : Sample(12),
      volume                 : Sample(9),
      tradePrice             : Sample(11),
      buyerId                : Sample(3),
      sellerId               : Sample(3),
      tradeTimeStamp         : Sample(6),
      originalTradeId        : Sample(9),
      lastSale               : Sample(11),
      tradingSystemTimeStamp : Sample(23),
      listingMarket          : Sample(1),
      productType            : Sample(1),
      tradeDate              : Sample(8) ]

EncodeTradeCancellationMessage(message) ==
    message.symbol
        \o message.volume
        \o message.tradePrice
        \o message.buyerId
        \o message.sellerId
        \o message.tradeTimeStamp
        \o message.originalTradeId
        \o message.lastSale
        \o message.tradingSystemTimeStamp
        \o message.listingMarket
        \o message.productType
        \o message.tradeDate

DecodeTradeCancellationMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 9) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 11) IN IF ~tradePrice.ok THEN Fail ELSE
    LET buyerId == ReadBytes(tradePrice.rest, 3) IN IF ~buyerId.ok THEN Fail ELSE
    LET sellerId == ReadBytes(buyerId.rest, 3) IN IF ~sellerId.ok THEN Fail ELSE
    LET tradeTimeStamp == ReadBytes(sellerId.rest, 6) IN IF ~tradeTimeStamp.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(tradeTimeStamp.rest, 9) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET lastSale == ReadBytes(originalTradeId.rest, 11) IN IF ~lastSale.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(lastSale.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(tradingSystemTimeStamp.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET productType == ReadBytes(listingMarket.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(productType.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         volume                 |-> volume.value,
         tradePrice             |-> tradePrice.value,
         buyerId                |-> buyerId.value,
         sellerId               |-> sellerId.value,
         tradeTimeStamp         |-> tradeTimeStamp.value,
         originalTradeId        |-> originalTradeId.value,
         lastSale               |-> lastSale.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         listingMarket          |-> listingMarket.value,
         productType            |-> productType.value,
         tradeDate              |-> tradeDate.value ], tradeDate.rest)

ZeroTradeCancellationMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      volume                 |-> [i \in 1 .. 9 |-> 0],
      tradePrice             |-> [i \in 1 .. 11 |-> 0],
      buyerId                |-> [i \in 1 .. 3 |-> 0],
      sellerId               |-> [i \in 1 .. 3 |-> 0],
      tradeTimeStamp         |-> [i \in 1 .. 6 |-> 0],
      originalTradeId        |-> [i \in 1 .. 9 |-> 0],
      lastSale               |-> [i \in 1 .. 11 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      listingMarket          |-> [i \in 1 .. 1 |-> 0],
      productType            |-> [i \in 1 .. 1 |-> 0],
      tradeDate              |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationMessage ==
    { ZeroTradeCancellationMessage }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(9) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.buyerId = one] : one \in Sample(3) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.sellerId = one] : one \in Sample(3) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeTimeStamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.originalTradeId = one] : one \in Sample(9) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.lastSale = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Indicative Price Message: 44 bytes                                      *)
(***************************************************************************)

IndicativePriceMessage ==
    [ symbol          : Sample(12),
      cusip           : Sample(12),
      indicativePrice : Sample(11),
      priceMarker     : Sample(1),
      businessDate    : Sample(8) ]

EncodeIndicativePriceMessage(message) ==
    message.symbol
        \o message.cusip
        \o message.indicativePrice
        \o message.priceMarker
        \o message.businessDate

DecodeIndicativePriceMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 12) IN IF ~cusip.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(cusip.rest, 11) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET priceMarker == ReadBytes(indicativePrice.rest, 1) IN IF ~priceMarker.ok THEN Fail ELSE
    LET businessDate == ReadBytes(priceMarker.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    Ok([ symbol          |-> symbol.value,
         cusip           |-> cusip.value,
         indicativePrice |-> indicativePrice.value,
         priceMarker     |-> priceMarker.value,
         businessDate    |-> businessDate.value ], businessDate.rest)

ZeroIndicativePriceMessage ==
    [ symbol          |-> [i \in 1 .. 12 |-> 0],
      cusip           |-> [i \in 1 .. 12 |-> 0],
      indicativePrice |-> [i \in 1 .. 11 |-> 0],
      priceMarker     |-> [i \in 1 .. 1 |-> 0],
      businessDate    |-> [i \in 1 .. 8 |-> 0] ]

(* Indicative Price Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativePriceMessage ==
    { ZeroIndicativePriceMessage }
        \cup { [ZeroIndicativePriceMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroIndicativePriceMessage EXCEPT !.cusip = one] : one \in Sample(12) }
        \cup { [ZeroIndicativePriceMessage EXCEPT !.indicativePrice = one] : one \in Sample(11) }
        \cup { [ZeroIndicativePriceMessage EXCEPT !.priceMarker = one] : one \in Sample(1) }
        \cup { [ZeroIndicativePriceMessage EXCEPT !.businessDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Calculated Opening Price Message: 59 bytes                              *)
(***************************************************************************)

CalculatedOpeningPriceMessage ==
    [ symbol                 : Sample(12),
      cusip                  : Sample(12),
      cop                    : Sample(11),
      priceMarker            : Sample(1),
      tradingSystemTimeStamp : Sample(23) ]

EncodeCalculatedOpeningPriceMessage(message) ==
    message.symbol
        \o message.cusip
        \o message.cop
        \o message.priceMarker
        \o message.tradingSystemTimeStamp

DecodeCalculatedOpeningPriceMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 12) IN IF ~cusip.ok THEN Fail ELSE
    LET cop == ReadBytes(cusip.rest, 11) IN IF ~cop.ok THEN Fail ELSE
    LET priceMarker == ReadBytes(cop.rest, 1) IN IF ~priceMarker.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(priceMarker.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         cusip                  |-> cusip.value,
         cop                    |-> cop.value,
         priceMarker            |-> priceMarker.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value ], tradingSystemTimeStamp.rest)

ZeroCalculatedOpeningPriceMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      cusip                  |-> [i \in 1 .. 12 |-> 0],
      cop                    |-> [i \in 1 .. 11 |-> 0],
      priceMarker            |-> [i \in 1 .. 1 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0] ]

(* Calculated Opening Price Message at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedOpeningPriceMessage ==
    { ZeroCalculatedOpeningPriceMessage }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.cusip = one] : one \in Sample(12) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.cop = one] : one \in Sample(11) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.priceMarker = one] : one \in Sample(1) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }

(***************************************************************************)
(* Tsx Tsxv Closing Price Message: 61 bytes                                *)
(***************************************************************************)

TsxTsxvClosingPriceMessage ==
    [ symbol              : Sample(12),
      cusip               : Sample(12),
      tsxTsxvClosingPrice : Sample(11),
      tsxTsxvLastBid      : Sample(9),
      tsxTsxvLastAsk      : Sample(9),
      businessDate        : Sample(8) ]

EncodeTsxTsxvClosingPriceMessage(message) ==
    message.symbol
        \o message.cusip
        \o message.tsxTsxvClosingPrice
        \o message.tsxTsxvLastBid
        \o message.tsxTsxvLastAsk
        \o message.businessDate

DecodeTsxTsxvClosingPriceMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 12) IN IF ~cusip.ok THEN Fail ELSE
    LET tsxTsxvClosingPrice == ReadBytes(cusip.rest, 11) IN IF ~tsxTsxvClosingPrice.ok THEN Fail ELSE
    LET tsxTsxvLastBid == ReadBytes(tsxTsxvClosingPrice.rest, 9) IN IF ~tsxTsxvLastBid.ok THEN Fail ELSE
    LET tsxTsxvLastAsk == ReadBytes(tsxTsxvLastBid.rest, 9) IN IF ~tsxTsxvLastAsk.ok THEN Fail ELSE
    LET businessDate == ReadBytes(tsxTsxvLastAsk.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    Ok([ symbol              |-> symbol.value,
         cusip               |-> cusip.value,
         tsxTsxvClosingPrice |-> tsxTsxvClosingPrice.value,
         tsxTsxvLastBid      |-> tsxTsxvLastBid.value,
         tsxTsxvLastAsk      |-> tsxTsxvLastAsk.value,
         businessDate        |-> businessDate.value ], businessDate.rest)

ZeroTsxTsxvClosingPriceMessage ==
    [ symbol              |-> [i \in 1 .. 12 |-> 0],
      cusip               |-> [i \in 1 .. 12 |-> 0],
      tsxTsxvClosingPrice |-> [i \in 1 .. 11 |-> 0],
      tsxTsxvLastBid      |-> [i \in 1 .. 9 |-> 0],
      tsxTsxvLastAsk      |-> [i \in 1 .. 9 |-> 0],
      businessDate        |-> [i \in 1 .. 8 |-> 0] ]

(* Tsx Tsxv Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedTsxTsxvClosingPriceMessage ==
    { ZeroTsxTsxvClosingPriceMessage }
        \cup { [ZeroTsxTsxvClosingPriceMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTsxTsxvClosingPriceMessage EXCEPT !.cusip = one] : one \in Sample(12) }
        \cup { [ZeroTsxTsxvClosingPriceMessage EXCEPT !.tsxTsxvClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroTsxTsxvClosingPriceMessage EXCEPT !.tsxTsxvLastBid = one] : one \in Sample(9) }
        \cup { [ZeroTsxTsxvClosingPriceMessage EXCEPT !.tsxTsxvLastAsk = one] : one \in Sample(9) }
        \cup { [ZeroTsxTsxvClosingPriceMessage EXCEPT !.businessDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Market State Message: 26 bytes                                          *)
(***************************************************************************)

MarketStateMessage ==
    [ tradingSystemTimeStamp : Sample(23),
      stockGroup             : Sample(2),
      marketState            : Sample(1) ]

EncodeMarketStateMessage(message) ==
    message.tradingSystemTimeStamp
        \o message.stockGroup
        \o message.marketState

DecodeMarketStateMessage(bytes) ==
    LET tradingSystemTimeStamp == ReadBytes(bytes, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET stockGroup == ReadBytes(tradingSystemTimeStamp.rest, 2) IN IF ~stockGroup.ok THEN Fail ELSE
    LET marketState == ReadBytes(stockGroup.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    Ok([ tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         stockGroup             |-> stockGroup.value,
         marketState            |-> marketState.value ], marketState.rest)

ZeroMarketStateMessage ==
    [ tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      stockGroup             |-> [i \in 1 .. 2 |-> 0],
      marketState            |-> [i \in 1 .. 1 |-> 0] ]

(* Market State Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStateMessage ==
    { ZeroMarketStateMessage }
        \cup { [ZeroMarketStateMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroMarketStateMessage EXCEPT !.stockGroup = one] : one \in Sample(2) }
        \cup { [ZeroMarketStateMessage EXCEPT !.marketState = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Tier Status Message: 40 bytes                                   *)
(***************************************************************************)

TradingTierStatusMessage ==
    [ exchangeId               : Sample(3),
      totalNumberOfSymbols     : Sample(5),
      totalNumberOfStockGroups : Sample(3),
      tradingSystemTimeStamp   : Sample(23),
      tradingTierId            : Sample(6) ]

EncodeTradingTierStatusMessage(message) ==
    message.exchangeId
        \o message.totalNumberOfSymbols
        \o message.totalNumberOfStockGroups
        \o message.tradingSystemTimeStamp
        \o message.tradingTierId

DecodeTradingTierStatusMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 3) IN IF ~exchangeId.ok THEN Fail ELSE
    LET totalNumberOfSymbols == ReadBytes(exchangeId.rest, 5) IN IF ~totalNumberOfSymbols.ok THEN Fail ELSE
    LET totalNumberOfStockGroups == ReadBytes(totalNumberOfSymbols.rest, 3) IN IF ~totalNumberOfStockGroups.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(totalNumberOfStockGroups.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET tradingTierId == ReadBytes(tradingSystemTimeStamp.rest, 6) IN IF ~tradingTierId.ok THEN Fail ELSE
    Ok([ exchangeId               |-> exchangeId.value,
         totalNumberOfSymbols     |-> totalNumberOfSymbols.value,
         totalNumberOfStockGroups |-> totalNumberOfStockGroups.value,
         tradingSystemTimeStamp   |-> tradingSystemTimeStamp.value,
         tradingTierId            |-> tradingTierId.value ], tradingTierId.rest)

ZeroTradingTierStatusMessage ==
    [ exchangeId               |-> [i \in 1 .. 3 |-> 0],
      totalNumberOfSymbols     |-> [i \in 1 .. 5 |-> 0],
      totalNumberOfStockGroups |-> [i \in 1 .. 3 |-> 0],
      tradingSystemTimeStamp   |-> [i \in 1 .. 23 |-> 0],
      tradingTierId            |-> [i \in 1 .. 6 |-> 0] ]

(* Trading Tier Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingTierStatusMessage ==
    { ZeroTradingTierStatusMessage }
        \cup { [ZeroTradingTierStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(3) }
        \cup { [ZeroTradingTierStatusMessage EXCEPT !.totalNumberOfSymbols = one] : one \in Sample(5) }
        \cup { [ZeroTradingTierStatusMessage EXCEPT !.totalNumberOfStockGroups = one] : one \in Sample(3) }
        \cup { [ZeroTradingTierStatusMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroTradingTierStatusMessage EXCEPT !.tradingTierId = one] : one \in Sample(6) }

(***************************************************************************)
(* Trade Correction Message: 114 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ symbol                 : Sample(12),
      volume                 : Sample(9),
      tradePrice             : Sample(11),
      buyerId                : Sample(3),
      sellerId               : Sample(3),
      tradeTimeStamp         : Sample(6),
      lastSale               : Sample(11),
      tradeId                : Sample(9),
      crossType              : Sample(1),
      moc                    : Sample(1),
      bypass                 : Sample(1),
      openingTrade           : Sample(1),
      settlementTerms        : Sample(1),
      originalTradeId        : Sample(9),
      tradingSystemTimeStamp : Sample(23),
      listingMarket          : Sample(1),
      productType            : Sample(1),
      tradeDate              : Sample(8),
      isMidOnly              : Sample(1),
      isDark                 : Sample(1),
      isConditional          : Sample(1) ]

EncodeTradeCorrectionMessage(message) ==
    message.symbol
        \o message.volume
        \o message.tradePrice
        \o message.buyerId
        \o message.sellerId
        \o message.tradeTimeStamp
        \o message.lastSale
        \o message.tradeId
        \o message.crossType
        \o message.moc
        \o message.bypass
        \o message.openingTrade
        \o message.settlementTerms
        \o message.originalTradeId
        \o message.tradingSystemTimeStamp
        \o message.listingMarket
        \o message.productType
        \o message.tradeDate
        \o message.isMidOnly
        \o message.isDark
        \o message.isConditional

DecodeTradeCorrectionMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 9) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 11) IN IF ~tradePrice.ok THEN Fail ELSE
    LET buyerId == ReadBytes(tradePrice.rest, 3) IN IF ~buyerId.ok THEN Fail ELSE
    LET sellerId == ReadBytes(buyerId.rest, 3) IN IF ~sellerId.ok THEN Fail ELSE
    LET tradeTimeStamp == ReadBytes(sellerId.rest, 6) IN IF ~tradeTimeStamp.ok THEN Fail ELSE
    LET lastSale == ReadBytes(tradeTimeStamp.rest, 11) IN IF ~lastSale.ok THEN Fail ELSE
    LET tradeId == ReadBytes(lastSale.rest, 9) IN IF ~tradeId.ok THEN Fail ELSE
    LET crossType == ReadBytes(tradeId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET moc == ReadBytes(crossType.rest, 1) IN IF ~moc.ok THEN Fail ELSE
    LET bypass == ReadBytes(moc.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(bypass.rest, 1) IN IF ~openingTrade.ok THEN Fail ELSE
    LET settlementTerms == ReadBytes(openingTrade.rest, 1) IN IF ~settlementTerms.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(settlementTerms.rest, 9) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(originalTradeId.rest, 23) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(tradingSystemTimeStamp.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET productType == ReadBytes(listingMarket.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(productType.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET isMidOnly == ReadBytes(tradeDate.rest, 1) IN IF ~isMidOnly.ok THEN Fail ELSE
    LET isDark == ReadBytes(isMidOnly.rest, 1) IN IF ~isDark.ok THEN Fail ELSE
    LET isConditional == ReadBytes(isDark.rest, 1) IN IF ~isConditional.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         volume                 |-> volume.value,
         tradePrice             |-> tradePrice.value,
         buyerId                |-> buyerId.value,
         sellerId               |-> sellerId.value,
         tradeTimeStamp         |-> tradeTimeStamp.value,
         lastSale               |-> lastSale.value,
         tradeId                |-> tradeId.value,
         crossType              |-> crossType.value,
         moc                    |-> moc.value,
         bypass                 |-> bypass.value,
         openingTrade           |-> openingTrade.value,
         settlementTerms        |-> settlementTerms.value,
         originalTradeId        |-> originalTradeId.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         listingMarket          |-> listingMarket.value,
         productType            |-> productType.value,
         tradeDate              |-> tradeDate.value,
         isMidOnly              |-> isMidOnly.value,
         isDark                 |-> isDark.value,
         isConditional          |-> isConditional.value ], isConditional.rest)

ZeroTradeCorrectionMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      volume                 |-> [i \in 1 .. 9 |-> 0],
      tradePrice             |-> [i \in 1 .. 11 |-> 0],
      buyerId                |-> [i \in 1 .. 3 |-> 0],
      sellerId               |-> [i \in 1 .. 3 |-> 0],
      tradeTimeStamp         |-> [i \in 1 .. 6 |-> 0],
      lastSale               |-> [i \in 1 .. 11 |-> 0],
      tradeId                |-> [i \in 1 .. 9 |-> 0],
      crossType              |-> [i \in 1 .. 1 |-> 0],
      moc                    |-> [i \in 1 .. 1 |-> 0],
      bypass                 |-> [i \in 1 .. 1 |-> 0],
      openingTrade           |-> [i \in 1 .. 1 |-> 0],
      settlementTerms        |-> [i \in 1 .. 1 |-> 0],
      originalTradeId        |-> [i \in 1 .. 9 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 23 |-> 0],
      listingMarket          |-> [i \in 1 .. 1 |-> 0],
      productType            |-> [i \in 1 .. 1 |-> 0],
      tradeDate              |-> [i \in 1 .. 8 |-> 0],
      isMidOnly              |-> [i \in 1 .. 1 |-> 0],
      isDark                 |-> [i \in 1 .. 1 |-> 0],
      isConditional          |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(9) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.buyerId = one] : one \in Sample(3) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.sellerId = one] : one \in Sample(3) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeTimeStamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.lastSale = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(9) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.moc = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.openingTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.settlementTerms = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(9) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(23) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.isMidOnly = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.isDark = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.isConditional = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

TradeMessageCode == 16672  \* "A "
SymbolStatusMessageCode == 16928  \* "B "
MocImbalanceNotificationMessageCode == 17184  \* "C "
MocPriceMovementDelayMessageCode == 17217  \* "CA"
StockStateMessageCode == 17440  \* "D "
QuoteMessageCode == 17696  \* "E "
GeneralMessageCode == 18208  \* "G "
TradeCancellationMessageCode == 18464  \* "H "
IndicativePriceMessageCode == 18720  \* "I "
CalculatedOpeningPriceMessageCode == 20256  \* "O "
TsxTsxvClosingPriceMessageCode == 21024  \* "R "
MarketStateMessageCode == 21280  \* "S "
TradingTierStatusMessageCode == 21536  \* "T "
TradeCorrectionMessageCode == 22560  \* "X "

MessageBody ==
    [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {MocImbalanceNotificationMessageCode}, body : MocImbalanceNotificationMessage ]
        \cup [ tag : {MocPriceMovementDelayMessageCode}, body : MocPriceMovementDelayMessage ]
        \cup [ tag : {StockStateMessageCode}, body : StockStateMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {GeneralMessageCode}, body : GeneralMessage ]
        \cup [ tag : {TradeCancellationMessageCode}, body : TradeCancellationMessage ]
        \cup [ tag : {IndicativePriceMessageCode}, body : IndicativePriceMessage ]
        \cup [ tag : {CalculatedOpeningPriceMessageCode}, body : CalculatedOpeningPriceMessage ]
        \cup [ tag : {TsxTsxvClosingPriceMessageCode}, body : TsxTsxvClosingPriceMessage ]
        \cup [ tag : {MarketStateMessageCode}, body : MarketStateMessage ]
        \cup [ tag : {TradingTierStatusMessageCode}, body : TradingTierStatusMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = MocImbalanceNotificationMessageCode -> EncodeMocImbalanceNotificationMessage(message.body)
      [] message.tag = MocPriceMovementDelayMessageCode -> EncodeMocPriceMovementDelayMessage(message.body)
      [] message.tag = StockStateMessageCode -> EncodeStockStateMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = GeneralMessageCode -> EncodeGeneralMessage(message.body)
      [] message.tag = TradeCancellationMessageCode -> EncodeTradeCancellationMessage(message.body)
      [] message.tag = IndicativePriceMessageCode -> EncodeIndicativePriceMessage(message.body)
      [] message.tag = CalculatedOpeningPriceMessageCode -> EncodeCalculatedOpeningPriceMessage(message.body)
      [] message.tag = TsxTsxvClosingPriceMessageCode -> EncodeTsxTsxvClosingPriceMessage(message.body)
      [] message.tag = MarketStateMessageCode -> EncodeMarketStateMessage(message.body)
      [] message.tag = TradingTierStatusMessageCode -> EncodeTradingTierStatusMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = MocImbalanceNotificationMessageCode -> DecodeMocImbalanceNotificationMessage(bytes)
              [] tag = MocPriceMovementDelayMessageCode -> DecodeMocPriceMovementDelayMessage(bytes)
              [] tag = StockStateMessageCode -> DecodeStockStateMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = GeneralMessageCode -> DecodeGeneralMessage(bytes)
              [] tag = TradeCancellationMessageCode -> DecodeTradeCancellationMessage(bytes)
              [] tag = IndicativePriceMessageCode -> DecodeIndicativePriceMessage(bytes)
              [] tag = CalculatedOpeningPriceMessageCode -> DecodeCalculatedOpeningPriceMessage(bytes)
              [] tag = TsxTsxvClosingPriceMessageCode -> DecodeTsxTsxvClosingPriceMessage(bytes)
              [] tag = MarketStateMessageCode -> DecodeMarketStateMessage(bytes)
              [] tag = TradingTierStatusMessageCode -> DecodeTradingTierStatusMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> MocImbalanceNotificationMessageCode, body |-> one] : one \in CheckedMocImbalanceNotificationMessage }
        \cup { [tag |-> MocPriceMovementDelayMessageCode, body |-> one] : one \in CheckedMocPriceMovementDelayMessage }
        \cup { [tag |-> StockStateMessageCode, body |-> one] : one \in CheckedStockStateMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> GeneralMessageCode, body |-> one] : one \in CheckedGeneralMessage }
        \cup { [tag |-> TradeCancellationMessageCode, body |-> one] : one \in CheckedTradeCancellationMessage }
        \cup { [tag |-> IndicativePriceMessageCode, body |-> one] : one \in CheckedIndicativePriceMessage }
        \cup { [tag |-> CalculatedOpeningPriceMessageCode, body |-> one] : one \in CheckedCalculatedOpeningPriceMessage }
        \cup { [tag |-> TsxTsxvClosingPriceMessageCode, body |-> one] : one \in CheckedTsxTsxvClosingPriceMessage }
        \cup { [tag |-> MarketStateMessageCode, body |-> one] : one \in CheckedMarketStateMessage }
        \cup { [tag |-> TradingTierStatusMessageCode, body |-> one] : one \in CheckedTradingTierStatusMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ qrtmdStx                 : Sample(1),
      messageLength            : Sample(4),
      sequenceNumber           : Sample(9),
      serviceIdentifier        : Sample(3),
      retransmissionIdentifier : Sample(1),
      continuationIdentifier   : Sample(1),
      exchangeIdentifier       : Sample(2),
      messageBody              : MessageBody,
      qrtmdEtx                 : Sample(1) ]

EncodePacket(message) ==
    message.qrtmdStx
        \o message.messageLength
        \o message.sequenceNumber
        \o message.serviceIdentifier
        \o message.retransmissionIdentifier
        \o message.continuationIdentifier
        \o EncodeUIntBE(message.messageBody.tag, 2)
        \o message.exchangeIdentifier
        \o EncodeMessageBody(message.messageBody)
        \o message.qrtmdEtx

DecodePacket(bytes) ==
    LET qrtmdStx == ReadBytes(bytes, 1) IN IF ~qrtmdStx.ok THEN Fail ELSE
    LET messageLength == ReadBytes(qrtmdStx.rest, 4) IN IF ~messageLength.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageLength.rest, 9) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET serviceIdentifier == ReadBytes(sequenceNumber.rest, 3) IN IF ~serviceIdentifier.ok THEN Fail ELSE
    LET retransmissionIdentifier == ReadBytes(serviceIdentifier.rest, 1) IN IF ~retransmissionIdentifier.ok THEN Fail ELSE
    LET continuationIdentifier == ReadBytes(retransmissionIdentifier.rest, 1) IN IF ~continuationIdentifier.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(continuationIdentifier.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET exchangeIdentifier == ReadBytes(messageType.rest, 2) IN IF ~exchangeIdentifier.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, exchangeIdentifier.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET qrtmdEtx == ReadBytes(messageBody.rest, 1) IN IF ~qrtmdEtx.ok THEN Fail ELSE
    Ok([ qrtmdStx                 |-> qrtmdStx.value,
         messageLength            |-> messageLength.value,
         sequenceNumber           |-> sequenceNumber.value,
         serviceIdentifier        |-> serviceIdentifier.value,
         retransmissionIdentifier |-> retransmissionIdentifier.value,
         continuationIdentifier   |-> continuationIdentifier.value,
         exchangeIdentifier       |-> exchangeIdentifier.value,
         messageBody              |-> messageBody.value,
         qrtmdEtx                 |-> qrtmdEtx.value ], qrtmdEtx.rest)

ZeroPacket ==
    [ qrtmdStx                 |-> [i \in 1 .. 1 |-> 0],
      messageLength            |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber           |-> [i \in 1 .. 9 |-> 0],
      serviceIdentifier        |-> [i \in 1 .. 3 |-> 0],
      retransmissionIdentifier |-> [i \in 1 .. 1 |-> 0],
      continuationIdentifier   |-> [i \in 1 .. 1 |-> 0],
      exchangeIdentifier       |-> [i \in 1 .. 2 |-> 0],
      messageBody              |-> ZeroMessageBody,
      qrtmdEtx                 |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.qrtmdStx = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.messageLength = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroPacket EXCEPT !.serviceIdentifier = one] : one \in Sample(3) }
        \cup { [ZeroPacket EXCEPT !.retransmissionIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.continuationIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.exchangeIdentifier = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.qrtmdEtx = one] : one \in Sample(1) }

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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStatusMessage ==
    \A message \in CheckedSymbolStatusMessage :
        LET read == DecodeSymbolStatusMessage(EncodeSymbolStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Moc Imbalance Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMocImbalanceNotificationMessage ==
    \A message \in CheckedMocImbalanceNotificationMessage :
        LET read == DecodeMocImbalanceNotificationMessage(EncodeMocImbalanceNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Moc Price Movement Delay Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMocPriceMovementDelayMessage ==
    \A message \in CheckedMocPriceMovementDelayMessage :
        LET read == DecodeMocPriceMovementDelayMessage(EncodeMocPriceMovementDelayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockStateMessage ==
    \A message \in CheckedStockStateMessage :
        LET read == DecodeStockStateMessage(EncodeStockStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every General Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralMessage ==
    \A message \in CheckedGeneralMessage :
        LET read == DecodeGeneralMessage(EncodeGeneralMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancellationMessage ==
    \A message \in CheckedTradeCancellationMessage :
        LET read == DecodeTradeCancellationMessage(EncodeTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indicative Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativePriceMessage ==
    \A message \in CheckedIndicativePriceMessage :
        LET read == DecodeIndicativePriceMessage(EncodeIndicativePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Opening Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedOpeningPriceMessage ==
    \A message \in CheckedCalculatedOpeningPriceMessage :
        LET read == DecodeCalculatedOpeningPriceMessage(EncodeCalculatedOpeningPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tsx Tsxv Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTsxTsxvClosingPriceMessage ==
    \A message \in CheckedTsxTsxvClosingPriceMessage :
        LET read == DecodeTsxTsxvClosingPriceMessage(EncodeTsxTsxvClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStateMessage ==
    \A message \in CheckedMarketStateMessage :
        LET read == DecodeMarketStateMessage(EncodeMarketStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Tier Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingTierStatusMessage ==
    \A message \in CheckedTradingTierStatusMessage :
        LET read == DecodeTradingTierStatusMessage(EncodeTradingTierStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
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

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
