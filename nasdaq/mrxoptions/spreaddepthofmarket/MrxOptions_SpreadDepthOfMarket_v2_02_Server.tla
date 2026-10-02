------------ MODULE MrxOptions_SpreadDepthOfMarket_v2_02_Server ------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) MRX Options Spread Depth v2.02                                 *)
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
(* Leg Information: 23 bytes                                               *)
(***************************************************************************)

LegInformation ==
    [ optionId            : Sample(4),
      securitySymbol      : Sample(6),
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
    LET securitySymbol == ReadBytes(optionId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
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
      securitySymbol      |-> [i \in 1 .. 6 |-> 0],
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
        \cup { [ZeroLegInformation EXCEPT !.securitySymbol = one] : one \in Sample(6) }
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
      legInformation   : SampleLists(OneLegInformation) ]

EncodeComplexStrategyDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.strategyType
        \o message.underlyingSymbol
        \o EncodeUIntBE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(underlyingSymbol.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legInformation == ReadLegInformationList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legInformation.ok THEN Fail ELSE
    Ok([ trackingNumber   |-> trackingNumber.value,
         timestamp        |-> timestamp.value,
         strategyId       |-> strategyId.value,
         strategyType     |-> strategyType.value,
         underlyingSymbol |-> underlyingSymbol.value,
         legInformation   |-> legInformation.value ], legInformation.rest)

ZeroComplexStrategyDirectoryMessage ==
    [ trackingNumber   |-> [i \in 1 .. 2 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      strategyType     |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      legInformation   |-> << >> ]

(* Complex Strategy Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDirectoryMessage ==
    { ZeroComplexStrategyDirectoryMessage }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
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
(* Add Order Short Form Message: 28 bytes                                  *)
(***************************************************************************)

AddOrderShortFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      depthSide            : Sample(1),
      orderCapacity        : Sample(1),
      priceShort           : Sample(2),
      volumeShort          : Sample(2) ]

EncodeAddOrderShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.depthSide
        \o message.orderCapacity
        \o message.priceShort
        \o message.volumeShort

DecodeAddOrderShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET depthSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~depthSide.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(depthSide.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET priceShort == ReadBytes(orderCapacity.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         depthSide            |-> depthSide.value,
         orderCapacity        |-> orderCapacity.value,
         priceShort           |-> priceShort.value,
         volumeShort          |-> volumeShort.value ], volumeShort.rest)

ZeroAddOrderShortFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      depthSide            |-> [i \in 1 .. 1 |-> 0],
      orderCapacity        |-> [i \in 1 .. 1 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      volumeShort          |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortFormMessage ==
    { ZeroAddOrderShortFormMessage }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.depthSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Order Long Form Message: 32 bytes                                   *)
(***************************************************************************)

AddOrderLongFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      depthSide            : Sample(1),
      orderCapacity        : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4) ]

EncodeAddOrderLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.depthSide
        \o message.orderCapacity
        \o message.priceLong
        \o message.volumeLong

DecodeAddOrderLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET depthSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~depthSide.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(depthSide.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET priceLong == ReadBytes(orderCapacity.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         depthSide            |-> depthSide.value,
         orderCapacity        |-> orderCapacity.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value ], volumeLong.rest)

ZeroAddOrderLongFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      depthSide            |-> [i \in 1 .. 1 |-> 0],
      orderCapacity        |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongFormMessage ==
    { ZeroAddOrderLongFormMessage }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.depthSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Message: 20 bytes                                              *)
(***************************************************************************)

SnapshotMessage ==
    [ sequenceNumber : Sample(20) ]

EncodeSnapshotMessage(message) ==
    message.sequenceNumber

DecodeSnapshotMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 20) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroSnapshotMessage ==
    [ sequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotMessage ==
    { ZeroSnapshotMessage }
        \cup { [ZeroSnapshotMessage EXCEPT !.sequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 78  \* "N"
StrategyTradingActionMessageCode == 72  \* "H"
AddOrderShortFormMessageCode == 102  \* "f"
AddOrderLongFormMessageCode == 70  \* "F"
SnapshotMessageCode == 77  \* "M"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {AddOrderShortFormMessageCode}, body : AddOrderShortFormMessage ]
        \cup [ tag : {AddOrderLongFormMessageCode}, body : AddOrderLongFormMessage ]
        \cup [ tag : {SnapshotMessageCode}, body : SnapshotMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = AddOrderShortFormMessageCode -> EncodeAddOrderShortFormMessage(message.body)
      [] message.tag = AddOrderLongFormMessageCode -> EncodeAddOrderLongFormMessage(message.body)
      [] message.tag = SnapshotMessageCode -> EncodeSnapshotMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = AddOrderShortFormMessageCode -> DecodeAddOrderShortFormMessage(bytes)
              [] tag = AddOrderLongFormMessageCode -> DecodeAddOrderLongFormMessage(bytes)
              [] tag = SnapshotMessageCode -> DecodeSnapshotMessage(bytes)
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
        \cup { [tag |-> SnapshotMessageCode, body |-> one] : one \in CheckedSnapshotMessage }

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
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

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
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

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

(* Every Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotMessage ==
    \A message \in CheckedSnapshotMessage :
        LET read == DecodeSnapshotMessage(EncodeSnapshotMessage(message))
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
