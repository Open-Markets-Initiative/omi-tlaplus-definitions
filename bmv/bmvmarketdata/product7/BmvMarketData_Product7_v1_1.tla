-------------------- MODULE BmvMarketData_Product7_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 7 v1.1                *)
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
(* Trade Cancellation Message: 8 bytes                                     *)
(***************************************************************************)

TradeCancellationMessage ==
    [ instrumentNumber : Sample(4),
      tradeNumber      : Sample(4) ]

EncodeTradeCancellationMessage(message) ==
    message.instrumentNumber
        \o message.tradeNumber

DecodeTradeCancellationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(instrumentNumber.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         tradeNumber      |-> tradeNumber.value ], tradeNumber.rest)

ZeroTradeCancellationMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      tradeNumber      |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationMessage ==
    { ZeroTradeCancellationMessage }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Status Changes Message: 5 bytes                                         *)
(***************************************************************************)

StatusChangesMessage ==
    [ instrumentNumber : Sample(4),
      instrumentStatus : Sample(1) ]

EncodeStatusChangesMessage(message) ==
    message.instrumentNumber
        \o message.instrumentStatus

DecodeStatusChangesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET instrumentStatus == ReadBytes(instrumentNumber.rest, 1) IN IF ~instrumentStatus.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         instrumentStatus |-> instrumentStatus.value ], instrumentStatus.rest)

ZeroStatusChangesMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      instrumentStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Status Changes Message at zero, then each field in turn at the values it is checked at *)
CheckedStatusChangesMessage ==
    { ZeroStatusChangesMessage }
        \cup { [ZeroStatusChangesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroStatusChangesMessage EXCEPT !.instrumentStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Weighted Average Price Settlement Prices Message: 20 bytes              *)
(***************************************************************************)

WeightedAveragePriceSettlementPricesMessage ==
    [ instrumentNumber     : Sample(4),
      weightedAveragePrice : Sample(8),
      volatility           : Sample(8) ]

EncodeWeightedAveragePriceSettlementPricesMessage(message) ==
    message.instrumentNumber
        \o message.weightedAveragePrice
        \o message.volatility

DecodeWeightedAveragePriceSettlementPricesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET weightedAveragePrice == ReadBytes(instrumentNumber.rest, 8) IN IF ~weightedAveragePrice.ok THEN Fail ELSE
    LET volatility == ReadBytes(weightedAveragePrice.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    Ok([ instrumentNumber     |-> instrumentNumber.value,
         weightedAveragePrice |-> weightedAveragePrice.value,
         volatility           |-> volatility.value ], volatility.rest)

ZeroWeightedAveragePriceSettlementPricesMessage ==
    [ instrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      weightedAveragePrice |-> [i \in 1 .. 8 |-> 0],
      volatility           |-> [i \in 1 .. 8 |-> 0] ]

(* Weighted Average Price Settlement Prices Message at zero, then each field in turn at the values it is checked at *)
CheckedWeightedAveragePriceSettlementPricesMessage ==
    { ZeroWeightedAveragePriceSettlementPricesMessage }
        \cup { [ZeroWeightedAveragePriceSettlementPricesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroWeightedAveragePriceSettlementPricesMessage EXCEPT !.weightedAveragePrice = one] : one \in Sample(8) }
        \cup { [ZeroWeightedAveragePriceSettlementPricesMessage EXCEPT !.volatility = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Level: 14 bytes                                                   *)
(***************************************************************************)

PriceLevel ==
    [ price          : Sample(8),
      numberOfOrders : Sample(2),
      volume         : Sample(4) ]

EncodePriceLevel(message) ==
    message.price
        \o message.numberOfOrders
        \o message.volume

DecodePriceLevel(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(price.rest, 2) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET volume == ReadBytes(numberOfOrders.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ price          |-> price.value,
         numberOfOrders |-> numberOfOrders.value,
         volume         |-> volume.value ], volume.rest)

ZeroPriceLevel ==
    [ price          |-> [i \in 1 .. 8 |-> 0],
      numberOfOrders |-> [i \in 1 .. 2 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0] ]

(* Price Level at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevel ==
    { ZeroPriceLevel }
        \cup { [ZeroPriceLevel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel EXCEPT !.numberOfOrders = one] : one \in Sample(2) }
        \cup { [ZeroPriceLevel EXCEPT !.volume = one] : one \in Sample(4) }

(* A run of Price Level, written one after another *)
RECURSIVE EncodePriceLevelList(_)
EncodePriceLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePriceLevel(Head(messages)) \o EncodePriceLevelList(Tail(messages))

(* As many Price Level as the field that counts them says *)
RECURSIVE ReadPriceLevelList(_, _)
ReadPriceLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePriceLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPriceLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Price Level of each kind, for the lists that carry them *)
OnePriceLevel == { ZeroPriceLevel }

(***************************************************************************)
(* Depth Message                                                           *)
(***************************************************************************)

DepthMessage ==
    [ instrumentNumber : Sample(4),
      side             : Sample(1),
      priceLevel       : SampleLists(OnePriceLevel) ]

EncodeDepthMessage(message) ==
    message.instrumentNumber
        \o message.side
        \o EncodeUIntBE(Len(message.priceLevel), 1)
        \o EncodePriceLevelList(message.priceLevel)

DecodeDepthMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET purchaseOrSaleLevels == ReadUIntBE(side.rest, 1) IN IF ~purchaseOrSaleLevels.ok THEN Fail ELSE
    LET priceLevel == ReadPriceLevelList(purchaseOrSaleLevels.rest, purchaseOrSaleLevels.value) IN IF ~priceLevel.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         side             |-> side.value,
         priceLevel       |-> priceLevel.value ], priceLevel.rest)

ZeroDepthMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      priceLevel       |-> << >> ]

(* Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedDepthMessage ==
    { ZeroDepthMessage }
        \cup { [ZeroDepthMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroDepthMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDepthMessage EXCEPT !.priceLevel = one] : one \in SampleLists(OnePriceLevel) }

(***************************************************************************)
(* Open Interest Message: 8 bytes                                          *)
(***************************************************************************)

OpenInterestMessage ==
    [ instrumentNumber : Sample(4),
      openInterest     : Sample(4) ]

EncodeOpenInterestMessage(message) ==
    message.instrumentNumber
        \o message.openInterest

DecodeOpenInterestMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET openInterest == ReadBytes(instrumentNumber.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         openInterest     |-> openInterest.value ], openInterest.rest)

ZeroOpenInterestMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      openInterest     |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(4) }

(***************************************************************************)
(* Derivatives Market Trades Message: 43 bytes                             *)
(***************************************************************************)

DerivativesMarketTradesMessage ==
    [ instrumentNumber  : Sample(4),
      tradeTime         : Sample(8),
      volume            : Sample(4),
      priceRate         : Sample(8),
      concertationType  : Sample(1),
      tradeNumber       : Sample(4),
      operationType     : Sample(1),
      amount            : Sample(8),
      parentTradeNumber : Sample(4),
      legType           : Sample(1) ]

EncodeDerivativesMarketTradesMessage(message) ==
    message.instrumentNumber
        \o message.tradeTime
        \o message.volume
        \o message.priceRate
        \o message.concertationType
        \o message.tradeNumber
        \o message.operationType
        \o message.amount
        \o message.parentTradeNumber
        \o message.legType

DecodeDerivativesMarketTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(instrumentNumber.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET volume == ReadBytes(tradeTime.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET priceRate == ReadBytes(volume.rest, 8) IN IF ~priceRate.ok THEN Fail ELSE
    LET concertationType == ReadBytes(priceRate.rest, 1) IN IF ~concertationType.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(concertationType.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET operationType == ReadBytes(tradeNumber.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET amount == ReadBytes(operationType.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    LET parentTradeNumber == ReadBytes(amount.rest, 4) IN IF ~parentTradeNumber.ok THEN Fail ELSE
    LET legType == ReadBytes(parentTradeNumber.rest, 1) IN IF ~legType.ok THEN Fail ELSE
    Ok([ instrumentNumber  |-> instrumentNumber.value,
         tradeTime         |-> tradeTime.value,
         volume            |-> volume.value,
         priceRate         |-> priceRate.value,
         concertationType  |-> concertationType.value,
         tradeNumber       |-> tradeNumber.value,
         operationType     |-> operationType.value,
         amount            |-> amount.value,
         parentTradeNumber |-> parentTradeNumber.value,
         legType           |-> legType.value ], legType.rest)

ZeroDerivativesMarketTradesMessage ==
    [ instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      tradeTime         |-> [i \in 1 .. 8 |-> 0],
      volume            |-> [i \in 1 .. 4 |-> 0],
      priceRate         |-> [i \in 1 .. 8 |-> 0],
      concertationType  |-> [i \in 1 .. 1 |-> 0],
      tradeNumber       |-> [i \in 1 .. 4 |-> 0],
      operationType     |-> [i \in 1 .. 1 |-> 0],
      amount            |-> [i \in 1 .. 8 |-> 0],
      parentTradeNumber |-> [i \in 1 .. 4 |-> 0],
      legType           |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Market Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesMarketTradesMessage ==
    { ZeroDerivativesMarketTradesMessage }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.priceRate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.concertationType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.amount = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.parentTradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.legType = one] : one \in Sample(1) }

(***************************************************************************)
(* Statistics Of Instruments Message: 44 bytes                             *)
(***************************************************************************)

StatisticsOfInstrumentsMessage ==
    [ instrumentNumber        : Sample(4),
      previousSettlementPrice : Sample(8),
      openingPrice            : Sample(8),
      maxPriceOfTheDay        : Sample(8),
      lowerPriceOfTheDay      : Sample(8),
      lastPriceOfTheDay       : Sample(8) ]

EncodeStatisticsOfInstrumentsMessage(message) ==
    message.instrumentNumber
        \o message.previousSettlementPrice
        \o message.openingPrice
        \o message.maxPriceOfTheDay
        \o message.lowerPriceOfTheDay
        \o message.lastPriceOfTheDay

DecodeStatisticsOfInstrumentsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(instrumentNumber.rest, 8) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(previousSettlementPrice.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPriceOfTheDay == ReadBytes(openingPrice.rest, 8) IN IF ~maxPriceOfTheDay.ok THEN Fail ELSE
    LET lowerPriceOfTheDay == ReadBytes(maxPriceOfTheDay.rest, 8) IN IF ~lowerPriceOfTheDay.ok THEN Fail ELSE
    LET lastPriceOfTheDay == ReadBytes(lowerPriceOfTheDay.rest, 8) IN IF ~lastPriceOfTheDay.ok THEN Fail ELSE
    Ok([ instrumentNumber        |-> instrumentNumber.value,
         previousSettlementPrice |-> previousSettlementPrice.value,
         openingPrice            |-> openingPrice.value,
         maxPriceOfTheDay        |-> maxPriceOfTheDay.value,
         lowerPriceOfTheDay      |-> lowerPriceOfTheDay.value,
         lastPriceOfTheDay       |-> lastPriceOfTheDay.value ], lastPriceOfTheDay.rest)

ZeroStatisticsOfInstrumentsMessage ==
    [ instrumentNumber        |-> [i \in 1 .. 4 |-> 0],
      previousSettlementPrice |-> [i \in 1 .. 8 |-> 0],
      openingPrice            |-> [i \in 1 .. 8 |-> 0],
      maxPriceOfTheDay        |-> [i \in 1 .. 8 |-> 0],
      lowerPriceOfTheDay      |-> [i \in 1 .. 8 |-> 0],
      lastPriceOfTheDay       |-> [i \in 1 .. 8 |-> 0] ]

(* Statistics Of Instruments Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsOfInstrumentsMessage ==
    { ZeroStatisticsOfInstrumentsMessage }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.maxPriceOfTheDay = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.lowerPriceOfTheDay = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.lastPriceOfTheDay = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

EventsSystemMessageCode == 83  \* 0x53
TradeCancellationMessageCode == 72  \* 0x48
StatusChangesMessageCode == 52  \* 0x34
WeightedAveragePriceSettlementPricesMessageCode == 77  \* 0x4d
DepthMessageCode == 49  \* 0x31
OpenInterestMessageCode == 73  \* 0x49
DerivativesMarketTradesMessageCode == 81  \* 0x51
StatisticsOfInstrumentsMessageCode == 82  \* 0x52

Payload ==
    [ tag : {EventsSystemMessageCode}, body : EventsSystemMessage ]
        \cup [ tag : {TradeCancellationMessageCode}, body : TradeCancellationMessage ]
        \cup [ tag : {StatusChangesMessageCode}, body : StatusChangesMessage ]
        \cup [ tag : {WeightedAveragePriceSettlementPricesMessageCode}, body : WeightedAveragePriceSettlementPricesMessage ]
        \cup [ tag : {DepthMessageCode}, body : DepthMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {DerivativesMarketTradesMessageCode}, body : DerivativesMarketTradesMessage ]
        \cup [ tag : {StatisticsOfInstrumentsMessageCode}, body : StatisticsOfInstrumentsMessage ]

EncodePayload(message) ==
    CASE message.tag = EventsSystemMessageCode -> EncodeEventsSystemMessage(message.body)
      [] message.tag = TradeCancellationMessageCode -> EncodeTradeCancellationMessage(message.body)
      [] message.tag = StatusChangesMessageCode -> EncodeStatusChangesMessage(message.body)
      [] message.tag = WeightedAveragePriceSettlementPricesMessageCode -> EncodeWeightedAveragePriceSettlementPricesMessage(message.body)
      [] message.tag = DepthMessageCode -> EncodeDepthMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = DerivativesMarketTradesMessageCode -> EncodeDerivativesMarketTradesMessage(message.body)
      [] message.tag = StatisticsOfInstrumentsMessageCode -> EncodeStatisticsOfInstrumentsMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = EventsSystemMessageCode -> DecodeEventsSystemMessage(bytes)
              [] tag = TradeCancellationMessageCode -> DecodeTradeCancellationMessage(bytes)
              [] tag = StatusChangesMessageCode -> DecodeStatusChangesMessage(bytes)
              [] tag = WeightedAveragePriceSettlementPricesMessageCode -> DecodeWeightedAveragePriceSettlementPricesMessage(bytes)
              [] tag = DepthMessageCode -> DecodeDepthMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = DerivativesMarketTradesMessageCode -> DecodeDerivativesMarketTradesMessage(bytes)
              [] tag = StatisticsOfInstrumentsMessageCode -> DecodeStatisticsOfInstrumentsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> EventsSystemMessageCode, body |-> one] : one \in CheckedEventsSystemMessage }
        \cup { [tag |-> TradeCancellationMessageCode, body |-> one] : one \in CheckedTradeCancellationMessage }
        \cup { [tag |-> StatusChangesMessageCode, body |-> one] : one \in CheckedStatusChangesMessage }
        \cup { [tag |-> WeightedAveragePriceSettlementPricesMessageCode, body |-> one] : one \in CheckedWeightedAveragePriceSettlementPricesMessage }
        \cup { [tag |-> DepthMessageCode, body |-> one] : one \in CheckedDepthMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> DerivativesMarketTradesMessageCode, body |-> one] : one \in CheckedDerivativesMarketTradesMessage }
        \cup { [tag |-> StatisticsOfInstrumentsMessageCode, body |-> one] : one \in CheckedStatisticsOfInstrumentsMessage }

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
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> TradeCancellationMessageCode, body |-> ZeroTradeCancellationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> StatusChangesMessageCode, body |-> ZeroStatusChangesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> WeightedAveragePriceSettlementPricesMessageCode, body |-> ZeroWeightedAveragePriceSettlementPricesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DepthMessageCode, body |-> ZeroDepthMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DerivativesMarketTradesMessageCode, body |-> ZeroDerivativesMarketTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> StatisticsOfInstrumentsMessageCode, body |-> ZeroStatisticsOfInstrumentsMessage]] }

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

(* Every Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancellationMessage ==
    \A message \in CheckedTradeCancellationMessage :
        LET read == DecodeTradeCancellationMessage(EncodeTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Status Changes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatusChangesMessage ==
    \A message \in CheckedStatusChangesMessage :
        LET read == DecodeStatusChangesMessage(EncodeStatusChangesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Average Price Settlement Prices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedAveragePriceSettlementPricesMessage ==
    \A message \in CheckedWeightedAveragePriceSettlementPricesMessage :
        LET read == DecodeWeightedAveragePriceSettlementPricesMessage(EncodeWeightedAveragePriceSettlementPricesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevel ==
    \A message \in CheckedPriceLevel :
        LET read == DecodePriceLevel(EncodePriceLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthMessage ==
    \A message \in CheckedDepthMessage :
        LET read == DecodeDepthMessage(EncodeDepthMessage(message))
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

(* Every Derivatives Market Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesMarketTradesMessage ==
    \A message \in CheckedDerivativesMarketTradesMessage :
        LET read == DecodeDerivativesMarketTradesMessage(EncodeDerivativesMarketTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Of Instruments Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsOfInstrumentsMessage ==
    \A message \in CheckedStatisticsOfInstrumentsMessage :
        LET read == DecodeStatisticsOfInstrumentsMessage(EncodeStatisticsOfInstrumentsMessage(message))
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
