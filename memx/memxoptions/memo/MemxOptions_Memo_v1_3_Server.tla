------------------- MODULE MemxOptions_Memo_v1_3_Server --------------------
(***************************************************************************)
(* The Members Exchange Members Orders v1.3                                *)
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
(* Note: Exec Inst is a bit field set, checked as its 2 bytes rather than  *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Mass Cancel Inst is a bit field set, checked as its 1 byte rather *)
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
(* Login Accepted Message: 1 bytes                                         *)
(***************************************************************************)

LoginAcceptedMessage ==
    [ supportedRequestMode : Sample(1) ]

EncodeLoginAcceptedMessage(message) ==
    message.supportedRequestMode

DecodeLoginAcceptedMessage(bytes) ==
    LET supportedRequestMode == ReadBytes(bytes, 1) IN IF ~supportedRequestMode.ok THEN Fail ELSE
    Ok([ supportedRequestMode |-> supportedRequestMode.value ], supportedRequestMode.rest)

ZeroLoginAcceptedMessage ==
    [ supportedRequestMode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedMessage ==
    { ZeroLoginAcceptedMessage }
        \cup { [ZeroLoginAcceptedMessage EXCEPT !.supportedRequestMode = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Rejected Message: 1 bytes                                         *)
(***************************************************************************)

LoginRejectedMessage ==
    [ loginRejectCode : Sample(1) ]

EncodeLoginRejectedMessage(message) ==
    message.loginRejectCode

DecodeLoginRejectedMessage(bytes) ==
    LET loginRejectCode == ReadBytes(bytes, 1) IN IF ~loginRejectCode.ok THEN Fail ELSE
    Ok([ loginRejectCode |-> loginRejectCode.value ], loginRejectCode.rest)

ZeroLoginRejectedMessage ==
    [ loginRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedMessage ==
    { ZeroLoginRejectedMessage }
        \cup { [ZeroLoginRejectedMessage EXCEPT !.loginRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Start Of Session Message: 8 bytes                                       *)
(***************************************************************************)

StartOfSessionMessage ==
    [ sessionId : Sample(8) ]

EncodeStartOfSessionMessage(message) ==
    message.sessionId

DecodeStartOfSessionMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroStartOfSessionMessage ==
    [ sessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfSessionMessage ==
    { ZeroStartOfSessionMessage }
        \cup { [ZeroStartOfSessionMessage EXCEPT !.sessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Replay Begin Message: 12 bytes                                          *)
(***************************************************************************)

ReplayBeginMessage ==
    [ nextSequenceNumber  : Sample(8),
      pendingMessageCount : Sample(4) ]

EncodeReplayBeginMessage(message) ==
    message.nextSequenceNumber
        \o message.pendingMessageCount

DecodeReplayBeginMessage(bytes) ==
    LET nextSequenceNumber == ReadBytes(bytes, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET pendingMessageCount == ReadBytes(nextSequenceNumber.rest, 4) IN IF ~pendingMessageCount.ok THEN Fail ELSE
    Ok([ nextSequenceNumber  |-> nextSequenceNumber.value,
         pendingMessageCount |-> pendingMessageCount.value ], pendingMessageCount.rest)

ZeroReplayBeginMessage ==
    [ nextSequenceNumber  |-> [i \in 1 .. 8 |-> 0],
      pendingMessageCount |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayBeginMessage ==
    { ZeroReplayBeginMessage }
        \cup { [ZeroReplayBeginMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplayBeginMessage EXCEPT !.pendingMessageCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay Rejected Message: 1 bytes                                        *)
(***************************************************************************)

ReplayRejectedMessage ==
    [ replayRejectCode : Sample(1) ]

EncodeReplayRejectedMessage(message) ==
    message.replayRejectCode

DecodeReplayRejectedMessage(bytes) ==
    LET replayRejectCode == ReadBytes(bytes, 1) IN IF ~replayRejectCode.ok THEN Fail ELSE
    Ok([ replayRejectCode |-> replayRejectCode.value ], replayRejectCode.rest)

ZeroReplayRejectedMessage ==
    [ replayRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRejectedMessage ==
    { ZeroReplayRejectedMessage }
        \cup { [ZeroReplayRejectedMessage EXCEPT !.replayRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Complete Message: 8 bytes                                        *)
(***************************************************************************)

ReplayCompleteMessage ==
    [ messageCount : Sample(8) ]

EncodeReplayCompleteMessage(message) ==
    message.messageCount

DecodeReplayCompleteMessage(bytes) ==
    LET messageCount == ReadBytes(bytes, 8) IN IF ~messageCount.ok THEN Fail ELSE
    Ok([ messageCount |-> messageCount.value ], messageCount.rest)

ZeroReplayCompleteMessage ==
    [ messageCount |-> [i \in 1 .. 8 |-> 0] ]

(* Replay Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayCompleteMessage ==
    { ZeroReplayCompleteMessage }
        \cup { [ZeroReplayCompleteMessage EXCEPT !.messageCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Begin Message: 16 bytes                                          *)
(***************************************************************************)

StreamBeginMessage ==
    [ nextSequenceNumber : Sample(8),
      maxSequenceNumber  : Sample(8) ]

EncodeStreamBeginMessage(message) ==
    message.nextSequenceNumber
        \o message.maxSequenceNumber

DecodeStreamBeginMessage(bytes) ==
    LET nextSequenceNumber == ReadBytes(bytes, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET maxSequenceNumber == ReadBytes(nextSequenceNumber.rest, 8) IN IF ~maxSequenceNumber.ok THEN Fail ELSE
    Ok([ nextSequenceNumber |-> nextSequenceNumber.value,
         maxSequenceNumber  |-> maxSequenceNumber.value ], maxSequenceNumber.rest)

ZeroStreamBeginMessage ==
    [ nextSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      maxSequenceNumber  |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamBeginMessage ==
    { ZeroStreamBeginMessage }
        \cup { [ZeroStreamBeginMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroStreamBeginMessage EXCEPT !.maxSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Rejected Message: 1 bytes                                        *)
(***************************************************************************)

StreamRejectedMessage ==
    [ streamRejectCode : Sample(1) ]

EncodeStreamRejectedMessage(message) ==
    message.streamRejectCode

DecodeStreamRejectedMessage(bytes) ==
    LET streamRejectCode == ReadBytes(bytes, 1) IN IF ~streamRejectCode.ok THEN Fail ELSE
    Ok([ streamRejectCode |-> streamRejectCode.value ], streamRejectCode.rest)

ZeroStreamRejectedMessage ==
    [ streamRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Stream Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamRejectedMessage ==
    { ZeroStreamRejectedMessage }
        \cup { [ZeroStreamRejectedMessage EXCEPT !.streamRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stream Complete Message: 8 bytes                                        *)
(***************************************************************************)

StreamCompleteMessage ==
    [ totalSequenceCount : Sample(8) ]

EncodeStreamCompleteMessage(message) ==
    message.totalSequenceCount

DecodeStreamCompleteMessage(bytes) ==
    LET totalSequenceCount == ReadBytes(bytes, 8) IN IF ~totalSequenceCount.ok THEN Fail ELSE
    Ok([ totalSequenceCount |-> totalSequenceCount.value ], totalSequenceCount.rest)

ZeroStreamCompleteMessage ==
    [ totalSequenceCount |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamCompleteMessage ==
    { ZeroStreamCompleteMessage }
        \cup { [ZeroStreamCompleteMessage EXCEPT !.totalSequenceCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup ==
    { ZeroPartiesGroup }
        \cup { [ZeroPartiesGroup EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroupList(_)
EncodePartiesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup(Head(messages)) \o EncodePartiesGroupList(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroupList(_, _)
ReadPartiesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup == { ZeroPartiesGroup }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup) ]

EncodePartiesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroupList(message.partiesGroup)

DecodePartiesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroupList(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups ==
    { ZeroPartiesGroups }
        \cup { [ZeroPartiesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup) }

(***************************************************************************)
(* Execution Report New Message                                            *)
(***************************************************************************)

ExecutionReportNewMessage ==
    [ orderId              : Sample(8),
      clordid              : Sample(20),
      listSeqNo            : Sample(1),
      execId               : Sample(8),
      ordStatus            : Sample(1),
      securityId           : Sample(8),
      side                 : Sample(1),
      orderQty             : Sample(4),
      ordType              : Sample(1),
      priceOptional        : Sample(8),
      timeInForce          : Sample(1),
      openOrCloseOptional  : Sample(1),
      execInst             : Sample(2),
      tradingCapacity      : Sample(1),
      repriceFrequency     : Sample(1),
      repriceBehavior      : Sample(1),
      leavesQty            : Sample(4),
      cumQty               : Sample(4),
      sendingTime          : Sample(8),
      transactTime         : Sample(8),
      mtpGroupId           : Sample(2),
      matchTradePrevention : Sample(1),
      cancelGroupId        : Sample(2),
      riskGroupId          : Sample(2),
      partiesGroups        : PartiesGroups ]

EncodeExecutionReportNewMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.execId
        \o message.ordStatus
        \o message.securityId
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.priceOptional
        \o message.timeInForce
        \o message.openOrCloseOptional
        \o message.execInst
        \o message.tradingCapacity
        \o message.repriceFrequency
        \o message.repriceBehavior
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime
        \o message.transactTime
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o EncodePartiesGroups(message.partiesGroups)

DecodeExecutionReportNewMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET execId == ReadBytes(listSeqNo.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(ordType.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceOptional.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET openOrCloseOptional == ReadBytes(timeInForce.rest, 1) IN IF ~openOrCloseOptional.ok THEN Fail ELSE
    LET execInst == ReadBytes(openOrCloseOptional.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET repriceFrequency == ReadBytes(tradingCapacity.rest, 1) IN IF ~repriceFrequency.ok THEN Fail ELSE
    LET repriceBehavior == ReadBytes(repriceFrequency.rest, 1) IN IF ~repriceBehavior.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(repriceBehavior.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(transactTime.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups(riskGroupId.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ orderId              |-> orderId.value,
         clordid              |-> clordid.value,
         listSeqNo            |-> listSeqNo.value,
         execId               |-> execId.value,
         ordStatus            |-> ordStatus.value,
         securityId           |-> securityId.value,
         side                 |-> side.value,
         orderQty             |-> orderQty.value,
         ordType              |-> ordType.value,
         priceOptional        |-> priceOptional.value,
         timeInForce          |-> timeInForce.value,
         openOrCloseOptional  |-> openOrCloseOptional.value,
         execInst             |-> execInst.value,
         tradingCapacity      |-> tradingCapacity.value,
         repriceFrequency     |-> repriceFrequency.value,
         repriceBehavior      |-> repriceBehavior.value,
         leavesQty            |-> leavesQty.value,
         cumQty               |-> cumQty.value,
         sendingTime          |-> sendingTime.value,
         transactTime         |-> transactTime.value,
         mtpGroupId           |-> mtpGroupId.value,
         matchTradePrevention |-> matchTradePrevention.value,
         cancelGroupId        |-> cancelGroupId.value,
         riskGroupId          |-> riskGroupId.value,
         partiesGroups        |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportNewMessage ==
    [ orderId              |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 20 |-> 0],
      listSeqNo            |-> [i \in 1 .. 1 |-> 0],
      execId               |-> [i \in 1 .. 8 |-> 0],
      ordStatus            |-> [i \in 1 .. 1 |-> 0],
      securityId           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      priceOptional        |-> [i \in 1 .. 8 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      openOrCloseOptional  |-> [i \in 1 .. 1 |-> 0],
      execInst             |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      repriceFrequency     |-> [i \in 1 .. 1 |-> 0],
      repriceBehavior      |-> [i \in 1 .. 1 |-> 0],
      leavesQty            |-> [i \in 1 .. 4 |-> 0],
      cumQty               |-> [i \in 1 .. 4 |-> 0],
      sendingTime          |-> [i \in 1 .. 8 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0],
      mtpGroupId           |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId        |-> [i \in 1 .. 2 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups ]

(* Execution Report New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportNewMessage ==
    { ZeroExecutionReportNewMessage }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.openOrCloseOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.repriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.repriceBehavior = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup2 ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup2(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup2(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup2 ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup2 ==
    { ZeroPartiesGroup2 }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup2List(_)
EncodePartiesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup2(Head(messages)) \o EncodePartiesGroup2List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup2List(_, _)
ReadPartiesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup2 == { ZeroPartiesGroup2 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups2 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup2) ]

EncodePartiesGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup2List(message.partiesGroup)

DecodePartiesGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups2 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups2 ==
    { ZeroPartiesGroups2 }
        \cup { [ZeroPartiesGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups2 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup2) }

(***************************************************************************)
(* Execution Report Bulk Quote Pending New Message                         *)
(***************************************************************************)

ExecutionReportBulkQuotePendingNewMessage ==
    [ clordid              : Sample(20),
      symbol               : Sample(6),
      timeInForce          : Sample(1),
      execInst             : Sample(2),
      tradingCapacity      : Sample(1),
      sendingTime          : Sample(8),
      transactTime         : Sample(8),
      mtpGroupId           : Sample(2),
      matchTradePrevention : Sample(1),
      cancelGroupId        : Sample(2),
      riskGroupId          : Sample(2),
      numberOfOrders       : Sample(1),
      partiesGroups        : PartiesGroups2 ]

EncodeExecutionReportBulkQuotePendingNewMessage(message) ==
    message.clordid
        \o message.symbol
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.sendingTime
        \o message.transactTime
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o message.numberOfOrders
        \o EncodePartiesGroups2(message.partiesGroups)

DecodeExecutionReportBulkQuotePendingNewMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET symbol == ReadBytes(clordid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(tradingCapacity.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(transactTime.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups2(numberOfOrders.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         symbol               |-> symbol.value,
         timeInForce          |-> timeInForce.value,
         execInst             |-> execInst.value,
         tradingCapacity      |-> tradingCapacity.value,
         sendingTime          |-> sendingTime.value,
         transactTime         |-> transactTime.value,
         mtpGroupId           |-> mtpGroupId.value,
         matchTradePrevention |-> matchTradePrevention.value,
         cancelGroupId        |-> cancelGroupId.value,
         riskGroupId          |-> riskGroupId.value,
         numberOfOrders       |-> numberOfOrders.value,
         partiesGroups        |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportBulkQuotePendingNewMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      execInst             |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      sendingTime          |-> [i \in 1 .. 8 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0],
      mtpGroupId           |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId        |-> [i \in 1 .. 2 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      numberOfOrders       |-> [i \in 1 .. 1 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups2 ]

(* Execution Report Bulk Quote Pending New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportBulkQuotePendingNewMessage ==
    { ZeroExecutionReportBulkQuotePendingNewMessage }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.numberOfOrders = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuotePendingNewMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups2 }

(***************************************************************************)
(* Execution Report Bulk Quote Component New Message: 83 bytes             *)
(***************************************************************************)

ExecutionReportBulkQuoteComponentNewMessage ==
    [ orderId       : Sample(8),
      clordid       : Sample(20),
      listSeqNo     : Sample(1),
      execId        : Sample(8),
      ordStatus     : Sample(1),
      securityId    : Sample(8),
      side          : Sample(1),
      orderQty      : Sample(4),
      priceOptional : Sample(8),
      leavesQty     : Sample(4),
      cumQty        : Sample(4),
      sendingTime   : Sample(8),
      transactTime  : Sample(8) ]

EncodeExecutionReportBulkQuoteComponentNewMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.execId
        \o message.ordStatus
        \o message.securityId
        \o message.side
        \o message.orderQty
        \o message.priceOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime
        \o message.transactTime

DecodeExecutionReportBulkQuoteComponentNewMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET execId == ReadBytes(listSeqNo.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(priceOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         clordid       |-> clordid.value,
         listSeqNo     |-> listSeqNo.value,
         execId        |-> execId.value,
         ordStatus     |-> ordStatus.value,
         securityId    |-> securityId.value,
         side          |-> side.value,
         orderQty      |-> orderQty.value,
         priceOptional |-> priceOptional.value,
         leavesQty     |-> leavesQty.value,
         cumQty        |-> cumQty.value,
         sendingTime   |-> sendingTime.value,
         transactTime  |-> transactTime.value ], transactTime.rest)

ZeroExecutionReportBulkQuoteComponentNewMessage ==
    [ orderId       |-> [i \in 1 .. 8 |-> 0],
      clordid       |-> [i \in 1 .. 20 |-> 0],
      listSeqNo     |-> [i \in 1 .. 1 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      ordStatus     |-> [i \in 1 .. 1 |-> 0],
      securityId    |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      orderQty      |-> [i \in 1 .. 4 |-> 0],
      priceOptional |-> [i \in 1 .. 8 |-> 0],
      leavesQty     |-> [i \in 1 .. 4 |-> 0],
      cumQty        |-> [i \in 1 .. 4 |-> 0],
      sendingTime   |-> [i \in 1 .. 8 |-> 0],
      transactTime  |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Bulk Quote Component New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportBulkQuoteComponentNewMessage ==
    { ZeroExecutionReportBulkQuoteComponentNewMessage }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportBulkQuoteComponentNewMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Rejected Message: 57 bytes                             *)
(***************************************************************************)

ExecutionReportRejectedMessage ==
    [ clordid           : Sample(20),
      listSeqNo         : Sample(1),
      execId            : Sample(8),
      ordStatus         : Sample(1),
      orderRejectReason : Sample(2),
      securityId        : Sample(8),
      side              : Sample(1),
      leavesQty         : Sample(4),
      cumQty            : Sample(4),
      sendingTime       : Sample(8) ]

EncodeExecutionReportRejectedMessage(message) ==
    message.clordid
        \o message.listSeqNo
        \o message.execId
        \o message.ordStatus
        \o message.orderRejectReason
        \o message.securityId
        \o message.side
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime

DecodeExecutionReportRejectedMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET execId == ReadBytes(listSeqNo.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(ordStatus.rest, 2) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderRejectReason.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(side.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         listSeqNo         |-> listSeqNo.value,
         execId            |-> execId.value,
         ordStatus         |-> ordStatus.value,
         orderRejectReason |-> orderRejectReason.value,
         securityId        |-> securityId.value,
         side              |-> side.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         sendingTime       |-> sendingTime.value ], sendingTime.rest)

ZeroExecutionReportRejectedMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      listSeqNo         |-> [i \in 1 .. 1 |-> 0],
      execId            |-> [i \in 1 .. 8 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      orderRejectReason |-> [i \in 1 .. 2 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      leavesQty         |-> [i \in 1 .. 4 |-> 0],
      cumQty            |-> [i \in 1 .. 4 |-> 0],
      sendingTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportRejectedMessage ==
    { ZeroExecutionReportRejectedMessage }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.orderRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup3 ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup3(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup3(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup3 ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup3 ==
    { ZeroPartiesGroup3 }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup3List(_)
EncodePartiesGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup3(Head(messages)) \o EncodePartiesGroup3List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup3List(_, _)
ReadPartiesGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup3 == { ZeroPartiesGroup3 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups3 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup3) ]

EncodePartiesGroups3(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup3List(message.partiesGroup)

DecodePartiesGroups3(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup3List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups3 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups3 ==
    { ZeroPartiesGroups3 }
        \cup { [ZeroPartiesGroups3 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups3 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup3) }

(***************************************************************************)
(* Execution Report Trade Message                                          *)
(***************************************************************************)

ExecutionReportTradeMessage ==
    [ orderId               : Sample(8),
      clordid               : Sample(20),
      listSeqNo             : Sample(1),
      trdMatchId            : Sample(8),
      execId                : Sample(8),
      ordStatus             : Sample(1),
      securityId            : Sample(8),
      side                  : Sample(1),
      lastQty               : Sample(4),
      lastPx                : Sample(8),
      leavesQty             : Sample(4),
      cumQty                : Sample(4),
      sendingTime           : Sample(8),
      transactTime          : Sample(8),
      lastLiquidityInd      : Sample(1),
      lastMkt               : Sample(4),
      openOrClose           : Sample(1),
      tradingCapacity       : Sample(1),
      contraTradingCapacity : Sample(1),
      partiesGroups         : PartiesGroups3 ]

EncodeExecutionReportTradeMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.trdMatchId
        \o message.execId
        \o message.ordStatus
        \o message.securityId
        \o message.side
        \o message.lastQty
        \o message.lastPx
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime
        \o message.transactTime
        \o message.lastLiquidityInd
        \o message.lastMkt
        \o message.openOrClose
        \o message.tradingCapacity
        \o message.contraTradingCapacity
        \o EncodePartiesGroups3(message.partiesGroups)

DecodeExecutionReportTradeMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(listSeqNo.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET execId == ReadBytes(trdMatchId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET lastQty == ReadBytes(side.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastLiquidityInd == ReadBytes(transactTime.rest, 1) IN IF ~lastLiquidityInd.ok THEN Fail ELSE
    LET lastMkt == ReadBytes(lastLiquidityInd.rest, 4) IN IF ~lastMkt.ok THEN Fail ELSE
    LET openOrClose == ReadBytes(lastMkt.rest, 1) IN IF ~openOrClose.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(openOrClose.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET contraTradingCapacity == ReadBytes(tradingCapacity.rest, 1) IN IF ~contraTradingCapacity.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups3(contraTradingCapacity.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ orderId               |-> orderId.value,
         clordid               |-> clordid.value,
         listSeqNo             |-> listSeqNo.value,
         trdMatchId            |-> trdMatchId.value,
         execId                |-> execId.value,
         ordStatus             |-> ordStatus.value,
         securityId            |-> securityId.value,
         side                  |-> side.value,
         lastQty               |-> lastQty.value,
         lastPx                |-> lastPx.value,
         leavesQty             |-> leavesQty.value,
         cumQty                |-> cumQty.value,
         sendingTime           |-> sendingTime.value,
         transactTime          |-> transactTime.value,
         lastLiquidityInd      |-> lastLiquidityInd.value,
         lastMkt               |-> lastMkt.value,
         openOrClose           |-> openOrClose.value,
         tradingCapacity       |-> tradingCapacity.value,
         contraTradingCapacity |-> contraTradingCapacity.value,
         partiesGroups         |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportTradeMessage ==
    [ orderId               |-> [i \in 1 .. 8 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      listSeqNo             |-> [i \in 1 .. 1 |-> 0],
      trdMatchId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      lastQty               |-> [i \in 1 .. 4 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      sendingTime           |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      lastLiquidityInd      |-> [i \in 1 .. 1 |-> 0],
      lastMkt               |-> [i \in 1 .. 4 |-> 0],
      openOrClose           |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity       |-> [i \in 1 .. 1 |-> 0],
      contraTradingCapacity |-> [i \in 1 .. 1 |-> 0],
      partiesGroups         |-> ZeroPartiesGroups3 ]

(* Execution Report Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeMessage ==
    { ZeroExecutionReportTradeMessage }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastMkt = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.openOrClose = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.contraTradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups3 }

(***************************************************************************)
(* Execution Report Pending Cancel Message: 75 bytes                       *)
(***************************************************************************)

ExecutionReportPendingCancelMessage ==
    [ orderId      : Sample(8),
      clordid      : Sample(20),
      listSeqNo    : Sample(1),
      origclordid  : Sample(20),
      ordStatus    : Sample(1),
      securityId   : Sample(8),
      sideOptional : Sample(1),
      leavesQty    : Sample(4),
      cumQty       : Sample(4),
      sendingTime  : Sample(8) ]

EncodeExecutionReportPendingCancelMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.origclordid
        \o message.ordStatus
        \o message.securityId
        \o message.sideOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime

DecodeExecutionReportPendingCancelMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET origclordid == ReadBytes(listSeqNo.rest, 20) IN IF ~origclordid.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(origclordid.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(securityId.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(sideOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ orderId      |-> orderId.value,
         clordid      |-> clordid.value,
         listSeqNo    |-> listSeqNo.value,
         origclordid  |-> origclordid.value,
         ordStatus    |-> ordStatus.value,
         securityId   |-> securityId.value,
         sideOptional |-> sideOptional.value,
         leavesQty    |-> leavesQty.value,
         cumQty       |-> cumQty.value,
         sendingTime  |-> sendingTime.value ], sendingTime.rest)

ZeroExecutionReportPendingCancelMessage ==
    [ orderId      |-> [i \in 1 .. 8 |-> 0],
      clordid      |-> [i \in 1 .. 20 |-> 0],
      listSeqNo    |-> [i \in 1 .. 1 |-> 0],
      origclordid  |-> [i \in 1 .. 20 |-> 0],
      ordStatus    |-> [i \in 1 .. 1 |-> 0],
      securityId   |-> [i \in 1 .. 8 |-> 0],
      sideOptional |-> [i \in 1 .. 1 |-> 0],
      leavesQty    |-> [i \in 1 .. 4 |-> 0],
      cumQty       |-> [i \in 1 .. 4 |-> 0],
      sendingTime  |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Pending Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingCancelMessage ==
    { ZeroExecutionReportPendingCancelMessage }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.origclordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Canceled Message: 92 bytes                             *)
(***************************************************************************)

ExecutionReportCanceledMessage ==
    [ orderId             : Sample(8),
      clordid             : Sample(20),
      listSeqNo           : Sample(1),
      origclordidOptional : Sample(20),
      execId              : Sample(8),
      ordStatus           : Sample(1),
      cancelReason        : Sample(1),
      securityId          : Sample(8),
      sideOptional        : Sample(1),
      leavesQty           : Sample(4),
      cumQty              : Sample(4),
      sendingTime         : Sample(8),
      transactTime        : Sample(8) ]

EncodeExecutionReportCanceledMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.origclordidOptional
        \o message.execId
        \o message.ordStatus
        \o message.cancelReason
        \o message.securityId
        \o message.sideOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime
        \o message.transactTime

DecodeExecutionReportCanceledMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET origclordidOptional == ReadBytes(listSeqNo.rest, 20) IN IF ~origclordidOptional.ok THEN Fail ELSE
    LET execId == ReadBytes(origclordidOptional.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(ordStatus.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET securityId == ReadBytes(cancelReason.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(securityId.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(sideOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ orderId             |-> orderId.value,
         clordid             |-> clordid.value,
         listSeqNo           |-> listSeqNo.value,
         origclordidOptional |-> origclordidOptional.value,
         execId              |-> execId.value,
         ordStatus           |-> ordStatus.value,
         cancelReason        |-> cancelReason.value,
         securityId          |-> securityId.value,
         sideOptional        |-> sideOptional.value,
         leavesQty           |-> leavesQty.value,
         cumQty              |-> cumQty.value,
         sendingTime         |-> sendingTime.value,
         transactTime        |-> transactTime.value ], transactTime.rest)

ZeroExecutionReportCanceledMessage ==
    [ orderId             |-> [i \in 1 .. 8 |-> 0],
      clordid             |-> [i \in 1 .. 20 |-> 0],
      listSeqNo           |-> [i \in 1 .. 1 |-> 0],
      origclordidOptional |-> [i \in 1 .. 20 |-> 0],
      execId              |-> [i \in 1 .. 8 |-> 0],
      ordStatus           |-> [i \in 1 .. 1 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      securityId          |-> [i \in 1 .. 8 |-> 0],
      sideOptional        |-> [i \in 1 .. 1 |-> 0],
      leavesQty           |-> [i \in 1 .. 4 |-> 0],
      cumQty              |-> [i \in 1 .. 4 |-> 0],
      sendingTime         |-> [i \in 1 .. 8 |-> 0],
      transactTime        |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportCanceledMessage ==
    { ZeroExecutionReportCanceledMessage }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.origclordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Pending Replace Message: 96 bytes                      *)
(***************************************************************************)

ExecutionReportPendingReplaceMessage ==
    [ orderId       : Sample(8),
      clordid       : Sample(20),
      listSeqNo     : Sample(1),
      origclordid   : Sample(20),
      execId        : Sample(8),
      ordStatus     : Sample(1),
      securityId    : Sample(8),
      side          : Sample(1),
      orderQty      : Sample(4),
      ordType       : Sample(1),
      priceOptional : Sample(8),
      leavesQty     : Sample(4),
      cumQty        : Sample(4),
      sendingTime   : Sample(8) ]

EncodeExecutionReportPendingReplaceMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.origclordid
        \o message.execId
        \o message.ordStatus
        \o message.securityId
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.priceOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime

DecodeExecutionReportPendingReplaceMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET origclordid == ReadBytes(listSeqNo.rest, 20) IN IF ~origclordid.ok THEN Fail ELSE
    LET execId == ReadBytes(origclordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(ordType.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(priceOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         clordid       |-> clordid.value,
         listSeqNo     |-> listSeqNo.value,
         origclordid   |-> origclordid.value,
         execId        |-> execId.value,
         ordStatus     |-> ordStatus.value,
         securityId    |-> securityId.value,
         side          |-> side.value,
         orderQty      |-> orderQty.value,
         ordType       |-> ordType.value,
         priceOptional |-> priceOptional.value,
         leavesQty     |-> leavesQty.value,
         cumQty        |-> cumQty.value,
         sendingTime   |-> sendingTime.value ], sendingTime.rest)

ZeroExecutionReportPendingReplaceMessage ==
    [ orderId       |-> [i \in 1 .. 8 |-> 0],
      clordid       |-> [i \in 1 .. 20 |-> 0],
      listSeqNo     |-> [i \in 1 .. 1 |-> 0],
      origclordid   |-> [i \in 1 .. 20 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      ordStatus     |-> [i \in 1 .. 1 |-> 0],
      securityId    |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      orderQty      |-> [i \in 1 .. 4 |-> 0],
      ordType       |-> [i \in 1 .. 1 |-> 0],
      priceOptional |-> [i \in 1 .. 8 |-> 0],
      leavesQty     |-> [i \in 1 .. 4 |-> 0],
      cumQty        |-> [i \in 1 .. 4 |-> 0],
      sendingTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Pending Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingReplaceMessage ==
    { ZeroExecutionReportPendingReplaceMessage }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.origclordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Replaced Message: 104 bytes                            *)
(***************************************************************************)

ExecutionReportReplacedMessage ==
    [ orderId       : Sample(8),
      clordid       : Sample(20),
      listSeqNo     : Sample(1),
      origclordid   : Sample(20),
      execId        : Sample(8),
      ordStatus     : Sample(1),
      securityId    : Sample(8),
      side          : Sample(1),
      orderQty      : Sample(4),
      ordType       : Sample(1),
      priceOptional : Sample(8),
      leavesQty     : Sample(4),
      cumQty        : Sample(4),
      sendingTime   : Sample(8),
      transactTime  : Sample(8) ]

EncodeExecutionReportReplacedMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.origclordid
        \o message.execId
        \o message.ordStatus
        \o message.securityId
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.priceOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime
        \o message.transactTime

DecodeExecutionReportReplacedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET origclordid == ReadBytes(listSeqNo.rest, 20) IN IF ~origclordid.ok THEN Fail ELSE
    LET execId == ReadBytes(origclordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(ordType.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(priceOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         clordid       |-> clordid.value,
         listSeqNo     |-> listSeqNo.value,
         origclordid   |-> origclordid.value,
         execId        |-> execId.value,
         ordStatus     |-> ordStatus.value,
         securityId    |-> securityId.value,
         side          |-> side.value,
         orderQty      |-> orderQty.value,
         ordType       |-> ordType.value,
         priceOptional |-> priceOptional.value,
         leavesQty     |-> leavesQty.value,
         cumQty        |-> cumQty.value,
         sendingTime   |-> sendingTime.value,
         transactTime  |-> transactTime.value ], transactTime.rest)

ZeroExecutionReportReplacedMessage ==
    [ orderId       |-> [i \in 1 .. 8 |-> 0],
      clordid       |-> [i \in 1 .. 20 |-> 0],
      listSeqNo     |-> [i \in 1 .. 1 |-> 0],
      origclordid   |-> [i \in 1 .. 20 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      ordStatus     |-> [i \in 1 .. 1 |-> 0],
      securityId    |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      orderQty      |-> [i \in 1 .. 4 |-> 0],
      ordType       |-> [i \in 1 .. 1 |-> 0],
      priceOptional |-> [i \in 1 .. 8 |-> 0],
      leavesQty     |-> [i \in 1 .. 4 |-> 0],
      cumQty        |-> [i \in 1 .. 4 |-> 0],
      sendingTime   |-> [i \in 1 .. 8 |-> 0],
      transactTime  |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportReplacedMessage ==
    { ZeroExecutionReportReplacedMessage }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.origclordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Trade Correction Message: 89 bytes                     *)
(***************************************************************************)

ExecutionReportTradeCorrectionMessage ==
    [ orderId     : Sample(8),
      clordid     : Sample(20),
      trdMatchId  : Sample(8),
      execId      : Sample(8),
      execRefId   : Sample(8),
      ordStatus   : Sample(1),
      securityId  : Sample(8),
      lastQty     : Sample(4),
      lastPx      : Sample(8),
      leavesQty   : Sample(4),
      cumQty      : Sample(4),
      sendingTime : Sample(8) ]

EncodeExecutionReportTradeCorrectionMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.trdMatchId
        \o message.execId
        \o message.execRefId
        \o message.ordStatus
        \o message.securityId
        \o message.lastQty
        \o message.lastPx
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime

DecodeExecutionReportTradeCorrectionMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(clordid.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET execId == ReadBytes(trdMatchId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(execId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRefId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ orderId     |-> orderId.value,
         clordid     |-> clordid.value,
         trdMatchId  |-> trdMatchId.value,
         execId      |-> execId.value,
         execRefId   |-> execRefId.value,
         ordStatus   |-> ordStatus.value,
         securityId  |-> securityId.value,
         lastQty     |-> lastQty.value,
         lastPx      |-> lastPx.value,
         leavesQty   |-> leavesQty.value,
         cumQty      |-> cumQty.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroExecutionReportTradeCorrectionMessage ==
    [ orderId     |-> [i \in 1 .. 8 |-> 0],
      clordid     |-> [i \in 1 .. 20 |-> 0],
      trdMatchId  |-> [i \in 1 .. 8 |-> 0],
      execId      |-> [i \in 1 .. 8 |-> 0],
      execRefId   |-> [i \in 1 .. 8 |-> 0],
      ordStatus   |-> [i \in 1 .. 1 |-> 0],
      securityId  |-> [i \in 1 .. 8 |-> 0],
      lastQty     |-> [i \in 1 .. 4 |-> 0],
      lastPx      |-> [i \in 1 .. 8 |-> 0],
      leavesQty   |-> [i \in 1 .. 4 |-> 0],
      cumQty      |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeCorrectionMessage ==
    { ZeroExecutionReportTradeCorrectionMessage }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Trade Break Message: 69 bytes                          *)
(***************************************************************************)

ExecutionReportTradeBreakMessage ==
    [ orderId     : Sample(8),
      clordid     : Sample(20),
      trdMatchId  : Sample(8),
      execId      : Sample(8),
      execRefId   : Sample(8),
      ordStatus   : Sample(1),
      leavesQty   : Sample(4),
      cumQty      : Sample(4),
      sendingTime : Sample(8) ]

EncodeExecutionReportTradeBreakMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.trdMatchId
        \o message.execId
        \o message.execRefId
        \o message.ordStatus
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime

DecodeExecutionReportTradeBreakMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(clordid.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET execId == ReadBytes(trdMatchId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(execId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRefId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordStatus.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ orderId     |-> orderId.value,
         clordid     |-> clordid.value,
         trdMatchId  |-> trdMatchId.value,
         execId      |-> execId.value,
         execRefId   |-> execRefId.value,
         ordStatus   |-> ordStatus.value,
         leavesQty   |-> leavesQty.value,
         cumQty      |-> cumQty.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroExecutionReportTradeBreakMessage ==
    [ orderId     |-> [i \in 1 .. 8 |-> 0],
      clordid     |-> [i \in 1 .. 20 |-> 0],
      trdMatchId  |-> [i \in 1 .. 8 |-> 0],
      execId      |-> [i \in 1 .. 8 |-> 0],
      execRefId   |-> [i \in 1 .. 8 |-> 0],
      ordStatus   |-> [i \in 1 .. 1 |-> 0],
      leavesQty   |-> [i \in 1 .. 4 |-> 0],
      cumQty      |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeBreakMessage ==
    { ZeroExecutionReportTradeBreakMessage }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Restatement Message: 85 bytes                          *)
(***************************************************************************)

ExecutionReportRestatementMessage ==
    [ orderId                   : Sample(8),
      clordid                   : Sample(20),
      listSeqNo                 : Sample(1),
      execId                    : Sample(8),
      ordStatus                 : Sample(1),
      securityId                : Sample(8),
      execRestatementReason     : Sample(1),
      extendedRestatementReason : Sample(1),
      side                      : Sample(1),
      lastPx                    : Sample(8),
      lastQtyOptional           : Sample(4),
      leavesQty                 : Sample(4),
      cumQty                    : Sample(4),
      sendingTime               : Sample(8),
      transactTime              : Sample(8) ]

EncodeExecutionReportRestatementMessage(message) ==
    message.orderId
        \o message.clordid
        \o message.listSeqNo
        \o message.execId
        \o message.ordStatus
        \o message.securityId
        \o message.execRestatementReason
        \o message.extendedRestatementReason
        \o message.side
        \o message.lastPx
        \o message.lastQtyOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.sendingTime
        \o message.transactTime

DecodeExecutionReportRestatementMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET execId == ReadBytes(listSeqNo.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET securityId == ReadBytes(ordStatus.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(securityId.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET extendedRestatementReason == ReadBytes(execRestatementReason.rest, 1) IN IF ~extendedRestatementReason.ok THEN Fail ELSE
    LET side == ReadBytes(extendedRestatementReason.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET lastPx == ReadBytes(side.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQtyOptional == ReadBytes(lastPx.rest, 4) IN IF ~lastQtyOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastQtyOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cumQty.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ orderId                   |-> orderId.value,
         clordid                   |-> clordid.value,
         listSeqNo                 |-> listSeqNo.value,
         execId                    |-> execId.value,
         ordStatus                 |-> ordStatus.value,
         securityId                |-> securityId.value,
         execRestatementReason     |-> execRestatementReason.value,
         extendedRestatementReason |-> extendedRestatementReason.value,
         side                      |-> side.value,
         lastPx                    |-> lastPx.value,
         lastQtyOptional           |-> lastQtyOptional.value,
         leavesQty                 |-> leavesQty.value,
         cumQty                    |-> cumQty.value,
         sendingTime               |-> sendingTime.value,
         transactTime              |-> transactTime.value ], transactTime.rest)

ZeroExecutionReportRestatementMessage ==
    [ orderId                   |-> [i \in 1 .. 8 |-> 0],
      clordid                   |-> [i \in 1 .. 20 |-> 0],
      listSeqNo                 |-> [i \in 1 .. 1 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 1 |-> 0],
      extendedRestatementReason |-> [i \in 1 .. 1 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0],
      lastQtyOptional           |-> [i \in 1 .. 4 |-> 0],
      leavesQty                 |-> [i \in 1 .. 4 |-> 0],
      cumQty                    |-> [i \in 1 .. 4 |-> 0],
      sendingTime               |-> [i \in 1 .. 8 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportRestatementMessage ==
    { ZeroExecutionReportRestatementMessage }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.extendedRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.lastQtyOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Pending Mass Cancel Message: 58 bytes                                   *)
(***************************************************************************)

PendingMassCancelMessage ==
    [ clordid                   : Sample(20),
      massCancelInst            : Sample(1),
      lockoutIdOptional         : Sample(8),
      efidOptional              : Sample(4),
      underlyingOrSeries        : Sample(1),
      underlierOptional         : Sample(6),
      optionsSecurityIdOptional : Sample(8),
      cancelGroupId             : Sample(2),
      sendingTime               : Sample(8) ]

EncodePendingMassCancelMessage(message) ==
    message.clordid
        \o message.massCancelInst
        \o message.lockoutIdOptional
        \o message.efidOptional
        \o message.underlyingOrSeries
        \o message.underlierOptional
        \o message.optionsSecurityIdOptional
        \o message.cancelGroupId
        \o message.sendingTime

DecodePendingMassCancelMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET massCancelInst == ReadBytes(clordid.rest, 1) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET lockoutIdOptional == ReadBytes(massCancelInst.rest, 8) IN IF ~lockoutIdOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(lockoutIdOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET underlyingOrSeries == ReadBytes(efidOptional.rest, 1) IN IF ~underlyingOrSeries.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(underlyingOrSeries.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET optionsSecurityIdOptional == ReadBytes(underlierOptional.rest, 8) IN IF ~optionsSecurityIdOptional.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(optionsSecurityIdOptional.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(cancelGroupId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid                   |-> clordid.value,
         massCancelInst            |-> massCancelInst.value,
         lockoutIdOptional         |-> lockoutIdOptional.value,
         efidOptional              |-> efidOptional.value,
         underlyingOrSeries        |-> underlyingOrSeries.value,
         underlierOptional         |-> underlierOptional.value,
         optionsSecurityIdOptional |-> optionsSecurityIdOptional.value,
         cancelGroupId             |-> cancelGroupId.value,
         sendingTime               |-> sendingTime.value ], sendingTime.rest)

ZeroPendingMassCancelMessage ==
    [ clordid                   |-> [i \in 1 .. 20 |-> 0],
      massCancelInst            |-> [i \in 1 .. 1 |-> 0],
      lockoutIdOptional         |-> [i \in 1 .. 8 |-> 0],
      efidOptional              |-> [i \in 1 .. 4 |-> 0],
      underlyingOrSeries        |-> [i \in 1 .. 1 |-> 0],
      underlierOptional         |-> [i \in 1 .. 6 |-> 0],
      optionsSecurityIdOptional |-> [i \in 1 .. 8 |-> 0],
      cancelGroupId             |-> [i \in 1 .. 2 |-> 0],
      sendingTime               |-> [i \in 1 .. 8 |-> 0] ]

(* Pending Mass Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedPendingMassCancelMessage ==
    { ZeroPendingMassCancelMessage }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.massCancelInst = one] : one \in Sample(1) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.lockoutIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.underlyingOrSeries = one] : one \in Sample(1) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.optionsSecurityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Reject Message: 52 bytes                                    *)
(***************************************************************************)

MassCancelRejectMessage ==
    [ clordid                   : Sample(20),
      massCancelRejectReason    : Sample(2),
      efidOptional              : Sample(4),
      underlyingOrSeries        : Sample(1),
      underlierOptional         : Sample(6),
      optionsSecurityIdOptional : Sample(8),
      cancelGroupId             : Sample(2),
      massCancelInst            : Sample(1),
      sendingTime               : Sample(8) ]

EncodeMassCancelRejectMessage(message) ==
    message.clordid
        \o message.massCancelRejectReason
        \o message.efidOptional
        \o message.underlyingOrSeries
        \o message.underlierOptional
        \o message.optionsSecurityIdOptional
        \o message.cancelGroupId
        \o message.massCancelInst
        \o message.sendingTime

DecodeMassCancelRejectMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(clordid.rest, 2) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(massCancelRejectReason.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET underlyingOrSeries == ReadBytes(efidOptional.rest, 1) IN IF ~underlyingOrSeries.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(underlyingOrSeries.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET optionsSecurityIdOptional == ReadBytes(underlierOptional.rest, 8) IN IF ~optionsSecurityIdOptional.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(optionsSecurityIdOptional.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET massCancelInst == ReadBytes(cancelGroupId.rest, 1) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(massCancelInst.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid                   |-> clordid.value,
         massCancelRejectReason    |-> massCancelRejectReason.value,
         efidOptional              |-> efidOptional.value,
         underlyingOrSeries        |-> underlyingOrSeries.value,
         underlierOptional         |-> underlierOptional.value,
         optionsSecurityIdOptional |-> optionsSecurityIdOptional.value,
         cancelGroupId             |-> cancelGroupId.value,
         massCancelInst            |-> massCancelInst.value,
         sendingTime               |-> sendingTime.value ], sendingTime.rest)

ZeroMassCancelRejectMessage ==
    [ clordid                   |-> [i \in 1 .. 20 |-> 0],
      massCancelRejectReason    |-> [i \in 1 .. 2 |-> 0],
      efidOptional              |-> [i \in 1 .. 4 |-> 0],
      underlyingOrSeries        |-> [i \in 1 .. 1 |-> 0],
      underlierOptional         |-> [i \in 1 .. 6 |-> 0],
      optionsSecurityIdOptional |-> [i \in 1 .. 8 |-> 0],
      cancelGroupId             |-> [i \in 1 .. 2 |-> 0],
      massCancelInst            |-> [i \in 1 .. 1 |-> 0],
      sendingTime               |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejectMessage ==
    { ZeroMassCancelRejectMessage }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.underlyingOrSeries = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.optionsSecurityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.massCancelInst = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Done Message: 32 bytes                                      *)
(***************************************************************************)

MassCancelDoneMessage ==
    [ clordid             : Sample(20),
      totalAffectedOrders : Sample(4),
      sendingTime         : Sample(8) ]

EncodeMassCancelDoneMessage(message) ==
    message.clordid
        \o message.totalAffectedOrders
        \o message.sendingTime

DecodeMassCancelDoneMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET totalAffectedOrders == ReadBytes(clordid.rest, 4) IN IF ~totalAffectedOrders.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(totalAffectedOrders.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid             |-> clordid.value,
         totalAffectedOrders |-> totalAffectedOrders.value,
         sendingTime         |-> sendingTime.value ], sendingTime.rest)

ZeroMassCancelDoneMessage ==
    [ clordid             |-> [i \in 1 .. 20 |-> 0],
      totalAffectedOrders |-> [i \in 1 .. 4 |-> 0],
      sendingTime         |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Done Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelDoneMessage ==
    { ZeroMassCancelDoneMessage }
        \cup { [ZeroMassCancelDoneMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelDoneMessage EXCEPT !.totalAffectedOrders = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelDoneMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Reject Message: 41 bytes                                   *)
(***************************************************************************)

OrderCancelRejectMessage ==
    [ clordid                   : Sample(20),
      listSeqNo                 : Sample(1),
      cxlRejResponseTo          : Sample(1),
      cxlRejReason              : Sample(2),
      optionsSecurityIdOptional : Sample(8),
      sideOptional              : Sample(1),
      sendingTime               : Sample(8) ]

EncodeOrderCancelRejectMessage(message) ==
    message.clordid
        \o message.listSeqNo
        \o message.cxlRejResponseTo
        \o message.cxlRejReason
        \o message.optionsSecurityIdOptional
        \o message.sideOptional
        \o message.sendingTime

DecodeOrderCancelRejectMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET cxlRejResponseTo == ReadBytes(listSeqNo.rest, 1) IN IF ~cxlRejResponseTo.ok THEN Fail ELSE
    LET cxlRejReason == ReadBytes(cxlRejResponseTo.rest, 2) IN IF ~cxlRejReason.ok THEN Fail ELSE
    LET optionsSecurityIdOptional == ReadBytes(cxlRejReason.rest, 8) IN IF ~optionsSecurityIdOptional.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(optionsSecurityIdOptional.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(sideOptional.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid                   |-> clordid.value,
         listSeqNo                 |-> listSeqNo.value,
         cxlRejResponseTo          |-> cxlRejResponseTo.value,
         cxlRejReason              |-> cxlRejReason.value,
         optionsSecurityIdOptional |-> optionsSecurityIdOptional.value,
         sideOptional              |-> sideOptional.value,
         sendingTime               |-> sendingTime.value ], sendingTime.rest)

ZeroOrderCancelRejectMessage ==
    [ clordid                   |-> [i \in 1 .. 20 |-> 0],
      listSeqNo                 |-> [i \in 1 .. 1 |-> 0],
      cxlRejResponseTo          |-> [i \in 1 .. 1 |-> 0],
      cxlRejReason              |-> [i \in 1 .. 2 |-> 0],
      optionsSecurityIdOptional |-> [i \in 1 .. 8 |-> 0],
      sideOptional              |-> [i \in 1 .. 1 |-> 0],
      sendingTime               |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRejectMessage ==
    { ZeroOrderCancelRejectMessage }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cxlRejResponseTo = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cxlRejReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.optionsSecurityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Allocation Instruction Ack Message: 39 bytes                            *)
(***************************************************************************)

AllocationInstructionAckMessage ==
    [ allocReportId : Sample(8),
      allocId       : Sample(20),
      allocStatus   : Sample(1),
      allocRejCode  : Sample(2),
      sendingTime   : Sample(8) ]

EncodeAllocationInstructionAckMessage(message) ==
    message.allocReportId
        \o message.allocId
        \o message.allocStatus
        \o message.allocRejCode
        \o message.sendingTime

DecodeAllocationInstructionAckMessage(bytes) ==
    LET allocReportId == ReadBytes(bytes, 8) IN IF ~allocReportId.ok THEN Fail ELSE
    LET allocId == ReadBytes(allocReportId.rest, 20) IN IF ~allocId.ok THEN Fail ELSE
    LET allocStatus == ReadBytes(allocId.rest, 1) IN IF ~allocStatus.ok THEN Fail ELSE
    LET allocRejCode == ReadBytes(allocStatus.rest, 2) IN IF ~allocRejCode.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(allocRejCode.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ allocReportId |-> allocReportId.value,
         allocId       |-> allocId.value,
         allocStatus   |-> allocStatus.value,
         allocRejCode  |-> allocRejCode.value,
         sendingTime   |-> sendingTime.value ], sendingTime.rest)

ZeroAllocationInstructionAckMessage ==
    [ allocReportId |-> [i \in 1 .. 8 |-> 0],
      allocId       |-> [i \in 1 .. 20 |-> 0],
      allocStatus   |-> [i \in 1 .. 1 |-> 0],
      allocRejCode  |-> [i \in 1 .. 2 |-> 0],
      sendingTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Allocation Instruction Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedAllocationInstructionAckMessage ==
    { ZeroAllocationInstructionAckMessage }
        \cup { [ZeroAllocationInstructionAckMessage EXCEPT !.allocReportId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionAckMessage EXCEPT !.allocId = one] : one \in Sample(20) }
        \cup { [ZeroAllocationInstructionAckMessage EXCEPT !.allocStatus = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionAckMessage EXCEPT !.allocRejCode = one] : one \in Sample(2) }
        \cup { [ZeroAllocationInstructionAckMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Allocation Report Message Parties Group: 18 bytes                       *)
(***************************************************************************)

AllocationReportMessagePartiesGroup ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodeAllocationReportMessagePartiesGroup(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodeAllocationReportMessagePartiesGroup(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroAllocationReportMessagePartiesGroup ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Allocation Report Message Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedAllocationReportMessagePartiesGroup ==
    { ZeroAllocationReportMessagePartiesGroup }
        \cup { [ZeroAllocationReportMessagePartiesGroup EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroAllocationReportMessagePartiesGroup EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessagePartiesGroup EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Allocation Report Message Parties Group, written one after another *)
RECURSIVE EncodeAllocationReportMessagePartiesGroupList(_)
EncodeAllocationReportMessagePartiesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAllocationReportMessagePartiesGroup(Head(messages)) \o EncodeAllocationReportMessagePartiesGroupList(Tail(messages))

(* As many Allocation Report Message Parties Group as the field that counts them says *)
RECURSIVE ReadAllocationReportMessagePartiesGroupList(_, _)
ReadAllocationReportMessagePartiesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAllocationReportMessagePartiesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAllocationReportMessagePartiesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Allocation Report Message Parties Group of each kind, for the lists that carry them *)
OneAllocationReportMessagePartiesGroup == { ZeroAllocationReportMessagePartiesGroup }

(***************************************************************************)
(* Allocation Report Message Parties Groups                                *)
(***************************************************************************)

AllocationReportMessagePartiesGroups ==
    [ blockLengthShort                    : Sample(1),
      allocationReportMessagePartiesGroup : SampleLists(OneAllocationReportMessagePartiesGroup) ]

EncodeAllocationReportMessagePartiesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.allocationReportMessagePartiesGroup), 1)
        \o EncodeAllocationReportMessagePartiesGroupList(message.allocationReportMessagePartiesGroup)

DecodeAllocationReportMessagePartiesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET allocationReportMessagePartiesGroup == ReadAllocationReportMessagePartiesGroupList(numInGroup.rest, numInGroup.value) IN IF ~allocationReportMessagePartiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                    |-> blockLengthShort.value,
         allocationReportMessagePartiesGroup |-> allocationReportMessagePartiesGroup.value ], allocationReportMessagePartiesGroup.rest)

ZeroAllocationReportMessagePartiesGroups ==
    [ blockLengthShort                    |-> [i \in 1 .. 1 |-> 0],
      allocationReportMessagePartiesGroup |-> << >> ]

(* Allocation Report Message Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedAllocationReportMessagePartiesGroups ==
    { ZeroAllocationReportMessagePartiesGroups }
        \cup { [ZeroAllocationReportMessagePartiesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessagePartiesGroups EXCEPT !.allocationReportMessagePartiesGroup = one] : one \in SampleLists(OneAllocationReportMessagePartiesGroup) }

(***************************************************************************)
(* Allocation Report Message Allocations Group                             *)
(***************************************************************************)

AllocationReportMessageAllocationsGroup ==
    [ allocQty                             : Sample(4),
      tradingCapacity                      : Sample(1),
      openOrClose                          : Sample(1),
      allocationReportMessagePartiesGroups : AllocationReportMessagePartiesGroups ]

EncodeAllocationReportMessageAllocationsGroup(message) ==
    message.allocQty
        \o message.tradingCapacity
        \o message.openOrClose
        \o EncodeAllocationReportMessagePartiesGroups(message.allocationReportMessagePartiesGroups)

DecodeAllocationReportMessageAllocationsGroup(bytes) ==
    LET allocQty == ReadBytes(bytes, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(allocQty.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET openOrClose == ReadBytes(tradingCapacity.rest, 1) IN IF ~openOrClose.ok THEN Fail ELSE
    LET allocationReportMessagePartiesGroups == DecodeAllocationReportMessagePartiesGroups(openOrClose.rest) IN IF ~allocationReportMessagePartiesGroups.ok THEN Fail ELSE
    Ok([ allocQty                             |-> allocQty.value,
         tradingCapacity                      |-> tradingCapacity.value,
         openOrClose                          |-> openOrClose.value,
         allocationReportMessagePartiesGroups |-> allocationReportMessagePartiesGroups.value ], allocationReportMessagePartiesGroups.rest)

ZeroAllocationReportMessageAllocationsGroup ==
    [ allocQty                             |-> [i \in 1 .. 4 |-> 0],
      tradingCapacity                      |-> [i \in 1 .. 1 |-> 0],
      openOrClose                          |-> [i \in 1 .. 1 |-> 0],
      allocationReportMessagePartiesGroups |-> ZeroAllocationReportMessagePartiesGroups ]

(* Allocation Report Message Allocations Group at zero, then each field in turn at the values it is checked at *)
CheckedAllocationReportMessageAllocationsGroup ==
    { ZeroAllocationReportMessageAllocationsGroup }
        \cup { [ZeroAllocationReportMessageAllocationsGroup EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroAllocationReportMessageAllocationsGroup EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessageAllocationsGroup EXCEPT !.openOrClose = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessageAllocationsGroup EXCEPT !.allocationReportMessagePartiesGroups = one] : one \in CheckedAllocationReportMessagePartiesGroups }

(* A run of Allocation Report Message Allocations Group, written one after another *)
RECURSIVE EncodeAllocationReportMessageAllocationsGroupList(_)
EncodeAllocationReportMessageAllocationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAllocationReportMessageAllocationsGroup(Head(messages)) \o EncodeAllocationReportMessageAllocationsGroupList(Tail(messages))

(* As many Allocation Report Message Allocations Group as the field that counts them says *)
RECURSIVE ReadAllocationReportMessageAllocationsGroupList(_, _)
ReadAllocationReportMessageAllocationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAllocationReportMessageAllocationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAllocationReportMessageAllocationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Allocation Report Message Allocations Group of each kind, for the lists that carry them *)
OneAllocationReportMessageAllocationsGroup == { ZeroAllocationReportMessageAllocationsGroup }

(***************************************************************************)
(* Allocation Report Message Allocations Groups                            *)
(***************************************************************************)

AllocationReportMessageAllocationsGroups ==
    [ blockLengthShort                        : Sample(1),
      allocationReportMessageAllocationsGroup : SampleLists(OneAllocationReportMessageAllocationsGroup) ]

EncodeAllocationReportMessageAllocationsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.allocationReportMessageAllocationsGroup), 1)
        \o EncodeAllocationReportMessageAllocationsGroupList(message.allocationReportMessageAllocationsGroup)

DecodeAllocationReportMessageAllocationsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET allocationReportMessageAllocationsGroup == ReadAllocationReportMessageAllocationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~allocationReportMessageAllocationsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                        |-> blockLengthShort.value,
         allocationReportMessageAllocationsGroup |-> allocationReportMessageAllocationsGroup.value ], allocationReportMessageAllocationsGroup.rest)

ZeroAllocationReportMessageAllocationsGroups ==
    [ blockLengthShort                        |-> [i \in 1 .. 1 |-> 0],
      allocationReportMessageAllocationsGroup |-> << >> ]

(* Allocation Report Message Allocations Groups at zero, then each field in turn at the values it is checked at *)
CheckedAllocationReportMessageAllocationsGroups ==
    { ZeroAllocationReportMessageAllocationsGroups }
        \cup { [ZeroAllocationReportMessageAllocationsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessageAllocationsGroups EXCEPT !.allocationReportMessageAllocationsGroup = one] : one \in SampleLists(OneAllocationReportMessageAllocationsGroup) }

(***************************************************************************)
(* Allocation Report Message                                               *)
(***************************************************************************)

AllocationReportMessage ==
    [ allocReportId                            : Sample(8),
      allocId                                  : Sample(20),
      allocTransType                           : Sample(1),
      allocType                                : Sample(1),
      allocStatus                              : Sample(1),
      execRefId                                : Sample(8),
      trdMatchId                               : Sample(8),
      securityId                               : Sample(8),
      side                                     : Sample(1),
      quantityLong                             : Sample(4),
      tradeDate                                : Sample(8),
      sendingTime                              : Sample(8),
      allocationReportMessageAllocationsGroups : AllocationReportMessageAllocationsGroups ]

EncodeAllocationReportMessage(message) ==
    message.allocReportId
        \o message.allocId
        \o message.allocTransType
        \o message.allocType
        \o message.allocStatus
        \o message.execRefId
        \o message.trdMatchId
        \o message.securityId
        \o message.side
        \o message.quantityLong
        \o message.tradeDate
        \o message.sendingTime
        \o EncodeAllocationReportMessageAllocationsGroups(message.allocationReportMessageAllocationsGroups)

DecodeAllocationReportMessage(bytes) ==
    LET allocReportId == ReadBytes(bytes, 8) IN IF ~allocReportId.ok THEN Fail ELSE
    LET allocId == ReadBytes(allocReportId.rest, 20) IN IF ~allocId.ok THEN Fail ELSE
    LET allocTransType == ReadBytes(allocId.rest, 1) IN IF ~allocTransType.ok THEN Fail ELSE
    LET allocType == ReadBytes(allocTransType.rest, 1) IN IF ~allocType.ok THEN Fail ELSE
    LET allocStatus == ReadBytes(allocType.rest, 1) IN IF ~allocStatus.ok THEN Fail ELSE
    LET execRefId == ReadBytes(allocStatus.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(execRefId.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdMatchId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(side.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(quantityLong.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(tradeDate.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET allocationReportMessageAllocationsGroups == DecodeAllocationReportMessageAllocationsGroups(sendingTime.rest) IN IF ~allocationReportMessageAllocationsGroups.ok THEN Fail ELSE
    Ok([ allocReportId                            |-> allocReportId.value,
         allocId                                  |-> allocId.value,
         allocTransType                           |-> allocTransType.value,
         allocType                                |-> allocType.value,
         allocStatus                              |-> allocStatus.value,
         execRefId                                |-> execRefId.value,
         trdMatchId                               |-> trdMatchId.value,
         securityId                               |-> securityId.value,
         side                                     |-> side.value,
         quantityLong                             |-> quantityLong.value,
         tradeDate                                |-> tradeDate.value,
         sendingTime                              |-> sendingTime.value,
         allocationReportMessageAllocationsGroups |-> allocationReportMessageAllocationsGroups.value ], allocationReportMessageAllocationsGroups.rest)

ZeroAllocationReportMessage ==
    [ allocReportId                            |-> [i \in 1 .. 8 |-> 0],
      allocId                                  |-> [i \in 1 .. 20 |-> 0],
      allocTransType                           |-> [i \in 1 .. 1 |-> 0],
      allocType                                |-> [i \in 1 .. 1 |-> 0],
      allocStatus                              |-> [i \in 1 .. 1 |-> 0],
      execRefId                                |-> [i \in 1 .. 8 |-> 0],
      trdMatchId                               |-> [i \in 1 .. 8 |-> 0],
      securityId                               |-> [i \in 1 .. 8 |-> 0],
      side                                     |-> [i \in 1 .. 1 |-> 0],
      quantityLong                             |-> [i \in 1 .. 4 |-> 0],
      tradeDate                                |-> [i \in 1 .. 8 |-> 0],
      sendingTime                              |-> [i \in 1 .. 8 |-> 0],
      allocationReportMessageAllocationsGroups |-> ZeroAllocationReportMessageAllocationsGroups ]

(* Allocation Report Message at zero, then each field in turn at the values it is checked at *)
CheckedAllocationReportMessage ==
    { ZeroAllocationReportMessage }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocReportId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocId = one] : one \in Sample(20) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocTransType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocStatus = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocationReportMessageAllocationsGroups = one] : one \in CheckedAllocationReportMessageAllocationsGroups }

(***************************************************************************)
(* User Notification Message: 9 bytes                                      *)
(***************************************************************************)

UserNotificationMessage ==
    [ sendingTime : Sample(8),
      userStatus  : Sample(1) ]

EncodeUserNotificationMessage(message) ==
    message.sendingTime
        \o message.userStatus

DecodeUserNotificationMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET userStatus == ReadBytes(sendingTime.rest, 1) IN IF ~userStatus.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value,
         userStatus  |-> userStatus.value ], userStatus.rest)

ZeroUserNotificationMessage ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0],
      userStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* User Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUserNotificationMessage ==
    { ZeroUserNotificationMessage }
        \cup { [ZeroUserNotificationMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.userStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Clear Lockout Reject Message: 38 bytes                      *)
(***************************************************************************)

MassCancelClearLockoutRejectMessage ==
    [ clordid     : Sample(20),
      lockoutId   : Sample(8),
      rejReason   : Sample(2),
      sendingTime : Sample(8) ]

EncodeMassCancelClearLockoutRejectMessage(message) ==
    message.clordid
        \o message.lockoutId
        \o message.rejReason
        \o message.sendingTime

DecodeMassCancelClearLockoutRejectMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET lockoutId == ReadBytes(clordid.rest, 8) IN IF ~lockoutId.ok THEN Fail ELSE
    LET rejReason == ReadBytes(lockoutId.rest, 2) IN IF ~rejReason.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(rejReason.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid     |-> clordid.value,
         lockoutId   |-> lockoutId.value,
         rejReason   |-> rejReason.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroMassCancelClearLockoutRejectMessage ==
    [ clordid     |-> [i \in 1 .. 20 |-> 0],
      lockoutId   |-> [i \in 1 .. 8 |-> 0],
      rejReason   |-> [i \in 1 .. 2 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Clear Lockout Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelClearLockoutRejectMessage ==
    { ZeroMassCancelClearLockoutRejectMessage }
        \cup { [ZeroMassCancelClearLockoutRejectMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelClearLockoutRejectMessage EXCEPT !.lockoutId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelClearLockoutRejectMessage EXCEPT !.rejReason = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelClearLockoutRejectMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Clear Lockout Done Message: 36 bytes                        *)
(***************************************************************************)

MassCancelClearLockoutDoneMessage ==
    [ clordid     : Sample(20),
      lockoutId   : Sample(8),
      sendingTime : Sample(8) ]

EncodeMassCancelClearLockoutDoneMessage(message) ==
    message.clordid
        \o message.lockoutId
        \o message.sendingTime

DecodeMassCancelClearLockoutDoneMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET lockoutId == ReadBytes(clordid.rest, 8) IN IF ~lockoutId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(lockoutId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ clordid     |-> clordid.value,
         lockoutId   |-> lockoutId.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroMassCancelClearLockoutDoneMessage ==
    [ clordid     |-> [i \in 1 .. 20 |-> 0],
      lockoutId   |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Clear Lockout Done Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelClearLockoutDoneMessage ==
    { ZeroMassCancelClearLockoutDoneMessage }
        \cup { [ZeroMassCancelClearLockoutDoneMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelClearLockoutDoneMessage EXCEPT !.lockoutId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelClearLockoutDoneMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

ExecutionReportNewMessageCode == 11  \* 0x0b
ExecutionReportBulkQuotePendingNewMessageCode == 12  \* 0x0c
ExecutionReportBulkQuoteComponentNewMessageCode == 13  \* 0x0d
ExecutionReportRejectedMessageCode == 14  \* 0x0e
ExecutionReportTradeMessageCode == 15  \* 0x0f
ExecutionReportPendingCancelMessageCode == 16  \* 0x10
ExecutionReportCanceledMessageCode == 17  \* 0x11
ExecutionReportPendingReplaceMessageCode == 18  \* 0x12
ExecutionReportReplacedMessageCode == 19  \* 0x13
ExecutionReportTradeCorrectionMessageCode == 20  \* 0x14
ExecutionReportTradeBreakMessageCode == 21  \* 0x15
ExecutionReportRestatementMessageCode == 22  \* 0x16
PendingMassCancelMessageCode == 23  \* 0x17
MassCancelRejectMessageCode == 24  \* 0x18
MassCancelDoneMessageCode == 25  \* 0x19
OrderCancelRejectMessageCode == 26  \* 0x1a
AllocationInstructionAckMessageCode == 27  \* 0x1b
AllocationReportMessageCode == 28  \* 0x1c
UserNotificationMessageCode == 29  \* 0x1d
MassCancelClearLockoutRejectMessageCode == 30  \* 0x1e
MassCancelClearLockoutDoneMessageCode == 31  \* 0x1f

ServerPayload ==
    [ tag : {ExecutionReportNewMessageCode}, body : ExecutionReportNewMessage ]
        \cup [ tag : {ExecutionReportBulkQuotePendingNewMessageCode}, body : ExecutionReportBulkQuotePendingNewMessage ]
        \cup [ tag : {ExecutionReportBulkQuoteComponentNewMessageCode}, body : ExecutionReportBulkQuoteComponentNewMessage ]
        \cup [ tag : {ExecutionReportRejectedMessageCode}, body : ExecutionReportRejectedMessage ]
        \cup [ tag : {ExecutionReportTradeMessageCode}, body : ExecutionReportTradeMessage ]
        \cup [ tag : {ExecutionReportPendingCancelMessageCode}, body : ExecutionReportPendingCancelMessage ]
        \cup [ tag : {ExecutionReportCanceledMessageCode}, body : ExecutionReportCanceledMessage ]
        \cup [ tag : {ExecutionReportPendingReplaceMessageCode}, body : ExecutionReportPendingReplaceMessage ]
        \cup [ tag : {ExecutionReportReplacedMessageCode}, body : ExecutionReportReplacedMessage ]
        \cup [ tag : {ExecutionReportTradeCorrectionMessageCode}, body : ExecutionReportTradeCorrectionMessage ]
        \cup [ tag : {ExecutionReportTradeBreakMessageCode}, body : ExecutionReportTradeBreakMessage ]
        \cup [ tag : {ExecutionReportRestatementMessageCode}, body : ExecutionReportRestatementMessage ]
        \cup [ tag : {PendingMassCancelMessageCode}, body : PendingMassCancelMessage ]
        \cup [ tag : {MassCancelRejectMessageCode}, body : MassCancelRejectMessage ]
        \cup [ tag : {MassCancelDoneMessageCode}, body : MassCancelDoneMessage ]
        \cup [ tag : {OrderCancelRejectMessageCode}, body : OrderCancelRejectMessage ]
        \cup [ tag : {AllocationInstructionAckMessageCode}, body : AllocationInstructionAckMessage ]
        \cup [ tag : {AllocationReportMessageCode}, body : AllocationReportMessage ]
        \cup [ tag : {UserNotificationMessageCode}, body : UserNotificationMessage ]
        \cup [ tag : {MassCancelClearLockoutRejectMessageCode}, body : MassCancelClearLockoutRejectMessage ]
        \cup [ tag : {MassCancelClearLockoutDoneMessageCode}, body : MassCancelClearLockoutDoneMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = ExecutionReportNewMessageCode -> EncodeExecutionReportNewMessage(message.body)
      [] message.tag = ExecutionReportBulkQuotePendingNewMessageCode -> EncodeExecutionReportBulkQuotePendingNewMessage(message.body)
      [] message.tag = ExecutionReportBulkQuoteComponentNewMessageCode -> EncodeExecutionReportBulkQuoteComponentNewMessage(message.body)
      [] message.tag = ExecutionReportRejectedMessageCode -> EncodeExecutionReportRejectedMessage(message.body)
      [] message.tag = ExecutionReportTradeMessageCode -> EncodeExecutionReportTradeMessage(message.body)
      [] message.tag = ExecutionReportPendingCancelMessageCode -> EncodeExecutionReportPendingCancelMessage(message.body)
      [] message.tag = ExecutionReportCanceledMessageCode -> EncodeExecutionReportCanceledMessage(message.body)
      [] message.tag = ExecutionReportPendingReplaceMessageCode -> EncodeExecutionReportPendingReplaceMessage(message.body)
      [] message.tag = ExecutionReportReplacedMessageCode -> EncodeExecutionReportReplacedMessage(message.body)
      [] message.tag = ExecutionReportTradeCorrectionMessageCode -> EncodeExecutionReportTradeCorrectionMessage(message.body)
      [] message.tag = ExecutionReportTradeBreakMessageCode -> EncodeExecutionReportTradeBreakMessage(message.body)
      [] message.tag = ExecutionReportRestatementMessageCode -> EncodeExecutionReportRestatementMessage(message.body)
      [] message.tag = PendingMassCancelMessageCode -> EncodePendingMassCancelMessage(message.body)
      [] message.tag = MassCancelRejectMessageCode -> EncodeMassCancelRejectMessage(message.body)
      [] message.tag = MassCancelDoneMessageCode -> EncodeMassCancelDoneMessage(message.body)
      [] message.tag = OrderCancelRejectMessageCode -> EncodeOrderCancelRejectMessage(message.body)
      [] message.tag = AllocationInstructionAckMessageCode -> EncodeAllocationInstructionAckMessage(message.body)
      [] message.tag = AllocationReportMessageCode -> EncodeAllocationReportMessage(message.body)
      [] message.tag = UserNotificationMessageCode -> EncodeUserNotificationMessage(message.body)
      [] message.tag = MassCancelClearLockoutRejectMessageCode -> EncodeMassCancelClearLockoutRejectMessage(message.body)
      [] message.tag = MassCancelClearLockoutDoneMessageCode -> EncodeMassCancelClearLockoutDoneMessage(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = ExecutionReportNewMessageCode -> DecodeExecutionReportNewMessage(bytes)
              [] tag = ExecutionReportBulkQuotePendingNewMessageCode -> DecodeExecutionReportBulkQuotePendingNewMessage(bytes)
              [] tag = ExecutionReportBulkQuoteComponentNewMessageCode -> DecodeExecutionReportBulkQuoteComponentNewMessage(bytes)
              [] tag = ExecutionReportRejectedMessageCode -> DecodeExecutionReportRejectedMessage(bytes)
              [] tag = ExecutionReportTradeMessageCode -> DecodeExecutionReportTradeMessage(bytes)
              [] tag = ExecutionReportPendingCancelMessageCode -> DecodeExecutionReportPendingCancelMessage(bytes)
              [] tag = ExecutionReportCanceledMessageCode -> DecodeExecutionReportCanceledMessage(bytes)
              [] tag = ExecutionReportPendingReplaceMessageCode -> DecodeExecutionReportPendingReplaceMessage(bytes)
              [] tag = ExecutionReportReplacedMessageCode -> DecodeExecutionReportReplacedMessage(bytes)
              [] tag = ExecutionReportTradeCorrectionMessageCode -> DecodeExecutionReportTradeCorrectionMessage(bytes)
              [] tag = ExecutionReportTradeBreakMessageCode -> DecodeExecutionReportTradeBreakMessage(bytes)
              [] tag = ExecutionReportRestatementMessageCode -> DecodeExecutionReportRestatementMessage(bytes)
              [] tag = PendingMassCancelMessageCode -> DecodePendingMassCancelMessage(bytes)
              [] tag = MassCancelRejectMessageCode -> DecodeMassCancelRejectMessage(bytes)
              [] tag = MassCancelDoneMessageCode -> DecodeMassCancelDoneMessage(bytes)
              [] tag = OrderCancelRejectMessageCode -> DecodeOrderCancelRejectMessage(bytes)
              [] tag = AllocationInstructionAckMessageCode -> DecodeAllocationInstructionAckMessage(bytes)
              [] tag = AllocationReportMessageCode -> DecodeAllocationReportMessage(bytes)
              [] tag = UserNotificationMessageCode -> DecodeUserNotificationMessage(bytes)
              [] tag = MassCancelClearLockoutRejectMessageCode -> DecodeMassCancelClearLockoutRejectMessage(bytes)
              [] tag = MassCancelClearLockoutDoneMessageCode -> DecodeMassCancelClearLockoutDoneMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> ExecutionReportNewMessageCode, body |-> ZeroExecutionReportNewMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> ExecutionReportNewMessageCode, body |-> one] : one \in CheckedExecutionReportNewMessage }
        \cup { [tag |-> ExecutionReportBulkQuotePendingNewMessageCode, body |-> one] : one \in CheckedExecutionReportBulkQuotePendingNewMessage }
        \cup { [tag |-> ExecutionReportBulkQuoteComponentNewMessageCode, body |-> one] : one \in CheckedExecutionReportBulkQuoteComponentNewMessage }
        \cup { [tag |-> ExecutionReportRejectedMessageCode, body |-> one] : one \in CheckedExecutionReportRejectedMessage }
        \cup { [tag |-> ExecutionReportTradeMessageCode, body |-> one] : one \in CheckedExecutionReportTradeMessage }
        \cup { [tag |-> ExecutionReportPendingCancelMessageCode, body |-> one] : one \in CheckedExecutionReportPendingCancelMessage }
        \cup { [tag |-> ExecutionReportCanceledMessageCode, body |-> one] : one \in CheckedExecutionReportCanceledMessage }
        \cup { [tag |-> ExecutionReportPendingReplaceMessageCode, body |-> one] : one \in CheckedExecutionReportPendingReplaceMessage }
        \cup { [tag |-> ExecutionReportReplacedMessageCode, body |-> one] : one \in CheckedExecutionReportReplacedMessage }
        \cup { [tag |-> ExecutionReportTradeCorrectionMessageCode, body |-> one] : one \in CheckedExecutionReportTradeCorrectionMessage }
        \cup { [tag |-> ExecutionReportTradeBreakMessageCode, body |-> one] : one \in CheckedExecutionReportTradeBreakMessage }
        \cup { [tag |-> ExecutionReportRestatementMessageCode, body |-> one] : one \in CheckedExecutionReportRestatementMessage }
        \cup { [tag |-> PendingMassCancelMessageCode, body |-> one] : one \in CheckedPendingMassCancelMessage }
        \cup { [tag |-> MassCancelRejectMessageCode, body |-> one] : one \in CheckedMassCancelRejectMessage }
        \cup { [tag |-> MassCancelDoneMessageCode, body |-> one] : one \in CheckedMassCancelDoneMessage }
        \cup { [tag |-> OrderCancelRejectMessageCode, body |-> one] : one \in CheckedOrderCancelRejectMessage }
        \cup { [tag |-> AllocationInstructionAckMessageCode, body |-> one] : one \in CheckedAllocationInstructionAckMessage }
        \cup { [tag |-> AllocationReportMessageCode, body |-> one] : one \in CheckedAllocationReportMessage }
        \cup { [tag |-> UserNotificationMessageCode, body |-> one] : one \in CheckedUserNotificationMessage }
        \cup { [tag |-> MassCancelClearLockoutRejectMessageCode, body |-> one] : one \in CheckedMassCancelClearLockoutRejectMessage }
        \cup { [tag |-> MassCancelClearLockoutDoneMessageCode, body |-> one] : one \in CheckedMassCancelClearLockoutDoneMessage }

(***************************************************************************)
(* Server Sbe Message                                                      *)
(***************************************************************************)

ServerSbeMessage ==
    [ blockLength   : Sample(2),
      schemaId      : Sample(1),
      version       : Sample(2),
      numGroups     : Sample(1),
      serverPayload : ServerPayload ]

EncodeServerSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.serverPayload.tag, 1)
        \o message.schemaId
        \o message.version
        \o message.numGroups
        \o EncodeServerPayload(message.serverPayload)

DecodeServerSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET numGroups == ReadBytes(version.rest, 1) IN IF ~numGroups.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(templateId.value, numGroups.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         numGroups     |-> numGroups.value,
         serverPayload |-> serverPayload.value ], serverPayload.rest)

ZeroServerSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 1 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      numGroups     |-> [i \in 1 .. 1 |-> 0],
      serverPayload |-> ZeroServerPayload ]

(* Server Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedServerSbeMessage ==
    { ZeroServerSbeMessage }
        \cup { [ZeroServerSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroServerSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroServerSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerSbeMessage EXCEPT !.numGroups = one] : one \in Sample(1) }
        \cup { [ZeroServerSbeMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(***************************************************************************)
(* Sequenced Message                                                       *)
(***************************************************************************)

SequencedMessage ==
    [ serverSbeMessage : ServerSbeMessage ]

EncodeSequencedMessage(message) ==
    EncodeServerSbeMessage(message.serverSbeMessage)

DecodeSequencedMessage(bytes) ==
    LET serverSbeMessage == DecodeServerSbeMessage(bytes) IN IF ~serverSbeMessage.ok THEN Fail ELSE
    Ok([ serverSbeMessage |-> serverSbeMessage.value ], serverSbeMessage.rest)

ZeroSequencedMessage ==
    [ serverSbeMessage |-> ZeroServerSbeMessage ]

(* Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessage ==
    { ZeroSequencedMessage }
        \cup { [ZeroSequencedMessage EXCEPT !.serverSbeMessage = one] : one \in CheckedServerSbeMessage }

(***************************************************************************)
(* Server Data, selected by Message Type                                   *)
(***************************************************************************)

LoginAcceptedMessageCode == 1  \* 0x01
LoginRejectedMessageCode == 2  \* 0x02
StartOfSessionMessageCode == 3  \* 0x03
ReplayBeginMessageCode == 5  \* 0x05
ReplayRejectedMessageCode == 6  \* 0x06
ReplayCompleteMessageCode == 7  \* 0x07
StreamBeginMessageCode == 8  \* 0x08
StreamRejectedMessageCode == 9  \* 0x09
StreamCompleteMessageCode == 10  \* 0x0a
SequencedMessageCode == 11  \* 0x0b

ServerData ==
    [ tag : {LoginAcceptedMessageCode}, body : LoginAcceptedMessage ]
        \cup [ tag : {LoginRejectedMessageCode}, body : LoginRejectedMessage ]
        \cup [ tag : {StartOfSessionMessageCode}, body : StartOfSessionMessage ]
        \cup [ tag : {ReplayBeginMessageCode}, body : ReplayBeginMessage ]
        \cup [ tag : {ReplayRejectedMessageCode}, body : ReplayRejectedMessage ]
        \cup [ tag : {ReplayCompleteMessageCode}, body : ReplayCompleteMessage ]
        \cup [ tag : {StreamBeginMessageCode}, body : StreamBeginMessage ]
        \cup [ tag : {StreamRejectedMessageCode}, body : StreamRejectedMessage ]
        \cup [ tag : {StreamCompleteMessageCode}, body : StreamCompleteMessage ]
        \cup [ tag : {SequencedMessageCode}, body : SequencedMessage ]

EncodeServerData(message) ==
    CASE message.tag = LoginAcceptedMessageCode -> EncodeLoginAcceptedMessage(message.body)
      [] message.tag = LoginRejectedMessageCode -> EncodeLoginRejectedMessage(message.body)
      [] message.tag = StartOfSessionMessageCode -> EncodeStartOfSessionMessage(message.body)
      [] message.tag = ReplayBeginMessageCode -> EncodeReplayBeginMessage(message.body)
      [] message.tag = ReplayRejectedMessageCode -> EncodeReplayRejectedMessage(message.body)
      [] message.tag = ReplayCompleteMessageCode -> EncodeReplayCompleteMessage(message.body)
      [] message.tag = StreamBeginMessageCode -> EncodeStreamBeginMessage(message.body)
      [] message.tag = StreamRejectedMessageCode -> EncodeStreamRejectedMessage(message.body)
      [] message.tag = StreamCompleteMessageCode -> EncodeStreamCompleteMessage(message.body)
      [] message.tag = SequencedMessageCode -> EncodeSequencedMessage(message.body)

DecodeServerData(tag, bytes) ==
    LET read ==
            CASE tag = LoginAcceptedMessageCode -> DecodeLoginAcceptedMessage(bytes)
              [] tag = LoginRejectedMessageCode -> DecodeLoginRejectedMessage(bytes)
              [] tag = StartOfSessionMessageCode -> DecodeStartOfSessionMessage(bytes)
              [] tag = ReplayBeginMessageCode -> DecodeReplayBeginMessage(bytes)
              [] tag = ReplayRejectedMessageCode -> DecodeReplayRejectedMessage(bytes)
              [] tag = ReplayCompleteMessageCode -> DecodeReplayCompleteMessage(bytes)
              [] tag = StreamBeginMessageCode -> DecodeStreamBeginMessage(bytes)
              [] tag = StreamRejectedMessageCode -> DecodeStreamRejectedMessage(bytes)
              [] tag = StreamCompleteMessageCode -> DecodeStreamCompleteMessage(bytes)
              [] tag = SequencedMessageCode -> DecodeSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerData == [tag |-> LoginAcceptedMessageCode, body |-> ZeroLoginAcceptedMessage]

(* Each Server Data in turn, at the values the message it names is checked at *)
CheckedServerData ==
    { [tag |-> LoginAcceptedMessageCode, body |-> one] : one \in CheckedLoginAcceptedMessage }
        \cup { [tag |-> LoginRejectedMessageCode, body |-> one] : one \in CheckedLoginRejectedMessage }
        \cup { [tag |-> StartOfSessionMessageCode, body |-> one] : one \in CheckedStartOfSessionMessage }
        \cup { [tag |-> ReplayBeginMessageCode, body |-> one] : one \in CheckedReplayBeginMessage }
        \cup { [tag |-> ReplayRejectedMessageCode, body |-> one] : one \in CheckedReplayRejectedMessage }
        \cup { [tag |-> ReplayCompleteMessageCode, body |-> one] : one \in CheckedReplayCompleteMessage }
        \cup { [tag |-> StreamBeginMessageCode, body |-> one] : one \in CheckedStreamBeginMessage }
        \cup { [tag |-> StreamRejectedMessageCode, body |-> one] : one \in CheckedStreamRejectedMessage }
        \cup { [tag |-> StreamCompleteMessageCode, body |-> one] : one \in CheckedStreamCompleteMessage }
        \cup { [tag |-> SequencedMessageCode, body |-> one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ messageLength : 0 .. 255,
      serverData    : ServerData ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverData.tag, 1)
        \o EncodeUIntBE(message.messageLength, 2)
        \o EncodeServerData(message.serverData)

DecodeServerPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageLength == ReadUIntBE(messageType.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET serverData == DecodeServerData(messageType.value, messageLength.rest) IN IF ~serverData.ok THEN Fail ELSE
    Ok([ messageLength |-> messageLength.value,
         serverData    |-> serverData.value ], serverData.rest)

ZeroServerPacket ==
    [ messageLength |-> 0,
      serverData    |-> ZeroServerData ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroServerPacket EXCEPT !.serverData = one] : one \in CheckedServerData }

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

(* Every Login Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedMessage ==
    \A message \in CheckedLoginAcceptedMessage :
        LET read == DecodeLoginAcceptedMessage(EncodeLoginAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedMessage ==
    \A message \in CheckedLoginRejectedMessage :
        LET read == DecodeLoginRejectedMessage(EncodeLoginRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfSessionMessage ==
    \A message \in CheckedStartOfSessionMessage :
        LET read == DecodeStartOfSessionMessage(EncodeStartOfSessionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayBeginMessage ==
    \A message \in CheckedReplayBeginMessage :
        LET read == DecodeReplayBeginMessage(EncodeReplayBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRejectedMessage ==
    \A message \in CheckedReplayRejectedMessage :
        LET read == DecodeReplayRejectedMessage(EncodeReplayRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayCompleteMessage ==
    \A message \in CheckedReplayCompleteMessage :
        LET read == DecodeReplayCompleteMessage(EncodeReplayCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamBeginMessage ==
    \A message \in CheckedStreamBeginMessage :
        LET read == DecodeStreamBeginMessage(EncodeStreamBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamRejectedMessage ==
    \A message \in CheckedStreamRejectedMessage :
        LET read == DecodeStreamRejectedMessage(EncodeStreamRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamCompleteMessage ==
    \A message \in CheckedStreamCompleteMessage :
        LET read == DecodeStreamCompleteMessage(EncodeStreamCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup ==
    \A message \in CheckedPartiesGroup :
        LET read == DecodePartiesGroup(EncodePartiesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups ==
    \A message \in CheckedPartiesGroups :
        LET read == DecodePartiesGroups(EncodePartiesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportNewMessage ==
    \A message \in CheckedExecutionReportNewMessage :
        LET read == DecodeExecutionReportNewMessage(EncodeExecutionReportNewMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup2 ==
    \A message \in CheckedPartiesGroup2 :
        LET read == DecodePartiesGroup2(EncodePartiesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups2 ==
    \A message \in CheckedPartiesGroups2 :
        LET read == DecodePartiesGroups2(EncodePartiesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Bulk Quote Pending New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportBulkQuotePendingNewMessage ==
    \A message \in CheckedExecutionReportBulkQuotePendingNewMessage :
        LET read == DecodeExecutionReportBulkQuotePendingNewMessage(EncodeExecutionReportBulkQuotePendingNewMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Bulk Quote Component New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportBulkQuoteComponentNewMessage ==
    \A message \in CheckedExecutionReportBulkQuoteComponentNewMessage :
        LET read == DecodeExecutionReportBulkQuoteComponentNewMessage(EncodeExecutionReportBulkQuoteComponentNewMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportRejectedMessage ==
    \A message \in CheckedExecutionReportRejectedMessage :
        LET read == DecodeExecutionReportRejectedMessage(EncodeExecutionReportRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup3 ==
    \A message \in CheckedPartiesGroup3 :
        LET read == DecodePartiesGroup3(EncodePartiesGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups3 ==
    \A message \in CheckedPartiesGroups3 :
        LET read == DecodePartiesGroups3(EncodePartiesGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeMessage ==
    \A message \in CheckedExecutionReportTradeMessage :
        LET read == DecodeExecutionReportTradeMessage(EncodeExecutionReportTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Pending Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportPendingCancelMessage ==
    \A message \in CheckedExecutionReportPendingCancelMessage :
        LET read == DecodeExecutionReportPendingCancelMessage(EncodeExecutionReportPendingCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportCanceledMessage ==
    \A message \in CheckedExecutionReportCanceledMessage :
        LET read == DecodeExecutionReportCanceledMessage(EncodeExecutionReportCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Pending Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportPendingReplaceMessage ==
    \A message \in CheckedExecutionReportPendingReplaceMessage :
        LET read == DecodeExecutionReportPendingReplaceMessage(EncodeExecutionReportPendingReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportReplacedMessage ==
    \A message \in CheckedExecutionReportReplacedMessage :
        LET read == DecodeExecutionReportReplacedMessage(EncodeExecutionReportReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeCorrectionMessage ==
    \A message \in CheckedExecutionReportTradeCorrectionMessage :
        LET read == DecodeExecutionReportTradeCorrectionMessage(EncodeExecutionReportTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeBreakMessage ==
    \A message \in CheckedExecutionReportTradeBreakMessage :
        LET read == DecodeExecutionReportTradeBreakMessage(EncodeExecutionReportTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportRestatementMessage ==
    \A message \in CheckedExecutionReportRestatementMessage :
        LET read == DecodeExecutionReportRestatementMessage(EncodeExecutionReportRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pending Mass Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPendingMassCancelMessage ==
    \A message \in CheckedPendingMassCancelMessage :
        LET read == DecodePendingMassCancelMessage(EncodePendingMassCancelMessage(message))
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

(* Every Mass Cancel Done Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelDoneMessage ==
    \A message \in CheckedMassCancelDoneMessage :
        LET read == DecodeMassCancelDoneMessage(EncodeMassCancelDoneMessage(message))
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

(* Every Allocation Instruction Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationInstructionAckMessage ==
    \A message \in CheckedAllocationInstructionAckMessage :
        LET read == DecodeAllocationInstructionAckMessage(EncodeAllocationInstructionAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Report Message Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationReportMessagePartiesGroup ==
    \A message \in CheckedAllocationReportMessagePartiesGroup :
        LET read == DecodeAllocationReportMessagePartiesGroup(EncodeAllocationReportMessagePartiesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Report Message Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationReportMessagePartiesGroups ==
    \A message \in CheckedAllocationReportMessagePartiesGroups :
        LET read == DecodeAllocationReportMessagePartiesGroups(EncodeAllocationReportMessagePartiesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Report Message Allocations Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationReportMessageAllocationsGroup ==
    \A message \in CheckedAllocationReportMessageAllocationsGroup :
        LET read == DecodeAllocationReportMessageAllocationsGroup(EncodeAllocationReportMessageAllocationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Report Message Allocations Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationReportMessageAllocationsGroups ==
    \A message \in CheckedAllocationReportMessageAllocationsGroups :
        LET read == DecodeAllocationReportMessageAllocationsGroups(EncodeAllocationReportMessageAllocationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationReportMessage ==
    \A message \in CheckedAllocationReportMessage :
        LET read == DecodeAllocationReportMessage(EncodeAllocationReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserNotificationMessage ==
    \A message \in CheckedUserNotificationMessage :
        LET read == DecodeUserNotificationMessage(EncodeUserNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Clear Lockout Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelClearLockoutRejectMessage ==
    \A message \in CheckedMassCancelClearLockoutRejectMessage :
        LET read == DecodeMassCancelClearLockoutRejectMessage(EncodeMassCancelClearLockoutRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Clear Lockout Done Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelClearLockoutDoneMessage ==
    \A message \in CheckedMassCancelClearLockoutDoneMessage :
        LET read == DecodeMassCancelClearLockoutDoneMessage(EncodeMassCancelClearLockoutDoneMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSbeMessage ==
    \A message \in CheckedServerSbeMessage :
        LET read == DecodeServerSbeMessage(EncodeServerSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(EncodeSequencedMessage(message))
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
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Data is selected by the Message Type it is written under *)
SelectsServerData ==
    \A message \in CheckedServerData :
        LET read == DecodeServerData(message.tag, EncodeServerData(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
