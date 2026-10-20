---------------------- MODULE Deribit_OrdersApi_v1_4 -----------------------
(***************************************************************************)
(* Coinbase Orders Api v1.4                                                *)
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
(* Note: Session Flags is a bit field set, checked as its 1 byte rather    *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Flags Order Flags is a bit field set, checked as its 2 bytes      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Flags Replace Order Flags is a bit field set, checked as its 2    *)
(* bytes rather than bit by bit.                                           *)
(*                                                                         *)
(* Note: Flags Mass Quote Flags is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Bid Flags is a bit field set, checked as its 2 bytes rather than  *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Ask Flags is a bit field set, checked as its 2 bytes rather than  *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Flags Fill Flags is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Flags Multi Part Event Flags is a bit field set, checked as its 1 *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Flags Cancel Flags is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
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
(* Logon Message: 67 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ clientId      : Sample(16),
      secret        : Sample(48),
      resetSeqNum   : Sample(1),
      schemaVersion : Sample(2) ]

EncodeLogonMessage(message) ==
    message.clientId
        \o message.secret
        \o message.resetSeqNum
        \o message.schemaVersion

DecodeLogonMessage(bytes) ==
    LET clientId == ReadBytes(bytes, 16) IN IF ~clientId.ok THEN Fail ELSE
    LET secret == ReadBytes(clientId.rest, 48) IN IF ~secret.ok THEN Fail ELSE
    LET resetSeqNum == ReadBytes(secret.rest, 1) IN IF ~resetSeqNum.ok THEN Fail ELSE
    LET schemaVersion == ReadBytes(resetSeqNum.rest, 2) IN IF ~schemaVersion.ok THEN Fail ELSE
    Ok([ clientId      |-> clientId.value,
         secret        |-> secret.value,
         resetSeqNum   |-> resetSeqNum.value,
         schemaVersion |-> schemaVersion.value ], schemaVersion.rest)

ZeroLogonMessage ==
    [ clientId      |-> [i \in 1 .. 16 |-> 0],
      secret        |-> [i \in 1 .. 48 |-> 0],
      resetSeqNum   |-> [i \in 1 .. 1 |-> 0],
      schemaVersion |-> [i \in 1 .. 2 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.clientId = one] : one \in Sample(16) }
        \cup { [ZeroLogonMessage EXCEPT !.secret = one] : one \in Sample(48) }
        \cup { [ZeroLogonMessage EXCEPT !.resetSeqNum = one] : one \in Sample(1) }
        \cup { [ZeroLogonMessage EXCEPT !.schemaVersion = one] : one \in Sample(2) }

(***************************************************************************)
(* Logon Conf Message: 6 bytes                                             *)
(***************************************************************************)

LogonConfMessage ==
    [ heartbeatIntervalSeconds : Sample(4),
      schemaVersion            : Sample(2) ]

EncodeLogonConfMessage(message) ==
    message.heartbeatIntervalSeconds
        \o message.schemaVersion

DecodeLogonConfMessage(bytes) ==
    LET heartbeatIntervalSeconds == ReadBytes(bytes, 4) IN IF ~heartbeatIntervalSeconds.ok THEN Fail ELSE
    LET schemaVersion == ReadBytes(heartbeatIntervalSeconds.rest, 2) IN IF ~schemaVersion.ok THEN Fail ELSE
    Ok([ heartbeatIntervalSeconds |-> heartbeatIntervalSeconds.value,
         schemaVersion            |-> schemaVersion.value ], schemaVersion.rest)

ZeroLogonConfMessage ==
    [ heartbeatIntervalSeconds |-> [i \in 1 .. 4 |-> 0],
      schemaVersion            |-> [i \in 1 .. 2 |-> 0] ]

(* Logon Conf Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonConfMessage ==
    { ZeroLogonConfMessage }
        \cup { [ZeroLogonConfMessage EXCEPT !.heartbeatIntervalSeconds = one] : one \in Sample(4) }
        \cup { [ZeroLogonConfMessage EXCEPT !.schemaVersion = one] : one \in Sample(2) }

(***************************************************************************)
(* Reason                                                                  *)
(***************************************************************************)

Reason ==
    [ reasonData : SampleBytes ]

EncodeReason(message) ==
    EncodeUIntBE(Len(message.reasonData), 1)
        \o message.reasonData

DecodeReason(bytes) ==
    LET reasonLength == ReadUIntBE(bytes, 1) IN IF ~reasonLength.ok THEN Fail ELSE
    LET reasonData == ReadBytes(reasonLength.rest, reasonLength.value) IN IF ~reasonData.ok THEN Fail ELSE
    Ok([ reasonData |-> reasonData.value ], reasonData.rest)

ZeroReason ==
    [ reasonData |-> << >> ]

(* Reason at zero, then each field in turn at the values it is checked at *)
CheckedReason ==
    { ZeroReason }
        \cup { [ZeroReason EXCEPT !.reasonData = one] : one \in SampleBytes }

(***************************************************************************)
(* Logout Message                                                          *)
(***************************************************************************)

LogoutMessage ==
    [ reason : Reason ]

EncodeLogoutMessage(message) ==
    EncodeReason(message.reason)

DecodeLogoutMessage(bytes) ==
    LET reason == DecodeReason(bytes) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroLogoutMessage ==
    [ reason |-> ZeroReason ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.reason = one] : one \in CheckedReason }

(***************************************************************************)
(* Reason                                                                  *)
(***************************************************************************)

Reason2 ==
    [ reasonData : SampleBytes ]

EncodeReason2(message) ==
    EncodeUIntBE(Len(message.reasonData), 1)
        \o message.reasonData

DecodeReason2(bytes) ==
    LET reasonLength == ReadUIntBE(bytes, 1) IN IF ~reasonLength.ok THEN Fail ELSE
    LET reasonData == ReadBytes(reasonLength.rest, reasonLength.value) IN IF ~reasonData.ok THEN Fail ELSE
    Ok([ reasonData |-> reasonData.value ], reasonData.rest)

ZeroReason2 ==
    [ reasonData |-> << >> ]

(* Reason at zero, then each field in turn at the values it is checked at *)
CheckedReason2 ==
    { ZeroReason2 }
        \cup { [ZeroReason2 EXCEPT !.reasonData = one] : one \in SampleBytes }

(***************************************************************************)
(* Logged Out Message                                                      *)
(***************************************************************************)

LoggedOutMessage ==
    [ reason : Reason2 ]

EncodeLoggedOutMessage(message) ==
    EncodeReason2(message.reason)

DecodeLoggedOutMessage(bytes) ==
    LET reason == DecodeReason2(bytes) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroLoggedOutMessage ==
    [ reason |-> ZeroReason2 ]

(* Logged Out Message at zero, then each field in turn at the values it is checked at *)
CheckedLoggedOutMessage ==
    { ZeroLoggedOutMessage }
        \cup { [ZeroLoggedOutMessage EXCEPT !.reason = one] : one \in CheckedReason2 }

(***************************************************************************)
(* Heartbeat Message: 8 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ correlationId : Sample(8) ]

EncodeHeartbeatMessage(message) ==
    message.correlationId

DecodeHeartbeatMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroHeartbeatMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Test Request Message: 8 bytes                                           *)
(***************************************************************************)

TestRequestMessage ==
    [ correlationId : Sample(8) ]

EncodeTestRequestMessage(message) ==
    message.correlationId

DecodeTestRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroTestRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Test Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTestRequestMessage ==
    { ZeroTestRequestMessage }
        \cup { [ZeroTestRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Resend Request Message: 16 bytes                                        *)
(***************************************************************************)

ResendRequestMessage ==
    [ fromSequenceNumber : Sample(8),
      toSequenceNumber   : Sample(8) ]

EncodeResendRequestMessage(message) ==
    message.fromSequenceNumber
        \o message.toSequenceNumber

DecodeResendRequestMessage(bytes) ==
    LET fromSequenceNumber == ReadBytes(bytes, 8) IN IF ~fromSequenceNumber.ok THEN Fail ELSE
    LET toSequenceNumber == ReadBytes(fromSequenceNumber.rest, 8) IN IF ~toSequenceNumber.ok THEN Fail ELSE
    Ok([ fromSequenceNumber |-> fromSequenceNumber.value,
         toSequenceNumber   |-> toSequenceNumber.value ], toSequenceNumber.rest)

ZeroResendRequestMessage ==
    [ fromSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      toSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Resend Request Message at zero, then each field in turn at the values it is checked at *)
CheckedResendRequestMessage ==
    { ZeroResendRequestMessage }
        \cup { [ZeroResendRequestMessage EXCEPT !.fromSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroResendRequestMessage EXCEPT !.toSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Gap Fill Message: 8 bytes                                               *)
(***************************************************************************)

GapFillMessage ==
    [ newSequenceNumber : Sample(8) ]

EncodeGapFillMessage(message) ==
    message.newSequenceNumber

DecodeGapFillMessage(bytes) ==
    LET newSequenceNumber == ReadBytes(bytes, 8) IN IF ~newSequenceNumber.ok THEN Fail ELSE
    Ok([ newSequenceNumber |-> newSequenceNumber.value ], newSequenceNumber.rest)

ZeroGapFillMessage ==
    [ newSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Gap Fill Message at zero, then each field in turn at the values it is checked at *)
CheckedGapFillMessage ==
    { ZeroGapFillMessage }
        \cup { [ZeroGapFillMessage EXCEPT !.newSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Details                                                                 *)
(***************************************************************************)

Details ==
    [ detailsData : SampleBytes ]

EncodeDetails(message) ==
    EncodeUIntBE(Len(message.detailsData), 1)
        \o message.detailsData

DecodeDetails(bytes) ==
    LET detailsLength == ReadUIntBE(bytes, 1) IN IF ~detailsLength.ok THEN Fail ELSE
    LET detailsData == ReadBytes(detailsLength.rest, detailsLength.value) IN IF ~detailsData.ok THEN Fail ELSE
    Ok([ detailsData |-> detailsData.value ], detailsData.rest)

ZeroDetails ==
    [ detailsData |-> << >> ]

(* Details at zero, then each field in turn at the values it is checked at *)
CheckedDetails ==
    { ZeroDetails }
        \cup { [ZeroDetails EXCEPT !.detailsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Reject Message                                                          *)
(***************************************************************************)

RejectMessage ==
    [ refSequenceNumber  : Sample(8),
      reasonRejectReason : Sample(1),
      details            : Details ]

EncodeRejectMessage(message) ==
    message.refSequenceNumber
        \o message.reasonRejectReason
        \o EncodeDetails(message.details)

DecodeRejectMessage(bytes) ==
    LET refSequenceNumber == ReadBytes(bytes, 8) IN IF ~refSequenceNumber.ok THEN Fail ELSE
    LET reasonRejectReason == ReadBytes(refSequenceNumber.rest, 1) IN IF ~reasonRejectReason.ok THEN Fail ELSE
    LET details == DecodeDetails(reasonRejectReason.rest) IN IF ~details.ok THEN Fail ELSE
    Ok([ refSequenceNumber  |-> refSequenceNumber.value,
         reasonRejectReason |-> reasonRejectReason.value,
         details            |-> details.value ], details.rest)

ZeroRejectMessage ==
    [ refSequenceNumber  |-> [i \in 1 .. 8 |-> 0],
      reasonRejectReason |-> [i \in 1 .. 1 |-> 0],
      details            |-> ZeroDetails ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.refSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.reasonRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.details = one] : one \in CheckedDetails }

(***************************************************************************)
(* Quantity: 9 bytes                                                       *)
(***************************************************************************)

Quantity ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeQuantity(message) ==
    message.mantissa
        \o message.exponent

DecodeQuantity(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroQuantity ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuantity ==
    { ZeroQuantity }
        \cup { [ZeroQuantity EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroQuantity EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Show Qty: 9 bytes                                                       *)
(***************************************************************************)

ShowQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeShowQty(message) ==
    message.mantissa
        \o message.exponent

DecodeShowQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroShowQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Show Qty at zero, then each field in turn at the values it is checked at *)
CheckedShowQty ==
    { ZeroShowQty }
        \cup { [ZeroShowQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroShowQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Request Message: 63 bytes                                     *)
(***************************************************************************)

NewOrderRequestMessage ==
    [ clientOrderId         : Sample(8),
      correlationId         : Sample(8),
      instrumentId          : Sample(8),
      price                 : Sample(8),
      quantity              : Quantity,
      showQty               : ShowQty,
      selfMatchPreventionId : Sample(8),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      flagsOrderFlags       : Sample(2),
      selfTradingMode       : Sample(1) ]

EncodeNewOrderRequestMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.instrumentId
        \o message.price
        \o EncodeQuantity(message.quantity)
        \o EncodeShowQty(message.showQty)
        \o message.selfMatchPreventionId
        \o message.side
        \o message.timeInForce
        \o message.flagsOrderFlags
        \o message.selfTradingMode

DecodeNewOrderRequestMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(correlationId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == DecodeQuantity(price.rest) IN IF ~quantity.ok THEN Fail ELSE
    LET showQty == DecodeShowQty(quantity.rest) IN IF ~showQty.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(showQty.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET side == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET flagsOrderFlags == ReadBytes(timeInForce.rest, 2) IN IF ~flagsOrderFlags.ok THEN Fail ELSE
    LET selfTradingMode == ReadBytes(flagsOrderFlags.rest, 1) IN IF ~selfTradingMode.ok THEN Fail ELSE
    Ok([ clientOrderId         |-> clientOrderId.value,
         correlationId         |-> correlationId.value,
         instrumentId          |-> instrumentId.value,
         price                 |-> price.value,
         quantity              |-> quantity.value,
         showQty               |-> showQty.value,
         selfMatchPreventionId |-> selfMatchPreventionId.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         flagsOrderFlags       |-> flagsOrderFlags.value,
         selfTradingMode       |-> selfTradingMode.value ], selfTradingMode.rest)

ZeroNewOrderRequestMessage ==
    [ clientOrderId         |-> [i \in 1 .. 8 |-> 0],
      correlationId         |-> [i \in 1 .. 8 |-> 0],
      instrumentId          |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      quantity              |-> ZeroQuantity,
      showQty               |-> ZeroShowQty,
      selfMatchPreventionId |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      flagsOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      selfTradingMode       |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRequestMessage ==
    { ZeroNewOrderRequestMessage }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.quantity = one] : one \in CheckedQuantity }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.showQty = one] : one \in CheckedShowQty }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.flagsOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfTradingMode = one] : one \in Sample(1) }

(***************************************************************************)
(* Quantity: 9 bytes                                                       *)
(***************************************************************************)

Quantity2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeQuantity2(message) ==
    message.mantissa
        \o message.exponent

DecodeQuantity2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroQuantity2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuantity2 ==
    { ZeroQuantity2 }
        \cup { [ZeroQuantity2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroQuantity2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Show Qty: 9 bytes                                                       *)
(***************************************************************************)

ShowQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeShowQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeShowQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroShowQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Show Qty at zero, then each field in turn at the values it is checked at *)
CheckedShowQty2 ==
    { ZeroShowQty2 }
        \cup { [ZeroShowQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroShowQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Amend Order Request Message: 52 bytes                                   *)
(***************************************************************************)

AmendOrderRequestMessage ==
    [ clientOrderId          : Sample(8),
      correlationId          : Sample(8),
      instrumentId           : Sample(8),
      price                  : Sample(8),
      quantity               : Quantity2,
      showQty                : ShowQty2,
      flagsReplaceOrderFlags : Sample(2) ]

EncodeAmendOrderRequestMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.instrumentId
        \o message.price
        \o EncodeQuantity2(message.quantity)
        \o EncodeShowQty2(message.showQty)
        \o message.flagsReplaceOrderFlags

DecodeAmendOrderRequestMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(correlationId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == DecodeQuantity2(price.rest) IN IF ~quantity.ok THEN Fail ELSE
    LET showQty == DecodeShowQty2(quantity.rest) IN IF ~showQty.ok THEN Fail ELSE
    LET flagsReplaceOrderFlags == ReadBytes(showQty.rest, 2) IN IF ~flagsReplaceOrderFlags.ok THEN Fail ELSE
    Ok([ clientOrderId          |-> clientOrderId.value,
         correlationId          |-> correlationId.value,
         instrumentId           |-> instrumentId.value,
         price                  |-> price.value,
         quantity               |-> quantity.value,
         showQty                |-> showQty.value,
         flagsReplaceOrderFlags |-> flagsReplaceOrderFlags.value ], flagsReplaceOrderFlags.rest)

ZeroAmendOrderRequestMessage ==
    [ clientOrderId          |-> [i \in 1 .. 8 |-> 0],
      correlationId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId           |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      quantity               |-> ZeroQuantity2,
      showQty                |-> ZeroShowQty2,
      flagsReplaceOrderFlags |-> [i \in 1 .. 2 |-> 0] ]

(* Amend Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderRequestMessage ==
    { ZeroAmendOrderRequestMessage }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.quantity = one] : one \in CheckedQuantity2 }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.showQty = one] : one \in CheckedShowQty2 }
        \cup { [ZeroAmendOrderRequestMessage EXCEPT !.flagsReplaceOrderFlags = one] : one \in Sample(2) }

(***************************************************************************)
(* Cancel Order Request Message: 24 bytes                                  *)
(***************************************************************************)

CancelOrderRequestMessage ==
    [ clientOrderId : Sample(8),
      correlationId : Sample(8),
      instrumentId  : Sample(8) ]

EncodeCancelOrderRequestMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.instrumentId

DecodeCancelOrderRequestMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(correlationId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         instrumentId  |-> instrumentId.value ], instrumentId.rest)

ZeroCancelOrderRequestMessage ==
    [ clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRequestMessage ==
    { ZeroCancelOrderRequestMessage }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Order By Id Request Message: 24 bytes                            *)
(***************************************************************************)

CancelOrderByIdRequestMessage ==
    [ orderId       : Sample(8),
      correlationId : Sample(8),
      instrumentId  : Sample(8) ]

EncodeCancelOrderByIdRequestMessage(message) ==
    message.orderId
        \o message.correlationId
        \o message.instrumentId

DecodeCancelOrderByIdRequestMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(orderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(correlationId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         correlationId |-> correlationId.value,
         instrumentId  |-> instrumentId.value ], instrumentId.rest)

ZeroCancelOrderByIdRequestMessage ==
    [ orderId       |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Order By Id Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderByIdRequestMessage ==
    { ZeroCancelOrderByIdRequestMessage }
        \cup { [ZeroCancelOrderByIdRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByIdRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByIdRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bid Qty: 9 bytes                                                        *)
(***************************************************************************)

BidQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeBidQty(message) ==
    message.mantissa
        \o message.exponent

DecodeBidQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroBidQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Bid Qty at zero, then each field in turn at the values it is checked at *)
CheckedBidQty ==
    { ZeroBidQty }
        \cup { [ZeroBidQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroBidQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Qty: 9 bytes                                                        *)
(***************************************************************************)

AskQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeAskQty(message) ==
    message.mantissa
        \o message.exponent

DecodeAskQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroAskQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Ask Qty at zero, then each field in turn at the values it is checked at *)
CheckedAskQty ==
    { ZeroAskQty }
        \cup { [ZeroAskQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroAskQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Request Message quotes Group: 46 bytes                       *)
(***************************************************************************)

MassQuoteRequestMessageQuotesGroup ==
    [ instrumentId     : Sample(8),
      bidPriceOptional : Sample(8),
      askPriceOptional : Sample(8),
      bidQty           : BidQty,
      askQty           : AskQty,
      bidFlags         : Sample(2),
      askFlags         : Sample(2) ]

EncodeMassQuoteRequestMessageQuotesGroup(message) ==
    message.instrumentId
        \o message.bidPriceOptional
        \o message.askPriceOptional
        \o EncodeBidQty(message.bidQty)
        \o EncodeAskQty(message.askQty)
        \o message.bidFlags
        \o message.askFlags

DecodeMassQuoteRequestMessageQuotesGroup(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPriceOptional == ReadBytes(instrumentId.rest, 8) IN IF ~bidPriceOptional.ok THEN Fail ELSE
    LET askPriceOptional == ReadBytes(bidPriceOptional.rest, 8) IN IF ~askPriceOptional.ok THEN Fail ELSE
    LET bidQty == DecodeBidQty(askPriceOptional.rest) IN IF ~bidQty.ok THEN Fail ELSE
    LET askQty == DecodeAskQty(bidQty.rest) IN IF ~askQty.ok THEN Fail ELSE
    LET bidFlags == ReadBytes(askQty.rest, 2) IN IF ~bidFlags.ok THEN Fail ELSE
    LET askFlags == ReadBytes(bidFlags.rest, 2) IN IF ~askFlags.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         bidPriceOptional |-> bidPriceOptional.value,
         askPriceOptional |-> askPriceOptional.value,
         bidQty           |-> bidQty.value,
         askQty           |-> askQty.value,
         bidFlags         |-> bidFlags.value,
         askFlags         |-> askFlags.value ], askFlags.rest)

ZeroMassQuoteRequestMessageQuotesGroup ==
    [ instrumentId     |-> [i \in 1 .. 8 |-> 0],
      bidPriceOptional |-> [i \in 1 .. 8 |-> 0],
      askPriceOptional |-> [i \in 1 .. 8 |-> 0],
      bidQty           |-> ZeroBidQty,
      askQty           |-> ZeroAskQty,
      bidFlags         |-> [i \in 1 .. 2 |-> 0],
      askFlags         |-> [i \in 1 .. 2 |-> 0] ]

(* Mass Quote Request Message quotes Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequestMessageQuotesGroup ==
    { ZeroMassQuoteRequestMessageQuotesGroup }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.bidPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.askPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.bidQty = one] : one \in CheckedBidQty }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.askQty = one] : one \in CheckedAskQty }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.bidFlags = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroup EXCEPT !.askFlags = one] : one \in Sample(2) }

(* A run of Mass Quote Request Message quotes Group, written one after another *)
RECURSIVE EncodeMassQuoteRequestMessageQuotesGroupList(_)
EncodeMassQuoteRequestMessageQuotesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteRequestMessageQuotesGroup(Head(messages)) \o EncodeMassQuoteRequestMessageQuotesGroupList(Tail(messages))

(* As many Mass Quote Request Message quotes Group as the field that counts them says *)
RECURSIVE ReadMassQuoteRequestMessageQuotesGroupList(_, _)
ReadMassQuoteRequestMessageQuotesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteRequestMessageQuotesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteRequestMessageQuotesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Request Message quotes Group of each kind, for the lists that carry them *)
OneMassQuoteRequestMessageQuotesGroup == { ZeroMassQuoteRequestMessageQuotesGroup }

(***************************************************************************)
(* Mass Quote Request Message quotes Groups                                *)
(***************************************************************************)

MassQuoteRequestMessageQuotesGroups ==
    [ blockLength                        : Sample(2),
      massQuoteRequestMessageQuotesGroup : SampleLists(OneMassQuoteRequestMessageQuotesGroup) ]

EncodeMassQuoteRequestMessageQuotesGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteRequestMessageQuotesGroup), 2)
        \o EncodeMassQuoteRequestMessageQuotesGroupList(message.massQuoteRequestMessageQuotesGroup)

DecodeMassQuoteRequestMessageQuotesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteRequestMessageQuotesGroup == ReadMassQuoteRequestMessageQuotesGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteRequestMessageQuotesGroup.ok THEN Fail ELSE
    Ok([ blockLength                        |-> blockLength.value,
         massQuoteRequestMessageQuotesGroup |-> massQuoteRequestMessageQuotesGroup.value ], massQuoteRequestMessageQuotesGroup.rest)

ZeroMassQuoteRequestMessageQuotesGroups ==
    [ blockLength                        |-> [i \in 1 .. 2 |-> 0],
      massQuoteRequestMessageQuotesGroup |-> << >> ]

(* Mass Quote Request Message quotes Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequestMessageQuotesGroups ==
    { ZeroMassQuoteRequestMessageQuotesGroups }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequestMessageQuotesGroups EXCEPT !.massQuoteRequestMessageQuotesGroup = one] : one \in SampleLists(OneMassQuoteRequestMessageQuotesGroup) }

(***************************************************************************)
(* Mass Quote Request Message                                              *)
(***************************************************************************)

MassQuoteRequestMessage ==
    [ quoteId                             : Sample(8),
      correlationId                       : Sample(8),
      mmpGroupId                          : Sample(8),
      selfMatchPreventionId               : Sample(8),
      flagsMassQuoteFlags                 : Sample(1),
      massQuoteRequestMessageQuotesGroups : MassQuoteRequestMessageQuotesGroups ]

EncodeMassQuoteRequestMessage(message) ==
    message.quoteId
        \o message.correlationId
        \o message.mmpGroupId
        \o message.selfMatchPreventionId
        \o message.flagsMassQuoteFlags
        \o EncodeMassQuoteRequestMessageQuotesGroups(message.massQuoteRequestMessageQuotesGroups)

DecodeMassQuoteRequestMessage(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(quoteId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(correlationId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(mmpGroupId.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET flagsMassQuoteFlags == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~flagsMassQuoteFlags.ok THEN Fail ELSE
    LET massQuoteRequestMessageQuotesGroups == DecodeMassQuoteRequestMessageQuotesGroups(flagsMassQuoteFlags.rest) IN IF ~massQuoteRequestMessageQuotesGroups.ok THEN Fail ELSE
    Ok([ quoteId                             |-> quoteId.value,
         correlationId                       |-> correlationId.value,
         mmpGroupId                          |-> mmpGroupId.value,
         selfMatchPreventionId               |-> selfMatchPreventionId.value,
         flagsMassQuoteFlags                 |-> flagsMassQuoteFlags.value,
         massQuoteRequestMessageQuotesGroups |-> massQuoteRequestMessageQuotesGroups.value ], massQuoteRequestMessageQuotesGroups.rest)

ZeroMassQuoteRequestMessage ==
    [ quoteId                             |-> [i \in 1 .. 8 |-> 0],
      correlationId                       |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId                          |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionId               |-> [i \in 1 .. 8 |-> 0],
      flagsMassQuoteFlags                 |-> [i \in 1 .. 1 |-> 0],
      massQuoteRequestMessageQuotesGroups |-> ZeroMassQuoteRequestMessageQuotesGroups ]

(* Mass Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequestMessage ==
    { ZeroMassQuoteRequestMessage }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.flagsMassQuoteFlags = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.massQuoteRequestMessageQuotesGroups = one] : one \in CheckedMassQuoteRequestMessageQuotesGroups }

(***************************************************************************)
(* Mass Cancel Request Message: 26 bytes                                   *)
(***************************************************************************)

MassCancelRequestMessage ==
    [ correlationId        : Sample(8),
      currencyPairId       : Sample(8),
      instrumentIdOptional : Sample(8),
      productType          : Sample(1),
      side                 : Sample(1) ]

EncodeMassCancelRequestMessage(message) ==
    message.correlationId
        \o message.currencyPairId
        \o message.instrumentIdOptional
        \o message.productType
        \o message.side

DecodeMassCancelRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET currencyPairId == ReadBytes(correlationId.rest, 8) IN IF ~currencyPairId.ok THEN Fail ELSE
    LET instrumentIdOptional == ReadBytes(currencyPairId.rest, 8) IN IF ~instrumentIdOptional.ok THEN Fail ELSE
    LET productType == ReadBytes(instrumentIdOptional.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET side == ReadBytes(productType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ correlationId        |-> correlationId.value,
         currencyPairId       |-> currencyPairId.value,
         instrumentIdOptional |-> instrumentIdOptional.value,
         productType          |-> productType.value,
         side                 |-> side.value ], side.rest)

ZeroMassCancelRequestMessage ==
    [ correlationId        |-> [i \in 1 .. 8 |-> 0],
      currencyPairId       |-> [i \in 1 .. 8 |-> 0],
      instrumentIdOptional |-> [i \in 1 .. 8 |-> 0],
      productType          |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequestMessage ==
    { ZeroMassCancelRequestMessage }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.currencyPairId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.instrumentIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Cancel Request Message: 17 bytes                             *)
(***************************************************************************)

MassQuoteCancelRequestMessage ==
    [ correlationId : Sample(8),
      mmpGroupId    : Sample(8),
      side          : Sample(1) ]

EncodeMassQuoteCancelRequestMessage(message) ==
    message.correlationId
        \o message.mmpGroupId
        \o message.side

DecodeMassQuoteCancelRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(correlationId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET side == ReadBytes(mmpGroupId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value,
         mmpGroupId    |-> mmpGroupId.value,
         side          |-> side.value ], side.rest)

ZeroMassQuoteCancelRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId    |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteCancelRequestMessage ==
    { ZeroMassQuoteCancelRequestMessage }
        \cup { [ZeroMassQuoteCancelRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteCancelRequestMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Get Mass Quote Mmp Status Request Message: 16 bytes                     *)
(***************************************************************************)

GetMassQuoteMmpStatusRequestMessage ==
    [ correlationId : Sample(8),
      mmpGroupId    : Sample(8) ]

EncodeGetMassQuoteMmpStatusRequestMessage(message) ==
    message.correlationId
        \o message.mmpGroupId

DecodeGetMassQuoteMmpStatusRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(correlationId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value,
         mmpGroupId    |-> mmpGroupId.value ], mmpGroupId.rest)

ZeroGetMassQuoteMmpStatusRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId    |-> [i \in 1 .. 8 |-> 0] ]

(* Get Mass Quote Mmp Status Request Message at zero, then each field in turn at the values it is checked at *)
CheckedGetMassQuoteMmpStatusRequestMessage ==
    { ZeroGetMassQuoteMmpStatusRequestMessage }
        \cup { [ZeroGetMassQuoteMmpStatusRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroGetMassQuoteMmpStatusRequestMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }

(***************************************************************************)
(* Get Orders Mmp Status Request Message: 16 bytes                         *)
(***************************************************************************)

GetOrdersMmpStatusRequestMessage ==
    [ correlationId  : Sample(8),
      currencyPairId : Sample(8) ]

EncodeGetOrdersMmpStatusRequestMessage(message) ==
    message.correlationId
        \o message.currencyPairId

DecodeGetOrdersMmpStatusRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET currencyPairId == ReadBytes(correlationId.rest, 8) IN IF ~currencyPairId.ok THEN Fail ELSE
    Ok([ correlationId  |-> correlationId.value,
         currencyPairId |-> currencyPairId.value ], currencyPairId.rest)

ZeroGetOrdersMmpStatusRequestMessage ==
    [ correlationId  |-> [i \in 1 .. 8 |-> 0],
      currencyPairId |-> [i \in 1 .. 8 |-> 0] ]

(* Get Orders Mmp Status Request Message at zero, then each field in turn at the values it is checked at *)
CheckedGetOrdersMmpStatusRequestMessage ==
    { ZeroGetOrdersMmpStatusRequestMessage }
        \cup { [ZeroGetOrdersMmpStatusRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroGetOrdersMmpStatusRequestMessage EXCEPT !.currencyPairId = one] : one \in Sample(8) }

(***************************************************************************)
(* Quantity: 9 bytes                                                       *)
(***************************************************************************)

Quantity3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeQuantity3(message) ==
    message.mantissa
        \o message.exponent

DecodeQuantity3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroQuantity3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuantity3 ==
    { ZeroQuantity3 }
        \cup { [ZeroQuantity3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroQuantity3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Total Filled: 9 bytes                                                   *)
(***************************************************************************)

TotalFilled ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeTotalFilled(message) ==
    message.mantissa
        \o message.exponent

DecodeTotalFilled(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroTotalFilled ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Total Filled at zero, then each field in turn at the values it is checked at *)
CheckedTotalFilled ==
    { ZeroTotalFilled }
        \cup { [ZeroTotalFilled EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroTotalFilled EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Visible Qty: 9 bytes                                                    *)
(***************************************************************************)

VisibleQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeVisibleQty(message) ==
    message.mantissa
        \o message.exponent

DecodeVisibleQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroVisibleQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Visible Qty at zero, then each field in turn at the values it is checked at *)
CheckedVisibleQty ==
    { ZeroVisibleQty }
        \cup { [ZeroVisibleQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroVisibleQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty ==
    { ZeroFillQty }
        \cup { [ZeroFillQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Response Message fills Group: 25 bytes                        *)
(***************************************************************************)

NewOrderResponseMessageFillsGroup ==
    [ matchId   : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty ]

EncodeNewOrderResponseMessageFillsGroup(message) ==
    message.matchId
        \o message.fillPrice
        \o EncodeFillQty(message.fillQty)

DecodeNewOrderResponseMessageFillsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(matchId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value ], fillQty.rest)

ZeroNewOrderResponseMessageFillsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty ]

(* New Order Response Message fills Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessageFillsGroup ==
    { ZeroNewOrderResponseMessageFillsGroup }
        \cup { [ZeroNewOrderResponseMessageFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessageFillsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessageFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty }

(* A run of New Order Response Message fills Group, written one after another *)
RECURSIVE EncodeNewOrderResponseMessageFillsGroupList(_)
EncodeNewOrderResponseMessageFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderResponseMessageFillsGroup(Head(messages)) \o EncodeNewOrderResponseMessageFillsGroupList(Tail(messages))

(* As many New Order Response Message fills Group as the field that counts them says *)
RECURSIVE ReadNewOrderResponseMessageFillsGroupList(_, _)
ReadNewOrderResponseMessageFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderResponseMessageFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderResponseMessageFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Response Message fills Group of each kind, for the lists that carry them *)
OneNewOrderResponseMessageFillsGroup == { ZeroNewOrderResponseMessageFillsGroup }

(***************************************************************************)
(* New Order Response Message fills Groups                                 *)
(***************************************************************************)

NewOrderResponseMessageFillsGroups ==
    [ blockLength                       : Sample(2),
      newOrderResponseMessageFillsGroup : SampleLists(OneNewOrderResponseMessageFillsGroup) ]

EncodeNewOrderResponseMessageFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.newOrderResponseMessageFillsGroup), 2)
        \o EncodeNewOrderResponseMessageFillsGroupList(message.newOrderResponseMessageFillsGroup)

DecodeNewOrderResponseMessageFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderResponseMessageFillsGroup == ReadNewOrderResponseMessageFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~newOrderResponseMessageFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                       |-> blockLength.value,
         newOrderResponseMessageFillsGroup |-> newOrderResponseMessageFillsGroup.value ], newOrderResponseMessageFillsGroup.rest)

ZeroNewOrderResponseMessageFillsGroups ==
    [ blockLength                       |-> [i \in 1 .. 2 |-> 0],
      newOrderResponseMessageFillsGroup |-> << >> ]

(* New Order Response Message fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessageFillsGroups ==
    { ZeroNewOrderResponseMessageFillsGroups }
        \cup { [ZeroNewOrderResponseMessageFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponseMessageFillsGroups EXCEPT !.newOrderResponseMessageFillsGroup = one] : one \in SampleLists(OneNewOrderResponseMessageFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty2 ==
    { ZeroFillQty2 }
        \cup { [ZeroFillQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Response Message legs Group: 34 bytes                         *)
(***************************************************************************)

NewOrderResponseMessageLegsGroup ==
    [ matchId   : Sample(8),
      fillId    : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty2,
      legSide   : Sample(1) ]

EncodeNewOrderResponseMessageLegsGroup(message) ==
    message.matchId
        \o message.fillId
        \o message.fillPrice
        \o EncodeFillQty2(message.fillQty)
        \o message.legSide

DecodeNewOrderResponseMessageLegsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillId == ReadBytes(matchId.rest, 8) IN IF ~fillId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty2(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(fillQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillId    |-> fillId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value,
         legSide   |-> legSide.value ], legSide.rest)

ZeroNewOrderResponseMessageLegsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillId    |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty2,
      legSide   |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Response Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessageLegsGroup ==
    { ZeroNewOrderResponseMessageLegsGroup }
        \cup { [ZeroNewOrderResponseMessageLegsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessageLegsGroup EXCEPT !.fillId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessageLegsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessageLegsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty2 }
        \cup { [ZeroNewOrderResponseMessageLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of New Order Response Message legs Group, written one after another *)
RECURSIVE EncodeNewOrderResponseMessageLegsGroupList(_)
EncodeNewOrderResponseMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderResponseMessageLegsGroup(Head(messages)) \o EncodeNewOrderResponseMessageLegsGroupList(Tail(messages))

(* As many New Order Response Message legs Group as the field that counts them says *)
RECURSIVE ReadNewOrderResponseMessageLegsGroupList(_, _)
ReadNewOrderResponseMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderResponseMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderResponseMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Response Message legs Group of each kind, for the lists that carry them *)
OneNewOrderResponseMessageLegsGroup == { ZeroNewOrderResponseMessageLegsGroup }

(***************************************************************************)
(* New Order Response Message legs Groups                                  *)
(***************************************************************************)

NewOrderResponseMessageLegsGroups ==
    [ blockLength                      : Sample(2),
      newOrderResponseMessageLegsGroup : SampleLists(OneNewOrderResponseMessageLegsGroup) ]

EncodeNewOrderResponseMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.newOrderResponseMessageLegsGroup), 2)
        \o EncodeNewOrderResponseMessageLegsGroupList(message.newOrderResponseMessageLegsGroup)

DecodeNewOrderResponseMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderResponseMessageLegsGroup == ReadNewOrderResponseMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~newOrderResponseMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                      |-> blockLength.value,
         newOrderResponseMessageLegsGroup |-> newOrderResponseMessageLegsGroup.value ], newOrderResponseMessageLegsGroup.rest)

ZeroNewOrderResponseMessageLegsGroups ==
    [ blockLength                      |-> [i \in 1 .. 2 |-> 0],
      newOrderResponseMessageLegsGroup |-> << >> ]

(* New Order Response Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessageLegsGroups ==
    { ZeroNewOrderResponseMessageLegsGroups }
        \cup { [ZeroNewOrderResponseMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponseMessageLegsGroups EXCEPT !.newOrderResponseMessageLegsGroup = one] : one \in SampleLists(OneNewOrderResponseMessageLegsGroup) }

(***************************************************************************)
(* New Order Response Message                                              *)
(***************************************************************************)

NewOrderResponseMessage ==
    [ timestamp                          : Sample(8),
      execId                             : Sample(8),
      clientOrderId                      : Sample(8),
      correlationId                      : Sample(8),
      orderId                            : Sample(8),
      instrumentId                       : Sample(8),
      price                              : Sample(8),
      quantity                           : Quantity3,
      totalFilled                        : TotalFilled,
      visibleQty                         : VisibleQty,
      receiveTime                        : Sample(8),
      side                               : Sample(1),
      status                             : Sample(1),
      cancelReason                       : Sample(1),
      newOrderResponseMessageFillsGroups : NewOrderResponseMessageFillsGroups,
      newOrderResponseMessageLegsGroups  : NewOrderResponseMessageLegsGroups ]

EncodeNewOrderResponseMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.instrumentId
        \o message.price
        \o EncodeQuantity3(message.quantity)
        \o EncodeTotalFilled(message.totalFilled)
        \o EncodeVisibleQty(message.visibleQty)
        \o message.receiveTime
        \o message.side
        \o message.status
        \o message.cancelReason
        \o EncodeNewOrderResponseMessageFillsGroups(message.newOrderResponseMessageFillsGroups)
        \o EncodeNewOrderResponseMessageLegsGroups(message.newOrderResponseMessageLegsGroups)

DecodeNewOrderResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == DecodeQuantity3(price.rest) IN IF ~quantity.ok THEN Fail ELSE
    LET totalFilled == DecodeTotalFilled(quantity.rest) IN IF ~totalFilled.ok THEN Fail ELSE
    LET visibleQty == DecodeVisibleQty(totalFilled.rest) IN IF ~visibleQty.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(visibleQty.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    LET side == ReadBytes(receiveTime.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET status == ReadBytes(side.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(status.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET newOrderResponseMessageFillsGroups == DecodeNewOrderResponseMessageFillsGroups(cancelReason.rest) IN IF ~newOrderResponseMessageFillsGroups.ok THEN Fail ELSE
    LET newOrderResponseMessageLegsGroups == DecodeNewOrderResponseMessageLegsGroups(newOrderResponseMessageFillsGroups.rest) IN IF ~newOrderResponseMessageLegsGroups.ok THEN Fail ELSE
    Ok([ timestamp                          |-> timestamp.value,
         execId                             |-> execId.value,
         clientOrderId                      |-> clientOrderId.value,
         correlationId                      |-> correlationId.value,
         orderId                            |-> orderId.value,
         instrumentId                       |-> instrumentId.value,
         price                              |-> price.value,
         quantity                           |-> quantity.value,
         totalFilled                        |-> totalFilled.value,
         visibleQty                         |-> visibleQty.value,
         receiveTime                        |-> receiveTime.value,
         side                               |-> side.value,
         status                             |-> status.value,
         cancelReason                       |-> cancelReason.value,
         newOrderResponseMessageFillsGroups |-> newOrderResponseMessageFillsGroups.value,
         newOrderResponseMessageLegsGroups  |-> newOrderResponseMessageLegsGroups.value ], newOrderResponseMessageLegsGroups.rest)

ZeroNewOrderResponseMessage ==
    [ timestamp                          |-> [i \in 1 .. 8 |-> 0],
      execId                             |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                      |-> [i \in 1 .. 8 |-> 0],
      correlationId                      |-> [i \in 1 .. 8 |-> 0],
      orderId                            |-> [i \in 1 .. 8 |-> 0],
      instrumentId                       |-> [i \in 1 .. 8 |-> 0],
      price                              |-> [i \in 1 .. 8 |-> 0],
      quantity                           |-> ZeroQuantity3,
      totalFilled                        |-> ZeroTotalFilled,
      visibleQty                         |-> ZeroVisibleQty,
      receiveTime                        |-> [i \in 1 .. 8 |-> 0],
      side                               |-> [i \in 1 .. 1 |-> 0],
      status                             |-> [i \in 1 .. 1 |-> 0],
      cancelReason                       |-> [i \in 1 .. 1 |-> 0],
      newOrderResponseMessageFillsGroups |-> ZeroNewOrderResponseMessageFillsGroups,
      newOrderResponseMessageLegsGroups  |-> ZeroNewOrderResponseMessageLegsGroups ]

(* New Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessage ==
    { ZeroNewOrderResponseMessage }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.quantity = one] : one \in CheckedQuantity3 }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.totalFilled = one] : one \in CheckedTotalFilled }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.visibleQty = one] : one \in CheckedVisibleQty }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.newOrderResponseMessageFillsGroups = one] : one \in CheckedNewOrderResponseMessageFillsGroups }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.newOrderResponseMessageLegsGroups = one] : one \in CheckedNewOrderResponseMessageLegsGroups }

(***************************************************************************)
(* Details                                                                 *)
(***************************************************************************)

Details2 ==
    [ detailsData : SampleBytes ]

EncodeDetails2(message) ==
    EncodeUIntBE(Len(message.detailsData), 1)
        \o message.detailsData

DecodeDetails2(bytes) ==
    LET detailsLength == ReadUIntBE(bytes, 1) IN IF ~detailsLength.ok THEN Fail ELSE
    LET detailsData == ReadBytes(detailsLength.rest, detailsLength.value) IN IF ~detailsData.ok THEN Fail ELSE
    Ok([ detailsData |-> detailsData.value ], detailsData.rest)

ZeroDetails2 ==
    [ detailsData |-> << >> ]

(* Details at zero, then each field in turn at the values it is checked at *)
CheckedDetails2 ==
    { ZeroDetails2 }
        \cup { [ZeroDetails2 EXCEPT !.detailsData = one] : one \in SampleBytes }

(***************************************************************************)
(* New Order Reject Message                                                *)
(***************************************************************************)

NewOrderRejectMessage ==
    [ timestamp               : Sample(8),
      execId                  : Sample(8),
      clientOrderId           : Sample(8),
      correlationId           : Sample(8),
      orderId                 : Sample(8),
      instrumentId            : Sample(8),
      reasonOrderRejectReason : Sample(1),
      details                 : Details2 ]

EncodeNewOrderRejectMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.instrumentId
        \o message.reasonOrderRejectReason
        \o EncodeDetails2(message.details)

DecodeNewOrderRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reasonOrderRejectReason == ReadBytes(instrumentId.rest, 1) IN IF ~reasonOrderRejectReason.ok THEN Fail ELSE
    LET details == DecodeDetails2(reasonOrderRejectReason.rest) IN IF ~details.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         execId                  |-> execId.value,
         clientOrderId           |-> clientOrderId.value,
         correlationId           |-> correlationId.value,
         orderId                 |-> orderId.value,
         instrumentId            |-> instrumentId.value,
         reasonOrderRejectReason |-> reasonOrderRejectReason.value,
         details                 |-> details.value ], details.rest)

ZeroNewOrderRejectMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      execId                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId           |-> [i \in 1 .. 8 |-> 0],
      correlationId           |-> [i \in 1 .. 8 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 8 |-> 0],
      reasonOrderRejectReason |-> [i \in 1 .. 1 |-> 0],
      details                 |-> ZeroDetails2 ]

(* New Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRejectMessage ==
    { ZeroNewOrderRejectMessage }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.reasonOrderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRejectMessage EXCEPT !.details = one] : one \in CheckedDetails2 }

(***************************************************************************)
(* Quantity: 9 bytes                                                       *)
(***************************************************************************)

Quantity4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeQuantity4(message) ==
    message.mantissa
        \o message.exponent

DecodeQuantity4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroQuantity4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuantity4 ==
    { ZeroQuantity4 }
        \cup { [ZeroQuantity4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroQuantity4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Total Filled: 9 bytes                                                   *)
(***************************************************************************)

TotalFilled2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeTotalFilled2(message) ==
    message.mantissa
        \o message.exponent

DecodeTotalFilled2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroTotalFilled2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Total Filled at zero, then each field in turn at the values it is checked at *)
CheckedTotalFilled2 ==
    { ZeroTotalFilled2 }
        \cup { [ZeroTotalFilled2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroTotalFilled2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Visible Qty: 9 bytes                                                    *)
(***************************************************************************)

VisibleQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeVisibleQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeVisibleQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroVisibleQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Visible Qty at zero, then each field in turn at the values it is checked at *)
CheckedVisibleQty2 ==
    { ZeroVisibleQty2 }
        \cup { [ZeroVisibleQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroVisibleQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty3(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty3 ==
    { ZeroFillQty3 }
        \cup { [ZeroFillQty3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Amend Order Response Message fills Group: 25 bytes                      *)
(***************************************************************************)

AmendOrderResponseMessageFillsGroup ==
    [ matchId   : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty3 ]

EncodeAmendOrderResponseMessageFillsGroup(message) ==
    message.matchId
        \o message.fillPrice
        \o EncodeFillQty3(message.fillQty)

DecodeAmendOrderResponseMessageFillsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(matchId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty3(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value ], fillQty.rest)

ZeroAmendOrderResponseMessageFillsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty3 ]

(* Amend Order Response Message fills Group at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderResponseMessageFillsGroup ==
    { ZeroAmendOrderResponseMessageFillsGroup }
        \cup { [ZeroAmendOrderResponseMessageFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessageFillsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessageFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty3 }

(* A run of Amend Order Response Message fills Group, written one after another *)
RECURSIVE EncodeAmendOrderResponseMessageFillsGroupList(_)
EncodeAmendOrderResponseMessageFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAmendOrderResponseMessageFillsGroup(Head(messages)) \o EncodeAmendOrderResponseMessageFillsGroupList(Tail(messages))

(* As many Amend Order Response Message fills Group as the field that counts them says *)
RECURSIVE ReadAmendOrderResponseMessageFillsGroupList(_, _)
ReadAmendOrderResponseMessageFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAmendOrderResponseMessageFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAmendOrderResponseMessageFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Amend Order Response Message fills Group of each kind, for the lists that carry them *)
OneAmendOrderResponseMessageFillsGroup == { ZeroAmendOrderResponseMessageFillsGroup }

(***************************************************************************)
(* Amend Order Response Message fills Groups                               *)
(***************************************************************************)

AmendOrderResponseMessageFillsGroups ==
    [ blockLength                         : Sample(2),
      amendOrderResponseMessageFillsGroup : SampleLists(OneAmendOrderResponseMessageFillsGroup) ]

EncodeAmendOrderResponseMessageFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.amendOrderResponseMessageFillsGroup), 2)
        \o EncodeAmendOrderResponseMessageFillsGroupList(message.amendOrderResponseMessageFillsGroup)

DecodeAmendOrderResponseMessageFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET amendOrderResponseMessageFillsGroup == ReadAmendOrderResponseMessageFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~amendOrderResponseMessageFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         amendOrderResponseMessageFillsGroup |-> amendOrderResponseMessageFillsGroup.value ], amendOrderResponseMessageFillsGroup.rest)

ZeroAmendOrderResponseMessageFillsGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      amendOrderResponseMessageFillsGroup |-> << >> ]

(* Amend Order Response Message fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderResponseMessageFillsGroups ==
    { ZeroAmendOrderResponseMessageFillsGroups }
        \cup { [ZeroAmendOrderResponseMessageFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroAmendOrderResponseMessageFillsGroups EXCEPT !.amendOrderResponseMessageFillsGroup = one] : one \in SampleLists(OneAmendOrderResponseMessageFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty4(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty4 ==
    { ZeroFillQty4 }
        \cup { [ZeroFillQty4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Amend Order Response Message legs Group: 34 bytes                       *)
(***************************************************************************)

AmendOrderResponseMessageLegsGroup ==
    [ matchId   : Sample(8),
      fillId    : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty4,
      legSide   : Sample(1) ]

EncodeAmendOrderResponseMessageLegsGroup(message) ==
    message.matchId
        \o message.fillId
        \o message.fillPrice
        \o EncodeFillQty4(message.fillQty)
        \o message.legSide

DecodeAmendOrderResponseMessageLegsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillId == ReadBytes(matchId.rest, 8) IN IF ~fillId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty4(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(fillQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillId    |-> fillId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value,
         legSide   |-> legSide.value ], legSide.rest)

ZeroAmendOrderResponseMessageLegsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillId    |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty4,
      legSide   |-> [i \in 1 .. 1 |-> 0] ]

(* Amend Order Response Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderResponseMessageLegsGroup ==
    { ZeroAmendOrderResponseMessageLegsGroup }
        \cup { [ZeroAmendOrderResponseMessageLegsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessageLegsGroup EXCEPT !.fillId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessageLegsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessageLegsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty4 }
        \cup { [ZeroAmendOrderResponseMessageLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Amend Order Response Message legs Group, written one after another *)
RECURSIVE EncodeAmendOrderResponseMessageLegsGroupList(_)
EncodeAmendOrderResponseMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAmendOrderResponseMessageLegsGroup(Head(messages)) \o EncodeAmendOrderResponseMessageLegsGroupList(Tail(messages))

(* As many Amend Order Response Message legs Group as the field that counts them says *)
RECURSIVE ReadAmendOrderResponseMessageLegsGroupList(_, _)
ReadAmendOrderResponseMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAmendOrderResponseMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAmendOrderResponseMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Amend Order Response Message legs Group of each kind, for the lists that carry them *)
OneAmendOrderResponseMessageLegsGroup == { ZeroAmendOrderResponseMessageLegsGroup }

(***************************************************************************)
(* Amend Order Response Message legs Groups                                *)
(***************************************************************************)

AmendOrderResponseMessageLegsGroups ==
    [ blockLength                        : Sample(2),
      amendOrderResponseMessageLegsGroup : SampleLists(OneAmendOrderResponseMessageLegsGroup) ]

EncodeAmendOrderResponseMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.amendOrderResponseMessageLegsGroup), 2)
        \o EncodeAmendOrderResponseMessageLegsGroupList(message.amendOrderResponseMessageLegsGroup)

DecodeAmendOrderResponseMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET amendOrderResponseMessageLegsGroup == ReadAmendOrderResponseMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~amendOrderResponseMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                        |-> blockLength.value,
         amendOrderResponseMessageLegsGroup |-> amendOrderResponseMessageLegsGroup.value ], amendOrderResponseMessageLegsGroup.rest)

ZeroAmendOrderResponseMessageLegsGroups ==
    [ blockLength                        |-> [i \in 1 .. 2 |-> 0],
      amendOrderResponseMessageLegsGroup |-> << >> ]

(* Amend Order Response Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderResponseMessageLegsGroups ==
    { ZeroAmendOrderResponseMessageLegsGroups }
        \cup { [ZeroAmendOrderResponseMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroAmendOrderResponseMessageLegsGroups EXCEPT !.amendOrderResponseMessageLegsGroup = one] : one \in SampleLists(OneAmendOrderResponseMessageLegsGroup) }

(***************************************************************************)
(* Amend Order Response Message                                            *)
(***************************************************************************)

AmendOrderResponseMessage ==
    [ timestamp                            : Sample(8),
      execId                               : Sample(8),
      clientOrderId                        : Sample(8),
      correlationId                        : Sample(8),
      orderId                              : Sample(8),
      instrumentId                         : Sample(8),
      price                                : Sample(8),
      quantity                             : Quantity4,
      totalFilled                          : TotalFilled2,
      visibleQty                           : VisibleQty2,
      receiveTime                          : Sample(8),
      status                               : Sample(1),
      cancelReason                         : Sample(1),
      amendOrderResponseMessageFillsGroups : AmendOrderResponseMessageFillsGroups,
      amendOrderResponseMessageLegsGroups  : AmendOrderResponseMessageLegsGroups ]

EncodeAmendOrderResponseMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.instrumentId
        \o message.price
        \o EncodeQuantity4(message.quantity)
        \o EncodeTotalFilled2(message.totalFilled)
        \o EncodeVisibleQty2(message.visibleQty)
        \o message.receiveTime
        \o message.status
        \o message.cancelReason
        \o EncodeAmendOrderResponseMessageFillsGroups(message.amendOrderResponseMessageFillsGroups)
        \o EncodeAmendOrderResponseMessageLegsGroups(message.amendOrderResponseMessageLegsGroups)

DecodeAmendOrderResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == DecodeQuantity4(price.rest) IN IF ~quantity.ok THEN Fail ELSE
    LET totalFilled == DecodeTotalFilled2(quantity.rest) IN IF ~totalFilled.ok THEN Fail ELSE
    LET visibleQty == DecodeVisibleQty2(totalFilled.rest) IN IF ~visibleQty.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(visibleQty.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    LET status == ReadBytes(receiveTime.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(status.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET amendOrderResponseMessageFillsGroups == DecodeAmendOrderResponseMessageFillsGroups(cancelReason.rest) IN IF ~amendOrderResponseMessageFillsGroups.ok THEN Fail ELSE
    LET amendOrderResponseMessageLegsGroups == DecodeAmendOrderResponseMessageLegsGroups(amendOrderResponseMessageFillsGroups.rest) IN IF ~amendOrderResponseMessageLegsGroups.ok THEN Fail ELSE
    Ok([ timestamp                            |-> timestamp.value,
         execId                               |-> execId.value,
         clientOrderId                        |-> clientOrderId.value,
         correlationId                        |-> correlationId.value,
         orderId                              |-> orderId.value,
         instrumentId                         |-> instrumentId.value,
         price                                |-> price.value,
         quantity                             |-> quantity.value,
         totalFilled                          |-> totalFilled.value,
         visibleQty                           |-> visibleQty.value,
         receiveTime                          |-> receiveTime.value,
         status                               |-> status.value,
         cancelReason                         |-> cancelReason.value,
         amendOrderResponseMessageFillsGroups |-> amendOrderResponseMessageFillsGroups.value,
         amendOrderResponseMessageLegsGroups  |-> amendOrderResponseMessageLegsGroups.value ], amendOrderResponseMessageLegsGroups.rest)

ZeroAmendOrderResponseMessage ==
    [ timestamp                            |-> [i \in 1 .. 8 |-> 0],
      execId                               |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                        |-> [i \in 1 .. 8 |-> 0],
      correlationId                        |-> [i \in 1 .. 8 |-> 0],
      orderId                              |-> [i \in 1 .. 8 |-> 0],
      instrumentId                         |-> [i \in 1 .. 8 |-> 0],
      price                                |-> [i \in 1 .. 8 |-> 0],
      quantity                             |-> ZeroQuantity4,
      totalFilled                          |-> ZeroTotalFilled2,
      visibleQty                           |-> ZeroVisibleQty2,
      receiveTime                          |-> [i \in 1 .. 8 |-> 0],
      status                               |-> [i \in 1 .. 1 |-> 0],
      cancelReason                         |-> [i \in 1 .. 1 |-> 0],
      amendOrderResponseMessageFillsGroups |-> ZeroAmendOrderResponseMessageFillsGroups,
      amendOrderResponseMessageLegsGroups  |-> ZeroAmendOrderResponseMessageLegsGroups ]

(* Amend Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderResponseMessage ==
    { ZeroAmendOrderResponseMessage }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.quantity = one] : one \in CheckedQuantity4 }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.totalFilled = one] : one \in CheckedTotalFilled2 }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.visibleQty = one] : one \in CheckedVisibleQty2 }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.amendOrderResponseMessageFillsGroups = one] : one \in CheckedAmendOrderResponseMessageFillsGroups }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.amendOrderResponseMessageLegsGroups = one] : one \in CheckedAmendOrderResponseMessageLegsGroups }

(***************************************************************************)
(* Details                                                                 *)
(***************************************************************************)

Details3 ==
    [ detailsData : SampleBytes ]

EncodeDetails3(message) ==
    EncodeUIntBE(Len(message.detailsData), 1)
        \o message.detailsData

DecodeDetails3(bytes) ==
    LET detailsLength == ReadUIntBE(bytes, 1) IN IF ~detailsLength.ok THEN Fail ELSE
    LET detailsData == ReadBytes(detailsLength.rest, detailsLength.value) IN IF ~detailsData.ok THEN Fail ELSE
    Ok([ detailsData |-> detailsData.value ], detailsData.rest)

ZeroDetails3 ==
    [ detailsData |-> << >> ]

(* Details at zero, then each field in turn at the values it is checked at *)
CheckedDetails3 ==
    { ZeroDetails3 }
        \cup { [ZeroDetails3 EXCEPT !.detailsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Amend Order Reject Message                                              *)
(***************************************************************************)

AmendOrderRejectMessage ==
    [ timestamp               : Sample(8),
      execId                  : Sample(8),
      clientOrderId           : Sample(8),
      correlationId           : Sample(8),
      orderId                 : Sample(8),
      instrumentId            : Sample(8),
      reasonOrderRejectReason : Sample(1),
      details                 : Details3 ]

EncodeAmendOrderRejectMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.instrumentId
        \o message.reasonOrderRejectReason
        \o EncodeDetails3(message.details)

DecodeAmendOrderRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reasonOrderRejectReason == ReadBytes(instrumentId.rest, 1) IN IF ~reasonOrderRejectReason.ok THEN Fail ELSE
    LET details == DecodeDetails3(reasonOrderRejectReason.rest) IN IF ~details.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         execId                  |-> execId.value,
         clientOrderId           |-> clientOrderId.value,
         correlationId           |-> correlationId.value,
         orderId                 |-> orderId.value,
         instrumentId            |-> instrumentId.value,
         reasonOrderRejectReason |-> reasonOrderRejectReason.value,
         details                 |-> details.value ], details.rest)

ZeroAmendOrderRejectMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      execId                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId           |-> [i \in 1 .. 8 |-> 0],
      correlationId           |-> [i \in 1 .. 8 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 8 |-> 0],
      reasonOrderRejectReason |-> [i \in 1 .. 1 |-> 0],
      details                 |-> ZeroDetails3 ]

(* Amend Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderRejectMessage ==
    { ZeroAmendOrderRejectMessage }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.reasonOrderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrderRejectMessage EXCEPT !.details = one] : one \in CheckedDetails3 }

(***************************************************************************)
(* Cancel Order Response Message: 56 bytes                                 *)
(***************************************************************************)

CancelOrderResponseMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      clientOrderId : Sample(8),
      correlationId : Sample(8),
      orderId       : Sample(8),
      instrumentId  : Sample(8),
      receiveTime   : Sample(8) ]

EncodeCancelOrderResponseMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.instrumentId
        \o message.receiveTime

DecodeCancelOrderResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(instrumentId.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         orderId       |-> orderId.value,
         instrumentId  |-> instrumentId.value,
         receiveTime   |-> receiveTime.value ], receiveTime.rest)

ZeroCancelOrderResponseMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 8 |-> 0],
      receiveTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderResponseMessage ==
    { ZeroCancelOrderResponseMessage }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Details                                                                 *)
(***************************************************************************)

Details4 ==
    [ detailsData : SampleBytes ]

EncodeDetails4(message) ==
    EncodeUIntBE(Len(message.detailsData), 1)
        \o message.detailsData

DecodeDetails4(bytes) ==
    LET detailsLength == ReadUIntBE(bytes, 1) IN IF ~detailsLength.ok THEN Fail ELSE
    LET detailsData == ReadBytes(detailsLength.rest, detailsLength.value) IN IF ~detailsData.ok THEN Fail ELSE
    Ok([ detailsData |-> detailsData.value ], detailsData.rest)

ZeroDetails4 ==
    [ detailsData |-> << >> ]

(* Details at zero, then each field in turn at the values it is checked at *)
CheckedDetails4 ==
    { ZeroDetails4 }
        \cup { [ZeroDetails4 EXCEPT !.detailsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Cancel Order Reject Message                                             *)
(***************************************************************************)

CancelOrderRejectMessage ==
    [ timestamp                     : Sample(8),
      execId                        : Sample(8),
      clientOrderId                 : Sample(8),
      correlationId                 : Sample(8),
      orderIdOptional               : Sample(8),
      instrumentId                  : Sample(8),
      reasonCancelOrderRejectReason : Sample(1),
      details                       : Details4 ]

EncodeCancelOrderRejectMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderIdOptional
        \o message.instrumentId
        \o message.reasonCancelOrderRejectReason
        \o EncodeDetails4(message.details)

DecodeCancelOrderRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(correlationId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderIdOptional.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reasonCancelOrderRejectReason == ReadBytes(instrumentId.rest, 1) IN IF ~reasonCancelOrderRejectReason.ok THEN Fail ELSE
    LET details == DecodeDetails4(reasonCancelOrderRejectReason.rest) IN IF ~details.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         execId                        |-> execId.value,
         clientOrderId                 |-> clientOrderId.value,
         correlationId                 |-> correlationId.value,
         orderIdOptional               |-> orderIdOptional.value,
         instrumentId                  |-> instrumentId.value,
         reasonCancelOrderRejectReason |-> reasonCancelOrderRejectReason.value,
         details                       |-> details.value ], details.rest)

ZeroCancelOrderRejectMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      execId                        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      correlationId                 |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional               |-> [i \in 1 .. 8 |-> 0],
      instrumentId                  |-> [i \in 1 .. 8 |-> 0],
      reasonCancelOrderRejectReason |-> [i \in 1 .. 1 |-> 0],
      details                       |-> ZeroDetails4 ]

(* Cancel Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRejectMessage ==
    { ZeroCancelOrderRejectMessage }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.reasonCancelOrderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.details = one] : one \in CheckedDetails4 }

(***************************************************************************)
(* Bid Qty: 9 bytes                                                        *)
(***************************************************************************)

BidQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeBidQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeBidQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroBidQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Bid Qty at zero, then each field in turn at the values it is checked at *)
CheckedBidQty2 ==
    { ZeroBidQty2 }
        \cup { [ZeroBidQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroBidQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Qty: 9 bytes                                                        *)
(***************************************************************************)

AskQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeAskQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeAskQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroAskQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Ask Qty at zero, then each field in turn at the values it is checked at *)
CheckedAskQty2 ==
    { ZeroAskQty2 }
        \cup { [ZeroAskQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroAskQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Filled Qty: 9 bytes                                                 *)
(***************************************************************************)

BidFilledQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeBidFilledQty(message) ==
    message.mantissa
        \o message.exponent

DecodeBidFilledQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroBidFilledQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Bid Filled Qty at zero, then each field in turn at the values it is checked at *)
CheckedBidFilledQty ==
    { ZeroBidFilledQty }
        \cup { [ZeroBidFilledQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroBidFilledQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Filled Qty: 9 bytes                                                 *)
(***************************************************************************)

AskFilledQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeAskFilledQty(message) ==
    message.mantissa
        \o message.exponent

DecodeAskFilledQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroAskFilledQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Ask Filled Qty at zero, then each field in turn at the values it is checked at *)
CheckedAskFilledQty ==
    { ZeroAskFilledQty }
        \cup { [ZeroAskFilledQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroAskFilledQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Response Message quotes Group: 80 bytes                      *)
(***************************************************************************)

MassQuoteResponseMessageQuotesGroup ==
    [ instrumentId    : Sample(8),
      bidOrderId      : Sample(8),
      askOrderId      : Sample(8),
      bidPrice        : Sample(8),
      askPrice        : Sample(8),
      bidQty          : BidQty2,
      askQty          : AskQty2,
      bidFilledQty    : BidFilledQty,
      askFilledQty    : AskFilledQty,
      bidStatus       : Sample(1),
      askStatus       : Sample(1),
      bidRejectReason : Sample(1),
      askRejectReason : Sample(1) ]

EncodeMassQuoteResponseMessageQuotesGroup(message) ==
    message.instrumentId
        \o message.bidOrderId
        \o message.askOrderId
        \o message.bidPrice
        \o message.askPrice
        \o EncodeBidQty2(message.bidQty)
        \o EncodeAskQty2(message.askQty)
        \o EncodeBidFilledQty(message.bidFilledQty)
        \o EncodeAskFilledQty(message.askFilledQty)
        \o message.bidStatus
        \o message.askStatus
        \o message.bidRejectReason
        \o message.askRejectReason

DecodeMassQuoteResponseMessageQuotesGroup(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~bidOrderId.ok THEN Fail ELSE
    LET askOrderId == ReadBytes(bidOrderId.rest, 8) IN IF ~askOrderId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askOrderId.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidPrice.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET bidQty == DecodeBidQty2(askPrice.rest) IN IF ~bidQty.ok THEN Fail ELSE
    LET askQty == DecodeAskQty2(bidQty.rest) IN IF ~askQty.ok THEN Fail ELSE
    LET bidFilledQty == DecodeBidFilledQty(askQty.rest) IN IF ~bidFilledQty.ok THEN Fail ELSE
    LET askFilledQty == DecodeAskFilledQty(bidFilledQty.rest) IN IF ~askFilledQty.ok THEN Fail ELSE
    LET bidStatus == ReadBytes(askFilledQty.rest, 1) IN IF ~bidStatus.ok THEN Fail ELSE
    LET askStatus == ReadBytes(bidStatus.rest, 1) IN IF ~askStatus.ok THEN Fail ELSE
    LET bidRejectReason == ReadBytes(askStatus.rest, 1) IN IF ~bidRejectReason.ok THEN Fail ELSE
    LET askRejectReason == ReadBytes(bidRejectReason.rest, 1) IN IF ~askRejectReason.ok THEN Fail ELSE
    Ok([ instrumentId    |-> instrumentId.value,
         bidOrderId      |-> bidOrderId.value,
         askOrderId      |-> askOrderId.value,
         bidPrice        |-> bidPrice.value,
         askPrice        |-> askPrice.value,
         bidQty          |-> bidQty.value,
         askQty          |-> askQty.value,
         bidFilledQty    |-> bidFilledQty.value,
         askFilledQty    |-> askFilledQty.value,
         bidStatus       |-> bidStatus.value,
         askStatus       |-> askStatus.value,
         bidRejectReason |-> bidRejectReason.value,
         askRejectReason |-> askRejectReason.value ], askRejectReason.rest)

ZeroMassQuoteResponseMessageQuotesGroup ==
    [ instrumentId    |-> [i \in 1 .. 8 |-> 0],
      bidOrderId      |-> [i \in 1 .. 8 |-> 0],
      askOrderId      |-> [i \in 1 .. 8 |-> 0],
      bidPrice        |-> [i \in 1 .. 8 |-> 0],
      askPrice        |-> [i \in 1 .. 8 |-> 0],
      bidQty          |-> ZeroBidQty2,
      askQty          |-> ZeroAskQty2,
      bidFilledQty    |-> ZeroBidFilledQty,
      askFilledQty    |-> ZeroAskFilledQty,
      bidStatus       |-> [i \in 1 .. 1 |-> 0],
      askStatus       |-> [i \in 1 .. 1 |-> 0],
      bidRejectReason |-> [i \in 1 .. 1 |-> 0],
      askRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Response Message quotes Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageQuotesGroup ==
    { ZeroMassQuoteResponseMessageQuotesGroup }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.bidOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.askOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.bidQty = one] : one \in CheckedBidQty2 }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.askQty = one] : one \in CheckedAskQty2 }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.bidFilledQty = one] : one \in CheckedBidFilledQty }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.askFilledQty = one] : one \in CheckedAskFilledQty }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.bidStatus = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.askStatus = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.bidRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroup EXCEPT !.askRejectReason = one] : one \in Sample(1) }

(* A run of Mass Quote Response Message quotes Group, written one after another *)
RECURSIVE EncodeMassQuoteResponseMessageQuotesGroupList(_)
EncodeMassQuoteResponseMessageQuotesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteResponseMessageQuotesGroup(Head(messages)) \o EncodeMassQuoteResponseMessageQuotesGroupList(Tail(messages))

(* As many Mass Quote Response Message quotes Group as the field that counts them says *)
RECURSIVE ReadMassQuoteResponseMessageQuotesGroupList(_, _)
ReadMassQuoteResponseMessageQuotesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteResponseMessageQuotesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteResponseMessageQuotesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Response Message quotes Group of each kind, for the lists that carry them *)
OneMassQuoteResponseMessageQuotesGroup == { ZeroMassQuoteResponseMessageQuotesGroup }

(***************************************************************************)
(* Mass Quote Response Message quotes Groups                               *)
(***************************************************************************)

MassQuoteResponseMessageQuotesGroups ==
    [ blockLength                         : Sample(2),
      massQuoteResponseMessageQuotesGroup : SampleLists(OneMassQuoteResponseMessageQuotesGroup) ]

EncodeMassQuoteResponseMessageQuotesGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteResponseMessageQuotesGroup), 2)
        \o EncodeMassQuoteResponseMessageQuotesGroupList(message.massQuoteResponseMessageQuotesGroup)

DecodeMassQuoteResponseMessageQuotesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteResponseMessageQuotesGroup == ReadMassQuoteResponseMessageQuotesGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteResponseMessageQuotesGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         massQuoteResponseMessageQuotesGroup |-> massQuoteResponseMessageQuotesGroup.value ], massQuoteResponseMessageQuotesGroup.rest)

ZeroMassQuoteResponseMessageQuotesGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      massQuoteResponseMessageQuotesGroup |-> << >> ]

(* Mass Quote Response Message quotes Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageQuotesGroups ==
    { ZeroMassQuoteResponseMessageQuotesGroups }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponseMessageQuotesGroups EXCEPT !.massQuoteResponseMessageQuotesGroup = one] : one \in SampleLists(OneMassQuoteResponseMessageQuotesGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty5 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty5(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty5(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty5 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty5 ==
    { ZeroFillQty5 }
        \cup { [ZeroFillQty5 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty5 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Response Message bid Fills Group: 33 bytes                   *)
(***************************************************************************)

MassQuoteResponseMessageBidFillsGroup ==
    [ matchId      : Sample(8),
      instrumentId : Sample(8),
      fillPrice    : Sample(8),
      fillQty      : FillQty5 ]

EncodeMassQuoteResponseMessageBidFillsGroup(message) ==
    message.matchId
        \o message.instrumentId
        \o message.fillPrice
        \o EncodeFillQty5(message.fillQty)

DecodeMassQuoteResponseMessageBidFillsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(matchId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(instrumentId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty5(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    Ok([ matchId      |-> matchId.value,
         instrumentId |-> instrumentId.value,
         fillPrice    |-> fillPrice.value,
         fillQty      |-> fillQty.value ], fillQty.rest)

ZeroMassQuoteResponseMessageBidFillsGroup ==
    [ matchId      |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 8 |-> 0],
      fillPrice    |-> [i \in 1 .. 8 |-> 0],
      fillQty      |-> ZeroFillQty5 ]

(* Mass Quote Response Message bid Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageBidFillsGroup ==
    { ZeroMassQuoteResponseMessageBidFillsGroup }
        \cup { [ZeroMassQuoteResponseMessageBidFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageBidFillsGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageBidFillsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageBidFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty5 }

(* A run of Mass Quote Response Message bid Fills Group, written one after another *)
RECURSIVE EncodeMassQuoteResponseMessageBidFillsGroupList(_)
EncodeMassQuoteResponseMessageBidFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteResponseMessageBidFillsGroup(Head(messages)) \o EncodeMassQuoteResponseMessageBidFillsGroupList(Tail(messages))

(* As many Mass Quote Response Message bid Fills Group as the field that counts them says *)
RECURSIVE ReadMassQuoteResponseMessageBidFillsGroupList(_, _)
ReadMassQuoteResponseMessageBidFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteResponseMessageBidFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteResponseMessageBidFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Response Message bid Fills Group of each kind, for the lists that carry them *)
OneMassQuoteResponseMessageBidFillsGroup == { ZeroMassQuoteResponseMessageBidFillsGroup }

(***************************************************************************)
(* Mass Quote Response Message bid Fills Groups                            *)
(***************************************************************************)

MassQuoteResponseMessageBidFillsGroups ==
    [ blockLength                           : Sample(2),
      massQuoteResponseMessageBidFillsGroup : SampleLists(OneMassQuoteResponseMessageBidFillsGroup) ]

EncodeMassQuoteResponseMessageBidFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteResponseMessageBidFillsGroup), 2)
        \o EncodeMassQuoteResponseMessageBidFillsGroupList(message.massQuoteResponseMessageBidFillsGroup)

DecodeMassQuoteResponseMessageBidFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteResponseMessageBidFillsGroup == ReadMassQuoteResponseMessageBidFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteResponseMessageBidFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                           |-> blockLength.value,
         massQuoteResponseMessageBidFillsGroup |-> massQuoteResponseMessageBidFillsGroup.value ], massQuoteResponseMessageBidFillsGroup.rest)

ZeroMassQuoteResponseMessageBidFillsGroups ==
    [ blockLength                           |-> [i \in 1 .. 2 |-> 0],
      massQuoteResponseMessageBidFillsGroup |-> << >> ]

(* Mass Quote Response Message bid Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageBidFillsGroups ==
    { ZeroMassQuoteResponseMessageBidFillsGroups }
        \cup { [ZeroMassQuoteResponseMessageBidFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponseMessageBidFillsGroups EXCEPT !.massQuoteResponseMessageBidFillsGroup = one] : one \in SampleLists(OneMassQuoteResponseMessageBidFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty6 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty6(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty6(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty6 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty6 ==
    { ZeroFillQty6 }
        \cup { [ZeroFillQty6 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty6 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Response Message ask Fills Group: 33 bytes                   *)
(***************************************************************************)

MassQuoteResponseMessageAskFillsGroup ==
    [ matchId      : Sample(8),
      instrumentId : Sample(8),
      fillPrice    : Sample(8),
      fillQty      : FillQty6 ]

EncodeMassQuoteResponseMessageAskFillsGroup(message) ==
    message.matchId
        \o message.instrumentId
        \o message.fillPrice
        \o EncodeFillQty6(message.fillQty)

DecodeMassQuoteResponseMessageAskFillsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(matchId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(instrumentId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty6(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    Ok([ matchId      |-> matchId.value,
         instrumentId |-> instrumentId.value,
         fillPrice    |-> fillPrice.value,
         fillQty      |-> fillQty.value ], fillQty.rest)

ZeroMassQuoteResponseMessageAskFillsGroup ==
    [ matchId      |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 8 |-> 0],
      fillPrice    |-> [i \in 1 .. 8 |-> 0],
      fillQty      |-> ZeroFillQty6 ]

(* Mass Quote Response Message ask Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageAskFillsGroup ==
    { ZeroMassQuoteResponseMessageAskFillsGroup }
        \cup { [ZeroMassQuoteResponseMessageAskFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageAskFillsGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageAskFillsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageAskFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty6 }

(* A run of Mass Quote Response Message ask Fills Group, written one after another *)
RECURSIVE EncodeMassQuoteResponseMessageAskFillsGroupList(_)
EncodeMassQuoteResponseMessageAskFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteResponseMessageAskFillsGroup(Head(messages)) \o EncodeMassQuoteResponseMessageAskFillsGroupList(Tail(messages))

(* As many Mass Quote Response Message ask Fills Group as the field that counts them says *)
RECURSIVE ReadMassQuoteResponseMessageAskFillsGroupList(_, _)
ReadMassQuoteResponseMessageAskFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteResponseMessageAskFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteResponseMessageAskFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Response Message ask Fills Group of each kind, for the lists that carry them *)
OneMassQuoteResponseMessageAskFillsGroup == { ZeroMassQuoteResponseMessageAskFillsGroup }

(***************************************************************************)
(* Mass Quote Response Message ask Fills Groups                            *)
(***************************************************************************)

MassQuoteResponseMessageAskFillsGroups ==
    [ blockLength                           : Sample(2),
      massQuoteResponseMessageAskFillsGroup : SampleLists(OneMassQuoteResponseMessageAskFillsGroup) ]

EncodeMassQuoteResponseMessageAskFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteResponseMessageAskFillsGroup), 2)
        \o EncodeMassQuoteResponseMessageAskFillsGroupList(message.massQuoteResponseMessageAskFillsGroup)

DecodeMassQuoteResponseMessageAskFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteResponseMessageAskFillsGroup == ReadMassQuoteResponseMessageAskFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteResponseMessageAskFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                           |-> blockLength.value,
         massQuoteResponseMessageAskFillsGroup |-> massQuoteResponseMessageAskFillsGroup.value ], massQuoteResponseMessageAskFillsGroup.rest)

ZeroMassQuoteResponseMessageAskFillsGroups ==
    [ blockLength                           |-> [i \in 1 .. 2 |-> 0],
      massQuoteResponseMessageAskFillsGroup |-> << >> ]

(* Mass Quote Response Message ask Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageAskFillsGroups ==
    { ZeroMassQuoteResponseMessageAskFillsGroups }
        \cup { [ZeroMassQuoteResponseMessageAskFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponseMessageAskFillsGroups EXCEPT !.massQuoteResponseMessageAskFillsGroup = one] : one \in SampleLists(OneMassQuoteResponseMessageAskFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty7 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty7(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty7(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty7 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty7 ==
    { ZeroFillQty7 }
        \cup { [ZeroFillQty7 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty7 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Response Message legs Group: 34 bytes                        *)
(***************************************************************************)

MassQuoteResponseMessageLegsGroup ==
    [ matchId   : Sample(8),
      fillId    : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty7,
      legSide   : Sample(1) ]

EncodeMassQuoteResponseMessageLegsGroup(message) ==
    message.matchId
        \o message.fillId
        \o message.fillPrice
        \o EncodeFillQty7(message.fillQty)
        \o message.legSide

DecodeMassQuoteResponseMessageLegsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillId == ReadBytes(matchId.rest, 8) IN IF ~fillId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty7(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(fillQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillId    |-> fillId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value,
         legSide   |-> legSide.value ], legSide.rest)

ZeroMassQuoteResponseMessageLegsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillId    |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty7,
      legSide   |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Response Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageLegsGroup ==
    { ZeroMassQuoteResponseMessageLegsGroup }
        \cup { [ZeroMassQuoteResponseMessageLegsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageLegsGroup EXCEPT !.fillId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageLegsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessageLegsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty7 }
        \cup { [ZeroMassQuoteResponseMessageLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Mass Quote Response Message legs Group, written one after another *)
RECURSIVE EncodeMassQuoteResponseMessageLegsGroupList(_)
EncodeMassQuoteResponseMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteResponseMessageLegsGroup(Head(messages)) \o EncodeMassQuoteResponseMessageLegsGroupList(Tail(messages))

(* As many Mass Quote Response Message legs Group as the field that counts them says *)
RECURSIVE ReadMassQuoteResponseMessageLegsGroupList(_, _)
ReadMassQuoteResponseMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteResponseMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteResponseMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Response Message legs Group of each kind, for the lists that carry them *)
OneMassQuoteResponseMessageLegsGroup == { ZeroMassQuoteResponseMessageLegsGroup }

(***************************************************************************)
(* Mass Quote Response Message legs Groups                                 *)
(***************************************************************************)

MassQuoteResponseMessageLegsGroups ==
    [ blockLength                       : Sample(2),
      massQuoteResponseMessageLegsGroup : SampleLists(OneMassQuoteResponseMessageLegsGroup) ]

EncodeMassQuoteResponseMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteResponseMessageLegsGroup), 2)
        \o EncodeMassQuoteResponseMessageLegsGroupList(message.massQuoteResponseMessageLegsGroup)

DecodeMassQuoteResponseMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteResponseMessageLegsGroup == ReadMassQuoteResponseMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteResponseMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                       |-> blockLength.value,
         massQuoteResponseMessageLegsGroup |-> massQuoteResponseMessageLegsGroup.value ], massQuoteResponseMessageLegsGroup.rest)

ZeroMassQuoteResponseMessageLegsGroups ==
    [ blockLength                       |-> [i \in 1 .. 2 |-> 0],
      massQuoteResponseMessageLegsGroup |-> << >> ]

(* Mass Quote Response Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessageLegsGroups ==
    { ZeroMassQuoteResponseMessageLegsGroups }
        \cup { [ZeroMassQuoteResponseMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponseMessageLegsGroups EXCEPT !.massQuoteResponseMessageLegsGroup = one] : one \in SampleLists(OneMassQuoteResponseMessageLegsGroup) }

(***************************************************************************)
(* Mass Quote Response Message                                             *)
(***************************************************************************)

MassQuoteResponseMessage ==
    [ timestamp                              : Sample(8),
      execId                                 : Sample(8),
      quoteId                                : Sample(8),
      correlationId                          : Sample(8),
      mmpGroupId                             : Sample(8),
      receiveTime                            : Sample(8),
      massQuoteResponseMessageQuotesGroups   : MassQuoteResponseMessageQuotesGroups,
      massQuoteResponseMessageBidFillsGroups : MassQuoteResponseMessageBidFillsGroups,
      massQuoteResponseMessageAskFillsGroups : MassQuoteResponseMessageAskFillsGroups,
      massQuoteResponseMessageLegsGroups     : MassQuoteResponseMessageLegsGroups ]

EncodeMassQuoteResponseMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.quoteId
        \o message.correlationId
        \o message.mmpGroupId
        \o message.receiveTime
        \o EncodeMassQuoteResponseMessageQuotesGroups(message.massQuoteResponseMessageQuotesGroups)
        \o EncodeMassQuoteResponseMessageBidFillsGroups(message.massQuoteResponseMessageBidFillsGroups)
        \o EncodeMassQuoteResponseMessageAskFillsGroups(message.massQuoteResponseMessageAskFillsGroups)
        \o EncodeMassQuoteResponseMessageLegsGroups(message.massQuoteResponseMessageLegsGroups)

DecodeMassQuoteResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(execId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(quoteId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(correlationId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(mmpGroupId.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    LET massQuoteResponseMessageQuotesGroups == DecodeMassQuoteResponseMessageQuotesGroups(receiveTime.rest) IN IF ~massQuoteResponseMessageQuotesGroups.ok THEN Fail ELSE
    LET massQuoteResponseMessageBidFillsGroups == DecodeMassQuoteResponseMessageBidFillsGroups(massQuoteResponseMessageQuotesGroups.rest) IN IF ~massQuoteResponseMessageBidFillsGroups.ok THEN Fail ELSE
    LET massQuoteResponseMessageAskFillsGroups == DecodeMassQuoteResponseMessageAskFillsGroups(massQuoteResponseMessageBidFillsGroups.rest) IN IF ~massQuoteResponseMessageAskFillsGroups.ok THEN Fail ELSE
    LET massQuoteResponseMessageLegsGroups == DecodeMassQuoteResponseMessageLegsGroups(massQuoteResponseMessageAskFillsGroups.rest) IN IF ~massQuoteResponseMessageLegsGroups.ok THEN Fail ELSE
    Ok([ timestamp                              |-> timestamp.value,
         execId                                 |-> execId.value,
         quoteId                                |-> quoteId.value,
         correlationId                          |-> correlationId.value,
         mmpGroupId                             |-> mmpGroupId.value,
         receiveTime                            |-> receiveTime.value,
         massQuoteResponseMessageQuotesGroups   |-> massQuoteResponseMessageQuotesGroups.value,
         massQuoteResponseMessageBidFillsGroups |-> massQuoteResponseMessageBidFillsGroups.value,
         massQuoteResponseMessageAskFillsGroups |-> massQuoteResponseMessageAskFillsGroups.value,
         massQuoteResponseMessageLegsGroups     |-> massQuoteResponseMessageLegsGroups.value ], massQuoteResponseMessageLegsGroups.rest)

ZeroMassQuoteResponseMessage ==
    [ timestamp                              |-> [i \in 1 .. 8 |-> 0],
      execId                                 |-> [i \in 1 .. 8 |-> 0],
      quoteId                                |-> [i \in 1 .. 8 |-> 0],
      correlationId                          |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId                             |-> [i \in 1 .. 8 |-> 0],
      receiveTime                            |-> [i \in 1 .. 8 |-> 0],
      massQuoteResponseMessageQuotesGroups   |-> ZeroMassQuoteResponseMessageQuotesGroups,
      massQuoteResponseMessageBidFillsGroups |-> ZeroMassQuoteResponseMessageBidFillsGroups,
      massQuoteResponseMessageAskFillsGroups |-> ZeroMassQuoteResponseMessageAskFillsGroups,
      massQuoteResponseMessageLegsGroups     |-> ZeroMassQuoteResponseMessageLegsGroups ]

(* Mass Quote Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponseMessage ==
    { ZeroMassQuoteResponseMessage }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.massQuoteResponseMessageQuotesGroups = one] : one \in CheckedMassQuoteResponseMessageQuotesGroups }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.massQuoteResponseMessageBidFillsGroups = one] : one \in CheckedMassQuoteResponseMessageBidFillsGroups }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.massQuoteResponseMessageAskFillsGroups = one] : one \in CheckedMassQuoteResponseMessageAskFillsGroups }
        \cup { [ZeroMassQuoteResponseMessage EXCEPT !.massQuoteResponseMessageLegsGroups = one] : one \in CheckedMassQuoteResponseMessageLegsGroups }

(***************************************************************************)
(* Details                                                                 *)
(***************************************************************************)

Details5 ==
    [ detailsData : SampleBytes ]

EncodeDetails5(message) ==
    EncodeUIntBE(Len(message.detailsData), 1)
        \o message.detailsData

DecodeDetails5(bytes) ==
    LET detailsLength == ReadUIntBE(bytes, 1) IN IF ~detailsLength.ok THEN Fail ELSE
    LET detailsData == ReadBytes(detailsLength.rest, detailsLength.value) IN IF ~detailsData.ok THEN Fail ELSE
    Ok([ detailsData |-> detailsData.value ], detailsData.rest)

ZeroDetails5 ==
    [ detailsData |-> << >> ]

(* Details at zero, then each field in turn at the values it is checked at *)
CheckedDetails5 ==
    { ZeroDetails5 }
        \cup { [ZeroDetails5 EXCEPT !.detailsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Mass Quote Reject Message                                               *)
(***************************************************************************)

MassQuoteRejectMessage ==
    [ timestamp                   : Sample(8),
      execId                      : Sample(8),
      quoteId                     : Sample(8),
      correlationId               : Sample(8),
      mmpGroupId                  : Sample(8),
      reasonMassQuoteRejectReason : Sample(1),
      details                     : Details5 ]

EncodeMassQuoteRejectMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.quoteId
        \o message.correlationId
        \o message.mmpGroupId
        \o message.reasonMassQuoteRejectReason
        \o EncodeDetails5(message.details)

DecodeMassQuoteRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(execId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(quoteId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(correlationId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET reasonMassQuoteRejectReason == ReadBytes(mmpGroupId.rest, 1) IN IF ~reasonMassQuoteRejectReason.ok THEN Fail ELSE
    LET details == DecodeDetails5(reasonMassQuoteRejectReason.rest) IN IF ~details.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         execId                      |-> execId.value,
         quoteId                     |-> quoteId.value,
         correlationId               |-> correlationId.value,
         mmpGroupId                  |-> mmpGroupId.value,
         reasonMassQuoteRejectReason |-> reasonMassQuoteRejectReason.value,
         details                     |-> details.value ], details.rest)

ZeroMassQuoteRejectMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      execId                      |-> [i \in 1 .. 8 |-> 0],
      quoteId                     |-> [i \in 1 .. 8 |-> 0],
      correlationId               |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId                  |-> [i \in 1 .. 8 |-> 0],
      reasonMassQuoteRejectReason |-> [i \in 1 .. 1 |-> 0],
      details                     |-> ZeroDetails5 ]

(* Mass Quote Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRejectMessage ==
    { ZeroMassQuoteRejectMessage }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.reasonMassQuoteRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRejectMessage EXCEPT !.details = one] : one \in CheckedDetails5 }

(***************************************************************************)
(* Mass Cancel Response Message: 36 bytes                                  *)
(***************************************************************************)

MassCancelResponseMessage ==
    [ timestamp       : Sample(8),
      execId          : Sample(8),
      correlationId   : Sample(8),
      receiveTime     : Sample(8),
      totalOrderCount : Sample(4) ]

EncodeMassCancelResponseMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.correlationId
        \o message.receiveTime
        \o message.totalOrderCount

DecodeMassCancelResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(execId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(correlationId.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    LET totalOrderCount == ReadBytes(receiveTime.rest, 4) IN IF ~totalOrderCount.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         execId          |-> execId.value,
         correlationId   |-> correlationId.value,
         receiveTime     |-> receiveTime.value,
         totalOrderCount |-> totalOrderCount.value ], totalOrderCount.rest)

ZeroMassCancelResponseMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      correlationId   |-> [i \in 1 .. 8 |-> 0],
      receiveTime     |-> [i \in 1 .. 8 |-> 0],
      totalOrderCount |-> [i \in 1 .. 4 |-> 0] ]

(* Mass Cancel Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponseMessage ==
    { ZeroMassCancelResponseMessage }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.totalOrderCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Details                                                                 *)
(***************************************************************************)

Details6 ==
    [ detailsData : SampleBytes ]

EncodeDetails6(message) ==
    EncodeUIntBE(Len(message.detailsData), 1)
        \o message.detailsData

DecodeDetails6(bytes) ==
    LET detailsLength == ReadUIntBE(bytes, 1) IN IF ~detailsLength.ok THEN Fail ELSE
    LET detailsData == ReadBytes(detailsLength.rest, detailsLength.value) IN IF ~detailsData.ok THEN Fail ELSE
    Ok([ detailsData |-> detailsData.value ], detailsData.rest)

ZeroDetails6 ==
    [ detailsData |-> << >> ]

(* Details at zero, then each field in turn at the values it is checked at *)
CheckedDetails6 ==
    { ZeroDetails6 }
        \cup { [ZeroDetails6 EXCEPT !.detailsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Mass Cancel Reject Message                                              *)
(***************************************************************************)

MassCancelRejectMessage ==
    [ timestamp                    : Sample(8),
      execId                       : Sample(8),
      correlationId                : Sample(8),
      reasonMassCancelRejectReason : Sample(1),
      details                      : Details6 ]

EncodeMassCancelRejectMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.correlationId
        \o message.reasonMassCancelRejectReason
        \o EncodeDetails6(message.details)

DecodeMassCancelRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(execId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET reasonMassCancelRejectReason == ReadBytes(correlationId.rest, 1) IN IF ~reasonMassCancelRejectReason.ok THEN Fail ELSE
    LET details == DecodeDetails6(reasonMassCancelRejectReason.rest) IN IF ~details.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         execId                       |-> execId.value,
         correlationId                |-> correlationId.value,
         reasonMassCancelRejectReason |-> reasonMassCancelRejectReason.value,
         details                      |-> details.value ], details.rest)

ZeroMassCancelRejectMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      execId                       |-> [i \in 1 .. 8 |-> 0],
      correlationId                |-> [i \in 1 .. 8 |-> 0],
      reasonMassCancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      details                      |-> ZeroDetails6 ]

(* Mass Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejectMessage ==
    { ZeroMassCancelRejectMessage }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.reasonMassCancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.details = one] : one \in CheckedDetails6 }

(***************************************************************************)
(* Get Mass Quote Mmp Status Response Message: 32 bytes                    *)
(***************************************************************************)

GetMassQuoteMmpStatusResponseMessage ==
    [ timestamp       : Sample(8),
      correlationId   : Sample(8),
      mmpGroupId      : Sample(8),
      frozenUntilTime : Sample(8) ]

EncodeGetMassQuoteMmpStatusResponseMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.mmpGroupId
        \o message.frozenUntilTime

DecodeGetMassQuoteMmpStatusResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(correlationId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET frozenUntilTime == ReadBytes(mmpGroupId.rest, 8) IN IF ~frozenUntilTime.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         correlationId   |-> correlationId.value,
         mmpGroupId      |-> mmpGroupId.value,
         frozenUntilTime |-> frozenUntilTime.value ], frozenUntilTime.rest)

ZeroGetMassQuoteMmpStatusResponseMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      correlationId   |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId      |-> [i \in 1 .. 8 |-> 0],
      frozenUntilTime |-> [i \in 1 .. 8 |-> 0] ]

(* Get Mass Quote Mmp Status Response Message at zero, then each field in turn at the values it is checked at *)
CheckedGetMassQuoteMmpStatusResponseMessage ==
    { ZeroGetMassQuoteMmpStatusResponseMessage }
        \cup { [ZeroGetMassQuoteMmpStatusResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroGetMassQuoteMmpStatusResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroGetMassQuoteMmpStatusResponseMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroGetMassQuoteMmpStatusResponseMessage EXCEPT !.frozenUntilTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Get Mass Quote Mmp Status Reject Message: 17 bytes                      *)
(***************************************************************************)

GetMassQuoteMmpStatusRejectMessage ==
    [ timestamp                   : Sample(8),
      correlationId               : Sample(8),
      reasonMmpStatusRejectReason : Sample(1) ]

EncodeGetMassQuoteMmpStatusRejectMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.reasonMmpStatusRejectReason

DecodeGetMassQuoteMmpStatusRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET reasonMmpStatusRejectReason == ReadBytes(correlationId.rest, 1) IN IF ~reasonMmpStatusRejectReason.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         correlationId               |-> correlationId.value,
         reasonMmpStatusRejectReason |-> reasonMmpStatusRejectReason.value ], reasonMmpStatusRejectReason.rest)

ZeroGetMassQuoteMmpStatusRejectMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      correlationId               |-> [i \in 1 .. 8 |-> 0],
      reasonMmpStatusRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Get Mass Quote Mmp Status Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedGetMassQuoteMmpStatusRejectMessage ==
    { ZeroGetMassQuoteMmpStatusRejectMessage }
        \cup { [ZeroGetMassQuoteMmpStatusRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroGetMassQuoteMmpStatusRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroGetMassQuoteMmpStatusRejectMessage EXCEPT !.reasonMmpStatusRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Get Orders Mmp Status Response Message: 32 bytes                        *)
(***************************************************************************)

GetOrdersMmpStatusResponseMessage ==
    [ timestamp       : Sample(8),
      correlationId   : Sample(8),
      currencyPairId  : Sample(8),
      frozenUntilTime : Sample(8) ]

EncodeGetOrdersMmpStatusResponseMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.currencyPairId
        \o message.frozenUntilTime

DecodeGetOrdersMmpStatusResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET currencyPairId == ReadBytes(correlationId.rest, 8) IN IF ~currencyPairId.ok THEN Fail ELSE
    LET frozenUntilTime == ReadBytes(currencyPairId.rest, 8) IN IF ~frozenUntilTime.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         correlationId   |-> correlationId.value,
         currencyPairId  |-> currencyPairId.value,
         frozenUntilTime |-> frozenUntilTime.value ], frozenUntilTime.rest)

ZeroGetOrdersMmpStatusResponseMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      correlationId   |-> [i \in 1 .. 8 |-> 0],
      currencyPairId  |-> [i \in 1 .. 8 |-> 0],
      frozenUntilTime |-> [i \in 1 .. 8 |-> 0] ]

(* Get Orders Mmp Status Response Message at zero, then each field in turn at the values it is checked at *)
CheckedGetOrdersMmpStatusResponseMessage ==
    { ZeroGetOrdersMmpStatusResponseMessage }
        \cup { [ZeroGetOrdersMmpStatusResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroGetOrdersMmpStatusResponseMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroGetOrdersMmpStatusResponseMessage EXCEPT !.currencyPairId = one] : one \in Sample(8) }
        \cup { [ZeroGetOrdersMmpStatusResponseMessage EXCEPT !.frozenUntilTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Get Orders Mmp Status Reject Message: 17 bytes                          *)
(***************************************************************************)

GetOrdersMmpStatusRejectMessage ==
    [ timestamp                   : Sample(8),
      correlationId               : Sample(8),
      reasonMmpStatusRejectReason : Sample(1) ]

EncodeGetOrdersMmpStatusRejectMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.reasonMmpStatusRejectReason

DecodeGetOrdersMmpStatusRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET reasonMmpStatusRejectReason == ReadBytes(correlationId.rest, 1) IN IF ~reasonMmpStatusRejectReason.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         correlationId               |-> correlationId.value,
         reasonMmpStatusRejectReason |-> reasonMmpStatusRejectReason.value ], reasonMmpStatusRejectReason.rest)

ZeroGetOrdersMmpStatusRejectMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      correlationId               |-> [i \in 1 .. 8 |-> 0],
      reasonMmpStatusRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Get Orders Mmp Status Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedGetOrdersMmpStatusRejectMessage ==
    { ZeroGetOrdersMmpStatusRejectMessage }
        \cup { [ZeroGetOrdersMmpStatusRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroGetOrdersMmpStatusRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroGetOrdersMmpStatusRejectMessage EXCEPT !.reasonMmpStatusRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty8 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty8(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty8(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty8 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty8 ==
    { ZeroFillQty8 }
        \cup { [ZeroFillQty8 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty8 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Total Filled: 9 bytes                                                   *)
(***************************************************************************)

TotalFilled3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeTotalFilled3(message) ==
    message.mantissa
        \o message.exponent

DecodeTotalFilled3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroTotalFilled3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Total Filled at zero, then each field in turn at the values it is checked at *)
CheckedTotalFilled3 ==
    { ZeroTotalFilled3 }
        \cup { [ZeroTotalFilled3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroTotalFilled3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Filled Message fills Group: 60 bytes                              *)
(***************************************************************************)

OrderFilledMessageFillsGroup ==
    [ clientOrderId  : Sample(8),
      orderId        : Sample(8),
      instrumentId   : Sample(8),
      matchId        : Sample(8),
      price          : Sample(8),
      fillQty        : FillQty8,
      totalFilled    : TotalFilled3,
      side           : Sample(1),
      flagsFillFlags : Sample(1) ]

EncodeOrderFilledMessageFillsGroup(message) ==
    message.clientOrderId
        \o message.orderId
        \o message.instrumentId
        \o message.matchId
        \o message.price
        \o EncodeFillQty8(message.fillQty)
        \o EncodeTotalFilled3(message.totalFilled)
        \o message.side
        \o message.flagsFillFlags

DecodeOrderFilledMessageFillsGroup(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET matchId == ReadBytes(instrumentId.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET price == ReadBytes(matchId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty8(price.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET totalFilled == DecodeTotalFilled3(fillQty.rest) IN IF ~totalFilled.ok THEN Fail ELSE
    LET side == ReadBytes(totalFilled.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET flagsFillFlags == ReadBytes(side.rest, 1) IN IF ~flagsFillFlags.ok THEN Fail ELSE
    Ok([ clientOrderId  |-> clientOrderId.value,
         orderId        |-> orderId.value,
         instrumentId   |-> instrumentId.value,
         matchId        |-> matchId.value,
         price          |-> price.value,
         fillQty        |-> fillQty.value,
         totalFilled    |-> totalFilled.value,
         side           |-> side.value,
         flagsFillFlags |-> flagsFillFlags.value ], flagsFillFlags.rest)

ZeroOrderFilledMessageFillsGroup ==
    [ clientOrderId  |-> [i \in 1 .. 8 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 8 |-> 0],
      matchId        |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      fillQty        |-> ZeroFillQty8,
      totalFilled    |-> ZeroTotalFilled3,
      side           |-> [i \in 1 .. 1 |-> 0],
      flagsFillFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Order Filled Message fills Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderFilledMessageFillsGroup ==
    { ZeroOrderFilledMessageFillsGroup }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty8 }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.totalFilled = one] : one \in CheckedTotalFilled3 }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderFilledMessageFillsGroup EXCEPT !.flagsFillFlags = one] : one \in Sample(1) }

(* A run of Order Filled Message fills Group, written one after another *)
RECURSIVE EncodeOrderFilledMessageFillsGroupList(_)
EncodeOrderFilledMessageFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderFilledMessageFillsGroup(Head(messages)) \o EncodeOrderFilledMessageFillsGroupList(Tail(messages))

(* As many Order Filled Message fills Group as the field that counts them says *)
RECURSIVE ReadOrderFilledMessageFillsGroupList(_, _)
ReadOrderFilledMessageFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderFilledMessageFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderFilledMessageFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Filled Message fills Group of each kind, for the lists that carry them *)
OneOrderFilledMessageFillsGroup == { ZeroOrderFilledMessageFillsGroup }

(***************************************************************************)
(* Order Filled Message fills Groups                                       *)
(***************************************************************************)

OrderFilledMessageFillsGroups ==
    [ blockLength                  : Sample(2),
      orderFilledMessageFillsGroup : SampleLists(OneOrderFilledMessageFillsGroup) ]

EncodeOrderFilledMessageFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.orderFilledMessageFillsGroup), 2)
        \o EncodeOrderFilledMessageFillsGroupList(message.orderFilledMessageFillsGroup)

DecodeOrderFilledMessageFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderFilledMessageFillsGroup == ReadOrderFilledMessageFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderFilledMessageFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         orderFilledMessageFillsGroup |-> orderFilledMessageFillsGroup.value ], orderFilledMessageFillsGroup.rest)

ZeroOrderFilledMessageFillsGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      orderFilledMessageFillsGroup |-> << >> ]

(* Order Filled Message fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderFilledMessageFillsGroups ==
    { ZeroOrderFilledMessageFillsGroups }
        \cup { [ZeroOrderFilledMessageFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOrderFilledMessageFillsGroups EXCEPT !.orderFilledMessageFillsGroup = one] : one \in SampleLists(OneOrderFilledMessageFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty9 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty9(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty9(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty9 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty9 ==
    { ZeroFillQty9 }
        \cup { [ZeroFillQty9 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty9 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Filled Message legs Group: 34 bytes                               *)
(***************************************************************************)

OrderFilledMessageLegsGroup ==
    [ matchId : Sample(8),
      fillId  : Sample(8),
      price   : Sample(8),
      fillQty : FillQty9,
      legSide : Sample(1) ]

EncodeOrderFilledMessageLegsGroup(message) ==
    message.matchId
        \o message.fillId
        \o message.price
        \o EncodeFillQty9(message.fillQty)
        \o message.legSide

DecodeOrderFilledMessageLegsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillId == ReadBytes(matchId.rest, 8) IN IF ~fillId.ok THEN Fail ELSE
    LET price == ReadBytes(fillId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty9(price.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(fillQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ matchId |-> matchId.value,
         fillId  |-> fillId.value,
         price   |-> price.value,
         fillQty |-> fillQty.value,
         legSide |-> legSide.value ], legSide.rest)

ZeroOrderFilledMessageLegsGroup ==
    [ matchId |-> [i \in 1 .. 8 |-> 0],
      fillId  |-> [i \in 1 .. 8 |-> 0],
      price   |-> [i \in 1 .. 8 |-> 0],
      fillQty |-> ZeroFillQty9,
      legSide |-> [i \in 1 .. 1 |-> 0] ]

(* Order Filled Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderFilledMessageLegsGroup ==
    { ZeroOrderFilledMessageLegsGroup }
        \cup { [ZeroOrderFilledMessageLegsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageLegsGroup EXCEPT !.fillId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageLegsGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessageLegsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty9 }
        \cup { [ZeroOrderFilledMessageLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Order Filled Message legs Group, written one after another *)
RECURSIVE EncodeOrderFilledMessageLegsGroupList(_)
EncodeOrderFilledMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderFilledMessageLegsGroup(Head(messages)) \o EncodeOrderFilledMessageLegsGroupList(Tail(messages))

(* As many Order Filled Message legs Group as the field that counts them says *)
RECURSIVE ReadOrderFilledMessageLegsGroupList(_, _)
ReadOrderFilledMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderFilledMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderFilledMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Filled Message legs Group of each kind, for the lists that carry them *)
OneOrderFilledMessageLegsGroup == { ZeroOrderFilledMessageLegsGroup }

(***************************************************************************)
(* Order Filled Message legs Groups                                        *)
(***************************************************************************)

OrderFilledMessageLegsGroups ==
    [ blockLength                 : Sample(2),
      orderFilledMessageLegsGroup : SampleLists(OneOrderFilledMessageLegsGroup) ]

EncodeOrderFilledMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.orderFilledMessageLegsGroup), 2)
        \o EncodeOrderFilledMessageLegsGroupList(message.orderFilledMessageLegsGroup)

DecodeOrderFilledMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderFilledMessageLegsGroup == ReadOrderFilledMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderFilledMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         orderFilledMessageLegsGroup |-> orderFilledMessageLegsGroup.value ], orderFilledMessageLegsGroup.rest)

ZeroOrderFilledMessageLegsGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      orderFilledMessageLegsGroup |-> << >> ]

(* Order Filled Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderFilledMessageLegsGroups ==
    { ZeroOrderFilledMessageLegsGroups }
        \cup { [ZeroOrderFilledMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOrderFilledMessageLegsGroups EXCEPT !.orderFilledMessageLegsGroup = one] : one \in SampleLists(OneOrderFilledMessageLegsGroup) }

(***************************************************************************)
(* Order Filled Message                                                    *)
(***************************************************************************)

OrderFilledMessage ==
    [ timestamp                     : Sample(8),
      execId                        : Sample(8),
      orderFilledMessageFillsGroups : OrderFilledMessageFillsGroups,
      orderFilledMessageLegsGroups  : OrderFilledMessageLegsGroups ]

EncodeOrderFilledMessage(message) ==
    message.timestamp
        \o message.execId
        \o EncodeOrderFilledMessageFillsGroups(message.orderFilledMessageFillsGroups)
        \o EncodeOrderFilledMessageLegsGroups(message.orderFilledMessageLegsGroups)

DecodeOrderFilledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderFilledMessageFillsGroups == DecodeOrderFilledMessageFillsGroups(execId.rest) IN IF ~orderFilledMessageFillsGroups.ok THEN Fail ELSE
    LET orderFilledMessageLegsGroups == DecodeOrderFilledMessageLegsGroups(orderFilledMessageFillsGroups.rest) IN IF ~orderFilledMessageLegsGroups.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         execId                        |-> execId.value,
         orderFilledMessageFillsGroups |-> orderFilledMessageFillsGroups.value,
         orderFilledMessageLegsGroups  |-> orderFilledMessageLegsGroups.value ], orderFilledMessageLegsGroups.rest)

ZeroOrderFilledMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      execId                        |-> [i \in 1 .. 8 |-> 0],
      orderFilledMessageFillsGroups |-> ZeroOrderFilledMessageFillsGroups,
      orderFilledMessageLegsGroups  |-> ZeroOrderFilledMessageLegsGroups ]

(* Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderFilledMessage ==
    { ZeroOrderFilledMessage }
        \cup { [ZeroOrderFilledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.orderFilledMessageFillsGroups = one] : one \in CheckedOrderFilledMessageFillsGroups }
        \cup { [ZeroOrderFilledMessage EXCEPT !.orderFilledMessageLegsGroups = one] : one \in CheckedOrderFilledMessageLegsGroups }

(***************************************************************************)
(* Total Filled: 9 bytes                                                   *)
(***************************************************************************)

TotalFilled4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeTotalFilled4(message) ==
    message.mantissa
        \o message.exponent

DecodeTotalFilled4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroTotalFilled4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Total Filled at zero, then each field in turn at the values it is checked at *)
CheckedTotalFilled4 ==
    { ZeroTotalFilled4 }
        \cup { [ZeroTotalFilled4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroTotalFilled4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Orders Canceled Message orders Group: 35 bytes                          *)
(***************************************************************************)

OrdersCanceledMessageOrdersGroup ==
    [ clientOrderId    : Sample(8),
      orderId          : Sample(8),
      instrumentId     : Sample(8),
      totalFilled      : TotalFilled4,
      cancelReason     : Sample(1),
      flagsCancelFlags : Sample(1) ]

EncodeOrdersCanceledMessageOrdersGroup(message) ==
    message.clientOrderId
        \o message.orderId
        \o message.instrumentId
        \o EncodeTotalFilled4(message.totalFilled)
        \o message.cancelReason
        \o message.flagsCancelFlags

DecodeOrdersCanceledMessageOrdersGroup(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET totalFilled == DecodeTotalFilled4(instrumentId.rest) IN IF ~totalFilled.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(totalFilled.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET flagsCancelFlags == ReadBytes(cancelReason.rest, 1) IN IF ~flagsCancelFlags.ok THEN Fail ELSE
    Ok([ clientOrderId    |-> clientOrderId.value,
         orderId          |-> orderId.value,
         instrumentId     |-> instrumentId.value,
         totalFilled      |-> totalFilled.value,
         cancelReason     |-> cancelReason.value,
         flagsCancelFlags |-> flagsCancelFlags.value ], flagsCancelFlags.rest)

ZeroOrdersCanceledMessageOrdersGroup ==
    [ clientOrderId    |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 8 |-> 0],
      totalFilled      |-> ZeroTotalFilled4,
      cancelReason     |-> [i \in 1 .. 1 |-> 0],
      flagsCancelFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Orders Canceled Message orders Group at zero, then each field in turn at the values it is checked at *)
CheckedOrdersCanceledMessageOrdersGroup ==
    { ZeroOrdersCanceledMessageOrdersGroup }
        \cup { [ZeroOrdersCanceledMessageOrdersGroup EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersCanceledMessageOrdersGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersCanceledMessageOrdersGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersCanceledMessageOrdersGroup EXCEPT !.totalFilled = one] : one \in CheckedTotalFilled4 }
        \cup { [ZeroOrdersCanceledMessageOrdersGroup EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroOrdersCanceledMessageOrdersGroup EXCEPT !.flagsCancelFlags = one] : one \in Sample(1) }

(* A run of Orders Canceled Message orders Group, written one after another *)
RECURSIVE EncodeOrdersCanceledMessageOrdersGroupList(_)
EncodeOrdersCanceledMessageOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrdersCanceledMessageOrdersGroup(Head(messages)) \o EncodeOrdersCanceledMessageOrdersGroupList(Tail(messages))

(* As many Orders Canceled Message orders Group as the field that counts them says *)
RECURSIVE ReadOrdersCanceledMessageOrdersGroupList(_, _)
ReadOrdersCanceledMessageOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrdersCanceledMessageOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrdersCanceledMessageOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Orders Canceled Message orders Group of each kind, for the lists that carry them *)
OneOrdersCanceledMessageOrdersGroup == { ZeroOrdersCanceledMessageOrdersGroup }

(***************************************************************************)
(* Orders Canceled Message orders Groups                                   *)
(***************************************************************************)

OrdersCanceledMessageOrdersGroups ==
    [ blockLength                      : Sample(2),
      ordersCanceledMessageOrdersGroup : SampleLists(OneOrdersCanceledMessageOrdersGroup) ]

EncodeOrdersCanceledMessageOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.ordersCanceledMessageOrdersGroup), 2)
        \o EncodeOrdersCanceledMessageOrdersGroupList(message.ordersCanceledMessageOrdersGroup)

DecodeOrdersCanceledMessageOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET ordersCanceledMessageOrdersGroup == ReadOrdersCanceledMessageOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~ordersCanceledMessageOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength                      |-> blockLength.value,
         ordersCanceledMessageOrdersGroup |-> ordersCanceledMessageOrdersGroup.value ], ordersCanceledMessageOrdersGroup.rest)

ZeroOrdersCanceledMessageOrdersGroups ==
    [ blockLength                      |-> [i \in 1 .. 2 |-> 0],
      ordersCanceledMessageOrdersGroup |-> << >> ]

(* Orders Canceled Message orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrdersCanceledMessageOrdersGroups ==
    { ZeroOrdersCanceledMessageOrdersGroups }
        \cup { [ZeroOrdersCanceledMessageOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOrdersCanceledMessageOrdersGroups EXCEPT !.ordersCanceledMessageOrdersGroup = one] : one \in SampleLists(OneOrdersCanceledMessageOrdersGroup) }

(***************************************************************************)
(* Orders Canceled Message                                                 *)
(***************************************************************************)

OrdersCanceledMessage ==
    [ timestamp                         : Sample(8),
      execId                            : Sample(8),
      flagsMultiPartEventFlags          : Sample(1),
      ordersCanceledMessageOrdersGroups : OrdersCanceledMessageOrdersGroups ]

EncodeOrdersCanceledMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.flagsMultiPartEventFlags
        \o EncodeOrdersCanceledMessageOrdersGroups(message.ordersCanceledMessageOrdersGroups)

DecodeOrdersCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET flagsMultiPartEventFlags == ReadBytes(execId.rest, 1) IN IF ~flagsMultiPartEventFlags.ok THEN Fail ELSE
    LET ordersCanceledMessageOrdersGroups == DecodeOrdersCanceledMessageOrdersGroups(flagsMultiPartEventFlags.rest) IN IF ~ordersCanceledMessageOrdersGroups.ok THEN Fail ELSE
    Ok([ timestamp                         |-> timestamp.value,
         execId                            |-> execId.value,
         flagsMultiPartEventFlags          |-> flagsMultiPartEventFlags.value,
         ordersCanceledMessageOrdersGroups |-> ordersCanceledMessageOrdersGroups.value ], ordersCanceledMessageOrdersGroups.rest)

ZeroOrdersCanceledMessage ==
    [ timestamp                         |-> [i \in 1 .. 8 |-> 0],
      execId                            |-> [i \in 1 .. 8 |-> 0],
      flagsMultiPartEventFlags          |-> [i \in 1 .. 1 |-> 0],
      ordersCanceledMessageOrdersGroups |-> ZeroOrdersCanceledMessageOrdersGroups ]

(* Orders Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrdersCanceledMessage ==
    { ZeroOrdersCanceledMessage }
        \cup { [ZeroOrdersCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrdersCanceledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersCanceledMessage EXCEPT !.flagsMultiPartEventFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrdersCanceledMessage EXCEPT !.ordersCanceledMessageOrdersGroups = one] : one \in CheckedOrdersCanceledMessageOrdersGroups }

(***************************************************************************)
(* Quantity: 9 bytes                                                       *)
(***************************************************************************)

Quantity5 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeQuantity5(message) ==
    message.mantissa
        \o message.exponent

DecodeQuantity5(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroQuantity5 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuantity5 ==
    { ZeroQuantity5 }
        \cup { [ZeroQuantity5 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroQuantity5 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Total Filled: 9 bytes                                                   *)
(***************************************************************************)

TotalFilled5 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeTotalFilled5(message) ==
    message.mantissa
        \o message.exponent

DecodeTotalFilled5(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroTotalFilled5 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Total Filled at zero, then each field in turn at the values it is checked at *)
CheckedTotalFilled5 ==
    { ZeroTotalFilled5 }
        \cup { [ZeroTotalFilled5 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroTotalFilled5 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Visible Qty: 9 bytes                                                    *)
(***************************************************************************)

VisibleQty3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeVisibleQty3(message) ==
    message.mantissa
        \o message.exponent

DecodeVisibleQty3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroVisibleQty3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Visible Qty at zero, then each field in turn at the values it is checked at *)
CheckedVisibleQty3 ==
    { ZeroVisibleQty3 }
        \cup { [ZeroVisibleQty3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroVisibleQty3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty10 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty10(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty10(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty10 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty10 ==
    { ZeroFillQty10 }
        \cup { [ZeroFillQty10 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty10 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Placed Message fills Group: 25 bytes                              *)
(***************************************************************************)

OrderPlacedMessageFillsGroup ==
    [ matchId   : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty10 ]

EncodeOrderPlacedMessageFillsGroup(message) ==
    message.matchId
        \o message.fillPrice
        \o EncodeFillQty10(message.fillQty)

DecodeOrderPlacedMessageFillsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(matchId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty10(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value ], fillQty.rest)

ZeroOrderPlacedMessageFillsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty10 ]

(* Order Placed Message fills Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderPlacedMessageFillsGroup ==
    { ZeroOrderPlacedMessageFillsGroup }
        \cup { [ZeroOrderPlacedMessageFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessageFillsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessageFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty10 }

(* A run of Order Placed Message fills Group, written one after another *)
RECURSIVE EncodeOrderPlacedMessageFillsGroupList(_)
EncodeOrderPlacedMessageFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderPlacedMessageFillsGroup(Head(messages)) \o EncodeOrderPlacedMessageFillsGroupList(Tail(messages))

(* As many Order Placed Message fills Group as the field that counts them says *)
RECURSIVE ReadOrderPlacedMessageFillsGroupList(_, _)
ReadOrderPlacedMessageFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderPlacedMessageFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderPlacedMessageFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Placed Message fills Group of each kind, for the lists that carry them *)
OneOrderPlacedMessageFillsGroup == { ZeroOrderPlacedMessageFillsGroup }

(***************************************************************************)
(* Order Placed Message fills Groups                                       *)
(***************************************************************************)

OrderPlacedMessageFillsGroups ==
    [ blockLength                  : Sample(2),
      orderPlacedMessageFillsGroup : SampleLists(OneOrderPlacedMessageFillsGroup) ]

EncodeOrderPlacedMessageFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.orderPlacedMessageFillsGroup), 2)
        \o EncodeOrderPlacedMessageFillsGroupList(message.orderPlacedMessageFillsGroup)

DecodeOrderPlacedMessageFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderPlacedMessageFillsGroup == ReadOrderPlacedMessageFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderPlacedMessageFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         orderPlacedMessageFillsGroup |-> orderPlacedMessageFillsGroup.value ], orderPlacedMessageFillsGroup.rest)

ZeroOrderPlacedMessageFillsGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      orderPlacedMessageFillsGroup |-> << >> ]

(* Order Placed Message fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderPlacedMessageFillsGroups ==
    { ZeroOrderPlacedMessageFillsGroups }
        \cup { [ZeroOrderPlacedMessageFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOrderPlacedMessageFillsGroups EXCEPT !.orderPlacedMessageFillsGroup = one] : one \in SampleLists(OneOrderPlacedMessageFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty11 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty11(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty11(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty11 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty11 ==
    { ZeroFillQty11 }
        \cup { [ZeroFillQty11 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty11 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Placed Message legs Group: 34 bytes                               *)
(***************************************************************************)

OrderPlacedMessageLegsGroup ==
    [ matchId   : Sample(8),
      fillId    : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty11,
      legSide   : Sample(1) ]

EncodeOrderPlacedMessageLegsGroup(message) ==
    message.matchId
        \o message.fillId
        \o message.fillPrice
        \o EncodeFillQty11(message.fillQty)
        \o message.legSide

DecodeOrderPlacedMessageLegsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillId == ReadBytes(matchId.rest, 8) IN IF ~fillId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty11(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(fillQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillId    |-> fillId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value,
         legSide   |-> legSide.value ], legSide.rest)

ZeroOrderPlacedMessageLegsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillId    |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty11,
      legSide   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Placed Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderPlacedMessageLegsGroup ==
    { ZeroOrderPlacedMessageLegsGroup }
        \cup { [ZeroOrderPlacedMessageLegsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessageLegsGroup EXCEPT !.fillId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessageLegsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessageLegsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty11 }
        \cup { [ZeroOrderPlacedMessageLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Order Placed Message legs Group, written one after another *)
RECURSIVE EncodeOrderPlacedMessageLegsGroupList(_)
EncodeOrderPlacedMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderPlacedMessageLegsGroup(Head(messages)) \o EncodeOrderPlacedMessageLegsGroupList(Tail(messages))

(* As many Order Placed Message legs Group as the field that counts them says *)
RECURSIVE ReadOrderPlacedMessageLegsGroupList(_, _)
ReadOrderPlacedMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderPlacedMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderPlacedMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Placed Message legs Group of each kind, for the lists that carry them *)
OneOrderPlacedMessageLegsGroup == { ZeroOrderPlacedMessageLegsGroup }

(***************************************************************************)
(* Order Placed Message legs Groups                                        *)
(***************************************************************************)

OrderPlacedMessageLegsGroups ==
    [ blockLength                 : Sample(2),
      orderPlacedMessageLegsGroup : SampleLists(OneOrderPlacedMessageLegsGroup) ]

EncodeOrderPlacedMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.orderPlacedMessageLegsGroup), 2)
        \o EncodeOrderPlacedMessageLegsGroupList(message.orderPlacedMessageLegsGroup)

DecodeOrderPlacedMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderPlacedMessageLegsGroup == ReadOrderPlacedMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderPlacedMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         orderPlacedMessageLegsGroup |-> orderPlacedMessageLegsGroup.value ], orderPlacedMessageLegsGroup.rest)

ZeroOrderPlacedMessageLegsGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      orderPlacedMessageLegsGroup |-> << >> ]

(* Order Placed Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderPlacedMessageLegsGroups ==
    { ZeroOrderPlacedMessageLegsGroups }
        \cup { [ZeroOrderPlacedMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOrderPlacedMessageLegsGroups EXCEPT !.orderPlacedMessageLegsGroup = one] : one \in SampleLists(OneOrderPlacedMessageLegsGroup) }

(***************************************************************************)
(* Order Placed Message                                                    *)
(***************************************************************************)

OrderPlacedMessage ==
    [ timestamp                     : Sample(8),
      execId                        : Sample(8),
      clientOrderId                 : Sample(8),
      orderId                       : Sample(8),
      instrumentId                  : Sample(8),
      price                         : Sample(8),
      quantity                      : Quantity5,
      totalFilled                   : TotalFilled5,
      visibleQty                    : VisibleQty3,
      status                        : Sample(1),
      cancelReason                  : Sample(1),
      padding3                      : Sample(3),
      correlationId                 : Sample(8),
      orderPlacedMessageFillsGroups : OrderPlacedMessageFillsGroups,
      orderPlacedMessageLegsGroups  : OrderPlacedMessageLegsGroups ]

EncodeOrderPlacedMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.orderId
        \o message.instrumentId
        \o message.price
        \o EncodeQuantity5(message.quantity)
        \o EncodeTotalFilled5(message.totalFilled)
        \o EncodeVisibleQty3(message.visibleQty)
        \o message.status
        \o message.cancelReason
        \o message.padding3
        \o message.correlationId
        \o EncodeOrderPlacedMessageFillsGroups(message.orderPlacedMessageFillsGroups)
        \o EncodeOrderPlacedMessageLegsGroups(message.orderPlacedMessageLegsGroups)

DecodeOrderPlacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == DecodeQuantity5(price.rest) IN IF ~quantity.ok THEN Fail ELSE
    LET totalFilled == DecodeTotalFilled5(quantity.rest) IN IF ~totalFilled.ok THEN Fail ELSE
    LET visibleQty == DecodeVisibleQty3(totalFilled.rest) IN IF ~visibleQty.ok THEN Fail ELSE
    LET status == ReadBytes(visibleQty.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(status.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET padding3 == ReadBytes(cancelReason.rest, 3) IN IF ~padding3.ok THEN Fail ELSE
    LET correlationId == ReadBytes(padding3.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderPlacedMessageFillsGroups == DecodeOrderPlacedMessageFillsGroups(correlationId.rest) IN IF ~orderPlacedMessageFillsGroups.ok THEN Fail ELSE
    LET orderPlacedMessageLegsGroups == DecodeOrderPlacedMessageLegsGroups(orderPlacedMessageFillsGroups.rest) IN IF ~orderPlacedMessageLegsGroups.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         execId                        |-> execId.value,
         clientOrderId                 |-> clientOrderId.value,
         orderId                       |-> orderId.value,
         instrumentId                  |-> instrumentId.value,
         price                         |-> price.value,
         quantity                      |-> quantity.value,
         totalFilled                   |-> totalFilled.value,
         visibleQty                    |-> visibleQty.value,
         status                        |-> status.value,
         cancelReason                  |-> cancelReason.value,
         padding3                      |-> padding3.value,
         correlationId                 |-> correlationId.value,
         orderPlacedMessageFillsGroups |-> orderPlacedMessageFillsGroups.value,
         orderPlacedMessageLegsGroups  |-> orderPlacedMessageLegsGroups.value ], orderPlacedMessageLegsGroups.rest)

ZeroOrderPlacedMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      execId                        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      orderId                       |-> [i \in 1 .. 8 |-> 0],
      instrumentId                  |-> [i \in 1 .. 8 |-> 0],
      price                         |-> [i \in 1 .. 8 |-> 0],
      quantity                      |-> ZeroQuantity5,
      totalFilled                   |-> ZeroTotalFilled5,
      visibleQty                    |-> ZeroVisibleQty3,
      status                        |-> [i \in 1 .. 1 |-> 0],
      cancelReason                  |-> [i \in 1 .. 1 |-> 0],
      padding3                      |-> [i \in 1 .. 3 |-> 0],
      correlationId                 |-> [i \in 1 .. 8 |-> 0],
      orderPlacedMessageFillsGroups |-> ZeroOrderPlacedMessageFillsGroups,
      orderPlacedMessageLegsGroups  |-> ZeroOrderPlacedMessageLegsGroups ]

(* Order Placed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPlacedMessage ==
    { ZeroOrderPlacedMessage }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.quantity = one] : one \in CheckedQuantity5 }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.totalFilled = one] : one \in CheckedTotalFilled5 }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.visibleQty = one] : one \in CheckedVisibleQty3 }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.padding3 = one] : one \in Sample(3) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.orderPlacedMessageFillsGroups = one] : one \in CheckedOrderPlacedMessageFillsGroups }
        \cup { [ZeroOrderPlacedMessage EXCEPT !.orderPlacedMessageLegsGroups = one] : one \in CheckedOrderPlacedMessageLegsGroups }

(***************************************************************************)
(* Quantity: 9 bytes                                                       *)
(***************************************************************************)

Quantity6 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeQuantity6(message) ==
    message.mantissa
        \o message.exponent

DecodeQuantity6(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroQuantity6 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuantity6 ==
    { ZeroQuantity6 }
        \cup { [ZeroQuantity6 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroQuantity6 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Total Filled: 9 bytes                                                   *)
(***************************************************************************)

TotalFilled6 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeTotalFilled6(message) ==
    message.mantissa
        \o message.exponent

DecodeTotalFilled6(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroTotalFilled6 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Total Filled at zero, then each field in turn at the values it is checked at *)
CheckedTotalFilled6 ==
    { ZeroTotalFilled6 }
        \cup { [ZeroTotalFilled6 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroTotalFilled6 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Visible Qty: 9 bytes                                                    *)
(***************************************************************************)

VisibleQty4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeVisibleQty4(message) ==
    message.mantissa
        \o message.exponent

DecodeVisibleQty4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroVisibleQty4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Visible Qty at zero, then each field in turn at the values it is checked at *)
CheckedVisibleQty4 ==
    { ZeroVisibleQty4 }
        \cup { [ZeroVisibleQty4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroVisibleQty4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Orders Placed Message orders Group: 62 bytes                 *)
(***************************************************************************)

MassQuoteOrdersPlacedMessageOrdersGroup ==
    [ clientOrderId : Sample(8),
      orderId       : Sample(8),
      instrumentId  : Sample(8),
      price         : Sample(8),
      quantity      : Quantity6,
      totalFilled   : TotalFilled6,
      visibleQty    : VisibleQty4,
      side          : Sample(1),
      status        : Sample(1),
      cancelReason  : Sample(1) ]

EncodeMassQuoteOrdersPlacedMessageOrdersGroup(message) ==
    message.clientOrderId
        \o message.orderId
        \o message.instrumentId
        \o message.price
        \o EncodeQuantity6(message.quantity)
        \o EncodeTotalFilled6(message.totalFilled)
        \o EncodeVisibleQty4(message.visibleQty)
        \o message.side
        \o message.status
        \o message.cancelReason

DecodeMassQuoteOrdersPlacedMessageOrdersGroup(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == DecodeQuantity6(price.rest) IN IF ~quantity.ok THEN Fail ELSE
    LET totalFilled == DecodeTotalFilled6(quantity.rest) IN IF ~totalFilled.ok THEN Fail ELSE
    LET visibleQty == DecodeVisibleQty4(totalFilled.rest) IN IF ~visibleQty.ok THEN Fail ELSE
    LET side == ReadBytes(visibleQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET status == ReadBytes(side.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(status.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         orderId       |-> orderId.value,
         instrumentId  |-> instrumentId.value,
         price         |-> price.value,
         quantity      |-> quantity.value,
         totalFilled   |-> totalFilled.value,
         visibleQty    |-> visibleQty.value,
         side          |-> side.value,
         status        |-> status.value,
         cancelReason  |-> cancelReason.value ], cancelReason.rest)

ZeroMassQuoteOrdersPlacedMessageOrdersGroup ==
    [ clientOrderId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      quantity      |-> ZeroQuantity6,
      totalFilled   |-> ZeroTotalFilled6,
      visibleQty    |-> ZeroVisibleQty4,
      side          |-> [i \in 1 .. 1 |-> 0],
      status        |-> [i \in 1 .. 1 |-> 0],
      cancelReason  |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Orders Placed Message orders Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessageOrdersGroup ==
    { ZeroMassQuoteOrdersPlacedMessageOrdersGroup }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.quantity = one] : one \in CheckedQuantity6 }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.totalFilled = one] : one \in CheckedTotalFilled6 }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.visibleQty = one] : one \in CheckedVisibleQty4 }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroup EXCEPT !.cancelReason = one] : one \in Sample(1) }

(* A run of Mass Quote Orders Placed Message orders Group, written one after another *)
RECURSIVE EncodeMassQuoteOrdersPlacedMessageOrdersGroupList(_)
EncodeMassQuoteOrdersPlacedMessageOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteOrdersPlacedMessageOrdersGroup(Head(messages)) \o EncodeMassQuoteOrdersPlacedMessageOrdersGroupList(Tail(messages))

(* As many Mass Quote Orders Placed Message orders Group as the field that counts them says *)
RECURSIVE ReadMassQuoteOrdersPlacedMessageOrdersGroupList(_, _)
ReadMassQuoteOrdersPlacedMessageOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteOrdersPlacedMessageOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteOrdersPlacedMessageOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Orders Placed Message orders Group of each kind, for the lists that carry them *)
OneMassQuoteOrdersPlacedMessageOrdersGroup == { ZeroMassQuoteOrdersPlacedMessageOrdersGroup }

(***************************************************************************)
(* Mass Quote Orders Placed Message orders Groups                          *)
(***************************************************************************)

MassQuoteOrdersPlacedMessageOrdersGroups ==
    [ blockLength                             : Sample(2),
      massQuoteOrdersPlacedMessageOrdersGroup : SampleLists(OneMassQuoteOrdersPlacedMessageOrdersGroup) ]

EncodeMassQuoteOrdersPlacedMessageOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteOrdersPlacedMessageOrdersGroup), 2)
        \o EncodeMassQuoteOrdersPlacedMessageOrdersGroupList(message.massQuoteOrdersPlacedMessageOrdersGroup)

DecodeMassQuoteOrdersPlacedMessageOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteOrdersPlacedMessageOrdersGroup == ReadMassQuoteOrdersPlacedMessageOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteOrdersPlacedMessageOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength                             |-> blockLength.value,
         massQuoteOrdersPlacedMessageOrdersGroup |-> massQuoteOrdersPlacedMessageOrdersGroup.value ], massQuoteOrdersPlacedMessageOrdersGroup.rest)

ZeroMassQuoteOrdersPlacedMessageOrdersGroups ==
    [ blockLength                             |-> [i \in 1 .. 2 |-> 0],
      massQuoteOrdersPlacedMessageOrdersGroup |-> << >> ]

(* Mass Quote Orders Placed Message orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessageOrdersGroups ==
    { ZeroMassQuoteOrdersPlacedMessageOrdersGroups }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageOrdersGroups EXCEPT !.massQuoteOrdersPlacedMessageOrdersGroup = one] : one \in SampleLists(OneMassQuoteOrdersPlacedMessageOrdersGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty12 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty12(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty12(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty12 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty12 ==
    { ZeroFillQty12 }
        \cup { [ZeroFillQty12 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty12 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Orders Placed Message fills Group: 33 bytes                  *)
(***************************************************************************)

MassQuoteOrdersPlacedMessageFillsGroup ==
    [ matchId       : Sample(8),
      orderIdFillId : Sample(8),
      fillPrice     : Sample(8),
      fillQty       : FillQty12 ]

EncodeMassQuoteOrdersPlacedMessageFillsGroup(message) ==
    message.matchId
        \o message.orderIdFillId
        \o message.fillPrice
        \o EncodeFillQty12(message.fillQty)

DecodeMassQuoteOrdersPlacedMessageFillsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET orderIdFillId == ReadBytes(matchId.rest, 8) IN IF ~orderIdFillId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(orderIdFillId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty12(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    Ok([ matchId       |-> matchId.value,
         orderIdFillId |-> orderIdFillId.value,
         fillPrice     |-> fillPrice.value,
         fillQty       |-> fillQty.value ], fillQty.rest)

ZeroMassQuoteOrdersPlacedMessageFillsGroup ==
    [ matchId       |-> [i \in 1 .. 8 |-> 0],
      orderIdFillId |-> [i \in 1 .. 8 |-> 0],
      fillPrice     |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> ZeroFillQty12 ]

(* Mass Quote Orders Placed Message fills Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessageFillsGroup ==
    { ZeroMassQuoteOrdersPlacedMessageFillsGroup }
        \cup { [ZeroMassQuoteOrdersPlacedMessageFillsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageFillsGroup EXCEPT !.orderIdFillId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageFillsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageFillsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty12 }

(* A run of Mass Quote Orders Placed Message fills Group, written one after another *)
RECURSIVE EncodeMassQuoteOrdersPlacedMessageFillsGroupList(_)
EncodeMassQuoteOrdersPlacedMessageFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteOrdersPlacedMessageFillsGroup(Head(messages)) \o EncodeMassQuoteOrdersPlacedMessageFillsGroupList(Tail(messages))

(* As many Mass Quote Orders Placed Message fills Group as the field that counts them says *)
RECURSIVE ReadMassQuoteOrdersPlacedMessageFillsGroupList(_, _)
ReadMassQuoteOrdersPlacedMessageFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteOrdersPlacedMessageFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteOrdersPlacedMessageFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Orders Placed Message fills Group of each kind, for the lists that carry them *)
OneMassQuoteOrdersPlacedMessageFillsGroup == { ZeroMassQuoteOrdersPlacedMessageFillsGroup }

(***************************************************************************)
(* Mass Quote Orders Placed Message fills Groups                           *)
(***************************************************************************)

MassQuoteOrdersPlacedMessageFillsGroups ==
    [ blockLength                            : Sample(2),
      massQuoteOrdersPlacedMessageFillsGroup : SampleLists(OneMassQuoteOrdersPlacedMessageFillsGroup) ]

EncodeMassQuoteOrdersPlacedMessageFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteOrdersPlacedMessageFillsGroup), 2)
        \o EncodeMassQuoteOrdersPlacedMessageFillsGroupList(message.massQuoteOrdersPlacedMessageFillsGroup)

DecodeMassQuoteOrdersPlacedMessageFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteOrdersPlacedMessageFillsGroup == ReadMassQuoteOrdersPlacedMessageFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteOrdersPlacedMessageFillsGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         massQuoteOrdersPlacedMessageFillsGroup |-> massQuoteOrdersPlacedMessageFillsGroup.value ], massQuoteOrdersPlacedMessageFillsGroup.rest)

ZeroMassQuoteOrdersPlacedMessageFillsGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      massQuoteOrdersPlacedMessageFillsGroup |-> << >> ]

(* Mass Quote Orders Placed Message fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessageFillsGroups ==
    { ZeroMassQuoteOrdersPlacedMessageFillsGroups }
        \cup { [ZeroMassQuoteOrdersPlacedMessageFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageFillsGroups EXCEPT !.massQuoteOrdersPlacedMessageFillsGroup = one] : one \in SampleLists(OneMassQuoteOrdersPlacedMessageFillsGroup) }

(***************************************************************************)
(* Fill Qty: 9 bytes                                                       *)
(***************************************************************************)

FillQty13 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFillQty13(message) ==
    message.mantissa
        \o message.exponent

DecodeFillQty13(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFillQty13 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fill Qty at zero, then each field in turn at the values it is checked at *)
CheckedFillQty13 ==
    { ZeroFillQty13 }
        \cup { [ZeroFillQty13 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillQty13 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Orders Placed Message legs Group: 34 bytes                   *)
(***************************************************************************)

MassQuoteOrdersPlacedMessageLegsGroup ==
    [ matchId   : Sample(8),
      fillId    : Sample(8),
      fillPrice : Sample(8),
      fillQty   : FillQty13,
      legSide   : Sample(1) ]

EncodeMassQuoteOrdersPlacedMessageLegsGroup(message) ==
    message.matchId
        \o message.fillId
        \o message.fillPrice
        \o EncodeFillQty13(message.fillQty)
        \o message.legSide

DecodeMassQuoteOrdersPlacedMessageLegsGroup(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET fillId == ReadBytes(matchId.rest, 8) IN IF ~fillId.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillId.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == DecodeFillQty13(fillPrice.rest) IN IF ~fillQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(fillQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ matchId   |-> matchId.value,
         fillId    |-> fillId.value,
         fillPrice |-> fillPrice.value,
         fillQty   |-> fillQty.value,
         legSide   |-> legSide.value ], legSide.rest)

ZeroMassQuoteOrdersPlacedMessageLegsGroup ==
    [ matchId   |-> [i \in 1 .. 8 |-> 0],
      fillId    |-> [i \in 1 .. 8 |-> 0],
      fillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty   |-> ZeroFillQty13,
      legSide   |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Orders Placed Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessageLegsGroup ==
    { ZeroMassQuoteOrdersPlacedMessageLegsGroup }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroup EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroup EXCEPT !.fillId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroup EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroup EXCEPT !.fillQty = one] : one \in CheckedFillQty13 }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Mass Quote Orders Placed Message legs Group, written one after another *)
RECURSIVE EncodeMassQuoteOrdersPlacedMessageLegsGroupList(_)
EncodeMassQuoteOrdersPlacedMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteOrdersPlacedMessageLegsGroup(Head(messages)) \o EncodeMassQuoteOrdersPlacedMessageLegsGroupList(Tail(messages))

(* As many Mass Quote Orders Placed Message legs Group as the field that counts them says *)
RECURSIVE ReadMassQuoteOrdersPlacedMessageLegsGroupList(_, _)
ReadMassQuoteOrdersPlacedMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteOrdersPlacedMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteOrdersPlacedMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Orders Placed Message legs Group of each kind, for the lists that carry them *)
OneMassQuoteOrdersPlacedMessageLegsGroup == { ZeroMassQuoteOrdersPlacedMessageLegsGroup }

(***************************************************************************)
(* Mass Quote Orders Placed Message legs Groups                            *)
(***************************************************************************)

MassQuoteOrdersPlacedMessageLegsGroups ==
    [ blockLength                           : Sample(2),
      massQuoteOrdersPlacedMessageLegsGroup : SampleLists(OneMassQuoteOrdersPlacedMessageLegsGroup) ]

EncodeMassQuoteOrdersPlacedMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteOrdersPlacedMessageLegsGroup), 2)
        \o EncodeMassQuoteOrdersPlacedMessageLegsGroupList(message.massQuoteOrdersPlacedMessageLegsGroup)

DecodeMassQuoteOrdersPlacedMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteOrdersPlacedMessageLegsGroup == ReadMassQuoteOrdersPlacedMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteOrdersPlacedMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                           |-> blockLength.value,
         massQuoteOrdersPlacedMessageLegsGroup |-> massQuoteOrdersPlacedMessageLegsGroup.value ], massQuoteOrdersPlacedMessageLegsGroup.rest)

ZeroMassQuoteOrdersPlacedMessageLegsGroups ==
    [ blockLength                           |-> [i \in 1 .. 2 |-> 0],
      massQuoteOrdersPlacedMessageLegsGroup |-> << >> ]

(* Mass Quote Orders Placed Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessageLegsGroups ==
    { ZeroMassQuoteOrdersPlacedMessageLegsGroups }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteOrdersPlacedMessageLegsGroups EXCEPT !.massQuoteOrdersPlacedMessageLegsGroup = one] : one \in SampleLists(OneMassQuoteOrdersPlacedMessageLegsGroup) }

(***************************************************************************)
(* Mass Quote Orders Placed Message                                        *)
(***************************************************************************)

MassQuoteOrdersPlacedMessage ==
    [ timestamp                                : Sample(8),
      execId                                   : Sample(8),
      mmpGroupId                               : Sample(8),
      massQuoteOrdersPlacedMessageOrdersGroups : MassQuoteOrdersPlacedMessageOrdersGroups,
      massQuoteOrdersPlacedMessageFillsGroups  : MassQuoteOrdersPlacedMessageFillsGroups,
      massQuoteOrdersPlacedMessageLegsGroups   : MassQuoteOrdersPlacedMessageLegsGroups ]

EncodeMassQuoteOrdersPlacedMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.mmpGroupId
        \o EncodeMassQuoteOrdersPlacedMessageOrdersGroups(message.massQuoteOrdersPlacedMessageOrdersGroups)
        \o EncodeMassQuoteOrdersPlacedMessageFillsGroups(message.massQuoteOrdersPlacedMessageFillsGroups)
        \o EncodeMassQuoteOrdersPlacedMessageLegsGroups(message.massQuoteOrdersPlacedMessageLegsGroups)

DecodeMassQuoteOrdersPlacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(execId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET massQuoteOrdersPlacedMessageOrdersGroups == DecodeMassQuoteOrdersPlacedMessageOrdersGroups(mmpGroupId.rest) IN IF ~massQuoteOrdersPlacedMessageOrdersGroups.ok THEN Fail ELSE
    LET massQuoteOrdersPlacedMessageFillsGroups == DecodeMassQuoteOrdersPlacedMessageFillsGroups(massQuoteOrdersPlacedMessageOrdersGroups.rest) IN IF ~massQuoteOrdersPlacedMessageFillsGroups.ok THEN Fail ELSE
    LET massQuoteOrdersPlacedMessageLegsGroups == DecodeMassQuoteOrdersPlacedMessageLegsGroups(massQuoteOrdersPlacedMessageFillsGroups.rest) IN IF ~massQuoteOrdersPlacedMessageLegsGroups.ok THEN Fail ELSE
    Ok([ timestamp                                |-> timestamp.value,
         execId                                   |-> execId.value,
         mmpGroupId                               |-> mmpGroupId.value,
         massQuoteOrdersPlacedMessageOrdersGroups |-> massQuoteOrdersPlacedMessageOrdersGroups.value,
         massQuoteOrdersPlacedMessageFillsGroups  |-> massQuoteOrdersPlacedMessageFillsGroups.value,
         massQuoteOrdersPlacedMessageLegsGroups   |-> massQuoteOrdersPlacedMessageLegsGroups.value ], massQuoteOrdersPlacedMessageLegsGroups.rest)

ZeroMassQuoteOrdersPlacedMessage ==
    [ timestamp                                |-> [i \in 1 .. 8 |-> 0],
      execId                                   |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId                               |-> [i \in 1 .. 8 |-> 0],
      massQuoteOrdersPlacedMessageOrdersGroups |-> ZeroMassQuoteOrdersPlacedMessageOrdersGroups,
      massQuoteOrdersPlacedMessageFillsGroups  |-> ZeroMassQuoteOrdersPlacedMessageFillsGroups,
      massQuoteOrdersPlacedMessageLegsGroups   |-> ZeroMassQuoteOrdersPlacedMessageLegsGroups ]

(* Mass Quote Orders Placed Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteOrdersPlacedMessage ==
    { ZeroMassQuoteOrdersPlacedMessage }
        \cup { [ZeroMassQuoteOrdersPlacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteOrdersPlacedMessage EXCEPT !.massQuoteOrdersPlacedMessageOrdersGroups = one] : one \in CheckedMassQuoteOrdersPlacedMessageOrdersGroups }
        \cup { [ZeroMassQuoteOrdersPlacedMessage EXCEPT !.massQuoteOrdersPlacedMessageFillsGroups = one] : one \in CheckedMassQuoteOrdersPlacedMessageFillsGroups }
        \cup { [ZeroMassQuoteOrdersPlacedMessage EXCEPT !.massQuoteOrdersPlacedMessageLegsGroups = one] : one \in CheckedMassQuoteOrdersPlacedMessageLegsGroups }

(***************************************************************************)
(* Mass Quote Mmp Triggered Message: 57 bytes                              *)
(***************************************************************************)

MassQuoteMmpTriggeredMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      mmpGroupId    : Sample(8),
      frozenUntil   : Sample(8),
      quantityLevel : Sample(8),
      vegaLevel     : Sample(8),
      deltaLevel    : Sample(8),
      trigger       : Sample(1) ]

EncodeMassQuoteMmpTriggeredMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.mmpGroupId
        \o message.frozenUntil
        \o message.quantityLevel
        \o message.vegaLevel
        \o message.deltaLevel
        \o message.trigger

DecodeMassQuoteMmpTriggeredMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(execId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET frozenUntil == ReadBytes(mmpGroupId.rest, 8) IN IF ~frozenUntil.ok THEN Fail ELSE
    LET quantityLevel == ReadBytes(frozenUntil.rest, 8) IN IF ~quantityLevel.ok THEN Fail ELSE
    LET vegaLevel == ReadBytes(quantityLevel.rest, 8) IN IF ~vegaLevel.ok THEN Fail ELSE
    LET deltaLevel == ReadBytes(vegaLevel.rest, 8) IN IF ~deltaLevel.ok THEN Fail ELSE
    LET trigger == ReadBytes(deltaLevel.rest, 1) IN IF ~trigger.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         mmpGroupId    |-> mmpGroupId.value,
         frozenUntil   |-> frozenUntil.value,
         quantityLevel |-> quantityLevel.value,
         vegaLevel     |-> vegaLevel.value,
         deltaLevel    |-> deltaLevel.value,
         trigger       |-> trigger.value ], trigger.rest)

ZeroMassQuoteMmpTriggeredMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId    |-> [i \in 1 .. 8 |-> 0],
      frozenUntil   |-> [i \in 1 .. 8 |-> 0],
      quantityLevel |-> [i \in 1 .. 8 |-> 0],
      vegaLevel     |-> [i \in 1 .. 8 |-> 0],
      deltaLevel    |-> [i \in 1 .. 8 |-> 0],
      trigger       |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Mmp Triggered Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteMmpTriggeredMessage ==
    { ZeroMassQuoteMmpTriggeredMessage }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.frozenUntil = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.quantityLevel = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.vegaLevel = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.deltaLevel = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpTriggeredMessage EXCEPT !.trigger = one] : one \in Sample(1) }

(***************************************************************************)
(* Orders Mmp Triggered Message: 57 bytes                                  *)
(***************************************************************************)

OrdersMmpTriggeredMessage ==
    [ timestamp      : Sample(8),
      execId         : Sample(8),
      currencyPairId : Sample(8),
      frozenUntil    : Sample(8),
      quantityLevel  : Sample(8),
      vegaLevel      : Sample(8),
      deltaLevel     : Sample(8),
      trigger        : Sample(1) ]

EncodeOrdersMmpTriggeredMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.currencyPairId
        \o message.frozenUntil
        \o message.quantityLevel
        \o message.vegaLevel
        \o message.deltaLevel
        \o message.trigger

DecodeOrdersMmpTriggeredMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET currencyPairId == ReadBytes(execId.rest, 8) IN IF ~currencyPairId.ok THEN Fail ELSE
    LET frozenUntil == ReadBytes(currencyPairId.rest, 8) IN IF ~frozenUntil.ok THEN Fail ELSE
    LET quantityLevel == ReadBytes(frozenUntil.rest, 8) IN IF ~quantityLevel.ok THEN Fail ELSE
    LET vegaLevel == ReadBytes(quantityLevel.rest, 8) IN IF ~vegaLevel.ok THEN Fail ELSE
    LET deltaLevel == ReadBytes(vegaLevel.rest, 8) IN IF ~deltaLevel.ok THEN Fail ELSE
    LET trigger == ReadBytes(deltaLevel.rest, 1) IN IF ~trigger.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         execId         |-> execId.value,
         currencyPairId |-> currencyPairId.value,
         frozenUntil    |-> frozenUntil.value,
         quantityLevel  |-> quantityLevel.value,
         vegaLevel      |-> vegaLevel.value,
         deltaLevel     |-> deltaLevel.value,
         trigger        |-> trigger.value ], trigger.rest)

ZeroOrdersMmpTriggeredMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      execId         |-> [i \in 1 .. 8 |-> 0],
      currencyPairId |-> [i \in 1 .. 8 |-> 0],
      frozenUntil    |-> [i \in 1 .. 8 |-> 0],
      quantityLevel  |-> [i \in 1 .. 8 |-> 0],
      vegaLevel      |-> [i \in 1 .. 8 |-> 0],
      deltaLevel     |-> [i \in 1 .. 8 |-> 0],
      trigger        |-> [i \in 1 .. 1 |-> 0] ]

(* Orders Mmp Triggered Message at zero, then each field in turn at the values it is checked at *)
CheckedOrdersMmpTriggeredMessage ==
    { ZeroOrdersMmpTriggeredMessage }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.currencyPairId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.frozenUntil = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.quantityLevel = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.vegaLevel = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.deltaLevel = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpTriggeredMessage EXCEPT !.trigger = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Mmp Unfrozen Message: 32 bytes                               *)
(***************************************************************************)

MassQuoteMmpUnfrozenMessage ==
    [ timestamp             : Sample(8),
      execId                : Sample(8),
      mmpGroupId            : Sample(8),
      correlationIdOptional : Sample(8) ]

EncodeMassQuoteMmpUnfrozenMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.mmpGroupId
        \o message.correlationIdOptional

DecodeMassQuoteMmpUnfrozenMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET mmpGroupId == ReadBytes(execId.rest, 8) IN IF ~mmpGroupId.ok THEN Fail ELSE
    LET correlationIdOptional == ReadBytes(mmpGroupId.rest, 8) IN IF ~correlationIdOptional.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         execId                |-> execId.value,
         mmpGroupId            |-> mmpGroupId.value,
         correlationIdOptional |-> correlationIdOptional.value ], correlationIdOptional.rest)

ZeroMassQuoteMmpUnfrozenMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      mmpGroupId            |-> [i \in 1 .. 8 |-> 0],
      correlationIdOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Quote Mmp Unfrozen Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteMmpUnfrozenMessage ==
    { ZeroMassQuoteMmpUnfrozenMessage }
        \cup { [ZeroMassQuoteMmpUnfrozenMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpUnfrozenMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpUnfrozenMessage EXCEPT !.mmpGroupId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteMmpUnfrozenMessage EXCEPT !.correlationIdOptional = one] : one \in Sample(8) }

(***************************************************************************)
(* Orders Mmp Unfrozen Message: 32 bytes                                   *)
(***************************************************************************)

OrdersMmpUnfrozenMessage ==
    [ timestamp             : Sample(8),
      execId                : Sample(8),
      currencyPairId        : Sample(8),
      correlationIdOptional : Sample(8) ]

EncodeOrdersMmpUnfrozenMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.currencyPairId
        \o message.correlationIdOptional

DecodeOrdersMmpUnfrozenMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET currencyPairId == ReadBytes(execId.rest, 8) IN IF ~currencyPairId.ok THEN Fail ELSE
    LET correlationIdOptional == ReadBytes(currencyPairId.rest, 8) IN IF ~correlationIdOptional.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         execId                |-> execId.value,
         currencyPairId        |-> currencyPairId.value,
         correlationIdOptional |-> correlationIdOptional.value ], correlationIdOptional.rest)

ZeroOrdersMmpUnfrozenMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      currencyPairId        |-> [i \in 1 .. 8 |-> 0],
      correlationIdOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Orders Mmp Unfrozen Message at zero, then each field in turn at the values it is checked at *)
CheckedOrdersMmpUnfrozenMessage ==
    { ZeroOrdersMmpUnfrozenMessage }
        \cup { [ZeroOrdersMmpUnfrozenMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpUnfrozenMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpUnfrozenMessage EXCEPT !.currencyPairId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersMmpUnfrozenMessage EXCEPT !.correlationIdOptional = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

LogonMessageCode == 1  \* 0x01
LogonConfMessageCode == 2  \* 0x02
LogoutMessageCode == 4  \* 0x04
LoggedOutMessageCode == 5  \* 0x05
HeartbeatMessageCode == 10  \* 0x0a
TestRequestMessageCode == 11  \* 0x0b
ResendRequestMessageCode == 20  \* 0x14
GapFillMessageCode == 21  \* 0x15
RejectMessageCode == 30  \* 0x1e
NewOrderRequestMessageCode == 100  \* 0x64
AmendOrderRequestMessageCode == 110  \* 0x6e
CancelOrderRequestMessageCode == 120  \* 0x78
CancelOrderByIdRequestMessageCode == 125  \* 0x7d
MassQuoteRequestMessageCode == 130  \* 0x82
MassCancelRequestMessageCode == 140  \* 0x8c
MassQuoteCancelRequestMessageCode == 145  \* 0x91
GetMassQuoteMmpStatusRequestMessageCode == 155  \* 0x9b
GetOrdersMmpStatusRequestMessageCode == 156  \* 0x9c
NewOrderResponseMessageCode == 200  \* 0xc8
NewOrderRejectMessageCode == 202  \* 0xca
AmendOrderResponseMessageCode == 210  \* 0xd2
AmendOrderRejectMessageCode == 212  \* 0xd4
CancelOrderResponseMessageCode == 220  \* 0xdc
CancelOrderRejectMessageCode == 222  \* 0xde
MassQuoteResponseMessageCode == 230  \* 0xe6
MassQuoteRejectMessageCode == 232  \* 0xe8
MassCancelResponseMessageCode == 240  \* 0xf0
MassCancelRejectMessageCode == 242  \* 0xf2
GetMassQuoteMmpStatusResponseMessageCode == 280  \* 0x118
GetMassQuoteMmpStatusRejectMessageCode == 281  \* 0x119
GetOrdersMmpStatusResponseMessageCode == 282  \* 0x11a
GetOrdersMmpStatusRejectMessageCode == 283  \* 0x11b
OrderFilledMessageCode == 300  \* 0x12c
OrdersCanceledMessageCode == 310  \* 0x136
OrderPlacedMessageCode == 312  \* 0x138
MassQuoteOrdersPlacedMessageCode == 314  \* 0x13a
MassQuoteMmpTriggeredMessageCode == 320  \* 0x140
OrdersMmpTriggeredMessageCode == 322  \* 0x142
MassQuoteMmpUnfrozenMessageCode == 324  \* 0x144
OrdersMmpUnfrozenMessageCode == 326  \* 0x146

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonConfMessageCode}, body : LogonConfMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {LoggedOutMessageCode}, body : LoggedOutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {TestRequestMessageCode}, body : TestRequestMessage ]
        \cup [ tag : {ResendRequestMessageCode}, body : ResendRequestMessage ]
        \cup [ tag : {GapFillMessageCode}, body : GapFillMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {NewOrderRequestMessageCode}, body : NewOrderRequestMessage ]
        \cup [ tag : {AmendOrderRequestMessageCode}, body : AmendOrderRequestMessage ]
        \cup [ tag : {CancelOrderRequestMessageCode}, body : CancelOrderRequestMessage ]
        \cup [ tag : {CancelOrderByIdRequestMessageCode}, body : CancelOrderByIdRequestMessage ]
        \cup [ tag : {MassQuoteRequestMessageCode}, body : MassQuoteRequestMessage ]
        \cup [ tag : {MassCancelRequestMessageCode}, body : MassCancelRequestMessage ]
        \cup [ tag : {MassQuoteCancelRequestMessageCode}, body : MassQuoteCancelRequestMessage ]
        \cup [ tag : {GetMassQuoteMmpStatusRequestMessageCode}, body : GetMassQuoteMmpStatusRequestMessage ]
        \cup [ tag : {GetOrdersMmpStatusRequestMessageCode}, body : GetOrdersMmpStatusRequestMessage ]
        \cup [ tag : {NewOrderResponseMessageCode}, body : NewOrderResponseMessage ]
        \cup [ tag : {NewOrderRejectMessageCode}, body : NewOrderRejectMessage ]
        \cup [ tag : {AmendOrderResponseMessageCode}, body : AmendOrderResponseMessage ]
        \cup [ tag : {AmendOrderRejectMessageCode}, body : AmendOrderRejectMessage ]
        \cup [ tag : {CancelOrderResponseMessageCode}, body : CancelOrderResponseMessage ]
        \cup [ tag : {CancelOrderRejectMessageCode}, body : CancelOrderRejectMessage ]
        \cup [ tag : {MassQuoteResponseMessageCode}, body : MassQuoteResponseMessage ]
        \cup [ tag : {MassQuoteRejectMessageCode}, body : MassQuoteRejectMessage ]
        \cup [ tag : {MassCancelResponseMessageCode}, body : MassCancelResponseMessage ]
        \cup [ tag : {MassCancelRejectMessageCode}, body : MassCancelRejectMessage ]
        \cup [ tag : {GetMassQuoteMmpStatusResponseMessageCode}, body : GetMassQuoteMmpStatusResponseMessage ]
        \cup [ tag : {GetMassQuoteMmpStatusRejectMessageCode}, body : GetMassQuoteMmpStatusRejectMessage ]
        \cup [ tag : {GetOrdersMmpStatusResponseMessageCode}, body : GetOrdersMmpStatusResponseMessage ]
        \cup [ tag : {GetOrdersMmpStatusRejectMessageCode}, body : GetOrdersMmpStatusRejectMessage ]
        \cup [ tag : {OrderFilledMessageCode}, body : OrderFilledMessage ]
        \cup [ tag : {OrdersCanceledMessageCode}, body : OrdersCanceledMessage ]
        \cup [ tag : {OrderPlacedMessageCode}, body : OrderPlacedMessage ]
        \cup [ tag : {MassQuoteOrdersPlacedMessageCode}, body : MassQuoteOrdersPlacedMessage ]
        \cup [ tag : {MassQuoteMmpTriggeredMessageCode}, body : MassQuoteMmpTriggeredMessage ]
        \cup [ tag : {OrdersMmpTriggeredMessageCode}, body : OrdersMmpTriggeredMessage ]
        \cup [ tag : {MassQuoteMmpUnfrozenMessageCode}, body : MassQuoteMmpUnfrozenMessage ]
        \cup [ tag : {OrdersMmpUnfrozenMessageCode}, body : OrdersMmpUnfrozenMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonConfMessageCode -> EncodeLogonConfMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = LoggedOutMessageCode -> EncodeLoggedOutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = TestRequestMessageCode -> EncodeTestRequestMessage(message.body)
      [] message.tag = ResendRequestMessageCode -> EncodeResendRequestMessage(message.body)
      [] message.tag = GapFillMessageCode -> EncodeGapFillMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = NewOrderRequestMessageCode -> EncodeNewOrderRequestMessage(message.body)
      [] message.tag = AmendOrderRequestMessageCode -> EncodeAmendOrderRequestMessage(message.body)
      [] message.tag = CancelOrderRequestMessageCode -> EncodeCancelOrderRequestMessage(message.body)
      [] message.tag = CancelOrderByIdRequestMessageCode -> EncodeCancelOrderByIdRequestMessage(message.body)
      [] message.tag = MassQuoteRequestMessageCode -> EncodeMassQuoteRequestMessage(message.body)
      [] message.tag = MassCancelRequestMessageCode -> EncodeMassCancelRequestMessage(message.body)
      [] message.tag = MassQuoteCancelRequestMessageCode -> EncodeMassQuoteCancelRequestMessage(message.body)
      [] message.tag = GetMassQuoteMmpStatusRequestMessageCode -> EncodeGetMassQuoteMmpStatusRequestMessage(message.body)
      [] message.tag = GetOrdersMmpStatusRequestMessageCode -> EncodeGetOrdersMmpStatusRequestMessage(message.body)
      [] message.tag = NewOrderResponseMessageCode -> EncodeNewOrderResponseMessage(message.body)
      [] message.tag = NewOrderRejectMessageCode -> EncodeNewOrderRejectMessage(message.body)
      [] message.tag = AmendOrderResponseMessageCode -> EncodeAmendOrderResponseMessage(message.body)
      [] message.tag = AmendOrderRejectMessageCode -> EncodeAmendOrderRejectMessage(message.body)
      [] message.tag = CancelOrderResponseMessageCode -> EncodeCancelOrderResponseMessage(message.body)
      [] message.tag = CancelOrderRejectMessageCode -> EncodeCancelOrderRejectMessage(message.body)
      [] message.tag = MassQuoteResponseMessageCode -> EncodeMassQuoteResponseMessage(message.body)
      [] message.tag = MassQuoteRejectMessageCode -> EncodeMassQuoteRejectMessage(message.body)
      [] message.tag = MassCancelResponseMessageCode -> EncodeMassCancelResponseMessage(message.body)
      [] message.tag = MassCancelRejectMessageCode -> EncodeMassCancelRejectMessage(message.body)
      [] message.tag = GetMassQuoteMmpStatusResponseMessageCode -> EncodeGetMassQuoteMmpStatusResponseMessage(message.body)
      [] message.tag = GetMassQuoteMmpStatusRejectMessageCode -> EncodeGetMassQuoteMmpStatusRejectMessage(message.body)
      [] message.tag = GetOrdersMmpStatusResponseMessageCode -> EncodeGetOrdersMmpStatusResponseMessage(message.body)
      [] message.tag = GetOrdersMmpStatusRejectMessageCode -> EncodeGetOrdersMmpStatusRejectMessage(message.body)
      [] message.tag = OrderFilledMessageCode -> EncodeOrderFilledMessage(message.body)
      [] message.tag = OrdersCanceledMessageCode -> EncodeOrdersCanceledMessage(message.body)
      [] message.tag = OrderPlacedMessageCode -> EncodeOrderPlacedMessage(message.body)
      [] message.tag = MassQuoteOrdersPlacedMessageCode -> EncodeMassQuoteOrdersPlacedMessage(message.body)
      [] message.tag = MassQuoteMmpTriggeredMessageCode -> EncodeMassQuoteMmpTriggeredMessage(message.body)
      [] message.tag = OrdersMmpTriggeredMessageCode -> EncodeOrdersMmpTriggeredMessage(message.body)
      [] message.tag = MassQuoteMmpUnfrozenMessageCode -> EncodeMassQuoteMmpUnfrozenMessage(message.body)
      [] message.tag = OrdersMmpUnfrozenMessageCode -> EncodeOrdersMmpUnfrozenMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonConfMessageCode -> DecodeLogonConfMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = LoggedOutMessageCode -> DecodeLoggedOutMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = TestRequestMessageCode -> DecodeTestRequestMessage(bytes)
              [] tag = ResendRequestMessageCode -> DecodeResendRequestMessage(bytes)
              [] tag = GapFillMessageCode -> DecodeGapFillMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = NewOrderRequestMessageCode -> DecodeNewOrderRequestMessage(bytes)
              [] tag = AmendOrderRequestMessageCode -> DecodeAmendOrderRequestMessage(bytes)
              [] tag = CancelOrderRequestMessageCode -> DecodeCancelOrderRequestMessage(bytes)
              [] tag = CancelOrderByIdRequestMessageCode -> DecodeCancelOrderByIdRequestMessage(bytes)
              [] tag = MassQuoteRequestMessageCode -> DecodeMassQuoteRequestMessage(bytes)
              [] tag = MassCancelRequestMessageCode -> DecodeMassCancelRequestMessage(bytes)
              [] tag = MassQuoteCancelRequestMessageCode -> DecodeMassQuoteCancelRequestMessage(bytes)
              [] tag = GetMassQuoteMmpStatusRequestMessageCode -> DecodeGetMassQuoteMmpStatusRequestMessage(bytes)
              [] tag = GetOrdersMmpStatusRequestMessageCode -> DecodeGetOrdersMmpStatusRequestMessage(bytes)
              [] tag = NewOrderResponseMessageCode -> DecodeNewOrderResponseMessage(bytes)
              [] tag = NewOrderRejectMessageCode -> DecodeNewOrderRejectMessage(bytes)
              [] tag = AmendOrderResponseMessageCode -> DecodeAmendOrderResponseMessage(bytes)
              [] tag = AmendOrderRejectMessageCode -> DecodeAmendOrderRejectMessage(bytes)
              [] tag = CancelOrderResponseMessageCode -> DecodeCancelOrderResponseMessage(bytes)
              [] tag = CancelOrderRejectMessageCode -> DecodeCancelOrderRejectMessage(bytes)
              [] tag = MassQuoteResponseMessageCode -> DecodeMassQuoteResponseMessage(bytes)
              [] tag = MassQuoteRejectMessageCode -> DecodeMassQuoteRejectMessage(bytes)
              [] tag = MassCancelResponseMessageCode -> DecodeMassCancelResponseMessage(bytes)
              [] tag = MassCancelRejectMessageCode -> DecodeMassCancelRejectMessage(bytes)
              [] tag = GetMassQuoteMmpStatusResponseMessageCode -> DecodeGetMassQuoteMmpStatusResponseMessage(bytes)
              [] tag = GetMassQuoteMmpStatusRejectMessageCode -> DecodeGetMassQuoteMmpStatusRejectMessage(bytes)
              [] tag = GetOrdersMmpStatusResponseMessageCode -> DecodeGetOrdersMmpStatusResponseMessage(bytes)
              [] tag = GetOrdersMmpStatusRejectMessageCode -> DecodeGetOrdersMmpStatusRejectMessage(bytes)
              [] tag = OrderFilledMessageCode -> DecodeOrderFilledMessage(bytes)
              [] tag = OrdersCanceledMessageCode -> DecodeOrdersCanceledMessage(bytes)
              [] tag = OrderPlacedMessageCode -> DecodeOrderPlacedMessage(bytes)
              [] tag = MassQuoteOrdersPlacedMessageCode -> DecodeMassQuoteOrdersPlacedMessage(bytes)
              [] tag = MassQuoteMmpTriggeredMessageCode -> DecodeMassQuoteMmpTriggeredMessage(bytes)
              [] tag = OrdersMmpTriggeredMessageCode -> DecodeOrdersMmpTriggeredMessage(bytes)
              [] tag = MassQuoteMmpUnfrozenMessageCode -> DecodeMassQuoteMmpUnfrozenMessage(bytes)
              [] tag = OrdersMmpUnfrozenMessageCode -> DecodeOrdersMmpUnfrozenMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonConfMessageCode, body |-> one] : one \in CheckedLogonConfMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> LoggedOutMessageCode, body |-> one] : one \in CheckedLoggedOutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> TestRequestMessageCode, body |-> one] : one \in CheckedTestRequestMessage }
        \cup { [tag |-> ResendRequestMessageCode, body |-> one] : one \in CheckedResendRequestMessage }
        \cup { [tag |-> GapFillMessageCode, body |-> one] : one \in CheckedGapFillMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> NewOrderRequestMessageCode, body |-> one] : one \in CheckedNewOrderRequestMessage }
        \cup { [tag |-> AmendOrderRequestMessageCode, body |-> one] : one \in CheckedAmendOrderRequestMessage }
        \cup { [tag |-> CancelOrderRequestMessageCode, body |-> one] : one \in CheckedCancelOrderRequestMessage }
        \cup { [tag |-> CancelOrderByIdRequestMessageCode, body |-> one] : one \in CheckedCancelOrderByIdRequestMessage }
        \cup { [tag |-> MassQuoteRequestMessageCode, body |-> one] : one \in CheckedMassQuoteRequestMessage }
        \cup { [tag |-> MassCancelRequestMessageCode, body |-> one] : one \in CheckedMassCancelRequestMessage }
        \cup { [tag |-> MassQuoteCancelRequestMessageCode, body |-> one] : one \in CheckedMassQuoteCancelRequestMessage }
        \cup { [tag |-> GetMassQuoteMmpStatusRequestMessageCode, body |-> one] : one \in CheckedGetMassQuoteMmpStatusRequestMessage }
        \cup { [tag |-> GetOrdersMmpStatusRequestMessageCode, body |-> one] : one \in CheckedGetOrdersMmpStatusRequestMessage }
        \cup { [tag |-> NewOrderResponseMessageCode, body |-> one] : one \in CheckedNewOrderResponseMessage }
        \cup { [tag |-> NewOrderRejectMessageCode, body |-> one] : one \in CheckedNewOrderRejectMessage }
        \cup { [tag |-> AmendOrderResponseMessageCode, body |-> one] : one \in CheckedAmendOrderResponseMessage }
        \cup { [tag |-> AmendOrderRejectMessageCode, body |-> one] : one \in CheckedAmendOrderRejectMessage }
        \cup { [tag |-> CancelOrderResponseMessageCode, body |-> one] : one \in CheckedCancelOrderResponseMessage }
        \cup { [tag |-> CancelOrderRejectMessageCode, body |-> one] : one \in CheckedCancelOrderRejectMessage }
        \cup { [tag |-> MassQuoteResponseMessageCode, body |-> one] : one \in CheckedMassQuoteResponseMessage }
        \cup { [tag |-> MassQuoteRejectMessageCode, body |-> one] : one \in CheckedMassQuoteRejectMessage }
        \cup { [tag |-> MassCancelResponseMessageCode, body |-> one] : one \in CheckedMassCancelResponseMessage }
        \cup { [tag |-> MassCancelRejectMessageCode, body |-> one] : one \in CheckedMassCancelRejectMessage }
        \cup { [tag |-> GetMassQuoteMmpStatusResponseMessageCode, body |-> one] : one \in CheckedGetMassQuoteMmpStatusResponseMessage }
        \cup { [tag |-> GetMassQuoteMmpStatusRejectMessageCode, body |-> one] : one \in CheckedGetMassQuoteMmpStatusRejectMessage }
        \cup { [tag |-> GetOrdersMmpStatusResponseMessageCode, body |-> one] : one \in CheckedGetOrdersMmpStatusResponseMessage }
        \cup { [tag |-> GetOrdersMmpStatusRejectMessageCode, body |-> one] : one \in CheckedGetOrdersMmpStatusRejectMessage }
        \cup { [tag |-> OrderFilledMessageCode, body |-> one] : one \in CheckedOrderFilledMessage }
        \cup { [tag |-> OrdersCanceledMessageCode, body |-> one] : one \in CheckedOrdersCanceledMessage }
        \cup { [tag |-> OrderPlacedMessageCode, body |-> one] : one \in CheckedOrderPlacedMessage }
        \cup { [tag |-> MassQuoteOrdersPlacedMessageCode, body |-> one] : one \in CheckedMassQuoteOrdersPlacedMessage }
        \cup { [tag |-> MassQuoteMmpTriggeredMessageCode, body |-> one] : one \in CheckedMassQuoteMmpTriggeredMessage }
        \cup { [tag |-> OrdersMmpTriggeredMessageCode, body |-> one] : one \in CheckedOrdersMmpTriggeredMessage }
        \cup { [tag |-> MassQuoteMmpUnfrozenMessageCode, body |-> one] : one \in CheckedMassQuoteMmpUnfrozenMessage }
        \cup { [tag |-> OrdersMmpUnfrozenMessageCode, body |-> one] : one \in CheckedOrdersMmpUnfrozenMessage }

(***************************************************************************)
(* Sbe Message, framed by Message Length                                   *)
(***************************************************************************)

SbeMessage ==
    [ protocolId         : Sample(1),
      sessionFlags       : Sample(1),
      schemaVersion      : Sample(2),
      sequenceNumber     : Sample(8),
      lastProcessedSeqNo : Sample(8),
      sendTimeNs         : Sample(8),
      payload            : Payload,
      padding            : SampleBytes ]

EncodeSbeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaVersion
        \o message.sequenceNumber
        \o message.lastProcessedSeqNo
        \o message.sendTimeNs
        \o EncodePayload(message.payload)
        \o message.padding

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  message.protocolId \o message.sessionFlags \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeSbeMessage(bytes) ==
    LET protocolId == ReadBytes(bytes, 1) IN IF ~protocolId.ok THEN Fail ELSE
    LET sessionFlags == ReadBytes(protocolId.rest, 1) IN IF ~sessionFlags.ok THEN Fail ELSE
    LET length == ReadUIntLE(sessionFlags.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET templateId == ReadUIntLE(framed, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaVersion == ReadBytes(templateId.rest, 2) IN IF ~schemaVersion.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(schemaVersion.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET lastProcessedSeqNo == ReadBytes(sequenceNumber.rest, 8) IN IF ~lastProcessedSeqNo.ok THEN Fail ELSE
    LET sendTimeNs == ReadBytes(lastProcessedSeqNo.rest, 8) IN IF ~sendTimeNs.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, sendTimeNs.rest) IN IF ~payload.ok THEN Fail ELSE
    LET padding == Ok(payload.rest, << >>) IN IF ~padding.ok THEN Fail ELSE
    IF padding.rest # << >> THEN Fail ELSE
    Ok([ protocolId         |-> protocolId.value,
         sessionFlags       |-> sessionFlags.value,
         schemaVersion      |-> schemaVersion.value,
         sequenceNumber     |-> sequenceNumber.value,
         lastProcessedSeqNo |-> lastProcessedSeqNo.value,
         sendTimeNs         |-> sendTimeNs.value,
         payload            |-> payload.value,
         padding            |-> padding.value ], beyond)

ZeroSbeMessage ==
    [ protocolId         |-> [i \in 1 .. 1 |-> 0],
      sessionFlags       |-> [i \in 1 .. 1 |-> 0],
      schemaVersion      |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber     |-> [i \in 1 .. 8 |-> 0],
      lastProcessedSeqNo |-> [i \in 1 .. 8 |-> 0],
      sendTimeNs         |-> [i \in 1 .. 8 |-> 0],
      payload            |-> ZeroPayload,
      padding            |-> << >> ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.protocolId = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.sessionFlags = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaVersion = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSbeMessage EXCEPT !.lastProcessedSeqNo = one] : one \in Sample(8) }
        \cup { [ZeroSbeMessage EXCEPT !.sendTimeNs = one] : one \in Sample(8) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroSbeMessage EXCEPT !.padding = one] : one \in SampleBytes }

(* A run of Sbe Message, written one after another *)
RECURSIVE EncodeSbeMessageList(_)
EncodeSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeMessage(Head(messages)) \o EncodeSbeMessageList(Tail(messages))

(* As many Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSbeMessageAll(_)
ReadSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Message of each kind, for the lists that carry them *)
OneSbeMessage ==
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogonConfMessageCode, body |-> ZeroLogonConfMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoggedOutMessageCode, body |-> ZeroLoggedOutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TestRequestMessageCode, body |-> ZeroTestRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ResendRequestMessageCode, body |-> ZeroResendRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GapFillMessageCode, body |-> ZeroGapFillMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewOrderRequestMessageCode, body |-> ZeroNewOrderRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> AmendOrderRequestMessageCode, body |-> ZeroAmendOrderRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> CancelOrderRequestMessageCode, body |-> ZeroCancelOrderRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> CancelOrderByIdRequestMessageCode, body |-> ZeroCancelOrderByIdRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteRequestMessageCode, body |-> ZeroMassQuoteRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelRequestMessageCode, body |-> ZeroMassCancelRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteCancelRequestMessageCode, body |-> ZeroMassQuoteCancelRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GetMassQuoteMmpStatusRequestMessageCode, body |-> ZeroGetMassQuoteMmpStatusRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GetOrdersMmpStatusRequestMessageCode, body |-> ZeroGetOrdersMmpStatusRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewOrderResponseMessageCode, body |-> ZeroNewOrderResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewOrderRejectMessageCode, body |-> ZeroNewOrderRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> AmendOrderResponseMessageCode, body |-> ZeroAmendOrderResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> AmendOrderRejectMessageCode, body |-> ZeroAmendOrderRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> CancelOrderResponseMessageCode, body |-> ZeroCancelOrderResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> CancelOrderRejectMessageCode, body |-> ZeroCancelOrderRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteResponseMessageCode, body |-> ZeroMassQuoteResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteRejectMessageCode, body |-> ZeroMassQuoteRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelResponseMessageCode, body |-> ZeroMassCancelResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelRejectMessageCode, body |-> ZeroMassCancelRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GetMassQuoteMmpStatusResponseMessageCode, body |-> ZeroGetMassQuoteMmpStatusResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GetMassQuoteMmpStatusRejectMessageCode, body |-> ZeroGetMassQuoteMmpStatusRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GetOrdersMmpStatusResponseMessageCode, body |-> ZeroGetOrdersMmpStatusResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GetOrdersMmpStatusRejectMessageCode, body |-> ZeroGetOrdersMmpStatusRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderFilledMessageCode, body |-> ZeroOrderFilledMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrdersCanceledMessageCode, body |-> ZeroOrdersCanceledMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderPlacedMessageCode, body |-> ZeroOrderPlacedMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteOrdersPlacedMessageCode, body |-> ZeroMassQuoteOrdersPlacedMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteMmpTriggeredMessageCode, body |-> ZeroMassQuoteMmpTriggeredMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrdersMmpTriggeredMessageCode, body |-> ZeroOrdersMmpTriggeredMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassQuoteMmpUnfrozenMessageCode, body |-> ZeroMassQuoteMmpUnfrozenMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrdersMmpUnfrozenMessageCode, body |-> ZeroOrdersMmpUnfrozenMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sbeMessage : SampleLists(OneSbeMessage) ]

EncodePacket(message) ==
    EncodeSbeMessageList(message.sbeMessage)

DecodePacket(bytes) ==
    LET sbeMessage == ReadSbeMessageAll(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroPacket ==
    [ sbeMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Conf Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonConfMessage ==
    \A message \in CheckedLogonConfMessage :
        LET read == DecodeLogonConfMessage(EncodeLogonConfMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reason decodes back to what was encoded, and leaves nothing over *)
RoundTripReason ==
    \A message \in CheckedReason :
        LET read == DecodeReason(EncodeReason(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reason decodes back to what was encoded, and leaves nothing over *)
RoundTripReason2 ==
    \A message \in CheckedReason2 :
        LET read == DecodeReason2(EncodeReason2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logged Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoggedOutMessage ==
    \A message \in CheckedLoggedOutMessage :
        LET read == DecodeLoggedOutMessage(EncodeLoggedOutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestRequestMessage ==
    \A message \in CheckedTestRequestMessage :
        LET read == DecodeTestRequestMessage(EncodeTestRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendRequestMessage ==
    \A message \in CheckedResendRequestMessage :
        LET read == DecodeResendRequestMessage(EncodeResendRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gap Fill Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGapFillMessage ==
    \A message \in CheckedGapFillMessage :
        LET read == DecodeGapFillMessage(EncodeGapFillMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Details decodes back to what was encoded, and leaves nothing over *)
RoundTripDetails ==
    \A message \in CheckedDetails :
        LET read == DecodeDetails(EncodeDetails(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantity ==
    \A message \in CheckedQuantity :
        LET read == DecodeQuantity(EncodeQuantity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Show Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripShowQty ==
    \A message \in CheckedShowQty :
        LET read == DecodeShowQty(EncodeShowQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRequestMessage ==
    \A message \in CheckedNewOrderRequestMessage :
        LET read == DecodeNewOrderRequestMessage(EncodeNewOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantity2 ==
    \A message \in CheckedQuantity2 :
        LET read == DecodeQuantity2(EncodeQuantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Show Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripShowQty2 ==
    \A message \in CheckedShowQty2 :
        LET read == DecodeShowQty2(EncodeShowQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderRequestMessage ==
    \A message \in CheckedAmendOrderRequestMessage :
        LET read == DecodeAmendOrderRequestMessage(EncodeAmendOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRequestMessage ==
    \A message \in CheckedCancelOrderRequestMessage :
        LET read == DecodeCancelOrderRequestMessage(EncodeCancelOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order By Id Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderByIdRequestMessage ==
    \A message \in CheckedCancelOrderByIdRequestMessage :
        LET read == DecodeCancelOrderByIdRequestMessage(EncodeCancelOrderByIdRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQty ==
    \A message \in CheckedBidQty :
        LET read == DecodeBidQty(EncodeBidQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQty ==
    \A message \in CheckedAskQty :
        LET read == DecodeAskQty(EncodeAskQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request Message quotes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequestMessageQuotesGroup ==
    \A message \in CheckedMassQuoteRequestMessageQuotesGroup :
        LET read == DecodeMassQuoteRequestMessageQuotesGroup(EncodeMassQuoteRequestMessageQuotesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request Message quotes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequestMessageQuotesGroups ==
    \A message \in CheckedMassQuoteRequestMessageQuotesGroups :
        LET read == DecodeMassQuoteRequestMessageQuotesGroups(EncodeMassQuoteRequestMessageQuotesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequestMessage ==
    \A message \in CheckedMassQuoteRequestMessage :
        LET read == DecodeMassQuoteRequestMessage(EncodeMassQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequestMessage ==
    \A message \in CheckedMassCancelRequestMessage :
        LET read == DecodeMassCancelRequestMessage(EncodeMassCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteCancelRequestMessage ==
    \A message \in CheckedMassQuoteCancelRequestMessage :
        LET read == DecodeMassQuoteCancelRequestMessage(EncodeMassQuoteCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Get Mass Quote Mmp Status Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGetMassQuoteMmpStatusRequestMessage ==
    \A message \in CheckedGetMassQuoteMmpStatusRequestMessage :
        LET read == DecodeGetMassQuoteMmpStatusRequestMessage(EncodeGetMassQuoteMmpStatusRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Get Orders Mmp Status Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGetOrdersMmpStatusRequestMessage ==
    \A message \in CheckedGetOrdersMmpStatusRequestMessage :
        LET read == DecodeGetOrdersMmpStatusRequestMessage(EncodeGetOrdersMmpStatusRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantity3 ==
    \A message \in CheckedQuantity3 :
        LET read == DecodeQuantity3(EncodeQuantity3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Filled decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalFilled ==
    \A message \in CheckedTotalFilled :
        LET read == DecodeTotalFilled(EncodeTotalFilled(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Visible Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripVisibleQty ==
    \A message \in CheckedVisibleQty :
        LET read == DecodeVisibleQty(EncodeVisibleQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty ==
    \A message \in CheckedFillQty :
        LET read == DecodeFillQty(EncodeFillQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessageFillsGroup ==
    \A message \in CheckedNewOrderResponseMessageFillsGroup :
        LET read == DecodeNewOrderResponseMessageFillsGroup(EncodeNewOrderResponseMessageFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessageFillsGroups ==
    \A message \in CheckedNewOrderResponseMessageFillsGroups :
        LET read == DecodeNewOrderResponseMessageFillsGroups(EncodeNewOrderResponseMessageFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty2 ==
    \A message \in CheckedFillQty2 :
        LET read == DecodeFillQty2(EncodeFillQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessageLegsGroup ==
    \A message \in CheckedNewOrderResponseMessageLegsGroup :
        LET read == DecodeNewOrderResponseMessageLegsGroup(EncodeNewOrderResponseMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessageLegsGroups ==
    \A message \in CheckedNewOrderResponseMessageLegsGroups :
        LET read == DecodeNewOrderResponseMessageLegsGroups(EncodeNewOrderResponseMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessage ==
    \A message \in CheckedNewOrderResponseMessage :
        LET read == DecodeNewOrderResponseMessage(EncodeNewOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Details decodes back to what was encoded, and leaves nothing over *)
RoundTripDetails2 ==
    \A message \in CheckedDetails2 :
        LET read == DecodeDetails2(EncodeDetails2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRejectMessage ==
    \A message \in CheckedNewOrderRejectMessage :
        LET read == DecodeNewOrderRejectMessage(EncodeNewOrderRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantity4 ==
    \A message \in CheckedQuantity4 :
        LET read == DecodeQuantity4(EncodeQuantity4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Filled decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalFilled2 ==
    \A message \in CheckedTotalFilled2 :
        LET read == DecodeTotalFilled2(EncodeTotalFilled2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Visible Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripVisibleQty2 ==
    \A message \in CheckedVisibleQty2 :
        LET read == DecodeVisibleQty2(EncodeVisibleQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty3 ==
    \A message \in CheckedFillQty3 :
        LET read == DecodeFillQty3(EncodeFillQty3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Response Message fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderResponseMessageFillsGroup ==
    \A message \in CheckedAmendOrderResponseMessageFillsGroup :
        LET read == DecodeAmendOrderResponseMessageFillsGroup(EncodeAmendOrderResponseMessageFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Response Message fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderResponseMessageFillsGroups ==
    \A message \in CheckedAmendOrderResponseMessageFillsGroups :
        LET read == DecodeAmendOrderResponseMessageFillsGroups(EncodeAmendOrderResponseMessageFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty4 ==
    \A message \in CheckedFillQty4 :
        LET read == DecodeFillQty4(EncodeFillQty4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Response Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderResponseMessageLegsGroup ==
    \A message \in CheckedAmendOrderResponseMessageLegsGroup :
        LET read == DecodeAmendOrderResponseMessageLegsGroup(EncodeAmendOrderResponseMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Response Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderResponseMessageLegsGroups ==
    \A message \in CheckedAmendOrderResponseMessageLegsGroups :
        LET read == DecodeAmendOrderResponseMessageLegsGroups(EncodeAmendOrderResponseMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderResponseMessage ==
    \A message \in CheckedAmendOrderResponseMessage :
        LET read == DecodeAmendOrderResponseMessage(EncodeAmendOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Details decodes back to what was encoded, and leaves nothing over *)
RoundTripDetails3 ==
    \A message \in CheckedDetails3 :
        LET read == DecodeDetails3(EncodeDetails3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderRejectMessage ==
    \A message \in CheckedAmendOrderRejectMessage :
        LET read == DecodeAmendOrderRejectMessage(EncodeAmendOrderRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderResponseMessage ==
    \A message \in CheckedCancelOrderResponseMessage :
        LET read == DecodeCancelOrderResponseMessage(EncodeCancelOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Details decodes back to what was encoded, and leaves nothing over *)
RoundTripDetails4 ==
    \A message \in CheckedDetails4 :
        LET read == DecodeDetails4(EncodeDetails4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRejectMessage ==
    \A message \in CheckedCancelOrderRejectMessage :
        LET read == DecodeCancelOrderRejectMessage(EncodeCancelOrderRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQty2 ==
    \A message \in CheckedBidQty2 :
        LET read == DecodeBidQty2(EncodeBidQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQty2 ==
    \A message \in CheckedAskQty2 :
        LET read == DecodeAskQty2(EncodeAskQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Filled Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripBidFilledQty ==
    \A message \in CheckedBidFilledQty :
        LET read == DecodeBidFilledQty(EncodeBidFilledQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Filled Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripAskFilledQty ==
    \A message \in CheckedAskFilledQty :
        LET read == DecodeAskFilledQty(EncodeAskFilledQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message quotes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageQuotesGroup ==
    \A message \in CheckedMassQuoteResponseMessageQuotesGroup :
        LET read == DecodeMassQuoteResponseMessageQuotesGroup(EncodeMassQuoteResponseMessageQuotesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message quotes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageQuotesGroups ==
    \A message \in CheckedMassQuoteResponseMessageQuotesGroups :
        LET read == DecodeMassQuoteResponseMessageQuotesGroups(EncodeMassQuoteResponseMessageQuotesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty5 ==
    \A message \in CheckedFillQty5 :
        LET read == DecodeFillQty5(EncodeFillQty5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message bid Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageBidFillsGroup ==
    \A message \in CheckedMassQuoteResponseMessageBidFillsGroup :
        LET read == DecodeMassQuoteResponseMessageBidFillsGroup(EncodeMassQuoteResponseMessageBidFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message bid Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageBidFillsGroups ==
    \A message \in CheckedMassQuoteResponseMessageBidFillsGroups :
        LET read == DecodeMassQuoteResponseMessageBidFillsGroups(EncodeMassQuoteResponseMessageBidFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty6 ==
    \A message \in CheckedFillQty6 :
        LET read == DecodeFillQty6(EncodeFillQty6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message ask Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageAskFillsGroup ==
    \A message \in CheckedMassQuoteResponseMessageAskFillsGroup :
        LET read == DecodeMassQuoteResponseMessageAskFillsGroup(EncodeMassQuoteResponseMessageAskFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message ask Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageAskFillsGroups ==
    \A message \in CheckedMassQuoteResponseMessageAskFillsGroups :
        LET read == DecodeMassQuoteResponseMessageAskFillsGroups(EncodeMassQuoteResponseMessageAskFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty7 ==
    \A message \in CheckedFillQty7 :
        LET read == DecodeFillQty7(EncodeFillQty7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageLegsGroup ==
    \A message \in CheckedMassQuoteResponseMessageLegsGroup :
        LET read == DecodeMassQuoteResponseMessageLegsGroup(EncodeMassQuoteResponseMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessageLegsGroups ==
    \A message \in CheckedMassQuoteResponseMessageLegsGroups :
        LET read == DecodeMassQuoteResponseMessageLegsGroups(EncodeMassQuoteResponseMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponseMessage ==
    \A message \in CheckedMassQuoteResponseMessage :
        LET read == DecodeMassQuoteResponseMessage(EncodeMassQuoteResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Details decodes back to what was encoded, and leaves nothing over *)
RoundTripDetails5 ==
    \A message \in CheckedDetails5 :
        LET read == DecodeDetails5(EncodeDetails5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRejectMessage ==
    \A message \in CheckedMassQuoteRejectMessage :
        LET read == DecodeMassQuoteRejectMessage(EncodeMassQuoteRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponseMessage ==
    \A message \in CheckedMassCancelResponseMessage :
        LET read == DecodeMassCancelResponseMessage(EncodeMassCancelResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Details decodes back to what was encoded, and leaves nothing over *)
RoundTripDetails6 ==
    \A message \in CheckedDetails6 :
        LET read == DecodeDetails6(EncodeDetails6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRejectMessage ==
    \A message \in CheckedMassCancelRejectMessage :
        LET read == DecodeMassCancelRejectMessage(EncodeMassCancelRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Get Mass Quote Mmp Status Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGetMassQuoteMmpStatusResponseMessage ==
    \A message \in CheckedGetMassQuoteMmpStatusResponseMessage :
        LET read == DecodeGetMassQuoteMmpStatusResponseMessage(EncodeGetMassQuoteMmpStatusResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Get Mass Quote Mmp Status Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGetMassQuoteMmpStatusRejectMessage ==
    \A message \in CheckedGetMassQuoteMmpStatusRejectMessage :
        LET read == DecodeGetMassQuoteMmpStatusRejectMessage(EncodeGetMassQuoteMmpStatusRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Get Orders Mmp Status Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGetOrdersMmpStatusResponseMessage ==
    \A message \in CheckedGetOrdersMmpStatusResponseMessage :
        LET read == DecodeGetOrdersMmpStatusResponseMessage(EncodeGetOrdersMmpStatusResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Get Orders Mmp Status Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGetOrdersMmpStatusRejectMessage ==
    \A message \in CheckedGetOrdersMmpStatusRejectMessage :
        LET read == DecodeGetOrdersMmpStatusRejectMessage(EncodeGetOrdersMmpStatusRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty8 ==
    \A message \in CheckedFillQty8 :
        LET read == DecodeFillQty8(EncodeFillQty8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Filled decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalFilled3 ==
    \A message \in CheckedTotalFilled3 :
        LET read == DecodeTotalFilled3(EncodeTotalFilled3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Filled Message fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderFilledMessageFillsGroup ==
    \A message \in CheckedOrderFilledMessageFillsGroup :
        LET read == DecodeOrderFilledMessageFillsGroup(EncodeOrderFilledMessageFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Filled Message fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderFilledMessageFillsGroups ==
    \A message \in CheckedOrderFilledMessageFillsGroups :
        LET read == DecodeOrderFilledMessageFillsGroups(EncodeOrderFilledMessageFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty9 ==
    \A message \in CheckedFillQty9 :
        LET read == DecodeFillQty9(EncodeFillQty9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Filled Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderFilledMessageLegsGroup ==
    \A message \in CheckedOrderFilledMessageLegsGroup :
        LET read == DecodeOrderFilledMessageLegsGroup(EncodeOrderFilledMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Filled Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderFilledMessageLegsGroups ==
    \A message \in CheckedOrderFilledMessageLegsGroups :
        LET read == DecodeOrderFilledMessageLegsGroups(EncodeOrderFilledMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderFilledMessage ==
    \A message \in CheckedOrderFilledMessage :
        LET read == DecodeOrderFilledMessage(EncodeOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Filled decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalFilled4 ==
    \A message \in CheckedTotalFilled4 :
        LET read == DecodeTotalFilled4(EncodeTotalFilled4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders Canceled Message orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrdersCanceledMessageOrdersGroup ==
    \A message \in CheckedOrdersCanceledMessageOrdersGroup :
        LET read == DecodeOrdersCanceledMessageOrdersGroup(EncodeOrdersCanceledMessageOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders Canceled Message orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrdersCanceledMessageOrdersGroups ==
    \A message \in CheckedOrdersCanceledMessageOrdersGroups :
        LET read == DecodeOrdersCanceledMessageOrdersGroups(EncodeOrdersCanceledMessageOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrdersCanceledMessage ==
    \A message \in CheckedOrdersCanceledMessage :
        LET read == DecodeOrdersCanceledMessage(EncodeOrdersCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantity5 ==
    \A message \in CheckedQuantity5 :
        LET read == DecodeQuantity5(EncodeQuantity5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Filled decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalFilled5 ==
    \A message \in CheckedTotalFilled5 :
        LET read == DecodeTotalFilled5(EncodeTotalFilled5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Visible Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripVisibleQty3 ==
    \A message \in CheckedVisibleQty3 :
        LET read == DecodeVisibleQty3(EncodeVisibleQty3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty10 ==
    \A message \in CheckedFillQty10 :
        LET read == DecodeFillQty10(EncodeFillQty10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Placed Message fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPlacedMessageFillsGroup ==
    \A message \in CheckedOrderPlacedMessageFillsGroup :
        LET read == DecodeOrderPlacedMessageFillsGroup(EncodeOrderPlacedMessageFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Placed Message fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPlacedMessageFillsGroups ==
    \A message \in CheckedOrderPlacedMessageFillsGroups :
        LET read == DecodeOrderPlacedMessageFillsGroups(EncodeOrderPlacedMessageFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty11 ==
    \A message \in CheckedFillQty11 :
        LET read == DecodeFillQty11(EncodeFillQty11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Placed Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPlacedMessageLegsGroup ==
    \A message \in CheckedOrderPlacedMessageLegsGroup :
        LET read == DecodeOrderPlacedMessageLegsGroup(EncodeOrderPlacedMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Placed Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPlacedMessageLegsGroups ==
    \A message \in CheckedOrderPlacedMessageLegsGroups :
        LET read == DecodeOrderPlacedMessageLegsGroups(EncodeOrderPlacedMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Placed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPlacedMessage ==
    \A message \in CheckedOrderPlacedMessage :
        LET read == DecodeOrderPlacedMessage(EncodeOrderPlacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantity6 ==
    \A message \in CheckedQuantity6 :
        LET read == DecodeQuantity6(EncodeQuantity6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Total Filled decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalFilled6 ==
    \A message \in CheckedTotalFilled6 :
        LET read == DecodeTotalFilled6(EncodeTotalFilled6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Visible Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripVisibleQty4 ==
    \A message \in CheckedVisibleQty4 :
        LET read == DecodeVisibleQty4(EncodeVisibleQty4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessageOrdersGroup ==
    \A message \in CheckedMassQuoteOrdersPlacedMessageOrdersGroup :
        LET read == DecodeMassQuoteOrdersPlacedMessageOrdersGroup(EncodeMassQuoteOrdersPlacedMessageOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessageOrdersGroups ==
    \A message \in CheckedMassQuoteOrdersPlacedMessageOrdersGroups :
        LET read == DecodeMassQuoteOrdersPlacedMessageOrdersGroups(EncodeMassQuoteOrdersPlacedMessageOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty12 ==
    \A message \in CheckedFillQty12 :
        LET read == DecodeFillQty12(EncodeFillQty12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessageFillsGroup ==
    \A message \in CheckedMassQuoteOrdersPlacedMessageFillsGroup :
        LET read == DecodeMassQuoteOrdersPlacedMessageFillsGroup(EncodeMassQuoteOrdersPlacedMessageFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessageFillsGroups ==
    \A message \in CheckedMassQuoteOrdersPlacedMessageFillsGroups :
        LET read == DecodeMassQuoteOrdersPlacedMessageFillsGroups(EncodeMassQuoteOrdersPlacedMessageFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripFillQty13 ==
    \A message \in CheckedFillQty13 :
        LET read == DecodeFillQty13(EncodeFillQty13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessageLegsGroup ==
    \A message \in CheckedMassQuoteOrdersPlacedMessageLegsGroup :
        LET read == DecodeMassQuoteOrdersPlacedMessageLegsGroup(EncodeMassQuoteOrdersPlacedMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessageLegsGroups ==
    \A message \in CheckedMassQuoteOrdersPlacedMessageLegsGroups :
        LET read == DecodeMassQuoteOrdersPlacedMessageLegsGroups(EncodeMassQuoteOrdersPlacedMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Orders Placed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteOrdersPlacedMessage ==
    \A message \in CheckedMassQuoteOrdersPlacedMessage :
        LET read == DecodeMassQuoteOrdersPlacedMessage(EncodeMassQuoteOrdersPlacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Mmp Triggered Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteMmpTriggeredMessage ==
    \A message \in CheckedMassQuoteMmpTriggeredMessage :
        LET read == DecodeMassQuoteMmpTriggeredMessage(EncodeMassQuoteMmpTriggeredMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders Mmp Triggered Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrdersMmpTriggeredMessage ==
    \A message \in CheckedOrdersMmpTriggeredMessage :
        LET read == DecodeOrdersMmpTriggeredMessage(EncodeOrdersMmpTriggeredMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Mmp Unfrozen Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteMmpUnfrozenMessage ==
    \A message \in CheckedMassQuoteMmpUnfrozenMessage :
        LET read == DecodeMassQuoteMmpUnfrozenMessage(EncodeMassQuoteMmpUnfrozenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders Mmp Unfrozen Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrdersMmpUnfrozenMessage ==
    \A message \in CheckedOrdersMmpUnfrozenMessage :
        LET read == DecodeOrdersMmpUnfrozenMessage(EncodeOrdersMmpUnfrozenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
