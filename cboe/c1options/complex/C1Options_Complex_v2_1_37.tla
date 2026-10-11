--------------------- MODULE C1Options_Complex_v2_1_37 ---------------------
(***************************************************************************)
(* Chicago Board Options Exchange Complex v2.1.37                          *)
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
(* Time Reference Message: 16 bytes                                        *)
(***************************************************************************)

TimeReferenceMessage ==
    [ midnightReference : Sample(4),
      timeReference     : Sample(4),
      timeOffset        : Sample(4),
      tradeDate         : Sample(4) ]

EncodeTimeReferenceMessage(message) ==
    message.midnightReference
        \o message.timeReference
        \o message.timeOffset
        \o message.tradeDate

DecodeTimeReferenceMessage(bytes) ==
    LET midnightReference == ReadBytes(bytes, 4) IN IF ~midnightReference.ok THEN Fail ELSE
    LET timeReference == ReadBytes(midnightReference.rest, 4) IN IF ~timeReference.ok THEN Fail ELSE
    LET timeOffset == ReadBytes(timeReference.rest, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timeOffset.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    Ok([ midnightReference |-> midnightReference.value,
         timeReference     |-> timeReference.value,
         timeOffset        |-> timeOffset.value,
         tradeDate         |-> tradeDate.value ], tradeDate.rest)

ZeroTimeReferenceMessage ==
    [ midnightReference |-> [i \in 1 .. 4 |-> 0],
      timeReference     |-> [i \in 1 .. 4 |-> 0],
      timeOffset        |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 4 |-> 0] ]

(* Time Reference Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeReferenceMessage ==
    { ZeroTimeReferenceMessage }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.midnightReference = one] : one \in Sample(4) }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.timeReference = one] : one \in Sample(4) }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Time Message: 8 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ time      : Sample(4),
      epochTime : Sample(4) ]

EncodeTimeMessage(message) ==
    message.time
        \o message.epochTime

DecodeTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET epochTime == ReadBytes(time.rest, 4) IN IF ~epochTime.ok THEN Fail ELSE
    Ok([ time      |-> time.value,
         epochTime |-> epochTime.value ], epochTime.rest)

ZeroTimeMessage ==
    [ time      |-> [i \in 1 .. 4 |-> 0],
      epochTime |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroTimeMessage EXCEPT !.epochTime = one] : one \in Sample(4) }

(***************************************************************************)
(* Unit Clear Message: 4 bytes                                             *)
(***************************************************************************)

UnitClearMessage ==
    [ timeOffset : Sample(4) ]

EncodeUnitClearMessage(message) ==
    message.timeOffset

DecodeUnitClearMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroUnitClearMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedUnitClearMessage ==
    { ZeroUnitClearMessage }
        \cup { [ZeroUnitClearMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Transaction Begin: 4 bytes                                              *)
(***************************************************************************)

TransactionBegin ==
    [ timeOffset : Sample(4) ]

EncodeTransactionBegin(message) ==
    message.timeOffset

DecodeTransactionBegin(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroTransactionBegin ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Transaction Begin at zero, then each field in turn at the values it is checked at *)
CheckedTransactionBegin ==
    { ZeroTransactionBegin }
        \cup { [ZeroTransactionBegin EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Transaction End Message: 4 bytes                                        *)
(***************************************************************************)

TransactionEndMessage ==
    [ timeOffset : Sample(4) ]

EncodeTransactionEndMessage(message) ==
    message.timeOffset

DecodeTransactionEndMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroTransactionEndMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Transaction End Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionEndMessage ==
    { ZeroTransactionEndMessage }
        \cup { [ZeroTransactionEndMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Instrument Leg: 13 bytes                                        *)
(***************************************************************************)

ComplexInstrumentLeg ==
    [ legSymbol       : Sample(8),
      legRatio        : Sample(4),
      legSecurityType : Sample(1) ]

EncodeComplexInstrumentLeg(message) ==
    message.legSymbol
        \o message.legRatio
        \o message.legSecurityType

DecodeComplexInstrumentLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbol.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatio.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ legSymbol       |-> legSymbol.value,
         legRatio        |-> legRatio.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroComplexInstrumentLeg ==
    [ legSymbol       |-> [i \in 1 .. 8 |-> 0],
      legRatio        |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentLeg ==
    { ZeroComplexInstrumentLeg }
        \cup { [ZeroComplexInstrumentLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentLeg EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Complex Instrument Leg, written one after another *)
RECURSIVE EncodeComplexInstrumentLegList(_)
EncodeComplexInstrumentLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexInstrumentLeg(Head(messages)) \o EncodeComplexInstrumentLegList(Tail(messages))

(* As many Complex Instrument Leg as the field that counts them says *)
RECURSIVE ReadComplexInstrumentLegList(_, _)
ReadComplexInstrumentLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexInstrumentLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexInstrumentLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Instrument Leg of each kind, for the lists that carry them *)
OneComplexInstrumentLeg == { ZeroComplexInstrumentLeg }

(***************************************************************************)
(* Complex Instrument Definition Expanded Message                          *)
(***************************************************************************)

ComplexInstrumentDefinitionExpandedMessage ==
    [ timeOffset                  : Sample(4),
      complexInstrumentId         : Sample(6),
      complexInstrumentUnderlying : Sample(8),
      complexInstrumentType       : Sample(4),
      complexInstrumentLeg        : SampleLists(OneComplexInstrumentLeg) ]

EncodeComplexInstrumentDefinitionExpandedMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId
        \o message.complexInstrumentUnderlying
        \o message.complexInstrumentType
        \o EncodeUIntLE(Len(message.complexInstrumentLeg), 1)
        \o EncodeComplexInstrumentLegList(message.complexInstrumentLeg)

DecodeComplexInstrumentDefinitionExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET complexInstrumentUnderlying == ReadBytes(complexInstrumentId.rest, 8) IN IF ~complexInstrumentUnderlying.ok THEN Fail ELSE
    LET complexInstrumentType == ReadBytes(complexInstrumentUnderlying.rest, 4) IN IF ~complexInstrumentType.ok THEN Fail ELSE
    LET legCount == ReadUIntLE(complexInstrumentType.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET complexInstrumentLeg == ReadComplexInstrumentLegList(legCount.rest, legCount.value) IN IF ~complexInstrumentLeg.ok THEN Fail ELSE
    Ok([ timeOffset                  |-> timeOffset.value,
         complexInstrumentId         |-> complexInstrumentId.value,
         complexInstrumentUnderlying |-> complexInstrumentUnderlying.value,
         complexInstrumentType       |-> complexInstrumentType.value,
         complexInstrumentLeg        |-> complexInstrumentLeg.value ], complexInstrumentLeg.rest)

ZeroComplexInstrumentDefinitionExpandedMessage ==
    [ timeOffset                  |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId         |-> [i \in 1 .. 6 |-> 0],
      complexInstrumentUnderlying |-> [i \in 1 .. 8 |-> 0],
      complexInstrumentType       |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentLeg        |-> << >> ]

(* Complex Instrument Definition Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionExpandedMessage ==
    { ZeroComplexInstrumentDefinitionExpandedMessage }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentUnderlying = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentType = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentLeg = one] : one \in SampleLists(OneComplexInstrumentLeg) }

(***************************************************************************)
(* Symbol Mapping Message: 36 bytes                                        *)
(***************************************************************************)

SymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1),
      underlying      : Sample(8) ]

EncodeSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition
        \o message.underlying

DecodeSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value,
         underlying      |-> underlying.value ], underlying.rest)

ZeroSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0],
      underlying      |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolMappingMessage ==
    { ZeroSymbolMappingMessage }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.underlying = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Long Message: 32 bytes                                        *)
(***************************************************************************)

AddOrderLongMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      sideIndicator       : Sample(1),
      quantity            : Sample(4),
      complexInstrumentId : Sample(6),
      price               : Sample(8),
      padding             : Sample(1) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.complexInstrumentId
        \o message.price
        \o message.padding

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(quantity.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(complexInstrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET padding == ReadBytes(price.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         sideIndicator       |-> sideIndicator.value,
         quantity            |-> quantity.value,
         complexInstrumentId |-> complexInstrumentId.value,
         price               |-> price.value,
         padding             |-> padding.value ], padding.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      padding             |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Message: 24 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      sideIndicator       : Sample(1),
      quantityShort       : Sample(2),
      complexInstrumentId : Sample(6),
      priceShort          : Sample(2),
      padding             : Sample(1) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.complexInstrumentId
        \o message.priceShort
        \o message.padding

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(quantityShort.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET priceShort == ReadBytes(complexInstrumentId.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET padding == ReadBytes(priceShort.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         sideIndicator       |-> sideIndicator.value,
         quantityShort       |-> quantityShort.value,
         complexInstrumentId |-> complexInstrumentId.value,
         priceShort          |-> priceShort.value,
         padding             |-> padding.value ], padding.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      quantityShort       |-> [i \in 1 .. 2 |-> 0],
      complexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      priceShort          |-> [i \in 1 .. 2 |-> 0],
      padding             |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Expanded Message: 43 bytes                                    *)
(***************************************************************************)

AddOrderExpandedMessage ==
    [ timeOffset           : Sample(4),
      orderId              : Sample(8),
      sideIndicator        : Sample(1),
      quantity             : Sample(4),
      complexInstrumentId8 : Sample(8),
      price                : Sample(8),
      reserved1            : Sample(1),
      participantId        : Sample(4),
      customerIndicator    : Sample(1),
      clientId             : Sample(4) ]

EncodeAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.complexInstrumentId8
        \o message.price
        \o message.reserved1
        \o message.participantId
        \o message.customerIndicator
        \o message.clientId

DecodeAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET complexInstrumentId8 == ReadBytes(quantity.rest, 8) IN IF ~complexInstrumentId8.ok THEN Fail ELSE
    LET price == ReadBytes(complexInstrumentId8.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(price.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET participantId == ReadBytes(reserved1.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(customerIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         orderId              |-> orderId.value,
         sideIndicator        |-> sideIndicator.value,
         quantity             |-> quantity.value,
         complexInstrumentId8 |-> complexInstrumentId8.value,
         price                |-> price.value,
         reserved1            |-> reserved1.value,
         participantId        |-> participantId.value,
         customerIndicator    |-> customerIndicator.value,
         clientId             |-> clientId.value ], clientId.rest)

ZeroAddOrderExpandedMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      sideIndicator        |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId8 |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      participantId        |-> [i \in 1 .. 4 |-> 0],
      customerIndicator    |-> [i \in 1 .. 1 |-> 0],
      clientId             |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExpandedMessage ==
    { ZeroAddOrderExpandedMessage }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.complexInstrumentId8 = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.clientId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 25 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      tradeCondition   : Sample(1) ]

EncodeOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o message.tradeCondition

DecodeOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value,
         tradeCondition   |-> tradeCondition.value ], tradeCondition.rest)

ZeroOrderExecutedMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      tradeCondition   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed At Price Size Message: 37 bytes                          *)
(***************************************************************************)

OrderExecutedAtPriceSizeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      price             : Sample(8),
      tradeCondition    : Sample(1) ]

EncodeOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.price
        \o message.tradeCondition

DecodeOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(price.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         price             |-> price.value,
         tradeCondition    |-> tradeCondition.value ], tradeCondition.rest)

ZeroOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      tradeCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceSizeMessage ==
    { ZeroOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Reduce Size Long Message: 16 bytes                                      *)
(***************************************************************************)

ReduceSizeLongMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      canceledQuantity : Sample(4) ]

EncodeReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantity

DecodeReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantity == ReadBytes(orderId.rest, 4) IN IF ~canceledQuantity.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         canceledQuantity |-> canceledQuantity.value ], canceledQuantity.rest)

ZeroReduceSizeLongMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      canceledQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeLongMessage ==
    { ZeroReduceSizeLongMessage }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.canceledQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Reduce Size Short Message: 14 bytes                                     *)
(***************************************************************************)

ReduceSizeShortMessage ==
    [ timeOffset            : Sample(4),
      orderId               : Sample(8),
      canceledQuantityShort : Sample(2) ]

EncodeReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityShort

DecodeReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityShort == ReadBytes(orderId.rest, 2) IN IF ~canceledQuantityShort.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         orderId               |-> orderId.value,
         canceledQuantityShort |-> canceledQuantityShort.value ], canceledQuantityShort.rest)

ZeroReduceSizeShortMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityShort |-> [i \in 1 .. 2 |-> 0] ]

(* Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeShortMessage ==
    { ZeroReduceSizeShortMessage }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.canceledQuantityShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Modify Order Long Message: 25 bytes                                     *)
(***************************************************************************)

ModifyOrderLongMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8),
      quantity   : Sample(4),
      price      : Sample(8),
      padding    : Sample(1) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.padding

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET padding == ReadBytes(price.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         padding    |-> padding.value ], padding.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      padding    |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Short Message: 17 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      quantityShort : Sample(2),
      priceShort    : Sample(2),
      padding       : Sample(1) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityShort
        \o message.priceShort
        \o message.padding

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(orderId.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantityShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET padding == ReadBytes(priceShort.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         quantityShort |-> quantityShort.value,
         priceShort    |-> priceShort.value,
         padding       |-> padding.value ], padding.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      padding       |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 12 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.timeOffset
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Long Message: 40 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      sideIndicator       : Sample(1),
      quantity            : Sample(4),
      complexInstrumentId : Sample(6),
      price               : Sample(8),
      executionId         : Sample(8),
      tradeCondition      : Sample(1) ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.complexInstrumentId
        \o message.price
        \o message.executionId
        \o message.tradeCondition

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(quantity.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(complexInstrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         sideIndicator       |-> sideIndicator.value,
         quantity            |-> quantity.value,
         complexInstrumentId |-> complexInstrumentId.value,
         price               |-> price.value,
         executionId         |-> executionId.value,
         tradeCondition      |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeLongMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      executionId         |-> [i \in 1 .. 8 |-> 0],
      tradeCondition      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 32 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      sideIndicator       : Sample(1),
      quantityShort       : Sample(2),
      complexInstrumentId : Sample(6),
      priceShort          : Sample(2),
      executionId         : Sample(8),
      tradeCondition      : Sample(1) ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.complexInstrumentId
        \o message.priceShort
        \o message.executionId
        \o message.tradeCondition

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(quantityShort.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET priceShort == ReadBytes(complexInstrumentId.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         sideIndicator       |-> sideIndicator.value,
         quantityShort       |-> quantityShort.value,
         complexInstrumentId |-> complexInstrumentId.value,
         priceShort          |-> priceShort.value,
         executionId         |-> executionId.value,
         tradeCondition      |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeShortMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      quantityShort       |-> [i \in 1 .. 2 |-> 0],
      complexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      priceShort          |-> [i \in 1 .. 2 |-> 0],
      executionId         |-> [i \in 1 .. 8 |-> 0],
      tradeCondition      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Notification Message: 45 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timeOffset          : Sample(4),
      complexInstrumentId : Sample(6),
      auctionId           : Sample(8),
      auctionType         : Sample(1),
      sideIndicator       : Sample(1),
      price               : Sample(8),
      quantity            : Sample(4),
      customerIndicator   : Sample(1),
      participantId       : Sample(4),
      auctionEndOffset    : Sample(4),
      clientId            : Sample(4) ]

EncodeAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId
        \o message.auctionId
        \o message.auctionType
        \o message.sideIndicator
        \o message.price
        \o message.quantity
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset
        \o message.clientId

DecodeAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(complexInstrumentId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(auctionType.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET price == ReadBytes(sideIndicator.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(quantity.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    LET clientId == ReadBytes(auctionEndOffset.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         complexInstrumentId |-> complexInstrumentId.value,
         auctionId           |-> auctionId.value,
         auctionType         |-> auctionType.value,
         sideIndicator       |-> sideIndicator.value,
         price               |-> price.value,
         quantity            |-> quantity.value,
         customerIndicator   |-> customerIndicator.value,
         participantId       |-> participantId.value,
         auctionEndOffset    |-> auctionEndOffset.value,
         clientId            |-> clientId.value ], clientId.rest)

ZeroAuctionNotificationMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      auctionId           |-> [i \in 1 .. 8 |-> 0],
      auctionType         |-> [i \in 1 .. 1 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      customerIndicator   |-> [i \in 1 .. 1 |-> 0],
      participantId       |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset    |-> [i \in 1 .. 4 |-> 0],
      clientId            |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.clientId = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Cancel Message: 12 bytes                                        *)
(***************************************************************************)

AuctionCancelMessage ==
    [ timeOffset : Sample(4),
      auctionId  : Sample(8) ]

EncodeAuctionCancelMessage(message) ==
    message.timeOffset
        \o message.auctionId

DecodeAuctionCancelMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         auctionId  |-> auctionId.value ], auctionId.rest)

ZeroAuctionCancelMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      auctionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCancelMessage ==
    { ZeroAuctionCancelMessage }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Trade Message: 32 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ timeOffset  : Sample(4),
      auctionId   : Sample(8),
      executionId : Sample(8),
      price       : Sample(8),
      quantity    : Sample(4) ]

EncodeAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.price
        \o message.quantity

DecodeAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         auctionId   |-> auctionId.value,
         executionId |-> executionId.value,
         price       |-> price.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroAuctionTradeMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      auctionId   |-> [i \in 1 .. 8 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      quantity    |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset       : Sample(4),
      complexSymbolId  : Sample(6),
      unused           : Sample(2),
      tradingStatus    : Sample(1),
      reserved1        : Sample(1),
      gthTradingStatus : Sample(1),
      padding          : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.complexSymbolId
        \o message.unused
        \o message.tradingStatus
        \o message.reserved1
        \o message.gthTradingStatus
        \o message.padding

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexSymbolId == ReadBytes(timeOffset.rest, 6) IN IF ~complexSymbolId.ok THEN Fail ELSE
    LET unused == ReadBytes(complexSymbolId.rest, 2) IN IF ~unused.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(unused.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET gthTradingStatus == ReadBytes(reserved1.rest, 1) IN IF ~gthTradingStatus.ok THEN Fail ELSE
    LET padding == ReadBytes(gthTradingStatus.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         complexSymbolId  |-> complexSymbolId.value,
         unused           |-> unused.value,
         tradingStatus    |-> tradingStatus.value,
         reserved1        |-> reserved1.value,
         gthTradingStatus |-> gthTradingStatus.value,
         padding          |-> padding.value ], padding.rest)

ZeroTradingStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      complexSymbolId  |-> [i \in 1 .. 6 |-> 0],
      unused           |-> [i \in 1 .. 2 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      gthTradingStatus |-> [i \in 1 .. 1 |-> 0],
      padding          |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.complexSymbolId = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.unused = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.gthTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Update Message: 62 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timeOffset                : Sample(4),
      complexInstrumentId8      : Sample(8),
      auctionOpeningType        : Sample(1),
      referencePrice            : Sample(8),
      buyContracts              : Sample(4),
      sellContracts             : Sample(4),
      indicativePrice           : Sample(8),
      auctionOnlyPrice          : Sample(8),
      openingCondition          : Sample(1),
      compositeMarketBidPrice   : Sample(8),
      compositeMarketOfferPrice : Sample(8) ]

EncodeAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId8
        \o message.auctionOpeningType
        \o message.referencePrice
        \o message.buyContracts
        \o message.sellContracts
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.openingCondition
        \o message.compositeMarketBidPrice
        \o message.compositeMarketOfferPrice

DecodeAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId8 == ReadBytes(timeOffset.rest, 8) IN IF ~complexInstrumentId8.ok THEN Fail ELSE
    LET auctionOpeningType == ReadBytes(complexInstrumentId8.rest, 1) IN IF ~auctionOpeningType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionOpeningType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyContracts == ReadBytes(referencePrice.rest, 4) IN IF ~buyContracts.ok THEN Fail ELSE
    LET sellContracts == ReadBytes(buyContracts.rest, 4) IN IF ~sellContracts.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellContracts.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET compositeMarketBidPrice == ReadBytes(openingCondition.rest, 8) IN IF ~compositeMarketBidPrice.ok THEN Fail ELSE
    LET compositeMarketOfferPrice == ReadBytes(compositeMarketBidPrice.rest, 8) IN IF ~compositeMarketOfferPrice.ok THEN Fail ELSE
    Ok([ timeOffset                |-> timeOffset.value,
         complexInstrumentId8      |-> complexInstrumentId8.value,
         auctionOpeningType        |-> auctionOpeningType.value,
         referencePrice            |-> referencePrice.value,
         buyContracts              |-> buyContracts.value,
         sellContracts             |-> sellContracts.value,
         indicativePrice           |-> indicativePrice.value,
         auctionOnlyPrice          |-> auctionOnlyPrice.value,
         openingCondition          |-> openingCondition.value,
         compositeMarketBidPrice   |-> compositeMarketBidPrice.value,
         compositeMarketOfferPrice |-> compositeMarketOfferPrice.value ], compositeMarketOfferPrice.rest)

ZeroAuctionUpdateMessage ==
    [ timeOffset                |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId8      |-> [i \in 1 .. 8 |-> 0],
      auctionOpeningType        |-> [i \in 1 .. 1 |-> 0],
      referencePrice            |-> [i \in 1 .. 8 |-> 0],
      buyContracts              |-> [i \in 1 .. 4 |-> 0],
      sellContracts             |-> [i \in 1 .. 4 |-> 0],
      indicativePrice           |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice          |-> [i \in 1 .. 8 |-> 0],
      openingCondition          |-> [i \in 1 .. 1 |-> 0],
      compositeMarketBidPrice   |-> [i \in 1 .. 8 |-> 0],
      compositeMarketOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.complexInstrumentId8 = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionOpeningType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.buyContracts = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.sellContracts = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.compositeMarketBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.compositeMarketOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Summary Message: 25 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset           : Sample(4),
      complexInstrumentId8 : Sample(8),
      auctionOpeningType   : Sample(1),
      price                : Sample(8),
      quantity             : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId8
        \o message.auctionOpeningType
        \o message.price
        \o message.quantity

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId8 == ReadBytes(timeOffset.rest, 8) IN IF ~complexInstrumentId8.ok THEN Fail ELSE
    LET auctionOpeningType == ReadBytes(complexInstrumentId8.rest, 1) IN IF ~auctionOpeningType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionOpeningType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         complexInstrumentId8 |-> complexInstrumentId8.value,
         auctionOpeningType   |-> auctionOpeningType.value,
         price                |-> price.value,
         quantity             |-> quantity.value ], quantity.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId8 |-> [i \in 1 .. 8 |-> 0],
      auctionOpeningType   |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.complexInstrumentId8 = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionOpeningType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timeOffset : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timeOffset

DecodeEndOfSessionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroEndOfSessionMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeReferenceMessageCode == 177  \* 0xb1
TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
TransactionBeginCode == 188  \* 0xbc
TransactionEndMessageCode == 189  \* 0xbd
ComplexInstrumentDefinitionExpandedMessageCode == 154  \* 0x9a
SymbolMappingMessageCode == 46  \* 0x2e
AddOrderLongMessageCode == 33  \* 0x21
AddOrderShortMessageCode == 34  \* 0x22
AddOrderExpandedMessageCode == 47  \* 0x2f
OrderExecutedMessageCode == 35  \* 0x23
OrderExecutedAtPriceSizeMessageCode == 36  \* 0x24
ReduceSizeLongMessageCode == 37  \* 0x25
ReduceSizeShortMessageCode == 38  \* 0x26
ModifyOrderLongMessageCode == 39  \* 0x27
ModifyOrderShortMessageCode == 40  \* 0x28
DeleteOrderMessageCode == 41  \* 0x29
TradeLongMessageCode == 42  \* 0x2a
TradeShortMessageCode == 43  \* 0x2b
AuctionNotificationMessageCode == 173  \* 0xad
AuctionCancelMessageCode == 174  \* 0xae
AuctionTradeMessageCode == 175  \* 0xaf
TradingStatusMessageCode == 49  \* 0x31
AuctionUpdateMessageCode == 209  \* 0xd1
AuctionSummaryMessageCode == 150  \* 0x96
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {TimeReferenceMessageCode}, body : TimeReferenceMessage ]
        \cup [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {TransactionBeginCode}, body : TransactionBegin ]
        \cup [ tag : {TransactionEndMessageCode}, body : TransactionEndMessage ]
        \cup [ tag : {ComplexInstrumentDefinitionExpandedMessageCode}, body : ComplexInstrumentDefinitionExpandedMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {AddOrderExpandedMessageCode}, body : AddOrderExpandedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedAtPriceSizeMessageCode}, body : OrderExecutedAtPriceSizeMessage ]
        \cup [ tag : {ReduceSizeLongMessageCode}, body : ReduceSizeLongMessage ]
        \cup [ tag : {ReduceSizeShortMessageCode}, body : ReduceSizeShortMessage ]
        \cup [ tag : {ModifyOrderLongMessageCode}, body : ModifyOrderLongMessage ]
        \cup [ tag : {ModifyOrderShortMessageCode}, body : ModifyOrderShortMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {TradeLongMessageCode}, body : TradeLongMessage ]
        \cup [ tag : {TradeShortMessageCode}, body : TradeShortMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {AuctionCancelMessageCode}, body : AuctionCancelMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeReferenceMessageCode -> EncodeTimeReferenceMessage(message.body)
      [] message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = TransactionBeginCode -> EncodeTransactionBegin(message.body)
      [] message.tag = TransactionEndMessageCode -> EncodeTransactionEndMessage(message.body)
      [] message.tag = ComplexInstrumentDefinitionExpandedMessageCode -> EncodeComplexInstrumentDefinitionExpandedMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = AddOrderExpandedMessageCode -> EncodeAddOrderExpandedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedAtPriceSizeMessageCode -> EncodeOrderExecutedAtPriceSizeMessage(message.body)
      [] message.tag = ReduceSizeLongMessageCode -> EncodeReduceSizeLongMessage(message.body)
      [] message.tag = ReduceSizeShortMessageCode -> EncodeReduceSizeShortMessage(message.body)
      [] message.tag = ModifyOrderLongMessageCode -> EncodeModifyOrderLongMessage(message.body)
      [] message.tag = ModifyOrderShortMessageCode -> EncodeModifyOrderShortMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = TradeLongMessageCode -> EncodeTradeLongMessage(message.body)
      [] message.tag = TradeShortMessageCode -> EncodeTradeShortMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = AuctionCancelMessageCode -> EncodeAuctionCancelMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeReferenceMessageCode -> DecodeTimeReferenceMessage(bytes)
              [] tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = TransactionBeginCode -> DecodeTransactionBegin(bytes)
              [] tag = TransactionEndMessageCode -> DecodeTransactionEndMessage(bytes)
              [] tag = ComplexInstrumentDefinitionExpandedMessageCode -> DecodeComplexInstrumentDefinitionExpandedMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = AddOrderExpandedMessageCode -> DecodeAddOrderExpandedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedAtPriceSizeMessageCode -> DecodeOrderExecutedAtPriceSizeMessage(bytes)
              [] tag = ReduceSizeLongMessageCode -> DecodeReduceSizeLongMessage(bytes)
              [] tag = ReduceSizeShortMessageCode -> DecodeReduceSizeShortMessage(bytes)
              [] tag = ModifyOrderLongMessageCode -> DecodeModifyOrderLongMessage(bytes)
              [] tag = ModifyOrderShortMessageCode -> DecodeModifyOrderShortMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = TradeLongMessageCode -> DecodeTradeLongMessage(bytes)
              [] tag = TradeShortMessageCode -> DecodeTradeShortMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = AuctionCancelMessageCode -> DecodeAuctionCancelMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeReferenceMessageCode, body |-> ZeroTimeReferenceMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeReferenceMessageCode, body |-> one] : one \in CheckedTimeReferenceMessage }
        \cup { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> TransactionBeginCode, body |-> one] : one \in CheckedTransactionBegin }
        \cup { [tag |-> TransactionEndMessageCode, body |-> one] : one \in CheckedTransactionEndMessage }
        \cup { [tag |-> ComplexInstrumentDefinitionExpandedMessageCode, body |-> one] : one \in CheckedComplexInstrumentDefinitionExpandedMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> AddOrderExpandedMessageCode, body |-> one] : one \in CheckedAddOrderExpandedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedAtPriceSizeMessageCode, body |-> one] : one \in CheckedOrderExecutedAtPriceSizeMessage }
        \cup { [tag |-> ReduceSizeLongMessageCode, body |-> one] : one \in CheckedReduceSizeLongMessage }
        \cup { [tag |-> ReduceSizeShortMessageCode, body |-> one] : one \in CheckedReduceSizeShortMessage }
        \cup { [tag |-> ModifyOrderLongMessageCode, body |-> one] : one \in CheckedModifyOrderLongMessage }
        \cup { [tag |-> ModifyOrderShortMessageCode, body |-> one] : one \in CheckedModifyOrderShortMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> TradeLongMessageCode, body |-> one] : one \in CheckedTradeLongMessage }
        \cup { [tag |-> TradeShortMessageCode, body |-> one] : one \in CheckedTradeShortMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> AuctionCancelMessageCode, body |-> one] : one \in CheckedAuctionCancelMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeReferenceMessageCode, body |-> ZeroTimeReferenceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionBeginCode, body |-> ZeroTransactionBegin]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionEndMessageCode, body |-> ZeroTransactionEndMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexInstrumentDefinitionExpandedMessageCode, body |-> ZeroComplexInstrumentDefinitionExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderLongMessageCode, body |-> ZeroAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderShortMessageCode, body |-> ZeroAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderExpandedMessageCode, body |-> ZeroAddOrderExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedAtPriceSizeMessageCode, body |-> ZeroOrderExecutedAtPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeLongMessageCode, body |-> ZeroReduceSizeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeShortMessageCode, body |-> ZeroReduceSizeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderLongMessageCode, body |-> ZeroModifyOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderShortMessageCode, body |-> ZeroModifyOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeLongMessageCode, body |-> ZeroTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeShortMessageCode, body |-> ZeroTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionCancelMessageCode, body |-> ZeroAuctionCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Time Reference Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeReferenceMessage ==
    \A message \in CheckedTimeReferenceMessage :
        LET read == DecodeTimeReferenceMessage(EncodeTimeReferenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitClearMessage ==
    \A message \in CheckedUnitClearMessage :
        LET read == DecodeUnitClearMessage(EncodeUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Begin decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionBegin ==
    \A message \in CheckedTransactionBegin :
        LET read == DecodeTransactionBegin(EncodeTransactionBegin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionEndMessage ==
    \A message \in CheckedTransactionEndMessage :
        LET read == DecodeTransactionEndMessage(EncodeTransactionEndMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentLeg ==
    \A message \in CheckedComplexInstrumentLeg :
        LET read == DecodeComplexInstrumentLeg(EncodeComplexInstrumentLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Definition Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDefinitionExpandedMessage ==
    \A message \in CheckedComplexInstrumentDefinitionExpandedMessage :
        LET read == DecodeComplexInstrumentDefinitionExpandedMessage(EncodeComplexInstrumentDefinitionExpandedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderLongMessage ==
    \A message \in CheckedAddOrderLongMessage :
        LET read == DecodeAddOrderLongMessage(EncodeAddOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortMessage ==
    \A message \in CheckedAddOrderShortMessage :
        LET read == DecodeAddOrderShortMessage(EncodeAddOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderExpandedMessage ==
    \A message \in CheckedAddOrderExpandedMessage :
        LET read == DecodeAddOrderExpandedMessage(EncodeAddOrderExpandedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed At Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedAtPriceSizeMessage ==
    \A message \in CheckedOrderExecutedAtPriceSizeMessage :
        LET read == DecodeOrderExecutedAtPriceSizeMessage(EncodeOrderExecutedAtPriceSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reduce Size Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeLongMessage ==
    \A message \in CheckedReduceSizeLongMessage :
        LET read == DecodeReduceSizeLongMessage(EncodeReduceSizeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reduce Size Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeShortMessage ==
    \A message \in CheckedReduceSizeShortMessage :
        LET read == DecodeReduceSizeShortMessage(EncodeReduceSizeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderLongMessage ==
    \A message \in CheckedModifyOrderLongMessage :
        LET read == DecodeModifyOrderLongMessage(EncodeModifyOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderShortMessage ==
    \A message \in CheckedModifyOrderShortMessage :
        LET read == DecodeModifyOrderShortMessage(EncodeModifyOrderShortMessage(message))
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

(* Every Trade Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeLongMessage ==
    \A message \in CheckedTradeLongMessage :
        LET read == DecodeTradeLongMessage(EncodeTradeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeShortMessage ==
    \A message \in CheckedTradeShortMessage :
        LET read == DecodeTradeShortMessage(EncodeTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionNotificationMessage ==
    \A message \in CheckedAuctionNotificationMessage :
        LET read == DecodeAuctionNotificationMessage(EncodeAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCancelMessage ==
    \A message \in CheckedAuctionCancelMessage :
        LET read == DecodeAuctionCancelMessage(EncodeAuctionCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionUpdateMessage ==
    \A message \in CheckedAuctionUpdateMessage :
        LET read == DecodeAuctionUpdateMessage(EncodeAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
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
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
