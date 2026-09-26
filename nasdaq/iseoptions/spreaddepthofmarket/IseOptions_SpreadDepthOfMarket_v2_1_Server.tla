------------ MODULE IseOptions_SpreadDepthOfMarket_v2_1_Server -------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Phlx Options Spread Depth v2.1                                 *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Information: 25 bytes                                               *)
(***************************************************************************)

LegInformation ==
    [ optionId            : Sample(4),
      securitySymbol      : Sample(8),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDay       : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      side                : Sample(1),
      legRatio            : Sample(4) ]

EncodeLegInformation(message) ==
    message.optionId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.side
        \o message.legRatio

DecodeLegInformation(bytes) ==
    LET optionId == ReadBytes(bytes, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDay.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET side == ReadBytes(optionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legRatio == ReadBytes(side.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDay       |-> expirationDay.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         side                |-> side.value,
         legRatio            |-> legRatio.value ], legRatio.rest)

ZeroLegInformation ==
    [ optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 8 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDay       |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      legRatio            |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Information at zero, then each field in turn at the values it is checked at *)
CheckedLegInformation ==
    { ZeroLegInformation }
        \cup { [ZeroLegInformation EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLegInformation EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroLegInformation EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroLegInformation EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Leg Information, written one after another *)
RECURSIVE EncodeLegInformationList(_)
EncodeLegInformationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegInformation(Head(messages)) \o EncodeLegInformationList(Tail(messages))

(* As many Leg Information as the field that counts them says *)
RECURSIVE ReadLegInformationList(_, _)
ReadLegInformationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegInformation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegInformationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Information of each kind, for the lists that carry them *)
OneLegInformation == { ZeroLegInformation }

(***************************************************************************)
(* Complex Strategy Directory Message                                      *)
(***************************************************************************)

ComplexStrategyDirectoryMessage ==
    [ trackingNumber   : Sample(2),
      timestamp        : Sample(8),
      strategyId       : Sample(4),
      strategyType     : Sample(1),
      underlyingSymbol : Sample(13),
      reserved16       : Sample(16),
      legInformation   : SampleLists(OneLegInformation) ]

EncodeComplexStrategyDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.strategyType
        \o message.underlyingSymbol
        \o message.reserved16
        \o EncodeUIntBE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(underlyingSymbol.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(reserved16.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legInformation == ReadLegInformationList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legInformation.ok THEN Fail ELSE
    Ok([ trackingNumber   |-> trackingNumber.value,
         timestamp        |-> timestamp.value,
         strategyId       |-> strategyId.value,
         strategyType     |-> strategyType.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reserved16       |-> reserved16.value,
         legInformation   |-> legInformation.value ], legInformation.rest)

ZeroComplexStrategyDirectoryMessage ==
    [ trackingNumber   |-> [i \in 1 .. 2 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      strategyType     |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      reserved16       |-> [i \in 1 .. 16 |-> 0],
      legInformation   |-> << >> ]

(* Complex Strategy Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDirectoryMessage ==
    { ZeroComplexStrategyDirectoryMessage }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.legInformation = one] : one \in SampleLists(OneLegInformation) }

(***************************************************************************)
(* Strategy Trading Action Message: 15 bytes                               *)
(***************************************************************************)

StrategyTradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      strategyId          : Sample(4),
      currentTradingState : Sample(1) ]

EncodeStrategyTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.currentTradingState

DecodeStrategyTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(strategyId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         strategyId          |-> strategyId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroStrategyTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      strategyId          |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradingActionMessage ==
    { ZeroStrategyTradingActionMessage }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Form Message: 32 bytes                                  *)
(***************************************************************************)

AddOrderShortFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      depthSide            : Sample(1),
      depthOrderCapacity   : Sample(1),
      priceShort           : Sample(2),
      volumeShort          : Sample(2),
      scope                : Sample(1),
      reserved3            : Sample(3) ]

EncodeAddOrderShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.depthSide
        \o message.depthOrderCapacity
        \o message.priceShort
        \o message.volumeShort
        \o message.scope
        \o message.reserved3

DecodeAddOrderShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET depthSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~depthSide.ok THEN Fail ELSE
    LET depthOrderCapacity == ReadBytes(depthSide.rest, 1) IN IF ~depthOrderCapacity.ok THEN Fail ELSE
    LET priceShort == ReadBytes(depthOrderCapacity.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    LET scope == ReadBytes(volumeShort.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(scope.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         depthSide            |-> depthSide.value,
         depthOrderCapacity   |-> depthOrderCapacity.value,
         priceShort           |-> priceShort.value,
         volumeShort          |-> volumeShort.value,
         scope                |-> scope.value,
         reserved3            |-> reserved3.value ], reserved3.rest)

ZeroAddOrderShortFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      depthSide            |-> [i \in 1 .. 1 |-> 0],
      depthOrderCapacity   |-> [i \in 1 .. 1 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      volumeShort          |-> [i \in 1 .. 2 |-> 0],
      scope                |-> [i \in 1 .. 1 |-> 0],
      reserved3            |-> [i \in 1 .. 3 |-> 0] ]

(* Add Order Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortFormMessage ==
    { ZeroAddOrderShortFormMessage }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.depthSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.depthOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Add Order Long Form Message: 36 bytes                                   *)
(***************************************************************************)

AddOrderLongFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      depthSide            : Sample(1),
      depthOrderCapacity   : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4),
      scope                : Sample(1),
      reserved3            : Sample(3) ]

EncodeAddOrderLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.depthSide
        \o message.depthOrderCapacity
        \o message.priceLong
        \o message.volumeLong
        \o message.scope
        \o message.reserved3

DecodeAddOrderLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET depthSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~depthSide.ok THEN Fail ELSE
    LET depthOrderCapacity == ReadBytes(depthSide.rest, 1) IN IF ~depthOrderCapacity.ok THEN Fail ELSE
    LET priceLong == ReadBytes(depthOrderCapacity.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET scope == ReadBytes(volumeLong.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(scope.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         depthSide            |-> depthSide.value,
         depthOrderCapacity   |-> depthOrderCapacity.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value,
         scope                |-> scope.value,
         reserved3            |-> reserved3.value ], reserved3.rest)

ZeroAddOrderLongFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      depthSide            |-> [i \in 1 .. 1 |-> 0],
      depthOrderCapacity   |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0],
      scope                |-> [i \in 1 .. 1 |-> 0],
      reserved3            |-> [i \in 1 .. 3 |-> 0] ]

(* Add Order Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongFormMessage ==
    { ZeroAddOrderLongFormMessage }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.depthSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.depthOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Single Side Executed Message: 39 bytes                                  *)
(***************************************************************************)

SingleSideExecutedMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      executedVolume       : Sample(4),
      tradeCondition       : Sample(1),
      auctionId            : Sample(4),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4) ]

EncodeSingleSideExecutedMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.executedVolume
        \o message.tradeCondition
        \o message.auctionId
        \o message.crossNumber
        \o message.matchNumber

DecodeSingleSideExecutedMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedVolume == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedVolume.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executedVolume.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeCondition.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(auctionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedVolume       |-> executedVolume.value,
         tradeCondition       |-> tradeCondition.value,
         auctionId            |-> auctionId.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroSingleSideExecutedMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedVolume       |-> [i \in 1 .. 4 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 4 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedMessage ==
    { ZeroSingleSideExecutedMessage }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.executedVolume = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed With Price Message: 44 bytes                       *)
(***************************************************************************)

SingleSideExecutedWithPriceMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4),
      reserved1            : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4),
      tradeCondition       : Sample(1),
      auctionId            : Sample(4) ]

EncodeSingleSideExecutedWithPriceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.crossNumber
        \o message.matchNumber
        \o message.reserved1
        \o message.priceLong
        \o message.volumeLong
        \o message.tradeCondition
        \o message.auctionId

DecodeSingleSideExecutedWithPriceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(matchNumber.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET priceLong == ReadBytes(reserved1.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(volumeLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeCondition.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value,
         reserved1            |-> reserved1.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value,
         tradeCondition       |-> tradeCondition.value,
         auctionId            |-> auctionId.value ], auctionId.rest)

ZeroSingleSideExecutedWithPriceMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedWithPriceMessage ==
    { ZeroSingleSideExecutedWithPriceMessage }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.auctionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Replace Short Form Message: 39 bytes                        *)
(***************************************************************************)

SingleSideReplaceShortFormMessage ==
    [ trackingNumber               : Sample(2),
      timestamp                    : Sample(8),
      strategyId                   : Sample(4),
      originalOrderReferenceNumber : Sample(8),
      newOrderReferenceNumber      : Sample(8),
      priceShort                   : Sample(2),
      volumeShort                  : Sample(2),
      orderType                    : Sample(1),
      scope                        : Sample(1),
      reserved3                    : Sample(3) ]

EncodeSingleSideReplaceShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.priceShort
        \o message.volumeShort
        \o message.orderType
        \o message.scope
        \o message.reserved3

DecodeSingleSideReplaceShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 8) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET priceShort == ReadBytes(newOrderReferenceNumber.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    LET orderType == ReadBytes(volumeShort.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET scope == ReadBytes(orderType.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(scope.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ trackingNumber               |-> trackingNumber.value,
         timestamp                    |-> timestamp.value,
         strategyId                   |-> strategyId.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         priceShort                   |-> priceShort.value,
         volumeShort                  |-> volumeShort.value,
         orderType                    |-> orderType.value,
         scope                        |-> scope.value,
         reserved3                    |-> reserved3.value ], reserved3.rest)

ZeroSingleSideReplaceShortFormMessage ==
    [ trackingNumber               |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 8 |-> 0],
      strategyId                   |-> [i \in 1 .. 4 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      priceShort                   |-> [i \in 1 .. 2 |-> 0],
      volumeShort                  |-> [i \in 1 .. 2 |-> 0],
      orderType                    |-> [i \in 1 .. 1 |-> 0],
      scope                        |-> [i \in 1 .. 1 |-> 0],
      reserved3                    |-> [i \in 1 .. 3 |-> 0] ]

(* Single Side Replace Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceShortFormMessage ==
    { ZeroSingleSideReplaceShortFormMessage }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Single Side Replace Long Form Message: 43 bytes                         *)
(***************************************************************************)

SingleSideReplaceLongFormMessage ==
    [ trackingNumber               : Sample(2),
      timestamp                    : Sample(8),
      strategyId                   : Sample(4),
      originalOrderReferenceNumber : Sample(8),
      newOrderReferenceNumber      : Sample(8),
      priceLong                    : Sample(4),
      volumeLong                   : Sample(4),
      orderType                    : Sample(1),
      scope                        : Sample(1),
      reserved3                    : Sample(3) ]

EncodeSingleSideReplaceLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.priceLong
        \o message.volumeLong
        \o message.orderType
        \o message.scope
        \o message.reserved3

DecodeSingleSideReplaceLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 8) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET priceLong == ReadBytes(newOrderReferenceNumber.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET orderType == ReadBytes(volumeLong.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET scope == ReadBytes(orderType.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(scope.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ trackingNumber               |-> trackingNumber.value,
         timestamp                    |-> timestamp.value,
         strategyId                   |-> strategyId.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         priceLong                    |-> priceLong.value,
         volumeLong                   |-> volumeLong.value,
         orderType                    |-> orderType.value,
         scope                        |-> scope.value,
         reserved3                    |-> reserved3.value ], reserved3.rest)

ZeroSingleSideReplaceLongFormMessage ==
    [ trackingNumber               |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 8 |-> 0],
      strategyId                   |-> [i \in 1 .. 4 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      priceLong                    |-> [i \in 1 .. 4 |-> 0],
      volumeLong                   |-> [i \in 1 .. 4 |-> 0],
      orderType                    |-> [i \in 1 .. 1 |-> 0],
      scope                        |-> [i \in 1 .. 1 |-> 0],
      reserved3                    |-> [i \in 1 .. 3 |-> 0] ]

(* Single Side Replace Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceLongFormMessage ==
    { ZeroSingleSideReplaceLongFormMessage }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Single Side Delete Message: 22 bytes                                    *)
(***************************************************************************)

SingleSideDeleteMessage ==
    [ trackingNumber           : Sample(2),
      timestamp                : Sample(8),
      strategyIdOrderReference : Sample(4),
      orderReferenceNumber     : Sample(8) ]

EncodeSingleSideDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyIdOrderReference
        \o message.orderReferenceNumber

DecodeSingleSideDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyIdOrderReference == ReadBytes(timestamp.rest, 4) IN IF ~strategyIdOrderReference.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyIdOrderReference.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber           |-> trackingNumber.value,
         timestamp                |-> timestamp.value,
         strategyIdOrderReference |-> strategyIdOrderReference.value,
         orderReferenceNumber     |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroSingleSideDeleteMessage ==
    [ trackingNumber           |-> [i \in 1 .. 2 |-> 0],
      timestamp                |-> [i \in 1 .. 8 |-> 0],
      strategyIdOrderReference |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber     |-> [i \in 1 .. 8 |-> 0] ]

(* Single Side Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideDeleteMessage ==
    { ZeroSingleSideDeleteMessage }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.strategyIdOrderReference = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Side Update Message: 32 bytes                                    *)
(***************************************************************************)

SingleSideUpdateMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      changeReason         : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4),
      orderType            : Sample(1) ]

EncodeSingleSideUpdateMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.changeReason
        \o message.priceLong
        \o message.volumeLong
        \o message.orderType

DecodeSingleSideUpdateMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET changeReason == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~changeReason.ok THEN Fail ELSE
    LET priceLong == ReadBytes(changeReason.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET orderType == ReadBytes(volumeLong.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         changeReason         |-> changeReason.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value,
         orderType            |-> orderType.value ], orderType.rest)

ZeroSingleSideUpdateMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      changeReason         |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0],
      orderType            |-> [i \in 1 .. 1 |-> 0] ]

(* Single Side Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateMessage ==
    { ZeroSingleSideUpdateMessage }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.changeReason = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.orderType = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Strategy Trade Message: 58 bytes                                *)
(***************************************************************************)

ComplexStrategyTradeMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      strategyId     : Sample(4),
      crossNumber    : Sample(4),
      matchNumber    : Sample(4),
      reserved4      : Sample(4),
      crossType      : Sample(1),
      priceLong      : Sample(4),
      volumeLong     : Sample(4),
      tradeCondition : Sample(1),
      auctionId      : Sample(4),
      reserved1      : Sample(1),
      tradeType      : Sample(1),
      reserved16     : Sample(16) ]

EncodeComplexStrategyTradeMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.crossNumber
        \o message.matchNumber
        \o message.reserved4
        \o message.crossType
        \o message.priceLong
        \o message.volumeLong
        \o message.tradeCondition
        \o message.auctionId
        \o message.reserved1
        \o message.tradeType
        \o message.reserved16

DecodeComplexStrategyTradeMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(strategyId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(matchNumber.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET crossType == ReadBytes(reserved4.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(crossType.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(volumeLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeCondition.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(auctionId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradeType == ReadBytes(reserved1.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(tradeType.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         crossNumber    |-> crossNumber.value,
         matchNumber    |-> matchNumber.value,
         reserved4      |-> reserved4.value,
         crossType      |-> crossType.value,
         priceLong      |-> priceLong.value,
         volumeLong     |-> volumeLong.value,
         tradeCondition |-> tradeCondition.value,
         auctionId      |-> auctionId.value,
         reserved1      |-> reserved1.value,
         tradeType      |-> tradeType.value,
         reserved16     |-> reserved16.value ], reserved16.rest)

ZeroComplexStrategyTradeMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      crossNumber    |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      reserved4      |-> [i \in 1 .. 4 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0],
      priceLong      |-> [i \in 1 .. 4 |-> 0],
      volumeLong     |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0],
      auctionId      |-> [i \in 1 .. 4 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0],
      tradeType      |-> [i \in 1 .. 1 |-> 0],
      reserved16     |-> [i \in 1 .. 16 |-> 0] ]

(* Complex Strategy Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyTradeMessage ==
    { ZeroComplexStrategyTradeMessage }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyTradeMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Flex Dac Leg Information: 8 bytes                                       *)
(***************************************************************************)

FlexDacLegInformation ==
    [ reserved8 : Sample(8) ]

EncodeFlexDacLegInformation(message) ==
    message.reserved8

DecodeFlexDacLegInformation(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexDacLegInformation ==
    [ reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Dac Leg Information at zero, then each field in turn at the values it is checked at *)
CheckedFlexDacLegInformation ==
    { ZeroFlexDacLegInformation }
        \cup { [ZeroFlexDacLegInformation EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Dac Leg Information, written one after another *)
RECURSIVE EncodeFlexDacLegInformationList(_)
EncodeFlexDacLegInformationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexDacLegInformation(Head(messages)) \o EncodeFlexDacLegInformationList(Tail(messages))

(* As many Flex Dac Leg Information as the field that counts them says *)
RECURSIVE ReadFlexDacLegInformationList(_, _)
ReadFlexDacLegInformationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexDacLegInformation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexDacLegInformationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Dac Leg Information of each kind, for the lists that carry them *)
OneFlexDacLegInformation == { ZeroFlexDacLegInformation }

(***************************************************************************)
(* Complex Strategy Auction Message                                        *)
(***************************************************************************)

ComplexStrategyAuctionMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(8),
      strategyId            : Sample(4),
      auctionId             : Sample(4),
      auctionType           : Sample(1),
      auctionDuration       : Sample(4),
      auctionEvent          : Sample(1),
      orderType             : Sample(1),
      side                  : Sample(1),
      priceLong             : Sample(4),
      size                  : Sample(4),
      execFlag              : Sample(1),
      orderCapacity         : Sample(1),
      scope                 : Sample(1),
      ownerId               : Sample(6),
      giveup                : Sample(6),
      cmta                  : Sample(6),
      responsePrice         : Sample(4),
      responseSize          : Sample(4),
      reserved4             : Sample(4),
      flexDacLegInformation : SampleLists(OneFlexDacLegInformation) ]

EncodeComplexStrategyAuctionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.auctionId
        \o message.auctionType
        \o message.auctionDuration
        \o message.auctionEvent
        \o message.orderType
        \o message.side
        \o message.priceLong
        \o message.size
        \o message.execFlag
        \o message.orderCapacity
        \o message.scope
        \o message.ownerId
        \o message.giveup
        \o message.cmta
        \o message.responsePrice
        \o message.responseSize
        \o message.reserved4
        \o EncodeUIntBE(Len(message.flexDacLegInformation), 1)
        \o EncodeFlexDacLegInformationList(message.flexDacLegInformation)

DecodeComplexStrategyAuctionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionType.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(auctionDuration.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET orderType == ReadBytes(auctionEvent.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET size == ReadBytes(priceLong.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET execFlag == ReadBytes(size.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET scope == ReadBytes(orderCapacity.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET ownerId == ReadBytes(scope.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    LET responsePrice == ReadBytes(cmta.rest, 4) IN IF ~responsePrice.ok THEN Fail ELSE
    LET responseSize == ReadBytes(responsePrice.rest, 4) IN IF ~responseSize.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(responseSize.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET numberOfFlexDacLegs == ReadUIntBE(reserved4.rest, 1) IN IF ~numberOfFlexDacLegs.ok THEN Fail ELSE
    LET flexDacLegInformation == ReadFlexDacLegInformationList(numberOfFlexDacLegs.rest, numberOfFlexDacLegs.value) IN IF ~flexDacLegInformation.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         strategyId            |-> strategyId.value,
         auctionId             |-> auctionId.value,
         auctionType           |-> auctionType.value,
         auctionDuration       |-> auctionDuration.value,
         auctionEvent          |-> auctionEvent.value,
         orderType             |-> orderType.value,
         side                  |-> side.value,
         priceLong             |-> priceLong.value,
         size                  |-> size.value,
         execFlag              |-> execFlag.value,
         orderCapacity         |-> orderCapacity.value,
         scope                 |-> scope.value,
         ownerId               |-> ownerId.value,
         giveup                |-> giveup.value,
         cmta                  |-> cmta.value,
         responsePrice         |-> responsePrice.value,
         responseSize          |-> responseSize.value,
         reserved4             |-> reserved4.value,
         flexDacLegInformation |-> flexDacLegInformation.value ], flexDacLegInformation.rest)

ZeroComplexStrategyAuctionMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      strategyId            |-> [i \in 1 .. 4 |-> 0],
      auctionId             |-> [i \in 1 .. 4 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      auctionDuration       |-> [i \in 1 .. 4 |-> 0],
      auctionEvent          |-> [i \in 1 .. 1 |-> 0],
      orderType             |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      priceLong             |-> [i \in 1 .. 4 |-> 0],
      size                  |-> [i \in 1 .. 4 |-> 0],
      execFlag              |-> [i \in 1 .. 1 |-> 0],
      orderCapacity         |-> [i \in 1 .. 1 |-> 0],
      scope                 |-> [i \in 1 .. 1 |-> 0],
      ownerId               |-> [i \in 1 .. 6 |-> 0],
      giveup                |-> [i \in 1 .. 6 |-> 0],
      cmta                  |-> [i \in 1 .. 6 |-> 0],
      responsePrice         |-> [i \in 1 .. 4 |-> 0],
      responseSize          |-> [i \in 1 .. 4 |-> 0],
      reserved4             |-> [i \in 1 .. 4 |-> 0],
      flexDacLegInformation |-> << >> ]

(* Complex Strategy Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyAuctionMessage ==
    { ZeroComplexStrategyAuctionMessage }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.cmta = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.responsePrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.responseSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.flexDacLegInformation = one] : one \in SampleLists(OneFlexDacLegInformation) }

(***************************************************************************)
(* End Of Replay Sequence Message: 20 bytes                                *)
(***************************************************************************)

EndOfReplaySequenceMessage ==
    [ endOfReplaySequenceNumber : Sample(20) ]

EncodeEndOfReplaySequenceMessage(message) ==
    message.endOfReplaySequenceNumber

DecodeEndOfReplaySequenceMessage(bytes) ==
    LET endOfReplaySequenceNumber == ReadBytes(bytes, 20) IN IF ~endOfReplaySequenceNumber.ok THEN Fail ELSE
    Ok([ endOfReplaySequenceNumber |-> endOfReplaySequenceNumber.value ], endOfReplaySequenceNumber.rest)

ZeroEndOfReplaySequenceMessage ==
    [ endOfReplaySequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* End Of Replay Sequence Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfReplaySequenceMessage ==
    { ZeroEndOfReplaySequenceMessage }
        \cup { [ZeroEndOfReplaySequenceMessage EXCEPT !.endOfReplaySequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 115  \* "s"
StrategyTradingActionMessageCode == 72  \* "H"
AddOrderShortFormMessageCode == 114  \* "r"
AddOrderLongFormMessageCode == 111  \* "o"
SingleSideExecutedMessageCode == 116  \* "t"
SingleSideExecutedWithPriceMessageCode == 84  \* "T"
SingleSideReplaceShortFormMessageCode == 105  \* "i"
SingleSideReplaceLongFormMessageCode == 73  \* "I"
SingleSideDeleteMessageCode == 68  \* "D"
SingleSideUpdateMessageCode == 80  \* "P"
ComplexStrategyTradeMessageCode == 113  \* "q"
ComplexStrategyAuctionMessageCode == 97  \* "a"
EndOfReplaySequenceMessageCode == 77  \* "M"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {AddOrderShortFormMessageCode}, body : AddOrderShortFormMessage ]
        \cup [ tag : {AddOrderLongFormMessageCode}, body : AddOrderLongFormMessage ]
        \cup [ tag : {SingleSideExecutedMessageCode}, body : SingleSideExecutedMessage ]
        \cup [ tag : {SingleSideExecutedWithPriceMessageCode}, body : SingleSideExecutedWithPriceMessage ]
        \cup [ tag : {SingleSideReplaceShortFormMessageCode}, body : SingleSideReplaceShortFormMessage ]
        \cup [ tag : {SingleSideReplaceLongFormMessageCode}, body : SingleSideReplaceLongFormMessage ]
        \cup [ tag : {SingleSideDeleteMessageCode}, body : SingleSideDeleteMessage ]
        \cup [ tag : {SingleSideUpdateMessageCode}, body : SingleSideUpdateMessage ]
        \cup [ tag : {ComplexStrategyTradeMessageCode}, body : ComplexStrategyTradeMessage ]
        \cup [ tag : {ComplexStrategyAuctionMessageCode}, body : ComplexStrategyAuctionMessage ]
        \cup [ tag : {EndOfReplaySequenceMessageCode}, body : EndOfReplaySequenceMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = AddOrderShortFormMessageCode -> EncodeAddOrderShortFormMessage(message.body)
      [] message.tag = AddOrderLongFormMessageCode -> EncodeAddOrderLongFormMessage(message.body)
      [] message.tag = SingleSideExecutedMessageCode -> EncodeSingleSideExecutedMessage(message.body)
      [] message.tag = SingleSideExecutedWithPriceMessageCode -> EncodeSingleSideExecutedWithPriceMessage(message.body)
      [] message.tag = SingleSideReplaceShortFormMessageCode -> EncodeSingleSideReplaceShortFormMessage(message.body)
      [] message.tag = SingleSideReplaceLongFormMessageCode -> EncodeSingleSideReplaceLongFormMessage(message.body)
      [] message.tag = SingleSideDeleteMessageCode -> EncodeSingleSideDeleteMessage(message.body)
      [] message.tag = SingleSideUpdateMessageCode -> EncodeSingleSideUpdateMessage(message.body)
      [] message.tag = ComplexStrategyTradeMessageCode -> EncodeComplexStrategyTradeMessage(message.body)
      [] message.tag = ComplexStrategyAuctionMessageCode -> EncodeComplexStrategyAuctionMessage(message.body)
      [] message.tag = EndOfReplaySequenceMessageCode -> EncodeEndOfReplaySequenceMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = AddOrderShortFormMessageCode -> DecodeAddOrderShortFormMessage(bytes)
              [] tag = AddOrderLongFormMessageCode -> DecodeAddOrderLongFormMessage(bytes)
              [] tag = SingleSideExecutedMessageCode -> DecodeSingleSideExecutedMessage(bytes)
              [] tag = SingleSideExecutedWithPriceMessageCode -> DecodeSingleSideExecutedWithPriceMessage(bytes)
              [] tag = SingleSideReplaceShortFormMessageCode -> DecodeSingleSideReplaceShortFormMessage(bytes)
              [] tag = SingleSideReplaceLongFormMessageCode -> DecodeSingleSideReplaceLongFormMessage(bytes)
              [] tag = SingleSideDeleteMessageCode -> DecodeSingleSideDeleteMessage(bytes)
              [] tag = SingleSideUpdateMessageCode -> DecodeSingleSideUpdateMessage(bytes)
              [] tag = ComplexStrategyTradeMessageCode -> DecodeComplexStrategyTradeMessage(bytes)
              [] tag = ComplexStrategyAuctionMessageCode -> DecodeComplexStrategyAuctionMessage(bytes)
              [] tag = EndOfReplaySequenceMessageCode -> DecodeEndOfReplaySequenceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ComplexStrategyDirectoryMessageCode, body |-> one] : one \in CheckedComplexStrategyDirectoryMessage }
        \cup { [tag |-> StrategyTradingActionMessageCode, body |-> one] : one \in CheckedStrategyTradingActionMessage }
        \cup { [tag |-> AddOrderShortFormMessageCode, body |-> one] : one \in CheckedAddOrderShortFormMessage }
        \cup { [tag |-> AddOrderLongFormMessageCode, body |-> one] : one \in CheckedAddOrderLongFormMessage }
        \cup { [tag |-> SingleSideExecutedMessageCode, body |-> one] : one \in CheckedSingleSideExecutedMessage }
        \cup { [tag |-> SingleSideExecutedWithPriceMessageCode, body |-> one] : one \in CheckedSingleSideExecutedWithPriceMessage }
        \cup { [tag |-> SingleSideReplaceShortFormMessageCode, body |-> one] : one \in CheckedSingleSideReplaceShortFormMessage }
        \cup { [tag |-> SingleSideReplaceLongFormMessageCode, body |-> one] : one \in CheckedSingleSideReplaceLongFormMessage }
        \cup { [tag |-> SingleSideDeleteMessageCode, body |-> one] : one \in CheckedSingleSideDeleteMessage }
        \cup { [tag |-> SingleSideUpdateMessageCode, body |-> one] : one \in CheckedSingleSideUpdateMessage }
        \cup { [tag |-> ComplexStrategyTradeMessageCode, body |-> one] : one \in CheckedComplexStrategyTradeMessage }
        \cup { [tag |-> ComplexStrategyAuctionMessageCode, body |-> one] : one \in CheckedComplexStrategyAuctionMessage }
        \cup { [tag |-> EndOfReplaySequenceMessageCode, body |-> one] : one \in CheckedEndOfReplaySequenceMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatPacketCode == 72  \* "H"
EndOfSessionPacketCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatPacketCode}, body : {0} ]
        \cup [ tag : {EndOfSessionPacketCode}, body : {0} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatPacketCode -> << >>
      [] message.tag = EndOfSessionPacketCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatPacketCode -> Ok(0, bytes)
              [] tag = EndOfSessionPacketCode -> Ok(0, bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatPacketCode, body |-> 0] }
        \cup { [tag |-> EndOfSessionPacketCode, body |-> 0] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatPacketCode, body |-> 0]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionPacketCode, body |-> 0]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
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

(* Every Leg Information decodes back to what was encoded, and leaves nothing over *)
RoundTripLegInformation ==
    \A message \in CheckedLegInformation :
        LET read == DecodeLegInformation(EncodeLegInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyDirectoryMessage ==
    \A message \in CheckedComplexStrategyDirectoryMessage :
        LET read == DecodeComplexStrategyDirectoryMessage(EncodeComplexStrategyDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradingActionMessage ==
    \A message \in CheckedStrategyTradingActionMessage :
        LET read == DecodeStrategyTradingActionMessage(EncodeStrategyTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortFormMessage ==
    \A message \in CheckedAddOrderShortFormMessage :
        LET read == DecodeAddOrderShortFormMessage(EncodeAddOrderShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderLongFormMessage ==
    \A message \in CheckedAddOrderLongFormMessage :
        LET read == DecodeAddOrderLongFormMessage(EncodeAddOrderLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideExecutedMessage ==
    \A message \in CheckedSingleSideExecutedMessage :
        LET read == DecodeSingleSideExecutedMessage(EncodeSingleSideExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideExecutedWithPriceMessage ==
    \A message \in CheckedSingleSideExecutedWithPriceMessage :
        LET read == DecodeSingleSideExecutedWithPriceMessage(EncodeSingleSideExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceShortFormMessage ==
    \A message \in CheckedSingleSideReplaceShortFormMessage :
        LET read == DecodeSingleSideReplaceShortFormMessage(EncodeSingleSideReplaceShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceLongFormMessage ==
    \A message \in CheckedSingleSideReplaceLongFormMessage :
        LET read == DecodeSingleSideReplaceLongFormMessage(EncodeSingleSideReplaceLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideDeleteMessage ==
    \A message \in CheckedSingleSideDeleteMessage :
        LET read == DecodeSingleSideDeleteMessage(EncodeSingleSideDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideUpdateMessage ==
    \A message \in CheckedSingleSideUpdateMessage :
        LET read == DecodeSingleSideUpdateMessage(EncodeSingleSideUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyTradeMessage ==
    \A message \in CheckedComplexStrategyTradeMessage :
        LET read == DecodeComplexStrategyTradeMessage(EncodeComplexStrategyTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Dac Leg Information decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexDacLegInformation ==
    \A message \in CheckedFlexDacLegInformation :
        LET read == DecodeFlexDacLegInformation(EncodeFlexDacLegInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyAuctionMessage ==
    \A message \in CheckedComplexStrategyAuctionMessage :
        LET read == DecodeComplexStrategyAuctionMessage(EncodeComplexStrategyAuctionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Replay Sequence Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfReplaySequenceMessage ==
    \A message \in CheckedEndOfReplaySequenceMessage :
        LET read == DecodeEndOfReplaySequenceMessage(EncodeEndOfReplaySequenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
