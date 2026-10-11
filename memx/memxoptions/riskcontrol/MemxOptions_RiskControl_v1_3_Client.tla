---------------- MODULE MemxOptions_RiskControl_v1_3_Client ----------------
(***************************************************************************)
(* The Members Exchange Risk Control v1.3                                  *)
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
(* Login Request Message: 2 bytes                                          *)
(***************************************************************************)

LoginRequestMessage ==
    [ tokenType : Sample(1),
      token     : Sample(1) ]

EncodeLoginRequestMessage(message) ==
    message.tokenType
        \o message.token

DecodeLoginRequestMessage(bytes) ==
    LET tokenType == ReadBytes(bytes, 1) IN IF ~tokenType.ok THEN Fail ELSE
    LET token == ReadBytes(tokenType.rest, 1) IN IF ~token.ok THEN Fail ELSE
    Ok([ tokenType |-> tokenType.value,
         token     |-> token.value ], token.rest)

ZeroLoginRequestMessage ==
    [ tokenType |-> [i \in 1 .. 1 |-> 0],
      token     |-> [i \in 1 .. 1 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.tokenType = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.token = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Request Message: 20 bytes                                        *)
(***************************************************************************)

ReplayRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8),
      count              : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber
        \o message.count

DecodeReplayRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET count == ReadBytes(nextSequenceNumber.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value,
         count              |-> count.value ], count.rest)

ZeroReplayRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      count              |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay All Request Message: 8 bytes                                     *)
(***************************************************************************)

ReplayAllRequestMessage ==
    [ sessionId : Sample(8) ]

EncodeReplayAllRequestMessage(message) ==
    message.sessionId

DecodeReplayAllRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroReplayAllRequestMessage ==
    [ sessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Replay All Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayAllRequestMessage ==
    { ZeroReplayAllRequestMessage }
        \cup { [ZeroReplayAllRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Request Message: 16 bytes                                        *)
(***************************************************************************)

StreamRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8) ]

EncodeStreamRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber

DecodeStreamRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroStreamRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Request Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamRequestMessage ==
    { ZeroStreamRequestMessage }
        \cup { [ZeroStreamRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroStreamRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }

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
(* Active Risk Threshold Change Req Message: 34 bytes                      *)
(***************************************************************************)

ActiveRiskThresholdChangeReqMessage ==
    [ clordid                                        : Sample(20),
      underlierActiveRiskThresholdChangeReqUnderlier : Sample(6),
      efidActiveRiskThresholdChangeReqEfid           : Sample(4),
      thresholdQuantity                              : Sample(4) ]

EncodeActiveRiskThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierActiveRiskThresholdChangeReqUnderlier
        \o message.efidActiveRiskThresholdChangeReqEfid
        \o message.thresholdQuantity

DecodeActiveRiskThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierActiveRiskThresholdChangeReqUnderlier == ReadBytes(clordid.rest, 6) IN IF ~underlierActiveRiskThresholdChangeReqUnderlier.ok THEN Fail ELSE
    LET efidActiveRiskThresholdChangeReqEfid == ReadBytes(underlierActiveRiskThresholdChangeReqUnderlier.rest, 4) IN IF ~efidActiveRiskThresholdChangeReqEfid.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidActiveRiskThresholdChangeReqEfid.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    Ok([ clordid                                        |-> clordid.value,
         underlierActiveRiskThresholdChangeReqUnderlier |-> underlierActiveRiskThresholdChangeReqUnderlier.value,
         efidActiveRiskThresholdChangeReqEfid           |-> efidActiveRiskThresholdChangeReqEfid.value,
         thresholdQuantity                              |-> thresholdQuantity.value ], thresholdQuantity.rest)

ZeroActiveRiskThresholdChangeReqMessage ==
    [ clordid                                        |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskThresholdChangeReqUnderlier |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskThresholdChangeReqEfid           |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity                              |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdChangeReqMessage ==
    { ZeroActiveRiskThresholdChangeReqMessage }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.underlierActiveRiskThresholdChangeReqUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.efidActiveRiskThresholdChangeReqEfid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledgement Req Message: 34 bytes                       *)
(***************************************************************************)

ActiveRiskAcknowledgementReqMessage ==
    [ clordid   : Sample(20),
      underlier : Sample(6),
      efid      : Sample(4),
      quantity  : Sample(4) ]

EncodeActiveRiskAcknowledgementReqMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efid
        \o message.quantity

DecodeActiveRiskAcknowledgementReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET quantity == ReadBytes(efid.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ clordid   |-> clordid.value,
         underlier |-> underlier.value,
         efid      |-> efid.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroActiveRiskAcknowledgementReqMessage ==
    [ clordid   |-> [i \in 1 .. 20 |-> 0],
      underlier |-> [i \in 1 .. 6 |-> 0],
      efid      |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledgement Req Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgementReqMessage ==
    { ZeroActiveRiskAcknowledgementReqMessage }
        \cup { [ZeroActiveRiskAcknowledgementReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgementReqMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgementReqMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgementReqMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Volume Threshold Change Req Message: 44 bytes                        *)
(***************************************************************************)

CpVolumeThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      volume               : Sample(8),
      periodInMilliSeconds : Sample(4) ]

EncodeCpVolumeThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.volume
        \o message.periodInMilliSeconds

DecodeCpVolumeThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET volume == ReadBytes(riskGroupId.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(volume.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         volume               |-> volume.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpVolumeThresholdChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      volume               |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Volume Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpVolumeThresholdChangeReqMessage ==
    { ZeroCpVolumeThresholdChangeReqMessage }
        \cup { [ZeroCpVolumeThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpVolumeThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpVolumeThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpVolumeThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpVolumeThresholdChangeReqMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroCpVolumeThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Executed Notional Threshold Change Req Message: 40 bytes             *)
(***************************************************************************)

CpExecutedNotionalThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      priceInDollars       : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpExecutedNotionalThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars
        \o message.periodInMilliSeconds

DecodeCpExecutedNotionalThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(priceInDollars.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         priceInDollars       |-> priceInDollars.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpExecutedNotionalThresholdChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      priceInDollars       |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Executed Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpExecutedNotionalThresholdChangeReqMessage ==
    { ZeroCpExecutedNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Total Executions Threshold Change Req Message: 40 bytes              *)
(***************************************************************************)

CpTotalExecutionsThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      totalExecutions      : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpTotalExecutionsThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.totalExecutions
        \o message.periodInMilliSeconds

DecodeCpTotalExecutionsThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET totalExecutions == ReadBytes(riskGroupId.rest, 4) IN IF ~totalExecutions.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(totalExecutions.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         totalExecutions      |-> totalExecutions.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpTotalExecutionsThresholdChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      totalExecutions      |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Total Executions Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpTotalExecutionsThresholdChangeReqMessage ==
    { ZeroCpTotalExecutionsThresholdChangeReqMessage }
        \cup { [ZeroCpTotalExecutionsThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeReqMessage EXCEPT !.totalExecutions = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Percent Outstanding Contracts Threshold Change Req Message: 38 bytes *)
(***************************************************************************)

CpPercentOutstandingContractsThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      percent              : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpPercentOutstandingContractsThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.percent
        \o message.periodInMilliSeconds

DecodeCpPercentOutstandingContractsThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET percent == ReadBytes(efidOptional.rest, 4) IN IF ~percent.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(percent.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         percent              |-> percent.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpPercentOutstandingContractsThresholdChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      percent              |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Percent Outstanding Contracts Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpPercentOutstandingContractsThresholdChangeReqMessage ==
    { ZeroCpPercentOutstandingContractsThresholdChangeReqMessage }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeReqMessage EXCEPT !.percent = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Breach Count Threshold Change Req Message: 40 bytes                  *)
(***************************************************************************)

CpBreachCountThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      count                : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpBreachCountThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.count
        \o message.periodInMilliSeconds

DecodeCpBreachCountThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET count == ReadBytes(riskGroupId.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(count.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         count                |-> count.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpBreachCountThresholdChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      count                |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Breach Count Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpBreachCountThresholdChangeReqMessage ==
    { ZeroCpBreachCountThresholdChangeReqMessage }
        \cup { [ZeroCpBreachCountThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpBreachCountThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpBreachCountThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpBreachCountThresholdChangeReqMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Manual Cp Breach Trigger Req Message: 33 bytes                          *)
(***************************************************************************)

ManualCpBreachTriggerReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      sendCancels       : Sample(1) ]

EncodeManualCpBreachTriggerReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.sendCancels

DecodeManualCpBreachTriggerReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET sendCancels == ReadBytes(riskGroupId.rest, 1) IN IF ~sendCancels.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         sendCancels       |-> sendCancels.value ], sendCancels.rest)

ZeroManualCpBreachTriggerReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      sendCancels       |-> [i \in 1 .. 1 |-> 0] ]

(* Manual Cp Breach Trigger Req Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerReqMessage ==
    { ZeroManualCpBreachTriggerReqMessage }
        \cup { [ZeroManualCpBreachTriggerReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerReqMessage EXCEPT !.sendCancels = one] : one \in Sample(1) }

(***************************************************************************)
(* Cp Clear Breach Req Message: 28 bytes                                   *)
(***************************************************************************)

CpClearBreachReqMessage ==
    [ clordid  : Sample(20),
      breachId : Sample(8) ]

EncodeCpClearBreachReqMessage(message) ==
    message.clordid
        \o message.breachId

DecodeCpClearBreachReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET breachId == ReadBytes(clordid.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    Ok([ clordid  |-> clordid.value,
         breachId |-> breachId.value ], breachId.rest)

ZeroCpClearBreachReqMessage ==
    [ clordid  |-> [i \in 1 .. 20 |-> 0],
      breachId |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Clear Breach Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearBreachReqMessage ==
    { ZeroCpClearBreachReqMessage }
        \cup { [ZeroCpClearBreachReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpClearBreachReqMessage EXCEPT !.breachId = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Allow Iso Orders Change Req Message: 33 bytes              *)
(***************************************************************************)

SingleOrderAllowIsoOrdersChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowIsoOrders    : Sample(1) ]

EncodeSingleOrderAllowIsoOrdersChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowIsoOrders

DecodeSingleOrderAllowIsoOrdersChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowIsoOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowIsoOrders.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         allowIsoOrders    |-> allowIsoOrders.value ], allowIsoOrders.rest)

ZeroSingleOrderAllowIsoOrdersChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowIsoOrders    |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Iso Orders Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowIsoOrdersChangeReqMessage ==
    { ZeroSingleOrderAllowIsoOrdersChangeReqMessage }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeReqMessage EXCEPT !.allowIsoOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Allow Orders In Crossed Market Change Req Message: 33      *)
(* bytes                                                                   *)
(***************************************************************************)

SingleOrderAllowOrdersInCrossedMarketChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowOrders       : Sample(1) ]

EncodeSingleOrderAllowOrdersInCrossedMarketChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowOrders

DecodeSingleOrderAllowOrdersInCrossedMarketChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowOrders.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         allowOrders       |-> allowOrders.value ], allowOrders.rest)

ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowOrders       |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Orders In Crossed Market Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowOrdersInCrossedMarketChangeReqMessage ==
    { ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeReqMessage EXCEPT !.allowOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Max Notional Change Req Message: 36 bytes                  *)
(***************************************************************************)

SingleOrderMaxNotionalChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxNotionalInDollars : Sample(4) ]

EncodeSingleOrderMaxNotionalChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxNotionalInDollars

DecodeSingleOrderMaxNotionalChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxNotionalInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~maxNotionalInDollars.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         maxNotionalInDollars |-> maxNotionalInDollars.value ], maxNotionalInDollars.rest)

ZeroSingleOrderMaxNotionalChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      maxNotionalInDollars |-> [i \in 1 .. 4 |-> 0] ]

(* Single Order Max Notional Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxNotionalChangeReqMessage ==
    { ZeroSingleOrderMaxNotionalChangeReqMessage }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.maxNotionalInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Order Max Contracts Change Req Message: 36 bytes                 *)
(***************************************************************************)

SingleOrderMaxContractsChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      maxContracts      : Sample(4) ]

EncodeSingleOrderMaxContractsChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxContracts

DecodeSingleOrderMaxContractsChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxContracts == ReadBytes(riskGroupId.rest, 4) IN IF ~maxContracts.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         maxContracts      |-> maxContracts.value ], maxContracts.rest)

ZeroSingleOrderMaxContractsChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      maxContracts      |-> [i \in 1 .. 4 |-> 0] ]

(* Single Order Max Contracts Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxContractsChangeReqMessage ==
    { ZeroSingleOrderMaxContractsChangeReqMessage }
        \cup { [ZeroSingleOrderMaxContractsChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxContractsChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxContractsChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxContractsChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxContractsChangeReqMessage EXCEPT !.maxContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Gross Notional Threshold Change Req Message: 36 bytes                *)
(***************************************************************************)

CpGrossNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

EncodeCpGrossNotionalThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpGrossNotionalThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpGrossNotionalThresholdChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Gross Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpGrossNotionalThresholdChangeReqMessage ==
    { ZeroCpGrossNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Market Order Gross Notional Threshold Change Req Message: 36 bytes   *)
(***************************************************************************)

CpMarketOrderGrossNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

EncodeCpMarketOrderGrossNotionalThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderGrossNotionalThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Market Order Gross Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderGrossNotionalThresholdChangeReqMessage ==
    { ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Net Notional Threshold Change Req Message: 36 bytes                  *)
(***************************************************************************)

CpNetNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

EncodeCpNetNotionalThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpNetNotionalThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpNetNotionalThresholdChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Net Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpNetNotionalThresholdChangeReqMessage ==
    { ZeroCpNetNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Market Order Net Notional Threshold Change Req Message: 36 bytes     *)
(***************************************************************************)

CpMarketOrderNetNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

EncodeCpMarketOrderNetNotionalThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderNetNotionalThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         priceInDollars    |-> priceInDollars.value ], priceInDollars.rest)

ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Market Order Net Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderNetNotionalThresholdChangeReqMessage ==
    { ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Duplicate Order Threshold Change Req Message: 41 bytes               *)
(***************************************************************************)

CpDuplicateOrderThresholdChangeReqMessage ==
    [ clordid                         : Sample(20),
      underlierOptional               : Sample(6),
      efidOptional                    : Sample(4),
      riskGroupId                     : Sample(2),
      maxDupOrders                    : Sample(4),
      useOrderPriceInDupCheckOptional : Sample(1),
      periodInMilliSeconds            : Sample(4) ]

EncodeCpDuplicateOrderThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxDupOrders
        \o message.useOrderPriceInDupCheckOptional
        \o message.periodInMilliSeconds

DecodeCpDuplicateOrderThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxDupOrders == ReadBytes(riskGroupId.rest, 4) IN IF ~maxDupOrders.ok THEN Fail ELSE
    LET useOrderPriceInDupCheckOptional == ReadBytes(maxDupOrders.rest, 1) IN IF ~useOrderPriceInDupCheckOptional.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(useOrderPriceInDupCheckOptional.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid                         |-> clordid.value,
         underlierOptional               |-> underlierOptional.value,
         efidOptional                    |-> efidOptional.value,
         riskGroupId                     |-> riskGroupId.value,
         maxDupOrders                    |-> maxDupOrders.value,
         useOrderPriceInDupCheckOptional |-> useOrderPriceInDupCheckOptional.value,
         periodInMilliSeconds            |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpDuplicateOrderThresholdChangeReqMessage ==
    [ clordid                         |-> [i \in 1 .. 20 |-> 0],
      underlierOptional               |-> [i \in 1 .. 6 |-> 0],
      efidOptional                    |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                     |-> [i \in 1 .. 2 |-> 0],
      maxDupOrders                    |-> [i \in 1 .. 4 |-> 0],
      useOrderPriceInDupCheckOptional |-> [i \in 1 .. 1 |-> 0],
      periodInMilliSeconds            |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Duplicate Order Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpDuplicateOrderThresholdChangeReqMessage ==
    { ZeroCpDuplicateOrderThresholdChangeReqMessage }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.maxDupOrders = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.useOrderPriceInDupCheckOptional = one] : one \in Sample(1) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Order Rate Threshold Change Req Message: 40 bytes                    *)
(***************************************************************************)

CpOrderRateThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxOrderMsgs         : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpOrderRateThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxOrderMsgs
        \o message.periodInMilliSeconds

DecodeCpOrderRateThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET maxOrderMsgs == ReadBytes(riskGroupId.rest, 4) IN IF ~maxOrderMsgs.ok THEN Fail ELSE
    LET periodInMilliSeconds == ReadBytes(maxOrderMsgs.rest, 4) IN IF ~periodInMilliSeconds.ok THEN Fail ELSE
    Ok([ clordid              |-> clordid.value,
         underlierOptional    |-> underlierOptional.value,
         efidOptional         |-> efidOptional.value,
         riskGroupId          |-> riskGroupId.value,
         maxOrderMsgs         |-> maxOrderMsgs.value,
         periodInMilliSeconds |-> periodInMilliSeconds.value ], periodInMilliSeconds.rest)

ZeroCpOrderRateThresholdChangeReqMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      maxOrderMsgs         |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Order Rate Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpOrderRateThresholdChangeReqMessage ==
    { ZeroCpOrderRateThresholdChangeReqMessage }
        \cup { [ZeroCpOrderRateThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpOrderRateThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpOrderRateThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpOrderRateThresholdChangeReqMessage EXCEPT !.maxOrderMsgs = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdChangeReqMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Threshold State Message: 34 bytes                           *)
(***************************************************************************)

ActiveRiskThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlier         : Sample(6),
      efid              : Sample(4),
      thresholdQuantity : Sample(4) ]

EncodeActiveRiskThresholdStateMessage(message) ==
    message.clordidOptional
        \o message.underlier
        \o message.efid
        \o message.thresholdQuantity

DecodeActiveRiskThresholdStateMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordidOptional.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efid.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    Ok([ clordidOptional   |-> clordidOptional.value,
         underlier         |-> underlier.value,
         efid              |-> efid.value,
         thresholdQuantity |-> thresholdQuantity.value ], thresholdQuantity.rest)

ZeroActiveRiskThresholdStateMessage ==
    [ clordidOptional   |-> [i \in 1 .. 20 |-> 0],
      underlier         |-> [i \in 1 .. 6 |-> 0],
      efid              |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdStateMessage ==
    { ZeroActiveRiskThresholdStateMessage }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdStateMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Threshold Change Rej Message: 36 bytes                      *)
(***************************************************************************)

ActiveRiskThresholdChangeRejMessage ==
    [ clordid                                        : Sample(20),
      underlierActiveRiskThresholdChangeRejUnderlier : Sample(6),
      efidActiveRiskThresholdChangeRejEfid           : Sample(4),
      thresholdQuantity                              : Sample(4),
      rejectReason                                   : Sample(2) ]

EncodeActiveRiskThresholdChangeRejMessage(message) ==
    message.clordid
        \o message.underlierActiveRiskThresholdChangeRejUnderlier
        \o message.efidActiveRiskThresholdChangeRejEfid
        \o message.thresholdQuantity
        \o message.rejectReason

DecodeActiveRiskThresholdChangeRejMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierActiveRiskThresholdChangeRejUnderlier == ReadBytes(clordid.rest, 6) IN IF ~underlierActiveRiskThresholdChangeRejUnderlier.ok THEN Fail ELSE
    LET efidActiveRiskThresholdChangeRejEfid == ReadBytes(underlierActiveRiskThresholdChangeRejUnderlier.rest, 4) IN IF ~efidActiveRiskThresholdChangeRejEfid.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidActiveRiskThresholdChangeRejEfid.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(thresholdQuantity.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clordid                                        |-> clordid.value,
         underlierActiveRiskThresholdChangeRejUnderlier |-> underlierActiveRiskThresholdChangeRejUnderlier.value,
         efidActiveRiskThresholdChangeRejEfid           |-> efidActiveRiskThresholdChangeRejEfid.value,
         thresholdQuantity                              |-> thresholdQuantity.value,
         rejectReason                                   |-> rejectReason.value ], rejectReason.rest)

ZeroActiveRiskThresholdChangeRejMessage ==
    [ clordid                                        |-> [i \in 1 .. 20 |-> 0],
      underlierActiveRiskThresholdChangeRejUnderlier |-> [i \in 1 .. 6 |-> 0],
      efidActiveRiskThresholdChangeRejEfid           |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity                              |-> [i \in 1 .. 4 |-> 0],
      rejectReason                                   |-> [i \in 1 .. 2 |-> 0] ]

(* Active Risk Threshold Change Rej Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdChangeRejMessage ==
    { ZeroActiveRiskThresholdChangeRejMessage }
        \cup { [ZeroActiveRiskThresholdChangeRejMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdChangeRejMessage EXCEPT !.underlierActiveRiskThresholdChangeRejUnderlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdChangeRejMessage EXCEPT !.efidActiveRiskThresholdChangeRejEfid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeRejMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeRejMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Active Risk Acknowledged Message: 38 bytes                              *)
(***************************************************************************)

ActiveRiskAcknowledgedMessage ==
    [ clordid         : Sample(20),
      underlier       : Sample(6),
      efid            : Sample(4),
      quantity        : Sample(4),
      unAckedQuantity : Sample(4) ]

EncodeActiveRiskAcknowledgedMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efid
        \o message.quantity
        \o message.unAckedQuantity

DecodeActiveRiskAcknowledgedMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET quantity == ReadBytes(efid.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET unAckedQuantity == ReadBytes(quantity.rest, 4) IN IF ~unAckedQuantity.ok THEN Fail ELSE
    Ok([ clordid         |-> clordid.value,
         underlier       |-> underlier.value,
         efid            |-> efid.value,
         quantity        |-> quantity.value,
         unAckedQuantity |-> unAckedQuantity.value ], unAckedQuantity.rest)

ZeroActiveRiskAcknowledgedMessage ==
    [ clordid         |-> [i \in 1 .. 20 |-> 0],
      underlier       |-> [i \in 1 .. 6 |-> 0],
      efid            |-> [i \in 1 .. 4 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      unAckedQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledged Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgedMessage ==
    { ZeroActiveRiskAcknowledgedMessage }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgedMessage EXCEPT !.unAckedQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledge Rej Message: 36 bytes                           *)
(***************************************************************************)

ActiveRiskAcknowledgeRejMessage ==
    [ clordid           : Sample(20),
      underlier         : Sample(6),
      efid              : Sample(4),
      thresholdQuantity : Sample(4),
      rejectReason      : Sample(2) ]

EncodeActiveRiskAcknowledgeRejMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efid
        \o message.thresholdQuantity
        \o message.rejectReason

DecodeActiveRiskAcknowledgeRejMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efid.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(thresholdQuantity.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlier         |-> underlier.value,
         efid              |-> efid.value,
         thresholdQuantity |-> thresholdQuantity.value,
         rejectReason      |-> rejectReason.value ], rejectReason.rest)

ZeroActiveRiskAcknowledgeRejMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlier         |-> [i \in 1 .. 6 |-> 0],
      efid              |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity |-> [i \in 1 .. 4 |-> 0],
      rejectReason      |-> [i \in 1 .. 2 |-> 0] ]

(* Active Risk Acknowledge Rej Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgeRejMessage ==
    { ZeroActiveRiskAcknowledgeRejMessage }
        \cup { [ZeroActiveRiskAcknowledgeRejMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgeRejMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgeRejMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgeRejMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgeRejMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

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
      unAckedQuantity  : Sample(4) ]

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
        \o message.unAckedQuantity

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
    LET unAckedQuantity == ReadBytes(lastQty.rest, 4) IN IF ~unAckedQuantity.ok THEN Fail ELSE
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
         unAckedQuantity  |-> unAckedQuantity.value ], unAckedQuantity.rest)

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
      unAckedQuantity  |-> [i \in 1 .. 4 |-> 0] ]

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
        \cup { [ZeroActiveRiskQuantityUpdateNotificationMessage EXCEPT !.unAckedQuantity = one] : one \in Sample(4) }

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
(* Cp Executed Notional Threshold State Message: 40 bytes                  *)
(***************************************************************************)

CpExecutedNotionalThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      priceInDollars       : Sample(4),
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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars       |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Executed Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpExecutedNotionalThresholdStateMessage ==
    { ZeroCpExecutedNotionalThresholdStateMessage }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpExecutedNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }
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
(* Manual Cp Breach Trigger Pending Message: 40 bytes                      *)
(***************************************************************************)

ManualCpBreachTriggerPendingMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      breachId          : Sample(8) ]

EncodeManualCpBreachTriggerPendingMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.breachId

DecodeManualCpBreachTriggerPendingMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET breachId == ReadBytes(riskGroupId.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         breachId          |-> breachId.value ], breachId.rest)

ZeroManualCpBreachTriggerPendingMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      breachId          |-> [i \in 1 .. 8 |-> 0] ]

(* Manual Cp Breach Trigger Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerPendingMessage ==
    { ZeroManualCpBreachTriggerPendingMessage }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerPendingMessage EXCEPT !.breachId = one] : one \in Sample(8) }

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
(* Risk Threshold Update Rej Message: 23 bytes                             *)
(***************************************************************************)

RiskThresholdUpdateRejMessage ==
    [ clordid      : Sample(20),
      riskType     : Sample(1),
      rejectReason : Sample(2) ]

EncodeRiskThresholdUpdateRejMessage(message) ==
    message.clordid
        \o message.riskType
        \o message.rejectReason

DecodeRiskThresholdUpdateRejMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET riskType == ReadBytes(clordid.rest, 1) IN IF ~riskType.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(riskType.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clordid      |-> clordid.value,
         riskType     |-> riskType.value,
         rejectReason |-> rejectReason.value ], rejectReason.rest)

ZeroRiskThresholdUpdateRejMessage ==
    [ clordid      |-> [i \in 1 .. 20 |-> 0],
      riskType     |-> [i \in 1 .. 1 |-> 0],
      rejectReason |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Threshold Update Rej Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskThresholdUpdateRejMessage ==
    { ZeroRiskThresholdUpdateRejMessage }
        \cup { [ZeroRiskThresholdUpdateRejMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroRiskThresholdUpdateRejMessage EXCEPT !.riskType = one] : one \in Sample(1) }
        \cup { [ZeroRiskThresholdUpdateRejMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

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
(* Single Order Max Notional Threshold State Message: 36 bytes             *)
(***************************************************************************)

SingleOrderMaxNotionalThresholdStateMessage ==
    [ clordidOptional      : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxNotionalInDollars : Sample(4) ]

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
    LET maxNotionalInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~maxNotionalInDollars.ok THEN Fail ELSE
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
      maxNotionalInDollars |-> [i \in 1 .. 4 |-> 0] ]

(* Single Order Max Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxNotionalThresholdStateMessage ==
    { ZeroSingleOrderMaxNotionalThresholdStateMessage }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxNotionalThresholdStateMessage EXCEPT !.maxNotionalInDollars = one] : one \in Sample(4) }

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
(* Risk Settings Query Rej Message: 22 bytes                               *)
(***************************************************************************)

RiskSettingsQueryRejMessage ==
    [ clordid      : Sample(20),
      rejectReason : Sample(2) ]

EncodeRiskSettingsQueryRejMessage(message) ==
    message.clordid
        \o message.rejectReason

DecodeRiskSettingsQueryRejMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(clordid.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clordid      |-> clordid.value,
         rejectReason |-> rejectReason.value ], rejectReason.rest)

ZeroRiskSettingsQueryRejMessage ==
    [ clordid      |-> [i \in 1 .. 20 |-> 0],
      rejectReason |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Settings Query Rej Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskSettingsQueryRejMessage ==
    { ZeroRiskSettingsQueryRejMessage }
        \cup { [ZeroRiskSettingsQueryRejMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroRiskSettingsQueryRejMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Manual Cp Breach Trigger Rej Message: 34 bytes                          *)
(***************************************************************************)

ManualCpBreachTriggerRejMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      rejectReason      : Sample(2) ]

EncodeManualCpBreachTriggerRejMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.rejectReason

DecodeManualCpBreachTriggerRejMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(riskGroupId.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         rejectReason      |-> rejectReason.value ], rejectReason.rest)

ZeroManualCpBreachTriggerRejMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      rejectReason      |-> [i \in 1 .. 2 |-> 0] ]

(* Manual Cp Breach Trigger Rej Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerRejMessage ==
    { ZeroManualCpBreachTriggerRejMessage }
        \cup { [ZeroManualCpBreachTriggerRejMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerRejMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerRejMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerRejMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerRejMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Breach Clear Rej Message: 30 bytes                                      *)
(***************************************************************************)

BreachClearRejMessage ==
    [ clordid      : Sample(20),
      breachId     : Sample(8),
      rejectReason : Sample(2) ]

EncodeBreachClearRejMessage(message) ==
    message.clordid
        \o message.breachId
        \o message.rejectReason

DecodeBreachClearRejMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET breachId == ReadBytes(clordid.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(breachId.rest, 2) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ clordid      |-> clordid.value,
         breachId     |-> breachId.value,
         rejectReason |-> rejectReason.value ], rejectReason.rest)

ZeroBreachClearRejMessage ==
    [ clordid      |-> [i \in 1 .. 20 |-> 0],
      breachId     |-> [i \in 1 .. 8 |-> 0],
      rejectReason |-> [i \in 1 .. 2 |-> 0] ]

(* Breach Clear Rej Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearRejMessage ==
    { ZeroBreachClearRejMessage }
        \cup { [ZeroBreachClearRejMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearRejMessage EXCEPT !.breachId = one] : one \in Sample(8) }
        \cup { [ZeroBreachClearRejMessage EXCEPT !.rejectReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Breach Cleared Message: 28 bytes                                        *)
(***************************************************************************)

BreachClearedMessage ==
    [ clordidOptional : Sample(20),
      breachId        : Sample(8) ]

EncodeBreachClearedMessage(message) ==
    message.clordidOptional
        \o message.breachId

DecodeBreachClearedMessage(bytes) ==
    LET clordidOptional == ReadBytes(bytes, 20) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET breachId == ReadBytes(clordidOptional.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    Ok([ clordidOptional |-> clordidOptional.value,
         breachId        |-> breachId.value ], breachId.rest)

ZeroBreachClearedMessage ==
    [ clordidOptional |-> [i \in 1 .. 20 |-> 0],
      breachId        |-> [i \in 1 .. 8 |-> 0] ]

(* Breach Cleared Message at zero, then each field in turn at the values it is checked at *)
CheckedBreachClearedMessage ==
    { ZeroBreachClearedMessage }
        \cup { [ZeroBreachClearedMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroBreachClearedMessage EXCEPT !.breachId = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Gross Notional Threshold State Message: 36 bytes                     *)
(***************************************************************************)

CpGrossNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Gross Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpGrossNotionalThresholdStateMessage ==
    { ZeroCpGrossNotionalThresholdStateMessage }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpGrossNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Market Order Gross Notional Threshold State Message: 36 bytes        *)
(***************************************************************************)

CpMarketOrderGrossNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Market Order Gross Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderGrossNotionalThresholdStateMessage ==
    { ZeroCpMarketOrderGrossNotionalThresholdStateMessage }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Net Notional Threshold State Message: 36 bytes                       *)
(***************************************************************************)

CpNetNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Net Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpNetNotionalThresholdStateMessage ==
    { ZeroCpNetNotionalThresholdStateMessage }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpNetNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Market Order Net Notional Threshold State Message: 36 bytes          *)
(***************************************************************************)

CpMarketOrderNetNotionalThresholdStateMessage ==
    [ clordidOptional   : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(4) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 4) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Market Order Net Notional Threshold State Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderNetNotionalThresholdStateMessage ==
    { ZeroCpMarketOrderNetNotionalThresholdStateMessage }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.clordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdStateMessage EXCEPT !.priceInDollars = one] : one \in Sample(4) }

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
ActiveRiskThresholdChangeReqMessageCode == 2  \* 0x02
ActiveRiskAcknowledgementReqMessageCode == 3  \* 0x03
CpVolumeThresholdChangeReqMessageCode == 4  \* 0x04
CpExecutedNotionalThresholdChangeReqMessageCode == 5  \* 0x05
CpTotalExecutionsThresholdChangeReqMessageCode == 6  \* 0x06
CpPercentOutstandingContractsThresholdChangeReqMessageCode == 7  \* 0x07
CpBreachCountThresholdChangeReqMessageCode == 8  \* 0x08
ManualCpBreachTriggerReqMessageCode == 9  \* 0x09
CpClearBreachReqMessageCode == 10  \* 0x0a
SingleOrderAllowIsoOrdersChangeReqMessageCode == 11  \* 0x0b
SingleOrderAllowOrdersInCrossedMarketChangeReqMessageCode == 12  \* 0x0c
SingleOrderMaxNotionalChangeReqMessageCode == 13  \* 0x0d
SingleOrderMaxContractsChangeReqMessageCode == 14  \* 0x0e
CpGrossNotionalThresholdChangeReqMessageCode == 18  \* 0x12
CpMarketOrderGrossNotionalThresholdChangeReqMessageCode == 19  \* 0x13
CpNetNotionalThresholdChangeReqMessageCode == 20  \* 0x14
CpMarketOrderNetNotionalThresholdChangeReqMessageCode == 21  \* 0x15
CpDuplicateOrderThresholdChangeReqMessageCode == 22  \* 0x16
CpOrderRateThresholdChangeReqMessageCode == 23  \* 0x17
ActiveRiskThresholdStateMessageCode == 30  \* 0x1e
ActiveRiskThresholdChangeRejMessageCode == 31  \* 0x1f
ActiveRiskAcknowledgedMessageCode == 32  \* 0x20
ActiveRiskAcknowledgeRejMessageCode == 33  \* 0x21
ActiveRiskQuantityUpdateNotificationMessageCode == 34  \* 0x22
CpVolumeThresholdStateMessageCode == 35  \* 0x23
CpExecutedNotionalThresholdStateMessageCode == 36  \* 0x24
CpTotalExecutionsThresholdStateMessageCode == 37  \* 0x25
CpPercentOutstandingContractsThresholdStateMessageCode == 38  \* 0x26
CpBreachCountThresholdStateMessageCode == 39  \* 0x27
ManualCpBreachTriggerPendingMessageCode == 40  \* 0x28
ManualCpBreachTriggerDoneMessageCode == 41  \* 0x29
RiskThresholdUpdateRejMessageCode == 42  \* 0x2a
PassiveRiskThresholdNotificationMessageCode == 43  \* 0x2b
SingleOrderAllowIsoOrdersStateMessageCode == 44  \* 0x2c
SingleOrderAllowOrdersInCrossedMarketStateMessageCode == 45  \* 0x2d
SingleOrderMaxNotionalThresholdStateMessageCode == 46  \* 0x2e
SingleOrderMaxContractsThresholdStateMessageCode == 47  \* 0x2f
RiskSettingsQueryDoneMessageCode == 48  \* 0x30
RiskSettingsQueryRejMessageCode == 49  \* 0x31
ManualCpBreachTriggerRejMessageCode == 50  \* 0x32
BreachClearRejMessageCode == 51  \* 0x33
BreachClearedMessageCode == 52  \* 0x34
CpGrossNotionalThresholdStateMessageCode == 60  \* 0x3c
CpMarketOrderGrossNotionalThresholdStateMessageCode == 61  \* 0x3d
CpNetNotionalThresholdStateMessageCode == 62  \* 0x3e
CpMarketOrderNetNotionalThresholdStateMessageCode == 63  \* 0x3f
CpDuplicateOrderThresholdStateMessageCode == 64  \* 0x40
CpOrderRateThresholdStateMessageCode == 65  \* 0x41

Payload ==
    [ tag : {RiskSettingsQueryMessageCode}, body : RiskSettingsQueryMessage ]
        \cup [ tag : {ActiveRiskThresholdChangeReqMessageCode}, body : ActiveRiskThresholdChangeReqMessage ]
        \cup [ tag : {ActiveRiskAcknowledgementReqMessageCode}, body : ActiveRiskAcknowledgementReqMessage ]
        \cup [ tag : {CpVolumeThresholdChangeReqMessageCode}, body : CpVolumeThresholdChangeReqMessage ]
        \cup [ tag : {CpExecutedNotionalThresholdChangeReqMessageCode}, body : CpExecutedNotionalThresholdChangeReqMessage ]
        \cup [ tag : {CpTotalExecutionsThresholdChangeReqMessageCode}, body : CpTotalExecutionsThresholdChangeReqMessage ]
        \cup [ tag : {CpPercentOutstandingContractsThresholdChangeReqMessageCode}, body : CpPercentOutstandingContractsThresholdChangeReqMessage ]
        \cup [ tag : {CpBreachCountThresholdChangeReqMessageCode}, body : CpBreachCountThresholdChangeReqMessage ]
        \cup [ tag : {ManualCpBreachTriggerReqMessageCode}, body : ManualCpBreachTriggerReqMessage ]
        \cup [ tag : {CpClearBreachReqMessageCode}, body : CpClearBreachReqMessage ]
        \cup [ tag : {SingleOrderAllowIsoOrdersChangeReqMessageCode}, body : SingleOrderAllowIsoOrdersChangeReqMessage ]
        \cup [ tag : {SingleOrderAllowOrdersInCrossedMarketChangeReqMessageCode}, body : SingleOrderAllowOrdersInCrossedMarketChangeReqMessage ]
        \cup [ tag : {SingleOrderMaxNotionalChangeReqMessageCode}, body : SingleOrderMaxNotionalChangeReqMessage ]
        \cup [ tag : {SingleOrderMaxContractsChangeReqMessageCode}, body : SingleOrderMaxContractsChangeReqMessage ]
        \cup [ tag : {CpGrossNotionalThresholdChangeReqMessageCode}, body : CpGrossNotionalThresholdChangeReqMessage ]
        \cup [ tag : {CpMarketOrderGrossNotionalThresholdChangeReqMessageCode}, body : CpMarketOrderGrossNotionalThresholdChangeReqMessage ]
        \cup [ tag : {CpNetNotionalThresholdChangeReqMessageCode}, body : CpNetNotionalThresholdChangeReqMessage ]
        \cup [ tag : {CpMarketOrderNetNotionalThresholdChangeReqMessageCode}, body : CpMarketOrderNetNotionalThresholdChangeReqMessage ]
        \cup [ tag : {CpDuplicateOrderThresholdChangeReqMessageCode}, body : CpDuplicateOrderThresholdChangeReqMessage ]
        \cup [ tag : {CpOrderRateThresholdChangeReqMessageCode}, body : CpOrderRateThresholdChangeReqMessage ]
        \cup [ tag : {ActiveRiskThresholdStateMessageCode}, body : ActiveRiskThresholdStateMessage ]
        \cup [ tag : {ActiveRiskThresholdChangeRejMessageCode}, body : ActiveRiskThresholdChangeRejMessage ]
        \cup [ tag : {ActiveRiskAcknowledgedMessageCode}, body : ActiveRiskAcknowledgedMessage ]
        \cup [ tag : {ActiveRiskAcknowledgeRejMessageCode}, body : ActiveRiskAcknowledgeRejMessage ]
        \cup [ tag : {ActiveRiskQuantityUpdateNotificationMessageCode}, body : ActiveRiskQuantityUpdateNotificationMessage ]
        \cup [ tag : {CpVolumeThresholdStateMessageCode}, body : CpVolumeThresholdStateMessage ]
        \cup [ tag : {CpExecutedNotionalThresholdStateMessageCode}, body : CpExecutedNotionalThresholdStateMessage ]
        \cup [ tag : {CpTotalExecutionsThresholdStateMessageCode}, body : CpTotalExecutionsThresholdStateMessage ]
        \cup [ tag : {CpPercentOutstandingContractsThresholdStateMessageCode}, body : CpPercentOutstandingContractsThresholdStateMessage ]
        \cup [ tag : {CpBreachCountThresholdStateMessageCode}, body : CpBreachCountThresholdStateMessage ]
        \cup [ tag : {ManualCpBreachTriggerPendingMessageCode}, body : ManualCpBreachTriggerPendingMessage ]
        \cup [ tag : {ManualCpBreachTriggerDoneMessageCode}, body : ManualCpBreachTriggerDoneMessage ]
        \cup [ tag : {RiskThresholdUpdateRejMessageCode}, body : RiskThresholdUpdateRejMessage ]
        \cup [ tag : {PassiveRiskThresholdNotificationMessageCode}, body : PassiveRiskThresholdNotificationMessage ]
        \cup [ tag : {SingleOrderAllowIsoOrdersStateMessageCode}, body : SingleOrderAllowIsoOrdersStateMessage ]
        \cup [ tag : {SingleOrderAllowOrdersInCrossedMarketStateMessageCode}, body : SingleOrderAllowOrdersInCrossedMarketStateMessage ]
        \cup [ tag : {SingleOrderMaxNotionalThresholdStateMessageCode}, body : SingleOrderMaxNotionalThresholdStateMessage ]
        \cup [ tag : {SingleOrderMaxContractsThresholdStateMessageCode}, body : SingleOrderMaxContractsThresholdStateMessage ]
        \cup [ tag : {RiskSettingsQueryDoneMessageCode}, body : RiskSettingsQueryDoneMessage ]
        \cup [ tag : {RiskSettingsQueryRejMessageCode}, body : RiskSettingsQueryRejMessage ]
        \cup [ tag : {ManualCpBreachTriggerRejMessageCode}, body : ManualCpBreachTriggerRejMessage ]
        \cup [ tag : {BreachClearRejMessageCode}, body : BreachClearRejMessage ]
        \cup [ tag : {BreachClearedMessageCode}, body : BreachClearedMessage ]
        \cup [ tag : {CpGrossNotionalThresholdStateMessageCode}, body : CpGrossNotionalThresholdStateMessage ]
        \cup [ tag : {CpMarketOrderGrossNotionalThresholdStateMessageCode}, body : CpMarketOrderGrossNotionalThresholdStateMessage ]
        \cup [ tag : {CpNetNotionalThresholdStateMessageCode}, body : CpNetNotionalThresholdStateMessage ]
        \cup [ tag : {CpMarketOrderNetNotionalThresholdStateMessageCode}, body : CpMarketOrderNetNotionalThresholdStateMessage ]
        \cup [ tag : {CpDuplicateOrderThresholdStateMessageCode}, body : CpDuplicateOrderThresholdStateMessage ]
        \cup [ tag : {CpOrderRateThresholdStateMessageCode}, body : CpOrderRateThresholdStateMessage ]

EncodePayload(message) ==
    CASE message.tag = RiskSettingsQueryMessageCode -> EncodeRiskSettingsQueryMessage(message.body)
      [] message.tag = ActiveRiskThresholdChangeReqMessageCode -> EncodeActiveRiskThresholdChangeReqMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgementReqMessageCode -> EncodeActiveRiskAcknowledgementReqMessage(message.body)
      [] message.tag = CpVolumeThresholdChangeReqMessageCode -> EncodeCpVolumeThresholdChangeReqMessage(message.body)
      [] message.tag = CpExecutedNotionalThresholdChangeReqMessageCode -> EncodeCpExecutedNotionalThresholdChangeReqMessage(message.body)
      [] message.tag = CpTotalExecutionsThresholdChangeReqMessageCode -> EncodeCpTotalExecutionsThresholdChangeReqMessage(message.body)
      [] message.tag = CpPercentOutstandingContractsThresholdChangeReqMessageCode -> EncodeCpPercentOutstandingContractsThresholdChangeReqMessage(message.body)
      [] message.tag = CpBreachCountThresholdChangeReqMessageCode -> EncodeCpBreachCountThresholdChangeReqMessage(message.body)
      [] message.tag = ManualCpBreachTriggerReqMessageCode -> EncodeManualCpBreachTriggerReqMessage(message.body)
      [] message.tag = CpClearBreachReqMessageCode -> EncodeCpClearBreachReqMessage(message.body)
      [] message.tag = SingleOrderAllowIsoOrdersChangeReqMessageCode -> EncodeSingleOrderAllowIsoOrdersChangeReqMessage(message.body)
      [] message.tag = SingleOrderAllowOrdersInCrossedMarketChangeReqMessageCode -> EncodeSingleOrderAllowOrdersInCrossedMarketChangeReqMessage(message.body)
      [] message.tag = SingleOrderMaxNotionalChangeReqMessageCode -> EncodeSingleOrderMaxNotionalChangeReqMessage(message.body)
      [] message.tag = SingleOrderMaxContractsChangeReqMessageCode -> EncodeSingleOrderMaxContractsChangeReqMessage(message.body)
      [] message.tag = CpGrossNotionalThresholdChangeReqMessageCode -> EncodeCpGrossNotionalThresholdChangeReqMessage(message.body)
      [] message.tag = CpMarketOrderGrossNotionalThresholdChangeReqMessageCode -> EncodeCpMarketOrderGrossNotionalThresholdChangeReqMessage(message.body)
      [] message.tag = CpNetNotionalThresholdChangeReqMessageCode -> EncodeCpNetNotionalThresholdChangeReqMessage(message.body)
      [] message.tag = CpMarketOrderNetNotionalThresholdChangeReqMessageCode -> EncodeCpMarketOrderNetNotionalThresholdChangeReqMessage(message.body)
      [] message.tag = CpDuplicateOrderThresholdChangeReqMessageCode -> EncodeCpDuplicateOrderThresholdChangeReqMessage(message.body)
      [] message.tag = CpOrderRateThresholdChangeReqMessageCode -> EncodeCpOrderRateThresholdChangeReqMessage(message.body)
      [] message.tag = ActiveRiskThresholdStateMessageCode -> EncodeActiveRiskThresholdStateMessage(message.body)
      [] message.tag = ActiveRiskThresholdChangeRejMessageCode -> EncodeActiveRiskThresholdChangeRejMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgedMessageCode -> EncodeActiveRiskAcknowledgedMessage(message.body)
      [] message.tag = ActiveRiskAcknowledgeRejMessageCode -> EncodeActiveRiskAcknowledgeRejMessage(message.body)
      [] message.tag = ActiveRiskQuantityUpdateNotificationMessageCode -> EncodeActiveRiskQuantityUpdateNotificationMessage(message.body)
      [] message.tag = CpVolumeThresholdStateMessageCode -> EncodeCpVolumeThresholdStateMessage(message.body)
      [] message.tag = CpExecutedNotionalThresholdStateMessageCode -> EncodeCpExecutedNotionalThresholdStateMessage(message.body)
      [] message.tag = CpTotalExecutionsThresholdStateMessageCode -> EncodeCpTotalExecutionsThresholdStateMessage(message.body)
      [] message.tag = CpPercentOutstandingContractsThresholdStateMessageCode -> EncodeCpPercentOutstandingContractsThresholdStateMessage(message.body)
      [] message.tag = CpBreachCountThresholdStateMessageCode -> EncodeCpBreachCountThresholdStateMessage(message.body)
      [] message.tag = ManualCpBreachTriggerPendingMessageCode -> EncodeManualCpBreachTriggerPendingMessage(message.body)
      [] message.tag = ManualCpBreachTriggerDoneMessageCode -> EncodeManualCpBreachTriggerDoneMessage(message.body)
      [] message.tag = RiskThresholdUpdateRejMessageCode -> EncodeRiskThresholdUpdateRejMessage(message.body)
      [] message.tag = PassiveRiskThresholdNotificationMessageCode -> EncodePassiveRiskThresholdNotificationMessage(message.body)
      [] message.tag = SingleOrderAllowIsoOrdersStateMessageCode -> EncodeSingleOrderAllowIsoOrdersStateMessage(message.body)
      [] message.tag = SingleOrderAllowOrdersInCrossedMarketStateMessageCode -> EncodeSingleOrderAllowOrdersInCrossedMarketStateMessage(message.body)
      [] message.tag = SingleOrderMaxNotionalThresholdStateMessageCode -> EncodeSingleOrderMaxNotionalThresholdStateMessage(message.body)
      [] message.tag = SingleOrderMaxContractsThresholdStateMessageCode -> EncodeSingleOrderMaxContractsThresholdStateMessage(message.body)
      [] message.tag = RiskSettingsQueryDoneMessageCode -> EncodeRiskSettingsQueryDoneMessage(message.body)
      [] message.tag = RiskSettingsQueryRejMessageCode -> EncodeRiskSettingsQueryRejMessage(message.body)
      [] message.tag = ManualCpBreachTriggerRejMessageCode -> EncodeManualCpBreachTriggerRejMessage(message.body)
      [] message.tag = BreachClearRejMessageCode -> EncodeBreachClearRejMessage(message.body)
      [] message.tag = BreachClearedMessageCode -> EncodeBreachClearedMessage(message.body)
      [] message.tag = CpGrossNotionalThresholdStateMessageCode -> EncodeCpGrossNotionalThresholdStateMessage(message.body)
      [] message.tag = CpMarketOrderGrossNotionalThresholdStateMessageCode -> EncodeCpMarketOrderGrossNotionalThresholdStateMessage(message.body)
      [] message.tag = CpNetNotionalThresholdStateMessageCode -> EncodeCpNetNotionalThresholdStateMessage(message.body)
      [] message.tag = CpMarketOrderNetNotionalThresholdStateMessageCode -> EncodeCpMarketOrderNetNotionalThresholdStateMessage(message.body)
      [] message.tag = CpDuplicateOrderThresholdStateMessageCode -> EncodeCpDuplicateOrderThresholdStateMessage(message.body)
      [] message.tag = CpOrderRateThresholdStateMessageCode -> EncodeCpOrderRateThresholdStateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = RiskSettingsQueryMessageCode -> DecodeRiskSettingsQueryMessage(bytes)
              [] tag = ActiveRiskThresholdChangeReqMessageCode -> DecodeActiveRiskThresholdChangeReqMessage(bytes)
              [] tag = ActiveRiskAcknowledgementReqMessageCode -> DecodeActiveRiskAcknowledgementReqMessage(bytes)
              [] tag = CpVolumeThresholdChangeReqMessageCode -> DecodeCpVolumeThresholdChangeReqMessage(bytes)
              [] tag = CpExecutedNotionalThresholdChangeReqMessageCode -> DecodeCpExecutedNotionalThresholdChangeReqMessage(bytes)
              [] tag = CpTotalExecutionsThresholdChangeReqMessageCode -> DecodeCpTotalExecutionsThresholdChangeReqMessage(bytes)
              [] tag = CpPercentOutstandingContractsThresholdChangeReqMessageCode -> DecodeCpPercentOutstandingContractsThresholdChangeReqMessage(bytes)
              [] tag = CpBreachCountThresholdChangeReqMessageCode -> DecodeCpBreachCountThresholdChangeReqMessage(bytes)
              [] tag = ManualCpBreachTriggerReqMessageCode -> DecodeManualCpBreachTriggerReqMessage(bytes)
              [] tag = CpClearBreachReqMessageCode -> DecodeCpClearBreachReqMessage(bytes)
              [] tag = SingleOrderAllowIsoOrdersChangeReqMessageCode -> DecodeSingleOrderAllowIsoOrdersChangeReqMessage(bytes)
              [] tag = SingleOrderAllowOrdersInCrossedMarketChangeReqMessageCode -> DecodeSingleOrderAllowOrdersInCrossedMarketChangeReqMessage(bytes)
              [] tag = SingleOrderMaxNotionalChangeReqMessageCode -> DecodeSingleOrderMaxNotionalChangeReqMessage(bytes)
              [] tag = SingleOrderMaxContractsChangeReqMessageCode -> DecodeSingleOrderMaxContractsChangeReqMessage(bytes)
              [] tag = CpGrossNotionalThresholdChangeReqMessageCode -> DecodeCpGrossNotionalThresholdChangeReqMessage(bytes)
              [] tag = CpMarketOrderGrossNotionalThresholdChangeReqMessageCode -> DecodeCpMarketOrderGrossNotionalThresholdChangeReqMessage(bytes)
              [] tag = CpNetNotionalThresholdChangeReqMessageCode -> DecodeCpNetNotionalThresholdChangeReqMessage(bytes)
              [] tag = CpMarketOrderNetNotionalThresholdChangeReqMessageCode -> DecodeCpMarketOrderNetNotionalThresholdChangeReqMessage(bytes)
              [] tag = CpDuplicateOrderThresholdChangeReqMessageCode -> DecodeCpDuplicateOrderThresholdChangeReqMessage(bytes)
              [] tag = CpOrderRateThresholdChangeReqMessageCode -> DecodeCpOrderRateThresholdChangeReqMessage(bytes)
              [] tag = ActiveRiskThresholdStateMessageCode -> DecodeActiveRiskThresholdStateMessage(bytes)
              [] tag = ActiveRiskThresholdChangeRejMessageCode -> DecodeActiveRiskThresholdChangeRejMessage(bytes)
              [] tag = ActiveRiskAcknowledgedMessageCode -> DecodeActiveRiskAcknowledgedMessage(bytes)
              [] tag = ActiveRiskAcknowledgeRejMessageCode -> DecodeActiveRiskAcknowledgeRejMessage(bytes)
              [] tag = ActiveRiskQuantityUpdateNotificationMessageCode -> DecodeActiveRiskQuantityUpdateNotificationMessage(bytes)
              [] tag = CpVolumeThresholdStateMessageCode -> DecodeCpVolumeThresholdStateMessage(bytes)
              [] tag = CpExecutedNotionalThresholdStateMessageCode -> DecodeCpExecutedNotionalThresholdStateMessage(bytes)
              [] tag = CpTotalExecutionsThresholdStateMessageCode -> DecodeCpTotalExecutionsThresholdStateMessage(bytes)
              [] tag = CpPercentOutstandingContractsThresholdStateMessageCode -> DecodeCpPercentOutstandingContractsThresholdStateMessage(bytes)
              [] tag = CpBreachCountThresholdStateMessageCode -> DecodeCpBreachCountThresholdStateMessage(bytes)
              [] tag = ManualCpBreachTriggerPendingMessageCode -> DecodeManualCpBreachTriggerPendingMessage(bytes)
              [] tag = ManualCpBreachTriggerDoneMessageCode -> DecodeManualCpBreachTriggerDoneMessage(bytes)
              [] tag = RiskThresholdUpdateRejMessageCode -> DecodeRiskThresholdUpdateRejMessage(bytes)
              [] tag = PassiveRiskThresholdNotificationMessageCode -> DecodePassiveRiskThresholdNotificationMessage(bytes)
              [] tag = SingleOrderAllowIsoOrdersStateMessageCode -> DecodeSingleOrderAllowIsoOrdersStateMessage(bytes)
              [] tag = SingleOrderAllowOrdersInCrossedMarketStateMessageCode -> DecodeSingleOrderAllowOrdersInCrossedMarketStateMessage(bytes)
              [] tag = SingleOrderMaxNotionalThresholdStateMessageCode -> DecodeSingleOrderMaxNotionalThresholdStateMessage(bytes)
              [] tag = SingleOrderMaxContractsThresholdStateMessageCode -> DecodeSingleOrderMaxContractsThresholdStateMessage(bytes)
              [] tag = RiskSettingsQueryDoneMessageCode -> DecodeRiskSettingsQueryDoneMessage(bytes)
              [] tag = RiskSettingsQueryRejMessageCode -> DecodeRiskSettingsQueryRejMessage(bytes)
              [] tag = ManualCpBreachTriggerRejMessageCode -> DecodeManualCpBreachTriggerRejMessage(bytes)
              [] tag = BreachClearRejMessageCode -> DecodeBreachClearRejMessage(bytes)
              [] tag = BreachClearedMessageCode -> DecodeBreachClearedMessage(bytes)
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
        \cup { [tag |-> ActiveRiskThresholdChangeReqMessageCode, body |-> one] : one \in CheckedActiveRiskThresholdChangeReqMessage }
        \cup { [tag |-> ActiveRiskAcknowledgementReqMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgementReqMessage }
        \cup { [tag |-> CpVolumeThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpVolumeThresholdChangeReqMessage }
        \cup { [tag |-> CpExecutedNotionalThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpExecutedNotionalThresholdChangeReqMessage }
        \cup { [tag |-> CpTotalExecutionsThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpTotalExecutionsThresholdChangeReqMessage }
        \cup { [tag |-> CpPercentOutstandingContractsThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpPercentOutstandingContractsThresholdChangeReqMessage }
        \cup { [tag |-> CpBreachCountThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpBreachCountThresholdChangeReqMessage }
        \cup { [tag |-> ManualCpBreachTriggerReqMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerReqMessage }
        \cup { [tag |-> CpClearBreachReqMessageCode, body |-> one] : one \in CheckedCpClearBreachReqMessage }
        \cup { [tag |-> SingleOrderAllowIsoOrdersChangeReqMessageCode, body |-> one] : one \in CheckedSingleOrderAllowIsoOrdersChangeReqMessage }
        \cup { [tag |-> SingleOrderAllowOrdersInCrossedMarketChangeReqMessageCode, body |-> one] : one \in CheckedSingleOrderAllowOrdersInCrossedMarketChangeReqMessage }
        \cup { [tag |-> SingleOrderMaxNotionalChangeReqMessageCode, body |-> one] : one \in CheckedSingleOrderMaxNotionalChangeReqMessage }
        \cup { [tag |-> SingleOrderMaxContractsChangeReqMessageCode, body |-> one] : one \in CheckedSingleOrderMaxContractsChangeReqMessage }
        \cup { [tag |-> CpGrossNotionalThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpGrossNotionalThresholdChangeReqMessage }
        \cup { [tag |-> CpMarketOrderGrossNotionalThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpMarketOrderGrossNotionalThresholdChangeReqMessage }
        \cup { [tag |-> CpNetNotionalThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpNetNotionalThresholdChangeReqMessage }
        \cup { [tag |-> CpMarketOrderNetNotionalThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpMarketOrderNetNotionalThresholdChangeReqMessage }
        \cup { [tag |-> CpDuplicateOrderThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpDuplicateOrderThresholdChangeReqMessage }
        \cup { [tag |-> CpOrderRateThresholdChangeReqMessageCode, body |-> one] : one \in CheckedCpOrderRateThresholdChangeReqMessage }
        \cup { [tag |-> ActiveRiskThresholdStateMessageCode, body |-> one] : one \in CheckedActiveRiskThresholdStateMessage }
        \cup { [tag |-> ActiveRiskThresholdChangeRejMessageCode, body |-> one] : one \in CheckedActiveRiskThresholdChangeRejMessage }
        \cup { [tag |-> ActiveRiskAcknowledgedMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgedMessage }
        \cup { [tag |-> ActiveRiskAcknowledgeRejMessageCode, body |-> one] : one \in CheckedActiveRiskAcknowledgeRejMessage }
        \cup { [tag |-> ActiveRiskQuantityUpdateNotificationMessageCode, body |-> one] : one \in CheckedActiveRiskQuantityUpdateNotificationMessage }
        \cup { [tag |-> CpVolumeThresholdStateMessageCode, body |-> one] : one \in CheckedCpVolumeThresholdStateMessage }
        \cup { [tag |-> CpExecutedNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedCpExecutedNotionalThresholdStateMessage }
        \cup { [tag |-> CpTotalExecutionsThresholdStateMessageCode, body |-> one] : one \in CheckedCpTotalExecutionsThresholdStateMessage }
        \cup { [tag |-> CpPercentOutstandingContractsThresholdStateMessageCode, body |-> one] : one \in CheckedCpPercentOutstandingContractsThresholdStateMessage }
        \cup { [tag |-> CpBreachCountThresholdStateMessageCode, body |-> one] : one \in CheckedCpBreachCountThresholdStateMessage }
        \cup { [tag |-> ManualCpBreachTriggerPendingMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerPendingMessage }
        \cup { [tag |-> ManualCpBreachTriggerDoneMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerDoneMessage }
        \cup { [tag |-> RiskThresholdUpdateRejMessageCode, body |-> one] : one \in CheckedRiskThresholdUpdateRejMessage }
        \cup { [tag |-> PassiveRiskThresholdNotificationMessageCode, body |-> one] : one \in CheckedPassiveRiskThresholdNotificationMessage }
        \cup { [tag |-> SingleOrderAllowIsoOrdersStateMessageCode, body |-> one] : one \in CheckedSingleOrderAllowIsoOrdersStateMessage }
        \cup { [tag |-> SingleOrderAllowOrdersInCrossedMarketStateMessageCode, body |-> one] : one \in CheckedSingleOrderAllowOrdersInCrossedMarketStateMessage }
        \cup { [tag |-> SingleOrderMaxNotionalThresholdStateMessageCode, body |-> one] : one \in CheckedSingleOrderMaxNotionalThresholdStateMessage }
        \cup { [tag |-> SingleOrderMaxContractsThresholdStateMessageCode, body |-> one] : one \in CheckedSingleOrderMaxContractsThresholdStateMessage }
        \cup { [tag |-> RiskSettingsQueryDoneMessageCode, body |-> one] : one \in CheckedRiskSettingsQueryDoneMessage }
        \cup { [tag |-> RiskSettingsQueryRejMessageCode, body |-> one] : one \in CheckedRiskSettingsQueryRejMessage }
        \cup { [tag |-> ManualCpBreachTriggerRejMessageCode, body |-> one] : one \in CheckedManualCpBreachTriggerRejMessage }
        \cup { [tag |-> BreachClearRejMessageCode, body |-> one] : one \in CheckedBreachClearRejMessage }
        \cup { [tag |-> BreachClearedMessageCode, body |-> one] : one \in CheckedBreachClearedMessage }
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
(* Unsequenced Message                                                     *)
(***************************************************************************)

UnsequencedMessage ==
    [ sbeMessage : SbeMessage ]

EncodeUnsequencedMessage(message) ==
    EncodeSbeMessage(message.sbeMessage)

DecodeUnsequencedMessage(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroUnsequencedMessage ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedMessage ==
    { ZeroUnsequencedMessage }
        \cup { [ZeroUnsequencedMessage EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

(***************************************************************************)
(* Client Data, selected by Message Type                                   *)
(***************************************************************************)

LoginRequestMessageCode == 100  \* 0x64
ReplayRequestMessageCode == 101  \* 0x65
ReplayAllRequestMessageCode == 102  \* 0x66
StreamRequestMessageCode == 103  \* 0x67
UnsequencedMessageCode == 104  \* 0x68

ClientData ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {ReplayAllRequestMessageCode}, body : ReplayAllRequestMessage ]
        \cup [ tag : {StreamRequestMessageCode}, body : StreamRequestMessage ]
        \cup [ tag : {UnsequencedMessageCode}, body : UnsequencedMessage ]

EncodeClientData(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = ReplayAllRequestMessageCode -> EncodeReplayAllRequestMessage(message.body)
      [] message.tag = StreamRequestMessageCode -> EncodeStreamRequestMessage(message.body)
      [] message.tag = UnsequencedMessageCode -> EncodeUnsequencedMessage(message.body)

DecodeClientData(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = ReplayAllRequestMessageCode -> DecodeReplayAllRequestMessage(bytes)
              [] tag = StreamRequestMessageCode -> DecodeStreamRequestMessage(bytes)
              [] tag = UnsequencedMessageCode -> DecodeUnsequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientData == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Client Data in turn, at the values the message it names is checked at *)
CheckedClientData ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> ReplayAllRequestMessageCode, body |-> one] : one \in CheckedReplayAllRequestMessage }
        \cup { [tag |-> StreamRequestMessageCode, body |-> one] : one \in CheckedStreamRequestMessage }
        \cup { [tag |-> UnsequencedMessageCode, body |-> one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ messageLength : 0 .. 255,
      clientData    : ClientData ]

EncodeClientPacket(message) ==
    EncodeUIntBE(message.clientData.tag, 1)
        \o EncodeUIntBE(message.messageLength, 2)
        \o EncodeClientData(message.clientData)

DecodeClientPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageLength == ReadUIntBE(messageType.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET clientData == DecodeClientData(messageType.value, messageLength.rest) IN IF ~clientData.ok THEN Fail ELSE
    Ok([ messageLength |-> messageLength.value,
         clientData    |-> clientData.value ], clientData.rest)

ZeroClientPacket ==
    [ messageLength |-> 0,
      clientData    |-> ZeroClientData ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroClientPacket EXCEPT !.clientData = one] : one \in CheckedClientData }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestMessage ==
    \A message \in CheckedReplayRequestMessage :
        LET read == DecodeReplayRequestMessage(EncodeReplayRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay All Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayAllRequestMessage ==
    \A message \in CheckedReplayAllRequestMessage :
        LET read == DecodeReplayAllRequestMessage(EncodeReplayAllRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamRequestMessage ==
    \A message \in CheckedStreamRequestMessage :
        LET read == DecodeStreamRequestMessage(EncodeStreamRequestMessage(message))
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

(* Every Active Risk Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskThresholdChangeReqMessage ==
    \A message \in CheckedActiveRiskThresholdChangeReqMessage :
        LET read == DecodeActiveRiskThresholdChangeReqMessage(EncodeActiveRiskThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Active Risk Acknowledgement Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskAcknowledgementReqMessage ==
    \A message \in CheckedActiveRiskAcknowledgementReqMessage :
        LET read == DecodeActiveRiskAcknowledgementReqMessage(EncodeActiveRiskAcknowledgementReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Volume Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpVolumeThresholdChangeReqMessage ==
    \A message \in CheckedCpVolumeThresholdChangeReqMessage :
        LET read == DecodeCpVolumeThresholdChangeReqMessage(EncodeCpVolumeThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Executed Notional Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpExecutedNotionalThresholdChangeReqMessage ==
    \A message \in CheckedCpExecutedNotionalThresholdChangeReqMessage :
        LET read == DecodeCpExecutedNotionalThresholdChangeReqMessage(EncodeCpExecutedNotionalThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Total Executions Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpTotalExecutionsThresholdChangeReqMessage ==
    \A message \in CheckedCpTotalExecutionsThresholdChangeReqMessage :
        LET read == DecodeCpTotalExecutionsThresholdChangeReqMessage(EncodeCpTotalExecutionsThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Percent Outstanding Contracts Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpPercentOutstandingContractsThresholdChangeReqMessage ==
    \A message \in CheckedCpPercentOutstandingContractsThresholdChangeReqMessage :
        LET read == DecodeCpPercentOutstandingContractsThresholdChangeReqMessage(EncodeCpPercentOutstandingContractsThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Breach Count Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpBreachCountThresholdChangeReqMessage ==
    \A message \in CheckedCpBreachCountThresholdChangeReqMessage :
        LET read == DecodeCpBreachCountThresholdChangeReqMessage(EncodeCpBreachCountThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Cp Breach Trigger Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualCpBreachTriggerReqMessage ==
    \A message \in CheckedManualCpBreachTriggerReqMessage :
        LET read == DecodeManualCpBreachTriggerReqMessage(EncodeManualCpBreachTriggerReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Clear Breach Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpClearBreachReqMessage ==
    \A message \in CheckedCpClearBreachReqMessage :
        LET read == DecodeCpClearBreachReqMessage(EncodeCpClearBreachReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Iso Orders Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowIsoOrdersChangeReqMessage ==
    \A message \in CheckedSingleOrderAllowIsoOrdersChangeReqMessage :
        LET read == DecodeSingleOrderAllowIsoOrdersChangeReqMessage(EncodeSingleOrderAllowIsoOrdersChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Allow Orders In Crossed Market Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderAllowOrdersInCrossedMarketChangeReqMessage ==
    \A message \in CheckedSingleOrderAllowOrdersInCrossedMarketChangeReqMessage :
        LET read == DecodeSingleOrderAllowOrdersInCrossedMarketChangeReqMessage(EncodeSingleOrderAllowOrdersInCrossedMarketChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Max Notional Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderMaxNotionalChangeReqMessage ==
    \A message \in CheckedSingleOrderMaxNotionalChangeReqMessage :
        LET read == DecodeSingleOrderMaxNotionalChangeReqMessage(EncodeSingleOrderMaxNotionalChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Order Max Contracts Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleOrderMaxContractsChangeReqMessage ==
    \A message \in CheckedSingleOrderMaxContractsChangeReqMessage :
        LET read == DecodeSingleOrderMaxContractsChangeReqMessage(EncodeSingleOrderMaxContractsChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Gross Notional Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpGrossNotionalThresholdChangeReqMessage ==
    \A message \in CheckedCpGrossNotionalThresholdChangeReqMessage :
        LET read == DecodeCpGrossNotionalThresholdChangeReqMessage(EncodeCpGrossNotionalThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Market Order Gross Notional Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpMarketOrderGrossNotionalThresholdChangeReqMessage ==
    \A message \in CheckedCpMarketOrderGrossNotionalThresholdChangeReqMessage :
        LET read == DecodeCpMarketOrderGrossNotionalThresholdChangeReqMessage(EncodeCpMarketOrderGrossNotionalThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Net Notional Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpNetNotionalThresholdChangeReqMessage ==
    \A message \in CheckedCpNetNotionalThresholdChangeReqMessage :
        LET read == DecodeCpNetNotionalThresholdChangeReqMessage(EncodeCpNetNotionalThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Market Order Net Notional Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpMarketOrderNetNotionalThresholdChangeReqMessage ==
    \A message \in CheckedCpMarketOrderNetNotionalThresholdChangeReqMessage :
        LET read == DecodeCpMarketOrderNetNotionalThresholdChangeReqMessage(EncodeCpMarketOrderNetNotionalThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Duplicate Order Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpDuplicateOrderThresholdChangeReqMessage ==
    \A message \in CheckedCpDuplicateOrderThresholdChangeReqMessage :
        LET read == DecodeCpDuplicateOrderThresholdChangeReqMessage(EncodeCpDuplicateOrderThresholdChangeReqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cp Order Rate Threshold Change Req Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCpOrderRateThresholdChangeReqMessage ==
    \A message \in CheckedCpOrderRateThresholdChangeReqMessage :
        LET read == DecodeCpOrderRateThresholdChangeReqMessage(EncodeCpOrderRateThresholdChangeReqMessage(message))
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

(* Every Active Risk Threshold Change Rej Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskThresholdChangeRejMessage ==
    \A message \in CheckedActiveRiskThresholdChangeRejMessage :
        LET read == DecodeActiveRiskThresholdChangeRejMessage(EncodeActiveRiskThresholdChangeRejMessage(message))
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

(* Every Active Risk Acknowledge Rej Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActiveRiskAcknowledgeRejMessage ==
    \A message \in CheckedActiveRiskAcknowledgeRejMessage :
        LET read == DecodeActiveRiskAcknowledgeRejMessage(EncodeActiveRiskAcknowledgeRejMessage(message))
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

(* Every Risk Threshold Update Rej Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskThresholdUpdateRejMessage ==
    \A message \in CheckedRiskThresholdUpdateRejMessage :
        LET read == DecodeRiskThresholdUpdateRejMessage(EncodeRiskThresholdUpdateRejMessage(message))
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

(* Every Risk Settings Query Done Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskSettingsQueryDoneMessage ==
    \A message \in CheckedRiskSettingsQueryDoneMessage :
        LET read == DecodeRiskSettingsQueryDoneMessage(EncodeRiskSettingsQueryDoneMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Settings Query Rej Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskSettingsQueryRejMessage ==
    \A message \in CheckedRiskSettingsQueryRejMessage :
        LET read == DecodeRiskSettingsQueryRejMessage(EncodeRiskSettingsQueryRejMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Cp Breach Trigger Rej Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualCpBreachTriggerRejMessage ==
    \A message \in CheckedManualCpBreachTriggerRejMessage :
        LET read == DecodeManualCpBreachTriggerRejMessage(EncodeManualCpBreachTriggerRejMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Breach Clear Rej Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreachClearRejMessage ==
    \A message \in CheckedBreachClearRejMessage :
        LET read == DecodeBreachClearRejMessage(EncodeBreachClearRejMessage(message))
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

(* Every Unsequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(EncodeUnsequencedMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Data is selected by the Message Type it is written under *)
SelectsClientData ==
    \A message \in CheckedClientData :
        LET read == DecodeClientData(message.tag, EncodeClientData(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
