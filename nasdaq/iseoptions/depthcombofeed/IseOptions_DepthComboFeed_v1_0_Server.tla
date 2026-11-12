--------------- MODULE IseOptions_DepthComboFeed_v1_0_Server ---------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Ise Depth Combo Market Data Feed v1.0                          *)
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
(*                                                                         *)
(* Note: a Update Action of any value but 78 or 78 or 78 or 78 or 78       *)
(* carries none of them.                                                   *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: a Server Soup Bin Tcp Packet that ends the session is the last of *)
(* its Server Packet: nothing may follow it.                               *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

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
(* System Event Message: 13 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp    : Sample(6),
      eventCode    : Sample(1),
      currentYear  : Sample(2),
      currentMonth : Sample(1),
      currentDay   : Sample(1),
      version      : Sample(1),
      subVersion   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.currentYear
        \o message.currentMonth
        \o message.currentDay
        \o message.version
        \o message.subVersion

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET currentYear == ReadBytes(eventCode.rest, 2) IN IF ~currentYear.ok THEN Fail ELSE
    LET currentMonth == ReadBytes(currentYear.rest, 1) IN IF ~currentMonth.ok THEN Fail ELSE
    LET currentDay == ReadBytes(currentMonth.rest, 1) IN IF ~currentDay.ok THEN Fail ELSE
    LET version == ReadBytes(currentDay.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET subVersion == ReadBytes(version.rest, 1) IN IF ~subVersion.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         eventCode    |-> eventCode.value,
         currentYear  |-> currentYear.value,
         currentMonth |-> currentMonth.value,
         currentDay   |-> currentDay.value,
         version      |-> version.value,
         subVersion   |-> subVersion.value ], subVersion.rest)

ZeroSystemEventMessage ==
    [ timestamp    |-> [i \in 1 .. 6 |-> 0],
      eventCode    |-> [i \in 1 .. 1 |-> 0],
      currentYear  |-> [i \in 1 .. 2 |-> 0],
      currentMonth |-> [i \in 1 .. 1 |-> 0],
      currentDay   |-> [i \in 1 .. 1 |-> 0],
      version      |-> [i \in 1 .. 1 |-> 0],
      subVersion   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentYear = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentMonth = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentDay = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.subVersion = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Information: 28 bytes                                               *)
(***************************************************************************)

LegInformation ==
    [ optionId            : Sample(4),
      securitySymbol      : Sample(6),
      legId               : Sample(1),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDay       : Sample(1),
      explicitStrikePrice : Sample(8),
      optionType          : Sample(1),
      side                : Sample(1),
      legRatio            : Sample(4) ]

EncodeLegInformation(message) ==
    message.optionId
        \o message.securitySymbol
        \o message.legId
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
    LET legId == ReadBytes(securitySymbol.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(legId.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDay.rest, 8) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET side == ReadBytes(optionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legRatio == ReadBytes(side.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         legId               |-> legId.value,
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
      legId               |-> [i \in 1 .. 1 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDay       |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 8 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      legRatio            |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Information at zero, then each field in turn at the values it is checked at *)
CheckedLegInformation ==
    { ZeroLegInformation }
        \cup { [ZeroLegInformation EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLegInformation EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroLegInformation EXCEPT !.legId = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.explicitStrikePrice = one] : one \in Sample(8) }
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
    [ timestamp        : Sample(6),
      strategyId       : Sample(4),
      strategyType     : Sample(1),
      source           : Sample(1),
      underlyingSymbol : Sample(13),
      legInformation   : SampleLists(OneLegInformation) ]

EncodeComplexStrategyDirectoryMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.strategyType
        \o message.source
        \o message.underlyingSymbol
        \o EncodeUIntBE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET source == ReadBytes(strategyType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(underlyingSymbol.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legInformation == ReadLegInformationList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legInformation.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         strategyId       |-> strategyId.value,
         strategyType     |-> strategyType.value,
         source           |-> source.value,
         underlyingSymbol |-> underlyingSymbol.value,
         legInformation   |-> legInformation.value ], legInformation.rest)

ZeroComplexStrategyDirectoryMessage ==
    [ timestamp        |-> [i \in 1 .. 6 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      strategyType     |-> [i \in 1 .. 1 |-> 0],
      source           |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      legInformation   |-> << >> ]

(* Complex Strategy Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDirectoryMessage ==
    { ZeroComplexStrategyDirectoryMessage }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.legInformation = one] : one \in SampleLists(OneLegInformation) }

(***************************************************************************)
(* Strategy Trading Action Message: 11 bytes                               *)
(***************************************************************************)

StrategyTradingActionMessage ==
    [ timestamp           : Sample(6),
      strategyId          : Sample(4),
      currentTradingState : Sample(1) ]

EncodeStrategyTradingActionMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.currentTradingState

DecodeStrategyTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(strategyId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         strategyId          |-> strategyId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroStrategyTradingActionMessage ==
    [ timestamp           |-> [i \in 1 .. 6 |-> 0],
      strategyId          |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradingActionMessage ==
    { ZeroStrategyTradingActionMessage }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Open Closed Message: 11 bytes                                  *)
(***************************************************************************)

StrategyOpenClosedMessage ==
    [ timestamp  : Sample(6),
      strategyId : Sample(4),
      openState  : Sample(1) ]

EncodeStrategyOpenClosedMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.openState

DecodeStrategyOpenClosedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET openState == ReadBytes(strategyId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         strategyId |-> strategyId.value,
         openState  |-> openState.value ], openState.rest)

ZeroStrategyOpenClosedMessage ==
    [ timestamp  |-> [i \in 1 .. 6 |-> 0],
      strategyId |-> [i \in 1 .. 4 |-> 0],
      openState  |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Open Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyOpenClosedMessage ==
    { ZeroStrategyOpenClosedMessage }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Price: 4 bytes                                                          *)
(***************************************************************************)

Price ==
    [ price : Sample(4) ]

EncodePrice(message) ==
    message.price

DecodePrice(bytes) ==
    LET price == ReadBytes(bytes, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ price |-> price.value ], price.rest)

ZeroPrice ==
    [ price |-> [i \in 1 .. 4 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice ==
    { ZeroPrice }
        \cup { [ZeroPrice EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Size: 4 bytes                                                           *)
(***************************************************************************)

Size ==
    [ size : Sample(4) ]

EncodeSize(message) ==
    message.size

DecodeSize(bytes) ==
    LET size == ReadBytes(bytes, 4) IN IF ~size.ok THEN Fail ELSE
    Ok([ size |-> size.value ], size.rest)

ZeroSize ==
    [ size |-> [i \in 1 .. 4 |-> 0] ]

(* Size at zero, then each field in turn at the values it is checked at *)
CheckedSize ==
    { ZeroSize }
        \cup { [ZeroSize EXCEPT !.size = one] : one \in Sample(4) }

(***************************************************************************)
(* Cust Size: 4 bytes                                                      *)
(***************************************************************************)

CustSize ==
    [ custSize : Sample(4) ]

EncodeCustSize(message) ==
    message.custSize

DecodeCustSize(bytes) ==
    LET custSize == ReadBytes(bytes, 4) IN IF ~custSize.ok THEN Fail ELSE
    Ok([ custSize |-> custSize.value ], custSize.rest)

ZeroCustSize ==
    [ custSize |-> [i \in 1 .. 4 |-> 0] ]

(* Cust Size at zero, then each field in turn at the values it is checked at *)
CheckedCustSize ==
    { ZeroCustSize }
        \cup { [ZeroCustSize EXCEPT !.custSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Pro Cust Size: 4 bytes                                                  *)
(***************************************************************************)

ProCustSize ==
    [ proCustSize : Sample(4) ]

EncodeProCustSize(message) ==
    message.proCustSize

DecodeProCustSize(bytes) ==
    LET proCustSize == ReadBytes(bytes, 4) IN IF ~proCustSize.ok THEN Fail ELSE
    Ok([ proCustSize |-> proCustSize.value ], proCustSize.rest)

ZeroProCustSize ==
    [ proCustSize |-> [i \in 1 .. 4 |-> 0] ]

(* Pro Cust Size at zero, then each field in turn at the values it is checked at *)
CheckedProCustSize ==
    { ZeroProCustSize }
        \cup { [ZeroProCustSize EXCEPT !.proCustSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Ntt Size: 4 bytes                                                       *)
(***************************************************************************)

NttSize ==
    [ nttSize : Sample(4) ]

EncodeNttSize(message) ==
    message.nttSize

DecodeNttSize(bytes) ==
    LET nttSize == ReadBytes(bytes, 4) IN IF ~nttSize.ok THEN Fail ELSE
    Ok([ nttSize |-> nttSize.value ], nttSize.rest)

ZeroNttSize ==
    [ nttSize |-> [i \in 1 .. 4 |-> 0] ]

(* Ntt Size at zero, then each field in turn at the values it is checked at *)
CheckedNttSize ==
    { ZeroNttSize }
        \cup { [ZeroNttSize EXCEPT !.nttSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Update Action: 20 bytes                                                 *)
(***************************************************************************)

PriceSizeCustSizeProCustSizeNttSize ==
    [ price       : Price,
      size        : Size,
      custSize    : CustSize,
      proCustSize : ProCustSize,
      nttSize     : NttSize ]

EncodePriceSizeCustSizeProCustSizeNttSize(message) ==
    EncodePrice(message.price)
        \o EncodeSize(message.size)
        \o EncodeCustSize(message.custSize)
        \o EncodeProCustSize(message.proCustSize)
        \o EncodeNttSize(message.nttSize)

DecodePriceSizeCustSizeProCustSizeNttSize(bytes) ==
    LET price == DecodePrice(bytes) IN IF ~price.ok THEN Fail ELSE
    LET size == DecodeSize(price.rest) IN IF ~size.ok THEN Fail ELSE
    LET custSize == DecodeCustSize(size.rest) IN IF ~custSize.ok THEN Fail ELSE
    LET proCustSize == DecodeProCustSize(custSize.rest) IN IF ~proCustSize.ok THEN Fail ELSE
    LET nttSize == DecodeNttSize(proCustSize.rest) IN IF ~nttSize.ok THEN Fail ELSE
    Ok([ price       |-> price.value,
         size        |-> size.value,
         custSize    |-> custSize.value,
         proCustSize |-> proCustSize.value,
         nttSize     |-> nttSize.value ], nttSize.rest)

ZeroPriceSizeCustSizeProCustSizeNttSize ==
    [ price       |-> ZeroPrice,
      size        |-> ZeroSize,
      custSize    |-> ZeroCustSize,
      proCustSize |-> ZeroProCustSize,
      nttSize     |-> ZeroNttSize ]

(* Update Action at zero, then each field in turn at the values it is checked at *)
CheckedPriceSizeCustSizeProCustSizeNttSize ==
    { ZeroPriceSizeCustSizeProCustSizeNttSize }
        \cup { [ZeroPriceSizeCustSizeProCustSizeNttSize EXCEPT !.price = one] : one \in CheckedPrice }
        \cup { [ZeroPriceSizeCustSizeProCustSizeNttSize EXCEPT !.size = one] : one \in CheckedSize }
        \cup { [ZeroPriceSizeCustSizeProCustSizeNttSize EXCEPT !.custSize = one] : one \in CheckedCustSize }
        \cup { [ZeroPriceSizeCustSizeProCustSizeNttSize EXCEPT !.proCustSize = one] : one \in CheckedProCustSize }
        \cup { [ZeroPriceSizeCustSizeProCustSizeNttSize EXCEPT !.nttSize = one] : one \in CheckedNttSize }

(***************************************************************************)
(* What Update Action decides is present                                   *)
(***************************************************************************)

PriceCode == 78  \* "N"
UpdateActionNoneCode == 0  \* 

UpdateActionChoice ==
    [ tag : {PriceCode}, body : PriceSizeCustSizeProCustSizeNttSize ]
        \cup [ tag : {UpdateActionNoneCode}, body : {[empty |-> 0]} ]

EncodeUpdateActionChoice(message) ==
    CASE message.tag = PriceCode -> EncodePriceSizeCustSizeProCustSizeNttSize(message.body)
      [] OTHER -> << >>

DecodeUpdateActionChoice(tag, bytes) ==
    LET read ==
            CASE tag = PriceCode -> DecodePriceSizeCustSizeProCustSizeNttSize(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUpdateActionChoice == [tag |-> PriceCode, body |-> ZeroPriceSizeCustSizeProCustSizeNttSize]

(* Each Update Action in turn, at the values the message it names is checked at *)
CheckedUpdateActionChoice ==
    { [tag |-> PriceCode, body |-> one] : one \in CheckedPriceSizeCustSizeProCustSizeNttSize }
        \cup { [tag |-> UpdateActionNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Depth Incrementals                                                      *)
(***************************************************************************)

DepthIncrementals ==
    [ depthSide          : Sample(1),
      level              : Sample(1),
      updateActionChoice : UpdateActionChoice ]

EncodeDepthIncrementals(message) ==
    EncodeUIntBE(message.updateActionChoice.tag, 1)
        \o message.depthSide
        \o message.level
        \o EncodeUpdateActionChoice(message.updateActionChoice)

DecodeDepthIncrementals(bytes) ==
    LET updateAction == ReadUIntBE(bytes, 1) IN IF ~updateAction.ok THEN Fail ELSE
    LET depthSide == ReadBytes(updateAction.rest, 1) IN IF ~depthSide.ok THEN Fail ELSE
    LET level == ReadBytes(depthSide.rest, 1) IN IF ~level.ok THEN Fail ELSE
    LET updateActionChoice == DecodeUpdateActionChoice(updateAction.value, level.rest) IN IF ~updateActionChoice.ok THEN Fail ELSE
    Ok([ depthSide          |-> depthSide.value,
         level              |-> level.value,
         updateActionChoice |-> updateActionChoice.value ], updateActionChoice.rest)

ZeroDepthIncrementals ==
    [ depthSide          |-> [i \in 1 .. 1 |-> 0],
      level              |-> [i \in 1 .. 1 |-> 0],
      updateActionChoice |-> ZeroUpdateActionChoice ]

(* Depth Incrementals at zero, then each field in turn at the values it is checked at *)
CheckedDepthIncrementals ==
    { ZeroDepthIncrementals }
        \cup { [ZeroDepthIncrementals EXCEPT !.depthSide = one] : one \in Sample(1) }
        \cup { [ZeroDepthIncrementals EXCEPT !.level = one] : one \in Sample(1) }
        \cup { [ZeroDepthIncrementals EXCEPT !.updateActionChoice = one] : one \in CheckedUpdateActionChoice }

(* A run of Depth Incrementals, written one after another *)
RECURSIVE EncodeDepthIncrementalsList(_)
EncodeDepthIncrementalsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDepthIncrementals(Head(messages)) \o EncodeDepthIncrementalsList(Tail(messages))

(* As many Depth Incrementals as the field that counts them says *)
RECURSIVE ReadDepthIncrementalsList(_, _)
ReadDepthIncrementalsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDepthIncrementals(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDepthIncrementalsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Depth Incrementals of each kind, for the lists that carry them *)
OneDepthIncrementals ==
    { [ZeroDepthIncrementals EXCEPT !.updateActionChoice = [tag |-> PriceCode, body |-> ZeroPriceSizeCustSizeProCustSizeNttSize]],
      [ZeroDepthIncrementals EXCEPT !.updateActionChoice = [tag |-> UpdateActionNoneCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Strategy Depth Incremental Message                                      *)
(***************************************************************************)

StrategyDepthIncrementalMessage ==
    [ timestamp         : Sample(6),
      strategyId        : Sample(4),
      quoteCondition    : Sample(1),
      bidMarketSize     : Sample(4),
      askMarketSize     : Sample(4),
      bidNttMarketSize  : Sample(4),
      askNttMarketSize  : Sample(4),
      depthIncrementals : SampleLists(OneDepthIncrementals) ]

EncodeStrategyDepthIncrementalMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.bidMarketSize
        \o message.askMarketSize
        \o message.bidNttMarketSize
        \o message.askNttMarketSize
        \o EncodeUIntBE(Len(message.depthIncrementals), 1)
        \o EncodeDepthIncrementalsList(message.depthIncrementals)

DecodeStrategyDepthIncrementalMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidMarketSize == ReadBytes(quoteCondition.rest, 4) IN IF ~bidMarketSize.ok THEN Fail ELSE
    LET askMarketSize == ReadBytes(bidMarketSize.rest, 4) IN IF ~askMarketSize.ok THEN Fail ELSE
    LET bidNttMarketSize == ReadBytes(askMarketSize.rest, 4) IN IF ~bidNttMarketSize.ok THEN Fail ELSE
    LET askNttMarketSize == ReadBytes(bidNttMarketSize.rest, 4) IN IF ~askNttMarketSize.ok THEN Fail ELSE
    LET numberOfDepthIncrementals == ReadUIntBE(askNttMarketSize.rest, 1) IN IF ~numberOfDepthIncrementals.ok THEN Fail ELSE
    LET depthIncrementals == ReadDepthIncrementalsList(numberOfDepthIncrementals.rest, numberOfDepthIncrementals.value) IN IF ~depthIncrementals.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         strategyId        |-> strategyId.value,
         quoteCondition    |-> quoteCondition.value,
         bidMarketSize     |-> bidMarketSize.value,
         askMarketSize     |-> askMarketSize.value,
         bidNttMarketSize  |-> bidNttMarketSize.value,
         askNttMarketSize  |-> askNttMarketSize.value,
         depthIncrementals |-> depthIncrementals.value ], depthIncrementals.rest)

ZeroStrategyDepthIncrementalMessage ==
    [ timestamp         |-> [i \in 1 .. 6 |-> 0],
      strategyId        |-> [i \in 1 .. 4 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      bidMarketSize     |-> [i \in 1 .. 4 |-> 0],
      askMarketSize     |-> [i \in 1 .. 4 |-> 0],
      bidNttMarketSize  |-> [i \in 1 .. 4 |-> 0],
      askNttMarketSize  |-> [i \in 1 .. 4 |-> 0],
      depthIncrementals |-> << >> ]

(* Strategy Depth Incremental Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyDepthIncrementalMessage ==
    { ZeroStrategyDepthIncrementalMessage }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.bidMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.askMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.bidNttMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.askNttMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyDepthIncrementalMessage EXCEPT !.depthIncrementals = one] : one \in SampleLists(OneDepthIncrementals) }

(***************************************************************************)
(* Complex Strategy Ticker Message: 51 bytes                               *)
(***************************************************************************)

ComplexStrategyTickerMessage ==
    [ timestamp      : Sample(6),
      strategyId     : Sample(4),
      lastPrice      : Sample(8),
      size           : Sample(4),
      volume         : Sample(4),
      high           : Sample(8),
      low            : Sample(8),
      first          : Sample(8),
      tradeCondition : Sample(1) ]

EncodeComplexStrategyTickerMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.lastPrice
        \o message.size
        \o message.volume
        \o message.high
        \o message.low
        \o message.first
        \o message.tradeCondition

DecodeComplexStrategyTickerMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(strategyId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET size == ReadBytes(lastPrice.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET volume == ReadBytes(size.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET high == ReadBytes(volume.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET first == ReadBytes(low.rest, 8) IN IF ~first.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(first.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         lastPrice      |-> lastPrice.value,
         size           |-> size.value,
         volume         |-> volume.value,
         high           |-> high.value,
         low            |-> low.value,
         first          |-> first.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroComplexStrategyTickerMessage ==
    [ timestamp      |-> [i \in 1 .. 6 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      lastPrice      |-> [i \in 1 .. 8 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0],
      high           |-> [i \in 1 .. 8 |-> 0],
      low            |-> [i \in 1 .. 8 |-> 0],
      first          |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Strategy Ticker Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyTickerMessage ==
    { ZeroComplexStrategyTickerMessage }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.first = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 82  \* "R"
StrategyTradingActionMessageCode == 72  \* "H"
StrategyOpenClosedMessageCode == 79  \* "O"
StrategyDepthIncrementalMessageCode == 75  \* "K"
ComplexStrategyTickerMessageCode == 116  \* "t"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {StrategyOpenClosedMessageCode}, body : StrategyOpenClosedMessage ]
        \cup [ tag : {StrategyDepthIncrementalMessageCode}, body : StrategyDepthIncrementalMessage ]
        \cup [ tag : {ComplexStrategyTickerMessageCode}, body : ComplexStrategyTickerMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = StrategyOpenClosedMessageCode -> EncodeStrategyOpenClosedMessage(message.body)
      [] message.tag = StrategyDepthIncrementalMessageCode -> EncodeStrategyDepthIncrementalMessage(message.body)
      [] message.tag = ComplexStrategyTickerMessageCode -> EncodeComplexStrategyTickerMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = StrategyOpenClosedMessageCode -> DecodeStrategyOpenClosedMessage(bytes)
              [] tag = StrategyDepthIncrementalMessageCode -> DecodeStrategyDepthIncrementalMessage(bytes)
              [] tag = ComplexStrategyTickerMessageCode -> DecodeComplexStrategyTickerMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ComplexStrategyDirectoryMessageCode, body |-> one] : one \in CheckedComplexStrategyDirectoryMessage }
        \cup { [tag |-> StrategyTradingActionMessageCode, body |-> one] : one \in CheckedStrategyTradingActionMessage }
        \cup { [tag |-> StrategyOpenClosedMessageCode, body |-> one] : one \in CheckedStrategyOpenClosedMessage }
        \cup { [tag |-> StrategyDepthIncrementalMessageCode, body |-> one] : one \in CheckedStrategyDepthIncrementalMessage }
        \cup { [tag |-> ComplexStrategyTickerMessageCode, body |-> one] : one \in CheckedComplexStrategyTickerMessage }

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

(* Does a Server Soup Bin Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionServerSoupBinTcpPacket(message) == message.serverPayload.tag \in {EndOfSessionCode}

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionServerSoupBinTcpPacket(one.value) /\ one.rest # << >> THEN Fail
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

(* The runs of Server Soup Bin Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleServerSoupBinTcpPacketLists ==
    { run \in SampleLists(OneServerSoupBinTcpPacket) \cup { <<one, other>> : one \in OneServerSoupBinTcpPacket, other \in OneServerSoupBinTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionServerSoupBinTcpPacket(run[at]) }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleServerSoupBinTcpPacketLists ]

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
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleServerSoupBinTcpPacketLists }

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

(* Every Strategy Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyOpenClosedMessage ==
    \A message \in CheckedStrategyOpenClosedMessage :
        LET read == DecodeStrategyOpenClosedMessage(EncodeStrategyOpenClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice ==
    \A message \in CheckedPrice :
        LET read == DecodePrice(EncodePrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Size decodes back to what was encoded, and leaves nothing over *)
RoundTripSize ==
    \A message \in CheckedSize :
        LET read == DecodeSize(EncodeSize(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cust Size decodes back to what was encoded, and leaves nothing over *)
RoundTripCustSize ==
    \A message \in CheckedCustSize :
        LET read == DecodeCustSize(EncodeCustSize(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pro Cust Size decodes back to what was encoded, and leaves nothing over *)
RoundTripProCustSize ==
    \A message \in CheckedProCustSize :
        LET read == DecodeProCustSize(EncodeProCustSize(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ntt Size decodes back to what was encoded, and leaves nothing over *)
RoundTripNttSize ==
    \A message \in CheckedNttSize :
        LET read == DecodeNttSize(EncodeNttSize(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Update Action decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceSizeCustSizeProCustSizeNttSize ==
    \A message \in CheckedPriceSizeCustSizeProCustSizeNttSize :
        LET read == DecodePriceSizeCustSizeProCustSizeNttSize(EncodePriceSizeCustSizeProCustSizeNttSize(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Incrementals decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthIncrementals ==
    \A message \in CheckedDepthIncrementals :
        LET read == DecodeDepthIncrementals(EncodeDepthIncrementals(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Depth Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyDepthIncrementalMessage ==
    \A message \in CheckedStrategyDepthIncrementalMessage :
        LET read == DecodeStrategyDepthIncrementalMessage(EncodeStrategyDepthIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Ticker Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyTickerMessage ==
    \A message \in CheckedComplexStrategyTickerMessage :
        LET read == DecodeComplexStrategyTickerMessage(EncodeComplexStrategyTickerMessage(message))
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

(* A Update Action is selected by the Update Action it is written under *)
SelectsUpdateActionChoice ==
    \A message \in CheckedUpdateActionChoice :
        LET sent == EncodeUpdateActionChoice(message)
            read == DecodeUpdateActionChoice(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET sent == EncodeServerPayload(message)
            read == DecodeServerPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

(* A Server Soup Bin Tcp Packet that ends the session is the last of its Server Packet: a run with one after it does not decode *)
EndsSessionLastServerSoupBinTcpPacket ==
    \A last \in { one \in OneServerSoupBinTcpPacket : EndsSessionServerSoupBinTcpPacket(one) } :
        \A after \in OneServerSoupBinTcpPacket :
            ~ReadServerSoupBinTcpPacketAll(EncodeServerSoupBinTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
