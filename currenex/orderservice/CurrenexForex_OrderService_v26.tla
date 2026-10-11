------------------ MODULE CurrenexForex_OrderService_v26 -------------------
(***************************************************************************)
(* Currenex Order Service v26                                              *)
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
(* Logon: 44 bytes                                                         *)
(***************************************************************************)

Logon ==
    [ userId    : Sample(20),
      password  : Sample(20),
      sessionId : Sample(4) ]

EncodeLogon(message) ==
    message.userId
        \o message.password
        \o message.sessionId

DecodeLogon(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET password == ReadBytes(userId.rest, 20) IN IF ~password.ok THEN Fail ELSE
    LET sessionId == ReadBytes(password.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ userId    |-> userId.value,
         password  |-> password.value,
         sessionId |-> sessionId.value ], sessionId.rest)

ZeroLogon ==
    [ userId    |-> [i \in 1 .. 20 |-> 0],
      password  |-> [i \in 1 .. 20 |-> 0],
      sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Logon at zero, then each field in turn at the values it is checked at *)
CheckedLogon ==
    { ZeroLogon }
        \cup { [ZeroLogon EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogon EXCEPT !.password = one] : one \in Sample(20) }
        \cup { [ZeroLogon EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout: 27 bytes                                                        *)
(***************************************************************************)

Logout ==
    [ userId    : Sample(20),
      sessionId : Sample(4),
      reason    : Sample(3) ]

EncodeLogout(message) ==
    message.userId
        \o message.sessionId
        \o message.reason

DecodeLogout(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(userId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET reason == ReadBytes(sessionId.rest, 3) IN IF ~reason.ok THEN Fail ELSE
    Ok([ userId    |-> userId.value,
         sessionId |-> sessionId.value,
         reason    |-> reason.value ], reason.rest)

ZeroLogout ==
    [ userId    |-> [i \in 1 .. 20 |-> 0],
      sessionId |-> [i \in 1 .. 4 |-> 0],
      reason    |-> [i \in 1 .. 3 |-> 0] ]

(* Logout at zero, then each field in turn at the values it is checked at *)
CheckedLogout ==
    { ZeroLogout }
        \cup { [ZeroLogout EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogout EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogout EXCEPT !.reason = one] : one \in Sample(3) }

(***************************************************************************)
(* Heartbeat: 4 bytes                                                      *)
(***************************************************************************)

Heartbeat ==
    [ sessionId : Sample(4) ]

EncodeHeartbeat(message) ==
    message.sessionId

DecodeHeartbeat(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroHeartbeat ==
    [ sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Info Request: 4 bytes                                        *)
(***************************************************************************)

InstrumentInfoRequest ==
    [ sessionId : Sample(4) ]

EncodeInstrumentInfoRequest(message) ==
    message.sessionId

DecodeInstrumentInfoRequest(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroInstrumentInfoRequest ==
    [ sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Info Request at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoRequest ==
    { ZeroInstrumentInfoRequest }
        \cup { [ZeroInstrumentInfoRequest EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Info: 35 bytes                                               *)
(***************************************************************************)

InstrumentInfo ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2),
      instrumentType  : Sample(1),
      instrumentId    : Sample(20),
      settlementDate  : Sample(8) ]

EncodeInstrumentInfo(message) ==
    message.sessionId
        \o message.instrumentIndex
        \o message.instrumentType
        \o message.instrumentId
        \o message.settlementDate

DecodeInstrumentInfo(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIndex.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentType.rest, 20) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(instrumentId.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value,
         instrumentType  |-> instrumentType.value,
         instrumentId    |-> instrumentId.value,
         settlementDate  |-> settlementDate.value ], settlementDate.rest)

ZeroInstrumentInfo ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      instrumentType  |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 20 |-> 0],
      settlementDate  |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Info at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfo ==
    { ZeroInstrumentInfo }
        \cup { [ZeroInstrumentInfo EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentId = one] : one \in Sample(20) }
        \cup { [ZeroInstrumentInfo EXCEPT !.settlementDate = one] : one \in Sample(8) }

(***************************************************************************)
(* New Order Request: 37 bytes                                             *)
(***************************************************************************)

NewOrderRequest ==
    [ clOrderId       : Sample(4),
      orderType       : Sample(1),
      instrumentIndex : Sample(2),
      side            : Sample(1),
      orderAmt        : Sample(8),
      minAmt          : Sample(8),
      price           : Sample(4),
      showAmt         : Sample(8),
      expireType      : Sample(1) ]

EncodeNewOrderRequest(message) ==
    message.clOrderId
        \o message.orderType
        \o message.instrumentIndex
        \o message.side
        \o message.orderAmt
        \o message.minAmt
        \o message.price
        \o message.showAmt
        \o message.expireType

DecodeNewOrderRequest(bytes) ==
    LET clOrderId == ReadBytes(bytes, 4) IN IF ~clOrderId.ok THEN Fail ELSE
    LET orderType == ReadBytes(clOrderId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(orderType.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderAmt == ReadBytes(side.rest, 8) IN IF ~orderAmt.ok THEN Fail ELSE
    LET minAmt == ReadBytes(orderAmt.rest, 8) IN IF ~minAmt.ok THEN Fail ELSE
    LET price == ReadBytes(minAmt.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET showAmt == ReadBytes(price.rest, 8) IN IF ~showAmt.ok THEN Fail ELSE
    LET expireType == ReadBytes(showAmt.rest, 1) IN IF ~expireType.ok THEN Fail ELSE
    Ok([ clOrderId       |-> clOrderId.value,
         orderType       |-> orderType.value,
         instrumentIndex |-> instrumentIndex.value,
         side            |-> side.value,
         orderAmt        |-> orderAmt.value,
         minAmt          |-> minAmt.value,
         price           |-> price.value,
         showAmt         |-> showAmt.value,
         expireType      |-> expireType.value ], expireType.rest)

ZeroNewOrderRequest ==
    [ clOrderId       |-> [i \in 1 .. 4 |-> 0],
      orderType       |-> [i \in 1 .. 1 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      orderAmt        |-> [i \in 1 .. 8 |-> 0],
      minAmt          |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      showAmt         |-> [i \in 1 .. 8 |-> 0],
      expireType      |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRequest ==
    { ZeroNewOrderRequest }
        \cup { [ZeroNewOrderRequest EXCEPT !.clOrderId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequest EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.orderAmt = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.minAmt = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequest EXCEPT !.showAmt = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.expireType = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Ack: 15 bytes                                                 *)
(***************************************************************************)

NewOrderAck ==
    [ clOrderId : Sample(4),
      orderId   : Sample(8),
      ackStatus : Sample(1),
      errorCode : Sample(2) ]

EncodeNewOrderAck(message) ==
    message.clOrderId
        \o message.orderId
        \o message.ackStatus
        \o message.errorCode

DecodeNewOrderAck(bytes) ==
    LET clOrderId == ReadBytes(bytes, 4) IN IF ~clOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET ackStatus == ReadBytes(orderId.rest, 1) IN IF ~ackStatus.ok THEN Fail ELSE
    LET errorCode == ReadBytes(ackStatus.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    Ok([ clOrderId |-> clOrderId.value,
         orderId   |-> orderId.value,
         ackStatus |-> ackStatus.value,
         errorCode |-> errorCode.value ], errorCode.rest)

ZeroNewOrderAck ==
    [ clOrderId |-> [i \in 1 .. 4 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      ackStatus |-> [i \in 1 .. 1 |-> 0],
      errorCode |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Ack at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAck ==
    { ZeroNewOrderAck }
        \cup { [ZeroNewOrderAck EXCEPT !.clOrderId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAck EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAck EXCEPT !.ackStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAck EXCEPT !.errorCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancel Request: 10 bytes                                          *)
(***************************************************************************)

OrderCancelRequest ==
    [ newClOrderId    : Sample(4),
      prevClOrderId   : Sample(4),
      instrumentIndex : Sample(2) ]

EncodeOrderCancelRequest(message) ==
    message.newClOrderId
        \o message.prevClOrderId
        \o message.instrumentIndex

DecodeOrderCancelRequest(bytes) ==
    LET newClOrderId == ReadBytes(bytes, 4) IN IF ~newClOrderId.ok THEN Fail ELSE
    LET prevClOrderId == ReadBytes(newClOrderId.rest, 4) IN IF ~prevClOrderId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(prevClOrderId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    Ok([ newClOrderId    |-> newClOrderId.value,
         prevClOrderId   |-> prevClOrderId.value,
         instrumentIndex |-> instrumentIndex.value ], instrumentIndex.rest)

ZeroOrderCancelRequest ==
    [ newClOrderId    |-> [i \in 1 .. 4 |-> 0],
      prevClOrderId   |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0] ]

(* Order Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequest ==
    { ZeroOrderCancelRequest }
        \cup { [ZeroOrderCancelRequest EXCEPT !.newClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.prevClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.instrumentIndex = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancel Reject: 10 bytes                                           *)
(***************************************************************************)

OrderCancelReject ==
    [ newClOrderId  : Sample(4),
      prevClOrderId : Sample(4),
      errorCode     : Sample(2) ]

EncodeOrderCancelReject(message) ==
    message.newClOrderId
        \o message.prevClOrderId
        \o message.errorCode

DecodeOrderCancelReject(bytes) ==
    LET newClOrderId == ReadBytes(bytes, 4) IN IF ~newClOrderId.ok THEN Fail ELSE
    LET prevClOrderId == ReadBytes(newClOrderId.rest, 4) IN IF ~prevClOrderId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(prevClOrderId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    Ok([ newClOrderId  |-> newClOrderId.value,
         prevClOrderId |-> prevClOrderId.value,
         errorCode     |-> errorCode.value ], errorCode.rest)

ZeroOrderCancelReject ==
    [ newClOrderId  |-> [i \in 1 .. 4 |-> 0],
      prevClOrderId |-> [i \in 1 .. 4 |-> 0],
      errorCode     |-> [i \in 1 .. 2 |-> 0] ]

(* Order Cancel Reject at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReject ==
    { ZeroOrderCancelReject }
        \cup { [ZeroOrderCancelReject EXCEPT !.newClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReject EXCEPT !.prevClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReject EXCEPT !.errorCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Replace Or Cancel Request: 22 bytes                               *)
(***************************************************************************)

OrderReplaceOrCancelRequest ==
    [ newClOrderId    : Sample(4),
      origClOrderId   : Sample(4),
      orderAmt        : Sample(8),
      price           : Sample(4),
      instrumentIndex : Sample(2) ]

EncodeOrderReplaceOrCancelRequest(message) ==
    message.newClOrderId
        \o message.origClOrderId
        \o message.orderAmt
        \o message.price
        \o message.instrumentIndex

DecodeOrderReplaceOrCancelRequest(bytes) ==
    LET newClOrderId == ReadBytes(bytes, 4) IN IF ~newClOrderId.ok THEN Fail ELSE
    LET origClOrderId == ReadBytes(newClOrderId.rest, 4) IN IF ~origClOrderId.ok THEN Fail ELSE
    LET orderAmt == ReadBytes(origClOrderId.rest, 8) IN IF ~orderAmt.ok THEN Fail ELSE
    LET price == ReadBytes(orderAmt.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(price.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    Ok([ newClOrderId    |-> newClOrderId.value,
         origClOrderId   |-> origClOrderId.value,
         orderAmt        |-> orderAmt.value,
         price           |-> price.value,
         instrumentIndex |-> instrumentIndex.value ], instrumentIndex.rest)

ZeroOrderReplaceOrCancelRequest ==
    [ newClOrderId    |-> [i \in 1 .. 4 |-> 0],
      origClOrderId   |-> [i \in 1 .. 4 |-> 0],
      orderAmt        |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0] ]

(* Order Replace Or Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceOrCancelRequest ==
    { ZeroOrderReplaceOrCancelRequest }
        \cup { [ZeroOrderReplaceOrCancelRequest EXCEPT !.newClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceOrCancelRequest EXCEPT !.origClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceOrCancelRequest EXCEPT !.orderAmt = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceOrCancelRequest EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceOrCancelRequest EXCEPT !.instrumentIndex = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Replace Or Cancel Ack: 11 bytes                                   *)
(***************************************************************************)

OrderReplaceOrCancelAck ==
    [ newClOrderId  : Sample(4),
      prevClOrderId : Sample(4),
      status        : Sample(1),
      errorCode     : Sample(2) ]

EncodeOrderReplaceOrCancelAck(message) ==
    message.newClOrderId
        \o message.prevClOrderId
        \o message.status
        \o message.errorCode

DecodeOrderReplaceOrCancelAck(bytes) ==
    LET newClOrderId == ReadBytes(bytes, 4) IN IF ~newClOrderId.ok THEN Fail ELSE
    LET prevClOrderId == ReadBytes(newClOrderId.rest, 4) IN IF ~prevClOrderId.ok THEN Fail ELSE
    LET status == ReadBytes(prevClOrderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET errorCode == ReadBytes(status.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    Ok([ newClOrderId  |-> newClOrderId.value,
         prevClOrderId |-> prevClOrderId.value,
         status        |-> status.value,
         errorCode     |-> errorCode.value ], errorCode.rest)

ZeroOrderReplaceOrCancelAck ==
    [ newClOrderId  |-> [i \in 1 .. 4 |-> 0],
      prevClOrderId |-> [i \in 1 .. 4 |-> 0],
      status        |-> [i \in 1 .. 1 |-> 0],
      errorCode     |-> [i \in 1 .. 2 |-> 0] ]

(* Order Replace Or Cancel Ack at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceOrCancelAck ==
    { ZeroOrderReplaceOrCancelAck }
        \cup { [ZeroOrderReplaceOrCancelAck EXCEPT !.newClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceOrCancelAck EXCEPT !.prevClOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceOrCancelAck EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceOrCancelAck EXCEPT !.errorCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Canceled Or Expired: 15 bytes                                     *)
(***************************************************************************)

OrderCanceledOrExpired ==
    [ clOrderId : Sample(4),
      orderId   : Sample(8),
      status    : Sample(1),
      type      : Sample(2) ]

EncodeOrderCanceledOrExpired(message) ==
    message.clOrderId
        \o message.orderId
        \o message.status
        \o message.type

DecodeOrderCanceledOrExpired(bytes) ==
    LET clOrderId == ReadBytes(bytes, 4) IN IF ~clOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET type == ReadBytes(status.rest, 2) IN IF ~type.ok THEN Fail ELSE
    Ok([ clOrderId |-> clOrderId.value,
         orderId   |-> orderId.value,
         status    |-> status.value,
         type      |-> type.value ], type.rest)

ZeroOrderCanceledOrExpired ==
    [ clOrderId |-> [i \in 1 .. 4 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      status    |-> [i \in 1 .. 1 |-> 0],
      type      |-> [i \in 1 .. 2 |-> 0] ]

(* Order Canceled Or Expired at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledOrExpired ==
    { ZeroOrderCanceledOrExpired }
        \cup { [ZeroOrderCanceledOrExpired EXCEPT !.clOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledOrExpired EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledOrExpired EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderCanceledOrExpired EXCEPT !.type = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade: 85 bytes                                                         *)
(***************************************************************************)

Trade ==
    [ clOrderId       : Sample(4),
      orderId         : Sample(8),
      instrumentIndex : Sample(2),
      side            : Sample(1),
      fillAmt         : Sample(8),
      fillRate        : Sample(4),
      execBroker      : Sample(4),
      executionId     : Sample(20),
      execType        : Sample(1),
      settleDate      : Sample(8),
      tradeDate       : Sample(8),
      transactTime    : Sample(8),
      leavesAmt       : Sample(8),
      aggressorFlag   : Sample(1) ]

EncodeTrade(message) ==
    message.clOrderId
        \o message.orderId
        \o message.instrumentIndex
        \o message.side
        \o message.fillAmt
        \o message.fillRate
        \o message.execBroker
        \o message.executionId
        \o message.execType
        \o message.settleDate
        \o message.tradeDate
        \o message.transactTime
        \o message.leavesAmt
        \o message.aggressorFlag

DecodeTrade(bytes) ==
    LET clOrderId == ReadBytes(bytes, 4) IN IF ~clOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(orderId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET fillAmt == ReadBytes(side.rest, 8) IN IF ~fillAmt.ok THEN Fail ELSE
    LET fillRate == ReadBytes(fillAmt.rest, 4) IN IF ~fillRate.ok THEN Fail ELSE
    LET execBroker == ReadBytes(fillRate.rest, 4) IN IF ~execBroker.ok THEN Fail ELSE
    LET executionId == ReadBytes(execBroker.rest, 20) IN IF ~executionId.ok THEN Fail ELSE
    LET execType == ReadBytes(executionId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET settleDate == ReadBytes(execType.rest, 8) IN IF ~settleDate.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(settleDate.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradeDate.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET leavesAmt == ReadBytes(transactTime.rest, 8) IN IF ~leavesAmt.ok THEN Fail ELSE
    LET aggressorFlag == ReadBytes(leavesAmt.rest, 1) IN IF ~aggressorFlag.ok THEN Fail ELSE
    Ok([ clOrderId       |-> clOrderId.value,
         orderId         |-> orderId.value,
         instrumentIndex |-> instrumentIndex.value,
         side            |-> side.value,
         fillAmt         |-> fillAmt.value,
         fillRate        |-> fillRate.value,
         execBroker      |-> execBroker.value,
         executionId     |-> executionId.value,
         execType        |-> execType.value,
         settleDate      |-> settleDate.value,
         tradeDate       |-> tradeDate.value,
         transactTime    |-> transactTime.value,
         leavesAmt       |-> leavesAmt.value,
         aggressorFlag   |-> aggressorFlag.value ], aggressorFlag.rest)

ZeroTrade ==
    [ clOrderId       |-> [i \in 1 .. 4 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      fillAmt         |-> [i \in 1 .. 8 |-> 0],
      fillRate        |-> [i \in 1 .. 4 |-> 0],
      execBroker      |-> [i \in 1 .. 4 |-> 0],
      executionId     |-> [i \in 1 .. 20 |-> 0],
      execType        |-> [i \in 1 .. 1 |-> 0],
      settleDate      |-> [i \in 1 .. 8 |-> 0],
      tradeDate       |-> [i \in 1 .. 8 |-> 0],
      transactTime    |-> [i \in 1 .. 8 |-> 0],
      leavesAmt       |-> [i \in 1 .. 8 |-> 0],
      aggressorFlag   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade at zero, then each field in turn at the values it is checked at *)
CheckedTrade ==
    { ZeroTrade }
        \cup { [ZeroTrade EXCEPT !.clOrderId = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroTrade EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.fillAmt = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.fillRate = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.execBroker = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.executionId = one] : one \in Sample(20) }
        \cup { [ZeroTrade EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.settleDate = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.leavesAmt = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.aggressorFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Pending Fill: 33 bytes                                                  *)
(***************************************************************************)

PendingFill ==
    [ clOrderId     : Sample(4),
      orderId       : Sample(8),
      tradeLinkId   : Sample(4),
      fillAmt       : Sample(8),
      fillRate      : Sample(4),
      aggressorFlag : Sample(1),
      execBroker    : Sample(4) ]

EncodePendingFill(message) ==
    message.clOrderId
        \o message.orderId
        \o message.tradeLinkId
        \o message.fillAmt
        \o message.fillRate
        \o message.aggressorFlag
        \o message.execBroker

DecodePendingFill(bytes) ==
    LET clOrderId == ReadBytes(bytes, 4) IN IF ~clOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeLinkId == ReadBytes(orderId.rest, 4) IN IF ~tradeLinkId.ok THEN Fail ELSE
    LET fillAmt == ReadBytes(tradeLinkId.rest, 8) IN IF ~fillAmt.ok THEN Fail ELSE
    LET fillRate == ReadBytes(fillAmt.rest, 4) IN IF ~fillRate.ok THEN Fail ELSE
    LET aggressorFlag == ReadBytes(fillRate.rest, 1) IN IF ~aggressorFlag.ok THEN Fail ELSE
    LET execBroker == ReadBytes(aggressorFlag.rest, 4) IN IF ~execBroker.ok THEN Fail ELSE
    Ok([ clOrderId     |-> clOrderId.value,
         orderId       |-> orderId.value,
         tradeLinkId   |-> tradeLinkId.value,
         fillAmt       |-> fillAmt.value,
         fillRate      |-> fillRate.value,
         aggressorFlag |-> aggressorFlag.value,
         execBroker    |-> execBroker.value ], execBroker.rest)

ZeroPendingFill ==
    [ clOrderId     |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      tradeLinkId   |-> [i \in 1 .. 4 |-> 0],
      fillAmt       |-> [i \in 1 .. 8 |-> 0],
      fillRate      |-> [i \in 1 .. 4 |-> 0],
      aggressorFlag |-> [i \in 1 .. 1 |-> 0],
      execBroker    |-> [i \in 1 .. 4 |-> 0] ]

(* Pending Fill at zero, then each field in turn at the values it is checked at *)
CheckedPendingFill ==
    { ZeroPendingFill }
        \cup { [ZeroPendingFill EXCEPT !.clOrderId = one] : one \in Sample(4) }
        \cup { [ZeroPendingFill EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroPendingFill EXCEPT !.tradeLinkId = one] : one \in Sample(4) }
        \cup { [ZeroPendingFill EXCEPT !.fillAmt = one] : one \in Sample(8) }
        \cup { [ZeroPendingFill EXCEPT !.fillRate = one] : one \in Sample(4) }
        \cup { [ZeroPendingFill EXCEPT !.aggressorFlag = one] : one \in Sample(1) }
        \cup { [ZeroPendingFill EXCEPT !.execBroker = one] : one \in Sample(4) }

(***************************************************************************)
(* Pending Fill Cancel: 16 bytes                                           *)
(***************************************************************************)

PendingFillCancel ==
    [ clOrderId   : Sample(4),
      orderId     : Sample(8),
      tradeLinkId : Sample(4) ]

EncodePendingFillCancel(message) ==
    message.clOrderId
        \o message.orderId
        \o message.tradeLinkId

DecodePendingFillCancel(bytes) ==
    LET clOrderId == ReadBytes(bytes, 4) IN IF ~clOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeLinkId == ReadBytes(orderId.rest, 4) IN IF ~tradeLinkId.ok THEN Fail ELSE
    Ok([ clOrderId   |-> clOrderId.value,
         orderId     |-> orderId.value,
         tradeLinkId |-> tradeLinkId.value ], tradeLinkId.rest)

ZeroPendingFillCancel ==
    [ clOrderId   |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      tradeLinkId |-> [i \in 1 .. 4 |-> 0] ]

(* Pending Fill Cancel at zero, then each field in turn at the values it is checked at *)
CheckedPendingFillCancel ==
    { ZeroPendingFillCancel }
        \cup { [ZeroPendingFillCancel EXCEPT !.clOrderId = one] : one \in Sample(4) }
        \cup { [ZeroPendingFillCancel EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroPendingFillCancel EXCEPT !.tradeLinkId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Pending: 34 bytes                                                 *)
(***************************************************************************)

TradePending ==
    [ execType      : Sample(1),
      settleDate    : Sample(8),
      tradeDate     : Sample(8),
      transactTime  : Sample(8),
      leavesAmt     : Sample(8),
      aggressorFlag : Sample(1) ]

EncodeTradePending(message) ==
    message.execType
        \o message.settleDate
        \o message.tradeDate
        \o message.transactTime
        \o message.leavesAmt
        \o message.aggressorFlag

DecodeTradePending(bytes) ==
    LET execType == ReadBytes(bytes, 1) IN IF ~execType.ok THEN Fail ELSE
    LET settleDate == ReadBytes(execType.rest, 8) IN IF ~settleDate.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(settleDate.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradeDate.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET leavesAmt == ReadBytes(transactTime.rest, 8) IN IF ~leavesAmt.ok THEN Fail ELSE
    LET aggressorFlag == ReadBytes(leavesAmt.rest, 1) IN IF ~aggressorFlag.ok THEN Fail ELSE
    Ok([ execType      |-> execType.value,
         settleDate    |-> settleDate.value,
         tradeDate     |-> tradeDate.value,
         transactTime  |-> transactTime.value,
         leavesAmt     |-> leavesAmt.value,
         aggressorFlag |-> aggressorFlag.value ], aggressorFlag.rest)

ZeroTradePending ==
    [ execType      |-> [i \in 1 .. 1 |-> 0],
      settleDate    |-> [i \in 1 .. 8 |-> 0],
      tradeDate     |-> [i \in 1 .. 8 |-> 0],
      transactTime  |-> [i \in 1 .. 8 |-> 0],
      leavesAmt     |-> [i \in 1 .. 8 |-> 0],
      aggressorFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Pending at zero, then each field in turn at the values it is checked at *)
CheckedTradePending ==
    { ZeroTradePending }
        \cup { [ZeroTradePending EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTradePending EXCEPT !.settleDate = one] : one \in Sample(8) }
        \cup { [ZeroTradePending EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradePending EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradePending EXCEPT !.leavesAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradePending EXCEPT !.aggressorFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Resend Request: 4 bytes                                                 *)
(***************************************************************************)

ResendRequest ==
    [ beginSeqNo : Sample(4) ]

EncodeResendRequest(message) ==
    message.beginSeqNo

DecodeResendRequest(bytes) ==
    LET beginSeqNo == ReadBytes(bytes, 4) IN IF ~beginSeqNo.ok THEN Fail ELSE
    Ok([ beginSeqNo |-> beginSeqNo.value ], beginSeqNo.rest)

ZeroResendRequest ==
    [ beginSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Resend Request at zero, then each field in turn at the values it is checked at *)
CheckedResendRequest ==
    { ZeroResendRequest }
        \cup { [ZeroResendRequest EXCEPT !.beginSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Gap Fill: 5 bytes                                                       *)
(***************************************************************************)

GapFill ==
    [ newSeqNo   : Sample(4),
      reasonCode : Sample(1) ]

EncodeGapFill(message) ==
    message.newSeqNo
        \o message.reasonCode

DecodeGapFill(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(newSeqNo.rest, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ newSeqNo   |-> newSeqNo.value,
         reasonCode |-> reasonCode.value ], reasonCode.rest)

ZeroGapFill ==
    [ newSeqNo   |-> [i \in 1 .. 4 |-> 0],
      reasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Gap Fill at zero, then each field in turn at the values it is checked at *)
CheckedGapFill ==
    { ZeroGapFill }
        \cup { [ZeroGapFill EXCEPT !.newSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroGapFill EXCEPT !.reasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

LogonCode == 65  \* "A"
LogoutCode == 66  \* "B"
HeartbeatCode == 67  \* "C"
InstrumentInfoRequestCode == 69  \* "E"
InstrumentInfoCode == 68  \* "D"
NewOrderRequestCode == 76  \* "L"
NewOrderAckCode == 77  \* "M"
OrderCancelRequestCode == 78  \* "N"
OrderCancelRejectCode == 79  \* "O"
OrderReplaceOrCancelRequestCode == 80  \* "P"
OrderReplaceOrCancelAckCode == 81  \* "Q"
OrderCanceledOrExpiredCode == 82  \* "R"
TradeCode == 84  \* "T"
PendingFillCode == 85  \* "U"
PendingFillCancelCode == 86  \* "V"
TradePendingCode == 116  \* "t"
ResendRequestCode == 50  \* "2"
GapFillCode == 52  \* "4"

MessageBody ==
    [ tag : {LogonCode}, body : Logon ]
        \cup [ tag : {LogoutCode}, body : Logout ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InstrumentInfoRequestCode}, body : InstrumentInfoRequest ]
        \cup [ tag : {InstrumentInfoCode}, body : InstrumentInfo ]
        \cup [ tag : {NewOrderRequestCode}, body : NewOrderRequest ]
        \cup [ tag : {NewOrderAckCode}, body : NewOrderAck ]
        \cup [ tag : {OrderCancelRequestCode}, body : OrderCancelRequest ]
        \cup [ tag : {OrderCancelRejectCode}, body : OrderCancelReject ]
        \cup [ tag : {OrderReplaceOrCancelRequestCode}, body : OrderReplaceOrCancelRequest ]
        \cup [ tag : {OrderReplaceOrCancelAckCode}, body : OrderReplaceOrCancelAck ]
        \cup [ tag : {OrderCanceledOrExpiredCode}, body : OrderCanceledOrExpired ]
        \cup [ tag : {TradeCode}, body : Trade ]
        \cup [ tag : {PendingFillCode}, body : PendingFill ]
        \cup [ tag : {PendingFillCancelCode}, body : PendingFillCancel ]
        \cup [ tag : {TradePendingCode}, body : TradePending ]
        \cup [ tag : {ResendRequestCode}, body : ResendRequest ]
        \cup [ tag : {GapFillCode}, body : GapFill ]

EncodeMessageBody(message) ==
    CASE message.tag = LogonCode -> EncodeLogon(message.body)
      [] message.tag = LogoutCode -> EncodeLogout(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InstrumentInfoRequestCode -> EncodeInstrumentInfoRequest(message.body)
      [] message.tag = InstrumentInfoCode -> EncodeInstrumentInfo(message.body)
      [] message.tag = NewOrderRequestCode -> EncodeNewOrderRequest(message.body)
      [] message.tag = NewOrderAckCode -> EncodeNewOrderAck(message.body)
      [] message.tag = OrderCancelRequestCode -> EncodeOrderCancelRequest(message.body)
      [] message.tag = OrderCancelRejectCode -> EncodeOrderCancelReject(message.body)
      [] message.tag = OrderReplaceOrCancelRequestCode -> EncodeOrderReplaceOrCancelRequest(message.body)
      [] message.tag = OrderReplaceOrCancelAckCode -> EncodeOrderReplaceOrCancelAck(message.body)
      [] message.tag = OrderCanceledOrExpiredCode -> EncodeOrderCanceledOrExpired(message.body)
      [] message.tag = TradeCode -> EncodeTrade(message.body)
      [] message.tag = PendingFillCode -> EncodePendingFill(message.body)
      [] message.tag = PendingFillCancelCode -> EncodePendingFillCancel(message.body)
      [] message.tag = TradePendingCode -> EncodeTradePending(message.body)
      [] message.tag = ResendRequestCode -> EncodeResendRequest(message.body)
      [] message.tag = GapFillCode -> EncodeGapFill(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LogonCode -> DecodeLogon(bytes)
              [] tag = LogoutCode -> DecodeLogout(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InstrumentInfoRequestCode -> DecodeInstrumentInfoRequest(bytes)
              [] tag = InstrumentInfoCode -> DecodeInstrumentInfo(bytes)
              [] tag = NewOrderRequestCode -> DecodeNewOrderRequest(bytes)
              [] tag = NewOrderAckCode -> DecodeNewOrderAck(bytes)
              [] tag = OrderCancelRequestCode -> DecodeOrderCancelRequest(bytes)
              [] tag = OrderCancelRejectCode -> DecodeOrderCancelReject(bytes)
              [] tag = OrderReplaceOrCancelRequestCode -> DecodeOrderReplaceOrCancelRequest(bytes)
              [] tag = OrderReplaceOrCancelAckCode -> DecodeOrderReplaceOrCancelAck(bytes)
              [] tag = OrderCanceledOrExpiredCode -> DecodeOrderCanceledOrExpired(bytes)
              [] tag = TradeCode -> DecodeTrade(bytes)
              [] tag = PendingFillCode -> DecodePendingFill(bytes)
              [] tag = PendingFillCancelCode -> DecodePendingFillCancel(bytes)
              [] tag = TradePendingCode -> DecodeTradePending(bytes)
              [] tag = ResendRequestCode -> DecodeResendRequest(bytes)
              [] tag = GapFillCode -> DecodeGapFill(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> LogonCode, body |-> ZeroLogon]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> LogonCode, body |-> one] : one \in CheckedLogon }
        \cup { [tag |-> LogoutCode, body |-> one] : one \in CheckedLogout }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InstrumentInfoRequestCode, body |-> one] : one \in CheckedInstrumentInfoRequest }
        \cup { [tag |-> InstrumentInfoCode, body |-> one] : one \in CheckedInstrumentInfo }
        \cup { [tag |-> NewOrderRequestCode, body |-> one] : one \in CheckedNewOrderRequest }
        \cup { [tag |-> NewOrderAckCode, body |-> one] : one \in CheckedNewOrderAck }
        \cup { [tag |-> OrderCancelRequestCode, body |-> one] : one \in CheckedOrderCancelRequest }
        \cup { [tag |-> OrderCancelRejectCode, body |-> one] : one \in CheckedOrderCancelReject }
        \cup { [tag |-> OrderReplaceOrCancelRequestCode, body |-> one] : one \in CheckedOrderReplaceOrCancelRequest }
        \cup { [tag |-> OrderReplaceOrCancelAckCode, body |-> one] : one \in CheckedOrderReplaceOrCancelAck }
        \cup { [tag |-> OrderCanceledOrExpiredCode, body |-> one] : one \in CheckedOrderCanceledOrExpired }
        \cup { [tag |-> TradeCode, body |-> one] : one \in CheckedTrade }
        \cup { [tag |-> PendingFillCode, body |-> one] : one \in CheckedPendingFill }
        \cup { [tag |-> PendingFillCancelCode, body |-> one] : one \in CheckedPendingFillCancel }
        \cup { [tag |-> TradePendingCode, body |-> one] : one \in CheckedTradePending }
        \cup { [tag |-> ResendRequestCode, body |-> one] : one \in CheckedResendRequest }
        \cup { [tag |-> GapFillCode, body |-> one] : one \in CheckedGapFill }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ soh            : Sample(1),
      sequenceNumber : Sample(4),
      timestamp      : Sample(4),
      messageBody    : MessageBody,
      etx            : Sample(1) ]

EncodePacket(message) ==
    message.soh
        \o message.sequenceNumber
        \o message.timestamp
        \o EncodeUIntBE(message.messageBody.tag, 1)
        \o EncodeMessageBody(message.messageBody)
        \o message.etx

DecodePacket(bytes) ==
    LET soh == ReadBytes(bytes, 1) IN IF ~soh.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(soh.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequenceNumber.rest, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, messageType.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET etx == ReadBytes(messageBody.rest, 1) IN IF ~etx.ok THEN Fail ELSE
    Ok([ soh            |-> soh.value,
         sequenceNumber |-> sequenceNumber.value,
         timestamp      |-> timestamp.value,
         messageBody    |-> messageBody.value,
         etx            |-> etx.value ], etx.rest)

ZeroPacket ==
    [ soh            |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      timestamp      |-> [i \in 1 .. 4 |-> 0],
      messageBody    |-> ZeroMessageBody,
      etx            |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.soh = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.etx = one] : one \in Sample(1) }

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

(* Every Logon decodes back to what was encoded, and leaves nothing over *)
RoundTripLogon ==
    \A message \in CheckedLogon :
        LET read == DecodeLogon(EncodeLogon(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout decodes back to what was encoded, and leaves nothing over *)
RoundTripLogout ==
    \A message \in CheckedLogout :
        LET read == DecodeLogout(EncodeLogout(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoRequest ==
    \A message \in CheckedInstrumentInfoRequest :
        LET read == DecodeInstrumentInfoRequest(EncodeInstrumentInfoRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfo ==
    \A message \in CheckedInstrumentInfo :
        LET read == DecodeInstrumentInfo(EncodeInstrumentInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRequest ==
    \A message \in CheckedNewOrderRequest :
        LET read == DecodeNewOrderRequest(EncodeNewOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderAck ==
    \A message \in CheckedNewOrderAck :
        LET read == DecodeNewOrderAck(EncodeNewOrderAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequest ==
    \A message \in CheckedOrderCancelRequest :
        LET read == DecodeOrderCancelRequest(EncodeOrderCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReject ==
    \A message \in CheckedOrderCancelReject :
        LET read == DecodeOrderCancelReject(EncodeOrderCancelReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Or Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceOrCancelRequest ==
    \A message \in CheckedOrderReplaceOrCancelRequest :
        LET read == DecodeOrderReplaceOrCancelRequest(EncodeOrderReplaceOrCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Or Cancel Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceOrCancelAck ==
    \A message \in CheckedOrderReplaceOrCancelAck :
        LET read == DecodeOrderReplaceOrCancelAck(EncodeOrderReplaceOrCancelAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Or Expired decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledOrExpired ==
    \A message \in CheckedOrderCanceledOrExpired :
        LET read == DecodeOrderCanceledOrExpired(EncodeOrderCanceledOrExpired(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripTrade ==
    \A message \in CheckedTrade :
        LET read == DecodeTrade(EncodeTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pending Fill decodes back to what was encoded, and leaves nothing over *)
RoundTripPendingFill ==
    \A message \in CheckedPendingFill :
        LET read == DecodePendingFill(EncodePendingFill(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pending Fill Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripPendingFillCancel ==
    \A message \in CheckedPendingFillCancel :
        LET read == DecodePendingFillCancel(EncodePendingFillCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Pending decodes back to what was encoded, and leaves nothing over *)
RoundTripTradePending ==
    \A message \in CheckedTradePending :
        LET read == DecodeTradePending(EncodeTradePending(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Request decodes back to what was encoded, and leaves nothing over *)
RoundTripResendRequest ==
    \A message \in CheckedResendRequest :
        LET read == DecodeResendRequest(EncodeResendRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gap Fill decodes back to what was encoded, and leaves nothing over *)
RoundTripGapFill ==
    \A message \in CheckedGapFill :
        LET read == DecodeGapFill(EncodeGapFill(message))
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

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
