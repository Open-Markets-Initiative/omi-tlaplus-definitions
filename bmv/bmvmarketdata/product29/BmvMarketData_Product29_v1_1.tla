------------------- MODULE BmvMarketData_Product29_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 29 v1.1               *)
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
(* Last Quote Message: 23 bytes                                            *)
(***************************************************************************)

LastQuoteMessage ==
    [ instrumentNumber  : Sample(4),
      origin            : Sample(1),
      volume            : Sample(8),
      priceRate         : Sample(8),
      directionOfTheBid : Sample(1),
      typeOfTrading     : Sample(1) ]

EncodeLastQuoteMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.volume
        \o message.priceRate
        \o message.directionOfTheBid
        \o message.typeOfTrading

DecodeLastQuoteMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET volume == ReadBytes(origin.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET priceRate == ReadBytes(volume.rest, 8) IN IF ~priceRate.ok THEN Fail ELSE
    LET directionOfTheBid == ReadBytes(priceRate.rest, 1) IN IF ~directionOfTheBid.ok THEN Fail ELSE
    LET typeOfTrading == ReadBytes(directionOfTheBid.rest, 1) IN IF ~typeOfTrading.ok THEN Fail ELSE
    Ok([ instrumentNumber  |-> instrumentNumber.value,
         origin            |-> origin.value,
         volume            |-> volume.value,
         priceRate         |-> priceRate.value,
         directionOfTheBid |-> directionOfTheBid.value,
         typeOfTrading     |-> typeOfTrading.value ], typeOfTrading.rest)

ZeroLastQuoteMessage ==
    [ instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      origin            |-> [i \in 1 .. 1 |-> 0],
      volume            |-> [i \in 1 .. 8 |-> 0],
      priceRate         |-> [i \in 1 .. 8 |-> 0],
      directionOfTheBid |-> [i \in 1 .. 1 |-> 0],
      typeOfTrading     |-> [i \in 1 .. 1 |-> 0] ]

(* Last Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLastQuoteMessage ==
    { ZeroLastQuoteMessage }
        \cup { [ZeroLastQuoteMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.priceRate = one] : one \in Sample(8) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.directionOfTheBid = one] : one \in Sample(1) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.typeOfTrading = one] : one \in Sample(1) }

(***************************************************************************)
(* Benchmark Trade Message: 25 bytes                                       *)
(***************************************************************************)

BenchmarkTradeMessage ==
    [ origin             : Sample(1),
      averageVolume      : Sample(8),
      averageTradedValue : Sample(8),
      market             : Sample(1),
      sector             : Sample(1),
      instrumentNumber   : Sample(4),
      indices            : Sample(2) ]

EncodeBenchmarkTradeMessage(message) ==
    message.origin
        \o message.averageVolume
        \o message.averageTradedValue
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeBenchmarkTradeMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET averageVolume == ReadBytes(origin.rest, 8) IN IF ~averageVolume.ok THEN Fail ELSE
    LET averageTradedValue == ReadBytes(averageVolume.rest, 8) IN IF ~averageTradedValue.ok THEN Fail ELSE
    LET market == ReadBytes(averageTradedValue.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin             |-> origin.value,
         averageVolume      |-> averageVolume.value,
         averageTradedValue |-> averageTradedValue.value,
         market             |-> market.value,
         sector             |-> sector.value,
         instrumentNumber   |-> instrumentNumber.value,
         indices            |-> indices.value ], indices.rest)

ZeroBenchmarkTradeMessage ==
    [ origin             |-> [i \in 1 .. 1 |-> 0],
      averageVolume      |-> [i \in 1 .. 8 |-> 0],
      averageTradedValue |-> [i \in 1 .. 8 |-> 0],
      market             |-> [i \in 1 .. 1 |-> 0],
      sector             |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber   |-> [i \in 1 .. 4 |-> 0],
      indices            |-> [i \in 1 .. 2 |-> 0] ]

(* Benchmark Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBenchmarkTradeMessage ==
    { ZeroBenchmarkTradeMessage }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.averageVolume = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.averageTradedValue = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroBenchmarkTradeMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Price Leaderboard Message: 33 bytes                                     *)
(***************************************************************************)

PriceLeaderboardMessage ==
    [ origin           : Sample(1),
      tBestBid         : Sample(4),
      tTieBestBid      : Sample(4),
      tWithoutBestBid  : Sample(4),
      tBestAsk         : Sample(4),
      tTieBestAsk      : Sample(4),
      tWithoutBestAsk  : Sample(4),
      market           : Sample(1),
      sector           : Sample(1),
      instrumentNumber : Sample(4),
      indices          : Sample(2) ]

EncodePriceLeaderboardMessage(message) ==
    message.origin
        \o message.tBestBid
        \o message.tTieBestBid
        \o message.tWithoutBestBid
        \o message.tBestAsk
        \o message.tTieBestAsk
        \o message.tWithoutBestAsk
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodePriceLeaderboardMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET tBestBid == ReadBytes(origin.rest, 4) IN IF ~tBestBid.ok THEN Fail ELSE
    LET tTieBestBid == ReadBytes(tBestBid.rest, 4) IN IF ~tTieBestBid.ok THEN Fail ELSE
    LET tWithoutBestBid == ReadBytes(tTieBestBid.rest, 4) IN IF ~tWithoutBestBid.ok THEN Fail ELSE
    LET tBestAsk == ReadBytes(tWithoutBestBid.rest, 4) IN IF ~tBestAsk.ok THEN Fail ELSE
    LET tTieBestAsk == ReadBytes(tBestAsk.rest, 4) IN IF ~tTieBestAsk.ok THEN Fail ELSE
    LET tWithoutBestAsk == ReadBytes(tTieBestAsk.rest, 4) IN IF ~tWithoutBestAsk.ok THEN Fail ELSE
    LET market == ReadBytes(tWithoutBestAsk.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin           |-> origin.value,
         tBestBid         |-> tBestBid.value,
         tTieBestBid      |-> tTieBestBid.value,
         tWithoutBestBid  |-> tWithoutBestBid.value,
         tBestAsk         |-> tBestAsk.value,
         tTieBestAsk      |-> tTieBestAsk.value,
         tWithoutBestAsk  |-> tWithoutBestAsk.value,
         market           |-> market.value,
         sector           |-> sector.value,
         instrumentNumber |-> instrumentNumber.value,
         indices          |-> indices.value ], indices.rest)

ZeroPriceLeaderboardMessage ==
    [ origin           |-> [i \in 1 .. 1 |-> 0],
      tBestBid         |-> [i \in 1 .. 4 |-> 0],
      tTieBestBid      |-> [i \in 1 .. 4 |-> 0],
      tWithoutBestBid  |-> [i \in 1 .. 4 |-> 0],
      tBestAsk         |-> [i \in 1 .. 4 |-> 0],
      tTieBestAsk      |-> [i \in 1 .. 4 |-> 0],
      tWithoutBestAsk  |-> [i \in 1 .. 4 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      indices          |-> [i \in 1 .. 2 |-> 0] ]

(* Price Leaderboard Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceLeaderboardMessage ==
    { ZeroPriceLeaderboardMessage }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.tBestBid = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.tTieBestBid = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.tWithoutBestBid = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.tBestAsk = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.tTieBestAsk = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.tWithoutBestAsk = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroPriceLeaderboardMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Trading Sniper Message: 73 bytes                                        *)
(***************************************************************************)

TradingSniperMessage ==
    [ origin           : Sample(1),
      depthBid         : Sample(8),
      depthAsk         : Sample(8),
      depthBid10L      : Sample(8),
      depthAsk10L      : Sample(8),
      vwpBid10L        : Sample(8),
      vwpAsk10L        : Sample(8),
      vwpBid           : Sample(8),
      vwpAsk           : Sample(8),
      market           : Sample(1),
      sector           : Sample(1),
      instrumentNumber : Sample(4),
      indices          : Sample(2) ]

EncodeTradingSniperMessage(message) ==
    message.origin
        \o message.depthBid
        \o message.depthAsk
        \o message.depthBid10L
        \o message.depthAsk10L
        \o message.vwpBid10L
        \o message.vwpAsk10L
        \o message.vwpBid
        \o message.vwpAsk
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeTradingSniperMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET depthBid == ReadBytes(origin.rest, 8) IN IF ~depthBid.ok THEN Fail ELSE
    LET depthAsk == ReadBytes(depthBid.rest, 8) IN IF ~depthAsk.ok THEN Fail ELSE
    LET depthBid10L == ReadBytes(depthAsk.rest, 8) IN IF ~depthBid10L.ok THEN Fail ELSE
    LET depthAsk10L == ReadBytes(depthBid10L.rest, 8) IN IF ~depthAsk10L.ok THEN Fail ELSE
    LET vwpBid10L == ReadBytes(depthAsk10L.rest, 8) IN IF ~vwpBid10L.ok THEN Fail ELSE
    LET vwpAsk10L == ReadBytes(vwpBid10L.rest, 8) IN IF ~vwpAsk10L.ok THEN Fail ELSE
    LET vwpBid == ReadBytes(vwpAsk10L.rest, 8) IN IF ~vwpBid.ok THEN Fail ELSE
    LET vwpAsk == ReadBytes(vwpBid.rest, 8) IN IF ~vwpAsk.ok THEN Fail ELSE
    LET market == ReadBytes(vwpAsk.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin           |-> origin.value,
         depthBid         |-> depthBid.value,
         depthAsk         |-> depthAsk.value,
         depthBid10L      |-> depthBid10L.value,
         depthAsk10L      |-> depthAsk10L.value,
         vwpBid10L        |-> vwpBid10L.value,
         vwpAsk10L        |-> vwpAsk10L.value,
         vwpBid           |-> vwpBid.value,
         vwpAsk           |-> vwpAsk.value,
         market           |-> market.value,
         sector           |-> sector.value,
         instrumentNumber |-> instrumentNumber.value,
         indices          |-> indices.value ], indices.rest)

ZeroTradingSniperMessage ==
    [ origin           |-> [i \in 1 .. 1 |-> 0],
      depthBid         |-> [i \in 1 .. 8 |-> 0],
      depthAsk         |-> [i \in 1 .. 8 |-> 0],
      depthBid10L      |-> [i \in 1 .. 8 |-> 0],
      depthAsk10L      |-> [i \in 1 .. 8 |-> 0],
      vwpBid10L        |-> [i \in 1 .. 8 |-> 0],
      vwpAsk10L        |-> [i \in 1 .. 8 |-> 0],
      vwpBid           |-> [i \in 1 .. 8 |-> 0],
      vwpAsk           |-> [i \in 1 .. 8 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      indices          |-> [i \in 1 .. 2 |-> 0] ]

(* Trading Sniper Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSniperMessage ==
    { ZeroTradingSniperMessage }
        \cup { [ZeroTradingSniperMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.depthBid = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.depthAsk = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.depthBid10L = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.depthAsk10L = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.vwpBid10L = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.vwpAsk10L = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.vwpBid = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.vwpAsk = one] : one \in Sample(8) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradingSniperMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Depth At Best Prices Message: 25 bytes                                  *)
(***************************************************************************)

DepthAtBestPricesMessage ==
    [ origin           : Sample(1),
      instrumentsBb    : Sample(2),
      instrumentsGvBb  : Sample(2),
      ratioVAtBb       : Sample(4),
      instrumentsBa    : Sample(2),
      instrumentsGvBa  : Sample(2),
      ratioVAtBa       : Sample(4),
      market           : Sample(1),
      sector           : Sample(1),
      instrumentNumber : Sample(4),
      indices          : Sample(2) ]

EncodeDepthAtBestPricesMessage(message) ==
    message.origin
        \o message.instrumentsBb
        \o message.instrumentsGvBb
        \o message.ratioVAtBb
        \o message.instrumentsBa
        \o message.instrumentsGvBa
        \o message.ratioVAtBa
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeDepthAtBestPricesMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET instrumentsBb == ReadBytes(origin.rest, 2) IN IF ~instrumentsBb.ok THEN Fail ELSE
    LET instrumentsGvBb == ReadBytes(instrumentsBb.rest, 2) IN IF ~instrumentsGvBb.ok THEN Fail ELSE
    LET ratioVAtBb == ReadBytes(instrumentsGvBb.rest, 4) IN IF ~ratioVAtBb.ok THEN Fail ELSE
    LET instrumentsBa == ReadBytes(ratioVAtBb.rest, 2) IN IF ~instrumentsBa.ok THEN Fail ELSE
    LET instrumentsGvBa == ReadBytes(instrumentsBa.rest, 2) IN IF ~instrumentsGvBa.ok THEN Fail ELSE
    LET ratioVAtBa == ReadBytes(instrumentsGvBa.rest, 4) IN IF ~ratioVAtBa.ok THEN Fail ELSE
    LET market == ReadBytes(ratioVAtBa.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin           |-> origin.value,
         instrumentsBb    |-> instrumentsBb.value,
         instrumentsGvBb  |-> instrumentsGvBb.value,
         ratioVAtBb       |-> ratioVAtBb.value,
         instrumentsBa    |-> instrumentsBa.value,
         instrumentsGvBa  |-> instrumentsGvBa.value,
         ratioVAtBa       |-> ratioVAtBa.value,
         market           |-> market.value,
         sector           |-> sector.value,
         instrumentNumber |-> instrumentNumber.value,
         indices          |-> indices.value ], indices.rest)

ZeroDepthAtBestPricesMessage ==
    [ origin           |-> [i \in 1 .. 1 |-> 0],
      instrumentsBb    |-> [i \in 1 .. 2 |-> 0],
      instrumentsGvBb  |-> [i \in 1 .. 2 |-> 0],
      ratioVAtBb       |-> [i \in 1 .. 4 |-> 0],
      instrumentsBa    |-> [i \in 1 .. 2 |-> 0],
      instrumentsGvBa  |-> [i \in 1 .. 2 |-> 0],
      ratioVAtBa       |-> [i \in 1 .. 4 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      indices          |-> [i \in 1 .. 2 |-> 0] ]

(* Depth At Best Prices Message at zero, then each field in turn at the values it is checked at *)
CheckedDepthAtBestPricesMessage ==
    { ZeroDepthAtBestPricesMessage }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.instrumentsBb = one] : one \in Sample(2) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.instrumentsGvBb = one] : one \in Sample(2) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.ratioVAtBb = one] : one \in Sample(4) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.instrumentsBa = one] : one \in Sample(2) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.instrumentsGvBa = one] : one \in Sample(2) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.ratioVAtBa = one] : one \in Sample(4) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroDepthAtBestPricesMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LastQuoteMessageCode == 109  \* 0x6d
BenchmarkTradeMessageCode == 58  \* 0x3a
PriceLeaderboardMessageCode == 64  \* 0x40
TradingSniperMessageCode == 60  \* 0x3c
DepthAtBestPricesMessageCode == 94  \* 0x5e

Payload ==
    [ tag : {LastQuoteMessageCode}, body : LastQuoteMessage ]
        \cup [ tag : {BenchmarkTradeMessageCode}, body : BenchmarkTradeMessage ]
        \cup [ tag : {PriceLeaderboardMessageCode}, body : PriceLeaderboardMessage ]
        \cup [ tag : {TradingSniperMessageCode}, body : TradingSniperMessage ]
        \cup [ tag : {DepthAtBestPricesMessageCode}, body : DepthAtBestPricesMessage ]

EncodePayload(message) ==
    CASE message.tag = LastQuoteMessageCode -> EncodeLastQuoteMessage(message.body)
      [] message.tag = BenchmarkTradeMessageCode -> EncodeBenchmarkTradeMessage(message.body)
      [] message.tag = PriceLeaderboardMessageCode -> EncodePriceLeaderboardMessage(message.body)
      [] message.tag = TradingSniperMessageCode -> EncodeTradingSniperMessage(message.body)
      [] message.tag = DepthAtBestPricesMessageCode -> EncodeDepthAtBestPricesMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LastQuoteMessageCode -> DecodeLastQuoteMessage(bytes)
              [] tag = BenchmarkTradeMessageCode -> DecodeBenchmarkTradeMessage(bytes)
              [] tag = PriceLeaderboardMessageCode -> DecodePriceLeaderboardMessage(bytes)
              [] tag = TradingSniperMessageCode -> DecodeTradingSniperMessage(bytes)
              [] tag = DepthAtBestPricesMessageCode -> DecodeDepthAtBestPricesMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LastQuoteMessageCode, body |-> ZeroLastQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LastQuoteMessageCode, body |-> one] : one \in CheckedLastQuoteMessage }
        \cup { [tag |-> BenchmarkTradeMessageCode, body |-> one] : one \in CheckedBenchmarkTradeMessage }
        \cup { [tag |-> PriceLeaderboardMessageCode, body |-> one] : one \in CheckedPriceLeaderboardMessage }
        \cup { [tag |-> TradingSniperMessageCode, body |-> one] : one \in CheckedTradingSniperMessage }
        \cup { [tag |-> DepthAtBestPricesMessageCode, body |-> one] : one \in CheckedDepthAtBestPricesMessage }

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
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> LastQuoteMessageCode, body |-> ZeroLastQuoteMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> BenchmarkTradeMessageCode, body |-> ZeroBenchmarkTradeMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> PriceLeaderboardMessageCode, body |-> ZeroPriceLeaderboardMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> TradingSniperMessageCode, body |-> ZeroTradingSniperMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DepthAtBestPricesMessageCode, body |-> ZeroDepthAtBestPricesMessage]] }

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

(* Every Last Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastQuoteMessage ==
    \A message \in CheckedLastQuoteMessage :
        LET read == DecodeLastQuoteMessage(EncodeLastQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Benchmark Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBenchmarkTradeMessage ==
    \A message \in CheckedBenchmarkTradeMessage :
        LET read == DecodeBenchmarkTradeMessage(EncodeBenchmarkTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Leaderboard Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLeaderboardMessage ==
    \A message \in CheckedPriceLeaderboardMessage :
        LET read == DecodePriceLeaderboardMessage(EncodePriceLeaderboardMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Sniper Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSniperMessage ==
    \A message \in CheckedTradingSniperMessage :
        LET read == DecodeTradingSniperMessage(EncodeTradingSniperMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth At Best Prices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthAtBestPricesMessage ==
    \A message \in CheckedDepthAtBestPricesMessage :
        LET read == DecodeDepthAtBestPricesMessage(EncodeDepthAtBestPricesMessage(message))
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
