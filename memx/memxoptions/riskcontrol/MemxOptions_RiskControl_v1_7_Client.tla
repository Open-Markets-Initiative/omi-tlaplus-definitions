---------------- MODULE MemxOptions_RiskControl_v1_7_Client ----------------
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
(* Active Risk Threshold Change Request Message: 34 bytes                  *)
(***************************************************************************)

ActiveRiskThresholdChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      thresholdQuantity : Sample(4) ]

EncodeActiveRiskThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.thresholdQuantity

DecodeActiveRiskThresholdChangeRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET thresholdQuantity == ReadBytes(efidOptional.rest, 4) IN IF ~thresholdQuantity.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         thresholdQuantity |-> thresholdQuantity.value ], thresholdQuantity.rest)

ZeroActiveRiskThresholdChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      thresholdQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskThresholdChangeRequestMessage ==
    { ZeroActiveRiskThresholdChangeRequestMessage }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskThresholdChangeRequestMessage EXCEPT !.thresholdQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledgement Request Message: 34 bytes                   *)
(***************************************************************************)

ActiveRiskAcknowledgementRequestMessage ==
    [ clordid   : Sample(20),
      underlier : Sample(6),
      efid      : Sample(4),
      quantity  : Sample(4) ]

EncodeActiveRiskAcknowledgementRequestMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efid
        \o message.quantity

DecodeActiveRiskAcknowledgementRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    LET quantity == ReadBytes(efid.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ clordid   |-> clordid.value,
         underlier |-> underlier.value,
         efid      |-> efid.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroActiveRiskAcknowledgementRequestMessage ==
    [ clordid   |-> [i \in 1 .. 20 |-> 0],
      underlier |-> [i \in 1 .. 6 |-> 0],
      efid      |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledgement Request Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgementRequestMessage ==
    { ZeroActiveRiskAcknowledgementRequestMessage }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.efid = one] : one \in Sample(4) }
        \cup { [ZeroActiveRiskAcknowledgementRequestMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Volume Threshold Change Request Message: 44 bytes                    *)
(***************************************************************************)

CpVolumeThresholdChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      volume               : Sample(8),
      periodInMilliSeconds : Sample(4) ]

EncodeCpVolumeThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.volume
        \o message.periodInMilliSeconds

DecodeCpVolumeThresholdChangeRequestMessage(bytes) ==
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

ZeroCpVolumeThresholdChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      volume               |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Volume Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpVolumeThresholdChangeRequestMessage ==
    { ZeroCpVolumeThresholdChangeRequestMessage }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroCpVolumeThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Executed Notional Threshold Change Request Message: 44 bytes         *)
(***************************************************************************)

CpExecutedNotionalThresholdChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      priceInDollars       : Sample(8),
      periodInMilliSeconds : Sample(4) ]

EncodeCpExecutedNotionalThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars
        \o message.periodInMilliSeconds

DecodeCpExecutedNotionalThresholdChangeRequestMessage(bytes) ==
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

ZeroCpExecutedNotionalThresholdChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      priceInDollars       |-> [i \in 1 .. 8 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Executed Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpExecutedNotionalThresholdChangeRequestMessage ==
    { ZeroCpExecutedNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }
        \cup { [ZeroCpExecutedNotionalThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Total Executions Threshold Change Request Message: 40 bytes          *)
(***************************************************************************)

CpTotalExecutionsThresholdChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      totalExecutions      : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpTotalExecutionsThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.totalExecutions
        \o message.periodInMilliSeconds

DecodeCpTotalExecutionsThresholdChangeRequestMessage(bytes) ==
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

ZeroCpTotalExecutionsThresholdChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      totalExecutions      |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Total Executions Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpTotalExecutionsThresholdChangeRequestMessage ==
    { ZeroCpTotalExecutionsThresholdChangeRequestMessage }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.totalExecutions = one] : one \in Sample(4) }
        \cup { [ZeroCpTotalExecutionsThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Percent Outstanding Contracts Threshold Change Request Message: 38   *)
(* bytes                                                                   *)
(***************************************************************************)

CpPercentOutstandingContractsThresholdChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      percent              : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpPercentOutstandingContractsThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.percent
        \o message.periodInMilliSeconds

DecodeCpPercentOutstandingContractsThresholdChangeRequestMessage(bytes) ==
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

ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      percent              |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Percent Outstanding Contracts Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpPercentOutstandingContractsThresholdChangeRequestMessage ==
    { ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.percent = one] : one \in Sample(4) }
        \cup { [ZeroCpPercentOutstandingContractsThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Breach Count Threshold Change Request Message: 40 bytes              *)
(***************************************************************************)

CpBreachCountThresholdChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      count                : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpBreachCountThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.count
        \o message.periodInMilliSeconds

DecodeCpBreachCountThresholdChangeRequestMessage(bytes) ==
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

ZeroCpBreachCountThresholdChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      count                |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Breach Count Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpBreachCountThresholdChangeRequestMessage ==
    { ZeroCpBreachCountThresholdChangeRequestMessage }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroCpBreachCountThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Manual Cp Breach Trigger Request Message: 33 bytes                      *)
(***************************************************************************)

ManualCpBreachTriggerRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      sendCancels       : Sample(1) ]

EncodeManualCpBreachTriggerRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.sendCancels

DecodeManualCpBreachTriggerRequestMessage(bytes) ==
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

ZeroManualCpBreachTriggerRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      sendCancels       |-> [i \in 1 .. 1 |-> 0] ]

(* Manual Cp Breach Trigger Request Message at zero, then each field in turn at the values it is checked at *)
CheckedManualCpBreachTriggerRequestMessage ==
    { ZeroManualCpBreachTriggerRequestMessage }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroManualCpBreachTriggerRequestMessage EXCEPT !.sendCancels = one] : one \in Sample(1) }

(***************************************************************************)
(* Cp Clear Breach Request Message: 28 bytes                               *)
(***************************************************************************)

CpClearBreachRequestMessage ==
    [ clordid  : Sample(20),
      breachId : Sample(8) ]

EncodeCpClearBreachRequestMessage(message) ==
    message.clordid
        \o message.breachId

DecodeCpClearBreachRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET breachId == ReadBytes(clordid.rest, 8) IN IF ~breachId.ok THEN Fail ELSE
    Ok([ clordid  |-> clordid.value,
         breachId |-> breachId.value ], breachId.rest)

ZeroCpClearBreachRequestMessage ==
    [ clordid  |-> [i \in 1 .. 20 |-> 0],
      breachId |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Clear Breach Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearBreachRequestMessage ==
    { ZeroCpClearBreachRequestMessage }
        \cup { [ZeroCpClearBreachRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpClearBreachRequestMessage EXCEPT !.breachId = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Allow Iso Orders Change Request Message: 33 bytes          *)
(***************************************************************************)

SingleOrderAllowIsoOrdersChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowIsoOrders    : Sample(1) ]

EncodeSingleOrderAllowIsoOrdersChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowIsoOrders

DecodeSingleOrderAllowIsoOrdersChangeRequestMessage(bytes) ==
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

ZeroSingleOrderAllowIsoOrdersChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowIsoOrders    |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Iso Orders Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowIsoOrdersChangeRequestMessage ==
    { ZeroSingleOrderAllowIsoOrdersChangeRequestMessage }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowIsoOrdersChangeRequestMessage EXCEPT !.allowIsoOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Allow Orders In Crossed Market Change Request Message: 33  *)
(* bytes                                                                   *)
(***************************************************************************)

SingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowOrders       : Sample(1) ]

EncodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowOrders

DecodeSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage(bytes) ==
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

ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowOrders       |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Orders In Crossed Market Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage ==
    { ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowOrdersInCrossedMarketChangeRequestMessage EXCEPT !.allowOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Max Notional Change Request Message: 40 bytes              *)
(***************************************************************************)

SingleOrderMaxNotionalChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxNotionalInDollars : Sample(8) ]

EncodeSingleOrderMaxNotionalChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxNotionalInDollars

DecodeSingleOrderMaxNotionalChangeRequestMessage(bytes) ==
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

ZeroSingleOrderMaxNotionalChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      maxNotionalInDollars |-> [i \in 1 .. 8 |-> 0] ]

(* Single Order Max Notional Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxNotionalChangeRequestMessage ==
    { ZeroSingleOrderMaxNotionalChangeRequestMessage }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxNotionalChangeRequestMessage EXCEPT !.maxNotionalInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Order Max Contracts Change Request Message: 36 bytes             *)
(***************************************************************************)

SingleOrderMaxContractsChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      maxContracts      : Sample(4) ]

EncodeSingleOrderMaxContractsChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxContracts

DecodeSingleOrderMaxContractsChangeRequestMessage(bytes) ==
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

ZeroSingleOrderMaxContractsChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      maxContracts      |-> [i \in 1 .. 4 |-> 0] ]

(* Single Order Max Contracts Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderMaxContractsChangeRequestMessage ==
    { ZeroSingleOrderMaxContractsChangeRequestMessage }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderMaxContractsChangeRequestMessage EXCEPT !.maxContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Order Allow Market Orders Change Request Message: 33 bytes       *)
(***************************************************************************)

SingleOrderAllowMarketOrdersChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      allowMarketOrders : Sample(1) ]

EncodeSingleOrderAllowMarketOrdersChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.allowMarketOrders

DecodeSingleOrderAllowMarketOrdersChangeRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET allowMarketOrders == ReadBytes(riskGroupId.rest, 1) IN IF ~allowMarketOrders.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value,
         riskGroupId       |-> riskGroupId.value,
         allowMarketOrders |-> allowMarketOrders.value ], allowMarketOrders.rest)

ZeroSingleOrderAllowMarketOrdersChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      allowMarketOrders |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Allow Market Orders Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderAllowMarketOrdersChangeRequestMessage ==
    { ZeroSingleOrderAllowMarketOrdersChangeRequestMessage }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderAllowMarketOrdersChangeRequestMessage EXCEPT !.allowMarketOrders = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Order Restricted Underlier Change Request Message: 33 bytes      *)
(***************************************************************************)

SingleOrderRestrictedUnderlierChangeRequestMessage ==
    [ clordid      : Sample(20),
      underlier    : Sample(6),
      efidOptional : Sample(4),
      riskGroupId  : Sample(2),
      restricted   : Sample(1) ]

EncodeSingleOrderRestrictedUnderlierChangeRequestMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efidOptional
        \o message.riskGroupId
        \o message.restricted

DecodeSingleOrderRestrictedUnderlierChangeRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlier.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(efidOptional.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET restricted == ReadBytes(riskGroupId.rest, 1) IN IF ~restricted.ok THEN Fail ELSE
    Ok([ clordid      |-> clordid.value,
         underlier    |-> underlier.value,
         efidOptional |-> efidOptional.value,
         riskGroupId  |-> riskGroupId.value,
         restricted   |-> restricted.value ], restricted.rest)

ZeroSingleOrderRestrictedUnderlierChangeRequestMessage ==
    [ clordid      |-> [i \in 1 .. 20 |-> 0],
      underlier    |-> [i \in 1 .. 6 |-> 0],
      efidOptional |-> [i \in 1 .. 4 |-> 0],
      riskGroupId  |-> [i \in 1 .. 2 |-> 0],
      restricted   |-> [i \in 1 .. 1 |-> 0] ]

(* Single Order Restricted Underlier Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleOrderRestrictedUnderlierChangeRequestMessage ==
    { ZeroSingleOrderRestrictedUnderlierChangeRequestMessage }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSingleOrderRestrictedUnderlierChangeRequestMessage EXCEPT !.restricted = one] : one \in Sample(1) }

(***************************************************************************)
(* Cp Gross Notional Threshold Change Request Message: 40 bytes            *)
(***************************************************************************)

CpGrossNotionalThresholdChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpGrossNotionalThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpGrossNotionalThresholdChangeRequestMessage(bytes) ==
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

ZeroCpGrossNotionalThresholdChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Gross Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpGrossNotionalThresholdChangeRequestMessage ==
    { ZeroCpGrossNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpGrossNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Gross Notional Threshold Change Request Message: 40     *)
(* bytes                                                                   *)
(***************************************************************************)

CpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderGrossNotionalThresholdChangeRequestMessage(bytes) ==
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

ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Gross Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderGrossNotionalThresholdChangeRequestMessage ==
    { ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderGrossNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Net Notional Threshold Change Request Message: 40 bytes              *)
(***************************************************************************)

CpNetNotionalThresholdChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpNetNotionalThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpNetNotionalThresholdChangeRequestMessage(bytes) ==
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

ZeroCpNetNotionalThresholdChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Net Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpNetNotionalThresholdChangeRequestMessage ==
    { ZeroCpNetNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpNetNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Market Order Net Notional Threshold Change Request Message: 40 bytes *)
(***************************************************************************)

CpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4),
      riskGroupId       : Sample(2),
      priceInDollars    : Sample(8) ]

EncodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.priceInDollars

DecodeCpMarketOrderNetNotionalThresholdChangeRequestMessage(bytes) ==
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

ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0],
      riskGroupId       |-> [i \in 1 .. 2 |-> 0],
      priceInDollars    |-> [i \in 1 .. 8 |-> 0] ]

(* Cp Market Order Net Notional Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpMarketOrderNetNotionalThresholdChangeRequestMessage ==
    { ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpMarketOrderNetNotionalThresholdChangeRequestMessage EXCEPT !.priceInDollars = one] : one \in Sample(8) }

(***************************************************************************)
(* Cp Duplicate Order Threshold Change Request Message: 41 bytes           *)
(***************************************************************************)

CpDuplicateOrderThresholdChangeRequestMessage ==
    [ clordid                         : Sample(20),
      underlierOptional               : Sample(6),
      efidOptional                    : Sample(4),
      riskGroupId                     : Sample(2),
      maxDupOrders                    : Sample(4),
      useOrderPriceInDupCheckOptional : Sample(1),
      periodInMilliSeconds            : Sample(4) ]

EncodeCpDuplicateOrderThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxDupOrders
        \o message.useOrderPriceInDupCheckOptional
        \o message.periodInMilliSeconds

DecodeCpDuplicateOrderThresholdChangeRequestMessage(bytes) ==
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

ZeroCpDuplicateOrderThresholdChangeRequestMessage ==
    [ clordid                         |-> [i \in 1 .. 20 |-> 0],
      underlierOptional               |-> [i \in 1 .. 6 |-> 0],
      efidOptional                    |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                     |-> [i \in 1 .. 2 |-> 0],
      maxDupOrders                    |-> [i \in 1 .. 4 |-> 0],
      useOrderPriceInDupCheckOptional |-> [i \in 1 .. 1 |-> 0],
      periodInMilliSeconds            |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Duplicate Order Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpDuplicateOrderThresholdChangeRequestMessage ==
    { ZeroCpDuplicateOrderThresholdChangeRequestMessage }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.maxDupOrders = one] : one \in Sample(4) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.useOrderPriceInDupCheckOptional = one] : one \in Sample(1) }
        \cup { [ZeroCpDuplicateOrderThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Order Rate Threshold Change Request Message: 40 bytes                *)
(***************************************************************************)

CpOrderRateThresholdChangeRequestMessage ==
    [ clordid              : Sample(20),
      underlierOptional    : Sample(6),
      efidOptional         : Sample(4),
      riskGroupId          : Sample(2),
      maxOrderMsgs         : Sample(4),
      periodInMilliSeconds : Sample(4) ]

EncodeCpOrderRateThresholdChangeRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional
        \o message.riskGroupId
        \o message.maxOrderMsgs
        \o message.periodInMilliSeconds

DecodeCpOrderRateThresholdChangeRequestMessage(bytes) ==
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

ZeroCpOrderRateThresholdChangeRequestMessage ==
    [ clordid              |-> [i \in 1 .. 20 |-> 0],
      underlierOptional    |-> [i \in 1 .. 6 |-> 0],
      efidOptional         |-> [i \in 1 .. 4 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      maxOrderMsgs         |-> [i \in 1 .. 4 |-> 0],
      periodInMilliSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Order Rate Threshold Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpOrderRateThresholdChangeRequestMessage ==
    { ZeroCpOrderRateThresholdChangeRequestMessage }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.maxOrderMsgs = one] : one \in Sample(4) }
        \cup { [ZeroCpOrderRateThresholdChangeRequestMessage EXCEPT !.periodInMilliSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Cp Clear All Breaches Request Message: 20 bytes                         *)
(***************************************************************************)

CpClearAllBreachesRequestMessage ==
    [ clordid : Sample(20) ]

EncodeCpClearAllBreachesRequestMessage(message) ==
    message.clordid

DecodeCpClearAllBreachesRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ clordid |-> clordid.value ], clordid.rest)

ZeroCpClearAllBreachesRequestMessage ==
    [ clordid |-> [i \in 1 .. 20 |-> 0] ]

(* Cp Clear All Breaches Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearAllBreachesRequestMessage ==
    { ZeroCpClearAllBreachesRequestMessage }
        \cup { [ZeroCpClearAllBreachesRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }

(***************************************************************************)
(* Cp Clear All Breaches By Efid Or Underlier Request Message: 30 bytes    *)
(***************************************************************************)

CpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    [ clordid           : Sample(20),
      underlierOptional : Sample(6),
      efidOptional      : Sample(4) ]

EncodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(message) ==
    message.clordid
        \o message.underlierOptional
        \o message.efidOptional

DecodeCpClearAllBreachesByEfidOrUnderlierRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(clordid.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(underlierOptional.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    Ok([ clordid           |-> clordid.value,
         underlierOptional |-> underlierOptional.value,
         efidOptional      |-> efidOptional.value ], efidOptional.rest)

ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    [ clordid           |-> [i \in 1 .. 20 |-> 0],
      underlierOptional |-> [i \in 1 .. 6 |-> 0],
      efidOptional      |-> [i \in 1 .. 4 |-> 0] ]

(* Cp Clear All Breaches By Efid Or Underlier Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCpClearAllBreachesByEfidOrUnderlierRequestMessage ==
    { ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage }
        \cup { [ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroCpClearAllBreachesByEfidOrUnderlierRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Active Risk Acknowledge All Request Message: 30 bytes                   *)
(***************************************************************************)

ActiveRiskAcknowledgeAllRequestMessage ==
    [ clordid   : Sample(20),
      underlier : Sample(6),
      efid      : Sample(4) ]

EncodeActiveRiskAcknowledgeAllRequestMessage(message) ==
    message.clordid
        \o message.underlier
        \o message.efid

DecodeActiveRiskAcknowledgeAllRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET underlier == ReadBytes(clordid.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET efid == ReadBytes(underlier.rest, 4) IN IF ~efid.ok THEN Fail ELSE
    Ok([ clordid   |-> clordid.value,
         underlier |-> underlier.value,
         efid      |-> efid.value ], efid.rest)

ZeroActiveRiskAcknowledgeAllRequestMessage ==
    [ clordid   |-> [i \in 1 .. 20 |-> 0],
      underlier |-> [i \in 1 .. 6 |-> 0],
      efid      |-> [i \in 1 .. 4 |-> 0] ]

(* Active Risk Acknowledge All Request Message at zero, then each field in turn at the values it is checked at *)
CheckedActiveRiskAcknowledgeAllRequestMessage ==
    { ZeroActiveRiskAcknowledgeAllRequestMessage }
        \cup { [ZeroActiveRiskAcknowledgeAllRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroActiveRiskAcknowledgeAllRequestMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroActiveRiskAcknowledgeAllRequestMessage EXCEPT !.efid = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
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

ClientPayload ==
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

EncodeClientPayload(message) ==
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

DecodeClientPayload(tag, bytes) ==
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
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> RiskSettingsQueryMessageCode, body |-> ZeroRiskSettingsQueryMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
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
        LET sent == EncodeClientPayload(message)
            read == DecodeClientPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Data is selected by the Message Type it is written under *)
SelectsClientData ==
    \A message \in CheckedClientData :
        LET sent == EncodeClientData(message)
            read == DecodeClientData(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
