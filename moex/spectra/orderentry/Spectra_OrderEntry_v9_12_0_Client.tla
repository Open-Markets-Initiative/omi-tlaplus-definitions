----------------- MODULE Spectra_OrderEntry_v9_12_0_Client -----------------
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
(* Establish Message: 32 bytes                                             *)
(***************************************************************************)

EstablishMessage ==
    [ timestamp         : Sample(8),
      keepaliveInterval : Sample(4),
      credentials       : Sample(20) ]

EncodeEstablishMessage(message) ==
    message.timestamp
        \o message.keepaliveInterval
        \o message.credentials

DecodeEstablishMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET keepaliveInterval == ReadBytes(timestamp.rest, 4) IN IF ~keepaliveInterval.ok THEN Fail ELSE
    LET credentials == ReadBytes(keepaliveInterval.rest, 20) IN IF ~credentials.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         keepaliveInterval |-> keepaliveInterval.value,
         credentials       |-> credentials.value ], credentials.rest)

ZeroEstablishMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      keepaliveInterval |-> [i \in 1 .. 4 |-> 0],
      credentials       |-> [i \in 1 .. 20 |-> 0] ]

(* Establish Message at zero, then each field in turn at the values it is checked at *)
CheckedEstablishMessage ==
    { ZeroEstablishMessage }
        \cup { [ZeroEstablishMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishMessage EXCEPT !.keepaliveInterval = one] : one \in Sample(4) }
        \cup { [ZeroEstablishMessage EXCEPT !.credentials = one] : one \in Sample(20) }

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
(* Retransmit Request Message: 20 bytes                                    *)
(***************************************************************************)

RetransmitRequestMessage ==
    [ timestamp : Sample(8),
      fromSeqNo : Sample(8),
      count     : Sample(4) ]

EncodeRetransmitRequestMessage(message) ==
    message.timestamp
        \o message.fromSeqNo
        \o message.count

DecodeRetransmitRequestMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET fromSeqNo == ReadBytes(timestamp.rest, 8) IN IF ~fromSeqNo.ok THEN Fail ELSE
    LET count == ReadBytes(fromSeqNo.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         fromSeqNo |-> fromSeqNo.value,
         count     |-> count.value ], count.rest)

ZeroRetransmitRequestMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      fromSeqNo |-> [i \in 1 .. 8 |-> 0],
      count     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmit Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequestMessage ==
    { ZeroRetransmitRequestMessage }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.fromSeqNo = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.count = one] : one \in Sample(4) }

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
(* New Order Single Message: 47 bytes                                      *)
(***************************************************************************)

NewOrderSingleMessage ==
    [ clOrdId      : Sample(8),
      expireDate   : Sample(8),
      price        : Sample(8),
      securityId   : Sample(4),
      clOrdLinkId  : Sample(4),
      orderQty     : Sample(4),
      complianceId : Sample(1),
      timeInForce  : Sample(1),
      side         : Sample(1),
      clientFlags  : Sample(1),
      account      : Sample(7) ]

EncodeNewOrderSingleMessage(message) ==
    message.clOrdId
        \o message.expireDate
        \o message.price
        \o message.securityId
        \o message.clOrdLinkId
        \o message.orderQty
        \o message.complianceId
        \o message.timeInForce
        \o message.side
        \o message.clientFlags
        \o message.account

DecodeNewOrderSingleMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(clOrdId.rest, 8) IN IF ~expireDate.ok THEN Fail ELSE
    LET price == ReadBytes(expireDate.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET securityId == ReadBytes(price.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(securityId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdLinkId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET complianceId == ReadBytes(orderQty.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(complianceId.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET side == ReadBytes(timeInForce.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(side.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         expireDate   |-> expireDate.value,
         price        |-> price.value,
         securityId   |-> securityId.value,
         clOrdLinkId  |-> clOrdLinkId.value,
         orderQty     |-> orderQty.value,
         complianceId |-> complianceId.value,
         timeInForce  |-> timeInForce.value,
         side         |-> side.value,
         clientFlags  |-> clientFlags.value,
         account      |-> account.value ], account.rest)

ZeroNewOrderSingleMessage ==
    [ clOrdId      |-> [i \in 1 .. 8 |-> 0],
      expireDate   |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId  |-> [i \in 1 .. 4 |-> 0],
      orderQty     |-> [i \in 1 .. 4 |-> 0],
      complianceId |-> [i \in 1 .. 1 |-> 0],
      timeInForce  |-> [i \in 1 .. 1 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      clientFlags  |-> [i \in 1 .. 1 |-> 0],
      account      |-> [i \in 1 .. 7 |-> 0] ]

(* New Order Single Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleMessage ==
    { ZeroNewOrderSingleMessage }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.expireDate = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.complianceId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* New Order Iceberg Message: 54 bytes                                     *)
(***************************************************************************)

NewOrderIcebergMessage ==
    [ clOrdId            : Sample(8),
      expireDate         : Sample(8),
      price              : Sample(8),
      securityId         : Sample(4),
      clOrdLinkId        : Sample(4),
      displayQty         : Sample(4),
      displayVarianceQty : Sample(4),
      orderQty           : Sample(4),
      complianceId       : Sample(1),
      side               : Sample(1),
      clientFlags        : Sample(1),
      account            : Sample(7) ]

EncodeNewOrderIcebergMessage(message) ==
    message.clOrdId
        \o message.expireDate
        \o message.price
        \o message.securityId
        \o message.clOrdLinkId
        \o message.displayQty
        \o message.displayVarianceQty
        \o message.orderQty
        \o message.complianceId
        \o message.side
        \o message.clientFlags
        \o message.account

DecodeNewOrderIcebergMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(clOrdId.rest, 8) IN IF ~expireDate.ok THEN Fail ELSE
    LET price == ReadBytes(expireDate.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET securityId == ReadBytes(price.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(securityId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET displayQty == ReadBytes(clOrdLinkId.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayVarianceQty == ReadBytes(displayQty.rest, 4) IN IF ~displayVarianceQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(displayVarianceQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET complianceId == ReadBytes(orderQty.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    LET side == ReadBytes(complianceId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(side.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         expireDate         |-> expireDate.value,
         price              |-> price.value,
         securityId         |-> securityId.value,
         clOrdLinkId        |-> clOrdLinkId.value,
         displayQty         |-> displayQty.value,
         displayVarianceQty |-> displayVarianceQty.value,
         orderQty           |-> orderQty.value,
         complianceId       |-> complianceId.value,
         side               |-> side.value,
         clientFlags        |-> clientFlags.value,
         account            |-> account.value ], account.rest)

ZeroNewOrderIcebergMessage ==
    [ clOrdId            |-> [i \in 1 .. 8 |-> 0],
      expireDate         |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      securityId         |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId        |-> [i \in 1 .. 4 |-> 0],
      displayQty         |-> [i \in 1 .. 4 |-> 0],
      displayVarianceQty |-> [i \in 1 .. 4 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      complianceId       |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      clientFlags        |-> [i \in 1 .. 1 |-> 0],
      account            |-> [i \in 1 .. 7 |-> 0] ]

(* New Order Iceberg Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderIcebergMessage ==
    { ZeroNewOrderIcebergMessage }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.expireDate = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.displayVarianceQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.complianceId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* New Order Iceberg X Message: 55 bytes                                   *)
(***************************************************************************)

NewOrderIcebergXMessage ==
    [ clOrdId            : Sample(8),
      expireDate         : Sample(8),
      price              : Sample(8),
      securityId         : Sample(4),
      clOrdLinkId        : Sample(4),
      displayQty         : Sample(4),
      displayVarianceQty : Sample(4),
      orderQty           : Sample(4),
      complianceId       : Sample(1),
      timeInForce        : Sample(1),
      side               : Sample(1),
      clientFlags        : Sample(1),
      account            : Sample(7) ]

EncodeNewOrderIcebergXMessage(message) ==
    message.clOrdId
        \o message.expireDate
        \o message.price
        \o message.securityId
        \o message.clOrdLinkId
        \o message.displayQty
        \o message.displayVarianceQty
        \o message.orderQty
        \o message.complianceId
        \o message.timeInForce
        \o message.side
        \o message.clientFlags
        \o message.account

DecodeNewOrderIcebergXMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(clOrdId.rest, 8) IN IF ~expireDate.ok THEN Fail ELSE
    LET price == ReadBytes(expireDate.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET securityId == ReadBytes(price.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(securityId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET displayQty == ReadBytes(clOrdLinkId.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayVarianceQty == ReadBytes(displayQty.rest, 4) IN IF ~displayVarianceQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(displayVarianceQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET complianceId == ReadBytes(orderQty.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(complianceId.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET side == ReadBytes(timeInForce.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(side.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         expireDate         |-> expireDate.value,
         price              |-> price.value,
         securityId         |-> securityId.value,
         clOrdLinkId        |-> clOrdLinkId.value,
         displayQty         |-> displayQty.value,
         displayVarianceQty |-> displayVarianceQty.value,
         orderQty           |-> orderQty.value,
         complianceId       |-> complianceId.value,
         timeInForce        |-> timeInForce.value,
         side               |-> side.value,
         clientFlags        |-> clientFlags.value,
         account            |-> account.value ], account.rest)

ZeroNewOrderIcebergXMessage ==
    [ clOrdId            |-> [i \in 1 .. 8 |-> 0],
      expireDate         |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      securityId         |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId        |-> [i \in 1 .. 4 |-> 0],
      displayQty         |-> [i \in 1 .. 4 |-> 0],
      displayVarianceQty |-> [i \in 1 .. 4 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      complianceId       |-> [i \in 1 .. 1 |-> 0],
      timeInForce        |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      clientFlags        |-> [i \in 1 .. 1 |-> 0],
      account            |-> [i \in 1 .. 7 |-> 0] ]

(* New Order Iceberg X Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderIcebergXMessage ==
    { ZeroNewOrderIcebergXMessage }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.expireDate = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.displayVarianceQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.complianceId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderIcebergXMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Cancel Request Message: 28 bytes                                  *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ clOrdId     : Sample(8),
      orderId     : Sample(8),
      securityId  : Sample(4),
      clientFlags : Sample(1),
      account     : Sample(7) ]

EncodeOrderCancelRequestMessage(message) ==
    message.clOrdId
        \o message.orderId
        \o message.securityId
        \o message.clientFlags
        \o message.account

DecodeOrderCancelRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(securityId.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId     |-> clOrdId.value,
         orderId     |-> orderId.value,
         securityId  |-> securityId.value,
         clientFlags |-> clientFlags.value,
         account     |-> account.value ], account.rest)

ZeroOrderCancelRequestMessage ==
    [ clOrdId     |-> [i \in 1 .. 8 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      securityId  |-> [i \in 1 .. 4 |-> 0],
      clientFlags |-> [i \in 1 .. 1 |-> 0],
      account     |-> [i \in 1 .. 7 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Iceberg Cancel Request Message: 28 bytes                          *)
(***************************************************************************)

OrderIcebergCancelRequestMessage ==
    [ clOrdId     : Sample(8),
      orderId     : Sample(8),
      securityId  : Sample(4),
      clientFlags : Sample(1),
      account     : Sample(7) ]

EncodeOrderIcebergCancelRequestMessage(message) ==
    message.clOrdId
        \o message.orderId
        \o message.securityId
        \o message.clientFlags
        \o message.account

DecodeOrderIcebergCancelRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(securityId.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId     |-> clOrdId.value,
         orderId     |-> orderId.value,
         securityId  |-> securityId.value,
         clientFlags |-> clientFlags.value,
         account     |-> account.value ], account.rest)

ZeroOrderIcebergCancelRequestMessage ==
    [ clOrdId     |-> [i \in 1 .. 8 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      securityId  |-> [i \in 1 .. 4 |-> 0],
      clientFlags |-> [i \in 1 .. 1 |-> 0],
      account     |-> [i \in 1 .. 7 |-> 0] ]

(* Order Iceberg Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderIcebergCancelRequestMessage ==
    { ZeroOrderIcebergCancelRequestMessage }
        \cup { [ZeroOrderIcebergCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderIcebergCancelRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderIcebergCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderIcebergCancelRequestMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderIcebergCancelRequestMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Replace Request Message: 46 bytes                                 *)
(***************************************************************************)

OrderReplaceRequestMessage ==
    [ clOrdId      : Sample(8),
      orderId      : Sample(8),
      price        : Sample(8),
      orderQty     : Sample(4),
      clOrdLinkId  : Sample(4),
      securityId   : Sample(4),
      complianceId : Sample(1),
      mode         : Sample(1),
      clientFlags  : Sample(1),
      account      : Sample(7) ]

EncodeOrderReplaceRequestMessage(message) ==
    message.clOrdId
        \o message.orderId
        \o message.price
        \o message.orderQty
        \o message.clOrdLinkId
        \o message.securityId
        \o message.complianceId
        \o message.mode
        \o message.clientFlags
        \o message.account

DecodeOrderReplaceRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(orderQty.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdLinkId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(securityId.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    LET mode == ReadBytes(complianceId.rest, 1) IN IF ~mode.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(mode.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         orderId      |-> orderId.value,
         price        |-> price.value,
         orderQty     |-> orderQty.value,
         clOrdLinkId  |-> clOrdLinkId.value,
         securityId   |-> securityId.value,
         complianceId |-> complianceId.value,
         mode         |-> mode.value,
         clientFlags  |-> clientFlags.value,
         account      |-> account.value ], account.rest)

ZeroOrderReplaceRequestMessage ==
    [ clOrdId      |-> [i \in 1 .. 8 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      orderQty     |-> [i \in 1 .. 4 |-> 0],
      clOrdLinkId  |-> [i \in 1 .. 4 |-> 0],
      securityId   |-> [i \in 1 .. 4 |-> 0],
      complianceId |-> [i \in 1 .. 1 |-> 0],
      mode         |-> [i \in 1 .. 1 |-> 0],
      clientFlags  |-> [i \in 1 .. 1 |-> 0],
      account      |-> [i \in 1 .. 7 |-> 0] ]

(* Order Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceRequestMessage ==
    { ZeroOrderReplaceRequestMessage }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.complianceId = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.mode = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceRequestMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Iceberg Replace Request Message: 41 bytes                         *)
(***************************************************************************)

OrderIcebergReplaceRequestMessage ==
    [ clOrdId      : Sample(8),
      orderId      : Sample(8),
      price        : Sample(8),
      clOrdLinkId  : Sample(4),
      securityId   : Sample(4),
      complianceId : Sample(1),
      clientFlags  : Sample(1),
      account      : Sample(7) ]

EncodeOrderIcebergReplaceRequestMessage(message) ==
    message.clOrdId
        \o message.orderId
        \o message.price
        \o message.clOrdLinkId
        \o message.securityId
        \o message.complianceId
        \o message.clientFlags
        \o message.account

DecodeOrderIcebergReplaceRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(price.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdLinkId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(securityId.rest, 1) IN IF ~complianceId.ok THEN Fail ELSE
    LET clientFlags == ReadBytes(complianceId.rest, 1) IN IF ~clientFlags.ok THEN Fail ELSE
    LET account == ReadBytes(clientFlags.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         orderId      |-> orderId.value,
         price        |-> price.value,
         clOrdLinkId  |-> clOrdLinkId.value,
         securityId   |-> securityId.value,
         complianceId |-> complianceId.value,
         clientFlags  |-> clientFlags.value,
         account      |-> account.value ], account.rest)

ZeroOrderIcebergReplaceRequestMessage ==
    [ clOrdId      |-> [i \in 1 .. 8 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      clOrdLinkId  |-> [i \in 1 .. 4 |-> 0],
      securityId   |-> [i \in 1 .. 4 |-> 0],
      complianceId |-> [i \in 1 .. 1 |-> 0],
      clientFlags  |-> [i \in 1 .. 1 |-> 0],
      account      |-> [i \in 1 .. 7 |-> 0] ]

(* Order Iceberg Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderIcebergReplaceRequestMessage ==
    { ZeroOrderIcebergReplaceRequestMessage }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.complianceId = one] : one \in Sample(1) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.clientFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderIcebergReplaceRequestMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Mass Cancel Request Message: 50 bytes                             *)
(***************************************************************************)

OrderMassCancelRequestMessage ==
    [ clOrdId       : Sample(8),
      clOrdLinkId   : Sample(4),
      securityId    : Sample(4),
      securityType  : Sample(1),
      side          : Sample(1),
      account       : Sample(7),
      securityGroup : Sample(25) ]

EncodeOrderMassCancelRequestMessage(message) ==
    message.clOrdId
        \o message.clOrdLinkId
        \o message.securityId
        \o message.securityType
        \o message.side
        \o message.account
        \o message.securityGroup

DecodeOrderMassCancelRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(clOrdId.rest, 4) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdLinkId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET side == ReadBytes(securityType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET account == ReadBytes(side.rest, 7) IN IF ~account.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(account.rest, 25) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ clOrdId       |-> clOrdId.value,
         clOrdLinkId   |-> clOrdLinkId.value,
         securityId    |-> securityId.value,
         securityType  |-> securityType.value,
         side          |-> side.value,
         account       |-> account.value,
         securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroOrderMassCancelRequestMessage ==
    [ clOrdId       |-> [i \in 1 .. 8 |-> 0],
      clOrdLinkId   |-> [i \in 1 .. 4 |-> 0],
      securityId    |-> [i \in 1 .. 4 |-> 0],
      securityType  |-> [i \in 1 .. 1 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      account       |-> [i \in 1 .. 7 |-> 0],
      securityGroup |-> [i \in 1 .. 25 |-> 0] ]

(* Order Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelRequestMessage ==
    { ZeroOrderMassCancelRequestMessage }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.account = one] : one \in Sample(7) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.securityGroup = one] : one \in Sample(25) }

(***************************************************************************)
(* Order Mass Cancel By Bf Limit Request Message: 15 bytes                 *)
(***************************************************************************)

OrderMassCancelByBfLimitRequestMessage ==
    [ clOrdId : Sample(8),
      account : Sample(7) ]

EncodeOrderMassCancelByBfLimitRequestMessage(message) ==
    message.clOrdId
        \o message.account

DecodeOrderMassCancelByBfLimitRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET account == ReadBytes(clOrdId.rest, 7) IN IF ~account.ok THEN Fail ELSE
    Ok([ clOrdId |-> clOrdId.value,
         account |-> account.value ], account.rest)

ZeroOrderMassCancelByBfLimitRequestMessage ==
    [ clOrdId |-> [i \in 1 .. 8 |-> 0],
      account |-> [i \in 1 .. 7 |-> 0] ]

(* Order Mass Cancel By Bf Limit Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelByBfLimitRequestMessage ==
    { ZeroOrderMassCancelByBfLimitRequestMessage }
        \cup { [ZeroOrderMassCancelByBfLimitRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelByBfLimitRequestMessage EXCEPT !.account = one] : one \in Sample(7) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

EstablishMessageCode == 5000  \* 0x1388
TerminateMessageCode == 5003  \* 0x138b
RetransmitRequestMessageCode == 5004  \* 0x138c
SequenceMessageCode == 5006  \* 0x138e
NewOrderSingleMessageCode == 6000  \* 0x1770
NewOrderIcebergMessageCode == 6008  \* 0x1778
NewOrderIcebergXMessageCode == 6011  \* 0x177b
OrderCancelRequestMessageCode == 6006  \* 0x1776
OrderIcebergCancelRequestMessageCode == 6009  \* 0x1779
OrderReplaceRequestMessageCode == 6007  \* 0x1777
OrderIcebergReplaceRequestMessageCode == 6010  \* 0x177a
OrderMassCancelRequestMessageCode == 6004  \* 0x1774
OrderMassCancelByBfLimitRequestMessageCode == 6005  \* 0x1775

ClientPayload ==
    [ tag : {EstablishMessageCode}, body : EstablishMessage ]
        \cup [ tag : {TerminateMessageCode}, body : TerminateMessage ]
        \cup [ tag : {RetransmitRequestMessageCode}, body : RetransmitRequestMessage ]
        \cup [ tag : {SequenceMessageCode}, body : SequenceMessage ]
        \cup [ tag : {NewOrderSingleMessageCode}, body : NewOrderSingleMessage ]
        \cup [ tag : {NewOrderIcebergMessageCode}, body : NewOrderIcebergMessage ]
        \cup [ tag : {NewOrderIcebergXMessageCode}, body : NewOrderIcebergXMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {OrderIcebergCancelRequestMessageCode}, body : OrderIcebergCancelRequestMessage ]
        \cup [ tag : {OrderReplaceRequestMessageCode}, body : OrderReplaceRequestMessage ]
        \cup [ tag : {OrderIcebergReplaceRequestMessageCode}, body : OrderIcebergReplaceRequestMessage ]
        \cup [ tag : {OrderMassCancelRequestMessageCode}, body : OrderMassCancelRequestMessage ]
        \cup [ tag : {OrderMassCancelByBfLimitRequestMessageCode}, body : OrderMassCancelByBfLimitRequestMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = EstablishMessageCode -> EncodeEstablishMessage(message.body)
      [] message.tag = TerminateMessageCode -> EncodeTerminateMessage(message.body)
      [] message.tag = RetransmitRequestMessageCode -> EncodeRetransmitRequestMessage(message.body)
      [] message.tag = SequenceMessageCode -> EncodeSequenceMessage(message.body)
      [] message.tag = NewOrderSingleMessageCode -> EncodeNewOrderSingleMessage(message.body)
      [] message.tag = NewOrderIcebergMessageCode -> EncodeNewOrderIcebergMessage(message.body)
      [] message.tag = NewOrderIcebergXMessageCode -> EncodeNewOrderIcebergXMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = OrderIcebergCancelRequestMessageCode -> EncodeOrderIcebergCancelRequestMessage(message.body)
      [] message.tag = OrderReplaceRequestMessageCode -> EncodeOrderReplaceRequestMessage(message.body)
      [] message.tag = OrderIcebergReplaceRequestMessageCode -> EncodeOrderIcebergReplaceRequestMessage(message.body)
      [] message.tag = OrderMassCancelRequestMessageCode -> EncodeOrderMassCancelRequestMessage(message.body)
      [] message.tag = OrderMassCancelByBfLimitRequestMessageCode -> EncodeOrderMassCancelByBfLimitRequestMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = EstablishMessageCode -> DecodeEstablishMessage(bytes)
              [] tag = TerminateMessageCode -> DecodeTerminateMessage(bytes)
              [] tag = RetransmitRequestMessageCode -> DecodeRetransmitRequestMessage(bytes)
              [] tag = SequenceMessageCode -> DecodeSequenceMessage(bytes)
              [] tag = NewOrderSingleMessageCode -> DecodeNewOrderSingleMessage(bytes)
              [] tag = NewOrderIcebergMessageCode -> DecodeNewOrderIcebergMessage(bytes)
              [] tag = NewOrderIcebergXMessageCode -> DecodeNewOrderIcebergXMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = OrderIcebergCancelRequestMessageCode -> DecodeOrderIcebergCancelRequestMessage(bytes)
              [] tag = OrderReplaceRequestMessageCode -> DecodeOrderReplaceRequestMessage(bytes)
              [] tag = OrderIcebergReplaceRequestMessageCode -> DecodeOrderIcebergReplaceRequestMessage(bytes)
              [] tag = OrderMassCancelRequestMessageCode -> DecodeOrderMassCancelRequestMessage(bytes)
              [] tag = OrderMassCancelByBfLimitRequestMessageCode -> DecodeOrderMassCancelByBfLimitRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> EstablishMessageCode, body |-> ZeroEstablishMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> EstablishMessageCode, body |-> one] : one \in CheckedEstablishMessage }
        \cup { [tag |-> TerminateMessageCode, body |-> one] : one \in CheckedTerminateMessage }
        \cup { [tag |-> RetransmitRequestMessageCode, body |-> one] : one \in CheckedRetransmitRequestMessage }
        \cup { [tag |-> SequenceMessageCode, body |-> one] : one \in CheckedSequenceMessage }
        \cup { [tag |-> NewOrderSingleMessageCode, body |-> one] : one \in CheckedNewOrderSingleMessage }
        \cup { [tag |-> NewOrderIcebergMessageCode, body |-> one] : one \in CheckedNewOrderIcebergMessage }
        \cup { [tag |-> NewOrderIcebergXMessageCode, body |-> one] : one \in CheckedNewOrderIcebergXMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> OrderIcebergCancelRequestMessageCode, body |-> one] : one \in CheckedOrderIcebergCancelRequestMessage }
        \cup { [tag |-> OrderReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderReplaceRequestMessage }
        \cup { [tag |-> OrderIcebergReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderIcebergReplaceRequestMessage }
        \cup { [tag |-> OrderMassCancelRequestMessageCode, body |-> one] : one \in CheckedOrderMassCancelRequestMessage }
        \cup { [tag |-> OrderMassCancelByBfLimitRequestMessageCode, body |-> one] : one \in CheckedOrderMassCancelByBfLimitRequestMessage }

(***************************************************************************)
(* Client Message, framed by Block Length                                  *)
(***************************************************************************)

ClientMessage ==
    [ schemaId      : Sample(2),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientMessageBody(message) ==
    EncodeUIntLE(message.clientPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

(* Block Length counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntLE(Len(body) - 6, 2) \o body

DecodeClientMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ schemaId      |-> schemaId.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 6 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientMessage ==
    [ schemaId      |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> EstablishMessageCode, body |-> ZeroEstablishMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> TerminateMessageCode, body |-> ZeroTerminateMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitRequestMessageCode, body |-> ZeroRetransmitRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SequenceMessageCode, body |-> ZeroSequenceMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleMessageCode, body |-> ZeroNewOrderSingleMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderIcebergMessageCode, body |-> ZeroNewOrderIcebergMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderIcebergXMessageCode, body |-> ZeroNewOrderIcebergXMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> OrderCancelRequestMessageCode, body |-> ZeroOrderCancelRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> OrderIcebergCancelRequestMessageCode, body |-> ZeroOrderIcebergCancelRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> OrderReplaceRequestMessageCode, body |-> ZeroOrderReplaceRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> OrderIcebergReplaceRequestMessageCode, body |-> ZeroOrderIcebergReplaceRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> OrderMassCancelRequestMessageCode, body |-> ZeroOrderMassCancelRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> OrderMassCancelByBfLimitRequestMessageCode, body |-> ZeroOrderMassCancelByBfLimitRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every Establish Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishMessage ==
    \A message \in CheckedEstablishMessage :
        LET read == DecodeEstablishMessage(EncodeEstablishMessage(message))
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

(* Every Retransmit Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequestMessage ==
    \A message \in CheckedRetransmitRequestMessage :
        LET read == DecodeRetransmitRequestMessage(EncodeRetransmitRequestMessage(message))
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

(* Every New Order Single Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleMessage ==
    \A message \in CheckedNewOrderSingleMessage :
        LET read == DecodeNewOrderSingleMessage(EncodeNewOrderSingleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Iceberg Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderIcebergMessage ==
    \A message \in CheckedNewOrderIcebergMessage :
        LET read == DecodeNewOrderIcebergMessage(EncodeNewOrderIcebergMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Iceberg X Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderIcebergXMessage ==
    \A message \in CheckedNewOrderIcebergXMessage :
        LET read == DecodeNewOrderIcebergXMessage(EncodeNewOrderIcebergXMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Iceberg Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderIcebergCancelRequestMessage ==
    \A message \in CheckedOrderIcebergCancelRequestMessage :
        LET read == DecodeOrderIcebergCancelRequestMessage(EncodeOrderIcebergCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceRequestMessage ==
    \A message \in CheckedOrderReplaceRequestMessage :
        LET read == DecodeOrderReplaceRequestMessage(EncodeOrderReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Iceberg Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderIcebergReplaceRequestMessage ==
    \A message \in CheckedOrderIcebergReplaceRequestMessage :
        LET read == DecodeOrderIcebergReplaceRequestMessage(EncodeOrderIcebergReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelRequestMessage ==
    \A message \in CheckedOrderMassCancelRequestMessage :
        LET read == DecodeOrderMassCancelRequestMessage(EncodeOrderMassCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel By Bf Limit Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelByBfLimitRequestMessage ==
    \A message \in CheckedOrderMassCancelByBfLimitRequestMessage :
        LET read == DecodeOrderMassCancelByBfLimitRequestMessage(EncodeOrderMassCancelByBfLimitRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET sent == EncodeClientPayload(message)
            read == DecodeClientPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Block Length is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 8

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
