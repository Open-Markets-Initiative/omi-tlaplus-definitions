---------------------- MODULE IceFutures_Mdf_v1_1_24 -----------------------
(***************************************************************************)
(* Intercontinental Exchange Multicast Data Feed v1.1.24                   *)
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
(*                                                                         *)
(* Note: a Number Of Msgs of 0 marks Heartbeat and carries no Message.     *)
(*                                                                         *)
(* Note: Extra Data is as wide as what is left of Message: it is read as   *)
(* the bytes left of what its record was given, which the records above it *)
(* keep those bytes back from.                                             *)
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
(* Market Snapshot Message: 133 bytes                                      *)
(***************************************************************************)

MarketSnapshotMessage ==
    [ marketId                              : Sample(4),
      marketType                            : Sample(2),
      tradingStatus                         : Sample(1),
      volume                                : Sample(4),
      blockVolume                           : Sample(4),
      efsVolume                             : Sample(4),
      efpVolume                             : Sample(4),
      openInterest                          : Sample(4),
      openingPrice                          : Sample(8),
      settlementPriceWithDealPricePrecision : Sample(8),
      high                                  : Sample(8),
      low                                   : Sample(8),
      vwap                                  : Sample(8),
      numOfBookEntries                      : Sample(4),
      lastTradePrice                        : Sample(8),
      lastTradeQuantity                     : Sample(4),
      lastTradeDateTime                     : Sample(8),
      settlePriceDateTime                   : Sample(8),
      lastMessageSequenceId                 : Sample(4),
      reserved2                             : Sample(2),
      openInterestDate                      : Sample(10),
      isSettlePriceOfficial                 : Sample(1),
      settlementPrice                       : Sample(8),
      hasPreviousDaySettlementPrice         : Sample(1),
      previousDaySettlementPrice            : Sample(8) ]

EncodeMarketSnapshotMessage(message) ==
    message.marketId
        \o message.marketType
        \o message.tradingStatus
        \o message.volume
        \o message.blockVolume
        \o message.efsVolume
        \o message.efpVolume
        \o message.openInterest
        \o message.openingPrice
        \o message.settlementPriceWithDealPricePrecision
        \o message.high
        \o message.low
        \o message.vwap
        \o message.numOfBookEntries
        \o message.lastTradePrice
        \o message.lastTradeQuantity
        \o message.lastTradeDateTime
        \o message.settlePriceDateTime
        \o message.lastMessageSequenceId
        \o message.reserved2
        \o message.openInterestDate
        \o message.isSettlePriceOfficial
        \o message.settlementPrice
        \o message.hasPreviousDaySettlementPrice
        \o message.previousDaySettlementPrice

DecodeMarketSnapshotMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketType == ReadBytes(marketId.rest, 2) IN IF ~marketType.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(marketType.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET volume == ReadBytes(tradingStatus.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET blockVolume == ReadBytes(volume.rest, 4) IN IF ~blockVolume.ok THEN Fail ELSE
    LET efsVolume == ReadBytes(blockVolume.rest, 4) IN IF ~efsVolume.ok THEN Fail ELSE
    LET efpVolume == ReadBytes(efsVolume.rest, 4) IN IF ~efpVolume.ok THEN Fail ELSE
    LET openInterest == ReadBytes(efpVolume.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(openInterest.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET settlementPriceWithDealPricePrecision == ReadBytes(openingPrice.rest, 8) IN IF ~settlementPriceWithDealPricePrecision.ok THEN Fail ELSE
    LET high == ReadBytes(settlementPriceWithDealPricePrecision.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET vwap == ReadBytes(low.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET numOfBookEntries == ReadBytes(vwap.rest, 4) IN IF ~numOfBookEntries.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(numOfBookEntries.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeQuantity == ReadBytes(lastTradePrice.rest, 4) IN IF ~lastTradeQuantity.ok THEN Fail ELSE
    LET lastTradeDateTime == ReadBytes(lastTradeQuantity.rest, 8) IN IF ~lastTradeDateTime.ok THEN Fail ELSE
    LET settlePriceDateTime == ReadBytes(lastTradeDateTime.rest, 8) IN IF ~settlePriceDateTime.ok THEN Fail ELSE
    LET lastMessageSequenceId == ReadBytes(settlePriceDateTime.rest, 4) IN IF ~lastMessageSequenceId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(lastMessageSequenceId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(reserved2.rest, 10) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET isSettlePriceOfficial == ReadBytes(openInterestDate.rest, 1) IN IF ~isSettlePriceOfficial.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(isSettlePriceOfficial.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET hasPreviousDaySettlementPrice == ReadBytes(settlementPrice.rest, 1) IN IF ~hasPreviousDaySettlementPrice.ok THEN Fail ELSE
    LET previousDaySettlementPrice == ReadBytes(hasPreviousDaySettlementPrice.rest, 8) IN IF ~previousDaySettlementPrice.ok THEN Fail ELSE
    Ok([ marketId                              |-> marketId.value,
         marketType                            |-> marketType.value,
         tradingStatus                         |-> tradingStatus.value,
         volume                                |-> volume.value,
         blockVolume                           |-> blockVolume.value,
         efsVolume                             |-> efsVolume.value,
         efpVolume                             |-> efpVolume.value,
         openInterest                          |-> openInterest.value,
         openingPrice                          |-> openingPrice.value,
         settlementPriceWithDealPricePrecision |-> settlementPriceWithDealPricePrecision.value,
         high                                  |-> high.value,
         low                                   |-> low.value,
         vwap                                  |-> vwap.value,
         numOfBookEntries                      |-> numOfBookEntries.value,
         lastTradePrice                        |-> lastTradePrice.value,
         lastTradeQuantity                     |-> lastTradeQuantity.value,
         lastTradeDateTime                     |-> lastTradeDateTime.value,
         settlePriceDateTime                   |-> settlePriceDateTime.value,
         lastMessageSequenceId                 |-> lastMessageSequenceId.value,
         reserved2                             |-> reserved2.value,
         openInterestDate                      |-> openInterestDate.value,
         isSettlePriceOfficial                 |-> isSettlePriceOfficial.value,
         settlementPrice                       |-> settlementPrice.value,
         hasPreviousDaySettlementPrice         |-> hasPreviousDaySettlementPrice.value,
         previousDaySettlementPrice            |-> previousDaySettlementPrice.value ], previousDaySettlementPrice.rest)

ZeroMarketSnapshotMessage ==
    [ marketId                              |-> [i \in 1 .. 4 |-> 0],
      marketType                            |-> [i \in 1 .. 2 |-> 0],
      tradingStatus                         |-> [i \in 1 .. 1 |-> 0],
      volume                                |-> [i \in 1 .. 4 |-> 0],
      blockVolume                           |-> [i \in 1 .. 4 |-> 0],
      efsVolume                             |-> [i \in 1 .. 4 |-> 0],
      efpVolume                             |-> [i \in 1 .. 4 |-> 0],
      openInterest                          |-> [i \in 1 .. 4 |-> 0],
      openingPrice                          |-> [i \in 1 .. 8 |-> 0],
      settlementPriceWithDealPricePrecision |-> [i \in 1 .. 8 |-> 0],
      high                                  |-> [i \in 1 .. 8 |-> 0],
      low                                   |-> [i \in 1 .. 8 |-> 0],
      vwap                                  |-> [i \in 1 .. 8 |-> 0],
      numOfBookEntries                      |-> [i \in 1 .. 4 |-> 0],
      lastTradePrice                        |-> [i \in 1 .. 8 |-> 0],
      lastTradeQuantity                     |-> [i \in 1 .. 4 |-> 0],
      lastTradeDateTime                     |-> [i \in 1 .. 8 |-> 0],
      settlePriceDateTime                   |-> [i \in 1 .. 8 |-> 0],
      lastMessageSequenceId                 |-> [i \in 1 .. 4 |-> 0],
      reserved2                             |-> [i \in 1 .. 2 |-> 0],
      openInterestDate                      |-> [i \in 1 .. 10 |-> 0],
      isSettlePriceOfficial                 |-> [i \in 1 .. 1 |-> 0],
      settlementPrice                       |-> [i \in 1 .. 8 |-> 0],
      hasPreviousDaySettlementPrice         |-> [i \in 1 .. 1 |-> 0],
      previousDaySettlementPrice            |-> [i \in 1 .. 8 |-> 0] ]

(* Market Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSnapshotMessage ==
    { ZeroMarketSnapshotMessage }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.marketType = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.blockVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.efsVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.efpVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.settlementPriceWithDealPricePrecision = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.numOfBookEntries = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.lastTradeQuantity = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.lastTradeDateTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.settlePriceDateTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.lastMessageSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.openInterestDate = one] : one \in Sample(10) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.isSettlePriceOfficial = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.hasPreviousDaySettlementPrice = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotMessage EXCEPT !.previousDaySettlementPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 46 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ marketId                    : Sample(4),
      tradeId                     : Sample(8),
      isSystemPricedLeg           : Sample(1),
      price                       : Sample(8),
      quantity                    : Sample(4),
      offMarketTradeIndicator     : Sample(1),
      transactDateTime            : Sample(8),
      systemPricedLegType         : Sample(1),
      isImpliedSpreadAtMarketOpen : Sample(1),
      isAdjustedTrade             : Sample(1),
      aggressorSide               : Sample(1),
      extraFlags                  : Sample(1),
      offMarketTradeType          : Sample(3),
      sequenceWithinMillis        : Sample(4) ]

EncodeTradeMessage(message) ==
    message.marketId
        \o message.tradeId
        \o message.isSystemPricedLeg
        \o message.price
        \o message.quantity
        \o message.offMarketTradeIndicator
        \o message.transactDateTime
        \o message.systemPricedLegType
        \o message.isImpliedSpreadAtMarketOpen
        \o message.isAdjustedTrade
        \o message.aggressorSide
        \o message.extraFlags
        \o message.offMarketTradeType
        \o message.sequenceWithinMillis

DecodeTradeMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(marketId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET isSystemPricedLeg == ReadBytes(tradeId.rest, 1) IN IF ~isSystemPricedLeg.ok THEN Fail ELSE
    LET price == ReadBytes(isSystemPricedLeg.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET offMarketTradeIndicator == ReadBytes(quantity.rest, 1) IN IF ~offMarketTradeIndicator.ok THEN Fail ELSE
    LET transactDateTime == ReadBytes(offMarketTradeIndicator.rest, 8) IN IF ~transactDateTime.ok THEN Fail ELSE
    LET systemPricedLegType == ReadBytes(transactDateTime.rest, 1) IN IF ~systemPricedLegType.ok THEN Fail ELSE
    LET isImpliedSpreadAtMarketOpen == ReadBytes(systemPricedLegType.rest, 1) IN IF ~isImpliedSpreadAtMarketOpen.ok THEN Fail ELSE
    LET isAdjustedTrade == ReadBytes(isImpliedSpreadAtMarketOpen.rest, 1) IN IF ~isAdjustedTrade.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(isAdjustedTrade.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET extraFlags == ReadBytes(aggressorSide.rest, 1) IN IF ~extraFlags.ok THEN Fail ELSE
    LET offMarketTradeType == ReadBytes(extraFlags.rest, 3) IN IF ~offMarketTradeType.ok THEN Fail ELSE
    LET sequenceWithinMillis == ReadBytes(offMarketTradeType.rest, 4) IN IF ~sequenceWithinMillis.ok THEN Fail ELSE
    Ok([ marketId                    |-> marketId.value,
         tradeId                     |-> tradeId.value,
         isSystemPricedLeg           |-> isSystemPricedLeg.value,
         price                       |-> price.value,
         quantity                    |-> quantity.value,
         offMarketTradeIndicator     |-> offMarketTradeIndicator.value,
         transactDateTime            |-> transactDateTime.value,
         systemPricedLegType         |-> systemPricedLegType.value,
         isImpliedSpreadAtMarketOpen |-> isImpliedSpreadAtMarketOpen.value,
         isAdjustedTrade             |-> isAdjustedTrade.value,
         aggressorSide               |-> aggressorSide.value,
         extraFlags                  |-> extraFlags.value,
         offMarketTradeType          |-> offMarketTradeType.value,
         sequenceWithinMillis        |-> sequenceWithinMillis.value ], sequenceWithinMillis.rest)

ZeroTradeMessage ==
    [ marketId                    |-> [i \in 1 .. 4 |-> 0],
      tradeId                     |-> [i \in 1 .. 8 |-> 0],
      isSystemPricedLeg           |-> [i \in 1 .. 1 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      quantity                    |-> [i \in 1 .. 4 |-> 0],
      offMarketTradeIndicator     |-> [i \in 1 .. 1 |-> 0],
      transactDateTime            |-> [i \in 1 .. 8 |-> 0],
      systemPricedLegType         |-> [i \in 1 .. 1 |-> 0],
      isImpliedSpreadAtMarketOpen |-> [i \in 1 .. 1 |-> 0],
      isAdjustedTrade             |-> [i \in 1 .. 1 |-> 0],
      aggressorSide               |-> [i \in 1 .. 1 |-> 0],
      extraFlags                  |-> [i \in 1 .. 1 |-> 0],
      offMarketTradeType          |-> [i \in 1 .. 3 |-> 0],
      sequenceWithinMillis        |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.isSystemPricedLeg = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.offMarketTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.transactDateTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.systemPricedLegType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.isImpliedSpreadAtMarketOpen = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.isAdjustedTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.extraFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.offMarketTradeType = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.sequenceWithinMillis = one] : one \in Sample(4) }

(***************************************************************************)
(* Spot Market Trade Message: 50 bytes                                     *)
(***************************************************************************)

SpotMarketTradeMessage ==
    [ marketId              : Sample(4),
      tradeId               : Sample(8),
      price                 : Sample(8),
      quantity              : Sample(4),
      transactDateTime      : Sample(8),
      extraFlags            : Sample(1),
      deliveryBeginDateTime : Sample(8),
      deliveryEndDateTime   : Sample(8),
      isSystemPricedLeg     : Sample(1) ]

EncodeSpotMarketTradeMessage(message) ==
    message.marketId
        \o message.tradeId
        \o message.price
        \o message.quantity
        \o message.transactDateTime
        \o message.extraFlags
        \o message.deliveryBeginDateTime
        \o message.deliveryEndDateTime
        \o message.isSystemPricedLeg

DecodeSpotMarketTradeMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(marketId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET transactDateTime == ReadBytes(quantity.rest, 8) IN IF ~transactDateTime.ok THEN Fail ELSE
    LET extraFlags == ReadBytes(transactDateTime.rest, 1) IN IF ~extraFlags.ok THEN Fail ELSE
    LET deliveryBeginDateTime == ReadBytes(extraFlags.rest, 8) IN IF ~deliveryBeginDateTime.ok THEN Fail ELSE
    LET deliveryEndDateTime == ReadBytes(deliveryBeginDateTime.rest, 8) IN IF ~deliveryEndDateTime.ok THEN Fail ELSE
    LET isSystemPricedLeg == ReadBytes(deliveryEndDateTime.rest, 1) IN IF ~isSystemPricedLeg.ok THEN Fail ELSE
    Ok([ marketId              |-> marketId.value,
         tradeId               |-> tradeId.value,
         price                 |-> price.value,
         quantity              |-> quantity.value,
         transactDateTime      |-> transactDateTime.value,
         extraFlags            |-> extraFlags.value,
         deliveryBeginDateTime |-> deliveryBeginDateTime.value,
         deliveryEndDateTime   |-> deliveryEndDateTime.value,
         isSystemPricedLeg     |-> isSystemPricedLeg.value ], isSystemPricedLeg.rest)

ZeroSpotMarketTradeMessage ==
    [ marketId              |-> [i \in 1 .. 4 |-> 0],
      tradeId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      transactDateTime      |-> [i \in 1 .. 8 |-> 0],
      extraFlags            |-> [i \in 1 .. 1 |-> 0],
      deliveryBeginDateTime |-> [i \in 1 .. 8 |-> 0],
      deliveryEndDateTime   |-> [i \in 1 .. 8 |-> 0],
      isSystemPricedLeg     |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Market Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotMarketTradeMessage ==
    { ZeroSpotMarketTradeMessage }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.transactDateTime = one] : one \in Sample(8) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.extraFlags = one] : one \in Sample(1) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.deliveryBeginDateTime = one] : one \in Sample(8) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.deliveryEndDateTime = one] : one \in Sample(8) }
        \cup { [ZeroSpotMarketTradeMessage EXCEPT !.isSystemPricedLeg = one] : one \in Sample(1) }

(***************************************************************************)
(* Investigated Trade Message: 37 bytes                                    *)
(***************************************************************************)

InvestigatedTradeMessage ==
    [ marketId                : Sample(4),
      tradeId                 : Sample(8),
      price                   : Sample(8),
      quantity                : Sample(4),
      offMarketTradeIndicator : Sample(1),
      messageDateTime         : Sample(8),
      status                  : Sample(1),
      offMarketTradeType      : Sample(3) ]

EncodeInvestigatedTradeMessage(message) ==
    message.marketId
        \o message.tradeId
        \o message.price
        \o message.quantity
        \o message.offMarketTradeIndicator
        \o message.messageDateTime
        \o message.status
        \o message.offMarketTradeType

DecodeInvestigatedTradeMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(marketId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET offMarketTradeIndicator == ReadBytes(quantity.rest, 1) IN IF ~offMarketTradeIndicator.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(offMarketTradeIndicator.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET status == ReadBytes(messageDateTime.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET offMarketTradeType == ReadBytes(status.rest, 3) IN IF ~offMarketTradeType.ok THEN Fail ELSE
    Ok([ marketId                |-> marketId.value,
         tradeId                 |-> tradeId.value,
         price                   |-> price.value,
         quantity                |-> quantity.value,
         offMarketTradeIndicator |-> offMarketTradeIndicator.value,
         messageDateTime         |-> messageDateTime.value,
         status                  |-> status.value,
         offMarketTradeType      |-> offMarketTradeType.value ], offMarketTradeType.rest)

ZeroInvestigatedTradeMessage ==
    [ marketId                |-> [i \in 1 .. 4 |-> 0],
      tradeId                 |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      offMarketTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      messageDateTime         |-> [i \in 1 .. 8 |-> 0],
      status                  |-> [i \in 1 .. 1 |-> 0],
      offMarketTradeType      |-> [i \in 1 .. 3 |-> 0] ]

(* Investigated Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedInvestigatedTradeMessage ==
    { ZeroInvestigatedTradeMessage }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.offMarketTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroInvestigatedTradeMessage EXCEPT !.offMarketTradeType = one] : one \in Sample(3) }

(***************************************************************************)
(* Cancelled Trade Message: 36 bytes                                       *)
(***************************************************************************)

CancelledTradeMessage ==
    [ marketId                : Sample(4),
      tradeId                 : Sample(8),
      price                   : Sample(8),
      quantity                : Sample(4),
      offMarketTradeIndicator : Sample(1),
      messageDateTime         : Sample(8),
      offMarketTradeType      : Sample(3) ]

EncodeCancelledTradeMessage(message) ==
    message.marketId
        \o message.tradeId
        \o message.price
        \o message.quantity
        \o message.offMarketTradeIndicator
        \o message.messageDateTime
        \o message.offMarketTradeType

DecodeCancelledTradeMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(marketId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET offMarketTradeIndicator == ReadBytes(quantity.rest, 1) IN IF ~offMarketTradeIndicator.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(offMarketTradeIndicator.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET offMarketTradeType == ReadBytes(messageDateTime.rest, 3) IN IF ~offMarketTradeType.ok THEN Fail ELSE
    Ok([ marketId                |-> marketId.value,
         tradeId                 |-> tradeId.value,
         price                   |-> price.value,
         quantity                |-> quantity.value,
         offMarketTradeIndicator |-> offMarketTradeIndicator.value,
         messageDateTime         |-> messageDateTime.value,
         offMarketTradeType      |-> offMarketTradeType.value ], offMarketTradeType.rest)

ZeroCancelledTradeMessage ==
    [ marketId                |-> [i \in 1 .. 4 |-> 0],
      tradeId                 |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      offMarketTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      messageDateTime         |-> [i \in 1 .. 8 |-> 0],
      offMarketTradeType      |-> [i \in 1 .. 3 |-> 0] ]

(* Cancelled Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelledTradeMessage ==
    { ZeroCancelledTradeMessage }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.offMarketTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelledTradeMessage EXCEPT !.offMarketTradeType = one] : one \in Sample(3) }

(***************************************************************************)
(* Market Statistics Message: 52 bytes                                     *)
(***************************************************************************)

MarketStatisticsMessage ==
    [ marketId        : Sample(4),
      volume          : Sample(4),
      blockVolume     : Sample(4),
      efsVolume       : Sample(4),
      efpVolume       : Sample(4),
      high            : Sample(8),
      low             : Sample(8),
      vwap            : Sample(8),
      messageDateTime : Sample(8) ]

EncodeMarketStatisticsMessage(message) ==
    message.marketId
        \o message.volume
        \o message.blockVolume
        \o message.efsVolume
        \o message.efpVolume
        \o message.high
        \o message.low
        \o message.vwap
        \o message.messageDateTime

DecodeMarketStatisticsMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET volume == ReadBytes(marketId.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET blockVolume == ReadBytes(volume.rest, 4) IN IF ~blockVolume.ok THEN Fail ELSE
    LET efsVolume == ReadBytes(blockVolume.rest, 4) IN IF ~efsVolume.ok THEN Fail ELSE
    LET efpVolume == ReadBytes(efsVolume.rest, 4) IN IF ~efpVolume.ok THEN Fail ELSE
    LET high == ReadBytes(efpVolume.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET vwap == ReadBytes(low.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(vwap.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    Ok([ marketId        |-> marketId.value,
         volume          |-> volume.value,
         blockVolume     |-> blockVolume.value,
         efsVolume       |-> efsVolume.value,
         efpVolume       |-> efpVolume.value,
         high            |-> high.value,
         low             |-> low.value,
         vwap            |-> vwap.value,
         messageDateTime |-> messageDateTime.value ], messageDateTime.rest)

ZeroMarketStatisticsMessage ==
    [ marketId        |-> [i \in 1 .. 4 |-> 0],
      volume          |-> [i \in 1 .. 4 |-> 0],
      blockVolume     |-> [i \in 1 .. 4 |-> 0],
      efsVolume       |-> [i \in 1 .. 4 |-> 0],
      efpVolume       |-> [i \in 1 .. 4 |-> 0],
      high            |-> [i \in 1 .. 8 |-> 0],
      low             |-> [i \in 1 .. 8 |-> 0],
      vwap            |-> [i \in 1 .. 8 |-> 0],
      messageDateTime |-> [i \in 1 .. 8 |-> 0] ]

(* Market Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatisticsMessage ==
    { ZeroMarketStatisticsMessage }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.blockVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.efsVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.efpVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatisticsMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Market State Change Message: 13 bytes                                   *)
(***************************************************************************)

MarketStateChangeMessage ==
    [ marketId        : Sample(4),
      tradingStatus   : Sample(1),
      messageDateTime : Sample(8) ]

EncodeMarketStateChangeMessage(message) ==
    message.marketId
        \o message.tradingStatus
        \o message.messageDateTime

DecodeMarketStateChangeMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(marketId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(tradingStatus.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    Ok([ marketId        |-> marketId.value,
         tradingStatus   |-> tradingStatus.value,
         messageDateTime |-> messageDateTime.value ], messageDateTime.rest)

ZeroMarketStateChangeMessage ==
    [ marketId        |-> [i \in 1 .. 4 |-> 0],
      tradingStatus   |-> [i \in 1 .. 1 |-> 0],
      messageDateTime |-> [i \in 1 .. 8 |-> 0] ]

(* Market State Change Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStateChangeMessage ==
    { ZeroMarketStateChangeMessage }
        \cup { [ZeroMarketStateChangeMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketStateChangeMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketStateChangeMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* System Text Message: 1008 bytes                                         *)
(***************************************************************************)

SystemTextMessage ==
    [ textMessage         : Sample(200),
      messageDateTime     : Sample(8),
      textMessageExtraFld : Sample(800) ]

EncodeSystemTextMessage(message) ==
    message.textMessage
        \o message.messageDateTime
        \o message.textMessageExtraFld

DecodeSystemTextMessage(bytes) ==
    LET textMessage == ReadBytes(bytes, 200) IN IF ~textMessage.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(textMessage.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET textMessageExtraFld == ReadBytes(messageDateTime.rest, 800) IN IF ~textMessageExtraFld.ok THEN Fail ELSE
    Ok([ textMessage         |-> textMessage.value,
         messageDateTime     |-> messageDateTime.value,
         textMessageExtraFld |-> textMessageExtraFld.value ], textMessageExtraFld.rest)

ZeroSystemTextMessage ==
    [ textMessage         |-> [i \in 1 .. 200 |-> 0],
      messageDateTime     |-> [i \in 1 .. 8 |-> 0],
      textMessageExtraFld |-> [i \in 1 .. 800 |-> 0] ]

(* System Text Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTextMessage ==
    { ZeroSystemTextMessage }
        \cup { [ZeroSystemTextMessage EXCEPT !.textMessage = one] : one \in Sample(200) }
        \cup { [ZeroSystemTextMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemTextMessage EXCEPT !.textMessageExtraFld = one] : one \in Sample(800) }

(***************************************************************************)
(* Open Interest Message: 30 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ marketId           : Sample(4),
      openInterest       : Sample(4),
      openInterestChange : Sample(4),
      messageDateTime    : Sample(8),
      openInterestDate   : Sample(10) ]

EncodeOpenInterestMessage(message) ==
    message.marketId
        \o message.openInterest
        \o message.openInterestChange
        \o message.messageDateTime
        \o message.openInterestDate

DecodeOpenInterestMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET openInterest == ReadBytes(marketId.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestChange == ReadBytes(openInterest.rest, 4) IN IF ~openInterestChange.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(openInterestChange.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(messageDateTime.rest, 10) IN IF ~openInterestDate.ok THEN Fail ELSE
    Ok([ marketId           |-> marketId.value,
         openInterest       |-> openInterest.value,
         openInterestChange |-> openInterestChange.value,
         messageDateTime    |-> messageDateTime.value,
         openInterestDate   |-> openInterestDate.value ], openInterestDate.rest)

ZeroOpenInterestMessage ==
    [ marketId           |-> [i \in 1 .. 4 |-> 0],
      openInterest       |-> [i \in 1 .. 4 |-> 0],
      openInterestChange |-> [i \in 1 .. 4 |-> 0],
      messageDateTime    |-> [i \in 1 .. 8 |-> 0],
      openInterestDate   |-> [i \in 1 .. 10 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterestChange = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterestDate = one] : one \in Sample(10) }

(***************************************************************************)
(* Open Price Message: 20 bytes                                            *)
(***************************************************************************)

OpenPriceMessage ==
    [ marketId        : Sample(4),
      openPrice       : Sample(8),
      messageDateTime : Sample(8) ]

EncodeOpenPriceMessage(message) ==
    message.marketId
        \o message.openPrice
        \o message.messageDateTime

DecodeOpenPriceMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET openPrice == ReadBytes(marketId.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(openPrice.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    Ok([ marketId        |-> marketId.value,
         openPrice       |-> openPrice.value,
         messageDateTime |-> messageDateTime.value ], messageDateTime.rest)

ZeroOpenPriceMessage ==
    [ marketId        |-> [i \in 1 .. 4 |-> 0],
      openPrice       |-> [i \in 1 .. 8 |-> 0],
      messageDateTime |-> [i \in 1 .. 8 |-> 0] ]

(* Open Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenPriceMessage ==
    { ZeroOpenPriceMessage }
        \cup { [ZeroOpenPriceMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroOpenPriceMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroOpenPriceMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Close Price Message: 20 bytes                                           *)
(***************************************************************************)

ClosePriceMessage ==
    [ marketId        : Sample(4),
      closePrice      : Sample(8),
      messageDateTime : Sample(8) ]

EncodeClosePriceMessage(message) ==
    message.marketId
        \o message.closePrice
        \o message.messageDateTime

DecodeClosePriceMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET closePrice == ReadBytes(marketId.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(closePrice.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    Ok([ marketId        |-> marketId.value,
         closePrice      |-> closePrice.value,
         messageDateTime |-> messageDateTime.value ], messageDateTime.rest)

ZeroClosePriceMessage ==
    [ marketId        |-> [i \in 1 .. 4 |-> 0],
      closePrice      |-> [i \in 1 .. 8 |-> 0],
      messageDateTime |-> [i \in 1 .. 8 |-> 0] ]

(* Close Price Message at zero, then each field in turn at the values it is checked at *)
CheckedClosePriceMessage ==
    { ZeroClosePriceMessage }
        \cup { [ZeroClosePriceMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroClosePriceMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroClosePriceMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Settlement Price Message: 37 bytes                                      *)
(***************************************************************************)

SettlementPriceMessage ==
    [ marketId                              : Sample(4),
      settlementPriceWithDealPricePrecision : Sample(8),
      messageDateTime                       : Sample(8),
      isOfficial                            : Sample(1),
      valuationDateTime                     : Sample(8),
      settlementPrice                       : Sample(8) ]

EncodeSettlementPriceMessage(message) ==
    message.marketId
        \o message.settlementPriceWithDealPricePrecision
        \o message.messageDateTime
        \o message.isOfficial
        \o message.valuationDateTime
        \o message.settlementPrice

DecodeSettlementPriceMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET settlementPriceWithDealPricePrecision == ReadBytes(marketId.rest, 8) IN IF ~settlementPriceWithDealPricePrecision.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(settlementPriceWithDealPricePrecision.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET isOfficial == ReadBytes(messageDateTime.rest, 1) IN IF ~isOfficial.ok THEN Fail ELSE
    LET valuationDateTime == ReadBytes(isOfficial.rest, 8) IN IF ~valuationDateTime.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(valuationDateTime.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    Ok([ marketId                              |-> marketId.value,
         settlementPriceWithDealPricePrecision |-> settlementPriceWithDealPricePrecision.value,
         messageDateTime                       |-> messageDateTime.value,
         isOfficial                            |-> isOfficial.value,
         valuationDateTime                     |-> valuationDateTime.value,
         settlementPrice                       |-> settlementPrice.value ], settlementPrice.rest)

ZeroSettlementPriceMessage ==
    [ marketId                              |-> [i \in 1 .. 4 |-> 0],
      settlementPriceWithDealPricePrecision |-> [i \in 1 .. 8 |-> 0],
      messageDateTime                       |-> [i \in 1 .. 8 |-> 0],
      isOfficial                            |-> [i \in 1 .. 1 |-> 0],
      valuationDateTime                     |-> [i \in 1 .. 8 |-> 0],
      settlementPrice                       |-> [i \in 1 .. 8 |-> 0] ]

(* Settlement Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementPriceMessage ==
    { ZeroSettlementPriceMessage }
        \cup { [ZeroSettlementPriceMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroSettlementPriceMessage EXCEPT !.settlementPriceWithDealPricePrecision = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceMessage EXCEPT !.isOfficial = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPriceMessage EXCEPT !.valuationDateTime = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPriceMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Marker Index Prices: 61 bytes                                           *)
(***************************************************************************)

MarkerIndexPrices ==
    [ marketId                  : Sample(4),
      price                     : Sample(8),
      shortName                 : Sample(30),
      publishedDateTime         : Sample(8),
      valuationDateApplyingDate : Sample(10),
      status                    : Sample(1) ]

EncodeMarkerIndexPrices(message) ==
    message.marketId
        \o message.price
        \o message.shortName
        \o message.publishedDateTime
        \o message.valuationDateApplyingDate
        \o message.status

DecodeMarkerIndexPrices(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET price == ReadBytes(marketId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET shortName == ReadBytes(price.rest, 30) IN IF ~shortName.ok THEN Fail ELSE
    LET publishedDateTime == ReadBytes(shortName.rest, 8) IN IF ~publishedDateTime.ok THEN Fail ELSE
    LET valuationDateApplyingDate == ReadBytes(publishedDateTime.rest, 10) IN IF ~valuationDateApplyingDate.ok THEN Fail ELSE
    LET status == ReadBytes(valuationDateApplyingDate.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ marketId                  |-> marketId.value,
         price                     |-> price.value,
         shortName                 |-> shortName.value,
         publishedDateTime         |-> publishedDateTime.value,
         valuationDateApplyingDate |-> valuationDateApplyingDate.value,
         status                    |-> status.value ], status.rest)

ZeroMarkerIndexPrices ==
    [ marketId                  |-> [i \in 1 .. 4 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      shortName                 |-> [i \in 1 .. 30 |-> 0],
      publishedDateTime         |-> [i \in 1 .. 8 |-> 0],
      valuationDateApplyingDate |-> [i \in 1 .. 10 |-> 0],
      status                    |-> [i \in 1 .. 1 |-> 0] ]

(* Marker Index Prices at zero, then each field in turn at the values it is checked at *)
CheckedMarkerIndexPrices ==
    { ZeroMarkerIndexPrices }
        \cup { [ZeroMarkerIndexPrices EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarkerIndexPrices EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMarkerIndexPrices EXCEPT !.shortName = one] : one \in Sample(30) }
        \cup { [ZeroMarkerIndexPrices EXCEPT !.publishedDateTime = one] : one \in Sample(8) }
        \cup { [ZeroMarkerIndexPrices EXCEPT !.valuationDateApplyingDate = one] : one \in Sample(10) }
        \cup { [ZeroMarkerIndexPrices EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Day Market Summary Message: 80 bytes                             *)
(***************************************************************************)

EndOfDayMarketSummaryMessage ==
    [ marketId                              : Sample(4),
      volume                                : Sample(4),
      blockVolume                           : Sample(4),
      efsVolume                             : Sample(4),
      efpVolume                             : Sample(4),
      openingPrice                          : Sample(8),
      high                                  : Sample(8),
      low                                   : Sample(8),
      vwap                                  : Sample(8),
      settlementPriceWithDealPricePrecision : Sample(8),
      openInterest                          : Sample(4),
      messageDateTime                       : Sample(8),
      settlementPrice                       : Sample(8) ]

EncodeEndOfDayMarketSummaryMessage(message) ==
    message.marketId
        \o message.volume
        \o message.blockVolume
        \o message.efsVolume
        \o message.efpVolume
        \o message.openingPrice
        \o message.high
        \o message.low
        \o message.vwap
        \o message.settlementPriceWithDealPricePrecision
        \o message.openInterest
        \o message.messageDateTime
        \o message.settlementPrice

DecodeEndOfDayMarketSummaryMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET volume == ReadBytes(marketId.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET blockVolume == ReadBytes(volume.rest, 4) IN IF ~blockVolume.ok THEN Fail ELSE
    LET efsVolume == ReadBytes(blockVolume.rest, 4) IN IF ~efsVolume.ok THEN Fail ELSE
    LET efpVolume == ReadBytes(efsVolume.rest, 4) IN IF ~efpVolume.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(efpVolume.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET high == ReadBytes(openingPrice.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET vwap == ReadBytes(low.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET settlementPriceWithDealPricePrecision == ReadBytes(vwap.rest, 8) IN IF ~settlementPriceWithDealPricePrecision.ok THEN Fail ELSE
    LET openInterest == ReadBytes(settlementPriceWithDealPricePrecision.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(openInterest.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(messageDateTime.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    Ok([ marketId                              |-> marketId.value,
         volume                                |-> volume.value,
         blockVolume                           |-> blockVolume.value,
         efsVolume                             |-> efsVolume.value,
         efpVolume                             |-> efpVolume.value,
         openingPrice                          |-> openingPrice.value,
         high                                  |-> high.value,
         low                                   |-> low.value,
         vwap                                  |-> vwap.value,
         settlementPriceWithDealPricePrecision |-> settlementPriceWithDealPricePrecision.value,
         openInterest                          |-> openInterest.value,
         messageDateTime                       |-> messageDateTime.value,
         settlementPrice                       |-> settlementPrice.value ], settlementPrice.rest)

ZeroEndOfDayMarketSummaryMessage ==
    [ marketId                              |-> [i \in 1 .. 4 |-> 0],
      volume                                |-> [i \in 1 .. 4 |-> 0],
      blockVolume                           |-> [i \in 1 .. 4 |-> 0],
      efsVolume                             |-> [i \in 1 .. 4 |-> 0],
      efpVolume                             |-> [i \in 1 .. 4 |-> 0],
      openingPrice                          |-> [i \in 1 .. 8 |-> 0],
      high                                  |-> [i \in 1 .. 8 |-> 0],
      low                                   |-> [i \in 1 .. 8 |-> 0],
      vwap                                  |-> [i \in 1 .. 8 |-> 0],
      settlementPriceWithDealPricePrecision |-> [i \in 1 .. 8 |-> 0],
      openInterest                          |-> [i \in 1 .. 4 |-> 0],
      messageDateTime                       |-> [i \in 1 .. 8 |-> 0],
      settlementPrice                       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Market Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMarketSummaryMessage ==
    { ZeroEndOfDayMarketSummaryMessage }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.blockVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.efsVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.efpVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.settlementPriceWithDealPricePrecision = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMarketSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Event Message: 13 bytes                                          *)
(***************************************************************************)

MarketEventMessage ==
    [ marketId        : Sample(4),
      eventType       : Sample(1),
      messageDateTime : Sample(8) ]

EncodeMarketEventMessage(message) ==
    message.marketId
        \o message.eventType
        \o message.messageDateTime

DecodeMarketEventMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET eventType == ReadBytes(marketId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(eventType.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    Ok([ marketId        |-> marketId.value,
         eventType       |-> eventType.value,
         messageDateTime |-> messageDateTime.value ], messageDateTime.rest)

ZeroMarketEventMessage ==
    [ marketId        |-> [i \in 1 .. 4 |-> 0],
      eventType       |-> [i \in 1 .. 1 |-> 0],
      messageDateTime |-> [i \in 1 .. 8 |-> 0] ]

(* Market Event Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketEventMessage ==
    { ZeroMarketEventMessage }
        \cup { [ZeroMarketEventMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketEventMessage EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroMarketEventMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Pre Open Price Indicator Message: 25 bytes                              *)
(***************************************************************************)

PreOpenPriceIndicatorMessage ==
    [ marketId         : Sample(4),
      preOpenPrice     : Sample(8),
      messageDateTime  : Sample(8),
      hasPreOpenVolume : Sample(1),
      preOpenVolume    : Sample(4) ]

EncodePreOpenPriceIndicatorMessage(message) ==
    message.marketId
        \o message.preOpenPrice
        \o message.messageDateTime
        \o message.hasPreOpenVolume
        \o message.preOpenVolume

DecodePreOpenPriceIndicatorMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET preOpenPrice == ReadBytes(marketId.rest, 8) IN IF ~preOpenPrice.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(preOpenPrice.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET hasPreOpenVolume == ReadBytes(messageDateTime.rest, 1) IN IF ~hasPreOpenVolume.ok THEN Fail ELSE
    LET preOpenVolume == ReadBytes(hasPreOpenVolume.rest, 4) IN IF ~preOpenVolume.ok THEN Fail ELSE
    Ok([ marketId         |-> marketId.value,
         preOpenPrice     |-> preOpenPrice.value,
         messageDateTime  |-> messageDateTime.value,
         hasPreOpenVolume |-> hasPreOpenVolume.value,
         preOpenVolume    |-> preOpenVolume.value ], preOpenVolume.rest)

ZeroPreOpenPriceIndicatorMessage ==
    [ marketId         |-> [i \in 1 .. 4 |-> 0],
      preOpenPrice     |-> [i \in 1 .. 8 |-> 0],
      messageDateTime  |-> [i \in 1 .. 8 |-> 0],
      hasPreOpenVolume |-> [i \in 1 .. 1 |-> 0],
      preOpenVolume    |-> [i \in 1 .. 4 |-> 0] ]

(* Pre Open Price Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedPreOpenPriceIndicatorMessage ==
    { ZeroPreOpenPriceIndicatorMessage }
        \cup { [ZeroPreOpenPriceIndicatorMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroPreOpenPriceIndicatorMessage EXCEPT !.preOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroPreOpenPriceIndicatorMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroPreOpenPriceIndicatorMessage EXCEPT !.hasPreOpenVolume = one] : one \in Sample(1) }
        \cup { [ZeroPreOpenPriceIndicatorMessage EXCEPT !.preOpenVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Strip Info Message: 88 bytes                                            *)
(***************************************************************************)

StripInfoMessage ==
    [ oldStripId : Sample(2),
      stripType  : Sample(20),
      beginYear  : Sample(2),
      beginMonth : Sample(2),
      beginDay   : Sample(2),
      endYear    : Sample(2),
      endMonth   : Sample(2),
      endDay     : Sample(2),
      stripInfo  : Sample(50),
      stripId    : Sample(4) ]

EncodeStripInfoMessage(message) ==
    message.oldStripId
        \o message.stripType
        \o message.beginYear
        \o message.beginMonth
        \o message.beginDay
        \o message.endYear
        \o message.endMonth
        \o message.endDay
        \o message.stripInfo
        \o message.stripId

DecodeStripInfoMessage(bytes) ==
    LET oldStripId == ReadBytes(bytes, 2) IN IF ~oldStripId.ok THEN Fail ELSE
    LET stripType == ReadBytes(oldStripId.rest, 20) IN IF ~stripType.ok THEN Fail ELSE
    LET beginYear == ReadBytes(stripType.rest, 2) IN IF ~beginYear.ok THEN Fail ELSE
    LET beginMonth == ReadBytes(beginYear.rest, 2) IN IF ~beginMonth.ok THEN Fail ELSE
    LET beginDay == ReadBytes(beginMonth.rest, 2) IN IF ~beginDay.ok THEN Fail ELSE
    LET endYear == ReadBytes(beginDay.rest, 2) IN IF ~endYear.ok THEN Fail ELSE
    LET endMonth == ReadBytes(endYear.rest, 2) IN IF ~endMonth.ok THEN Fail ELSE
    LET endDay == ReadBytes(endMonth.rest, 2) IN IF ~endDay.ok THEN Fail ELSE
    LET stripInfo == ReadBytes(endDay.rest, 50) IN IF ~stripInfo.ok THEN Fail ELSE
    LET stripId == ReadBytes(stripInfo.rest, 4) IN IF ~stripId.ok THEN Fail ELSE
    Ok([ oldStripId |-> oldStripId.value,
         stripType  |-> stripType.value,
         beginYear  |-> beginYear.value,
         beginMonth |-> beginMonth.value,
         beginDay   |-> beginDay.value,
         endYear    |-> endYear.value,
         endMonth   |-> endMonth.value,
         endDay     |-> endDay.value,
         stripInfo  |-> stripInfo.value,
         stripId    |-> stripId.value ], stripId.rest)

ZeroStripInfoMessage ==
    [ oldStripId |-> [i \in 1 .. 2 |-> 0],
      stripType  |-> [i \in 1 .. 20 |-> 0],
      beginYear  |-> [i \in 1 .. 2 |-> 0],
      beginMonth |-> [i \in 1 .. 2 |-> 0],
      beginDay   |-> [i \in 1 .. 2 |-> 0],
      endYear    |-> [i \in 1 .. 2 |-> 0],
      endMonth   |-> [i \in 1 .. 2 |-> 0],
      endDay     |-> [i \in 1 .. 2 |-> 0],
      stripInfo  |-> [i \in 1 .. 50 |-> 0],
      stripId    |-> [i \in 1 .. 4 |-> 0] ]

(* Strip Info Message at zero, then each field in turn at the values it is checked at *)
CheckedStripInfoMessage ==
    { ZeroStripInfoMessage }
        \cup { [ZeroStripInfoMessage EXCEPT !.oldStripId = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.stripType = one] : one \in Sample(20) }
        \cup { [ZeroStripInfoMessage EXCEPT !.beginYear = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.beginMonth = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.beginDay = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.endYear = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.endMonth = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.endDay = one] : one \in Sample(2) }
        \cup { [ZeroStripInfoMessage EXCEPT !.stripInfo = one] : one \in Sample(50) }
        \cup { [ZeroStripInfoMessage EXCEPT !.stripId = one] : one \in Sample(4) }

(***************************************************************************)
(* Interval Price Limit Notification Message: 34 bytes                     *)
(***************************************************************************)

IntervalPriceLimitNotificationMessage ==
    [ marketId             : Sample(4),
      iplHoldType          : Sample(1),
      notificationDateTime : Sample(8),
      isUp                 : Sample(1),
      iplHoldDuration      : Sample(4),
      iplUp                : Sample(8),
      iplDown              : Sample(8) ]

EncodeIntervalPriceLimitNotificationMessage(message) ==
    message.marketId
        \o message.iplHoldType
        \o message.notificationDateTime
        \o message.isUp
        \o message.iplHoldDuration
        \o message.iplUp
        \o message.iplDown

DecodeIntervalPriceLimitNotificationMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET iplHoldType == ReadBytes(marketId.rest, 1) IN IF ~iplHoldType.ok THEN Fail ELSE
    LET notificationDateTime == ReadBytes(iplHoldType.rest, 8) IN IF ~notificationDateTime.ok THEN Fail ELSE
    LET isUp == ReadBytes(notificationDateTime.rest, 1) IN IF ~isUp.ok THEN Fail ELSE
    LET iplHoldDuration == ReadBytes(isUp.rest, 4) IN IF ~iplHoldDuration.ok THEN Fail ELSE
    LET iplUp == ReadBytes(iplHoldDuration.rest, 8) IN IF ~iplUp.ok THEN Fail ELSE
    LET iplDown == ReadBytes(iplUp.rest, 8) IN IF ~iplDown.ok THEN Fail ELSE
    Ok([ marketId             |-> marketId.value,
         iplHoldType          |-> iplHoldType.value,
         notificationDateTime |-> notificationDateTime.value,
         isUp                 |-> isUp.value,
         iplHoldDuration      |-> iplHoldDuration.value,
         iplUp                |-> iplUp.value,
         iplDown              |-> iplDown.value ], iplDown.rest)

ZeroIntervalPriceLimitNotificationMessage ==
    [ marketId             |-> [i \in 1 .. 4 |-> 0],
      iplHoldType          |-> [i \in 1 .. 1 |-> 0],
      notificationDateTime |-> [i \in 1 .. 8 |-> 0],
      isUp                 |-> [i \in 1 .. 1 |-> 0],
      iplHoldDuration      |-> [i \in 1 .. 4 |-> 0],
      iplUp                |-> [i \in 1 .. 8 |-> 0],
      iplDown              |-> [i \in 1 .. 8 |-> 0] ]

(* Interval Price Limit Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedIntervalPriceLimitNotificationMessage ==
    { ZeroIntervalPriceLimitNotificationMessage }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.iplHoldType = one] : one \in Sample(1) }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.notificationDateTime = one] : one \in Sample(8) }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.isUp = one] : one \in Sample(1) }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.iplHoldDuration = one] : one \in Sample(4) }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.iplUp = one] : one \in Sample(8) }
        \cup { [ZeroIntervalPriceLimitNotificationMessage EXCEPT !.iplDown = one] : one \in Sample(8) }

(***************************************************************************)
(* Leg Definition: 8 bytes                                                 *)
(***************************************************************************)

LegDefinition ==
    [ legBodyLength : Sample(1),
      legMarketId   : Sample(4),
      legRatio      : Sample(2),
      legSide       : Sample(1) ]

EncodeLegDefinition(message) ==
    message.legBodyLength
        \o message.legMarketId
        \o message.legRatio
        \o message.legSide

DecodeLegDefinition(bytes) ==
    LET legBodyLength == ReadBytes(bytes, 1) IN IF ~legBodyLength.ok THEN Fail ELSE
    LET legMarketId == ReadBytes(legBodyLength.rest, 4) IN IF ~legMarketId.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legMarketId.rest, 2) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatio.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legBodyLength |-> legBodyLength.value,
         legMarketId   |-> legMarketId.value,
         legRatio      |-> legRatio.value,
         legSide       |-> legSide.value ], legSide.rest)

ZeroLegDefinition ==
    [ legBodyLength |-> [i \in 1 .. 1 |-> 0],
      legMarketId   |-> [i \in 1 .. 4 |-> 0],
      legRatio      |-> [i \in 1 .. 2 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Definition at zero, then each field in turn at the values it is checked at *)
CheckedLegDefinition ==
    { ZeroLegDefinition }
        \cup { [ZeroLegDefinition EXCEPT !.legBodyLength = one] : one \in Sample(1) }
        \cup { [ZeroLegDefinition EXCEPT !.legMarketId = one] : one \in Sample(4) }
        \cup { [ZeroLegDefinition EXCEPT !.legRatio = one] : one \in Sample(2) }
        \cup { [ZeroLegDefinition EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Leg Definition, written one after another *)
RECURSIVE EncodeLegDefinitionList(_)
EncodeLegDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegDefinition(Head(messages)) \o EncodeLegDefinitionList(Tail(messages))

(* As many Leg Definition as the field that counts them says *)
RECURSIVE ReadLegDefinitionList(_, _)
ReadLegDefinitionList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegDefinitionList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Definition of each kind, for the lists that carry them *)
OneLegDefinition == { ZeroLegDefinition }

(***************************************************************************)
(* New Futures Strategy Definition Message                                 *)
(***************************************************************************)

NewFuturesStrategyDefinitionMessage ==
    [ marketId              : Sample(4),
      futuresContractSymbol : Sample(70),
      tradingStatus         : Sample(1),
      orderPriceDenominator : Sample(1),
      incrementPrice        : Sample(4),
      incrementQty          : Sample(4),
      minQty                : Sample(4),
      legDefinition         : SampleLists(OneLegDefinition),
      securitySubType       : Sample(2),
      isBlockOnly           : Sample(1),
      strategySymbol        : Sample(18),
      gtAllowed             : Sample(1) ]

EncodeNewFuturesStrategyDefinitionMessage(message) ==
    message.marketId
        \o message.futuresContractSymbol
        \o message.tradingStatus
        \o message.orderPriceDenominator
        \o message.incrementPrice
        \o message.incrementQty
        \o message.minQty
        \o EncodeUIntBE(Len(message.legDefinition), 1)
        \o EncodeLegDefinitionList(message.legDefinition)
        \o message.securitySubType
        \o message.isBlockOnly
        \o message.strategySymbol
        \o message.gtAllowed

DecodeNewFuturesStrategyDefinitionMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET futuresContractSymbol == ReadBytes(marketId.rest, 70) IN IF ~futuresContractSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(futuresContractSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET orderPriceDenominator == ReadBytes(tradingStatus.rest, 1) IN IF ~orderPriceDenominator.ok THEN Fail ELSE
    LET incrementPrice == ReadBytes(orderPriceDenominator.rest, 4) IN IF ~incrementPrice.ok THEN Fail ELSE
    LET incrementQty == ReadBytes(incrementPrice.rest, 4) IN IF ~incrementQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(incrementQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET numberOfLegDefinitions == ReadUIntBE(minQty.rest, 1) IN IF ~numberOfLegDefinitions.ok THEN Fail ELSE
    LET legDefinition == ReadLegDefinitionList(numberOfLegDefinitions.rest, numberOfLegDefinitions.value) IN IF ~legDefinition.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(legDefinition.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET isBlockOnly == ReadBytes(securitySubType.rest, 1) IN IF ~isBlockOnly.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(isBlockOnly.rest, 18) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET gtAllowed == ReadBytes(strategySymbol.rest, 1) IN IF ~gtAllowed.ok THEN Fail ELSE
    Ok([ marketId              |-> marketId.value,
         futuresContractSymbol |-> futuresContractSymbol.value,
         tradingStatus         |-> tradingStatus.value,
         orderPriceDenominator |-> orderPriceDenominator.value,
         incrementPrice        |-> incrementPrice.value,
         incrementQty          |-> incrementQty.value,
         minQty                |-> minQty.value,
         legDefinition         |-> legDefinition.value,
         securitySubType       |-> securitySubType.value,
         isBlockOnly           |-> isBlockOnly.value,
         strategySymbol        |-> strategySymbol.value,
         gtAllowed             |-> gtAllowed.value ], gtAllowed.rest)

ZeroNewFuturesStrategyDefinitionMessage ==
    [ marketId              |-> [i \in 1 .. 4 |-> 0],
      futuresContractSymbol |-> [i \in 1 .. 70 |-> 0],
      tradingStatus         |-> [i \in 1 .. 1 |-> 0],
      orderPriceDenominator |-> [i \in 1 .. 1 |-> 0],
      incrementPrice        |-> [i \in 1 .. 4 |-> 0],
      incrementQty          |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      legDefinition         |-> << >>,
      securitySubType       |-> [i \in 1 .. 2 |-> 0],
      isBlockOnly           |-> [i \in 1 .. 1 |-> 0],
      strategySymbol        |-> [i \in 1 .. 18 |-> 0],
      gtAllowed             |-> [i \in 1 .. 1 |-> 0] ]

(* New Futures Strategy Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedNewFuturesStrategyDefinitionMessage ==
    { ZeroNewFuturesStrategyDefinitionMessage }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.futuresContractSymbol = one] : one \in Sample(70) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.orderPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.incrementPrice = one] : one \in Sample(4) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.incrementQty = one] : one \in Sample(4) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.legDefinition = one] : one \in SampleLists(OneLegDefinition) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.isBlockOnly = one] : one \in Sample(1) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.strategySymbol = one] : one \in Sample(18) }
        \cup { [ZeroNewFuturesStrategyDefinitionMessage EXCEPT !.gtAllowed = one] : one \in Sample(1) }

(***************************************************************************)
(* New Expiry Message: 502 bytes                                           *)
(***************************************************************************)

NewExpiryMessage ==
    [ marketId                           : Sample(4),
      marketTypeId                       : Sample(2),
      orderPriceDenominator              : Sample(1),
      incrementPrice                     : Sample(4),
      incrementQty                       : Sample(4),
      lotSize                            : Sample(4),
      marketDesc                         : Sample(120),
      maturityYear                       : Sample(2),
      maturityMonth                      : Sample(2),
      maturityDay                        : Sample(2),
      dealPriceDenominator               : Sample(1),
      minQty                             : Sample(4),
      unitQuantity                       : Sample(4),
      currency                           : Sample(20),
      clearedAlias                       : Sample(15),
      minPrice                           : Sample(8),
      maxPrice                           : Sample(8),
      productId                          : Sample(4),
      productName                        : Sample(62),
      hubId                              : Sample(4),
      hubAlias                           : Sample(80),
      stripId                            : Sample(4),
      stripName                          : Sample(39),
      settlePriceDenominator             : Sample(1),
      micCode                            : Sample(4),
      unitQtyDenominator                 : Sample(1),
      offExchangeIncrementQtyDenominator : Sample(1),
      offExchangeIncrementQty            : Sample(4),
      offExchangeIncrementPrice          : Sample(4),
      offExchangeIncrementOptionPrice    : Sample(4),
      contractSymbol                     : Sample(35),
      isin                               : Sample(12),
      numDecimalsOptionsPrice            : Sample(1),
      hedgeMarketId                      : Sample(4),
      settlementType                     : Sample(1),
      gtAllowed                          : Sample(1),
      crossOrderSupported                : Sample(1),
      unitOfMeasure                      : Sample(30) ]

EncodeNewExpiryMessage(message) ==
    message.marketId
        \o message.marketTypeId
        \o message.orderPriceDenominator
        \o message.incrementPrice
        \o message.incrementQty
        \o message.lotSize
        \o message.marketDesc
        \o message.maturityYear
        \o message.maturityMonth
        \o message.maturityDay
        \o message.dealPriceDenominator
        \o message.minQty
        \o message.unitQuantity
        \o message.currency
        \o message.clearedAlias
        \o message.minPrice
        \o message.maxPrice
        \o message.productId
        \o message.productName
        \o message.hubId
        \o message.hubAlias
        \o message.stripId
        \o message.stripName
        \o message.settlePriceDenominator
        \o message.micCode
        \o message.unitQtyDenominator
        \o message.offExchangeIncrementQtyDenominator
        \o message.offExchangeIncrementQty
        \o message.offExchangeIncrementPrice
        \o message.offExchangeIncrementOptionPrice
        \o message.contractSymbol
        \o message.isin
        \o message.numDecimalsOptionsPrice
        \o message.hedgeMarketId
        \o message.settlementType
        \o message.gtAllowed
        \o message.crossOrderSupported
        \o message.unitOfMeasure

DecodeNewExpiryMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketTypeId == ReadBytes(marketId.rest, 2) IN IF ~marketTypeId.ok THEN Fail ELSE
    LET orderPriceDenominator == ReadBytes(marketTypeId.rest, 1) IN IF ~orderPriceDenominator.ok THEN Fail ELSE
    LET incrementPrice == ReadBytes(orderPriceDenominator.rest, 4) IN IF ~incrementPrice.ok THEN Fail ELSE
    LET incrementQty == ReadBytes(incrementPrice.rest, 4) IN IF ~incrementQty.ok THEN Fail ELSE
    LET lotSize == ReadBytes(incrementQty.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET marketDesc == ReadBytes(lotSize.rest, 120) IN IF ~marketDesc.ok THEN Fail ELSE
    LET maturityYear == ReadBytes(marketDesc.rest, 2) IN IF ~maturityYear.ok THEN Fail ELSE
    LET maturityMonth == ReadBytes(maturityYear.rest, 2) IN IF ~maturityMonth.ok THEN Fail ELSE
    LET maturityDay == ReadBytes(maturityMonth.rest, 2) IN IF ~maturityDay.ok THEN Fail ELSE
    LET dealPriceDenominator == ReadBytes(maturityDay.rest, 1) IN IF ~dealPriceDenominator.ok THEN Fail ELSE
    LET minQty == ReadBytes(dealPriceDenominator.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET unitQuantity == ReadBytes(minQty.rest, 4) IN IF ~unitQuantity.ok THEN Fail ELSE
    LET currency == ReadBytes(unitQuantity.rest, 20) IN IF ~currency.ok THEN Fail ELSE
    LET clearedAlias == ReadBytes(currency.rest, 15) IN IF ~clearedAlias.ok THEN Fail ELSE
    LET minPrice == ReadBytes(clearedAlias.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(minPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET productId == ReadBytes(maxPrice.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET productName == ReadBytes(productId.rest, 62) IN IF ~productName.ok THEN Fail ELSE
    LET hubId == ReadBytes(productName.rest, 4) IN IF ~hubId.ok THEN Fail ELSE
    LET hubAlias == ReadBytes(hubId.rest, 80) IN IF ~hubAlias.ok THEN Fail ELSE
    LET stripId == ReadBytes(hubAlias.rest, 4) IN IF ~stripId.ok THEN Fail ELSE
    LET stripName == ReadBytes(stripId.rest, 39) IN IF ~stripName.ok THEN Fail ELSE
    LET settlePriceDenominator == ReadBytes(stripName.rest, 1) IN IF ~settlePriceDenominator.ok THEN Fail ELSE
    LET micCode == ReadBytes(settlePriceDenominator.rest, 4) IN IF ~micCode.ok THEN Fail ELSE
    LET unitQtyDenominator == ReadBytes(micCode.rest, 1) IN IF ~unitQtyDenominator.ok THEN Fail ELSE
    LET offExchangeIncrementQtyDenominator == ReadBytes(unitQtyDenominator.rest, 1) IN IF ~offExchangeIncrementQtyDenominator.ok THEN Fail ELSE
    LET offExchangeIncrementQty == ReadBytes(offExchangeIncrementQtyDenominator.rest, 4) IN IF ~offExchangeIncrementQty.ok THEN Fail ELSE
    LET offExchangeIncrementPrice == ReadBytes(offExchangeIncrementQty.rest, 4) IN IF ~offExchangeIncrementPrice.ok THEN Fail ELSE
    LET offExchangeIncrementOptionPrice == ReadBytes(offExchangeIncrementPrice.rest, 4) IN IF ~offExchangeIncrementOptionPrice.ok THEN Fail ELSE
    LET contractSymbol == ReadBytes(offExchangeIncrementOptionPrice.rest, 35) IN IF ~contractSymbol.ok THEN Fail ELSE
    LET isin == ReadBytes(contractSymbol.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET numDecimalsOptionsPrice == ReadBytes(isin.rest, 1) IN IF ~numDecimalsOptionsPrice.ok THEN Fail ELSE
    LET hedgeMarketId == ReadBytes(numDecimalsOptionsPrice.rest, 4) IN IF ~hedgeMarketId.ok THEN Fail ELSE
    LET settlementType == ReadBytes(hedgeMarketId.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET gtAllowed == ReadBytes(settlementType.rest, 1) IN IF ~gtAllowed.ok THEN Fail ELSE
    LET crossOrderSupported == ReadBytes(gtAllowed.rest, 1) IN IF ~crossOrderSupported.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(crossOrderSupported.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    Ok([ marketId                           |-> marketId.value,
         marketTypeId                       |-> marketTypeId.value,
         orderPriceDenominator              |-> orderPriceDenominator.value,
         incrementPrice                     |-> incrementPrice.value,
         incrementQty                       |-> incrementQty.value,
         lotSize                            |-> lotSize.value,
         marketDesc                         |-> marketDesc.value,
         maturityYear                       |-> maturityYear.value,
         maturityMonth                      |-> maturityMonth.value,
         maturityDay                        |-> maturityDay.value,
         dealPriceDenominator               |-> dealPriceDenominator.value,
         minQty                             |-> minQty.value,
         unitQuantity                       |-> unitQuantity.value,
         currency                           |-> currency.value,
         clearedAlias                       |-> clearedAlias.value,
         minPrice                           |-> minPrice.value,
         maxPrice                           |-> maxPrice.value,
         productId                          |-> productId.value,
         productName                        |-> productName.value,
         hubId                              |-> hubId.value,
         hubAlias                           |-> hubAlias.value,
         stripId                            |-> stripId.value,
         stripName                          |-> stripName.value,
         settlePriceDenominator             |-> settlePriceDenominator.value,
         micCode                            |-> micCode.value,
         unitQtyDenominator                 |-> unitQtyDenominator.value,
         offExchangeIncrementQtyDenominator |-> offExchangeIncrementQtyDenominator.value,
         offExchangeIncrementQty            |-> offExchangeIncrementQty.value,
         offExchangeIncrementPrice          |-> offExchangeIncrementPrice.value,
         offExchangeIncrementOptionPrice    |-> offExchangeIncrementOptionPrice.value,
         contractSymbol                     |-> contractSymbol.value,
         isin                               |-> isin.value,
         numDecimalsOptionsPrice            |-> numDecimalsOptionsPrice.value,
         hedgeMarketId                      |-> hedgeMarketId.value,
         settlementType                     |-> settlementType.value,
         gtAllowed                          |-> gtAllowed.value,
         crossOrderSupported                |-> crossOrderSupported.value,
         unitOfMeasure                      |-> unitOfMeasure.value ], unitOfMeasure.rest)

ZeroNewExpiryMessage ==
    [ marketId                           |-> [i \in 1 .. 4 |-> 0],
      marketTypeId                       |-> [i \in 1 .. 2 |-> 0],
      orderPriceDenominator              |-> [i \in 1 .. 1 |-> 0],
      incrementPrice                     |-> [i \in 1 .. 4 |-> 0],
      incrementQty                       |-> [i \in 1 .. 4 |-> 0],
      lotSize                            |-> [i \in 1 .. 4 |-> 0],
      marketDesc                         |-> [i \in 1 .. 120 |-> 0],
      maturityYear                       |-> [i \in 1 .. 2 |-> 0],
      maturityMonth                      |-> [i \in 1 .. 2 |-> 0],
      maturityDay                        |-> [i \in 1 .. 2 |-> 0],
      dealPriceDenominator               |-> [i \in 1 .. 1 |-> 0],
      minQty                             |-> [i \in 1 .. 4 |-> 0],
      unitQuantity                       |-> [i \in 1 .. 4 |-> 0],
      currency                           |-> [i \in 1 .. 20 |-> 0],
      clearedAlias                       |-> [i \in 1 .. 15 |-> 0],
      minPrice                           |-> [i \in 1 .. 8 |-> 0],
      maxPrice                           |-> [i \in 1 .. 8 |-> 0],
      productId                          |-> [i \in 1 .. 4 |-> 0],
      productName                        |-> [i \in 1 .. 62 |-> 0],
      hubId                              |-> [i \in 1 .. 4 |-> 0],
      hubAlias                           |-> [i \in 1 .. 80 |-> 0],
      stripId                            |-> [i \in 1 .. 4 |-> 0],
      stripName                          |-> [i \in 1 .. 39 |-> 0],
      settlePriceDenominator             |-> [i \in 1 .. 1 |-> 0],
      micCode                            |-> [i \in 1 .. 4 |-> 0],
      unitQtyDenominator                 |-> [i \in 1 .. 1 |-> 0],
      offExchangeIncrementQtyDenominator |-> [i \in 1 .. 1 |-> 0],
      offExchangeIncrementQty            |-> [i \in 1 .. 4 |-> 0],
      offExchangeIncrementPrice          |-> [i \in 1 .. 4 |-> 0],
      offExchangeIncrementOptionPrice    |-> [i \in 1 .. 4 |-> 0],
      contractSymbol                     |-> [i \in 1 .. 35 |-> 0],
      isin                               |-> [i \in 1 .. 12 |-> 0],
      numDecimalsOptionsPrice            |-> [i \in 1 .. 1 |-> 0],
      hedgeMarketId                      |-> [i \in 1 .. 4 |-> 0],
      settlementType                     |-> [i \in 1 .. 1 |-> 0],
      gtAllowed                          |-> [i \in 1 .. 1 |-> 0],
      crossOrderSupported                |-> [i \in 1 .. 1 |-> 0],
      unitOfMeasure                      |-> [i \in 1 .. 30 |-> 0] ]

(* New Expiry Message at zero, then each field in turn at the values it is checked at *)
CheckedNewExpiryMessage ==
    { ZeroNewExpiryMessage }
        \cup { [ZeroNewExpiryMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.marketTypeId = one] : one \in Sample(2) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.orderPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.incrementPrice = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.incrementQty = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.marketDesc = one] : one \in Sample(120) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.maturityYear = one] : one \in Sample(2) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.maturityMonth = one] : one \in Sample(2) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.maturityDay = one] : one \in Sample(2) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.dealPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.unitQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.currency = one] : one \in Sample(20) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.clearedAlias = one] : one \in Sample(15) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.productName = one] : one \in Sample(62) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.hubId = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.hubAlias = one] : one \in Sample(80) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.stripId = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.stripName = one] : one \in Sample(39) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.settlePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.micCode = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.unitQtyDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.offExchangeIncrementQtyDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.offExchangeIncrementQty = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.offExchangeIncrementPrice = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.offExchangeIncrementOptionPrice = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.contractSymbol = one] : one \in Sample(35) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.numDecimalsOptionsPrice = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.hedgeMarketId = one] : one \in Sample(4) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.gtAllowed = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.crossOrderSupported = one] : one \in Sample(1) }
        \cup { [ZeroNewExpiryMessage EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }

(***************************************************************************)
(* Special Field                                                           *)
(***************************************************************************)

SpecialField ==
    [ specialFieldId    : Sample(1),
      specialFieldValue : SampleBytes ]

EncodeSpecialField(message) ==
    message.specialFieldId
        \o EncodeUIntBE(Len(message.specialFieldValue), 2)
        \o message.specialFieldValue

DecodeSpecialField(bytes) ==
    LET specialFieldId == ReadBytes(bytes, 1) IN IF ~specialFieldId.ok THEN Fail ELSE
    LET specialFieldLength == ReadUIntBE(specialFieldId.rest, 2) IN IF ~specialFieldLength.ok THEN Fail ELSE
    LET specialFieldValue == ReadBytes(specialFieldLength.rest, specialFieldLength.value) IN IF ~specialFieldValue.ok THEN Fail ELSE
    Ok([ specialFieldId    |-> specialFieldId.value,
         specialFieldValue |-> specialFieldValue.value ], specialFieldValue.rest)

ZeroSpecialField ==
    [ specialFieldId    |-> [i \in 1 .. 1 |-> 0],
      specialFieldValue |-> << >> ]

(* Special Field at zero, then each field in turn at the values it is checked at *)
CheckedSpecialField ==
    { ZeroSpecialField }
        \cup { [ZeroSpecialField EXCEPT !.specialFieldId = one] : one \in Sample(1) }
        \cup { [ZeroSpecialField EXCEPT !.specialFieldValue = one] : one \in SampleBytes }

(* A run of Special Field, written one after another *)
RECURSIVE EncodeSpecialFieldList(_)
EncodeSpecialFieldList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSpecialField(Head(messages)) \o EncodeSpecialFieldList(Tail(messages))

(* As many Special Field as the field that counts them says *)
RECURSIVE ReadSpecialFieldList(_, _)
ReadSpecialFieldList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSpecialField(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSpecialFieldList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Special Field of each kind, for the lists that carry them *)
OneSpecialField == { ZeroSpecialField }

(***************************************************************************)
(* Special Field Message                                                   *)
(***************************************************************************)

SpecialFieldMessage ==
    [ specialField : SampleLists(OneSpecialField) ]

EncodeSpecialFieldMessage(message) ==
    EncodeUIntBE(Len(message.specialField), 1)
        \o EncodeSpecialFieldList(message.specialField)

DecodeSpecialFieldMessage(bytes) ==
    LET numberOfSpecialFields == ReadUIntBE(bytes, 1) IN IF ~numberOfSpecialFields.ok THEN Fail ELSE
    LET specialField == ReadSpecialFieldList(numberOfSpecialFields.rest, numberOfSpecialFields.value) IN IF ~specialField.ok THEN Fail ELSE
    Ok([ specialField |-> specialField.value ], specialField.rest)

ZeroSpecialFieldMessage ==
    [ specialField |-> << >> ]

(* Special Field Message at zero, then each field in turn at the values it is checked at *)
CheckedSpecialFieldMessage ==
    { ZeroSpecialFieldMessage }
        \cup { [ZeroSpecialFieldMessage EXCEPT !.specialField = one] : one \in SampleLists(OneSpecialField) }

(***************************************************************************)
(* Market Snapshot Order Message: 41 bytes                                 *)
(***************************************************************************)

MarketSnapshotOrderMessage ==
    [ marketId             : Sample(4),
      orderId              : Sample(8),
      orderSequenceId      : Sample(2),
      side                 : Sample(1),
      price                : Sample(8),
      quantity             : Sample(4),
      isImplied            : Sample(1),
      isRfq                : Sample(1),
      orderEntryDateTime   : Sample(8),
      sequenceWithinMillis : Sample(4) ]

EncodeMarketSnapshotOrderMessage(message) ==
    message.marketId
        \o message.orderId
        \o message.orderSequenceId
        \o message.side
        \o message.price
        \o message.quantity
        \o message.isImplied
        \o message.isRfq
        \o message.orderEntryDateTime
        \o message.sequenceWithinMillis

DecodeMarketSnapshotOrderMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET orderId == ReadBytes(marketId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSequenceId == ReadBytes(orderId.rest, 2) IN IF ~orderSequenceId.ok THEN Fail ELSE
    LET side == ReadBytes(orderSequenceId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET isImplied == ReadBytes(quantity.rest, 1) IN IF ~isImplied.ok THEN Fail ELSE
    LET isRfq == ReadBytes(isImplied.rest, 1) IN IF ~isRfq.ok THEN Fail ELSE
    LET orderEntryDateTime == ReadBytes(isRfq.rest, 8) IN IF ~orderEntryDateTime.ok THEN Fail ELSE
    LET sequenceWithinMillis == ReadBytes(orderEntryDateTime.rest, 4) IN IF ~sequenceWithinMillis.ok THEN Fail ELSE
    Ok([ marketId             |-> marketId.value,
         orderId              |-> orderId.value,
         orderSequenceId      |-> orderSequenceId.value,
         side                 |-> side.value,
         price                |-> price.value,
         quantity             |-> quantity.value,
         isImplied            |-> isImplied.value,
         isRfq                |-> isRfq.value,
         orderEntryDateTime   |-> orderEntryDateTime.value,
         sequenceWithinMillis |-> sequenceWithinMillis.value ], sequenceWithinMillis.rest)

ZeroMarketSnapshotOrderMessage ==
    [ marketId             |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      orderSequenceId      |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      isImplied            |-> [i \in 1 .. 1 |-> 0],
      isRfq                |-> [i \in 1 .. 1 |-> 0],
      orderEntryDateTime   |-> [i \in 1 .. 8 |-> 0],
      sequenceWithinMillis |-> [i \in 1 .. 4 |-> 0] ]

(* Market Snapshot Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSnapshotOrderMessage ==
    { ZeroMarketSnapshotOrderMessage }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.orderSequenceId = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.isImplied = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.isRfq = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.orderEntryDateTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotOrderMessage EXCEPT !.sequenceWithinMillis = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Or Modify Order Message: 42 bytes                                   *)
(***************************************************************************)

AddOrModifyOrderMessage ==
    [ marketId             : Sample(4),
      orderId              : Sample(8),
      orderSequenceId      : Sample(2),
      side                 : Sample(1),
      price                : Sample(8),
      quantity             : Sample(4),
      isImplied            : Sample(1),
      isRfq                : Sample(1),
      orderEntryDateTime   : Sample(8),
      extraFlags           : Sample(1),
      sequenceWithinMillis : Sample(4) ]

EncodeAddOrModifyOrderMessage(message) ==
    message.marketId
        \o message.orderId
        \o message.orderSequenceId
        \o message.side
        \o message.price
        \o message.quantity
        \o message.isImplied
        \o message.isRfq
        \o message.orderEntryDateTime
        \o message.extraFlags
        \o message.sequenceWithinMillis

DecodeAddOrModifyOrderMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET orderId == ReadBytes(marketId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSequenceId == ReadBytes(orderId.rest, 2) IN IF ~orderSequenceId.ok THEN Fail ELSE
    LET side == ReadBytes(orderSequenceId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET isImplied == ReadBytes(quantity.rest, 1) IN IF ~isImplied.ok THEN Fail ELSE
    LET isRfq == ReadBytes(isImplied.rest, 1) IN IF ~isRfq.ok THEN Fail ELSE
    LET orderEntryDateTime == ReadBytes(isRfq.rest, 8) IN IF ~orderEntryDateTime.ok THEN Fail ELSE
    LET extraFlags == ReadBytes(orderEntryDateTime.rest, 1) IN IF ~extraFlags.ok THEN Fail ELSE
    LET sequenceWithinMillis == ReadBytes(extraFlags.rest, 4) IN IF ~sequenceWithinMillis.ok THEN Fail ELSE
    Ok([ marketId             |-> marketId.value,
         orderId              |-> orderId.value,
         orderSequenceId      |-> orderSequenceId.value,
         side                 |-> side.value,
         price                |-> price.value,
         quantity             |-> quantity.value,
         isImplied            |-> isImplied.value,
         isRfq                |-> isRfq.value,
         orderEntryDateTime   |-> orderEntryDateTime.value,
         extraFlags           |-> extraFlags.value,
         sequenceWithinMillis |-> sequenceWithinMillis.value ], sequenceWithinMillis.rest)

ZeroAddOrModifyOrderMessage ==
    [ marketId             |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      orderSequenceId      |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      isImplied            |-> [i \in 1 .. 1 |-> 0],
      isRfq                |-> [i \in 1 .. 1 |-> 0],
      orderEntryDateTime   |-> [i \in 1 .. 8 |-> 0],
      extraFlags           |-> [i \in 1 .. 1 |-> 0],
      sequenceWithinMillis |-> [i \in 1 .. 4 |-> 0] ]

(* Add Or Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrModifyOrderMessage ==
    { ZeroAddOrModifyOrderMessage }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.orderSequenceId = one] : one \in Sample(2) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.isImplied = one] : one \in Sample(1) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.isRfq = one] : one \in Sample(1) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.orderEntryDateTime = one] : one \in Sample(8) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.extraFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrModifyOrderMessage EXCEPT !.sequenceWithinMillis = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Message: 12 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ marketId : Sample(4),
      orderId  : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.marketId
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET orderId == ReadBytes(marketId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ marketId |-> marketId.value,
         orderId  |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ marketId |-> [i \in 1 .. 4 |-> 0],
      orderId  |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Bundle Marker: 1 bytes                                          *)
(***************************************************************************)

MessageBundleMarker ==
    [ startOrEnd : Sample(1) ]

EncodeMessageBundleMarker(message) ==
    message.startOrEnd

DecodeMessageBundleMarker(bytes) ==
    LET startOrEnd == ReadBytes(bytes, 1) IN IF ~startOrEnd.ok THEN Fail ELSE
    Ok([ startOrEnd |-> startOrEnd.value ], startOrEnd.rest)

ZeroMessageBundleMarker ==
    [ startOrEnd |-> [i \in 1 .. 1 |-> 0] ]

(* Message Bundle Marker at zero, then each field in turn at the values it is checked at *)
CheckedMessageBundleMarker ==
    { ZeroMessageBundleMarker }
        \cup { [ZeroMessageBundleMarker EXCEPT !.startOrEnd = one] : one \in Sample(1) }

(***************************************************************************)
(* Fixing Transition Message: 25 bytes                                     *)
(***************************************************************************)

FixingTransitionMessage ==
    [ marketId              : Sample(4),
      status                : Sample(1),
      auctionEndTime        : Sample(8),
      thresholdImbalanceQty : Sample(4),
      messageDateTime       : Sample(8) ]

EncodeFixingTransitionMessage(message) ==
    message.marketId
        \o message.status
        \o message.auctionEndTime
        \o message.thresholdImbalanceQty
        \o message.messageDateTime

DecodeFixingTransitionMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET status == ReadBytes(marketId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET auctionEndTime == ReadBytes(status.rest, 8) IN IF ~auctionEndTime.ok THEN Fail ELSE
    LET thresholdImbalanceQty == ReadBytes(auctionEndTime.rest, 4) IN IF ~thresholdImbalanceQty.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(thresholdImbalanceQty.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    Ok([ marketId              |-> marketId.value,
         status                |-> status.value,
         auctionEndTime        |-> auctionEndTime.value,
         thresholdImbalanceQty |-> thresholdImbalanceQty.value,
         messageDateTime       |-> messageDateTime.value ], messageDateTime.rest)

ZeroFixingTransitionMessage ==
    [ marketId              |-> [i \in 1 .. 4 |-> 0],
      status                |-> [i \in 1 .. 1 |-> 0],
      auctionEndTime        |-> [i \in 1 .. 8 |-> 0],
      thresholdImbalanceQty |-> [i \in 1 .. 4 |-> 0],
      messageDateTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Fixing Transition Message at zero, then each field in turn at the values it is checked at *)
CheckedFixingTransitionMessage ==
    { ZeroFixingTransitionMessage }
        \cup { [ZeroFixingTransitionMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroFixingTransitionMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroFixingTransitionMessage EXCEPT !.auctionEndTime = one] : one \in Sample(8) }
        \cup { [ZeroFixingTransitionMessage EXCEPT !.thresholdImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroFixingTransitionMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Fixing Lockdown Message: 78 bytes                                       *)
(***************************************************************************)

FixingLockdownMessage ==
    [ marketId        : Sample(4),
      auctionDate     : Sample(10),
      messageDateTime : Sample(8),
      description     : Sample(20),
      round           : Sample(2),
      aggBidQty       : Sample(4),
      aggOfferQty     : Sample(4),
      usdPrice        : Sample(8),
      isBalanced      : Sample(1),
      isFinal         : Sample(1),
      gbpPrice        : Sample(8),
      eurPrice        : Sample(8) ]

EncodeFixingLockdownMessage(message) ==
    message.marketId
        \o message.auctionDate
        \o message.messageDateTime
        \o message.description
        \o message.round
        \o message.aggBidQty
        \o message.aggOfferQty
        \o message.usdPrice
        \o message.isBalanced
        \o message.isFinal
        \o message.gbpPrice
        \o message.eurPrice

DecodeFixingLockdownMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET auctionDate == ReadBytes(marketId.rest, 10) IN IF ~auctionDate.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(auctionDate.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET description == ReadBytes(messageDateTime.rest, 20) IN IF ~description.ok THEN Fail ELSE
    LET round == ReadBytes(description.rest, 2) IN IF ~round.ok THEN Fail ELSE
    LET aggBidQty == ReadBytes(round.rest, 4) IN IF ~aggBidQty.ok THEN Fail ELSE
    LET aggOfferQty == ReadBytes(aggBidQty.rest, 4) IN IF ~aggOfferQty.ok THEN Fail ELSE
    LET usdPrice == ReadBytes(aggOfferQty.rest, 8) IN IF ~usdPrice.ok THEN Fail ELSE
    LET isBalanced == ReadBytes(usdPrice.rest, 1) IN IF ~isBalanced.ok THEN Fail ELSE
    LET isFinal == ReadBytes(isBalanced.rest, 1) IN IF ~isFinal.ok THEN Fail ELSE
    LET gbpPrice == ReadBytes(isFinal.rest, 8) IN IF ~gbpPrice.ok THEN Fail ELSE
    LET eurPrice == ReadBytes(gbpPrice.rest, 8) IN IF ~eurPrice.ok THEN Fail ELSE
    Ok([ marketId        |-> marketId.value,
         auctionDate     |-> auctionDate.value,
         messageDateTime |-> messageDateTime.value,
         description     |-> description.value,
         round           |-> round.value,
         aggBidQty       |-> aggBidQty.value,
         aggOfferQty     |-> aggOfferQty.value,
         usdPrice        |-> usdPrice.value,
         isBalanced      |-> isBalanced.value,
         isFinal         |-> isFinal.value,
         gbpPrice        |-> gbpPrice.value,
         eurPrice        |-> eurPrice.value ], eurPrice.rest)

ZeroFixingLockdownMessage ==
    [ marketId        |-> [i \in 1 .. 4 |-> 0],
      auctionDate     |-> [i \in 1 .. 10 |-> 0],
      messageDateTime |-> [i \in 1 .. 8 |-> 0],
      description     |-> [i \in 1 .. 20 |-> 0],
      round           |-> [i \in 1 .. 2 |-> 0],
      aggBidQty       |-> [i \in 1 .. 4 |-> 0],
      aggOfferQty     |-> [i \in 1 .. 4 |-> 0],
      usdPrice        |-> [i \in 1 .. 8 |-> 0],
      isBalanced      |-> [i \in 1 .. 1 |-> 0],
      isFinal         |-> [i \in 1 .. 1 |-> 0],
      gbpPrice        |-> [i \in 1 .. 8 |-> 0],
      eurPrice        |-> [i \in 1 .. 8 |-> 0] ]

(* Fixing Lockdown Message at zero, then each field in turn at the values it is checked at *)
CheckedFixingLockdownMessage ==
    { ZeroFixingLockdownMessage }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.auctionDate = one] : one \in Sample(10) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.description = one] : one \in Sample(20) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.round = one] : one \in Sample(2) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.aggBidQty = one] : one \in Sample(4) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.aggOfferQty = one] : one \in Sample(4) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.usdPrice = one] : one \in Sample(8) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.isBalanced = one] : one \in Sample(1) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.isFinal = one] : one \in Sample(1) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.gbpPrice = one] : one \in Sample(8) }
        \cup { [ZeroFixingLockdownMessage EXCEPT !.eurPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Snapshot Price Level Message: 26 bytes                           *)
(***************************************************************************)

MarketSnapshotPriceLevelMessage ==
    [ marketId           : Sample(4),
      side               : Sample(1),
      priceLevelPosition : Sample(1),
      price              : Sample(8),
      quantity           : Sample(4),
      orderCount         : Sample(2),
      impliedQuantity    : Sample(4),
      impliedOrderCount  : Sample(2) ]

EncodeMarketSnapshotPriceLevelMessage(message) ==
    message.marketId
        \o message.side
        \o message.priceLevelPosition
        \o message.price
        \o message.quantity
        \o message.orderCount
        \o message.impliedQuantity
        \o message.impliedOrderCount

DecodeMarketSnapshotPriceLevelMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET side == ReadBytes(marketId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLevelPosition == ReadBytes(side.rest, 1) IN IF ~priceLevelPosition.ok THEN Fail ELSE
    LET price == ReadBytes(priceLevelPosition.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderCount == ReadBytes(quantity.rest, 2) IN IF ~orderCount.ok THEN Fail ELSE
    LET impliedQuantity == ReadBytes(orderCount.rest, 4) IN IF ~impliedQuantity.ok THEN Fail ELSE
    LET impliedOrderCount == ReadBytes(impliedQuantity.rest, 2) IN IF ~impliedOrderCount.ok THEN Fail ELSE
    Ok([ marketId           |-> marketId.value,
         side               |-> side.value,
         priceLevelPosition |-> priceLevelPosition.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         orderCount         |-> orderCount.value,
         impliedQuantity    |-> impliedQuantity.value,
         impliedOrderCount  |-> impliedOrderCount.value ], impliedOrderCount.rest)

ZeroMarketSnapshotPriceLevelMessage ==
    [ marketId           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      priceLevelPosition |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      orderCount         |-> [i \in 1 .. 2 |-> 0],
      impliedQuantity    |-> [i \in 1 .. 4 |-> 0],
      impliedOrderCount  |-> [i \in 1 .. 2 |-> 0] ]

(* Market Snapshot Price Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSnapshotPriceLevelMessage ==
    { ZeroMarketSnapshotPriceLevelMessage }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.priceLevelPosition = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.orderCount = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.impliedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotPriceLevelMessage EXCEPT !.impliedOrderCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Price Level Message: 26 bytes                                       *)
(***************************************************************************)

AddPriceLevelMessage ==
    [ marketId           : Sample(4),
      side               : Sample(1),
      priceLevelPosition : Sample(1),
      price              : Sample(8),
      quantity           : Sample(4),
      orderCount         : Sample(2),
      impliedQuantity    : Sample(4),
      impliedOrderCount  : Sample(2) ]

EncodeAddPriceLevelMessage(message) ==
    message.marketId
        \o message.side
        \o message.priceLevelPosition
        \o message.price
        \o message.quantity
        \o message.orderCount
        \o message.impliedQuantity
        \o message.impliedOrderCount

DecodeAddPriceLevelMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET side == ReadBytes(marketId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLevelPosition == ReadBytes(side.rest, 1) IN IF ~priceLevelPosition.ok THEN Fail ELSE
    LET price == ReadBytes(priceLevelPosition.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderCount == ReadBytes(quantity.rest, 2) IN IF ~orderCount.ok THEN Fail ELSE
    LET impliedQuantity == ReadBytes(orderCount.rest, 4) IN IF ~impliedQuantity.ok THEN Fail ELSE
    LET impliedOrderCount == ReadBytes(impliedQuantity.rest, 2) IN IF ~impliedOrderCount.ok THEN Fail ELSE
    Ok([ marketId           |-> marketId.value,
         side               |-> side.value,
         priceLevelPosition |-> priceLevelPosition.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         orderCount         |-> orderCount.value,
         impliedQuantity    |-> impliedQuantity.value,
         impliedOrderCount  |-> impliedOrderCount.value ], impliedOrderCount.rest)

ZeroAddPriceLevelMessage ==
    [ marketId           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      priceLevelPosition |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      orderCount         |-> [i \in 1 .. 2 |-> 0],
      impliedQuantity    |-> [i \in 1 .. 4 |-> 0],
      impliedOrderCount  |-> [i \in 1 .. 2 |-> 0] ]

(* Add Price Level Message at zero, then each field in turn at the values it is checked at *)
CheckedAddPriceLevelMessage ==
    { ZeroAddPriceLevelMessage }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.priceLevelPosition = one] : one \in Sample(1) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.orderCount = one] : one \in Sample(2) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.impliedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAddPriceLevelMessage EXCEPT !.impliedOrderCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Change Price Level Message: 26 bytes                                    *)
(***************************************************************************)

ChangePriceLevelMessage ==
    [ marketId           : Sample(4),
      side               : Sample(1),
      priceLevelPosition : Sample(1),
      price              : Sample(8),
      quantity           : Sample(4),
      orderCount         : Sample(2),
      impliedQuantity    : Sample(4),
      impliedOrderCount  : Sample(2) ]

EncodeChangePriceLevelMessage(message) ==
    message.marketId
        \o message.side
        \o message.priceLevelPosition
        \o message.price
        \o message.quantity
        \o message.orderCount
        \o message.impliedQuantity
        \o message.impliedOrderCount

DecodeChangePriceLevelMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET side == ReadBytes(marketId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLevelPosition == ReadBytes(side.rest, 1) IN IF ~priceLevelPosition.ok THEN Fail ELSE
    LET price == ReadBytes(priceLevelPosition.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderCount == ReadBytes(quantity.rest, 2) IN IF ~orderCount.ok THEN Fail ELSE
    LET impliedQuantity == ReadBytes(orderCount.rest, 4) IN IF ~impliedQuantity.ok THEN Fail ELSE
    LET impliedOrderCount == ReadBytes(impliedQuantity.rest, 2) IN IF ~impliedOrderCount.ok THEN Fail ELSE
    Ok([ marketId           |-> marketId.value,
         side               |-> side.value,
         priceLevelPosition |-> priceLevelPosition.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         orderCount         |-> orderCount.value,
         impliedQuantity    |-> impliedQuantity.value,
         impliedOrderCount  |-> impliedOrderCount.value ], impliedOrderCount.rest)

ZeroChangePriceLevelMessage ==
    [ marketId           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      priceLevelPosition |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      orderCount         |-> [i \in 1 .. 2 |-> 0],
      impliedQuantity    |-> [i \in 1 .. 4 |-> 0],
      impliedOrderCount  |-> [i \in 1 .. 2 |-> 0] ]

(* Change Price Level Message at zero, then each field in turn at the values it is checked at *)
CheckedChangePriceLevelMessage ==
    { ZeroChangePriceLevelMessage }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.priceLevelPosition = one] : one \in Sample(1) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.orderCount = one] : one \in Sample(2) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.impliedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroChangePriceLevelMessage EXCEPT !.impliedOrderCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Delete Price Level Message: 6 bytes                                     *)
(***************************************************************************)

DeletePriceLevelMessage ==
    [ marketId           : Sample(4),
      side               : Sample(1),
      priceLevelPosition : Sample(1) ]

EncodeDeletePriceLevelMessage(message) ==
    message.marketId
        \o message.side
        \o message.priceLevelPosition

DecodeDeletePriceLevelMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET side == ReadBytes(marketId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLevelPosition == ReadBytes(side.rest, 1) IN IF ~priceLevelPosition.ok THEN Fail ELSE
    Ok([ marketId           |-> marketId.value,
         side               |-> side.value,
         priceLevelPosition |-> priceLevelPosition.value ], priceLevelPosition.rest)

ZeroDeletePriceLevelMessage ==
    [ marketId           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      priceLevelPosition |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Price Level Message at zero, then each field in turn at the values it is checked at *)
CheckedDeletePriceLevelMessage ==
    { ZeroDeletePriceLevelMessage }
        \cup { [ZeroDeletePriceLevelMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroDeletePriceLevelMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeletePriceLevelMessage EXCEPT !.priceLevelPosition = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Leg Definition: 12 bytes                                       *)
(***************************************************************************)

StrategyLegDefinition ==
    [ legBodyLength         : Sample(1),
      legMarketId           : Sample(4),
      legUnderlyingMarketId : Sample(4),
      legRatio              : Sample(2),
      legSide               : Sample(1) ]

EncodeStrategyLegDefinition(message) ==
    message.legBodyLength
        \o message.legMarketId
        \o message.legUnderlyingMarketId
        \o message.legRatio
        \o message.legSide

DecodeStrategyLegDefinition(bytes) ==
    LET legBodyLength == ReadBytes(bytes, 1) IN IF ~legBodyLength.ok THEN Fail ELSE
    LET legMarketId == ReadBytes(legBodyLength.rest, 4) IN IF ~legMarketId.ok THEN Fail ELSE
    LET legUnderlyingMarketId == ReadBytes(legMarketId.rest, 4) IN IF ~legUnderlyingMarketId.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legUnderlyingMarketId.rest, 2) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatio.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legBodyLength         |-> legBodyLength.value,
         legMarketId           |-> legMarketId.value,
         legUnderlyingMarketId |-> legUnderlyingMarketId.value,
         legRatio              |-> legRatio.value,
         legSide               |-> legSide.value ], legSide.rest)

ZeroStrategyLegDefinition ==
    [ legBodyLength         |-> [i \in 1 .. 1 |-> 0],
      legMarketId           |-> [i \in 1 .. 4 |-> 0],
      legUnderlyingMarketId |-> [i \in 1 .. 4 |-> 0],
      legRatio              |-> [i \in 1 .. 2 |-> 0],
      legSide               |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Leg Definition at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLegDefinition ==
    { ZeroStrategyLegDefinition }
        \cup { [ZeroStrategyLegDefinition EXCEPT !.legBodyLength = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLegDefinition EXCEPT !.legMarketId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLegDefinition EXCEPT !.legUnderlyingMarketId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLegDefinition EXCEPT !.legRatio = one] : one \in Sample(2) }
        \cup { [ZeroStrategyLegDefinition EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Strategy Leg Definition, written one after another *)
RECURSIVE EncodeStrategyLegDefinitionList(_)
EncodeStrategyLegDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyLegDefinition(Head(messages)) \o EncodeStrategyLegDefinitionList(Tail(messages))

(* As many Strategy Leg Definition as the field that counts them says *)
RECURSIVE ReadStrategyLegDefinitionList(_, _)
ReadStrategyLegDefinitionList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyLegDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyLegDefinitionList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Leg Definition of each kind, for the lists that carry them *)
OneStrategyLegDefinition == { ZeroStrategyLegDefinition }

(***************************************************************************)
(* Hedge Definition: 18 bytes                                              *)
(***************************************************************************)

HedgeDefinition ==
    [ hedgeBodyLength       : Sample(1),
      hedgeMarketId         : Sample(4),
      hedgeSecurityType     : Sample(1),
      hedgeSide             : Sample(1),
      hedgePrice            : Sample(8),
      hedgePriceDenominator : Sample(1),
      hedgeDelta            : Sample(2) ]

EncodeHedgeDefinition(message) ==
    message.hedgeBodyLength
        \o message.hedgeMarketId
        \o message.hedgeSecurityType
        \o message.hedgeSide
        \o message.hedgePrice
        \o message.hedgePriceDenominator
        \o message.hedgeDelta

DecodeHedgeDefinition(bytes) ==
    LET hedgeBodyLength == ReadBytes(bytes, 1) IN IF ~hedgeBodyLength.ok THEN Fail ELSE
    LET hedgeMarketId == ReadBytes(hedgeBodyLength.rest, 4) IN IF ~hedgeMarketId.ok THEN Fail ELSE
    LET hedgeSecurityType == ReadBytes(hedgeMarketId.rest, 1) IN IF ~hedgeSecurityType.ok THEN Fail ELSE
    LET hedgeSide == ReadBytes(hedgeSecurityType.rest, 1) IN IF ~hedgeSide.ok THEN Fail ELSE
    LET hedgePrice == ReadBytes(hedgeSide.rest, 8) IN IF ~hedgePrice.ok THEN Fail ELSE
    LET hedgePriceDenominator == ReadBytes(hedgePrice.rest, 1) IN IF ~hedgePriceDenominator.ok THEN Fail ELSE
    LET hedgeDelta == ReadBytes(hedgePriceDenominator.rest, 2) IN IF ~hedgeDelta.ok THEN Fail ELSE
    Ok([ hedgeBodyLength       |-> hedgeBodyLength.value,
         hedgeMarketId         |-> hedgeMarketId.value,
         hedgeSecurityType     |-> hedgeSecurityType.value,
         hedgeSide             |-> hedgeSide.value,
         hedgePrice            |-> hedgePrice.value,
         hedgePriceDenominator |-> hedgePriceDenominator.value,
         hedgeDelta            |-> hedgeDelta.value ], hedgeDelta.rest)

ZeroHedgeDefinition ==
    [ hedgeBodyLength       |-> [i \in 1 .. 1 |-> 0],
      hedgeMarketId         |-> [i \in 1 .. 4 |-> 0],
      hedgeSecurityType     |-> [i \in 1 .. 1 |-> 0],
      hedgeSide             |-> [i \in 1 .. 1 |-> 0],
      hedgePrice            |-> [i \in 1 .. 8 |-> 0],
      hedgePriceDenominator |-> [i \in 1 .. 1 |-> 0],
      hedgeDelta            |-> [i \in 1 .. 2 |-> 0] ]

(* Hedge Definition at zero, then each field in turn at the values it is checked at *)
CheckedHedgeDefinition ==
    { ZeroHedgeDefinition }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgeBodyLength = one] : one \in Sample(1) }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgeMarketId = one] : one \in Sample(4) }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgeSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgeSide = one] : one \in Sample(1) }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgePrice = one] : one \in Sample(8) }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroHedgeDefinition EXCEPT !.hedgeDelta = one] : one \in Sample(2) }

(* A run of Hedge Definition, written one after another *)
RECURSIVE EncodeHedgeDefinitionList(_)
EncodeHedgeDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeHedgeDefinition(Head(messages)) \o EncodeHedgeDefinitionList(Tail(messages))

(* As many Hedge Definition as the field that counts them says *)
RECURSIVE ReadHedgeDefinitionList(_, _)
ReadHedgeDefinitionList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeHedgeDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadHedgeDefinitionList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Hedge Definition of each kind, for the lists that carry them *)
OneHedgeDefinition == { ZeroHedgeDefinition }

(***************************************************************************)
(* New Options Strategy Definition Message                                 *)
(***************************************************************************)

NewOptionsStrategyDefinitionMessage ==
    [ marketId              : Sample(4),
      underlyingMarketId    : Sample(4),
      contractSymbol        : Sample(35),
      tradingStatus         : Sample(1),
      orderPriceDenominator : Sample(1),
      incrementPrice        : Sample(4),
      incrementQty          : Sample(4),
      minQty                : Sample(4),
      strategyLegDefinition : SampleLists(OneStrategyLegDefinition),
      hedgeDefinition       : SampleLists(OneHedgeDefinition),
      securitySubType       : Sample(2),
      isBlockOnly           : Sample(1),
      strategySymbol        : Sample(18),
      gtAllowed             : Sample(1) ]

EncodeNewOptionsStrategyDefinitionMessage(message) ==
    message.marketId
        \o message.underlyingMarketId
        \o message.contractSymbol
        \o message.tradingStatus
        \o message.orderPriceDenominator
        \o message.incrementPrice
        \o message.incrementQty
        \o message.minQty
        \o EncodeUIntBE(Len(message.strategyLegDefinition), 1)
        \o EncodeStrategyLegDefinitionList(message.strategyLegDefinition)
        \o EncodeUIntBE(Len(message.hedgeDefinition), 1)
        \o EncodeHedgeDefinitionList(message.hedgeDefinition)
        \o message.securitySubType
        \o message.isBlockOnly
        \o message.strategySymbol
        \o message.gtAllowed

DecodeNewOptionsStrategyDefinitionMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET underlyingMarketId == ReadBytes(marketId.rest, 4) IN IF ~underlyingMarketId.ok THEN Fail ELSE
    LET contractSymbol == ReadBytes(underlyingMarketId.rest, 35) IN IF ~contractSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(contractSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET orderPriceDenominator == ReadBytes(tradingStatus.rest, 1) IN IF ~orderPriceDenominator.ok THEN Fail ELSE
    LET incrementPrice == ReadBytes(orderPriceDenominator.rest, 4) IN IF ~incrementPrice.ok THEN Fail ELSE
    LET incrementQty == ReadBytes(incrementPrice.rest, 4) IN IF ~incrementQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(incrementQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET numberOfStrategyLegDefinitions == ReadUIntBE(minQty.rest, 1) IN IF ~numberOfStrategyLegDefinitions.ok THEN Fail ELSE
    LET strategyLegDefinition == ReadStrategyLegDefinitionList(numberOfStrategyLegDefinitions.rest, numberOfStrategyLegDefinitions.value) IN IF ~strategyLegDefinition.ok THEN Fail ELSE
    LET numberOfHedgeDefinitions == ReadUIntBE(strategyLegDefinition.rest, 1) IN IF ~numberOfHedgeDefinitions.ok THEN Fail ELSE
    LET hedgeDefinition == ReadHedgeDefinitionList(numberOfHedgeDefinitions.rest, numberOfHedgeDefinitions.value) IN IF ~hedgeDefinition.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(hedgeDefinition.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET isBlockOnly == ReadBytes(securitySubType.rest, 1) IN IF ~isBlockOnly.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(isBlockOnly.rest, 18) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET gtAllowed == ReadBytes(strategySymbol.rest, 1) IN IF ~gtAllowed.ok THEN Fail ELSE
    Ok([ marketId              |-> marketId.value,
         underlyingMarketId    |-> underlyingMarketId.value,
         contractSymbol        |-> contractSymbol.value,
         tradingStatus         |-> tradingStatus.value,
         orderPriceDenominator |-> orderPriceDenominator.value,
         incrementPrice        |-> incrementPrice.value,
         incrementQty          |-> incrementQty.value,
         minQty                |-> minQty.value,
         strategyLegDefinition |-> strategyLegDefinition.value,
         hedgeDefinition       |-> hedgeDefinition.value,
         securitySubType       |-> securitySubType.value,
         isBlockOnly           |-> isBlockOnly.value,
         strategySymbol        |-> strategySymbol.value,
         gtAllowed             |-> gtAllowed.value ], gtAllowed.rest)

ZeroNewOptionsStrategyDefinitionMessage ==
    [ marketId              |-> [i \in 1 .. 4 |-> 0],
      underlyingMarketId    |-> [i \in 1 .. 4 |-> 0],
      contractSymbol        |-> [i \in 1 .. 35 |-> 0],
      tradingStatus         |-> [i \in 1 .. 1 |-> 0],
      orderPriceDenominator |-> [i \in 1 .. 1 |-> 0],
      incrementPrice        |-> [i \in 1 .. 4 |-> 0],
      incrementQty          |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      strategyLegDefinition |-> << >>,
      hedgeDefinition       |-> << >>,
      securitySubType       |-> [i \in 1 .. 2 |-> 0],
      isBlockOnly           |-> [i \in 1 .. 1 |-> 0],
      strategySymbol        |-> [i \in 1 .. 18 |-> 0],
      gtAllowed             |-> [i \in 1 .. 1 |-> 0] ]

(* New Options Strategy Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOptionsStrategyDefinitionMessage ==
    { ZeroNewOptionsStrategyDefinitionMessage }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.underlyingMarketId = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.contractSymbol = one] : one \in Sample(35) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.orderPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.incrementPrice = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.incrementQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.strategyLegDefinition = one] : one \in SampleLists(OneStrategyLegDefinition) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.hedgeDefinition = one] : one \in SampleLists(OneHedgeDefinition) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.isBlockOnly = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.strategySymbol = one] : one \in Sample(18) }
        \cup { [ZeroNewOptionsStrategyDefinitionMessage EXCEPT !.gtAllowed = one] : one \in Sample(1) }

(***************************************************************************)
(* New Options Market Definition Message: 321 bytes                        *)
(***************************************************************************)

NewOptionsMarketDefinitionMessage ==
    [ marketId                 : Sample(4),
      underlyingMarketId       : Sample(4),
      futuresContractSymbol    : Sample(70),
      tradingStatus            : Sample(1),
      orderPriceDenominator    : Sample(1),
      incrementQty             : Sample(4),
      lotSize                  : Sample(4),
      marketDesc               : Sample(120),
      optionType               : Sample(1),
      strikePrice              : Sample(8),
      dealPriceDenominator     : Sample(1),
      minQty                   : Sample(4),
      currency                 : Sample(20),
      numDecimalsStrikePrice   : Sample(1),
      minOptionsPrice          : Sample(8),
      maxOptionsPrice          : Sample(8),
      incrementPremiumPrice    : Sample(4),
      optionsExpirationYear    : Sample(2),
      optionsExpirationMonth   : Sample(2),
      optionsExpirationDay     : Sample(2),
      optionsStyle             : Sample(1),
      optionsExpirationType    : Sample(1),
      hedgeMarketId            : Sample(4),
      settlePriceDenominator   : Sample(1),
      unitQtyDenominator       : Sample(1),
      tickValue                : Sample(8),
      flexAllowed              : Sample(1),
      settlementType           : Sample(1),
      isBlockOnly              : Sample(1),
      gtAllowed                : Sample(1),
      crossOrderSupported      : Sample(1),
      guaranteedCrossSupported : Sample(1),
      unitOfMeasure            : Sample(30) ]

EncodeNewOptionsMarketDefinitionMessage(message) ==
    message.marketId
        \o message.underlyingMarketId
        \o message.futuresContractSymbol
        \o message.tradingStatus
        \o message.orderPriceDenominator
        \o message.incrementQty
        \o message.lotSize
        \o message.marketDesc
        \o message.optionType
        \o message.strikePrice
        \o message.dealPriceDenominator
        \o message.minQty
        \o message.currency
        \o message.numDecimalsStrikePrice
        \o message.minOptionsPrice
        \o message.maxOptionsPrice
        \o message.incrementPremiumPrice
        \o message.optionsExpirationYear
        \o message.optionsExpirationMonth
        \o message.optionsExpirationDay
        \o message.optionsStyle
        \o message.optionsExpirationType
        \o message.hedgeMarketId
        \o message.settlePriceDenominator
        \o message.unitQtyDenominator
        \o message.tickValue
        \o message.flexAllowed
        \o message.settlementType
        \o message.isBlockOnly
        \o message.gtAllowed
        \o message.crossOrderSupported
        \o message.guaranteedCrossSupported
        \o message.unitOfMeasure

DecodeNewOptionsMarketDefinitionMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET underlyingMarketId == ReadBytes(marketId.rest, 4) IN IF ~underlyingMarketId.ok THEN Fail ELSE
    LET futuresContractSymbol == ReadBytes(underlyingMarketId.rest, 70) IN IF ~futuresContractSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(futuresContractSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET orderPriceDenominator == ReadBytes(tradingStatus.rest, 1) IN IF ~orderPriceDenominator.ok THEN Fail ELSE
    LET incrementQty == ReadBytes(orderPriceDenominator.rest, 4) IN IF ~incrementQty.ok THEN Fail ELSE
    LET lotSize == ReadBytes(incrementQty.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET marketDesc == ReadBytes(lotSize.rest, 120) IN IF ~marketDesc.ok THEN Fail ELSE
    LET optionType == ReadBytes(marketDesc.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET dealPriceDenominator == ReadBytes(strikePrice.rest, 1) IN IF ~dealPriceDenominator.ok THEN Fail ELSE
    LET minQty == ReadBytes(dealPriceDenominator.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET currency == ReadBytes(minQty.rest, 20) IN IF ~currency.ok THEN Fail ELSE
    LET numDecimalsStrikePrice == ReadBytes(currency.rest, 1) IN IF ~numDecimalsStrikePrice.ok THEN Fail ELSE
    LET minOptionsPrice == ReadBytes(numDecimalsStrikePrice.rest, 8) IN IF ~minOptionsPrice.ok THEN Fail ELSE
    LET maxOptionsPrice == ReadBytes(minOptionsPrice.rest, 8) IN IF ~maxOptionsPrice.ok THEN Fail ELSE
    LET incrementPremiumPrice == ReadBytes(maxOptionsPrice.rest, 4) IN IF ~incrementPremiumPrice.ok THEN Fail ELSE
    LET optionsExpirationYear == ReadBytes(incrementPremiumPrice.rest, 2) IN IF ~optionsExpirationYear.ok THEN Fail ELSE
    LET optionsExpirationMonth == ReadBytes(optionsExpirationYear.rest, 2) IN IF ~optionsExpirationMonth.ok THEN Fail ELSE
    LET optionsExpirationDay == ReadBytes(optionsExpirationMonth.rest, 2) IN IF ~optionsExpirationDay.ok THEN Fail ELSE
    LET optionsStyle == ReadBytes(optionsExpirationDay.rest, 1) IN IF ~optionsStyle.ok THEN Fail ELSE
    LET optionsExpirationType == ReadBytes(optionsStyle.rest, 1) IN IF ~optionsExpirationType.ok THEN Fail ELSE
    LET hedgeMarketId == ReadBytes(optionsExpirationType.rest, 4) IN IF ~hedgeMarketId.ok THEN Fail ELSE
    LET settlePriceDenominator == ReadBytes(hedgeMarketId.rest, 1) IN IF ~settlePriceDenominator.ok THEN Fail ELSE
    LET unitQtyDenominator == ReadBytes(settlePriceDenominator.rest, 1) IN IF ~unitQtyDenominator.ok THEN Fail ELSE
    LET tickValue == ReadBytes(unitQtyDenominator.rest, 8) IN IF ~tickValue.ok THEN Fail ELSE
    LET flexAllowed == ReadBytes(tickValue.rest, 1) IN IF ~flexAllowed.ok THEN Fail ELSE
    LET settlementType == ReadBytes(flexAllowed.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET isBlockOnly == ReadBytes(settlementType.rest, 1) IN IF ~isBlockOnly.ok THEN Fail ELSE
    LET gtAllowed == ReadBytes(isBlockOnly.rest, 1) IN IF ~gtAllowed.ok THEN Fail ELSE
    LET crossOrderSupported == ReadBytes(gtAllowed.rest, 1) IN IF ~crossOrderSupported.ok THEN Fail ELSE
    LET guaranteedCrossSupported == ReadBytes(crossOrderSupported.rest, 1) IN IF ~guaranteedCrossSupported.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(guaranteedCrossSupported.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    Ok([ marketId                 |-> marketId.value,
         underlyingMarketId       |-> underlyingMarketId.value,
         futuresContractSymbol    |-> futuresContractSymbol.value,
         tradingStatus            |-> tradingStatus.value,
         orderPriceDenominator    |-> orderPriceDenominator.value,
         incrementQty             |-> incrementQty.value,
         lotSize                  |-> lotSize.value,
         marketDesc               |-> marketDesc.value,
         optionType               |-> optionType.value,
         strikePrice              |-> strikePrice.value,
         dealPriceDenominator     |-> dealPriceDenominator.value,
         minQty                   |-> minQty.value,
         currency                 |-> currency.value,
         numDecimalsStrikePrice   |-> numDecimalsStrikePrice.value,
         minOptionsPrice          |-> minOptionsPrice.value,
         maxOptionsPrice          |-> maxOptionsPrice.value,
         incrementPremiumPrice    |-> incrementPremiumPrice.value,
         optionsExpirationYear    |-> optionsExpirationYear.value,
         optionsExpirationMonth   |-> optionsExpirationMonth.value,
         optionsExpirationDay     |-> optionsExpirationDay.value,
         optionsStyle             |-> optionsStyle.value,
         optionsExpirationType    |-> optionsExpirationType.value,
         hedgeMarketId            |-> hedgeMarketId.value,
         settlePriceDenominator   |-> settlePriceDenominator.value,
         unitQtyDenominator       |-> unitQtyDenominator.value,
         tickValue                |-> tickValue.value,
         flexAllowed              |-> flexAllowed.value,
         settlementType           |-> settlementType.value,
         isBlockOnly              |-> isBlockOnly.value,
         gtAllowed                |-> gtAllowed.value,
         crossOrderSupported      |-> crossOrderSupported.value,
         guaranteedCrossSupported |-> guaranteedCrossSupported.value,
         unitOfMeasure            |-> unitOfMeasure.value ], unitOfMeasure.rest)

ZeroNewOptionsMarketDefinitionMessage ==
    [ marketId                 |-> [i \in 1 .. 4 |-> 0],
      underlyingMarketId       |-> [i \in 1 .. 4 |-> 0],
      futuresContractSymbol    |-> [i \in 1 .. 70 |-> 0],
      tradingStatus            |-> [i \in 1 .. 1 |-> 0],
      orderPriceDenominator    |-> [i \in 1 .. 1 |-> 0],
      incrementQty             |-> [i \in 1 .. 4 |-> 0],
      lotSize                  |-> [i \in 1 .. 4 |-> 0],
      marketDesc               |-> [i \in 1 .. 120 |-> 0],
      optionType               |-> [i \in 1 .. 1 |-> 0],
      strikePrice              |-> [i \in 1 .. 8 |-> 0],
      dealPriceDenominator     |-> [i \in 1 .. 1 |-> 0],
      minQty                   |-> [i \in 1 .. 4 |-> 0],
      currency                 |-> [i \in 1 .. 20 |-> 0],
      numDecimalsStrikePrice   |-> [i \in 1 .. 1 |-> 0],
      minOptionsPrice          |-> [i \in 1 .. 8 |-> 0],
      maxOptionsPrice          |-> [i \in 1 .. 8 |-> 0],
      incrementPremiumPrice    |-> [i \in 1 .. 4 |-> 0],
      optionsExpirationYear    |-> [i \in 1 .. 2 |-> 0],
      optionsExpirationMonth   |-> [i \in 1 .. 2 |-> 0],
      optionsExpirationDay     |-> [i \in 1 .. 2 |-> 0],
      optionsStyle             |-> [i \in 1 .. 1 |-> 0],
      optionsExpirationType    |-> [i \in 1 .. 1 |-> 0],
      hedgeMarketId            |-> [i \in 1 .. 4 |-> 0],
      settlePriceDenominator   |-> [i \in 1 .. 1 |-> 0],
      unitQtyDenominator       |-> [i \in 1 .. 1 |-> 0],
      tickValue                |-> [i \in 1 .. 8 |-> 0],
      flexAllowed              |-> [i \in 1 .. 1 |-> 0],
      settlementType           |-> [i \in 1 .. 1 |-> 0],
      isBlockOnly              |-> [i \in 1 .. 1 |-> 0],
      gtAllowed                |-> [i \in 1 .. 1 |-> 0],
      crossOrderSupported      |-> [i \in 1 .. 1 |-> 0],
      guaranteedCrossSupported |-> [i \in 1 .. 1 |-> 0],
      unitOfMeasure            |-> [i \in 1 .. 30 |-> 0] ]

(* New Options Market Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOptionsMarketDefinitionMessage ==
    { ZeroNewOptionsMarketDefinitionMessage }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.underlyingMarketId = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.futuresContractSymbol = one] : one \in Sample(70) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.orderPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.incrementQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.marketDesc = one] : one \in Sample(120) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.dealPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.currency = one] : one \in Sample(20) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.numDecimalsStrikePrice = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.minOptionsPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.maxOptionsPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.incrementPremiumPrice = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.optionsExpirationYear = one] : one \in Sample(2) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.optionsExpirationMonth = one] : one \in Sample(2) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.optionsExpirationDay = one] : one \in Sample(2) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.optionsStyle = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.optionsExpirationType = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.hedgeMarketId = one] : one \in Sample(4) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.settlePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.unitQtyDenominator = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.tickValue = one] : one \in Sample(8) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.flexAllowed = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.isBlockOnly = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.gtAllowed = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.crossOrderSupported = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.guaranteedCrossSupported = one] : one \in Sample(1) }
        \cup { [ZeroNewOptionsMarketDefinitionMessage EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }

(***************************************************************************)
(* Rfq Message: 31 bytes                                                   *)
(***************************************************************************)

RfqMessage ==
    [ marketId           : Sample(4),
      messageTimestamp   : Sample(8),
      rfqSystemId        : Sample(8),
      marketTypeId       : Sample(2),
      underlyingMarketId : Sample(4),
      quantity           : Sample(4),
      side               : Sample(1) ]

EncodeRfqMessage(message) ==
    message.marketId
        \o message.messageTimestamp
        \o message.rfqSystemId
        \o message.marketTypeId
        \o message.underlyingMarketId
        \o message.quantity
        \o message.side

DecodeRfqMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET messageTimestamp == ReadBytes(marketId.rest, 8) IN IF ~messageTimestamp.ok THEN Fail ELSE
    LET rfqSystemId == ReadBytes(messageTimestamp.rest, 8) IN IF ~rfqSystemId.ok THEN Fail ELSE
    LET marketTypeId == ReadBytes(rfqSystemId.rest, 2) IN IF ~marketTypeId.ok THEN Fail ELSE
    LET underlyingMarketId == ReadBytes(marketTypeId.rest, 4) IN IF ~underlyingMarketId.ok THEN Fail ELSE
    LET quantity == ReadBytes(underlyingMarketId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ marketId           |-> marketId.value,
         messageTimestamp   |-> messageTimestamp.value,
         rfqSystemId        |-> rfqSystemId.value,
         marketTypeId       |-> marketTypeId.value,
         underlyingMarketId |-> underlyingMarketId.value,
         quantity           |-> quantity.value,
         side               |-> side.value ], side.rest)

ZeroRfqMessage ==
    [ marketId           |-> [i \in 1 .. 4 |-> 0],
      messageTimestamp   |-> [i \in 1 .. 8 |-> 0],
      rfqSystemId        |-> [i \in 1 .. 8 |-> 0],
      marketTypeId       |-> [i \in 1 .. 2 |-> 0],
      underlyingMarketId |-> [i \in 1 .. 4 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0] ]

(* Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqMessage ==
    { ZeroRfqMessage }
        \cup { [ZeroRfqMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroRfqMessage EXCEPT !.messageTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRfqMessage EXCEPT !.rfqSystemId = one] : one \in Sample(8) }
        \cup { [ZeroRfqMessage EXCEPT !.marketTypeId = one] : one \in Sample(2) }
        \cup { [ZeroRfqMessage EXCEPT !.underlyingMarketId = one] : one \in Sample(4) }
        \cup { [ZeroRfqMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroRfqMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Open Interest Message: 26 bytes                                  *)
(***************************************************************************)

OptionOpenInterestMessage ==
    [ marketId         : Sample(4),
      openInterest     : Sample(4),
      messageDateTime  : Sample(8),
      openInterestDate : Sample(10) ]

EncodeOptionOpenInterestMessage(message) ==
    message.marketId
        \o message.openInterest
        \o message.messageDateTime
        \o message.openInterestDate

DecodeOptionOpenInterestMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET openInterest == ReadBytes(marketId.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(openInterest.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(messageDateTime.rest, 10) IN IF ~openInterestDate.ok THEN Fail ELSE
    Ok([ marketId         |-> marketId.value,
         openInterest     |-> openInterest.value,
         messageDateTime  |-> messageDateTime.value,
         openInterestDate |-> openInterestDate.value ], openInterestDate.rest)

ZeroOptionOpenInterestMessage ==
    [ marketId         |-> [i \in 1 .. 4 |-> 0],
      openInterest     |-> [i \in 1 .. 4 |-> 0],
      messageDateTime  |-> [i \in 1 .. 8 |-> 0],
      openInterestDate |-> [i \in 1 .. 10 |-> 0] ]

(* Option Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionOpenInterestMessage ==
    { ZeroOptionOpenInterestMessage }
        \cup { [ZeroOptionOpenInterestMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroOptionOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroOptionOpenInterestMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroOptionOpenInterestMessage EXCEPT !.openInterestDate = one] : one \in Sample(10) }

(***************************************************************************)
(* Option Settlement Price Message: 53 bytes                               *)
(***************************************************************************)

OptionSettlementPriceMessage ==
    [ marketId                              : Sample(4),
      settlementPriceWithDealPricePrecision : Sample(8),
      messageDateTime                       : Sample(8),
      isOfficial                            : Sample(1),
      valuationDateTime                     : Sample(8),
      volatility                            : Sample(8),
      settlementPrice                       : Sample(8),
      delta                                 : Sample(8) ]

EncodeOptionSettlementPriceMessage(message) ==
    message.marketId
        \o message.settlementPriceWithDealPricePrecision
        \o message.messageDateTime
        \o message.isOfficial
        \o message.valuationDateTime
        \o message.volatility
        \o message.settlementPrice
        \o message.delta

DecodeOptionSettlementPriceMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET settlementPriceWithDealPricePrecision == ReadBytes(marketId.rest, 8) IN IF ~settlementPriceWithDealPricePrecision.ok THEN Fail ELSE
    LET messageDateTime == ReadBytes(settlementPriceWithDealPricePrecision.rest, 8) IN IF ~messageDateTime.ok THEN Fail ELSE
    LET isOfficial == ReadBytes(messageDateTime.rest, 1) IN IF ~isOfficial.ok THEN Fail ELSE
    LET valuationDateTime == ReadBytes(isOfficial.rest, 8) IN IF ~valuationDateTime.ok THEN Fail ELSE
    LET volatility == ReadBytes(valuationDateTime.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(volatility.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET delta == ReadBytes(settlementPrice.rest, 8) IN IF ~delta.ok THEN Fail ELSE
    Ok([ marketId                              |-> marketId.value,
         settlementPriceWithDealPricePrecision |-> settlementPriceWithDealPricePrecision.value,
         messageDateTime                       |-> messageDateTime.value,
         isOfficial                            |-> isOfficial.value,
         valuationDateTime                     |-> valuationDateTime.value,
         volatility                            |-> volatility.value,
         settlementPrice                       |-> settlementPrice.value,
         delta                                 |-> delta.value ], delta.rest)

ZeroOptionSettlementPriceMessage ==
    [ marketId                              |-> [i \in 1 .. 4 |-> 0],
      settlementPriceWithDealPricePrecision |-> [i \in 1 .. 8 |-> 0],
      messageDateTime                       |-> [i \in 1 .. 8 |-> 0],
      isOfficial                            |-> [i \in 1 .. 1 |-> 0],
      valuationDateTime                     |-> [i \in 1 .. 8 |-> 0],
      volatility                            |-> [i \in 1 .. 8 |-> 0],
      settlementPrice                       |-> [i \in 1 .. 8 |-> 0],
      delta                                 |-> [i \in 1 .. 8 |-> 0] ]

(* Option Settlement Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionSettlementPriceMessage ==
    { ZeroOptionSettlementPriceMessage }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.settlementPriceWithDealPricePrecision = one] : one \in Sample(8) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.messageDateTime = one] : one \in Sample(8) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.isOfficial = one] : one \in Sample(1) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.valuationDateTime = one] : one \in Sample(8) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionSettlementPriceMessage EXCEPT !.delta = one] : one \in Sample(8) }

(***************************************************************************)
(* Old Style Options Trade And Market Stats Message: 83 bytes              *)
(***************************************************************************)

OldStyleOptionsTradeAndMarketStatsMessage ==
    [ underlyingMarketId      : Sample(4),
      tradeId                 : Sample(8),
      price                   : Sample(8),
      quantity                : Sample(4),
      offMarketTradeIndicator : Sample(1),
      transactDateTime        : Sample(8),
      optionType              : Sample(1),
      strikePrice             : Sample(8),
      eventCode               : Sample(1),
      totalVolume             : Sample(4),
      blockVolume             : Sample(4),
      efsVolume               : Sample(4),
      efpVolume               : Sample(4),
      high                    : Sample(8),
      low                     : Sample(8),
      vwap                    : Sample(8) ]

EncodeOldStyleOptionsTradeAndMarketStatsMessage(message) ==
    message.underlyingMarketId
        \o message.tradeId
        \o message.price
        \o message.quantity
        \o message.offMarketTradeIndicator
        \o message.transactDateTime
        \o message.optionType
        \o message.strikePrice
        \o message.eventCode
        \o message.totalVolume
        \o message.blockVolume
        \o message.efsVolume
        \o message.efpVolume
        \o message.high
        \o message.low
        \o message.vwap

DecodeOldStyleOptionsTradeAndMarketStatsMessage(bytes) ==
    LET underlyingMarketId == ReadBytes(bytes, 4) IN IF ~underlyingMarketId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(underlyingMarketId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET offMarketTradeIndicator == ReadBytes(quantity.rest, 1) IN IF ~offMarketTradeIndicator.ok THEN Fail ELSE
    LET transactDateTime == ReadBytes(offMarketTradeIndicator.rest, 8) IN IF ~transactDateTime.ok THEN Fail ELSE
    LET optionType == ReadBytes(transactDateTime.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET eventCode == ReadBytes(strikePrice.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(eventCode.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET blockVolume == ReadBytes(totalVolume.rest, 4) IN IF ~blockVolume.ok THEN Fail ELSE
    LET efsVolume == ReadBytes(blockVolume.rest, 4) IN IF ~efsVolume.ok THEN Fail ELSE
    LET efpVolume == ReadBytes(efsVolume.rest, 4) IN IF ~efpVolume.ok THEN Fail ELSE
    LET high == ReadBytes(efpVolume.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET vwap == ReadBytes(low.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    Ok([ underlyingMarketId      |-> underlyingMarketId.value,
         tradeId                 |-> tradeId.value,
         price                   |-> price.value,
         quantity                |-> quantity.value,
         offMarketTradeIndicator |-> offMarketTradeIndicator.value,
         transactDateTime        |-> transactDateTime.value,
         optionType              |-> optionType.value,
         strikePrice             |-> strikePrice.value,
         eventCode               |-> eventCode.value,
         totalVolume             |-> totalVolume.value,
         blockVolume             |-> blockVolume.value,
         efsVolume               |-> efsVolume.value,
         efpVolume               |-> efpVolume.value,
         high                    |-> high.value,
         low                     |-> low.value,
         vwap                    |-> vwap.value ], vwap.rest)

ZeroOldStyleOptionsTradeAndMarketStatsMessage ==
    [ underlyingMarketId      |-> [i \in 1 .. 4 |-> 0],
      tradeId                 |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      offMarketTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      transactDateTime        |-> [i \in 1 .. 8 |-> 0],
      optionType              |-> [i \in 1 .. 1 |-> 0],
      strikePrice             |-> [i \in 1 .. 8 |-> 0],
      eventCode               |-> [i \in 1 .. 1 |-> 0],
      totalVolume             |-> [i \in 1 .. 4 |-> 0],
      blockVolume             |-> [i \in 1 .. 4 |-> 0],
      efsVolume               |-> [i \in 1 .. 4 |-> 0],
      efpVolume               |-> [i \in 1 .. 4 |-> 0],
      high                    |-> [i \in 1 .. 8 |-> 0],
      low                     |-> [i \in 1 .. 8 |-> 0],
      vwap                    |-> [i \in 1 .. 8 |-> 0] ]

(* Old Style Options Trade And Market Stats Message at zero, then each field in turn at the values it is checked at *)
CheckedOldStyleOptionsTradeAndMarketStatsMessage ==
    { ZeroOldStyleOptionsTradeAndMarketStatsMessage }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.underlyingMarketId = one] : one \in Sample(4) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.offMarketTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.transactDateTime = one] : one \in Sample(8) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.blockVolume = one] : one \in Sample(4) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.efsVolume = one] : one \in Sample(4) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.efpVolume = one] : one \in Sample(4) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroOldStyleOptionsTradeAndMarketStatsMessage EXCEPT !.vwap = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

MarketSnapshotMessageCode == 67  \* "C"
TradeMessageCode == 71  \* "G"
SpotMarketTradeMessageCode == 89  \* "Y"
InvestigatedTradeMessageCode == 72  \* "H"
CancelledTradeMessageCode == 73  \* "I"
MarketStatisticsMessageCode == 74  \* "J"
MarketStateChangeMessageCode == 75  \* "K"
SystemTextMessageCode == 76  \* "L"
OpenInterestMessageCode == 77  \* "M"
OpenPriceMessageCode == 78  \* "N"
ClosePriceMessageCode == 99  \* "c"
SettlementPriceMessageCode == 79  \* "O"
MarkerIndexPricesCode == 122  \* "z"
EndOfDayMarketSummaryMessageCode == 117  \* "u"
MarketEventMessageCode == 102  \* "f"
PreOpenPriceIndicatorMessageCode == 103  \* "g"
StripInfoMessageCode == 105  \* "i"
IntervalPriceLimitNotificationMessageCode == 86  \* "V"
NewFuturesStrategyDefinitionMessageCode == 57  \* "9"
NewExpiryMessageCode == 82  \* "R"
SpecialFieldMessageCode == 98  \* "b"
MarketSnapshotOrderMessageCode == 68  \* "D"
AddOrModifyOrderMessageCode == 69  \* "E"
DeleteOrderMessageCode == 70  \* "F"
MessageBundleMarkerCode == 84  \* "T"
FixingTransitionMessageCode == 51  \* "3"
FixingLockdownMessageCode == 52  \* "4"
MarketSnapshotPriceLevelMessageCode == 109  \* "m"
AddPriceLevelMessageCode == 116  \* "t"
ChangePriceLevelMessageCode == 115  \* "s"
DeletePriceLevelMessageCode == 114  \* "r"
NewOptionsStrategyDefinitionMessageCode == 85  \* "U"
NewOptionsMarketDefinitionMessageCode == 108  \* "l"
RfqMessageCode == 107  \* "k"
OptionOpenInterestMessageCode == 118  \* "v"
OptionSettlementPriceMessageCode == 119  \* "w"
OldStyleOptionsTradeAndMarketStatsMessageCode == 87  \* "W"

Payload ==
    [ tag : {MarketSnapshotMessageCode}, body : MarketSnapshotMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {SpotMarketTradeMessageCode}, body : SpotMarketTradeMessage ]
        \cup [ tag : {InvestigatedTradeMessageCode}, body : InvestigatedTradeMessage ]
        \cup [ tag : {CancelledTradeMessageCode}, body : CancelledTradeMessage ]
        \cup [ tag : {MarketStatisticsMessageCode}, body : MarketStatisticsMessage ]
        \cup [ tag : {MarketStateChangeMessageCode}, body : MarketStateChangeMessage ]
        \cup [ tag : {SystemTextMessageCode}, body : SystemTextMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {OpenPriceMessageCode}, body : OpenPriceMessage ]
        \cup [ tag : {ClosePriceMessageCode}, body : ClosePriceMessage ]
        \cup [ tag : {SettlementPriceMessageCode}, body : SettlementPriceMessage ]
        \cup [ tag : {MarkerIndexPricesCode}, body : MarkerIndexPrices ]
        \cup [ tag : {EndOfDayMarketSummaryMessageCode}, body : EndOfDayMarketSummaryMessage ]
        \cup [ tag : {MarketEventMessageCode}, body : MarketEventMessage ]
        \cup [ tag : {PreOpenPriceIndicatorMessageCode}, body : PreOpenPriceIndicatorMessage ]
        \cup [ tag : {StripInfoMessageCode}, body : StripInfoMessage ]
        \cup [ tag : {IntervalPriceLimitNotificationMessageCode}, body : IntervalPriceLimitNotificationMessage ]
        \cup [ tag : {NewFuturesStrategyDefinitionMessageCode}, body : NewFuturesStrategyDefinitionMessage ]
        \cup [ tag : {NewExpiryMessageCode}, body : NewExpiryMessage ]
        \cup [ tag : {SpecialFieldMessageCode}, body : SpecialFieldMessage ]
        \cup [ tag : {MarketSnapshotOrderMessageCode}, body : MarketSnapshotOrderMessage ]
        \cup [ tag : {AddOrModifyOrderMessageCode}, body : AddOrModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {MessageBundleMarkerCode}, body : MessageBundleMarker ]
        \cup [ tag : {FixingTransitionMessageCode}, body : FixingTransitionMessage ]
        \cup [ tag : {FixingLockdownMessageCode}, body : FixingLockdownMessage ]
        \cup [ tag : {MarketSnapshotPriceLevelMessageCode}, body : MarketSnapshotPriceLevelMessage ]
        \cup [ tag : {AddPriceLevelMessageCode}, body : AddPriceLevelMessage ]
        \cup [ tag : {ChangePriceLevelMessageCode}, body : ChangePriceLevelMessage ]
        \cup [ tag : {DeletePriceLevelMessageCode}, body : DeletePriceLevelMessage ]
        \cup [ tag : {NewOptionsStrategyDefinitionMessageCode}, body : NewOptionsStrategyDefinitionMessage ]
        \cup [ tag : {NewOptionsMarketDefinitionMessageCode}, body : NewOptionsMarketDefinitionMessage ]
        \cup [ tag : {RfqMessageCode}, body : RfqMessage ]
        \cup [ tag : {OptionOpenInterestMessageCode}, body : OptionOpenInterestMessage ]
        \cup [ tag : {OptionSettlementPriceMessageCode}, body : OptionSettlementPriceMessage ]
        \cup [ tag : {OldStyleOptionsTradeAndMarketStatsMessageCode}, body : OldStyleOptionsTradeAndMarketStatsMessage ]

EncodePayload(message) ==
    CASE message.tag = MarketSnapshotMessageCode -> EncodeMarketSnapshotMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = SpotMarketTradeMessageCode -> EncodeSpotMarketTradeMessage(message.body)
      [] message.tag = InvestigatedTradeMessageCode -> EncodeInvestigatedTradeMessage(message.body)
      [] message.tag = CancelledTradeMessageCode -> EncodeCancelledTradeMessage(message.body)
      [] message.tag = MarketStatisticsMessageCode -> EncodeMarketStatisticsMessage(message.body)
      [] message.tag = MarketStateChangeMessageCode -> EncodeMarketStateChangeMessage(message.body)
      [] message.tag = SystemTextMessageCode -> EncodeSystemTextMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = OpenPriceMessageCode -> EncodeOpenPriceMessage(message.body)
      [] message.tag = ClosePriceMessageCode -> EncodeClosePriceMessage(message.body)
      [] message.tag = SettlementPriceMessageCode -> EncodeSettlementPriceMessage(message.body)
      [] message.tag = MarkerIndexPricesCode -> EncodeMarkerIndexPrices(message.body)
      [] message.tag = EndOfDayMarketSummaryMessageCode -> EncodeEndOfDayMarketSummaryMessage(message.body)
      [] message.tag = MarketEventMessageCode -> EncodeMarketEventMessage(message.body)
      [] message.tag = PreOpenPriceIndicatorMessageCode -> EncodePreOpenPriceIndicatorMessage(message.body)
      [] message.tag = StripInfoMessageCode -> EncodeStripInfoMessage(message.body)
      [] message.tag = IntervalPriceLimitNotificationMessageCode -> EncodeIntervalPriceLimitNotificationMessage(message.body)
      [] message.tag = NewFuturesStrategyDefinitionMessageCode -> EncodeNewFuturesStrategyDefinitionMessage(message.body)
      [] message.tag = NewExpiryMessageCode -> EncodeNewExpiryMessage(message.body)
      [] message.tag = SpecialFieldMessageCode -> EncodeSpecialFieldMessage(message.body)
      [] message.tag = MarketSnapshotOrderMessageCode -> EncodeMarketSnapshotOrderMessage(message.body)
      [] message.tag = AddOrModifyOrderMessageCode -> EncodeAddOrModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = MessageBundleMarkerCode -> EncodeMessageBundleMarker(message.body)
      [] message.tag = FixingTransitionMessageCode -> EncodeFixingTransitionMessage(message.body)
      [] message.tag = FixingLockdownMessageCode -> EncodeFixingLockdownMessage(message.body)
      [] message.tag = MarketSnapshotPriceLevelMessageCode -> EncodeMarketSnapshotPriceLevelMessage(message.body)
      [] message.tag = AddPriceLevelMessageCode -> EncodeAddPriceLevelMessage(message.body)
      [] message.tag = ChangePriceLevelMessageCode -> EncodeChangePriceLevelMessage(message.body)
      [] message.tag = DeletePriceLevelMessageCode -> EncodeDeletePriceLevelMessage(message.body)
      [] message.tag = NewOptionsStrategyDefinitionMessageCode -> EncodeNewOptionsStrategyDefinitionMessage(message.body)
      [] message.tag = NewOptionsMarketDefinitionMessageCode -> EncodeNewOptionsMarketDefinitionMessage(message.body)
      [] message.tag = RfqMessageCode -> EncodeRfqMessage(message.body)
      [] message.tag = OptionOpenInterestMessageCode -> EncodeOptionOpenInterestMessage(message.body)
      [] message.tag = OptionSettlementPriceMessageCode -> EncodeOptionSettlementPriceMessage(message.body)
      [] message.tag = OldStyleOptionsTradeAndMarketStatsMessageCode -> EncodeOldStyleOptionsTradeAndMarketStatsMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MarketSnapshotMessageCode -> DecodeMarketSnapshotMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = SpotMarketTradeMessageCode -> DecodeSpotMarketTradeMessage(bytes)
              [] tag = InvestigatedTradeMessageCode -> DecodeInvestigatedTradeMessage(bytes)
              [] tag = CancelledTradeMessageCode -> DecodeCancelledTradeMessage(bytes)
              [] tag = MarketStatisticsMessageCode -> DecodeMarketStatisticsMessage(bytes)
              [] tag = MarketStateChangeMessageCode -> DecodeMarketStateChangeMessage(bytes)
              [] tag = SystemTextMessageCode -> DecodeSystemTextMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = OpenPriceMessageCode -> DecodeOpenPriceMessage(bytes)
              [] tag = ClosePriceMessageCode -> DecodeClosePriceMessage(bytes)
              [] tag = SettlementPriceMessageCode -> DecodeSettlementPriceMessage(bytes)
              [] tag = MarkerIndexPricesCode -> DecodeMarkerIndexPrices(bytes)
              [] tag = EndOfDayMarketSummaryMessageCode -> DecodeEndOfDayMarketSummaryMessage(bytes)
              [] tag = MarketEventMessageCode -> DecodeMarketEventMessage(bytes)
              [] tag = PreOpenPriceIndicatorMessageCode -> DecodePreOpenPriceIndicatorMessage(bytes)
              [] tag = StripInfoMessageCode -> DecodeStripInfoMessage(bytes)
              [] tag = IntervalPriceLimitNotificationMessageCode -> DecodeIntervalPriceLimitNotificationMessage(bytes)
              [] tag = NewFuturesStrategyDefinitionMessageCode -> DecodeNewFuturesStrategyDefinitionMessage(bytes)
              [] tag = NewExpiryMessageCode -> DecodeNewExpiryMessage(bytes)
              [] tag = SpecialFieldMessageCode -> DecodeSpecialFieldMessage(bytes)
              [] tag = MarketSnapshotOrderMessageCode -> DecodeMarketSnapshotOrderMessage(bytes)
              [] tag = AddOrModifyOrderMessageCode -> DecodeAddOrModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = MessageBundleMarkerCode -> DecodeMessageBundleMarker(bytes)
              [] tag = FixingTransitionMessageCode -> DecodeFixingTransitionMessage(bytes)
              [] tag = FixingLockdownMessageCode -> DecodeFixingLockdownMessage(bytes)
              [] tag = MarketSnapshotPriceLevelMessageCode -> DecodeMarketSnapshotPriceLevelMessage(bytes)
              [] tag = AddPriceLevelMessageCode -> DecodeAddPriceLevelMessage(bytes)
              [] tag = ChangePriceLevelMessageCode -> DecodeChangePriceLevelMessage(bytes)
              [] tag = DeletePriceLevelMessageCode -> DecodeDeletePriceLevelMessage(bytes)
              [] tag = NewOptionsStrategyDefinitionMessageCode -> DecodeNewOptionsStrategyDefinitionMessage(bytes)
              [] tag = NewOptionsMarketDefinitionMessageCode -> DecodeNewOptionsMarketDefinitionMessage(bytes)
              [] tag = RfqMessageCode -> DecodeRfqMessage(bytes)
              [] tag = OptionOpenInterestMessageCode -> DecodeOptionOpenInterestMessage(bytes)
              [] tag = OptionSettlementPriceMessageCode -> DecodeOptionSettlementPriceMessage(bytes)
              [] tag = OldStyleOptionsTradeAndMarketStatsMessageCode -> DecodeOldStyleOptionsTradeAndMarketStatsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MarketSnapshotMessageCode, body |-> ZeroMarketSnapshotMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MarketSnapshotMessageCode, body |-> one] : one \in CheckedMarketSnapshotMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> SpotMarketTradeMessageCode, body |-> one] : one \in CheckedSpotMarketTradeMessage }
        \cup { [tag |-> InvestigatedTradeMessageCode, body |-> one] : one \in CheckedInvestigatedTradeMessage }
        \cup { [tag |-> CancelledTradeMessageCode, body |-> one] : one \in CheckedCancelledTradeMessage }
        \cup { [tag |-> MarketStatisticsMessageCode, body |-> one] : one \in CheckedMarketStatisticsMessage }
        \cup { [tag |-> MarketStateChangeMessageCode, body |-> one] : one \in CheckedMarketStateChangeMessage }
        \cup { [tag |-> SystemTextMessageCode, body |-> one] : one \in CheckedSystemTextMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> OpenPriceMessageCode, body |-> one] : one \in CheckedOpenPriceMessage }
        \cup { [tag |-> ClosePriceMessageCode, body |-> one] : one \in CheckedClosePriceMessage }
        \cup { [tag |-> SettlementPriceMessageCode, body |-> one] : one \in CheckedSettlementPriceMessage }
        \cup { [tag |-> MarkerIndexPricesCode, body |-> one] : one \in CheckedMarkerIndexPrices }
        \cup { [tag |-> EndOfDayMarketSummaryMessageCode, body |-> one] : one \in CheckedEndOfDayMarketSummaryMessage }
        \cup { [tag |-> MarketEventMessageCode, body |-> one] : one \in CheckedMarketEventMessage }
        \cup { [tag |-> PreOpenPriceIndicatorMessageCode, body |-> one] : one \in CheckedPreOpenPriceIndicatorMessage }
        \cup { [tag |-> StripInfoMessageCode, body |-> one] : one \in CheckedStripInfoMessage }
        \cup { [tag |-> IntervalPriceLimitNotificationMessageCode, body |-> one] : one \in CheckedIntervalPriceLimitNotificationMessage }
        \cup { [tag |-> NewFuturesStrategyDefinitionMessageCode, body |-> one] : one \in CheckedNewFuturesStrategyDefinitionMessage }
        \cup { [tag |-> NewExpiryMessageCode, body |-> one] : one \in CheckedNewExpiryMessage }
        \cup { [tag |-> SpecialFieldMessageCode, body |-> one] : one \in CheckedSpecialFieldMessage }
        \cup { [tag |-> MarketSnapshotOrderMessageCode, body |-> one] : one \in CheckedMarketSnapshotOrderMessage }
        \cup { [tag |-> AddOrModifyOrderMessageCode, body |-> one] : one \in CheckedAddOrModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> MessageBundleMarkerCode, body |-> one] : one \in CheckedMessageBundleMarker }
        \cup { [tag |-> FixingTransitionMessageCode, body |-> one] : one \in CheckedFixingTransitionMessage }
        \cup { [tag |-> FixingLockdownMessageCode, body |-> one] : one \in CheckedFixingLockdownMessage }
        \cup { [tag |-> MarketSnapshotPriceLevelMessageCode, body |-> one] : one \in CheckedMarketSnapshotPriceLevelMessage }
        \cup { [tag |-> AddPriceLevelMessageCode, body |-> one] : one \in CheckedAddPriceLevelMessage }
        \cup { [tag |-> ChangePriceLevelMessageCode, body |-> one] : one \in CheckedChangePriceLevelMessage }
        \cup { [tag |-> DeletePriceLevelMessageCode, body |-> one] : one \in CheckedDeletePriceLevelMessage }
        \cup { [tag |-> NewOptionsStrategyDefinitionMessageCode, body |-> one] : one \in CheckedNewOptionsStrategyDefinitionMessage }
        \cup { [tag |-> NewOptionsMarketDefinitionMessageCode, body |-> one] : one \in CheckedNewOptionsMarketDefinitionMessage }
        \cup { [tag |-> RfqMessageCode, body |-> one] : one \in CheckedRfqMessage }
        \cup { [tag |-> OptionOpenInterestMessageCode, body |-> one] : one \in CheckedOptionOpenInterestMessage }
        \cup { [tag |-> OptionSettlementPriceMessageCode, body |-> one] : one \in CheckedOptionSettlementPriceMessage }
        \cup { [tag |-> OldStyleOptionsTradeAndMarketStatsMessageCode, body |-> one] : one \in CheckedOldStyleOptionsTradeAndMarketStatsMessage }

(***************************************************************************)
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ payload   : Payload,
      extraData : SampleBytes ]

EncodeMessageBody(message) ==
    EncodePayload(message.payload)
        \o message.extraData

(* Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(message.payload.tag, 1) \o EncodeUIntBE(Len(body), 2) \o body

DecodeMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET length == ReadUIntBE(messageType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
    IN
    LET payload == DecodePayload(messageType.value, framed) IN IF ~payload.ok THEN Fail ELSE
    LET extraData == Ok(payload.rest, << >>) IN IF ~extraData.ok THEN Fail ELSE
    IF extraData.rest # << >> THEN Fail ELSE
    Ok([ payload   |-> payload.value,
         extraData |-> extraData.value ], beyond)

ZeroMessage ==
    [ payload   |-> ZeroPayload,
      extraData |-> << >> ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroMessage EXCEPT !.extraData = one] : one \in SampleBytes }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> MarketSnapshotMessageCode, body |-> ZeroMarketSnapshotMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpotMarketTradeMessageCode, body |-> ZeroSpotMarketTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InvestigatedTradeMessageCode, body |-> ZeroInvestigatedTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CancelledTradeMessageCode, body |-> ZeroCancelledTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketStatisticsMessageCode, body |-> ZeroMarketStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketStateChangeMessageCode, body |-> ZeroMarketStateChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemTextMessageCode, body |-> ZeroSystemTextMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenPriceMessageCode, body |-> ZeroOpenPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClosePriceMessageCode, body |-> ZeroClosePriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementPriceMessageCode, body |-> ZeroSettlementPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarkerIndexPricesCode, body |-> ZeroMarkerIndexPrices]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDayMarketSummaryMessageCode, body |-> ZeroEndOfDayMarketSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketEventMessageCode, body |-> ZeroMarketEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PreOpenPriceIndicatorMessageCode, body |-> ZeroPreOpenPriceIndicatorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StripInfoMessageCode, body |-> ZeroStripInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IntervalPriceLimitNotificationMessageCode, body |-> ZeroIntervalPriceLimitNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewFuturesStrategyDefinitionMessageCode, body |-> ZeroNewFuturesStrategyDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewExpiryMessageCode, body |-> ZeroNewExpiryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpecialFieldMessageCode, body |-> ZeroSpecialFieldMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketSnapshotOrderMessageCode, body |-> ZeroMarketSnapshotOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrModifyOrderMessageCode, body |-> ZeroAddOrModifyOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MessageBundleMarkerCode, body |-> ZeroMessageBundleMarker]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FixingTransitionMessageCode, body |-> ZeroFixingTransitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FixingLockdownMessageCode, body |-> ZeroFixingLockdownMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketSnapshotPriceLevelMessageCode, body |-> ZeroMarketSnapshotPriceLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddPriceLevelMessageCode, body |-> ZeroAddPriceLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ChangePriceLevelMessageCode, body |-> ZeroChangePriceLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeletePriceLevelMessageCode, body |-> ZeroDeletePriceLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewOptionsStrategyDefinitionMessageCode, body |-> ZeroNewOptionsStrategyDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewOptionsMarketDefinitionMessageCode, body |-> ZeroNewOptionsMarketDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqMessageCode, body |-> ZeroRfqMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionOpenInterestMessageCode, body |-> ZeroOptionOpenInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionSettlementPriceMessageCode, body |-> ZeroOptionSettlementPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OldStyleOptionsTradeAndMarketStatsMessageCode, body |-> ZeroOldStyleOptionsTradeAndMarketStatsMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session      : Sample(2),
      sequence     : Sample(4),
      sentDateTime : Sample(8),
      message      : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntBE(Len(message.message), 2)
        \o message.sentDateTime
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 2) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET numberOfMsgs == ReadUIntBE(sequence.rest, 2) IN IF ~numberOfMsgs.ok THEN Fail ELSE
    LET sentDateTime == ReadBytes(numberOfMsgs.rest, 8) IN IF ~sentDateTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sentDateTime.rest, numberOfMsgs.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session      |-> session.value,
         sequence     |-> sequence.value,
         sentDateTime |-> sentDateTime.value,
         message      |-> message.value ], message.rest)

ZeroPacket ==
    [ session      |-> [i \in 1 .. 2 |-> 0],
      sequence     |-> [i \in 1 .. 4 |-> 0],
      sentDateTime |-> [i \in 1 .. 8 |-> 0],
      message      |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sentDateTime = one] : one \in Sample(8) }
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

(* Every Market Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSnapshotMessage ==
    \A message \in CheckedMarketSnapshotMessage :
        LET read == DecodeMarketSnapshotMessage(EncodeMarketSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Market Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotMarketTradeMessage ==
    \A message \in CheckedSpotMarketTradeMessage :
        LET read == DecodeSpotMarketTradeMessage(EncodeSpotMarketTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investigated Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestigatedTradeMessage ==
    \A message \in CheckedInvestigatedTradeMessage :
        LET read == DecodeInvestigatedTradeMessage(EncodeInvestigatedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancelled Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelledTradeMessage ==
    \A message \in CheckedCancelledTradeMessage :
        LET read == DecodeCancelledTradeMessage(EncodeCancelledTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatisticsMessage ==
    \A message \in CheckedMarketStatisticsMessage :
        LET read == DecodeMarketStatisticsMessage(EncodeMarketStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market State Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStateChangeMessage ==
    \A message \in CheckedMarketStateChangeMessage :
        LET read == DecodeMarketStateChangeMessage(EncodeMarketStateChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Text Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTextMessage ==
    \A message \in CheckedSystemTextMessage :
        LET read == DecodeSystemTextMessage(EncodeSystemTextMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestMessage ==
    \A message \in CheckedOpenInterestMessage :
        LET read == DecodeOpenInterestMessage(EncodeOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenPriceMessage ==
    \A message \in CheckedOpenPriceMessage :
        LET read == DecodeOpenPriceMessage(EncodeOpenPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Close Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosePriceMessage ==
    \A message \in CheckedClosePriceMessage :
        LET read == DecodeClosePriceMessage(EncodeClosePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementPriceMessage ==
    \A message \in CheckedSettlementPriceMessage :
        LET read == DecodeSettlementPriceMessage(EncodeSettlementPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Marker Index Prices decodes back to what was encoded, and leaves nothing over *)
RoundTripMarkerIndexPrices ==
    \A message \in CheckedMarkerIndexPrices :
        LET read == DecodeMarkerIndexPrices(EncodeMarkerIndexPrices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Market Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMarketSummaryMessage ==
    \A message \in CheckedEndOfDayMarketSummaryMessage :
        LET read == DecodeEndOfDayMarketSummaryMessage(EncodeEndOfDayMarketSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketEventMessage ==
    \A message \in CheckedMarketEventMessage :
        LET read == DecodeMarketEventMessage(EncodeMarketEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pre Open Price Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPreOpenPriceIndicatorMessage ==
    \A message \in CheckedPreOpenPriceIndicatorMessage :
        LET read == DecodePreOpenPriceIndicatorMessage(EncodePreOpenPriceIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strip Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStripInfoMessage ==
    \A message \in CheckedStripInfoMessage :
        LET read == DecodeStripInfoMessage(EncodeStripInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Interval Price Limit Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIntervalPriceLimitNotificationMessage ==
    \A message \in CheckedIntervalPriceLimitNotificationMessage :
        LET read == DecodeIntervalPriceLimitNotificationMessage(EncodeIntervalPriceLimitNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripLegDefinition ==
    \A message \in CheckedLegDefinition :
        LET read == DecodeLegDefinition(EncodeLegDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Futures Strategy Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewFuturesStrategyDefinitionMessage ==
    \A message \in CheckedNewFuturesStrategyDefinitionMessage :
        LET read == DecodeNewFuturesStrategyDefinitionMessage(EncodeNewFuturesStrategyDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Expiry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewExpiryMessage ==
    \A message \in CheckedNewExpiryMessage :
        LET read == DecodeNewExpiryMessage(EncodeNewExpiryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Field decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialField ==
    \A message \in CheckedSpecialField :
        LET read == DecodeSpecialField(EncodeSpecialField(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Field Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialFieldMessage ==
    \A message \in CheckedSpecialFieldMessage :
        LET read == DecodeSpecialFieldMessage(EncodeSpecialFieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Snapshot Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSnapshotOrderMessage ==
    \A message \in CheckedMarketSnapshotOrderMessage :
        LET read == DecodeMarketSnapshotOrderMessage(EncodeMarketSnapshotOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Or Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrModifyOrderMessage ==
    \A message \in CheckedAddOrModifyOrderMessage :
        LET read == DecodeAddOrModifyOrderMessage(EncodeAddOrModifyOrderMessage(message))
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

(* Every Message Bundle Marker decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBundleMarker ==
    \A message \in CheckedMessageBundleMarker :
        LET read == DecodeMessageBundleMarker(EncodeMessageBundleMarker(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fixing Transition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFixingTransitionMessage ==
    \A message \in CheckedFixingTransitionMessage :
        LET read == DecodeFixingTransitionMessage(EncodeFixingTransitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fixing Lockdown Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFixingLockdownMessage ==
    \A message \in CheckedFixingLockdownMessage :
        LET read == DecodeFixingLockdownMessage(EncodeFixingLockdownMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Snapshot Price Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSnapshotPriceLevelMessage ==
    \A message \in CheckedMarketSnapshotPriceLevelMessage :
        LET read == DecodeMarketSnapshotPriceLevelMessage(EncodeMarketSnapshotPriceLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Price Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddPriceLevelMessage ==
    \A message \in CheckedAddPriceLevelMessage :
        LET read == DecodeAddPriceLevelMessage(EncodeAddPriceLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Change Price Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripChangePriceLevelMessage ==
    \A message \in CheckedChangePriceLevelMessage :
        LET read == DecodeChangePriceLevelMessage(EncodeChangePriceLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Price Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeletePriceLevelMessage ==
    \A message \in CheckedDeletePriceLevelMessage :
        LET read == DecodeDeletePriceLevelMessage(EncodeDeletePriceLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Leg Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyLegDefinition ==
    \A message \in CheckedStrategyLegDefinition :
        LET read == DecodeStrategyLegDefinition(EncodeStrategyLegDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hedge Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripHedgeDefinition ==
    \A message \in CheckedHedgeDefinition :
        LET read == DecodeHedgeDefinition(EncodeHedgeDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Options Strategy Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOptionsStrategyDefinitionMessage ==
    \A message \in CheckedNewOptionsStrategyDefinitionMessage :
        LET read == DecodeNewOptionsStrategyDefinitionMessage(EncodeNewOptionsStrategyDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Options Market Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOptionsMarketDefinitionMessage ==
    \A message \in CheckedNewOptionsMarketDefinitionMessage :
        LET read == DecodeNewOptionsMarketDefinitionMessage(EncodeNewOptionsMarketDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqMessage ==
    \A message \in CheckedRfqMessage :
        LET read == DecodeRfqMessage(EncodeRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionOpenInterestMessage ==
    \A message \in CheckedOptionOpenInterestMessage :
        LET read == DecodeOptionOpenInterestMessage(EncodeOptionOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Settlement Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSettlementPriceMessage ==
    \A message \in CheckedOptionSettlementPriceMessage :
        LET read == DecodeOptionSettlementPriceMessage(EncodeOptionSettlementPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Old Style Options Trade And Market Stats Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOldStyleOptionsTradeAndMarketStatsMessage ==
    \A message \in CheckedOldStyleOptionsTradeAndMarketStatsMessage :
        LET read == DecodeOldStyleOptionsTradeAndMarketStatsMessage(EncodeOldStyleOptionsTradeAndMarketStatsMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 2, 3)) = Len(bytes) - 3

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
