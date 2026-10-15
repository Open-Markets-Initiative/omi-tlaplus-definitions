------------------ MODULE BlueEquities_Memo_v1_14_Server -------------------
(***************************************************************************)
(* Blue Ocean Technologies Members Orders v1.14                            *)
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
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup ==
    { ZeroPartiesGroup }
        \cup { [ZeroPartiesGroup EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
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
(* Execution Report Pending New Message                                    *)
(***************************************************************************)

ExecutionReportPendingNewMessage ==
    [ sendingTime            : Sample(8),
      orderId                : Sample(8),
      clordid                : Sample(16),
      execId                 : Sample(8),
      ordStatus              : Sample(1),
      symbol                 : Sample(6),
      symbolSfx              : Sample(6),
      side                   : Sample(1),
      ordType                : Sample(1),
      orderQty               : Sample(4),
      price                  : Sample(8),
      timeInForce            : Sample(1),
      orderCapacity          : Sample(1),
      custOrderCapacity      : Sample(1),
      execInst               : Sample(2),
      pegOffsetValue         : Sample(8),
      pegPriceType           : Sample(1),
      expireTime             : Sample(8),
      minQty                 : Sample(4),
      displayQty             : Sample(4),
      displayMethod          : Sample(1),
      reserveReplenishTiming : Sample(1),
      displayMinIncr         : Sample(4),
      locateReqd             : Sample(1),
      repriceFrequency       : Sample(1),
      repriceBehavior        : Sample(1),
      cancelGroupId          : Sample(2),
      stpGroupId             : Sample(2),
      selfTradePrevention    : Sample(1),
      riskGroupId            : Sample(2),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      linkIdOptional         : Sample(4),
      locateBrokerOptional   : Sample(4),
      partiesGroups          : PartiesGroups ]

EncodeExecutionReportPendingNewMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.execId
        \o message.ordStatus
        \o message.symbol
        \o message.symbolSfx
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.timeInForce
        \o message.orderCapacity
        \o message.custOrderCapacity
        \o message.execInst
        \o message.pegOffsetValue
        \o message.pegPriceType
        \o message.expireTime
        \o message.minQty
        \o message.displayQty
        \o message.displayMethod
        \o message.reserveReplenishTiming
        \o message.displayMinIncr
        \o message.locateReqd
        \o message.repriceFrequency
        \o message.repriceBehavior
        \o message.cancelGroupId
        \o message.stpGroupId
        \o message.selfTradePrevention
        \o message.riskGroupId
        \o message.leavesQty
        \o message.cumQty
        \o message.linkIdOptional
        \o message.locateBrokerOptional
        \o EncodePartiesGroups(message.partiesGroups)

DecodeExecutionReportPendingNewMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET symbol == ReadBytes(ordStatus.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSfx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET custOrderCapacity == ReadBytes(orderCapacity.rest, 1) IN IF ~custOrderCapacity.ok THEN Fail ELSE
    LET execInst == ReadBytes(custOrderCapacity.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET pegOffsetValue == ReadBytes(execInst.rest, 8) IN IF ~pegOffsetValue.ok THEN Fail ELSE
    LET pegPriceType == ReadBytes(pegOffsetValue.rest, 1) IN IF ~pegPriceType.ok THEN Fail ELSE
    LET expireTime == ReadBytes(pegPriceType.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET minQty == ReadBytes(expireTime.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayMethod == ReadBytes(displayQty.rest, 1) IN IF ~displayMethod.ok THEN Fail ELSE
    LET reserveReplenishTiming == ReadBytes(displayMethod.rest, 1) IN IF ~reserveReplenishTiming.ok THEN Fail ELSE
    LET displayMinIncr == ReadBytes(reserveReplenishTiming.rest, 4) IN IF ~displayMinIncr.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(displayMinIncr.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET repriceFrequency == ReadBytes(locateReqd.rest, 1) IN IF ~repriceFrequency.ok THEN Fail ELSE
    LET repriceBehavior == ReadBytes(repriceFrequency.rest, 1) IN IF ~repriceBehavior.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(repriceBehavior.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET stpGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~stpGroupId.ok THEN Fail ELSE
    LET selfTradePrevention == ReadBytes(stpGroupId.rest, 1) IN IF ~selfTradePrevention.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(selfTradePrevention.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(riskGroupId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(cumQty.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET locateBrokerOptional == ReadBytes(linkIdOptional.rest, 4) IN IF ~locateBrokerOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups(locateBrokerOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime            |-> sendingTime.value,
         orderId                |-> orderId.value,
         clordid                |-> clordid.value,
         execId                 |-> execId.value,
         ordStatus              |-> ordStatus.value,
         symbol                 |-> symbol.value,
         symbolSfx              |-> symbolSfx.value,
         side                   |-> side.value,
         ordType                |-> ordType.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         timeInForce            |-> timeInForce.value,
         orderCapacity          |-> orderCapacity.value,
         custOrderCapacity      |-> custOrderCapacity.value,
         execInst               |-> execInst.value,
         pegOffsetValue         |-> pegOffsetValue.value,
         pegPriceType           |-> pegPriceType.value,
         expireTime             |-> expireTime.value,
         minQty                 |-> minQty.value,
         displayQty             |-> displayQty.value,
         displayMethod          |-> displayMethod.value,
         reserveReplenishTiming |-> reserveReplenishTiming.value,
         displayMinIncr         |-> displayMinIncr.value,
         locateReqd             |-> locateReqd.value,
         repriceFrequency       |-> repriceFrequency.value,
         repriceBehavior        |-> repriceBehavior.value,
         cancelGroupId          |-> cancelGroupId.value,
         stpGroupId             |-> stpGroupId.value,
         selfTradePrevention    |-> selfTradePrevention.value,
         riskGroupId            |-> riskGroupId.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         linkIdOptional         |-> linkIdOptional.value,
         locateBrokerOptional   |-> locateBrokerOptional.value,
         partiesGroups          |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportPendingNewMessage ==
    [ sendingTime            |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clordid                |-> [i \in 1 .. 16 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      symbolSfx              |-> [i \in 1 .. 6 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      orderCapacity          |-> [i \in 1 .. 1 |-> 0],
      custOrderCapacity      |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 2 |-> 0],
      pegOffsetValue         |-> [i \in 1 .. 8 |-> 0],
      pegPriceType           |-> [i \in 1 .. 1 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      minQty                 |-> [i \in 1 .. 4 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      displayMethod          |-> [i \in 1 .. 1 |-> 0],
      reserveReplenishTiming |-> [i \in 1 .. 1 |-> 0],
      displayMinIncr         |-> [i \in 1 .. 4 |-> 0],
      locateReqd             |-> [i \in 1 .. 1 |-> 0],
      repriceFrequency       |-> [i \in 1 .. 1 |-> 0],
      repriceBehavior        |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId          |-> [i \in 1 .. 2 |-> 0],
      stpGroupId             |-> [i \in 1 .. 2 |-> 0],
      selfTradePrevention    |-> [i \in 1 .. 1 |-> 0],
      riskGroupId            |-> [i \in 1 .. 2 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      linkIdOptional         |-> [i \in 1 .. 4 |-> 0],
      locateBrokerOptional   |-> [i \in 1 .. 4 |-> 0],
      partiesGroups          |-> ZeroPartiesGroups ]

(* Execution Report Pending New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingNewMessage ==
    { ZeroExecutionReportPendingNewMessage }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.custOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.pegOffsetValue = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.pegPriceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.displayMethod = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.reserveReplenishTiming = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.displayMinIncr = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.repriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.repriceBehavior = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.stpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.selfTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.locateBrokerOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingNewMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup2 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup2(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup2(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup2 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup2 ==
    { ZeroPartiesGroup2 }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
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
(* Execution Report New Message                                            *)
(***************************************************************************)

ExecutionReportNewMessage ==
    [ sendingTime            : Sample(8),
      orderId                : Sample(8),
      clordid                : Sample(16),
      execId                 : Sample(8),
      ordStatus              : Sample(1),
      symbol                 : Sample(6),
      symbolSfx              : Sample(6),
      side                   : Sample(1),
      ordType                : Sample(1),
      orderQty               : Sample(4),
      price                  : Sample(8),
      timeInForce            : Sample(1),
      orderCapacity          : Sample(1),
      custOrderCapacity      : Sample(1),
      execInst               : Sample(2),
      pegOffsetValue         : Sample(8),
      pegPriceType           : Sample(1),
      expireTime             : Sample(8),
      minQty                 : Sample(4),
      displayQty             : Sample(4),
      displayMethod          : Sample(1),
      reserveReplenishTiming : Sample(1),
      displayMinIncr         : Sample(4),
      locateReqd             : Sample(1),
      repriceFrequency       : Sample(1),
      repriceBehavior        : Sample(1),
      cancelGroupId          : Sample(2),
      stpGroupId             : Sample(2),
      selfTradePrevention    : Sample(1),
      riskGroupId            : Sample(2),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      transactTime           : Sample(8),
      linkIdOptional         : Sample(4),
      locateBrokerOptional   : Sample(4),
      partiesGroups          : PartiesGroups2 ]

EncodeExecutionReportNewMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.execId
        \o message.ordStatus
        \o message.symbol
        \o message.symbolSfx
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.timeInForce
        \o message.orderCapacity
        \o message.custOrderCapacity
        \o message.execInst
        \o message.pegOffsetValue
        \o message.pegPriceType
        \o message.expireTime
        \o message.minQty
        \o message.displayQty
        \o message.displayMethod
        \o message.reserveReplenishTiming
        \o message.displayMinIncr
        \o message.locateReqd
        \o message.repriceFrequency
        \o message.repriceBehavior
        \o message.cancelGroupId
        \o message.stpGroupId
        \o message.selfTradePrevention
        \o message.riskGroupId
        \o message.leavesQty
        \o message.cumQty
        \o message.transactTime
        \o message.linkIdOptional
        \o message.locateBrokerOptional
        \o EncodePartiesGroups2(message.partiesGroups)

DecodeExecutionReportNewMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET symbol == ReadBytes(ordStatus.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSfx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET custOrderCapacity == ReadBytes(orderCapacity.rest, 1) IN IF ~custOrderCapacity.ok THEN Fail ELSE
    LET execInst == ReadBytes(custOrderCapacity.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET pegOffsetValue == ReadBytes(execInst.rest, 8) IN IF ~pegOffsetValue.ok THEN Fail ELSE
    LET pegPriceType == ReadBytes(pegOffsetValue.rest, 1) IN IF ~pegPriceType.ok THEN Fail ELSE
    LET expireTime == ReadBytes(pegPriceType.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET minQty == ReadBytes(expireTime.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayMethod == ReadBytes(displayQty.rest, 1) IN IF ~displayMethod.ok THEN Fail ELSE
    LET reserveReplenishTiming == ReadBytes(displayMethod.rest, 1) IN IF ~reserveReplenishTiming.ok THEN Fail ELSE
    LET displayMinIncr == ReadBytes(reserveReplenishTiming.rest, 4) IN IF ~displayMinIncr.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(displayMinIncr.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET repriceFrequency == ReadBytes(locateReqd.rest, 1) IN IF ~repriceFrequency.ok THEN Fail ELSE
    LET repriceBehavior == ReadBytes(repriceFrequency.rest, 1) IN IF ~repriceBehavior.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(repriceBehavior.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET stpGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~stpGroupId.ok THEN Fail ELSE
    LET selfTradePrevention == ReadBytes(stpGroupId.rest, 1) IN IF ~selfTradePrevention.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(selfTradePrevention.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(riskGroupId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET transactTime == ReadBytes(cumQty.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET locateBrokerOptional == ReadBytes(linkIdOptional.rest, 4) IN IF ~locateBrokerOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups2(locateBrokerOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime            |-> sendingTime.value,
         orderId                |-> orderId.value,
         clordid                |-> clordid.value,
         execId                 |-> execId.value,
         ordStatus              |-> ordStatus.value,
         symbol                 |-> symbol.value,
         symbolSfx              |-> symbolSfx.value,
         side                   |-> side.value,
         ordType                |-> ordType.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         timeInForce            |-> timeInForce.value,
         orderCapacity          |-> orderCapacity.value,
         custOrderCapacity      |-> custOrderCapacity.value,
         execInst               |-> execInst.value,
         pegOffsetValue         |-> pegOffsetValue.value,
         pegPriceType           |-> pegPriceType.value,
         expireTime             |-> expireTime.value,
         minQty                 |-> minQty.value,
         displayQty             |-> displayQty.value,
         displayMethod          |-> displayMethod.value,
         reserveReplenishTiming |-> reserveReplenishTiming.value,
         displayMinIncr         |-> displayMinIncr.value,
         locateReqd             |-> locateReqd.value,
         repriceFrequency       |-> repriceFrequency.value,
         repriceBehavior        |-> repriceBehavior.value,
         cancelGroupId          |-> cancelGroupId.value,
         stpGroupId             |-> stpGroupId.value,
         selfTradePrevention    |-> selfTradePrevention.value,
         riskGroupId            |-> riskGroupId.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         transactTime           |-> transactTime.value,
         linkIdOptional         |-> linkIdOptional.value,
         locateBrokerOptional   |-> locateBrokerOptional.value,
         partiesGroups          |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportNewMessage ==
    [ sendingTime            |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clordid                |-> [i \in 1 .. 16 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      symbolSfx              |-> [i \in 1 .. 6 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      orderCapacity          |-> [i \in 1 .. 1 |-> 0],
      custOrderCapacity      |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 2 |-> 0],
      pegOffsetValue         |-> [i \in 1 .. 8 |-> 0],
      pegPriceType           |-> [i \in 1 .. 1 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      minQty                 |-> [i \in 1 .. 4 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      displayMethod          |-> [i \in 1 .. 1 |-> 0],
      reserveReplenishTiming |-> [i \in 1 .. 1 |-> 0],
      displayMinIncr         |-> [i \in 1 .. 4 |-> 0],
      locateReqd             |-> [i \in 1 .. 1 |-> 0],
      repriceFrequency       |-> [i \in 1 .. 1 |-> 0],
      repriceBehavior        |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId          |-> [i \in 1 .. 2 |-> 0],
      stpGroupId             |-> [i \in 1 .. 2 |-> 0],
      selfTradePrevention    |-> [i \in 1 .. 1 |-> 0],
      riskGroupId            |-> [i \in 1 .. 2 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      linkIdOptional         |-> [i \in 1 .. 4 |-> 0],
      locateBrokerOptional   |-> [i \in 1 .. 4 |-> 0],
      partiesGroups          |-> ZeroPartiesGroups2 ]

(* Execution Report New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportNewMessage ==
    { ZeroExecutionReportNewMessage }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.custOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.pegOffsetValue = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.pegPriceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.displayMethod = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.reserveReplenishTiming = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.displayMinIncr = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.repriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.repriceBehavior = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.stpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.selfTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.locateBrokerOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups2 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup3 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup3(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup3(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup3 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup3 ==
    { ZeroPartiesGroup3 }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
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
(* Execution Report Rejected Message                                       *)
(***************************************************************************)

ExecutionReportRejectedMessage ==
    [ sendingTime       : Sample(8),
      clordid           : Sample(16),
      execId            : Sample(8),
      ordStatus         : Sample(1),
      symbol            : Sample(6),
      symbolSfx         : Sample(6),
      leavesQty         : Sample(4),
      cumQty            : Sample(4),
      orderRejectReason : Sample(1),
      linkIdOptional    : Sample(4),
      partiesGroups     : PartiesGroups3 ]

EncodeExecutionReportRejectedMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.execId
        \o message.ordStatus
        \o message.symbol
        \o message.symbolSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.orderRejectReason
        \o message.linkIdOptional
        \o EncodePartiesGroups3(message.partiesGroups)

DecodeExecutionReportRejectedMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET symbol == ReadBytes(ordStatus.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(symbolSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(cumQty.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(orderRejectReason.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups3(linkIdOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime       |-> sendingTime.value,
         clordid           |-> clordid.value,
         execId            |-> execId.value,
         ordStatus         |-> ordStatus.value,
         symbol            |-> symbol.value,
         symbolSfx         |-> symbolSfx.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         orderRejectReason |-> orderRejectReason.value,
         linkIdOptional    |-> linkIdOptional.value,
         partiesGroups     |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportRejectedMessage ==
    [ sendingTime       |-> [i \in 1 .. 8 |-> 0],
      clordid           |-> [i \in 1 .. 16 |-> 0],
      execId            |-> [i \in 1 .. 8 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      symbol            |-> [i \in 1 .. 6 |-> 0],
      symbolSfx         |-> [i \in 1 .. 6 |-> 0],
      leavesQty         |-> [i \in 1 .. 4 |-> 0],
      cumQty            |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      linkIdOptional    |-> [i \in 1 .. 4 |-> 0],
      partiesGroups     |-> ZeroPartiesGroups3 ]

(* Execution Report Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportRejectedMessage ==
    { ZeroExecutionReportRejectedMessage }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectedMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups3 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup4 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup4(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup4(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup4 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup4 ==
    { ZeroPartiesGroup4 }
        \cup { [ZeroPartiesGroup4 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup4 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup4 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup4List(_)
EncodePartiesGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup4(Head(messages)) \o EncodePartiesGroup4List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup4List(_, _)
ReadPartiesGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup4 == { ZeroPartiesGroup4 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups4 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup4) ]

EncodePartiesGroups4(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup4List(message.partiesGroup)

DecodePartiesGroups4(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup4List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups4 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups4 ==
    { ZeroPartiesGroups4 }
        \cup { [ZeroPartiesGroups4 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups4 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup4) }

(***************************************************************************)
(* Execution Report Trade Message                                          *)
(***************************************************************************)

ExecutionReportTradeMessage ==
    [ sendingTime      : Sample(8),
      orderId          : Sample(8),
      clordid          : Sample(16),
      execId           : Sample(8),
      ordStatus        : Sample(1),
      lastQty          : Sample(4),
      lastPx           : Sample(8),
      leavesQty        : Sample(4),
      cumQty           : Sample(4),
      transactTime     : Sample(8),
      lastLiquidityInd : Sample(1),
      lastMkt          : Sample(4),
      trdMatchingId    : Sample(8),
      linkIdOptional   : Sample(4),
      securityGroup    : Sample(1),
      partiesGroups    : PartiesGroups4 ]

EncodeExecutionReportTradeMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.execId
        \o message.ordStatus
        \o message.lastQty
        \o message.lastPx
        \o message.leavesQty
        \o message.cumQty
        \o message.transactTime
        \o message.lastLiquidityInd
        \o message.lastMkt
        \o message.trdMatchingId
        \o message.linkIdOptional
        \o message.securityGroup
        \o EncodePartiesGroups4(message.partiesGroups)

DecodeExecutionReportTradeMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET lastQty == ReadBytes(ordStatus.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET transactTime == ReadBytes(cumQty.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastLiquidityInd == ReadBytes(transactTime.rest, 1) IN IF ~lastLiquidityInd.ok THEN Fail ELSE
    LET lastMkt == ReadBytes(lastLiquidityInd.rest, 4) IN IF ~lastMkt.ok THEN Fail ELSE
    LET trdMatchingId == ReadBytes(lastMkt.rest, 8) IN IF ~trdMatchingId.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(trdMatchingId.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(linkIdOptional.rest, 1) IN IF ~securityGroup.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups4(securityGroup.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime      |-> sendingTime.value,
         orderId          |-> orderId.value,
         clordid          |-> clordid.value,
         execId           |-> execId.value,
         ordStatus        |-> ordStatus.value,
         lastQty          |-> lastQty.value,
         lastPx           |-> lastPx.value,
         leavesQty        |-> leavesQty.value,
         cumQty           |-> cumQty.value,
         transactTime     |-> transactTime.value,
         lastLiquidityInd |-> lastLiquidityInd.value,
         lastMkt          |-> lastMkt.value,
         trdMatchingId    |-> trdMatchingId.value,
         linkIdOptional   |-> linkIdOptional.value,
         securityGroup    |-> securityGroup.value,
         partiesGroups    |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportTradeMessage ==
    [ sendingTime      |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      clordid          |-> [i \in 1 .. 16 |-> 0],
      execId           |-> [i \in 1 .. 8 |-> 0],
      ordStatus        |-> [i \in 1 .. 1 |-> 0],
      lastQty          |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      leavesQty        |-> [i \in 1 .. 4 |-> 0],
      cumQty           |-> [i \in 1 .. 4 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      lastLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      lastMkt          |-> [i \in 1 .. 4 |-> 0],
      trdMatchingId    |-> [i \in 1 .. 8 |-> 0],
      linkIdOptional   |-> [i \in 1 .. 4 |-> 0],
      securityGroup    |-> [i \in 1 .. 1 |-> 0],
      partiesGroups    |-> ZeroPartiesGroups4 ]

(* Execution Report Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeMessage ==
    { ZeroExecutionReportTradeMessage }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastMkt = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.trdMatchingId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.securityGroup = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups4 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup5 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup5(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup5(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup5 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup5 ==
    { ZeroPartiesGroup5 }
        \cup { [ZeroPartiesGroup5 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup5 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup5 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup5List(_)
EncodePartiesGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup5(Head(messages)) \o EncodePartiesGroup5List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup5List(_, _)
ReadPartiesGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup5 == { ZeroPartiesGroup5 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups5 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup5) ]

EncodePartiesGroups5(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup5List(message.partiesGroup)

DecodePartiesGroups5(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup5List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups5 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups5 ==
    { ZeroPartiesGroups5 }
        \cup { [ZeroPartiesGroups5 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups5 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup5) }

(***************************************************************************)
(* Execution Report Pending Cancel Message                                 *)
(***************************************************************************)

ExecutionReportPendingCancelMessage ==
    [ sendingTime         : Sample(8),
      orderId             : Sample(8),
      clordid             : Sample(16),
      origclordidOptional : Sample(16),
      execId              : Sample(8),
      symbol              : Sample(6),
      symbolSfx           : Sample(6),
      ordStatus           : Sample(1),
      leavesQty           : Sample(4),
      cumQty              : Sample(4),
      linkIdOptional      : Sample(4),
      partiesGroups       : PartiesGroups5 ]

EncodeExecutionReportPendingCancelMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.origclordidOptional
        \o message.execId
        \o message.symbol
        \o message.symbolSfx
        \o message.ordStatus
        \o message.leavesQty
        \o message.cumQty
        \o message.linkIdOptional
        \o EncodePartiesGroups5(message.partiesGroups)

DecodeExecutionReportPendingCancelMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET origclordidOptional == ReadBytes(clordid.rest, 16) IN IF ~origclordidOptional.ok THEN Fail ELSE
    LET execId == ReadBytes(origclordidOptional.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbol == ReadBytes(execId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(symbolSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordStatus.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(cumQty.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups5(linkIdOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime         |-> sendingTime.value,
         orderId             |-> orderId.value,
         clordid             |-> clordid.value,
         origclordidOptional |-> origclordidOptional.value,
         execId              |-> execId.value,
         symbol              |-> symbol.value,
         symbolSfx           |-> symbolSfx.value,
         ordStatus           |-> ordStatus.value,
         leavesQty           |-> leavesQty.value,
         cumQty              |-> cumQty.value,
         linkIdOptional      |-> linkIdOptional.value,
         partiesGroups       |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportPendingCancelMessage ==
    [ sendingTime         |-> [i \in 1 .. 8 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      clordid             |-> [i \in 1 .. 16 |-> 0],
      origclordidOptional |-> [i \in 1 .. 16 |-> 0],
      execId              |-> [i \in 1 .. 8 |-> 0],
      symbol              |-> [i \in 1 .. 6 |-> 0],
      symbolSfx           |-> [i \in 1 .. 6 |-> 0],
      ordStatus           |-> [i \in 1 .. 1 |-> 0],
      leavesQty           |-> [i \in 1 .. 4 |-> 0],
      cumQty              |-> [i \in 1 .. 4 |-> 0],
      linkIdOptional      |-> [i \in 1 .. 4 |-> 0],
      partiesGroups       |-> ZeroPartiesGroups5 ]

(* Execution Report Pending Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingCancelMessage ==
    { ZeroExecutionReportPendingCancelMessage }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.origclordidOptional = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancelMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups5 }

(***************************************************************************)
(* Pending Mass Cancel Message: 55 bytes                                   *)
(***************************************************************************)

PendingMassCancelMessage ==
    [ sendingTime     : Sample(8),
      clordid         : Sample(16),
      symbol          : Sample(6),
      symbolSfx       : Sample(6),
      sideOptional    : Sample(1),
      lowerThanPrice  : Sample(8),
      higherThanPrice : Sample(8),
      cancelGroupId   : Sample(2) ]

EncodePendingMassCancelMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.symbol
        \o message.symbolSfx
        \o message.sideOptional
        \o message.lowerThanPrice
        \o message.higherThanPrice
        \o message.cancelGroupId

DecodePendingMassCancelMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET symbol == ReadBytes(clordid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(symbolSfx.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET lowerThanPrice == ReadBytes(sideOptional.rest, 8) IN IF ~lowerThanPrice.ok THEN Fail ELSE
    LET higherThanPrice == ReadBytes(lowerThanPrice.rest, 8) IN IF ~higherThanPrice.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(higherThanPrice.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    Ok([ sendingTime     |-> sendingTime.value,
         clordid         |-> clordid.value,
         symbol          |-> symbol.value,
         symbolSfx       |-> symbolSfx.value,
         sideOptional    |-> sideOptional.value,
         lowerThanPrice  |-> lowerThanPrice.value,
         higherThanPrice |-> higherThanPrice.value,
         cancelGroupId   |-> cancelGroupId.value ], cancelGroupId.rest)

ZeroPendingMassCancelMessage ==
    [ sendingTime     |-> [i \in 1 .. 8 |-> 0],
      clordid         |-> [i \in 1 .. 16 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      symbolSfx       |-> [i \in 1 .. 6 |-> 0],
      sideOptional    |-> [i \in 1 .. 1 |-> 0],
      lowerThanPrice  |-> [i \in 1 .. 8 |-> 0],
      higherThanPrice |-> [i \in 1 .. 8 |-> 0],
      cancelGroupId   |-> [i \in 1 .. 2 |-> 0] ]

(* Pending Mass Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedPendingMassCancelMessage ==
    { ZeroPendingMassCancelMessage }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.lowerThanPrice = one] : one \in Sample(8) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.higherThanPrice = one] : one \in Sample(8) }
        \cup { [ZeroPendingMassCancelMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup6 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup6(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup6(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup6 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup6 ==
    { ZeroPartiesGroup6 }
        \cup { [ZeroPartiesGroup6 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup6 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup6 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup6List(_)
EncodePartiesGroup6List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup6(Head(messages)) \o EncodePartiesGroup6List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup6List(_, _)
ReadPartiesGroup6List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup6(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup6List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup6 == { ZeroPartiesGroup6 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups6 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup6) ]

EncodePartiesGroups6(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup6List(message.partiesGroup)

DecodePartiesGroups6(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup6List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups6 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups6 ==
    { ZeroPartiesGroups6 }
        \cup { [ZeroPartiesGroups6 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups6 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup6) }

(***************************************************************************)
(* Execution Report Canceled Message                                       *)
(***************************************************************************)

ExecutionReportCanceledMessage ==
    [ sendingTime         : Sample(8),
      clordid             : Sample(16),
      origclordidOptional : Sample(16),
      orderId             : Sample(8),
      execId              : Sample(8),
      ordStatus           : Sample(1),
      leavesQty           : Sample(4),
      cumQty              : Sample(4),
      cancelReason        : Sample(1),
      transactTime        : Sample(8),
      linkIdOptional      : Sample(4),
      partiesGroups       : PartiesGroups6 ]

EncodeExecutionReportCanceledMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.origclordidOptional
        \o message.orderId
        \o message.execId
        \o message.ordStatus
        \o message.leavesQty
        \o message.cumQty
        \o message.cancelReason
        \o message.transactTime
        \o message.linkIdOptional
        \o EncodePartiesGroups6(message.partiesGroups)

DecodeExecutionReportCanceledMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET origclordidOptional == ReadBytes(clordid.rest, 16) IN IF ~origclordidOptional.ok THEN Fail ELSE
    LET orderId == ReadBytes(origclordidOptional.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execId == ReadBytes(orderId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordStatus.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(cumQty.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET transactTime == ReadBytes(cancelReason.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups6(linkIdOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime         |-> sendingTime.value,
         clordid             |-> clordid.value,
         origclordidOptional |-> origclordidOptional.value,
         orderId             |-> orderId.value,
         execId              |-> execId.value,
         ordStatus           |-> ordStatus.value,
         leavesQty           |-> leavesQty.value,
         cumQty              |-> cumQty.value,
         cancelReason        |-> cancelReason.value,
         transactTime        |-> transactTime.value,
         linkIdOptional      |-> linkIdOptional.value,
         partiesGroups       |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportCanceledMessage ==
    [ sendingTime         |-> [i \in 1 .. 8 |-> 0],
      clordid             |-> [i \in 1 .. 16 |-> 0],
      origclordidOptional |-> [i \in 1 .. 16 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      execId              |-> [i \in 1 .. 8 |-> 0],
      ordStatus           |-> [i \in 1 .. 1 |-> 0],
      leavesQty           |-> [i \in 1 .. 4 |-> 0],
      cumQty              |-> [i \in 1 .. 4 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      transactTime        |-> [i \in 1 .. 8 |-> 0],
      linkIdOptional      |-> [i \in 1 .. 4 |-> 0],
      partiesGroups       |-> ZeroPartiesGroups6 ]

(* Execution Report Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportCanceledMessage ==
    { ZeroExecutionReportCanceledMessage }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.origclordidOptional = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCanceledMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups6 }

(***************************************************************************)
(* Mass Cancel Done Message: 24 bytes                                      *)
(***************************************************************************)

MassCancelDoneMessage ==
    [ sendingTime : Sample(8),
      clordid     : Sample(16) ]

EncodeMassCancelDoneMessage(message) ==
    message.sendingTime
        \o message.clordid

DecodeMassCancelDoneMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value,
         clordid     |-> clordid.value ], clordid.rest)

ZeroMassCancelDoneMessage ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0],
      clordid     |-> [i \in 1 .. 16 |-> 0] ]

(* Mass Cancel Done Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelDoneMessage ==
    { ZeroMassCancelDoneMessage }
        \cup { [ZeroMassCancelDoneMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelDoneMessage EXCEPT !.clordid = one] : one \in Sample(16) }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup7 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup7(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup7(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup7 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup7 ==
    { ZeroPartiesGroup7 }
        \cup { [ZeroPartiesGroup7 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup7 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup7 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup7List(_)
EncodePartiesGroup7List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup7(Head(messages)) \o EncodePartiesGroup7List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup7List(_, _)
ReadPartiesGroup7List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup7(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup7List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup7 == { ZeroPartiesGroup7 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups7 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup7) ]

EncodePartiesGroups7(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup7List(message.partiesGroup)

DecodePartiesGroups7(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup7List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups7 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups7 ==
    { ZeroPartiesGroups7 }
        \cup { [ZeroPartiesGroups7 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups7 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup7) }

(***************************************************************************)
(* Execution Report Pending Replace Message                                *)
(***************************************************************************)

ExecutionReportPendingReplaceMessage ==
    [ sendingTime          : Sample(8),
      orderId              : Sample(8),
      clordid              : Sample(16),
      origclordidOptional  : Sample(16),
      execId               : Sample(8),
      symbol               : Sample(6),
      symbolSfx            : Sample(6),
      side                 : Sample(1),
      orderQty             : Sample(4),
      ordType              : Sample(1),
      price                : Sample(8),
      displayQty           : Sample(4),
      locateReqd           : Sample(1),
      ordStatus            : Sample(1),
      leavesQty            : Sample(4),
      cumQty               : Sample(4),
      linkIdOptional       : Sample(4),
      locateBrokerOptional : Sample(4),
      partiesGroups        : PartiesGroups7 ]

EncodeExecutionReportPendingReplaceMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.origclordidOptional
        \o message.execId
        \o message.symbol
        \o message.symbolSfx
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.displayQty
        \o message.locateReqd
        \o message.ordStatus
        \o message.leavesQty
        \o message.cumQty
        \o message.linkIdOptional
        \o message.locateBrokerOptional
        \o EncodePartiesGroups7(message.partiesGroups)

DecodeExecutionReportPendingReplaceMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET origclordidOptional == ReadBytes(clordid.rest, 16) IN IF ~origclordidOptional.ok THEN Fail ELSE
    LET execId == ReadBytes(origclordidOptional.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbol == ReadBytes(execId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSfx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(displayQty.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(locateReqd.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordStatus.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(cumQty.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET locateBrokerOptional == ReadBytes(linkIdOptional.rest, 4) IN IF ~locateBrokerOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups7(locateBrokerOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         orderId              |-> orderId.value,
         clordid              |-> clordid.value,
         origclordidOptional  |-> origclordidOptional.value,
         execId               |-> execId.value,
         symbol               |-> symbol.value,
         symbolSfx            |-> symbolSfx.value,
         side                 |-> side.value,
         orderQty             |-> orderQty.value,
         ordType              |-> ordType.value,
         price                |-> price.value,
         displayQty           |-> displayQty.value,
         locateReqd           |-> locateReqd.value,
         ordStatus            |-> ordStatus.value,
         leavesQty            |-> leavesQty.value,
         cumQty               |-> cumQty.value,
         linkIdOptional       |-> linkIdOptional.value,
         locateBrokerOptional |-> locateBrokerOptional.value,
         partiesGroups        |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportPendingReplaceMessage ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 16 |-> 0],
      origclordidOptional  |-> [i \in 1 .. 16 |-> 0],
      execId               |-> [i \in 1 .. 8 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      symbolSfx            |-> [i \in 1 .. 6 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 4 |-> 0],
      locateReqd           |-> [i \in 1 .. 1 |-> 0],
      ordStatus            |-> [i \in 1 .. 1 |-> 0],
      leavesQty            |-> [i \in 1 .. 4 |-> 0],
      cumQty               |-> [i \in 1 .. 4 |-> 0],
      linkIdOptional       |-> [i \in 1 .. 4 |-> 0],
      locateBrokerOptional |-> [i \in 1 .. 4 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups7 ]

(* Execution Report Pending Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingReplaceMessage ==
    { ZeroExecutionReportPendingReplaceMessage }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.origclordidOptional = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.locateBrokerOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplaceMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups7 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup8 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup8(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup8(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup8 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup8 ==
    { ZeroPartiesGroup8 }
        \cup { [ZeroPartiesGroup8 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup8 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup8 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup8List(_)
EncodePartiesGroup8List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup8(Head(messages)) \o EncodePartiesGroup8List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup8List(_, _)
ReadPartiesGroup8List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup8(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup8List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup8 == { ZeroPartiesGroup8 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups8 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup8) ]

EncodePartiesGroups8(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup8List(message.partiesGroup)

DecodePartiesGroups8(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup8List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups8 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups8 ==
    { ZeroPartiesGroups8 }
        \cup { [ZeroPartiesGroups8 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups8 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup8) }

(***************************************************************************)
(* Execution Report Replaced Message                                       *)
(***************************************************************************)

ExecutionReportReplacedMessage ==
    [ sendingTime          : Sample(8),
      orderId              : Sample(8),
      clordid              : Sample(16),
      origclordidOptional  : Sample(16),
      execId               : Sample(8),
      symbol               : Sample(6),
      symbolSfx            : Sample(6),
      side                 : Sample(1),
      orderQty             : Sample(4),
      ordType              : Sample(1),
      price                : Sample(8),
      displayQty           : Sample(4),
      locateReqd           : Sample(1),
      ordStatus            : Sample(1),
      leavesQty            : Sample(4),
      cumQty               : Sample(4),
      transactTime         : Sample(8),
      linkIdOptional       : Sample(4),
      locateBrokerOptional : Sample(4),
      partiesGroups        : PartiesGroups8 ]

EncodeExecutionReportReplacedMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.origclordidOptional
        \o message.execId
        \o message.symbol
        \o message.symbolSfx
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.displayQty
        \o message.locateReqd
        \o message.ordStatus
        \o message.leavesQty
        \o message.cumQty
        \o message.transactTime
        \o message.linkIdOptional
        \o message.locateBrokerOptional
        \o EncodePartiesGroups8(message.partiesGroups)

DecodeExecutionReportReplacedMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET origclordidOptional == ReadBytes(clordid.rest, 16) IN IF ~origclordidOptional.ok THEN Fail ELSE
    LET execId == ReadBytes(origclordidOptional.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbol == ReadBytes(execId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSfx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(displayQty.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(locateReqd.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordStatus.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET transactTime == ReadBytes(cumQty.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET locateBrokerOptional == ReadBytes(linkIdOptional.rest, 4) IN IF ~locateBrokerOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups8(locateBrokerOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         orderId              |-> orderId.value,
         clordid              |-> clordid.value,
         origclordidOptional  |-> origclordidOptional.value,
         execId               |-> execId.value,
         symbol               |-> symbol.value,
         symbolSfx            |-> symbolSfx.value,
         side                 |-> side.value,
         orderQty             |-> orderQty.value,
         ordType              |-> ordType.value,
         price                |-> price.value,
         displayQty           |-> displayQty.value,
         locateReqd           |-> locateReqd.value,
         ordStatus            |-> ordStatus.value,
         leavesQty            |-> leavesQty.value,
         cumQty               |-> cumQty.value,
         transactTime         |-> transactTime.value,
         linkIdOptional       |-> linkIdOptional.value,
         locateBrokerOptional |-> locateBrokerOptional.value,
         partiesGroups        |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportReplacedMessage ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 16 |-> 0],
      origclordidOptional  |-> [i \in 1 .. 16 |-> 0],
      execId               |-> [i \in 1 .. 8 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      symbolSfx            |-> [i \in 1 .. 6 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 4 |-> 0],
      locateReqd           |-> [i \in 1 .. 1 |-> 0],
      ordStatus            |-> [i \in 1 .. 1 |-> 0],
      leavesQty            |-> [i \in 1 .. 4 |-> 0],
      cumQty               |-> [i \in 1 .. 4 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0],
      linkIdOptional       |-> [i \in 1 .. 4 |-> 0],
      locateBrokerOptional |-> [i \in 1 .. 4 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups8 ]

(* Execution Report Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportReplacedMessage ==
    { ZeroExecutionReportReplacedMessage }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.origclordidOptional = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.locateBrokerOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReplacedMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups8 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup9 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup9(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup9(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup9 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup9 ==
    { ZeroPartiesGroup9 }
        \cup { [ZeroPartiesGroup9 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup9 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup9 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup9List(_)
EncodePartiesGroup9List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup9(Head(messages)) \o EncodePartiesGroup9List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup9List(_, _)
ReadPartiesGroup9List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup9(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup9List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup9 == { ZeroPartiesGroup9 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups9 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup9) ]

EncodePartiesGroups9(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup9List(message.partiesGroup)

DecodePartiesGroups9(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup9List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups9 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups9 ==
    { ZeroPartiesGroups9 }
        \cup { [ZeroPartiesGroups9 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups9 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup9) }

(***************************************************************************)
(* Execution Report Trade Correction Message                               *)
(***************************************************************************)

ExecutionReportTradeCorrectionMessage ==
    [ sendingTime     : Sample(8),
      orderId         : Sample(8),
      clordid         : Sample(16),
      execId          : Sample(8),
      execRefId       : Sample(8),
      trdMatchId      : Sample(8),
      ordStatus       : Sample(1),
      lastPx          : Sample(8),
      lastQtyOptional : Sample(4),
      leavesQty       : Sample(4),
      cumQty          : Sample(4),
      linkIdOptional  : Sample(4),
      securityGroup   : Sample(1),
      partiesGroups   : PartiesGroups9 ]

EncodeExecutionReportTradeCorrectionMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.execId
        \o message.execRefId
        \o message.trdMatchId
        \o message.ordStatus
        \o message.lastPx
        \o message.lastQtyOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.linkIdOptional
        \o message.securityGroup
        \o EncodePartiesGroups9(message.partiesGroups)

DecodeExecutionReportTradeCorrectionMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(execId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(execRefId.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(trdMatchId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET lastPx == ReadBytes(ordStatus.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQtyOptional == ReadBytes(lastPx.rest, 4) IN IF ~lastQtyOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastQtyOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(cumQty.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(linkIdOptional.rest, 1) IN IF ~securityGroup.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups9(securityGroup.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime     |-> sendingTime.value,
         orderId         |-> orderId.value,
         clordid         |-> clordid.value,
         execId          |-> execId.value,
         execRefId       |-> execRefId.value,
         trdMatchId      |-> trdMatchId.value,
         ordStatus       |-> ordStatus.value,
         lastPx          |-> lastPx.value,
         lastQtyOptional |-> lastQtyOptional.value,
         leavesQty       |-> leavesQty.value,
         cumQty          |-> cumQty.value,
         linkIdOptional  |-> linkIdOptional.value,
         securityGroup   |-> securityGroup.value,
         partiesGroups   |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportTradeCorrectionMessage ==
    [ sendingTime     |-> [i \in 1 .. 8 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      clordid         |-> [i \in 1 .. 16 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      execRefId       |-> [i \in 1 .. 8 |-> 0],
      trdMatchId      |-> [i \in 1 .. 8 |-> 0],
      ordStatus       |-> [i \in 1 .. 1 |-> 0],
      lastPx          |-> [i \in 1 .. 8 |-> 0],
      lastQtyOptional |-> [i \in 1 .. 4 |-> 0],
      leavesQty       |-> [i \in 1 .. 4 |-> 0],
      cumQty          |-> [i \in 1 .. 4 |-> 0],
      linkIdOptional  |-> [i \in 1 .. 4 |-> 0],
      securityGroup   |-> [i \in 1 .. 1 |-> 0],
      partiesGroups   |-> ZeroPartiesGroups9 ]

(* Execution Report Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeCorrectionMessage ==
    { ZeroExecutionReportTradeCorrectionMessage }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.lastQtyOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.securityGroup = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeCorrectionMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups9 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup10 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup10(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup10(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup10 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup10 ==
    { ZeroPartiesGroup10 }
        \cup { [ZeroPartiesGroup10 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup10 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup10 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup10List(_)
EncodePartiesGroup10List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup10(Head(messages)) \o EncodePartiesGroup10List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup10List(_, _)
ReadPartiesGroup10List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup10(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup10List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup10 == { ZeroPartiesGroup10 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups10 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup10) ]

EncodePartiesGroups10(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup10List(message.partiesGroup)

DecodePartiesGroups10(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup10List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups10 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups10 ==
    { ZeroPartiesGroups10 }
        \cup { [ZeroPartiesGroups10 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups10 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup10) }

(***************************************************************************)
(* Execution Report Trade Break Message                                    *)
(***************************************************************************)

ExecutionReportTradeBreakMessage ==
    [ sendingTime    : Sample(8),
      orderId        : Sample(8),
      clordid        : Sample(16),
      execId         : Sample(8),
      execRefId      : Sample(8),
      trdMatchId     : Sample(8),
      ordStatus      : Sample(1),
      leavesQty      : Sample(4),
      cumQty         : Sample(4),
      linkIdOptional : Sample(4),
      securityGroup  : Sample(1),
      partiesGroups  : PartiesGroups10 ]

EncodeExecutionReportTradeBreakMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.execId
        \o message.execRefId
        \o message.trdMatchId
        \o message.ordStatus
        \o message.leavesQty
        \o message.cumQty
        \o message.linkIdOptional
        \o message.securityGroup
        \o EncodePartiesGroups10(message.partiesGroups)

DecodeExecutionReportTradeBreakMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(execId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(execRefId.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(trdMatchId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordStatus.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(cumQty.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(linkIdOptional.rest, 1) IN IF ~securityGroup.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups10(securityGroup.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         orderId        |-> orderId.value,
         clordid        |-> clordid.value,
         execId         |-> execId.value,
         execRefId      |-> execRefId.value,
         trdMatchId     |-> trdMatchId.value,
         ordStatus      |-> ordStatus.value,
         leavesQty      |-> leavesQty.value,
         cumQty         |-> cumQty.value,
         linkIdOptional |-> linkIdOptional.value,
         securityGroup  |-> securityGroup.value,
         partiesGroups  |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportTradeBreakMessage ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      clordid        |-> [i \in 1 .. 16 |-> 0],
      execId         |-> [i \in 1 .. 8 |-> 0],
      execRefId      |-> [i \in 1 .. 8 |-> 0],
      trdMatchId     |-> [i \in 1 .. 8 |-> 0],
      ordStatus      |-> [i \in 1 .. 1 |-> 0],
      leavesQty      |-> [i \in 1 .. 4 |-> 0],
      cumQty         |-> [i \in 1 .. 4 |-> 0],
      linkIdOptional |-> [i \in 1 .. 4 |-> 0],
      securityGroup  |-> [i \in 1 .. 1 |-> 0],
      partiesGroups  |-> ZeroPartiesGroups10 ]

(* Execution Report Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeBreakMessage ==
    { ZeroExecutionReportTradeBreakMessage }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.securityGroup = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeBreakMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups10 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup11 ==
    [ partyIdNewOrderSinglePartyId : Sample(16),
      partyIdSource                : Sample(1),
      partyRole                    : Sample(1) ]

EncodePartiesGroup11(message) ==
    message.partyIdNewOrderSinglePartyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup11(bytes) ==
    LET partyIdNewOrderSinglePartyId == ReadBytes(bytes, 16) IN IF ~partyIdNewOrderSinglePartyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyIdNewOrderSinglePartyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyIdNewOrderSinglePartyId |-> partyIdNewOrderSinglePartyId.value,
         partyIdSource                |-> partyIdSource.value,
         partyRole                    |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup11 ==
    [ partyIdNewOrderSinglePartyId |-> [i \in 1 .. 16 |-> 0],
      partyIdSource                |-> [i \in 1 .. 1 |-> 0],
      partyRole                    |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup11 ==
    { ZeroPartiesGroup11 }
        \cup { [ZeroPartiesGroup11 EXCEPT !.partyIdNewOrderSinglePartyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup11 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup11 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup11List(_)
EncodePartiesGroup11List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup11(Head(messages)) \o EncodePartiesGroup11List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup11List(_, _)
ReadPartiesGroup11List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup11(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup11List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup11 == { ZeroPartiesGroup11 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups11 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup11) ]

EncodePartiesGroups11(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup11List(message.partiesGroup)

DecodePartiesGroups11(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup11List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups11 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups11 ==
    { ZeroPartiesGroups11 }
        \cup { [ZeroPartiesGroups11 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups11 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup11) }

(***************************************************************************)
(* Execution Report Restatement Message                                    *)
(***************************************************************************)

ExecutionReportRestatementMessage ==
    [ sendingTime               : Sample(8),
      orderId                   : Sample(8),
      clordid                   : Sample(16),
      execId                    : Sample(8),
      ordStatus                 : Sample(1),
      lastPxOptional            : Sample(8),
      leavesQty                 : Sample(4),
      cumQty                    : Sample(4),
      lastShares                : Sample(4),
      execRestatementReason     : Sample(1),
      transactTime              : Sample(8),
      extendedRestatementReason : Sample(1),
      linkIdOptional            : Sample(4),
      partiesGroups             : PartiesGroups11 ]

EncodeExecutionReportRestatementMessage(message) ==
    message.sendingTime
        \o message.orderId
        \o message.clordid
        \o message.execId
        \o message.ordStatus
        \o message.lastPxOptional
        \o message.leavesQty
        \o message.cumQty
        \o message.lastShares
        \o message.execRestatementReason
        \o message.transactTime
        \o message.extendedRestatementReason
        \o message.linkIdOptional
        \o EncodePartiesGroups11(message.partiesGroups)

DecodeExecutionReportRestatementMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(sendingTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderId.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET execId == ReadBytes(clordid.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET lastPxOptional == ReadBytes(ordStatus.rest, 8) IN IF ~lastPxOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPxOptional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET lastShares == ReadBytes(cumQty.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(lastShares.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execRestatementReason.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET extendedRestatementReason == ReadBytes(transactTime.rest, 1) IN IF ~extendedRestatementReason.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(extendedRestatementReason.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups11(linkIdOptional.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime               |-> sendingTime.value,
         orderId                   |-> orderId.value,
         clordid                   |-> clordid.value,
         execId                    |-> execId.value,
         ordStatus                 |-> ordStatus.value,
         lastPxOptional            |-> lastPxOptional.value,
         leavesQty                 |-> leavesQty.value,
         cumQty                    |-> cumQty.value,
         lastShares                |-> lastShares.value,
         execRestatementReason     |-> execRestatementReason.value,
         transactTime              |-> transactTime.value,
         extendedRestatementReason |-> extendedRestatementReason.value,
         linkIdOptional            |-> linkIdOptional.value,
         partiesGroups             |-> partiesGroups.value ], partiesGroups.rest)

ZeroExecutionReportRestatementMessage ==
    [ sendingTime               |-> [i \in 1 .. 8 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clordid                   |-> [i \in 1 .. 16 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      lastPxOptional            |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 4 |-> 0],
      cumQty                    |-> [i \in 1 .. 4 |-> 0],
      lastShares                |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 1 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      extendedRestatementReason |-> [i \in 1 .. 1 |-> 0],
      linkIdOptional            |-> [i \in 1 .. 4 |-> 0],
      partiesGroups             |-> ZeroPartiesGroups11 ]

(* Execution Report Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportRestatementMessage ==
    { ZeroExecutionReportRestatementMessage }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.lastPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.extendedRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRestatementMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups11 }

(***************************************************************************)
(* Order Cancel Reject Message: 30 bytes                                   *)
(***************************************************************************)

OrderCancelRejectMessage ==
    [ sendingTime      : Sample(8),
      clordid          : Sample(16),
      cxlRejResponseTo : Sample(1),
      cxlRejReason     : Sample(1),
      linkIdOptional   : Sample(4) ]

EncodeOrderCancelRejectMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.cxlRejResponseTo
        \o message.cxlRejReason
        \o message.linkIdOptional

DecodeOrderCancelRejectMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET cxlRejResponseTo == ReadBytes(clordid.rest, 1) IN IF ~cxlRejResponseTo.ok THEN Fail ELSE
    LET cxlRejReason == ReadBytes(cxlRejResponseTo.rest, 1) IN IF ~cxlRejReason.ok THEN Fail ELSE
    LET linkIdOptional == ReadBytes(cxlRejReason.rest, 4) IN IF ~linkIdOptional.ok THEN Fail ELSE
    Ok([ sendingTime      |-> sendingTime.value,
         clordid          |-> clordid.value,
         cxlRejResponseTo |-> cxlRejResponseTo.value,
         cxlRejReason     |-> cxlRejReason.value,
         linkIdOptional   |-> linkIdOptional.value ], linkIdOptional.rest)

ZeroOrderCancelRejectMessage ==
    [ sendingTime      |-> [i \in 1 .. 8 |-> 0],
      clordid          |-> [i \in 1 .. 16 |-> 0],
      cxlRejResponseTo |-> [i \in 1 .. 1 |-> 0],
      cxlRejReason     |-> [i \in 1 .. 1 |-> 0],
      linkIdOptional   |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRejectMessage ==
    { ZeroOrderCancelRejectMessage }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cxlRejResponseTo = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cxlRejReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.linkIdOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Mass Cancel Reject Message: 56 bytes                                    *)
(***************************************************************************)

MassCancelRejectMessage ==
    [ sendingTime            : Sample(8),
      clordid                : Sample(16),
      symbol                 : Sample(6),
      symbolSfx              : Sample(6),
      sideOptional           : Sample(1),
      lowerThanPrice         : Sample(8),
      higherThanPrice        : Sample(8),
      cancelGroupId          : Sample(2),
      massCancelRejectReason : Sample(1) ]

EncodeMassCancelRejectMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.symbol
        \o message.symbolSfx
        \o message.sideOptional
        \o message.lowerThanPrice
        \o message.higherThanPrice
        \o message.cancelGroupId
        \o message.massCancelRejectReason

DecodeMassCancelRejectMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET symbol == ReadBytes(clordid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(symbolSfx.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET lowerThanPrice == ReadBytes(sideOptional.rest, 8) IN IF ~lowerThanPrice.ok THEN Fail ELSE
    LET higherThanPrice == ReadBytes(lowerThanPrice.rest, 8) IN IF ~higherThanPrice.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(higherThanPrice.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(cancelGroupId.rest, 1) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    Ok([ sendingTime            |-> sendingTime.value,
         clordid                |-> clordid.value,
         symbol                 |-> symbol.value,
         symbolSfx              |-> symbolSfx.value,
         sideOptional           |-> sideOptional.value,
         lowerThanPrice         |-> lowerThanPrice.value,
         higherThanPrice        |-> higherThanPrice.value,
         cancelGroupId          |-> cancelGroupId.value,
         massCancelRejectReason |-> massCancelRejectReason.value ], massCancelRejectReason.rest)

ZeroMassCancelRejectMessage ==
    [ sendingTime            |-> [i \in 1 .. 8 |-> 0],
      clordid                |-> [i \in 1 .. 16 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      symbolSfx              |-> [i \in 1 .. 6 |-> 0],
      sideOptional           |-> [i \in 1 .. 1 |-> 0],
      lowerThanPrice         |-> [i \in 1 .. 8 |-> 0],
      higherThanPrice        |-> [i \in 1 .. 8 |-> 0],
      cancelGroupId          |-> [i \in 1 .. 2 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejectMessage ==
    { ZeroMassCancelRejectMessage }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.lowerThanPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.higherThanPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelRejectMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

ExecutionReportPendingNewMessageCode == 5  \* 0x05
ExecutionReportNewMessageCode == 6  \* 0x06
ExecutionReportRejectedMessageCode == 7  \* 0x07
ExecutionReportTradeMessageCode == 8  \* 0x08
ExecutionReportPendingCancelMessageCode == 9  \* 0x09
PendingMassCancelMessageCode == 10  \* 0x0a
ExecutionReportCanceledMessageCode == 11  \* 0x0b
MassCancelDoneMessageCode == 12  \* 0x0c
ExecutionReportPendingReplaceMessageCode == 13  \* 0x0d
ExecutionReportReplacedMessageCode == 14  \* 0x0e
ExecutionReportTradeCorrectionMessageCode == 15  \* 0x0f
ExecutionReportTradeBreakMessageCode == 16  \* 0x10
ExecutionReportRestatementMessageCode == 17  \* 0x11
OrderCancelRejectMessageCode == 18  \* 0x12
MassCancelRejectMessageCode == 20  \* 0x14

ServerPayload ==
    [ tag : {ExecutionReportPendingNewMessageCode}, body : ExecutionReportPendingNewMessage ]
        \cup [ tag : {ExecutionReportNewMessageCode}, body : ExecutionReportNewMessage ]
        \cup [ tag : {ExecutionReportRejectedMessageCode}, body : ExecutionReportRejectedMessage ]
        \cup [ tag : {ExecutionReportTradeMessageCode}, body : ExecutionReportTradeMessage ]
        \cup [ tag : {ExecutionReportPendingCancelMessageCode}, body : ExecutionReportPendingCancelMessage ]
        \cup [ tag : {PendingMassCancelMessageCode}, body : PendingMassCancelMessage ]
        \cup [ tag : {ExecutionReportCanceledMessageCode}, body : ExecutionReportCanceledMessage ]
        \cup [ tag : {MassCancelDoneMessageCode}, body : MassCancelDoneMessage ]
        \cup [ tag : {ExecutionReportPendingReplaceMessageCode}, body : ExecutionReportPendingReplaceMessage ]
        \cup [ tag : {ExecutionReportReplacedMessageCode}, body : ExecutionReportReplacedMessage ]
        \cup [ tag : {ExecutionReportTradeCorrectionMessageCode}, body : ExecutionReportTradeCorrectionMessage ]
        \cup [ tag : {ExecutionReportTradeBreakMessageCode}, body : ExecutionReportTradeBreakMessage ]
        \cup [ tag : {ExecutionReportRestatementMessageCode}, body : ExecutionReportRestatementMessage ]
        \cup [ tag : {OrderCancelRejectMessageCode}, body : OrderCancelRejectMessage ]
        \cup [ tag : {MassCancelRejectMessageCode}, body : MassCancelRejectMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = ExecutionReportPendingNewMessageCode -> EncodeExecutionReportPendingNewMessage(message.body)
      [] message.tag = ExecutionReportNewMessageCode -> EncodeExecutionReportNewMessage(message.body)
      [] message.tag = ExecutionReportRejectedMessageCode -> EncodeExecutionReportRejectedMessage(message.body)
      [] message.tag = ExecutionReportTradeMessageCode -> EncodeExecutionReportTradeMessage(message.body)
      [] message.tag = ExecutionReportPendingCancelMessageCode -> EncodeExecutionReportPendingCancelMessage(message.body)
      [] message.tag = PendingMassCancelMessageCode -> EncodePendingMassCancelMessage(message.body)
      [] message.tag = ExecutionReportCanceledMessageCode -> EncodeExecutionReportCanceledMessage(message.body)
      [] message.tag = MassCancelDoneMessageCode -> EncodeMassCancelDoneMessage(message.body)
      [] message.tag = ExecutionReportPendingReplaceMessageCode -> EncodeExecutionReportPendingReplaceMessage(message.body)
      [] message.tag = ExecutionReportReplacedMessageCode -> EncodeExecutionReportReplacedMessage(message.body)
      [] message.tag = ExecutionReportTradeCorrectionMessageCode -> EncodeExecutionReportTradeCorrectionMessage(message.body)
      [] message.tag = ExecutionReportTradeBreakMessageCode -> EncodeExecutionReportTradeBreakMessage(message.body)
      [] message.tag = ExecutionReportRestatementMessageCode -> EncodeExecutionReportRestatementMessage(message.body)
      [] message.tag = OrderCancelRejectMessageCode -> EncodeOrderCancelRejectMessage(message.body)
      [] message.tag = MassCancelRejectMessageCode -> EncodeMassCancelRejectMessage(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = ExecutionReportPendingNewMessageCode -> DecodeExecutionReportPendingNewMessage(bytes)
              [] tag = ExecutionReportNewMessageCode -> DecodeExecutionReportNewMessage(bytes)
              [] tag = ExecutionReportRejectedMessageCode -> DecodeExecutionReportRejectedMessage(bytes)
              [] tag = ExecutionReportTradeMessageCode -> DecodeExecutionReportTradeMessage(bytes)
              [] tag = ExecutionReportPendingCancelMessageCode -> DecodeExecutionReportPendingCancelMessage(bytes)
              [] tag = PendingMassCancelMessageCode -> DecodePendingMassCancelMessage(bytes)
              [] tag = ExecutionReportCanceledMessageCode -> DecodeExecutionReportCanceledMessage(bytes)
              [] tag = MassCancelDoneMessageCode -> DecodeMassCancelDoneMessage(bytes)
              [] tag = ExecutionReportPendingReplaceMessageCode -> DecodeExecutionReportPendingReplaceMessage(bytes)
              [] tag = ExecutionReportReplacedMessageCode -> DecodeExecutionReportReplacedMessage(bytes)
              [] tag = ExecutionReportTradeCorrectionMessageCode -> DecodeExecutionReportTradeCorrectionMessage(bytes)
              [] tag = ExecutionReportTradeBreakMessageCode -> DecodeExecutionReportTradeBreakMessage(bytes)
              [] tag = ExecutionReportRestatementMessageCode -> DecodeExecutionReportRestatementMessage(bytes)
              [] tag = OrderCancelRejectMessageCode -> DecodeOrderCancelRejectMessage(bytes)
              [] tag = MassCancelRejectMessageCode -> DecodeMassCancelRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> ExecutionReportPendingNewMessageCode, body |-> ZeroExecutionReportPendingNewMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> ExecutionReportPendingNewMessageCode, body |-> one] : one \in CheckedExecutionReportPendingNewMessage }
        \cup { [tag |-> ExecutionReportNewMessageCode, body |-> one] : one \in CheckedExecutionReportNewMessage }
        \cup { [tag |-> ExecutionReportRejectedMessageCode, body |-> one] : one \in CheckedExecutionReportRejectedMessage }
        \cup { [tag |-> ExecutionReportTradeMessageCode, body |-> one] : one \in CheckedExecutionReportTradeMessage }
        \cup { [tag |-> ExecutionReportPendingCancelMessageCode, body |-> one] : one \in CheckedExecutionReportPendingCancelMessage }
        \cup { [tag |-> PendingMassCancelMessageCode, body |-> one] : one \in CheckedPendingMassCancelMessage }
        \cup { [tag |-> ExecutionReportCanceledMessageCode, body |-> one] : one \in CheckedExecutionReportCanceledMessage }
        \cup { [tag |-> MassCancelDoneMessageCode, body |-> one] : one \in CheckedMassCancelDoneMessage }
        \cup { [tag |-> ExecutionReportPendingReplaceMessageCode, body |-> one] : one \in CheckedExecutionReportPendingReplaceMessage }
        \cup { [tag |-> ExecutionReportReplacedMessageCode, body |-> one] : one \in CheckedExecutionReportReplacedMessage }
        \cup { [tag |-> ExecutionReportTradeCorrectionMessageCode, body |-> one] : one \in CheckedExecutionReportTradeCorrectionMessage }
        \cup { [tag |-> ExecutionReportTradeBreakMessageCode, body |-> one] : one \in CheckedExecutionReportTradeBreakMessage }
        \cup { [tag |-> ExecutionReportRestatementMessageCode, body |-> one] : one \in CheckedExecutionReportRestatementMessage }
        \cup { [tag |-> OrderCancelRejectMessageCode, body |-> one] : one \in CheckedOrderCancelRejectMessage }
        \cup { [tag |-> MassCancelRejectMessageCode, body |-> one] : one \in CheckedMassCancelRejectMessage }

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

(* Every Execution Report Pending New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportPendingNewMessage ==
    \A message \in CheckedExecutionReportPendingNewMessage :
        LET read == DecodeExecutionReportPendingNewMessage(EncodeExecutionReportPendingNewMessage(message))
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

(* Every Execution Report New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportNewMessage ==
    \A message \in CheckedExecutionReportNewMessage :
        LET read == DecodeExecutionReportNewMessage(EncodeExecutionReportNewMessage(message))
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

(* Every Execution Report Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportRejectedMessage ==
    \A message \in CheckedExecutionReportRejectedMessage :
        LET read == DecodeExecutionReportRejectedMessage(EncodeExecutionReportRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup4 ==
    \A message \in CheckedPartiesGroup4 :
        LET read == DecodePartiesGroup4(EncodePartiesGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups4 ==
    \A message \in CheckedPartiesGroups4 :
        LET read == DecodePartiesGroups4(EncodePartiesGroups4(message))
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

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup5 ==
    \A message \in CheckedPartiesGroup5 :
        LET read == DecodePartiesGroup5(EncodePartiesGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups5 ==
    \A message \in CheckedPartiesGroups5 :
        LET read == DecodePartiesGroups5(EncodePartiesGroups5(message))
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

(* Every Pending Mass Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPendingMassCancelMessage ==
    \A message \in CheckedPendingMassCancelMessage :
        LET read == DecodePendingMassCancelMessage(EncodePendingMassCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup6 ==
    \A message \in CheckedPartiesGroup6 :
        LET read == DecodePartiesGroup6(EncodePartiesGroup6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups6 ==
    \A message \in CheckedPartiesGroups6 :
        LET read == DecodePartiesGroups6(EncodePartiesGroups6(message))
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

(* Every Mass Cancel Done Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelDoneMessage ==
    \A message \in CheckedMassCancelDoneMessage :
        LET read == DecodeMassCancelDoneMessage(EncodeMassCancelDoneMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup7 ==
    \A message \in CheckedPartiesGroup7 :
        LET read == DecodePartiesGroup7(EncodePartiesGroup7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups7 ==
    \A message \in CheckedPartiesGroups7 :
        LET read == DecodePartiesGroups7(EncodePartiesGroups7(message))
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

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup8 ==
    \A message \in CheckedPartiesGroup8 :
        LET read == DecodePartiesGroup8(EncodePartiesGroup8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups8 ==
    \A message \in CheckedPartiesGroups8 :
        LET read == DecodePartiesGroups8(EncodePartiesGroups8(message))
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

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup9 ==
    \A message \in CheckedPartiesGroup9 :
        LET read == DecodePartiesGroup9(EncodePartiesGroup9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups9 ==
    \A message \in CheckedPartiesGroups9 :
        LET read == DecodePartiesGroups9(EncodePartiesGroups9(message))
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

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup10 ==
    \A message \in CheckedPartiesGroup10 :
        LET read == DecodePartiesGroup10(EncodePartiesGroup10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups10 ==
    \A message \in CheckedPartiesGroups10 :
        LET read == DecodePartiesGroups10(EncodePartiesGroups10(message))
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

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup11 ==
    \A message \in CheckedPartiesGroup11 :
        LET read == DecodePartiesGroup11(EncodePartiesGroup11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups11 ==
    \A message \in CheckedPartiesGroups11 :
        LET read == DecodePartiesGroups11(EncodePartiesGroups11(message))
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

(* Every Order Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRejectMessage ==
    \A message \in CheckedOrderCancelRejectMessage :
        LET read == DecodeOrderCancelRejectMessage(EncodeOrderCancelRejectMessage(message))
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
