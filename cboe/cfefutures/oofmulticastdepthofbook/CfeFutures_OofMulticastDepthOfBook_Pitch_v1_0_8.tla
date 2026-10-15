---------- MODULE CfeFutures_OofMulticastDepthOfBook_Pitch_v1_0_8 ----------
(***************************************************************************)
(* Chicago Board Options Exchange OOF Multicast Depth Of Book v1.0.8       *)
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
(* Note: Summary Flags is a bit field set, checked as its 1 byte rather    *)
(* than bit by bit.                                                        *)
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
    [ timeReference : Sample(4),
      epochTime     : Sample(4) ]

EncodeTimeMessage(message) ==
    message.timeReference
        \o message.epochTime

DecodeTimeMessage(bytes) ==
    LET timeReference == ReadBytes(bytes, 4) IN IF ~timeReference.ok THEN Fail ELSE
    LET epochTime == ReadBytes(timeReference.rest, 4) IN IF ~epochTime.ok THEN Fail ELSE
    Ok([ timeReference |-> timeReference.value,
         epochTime     |-> epochTime.value ], epochTime.rest)

ZeroTimeMessage ==
    [ timeReference |-> [i \in 1 .. 4 |-> 0],
      epochTime     |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.timeReference = one] : one \in Sample(4) }
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
(* Oof Symbol Mapping Message: 58 bytes                                    *)
(***************************************************************************)

OofSymbolMappingMessage ==
    [ timeOffset           : Sample(4),
      feedSymbol           : Sample(6),
      futuresProduct       : Sample(8),
      futuresExpiration    : Sample(4),
      futuresSymbol        : Sample(6),
      strikePrice          : Sample(8),
      callPutIndicator     : Sample(1),
      optionsExpiration    : Sample(4),
      optionsOnFuturesName : Sample(16),
      symbolCondition      : Sample(1) ]

EncodeOofSymbolMappingMessage(message) ==
    message.timeOffset
        \o message.feedSymbol
        \o message.futuresProduct
        \o message.futuresExpiration
        \o message.futuresSymbol
        \o message.strikePrice
        \o message.callPutIndicator
        \o message.optionsExpiration
        \o message.optionsOnFuturesName
        \o message.symbolCondition

DecodeOofSymbolMappingMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET feedSymbol == ReadBytes(timeOffset.rest, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET futuresProduct == ReadBytes(feedSymbol.rest, 8) IN IF ~futuresProduct.ok THEN Fail ELSE
    LET futuresExpiration == ReadBytes(futuresProduct.rest, 4) IN IF ~futuresExpiration.ok THEN Fail ELSE
    LET futuresSymbol == ReadBytes(futuresExpiration.rest, 6) IN IF ~futuresSymbol.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(futuresSymbol.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET callPutIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~callPutIndicator.ok THEN Fail ELSE
    LET optionsExpiration == ReadBytes(callPutIndicator.rest, 4) IN IF ~optionsExpiration.ok THEN Fail ELSE
    LET optionsOnFuturesName == ReadBytes(optionsExpiration.rest, 16) IN IF ~optionsOnFuturesName.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(optionsOnFuturesName.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         feedSymbol           |-> feedSymbol.value,
         futuresProduct       |-> futuresProduct.value,
         futuresExpiration    |-> futuresExpiration.value,
         futuresSymbol        |-> futuresSymbol.value,
         strikePrice          |-> strikePrice.value,
         callPutIndicator     |-> callPutIndicator.value,
         optionsExpiration    |-> optionsExpiration.value,
         optionsOnFuturesName |-> optionsOnFuturesName.value,
         symbolCondition      |-> symbolCondition.value ], symbolCondition.rest)

ZeroOofSymbolMappingMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      feedSymbol           |-> [i \in 1 .. 6 |-> 0],
      futuresProduct       |-> [i \in 1 .. 8 |-> 0],
      futuresExpiration    |-> [i \in 1 .. 4 |-> 0],
      futuresSymbol        |-> [i \in 1 .. 6 |-> 0],
      strikePrice          |-> [i \in 1 .. 8 |-> 0],
      callPutIndicator     |-> [i \in 1 .. 1 |-> 0],
      optionsExpiration    |-> [i \in 1 .. 4 |-> 0],
      optionsOnFuturesName |-> [i \in 1 .. 16 |-> 0],
      symbolCondition      |-> [i \in 1 .. 1 |-> 0] ]

(* Oof Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedOofSymbolMappingMessage ==
    { ZeroOofSymbolMappingMessage }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.futuresProduct = one] : one \in Sample(8) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.futuresExpiration = one] : one \in Sample(4) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.futuresSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.callPutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.optionsExpiration = one] : one \in Sample(4) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.optionsOnFuturesName = one] : one \in Sample(16) }
        \cup { [ZeroOofSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Leg: 13 bytes                                                    *)
(***************************************************************************)

OptionLeg ==
    [ legSymbol       : Sample(8),
      legRatio        : Sample(4),
      legSecurityType : Sample(1) ]

EncodeOptionLeg(message) ==
    message.legSymbol
        \o message.legRatio
        \o message.legSecurityType

DecodeOptionLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbol.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatio.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ legSymbol       |-> legSymbol.value,
         legRatio        |-> legRatio.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroOptionLeg ==
    [ legSymbol       |-> [i \in 1 .. 8 |-> 0],
      legRatio        |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Option Leg at zero, then each field in turn at the values it is checked at *)
CheckedOptionLeg ==
    { ZeroOptionLeg }
        \cup { [ZeroOptionLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroOptionLeg EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Option Leg, written one after another *)
RECURSIVE EncodeOptionLegList(_)
EncodeOptionLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOptionLeg(Head(messages)) \o EncodeOptionLegList(Tail(messages))

(* As many Option Leg as the field that counts them says *)
RECURSIVE ReadOptionLegList(_, _)
ReadOptionLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOptionLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOptionLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Option Leg of each kind, for the lists that carry them *)
OneOptionLeg == { ZeroOptionLeg }

(***************************************************************************)
(* Complex Instrument Definition Expanded Message                          *)
(***************************************************************************)

ComplexInstrumentDefinitionExpandedMessage ==
    [ timeOffset                  : Sample(4),
      complexInstrumentId         : Sample(6),
      complexInstrumentUnderlying : Sample(8),
      complexInstrumentType       : Sample(4),
      optionLeg                   : SampleLists(OneOptionLeg) ]

EncodeComplexInstrumentDefinitionExpandedMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId
        \o message.complexInstrumentUnderlying
        \o message.complexInstrumentType
        \o EncodeUIntLE(Len(message.optionLeg), 1)
        \o EncodeOptionLegList(message.optionLeg)

DecodeComplexInstrumentDefinitionExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET complexInstrumentUnderlying == ReadBytes(complexInstrumentId.rest, 8) IN IF ~complexInstrumentUnderlying.ok THEN Fail ELSE
    LET complexInstrumentType == ReadBytes(complexInstrumentUnderlying.rest, 4) IN IF ~complexInstrumentType.ok THEN Fail ELSE
    LET legCount == ReadUIntLE(complexInstrumentType.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET optionLeg == ReadOptionLegList(legCount.rest, legCount.value) IN IF ~optionLeg.ok THEN Fail ELSE
    Ok([ timeOffset                  |-> timeOffset.value,
         complexInstrumentId         |-> complexInstrumentId.value,
         complexInstrumentUnderlying |-> complexInstrumentUnderlying.value,
         complexInstrumentType       |-> complexInstrumentType.value,
         optionLeg                   |-> optionLeg.value ], optionLeg.rest)

ZeroComplexInstrumentDefinitionExpandedMessage ==
    [ timeOffset                  |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId         |-> [i \in 1 .. 6 |-> 0],
      complexInstrumentUnderlying |-> [i \in 1 .. 8 |-> 0],
      complexInstrumentType       |-> [i \in 1 .. 4 |-> 0],
      optionLeg                   |-> << >> ]

(* Complex Instrument Definition Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionExpandedMessage ==
    { ZeroComplexInstrumentDefinitionExpandedMessage }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentUnderlying = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.complexInstrumentType = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionExpandedMessage EXCEPT !.optionLeg = one] : one \in SampleLists(OneOptionLeg) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset    : Sample(4),
      symbol        : Sample(6),
      reserved2     : Sample(2),
      tradingStatus : Sample(1),
      reserved3     : Sample(3) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.reserved2
        \o message.tradingStatus
        \o message.reserved3

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(symbol.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reserved2.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(tradingStatus.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         symbol        |-> symbol.value,
         reserved2     |-> reserved2.value,
         tradingStatus |-> tradingStatus.value,
         reserved3     |-> reserved3.value ], reserved3.rest)

ZeroTradingStatusMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      reserved3     |-> [i \in 1 .. 3 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Add Order Long Message: 31 bytes                                        *)
(***************************************************************************)

AddOrderLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityLong  : Sample(4),
      symbol        : Sample(6),
      priceLong     : Sample(8) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbol
        \o message.priceLong

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityLong.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbol.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbol        |-> symbol.value,
         priceLong     |-> priceLong.value ], priceLong.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Short Message: 23 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbol        : Sample(6),
      priceShort    : Sample(2) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbol
        \o message.priceShort

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityShort.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbol.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityShort |-> quantityShort.value,
         symbol        |-> symbol.value,
         priceShort    |-> priceShort.value ], priceShort.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }

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
(* Modify Order Long Message: 24 bytes                                     *)
(***************************************************************************)

ModifyOrderLongMessage ==
    [ timeOffset   : Sample(4),
      orderId      : Sample(8),
      quantityLong : Sample(4),
      priceLong    : Sample(8) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityLong
        \o message.priceLong

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(orderId.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(quantityLong.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timeOffset   |-> timeOffset.value,
         orderId      |-> orderId.value,
         quantityLong |-> quantityLong.value,
         priceLong    |-> priceLong.value ], priceLong.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 4 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Short Message: 16 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      quantityShort : Sample(2),
      priceShort    : Sample(2) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityShort
        \o message.priceShort

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(orderId.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantityShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         quantityShort |-> quantityShort.value,
         priceShort    |-> priceShort.value ], priceShort.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }

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
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      quantityLong   : Sample(4),
      symbol         : Sample(6),
      priceLong      : Sample(8),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbol
        \o message.priceLong
        \o message.executionId
        \o message.tradeCondition

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityLong.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbol.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         quantityLong   |-> quantityLong.value,
         symbol         |-> symbol.value,
         priceLong      |-> priceLong.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeLongMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      quantityLong   |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      priceLong      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 32 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      quantityShort  : Sample(2),
      symbol         : Sample(6),
      priceShort     : Sample(2),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbol
        \o message.priceShort
        \o message.executionId
        \o message.tradeCondition

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityShort.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbol.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         quantityShort  |-> quantityShort.value,
         symbol         |-> symbol.value,
         priceShort     |-> priceShort.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeShortMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      quantityShort  |-> [i \in 1 .. 2 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      priceShort     |-> [i \in 1 .. 2 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Break Message: 12 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timeOffset  : Sample(4),
      executionId : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.timeOffset
        \o message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executionId == ReadBytes(timeOffset.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Settlement Message: 23 bytes                                            *)
(***************************************************************************)

SettlementMessage ==
    [ timeOffset      : Sample(4),
      symbol          : Sample(6),
      tradeDate       : Sample(4),
      settlementPrice : Sample(8),
      issue           : Sample(1) ]

EncodeSettlementMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.tradeDate
        \o message.settlementPrice
        \o message.issue

DecodeSettlementMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(symbol.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(tradeDate.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET issue == ReadBytes(settlementPrice.rest, 1) IN IF ~issue.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         symbol          |-> symbol.value,
         tradeDate       |-> tradeDate.value,
         settlementPrice |-> settlementPrice.value,
         issue           |-> issue.value ], issue.rest)

ZeroSettlementMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      tradeDate       |-> [i \in 1 .. 4 |-> 0],
      settlementPrice |-> [i \in 1 .. 8 |-> 0],
      issue           |-> [i \in 1 .. 1 |-> 0] ]

(* Settlement Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementMessage ==
    { ZeroSettlementMessage }
        \cup { [ZeroSettlementMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSettlementMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroSettlementMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroSettlementMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSettlementMessage EXCEPT !.issue = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Day Summary Message: 63 bytes                                    *)
(***************************************************************************)

EndOfDaySummaryMessage ==
    [ timeOffset   : Sample(4),
      symbol       : Sample(6),
      tradeDate    : Sample(4),
      openInterest : Sample(4),
      highPrice    : Sample(8),
      lowPrice     : Sample(8),
      openPrice    : Sample(8),
      closePrice   : Sample(8),
      totalVolume  : Sample(4),
      blockVolume  : Sample(4),
      ecrpVolume   : Sample(4),
      summaryFlags : Sample(1) ]

EncodeEndOfDaySummaryMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.tradeDate
        \o message.openInterest
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.closePrice
        \o message.totalVolume
        \o message.blockVolume
        \o message.ecrpVolume
        \o message.summaryFlags

DecodeEndOfDaySummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(symbol.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET openInterest == ReadBytes(tradeDate.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openInterest.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET closePrice == ReadBytes(openPrice.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(closePrice.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET blockVolume == ReadBytes(totalVolume.rest, 4) IN IF ~blockVolume.ok THEN Fail ELSE
    LET ecrpVolume == ReadBytes(blockVolume.rest, 4) IN IF ~ecrpVolume.ok THEN Fail ELSE
    LET summaryFlags == ReadBytes(ecrpVolume.rest, 1) IN IF ~summaryFlags.ok THEN Fail ELSE
    Ok([ timeOffset   |-> timeOffset.value,
         symbol       |-> symbol.value,
         tradeDate    |-> tradeDate.value,
         openInterest |-> openInterest.value,
         highPrice    |-> highPrice.value,
         lowPrice     |-> lowPrice.value,
         openPrice    |-> openPrice.value,
         closePrice   |-> closePrice.value,
         totalVolume  |-> totalVolume.value,
         blockVolume  |-> blockVolume.value,
         ecrpVolume   |-> ecrpVolume.value,
         summaryFlags |-> summaryFlags.value ], summaryFlags.rest)

ZeroEndOfDaySummaryMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      symbol       |-> [i \in 1 .. 6 |-> 0],
      tradeDate    |-> [i \in 1 .. 4 |-> 0],
      openInterest |-> [i \in 1 .. 4 |-> 0],
      highPrice    |-> [i \in 1 .. 8 |-> 0],
      lowPrice     |-> [i \in 1 .. 8 |-> 0],
      openPrice    |-> [i \in 1 .. 8 |-> 0],
      closePrice   |-> [i \in 1 .. 8 |-> 0],
      totalVolume  |-> [i \in 1 .. 4 |-> 0],
      blockVolume  |-> [i \in 1 .. 4 |-> 0],
      ecrpVolume   |-> [i \in 1 .. 4 |-> 0],
      summaryFlags |-> [i \in 1 .. 1 |-> 0] ]

(* End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDaySummaryMessage ==
    { ZeroEndOfDaySummaryMessage }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.blockVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.ecrpVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.summaryFlags = one] : one \in Sample(1) }

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
TransactionBeginMessageCode == 188  \* 0xbc
TransactionEndMessageCode == 189  \* 0xbd
OofSymbolMappingMessageCode == 249  \* 0xf9
ComplexInstrumentDefinitionExpandedMessageCode == 154  \* 0x9a
TradingStatusMessageCode == 49  \* 0x31
AddOrderLongMessageCode == 33  \* 0x21
AddOrderShortMessageCode == 34  \* 0x22
OrderExecutedMessageCode == 35  \* 0x23
ReduceSizeLongMessageCode == 37  \* 0x25
ReduceSizeShortMessageCode == 38  \* 0x26
ModifyOrderLongMessageCode == 39  \* 0x27
ModifyOrderShortMessageCode == 40  \* 0x28
DeleteOrderMessageCode == 41  \* 0x29
TradeLongMessageCode == 42  \* 0x2a
TradeShortMessageCode == 43  \* 0x2b
TradeBreakMessageCode == 44  \* 0x2c
SettlementMessageCode == 185  \* 0xb9
EndOfDaySummaryMessageCode == 186  \* 0xba
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {TimeReferenceMessageCode}, body : TimeReferenceMessage ]
        \cup [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {TransactionBeginMessageCode}, body : TransactionBeginMessage ]
        \cup [ tag : {TransactionEndMessageCode}, body : TransactionEndMessage ]
        \cup [ tag : {OofSymbolMappingMessageCode}, body : OofSymbolMappingMessage ]
        \cup [ tag : {ComplexInstrumentDefinitionExpandedMessageCode}, body : ComplexInstrumentDefinitionExpandedMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {ReduceSizeLongMessageCode}, body : ReduceSizeLongMessage ]
        \cup [ tag : {ReduceSizeShortMessageCode}, body : ReduceSizeShortMessage ]
        \cup [ tag : {ModifyOrderLongMessageCode}, body : ModifyOrderLongMessage ]
        \cup [ tag : {ModifyOrderShortMessageCode}, body : ModifyOrderShortMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {TradeLongMessageCode}, body : TradeLongMessage ]
        \cup [ tag : {TradeShortMessageCode}, body : TradeShortMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {SettlementMessageCode}, body : SettlementMessage ]
        \cup [ tag : {EndOfDaySummaryMessageCode}, body : EndOfDaySummaryMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeReferenceMessageCode -> EncodeTimeReferenceMessage(message.body)
      [] message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = TransactionBeginMessageCode -> EncodeTransactionBeginMessage(message.body)
      [] message.tag = TransactionEndMessageCode -> EncodeTransactionEndMessage(message.body)
      [] message.tag = OofSymbolMappingMessageCode -> EncodeOofSymbolMappingMessage(message.body)
      [] message.tag = ComplexInstrumentDefinitionExpandedMessageCode -> EncodeComplexInstrumentDefinitionExpandedMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = ReduceSizeLongMessageCode -> EncodeReduceSizeLongMessage(message.body)
      [] message.tag = ReduceSizeShortMessageCode -> EncodeReduceSizeShortMessage(message.body)
      [] message.tag = ModifyOrderLongMessageCode -> EncodeModifyOrderLongMessage(message.body)
      [] message.tag = ModifyOrderShortMessageCode -> EncodeModifyOrderShortMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = TradeLongMessageCode -> EncodeTradeLongMessage(message.body)
      [] message.tag = TradeShortMessageCode -> EncodeTradeShortMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = SettlementMessageCode -> EncodeSettlementMessage(message.body)
      [] message.tag = EndOfDaySummaryMessageCode -> EncodeEndOfDaySummaryMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeReferenceMessageCode -> DecodeTimeReferenceMessage(bytes)
              [] tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = TransactionBeginMessageCode -> DecodeTransactionBeginMessage(bytes)
              [] tag = TransactionEndMessageCode -> DecodeTransactionEndMessage(bytes)
              [] tag = OofSymbolMappingMessageCode -> DecodeOofSymbolMappingMessage(bytes)
              [] tag = ComplexInstrumentDefinitionExpandedMessageCode -> DecodeComplexInstrumentDefinitionExpandedMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = ReduceSizeLongMessageCode -> DecodeReduceSizeLongMessage(bytes)
              [] tag = ReduceSizeShortMessageCode -> DecodeReduceSizeShortMessage(bytes)
              [] tag = ModifyOrderLongMessageCode -> DecodeModifyOrderLongMessage(bytes)
              [] tag = ModifyOrderShortMessageCode -> DecodeModifyOrderShortMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = TradeLongMessageCode -> DecodeTradeLongMessage(bytes)
              [] tag = TradeShortMessageCode -> DecodeTradeShortMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = SettlementMessageCode -> DecodeSettlementMessage(bytes)
              [] tag = EndOfDaySummaryMessageCode -> DecodeEndOfDaySummaryMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeReferenceMessageCode, body |-> ZeroTimeReferenceMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeReferenceMessageCode, body |-> one] : one \in CheckedTimeReferenceMessage }
        \cup { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> TransactionBeginMessageCode, body |-> one] : one \in CheckedTransactionBeginMessage }
        \cup { [tag |-> TransactionEndMessageCode, body |-> one] : one \in CheckedTransactionEndMessage }
        \cup { [tag |-> OofSymbolMappingMessageCode, body |-> one] : one \in CheckedOofSymbolMappingMessage }
        \cup { [tag |-> ComplexInstrumentDefinitionExpandedMessageCode, body |-> one] : one \in CheckedComplexInstrumentDefinitionExpandedMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> ReduceSizeLongMessageCode, body |-> one] : one \in CheckedReduceSizeLongMessage }
        \cup { [tag |-> ReduceSizeShortMessageCode, body |-> one] : one \in CheckedReduceSizeShortMessage }
        \cup { [tag |-> ModifyOrderLongMessageCode, body |-> one] : one \in CheckedModifyOrderLongMessage }
        \cup { [tag |-> ModifyOrderShortMessageCode, body |-> one] : one \in CheckedModifyOrderShortMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> TradeLongMessageCode, body |-> one] : one \in CheckedTradeLongMessage }
        \cup { [tag |-> TradeShortMessageCode, body |-> one] : one \in CheckedTradeShortMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> SettlementMessageCode, body |-> one] : one \in CheckedSettlementMessage }
        \cup { [tag |-> EndOfDaySummaryMessageCode, body |-> one] : one \in CheckedEndOfDaySummaryMessage }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionBeginMessageCode, body |-> ZeroTransactionBeginMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionEndMessageCode, body |-> ZeroTransactionEndMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OofSymbolMappingMessageCode, body |-> ZeroOofSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexInstrumentDefinitionExpandedMessageCode, body |-> ZeroComplexInstrumentDefinitionExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderLongMessageCode, body |-> ZeroAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderShortMessageCode, body |-> ZeroAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeLongMessageCode, body |-> ZeroReduceSizeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeShortMessageCode, body |-> ZeroReduceSizeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderLongMessageCode, body |-> ZeroModifyOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderShortMessageCode, body |-> ZeroModifyOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeLongMessageCode, body |-> ZeroTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeShortMessageCode, body |-> ZeroTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementMessageCode, body |-> ZeroSettlementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDaySummaryMessageCode, body |-> ZeroEndOfDaySummaryMessage]],
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

(* Every Oof Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOofSymbolMappingMessage ==
    \A message \in CheckedOofSymbolMappingMessage :
        LET read == DecodeOofSymbolMappingMessage(EncodeOofSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionLeg ==
    \A message \in CheckedOptionLeg :
        LET read == DecodeOptionLeg(EncodeOptionLeg(message))
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

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
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

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
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

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementMessage ==
    \A message \in CheckedSettlementMessage :
        LET read == DecodeSettlementMessage(EncodeSettlementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDaySummaryMessage ==
    \A message \in CheckedEndOfDaySummaryMessage :
        LET read == DecodeEndOfDaySummaryMessage(EncodeEndOfDaySummaryMessage(message))
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
