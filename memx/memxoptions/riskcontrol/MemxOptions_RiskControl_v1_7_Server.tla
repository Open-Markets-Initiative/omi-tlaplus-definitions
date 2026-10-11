---------------- MODULE MemxOptions_RiskControl_v1_7_Server ----------------
(***************************************************************************)
(* The Members Exchange Risk Control v1.7                                  *)
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
(* Risk Settings Query Message: 20 bytes                                   *)
(***************************************************************************)

RiskSettingsQueryMessage ==
    [ clordid : Sample(20) ]

EncodeRiskSettingsQueryMessage(message) ==
    message.clordid

DecodeRiskSettingsQueryMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ clordid |-> clordid.value ], clordid.rest)

ZeroRiskSettingsQueryMessage ==
    [ clordid |-> [i \in 1 .. 20 |-> 0] ]

(* Risk Settings Query Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskSettingsQueryMessage ==
    { ZeroRiskSettingsQueryMessage }
        \cup { [ZeroRiskSettingsQueryMessage EXCEPT !.clordid = one] : one \in Sample(20) }

(***************************************************************************)
(* Active Risk Threshold Change Request Message: 34 bytes                  *)
(***************************************************************************)

ActiveRiskThresholdChangeRequestMessage ==
    [ clOrdIdActiveRiskThresholdChangeRequestClOrdId             : Sample(20),
      underlierActiveRiskThresholdChangeRequestUnderlierOptional : Sample(6),
      efidActiveRiskThresholdChangeRequestEfidOptional           : Sample(4),
      thresholdQuantity                                          : Sample(4) ]

EncodeActiveRiskThresholdChangeRequestMessage(message) ==
    message.clOrdIdActiveRiskThresholdChangeRequestClOrdId
        \o message.underlierActiveRiskThresholdChangeRequestUnderlierOptional
        \o message.efidActiveRiskThresholdChangeRequestEfidOptional
        \o message.thresholdQuantity

DecodeActiveRiskThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdActiveRiskThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdActiveRiskThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierActiveRiskThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdActiveRiskThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierActiveRiskThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidActiveRiskThresholdChangeRequestEfidOptional == ReadBytes(underlierActiveRiskThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidActiveRiskThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidActiveRiskThresholdChangeRequestEfidOptional.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    Ok([ clOrdIdActiveRiskThresholdChangeRequestClOrdId             |-> clOrdIdActiveRiskThresholdChangeRequestClOrdId.value,
         underlierActiveRiskThresholdChangeRequestUnderlierOptional |-> underlierActiveRiskThresholdChangeRequestUnderlierOptional.value,
         efidActiveRiskThresholdChangeRequestEfidOptional           |-> efidActiveRiskThresholdChangeRequestEfidOptional.value,
         thresholdQuantity                                          |-> thresholdQuantity.value ], thresholdQuantity.rest)

ZeroActiveRiskThresholdChangeRequestMessage ==
    [ clOrdIdActiveRiskThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity                                          |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdChangeRequestMessage ==
    { ZeroActiveRiskThresholdChangeRequestMessage }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.clOrdIdActiveRiskThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.underlierActiveRiskThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.efidActiveRiskThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledgement Request Message: 34 bytes                   *)
(***************************************************************************)

ActiveRiskAcknowledgementRequestMessage ==
    [ clOrdIdActiveRiskAcknowledgementRequestClOrdId     : Sample(20),
      underlierActiveRiskAcknowledgementRequestUnderlier : Sample(6),
      efidActiveRiskAcknowledgementRequestEfid           : Sample(4),
      quantity                                           : Sample(4) ]

EncodeActiveRiskAcknowledgementRequestMessage(message) ==
    message.clOrdIdActiveRiskAcknowledgementRequestClOrdId
        \o message.underlierActiveRiskAcknowledgementRequestUnderlier
        \o message.efidActiveRiskAcknowledgementRequestEfid
        \o message.quantity

DecodeActiveRiskAcknowledgementRequestMessage(bytes) ==
    LET clOrdIdActiveRiskAcknowledgementRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdActiveRiskAcknowledgementRequestClOrdId.ok THEN Fail ELSE
    LET underlierActiveRiskAcknowledgementRequestUnderlier == ReadBytes(clOrdIdActiveRiskAcknowledgementRequestClOrdId.rest, 6) IN IF ~underlierActiveRiskAcknowledgementRequestUnderlier.ok THEN Fail ELSE
    LET efidActiveRiskAcknowledgementRequestEfid == ReadBytes(underlierActiveRiskAcknowledgementRequestUnderlier.rest, 4) IN IF ~efidActiveRiskAcknowledgementRequestEfid.ok THEN Fail ELSE
    LET quantity == ReadBytes(efidActiveRiskAcknowledgementRequestEfid.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ clOrdIdActiveRiskAcknowledgementRequestClOrdId     |-> clOrdIdActiveRiskAcknowledgementRequestClOrdId.value,
         underlierActiveRiskAcknowledgementRequestUnderlier |-> underlierActiveRiskAcknowledgementRequestUnderlier.value,
         efidActiveRiskAcknowledgementRequestEfid           |-> efidActiveRiskAcknowledgementRequestEfid.value,
         quantity                                           |-> quantity.value ], quantity.rest)

ZeroActiveRiskAcknowledgementRequestMessage ==
    [ clOrdIdActiveRiskAcknowledgementRequestClOrdId     |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskAcknowledgementRequestUnderlier |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskAcknowledgementRequestEfid           |-> [i \in 1 .. 4 |-> 0],
      quantity                                           |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledgement Request Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgementRequestMessage ==
    { ZeroActiveRiskAcknowledgementRequestMessage }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.clOrdIdActiveRiskAcknowledgementRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.underlierActiveRiskAcknowledgementRequestUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.efidActiveRiskAcknowledgementRequestEfid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Volume Threshold Change Request Message: 44 bytes                    *)
(***************************************************************************)

CpVolumeThresholdChangeRequestMessage ==
    [ clOrdIdCpVolumeThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpVolumeThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpVolumeThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                              : Sample(2),
      volume                                                   : Sample(8),
      periodInMilliSeconds                                     : Sample(4) ]

EncodeCpVolumeThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpVolumeThresholdChangeRequestClOrdId
        \o message.underlierCpVolumeThresholdChangeRequestUnderlierOptional
        \o message.efidCpVolumeThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.volume
        \o message.periodInMilliSeconds

DecodeCpVolumeThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpVolumeThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpVolumeThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpVolumeThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpVolumeThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpVolumeThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpVolumeThresholdChangeRequestEfidOptional == ReadBytes(underlierCpVolumeThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpVolumeThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpVolumeThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET volume == ReadBytes(riskGroupId.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(volume.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpVolumeThresholdChangeRequestClOrdId             |-> clOrdIdCpVolumeThresholdChangeRequestClOrdId.value,
         underlierCpVolumeThresholdChangeRequestUnderlierOptional |-> underlierCpVolumeThresholdChangeRequestUnderlierOptional.value,
         efidCpVolumeThresholdChangeRequestEfidOptional           |-> efidCpVolumeThresholdChangeRequestEfidOptional.value,
         riskGroupId                                              |-> riskGroupId.value,
         volume                                                   |-> volume.value,
         periodInMilliSeconds                                     |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpVolumeThresholdChangeRequestMessage ==
    [ clOrdIdCpVolumeThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpVolumeThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpVolumeThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                              |-> [i \in 1 .. 2 |-> 0],
      volume                                                   |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds                                     |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Volume Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpVolumeThresholdChangeRequestMessage ==
    { ZeroCpVolumeThresholdChangeRequestMessage }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.clOrdIdCpVolumeThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.underlierCpVolumeThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.efidCpVolumeThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Executed Notional Threshold Change Request Message: 44 bytes         *)
(***************************************************************************)

CpExecutedNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpExecutedNotionalThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                        : Sample(2),
      priceInDollars                                                     : Sample(8),
      periodInMilliSeconds                                               : Sample(4) ]

EncodeCpExecutedNotionalThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId
        \o message.underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional
        \o message.efidCpExecutedNotionalThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.priceInDollars
        \o message.periodInMilliSeconds

DecodeCpExecutedNotionalThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpExecutedNotionalThresholdChangeRequestEfidOptional == ReadBytes(underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpExecutedNotionalThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpExecutedNotionalThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(priceInDollars.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId             |-> clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId.value,
         underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional |-> underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional.value,
         efidCpExecutedNotionalThresholdChangeRequestEfidOptional           |-> efidCpExecutedNotionalThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                        |-> riskGroupId.value,
         priceInDollars                                                     |-> priceInDollars.value,
         periodInMilliSeconds                                               |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpExecutedNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpExecutedNotionalThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                        |-> [i \in 1 .. 2 |-> 0],
      priceInDollars                                                     |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds                                               |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Executed Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpExecutedNotionalThresholdChangeRequestMessage ==
    { ZeroCpExecutedNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.clOrdIdCpExecutedNotionalThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.underlierCpExecutedNotionalThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.efidCpExecutedNotionalThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Total Executions Threshold Change Request Message: 40 bytes          *)
(***************************************************************************)

CpTotalExecutionsThresholdChangeRequestMessage ==
    [ clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpTotalExecutionsThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                       : Sample(2),
      totalExecutions                                                   : Sample(4),
      periodInMilliSeconds                                              : Sample(4) ]

EncodeCpTotalExecutionsThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId
        \o message.underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional
        \o message.efidCpTotalExecutionsThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.totalExecutions
        \o message.periodInMilliSeconds

DecodeCpTotalExecutionsThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpTotalExecutionsThresholdChangeRequestEfidOptional == ReadBytes(underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpTotalExecutionsThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpTotalExecutionsThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET totalExecutions == ReadBytes(riskGroupId.rest, 4) IN IF ~totalExecutions.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(totalExecutions.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId             |-> clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId.value,
         underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional |-> underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional.value,
         efidCpTotalExecutionsThresholdChangeRequestEfidOptional           |-> efidCpTotalExecutionsThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                       |-> riskGroupId.value,
         totalExecutions                                                   |-> totalExecutions.value,
         periodInMilliSeconds                                              |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpTotalExecutionsThresholdChangeRequestMessage ==
    [ clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpTotalExecutionsThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                       |-> [i \in 1 .. 2 |-> 0],
      totalExecutions                                                   |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds                                              |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Total Executions Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpTotalExecutionsThresholdChangeRequestMessage ==
    { ZeroCpTotalExecutionsThresholdChangeRequestMessage }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.clOrdIdCpTotalExecutionsThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.underlierCpTotalExecutionsThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.efidCpTotalExecutionsThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.totalExecutions = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Percent Outstanding Contracts Threshold Change Request Message: 38   *)
(* bytes                                                                   *)
(***************************************************************************)

CpPercentOutstandingContractsThresholdChangeRequestMessage ==
    [ clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional           : Sample(4),
      percent                                                                       : Sample(4),
      periodInMilliSeconds                                                          : Sample(4) ]

EncodeCpPercentOutstandingContractsThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId
        \o message.underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional
        \o message.efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional
        \o message.percent
        \o message.periodInMilliSeconds

DecodeCpPercentOutstandingContractsThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional == ReadBytes(underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET percent == ReadBytes(efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional.rest, 4) IN IF ~percent.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(percent.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId             |-> clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId.value,
         underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional |-> underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional.value,
         efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional           |-> efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional.value,
         percent                                                                       |-> percent.value,
         periodInMilliSeconds                                                          |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage ==
    [ clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      percent                                                                       |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds                                                          |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Percent Outstanding Contracts Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpPercentOutstandingContractsThresholdChangeRequestMessage ==
    { ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.clOrdIdCpPercentOutstandingContractsThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.underlierCpPercentOutstandingContractsThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.efidCpPercentOutstandingContractsThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.percent = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Breach Count Threshold Change Request Message: 40 bytes              *)
(***************************************************************************)

CpBreachCountThresholdChangeRequestMessage ==
    [ clOrdIdCpBreachCountThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpBreachCountThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpBreachCountThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                   : Sample(2),
      count                                                         : Sample(4),
      periodInMilliSeconds                                          : Sample(4) ]

EncodeCpBreachCountThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpBreachCountThresholdChangeRequestClOrdId
        \o message.underlierCpBreachCountThresholdChangeRequestUnderlierOptional
        \o message.efidCpBreachCountThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.count
        \o message.periodInMilliSeconds

DecodeCpBreachCountThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpBreachCountThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpBreachCountThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpBreachCountThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpBreachCountThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpBreachCountThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpBreachCountThresholdChangeRequestEfidOptional == ReadBytes(underlierCpBreachCountThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpBreachCountThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpBreachCountThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET count == ReadBytes(riskGroupId.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(count.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpBreachCountThresholdChangeRequestClOrdId             |-> clOrdIdCpBreachCountThresholdChangeRequestClOrdId.value,
         underlierCpBreachCountThresholdChangeRequestUnderlierOptional |-> underlierCpBreachCountThresholdChangeRequestUnderlierOptional.value,
         efidCpBreachCountThresholdChangeRequestEfidOptional           |-> efidCpBreachCountThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                   |-> riskGroupId.value,
         count                                                         |-> count.value,
         periodInMilliSeconds                                          |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpBreachCountThresholdChangeRequestMessage ==
    [ clOrdIdCpBreachCountThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpBreachCountThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpBreachCountThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                   |-> [i \in 1 .. 2 |-> 0],
      count                                                         |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds                                          |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Breach Count Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpBreachCountThresholdChangeRequestMessage ==
    { ZeroCpBreachCountThresholdChangeRequestMessage }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.clOrdIdCpBreachCountThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.underlierCpBreachCountThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.efidCpBreachCountThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Manual Cp Breach Trigger Request Message: 33 bytes                      *)
(***************************************************************************)

ManualCpBreachTriggerRequestMessage ==
    [ clOrdIdManualCpBreachTriggerRequestClOrdId             : Sample(20),
      underlierManualCpBreachTriggerRequestUnderlierOptional : Sample(6),
      efidManualCpBreachTriggerRequestEfidOptional           : Sample(4),
      riskGroupId                                            : Sample(2),
      sendCancels                                            : Sample(1) ]

EncodeManualCpBreachTriggerRequestMessage(message) ==
    message.clOrdIdManualCpBreachTriggerRequestClOrdId
        \o message.underlierManualCpBreachTriggerRequestUnderlierOptional
        \o message.efidManualCpBreachTriggerRequestEfidOptional
        \o message.riskGroupId
        \o message.sendCancels

DecodeManualCpBreachTriggerRequestMessage(bytes) ==
    LET clOrdIdManualCpBreachTriggerRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdManualCpBreachTriggerRequestClOrdId.ok THEN Fail ELSE
    LET underlierManualCpBreachTriggerRequestUnderlierOptional == ReadBytes(clOrdIdManualCpBreachTriggerRequestClOrdId.rest, 6) IN IF ~underlierManualCpBreachTriggerRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidManualCpBreachTriggerRequestEfidOptional == ReadBytes(underlierManualCpBreachTriggerRequestUnderlierOptional.rest, 4) IN IF ~efidManualCpBreachTriggerRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidManualCpBreachTriggerRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET sendCancels == ReadBytes(riskGroupId.rest, 1) IN IF ~sendCancels.ok THEN Fail ELSE
    Ok([ clOrdIdManualCpBreachTriggerRequestClOrdId             |-> clOrdIdManualCpBreachTriggerRequestClOrdId.value,
         underlierManualCpBreachTriggerRequestUnderlierOptional |-> underlierManualCpBreachTriggerRequestUnderlierOptional.value,
         efidManualCpBreachTriggerRequestEfidOptional           |-> efidManualCpBreachTriggerRequestEfidOptional.value,
         riskGroupId                                            |-> riskGroupId.value,
         sendCancels                                            |-> sendCancels.value ], sendCancels.rest)

ZeroManualCpBreachTriggerRequestMessage ==
    [ clOrdIdManualCpBreachTriggerRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierManualCpBreachTriggerRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidManualCpBreachTriggerRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                            |-> [i \in 1 .. 2 |-> 0],
      sendCancels                                            |-> [i \in 1 .. 1 |-> 0] ]

(* Manual Cp Breach Trigger Request Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerRequestMessage ==
    { ZeroManualCpBreachTriggerRequestMessage }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.clOrdIdManualCpBreachTriggerRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.underlierManualCpBreachTriggerRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.efidManualCpBreachTriggerRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.sendCancels = one] : one \in Sample(1) }

(***************************************************************************)
(* Cp Clear Breach Request Message: 28 bytes                               *)
(***************************************************************************)

CpClearBreachRequestMessage ==
    [ clOrdIdCpClearBreachRequestClOrdId : Sample(20),
      breachId                           : Sample(8) ]

EncodeCpClearBreachRequestMessage(message) ==
    message.clOrdIdCpClearBreachRequestClOrdId
        \o message.breachId

DecodeCpClearBreachRequestMessage(bytes) ==
    LET clOrdIdCpClearBreachRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpClearBreachRequestClOrdId.ok THEN Fail ELSE
    LET breachId == ReadBytes(clOrdIdCpClearBreachRequestClOrdId.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    Ok([ clOrdIdCpClearBreachRequestClOrdId |-> clOrdIdCpClearBreachRequestClOrdId.value,
         breachId                           |-> breachId.value ], breachId.rest)

ZeroCpClearBreachRequestMessage ==
    [ clOrdIdCpClearBreachRequestClOrdId |-> [i \in 1 .. 20 |-> 0],
      breachId                           |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Clear Breach Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearBreachRequestMessage ==
    { ZeroCpClearBreachRequestMessage }
        \cup { [ZeroCpClearBreachRequestMessage EXCEPT !.clOrdIdCpClearBreachRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpClearBreachRequestMessage EXCEPT !.breachId = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Allow Iso Orders Change Request Message: 33 bytes          *)
(***************************************************************************)

SingleOrderAllowIsoOrdersChangeRequestMessage ==
    [ clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId             : Sample(20),
      underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional : Sample(6),
      efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                      : Sample(2),
      allowIsoOrders                                                   : Sample(1) ]

EncodeSingleOrderAllowIsoOrdersChangeRequestMessage(message) ==
    message.clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId
        \o message.underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional
        \o message.efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.allowIsoOrders

DecodeSingleOrderAllowIsoOrdersChangeRequestMessage(bytes) ==
    LET clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional == ReadBytes(clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId.rest, 6) IN IF ~underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional == ReadBytes(underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional.rest, 4) IN IF ~efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowIsoOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowIsoOrders.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId             |-> clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId.value,
         underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional |-> underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional.value,
         efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional           |-> efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional.value,
         riskGroupId                                                      |-> riskGroupId.value,
         allowIsoOrders                                                   |-> allowIsoOrders.value ], allowIsoOrders.rest)

ZeroSingleOrderAllowIsoOrdersChangeRequestMessage ==
    [ clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                      |-> [i \in 1 .. 2 |-> 0],
      allowIsoOrders                                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Iso Orders Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowIsoOrdersChangeRequestMessage ==
    { ZeroSingleOrderAllowIsoOrdersChangeRequestMessage }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.clOrdIdSingleOrderAllowIsoOrdersChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.underlierSingleOrderAllowIsoOrdersChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.efidSingleOrderAllowIsoOrdersChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.allowIsoOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Allow Orders In Crossed Market Change Request Message: 33  *)
(* bytes                                                                   *)
(***************************************************************************)

SingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    [ clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId             : Sample(20),
      underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional : Sample(6),
      efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                                  : Sample(2),
      allowOrders                                                                  : Sample(1) ]

EncodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(message) ==
    message.clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId
        \o message.underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional
        \o message.efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.allowOrders

DecodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(bytes) ==
    LET clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional == ReadBytes(clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId.rest, 6) IN IF ~underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional == ReadBytes(underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional.rest, 4) IN IF ~efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowOrders.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId             |-> clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId.value,
         underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional |-> underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional.value,
         efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional           |-> efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional.value,
         riskGroupId                                                                  |-> riskGroupId.value,
         allowOrders                                                                  |-> allowOrders.value ], allowOrders.rest)

ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    [ clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                                  |-> [i \in 1 .. 2 |-> 0],
      allowOrders                                                                  |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Orders In Crossed Market Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    { ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.clOrdIdSingleOrderAllowOrdersInCrossedMarketChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.underlierSingleOrderAllowOrdersInCrossedMarketChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.efidSingleOrderAllowOrdersInCrossedMarketChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.allowOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Max Notional Change Request Message: 40 bytes              *)
(***************************************************************************)

SingleOrderMaxNotionalChangeRequestMessage ==
    [ clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId             : Sample(20),
      underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional : Sample(6),
      efidSingleOrderMaxNotionalChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                   : Sample(2),
      maxNotionalInDollars                                          : Sample(8) ]

EncodeSingleOrderMaxNotionalChangeRequestMessage(message) ==
    message.clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId
        \o message.underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional
        \o message.efidSingleOrderMaxNotionalChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.maxNotionalInDollars

DecodeSingleOrderMaxNotionalChangeRequestMessage(bytes) ==
    LET clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional == ReadBytes(clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId.rest, 6) IN IF ~underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidSingleOrderMaxNotionalChangeRequestEfidOptional == ReadBytes(underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional.rest, 4) IN IF ~efidSingleOrderMaxNotionalChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderMaxNotionalChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxNotionalInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~maxNotionalInDollars.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId             |-> clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId.value,
         underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional |-> underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional.value,
         efidSingleOrderMaxNotionalChangeRequestEfidOptional           |-> efidSingleOrderMaxNotionalChangeRequestEfidOptional.value,
         riskGroupId                                                   |-> riskGroupId.value,
         maxNotionalInDollars                                          |-> maxNotionalInDollars.value ], maxNotionalInDollars.rest)

ZeroSingleOrderMaxNotionalChangeRequestMessage ==
    [ clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderMaxNotionalChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                   |-> [i \in 1 .. 2 |-> 0],
      maxNotionalInDollars                                          |-> [i \in 1 .. 8 |-> 0] ]

(* Single Order Max Notional Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxNotionalChangeRequestMessage ==
    { ZeroSingleOrderMaxNotionalChangeRequestMessage }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.clOrdIdSingleOrderMaxNotionalChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.underlierSingleOrderMaxNotionalChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.efidSingleOrderMaxNotionalChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.maxNotionalInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Max Contracts Change Request Message: 36 bytes             *)
(***************************************************************************)

SingleOrderMaxContractsChangeRequestMessage ==
    [ clOrdIdSingleOrderMaxContractsChangeRequestClOrdId             : Sample(20),
      underlierSingleOrderMaxContractsChangeRequestUnderlierOptional : Sample(6),
      efidSingleOrderMaxContractsChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                    : Sample(2),
      maxContracts                                                   : Sample(4) ]

EncodeSingleOrderMaxContractsChangeRequestMessage(message) ==
    message.clOrdIdSingleOrderMaxContractsChangeRequestClOrdId
        \o message.underlierSingleOrderMaxContractsChangeRequestUnderlierOptional
        \o message.efidSingleOrderMaxContractsChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.maxContracts

DecodeSingleOrderMaxContractsChangeRequestMessage(bytes) ==
    LET clOrdIdSingleOrderMaxContractsChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderMaxContractsChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierSingleOrderMaxContractsChangeRequestUnderlierOptional == ReadBytes(clOrdIdSingleOrderMaxContractsChangeRequestClOrdId.rest, 6) IN IF ~underlierSingleOrderMaxContractsChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidSingleOrderMaxContractsChangeRequestEfidOptional == ReadBytes(underlierSingleOrderMaxContractsChangeRequestUnderlierOptional.rest, 4) IN IF ~efidSingleOrderMaxContractsChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderMaxContractsChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxContracts == ReadBytes(riskGroupId.rest, 4) IN IF ~maxContracts.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderMaxContractsChangeRequestClOrdId             |-> clOrdIdSingleOrderMaxContractsChangeRequestClOrdId.value,
         underlierSingleOrderMaxContractsChangeRequestUnderlierOptional |-> underlierSingleOrderMaxContractsChangeRequestUnderlierOptional.value,
         efidSingleOrderMaxContractsChangeRequestEfidOptional           |-> efidSingleOrderMaxContractsChangeRequestEfidOptional.value,
         riskGroupId                                                    |-> riskGroupId.value,
         maxContracts                                                   |-> maxContracts.value ], maxContracts.rest)

ZeroSingleOrderMaxContractsChangeRequestMessage ==
    [ clOrdIdSingleOrderMaxContractsChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderMaxContractsChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderMaxContractsChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                    |-> [i \in 1 .. 2 |-> 0],
      maxContracts                                                   |-> [i \in 1 .. 4 |-> 0] ]

(* Single Order Max Contracts Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxContractsChangeRequestMessage ==
    { ZeroSingleOrderMaxContractsChangeRequestMessage }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.clOrdIdSingleOrderMaxContractsChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.underlierSingleOrderMaxContractsChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.efidSingleOrderMaxContractsChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.maxContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Order Allow Market Orders Change Request Message: 33 bytes       *)
(***************************************************************************)

SingleOrderAllowMarketOrdersChangeRequestMessage ==
    [ clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId             : Sample(20),
      underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional : Sample(6),
      efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                         : Sample(2),
      allowMarketOrders                                                   : Sample(1) ]

EncodeSingleOrderAllowMarketOrdersChangeRequestMessage(message) ==
    message.clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId
        \o message.underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional
        \o message.efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.allowMarketOrders

DecodeSingleOrderAllowMarketOrdersChangeRequestMessage(bytes) ==
    LET clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional == ReadBytes(clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId.rest, 6) IN IF ~underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional == ReadBytes(underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional.rest, 4) IN IF ~efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowMarketOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowMarketOrders.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId             |-> clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId.value,
         underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional |-> underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional.value,
         efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional           |-> efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional.value,
         riskGroupId                                                         |-> riskGroupId.value,
         allowMarketOrders                                                   |-> allowMarketOrders.value ], allowMarketOrders.rest)

ZeroSingleOrderAllowMarketOrdersChangeRequestMessage ==
    [ clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                         |-> [i \in 1 .. 2 |-> 0],
      allowMarketOrders                                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Market Orders Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowMarketOrdersChangeRequestMessage ==
    { ZeroSingleOrderAllowMarketOrdersChangeRequestMessage }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.clOrdIdSingleOrderAllowMarketOrdersChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.underlierSingleOrderAllowMarketOrdersChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.efidSingleOrderAllowMarketOrdersChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.allowMarketOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Restricted Underlier Change Request Message: 33 bytes      *)
(***************************************************************************)

SingleOrderRestrictedUnderlierChangeRequestMessage ==
    [ clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId     : Sample(20),
      underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier : Sample(6),
      efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional   : Sample(4),
      riskGroupId                                                   : Sample(2),
      restricted                                                    : Sample(1) ]

EncodeSingleOrderRestrictedUnderlierChangeRequestMessage(message) ==
    message.clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId
        \o message.underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier
        \o message.efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.restricted

DecodeSingleOrderRestrictedUnderlierChangeRequestMessage(bytes) ==
    LET clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier == ReadBytes(clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId.rest, 6) IN IF ~underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier.ok THEN Fail ELSE
    LET efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional == ReadBytes(underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier.rest, 4) IN IF ~efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET restricted == ReadBytes(riskGroupId.rest, 1) IN IF ~restricted.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId     |-> clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId.value,
         underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier |-> underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier.value,
         efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional   |-> efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional.value,
         riskGroupId                                                   |-> riskGroupId.value,
         restricted                                                    |-> restricted.value ], restricted.rest)

ZeroSingleOrderRestrictedUnderlierChangeRequestMessage ==
    [ clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId     |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional   |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                   |-> [i \in 1 .. 2 |-> 0],
      restricted                                                    |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Restricted Underlier Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderRestrictedUnderlierChangeRequestMessage ==
    { ZeroSingleOrderRestrictedUnderlierChangeRequestMessage }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.clOrdIdSingleOrderRestrictedUnderlierChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.underlierSingleOrderRestrictedUnderlierChangeRequestUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.efidSingleOrderRestrictedUnderlierChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.restricted = one] : one \in Sample(1) }

(***************************************************************************)
(* Cp Gross Notional Threshold Change Request Message: 40 bytes            *)
(***************************************************************************)

CpGrossNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpGrossNotionalThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                     : Sample(2),
      priceInDollars                                                  : Sample(8) ]

EncodeCpGrossNotionalThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId
        \o message.underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional
        \o message.efidCpGrossNotionalThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpGrossNotionalThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpGrossNotionalThresholdChangeRequestEfidOptional == ReadBytes(underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpGrossNotionalThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpGrossNotionalThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId             |-> clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId.value,
         underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional |-> underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional.value,
         efidCpGrossNotionalThresholdChangeRequestEfidOptional           |-> efidCpGrossNotionalThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                     |-> riskGroupId.value,
         priceInDollars                                                  |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpGrossNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpGrossNotionalThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                     |-> [i \in 1 .. 2 |-> 0],
      priceInDollars                                                  |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Gross Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpGrossNotionalThresholdChangeRequestMessage ==
    { ZeroCpGrossNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.clOrdIdCpGrossNotionalThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.underlierCpGrossNotionalThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.efidCpGrossNotionalThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Gross Notional Threshold Change Request Message: 40     *)
(* bytes                                                                   *)
(***************************************************************************)

CpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                                : Sample(2),
      priceInDollars                                                             : Sample(8) ]

EncodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId
        \o message.underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional
        \o message.efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional == ReadBytes(underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId             |-> clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId.value,
         underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional |-> underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional.value,
         efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional           |-> efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                                |-> riskGroupId.value,
         priceInDollars                                                             |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                                |-> [i \in 1 .. 2 |-> 0],
      priceInDollars                                                             |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Gross Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    { ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.clOrdIdCpMarketOrderGrossNotionalThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.underlierCpMarketOrderGrossNotionalThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.efidCpMarketOrderGrossNotionalThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Net Notional Threshold Change Request Message: 40 bytes              *)
(***************************************************************************)

CpNetNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpNetNotionalThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpNetNotionalThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpNetNotionalThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                   : Sample(2),
      priceInDollars                                                : Sample(8) ]

EncodeCpNetNotionalThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpNetNotionalThresholdChangeRequestClOrdId
        \o message.underlierCpNetNotionalThresholdChangeRequestUnderlierOptional
        \o message.efidCpNetNotionalThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpNetNotionalThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpNetNotionalThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpNetNotionalThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpNetNotionalThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpNetNotionalThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpNetNotionalThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpNetNotionalThresholdChangeRequestEfidOptional == ReadBytes(underlierCpNetNotionalThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpNetNotionalThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpNetNotionalThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clOrdIdCpNetNotionalThresholdChangeRequestClOrdId             |-> clOrdIdCpNetNotionalThresholdChangeRequestClOrdId.value,
         underlierCpNetNotionalThresholdChangeRequestUnderlierOptional |-> underlierCpNetNotionalThresholdChangeRequestUnderlierOptional.value,
         efidCpNetNotionalThresholdChangeRequestEfidOptional           |-> efidCpNetNotionalThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                   |-> riskGroupId.value,
         priceInDollars                                                |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpNetNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpNetNotionalThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpNetNotionalThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpNetNotionalThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                   |-> [i \in 1 .. 2 |-> 0],
      priceInDollars                                                |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Net Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpNetNotionalThresholdChangeRequestMessage ==
    { ZeroCpNetNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.clOrdIdCpNetNotionalThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.underlierCpNetNotionalThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.efidCpNetNotionalThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Net Notional Threshold Change Request Message: 40 bytes *)
(***************************************************************************)

CpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                              : Sample(2),
      priceInDollars                                                           : Sample(8) ]

EncodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId
        \o message.underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional
        \o message.efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional == ReadBytes(underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId             |-> clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId.value,
         underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional |-> underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional.value,
         efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional           |-> efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                              |-> riskGroupId.value,
         priceInDollars                                                           |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    [ clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                              |-> [i \in 1 .. 2 |-> 0],
      priceInDollars                                                           |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Net Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    { ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.clOrdIdCpMarketOrderNetNotionalThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.underlierCpMarketOrderNetNotionalThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.efidCpMarketOrderNetNotionalThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Duplicate Order Threshold Change Request Message: 41 bytes           *)
(***************************************************************************)

CpDuplicateOrderThresholdChangeRequestMessage ==
    [ clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpDuplicateOrderThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                      : Sample(2),
      maxDupOrders                                                     : Sample(4),
      useOrderPriceInDupCheckOptional                                  : Sample(1),
      periodInMilliSeconds                                             : Sample(4) ]

EncodeCpDuplicateOrderThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId
        \o message.underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional
        \o message.efidCpDuplicateOrderThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.maxDupOrders
        \o message.useOrderPriceInDupCheckOptional
        \o message.periodInMilliSeconds

DecodeCpDuplicateOrderThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpDuplicateOrderThresholdChangeRequestEfidOptional == ReadBytes(underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpDuplicateOrderThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpDuplicateOrderThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxDupOrders == ReadBytes(riskGroupId.rest, 4) IN IF ~maxDupOrders.ok THEN Fail ELSE
    LET useOrderPriceInDupCheckOptional == ReadBytes(maxDupOrders.rest, 1) IN IF ~useOrderPriceInDupCheckOptional.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(useOrderPriceInDupCheckOptional.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId             |-> clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId.value,
         underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional |-> underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional.value,
         efidCpDuplicateOrderThresholdChangeRequestEfidOptional           |-> efidCpDuplicateOrderThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                      |-> riskGroupId.value,
         maxDupOrders                                                     |-> maxDupOrders.value,
         useOrderPriceInDupCheckOptional                                  |-> useOrderPriceInDupCheckOptional.value,
         periodInMilliSeconds                                             |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpDuplicateOrderThresholdChangeRequestMessage ==
    [ clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpDuplicateOrderThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                      |-> [i \in 1 .. 2 |-> 0],
      maxDupOrders                                                     |-> [i \in 1 .. 4 |-> 0],
      useOrderPriceInDupCheckOptional                                  |-> [i \in 1 .. 1 |-> 0],
      periodInMilliSeconds                                             |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Duplicate Order Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpDuplicateOrderThresholdChangeRequestMessage ==
    { ZeroCpDuplicateOrderThresholdChangeRequestMessage }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.clOrdIdCpDuplicateOrderThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.underlierCpDuplicateOrderThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.efidCpDuplicateOrderThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.maxDupOrders = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.useOrderPriceInDupCheckOptional = one] : one \in Sample(1) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Order Rate Threshold Change Request Message: 40 bytes                *)
(***************************************************************************)

CpOrderRateThresholdChangeRequestMessage ==
    [ clOrdIdCpOrderRateThresholdChangeRequestClOrdId             : Sample(20),
      underlierCpOrderRateThresholdChangeRequestUnderlierOptional : Sample(6),
      efidCpOrderRateThresholdChangeRequestEfidOptional           : Sample(4),
      riskGroupId                                                 : Sample(2),
      maxOrderMsgs                                                : Sample(4),
      periodInMilliSeconds                                        : Sample(4) ]

EncodeCpOrderRateThresholdChangeRequestMessage(message) ==
    message.clOrdIdCpOrderRateThresholdChangeRequestClOrdId
        \o message.underlierCpOrderRateThresholdChangeRequestUnderlierOptional
        \o message.efidCpOrderRateThresholdChangeRequestEfidOptional
        \o message.riskGroupId
        \o message.maxOrderMsgs
        \o message.periodInMilliSeconds

DecodeCpOrderRateThresholdChangeRequestMessage(bytes) ==
    LET clOrdIdCpOrderRateThresholdChangeRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpOrderRateThresholdChangeRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpOrderRateThresholdChangeRequestUnderlierOptional == ReadBytes(clOrdIdCpOrderRateThresholdChangeRequestClOrdId.rest, 6) IN IF ~underlierCpOrderRateThresholdChangeRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpOrderRateThresholdChangeRequestEfidOptional == ReadBytes(underlierCpOrderRateThresholdChangeRequestUnderlierOptional.rest, 4) IN IF ~efidCpOrderRateThresholdChangeRequestEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidCpOrderRateThresholdChangeRequestEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxOrderMsgs == ReadBytes(riskGroupId.rest, 4) IN IF ~maxOrderMsgs.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(maxOrderMsgs.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clOrdIdCpOrderRateThresholdChangeRequestClOrdId             |-> clOrdIdCpOrderRateThresholdChangeRequestClOrdId.value,
         underlierCpOrderRateThresholdChangeRequestUnderlierOptional |-> underlierCpOrderRateThresholdChangeRequestUnderlierOptional.value,
         efidCpOrderRateThresholdChangeRequestEfidOptional           |-> efidCpOrderRateThresholdChangeRequestEfidOptional.value,
         riskGroupId                                                 |-> riskGroupId.value,
         maxOrderMsgs                                                |-> maxOrderMsgs.value,
         periodInMilliSeconds                                        |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpOrderRateThresholdChangeRequestMessage ==
    [ clOrdIdCpOrderRateThresholdChangeRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpOrderRateThresholdChangeRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpOrderRateThresholdChangeRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                 |-> [i \in 1 .. 2 |-> 0],
      maxOrderMsgs                                                |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds                                        |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Order Rate Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpOrderRateThresholdChangeRequestMessage ==
    { ZeroCpOrderRateThresholdChangeRequestMessage }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.clOrdIdCpOrderRateThresholdChangeRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.underlierCpOrderRateThresholdChangeRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.efidCpOrderRateThresholdChangeRequestEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.maxOrderMsgs = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Clear All Breaches Request Message: 20 bytes                         *)
(***************************************************************************)

CpClearAllBreachesRequestMessage ==
    [ clOrdIdCpClearAllBreachesRequestClOrdId : Sample(20) ]

EncodeCpClearAllBreachesRequestMessage(message) ==
    message.clOrdIdCpClearAllBreachesRequestClOrdId

DecodeCpClearAllBreachesRequestMessage(bytes) ==
    LET clOrdIdCpClearAllBreachesRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpClearAllBreachesRequestClOrdId.ok THEN Fail ELSE
    Ok([ clOrdIdCpClearAllBreachesRequestClOrdId |-> clOrdIdCpClearAllBreachesRequestClOrdId.value ], clOrdIdCpClearAllBreachesRequestClOrdId.rest)

ZeroCpClearAllBreachesRequestMessage ==
    [ clOrdIdCpClearAllBreachesRequestClOrdId |-> [i \in 1 .. 20 |-> 0] ]

(* Cp Clear All Breaches Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearAllBreachesRequestMessage ==
    { ZeroCpClearAllBreachesRequestMessage }
        \cup { [ZeroCpClearAllBreachesRequestMessage EXCEPT !.clOrdIdCpClearAllBreachesRequestClOrdId = one] : one \in Sample(20) }

(***************************************************************************)
(* Cp Clear All Breaches By Efid Or Underlier Request Message: 30 bytes    *)
(***************************************************************************)

CpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    [ clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId             : Sample(20),
      underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional : Sample(6),
      efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional           : Sample(4) ]

EncodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(message) ==
    message.clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId
        \o message.underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional
        \o message.efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional

DecodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(bytes) ==
    LET clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId.ok THEN Fail ELSE
    LET underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional == ReadBytes(clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId.rest, 6) IN IF ~underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional.ok THEN Fail ELSE
    LET efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional == ReadBytes(underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional.rest, 4) IN IF ~efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional.ok THEN Fail ELSE
    Ok([ clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId             |-> clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId.value,
         underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional |-> underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional.value,
         efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional           |-> efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional.value ], efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional.rest)

ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    [ clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional           |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Clear All Breaches By Efid Or Underlier Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    { ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage }
        \cup { [ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage EXCEPT !.clOrdIdCpClearAllBreachesByEfidOrUnderlierRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage EXCEPT !.underlierCpClearAllBreachesByEfidOrUnderlierRequestUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage EXCEPT !.efidCpClearAllBreachesByEfidOrUnderlierRequestEfidOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledge All Request Message: 30 bytes                   *)
(***************************************************************************)

ActiveRiskAcknowledgeAllRequestMessage ==
    [ clOrdIdActiveRiskAcknowledgeAllRequestClOrdId     : Sample(20),
      underlierActiveRiskAcknowledgeAllRequestUnderlier : Sample(6),
      efidActiveRiskAcknowledgeAllRequestEfid           : Sample(4) ]

EncodeActiveRiskAcknowledgeAllRequestMessage(message) ==
    message.clOrdIdActiveRiskAcknowledgeAllRequestClOrdId
        \o message.underlierActiveRiskAcknowledgeAllRequestUnderlier
        \o message.efidActiveRiskAcknowledgeAllRequestEfid

DecodeActiveRiskAcknowledgeAllRequestMessage(bytes) ==
    LET clOrdIdActiveRiskAcknowledgeAllRequestClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdActiveRiskAcknowledgeAllRequestClOrdId.ok THEN Fail ELSE
    LET underlierActiveRiskAcknowledgeAllRequestUnderlier == ReadBytes(clOrdIdActiveRiskAcknowledgeAllRequestClOrdId.rest, 6) IN IF ~underlierActiveRiskAcknowledgeAllRequestUnderlier.ok THEN Fail ELSE
    LET efidActiveRiskAcknowledgeAllRequestEfid == ReadBytes(underlierActiveRiskAcknowledgeAllRequestUnderlier.rest, 4) IN IF ~efidActiveRiskAcknowledgeAllRequestEfid.ok THEN Fail ELSE
    Ok([ clOrdIdActiveRiskAcknowledgeAllRequestClOrdId     |-> clOrdIdActiveRiskAcknowledgeAllRequestClOrdId.value,
         underlierActiveRiskAcknowledgeAllRequestUnderlier |-> underlierActiveRiskAcknowledgeAllRequestUnderlier.value,
         efidActiveRiskAcknowledgeAllRequestEfid           |-> efidActiveRiskAcknowledgeAllRequestEfid.value ], efidActiveRiskAcknowledgeAllRequestEfid.rest)

ZeroActiveRiskAcknowledgeAllRequestMessage ==
    [ clOrdIdActiveRiskAcknowledgeAllRequestClOrdId     |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskAcknowledgeAllRequestUnderlier |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskAcknowledgeAllRequestEfid           |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledge All Request Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgeAllRequestMessage ==
    { ZeroActiveRiskAcknowledgeAllRequestMessage }
        \cup { [ZeroActiveRiskAcknowledgeAllRequestMessage EXCEPT !.clOrdIdActiveRiskAcknowledgeAllRequestClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgeAllRequestMessage EXCEPT !.underlierActiveRiskAcknowledgeAllRequestUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgeAllRequestMessage EXCEPT !.efidActiveRiskAcknowledgeAllRequestEfid = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Threshold State Message: 38 bytes                           *)
(***************************************************************************)

ActiveRiskThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlier         : Sample(6),
      efid              : Sample(4),
      thresholdQuantity : Sample(4),
      unackedQuantity   : Sample(4) ]

EncodeActiveRiskThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlier
        \o message.efid
        \o message.thresholdQuantity
        \o message.unackedQuantity

DecodeActiveRiskThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordidOptional.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efid.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    LET unackedQuantity == ReadBytes(thresholdQuantity.rest, 4) IN IF ~unackedQuantity.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlier         |-> underlier.value,
         efid              |-> efid.value,
         thresholdQuantity |-> thresholdQuantity.value,
         unackedQuantity   |-> unackedQuantity.value ], unackedQuantity.rest)

ZeroActiveRiskThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlier         |-> [i \in 1 .. 6 |-> 0],
      efid              |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity |-> [i \in 1 .. 4 |-> 0],
      unackedQuantity   |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdStateMessage ==
    { ZeroActiveRiskThresholdStateMessage }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.unackedQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Threshold Change Rejected Message: 36 bytes                 *)
(***************************************************************************)

ActiveRiskThresholdChangeRejectedMessage ==
    [ clOrdIdActiveRiskThresholdChangeRejectedClOrdId             : Sample(20),
      underlierActiveRiskThresholdChangeRejectedUnderlierOptional : Sample(6),
      efidActiveRiskThresholdChangeRejectedEfidOptional           : Sample(4),
      thresholdQuantity                                           : Sample(4),
      rejectReason                                                : Sample(2) ]

EncodeActiveRiskThresholdChangeRejectedMessage(message) ==
    message.clOrdIdActiveRiskThresholdChangeRejectedClOrdId
        \o message.underlierActiveRiskThresholdChangeRejectedUnderlierOptional
        \o message.efidActiveRiskThresholdChangeRejectedEfidOptional
        \o message.thresholdQuantity
        \o message.rejectReason

DecodeActiveRiskThresholdChangeRejectedMessage(bytes) ==
    LET clOrdIdActiveRiskThresholdChangeRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdActiveRiskThresholdChangeRejectedClOrdId.ok THEN Fail ELSE
    LET underlierActiveRiskThresholdChangeRejectedUnderlierOptional == ReadBytes(clOrdIdActiveRiskThresholdChangeRejectedClOrdId.rest, 6) IN IF ~underlierActiveRiskThresholdChangeRejectedUnderlierOptional.ok THEN Fail ELSE
    LET efidActiveRiskThresholdChangeRejectedEfidOptional == ReadBytes(underlierActiveRiskThresholdChangeRejectedUnderlierOptional.rest, 4) IN IF ~efidActiveRiskThresholdChangeRejectedEfidOptional.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidActiveRiskThresholdChangeRejectedEfidOptional.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(thresholdQuantity.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdActiveRiskThresholdChangeRejectedClOrdId             |-> clOrdIdActiveRiskThresholdChangeRejectedClOrdId.value,
         underlierActiveRiskThresholdChangeRejectedUnderlierOptional |-> underlierActiveRiskThresholdChangeRejectedUnderlierOptional.value,
         efidActiveRiskThresholdChangeRejectedEfidOptional           |-> efidActiveRiskThresholdChangeRejectedEfidOptional.value,
         thresholdQuantity                                           |-> thresholdQuantity.value,
         rejectReason                                                |-> rejectReason.value ], rejectReason.rest)

ZeroActiveRiskThresholdChangeRejectedMessage ==
    [ clOrdIdActiveRiskThresholdChangeRejectedClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskThresholdChangeRejectedUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskThresholdChangeRejectedEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity                                           |-> [i \in 1 .. 4 |-> 0],
      rejectReason                                                |-> [i \in 1 .. 2 |-> 0] ]

(* Active Risk Threshold Change Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdChangeRejectedMessage ==
    { ZeroActiveRiskThresholdChangeRejectedMessage }
        \cup { [ZeroActiveRiskThresholdChangeRejectedMessage EXCEPT !.clOrdIdActiveRiskThresholdChangeRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdChangeRejectedMessage EXCEPT !.underlierActiveRiskThresholdChangeRejectedUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdChangeRejectedMessage EXCEPT !.efidActiveRiskThresholdChangeRejectedEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeRejectedMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Active Risk Acknowledged Message: 38 bytes                              *)
(***************************************************************************)

ActiveRiskAcknowledgedMessage ==
    [ clordid         : Sample(20),
      underlier       : Sample(6),
      efid            : Sample(4),
      quantity        : Sample(4),
      unackedQuantity : Sample(4) ]

EncodeActiveRiskAcknowledgedMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efid
        \o message.quantity
        \o message.unackedQuantity

DecodeActiveRiskAcknowledgedMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET quantity == ReadBytes(efid.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET unackedQuantity == ReadBytes(quantity.rest, 4) IN IF ~unackedQuantity.ok THEN Fail ELSE
    Ok([ clordid         |-> clordid.value,
         underlier       |-> underlier.value,
         efid            |-> efid.value,
         quantity        |-> quantity.value,
         unackedQuantity |-> unackedQuantity.value ], unackedQuantity.rest)

ZeroActiveRiskAcknowledgedMessage ==
    [ clordid         |-> [i \in 1 .. 20 |-> 0],
      underlier       |-> [i \in 1 .. 6 |-> 0],
      efid            |-> [i \in 1 .. 4 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      unackedQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledged Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgedMessage ==
    { ZeroActiveRiskAcknowledgedMessage }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.unackedQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledge Rejected Message: 36 bytes                      *)
(***************************************************************************)

ActiveRiskAcknowledgeRejectedMessage ==
    [ clOrdIdActiveRiskAcknowledgeRejectedClOrdId     : Sample(20),
      underlierActiveRiskAcknowledgeRejectedUnderlier : Sample(6),
      efidActiveRiskAcknowledgeRejectedEfid           : Sample(4),
      thresholdQuantity                               : Sample(4),
      rejectReason                                    : Sample(2) ]

EncodeActiveRiskAcknowledgeRejectedMessage(message) ==
    message.clOrdIdActiveRiskAcknowledgeRejectedClOrdId
        \o message.underlierActiveRiskAcknowledgeRejectedUnderlier
        \o message.efidActiveRiskAcknowledgeRejectedEfid
        \o message.thresholdQuantity
        \o message.rejectReason

DecodeActiveRiskAcknowledgeRejectedMessage(bytes) ==
    LET clOrdIdActiveRiskAcknowledgeRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdActiveRiskAcknowledgeRejectedClOrdId.ok THEN Fail ELSE
    LET underlierActiveRiskAcknowledgeRejectedUnderlier == ReadBytes(clOrdIdActiveRiskAcknowledgeRejectedClOrdId.rest, 6) IN IF ~underlierActiveRiskAcknowledgeRejectedUnderlier.ok THEN Fail ELSE
    LET efidActiveRiskAcknowledgeRejectedEfid == ReadBytes(underlierActiveRiskAcknowledgeRejectedUnderlier.rest, 4) IN IF ~efidActiveRiskAcknowledgeRejectedEfid.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidActiveRiskAcknowledgeRejectedEfid.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(thresholdQuantity.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdActiveRiskAcknowledgeRejectedClOrdId     |-> clOrdIdActiveRiskAcknowledgeRejectedClOrdId.value,
         underlierActiveRiskAcknowledgeRejectedUnderlier |-> underlierActiveRiskAcknowledgeRejectedUnderlier.value,
         efidActiveRiskAcknowledgeRejectedEfid           |-> efidActiveRiskAcknowledgeRejectedEfid.value,
         thresholdQuantity                               |-> thresholdQuantity.value,
         rejectReason                                    |-> rejectReason.value ], rejectReason.rest)

ZeroActiveRiskAcknowledgeRejectedMessage ==
    [ clOrdIdActiveRiskAcknowledgeRejectedClOrdId     |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskAcknowledgeRejectedUnderlier |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskAcknowledgeRejectedEfid           |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity                               |-> [i \in 1 .. 4 |-> 0],
      rejectReason                                    |-> [i \in 1 .. 2 |-> 0] ]

(* Active Risk Acknowledge Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgeRejectedMessage ==
    { ZeroActiveRiskAcknowledgeRejectedMessage }
        \cup { [ZeroActiveRiskAcknowledgeRejectedMessage EXCEPT !.clOrdIdActiveRiskAcknowledgeRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgeRejectedMessage EXCEPT !.underlierActiveRiskAcknowledgeRejectedUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgeRejectedMessage EXCEPT !.efidActiveRiskAcknowledgeRejectedEfid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgeRejectedMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgeRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Active Risk Quantity Update Notification Message: 67 bytes              *)
(***************************************************************************)

ActiveRiskQuantityUpdateNotificationMessage ==
    [ sendingTime      : Sample(8),
      transactTime     : Sample(8),
      orderId          : Sample(8),
      trdMatchId       : Sample(8),
      efid             : Sample(4),
      underlier        : Sample(6),
      optionSecurityId : Sample(8),
      side             : Sample(1),
      lastPx           : Sample(8),
      lastQty          : Sample(4),
      unackedQuantity  : Sample(4) ]

EncodeActiveRiskQuantityUpdateNotificationMessage(message) ==
    message.sendingTime
        \o message.transactTime
        \o message.orderId
        \o message.trdMatchId
        \o message.efid
        \o message.underlier
        \o message.optionSecurityId
        \o message.side
        \o message.lastPx
        \o message.lastQty
        \o message.unackedQuantity

DecodeActiveRiskQuantityUpdateNotificationMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(sendingTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(orderId.rest, 8) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET efid == ReadBytes(trdMatchId.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET underlier == ReadBytes(efid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET optionSecurityId == ReadBytes(underlier.rest, 8) IN IF ~optionSecurityId.ok THEN Fail ELSE
    LET side == ReadBytes(optionSecurityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET lastPx == ReadBytes(side.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET unackedQuantity == ReadBytes(lastQty.rest, 4) IN IF ~unackedQuantity.ok THEN Fail ELSE
    Ok([ sendingTime      |-> sendingTime.value,
         transactTime     |-> transactTime.value,
         orderId          |-> orderId.value,
         trdMatchId       |-> trdMatchId.value,
         efid             |-> efid.value,
         underlier        |-> underlier.value,
         optionSecurityId |-> optionSecurityId.value,
         side             |-> side.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         unackedQuantity  |-> unackedQuantity.value ], unackedQuantity.rest)

ZeroActiveRiskQuantityUpdateNotificationMessage ==
    [ sendingTime      |-> [i \in 1 .. 8 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      trdMatchId       |-> [i \in 1 .. 8 |-> 0],
      efid             |-> [i \in 1 .. 4 |-> 0],
      underlier        |-> [i \in 1 .. 6 |-> 0],
      optionSecurityId |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 4 |-> 0],
      unackedQuantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Quantity Update Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskQuantityUpdateNotificationMessage ==
    { ZeroActiveRiskQuantityUpdateNotificationMessage }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.trdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.optionSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.unackedQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Volume Threshold State Message: 44 bytes                             *)
(***************************************************************************)

CpVolumeThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      volume               : Sample(8),
      periodInMilliSeconds : Sample(4) ]

EncodeCpVolumeThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.volume
        \o message.periodInMilliSeconds

DecodeCpVolumeThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET volume == ReadBytes(riskGroupId.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(volume.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         volume               |-> volume.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpVolumeThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      volume               |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Volume Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpVolumeThresholdStateMessage ==
    { ZeroCpVolumeThresholdStateMessage }
        \cup { [ZeroCpVolumeThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpVolumeThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpVolumeThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpVolumeThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpVolumeThresholdStateMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroCpVolumeThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Executed Notional Threshold State Message: 44 bytes                  *)
(***************************************************************************)

CpExecutedNotionalThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      priceInDollars       : Sample(8),
      periodInMilliSeconds : Sample(4) ]

EncodeCpExecutedNotionalThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars
        \o message.periodInMilliSeconds

DecodeCpExecutedNotionalThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(priceInDollars.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         priceInDollars       |-> priceInDollars.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpExecutedNotionalThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      priceInDollars       |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Executed Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpExecutedNotionalThresholdStateMessage ==
    { ZeroCpExecutedNotionalThresholdStateMessage }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Total Executions Threshold State Message: 40 bytes                   *)
(***************************************************************************)

CpTotalExecutionsThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      totalExecutions      : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpTotalExecutionsThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.totalExecutions
        \o message.periodInMilliSeconds

DecodeCpTotalExecutionsThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET totalExecutions == ReadBytes(riskGroupId.rest, 4) IN IF ~totalExecutions.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(totalExecutions.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         totalExecutions      |-> totalExecutions.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpTotalExecutionsThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      totalExecutions      |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Total Executions Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpTotalExecutionsThresholdStateMessage ==
    { ZeroCpTotalExecutionsThresholdStateMessage }
        \cup { [ZeroCpTotalExecutionsThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpTotalExecutionsThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpTotalExecutionsThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpTotalExecutionsThresholdStateMessage EXCEPT !.totalExecutions = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Percent Outstanding Contracts Threshold State Message: 38 bytes      *)
(***************************************************************************)

CpPercentOutstandingContractsThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      percent              : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpPercentOutstandingContractsThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.percent
        \o message.periodInMilliSeconds

DecodeCpPercentOutstandingContractsThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET percent == ReadBytes(efidOptional.rest, 4) IN IF ~percent.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(percent.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         percent              |-> percent.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpPercentOutstandingContractsThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      percent              |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Percent Outstanding Contracts Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpPercentOutstandingContractsThresholdStateMessage ==
    { ZeroCpPercentOutstandingContractsThresholdStateMessage }
        \cup { [ZeroCpPercentOutstandingContractsThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdStateMessage EXCEPT !.percent = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Breach Count Threshold State Message: 40 bytes                       *)
(***************************************************************************)

CpBreachCountThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      count                : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpBreachCountThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.count
        \o message.periodInMilliSeconds

DecodeCpBreachCountThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET count == ReadBytes(riskGroupId.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(count.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         count                |-> count.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpBreachCountThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      count                |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Breach Count Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpBreachCountThresholdStateMessage ==
    { ZeroCpBreachCountThresholdStateMessage }
        \cup { [ZeroCpBreachCountThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpBreachCountThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpBreachCountThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpBreachCountThresholdStateMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Manual Cp Breach Trigger Pending Message: 32 bytes                      *)
(***************************************************************************)

ManualCpBreachTriggerPendingMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2) ]

EncodeManualCpBreachTriggerPendingMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId

DecodeManualCpBreachTriggerPendingMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value ], riskGroupId.rest)

ZeroManualCpBreachTriggerPendingMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0] ]

(* Manual Cp Breach Trigger Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerPendingMessage ==
    { ZeroManualCpBreachTriggerPendingMessage }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Manual Cp Breach Trigger Done Message: 44 bytes                         *)
(***************************************************************************)

ManualCpBreachTriggerDoneMessage ==
    [ clordid             : Sample(20),
      underlierOptional   : Sample(6),
      efidOptional        : Sample(4),
      riskGroupId         : Sample(2),
      breachId            : Sample(8),
      totalAffectedOrders : Sample(4) ]

EncodeManualCpBreachTriggerDoneMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.breachId
        \o message.totalAffectedOrders

DecodeManualCpBreachTriggerDoneMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET breachId == ReadBytes(riskGroupId.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    LET totalAffectedOrders == ReadBytes(breachId.rest, 4) IN IF ~totalAffectedOrders.ok THEN Fail ELSE
    Ok([ clordid             |-> clordid.value,
         underlierOptional   |-> underlierOptional.value,
         efidOptional        |-> efidOptional.value,
         riskGroupId         |-> riskGroupId.value,
         breachId            |-> breachId.value,
         totalAffectedOrders |-> totalAffectedOrders.value ], totalAffectedOrders.rest)

ZeroManualCpBreachTriggerDoneMessage ==
    [ clordid             |-> [i \in 1 .. 20 |-> 0],
      underlierOptional   |-> [i \in 1 .. 6 |-> 0],
      efidOptional        |-> [i \in 1 .. 4 |-> 0],
      riskGroupId         |-> [i \in 1 .. 2 |-> 0],
      breachId            |-> [i \in 1 .. 8 |-> 0],
      totalAffectedOrders |-> [i \in 1 .. 4 |-> 0] ]

(* Manual Cp Breach Trigger Done Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerDoneMessage ==
    { ZeroManualCpBreachTriggerDoneMessage }
        \cup { [ZeroManualCpBreachTriggerDoneMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerDoneMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerDoneMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerDoneMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerDoneMessage EXCEPT !.breachId = one] : one \in Sample(8) }
        \cup { [ZeroManualCpBreachTriggerDoneMessage EXCEPT !.totalAffectedOrders = one] : one \in Sample(4) }

(***************************************************************************)
(* Risk Threshold Update Rejected Message: 23 bytes                        *)
(***************************************************************************)

RiskThresholdUpdateRejectedMessage ==
    [ clOrdIdRiskThresholdUpdateRejectedClOrdId : Sample(20),
      riskType                                  : Sample(1),
      rejectReason                              : Sample(2) ]

EncodeRiskThresholdUpdateRejectedMessage(message) ==
    message.clOrdIdRiskThresholdUpdateRejectedClOrdId
        \o message.riskType
        \o message.rejectReason

DecodeRiskThresholdUpdateRejectedMessage(bytes) ==
    LET clOrdIdRiskThresholdUpdateRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdRiskThresholdUpdateRejectedClOrdId.ok THEN Fail ELSE
    LET riskType == ReadBytes(clOrdIdRiskThresholdUpdateRejectedClOrdId.rest, 1) IN IF ~riskType.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(riskType.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdRiskThresholdUpdateRejectedClOrdId |-> clOrdIdRiskThresholdUpdateRejectedClOrdId.value,
         riskType                                  |-> riskType.value,
         rejectReason                              |-> rejectReason.value ], rejectReason.rest)

ZeroRiskThresholdUpdateRejectedMessage ==
    [ clOrdIdRiskThresholdUpdateRejectedClOrdId |-> [i \in 1 .. 20 |-> 0],
      riskType                                  |-> [i \in 1 .. 1 |-> 0],
      rejectReason                              |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Threshold Update Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskThresholdUpdateRejectedMessage ==
    { ZeroRiskThresholdUpdateRejectedMessage }
        \cup { [ZeroRiskThresholdUpdateRejectedMessage EXCEPT !.clOrdIdRiskThresholdUpdateRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroRiskThresholdUpdateRejectedMessage EXCEPT !.riskType = one] : one \in Sample(1) }
        \cup { [ZeroRiskThresholdUpdateRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Passive Risk Threshold Notification Message: 30 bytes                   *)
(***************************************************************************)

PassiveRiskThresholdNotificationMessage ==
    [ underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      ruleType          : Sample(1),
      latestPercentage  : Sample(1),
      breachIdOptional  : Sample(8),
      transactTime      : Sample(8) ]

EncodePassiveRiskThresholdNotificationMessage(message) ==
    message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.ruleType
        \o message.latestPercentage
        \o message.breachIdOptional
        \o message.transactTime

DecodePassiveRiskThresholdNotificationMessage(bytes) ==
    LET underlierOptional == ReadBytes(bytes, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET ruleType == ReadBytes(riskGroupId.rest, 1) IN IF ~ruleType.ok THEN Fail ELSE
    LET latestPercentage == ReadBytes(ruleType.rest, 1) IN IF ~latestPercentage.ok THEN Fail ELSE
    LET breachIdOptional == ReadBytes(latestPercentage.rest, 8) IN IF ~breachIdOptional.ok THEN Fail ELSE
    LET transactTime == ReadBytes(breachIdOptional.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         ruleType          |-> ruleType.value,
         latestPercentage  |-> latestPercentage.value,
         breachIdOptional  |-> breachIdOptional.value,
         transactTime      |-> transactTime.value ], transactTime.rest)

ZeroPassiveRiskThresholdNotificationMessage ==
    [ underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      ruleType          |-> [i \in 1 .. 1 |-> 0],
      latestPercentage  |-> [i \in 1 .. 1 |-> 0],
      breachIdOptional  |-> [i \in 1 .. 8 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Passive Risk Threshold Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedPassiveRiskThresholdNotificationMessage ==
    { ZeroPassiveRiskThresholdNotificationMessage }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.ruleType = one] : one \in Sample(1) }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.latestPercentage = one] : one \in Sample(1) }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.breachIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroPassiveRiskThresholdNotificationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Allow Iso Orders State Message: 33 bytes                   *)
(***************************************************************************)

SingleOrderAllowIsoOrdersStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowIsoOrders    : Sample(1) ]

EncodeSingleOrderAllowIsoOrdersStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowIsoOrders

DecodeSingleOrderAllowIsoOrdersStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowIsoOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowIsoOrders.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         allowIsoOrders    |-> allowIsoOrders.value ], allowIsoOrders.rest)

ZeroSingleOrderAllowIsoOrdersStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowIsoOrders    |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Iso Orders State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowIsoOrdersStateMessage ==
    { ZeroSingleOrderAllowIsoOrdersStateMessage }
        \cup { [ZeroSingleOrderAllowIsoOrdersStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowIsoOrdersStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowIsoOrdersStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowIsoOrdersStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowIsoOrdersStateMessage EXCEPT !.allowIsoOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Allow Orders In Crossed Market State Message: 33 bytes     *)
(***************************************************************************)

SingleOrderAllowOrdersInCrossedMarketStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowOrders       : Sample(1) ]

EncodeSingleOrderAllowOrdersInCrossedMarketStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowOrders

DecodeSingleOrderAllowOrdersInCrossedMarketStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowOrders.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         allowOrders       |-> allowOrders.value ], allowOrders.rest)

ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowOrders       |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Orders In Crossed Market State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowOrdersInCrossedMarketStateMessage ==
    { ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketStateMessage EXCEPT !.allowOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Max Notional Threshold State Message: 40 bytes             *)
(***************************************************************************)

SingleOrderMaxNotionalThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxNotionalInDollars : Sample(8) ]

EncodeSingleOrderMaxNotionalThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxNotionalInDollars

DecodeSingleOrderMaxNotionalThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxNotionalInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~maxNotionalInDollars.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         maxNotionalInDollars |-> maxNotionalInDollars.value ], maxNotionalInDollars.rest)

ZeroSingleOrderMaxNotionalThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      maxNotionalInDollars |-> [i \in 1 .. 8 |-> 0] ]

(* Single Order Max Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxNotionalThresholdStateMessage ==
    { ZeroSingleOrderMaxNotionalThresholdStateMessage }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.maxNotionalInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Max Contracts Threshold State Message: 36 bytes            *)
(***************************************************************************)

SingleOrderMaxContractsThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      maxContracts      : Sample(4) ]

EncodeSingleOrderMaxContractsThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxContracts

DecodeSingleOrderMaxContractsThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxContracts == ReadBytes(riskGroupId.rest, 4) IN IF ~maxContracts.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         maxContracts      |-> maxContracts.value ], maxContracts.rest)

ZeroSingleOrderMaxContractsThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      maxContracts      |-> [i \in 1 .. 4 |-> 0] ]

(* Single Order Max Contracts Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxContractsThresholdStateMessage ==
    { ZeroSingleOrderMaxContractsThresholdStateMessage }
        \cup { [ZeroSingleOrderMaxContractsThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxContractsThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxContractsThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxContractsThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxContractsThresholdStateMessage EXCEPT !.maxContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Order Allow Market Orders State Message: 33 bytes                *)
(***************************************************************************)

SingleOrderAllowMarketOrdersStateMessage ==
    [ clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional     : Sample(20),
      underlierSingleOrderAllowMarketOrdersStateUnderlierOptional : Sample(6),
      efidSingleOrderAllowMarketOrdersStateEfidOptional           : Sample(4),
      riskGroupId                                                 : Sample(2),
      marketOrders                                                : Sample(1) ]

EncodeSingleOrderAllowMarketOrdersStateMessage(message) ==
    message.clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional
        \o message.underlierSingleOrderAllowMarketOrdersStateUnderlierOptional
        \o message.efidSingleOrderAllowMarketOrdersStateEfidOptional
        \o message.riskGroupId
        \o message.marketOrders

DecodeSingleOrderAllowMarketOrdersStateMessage(bytes) ==
    LET clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional.ok THEN Fail ELSE
    LET underlierSingleOrderAllowMarketOrdersStateUnderlierOptional == ReadBytes(clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional.rest, 6) IN IF ~underlierSingleOrderAllowMarketOrdersStateUnderlierOptional.ok THEN Fail ELSE
    LET efidSingleOrderAllowMarketOrdersStateEfidOptional == ReadBytes(underlierSingleOrderAllowMarketOrdersStateUnderlierOptional.rest, 4) IN IF ~efidSingleOrderAllowMarketOrdersStateEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderAllowMarketOrdersStateEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET marketOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~marketOrders.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional     |-> clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional.value,
         underlierSingleOrderAllowMarketOrdersStateUnderlierOptional |-> underlierSingleOrderAllowMarketOrdersStateUnderlierOptional.value,
         efidSingleOrderAllowMarketOrdersStateEfidOptional           |-> efidSingleOrderAllowMarketOrdersStateEfidOptional.value,
         riskGroupId                                                 |-> riskGroupId.value,
         marketOrders                                                |-> marketOrders.value ], marketOrders.rest)

ZeroSingleOrderAllowMarketOrdersStateMessage ==
    [ clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional     |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderAllowMarketOrdersStateUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderAllowMarketOrdersStateEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                                 |-> [i \in 1 .. 2 |-> 0],
      marketOrders                                                |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Market Orders State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowMarketOrdersStateMessage ==
    { ZeroSingleOrderAllowMarketOrdersStateMessage }
        \cup { [ZeroSingleOrderAllowMarketOrdersStateMessage EXCEPT !.clOrdIdSingleOrderAllowMarketOrdersStateClOrdIdOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowMarketOrdersStateMessage EXCEPT !.underlierSingleOrderAllowMarketOrdersStateUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowMarketOrdersStateMessage EXCEPT !.efidSingleOrderAllowMarketOrdersStateEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowMarketOrdersStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowMarketOrdersStateMessage EXCEPT !.marketOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Restricted Underlier State Message: 33 bytes               *)
(***************************************************************************)

SingleOrderRestrictedUnderlierStateMessage ==
    [ clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional : Sample(20),
      underlierSingleOrderRestrictedUnderlierStateUnderlier     : Sample(6),
      efidSingleOrderRestrictedUnderlierStateEfidOptional       : Sample(4),
      riskGroupId                                               : Sample(2),
      restricted                                                : Sample(1) ]

EncodeSingleOrderRestrictedUnderlierStateMessage(message) ==
    message.clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional
        \o message.underlierSingleOrderRestrictedUnderlierStateUnderlier
        \o message.efidSingleOrderRestrictedUnderlierStateEfidOptional
        \o message.riskGroupId
        \o message.restricted

DecodeSingleOrderRestrictedUnderlierStateMessage(bytes) ==
    LET clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional == ReadBytes(bytes, 20) IN IF ~clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional.ok THEN Fail ELSE
    LET underlierSingleOrderRestrictedUnderlierStateUnderlier == ReadBytes(clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional.rest, 6) IN IF ~underlierSingleOrderRestrictedUnderlierStateUnderlier.ok THEN Fail ELSE
    LET efidSingleOrderRestrictedUnderlierStateEfidOptional == ReadBytes(underlierSingleOrderRestrictedUnderlierStateUnderlier.rest, 4) IN IF ~efidSingleOrderRestrictedUnderlierStateEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidSingleOrderRestrictedUnderlierStateEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET restricted == ReadBytes(riskGroupId.rest, 1) IN IF ~restricted.ok THEN Fail ELSE
    Ok([ clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional |-> clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional.value,
         underlierSingleOrderRestrictedUnderlierStateUnderlier     |-> underlierSingleOrderRestrictedUnderlierStateUnderlier.value,
         efidSingleOrderRestrictedUnderlierStateEfidOptional       |-> efidSingleOrderRestrictedUnderlierStateEfidOptional.value,
         riskGroupId                                               |-> riskGroupId.value,
         restricted                                                |-> restricted.value ], restricted.rest)

ZeroSingleOrderRestrictedUnderlierStateMessage ==
    [ clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional |-> [i \in 1 .. 20 |-> 0],
      underlierSingleOrderRestrictedUnderlierStateUnderlier     |-> [i \in 1 .. 6 |-> 0],
      efidSingleOrderRestrictedUnderlierStateEfidOptional       |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                               |-> [i \in 1 .. 2 |-> 0],
      restricted                                                |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Restricted Underlier State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderRestrictedUnderlierStateMessage ==
    { ZeroSingleOrderRestrictedUnderlierStateMessage }
        \cup { [ZeroSingleOrderRestrictedUnderlierStateMessage EXCEPT !.clOrdIdSingleOrderRestrictedUnderlierStateClOrdIdOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderRestrictedUnderlierStateMessage EXCEPT !.underlierSingleOrderRestrictedUnderlierStateUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderRestrictedUnderlierStateMessage EXCEPT !.efidSingleOrderRestrictedUnderlierStateEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderRestrictedUnderlierStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderRestrictedUnderlierStateMessage EXCEPT !.restricted = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Settings Query Done Message: 24 bytes                              *)
(***************************************************************************)

RiskSettingsQueryDoneMessage ==
    [ clordid        : Sample(20),
      numberMsgsSent : Sample(4) ]

EncodeRiskSettingsQueryDoneMessage(message) ==
    message.clordid
        \o message.numberMsgsSent

DecodeRiskSettingsQueryDoneMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET numberMsgsSent == ReadBytes(clordid.rest, 4) IN IF ~numberMsgsSent.ok THEN Fail ELSE
    Ok([ clordid        |-> clordid.value,
         numberMsgsSent |-> numberMsgsSent.value ], numberMsgsSent.rest)

ZeroRiskSettingsQueryDoneMessage ==
    [ clordid        |-> [i \in 1 .. 20 |-> 0],
      numberMsgsSent |-> [i \in 1 .. 4 |-> 0] ]

(* Risk Settings Query Done Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskSettingsQueryDoneMessage ==
    { ZeroRiskSettingsQueryDoneMessage }
        \cup { [ZeroRiskSettingsQueryDoneMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroRiskSettingsQueryDoneMessage EXCEPT !.numberMsgsSent = one] : one \in Sample(4) }

(***************************************************************************)
(* Risk Settings Query Rejected Message: 22 bytes                          *)
(***************************************************************************)

RiskSettingsQueryRejectedMessage ==
    [ clOrdIdRiskSettingsQueryRejectedClOrdId : Sample(20),
      rejectReason                            : Sample(2) ]

EncodeRiskSettingsQueryRejectedMessage(message) ==
    message.clOrdIdRiskSettingsQueryRejectedClOrdId
        \o message.rejectReason

DecodeRiskSettingsQueryRejectedMessage(bytes) ==
    LET clOrdIdRiskSettingsQueryRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdRiskSettingsQueryRejectedClOrdId.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(clOrdIdRiskSettingsQueryRejectedClOrdId.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdRiskSettingsQueryRejectedClOrdId |-> clOrdIdRiskSettingsQueryRejectedClOrdId.value,
         rejectReason                            |-> rejectReason.value ], rejectReason.rest)

ZeroRiskSettingsQueryRejectedMessage ==
    [ clOrdIdRiskSettingsQueryRejectedClOrdId |-> [i \in 1 .. 20 |-> 0],
      rejectReason                            |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Settings Query Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskSettingsQueryRejectedMessage ==
    { ZeroRiskSettingsQueryRejectedMessage }
        \cup { [ZeroRiskSettingsQueryRejectedMessage EXCEPT !.clOrdIdRiskSettingsQueryRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroRiskSettingsQueryRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Manual Cp Breach Trigger Rejected Message: 34 bytes                     *)
(***************************************************************************)

ManualCpBreachTriggerRejectedMessage ==
    [ clOrdIdManualCpBreachTriggerRejectedClOrdId             : Sample(20),
      underlierManualCpBreachTriggerRejectedUnderlierOptional : Sample(6),
      efidManualCpBreachTriggerRejectedEfidOptional           : Sample(4),
      riskGroupId                                             : Sample(2),
      rejectReason                                            : Sample(2) ]

EncodeManualCpBreachTriggerRejectedMessage(message) ==
    message.clOrdIdManualCpBreachTriggerRejectedClOrdId
        \o message.underlierManualCpBreachTriggerRejectedUnderlierOptional
        \o message.efidManualCpBreachTriggerRejectedEfidOptional
        \o message.riskGroupId
        \o message.rejectReason

DecodeManualCpBreachTriggerRejectedMessage(bytes) ==
    LET clOrdIdManualCpBreachTriggerRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdManualCpBreachTriggerRejectedClOrdId.ok THEN Fail ELSE
    LET underlierManualCpBreachTriggerRejectedUnderlierOptional == ReadBytes(clOrdIdManualCpBreachTriggerRejectedClOrdId.rest, 6) IN IF ~underlierManualCpBreachTriggerRejectedUnderlierOptional.ok THEN Fail ELSE
    LET efidManualCpBreachTriggerRejectedEfidOptional == ReadBytes(underlierManualCpBreachTriggerRejectedUnderlierOptional.rest, 4) IN IF ~efidManualCpBreachTriggerRejectedEfidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidManualCpBreachTriggerRejectedEfidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(riskGroupId.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdManualCpBreachTriggerRejectedClOrdId             |-> clOrdIdManualCpBreachTriggerRejectedClOrdId.value,
         underlierManualCpBreachTriggerRejectedUnderlierOptional |-> underlierManualCpBreachTriggerRejectedUnderlierOptional.value,
         efidManualCpBreachTriggerRejectedEfidOptional           |-> efidManualCpBreachTriggerRejectedEfidOptional.value,
         riskGroupId                                             |-> riskGroupId.value,
         rejectReason                                            |-> rejectReason.value ], rejectReason.rest)

ZeroManualCpBreachTriggerRejectedMessage ==
    [ clOrdIdManualCpBreachTriggerRejectedClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierManualCpBreachTriggerRejectedUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidManualCpBreachTriggerRejectedEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                                             |-> [i \in 1 .. 2 |-> 0],
      rejectReason                                            |-> [i \in 1 .. 2 |-> 0] ]

(* Manual Cp Breach Trigger Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerRejectedMessage ==
    { ZeroManualCpBreachTriggerRejectedMessage }
        \cup { [ZeroManualCpBreachTriggerRejectedMessage EXCEPT !.clOrdIdManualCpBreachTriggerRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerRejectedMessage EXCEPT !.underlierManualCpBreachTriggerRejectedUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerRejectedMessage EXCEPT !.efidManualCpBreachTriggerRejectedEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerRejectedMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Breach Clear Rejected Message: 30 bytes                                 *)
(***************************************************************************)

BreachClearRejectedMessage ==
    [ clOrdIdBreachClearRejectedClOrdId : Sample(20),
      breachIdOptional                  : Sample(8),
      rejectReason                      : Sample(2) ]

EncodeBreachClearRejectedMessage(message) ==
    message.clOrdIdBreachClearRejectedClOrdId
        \o message.breachIdOptional
        \o message.rejectReason

DecodeBreachClearRejectedMessage(bytes) ==
    LET clOrdIdBreachClearRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdBreachClearRejectedClOrdId.ok THEN Fail ELSE
    LET breachIdOptional == ReadBytes(clOrdIdBreachClearRejectedClOrdId.rest, 8) IN IF ~breachIdOptional.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(breachIdOptional.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdBreachClearRejectedClOrdId |-> clOrdIdBreachClearRejectedClOrdId.value,
         breachIdOptional                  |-> breachIdOptional.value,
         rejectReason                      |-> rejectReason.value ], rejectReason.rest)

ZeroBreachClearRejectedMessage ==
    [ clOrdIdBreachClearRejectedClOrdId |-> [i \in 1 .. 20 |-> 0],
      breachIdOptional                  |-> [i \in 1 .. 8 |-> 0],
      rejectReason                      |-> [i \in 1 .. 2 |-> 0] ]

(* Breach Clear Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearRejectedMessage ==
    { ZeroBreachClearRejectedMessage }
        \cup { [ZeroBreachClearRejectedMessage EXCEPT !.clOrdIdBreachClearRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearRejectedMessage EXCEPT !.breachIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroBreachClearRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Breach Cleared Message: 28 bytes                                        *)
(***************************************************************************)

BreachClearedMessage ==
    [ clordidOptional  : Sample(20),
      breachIdOptional : Sample(8) ]

EncodeBreachClearedMessage(message) ==
    message.clordidOptional
        \o message.breachIdOptional

DecodeBreachClearedMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET breachIdOptional == ReadBytes(clordidOptional.rest, 8) IN IF ~breachIdOptional.ok THEN Fail ELSE
    Ok([ clordidOptional  |-> clordidOptional.value,
         breachIdOptional |-> breachIdOptional.value ], breachIdOptional.rest)

ZeroBreachClearedMessage ==
    [ clordidOptional  |-> [i \in 1 .. 20 |-> 0],
      breachIdOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Breach Cleared Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearedMessage ==
    { ZeroBreachClearedMessage }
        \cup { [ZeroBreachClearedMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearedMessage EXCEPT !.breachIdOptional = one] : one \in Sample(8) }

(***************************************************************************)
(* Breach Clear All Accepted Message: 20 bytes                             *)
(***************************************************************************)

BreachClearAllAcceptedMessage ==
    [ clOrdIdBreachClearAllAcceptedClOrdId : Sample(20) ]

EncodeBreachClearAllAcceptedMessage(message) ==
    message.clOrdIdBreachClearAllAcceptedClOrdId

DecodeBreachClearAllAcceptedMessage(bytes) ==
    LET clOrdIdBreachClearAllAcceptedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdBreachClearAllAcceptedClOrdId.ok THEN Fail ELSE
    Ok([ clOrdIdBreachClearAllAcceptedClOrdId |-> clOrdIdBreachClearAllAcceptedClOrdId.value ], clOrdIdBreachClearAllAcceptedClOrdId.rest)

ZeroBreachClearAllAcceptedMessage ==
    [ clOrdIdBreachClearAllAcceptedClOrdId |-> [i \in 1 .. 20 |-> 0] ]

(* Breach Clear All Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearAllAcceptedMessage ==
    { ZeroBreachClearAllAcceptedMessage }
        \cup { [ZeroBreachClearAllAcceptedMessage EXCEPT !.clOrdIdBreachClearAllAcceptedClOrdId = one] : one \in Sample(20) }

(***************************************************************************)
(* Breach Clear All Rejected Message: 22 bytes                             *)
(***************************************************************************)

BreachClearAllRejectedMessage ==
    [ clOrdIdBreachClearAllRejectedClOrdId : Sample(20),
      rejectReason                         : Sample(2) ]

EncodeBreachClearAllRejectedMessage(message) ==
    message.clOrdIdBreachClearAllRejectedClOrdId
        \o message.rejectReason

DecodeBreachClearAllRejectedMessage(bytes) ==
    LET clOrdIdBreachClearAllRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdBreachClearAllRejectedClOrdId.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(clOrdIdBreachClearAllRejectedClOrdId.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdBreachClearAllRejectedClOrdId |-> clOrdIdBreachClearAllRejectedClOrdId.value,
         rejectReason                         |-> rejectReason.value ], rejectReason.rest)

ZeroBreachClearAllRejectedMessage ==
    [ clOrdIdBreachClearAllRejectedClOrdId |-> [i \in 1 .. 20 |-> 0],
      rejectReason                         |-> [i \in 1 .. 2 |-> 0] ]

(* Breach Clear All Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearAllRejectedMessage ==
    { ZeroBreachClearAllRejectedMessage }
        \cup { [ZeroBreachClearAllRejectedMessage EXCEPT !.clOrdIdBreachClearAllRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearAllRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Breach Clear All By Efid Or Underlier Accepted Message: 30 bytes        *)
(***************************************************************************)

BreachClearAllByEfidOrUnderlierAcceptedMessage ==
    [ clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId             : Sample(20),
      underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional : Sample(6),
      efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional           : Sample(4) ]

EncodeBreachClearAllByEfidOrUnderlierAcceptedMessage(message) ==
    message.clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId
        \o message.underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional
        \o message.efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional

DecodeBreachClearAllByEfidOrUnderlierAcceptedMessage(bytes) ==
    LET clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId.ok THEN Fail ELSE
    LET underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional == ReadBytes(clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId.rest, 6) IN IF ~underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional.ok THEN Fail ELSE
    LET efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional == ReadBytes(underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional.rest, 4) IN IF ~efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional.ok THEN Fail ELSE
    Ok([ clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId             |-> clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId.value,
         underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional |-> underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional.value,
         efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional           |-> efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional.value ], efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional.rest)

ZeroBreachClearAllByEfidOrUnderlierAcceptedMessage ==
    [ clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional           |-> [i \in 1 .. 4 |-> 0] ]

(* Breach Clear All By Efid Or Underlier Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearAllByEfidOrUnderlierAcceptedMessage ==
    { ZeroBreachClearAllByEfidOrUnderlierAcceptedMessage }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierAcceptedMessage EXCEPT !.clOrdIdBreachClearAllByEfidOrUnderlierAcceptedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierAcceptedMessage EXCEPT !.underlierBreachClearAllByEfidOrUnderlierAcceptedUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierAcceptedMessage EXCEPT !.efidBreachClearAllByEfidOrUnderlierAcceptedEfidOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Breach Clear All By Efid Or Underlier Rejected Message: 32 bytes        *)
(***************************************************************************)

BreachClearAllByEfidOrUnderlierRejectedMessage ==
    [ clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId             : Sample(20),
      underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional : Sample(6),
      efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional           : Sample(4),
      rejectReason                                                      : Sample(2) ]

EncodeBreachClearAllByEfidOrUnderlierRejectedMessage(message) ==
    message.clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId
        \o message.underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional
        \o message.efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional
        \o message.rejectReason

DecodeBreachClearAllByEfidOrUnderlierRejectedMessage(bytes) ==
    LET clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId == ReadBytes(bytes, 20) IN IF ~clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId.ok THEN Fail ELSE
    LET underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional == ReadBytes(clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId.rest, 6) IN IF ~underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional.ok THEN Fail ELSE
    LET efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional == ReadBytes(underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional.rest, 4) IN IF ~efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId             |-> clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId.value,
         underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional |-> underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional.value,
         efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional           |-> efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional.value,
         rejectReason                                                      |-> rejectReason.value ], rejectReason.rest)

ZeroBreachClearAllByEfidOrUnderlierRejectedMessage ==
    [ clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId             |-> [i \in 1 .. 20 |-> 0],
      underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional           |-> [i \in 1 .. 4 |-> 0],
      rejectReason                                                      |-> [i \in 1 .. 2 |-> 0] ]

(* Breach Clear All By Efid Or Underlier Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearAllByEfidOrUnderlierRejectedMessage ==
    { ZeroBreachClearAllByEfidOrUnderlierRejectedMessage }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierRejectedMessage EXCEPT !.clOrdIdBreachClearAllByEfidOrUnderlierRejectedClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierRejectedMessage EXCEPT !.underlierBreachClearAllByEfidOrUnderlierRejectedUnderlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierRejectedMessage EXCEPT !.efidBreachClearAllByEfidOrUnderlierRejectedEfidOptional = one] : one \in Sample(4) }
        \cup { [ZeroBreachClearAllByEfidOrUnderlierRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Cp Gross Notional Threshold State Message: 40 bytes                     *)
(***************************************************************************)

CpGrossNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpGrossNotionalThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpGrossNotionalThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpGrossNotionalThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Gross Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpGrossNotionalThresholdStateMessage ==
    { ZeroCpGrossNotionalThresholdStateMessage }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Gross Notional Threshold State Message: 40 bytes        *)
(***************************************************************************)

CpMarketOrderGrossNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpMarketOrderGrossNotionalThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderGrossNotionalThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpMarketOrderGrossNotionalThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Gross Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderGrossNotionalThresholdStateMessage ==
    { ZeroCpMarketOrderGrossNotionalThresholdStateMessage }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Net Notional Threshold State Message: 40 bytes                       *)
(***************************************************************************)

CpNetNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpNetNotionalThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpNetNotionalThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpNetNotionalThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Net Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpNetNotionalThresholdStateMessage ==
    { ZeroCpNetNotionalThresholdStateMessage }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Net Notional Threshold State Message: 40 bytes          *)
(***************************************************************************)

CpMarketOrderNetNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpMarketOrderNetNotionalThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderNetNotionalThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpMarketOrderNetNotionalThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Net Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderNetNotionalThresholdStateMessage ==
    { ZeroCpMarketOrderNetNotionalThresholdStateMessage }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Duplicate Order Threshold State Message: 41 bytes                    *)
(***************************************************************************)

CpDuplicateOrderThresholdStateMessage ==
    [ clordidOptional         : Sample(20),
      underlierOptional       : Sample(6),
      efidOptional            : Sample(4),
      riskGroupId             : Sample(2),
      maxDupOrders            : Sample(4),
      useOrderPriceInDupCheck : Sample(1),
      periodInMilliSeconds    : Sample(4) ]

EncodeCpDuplicateOrderThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxDupOrders
        \o message.useOrderPriceInDupCheck
        \o message.periodInMilliSeconds

DecodeCpDuplicateOrderThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxDupOrders == ReadBytes(riskGroupId.rest, 4) IN IF ~maxDupOrders.ok THEN Fail ELSE
    LET useOrderPriceInDupCheck == ReadBytes(maxDupOrders.rest, 1) IN IF ~useOrderPriceInDupCheck.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(useOrderPriceInDupCheck.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional         |-> clordidOptional.value,
         underlierOptional       |-> underlierOptional.value,
         efidOptional            |-> efidOptional.value,
         riskGroupId             |-> riskGroupId.value,
         maxDupOrders            |-> maxDupOrders.value,
         useOrderPriceInDupCheck |-> useOrderPriceInDupCheck.value,
         periodInMilliSeconds    |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpDuplicateOrderThresholdStateMessage ==
    [ clordidOptional         |-> [i \in 1 .. 20 |-> 0],
      underlierOptional       |-> [i \in 1 .. 6 |-> 0],
      efidOptional            |-> [i \in 1 .. 4 |-> 0],
      riskGroupId             |-> [i \in 1 .. 2 |-> 0],
      maxDupOrders            |-> [i \in 1 .. 4 |-> 0],
      useOrderPriceInDupCheck |-> [i \in 1 .. 1 |-> 0],
      periodInMilliSeconds    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Duplicate Order Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpDuplicateOrderThresholdStateMessage ==
    { ZeroCpDuplicateOrderThresholdStateMessage }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.maxDupOrders = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.useOrderPriceInDupCheck = one] : one \in Sample(1) }
        \cup { [ZeroCpDuplicateOrderThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Order Rate Threshold State Message: 40 bytes                         *)
(***************************************************************************)

CpOrderRateThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxOrderMsgs         : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpOrderRateThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxOrderMsgs
        \o message.periodInMilliSeconds

DecodeCpOrderRateThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordidOptional.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxOrderMsgs == ReadBytes(riskGroupId.rest, 4) IN IF ~maxOrderMsgs.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(maxOrderMsgs.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordidOptional      |-> clordidOptional.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         maxOrderMsgs         |-> maxOrderMsgs.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpOrderRateThresholdStateMessage ==
    [ clordidOptional      |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      maxOrderMsgs         |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Order Rate Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpOrderRateThresholdStateMessage ==
    { ZeroCpOrderRateThresholdStateMessage }
        \cup { [ZeroCpOrderRateThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpOrderRateThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpOrderRateThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpOrderRateThresholdStateMessage EXCEPT !.maxOrderMsgs = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdStateMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

RiskSettingsQueryMessageCode == 1  \* 0x01
ActiveRiskThresholdChangeRequestMessageCode == 2  \* 0x02
ActiveRiskAcknowledgementRequestMessageCode == 3  \* 0x03
CpVolumeThresholdChangeRequestMessageCode == 4  \* 0x04
CpExecutedNotionalThresholdChangeRequestMessageCode == 5  \* 0x05
CpTotalExecutionsThresholdChangeRequestMessageCode == 6  \* 0x06
CpPercentOutstandingContractsThresholdChangeRequestMessageCode == 7  \* 0x07
CpBreachCountThresholdChangeRequestMessageCode == 8  \* 0x08
ManualCpBreachTriggerRequestMessageCode == 9  \* 0x09
CpClearBreachRequestMessageCode == 10  \* 0x0a
SingleOrderAllowIsoOrdersChangeRequestMessageCode == 11  \* 0x0b
SingleOrderAllowOrdersInCrossedMarketChangeRequestMessageCode == 12  \* 0x0c
SingleOrderMaxNotionalChangeRequestMessageCode == 13  \* 0x0d
SingleOrderMaxContractsChangeRequestMessageCode == 14  \* 0x0e
SingleOrderAllowMarketOrdersChangeRequestMessageCode == 15  \* 0x0f
SingleOrderRestrictedUnderlierChangeRequestMessageCode == 16  \* 0x10
CpGrossNotionalThresholdChangeRequestMessageCode == 18  \* 0x12
CpMarketOrderGrossNotionalThresholdChangeRequestMessageCode == 19  \* 0x13
CpNetNotionalThresholdChangeRequestMessageCode == 20  \* 0x14
CpMarketOrderNetNotionalThresholdChangeRequestMessageCode == 21  \* 0x15
CpDuplicateOrderThresholdChangeRequestMessageCode == 22  \* 0x16
CpOrderRateThresholdChangeRequestMessageCode == 23  \* 0x17
CpClearAllBreachesRequestMessageCode == 24  \* 0x18
CpClearAllBreachesByEfidOrUnderlierRequestMessageCode == 25  \* 0x19
ActiveRiskAcknowledgeAllRequestMessageCode == 26  \* 0x1a
ActiveRiskThresholdStateMessageCode == 30  \* 0x1e
ActiveRiskThresholdChangeRejectedMessageCode == 31  \* 0x1f
ActiveRiskAcknowledgedMessageCode == 32  \* 0x20
ActiveRiskAcknowledgeRejectedMessageCode == 33  \* 0x21
ActiveRiskQuantityUpdateNotificationMessageCode == 34  \* 0x22
CpVolumeThresholdStateMessageCode == 35  \* 0x23
CpExecutedNotionalThresholdStateMessageCode == 36  \* 0x24
CpTotalExecutionsThresholdStateMessageCode == 37  \* 0x25
CpPercentOutstandingContractsThresholdStateMessageCode == 38  \* 0x26
CpBreachCountThresholdStateMessageCode == 39  \* 0x27
ManualCpBreachTriggerPendingMessageCode == 40  \* 0x28
ManualCpBreachTriggerDoneMessageCode == 41  \* 0x29
RiskThresholdUpdateRejectedMessageCode == 42  \* 0x2a
PassiveRiskThresholdNotificationMessageCode == 43  \* 0x2b
SingleOrderAllowIsoOrdersStateMessageCode == 44  \* 0x2c
SingleOrderAllowOrdersInCrossedMarketStateMessageCode == 45  \* 0x2d
SingleOrderMaxNotionalThresholdStateMessageCode == 46  \* 0x2e
SingleOrderMaxContractsThresholdStateMessageCode == 47  \* 0x2f
SingleOrderAllowMarketOrdersStateMessageCode == 66  \* 0x42
SingleOrderRestrictedUnderlierStateMessageCode == 67  \* 0x43
RiskSettingsQueryDoneMessageCode == 48  \* 0x30
RiskSettingsQueryRejectedMessageCode == 49  \* 0x31
ManualCpBreachTriggerRejectedMessageCode == 50  \* 0x32
BreachClearRejectedMessageCode == 51  \* 0x33
BreachClearedMessageCode == 52  \* 0x34
BreachClearAllAcceptedMessageCode == 53  \* 0x35
BreachClearAllRejectedMessageCode == 69  \* 0x45
BreachClearAllByEfidOrUnderlierAcceptedMessageCode == 54  \* 0x36
BreachClearAllByEfidOrUnderlierRejectedMessageCode == 68  \* 0x44
CpGrossNotionalThresholdStateMessageCode == 60  \* 0x3c
CpMarketOrderGrossNotionalThresholdStateMessageCode == 61  \* 0x3d
CpNetNotionalThresholdStateMessageCode == 62  \* 0x3e
CpMarketOrderNetNotionalThresholdStateMessageCode == 63  \* 0x3f
CpDuplicateOrderThresholdStateMessageCode == 64  \* 0x40
CpOrderRateThresholdStateMessageCode == 65  \* 0x41

Payload ==
    [ tag : {RiskSettingsQueryMessageCode}, body : RiskSettingsQueryMessage ]
        \cup [ tag : {ActiveRiskThresholdChangeRequestMessageCode}, body : ActiveRiskThresholdChangeRequestMessage ]
        \cup [ tag : {ActiveRiskAcknowledgementRequestMessageCode}, body : ActiveRiskAcknowledgementRequestMessage ]
        \cup [ tag : {CpVolumeThresholdChangeRequestMessageCode}, body : CpVolumeThresholdChangeRequestMessage ]
        \cup [ tag : {CpExecutedNotionalThresholdChangeRequestMessageCode}, body : CpExecutedNotionalThresholdChangeRequestMessage ]
        \cup [ tag : {CpTotalExecutionsThresholdChangeRequestMessageCode}, body : CpTotalExecutionsThresholdChangeRequestMessage ]
        \cup [ tag : {CpPercentOutstandingContractsThresholdChangeRequestMessageCode}, body : CpPercentOutstandingContractsThresholdChangeRequestMessage ]
        \cup [ tag : {CpBreachCountThresholdChangeRequestMessageCode}, body : CpBreachCountThresholdChangeRequestMessage ]
        \cup [ tag : {ManualCpBreachTriggerRequestMessageCode}, body : ManualCpBreachTriggerRequestMessage ]
        \cup [ tag : {CpClearBreachRequestMessageCode}, body : CpClearBreachRequestMessage ]
        \cup [ tag : {SingleOrderAllowIsoOrdersChangeRequestMessageCode}, body : SingleOrderAllowIsoOrdersChangeRequestMessage ]
        \cup [ tag : {SingleOrderAllowOrdersInCrossedMarketChangeRequestMessageCode}, body : SingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ]
        \cup [ tag : {SingleOrderMaxNotionalChangeRequestMessageCode}, body : SingleOrderMaxNotionalChangeRequestMessage ]
        \cup [ tag : {SingleOrderMaxContractsChangeRequestMessageCode}, body : SingleOrderMaxContractsChangeRequestMessage ]
        \cup [ tag : {SingleOrderAllowMarketOrdersChangeRequestMessageCode}, body : SingleOrderAllowMarketOrdersChangeRequestMessage ]
        \cup [ tag : {SingleOrderRestrictedUnderlierChangeRequestMessageCode}, body : SingleOrderRestrictedUnderlierChangeRequestMessage ]
        \cup [ tag : {CpGrossNotionalThresholdChangeRequestMessageCode}, body : CpGrossNotionalThresholdChangeRequestMessage ]
        \cup [ tag : {CpMarketOrderGrossNotionalThresholdChangeRequestMessageCode}, body : CpMarketOrderGrossNotionalThresholdChangeRequestMessage ]
        \cup [ tag : {CpNetNotionalThresholdChangeRequestMessageCode}, body : CpNetNotionalThresholdChangeRequestMessage ]
        \cup [ tag : {CpMarketOrderNetNotionalThresholdChangeRequestMessageCode}, body : CpMarketOrderNetNotionalThresholdChangeRequestMessage ]
        \cup [ tag : {CpDuplicateOrderThresholdChangeRequestMessageCode}, body : CpDuplicateOrderThresholdChangeRequestMessage ]
        \cup [ tag : {CpOrderRateThresholdChangeRequestMessageCode}, body : CpOrderRateThresholdChangeRequestMessage ]
        \cup [ tag : {CpClearAllBreachesRequestMessageCode}, body : CpClearAllBreachesRequestMessage ]
        \cup [ tag : {CpClearAllBreachesByEfidOrUnderlierRequestMessageCode}, body : CpClearAllBreachesByEfidOrUnderlierRequestMessage ]
        \cup [ tag : {ActiveRiskAcknowledgeAllRequestMessageCode}, body : ActiveRiskAcknowledgeAllRequestMessage ]
        \cup [ tag : {ActiveRiskThresholdStateMessageCode}, body : ActiveRiskThresholdStateMessage ]
        \cup [ tag : {ActiveRiskThresholdChangeRejectedMessageCode}, body : ActiveRiskThresholdChangeRejectedMessage ]
        \cup [ tag : {ActiveRiskAcknowledgedMessageCode}, body : ActiveRiskAcknowledgedMessage ]
        \cup [ tag : {ActiveRiskAcknowledgeRejectedMessageCode}, body : ActiveRiskAcknowledgeRejectedMessage ]
        \cup [ tag : {ActiveRiskQuantityUpdateNotificationMessageCode}, body : ActiveRiskQuantityUpdateNotificationMessage ]
        \cup [ tag : {CpVolumeThresholdStateMessageCode}, body : CpVolumeThresholdStateMessage ]
        \cup [ tag : {CpExecutedNotionalThresholdStateMessageCode}, body : CpExecutedNotionalThresholdStateMessage ]
        \cup [ tag : {CpTotalExecutionsThresholdStateMessageCode}, body : CpTotalExecutionsThresholdStateMessage ]
        \cup [ tag : {CpPercentOutstandingContractsThresholdStateMessageCode}, body : CpPercentOutstandingContractsThresholdStateMessage ]
        \cup [ tag : {CpBreachCountThresholdStateMessageCode}, body : CpBreachCountThresholdStateMessage ]
        \cup [ tag : {ManualCpBreachTriggerPendingMessageCode}, body : ManualCpBreachTriggerPendingMessage ]
        \cup [ tag : {ManualCpBreachTriggerDoneMessageCode}, body : ManualCpBreachTriggerDoneMessage ]
        \cup [ tag : {RiskThresholdUpdateRejectedMessageCode}, body : RiskThresholdUpdateRejectedMessage ]
        \cup [ tag : {PassiveRiskThresholdNotificationMessageCode}, body : PassiveRiskThresholdNotificationMessage ]
        \cup [ tag : {SingleOrderAllowIsoOrdersStateMessageCode}, body : SingleOrderAllowIsoOrdersStateMessage ]
        \cup [ tag : {SingleOrderAllowOrdersInCrossedMarketStateMessageCode}, body : SingleOrderAllowOrdersInCrossedMarketStateMessage ]
        \cup [ tag : {SingleOrderMaxNotionalThresholdStateMessageCode}, body : SingleOrderMaxNotionalThresholdStateMessage ]
        \cup [ tag : {SingleOrderMaxContractsThresholdStateMessageCode}, body : SingleOrderMaxContractsThresholdStateMessage ]
        \cup [ tag : {SingleOrderAllowMarketOrdersStateMessageCode}, body : SingleOrderAllowMarketOrdersStateMessage ]
        \cup [ tag : {SingleOrderRestrictedUnderlierStateMessageCode}, body : SingleOrderRestrictedUnderlierStateMessage ]
        \cup [ tag : {RiskSettingsQueryDoneMessageCode}, body : RiskSettingsQueryDoneMessage ]
        \cup [ tag : {RiskSettingsQueryRejectedMessageCode}, body : RiskSettingsQueryRejectedMessage ]
        \cup [ tag : {ManualCpBreachTriggerRejectedMessageCode}, body : ManualCpBreachTriggerRejectedMessage ]
        \cup [ tag : {BreachClearRejectedMessageCode}, body : BreachClearRejectedMessage ]
        \cup [ tag : {BreachClearedMessageCode}, body : BreachClearedMessage ]
        \cup [ tag : {BreachClearAllAcceptedMessageCode}, body : BreachClearAllAcceptedMessage ]
        \cup [ tag : {BreachClearAllRejectedMessageCode}, body : BreachClearAllRejectedMessage ]
        \cup [ tag : {BreachClearAllByEfidOrUnderlierAcceptedMessageCode}, body : BreachClearAllByEfidOrUnderlierAcceptedMessage ]
        \cup [ tag : {BreachClearAllByEfidOrUnderlierRejectedMessageCode}, body : BreachClearAllByEfidOrUnderlierRejectedMessage ]
        \cup [ tag : {CpGrossNotionalThresholdStateMessageCode}, body : CpGrossNotionalThresholdStateMessage ]
        \cup [ tag : {CpMarketOrderGrossNotionalThresholdStateMessageCode}, body : CpMarketOrderGrossNotionalThresholdStateMessage ]
        \cup [ tag : {CpNetNotionalThresholdStateMessageCode}, body : CpNetNotionalThresholdStateMessage ]
        \cup [ tag : {CpMarketOrderNetNotionalThresholdStateMessageCode}, body : CpMarketOrderNetNotionalThresholdStateMessage ]
        \cup [ tag : {CpDuplicateOrderThresholdStateMessageCode}, body : CpDuplicateOrderThresholdStateMessage ]
        \cup [ tag : {CpOrderRateThresholdStateMessageCode}, body : CpOrderRateThresholdStateMessage ]

EncodePayload(message) ==
    CASE message.tag = RiskSettingsQueryMessageCode -> EncodeRiskSettingsQueryMessage(message.body)
      [] message.tag = ActiveRiskThresholdChangeRequestMessageCode -> EncodeActiveRiskThresholdChangeRequestMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgementRequestMessageCode -> EncodeActiveRiskAcknowledgementRequestMessage(message.body)
      [] message.tag = CpVolumeThresholdChangeRequestMessageCode -> EncodeCpVolumeThresholdChangeRequestMessage(message.body)
      [] message.tag = CpExecutedNotionalThresholdChangeRequestMessageCode -> EncodeCpExecutedNotionalThresholdChangeRequestMessage(message.body)
      [] message.tag = CpTotalExecutionsThresholdChangeRequestMessageCode -> EncodeCpTotalExecutionsThresholdChangeRequestMessage(message.body)
      [] message.tag = CpPercentOutstandingContractsThresholdChangeRequestMessageCode -> EncodeCpPercentOutstandingContractsThresholdChangeRequestMessage(message.body)
      [] message.tag = CpBreachCountThresholdChangeRequestMessageCode -> EncodeCpBreachCountThresholdChangeRequestMessage(message.body)
      [] message.tag = ManualCpBreachTriggerRequestMessageCode -> EncodeManualCpBreachTriggerRequestMessage(message.body)
      [] message.tag = CpClearBreachRequestMessageCode -> EncodeCpClearBreachRequestMessage(message.body)
      [] message.tag = SingleOrderAllowIsoOrdersChangeRequestMessageCode -> EncodeSingleOrderAllowIsoOrdersChangeRequestMessage(message.body)
      [] message.tag = SingleOrderAllowOrdersInCrossedMarketChangeRequestMessageCode -> EncodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(message.body)
      [] message.tag = SingleOrderMaxNotionalChangeRequestMessageCode -> EncodeSingleOrderMaxNotionalChangeRequestMessage(message.body)
      [] message.tag = SingleOrderMaxContractsChangeRequestMessageCode -> EncodeSingleOrderMaxContractsChangeRequestMessage(message.body)
      [] message.tag = SingleOrderAllowMarketOrdersChangeRequestMessageCode -> EncodeSingleOrderAllowMarketOrdersChangeRequestMessage(message.body)
      [] message.tag = SingleOrderRestrictedUnderlierChangeRequestMessageCode -> EncodeSingleOrderRestrictedUnderlierChangeRequestMessage(message.body)
      [] message.tag = CpGrossNotionalThresholdChangeRequestMessageCode -> EncodeCpGrossNotionalThresholdChangeRequestMessage(message.body)
      [] message.tag = CpMarketOrderGrossNotionalThresholdChangeRequestMessageCode -> EncodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(message.body)
      [] message.tag = CpNetNotionalThresholdChangeRequestMessageCode -> EncodeCpNetNotionalThresholdChangeRequestMessage(message.body)
      [] message.tag = CpMarketOrderNetNotionalThresholdChangeRequestMessageCode -> EncodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(message.body)
      [] message.tag = CpDuplicateOrderThresholdChangeRequestMessageCode -> EncodeCpDuplicateOrderThresholdChangeRequestMessage(message.body)
      [] message.tag = CpOrderRateThresholdChangeRequestMessageCode -> EncodeCpOrderRateThresholdChangeRequestMessage(message.body)
      [] message.tag = CpClearAllBreachesRequestMessageCode -> EncodeCpClearAllBreachesRequestMessage(message.body)
      [] message.tag = CpClearAllBreachesByEfidOrUnderlierRequestMessageCode -> EncodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgeAllRequestMessageCode -> EncodeActiveRiskAcknowledgeAllRequestMessage(message.body)
      [] message.tag = ActiveRiskThresholdStateMessageCode -> EncodeActiveRiskThresholdStateMessage(message.body)
      [] message.tag = ActiveRiskThresholdChangeRejectedMessageCode -> EncodeActiveRiskThresholdChangeRejectedMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgedMessageCode -> EncodeActiveRiskAcknowledgedMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgeRejectedMessageCode -> EncodeActiveRiskAcknowledgeRejectedMessage(message.body)
      [] message.tag = ActiveRiskQuantityUpdateNotificationMessageCode -> EncodeActiveRiskQuantityUpdateNotificationMessage(message.body)
      [] message.tag = CpVolumeThresholdStateMessageCode -> EncodeCpVolumeThresholdStateMessage(message.body)
      [] message.tag = CpExecutedNotionalThresholdStateMessageCode -> EncodeCpExecutedNotionalThresholdStateMessage(message.body)
      [] message.tag = CpTotalExecutionsThresholdStateMessageCode -> EncodeCpTotalExecutionsThresholdStateMessage(message.body)
      [] message.tag = CpPercentOutstandingContractsThresholdStateMessageCode -> EncodeCpPercentOutstandingContractsThresholdStateMessage(message.body)
      [] message.tag = CpBreachCountThresholdStateMessageCode -> EncodeCpBreachCountThresholdStateMessage(message.body)
      [] message.tag = ManualCpBreachTriggerPendingMessageCode -> EncodeManualCpBreachTriggerPendingMessage(message.body)
      [] message.tag = ManualCpBreachTriggerDoneMessageCode -> EncodeManualCpBreachTriggerDoneMessage(message.body)
      [] message.tag = RiskThresholdUpdateRejectedMessageCode -> EncodeRiskThresholdUpdateRejectedMessage(message.body)
      [] message.tag = PassiveRiskThresholdNotificationMessageCode -> EncodePassiveRiskThresholdNotificationMessage(message.body)
      [] message.tag = SingleOrderAllowIsoOrdersStateMessageCode -> EncodeSingleOrderAllowIsoOrdersStateMessage(message.body)
      [] message.tag = SingleOrderAllowOrdersInCrossedMarketStateMessageCode -> EncodeSingleOrderAllowOrdersInCrossedMarketStateMessage(message.body)
      [] message.tag = SingleOrderMaxNotionalThresholdStateMessageCode -> EncodeSingleOrderMaxNotionalThresholdStateMessage(message.body)
      [] message.tag = SingleOrderMaxContractsThresholdStateMessageCode -> EncodeSingleOrderMaxContractsThresholdStateMessage(message.body)
      [] message.tag = SingleOrderAllowMarketOrdersStateMessageCode -> EncodeSingleOrderAllowMarketOrdersStateMessage(message.body)
      [] message.tag = SingleOrderRestrictedUnderlierStateMessageCode -> EncodeSingleOrderRestrictedUnderlierStateMessage(message.body)
      [] message.tag = RiskSettingsQueryDoneMessageCode -> EncodeRiskSettingsQueryDoneMessage(message.body)
      [] message.tag = RiskSettingsQueryRejectedMessageCode -> EncodeRiskSettingsQueryRejectedMessage(message.body)
      [] message.tag = ManualCpBreachTriggerRejectedMessageCode -> EncodeManualCpBreachTriggerRejectedMessage(message.body)
      [] message.tag = BreachClearRejectedMessageCode -> EncodeBreachClearRejectedMessage(message.body)
      [] message.tag = BreachClearedMessageCode -> EncodeBreachClearedMessage(message.body)
      [] message.tag = BreachClearAllAcceptedMessageCode -> EncodeBreachClearAllAcceptedMessage(message.body)
      [] message.tag = BreachClearAllRejectedMessageCode -> EncodeBreachClearAllRejectedMessage(message.body)
      [] message.tag = BreachClearAllByEfidOrUnderlierAcceptedMessageCode -> EncodeBreachClearAllByEfidOrUnderlierAcceptedMessage(message.body)
      [] message.tag = BreachClearAllByEfidOrUnderlierRejectedMessageCode -> EncodeBreachClearAllByEfidOrUnderlierRejectedMessage(message.body)
      [] message.tag = CpGrossNotionalThresholdStateMessageCode -> EncodeCpGrossNotionalThresholdStateMessage(message.body)
      [] message.tag = CpMarketOrderGrossNotionalThresholdStateMessageCode -> EncodeCpMarketOrderGrossNotionalThresholdStateMessage(message.body)
      [] message.tag = CpNetNotionalThresholdStateMessageCode -> EncodeCpNetNotionalThresholdStateMessage(message.body)
      [] message.tag = CpMarketOrderNetNotionalThresholdStateMessageCode -> EncodeCpMarketOrderNetNotionalThresholdStateMessage(message.body)
      [] message.tag = CpDuplicateOrderThresholdStateMessageCode -> EncodeCpDuplicateOrderThresholdStateMessage(message.body)
      [] message.tag = CpOrderRateThresholdStateMessageCode -> EncodeCpOrderRateThresholdStateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = RiskSettingsQueryMessageCode -> DecodeRiskSettingsQueryMessage(bytes)
              [] tag = ActiveRiskThresholdChangeRequestMessageCode -> DecodeActiveRiskThresholdChangeRequestMessage(bytes)
              [] tag = ActiveRiskAcknowledgementRequestMessageCode -> DecodeActiveRiskAcknowledgementRequestMessage(bytes)
              [] tag = CpVolumeThresholdChangeRequestMessageCode -> DecodeCpVolumeThresholdChangeRequestMessage(bytes)
              [] tag = CpExecutedNotionalThresholdChangeRequestMessageCode -> DecodeCpExecutedNotionalThresholdChangeRequestMessage(bytes)
              [] tag = CpTotalExecutionsThresholdChangeRequestMessageCode -> DecodeCpTotalExecutionsThresholdChangeRequestMessage(bytes)
              [] tag = CpPercentOutstandingContractsThresholdChangeRequestMessageCode -> DecodeCpPercentOutstandingContractsThresholdChangeRequestMessage(bytes)
              [] tag = CpBreachCountThresholdChangeRequestMessageCode -> DecodeCpBreachCountThresholdChangeRequestMessage(bytes)
              [] tag = ManualCpBreachTriggerRequestMessageCode -> DecodeManualCpBreachTriggerRequestMessage(bytes)
              [] tag = CpClearBreachRequestMessageCode -> DecodeCpClearBreachRequestMessage(bytes)
              [] tag = SingleOrderAllowIsoOrdersChangeRequestMessageCode -> DecodeSingleOrderAllowIsoOrdersChangeRequestMessage(bytes)
              [] tag = SingleOrderAllowOrdersInCrossedMarketChangeRequestMessageCode -> DecodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(bytes)
              [] tag = SingleOrderMaxNotionalChangeRequestMessageCode -> DecodeSingleOrderMaxNotionalChangeRequestMessage(bytes)
              [] tag = SingleOrderMaxContractsChangeRequestMessageCode -> DecodeSingleOrderMaxContractsChangeRequestMessage(bytes)
              [] tag = SingleOrderAllowMarketOrdersChangeRequestMessageCode -> DecodeSingleOrderAllowMarketOrdersChangeRequestMessage(bytes)
              [] tag = SingleOrderRestrictedUnderlierChangeRequestMessageCode -> DecodeSingleOrderRestrictedUnderlierChangeRequestMessage(bytes)
              [] tag = CpGrossNotionalThresholdChangeRequestMessageCode -> DecodeCpGrossNotionalThresholdChangeRequestMessage(bytes)
              [] tag = CpMarketOrderGrossNotionalThresholdChangeRequestMessageCode -> DecodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(bytes)
              [] tag = CpNetNotionalThresholdChangeRequestMessageCode -> DecodeCpNetNotionalThresholdChangeRequestMessage(bytes)
              [] tag = CpMarketOrderNetNotionalThresholdChangeRequestMessageCode -> DecodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(bytes)
              [] tag = CpDuplicateOrderThresholdChangeRequestMessageCode -> DecodeCpDuplicateOrderThresholdChangeRequestMessage(bytes)
              [] tag = CpOrderRateThresholdChangeRequestMessageCode -> DecodeCpOrderRateThresholdChangeRequestMessage(bytes)
              [] tag = CpClearAllBreachesRequestMessageCode -> DecodeCpClearAllBreachesRequestMessage(bytes)
              [] tag = CpClearAllBreachesByEfidOrUnderlierRequestMessageCode -> DecodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(bytes)
              [] tag = ActiveRiskAcknowledgeAllRequestMessageCode -> DecodeActiveRiskAcknowledgeAllRequestMessage(bytes)
              [] tag = ActiveRiskThresholdStateMessageCode -> DecodeActiveRiskThresholdStateMessage(bytes)
              [] tag = ActiveRiskThresholdChangeRejectedMessageCode -> DecodeActiveRiskThresholdChangeRejectedMessage(bytes)
              [] tag = ActiveRiskAcknowledgedMessageCode -> DecodeActiveRiskAcknowledgedMessage(bytes)
              [] tag = ActiveRiskAcknowledgeRejectedMessageCode -> DecodeActiveRiskAcknowledgeRejectedMessage(bytes)
              [] tag = ActiveRiskQuantityUpdateNotificationMessageCode -> DecodeActiveRiskQuantityUpdateNotificationMessage(bytes)
              [] tag = CpVolumeThresholdStateMessageCode -> DecodeCpVolumeThresholdStateMessage(bytes)
              [] tag = CpExecutedNotionalThresholdStateMessageCode -> DecodeCpExecutedNotionalThresholdStateMessage(bytes)
              [] tag = CpTotalExecutionsThresholdStateMessageCode -> DecodeCpTotalExecutionsThresholdStateMessage(bytes)
              [] tag = CpPercentOutstandingContractsThresholdStateMessageCode -> DecodeCpPercentOutstandingContractsThresholdStateMessage(bytes)
              [] tag = CpBreachCountThresholdStateMessageCode -> DecodeCpBreachCountThresholdStateMessage(bytes)
              [] tag = ManualCpBreachTriggerPendingMessageCode -> DecodeManualCpBreachTriggerPendingMessage(bytes)
              [] tag = ManualCpBreachTriggerDoneMessageCode -> DecodeManualCpBreachTriggerDoneMessage(bytes)
              [] tag = RiskThresholdUpdateRejectedMessageCode -> DecodeRiskThresholdUpdateRejectedMessage(bytes)
              [] tag = PassiveRiskThresholdNotificationMessageCode -> DecodePassiveRiskThresholdNotificationMessage(bytes)
              [] tag = SingleOrderAllowIsoOrdersStateMessageCode -> DecodeSingleOrderAllowIsoOrdersStateMessage(bytes)
              [] tag = SingleOrderAllowOrdersInCrossedMarketStateMessageCode -> DecodeSingleOrderAllowOrdersInCrossedMarketStateMessage(bytes)
              [] tag = SingleOrderMaxNotionalThresholdStateMessageCode -> DecodeSingleOrderMaxNotionalThresholdStateMessage(bytes)
              [] tag = SingleOrderMaxContractsThresholdStateMessageCode -> DecodeSingleOrderMaxContractsThresholdStateMessage(bytes)
              [] tag = SingleOrderAllowMarketOrdersStateMessageCode -> DecodeSingleOrderAllowMarketOrdersStateMessage(bytes)
              [] tag = SingleOrderRestrictedUnderlierStateMessageCode -> DecodeSingleOrderRestrictedUnderlierStateMessage(bytes)
              [] tag = RiskSettingsQueryDoneMessageCode -> DecodeRiskSettingsQueryDoneMessage(bytes)
              [] tag = RiskSettingsQueryRejectedMessageCode -> DecodeRiskSettingsQueryRejectedMessage(bytes)
              [] tag = ManualCpBreachTriggerRejectedMessageCode -> DecodeManualCpBreachTriggerRejectedMessage(bytes)
              [] tag = BreachClearRejectedMessageCode -> DecodeBreachClearRejectedMessage(bytes)
              [] tag = BreachClearedMessageCode -> DecodeBreachClearedMessage(bytes)
              [] tag = BreachClearAllAcceptedMessageCode -> DecodeBreachClearAllAcceptedMessage(bytes)
              [] tag = BreachClearAllRejectedMessageCode -> DecodeBreachClearAllRejectedMessage(bytes)
              [] tag = BreachClearAllByEfidOrUnderlierAcceptedMessageCode -> DecodeBreachClearAllByEfidOrUnderlierAcceptedMessage(bytes)
              [] tag = BreachClearAllByEfidOrUnderlierRejectedMessageCode -> DecodeBreachClearAllByEfidOrUnderlierRejectedMessage(bytes)
              [] tag = CpGrossNotionalThresholdStateMessageCode -> DecodeCpGrossNotionalThresholdStateMessage(bytes)
              [] tag = CpMarketOrderGrossNotionalThresholdStateMessageCode -> DecodeCpMarketOrderGrossNotionalThresholdStateMessage(bytes)
              [] tag = CpNetNotionalThresholdStateMessageCode -> DecodeCpNetNotionalThresholdStateMessage(bytes)
              [] tag = CpMarketOrderNetNotionalThresholdStateMessageCode -> DecodeCpMarketOrderNetNotionalThresholdStateMessage(bytes)
              [] tag = CpDuplicateOrderThresholdStateMessageCode -> DecodeCpDuplicateOrderThresholdStateMessage(bytes)
              [] tag = CpOrderRateThresholdStateMessageCode -> DecodeCpOrderRateThresholdStateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> RiskSettingsQueryMessageCode, body |-> ZeroRiskSettingsQueryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> RiskSettingsQueryMessageCode, body |-> one] : one \in CheckedRiskSettingsQueryMessage }
        \cup { [tag |-> ActiveRiskThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedActiveRiskThresholdChangeRequestMessage }
        \cup { [tag |-> ActiveRiskAcknowledgementRequestMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgementRequestMessage }
        \cup { [tag |-> CpVolumeThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpVolumeThresholdChangeRequestMessage }
        \cup { [tag |-> CpExecutedNotionalThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpExecutedNotionalThresholdChangeRequestMessage }
        \cup { [tag |-> CpTotalExecutionsThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpTotalExecutionsThresholdChangeRequestMessage }
        \cup { [tag |-> CpPercentOutstandingContractsThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpPercentOutstandingContractsThresholdChangeRequestMessage }
        \cup { [tag |-> CpBreachCountThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpBreachCountThresholdChangeRequestMessage }
        \cup { [tag |-> ManualCpBreachTriggerRequestMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerRequestMessage }
        \cup { [tag |-> CpClearBreachRequestMessageCode, body |-> one] : one \in CheckedCpClearBreachRequestMessage }
        \cup { [tag |-> SingleOrderAllowIsoOrdersChangeRequestMessageCode, body |-> one] : one \in CheckedSingleOrderAllowIsoOrdersChangeRequestMessage }
        \cup { [tag |-> SingleOrderAllowOrdersInCrossedMarketChangeRequestMessageCode, body |-> one] : one \in CheckedSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage }
        \cup { [tag |-> SingleOrderMaxNotionalChangeRequestMessageCode, body |-> one] : one \in CheckedSingleOrderMaxNotionalChangeRequestMessage }
        \cup { [tag |-> SingleOrderMaxContractsChangeRequestMessageCode, body |-> one] : one \in CheckedSingleOrderMaxContractsChangeRequestMessage }
        \cup { [tag |-> SingleOrderAllowMarketOrdersChangeRequestMessageCode, body |-> one] : one \in CheckedSingleOrderAllowMarketOrdersChangeRequestMessage }
        \cup { [tag |-> SingleOrderRestrictedUnderlierChangeRequestMessageCode, body |-> one] : one \in CheckedSingleOrderRestrictedUnderlierChangeRequestMessage }
        \cup { [tag |-> CpGrossNotionalThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpGrossNotionalThresholdChangeRequestMessage }
        \cup { [tag |-> CpMarketOrderGrossNotionalThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpMarketOrderGrossNotionalThresholdChangeRequestMessage }
        \cup { [tag |-> CpNetNotionalThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpNetNotionalThresholdChangeRequestMessage }
        \cup { [tag |-> CpMarketOrderNetNotionalThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpMarketOrderNetNotionalThresholdChangeRequestMessage }
        \cup { [tag |-> CpDuplicateOrderThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpDuplicateOrderThresholdChangeRequestMessage }
        \cup { [tag |-> CpOrderRateThresholdChangeRequestMessageCode, body |-> one] : one \in CheckedCpOrderRateThresholdChangeRequestMessage }
        \cup { [tag |-> CpClearAllBreachesRequestMessageCode, body |-> one] : one \in CheckedCpClearAllBreachesRequestMessage }
        \cup { [tag |-> CpClearAllBreachesByEfidOrUnderlierRequestMessageCode, body |-> one] : one \in CheckedCpClearAllBreachesByEfidOrUnderlierRequestMessage }
        \cup { [tag |-> ActiveRiskAcknowledgeAllRequestMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgeAllRequestMessage }
        \cup { [tag |-> ActiveRiskThresholdStateMessageCode, body |-> one] : one \in CheckedActiveRiskThresholdStateMessage }
        \cup { [tag |-> ActiveRiskThresholdChangeRejectedMessageCode, body |-> one] : one \in CheckedActiveRiskThresholdChangeRejectedMessage }
        \cup { [tag |-> ActiveRiskAcknowledgedMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgedMessage }
        \cup { [tag |-> ActiveRiskAcknowledgeRejectedMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgeRejectedMessage }
        \cup { [tag |-> ActiveRiskQuantityUpdateNotificationMessageCode, body |-> one] : one \in CheckedActiveRiskQuantityUpdateNotificationMessage }
        \cup { [tag |-> CpVolumeThresholdStateMessageCode, body |-> one] : one \in CheckedCpVolumeThresholdStateMessage }
        \cup { [tag |-> CpExecutedNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedCpExecutedNotionalThresholdStateMessage }
        \cup { [tag |-> CpTotalExecutionsThresholdStateMessageCode, body |-> one] : one \in CheckedCpTotalExecutionsThresholdStateMessage }
        \cup { [tag |-> CpPercentOutstandingContractsThresholdStateMessageCode, body |-> one] : one \in CheckedCpPercentOutstandingContractsThresholdStateMessage }
        \cup { [tag |-> CpBreachCountThresholdStateMessageCode, body |-> one] : one \in CheckedCpBreachCountThresholdStateMessage }
        \cup { [tag |-> ManualCpBreachTriggerPendingMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerPendingMessage }
        \cup { [tag |-> ManualCpBreachTriggerDoneMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerDoneMessage }
        \cup { [tag |-> RiskThresholdUpdateRejectedMessageCode, body |-> one] : one \in CheckedRiskThresholdUpdateRejectedMessage }
        \cup { [tag |-> PassiveRiskThresholdNotificationMessageCode, body |-> one] : one \in CheckedPassiveRiskThresholdNotificationMessage }
        \cup { [tag |-> SingleOrderAllowIsoOrdersStateMessageCode, body |-> one] : one \in CheckedSingleOrderAllowIsoOrdersStateMessage }
        \cup { [tag |-> SingleOrderAllowOrdersInCrossedMarketStateMessageCode, body |-> one] : one \in CheckedSingleOrderAllowOrdersInCrossedMarketStateMessage }
        \cup { [tag |-> SingleOrderMaxNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedSingleOrderMaxNotionalThresholdStateMessage }
        \cup { [tag |-> SingleOrderMaxContractsThresholdStateMessageCode, body |-> one] : one \in CheckedSingleOrderMaxContractsThresholdStateMessage }
        \cup { [tag |-> SingleOrderAllowMarketOrdersStateMessageCode, body |-> one] : one \in CheckedSingleOrderAllowMarketOrdersStateMessage }
        \cup { [tag |-> SingleOrderRestrictedUnderlierStateMessageCode, body |-> one] : one \in CheckedSingleOrderRestrictedUnderlierStateMessage }
        \cup { [tag |-> RiskSettingsQueryDoneMessageCode, body |-> one] : one \in CheckedRiskSettingsQueryDoneMessage }
        \cup { [tag |-> RiskSettingsQueryRejectedMessageCode, body |-> one] : one \in CheckedRiskSettingsQueryRejectedMessage }
        \cup { [tag |-> ManualCpBreachTriggerRejectedMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerRejectedMessage }
        \cup { [tag |-> BreachClearRejectedMessageCode, body |-> one] : one \in CheckedBreachClearRejectedMessage }
        \cup { [tag |-> BreachClearedMessageCode, body |-> one] : one \in CheckedBreachClearedMessage }
        \cup { [tag |-> BreachClearAllAcceptedMessageCode, body |-> one] : one \in CheckedBreachClearAllAcceptedMessage }
        \cup { [tag |-> BreachClearAllRejectedMessageCode, body |-> one] : one \in CheckedBreachClearAllRejectedMessage }
        \cup { [tag |-> BreachClearAllByEfidOrUnderlierAcceptedMessageCode, body |-> one] : one \in CheckedBreachClearAllByEfidOrUnderlierAcceptedMessage }
        \cup { [tag |-> BreachClearAllByEfidOrUnderlierRejectedMessageCode, body |-> one] : one \in CheckedBreachClearAllByEfidOrUnderlierRejectedMessage }
        \cup { [tag |-> CpGrossNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedCpGrossNotionalThresholdStateMessage }
        \cup { [tag |-> CpMarketOrderGrossNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedCpMarketOrderGrossNotionalThresholdStateMessage }
        \cup { [tag |-> CpNetNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedCpNetNotionalThresholdStateMessage }
        \cup { [tag |-> CpMarketOrderNetNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedCpMarketOrderNetNotionalThresholdStateMessage }
        \cup { [tag |-> CpDuplicateOrderThresholdStateMessageCode, body |-> one] : one \in CheckedCpDuplicateOrderThresholdStateMessage }
        \cup { [tag |-> CpOrderRateThresholdStateMessageCode, body |-> one] : one \in CheckedCpOrderRateThresholdStateMessage }

(***************************************************************************)
(* Sbe Message                                                             *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(1),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.payload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 1 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Sequenced Message                                                       *)
(***************************************************************************)

SequencedMessage ==
    [ sbeMessage : SbeMessage ]

EncodeSequencedMessage(message) ==
    EncodeSbeMessage(message.sbeMessage)

DecodeSequencedMessage(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroSequencedMessage ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessage ==
    { ZeroSequencedMessage }
        \cup { [ZeroSequencedMessage EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

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

(* Every Risk Settings Query Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskSettingsQueryMessage ==
    \A message \in CheckedRiskSettingsQueryMessage :
        LET read == DecodeRiskSettingsQueryMessage(EncodeRiskSettingsQueryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskThresholdChangeRequestMessage ==
    \A message \in CheckedActiveRiskThresholdChangeRequestMessage :
        LET read == DecodeActiveRiskThresholdChangeRequestMessage(EncodeActiveRiskThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Acknowledgement Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskAcknowledgementRequestMessage ==
    \A message \in CheckedActiveRiskAcknowledgementRequestMessage :
        LET read == DecodeActiveRiskAcknowledgementRequestMessage(EncodeActiveRiskAcknowledgementRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Volume Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpVolumeThresholdChangeRequestMessage ==
    \A message \in CheckedCpVolumeThresholdChangeRequestMessage :
        LET read == DecodeCpVolumeThresholdChangeRequestMessage(EncodeCpVolumeThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Executed Notional Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpExecutedNotionalThresholdChangeRequestMessage ==
    \A message \in CheckedCpExecutedNotionalThresholdChangeRequestMessage :
        LET read == DecodeCpExecutedNotionalThresholdChangeRequestMessage(EncodeCpExecutedNotionalThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Total Executions Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpTotalExecutionsThresholdChangeRequestMessage ==
    \A message \in CheckedCpTotalExecutionsThresholdChangeRequestMessage :
        LET read == DecodeCpTotalExecutionsThresholdChangeRequestMessage(EncodeCpTotalExecutionsThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Percent Outstanding Contracts Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpPercentOutstandingContractsThresholdChangeRequestMessage ==
    \A message \in CheckedCpPercentOutstandingContractsThresholdChangeRequestMessage :
        LET read == DecodeCpPercentOutstandingContractsThresholdChangeRequestMessage(EncodeCpPercentOutstandingContractsThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Breach Count Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpBreachCountThresholdChangeRequestMessage ==
    \A message \in CheckedCpBreachCountThresholdChangeRequestMessage :
        LET read == DecodeCpBreachCountThresholdChangeRequestMessage(EncodeCpBreachCountThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Cp Breach Trigger Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualCpBreachTriggerRequestMessage ==
    \A message \in CheckedManualCpBreachTriggerRequestMessage :
        LET read == DecodeManualCpBreachTriggerRequestMessage(EncodeManualCpBreachTriggerRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Clear Breach Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpClearBreachRequestMessage ==
    \A message \in CheckedCpClearBreachRequestMessage :
        LET read == DecodeCpClearBreachRequestMessage(EncodeCpClearBreachRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Iso Orders Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowIsoOrdersChangeRequestMessage ==
    \A message \in CheckedSingleOrderAllowIsoOrdersChangeRequestMessage :
        LET read == DecodeSingleOrderAllowIsoOrdersChangeRequestMessage(EncodeSingleOrderAllowIsoOrdersChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Orders In Crossed Market Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    \A message \in CheckedSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage :
        LET read == DecodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(EncodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Max Notional Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderMaxNotionalChangeRequestMessage ==
    \A message \in CheckedSingleOrderMaxNotionalChangeRequestMessage :
        LET read == DecodeSingleOrderMaxNotionalChangeRequestMessage(EncodeSingleOrderMaxNotionalChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Max Contracts Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderMaxContractsChangeRequestMessage ==
    \A message \in CheckedSingleOrderMaxContractsChangeRequestMessage :
        LET read == DecodeSingleOrderMaxContractsChangeRequestMessage(EncodeSingleOrderMaxContractsChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Market Orders Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowMarketOrdersChangeRequestMessage ==
    \A message \in CheckedSingleOrderAllowMarketOrdersChangeRequestMessage :
        LET read == DecodeSingleOrderAllowMarketOrdersChangeRequestMessage(EncodeSingleOrderAllowMarketOrdersChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Restricted Underlier Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderRestrictedUnderlierChangeRequestMessage ==
    \A message \in CheckedSingleOrderRestrictedUnderlierChangeRequestMessage :
        LET read == DecodeSingleOrderRestrictedUnderlierChangeRequestMessage(EncodeSingleOrderRestrictedUnderlierChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Gross Notional Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpGrossNotionalThresholdChangeRequestMessage ==
    \A message \in CheckedCpGrossNotionalThresholdChangeRequestMessage :
        LET read == DecodeCpGrossNotionalThresholdChangeRequestMessage(EncodeCpGrossNotionalThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Market Order Gross Notional Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    \A message \in CheckedCpMarketOrderGrossNotionalThresholdChangeRequestMessage :
        LET read == DecodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(EncodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Net Notional Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpNetNotionalThresholdChangeRequestMessage ==
    \A message \in CheckedCpNetNotionalThresholdChangeRequestMessage :
        LET read == DecodeCpNetNotionalThresholdChangeRequestMessage(EncodeCpNetNotionalThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Market Order Net Notional Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    \A message \in CheckedCpMarketOrderNetNotionalThresholdChangeRequestMessage :
        LET read == DecodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(EncodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Duplicate Order Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpDuplicateOrderThresholdChangeRequestMessage ==
    \A message \in CheckedCpDuplicateOrderThresholdChangeRequestMessage :
        LET read == DecodeCpDuplicateOrderThresholdChangeRequestMessage(EncodeCpDuplicateOrderThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Order Rate Threshold Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpOrderRateThresholdChangeRequestMessage ==
    \A message \in CheckedCpOrderRateThresholdChangeRequestMessage :
        LET read == DecodeCpOrderRateThresholdChangeRequestMessage(EncodeCpOrderRateThresholdChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Clear All Breaches Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpClearAllBreachesRequestMessage ==
    \A message \in CheckedCpClearAllBreachesRequestMessage :
        LET read == DecodeCpClearAllBreachesRequestMessage(EncodeCpClearAllBreachesRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Clear All Breaches By Efid Or Underlier Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    \A message \in CheckedCpClearAllBreachesByEfidOrUnderlierRequestMessage :
        LET read == DecodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(EncodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Acknowledge All Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskAcknowledgeAllRequestMessage ==
    \A message \in CheckedActiveRiskAcknowledgeAllRequestMessage :
        LET read == DecodeActiveRiskAcknowledgeAllRequestMessage(EncodeActiveRiskAcknowledgeAllRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskThresholdStateMessage ==
    \A message \in CheckedActiveRiskThresholdStateMessage :
        LET read == DecodeActiveRiskThresholdStateMessage(EncodeActiveRiskThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Threshold Change Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskThresholdChangeRejectedMessage ==
    \A message \in CheckedActiveRiskThresholdChangeRejectedMessage :
        LET read == DecodeActiveRiskThresholdChangeRejectedMessage(EncodeActiveRiskThresholdChangeRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Acknowledged Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskAcknowledgedMessage ==
    \A message \in CheckedActiveRiskAcknowledgedMessage :
        LET read == DecodeActiveRiskAcknowledgedMessage(EncodeActiveRiskAcknowledgedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Acknowledge Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskAcknowledgeRejectedMessage ==
    \A message \in CheckedActiveRiskAcknowledgeRejectedMessage :
        LET read == DecodeActiveRiskAcknowledgeRejectedMessage(EncodeActiveRiskAcknowledgeRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Quantity Update Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskQuantityUpdateNotificationMessage ==
    \A message \in CheckedActiveRiskQuantityUpdateNotificationMessage :
        LET read == DecodeActiveRiskQuantityUpdateNotificationMessage(EncodeActiveRiskQuantityUpdateNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Volume Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpVolumeThresholdStateMessage ==
    \A message \in CheckedCpVolumeThresholdStateMessage :
        LET read == DecodeCpVolumeThresholdStateMessage(EncodeCpVolumeThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Executed Notional Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpExecutedNotionalThresholdStateMessage ==
    \A message \in CheckedCpExecutedNotionalThresholdStateMessage :
        LET read == DecodeCpExecutedNotionalThresholdStateMessage(EncodeCpExecutedNotionalThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Total Executions Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpTotalExecutionsThresholdStateMessage ==
    \A message \in CheckedCpTotalExecutionsThresholdStateMessage :
        LET read == DecodeCpTotalExecutionsThresholdStateMessage(EncodeCpTotalExecutionsThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Percent Outstanding Contracts Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpPercentOutstandingContractsThresholdStateMessage ==
    \A message \in CheckedCpPercentOutstandingContractsThresholdStateMessage :
        LET read == DecodeCpPercentOutstandingContractsThresholdStateMessage(EncodeCpPercentOutstandingContractsThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Breach Count Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpBreachCountThresholdStateMessage ==
    \A message \in CheckedCpBreachCountThresholdStateMessage :
        LET read == DecodeCpBreachCountThresholdStateMessage(EncodeCpBreachCountThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Cp Breach Trigger Pending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualCpBreachTriggerPendingMessage ==
    \A message \in CheckedManualCpBreachTriggerPendingMessage :
        LET read == DecodeManualCpBreachTriggerPendingMessage(EncodeManualCpBreachTriggerPendingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Cp Breach Trigger Done Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualCpBreachTriggerDoneMessage ==
    \A message \in CheckedManualCpBreachTriggerDoneMessage :
        LET read == DecodeManualCpBreachTriggerDoneMessage(EncodeManualCpBreachTriggerDoneMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Threshold Update Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskThresholdUpdateRejectedMessage ==
    \A message \in CheckedRiskThresholdUpdateRejectedMessage :
        LET read == DecodeRiskThresholdUpdateRejectedMessage(EncodeRiskThresholdUpdateRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Passive Risk Threshold Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPassiveRiskThresholdNotificationMessage ==
    \A message \in CheckedPassiveRiskThresholdNotificationMessage :
        LET read == DecodePassiveRiskThresholdNotificationMessage(EncodePassiveRiskThresholdNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Iso Orders State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowIsoOrdersStateMessage ==
    \A message \in CheckedSingleOrderAllowIsoOrdersStateMessage :
        LET read == DecodeSingleOrderAllowIsoOrdersStateMessage(EncodeSingleOrderAllowIsoOrdersStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Orders In Crossed Market State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowOrdersInCrossedMarketStateMessage ==
    \A message \in CheckedSingleOrderAllowOrdersInCrossedMarketStateMessage :
        LET read == DecodeSingleOrderAllowOrdersInCrossedMarketStateMessage(EncodeSingleOrderAllowOrdersInCrossedMarketStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Max Notional Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderMaxNotionalThresholdStateMessage ==
    \A message \in CheckedSingleOrderMaxNotionalThresholdStateMessage :
        LET read == DecodeSingleOrderMaxNotionalThresholdStateMessage(EncodeSingleOrderMaxNotionalThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Max Contracts Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderMaxContractsThresholdStateMessage ==
    \A message \in CheckedSingleOrderMaxContractsThresholdStateMessage :
        LET read == DecodeSingleOrderMaxContractsThresholdStateMessage(EncodeSingleOrderMaxContractsThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Market Orders State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowMarketOrdersStateMessage ==
    \A message \in CheckedSingleOrderAllowMarketOrdersStateMessage :
        LET read == DecodeSingleOrderAllowMarketOrdersStateMessage(EncodeSingleOrderAllowMarketOrdersStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Restricted Underlier State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderRestrictedUnderlierStateMessage ==
    \A message \in CheckedSingleOrderRestrictedUnderlierStateMessage :
        LET read == DecodeSingleOrderRestrictedUnderlierStateMessage(EncodeSingleOrderRestrictedUnderlierStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Settings Query Done Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskSettingsQueryDoneMessage ==
    \A message \in CheckedRiskSettingsQueryDoneMessage :
        LET read == DecodeRiskSettingsQueryDoneMessage(EncodeRiskSettingsQueryDoneMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Settings Query Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskSettingsQueryRejectedMessage ==
    \A message \in CheckedRiskSettingsQueryRejectedMessage :
        LET read == DecodeRiskSettingsQueryRejectedMessage(EncodeRiskSettingsQueryRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Cp Breach Trigger Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualCpBreachTriggerRejectedMessage ==
    \A message \in CheckedManualCpBreachTriggerRejectedMessage :
        LET read == DecodeManualCpBreachTriggerRejectedMessage(EncodeManualCpBreachTriggerRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Clear Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearRejectedMessage ==
    \A message \in CheckedBreachClearRejectedMessage :
        LET read == DecodeBreachClearRejectedMessage(EncodeBreachClearRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Cleared Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearedMessage ==
    \A message \in CheckedBreachClearedMessage :
        LET read == DecodeBreachClearedMessage(EncodeBreachClearedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Clear All Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearAllAcceptedMessage ==
    \A message \in CheckedBreachClearAllAcceptedMessage :
        LET read == DecodeBreachClearAllAcceptedMessage(EncodeBreachClearAllAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Clear All Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearAllRejectedMessage ==
    \A message \in CheckedBreachClearAllRejectedMessage :
        LET read == DecodeBreachClearAllRejectedMessage(EncodeBreachClearAllRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Clear All By Efid Or Underlier Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearAllByEfidOrUnderlierAcceptedMessage ==
    \A message \in CheckedBreachClearAllByEfidOrUnderlierAcceptedMessage :
        LET read == DecodeBreachClearAllByEfidOrUnderlierAcceptedMessage(EncodeBreachClearAllByEfidOrUnderlierAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Clear All By Efid Or Underlier Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearAllByEfidOrUnderlierRejectedMessage ==
    \A message \in CheckedBreachClearAllByEfidOrUnderlierRejectedMessage :
        LET read == DecodeBreachClearAllByEfidOrUnderlierRejectedMessage(EncodeBreachClearAllByEfidOrUnderlierRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Gross Notional Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpGrossNotionalThresholdStateMessage ==
    \A message \in CheckedCpGrossNotionalThresholdStateMessage :
        LET read == DecodeCpGrossNotionalThresholdStateMessage(EncodeCpGrossNotionalThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Market Order Gross Notional Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpMarketOrderGrossNotionalThresholdStateMessage ==
    \A message \in CheckedCpMarketOrderGrossNotionalThresholdStateMessage :
        LET read == DecodeCpMarketOrderGrossNotionalThresholdStateMessage(EncodeCpMarketOrderGrossNotionalThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Net Notional Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpNetNotionalThresholdStateMessage ==
    \A message \in CheckedCpNetNotionalThresholdStateMessage :
        LET read == DecodeCpNetNotionalThresholdStateMessage(EncodeCpNetNotionalThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Market Order Net Notional Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpMarketOrderNetNotionalThresholdStateMessage ==
    \A message \in CheckedCpMarketOrderNetNotionalThresholdStateMessage :
        LET read == DecodeCpMarketOrderNetNotionalThresholdStateMessage(EncodeCpMarketOrderNetNotionalThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Duplicate Order Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpDuplicateOrderThresholdStateMessage ==
    \A message \in CheckedCpDuplicateOrderThresholdStateMessage :
        LET read == DecodeCpDuplicateOrderThresholdStateMessage(EncodeCpDuplicateOrderThresholdStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Order Rate Threshold State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpOrderRateThresholdStateMessage ==
    \A message \in CheckedCpOrderRateThresholdStateMessage :
        LET read == DecodeCpOrderRateThresholdStateMessage(EncodeCpOrderRateThresholdStateMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
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
