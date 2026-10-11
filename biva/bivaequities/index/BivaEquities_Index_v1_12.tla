--------------------- MODULE BivaEquities_Index_v1_12 ----------------------
(***************************************************************************)
(* Bolsa Institucional de Valores Index v1.12                              *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
(* Time Stamp Seconds Message: 4 bytes                                     *)
(***************************************************************************)

TimeStampSecondsMessage ==
    [ second : Sample(4) ]

EncodeTimeStampSecondsMessage(message) ==
    message.second

DecodeTimeStampSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimeStampSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Time Stamp Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeStampSecondsMessage ==
    { ZeroTimeStampSecondsMessage }
        \cup { [ZeroTimeStampSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 17 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      group       : Sample(8),
      eventCode   : Sample(1),
      orderbook   : Sample(4) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.group
        \o message.eventCode
        \o message.orderbook

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET group == ReadBytes(nanoseconds.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET eventCode == ReadBytes(group.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET orderbook == ReadBytes(eventCode.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         group       |-> group.value,
         eventCode   |-> eventCode.value,
         orderbook   |-> orderbook.value ], orderbook.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      group       |-> [i \in 1 .. 8 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      orderbook   |-> [i \in 1 .. 4 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.orderbook = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Tick Size Message: 16 bytes                                       *)
(***************************************************************************)

PriceTickSizeMessage ==
    [ nanoseconds     : Sample(4),
      tickSizeTableId : Sample(4),
      priceTickSize   : Sample(4),
      priceStart      : Sample(4) ]

EncodePriceTickSizeMessage(message) ==
    message.nanoseconds
        \o message.tickSizeTableId
        \o message.priceTickSize
        \o message.priceStart

DecodePriceTickSizeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tickSizeTableId == ReadBytes(nanoseconds.rest, 4) IN IF ~tickSizeTableId.ok THEN Fail ELSE
    LET priceTickSize == ReadBytes(tickSizeTableId.rest, 4) IN IF ~priceTickSize.ok THEN Fail ELSE
    LET priceStart == ReadBytes(priceTickSize.rest, 4) IN IF ~priceStart.ok THEN Fail ELSE
    Ok([ nanoseconds     |-> nanoseconds.value,
         tickSizeTableId |-> tickSizeTableId.value,
         priceTickSize   |-> priceTickSize.value,
         priceStart      |-> priceStart.value ], priceStart.rest)

ZeroPriceTickSizeMessage ==
    [ nanoseconds     |-> [i \in 1 .. 4 |-> 0],
      tickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      priceTickSize   |-> [i \in 1 .. 4 |-> 0],
      priceStart      |-> [i \in 1 .. 4 |-> 0] ]

(* Price Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceTickSizeMessage ==
    { ZeroPriceTickSizeMessage }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.tickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceTickSize = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceStart = one] : one \in Sample(4) }

(***************************************************************************)
(* Quantity Tick Size Message: 24 bytes                                    *)
(***************************************************************************)

QuantityTickSizeMessage ==
    [ nanoseconds      : Sample(4),
      tickSizeTableId  : Sample(4),
      quantityTickSize : Sample(8),
      quantityStart    : Sample(8) ]

EncodeQuantityTickSizeMessage(message) ==
    message.nanoseconds
        \o message.tickSizeTableId
        \o message.quantityTickSize
        \o message.quantityStart

DecodeQuantityTickSizeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tickSizeTableId == ReadBytes(nanoseconds.rest, 4) IN IF ~tickSizeTableId.ok THEN Fail ELSE
    LET quantityTickSize == ReadBytes(tickSizeTableId.rest, 8) IN IF ~quantityTickSize.ok THEN Fail ELSE
    LET quantityStart == ReadBytes(quantityTickSize.rest, 8) IN IF ~quantityStart.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         tickSizeTableId  |-> tickSizeTableId.value,
         quantityTickSize |-> quantityTickSize.value,
         quantityStart    |-> quantityStart.value ], quantityStart.rest)

ZeroQuantityTickSizeMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      tickSizeTableId  |-> [i \in 1 .. 4 |-> 0],
      quantityTickSize |-> [i \in 1 .. 8 |-> 0],
      quantityStart    |-> [i \in 1 .. 8 |-> 0] ]

(* Quantity Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedQuantityTickSizeMessage ==
    { ZeroQuantityTickSizeMessage }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.tickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.quantityTickSize = one] : one \in Sample(8) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.quantityStart = one] : one \in Sample(8) }

(***************************************************************************)
(* Orderbook Directory Message: 99 bytes                                   *)
(***************************************************************************)

OrderbookDirectoryMessage ==
    [ nanoseconds             : Sample(4),
      orderbook               : Sample(4),
      isin                    : Sample(12),
      secCode                 : Sample(15),
      currency                : Sample(3),
      group                   : Sample(8),
      minimumQuantity         : Sample(8),
      quantityTickSizeTableId : Sample(4),
      quantityDecimals        : Sample(4),
      priceTickSizeTableId    : Sample(4),
      priceDecimals           : Sample(4),
      delistingOrMaturityDate : Sample(4),
      delistingTime           : Sample(4),
      turnoverRatio           : Sample(1),
      quotationBasis          : Sample(3),
      instrument              : Sample(12),
      listingType             : Sample(1),
      listingExchange         : Sample(4) ]

EncodeOrderbookDirectoryMessage(message) ==
    message.nanoseconds
        \o message.orderbook
        \o message.isin
        \o message.secCode
        \o message.currency
        \o message.group
        \o message.minimumQuantity
        \o message.quantityTickSizeTableId
        \o message.quantityDecimals
        \o message.priceTickSizeTableId
        \o message.priceDecimals
        \o message.delistingOrMaturityDate
        \o message.delistingTime
        \o message.turnoverRatio
        \o message.quotationBasis
        \o message.instrument
        \o message.listingType
        \o message.listingExchange

DecodeOrderbookDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbook == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET isin == ReadBytes(orderbook.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET secCode == ReadBytes(isin.rest, 15) IN IF ~secCode.ok THEN Fail ELSE
    LET currency == ReadBytes(secCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET group == ReadBytes(currency.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(group.rest, 8) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET quantityTickSizeTableId == ReadBytes(minimumQuantity.rest, 4) IN IF ~quantityTickSizeTableId.ok THEN Fail ELSE
    LET quantityDecimals == ReadBytes(quantityTickSizeTableId.rest, 4) IN IF ~quantityDecimals.ok THEN Fail ELSE
    LET priceTickSizeTableId == ReadBytes(quantityDecimals.rest, 4) IN IF ~priceTickSizeTableId.ok THEN Fail ELSE
    LET priceDecimals == ReadBytes(priceTickSizeTableId.rest, 4) IN IF ~priceDecimals.ok THEN Fail ELSE
    LET delistingOrMaturityDate == ReadBytes(priceDecimals.rest, 4) IN IF ~delistingOrMaturityDate.ok THEN Fail ELSE
    LET delistingTime == ReadBytes(delistingOrMaturityDate.rest, 4) IN IF ~delistingTime.ok THEN Fail ELSE
    LET turnoverRatio == ReadBytes(delistingTime.rest, 1) IN IF ~turnoverRatio.ok THEN Fail ELSE
    LET quotationBasis == ReadBytes(turnoverRatio.rest, 3) IN IF ~quotationBasis.ok THEN Fail ELSE
    LET instrument == ReadBytes(quotationBasis.rest, 12) IN IF ~instrument.ok THEN Fail ELSE
    LET listingType == ReadBytes(instrument.rest, 1) IN IF ~listingType.ok THEN Fail ELSE
    LET listingExchange == ReadBytes(listingType.rest, 4) IN IF ~listingExchange.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         orderbook               |-> orderbook.value,
         isin                    |-> isin.value,
         secCode                 |-> secCode.value,
         currency                |-> currency.value,
         group                   |-> group.value,
         minimumQuantity         |-> minimumQuantity.value,
         quantityTickSizeTableId |-> quantityTickSizeTableId.value,
         quantityDecimals        |-> quantityDecimals.value,
         priceTickSizeTableId    |-> priceTickSizeTableId.value,
         priceDecimals           |-> priceDecimals.value,
         delistingOrMaturityDate |-> delistingOrMaturityDate.value,
         delistingTime           |-> delistingTime.value,
         turnoverRatio           |-> turnoverRatio.value,
         quotationBasis          |-> quotationBasis.value,
         instrument              |-> instrument.value,
         listingType             |-> listingType.value,
         listingExchange         |-> listingExchange.value ], listingExchange.rest)

ZeroOrderbookDirectoryMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      orderbook               |-> [i \in 1 .. 4 |-> 0],
      isin                    |-> [i \in 1 .. 12 |-> 0],
      secCode                 |-> [i \in 1 .. 15 |-> 0],
      currency                |-> [i \in 1 .. 3 |-> 0],
      group                   |-> [i \in 1 .. 8 |-> 0],
      minimumQuantity         |-> [i \in 1 .. 8 |-> 0],
      quantityTickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      quantityDecimals        |-> [i \in 1 .. 4 |-> 0],
      priceTickSizeTableId    |-> [i \in 1 .. 4 |-> 0],
      priceDecimals           |-> [i \in 1 .. 4 |-> 0],
      delistingOrMaturityDate |-> [i \in 1 .. 4 |-> 0],
      delistingTime           |-> [i \in 1 .. 4 |-> 0],
      turnoverRatio           |-> [i \in 1 .. 1 |-> 0],
      quotationBasis          |-> [i \in 1 .. 3 |-> 0],
      instrument              |-> [i \in 1 .. 12 |-> 0],
      listingType             |-> [i \in 1 .. 1 |-> 0],
      listingExchange         |-> [i \in 1 .. 4 |-> 0] ]

(* Orderbook Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookDirectoryMessage ==
    { ZeroOrderbookDirectoryMessage }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.secCode = one] : one \in Sample(15) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.minimumQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quantityTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quantityDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.delistingOrMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.delistingTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.turnoverRatio = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quotationBasis = one] : one \in Sample(3) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.listingType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.listingExchange = one] : one \in Sample(4) }

(***************************************************************************)
(* Orderbook Trading Action Message: 10 bytes                              *)
(***************************************************************************)

OrderbookTradingActionMessage ==
    [ nanoseconds         : Sample(4),
      orderbook           : Sample(4),
      tradingState        : Sample(1),
      tradingActionReason : Sample(1) ]

EncodeOrderbookTradingActionMessage(message) ==
    message.nanoseconds
        \o message.orderbook
        \o message.tradingState
        \o message.tradingActionReason

DecodeOrderbookTradingActionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbook == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET tradingState == ReadBytes(orderbook.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET tradingActionReason == ReadBytes(tradingState.rest, 1) IN IF ~tradingActionReason.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         orderbook           |-> orderbook.value,
         tradingState        |-> tradingState.value,
         tradingActionReason |-> tradingActionReason.value ], tradingActionReason.rest)

ZeroOrderbookTradingActionMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      orderbook           |-> [i \in 1 .. 4 |-> 0],
      tradingState        |-> [i \in 1 .. 1 |-> 0],
      tradingActionReason |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookTradingActionMessage ==
    { ZeroOrderbookTradingActionMessage }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.tradingActionReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Orderbook Reference Price Message: 14 bytes                             *)
(***************************************************************************)

OrderbookReferencePriceMessage ==
    [ nanoseconds          : Sample(4),
      orderbook            : Sample(4),
      referencePrice       : Sample(4),
      priceType            : Sample(1),
      referencePriceReason : Sample(1) ]

EncodeOrderbookReferencePriceMessage(message) ==
    message.nanoseconds
        \o message.orderbook
        \o message.referencePrice
        \o message.priceType
        \o message.referencePriceReason

DecodeOrderbookReferencePriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbook == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(orderbook.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET priceType == ReadBytes(referencePrice.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET referencePriceReason == ReadBytes(priceType.rest, 1) IN IF ~referencePriceReason.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderbook            |-> orderbook.value,
         referencePrice       |-> referencePrice.value,
         priceType            |-> priceType.value,
         referencePriceReason |-> referencePriceReason.value ], referencePriceReason.rest)

ZeroOrderbookReferencePriceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderbook            |-> [i \in 1 .. 4 |-> 0],
      referencePrice       |-> [i \in 1 .. 4 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      referencePriceReason |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookReferencePriceMessage ==
    { ZeroOrderbookReferencePriceMessage }
        \cup { [ZeroOrderbookReferencePriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookReferencePriceMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookReferencePriceMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookReferencePriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookReferencePriceMessage EXCEPT !.referencePriceReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeStampSecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
PriceTickSizeMessageCode == 76  \* "L"
QuantityTickSizeMessageCode == 77  \* "M"
OrderbookDirectoryMessageCode == 82  \* "R"
OrderbookTradingActionMessageCode == 72  \* "H"
OrderbookReferencePriceMessageCode == 88  \* "X"

Payload ==
    [ tag : {TimeStampSecondsMessageCode}, body : TimeStampSecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {PriceTickSizeMessageCode}, body : PriceTickSizeMessage ]
        \cup [ tag : {QuantityTickSizeMessageCode}, body : QuantityTickSizeMessage ]
        \cup [ tag : {OrderbookDirectoryMessageCode}, body : OrderbookDirectoryMessage ]
        \cup [ tag : {OrderbookTradingActionMessageCode}, body : OrderbookTradingActionMessage ]
        \cup [ tag : {OrderbookReferencePriceMessageCode}, body : OrderbookReferencePriceMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeStampSecondsMessageCode -> EncodeTimeStampSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = PriceTickSizeMessageCode -> EncodePriceTickSizeMessage(message.body)
      [] message.tag = QuantityTickSizeMessageCode -> EncodeQuantityTickSizeMessage(message.body)
      [] message.tag = OrderbookDirectoryMessageCode -> EncodeOrderbookDirectoryMessage(message.body)
      [] message.tag = OrderbookTradingActionMessageCode -> EncodeOrderbookTradingActionMessage(message.body)
      [] message.tag = OrderbookReferencePriceMessageCode -> EncodeOrderbookReferencePriceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeStampSecondsMessageCode -> DecodeTimeStampSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = PriceTickSizeMessageCode -> DecodePriceTickSizeMessage(bytes)
              [] tag = QuantityTickSizeMessageCode -> DecodeQuantityTickSizeMessage(bytes)
              [] tag = OrderbookDirectoryMessageCode -> DecodeOrderbookDirectoryMessage(bytes)
              [] tag = OrderbookTradingActionMessageCode -> DecodeOrderbookTradingActionMessage(bytes)
              [] tag = OrderbookReferencePriceMessageCode -> DecodeOrderbookReferencePriceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeStampSecondsMessageCode, body |-> ZeroTimeStampSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeStampSecondsMessageCode, body |-> one] : one \in CheckedTimeStampSecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> PriceTickSizeMessageCode, body |-> one] : one \in CheckedPriceTickSizeMessage }
        \cup { [tag |-> QuantityTickSizeMessageCode, body |-> one] : one \in CheckedQuantityTickSizeMessage }
        \cup { [tag |-> OrderbookDirectoryMessageCode, body |-> one] : one \in CheckedOrderbookDirectoryMessage }
        \cup { [tag |-> OrderbookTradingActionMessageCode, body |-> one] : one \in CheckedOrderbookTradingActionMessage }
        \cup { [tag |-> OrderbookReferencePriceMessageCode, body |-> one] : one \in CheckedOrderbookReferencePriceMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeStampSecondsMessageCode, body |-> ZeroTimeStampSecondsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceTickSizeMessageCode, body |-> ZeroPriceTickSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuantityTickSizeMessageCode, body |-> ZeroQuantityTickSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderbookDirectoryMessageCode, body |-> ZeroOrderbookDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderbookTradingActionMessageCode, body |-> ZeroOrderbookTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderbookReferencePriceMessageCode, body |-> ZeroOrderbookReferencePriceMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Time Stamp Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeStampSecondsMessage ==
    \A message \in CheckedTimeStampSecondsMessage :
        LET read == DecodeTimeStampSecondsMessage(EncodeTimeStampSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceTickSizeMessage ==
    \A message \in CheckedPriceTickSizeMessage :
        LET read == DecodePriceTickSizeMessage(EncodePriceTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantityTickSizeMessage ==
    \A message \in CheckedQuantityTickSizeMessage :
        LET read == DecodeQuantityTickSizeMessage(EncodeQuantityTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookDirectoryMessage ==
    \A message \in CheckedOrderbookDirectoryMessage :
        LET read == DecodeOrderbookDirectoryMessage(EncodeOrderbookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookTradingActionMessage ==
    \A message \in CheckedOrderbookTradingActionMessage :
        LET read == DecodeOrderbookTradingActionMessage(EncodeOrderbookTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Reference Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookReferencePriceMessage ==
    \A message \in CheckedOrderbookReferencePriceMessage :
        LET read == DecodeOrderbookReferencePriceMessage(EncodeOrderbookReferencePriceMessage(message))
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
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
