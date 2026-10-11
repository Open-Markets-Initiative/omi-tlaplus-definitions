--------------- MODULE CfeFutures_MulticastTop_Spin_v1_2_20 ----------------
(***************************************************************************)
(* Chicago Board Options Exchange Futures Multicast Top v1.2.20            *)
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
(* Note: Futures Flags is a bit field set, checked as its 1 byte rather    *)
(* than bit by bit.                                                        *)
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
(* Login Message: 20 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ sessionSubId : Sample(4),
      username     : Sample(4),
      filler       : Sample(2),
      password     : Sample(10) ]

EncodeLoginMessage(message) ==
    message.sessionSubId
        \o message.username
        \o message.filler
        \o message.password

DecodeLoginMessage(bytes) ==
    LET sessionSubId == ReadBytes(bytes, 4) IN IF ~sessionSubId.ok THEN Fail ELSE
    LET username == ReadBytes(sessionSubId.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET filler == ReadBytes(username.rest, 2) IN IF ~filler.ok THEN Fail ELSE
    LET password == ReadBytes(filler.rest, 10) IN IF ~password.ok THEN Fail ELSE
    Ok([ sessionSubId |-> sessionSubId.value,
         username     |-> username.value,
         filler       |-> filler.value,
         password     |-> password.value ], password.rest)

ZeroLoginMessage ==
    [ sessionSubId |-> [i \in 1 .. 4 |-> 0],
      username     |-> [i \in 1 .. 4 |-> 0],
      filler       |-> [i \in 1 .. 2 |-> 0],
      password     |-> [i \in 1 .. 10 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.sessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroLoginMessage EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroLoginMessage EXCEPT !.filler = one] : one \in Sample(2) }
        \cup { [ZeroLoginMessage EXCEPT !.password = one] : one \in Sample(10) }

(***************************************************************************)
(* Login Response Message: 1 bytes                                         *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginResponseStatus : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    Ok([ loginResponseStatus |-> loginResponseStatus.value ], loginResponseStatus.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Spin Image Available Message: 4 bytes                                   *)
(***************************************************************************)

SpinImageAvailableMessage ==
    [ sequence : Sample(4) ]

EncodeSpinImageAvailableMessage(message) ==
    message.sequence

DecodeSpinImageAvailableMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value ], sequence.rest)

ZeroSpinImageAvailableMessage ==
    [ sequence |-> [i \in 1 .. 4 |-> 0] ]

(* Spin Image Available Message at zero, then each field in turn at the values it is checked at *)
CheckedSpinImageAvailableMessage ==
    { ZeroSpinImageAvailableMessage }
        \cup { [ZeroSpinImageAvailableMessage EXCEPT !.sequence = one] : one \in Sample(4) }

(***************************************************************************)
(* Spin Request Message: 4 bytes                                           *)
(***************************************************************************)

SpinRequestMessage ==
    [ sequence : Sample(4) ]

EncodeSpinRequestMessage(message) ==
    message.sequence

DecodeSpinRequestMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value ], sequence.rest)

ZeroSpinRequestMessage ==
    [ sequence |-> [i \in 1 .. 4 |-> 0] ]

(* Spin Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSpinRequestMessage ==
    { ZeroSpinRequestMessage }
        \cup { [ZeroSpinRequestMessage EXCEPT !.sequence = one] : one \in Sample(4) }

(***************************************************************************)
(* Spin Response Message: 9 bytes                                          *)
(***************************************************************************)

SpinResponseMessage ==
    [ sequence           : Sample(4),
      orderCount         : Sample(4),
      spinResponseStatus : Sample(1) ]

EncodeSpinResponseMessage(message) ==
    message.sequence
        \o message.orderCount
        \o message.spinResponseStatus

DecodeSpinResponseMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET orderCount == ReadBytes(sequence.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET spinResponseStatus == ReadBytes(orderCount.rest, 1) IN IF ~spinResponseStatus.ok THEN Fail ELSE
    Ok([ sequence           |-> sequence.value,
         orderCount         |-> orderCount.value,
         spinResponseStatus |-> spinResponseStatus.value ], spinResponseStatus.rest)

ZeroSpinResponseMessage ==
    [ sequence           |-> [i \in 1 .. 4 |-> 0],
      orderCount         |-> [i \in 1 .. 4 |-> 0],
      spinResponseStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Spin Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSpinResponseMessage ==
    { ZeroSpinResponseMessage }
        \cup { [ZeroSpinResponseMessage EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroSpinResponseMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroSpinResponseMessage EXCEPT !.spinResponseStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Spin Finished Message: 4 bytes                                          *)
(***************************************************************************)

SpinFinishedMessage ==
    [ sequence : Sample(4) ]

EncodeSpinFinishedMessage(message) ==
    message.sequence

DecodeSpinFinishedMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value ], sequence.rest)

ZeroSpinFinishedMessage ==
    [ sequence |-> [i \in 1 .. 4 |-> 0] ]

(* Spin Finished Message at zero, then each field in turn at the values it is checked at *)
CheckedSpinFinishedMessage ==
    { ZeroSpinFinishedMessage }
        \cup { [ZeroSpinFinishedMessage EXCEPT !.sequence = one] : one \in Sample(4) }

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
(* Future Leg: 10 bytes                                                    *)
(***************************************************************************)

FutureLeg ==
    [ legRatio  : Sample(4),
      legSymbol : Sample(6) ]

EncodeFutureLeg(message) ==
    message.legRatio
        \o message.legSymbol

DecodeFutureLeg(bytes) ==
    LET legRatio == ReadBytes(bytes, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legRatio.rest, 6) IN IF ~legSymbol.ok THEN Fail ELSE
    Ok([ legRatio  |-> legRatio.value,
         legSymbol |-> legSymbol.value ], legSymbol.rest)

ZeroFutureLeg ==
    [ legRatio  |-> [i \in 1 .. 4 |-> 0],
      legSymbol |-> [i \in 1 .. 6 |-> 0] ]

(* Future Leg at zero, then each field in turn at the values it is checked at *)
CheckedFutureLeg ==
    { ZeroFutureLeg }
        \cup { [ZeroFutureLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroFutureLeg EXCEPT !.legSymbol = one] : one \in Sample(6) }

(* A run of Future Leg, written one after another *)
RECURSIVE EncodeFutureLegList(_)
EncodeFutureLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFutureLeg(Head(messages)) \o EncodeFutureLegList(Tail(messages))

(* As many Future Leg as the field that counts them says *)
RECURSIVE ReadFutureLegList(_, _)
ReadFutureLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFutureLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFutureLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Future Leg of each kind, for the lists that carry them *)
OneFutureLeg == { ZeroFutureLeg }

(***************************************************************************)
(* Futures Instrument Definition Message                                   *)
(***************************************************************************)

FuturesInstrumentDefinitionMessage ==
    [ timeOffset     : Sample(4),
      symbol         : Sample(6),
      unitTimestamp  : Sample(4),
      reportSymbol   : Sample(6),
      futuresFlags   : Sample(1),
      expirationDate : Sample(4),
      contractSize   : Sample(2),
      listingState   : Sample(1),
      priceIncrement : Sample(8),
      legOffset      : Sample(1),
      reserved1      : Sample(1),
      contractDate   : Sample(4),
      futureLeg      : SampleLists(OneFutureLeg) ]

EncodeFuturesInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.unitTimestamp
        \o message.reportSymbol
        \o message.futuresFlags
        \o message.expirationDate
        \o message.contractSize
        \o message.listingState
        \o message.priceIncrement
        \o EncodeUIntLE(Len(message.futureLeg), 1)
        \o message.legOffset
        \o message.reserved1
        \o message.contractDate
        \o EncodeFutureLegList(message.futureLeg)

DecodeFuturesInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET unitTimestamp == ReadBytes(symbol.rest, 4) IN IF ~unitTimestamp.ok THEN Fail ELSE
    LET reportSymbol == ReadBytes(unitTimestamp.rest, 6) IN IF ~reportSymbol.ok THEN Fail ELSE
    LET futuresFlags == ReadBytes(reportSymbol.rest, 1) IN IF ~futuresFlags.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(futuresFlags.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET contractSize == ReadBytes(expirationDate.rest, 2) IN IF ~contractSize.ok THEN Fail ELSE
    LET listingState == ReadBytes(contractSize.rest, 1) IN IF ~listingState.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(listingState.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    LET legCount == ReadUIntLE(priceIncrement.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET legOffset == ReadBytes(legCount.rest, 1) IN IF ~legOffset.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(legOffset.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET contractDate == ReadBytes(reserved1.rest, 4) IN IF ~contractDate.ok THEN Fail ELSE
    LET futureLeg == ReadFutureLegList(contractDate.rest, legCount.value) IN IF ~futureLeg.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         symbol         |-> symbol.value,
         unitTimestamp  |-> unitTimestamp.value,
         reportSymbol   |-> reportSymbol.value,
         futuresFlags   |-> futuresFlags.value,
         expirationDate |-> expirationDate.value,
         contractSize   |-> contractSize.value,
         listingState   |-> listingState.value,
         priceIncrement |-> priceIncrement.value,
         legOffset      |-> legOffset.value,
         reserved1      |-> reserved1.value,
         contractDate   |-> contractDate.value,
         futureLeg      |-> futureLeg.value ], futureLeg.rest)

ZeroFuturesInstrumentDefinitionMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      unitTimestamp  |-> [i \in 1 .. 4 |-> 0],
      reportSymbol   |-> [i \in 1 .. 6 |-> 0],
      futuresFlags   |-> [i \in 1 .. 1 |-> 0],
      expirationDate |-> [i \in 1 .. 4 |-> 0],
      contractSize   |-> [i \in 1 .. 2 |-> 0],
      listingState   |-> [i \in 1 .. 1 |-> 0],
      priceIncrement |-> [i \in 1 .. 8 |-> 0],
      legOffset      |-> [i \in 1 .. 1 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0],
      contractDate   |-> [i \in 1 .. 4 |-> 0],
      futureLeg      |-> << >> ]

(* Futures Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesInstrumentDefinitionMessage ==
    { ZeroFuturesInstrumentDefinitionMessage }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.unitTimestamp = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.reportSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.futuresFlags = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.contractSize = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.listingState = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.priceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.legOffset = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.contractDate = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.futureLeg = one] : one \in SampleLists(OneFutureLeg) }

(***************************************************************************)
(* Futures Variance Symbol Mapping Message: 38 bytes                       *)
(***************************************************************************)

FuturesVarianceSymbolMappingMessage ==
    [ timeOffset         : Sample(4),
      unitTimestamp      : Sample(4),
      feedSymbol         : Sample(6),
      futuresSymbol      : Sample(12),
      accruedDayVariance : Sample(8),
      numFinalReturns    : Sample(2),
      numElapsedReturns  : Sample(2) ]

EncodeFuturesVarianceSymbolMappingMessage(message) ==
    message.timeOffset
        \o message.unitTimestamp
        \o message.feedSymbol
        \o message.futuresSymbol
        \o message.accruedDayVariance
        \o message.numFinalReturns
        \o message.numElapsedReturns

DecodeFuturesVarianceSymbolMappingMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET unitTimestamp == ReadBytes(timeOffset.rest, 4) IN IF ~unitTimestamp.ok THEN Fail ELSE
    LET feedSymbol == ReadBytes(unitTimestamp.rest, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET futuresSymbol == ReadBytes(feedSymbol.rest, 12) IN IF ~futuresSymbol.ok THEN Fail ELSE
    LET accruedDayVariance == ReadBytes(futuresSymbol.rest, 8) IN IF ~accruedDayVariance.ok THEN Fail ELSE
    LET numFinalReturns == ReadBytes(accruedDayVariance.rest, 2) IN IF ~numFinalReturns.ok THEN Fail ELSE
    LET numElapsedReturns == ReadBytes(numFinalReturns.rest, 2) IN IF ~numElapsedReturns.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         unitTimestamp      |-> unitTimestamp.value,
         feedSymbol         |-> feedSymbol.value,
         futuresSymbol      |-> futuresSymbol.value,
         accruedDayVariance |-> accruedDayVariance.value,
         numFinalReturns    |-> numFinalReturns.value,
         numElapsedReturns  |-> numElapsedReturns.value ], numElapsedReturns.rest)

ZeroFuturesVarianceSymbolMappingMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      unitTimestamp      |-> [i \in 1 .. 4 |-> 0],
      feedSymbol         |-> [i \in 1 .. 6 |-> 0],
      futuresSymbol      |-> [i \in 1 .. 12 |-> 0],
      accruedDayVariance |-> [i \in 1 .. 8 |-> 0],
      numFinalReturns    |-> [i \in 1 .. 2 |-> 0],
      numElapsedReturns  |-> [i \in 1 .. 2 |-> 0] ]

(* Futures Variance Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesVarianceSymbolMappingMessage ==
    { ZeroFuturesVarianceSymbolMappingMessage }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.unitTimestamp = one] : one \in Sample(4) }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.futuresSymbol = one] : one \in Sample(12) }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.accruedDayVariance = one] : one \in Sample(8) }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.numFinalReturns = one] : one \in Sample(2) }
        \cup { [ZeroFuturesVarianceSymbolMappingMessage EXCEPT !.numElapsedReturns = one] : one \in Sample(2) }

(***************************************************************************)
(* Price Limits Message: 26 bytes                                          *)
(***************************************************************************)

PriceLimitsMessage ==
    [ timeOffset      : Sample(4),
      symbol          : Sample(6),
      upperPriceLimit : Sample(8),
      lowerPriceLimit : Sample(8) ]

EncodePriceLimitsMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.upperPriceLimit
        \o message.lowerPriceLimit

DecodePriceLimitsMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET upperPriceLimit == ReadBytes(symbol.rest, 8) IN IF ~upperPriceLimit.ok THEN Fail ELSE
    LET lowerPriceLimit == ReadBytes(upperPriceLimit.rest, 8) IN IF ~lowerPriceLimit.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         symbol          |-> symbol.value,
         upperPriceLimit |-> upperPriceLimit.value,
         lowerPriceLimit |-> lowerPriceLimit.value ], lowerPriceLimit.rest)

ZeroPriceLimitsMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      upperPriceLimit |-> [i \in 1 .. 8 |-> 0],
      lowerPriceLimit |-> [i \in 1 .. 8 |-> 0] ]

(* Price Limits Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceLimitsMessage ==
    { ZeroPriceLimitsMessage }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.upperPriceLimit = one] : one \in Sample(8) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.lowerPriceLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Snapshot Short Message: 35 bytes                                 *)
(***************************************************************************)

MarketSnapshotShortMessage ==
    [ timeOffset          : Sample(4),
      symbol              : Sample(6),
      unitTimestamp       : Sample(4),
      bidPriceShort       : Sample(2),
      bidQuantityShort    : Sample(2),
      askPriceShort       : Sample(2),
      askQuantityShort    : Sample(2),
      lastTradePriceShort : Sample(2),
      lastTradeSizeShort  : Sample(2),
      lastTradeCondition  : Sample(1),
      totalVolume         : Sample(4),
      tradingStatus       : Sample(1),
      reserved3           : Sample(3) ]

EncodeMarketSnapshotShortMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.unitTimestamp
        \o message.bidPriceShort
        \o message.bidQuantityShort
        \o message.askPriceShort
        \o message.askQuantityShort
        \o message.lastTradePriceShort
        \o message.lastTradeSizeShort
        \o message.lastTradeCondition
        \o message.totalVolume
        \o message.tradingStatus
        \o message.reserved3

DecodeMarketSnapshotShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET unitTimestamp == ReadBytes(symbol.rest, 4) IN IF ~unitTimestamp.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(unitTimestamp.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidQuantityShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidQuantityShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidQuantityShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askQuantityShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askQuantityShort.ok THEN Fail ELSE
    LET lastTradePriceShort == ReadBytes(askQuantityShort.rest, 2) IN IF ~lastTradePriceShort.ok THEN Fail ELSE
    LET lastTradeSizeShort == ReadBytes(lastTradePriceShort.rest, 2) IN IF ~lastTradeSizeShort.ok THEN Fail ELSE
    LET lastTradeCondition == ReadBytes(lastTradeSizeShort.rest, 1) IN IF ~lastTradeCondition.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(lastTradeCondition.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(totalVolume.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(tradingStatus.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         symbol              |-> symbol.value,
         unitTimestamp       |-> unitTimestamp.value,
         bidPriceShort       |-> bidPriceShort.value,
         bidQuantityShort    |-> bidQuantityShort.value,
         askPriceShort       |-> askPriceShort.value,
         askQuantityShort    |-> askQuantityShort.value,
         lastTradePriceShort |-> lastTradePriceShort.value,
         lastTradeSizeShort  |-> lastTradeSizeShort.value,
         lastTradeCondition  |-> lastTradeCondition.value,
         totalVolume         |-> totalVolume.value,
         tradingStatus       |-> tradingStatus.value,
         reserved3           |-> reserved3.value ], reserved3.rest)

ZeroMarketSnapshotShortMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      symbol              |-> [i \in 1 .. 6 |-> 0],
      unitTimestamp       |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      bidQuantityShort    |-> [i \in 1 .. 2 |-> 0],
      askPriceShort       |-> [i \in 1 .. 2 |-> 0],
      askQuantityShort    |-> [i \in 1 .. 2 |-> 0],
      lastTradePriceShort |-> [i \in 1 .. 2 |-> 0],
      lastTradeSizeShort  |-> [i \in 1 .. 2 |-> 0],
      lastTradeCondition  |-> [i \in 1 .. 1 |-> 0],
      totalVolume         |-> [i \in 1 .. 4 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved3           |-> [i \in 1 .. 3 |-> 0] ]

(* Market Snapshot Short Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSnapshotShortMessage ==
    { ZeroMarketSnapshotShortMessage }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.unitTimestamp = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.bidQuantityShort = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.askQuantityShort = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.lastTradePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.lastTradeSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.lastTradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotShortMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Market Snapshot Long Message: 59 bytes                                  *)
(***************************************************************************)

MarketSnapshotLongMessage ==
    [ timeOffset         : Sample(4),
      symbol             : Sample(6),
      unitTimestamp      : Sample(4),
      bidPriceLong       : Sample(8),
      bidQuantityLong    : Sample(4),
      askPriceLong       : Sample(8),
      askQuantityLong    : Sample(4),
      lastTradePriceLong : Sample(8),
      lastTradeSizeLong  : Sample(4),
      lastTradeCondition : Sample(1),
      totalVolume        : Sample(4),
      tradingStatus      : Sample(1),
      reserved3          : Sample(3) ]

EncodeMarketSnapshotLongMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.unitTimestamp
        \o message.bidPriceLong
        \o message.bidQuantityLong
        \o message.askPriceLong
        \o message.askQuantityLong
        \o message.lastTradePriceLong
        \o message.lastTradeSizeLong
        \o message.lastTradeCondition
        \o message.totalVolume
        \o message.tradingStatus
        \o message.reserved3

DecodeMarketSnapshotLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET unitTimestamp == ReadBytes(symbol.rest, 4) IN IF ~unitTimestamp.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(unitTimestamp.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidQuantityLong.rest, 8) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askQuantityLong.ok THEN Fail ELSE
    LET lastTradePriceLong == ReadBytes(askQuantityLong.rest, 8) IN IF ~lastTradePriceLong.ok THEN Fail ELSE
    LET lastTradeSizeLong == ReadBytes(lastTradePriceLong.rest, 4) IN IF ~lastTradeSizeLong.ok THEN Fail ELSE
    LET lastTradeCondition == ReadBytes(lastTradeSizeLong.rest, 1) IN IF ~lastTradeCondition.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(lastTradeCondition.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(totalVolume.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(tradingStatus.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         symbol             |-> symbol.value,
         unitTimestamp      |-> unitTimestamp.value,
         bidPriceLong       |-> bidPriceLong.value,
         bidQuantityLong    |-> bidQuantityLong.value,
         askPriceLong       |-> askPriceLong.value,
         askQuantityLong    |-> askQuantityLong.value,
         lastTradePriceLong |-> lastTradePriceLong.value,
         lastTradeSizeLong  |-> lastTradeSizeLong.value,
         lastTradeCondition |-> lastTradeCondition.value,
         totalVolume        |-> totalVolume.value,
         tradingStatus      |-> tradingStatus.value,
         reserved3          |-> reserved3.value ], reserved3.rest)

ZeroMarketSnapshotLongMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      symbol             |-> [i \in 1 .. 6 |-> 0],
      unitTimestamp      |-> [i \in 1 .. 4 |-> 0],
      bidPriceLong       |-> [i \in 1 .. 8 |-> 0],
      bidQuantityLong    |-> [i \in 1 .. 4 |-> 0],
      askPriceLong       |-> [i \in 1 .. 8 |-> 0],
      askQuantityLong    |-> [i \in 1 .. 4 |-> 0],
      lastTradePriceLong |-> [i \in 1 .. 8 |-> 0],
      lastTradeSizeLong  |-> [i \in 1 .. 4 |-> 0],
      lastTradeCondition |-> [i \in 1 .. 1 |-> 0],
      totalVolume        |-> [i \in 1 .. 4 |-> 0],
      tradingStatus      |-> [i \in 1 .. 1 |-> 0],
      reserved3          |-> [i \in 1 .. 3 |-> 0] ]

(* Market Snapshot Long Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSnapshotLongMessage ==
    { ZeroMarketSnapshotLongMessage }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.unitTimestamp = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.askPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.askQuantityLong = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.lastTradePriceLong = one] : one \in Sample(8) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.lastTradeSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.lastTradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketSnapshotLongMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

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
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginMessageCode == 1  \* 0x01
LoginResponseMessageCode == 2  \* 0x02
SpinImageAvailableMessageCode == 128  \* 0x80
SpinRequestMessageCode == 129  \* 0x81
SpinResponseMessageCode == 130  \* 0x82
SpinFinishedMessageCode == 131  \* 0x83
TimeReferenceMessageCode == 177  \* 0xb1
TimeMessageCode == 32  \* 0x20
FuturesInstrumentDefinitionMessageCode == 187  \* 0xbb
FuturesVarianceSymbolMappingMessageCode == 250  \* 0xfa
PriceLimitsMessageCode == 190  \* 0xbe
MarketSnapshotShortMessageCode == 178  \* 0xb2
MarketSnapshotLongMessageCode == 179  \* 0xb3
SettlementMessageCode == 185  \* 0xb9
EndOfDaySummaryMessageCode == 186  \* 0xba

Payload ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {SpinImageAvailableMessageCode}, body : SpinImageAvailableMessage ]
        \cup [ tag : {SpinRequestMessageCode}, body : SpinRequestMessage ]
        \cup [ tag : {SpinResponseMessageCode}, body : SpinResponseMessage ]
        \cup [ tag : {SpinFinishedMessageCode}, body : SpinFinishedMessage ]
        \cup [ tag : {TimeReferenceMessageCode}, body : TimeReferenceMessage ]
        \cup [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {FuturesInstrumentDefinitionMessageCode}, body : FuturesInstrumentDefinitionMessage ]
        \cup [ tag : {FuturesVarianceSymbolMappingMessageCode}, body : FuturesVarianceSymbolMappingMessage ]
        \cup [ tag : {PriceLimitsMessageCode}, body : PriceLimitsMessage ]
        \cup [ tag : {MarketSnapshotShortMessageCode}, body : MarketSnapshotShortMessage ]
        \cup [ tag : {MarketSnapshotLongMessageCode}, body : MarketSnapshotLongMessage ]
        \cup [ tag : {SettlementMessageCode}, body : SettlementMessage ]
        \cup [ tag : {EndOfDaySummaryMessageCode}, body : EndOfDaySummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = SpinImageAvailableMessageCode -> EncodeSpinImageAvailableMessage(message.body)
      [] message.tag = SpinRequestMessageCode -> EncodeSpinRequestMessage(message.body)
      [] message.tag = SpinResponseMessageCode -> EncodeSpinResponseMessage(message.body)
      [] message.tag = SpinFinishedMessageCode -> EncodeSpinFinishedMessage(message.body)
      [] message.tag = TimeReferenceMessageCode -> EncodeTimeReferenceMessage(message.body)
      [] message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = FuturesInstrumentDefinitionMessageCode -> EncodeFuturesInstrumentDefinitionMessage(message.body)
      [] message.tag = FuturesVarianceSymbolMappingMessageCode -> EncodeFuturesVarianceSymbolMappingMessage(message.body)
      [] message.tag = PriceLimitsMessageCode -> EncodePriceLimitsMessage(message.body)
      [] message.tag = MarketSnapshotShortMessageCode -> EncodeMarketSnapshotShortMessage(message.body)
      [] message.tag = MarketSnapshotLongMessageCode -> EncodeMarketSnapshotLongMessage(message.body)
      [] message.tag = SettlementMessageCode -> EncodeSettlementMessage(message.body)
      [] message.tag = EndOfDaySummaryMessageCode -> EncodeEndOfDaySummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = SpinImageAvailableMessageCode -> DecodeSpinImageAvailableMessage(bytes)
              [] tag = SpinRequestMessageCode -> DecodeSpinRequestMessage(bytes)
              [] tag = SpinResponseMessageCode -> DecodeSpinResponseMessage(bytes)
              [] tag = SpinFinishedMessageCode -> DecodeSpinFinishedMessage(bytes)
              [] tag = TimeReferenceMessageCode -> DecodeTimeReferenceMessage(bytes)
              [] tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = FuturesInstrumentDefinitionMessageCode -> DecodeFuturesInstrumentDefinitionMessage(bytes)
              [] tag = FuturesVarianceSymbolMappingMessageCode -> DecodeFuturesVarianceSymbolMappingMessage(bytes)
              [] tag = PriceLimitsMessageCode -> DecodePriceLimitsMessage(bytes)
              [] tag = MarketSnapshotShortMessageCode -> DecodeMarketSnapshotShortMessage(bytes)
              [] tag = MarketSnapshotLongMessageCode -> DecodeMarketSnapshotLongMessage(bytes)
              [] tag = SettlementMessageCode -> DecodeSettlementMessage(bytes)
              [] tag = EndOfDaySummaryMessageCode -> DecodeEndOfDaySummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> SpinImageAvailableMessageCode, body |-> one] : one \in CheckedSpinImageAvailableMessage }
        \cup { [tag |-> SpinRequestMessageCode, body |-> one] : one \in CheckedSpinRequestMessage }
        \cup { [tag |-> SpinResponseMessageCode, body |-> one] : one \in CheckedSpinResponseMessage }
        \cup { [tag |-> SpinFinishedMessageCode, body |-> one] : one \in CheckedSpinFinishedMessage }
        \cup { [tag |-> TimeReferenceMessageCode, body |-> one] : one \in CheckedTimeReferenceMessage }
        \cup { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> FuturesInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedFuturesInstrumentDefinitionMessage }
        \cup { [tag |-> FuturesVarianceSymbolMappingMessageCode, body |-> one] : one \in CheckedFuturesVarianceSymbolMappingMessage }
        \cup { [tag |-> PriceLimitsMessageCode, body |-> one] : one \in CheckedPriceLimitsMessage }
        \cup { [tag |-> MarketSnapshotShortMessageCode, body |-> one] : one \in CheckedMarketSnapshotShortMessage }
        \cup { [tag |-> MarketSnapshotLongMessageCode, body |-> one] : one \in CheckedMarketSnapshotLongMessage }
        \cup { [tag |-> SettlementMessageCode, body |-> one] : one \in CheckedSettlementMessage }
        \cup { [tag |-> EndOfDaySummaryMessageCode, body |-> one] : one \in CheckedEndOfDaySummaryMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpinImageAvailableMessageCode, body |-> ZeroSpinImageAvailableMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpinRequestMessageCode, body |-> ZeroSpinRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpinResponseMessageCode, body |-> ZeroSpinResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpinFinishedMessageCode, body |-> ZeroSpinFinishedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TimeReferenceMessageCode, body |-> ZeroTimeReferenceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FuturesInstrumentDefinitionMessageCode, body |-> ZeroFuturesInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FuturesVarianceSymbolMappingMessageCode, body |-> ZeroFuturesVarianceSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceLimitsMessageCode, body |-> ZeroPriceLimitsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketSnapshotShortMessageCode, body |-> ZeroMarketSnapshotShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketSnapshotLongMessageCode, body |-> ZeroMarketSnapshotLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementMessageCode, body |-> ZeroSettlementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDaySummaryMessageCode, body |-> ZeroEndOfDaySummaryMessage]] }

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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spin Image Available Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpinImageAvailableMessage ==
    \A message \in CheckedSpinImageAvailableMessage :
        LET read == DecodeSpinImageAvailableMessage(EncodeSpinImageAvailableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spin Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpinRequestMessage ==
    \A message \in CheckedSpinRequestMessage :
        LET read == DecodeSpinRequestMessage(EncodeSpinRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spin Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpinResponseMessage ==
    \A message \in CheckedSpinResponseMessage :
        LET read == DecodeSpinResponseMessage(EncodeSpinResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spin Finished Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpinFinishedMessage ==
    \A message \in CheckedSpinFinishedMessage :
        LET read == DecodeSpinFinishedMessage(EncodeSpinFinishedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Future Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureLeg ==
    \A message \in CheckedFutureLeg :
        LET read == DecodeFutureLeg(EncodeFutureLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesInstrumentDefinitionMessage ==
    \A message \in CheckedFuturesInstrumentDefinitionMessage :
        LET read == DecodeFuturesInstrumentDefinitionMessage(EncodeFuturesInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Variance Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesVarianceSymbolMappingMessage ==
    \A message \in CheckedFuturesVarianceSymbolMappingMessage :
        LET read == DecodeFuturesVarianceSymbolMappingMessage(EncodeFuturesVarianceSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Limits Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLimitsMessage ==
    \A message \in CheckedPriceLimitsMessage :
        LET read == DecodePriceLimitsMessage(EncodePriceLimitsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Snapshot Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSnapshotShortMessage ==
    \A message \in CheckedMarketSnapshotShortMessage :
        LET read == DecodeMarketSnapshotShortMessage(EncodeMarketSnapshotShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Snapshot Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSnapshotLongMessage ==
    \A message \in CheckedMarketSnapshotLongMessage :
        LET read == DecodeMarketSnapshotLongMessage(EncodeMarketSnapshotLongMessage(message))
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
