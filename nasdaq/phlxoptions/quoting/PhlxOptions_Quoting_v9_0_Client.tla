------------------ MODULE PhlxOptions_Quoting_v9_0_Client ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Specialized Quote Interface v9.0                               *)
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Login Request Packet: 51 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20),
      heartbeatTimeout        : Sample(5) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber
        \o message.heartbeatTimeout

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    LET heartbeatTimeout == ReadBytes(requestedSequenceNumber.rest, 5) IN IF ~heartbeatTimeout.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value,
         heartbeatTimeout        |-> heartbeatTimeout.value ], heartbeatTimeout.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0],
      heartbeatTimeout        |-> [i \in 1 .. 5 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.heartbeatTimeout = one] : one \in Sample(5) }

(***************************************************************************)
(* Notification Subscription Request Message: 36 bytes                     *)
(***************************************************************************)

NotificationSubscriptionRequestMessage ==
    [ badge        : Sample(4),
      messageId    : Sample(8),
      subscription : Sample(24) ]

EncodeNotificationSubscriptionRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.subscription

DecodeNotificationSubscriptionRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET subscription == ReadBytes(messageId.rest, 24) IN IF ~subscription.ok THEN Fail ELSE
    Ok([ badge        |-> badge.value,
         messageId    |-> messageId.value,
         subscription |-> subscription.value ], subscription.rest)

ZeroNotificationSubscriptionRequestMessage ==
    [ badge        |-> [i \in 1 .. 4 |-> 0],
      messageId    |-> [i \in 1 .. 8 |-> 0],
      subscription |-> [i \in 1 .. 24 |-> 0] ]

(* Notification Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNotificationSubscriptionRequestMessage ==
    { ZeroNotificationSubscriptionRequestMessage }
        \cup { [ZeroNotificationSubscriptionRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroNotificationSubscriptionRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroNotificationSubscriptionRequestMessage EXCEPT !.subscription = one] : one \in Sample(24) }

(***************************************************************************)
(* Complex Legs: 9 bytes                                                   *)
(***************************************************************************)

ComplexLegs ==
    [ legInstrumentId : Sample(4),
      legSide         : Sample(1),
      legRatio        : Sample(4) ]

EncodeComplexLegs(message) ==
    message.legInstrumentId
        \o message.legSide
        \o message.legRatio

DecodeComplexLegs(bytes) ==
    LET legInstrumentId == ReadBytes(bytes, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legInstrumentId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legInstrumentId |-> legInstrumentId.value,
         legSide         |-> legSide.value,
         legRatio        |-> legRatio.value ], legRatio.rest)

ZeroComplexLegs ==
    [ legInstrumentId |-> [i \in 1 .. 4 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legRatio        |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Legs at zero, then each field in turn at the values it is checked at *)
CheckedComplexLegs ==
    { ZeroComplexLegs }
        \cup { [ZeroComplexLegs EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexLegs EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexLegs EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Complex Legs, written one after another *)
RECURSIVE EncodeComplexLegsList(_)
EncodeComplexLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexLegs(Head(messages)) \o EncodeComplexLegsList(Tail(messages))

(* As many Complex Legs as the field that counts them says *)
RECURSIVE ReadComplexLegsList(_, _)
ReadComplexLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Legs of each kind, for the lists that carry them *)
OneComplexLegs == { ZeroComplexLegs }

(***************************************************************************)
(* Add Complex Instrument Request Message                                  *)
(***************************************************************************)

AddComplexInstrumentRequestMessage ==
    [ badge            : Sample(4),
      messageId        : Sample(8),
      underlyingSymbol : Sample(13),
      complexLegs      : SampleLists(OneComplexLegs) ]

EncodeAddComplexInstrumentRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.underlyingSymbol
        \o EncodeUIntBE(Len(message.complexLegs), 1)
        \o EncodeComplexLegsList(message.complexLegs)

DecodeAddComplexInstrumentRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(messageId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(underlyingSymbol.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET complexLegs == ReadComplexLegsList(numberOfLegs.rest, numberOfLegs.value) IN IF ~complexLegs.ok THEN Fail ELSE
    Ok([ badge            |-> badge.value,
         messageId        |-> messageId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         complexLegs      |-> complexLegs.value ], complexLegs.rest)

ZeroAddComplexInstrumentRequestMessage ==
    [ badge            |-> [i \in 1 .. 4 |-> 0],
      messageId        |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      complexLegs      |-> << >> ]

(* Add Complex Instrument Request Message at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentRequestMessage ==
    { ZeroAddComplexInstrumentRequestMessage }
        \cup { [ZeroAddComplexInstrumentRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentRequestMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroAddComplexInstrumentRequestMessage EXCEPT !.complexLegs = one] : one \in SampleLists(OneComplexLegs) }

(***************************************************************************)
(* Mm Parameter Definition Request Message: 74 bytes                       *)
(***************************************************************************)

MmParameterDefinitionRequestMessage ==
    [ badge          : Sample(4),
      messageId      : Sample(8),
      instrumentType : Sample(1),
      underlying     : Sample(13),
      interval       : Sample(2),
      percentage     : Sample(2),
      cumQty         : Sample(4),
      delta          : Sample(4),
      vega           : Sample(4),
      reserved32     : Sample(32) ]

EncodeMmParameterDefinitionRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.instrumentType
        \o message.underlying
        \o message.interval
        \o message.percentage
        \o message.cumQty
        \o message.delta
        \o message.vega
        \o message.reserved32

DecodeMmParameterDefinitionRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(messageId.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET underlying == ReadBytes(instrumentType.rest, 13) IN IF ~underlying.ok THEN Fail ELSE
    LET interval == ReadBytes(underlying.rest, 2) IN IF ~interval.ok THEN Fail ELSE
    LET percentage == ReadBytes(interval.rest, 2) IN IF ~percentage.ok THEN Fail ELSE
    LET cumQty == ReadBytes(percentage.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET delta == ReadBytes(cumQty.rest, 4) IN IF ~delta.ok THEN Fail ELSE
    LET vega == ReadBytes(delta.rest, 4) IN IF ~vega.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(vega.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ badge          |-> badge.value,
         messageId      |-> messageId.value,
         instrumentType |-> instrumentType.value,
         underlying     |-> underlying.value,
         interval       |-> interval.value,
         percentage     |-> percentage.value,
         cumQty         |-> cumQty.value,
         delta          |-> delta.value,
         vega           |-> vega.value,
         reserved32     |-> reserved32.value ], reserved32.rest)

ZeroMmParameterDefinitionRequestMessage ==
    [ badge          |-> [i \in 1 .. 4 |-> 0],
      messageId      |-> [i \in 1 .. 8 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0],
      underlying     |-> [i \in 1 .. 13 |-> 0],
      interval       |-> [i \in 1 .. 2 |-> 0],
      percentage     |-> [i \in 1 .. 2 |-> 0],
      cumQty         |-> [i \in 1 .. 4 |-> 0],
      delta          |-> [i \in 1 .. 4 |-> 0],
      vega           |-> [i \in 1 .. 4 |-> 0],
      reserved32     |-> [i \in 1 .. 32 |-> 0] ]

(* Mm Parameter Definition Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMmParameterDefinitionRequestMessage ==
    { ZeroMmParameterDefinitionRequestMessage }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.underlying = one] : one \in Sample(13) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.interval = one] : one \in Sample(2) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.percentage = one] : one \in Sample(2) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.delta = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.vega = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequestMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Active Qp Self Replenishment Set Limit Message: 29 bytes                *)
(***************************************************************************)

ActiveQpSelfReplenishmentSetLimitMessage ==
    [ badge            : Sample(4),
      messageId        : Sample(8),
      underlyingSymbol : Sample(13),
      setValue         : Sample(4) ]

EncodeActiveQpSelfReplenishmentSetLimitMessage(message) ==
    message.badge
        \o message.messageId
        \o message.underlyingSymbol
        \o message.setValue

DecodeActiveQpSelfReplenishmentSetLimitMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(messageId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET setValue == ReadBytes(underlyingSymbol.rest, 4) IN IF ~setValue.ok THEN Fail ELSE
    Ok([ badge            |-> badge.value,
         messageId        |-> messageId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         setValue         |-> setValue.value ], setValue.rest)

ZeroActiveQpSelfReplenishmentSetLimitMessage ==
    [ badge            |-> [i \in 1 .. 4 |-> 0],
      messageId        |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      setValue         |-> [i \in 1 .. 4 |-> 0] ]

(* Active Qp Self Replenishment Set Limit Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveQpSelfReplenishmentSetLimitMessage ==
    { ZeroActiveQpSelfReplenishmentSetLimitMessage }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitMessage EXCEPT !.setValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Rapid Fire Config Request Message: 25 bytes                             *)
(***************************************************************************)

RapidFireConfigRequestMessage ==
    [ badge            : Sample(4),
      underlyingSymbol : Sample(13),
      percentage       : Sample(2),
      interval         : Sample(2),
      cumQty           : Sample(4) ]

EncodeRapidFireConfigRequestMessage(message) ==
    message.badge
        \o message.underlyingSymbol
        \o message.percentage
        \o message.interval
        \o message.cumQty

DecodeRapidFireConfigRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(badge.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET percentage == ReadBytes(underlyingSymbol.rest, 2) IN IF ~percentage.ok THEN Fail ELSE
    LET interval == ReadBytes(percentage.rest, 2) IN IF ~interval.ok THEN Fail ELSE
    LET cumQty == ReadBytes(interval.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    Ok([ badge            |-> badge.value,
         underlyingSymbol |-> underlyingSymbol.value,
         percentage       |-> percentage.value,
         interval         |-> interval.value,
         cumQty           |-> cumQty.value ], cumQty.rest)

ZeroRapidFireConfigRequestMessage ==
    [ badge            |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      percentage       |-> [i \in 1 .. 2 |-> 0],
      interval         |-> [i \in 1 .. 2 |-> 0],
      cumQty           |-> [i \in 1 .. 4 |-> 0] ]

(* Rapid Fire Config Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRapidFireConfigRequestMessage ==
    { ZeroRapidFireConfigRequestMessage }
        \cup { [ZeroRapidFireConfigRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroRapidFireConfigRequestMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroRapidFireConfigRequestMessage EXCEPT !.percentage = one] : one \in Sample(2) }
        \cup { [ZeroRapidFireConfigRequestMessage EXCEPT !.interval = one] : one \in Sample(2) }
        \cup { [ZeroRapidFireConfigRequestMessage EXCEPT !.cumQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Quotes: 21 bytes                                                 *)
(***************************************************************************)

SimpleQuotes ==
    [ instrumentId     : Sample(4),
      bidPrice         : Sample(4),
      bidSize          : Sample(4),
      askPrice         : Sample(4),
      askSize          : Sample(4),
      reentryIndicator : Sample(1) ]

EncodeSimpleQuotes(message) ==
    message.instrumentId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.reentryIndicator

DecodeSimpleQuotes(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET reentryIndicator == ReadBytes(askSize.rest, 1) IN IF ~reentryIndicator.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         bidPrice         |-> bidPrice.value,
         bidSize          |-> bidSize.value,
         askPrice         |-> askPrice.value,
         askSize          |-> askSize.value,
         reentryIndicator |-> reentryIndicator.value ], reentryIndicator.rest)

ZeroSimpleQuotes ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 4 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      reentryIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Quotes at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuotes ==
    { ZeroSimpleQuotes }
        \cup { [ZeroSimpleQuotes EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes EXCEPT !.reentryIndicator = one] : one \in Sample(1) }

(* A run of Simple Quotes, written one after another *)
RECURSIVE EncodeSimpleQuotesList(_)
EncodeSimpleQuotesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSimpleQuotes(Head(messages)) \o EncodeSimpleQuotesList(Tail(messages))

(* As many Simple Quotes as the field that counts them says *)
RECURSIVE ReadSimpleQuotesList(_, _)
ReadSimpleQuotesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSimpleQuotes(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSimpleQuotesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Simple Quotes of each kind, for the lists that carry them *)
OneSimpleQuotes == { ZeroSimpleQuotes }

(***************************************************************************)
(* Simple Quote Block Short Form Message                                   *)
(***************************************************************************)

SimpleQuoteBlockShortFormMessage ==
    [ badge         : Sample(4),
      messageId     : Sample(8),
      sentTimestamp : Sample(8),
      simpleQuotes  : SampleLists(OneSimpleQuotes) ]

EncodeSimpleQuoteBlockShortFormMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o EncodeUIntBE(Len(message.simpleQuotes), 2)
        \o EncodeSimpleQuotesList(message.simpleQuotes)

DecodeSimpleQuoteBlockShortFormMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(sentTimestamp.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET simpleQuotes == ReadSimpleQuotesList(quoteCount.rest, quoteCount.value) IN IF ~simpleQuotes.ok THEN Fail ELSE
    Ok([ badge         |-> badge.value,
         messageId     |-> messageId.value,
         sentTimestamp |-> sentTimestamp.value,
         simpleQuotes  |-> simpleQuotes.value ], simpleQuotes.rest)

ZeroSimpleQuoteBlockShortFormMessage ==
    [ badge         |-> [i \in 1 .. 4 |-> 0],
      messageId     |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp |-> [i \in 1 .. 8 |-> 0],
      simpleQuotes  |-> << >> ]

(* Simple Quote Block Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteBlockShortFormMessage ==
    { ZeroSimpleQuoteBlockShortFormMessage }
        \cup { [ZeroSimpleQuoteBlockShortFormMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteBlockShortFormMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockShortFormMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockShortFormMessage EXCEPT !.simpleQuotes = one] : one \in SampleLists(OneSimpleQuotes) }

(***************************************************************************)
(* Simple Quotes: 21 bytes                                                 *)
(***************************************************************************)

SimpleQuotes2 ==
    [ instrumentId     : Sample(4),
      bidPrice         : Sample(4),
      bidSize          : Sample(4),
      askPrice         : Sample(4),
      askSize          : Sample(4),
      reentryIndicator : Sample(1) ]

EncodeSimpleQuotes2(message) ==
    message.instrumentId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.reentryIndicator

DecodeSimpleQuotes2(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET reentryIndicator == ReadBytes(askSize.rest, 1) IN IF ~reentryIndicator.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         bidPrice         |-> bidPrice.value,
         bidSize          |-> bidSize.value,
         askPrice         |-> askPrice.value,
         askSize          |-> askSize.value,
         reentryIndicator |-> reentryIndicator.value ], reentryIndicator.rest)

ZeroSimpleQuotes2 ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 4 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      reentryIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Quotes at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuotes2 ==
    { ZeroSimpleQuotes2 }
        \cup { [ZeroSimpleQuotes2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes2 EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes2 EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes2 EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes2 EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotes2 EXCEPT !.reentryIndicator = one] : one \in Sample(1) }

(* A run of Simple Quotes, written one after another *)
RECURSIVE EncodeSimpleQuotes2List(_)
EncodeSimpleQuotes2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSimpleQuotes2(Head(messages)) \o EncodeSimpleQuotes2List(Tail(messages))

(* As many Simple Quotes as the field that counts them says *)
RECURSIVE ReadSimpleQuotes2List(_, _)
ReadSimpleQuotes2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSimpleQuotes2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSimpleQuotes2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Simple Quotes of each kind, for the lists that carry them *)
OneSimpleQuotes2 == { ZeroSimpleQuotes2 }

(***************************************************************************)
(* Simple Quote Block Short Form Detailed Message                          *)
(***************************************************************************)

SimpleQuoteBlockShortFormDetailedMessage ==
    [ badge         : Sample(4),
      messageId     : Sample(8),
      sentTimestamp : Sample(8),
      simpleQuotes  : SampleLists(OneSimpleQuotes2) ]

EncodeSimpleQuoteBlockShortFormDetailedMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o EncodeUIntBE(Len(message.simpleQuotes), 2)
        \o EncodeSimpleQuotes2List(message.simpleQuotes)

DecodeSimpleQuoteBlockShortFormDetailedMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(sentTimestamp.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET simpleQuotes == ReadSimpleQuotes2List(quoteCount.rest, quoteCount.value) IN IF ~simpleQuotes.ok THEN Fail ELSE
    Ok([ badge         |-> badge.value,
         messageId     |-> messageId.value,
         sentTimestamp |-> sentTimestamp.value,
         simpleQuotes  |-> simpleQuotes.value ], simpleQuotes.rest)

ZeroSimpleQuoteBlockShortFormDetailedMessage ==
    [ badge         |-> [i \in 1 .. 4 |-> 0],
      messageId     |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp |-> [i \in 1 .. 8 |-> 0],
      simpleQuotes  |-> << >> ]

(* Simple Quote Block Short Form Detailed Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteBlockShortFormDetailedMessage ==
    { ZeroSimpleQuoteBlockShortFormDetailedMessage }
        \cup { [ZeroSimpleQuoteBlockShortFormDetailedMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteBlockShortFormDetailedMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockShortFormDetailedMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockShortFormDetailedMessage EXCEPT !.simpleQuotes = one] : one \in SampleLists(OneSimpleQuotes2) }

(***************************************************************************)
(* Simple Quotes Long Form: 29 bytes                                       *)
(***************************************************************************)

SimpleQuotesLongForm ==
    [ quoteId          : Sample(8),
      instrumentId     : Sample(4),
      bidPrice         : Sample(4),
      bidSize          : Sample(4),
      askPrice         : Sample(4),
      askSize          : Sample(4),
      reentryIndicator : Sample(1) ]

EncodeSimpleQuotesLongForm(message) ==
    message.quoteId
        \o message.instrumentId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.reentryIndicator

DecodeSimpleQuotesLongForm(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quoteId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET reentryIndicator == ReadBytes(askSize.rest, 1) IN IF ~reentryIndicator.ok THEN Fail ELSE
    Ok([ quoteId          |-> quoteId.value,
         instrumentId     |-> instrumentId.value,
         bidPrice         |-> bidPrice.value,
         bidSize          |-> bidSize.value,
         askPrice         |-> askPrice.value,
         askSize          |-> askSize.value,
         reentryIndicator |-> reentryIndicator.value ], reentryIndicator.rest)

ZeroSimpleQuotesLongForm ==
    [ quoteId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 4 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      reentryIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Quotes Long Form at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuotesLongForm ==
    { ZeroSimpleQuotesLongForm }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm EXCEPT !.reentryIndicator = one] : one \in Sample(1) }

(* A run of Simple Quotes Long Form, written one after another *)
RECURSIVE EncodeSimpleQuotesLongFormList(_)
EncodeSimpleQuotesLongFormList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSimpleQuotesLongForm(Head(messages)) \o EncodeSimpleQuotesLongFormList(Tail(messages))

(* As many Simple Quotes Long Form as the field that counts them says *)
RECURSIVE ReadSimpleQuotesLongFormList(_, _)
ReadSimpleQuotesLongFormList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSimpleQuotesLongForm(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSimpleQuotesLongFormList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Simple Quotes Long Form of each kind, for the lists that carry them *)
OneSimpleQuotesLongForm == { ZeroSimpleQuotesLongForm }

(***************************************************************************)
(* Simple Quote Block Long Form Message                                    *)
(***************************************************************************)

SimpleQuoteBlockLongFormMessage ==
    [ badge                : Sample(4),
      messageId            : Sample(8),
      sentTimestamp        : Sample(8),
      simpleQuotesLongForm : SampleLists(OneSimpleQuotesLongForm) ]

EncodeSimpleQuoteBlockLongFormMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o EncodeUIntBE(Len(message.simpleQuotesLongForm), 2)
        \o EncodeSimpleQuotesLongFormList(message.simpleQuotesLongForm)

DecodeSimpleQuoteBlockLongFormMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(sentTimestamp.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET simpleQuotesLongForm == ReadSimpleQuotesLongFormList(quoteCount.rest, quoteCount.value) IN IF ~simpleQuotesLongForm.ok THEN Fail ELSE
    Ok([ badge                |-> badge.value,
         messageId            |-> messageId.value,
         sentTimestamp        |-> sentTimestamp.value,
         simpleQuotesLongForm |-> simpleQuotesLongForm.value ], simpleQuotesLongForm.rest)

ZeroSimpleQuoteBlockLongFormMessage ==
    [ badge                |-> [i \in 1 .. 4 |-> 0],
      messageId            |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp        |-> [i \in 1 .. 8 |-> 0],
      simpleQuotesLongForm |-> << >> ]

(* Simple Quote Block Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteBlockLongFormMessage ==
    { ZeroSimpleQuoteBlockLongFormMessage }
        \cup { [ZeroSimpleQuoteBlockLongFormMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteBlockLongFormMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockLongFormMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockLongFormMessage EXCEPT !.simpleQuotesLongForm = one] : one \in SampleLists(OneSimpleQuotesLongForm) }

(***************************************************************************)
(* Simple Quotes Long Form: 29 bytes                                       *)
(***************************************************************************)

SimpleQuotesLongForm2 ==
    [ quoteId          : Sample(8),
      instrumentId     : Sample(4),
      bidPrice         : Sample(4),
      bidSize          : Sample(4),
      askPrice         : Sample(4),
      askSize          : Sample(4),
      reentryIndicator : Sample(1) ]

EncodeSimpleQuotesLongForm2(message) ==
    message.quoteId
        \o message.instrumentId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.reentryIndicator

DecodeSimpleQuotesLongForm2(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quoteId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET reentryIndicator == ReadBytes(askSize.rest, 1) IN IF ~reentryIndicator.ok THEN Fail ELSE
    Ok([ quoteId          |-> quoteId.value,
         instrumentId     |-> instrumentId.value,
         bidPrice         |-> bidPrice.value,
         bidSize          |-> bidSize.value,
         askPrice         |-> askPrice.value,
         askSize          |-> askSize.value,
         reentryIndicator |-> reentryIndicator.value ], reentryIndicator.rest)

ZeroSimpleQuotesLongForm2 ==
    [ quoteId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 4 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      reentryIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Quotes Long Form at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuotesLongForm2 ==
    { ZeroSimpleQuotesLongForm2 }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuotesLongForm2 EXCEPT !.reentryIndicator = one] : one \in Sample(1) }

(* A run of Simple Quotes Long Form, written one after another *)
RECURSIVE EncodeSimpleQuotesLongForm2List(_)
EncodeSimpleQuotesLongForm2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSimpleQuotesLongForm2(Head(messages)) \o EncodeSimpleQuotesLongForm2List(Tail(messages))

(* As many Simple Quotes Long Form as the field that counts them says *)
RECURSIVE ReadSimpleQuotesLongForm2List(_, _)
ReadSimpleQuotesLongForm2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSimpleQuotesLongForm2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSimpleQuotesLongForm2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Simple Quotes Long Form of each kind, for the lists that carry them *)
OneSimpleQuotesLongForm2 == { ZeroSimpleQuotesLongForm2 }

(***************************************************************************)
(* Simple Quote Block Long Form Detailed Message                           *)
(***************************************************************************)

SimpleQuoteBlockLongFormDetailedMessage ==
    [ badge                : Sample(4),
      messageId            : Sample(8),
      sentTimestamp        : Sample(8),
      simpleQuotesLongForm : SampleLists(OneSimpleQuotesLongForm2) ]

EncodeSimpleQuoteBlockLongFormDetailedMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o EncodeUIntBE(Len(message.simpleQuotesLongForm), 2)
        \o EncodeSimpleQuotesLongForm2List(message.simpleQuotesLongForm)

DecodeSimpleQuoteBlockLongFormDetailedMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(sentTimestamp.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET simpleQuotesLongForm == ReadSimpleQuotesLongForm2List(quoteCount.rest, quoteCount.value) IN IF ~simpleQuotesLongForm.ok THEN Fail ELSE
    Ok([ badge                |-> badge.value,
         messageId            |-> messageId.value,
         sentTimestamp        |-> sentTimestamp.value,
         simpleQuotesLongForm |-> simpleQuotesLongForm.value ], simpleQuotesLongForm.rest)

ZeroSimpleQuoteBlockLongFormDetailedMessage ==
    [ badge                |-> [i \in 1 .. 4 |-> 0],
      messageId            |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp        |-> [i \in 1 .. 8 |-> 0],
      simpleQuotesLongForm |-> << >> ]

(* Simple Quote Block Long Form Detailed Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteBlockLongFormDetailedMessage ==
    { ZeroSimpleQuoteBlockLongFormDetailedMessage }
        \cup { [ZeroSimpleQuoteBlockLongFormDetailedMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteBlockLongFormDetailedMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockLongFormDetailedMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteBlockLongFormDetailedMessage EXCEPT !.simpleQuotesLongForm = one] : one \in SampleLists(OneSimpleQuotesLongForm2) }

(***************************************************************************)
(* Complex Quotes: 34 bytes                                                *)
(***************************************************************************)

ComplexQuotes ==
    [ quoteId           : Sample(8),
      instrumentId      : Sample(4),
      bidPrice          : Sample(4),
      bidSize           : Sample(4),
      askPrice          : Sample(4),
      askSize           : Sample(4),
      reentryIndicator  : Sample(1),
      stockLegShortSale : Sample(1),
      reserved4         : Sample(4) ]

EncodeComplexQuotes(message) ==
    message.quoteId
        \o message.instrumentId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.reentryIndicator
        \o message.stockLegShortSale
        \o message.reserved4

DecodeComplexQuotes(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quoteId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET reentryIndicator == ReadBytes(askSize.rest, 1) IN IF ~reentryIndicator.ok THEN Fail ELSE
    LET stockLegShortSale == ReadBytes(reentryIndicator.rest, 1) IN IF ~stockLegShortSale.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(stockLegShortSale.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ quoteId           |-> quoteId.value,
         instrumentId      |-> instrumentId.value,
         bidPrice          |-> bidPrice.value,
         bidSize           |-> bidSize.value,
         askPrice          |-> askPrice.value,
         askSize           |-> askSize.value,
         reentryIndicator  |-> reentryIndicator.value,
         stockLegShortSale |-> stockLegShortSale.value,
         reserved4         |-> reserved4.value ], reserved4.rest)

ZeroComplexQuotes ==
    [ quoteId           |-> [i \in 1 .. 8 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      bidPrice          |-> [i \in 1 .. 4 |-> 0],
      bidSize           |-> [i \in 1 .. 4 |-> 0],
      askPrice          |-> [i \in 1 .. 4 |-> 0],
      askSize           |-> [i \in 1 .. 4 |-> 0],
      reentryIndicator  |-> [i \in 1 .. 1 |-> 0],
      stockLegShortSale |-> [i \in 1 .. 1 |-> 0],
      reserved4         |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Quotes at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuotes ==
    { ZeroComplexQuotes }
        \cup { [ZeroComplexQuotes EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuotes EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes EXCEPT !.reentryIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuotes EXCEPT !.stockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuotes EXCEPT !.reserved4 = one] : one \in Sample(4) }

(* A run of Complex Quotes, written one after another *)
RECURSIVE EncodeComplexQuotesList(_)
EncodeComplexQuotesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexQuotes(Head(messages)) \o EncodeComplexQuotesList(Tail(messages))

(* As many Complex Quotes as the field that counts them says *)
RECURSIVE ReadComplexQuotesList(_, _)
ReadComplexQuotesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexQuotes(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexQuotesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Quotes of each kind, for the lists that carry them *)
OneComplexQuotes == { ZeroComplexQuotes }

(***************************************************************************)
(* Complex Quote Block Message                                             *)
(***************************************************************************)

ComplexQuoteBlockMessage ==
    [ badge         : Sample(4),
      messageId     : Sample(8),
      sentTimestamp : Sample(8),
      complexQuotes : SampleLists(OneComplexQuotes) ]

EncodeComplexQuoteBlockMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o EncodeUIntBE(Len(message.complexQuotes), 2)
        \o EncodeComplexQuotesList(message.complexQuotes)

DecodeComplexQuoteBlockMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(sentTimestamp.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET complexQuotes == ReadComplexQuotesList(quoteCount.rest, quoteCount.value) IN IF ~complexQuotes.ok THEN Fail ELSE
    Ok([ badge         |-> badge.value,
         messageId     |-> messageId.value,
         sentTimestamp |-> sentTimestamp.value,
         complexQuotes |-> complexQuotes.value ], complexQuotes.rest)

ZeroComplexQuoteBlockMessage ==
    [ badge         |-> [i \in 1 .. 4 |-> 0],
      messageId     |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp |-> [i \in 1 .. 8 |-> 0],
      complexQuotes |-> << >> ]

(* Complex Quote Block Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteBlockMessage ==
    { ZeroComplexQuoteBlockMessage }
        \cup { [ZeroComplexQuoteBlockMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteBlockMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteBlockMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteBlockMessage EXCEPT !.complexQuotes = one] : one \in SampleLists(OneComplexQuotes) }

(***************************************************************************)
(* Complex Quotes: 34 bytes                                                *)
(***************************************************************************)

ComplexQuotes2 ==
    [ quoteId           : Sample(8),
      instrumentId      : Sample(4),
      bidPrice          : Sample(4),
      bidSize           : Sample(4),
      askPrice          : Sample(4),
      askSize           : Sample(4),
      reentryIndicator  : Sample(1),
      stockLegShortSale : Sample(1),
      reserved4         : Sample(4) ]

EncodeComplexQuotes2(message) ==
    message.quoteId
        \o message.instrumentId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.reentryIndicator
        \o message.stockLegShortSale
        \o message.reserved4

DecodeComplexQuotes2(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quoteId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET reentryIndicator == ReadBytes(askSize.rest, 1) IN IF ~reentryIndicator.ok THEN Fail ELSE
    LET stockLegShortSale == ReadBytes(reentryIndicator.rest, 1) IN IF ~stockLegShortSale.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(stockLegShortSale.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ quoteId           |-> quoteId.value,
         instrumentId      |-> instrumentId.value,
         bidPrice          |-> bidPrice.value,
         bidSize           |-> bidSize.value,
         askPrice          |-> askPrice.value,
         askSize           |-> askSize.value,
         reentryIndicator  |-> reentryIndicator.value,
         stockLegShortSale |-> stockLegShortSale.value,
         reserved4         |-> reserved4.value ], reserved4.rest)

ZeroComplexQuotes2 ==
    [ quoteId           |-> [i \in 1 .. 8 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      bidPrice          |-> [i \in 1 .. 4 |-> 0],
      bidSize           |-> [i \in 1 .. 4 |-> 0],
      askPrice          |-> [i \in 1 .. 4 |-> 0],
      askSize           |-> [i \in 1 .. 4 |-> 0],
      reentryIndicator  |-> [i \in 1 .. 1 |-> 0],
      stockLegShortSale |-> [i \in 1 .. 1 |-> 0],
      reserved4         |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Quotes at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuotes2 ==
    { ZeroComplexQuotes2 }
        \cup { [ZeroComplexQuotes2 EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.reentryIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.stockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuotes2 EXCEPT !.reserved4 = one] : one \in Sample(4) }

(* A run of Complex Quotes, written one after another *)
RECURSIVE EncodeComplexQuotes2List(_)
EncodeComplexQuotes2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexQuotes2(Head(messages)) \o EncodeComplexQuotes2List(Tail(messages))

(* As many Complex Quotes as the field that counts them says *)
RECURSIVE ReadComplexQuotes2List(_, _)
ReadComplexQuotes2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexQuotes2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexQuotes2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Quotes of each kind, for the lists that carry them *)
OneComplexQuotes2 == { ZeroComplexQuotes2 }

(***************************************************************************)
(* Complex Quote Block Detailed Message                                    *)
(***************************************************************************)

ComplexQuoteBlockDetailedMessage ==
    [ badge         : Sample(4),
      messageId     : Sample(8),
      sentTimestamp : Sample(8),
      complexQuotes : SampleLists(OneComplexQuotes2) ]

EncodeComplexQuoteBlockDetailedMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o EncodeUIntBE(Len(message.complexQuotes), 2)
        \o EncodeComplexQuotes2List(message.complexQuotes)

DecodeComplexQuoteBlockDetailedMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(sentTimestamp.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET complexQuotes == ReadComplexQuotes2List(quoteCount.rest, quoteCount.value) IN IF ~complexQuotes.ok THEN Fail ELSE
    Ok([ badge         |-> badge.value,
         messageId     |-> messageId.value,
         sentTimestamp |-> sentTimestamp.value,
         complexQuotes |-> complexQuotes.value ], complexQuotes.rest)

ZeroComplexQuoteBlockDetailedMessage ==
    [ badge         |-> [i \in 1 .. 4 |-> 0],
      messageId     |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp |-> [i \in 1 .. 8 |-> 0],
      complexQuotes |-> << >> ]

(* Complex Quote Block Detailed Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteBlockDetailedMessage ==
    { ZeroComplexQuoteBlockDetailedMessage }
        \cup { [ZeroComplexQuoteBlockDetailedMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteBlockDetailedMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteBlockDetailedMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteBlockDetailedMessage EXCEPT !.complexQuotes = one] : one \in SampleLists(OneComplexQuotes2) }

(***************************************************************************)
(* Underlying Purge Request Message: 34 bytes                              *)
(***************************************************************************)

UnderlyingPurgeRequestMessage ==
    [ badge            : Sample(4),
      messageId        : Sample(8),
      sentTimestamp    : Sample(8),
      underlyingSymbol : Sample(13),
      instrumentType   : Sample(1) ]

EncodeUnderlyingPurgeRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o message.underlyingSymbol
        \o message.instrumentType

DecodeUnderlyingPurgeRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(sentTimestamp.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ badge            |-> badge.value,
         messageId        |-> messageId.value,
         sentTimestamp    |-> sentTimestamp.value,
         underlyingSymbol |-> underlyingSymbol.value,
         instrumentType   |-> instrumentType.value ], instrumentType.rest)

ZeroUnderlyingPurgeRequestMessage ==
    [ badge            |-> [i \in 1 .. 4 |-> 0],
      messageId        |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp    |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Purge Request Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingPurgeRequestMessage ==
    { ZeroUnderlyingPurgeRequestMessage }
        \cup { [ZeroUnderlyingPurgeRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPurgeRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPurgeRequestMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPurgeRequestMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroUnderlyingPurgeRequestMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Reentry Request Message: 26 bytes                                *)
(***************************************************************************)

MarketReentryRequestMessage ==
    [ badge            : Sample(4),
      messageId        : Sample(8),
      underlyingSymbol : Sample(13),
      instrumentType   : Sample(1) ]

EncodeMarketReentryRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.underlyingSymbol
        \o message.instrumentType

DecodeMarketReentryRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(messageId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    Ok([ badge            |-> badge.value,
         messageId        |-> messageId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         instrumentType   |-> instrumentType.value ], instrumentType.rest)

ZeroMarketReentryRequestMessage ==
    [ badge            |-> [i \in 1 .. 4 |-> 0],
      messageId        |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0] ]

(* Market Reentry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketReentryRequestMessage ==
    { ZeroMarketReentryRequestMessage }
        \cup { [ZeroMarketReentryRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMarketReentryRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMarketReentryRequestMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroMarketReentryRequestMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }

(***************************************************************************)
(* Active Qp Self Replenishment Request Reentry Message: 29 bytes          *)
(***************************************************************************)

ActiveQpSelfReplenishmentRequestReentryMessage ==
    [ badge              : Sample(4),
      messageId          : Sample(8),
      underlyingSymbol   : Sample(13),
      replenishmentValue : Sample(4) ]

EncodeActiveQpSelfReplenishmentRequestReentryMessage(message) ==
    message.badge
        \o message.messageId
        \o message.underlyingSymbol
        \o message.replenishmentValue

DecodeActiveQpSelfReplenishmentRequestReentryMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(messageId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET replenishmentValue == ReadBytes(underlyingSymbol.rest, 4) IN IF ~replenishmentValue.ok THEN Fail ELSE
    Ok([ badge              |-> badge.value,
         messageId          |-> messageId.value,
         underlyingSymbol   |-> underlyingSymbol.value,
         replenishmentValue |-> replenishmentValue.value ], replenishmentValue.rest)

ZeroActiveQpSelfReplenishmentRequestReentryMessage ==
    [ badge              |-> [i \in 1 .. 4 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol   |-> [i \in 1 .. 13 |-> 0],
      replenishmentValue |-> [i \in 1 .. 4 |-> 0] ]

(* Active Qp Self Replenishment Request Reentry Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveQpSelfReplenishmentRequestReentryMessage ==
    { ZeroActiveQpSelfReplenishmentRequestReentryMessage }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryMessage EXCEPT !.replenishmentValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Msar Request Message: 30 bytes                                   *)
(***************************************************************************)

SimpleMsarRequestMessage ==
    [ badge        : Sample(4),
      messageId    : Sample(8),
      instrumentId : Sample(4),
      msarType     : Sample(1),
      auctionId    : Sample(4),
      price        : Sample(4),
      side         : Sample(1),
      contracts    : Sample(4) ]

EncodeSimpleMsarRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.msarType
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.contracts

DecodeSimpleMsarRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(messageId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET msarType == ReadBytes(instrumentId.rest, 1) IN IF ~msarType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(msarType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ badge        |-> badge.value,
         messageId    |-> messageId.value,
         instrumentId |-> instrumentId.value,
         msarType     |-> msarType.value,
         auctionId    |-> auctionId.value,
         price        |-> price.value,
         side         |-> side.value,
         contracts    |-> contracts.value ], contracts.rest)

ZeroSimpleMsarRequestMessage ==
    [ badge        |-> [i \in 1 .. 4 |-> 0],
      messageId    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      msarType     |-> [i \in 1 .. 1 |-> 0],
      auctionId    |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      contracts    |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Msar Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleMsarRequestMessage ==
    { ZeroSimpleMsarRequestMessage }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.msarType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleMsarRequestMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Msar Request Message: 36 bytes                                  *)
(***************************************************************************)

ComplexMsarRequestMessage ==
    [ badge           : Sample(4),
      messageId       : Sample(8),
      instrumentId    : Sample(4),
      msarType        : Sample(1),
      auctionId       : Sample(4),
      price           : Sample(4),
      side            : Sample(1),
      debitCredit     : Sample(1),
      contracts       : Sample(4),
      priceProtection : Sample(1),
      reserved4       : Sample(4) ]

EncodeComplexMsarRequestMessage(message) ==
    message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.msarType
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.debitCredit
        \o message.contracts
        \o message.priceProtection
        \o message.reserved4

DecodeComplexMsarRequestMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(messageId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET msarType == ReadBytes(instrumentId.rest, 1) IN IF ~msarType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(msarType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET debitCredit == ReadBytes(side.rest, 1) IN IF ~debitCredit.ok THEN Fail ELSE
    LET contracts == ReadBytes(debitCredit.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(contracts.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(priceProtection.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ badge           |-> badge.value,
         messageId       |-> messageId.value,
         instrumentId    |-> instrumentId.value,
         msarType        |-> msarType.value,
         auctionId       |-> auctionId.value,
         price           |-> price.value,
         side            |-> side.value,
         debitCredit     |-> debitCredit.value,
         contracts       |-> contracts.value,
         priceProtection |-> priceProtection.value,
         reserved4       |-> reserved4.value ], reserved4.rest)

ZeroComplexMsarRequestMessage ==
    [ badge           |-> [i \in 1 .. 4 |-> 0],
      messageId       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      msarType        |-> [i \in 1 .. 1 |-> 0],
      auctionId       |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      debitCredit     |-> [i \in 1 .. 1 |-> 0],
      contracts       |-> [i \in 1 .. 4 |-> 0],
      priceProtection |-> [i \in 1 .. 1 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Msar Request Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexMsarRequestMessage ==
    { ZeroComplexMsarRequestMessage }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.msarType = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.debitCredit = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

NotificationSubscriptionRequestMessageCode == 16706  \* "AB"
AddComplexInstrumentRequestMessageCode == 16707  \* "AC"
MmParameterDefinitionRequestMessageCode == 16709  \* "AE"
ActiveQpSelfReplenishmentSetLimitMessageCode == 16711  \* "AG"
RapidFireConfigRequestMessageCode == 16710  \* "AF"
SimpleQuoteBlockShortFormMessageCode == 20801  \* "QA"
SimpleQuoteBlockShortFormDetailedMessageCode == 20833  \* "Qa"
SimpleQuoteBlockLongFormMessageCode == 20813  \* "QM"
SimpleQuoteBlockLongFormDetailedMessageCode == 20845  \* "Qm"
ComplexQuoteBlockMessageCode == 20804  \* "QD"
ComplexQuoteBlockDetailedMessageCode == 20836  \* "Qd"
UnderlyingPurgeRequestMessageCode == 20597  \* "Pu"
MarketReentryRequestMessageCode == 21077  \* "RU"
ActiveQpSelfReplenishmentRequestReentryMessageCode == 21063  \* "RG"
SimpleMsarRequestMessageCode == 21314  \* "SB"
ComplexMsarRequestMessageCode == 21336  \* "SX"

UnsequencedMessage ==
    [ tag : {NotificationSubscriptionRequestMessageCode}, body : NotificationSubscriptionRequestMessage ]
        \cup [ tag : {AddComplexInstrumentRequestMessageCode}, body : AddComplexInstrumentRequestMessage ]
        \cup [ tag : {MmParameterDefinitionRequestMessageCode}, body : MmParameterDefinitionRequestMessage ]
        \cup [ tag : {ActiveQpSelfReplenishmentSetLimitMessageCode}, body : ActiveQpSelfReplenishmentSetLimitMessage ]
        \cup [ tag : {RapidFireConfigRequestMessageCode}, body : RapidFireConfigRequestMessage ]
        \cup [ tag : {SimpleQuoteBlockShortFormMessageCode}, body : SimpleQuoteBlockShortFormMessage ]
        \cup [ tag : {SimpleQuoteBlockShortFormDetailedMessageCode}, body : SimpleQuoteBlockShortFormDetailedMessage ]
        \cup [ tag : {SimpleQuoteBlockLongFormMessageCode}, body : SimpleQuoteBlockLongFormMessage ]
        \cup [ tag : {SimpleQuoteBlockLongFormDetailedMessageCode}, body : SimpleQuoteBlockLongFormDetailedMessage ]
        \cup [ tag : {ComplexQuoteBlockMessageCode}, body : ComplexQuoteBlockMessage ]
        \cup [ tag : {ComplexQuoteBlockDetailedMessageCode}, body : ComplexQuoteBlockDetailedMessage ]
        \cup [ tag : {UnderlyingPurgeRequestMessageCode}, body : UnderlyingPurgeRequestMessage ]
        \cup [ tag : {MarketReentryRequestMessageCode}, body : MarketReentryRequestMessage ]
        \cup [ tag : {ActiveQpSelfReplenishmentRequestReentryMessageCode}, body : ActiveQpSelfReplenishmentRequestReentryMessage ]
        \cup [ tag : {SimpleMsarRequestMessageCode}, body : SimpleMsarRequestMessage ]
        \cup [ tag : {ComplexMsarRequestMessageCode}, body : ComplexMsarRequestMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = NotificationSubscriptionRequestMessageCode -> EncodeNotificationSubscriptionRequestMessage(message.body)
      [] message.tag = AddComplexInstrumentRequestMessageCode -> EncodeAddComplexInstrumentRequestMessage(message.body)
      [] message.tag = MmParameterDefinitionRequestMessageCode -> EncodeMmParameterDefinitionRequestMessage(message.body)
      [] message.tag = ActiveQpSelfReplenishmentSetLimitMessageCode -> EncodeActiveQpSelfReplenishmentSetLimitMessage(message.body)
      [] message.tag = RapidFireConfigRequestMessageCode -> EncodeRapidFireConfigRequestMessage(message.body)
      [] message.tag = SimpleQuoteBlockShortFormMessageCode -> EncodeSimpleQuoteBlockShortFormMessage(message.body)
      [] message.tag = SimpleQuoteBlockShortFormDetailedMessageCode -> EncodeSimpleQuoteBlockShortFormDetailedMessage(message.body)
      [] message.tag = SimpleQuoteBlockLongFormMessageCode -> EncodeSimpleQuoteBlockLongFormMessage(message.body)
      [] message.tag = SimpleQuoteBlockLongFormDetailedMessageCode -> EncodeSimpleQuoteBlockLongFormDetailedMessage(message.body)
      [] message.tag = ComplexQuoteBlockMessageCode -> EncodeComplexQuoteBlockMessage(message.body)
      [] message.tag = ComplexQuoteBlockDetailedMessageCode -> EncodeComplexQuoteBlockDetailedMessage(message.body)
      [] message.tag = UnderlyingPurgeRequestMessageCode -> EncodeUnderlyingPurgeRequestMessage(message.body)
      [] message.tag = MarketReentryRequestMessageCode -> EncodeMarketReentryRequestMessage(message.body)
      [] message.tag = ActiveQpSelfReplenishmentRequestReentryMessageCode -> EncodeActiveQpSelfReplenishmentRequestReentryMessage(message.body)
      [] message.tag = SimpleMsarRequestMessageCode -> EncodeSimpleMsarRequestMessage(message.body)
      [] message.tag = ComplexMsarRequestMessageCode -> EncodeComplexMsarRequestMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NotificationSubscriptionRequestMessageCode -> DecodeNotificationSubscriptionRequestMessage(bytes)
              [] tag = AddComplexInstrumentRequestMessageCode -> DecodeAddComplexInstrumentRequestMessage(bytes)
              [] tag = MmParameterDefinitionRequestMessageCode -> DecodeMmParameterDefinitionRequestMessage(bytes)
              [] tag = ActiveQpSelfReplenishmentSetLimitMessageCode -> DecodeActiveQpSelfReplenishmentSetLimitMessage(bytes)
              [] tag = RapidFireConfigRequestMessageCode -> DecodeRapidFireConfigRequestMessage(bytes)
              [] tag = SimpleQuoteBlockShortFormMessageCode -> DecodeSimpleQuoteBlockShortFormMessage(bytes)
              [] tag = SimpleQuoteBlockShortFormDetailedMessageCode -> DecodeSimpleQuoteBlockShortFormDetailedMessage(bytes)
              [] tag = SimpleQuoteBlockLongFormMessageCode -> DecodeSimpleQuoteBlockLongFormMessage(bytes)
              [] tag = SimpleQuoteBlockLongFormDetailedMessageCode -> DecodeSimpleQuoteBlockLongFormDetailedMessage(bytes)
              [] tag = ComplexQuoteBlockMessageCode -> DecodeComplexQuoteBlockMessage(bytes)
              [] tag = ComplexQuoteBlockDetailedMessageCode -> DecodeComplexQuoteBlockDetailedMessage(bytes)
              [] tag = UnderlyingPurgeRequestMessageCode -> DecodeUnderlyingPurgeRequestMessage(bytes)
              [] tag = MarketReentryRequestMessageCode -> DecodeMarketReentryRequestMessage(bytes)
              [] tag = ActiveQpSelfReplenishmentRequestReentryMessageCode -> DecodeActiveQpSelfReplenishmentRequestReentryMessage(bytes)
              [] tag = SimpleMsarRequestMessageCode -> DecodeSimpleMsarRequestMessage(bytes)
              [] tag = ComplexMsarRequestMessageCode -> DecodeComplexMsarRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> NotificationSubscriptionRequestMessageCode, body |-> ZeroNotificationSubscriptionRequestMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> NotificationSubscriptionRequestMessageCode, body |-> one] : one \in CheckedNotificationSubscriptionRequestMessage }
        \cup { [tag |-> AddComplexInstrumentRequestMessageCode, body |-> one] : one \in CheckedAddComplexInstrumentRequestMessage }
        \cup { [tag |-> MmParameterDefinitionRequestMessageCode, body |-> one] : one \in CheckedMmParameterDefinitionRequestMessage }
        \cup { [tag |-> ActiveQpSelfReplenishmentSetLimitMessageCode, body |-> one] : one \in CheckedActiveQpSelfReplenishmentSetLimitMessage }
        \cup { [tag |-> RapidFireConfigRequestMessageCode, body |-> one] : one \in CheckedRapidFireConfigRequestMessage }
        \cup { [tag |-> SimpleQuoteBlockShortFormMessageCode, body |-> one] : one \in CheckedSimpleQuoteBlockShortFormMessage }
        \cup { [tag |-> SimpleQuoteBlockShortFormDetailedMessageCode, body |-> one] : one \in CheckedSimpleQuoteBlockShortFormDetailedMessage }
        \cup { [tag |-> SimpleQuoteBlockLongFormMessageCode, body |-> one] : one \in CheckedSimpleQuoteBlockLongFormMessage }
        \cup { [tag |-> SimpleQuoteBlockLongFormDetailedMessageCode, body |-> one] : one \in CheckedSimpleQuoteBlockLongFormDetailedMessage }
        \cup { [tag |-> ComplexQuoteBlockMessageCode, body |-> one] : one \in CheckedComplexQuoteBlockMessage }
        \cup { [tag |-> ComplexQuoteBlockDetailedMessageCode, body |-> one] : one \in CheckedComplexQuoteBlockDetailedMessage }
        \cup { [tag |-> UnderlyingPurgeRequestMessageCode, body |-> one] : one \in CheckedUnderlyingPurgeRequestMessage }
        \cup { [tag |-> MarketReentryRequestMessageCode, body |-> one] : one \in CheckedMarketReentryRequestMessage }
        \cup { [tag |-> ActiveQpSelfReplenishmentRequestReentryMessageCode, body |-> one] : one \in CheckedActiveQpSelfReplenishmentRequestReentryMessage }
        \cup { [tag |-> SimpleMsarRequestMessageCode, body |-> one] : one \in CheckedSimpleMsarRequestMessage }
        \cup { [tag |-> ComplexMsarRequestMessageCode, body |-> one] : one \in CheckedComplexMsarRequestMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 2)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 2) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatPacketCode == 82  \* "R"
LogoutRequestPacketCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatPacketCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestPacketCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatPacketCode -> << >>
      [] message.tag = LogoutRequestPacketCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatPacketCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestPacketCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatPacketCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestPacketCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatPacketCode, body |-> [empty |-> 0]]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestPacketCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Notification Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNotificationSubscriptionRequestMessage ==
    \A message \in CheckedNotificationSubscriptionRequestMessage :
        LET read == DecodeNotificationSubscriptionRequestMessage(EncodeNotificationSubscriptionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexLegs ==
    \A message \in CheckedComplexLegs :
        LET read == DecodeComplexLegs(EncodeComplexLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentRequestMessage ==
    \A message \in CheckedAddComplexInstrumentRequestMessage :
        LET read == DecodeAddComplexInstrumentRequestMessage(EncodeAddComplexInstrumentRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Parameter Definition Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmParameterDefinitionRequestMessage ==
    \A message \in CheckedMmParameterDefinitionRequestMessage :
        LET read == DecodeMmParameterDefinitionRequestMessage(EncodeMmParameterDefinitionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Qp Self Replenishment Set Limit Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveQpSelfReplenishmentSetLimitMessage ==
    \A message \in CheckedActiveQpSelfReplenishmentSetLimitMessage :
        LET read == DecodeActiveQpSelfReplenishmentSetLimitMessage(EncodeActiveQpSelfReplenishmentSetLimitMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rapid Fire Config Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRapidFireConfigRequestMessage ==
    \A message \in CheckedRapidFireConfigRequestMessage :
        LET read == DecodeRapidFireConfigRequestMessage(EncodeRapidFireConfigRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quotes decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuotes ==
    \A message \in CheckedSimpleQuotes :
        LET read == DecodeSimpleQuotes(EncodeSimpleQuotes(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Block Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteBlockShortFormMessage ==
    \A message \in CheckedSimpleQuoteBlockShortFormMessage :
        LET read == DecodeSimpleQuoteBlockShortFormMessage(EncodeSimpleQuoteBlockShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quotes decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuotes2 ==
    \A message \in CheckedSimpleQuotes2 :
        LET read == DecodeSimpleQuotes2(EncodeSimpleQuotes2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Block Short Form Detailed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteBlockShortFormDetailedMessage ==
    \A message \in CheckedSimpleQuoteBlockShortFormDetailedMessage :
        LET read == DecodeSimpleQuoteBlockShortFormDetailedMessage(EncodeSimpleQuoteBlockShortFormDetailedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quotes Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuotesLongForm ==
    \A message \in CheckedSimpleQuotesLongForm :
        LET read == DecodeSimpleQuotesLongForm(EncodeSimpleQuotesLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Block Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteBlockLongFormMessage ==
    \A message \in CheckedSimpleQuoteBlockLongFormMessage :
        LET read == DecodeSimpleQuoteBlockLongFormMessage(EncodeSimpleQuoteBlockLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quotes Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuotesLongForm2 ==
    \A message \in CheckedSimpleQuotesLongForm2 :
        LET read == DecodeSimpleQuotesLongForm2(EncodeSimpleQuotesLongForm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Block Long Form Detailed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteBlockLongFormDetailedMessage ==
    \A message \in CheckedSimpleQuoteBlockLongFormDetailedMessage :
        LET read == DecodeSimpleQuoteBlockLongFormDetailedMessage(EncodeSimpleQuoteBlockLongFormDetailedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quotes decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuotes ==
    \A message \in CheckedComplexQuotes :
        LET read == DecodeComplexQuotes(EncodeComplexQuotes(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Block Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteBlockMessage ==
    \A message \in CheckedComplexQuoteBlockMessage :
        LET read == DecodeComplexQuoteBlockMessage(EncodeComplexQuoteBlockMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quotes decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuotes2 ==
    \A message \in CheckedComplexQuotes2 :
        LET read == DecodeComplexQuotes2(EncodeComplexQuotes2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Block Detailed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteBlockDetailedMessage ==
    \A message \in CheckedComplexQuoteBlockDetailedMessage :
        LET read == DecodeComplexQuoteBlockDetailedMessage(EncodeComplexQuoteBlockDetailedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Purge Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingPurgeRequestMessage ==
    \A message \in CheckedUnderlyingPurgeRequestMessage :
        LET read == DecodeUnderlyingPurgeRequestMessage(EncodeUnderlyingPurgeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Reentry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketReentryRequestMessage ==
    \A message \in CheckedMarketReentryRequestMessage :
        LET read == DecodeMarketReentryRequestMessage(EncodeMarketReentryRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Qp Self Replenishment Request Reentry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveQpSelfReplenishmentRequestReentryMessage ==
    \A message \in CheckedActiveQpSelfReplenishmentRequestReentryMessage :
        LET read == DecodeActiveQpSelfReplenishmentRequestReentryMessage(EncodeActiveQpSelfReplenishmentRequestReentryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Msar Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleMsarRequestMessage ==
    \A message \in CheckedSimpleMsarRequestMessage :
        LET read == DecodeSimpleMsarRequestMessage(EncodeSimpleMsarRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Msar Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexMsarRequestMessage ==
    \A message \in CheckedComplexMsarRequestMessage :
        LET read == DecodeComplexMsarRequestMessage(EncodeComplexMsarRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
