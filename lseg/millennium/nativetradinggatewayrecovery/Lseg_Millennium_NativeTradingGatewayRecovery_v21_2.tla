-------- MODULE Lseg_Millennium_NativeTradingGatewayRecovery_v21_2 ---------
(***************************************************************************)
(* London Stock Exchange Native Trading Gateway Recovery v21.2             *)
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
(* Note: Waiver Flags Post Trade Flags is a bit field set, checked as its  *)
(* 1 byte rather than bit by bit.                                          *)
(*                                                                         *)
(* Note: Mi Fid Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Party Role Qualifiers is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Waiver Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
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
(* Logon Message: 76 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ userName       : Sample(25),
      password       : Sample(25),
      newPassword    : Sample(25),
      messageVersion : Sample(1) ]

EncodeLogonMessage(message) ==
    message.userName
        \o message.password
        \o message.newPassword
        \o message.messageVersion

DecodeLogonMessage(bytes) ==
    LET userName == ReadBytes(bytes, 25) IN IF ~userName.ok THEN Fail ELSE
    LET password == ReadBytes(userName.rest, 25) IN IF ~password.ok THEN Fail ELSE
    LET newPassword == ReadBytes(password.rest, 25) IN IF ~newPassword.ok THEN Fail ELSE
    LET messageVersion == ReadBytes(newPassword.rest, 1) IN IF ~messageVersion.ok THEN Fail ELSE
    Ok([ userName       |-> userName.value,
         password       |-> password.value,
         newPassword    |-> newPassword.value,
         messageVersion |-> messageVersion.value ], messageVersion.rest)

ZeroLogonMessage ==
    [ userName       |-> [i \in 1 .. 25 |-> 0],
      password       |-> [i \in 1 .. 25 |-> 0],
      newPassword    |-> [i \in 1 .. 25 |-> 0],
      messageVersion |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.userName = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.newPassword = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.messageVersion = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Reply Message: 34 bytes                                           *)
(***************************************************************************)

LogonReplyMessage ==
    [ rejectCode             : Sample(4),
      passwordExpiryDayCount : Sample(30) ]

EncodeLogonReplyMessage(message) ==
    message.rejectCode
        \o message.passwordExpiryDayCount

DecodeLogonReplyMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET passwordExpiryDayCount == ReadBytes(rejectCode.rest, 30) IN IF ~passwordExpiryDayCount.ok THEN Fail ELSE
    Ok([ rejectCode             |-> rejectCode.value,
         passwordExpiryDayCount |-> passwordExpiryDayCount.value ], passwordExpiryDayCount.rest)

ZeroLogonReplyMessage ==
    [ rejectCode             |-> [i \in 1 .. 4 |-> 0],
      passwordExpiryDayCount |-> [i \in 1 .. 30 |-> 0] ]

(* Logon Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonReplyMessage ==
    { ZeroLogonReplyMessage }
        \cup { [ZeroLogonReplyMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroLogonReplyMessage EXCEPT !.passwordExpiryDayCount = one] : one \in Sample(30) }

(***************************************************************************)
(* Logout Message: 20 bytes                                                *)
(***************************************************************************)

LogoutMessage ==
    [ reason : Sample(20) ]

EncodeLogoutMessage(message) ==
    message.reason

DecodeLogoutMessage(bytes) ==
    LET reason == ReadBytes(bytes, 20) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroLogoutMessage ==
    [ reason |-> [i \in 1 .. 20 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.reason = one] : one \in Sample(20) }

(***************************************************************************)
(* Missed Message Request Message: 5 bytes                                 *)
(***************************************************************************)

MissedMessageRequestMessage ==
    [ appId         : Sample(1),
      lastMsgSeqNum : Sample(4) ]

EncodeMissedMessageRequestMessage(message) ==
    message.appId
        \o message.lastMsgSeqNum

DecodeMissedMessageRequestMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET lastMsgSeqNum == ReadBytes(appId.rest, 4) IN IF ~lastMsgSeqNum.ok THEN Fail ELSE
    Ok([ appId         |-> appId.value,
         lastMsgSeqNum |-> lastMsgSeqNum.value ], lastMsgSeqNum.rest)

ZeroMissedMessageRequestMessage ==
    [ appId         |-> [i \in 1 .. 1 |-> 0],
      lastMsgSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Missed Message Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMissedMessageRequestMessage ==
    { ZeroMissedMessageRequestMessage }
        \cup { [ZeroMissedMessageRequestMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroMissedMessageRequestMessage EXCEPT !.lastMsgSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Missed Message Request Ack Message: 1 bytes                             *)
(***************************************************************************)

MissedMessageRequestAckMessage ==
    [ missedMessageRequestAckResponseType : Sample(1) ]

EncodeMissedMessageRequestAckMessage(message) ==
    message.missedMessageRequestAckResponseType

DecodeMissedMessageRequestAckMessage(bytes) ==
    LET missedMessageRequestAckResponseType == ReadBytes(bytes, 1) IN IF ~missedMessageRequestAckResponseType.ok THEN Fail ELSE
    Ok([ missedMessageRequestAckResponseType |-> missedMessageRequestAckResponseType.value ], missedMessageRequestAckResponseType.rest)

ZeroMissedMessageRequestAckMessage ==
    [ missedMessageRequestAckResponseType |-> [i \in 1 .. 1 |-> 0] ]

(* Missed Message Request Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMissedMessageRequestAckMessage ==
    { ZeroMissedMessageRequestAckMessage }
        \cup { [ZeroMissedMessageRequestAckMessage EXCEPT !.missedMessageRequestAckResponseType = one] : one \in Sample(1) }

(***************************************************************************)
(* Missed Message Report Message: 1 bytes                                  *)
(***************************************************************************)

MissedMessageReportMessage ==
    [ missedMessageReportResponseType : Sample(1) ]

EncodeMissedMessageReportMessage(message) ==
    message.missedMessageReportResponseType

DecodeMissedMessageReportMessage(bytes) ==
    LET missedMessageReportResponseType == ReadBytes(bytes, 1) IN IF ~missedMessageReportResponseType.ok THEN Fail ELSE
    Ok([ missedMessageReportResponseType |-> missedMessageReportResponseType.value ], missedMessageReportResponseType.rest)

ZeroMissedMessageReportMessage ==
    [ missedMessageReportResponseType |-> [i \in 1 .. 1 |-> 0] ]

(* Missed Message Report Message at zero, then each field in turn at the values it is checked at *)
CheckedMissedMessageReportMessage ==
    { ZeroMissedMessageReportMessage }
        \cup { [ZeroMissedMessageReportMessage EXCEPT !.missedMessageReportResponseType = one] : one \in Sample(1) }

(***************************************************************************)
(* Reject Message: 55 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ rejectCode          : Sample(4),
      rejectReason        : Sample(30),
      rejectedMessageType : Sample(1),
      clientOrderId       : Sample(20) ]

EncodeRejectMessage(message) ==
    message.rejectCode
        \o message.rejectReason
        \o message.rejectedMessageType
        \o message.clientOrderId

DecodeRejectMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(rejectCode.rest, 30) IN IF ~rejectReason.ok THEN Fail ELSE
    LET rejectedMessageType == ReadBytes(rejectReason.rest, 1) IN IF ~rejectedMessageType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(rejectedMessageType.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ rejectCode          |-> rejectCode.value,
         rejectReason        |-> rejectReason.value,
         rejectedMessageType |-> rejectedMessageType.value,
         clientOrderId       |-> clientOrderId.value ], clientOrderId.rest)

ZeroRejectMessage ==
    [ rejectCode          |-> [i \in 1 .. 4 |-> 0],
      rejectReason        |-> [i \in 1 .. 30 |-> 0],
      rejectedMessageType |-> [i \in 1 .. 1 |-> 0],
      clientOrderId       |-> [i \in 1 .. 20 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectReason = one] : one \in Sample(30) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectedMessageType = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* System Status Message: 2 bytes                                          *)
(***************************************************************************)

SystemStatusMessage ==
    [ appId     : Sample(1),
      appStatus : Sample(1) ]

EncodeSystemStatusMessage(message) ==
    message.appId
        \o message.appStatus

DecodeSystemStatusMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET appStatus == ReadBytes(appId.rest, 1) IN IF ~appStatus.ok THEN Fail ELSE
    Ok([ appId     |-> appId.value,
         appStatus |-> appStatus.value ], appStatus.rest)

ZeroSystemStatusMessage ==
    [ appId     |-> [i \in 1 .. 1 |-> 0],
      appStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStatusMessage ==
    { ZeroSystemStatusMessage }
        \cup { [ZeroSystemStatusMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStatusMessage EXCEPT !.appStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime ==
    { ZeroTransactTime }
        \cup { [ZeroTransactTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Execution Report Message: 151 bytes                                     *)
(***************************************************************************)

ExecutionReportMessage ==
    [ appId                         : Sample(1),
      sequenceNo                    : Sample(4),
      executionId                   : Sample(12),
      clientOrderId                 : Sample(20),
      orderId                       : Sample(12),
      execType                      : Sample(1),
      executionReportRefId          : Sample(12),
      executionReportOrderStatus    : Sample(1),
      orderRejectCode               : Sample(4),
      executedPrice                 : Sample(8),
      executedQty                   : Sample(4),
      leavesQty                     : Sample(4),
      waiverFlagsPostTradeFlags     : Sample(1),
      displayQty                    : Sample(4),
      instrumentId                  : Sample(4),
      restatementReason             : Sample(1),
      executionReportPeggedExecInst : Sample(1),
      side                          : Sample(1),
      ownerType                     : Sample(1),
      reserved7                     : Sample(7),
      counterparty                  : Sample(11),
      tradeLiquidityIndicator       : Sample(1),
      tradeMatchId                  : Sample(8),
      transactTime                  : TransactTime,
      lastMarket                    : Sample(1),
      typeOfTrade                   : Sample(1),
      capacity                      : Sample(1),
      reserved1                     : Sample(1),
      publicOrderId                 : Sample(12),
      minimumQuantity               : Sample(4) ]

EncodeExecutionReportMessage(message) ==
    message.appId
        \o message.sequenceNo
        \o message.executionId
        \o message.clientOrderId
        \o message.orderId
        \o message.execType
        \o message.executionReportRefId
        \o message.executionReportOrderStatus
        \o message.orderRejectCode
        \o message.executedPrice
        \o message.executedQty
        \o message.leavesQty
        \o message.waiverFlagsPostTradeFlags
        \o message.displayQty
        \o message.instrumentId
        \o message.restatementReason
        \o message.executionReportPeggedExecInst
        \o message.side
        \o message.ownerType
        \o message.reserved7
        \o message.counterparty
        \o message.tradeLiquidityIndicator
        \o message.tradeMatchId
        \o EncodeTransactTime(message.transactTime)
        \o message.lastMarket
        \o message.typeOfTrade
        \o message.capacity
        \o message.reserved1
        \o message.publicOrderId
        \o message.minimumQuantity

DecodeExecutionReportMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET sequenceNo == ReadBytes(appId.rest, 4) IN IF ~sequenceNo.ok THEN Fail ELSE
    LET executionId == ReadBytes(sequenceNo.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(executionId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET execType == ReadBytes(orderId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET executionReportRefId == ReadBytes(execType.rest, 12) IN IF ~executionReportRefId.ok THEN Fail ELSE
    LET executionReportOrderStatus == ReadBytes(executionReportRefId.rest, 1) IN IF ~executionReportOrderStatus.ok THEN Fail ELSE
    LET orderRejectCode == ReadBytes(executionReportOrderStatus.rest, 4) IN IF ~orderRejectCode.ok THEN Fail ELSE
    LET executedPrice == ReadBytes(orderRejectCode.rest, 8) IN IF ~executedPrice.ok THEN Fail ELSE
    LET executedQty == ReadBytes(executedPrice.rest, 4) IN IF ~executedQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(executedQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET waiverFlagsPostTradeFlags == ReadBytes(leavesQty.rest, 1) IN IF ~waiverFlagsPostTradeFlags.ok THEN Fail ELSE
    LET displayQty == ReadBytes(waiverFlagsPostTradeFlags.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(displayQty.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(instrumentId.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    LET executionReportPeggedExecInst == ReadBytes(restatementReason.rest, 1) IN IF ~executionReportPeggedExecInst.ok THEN Fail ELSE
    LET side == ReadBytes(executionReportPeggedExecInst.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ownerType == ReadBytes(side.rest, 1) IN IF ~ownerType.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(ownerType.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    LET counterparty == ReadBytes(reserved7.rest, 11) IN IF ~counterparty.ok THEN Fail ELSE
    LET tradeLiquidityIndicator == ReadBytes(counterparty.rest, 1) IN IF ~tradeLiquidityIndicator.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(tradeLiquidityIndicator.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime(tradeMatchId.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastMarket == ReadBytes(transactTime.rest, 1) IN IF ~lastMarket.ok THEN Fail ELSE
    LET typeOfTrade == ReadBytes(lastMarket.rest, 1) IN IF ~typeOfTrade.ok THEN Fail ELSE
    LET capacity == ReadBytes(typeOfTrade.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(capacity.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET publicOrderId == ReadBytes(reserved1.rest, 12) IN IF ~publicOrderId.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(publicOrderId.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    Ok([ appId                         |-> appId.value,
         sequenceNo                    |-> sequenceNo.value,
         executionId                   |-> executionId.value,
         clientOrderId                 |-> clientOrderId.value,
         orderId                       |-> orderId.value,
         execType                      |-> execType.value,
         executionReportRefId          |-> executionReportRefId.value,
         executionReportOrderStatus    |-> executionReportOrderStatus.value,
         orderRejectCode               |-> orderRejectCode.value,
         executedPrice                 |-> executedPrice.value,
         executedQty                   |-> executedQty.value,
         leavesQty                     |-> leavesQty.value,
         waiverFlagsPostTradeFlags     |-> waiverFlagsPostTradeFlags.value,
         displayQty                    |-> displayQty.value,
         instrumentId                  |-> instrumentId.value,
         restatementReason             |-> restatementReason.value,
         executionReportPeggedExecInst |-> executionReportPeggedExecInst.value,
         side                          |-> side.value,
         ownerType                     |-> ownerType.value,
         reserved7                     |-> reserved7.value,
         counterparty                  |-> counterparty.value,
         tradeLiquidityIndicator       |-> tradeLiquidityIndicator.value,
         tradeMatchId                  |-> tradeMatchId.value,
         transactTime                  |-> transactTime.value,
         lastMarket                    |-> lastMarket.value,
         typeOfTrade                   |-> typeOfTrade.value,
         capacity                      |-> capacity.value,
         reserved1                     |-> reserved1.value,
         publicOrderId                 |-> publicOrderId.value,
         minimumQuantity               |-> minimumQuantity.value ], minimumQuantity.rest)

ZeroExecutionReportMessage ==
    [ appId                         |-> [i \in 1 .. 1 |-> 0],
      sequenceNo                    |-> [i \in 1 .. 4 |-> 0],
      executionId                   |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 20 |-> 0],
      orderId                       |-> [i \in 1 .. 12 |-> 0],
      execType                      |-> [i \in 1 .. 1 |-> 0],
      executionReportRefId          |-> [i \in 1 .. 12 |-> 0],
      executionReportOrderStatus    |-> [i \in 1 .. 1 |-> 0],
      orderRejectCode               |-> [i \in 1 .. 4 |-> 0],
      executedPrice                 |-> [i \in 1 .. 8 |-> 0],
      executedQty                   |-> [i \in 1 .. 4 |-> 0],
      leavesQty                     |-> [i \in 1 .. 4 |-> 0],
      waiverFlagsPostTradeFlags     |-> [i \in 1 .. 1 |-> 0],
      displayQty                    |-> [i \in 1 .. 4 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      restatementReason             |-> [i \in 1 .. 1 |-> 0],
      executionReportPeggedExecInst |-> [i \in 1 .. 1 |-> 0],
      side                          |-> [i \in 1 .. 1 |-> 0],
      ownerType                     |-> [i \in 1 .. 1 |-> 0],
      reserved7                     |-> [i \in 1 .. 7 |-> 0],
      counterparty                  |-> [i \in 1 .. 11 |-> 0],
      tradeLiquidityIndicator       |-> [i \in 1 .. 1 |-> 0],
      tradeMatchId                  |-> [i \in 1 .. 8 |-> 0],
      transactTime                  |-> ZeroTransactTime,
      lastMarket                    |-> [i \in 1 .. 1 |-> 0],
      typeOfTrade                   |-> [i \in 1 .. 1 |-> 0],
      capacity                      |-> [i \in 1 .. 1 |-> 0],
      reserved1                     |-> [i \in 1 .. 1 |-> 0],
      publicOrderId                 |-> [i \in 1 .. 12 |-> 0],
      minimumQuantity               |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportMessage ==
    { ZeroExecutionReportMessage }
        \cup { [ZeroExecutionReportMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.sequenceNo = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionReportRefId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionReportOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderRejectCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executedPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executedQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.waiverFlagsPostTradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.restatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionReportPeggedExecInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.counterparty = one] : one \in Sample(11) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.tradeLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastMarket = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.typeOfTrade = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.publicOrderId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime2 ==
    { ZeroTransactTime2 }
        \cup { [ZeroTransactTime2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mass Cancel Report Message: 52 bytes                              *)
(***************************************************************************)

OrderMassCancelReportMessage ==
    [ appId                  : Sample(1),
      sequenceNo             : Sample(4),
      clientOrderId          : Sample(20),
      massCancelResponse     : Sample(1),
      massCancelRejectReason : Sample(4),
      reserved4              : Sample(4),
      transactTime           : TransactTime2,
      reserved10             : Sample(10) ]

EncodeOrderMassCancelReportMessage(message) ==
    message.appId
        \o message.sequenceNo
        \o message.clientOrderId
        \o message.massCancelResponse
        \o message.massCancelRejectReason
        \o message.reserved4
        \o EncodeTransactTime2(message.transactTime)
        \o message.reserved10

DecodeOrderMassCancelReportMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET sequenceNo == ReadBytes(appId.rest, 4) IN IF ~sequenceNo.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sequenceNo.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET massCancelResponse == ReadBytes(clientOrderId.rest, 1) IN IF ~massCancelResponse.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(massCancelResponse.rest, 4) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(massCancelRejectReason.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime2(reserved4.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(transactTime.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ appId                  |-> appId.value,
         sequenceNo             |-> sequenceNo.value,
         clientOrderId          |-> clientOrderId.value,
         massCancelResponse     |-> massCancelResponse.value,
         massCancelRejectReason |-> massCancelRejectReason.value,
         reserved4              |-> reserved4.value,
         transactTime           |-> transactTime.value,
         reserved10             |-> reserved10.value ], reserved10.rest)

ZeroOrderMassCancelReportMessage ==
    [ appId                  |-> [i \in 1 .. 1 |-> 0],
      sequenceNo             |-> [i \in 1 .. 4 |-> 0],
      clientOrderId          |-> [i \in 1 .. 20 |-> 0],
      massCancelResponse     |-> [i \in 1 .. 1 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 4 |-> 0],
      reserved4              |-> [i \in 1 .. 4 |-> 0],
      transactTime           |-> ZeroTransactTime2,
      reserved10             |-> [i \in 1 .. 10 |-> 0] ]

(* Order Mass Cancel Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelReportMessage ==
    { ZeroOrderMassCancelReportMessage }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.sequenceNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelResponse = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime2 }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Quote Request Message: 157 bytes                                        *)
(***************************************************************************)

QuoteRequestMessage ==
    [ partitionId             : Sample(1),
      sequenceNumber          : Sample(4),
      quoteReqId              : Sample(10),
      orderBook               : Sample(1),
      privateQuote            : Sample(1),
      instrumentId            : Sample(4),
      side                    : Sample(1),
      orderQuantity           : Sample(4),
      expireTime              : Sample(4),
      marketMakers            : Sample(60),
      contraTrader            : Sample(11),
      contraFirm              : Sample(11),
      rfqId                   : Sample(10),
      clientId                : Sample(4),
      investmentDecisionMaker : Sample(4),
      executingTrader         : Sample(4),
      miFidFlags              : Sample(1),
      partyRoleQualifiers     : Sample(1),
      quoteRequestType        : Sample(1),
      price                   : Sample(8),
      rfqExecutionDelay       : Sample(1),
      rfqMinQuotes            : Sample(1),
      accountType             : Sample(1),
      orderCapacity           : Sample(1),
      rfqDiscloseSide         : Sample(1),
      expireTimeMilliseconds  : Sample(4),
      autoRfqExecStrategy     : Sample(1),
      numOfCompetitors        : Sample(1),
      marketMakerRank         : Sample(1) ]

EncodeQuoteRequestMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.quoteReqId
        \o message.orderBook
        \o message.privateQuote
        \o message.instrumentId
        \o message.side
        \o message.orderQuantity
        \o message.expireTime
        \o message.marketMakers
        \o message.contraTrader
        \o message.contraFirm
        \o message.rfqId
        \o message.clientId
        \o message.investmentDecisionMaker
        \o message.executingTrader
        \o message.miFidFlags
        \o message.partyRoleQualifiers
        \o message.quoteRequestType
        \o message.price
        \o message.rfqExecutionDelay
        \o message.rfqMinQuotes
        \o message.accountType
        \o message.orderCapacity
        \o message.rfqDiscloseSide
        \o message.expireTimeMilliseconds
        \o message.autoRfqExecStrategy
        \o message.numOfCompetitors
        \o message.marketMakerRank

DecodeQuoteRequestMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(sequenceNumber.rest, 10) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET orderBook == ReadBytes(quoteReqId.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    LET privateQuote == ReadBytes(orderBook.rest, 1) IN IF ~privateQuote.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(privateQuote.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(side.rest, 4) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET expireTime == ReadBytes(orderQuantity.rest, 4) IN IF ~expireTime.ok THEN Fail ELSE
    LET marketMakers == ReadBytes(expireTime.rest, 60) IN IF ~marketMakers.ok THEN Fail ELSE
    LET contraTrader == ReadBytes(marketMakers.rest, 11) IN IF ~contraTrader.ok THEN Fail ELSE
    LET contraFirm == ReadBytes(contraTrader.rest, 11) IN IF ~contraFirm.ok THEN Fail ELSE
    LET rfqId == ReadBytes(contraFirm.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET clientId == ReadBytes(rfqId.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET investmentDecisionMaker == ReadBytes(clientId.rest, 4) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(investmentDecisionMaker.rest, 4) IN IF ~executingTrader.ok THEN Fail ELSE
    LET miFidFlags == ReadBytes(executingTrader.rest, 1) IN IF ~miFidFlags.ok THEN Fail ELSE
    LET partyRoleQualifiers == ReadBytes(miFidFlags.rest, 1) IN IF ~partyRoleQualifiers.ok THEN Fail ELSE
    LET quoteRequestType == ReadBytes(partyRoleQualifiers.rest, 1) IN IF ~quoteRequestType.ok THEN Fail ELSE
    LET price == ReadBytes(quoteRequestType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET rfqExecutionDelay == ReadBytes(price.rest, 1) IN IF ~rfqExecutionDelay.ok THEN Fail ELSE
    LET rfqMinQuotes == ReadBytes(rfqExecutionDelay.rest, 1) IN IF ~rfqMinQuotes.ok THEN Fail ELSE
    LET accountType == ReadBytes(rfqMinQuotes.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(accountType.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET rfqDiscloseSide == ReadBytes(orderCapacity.rest, 1) IN IF ~rfqDiscloseSide.ok THEN Fail ELSE
    LET expireTimeMilliseconds == ReadBytes(rfqDiscloseSide.rest, 4) IN IF ~expireTimeMilliseconds.ok THEN Fail ELSE
    LET autoRfqExecStrategy == ReadBytes(expireTimeMilliseconds.rest, 1) IN IF ~autoRfqExecStrategy.ok THEN Fail ELSE
    LET numOfCompetitors == ReadBytes(autoRfqExecStrategy.rest, 1) IN IF ~numOfCompetitors.ok THEN Fail ELSE
    LET marketMakerRank == ReadBytes(numOfCompetitors.rest, 1) IN IF ~marketMakerRank.ok THEN Fail ELSE
    Ok([ partitionId             |-> partitionId.value,
         sequenceNumber          |-> sequenceNumber.value,
         quoteReqId              |-> quoteReqId.value,
         orderBook               |-> orderBook.value,
         privateQuote            |-> privateQuote.value,
         instrumentId            |-> instrumentId.value,
         side                    |-> side.value,
         orderQuantity           |-> orderQuantity.value,
         expireTime              |-> expireTime.value,
         marketMakers            |-> marketMakers.value,
         contraTrader            |-> contraTrader.value,
         contraFirm              |-> contraFirm.value,
         rfqId                   |-> rfqId.value,
         clientId                |-> clientId.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value,
         executingTrader         |-> executingTrader.value,
         miFidFlags              |-> miFidFlags.value,
         partyRoleQualifiers     |-> partyRoleQualifiers.value,
         quoteRequestType        |-> quoteRequestType.value,
         price                   |-> price.value,
         rfqExecutionDelay       |-> rfqExecutionDelay.value,
         rfqMinQuotes            |-> rfqMinQuotes.value,
         accountType             |-> accountType.value,
         orderCapacity           |-> orderCapacity.value,
         rfqDiscloseSide         |-> rfqDiscloseSide.value,
         expireTimeMilliseconds  |-> expireTimeMilliseconds.value,
         autoRfqExecStrategy     |-> autoRfqExecStrategy.value,
         numOfCompetitors        |-> numOfCompetitors.value,
         marketMakerRank         |-> marketMakerRank.value ], marketMakerRank.rest)

ZeroQuoteRequestMessage ==
    [ partitionId             |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber          |-> [i \in 1 .. 4 |-> 0],
      quoteReqId              |-> [i \in 1 .. 10 |-> 0],
      orderBook               |-> [i \in 1 .. 1 |-> 0],
      privateQuote            |-> [i \in 1 .. 1 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      orderQuantity           |-> [i \in 1 .. 4 |-> 0],
      expireTime              |-> [i \in 1 .. 4 |-> 0],
      marketMakers            |-> [i \in 1 .. 60 |-> 0],
      contraTrader            |-> [i \in 1 .. 11 |-> 0],
      contraFirm              |-> [i \in 1 .. 11 |-> 0],
      rfqId                   |-> [i \in 1 .. 10 |-> 0],
      clientId                |-> [i \in 1 .. 4 |-> 0],
      investmentDecisionMaker |-> [i \in 1 .. 4 |-> 0],
      executingTrader         |-> [i \in 1 .. 4 |-> 0],
      miFidFlags              |-> [i \in 1 .. 1 |-> 0],
      partyRoleQualifiers     |-> [i \in 1 .. 1 |-> 0],
      quoteRequestType        |-> [i \in 1 .. 1 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      rfqExecutionDelay       |-> [i \in 1 .. 1 |-> 0],
      rfqMinQuotes            |-> [i \in 1 .. 1 |-> 0],
      accountType             |-> [i \in 1 .. 1 |-> 0],
      orderCapacity           |-> [i \in 1 .. 1 |-> 0],
      rfqDiscloseSide         |-> [i \in 1 .. 1 |-> 0],
      expireTimeMilliseconds  |-> [i \in 1 .. 4 |-> 0],
      autoRfqExecStrategy     |-> [i \in 1 .. 1 |-> 0],
      numOfCompetitors        |-> [i \in 1 .. 1 |-> 0],
      marketMakerRank         |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quoteReqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderBook = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.privateQuote = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.expireTime = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakers = one] : one \in Sample(60) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.contraTrader = one] : one \in Sample(11) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.contraFirm = one] : one \in Sample(11) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.investmentDecisionMaker = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.executingTrader = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.miFidFlags = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.partyRoleQualifiers = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quoteRequestType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.rfqExecutionDelay = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.rfqMinQuotes = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.rfqDiscloseSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.expireTimeMilliseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.autoRfqExecStrategy = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.numOfCompetitors = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakerRank = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Status Report Message: 143 bytes                                  *)
(***************************************************************************)

QuoteStatusReportMessage ==
    [ partitionId            : Sample(1),
      sequenceNumber         : Sample(4),
      quoteMsgId             : Sample(20),
      quoteReqId             : Sample(10),
      quoteStatus            : Sample(1),
      rejectCode             : Sample(4),
      orderBook              : Sample(1),
      marketMakers           : Sample(60),
      rfqId                  : Sample(10),
      expireTime             : Sample(4),
      bidId                  : Sample(12),
      offerId                : Sample(12),
      expireTimeMilliseconds : Sample(4) ]

EncodeQuoteStatusReportMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.quoteMsgId
        \o message.quoteReqId
        \o message.quoteStatus
        \o message.rejectCode
        \o message.orderBook
        \o message.marketMakers
        \o message.rfqId
        \o message.expireTime
        \o message.bidId
        \o message.offerId
        \o message.expireTimeMilliseconds

DecodeQuoteStatusReportMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(sequenceNumber.rest, 20) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(quoteMsgId.rest, 10) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(quoteReqId.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(quoteStatus.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET orderBook == ReadBytes(rejectCode.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    LET marketMakers == ReadBytes(orderBook.rest, 60) IN IF ~marketMakers.ok THEN Fail ELSE
    LET rfqId == ReadBytes(marketMakers.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET expireTime == ReadBytes(rfqId.rest, 4) IN IF ~expireTime.ok THEN Fail ELSE
    LET bidId == ReadBytes(expireTime.rest, 12) IN IF ~bidId.ok THEN Fail ELSE
    LET offerId == ReadBytes(bidId.rest, 12) IN IF ~offerId.ok THEN Fail ELSE
    LET expireTimeMilliseconds == ReadBytes(offerId.rest, 4) IN IF ~expireTimeMilliseconds.ok THEN Fail ELSE
    Ok([ partitionId            |-> partitionId.value,
         sequenceNumber         |-> sequenceNumber.value,
         quoteMsgId             |-> quoteMsgId.value,
         quoteReqId             |-> quoteReqId.value,
         quoteStatus            |-> quoteStatus.value,
         rejectCode             |-> rejectCode.value,
         orderBook              |-> orderBook.value,
         marketMakers           |-> marketMakers.value,
         rfqId                  |-> rfqId.value,
         expireTime             |-> expireTime.value,
         bidId                  |-> bidId.value,
         offerId                |-> offerId.value,
         expireTimeMilliseconds |-> expireTimeMilliseconds.value ], expireTimeMilliseconds.rest)

ZeroQuoteStatusReportMessage ==
    [ partitionId            |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      quoteMsgId             |-> [i \in 1 .. 20 |-> 0],
      quoteReqId             |-> [i \in 1 .. 10 |-> 0],
      quoteStatus            |-> [i \in 1 .. 1 |-> 0],
      rejectCode             |-> [i \in 1 .. 4 |-> 0],
      orderBook              |-> [i \in 1 .. 1 |-> 0],
      marketMakers           |-> [i \in 1 .. 60 |-> 0],
      rfqId                  |-> [i \in 1 .. 10 |-> 0],
      expireTime             |-> [i \in 1 .. 4 |-> 0],
      bidId                  |-> [i \in 1 .. 12 |-> 0],
      offerId                |-> [i \in 1 .. 12 |-> 0],
      expireTimeMilliseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteStatusReportMessage ==
    { ZeroQuoteStatusReportMessage }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteMsgId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteReqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.orderBook = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.marketMakers = one] : one \in Sample(60) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.expireTime = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.bidId = one] : one \in Sample(12) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.offerId = one] : one \in Sample(12) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.expireTimeMilliseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Request Reject Message: 110 bytes                                 *)
(***************************************************************************)

QuoteRequestRejectMessage ==
    [ partitionId    : Sample(1),
      sequenceNumber : Sample(4),
      quoteReqId     : Sample(10),
      rejectCode     : Sample(4),
      orderBook      : Sample(1),
      instrumentId   : Sample(4),
      side           : Sample(1),
      orderQuantity  : Sample(4),
      marketMakers   : Sample(60),
      contraTrader   : Sample(11),
      rfqId          : Sample(10) ]

EncodeQuoteRequestRejectMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.quoteReqId
        \o message.rejectCode
        \o message.orderBook
        \o message.instrumentId
        \o message.side
        \o message.orderQuantity
        \o message.marketMakers
        \o message.contraTrader
        \o message.rfqId

DecodeQuoteRequestRejectMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(sequenceNumber.rest, 10) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(quoteReqId.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET orderBook == ReadBytes(rejectCode.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderBook.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(side.rest, 4) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET marketMakers == ReadBytes(orderQuantity.rest, 60) IN IF ~marketMakers.ok THEN Fail ELSE
    LET contraTrader == ReadBytes(marketMakers.rest, 11) IN IF ~contraTrader.ok THEN Fail ELSE
    LET rfqId == ReadBytes(contraTrader.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    Ok([ partitionId    |-> partitionId.value,
         sequenceNumber |-> sequenceNumber.value,
         quoteReqId     |-> quoteReqId.value,
         rejectCode     |-> rejectCode.value,
         orderBook      |-> orderBook.value,
         instrumentId   |-> instrumentId.value,
         side           |-> side.value,
         orderQuantity  |-> orderQuantity.value,
         marketMakers   |-> marketMakers.value,
         contraTrader   |-> contraTrader.value,
         rfqId          |-> rfqId.value ], rfqId.rest)

ZeroQuoteRequestRejectMessage ==
    [ partitionId    |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      quoteReqId     |-> [i \in 1 .. 10 |-> 0],
      rejectCode     |-> [i \in 1 .. 4 |-> 0],
      orderBook      |-> [i \in 1 .. 1 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      orderQuantity  |-> [i \in 1 .. 4 |-> 0],
      marketMakers   |-> [i \in 1 .. 60 |-> 0],
      contraTrader   |-> [i \in 1 .. 11 |-> 0],
      rfqId          |-> [i \in 1 .. 10 |-> 0] ]

(* Quote Request Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestRejectMessage ==
    { ZeroQuoteRequestRejectMessage }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.quoteReqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.orderBook = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.orderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.marketMakers = one] : one \in Sample(60) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.contraTrader = one] : one \in Sample(11) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.rfqId = one] : one \in Sample(10) }

(***************************************************************************)
(* Rfq Quote Message: 126 bytes                                            *)
(***************************************************************************)

RfqQuoteMessage ==
    [ partitionId             : Sample(1),
      sequenceNumber          : Sample(4),
      quoteMsgId              : Sample(20),
      rfqId                   : Sample(10),
      instrumentId            : Sample(4),
      bidPrice                : Sample(8),
      bidQuantity             : Sample(4),
      offerPrice              : Sample(8),
      offerQuantity           : Sample(4),
      autoCancel              : Sample(1),
      marketMaker             : Sample(11),
      marketMakerFirm         : Sample(11),
      bidId                   : Sample(12),
      offerId                 : Sample(12),
      capacity                : Sample(1),
      clearingAccount         : Sample(1),
      clientId                : Sample(4),
      investmentDecisionMaker : Sample(4),
      executingTrader         : Sample(4),
      miFidFlags              : Sample(1),
      partyRoleQualifiers     : Sample(1) ]

EncodeRfqQuoteMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.quoteMsgId
        \o message.rfqId
        \o message.instrumentId
        \o message.bidPrice
        \o message.bidQuantity
        \o message.offerPrice
        \o message.offerQuantity
        \o message.autoCancel
        \o message.marketMaker
        \o message.marketMakerFirm
        \o message.bidId
        \o message.offerId
        \o message.capacity
        \o message.clearingAccount
        \o message.clientId
        \o message.investmentDecisionMaker
        \o message.executingTrader
        \o message.miFidFlags
        \o message.partyRoleQualifiers

DecodeRfqQuoteMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(sequenceNumber.rest, 20) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET rfqId == ReadBytes(quoteMsgId.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(rfqId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentId.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidQuantity == ReadBytes(bidPrice.rest, 4) IN IF ~bidQuantity.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidQuantity.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerQuantity == ReadBytes(offerPrice.rest, 4) IN IF ~offerQuantity.ok THEN Fail ELSE
    LET autoCancel == ReadBytes(offerQuantity.rest, 1) IN IF ~autoCancel.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(autoCancel.rest, 11) IN IF ~marketMaker.ok THEN Fail ELSE
    LET marketMakerFirm == ReadBytes(marketMaker.rest, 11) IN IF ~marketMakerFirm.ok THEN Fail ELSE
    LET bidId == ReadBytes(marketMakerFirm.rest, 12) IN IF ~bidId.ok THEN Fail ELSE
    LET offerId == ReadBytes(bidId.rest, 12) IN IF ~offerId.ok THEN Fail ELSE
    LET capacity == ReadBytes(offerId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(capacity.rest, 1) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET clientId == ReadBytes(clearingAccount.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET investmentDecisionMaker == ReadBytes(clientId.rest, 4) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(investmentDecisionMaker.rest, 4) IN IF ~executingTrader.ok THEN Fail ELSE
    LET miFidFlags == ReadBytes(executingTrader.rest, 1) IN IF ~miFidFlags.ok THEN Fail ELSE
    LET partyRoleQualifiers == ReadBytes(miFidFlags.rest, 1) IN IF ~partyRoleQualifiers.ok THEN Fail ELSE
    Ok([ partitionId             |-> partitionId.value,
         sequenceNumber          |-> sequenceNumber.value,
         quoteMsgId              |-> quoteMsgId.value,
         rfqId                   |-> rfqId.value,
         instrumentId            |-> instrumentId.value,
         bidPrice                |-> bidPrice.value,
         bidQuantity             |-> bidQuantity.value,
         offerPrice              |-> offerPrice.value,
         offerQuantity           |-> offerQuantity.value,
         autoCancel              |-> autoCancel.value,
         marketMaker             |-> marketMaker.value,
         marketMakerFirm         |-> marketMakerFirm.value,
         bidId                   |-> bidId.value,
         offerId                 |-> offerId.value,
         capacity                |-> capacity.value,
         clearingAccount         |-> clearingAccount.value,
         clientId                |-> clientId.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value,
         executingTrader         |-> executingTrader.value,
         miFidFlags              |-> miFidFlags.value,
         partyRoleQualifiers     |-> partyRoleQualifiers.value ], partyRoleQualifiers.rest)

ZeroRfqQuoteMessage ==
    [ partitionId             |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber          |-> [i \in 1 .. 4 |-> 0],
      quoteMsgId              |-> [i \in 1 .. 20 |-> 0],
      rfqId                   |-> [i \in 1 .. 10 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      bidPrice                |-> [i \in 1 .. 8 |-> 0],
      bidQuantity             |-> [i \in 1 .. 4 |-> 0],
      offerPrice              |-> [i \in 1 .. 8 |-> 0],
      offerQuantity           |-> [i \in 1 .. 4 |-> 0],
      autoCancel              |-> [i \in 1 .. 1 |-> 0],
      marketMaker             |-> [i \in 1 .. 11 |-> 0],
      marketMakerFirm         |-> [i \in 1 .. 11 |-> 0],
      bidId                   |-> [i \in 1 .. 12 |-> 0],
      offerId                 |-> [i \in 1 .. 12 |-> 0],
      capacity                |-> [i \in 1 .. 1 |-> 0],
      clearingAccount         |-> [i \in 1 .. 1 |-> 0],
      clientId                |-> [i \in 1 .. 4 |-> 0],
      investmentDecisionMaker |-> [i \in 1 .. 4 |-> 0],
      executingTrader         |-> [i \in 1 .. 4 |-> 0],
      miFidFlags              |-> [i \in 1 .. 1 |-> 0],
      partyRoleQualifiers     |-> [i \in 1 .. 1 |-> 0] ]

(* Rfq Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqQuoteMessage ==
    { ZeroRfqQuoteMessage }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.quoteMsgId = one] : one \in Sample(20) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.bidQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.offerQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.autoCancel = one] : one \in Sample(1) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.marketMaker = one] : one \in Sample(11) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.marketMakerFirm = one] : one \in Sample(11) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.bidId = one] : one \in Sample(12) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.offerId = one] : one \in Sample(12) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.clearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.investmentDecisionMaker = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.executingTrader = one] : one \in Sample(4) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.miFidFlags = one] : one \in Sample(1) }
        \cup { [ZeroRfqQuoteMessage EXCEPT !.partyRoleQualifiers = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Ack Message: 65 bytes                                             *)
(***************************************************************************)

QuoteAckMessage ==
    [ partitionId    : Sample(1),
      sequenceNumber : Sample(4),
      quoteMsgId     : Sample(20),
      rfqId          : Sample(10),
      bidId          : Sample(12),
      offerId        : Sample(12),
      quoteAckStatus : Sample(1),
      rejectCode     : Sample(4),
      orderBook      : Sample(1) ]

EncodeQuoteAckMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.quoteMsgId
        \o message.rfqId
        \o message.bidId
        \o message.offerId
        \o message.quoteAckStatus
        \o message.rejectCode
        \o message.orderBook

DecodeQuoteAckMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(sequenceNumber.rest, 20) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET rfqId == ReadBytes(quoteMsgId.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET bidId == ReadBytes(rfqId.rest, 12) IN IF ~bidId.ok THEN Fail ELSE
    LET offerId == ReadBytes(bidId.rest, 12) IN IF ~offerId.ok THEN Fail ELSE
    LET quoteAckStatus == ReadBytes(offerId.rest, 1) IN IF ~quoteAckStatus.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(quoteAckStatus.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET orderBook == ReadBytes(rejectCode.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    Ok([ partitionId    |-> partitionId.value,
         sequenceNumber |-> sequenceNumber.value,
         quoteMsgId     |-> quoteMsgId.value,
         rfqId          |-> rfqId.value,
         bidId          |-> bidId.value,
         offerId        |-> offerId.value,
         quoteAckStatus |-> quoteAckStatus.value,
         rejectCode     |-> rejectCode.value,
         orderBook      |-> orderBook.value ], orderBook.rest)

ZeroQuoteAckMessage ==
    [ partitionId    |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      quoteMsgId     |-> [i \in 1 .. 20 |-> 0],
      rfqId          |-> [i \in 1 .. 10 |-> 0],
      bidId          |-> [i \in 1 .. 12 |-> 0],
      offerId        |-> [i \in 1 .. 12 |-> 0],
      quoteAckStatus |-> [i \in 1 .. 1 |-> 0],
      rejectCode     |-> [i \in 1 .. 4 |-> 0],
      orderBook      |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAckMessage ==
    { ZeroQuoteAckMessage }
        \cup { [ZeroQuoteAckMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.quoteMsgId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.bidId = one] : one \in Sample(12) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.offerId = one] : one \in Sample(12) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.quoteAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.orderBook = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Response Message: 88 bytes                                        *)
(***************************************************************************)

QuoteResponseMessage ==
    [ partitionId     : Sample(1),
      sequenceNumber  : Sample(4),
      quoteMsgId      : Sample(20),
      rfqId           : Sample(10),
      quoteRespType   : Sample(1),
      instrumentId    : Sample(4),
      side            : Sample(1),
      orderQuantity   : Sample(4),
      limitPrice      : Sample(8),
      orderBook       : Sample(1),
      bidId           : Sample(12),
      offerId         : Sample(12),
      capacity        : Sample(1),
      clearingAccount : Sample(1),
      reserved8       : Sample(8) ]

EncodeQuoteResponseMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.quoteMsgId
        \o message.rfqId
        \o message.quoteRespType
        \o message.instrumentId
        \o message.side
        \o message.orderQuantity
        \o message.limitPrice
        \o message.orderBook
        \o message.bidId
        \o message.offerId
        \o message.capacity
        \o message.clearingAccount
        \o message.reserved8

DecodeQuoteResponseMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(sequenceNumber.rest, 20) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET rfqId == ReadBytes(quoteMsgId.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET quoteRespType == ReadBytes(rfqId.rest, 1) IN IF ~quoteRespType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quoteRespType.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(side.rest, 4) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(orderQuantity.rest, 8) IN IF ~limitPrice.ok THEN Fail ELSE
    LET orderBook == ReadBytes(limitPrice.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    LET bidId == ReadBytes(orderBook.rest, 12) IN IF ~bidId.ok THEN Fail ELSE
    LET offerId == ReadBytes(bidId.rest, 12) IN IF ~offerId.ok THEN Fail ELSE
    LET capacity == ReadBytes(offerId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(capacity.rest, 1) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(clearingAccount.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ partitionId     |-> partitionId.value,
         sequenceNumber  |-> sequenceNumber.value,
         quoteMsgId      |-> quoteMsgId.value,
         rfqId           |-> rfqId.value,
         quoteRespType   |-> quoteRespType.value,
         instrumentId    |-> instrumentId.value,
         side            |-> side.value,
         orderQuantity   |-> orderQuantity.value,
         limitPrice      |-> limitPrice.value,
         orderBook       |-> orderBook.value,
         bidId           |-> bidId.value,
         offerId         |-> offerId.value,
         capacity        |-> capacity.value,
         clearingAccount |-> clearingAccount.value,
         reserved8       |-> reserved8.value ], reserved8.rest)

ZeroQuoteResponseMessage ==
    [ partitionId     |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      quoteMsgId      |-> [i \in 1 .. 20 |-> 0],
      rfqId           |-> [i \in 1 .. 10 |-> 0],
      quoteRespType   |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      orderQuantity   |-> [i \in 1 .. 4 |-> 0],
      limitPrice      |-> [i \in 1 .. 8 |-> 0],
      orderBook       |-> [i \in 1 .. 1 |-> 0],
      bidId           |-> [i \in 1 .. 12 |-> 0],
      offerId         |-> [i \in 1 .. 12 |-> 0],
      capacity        |-> [i \in 1 .. 1 |-> 0],
      clearingAccount |-> [i \in 1 .. 1 |-> 0],
      reserved8       |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Response Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteResponseMessage ==
    { ZeroQuoteResponseMessage }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.quoteMsgId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.quoteRespType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.orderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.limitPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.orderBook = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.bidId = one] : one \in Sample(12) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.offerId = one] : one \in Sample(12) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.clearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResponseMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime3 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime3(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime3(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime3 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime3 ==
    { ZeroTransactTime3 }
        \cup { [ZeroTransactTime3 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime3 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Rfq Execution Report Message: 153 bytes                                 *)
(***************************************************************************)

RfqExecutionReportMessage ==
    [ partitionId                   : Sample(1),
      sequenceNumber                : Sample(4),
      executionId                   : Sample(12),
      rfqId                         : Sample(10),
      orderId                       : Sample(12),
      executionType                 : Sample(1),
      tradeMatchId                  : Sample(8),
      side                          : Sample(1),
      executedQuantity              : Sample(4),
      executedPrice                 : Sample(8),
      transactTime                  : TransactTime3,
      reserved8                     : Sample(8),
      secondReserved8               : Sample(8),
      rfqExecutionReportOrderStatus : Sample(1),
      leavesQuantity                : Sample(4),
      instrumentId                  : Sample(4),
      thirdReserved8                : Sample(8),
      fourthReserved8               : Sample(8),
      contraFirm                    : Sample(11),
      capacity                      : Sample(1),
      clearingAccount               : Sample(1),
      waiverFlags                   : Sample(1),
      executionReportRefId          : Sample(12),
      contraOrderBook               : Sample(1),
      avgPx                         : Sample(8),
      lastMarket                    : Sample(1),
      reserved7                     : Sample(7) ]

EncodeRfqExecutionReportMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.executionId
        \o message.rfqId
        \o message.orderId
        \o message.executionType
        \o message.tradeMatchId
        \o message.side
        \o message.executedQuantity
        \o message.executedPrice
        \o EncodeTransactTime3(message.transactTime)
        \o message.reserved8
        \o message.secondReserved8
        \o message.rfqExecutionReportOrderStatus
        \o message.leavesQuantity
        \o message.instrumentId
        \o message.thirdReserved8
        \o message.fourthReserved8
        \o message.contraFirm
        \o message.capacity
        \o message.clearingAccount
        \o message.waiverFlags
        \o message.executionReportRefId
        \o message.contraOrderBook
        \o message.avgPx
        \o message.lastMarket
        \o message.reserved7

DecodeRfqExecutionReportMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET executionId == ReadBytes(sequenceNumber.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET rfqId == ReadBytes(executionId.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(rfqId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET executionType == ReadBytes(orderId.rest, 1) IN IF ~executionType.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(executionType.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeMatchId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executedPrice == ReadBytes(executedQuantity.rest, 8) IN IF ~executedPrice.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime3(executedPrice.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(transactTime.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(reserved8.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET rfqExecutionReportOrderStatus == ReadBytes(secondReserved8.rest, 1) IN IF ~rfqExecutionReportOrderStatus.ok THEN Fail ELSE
    LET leavesQuantity == ReadBytes(rfqExecutionReportOrderStatus.rest, 4) IN IF ~leavesQuantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(leavesQuantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(instrumentId.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(thirdReserved8.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    LET contraFirm == ReadBytes(fourthReserved8.rest, 11) IN IF ~contraFirm.ok THEN Fail ELSE
    LET capacity == ReadBytes(contraFirm.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(capacity.rest, 1) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET waiverFlags == ReadBytes(clearingAccount.rest, 1) IN IF ~waiverFlags.ok THEN Fail ELSE
    LET executionReportRefId == ReadBytes(waiverFlags.rest, 12) IN IF ~executionReportRefId.ok THEN Fail ELSE
    LET contraOrderBook == ReadBytes(executionReportRefId.rest, 1) IN IF ~contraOrderBook.ok THEN Fail ELSE
    LET avgPx == ReadBytes(contraOrderBook.rest, 8) IN IF ~avgPx.ok THEN Fail ELSE
    LET lastMarket == ReadBytes(avgPx.rest, 1) IN IF ~lastMarket.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(lastMarket.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ partitionId                   |-> partitionId.value,
         sequenceNumber                |-> sequenceNumber.value,
         executionId                   |-> executionId.value,
         rfqId                         |-> rfqId.value,
         orderId                       |-> orderId.value,
         executionType                 |-> executionType.value,
         tradeMatchId                  |-> tradeMatchId.value,
         side                          |-> side.value,
         executedQuantity              |-> executedQuantity.value,
         executedPrice                 |-> executedPrice.value,
         transactTime                  |-> transactTime.value,
         reserved8                     |-> reserved8.value,
         secondReserved8               |-> secondReserved8.value,
         rfqExecutionReportOrderStatus |-> rfqExecutionReportOrderStatus.value,
         leavesQuantity                |-> leavesQuantity.value,
         instrumentId                  |-> instrumentId.value,
         thirdReserved8                |-> thirdReserved8.value,
         fourthReserved8               |-> fourthReserved8.value,
         contraFirm                    |-> contraFirm.value,
         capacity                      |-> capacity.value,
         clearingAccount               |-> clearingAccount.value,
         waiverFlags                   |-> waiverFlags.value,
         executionReportRefId          |-> executionReportRefId.value,
         contraOrderBook               |-> contraOrderBook.value,
         avgPx                         |-> avgPx.value,
         lastMarket                    |-> lastMarket.value,
         reserved7                     |-> reserved7.value ], reserved7.rest)

ZeroRfqExecutionReportMessage ==
    [ partitionId                   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber                |-> [i \in 1 .. 4 |-> 0],
      executionId                   |-> [i \in 1 .. 12 |-> 0],
      rfqId                         |-> [i \in 1 .. 10 |-> 0],
      orderId                       |-> [i \in 1 .. 12 |-> 0],
      executionType                 |-> [i \in 1 .. 1 |-> 0],
      tradeMatchId                  |-> [i \in 1 .. 8 |-> 0],
      side                          |-> [i \in 1 .. 1 |-> 0],
      executedQuantity              |-> [i \in 1 .. 4 |-> 0],
      executedPrice                 |-> [i \in 1 .. 8 |-> 0],
      transactTime                  |-> ZeroTransactTime3,
      reserved8                     |-> [i \in 1 .. 8 |-> 0],
      secondReserved8               |-> [i \in 1 .. 8 |-> 0],
      rfqExecutionReportOrderStatus |-> [i \in 1 .. 1 |-> 0],
      leavesQuantity                |-> [i \in 1 .. 4 |-> 0],
      instrumentId                  |-> [i \in 1 .. 4 |-> 0],
      thirdReserved8                |-> [i \in 1 .. 8 |-> 0],
      fourthReserved8               |-> [i \in 1 .. 8 |-> 0],
      contraFirm                    |-> [i \in 1 .. 11 |-> 0],
      capacity                      |-> [i \in 1 .. 1 |-> 0],
      clearingAccount               |-> [i \in 1 .. 1 |-> 0],
      waiverFlags                   |-> [i \in 1 .. 1 |-> 0],
      executionReportRefId          |-> [i \in 1 .. 12 |-> 0],
      contraOrderBook               |-> [i \in 1 .. 1 |-> 0],
      avgPx                         |-> [i \in 1 .. 8 |-> 0],
      lastMarket                    |-> [i \in 1 .. 1 |-> 0],
      reserved7                     |-> [i \in 1 .. 7 |-> 0] ]

(* Rfq Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqExecutionReportMessage ==
    { ZeroRfqExecutionReportMessage }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.executionType = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.executedPrice = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime3 }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.rfqExecutionReportOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.leavesQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.contraFirm = one] : one \in Sample(11) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.clearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.waiverFlags = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.executionReportRefId = one] : one \in Sample(12) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.contraOrderBook = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.avgPx = one] : one \in Sample(8) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.lastMarket = one] : one \in Sample(1) }
        \cup { [ZeroRfqExecutionReportMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonMessageCode == 65  \* "A"
LogonReplyMessageCode == 66  \* "B"
LogoutMessageCode == 53  \* "5"
HeartbeatMessageCode == 48  \* "0"
MissedMessageRequestMessageCode == 77  \* "M"
MissedMessageRequestAckMessageCode == 78  \* "N"
MissedMessageReportMessageCode == 80  \* "P"
RejectMessageCode == 51  \* "3"
SystemStatusMessageCode == 110  \* "n"
ExecutionReportMessageCode == 56  \* "8"
OrderMassCancelReportMessageCode == 114  \* "r"
QuoteRequestMessageCode == 97  \* "a"
QuoteStatusReportMessageCode == 99  \* "c"
QuoteRequestRejectMessageCode == 98  \* "b"
RfqQuoteMessageCode == 100  \* "d"
QuoteAckMessageCode == 101  \* "e"
QuoteResponseMessageCode == 102  \* "f"
RfqExecutionReportMessageCode == 103  \* "g"

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonReplyMessageCode}, body : LogonReplyMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {MissedMessageRequestMessageCode}, body : MissedMessageRequestMessage ]
        \cup [ tag : {MissedMessageRequestAckMessageCode}, body : MissedMessageRequestAckMessage ]
        \cup [ tag : {MissedMessageReportMessageCode}, body : MissedMessageReportMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {SystemStatusMessageCode}, body : SystemStatusMessage ]
        \cup [ tag : {ExecutionReportMessageCode}, body : ExecutionReportMessage ]
        \cup [ tag : {OrderMassCancelReportMessageCode}, body : OrderMassCancelReportMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {QuoteStatusReportMessageCode}, body : QuoteStatusReportMessage ]
        \cup [ tag : {QuoteRequestRejectMessageCode}, body : QuoteRequestRejectMessage ]
        \cup [ tag : {RfqQuoteMessageCode}, body : RfqQuoteMessage ]
        \cup [ tag : {QuoteAckMessageCode}, body : QuoteAckMessage ]
        \cup [ tag : {QuoteResponseMessageCode}, body : QuoteResponseMessage ]
        \cup [ tag : {RfqExecutionReportMessageCode}, body : RfqExecutionReportMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonReplyMessageCode -> EncodeLogonReplyMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = MissedMessageRequestMessageCode -> EncodeMissedMessageRequestMessage(message.body)
      [] message.tag = MissedMessageRequestAckMessageCode -> EncodeMissedMessageRequestAckMessage(message.body)
      [] message.tag = MissedMessageReportMessageCode -> EncodeMissedMessageReportMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = SystemStatusMessageCode -> EncodeSystemStatusMessage(message.body)
      [] message.tag = ExecutionReportMessageCode -> EncodeExecutionReportMessage(message.body)
      [] message.tag = OrderMassCancelReportMessageCode -> EncodeOrderMassCancelReportMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = QuoteStatusReportMessageCode -> EncodeQuoteStatusReportMessage(message.body)
      [] message.tag = QuoteRequestRejectMessageCode -> EncodeQuoteRequestRejectMessage(message.body)
      [] message.tag = RfqQuoteMessageCode -> EncodeRfqQuoteMessage(message.body)
      [] message.tag = QuoteAckMessageCode -> EncodeQuoteAckMessage(message.body)
      [] message.tag = QuoteResponseMessageCode -> EncodeQuoteResponseMessage(message.body)
      [] message.tag = RfqExecutionReportMessageCode -> EncodeRfqExecutionReportMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonReplyMessageCode -> DecodeLogonReplyMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = MissedMessageRequestMessageCode -> DecodeMissedMessageRequestMessage(bytes)
              [] tag = MissedMessageRequestAckMessageCode -> DecodeMissedMessageRequestAckMessage(bytes)
              [] tag = MissedMessageReportMessageCode -> DecodeMissedMessageReportMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = SystemStatusMessageCode -> DecodeSystemStatusMessage(bytes)
              [] tag = ExecutionReportMessageCode -> DecodeExecutionReportMessage(bytes)
              [] tag = OrderMassCancelReportMessageCode -> DecodeOrderMassCancelReportMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = QuoteStatusReportMessageCode -> DecodeQuoteStatusReportMessage(bytes)
              [] tag = QuoteRequestRejectMessageCode -> DecodeQuoteRequestRejectMessage(bytes)
              [] tag = RfqQuoteMessageCode -> DecodeRfqQuoteMessage(bytes)
              [] tag = QuoteAckMessageCode -> DecodeQuoteAckMessage(bytes)
              [] tag = QuoteResponseMessageCode -> DecodeQuoteResponseMessage(bytes)
              [] tag = RfqExecutionReportMessageCode -> DecodeRfqExecutionReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonReplyMessageCode, body |-> one] : one \in CheckedLogonReplyMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> MissedMessageRequestMessageCode, body |-> one] : one \in CheckedMissedMessageRequestMessage }
        \cup { [tag |-> MissedMessageRequestAckMessageCode, body |-> one] : one \in CheckedMissedMessageRequestAckMessage }
        \cup { [tag |-> MissedMessageReportMessageCode, body |-> one] : one \in CheckedMissedMessageReportMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> SystemStatusMessageCode, body |-> one] : one \in CheckedSystemStatusMessage }
        \cup { [tag |-> ExecutionReportMessageCode, body |-> one] : one \in CheckedExecutionReportMessage }
        \cup { [tag |-> OrderMassCancelReportMessageCode, body |-> one] : one \in CheckedOrderMassCancelReportMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> QuoteStatusReportMessageCode, body |-> one] : one \in CheckedQuoteStatusReportMessage }
        \cup { [tag |-> QuoteRequestRejectMessageCode, body |-> one] : one \in CheckedQuoteRequestRejectMessage }
        \cup { [tag |-> RfqQuoteMessageCode, body |-> one] : one \in CheckedRfqQuoteMessage }
        \cup { [tag |-> QuoteAckMessageCode, body |-> one] : one \in CheckedQuoteAckMessage }
        \cup { [tag |-> QuoteResponseMessageCode, body |-> one] : one \in CheckedQuoteResponseMessage }
        \cup { [tag |-> RfqExecutionReportMessageCode, body |-> one] : one \in CheckedRfqExecutionReportMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ startOfMessage : Sample(1),
      payload        : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  message.startOfMessage \o EncodeUIntLE(Len(body), 2) \o body

DecodeMessage(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 1) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET length == ReadUIntLE(startOfMessage.rest, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
    IN
    LET messageType == ReadUIntBE(framed, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ startOfMessage |-> startOfMessage.value,
         payload        |-> payload.value ], beyond)

ZeroMessage ==
    [ startOfMessage |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.startOfMessage = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonReplyMessageCode, body |-> ZeroLogonReplyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MissedMessageRequestMessageCode, body |-> ZeroMissedMessageRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MissedMessageRequestAckMessageCode, body |-> ZeroMissedMessageRequestAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MissedMessageReportMessageCode, body |-> ZeroMissedMessageReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemStatusMessageCode, body |-> ZeroSystemStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionReportMessageCode, body |-> ZeroExecutionReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassCancelReportMessageCode, body |-> ZeroOrderMassCancelReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteStatusReportMessageCode, body |-> ZeroQuoteStatusReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestRejectMessageCode, body |-> ZeroQuoteRequestRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqQuoteMessageCode, body |-> ZeroRfqQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteAckMessageCode, body |-> ZeroQuoteAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteResponseMessageCode, body |-> ZeroQuoteResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqExecutionReportMessageCode, body |-> ZeroRfqExecutionReportMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonReplyMessage ==
    \A message \in CheckedLogonReplyMessage :
        LET read == DecodeLogonReplyMessage(EncodeLogonReplyMessage(message))
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

(* Every Missed Message Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMissedMessageRequestMessage ==
    \A message \in CheckedMissedMessageRequestMessage :
        LET read == DecodeMissedMessageRequestMessage(EncodeMissedMessageRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Missed Message Request Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMissedMessageRequestAckMessage ==
    \A message \in CheckedMissedMessageRequestAckMessage :
        LET read == DecodeMissedMessageRequestAckMessage(EncodeMissedMessageRequestAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Missed Message Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMissedMessageReportMessage ==
    \A message \in CheckedMissedMessageReportMessage :
        LET read == DecodeMissedMessageReportMessage(EncodeMissedMessageReportMessage(message))
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

(* Every System Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStatusMessage ==
    \A message \in CheckedSystemStatusMessage :
        LET read == DecodeSystemStatusMessage(EncodeSystemStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime ==
    \A message \in CheckedTransactTime :
        LET read == DecodeTransactTime(EncodeTransactTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportMessage ==
    \A message \in CheckedExecutionReportMessage :
        LET read == DecodeExecutionReportMessage(EncodeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime2 ==
    \A message \in CheckedTransactTime2 :
        LET read == DecodeTransactTime2(EncodeTransactTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelReportMessage ==
    \A message \in CheckedOrderMassCancelReportMessage :
        LET read == DecodeOrderMassCancelReportMessage(EncodeOrderMassCancelReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestMessage ==
    \A message \in CheckedQuoteRequestMessage :
        LET read == DecodeQuoteRequestMessage(EncodeQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteStatusReportMessage ==
    \A message \in CheckedQuoteStatusReportMessage :
        LET read == DecodeQuoteStatusReportMessage(EncodeQuoteStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestRejectMessage ==
    \A message \in CheckedQuoteRequestRejectMessage :
        LET read == DecodeQuoteRequestRejectMessage(EncodeQuoteRequestRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqQuoteMessage ==
    \A message \in CheckedRfqQuoteMessage :
        LET read == DecodeRfqQuoteMessage(EncodeRfqQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAckMessage ==
    \A message \in CheckedQuoteAckMessage :
        LET read == DecodeQuoteAckMessage(EncodeQuoteAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteResponseMessage ==
    \A message \in CheckedQuoteResponseMessage :
        LET read == DecodeQuoteResponseMessage(EncodeQuoteResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime3 ==
    \A message \in CheckedTransactTime3 :
        LET read == DecodeTransactTime3(EncodeTransactTime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqExecutionReportMessage ==
    \A message \in CheckedRfqExecutionReportMessage :
        LET read == DecodeRfqExecutionReportMessage(EncodeRfqExecutionReportMessage(message))
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

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 2, 3)) = Len(bytes) - 3

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
