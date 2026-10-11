---------------- MODULE MemxOptions_RiskControl_v1_6_Client ----------------
(***************************************************************************)
(* The Members Exchange Risk Control v1.6                                  *)
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
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      thresholdQuantity : Sample(4) ]

EncodeActiveRiskThresholdChangeReqMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.thresholdQuantity

DecodeActiveRiskThresholdChangeReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidOptional.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         thresholdQuantity |-> thresholdQuantity.value ], thresholdQuantity.rest)

ZeroActiveRiskThresholdChangeReqMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdChangeReqMessage ==
    { ZeroActiveRiskThresholdChangeReqMessage }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
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
(* Cp Executed Notional Threshold Change Req Message: 44 bytes             *)
(***************************************************************************)

CpExecutedNotionalThresholdChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      priceInDollars       : Sample(8),
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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars       |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Executed Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpExecutedNotionalThresholdChangeReqMessage ==
    { ZeroCpExecutedNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }
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
    [ clordid          : Sample(20),
      breachIdOptional : Sample(8) ]

EncodeCpClearBreachReqMessage(message) ==
    message.clordid
        \o message.breachIdOptional

DecodeCpClearBreachReqMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET breachIdOptional == ReadBytes(clordid.rest, 8) IN IF ~breachIdOptional.ok THEN Fail ELSE
    Ok([ clordid          |-> clordid.value,
         breachIdOptional |-> breachIdOptional.value ], breachIdOptional.rest)

ZeroCpClearBreachReqMessage ==
    [ clordid          |-> [i \in 1 .. 20 |-> 0],
      breachIdOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Clear Breach Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearBreachReqMessage ==
    { ZeroCpClearBreachReqMessage }
        \cup { [ZeroCpClearBreachReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpClearBreachReqMessage EXCEPT !.breachIdOptional = one] : one \in Sample(8) }

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
(* Single Order Max Notional Change Req Message: 40 bytes                  *)
(***************************************************************************)

SingleOrderMaxNotionalChangeReqMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxNotionalInDollars : Sample(8) ]

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
    LET maxNotionalInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~maxNotionalInDollars.ok THEN Fail ELSE
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
      maxNotionalInDollars |-> [i \in 1 .. 8 |-> 0] ]

(* Single Order Max Notional Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxNotionalChangeReqMessage ==
    { ZeroSingleOrderMaxNotionalChangeReqMessage }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxNotionalChangeReqMessage EXCEPT !.maxNotionalInDollars = one] : one \in Sample(8) }

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
(* Cp Gross Notional Threshold Change Req Message: 40 bytes                *)
(***************************************************************************)

CpGrossNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Gross Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpGrossNotionalThresholdChangeReqMessage ==
    { ZeroCpGrossNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpGrossNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Gross Notional Threshold Change Req Message: 40 bytes   *)
(***************************************************************************)

CpMarketOrderGrossNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Gross Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderGrossNotionalThresholdChangeReqMessage ==
    { ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Net Notional Threshold Change Req Message: 40 bytes                  *)
(***************************************************************************)

CpNetNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Net Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpNetNotionalThresholdChangeReqMessage ==
    { ZeroCpNetNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpNetNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Net Notional Threshold Change Req Message: 40 bytes     *)
(***************************************************************************)

CpMarketOrderNetNotionalThresholdChangeReqMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

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
    LET priceInDollars == ReadBytes(riskGroupId.rest, 8) IN IF ~priceInDollars.ok THEN Fail ELSE
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
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Net Notional Threshold Change Req Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderNetNotionalThresholdChangeReqMessage ==
    { ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeReqMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

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
(* Client Payload, selected by Template Id                                 *)
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

ClientPayload ==
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

EncodeClientPayload(message) ==
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

DecodeClientPayload(tag, bytes) ==
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
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> RiskSettingsQueryMessageCode, body |-> ZeroRiskSettingsQueryMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
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

(***************************************************************************)
(* Client Sbe Message                                                      *)
(***************************************************************************)

ClientSbeMessage ==
    [ blockLength   : Sample(2),
      schemaId      : Sample(1),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.clientPayload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

DecodeClientSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

ZeroClientSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 1 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedClientSbeMessage ==
    { ZeroClientSbeMessage }
        \cup { [ZeroClientSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroClientSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(***************************************************************************)
(* Unsequenced Message                                                     *)
(***************************************************************************)

UnsequencedMessage ==
    [ clientSbeMessage : ClientSbeMessage ]

EncodeUnsequencedMessage(message) ==
    EncodeClientSbeMessage(message.clientSbeMessage)

DecodeUnsequencedMessage(bytes) ==
    LET clientSbeMessage == DecodeClientSbeMessage(bytes) IN IF ~clientSbeMessage.ok THEN Fail ELSE
    Ok([ clientSbeMessage |-> clientSbeMessage.value ], clientSbeMessage.rest)

ZeroUnsequencedMessage ==
    [ clientSbeMessage |-> ZeroClientSbeMessage ]

(* Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedMessage ==
    { ZeroUnsequencedMessage }
        \cup { [ZeroUnsequencedMessage EXCEPT !.clientSbeMessage = one] : one \in CheckedClientSbeMessage }

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

(* Every Client Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET read == DecodeClientSbeMessage(EncodeClientSbeMessage(message))
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

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
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
