------------------ MODULE GemxOptions_Quoting_v9_0_Server ------------------
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Server Unsequenced Data Packet fills what is left of the frame    *)
(* Packet Length states, which is what it is read from.                    *)
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
(* Msar Accept Message: 30 bytes                                           *)
(***************************************************************************)

MsarAcceptMessage ==
    [ badge        : Sample(4),
      messageId    : Sample(8),
      instrumentId : Sample(4),
      msarType     : Sample(1),
      auctionId    : Sample(4),
      price        : Sample(4),
      side         : Sample(1),
      contracts    : Sample(4) ]

EncodeMsarAcceptMessage(message) ==
    message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.msarType
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.contracts

DecodeMsarAcceptMessage(bytes) ==
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

ZeroMsarAcceptMessage ==
    [ badge        |-> [i \in 1 .. 4 |-> 0],
      messageId    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      msarType     |-> [i \in 1 .. 1 |-> 0],
      auctionId    |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      contracts    |-> [i \in 1 .. 4 |-> 0] ]

(* Msar Accept Message at zero, then each field in turn at the values it is checked at *)
CheckedMsarAcceptMessage ==
    { ZeroMsarAcceptMessage }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.msarType = one] : one \in Sample(1) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMsarAcceptMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Msar Reject Message: 13 bytes                                           *)
(***************************************************************************)

MsarRejectMessage ==
    [ badge      : Sample(4),
      messageId  : Sample(8),
      statusCode : Sample(1) ]

EncodeMsarRejectMessage(message) ==
    message.badge
        \o message.messageId
        \o message.statusCode

DecodeMsarRejectMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET statusCode == ReadBytes(messageId.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ badge      |-> badge.value,
         messageId  |-> messageId.value,
         statusCode |-> statusCode.value ], statusCode.rest)

ZeroMsarRejectMessage ==
    [ badge      |-> [i \in 1 .. 4 |-> 0],
      messageId  |-> [i \in 1 .. 8 |-> 0],
      statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Msar Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMsarRejectMessage ==
    { ZeroMsarRejectMessage }
        \cup { [ZeroMsarRejectMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMsarRejectMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMsarRejectMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Msar Accept Message: 35 bytes                                   *)
(***************************************************************************)

ComplexMsarAcceptMessage ==
    [ badge           : Sample(4),
      messageId       : Sample(8),
      instrumentId    : Sample(4),
      msarType        : Sample(1),
      auctionId       : Sample(4),
      price           : Sample(4),
      side            : Sample(1),
      contracts       : Sample(4),
      priceProtection : Sample(1),
      reserved4       : Sample(4) ]

EncodeComplexMsarAcceptMessage(message) ==
    message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.msarType
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.contracts
        \o message.priceProtection
        \o message.reserved4

DecodeComplexMsarAcceptMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(messageId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET msarType == ReadBytes(instrumentId.rest, 1) IN IF ~msarType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(msarType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(contracts.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(priceProtection.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ badge           |-> badge.value,
         messageId       |-> messageId.value,
         instrumentId    |-> instrumentId.value,
         msarType        |-> msarType.value,
         auctionId       |-> auctionId.value,
         price           |-> price.value,
         side            |-> side.value,
         contracts       |-> contracts.value,
         priceProtection |-> priceProtection.value,
         reserved4       |-> reserved4.value ], reserved4.rest)

ZeroComplexMsarAcceptMessage ==
    [ badge           |-> [i \in 1 .. 4 |-> 0],
      messageId       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      msarType        |-> [i \in 1 .. 1 |-> 0],
      auctionId       |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      contracts       |-> [i \in 1 .. 4 |-> 0],
      priceProtection |-> [i \in 1 .. 1 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Msar Accept Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexMsarAcceptMessage ==
    { ZeroComplexMsarAcceptMessage }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.msarType = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarAcceptMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Msar Reject Message: 13 bytes                                   *)
(***************************************************************************)

ComplexMsarRejectMessage ==
    [ badge      : Sample(4),
      messageId  : Sample(8),
      statusCode : Sample(1) ]

EncodeComplexMsarRejectMessage(message) ==
    message.badge
        \o message.messageId
        \o message.statusCode

DecodeComplexMsarRejectMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET statusCode == ReadBytes(messageId.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ badge      |-> badge.value,
         messageId  |-> messageId.value,
         statusCode |-> statusCode.value ], statusCode.rest)

ZeroComplexMsarRejectMessage ==
    [ badge      |-> [i \in 1 .. 4 |-> 0],
      messageId  |-> [i \in 1 .. 8 |-> 0],
      statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Msar Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexMsarRejectMessage ==
    { ZeroComplexMsarRejectMessage }
        \cup { [ZeroComplexMsarRejectMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarRejectMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexMsarRejectMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Permission Notification Message: 26 bytes                    *)
(***************************************************************************)

UnderlyingPermissionNotificationMessage ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4),
      badge       : Sample(4),
      underlying  : Sample(13),
      permitted   : Sample(1) ]

EncodeUnderlyingPermissionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.underlying
        \o message.permitted

DecodeUnderlyingPermissionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET underlying == ReadBytes(badge.rest, 13) IN IF ~underlying.ok THEN Fail ELSE
    LET permitted == ReadBytes(underlying.rest, 1) IN IF ~permitted.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value,
         badge       |-> badge.value,
         underlying  |-> underlying.value,
         permitted   |-> permitted.value ], permitted.rest)

ZeroUnderlyingPermissionNotificationMessage ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0],
      badge       |-> [i \in 1 .. 4 |-> 0],
      underlying  |-> [i \in 1 .. 13 |-> 0],
      permitted   |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Permission Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingPermissionNotificationMessage ==
    { ZeroUnderlyingPermissionNotificationMessage }
        \cup { [ZeroUnderlyingPermissionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPermissionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPermissionNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPermissionNotificationMessage EXCEPT !.underlying = one] : one \in Sample(13) }
        \cup { [ZeroUnderlyingPermissionNotificationMessage EXCEPT !.permitted = one] : one \in Sample(1) }

(***************************************************************************)
(* Mm Parameter Definition Notification Message: 74 bytes                  *)
(***************************************************************************)

MmParameterDefinitionNotificationMessage ==
    [ seconds        : Sample(4),
      nanoseconds    : Sample(4),
      badge          : Sample(4),
      instrumentType : Sample(1),
      underlying     : Sample(13),
      interval       : Sample(2),
      percentage     : Sample(2),
      cumQty         : Sample(4),
      delta          : Sample(4),
      vega           : Sample(4),
      reserved32     : Sample(32) ]

EncodeMmParameterDefinitionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.instrumentType
        \o message.underlying
        \o message.interval
        \o message.percentage
        \o message.cumQty
        \o message.delta
        \o message.vega
        \o message.reserved32

DecodeMmParameterDefinitionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(badge.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET underlying == ReadBytes(instrumentType.rest, 13) IN IF ~underlying.ok THEN Fail ELSE
    LET interval == ReadBytes(underlying.rest, 2) IN IF ~interval.ok THEN Fail ELSE
    LET percentage == ReadBytes(interval.rest, 2) IN IF ~percentage.ok THEN Fail ELSE
    LET cumQty == ReadBytes(percentage.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET delta == ReadBytes(cumQty.rest, 4) IN IF ~delta.ok THEN Fail ELSE
    LET vega == ReadBytes(delta.rest, 4) IN IF ~vega.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(vega.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ seconds        |-> seconds.value,
         nanoseconds    |-> nanoseconds.value,
         badge          |-> badge.value,
         instrumentType |-> instrumentType.value,
         underlying     |-> underlying.value,
         interval       |-> interval.value,
         percentage     |-> percentage.value,
         cumQty         |-> cumQty.value,
         delta          |-> delta.value,
         vega           |-> vega.value,
         reserved32     |-> reserved32.value ], reserved32.rest)

ZeroMmParameterDefinitionNotificationMessage ==
    [ seconds        |-> [i \in 1 .. 4 |-> 0],
      nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      badge          |-> [i \in 1 .. 4 |-> 0],
      instrumentType |-> [i \in 1 .. 1 |-> 0],
      underlying     |-> [i \in 1 .. 13 |-> 0],
      interval       |-> [i \in 1 .. 2 |-> 0],
      percentage     |-> [i \in 1 .. 2 |-> 0],
      cumQty         |-> [i \in 1 .. 4 |-> 0],
      delta          |-> [i \in 1 .. 4 |-> 0],
      vega           |-> [i \in 1 .. 4 |-> 0],
      reserved32     |-> [i \in 1 .. 32 |-> 0] ]

(* Mm Parameter Definition Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedMmParameterDefinitionNotificationMessage ==
    { ZeroMmParameterDefinitionNotificationMessage }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.underlying = one] : one \in Sample(13) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.interval = one] : one \in Sample(2) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.percentage = one] : one \in Sample(2) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.delta = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.vega = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionNotificationMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Active Qp Self Replenishment Parameter Definition Notification Message: *)
(* 61 bytes                                                                *)
(***************************************************************************)

ActiveQpSelfReplenishmentParameterDefinitionNotificationMessage ==
    [ seconds          : Sample(4),
      nanoseconds      : Sample(4),
      badge            : Sample(4),
      underlying       : Sample(13),
      setContractLimit : Sample(4),
      reserved32       : Sample(32) ]

EncodeActiveQpSelfReplenishmentParameterDefinitionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.underlying
        \o message.setContractLimit
        \o message.reserved32

DecodeActiveQpSelfReplenishmentParameterDefinitionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET underlying == ReadBytes(badge.rest, 13) IN IF ~underlying.ok THEN Fail ELSE
    LET setContractLimit == ReadBytes(underlying.rest, 4) IN IF ~setContractLimit.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(setContractLimit.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ seconds          |-> seconds.value,
         nanoseconds      |-> nanoseconds.value,
         badge            |-> badge.value,
         underlying       |-> underlying.value,
         setContractLimit |-> setContractLimit.value,
         reserved32       |-> reserved32.value ], reserved32.rest)

ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage ==
    [ seconds          |-> [i \in 1 .. 4 |-> 0],
      nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      badge            |-> [i \in 1 .. 4 |-> 0],
      underlying       |-> [i \in 1 .. 13 |-> 0],
      setContractLimit |-> [i \in 1 .. 4 |-> 0],
      reserved32       |-> [i \in 1 .. 32 |-> 0] ]

(* Active Qp Self Replenishment Parameter Definition Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveQpSelfReplenishmentParameterDefinitionNotificationMessage ==
    { ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage }
        \cup { [ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage EXCEPT !.underlying = one] : one \in Sample(13) }
        \cup { [ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage EXCEPT !.setContractLimit = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentParameterDefinitionNotificationMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4),
      eventCode   : Sample(1),
      version     : Sample(1),
      subversion  : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.eventCode
        \o message.version
        \o message.subversion

DecodeSystemEventMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET version == ReadBytes(eventCode.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET subversion == ReadBytes(version.rest, 1) IN IF ~subversion.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value,
         version     |-> version.value,
         subversion  |-> subversion.value ], subversion.rest)

ZeroSystemEventMessage ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      version     |-> [i \in 1 .. 1 |-> 0],
      subversion  |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.subversion = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Instrument Directory Message: 59 bytes                           *)
(***************************************************************************)

SimpleInstrumentDirectoryMessage ==
    [ seconds          : Sample(4),
      nanoseconds      : Sample(4),
      instrumentId     : Sample(4),
      securitySymbol   : Sample(8),
      expiration       : Sample(2),
      strikePrice      : Sample(4),
      optionType       : Sample(1),
      underlyingSymbol : Sample(13),
      closingType      : Sample(1),
      tradable         : Sample(1),
      mpv              : Sample(1),
      reserved16       : Sample(16) ]

EncodeSimpleInstrumentDirectoryMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.instrumentId
        \o message.securitySymbol
        \o message.expiration
        \o message.strikePrice
        \o message.optionType
        \o message.underlyingSymbol
        \o message.closingType
        \o message.tradable
        \o message.mpv
        \o message.reserved16

DecodeSimpleInstrumentDirectoryMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanoseconds.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(instrumentId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiration.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET closingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~closingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(closingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(mpv.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ seconds          |-> seconds.value,
         nanoseconds      |-> nanoseconds.value,
         instrumentId     |-> instrumentId.value,
         securitySymbol   |-> securitySymbol.value,
         expiration       |-> expiration.value,
         strikePrice      |-> strikePrice.value,
         optionType       |-> optionType.value,
         underlyingSymbol |-> underlyingSymbol.value,
         closingType      |-> closingType.value,
         tradable         |-> tradable.value,
         mpv              |-> mpv.value,
         reserved16       |-> reserved16.value ], reserved16.rest)

ZeroSimpleInstrumentDirectoryMessage ==
    [ seconds          |-> [i \in 1 .. 4 |-> 0],
      nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      securitySymbol   |-> [i \in 1 .. 8 |-> 0],
      expiration       |-> [i \in 1 .. 2 |-> 0],
      strikePrice      |-> [i \in 1 .. 4 |-> 0],
      optionType       |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      closingType      |-> [i \in 1 .. 1 |-> 0],
      tradable         |-> [i \in 1 .. 1 |-> 0],
      mpv              |-> [i \in 1 .. 1 |-> 0],
      reserved16       |-> [i \in 1 .. 16 |-> 0] ]

(* Simple Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleInstrumentDirectoryMessage ==
    { ZeroSimpleInstrumentDirectoryMessage }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.closingType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

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
(* Complex Instrument Directory Message                                    *)
(***************************************************************************)

ComplexInstrumentDirectoryMessage ==
    [ seconds          : Sample(4),
      nanoseconds      : Sample(4),
      instrumentId     : Sample(4),
      underlyingSymbol : Sample(13),
      reserved1        : Sample(1),
      complexLegs      : SampleLists(OneComplexLegs) ]

EncodeComplexInstrumentDirectoryMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.instrumentId
        \o message.underlyingSymbol
        \o message.reserved1
        \o EncodeUIntBE(Len(message.complexLegs), 1)
        \o EncodeComplexLegsList(message.complexLegs)

DecodeComplexInstrumentDirectoryMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanoseconds.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(instrumentId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(underlyingSymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET complexLegs == ReadComplexLegsList(numberOfLegs.rest, numberOfLegs.value) IN IF ~complexLegs.ok THEN Fail ELSE
    Ok([ seconds          |-> seconds.value,
         nanoseconds      |-> nanoseconds.value,
         instrumentId     |-> instrumentId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reserved1        |-> reserved1.value,
         complexLegs      |-> complexLegs.value ], complexLegs.rest)

ZeroComplexInstrumentDirectoryMessage ==
    [ seconds          |-> [i \in 1 .. 4 |-> 0],
      nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      complexLegs      |-> << >> ]

(* Complex Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDirectoryMessage ==
    { ZeroComplexInstrumentDirectoryMessage }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.complexLegs = one] : one \in SampleLists(OneComplexLegs) }

(***************************************************************************)
(* Simple Instrument Trading Action Message: 13 bytes                      *)
(***************************************************************************)

SimpleInstrumentTradingActionMessage ==
    [ seconds      : Sample(4),
      nanoseconds  : Sample(4),
      instrumentId : Sample(4),
      tradingState : Sample(1) ]

EncodeSimpleInstrumentTradingActionMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.instrumentId
        \o message.tradingState

DecodeSimpleInstrumentTradingActionMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanoseconds.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingState == ReadBytes(instrumentId.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    Ok([ seconds      |-> seconds.value,
         nanoseconds  |-> nanoseconds.value,
         instrumentId |-> instrumentId.value,
         tradingState |-> tradingState.value ], tradingState.rest)

ZeroSimpleInstrumentTradingActionMessage ==
    [ seconds      |-> [i \in 1 .. 4 |-> 0],
      nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Instrument Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleInstrumentTradingActionMessage ==
    { ZeroSimpleInstrumentTradingActionMessage }
        \cup { [ZeroSimpleInstrumentTradingActionMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentTradingActionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Instrument Trading Action Message: 13 bytes                     *)
(***************************************************************************)

ComplexInstrumentTradingActionMessage ==
    [ seconds      : Sample(4),
      nanoseconds  : Sample(4),
      instrumentId : Sample(4),
      tradingState : Sample(1) ]

EncodeComplexInstrumentTradingActionMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.instrumentId
        \o message.tradingState

DecodeComplexInstrumentTradingActionMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanoseconds.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingState == ReadBytes(instrumentId.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    Ok([ seconds      |-> seconds.value,
         nanoseconds  |-> nanoseconds.value,
         instrumentId |-> instrumentId.value,
         tradingState |-> tradingState.value ], tradingState.rest)

ZeroComplexInstrumentTradingActionMessage ==
    [ seconds      |-> [i \in 1 .. 4 |-> 0],
      nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Instrument Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentTradingActionMessage ==
    { ZeroComplexInstrumentTradingActionMessage }
        \cup { [ZeroComplexInstrumentTradingActionMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentTradingActionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Quote Execution Notification Message: 46 bytes                   *)
(***************************************************************************)

SimpleQuoteExecutionNotificationMessage ==
    [ seconds            : Sample(4),
      nanoseconds        : Sample(4),
      badge              : Sample(4),
      instrumentId       : Sample(4),
      messageId          : Sample(8),
      auctionId          : Sample(4),
      price              : Sample(4),
      side               : Sample(1),
      contracts          : Sample(4),
      liquidityIndicator : Sample(1),
      crossId            : Sample(4),
      matchId            : Sample(4) ]

EncodeSimpleQuoteExecutionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.instrumentId
        \o message.messageId
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.contracts
        \o message.liquidityIndicator
        \o message.crossId
        \o message.matchId

DecodeSimpleQuoteExecutionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(badge.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET messageId == ReadBytes(instrumentId.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(messageId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(contracts.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET crossId == ReadBytes(liquidityIndicator.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ seconds            |-> seconds.value,
         nanoseconds        |-> nanoseconds.value,
         badge              |-> badge.value,
         instrumentId       |-> instrumentId.value,
         messageId          |-> messageId.value,
         auctionId          |-> auctionId.value,
         price              |-> price.value,
         side               |-> side.value,
         contracts          |-> contracts.value,
         liquidityIndicator |-> liquidityIndicator.value,
         crossId            |-> crossId.value,
         matchId            |-> matchId.value ], matchId.rest)

ZeroSimpleQuoteExecutionNotificationMessage ==
    [ seconds            |-> [i \in 1 .. 4 |-> 0],
      nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      badge              |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      crossId            |-> [i \in 1 .. 4 |-> 0],
      matchId            |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Quote Execution Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteExecutionNotificationMessage ==
    { ZeroSimpleQuoteExecutionNotificationMessage }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteExecutionNotificationMessage EXCEPT !.matchId = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Quote Execution Notification Message: 50 bytes                  *)
(***************************************************************************)

ComplexQuoteExecutionNotificationMessage ==
    [ seconds            : Sample(4),
      nanoseconds        : Sample(4),
      badge              : Sample(4),
      messageId          : Sample(8),
      instrumentId       : Sample(4),
      auctionId          : Sample(4),
      price6             : Sample(8),
      side               : Sample(1),
      contracts          : Sample(4),
      liquidityIndicator : Sample(1),
      crossId            : Sample(4),
      matchId            : Sample(4) ]

EncodeComplexQuoteExecutionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.auctionId
        \o message.price6
        \o message.side
        \o message.contracts
        \o message.liquidityIndicator
        \o message.crossId
        \o message.matchId

DecodeComplexQuoteExecutionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(messageId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(instrumentId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price6 == ReadBytes(auctionId.rest, 8) IN IF ~price6.ok THEN Fail ELSE
    LET side == ReadBytes(price6.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(contracts.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET crossId == ReadBytes(liquidityIndicator.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ seconds            |-> seconds.value,
         nanoseconds        |-> nanoseconds.value,
         badge              |-> badge.value,
         messageId          |-> messageId.value,
         instrumentId       |-> instrumentId.value,
         auctionId          |-> auctionId.value,
         price6             |-> price6.value,
         side               |-> side.value,
         contracts          |-> contracts.value,
         liquidityIndicator |-> liquidityIndicator.value,
         crossId            |-> crossId.value,
         matchId            |-> matchId.value ], matchId.rest)

ZeroComplexQuoteExecutionNotificationMessage ==
    [ seconds            |-> [i \in 1 .. 4 |-> 0],
      nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      badge              |-> [i \in 1 .. 4 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      price6             |-> [i \in 1 .. 8 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      crossId            |-> [i \in 1 .. 4 |-> 0],
      matchId            |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Quote Execution Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteExecutionNotificationMessage ==
    { ZeroComplexQuoteExecutionNotificationMessage }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.price6 = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteExecutionNotificationMessage EXCEPT !.matchId = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Quote Leg Execution Notification Message: 55 bytes              *)
(***************************************************************************)

ComplexQuoteLegExecutionNotificationMessage ==
    [ seconds            : Sample(4),
      nanoseconds        : Sample(4),
      badge              : Sample(4),
      messageId          : Sample(8),
      instrumentId       : Sample(4),
      legInstrumentId    : Sample(4),
      legId              : Sample(1),
      auctionId          : Sample(4),
      price6             : Sample(8),
      side               : Sample(1),
      contracts          : Sample(4),
      liquidityIndicator : Sample(1),
      crossId            : Sample(4),
      matchId            : Sample(4) ]

EncodeComplexQuoteLegExecutionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.legInstrumentId
        \o message.legId
        \o message.auctionId
        \o message.price6
        \o message.side
        \o message.contracts
        \o message.liquidityIndicator
        \o message.crossId
        \o message.matchId

DecodeComplexQuoteLegExecutionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(messageId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(instrumentId.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legId == ReadBytes(legInstrumentId.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(legId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price6 == ReadBytes(auctionId.rest, 8) IN IF ~price6.ok THEN Fail ELSE
    LET side == ReadBytes(price6.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(contracts.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET crossId == ReadBytes(liquidityIndicator.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ seconds            |-> seconds.value,
         nanoseconds        |-> nanoseconds.value,
         badge              |-> badge.value,
         messageId          |-> messageId.value,
         instrumentId       |-> instrumentId.value,
         legInstrumentId    |-> legInstrumentId.value,
         legId              |-> legId.value,
         auctionId          |-> auctionId.value,
         price6             |-> price6.value,
         side               |-> side.value,
         contracts          |-> contracts.value,
         liquidityIndicator |-> liquidityIndicator.value,
         crossId            |-> crossId.value,
         matchId            |-> matchId.value ], matchId.rest)

ZeroComplexQuoteLegExecutionNotificationMessage ==
    [ seconds            |-> [i \in 1 .. 4 |-> 0],
      nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      badge              |-> [i \in 1 .. 4 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      legInstrumentId    |-> [i \in 1 .. 4 |-> 0],
      legId              |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      price6             |-> [i \in 1 .. 8 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      crossId            |-> [i \in 1 .. 4 |-> 0],
      matchId            |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Quote Leg Execution Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteLegExecutionNotificationMessage ==
    { ZeroComplexQuoteLegExecutionNotificationMessage }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.legId = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.price6 = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteLegExecutionNotificationMessage EXCEPT !.matchId = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Msar Notification Message: 47 bytes                              *)
(***************************************************************************)

SimpleMsarNotificationMessage ==
    [ seconds            : Sample(4),
      nanoseconds        : Sample(4),
      badge              : Sample(4),
      instrumentId       : Sample(4),
      notificationType   : Sample(1),
      messageId          : Sample(8),
      auctionId          : Sample(4),
      price              : Sample(4),
      side               : Sample(1),
      contracts          : Sample(4),
      liquidityIndicator : Sample(1),
      crossId            : Sample(4),
      matchId            : Sample(4) ]

EncodeSimpleMsarNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.instrumentId
        \o message.notificationType
        \o message.messageId
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.contracts
        \o message.liquidityIndicator
        \o message.crossId
        \o message.matchId

DecodeSimpleMsarNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(badge.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET notificationType == ReadBytes(instrumentId.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET messageId == ReadBytes(notificationType.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(messageId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(contracts.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET crossId == ReadBytes(liquidityIndicator.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ seconds            |-> seconds.value,
         nanoseconds        |-> nanoseconds.value,
         badge              |-> badge.value,
         instrumentId       |-> instrumentId.value,
         notificationType   |-> notificationType.value,
         messageId          |-> messageId.value,
         auctionId          |-> auctionId.value,
         price              |-> price.value,
         side               |-> side.value,
         contracts          |-> contracts.value,
         liquidityIndicator |-> liquidityIndicator.value,
         crossId            |-> crossId.value,
         matchId            |-> matchId.value ], matchId.rest)

ZeroSimpleMsarNotificationMessage ==
    [ seconds            |-> [i \in 1 .. 4 |-> 0],
      nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      badge              |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      notificationType   |-> [i \in 1 .. 1 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      crossId            |-> [i \in 1 .. 4 |-> 0],
      matchId            |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Msar Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleMsarNotificationMessage ==
    { ZeroSimpleMsarNotificationMessage }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMsarNotificationMessage EXCEPT !.matchId = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Msar Leg Notification Message: 61 bytes                         *)
(***************************************************************************)

ComplexMsarLegNotificationMessage ==
    [ seconds            : Sample(4),
      nanoseconds        : Sample(4),
      badge              : Sample(4),
      instrumentId       : Sample(4),
      legId              : Sample(1),
      legInstrumentId    : Sample(4),
      notificationType   : Sample(1),
      messageId          : Sample(8),
      auctionId          : Sample(4),
      price              : Sample(4),
      side               : Sample(1),
      legSide            : Sample(1),
      contracts          : Sample(4),
      liquidityIndicator : Sample(1),
      crossId            : Sample(4),
      matchId            : Sample(4),
      price6             : Sample(8) ]

EncodeComplexMsarLegNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.instrumentId
        \o message.legId
        \o message.legInstrumentId
        \o message.notificationType
        \o message.messageId
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.legSide
        \o message.contracts
        \o message.liquidityIndicator
        \o message.crossId
        \o message.matchId
        \o message.price6

DecodeComplexMsarLegNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(badge.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legId == ReadBytes(instrumentId.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legId.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET notificationType == ReadBytes(legInstrumentId.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET messageId == ReadBytes(notificationType.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(messageId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legSide == ReadBytes(side.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET contracts == ReadBytes(legSide.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(contracts.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET crossId == ReadBytes(liquidityIndicator.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET price6 == ReadBytes(matchId.rest, 8) IN IF ~price6.ok THEN Fail ELSE
    Ok([ seconds            |-> seconds.value,
         nanoseconds        |-> nanoseconds.value,
         badge              |-> badge.value,
         instrumentId       |-> instrumentId.value,
         legId              |-> legId.value,
         legInstrumentId    |-> legInstrumentId.value,
         notificationType   |-> notificationType.value,
         messageId          |-> messageId.value,
         auctionId          |-> auctionId.value,
         price              |-> price.value,
         side               |-> side.value,
         legSide            |-> legSide.value,
         contracts          |-> contracts.value,
         liquidityIndicator |-> liquidityIndicator.value,
         crossId            |-> crossId.value,
         matchId            |-> matchId.value,
         price6             |-> price6.value ], price6.rest)

ZeroComplexMsarLegNotificationMessage ==
    [ seconds            |-> [i \in 1 .. 4 |-> 0],
      nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      badge              |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      legId              |-> [i \in 1 .. 1 |-> 0],
      legInstrumentId    |-> [i \in 1 .. 4 |-> 0],
      notificationType   |-> [i \in 1 .. 1 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      legSide            |-> [i \in 1 .. 1 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      crossId            |-> [i \in 1 .. 4 |-> 0],
      matchId            |-> [i \in 1 .. 4 |-> 0],
      price6             |-> [i \in 1 .. 8 |-> 0] ]

(* Complex Msar Leg Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexMsarLegNotificationMessage ==
    { ZeroComplexMsarLegNotificationMessage }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.legId = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarLegNotificationMessage EXCEPT !.price6 = one] : one \in Sample(8) }

(***************************************************************************)
(* Complex Msar Notification Message: 55 bytes                             *)
(***************************************************************************)

ComplexMsarNotificationMessage ==
    [ seconds            : Sample(4),
      nanoseconds        : Sample(4),
      badge              : Sample(4),
      instrumentId       : Sample(4),
      notificationType   : Sample(1),
      messageId          : Sample(8),
      auctionId          : Sample(4),
      price              : Sample(4),
      side               : Sample(1),
      contracts          : Sample(4),
      liquidityIndicator : Sample(1),
      crossId            : Sample(4),
      matchId            : Sample(4),
      price6             : Sample(8) ]

EncodeComplexMsarNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.instrumentId
        \o message.notificationType
        \o message.messageId
        \o message.auctionId
        \o message.price
        \o message.side
        \o message.contracts
        \o message.liquidityIndicator
        \o message.crossId
        \o message.matchId
        \o message.price6

DecodeComplexMsarNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(badge.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET notificationType == ReadBytes(instrumentId.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET messageId == ReadBytes(notificationType.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(messageId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET contracts == ReadBytes(side.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(contracts.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET crossId == ReadBytes(liquidityIndicator.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET price6 == ReadBytes(matchId.rest, 8) IN IF ~price6.ok THEN Fail ELSE
    Ok([ seconds            |-> seconds.value,
         nanoseconds        |-> nanoseconds.value,
         badge              |-> badge.value,
         instrumentId       |-> instrumentId.value,
         notificationType   |-> notificationType.value,
         messageId          |-> messageId.value,
         auctionId          |-> auctionId.value,
         price              |-> price.value,
         side               |-> side.value,
         contracts          |-> contracts.value,
         liquidityIndicator |-> liquidityIndicator.value,
         crossId            |-> crossId.value,
         matchId            |-> matchId.value,
         price6             |-> price6.value ], price6.rest)

ZeroComplexMsarNotificationMessage ==
    [ seconds            |-> [i \in 1 .. 4 |-> 0],
      nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      badge              |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      notificationType   |-> [i \in 1 .. 1 |-> 0],
      messageId          |-> [i \in 1 .. 8 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      crossId            |-> [i \in 1 .. 4 |-> 0],
      matchId            |-> [i \in 1 .. 4 |-> 0],
      price6             |-> [i \in 1 .. 8 |-> 0] ]

(* Complex Msar Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexMsarNotificationMessage ==
    { ZeroComplexMsarNotificationMessage }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroComplexMsarNotificationMessage EXCEPT !.price6 = one] : one \in Sample(8) }

(***************************************************************************)
(* Opening Rotation Quote Spread Multiplier Notification Message: 22 bytes *)
(***************************************************************************)

OpeningRotationQuoteSpreadMultiplierNotificationMessage ==
    [ seconds          : Sample(4),
      nanoseconds      : Sample(4),
      underlyingSymbol : Sample(13),
      multiplier       : Sample(1) ]

EncodeOpeningRotationQuoteSpreadMultiplierNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.underlyingSymbol
        \o message.multiplier

DecodeOpeningRotationQuoteSpreadMultiplierNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(nanoseconds.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET multiplier == ReadBytes(underlyingSymbol.rest, 1) IN IF ~multiplier.ok THEN Fail ELSE
    Ok([ seconds          |-> seconds.value,
         nanoseconds      |-> nanoseconds.value,
         underlyingSymbol |-> underlyingSymbol.value,
         multiplier       |-> multiplier.value ], multiplier.rest)

ZeroOpeningRotationQuoteSpreadMultiplierNotificationMessage ==
    [ seconds          |-> [i \in 1 .. 4 |-> 0],
      nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      multiplier       |-> [i \in 1 .. 1 |-> 0] ]

(* Opening Rotation Quote Spread Multiplier Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningRotationQuoteSpreadMultiplierNotificationMessage ==
    { ZeroOpeningRotationQuoteSpreadMultiplierNotificationMessage }
        \cup { [ZeroOpeningRotationQuoteSpreadMultiplierNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroOpeningRotationQuoteSpreadMultiplierNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOpeningRotationQuoteSpreadMultiplierNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOpeningRotationQuoteSpreadMultiplierNotificationMessage EXCEPT !.multiplier = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

MsarAcceptMessageCode == 21313  \* "SA"
MsarRejectMessageCode == 21330  \* "SR"
ComplexMsarAcceptMessageCode == 21337  \* "SY"
ComplexMsarRejectMessageCode == 21326  \* "SN"
UnderlyingPermissionNotificationMessageCode == 16720  \* "AP"
MmParameterDefinitionNotificationMessageCode == 16714  \* "AJ"
ActiveQpSelfReplenishmentParameterDefinitionNotificationMessageCode == 16715  \* "AK"
SystemEventMessageCode == 16723  \* "AS"
SimpleInstrumentDirectoryMessageCode == 16708  \* "AD"
ComplexInstrumentDirectoryMessageCode == 16722  \* "AR"
SimpleInstrumentTradingActionMessageCode == 16712  \* "AH"
ComplexInstrumentTradingActionMessageCode == 16713  \* "AI"
SimpleQuoteExecutionNotificationMessageCode == 20037  \* "NE"
ComplexQuoteExecutionNotificationMessageCode == 20054  \* "NV"
ComplexQuoteLegExecutionNotificationMessageCode == 20055  \* "NW"
SimpleMsarNotificationMessageCode == 20051  \* "NS"
ComplexMsarLegNotificationMessageCode == 20044  \* "NL"
ComplexMsarNotificationMessageCode == 20056  \* "NX"
OpeningRotationQuoteSpreadMultiplierNotificationMessageCode == 16717  \* "AM"

SequencedMessage ==
    [ tag : {MsarAcceptMessageCode}, body : MsarAcceptMessage ]
        \cup [ tag : {MsarRejectMessageCode}, body : MsarRejectMessage ]
        \cup [ tag : {ComplexMsarAcceptMessageCode}, body : ComplexMsarAcceptMessage ]
        \cup [ tag : {ComplexMsarRejectMessageCode}, body : ComplexMsarRejectMessage ]
        \cup [ tag : {UnderlyingPermissionNotificationMessageCode}, body : UnderlyingPermissionNotificationMessage ]
        \cup [ tag : {MmParameterDefinitionNotificationMessageCode}, body : MmParameterDefinitionNotificationMessage ]
        \cup [ tag : {ActiveQpSelfReplenishmentParameterDefinitionNotificationMessageCode}, body : ActiveQpSelfReplenishmentParameterDefinitionNotificationMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SimpleInstrumentDirectoryMessageCode}, body : SimpleInstrumentDirectoryMessage ]
        \cup [ tag : {ComplexInstrumentDirectoryMessageCode}, body : ComplexInstrumentDirectoryMessage ]
        \cup [ tag : {SimpleInstrumentTradingActionMessageCode}, body : SimpleInstrumentTradingActionMessage ]
        \cup [ tag : {ComplexInstrumentTradingActionMessageCode}, body : ComplexInstrumentTradingActionMessage ]
        \cup [ tag : {SimpleQuoteExecutionNotificationMessageCode}, body : SimpleQuoteExecutionNotificationMessage ]
        \cup [ tag : {ComplexQuoteExecutionNotificationMessageCode}, body : ComplexQuoteExecutionNotificationMessage ]
        \cup [ tag : {ComplexQuoteLegExecutionNotificationMessageCode}, body : ComplexQuoteLegExecutionNotificationMessage ]
        \cup [ tag : {SimpleMsarNotificationMessageCode}, body : SimpleMsarNotificationMessage ]
        \cup [ tag : {ComplexMsarLegNotificationMessageCode}, body : ComplexMsarLegNotificationMessage ]
        \cup [ tag : {ComplexMsarNotificationMessageCode}, body : ComplexMsarNotificationMessage ]
        \cup [ tag : {OpeningRotationQuoteSpreadMultiplierNotificationMessageCode}, body : OpeningRotationQuoteSpreadMultiplierNotificationMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = MsarAcceptMessageCode -> EncodeMsarAcceptMessage(message.body)
      [] message.tag = MsarRejectMessageCode -> EncodeMsarRejectMessage(message.body)
      [] message.tag = ComplexMsarAcceptMessageCode -> EncodeComplexMsarAcceptMessage(message.body)
      [] message.tag = ComplexMsarRejectMessageCode -> EncodeComplexMsarRejectMessage(message.body)
      [] message.tag = UnderlyingPermissionNotificationMessageCode -> EncodeUnderlyingPermissionNotificationMessage(message.body)
      [] message.tag = MmParameterDefinitionNotificationMessageCode -> EncodeMmParameterDefinitionNotificationMessage(message.body)
      [] message.tag = ActiveQpSelfReplenishmentParameterDefinitionNotificationMessageCode -> EncodeActiveQpSelfReplenishmentParameterDefinitionNotificationMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SimpleInstrumentDirectoryMessageCode -> EncodeSimpleInstrumentDirectoryMessage(message.body)
      [] message.tag = ComplexInstrumentDirectoryMessageCode -> EncodeComplexInstrumentDirectoryMessage(message.body)
      [] message.tag = SimpleInstrumentTradingActionMessageCode -> EncodeSimpleInstrumentTradingActionMessage(message.body)
      [] message.tag = ComplexInstrumentTradingActionMessageCode -> EncodeComplexInstrumentTradingActionMessage(message.body)
      [] message.tag = SimpleQuoteExecutionNotificationMessageCode -> EncodeSimpleQuoteExecutionNotificationMessage(message.body)
      [] message.tag = ComplexQuoteExecutionNotificationMessageCode -> EncodeComplexQuoteExecutionNotificationMessage(message.body)
      [] message.tag = ComplexQuoteLegExecutionNotificationMessageCode -> EncodeComplexQuoteLegExecutionNotificationMessage(message.body)
      [] message.tag = SimpleMsarNotificationMessageCode -> EncodeSimpleMsarNotificationMessage(message.body)
      [] message.tag = ComplexMsarLegNotificationMessageCode -> EncodeComplexMsarLegNotificationMessage(message.body)
      [] message.tag = ComplexMsarNotificationMessageCode -> EncodeComplexMsarNotificationMessage(message.body)
      [] message.tag = OpeningRotationQuoteSpreadMultiplierNotificationMessageCode -> EncodeOpeningRotationQuoteSpreadMultiplierNotificationMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = MsarAcceptMessageCode -> DecodeMsarAcceptMessage(bytes)
              [] tag = MsarRejectMessageCode -> DecodeMsarRejectMessage(bytes)
              [] tag = ComplexMsarAcceptMessageCode -> DecodeComplexMsarAcceptMessage(bytes)
              [] tag = ComplexMsarRejectMessageCode -> DecodeComplexMsarRejectMessage(bytes)
              [] tag = UnderlyingPermissionNotificationMessageCode -> DecodeUnderlyingPermissionNotificationMessage(bytes)
              [] tag = MmParameterDefinitionNotificationMessageCode -> DecodeMmParameterDefinitionNotificationMessage(bytes)
              [] tag = ActiveQpSelfReplenishmentParameterDefinitionNotificationMessageCode -> DecodeActiveQpSelfReplenishmentParameterDefinitionNotificationMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SimpleInstrumentDirectoryMessageCode -> DecodeSimpleInstrumentDirectoryMessage(bytes)
              [] tag = ComplexInstrumentDirectoryMessageCode -> DecodeComplexInstrumentDirectoryMessage(bytes)
              [] tag = SimpleInstrumentTradingActionMessageCode -> DecodeSimpleInstrumentTradingActionMessage(bytes)
              [] tag = ComplexInstrumentTradingActionMessageCode -> DecodeComplexInstrumentTradingActionMessage(bytes)
              [] tag = SimpleQuoteExecutionNotificationMessageCode -> DecodeSimpleQuoteExecutionNotificationMessage(bytes)
              [] tag = ComplexQuoteExecutionNotificationMessageCode -> DecodeComplexQuoteExecutionNotificationMessage(bytes)
              [] tag = ComplexQuoteLegExecutionNotificationMessageCode -> DecodeComplexQuoteLegExecutionNotificationMessage(bytes)
              [] tag = SimpleMsarNotificationMessageCode -> DecodeSimpleMsarNotificationMessage(bytes)
              [] tag = ComplexMsarLegNotificationMessageCode -> DecodeComplexMsarLegNotificationMessage(bytes)
              [] tag = ComplexMsarNotificationMessageCode -> DecodeComplexMsarNotificationMessage(bytes)
              [] tag = OpeningRotationQuoteSpreadMultiplierNotificationMessageCode -> DecodeOpeningRotationQuoteSpreadMultiplierNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> MsarAcceptMessageCode, body |-> ZeroMsarAcceptMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> MsarAcceptMessageCode, body |-> one] : one \in CheckedMsarAcceptMessage }
        \cup { [tag |-> MsarRejectMessageCode, body |-> one] : one \in CheckedMsarRejectMessage }
        \cup { [tag |-> ComplexMsarAcceptMessageCode, body |-> one] : one \in CheckedComplexMsarAcceptMessage }
        \cup { [tag |-> ComplexMsarRejectMessageCode, body |-> one] : one \in CheckedComplexMsarRejectMessage }
        \cup { [tag |-> UnderlyingPermissionNotificationMessageCode, body |-> one] : one \in CheckedUnderlyingPermissionNotificationMessage }
        \cup { [tag |-> MmParameterDefinitionNotificationMessageCode, body |-> one] : one \in CheckedMmParameterDefinitionNotificationMessage }
        \cup { [tag |-> ActiveQpSelfReplenishmentParameterDefinitionNotificationMessageCode, body |-> one] : one \in CheckedActiveQpSelfReplenishmentParameterDefinitionNotificationMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SimpleInstrumentDirectoryMessageCode, body |-> one] : one \in CheckedSimpleInstrumentDirectoryMessage }
        \cup { [tag |-> ComplexInstrumentDirectoryMessageCode, body |-> one] : one \in CheckedComplexInstrumentDirectoryMessage }
        \cup { [tag |-> SimpleInstrumentTradingActionMessageCode, body |-> one] : one \in CheckedSimpleInstrumentTradingActionMessage }
        \cup { [tag |-> ComplexInstrumentTradingActionMessageCode, body |-> one] : one \in CheckedComplexInstrumentTradingActionMessage }
        \cup { [tag |-> SimpleQuoteExecutionNotificationMessageCode, body |-> one] : one \in CheckedSimpleQuoteExecutionNotificationMessage }
        \cup { [tag |-> ComplexQuoteExecutionNotificationMessageCode, body |-> one] : one \in CheckedComplexQuoteExecutionNotificationMessage }
        \cup { [tag |-> ComplexQuoteLegExecutionNotificationMessageCode, body |-> one] : one \in CheckedComplexQuoteLegExecutionNotificationMessage }
        \cup { [tag |-> SimpleMsarNotificationMessageCode, body |-> one] : one \in CheckedSimpleMsarNotificationMessage }
        \cup { [tag |-> ComplexMsarLegNotificationMessageCode, body |-> one] : one \in CheckedComplexMsarLegNotificationMessage }
        \cup { [tag |-> ComplexMsarNotificationMessageCode, body |-> one] : one \in CheckedComplexMsarNotificationMessage }
        \cup { [tag |-> OpeningRotationQuoteSpreadMultiplierNotificationMessageCode, body |-> one] : one \in CheckedOpeningRotationQuoteSpreadMultiplierNotificationMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 2)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 2) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Notification Subscription Reply Message: 13 bytes                       *)
(***************************************************************************)

NotificationSubscriptionReplyMessage ==
    [ badge      : Sample(4),
      messageId  : Sample(8),
      statusCode : Sample(1) ]

EncodeNotificationSubscriptionReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.statusCode

DecodeNotificationSubscriptionReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET statusCode == ReadBytes(messageId.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ badge      |-> badge.value,
         messageId  |-> messageId.value,
         statusCode |-> statusCode.value ], statusCode.rest)

ZeroNotificationSubscriptionReplyMessage ==
    [ badge      |-> [i \in 1 .. 4 |-> 0],
      messageId  |-> [i \in 1 .. 8 |-> 0],
      statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Notification Subscription Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedNotificationSubscriptionReplyMessage ==
    { ZeroNotificationSubscriptionReplyMessage }
        \cup { [ZeroNotificationSubscriptionReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroNotificationSubscriptionReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroNotificationSubscriptionReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Complex Instrument Reply Message: 13 bytes                          *)
(***************************************************************************)

AddComplexInstrumentReplyMessage ==
    [ badge      : Sample(4),
      messageId  : Sample(8),
      statusCode : Sample(1) ]

EncodeAddComplexInstrumentReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.statusCode

DecodeAddComplexInstrumentReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET statusCode == ReadBytes(messageId.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ badge      |-> badge.value,
         messageId  |-> messageId.value,
         statusCode |-> statusCode.value ], statusCode.rest)

ZeroAddComplexInstrumentReplyMessage ==
    [ badge      |-> [i \in 1 .. 4 |-> 0],
      messageId  |-> [i \in 1 .. 8 |-> 0],
      statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Add Complex Instrument Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentReplyMessage ==
    { ZeroAddComplexInstrumentReplyMessage }
        \cup { [ZeroAddComplexInstrumentReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Mm Parameter Definition Reply Message: 13 bytes                         *)
(***************************************************************************)

MmParameterDefinitionReplyMessage ==
    [ badge      : Sample(4),
      messageId  : Sample(8),
      statusCode : Sample(1) ]

EncodeMmParameterDefinitionReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.statusCode

DecodeMmParameterDefinitionReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET statusCode == ReadBytes(messageId.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ badge      |-> badge.value,
         messageId  |-> messageId.value,
         statusCode |-> statusCode.value ], statusCode.rest)

ZeroMmParameterDefinitionReplyMessage ==
    [ badge      |-> [i \in 1 .. 4 |-> 0],
      messageId  |-> [i \in 1 .. 8 |-> 0],
      statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Mm Parameter Definition Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedMmParameterDefinitionReplyMessage ==
    { ZeroMmParameterDefinitionReplyMessage }
        \cup { [ZeroMmParameterDefinitionReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Active Qp Self Replenishment Set Limit Reply Message: 30 bytes          *)
(***************************************************************************)

ActiveQpSelfReplenishmentSetLimitReplyMessage ==
    [ badge            : Sample(4),
      messageId        : Sample(8),
      underlyingSymbol : Sample(13),
      setValue         : Sample(4),
      statusCode       : Sample(1) ]

EncodeActiveQpSelfReplenishmentSetLimitReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.underlyingSymbol
        \o message.setValue
        \o message.statusCode

DecodeActiveQpSelfReplenishmentSetLimitReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(messageId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET setValue == ReadBytes(underlyingSymbol.rest, 4) IN IF ~setValue.ok THEN Fail ELSE
    LET statusCode == ReadBytes(setValue.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ badge            |-> badge.value,
         messageId        |-> messageId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         setValue         |-> setValue.value,
         statusCode       |-> statusCode.value ], statusCode.rest)

ZeroActiveQpSelfReplenishmentSetLimitReplyMessage ==
    [ badge            |-> [i \in 1 .. 4 |-> 0],
      messageId        |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      setValue         |-> [i \in 1 .. 4 |-> 0],
      statusCode       |-> [i \in 1 .. 1 |-> 0] ]

(* Active Qp Self Replenishment Set Limit Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveQpSelfReplenishmentSetLimitReplyMessage ==
    { ZeroActiveQpSelfReplenishmentSetLimitReplyMessage }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitReplyMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitReplyMessage EXCEPT !.setValue = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentSetLimitReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Responses: 9 bytes                                                *)
(***************************************************************************)

QuoteResponses ==
    [ quoteStatusCode : Sample(1),
      sequence        : Sample(8) ]

EncodeQuoteResponses(message) ==
    message.quoteStatusCode
        \o message.sequence

DecodeQuoteResponses(bytes) ==
    LET quoteStatusCode == ReadBytes(bytes, 1) IN IF ~quoteStatusCode.ok THEN Fail ELSE
    LET sequence == ReadBytes(quoteStatusCode.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ quoteStatusCode |-> quoteStatusCode.value,
         sequence        |-> sequence.value ], sequence.rest)

ZeroQuoteResponses ==
    [ quoteStatusCode |-> [i \in 1 .. 1 |-> 0],
      sequence        |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Responses at zero, then each field in turn at the values it is checked at *)
CheckedQuoteResponses ==
    { ZeroQuoteResponses }
        \cup { [ZeroQuoteResponses EXCEPT !.quoteStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponses EXCEPT !.sequence = one] : one \in Sample(8) }

(* A run of Quote Responses, written one after another *)
RECURSIVE EncodeQuoteResponsesList(_)
EncodeQuoteResponsesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteResponses(Head(messages)) \o EncodeQuoteResponsesList(Tail(messages))

(* As many Quote Responses as the field that counts them says *)
RECURSIVE ReadQuoteResponsesList(_, _)
ReadQuoteResponsesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteResponses(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteResponsesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Responses of each kind, for the lists that carry them *)
OneQuoteResponses == { ZeroQuoteResponses }

(***************************************************************************)
(* Quote Block Reply Message                                               *)
(***************************************************************************)

QuoteBlockReplyMessage ==
    [ badge           : Sample(4),
      messageId       : Sample(8),
      sentTimestamp   : Sample(8),
      blockStatusCode : Sample(1),
      quoteCount      : Sample(2),
      quoteResponses  : SampleLists(OneQuoteResponses) ]

EncodeQuoteBlockReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o message.blockStatusCode
        \o message.quoteCount
        \o EncodeUIntBE(Len(message.quoteResponses), 2)
        \o EncodeQuoteResponsesList(message.quoteResponses)

DecodeQuoteBlockReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET blockStatusCode == ReadBytes(sentTimestamp.rest, 1) IN IF ~blockStatusCode.ok THEN Fail ELSE
    LET quoteCount == ReadBytes(blockStatusCode.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET validQuoteCount == ReadUIntBE(quoteCount.rest, 2) IN IF ~validQuoteCount.ok THEN Fail ELSE
    LET quoteResponses == ReadQuoteResponsesList(validQuoteCount.rest, validQuoteCount.value) IN IF ~quoteResponses.ok THEN Fail ELSE
    Ok([ badge           |-> badge.value,
         messageId       |-> messageId.value,
         sentTimestamp   |-> sentTimestamp.value,
         blockStatusCode |-> blockStatusCode.value,
         quoteCount      |-> quoteCount.value,
         quoteResponses  |-> quoteResponses.value ], quoteResponses.rest)

ZeroQuoteBlockReplyMessage ==
    [ badge           |-> [i \in 1 .. 4 |-> 0],
      messageId       |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp   |-> [i \in 1 .. 8 |-> 0],
      blockStatusCode |-> [i \in 1 .. 1 |-> 0],
      quoteCount      |-> [i \in 1 .. 2 |-> 0],
      quoteResponses  |-> << >> ]

(* Quote Block Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteBlockReplyMessage ==
    { ZeroQuoteBlockReplyMessage }
        \cup { [ZeroQuoteBlockReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroQuoteBlockReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteBlockReplyMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteBlockReplyMessage EXCEPT !.blockStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteBlockReplyMessage EXCEPT !.quoteCount = one] : one \in Sample(2) }
        \cup { [ZeroQuoteBlockReplyMessage EXCEPT !.quoteResponses = one] : one \in SampleLists(OneQuoteResponses) }

(***************************************************************************)
(* Detailed Quote Responses: 25 bytes                                      *)
(***************************************************************************)

DetailedQuoteResponses ==
    [ quoteStatusCode : Sample(1),
      sequence        : Sample(8),
      bidSequence     : Sample(8),
      askSequence     : Sample(8) ]

EncodeDetailedQuoteResponses(message) ==
    message.quoteStatusCode
        \o message.sequence
        \o message.bidSequence
        \o message.askSequence

DecodeDetailedQuoteResponses(bytes) ==
    LET quoteStatusCode == ReadBytes(bytes, 1) IN IF ~quoteStatusCode.ok THEN Fail ELSE
    LET sequence == ReadBytes(quoteStatusCode.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET bidSequence == ReadBytes(sequence.rest, 8) IN IF ~bidSequence.ok THEN Fail ELSE
    LET askSequence == ReadBytes(bidSequence.rest, 8) IN IF ~askSequence.ok THEN Fail ELSE
    Ok([ quoteStatusCode |-> quoteStatusCode.value,
         sequence        |-> sequence.value,
         bidSequence     |-> bidSequence.value,
         askSequence     |-> askSequence.value ], askSequence.rest)

ZeroDetailedQuoteResponses ==
    [ quoteStatusCode |-> [i \in 1 .. 1 |-> 0],
      sequence        |-> [i \in 1 .. 8 |-> 0],
      bidSequence     |-> [i \in 1 .. 8 |-> 0],
      askSequence     |-> [i \in 1 .. 8 |-> 0] ]

(* Detailed Quote Responses at zero, then each field in turn at the values it is checked at *)
CheckedDetailedQuoteResponses ==
    { ZeroDetailedQuoteResponses }
        \cup { [ZeroDetailedQuoteResponses EXCEPT !.quoteStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroDetailedQuoteResponses EXCEPT !.sequence = one] : one \in Sample(8) }
        \cup { [ZeroDetailedQuoteResponses EXCEPT !.bidSequence = one] : one \in Sample(8) }
        \cup { [ZeroDetailedQuoteResponses EXCEPT !.askSequence = one] : one \in Sample(8) }

(* A run of Detailed Quote Responses, written one after another *)
RECURSIVE EncodeDetailedQuoteResponsesList(_)
EncodeDetailedQuoteResponsesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDetailedQuoteResponses(Head(messages)) \o EncodeDetailedQuoteResponsesList(Tail(messages))

(* As many Detailed Quote Responses as the field that counts them says *)
RECURSIVE ReadDetailedQuoteResponsesList(_, _)
ReadDetailedQuoteResponsesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDetailedQuoteResponses(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDetailedQuoteResponsesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Detailed Quote Responses of each kind, for the lists that carry them *)
OneDetailedQuoteResponses == { ZeroDetailedQuoteResponses }

(***************************************************************************)
(* Detailed Quote Block Reply Message                                      *)
(***************************************************************************)

DetailedQuoteBlockReplyMessage ==
    [ badge                  : Sample(4),
      messageId              : Sample(8),
      sentTimestamp          : Sample(8),
      blockStatusCode        : Sample(1),
      quoteCount             : Sample(2),
      detailedQuoteResponses : SampleLists(OneDetailedQuoteResponses) ]

EncodeDetailedQuoteBlockReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o message.blockStatusCode
        \o message.quoteCount
        \o EncodeUIntBE(Len(message.detailedQuoteResponses), 2)
        \o EncodeDetailedQuoteResponsesList(message.detailedQuoteResponses)

DecodeDetailedQuoteBlockReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET blockStatusCode == ReadBytes(sentTimestamp.rest, 1) IN IF ~blockStatusCode.ok THEN Fail ELSE
    LET quoteCount == ReadBytes(blockStatusCode.rest, 2) IN IF ~quoteCount.ok THEN Fail ELSE
    LET validQuoteCount == ReadUIntBE(quoteCount.rest, 2) IN IF ~validQuoteCount.ok THEN Fail ELSE
    LET detailedQuoteResponses == ReadDetailedQuoteResponsesList(validQuoteCount.rest, validQuoteCount.value) IN IF ~detailedQuoteResponses.ok THEN Fail ELSE
    Ok([ badge                  |-> badge.value,
         messageId              |-> messageId.value,
         sentTimestamp          |-> sentTimestamp.value,
         blockStatusCode        |-> blockStatusCode.value,
         quoteCount             |-> quoteCount.value,
         detailedQuoteResponses |-> detailedQuoteResponses.value ], detailedQuoteResponses.rest)

ZeroDetailedQuoteBlockReplyMessage ==
    [ badge                  |-> [i \in 1 .. 4 |-> 0],
      messageId              |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp          |-> [i \in 1 .. 8 |-> 0],
      blockStatusCode        |-> [i \in 1 .. 1 |-> 0],
      quoteCount             |-> [i \in 1 .. 2 |-> 0],
      detailedQuoteResponses |-> << >> ]

(* Detailed Quote Block Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedDetailedQuoteBlockReplyMessage ==
    { ZeroDetailedQuoteBlockReplyMessage }
        \cup { [ZeroDetailedQuoteBlockReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroDetailedQuoteBlockReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroDetailedQuoteBlockReplyMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroDetailedQuoteBlockReplyMessage EXCEPT !.blockStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroDetailedQuoteBlockReplyMessage EXCEPT !.quoteCount = one] : one \in Sample(2) }
        \cup { [ZeroDetailedQuoteBlockReplyMessage EXCEPT !.detailedQuoteResponses = one] : one \in SampleLists(OneDetailedQuoteResponses) }

(***************************************************************************)
(* Underlying Purge Reply Message: 29 bytes                                *)
(***************************************************************************)

UnderlyingPurgeReplyMessage ==
    [ badge         : Sample(4),
      messageId     : Sample(8),
      sentTimestamp : Sample(8),
      statusCode    : Sample(1),
      sequence      : Sample(8) ]

EncodeUnderlyingPurgeReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.sentTimestamp
        \o message.statusCode
        \o message.sequence

DecodeUnderlyingPurgeReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sentTimestamp == ReadBytes(messageId.rest, 8) IN IF ~sentTimestamp.ok THEN Fail ELSE
    LET statusCode == ReadBytes(sentTimestamp.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET sequence == ReadBytes(statusCode.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ badge         |-> badge.value,
         messageId     |-> messageId.value,
         sentTimestamp |-> sentTimestamp.value,
         statusCode    |-> statusCode.value,
         sequence      |-> sequence.value ], sequence.rest)

ZeroUnderlyingPurgeReplyMessage ==
    [ badge         |-> [i \in 1 .. 4 |-> 0],
      messageId     |-> [i \in 1 .. 8 |-> 0],
      sentTimestamp |-> [i \in 1 .. 8 |-> 0],
      statusCode    |-> [i \in 1 .. 1 |-> 0],
      sequence      |-> [i \in 1 .. 8 |-> 0] ]

(* Underlying Purge Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingPurgeReplyMessage ==
    { ZeroUnderlyingPurgeReplyMessage }
        \cup { [ZeroUnderlyingPurgeReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPurgeReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPurgeReplyMessage EXCEPT !.sentTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPurgeReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingPurgeReplyMessage EXCEPT !.sequence = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Reentry Reply Message: 21 bytes                                  *)
(***************************************************************************)

MarketReentryReplyMessage ==
    [ badge      : Sample(4),
      messageId  : Sample(8),
      statusCode : Sample(1),
      reserved8  : Sample(8) ]

EncodeMarketReentryReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.statusCode
        \o message.reserved8

DecodeMarketReentryReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET statusCode == ReadBytes(messageId.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(statusCode.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ badge      |-> badge.value,
         messageId  |-> messageId.value,
         statusCode |-> statusCode.value,
         reserved8  |-> reserved8.value ], reserved8.rest)

ZeroMarketReentryReplyMessage ==
    [ badge      |-> [i \in 1 .. 4 |-> 0],
      messageId  |-> [i \in 1 .. 8 |-> 0],
      statusCode |-> [i \in 1 .. 1 |-> 0],
      reserved8  |-> [i \in 1 .. 8 |-> 0] ]

(* Market Reentry Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketReentryReplyMessage ==
    { ZeroMarketReentryReplyMessage }
        \cup { [ZeroMarketReentryReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMarketReentryReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMarketReentryReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketReentryReplyMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Active Qp Self Replenishment Request Reentry Reply Message: 38 bytes    *)
(***************************************************************************)

ActiveQpSelfReplenishmentRequestReentryReplyMessage ==
    [ badge                       : Sample(4),
      messageId                   : Sample(8),
      underlyingSymbol            : Sample(13),
      statusCode                  : Sample(1),
      requestedReplenishmentValue : Sample(4),
      activeCounterValue          : Sample(4),
      setContractLimit            : Sample(4) ]

EncodeActiveQpSelfReplenishmentRequestReentryReplyMessage(message) ==
    message.badge
        \o message.messageId
        \o message.underlyingSymbol
        \o message.statusCode
        \o message.requestedReplenishmentValue
        \o message.activeCounterValue
        \o message.setContractLimit

DecodeActiveQpSelfReplenishmentRequestReentryReplyMessage(bytes) ==
    LET badge == ReadBytes(bytes, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(messageId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET statusCode == ReadBytes(underlyingSymbol.rest, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET requestedReplenishmentValue == ReadBytes(statusCode.rest, 4) IN IF ~requestedReplenishmentValue.ok THEN Fail ELSE
    LET activeCounterValue == ReadBytes(requestedReplenishmentValue.rest, 4) IN IF ~activeCounterValue.ok THEN Fail ELSE
    LET setContractLimit == ReadBytes(activeCounterValue.rest, 4) IN IF ~setContractLimit.ok THEN Fail ELSE
    Ok([ badge                       |-> badge.value,
         messageId                   |-> messageId.value,
         underlyingSymbol            |-> underlyingSymbol.value,
         statusCode                  |-> statusCode.value,
         requestedReplenishmentValue |-> requestedReplenishmentValue.value,
         activeCounterValue          |-> activeCounterValue.value,
         setContractLimit            |-> setContractLimit.value ], setContractLimit.rest)

ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage ==
    [ badge                       |-> [i \in 1 .. 4 |-> 0],
      messageId                   |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol            |-> [i \in 1 .. 13 |-> 0],
      statusCode                  |-> [i \in 1 .. 1 |-> 0],
      requestedReplenishmentValue |-> [i \in 1 .. 4 |-> 0],
      activeCounterValue          |-> [i \in 1 .. 4 |-> 0],
      setContractLimit            |-> [i \in 1 .. 4 |-> 0] ]

(* Active Qp Self Replenishment Request Reentry Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveQpSelfReplenishmentRequestReentryReplyMessage ==
    { ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.requestedReplenishmentValue = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.activeCounterValue = one] : one \in Sample(4) }
        \cup { [ZeroActiveQpSelfReplenishmentRequestReentryReplyMessage EXCEPT !.setContractLimit = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Dac Legs: 8 bytes                                                  *)
(***************************************************************************)

FlexDacLegs ==
    [ reserved8 : Sample(8) ]

EncodeFlexDacLegs(message) ==
    message.reserved8

DecodeFlexDacLegs(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexDacLegs ==
    [ reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Dac Legs at zero, then each field in turn at the values it is checked at *)
CheckedFlexDacLegs ==
    { ZeroFlexDacLegs }
        \cup { [ZeroFlexDacLegs EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Dac Legs, written one after another *)
RECURSIVE EncodeFlexDacLegsList(_)
EncodeFlexDacLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexDacLegs(Head(messages)) \o EncodeFlexDacLegsList(Tail(messages))

(* As many Flex Dac Legs as the field that counts them says *)
RECURSIVE ReadFlexDacLegsList(_, _)
ReadFlexDacLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexDacLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexDacLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Dac Legs of each kind, for the lists that carry them *)
OneFlexDacLegs == { ZeroFlexDacLegs }

(***************************************************************************)
(* Auction Notification Message                                            *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ seconds           : Sample(4),
      nanoseconds       : Sample(4),
      instrumentType    : Sample(1),
      instrumentId      : Sample(4),
      auctionId         : Sample(4),
      orderType         : Sample(1),
      side              : Sample(1),
      price             : Sample(4),
      matchedVolume     : Sample(4),
      volume            : Sample(4),
      execFlag          : Sample(1),
      orderCapacity     : Sample(1),
      firmId            : Sample(4),
      occAccount        : Sample(4),
      cmta              : Sample(4),
      auctionEvent      : Sample(1),
      auctionType       : Sample(1),
      auctionDuration   : Sample(4),
      bestResponsePrice : Sample(4),
      bestResponseSize  : Sample(4),
      reserved9         : Sample(9),
      flexDacLegs       : SampleLists(OneFlexDacLegs) ]

EncodeAuctionNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.instrumentType
        \o message.instrumentId
        \o message.auctionId
        \o message.orderType
        \o message.side
        \o message.price
        \o message.matchedVolume
        \o message.volume
        \o message.execFlag
        \o message.orderCapacity
        \o message.firmId
        \o message.occAccount
        \o message.cmta
        \o message.auctionEvent
        \o message.auctionType
        \o message.auctionDuration
        \o message.bestResponsePrice
        \o message.bestResponseSize
        \o message.reserved9
        \o EncodeUIntBE(Len(message.flexDacLegs), 1)
        \o EncodeFlexDacLegsList(message.flexDacLegs)

DecodeAuctionNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(nanoseconds.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentType.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(instrumentId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET orderType == ReadBytes(auctionId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET matchedVolume == ReadBytes(price.rest, 4) IN IF ~matchedVolume.ok THEN Fail ELSE
    LET volume == ReadBytes(matchedVolume.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET execFlag == ReadBytes(volume.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET firmId == ReadBytes(orderCapacity.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET occAccount == ReadBytes(firmId.rest, 4) IN IF ~occAccount.ok THEN Fail ELSE
    LET cmta == ReadBytes(occAccount.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(cmta.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionEvent.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionType.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET bestResponsePrice == ReadBytes(auctionDuration.rest, 4) IN IF ~bestResponsePrice.ok THEN Fail ELSE
    LET bestResponseSize == ReadBytes(bestResponsePrice.rest, 4) IN IF ~bestResponseSize.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(bestResponseSize.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET numberOfFlexDacLegs == ReadUIntBE(reserved9.rest, 1) IN IF ~numberOfFlexDacLegs.ok THEN Fail ELSE
    LET flexDacLegs == ReadFlexDacLegsList(numberOfFlexDacLegs.rest, numberOfFlexDacLegs.value) IN IF ~flexDacLegs.ok THEN Fail ELSE
    Ok([ seconds           |-> seconds.value,
         nanoseconds       |-> nanoseconds.value,
         instrumentType    |-> instrumentType.value,
         instrumentId      |-> instrumentId.value,
         auctionId         |-> auctionId.value,
         orderType         |-> orderType.value,
         side              |-> side.value,
         price             |-> price.value,
         matchedVolume     |-> matchedVolume.value,
         volume            |-> volume.value,
         execFlag          |-> execFlag.value,
         orderCapacity     |-> orderCapacity.value,
         firmId            |-> firmId.value,
         occAccount        |-> occAccount.value,
         cmta              |-> cmta.value,
         auctionEvent      |-> auctionEvent.value,
         auctionType       |-> auctionType.value,
         auctionDuration   |-> auctionDuration.value,
         bestResponsePrice |-> bestResponsePrice.value,
         bestResponseSize  |-> bestResponseSize.value,
         reserved9         |-> reserved9.value,
         flexDacLegs       |-> flexDacLegs.value ], flexDacLegs.rest)

ZeroAuctionNotificationMessage ==
    [ seconds           |-> [i \in 1 .. 4 |-> 0],
      nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      instrumentType    |-> [i \in 1 .. 1 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      auctionId         |-> [i \in 1 .. 4 |-> 0],
      orderType         |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      matchedVolume     |-> [i \in 1 .. 4 |-> 0],
      volume            |-> [i \in 1 .. 4 |-> 0],
      execFlag          |-> [i \in 1 .. 1 |-> 0],
      orderCapacity     |-> [i \in 1 .. 1 |-> 0],
      firmId            |-> [i \in 1 .. 4 |-> 0],
      occAccount        |-> [i \in 1 .. 4 |-> 0],
      cmta              |-> [i \in 1 .. 4 |-> 0],
      auctionEvent      |-> [i \in 1 .. 1 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      auctionDuration   |-> [i \in 1 .. 4 |-> 0],
      bestResponsePrice |-> [i \in 1 .. 4 |-> 0],
      bestResponseSize  |-> [i \in 1 .. 4 |-> 0],
      reserved9         |-> [i \in 1 .. 9 |-> 0],
      flexDacLegs       |-> << >> ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.matchedVolume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.occAccount = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.bestResponsePrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.bestResponseSize = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.flexDacLegs = one] : one \in SampleLists(OneFlexDacLegs) }

(***************************************************************************)
(* Instrument Purge Notification Message: 49 bytes                         *)
(***************************************************************************)

InstrumentPurgeNotificationMessage ==
    [ seconds      : Sample(4),
      nanoseconds  : Sample(4),
      badge        : Sample(4),
      messageId    : Sample(8),
      instrumentId : Sample(4),
      purgeReason  : Sample(1),
      sequence     : Sample(8),
      reserved16   : Sample(16) ]

EncodeInstrumentPurgeNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.messageId
        \o message.instrumentId
        \o message.purgeReason
        \o message.sequence
        \o message.reserved16

DecodeInstrumentPurgeNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET messageId == ReadBytes(badge.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(messageId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET purgeReason == ReadBytes(instrumentId.rest, 1) IN IF ~purgeReason.ok THEN Fail ELSE
    LET sequence == ReadBytes(purgeReason.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(sequence.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ seconds      |-> seconds.value,
         nanoseconds  |-> nanoseconds.value,
         badge        |-> badge.value,
         messageId    |-> messageId.value,
         instrumentId |-> instrumentId.value,
         purgeReason  |-> purgeReason.value,
         sequence     |-> sequence.value,
         reserved16   |-> reserved16.value ], reserved16.rest)

ZeroInstrumentPurgeNotificationMessage ==
    [ seconds      |-> [i \in 1 .. 4 |-> 0],
      nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      badge        |-> [i \in 1 .. 4 |-> 0],
      messageId    |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      purgeReason  |-> [i \in 1 .. 1 |-> 0],
      sequence     |-> [i \in 1 .. 8 |-> 0],
      reserved16   |-> [i \in 1 .. 16 |-> 0] ]

(* Instrument Purge Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentPurgeNotificationMessage ==
    { ZeroInstrumentPurgeNotificationMessage }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.purgeReason = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.sequence = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentPurgeNotificationMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Underlying Purge Notification Message: 42 bytes                         *)
(***************************************************************************)

UnderlyingPurgeNotificationMessage ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4),
      badge       : Sample(4),
      underlying  : Sample(13),
      purgeReason : Sample(1),
      messageId   : Sample(8),
      sequence    : Sample(8) ]

EncodeUnderlyingPurgeNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.underlying
        \o message.purgeReason
        \o message.messageId
        \o message.sequence

DecodeUnderlyingPurgeNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET underlying == ReadBytes(badge.rest, 13) IN IF ~underlying.ok THEN Fail ELSE
    LET purgeReason == ReadBytes(underlying.rest, 1) IN IF ~purgeReason.ok THEN Fail ELSE
    LET messageId == ReadBytes(purgeReason.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET sequence == ReadBytes(messageId.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value,
         badge       |-> badge.value,
         underlying  |-> underlying.value,
         purgeReason |-> purgeReason.value,
         messageId   |-> messageId.value,
         sequence    |-> sequence.value ], sequence.rest)

ZeroUnderlyingPurgeNotificationMessage ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0],
      badge       |-> [i \in 1 .. 4 |-> 0],
      underlying  |-> [i \in 1 .. 13 |-> 0],
      purgeReason |-> [i \in 1 .. 1 |-> 0],
      messageId   |-> [i \in 1 .. 8 |-> 0],
      sequence    |-> [i \in 1 .. 8 |-> 0] ]

(* Underlying Purge Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingPurgeNotificationMessage ==
    { ZeroUnderlyingPurgeNotificationMessage }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.underlying = one] : one \in Sample(13) }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.purgeReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPurgeNotificationMessage EXCEPT !.sequence = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Reentry Notification Message: 42 bytes                           *)
(***************************************************************************)

MarketReentryNotificationMessage ==
    [ seconds          : Sample(4),
      nanoseconds      : Sample(4),
      badge            : Sample(4),
      underlyingSymbol : Sample(13),
      reentryScope     : Sample(1),
      messageId        : Sample(8),
      reserved8        : Sample(8) ]

EncodeMarketReentryNotificationMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.badge
        \o message.underlyingSymbol
        \o message.reentryScope
        \o message.messageId
        \o message.reserved8

DecodeMarketReentryNotificationMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET badge == ReadBytes(nanoseconds.rest, 4) IN IF ~badge.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(badge.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reentryScope == ReadBytes(underlyingSymbol.rest, 1) IN IF ~reentryScope.ok THEN Fail ELSE
    LET messageId == ReadBytes(reentryScope.rest, 8) IN IF ~messageId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(messageId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ seconds          |-> seconds.value,
         nanoseconds      |-> nanoseconds.value,
         badge            |-> badge.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reentryScope     |-> reentryScope.value,
         messageId        |-> messageId.value,
         reserved8        |-> reserved8.value ], reserved8.rest)

ZeroMarketReentryNotificationMessage ==
    [ seconds          |-> [i \in 1 .. 4 |-> 0],
      nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      badge            |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      reentryScope     |-> [i \in 1 .. 1 |-> 0],
      messageId        |-> [i \in 1 .. 8 |-> 0],
      reserved8        |-> [i \in 1 .. 8 |-> 0] ]

(* Market Reentry Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketReentryNotificationMessage ==
    { ZeroMarketReentryNotificationMessage }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.badge = one] : one \in Sample(4) }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.reentryScope = one] : one \in Sample(1) }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.messageId = one] : one \in Sample(8) }
        \cup { [ZeroMarketReentryNotificationMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Server Unsequenced Message, selected by Server Unsequenced Message Type *)
(***************************************************************************)

NotificationSubscriptionReplyMessageCode == 16738  \* "Ab"
AddComplexInstrumentReplyMessageCode == 16739  \* "Ac"
MmParameterDefinitionReplyMessageCode == 16741  \* "Ae"
ActiveQpSelfReplenishmentSetLimitReplyMessageCode == 16743  \* "Ag"
QuoteBlockReplyMessageCode == 20819  \* "QS"
DetailedQuoteBlockReplyMessageCode == 20851  \* "Qs"
UnderlyingPurgeReplyMessageCode == 20594  \* "Pr"
MarketReentryReplyMessageCode == 21074  \* "RR"
ActiveQpSelfReplenishmentRequestReentryReplyMessageCode == 21095  \* "Rg"
AuctionNotificationMessageCode == 20033  \* "NA"
InstrumentPurgeNotificationMessageCode == 20036  \* "ND"
UnderlyingPurgeNotificationMessageCode == 20053  \* "NU"
MarketReentryNotificationMessageCode == 20050  \* "NR"

ServerUnsequencedMessage ==
    [ tag : {NotificationSubscriptionReplyMessageCode}, body : NotificationSubscriptionReplyMessage ]
        \cup [ tag : {AddComplexInstrumentReplyMessageCode}, body : AddComplexInstrumentReplyMessage ]
        \cup [ tag : {MmParameterDefinitionReplyMessageCode}, body : MmParameterDefinitionReplyMessage ]
        \cup [ tag : {ActiveQpSelfReplenishmentSetLimitReplyMessageCode}, body : ActiveQpSelfReplenishmentSetLimitReplyMessage ]
        \cup [ tag : {QuoteBlockReplyMessageCode}, body : QuoteBlockReplyMessage ]
        \cup [ tag : {DetailedQuoteBlockReplyMessageCode}, body : DetailedQuoteBlockReplyMessage ]
        \cup [ tag : {UnderlyingPurgeReplyMessageCode}, body : UnderlyingPurgeReplyMessage ]
        \cup [ tag : {MarketReentryReplyMessageCode}, body : MarketReentryReplyMessage ]
        \cup [ tag : {ActiveQpSelfReplenishmentRequestReentryReplyMessageCode}, body : ActiveQpSelfReplenishmentRequestReentryReplyMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {InstrumentPurgeNotificationMessageCode}, body : InstrumentPurgeNotificationMessage ]
        \cup [ tag : {UnderlyingPurgeNotificationMessageCode}, body : UnderlyingPurgeNotificationMessage ]
        \cup [ tag : {MarketReentryNotificationMessageCode}, body : MarketReentryNotificationMessage ]

EncodeServerUnsequencedMessage(message) ==
    CASE message.tag = NotificationSubscriptionReplyMessageCode -> EncodeNotificationSubscriptionReplyMessage(message.body)
      [] message.tag = AddComplexInstrumentReplyMessageCode -> EncodeAddComplexInstrumentReplyMessage(message.body)
      [] message.tag = MmParameterDefinitionReplyMessageCode -> EncodeMmParameterDefinitionReplyMessage(message.body)
      [] message.tag = ActiveQpSelfReplenishmentSetLimitReplyMessageCode -> EncodeActiveQpSelfReplenishmentSetLimitReplyMessage(message.body)
      [] message.tag = QuoteBlockReplyMessageCode -> EncodeQuoteBlockReplyMessage(message.body)
      [] message.tag = DetailedQuoteBlockReplyMessageCode -> EncodeDetailedQuoteBlockReplyMessage(message.body)
      [] message.tag = UnderlyingPurgeReplyMessageCode -> EncodeUnderlyingPurgeReplyMessage(message.body)
      [] message.tag = MarketReentryReplyMessageCode -> EncodeMarketReentryReplyMessage(message.body)
      [] message.tag = ActiveQpSelfReplenishmentRequestReentryReplyMessageCode -> EncodeActiveQpSelfReplenishmentRequestReentryReplyMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = InstrumentPurgeNotificationMessageCode -> EncodeInstrumentPurgeNotificationMessage(message.body)
      [] message.tag = UnderlyingPurgeNotificationMessageCode -> EncodeUnderlyingPurgeNotificationMessage(message.body)
      [] message.tag = MarketReentryNotificationMessageCode -> EncodeMarketReentryNotificationMessage(message.body)

DecodeServerUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NotificationSubscriptionReplyMessageCode -> DecodeNotificationSubscriptionReplyMessage(bytes)
              [] tag = AddComplexInstrumentReplyMessageCode -> DecodeAddComplexInstrumentReplyMessage(bytes)
              [] tag = MmParameterDefinitionReplyMessageCode -> DecodeMmParameterDefinitionReplyMessage(bytes)
              [] tag = ActiveQpSelfReplenishmentSetLimitReplyMessageCode -> DecodeActiveQpSelfReplenishmentSetLimitReplyMessage(bytes)
              [] tag = QuoteBlockReplyMessageCode -> DecodeQuoteBlockReplyMessage(bytes)
              [] tag = DetailedQuoteBlockReplyMessageCode -> DecodeDetailedQuoteBlockReplyMessage(bytes)
              [] tag = UnderlyingPurgeReplyMessageCode -> DecodeUnderlyingPurgeReplyMessage(bytes)
              [] tag = MarketReentryReplyMessageCode -> DecodeMarketReentryReplyMessage(bytes)
              [] tag = ActiveQpSelfReplenishmentRequestReentryReplyMessageCode -> DecodeActiveQpSelfReplenishmentRequestReentryReplyMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = InstrumentPurgeNotificationMessageCode -> DecodeInstrumentPurgeNotificationMessage(bytes)
              [] tag = UnderlyingPurgeNotificationMessageCode -> DecodeUnderlyingPurgeNotificationMessage(bytes)
              [] tag = MarketReentryNotificationMessageCode -> DecodeMarketReentryNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerUnsequencedMessage == [tag |-> NotificationSubscriptionReplyMessageCode, body |-> ZeroNotificationSubscriptionReplyMessage]

(* Each Server Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedServerUnsequencedMessage ==
    { [tag |-> NotificationSubscriptionReplyMessageCode, body |-> one] : one \in CheckedNotificationSubscriptionReplyMessage }
        \cup { [tag |-> AddComplexInstrumentReplyMessageCode, body |-> one] : one \in CheckedAddComplexInstrumentReplyMessage }
        \cup { [tag |-> MmParameterDefinitionReplyMessageCode, body |-> one] : one \in CheckedMmParameterDefinitionReplyMessage }
        \cup { [tag |-> ActiveQpSelfReplenishmentSetLimitReplyMessageCode, body |-> one] : one \in CheckedActiveQpSelfReplenishmentSetLimitReplyMessage }
        \cup { [tag |-> QuoteBlockReplyMessageCode, body |-> one] : one \in CheckedQuoteBlockReplyMessage }
        \cup { [tag |-> DetailedQuoteBlockReplyMessageCode, body |-> one] : one \in CheckedDetailedQuoteBlockReplyMessage }
        \cup { [tag |-> UnderlyingPurgeReplyMessageCode, body |-> one] : one \in CheckedUnderlyingPurgeReplyMessage }
        \cup { [tag |-> MarketReentryReplyMessageCode, body |-> one] : one \in CheckedMarketReentryReplyMessage }
        \cup { [tag |-> ActiveQpSelfReplenishmentRequestReentryReplyMessageCode, body |-> one] : one \in CheckedActiveQpSelfReplenishmentRequestReentryReplyMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> InstrumentPurgeNotificationMessageCode, body |-> one] : one \in CheckedInstrumentPurgeNotificationMessage }
        \cup { [tag |-> UnderlyingPurgeNotificationMessageCode, body |-> one] : one \in CheckedUnderlyingPurgeNotificationMessage }
        \cup { [tag |-> MarketReentryNotificationMessageCode, body |-> one] : one \in CheckedMarketReentryNotificationMessage }

(***************************************************************************)
(* Server Unsequenced Data Packet                                          *)
(***************************************************************************)

ServerUnsequencedDataPacket ==
    [ serverUnsequencedMessage : ServerUnsequencedMessage ]

EncodeServerUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.serverUnsequencedMessage.tag, 2)
        \o EncodeServerUnsequencedMessage(message.serverUnsequencedMessage)

DecodeServerUnsequencedDataPacket(bytes) ==
    LET serverUnsequencedMessageType == ReadUIntBE(bytes, 2) IN IF ~serverUnsequencedMessageType.ok THEN Fail ELSE
    LET serverUnsequencedMessage == DecodeServerUnsequencedMessage(serverUnsequencedMessageType.value, serverUnsequencedMessageType.rest) IN IF ~serverUnsequencedMessage.ok THEN Fail ELSE
    Ok([ serverUnsequencedMessage |-> serverUnsequencedMessage.value ], serverUnsequencedMessage.rest)

ZeroServerUnsequencedDataPacket ==
    [ serverUnsequencedMessage |-> ZeroServerUnsequencedMessage ]

(* Server Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerUnsequencedDataPacket ==
    { ZeroServerUnsequencedDataPacket }
        \cup { [ZeroServerUnsequencedDataPacket EXCEPT !.serverUnsequencedMessage = one] : one \in CheckedServerUnsequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerUnsequencedDataPacketCode == 85  \* "U"
ServerHeartbeatPacketCode == 72  \* "H"
EndOfSessionPacketCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerUnsequencedDataPacketCode}, body : ServerUnsequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatPacketCode}, body : {0} ]
        \cup [ tag : {EndOfSessionPacketCode}, body : {0} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerUnsequencedDataPacketCode -> EncodeServerUnsequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatPacketCode -> << >>
      [] message.tag = EndOfSessionPacketCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerUnsequencedDataPacketCode -> DecodeServerUnsequencedDataPacket(bytes)
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
        \cup { [tag |-> ServerUnsequencedDataPacketCode, body |-> one] : one \in CheckedServerUnsequencedDataPacket }
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
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerUnsequencedDataPacketCode, body |-> ZeroServerUnsequencedDataPacket]],
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

(* Every Msar Accept Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMsarAcceptMessage ==
    \A message \in CheckedMsarAcceptMessage :
        LET read == DecodeMsarAcceptMessage(EncodeMsarAcceptMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Msar Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMsarRejectMessage ==
    \A message \in CheckedMsarRejectMessage :
        LET read == DecodeMsarRejectMessage(EncodeMsarRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Msar Accept Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexMsarAcceptMessage ==
    \A message \in CheckedComplexMsarAcceptMessage :
        LET read == DecodeComplexMsarAcceptMessage(EncodeComplexMsarAcceptMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Msar Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexMsarRejectMessage ==
    \A message \in CheckedComplexMsarRejectMessage :
        LET read == DecodeComplexMsarRejectMessage(EncodeComplexMsarRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Permission Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingPermissionNotificationMessage ==
    \A message \in CheckedUnderlyingPermissionNotificationMessage :
        LET read == DecodeUnderlyingPermissionNotificationMessage(EncodeUnderlyingPermissionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Parameter Definition Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmParameterDefinitionNotificationMessage ==
    \A message \in CheckedMmParameterDefinitionNotificationMessage :
        LET read == DecodeMmParameterDefinitionNotificationMessage(EncodeMmParameterDefinitionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Qp Self Replenishment Parameter Definition Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveQpSelfReplenishmentParameterDefinitionNotificationMessage ==
    \A message \in CheckedActiveQpSelfReplenishmentParameterDefinitionNotificationMessage :
        LET read == DecodeActiveQpSelfReplenishmentParameterDefinitionNotificationMessage(EncodeActiveQpSelfReplenishmentParameterDefinitionNotificationMessage(message))
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

(* Every Simple Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleInstrumentDirectoryMessage ==
    \A message \in CheckedSimpleInstrumentDirectoryMessage :
        LET read == DecodeSimpleInstrumentDirectoryMessage(EncodeSimpleInstrumentDirectoryMessage(message))
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

(* Every Complex Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDirectoryMessage ==
    \A message \in CheckedComplexInstrumentDirectoryMessage :
        LET read == DecodeComplexInstrumentDirectoryMessage(EncodeComplexInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Instrument Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleInstrumentTradingActionMessage ==
    \A message \in CheckedSimpleInstrumentTradingActionMessage :
        LET read == DecodeSimpleInstrumentTradingActionMessage(EncodeSimpleInstrumentTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentTradingActionMessage ==
    \A message \in CheckedComplexInstrumentTradingActionMessage :
        LET read == DecodeComplexInstrumentTradingActionMessage(EncodeComplexInstrumentTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Execution Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteExecutionNotificationMessage ==
    \A message \in CheckedSimpleQuoteExecutionNotificationMessage :
        LET read == DecodeSimpleQuoteExecutionNotificationMessage(EncodeSimpleQuoteExecutionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Execution Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteExecutionNotificationMessage ==
    \A message \in CheckedComplexQuoteExecutionNotificationMessage :
        LET read == DecodeComplexQuoteExecutionNotificationMessage(EncodeComplexQuoteExecutionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Leg Execution Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteLegExecutionNotificationMessage ==
    \A message \in CheckedComplexQuoteLegExecutionNotificationMessage :
        LET read == DecodeComplexQuoteLegExecutionNotificationMessage(EncodeComplexQuoteLegExecutionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Msar Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleMsarNotificationMessage ==
    \A message \in CheckedSimpleMsarNotificationMessage :
        LET read == DecodeSimpleMsarNotificationMessage(EncodeSimpleMsarNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Msar Leg Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexMsarLegNotificationMessage ==
    \A message \in CheckedComplexMsarLegNotificationMessage :
        LET read == DecodeComplexMsarLegNotificationMessage(EncodeComplexMsarLegNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Msar Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexMsarNotificationMessage ==
    \A message \in CheckedComplexMsarNotificationMessage :
        LET read == DecodeComplexMsarNotificationMessage(EncodeComplexMsarNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Rotation Quote Spread Multiplier Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningRotationQuoteSpreadMultiplierNotificationMessage ==
    \A message \in CheckedOpeningRotationQuoteSpreadMultiplierNotificationMessage :
        LET read == DecodeOpeningRotationQuoteSpreadMultiplierNotificationMessage(EncodeOpeningRotationQuoteSpreadMultiplierNotificationMessage(message))
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

(* Every Notification Subscription Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNotificationSubscriptionReplyMessage ==
    \A message \in CheckedNotificationSubscriptionReplyMessage :
        LET read == DecodeNotificationSubscriptionReplyMessage(EncodeNotificationSubscriptionReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentReplyMessage ==
    \A message \in CheckedAddComplexInstrumentReplyMessage :
        LET read == DecodeAddComplexInstrumentReplyMessage(EncodeAddComplexInstrumentReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Parameter Definition Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmParameterDefinitionReplyMessage ==
    \A message \in CheckedMmParameterDefinitionReplyMessage :
        LET read == DecodeMmParameterDefinitionReplyMessage(EncodeMmParameterDefinitionReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Qp Self Replenishment Set Limit Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveQpSelfReplenishmentSetLimitReplyMessage ==
    \A message \in CheckedActiveQpSelfReplenishmentSetLimitReplyMessage :
        LET read == DecodeActiveQpSelfReplenishmentSetLimitReplyMessage(EncodeActiveQpSelfReplenishmentSetLimitReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Responses decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteResponses ==
    \A message \in CheckedQuoteResponses :
        LET read == DecodeQuoteResponses(EncodeQuoteResponses(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Block Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteBlockReplyMessage ==
    \A message \in CheckedQuoteBlockReplyMessage :
        LET read == DecodeQuoteBlockReplyMessage(EncodeQuoteBlockReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Detailed Quote Responses decodes back to what was encoded, and leaves nothing over *)
RoundTripDetailedQuoteResponses ==
    \A message \in CheckedDetailedQuoteResponses :
        LET read == DecodeDetailedQuoteResponses(EncodeDetailedQuoteResponses(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Detailed Quote Block Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDetailedQuoteBlockReplyMessage ==
    \A message \in CheckedDetailedQuoteBlockReplyMessage :
        LET read == DecodeDetailedQuoteBlockReplyMessage(EncodeDetailedQuoteBlockReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Purge Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingPurgeReplyMessage ==
    \A message \in CheckedUnderlyingPurgeReplyMessage :
        LET read == DecodeUnderlyingPurgeReplyMessage(EncodeUnderlyingPurgeReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Reentry Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketReentryReplyMessage ==
    \A message \in CheckedMarketReentryReplyMessage :
        LET read == DecodeMarketReentryReplyMessage(EncodeMarketReentryReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Qp Self Replenishment Request Reentry Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveQpSelfReplenishmentRequestReentryReplyMessage ==
    \A message \in CheckedActiveQpSelfReplenishmentRequestReentryReplyMessage :
        LET read == DecodeActiveQpSelfReplenishmentRequestReentryReplyMessage(EncodeActiveQpSelfReplenishmentRequestReentryReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Dac Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexDacLegs ==
    \A message \in CheckedFlexDacLegs :
        LET read == DecodeFlexDacLegs(EncodeFlexDacLegs(message))
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

(* Every Instrument Purge Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentPurgeNotificationMessage ==
    \A message \in CheckedInstrumentPurgeNotificationMessage :
        LET read == DecodeInstrumentPurgeNotificationMessage(EncodeInstrumentPurgeNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Purge Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingPurgeNotificationMessage ==
    \A message \in CheckedUnderlyingPurgeNotificationMessage :
        LET read == DecodeUnderlyingPurgeNotificationMessage(EncodeUnderlyingPurgeNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Reentry Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketReentryNotificationMessage ==
    \A message \in CheckedMarketReentryNotificationMessage :
        LET read == DecodeMarketReentryNotificationMessage(EncodeMarketReentryNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerUnsequencedDataPacket ==
    \A message \in CheckedServerUnsequencedDataPacket :
        LET read == DecodeServerUnsequencedDataPacket(EncodeServerUnsequencedDataPacket(message))
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

(* A Server Unsequenced Message is selected by the Server Unsequenced Message Type it is written under *)
SelectsServerUnsequencedMessage ==
    \A message \in CheckedServerUnsequencedMessage :
        LET read == DecodeServerUnsequencedMessage(message.tag, EncodeServerUnsequencedMessage(message))
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
