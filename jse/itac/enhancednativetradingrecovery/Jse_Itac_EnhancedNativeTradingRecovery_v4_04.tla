----------- MODULE Jse_Itac_EnhancedNativeTradingRecovery_v4_04 ------------
(***************************************************************************)
(* JSE Limited Enhanced Native Trading Recovery v4.04                      *)
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
(* Note: Indicator Flags is a bit field set, checked as its 1 byte rather  *)
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
(* Logon Message: 60 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ compId          : Sample(6),
      password        : Sample(25),
      newPassword     : Sample(25),
      protocolVersion : Sample(4) ]

EncodeLogonMessage(message) ==
    message.compId
        \o message.password
        \o message.newPassword
        \o message.protocolVersion

DecodeLogonMessage(bytes) ==
    LET compId == ReadBytes(bytes, 6) IN IF ~compId.ok THEN Fail ELSE
    LET password == ReadBytes(compId.rest, 25) IN IF ~password.ok THEN Fail ELSE
    LET newPassword == ReadBytes(password.rest, 25) IN IF ~newPassword.ok THEN Fail ELSE
    LET protocolVersion == ReadBytes(newPassword.rest, 4) IN IF ~protocolVersion.ok THEN Fail ELSE
    Ok([ compId          |-> compId.value,
         password        |-> password.value,
         newPassword     |-> newPassword.value,
         protocolVersion |-> protocolVersion.value ], protocolVersion.rest)

ZeroLogonMessage ==
    [ compId          |-> [i \in 1 .. 6 |-> 0],
      password        |-> [i \in 1 .. 25 |-> 0],
      newPassword     |-> [i \in 1 .. 25 |-> 0],
      protocolVersion |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.compId = one] : one \in Sample(6) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.newPassword = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.protocolVersion = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Response Message: 8 bytes                                         *)
(***************************************************************************)

LogonResponseMessage ==
    [ rejectCode     : Sample(4),
      passwordExpiry : Sample(4) ]

EncodeLogonResponseMessage(message) ==
    message.rejectCode
        \o message.passwordExpiry

DecodeLogonResponseMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET passwordExpiry == ReadBytes(rejectCode.rest, 4) IN IF ~passwordExpiry.ok THEN Fail ELSE
    Ok([ rejectCode     |-> rejectCode.value,
         passwordExpiry |-> passwordExpiry.value ], passwordExpiry.rest)

ZeroLogonResponseMessage ==
    [ rejectCode     |-> [i \in 1 .. 4 |-> 0],
      passwordExpiry |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.passwordExpiry = one] : one \in Sample(4) }

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
(* Reject Message: 55 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ rejectCode    : Sample(4),
      rejectReason  : Sample(30),
      messageType   : Sample(1),
      clientOrderId : Sample(20) ]

EncodeRejectMessage(message) ==
    message.rejectCode
        \o message.rejectReason
        \o message.messageType
        \o message.clientOrderId

DecodeRejectMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(rejectCode.rest, 30) IN IF ~rejectReason.ok THEN Fail ELSE
    LET messageType == ReadBytes(rejectReason.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(messageType.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ rejectCode    |-> rejectCode.value,
         rejectReason  |-> rejectReason.value,
         messageType   |-> messageType.value,
         clientOrderId |-> clientOrderId.value ], clientOrderId.rest)

ZeroRejectMessage ==
    [ rejectCode    |-> [i \in 1 .. 4 |-> 0],
      rejectReason  |-> [i \in 1 .. 30 |-> 0],
      messageType   |-> [i \in 1 .. 1 |-> 0],
      clientOrderId |-> [i \in 1 .. 20 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectReason = one] : one \in Sample(30) }
        \cup { [ZeroRejectMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Missed Message Request Message: 5 bytes                                 *)
(***************************************************************************)

MissedMessageRequestMessage ==
    [ partitionId    : Sample(1),
      sequenceNumber : Sample(4) ]

EncodeMissedMessageRequestMessage(message) ==
    message.partitionId
        \o message.sequenceNumber

DecodeMissedMessageRequestMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ partitionId    |-> partitionId.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroMissedMessageRequestMessage ==
    [ partitionId    |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Missed Message Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMissedMessageRequestMessage ==
    { ZeroMissedMessageRequestMessage }
        \cup { [ZeroMissedMessageRequestMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroMissedMessageRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Missed Message Request Ack Message: 1 bytes                             *)
(***************************************************************************)

MissedMessageRequestAckMessage ==
    [ missedMessageStatus : Sample(1) ]

EncodeMissedMessageRequestAckMessage(message) ==
    message.missedMessageStatus

DecodeMissedMessageRequestAckMessage(bytes) ==
    LET missedMessageStatus == ReadBytes(bytes, 1) IN IF ~missedMessageStatus.ok THEN Fail ELSE
    Ok([ missedMessageStatus |-> missedMessageStatus.value ], missedMessageStatus.rest)

ZeroMissedMessageRequestAckMessage ==
    [ missedMessageStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Missed Message Request Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMissedMessageRequestAckMessage ==
    { ZeroMissedMessageRequestAckMessage }
        \cup { [ZeroMissedMessageRequestAckMessage EXCEPT !.missedMessageStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Transmission Complete Message: 1 bytes                                  *)
(***************************************************************************)

TransmissionCompleteMessage ==
    [ transmissionStatus : Sample(1) ]

EncodeTransmissionCompleteMessage(message) ==
    message.transmissionStatus

DecodeTransmissionCompleteMessage(bytes) ==
    LET transmissionStatus == ReadBytes(bytes, 1) IN IF ~transmissionStatus.ok THEN Fail ELSE
    Ok([ transmissionStatus |-> transmissionStatus.value ], transmissionStatus.rest)

ZeroTransmissionCompleteMessage ==
    [ transmissionStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Transmission Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedTransmissionCompleteMessage ==
    { ZeroTransmissionCompleteMessage }
        \cup { [ZeroTransmissionCompleteMessage EXCEPT !.transmissionStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* System Status Message: 2 bytes                                          *)
(***************************************************************************)

SystemStatusMessage ==
    [ partitionId  : Sample(1),
      systemStatus : Sample(1) ]

EncodeSystemStatusMessage(message) ==
    message.partitionId
        \o message.systemStatus

DecodeSystemStatusMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(partitionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ partitionId  |-> partitionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStatusMessage ==
    [ partitionId  |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStatusMessage ==
    { ZeroSystemStatusMessage }
        \cup { [ZeroSystemStatusMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStatusMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime ==
    [ transactTimeSeconds     : Sample(4),
      transactTimeNanoseconds : Sample(4) ]

EncodeTransactTime(message) ==
    message.transactTimeSeconds
        \o message.transactTimeNanoseconds

DecodeTransactTime(bytes) ==
    LET transactTimeSeconds == ReadBytes(bytes, 4) IN IF ~transactTimeSeconds.ok THEN Fail ELSE
    LET transactTimeNanoseconds == ReadBytes(transactTimeSeconds.rest, 4) IN IF ~transactTimeNanoseconds.ok THEN Fail ELSE
    Ok([ transactTimeSeconds     |-> transactTimeSeconds.value,
         transactTimeNanoseconds |-> transactTimeNanoseconds.value ], transactTimeNanoseconds.rest)

ZeroTransactTime ==
    [ transactTimeSeconds     |-> [i \in 1 .. 4 |-> 0],
      transactTimeNanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime ==
    { ZeroTransactTime }
        \cup { [ZeroTransactTime EXCEPT !.transactTimeSeconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime EXCEPT !.transactTimeNanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Execution Report Message: 152 bytes                                     *)
(***************************************************************************)

ExecutionReportMessage ==
    [ partitionId            : Sample(1),
      sequenceNumber         : Sample(4),
      executionId            : Sample(21),
      clientOrderId          : Sample(20),
      orderId                : Sample(12),
      executionType          : Sample(1),
      orderStatus            : Sample(1),
      rejectCode             : Sample(4),
      executedPrice          : Sample(8),
      executedQuantity       : Sample(4),
      leavesQuantity         : Sample(4),
      workingIndicator       : Sample(1),
      securityId             : Sample(4),
      side                   : Sample(1),
      traderMnemonic         : Sample(17),
      account                : Sample(10),
      isMarketOpsRequest     : Sample(1),
      transactTime           : TransactTime,
      orderBook              : Sample(1),
      executionInstruction   : Sample(1),
      multiLegReportingType  : Sample(1),
      lastOptPx              : Sample(8),
      volatility             : Sample(8),
      secondaryTradeReportId : Sample(10),
      indicatorFlags         : Sample(1) ]

EncodeExecutionReportMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.executionId
        \o message.clientOrderId
        \o message.orderId
        \o message.executionType
        \o message.orderStatus
        \o message.rejectCode
        \o message.executedPrice
        \o message.executedQuantity
        \o message.leavesQuantity
        \o message.workingIndicator
        \o message.securityId
        \o message.side
        \o message.traderMnemonic
        \o message.account
        \o message.isMarketOpsRequest
        \o EncodeTransactTime(message.transactTime)
        \o message.orderBook
        \o message.executionInstruction
        \o message.multiLegReportingType
        \o message.lastOptPx
        \o message.volatility
        \o message.secondaryTradeReportId
        \o message.indicatorFlags

DecodeExecutionReportMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET executionId == ReadBytes(sequenceNumber.rest, 21) IN IF ~executionId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(executionId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET executionType == ReadBytes(orderId.rest, 1) IN IF ~executionType.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(executionType.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(orderStatus.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET executedPrice == ReadBytes(rejectCode.rest, 8) IN IF ~executedPrice.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(executedPrice.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET leavesQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~leavesQuantity.ok THEN Fail ELSE
    LET workingIndicator == ReadBytes(leavesQuantity.rest, 1) IN IF ~workingIndicator.ok THEN Fail ELSE
    LET securityId == ReadBytes(workingIndicator.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET traderMnemonic == ReadBytes(side.rest, 17) IN IF ~traderMnemonic.ok THEN Fail ELSE
    LET account == ReadBytes(traderMnemonic.rest, 10) IN IF ~account.ok THEN Fail ELSE
    LET isMarketOpsRequest == ReadBytes(account.rest, 1) IN IF ~isMarketOpsRequest.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime(isMarketOpsRequest.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderBook == ReadBytes(transactTime.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    LET executionInstruction == ReadBytes(orderBook.rest, 1) IN IF ~executionInstruction.ok THEN Fail ELSE
    LET multiLegReportingType == ReadBytes(executionInstruction.rest, 1) IN IF ~multiLegReportingType.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(multiLegReportingType.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET secondaryTradeReportId == ReadBytes(volatility.rest, 10) IN IF ~secondaryTradeReportId.ok THEN Fail ELSE
    LET indicatorFlags == ReadBytes(secondaryTradeReportId.rest, 1) IN IF ~indicatorFlags.ok THEN Fail ELSE
    Ok([ partitionId            |-> partitionId.value,
         sequenceNumber         |-> sequenceNumber.value,
         executionId            |-> executionId.value,
         clientOrderId          |-> clientOrderId.value,
         orderId                |-> orderId.value,
         executionType          |-> executionType.value,
         orderStatus            |-> orderStatus.value,
         rejectCode             |-> rejectCode.value,
         executedPrice          |-> executedPrice.value,
         executedQuantity       |-> executedQuantity.value,
         leavesQuantity         |-> leavesQuantity.value,
         workingIndicator       |-> workingIndicator.value,
         securityId             |-> securityId.value,
         side                   |-> side.value,
         traderMnemonic         |-> traderMnemonic.value,
         account                |-> account.value,
         isMarketOpsRequest     |-> isMarketOpsRequest.value,
         transactTime           |-> transactTime.value,
         orderBook              |-> orderBook.value,
         executionInstruction   |-> executionInstruction.value,
         multiLegReportingType  |-> multiLegReportingType.value,
         lastOptPx              |-> lastOptPx.value,
         volatility             |-> volatility.value,
         secondaryTradeReportId |-> secondaryTradeReportId.value,
         indicatorFlags         |-> indicatorFlags.value ], indicatorFlags.rest)

ZeroExecutionReportMessage ==
    [ partitionId            |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      executionId            |-> [i \in 1 .. 21 |-> 0],
      clientOrderId          |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 12 |-> 0],
      executionType          |-> [i \in 1 .. 1 |-> 0],
      orderStatus            |-> [i \in 1 .. 1 |-> 0],
      rejectCode             |-> [i \in 1 .. 4 |-> 0],
      executedPrice          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity       |-> [i \in 1 .. 4 |-> 0],
      leavesQuantity         |-> [i \in 1 .. 4 |-> 0],
      workingIndicator       |-> [i \in 1 .. 1 |-> 0],
      securityId             |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      traderMnemonic         |-> [i \in 1 .. 17 |-> 0],
      account                |-> [i \in 1 .. 10 |-> 0],
      isMarketOpsRequest     |-> [i \in 1 .. 1 |-> 0],
      transactTime           |-> ZeroTransactTime,
      orderBook              |-> [i \in 1 .. 1 |-> 0],
      executionInstruction   |-> [i \in 1 .. 1 |-> 0],
      multiLegReportingType  |-> [i \in 1 .. 1 |-> 0],
      lastOptPx              |-> [i \in 1 .. 8 |-> 0],
      volatility             |-> [i \in 1 .. 8 |-> 0],
      secondaryTradeReportId |-> [i \in 1 .. 10 |-> 0],
      indicatorFlags         |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportMessage ==
    { ZeroExecutionReportMessage }
        \cup { [ZeroExecutionReportMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionId = one] : one \in Sample(21) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executedPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.leavesQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.workingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.traderMnemonic = one] : one \in Sample(17) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.isMarketOpsRequest = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderBook = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.multiLegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.secondaryTradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.indicatorFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime2 ==
    [ transactTimeSeconds     : Sample(4),
      transactTimeNanoseconds : Sample(4) ]

EncodeTransactTime2(message) ==
    message.transactTimeSeconds
        \o message.transactTimeNanoseconds

DecodeTransactTime2(bytes) ==
    LET transactTimeSeconds == ReadBytes(bytes, 4) IN IF ~transactTimeSeconds.ok THEN Fail ELSE
    LET transactTimeNanoseconds == ReadBytes(transactTimeSeconds.rest, 4) IN IF ~transactTimeNanoseconds.ok THEN Fail ELSE
    Ok([ transactTimeSeconds     |-> transactTimeSeconds.value,
         transactTimeNanoseconds |-> transactTimeNanoseconds.value ], transactTimeNanoseconds.rest)

ZeroTransactTime2 ==
    [ transactTimeSeconds     |-> [i \in 1 .. 4 |-> 0],
      transactTimeNanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime2 ==
    { ZeroTransactTime2 }
        \cup { [ZeroTransactTime2 EXCEPT !.transactTimeSeconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime2 EXCEPT !.transactTimeNanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Reject Message: 60 bytes                                   *)
(***************************************************************************)

OrderCancelRejectMessage ==
    [ partitionId    : Sample(1),
      sequenceNumber : Sample(4),
      clientOrderId  : Sample(20),
      orderId        : Sample(12),
      transactTime   : TransactTime2,
      rejectCode     : Sample(4),
      orderBook      : Sample(1),
      rfqId          : Sample(10) ]

EncodeOrderCancelRejectMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.clientOrderId
        \o message.orderId
        \o EncodeTransactTime2(message.transactTime)
        \o message.rejectCode
        \o message.orderBook
        \o message.rfqId

DecodeOrderCancelRejectMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sequenceNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime2(orderId.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(transactTime.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET orderBook == ReadBytes(rejectCode.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    LET rfqId == ReadBytes(orderBook.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    Ok([ partitionId    |-> partitionId.value,
         sequenceNumber |-> sequenceNumber.value,
         clientOrderId  |-> clientOrderId.value,
         orderId        |-> orderId.value,
         transactTime   |-> transactTime.value,
         rejectCode     |-> rejectCode.value,
         orderBook      |-> orderBook.value,
         rfqId          |-> rfqId.value ], rfqId.rest)

ZeroOrderCancelRejectMessage ==
    [ partitionId    |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      clientOrderId  |-> [i \in 1 .. 20 |-> 0],
      orderId        |-> [i \in 1 .. 12 |-> 0],
      transactTime   |-> ZeroTransactTime2,
      rejectCode     |-> [i \in 1 .. 4 |-> 0],
      orderBook      |-> [i \in 1 .. 1 |-> 0],
      rfqId          |-> [i \in 1 .. 10 |-> 0] ]

(* Order Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRejectMessage ==
    { ZeroOrderCancelRejectMessage }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime2 }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.orderBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.rfqId = one] : one \in Sample(10) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime3 ==
    [ transactTimeSeconds     : Sample(4),
      transactTimeNanoseconds : Sample(4) ]

EncodeTransactTime3(message) ==
    message.transactTimeSeconds
        \o message.transactTimeNanoseconds

DecodeTransactTime3(bytes) ==
    LET transactTimeSeconds == ReadBytes(bytes, 4) IN IF ~transactTimeSeconds.ok THEN Fail ELSE
    LET transactTimeNanoseconds == ReadBytes(transactTimeSeconds.rest, 4) IN IF ~transactTimeNanoseconds.ok THEN Fail ELSE
    Ok([ transactTimeSeconds     |-> transactTimeSeconds.value,
         transactTimeNanoseconds |-> transactTimeNanoseconds.value ], transactTimeNanoseconds.rest)

ZeroTransactTime3 ==
    [ transactTimeSeconds     |-> [i \in 1 .. 4 |-> 0],
      transactTimeNanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime3 ==
    { ZeroTransactTime3 }
        \cup { [ZeroTransactTime3 EXCEPT !.transactTimeSeconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime3 EXCEPT !.transactTimeNanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mass Cancel Report Message: 39 bytes                              *)
(***************************************************************************)

OrderMassCancelReportMessage ==
    [ partitionId      : Sample(1),
      sequenceNumber   : Sample(4),
      clientOrderId    : Sample(20),
      massCancelStatus : Sample(1),
      rejectCode       : Sample(4),
      transactTime     : TransactTime3,
      orderBook        : Sample(1) ]

EncodeOrderMassCancelReportMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.clientOrderId
        \o message.massCancelStatus
        \o message.rejectCode
        \o EncodeTransactTime3(message.transactTime)
        \o message.orderBook

DecodeOrderMassCancelReportMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sequenceNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET massCancelStatus == ReadBytes(clientOrderId.rest, 1) IN IF ~massCancelStatus.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(massCancelStatus.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime3(rejectCode.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderBook == ReadBytes(transactTime.rest, 1) IN IF ~orderBook.ok THEN Fail ELSE
    Ok([ partitionId      |-> partitionId.value,
         sequenceNumber   |-> sequenceNumber.value,
         clientOrderId    |-> clientOrderId.value,
         massCancelStatus |-> massCancelStatus.value,
         rejectCode       |-> rejectCode.value,
         transactTime     |-> transactTime.value,
         orderBook        |-> orderBook.value ], orderBook.rest)

ZeroOrderMassCancelReportMessage ==
    [ partitionId      |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber   |-> [i \in 1 .. 4 |-> 0],
      clientOrderId    |-> [i \in 1 .. 20 |-> 0],
      massCancelStatus |-> [i \in 1 .. 1 |-> 0],
      rejectCode       |-> [i \in 1 .. 4 |-> 0],
      transactTime     |-> ZeroTransactTime3,
      orderBook        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Mass Cancel Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelReportMessage ==
    { ZeroOrderMassCancelReportMessage }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime3 }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.orderBook = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Definition Response Message: 20 bytes                          *)
(***************************************************************************)

SecurityDefinitionResponseMessage ==
    [ securityRequestId    : Sample(10),
      securityResponseType : Sample(1),
      rejectCode           : Sample(4),
      securityId           : Sample(4),
      securityType         : Sample(1) ]

EncodeSecurityDefinitionResponseMessage(message) ==
    message.securityRequestId
        \o message.securityResponseType
        \o message.rejectCode
        \o message.securityId
        \o message.securityType

DecodeSecurityDefinitionResponseMessage(bytes) ==
    LET securityRequestId == ReadBytes(bytes, 10) IN IF ~securityRequestId.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(securityRequestId.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(securityResponseType.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET securityId == ReadBytes(rejectCode.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    Ok([ securityRequestId    |-> securityRequestId.value,
         securityResponseType |-> securityResponseType.value,
         rejectCode           |-> rejectCode.value,
         securityId           |-> securityId.value,
         securityType         |-> securityType.value ], securityType.rest)

ZeroSecurityDefinitionResponseMessage ==
    [ securityRequestId    |-> [i \in 1 .. 10 |-> 0],
      securityResponseType |-> [i \in 1 .. 1 |-> 0],
      rejectCode           |-> [i \in 1 .. 4 |-> 0],
      securityId           |-> [i \in 1 .. 4 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0] ]

(* Security Definition Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionResponseMessage ==
    { ZeroSecurityDefinitionResponseMessage }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityRequestId = one] : one \in Sample(10) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityType = one] : one \in Sample(1) }

(***************************************************************************)
(* News Message: 1188 bytes                                                *)
(***************************************************************************)

NewsMessage ==
    [ partitionId    : Sample(1),
      sequenceNumber : Sample(4),
      origTime       : Sample(24),
      urgency        : Sample(1),
      headline       : Sample(100),
      text           : Sample(750),
      instruments    : Sample(100),
      underlyings    : Sample(100),
      firmList       : Sample(54),
      userList       : Sample(54) ]

EncodeNewsMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.origTime
        \o message.urgency
        \o message.headline
        \o message.text
        \o message.instruments
        \o message.underlyings
        \o message.firmList
        \o message.userList

DecodeNewsMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET origTime == ReadBytes(sequenceNumber.rest, 24) IN IF ~origTime.ok THEN Fail ELSE
    LET urgency == ReadBytes(origTime.rest, 1) IN IF ~urgency.ok THEN Fail ELSE
    LET headline == ReadBytes(urgency.rest, 100) IN IF ~headline.ok THEN Fail ELSE
    LET text == ReadBytes(headline.rest, 750) IN IF ~text.ok THEN Fail ELSE
    LET instruments == ReadBytes(text.rest, 100) IN IF ~instruments.ok THEN Fail ELSE
    LET underlyings == ReadBytes(instruments.rest, 100) IN IF ~underlyings.ok THEN Fail ELSE
    LET firmList == ReadBytes(underlyings.rest, 54) IN IF ~firmList.ok THEN Fail ELSE
    LET userList == ReadBytes(firmList.rest, 54) IN IF ~userList.ok THEN Fail ELSE
    Ok([ partitionId    |-> partitionId.value,
         sequenceNumber |-> sequenceNumber.value,
         origTime       |-> origTime.value,
         urgency        |-> urgency.value,
         headline       |-> headline.value,
         text           |-> text.value,
         instruments    |-> instruments.value,
         underlyings    |-> underlyings.value,
         firmList       |-> firmList.value,
         userList       |-> userList.value ], userList.rest)

ZeroNewsMessage ==
    [ partitionId    |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      origTime       |-> [i \in 1 .. 24 |-> 0],
      urgency        |-> [i \in 1 .. 1 |-> 0],
      headline       |-> [i \in 1 .. 100 |-> 0],
      text           |-> [i \in 1 .. 750 |-> 0],
      instruments    |-> [i \in 1 .. 100 |-> 0],
      underlyings    |-> [i \in 1 .. 100 |-> 0],
      firmList       |-> [i \in 1 .. 54 |-> 0],
      userList       |-> [i \in 1 .. 54 |-> 0] ]

(* News Message at zero, then each field in turn at the values it is checked at *)
CheckedNewsMessage ==
    { ZeroNewsMessage }
        \cup { [ZeroNewsMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroNewsMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.origTime = one] : one \in Sample(24) }
        \cup { [ZeroNewsMessage EXCEPT !.urgency = one] : one \in Sample(1) }
        \cup { [ZeroNewsMessage EXCEPT !.headline = one] : one \in Sample(100) }
        \cup { [ZeroNewsMessage EXCEPT !.text = one] : one \in Sample(750) }
        \cup { [ZeroNewsMessage EXCEPT !.instruments = one] : one \in Sample(100) }
        \cup { [ZeroNewsMessage EXCEPT !.underlyings = one] : one \in Sample(100) }
        \cup { [ZeroNewsMessage EXCEPT !.firmList = one] : one \in Sample(54) }
        \cup { [ZeroNewsMessage EXCEPT !.userList = one] : one \in Sample(54) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime4 ==
    [ transactTimeSeconds     : Sample(4),
      transactTimeNanoseconds : Sample(4) ]

EncodeTransactTime4(message) ==
    message.transactTimeSeconds
        \o message.transactTimeNanoseconds

DecodeTransactTime4(bytes) ==
    LET transactTimeSeconds == ReadBytes(bytes, 4) IN IF ~transactTimeSeconds.ok THEN Fail ELSE
    LET transactTimeNanoseconds == ReadBytes(transactTimeSeconds.rest, 4) IN IF ~transactTimeNanoseconds.ok THEN Fail ELSE
    Ok([ transactTimeSeconds     |-> transactTimeSeconds.value,
         transactTimeNanoseconds |-> transactTimeNanoseconds.value ], transactTimeNanoseconds.rest)

ZeroTransactTime4 ==
    [ transactTimeSeconds     |-> [i \in 1 .. 4 |-> 0],
      transactTimeNanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime4 ==
    { ZeroTransactTime4 }
        \cup { [ZeroTransactTime4 EXCEPT !.transactTimeSeconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime4 EXCEPT !.transactTimeNanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Business Reject Message: 49 bytes                                       *)
(***************************************************************************)

BusinessRejectMessage ==
    [ partitionId    : Sample(1),
      sequenceNumber : Sample(4),
      rejectCode     : Sample(4),
      clientOrderId  : Sample(20),
      orderId        : Sample(12),
      transactTime   : TransactTime4 ]

EncodeBusinessRejectMessage(message) ==
    message.partitionId
        \o message.sequenceNumber
        \o message.rejectCode
        \o message.clientOrderId
        \o message.orderId
        \o EncodeTransactTime4(message.transactTime)

DecodeBusinessRejectMessage(bytes) ==
    LET partitionId == ReadBytes(bytes, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(partitionId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(rejectCode.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime4(orderId.rest) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ partitionId    |-> partitionId.value,
         sequenceNumber |-> sequenceNumber.value,
         rejectCode     |-> rejectCode.value,
         clientOrderId  |-> clientOrderId.value,
         orderId        |-> orderId.value,
         transactTime   |-> transactTime.value ], transactTime.rest)

ZeroBusinessRejectMessage ==
    [ partitionId    |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      rejectCode     |-> [i \in 1 .. 4 |-> 0],
      clientOrderId  |-> [i \in 1 .. 20 |-> 0],
      orderId        |-> [i \in 1 .. 12 |-> 0],
      transactTime   |-> ZeroTransactTime4 ]

(* Business Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessRejectMessage ==
    { ZeroBusinessRejectMessage }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime4 }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonMessageCode == 65  \* "A"
LogonResponseMessageCode == 66  \* "B"
LogoutMessageCode == 53  \* "5"
HeartbeatMessageCode == 48  \* "0"
RejectMessageCode == 51  \* "3"
MissedMessageRequestMessageCode == 77  \* "M"
MissedMessageRequestAckMessageCode == 78  \* "N"
TransmissionCompleteMessageCode == 80  \* "P"
SystemStatusMessageCode == 110  \* "n"
ExecutionReportMessageCode == 56  \* "8"
OrderCancelRejectMessageCode == 57  \* "9"
OrderMassCancelReportMessageCode == 114  \* "r"
SecurityDefinitionResponseMessageCode == 82  \* "R"
NewsMessageCode == 90  \* "Z"
BusinessRejectMessageCode == 106  \* "j"

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {MissedMessageRequestMessageCode}, body : MissedMessageRequestMessage ]
        \cup [ tag : {MissedMessageRequestAckMessageCode}, body : MissedMessageRequestAckMessage ]
        \cup [ tag : {TransmissionCompleteMessageCode}, body : TransmissionCompleteMessage ]
        \cup [ tag : {SystemStatusMessageCode}, body : SystemStatusMessage ]
        \cup [ tag : {ExecutionReportMessageCode}, body : ExecutionReportMessage ]
        \cup [ tag : {OrderCancelRejectMessageCode}, body : OrderCancelRejectMessage ]
        \cup [ tag : {OrderMassCancelReportMessageCode}, body : OrderMassCancelReportMessage ]
        \cup [ tag : {SecurityDefinitionResponseMessageCode}, body : SecurityDefinitionResponseMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {BusinessRejectMessageCode}, body : BusinessRejectMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = MissedMessageRequestMessageCode -> EncodeMissedMessageRequestMessage(message.body)
      [] message.tag = MissedMessageRequestAckMessageCode -> EncodeMissedMessageRequestAckMessage(message.body)
      [] message.tag = TransmissionCompleteMessageCode -> EncodeTransmissionCompleteMessage(message.body)
      [] message.tag = SystemStatusMessageCode -> EncodeSystemStatusMessage(message.body)
      [] message.tag = ExecutionReportMessageCode -> EncodeExecutionReportMessage(message.body)
      [] message.tag = OrderCancelRejectMessageCode -> EncodeOrderCancelRejectMessage(message.body)
      [] message.tag = OrderMassCancelReportMessageCode -> EncodeOrderMassCancelReportMessage(message.body)
      [] message.tag = SecurityDefinitionResponseMessageCode -> EncodeSecurityDefinitionResponseMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = BusinessRejectMessageCode -> EncodeBusinessRejectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = MissedMessageRequestMessageCode -> DecodeMissedMessageRequestMessage(bytes)
              [] tag = MissedMessageRequestAckMessageCode -> DecodeMissedMessageRequestAckMessage(bytes)
              [] tag = TransmissionCompleteMessageCode -> DecodeTransmissionCompleteMessage(bytes)
              [] tag = SystemStatusMessageCode -> DecodeSystemStatusMessage(bytes)
              [] tag = ExecutionReportMessageCode -> DecodeExecutionReportMessage(bytes)
              [] tag = OrderCancelRejectMessageCode -> DecodeOrderCancelRejectMessage(bytes)
              [] tag = OrderMassCancelReportMessageCode -> DecodeOrderMassCancelReportMessage(bytes)
              [] tag = SecurityDefinitionResponseMessageCode -> DecodeSecurityDefinitionResponseMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = BusinessRejectMessageCode -> DecodeBusinessRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> MissedMessageRequestMessageCode, body |-> one] : one \in CheckedMissedMessageRequestMessage }
        \cup { [tag |-> MissedMessageRequestAckMessageCode, body |-> one] : one \in CheckedMissedMessageRequestAckMessage }
        \cup { [tag |-> TransmissionCompleteMessageCode, body |-> one] : one \in CheckedTransmissionCompleteMessage }
        \cup { [tag |-> SystemStatusMessageCode, body |-> one] : one \in CheckedSystemStatusMessage }
        \cup { [tag |-> ExecutionReportMessageCode, body |-> one] : one \in CheckedExecutionReportMessage }
        \cup { [tag |-> OrderCancelRejectMessageCode, body |-> one] : one \in CheckedOrderCancelRejectMessage }
        \cup { [tag |-> OrderMassCancelReportMessageCode, body |-> one] : one \in CheckedOrderMassCancelReportMessage }
        \cup { [tag |-> SecurityDefinitionResponseMessageCode, body |-> one] : one \in CheckedSecurityDefinitionResponseMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> BusinessRejectMessageCode, body |-> one] : one \in CheckedBusinessRejectMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MissedMessageRequestMessageCode, body |-> ZeroMissedMessageRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MissedMessageRequestAckMessageCode, body |-> ZeroMissedMessageRequestAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransmissionCompleteMessageCode, body |-> ZeroTransmissionCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemStatusMessageCode, body |-> ZeroSystemStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionReportMessageCode, body |-> ZeroExecutionReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelRejectMessageCode, body |-> ZeroOrderCancelRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassCancelReportMessageCode, body |-> ZeroOrderMassCancelReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionResponseMessageCode, body |-> ZeroSecurityDefinitionResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BusinessRejectMessageCode, body |-> ZeroBusinessRejectMessage]] }

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

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
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

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
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

(* Every Transmission Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransmissionCompleteMessage ==
    \A message \in CheckedTransmissionCompleteMessage :
        LET read == DecodeTransmissionCompleteMessage(EncodeTransmissionCompleteMessage(message))
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

(* Every Order Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRejectMessage ==
    \A message \in CheckedOrderCancelRejectMessage :
        LET read == DecodeOrderCancelRejectMessage(EncodeOrderCancelRejectMessage(message))
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

(* Every Order Mass Cancel Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelReportMessage ==
    \A message \in CheckedOrderMassCancelReportMessage :
        LET read == DecodeOrderMassCancelReportMessage(EncodeOrderMassCancelReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionResponseMessage ==
    \A message \in CheckedSecurityDefinitionResponseMessage :
        LET read == DecodeSecurityDefinitionResponseMessage(EncodeSecurityDefinitionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMessage ==
    \A message \in CheckedNewsMessage :
        LET read == DecodeNewsMessage(EncodeNewsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime4 ==
    \A message \in CheckedTransactTime4 :
        LET read == DecodeTransactTime4(EncodeTransactTime4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessRejectMessage ==
    \A message \in CheckedBusinessRejectMessage :
        LET read == DecodeBusinessRejectMessage(EncodeBusinessRejectMessage(message))
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
