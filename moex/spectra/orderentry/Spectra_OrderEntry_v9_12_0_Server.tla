----------------- MODULE Spectra_OrderEntry_v9_12_0_Server -----------------
(***************************************************************************)
(* Moscow Exchange TWIME Spectra Order Entry v9.12.0                       *)
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
(* Establishment Ack Message: 20 bytes                                     *)
(***************************************************************************)

EstablishmentAckMessage ==
    [ requestTimestamp  : Sample(8),
      keepaliveInterval : Sample(4),
      nextSeqNo         : Sample(8) ]

EncodeEstablishmentAckMessage(message) ==
    message.requestTimestamp
        \o message.keepaliveInterval
        \o message.nextSeqNo

DecodeEstablishmentAckMessage(bytes) ==
    LET requestTimestamp == ReadBytes(bytes, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET keepaliveInterval == ReadBytes(requestTimestamp.rest, 4) IN IF ~keepaliveInterval.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(keepaliveInterval.rest, 8) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ requestTimestamp  |-> requestTimestamp.value,
         keepaliveInterval |-> keepaliveInterval.value,
         nextSeqNo         |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroEstablishmentAckMessage ==
    [ requestTimestamp  |-> [i \in 1 .. 8 |-> 0],
      keepaliveInterval |-> [i \in 1 .. 4 |-> 0],
      nextSeqNo         |-> [i \in 1 .. 8 |-> 0] ]

(* Establishment Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedEstablishmentAckMessage ==
    { ZeroEstablishmentAckMessage }
        \cup { [ZeroEstablishmentAckMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentAckMessage EXCEPT !.keepaliveInterval = one] : one \in Sample(4) }
        \cup { [ZeroEstablishmentAckMessage EXCEPT !.nextSeqNo = one] : one \in Sample(8) }

(***************************************************************************)
(* Establishment Reject Message: 9 bytes                                   *)
(***************************************************************************)

EstablishmentRejectMessage ==
    [ requestTimestamp        : Sample(8),
      establishmentRejectCode : Sample(1) ]

EncodeEstablishmentRejectMessage(message) ==
    message.requestTimestamp
        \o message.establishmentRejectCode

DecodeEstablishmentRejectMessage(bytes) ==
    LET requestTimestamp == ReadBytes(bytes, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET establishmentRejectCode == ReadBytes(requestTimestamp.rest, 1) IN IF ~establishmentRejectCode.ok THEN Fail ELSE
    Ok([ requestTimestamp        |-> requestTimestamp.value,
         establishmentRejectCode |-> establishmentRejectCode.value ], establishmentRejectCode.rest)

ZeroEstablishmentRejectMessage ==
    [ requestTimestamp        |-> [i \in 1 .. 8 |-> 0],
      establishmentRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Establishment Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedEstablishmentRejectMessage ==
    { ZeroEstablishmentRejectMessage }
        \cup { [ZeroEstablishmentRejectMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentRejectMessage EXCEPT !.establishmentRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Terminate Message: 1 bytes                                              *)
(***************************************************************************)

TerminateMessage ==
    [ terminationCode : Sample(1) ]

EncodeTerminateMessage(message) ==
    message.terminationCode

DecodeTerminateMessage(bytes) ==
    LET terminationCode == ReadBytes(bytes, 1) IN IF ~terminationCode.ok THEN Fail ELSE
    Ok([ terminationCode |-> terminationCode.value ], terminationCode.rest)

ZeroTerminateMessage ==
    [ terminationCode |-> [i \in 1 .. 1 |-> 0] ]

(* Terminate Message at zero, then each field in turn at the values it is checked at *)
CheckedTerminateMessage ==
    { ZeroTerminateMessage }
        \cup { [ZeroTerminateMessage EXCEPT !.terminationCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Message: 20 bytes                                        *)
(***************************************************************************)

RetransmissionMessage ==
    [ nextSeqNo        : Sample(8),
      requestTimestamp : Sample(8),
      count            : Sample(4) ]

EncodeRetransmissionMessage(message) ==
    message.nextSeqNo
        \o message.requestTimestamp
        \o message.count

DecodeRetransmissionMessage(bytes) ==
    LET nextSeqNo == ReadBytes(bytes, 8) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(nextSeqNo.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET count == ReadBytes(requestTimestamp.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ nextSeqNo        |-> nextSeqNo.value,
         requestTimestamp |-> requestTimestamp.value,
         count            |-> count.value ], count.rest)

ZeroRetransmissionMessage ==
    [ nextSeqNo        |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      count            |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionMessage ==
    { ZeroRetransmissionMessage }
        \cup { [ZeroRetransmissionMessage EXCEPT !.nextSeqNo = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequence Message: 8 bytes                                               *)
(***************************************************************************)

SequenceMessage ==
    [ nextSeqNo : Sample(8) ]

EncodeSequenceMessage(message) ==
    message.nextSeqNo

DecodeSequenceMessage(bytes) ==
    LET nextSeqNo == ReadBytes(bytes, 8) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ nextSeqNo |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroSequenceMessage ==
    [ nextSeqNo |-> [i \in 1 .. 8 |-> 0] ]

(* Sequence Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceMessage ==
    { ZeroSequenceMessage }
        \cup { [ZeroSequenceMessage EXCEPT !.nextSeqNo = one] : one \in Sample(8) }

(***************************************************************************)
(* Flood Reject Message: 16 bytes                                          *)
(***************************************************************************)

FloodRejectMessage ==
    [ clOrdId       : Sample(8),
      queueSize     : Sample(4),
      penaltyRemain : Sample(4) ]

EncodeFloodRejectMessage(message) ==
    message.clOrdId
        \o message.queueSize
        \o message.penaltyRemain

DecodeFloodRejectMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET queueSize == ReadBytes(clOrdId.rest, 4) IN IF ~queueSize.ok THEN Fail ELSE
    LET penaltyRemain == ReadBytes(queueSize.rest, 4) IN IF ~penaltyRemain.ok THEN Fail ELSE
    Ok([ clOrdId       |-> clOrdId.value,
         queueSize     |-> queueSize.value,
         penaltyRemain |-> penaltyRemain.value ], penaltyRemain.rest)

ZeroFloodRejectMessage ==
    [ clOrdId       |-> [i \in 1 .. 8 |-> 0],
      queueSize     |-> [i \in 1 .. 4 |-> 0],
      penaltyRemain |-> [i \in 1 .. 4 |-> 0] ]

(* Flood Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedFloodRejectMessage ==
    { ZeroFloodRejectMessage }
        \cup { [ZeroFloodRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroFloodRejectMessage EXCEPT !.queueSize = one] : one \in Sample(4) }
        \cup { [ZeroFloodRejectMessage EXCEPT !.penaltyRemain = one] : one \in Sample(4) }

(***************************************************************************)
(* Session Reject Message: 13 bytes                                        *)
(***************************************************************************)

SessionRejectMessage ==
    [ clOrdId             : Sample(8),
      refTagId            : Sample(4),
      sessionRejectReason : Sample(1) ]

EncodeSessionRejectMessage(message) ==
    message.clOrdId
        \o message.refTagId
        \o message.sessionRejectReason

DecodeSessionRejectMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET refTagId == ReadBytes(clOrdId.rest, 4) IN IF ~refTagId.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(refTagId.rest, 1) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    Ok([ clOrdId             |-> clOrdId.value,
         refTagId            |-> refTagId.value,
         sessionRejectReason |-> sessionRejectReason.value ], sessionRejectReason.rest)

ZeroSessionRejectMessage ==
    [ clOrdId             |-> [i \in 1 .. 8 |-> 0],
      refTagId            |-> [i \in 1 .. 4 |-> 0],
      sessionRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Session Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionRejectMessage ==
    { ZeroSessionRejectMessage }
        \cup { [ZeroSessionRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroSessionRejectMessage EXCEPT !.refTagId = one] : one \in Sample(4) }
        \cup { [ZeroSessionRejectMessage EXCEPT !.sessionRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Business Message Reject Message: 20 bytes                               *)
(***************************************************************************)

BusinessMessageRejectMessage ==
    [ clOrdId      : Sample(8),
      timestamp    : Sample(8),
      ordRejReason : Sample(4) ]

EncodeBusinessMessageRejectMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.ordRejReason

DecodeBusinessMessageRejectMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(timestamp.rest, 4) IN IF ~ordRejReason.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         timestamp    |-> timestamp.value,
         ordRejReason |-> ordRejReason.value ], ordRejReason.rest)

ZeroBusinessMessageRejectMessage ==
    [ clOrdId      |-> [i \in 1 .. 8 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      ordRejReason |-> [i \in 1 .. 4 |-> 0] ]

(* Business Message Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessMessageRejectMessage ==
    { ZeroBusinessMessageRejectMessage }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.ordRejReason = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Single Response Message: 74 bytes                             *)
(***************************************************************************)

NewOrderSingleResponseMessage ==
    [ clOrdId          : Sample(8),
      timestamp        : Sample(8),
      expireDate       : Sample(8),
      orderId          : Sample(8),
      flags            : Sample(8),
      flags2           : Sample(8),
      price            : Sample(8),
      securityId       : Sample(4),
      orderQty         : Sample(4),
      tradingSessionId : Sample(4),
      clOrdLinkId      : Sample(4),
      side             : Sample(1),
      complianceId     : Sample(1) ]

EncodeNewOrderSingleResponseMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.expireDate
        \o message.orderId
        \o message.flags
        \o message.flags2
        \o message.price
        \o message.securityId
        \o message.orderQty
        \o message.tradingSessionId
        \o message.clOrdLinkId
        \o message.side
        \o message.complianceId

DecodeNewOrderSingleResponseMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET expireDate == ReadBytes(timestamp.rest, 8) IN IF ~expireDate.ok THEN Fail ELSE
    LET orderId == ReadBytes(expireDate.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET flags == ReadBytes(orderId.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET flags2 == ReadBytes(flags.rest, 8) IN IF ~flags2.ok THEN Fail ELSE
    LET price == ReadBytes(flags2.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET securityId == ReadBytes(price.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(tradingSessionId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdLinkId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET complianceId == ReadBytes(side.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    Ok([ clOrdId          |-> clOrdId.value,
         timestamp        |-> timestamp.value,
         expireDate       |-> expireDate.value,
         orderId          |-> orderId.value,
         flags            |-> flags.value,
         flags2           |-> flags2.value,
         price            |-> price.value,
         securityId       |-> securityId.value,
         orderQty         |-> orderQty.value,
         tradingSessionId |-> tradingSessionId.value,
         clOrdLinkId      |-> clOrdLinkId.value,
         side             |-> side.value,
         complianceId     |-> complianceId.value ], complianceId.rest)

ZeroNewOrderSingleResponseMessage ==
    [ clOrdId          |-> [i \in 1 .. 8 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      expireDate       |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      flags            |-> [i \in 1 .. 8 |-> 0],
      flags2           |-> [i \in 1 .. 8 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 4 |-> 0],
      orderQty         |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId      |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      complianceId     |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Single Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleResponseMessage ==
    { ZeroNewOrderSingleResponseMessage }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.expireDate = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.flags2 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleResponseMessage EXCEPT !.complianceId = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Iceberg Response Message: 90 bytes                            *)
(***************************************************************************)

NewOrderIcebergResponseMessage ==
    [ clOrdId            : Sample(8),
      timestamp          : Sample(8),
      expireDate         : Sample(8),
      orderId            : Sample(8),
      displayOrderId     : Sample(8),
      flags              : Sample(8),
      flags2             : Sample(8),
      price              : Sample(8),
      securityId         : Sample(4),
      orderQty           : Sample(4),
      displayQty         : Sample(4),
      displayVarianceQty : Sample(4),
      tradingSessionId   : Sample(4),
      clOrdLinkId        : Sample(4),
      side               : Sample(1),
      complianceId       : Sample(1) ]

EncodeNewOrderIcebergResponseMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.expireDate
        \o message.orderId
        \o message.displayOrderId
        \o message.flags
        \o message.flags2
        \o message.price
        \o message.securityId
        \o message.orderQty
        \o message.displayQty
        \o message.displayVarianceQty
        \o message.tradingSessionId
        \o message.clOrdLinkId
        \o message.side
        \o message.complianceId

DecodeNewOrderIcebergResponseMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET expireDate == ReadBytes(timestamp.rest, 8) IN IF ~expireDate.ok THEN Fail ELSE
    LET orderId == ReadBytes(expireDate.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET displayOrderId == ReadBytes(orderId.rest, 8) IN IF ~displayOrderId.ok THEN Fail ELSE
    LET flags == ReadBytes(displayOrderId.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET flags2 == ReadBytes(flags.rest, 8) IN IF ~flags2.ok THEN Fail ELSE
    LET price == ReadBytes(flags2.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET securityId == ReadBytes(price.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayVarianceQty == ReadBytes(displayQty.rest, 4) IN IF ~displayVarianceQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(displayVarianceQty.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(tradingSessionId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdLinkId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET complianceId == ReadBytes(side.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         timestamp          |-> timestamp.value,
         expireDate         |-> expireDate.value,
         orderId            |-> orderId.value,
         displayOrderId     |-> displayOrderId.value,
         flags              |-> flags.value,
         flags2             |-> flags2.value,
         price              |-> price.value,
         securityId         |-> securityId.value,
         orderQty           |-> orderQty.value,
         displayQty         |-> displayQty.value,
         displayVarianceQty |-> displayVarianceQty.value,
         tradingSessionId   |-> tradingSessionId.value,
         clOrdLinkId        |-> clOrdLinkId.value,
         side               |-> side.value,
         complianceId       |-> complianceId.value ], complianceId.rest)

ZeroNewOrderIcebergResponseMessage ==
    [ clOrdId            |-> [i \in 1 .. 8 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      expireDate         |-> [i \in 1 .. 8 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      displayOrderId     |-> [i \in 1 .. 8 |-> 0],
      flags              |-> [i \in 1 .. 8 |-> 0],
      flags2             |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      securityId         |-> [i \in 1 .. 4 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      displayQty         |-> [i \in 1 .. 4 |-> 0],
      displayVarianceQty |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId   |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId        |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      complianceId       |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Iceberg Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderIcebergResponseMessage ==
    { ZeroNewOrderIcebergResponseMessage }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.expireDate = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.displayOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.flags2 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.displayVarianceQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergResponseMessage EXCEPT !.complianceId = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Response Message: 52 bytes                                 *)
(***************************************************************************)

OrderCancelResponseMessage ==
    [ clOrdId          : Sample(8),
      timestamp        : Sample(8),
      orderId          : Sample(8),
      flags            : Sample(8),
      flags2           : Sample(8),
      orderQty         : Sample(4),
      tradingSessionId : Sample(4),
      clOrdLinkId      : Sample(4) ]

EncodeOrderCancelResponseMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.orderId
        \o message.flags
        \o message.flags2
        \o message.orderQty
        \o message.tradingSessionId
        \o message.clOrdLinkId

DecodeOrderCancelResponseMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET flags == ReadBytes(orderId.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET flags2 == ReadBytes(flags.rest, 8) IN IF ~flags2.ok THEN Fail ELSE
    LET orderQty == ReadBytes(flags2.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(tradingSessionId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    Ok([ clOrdId          |-> clOrdId.value,
         timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         flags            |-> flags.value,
         flags2           |-> flags2.value,
         orderQty         |-> orderQty.value,
         tradingSessionId |-> tradingSessionId.value,
         clOrdLinkId      |-> clOrdLinkId.value ], clOrdLinkId.rest)

ZeroOrderCancelResponseMessage ==
    [ clOrdId          |-> [i \in 1 .. 8 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      flags            |-> [i \in 1 .. 8 |-> 0],
      flags2           |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelResponseMessage ==
    { ZeroOrderCancelResponseMessage }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.flags2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replace Response Message: 69 bytes                                *)
(***************************************************************************)

OrderReplaceResponseMessage ==
    [ clOrdId          : Sample(8),
      timestamp        : Sample(8),
      orderId          : Sample(8),
      prevOrderId      : Sample(8),
      flags            : Sample(8),
      flags2           : Sample(8),
      price            : Sample(8),
      orderQty         : Sample(4),
      tradingSessionId : Sample(4),
      clOrdLinkId      : Sample(4),
      complianceId     : Sample(1) ]

EncodeOrderReplaceResponseMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.orderId
        \o message.prevOrderId
        \o message.flags
        \o message.flags2
        \o message.price
        \o message.orderQty
        \o message.tradingSessionId
        \o message.clOrdLinkId
        \o message.complianceId

DecodeOrderReplaceResponseMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET prevOrderId == ReadBytes(orderId.rest, 8) IN IF ~prevOrderId.ok THEN Fail ELSE
    LET flags == ReadBytes(prevOrderId.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET flags2 == ReadBytes(flags.rest, 8) IN IF ~flags2.ok THEN Fail ELSE
    LET price == ReadBytes(flags2.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(tradingSessionId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(clOrdLinkId.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    Ok([ clOrdId          |-> clOrdId.value,
         timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         prevOrderId      |-> prevOrderId.value,
         flags            |-> flags.value,
         flags2           |-> flags2.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         tradingSessionId |-> tradingSessionId.value,
         clOrdLinkId      |-> clOrdLinkId.value,
         complianceId     |-> complianceId.value ], complianceId.rest)

ZeroOrderReplaceResponseMessage ==
    [ clOrdId          |-> [i \in 1 .. 8 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      prevOrderId      |-> [i \in 1 .. 8 |-> 0],
      flags            |-> [i \in 1 .. 8 |-> 0],
      flags2           |-> [i \in 1 .. 8 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId      |-> [i \in 1 .. 4 |-> 0],
      complianceId     |-> [i \in 1 .. 1 |-> 0] ]

(* Order Replace Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceResponseMessage ==
    { ZeroOrderReplaceResponseMessage }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.prevOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.flags2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceResponseMessage EXCEPT !.complianceId = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Mass Cancel Response Message: 20 bytes                            *)
(***************************************************************************)

OrderMassCancelResponseMessage ==
    [ clOrdId             : Sample(8),
      timestamp           : Sample(8),
      totalAffectedOrders : Sample(4) ]

EncodeOrderMassCancelResponseMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.totalAffectedOrders

DecodeOrderMassCancelResponseMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET totalAffectedOrders == ReadBytes(timestamp.rest, 4) IN IF ~totalAffectedOrders.ok THEN Fail ELSE
    Ok([ clOrdId             |-> clOrdId.value,
         timestamp           |-> timestamp.value,
         totalAffectedOrders |-> totalAffectedOrders.value ], totalAffectedOrders.rest)

ZeroOrderMassCancelResponseMessage ==
    [ clOrdId             |-> [i \in 1 .. 8 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      totalAffectedOrders |-> [i \in 1 .. 4 |-> 0] ]

(* Order Mass Cancel Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelResponseMessage ==
    { ZeroOrderMassCancelResponseMessage }
        \cup { [ZeroOrderMassCancelResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelResponseMessage EXCEPT !.totalAffectedOrders = one] : one \in Sample(4) }

(***************************************************************************)
(* Execution Single Report Message: 77 bytes                               *)
(***************************************************************************)

ExecutionSingleReportMessage ==
    [ clOrdId          : Sample(8),
      timestamp        : Sample(8),
      orderId          : Sample(8),
      trdMatchId       : Sample(8),
      flags            : Sample(8),
      flags2           : Sample(8),
      lastPx           : Sample(8),
      lastQty          : Sample(4),
      orderQty         : Sample(4),
      tradingSessionId : Sample(4),
      clOrdLinkId      : Sample(4),
      securityId       : Sample(4),
      side             : Sample(1) ]

EncodeExecutionSingleReportMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.orderId
        \o message.trdMatchId
        \o message.flags
        \o message.flags2
        \o message.lastPx
        \o message.lastQty
        \o message.orderQty
        \o message.tradingSessionId
        \o message.clOrdLinkId
        \o message.securityId
        \o message.side

DecodeExecutionSingleReportMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(orderId.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET flags == ReadBytes(trdMatchId.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET flags2 == ReadBytes(flags.rest, 8) IN IF ~flags2.ok THEN Fail ELSE
    LET lastPx == ReadBytes(flags2.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(lastQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(tradingSessionId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdLinkId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ clOrdId          |-> clOrdId.value,
         timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         trdMatchId       |-> trdMatchId.value,
         flags            |-> flags.value,
         flags2           |-> flags2.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         orderQty         |-> orderQty.value,
         tradingSessionId |-> tradingSessionId.value,
         clOrdLinkId      |-> clOrdLinkId.value,
         securityId       |-> securityId.value,
         side             |-> side.value ], side.rest)

ZeroExecutionSingleReportMessage ==
    [ clOrdId          |-> [i \in 1 .. 8 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      trdMatchId       |-> [i \in 1 .. 8 |-> 0],
      flags            |-> [i \in 1 .. 8 |-> 0],
      flags2           |-> [i \in 1 .. 8 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 4 |-> 0],
      orderQty         |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId      |-> [i \in 1 .. 4 |-> 0],
      securityId       |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Single Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionSingleReportMessage ==
    { ZeroExecutionSingleReportMessage }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.flags2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSingleReportMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Multileg Report Message: 85 bytes                             *)
(***************************************************************************)

ExecutionMultilegReportMessage ==
    [ clOrdId          : Sample(8),
      timestamp        : Sample(8),
      orderId          : Sample(8),
      trdMatchId       : Sample(8),
      flags            : Sample(8),
      flags2           : Sample(8),
      lastPx           : Sample(8),
      legPrice         : Sample(8),
      lastQty          : Sample(4),
      orderQty         : Sample(4),
      tradingSessionId : Sample(4),
      clOrdLinkId      : Sample(4),
      securityId       : Sample(4),
      side             : Sample(1) ]

EncodeExecutionMultilegReportMessage(message) ==
    message.clOrdId
        \o message.timestamp
        \o message.orderId
        \o message.trdMatchId
        \o message.flags
        \o message.flags2
        \o message.lastPx
        \o message.legPrice
        \o message.lastQty
        \o message.orderQty
        \o message.tradingSessionId
        \o message.clOrdLinkId
        \o message.securityId
        \o message.side

DecodeExecutionMultilegReportMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(clOrdId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(orderId.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET flags == ReadBytes(trdMatchId.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET flags2 == ReadBytes(flags.rest, 8) IN IF ~flags2.ok THEN Fail ELSE
    LET lastPx == ReadBytes(flags2.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET legPrice == ReadBytes(lastPx.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET lastQty == ReadBytes(legPrice.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(lastQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(tradingSessionId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdLinkId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ clOrdId          |-> clOrdId.value,
         timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         trdMatchId       |-> trdMatchId.value,
         flags            |-> flags.value,
         flags2           |-> flags2.value,
         lastPx           |-> lastPx.value,
         legPrice         |-> legPrice.value,
         lastQty          |-> lastQty.value,
         orderQty         |-> orderQty.value,
         tradingSessionId |-> tradingSessionId.value,
         clOrdLinkId      |-> clOrdLinkId.value,
         securityId       |-> securityId.value,
         side             |-> side.value ], side.rest)

ZeroExecutionMultilegReportMessage ==
    [ clOrdId          |-> [i \in 1 .. 8 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      trdMatchId       |-> [i \in 1 .. 8 |-> 0],
      flags            |-> [i \in 1 .. 8 |-> 0],
      flags2           |-> [i \in 1 .. 8 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      legPrice         |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 4 |-> 0],
      orderQty         |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId      |-> [i \in 1 .. 4 |-> 0],
      securityId       |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Multileg Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionMultilegReportMessage ==
    { ZeroExecutionMultilegReportMessage }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.flags2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMultilegReportMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Empty Book Message: 12 bytes                                            *)
(***************************************************************************)

EmptyBookMessage ==
    [ timestamp        : Sample(8),
      tradingSessionId : Sample(4) ]

EncodeEmptyBookMessage(message) ==
    message.timestamp
        \o message.tradingSessionId

DecodeEmptyBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(timestamp.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         tradingSessionId |-> tradingSessionId.value ], tradingSessionId.rest)

ZeroEmptyBookMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Empty Book Message at zero, then each field in turn at the values it is checked at *)
CheckedEmptyBookMessage ==
    { ZeroEmptyBookMessage }
        \cup { [ZeroEmptyBookMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroEmptyBookMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 21 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp        : Sample(8),
      eventId          : Sample(8),
      tradingSessionId : Sample(4),
      tradSesEvent     : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventId
        \o message.tradingSessionId
        \o message.tradSesEvent

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventId == ReadBytes(timestamp.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(eventId.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         eventId          |-> eventId.value,
         tradingSessionId |-> tradingSessionId.value,
         tradSesEvent     |-> tradSesEvent.value ], tradSesEvent.rest)

ZeroSystemEventMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      eventId          |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent     |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.tradSesEvent = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

EstablishmentAckMessageCode == 5001  \* 0x1389
EstablishmentRejectMessageCode == 5002  \* 0x138a
TerminateMessageCode == 5003  \* 0x138b
RetransmissionMessageCode == 5005  \* 0x138d
SequenceMessageCode == 5006  \* 0x138e
FloodRejectMessageCode == 5007  \* 0x138f
SessionRejectMessageCode == 5008  \* 0x1390
BusinessMessageRejectMessageCode == 5009  \* 0x1391
NewOrderSingleResponseMessageCode == 7015  \* 0x1b67
NewOrderIcebergResponseMessageCode == 7016  \* 0x1b68
OrderCancelResponseMessageCode == 7017  \* 0x1b69
OrderReplaceResponseMessageCode == 7018  \* 0x1b6a
OrderMassCancelResponseMessageCode == 7007  \* 0x1b5f
ExecutionSingleReportMessageCode == 7019  \* 0x1b6b
ExecutionMultilegReportMessageCode == 7020  \* 0x1b6c
EmptyBookMessageCode == 7010  \* 0x1b62
SystemEventMessageCode == 7014  \* 0x1b66

ServerPayload ==
    [ tag : {EstablishmentAckMessageCode}, body : EstablishmentAckMessage ]
        \cup [ tag : {EstablishmentRejectMessageCode}, body : EstablishmentRejectMessage ]
        \cup [ tag : {TerminateMessageCode}, body : TerminateMessage ]
        \cup [ tag : {RetransmissionMessageCode}, body : RetransmissionMessage ]
        \cup [ tag : {SequenceMessageCode}, body : SequenceMessage ]
        \cup [ tag : {FloodRejectMessageCode}, body : FloodRejectMessage ]
        \cup [ tag : {SessionRejectMessageCode}, body : SessionRejectMessage ]
        \cup [ tag : {BusinessMessageRejectMessageCode}, body : BusinessMessageRejectMessage ]
        \cup [ tag : {NewOrderSingleResponseMessageCode}, body : NewOrderSingleResponseMessage ]
        \cup [ tag : {NewOrderIcebergResponseMessageCode}, body : NewOrderIcebergResponseMessage ]
        \cup [ tag : {OrderCancelResponseMessageCode}, body : OrderCancelResponseMessage ]
        \cup [ tag : {OrderReplaceResponseMessageCode}, body : OrderReplaceResponseMessage ]
        \cup [ tag : {OrderMassCancelResponseMessageCode}, body : OrderMassCancelResponseMessage ]
        \cup [ tag : {ExecutionSingleReportMessageCode}, body : ExecutionSingleReportMessage ]
        \cup [ tag : {ExecutionMultilegReportMessageCode}, body : ExecutionMultilegReportMessage ]
        \cup [ tag : {EmptyBookMessageCode}, body : EmptyBookMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = EstablishmentAckMessageCode -> EncodeEstablishmentAckMessage(message.body)
      [] message.tag = EstablishmentRejectMessageCode -> EncodeEstablishmentRejectMessage(message.body)
      [] message.tag = TerminateMessageCode -> EncodeTerminateMessage(message.body)
      [] message.tag = RetransmissionMessageCode -> EncodeRetransmissionMessage(message.body)
      [] message.tag = SequenceMessageCode -> EncodeSequenceMessage(message.body)
      [] message.tag = FloodRejectMessageCode -> EncodeFloodRejectMessage(message.body)
      [] message.tag = SessionRejectMessageCode -> EncodeSessionRejectMessage(message.body)
      [] message.tag = BusinessMessageRejectMessageCode -> EncodeBusinessMessageRejectMessage(message.body)
      [] message.tag = NewOrderSingleResponseMessageCode -> EncodeNewOrderSingleResponseMessage(message.body)
      [] message.tag = NewOrderIcebergResponseMessageCode -> EncodeNewOrderIcebergResponseMessage(message.body)
      [] message.tag = OrderCancelResponseMessageCode -> EncodeOrderCancelResponseMessage(message.body)
      [] message.tag = OrderReplaceResponseMessageCode -> EncodeOrderReplaceResponseMessage(message.body)
      [] message.tag = OrderMassCancelResponseMessageCode -> EncodeOrderMassCancelResponseMessage(message.body)
      [] message.tag = ExecutionSingleReportMessageCode -> EncodeExecutionSingleReportMessage(message.body)
      [] message.tag = ExecutionMultilegReportMessageCode -> EncodeExecutionMultilegReportMessage(message.body)
      [] message.tag = EmptyBookMessageCode -> EncodeEmptyBookMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = EstablishmentAckMessageCode -> DecodeEstablishmentAckMessage(bytes)
              [] tag = EstablishmentRejectMessageCode -> DecodeEstablishmentRejectMessage(bytes)
              [] tag = TerminateMessageCode -> DecodeTerminateMessage(bytes)
              [] tag = RetransmissionMessageCode -> DecodeRetransmissionMessage(bytes)
              [] tag = SequenceMessageCode -> DecodeSequenceMessage(bytes)
              [] tag = FloodRejectMessageCode -> DecodeFloodRejectMessage(bytes)
              [] tag = SessionRejectMessageCode -> DecodeSessionRejectMessage(bytes)
              [] tag = BusinessMessageRejectMessageCode -> DecodeBusinessMessageRejectMessage(bytes)
              [] tag = NewOrderSingleResponseMessageCode -> DecodeNewOrderSingleResponseMessage(bytes)
              [] tag = NewOrderIcebergResponseMessageCode -> DecodeNewOrderIcebergResponseMessage(bytes)
              [] tag = OrderCancelResponseMessageCode -> DecodeOrderCancelResponseMessage(bytes)
              [] tag = OrderReplaceResponseMessageCode -> DecodeOrderReplaceResponseMessage(bytes)
              [] tag = OrderMassCancelResponseMessageCode -> DecodeOrderMassCancelResponseMessage(bytes)
              [] tag = ExecutionSingleReportMessageCode -> DecodeExecutionSingleReportMessage(bytes)
              [] tag = ExecutionMultilegReportMessageCode -> DecodeExecutionMultilegReportMessage(bytes)
              [] tag = EmptyBookMessageCode -> DecodeEmptyBookMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> EstablishmentAckMessageCode, body |-> ZeroEstablishmentAckMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> EstablishmentAckMessageCode, body |-> one] : one \in CheckedEstablishmentAckMessage }
        \cup { [tag |-> EstablishmentRejectMessageCode, body |-> one] : one \in CheckedEstablishmentRejectMessage }
        \cup { [tag |-> TerminateMessageCode, body |-> one] : one \in CheckedTerminateMessage }
        \cup { [tag |-> RetransmissionMessageCode, body |-> one] : one \in CheckedRetransmissionMessage }
        \cup { [tag |-> SequenceMessageCode, body |-> one] : one \in CheckedSequenceMessage }
        \cup { [tag |-> FloodRejectMessageCode, body |-> one] : one \in CheckedFloodRejectMessage }
        \cup { [tag |-> SessionRejectMessageCode, body |-> one] : one \in CheckedSessionRejectMessage }
        \cup { [tag |-> BusinessMessageRejectMessageCode, body |-> one] : one \in CheckedBusinessMessageRejectMessage }
        \cup { [tag |-> NewOrderSingleResponseMessageCode, body |-> one] : one \in CheckedNewOrderSingleResponseMessage }
        \cup { [tag |-> NewOrderIcebergResponseMessageCode, body |-> one] : one \in CheckedNewOrderIcebergResponseMessage }
        \cup { [tag |-> OrderCancelResponseMessageCode, body |-> one] : one \in CheckedOrderCancelResponseMessage }
        \cup { [tag |-> OrderReplaceResponseMessageCode, body |-> one] : one \in CheckedOrderReplaceResponseMessage }
        \cup { [tag |-> OrderMassCancelResponseMessageCode, body |-> one] : one \in CheckedOrderMassCancelResponseMessage }
        \cup { [tag |-> ExecutionSingleReportMessageCode, body |-> one] : one \in CheckedExecutionSingleReportMessage }
        \cup { [tag |-> ExecutionMultilegReportMessageCode, body |-> one] : one \in CheckedExecutionMultilegReportMessage }
        \cup { [tag |-> EmptyBookMessageCode, body |-> one] : one \in CheckedEmptyBookMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }

(***************************************************************************)
(* Server Message, framed by Block Length                                  *)
(***************************************************************************)

ServerMessage ==
    [ schemaId      : Sample(2),
      version       : Sample(2),
      serverPayload : ServerPayload ]

EncodeServerMessageBody(message) ==
    EncodeUIntLE(message.serverPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeServerPayload(message.serverPayload)

(* Block Length counts the bytes it frames, so it is written from them *)
EncodeServerMessage(message) ==
    LET body == EncodeServerMessageBody(message)
    IN  EncodeUIntLE(Len(body) - 6, 2) \o body

DecodeServerMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(templateId.value, version.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ schemaId      |-> schemaId.value,
         version       |-> version.value,
         serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 6 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerMessage ==
    [ schemaId      |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      serverPayload |-> ZeroServerPayload ]

(* Server Message at zero, then each field in turn at the values it is checked at *)
CheckedServerMessage ==
    { ZeroServerMessage }
        \cup { [ZeroServerMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroServerMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Message, written one after another *)
RECURSIVE EncodeServerMessageList(_)
EncodeServerMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerMessage(Head(messages)) \o EncodeServerMessageList(Tail(messages))

(* As many Server Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerMessageAll(_)
ReadServerMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Message of each kind, for the lists that carry them *)
OneServerMessage ==
    { [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> EstablishmentAckMessageCode, body |-> ZeroEstablishmentAckMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> EstablishmentRejectMessageCode, body |-> ZeroEstablishmentRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TerminateMessageCode, body |-> ZeroTerminateMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmissionMessageCode, body |-> ZeroRetransmissionMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SequenceMessageCode, body |-> ZeroSequenceMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> FloodRejectMessageCode, body |-> ZeroFloodRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SessionRejectMessageCode, body |-> ZeroSessionRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> BusinessMessageRejectMessageCode, body |-> ZeroBusinessMessageRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewOrderSingleResponseMessageCode, body |-> ZeroNewOrderSingleResponseMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewOrderIcebergResponseMessageCode, body |-> ZeroNewOrderIcebergResponseMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderCancelResponseMessageCode, body |-> ZeroOrderCancelResponseMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderReplaceResponseMessageCode, body |-> ZeroOrderReplaceResponseMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderMassCancelResponseMessageCode, body |-> ZeroOrderMassCancelResponseMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ExecutionSingleReportMessageCode, body |-> ZeroExecutionSingleReportMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ExecutionMultilegReportMessageCode, body |-> ZeroExecutionMultilegReportMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> EmptyBookMessageCode, body |-> ZeroEmptyBookMessage]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverMessage : SampleLists(OneServerMessage) ]

EncodeServerPacket(message) ==
    EncodeServerMessageList(message.serverMessage)

DecodeServerPacket(bytes) ==
    LET serverMessage == ReadServerMessageAll(bytes) IN IF ~serverMessage.ok THEN Fail ELSE
    Ok([ serverMessage |-> serverMessage.value ], serverMessage.rest)

ZeroServerPacket ==
    [ serverMessage |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverMessage = one] : one \in SampleLists(OneServerMessage) }

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

(* Every Establishment Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishmentAckMessage ==
    \A message \in CheckedEstablishmentAckMessage :
        LET read == DecodeEstablishmentAckMessage(EncodeEstablishmentAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establishment Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishmentRejectMessage ==
    \A message \in CheckedEstablishmentRejectMessage :
        LET read == DecodeEstablishmentRejectMessage(EncodeEstablishmentRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminateMessage ==
    \A message \in CheckedTerminateMessage :
        LET read == DecodeTerminateMessage(EncodeTerminateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionMessage ==
    \A message \in CheckedRetransmissionMessage :
        LET read == DecodeRetransmissionMessage(EncodeRetransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceMessage ==
    \A message \in CheckedSequenceMessage :
        LET read == DecodeSequenceMessage(EncodeSequenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flood Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFloodRejectMessage ==
    \A message \in CheckedFloodRejectMessage :
        LET read == DecodeFloodRejectMessage(EncodeFloodRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionRejectMessage ==
    \A message \in CheckedSessionRejectMessage :
        LET read == DecodeSessionRejectMessage(EncodeSessionRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Message Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessMessageRejectMessage ==
    \A message \in CheckedBusinessMessageRejectMessage :
        LET read == DecodeBusinessMessageRejectMessage(EncodeBusinessMessageRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleResponseMessage ==
    \A message \in CheckedNewOrderSingleResponseMessage :
        LET read == DecodeNewOrderSingleResponseMessage(EncodeNewOrderSingleResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Iceberg Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderIcebergResponseMessage ==
    \A message \in CheckedNewOrderIcebergResponseMessage :
        LET read == DecodeNewOrderIcebergResponseMessage(EncodeNewOrderIcebergResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelResponseMessage ==
    \A message \in CheckedOrderCancelResponseMessage :
        LET read == DecodeOrderCancelResponseMessage(EncodeOrderCancelResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceResponseMessage ==
    \A message \in CheckedOrderReplaceResponseMessage :
        LET read == DecodeOrderReplaceResponseMessage(EncodeOrderReplaceResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelResponseMessage ==
    \A message \in CheckedOrderMassCancelResponseMessage :
        LET read == DecodeOrderMassCancelResponseMessage(EncodeOrderMassCancelResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Single Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionSingleReportMessage ==
    \A message \in CheckedExecutionSingleReportMessage :
        LET read == DecodeExecutionSingleReportMessage(EncodeExecutionSingleReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Multileg Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionMultilegReportMessage ==
    \A message \in CheckedExecutionMultilegReportMessage :
        LET read == DecodeExecutionMultilegReportMessage(EncodeExecutionMultilegReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Empty Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmptyBookMessage ==
    \A message \in CheckedEmptyBookMessage :
        LET read == DecodeEmptyBookMessage(EncodeEmptyBookMessage(message))
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

(* Every Server Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerMessage ==
    \A message \in CheckedServerMessage :
        LET read == DecodeServerMessage(EncodeServerMessage(message))
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

(* A Server Payload is selected by the Template Id it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET sent == EncodeServerPayload(message)
            read == DecodeServerPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Block Length is written from the bytes it frames *)
FramesServerMessage ==
    \A message \in CheckedServerMessage :
        LET bytes == EncodeServerMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 8

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
