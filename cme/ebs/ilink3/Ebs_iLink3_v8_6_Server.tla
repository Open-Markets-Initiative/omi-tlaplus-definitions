---------------------- MODULE Ebs_iLink3_v8_6_Server -----------------------
(***************************************************************************)
(* CME Group iLink 3 v8.6                                                  *)
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
(* Note: Exec Inst is a bit field set, checked as its 1 byte rather than   *)
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
(* Credentials                                                             *)
(***************************************************************************)

Credentials ==
    [ credentialsData : SampleBytes ]

EncodeCredentials(message) ==
    EncodeUIntLE(Len(message.credentialsData), 2)
        \o message.credentialsData

DecodeCredentials(bytes) ==
    LET credentialsLength == ReadUIntLE(bytes, 2) IN IF ~credentialsLength.ok THEN Fail ELSE
    LET credentialsData == ReadBytes(credentialsLength.rest, credentialsLength.value) IN IF ~credentialsData.ok THEN Fail ELSE
    Ok([ credentialsData |-> credentialsData.value ], credentialsData.rest)

ZeroCredentials ==
    [ credentialsData |-> << >> ]

(* Credentials at zero, then each field in turn at the values it is checked at *)
CheckedCredentials ==
    { ZeroCredentials }
        \cup { [ZeroCredentials EXCEPT !.credentialsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Negotiation Response                                                    *)
(***************************************************************************)

NegotiationResponse ==
    [ uuid                        : Sample(8),
      requestTimestamp            : Sample(8),
      secretKeySecureIdExpiration : Sample(2),
      faultToleranceIndicator     : Sample(1),
      splitMsg                    : Sample(1),
      previousSeqNo               : Sample(4),
      previousUuid                : Sample(8),
      credentials                 : Credentials ]

EncodeNegotiationResponse(message) ==
    message.uuid
        \o message.requestTimestamp
        \o message.secretKeySecureIdExpiration
        \o message.faultToleranceIndicator
        \o message.splitMsg
        \o message.previousSeqNo
        \o message.previousUuid
        \o EncodeCredentials(message.credentials)

DecodeNegotiationResponse(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET secretKeySecureIdExpiration == ReadBytes(requestTimestamp.rest, 2) IN IF ~secretKeySecureIdExpiration.ok THEN Fail ELSE
    LET faultToleranceIndicator == ReadBytes(secretKeySecureIdExpiration.rest, 1) IN IF ~faultToleranceIndicator.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(faultToleranceIndicator.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET previousSeqNo == ReadBytes(splitMsg.rest, 4) IN IF ~previousSeqNo.ok THEN Fail ELSE
    LET previousUuid == ReadBytes(previousSeqNo.rest, 8) IN IF ~previousUuid.ok THEN Fail ELSE
    LET credentials == DecodeCredentials(previousUuid.rest) IN IF ~credentials.ok THEN Fail ELSE
    Ok([ uuid                        |-> uuid.value,
         requestTimestamp            |-> requestTimestamp.value,
         secretKeySecureIdExpiration |-> secretKeySecureIdExpiration.value,
         faultToleranceIndicator     |-> faultToleranceIndicator.value,
         splitMsg                    |-> splitMsg.value,
         previousSeqNo               |-> previousSeqNo.value,
         previousUuid                |-> previousUuid.value,
         credentials                 |-> credentials.value ], credentials.rest)

ZeroNegotiationResponse ==
    [ uuid                        |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp            |-> [i \in 1 .. 8 |-> 0],
      secretKeySecureIdExpiration |-> [i \in 1 .. 2 |-> 0],
      faultToleranceIndicator     |-> [i \in 1 .. 1 |-> 0],
      splitMsg                    |-> [i \in 1 .. 1 |-> 0],
      previousSeqNo               |-> [i \in 1 .. 4 |-> 0],
      previousUuid                |-> [i \in 1 .. 8 |-> 0],
      credentials                 |-> ZeroCredentials ]

(* Negotiation Response at zero, then each field in turn at the values it is checked at *)
CheckedNegotiationResponse ==
    { ZeroNegotiationResponse }
        \cup { [ZeroNegotiationResponse EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.secretKeySecureIdExpiration = one] : one \in Sample(2) }
        \cup { [ZeroNegotiationResponse EXCEPT !.faultToleranceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNegotiationResponse EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroNegotiationResponse EXCEPT !.previousSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroNegotiationResponse EXCEPT !.previousUuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.credentials = one] : one \in CheckedCredentials }

(***************************************************************************)
(* Negotiation Reject: 68 bytes                                            *)
(***************************************************************************)

NegotiationReject ==
    [ reason                  : Sample(48),
      uuid                    : Sample(8),
      requestTimestamp        : Sample(8),
      errorCodes              : Sample(2),
      faultToleranceIndicator : Sample(1),
      splitMsg                : Sample(1) ]

EncodeNegotiationReject(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.faultToleranceIndicator
        \o message.splitMsg

DecodeNegotiationReject(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 2) IN IF ~errorCodes.ok THEN Fail ELSE
    LET faultToleranceIndicator == ReadBytes(errorCodes.rest, 1) IN IF ~faultToleranceIndicator.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(faultToleranceIndicator.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ reason                  |-> reason.value,
         uuid                    |-> uuid.value,
         requestTimestamp        |-> requestTimestamp.value,
         errorCodes              |-> errorCodes.value,
         faultToleranceIndicator |-> faultToleranceIndicator.value,
         splitMsg                |-> splitMsg.value ], splitMsg.rest)

ZeroNegotiationReject ==
    [ reason                  |-> [i \in 1 .. 48 |-> 0],
      uuid                    |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp        |-> [i \in 1 .. 8 |-> 0],
      errorCodes              |-> [i \in 1 .. 2 |-> 0],
      faultToleranceIndicator |-> [i \in 1 .. 1 |-> 0],
      splitMsg                |-> [i \in 1 .. 1 |-> 0] ]

(* Negotiation Reject at zero, then each field in turn at the values it is checked at *)
CheckedNegotiationReject ==
    { ZeroNegotiationReject }
        \cup { [ZeroNegotiationReject EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroNegotiationReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationReject EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationReject EXCEPT !.errorCodes = one] : one \in Sample(2) }
        \cup { [ZeroNegotiationReject EXCEPT !.faultToleranceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNegotiationReject EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Establishment Ack: 38 bytes                                             *)
(***************************************************************************)

EstablishmentAck ==
    [ uuid                        : Sample(8),
      requestTimestamp            : Sample(8),
      nextSeqNo                   : Sample(4),
      previousSeqNo               : Sample(4),
      previousUuid                : Sample(8),
      keepAliveInterval           : Sample(2),
      secretKeySecureIdExpiration : Sample(2),
      faultToleranceIndicator     : Sample(1),
      splitMsg                    : Sample(1) ]

EncodeEstablishmentAck(message) ==
    message.uuid
        \o message.requestTimestamp
        \o message.nextSeqNo
        \o message.previousSeqNo
        \o message.previousUuid
        \o message.keepAliveInterval
        \o message.secretKeySecureIdExpiration
        \o message.faultToleranceIndicator
        \o message.splitMsg

DecodeEstablishmentAck(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(requestTimestamp.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET previousSeqNo == ReadBytes(nextSeqNo.rest, 4) IN IF ~previousSeqNo.ok THEN Fail ELSE
    LET previousUuid == ReadBytes(previousSeqNo.rest, 8) IN IF ~previousUuid.ok THEN Fail ELSE
    LET keepAliveInterval == ReadBytes(previousUuid.rest, 2) IN IF ~keepAliveInterval.ok THEN Fail ELSE
    LET secretKeySecureIdExpiration == ReadBytes(keepAliveInterval.rest, 2) IN IF ~secretKeySecureIdExpiration.ok THEN Fail ELSE
    LET faultToleranceIndicator == ReadBytes(secretKeySecureIdExpiration.rest, 1) IN IF ~faultToleranceIndicator.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(faultToleranceIndicator.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ uuid                        |-> uuid.value,
         requestTimestamp            |-> requestTimestamp.value,
         nextSeqNo                   |-> nextSeqNo.value,
         previousSeqNo               |-> previousSeqNo.value,
         previousUuid                |-> previousUuid.value,
         keepAliveInterval           |-> keepAliveInterval.value,
         secretKeySecureIdExpiration |-> secretKeySecureIdExpiration.value,
         faultToleranceIndicator     |-> faultToleranceIndicator.value,
         splitMsg                    |-> splitMsg.value ], splitMsg.rest)

ZeroEstablishmentAck ==
    [ uuid                        |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp            |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo                   |-> [i \in 1 .. 4 |-> 0],
      previousSeqNo               |-> [i \in 1 .. 4 |-> 0],
      previousUuid                |-> [i \in 1 .. 8 |-> 0],
      keepAliveInterval           |-> [i \in 1 .. 2 |-> 0],
      secretKeySecureIdExpiration |-> [i \in 1 .. 2 |-> 0],
      faultToleranceIndicator     |-> [i \in 1 .. 1 |-> 0],
      splitMsg                    |-> [i \in 1 .. 1 |-> 0] ]

(* Establishment Ack at zero, then each field in turn at the values it is checked at *)
CheckedEstablishmentAck ==
    { ZeroEstablishmentAck }
        \cup { [ZeroEstablishmentAck EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentAck EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentAck EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroEstablishmentAck EXCEPT !.previousSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroEstablishmentAck EXCEPT !.previousUuid = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentAck EXCEPT !.keepAliveInterval = one] : one \in Sample(2) }
        \cup { [ZeroEstablishmentAck EXCEPT !.secretKeySecureIdExpiration = one] : one \in Sample(2) }
        \cup { [ZeroEstablishmentAck EXCEPT !.faultToleranceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEstablishmentAck EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Establishment Reject: 72 bytes                                          *)
(***************************************************************************)

EstablishmentReject ==
    [ reason                  : Sample(48),
      uuid                    : Sample(8),
      requestTimestamp        : Sample(8),
      nextSeqNo               : Sample(4),
      errorCodes              : Sample(2),
      faultToleranceIndicator : Sample(1),
      splitMsg                : Sample(1) ]

EncodeEstablishmentReject(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.nextSeqNo
        \o message.errorCodes
        \o message.faultToleranceIndicator
        \o message.splitMsg

DecodeEstablishmentReject(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(requestTimestamp.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(nextSeqNo.rest, 2) IN IF ~errorCodes.ok THEN Fail ELSE
    LET faultToleranceIndicator == ReadBytes(errorCodes.rest, 1) IN IF ~faultToleranceIndicator.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(faultToleranceIndicator.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ reason                  |-> reason.value,
         uuid                    |-> uuid.value,
         requestTimestamp        |-> requestTimestamp.value,
         nextSeqNo               |-> nextSeqNo.value,
         errorCodes              |-> errorCodes.value,
         faultToleranceIndicator |-> faultToleranceIndicator.value,
         splitMsg                |-> splitMsg.value ], splitMsg.rest)

ZeroEstablishmentReject ==
    [ reason                  |-> [i \in 1 .. 48 |-> 0],
      uuid                    |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp        |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo               |-> [i \in 1 .. 4 |-> 0],
      errorCodes              |-> [i \in 1 .. 2 |-> 0],
      faultToleranceIndicator |-> [i \in 1 .. 1 |-> 0],
      splitMsg                |-> [i \in 1 .. 1 |-> 0] ]

(* Establishment Reject at zero, then each field in turn at the values it is checked at *)
CheckedEstablishmentReject ==
    { ZeroEstablishmentReject }
        \cup { [ZeroEstablishmentReject EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroEstablishmentReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentReject EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishmentReject EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroEstablishmentReject EXCEPT !.errorCodes = one] : one \in Sample(2) }
        \cup { [ZeroEstablishmentReject EXCEPT !.faultToleranceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEstablishmentReject EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequence: 14 bytes                                                      *)
(***************************************************************************)

Sequence ==
    [ uuid                    : Sample(8),
      nextSeqNo               : Sample(4),
      faultToleranceIndicator : Sample(1),
      keepAliveIntervalLapsed : Sample(1) ]

EncodeSequence(message) ==
    message.uuid
        \o message.nextSeqNo
        \o message.faultToleranceIndicator
        \o message.keepAliveIntervalLapsed

DecodeSequence(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(uuid.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET faultToleranceIndicator == ReadBytes(nextSeqNo.rest, 1) IN IF ~faultToleranceIndicator.ok THEN Fail ELSE
    LET keepAliveIntervalLapsed == ReadBytes(faultToleranceIndicator.rest, 1) IN IF ~keepAliveIntervalLapsed.ok THEN Fail ELSE
    Ok([ uuid                    |-> uuid.value,
         nextSeqNo               |-> nextSeqNo.value,
         faultToleranceIndicator |-> faultToleranceIndicator.value,
         keepAliveIntervalLapsed |-> keepAliveIntervalLapsed.value ], keepAliveIntervalLapsed.rest)

ZeroSequence ==
    [ uuid                    |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo               |-> [i \in 1 .. 4 |-> 0],
      faultToleranceIndicator |-> [i \in 1 .. 1 |-> 0],
      keepAliveIntervalLapsed |-> [i \in 1 .. 1 |-> 0] ]

(* Sequence at zero, then each field in turn at the values it is checked at *)
CheckedSequence ==
    { ZeroSequence }
        \cup { [ZeroSequence EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroSequence EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSequence EXCEPT !.faultToleranceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSequence EXCEPT !.keepAliveIntervalLapsed = one] : one \in Sample(1) }

(***************************************************************************)
(* Terminate: 67 bytes                                                     *)
(***************************************************************************)

Terminate ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(2),
      splitMsg         : Sample(1) ]

EncodeTerminate(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.splitMsg

DecodeTerminate(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 2) IN IF ~errorCodes.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(errorCodes.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         splitMsg         |-> splitMsg.value ], splitMsg.rest)

ZeroTerminate ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 2 |-> 0],
      splitMsg         |-> [i \in 1 .. 1 |-> 0] ]

(* Terminate at zero, then each field in turn at the values it is checked at *)
CheckedTerminate ==
    { ZeroTerminate }
        \cup { [ZeroTerminate EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroTerminate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.errorCodes = one] : one \in Sample(2) }
        \cup { [ZeroTerminate EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission: 31 bytes                                                *)
(***************************************************************************)

Retransmission ==
    [ uuid             : Sample(8),
      lastUuid         : Sample(8),
      requestTimestamp : Sample(8),
      fromSeqNo        : Sample(4),
      msgCount16       : Sample(2),
      splitMsg         : Sample(1) ]

EncodeRetransmission(message) ==
    message.uuid
        \o message.lastUuid
        \o message.requestTimestamp
        \o message.fromSeqNo
        \o message.msgCount16
        \o message.splitMsg

DecodeRetransmission(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET lastUuid == ReadBytes(uuid.rest, 8) IN IF ~lastUuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(lastUuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET fromSeqNo == ReadBytes(requestTimestamp.rest, 4) IN IF ~fromSeqNo.ok THEN Fail ELSE
    LET msgCount16 == ReadBytes(fromSeqNo.rest, 2) IN IF ~msgCount16.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(msgCount16.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ uuid             |-> uuid.value,
         lastUuid         |-> lastUuid.value,
         requestTimestamp |-> requestTimestamp.value,
         fromSeqNo        |-> fromSeqNo.value,
         msgCount16       |-> msgCount16.value,
         splitMsg         |-> splitMsg.value ], splitMsg.rest)

ZeroRetransmission ==
    [ uuid             |-> [i \in 1 .. 8 |-> 0],
      lastUuid         |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      fromSeqNo        |-> [i \in 1 .. 4 |-> 0],
      msgCount16       |-> [i \in 1 .. 2 |-> 0],
      splitMsg         |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmission at zero, then each field in turn at the values it is checked at *)
CheckedRetransmission ==
    { ZeroRetransmission }
        \cup { [ZeroRetransmission EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroRetransmission EXCEPT !.lastUuid = one] : one \in Sample(8) }
        \cup { [ZeroRetransmission EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmission EXCEPT !.fromSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroRetransmission EXCEPT !.msgCount16 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmission EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmit Reject: 75 bytes                                             *)
(***************************************************************************)

RetransmitReject ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      lastUuid         : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(2),
      splitMsg         : Sample(1) ]

EncodeRetransmitReject(message) ==
    message.reason
        \o message.uuid
        \o message.lastUuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.splitMsg

DecodeRetransmitReject(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET lastUuid == ReadBytes(uuid.rest, 8) IN IF ~lastUuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(lastUuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 2) IN IF ~errorCodes.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(errorCodes.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         lastUuid         |-> lastUuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         splitMsg         |-> splitMsg.value ], splitMsg.rest)

ZeroRetransmitReject ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      lastUuid         |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 2 |-> 0],
      splitMsg         |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Reject at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitReject ==
    { ZeroRetransmitReject }
        \cup { [ZeroRetransmitReject EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroRetransmitReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitReject EXCEPT !.lastUuid = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitReject EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitReject EXCEPT !.errorCodes = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitReject EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Not Applied: 17 bytes                                                   *)
(***************************************************************************)

NotApplied ==
    [ uuid      : Sample(8),
      fromSeqNo : Sample(4),
      msgCount  : Sample(4),
      splitMsg  : Sample(1) ]

EncodeNotApplied(message) ==
    message.uuid
        \o message.fromSeqNo
        \o message.msgCount
        \o message.splitMsg

DecodeNotApplied(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET fromSeqNo == ReadBytes(uuid.rest, 4) IN IF ~fromSeqNo.ok THEN Fail ELSE
    LET msgCount == ReadBytes(fromSeqNo.rest, 4) IN IF ~msgCount.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(msgCount.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ uuid      |-> uuid.value,
         fromSeqNo |-> fromSeqNo.value,
         msgCount  |-> msgCount.value,
         splitMsg  |-> splitMsg.value ], splitMsg.rest)

ZeroNotApplied ==
    [ uuid      |-> [i \in 1 .. 8 |-> 0],
      fromSeqNo |-> [i \in 1 .. 4 |-> 0],
      msgCount  |-> [i \in 1 .. 4 |-> 0],
      splitMsg  |-> [i \in 1 .. 1 |-> 0] ]

(* Not Applied at zero, then each field in turn at the values it is checked at *)
CheckedNotApplied ==
    { ZeroNotApplied }
        \cup { [ZeroNotApplied EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNotApplied EXCEPT !.fromSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroNotApplied EXCEPT !.msgCount = one] : one \in Sample(4) }
        \cup { [ZeroNotApplied EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Party Details Group: 22 bytes                                           *)
(***************************************************************************)

PartyDetailsGroup ==
    [ partyDetailId   : Sample(20),
      partyDetailRole : Sample(2) ]

EncodePartyDetailsGroup(message) ==
    message.partyDetailId
        \o message.partyDetailRole

DecodePartyDetailsGroup(bytes) ==
    LET partyDetailId == ReadBytes(bytes, 20) IN IF ~partyDetailId.ok THEN Fail ELSE
    LET partyDetailRole == ReadBytes(partyDetailId.rest, 2) IN IF ~partyDetailRole.ok THEN Fail ELSE
    Ok([ partyDetailId   |-> partyDetailId.value,
         partyDetailRole |-> partyDetailRole.value ], partyDetailRole.rest)

ZeroPartyDetailsGroup ==
    [ partyDetailId   |-> [i \in 1 .. 20 |-> 0],
      partyDetailRole |-> [i \in 1 .. 2 |-> 0] ]

(* Party Details Group at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGroup ==
    { ZeroPartyDetailsGroup }
        \cup { [ZeroPartyDetailsGroup EXCEPT !.partyDetailId = one] : one \in Sample(20) }
        \cup { [ZeroPartyDetailsGroup EXCEPT !.partyDetailRole = one] : one \in Sample(2) }

(* A run of Party Details Group, written one after another *)
RECURSIVE EncodePartyDetailsGroupList(_)
EncodePartyDetailsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartyDetailsGroup(Head(messages)) \o EncodePartyDetailsGroupList(Tail(messages))

(* As many Party Details Group as the field that counts them says *)
RECURSIVE ReadPartyDetailsGroupList(_, _)
ReadPartyDetailsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartyDetailsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartyDetailsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Party Details Group of each kind, for the lists that carry them *)
OnePartyDetailsGroup == { ZeroPartyDetailsGroup }

(***************************************************************************)
(* Party Details Groups                                                    *)
(***************************************************************************)

PartyDetailsGroups ==
    [ blockLength       : Sample(2),
      partyDetailsGroup : SampleLists(OnePartyDetailsGroup) ]

EncodePartyDetailsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.partyDetailsGroup), 1)
        \o EncodePartyDetailsGroupList(message.partyDetailsGroup)

DecodePartyDetailsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partyDetailsGroup == ReadPartyDetailsGroupList(numInGroup.rest, numInGroup.value) IN IF ~partyDetailsGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         partyDetailsGroup |-> partyDetailsGroup.value ], partyDetailsGroup.rest)

ZeroPartyDetailsGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      partyDetailsGroup |-> << >> ]

(* Party Details Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGroups ==
    { ZeroPartyDetailsGroups }
        \cup { [ZeroPartyDetailsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPartyDetailsGroups EXCEPT !.partyDetailsGroup = one] : one \in SampleLists(OnePartyDetailsGroup) }

(***************************************************************************)
(* Trd Reg Publications Group: 2 bytes                                     *)
(***************************************************************************)

TrdRegPublicationsGroup ==
    [ trdRegPublicationType   : Sample(1),
      trdRegPublicationReason : Sample(1) ]

EncodeTrdRegPublicationsGroup(message) ==
    message.trdRegPublicationType
        \o message.trdRegPublicationReason

DecodeTrdRegPublicationsGroup(bytes) ==
    LET trdRegPublicationType == ReadBytes(bytes, 1) IN IF ~trdRegPublicationType.ok THEN Fail ELSE
    LET trdRegPublicationReason == ReadBytes(trdRegPublicationType.rest, 1) IN IF ~trdRegPublicationReason.ok THEN Fail ELSE
    Ok([ trdRegPublicationType   |-> trdRegPublicationType.value,
         trdRegPublicationReason |-> trdRegPublicationReason.value ], trdRegPublicationReason.rest)

ZeroTrdRegPublicationsGroup ==
    [ trdRegPublicationType   |-> [i \in 1 .. 1 |-> 0],
      trdRegPublicationReason |-> [i \in 1 .. 1 |-> 0] ]

(* Trd Reg Publications Group at zero, then each field in turn at the values it is checked at *)
CheckedTrdRegPublicationsGroup ==
    { ZeroTrdRegPublicationsGroup }
        \cup { [ZeroTrdRegPublicationsGroup EXCEPT !.trdRegPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTrdRegPublicationsGroup EXCEPT !.trdRegPublicationReason = one] : one \in Sample(1) }

(* A run of Trd Reg Publications Group, written one after another *)
RECURSIVE EncodeTrdRegPublicationsGroupList(_)
EncodeTrdRegPublicationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdRegPublicationsGroup(Head(messages)) \o EncodeTrdRegPublicationsGroupList(Tail(messages))

(* As many Trd Reg Publications Group as the field that counts them says *)
RECURSIVE ReadTrdRegPublicationsGroupList(_, _)
ReadTrdRegPublicationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdRegPublicationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdRegPublicationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Reg Publications Group of each kind, for the lists that carry them *)
OneTrdRegPublicationsGroup == { ZeroTrdRegPublicationsGroup }

(***************************************************************************)
(* Trd Reg Publications Groups                                             *)
(***************************************************************************)

TrdRegPublicationsGroups ==
    [ blockLength             : Sample(2),
      trdRegPublicationsGroup : SampleLists(OneTrdRegPublicationsGroup) ]

EncodeTrdRegPublicationsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.trdRegPublicationsGroup), 1)
        \o EncodeTrdRegPublicationsGroupList(message.trdRegPublicationsGroup)

DecodeTrdRegPublicationsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET trdRegPublicationsGroup == ReadTrdRegPublicationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~trdRegPublicationsGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         trdRegPublicationsGroup |-> trdRegPublicationsGroup.value ], trdRegPublicationsGroup.rest)

ZeroTrdRegPublicationsGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      trdRegPublicationsGroup |-> << >> ]

(* Trd Reg Publications Groups at zero, then each field in turn at the values it is checked at *)
CheckedTrdRegPublicationsGroups ==
    { ZeroTrdRegPublicationsGroups }
        \cup { [ZeroTrdRegPublicationsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTrdRegPublicationsGroups EXCEPT !.trdRegPublicationsGroup = one] : one \in SampleLists(OneTrdRegPublicationsGroup) }

(***************************************************************************)
(* Party Details Definition Request Ack                                    *)
(***************************************************************************)

PartyDetailsDefinitionRequestAck ==
    [ seqNum                         : Sample(4),
      uuid                           : Sample(8),
      memo                           : Sample(75),
      avgPxGroupId                   : Sample(20),
      partyDetailsListReqId          : Sample(8),
      sendingTimeEpoch               : Sample(8),
      selfMatchPreventionId          : Sample(8),
      partyDetailRequestStatus       : Sample(1),
      custOrderCapacity              : Sample(1),
      clearingAccountType            : Sample(1),
      selfMatchPreventionInstruction : Sample(1),
      avgPxIndicator                 : Sample(1),
      clearingTradePriceType         : Sample(1),
      cmtaGiveupCd                   : Sample(1),
      custOrderHandlingInst          : Sample(1),
      listUpdateAction               : Sample(1),
      partyDetailDefinitionStatus    : Sample(1),
      executor                       : Sample(8),
      idmShortCode                   : Sample(8),
      possRetransFlag                : Sample(1),
      splitMsg                       : Sample(1),
      partyDetailsGroups             : PartyDetailsGroups,
      trdRegPublicationsGroups       : TrdRegPublicationsGroups ]

EncodePartyDetailsDefinitionRequestAck(message) ==
    message.seqNum
        \o message.uuid
        \o message.memo
        \o message.avgPxGroupId
        \o message.partyDetailsListReqId
        \o message.sendingTimeEpoch
        \o message.selfMatchPreventionId
        \o message.partyDetailRequestStatus
        \o message.custOrderCapacity
        \o message.clearingAccountType
        \o message.selfMatchPreventionInstruction
        \o message.avgPxIndicator
        \o message.clearingTradePriceType
        \o message.cmtaGiveupCd
        \o message.custOrderHandlingInst
        \o message.listUpdateAction
        \o message.partyDetailDefinitionStatus
        \o message.executor
        \o message.idmShortCode
        \o message.possRetransFlag
        \o message.splitMsg
        \o EncodePartyDetailsGroups(message.partyDetailsGroups)
        \o EncodeTrdRegPublicationsGroups(message.trdRegPublicationsGroups)

DecodePartyDetailsDefinitionRequestAck(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET memo == ReadBytes(uuid.rest, 75) IN IF ~memo.ok THEN Fail ELSE
    LET avgPxGroupId == ReadBytes(memo.rest, 20) IN IF ~avgPxGroupId.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(avgPxGroupId.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET partyDetailRequestStatus == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~partyDetailRequestStatus.ok THEN Fail ELSE
    LET custOrderCapacity == ReadBytes(partyDetailRequestStatus.rest, 1) IN IF ~custOrderCapacity.ok THEN Fail ELSE
    LET clearingAccountType == ReadBytes(custOrderCapacity.rest, 1) IN IF ~clearingAccountType.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(clearingAccountType.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET avgPxIndicator == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~avgPxIndicator.ok THEN Fail ELSE
    LET clearingTradePriceType == ReadBytes(avgPxIndicator.rest, 1) IN IF ~clearingTradePriceType.ok THEN Fail ELSE
    LET cmtaGiveupCd == ReadBytes(clearingTradePriceType.rest, 1) IN IF ~cmtaGiveupCd.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(cmtaGiveupCd.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET listUpdateAction == ReadBytes(custOrderHandlingInst.rest, 1) IN IF ~listUpdateAction.ok THEN Fail ELSE
    LET partyDetailDefinitionStatus == ReadBytes(listUpdateAction.rest, 1) IN IF ~partyDetailDefinitionStatus.ok THEN Fail ELSE
    LET executor == ReadBytes(partyDetailDefinitionStatus.rest, 8) IN IF ~executor.ok THEN Fail ELSE
    LET idmShortCode == ReadBytes(executor.rest, 8) IN IF ~idmShortCode.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(idmShortCode.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET partyDetailsGroups == DecodePartyDetailsGroups(splitMsg.rest) IN IF ~partyDetailsGroups.ok THEN Fail ELSE
    LET trdRegPublicationsGroups == DecodeTrdRegPublicationsGroups(partyDetailsGroups.rest) IN IF ~trdRegPublicationsGroups.ok THEN Fail ELSE
    Ok([ seqNum                         |-> seqNum.value,
         uuid                           |-> uuid.value,
         memo                           |-> memo.value,
         avgPxGroupId                   |-> avgPxGroupId.value,
         partyDetailsListReqId          |-> partyDetailsListReqId.value,
         sendingTimeEpoch               |-> sendingTimeEpoch.value,
         selfMatchPreventionId          |-> selfMatchPreventionId.value,
         partyDetailRequestStatus       |-> partyDetailRequestStatus.value,
         custOrderCapacity              |-> custOrderCapacity.value,
         clearingAccountType            |-> clearingAccountType.value,
         selfMatchPreventionInstruction |-> selfMatchPreventionInstruction.value,
         avgPxIndicator                 |-> avgPxIndicator.value,
         clearingTradePriceType         |-> clearingTradePriceType.value,
         cmtaGiveupCd                   |-> cmtaGiveupCd.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value,
         listUpdateAction               |-> listUpdateAction.value,
         partyDetailDefinitionStatus    |-> partyDetailDefinitionStatus.value,
         executor                       |-> executor.value,
         idmShortCode                   |-> idmShortCode.value,
         possRetransFlag                |-> possRetransFlag.value,
         splitMsg                       |-> splitMsg.value,
         partyDetailsGroups             |-> partyDetailsGroups.value,
         trdRegPublicationsGroups       |-> trdRegPublicationsGroups.value ], trdRegPublicationsGroups.rest)

ZeroPartyDetailsDefinitionRequestAck ==
    [ seqNum                         |-> [i \in 1 .. 4 |-> 0],
      uuid                           |-> [i \in 1 .. 8 |-> 0],
      memo                           |-> [i \in 1 .. 75 |-> 0],
      avgPxGroupId                   |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch               |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionId          |-> [i \in 1 .. 8 |-> 0],
      partyDetailRequestStatus       |-> [i \in 1 .. 1 |-> 0],
      custOrderCapacity              |-> [i \in 1 .. 1 |-> 0],
      clearingAccountType            |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      avgPxIndicator                 |-> [i \in 1 .. 1 |-> 0],
      clearingTradePriceType         |-> [i \in 1 .. 1 |-> 0],
      cmtaGiveupCd                   |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst          |-> [i \in 1 .. 1 |-> 0],
      listUpdateAction               |-> [i \in 1 .. 1 |-> 0],
      partyDetailDefinitionStatus    |-> [i \in 1 .. 1 |-> 0],
      executor                       |-> [i \in 1 .. 8 |-> 0],
      idmShortCode                   |-> [i \in 1 .. 8 |-> 0],
      possRetransFlag                |-> [i \in 1 .. 1 |-> 0],
      splitMsg                       |-> [i \in 1 .. 1 |-> 0],
      partyDetailsGroups             |-> ZeroPartyDetailsGroups,
      trdRegPublicationsGroups       |-> ZeroTrdRegPublicationsGroups ]

(* Party Details Definition Request Ack at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsDefinitionRequestAck ==
    { ZeroPartyDetailsDefinitionRequestAck }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.memo = one] : one \in Sample(75) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.avgPxGroupId = one] : one \in Sample(20) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.partyDetailRequestStatus = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.custOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.clearingAccountType = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.avgPxIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.clearingTradePriceType = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.cmtaGiveupCd = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.listUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.partyDetailDefinitionStatus = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.executor = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.idmShortCode = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.partyDetailsGroups = one] : one \in CheckedPartyDetailsGroups }
        \cup { [ZeroPartyDetailsDefinitionRequestAck EXCEPT !.trdRegPublicationsGroups = one] : one \in CheckedTrdRegPublicationsGroups }

(***************************************************************************)
(* Business Reject: 330 bytes                                              *)
(***************************************************************************)

BusinessReject ==
    [ seqNum                        : Sample(4),
      uuid                          : Sample(8),
      text                          : Sample(256),
      senderIdOptional              : Sample(20),
      partyDetailsListReqIdOptional : Sample(8),
      sendingTimeEpoch              : Sample(8),
      businessRejectRefId           : Sample(8),
      locationOptional              : Sample(5),
      refSeqNum                     : Sample(4),
      refTagId                      : Sample(2),
      businessRejectReason          : Sample(2),
      refMsgType                    : Sample(2),
      possRetransFlag               : Sample(1),
      manualOrderIndicatorOptional  : Sample(1),
      splitMsg                      : Sample(1) ]

EncodeBusinessReject(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.senderIdOptional
        \o message.partyDetailsListReqIdOptional
        \o message.sendingTimeEpoch
        \o message.businessRejectRefId
        \o message.locationOptional
        \o message.refSeqNum
        \o message.refTagId
        \o message.businessRejectReason
        \o message.refMsgType
        \o message.possRetransFlag
        \o message.manualOrderIndicatorOptional
        \o message.splitMsg

DecodeBusinessReject(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET senderIdOptional == ReadBytes(text.rest, 20) IN IF ~senderIdOptional.ok THEN Fail ELSE
    LET partyDetailsListReqIdOptional == ReadBytes(senderIdOptional.rest, 8) IN IF ~partyDetailsListReqIdOptional.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReqIdOptional.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET businessRejectRefId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~businessRejectRefId.ok THEN Fail ELSE
    LET locationOptional == ReadBytes(businessRejectRefId.rest, 5) IN IF ~locationOptional.ok THEN Fail ELSE
    LET refSeqNum == ReadBytes(locationOptional.rest, 4) IN IF ~refSeqNum.ok THEN Fail ELSE
    LET refTagId == ReadBytes(refSeqNum.rest, 2) IN IF ~refTagId.ok THEN Fail ELSE
    LET businessRejectReason == ReadBytes(refTagId.rest, 2) IN IF ~businessRejectReason.ok THEN Fail ELSE
    LET refMsgType == ReadBytes(businessRejectReason.rest, 2) IN IF ~refMsgType.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(refMsgType.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET manualOrderIndicatorOptional == ReadBytes(possRetransFlag.rest, 1) IN IF ~manualOrderIndicatorOptional.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(manualOrderIndicatorOptional.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ seqNum                        |-> seqNum.value,
         uuid                          |-> uuid.value,
         text                          |-> text.value,
         senderIdOptional              |-> senderIdOptional.value,
         partyDetailsListReqIdOptional |-> partyDetailsListReqIdOptional.value,
         sendingTimeEpoch              |-> sendingTimeEpoch.value,
         businessRejectRefId           |-> businessRejectRefId.value,
         locationOptional              |-> locationOptional.value,
         refSeqNum                     |-> refSeqNum.value,
         refTagId                      |-> refTagId.value,
         businessRejectReason          |-> businessRejectReason.value,
         refMsgType                    |-> refMsgType.value,
         possRetransFlag               |-> possRetransFlag.value,
         manualOrderIndicatorOptional  |-> manualOrderIndicatorOptional.value,
         splitMsg                      |-> splitMsg.value ], splitMsg.rest)

ZeroBusinessReject ==
    [ seqNum                        |-> [i \in 1 .. 4 |-> 0],
      uuid                          |-> [i \in 1 .. 8 |-> 0],
      text                          |-> [i \in 1 .. 256 |-> 0],
      senderIdOptional              |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqIdOptional |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch              |-> [i \in 1 .. 8 |-> 0],
      businessRejectRefId           |-> [i \in 1 .. 8 |-> 0],
      locationOptional              |-> [i \in 1 .. 5 |-> 0],
      refSeqNum                     |-> [i \in 1 .. 4 |-> 0],
      refTagId                      |-> [i \in 1 .. 2 |-> 0],
      businessRejectReason          |-> [i \in 1 .. 2 |-> 0],
      refMsgType                    |-> [i \in 1 .. 2 |-> 0],
      possRetransFlag               |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicatorOptional  |-> [i \in 1 .. 1 |-> 0],
      splitMsg                      |-> [i \in 1 .. 1 |-> 0] ]

(* Business Reject at zero, then each field in turn at the values it is checked at *)
CheckedBusinessReject ==
    { ZeroBusinessReject }
        \cup { [ZeroBusinessReject EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroBusinessReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroBusinessReject EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroBusinessReject EXCEPT !.senderIdOptional = one] : one \in Sample(20) }
        \cup { [ZeroBusinessReject EXCEPT !.partyDetailsListReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroBusinessReject EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroBusinessReject EXCEPT !.businessRejectRefId = one] : one \in Sample(8) }
        \cup { [ZeroBusinessReject EXCEPT !.locationOptional = one] : one \in Sample(5) }
        \cup { [ZeroBusinessReject EXCEPT !.refSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBusinessReject EXCEPT !.refTagId = one] : one \in Sample(2) }
        \cup { [ZeroBusinessReject EXCEPT !.businessRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroBusinessReject EXCEPT !.refMsgType = one] : one \in Sample(2) }
        \cup { [ZeroBusinessReject EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroBusinessReject EXCEPT !.manualOrderIndicatorOptional = one] : one \in Sample(1) }
        \cup { [ZeroBusinessReject EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Report New: 217 bytes                                         *)
(***************************************************************************)

ExecutionReportNew ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      stopPx                : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      crossIdOptional       : Sample(8),
      hostCrossId           : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      orderQty              : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      delayDuration         : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      crossType             : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      delayToTime           : Sample(8),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportNew(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.price
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.delayDuration
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.delayToTime
        \o message.discretionPrice

DecodeExecutionReportNew(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(orderRequestId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(expireDate.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(delayDuration.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET crossType == ReadBytes(splitMsg.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(shortSaleType.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(delayToTime.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         stopPx                |-> stopPx.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         crossIdOptional       |-> crossIdOptional.value,
         hostCrossId           |-> hostCrossId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         orderQty              |-> orderQty.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         delayDuration         |-> delayDuration.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         crossType             |-> crossType.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         delayToTime           |-> delayToTime.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportNew ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional       |-> [i \in 1 .. 8 |-> 0],
      hostCrossId           |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      crossType             |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report New at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportNew ==
    { ZeroExecutionReportNew }
        \cup { [ZeroExecutionReportNew EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNew EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportNew EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportNew EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportNew EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportNew EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNew EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNew EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNew EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNew EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNew EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNew EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNew EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNew EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Reject: 475 bytes                                      *)
(***************************************************************************)

ExecutionReportReject ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      text                  : Sample(256),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      priceOptional         : Sample(8),
      stopPx                : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      crossIdOptional       : Sample(8),
      hostCrossId           : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      orderQty              : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      ordRejReason          : Sample(2),
      expireDate            : Sample(2),
      delayDuration         : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      crossType             : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      delayToTime           : Sample(8),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportReject(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.priceOptional
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.minQty
        \o message.displayQty
        \o message.ordRejReason
        \o message.expireDate
        \o message.delayDuration
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.delayToTime
        \o message.discretionPrice

DecodeExecutionReportReject(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET execId == ReadBytes(text.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderId.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(orderRequestId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(displayQty.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET expireDate == ReadBytes(ordRejReason.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(expireDate.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(delayDuration.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET crossType == ReadBytes(splitMsg.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(shortSaleType.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(delayToTime.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         text                  |-> text.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         priceOptional         |-> priceOptional.value,
         stopPx                |-> stopPx.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         crossIdOptional       |-> crossIdOptional.value,
         hostCrossId           |-> hostCrossId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         orderQty              |-> orderQty.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         ordRejReason          |-> ordRejReason.value,
         expireDate            |-> expireDate.value,
         delayDuration         |-> delayDuration.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         crossType             |-> crossType.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         delayToTime           |-> delayToTime.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportReject ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      text                  |-> [i \in 1 .. 256 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      priceOptional         |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional       |-> [i \in 1 .. 8 |-> 0],
      hostCrossId           |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      ordRejReason          |-> [i \in 1 .. 2 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      crossType             |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Reject at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportReject ==
    { ZeroExecutionReportReject }
        \cup { [ZeroExecutionReportReject EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroExecutionReportReject EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportReject EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportReject EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportReject EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportReject EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReject EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReject EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReject EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportReject EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportReject EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportReject EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportReject EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportReject EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportReject EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Elimination: 210 bytes                                 *)
(***************************************************************************)

ExecutionReportElimination ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      stopPx                : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      crossIdOptional       : Sample(8),
      hostCrossId           : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      cumQty                : Sample(4),
      orderQty              : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      crossType             : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportElimination(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.price
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.cumQty
        \o message.orderQty
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.discretionPrice

DecodeExecutionReportElimination(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(orderRequestId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(securityId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cumQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(expireDate.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET crossType == ReadBytes(possRetransFlag.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(shortSaleType.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         stopPx                |-> stopPx.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         crossIdOptional       |-> crossIdOptional.value,
         hostCrossId           |-> hostCrossId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         cumQty                |-> cumQty.value,
         orderQty              |-> orderQty.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         crossType             |-> crossType.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportElimination ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional       |-> [i \in 1 .. 8 |-> 0],
      hostCrossId           |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      crossType             |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Elimination at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportElimination ==
    { ZeroExecutionReportElimination }
        \cup { [ZeroExecutionReportElimination EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportElimination EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Calculated Ccy Last Qty: 9 bytes                                        *)
(***************************************************************************)

CalculatedCcyLastQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeCalculatedCcyLastQty(message) ==
    message.mantissa
        \o message.exponent

DecodeCalculatedCcyLastQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroCalculatedCcyLastQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Calculated Ccy Last Qty at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedCcyLastQty ==
    { ZeroCalculatedCcyLastQty }
        \cup { [ZeroCalculatedCcyLastQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedCcyLastQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Gross Trade Amt: 9 bytes                                                *)
(***************************************************************************)

GrossTradeAmt ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeGrossTradeAmt(message) ==
    message.mantissa
        \o message.exponent

DecodeGrossTradeAmt(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroGrossTradeAmt ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Gross Trade Amt at zero, then each field in turn at the values it is checked at *)
CheckedGrossTradeAmt ==
    { ZeroGrossTradeAmt }
        \cup { [ZeroGrossTradeAmt EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroGrossTradeAmt EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Group: 15 bytes                                                   *)
(***************************************************************************)

FillsGroup ==
    [ fillPx        : Sample(8),
      fillQty       : Sample(4),
      fillExecId    : Sample(2),
      fillYieldType : Sample(1) ]

EncodeFillsGroup(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillExecId
        \o message.fillYieldType

DecodeFillsGroup(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillQty.rest, 2) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillYieldType == ReadBytes(fillExecId.rest, 1) IN IF ~fillYieldType.ok THEN Fail ELSE
    Ok([ fillPx        |-> fillPx.value,
         fillQty       |-> fillQty.value,
         fillExecId    |-> fillExecId.value,
         fillYieldType |-> fillYieldType.value ], fillYieldType.rest)

ZeroFillsGroup ==
    [ fillPx        |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      fillExecId    |-> [i \in 1 .. 2 |-> 0],
      fillYieldType |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroup ==
    { ZeroFillsGroup }
        \cup { [ZeroFillsGroup EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGroup EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGroup EXCEPT !.fillExecId = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroup EXCEPT !.fillYieldType = one] : one \in Sample(1) }

(* A run of Fills Group, written one after another *)
RECURSIVE EncodeFillsGroupList(_)
EncodeFillsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGroup(Head(messages)) \o EncodeFillsGroupList(Tail(messages))

(* As many Fills Group as the field that counts them says *)
RECURSIVE ReadFillsGroupList(_, _)
ReadFillsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Group of each kind, for the lists that carry them *)
OneFillsGroup == { ZeroFillsGroup }

(***************************************************************************)
(* Fills Groups                                                            *)
(***************************************************************************)

FillsGroups ==
    [ blockLength : Sample(2),
      fillsGroup  : SampleLists(OneFillsGroup) ]

EncodeFillsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.fillsGroup), 1)
        \o EncodeFillsGroupList(message.fillsGroup)

DecodeFillsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillsGroup == ReadFillsGroupList(numInGroup.rest, numInGroup.value) IN IF ~fillsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         fillsGroup  |-> fillsGroup.value ], fillsGroup.rest)

ZeroFillsGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      fillsGroup  |-> << >> ]

(* Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroups ==
    { ZeroFillsGroups }
        \cup { [ZeroFillsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroups EXCEPT !.fillsGroup = one] : one \in SampleLists(OneFillsGroup) }

(***************************************************************************)
(* Contra Gross Trade Amt: 9 bytes                                         *)
(***************************************************************************)

ContraGrossTradeAmt ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeContraGrossTradeAmt(message) ==
    message.mantissa
        \o message.exponent

DecodeContraGrossTradeAmt(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroContraGrossTradeAmt ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Contra Gross Trade Amt at zero, then each field in turn at the values it is checked at *)
CheckedContraGrossTradeAmt ==
    { ZeroContraGrossTradeAmt }
        \cup { [ZeroContraGrossTradeAmt EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroContraGrossTradeAmt EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Contra Calculated Ccy Last Qty: 9 bytes                                 *)
(***************************************************************************)

ContraCalculatedCcyLastQty ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeContraCalculatedCcyLastQty(message) ==
    message.mantissa
        \o message.exponent

DecodeContraCalculatedCcyLastQty(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroContraCalculatedCcyLastQty ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Contra Calculated Ccy Last Qty at zero, then each field in turn at the values it is checked at *)
CheckedContraCalculatedCcyLastQty ==
    { ZeroContraCalculatedCcyLastQty }
        \cup { [ZeroContraCalculatedCcyLastQty EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroContraCalculatedCcyLastQty EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Outright Order Events Group: 41 bytes                                   *)
(***************************************************************************)

OutrightOrderEventsGroup ==
    [ orderEventPx               : Sample(8),
      orderEventText             : Sample(5),
      orderEventExecId           : Sample(4),
      orderEventQty              : Sample(4),
      orderEventType             : Sample(1),
      orderEventReason           : Sample(1),
      contraGrossTradeAmt        : ContraGrossTradeAmt,
      contraCalculatedCcyLastQty : ContraCalculatedCcyLastQty ]

EncodeOutrightOrderEventsGroup(message) ==
    message.orderEventPx
        \o message.orderEventText
        \o message.orderEventExecId
        \o message.orderEventQty
        \o message.orderEventType
        \o message.orderEventReason
        \o EncodeContraGrossTradeAmt(message.contraGrossTradeAmt)
        \o EncodeContraCalculatedCcyLastQty(message.contraCalculatedCcyLastQty)

DecodeOutrightOrderEventsGroup(bytes) ==
    LET orderEventPx == ReadBytes(bytes, 8) IN IF ~orderEventPx.ok THEN Fail ELSE
    LET orderEventText == ReadBytes(orderEventPx.rest, 5) IN IF ~orderEventText.ok THEN Fail ELSE
    LET orderEventExecId == ReadBytes(orderEventText.rest, 4) IN IF ~orderEventExecId.ok THEN Fail ELSE
    LET orderEventQty == ReadBytes(orderEventExecId.rest, 4) IN IF ~orderEventQty.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(orderEventQty.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET orderEventReason == ReadBytes(orderEventType.rest, 1) IN IF ~orderEventReason.ok THEN Fail ELSE
    LET contraGrossTradeAmt == DecodeContraGrossTradeAmt(orderEventReason.rest) IN IF ~contraGrossTradeAmt.ok THEN Fail ELSE
    LET contraCalculatedCcyLastQty == DecodeContraCalculatedCcyLastQty(contraGrossTradeAmt.rest) IN IF ~contraCalculatedCcyLastQty.ok THEN Fail ELSE
    Ok([ orderEventPx               |-> orderEventPx.value,
         orderEventText             |-> orderEventText.value,
         orderEventExecId           |-> orderEventExecId.value,
         orderEventQty              |-> orderEventQty.value,
         orderEventType             |-> orderEventType.value,
         orderEventReason           |-> orderEventReason.value,
         contraGrossTradeAmt        |-> contraGrossTradeAmt.value,
         contraCalculatedCcyLastQty |-> contraCalculatedCcyLastQty.value ], contraCalculatedCcyLastQty.rest)

ZeroOutrightOrderEventsGroup ==
    [ orderEventPx               |-> [i \in 1 .. 8 |-> 0],
      orderEventText             |-> [i \in 1 .. 5 |-> 0],
      orderEventExecId           |-> [i \in 1 .. 4 |-> 0],
      orderEventQty              |-> [i \in 1 .. 4 |-> 0],
      orderEventType             |-> [i \in 1 .. 1 |-> 0],
      orderEventReason           |-> [i \in 1 .. 1 |-> 0],
      contraGrossTradeAmt        |-> ZeroContraGrossTradeAmt,
      contraCalculatedCcyLastQty |-> ZeroContraCalculatedCcyLastQty ]

(* Outright Order Events Group at zero, then each field in turn at the values it is checked at *)
CheckedOutrightOrderEventsGroup ==
    { ZeroOutrightOrderEventsGroup }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.orderEventPx = one] : one \in Sample(8) }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.orderEventText = one] : one \in Sample(5) }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.orderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.orderEventQty = one] : one \in Sample(4) }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.orderEventReason = one] : one \in Sample(1) }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.contraGrossTradeAmt = one] : one \in CheckedContraGrossTradeAmt }
        \cup { [ZeroOutrightOrderEventsGroup EXCEPT !.contraCalculatedCcyLastQty = one] : one \in CheckedContraCalculatedCcyLastQty }

(* A run of Outright Order Events Group, written one after another *)
RECURSIVE EncodeOutrightOrderEventsGroupList(_)
EncodeOutrightOrderEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOutrightOrderEventsGroup(Head(messages)) \o EncodeOutrightOrderEventsGroupList(Tail(messages))

(* As many Outright Order Events Group as the field that counts them says *)
RECURSIVE ReadOutrightOrderEventsGroupList(_, _)
ReadOutrightOrderEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOutrightOrderEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOutrightOrderEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Outright Order Events Group of each kind, for the lists that carry them *)
OneOutrightOrderEventsGroup == { ZeroOutrightOrderEventsGroup }

(***************************************************************************)
(* Outright Order Events Groups                                            *)
(***************************************************************************)

OutrightOrderEventsGroups ==
    [ blockLength              : Sample(2),
      outrightOrderEventsGroup : SampleLists(OneOutrightOrderEventsGroup) ]

EncodeOutrightOrderEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.outrightOrderEventsGroup), 1)
        \o EncodeOutrightOrderEventsGroupList(message.outrightOrderEventsGroup)

DecodeOutrightOrderEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET outrightOrderEventsGroup == ReadOutrightOrderEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~outrightOrderEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         outrightOrderEventsGroup |-> outrightOrderEventsGroup.value ], outrightOrderEventsGroup.rest)

ZeroOutrightOrderEventsGroups ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      outrightOrderEventsGroup |-> << >> ]

(* Outright Order Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedOutrightOrderEventsGroups ==
    { ZeroOutrightOrderEventsGroups }
        \cup { [ZeroOutrightOrderEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOutrightOrderEventsGroups EXCEPT !.outrightOrderEventsGroup = one] : one \in SampleLists(OneOutrightOrderEventsGroup) }

(***************************************************************************)
(* Execution Report Trade Outright                                         *)
(***************************************************************************)

ExecutionReportTradeOutright ==
    [ seqNum                    : Sample(4),
      uuid                      : Sample(8),
      execId                    : Sample(40),
      senderId                  : Sample(20),
      clordid                   : Sample(20),
      partyDetailsListReqId     : Sample(8),
      lastPx                    : Sample(8),
      orderId                   : Sample(8),
      price                     : Sample(8),
      stopPx                    : Sample(8),
      transactTime              : Sample(8),
      sendingTimeEpoch          : Sample(8),
      orderRequestId            : Sample(8),
      secExecId                 : Sample(8),
      crossIdOptional           : Sample(8),
      hostCrossId               : Sample(8),
      location                  : Sample(5),
      securityId                : Sample(4),
      orderQty                  : Sample(4),
      lastQty                   : Sample(4),
      cumQty                    : Sample(4),
      mdTradeEntryId            : Sample(4),
      sideTradeId               : Sample(4),
      tradeLinkId               : Sample(4),
      leaves                    : Sample(4),
      tradeDate                 : Sample(2),
      expireDate                : Sample(2),
      ordStatusTrd              : Sample(1),
      ordTypeOptional           : Sample(1),
      side                      : Sample(1),
      timeInForce               : Sample(1),
      manualOrderIndicator      : Sample(1),
      possRetransFlag           : Sample(1),
      aggressorIndicator        : Sample(1),
      crossType                 : Sample(1),
      execInst                  : Sample(1),
      executionMode             : Sample(1),
      liquidityFlag             : Sample(1),
      managedOrder              : Sample(1),
      shortSaleType             : Sample(1),
      ownership                 : Sample(1),
      discretionPrice           : Sample(8),
      trdType                   : Sample(2),
      execRestatementReason     : Sample(1),
      settlDate                 : Sample(2),
      maturityDate              : Sample(2),
      calculatedCcyLastQty      : CalculatedCcyLastQty,
      grossTradeAmt             : GrossTradeAmt,
      benchmarkPrice            : Sample(8),
      fillsGroups               : FillsGroups,
      outrightOrderEventsGroups : OutrightOrderEventsGroups ]

EncodeExecutionReportTradeOutright(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.lastPx
        \o message.orderId
        \o message.price
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.secExecId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.lastQty
        \o message.cumQty
        \o message.mdTradeEntryId
        \o message.sideTradeId
        \o message.tradeLinkId
        \o message.leaves
        \o message.tradeDate
        \o message.expireDate
        \o message.ordStatusTrd
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.aggressorIndicator
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.ownership
        \o message.discretionPrice
        \o message.trdType
        \o message.execRestatementReason
        \o message.settlDate
        \o message.maturityDate
        \o EncodeCalculatedCcyLastQty(message.calculatedCcyLastQty)
        \o EncodeGrossTradeAmt(message.grossTradeAmt)
        \o message.benchmarkPrice
        \o EncodeFillsGroups(message.fillsGroups)
        \o EncodeOutrightOrderEventsGroups(message.outrightOrderEventsGroups)

DecodeExecutionReportTradeOutright(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET secExecId == ReadBytes(orderRequestId.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(secExecId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET lastQty == ReadBytes(orderQty.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(lastQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET mdTradeEntryId == ReadBytes(cumQty.rest, 4) IN IF ~mdTradeEntryId.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(mdTradeEntryId.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET tradeLinkId == ReadBytes(sideTradeId.rest, 4) IN IF ~tradeLinkId.ok THEN Fail ELSE
    LET leaves == ReadBytes(tradeLinkId.rest, 4) IN IF ~leaves.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(leaves.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET expireDate == ReadBytes(tradeDate.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordStatusTrd == ReadBytes(expireDate.rest, 1) IN IF ~ordStatusTrd.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(ordStatusTrd.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(possRetransFlag.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET crossType == ReadBytes(aggressorIndicator.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET ownership == ReadBytes(shortSaleType.rest, 1) IN IF ~ownership.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(ownership.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    LET trdType == ReadBytes(discretionPrice.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(trdType.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET settlDate == ReadBytes(execRestatementReason.rest, 2) IN IF ~settlDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(settlDate.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET calculatedCcyLastQty == DecodeCalculatedCcyLastQty(maturityDate.rest) IN IF ~calculatedCcyLastQty.ok THEN Fail ELSE
    LET grossTradeAmt == DecodeGrossTradeAmt(calculatedCcyLastQty.rest) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET benchmarkPrice == ReadBytes(grossTradeAmt.rest, 8) IN IF ~benchmarkPrice.ok THEN Fail ELSE
    LET fillsGroups == DecodeFillsGroups(benchmarkPrice.rest) IN IF ~fillsGroups.ok THEN Fail ELSE
    LET outrightOrderEventsGroups == DecodeOutrightOrderEventsGroups(fillsGroups.rest) IN IF ~outrightOrderEventsGroups.ok THEN Fail ELSE
    Ok([ seqNum                    |-> seqNum.value,
         uuid                      |-> uuid.value,
         execId                    |-> execId.value,
         senderId                  |-> senderId.value,
         clordid                   |-> clordid.value,
         partyDetailsListReqId     |-> partyDetailsListReqId.value,
         lastPx                    |-> lastPx.value,
         orderId                   |-> orderId.value,
         price                     |-> price.value,
         stopPx                    |-> stopPx.value,
         transactTime              |-> transactTime.value,
         sendingTimeEpoch          |-> sendingTimeEpoch.value,
         orderRequestId            |-> orderRequestId.value,
         secExecId                 |-> secExecId.value,
         crossIdOptional           |-> crossIdOptional.value,
         hostCrossId               |-> hostCrossId.value,
         location                  |-> location.value,
         securityId                |-> securityId.value,
         orderQty                  |-> orderQty.value,
         lastQty                   |-> lastQty.value,
         cumQty                    |-> cumQty.value,
         mdTradeEntryId            |-> mdTradeEntryId.value,
         sideTradeId               |-> sideTradeId.value,
         tradeLinkId               |-> tradeLinkId.value,
         leaves                    |-> leaves.value,
         tradeDate                 |-> tradeDate.value,
         expireDate                |-> expireDate.value,
         ordStatusTrd              |-> ordStatusTrd.value,
         ordTypeOptional           |-> ordTypeOptional.value,
         side                      |-> side.value,
         timeInForce               |-> timeInForce.value,
         manualOrderIndicator      |-> manualOrderIndicator.value,
         possRetransFlag           |-> possRetransFlag.value,
         aggressorIndicator        |-> aggressorIndicator.value,
         crossType                 |-> crossType.value,
         execInst                  |-> execInst.value,
         executionMode             |-> executionMode.value,
         liquidityFlag             |-> liquidityFlag.value,
         managedOrder              |-> managedOrder.value,
         shortSaleType             |-> shortSaleType.value,
         ownership                 |-> ownership.value,
         discretionPrice           |-> discretionPrice.value,
         trdType                   |-> trdType.value,
         execRestatementReason     |-> execRestatementReason.value,
         settlDate                 |-> settlDate.value,
         maturityDate              |-> maturityDate.value,
         calculatedCcyLastQty      |-> calculatedCcyLastQty.value,
         grossTradeAmt             |-> grossTradeAmt.value,
         benchmarkPrice            |-> benchmarkPrice.value,
         fillsGroups               |-> fillsGroups.value,
         outrightOrderEventsGroups |-> outrightOrderEventsGroups.value ], outrightOrderEventsGroups.rest)

ZeroExecutionReportTradeOutright ==
    [ seqNum                    |-> [i \in 1 .. 4 |-> 0],
      uuid                      |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 40 |-> 0],
      senderId                  |-> [i \in 1 .. 20 |-> 0],
      clordid                   |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId     |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      stopPx                    |-> [i \in 1 .. 8 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch          |-> [i \in 1 .. 8 |-> 0],
      orderRequestId            |-> [i \in 1 .. 8 |-> 0],
      secExecId                 |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional           |-> [i \in 1 .. 8 |-> 0],
      hostCrossId               |-> [i \in 1 .. 8 |-> 0],
      location                  |-> [i \in 1 .. 5 |-> 0],
      securityId                |-> [i \in 1 .. 4 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      lastQty                   |-> [i \in 1 .. 4 |-> 0],
      cumQty                    |-> [i \in 1 .. 4 |-> 0],
      mdTradeEntryId            |-> [i \in 1 .. 4 |-> 0],
      sideTradeId               |-> [i \in 1 .. 4 |-> 0],
      tradeLinkId               |-> [i \in 1 .. 4 |-> 0],
      leaves                    |-> [i \in 1 .. 4 |-> 0],
      tradeDate                 |-> [i \in 1 .. 2 |-> 0],
      expireDate                |-> [i \in 1 .. 2 |-> 0],
      ordStatusTrd              |-> [i \in 1 .. 1 |-> 0],
      ordTypeOptional           |-> [i \in 1 .. 1 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      timeInForce               |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator      |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag           |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator        |-> [i \in 1 .. 1 |-> 0],
      crossType                 |-> [i \in 1 .. 1 |-> 0],
      execInst                  |-> [i \in 1 .. 1 |-> 0],
      executionMode             |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag             |-> [i \in 1 .. 1 |-> 0],
      managedOrder              |-> [i \in 1 .. 1 |-> 0],
      shortSaleType             |-> [i \in 1 .. 1 |-> 0],
      ownership                 |-> [i \in 1 .. 1 |-> 0],
      discretionPrice           |-> [i \in 1 .. 8 |-> 0],
      trdType                   |-> [i \in 1 .. 2 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 1 |-> 0],
      settlDate                 |-> [i \in 1 .. 2 |-> 0],
      maturityDate              |-> [i \in 1 .. 2 |-> 0],
      calculatedCcyLastQty      |-> ZeroCalculatedCcyLastQty,
      grossTradeAmt             |-> ZeroGrossTradeAmt,
      benchmarkPrice            |-> [i \in 1 .. 8 |-> 0],
      fillsGroups               |-> ZeroFillsGroups,
      outrightOrderEventsGroups |-> ZeroOutrightOrderEventsGroups ]

(* Execution Report Trade Outright at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeOutright ==
    { ZeroExecutionReportTradeOutright }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.mdTradeEntryId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.tradeLinkId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.leaves = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.ordStatusTrd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.ownership = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.discretionPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.settlDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.calculatedCcyLastQty = one] : one \in CheckedCalculatedCcyLastQty }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.grossTradeAmt = one] : one \in CheckedGrossTradeAmt }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.benchmarkPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.fillsGroups = one] : one \in CheckedFillsGroups }
        \cup { [ZeroExecutionReportTradeOutright EXCEPT !.outrightOrderEventsGroups = one] : one \in CheckedOutrightOrderEventsGroups }

(***************************************************************************)
(* Fills Group: 15 bytes                                                   *)
(***************************************************************************)

FillsGroup2 ==
    [ fillPx        : Sample(8),
      fillQty       : Sample(4),
      fillExecId    : Sample(2),
      fillYieldType : Sample(1) ]

EncodeFillsGroup2(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillExecId
        \o message.fillYieldType

DecodeFillsGroup2(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillQty.rest, 2) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillYieldType == ReadBytes(fillExecId.rest, 1) IN IF ~fillYieldType.ok THEN Fail ELSE
    Ok([ fillPx        |-> fillPx.value,
         fillQty       |-> fillQty.value,
         fillExecId    |-> fillExecId.value,
         fillYieldType |-> fillYieldType.value ], fillYieldType.rest)

ZeroFillsGroup2 ==
    [ fillPx        |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      fillExecId    |-> [i \in 1 .. 2 |-> 0],
      fillYieldType |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroup2 ==
    { ZeroFillsGroup2 }
        \cup { [ZeroFillsGroup2 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGroup2 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGroup2 EXCEPT !.fillExecId = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroup2 EXCEPT !.fillYieldType = one] : one \in Sample(1) }

(* A run of Fills Group, written one after another *)
RECURSIVE EncodeFillsGroup2List(_)
EncodeFillsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGroup2(Head(messages)) \o EncodeFillsGroup2List(Tail(messages))

(* As many Fills Group as the field that counts them says *)
RECURSIVE ReadFillsGroup2List(_, _)
ReadFillsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Group of each kind, for the lists that carry them *)
OneFillsGroup2 == { ZeroFillsGroup2 }

(***************************************************************************)
(* Fills Groups                                                            *)
(***************************************************************************)

FillsGroups2 ==
    [ blockLength : Sample(2),
      fillsGroup  : SampleLists(OneFillsGroup2) ]

EncodeFillsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.fillsGroup), 1)
        \o EncodeFillsGroup2List(message.fillsGroup)

DecodeFillsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillsGroup == ReadFillsGroup2List(numInGroup.rest, numInGroup.value) IN IF ~fillsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         fillsGroup  |-> fillsGroup.value ], fillsGroup.rest)

ZeroFillsGroups2 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      fillsGroup  |-> << >> ]

(* Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroups2 ==
    { ZeroFillsGroups2 }
        \cup { [ZeroFillsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroups2 EXCEPT !.fillsGroup = one] : one \in SampleLists(OneFillsGroup2) }

(***************************************************************************)
(* Trade Legs Group: 29 bytes                                              *)
(***************************************************************************)

TradeLegsGroup ==
    [ legExecId     : Sample(8),
      legLastPx     : Sample(8),
      legSecurityId : Sample(4),
      legTradeId    : Sample(4),
      legLastQty    : Sample(4),
      legSide       : Sample(1) ]

EncodeTradeLegsGroup(message) ==
    message.legExecId
        \o message.legLastPx
        \o message.legSecurityId
        \o message.legTradeId
        \o message.legLastQty
        \o message.legSide

DecodeTradeLegsGroup(bytes) ==
    LET legExecId == ReadBytes(bytes, 8) IN IF ~legExecId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legExecId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legLastPx.rest, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legTradeId == ReadBytes(legSecurityId.rest, 4) IN IF ~legTradeId.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legTradeId.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legLastQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legExecId     |-> legExecId.value,
         legLastPx     |-> legLastPx.value,
         legSecurityId |-> legSecurityId.value,
         legTradeId    |-> legTradeId.value,
         legLastQty    |-> legLastQty.value,
         legSide       |-> legSide.value ], legSide.rest)

ZeroTradeLegsGroup ==
    [ legExecId     |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legSecurityId |-> [i \in 1 .. 4 |-> 0],
      legTradeId    |-> [i \in 1 .. 4 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeLegsGroup ==
    { ZeroTradeLegsGroup }
        \cup { [ZeroTradeLegsGroup EXCEPT !.legExecId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLegsGroup EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroTradeLegsGroup EXCEPT !.legTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeLegsGroup EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Trade Legs Group, written one after another *)
RECURSIVE EncodeTradeLegsGroupList(_)
EncodeTradeLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeLegsGroup(Head(messages)) \o EncodeTradeLegsGroupList(Tail(messages))

(* As many Trade Legs Group as the field that counts them says *)
RECURSIVE ReadTradeLegsGroupList(_, _)
ReadTradeLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Legs Group of each kind, for the lists that carry them *)
OneTradeLegsGroup == { ZeroTradeLegsGroup }

(***************************************************************************)
(* Trade Legs Groups                                                       *)
(***************************************************************************)

TradeLegsGroups ==
    [ blockLength    : Sample(2),
      tradeLegsGroup : SampleLists(OneTradeLegsGroup) ]

EncodeTradeLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeLegsGroup), 1)
        \o EncodeTradeLegsGroupList(message.tradeLegsGroup)

DecodeTradeLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET tradeLegsGroup == ReadTradeLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~tradeLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         tradeLegsGroup |-> tradeLegsGroup.value ], tradeLegsGroup.rest)

ZeroTradeLegsGroups ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      tradeLegsGroup |-> << >> ]

(* Trade Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeLegsGroups ==
    { ZeroTradeLegsGroups }
        \cup { [ZeroTradeLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeLegsGroups EXCEPT !.tradeLegsGroup = one] : one \in SampleLists(OneTradeLegsGroup) }

(***************************************************************************)
(* Spread Order Events Group: 23 bytes                                     *)
(***************************************************************************)

SpreadOrderEventsGroup ==
    [ orderEventPx     : Sample(8),
      orderEventText   : Sample(5),
      orderEventExecId : Sample(4),
      orderEventQty    : Sample(4),
      orderEventType   : Sample(1),
      orderEventReason : Sample(1) ]

EncodeSpreadOrderEventsGroup(message) ==
    message.orderEventPx
        \o message.orderEventText
        \o message.orderEventExecId
        \o message.orderEventQty
        \o message.orderEventType
        \o message.orderEventReason

DecodeSpreadOrderEventsGroup(bytes) ==
    LET orderEventPx == ReadBytes(bytes, 8) IN IF ~orderEventPx.ok THEN Fail ELSE
    LET orderEventText == ReadBytes(orderEventPx.rest, 5) IN IF ~orderEventText.ok THEN Fail ELSE
    LET orderEventExecId == ReadBytes(orderEventText.rest, 4) IN IF ~orderEventExecId.ok THEN Fail ELSE
    LET orderEventQty == ReadBytes(orderEventExecId.rest, 4) IN IF ~orderEventQty.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(orderEventQty.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET orderEventReason == ReadBytes(orderEventType.rest, 1) IN IF ~orderEventReason.ok THEN Fail ELSE
    Ok([ orderEventPx     |-> orderEventPx.value,
         orderEventText   |-> orderEventText.value,
         orderEventExecId |-> orderEventExecId.value,
         orderEventQty    |-> orderEventQty.value,
         orderEventType   |-> orderEventType.value,
         orderEventReason |-> orderEventReason.value ], orderEventReason.rest)

ZeroSpreadOrderEventsGroup ==
    [ orderEventPx     |-> [i \in 1 .. 8 |-> 0],
      orderEventText   |-> [i \in 1 .. 5 |-> 0],
      orderEventExecId |-> [i \in 1 .. 4 |-> 0],
      orderEventQty    |-> [i \in 1 .. 4 |-> 0],
      orderEventType   |-> [i \in 1 .. 1 |-> 0],
      orderEventReason |-> [i \in 1 .. 1 |-> 0] ]

(* Spread Order Events Group at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderEventsGroup ==
    { ZeroSpreadOrderEventsGroup }
        \cup { [ZeroSpreadOrderEventsGroup EXCEPT !.orderEventPx = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderEventsGroup EXCEPT !.orderEventText = one] : one \in Sample(5) }
        \cup { [ZeroSpreadOrderEventsGroup EXCEPT !.orderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderEventsGroup EXCEPT !.orderEventQty = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderEventsGroup EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderEventsGroup EXCEPT !.orderEventReason = one] : one \in Sample(1) }

(* A run of Spread Order Events Group, written one after another *)
RECURSIVE EncodeSpreadOrderEventsGroupList(_)
EncodeSpreadOrderEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSpreadOrderEventsGroup(Head(messages)) \o EncodeSpreadOrderEventsGroupList(Tail(messages))

(* As many Spread Order Events Group as the field that counts them says *)
RECURSIVE ReadSpreadOrderEventsGroupList(_, _)
ReadSpreadOrderEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSpreadOrderEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSpreadOrderEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Spread Order Events Group of each kind, for the lists that carry them *)
OneSpreadOrderEventsGroup == { ZeroSpreadOrderEventsGroup }

(***************************************************************************)
(* Spread Order Events Groups                                              *)
(***************************************************************************)

SpreadOrderEventsGroups ==
    [ blockLength            : Sample(2),
      spreadOrderEventsGroup : SampleLists(OneSpreadOrderEventsGroup) ]

EncodeSpreadOrderEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.spreadOrderEventsGroup), 1)
        \o EncodeSpreadOrderEventsGroupList(message.spreadOrderEventsGroup)

DecodeSpreadOrderEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET spreadOrderEventsGroup == ReadSpreadOrderEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~spreadOrderEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         spreadOrderEventsGroup |-> spreadOrderEventsGroup.value ], spreadOrderEventsGroup.rest)

ZeroSpreadOrderEventsGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      spreadOrderEventsGroup |-> << >> ]

(* Spread Order Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderEventsGroups ==
    { ZeroSpreadOrderEventsGroups }
        \cup { [ZeroSpreadOrderEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderEventsGroups EXCEPT !.spreadOrderEventsGroup = one] : one \in SampleLists(OneSpreadOrderEventsGroup) }

(***************************************************************************)
(* Execution Report Trade Spread                                           *)
(***************************************************************************)

ExecutionReportTradeSpread ==
    [ seqNum                  : Sample(4),
      uuid                    : Sample(8),
      execId                  : Sample(40),
      senderId                : Sample(20),
      clordid                 : Sample(20),
      partyDetailsListReqId   : Sample(8),
      lastPx                  : Sample(8),
      orderId                 : Sample(8),
      price                   : Sample(8),
      stopPx                  : Sample(8),
      transactTime            : Sample(8),
      sendingTimeEpoch        : Sample(8),
      orderRequestId          : Sample(8),
      secExecId               : Sample(8),
      crossIdOptional         : Sample(8),
      hostCrossId             : Sample(8),
      location                : Sample(5),
      securityId              : Sample(4),
      orderQty                : Sample(4),
      lastQty                 : Sample(4),
      cumQty                  : Sample(4),
      mdTradeEntryId          : Sample(4),
      sideTradeId             : Sample(4),
      leaves                  : Sample(4),
      tradeDate               : Sample(2),
      expireDate              : Sample(2),
      ordStatusTrd            : Sample(1),
      ordTypeOptional         : Sample(1),
      side                    : Sample(1),
      timeInForce             : Sample(1),
      manualOrderIndicator    : Sample(1),
      possRetransFlag         : Sample(1),
      aggressorIndicator      : Sample(1),
      crossType               : Sample(1),
      totalNumSecurities      : Sample(1),
      execInst                : Sample(1),
      executionMode           : Sample(1),
      liquidityFlag           : Sample(1),
      shortSaleType           : Sample(1),
      fillsGroups             : FillsGroups2,
      tradeLegsGroups         : TradeLegsGroups,
      spreadOrderEventsGroups : SpreadOrderEventsGroups ]

EncodeExecutionReportTradeSpread(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.lastPx
        \o message.orderId
        \o message.price
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.secExecId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.lastQty
        \o message.cumQty
        \o message.mdTradeEntryId
        \o message.sideTradeId
        \o message.leaves
        \o message.tradeDate
        \o message.expireDate
        \o message.ordStatusTrd
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.aggressorIndicator
        \o message.crossType
        \o message.totalNumSecurities
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.shortSaleType
        \o EncodeFillsGroups2(message.fillsGroups)
        \o EncodeTradeLegsGroups(message.tradeLegsGroups)
        \o EncodeSpreadOrderEventsGroups(message.spreadOrderEventsGroups)

DecodeExecutionReportTradeSpread(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET secExecId == ReadBytes(orderRequestId.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(secExecId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET lastQty == ReadBytes(orderQty.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(lastQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET mdTradeEntryId == ReadBytes(cumQty.rest, 4) IN IF ~mdTradeEntryId.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(mdTradeEntryId.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET leaves == ReadBytes(sideTradeId.rest, 4) IN IF ~leaves.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(leaves.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET expireDate == ReadBytes(tradeDate.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordStatusTrd == ReadBytes(expireDate.rest, 1) IN IF ~ordStatusTrd.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(ordStatusTrd.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(possRetransFlag.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET crossType == ReadBytes(aggressorIndicator.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET totalNumSecurities == ReadBytes(crossType.rest, 1) IN IF ~totalNumSecurities.ok THEN Fail ELSE
    LET execInst == ReadBytes(totalNumSecurities.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(liquidityFlag.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET fillsGroups == DecodeFillsGroups2(shortSaleType.rest) IN IF ~fillsGroups.ok THEN Fail ELSE
    LET tradeLegsGroups == DecodeTradeLegsGroups(fillsGroups.rest) IN IF ~tradeLegsGroups.ok THEN Fail ELSE
    LET spreadOrderEventsGroups == DecodeSpreadOrderEventsGroups(tradeLegsGroups.rest) IN IF ~spreadOrderEventsGroups.ok THEN Fail ELSE
    Ok([ seqNum                  |-> seqNum.value,
         uuid                    |-> uuid.value,
         execId                  |-> execId.value,
         senderId                |-> senderId.value,
         clordid                 |-> clordid.value,
         partyDetailsListReqId   |-> partyDetailsListReqId.value,
         lastPx                  |-> lastPx.value,
         orderId                 |-> orderId.value,
         price                   |-> price.value,
         stopPx                  |-> stopPx.value,
         transactTime            |-> transactTime.value,
         sendingTimeEpoch        |-> sendingTimeEpoch.value,
         orderRequestId          |-> orderRequestId.value,
         secExecId               |-> secExecId.value,
         crossIdOptional         |-> crossIdOptional.value,
         hostCrossId             |-> hostCrossId.value,
         location                |-> location.value,
         securityId              |-> securityId.value,
         orderQty                |-> orderQty.value,
         lastQty                 |-> lastQty.value,
         cumQty                  |-> cumQty.value,
         mdTradeEntryId          |-> mdTradeEntryId.value,
         sideTradeId             |-> sideTradeId.value,
         leaves                  |-> leaves.value,
         tradeDate               |-> tradeDate.value,
         expireDate              |-> expireDate.value,
         ordStatusTrd            |-> ordStatusTrd.value,
         ordTypeOptional         |-> ordTypeOptional.value,
         side                    |-> side.value,
         timeInForce             |-> timeInForce.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         possRetransFlag         |-> possRetransFlag.value,
         aggressorIndicator      |-> aggressorIndicator.value,
         crossType               |-> crossType.value,
         totalNumSecurities      |-> totalNumSecurities.value,
         execInst                |-> execInst.value,
         executionMode           |-> executionMode.value,
         liquidityFlag           |-> liquidityFlag.value,
         shortSaleType           |-> shortSaleType.value,
         fillsGroups             |-> fillsGroups.value,
         tradeLegsGroups         |-> tradeLegsGroups.value,
         spreadOrderEventsGroups |-> spreadOrderEventsGroups.value ], spreadOrderEventsGroups.rest)

ZeroExecutionReportTradeSpread ==
    [ seqNum                  |-> [i \in 1 .. 4 |-> 0],
      uuid                    |-> [i \in 1 .. 8 |-> 0],
      execId                  |-> [i \in 1 .. 40 |-> 0],
      senderId                |-> [i \in 1 .. 20 |-> 0],
      clordid                 |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId   |-> [i \in 1 .. 8 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      stopPx                  |-> [i \in 1 .. 8 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch        |-> [i \in 1 .. 8 |-> 0],
      orderRequestId          |-> [i \in 1 .. 8 |-> 0],
      secExecId               |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional         |-> [i \in 1 .. 8 |-> 0],
      hostCrossId             |-> [i \in 1 .. 8 |-> 0],
      location                |-> [i \in 1 .. 5 |-> 0],
      securityId              |-> [i \in 1 .. 4 |-> 0],
      orderQty                |-> [i \in 1 .. 4 |-> 0],
      lastQty                 |-> [i \in 1 .. 4 |-> 0],
      cumQty                  |-> [i \in 1 .. 4 |-> 0],
      mdTradeEntryId          |-> [i \in 1 .. 4 |-> 0],
      sideTradeId             |-> [i \in 1 .. 4 |-> 0],
      leaves                  |-> [i \in 1 .. 4 |-> 0],
      tradeDate               |-> [i \in 1 .. 2 |-> 0],
      expireDate              |-> [i \in 1 .. 2 |-> 0],
      ordStatusTrd            |-> [i \in 1 .. 1 |-> 0],
      ordTypeOptional         |-> [i \in 1 .. 1 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce             |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator    |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag         |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator      |-> [i \in 1 .. 1 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      totalNumSecurities      |-> [i \in 1 .. 1 |-> 0],
      execInst                |-> [i \in 1 .. 1 |-> 0],
      executionMode           |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag           |-> [i \in 1 .. 1 |-> 0],
      shortSaleType           |-> [i \in 1 .. 1 |-> 0],
      fillsGroups             |-> ZeroFillsGroups2,
      tradeLegsGroups         |-> ZeroTradeLegsGroups,
      spreadOrderEventsGroups |-> ZeroSpreadOrderEventsGroups ]

(* Execution Report Trade Spread at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeSpread ==
    { ZeroExecutionReportTradeSpread }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.mdTradeEntryId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.leaves = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.ordStatusTrd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.totalNumSecurities = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.fillsGroups = one] : one \in CheckedFillsGroups2 }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.tradeLegsGroups = one] : one \in CheckedTradeLegsGroups }
        \cup { [ZeroExecutionReportTradeSpread EXCEPT !.spreadOrderEventsGroups = one] : one \in CheckedSpreadOrderEventsGroups }

(***************************************************************************)
(* Volatility: 9 bytes                                                     *)
(***************************************************************************)

Volatility ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeVolatility(message) ==
    message.mantissa
        \o message.exponent

DecodeVolatility(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroVolatility ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Volatility at zero, then each field in turn at the values it is checked at *)
CheckedVolatility ==
    { ZeroVolatility }
        \cup { [ZeroVolatility EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroVolatility EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Delta: 5 bytes                                                   *)
(***************************************************************************)

OptionDelta ==
    [ mantissa32 : Sample(4),
      exponent   : Sample(1) ]

EncodeOptionDelta(message) ==
    message.mantissa32
        \o message.exponent

DecodeOptionDelta(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa32.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa32 |-> mantissa32.value,
         exponent   |-> exponent.value ], exponent.rest)

ZeroOptionDelta ==
    [ mantissa32 |-> [i \in 1 .. 4 |-> 0],
      exponent   |-> [i \in 1 .. 1 |-> 0] ]

(* Option Delta at zero, then each field in turn at the values it is checked at *)
CheckedOptionDelta ==
    { ZeroOptionDelta }
        \cup { [ZeroOptionDelta EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroOptionDelta EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Time To Expiration: 5 bytes                                             *)
(***************************************************************************)

TimeToExpiration ==
    [ mantissa32 : Sample(4),
      exponent   : Sample(1) ]

EncodeTimeToExpiration(message) ==
    message.mantissa32
        \o message.exponent

DecodeTimeToExpiration(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa32.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa32 |-> mantissa32.value,
         exponent   |-> exponent.value ], exponent.rest)

ZeroTimeToExpiration ==
    [ mantissa32 |-> [i \in 1 .. 4 |-> 0],
      exponent   |-> [i \in 1 .. 1 |-> 0] ]

(* Time To Expiration at zero, then each field in turn at the values it is checked at *)
CheckedTimeToExpiration ==
    { ZeroTimeToExpiration }
        \cup { [ZeroTimeToExpiration EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroTimeToExpiration EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Free Rate: 5 bytes                                                 *)
(***************************************************************************)

RiskFreeRate ==
    [ mantissa32 : Sample(4),
      exponent   : Sample(1) ]

EncodeRiskFreeRate(message) ==
    message.mantissa32
        \o message.exponent

DecodeRiskFreeRate(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa32.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa32 |-> mantissa32.value,
         exponent   |-> exponent.value ], exponent.rest)

ZeroRiskFreeRate ==
    [ mantissa32 |-> [i \in 1 .. 4 |-> 0],
      exponent   |-> [i \in 1 .. 1 |-> 0] ]

(* Risk Free Rate at zero, then each field in turn at the values it is checked at *)
CheckedRiskFreeRate ==
    { ZeroRiskFreeRate }
        \cup { [ZeroRiskFreeRate EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroRiskFreeRate EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Calculated Ccy Last Qty: 9 bytes                                        *)
(***************************************************************************)

CalculatedCcyLastQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeCalculatedCcyLastQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeCalculatedCcyLastQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroCalculatedCcyLastQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Calculated Ccy Last Qty at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedCcyLastQty2 ==
    { ZeroCalculatedCcyLastQty2 }
        \cup { [ZeroCalculatedCcyLastQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedCcyLastQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Gross Trade Amt: 9 bytes                                                *)
(***************************************************************************)

GrossTradeAmt2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeGrossTradeAmt2(message) ==
    message.mantissa
        \o message.exponent

DecodeGrossTradeAmt2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroGrossTradeAmt2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Gross Trade Amt at zero, then each field in turn at the values it is checked at *)
CheckedGrossTradeAmt2 ==
    { ZeroGrossTradeAmt2 }
        \cup { [ZeroGrossTradeAmt2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroGrossTradeAmt2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Group: 15 bytes                                                   *)
(***************************************************************************)

FillsGroup3 ==
    [ fillPx        : Sample(8),
      fillQty       : Sample(4),
      fillExecId    : Sample(2),
      fillYieldType : Sample(1) ]

EncodeFillsGroup3(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillExecId
        \o message.fillYieldType

DecodeFillsGroup3(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillQty.rest, 2) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillYieldType == ReadBytes(fillExecId.rest, 1) IN IF ~fillYieldType.ok THEN Fail ELSE
    Ok([ fillPx        |-> fillPx.value,
         fillQty       |-> fillQty.value,
         fillExecId    |-> fillExecId.value,
         fillYieldType |-> fillYieldType.value ], fillYieldType.rest)

ZeroFillsGroup3 ==
    [ fillPx        |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      fillExecId    |-> [i \in 1 .. 2 |-> 0],
      fillYieldType |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroup3 ==
    { ZeroFillsGroup3 }
        \cup { [ZeroFillsGroup3 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGroup3 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGroup3 EXCEPT !.fillExecId = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroup3 EXCEPT !.fillYieldType = one] : one \in Sample(1) }

(* A run of Fills Group, written one after another *)
RECURSIVE EncodeFillsGroup3List(_)
EncodeFillsGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGroup3(Head(messages)) \o EncodeFillsGroup3List(Tail(messages))

(* As many Fills Group as the field that counts them says *)
RECURSIVE ReadFillsGroup3List(_, _)
ReadFillsGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Group of each kind, for the lists that carry them *)
OneFillsGroup3 == { ZeroFillsGroup3 }

(***************************************************************************)
(* Fills Groups                                                            *)
(***************************************************************************)

FillsGroups3 ==
    [ blockLength : Sample(2),
      fillsGroup  : SampleLists(OneFillsGroup3) ]

EncodeFillsGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.fillsGroup), 1)
        \o EncodeFillsGroup3List(message.fillsGroup)

DecodeFillsGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillsGroup == ReadFillsGroup3List(numInGroup.rest, numInGroup.value) IN IF ~fillsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         fillsGroup  |-> fillsGroup.value ], fillsGroup.rest)

ZeroFillsGroups3 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      fillsGroup  |-> << >> ]

(* Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroups3 ==
    { ZeroFillsGroups3 }
        \cup { [ZeroFillsGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroups3 EXCEPT !.fillsGroup = one] : one \in SampleLists(OneFillsGroup3) }

(***************************************************************************)
(* Spread Leg Order Events Group: 23 bytes                                 *)
(***************************************************************************)

SpreadLegOrderEventsGroup ==
    [ orderEventPx     : Sample(8),
      orderEventText   : Sample(5),
      orderEventExecId : Sample(4),
      orderEventQty    : Sample(4),
      orderEventType   : Sample(1),
      orderEventReason : Sample(1) ]

EncodeSpreadLegOrderEventsGroup(message) ==
    message.orderEventPx
        \o message.orderEventText
        \o message.orderEventExecId
        \o message.orderEventQty
        \o message.orderEventType
        \o message.orderEventReason

DecodeSpreadLegOrderEventsGroup(bytes) ==
    LET orderEventPx == ReadBytes(bytes, 8) IN IF ~orderEventPx.ok THEN Fail ELSE
    LET orderEventText == ReadBytes(orderEventPx.rest, 5) IN IF ~orderEventText.ok THEN Fail ELSE
    LET orderEventExecId == ReadBytes(orderEventText.rest, 4) IN IF ~orderEventExecId.ok THEN Fail ELSE
    LET orderEventQty == ReadBytes(orderEventExecId.rest, 4) IN IF ~orderEventQty.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(orderEventQty.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET orderEventReason == ReadBytes(orderEventType.rest, 1) IN IF ~orderEventReason.ok THEN Fail ELSE
    Ok([ orderEventPx     |-> orderEventPx.value,
         orderEventText   |-> orderEventText.value,
         orderEventExecId |-> orderEventExecId.value,
         orderEventQty    |-> orderEventQty.value,
         orderEventType   |-> orderEventType.value,
         orderEventReason |-> orderEventReason.value ], orderEventReason.rest)

ZeroSpreadLegOrderEventsGroup ==
    [ orderEventPx     |-> [i \in 1 .. 8 |-> 0],
      orderEventText   |-> [i \in 1 .. 5 |-> 0],
      orderEventExecId |-> [i \in 1 .. 4 |-> 0],
      orderEventQty    |-> [i \in 1 .. 4 |-> 0],
      orderEventType   |-> [i \in 1 .. 1 |-> 0],
      orderEventReason |-> [i \in 1 .. 1 |-> 0] ]

(* Spread Leg Order Events Group at zero, then each field in turn at the values it is checked at *)
CheckedSpreadLegOrderEventsGroup ==
    { ZeroSpreadLegOrderEventsGroup }
        \cup { [ZeroSpreadLegOrderEventsGroup EXCEPT !.orderEventPx = one] : one \in Sample(8) }
        \cup { [ZeroSpreadLegOrderEventsGroup EXCEPT !.orderEventText = one] : one \in Sample(5) }
        \cup { [ZeroSpreadLegOrderEventsGroup EXCEPT !.orderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadLegOrderEventsGroup EXCEPT !.orderEventQty = one] : one \in Sample(4) }
        \cup { [ZeroSpreadLegOrderEventsGroup EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroSpreadLegOrderEventsGroup EXCEPT !.orderEventReason = one] : one \in Sample(1) }

(* A run of Spread Leg Order Events Group, written one after another *)
RECURSIVE EncodeSpreadLegOrderEventsGroupList(_)
EncodeSpreadLegOrderEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSpreadLegOrderEventsGroup(Head(messages)) \o EncodeSpreadLegOrderEventsGroupList(Tail(messages))

(* As many Spread Leg Order Events Group as the field that counts them says *)
RECURSIVE ReadSpreadLegOrderEventsGroupList(_, _)
ReadSpreadLegOrderEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSpreadLegOrderEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSpreadLegOrderEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Spread Leg Order Events Group of each kind, for the lists that carry them *)
OneSpreadLegOrderEventsGroup == { ZeroSpreadLegOrderEventsGroup }

(***************************************************************************)
(* Spread Leg Order Events Groups                                          *)
(***************************************************************************)

SpreadLegOrderEventsGroups ==
    [ blockLength               : Sample(2),
      spreadLegOrderEventsGroup : SampleLists(OneSpreadLegOrderEventsGroup) ]

EncodeSpreadLegOrderEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.spreadLegOrderEventsGroup), 1)
        \o EncodeSpreadLegOrderEventsGroupList(message.spreadLegOrderEventsGroup)

DecodeSpreadLegOrderEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET spreadLegOrderEventsGroup == ReadSpreadLegOrderEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~spreadLegOrderEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength               |-> blockLength.value,
         spreadLegOrderEventsGroup |-> spreadLegOrderEventsGroup.value ], spreadLegOrderEventsGroup.rest)

ZeroSpreadLegOrderEventsGroups ==
    [ blockLength               |-> [i \in 1 .. 2 |-> 0],
      spreadLegOrderEventsGroup |-> << >> ]

(* Spread Leg Order Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedSpreadLegOrderEventsGroups ==
    { ZeroSpreadLegOrderEventsGroups }
        \cup { [ZeroSpreadLegOrderEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSpreadLegOrderEventsGroups EXCEPT !.spreadLegOrderEventsGroup = one] : one \in SampleLists(OneSpreadLegOrderEventsGroup) }

(***************************************************************************)
(* Execution Report Trade Spread Leg                                       *)
(***************************************************************************)

ExecutionReportTradeSpreadLeg ==
    [ seqNum                     : Sample(4),
      uuid                       : Sample(8),
      execId                     : Sample(40),
      senderId                   : Sample(20),
      clordid                    : Sample(20),
      volatility                 : Volatility,
      partyDetailsListReqId      : Sample(8),
      lastPx                     : Sample(8),
      orderId                    : Sample(8),
      underlyingPx               : Sample(8),
      transactTime               : Sample(8),
      sendingTimeEpoch           : Sample(8),
      secExecId                  : Sample(8),
      location                   : Sample(5),
      optionDelta                : OptionDelta,
      timeToExpiration           : TimeToExpiration,
      riskFreeRate               : RiskFreeRate,
      securityId                 : Sample(4),
      lastQty                    : Sample(4),
      cumQty                     : Sample(4),
      sideTradeId                : Sample(4),
      tradeDate                  : Sample(2),
      ordStatusTrd               : Sample(1),
      ordTypeOptional            : Sample(1),
      side                       : Sample(1),
      possRetransFlag            : Sample(1),
      settlDate                  : Sample(2),
      calculatedCcyLastQty       : CalculatedCcyLastQty2,
      grossTradeAmt              : GrossTradeAmt2,
      fillsGroups                : FillsGroups3,
      spreadLegOrderEventsGroups : SpreadLegOrderEventsGroups ]

EncodeExecutionReportTradeSpreadLeg(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o EncodeVolatility(message.volatility)
        \o message.partyDetailsListReqId
        \o message.lastPx
        \o message.orderId
        \o message.underlyingPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.secExecId
        \o message.location
        \o EncodeOptionDelta(message.optionDelta)
        \o EncodeTimeToExpiration(message.timeToExpiration)
        \o EncodeRiskFreeRate(message.riskFreeRate)
        \o message.securityId
        \o message.lastQty
        \o message.cumQty
        \o message.sideTradeId
        \o message.tradeDate
        \o message.ordStatusTrd
        \o message.ordTypeOptional
        \o message.side
        \o message.possRetransFlag
        \o message.settlDate
        \o EncodeCalculatedCcyLastQty2(message.calculatedCcyLastQty)
        \o EncodeGrossTradeAmt2(message.grossTradeAmt)
        \o EncodeFillsGroups3(message.fillsGroups)
        \o EncodeSpreadLegOrderEventsGroups(message.spreadLegOrderEventsGroups)

DecodeExecutionReportTradeSpreadLeg(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET volatility == DecodeVolatility(clordid.rest) IN IF ~volatility.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(volatility.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(orderId.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(underlyingPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET secExecId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET location == ReadBytes(secExecId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET optionDelta == DecodeOptionDelta(location.rest) IN IF ~optionDelta.ok THEN Fail ELSE
    LET timeToExpiration == DecodeTimeToExpiration(optionDelta.rest) IN IF ~timeToExpiration.ok THEN Fail ELSE
    LET riskFreeRate == DecodeRiskFreeRate(timeToExpiration.rest) IN IF ~riskFreeRate.ok THEN Fail ELSE
    LET securityId == ReadBytes(riskFreeRate.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(lastQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(cumQty.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(sideTradeId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET ordStatusTrd == ReadBytes(tradeDate.rest, 1) IN IF ~ordStatusTrd.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(ordStatusTrd.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(side.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET settlDate == ReadBytes(possRetransFlag.rest, 2) IN IF ~settlDate.ok THEN Fail ELSE
    LET calculatedCcyLastQty == DecodeCalculatedCcyLastQty2(settlDate.rest) IN IF ~calculatedCcyLastQty.ok THEN Fail ELSE
    LET grossTradeAmt == DecodeGrossTradeAmt2(calculatedCcyLastQty.rest) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET fillsGroups == DecodeFillsGroups3(grossTradeAmt.rest) IN IF ~fillsGroups.ok THEN Fail ELSE
    LET spreadLegOrderEventsGroups == DecodeSpreadLegOrderEventsGroups(fillsGroups.rest) IN IF ~spreadLegOrderEventsGroups.ok THEN Fail ELSE
    Ok([ seqNum                     |-> seqNum.value,
         uuid                       |-> uuid.value,
         execId                     |-> execId.value,
         senderId                   |-> senderId.value,
         clordid                    |-> clordid.value,
         volatility                 |-> volatility.value,
         partyDetailsListReqId      |-> partyDetailsListReqId.value,
         lastPx                     |-> lastPx.value,
         orderId                    |-> orderId.value,
         underlyingPx               |-> underlyingPx.value,
         transactTime               |-> transactTime.value,
         sendingTimeEpoch           |-> sendingTimeEpoch.value,
         secExecId                  |-> secExecId.value,
         location                   |-> location.value,
         optionDelta                |-> optionDelta.value,
         timeToExpiration           |-> timeToExpiration.value,
         riskFreeRate               |-> riskFreeRate.value,
         securityId                 |-> securityId.value,
         lastQty                    |-> lastQty.value,
         cumQty                     |-> cumQty.value,
         sideTradeId                |-> sideTradeId.value,
         tradeDate                  |-> tradeDate.value,
         ordStatusTrd               |-> ordStatusTrd.value,
         ordTypeOptional            |-> ordTypeOptional.value,
         side                       |-> side.value,
         possRetransFlag            |-> possRetransFlag.value,
         settlDate                  |-> settlDate.value,
         calculatedCcyLastQty       |-> calculatedCcyLastQty.value,
         grossTradeAmt              |-> grossTradeAmt.value,
         fillsGroups                |-> fillsGroups.value,
         spreadLegOrderEventsGroups |-> spreadLegOrderEventsGroups.value ], spreadLegOrderEventsGroups.rest)

ZeroExecutionReportTradeSpreadLeg ==
    [ seqNum                     |-> [i \in 1 .. 4 |-> 0],
      uuid                       |-> [i \in 1 .. 8 |-> 0],
      execId                     |-> [i \in 1 .. 40 |-> 0],
      senderId                   |-> [i \in 1 .. 20 |-> 0],
      clordid                    |-> [i \in 1 .. 20 |-> 0],
      volatility                 |-> ZeroVolatility,
      partyDetailsListReqId      |-> [i \in 1 .. 8 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      orderId                    |-> [i \in 1 .. 8 |-> 0],
      underlyingPx               |-> [i \in 1 .. 8 |-> 0],
      transactTime               |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch           |-> [i \in 1 .. 8 |-> 0],
      secExecId                  |-> [i \in 1 .. 8 |-> 0],
      location                   |-> [i \in 1 .. 5 |-> 0],
      optionDelta                |-> ZeroOptionDelta,
      timeToExpiration           |-> ZeroTimeToExpiration,
      riskFreeRate               |-> ZeroRiskFreeRate,
      securityId                 |-> [i \in 1 .. 4 |-> 0],
      lastQty                    |-> [i \in 1 .. 4 |-> 0],
      cumQty                     |-> [i \in 1 .. 4 |-> 0],
      sideTradeId                |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      ordStatusTrd               |-> [i \in 1 .. 1 |-> 0],
      ordTypeOptional            |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag            |-> [i \in 1 .. 1 |-> 0],
      settlDate                  |-> [i \in 1 .. 2 |-> 0],
      calculatedCcyLastQty       |-> ZeroCalculatedCcyLastQty2,
      grossTradeAmt              |-> ZeroGrossTradeAmt2,
      fillsGroups                |-> ZeroFillsGroups3,
      spreadLegOrderEventsGroups |-> ZeroSpreadLegOrderEventsGroups ]

(* Execution Report Trade Spread Leg at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeSpreadLeg ==
    { ZeroExecutionReportTradeSpreadLeg }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.volatility = one] : one \in CheckedVolatility }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.optionDelta = one] : one \in CheckedOptionDelta }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.timeToExpiration = one] : one \in CheckedTimeToExpiration }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.riskFreeRate = one] : one \in CheckedRiskFreeRate }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.ordStatusTrd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.settlDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.calculatedCcyLastQty = one] : one \in CheckedCalculatedCcyLastQty2 }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.grossTradeAmt = one] : one \in CheckedGrossTradeAmt2 }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.fillsGroups = one] : one \in CheckedFillsGroups3 }
        \cup { [ZeroExecutionReportTradeSpreadLeg EXCEPT !.spreadLegOrderEventsGroups = one] : one \in CheckedSpreadLegOrderEventsGroups }

(***************************************************************************)
(* Execution Report Modify: 225 bytes                                      *)
(***************************************************************************)

ExecutionReportModify ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      stopPx                : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      crossIdOptional       : Sample(8),
      hostCrossId           : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      orderQty              : Sample(4),
      cumQty                : Sample(4),
      leaves                : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      delayDuration         : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      crossType             : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      delayToTime           : Sample(8),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportModify(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.price
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.cumQty
        \o message.leaves
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.delayDuration
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.delayToTime
        \o message.discretionPrice

DecodeExecutionReportModify(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(orderRequestId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leaves == ReadBytes(cumQty.rest, 4) IN IF ~leaves.ok THEN Fail ELSE
    LET minQty == ReadBytes(leaves.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(expireDate.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(delayDuration.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET crossType == ReadBytes(splitMsg.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(shortSaleType.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(delayToTime.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         stopPx                |-> stopPx.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         crossIdOptional       |-> crossIdOptional.value,
         hostCrossId           |-> hostCrossId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         orderQty              |-> orderQty.value,
         cumQty                |-> cumQty.value,
         leaves                |-> leaves.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         delayDuration         |-> delayDuration.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         crossType             |-> crossType.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         delayToTime           |-> delayToTime.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportModify ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional       |-> [i \in 1 .. 8 |-> 0],
      hostCrossId           |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      leaves                |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      crossType             |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Modify at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportModify ==
    { ZeroExecutionReportModify }
        \cup { [ZeroExecutionReportModify EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportModify EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportModify EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportModify EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportModify EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.leaves = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModify EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportModify EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportModify EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModify EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModify EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Status: 488 bytes                                      *)
(***************************************************************************)

ExecutionReportStatus ==
    [ seqNum                  : Sample(4),
      uuid                    : Sample(8),
      text                    : Sample(256),
      execId                  : Sample(40),
      senderId                : Sample(20),
      clordid                 : Sample(20),
      partyDetailsListReqId   : Sample(8),
      orderId                 : Sample(8),
      priceOptional           : Sample(8),
      stopPx                  : Sample(8),
      transactTime            : Sample(8),
      sendingTimeEpoch        : Sample(8),
      orderRequestId          : Sample(8),
      ordStatusReqIdOptional  : Sample(8),
      massStatusReqIdOptional : Sample(8),
      crossIdOptional         : Sample(8),
      hostCrossId             : Sample(8),
      location                : Sample(5),
      securityId              : Sample(4),
      orderQty                : Sample(4),
      cumQty                  : Sample(4),
      leaves                  : Sample(4),
      minQty                  : Sample(4),
      displayQty              : Sample(4),
      expireDate              : Sample(2),
      ordStatus               : Sample(1),
      ordTypeOptional         : Sample(1),
      side                    : Sample(1),
      timeInForce             : Sample(1),
      manualOrderIndicator    : Sample(1),
      possRetransFlag         : Sample(1),
      lastRptRequested        : Sample(1),
      crossType               : Sample(1),
      execInst                : Sample(1),
      executionMode           : Sample(1),
      liquidityFlag           : Sample(1),
      managedOrder            : Sample(1),
      shortSaleType           : Sample(1),
      discretionPrice         : Sample(8) ]

EncodeExecutionReportStatus(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.priceOptional
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.ordStatusReqIdOptional
        \o message.massStatusReqIdOptional
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.cumQty
        \o message.leaves
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.ordStatus
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.lastRptRequested
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.discretionPrice

DecodeExecutionReportStatus(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET execId == ReadBytes(text.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderId.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET ordStatusReqIdOptional == ReadBytes(orderRequestId.rest, 8) IN IF ~ordStatusReqIdOptional.ok THEN Fail ELSE
    LET massStatusReqIdOptional == ReadBytes(ordStatusReqIdOptional.rest, 8) IN IF ~massStatusReqIdOptional.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(massStatusReqIdOptional.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leaves == ReadBytes(cumQty.rest, 4) IN IF ~leaves.ok THEN Fail ELSE
    LET minQty == ReadBytes(leaves.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(expireDate.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(ordStatus.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET lastRptRequested == ReadBytes(possRetransFlag.rest, 1) IN IF ~lastRptRequested.ok THEN Fail ELSE
    LET crossType == ReadBytes(lastRptRequested.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(shortSaleType.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                  |-> seqNum.value,
         uuid                    |-> uuid.value,
         text                    |-> text.value,
         execId                  |-> execId.value,
         senderId                |-> senderId.value,
         clordid                 |-> clordid.value,
         partyDetailsListReqId   |-> partyDetailsListReqId.value,
         orderId                 |-> orderId.value,
         priceOptional           |-> priceOptional.value,
         stopPx                  |-> stopPx.value,
         transactTime            |-> transactTime.value,
         sendingTimeEpoch        |-> sendingTimeEpoch.value,
         orderRequestId          |-> orderRequestId.value,
         ordStatusReqIdOptional  |-> ordStatusReqIdOptional.value,
         massStatusReqIdOptional |-> massStatusReqIdOptional.value,
         crossIdOptional         |-> crossIdOptional.value,
         hostCrossId             |-> hostCrossId.value,
         location                |-> location.value,
         securityId              |-> securityId.value,
         orderQty                |-> orderQty.value,
         cumQty                  |-> cumQty.value,
         leaves                  |-> leaves.value,
         minQty                  |-> minQty.value,
         displayQty              |-> displayQty.value,
         expireDate              |-> expireDate.value,
         ordStatus               |-> ordStatus.value,
         ordTypeOptional         |-> ordTypeOptional.value,
         side                    |-> side.value,
         timeInForce             |-> timeInForce.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         possRetransFlag         |-> possRetransFlag.value,
         lastRptRequested        |-> lastRptRequested.value,
         crossType               |-> crossType.value,
         execInst                |-> execInst.value,
         executionMode           |-> executionMode.value,
         liquidityFlag           |-> liquidityFlag.value,
         managedOrder            |-> managedOrder.value,
         shortSaleType           |-> shortSaleType.value,
         discretionPrice         |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportStatus ==
    [ seqNum                  |-> [i \in 1 .. 4 |-> 0],
      uuid                    |-> [i \in 1 .. 8 |-> 0],
      text                    |-> [i \in 1 .. 256 |-> 0],
      execId                  |-> [i \in 1 .. 40 |-> 0],
      senderId                |-> [i \in 1 .. 20 |-> 0],
      clordid                 |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId   |-> [i \in 1 .. 8 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      priceOptional           |-> [i \in 1 .. 8 |-> 0],
      stopPx                  |-> [i \in 1 .. 8 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch        |-> [i \in 1 .. 8 |-> 0],
      orderRequestId          |-> [i \in 1 .. 8 |-> 0],
      ordStatusReqIdOptional  |-> [i \in 1 .. 8 |-> 0],
      massStatusReqIdOptional |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional         |-> [i \in 1 .. 8 |-> 0],
      hostCrossId             |-> [i \in 1 .. 8 |-> 0],
      location                |-> [i \in 1 .. 5 |-> 0],
      securityId              |-> [i \in 1 .. 4 |-> 0],
      orderQty                |-> [i \in 1 .. 4 |-> 0],
      cumQty                  |-> [i \in 1 .. 4 |-> 0],
      leaves                  |-> [i \in 1 .. 4 |-> 0],
      minQty                  |-> [i \in 1 .. 4 |-> 0],
      displayQty              |-> [i \in 1 .. 4 |-> 0],
      expireDate              |-> [i \in 1 .. 2 |-> 0],
      ordStatus               |-> [i \in 1 .. 1 |-> 0],
      ordTypeOptional         |-> [i \in 1 .. 1 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce             |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator    |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag         |-> [i \in 1 .. 1 |-> 0],
      lastRptRequested        |-> [i \in 1 .. 1 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      execInst                |-> [i \in 1 .. 1 |-> 0],
      executionMode           |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag           |-> [i \in 1 .. 1 |-> 0],
      managedOrder            |-> [i \in 1 .. 1 |-> 0],
      shortSaleType           |-> [i \in 1 .. 1 |-> 0],
      discretionPrice         |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Status at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportStatus ==
    { ZeroExecutionReportStatus }
        \cup { [ZeroExecutionReportStatus EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.ordStatusReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.massStatusReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.leaves = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.lastRptRequested = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportStatus EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Cancel: 222 bytes                                      *)
(***************************************************************************)

ExecutionReportCancel ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      stopPx                : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      crossIdOptional       : Sample(8),
      hostCrossId           : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      orderQty              : Sample(4),
      cumQty                : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      delayDuration         : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      execRestatementReason : Sample(1),
      crossType             : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      delayToTime           : Sample(8),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportCancel(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.price
        \o message.stopPx
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.crossIdOptional
        \o message.hostCrossId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.cumQty
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.delayDuration
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.execRestatementReason
        \o message.crossType
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.delayToTime
        \o message.discretionPrice

DecodeExecutionReportCancel(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(stopPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET crossIdOptional == ReadBytes(orderRequestId.rest, 8) IN IF ~crossIdOptional.ok THEN Fail ELSE
    LET hostCrossId == ReadBytes(crossIdOptional.rest, 8) IN IF ~hostCrossId.ok THEN Fail ELSE
    LET location == ReadBytes(hostCrossId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(cumQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(expireDate.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(delayDuration.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(splitMsg.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossType == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET execInst == ReadBytes(crossType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(shortSaleType.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(delayToTime.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         stopPx                |-> stopPx.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         crossIdOptional       |-> crossIdOptional.value,
         hostCrossId           |-> hostCrossId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         orderQty              |-> orderQty.value,
         cumQty                |-> cumQty.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         delayDuration         |-> delayDuration.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         execRestatementReason |-> execRestatementReason.value,
         crossType             |-> crossType.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         delayToTime           |-> delayToTime.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportCancel ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      crossIdOptional       |-> [i \in 1 .. 8 |-> 0],
      hostCrossId           |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 1 |-> 0],
      crossType             |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Cancel at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportCancel ==
    { ZeroExecutionReportCancel }
        \cup { [ZeroExecutionReportCancel EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.crossIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.hostCrossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancel EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Reject: 409 bytes                                          *)
(***************************************************************************)

OrderCancelReject ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      text                  : Sample(256),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      location              : Sample(5),
      cxlRejReason          : Sample(2),
      delayDuration         : Sample(2),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      liquidityFlag         : Sample(1),
      delayToTime           : Sample(8) ]

EncodeOrderCancelReject(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.location
        \o message.cxlRejReason
        \o message.delayDuration
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.liquidityFlag
        \o message.delayToTime

DecodeOrderCancelReject(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET execId == ReadBytes(text.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET location == ReadBytes(orderRequestId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET cxlRejReason == ReadBytes(location.rest, 2) IN IF ~cxlRejReason.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(cxlRejReason.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(delayDuration.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(splitMsg.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(liquidityFlag.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         text                  |-> text.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         location              |-> location.value,
         cxlRejReason          |-> cxlRejReason.value,
         delayDuration         |-> delayDuration.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         liquidityFlag         |-> liquidityFlag.value,
         delayToTime           |-> delayToTime.value ], delayToTime.rest)

ZeroOrderCancelReject ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      text                  |-> [i \in 1 .. 256 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      cxlRejReason          |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Reject at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReject ==
    { ZeroOrderCancelReject }
        \cup { [ZeroOrderCancelReject EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReject EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroOrderCancelReject EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroOrderCancelReject EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReject EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReject EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReject EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReject EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReject EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReject EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReject EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelReject EXCEPT !.cxlRejReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelReject EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelReject EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReject EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReject EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReject EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReject EXCEPT !.delayToTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Replace Reject: 409 bytes                                  *)
(***************************************************************************)

OrderCancelReplaceReject ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      text                  : Sample(256),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      location              : Sample(5),
      cxlRejReason          : Sample(2),
      delayDuration         : Sample(2),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      liquidityFlag         : Sample(1),
      delayToTime           : Sample(8) ]

EncodeOrderCancelReplaceReject(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.location
        \o message.cxlRejReason
        \o message.delayDuration
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.liquidityFlag
        \o message.delayToTime

DecodeOrderCancelReplaceReject(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET execId == ReadBytes(text.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET location == ReadBytes(orderRequestId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET cxlRejReason == ReadBytes(location.rest, 2) IN IF ~cxlRejReason.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(cxlRejReason.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(delayDuration.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(splitMsg.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(liquidityFlag.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         text                  |-> text.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         location              |-> location.value,
         cxlRejReason          |-> cxlRejReason.value,
         delayDuration         |-> delayDuration.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         liquidityFlag         |-> liquidityFlag.value,
         delayToTime           |-> delayToTime.value ], delayToTime.rest)

ZeroOrderCancelReplaceReject ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      text                  |-> [i \in 1 .. 256 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      cxlRejReason          |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Replace Reject at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceReject ==
    { ZeroOrderCancelReplaceReject }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.cxlRejReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceReject EXCEPT !.delayToTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Party Details Group: 22 bytes                                           *)
(***************************************************************************)

PartyDetailsGroup2 ==
    [ partyDetailId   : Sample(20),
      partyDetailRole : Sample(2) ]

EncodePartyDetailsGroup2(message) ==
    message.partyDetailId
        \o message.partyDetailRole

DecodePartyDetailsGroup2(bytes) ==
    LET partyDetailId == ReadBytes(bytes, 20) IN IF ~partyDetailId.ok THEN Fail ELSE
    LET partyDetailRole == ReadBytes(partyDetailId.rest, 2) IN IF ~partyDetailRole.ok THEN Fail ELSE
    Ok([ partyDetailId   |-> partyDetailId.value,
         partyDetailRole |-> partyDetailRole.value ], partyDetailRole.rest)

ZeroPartyDetailsGroup2 ==
    [ partyDetailId   |-> [i \in 1 .. 20 |-> 0],
      partyDetailRole |-> [i \in 1 .. 2 |-> 0] ]

(* Party Details Group at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGroup2 ==
    { ZeroPartyDetailsGroup2 }
        \cup { [ZeroPartyDetailsGroup2 EXCEPT !.partyDetailId = one] : one \in Sample(20) }
        \cup { [ZeroPartyDetailsGroup2 EXCEPT !.partyDetailRole = one] : one \in Sample(2) }

(* A run of Party Details Group, written one after another *)
RECURSIVE EncodePartyDetailsGroup2List(_)
EncodePartyDetailsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartyDetailsGroup2(Head(messages)) \o EncodePartyDetailsGroup2List(Tail(messages))

(* As many Party Details Group as the field that counts them says *)
RECURSIVE ReadPartyDetailsGroup2List(_, _)
ReadPartyDetailsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartyDetailsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartyDetailsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Party Details Group of each kind, for the lists that carry them *)
OnePartyDetailsGroup2 == { ZeroPartyDetailsGroup2 }

(***************************************************************************)
(* Party Details Groups                                                    *)
(***************************************************************************)

PartyDetailsGroups2 ==
    [ blockLength       : Sample(2),
      partyDetailsGroup : SampleLists(OnePartyDetailsGroup2) ]

EncodePartyDetailsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.partyDetailsGroup), 1)
        \o EncodePartyDetailsGroup2List(message.partyDetailsGroup)

DecodePartyDetailsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partyDetailsGroup == ReadPartyDetailsGroup2List(numInGroup.rest, numInGroup.value) IN IF ~partyDetailsGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         partyDetailsGroup |-> partyDetailsGroup.value ], partyDetailsGroup.rest)

ZeroPartyDetailsGroups2 ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      partyDetailsGroup |-> << >> ]

(* Party Details Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGroups2 ==
    { ZeroPartyDetailsGroups2 }
        \cup { [ZeroPartyDetailsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPartyDetailsGroups2 EXCEPT !.partyDetailsGroup = one] : one \in SampleLists(OnePartyDetailsGroup2) }

(***************************************************************************)
(* Trd Reg Publications Group: 2 bytes                                     *)
(***************************************************************************)

TrdRegPublicationsGroup2 ==
    [ trdRegPublicationType   : Sample(1),
      trdRegPublicationReason : Sample(1) ]

EncodeTrdRegPublicationsGroup2(message) ==
    message.trdRegPublicationType
        \o message.trdRegPublicationReason

DecodeTrdRegPublicationsGroup2(bytes) ==
    LET trdRegPublicationType == ReadBytes(bytes, 1) IN IF ~trdRegPublicationType.ok THEN Fail ELSE
    LET trdRegPublicationReason == ReadBytes(trdRegPublicationType.rest, 1) IN IF ~trdRegPublicationReason.ok THEN Fail ELSE
    Ok([ trdRegPublicationType   |-> trdRegPublicationType.value,
         trdRegPublicationReason |-> trdRegPublicationReason.value ], trdRegPublicationReason.rest)

ZeroTrdRegPublicationsGroup2 ==
    [ trdRegPublicationType   |-> [i \in 1 .. 1 |-> 0],
      trdRegPublicationReason |-> [i \in 1 .. 1 |-> 0] ]

(* Trd Reg Publications Group at zero, then each field in turn at the values it is checked at *)
CheckedTrdRegPublicationsGroup2 ==
    { ZeroTrdRegPublicationsGroup2 }
        \cup { [ZeroTrdRegPublicationsGroup2 EXCEPT !.trdRegPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTrdRegPublicationsGroup2 EXCEPT !.trdRegPublicationReason = one] : one \in Sample(1) }

(* A run of Trd Reg Publications Group, written one after another *)
RECURSIVE EncodeTrdRegPublicationsGroup2List(_)
EncodeTrdRegPublicationsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdRegPublicationsGroup2(Head(messages)) \o EncodeTrdRegPublicationsGroup2List(Tail(messages))

(* As many Trd Reg Publications Group as the field that counts them says *)
RECURSIVE ReadTrdRegPublicationsGroup2List(_, _)
ReadTrdRegPublicationsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdRegPublicationsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdRegPublicationsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Reg Publications Group of each kind, for the lists that carry them *)
OneTrdRegPublicationsGroup2 == { ZeroTrdRegPublicationsGroup2 }

(***************************************************************************)
(* Trd Reg Publications Groups                                             *)
(***************************************************************************)

TrdRegPublicationsGroups2 ==
    [ blockLength             : Sample(2),
      trdRegPublicationsGroup : SampleLists(OneTrdRegPublicationsGroup2) ]

EncodeTrdRegPublicationsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.trdRegPublicationsGroup), 1)
        \o EncodeTrdRegPublicationsGroup2List(message.trdRegPublicationsGroup)

DecodeTrdRegPublicationsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET trdRegPublicationsGroup == ReadTrdRegPublicationsGroup2List(numInGroup.rest, numInGroup.value) IN IF ~trdRegPublicationsGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         trdRegPublicationsGroup |-> trdRegPublicationsGroup.value ], trdRegPublicationsGroup.rest)

ZeroTrdRegPublicationsGroups2 ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      trdRegPublicationsGroup |-> << >> ]

(* Trd Reg Publications Groups at zero, then each field in turn at the values it is checked at *)
CheckedTrdRegPublicationsGroups2 ==
    { ZeroTrdRegPublicationsGroups2 }
        \cup { [ZeroTrdRegPublicationsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTrdRegPublicationsGroups2 EXCEPT !.trdRegPublicationsGroup = one] : one \in SampleLists(OneTrdRegPublicationsGroup2) }

(***************************************************************************)
(* Party Details List Report                                               *)
(***************************************************************************)

PartyDetailsListReport ==
    [ seqNum                         : Sample(4),
      uuid                           : Sample(8),
      avgPxGroupId                   : Sample(20),
      partyDetailsListReqId          : Sample(8),
      partyDetailsListReportId       : Sample(8),
      sendingTimeEpoch               : Sample(8),
      selfMatchPreventionId          : Sample(8),
      totNumParties                  : Sample(2),
      requestResult                  : Sample(1),
      lastFragment                   : Sample(1),
      custOrderCapacity              : Sample(1),
      clearingAccountType            : Sample(1),
      selfMatchPreventionInstruction : Sample(1),
      avgPxIndicator                 : Sample(1),
      clearingTradePriceType         : Sample(1),
      cmtaGiveupCd                   : Sample(1),
      custOrderHandlingInst          : Sample(1),
      executor                       : Sample(8),
      idmShortCode                   : Sample(8),
      possRetransFlag                : Sample(1),
      splitMsg                       : Sample(1),
      partyDetailsGroups             : PartyDetailsGroups2,
      trdRegPublicationsGroups       : TrdRegPublicationsGroups2 ]

EncodePartyDetailsListReport(message) ==
    message.seqNum
        \o message.uuid
        \o message.avgPxGroupId
        \o message.partyDetailsListReqId
        \o message.partyDetailsListReportId
        \o message.sendingTimeEpoch
        \o message.selfMatchPreventionId
        \o message.totNumParties
        \o message.requestResult
        \o message.lastFragment
        \o message.custOrderCapacity
        \o message.clearingAccountType
        \o message.selfMatchPreventionInstruction
        \o message.avgPxIndicator
        \o message.clearingTradePriceType
        \o message.cmtaGiveupCd
        \o message.custOrderHandlingInst
        \o message.executor
        \o message.idmShortCode
        \o message.possRetransFlag
        \o message.splitMsg
        \o EncodePartyDetailsGroups2(message.partyDetailsGroups)
        \o EncodeTrdRegPublicationsGroups2(message.trdRegPublicationsGroups)

DecodePartyDetailsListReport(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET avgPxGroupId == ReadBytes(uuid.rest, 20) IN IF ~avgPxGroupId.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(avgPxGroupId.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET partyDetailsListReportId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~partyDetailsListReportId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReportId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET totNumParties == ReadBytes(selfMatchPreventionId.rest, 2) IN IF ~totNumParties.ok THEN Fail ELSE
    LET requestResult == ReadBytes(totNumParties.rest, 1) IN IF ~requestResult.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(requestResult.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET custOrderCapacity == ReadBytes(lastFragment.rest, 1) IN IF ~custOrderCapacity.ok THEN Fail ELSE
    LET clearingAccountType == ReadBytes(custOrderCapacity.rest, 1) IN IF ~clearingAccountType.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(clearingAccountType.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET avgPxIndicator == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~avgPxIndicator.ok THEN Fail ELSE
    LET clearingTradePriceType == ReadBytes(avgPxIndicator.rest, 1) IN IF ~clearingTradePriceType.ok THEN Fail ELSE
    LET cmtaGiveupCd == ReadBytes(clearingTradePriceType.rest, 1) IN IF ~cmtaGiveupCd.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(cmtaGiveupCd.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET executor == ReadBytes(custOrderHandlingInst.rest, 8) IN IF ~executor.ok THEN Fail ELSE
    LET idmShortCode == ReadBytes(executor.rest, 8) IN IF ~idmShortCode.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(idmShortCode.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET partyDetailsGroups == DecodePartyDetailsGroups2(splitMsg.rest) IN IF ~partyDetailsGroups.ok THEN Fail ELSE
    LET trdRegPublicationsGroups == DecodeTrdRegPublicationsGroups2(partyDetailsGroups.rest) IN IF ~trdRegPublicationsGroups.ok THEN Fail ELSE
    Ok([ seqNum                         |-> seqNum.value,
         uuid                           |-> uuid.value,
         avgPxGroupId                   |-> avgPxGroupId.value,
         partyDetailsListReqId          |-> partyDetailsListReqId.value,
         partyDetailsListReportId       |-> partyDetailsListReportId.value,
         sendingTimeEpoch               |-> sendingTimeEpoch.value,
         selfMatchPreventionId          |-> selfMatchPreventionId.value,
         totNumParties                  |-> totNumParties.value,
         requestResult                  |-> requestResult.value,
         lastFragment                   |-> lastFragment.value,
         custOrderCapacity              |-> custOrderCapacity.value,
         clearingAccountType            |-> clearingAccountType.value,
         selfMatchPreventionInstruction |-> selfMatchPreventionInstruction.value,
         avgPxIndicator                 |-> avgPxIndicator.value,
         clearingTradePriceType         |-> clearingTradePriceType.value,
         cmtaGiveupCd                   |-> cmtaGiveupCd.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value,
         executor                       |-> executor.value,
         idmShortCode                   |-> idmShortCode.value,
         possRetransFlag                |-> possRetransFlag.value,
         splitMsg                       |-> splitMsg.value,
         partyDetailsGroups             |-> partyDetailsGroups.value,
         trdRegPublicationsGroups       |-> trdRegPublicationsGroups.value ], trdRegPublicationsGroups.rest)

ZeroPartyDetailsListReport ==
    [ seqNum                         |-> [i \in 1 .. 4 |-> 0],
      uuid                           |-> [i \in 1 .. 8 |-> 0],
      avgPxGroupId                   |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId          |-> [i \in 1 .. 8 |-> 0],
      partyDetailsListReportId       |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch               |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionId          |-> [i \in 1 .. 8 |-> 0],
      totNumParties                  |-> [i \in 1 .. 2 |-> 0],
      requestResult                  |-> [i \in 1 .. 1 |-> 0],
      lastFragment                   |-> [i \in 1 .. 1 |-> 0],
      custOrderCapacity              |-> [i \in 1 .. 1 |-> 0],
      clearingAccountType            |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      avgPxIndicator                 |-> [i \in 1 .. 1 |-> 0],
      clearingTradePriceType         |-> [i \in 1 .. 1 |-> 0],
      cmtaGiveupCd                   |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst          |-> [i \in 1 .. 1 |-> 0],
      executor                       |-> [i \in 1 .. 8 |-> 0],
      idmShortCode                   |-> [i \in 1 .. 8 |-> 0],
      possRetransFlag                |-> [i \in 1 .. 1 |-> 0],
      splitMsg                       |-> [i \in 1 .. 1 |-> 0],
      partyDetailsGroups             |-> ZeroPartyDetailsGroups2,
      trdRegPublicationsGroups       |-> ZeroTrdRegPublicationsGroups2 ]

(* Party Details List Report at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsListReport ==
    { ZeroPartyDetailsListReport }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.avgPxGroupId = one] : one \in Sample(20) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.partyDetailsListReportId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.totNumParties = one] : one \in Sample(2) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.requestResult = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.custOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.clearingAccountType = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.avgPxIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.clearingTradePriceType = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.cmtaGiveupCd = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.executor = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.idmShortCode = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.partyDetailsGroups = one] : one \in CheckedPartyDetailsGroups2 }
        \cup { [ZeroPartyDetailsListReport EXCEPT !.trdRegPublicationsGroups = one] : one \in CheckedTrdRegPublicationsGroups2 }

(***************************************************************************)
(* Request For Quote Ack: 358 bytes                                        *)
(***************************************************************************)

RequestForQuoteAck ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      text                  : Sample(256),
      senderId              : Sample(20),
      exchangeQuoteReqId    : Sample(17),
      partyDetailsListReqId : Sample(8),
      requestTime           : Sample(8),
      sendingTimeEpoch      : Sample(8),
      quoteReqId            : Sample(8),
      location              : Sample(5),
      quoteRejectReason     : Sample(2),
      delayDuration         : Sample(2),
      quoteAckStatus        : Sample(1),
      manualOrderIndicator  : Sample(1),
      splitMsg              : Sample(1),
      possRetransFlag       : Sample(1),
      delayToTime           : Sample(8) ]

EncodeRequestForQuoteAck(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.senderId
        \o message.exchangeQuoteReqId
        \o message.partyDetailsListReqId
        \o message.requestTime
        \o message.sendingTimeEpoch
        \o message.quoteReqId
        \o message.location
        \o message.quoteRejectReason
        \o message.delayDuration
        \o message.quoteAckStatus
        \o message.manualOrderIndicator
        \o message.splitMsg
        \o message.possRetransFlag
        \o message.delayToTime

DecodeRequestForQuoteAck(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET senderId == ReadBytes(text.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET exchangeQuoteReqId == ReadBytes(senderId.rest, 17) IN IF ~exchangeQuoteReqId.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(exchangeQuoteReqId.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET requestTime == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(requestTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET location == ReadBytes(quoteReqId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(location.rest, 2) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(quoteRejectReason.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET quoteAckStatus == ReadBytes(delayDuration.rest, 1) IN IF ~quoteAckStatus.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(quoteAckStatus.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(splitMsg.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(possRetransFlag.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         text                  |-> text.value,
         senderId              |-> senderId.value,
         exchangeQuoteReqId    |-> exchangeQuoteReqId.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         requestTime           |-> requestTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         quoteReqId            |-> quoteReqId.value,
         location              |-> location.value,
         quoteRejectReason     |-> quoteRejectReason.value,
         delayDuration         |-> delayDuration.value,
         quoteAckStatus        |-> quoteAckStatus.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         splitMsg              |-> splitMsg.value,
         possRetransFlag       |-> possRetransFlag.value,
         delayToTime           |-> delayToTime.value ], delayToTime.rest)

ZeroRequestForQuoteAck ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      text                  |-> [i \in 1 .. 256 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      exchangeQuoteReqId    |-> [i \in 1 .. 17 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      requestTime           |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      quoteReqId            |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      quoteRejectReason     |-> [i \in 1 .. 2 |-> 0],
      delayDuration         |-> [i \in 1 .. 2 |-> 0],
      quoteAckStatus        |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Request For Quote Ack at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuoteAck ==
    { ZeroRequestForQuoteAck }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.exchangeQuoteReqId = one] : one \in Sample(17) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.quoteRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.quoteAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuoteAck EXCEPT !.delayToTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Calculated Ccy Last Qty: 9 bytes                                        *)
(***************************************************************************)

CalculatedCcyLastQty3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeCalculatedCcyLastQty3(message) ==
    message.mantissa
        \o message.exponent

DecodeCalculatedCcyLastQty3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroCalculatedCcyLastQty3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Calculated Ccy Last Qty at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedCcyLastQty3 ==
    { ZeroCalculatedCcyLastQty3 }
        \cup { [ZeroCalculatedCcyLastQty3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedCcyLastQty3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Gross Trade Amt: 9 bytes                                                *)
(***************************************************************************)

GrossTradeAmt3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeGrossTradeAmt3(message) ==
    message.mantissa
        \o message.exponent

DecodeGrossTradeAmt3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroGrossTradeAmt3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Gross Trade Amt at zero, then each field in turn at the values it is checked at *)
CheckedGrossTradeAmt3 ==
    { ZeroGrossTradeAmt3 }
        \cup { [ZeroGrossTradeAmt3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroGrossTradeAmt3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Group: 15 bytes                                                   *)
(***************************************************************************)

FillsGroup4 ==
    [ fillPx        : Sample(8),
      fillQty       : Sample(4),
      fillExecId    : Sample(2),
      fillYieldType : Sample(1) ]

EncodeFillsGroup4(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillExecId
        \o message.fillYieldType

DecodeFillsGroup4(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillQty.rest, 2) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillYieldType == ReadBytes(fillExecId.rest, 1) IN IF ~fillYieldType.ok THEN Fail ELSE
    Ok([ fillPx        |-> fillPx.value,
         fillQty       |-> fillQty.value,
         fillExecId    |-> fillExecId.value,
         fillYieldType |-> fillYieldType.value ], fillYieldType.rest)

ZeroFillsGroup4 ==
    [ fillPx        |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      fillExecId    |-> [i \in 1 .. 2 |-> 0],
      fillYieldType |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroup4 ==
    { ZeroFillsGroup4 }
        \cup { [ZeroFillsGroup4 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGroup4 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGroup4 EXCEPT !.fillExecId = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroup4 EXCEPT !.fillYieldType = one] : one \in Sample(1) }

(* A run of Fills Group, written one after another *)
RECURSIVE EncodeFillsGroup4List(_)
EncodeFillsGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGroup4(Head(messages)) \o EncodeFillsGroup4List(Tail(messages))

(* As many Fills Group as the field that counts them says *)
RECURSIVE ReadFillsGroup4List(_, _)
ReadFillsGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Group of each kind, for the lists that carry them *)
OneFillsGroup4 == { ZeroFillsGroup4 }

(***************************************************************************)
(* Fills Groups                                                            *)
(***************************************************************************)

FillsGroups4 ==
    [ blockLength : Sample(2),
      fillsGroup  : SampleLists(OneFillsGroup4) ]

EncodeFillsGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.fillsGroup), 1)
        \o EncodeFillsGroup4List(message.fillsGroup)

DecodeFillsGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillsGroup == ReadFillsGroup4List(numInGroup.rest, numInGroup.value) IN IF ~fillsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         fillsGroup  |-> fillsGroup.value ], fillsGroup.rest)

ZeroFillsGroups4 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      fillsGroup  |-> << >> ]

(* Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroups4 ==
    { ZeroFillsGroups4 }
        \cup { [ZeroFillsGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroups4 EXCEPT !.fillsGroup = one] : one \in SampleLists(OneFillsGroup4) }

(***************************************************************************)
(* Contra Gross Trade Amt: 9 bytes                                         *)
(***************************************************************************)

ContraGrossTradeAmt2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeContraGrossTradeAmt2(message) ==
    message.mantissa
        \o message.exponent

DecodeContraGrossTradeAmt2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroContraGrossTradeAmt2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Contra Gross Trade Amt at zero, then each field in turn at the values it is checked at *)
CheckedContraGrossTradeAmt2 ==
    { ZeroContraGrossTradeAmt2 }
        \cup { [ZeroContraGrossTradeAmt2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroContraGrossTradeAmt2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Contra Calculated Ccy Last Qty: 9 bytes                                 *)
(***************************************************************************)

ContraCalculatedCcyLastQty2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeContraCalculatedCcyLastQty2(message) ==
    message.mantissa
        \o message.exponent

DecodeContraCalculatedCcyLastQty2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroContraCalculatedCcyLastQty2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Contra Calculated Ccy Last Qty at zero, then each field in turn at the values it is checked at *)
CheckedContraCalculatedCcyLastQty2 ==
    { ZeroContraCalculatedCcyLastQty2 }
        \cup { [ZeroContraCalculatedCcyLastQty2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroContraCalculatedCcyLastQty2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Outright Trade Events Group: 45 bytes                                   *)
(***************************************************************************)

OutrightTradeEventsGroup ==
    [ orderEventPx               : Sample(8),
      orderEventText             : Sample(5),
      orderEventExecId           : Sample(4),
      orderEventQty              : Sample(4),
      tradeAddendum              : Sample(1),
      orderEventReason           : Sample(1),
      originalOrderEventExecId   : Sample(4),
      contraGrossTradeAmt        : ContraGrossTradeAmt2,
      contraCalculatedCcyLastQty : ContraCalculatedCcyLastQty2 ]

EncodeOutrightTradeEventsGroup(message) ==
    message.orderEventPx
        \o message.orderEventText
        \o message.orderEventExecId
        \o message.orderEventQty
        \o message.tradeAddendum
        \o message.orderEventReason
        \o message.originalOrderEventExecId
        \o EncodeContraGrossTradeAmt2(message.contraGrossTradeAmt)
        \o EncodeContraCalculatedCcyLastQty2(message.contraCalculatedCcyLastQty)

DecodeOutrightTradeEventsGroup(bytes) ==
    LET orderEventPx == ReadBytes(bytes, 8) IN IF ~orderEventPx.ok THEN Fail ELSE
    LET orderEventText == ReadBytes(orderEventPx.rest, 5) IN IF ~orderEventText.ok THEN Fail ELSE
    LET orderEventExecId == ReadBytes(orderEventText.rest, 4) IN IF ~orderEventExecId.ok THEN Fail ELSE
    LET orderEventQty == ReadBytes(orderEventExecId.rest, 4) IN IF ~orderEventQty.ok THEN Fail ELSE
    LET tradeAddendum == ReadBytes(orderEventQty.rest, 1) IN IF ~tradeAddendum.ok THEN Fail ELSE
    LET orderEventReason == ReadBytes(tradeAddendum.rest, 1) IN IF ~orderEventReason.ok THEN Fail ELSE
    LET originalOrderEventExecId == ReadBytes(orderEventReason.rest, 4) IN IF ~originalOrderEventExecId.ok THEN Fail ELSE
    LET contraGrossTradeAmt == DecodeContraGrossTradeAmt2(originalOrderEventExecId.rest) IN IF ~contraGrossTradeAmt.ok THEN Fail ELSE
    LET contraCalculatedCcyLastQty == DecodeContraCalculatedCcyLastQty2(contraGrossTradeAmt.rest) IN IF ~contraCalculatedCcyLastQty.ok THEN Fail ELSE
    Ok([ orderEventPx               |-> orderEventPx.value,
         orderEventText             |-> orderEventText.value,
         orderEventExecId           |-> orderEventExecId.value,
         orderEventQty              |-> orderEventQty.value,
         tradeAddendum              |-> tradeAddendum.value,
         orderEventReason           |-> orderEventReason.value,
         originalOrderEventExecId   |-> originalOrderEventExecId.value,
         contraGrossTradeAmt        |-> contraGrossTradeAmt.value,
         contraCalculatedCcyLastQty |-> contraCalculatedCcyLastQty.value ], contraCalculatedCcyLastQty.rest)

ZeroOutrightTradeEventsGroup ==
    [ orderEventPx               |-> [i \in 1 .. 8 |-> 0],
      orderEventText             |-> [i \in 1 .. 5 |-> 0],
      orderEventExecId           |-> [i \in 1 .. 4 |-> 0],
      orderEventQty              |-> [i \in 1 .. 4 |-> 0],
      tradeAddendum              |-> [i \in 1 .. 1 |-> 0],
      orderEventReason           |-> [i \in 1 .. 1 |-> 0],
      originalOrderEventExecId   |-> [i \in 1 .. 4 |-> 0],
      contraGrossTradeAmt        |-> ZeroContraGrossTradeAmt2,
      contraCalculatedCcyLastQty |-> ZeroContraCalculatedCcyLastQty2 ]

(* Outright Trade Events Group at zero, then each field in turn at the values it is checked at *)
CheckedOutrightTradeEventsGroup ==
    { ZeroOutrightTradeEventsGroup }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.orderEventPx = one] : one \in Sample(8) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.orderEventText = one] : one \in Sample(5) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.orderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.orderEventQty = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.tradeAddendum = one] : one \in Sample(1) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.orderEventReason = one] : one \in Sample(1) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.originalOrderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.contraGrossTradeAmt = one] : one \in CheckedContraGrossTradeAmt2 }
        \cup { [ZeroOutrightTradeEventsGroup EXCEPT !.contraCalculatedCcyLastQty = one] : one \in CheckedContraCalculatedCcyLastQty2 }

(* A run of Outright Trade Events Group, written one after another *)
RECURSIVE EncodeOutrightTradeEventsGroupList(_)
EncodeOutrightTradeEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOutrightTradeEventsGroup(Head(messages)) \o EncodeOutrightTradeEventsGroupList(Tail(messages))

(* As many Outright Trade Events Group as the field that counts them says *)
RECURSIVE ReadOutrightTradeEventsGroupList(_, _)
ReadOutrightTradeEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOutrightTradeEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOutrightTradeEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Outright Trade Events Group of each kind, for the lists that carry them *)
OneOutrightTradeEventsGroup == { ZeroOutrightTradeEventsGroup }

(***************************************************************************)
(* Outright Trade Events Groups                                            *)
(***************************************************************************)

OutrightTradeEventsGroups ==
    [ blockLength              : Sample(2),
      outrightTradeEventsGroup : SampleLists(OneOutrightTradeEventsGroup) ]

EncodeOutrightTradeEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.outrightTradeEventsGroup), 1)
        \o EncodeOutrightTradeEventsGroupList(message.outrightTradeEventsGroup)

DecodeOutrightTradeEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET outrightTradeEventsGroup == ReadOutrightTradeEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~outrightTradeEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         outrightTradeEventsGroup |-> outrightTradeEventsGroup.value ], outrightTradeEventsGroup.rest)

ZeroOutrightTradeEventsGroups ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      outrightTradeEventsGroup |-> << >> ]

(* Outright Trade Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedOutrightTradeEventsGroups ==
    { ZeroOutrightTradeEventsGroups }
        \cup { [ZeroOutrightTradeEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOutrightTradeEventsGroups EXCEPT !.outrightTradeEventsGroup = one] : one \in SampleLists(OneOutrightTradeEventsGroup) }

(***************************************************************************)
(* Execution Report Trade Addendum Outright                                *)
(***************************************************************************)

ExecutionReportTradeAddendumOutright ==
    [ seqNum                    : Sample(4),
      uuid                      : Sample(8),
      execId                    : Sample(40),
      senderId                  : Sample(20),
      clordid                   : Sample(20),
      partyDetailsListReqId     : Sample(8),
      lastPx                    : Sample(8),
      orderId                   : Sample(8),
      transactTime              : Sample(8),
      sendingTimeEpoch          : Sample(8),
      secExecId                 : Sample(8),
      origSecondaryExecutionId  : Sample(8),
      location                  : Sample(5),
      securityId                : Sample(4),
      lastQty                   : Sample(4),
      sideTradeId               : Sample(4),
      origSideTradeId           : Sample(4),
      tradeDate                 : Sample(2),
      ordStatusTrdCxl           : Sample(1),
      execType                  : Sample(1),
      side                      : Sample(1),
      manualOrderIndicator      : Sample(1),
      possRetransFlag           : Sample(1),
      execInst                  : Sample(1),
      executionMode             : Sample(1),
      liquidityFlag             : Sample(1),
      managedOrder              : Sample(1),
      shortSaleType             : Sample(1),
      discretionPrice           : Sample(8),
      trdType                   : Sample(2),
      execRestatementReason     : Sample(1),
      settlDate                 : Sample(2),
      maturityDate              : Sample(2),
      calculatedCcyLastQty      : CalculatedCcyLastQty3,
      grossTradeAmt             : GrossTradeAmt3,
      benchmarkPrice            : Sample(8),
      fillsGroups               : FillsGroups4,
      outrightTradeEventsGroups : OutrightTradeEventsGroups ]

EncodeExecutionReportTradeAddendumOutright(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.lastPx
        \o message.orderId
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.secExecId
        \o message.origSecondaryExecutionId
        \o message.location
        \o message.securityId
        \o message.lastQty
        \o message.sideTradeId
        \o message.origSideTradeId
        \o message.tradeDate
        \o message.ordStatusTrdCxl
        \o message.execType
        \o message.side
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.discretionPrice
        \o message.trdType
        \o message.execRestatementReason
        \o message.settlDate
        \o message.maturityDate
        \o EncodeCalculatedCcyLastQty3(message.calculatedCcyLastQty)
        \o EncodeGrossTradeAmt3(message.grossTradeAmt)
        \o message.benchmarkPrice
        \o EncodeFillsGroups4(message.fillsGroups)
        \o EncodeOutrightTradeEventsGroups(message.outrightTradeEventsGroups)

DecodeExecutionReportTradeAddendumOutright(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET secExecId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET origSecondaryExecutionId == ReadBytes(secExecId.rest, 8) IN IF ~origSecondaryExecutionId.ok THEN Fail ELSE
    LET location == ReadBytes(origSecondaryExecutionId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(lastQty.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET origSideTradeId == ReadBytes(sideTradeId.rest, 4) IN IF ~origSideTradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(origSideTradeId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET ordStatusTrdCxl == ReadBytes(tradeDate.rest, 1) IN IF ~ordStatusTrdCxl.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatusTrdCxl.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(side.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET execInst == ReadBytes(possRetransFlag.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(shortSaleType.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    LET trdType == ReadBytes(discretionPrice.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(trdType.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET settlDate == ReadBytes(execRestatementReason.rest, 2) IN IF ~settlDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(settlDate.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET calculatedCcyLastQty == DecodeCalculatedCcyLastQty3(maturityDate.rest) IN IF ~calculatedCcyLastQty.ok THEN Fail ELSE
    LET grossTradeAmt == DecodeGrossTradeAmt3(calculatedCcyLastQty.rest) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET benchmarkPrice == ReadBytes(grossTradeAmt.rest, 8) IN IF ~benchmarkPrice.ok THEN Fail ELSE
    LET fillsGroups == DecodeFillsGroups4(benchmarkPrice.rest) IN IF ~fillsGroups.ok THEN Fail ELSE
    LET outrightTradeEventsGroups == DecodeOutrightTradeEventsGroups(fillsGroups.rest) IN IF ~outrightTradeEventsGroups.ok THEN Fail ELSE
    Ok([ seqNum                    |-> seqNum.value,
         uuid                      |-> uuid.value,
         execId                    |-> execId.value,
         senderId                  |-> senderId.value,
         clordid                   |-> clordid.value,
         partyDetailsListReqId     |-> partyDetailsListReqId.value,
         lastPx                    |-> lastPx.value,
         orderId                   |-> orderId.value,
         transactTime              |-> transactTime.value,
         sendingTimeEpoch          |-> sendingTimeEpoch.value,
         secExecId                 |-> secExecId.value,
         origSecondaryExecutionId  |-> origSecondaryExecutionId.value,
         location                  |-> location.value,
         securityId                |-> securityId.value,
         lastQty                   |-> lastQty.value,
         sideTradeId               |-> sideTradeId.value,
         origSideTradeId           |-> origSideTradeId.value,
         tradeDate                 |-> tradeDate.value,
         ordStatusTrdCxl           |-> ordStatusTrdCxl.value,
         execType                  |-> execType.value,
         side                      |-> side.value,
         manualOrderIndicator      |-> manualOrderIndicator.value,
         possRetransFlag           |-> possRetransFlag.value,
         execInst                  |-> execInst.value,
         executionMode             |-> executionMode.value,
         liquidityFlag             |-> liquidityFlag.value,
         managedOrder              |-> managedOrder.value,
         shortSaleType             |-> shortSaleType.value,
         discretionPrice           |-> discretionPrice.value,
         trdType                   |-> trdType.value,
         execRestatementReason     |-> execRestatementReason.value,
         settlDate                 |-> settlDate.value,
         maturityDate              |-> maturityDate.value,
         calculatedCcyLastQty      |-> calculatedCcyLastQty.value,
         grossTradeAmt             |-> grossTradeAmt.value,
         benchmarkPrice            |-> benchmarkPrice.value,
         fillsGroups               |-> fillsGroups.value,
         outrightTradeEventsGroups |-> outrightTradeEventsGroups.value ], outrightTradeEventsGroups.rest)

ZeroExecutionReportTradeAddendumOutright ==
    [ seqNum                    |-> [i \in 1 .. 4 |-> 0],
      uuid                      |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 40 |-> 0],
      senderId                  |-> [i \in 1 .. 20 |-> 0],
      clordid                   |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId     |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch          |-> [i \in 1 .. 8 |-> 0],
      secExecId                 |-> [i \in 1 .. 8 |-> 0],
      origSecondaryExecutionId  |-> [i \in 1 .. 8 |-> 0],
      location                  |-> [i \in 1 .. 5 |-> 0],
      securityId                |-> [i \in 1 .. 4 |-> 0],
      lastQty                   |-> [i \in 1 .. 4 |-> 0],
      sideTradeId               |-> [i \in 1 .. 4 |-> 0],
      origSideTradeId           |-> [i \in 1 .. 4 |-> 0],
      tradeDate                 |-> [i \in 1 .. 2 |-> 0],
      ordStatusTrdCxl           |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator      |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag           |-> [i \in 1 .. 1 |-> 0],
      execInst                  |-> [i \in 1 .. 1 |-> 0],
      executionMode             |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag             |-> [i \in 1 .. 1 |-> 0],
      managedOrder              |-> [i \in 1 .. 1 |-> 0],
      shortSaleType             |-> [i \in 1 .. 1 |-> 0],
      discretionPrice           |-> [i \in 1 .. 8 |-> 0],
      trdType                   |-> [i \in 1 .. 2 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 1 |-> 0],
      settlDate                 |-> [i \in 1 .. 2 |-> 0],
      maturityDate              |-> [i \in 1 .. 2 |-> 0],
      calculatedCcyLastQty      |-> ZeroCalculatedCcyLastQty3,
      grossTradeAmt             |-> ZeroGrossTradeAmt3,
      benchmarkPrice            |-> [i \in 1 .. 8 |-> 0],
      fillsGroups               |-> ZeroFillsGroups4,
      outrightTradeEventsGroups |-> ZeroOutrightTradeEventsGroups ]

(* Execution Report Trade Addendum Outright at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeAddendumOutright ==
    { ZeroExecutionReportTradeAddendumOutright }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.origSecondaryExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.origSideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.ordStatusTrdCxl = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.discretionPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.settlDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.calculatedCcyLastQty = one] : one \in CheckedCalculatedCcyLastQty3 }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.grossTradeAmt = one] : one \in CheckedGrossTradeAmt3 }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.benchmarkPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.fillsGroups = one] : one \in CheckedFillsGroups4 }
        \cup { [ZeroExecutionReportTradeAddendumOutright EXCEPT !.outrightTradeEventsGroups = one] : one \in CheckedOutrightTradeEventsGroups }

(***************************************************************************)
(* Fills Group: 15 bytes                                                   *)
(***************************************************************************)

FillsGroup5 ==
    [ fillPx        : Sample(8),
      fillQty       : Sample(4),
      fillExecId    : Sample(2),
      fillYieldType : Sample(1) ]

EncodeFillsGroup5(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillExecId
        \o message.fillYieldType

DecodeFillsGroup5(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillQty.rest, 2) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillYieldType == ReadBytes(fillExecId.rest, 1) IN IF ~fillYieldType.ok THEN Fail ELSE
    Ok([ fillPx        |-> fillPx.value,
         fillQty       |-> fillQty.value,
         fillExecId    |-> fillExecId.value,
         fillYieldType |-> fillYieldType.value ], fillYieldType.rest)

ZeroFillsGroup5 ==
    [ fillPx        |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      fillExecId    |-> [i \in 1 .. 2 |-> 0],
      fillYieldType |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroup5 ==
    { ZeroFillsGroup5 }
        \cup { [ZeroFillsGroup5 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGroup5 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGroup5 EXCEPT !.fillExecId = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroup5 EXCEPT !.fillYieldType = one] : one \in Sample(1) }

(* A run of Fills Group, written one after another *)
RECURSIVE EncodeFillsGroup5List(_)
EncodeFillsGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGroup5(Head(messages)) \o EncodeFillsGroup5List(Tail(messages))

(* As many Fills Group as the field that counts them says *)
RECURSIVE ReadFillsGroup5List(_, _)
ReadFillsGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Group of each kind, for the lists that carry them *)
OneFillsGroup5 == { ZeroFillsGroup5 }

(***************************************************************************)
(* Fills Groups                                                            *)
(***************************************************************************)

FillsGroups5 ==
    [ blockLength : Sample(2),
      fillsGroup  : SampleLists(OneFillsGroup5) ]

EncodeFillsGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.fillsGroup), 1)
        \o EncodeFillsGroup5List(message.fillsGroup)

DecodeFillsGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillsGroup == ReadFillsGroup5List(numInGroup.rest, numInGroup.value) IN IF ~fillsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         fillsGroup  |-> fillsGroup.value ], fillsGroup.rest)

ZeroFillsGroups5 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      fillsGroup  |-> << >> ]

(* Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroups5 ==
    { ZeroFillsGroups5 }
        \cup { [ZeroFillsGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroups5 EXCEPT !.fillsGroup = one] : one \in SampleLists(OneFillsGroup5) }

(***************************************************************************)
(* Trade Addendum Legs Group: 41 bytes                                     *)
(***************************************************************************)

TradeAddendumLegsGroup ==
    [ legExecId     : Sample(8),
      legLastPx     : Sample(8),
      legExecRefId  : Sample(8),
      legTradeId    : Sample(4),
      legTradeRefId : Sample(4),
      legSecurityId : Sample(4),
      legLastQty    : Sample(4),
      legSide       : Sample(1) ]

EncodeTradeAddendumLegsGroup(message) ==
    message.legExecId
        \o message.legLastPx
        \o message.legExecRefId
        \o message.legTradeId
        \o message.legTradeRefId
        \o message.legSecurityId
        \o message.legLastQty
        \o message.legSide

DecodeTradeAddendumLegsGroup(bytes) ==
    LET legExecId == ReadBytes(bytes, 8) IN IF ~legExecId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legExecId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legExecRefId == ReadBytes(legLastPx.rest, 8) IN IF ~legExecRefId.ok THEN Fail ELSE
    LET legTradeId == ReadBytes(legExecRefId.rest, 4) IN IF ~legTradeId.ok THEN Fail ELSE
    LET legTradeRefId == ReadBytes(legTradeId.rest, 4) IN IF ~legTradeRefId.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legTradeRefId.rest, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legSecurityId.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legLastQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legExecId     |-> legExecId.value,
         legLastPx     |-> legLastPx.value,
         legExecRefId  |-> legExecRefId.value,
         legTradeId    |-> legTradeId.value,
         legTradeRefId |-> legTradeRefId.value,
         legSecurityId |-> legSecurityId.value,
         legLastQty    |-> legLastQty.value,
         legSide       |-> legSide.value ], legSide.rest)

ZeroTradeAddendumLegsGroup ==
    [ legExecId     |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legExecRefId  |-> [i \in 1 .. 8 |-> 0],
      legTradeId    |-> [i \in 1 .. 4 |-> 0],
      legTradeRefId |-> [i \in 1 .. 4 |-> 0],
      legSecurityId |-> [i \in 1 .. 4 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Addendum Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeAddendumLegsGroup ==
    { ZeroTradeAddendumLegsGroup }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legExecId = one] : one \in Sample(8) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legExecRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legTradeRefId = one] : one \in Sample(4) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeAddendumLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Trade Addendum Legs Group, written one after another *)
RECURSIVE EncodeTradeAddendumLegsGroupList(_)
EncodeTradeAddendumLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeAddendumLegsGroup(Head(messages)) \o EncodeTradeAddendumLegsGroupList(Tail(messages))

(* As many Trade Addendum Legs Group as the field that counts them says *)
RECURSIVE ReadTradeAddendumLegsGroupList(_, _)
ReadTradeAddendumLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeAddendumLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeAddendumLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Addendum Legs Group of each kind, for the lists that carry them *)
OneTradeAddendumLegsGroup == { ZeroTradeAddendumLegsGroup }

(***************************************************************************)
(* Trade Addendum Legs Groups                                              *)
(***************************************************************************)

TradeAddendumLegsGroups ==
    [ blockLength            : Sample(2),
      tradeAddendumLegsGroup : SampleLists(OneTradeAddendumLegsGroup) ]

EncodeTradeAddendumLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeAddendumLegsGroup), 1)
        \o EncodeTradeAddendumLegsGroupList(message.tradeAddendumLegsGroup)

DecodeTradeAddendumLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET tradeAddendumLegsGroup == ReadTradeAddendumLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~tradeAddendumLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         tradeAddendumLegsGroup |-> tradeAddendumLegsGroup.value ], tradeAddendumLegsGroup.rest)

ZeroTradeAddendumLegsGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      tradeAddendumLegsGroup |-> << >> ]

(* Trade Addendum Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeAddendumLegsGroups ==
    { ZeroTradeAddendumLegsGroups }
        \cup { [ZeroTradeAddendumLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeAddendumLegsGroups EXCEPT !.tradeAddendumLegsGroup = one] : one \in SampleLists(OneTradeAddendumLegsGroup) }

(***************************************************************************)
(* Spread Trade Events Group: 27 bytes                                     *)
(***************************************************************************)

SpreadTradeEventsGroup ==
    [ orderEventPx             : Sample(8),
      orderEventText           : Sample(5),
      orderEventExecId         : Sample(4),
      orderEventQty            : Sample(4),
      tradeAddendum            : Sample(1),
      orderEventReason         : Sample(1),
      originalOrderEventExecId : Sample(4) ]

EncodeSpreadTradeEventsGroup(message) ==
    message.orderEventPx
        \o message.orderEventText
        \o message.orderEventExecId
        \o message.orderEventQty
        \o message.tradeAddendum
        \o message.orderEventReason
        \o message.originalOrderEventExecId

DecodeSpreadTradeEventsGroup(bytes) ==
    LET orderEventPx == ReadBytes(bytes, 8) IN IF ~orderEventPx.ok THEN Fail ELSE
    LET orderEventText == ReadBytes(orderEventPx.rest, 5) IN IF ~orderEventText.ok THEN Fail ELSE
    LET orderEventExecId == ReadBytes(orderEventText.rest, 4) IN IF ~orderEventExecId.ok THEN Fail ELSE
    LET orderEventQty == ReadBytes(orderEventExecId.rest, 4) IN IF ~orderEventQty.ok THEN Fail ELSE
    LET tradeAddendum == ReadBytes(orderEventQty.rest, 1) IN IF ~tradeAddendum.ok THEN Fail ELSE
    LET orderEventReason == ReadBytes(tradeAddendum.rest, 1) IN IF ~orderEventReason.ok THEN Fail ELSE
    LET originalOrderEventExecId == ReadBytes(orderEventReason.rest, 4) IN IF ~originalOrderEventExecId.ok THEN Fail ELSE
    Ok([ orderEventPx             |-> orderEventPx.value,
         orderEventText           |-> orderEventText.value,
         orderEventExecId         |-> orderEventExecId.value,
         orderEventQty            |-> orderEventQty.value,
         tradeAddendum            |-> tradeAddendum.value,
         orderEventReason         |-> orderEventReason.value,
         originalOrderEventExecId |-> originalOrderEventExecId.value ], originalOrderEventExecId.rest)

ZeroSpreadTradeEventsGroup ==
    [ orderEventPx             |-> [i \in 1 .. 8 |-> 0],
      orderEventText           |-> [i \in 1 .. 5 |-> 0],
      orderEventExecId         |-> [i \in 1 .. 4 |-> 0],
      orderEventQty            |-> [i \in 1 .. 4 |-> 0],
      tradeAddendum            |-> [i \in 1 .. 1 |-> 0],
      orderEventReason         |-> [i \in 1 .. 1 |-> 0],
      originalOrderEventExecId |-> [i \in 1 .. 4 |-> 0] ]

(* Spread Trade Events Group at zero, then each field in turn at the values it is checked at *)
CheckedSpreadTradeEventsGroup ==
    { ZeroSpreadTradeEventsGroup }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.orderEventPx = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.orderEventText = one] : one \in Sample(5) }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.orderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.orderEventQty = one] : one \in Sample(4) }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.tradeAddendum = one] : one \in Sample(1) }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.orderEventReason = one] : one \in Sample(1) }
        \cup { [ZeroSpreadTradeEventsGroup EXCEPT !.originalOrderEventExecId = one] : one \in Sample(4) }

(* A run of Spread Trade Events Group, written one after another *)
RECURSIVE EncodeSpreadTradeEventsGroupList(_)
EncodeSpreadTradeEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSpreadTradeEventsGroup(Head(messages)) \o EncodeSpreadTradeEventsGroupList(Tail(messages))

(* As many Spread Trade Events Group as the field that counts them says *)
RECURSIVE ReadSpreadTradeEventsGroupList(_, _)
ReadSpreadTradeEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSpreadTradeEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSpreadTradeEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Spread Trade Events Group of each kind, for the lists that carry them *)
OneSpreadTradeEventsGroup == { ZeroSpreadTradeEventsGroup }

(***************************************************************************)
(* Spread Trade Events Groups                                              *)
(***************************************************************************)

SpreadTradeEventsGroups ==
    [ blockLength            : Sample(2),
      spreadTradeEventsGroup : SampleLists(OneSpreadTradeEventsGroup) ]

EncodeSpreadTradeEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.spreadTradeEventsGroup), 1)
        \o EncodeSpreadTradeEventsGroupList(message.spreadTradeEventsGroup)

DecodeSpreadTradeEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET spreadTradeEventsGroup == ReadSpreadTradeEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~spreadTradeEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         spreadTradeEventsGroup |-> spreadTradeEventsGroup.value ], spreadTradeEventsGroup.rest)

ZeroSpreadTradeEventsGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      spreadTradeEventsGroup |-> << >> ]

(* Spread Trade Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedSpreadTradeEventsGroups ==
    { ZeroSpreadTradeEventsGroups }
        \cup { [ZeroSpreadTradeEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSpreadTradeEventsGroups EXCEPT !.spreadTradeEventsGroup = one] : one \in SampleLists(OneSpreadTradeEventsGroup) }

(***************************************************************************)
(* Execution Report Trade Addendum Spread                                  *)
(***************************************************************************)

ExecutionReportTradeAddendumSpread ==
    [ seqNum                   : Sample(4),
      uuid                     : Sample(8),
      execId                   : Sample(40),
      senderId                 : Sample(20),
      clordid                  : Sample(20),
      partyDetailsListReqId    : Sample(8),
      lastPx                   : Sample(8),
      orderId                  : Sample(8),
      transactTime             : Sample(8),
      sendingTimeEpoch         : Sample(8),
      secExecId                : Sample(8),
      origSecondaryExecutionId : Sample(8),
      location                 : Sample(5),
      securityId               : Sample(4),
      mdTradeEntryId           : Sample(4),
      lastQty                  : Sample(4),
      sideTradeId              : Sample(4),
      origSideTradeId          : Sample(4),
      tradeDate                : Sample(2),
      ordStatusTrdCxl          : Sample(1),
      execType                 : Sample(1),
      ordTypeOptional          : Sample(1),
      side                     : Sample(1),
      manualOrderIndicator     : Sample(1),
      possRetransFlag          : Sample(1),
      totalNumSecurities       : Sample(1),
      execInst                 : Sample(1),
      executionMode            : Sample(1),
      liquidityFlag            : Sample(1),
      managedOrder             : Sample(1),
      shortSaleType            : Sample(1),
      fillsGroups              : FillsGroups5,
      tradeAddendumLegsGroups  : TradeAddendumLegsGroups,
      spreadTradeEventsGroups  : SpreadTradeEventsGroups ]

EncodeExecutionReportTradeAddendumSpread(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.lastPx
        \o message.orderId
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.secExecId
        \o message.origSecondaryExecutionId
        \o message.location
        \o message.securityId
        \o message.mdTradeEntryId
        \o message.lastQty
        \o message.sideTradeId
        \o message.origSideTradeId
        \o message.tradeDate
        \o message.ordStatusTrdCxl
        \o message.execType
        \o message.ordTypeOptional
        \o message.side
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.totalNumSecurities
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o EncodeFillsGroups5(message.fillsGroups)
        \o EncodeTradeAddendumLegsGroups(message.tradeAddendumLegsGroups)
        \o EncodeSpreadTradeEventsGroups(message.spreadTradeEventsGroups)

DecodeExecutionReportTradeAddendumSpread(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET secExecId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET origSecondaryExecutionId == ReadBytes(secExecId.rest, 8) IN IF ~origSecondaryExecutionId.ok THEN Fail ELSE
    LET location == ReadBytes(origSecondaryExecutionId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET mdTradeEntryId == ReadBytes(securityId.rest, 4) IN IF ~mdTradeEntryId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(mdTradeEntryId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(lastQty.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET origSideTradeId == ReadBytes(sideTradeId.rest, 4) IN IF ~origSideTradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(origSideTradeId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET ordStatusTrdCxl == ReadBytes(tradeDate.rest, 1) IN IF ~ordStatusTrdCxl.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatusTrdCxl.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(execType.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(side.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET totalNumSecurities == ReadBytes(possRetransFlag.rest, 1) IN IF ~totalNumSecurities.ok THEN Fail ELSE
    LET execInst == ReadBytes(totalNumSecurities.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET fillsGroups == DecodeFillsGroups5(shortSaleType.rest) IN IF ~fillsGroups.ok THEN Fail ELSE
    LET tradeAddendumLegsGroups == DecodeTradeAddendumLegsGroups(fillsGroups.rest) IN IF ~tradeAddendumLegsGroups.ok THEN Fail ELSE
    LET spreadTradeEventsGroups == DecodeSpreadTradeEventsGroups(tradeAddendumLegsGroups.rest) IN IF ~spreadTradeEventsGroups.ok THEN Fail ELSE
    Ok([ seqNum                   |-> seqNum.value,
         uuid                     |-> uuid.value,
         execId                   |-> execId.value,
         senderId                 |-> senderId.value,
         clordid                  |-> clordid.value,
         partyDetailsListReqId    |-> partyDetailsListReqId.value,
         lastPx                   |-> lastPx.value,
         orderId                  |-> orderId.value,
         transactTime             |-> transactTime.value,
         sendingTimeEpoch         |-> sendingTimeEpoch.value,
         secExecId                |-> secExecId.value,
         origSecondaryExecutionId |-> origSecondaryExecutionId.value,
         location                 |-> location.value,
         securityId               |-> securityId.value,
         mdTradeEntryId           |-> mdTradeEntryId.value,
         lastQty                  |-> lastQty.value,
         sideTradeId              |-> sideTradeId.value,
         origSideTradeId          |-> origSideTradeId.value,
         tradeDate                |-> tradeDate.value,
         ordStatusTrdCxl          |-> ordStatusTrdCxl.value,
         execType                 |-> execType.value,
         ordTypeOptional          |-> ordTypeOptional.value,
         side                     |-> side.value,
         manualOrderIndicator     |-> manualOrderIndicator.value,
         possRetransFlag          |-> possRetransFlag.value,
         totalNumSecurities       |-> totalNumSecurities.value,
         execInst                 |-> execInst.value,
         executionMode            |-> executionMode.value,
         liquidityFlag            |-> liquidityFlag.value,
         managedOrder             |-> managedOrder.value,
         shortSaleType            |-> shortSaleType.value,
         fillsGroups              |-> fillsGroups.value,
         tradeAddendumLegsGroups  |-> tradeAddendumLegsGroups.value,
         spreadTradeEventsGroups  |-> spreadTradeEventsGroups.value ], spreadTradeEventsGroups.rest)

ZeroExecutionReportTradeAddendumSpread ==
    [ seqNum                   |-> [i \in 1 .. 4 |-> 0],
      uuid                     |-> [i \in 1 .. 8 |-> 0],
      execId                   |-> [i \in 1 .. 40 |-> 0],
      senderId                 |-> [i \in 1 .. 20 |-> 0],
      clordid                  |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId    |-> [i \in 1 .. 8 |-> 0],
      lastPx                   |-> [i \in 1 .. 8 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      transactTime             |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch         |-> [i \in 1 .. 8 |-> 0],
      secExecId                |-> [i \in 1 .. 8 |-> 0],
      origSecondaryExecutionId |-> [i \in 1 .. 8 |-> 0],
      location                 |-> [i \in 1 .. 5 |-> 0],
      securityId               |-> [i \in 1 .. 4 |-> 0],
      mdTradeEntryId           |-> [i \in 1 .. 4 |-> 0],
      lastQty                  |-> [i \in 1 .. 4 |-> 0],
      sideTradeId              |-> [i \in 1 .. 4 |-> 0],
      origSideTradeId          |-> [i \in 1 .. 4 |-> 0],
      tradeDate                |-> [i \in 1 .. 2 |-> 0],
      ordStatusTrdCxl          |-> [i \in 1 .. 1 |-> 0],
      execType                 |-> [i \in 1 .. 1 |-> 0],
      ordTypeOptional          |-> [i \in 1 .. 1 |-> 0],
      side                     |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator     |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag          |-> [i \in 1 .. 1 |-> 0],
      totalNumSecurities       |-> [i \in 1 .. 1 |-> 0],
      execInst                 |-> [i \in 1 .. 1 |-> 0],
      executionMode            |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag            |-> [i \in 1 .. 1 |-> 0],
      managedOrder             |-> [i \in 1 .. 1 |-> 0],
      shortSaleType            |-> [i \in 1 .. 1 |-> 0],
      fillsGroups              |-> ZeroFillsGroups5,
      tradeAddendumLegsGroups  |-> ZeroTradeAddendumLegsGroups,
      spreadTradeEventsGroups  |-> ZeroSpreadTradeEventsGroups ]

(* Execution Report Trade Addendum Spread at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeAddendumSpread ==
    { ZeroExecutionReportTradeAddendumSpread }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.origSecondaryExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.mdTradeEntryId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.origSideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.ordStatusTrdCxl = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.totalNumSecurities = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.fillsGroups = one] : one \in CheckedFillsGroups5 }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.tradeAddendumLegsGroups = one] : one \in CheckedTradeAddendumLegsGroups }
        \cup { [ZeroExecutionReportTradeAddendumSpread EXCEPT !.spreadTradeEventsGroups = one] : one \in CheckedSpreadTradeEventsGroups }

(***************************************************************************)
(* Calculated Ccy Last Qty: 9 bytes                                        *)
(***************************************************************************)

CalculatedCcyLastQty4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeCalculatedCcyLastQty4(message) ==
    message.mantissa
        \o message.exponent

DecodeCalculatedCcyLastQty4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroCalculatedCcyLastQty4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Calculated Ccy Last Qty at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedCcyLastQty4 ==
    { ZeroCalculatedCcyLastQty4 }
        \cup { [ZeroCalculatedCcyLastQty4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedCcyLastQty4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Gross Trade Amt: 9 bytes                                                *)
(***************************************************************************)

GrossTradeAmt4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeGrossTradeAmt4(message) ==
    message.mantissa
        \o message.exponent

DecodeGrossTradeAmt4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroGrossTradeAmt4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Gross Trade Amt at zero, then each field in turn at the values it is checked at *)
CheckedGrossTradeAmt4 ==
    { ZeroGrossTradeAmt4 }
        \cup { [ZeroGrossTradeAmt4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroGrossTradeAmt4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Group: 15 bytes                                                   *)
(***************************************************************************)

FillsGroup6 ==
    [ fillPx        : Sample(8),
      fillQty       : Sample(4),
      fillExecId    : Sample(2),
      fillYieldType : Sample(1) ]

EncodeFillsGroup6(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillExecId
        \o message.fillYieldType

DecodeFillsGroup6(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillQty.rest, 2) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillYieldType == ReadBytes(fillExecId.rest, 1) IN IF ~fillYieldType.ok THEN Fail ELSE
    Ok([ fillPx        |-> fillPx.value,
         fillQty       |-> fillQty.value,
         fillExecId    |-> fillExecId.value,
         fillYieldType |-> fillYieldType.value ], fillYieldType.rest)

ZeroFillsGroup6 ==
    [ fillPx        |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      fillExecId    |-> [i \in 1 .. 2 |-> 0],
      fillYieldType |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Group at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroup6 ==
    { ZeroFillsGroup6 }
        \cup { [ZeroFillsGroup6 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGroup6 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGroup6 EXCEPT !.fillExecId = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroup6 EXCEPT !.fillYieldType = one] : one \in Sample(1) }

(* A run of Fills Group, written one after another *)
RECURSIVE EncodeFillsGroup6List(_)
EncodeFillsGroup6List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGroup6(Head(messages)) \o EncodeFillsGroup6List(Tail(messages))

(* As many Fills Group as the field that counts them says *)
RECURSIVE ReadFillsGroup6List(_, _)
ReadFillsGroup6List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGroup6(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGroup6List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Group of each kind, for the lists that carry them *)
OneFillsGroup6 == { ZeroFillsGroup6 }

(***************************************************************************)
(* Fills Groups                                                            *)
(***************************************************************************)

FillsGroups6 ==
    [ blockLength : Sample(2),
      fillsGroup  : SampleLists(OneFillsGroup6) ]

EncodeFillsGroups6(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.fillsGroup), 1)
        \o EncodeFillsGroup6List(message.fillsGroup)

DecodeFillsGroups6(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillsGroup == ReadFillsGroup6List(numInGroup.rest, numInGroup.value) IN IF ~fillsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         fillsGroup  |-> fillsGroup.value ], fillsGroup.rest)

ZeroFillsGroups6 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      fillsGroup  |-> << >> ]

(* Fills Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillsGroups6 ==
    { ZeroFillsGroups6 }
        \cup { [ZeroFillsGroups6 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFillsGroups6 EXCEPT !.fillsGroup = one] : one \in SampleLists(OneFillsGroup6) }

(***************************************************************************)
(* Spread Leg Trade Events Group: 27 bytes                                 *)
(***************************************************************************)

SpreadLegTradeEventsGroup ==
    [ orderEventPx             : Sample(8),
      orderEventText           : Sample(5),
      orderEventExecId         : Sample(4),
      orderEventQty            : Sample(4),
      tradeAddendum            : Sample(1),
      orderEventReason         : Sample(1),
      originalOrderEventExecId : Sample(4) ]

EncodeSpreadLegTradeEventsGroup(message) ==
    message.orderEventPx
        \o message.orderEventText
        \o message.orderEventExecId
        \o message.orderEventQty
        \o message.tradeAddendum
        \o message.orderEventReason
        \o message.originalOrderEventExecId

DecodeSpreadLegTradeEventsGroup(bytes) ==
    LET orderEventPx == ReadBytes(bytes, 8) IN IF ~orderEventPx.ok THEN Fail ELSE
    LET orderEventText == ReadBytes(orderEventPx.rest, 5) IN IF ~orderEventText.ok THEN Fail ELSE
    LET orderEventExecId == ReadBytes(orderEventText.rest, 4) IN IF ~orderEventExecId.ok THEN Fail ELSE
    LET orderEventQty == ReadBytes(orderEventExecId.rest, 4) IN IF ~orderEventQty.ok THEN Fail ELSE
    LET tradeAddendum == ReadBytes(orderEventQty.rest, 1) IN IF ~tradeAddendum.ok THEN Fail ELSE
    LET orderEventReason == ReadBytes(tradeAddendum.rest, 1) IN IF ~orderEventReason.ok THEN Fail ELSE
    LET originalOrderEventExecId == ReadBytes(orderEventReason.rest, 4) IN IF ~originalOrderEventExecId.ok THEN Fail ELSE
    Ok([ orderEventPx             |-> orderEventPx.value,
         orderEventText           |-> orderEventText.value,
         orderEventExecId         |-> orderEventExecId.value,
         orderEventQty            |-> orderEventQty.value,
         tradeAddendum            |-> tradeAddendum.value,
         orderEventReason         |-> orderEventReason.value,
         originalOrderEventExecId |-> originalOrderEventExecId.value ], originalOrderEventExecId.rest)

ZeroSpreadLegTradeEventsGroup ==
    [ orderEventPx             |-> [i \in 1 .. 8 |-> 0],
      orderEventText           |-> [i \in 1 .. 5 |-> 0],
      orderEventExecId         |-> [i \in 1 .. 4 |-> 0],
      orderEventQty            |-> [i \in 1 .. 4 |-> 0],
      tradeAddendum            |-> [i \in 1 .. 1 |-> 0],
      orderEventReason         |-> [i \in 1 .. 1 |-> 0],
      originalOrderEventExecId |-> [i \in 1 .. 4 |-> 0] ]

(* Spread Leg Trade Events Group at zero, then each field in turn at the values it is checked at *)
CheckedSpreadLegTradeEventsGroup ==
    { ZeroSpreadLegTradeEventsGroup }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.orderEventPx = one] : one \in Sample(8) }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.orderEventText = one] : one \in Sample(5) }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.orderEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.orderEventQty = one] : one \in Sample(4) }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.tradeAddendum = one] : one \in Sample(1) }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.orderEventReason = one] : one \in Sample(1) }
        \cup { [ZeroSpreadLegTradeEventsGroup EXCEPT !.originalOrderEventExecId = one] : one \in Sample(4) }

(* A run of Spread Leg Trade Events Group, written one after another *)
RECURSIVE EncodeSpreadLegTradeEventsGroupList(_)
EncodeSpreadLegTradeEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSpreadLegTradeEventsGroup(Head(messages)) \o EncodeSpreadLegTradeEventsGroupList(Tail(messages))

(* As many Spread Leg Trade Events Group as the field that counts them says *)
RECURSIVE ReadSpreadLegTradeEventsGroupList(_, _)
ReadSpreadLegTradeEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSpreadLegTradeEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSpreadLegTradeEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Spread Leg Trade Events Group of each kind, for the lists that carry them *)
OneSpreadLegTradeEventsGroup == { ZeroSpreadLegTradeEventsGroup }

(***************************************************************************)
(* Spread Leg Trade Events Groups                                          *)
(***************************************************************************)

SpreadLegTradeEventsGroups ==
    [ blockLength               : Sample(2),
      spreadLegTradeEventsGroup : SampleLists(OneSpreadLegTradeEventsGroup) ]

EncodeSpreadLegTradeEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.spreadLegTradeEventsGroup), 1)
        \o EncodeSpreadLegTradeEventsGroupList(message.spreadLegTradeEventsGroup)

DecodeSpreadLegTradeEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET spreadLegTradeEventsGroup == ReadSpreadLegTradeEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~spreadLegTradeEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength               |-> blockLength.value,
         spreadLegTradeEventsGroup |-> spreadLegTradeEventsGroup.value ], spreadLegTradeEventsGroup.rest)

ZeroSpreadLegTradeEventsGroups ==
    [ blockLength               |-> [i \in 1 .. 2 |-> 0],
      spreadLegTradeEventsGroup |-> << >> ]

(* Spread Leg Trade Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedSpreadLegTradeEventsGroups ==
    { ZeroSpreadLegTradeEventsGroups }
        \cup { [ZeroSpreadLegTradeEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSpreadLegTradeEventsGroups EXCEPT !.spreadLegTradeEventsGroup = one] : one \in SampleLists(OneSpreadLegTradeEventsGroup) }

(***************************************************************************)
(* Execution Report Trade Addendum Spread Leg                              *)
(***************************************************************************)

ExecutionReportTradeAddendumSpreadLeg ==
    [ seqNum                     : Sample(4),
      uuid                       : Sample(8),
      execId                     : Sample(40),
      senderId                   : Sample(20),
      clordid                    : Sample(20),
      partyDetailsListReqId      : Sample(8),
      lastPx                     : Sample(8),
      orderId                    : Sample(8),
      transactTime               : Sample(8),
      sendingTimeEpoch           : Sample(8),
      secExecId                  : Sample(8),
      origSecondaryExecutionId   : Sample(8),
      location                   : Sample(5),
      securityId                 : Sample(4),
      lastQty                    : Sample(4),
      sideTradeId                : Sample(4),
      origSideTradeId            : Sample(4),
      tradeDate                  : Sample(2),
      ordStatusTrdCxl            : Sample(1),
      execType                   : Sample(1),
      manualOrderIndicator       : Sample(1),
      possRetransFlag            : Sample(1),
      side                       : Sample(1),
      settlDate                  : Sample(2),
      calculatedCcyLastQty       : CalculatedCcyLastQty4,
      grossTradeAmt              : GrossTradeAmt4,
      fillsGroups                : FillsGroups6,
      spreadLegTradeEventsGroups : SpreadLegTradeEventsGroups ]

EncodeExecutionReportTradeAddendumSpreadLeg(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.lastPx
        \o message.orderId
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.secExecId
        \o message.origSecondaryExecutionId
        \o message.location
        \o message.securityId
        \o message.lastQty
        \o message.sideTradeId
        \o message.origSideTradeId
        \o message.tradeDate
        \o message.ordStatusTrdCxl
        \o message.execType
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.side
        \o message.settlDate
        \o EncodeCalculatedCcyLastQty4(message.calculatedCcyLastQty)
        \o EncodeGrossTradeAmt4(message.grossTradeAmt)
        \o EncodeFillsGroups6(message.fillsGroups)
        \o EncodeSpreadLegTradeEventsGroups(message.spreadLegTradeEventsGroups)

DecodeExecutionReportTradeAddendumSpreadLeg(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET secExecId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET origSecondaryExecutionId == ReadBytes(secExecId.rest, 8) IN IF ~origSecondaryExecutionId.ok THEN Fail ELSE
    LET location == ReadBytes(origSecondaryExecutionId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(lastQty.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET origSideTradeId == ReadBytes(sideTradeId.rest, 4) IN IF ~origSideTradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(origSideTradeId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET ordStatusTrdCxl == ReadBytes(tradeDate.rest, 1) IN IF ~ordStatusTrdCxl.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatusTrdCxl.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(execType.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET side == ReadBytes(possRetransFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET settlDate == ReadBytes(side.rest, 2) IN IF ~settlDate.ok THEN Fail ELSE
    LET calculatedCcyLastQty == DecodeCalculatedCcyLastQty4(settlDate.rest) IN IF ~calculatedCcyLastQty.ok THEN Fail ELSE
    LET grossTradeAmt == DecodeGrossTradeAmt4(calculatedCcyLastQty.rest) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET fillsGroups == DecodeFillsGroups6(grossTradeAmt.rest) IN IF ~fillsGroups.ok THEN Fail ELSE
    LET spreadLegTradeEventsGroups == DecodeSpreadLegTradeEventsGroups(fillsGroups.rest) IN IF ~spreadLegTradeEventsGroups.ok THEN Fail ELSE
    Ok([ seqNum                     |-> seqNum.value,
         uuid                       |-> uuid.value,
         execId                     |-> execId.value,
         senderId                   |-> senderId.value,
         clordid                    |-> clordid.value,
         partyDetailsListReqId      |-> partyDetailsListReqId.value,
         lastPx                     |-> lastPx.value,
         orderId                    |-> orderId.value,
         transactTime               |-> transactTime.value,
         sendingTimeEpoch           |-> sendingTimeEpoch.value,
         secExecId                  |-> secExecId.value,
         origSecondaryExecutionId   |-> origSecondaryExecutionId.value,
         location                   |-> location.value,
         securityId                 |-> securityId.value,
         lastQty                    |-> lastQty.value,
         sideTradeId                |-> sideTradeId.value,
         origSideTradeId            |-> origSideTradeId.value,
         tradeDate                  |-> tradeDate.value,
         ordStatusTrdCxl            |-> ordStatusTrdCxl.value,
         execType                   |-> execType.value,
         manualOrderIndicator       |-> manualOrderIndicator.value,
         possRetransFlag            |-> possRetransFlag.value,
         side                       |-> side.value,
         settlDate                  |-> settlDate.value,
         calculatedCcyLastQty       |-> calculatedCcyLastQty.value,
         grossTradeAmt              |-> grossTradeAmt.value,
         fillsGroups                |-> fillsGroups.value,
         spreadLegTradeEventsGroups |-> spreadLegTradeEventsGroups.value ], spreadLegTradeEventsGroups.rest)

ZeroExecutionReportTradeAddendumSpreadLeg ==
    [ seqNum                     |-> [i \in 1 .. 4 |-> 0],
      uuid                       |-> [i \in 1 .. 8 |-> 0],
      execId                     |-> [i \in 1 .. 40 |-> 0],
      senderId                   |-> [i \in 1 .. 20 |-> 0],
      clordid                    |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId      |-> [i \in 1 .. 8 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      orderId                    |-> [i \in 1 .. 8 |-> 0],
      transactTime               |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch           |-> [i \in 1 .. 8 |-> 0],
      secExecId                  |-> [i \in 1 .. 8 |-> 0],
      origSecondaryExecutionId   |-> [i \in 1 .. 8 |-> 0],
      location                   |-> [i \in 1 .. 5 |-> 0],
      securityId                 |-> [i \in 1 .. 4 |-> 0],
      lastQty                    |-> [i \in 1 .. 4 |-> 0],
      sideTradeId                |-> [i \in 1 .. 4 |-> 0],
      origSideTradeId            |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      ordStatusTrdCxl            |-> [i \in 1 .. 1 |-> 0],
      execType                   |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator       |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag            |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      settlDate                  |-> [i \in 1 .. 2 |-> 0],
      calculatedCcyLastQty       |-> ZeroCalculatedCcyLastQty4,
      grossTradeAmt              |-> ZeroGrossTradeAmt4,
      fillsGroups                |-> ZeroFillsGroups6,
      spreadLegTradeEventsGroups |-> ZeroSpreadLegTradeEventsGroups ]

(* Execution Report Trade Addendum Spread Leg at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeAddendumSpreadLeg ==
    { ZeroExecutionReportTradeAddendumSpreadLeg }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.origSecondaryExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.origSideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.ordStatusTrdCxl = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.settlDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.calculatedCcyLastQty = one] : one \in CheckedCalculatedCcyLastQty4 }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.grossTradeAmt = one] : one \in CheckedGrossTradeAmt4 }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.fillsGroups = one] : one \in CheckedFillsGroups6 }
        \cup { [ZeroExecutionReportTradeAddendumSpreadLeg EXCEPT !.spreadLegTradeEventsGroups = one] : one \in CheckedSpreadLegTradeEventsGroups }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear ==
    { ZeroMaturityMonthYear }
        \cup { [ZeroMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Option Delta: 5 bytes                                               *)
(***************************************************************************)

LegOptionDelta ==
    [ mantissa32 : Sample(4),
      exponent   : Sample(1) ]

EncodeLegOptionDelta(message) ==
    message.mantissa32
        \o message.exponent

DecodeLegOptionDelta(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa32.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa32 |-> mantissa32.value,
         exponent   |-> exponent.value ], exponent.rest)

ZeroLegOptionDelta ==
    [ mantissa32 |-> [i \in 1 .. 4 |-> 0],
      exponent   |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Option Delta at zero, then each field in turn at the values it is checked at *)
CheckedLegOptionDelta ==
    { ZeroLegOptionDelta }
        \cup { [ZeroLegOptionDelta EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroLegOptionDelta EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Response Legs Group: 19 bytes                                           *)
(***************************************************************************)

ResponseLegsGroup ==
    [ legPrice       : Sample(8),
      legOptionDelta : LegOptionDelta,
      legSecurityId  : Sample(4),
      legSide        : Sample(1),
      legRatioQty    : Sample(1) ]

EncodeResponseLegsGroup(message) ==
    message.legPrice
        \o EncodeLegOptionDelta(message.legOptionDelta)
        \o message.legSecurityId
        \o message.legSide
        \o message.legRatioQty

DecodeResponseLegsGroup(bytes) ==
    LET legPrice == ReadBytes(bytes, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legOptionDelta == DecodeLegOptionDelta(legPrice.rest) IN IF ~legOptionDelta.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legOptionDelta.rest, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSide.rest, 1) IN IF ~legRatioQty.ok THEN Fail ELSE
    Ok([ legPrice       |-> legPrice.value,
         legOptionDelta |-> legOptionDelta.value,
         legSecurityId  |-> legSecurityId.value,
         legSide        |-> legSide.value,
         legRatioQty    |-> legRatioQty.value ], legRatioQty.rest)

ZeroResponseLegsGroup ==
    [ legPrice       |-> [i \in 1 .. 8 |-> 0],
      legOptionDelta |-> ZeroLegOptionDelta,
      legSecurityId  |-> [i \in 1 .. 4 |-> 0],
      legSide        |-> [i \in 1 .. 1 |-> 0],
      legRatioQty    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedResponseLegsGroup ==
    { ZeroResponseLegsGroup }
        \cup { [ZeroResponseLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroResponseLegsGroup EXCEPT !.legOptionDelta = one] : one \in CheckedLegOptionDelta }
        \cup { [ZeroResponseLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroResponseLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroResponseLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(1) }

(* A run of Response Legs Group, written one after another *)
RECURSIVE EncodeResponseLegsGroupList(_)
EncodeResponseLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeResponseLegsGroup(Head(messages)) \o EncodeResponseLegsGroupList(Tail(messages))

(* As many Response Legs Group as the field that counts them says *)
RECURSIVE ReadResponseLegsGroupList(_, _)
ReadResponseLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeResponseLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadResponseLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Response Legs Group of each kind, for the lists that carry them *)
OneResponseLegsGroup == { ZeroResponseLegsGroup }

(***************************************************************************)
(* Response Legs Groups                                                    *)
(***************************************************************************)

ResponseLegsGroups ==
    [ blockLength       : Sample(2),
      responseLegsGroup : SampleLists(OneResponseLegsGroup) ]

EncodeResponseLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.responseLegsGroup), 1)
        \o EncodeResponseLegsGroupList(message.responseLegsGroup)

DecodeResponseLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET responseLegsGroup == ReadResponseLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~responseLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         responseLegsGroup |-> responseLegsGroup.value ], responseLegsGroup.rest)

ZeroResponseLegsGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      responseLegsGroup |-> << >> ]

(* Response Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedResponseLegsGroups ==
    { ZeroResponseLegsGroups }
        \cup { [ZeroResponseLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroResponseLegsGroups EXCEPT !.responseLegsGroup = one] : one \in SampleLists(OneResponseLegsGroup) }

(***************************************************************************)
(* Security Definition Response                                            *)
(***************************************************************************)

SecurityDefinitionResponse ==
    [ seqNum                      : Sample(4),
      uuid                        : Sample(8),
      text                        : Sample(256),
      financialInstrumentFullName : Sample(35),
      senderId                    : Sample(20),
      symbol                      : Sample(20),
      partyDetailsListReqId       : Sample(8),
      securityReqId               : Sample(8),
      securityResponseId          : Sample(8),
      sendingTimeEpoch            : Sample(8),
      securityGroup               : Sample(6),
      securityType                : Sample(6),
      location                    : Sample(5),
      securityIdOptional          : Sample(4),
      currency                    : Sample(3),
      maturityMonthYear           : MaturityMonthYear,
      delayDuration               : Sample(2),
      startDate                   : Sample(2),
      endDate                     : Sample(2),
      maxNoOfSubstitutions        : Sample(1),
      sourceRepoId                : Sample(4),
      terminationType             : Sample(8),
      securityResponseType        : Sample(1),
      expirationCycle             : Sample(1),
      manualOrderIndicator        : Sample(1),
      splitMsg                    : Sample(1),
      autoQuoteRequest            : Sample(1),
      possRetransFlag             : Sample(1),
      responseLegsGroups          : ResponseLegsGroups ]

EncodeSecurityDefinitionResponse(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.financialInstrumentFullName
        \o message.senderId
        \o message.symbol
        \o message.partyDetailsListReqId
        \o message.securityReqId
        \o message.securityResponseId
        \o message.sendingTimeEpoch
        \o message.securityGroup
        \o message.securityType
        \o message.location
        \o message.securityIdOptional
        \o message.currency
        \o EncodeMaturityMonthYear(message.maturityMonthYear)
        \o message.delayDuration
        \o message.startDate
        \o message.endDate
        \o message.maxNoOfSubstitutions
        \o message.sourceRepoId
        \o message.terminationType
        \o message.securityResponseType
        \o message.expirationCycle
        \o message.manualOrderIndicator
        \o message.splitMsg
        \o message.autoQuoteRequest
        \o message.possRetransFlag
        \o EncodeResponseLegsGroups(message.responseLegsGroups)

DecodeSecurityDefinitionResponse(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(text.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET senderId == ReadBytes(financialInstrumentFullName.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET symbol == ReadBytes(senderId.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(symbol.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityResponseId == ReadBytes(securityReqId.rest, 8) IN IF ~securityResponseId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(securityResponseId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(sendingTimeEpoch.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET location == ReadBytes(securityType.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(location.rest, 4) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET currency == ReadBytes(securityIdOptional.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear(currency.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(maturityMonthYear.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET startDate == ReadBytes(delayDuration.rest, 2) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 2) IN IF ~endDate.ok THEN Fail ELSE
    LET maxNoOfSubstitutions == ReadBytes(endDate.rest, 1) IN IF ~maxNoOfSubstitutions.ok THEN Fail ELSE
    LET sourceRepoId == ReadBytes(maxNoOfSubstitutions.rest, 4) IN IF ~sourceRepoId.ok THEN Fail ELSE
    LET terminationType == ReadBytes(sourceRepoId.rest, 8) IN IF ~terminationType.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(terminationType.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET expirationCycle == ReadBytes(securityResponseType.rest, 1) IN IF ~expirationCycle.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(expirationCycle.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET autoQuoteRequest == ReadBytes(splitMsg.rest, 1) IN IF ~autoQuoteRequest.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(autoQuoteRequest.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET responseLegsGroups == DecodeResponseLegsGroups(possRetransFlag.rest) IN IF ~responseLegsGroups.ok THEN Fail ELSE
    Ok([ seqNum                      |-> seqNum.value,
         uuid                        |-> uuid.value,
         text                        |-> text.value,
         financialInstrumentFullName |-> financialInstrumentFullName.value,
         senderId                    |-> senderId.value,
         symbol                      |-> symbol.value,
         partyDetailsListReqId       |-> partyDetailsListReqId.value,
         securityReqId               |-> securityReqId.value,
         securityResponseId          |-> securityResponseId.value,
         sendingTimeEpoch            |-> sendingTimeEpoch.value,
         securityGroup               |-> securityGroup.value,
         securityType                |-> securityType.value,
         location                    |-> location.value,
         securityIdOptional          |-> securityIdOptional.value,
         currency                    |-> currency.value,
         maturityMonthYear           |-> maturityMonthYear.value,
         delayDuration               |-> delayDuration.value,
         startDate                   |-> startDate.value,
         endDate                     |-> endDate.value,
         maxNoOfSubstitutions        |-> maxNoOfSubstitutions.value,
         sourceRepoId                |-> sourceRepoId.value,
         terminationType             |-> terminationType.value,
         securityResponseType        |-> securityResponseType.value,
         expirationCycle             |-> expirationCycle.value,
         manualOrderIndicator        |-> manualOrderIndicator.value,
         splitMsg                    |-> splitMsg.value,
         autoQuoteRequest            |-> autoQuoteRequest.value,
         possRetransFlag             |-> possRetransFlag.value,
         responseLegsGroups          |-> responseLegsGroups.value ], responseLegsGroups.rest)

ZeroSecurityDefinitionResponse ==
    [ seqNum                      |-> [i \in 1 .. 4 |-> 0],
      uuid                        |-> [i \in 1 .. 8 |-> 0],
      text                        |-> [i \in 1 .. 256 |-> 0],
      financialInstrumentFullName |-> [i \in 1 .. 35 |-> 0],
      senderId                    |-> [i \in 1 .. 20 |-> 0],
      symbol                      |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId       |-> [i \in 1 .. 8 |-> 0],
      securityReqId               |-> [i \in 1 .. 8 |-> 0],
      securityResponseId          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch            |-> [i \in 1 .. 8 |-> 0],
      securityGroup               |-> [i \in 1 .. 6 |-> 0],
      securityType                |-> [i \in 1 .. 6 |-> 0],
      location                    |-> [i \in 1 .. 5 |-> 0],
      securityIdOptional          |-> [i \in 1 .. 4 |-> 0],
      currency                    |-> [i \in 1 .. 3 |-> 0],
      maturityMonthYear           |-> ZeroMaturityMonthYear,
      delayDuration               |-> [i \in 1 .. 2 |-> 0],
      startDate                   |-> [i \in 1 .. 2 |-> 0],
      endDate                     |-> [i \in 1 .. 2 |-> 0],
      maxNoOfSubstitutions        |-> [i \in 1 .. 1 |-> 0],
      sourceRepoId                |-> [i \in 1 .. 4 |-> 0],
      terminationType             |-> [i \in 1 .. 8 |-> 0],
      securityResponseType        |-> [i \in 1 .. 1 |-> 0],
      expirationCycle             |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator        |-> [i \in 1 .. 1 |-> 0],
      splitMsg                    |-> [i \in 1 .. 1 |-> 0],
      autoQuoteRequest            |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag             |-> [i \in 1 .. 1 |-> 0],
      responseLegsGroups          |-> ZeroResponseLegsGroups ]

(* Security Definition Response at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionResponse ==
    { ZeroSecurityDefinitionResponse }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.securityReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.securityResponseId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.securityIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.startDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.endDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.maxNoOfSubstitutions = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.sourceRepoId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.terminationType = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.expirationCycle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.autoQuoteRequest = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponse EXCEPT !.responseLegsGroups = one] : one \in CheckedResponseLegsGroups }

(***************************************************************************)
(* Quote Cancel Ack Entries Group: 9 bytes                                 *)
(***************************************************************************)

QuoteCancelAckEntriesGroup ==
    [ quoteEntryId           : Sample(4),
      securityId             : Sample(4),
      quoteEntryRejectReason : Sample(1) ]

EncodeQuoteCancelAckEntriesGroup(message) ==
    message.quoteEntryId
        \o message.securityId
        \o message.quoteEntryRejectReason

DecodeQuoteCancelAckEntriesGroup(bytes) ==
    LET quoteEntryId == ReadBytes(bytes, 4) IN IF ~quoteEntryId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteEntryId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteEntryRejectReason == ReadBytes(securityId.rest, 1) IN IF ~quoteEntryRejectReason.ok THEN Fail ELSE
    Ok([ quoteEntryId           |-> quoteEntryId.value,
         securityId             |-> securityId.value,
         quoteEntryRejectReason |-> quoteEntryRejectReason.value ], quoteEntryRejectReason.rest)

ZeroQuoteCancelAckEntriesGroup ==
    [ quoteEntryId           |-> [i \in 1 .. 4 |-> 0],
      securityId             |-> [i \in 1 .. 4 |-> 0],
      quoteEntryRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Cancel Ack Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelAckEntriesGroup ==
    { ZeroQuoteCancelAckEntriesGroup }
        \cup { [ZeroQuoteCancelAckEntriesGroup EXCEPT !.quoteEntryId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelAckEntriesGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelAckEntriesGroup EXCEPT !.quoteEntryRejectReason = one] : one \in Sample(1) }

(* A run of Quote Cancel Ack Entries Group, written one after another *)
RECURSIVE EncodeQuoteCancelAckEntriesGroupList(_)
EncodeQuoteCancelAckEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteCancelAckEntriesGroup(Head(messages)) \o EncodeQuoteCancelAckEntriesGroupList(Tail(messages))

(* As many Quote Cancel Ack Entries Group as the field that counts them says *)
RECURSIVE ReadQuoteCancelAckEntriesGroupList(_, _)
ReadQuoteCancelAckEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteCancelAckEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteCancelAckEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Cancel Ack Entries Group of each kind, for the lists that carry them *)
OneQuoteCancelAckEntriesGroup == { ZeroQuoteCancelAckEntriesGroup }

(***************************************************************************)
(* Quote Cancel Ack Entries Groups                                         *)
(***************************************************************************)

QuoteCancelAckEntriesGroups ==
    [ blockLength                : Sample(2),
      quoteCancelAckEntriesGroup : SampleLists(OneQuoteCancelAckEntriesGroup) ]

EncodeQuoteCancelAckEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.quoteCancelAckEntriesGroup), 1)
        \o EncodeQuoteCancelAckEntriesGroupList(message.quoteCancelAckEntriesGroup)

DecodeQuoteCancelAckEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteCancelAckEntriesGroup == ReadQuoteCancelAckEntriesGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteCancelAckEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength                |-> blockLength.value,
         quoteCancelAckEntriesGroup |-> quoteCancelAckEntriesGroup.value ], quoteCancelAckEntriesGroup.rest)

ZeroQuoteCancelAckEntriesGroups ==
    [ blockLength                |-> [i \in 1 .. 2 |-> 0],
      quoteCancelAckEntriesGroup |-> << >> ]

(* Quote Cancel Ack Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelAckEntriesGroups ==
    { ZeroQuoteCancelAckEntriesGroups }
        \cup { [ZeroQuoteCancelAckEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelAckEntriesGroups EXCEPT !.quoteCancelAckEntriesGroup = one] : one \in SampleLists(OneQuoteCancelAckEntriesGroup) }

(***************************************************************************)
(* Quote Cancel Ack Sets Group: 4 bytes                                    *)
(***************************************************************************)

QuoteCancelAckSetsGroup ==
    [ quoteSetId     : Sample(2),
      quoteErrorCode : Sample(2) ]

EncodeQuoteCancelAckSetsGroup(message) ==
    message.quoteSetId
        \o message.quoteErrorCode

DecodeQuoteCancelAckSetsGroup(bytes) ==
    LET quoteSetId == ReadBytes(bytes, 2) IN IF ~quoteSetId.ok THEN Fail ELSE
    LET quoteErrorCode == ReadBytes(quoteSetId.rest, 2) IN IF ~quoteErrorCode.ok THEN Fail ELSE
    Ok([ quoteSetId     |-> quoteSetId.value,
         quoteErrorCode |-> quoteErrorCode.value ], quoteErrorCode.rest)

ZeroQuoteCancelAckSetsGroup ==
    [ quoteSetId     |-> [i \in 1 .. 2 |-> 0],
      quoteErrorCode |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Cancel Ack Sets Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelAckSetsGroup ==
    { ZeroQuoteCancelAckSetsGroup }
        \cup { [ZeroQuoteCancelAckSetsGroup EXCEPT !.quoteSetId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelAckSetsGroup EXCEPT !.quoteErrorCode = one] : one \in Sample(2) }

(* A run of Quote Cancel Ack Sets Group, written one after another *)
RECURSIVE EncodeQuoteCancelAckSetsGroupList(_)
EncodeQuoteCancelAckSetsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteCancelAckSetsGroup(Head(messages)) \o EncodeQuoteCancelAckSetsGroupList(Tail(messages))

(* As many Quote Cancel Ack Sets Group as the field that counts them says *)
RECURSIVE ReadQuoteCancelAckSetsGroupList(_, _)
ReadQuoteCancelAckSetsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteCancelAckSetsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteCancelAckSetsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Cancel Ack Sets Group of each kind, for the lists that carry them *)
OneQuoteCancelAckSetsGroup == { ZeroQuoteCancelAckSetsGroup }

(***************************************************************************)
(* Quote Cancel Ack Sets Groups                                            *)
(***************************************************************************)

QuoteCancelAckSetsGroups ==
    [ blockLength             : Sample(2),
      quoteCancelAckSetsGroup : SampleLists(OneQuoteCancelAckSetsGroup) ]

EncodeQuoteCancelAckSetsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.quoteCancelAckSetsGroup), 1)
        \o EncodeQuoteCancelAckSetsGroupList(message.quoteCancelAckSetsGroup)

DecodeQuoteCancelAckSetsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteCancelAckSetsGroup == ReadQuoteCancelAckSetsGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteCancelAckSetsGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         quoteCancelAckSetsGroup |-> quoteCancelAckSetsGroup.value ], quoteCancelAckSetsGroup.rest)

ZeroQuoteCancelAckSetsGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      quoteCancelAckSetsGroup |-> << >> ]

(* Quote Cancel Ack Sets Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelAckSetsGroups ==
    { ZeroQuoteCancelAckSetsGroups }
        \cup { [ZeroQuoteCancelAckSetsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelAckSetsGroups EXCEPT !.quoteCancelAckSetsGroup = one] : one \in SampleLists(OneQuoteCancelAckSetsGroup) }

(***************************************************************************)
(* Quote Cancel Ack                                                        *)
(***************************************************************************)

QuoteCancelAck ==
    [ seqNum                      : Sample(4),
      uuid                        : Sample(8),
      text                        : Sample(256),
      senderId                    : Sample(20),
      partyDetailsListReqId       : Sample(8),
      requestTime                 : Sample(8),
      sendingTimeEpoch            : Sample(8),
      cancelledSymbol             : Sample(6),
      location                    : Sample(5),
      quoteId                     : Sample(4),
      quoteRejectReason           : Sample(2),
      delayDuration               : Sample(2),
      manualOrderIndicator        : Sample(1),
      quoteCxlStatus              : Sample(1),
      noProcessedEntries32        : Sample(4),
      mmProtectionReset           : Sample(1),
      unsolicitedCancelType       : Sample(1),
      splitMsg                    : Sample(1),
      totNoQuoteEntriesOptional   : Sample(1),
      liquidityFlag               : Sample(1),
      possRetransFlag             : Sample(1),
      delayToTime                 : Sample(8),
      quoteCancelAckEntriesGroups : QuoteCancelAckEntriesGroups,
      quoteCancelAckSetsGroups    : QuoteCancelAckSetsGroups ]

EncodeQuoteCancelAck(message) ==
    message.seqNum
        \o message.uuid
        \o message.text
        \o message.senderId
        \o message.partyDetailsListReqId
        \o message.requestTime
        \o message.sendingTimeEpoch
        \o message.cancelledSymbol
        \o message.location
        \o message.quoteId
        \o message.quoteRejectReason
        \o message.delayDuration
        \o message.manualOrderIndicator
        \o message.quoteCxlStatus
        \o message.noProcessedEntries32
        \o message.mmProtectionReset
        \o message.unsolicitedCancelType
        \o message.splitMsg
        \o message.totNoQuoteEntriesOptional
        \o message.liquidityFlag
        \o message.possRetransFlag
        \o message.delayToTime
        \o EncodeQuoteCancelAckEntriesGroups(message.quoteCancelAckEntriesGroups)
        \o EncodeQuoteCancelAckSetsGroups(message.quoteCancelAckSetsGroups)

DecodeQuoteCancelAck(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET text == ReadBytes(uuid.rest, 256) IN IF ~text.ok THEN Fail ELSE
    LET senderId == ReadBytes(text.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(senderId.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET requestTime == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(requestTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET cancelledSymbol == ReadBytes(sendingTimeEpoch.rest, 6) IN IF ~cancelledSymbol.ok THEN Fail ELSE
    LET location == ReadBytes(cancelledSymbol.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET quoteId == ReadBytes(location.rest, 4) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteId.rest, 2) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET delayDuration == ReadBytes(quoteRejectReason.rest, 2) IN IF ~delayDuration.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(delayDuration.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET quoteCxlStatus == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~quoteCxlStatus.ok THEN Fail ELSE
    LET noProcessedEntries32 == ReadBytes(quoteCxlStatus.rest, 4) IN IF ~noProcessedEntries32.ok THEN Fail ELSE
    LET mmProtectionReset == ReadBytes(noProcessedEntries32.rest, 1) IN IF ~mmProtectionReset.ok THEN Fail ELSE
    LET unsolicitedCancelType == ReadBytes(mmProtectionReset.rest, 1) IN IF ~unsolicitedCancelType.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(unsolicitedCancelType.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET totNoQuoteEntriesOptional == ReadBytes(splitMsg.rest, 1) IN IF ~totNoQuoteEntriesOptional.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(totNoQuoteEntriesOptional.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(liquidityFlag.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(possRetransFlag.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET quoteCancelAckEntriesGroups == DecodeQuoteCancelAckEntriesGroups(delayToTime.rest) IN IF ~quoteCancelAckEntriesGroups.ok THEN Fail ELSE
    LET quoteCancelAckSetsGroups == DecodeQuoteCancelAckSetsGroups(quoteCancelAckEntriesGroups.rest) IN IF ~quoteCancelAckSetsGroups.ok THEN Fail ELSE
    Ok([ seqNum                      |-> seqNum.value,
         uuid                        |-> uuid.value,
         text                        |-> text.value,
         senderId                    |-> senderId.value,
         partyDetailsListReqId       |-> partyDetailsListReqId.value,
         requestTime                 |-> requestTime.value,
         sendingTimeEpoch            |-> sendingTimeEpoch.value,
         cancelledSymbol             |-> cancelledSymbol.value,
         location                    |-> location.value,
         quoteId                     |-> quoteId.value,
         quoteRejectReason           |-> quoteRejectReason.value,
         delayDuration               |-> delayDuration.value,
         manualOrderIndicator        |-> manualOrderIndicator.value,
         quoteCxlStatus              |-> quoteCxlStatus.value,
         noProcessedEntries32        |-> noProcessedEntries32.value,
         mmProtectionReset           |-> mmProtectionReset.value,
         unsolicitedCancelType       |-> unsolicitedCancelType.value,
         splitMsg                    |-> splitMsg.value,
         totNoQuoteEntriesOptional   |-> totNoQuoteEntriesOptional.value,
         liquidityFlag               |-> liquidityFlag.value,
         possRetransFlag             |-> possRetransFlag.value,
         delayToTime                 |-> delayToTime.value,
         quoteCancelAckEntriesGroups |-> quoteCancelAckEntriesGroups.value,
         quoteCancelAckSetsGroups    |-> quoteCancelAckSetsGroups.value ], quoteCancelAckSetsGroups.rest)

ZeroQuoteCancelAck ==
    [ seqNum                      |-> [i \in 1 .. 4 |-> 0],
      uuid                        |-> [i \in 1 .. 8 |-> 0],
      text                        |-> [i \in 1 .. 256 |-> 0],
      senderId                    |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId       |-> [i \in 1 .. 8 |-> 0],
      requestTime                 |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch            |-> [i \in 1 .. 8 |-> 0],
      cancelledSymbol             |-> [i \in 1 .. 6 |-> 0],
      location                    |-> [i \in 1 .. 5 |-> 0],
      quoteId                     |-> [i \in 1 .. 4 |-> 0],
      quoteRejectReason           |-> [i \in 1 .. 2 |-> 0],
      delayDuration               |-> [i \in 1 .. 2 |-> 0],
      manualOrderIndicator        |-> [i \in 1 .. 1 |-> 0],
      quoteCxlStatus              |-> [i \in 1 .. 1 |-> 0],
      noProcessedEntries32        |-> [i \in 1 .. 4 |-> 0],
      mmProtectionReset           |-> [i \in 1 .. 1 |-> 0],
      unsolicitedCancelType       |-> [i \in 1 .. 1 |-> 0],
      splitMsg                    |-> [i \in 1 .. 1 |-> 0],
      totNoQuoteEntriesOptional   |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag               |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag             |-> [i \in 1 .. 1 |-> 0],
      delayToTime                 |-> [i \in 1 .. 8 |-> 0],
      quoteCancelAckEntriesGroups |-> ZeroQuoteCancelAckEntriesGroups,
      quoteCancelAckSetsGroups    |-> ZeroQuoteCancelAckSetsGroups ]

(* Quote Cancel Ack at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelAck ==
    { ZeroQuoteCancelAck }
        \cup { [ZeroQuoteCancelAck EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.text = one] : one \in Sample(256) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.cancelledSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.quoteId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.quoteRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.delayDuration = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.quoteCxlStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.noProcessedEntries32 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.mmProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.unsolicitedCancelType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.totNoQuoteEntriesOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelAck EXCEPT !.quoteCancelAckEntriesGroups = one] : one \in CheckedQuoteCancelAckEntriesGroups }
        \cup { [ZeroQuoteCancelAck EXCEPT !.quoteCancelAckSetsGroups = one] : one \in CheckedQuoteCancelAckSetsGroups }

(***************************************************************************)
(* Execution Report Pending Cancel: 194 bytes                              *)
(***************************************************************************)

ExecutionReportPendingCancel ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      orderQty              : Sample(4),
      cumQty                : Sample(4),
      leavesQtyOptional     : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      liquidityFlag         : Sample(1),
      delayToTime           : Sample(8),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportPendingCancel(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.price
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.cumQty
        \o message.leavesQtyOptional
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.liquidityFlag
        \o message.delayToTime
        \o message.discretionPrice

DecodeExecutionReportPendingCancel(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET transactTime == ReadBytes(price.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET location == ReadBytes(orderRequestId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQtyOptional == ReadBytes(cumQty.rest, 4) IN IF ~leavesQtyOptional.ok THEN Fail ELSE
    LET minQty == ReadBytes(leavesQtyOptional.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(expireDate.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(splitMsg.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(liquidityFlag.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(delayToTime.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         orderQty              |-> orderQty.value,
         cumQty                |-> cumQty.value,
         leavesQtyOptional     |-> leavesQtyOptional.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         liquidityFlag         |-> liquidityFlag.value,
         delayToTime           |-> delayToTime.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportPendingCancel ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      leavesQtyOptional     |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Pending Cancel at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingCancel ==
    { ZeroExecutionReportPendingCancel }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.leavesQtyOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingCancel EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Pending Replace: 195 bytes                             *)
(***************************************************************************)

ExecutionReportPendingReplace ==
    [ seqNum                : Sample(4),
      uuid                  : Sample(8),
      execId                : Sample(40),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      transactTime          : Sample(8),
      sendingTimeEpoch      : Sample(8),
      orderRequestId        : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      orderQty              : Sample(4),
      cumQty                : Sample(4),
      leaves                : Sample(4),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      ordTypeOptional       : Sample(1),
      side                  : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      possRetransFlag       : Sample(1),
      splitMsg              : Sample(1),
      liquidityFlag         : Sample(1),
      shortSaleType         : Sample(1),
      delayToTime           : Sample(8),
      discretionPrice       : Sample(8) ]

EncodeExecutionReportPendingReplace(message) ==
    message.seqNum
        \o message.uuid
        \o message.execId
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderId
        \o message.price
        \o message.transactTime
        \o message.sendingTimeEpoch
        \o message.orderRequestId
        \o message.location
        \o message.securityId
        \o message.orderQty
        \o message.cumQty
        \o message.leaves
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.ordTypeOptional
        \o message.side
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.possRetransFlag
        \o message.splitMsg
        \o message.liquidityFlag
        \o message.shortSaleType
        \o message.delayToTime
        \o message.discretionPrice

DecodeExecutionReportPendingReplace(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET uuid == ReadBytes(seqNum.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET execId == ReadBytes(uuid.rest, 40) IN IF ~execId.ok THEN Fail ELSE
    LET senderId == ReadBytes(execId.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET transactTime == ReadBytes(price.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transactTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET location == ReadBytes(orderRequestId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leaves == ReadBytes(cumQty.rest, 4) IN IF ~leaves.ok THEN Fail ELSE
    LET minQty == ReadBytes(leaves.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(expireDate.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET side == ReadBytes(ordTypeOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET possRetransFlag == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~possRetransFlag.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(possRetransFlag.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(splitMsg.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(liquidityFlag.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET delayToTime == ReadBytes(shortSaleType.rest, 8) IN IF ~delayToTime.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(delayToTime.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ seqNum                |-> seqNum.value,
         uuid                  |-> uuid.value,
         execId                |-> execId.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         transactTime          |-> transactTime.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         orderRequestId        |-> orderRequestId.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         orderQty              |-> orderQty.value,
         cumQty                |-> cumQty.value,
         leaves                |-> leaves.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         ordTypeOptional       |-> ordTypeOptional.value,
         side                  |-> side.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         possRetransFlag       |-> possRetransFlag.value,
         splitMsg              |-> splitMsg.value,
         liquidityFlag         |-> liquidityFlag.value,
         shortSaleType         |-> shortSaleType.value,
         delayToTime           |-> delayToTime.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroExecutionReportPendingReplace ==
    [ seqNum                |-> [i \in 1 .. 4 |-> 0],
      uuid                  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 40 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      leaves                |-> [i \in 1 .. 4 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      ordTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      possRetransFlag       |-> [i \in 1 .. 1 |-> 0],
      splitMsg              |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      delayToTime           |-> [i \in 1 .. 8 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Report Pending Replace at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportPendingReplace ==
    { ZeroExecutionReportPendingReplace }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.execId = one] : one \in Sample(40) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.leaves = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.possRetransFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.splitMsg = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.delayToTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportPendingReplace EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

NegotiationResponseCode == 501  \* 0x1f5
NegotiationRejectCode == 502  \* 0x1f6
EstablishmentAckCode == 504  \* 0x1f8
EstablishmentRejectCode == 505  \* 0x1f9
SequenceCode == 506  \* 0x1fa
TerminateCode == 507  \* 0x1fb
RetransmissionCode == 509  \* 0x1fd
RetransmitRejectCode == 510  \* 0x1fe
NotAppliedCode == 513  \* 0x201
PartyDetailsDefinitionRequestAckCode == 519  \* 0x207
BusinessRejectCode == 521  \* 0x209
ExecutionReportNewCode == 522  \* 0x20a
ExecutionReportRejectCode == 523  \* 0x20b
ExecutionReportEliminationCode == 524  \* 0x20c
ExecutionReportTradeOutrightCode == 525  \* 0x20d
ExecutionReportTradeSpreadCode == 526  \* 0x20e
ExecutionReportTradeSpreadLegCode == 527  \* 0x20f
ExecutionReportModifyCode == 531  \* 0x213
ExecutionReportStatusCode == 532  \* 0x214
ExecutionReportCancelCode == 534  \* 0x216
OrderCancelRejectCode == 535  \* 0x217
OrderCancelReplaceRejectCode == 536  \* 0x218
PartyDetailsListReportCode == 538  \* 0x21a
RequestForQuoteAckCode == 546  \* 0x222
ExecutionReportTradeAddendumOutrightCode == 548  \* 0x224
ExecutionReportTradeAddendumSpreadCode == 549  \* 0x225
ExecutionReportTradeAddendumSpreadLegCode == 550  \* 0x226
SecurityDefinitionResponseCode == 561  \* 0x231
QuoteCancelAckCode == 563  \* 0x233
ExecutionReportPendingCancelCode == 564  \* 0x234
ExecutionReportPendingReplaceCode == 565  \* 0x235

ServerPayload ==
    [ tag : {NegotiationResponseCode}, body : NegotiationResponse ]
        \cup [ tag : {NegotiationRejectCode}, body : NegotiationReject ]
        \cup [ tag : {EstablishmentAckCode}, body : EstablishmentAck ]
        \cup [ tag : {EstablishmentRejectCode}, body : EstablishmentReject ]
        \cup [ tag : {SequenceCode}, body : Sequence ]
        \cup [ tag : {TerminateCode}, body : Terminate ]
        \cup [ tag : {RetransmissionCode}, body : Retransmission ]
        \cup [ tag : {RetransmitRejectCode}, body : RetransmitReject ]
        \cup [ tag : {NotAppliedCode}, body : NotApplied ]
        \cup [ tag : {PartyDetailsDefinitionRequestAckCode}, body : PartyDetailsDefinitionRequestAck ]
        \cup [ tag : {BusinessRejectCode}, body : BusinessReject ]
        \cup [ tag : {ExecutionReportNewCode}, body : ExecutionReportNew ]
        \cup [ tag : {ExecutionReportRejectCode}, body : ExecutionReportReject ]
        \cup [ tag : {ExecutionReportEliminationCode}, body : ExecutionReportElimination ]
        \cup [ tag : {ExecutionReportTradeOutrightCode}, body : ExecutionReportTradeOutright ]
        \cup [ tag : {ExecutionReportTradeSpreadCode}, body : ExecutionReportTradeSpread ]
        \cup [ tag : {ExecutionReportTradeSpreadLegCode}, body : ExecutionReportTradeSpreadLeg ]
        \cup [ tag : {ExecutionReportModifyCode}, body : ExecutionReportModify ]
        \cup [ tag : {ExecutionReportStatusCode}, body : ExecutionReportStatus ]
        \cup [ tag : {ExecutionReportCancelCode}, body : ExecutionReportCancel ]
        \cup [ tag : {OrderCancelRejectCode}, body : OrderCancelReject ]
        \cup [ tag : {OrderCancelReplaceRejectCode}, body : OrderCancelReplaceReject ]
        \cup [ tag : {PartyDetailsListReportCode}, body : PartyDetailsListReport ]
        \cup [ tag : {RequestForQuoteAckCode}, body : RequestForQuoteAck ]
        \cup [ tag : {ExecutionReportTradeAddendumOutrightCode}, body : ExecutionReportTradeAddendumOutright ]
        \cup [ tag : {ExecutionReportTradeAddendumSpreadCode}, body : ExecutionReportTradeAddendumSpread ]
        \cup [ tag : {ExecutionReportTradeAddendumSpreadLegCode}, body : ExecutionReportTradeAddendumSpreadLeg ]
        \cup [ tag : {SecurityDefinitionResponseCode}, body : SecurityDefinitionResponse ]
        \cup [ tag : {QuoteCancelAckCode}, body : QuoteCancelAck ]
        \cup [ tag : {ExecutionReportPendingCancelCode}, body : ExecutionReportPendingCancel ]
        \cup [ tag : {ExecutionReportPendingReplaceCode}, body : ExecutionReportPendingReplace ]

EncodeServerPayload(message) ==
    CASE message.tag = NegotiationResponseCode -> EncodeNegotiationResponse(message.body)
      [] message.tag = NegotiationRejectCode -> EncodeNegotiationReject(message.body)
      [] message.tag = EstablishmentAckCode -> EncodeEstablishmentAck(message.body)
      [] message.tag = EstablishmentRejectCode -> EncodeEstablishmentReject(message.body)
      [] message.tag = SequenceCode -> EncodeSequence(message.body)
      [] message.tag = TerminateCode -> EncodeTerminate(message.body)
      [] message.tag = RetransmissionCode -> EncodeRetransmission(message.body)
      [] message.tag = RetransmitRejectCode -> EncodeRetransmitReject(message.body)
      [] message.tag = NotAppliedCode -> EncodeNotApplied(message.body)
      [] message.tag = PartyDetailsDefinitionRequestAckCode -> EncodePartyDetailsDefinitionRequestAck(message.body)
      [] message.tag = BusinessRejectCode -> EncodeBusinessReject(message.body)
      [] message.tag = ExecutionReportNewCode -> EncodeExecutionReportNew(message.body)
      [] message.tag = ExecutionReportRejectCode -> EncodeExecutionReportReject(message.body)
      [] message.tag = ExecutionReportEliminationCode -> EncodeExecutionReportElimination(message.body)
      [] message.tag = ExecutionReportTradeOutrightCode -> EncodeExecutionReportTradeOutright(message.body)
      [] message.tag = ExecutionReportTradeSpreadCode -> EncodeExecutionReportTradeSpread(message.body)
      [] message.tag = ExecutionReportTradeSpreadLegCode -> EncodeExecutionReportTradeSpreadLeg(message.body)
      [] message.tag = ExecutionReportModifyCode -> EncodeExecutionReportModify(message.body)
      [] message.tag = ExecutionReportStatusCode -> EncodeExecutionReportStatus(message.body)
      [] message.tag = ExecutionReportCancelCode -> EncodeExecutionReportCancel(message.body)
      [] message.tag = OrderCancelRejectCode -> EncodeOrderCancelReject(message.body)
      [] message.tag = OrderCancelReplaceRejectCode -> EncodeOrderCancelReplaceReject(message.body)
      [] message.tag = PartyDetailsListReportCode -> EncodePartyDetailsListReport(message.body)
      [] message.tag = RequestForQuoteAckCode -> EncodeRequestForQuoteAck(message.body)
      [] message.tag = ExecutionReportTradeAddendumOutrightCode -> EncodeExecutionReportTradeAddendumOutright(message.body)
      [] message.tag = ExecutionReportTradeAddendumSpreadCode -> EncodeExecutionReportTradeAddendumSpread(message.body)
      [] message.tag = ExecutionReportTradeAddendumSpreadLegCode -> EncodeExecutionReportTradeAddendumSpreadLeg(message.body)
      [] message.tag = SecurityDefinitionResponseCode -> EncodeSecurityDefinitionResponse(message.body)
      [] message.tag = QuoteCancelAckCode -> EncodeQuoteCancelAck(message.body)
      [] message.tag = ExecutionReportPendingCancelCode -> EncodeExecutionReportPendingCancel(message.body)
      [] message.tag = ExecutionReportPendingReplaceCode -> EncodeExecutionReportPendingReplace(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = NegotiationResponseCode -> DecodeNegotiationResponse(bytes)
              [] tag = NegotiationRejectCode -> DecodeNegotiationReject(bytes)
              [] tag = EstablishmentAckCode -> DecodeEstablishmentAck(bytes)
              [] tag = EstablishmentRejectCode -> DecodeEstablishmentReject(bytes)
              [] tag = SequenceCode -> DecodeSequence(bytes)
              [] tag = TerminateCode -> DecodeTerminate(bytes)
              [] tag = RetransmissionCode -> DecodeRetransmission(bytes)
              [] tag = RetransmitRejectCode -> DecodeRetransmitReject(bytes)
              [] tag = NotAppliedCode -> DecodeNotApplied(bytes)
              [] tag = PartyDetailsDefinitionRequestAckCode -> DecodePartyDetailsDefinitionRequestAck(bytes)
              [] tag = BusinessRejectCode -> DecodeBusinessReject(bytes)
              [] tag = ExecutionReportNewCode -> DecodeExecutionReportNew(bytes)
              [] tag = ExecutionReportRejectCode -> DecodeExecutionReportReject(bytes)
              [] tag = ExecutionReportEliminationCode -> DecodeExecutionReportElimination(bytes)
              [] tag = ExecutionReportTradeOutrightCode -> DecodeExecutionReportTradeOutright(bytes)
              [] tag = ExecutionReportTradeSpreadCode -> DecodeExecutionReportTradeSpread(bytes)
              [] tag = ExecutionReportTradeSpreadLegCode -> DecodeExecutionReportTradeSpreadLeg(bytes)
              [] tag = ExecutionReportModifyCode -> DecodeExecutionReportModify(bytes)
              [] tag = ExecutionReportStatusCode -> DecodeExecutionReportStatus(bytes)
              [] tag = ExecutionReportCancelCode -> DecodeExecutionReportCancel(bytes)
              [] tag = OrderCancelRejectCode -> DecodeOrderCancelReject(bytes)
              [] tag = OrderCancelReplaceRejectCode -> DecodeOrderCancelReplaceReject(bytes)
              [] tag = PartyDetailsListReportCode -> DecodePartyDetailsListReport(bytes)
              [] tag = RequestForQuoteAckCode -> DecodeRequestForQuoteAck(bytes)
              [] tag = ExecutionReportTradeAddendumOutrightCode -> DecodeExecutionReportTradeAddendumOutright(bytes)
              [] tag = ExecutionReportTradeAddendumSpreadCode -> DecodeExecutionReportTradeAddendumSpread(bytes)
              [] tag = ExecutionReportTradeAddendumSpreadLegCode -> DecodeExecutionReportTradeAddendumSpreadLeg(bytes)
              [] tag = SecurityDefinitionResponseCode -> DecodeSecurityDefinitionResponse(bytes)
              [] tag = QuoteCancelAckCode -> DecodeQuoteCancelAck(bytes)
              [] tag = ExecutionReportPendingCancelCode -> DecodeExecutionReportPendingCancel(bytes)
              [] tag = ExecutionReportPendingReplaceCode -> DecodeExecutionReportPendingReplace(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> NegotiationResponseCode, body |-> ZeroNegotiationResponse]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> NegotiationResponseCode, body |-> one] : one \in CheckedNegotiationResponse }
        \cup { [tag |-> NegotiationRejectCode, body |-> one] : one \in CheckedNegotiationReject }
        \cup { [tag |-> EstablishmentAckCode, body |-> one] : one \in CheckedEstablishmentAck }
        \cup { [tag |-> EstablishmentRejectCode, body |-> one] : one \in CheckedEstablishmentReject }
        \cup { [tag |-> SequenceCode, body |-> one] : one \in CheckedSequence }
        \cup { [tag |-> TerminateCode, body |-> one] : one \in CheckedTerminate }
        \cup { [tag |-> RetransmissionCode, body |-> one] : one \in CheckedRetransmission }
        \cup { [tag |-> RetransmitRejectCode, body |-> one] : one \in CheckedRetransmitReject }
        \cup { [tag |-> NotAppliedCode, body |-> one] : one \in CheckedNotApplied }
        \cup { [tag |-> PartyDetailsDefinitionRequestAckCode, body |-> one] : one \in CheckedPartyDetailsDefinitionRequestAck }
        \cup { [tag |-> BusinessRejectCode, body |-> one] : one \in CheckedBusinessReject }
        \cup { [tag |-> ExecutionReportNewCode, body |-> one] : one \in CheckedExecutionReportNew }
        \cup { [tag |-> ExecutionReportRejectCode, body |-> one] : one \in CheckedExecutionReportReject }
        \cup { [tag |-> ExecutionReportEliminationCode, body |-> one] : one \in CheckedExecutionReportElimination }
        \cup { [tag |-> ExecutionReportTradeOutrightCode, body |-> one] : one \in CheckedExecutionReportTradeOutright }
        \cup { [tag |-> ExecutionReportTradeSpreadCode, body |-> one] : one \in CheckedExecutionReportTradeSpread }
        \cup { [tag |-> ExecutionReportTradeSpreadLegCode, body |-> one] : one \in CheckedExecutionReportTradeSpreadLeg }
        \cup { [tag |-> ExecutionReportModifyCode, body |-> one] : one \in CheckedExecutionReportModify }
        \cup { [tag |-> ExecutionReportStatusCode, body |-> one] : one \in CheckedExecutionReportStatus }
        \cup { [tag |-> ExecutionReportCancelCode, body |-> one] : one \in CheckedExecutionReportCancel }
        \cup { [tag |-> OrderCancelRejectCode, body |-> one] : one \in CheckedOrderCancelReject }
        \cup { [tag |-> OrderCancelReplaceRejectCode, body |-> one] : one \in CheckedOrderCancelReplaceReject }
        \cup { [tag |-> PartyDetailsListReportCode, body |-> one] : one \in CheckedPartyDetailsListReport }
        \cup { [tag |-> RequestForQuoteAckCode, body |-> one] : one \in CheckedRequestForQuoteAck }
        \cup { [tag |-> ExecutionReportTradeAddendumOutrightCode, body |-> one] : one \in CheckedExecutionReportTradeAddendumOutright }
        \cup { [tag |-> ExecutionReportTradeAddendumSpreadCode, body |-> one] : one \in CheckedExecutionReportTradeAddendumSpread }
        \cup { [tag |-> ExecutionReportTradeAddendumSpreadLegCode, body |-> one] : one \in CheckedExecutionReportTradeAddendumSpreadLeg }
        \cup { [tag |-> SecurityDefinitionResponseCode, body |-> one] : one \in CheckedSecurityDefinitionResponse }
        \cup { [tag |-> QuoteCancelAckCode, body |-> one] : one \in CheckedQuoteCancelAck }
        \cup { [tag |-> ExecutionReportPendingCancelCode, body |-> one] : one \in CheckedExecutionReportPendingCancel }
        \cup { [tag |-> ExecutionReportPendingReplaceCode, body |-> one] : one \in CheckedExecutionReportPendingReplace }

(***************************************************************************)
(* Server Simple Open Frame, framed by Message Length                      *)
(***************************************************************************)

ServerSimpleOpenFrame ==
    [ encodingType  : Sample(2),
      blockLength   : Sample(2),
      schemaId      : Sample(2),
      version       : Sample(2),
      serverPayload : ServerPayload ]

EncodeServerSimpleOpenFrameBody(message) ==
    message.encodingType
        \o message.blockLength
        \o EncodeUIntLE(message.serverPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeServerPayload(message.serverPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeServerSimpleOpenFrame(message) ==
    LET body == EncodeServerSimpleOpenFrameBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeServerSimpleOpenFrameBody(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET blockLength == ReadBytes(encodingType.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(templateId.value, version.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ encodingType  |-> encodingType.value,
         blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSimpleOpenFrame(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerSimpleOpenFrameBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSimpleOpenFrame ==
    [ encodingType  |-> [i \in 1 .. 2 |-> 0],
      blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      serverPayload |-> ZeroServerPayload ]

(* Server Simple Open Frame at zero, then each field in turn at the values it is checked at *)
CheckedServerSimpleOpenFrame ==
    { ZeroServerSimpleOpenFrame }
        \cup { [ZeroServerSimpleOpenFrame EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroServerSimpleOpenFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroServerSimpleOpenFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroServerSimpleOpenFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Simple Open Frame, written one after another *)
RECURSIVE EncodeServerSimpleOpenFrameList(_)
EncodeServerSimpleOpenFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSimpleOpenFrame(Head(messages)) \o EncodeServerSimpleOpenFrameList(Tail(messages))

(* As many Server Simple Open Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSimpleOpenFrameAll(_)
ReadServerSimpleOpenFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSimpleOpenFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSimpleOpenFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Simple Open Frame of each kind, for the lists that carry them *)
OneServerSimpleOpenFrame ==
    { [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> NegotiationResponseCode, body |-> ZeroNegotiationResponse]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> NegotiationRejectCode, body |-> ZeroNegotiationReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> EstablishmentAckCode, body |-> ZeroEstablishmentAck]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> EstablishmentRejectCode, body |-> ZeroEstablishmentReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> SequenceCode, body |-> ZeroSequence]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> TerminateCode, body |-> ZeroTerminate]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> RetransmissionCode, body |-> ZeroRetransmission]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> RetransmitRejectCode, body |-> ZeroRetransmitReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> NotAppliedCode, body |-> ZeroNotApplied]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> PartyDetailsDefinitionRequestAckCode, body |-> ZeroPartyDetailsDefinitionRequestAck]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> BusinessRejectCode, body |-> ZeroBusinessReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportNewCode, body |-> ZeroExecutionReportNew]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportRejectCode, body |-> ZeroExecutionReportReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportEliminationCode, body |-> ZeroExecutionReportElimination]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportTradeOutrightCode, body |-> ZeroExecutionReportTradeOutright]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportTradeSpreadCode, body |-> ZeroExecutionReportTradeSpread]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportTradeSpreadLegCode, body |-> ZeroExecutionReportTradeSpreadLeg]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportModifyCode, body |-> ZeroExecutionReportModify]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportStatusCode, body |-> ZeroExecutionReportStatus]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportCancelCode, body |-> ZeroExecutionReportCancel]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> OrderCancelRejectCode, body |-> ZeroOrderCancelReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> OrderCancelReplaceRejectCode, body |-> ZeroOrderCancelReplaceReject]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> PartyDetailsListReportCode, body |-> ZeroPartyDetailsListReport]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> RequestForQuoteAckCode, body |-> ZeroRequestForQuoteAck]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportTradeAddendumOutrightCode, body |-> ZeroExecutionReportTradeAddendumOutright]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportTradeAddendumSpreadCode, body |-> ZeroExecutionReportTradeAddendumSpread]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportTradeAddendumSpreadLegCode, body |-> ZeroExecutionReportTradeAddendumSpreadLeg]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> SecurityDefinitionResponseCode, body |-> ZeroSecurityDefinitionResponse]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> QuoteCancelAckCode, body |-> ZeroQuoteCancelAck]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportPendingCancelCode, body |-> ZeroExecutionReportPendingCancel]],
      [ZeroServerSimpleOpenFrame EXCEPT !.serverPayload = [tag |-> ExecutionReportPendingReplaceCode, body |-> ZeroExecutionReportPendingReplace]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSimpleOpenFrame : SampleLists(OneServerSimpleOpenFrame) ]

EncodeServerPacket(message) ==
    EncodeServerSimpleOpenFrameList(message.serverSimpleOpenFrame)

DecodeServerPacket(bytes) ==
    LET serverSimpleOpenFrame == ReadServerSimpleOpenFrameAll(bytes) IN IF ~serverSimpleOpenFrame.ok THEN Fail ELSE
    Ok([ serverSimpleOpenFrame |-> serverSimpleOpenFrame.value ], serverSimpleOpenFrame.rest)

ZeroServerPacket ==
    [ serverSimpleOpenFrame |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSimpleOpenFrame = one] : one \in SampleLists(OneServerSimpleOpenFrame) }

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

(* Every Credentials decodes back to what was encoded, and leaves nothing over *)
RoundTripCredentials ==
    \A message \in CheckedCredentials :
        LET read == DecodeCredentials(EncodeCredentials(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiation Response decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiationResponse ==
    \A message \in CheckedNegotiationResponse :
        LET read == DecodeNegotiationResponse(EncodeNegotiationResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiation Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiationReject ==
    \A message \in CheckedNegotiationReject :
        LET read == DecodeNegotiationReject(EncodeNegotiationReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establishment Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishmentAck ==
    \A message \in CheckedEstablishmentAck :
        LET read == DecodeEstablishmentAck(EncodeEstablishmentAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establishment Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishmentReject ==
    \A message \in CheckedEstablishmentReject :
        LET read == DecodeEstablishmentReject(EncodeEstablishmentReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripSequence ==
    \A message \in CheckedSequence :
        LET read == DecodeSequence(EncodeSequence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminate ==
    \A message \in CheckedTerminate :
        LET read == DecodeTerminate(EncodeTerminate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmission ==
    \A message \in CheckedRetransmission :
        LET read == DecodeRetransmission(EncodeRetransmission(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitReject ==
    \A message \in CheckedRetransmitReject :
        LET read == DecodeRetransmitReject(EncodeRetransmitReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Applied decodes back to what was encoded, and leaves nothing over *)
RoundTripNotApplied ==
    \A message \in CheckedNotApplied :
        LET read == DecodeNotApplied(EncodeNotApplied(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGroup ==
    \A message \in CheckedPartyDetailsGroup :
        LET read == DecodePartyDetailsGroup(EncodePartyDetailsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGroups ==
    \A message \in CheckedPartyDetailsGroups :
        LET read == DecodePartyDetailsGroups(EncodePartyDetailsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Reg Publications Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdRegPublicationsGroup ==
    \A message \in CheckedTrdRegPublicationsGroup :
        LET read == DecodeTrdRegPublicationsGroup(EncodeTrdRegPublicationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Reg Publications Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdRegPublicationsGroups ==
    \A message \in CheckedTrdRegPublicationsGroups :
        LET read == DecodeTrdRegPublicationsGroups(EncodeTrdRegPublicationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Definition Request Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsDefinitionRequestAck ==
    \A message \in CheckedPartyDetailsDefinitionRequestAck :
        LET read == DecodePartyDetailsDefinitionRequestAck(EncodePartyDetailsDefinitionRequestAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessReject ==
    \A message \in CheckedBusinessReject :
        LET read == DecodeBusinessReject(EncodeBusinessReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report New decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportNew ==
    \A message \in CheckedExecutionReportNew :
        LET read == DecodeExecutionReportNew(EncodeExecutionReportNew(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportReject ==
    \A message \in CheckedExecutionReportReject :
        LET read == DecodeExecutionReportReject(EncodeExecutionReportReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Elimination decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportElimination ==
    \A message \in CheckedExecutionReportElimination :
        LET read == DecodeExecutionReportElimination(EncodeExecutionReportElimination(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Ccy Last Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedCcyLastQty ==
    \A message \in CheckedCalculatedCcyLastQty :
        LET read == DecodeCalculatedCcyLastQty(EncodeCalculatedCcyLastQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gross Trade Amt decodes back to what was encoded, and leaves nothing over *)
RoundTripGrossTradeAmt ==
    \A message \in CheckedGrossTradeAmt :
        LET read == DecodeGrossTradeAmt(EncodeGrossTradeAmt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroup ==
    \A message \in CheckedFillsGroup :
        LET read == DecodeFillsGroup(EncodeFillsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroups ==
    \A message \in CheckedFillsGroups :
        LET read == DecodeFillsGroups(EncodeFillsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contra Gross Trade Amt decodes back to what was encoded, and leaves nothing over *)
RoundTripContraGrossTradeAmt ==
    \A message \in CheckedContraGrossTradeAmt :
        LET read == DecodeContraGrossTradeAmt(EncodeContraGrossTradeAmt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contra Calculated Ccy Last Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripContraCalculatedCcyLastQty ==
    \A message \in CheckedContraCalculatedCcyLastQty :
        LET read == DecodeContraCalculatedCcyLastQty(EncodeContraCalculatedCcyLastQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Order Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightOrderEventsGroup ==
    \A message \in CheckedOutrightOrderEventsGroup :
        LET read == DecodeOutrightOrderEventsGroup(EncodeOutrightOrderEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Order Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightOrderEventsGroups ==
    \A message \in CheckedOutrightOrderEventsGroups :
        LET read == DecodeOutrightOrderEventsGroups(EncodeOutrightOrderEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Outright decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeOutright ==
    \A message \in CheckedExecutionReportTradeOutright :
        LET read == DecodeExecutionReportTradeOutright(EncodeExecutionReportTradeOutright(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroup2 ==
    \A message \in CheckedFillsGroup2 :
        LET read == DecodeFillsGroup2(EncodeFillsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroups2 ==
    \A message \in CheckedFillsGroups2 :
        LET read == DecodeFillsGroups2(EncodeFillsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeLegsGroup ==
    \A message \in CheckedTradeLegsGroup :
        LET read == DecodeTradeLegsGroup(EncodeTradeLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeLegsGroups ==
    \A message \in CheckedTradeLegsGroups :
        LET read == DecodeTradeLegsGroups(EncodeTradeLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderEventsGroup ==
    \A message \in CheckedSpreadOrderEventsGroup :
        LET read == DecodeSpreadOrderEventsGroup(EncodeSpreadOrderEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderEventsGroups ==
    \A message \in CheckedSpreadOrderEventsGroups :
        LET read == DecodeSpreadOrderEventsGroups(EncodeSpreadOrderEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Spread decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeSpread ==
    \A message \in CheckedExecutionReportTradeSpread :
        LET read == DecodeExecutionReportTradeSpread(EncodeExecutionReportTradeSpread(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Volatility decodes back to what was encoded, and leaves nothing over *)
RoundTripVolatility ==
    \A message \in CheckedVolatility :
        LET read == DecodeVolatility(EncodeVolatility(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Delta decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionDelta ==
    \A message \in CheckedOptionDelta :
        LET read == DecodeOptionDelta(EncodeOptionDelta(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time To Expiration decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeToExpiration ==
    \A message \in CheckedTimeToExpiration :
        LET read == DecodeTimeToExpiration(EncodeTimeToExpiration(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Free Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskFreeRate ==
    \A message \in CheckedRiskFreeRate :
        LET read == DecodeRiskFreeRate(EncodeRiskFreeRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Ccy Last Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedCcyLastQty2 ==
    \A message \in CheckedCalculatedCcyLastQty2 :
        LET read == DecodeCalculatedCcyLastQty2(EncodeCalculatedCcyLastQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gross Trade Amt decodes back to what was encoded, and leaves nothing over *)
RoundTripGrossTradeAmt2 ==
    \A message \in CheckedGrossTradeAmt2 :
        LET read == DecodeGrossTradeAmt2(EncodeGrossTradeAmt2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroup3 ==
    \A message \in CheckedFillsGroup3 :
        LET read == DecodeFillsGroup3(EncodeFillsGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroups3 ==
    \A message \in CheckedFillsGroups3 :
        LET read == DecodeFillsGroups3(EncodeFillsGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Leg Order Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadLegOrderEventsGroup ==
    \A message \in CheckedSpreadLegOrderEventsGroup :
        LET read == DecodeSpreadLegOrderEventsGroup(EncodeSpreadLegOrderEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Leg Order Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadLegOrderEventsGroups ==
    \A message \in CheckedSpreadLegOrderEventsGroups :
        LET read == DecodeSpreadLegOrderEventsGroups(EncodeSpreadLegOrderEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Spread Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeSpreadLeg ==
    \A message \in CheckedExecutionReportTradeSpreadLeg :
        LET read == DecodeExecutionReportTradeSpreadLeg(EncodeExecutionReportTradeSpreadLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Modify decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportModify ==
    \A message \in CheckedExecutionReportModify :
        LET read == DecodeExecutionReportModify(EncodeExecutionReportModify(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Status decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportStatus ==
    \A message \in CheckedExecutionReportStatus :
        LET read == DecodeExecutionReportStatus(EncodeExecutionReportStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportCancel ==
    \A message \in CheckedExecutionReportCancel :
        LET read == DecodeExecutionReportCancel(EncodeExecutionReportCancel(message))
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

(* Every Order Cancel Replace Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReplaceReject ==
    \A message \in CheckedOrderCancelReplaceReject :
        LET read == DecodeOrderCancelReplaceReject(EncodeOrderCancelReplaceReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGroup2 ==
    \A message \in CheckedPartyDetailsGroup2 :
        LET read == DecodePartyDetailsGroup2(EncodePartyDetailsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGroups2 ==
    \A message \in CheckedPartyDetailsGroups2 :
        LET read == DecodePartyDetailsGroups2(EncodePartyDetailsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Reg Publications Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdRegPublicationsGroup2 ==
    \A message \in CheckedTrdRegPublicationsGroup2 :
        LET read == DecodeTrdRegPublicationsGroup2(EncodeTrdRegPublicationsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Reg Publications Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdRegPublicationsGroups2 ==
    \A message \in CheckedTrdRegPublicationsGroups2 :
        LET read == DecodeTrdRegPublicationsGroups2(EncodeTrdRegPublicationsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details List Report decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsListReport ==
    \A message \in CheckedPartyDetailsListReport :
        LET read == DecodePartyDetailsListReport(EncodePartyDetailsListReport(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Quote Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForQuoteAck ==
    \A message \in CheckedRequestForQuoteAck :
        LET read == DecodeRequestForQuoteAck(EncodeRequestForQuoteAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Ccy Last Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedCcyLastQty3 ==
    \A message \in CheckedCalculatedCcyLastQty3 :
        LET read == DecodeCalculatedCcyLastQty3(EncodeCalculatedCcyLastQty3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gross Trade Amt decodes back to what was encoded, and leaves nothing over *)
RoundTripGrossTradeAmt3 ==
    \A message \in CheckedGrossTradeAmt3 :
        LET read == DecodeGrossTradeAmt3(EncodeGrossTradeAmt3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroup4 ==
    \A message \in CheckedFillsGroup4 :
        LET read == DecodeFillsGroup4(EncodeFillsGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroups4 ==
    \A message \in CheckedFillsGroups4 :
        LET read == DecodeFillsGroups4(EncodeFillsGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contra Gross Trade Amt decodes back to what was encoded, and leaves nothing over *)
RoundTripContraGrossTradeAmt2 ==
    \A message \in CheckedContraGrossTradeAmt2 :
        LET read == DecodeContraGrossTradeAmt2(EncodeContraGrossTradeAmt2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contra Calculated Ccy Last Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripContraCalculatedCcyLastQty2 ==
    \A message \in CheckedContraCalculatedCcyLastQty2 :
        LET read == DecodeContraCalculatedCcyLastQty2(EncodeContraCalculatedCcyLastQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Trade Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightTradeEventsGroup ==
    \A message \in CheckedOutrightTradeEventsGroup :
        LET read == DecodeOutrightTradeEventsGroup(EncodeOutrightTradeEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Trade Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightTradeEventsGroups ==
    \A message \in CheckedOutrightTradeEventsGroups :
        LET read == DecodeOutrightTradeEventsGroups(EncodeOutrightTradeEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Addendum Outright decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeAddendumOutright ==
    \A message \in CheckedExecutionReportTradeAddendumOutright :
        LET read == DecodeExecutionReportTradeAddendumOutright(EncodeExecutionReportTradeAddendumOutright(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroup5 ==
    \A message \in CheckedFillsGroup5 :
        LET read == DecodeFillsGroup5(EncodeFillsGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroups5 ==
    \A message \in CheckedFillsGroups5 :
        LET read == DecodeFillsGroups5(EncodeFillsGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Addendum Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeAddendumLegsGroup ==
    \A message \in CheckedTradeAddendumLegsGroup :
        LET read == DecodeTradeAddendumLegsGroup(EncodeTradeAddendumLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Addendum Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeAddendumLegsGroups ==
    \A message \in CheckedTradeAddendumLegsGroups :
        LET read == DecodeTradeAddendumLegsGroups(EncodeTradeAddendumLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Trade Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadTradeEventsGroup ==
    \A message \in CheckedSpreadTradeEventsGroup :
        LET read == DecodeSpreadTradeEventsGroup(EncodeSpreadTradeEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Trade Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadTradeEventsGroups ==
    \A message \in CheckedSpreadTradeEventsGroups :
        LET read == DecodeSpreadTradeEventsGroups(EncodeSpreadTradeEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Addendum Spread decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeAddendumSpread ==
    \A message \in CheckedExecutionReportTradeAddendumSpread :
        LET read == DecodeExecutionReportTradeAddendumSpread(EncodeExecutionReportTradeAddendumSpread(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Ccy Last Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedCcyLastQty4 ==
    \A message \in CheckedCalculatedCcyLastQty4 :
        LET read == DecodeCalculatedCcyLastQty4(EncodeCalculatedCcyLastQty4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gross Trade Amt decodes back to what was encoded, and leaves nothing over *)
RoundTripGrossTradeAmt4 ==
    \A message \in CheckedGrossTradeAmt4 :
        LET read == DecodeGrossTradeAmt4(EncodeGrossTradeAmt4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroup6 ==
    \A message \in CheckedFillsGroup6 :
        LET read == DecodeFillsGroup6(EncodeFillsGroup6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGroups6 ==
    \A message \in CheckedFillsGroups6 :
        LET read == DecodeFillsGroups6(EncodeFillsGroups6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Leg Trade Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadLegTradeEventsGroup ==
    \A message \in CheckedSpreadLegTradeEventsGroup :
        LET read == DecodeSpreadLegTradeEventsGroup(EncodeSpreadLegTradeEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Leg Trade Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadLegTradeEventsGroups ==
    \A message \in CheckedSpreadLegTradeEventsGroups :
        LET read == DecodeSpreadLegTradeEventsGroups(EncodeSpreadLegTradeEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Addendum Spread Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeAddendumSpreadLeg ==
    \A message \in CheckedExecutionReportTradeAddendumSpreadLeg :
        LET read == DecodeExecutionReportTradeAddendumSpreadLeg(EncodeExecutionReportTradeAddendumSpreadLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear ==
    \A message \in CheckedMaturityMonthYear :
        LET read == DecodeMaturityMonthYear(EncodeMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Option Delta decodes back to what was encoded, and leaves nothing over *)
RoundTripLegOptionDelta ==
    \A message \in CheckedLegOptionDelta :
        LET read == DecodeLegOptionDelta(EncodeLegOptionDelta(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseLegsGroup ==
    \A message \in CheckedResponseLegsGroup :
        LET read == DecodeResponseLegsGroup(EncodeResponseLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseLegsGroups ==
    \A message \in CheckedResponseLegsGroups :
        LET read == DecodeResponseLegsGroups(EncodeResponseLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionResponse ==
    \A message \in CheckedSecurityDefinitionResponse :
        LET read == DecodeSecurityDefinitionResponse(EncodeSecurityDefinitionResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Ack Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelAckEntriesGroup ==
    \A message \in CheckedQuoteCancelAckEntriesGroup :
        LET read == DecodeQuoteCancelAckEntriesGroup(EncodeQuoteCancelAckEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Ack Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelAckEntriesGroups ==
    \A message \in CheckedQuoteCancelAckEntriesGroups :
        LET read == DecodeQuoteCancelAckEntriesGroups(EncodeQuoteCancelAckEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Ack Sets Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelAckSetsGroup ==
    \A message \in CheckedQuoteCancelAckSetsGroup :
        LET read == DecodeQuoteCancelAckSetsGroup(EncodeQuoteCancelAckSetsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Ack Sets Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelAckSetsGroups ==
    \A message \in CheckedQuoteCancelAckSetsGroups :
        LET read == DecodeQuoteCancelAckSetsGroups(EncodeQuoteCancelAckSetsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelAck ==
    \A message \in CheckedQuoteCancelAck :
        LET read == DecodeQuoteCancelAck(EncodeQuoteCancelAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Pending Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportPendingCancel ==
    \A message \in CheckedExecutionReportPendingCancel :
        LET read == DecodeExecutionReportPendingCancel(EncodeExecutionReportPendingCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Pending Replace decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportPendingReplace ==
    \A message \in CheckedExecutionReportPendingReplace :
        LET read == DecodeExecutionReportPendingReplace(EncodeExecutionReportPendingReplace(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Simple Open Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSimpleOpenFrame ==
    \A message \in CheckedServerSimpleOpenFrame :
        LET read == DecodeServerSimpleOpenFrame(EncodeServerSimpleOpenFrame(message))
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

(* Message Length is written from the bytes it frames *)
FramesServerSimpleOpenFrame ==
    \A message \in CheckedServerSimpleOpenFrame :
        LET bytes == EncodeServerSimpleOpenFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
