-------------------- MODULE C1Options_Flex_Spin_v1_1_30 --------------------
(***************************************************************************)
(* Chicago Board Options Exchange Flex v1.1.30                             *)
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
(* Note: Bit Fields is a bit field set, checked as its 1 byte rather than  *)
(* bit by bit.                                                             *)
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
(* Instrument Definition Request Message: 4 bytes                          *)
(***************************************************************************)

InstrumentDefinitionRequestMessage ==
    [ sequence : Sample(4) ]

EncodeInstrumentDefinitionRequestMessage(message) ==
    message.sequence

DecodeInstrumentDefinitionRequestMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value ], sequence.rest)

ZeroInstrumentDefinitionRequestMessage ==
    [ sequence |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Definition Request Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionRequestMessage ==
    { ZeroInstrumentDefinitionRequestMessage }
        \cup { [ZeroInstrumentDefinitionRequestMessage EXCEPT !.sequence = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Definition Response Message: 9 bytes                         *)
(***************************************************************************)

InstrumentDefinitionResponseMessage ==
    [ sequence                           : Sample(4),
      instrumentCount                    : Sample(4),
      instrumentDefinitionResponseStatus : Sample(1) ]

EncodeInstrumentDefinitionResponseMessage(message) ==
    message.sequence
        \o message.instrumentCount
        \o message.instrumentDefinitionResponseStatus

DecodeInstrumentDefinitionResponseMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET instrumentCount == ReadBytes(sequence.rest, 4) IN IF ~instrumentCount.ok THEN Fail ELSE
    LET instrumentDefinitionResponseStatus == ReadBytes(instrumentCount.rest, 1) IN IF ~instrumentDefinitionResponseStatus.ok THEN Fail ELSE
    Ok([ sequence                           |-> sequence.value,
         instrumentCount                    |-> instrumentCount.value,
         instrumentDefinitionResponseStatus |-> instrumentDefinitionResponseStatus.value ], instrumentDefinitionResponseStatus.rest)

ZeroInstrumentDefinitionResponseMessage ==
    [ sequence                           |-> [i \in 1 .. 4 |-> 0],
      instrumentCount                    |-> [i \in 1 .. 4 |-> 0],
      instrumentDefinitionResponseStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Definition Response Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionResponseMessage ==
    { ZeroInstrumentDefinitionResponseMessage }
        \cup { [ZeroInstrumentDefinitionResponseMessage EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinitionResponseMessage EXCEPT !.instrumentCount = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinitionResponseMessage EXCEPT !.instrumentDefinitionResponseStatus = one] : one \in Sample(1) }

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
(* Flex Instrument Definition Message: 55 bytes                            *)
(***************************************************************************)

FlexInstrumentDefinitionMessage ==
    [ timeOffset          : Sample(4),
      feedSymbol          : Sample(6),
      osiRoot             : Sample(6),
      year                : Sample(2),
      month               : Sample(2),
      day                 : Sample(2),
      callPutIndicator    : Sample(1),
      dollarStrike        : Sample(5),
      decimalStrike       : Sample(3),
      symbolCondition     : Sample(1),
      underlying          : Sample(8),
      exerciseStyle       : Sample(1),
      settlementType      : Sample(1),
      percentage          : Sample(4),
      observationDay      : Sample(2),
      returnCapPercentage : Sample(4),
      creationDay         : Sample(2),
      bitFields           : Sample(1) ]

EncodeFlexInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.feedSymbol
        \o message.osiRoot
        \o message.year
        \o message.month
        \o message.day
        \o message.callPutIndicator
        \o message.dollarStrike
        \o message.decimalStrike
        \o message.symbolCondition
        \o message.underlying
        \o message.exerciseStyle
        \o message.settlementType
        \o message.percentage
        \o message.observationDay
        \o message.returnCapPercentage
        \o message.creationDay
        \o message.bitFields

DecodeFlexInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET feedSymbol == ReadBytes(timeOffset.rest, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiRoot == ReadBytes(feedSymbol.rest, 6) IN IF ~osiRoot.ok THEN Fail ELSE
    LET year == ReadBytes(osiRoot.rest, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET callPutIndicator == ReadBytes(day.rest, 1) IN IF ~callPutIndicator.ok THEN Fail ELSE
    LET dollarStrike == ReadBytes(callPutIndicator.rest, 5) IN IF ~dollarStrike.ok THEN Fail ELSE
    LET decimalStrike == ReadBytes(dollarStrike.rest, 3) IN IF ~decimalStrike.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(decimalStrike.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(underlying.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET settlementType == ReadBytes(exerciseStyle.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET percentage == ReadBytes(settlementType.rest, 4) IN IF ~percentage.ok THEN Fail ELSE
    LET observationDay == ReadBytes(percentage.rest, 2) IN IF ~observationDay.ok THEN Fail ELSE
    LET returnCapPercentage == ReadBytes(observationDay.rest, 4) IN IF ~returnCapPercentage.ok THEN Fail ELSE
    LET creationDay == ReadBytes(returnCapPercentage.rest, 2) IN IF ~creationDay.ok THEN Fail ELSE
    LET bitFields == ReadBytes(creationDay.rest, 1) IN IF ~bitFields.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         feedSymbol          |-> feedSymbol.value,
         osiRoot             |-> osiRoot.value,
         year                |-> year.value,
         month               |-> month.value,
         day                 |-> day.value,
         callPutIndicator    |-> callPutIndicator.value,
         dollarStrike        |-> dollarStrike.value,
         decimalStrike       |-> decimalStrike.value,
         symbolCondition     |-> symbolCondition.value,
         underlying          |-> underlying.value,
         exerciseStyle       |-> exerciseStyle.value,
         settlementType      |-> settlementType.value,
         percentage          |-> percentage.value,
         observationDay      |-> observationDay.value,
         returnCapPercentage |-> returnCapPercentage.value,
         creationDay         |-> creationDay.value,
         bitFields           |-> bitFields.value ], bitFields.rest)

ZeroFlexInstrumentDefinitionMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      feedSymbol          |-> [i \in 1 .. 6 |-> 0],
      osiRoot             |-> [i \in 1 .. 6 |-> 0],
      year                |-> [i \in 1 .. 2 |-> 0],
      month               |-> [i \in 1 .. 2 |-> 0],
      day                 |-> [i \in 1 .. 2 |-> 0],
      callPutIndicator    |-> [i \in 1 .. 1 |-> 0],
      dollarStrike        |-> [i \in 1 .. 5 |-> 0],
      decimalStrike       |-> [i \in 1 .. 3 |-> 0],
      symbolCondition     |-> [i \in 1 .. 1 |-> 0],
      underlying          |-> [i \in 1 .. 8 |-> 0],
      exerciseStyle       |-> [i \in 1 .. 1 |-> 0],
      settlementType      |-> [i \in 1 .. 1 |-> 0],
      percentage          |-> [i \in 1 .. 4 |-> 0],
      observationDay      |-> [i \in 1 .. 2 |-> 0],
      returnCapPercentage |-> [i \in 1 .. 4 |-> 0],
      creationDay         |-> [i \in 1 .. 2 |-> 0],
      bitFields           |-> [i \in 1 .. 1 |-> 0] ]

(* Flex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexInstrumentDefinitionMessage ==
    { ZeroFlexInstrumentDefinitionMessage }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.osiRoot = one] : one \in Sample(6) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.callPutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.dollarStrike = one] : one \in Sample(5) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.decimalStrike = one] : one \in Sample(3) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.percentage = one] : one \in Sample(4) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.observationDay = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.returnCapPercentage = one] : one \in Sample(4) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.creationDay = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.bitFields = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Flex Leg: 13 bytes                                              *)
(***************************************************************************)

ComplexFlexLeg ==
    [ legSymbol       : Sample(8),
      legRatio        : Sample(4),
      legSecurityType : Sample(1) ]

EncodeComplexFlexLeg(message) ==
    message.legSymbol
        \o message.legRatio
        \o message.legSecurityType

DecodeComplexFlexLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbol.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatio.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ legSymbol       |-> legSymbol.value,
         legRatio        |-> legRatio.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroComplexFlexLeg ==
    [ legSymbol       |-> [i \in 1 .. 8 |-> 0],
      legRatio        |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Flex Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexFlexLeg ==
    { ZeroComplexFlexLeg }
        \cup { [ZeroComplexFlexLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroComplexFlexLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroComplexFlexLeg EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Complex Flex Leg, written one after another *)
RECURSIVE EncodeComplexFlexLegList(_)
EncodeComplexFlexLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexFlexLeg(Head(messages)) \o EncodeComplexFlexLegList(Tail(messages))

(* As many Complex Flex Leg as the field that counts them says *)
RECURSIVE ReadComplexFlexLegList(_, _)
ReadComplexFlexLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexFlexLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexFlexLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Flex Leg of each kind, for the lists that carry them *)
OneComplexFlexLeg == { ZeroComplexFlexLeg }

(***************************************************************************)
(* Complex Flex Instrument Definition Message                              *)
(***************************************************************************)

ComplexFlexInstrumentDefinitionMessage ==
    [ timeOffset            : Sample(4),
      complexInstrumentId   : Sample(6),
      underlying            : Sample(8),
      complexInstrumentType : Sample(4),
      legCount              : Sample(1),
      messageCount          : Sample(1),
      messageNumber         : Sample(1),
      complexFlexLeg        : SampleLists(OneComplexFlexLeg) ]

EncodeComplexFlexInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId
        \o message.underlying
        \o message.complexInstrumentType
        \o message.legCount
        \o message.messageCount
        \o message.messageNumber
        \o EncodeUIntLE(Len(message.complexFlexLeg), 1)
        \o EncodeComplexFlexLegList(message.complexFlexLeg)

DecodeComplexFlexInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET underlying == ReadBytes(complexInstrumentId.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET complexInstrumentType == ReadBytes(underlying.rest, 4) IN IF ~complexInstrumentType.ok THEN Fail ELSE
    LET legCount == ReadBytes(complexInstrumentType.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET messageCount == ReadBytes(legCount.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET messageNumber == ReadBytes(messageCount.rest, 1) IN IF ~messageNumber.ok THEN Fail ELSE
    LET messageLegCount == ReadUIntLE(messageNumber.rest, 1) IN IF ~messageLegCount.ok THEN Fail ELSE
    LET complexFlexLeg == ReadComplexFlexLegList(messageLegCount.rest, messageLegCount.value) IN IF ~complexFlexLeg.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         complexInstrumentId   |-> complexInstrumentId.value,
         underlying            |-> underlying.value,
         complexInstrumentType |-> complexInstrumentType.value,
         legCount              |-> legCount.value,
         messageCount          |-> messageCount.value,
         messageNumber         |-> messageNumber.value,
         complexFlexLeg        |-> complexFlexLeg.value ], complexFlexLeg.rest)

ZeroComplexFlexInstrumentDefinitionMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId   |-> [i \in 1 .. 6 |-> 0],
      underlying            |-> [i \in 1 .. 8 |-> 0],
      complexInstrumentType |-> [i \in 1 .. 4 |-> 0],
      legCount              |-> [i \in 1 .. 1 |-> 0],
      messageCount          |-> [i \in 1 .. 1 |-> 0],
      messageNumber         |-> [i \in 1 .. 1 |-> 0],
      complexFlexLeg        |-> << >> ]

(* Complex Flex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexFlexInstrumentDefinitionMessage ==
    { ZeroComplexFlexInstrumentDefinitionMessage }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.complexInstrumentType = one] : one \in Sample(4) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.legCount = one] : one \in Sample(1) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.messageCount = one] : one \in Sample(1) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.messageNumber = one] : one \in Sample(1) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.complexFlexLeg = one] : one \in SampleLists(OneComplexFlexLeg) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset       : Sample(4),
      symbol           : Sample(6),
      reserved2        : Sample(2),
      tradingStatus    : Sample(1),
      reserved1        : Sample(1),
      gthTradingStatus : Sample(1),
      secondReserved1  : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.reserved2
        \o message.tradingStatus
        \o message.reserved1
        \o message.gthTradingStatus
        \o message.secondReserved1

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(symbol.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reserved2.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET gthTradingStatus == ReadBytes(reserved1.rest, 1) IN IF ~gthTradingStatus.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(gthTradingStatus.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbol           |-> symbol.value,
         reserved2        |-> reserved2.value,
         tradingStatus    |-> tradingStatus.value,
         reserved1        |-> reserved1.value,
         gthTradingStatus |-> gthTradingStatus.value,
         secondReserved1  |-> secondReserved1.value ], secondReserved1.rest)

ZeroTradingStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbol           |-> [i \in 1 .. 6 |-> 0],
      reserved2        |-> [i \in 1 .. 2 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      gthTradingStatus |-> [i \in 1 .. 1 |-> 0],
      secondReserved1  |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.gthTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginMessageCode == 1  \* 0x01
LoginResponseMessageCode == 2  \* 0x02
SpinImageAvailableMessageCode == 128  \* 0x80
SpinRequestMessageCode == 129  \* 0x81
SpinResponseMessageCode == 130  \* 0x82
SpinFinishedMessageCode == 131  \* 0x83
InstrumentDefinitionRequestMessageCode == 132  \* 0x84
InstrumentDefinitionResponseMessageCode == 133  \* 0x85
InstrumentDefinitionFinishedMessageCode == 134  \* 0x86
TimeMessageCode == 32  \* 0x20
SymbolMappingMessageCode == 46  \* 0x2e
FlexInstrumentDefinitionMessageCode == 156  \* 0x9c
ComplexFlexInstrumentDefinitionMessageCode == 155  \* 0x9b
TradingStatusMessageCode == 49  \* 0x31

Payload ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {SpinImageAvailableMessageCode}, body : SpinImageAvailableMessage ]
        \cup [ tag : {SpinRequestMessageCode}, body : SpinRequestMessage ]
        \cup [ tag : {SpinResponseMessageCode}, body : SpinResponseMessage ]
        \cup [ tag : {SpinFinishedMessageCode}, body : SpinFinishedMessage ]
        \cup [ tag : {InstrumentDefinitionRequestMessageCode}, body : InstrumentDefinitionRequestMessage ]
        \cup [ tag : {InstrumentDefinitionResponseMessageCode}, body : InstrumentDefinitionResponseMessage ]
        \cup [ tag : {InstrumentDefinitionFinishedMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {FlexInstrumentDefinitionMessageCode}, body : FlexInstrumentDefinitionMessage ]
        \cup [ tag : {ComplexFlexInstrumentDefinitionMessageCode}, body : ComplexFlexInstrumentDefinitionMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = SpinImageAvailableMessageCode -> EncodeSpinImageAvailableMessage(message.body)
      [] message.tag = SpinRequestMessageCode -> EncodeSpinRequestMessage(message.body)
      [] message.tag = SpinResponseMessageCode -> EncodeSpinResponseMessage(message.body)
      [] message.tag = SpinFinishedMessageCode -> EncodeSpinFinishedMessage(message.body)
      [] message.tag = InstrumentDefinitionRequestMessageCode -> EncodeInstrumentDefinitionRequestMessage(message.body)
      [] message.tag = InstrumentDefinitionResponseMessageCode -> EncodeInstrumentDefinitionResponseMessage(message.body)
      [] message.tag = InstrumentDefinitionFinishedMessageCode -> << >>
      [] message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = FlexInstrumentDefinitionMessageCode -> EncodeFlexInstrumentDefinitionMessage(message.body)
      [] message.tag = ComplexFlexInstrumentDefinitionMessageCode -> EncodeComplexFlexInstrumentDefinitionMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = SpinImageAvailableMessageCode -> DecodeSpinImageAvailableMessage(bytes)
              [] tag = SpinRequestMessageCode -> DecodeSpinRequestMessage(bytes)
              [] tag = SpinResponseMessageCode -> DecodeSpinResponseMessage(bytes)
              [] tag = SpinFinishedMessageCode -> DecodeSpinFinishedMessage(bytes)
              [] tag = InstrumentDefinitionRequestMessageCode -> DecodeInstrumentDefinitionRequestMessage(bytes)
              [] tag = InstrumentDefinitionResponseMessageCode -> DecodeInstrumentDefinitionResponseMessage(bytes)
              [] tag = InstrumentDefinitionFinishedMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = FlexInstrumentDefinitionMessageCode -> DecodeFlexInstrumentDefinitionMessage(bytes)
              [] tag = ComplexFlexInstrumentDefinitionMessageCode -> DecodeComplexFlexInstrumentDefinitionMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
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
        \cup { [tag |-> InstrumentDefinitionRequestMessageCode, body |-> one] : one \in CheckedInstrumentDefinitionRequestMessage }
        \cup { [tag |-> InstrumentDefinitionResponseMessageCode, body |-> one] : one \in CheckedInstrumentDefinitionResponseMessage }
        \cup { [tag |-> InstrumentDefinitionFinishedMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> FlexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedFlexInstrumentDefinitionMessage }
        \cup { [tag |-> ComplexFlexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedComplexFlexInstrumentDefinitionMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDefinitionRequestMessageCode, body |-> ZeroInstrumentDefinitionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDefinitionResponseMessageCode, body |-> ZeroInstrumentDefinitionResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDefinitionFinishedMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FlexInstrumentDefinitionMessageCode, body |-> ZeroFlexInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexFlexInstrumentDefinitionMessageCode, body |-> ZeroComplexFlexInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]] }

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

(* Every Instrument Definition Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionRequestMessage ==
    \A message \in CheckedInstrumentDefinitionRequestMessage :
        LET read == DecodeInstrumentDefinitionRequestMessage(EncodeInstrumentDefinitionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionResponseMessage ==
    \A message \in CheckedInstrumentDefinitionResponseMessage :
        LET read == DecodeInstrumentDefinitionResponseMessage(EncodeInstrumentDefinitionResponseMessage(message))
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

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexInstrumentDefinitionMessage ==
    \A message \in CheckedFlexInstrumentDefinitionMessage :
        LET read == DecodeFlexInstrumentDefinitionMessage(EncodeFlexInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Flex Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexFlexLeg ==
    \A message \in CheckedComplexFlexLeg :
        LET read == DecodeComplexFlexLeg(EncodeComplexFlexLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Flex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexFlexInstrumentDefinitionMessage ==
    \A message \in CheckedComplexFlexInstrumentDefinitionMessage :
        LET read == DecodeComplexFlexInstrumentDefinitionMessage(EncodeComplexFlexInstrumentDefinitionMessage(message))
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
