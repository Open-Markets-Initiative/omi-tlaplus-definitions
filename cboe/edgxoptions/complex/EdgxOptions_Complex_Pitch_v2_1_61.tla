----------------- MODULE EdgxOptions_Complex_Pitch_v2_1_61 -----------------
(***************************************************************************)
(* Chicago Board Options Exchange Complex v2.1.61                          *)
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
(* Time Message: 4 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ time : Sample(4) ]

EncodeTimeMessage(message) ==
    message.time

DecodeTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroTimeMessage ==
    [ time |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.time = one] : one \in Sample(4) }

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
(* Transaction Begin Message: 4 bytes                                      *)
(***************************************************************************)

TransactionBeginMessage ==
    [ timeOffset : Sample(4) ]

EncodeTransactionBeginMessage(message) ==
    message.timeOffset

DecodeTransactionBeginMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroTransactionBeginMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Transaction Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionBeginMessage ==
    { ZeroTransactionBeginMessage }
        \cup { [ZeroTransactionBeginMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

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
(* Complex Leg: 13 bytes                                                   *)
(***************************************************************************)

ComplexLeg ==
    [ legSymbol       : Sample(8),
      legRatio        : Sample(4),
      legSecurityType : Sample(1) ]

EncodeComplexLeg(message) ==
    message.legSymbol
        \o message.legRatio
        \o message.legSecurityType

DecodeComplexLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbol.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatio.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ legSymbol       |-> legSymbol.value,
         legRatio        |-> legRatio.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroComplexLeg ==
    [ legSymbol       |-> [i \in 1 .. 8 |-> 0],
      legRatio        |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexLeg ==
    { ZeroComplexLeg }
        \cup { [ZeroComplexLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroComplexLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroComplexLeg EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Complex Leg, written one after another *)
RECURSIVE EncodeComplexLegList(_)
EncodeComplexLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexLeg(Head(messages)) \o EncodeComplexLegList(Tail(messages))

(* As many Complex Leg as the field that counts them says *)
RECURSIVE ReadComplexLegList(_, _)
ReadComplexLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Leg of each kind, for the lists that carry them *)
OneComplexLeg == { ZeroComplexLeg }

(***************************************************************************)
(* Complex Instrument Definition Expanded Message                          *)
(***************************************************************************)

ComplexInstrumentDefinitionExpandedMessage ==
    [ timeOffset                  : Sample(4),
      complexInstrumentIdShort    : Sample(6),
      complexInstrumentUnderlying : Sample(8),
      complexInstrumentType       : Sample(4),
      complexLeg                  : SampleLists(OneComplexLeg) ]

EncodeComplexInstrumentDefinitionExpandedMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentIdShort
        \o message.complexInstrumentUnderlying
        \o message.complexInstrumentType
        \o EncodeUIntLE(Len(message.complexLeg), 1)
        \o EncodeComplexLegList(message.complexLeg)

DecodeComplexInstrumentDefinitionExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentIdShort == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentIdShort.ok THEN Fail ELSE
    LET complexInstrumentUnderlying == ReadBytes(complexInstrumentIdShort.rest, 8) IN IF ~complexInstrumentUnderlying.ok THEN Fail ELSE
    LET complexInstrumentType == ReadBytes(complexInstrumentUnderlying.rest, 4) IN IF ~complexInstrumentType.ok THEN Fail ELSE
    LET legCount == ReadUIntLE(complexInstrumentType.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET complexLeg == ReadComplexLegList(legCount.rest, legCount.value) IN IF ~complexLeg.ok THEN Fail ELSE
    Ok([ timeOffset                  |-> timeOffset.value,
         complexInstrumentIdShort    |-> complexInstrumentIdShort.value,
         complexInstrumentUnderlying |-> complexInstrumentUnderlying.value,
         complexInstrumentType       |-> complexInstrumentType.value,
         complexLeg                  |-> complexLeg.value ], complexLeg.rest)

ZeroComplexInstrumentDefinitionExpandedMessage ==
    [ timeOffset                  |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdShort    |-> [i \in 1 .. 6 |-> 0],
      complexInstrumentUnderlying |-> [i \in 1 .. 8 |-> 0],
      complexInstrumentType       |-> [i \in 1 .. 4 |-> 0],
      complexLeg                  |-> << >> ]

(* Complex Instrument Definition Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionExpandedMessage ==
    { ZeroComplexInstrumentDefinitionExpandedMessage }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentIdShort = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentUnderlying = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentType = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexLeg = one] : one \in SampleLists(OneComplexLeg) }

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
    [ timeOffset               : Sample(4),
      orderId                  : Sample(8),
      sideIndicator            : Sample(1),
      quantityLong             : Sample(4),
      complexInstrumentIdShort : Sample(6),
      signedPriceLong          : Sample(8),
      reserved1                : Sample(1) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.complexInstrumentIdShort
        \o message.signedPriceLong
        \o message.reserved1

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET complexInstrumentIdShort == ReadBytes(quantityLong.rest, 6) IN IF ~complexInstrumentIdShort.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(complexInstrumentIdShort.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(signedPriceLong.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timeOffset               |-> timeOffset.value,
         orderId                  |-> orderId.value,
         sideIndicator            |-> sideIndicator.value,
         quantityLong             |-> quantityLong.value,
         complexInstrumentIdShort |-> complexInstrumentIdShort.value,
         signedPriceLong          |-> signedPriceLong.value,
         reserved1                |-> reserved1.value ], reserved1.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      sideIndicator            |-> [i \in 1 .. 1 |-> 0],
      quantityLong             |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdShort |-> [i \in 1 .. 6 |-> 0],
      signedPriceLong          |-> [i \in 1 .. 8 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.complexInstrumentIdShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Message: 24 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset               : Sample(4),
      orderId                  : Sample(8),
      sideIndicator            : Sample(1),
      quantityShort            : Sample(2),
      complexInstrumentIdShort : Sample(6),
      signedPriceShort         : Sample(2),
      reserved1                : Sample(1) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.complexInstrumentIdShort
        \o message.signedPriceShort
        \o message.reserved1

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET complexInstrumentIdShort == ReadBytes(quantityShort.rest, 6) IN IF ~complexInstrumentIdShort.ok THEN Fail ELSE
    LET signedPriceShort == ReadBytes(complexInstrumentIdShort.rest, 2) IN IF ~signedPriceShort.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(signedPriceShort.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timeOffset               |-> timeOffset.value,
         orderId                  |-> orderId.value,
         sideIndicator            |-> sideIndicator.value,
         quantityShort            |-> quantityShort.value,
         complexInstrumentIdShort |-> complexInstrumentIdShort.value,
         signedPriceShort         |-> signedPriceShort.value,
         reserved1                |-> reserved1.value ], reserved1.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      sideIndicator            |-> [i \in 1 .. 1 |-> 0],
      quantityShort            |-> [i \in 1 .. 2 |-> 0],
      complexInstrumentIdShort |-> [i \in 1 .. 6 |-> 0],
      signedPriceShort         |-> [i \in 1 .. 2 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.complexInstrumentIdShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.signedPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Expanded Message: 48 bytes                                    *)
(***************************************************************************)

AddOrderExpandedMessage ==
    [ timeOffset              : Sample(4),
      orderId                 : Sample(8),
      sideIndicator           : Sample(1),
      quantityLong            : Sample(4),
      complexInstrumentIdLong : Sample(8),
      signedPriceLong         : Sample(8),
      reserved1               : Sample(1),
      participantId           : Sample(4),
      customerIndicator       : Sample(1),
      clientId                : Sample(4),
      reserved5               : Sample(5) ]

EncodeAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.complexInstrumentIdLong
        \o message.signedPriceLong
        \o message.reserved1
        \o message.participantId
        \o message.customerIndicator
        \o message.clientId
        \o message.reserved5

DecodeAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET complexInstrumentIdLong == ReadBytes(quantityLong.rest, 8) IN IF ~complexInstrumentIdLong.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(complexInstrumentIdLong.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(signedPriceLong.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET participantId == ReadBytes(reserved1.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(customerIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(clientId.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    Ok([ timeOffset              |-> timeOffset.value,
         orderId                 |-> orderId.value,
         sideIndicator           |-> sideIndicator.value,
         quantityLong            |-> quantityLong.value,
         complexInstrumentIdLong |-> complexInstrumentIdLong.value,
         signedPriceLong         |-> signedPriceLong.value,
         reserved1               |-> reserved1.value,
         participantId           |-> participantId.value,
         customerIndicator       |-> customerIndicator.value,
         clientId                |-> clientId.value,
         reserved5               |-> reserved5.value ], reserved5.rest)

ZeroAddOrderExpandedMessage ==
    [ timeOffset              |-> [i \in 1 .. 4 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      sideIndicator           |-> [i \in 1 .. 1 |-> 0],
      quantityLong            |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdLong |-> [i \in 1 .. 8 |-> 0],
      signedPriceLong         |-> [i \in 1 .. 8 |-> 0],
      reserved1               |-> [i \in 1 .. 1 |-> 0],
      participantId           |-> [i \in 1 .. 4 |-> 0],
      customerIndicator       |-> [i \in 1 .. 1 |-> 0],
      clientId                |-> [i \in 1 .. 4 |-> 0],
      reserved5               |-> [i \in 1 .. 5 |-> 0] ]

(* Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExpandedMessage ==
    { ZeroAddOrderExpandedMessage }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.complexInstrumentIdLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }

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
      signedPriceLong   : Sample(8),
      tradeCondition    : Sample(1) ]

EncodeOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.signedPriceLong
        \o message.tradeCondition

DecodeOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(executionId.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(signedPriceLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         signedPriceLong   |-> signedPriceLong.value,
         tradeCondition    |-> tradeCondition.value ], tradeCondition.rest)

ZeroOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      signedPriceLong   |-> [i \in 1 .. 8 |-> 0],
      tradeCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceSizeMessage ==
    { ZeroOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Reduce Size Long Message: 16 bytes                                      *)
(***************************************************************************)

ReduceSizeLongMessage ==
    [ timeOffset           : Sample(4),
      orderId              : Sample(8),
      canceledQuantityLong : Sample(4) ]

EncodeReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityLong

DecodeReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityLong == ReadBytes(orderId.rest, 4) IN IF ~canceledQuantityLong.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         orderId              |-> orderId.value,
         canceledQuantityLong |-> canceledQuantityLong.value ], canceledQuantityLong.rest)

ZeroReduceSizeLongMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityLong |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeLongMessage ==
    { ZeroReduceSizeLongMessage }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.canceledQuantityLong = one] : one \in Sample(4) }

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
    [ timeOffset      : Sample(4),
      orderId         : Sample(8),
      quantityLong    : Sample(4),
      signedPriceLong : Sample(8),
      reserved1       : Sample(1) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityLong
        \o message.signedPriceLong
        \o message.reserved1

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(orderId.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(quantityLong.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(signedPriceLong.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         orderId         |-> orderId.value,
         quantityLong    |-> quantityLong.value,
         signedPriceLong |-> signedPriceLong.value,
         reserved1       |-> reserved1.value ], reserved1.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      quantityLong    |-> [i \in 1 .. 4 |-> 0],
      signedPriceLong |-> [i \in 1 .. 8 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Short Message: 17 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      quantityShort    : Sample(2),
      signedPriceShort : Sample(2),
      reserved1        : Sample(1) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityShort
        \o message.signedPriceShort
        \o message.reserved1

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(orderId.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET signedPriceShort == ReadBytes(quantityShort.rest, 2) IN IF ~signedPriceShort.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(signedPriceShort.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         quantityShort    |-> quantityShort.value,
         signedPriceShort |-> signedPriceShort.value,
         reserved1        |-> reserved1.value ], reserved1.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      quantityShort    |-> [i \in 1 .. 2 |-> 0],
      signedPriceShort |-> [i \in 1 .. 2 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.signedPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

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
    [ timeOffset               : Sample(4),
      orderId                  : Sample(8),
      sideIndicator            : Sample(1),
      quantityLong             : Sample(4),
      complexInstrumentIdShort : Sample(6),
      signedPriceLong          : Sample(8),
      executionId              : Sample(8),
      tradeCondition           : Sample(1) ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.complexInstrumentIdShort
        \o message.signedPriceLong
        \o message.executionId
        \o message.tradeCondition

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET complexInstrumentIdShort == ReadBytes(quantityLong.rest, 6) IN IF ~complexInstrumentIdShort.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(complexInstrumentIdShort.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(signedPriceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset               |-> timeOffset.value,
         orderId                  |-> orderId.value,
         sideIndicator            |-> sideIndicator.value,
         quantityLong             |-> quantityLong.value,
         complexInstrumentIdShort |-> complexInstrumentIdShort.value,
         signedPriceLong          |-> signedPriceLong.value,
         executionId              |-> executionId.value,
         tradeCondition           |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeLongMessage ==
    [ timeOffset               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      sideIndicator            |-> [i \in 1 .. 1 |-> 0],
      quantityLong             |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdShort |-> [i \in 1 .. 6 |-> 0],
      signedPriceLong          |-> [i \in 1 .. 8 |-> 0],
      executionId              |-> [i \in 1 .. 8 |-> 0],
      tradeCondition           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.complexInstrumentIdShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 32 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset               : Sample(4),
      orderId                  : Sample(8),
      sideIndicator            : Sample(1),
      quantityShort            : Sample(2),
      complexInstrumentIdShort : Sample(6),
      signedPriceShort         : Sample(2),
      executionId              : Sample(8),
      tradeCondition           : Sample(1) ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.complexInstrumentIdShort
        \o message.signedPriceShort
        \o message.executionId
        \o message.tradeCondition

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET complexInstrumentIdShort == ReadBytes(quantityShort.rest, 6) IN IF ~complexInstrumentIdShort.ok THEN Fail ELSE
    LET signedPriceShort == ReadBytes(complexInstrumentIdShort.rest, 2) IN IF ~signedPriceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(signedPriceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset               |-> timeOffset.value,
         orderId                  |-> orderId.value,
         sideIndicator            |-> sideIndicator.value,
         quantityShort            |-> quantityShort.value,
         complexInstrumentIdShort |-> complexInstrumentIdShort.value,
         signedPriceShort         |-> signedPriceShort.value,
         executionId              |-> executionId.value,
         tradeCondition           |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeShortMessage ==
    [ timeOffset               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      sideIndicator            |-> [i \in 1 .. 1 |-> 0],
      quantityShort            |-> [i \in 1 .. 2 |-> 0],
      complexInstrumentIdShort |-> [i \in 1 .. 6 |-> 0],
      signedPriceShort         |-> [i \in 1 .. 2 |-> 0],
      executionId              |-> [i \in 1 .. 8 |-> 0],
      tradeCondition           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.complexInstrumentIdShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.signedPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Notification Message: 45 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timeOffset               : Sample(4),
      complexInstrumentIdShort : Sample(6),
      auctionId                : Sample(8),
      notificationAuctionType  : Sample(1),
      side                     : Sample(1),
      signedPriceLong          : Sample(8),
      quantityLong             : Sample(4),
      customerIndicator        : Sample(1),
      participantId            : Sample(4),
      auctionEndOffset         : Sample(4),
      clientId                 : Sample(4) ]

EncodeAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentIdShort
        \o message.auctionId
        \o message.notificationAuctionType
        \o message.side
        \o message.signedPriceLong
        \o message.quantityLong
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset
        \o message.clientId

DecodeAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentIdShort == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentIdShort.ok THEN Fail ELSE
    LET auctionId == ReadBytes(complexInstrumentIdShort.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET notificationAuctionType == ReadBytes(auctionId.rest, 1) IN IF ~notificationAuctionType.ok THEN Fail ELSE
    LET side == ReadBytes(notificationAuctionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(side.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(signedPriceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(quantityLong.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    LET clientId == ReadBytes(auctionEndOffset.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    Ok([ timeOffset               |-> timeOffset.value,
         complexInstrumentIdShort |-> complexInstrumentIdShort.value,
         auctionId                |-> auctionId.value,
         notificationAuctionType  |-> notificationAuctionType.value,
         side                     |-> side.value,
         signedPriceLong          |-> signedPriceLong.value,
         quantityLong             |-> quantityLong.value,
         customerIndicator        |-> customerIndicator.value,
         participantId            |-> participantId.value,
         auctionEndOffset         |-> auctionEndOffset.value,
         clientId                 |-> clientId.value ], clientId.rest)

ZeroAuctionNotificationMessage ==
    [ timeOffset               |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdShort |-> [i \in 1 .. 6 |-> 0],
      auctionId                |-> [i \in 1 .. 8 |-> 0],
      notificationAuctionType  |-> [i \in 1 .. 1 |-> 0],
      side                     |-> [i \in 1 .. 1 |-> 0],
      signedPriceLong          |-> [i \in 1 .. 8 |-> 0],
      quantityLong             |-> [i \in 1 .. 4 |-> 0],
      customerIndicator        |-> [i \in 1 .. 1 |-> 0],
      participantId            |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset         |-> [i \in 1 .. 4 |-> 0],
      clientId                 |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.complexInstrumentIdShort = one] : one \in Sample(6) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.notificationAuctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
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
    [ timeOffset      : Sample(4),
      auctionId       : Sample(8),
      executionId     : Sample(8),
      signedPriceLong : Sample(8),
      quantityLong    : Sample(4) ]

EncodeAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.signedPriceLong
        \o message.quantityLong

DecodeAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(executionId.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(signedPriceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         auctionId       |-> auctionId.value,
         executionId     |-> executionId.value,
         signedPriceLong |-> signedPriceLong.value,
         quantityLong    |-> quantityLong.value ], quantityLong.rest)

ZeroAuctionTradeMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      auctionId       |-> [i \in 1 .. 8 |-> 0],
      executionId     |-> [i \in 1 .. 8 |-> 0],
      signedPriceLong |-> [i \in 1 .. 8 |-> 0],
      quantityLong    |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset       : Sample(4),
      complexSymbolId  : Sample(6),
      reserved2        : Sample(2),
      tradingStatus    : Sample(1),
      reserved1        : Sample(1),
      gthTradingStatus : Sample(1),
      secondReserved1  : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.complexSymbolId
        \o message.reserved2
        \o message.tradingStatus
        \o message.reserved1
        \o message.gthTradingStatus
        \o message.secondReserved1

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexSymbolId == ReadBytes(timeOffset.rest, 6) IN IF ~complexSymbolId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(complexSymbolId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reserved2.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET gthTradingStatus == ReadBytes(reserved1.rest, 1) IN IF ~gthTradingStatus.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(gthTradingStatus.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         complexSymbolId  |-> complexSymbolId.value,
         reserved2        |-> reserved2.value,
         tradingStatus    |-> tradingStatus.value,
         reserved1        |-> reserved1.value,
         gthTradingStatus |-> gthTradingStatus.value,
         secondReserved1  |-> secondReserved1.value ], secondReserved1.rest)

ZeroTradingStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      complexSymbolId  |-> [i \in 1 .. 6 |-> 0],
      reserved2        |-> [i \in 1 .. 2 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      gthTradingStatus |-> [i \in 1 .. 1 |-> 0],
      secondReserved1  |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.complexSymbolId = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.gthTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Auction Update Message: 62 bytes                                *)
(***************************************************************************)

OptionsAuctionUpdateMessage ==
    [ timeOffset                : Sample(4),
      complexInstrumentIdLong   : Sample(8),
      auctionType               : Sample(1),
      referencePrice            : Sample(8),
      buyContracts              : Sample(4),
      sellContracts             : Sample(4),
      indicativePrice           : Sample(8),
      auctionOnlyPrice          : Sample(8),
      openingCondition          : Sample(1),
      compositeMarketBidPrice   : Sample(8),
      compositeMarketOfferPrice : Sample(8) ]

EncodeOptionsAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentIdLong
        \o message.auctionType
        \o message.referencePrice
        \o message.buyContracts
        \o message.sellContracts
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.openingCondition
        \o message.compositeMarketBidPrice
        \o message.compositeMarketOfferPrice

DecodeOptionsAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentIdLong == ReadBytes(timeOffset.rest, 8) IN IF ~complexInstrumentIdLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(complexInstrumentIdLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyContracts == ReadBytes(referencePrice.rest, 4) IN IF ~buyContracts.ok THEN Fail ELSE
    LET sellContracts == ReadBytes(buyContracts.rest, 4) IN IF ~sellContracts.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellContracts.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET compositeMarketBidPrice == ReadBytes(openingCondition.rest, 8) IN IF ~compositeMarketBidPrice.ok THEN Fail ELSE
    LET compositeMarketOfferPrice == ReadBytes(compositeMarketBidPrice.rest, 8) IN IF ~compositeMarketOfferPrice.ok THEN Fail ELSE
    Ok([ timeOffset                |-> timeOffset.value,
         complexInstrumentIdLong   |-> complexInstrumentIdLong.value,
         auctionType               |-> auctionType.value,
         referencePrice            |-> referencePrice.value,
         buyContracts              |-> buyContracts.value,
         sellContracts             |-> sellContracts.value,
         indicativePrice           |-> indicativePrice.value,
         auctionOnlyPrice          |-> auctionOnlyPrice.value,
         openingCondition          |-> openingCondition.value,
         compositeMarketBidPrice   |-> compositeMarketBidPrice.value,
         compositeMarketOfferPrice |-> compositeMarketOfferPrice.value ], compositeMarketOfferPrice.rest)

ZeroOptionsAuctionUpdateMessage ==
    [ timeOffset                |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdLong   |-> [i \in 1 .. 8 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      referencePrice            |-> [i \in 1 .. 8 |-> 0],
      buyContracts              |-> [i \in 1 .. 4 |-> 0],
      sellContracts             |-> [i \in 1 .. 4 |-> 0],
      indicativePrice           |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice          |-> [i \in 1 .. 8 |-> 0],
      openingCondition          |-> [i \in 1 .. 1 |-> 0],
      compositeMarketBidPrice   |-> [i \in 1 .. 8 |-> 0],
      compositeMarketOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Options Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsAuctionUpdateMessage ==
    { ZeroOptionsAuctionUpdateMessage }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.complexInstrumentIdLong = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.buyContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.sellContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.compositeMarketBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.compositeMarketOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Summary Message: 25 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset              : Sample(4),
      complexInstrumentIdLong : Sample(8),
      auctionType             : Sample(1),
      signedPriceLong         : Sample(8),
      quantityLong            : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentIdLong
        \o message.auctionType
        \o message.signedPriceLong
        \o message.quantityLong

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentIdLong == ReadBytes(timeOffset.rest, 8) IN IF ~complexInstrumentIdLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(complexInstrumentIdLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(auctionType.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(signedPriceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ timeOffset              |-> timeOffset.value,
         complexInstrumentIdLong |-> complexInstrumentIdLong.value,
         auctionType             |-> auctionType.value,
         signedPriceLong         |-> signedPriceLong.value,
         quantityLong            |-> quantityLong.value ], quantityLong.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset              |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentIdLong |-> [i \in 1 .. 8 |-> 0],
      auctionType             |-> [i \in 1 .. 1 |-> 0],
      signedPriceLong         |-> [i \in 1 .. 8 |-> 0],
      quantityLong            |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.complexInstrumentIdLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timestamp : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timestamp

DecodeEndOfSessionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value ], timestamp.rest)

ZeroEndOfSessionMessage ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timestamp = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
TransactionBeginMessageCode == 188  \* 0xbc
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
OptionsAuctionUpdateMessageCode == 209  \* 0xd1
AuctionSummaryMessageCode == 150  \* 0x96
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {TransactionBeginMessageCode}, body : TransactionBeginMessage ]
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
        \cup [ tag : {OptionsAuctionUpdateMessageCode}, body : OptionsAuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = TransactionBeginMessageCode -> EncodeTransactionBeginMessage(message.body)
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
      [] message.tag = OptionsAuctionUpdateMessageCode -> EncodeOptionsAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = TransactionBeginMessageCode -> DecodeTransactionBeginMessage(bytes)
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
              [] tag = OptionsAuctionUpdateMessageCode -> DecodeOptionsAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> TransactionBeginMessageCode, body |-> one] : one \in CheckedTransactionBeginMessage }
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
        \cup { [tag |-> OptionsAuctionUpdateMessageCode, body |-> one] : one \in CheckedOptionsAuctionUpdateMessage }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionBeginMessageCode, body |-> ZeroTransactionBeginMessage]],
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
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsAuctionUpdateMessageCode, body |-> ZeroOptionsAuctionUpdateMessage]],
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

(* Every Transaction Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionBeginMessage ==
    \A message \in CheckedTransactionBeginMessage :
        LET read == DecodeTransactionBeginMessage(EncodeTransactionBeginMessage(message))
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

(* Every Complex Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexLeg ==
    \A message \in CheckedComplexLeg :
        LET read == DecodeComplexLeg(EncodeComplexLeg(message))
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

(* Every Options Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsAuctionUpdateMessage ==
    \A message \in CheckedOptionsAuctionUpdateMessage :
        LET read == DecodeOptionsAuctionUpdateMessage(EncodeOptionsAuctionUpdateMessage(message))
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
