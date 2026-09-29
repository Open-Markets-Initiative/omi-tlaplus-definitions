--------------------- MODULE PhlxOptions_Orders_v1_91 ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) PHLX Orders v1.91                                              *)
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
(* Note: a Count of 0 marks Heartbeat and carries no Message.              *)
(*                                                                         *)
(* Note: a Count of 0 marks End Of Session and carries no Message.         *)
(*                                                                         *)
(* Note: Expiration is a bit field set, checked as its 2 bytes rather than *)
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
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp ==
    { ZeroTimestamp }
        \cup { [ZeroTimestamp EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 10 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp : Timestamp,
      eventCode : Sample(1),
      version   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    EncodeTimestamp(message.timestamp)
        \o message.eventCode
        \o message.version

DecodeSystemEventMessage(bytes) ==
    LET timestamp == DecodeTimestamp(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET version == ReadBytes(eventCode.rest, 1) IN IF ~version.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         eventCode |-> eventCode.value,
         version   |-> version.value ], version.rest)

ZeroSystemEventMessage ==
    [ timestamp |-> ZeroTimestamp,
      eventCode |-> [i \in 1 .. 1 |-> 0],
      version   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp2 ==
    { ZeroTimestamp2 }
        \cup { [ZeroTimestamp2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Directory Message: 40 bytes                                     *)
(***************************************************************************)

OptionsDirectoryMessage ==
    [ timestamp           : Timestamp2,
      optionId            : Sample(4),
      securitySymbol      : Sample(5),
      expiration          : Sample(2),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      source              : Sample(1),
      underlyingSymbol    : Sample(13),
      optionClosingType   : Sample(1),
      phlxTradable        : Sample(1) ]

EncodeOptionsDirectoryMessage(message) ==
    EncodeTimestamp2(message.timestamp)
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.source
        \o message.underlyingSymbol
        \o message.optionClosingType
        \o message.phlxTradable

DecodeOptionsDirectoryMessage(bytes) ==
    LET timestamp == DecodeTimestamp2(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET source == ReadBytes(optionType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET optionClosingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~optionClosingType.ok THEN Fail ELSE
    LET phlxTradable == ReadBytes(optionClosingType.rest, 1) IN IF ~phlxTradable.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expiration          |-> expiration.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         source              |-> source.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         optionClosingType   |-> optionClosingType.value,
         phlxTradable        |-> phlxTradable.value ], phlxTradable.rest)

ZeroOptionsDirectoryMessage ==
    [ timestamp           |-> ZeroTimestamp2,
      optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 5 |-> 0],
      expiration          |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      source              |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      optionClosingType   |-> [i \in 1 .. 1 |-> 0],
      phlxTradable        |-> [i \in 1 .. 1 |-> 0] ]

(* Options Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsDirectoryMessage ==
    { ZeroOptionsDirectoryMessage }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp2 }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionClosingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.phlxTradable = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp3 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp3(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp3(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp3 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp3 ==
    { ZeroTimestamp3 }
        \cup { [ZeroTimestamp3 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp3 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Order Strategy Leg: 21 bytes                                    *)
(***************************************************************************)

ComplexOrderStrategyLeg ==
    [ optionId            : Sample(4),
      securitySymbol      : Sample(5),
      expiration          : Sample(2),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      side                : Sample(1),
      legRatio            : Sample(4) ]

EncodeComplexOrderStrategyLeg(message) ==
    message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.side
        \o message.legRatio

DecodeComplexOrderStrategyLeg(bytes) ==
    LET optionId == ReadBytes(bytes, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET side == ReadBytes(optionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legRatio == ReadBytes(side.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expiration          |-> expiration.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         side                |-> side.value,
         legRatio            |-> legRatio.value ], legRatio.rest)

ZeroComplexOrderStrategyLeg ==
    [ optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 5 |-> 0],
      expiration          |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      legRatio            |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Order Strategy Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderStrategyLeg ==
    { ZeroComplexOrderStrategyLeg }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderStrategyLeg EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Complex Order Strategy Leg, written one after another *)
RECURSIVE EncodeComplexOrderStrategyLegList(_)
EncodeComplexOrderStrategyLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexOrderStrategyLeg(Head(messages)) \o EncodeComplexOrderStrategyLegList(Tail(messages))

(* As many Complex Order Strategy Leg as the field that counts them says *)
RECURSIVE ReadComplexOrderStrategyLegList(_, _)
ReadComplexOrderStrategyLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexOrderStrategyLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexOrderStrategyLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Order Strategy Leg of each kind, for the lists that carry them *)
OneComplexOrderStrategyLeg == { ZeroComplexOrderStrategyLeg }

(***************************************************************************)
(* Complex Order Strategy Message                                          *)
(***************************************************************************)

ComplexOrderStrategyMessage ==
    [ timestamp               : Timestamp3,
      strategyId              : Sample(4),
      source                  : Sample(1),
      underlyingSymbol        : Sample(13),
      action                  : Sample(1),
      complexOrderStrategyLeg : SampleLists(OneComplexOrderStrategyLeg) ]

EncodeComplexOrderStrategyMessage(message) ==
    EncodeTimestamp3(message.timestamp)
        \o message.strategyId
        \o message.source
        \o message.underlyingSymbol
        \o message.action
        \o EncodeUIntBE(Len(message.complexOrderStrategyLeg), 1)
        \o EncodeComplexOrderStrategyLegList(message.complexOrderStrategyLeg)

DecodeComplexOrderStrategyMessage(bytes) ==
    LET timestamp == DecodeTimestamp3(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET source == ReadBytes(strategyId.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET action == ReadBytes(underlyingSymbol.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(action.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET complexOrderStrategyLeg == ReadComplexOrderStrategyLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~complexOrderStrategyLeg.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         strategyId              |-> strategyId.value,
         source                  |-> source.value,
         underlyingSymbol        |-> underlyingSymbol.value,
         action                  |-> action.value,
         complexOrderStrategyLeg |-> complexOrderStrategyLeg.value ], complexOrderStrategyLeg.rest)

ZeroComplexOrderStrategyMessage ==
    [ timestamp               |-> ZeroTimestamp3,
      strategyId              |-> [i \in 1 .. 4 |-> 0],
      source                  |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol        |-> [i \in 1 .. 13 |-> 0],
      action                  |-> [i \in 1 .. 1 |-> 0],
      complexOrderStrategyLeg |-> << >> ]

(* Complex Order Strategy Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderStrategyMessage ==
    { ZeroComplexOrderStrategyMessage }
        \cup { [ZeroComplexOrderStrategyMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp3 }
        \cup { [ZeroComplexOrderStrategyMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderStrategyMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderStrategyMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexOrderStrategyMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderStrategyMessage EXCEPT !.complexOrderStrategyLeg = one] : one \in SampleLists(OneComplexOrderStrategyLeg) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp4 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp4(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp4(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp4 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp4 ==
    { ZeroTimestamp4 }
        \cup { [ZeroTimestamp4 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp4 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Trading Action Message: 25 bytes                               *)
(***************************************************************************)

SecurityTradingActionMessage ==
    [ timestamp           : Timestamp4,
      optionId            : Sample(4),
      securitySymbol      : Sample(5),
      expiration          : Sample(2),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      currentTradingState : Sample(1) ]

EncodeSecurityTradingActionMessage(message) ==
    EncodeTimestamp4(message.timestamp)
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.currentTradingState

DecodeSecurityTradingActionMessage(bytes) ==
    LET timestamp == DecodeTimestamp4(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(optionType.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expiration          |-> expiration.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroSecurityTradingActionMessage ==
    [ timestamp           |-> ZeroTimestamp4,
      optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 5 |-> 0],
      expiration          |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingActionMessage ==
    { ZeroSecurityTradingActionMessage }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp4 }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp5 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp5(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp5(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp5 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp5 ==
    { ZeroTimestamp5 }
        \cup { [ZeroTimestamp5 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp5 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Trading Action Message: 13 bytes                                *)
(***************************************************************************)

ComplexTradingActionMessage ==
    [ timestamp           : Timestamp5,
      strategyId          : Sample(4),
      currentTradingState : Sample(1) ]

EncodeComplexTradingActionMessage(message) ==
    EncodeTimestamp5(message.timestamp)
        \o message.strategyId
        \o message.currentTradingState

DecodeComplexTradingActionMessage(bytes) ==
    LET timestamp == DecodeTimestamp5(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(strategyId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         strategyId          |-> strategyId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroComplexTradingActionMessage ==
    [ timestamp           |-> ZeroTimestamp5,
      strategyId          |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTradingActionMessage ==
    { ZeroComplexTradingActionMessage }
        \cup { [ZeroComplexTradingActionMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp5 }
        \cup { [ZeroComplexTradingActionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp6 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp6(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp6(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp6 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp6 ==
    { ZeroTimestamp6 }
        \cup { [ZeroTimestamp6 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp6 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Open Closed Message: 25 bytes                                  *)
(***************************************************************************)

SecurityOpenClosedMessage ==
    [ timestamp           : Timestamp6,
      optionId            : Sample(4),
      securitySymbol      : Sample(5),
      expiration          : Sample(2),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      openState           : Sample(1) ]

EncodeSecurityOpenClosedMessage(message) ==
    EncodeTimestamp6(message.timestamp)
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.openState

DecodeSecurityOpenClosedMessage(bytes) ==
    LET timestamp == DecodeTimestamp6(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET openState == ReadBytes(optionType.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expiration          |-> expiration.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         openState           |-> openState.value ], openState.rest)

ZeroSecurityOpenClosedMessage ==
    [ timestamp           |-> ZeroTimestamp6,
      optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 5 |-> 0],
      expiration          |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      openState           |-> [i \in 1 .. 1 |-> 0] ]

(* Security Open Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityOpenClosedMessage ==
    { ZeroSecurityOpenClosedMessage }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp6 }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp7 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp7(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp7(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp7 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp7 ==
    { ZeroTimestamp7 }
        \cup { [ZeroTimestamp7 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp7 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Strategy Open Closed Message: 13 bytes                                  *)
(***************************************************************************)

StrategyOpenClosedMessage ==
    [ timestamp  : Timestamp7,
      strategyId : Sample(4),
      openState  : Sample(1) ]

EncodeStrategyOpenClosedMessage(message) ==
    EncodeTimestamp7(message.timestamp)
        \o message.strategyId
        \o message.openState

DecodeStrategyOpenClosedMessage(bytes) ==
    LET timestamp == DecodeTimestamp7(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET openState == ReadBytes(strategyId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         strategyId |-> strategyId.value,
         openState  |-> openState.value ], openState.rest)

ZeroStrategyOpenClosedMessage ==
    [ timestamp  |-> ZeroTimestamp7,
      strategyId |-> [i \in 1 .. 4 |-> 0],
      openState  |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Open Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyOpenClosedMessage ==
    { ZeroStrategyOpenClosedMessage }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp7 }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp8 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp8(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp8(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp8 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp8 ==
    { ZeroTimestamp8 }
        \cup { [ZeroTimestamp8 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp8 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Order Message: 48 bytes                                          *)
(***************************************************************************)

SimpleOrderMessage ==
    [ timestamp             : Timestamp8,
      optionId              : Sample(4),
      securitySymbol        : Sample(5),
      expiration            : Sample(2),
      explicitStrikePrice   : Sample(4),
      optionType            : Sample(1),
      orderId               : Sample(4),
      side                  : Sample(1),
      originalOrderVolume   : Sample(4),
      executableOrderVolume : Sample(4),
      orderStatus           : Sample(1),
      orderType             : Sample(1),
      marketQualifier       : Sample(1),
      limitPrice            : Sample(4),
      allOrNone             : Sample(1),
      timeInForce           : Sample(1),
      customerFirmIndicator : Sample(1),
      openCloseIndicator    : Sample(1) ]

EncodeSimpleOrderMessage(message) ==
    EncodeTimestamp8(message.timestamp)
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.orderId
        \o message.side
        \o message.originalOrderVolume
        \o message.executableOrderVolume
        \o message.orderStatus
        \o message.orderType
        \o message.marketQualifier
        \o message.limitPrice
        \o message.allOrNone
        \o message.timeInForce
        \o message.customerFirmIndicator
        \o message.openCloseIndicator

DecodeSimpleOrderMessage(bytes) ==
    LET timestamp == DecodeTimestamp8(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET orderId == ReadBytes(optionType.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET originalOrderVolume == ReadBytes(side.rest, 4) IN IF ~originalOrderVolume.ok THEN Fail ELSE
    LET executableOrderVolume == ReadBytes(originalOrderVolume.rest, 4) IN IF ~executableOrderVolume.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(executableOrderVolume.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderStatus.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET marketQualifier == ReadBytes(orderType.rest, 1) IN IF ~marketQualifier.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(marketQualifier.rest, 4) IN IF ~limitPrice.ok THEN Fail ELSE
    LET allOrNone == ReadBytes(limitPrice.rest, 1) IN IF ~allOrNone.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(allOrNone.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET customerFirmIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~customerFirmIndicator.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(customerFirmIndicator.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         optionId              |-> optionId.value,
         securitySymbol        |-> securitySymbol.value,
         expiration            |-> expiration.value,
         explicitStrikePrice   |-> explicitStrikePrice.value,
         optionType            |-> optionType.value,
         orderId               |-> orderId.value,
         side                  |-> side.value,
         originalOrderVolume   |-> originalOrderVolume.value,
         executableOrderVolume |-> executableOrderVolume.value,
         orderStatus           |-> orderStatus.value,
         orderType             |-> orderType.value,
         marketQualifier       |-> marketQualifier.value,
         limitPrice            |-> limitPrice.value,
         allOrNone             |-> allOrNone.value,
         timeInForce           |-> timeInForce.value,
         customerFirmIndicator |-> customerFirmIndicator.value,
         openCloseIndicator    |-> openCloseIndicator.value ], openCloseIndicator.rest)

ZeroSimpleOrderMessage ==
    [ timestamp             |-> ZeroTimestamp8,
      optionId              |-> [i \in 1 .. 4 |-> 0],
      securitySymbol        |-> [i \in 1 .. 5 |-> 0],
      expiration            |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice   |-> [i \in 1 .. 4 |-> 0],
      optionType            |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      originalOrderVolume   |-> [i \in 1 .. 4 |-> 0],
      executableOrderVolume |-> [i \in 1 .. 4 |-> 0],
      orderStatus           |-> [i \in 1 .. 1 |-> 0],
      orderType             |-> [i \in 1 .. 1 |-> 0],
      marketQualifier       |-> [i \in 1 .. 1 |-> 0],
      limitPrice            |-> [i \in 1 .. 4 |-> 0],
      allOrNone             |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      customerFirmIndicator |-> [i \in 1 .. 1 |-> 0],
      openCloseIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOrderMessage ==
    { ZeroSimpleOrderMessage }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp8 }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.originalOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.executableOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.marketQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.allOrNone = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.customerFirmIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp9 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp9(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp9(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp9 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp9 ==
    { ZeroTimestamp9 }
        \cup { [ZeroTimestamp9 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp9 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Order Leg: 22 bytes                                             *)
(***************************************************************************)

ComplexOrderLeg ==
    [ legOpenCloseIndicator : Sample(1),
      optionId              : Sample(4),
      securitySymbol        : Sample(5),
      expiration            : Sample(2),
      explicitStrikePrice   : Sample(4),
      optionType            : Sample(1),
      side                  : Sample(1),
      legRatio              : Sample(4) ]

EncodeComplexOrderLeg(message) ==
    message.legOpenCloseIndicator
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.side
        \o message.legRatio

DecodeComplexOrderLeg(bytes) ==
    LET legOpenCloseIndicator == ReadBytes(bytes, 1) IN IF ~legOpenCloseIndicator.ok THEN Fail ELSE
    LET optionId == ReadBytes(legOpenCloseIndicator.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET side == ReadBytes(optionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legRatio == ReadBytes(side.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legOpenCloseIndicator |-> legOpenCloseIndicator.value,
         optionId              |-> optionId.value,
         securitySymbol        |-> securitySymbol.value,
         expiration            |-> expiration.value,
         explicitStrikePrice   |-> explicitStrikePrice.value,
         optionType            |-> optionType.value,
         side                  |-> side.value,
         legRatio              |-> legRatio.value ], legRatio.rest)

ZeroComplexOrderLeg ==
    [ legOpenCloseIndicator |-> [i \in 1 .. 1 |-> 0],
      optionId              |-> [i \in 1 .. 4 |-> 0],
      securitySymbol        |-> [i \in 1 .. 5 |-> 0],
      expiration            |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice   |-> [i \in 1 .. 4 |-> 0],
      optionType            |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      legRatio              |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Order Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderLeg ==
    { ZeroComplexOrderLeg }
        \cup { [ZeroComplexOrderLeg EXCEPT !.legOpenCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderLeg EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Complex Order Leg, written one after another *)
RECURSIVE EncodeComplexOrderLegList(_)
EncodeComplexOrderLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexOrderLeg(Head(messages)) \o EncodeComplexOrderLegList(Tail(messages))

(* As many Complex Order Leg as the field that counts them says *)
RECURSIVE ReadComplexOrderLegList(_, _)
ReadComplexOrderLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexOrderLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexOrderLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Order Leg of each kind, for the lists that carry them *)
OneComplexOrderLeg == { ZeroComplexOrderLeg }

(***************************************************************************)
(* Complex Order Message                                                   *)
(***************************************************************************)

ComplexOrderMessage ==
    [ timestamp             : Timestamp9,
      strategyId            : Sample(4),
      orderId               : Sample(4),
      side                  : Sample(1),
      originalOrderVolume   : Sample(4),
      executableOrderVolume : Sample(4),
      orderStatus           : Sample(1),
      orderType             : Sample(1),
      limitPrice            : Sample(4),
      debitOrCredit         : Sample(1),
      allOrNone             : Sample(1),
      timeInForce           : Sample(1),
      customerFirmIndicator : Sample(1),
      underlyingSymbol      : Sample(13),
      complexOrderLeg       : SampleLists(OneComplexOrderLeg) ]

EncodeComplexOrderMessage(message) ==
    EncodeTimestamp9(message.timestamp)
        \o message.strategyId
        \o message.orderId
        \o message.side
        \o message.originalOrderVolume
        \o message.executableOrderVolume
        \o message.orderStatus
        \o message.orderType
        \o message.limitPrice
        \o message.debitOrCredit
        \o message.allOrNone
        \o message.timeInForce
        \o message.customerFirmIndicator
        \o message.underlyingSymbol
        \o EncodeUIntBE(Len(message.complexOrderLeg), 1)
        \o EncodeComplexOrderLegList(message.complexOrderLeg)

DecodeComplexOrderMessage(bytes) ==
    LET timestamp == DecodeTimestamp9(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderId == ReadBytes(strategyId.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET originalOrderVolume == ReadBytes(side.rest, 4) IN IF ~originalOrderVolume.ok THEN Fail ELSE
    LET executableOrderVolume == ReadBytes(originalOrderVolume.rest, 4) IN IF ~executableOrderVolume.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(executableOrderVolume.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderStatus.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(orderType.rest, 4) IN IF ~limitPrice.ok THEN Fail ELSE
    LET debitOrCredit == ReadBytes(limitPrice.rest, 1) IN IF ~debitOrCredit.ok THEN Fail ELSE
    LET allOrNone == ReadBytes(debitOrCredit.rest, 1) IN IF ~allOrNone.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(allOrNone.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET customerFirmIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~customerFirmIndicator.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(customerFirmIndicator.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(underlyingSymbol.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET complexOrderLeg == ReadComplexOrderLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~complexOrderLeg.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         strategyId            |-> strategyId.value,
         orderId               |-> orderId.value,
         side                  |-> side.value,
         originalOrderVolume   |-> originalOrderVolume.value,
         executableOrderVolume |-> executableOrderVolume.value,
         orderStatus           |-> orderStatus.value,
         orderType             |-> orderType.value,
         limitPrice            |-> limitPrice.value,
         debitOrCredit         |-> debitOrCredit.value,
         allOrNone             |-> allOrNone.value,
         timeInForce           |-> timeInForce.value,
         customerFirmIndicator |-> customerFirmIndicator.value,
         underlyingSymbol      |-> underlyingSymbol.value,
         complexOrderLeg       |-> complexOrderLeg.value ], complexOrderLeg.rest)

ZeroComplexOrderMessage ==
    [ timestamp             |-> ZeroTimestamp9,
      strategyId            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      originalOrderVolume   |-> [i \in 1 .. 4 |-> 0],
      executableOrderVolume |-> [i \in 1 .. 4 |-> 0],
      orderStatus           |-> [i \in 1 .. 1 |-> 0],
      orderType             |-> [i \in 1 .. 1 |-> 0],
      limitPrice            |-> [i \in 1 .. 4 |-> 0],
      debitOrCredit         |-> [i \in 1 .. 1 |-> 0],
      allOrNone             |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      customerFirmIndicator |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol      |-> [i \in 1 .. 13 |-> 0],
      complexOrderLeg       |-> << >> ]

(* Complex Order Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderMessage ==
    { ZeroComplexOrderMessage }
        \cup { [ZeroComplexOrderMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp9 }
        \cup { [ZeroComplexOrderMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.originalOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.executableOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.debitOrCredit = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.allOrNone = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.customerFirmIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.complexOrderLeg = one] : one \in SampleLists(OneComplexOrderLeg) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp10 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp10(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp10(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp10 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp10 ==
    { ZeroTimestamp10 }
        \cup { [ZeroTimestamp10 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp10 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Notification Message: 46 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timestamp             : Timestamp10,
      optionId              : Sample(4),
      securitySymbol        : Sample(5),
      expiration            : Sample(2),
      explicitStrikePrice   : Sample(4),
      optionType            : Sample(1),
      auctionId             : Sample(4),
      auctionType           : Sample(1),
      price                 : Sample(4),
      auctionSide           : Sample(1),
      matchedVolume         : Sample(4),
      imbalanceVolume       : Sample(4),
      customerFirmIndicator : Sample(1),
      reserved3             : Sample(3) ]

EncodeAuctionNotificationMessage(message) ==
    EncodeTimestamp10(message.timestamp)
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.auctionId
        \o message.auctionType
        \o message.price
        \o message.auctionSide
        \o message.matchedVolume
        \o message.imbalanceVolume
        \o message.customerFirmIndicator
        \o message.reserved3

DecodeAuctionNotificationMessage(bytes) ==
    LET timestamp == DecodeTimestamp10(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expiration.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(optionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET auctionSide == ReadBytes(price.rest, 1) IN IF ~auctionSide.ok THEN Fail ELSE
    LET matchedVolume == ReadBytes(auctionSide.rest, 4) IN IF ~matchedVolume.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(matchedVolume.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET customerFirmIndicator == ReadBytes(imbalanceVolume.rest, 1) IN IF ~customerFirmIndicator.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(customerFirmIndicator.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         optionId              |-> optionId.value,
         securitySymbol        |-> securitySymbol.value,
         expiration            |-> expiration.value,
         explicitStrikePrice   |-> explicitStrikePrice.value,
         optionType            |-> optionType.value,
         auctionId             |-> auctionId.value,
         auctionType           |-> auctionType.value,
         price                 |-> price.value,
         auctionSide           |-> auctionSide.value,
         matchedVolume         |-> matchedVolume.value,
         imbalanceVolume       |-> imbalanceVolume.value,
         customerFirmIndicator |-> customerFirmIndicator.value,
         reserved3             |-> reserved3.value ], reserved3.rest)

ZeroAuctionNotificationMessage ==
    [ timestamp             |-> ZeroTimestamp10,
      optionId              |-> [i \in 1 .. 4 |-> 0],
      securitySymbol        |-> [i \in 1 .. 5 |-> 0],
      expiration            |-> [i \in 1 .. 2 |-> 0],
      explicitStrikePrice   |-> [i \in 1 .. 4 |-> 0],
      optionType            |-> [i \in 1 .. 1 |-> 0],
      auctionId             |-> [i \in 1 .. 4 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      auctionSide           |-> [i \in 1 .. 1 |-> 0],
      matchedVolume         |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume       |-> [i \in 1 .. 4 |-> 0],
      customerFirmIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved3             |-> [i \in 1 .. 3 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp10 }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionSide = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.matchedVolume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerFirmIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Timestamp: 8 bytes                                                      *)
(***************************************************************************)

Timestamp11 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp11(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp11(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp11 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp11 ==
    { ZeroTimestamp11 }
        \cup { [ZeroTimestamp11 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp11 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Auction Notification Message: 27 bytes                          *)
(***************************************************************************)

ComplexAuctionNotificationMessage ==
    [ timestamp     : Timestamp11,
      strategyId    : Sample(4),
      auctionId     : Sample(4),
      auctionType   : Sample(1),
      price         : Sample(4),
      auctionSide   : Sample(1),
      debitOrCredit : Sample(1),
      volume        : Sample(4) ]

EncodeComplexAuctionNotificationMessage(message) ==
    EncodeTimestamp11(message.timestamp)
        \o message.strategyId
        \o message.auctionId
        \o message.auctionType
        \o message.price
        \o message.auctionSide
        \o message.debitOrCredit
        \o message.volume

DecodeComplexAuctionNotificationMessage(bytes) ==
    LET timestamp == DecodeTimestamp11(bytes) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET auctionSide == ReadBytes(price.rest, 1) IN IF ~auctionSide.ok THEN Fail ELSE
    LET debitOrCredit == ReadBytes(auctionSide.rest, 1) IN IF ~debitOrCredit.ok THEN Fail ELSE
    LET volume == ReadBytes(debitOrCredit.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         strategyId    |-> strategyId.value,
         auctionId     |-> auctionId.value,
         auctionType   |-> auctionType.value,
         price         |-> price.value,
         auctionSide   |-> auctionSide.value,
         debitOrCredit |-> debitOrCredit.value,
         volume        |-> volume.value ], volume.rest)

ZeroComplexAuctionNotificationMessage ==
    [ timestamp     |-> ZeroTimestamp11,
      strategyId    |-> [i \in 1 .. 4 |-> 0],
      auctionId     |-> [i \in 1 .. 4 |-> 0],
      auctionType   |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      auctionSide   |-> [i \in 1 .. 1 |-> 0],
      debitOrCredit |-> [i \in 1 .. 1 |-> 0],
      volume        |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexAuctionNotificationMessage ==
    { ZeroComplexAuctionNotificationMessage }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.timestamp = one] : one \in CheckedTimestamp11 }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.auctionSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.debitOrCredit = one] : one \in Sample(1) }
        \cup { [ZeroComplexAuctionNotificationMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OptionsDirectoryMessageCode == 68  \* "D"
ComplexOrderStrategyMessageCode == 82  \* "R"
SecurityTradingActionMessageCode == 72  \* "H"
ComplexTradingActionMessageCode == 73  \* "I"
SecurityOpenClosedMessageCode == 80  \* "P"
StrategyOpenClosedMessageCode == 81  \* "Q"
SimpleOrderMessageCode == 79  \* "O"
ComplexOrderMessageCode == 88  \* "X"
AuctionNotificationMessageCode == 65  \* "A"
ComplexAuctionNotificationMessageCode == 67  \* "C"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OptionsDirectoryMessageCode}, body : OptionsDirectoryMessage ]
        \cup [ tag : {ComplexOrderStrategyMessageCode}, body : ComplexOrderStrategyMessage ]
        \cup [ tag : {SecurityTradingActionMessageCode}, body : SecurityTradingActionMessage ]
        \cup [ tag : {ComplexTradingActionMessageCode}, body : ComplexTradingActionMessage ]
        \cup [ tag : {SecurityOpenClosedMessageCode}, body : SecurityOpenClosedMessage ]
        \cup [ tag : {StrategyOpenClosedMessageCode}, body : StrategyOpenClosedMessage ]
        \cup [ tag : {SimpleOrderMessageCode}, body : SimpleOrderMessage ]
        \cup [ tag : {ComplexOrderMessageCode}, body : ComplexOrderMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {ComplexAuctionNotificationMessageCode}, body : ComplexAuctionNotificationMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OptionsDirectoryMessageCode -> EncodeOptionsDirectoryMessage(message.body)
      [] message.tag = ComplexOrderStrategyMessageCode -> EncodeComplexOrderStrategyMessage(message.body)
      [] message.tag = SecurityTradingActionMessageCode -> EncodeSecurityTradingActionMessage(message.body)
      [] message.tag = ComplexTradingActionMessageCode -> EncodeComplexTradingActionMessage(message.body)
      [] message.tag = SecurityOpenClosedMessageCode -> EncodeSecurityOpenClosedMessage(message.body)
      [] message.tag = StrategyOpenClosedMessageCode -> EncodeStrategyOpenClosedMessage(message.body)
      [] message.tag = SimpleOrderMessageCode -> EncodeSimpleOrderMessage(message.body)
      [] message.tag = ComplexOrderMessageCode -> EncodeComplexOrderMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = ComplexAuctionNotificationMessageCode -> EncodeComplexAuctionNotificationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OptionsDirectoryMessageCode -> DecodeOptionsDirectoryMessage(bytes)
              [] tag = ComplexOrderStrategyMessageCode -> DecodeComplexOrderStrategyMessage(bytes)
              [] tag = SecurityTradingActionMessageCode -> DecodeSecurityTradingActionMessage(bytes)
              [] tag = ComplexTradingActionMessageCode -> DecodeComplexTradingActionMessage(bytes)
              [] tag = SecurityOpenClosedMessageCode -> DecodeSecurityOpenClosedMessage(bytes)
              [] tag = StrategyOpenClosedMessageCode -> DecodeStrategyOpenClosedMessage(bytes)
              [] tag = SimpleOrderMessageCode -> DecodeSimpleOrderMessage(bytes)
              [] tag = ComplexOrderMessageCode -> DecodeComplexOrderMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = ComplexAuctionNotificationMessageCode -> DecodeComplexAuctionNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OptionsDirectoryMessageCode, body |-> one] : one \in CheckedOptionsDirectoryMessage }
        \cup { [tag |-> ComplexOrderStrategyMessageCode, body |-> one] : one \in CheckedComplexOrderStrategyMessage }
        \cup { [tag |-> SecurityTradingActionMessageCode, body |-> one] : one \in CheckedSecurityTradingActionMessage }
        \cup { [tag |-> ComplexTradingActionMessageCode, body |-> one] : one \in CheckedComplexTradingActionMessage }
        \cup { [tag |-> SecurityOpenClosedMessageCode, body |-> one] : one \in CheckedSecurityOpenClosedMessage }
        \cup { [tag |-> StrategyOpenClosedMessageCode, body |-> one] : one \in CheckedStrategyOpenClosedMessage }
        \cup { [tag |-> SimpleOrderMessageCode, body |-> one] : one \in CheckedSimpleOrderMessage }
        \cup { [tag |-> ComplexOrderMessageCode, body |-> one] : one \in CheckedComplexOrderMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> ComplexAuctionNotificationMessageCode, body |-> one] : one \in CheckedComplexAuctionNotificationMessage }

(***************************************************************************)
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Length counts the bytes it frames, so it is written from them *)
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsDirectoryMessageCode, body |-> ZeroOptionsDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexOrderStrategyMessageCode, body |-> ZeroComplexOrderStrategyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityTradingActionMessageCode, body |-> ZeroSecurityTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexTradingActionMessageCode, body |-> ZeroComplexTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityOpenClosedMessageCode, body |-> ZeroSecurityOpenClosedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyOpenClosedMessageCode, body |-> ZeroStrategyOpenClosedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SimpleOrderMessageCode, body |-> ZeroSimpleOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexOrderMessageCode, body |-> ZeroComplexOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexAuctionNotificationMessageCode, body |-> ZeroComplexAuctionNotificationMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session  : Sample(10),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntLE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session  |-> session.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ session  |-> [i \in 1 .. 10 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
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

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp ==
    \A message \in CheckedTimestamp :
        LET read == DecodeTimestamp(EncodeTimestamp(message))
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

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp2 ==
    \A message \in CheckedTimestamp2 :
        LET read == DecodeTimestamp2(EncodeTimestamp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsDirectoryMessage ==
    \A message \in CheckedOptionsDirectoryMessage :
        LET read == DecodeOptionsDirectoryMessage(EncodeOptionsDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp3 ==
    \A message \in CheckedTimestamp3 :
        LET read == DecodeTimestamp3(EncodeTimestamp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Strategy Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderStrategyLeg ==
    \A message \in CheckedComplexOrderStrategyLeg :
        LET read == DecodeComplexOrderStrategyLeg(EncodeComplexOrderStrategyLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Strategy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderStrategyMessage ==
    \A message \in CheckedComplexOrderStrategyMessage :
        LET read == DecodeComplexOrderStrategyMessage(EncodeComplexOrderStrategyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp4 ==
    \A message \in CheckedTimestamp4 :
        LET read == DecodeTimestamp4(EncodeTimestamp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingActionMessage ==
    \A message \in CheckedSecurityTradingActionMessage :
        LET read == DecodeSecurityTradingActionMessage(EncodeSecurityTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp5 ==
    \A message \in CheckedTimestamp5 :
        LET read == DecodeTimestamp5(EncodeTimestamp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTradingActionMessage ==
    \A message \in CheckedComplexTradingActionMessage :
        LET read == DecodeComplexTradingActionMessage(EncodeComplexTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp6 ==
    \A message \in CheckedTimestamp6 :
        LET read == DecodeTimestamp6(EncodeTimestamp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityOpenClosedMessage ==
    \A message \in CheckedSecurityOpenClosedMessage :
        LET read == DecodeSecurityOpenClosedMessage(EncodeSecurityOpenClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp7 ==
    \A message \in CheckedTimestamp7 :
        LET read == DecodeTimestamp7(EncodeTimestamp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyOpenClosedMessage ==
    \A message \in CheckedStrategyOpenClosedMessage :
        LET read == DecodeStrategyOpenClosedMessage(EncodeStrategyOpenClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp8 ==
    \A message \in CheckedTimestamp8 :
        LET read == DecodeTimestamp8(EncodeTimestamp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOrderMessage ==
    \A message \in CheckedSimpleOrderMessage :
        LET read == DecodeSimpleOrderMessage(EncodeSimpleOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp9 ==
    \A message \in CheckedTimestamp9 :
        LET read == DecodeTimestamp9(EncodeTimestamp9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderLeg ==
    \A message \in CheckedComplexOrderLeg :
        LET read == DecodeComplexOrderLeg(EncodeComplexOrderLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderMessage ==
    \A message \in CheckedComplexOrderMessage :
        LET read == DecodeComplexOrderMessage(EncodeComplexOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp10 ==
    \A message \in CheckedTimestamp10 :
        LET read == DecodeTimestamp10(EncodeTimestamp10(message))
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

(* Every Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp11 ==
    \A message \in CheckedTimestamp11 :
        LET read == DecodeTimestamp11(EncodeTimestamp11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexAuctionNotificationMessage ==
    \A message \in CheckedComplexAuctionNotificationMessage :
        LET read == DecodeComplexAuctionNotificationMessage(EncodeComplexAuctionNotificationMessage(message))
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

(* Length is written from the bytes it frames *)
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
