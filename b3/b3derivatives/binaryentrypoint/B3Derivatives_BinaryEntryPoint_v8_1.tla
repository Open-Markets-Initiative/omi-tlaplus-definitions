---------------- MODULE B3Derivatives_BinaryEntryPoint_v8_1 ----------------
(***************************************************************************)
(* Brasil, Bolsa, Balcão Binary Entry Point v8.1                           *)
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
(* Credentials                                                             *)
(***************************************************************************)

Credentials ==
    [ credentialsData : SampleBytes ]

EncodeCredentials(message) ==
    EncodeUIntBE(Len(message.credentialsData), 1)
        \o message.credentialsData

DecodeCredentials(bytes) ==
    LET credentialsLength == ReadUIntBE(bytes, 1) IN IF ~credentialsLength.ok THEN Fail ELSE
    LET credentialsData == ReadBytes(credentialsLength.rest, credentialsLength.value) IN IF ~credentialsData.ok THEN Fail ELSE
    Ok([ credentialsData |-> credentialsData.value ], credentialsData.rest)

ZeroCredentials ==
    [ credentialsData |-> << >> ]

(* Credentials at zero, then each field in turn at the values it is checked at *)
CheckedCredentials ==
    { ZeroCredentials }
        \cup { [ZeroCredentials EXCEPT !.credentialsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Client Ip                                                               *)
(***************************************************************************)

ClientIp ==
    [ clientIpData : SampleBytes ]

EncodeClientIp(message) ==
    EncodeUIntBE(Len(message.clientIpData), 1)
        \o message.clientIpData

DecodeClientIp(bytes) ==
    LET clientIpLength == ReadUIntBE(bytes, 1) IN IF ~clientIpLength.ok THEN Fail ELSE
    LET clientIpData == ReadBytes(clientIpLength.rest, clientIpLength.value) IN IF ~clientIpData.ok THEN Fail ELSE
    Ok([ clientIpData |-> clientIpData.value ], clientIpData.rest)

ZeroClientIp ==
    [ clientIpData |-> << >> ]

(* Client Ip at zero, then each field in turn at the values it is checked at *)
CheckedClientIp ==
    { ZeroClientIp }
        \cup { [ZeroClientIp EXCEPT !.clientIpData = one] : one \in SampleBytes }

(***************************************************************************)
(* Client App Name                                                         *)
(***************************************************************************)

ClientAppName ==
    [ clientAppNameData : SampleBytes ]

EncodeClientAppName(message) ==
    EncodeUIntBE(Len(message.clientAppNameData), 1)
        \o message.clientAppNameData

DecodeClientAppName(bytes) ==
    LET clientAppNameLength == ReadUIntBE(bytes, 1) IN IF ~clientAppNameLength.ok THEN Fail ELSE
    LET clientAppNameData == ReadBytes(clientAppNameLength.rest, clientAppNameLength.value) IN IF ~clientAppNameData.ok THEN Fail ELSE
    Ok([ clientAppNameData |-> clientAppNameData.value ], clientAppNameData.rest)

ZeroClientAppName ==
    [ clientAppNameData |-> << >> ]

(* Client App Name at zero, then each field in turn at the values it is checked at *)
CheckedClientAppName ==
    { ZeroClientAppName }
        \cup { [ZeroClientAppName EXCEPT !.clientAppNameData = one] : one \in SampleBytes }

(***************************************************************************)
(* Client App Version                                                      *)
(***************************************************************************)

ClientAppVersion ==
    [ clientAppVersionData : SampleBytes ]

EncodeClientAppVersion(message) ==
    EncodeUIntBE(Len(message.clientAppVersionData), 1)
        \o message.clientAppVersionData

DecodeClientAppVersion(bytes) ==
    LET clientAppVersionLength == ReadUIntBE(bytes, 1) IN IF ~clientAppVersionLength.ok THEN Fail ELSE
    LET clientAppVersionData == ReadBytes(clientAppVersionLength.rest, clientAppVersionLength.value) IN IF ~clientAppVersionData.ok THEN Fail ELSE
    Ok([ clientAppVersionData |-> clientAppVersionData.value ], clientAppVersionData.rest)

ZeroClientAppVersion ==
    [ clientAppVersionData |-> << >> ]

(* Client App Version at zero, then each field in turn at the values it is checked at *)
CheckedClientAppVersion ==
    { ZeroClientAppVersion }
        \cup { [ZeroClientAppVersion EXCEPT !.clientAppVersionData = one] : one \in SampleBytes }

(***************************************************************************)
(* Negotiate Message                                                       *)
(***************************************************************************)

NegotiateMessage ==
    [ sessionId        : Sample(4),
      sessionVerId     : Sample(8),
      timestamp        : Sample(8),
      enteringFirm     : Sample(4),
      onbehalfFirm     : Sample(4),
      credentials      : Credentials,
      clientIp         : ClientIp,
      clientAppName    : ClientAppName,
      clientAppVersion : ClientAppVersion ]

EncodeNegotiateMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.timestamp
        \o message.enteringFirm
        \o message.onbehalfFirm
        \o EncodeCredentials(message.credentials)
        \o EncodeClientIp(message.clientIp)
        \o EncodeClientAppName(message.clientAppName)
        \o EncodeClientAppVersion(message.clientAppVersion)

DecodeNegotiateMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sessionVerId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET enteringFirm == ReadBytes(timestamp.rest, 4) IN IF ~enteringFirm.ok THEN Fail ELSE
    LET onbehalfFirm == ReadBytes(enteringFirm.rest, 4) IN IF ~onbehalfFirm.ok THEN Fail ELSE
    LET credentials == DecodeCredentials(onbehalfFirm.rest) IN IF ~credentials.ok THEN Fail ELSE
    LET clientIp == DecodeClientIp(credentials.rest) IN IF ~clientIp.ok THEN Fail ELSE
    LET clientAppName == DecodeClientAppName(clientIp.rest) IN IF ~clientAppName.ok THEN Fail ELSE
    LET clientAppVersion == DecodeClientAppVersion(clientAppName.rest) IN IF ~clientAppVersion.ok THEN Fail ELSE
    Ok([ sessionId        |-> sessionId.value,
         sessionVerId     |-> sessionVerId.value,
         timestamp        |-> timestamp.value,
         enteringFirm     |-> enteringFirm.value,
         onbehalfFirm     |-> onbehalfFirm.value,
         credentials      |-> credentials.value,
         clientIp         |-> clientIp.value,
         clientAppName    |-> clientAppName.value,
         clientAppVersion |-> clientAppVersion.value ], clientAppVersion.rest)

ZeroNegotiateMessage ==
    [ sessionId        |-> [i \in 1 .. 4 |-> 0],
      sessionVerId     |-> [i \in 1 .. 8 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      enteringFirm     |-> [i \in 1 .. 4 |-> 0],
      onbehalfFirm     |-> [i \in 1 .. 4 |-> 0],
      credentials      |-> ZeroCredentials,
      clientIp         |-> ZeroClientIp,
      clientAppName    |-> ZeroClientAppName,
      clientAppVersion |-> ZeroClientAppVersion ]

(* Negotiate Message at zero, then each field in turn at the values it is checked at *)
CheckedNegotiateMessage ==
    { ZeroNegotiateMessage }
        \cup { [ZeroNegotiateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroNegotiateMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroNegotiateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiateMessage EXCEPT !.enteringFirm = one] : one \in Sample(4) }
        \cup { [ZeroNegotiateMessage EXCEPT !.onbehalfFirm = one] : one \in Sample(4) }
        \cup { [ZeroNegotiateMessage EXCEPT !.credentials = one] : one \in CheckedCredentials }
        \cup { [ZeroNegotiateMessage EXCEPT !.clientIp = one] : one \in CheckedClientIp }
        \cup { [ZeroNegotiateMessage EXCEPT !.clientAppName = one] : one \in CheckedClientAppName }
        \cup { [ZeroNegotiateMessage EXCEPT !.clientAppVersion = one] : one \in CheckedClientAppVersion }

(***************************************************************************)
(* Negotiate Response Message: 24 bytes                                    *)
(***************************************************************************)

NegotiateResponseMessage ==
    [ sessionId        : Sample(4),
      sessionVerId     : Sample(8),
      requestTimestamp : Sample(8),
      enteringFirm     : Sample(4) ]

EncodeNegotiateResponseMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.requestTimestamp
        \o message.enteringFirm

DecodeNegotiateResponseMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(sessionVerId.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET enteringFirm == ReadBytes(requestTimestamp.rest, 4) IN IF ~enteringFirm.ok THEN Fail ELSE
    Ok([ sessionId        |-> sessionId.value,
         sessionVerId     |-> sessionVerId.value,
         requestTimestamp |-> requestTimestamp.value,
         enteringFirm     |-> enteringFirm.value ], enteringFirm.rest)

ZeroNegotiateResponseMessage ==
    [ sessionId        |-> [i \in 1 .. 4 |-> 0],
      sessionVerId     |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      enteringFirm     |-> [i \in 1 .. 4 |-> 0] ]

(* Negotiate Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNegotiateResponseMessage ==
    { ZeroNegotiateResponseMessage }
        \cup { [ZeroNegotiateResponseMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroNegotiateResponseMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroNegotiateResponseMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiateResponseMessage EXCEPT !.enteringFirm = one] : one \in Sample(4) }

(***************************************************************************)
(* Negotiate Reject Message: 36 bytes                                      *)
(***************************************************************************)

NegotiateRejectMessage ==
    [ sessionId             : Sample(4),
      sessionVerId          : Sample(8),
      requestTimestamp      : Sample(8),
      enteringFirmOptional  : Sample(4),
      negotiationRejectCode : Sample(1),
      offset25Padding3      : Sample(3),
      currentSessionVerId   : Sample(8) ]

EncodeNegotiateRejectMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.requestTimestamp
        \o message.enteringFirmOptional
        \o message.negotiationRejectCode
        \o message.offset25Padding3
        \o message.currentSessionVerId

DecodeNegotiateRejectMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(sessionVerId.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET enteringFirmOptional == ReadBytes(requestTimestamp.rest, 4) IN IF ~enteringFirmOptional.ok THEN Fail ELSE
    LET negotiationRejectCode == ReadBytes(enteringFirmOptional.rest, 1) IN IF ~negotiationRejectCode.ok THEN Fail ELSE
    LET offset25Padding3 == ReadBytes(negotiationRejectCode.rest, 3) IN IF ~offset25Padding3.ok THEN Fail ELSE
    LET currentSessionVerId == ReadBytes(offset25Padding3.rest, 8) IN IF ~currentSessionVerId.ok THEN Fail ELSE
    Ok([ sessionId             |-> sessionId.value,
         sessionVerId          |-> sessionVerId.value,
         requestTimestamp      |-> requestTimestamp.value,
         enteringFirmOptional  |-> enteringFirmOptional.value,
         negotiationRejectCode |-> negotiationRejectCode.value,
         offset25Padding3      |-> offset25Padding3.value,
         currentSessionVerId   |-> currentSessionVerId.value ], currentSessionVerId.rest)

ZeroNegotiateRejectMessage ==
    [ sessionId             |-> [i \in 1 .. 4 |-> 0],
      sessionVerId          |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp      |-> [i \in 1 .. 8 |-> 0],
      enteringFirmOptional  |-> [i \in 1 .. 4 |-> 0],
      negotiationRejectCode |-> [i \in 1 .. 1 |-> 0],
      offset25Padding3      |-> [i \in 1 .. 3 |-> 0],
      currentSessionVerId   |-> [i \in 1 .. 8 |-> 0] ]

(* Negotiate Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedNegotiateRejectMessage ==
    { ZeroNegotiateRejectMessage }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.enteringFirmOptional = one] : one \in Sample(4) }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.negotiationRejectCode = one] : one \in Sample(1) }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.offset25Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroNegotiateRejectMessage EXCEPT !.currentSessionVerId = one] : one \in Sample(8) }

(***************************************************************************)
(* Credentials                                                             *)
(***************************************************************************)

Credentials2 ==
    [ credentialsData : SampleBytes ]

EncodeCredentials2(message) ==
    EncodeUIntBE(Len(message.credentialsData), 1)
        \o message.credentialsData

DecodeCredentials2(bytes) ==
    LET credentialsLength == ReadUIntBE(bytes, 1) IN IF ~credentialsLength.ok THEN Fail ELSE
    LET credentialsData == ReadBytes(credentialsLength.rest, credentialsLength.value) IN IF ~credentialsData.ok THEN Fail ELSE
    Ok([ credentialsData |-> credentialsData.value ], credentialsData.rest)

ZeroCredentials2 ==
    [ credentialsData |-> << >> ]

(* Credentials at zero, then each field in turn at the values it is checked at *)
CheckedCredentials2 ==
    { ZeroCredentials2 }
        \cup { [ZeroCredentials2 EXCEPT !.credentialsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Establish Message                                                       *)
(***************************************************************************)

EstablishMessage ==
    [ sessionId              : Sample(4),
      sessionVerId           : Sample(8),
      timestamp              : Sample(8),
      keepAliveInterval      : Sample(8),
      nextSeqNo              : Sample(4),
      cancelOnDisconnectType : Sample(1),
      offset33Padding1       : Sample(1),
      codTimeoutWindow       : Sample(8),
      credentials            : Credentials2 ]

EncodeEstablishMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.timestamp
        \o message.keepAliveInterval
        \o message.nextSeqNo
        \o message.cancelOnDisconnectType
        \o message.offset33Padding1
        \o message.codTimeoutWindow
        \o EncodeCredentials2(message.credentials)

DecodeEstablishMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sessionVerId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET keepAliveInterval == ReadBytes(timestamp.rest, 8) IN IF ~keepAliveInterval.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(keepAliveInterval.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET cancelOnDisconnectType == ReadBytes(nextSeqNo.rest, 1) IN IF ~cancelOnDisconnectType.ok THEN Fail ELSE
    LET offset33Padding1 == ReadBytes(cancelOnDisconnectType.rest, 1) IN IF ~offset33Padding1.ok THEN Fail ELSE
    LET codTimeoutWindow == ReadBytes(offset33Padding1.rest, 8) IN IF ~codTimeoutWindow.ok THEN Fail ELSE
    LET credentials == DecodeCredentials2(codTimeoutWindow.rest) IN IF ~credentials.ok THEN Fail ELSE
    Ok([ sessionId              |-> sessionId.value,
         sessionVerId           |-> sessionVerId.value,
         timestamp              |-> timestamp.value,
         keepAliveInterval      |-> keepAliveInterval.value,
         nextSeqNo              |-> nextSeqNo.value,
         cancelOnDisconnectType |-> cancelOnDisconnectType.value,
         offset33Padding1       |-> offset33Padding1.value,
         codTimeoutWindow       |-> codTimeoutWindow.value,
         credentials            |-> credentials.value ], credentials.rest)

ZeroEstablishMessage ==
    [ sessionId              |-> [i \in 1 .. 4 |-> 0],
      sessionVerId           |-> [i \in 1 .. 8 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      keepAliveInterval      |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo              |-> [i \in 1 .. 4 |-> 0],
      cancelOnDisconnectType |-> [i \in 1 .. 1 |-> 0],
      offset33Padding1       |-> [i \in 1 .. 1 |-> 0],
      codTimeoutWindow       |-> [i \in 1 .. 8 |-> 0],
      credentials            |-> ZeroCredentials2 ]

(* Establish Message at zero, then each field in turn at the values it is checked at *)
CheckedEstablishMessage ==
    { ZeroEstablishMessage }
        \cup { [ZeroEstablishMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroEstablishMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroEstablishMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishMessage EXCEPT !.keepAliveInterval = one] : one \in Sample(8) }
        \cup { [ZeroEstablishMessage EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroEstablishMessage EXCEPT !.cancelOnDisconnectType = one] : one \in Sample(1) }
        \cup { [ZeroEstablishMessage EXCEPT !.offset33Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroEstablishMessage EXCEPT !.codTimeoutWindow = one] : one \in Sample(8) }
        \cup { [ZeroEstablishMessage EXCEPT !.credentials = one] : one \in CheckedCredentials2 }

(***************************************************************************)
(* Establish Ack Message: 36 bytes                                         *)
(***************************************************************************)

EstablishAckMessage ==
    [ sessionId         : Sample(4),
      sessionVerId      : Sample(8),
      requestTimestamp  : Sample(8),
      keepAliveInterval : Sample(8),
      nextSeqNo         : Sample(4),
      lastIncomingSeqNo : Sample(4) ]

EncodeEstablishAckMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.requestTimestamp
        \o message.keepAliveInterval
        \o message.nextSeqNo
        \o message.lastIncomingSeqNo

DecodeEstablishAckMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(sessionVerId.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET keepAliveInterval == ReadBytes(requestTimestamp.rest, 8) IN IF ~keepAliveInterval.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(keepAliveInterval.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET lastIncomingSeqNo == ReadBytes(nextSeqNo.rest, 4) IN IF ~lastIncomingSeqNo.ok THEN Fail ELSE
    Ok([ sessionId         |-> sessionId.value,
         sessionVerId      |-> sessionVerId.value,
         requestTimestamp  |-> requestTimestamp.value,
         keepAliveInterval |-> keepAliveInterval.value,
         nextSeqNo         |-> nextSeqNo.value,
         lastIncomingSeqNo |-> lastIncomingSeqNo.value ], lastIncomingSeqNo.rest)

ZeroEstablishAckMessage ==
    [ sessionId         |-> [i \in 1 .. 4 |-> 0],
      sessionVerId      |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp  |-> [i \in 1 .. 8 |-> 0],
      keepAliveInterval |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo         |-> [i \in 1 .. 4 |-> 0],
      lastIncomingSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Establish Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedEstablishAckMessage ==
    { ZeroEstablishAckMessage }
        \cup { [ZeroEstablishAckMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroEstablishAckMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroEstablishAckMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishAckMessage EXCEPT !.keepAliveInterval = one] : one \in Sample(8) }
        \cup { [ZeroEstablishAckMessage EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroEstablishAckMessage EXCEPT !.lastIncomingSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Establish Reject Message: 26 bytes                                      *)
(***************************************************************************)

EstablishRejectMessage ==
    [ sessionId                 : Sample(4),
      sessionVerId              : Sample(8),
      requestTimestamp          : Sample(8),
      establishmentRejectCode   : Sample(1),
      offset21Padding1          : Sample(1),
      lastIncomingSeqNoOptional : Sample(4) ]

EncodeEstablishRejectMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.requestTimestamp
        \o message.establishmentRejectCode
        \o message.offset21Padding1
        \o message.lastIncomingSeqNoOptional

DecodeEstablishRejectMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(sessionVerId.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET establishmentRejectCode == ReadBytes(requestTimestamp.rest, 1) IN IF ~establishmentRejectCode.ok THEN Fail ELSE
    LET offset21Padding1 == ReadBytes(establishmentRejectCode.rest, 1) IN IF ~offset21Padding1.ok THEN Fail ELSE
    LET lastIncomingSeqNoOptional == ReadBytes(offset21Padding1.rest, 4) IN IF ~lastIncomingSeqNoOptional.ok THEN Fail ELSE
    Ok([ sessionId                 |-> sessionId.value,
         sessionVerId              |-> sessionVerId.value,
         requestTimestamp          |-> requestTimestamp.value,
         establishmentRejectCode   |-> establishmentRejectCode.value,
         offset21Padding1          |-> offset21Padding1.value,
         lastIncomingSeqNoOptional |-> lastIncomingSeqNoOptional.value ], lastIncomingSeqNoOptional.rest)

ZeroEstablishRejectMessage ==
    [ sessionId                 |-> [i \in 1 .. 4 |-> 0],
      sessionVerId              |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp          |-> [i \in 1 .. 8 |-> 0],
      establishmentRejectCode   |-> [i \in 1 .. 1 |-> 0],
      offset21Padding1          |-> [i \in 1 .. 1 |-> 0],
      lastIncomingSeqNoOptional |-> [i \in 1 .. 4 |-> 0] ]

(* Establish Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedEstablishRejectMessage ==
    { ZeroEstablishRejectMessage }
        \cup { [ZeroEstablishRejectMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroEstablishRejectMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroEstablishRejectMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablishRejectMessage EXCEPT !.establishmentRejectCode = one] : one \in Sample(1) }
        \cup { [ZeroEstablishRejectMessage EXCEPT !.offset21Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroEstablishRejectMessage EXCEPT !.lastIncomingSeqNoOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Terminate Message: 13 bytes                                             *)
(***************************************************************************)

TerminateMessage ==
    [ sessionId       : Sample(4),
      sessionVerId    : Sample(8),
      terminationCode : Sample(1) ]

EncodeTerminateMessage(message) ==
    message.sessionId
        \o message.sessionVerId
        \o message.terminationCode

DecodeTerminateMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionVerId == ReadBytes(sessionId.rest, 8) IN IF ~sessionVerId.ok THEN Fail ELSE
    LET terminationCode == ReadBytes(sessionVerId.rest, 1) IN IF ~terminationCode.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         sessionVerId    |-> sessionVerId.value,
         terminationCode |-> terminationCode.value ], terminationCode.rest)

ZeroTerminateMessage ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      sessionVerId    |-> [i \in 1 .. 8 |-> 0],
      terminationCode |-> [i \in 1 .. 1 |-> 0] ]

(* Terminate Message at zero, then each field in turn at the values it is checked at *)
CheckedTerminateMessage ==
    { ZeroTerminateMessage }
        \cup { [ZeroTerminateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroTerminateMessage EXCEPT !.sessionVerId = one] : one \in Sample(8) }
        \cup { [ZeroTerminateMessage EXCEPT !.terminationCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Not Applied Message: 8 bytes                                            *)
(***************************************************************************)

NotAppliedMessage ==
    [ fromSeqNo : Sample(4),
      count     : Sample(4) ]

EncodeNotAppliedMessage(message) ==
    message.fromSeqNo
        \o message.count

DecodeNotAppliedMessage(bytes) ==
    LET fromSeqNo == ReadBytes(bytes, 4) IN IF ~fromSeqNo.ok THEN Fail ELSE
    LET count == ReadBytes(fromSeqNo.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ fromSeqNo |-> fromSeqNo.value,
         count     |-> count.value ], count.rest)

ZeroNotAppliedMessage ==
    [ fromSeqNo |-> [i \in 1 .. 4 |-> 0],
      count     |-> [i \in 1 .. 4 |-> 0] ]

(* Not Applied Message at zero, then each field in turn at the values it is checked at *)
CheckedNotAppliedMessage ==
    { ZeroNotAppliedMessage }
        \cup { [ZeroNotAppliedMessage EXCEPT !.fromSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroNotAppliedMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequence Message: 4 bytes                                               *)
(***************************************************************************)

SequenceMessage ==
    [ nextSeqNo : Sample(4) ]

EncodeSequenceMessage(message) ==
    message.nextSeqNo

DecodeSequenceMessage(bytes) ==
    LET nextSeqNo == ReadBytes(bytes, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ nextSeqNo |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroSequenceMessage ==
    [ nextSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceMessage ==
    { ZeroSequenceMessage }
        \cup { [ZeroSequenceMessage EXCEPT !.nextSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Request Message: 20 bytes                                    *)
(***************************************************************************)

RetransmitRequestMessage ==
    [ sessionId : Sample(4),
      timestamp : Sample(8),
      fromSeqNo : Sample(4),
      count     : Sample(4) ]

EncodeRetransmitRequestMessage(message) ==
    message.sessionId
        \o message.timestamp
        \o message.fromSeqNo
        \o message.count

DecodeRetransmitRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sessionId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET fromSeqNo == ReadBytes(timestamp.rest, 4) IN IF ~fromSeqNo.ok THEN Fail ELSE
    LET count == ReadBytes(fromSeqNo.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value,
         timestamp |-> timestamp.value,
         fromSeqNo |-> fromSeqNo.value,
         count     |-> count.value ], count.rest)

ZeroRetransmitRequestMessage ==
    [ sessionId |-> [i \in 1 .. 4 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0],
      fromSeqNo |-> [i \in 1 .. 4 |-> 0],
      count     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmit Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequestMessage ==
    { ZeroRetransmitRequestMessage }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.fromSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmission Message: 20 bytes                                        *)
(***************************************************************************)

RetransmissionMessage ==
    [ sessionId        : Sample(4),
      requestTimestamp : Sample(8),
      nextSeqNo        : Sample(4),
      count            : Sample(4) ]

EncodeRetransmissionMessage(message) ==
    message.sessionId
        \o message.requestTimestamp
        \o message.nextSeqNo
        \o message.count

DecodeRetransmissionMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(sessionId.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(requestTimestamp.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET count == ReadBytes(nextSeqNo.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ sessionId        |-> sessionId.value,
         requestTimestamp |-> requestTimestamp.value,
         nextSeqNo        |-> nextSeqNo.value,
         count            |-> count.value ], count.rest)

ZeroRetransmissionMessage ==
    [ sessionId        |-> [i \in 1 .. 4 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo        |-> [i \in 1 .. 4 |-> 0],
      count            |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionMessage ==
    { ZeroRetransmissionMessage }
        \cup { [ZeroRetransmissionMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Reject Message: 13 bytes                                     *)
(***************************************************************************)

RetransmitRejectMessage ==
    [ sessionId            : Sample(4),
      requestTimestamp     : Sample(8),
      retransmitRejectCode : Sample(1) ]

EncodeRetransmitRejectMessage(message) ==
    message.sessionId
        \o message.requestTimestamp
        \o message.retransmitRejectCode

DecodeRetransmitRejectMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(sessionId.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET retransmitRejectCode == ReadBytes(requestTimestamp.rest, 1) IN IF ~retransmitRejectCode.ok THEN Fail ELSE
    Ok([ sessionId            |-> sessionId.value,
         requestTimestamp     |-> requestTimestamp.value,
         retransmitRejectCode |-> retransmitRejectCode.value ], retransmitRejectCode.rest)

ZeroRetransmitRejectMessage ==
    [ sessionId            |-> [i \in 1 .. 4 |-> 0],
      requestTimestamp     |-> [i \in 1 .. 8 |-> 0],
      retransmitRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRejectMessage ==
    { ZeroRetransmitRejectMessage }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.retransmitRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader ==
    { ZeroInboundBusinessHeader }
        \cup { [ZeroInboundBusinessHeader EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId ==
    { ZeroInvestorId }
        \cup { [ZeroInvestorId EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo ==
    [ memoData : SampleBytes ]

EncodeMemo(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo ==
    { ZeroMemo }
        \cup { [ZeroMemo EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Simple New Order Message                                                *)
(***************************************************************************)

SimpleNewOrderMessage ==
    [ inboundBusinessHeader          : InboundBusinessHeader,
      ordtagid                       : Sample(1),
      mmProtectionReset              : Sample(1),
      clordid                        : Sample(8),
      account                        : Sample(4),
      senderLocation                 : Sample(10),
      enteringTrader                 : Sample(5),
      selfTradePreventionInstruction : Sample(1),
      securityId                     : Sample(8),
      side                           : Sample(1),
      simpleOrdtype                  : Sample(1),
      timeInForceSimple              : Sample(1),
      routingInstruction             : Sample(1),
      orderQty                       : Sample(8),
      priceOptional                  : Sample(8),
      investorId                     : InvestorId,
      memo                           : Memo ]

EncodeSimpleNewOrderMessage(message) ==
    EncodeInboundBusinessHeader(message.inboundBusinessHeader)
        \o message.ordtagid
        \o message.mmProtectionReset
        \o message.clordid
        \o message.account
        \o message.senderLocation
        \o message.enteringTrader
        \o message.selfTradePreventionInstruction
        \o message.securityId
        \o message.side
        \o message.simpleOrdtype
        \o message.timeInForceSimple
        \o message.routingInstruction
        \o message.orderQty
        \o message.priceOptional
        \o EncodeInvestorId(message.investorId)
        \o EncodeMemo(message.memo)

DecodeSimpleNewOrderMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(inboundBusinessHeader.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET mmProtectionReset == ReadBytes(ordtagid.rest, 1) IN IF ~mmProtectionReset.ok THEN Fail ELSE
    LET clordid == ReadBytes(mmProtectionReset.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET account == ReadBytes(clordid.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET selfTradePreventionInstruction == ReadBytes(enteringTrader.rest, 1) IN IF ~selfTradePreventionInstruction.ok THEN Fail ELSE
    LET securityId == ReadBytes(selfTradePreventionInstruction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET simpleOrdtype == ReadBytes(side.rest, 1) IN IF ~simpleOrdtype.ok THEN Fail ELSE
    LET timeInForceSimple == ReadBytes(simpleOrdtype.rest, 1) IN IF ~timeInForceSimple.ok THEN Fail ELSE
    LET routingInstruction == ReadBytes(timeInForceSimple.rest, 1) IN IF ~routingInstruction.ok THEN Fail ELSE
    LET orderQty == ReadBytes(routingInstruction.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId(priceOptional.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET memo == DecodeMemo(investorId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader          |-> inboundBusinessHeader.value,
         ordtagid                       |-> ordtagid.value,
         mmProtectionReset              |-> mmProtectionReset.value,
         clordid                        |-> clordid.value,
         account                        |-> account.value,
         senderLocation                 |-> senderLocation.value,
         enteringTrader                 |-> enteringTrader.value,
         selfTradePreventionInstruction |-> selfTradePreventionInstruction.value,
         securityId                     |-> securityId.value,
         side                           |-> side.value,
         simpleOrdtype                  |-> simpleOrdtype.value,
         timeInForceSimple              |-> timeInForceSimple.value,
         routingInstruction             |-> routingInstruction.value,
         orderQty                       |-> orderQty.value,
         priceOptional                  |-> priceOptional.value,
         investorId                     |-> investorId.value,
         memo                           |-> memo.value ], memo.rest)

ZeroSimpleNewOrderMessage ==
    [ inboundBusinessHeader          |-> ZeroInboundBusinessHeader,
      ordtagid                       |-> [i \in 1 .. 1 |-> 0],
      mmProtectionReset              |-> [i \in 1 .. 1 |-> 0],
      clordid                        |-> [i \in 1 .. 8 |-> 0],
      account                        |-> [i \in 1 .. 4 |-> 0],
      senderLocation                 |-> [i \in 1 .. 10 |-> 0],
      enteringTrader                 |-> [i \in 1 .. 5 |-> 0],
      selfTradePreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      securityId                     |-> [i \in 1 .. 8 |-> 0],
      side                           |-> [i \in 1 .. 1 |-> 0],
      simpleOrdtype                  |-> [i \in 1 .. 1 |-> 0],
      timeInForceSimple              |-> [i \in 1 .. 1 |-> 0],
      routingInstruction             |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 8 |-> 0],
      priceOptional                  |-> [i \in 1 .. 8 |-> 0],
      investorId                     |-> ZeroInvestorId,
      memo                           |-> ZeroMemo ]

(* Simple New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleNewOrderMessage ==
    { ZeroSimpleNewOrderMessage }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.mmProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.selfTradePreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.simpleOrdtype = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.timeInForceSimple = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.routingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.memo = one] : one \in CheckedMemo }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader2 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader2(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader2(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader2 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader2 ==
    { ZeroInboundBusinessHeader2 }
        \cup { [ZeroInboundBusinessHeader2 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader2 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader2 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId2 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId2(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId2(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId2 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId2 ==
    { ZeroInvestorId2 }
        \cup { [ZeroInvestorId2 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId2 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId2 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo2 ==
    [ memoData : SampleBytes ]

EncodeMemo2(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo2(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo2 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo2 ==
    { ZeroMemo2 }
        \cup { [ZeroMemo2 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Simple Modify Order Message                                             *)
(***************************************************************************)

SimpleModifyOrderMessage ==
    [ inboundBusinessHeader          : InboundBusinessHeader2,
      ordtagid                       : Sample(1),
      mmProtectionReset              : Sample(1),
      clordid                        : Sample(8),
      account                        : Sample(4),
      senderLocation                 : Sample(10),
      enteringTrader                 : Sample(5),
      selfTradePreventionInstruction : Sample(1),
      securityId                     : Sample(8),
      side                           : Sample(1),
      simpleOrdtype                  : Sample(1),
      timeInForceSimple              : Sample(1),
      routingInstruction             : Sample(1),
      orderQty                       : Sample(8),
      priceOptional                  : Sample(8),
      orderIdOptional                : Sample(8),
      origclordid                    : Sample(8),
      investorId                     : InvestorId2,
      memo                           : Memo2 ]

EncodeSimpleModifyOrderMessage(message) ==
    EncodeInboundBusinessHeader2(message.inboundBusinessHeader)
        \o message.ordtagid
        \o message.mmProtectionReset
        \o message.clordid
        \o message.account
        \o message.senderLocation
        \o message.enteringTrader
        \o message.selfTradePreventionInstruction
        \o message.securityId
        \o message.side
        \o message.simpleOrdtype
        \o message.timeInForceSimple
        \o message.routingInstruction
        \o message.orderQty
        \o message.priceOptional
        \o message.orderIdOptional
        \o message.origclordid
        \o EncodeInvestorId2(message.investorId)
        \o EncodeMemo2(message.memo)

DecodeSimpleModifyOrderMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader2(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(inboundBusinessHeader.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET mmProtectionReset == ReadBytes(ordtagid.rest, 1) IN IF ~mmProtectionReset.ok THEN Fail ELSE
    LET clordid == ReadBytes(mmProtectionReset.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET account == ReadBytes(clordid.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET selfTradePreventionInstruction == ReadBytes(enteringTrader.rest, 1) IN IF ~selfTradePreventionInstruction.ok THEN Fail ELSE
    LET securityId == ReadBytes(selfTradePreventionInstruction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET simpleOrdtype == ReadBytes(side.rest, 1) IN IF ~simpleOrdtype.ok THEN Fail ELSE
    LET timeInForceSimple == ReadBytes(simpleOrdtype.rest, 1) IN IF ~timeInForceSimple.ok THEN Fail ELSE
    LET routingInstruction == ReadBytes(timeInForceSimple.rest, 1) IN IF ~routingInstruction.ok THEN Fail ELSE
    LET orderQty == ReadBytes(routingInstruction.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(priceOptional.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origclordid == ReadBytes(orderIdOptional.rest, 8) IN IF ~origclordid.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId2(origclordid.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET memo == DecodeMemo2(investorId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader          |-> inboundBusinessHeader.value,
         ordtagid                       |-> ordtagid.value,
         mmProtectionReset              |-> mmProtectionReset.value,
         clordid                        |-> clordid.value,
         account                        |-> account.value,
         senderLocation                 |-> senderLocation.value,
         enteringTrader                 |-> enteringTrader.value,
         selfTradePreventionInstruction |-> selfTradePreventionInstruction.value,
         securityId                     |-> securityId.value,
         side                           |-> side.value,
         simpleOrdtype                  |-> simpleOrdtype.value,
         timeInForceSimple              |-> timeInForceSimple.value,
         routingInstruction             |-> routingInstruction.value,
         orderQty                       |-> orderQty.value,
         priceOptional                  |-> priceOptional.value,
         orderIdOptional                |-> orderIdOptional.value,
         origclordid                    |-> origclordid.value,
         investorId                     |-> investorId.value,
         memo                           |-> memo.value ], memo.rest)

ZeroSimpleModifyOrderMessage ==
    [ inboundBusinessHeader          |-> ZeroInboundBusinessHeader2,
      ordtagid                       |-> [i \in 1 .. 1 |-> 0],
      mmProtectionReset              |-> [i \in 1 .. 1 |-> 0],
      clordid                        |-> [i \in 1 .. 8 |-> 0],
      account                        |-> [i \in 1 .. 4 |-> 0],
      senderLocation                 |-> [i \in 1 .. 10 |-> 0],
      enteringTrader                 |-> [i \in 1 .. 5 |-> 0],
      selfTradePreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      securityId                     |-> [i \in 1 .. 8 |-> 0],
      side                           |-> [i \in 1 .. 1 |-> 0],
      simpleOrdtype                  |-> [i \in 1 .. 1 |-> 0],
      timeInForceSimple              |-> [i \in 1 .. 1 |-> 0],
      routingInstruction             |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 8 |-> 0],
      priceOptional                  |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional                |-> [i \in 1 .. 8 |-> 0],
      origclordid                    |-> [i \in 1 .. 8 |-> 0],
      investorId                     |-> ZeroInvestorId2,
      memo                           |-> ZeroMemo2 ]

(* Simple Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleModifyOrderMessage ==
    { ZeroSimpleModifyOrderMessage }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader2 }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.mmProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.selfTradePreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.simpleOrdtype = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.timeInForceSimple = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.routingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.origclordid = one] : one \in Sample(8) }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId2 }
        \cup { [ZeroSimpleModifyOrderMessage EXCEPT !.memo = one] : one \in CheckedMemo2 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader3 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader3(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader3(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader3 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader3 ==
    { ZeroInboundBusinessHeader3 }
        \cup { [ZeroInboundBusinessHeader3 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader3 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader3 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Custodian Info: 12 bytes                                                *)
(***************************************************************************)

CustodianInfo ==
    [ custodian             : Sample(4),
      custodyAccount        : Sample(4),
      custodyAllocationType : Sample(4) ]

EncodeCustodianInfo(message) ==
    message.custodian
        \o message.custodyAccount
        \o message.custodyAllocationType

DecodeCustodianInfo(bytes) ==
    LET custodian == ReadBytes(bytes, 4) IN IF ~custodian.ok THEN Fail ELSE
    LET custodyAccount == ReadBytes(custodian.rest, 4) IN IF ~custodyAccount.ok THEN Fail ELSE
    LET custodyAllocationType == ReadBytes(custodyAccount.rest, 4) IN IF ~custodyAllocationType.ok THEN Fail ELSE
    Ok([ custodian             |-> custodian.value,
         custodyAccount        |-> custodyAccount.value,
         custodyAllocationType |-> custodyAllocationType.value ], custodyAllocationType.rest)

ZeroCustodianInfo ==
    [ custodian             |-> [i \in 1 .. 4 |-> 0],
      custodyAccount        |-> [i \in 1 .. 4 |-> 0],
      custodyAllocationType |-> [i \in 1 .. 4 |-> 0] ]

(* Custodian Info at zero, then each field in turn at the values it is checked at *)
CheckedCustodianInfo ==
    { ZeroCustodianInfo }
        \cup { [ZeroCustodianInfo EXCEPT !.custodian = one] : one \in Sample(4) }
        \cup { [ZeroCustodianInfo EXCEPT !.custodyAccount = one] : one \in Sample(4) }
        \cup { [ZeroCustodianInfo EXCEPT !.custodyAllocationType = one] : one \in Sample(4) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId3 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId3(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId3(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId3 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId3 ==
    { ZeroInvestorId3 }
        \cup { [ZeroInvestorId3 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId3 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId3 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId ==
    [ deskIdData : SampleBytes ]

EncodeDeskId(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId ==
    { ZeroDeskId }
        \cup { [ZeroDeskId EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo3 ==
    [ memoData : SampleBytes ]

EncodeMemo3(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo3(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo3 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo3 ==
    { ZeroMemo3 }
        \cup { [ZeroMemo3 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* New Order Single Message                                                *)
(***************************************************************************)

NewOrderSingleMessage ==
    [ inboundBusinessHeader          : InboundBusinessHeader3,
      ordtagid                       : Sample(1),
      mmProtectionReset              : Sample(1),
      clordid                        : Sample(8),
      account                        : Sample(4),
      senderLocation                 : Sample(10),
      enteringTrader                 : Sample(5),
      selfTradePreventionInstruction : Sample(1),
      securityId                     : Sample(8),
      side                           : Sample(1),
      ordtype                        : Sample(1),
      timeInForce                    : Sample(1),
      routingInstruction             : Sample(1),
      orderQty                       : Sample(8),
      priceOptional                  : Sample(8),
      stopPx                         : Sample(8),
      minQty                         : Sample(8),
      maxFloor                       : Sample(8),
      executingTraderOptional        : Sample(5),
      expireDate                     : Sample(2),
      custodianInfo                  : CustodianInfo,
      investorId                     : InvestorId3,
      strategyId                     : Sample(4),
      deskId                         : DeskId,
      memo                           : Memo3 ]

EncodeNewOrderSingleMessage(message) ==
    EncodeInboundBusinessHeader3(message.inboundBusinessHeader)
        \o message.ordtagid
        \o message.mmProtectionReset
        \o message.clordid
        \o message.account
        \o message.senderLocation
        \o message.enteringTrader
        \o message.selfTradePreventionInstruction
        \o message.securityId
        \o message.side
        \o message.ordtype
        \o message.timeInForce
        \o message.routingInstruction
        \o message.orderQty
        \o message.priceOptional
        \o message.stopPx
        \o message.minQty
        \o message.maxFloor
        \o message.executingTraderOptional
        \o message.expireDate
        \o EncodeCustodianInfo(message.custodianInfo)
        \o EncodeInvestorId3(message.investorId)
        \o message.strategyId
        \o EncodeDeskId(message.deskId)
        \o EncodeMemo3(message.memo)

DecodeNewOrderSingleMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader3(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(inboundBusinessHeader.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET mmProtectionReset == ReadBytes(ordtagid.rest, 1) IN IF ~mmProtectionReset.ok THEN Fail ELSE
    LET clordid == ReadBytes(mmProtectionReset.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET account == ReadBytes(clordid.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET selfTradePreventionInstruction == ReadBytes(enteringTrader.rest, 1) IN IF ~selfTradePreventionInstruction.ok THEN Fail ELSE
    LET securityId == ReadBytes(selfTradePreventionInstruction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordtype == ReadBytes(side.rest, 1) IN IF ~ordtype.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordtype.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET routingInstruction == ReadBytes(timeInForce.rest, 1) IN IF ~routingInstruction.ok THEN Fail ELSE
    LET orderQty == ReadBytes(routingInstruction.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 8) IN IF ~maxFloor.ok THEN Fail ELSE
    LET executingTraderOptional == ReadBytes(maxFloor.rest, 5) IN IF ~executingTraderOptional.ok THEN Fail ELSE
    LET expireDate == ReadBytes(executingTraderOptional.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET custodianInfo == DecodeCustodianInfo(expireDate.rest) IN IF ~custodianInfo.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId3(custodianInfo.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(investorId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId(strategyId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo3(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader          |-> inboundBusinessHeader.value,
         ordtagid                       |-> ordtagid.value,
         mmProtectionReset              |-> mmProtectionReset.value,
         clordid                        |-> clordid.value,
         account                        |-> account.value,
         senderLocation                 |-> senderLocation.value,
         enteringTrader                 |-> enteringTrader.value,
         selfTradePreventionInstruction |-> selfTradePreventionInstruction.value,
         securityId                     |-> securityId.value,
         side                           |-> side.value,
         ordtype                        |-> ordtype.value,
         timeInForce                    |-> timeInForce.value,
         routingInstruction             |-> routingInstruction.value,
         orderQty                       |-> orderQty.value,
         priceOptional                  |-> priceOptional.value,
         stopPx                         |-> stopPx.value,
         minQty                         |-> minQty.value,
         maxFloor                       |-> maxFloor.value,
         executingTraderOptional        |-> executingTraderOptional.value,
         expireDate                     |-> expireDate.value,
         custodianInfo                  |-> custodianInfo.value,
         investorId                     |-> investorId.value,
         strategyId                     |-> strategyId.value,
         deskId                         |-> deskId.value,
         memo                           |-> memo.value ], memo.rest)

ZeroNewOrderSingleMessage ==
    [ inboundBusinessHeader          |-> ZeroInboundBusinessHeader3,
      ordtagid                       |-> [i \in 1 .. 1 |-> 0],
      mmProtectionReset              |-> [i \in 1 .. 1 |-> 0],
      clordid                        |-> [i \in 1 .. 8 |-> 0],
      account                        |-> [i \in 1 .. 4 |-> 0],
      senderLocation                 |-> [i \in 1 .. 10 |-> 0],
      enteringTrader                 |-> [i \in 1 .. 5 |-> 0],
      selfTradePreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      securityId                     |-> [i \in 1 .. 8 |-> 0],
      side                           |-> [i \in 1 .. 1 |-> 0],
      ordtype                        |-> [i \in 1 .. 1 |-> 0],
      timeInForce                    |-> [i \in 1 .. 1 |-> 0],
      routingInstruction             |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 8 |-> 0],
      priceOptional                  |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
      minQty                         |-> [i \in 1 .. 8 |-> 0],
      maxFloor                       |-> [i \in 1 .. 8 |-> 0],
      executingTraderOptional        |-> [i \in 1 .. 5 |-> 0],
      expireDate                     |-> [i \in 1 .. 2 |-> 0],
      custodianInfo                  |-> ZeroCustodianInfo,
      investorId                     |-> ZeroInvestorId3,
      strategyId                     |-> [i \in 1 .. 4 |-> 0],
      deskId                         |-> ZeroDeskId,
      memo                           |-> ZeroMemo3 ]

(* New Order Single Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleMessage ==
    { ZeroNewOrderSingleMessage }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader3 }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.mmProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.selfTradePreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.ordtype = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.routingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.maxFloor = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.executingTraderOptional = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.custodianInfo = one] : one \in CheckedCustodianInfo }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId3 }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.deskId = one] : one \in CheckedDeskId }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.memo = one] : one \in CheckedMemo3 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader4 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader4(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader4(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader4 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader4 ==
    { ZeroInboundBusinessHeader4 }
        \cup { [ZeroInboundBusinessHeader4 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader4 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader4 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Custodian Info: 12 bytes                                                *)
(***************************************************************************)

CustodianInfo2 ==
    [ custodian             : Sample(4),
      custodyAccount        : Sample(4),
      custodyAllocationType : Sample(4) ]

EncodeCustodianInfo2(message) ==
    message.custodian
        \o message.custodyAccount
        \o message.custodyAllocationType

DecodeCustodianInfo2(bytes) ==
    LET custodian == ReadBytes(bytes, 4) IN IF ~custodian.ok THEN Fail ELSE
    LET custodyAccount == ReadBytes(custodian.rest, 4) IN IF ~custodyAccount.ok THEN Fail ELSE
    LET custodyAllocationType == ReadBytes(custodyAccount.rest, 4) IN IF ~custodyAllocationType.ok THEN Fail ELSE
    Ok([ custodian             |-> custodian.value,
         custodyAccount        |-> custodyAccount.value,
         custodyAllocationType |-> custodyAllocationType.value ], custodyAllocationType.rest)

ZeroCustodianInfo2 ==
    [ custodian             |-> [i \in 1 .. 4 |-> 0],
      custodyAccount        |-> [i \in 1 .. 4 |-> 0],
      custodyAllocationType |-> [i \in 1 .. 4 |-> 0] ]

(* Custodian Info at zero, then each field in turn at the values it is checked at *)
CheckedCustodianInfo2 ==
    { ZeroCustodianInfo2 }
        \cup { [ZeroCustodianInfo2 EXCEPT !.custodian = one] : one \in Sample(4) }
        \cup { [ZeroCustodianInfo2 EXCEPT !.custodyAccount = one] : one \in Sample(4) }
        \cup { [ZeroCustodianInfo2 EXCEPT !.custodyAllocationType = one] : one \in Sample(4) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId4 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId4(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId4(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId4 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId4 ==
    { ZeroInvestorId4 }
        \cup { [ZeroInvestorId4 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId4 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId4 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId2 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId2(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId2(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId2 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId2 ==
    { ZeroDeskId2 }
        \cup { [ZeroDeskId2 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo4 ==
    [ memoData : SampleBytes ]

EncodeMemo4(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo4(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo4 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo4 ==
    { ZeroMemo4 }
        \cup { [ZeroMemo4 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Order Cancel Replace Request Message                                    *)
(***************************************************************************)

OrderCancelReplaceRequestMessage ==
    [ inboundBusinessHeader          : InboundBusinessHeader4,
      ordtagid                       : Sample(1),
      mmProtectionReset              : Sample(1),
      clordid                        : Sample(8),
      account                        : Sample(4),
      senderLocation                 : Sample(10),
      enteringTrader                 : Sample(5),
      selfTradePreventionInstruction : Sample(1),
      securityId                     : Sample(8),
      side                           : Sample(1),
      ordtype                        : Sample(1),
      timeInForceOptional            : Sample(1),
      routingInstruction             : Sample(1),
      orderQty                       : Sample(8),
      priceOptional                  : Sample(8),
      orderIdOptional                : Sample(8),
      origclordid                    : Sample(8),
      stopPx                         : Sample(8),
      minQty                         : Sample(8),
      maxFloor                       : Sample(8),
      executingTraderOptional        : Sample(5),
      accountType                    : Sample(1),
      expireDate                     : Sample(2),
      custodianInfo                  : CustodianInfo2,
      investorId                     : InvestorId4,
      strategyId                     : Sample(4),
      deskId                         : DeskId2,
      memo                           : Memo4 ]

EncodeOrderCancelReplaceRequestMessage(message) ==
    EncodeInboundBusinessHeader4(message.inboundBusinessHeader)
        \o message.ordtagid
        \o message.mmProtectionReset
        \o message.clordid
        \o message.account
        \o message.senderLocation
        \o message.enteringTrader
        \o message.selfTradePreventionInstruction
        \o message.securityId
        \o message.side
        \o message.ordtype
        \o message.timeInForceOptional
        \o message.routingInstruction
        \o message.orderQty
        \o message.priceOptional
        \o message.orderIdOptional
        \o message.origclordid
        \o message.stopPx
        \o message.minQty
        \o message.maxFloor
        \o message.executingTraderOptional
        \o message.accountType
        \o message.expireDate
        \o EncodeCustodianInfo2(message.custodianInfo)
        \o EncodeInvestorId4(message.investorId)
        \o message.strategyId
        \o EncodeDeskId2(message.deskId)
        \o EncodeMemo4(message.memo)

DecodeOrderCancelReplaceRequestMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader4(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(inboundBusinessHeader.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET mmProtectionReset == ReadBytes(ordtagid.rest, 1) IN IF ~mmProtectionReset.ok THEN Fail ELSE
    LET clordid == ReadBytes(mmProtectionReset.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET account == ReadBytes(clordid.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET selfTradePreventionInstruction == ReadBytes(enteringTrader.rest, 1) IN IF ~selfTradePreventionInstruction.ok THEN Fail ELSE
    LET securityId == ReadBytes(selfTradePreventionInstruction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordtype == ReadBytes(side.rest, 1) IN IF ~ordtype.ok THEN Fail ELSE
    LET timeInForceOptional == ReadBytes(ordtype.rest, 1) IN IF ~timeInForceOptional.ok THEN Fail ELSE
    LET routingInstruction == ReadBytes(timeInForceOptional.rest, 1) IN IF ~routingInstruction.ok THEN Fail ELSE
    LET orderQty == ReadBytes(routingInstruction.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(priceOptional.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origclordid == ReadBytes(orderIdOptional.rest, 8) IN IF ~origclordid.ok THEN Fail ELSE
    LET stopPx == ReadBytes(origclordid.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 8) IN IF ~maxFloor.ok THEN Fail ELSE
    LET executingTraderOptional == ReadBytes(maxFloor.rest, 5) IN IF ~executingTraderOptional.ok THEN Fail ELSE
    LET accountType == ReadBytes(executingTraderOptional.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET expireDate == ReadBytes(accountType.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET custodianInfo == DecodeCustodianInfo2(expireDate.rest) IN IF ~custodianInfo.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId4(custodianInfo.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(investorId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId2(strategyId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo4(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader          |-> inboundBusinessHeader.value,
         ordtagid                       |-> ordtagid.value,
         mmProtectionReset              |-> mmProtectionReset.value,
         clordid                        |-> clordid.value,
         account                        |-> account.value,
         senderLocation                 |-> senderLocation.value,
         enteringTrader                 |-> enteringTrader.value,
         selfTradePreventionInstruction |-> selfTradePreventionInstruction.value,
         securityId                     |-> securityId.value,
         side                           |-> side.value,
         ordtype                        |-> ordtype.value,
         timeInForceOptional            |-> timeInForceOptional.value,
         routingInstruction             |-> routingInstruction.value,
         orderQty                       |-> orderQty.value,
         priceOptional                  |-> priceOptional.value,
         orderIdOptional                |-> orderIdOptional.value,
         origclordid                    |-> origclordid.value,
         stopPx                         |-> stopPx.value,
         minQty                         |-> minQty.value,
         maxFloor                       |-> maxFloor.value,
         executingTraderOptional        |-> executingTraderOptional.value,
         accountType                    |-> accountType.value,
         expireDate                     |-> expireDate.value,
         custodianInfo                  |-> custodianInfo.value,
         investorId                     |-> investorId.value,
         strategyId                     |-> strategyId.value,
         deskId                         |-> deskId.value,
         memo                           |-> memo.value ], memo.rest)

ZeroOrderCancelReplaceRequestMessage ==
    [ inboundBusinessHeader          |-> ZeroInboundBusinessHeader4,
      ordtagid                       |-> [i \in 1 .. 1 |-> 0],
      mmProtectionReset              |-> [i \in 1 .. 1 |-> 0],
      clordid                        |-> [i \in 1 .. 8 |-> 0],
      account                        |-> [i \in 1 .. 4 |-> 0],
      senderLocation                 |-> [i \in 1 .. 10 |-> 0],
      enteringTrader                 |-> [i \in 1 .. 5 |-> 0],
      selfTradePreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      securityId                     |-> [i \in 1 .. 8 |-> 0],
      side                           |-> [i \in 1 .. 1 |-> 0],
      ordtype                        |-> [i \in 1 .. 1 |-> 0],
      timeInForceOptional            |-> [i \in 1 .. 1 |-> 0],
      routingInstruction             |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 8 |-> 0],
      priceOptional                  |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional                |-> [i \in 1 .. 8 |-> 0],
      origclordid                    |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
      minQty                         |-> [i \in 1 .. 8 |-> 0],
      maxFloor                       |-> [i \in 1 .. 8 |-> 0],
      executingTraderOptional        |-> [i \in 1 .. 5 |-> 0],
      accountType                    |-> [i \in 1 .. 1 |-> 0],
      expireDate                     |-> [i \in 1 .. 2 |-> 0],
      custodianInfo                  |-> ZeroCustodianInfo2,
      investorId                     |-> ZeroInvestorId4,
      strategyId                     |-> [i \in 1 .. 4 |-> 0],
      deskId                         |-> ZeroDeskId2,
      memo                           |-> ZeroMemo4 ]

(* Order Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceRequestMessage ==
    { ZeroOrderCancelReplaceRequestMessage }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader4 }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.mmProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.selfTradePreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.ordtype = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.timeInForceOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.routingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.origclordid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.maxFloor = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.executingTraderOptional = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.custodianInfo = one] : one \in CheckedCustodianInfo2 }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId4 }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.deskId = one] : one \in CheckedDeskId2 }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.memo = one] : one \in CheckedMemo4 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader5 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader5(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader5(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader5 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader5 ==
    { ZeroInboundBusinessHeader5 }
        \cup { [ZeroInboundBusinessHeader5 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader5 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader5 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId3 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId3(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId3(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId3 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId3 ==
    { ZeroDeskId3 }
        \cup { [ZeroDeskId3 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo5 ==
    [ memoData : SampleBytes ]

EncodeMemo5(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo5(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo5 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo5 ==
    { ZeroMemo5 }
        \cup { [ZeroMemo5 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Order Cancel Request Message                                            *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ inboundBusinessHeader         : InboundBusinessHeader5,
      offset18Padding2              : Sample(2),
      clordid                       : Sample(8),
      securityId                    : Sample(8),
      orderIdOptional               : Sample(8),
      origclordid                   : Sample(8),
      side                          : Sample(1),
      singleCancelRestatementReason : Sample(1),
      offset54Padding2              : Sample(2),
      senderLocation                : Sample(10),
      enteringTrader                : Sample(5),
      executingTraderOptional       : Sample(5),
      deskId                        : DeskId3,
      memo                          : Memo5 ]

EncodeOrderCancelRequestMessage(message) ==
    EncodeInboundBusinessHeader5(message.inboundBusinessHeader)
        \o message.offset18Padding2
        \o message.clordid
        \o message.securityId
        \o message.orderIdOptional
        \o message.origclordid
        \o message.side
        \o message.singleCancelRestatementReason
        \o message.offset54Padding2
        \o message.senderLocation
        \o message.enteringTrader
        \o message.executingTraderOptional
        \o EncodeDeskId3(message.deskId)
        \o EncodeMemo5(message.memo)

DecodeOrderCancelRequestMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader5(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET offset18Padding2 == ReadBytes(inboundBusinessHeader.rest, 2) IN IF ~offset18Padding2.ok THEN Fail ELSE
    LET clordid == ReadBytes(offset18Padding2.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET securityId == ReadBytes(clordid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(securityId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origclordid == ReadBytes(orderIdOptional.rest, 8) IN IF ~origclordid.ok THEN Fail ELSE
    LET side == ReadBytes(origclordid.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET singleCancelRestatementReason == ReadBytes(side.rest, 1) IN IF ~singleCancelRestatementReason.ok THEN Fail ELSE
    LET offset54Padding2 == ReadBytes(singleCancelRestatementReason.rest, 2) IN IF ~offset54Padding2.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(offset54Padding2.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET executingTraderOptional == ReadBytes(enteringTrader.rest, 5) IN IF ~executingTraderOptional.ok THEN Fail ELSE
    LET deskId == DecodeDeskId3(executingTraderOptional.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo5(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader         |-> inboundBusinessHeader.value,
         offset18Padding2              |-> offset18Padding2.value,
         clordid                       |-> clordid.value,
         securityId                    |-> securityId.value,
         orderIdOptional               |-> orderIdOptional.value,
         origclordid                   |-> origclordid.value,
         side                          |-> side.value,
         singleCancelRestatementReason |-> singleCancelRestatementReason.value,
         offset54Padding2              |-> offset54Padding2.value,
         senderLocation                |-> senderLocation.value,
         enteringTrader                |-> enteringTrader.value,
         executingTraderOptional       |-> executingTraderOptional.value,
         deskId                        |-> deskId.value,
         memo                          |-> memo.value ], memo.rest)

ZeroOrderCancelRequestMessage ==
    [ inboundBusinessHeader         |-> ZeroInboundBusinessHeader5,
      offset18Padding2              |-> [i \in 1 .. 2 |-> 0],
      clordid                       |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional               |-> [i \in 1 .. 8 |-> 0],
      origclordid                   |-> [i \in 1 .. 8 |-> 0],
      side                          |-> [i \in 1 .. 1 |-> 0],
      singleCancelRestatementReason |-> [i \in 1 .. 1 |-> 0],
      offset54Padding2              |-> [i \in 1 .. 2 |-> 0],
      senderLocation                |-> [i \in 1 .. 10 |-> 0],
      enteringTrader                |-> [i \in 1 .. 5 |-> 0],
      executingTraderOptional       |-> [i \in 1 .. 5 |-> 0],
      deskId                        |-> ZeroDeskId3,
      memo                          |-> ZeroMemo5 ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader5 }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.offset18Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.origclordid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.singleCancelRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.offset54Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.executingTraderOptional = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.deskId = one] : one \in CheckedDeskId3 }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.memo = one] : one \in CheckedMemo5 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader6 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader6(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader6(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader6 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader6 ==
    { ZeroInboundBusinessHeader6 }
        \cup { [ZeroInboundBusinessHeader6 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader6 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader6 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Cross Sides Group: 18 bytes                                             *)
(***************************************************************************)

CrossSidesGroup ==
    [ side                 : Sample(1),
      offset1Padding1      : Sample(1),
      account              : Sample(4),
      enteringFirmOptional : Sample(4),
      clordid              : Sample(8) ]

EncodeCrossSidesGroup(message) ==
    message.side
        \o message.offset1Padding1
        \o message.account
        \o message.enteringFirmOptional
        \o message.clordid

DecodeCrossSidesGroup(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET offset1Padding1 == ReadBytes(side.rest, 1) IN IF ~offset1Padding1.ok THEN Fail ELSE
    LET account == ReadBytes(offset1Padding1.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET enteringFirmOptional == ReadBytes(account.rest, 4) IN IF ~enteringFirmOptional.ok THEN Fail ELSE
    LET clordid == ReadBytes(enteringFirmOptional.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ side                 |-> side.value,
         offset1Padding1      |-> offset1Padding1.value,
         account              |-> account.value,
         enteringFirmOptional |-> enteringFirmOptional.value,
         clordid              |-> clordid.value ], clordid.rest)

ZeroCrossSidesGroup ==
    [ side                 |-> [i \in 1 .. 1 |-> 0],
      offset1Padding1      |-> [i \in 1 .. 1 |-> 0],
      account              |-> [i \in 1 .. 4 |-> 0],
      enteringFirmOptional |-> [i \in 1 .. 4 |-> 0],
      clordid              |-> [i \in 1 .. 8 |-> 0] ]

(* Cross Sides Group at zero, then each field in turn at the values it is checked at *)
CheckedCrossSidesGroup ==
    { ZeroCrossSidesGroup }
        \cup { [ZeroCrossSidesGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCrossSidesGroup EXCEPT !.offset1Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroCrossSidesGroup EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroCrossSidesGroup EXCEPT !.enteringFirmOptional = one] : one \in Sample(4) }
        \cup { [ZeroCrossSidesGroup EXCEPT !.clordid = one] : one \in Sample(8) }

(* A run of Cross Sides Group, written one after another *)
RECURSIVE EncodeCrossSidesGroupList(_)
EncodeCrossSidesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCrossSidesGroup(Head(messages)) \o EncodeCrossSidesGroupList(Tail(messages))

(* As many Cross Sides Group as the field that counts them says *)
RECURSIVE ReadCrossSidesGroupList(_, _)
ReadCrossSidesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCrossSidesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCrossSidesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cross Sides Group of each kind, for the lists that carry them *)
OneCrossSidesGroup == { ZeroCrossSidesGroup }

(***************************************************************************)
(* Cross Sides Groups                                                      *)
(***************************************************************************)

CrossSidesGroups ==
    [ blockLength     : Sample(2),
      crossSidesGroup : SampleLists(OneCrossSidesGroup) ]

EncodeCrossSidesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.crossSidesGroup), 1)
        \o EncodeCrossSidesGroupList(message.crossSidesGroup)

DecodeCrossSidesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET crossSidesGroup == ReadCrossSidesGroupList(numInGroup.rest, numInGroup.value) IN IF ~crossSidesGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         crossSidesGroup |-> crossSidesGroup.value ], crossSidesGroup.rest)

ZeroCrossSidesGroups ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      crossSidesGroup |-> << >> ]

(* Cross Sides Groups at zero, then each field in turn at the values it is checked at *)
CheckedCrossSidesGroups ==
    { ZeroCrossSidesGroups }
        \cup { [ZeroCrossSidesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroCrossSidesGroups EXCEPT !.crossSidesGroup = one] : one \in SampleLists(OneCrossSidesGroup) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId4 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId4(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId4(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId4 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId4 ==
    { ZeroDeskId4 }
        \cup { [ZeroDeskId4 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo6 ==
    [ memoData : SampleBytes ]

EncodeMemo6(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo6(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo6 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo6 ==
    { ZeroMemo6 }
        \cup { [ZeroMemo6 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* New Order Cross Message                                                 *)
(***************************************************************************)

NewOrderCrossMessage ==
    [ inboundBusinessHeader   : InboundBusinessHeader6,
      offset18Padding2        : Sample(2),
      crossid                 : Sample(8),
      senderLocation          : Sample(10),
      enteringTrader          : Sample(5),
      executingTraderOptional : Sample(5),
      securityId              : Sample(8),
      orderQty                : Sample(8),
      price                   : Sample(8),
      crossedIndicator        : Sample(2),
      crossType               : Sample(1),
      crossPrioritization     : Sample(1),
      maxSweepQty             : Sample(8),
      crossSidesGroups        : CrossSidesGroups,
      deskId                  : DeskId4,
      memo                    : Memo6 ]

EncodeNewOrderCrossMessage(message) ==
    EncodeInboundBusinessHeader6(message.inboundBusinessHeader)
        \o message.offset18Padding2
        \o message.crossid
        \o message.senderLocation
        \o message.enteringTrader
        \o message.executingTraderOptional
        \o message.securityId
        \o message.orderQty
        \o message.price
        \o message.crossedIndicator
        \o message.crossType
        \o message.crossPrioritization
        \o message.maxSweepQty
        \o EncodeCrossSidesGroups(message.crossSidesGroups)
        \o EncodeDeskId4(message.deskId)
        \o EncodeMemo6(message.memo)

DecodeNewOrderCrossMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader6(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET offset18Padding2 == ReadBytes(inboundBusinessHeader.rest, 2) IN IF ~offset18Padding2.ok THEN Fail ELSE
    LET crossid == ReadBytes(offset18Padding2.rest, 8) IN IF ~crossid.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(crossid.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET executingTraderOptional == ReadBytes(enteringTrader.rest, 5) IN IF ~executingTraderOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(executingTraderOptional.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(price.rest, 2) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossedIndicator.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossPrioritization == ReadBytes(crossType.rest, 1) IN IF ~crossPrioritization.ok THEN Fail ELSE
    LET maxSweepQty == ReadBytes(crossPrioritization.rest, 8) IN IF ~maxSweepQty.ok THEN Fail ELSE
    LET crossSidesGroups == DecodeCrossSidesGroups(maxSweepQty.rest) IN IF ~crossSidesGroups.ok THEN Fail ELSE
    LET deskId == DecodeDeskId4(crossSidesGroups.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo6(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader   |-> inboundBusinessHeader.value,
         offset18Padding2        |-> offset18Padding2.value,
         crossid                 |-> crossid.value,
         senderLocation          |-> senderLocation.value,
         enteringTrader          |-> enteringTrader.value,
         executingTraderOptional |-> executingTraderOptional.value,
         securityId              |-> securityId.value,
         orderQty                |-> orderQty.value,
         price                   |-> price.value,
         crossedIndicator        |-> crossedIndicator.value,
         crossType               |-> crossType.value,
         crossPrioritization     |-> crossPrioritization.value,
         maxSweepQty             |-> maxSweepQty.value,
         crossSidesGroups        |-> crossSidesGroups.value,
         deskId                  |-> deskId.value,
         memo                    |-> memo.value ], memo.rest)

ZeroNewOrderCrossMessage ==
    [ inboundBusinessHeader   |-> ZeroInboundBusinessHeader6,
      offset18Padding2        |-> [i \in 1 .. 2 |-> 0],
      crossid                 |-> [i \in 1 .. 8 |-> 0],
      senderLocation          |-> [i \in 1 .. 10 |-> 0],
      enteringTrader          |-> [i \in 1 .. 5 |-> 0],
      executingTraderOptional |-> [i \in 1 .. 5 |-> 0],
      securityId              |-> [i \in 1 .. 8 |-> 0],
      orderQty                |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      crossedIndicator        |-> [i \in 1 .. 2 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      crossPrioritization     |-> [i \in 1 .. 1 |-> 0],
      maxSweepQty             |-> [i \in 1 .. 8 |-> 0],
      crossSidesGroups        |-> ZeroCrossSidesGroups,
      deskId                  |-> ZeroDeskId4,
      memo                    |-> ZeroMemo6 ]

(* New Order Cross Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossMessage ==
    { ZeroNewOrderCrossMessage }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader6 }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.offset18Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossid = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.executingTraderOptional = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossedIndicator = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossPrioritization = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.maxSweepQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossSidesGroups = one] : one \in CheckedCrossSidesGroups }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.deskId = one] : one \in CheckedDeskId4 }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.memo = one] : one \in CheckedMemo6 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader ==
    { ZeroOutboundBusinessHeader }
        \cup { [ZeroOutboundBusinessHeader EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId5 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId5(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId5(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId5 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId5 ==
    { ZeroInvestorId5 }
        \cup { [ZeroInvestorId5 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId5 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId5 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId5 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId5(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId5(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId5 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId5 ==
    { ZeroDeskId5 }
        \cup { [ZeroDeskId5 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo7 ==
    [ memoData : SampleBytes ]

EncodeMemo7(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo7(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo7 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo7 ==
    { ZeroMemo7 }
        \cup { [ZeroMemo7 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Execution Report New Message                                            *)
(***************************************************************************)

ExecutionReportNewMessage ==
    [ outboundBusinessHeader    : OutboundBusinessHeader,
      side                      : Sample(1),
      ordStatus                 : Sample(1),
      clordid                   : Sample(8),
      secondaryOrderId          : Sample(8),
      securityId                : Sample(8),
      orderId                   : Sample(8),
      account                   : Sample(4),
      execId                    : Sample(8),
      transactTime              : Sample(8),
      marketSegmentReceivedTime : Sample(8),
      protectionPrice           : Sample(8),
      tradeDate                 : Sample(2),
      workingIndicator          : Sample(1),
      multiLegReportingType     : Sample(1),
      ordtype                   : Sample(1),
      timeInForce               : Sample(1),
      expireDate                : Sample(2),
      orderQty                  : Sample(8),
      priceOptional             : Sample(8),
      stopPx                    : Sample(8),
      minQty                    : Sample(8),
      maxFloor                  : Sample(8),
      crossidOptional           : Sample(8),
      receivedTime              : Sample(8),
      offset152Padding3         : Sample(3),
      ordtagid                  : Sample(1),
      investorId                : InvestorId5,
      crossType                 : Sample(1),
      crossPrioritization       : Sample(1),
      mmProtectionResetOptional : Sample(1),
      offset167Padding1         : Sample(1),
      strategyId                : Sample(4),
      deskId                    : DeskId5,
      memo                      : Memo7 ]

EncodeExecutionReportNewMessage(message) ==
    EncodeOutboundBusinessHeader(message.outboundBusinessHeader)
        \o message.side
        \o message.ordStatus
        \o message.clordid
        \o message.secondaryOrderId
        \o message.securityId
        \o message.orderId
        \o message.account
        \o message.execId
        \o message.transactTime
        \o message.marketSegmentReceivedTime
        \o message.protectionPrice
        \o message.tradeDate
        \o message.workingIndicator
        \o message.multiLegReportingType
        \o message.ordtype
        \o message.timeInForce
        \o message.expireDate
        \o message.orderQty
        \o message.priceOptional
        \o message.stopPx
        \o message.minQty
        \o message.maxFloor
        \o message.crossidOptional
        \o message.receivedTime
        \o message.offset152Padding3
        \o message.ordtagid
        \o EncodeInvestorId5(message.investorId)
        \o message.crossType
        \o message.crossPrioritization
        \o message.mmProtectionResetOptional
        \o message.offset167Padding1
        \o message.strategyId
        \o EncodeDeskId5(message.deskId)
        \o EncodeMemo7(message.memo)

DecodeExecutionReportNewMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET side == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET clordid == ReadBytes(ordStatus.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(clordid.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(secondaryOrderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET account == ReadBytes(orderId.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET execId == ReadBytes(account.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketSegmentReceivedTime == ReadBytes(transactTime.rest, 8) IN IF ~marketSegmentReceivedTime.ok THEN Fail ELSE
    LET protectionPrice == ReadBytes(marketSegmentReceivedTime.rest, 8) IN IF ~protectionPrice.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(protectionPrice.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET workingIndicator == ReadBytes(tradeDate.rest, 1) IN IF ~workingIndicator.ok THEN Fail ELSE
    LET multiLegReportingType == ReadBytes(workingIndicator.rest, 1) IN IF ~multiLegReportingType.ok THEN Fail ELSE
    LET ordtype == ReadBytes(multiLegReportingType.rest, 1) IN IF ~ordtype.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordtype.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET expireDate == ReadBytes(timeInForce.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET orderQty == ReadBytes(expireDate.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 8) IN IF ~maxFloor.ok THEN Fail ELSE
    LET crossidOptional == ReadBytes(maxFloor.rest, 8) IN IF ~crossidOptional.ok THEN Fail ELSE
    LET receivedTime == ReadBytes(crossidOptional.rest, 8) IN IF ~receivedTime.ok THEN Fail ELSE
    LET offset152Padding3 == ReadBytes(receivedTime.rest, 3) IN IF ~offset152Padding3.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(offset152Padding3.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId5(ordtagid.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET crossType == ReadBytes(investorId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossPrioritization == ReadBytes(crossType.rest, 1) IN IF ~crossPrioritization.ok THEN Fail ELSE
    LET mmProtectionResetOptional == ReadBytes(crossPrioritization.rest, 1) IN IF ~mmProtectionResetOptional.ok THEN Fail ELSE
    LET offset167Padding1 == ReadBytes(mmProtectionResetOptional.rest, 1) IN IF ~offset167Padding1.ok THEN Fail ELSE
    LET strategyId == ReadBytes(offset167Padding1.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId5(strategyId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo7(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader    |-> outboundBusinessHeader.value,
         side                      |-> side.value,
         ordStatus                 |-> ordStatus.value,
         clordid                   |-> clordid.value,
         secondaryOrderId          |-> secondaryOrderId.value,
         securityId                |-> securityId.value,
         orderId                   |-> orderId.value,
         account                   |-> account.value,
         execId                    |-> execId.value,
         transactTime              |-> transactTime.value,
         marketSegmentReceivedTime |-> marketSegmentReceivedTime.value,
         protectionPrice           |-> protectionPrice.value,
         tradeDate                 |-> tradeDate.value,
         workingIndicator          |-> workingIndicator.value,
         multiLegReportingType     |-> multiLegReportingType.value,
         ordtype                   |-> ordtype.value,
         timeInForce               |-> timeInForce.value,
         expireDate                |-> expireDate.value,
         orderQty                  |-> orderQty.value,
         priceOptional             |-> priceOptional.value,
         stopPx                    |-> stopPx.value,
         minQty                    |-> minQty.value,
         maxFloor                  |-> maxFloor.value,
         crossidOptional           |-> crossidOptional.value,
         receivedTime              |-> receivedTime.value,
         offset152Padding3         |-> offset152Padding3.value,
         ordtagid                  |-> ordtagid.value,
         investorId                |-> investorId.value,
         crossType                 |-> crossType.value,
         crossPrioritization       |-> crossPrioritization.value,
         mmProtectionResetOptional |-> mmProtectionResetOptional.value,
         offset167Padding1         |-> offset167Padding1.value,
         strategyId                |-> strategyId.value,
         deskId                    |-> deskId.value,
         memo                      |-> memo.value ], memo.rest)

ZeroExecutionReportNewMessage ==
    [ outboundBusinessHeader    |-> ZeroOutboundBusinessHeader,
      side                      |-> [i \in 1 .. 1 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      clordid                   |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId          |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      account                   |-> [i \in 1 .. 4 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      marketSegmentReceivedTime |-> [i \in 1 .. 8 |-> 0],
      protectionPrice           |-> [i \in 1 .. 8 |-> 0],
      tradeDate                 |-> [i \in 1 .. 2 |-> 0],
      workingIndicator          |-> [i \in 1 .. 1 |-> 0],
      multiLegReportingType     |-> [i \in 1 .. 1 |-> 0],
      ordtype                   |-> [i \in 1 .. 1 |-> 0],
      timeInForce               |-> [i \in 1 .. 1 |-> 0],
      expireDate                |-> [i \in 1 .. 2 |-> 0],
      orderQty                  |-> [i \in 1 .. 8 |-> 0],
      priceOptional             |-> [i \in 1 .. 8 |-> 0],
      stopPx                    |-> [i \in 1 .. 8 |-> 0],
      minQty                    |-> [i \in 1 .. 8 |-> 0],
      maxFloor                  |-> [i \in 1 .. 8 |-> 0],
      crossidOptional           |-> [i \in 1 .. 8 |-> 0],
      receivedTime              |-> [i \in 1 .. 8 |-> 0],
      offset152Padding3         |-> [i \in 1 .. 3 |-> 0],
      ordtagid                  |-> [i \in 1 .. 1 |-> 0],
      investorId                |-> ZeroInvestorId5,
      crossType                 |-> [i \in 1 .. 1 |-> 0],
      crossPrioritization       |-> [i \in 1 .. 1 |-> 0],
      mmProtectionResetOptional |-> [i \in 1 .. 1 |-> 0],
      offset167Padding1         |-> [i \in 1 .. 1 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      deskId                    |-> ZeroDeskId5,
      memo                      |-> ZeroMemo7 ]

(* Execution Report New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportNewMessage ==
    { ZeroExecutionReportNewMessage }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.marketSegmentReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.protectionPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.workingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.multiLegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordtype = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.maxFloor = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.crossidOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.receivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.offset152Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId5 }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.crossPrioritization = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.mmProtectionResetOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.offset167Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.deskId = one] : one \in CheckedDeskId5 }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.memo = one] : one \in CheckedMemo7 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader2 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader2(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader2(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader2 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader2 ==
    { ZeroOutboundBusinessHeader2 }
        \cup { [ZeroOutboundBusinessHeader2 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader2 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader2 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId6 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId6(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId6(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId6 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId6 ==
    { ZeroInvestorId6 }
        \cup { [ZeroInvestorId6 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId6 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId6 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId6 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId6(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId6(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId6 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId6 ==
    { ZeroDeskId6 }
        \cup { [ZeroDeskId6 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo8 ==
    [ memoData : SampleBytes ]

EncodeMemo8(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo8(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo8 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo8 ==
    { ZeroMemo8 }
        \cup { [ZeroMemo8 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Execution Report Modify Message                                         *)
(***************************************************************************)

ExecutionReportModifyMessage ==
    [ outboundBusinessHeader    : OutboundBusinessHeader2,
      side                      : Sample(1),
      ordStatus                 : Sample(1),
      clordid                   : Sample(8),
      secondaryOrderId          : Sample(8),
      securityId                : Sample(8),
      leavesQty                 : Sample(8),
      account                   : Sample(4),
      execId                    : Sample(8),
      transactTime              : Sample(8),
      cumQty                    : Sample(8),
      marketSegmentReceivedTime : Sample(8),
      orderId                   : Sample(8),
      origclordid               : Sample(8),
      protectionPrice           : Sample(8),
      tradeDate                 : Sample(2),
      workingIndicator          : Sample(1),
      multiLegReportingType     : Sample(1),
      ordtype                   : Sample(1),
      timeInForce               : Sample(1),
      expireDate                : Sample(2),
      orderQty                  : Sample(8),
      priceOptional             : Sample(8),
      stopPx                    : Sample(8),
      minQty                    : Sample(8),
      maxFloor                  : Sample(8),
      receivedTime              : Sample(8),
      offset168Padding3         : Sample(3),
      ordtagid                  : Sample(1),
      investorId                : InvestorId6,
      mmProtectionResetOptional : Sample(1),
      offset181Padding1         : Sample(1),
      strategyId                : Sample(4),
      deskId                    : DeskId6,
      memo                      : Memo8 ]

EncodeExecutionReportModifyMessage(message) ==
    EncodeOutboundBusinessHeader2(message.outboundBusinessHeader)
        \o message.side
        \o message.ordStatus
        \o message.clordid
        \o message.secondaryOrderId
        \o message.securityId
        \o message.leavesQty
        \o message.account
        \o message.execId
        \o message.transactTime
        \o message.cumQty
        \o message.marketSegmentReceivedTime
        \o message.orderId
        \o message.origclordid
        \o message.protectionPrice
        \o message.tradeDate
        \o message.workingIndicator
        \o message.multiLegReportingType
        \o message.ordtype
        \o message.timeInForce
        \o message.expireDate
        \o message.orderQty
        \o message.priceOptional
        \o message.stopPx
        \o message.minQty
        \o message.maxFloor
        \o message.receivedTime
        \o message.offset168Padding3
        \o message.ordtagid
        \o EncodeInvestorId6(message.investorId)
        \o message.mmProtectionResetOptional
        \o message.offset181Padding1
        \o message.strategyId
        \o EncodeDeskId6(message.deskId)
        \o EncodeMemo8(message.memo)

DecodeExecutionReportModifyMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader2(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET side == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET clordid == ReadBytes(ordStatus.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(clordid.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(secondaryOrderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(securityId.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET account == ReadBytes(leavesQty.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET execId == ReadBytes(account.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET cumQty == ReadBytes(transactTime.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET marketSegmentReceivedTime == ReadBytes(cumQty.rest, 8) IN IF ~marketSegmentReceivedTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(marketSegmentReceivedTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET origclordid == ReadBytes(orderId.rest, 8) IN IF ~origclordid.ok THEN Fail ELSE
    LET protectionPrice == ReadBytes(origclordid.rest, 8) IN IF ~protectionPrice.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(protectionPrice.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET workingIndicator == ReadBytes(tradeDate.rest, 1) IN IF ~workingIndicator.ok THEN Fail ELSE
    LET multiLegReportingType == ReadBytes(workingIndicator.rest, 1) IN IF ~multiLegReportingType.ok THEN Fail ELSE
    LET ordtype == ReadBytes(multiLegReportingType.rest, 1) IN IF ~ordtype.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordtype.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET expireDate == ReadBytes(timeInForce.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET orderQty == ReadBytes(expireDate.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 8) IN IF ~maxFloor.ok THEN Fail ELSE
    LET receivedTime == ReadBytes(maxFloor.rest, 8) IN IF ~receivedTime.ok THEN Fail ELSE
    LET offset168Padding3 == ReadBytes(receivedTime.rest, 3) IN IF ~offset168Padding3.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(offset168Padding3.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId6(ordtagid.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET mmProtectionResetOptional == ReadBytes(investorId.rest, 1) IN IF ~mmProtectionResetOptional.ok THEN Fail ELSE
    LET offset181Padding1 == ReadBytes(mmProtectionResetOptional.rest, 1) IN IF ~offset181Padding1.ok THEN Fail ELSE
    LET strategyId == ReadBytes(offset181Padding1.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId6(strategyId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo8(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader    |-> outboundBusinessHeader.value,
         side                      |-> side.value,
         ordStatus                 |-> ordStatus.value,
         clordid                   |-> clordid.value,
         secondaryOrderId          |-> secondaryOrderId.value,
         securityId                |-> securityId.value,
         leavesQty                 |-> leavesQty.value,
         account                   |-> account.value,
         execId                    |-> execId.value,
         transactTime              |-> transactTime.value,
         cumQty                    |-> cumQty.value,
         marketSegmentReceivedTime |-> marketSegmentReceivedTime.value,
         orderId                   |-> orderId.value,
         origclordid               |-> origclordid.value,
         protectionPrice           |-> protectionPrice.value,
         tradeDate                 |-> tradeDate.value,
         workingIndicator          |-> workingIndicator.value,
         multiLegReportingType     |-> multiLegReportingType.value,
         ordtype                   |-> ordtype.value,
         timeInForce               |-> timeInForce.value,
         expireDate                |-> expireDate.value,
         orderQty                  |-> orderQty.value,
         priceOptional             |-> priceOptional.value,
         stopPx                    |-> stopPx.value,
         minQty                    |-> minQty.value,
         maxFloor                  |-> maxFloor.value,
         receivedTime              |-> receivedTime.value,
         offset168Padding3         |-> offset168Padding3.value,
         ordtagid                  |-> ordtagid.value,
         investorId                |-> investorId.value,
         mmProtectionResetOptional |-> mmProtectionResetOptional.value,
         offset181Padding1         |-> offset181Padding1.value,
         strategyId                |-> strategyId.value,
         deskId                    |-> deskId.value,
         memo                      |-> memo.value ], memo.rest)

ZeroExecutionReportModifyMessage ==
    [ outboundBusinessHeader    |-> ZeroOutboundBusinessHeader2,
      side                      |-> [i \in 1 .. 1 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      clordid                   |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId          |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 8 |-> 0],
      account                   |-> [i \in 1 .. 4 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      cumQty                    |-> [i \in 1 .. 8 |-> 0],
      marketSegmentReceivedTime |-> [i \in 1 .. 8 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      origclordid               |-> [i \in 1 .. 8 |-> 0],
      protectionPrice           |-> [i \in 1 .. 8 |-> 0],
      tradeDate                 |-> [i \in 1 .. 2 |-> 0],
      workingIndicator          |-> [i \in 1 .. 1 |-> 0],
      multiLegReportingType     |-> [i \in 1 .. 1 |-> 0],
      ordtype                   |-> [i \in 1 .. 1 |-> 0],
      timeInForce               |-> [i \in 1 .. 1 |-> 0],
      expireDate                |-> [i \in 1 .. 2 |-> 0],
      orderQty                  |-> [i \in 1 .. 8 |-> 0],
      priceOptional             |-> [i \in 1 .. 8 |-> 0],
      stopPx                    |-> [i \in 1 .. 8 |-> 0],
      minQty                    |-> [i \in 1 .. 8 |-> 0],
      maxFloor                  |-> [i \in 1 .. 8 |-> 0],
      receivedTime              |-> [i \in 1 .. 8 |-> 0],
      offset168Padding3         |-> [i \in 1 .. 3 |-> 0],
      ordtagid                  |-> [i \in 1 .. 1 |-> 0],
      investorId                |-> ZeroInvestorId6,
      mmProtectionResetOptional |-> [i \in 1 .. 1 |-> 0],
      offset181Padding1         |-> [i \in 1 .. 1 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      deskId                    |-> ZeroDeskId6,
      memo                      |-> ZeroMemo8 ]

(* Execution Report Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportModifyMessage ==
    { ZeroExecutionReportModifyMessage }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader2 }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.marketSegmentReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.origclordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.protectionPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.workingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.multiLegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.ordtype = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.maxFloor = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.receivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.offset168Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId6 }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.mmProtectionResetOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.offset181Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.deskId = one] : one \in CheckedDeskId6 }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.memo = one] : one \in CheckedMemo8 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader3 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader3(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader3(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader3 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader3 ==
    { ZeroOutboundBusinessHeader3 }
        \cup { [ZeroOutboundBusinessHeader3 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader3 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader3 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId7 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId7(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId7(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId7 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId7 ==
    { ZeroInvestorId7 }
        \cup { [ZeroInvestorId7 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId7 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId7 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId7 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId7(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId7(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId7 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId7 ==
    { ZeroDeskId7 }
        \cup { [ZeroDeskId7 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo9 ==
    [ memoData : SampleBytes ]

EncodeMemo9(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo9(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo9 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo9 ==
    { ZeroMemo9 }
        \cup { [ZeroMemo9 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Execution Report Cancel Message                                         *)
(***************************************************************************)

ExecutionReportCancelMessage ==
    [ outboundBusinessHeader       : OutboundBusinessHeader3,
      side                         : Sample(1),
      ordStatus                    : Sample(1),
      clordid                      : Sample(8),
      secondaryOrderId             : Sample(8),
      securityId                   : Sample(8),
      cumQty                       : Sample(8),
      account                      : Sample(4),
      execId                       : Sample(8),
      transactTime                 : Sample(8),
      marketSegmentReceivedTime    : Sample(8),
      orderId                      : Sample(8),
      origclordid                  : Sample(8),
      tradeDate                    : Sample(2),
      workingIndicator             : Sample(1),
      execRestatementReason        : Sample(1),
      offset100Padding4            : Sample(4),
      massActionReportIdOptional   : Sample(8),
      ordtype                      : Sample(1),
      timeInForce                  : Sample(1),
      expireDate                   : Sample(2),
      orderQty                     : Sample(8),
      priceOptional                : Sample(8),
      stopPx                       : Sample(8),
      minQty                       : Sample(8),
      maxFloor                     : Sample(8),
      receivedTime                 : Sample(8),
      offset164Padding3            : Sample(3),
      ordtagid                     : Sample(1),
      investorId                   : InvestorId7,
      strategyId                   : Sample(4),
      actionRequestedFromSessionId : Sample(4),
      deskId                       : DeskId7,
      memo                         : Memo9 ]

EncodeExecutionReportCancelMessage(message) ==
    EncodeOutboundBusinessHeader3(message.outboundBusinessHeader)
        \o message.side
        \o message.ordStatus
        \o message.clordid
        \o message.secondaryOrderId
        \o message.securityId
        \o message.cumQty
        \o message.account
        \o message.execId
        \o message.transactTime
        \o message.marketSegmentReceivedTime
        \o message.orderId
        \o message.origclordid
        \o message.tradeDate
        \o message.workingIndicator
        \o message.execRestatementReason
        \o message.offset100Padding4
        \o message.massActionReportIdOptional
        \o message.ordtype
        \o message.timeInForce
        \o message.expireDate
        \o message.orderQty
        \o message.priceOptional
        \o message.stopPx
        \o message.minQty
        \o message.maxFloor
        \o message.receivedTime
        \o message.offset164Padding3
        \o message.ordtagid
        \o EncodeInvestorId7(message.investorId)
        \o message.strategyId
        \o message.actionRequestedFromSessionId
        \o EncodeDeskId7(message.deskId)
        \o EncodeMemo9(message.memo)

DecodeExecutionReportCancelMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader3(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET side == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET clordid == ReadBytes(ordStatus.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(clordid.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(secondaryOrderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(securityId.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET account == ReadBytes(cumQty.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET execId == ReadBytes(account.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketSegmentReceivedTime == ReadBytes(transactTime.rest, 8) IN IF ~marketSegmentReceivedTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(marketSegmentReceivedTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET origclordid == ReadBytes(orderId.rest, 8) IN IF ~origclordid.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(origclordid.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET workingIndicator == ReadBytes(tradeDate.rest, 1) IN IF ~workingIndicator.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(workingIndicator.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET offset100Padding4 == ReadBytes(execRestatementReason.rest, 4) IN IF ~offset100Padding4.ok THEN Fail ELSE
    LET massActionReportIdOptional == ReadBytes(offset100Padding4.rest, 8) IN IF ~massActionReportIdOptional.ok THEN Fail ELSE
    LET ordtype == ReadBytes(massActionReportIdOptional.rest, 1) IN IF ~ordtype.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordtype.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET expireDate == ReadBytes(timeInForce.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET orderQty == ReadBytes(expireDate.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 8) IN IF ~maxFloor.ok THEN Fail ELSE
    LET receivedTime == ReadBytes(maxFloor.rest, 8) IN IF ~receivedTime.ok THEN Fail ELSE
    LET offset164Padding3 == ReadBytes(receivedTime.rest, 3) IN IF ~offset164Padding3.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(offset164Padding3.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId7(ordtagid.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(investorId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET actionRequestedFromSessionId == ReadBytes(strategyId.rest, 4) IN IF ~actionRequestedFromSessionId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId7(actionRequestedFromSessionId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo9(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader       |-> outboundBusinessHeader.value,
         side                         |-> side.value,
         ordStatus                    |-> ordStatus.value,
         clordid                      |-> clordid.value,
         secondaryOrderId             |-> secondaryOrderId.value,
         securityId                   |-> securityId.value,
         cumQty                       |-> cumQty.value,
         account                      |-> account.value,
         execId                       |-> execId.value,
         transactTime                 |-> transactTime.value,
         marketSegmentReceivedTime    |-> marketSegmentReceivedTime.value,
         orderId                      |-> orderId.value,
         origclordid                  |-> origclordid.value,
         tradeDate                    |-> tradeDate.value,
         workingIndicator             |-> workingIndicator.value,
         execRestatementReason        |-> execRestatementReason.value,
         offset100Padding4            |-> offset100Padding4.value,
         massActionReportIdOptional   |-> massActionReportIdOptional.value,
         ordtype                      |-> ordtype.value,
         timeInForce                  |-> timeInForce.value,
         expireDate                   |-> expireDate.value,
         orderQty                     |-> orderQty.value,
         priceOptional                |-> priceOptional.value,
         stopPx                       |-> stopPx.value,
         minQty                       |-> minQty.value,
         maxFloor                     |-> maxFloor.value,
         receivedTime                 |-> receivedTime.value,
         offset164Padding3            |-> offset164Padding3.value,
         ordtagid                     |-> ordtagid.value,
         investorId                   |-> investorId.value,
         strategyId                   |-> strategyId.value,
         actionRequestedFromSessionId |-> actionRequestedFromSessionId.value,
         deskId                       |-> deskId.value,
         memo                         |-> memo.value ], memo.rest)

ZeroExecutionReportCancelMessage ==
    [ outboundBusinessHeader       |-> ZeroOutboundBusinessHeader3,
      side                         |-> [i \in 1 .. 1 |-> 0],
      ordStatus                    |-> [i \in 1 .. 1 |-> 0],
      clordid                      |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId             |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      cumQty                       |-> [i \in 1 .. 8 |-> 0],
      account                      |-> [i \in 1 .. 4 |-> 0],
      execId                       |-> [i \in 1 .. 8 |-> 0],
      transactTime                 |-> [i \in 1 .. 8 |-> 0],
      marketSegmentReceivedTime    |-> [i \in 1 .. 8 |-> 0],
      orderId                      |-> [i \in 1 .. 8 |-> 0],
      origclordid                  |-> [i \in 1 .. 8 |-> 0],
      tradeDate                    |-> [i \in 1 .. 2 |-> 0],
      workingIndicator             |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason        |-> [i \in 1 .. 1 |-> 0],
      offset100Padding4            |-> [i \in 1 .. 4 |-> 0],
      massActionReportIdOptional   |-> [i \in 1 .. 8 |-> 0],
      ordtype                      |-> [i \in 1 .. 1 |-> 0],
      timeInForce                  |-> [i \in 1 .. 1 |-> 0],
      expireDate                   |-> [i \in 1 .. 2 |-> 0],
      orderQty                     |-> [i \in 1 .. 8 |-> 0],
      priceOptional                |-> [i \in 1 .. 8 |-> 0],
      stopPx                       |-> [i \in 1 .. 8 |-> 0],
      minQty                       |-> [i \in 1 .. 8 |-> 0],
      maxFloor                     |-> [i \in 1 .. 8 |-> 0],
      receivedTime                 |-> [i \in 1 .. 8 |-> 0],
      offset164Padding3            |-> [i \in 1 .. 3 |-> 0],
      ordtagid                     |-> [i \in 1 .. 1 |-> 0],
      investorId                   |-> ZeroInvestorId7,
      strategyId                   |-> [i \in 1 .. 4 |-> 0],
      actionRequestedFromSessionId |-> [i \in 1 .. 4 |-> 0],
      deskId                       |-> ZeroDeskId7,
      memo                         |-> ZeroMemo9 ]

(* Execution Report Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportCancelMessage ==
    { ZeroExecutionReportCancelMessage }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader3 }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.marketSegmentReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.origclordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.workingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.offset100Padding4 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.massActionReportIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.ordtype = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.maxFloor = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.receivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.offset164Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId7 }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.actionRequestedFromSessionId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.deskId = one] : one \in CheckedDeskId7 }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.memo = one] : one \in CheckedMemo9 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader4 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader4(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader4(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader4 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader4 ==
    { ZeroOutboundBusinessHeader4 }
        \cup { [ZeroOutboundBusinessHeader4 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader4 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader4 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId8 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId8(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId8(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId8 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId8 ==
    { ZeroDeskId8 }
        \cup { [ZeroDeskId8 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo10 ==
    [ memoData : SampleBytes ]

EncodeMemo10(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo10(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo10 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo10 ==
    { ZeroMemo10 }
        \cup { [ZeroMemo10 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Execution Report Trade Message                                          *)
(***************************************************************************)

ExecutionReportTradeMessage ==
    [ outboundBusinessHeader : OutboundBusinessHeader4,
      side                   : Sample(1),
      ordStatus              : Sample(1),
      clordidOptional        : Sample(8),
      secondaryOrderId       : Sample(8),
      securityId             : Sample(8),
      account                : Sample(4),
      lastQty                : Sample(8),
      lastPx                 : Sample(8),
      execId                 : Sample(8),
      transactTime           : Sample(8),
      leavesQty              : Sample(8),
      cumQty                 : Sample(8),
      aggressorIndicator     : Sample(1),
      execType               : Sample(1),
      orderCategory          : Sample(1),
      multiLegReportingType  : Sample(1),
      tradeId                : Sample(4),
      contraBroker           : Sample(4),
      orderId                : Sample(8),
      tradeDate              : Sample(2),
      totNoRelatedSym        : Sample(1),
      offset119Padding1      : Sample(1),
      secondaryExecId        : Sample(8),
      execRefId              : Sample(8),
      crossidOptional        : Sample(8),
      crossedIndicator       : Sample(2),
      orderQty               : Sample(8),
      tradingSessionId       : Sample(1),
      tradingSessionSubId    : Sample(1),
      securityTradingStatus  : Sample(1),
      crossType              : Sample(1),
      crossPrioritization    : Sample(1),
      offset159Padding1      : Sample(1),
      strategyId             : Sample(4),
      deskId                 : DeskId8,
      memo                   : Memo10 ]

EncodeExecutionReportTradeMessage(message) ==
    EncodeOutboundBusinessHeader4(message.outboundBusinessHeader)
        \o message.side
        \o message.ordStatus
        \o message.clordidOptional
        \o message.secondaryOrderId
        \o message.securityId
        \o message.account
        \o message.lastQty
        \o message.lastPx
        \o message.execId
        \o message.transactTime
        \o message.leavesQty
        \o message.cumQty
        \o message.aggressorIndicator
        \o message.execType
        \o message.orderCategory
        \o message.multiLegReportingType
        \o message.tradeId
        \o message.contraBroker
        \o message.orderId
        \o message.tradeDate
        \o message.totNoRelatedSym
        \o message.offset119Padding1
        \o message.secondaryExecId
        \o message.execRefId
        \o message.crossidOptional
        \o message.crossedIndicator
        \o message.orderQty
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.securityTradingStatus
        \o message.crossType
        \o message.crossPrioritization
        \o message.offset159Padding1
        \o message.strategyId
        \o EncodeDeskId8(message.deskId)
        \o EncodeMemo10(message.memo)

DecodeExecutionReportTradeMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader4(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET side == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET clordidOptional == ReadBytes(ordStatus.rest, 8) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(clordidOptional.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(secondaryOrderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET account == ReadBytes(securityId.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET lastQty == ReadBytes(account.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET execId == ReadBytes(lastPx.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(transactTime.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(cumQty.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET execType == ReadBytes(aggressorIndicator.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(execType.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    LET multiLegReportingType == ReadBytes(orderCategory.rest, 1) IN IF ~multiLegReportingType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(multiLegReportingType.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeId.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET orderId == ReadBytes(contraBroker.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(orderId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET totNoRelatedSym == ReadBytes(tradeDate.rest, 1) IN IF ~totNoRelatedSym.ok THEN Fail ELSE
    LET offset119Padding1 == ReadBytes(totNoRelatedSym.rest, 1) IN IF ~offset119Padding1.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(offset119Padding1.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(secondaryExecId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET crossidOptional == ReadBytes(execRefId.rest, 8) IN IF ~crossidOptional.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(crossidOptional.rest, 2) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET orderQty == ReadBytes(crossedIndicator.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET crossType == ReadBytes(securityTradingStatus.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossPrioritization == ReadBytes(crossType.rest, 1) IN IF ~crossPrioritization.ok THEN Fail ELSE
    LET offset159Padding1 == ReadBytes(crossPrioritization.rest, 1) IN IF ~offset159Padding1.ok THEN Fail ELSE
    LET strategyId == ReadBytes(offset159Padding1.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId8(strategyId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo10(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader |-> outboundBusinessHeader.value,
         side                   |-> side.value,
         ordStatus              |-> ordStatus.value,
         clordidOptional        |-> clordidOptional.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         securityId             |-> securityId.value,
         account                |-> account.value,
         lastQty                |-> lastQty.value,
         lastPx                 |-> lastPx.value,
         execId                 |-> execId.value,
         transactTime           |-> transactTime.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         aggressorIndicator     |-> aggressorIndicator.value,
         execType               |-> execType.value,
         orderCategory          |-> orderCategory.value,
         multiLegReportingType  |-> multiLegReportingType.value,
         tradeId                |-> tradeId.value,
         contraBroker           |-> contraBroker.value,
         orderId                |-> orderId.value,
         tradeDate              |-> tradeDate.value,
         totNoRelatedSym        |-> totNoRelatedSym.value,
         offset119Padding1      |-> offset119Padding1.value,
         secondaryExecId        |-> secondaryExecId.value,
         execRefId              |-> execRefId.value,
         crossidOptional        |-> crossidOptional.value,
         crossedIndicator       |-> crossedIndicator.value,
         orderQty               |-> orderQty.value,
         tradingSessionId       |-> tradingSessionId.value,
         tradingSessionSubId    |-> tradingSessionSubId.value,
         securityTradingStatus  |-> securityTradingStatus.value,
         crossType              |-> crossType.value,
         crossPrioritization    |-> crossPrioritization.value,
         offset159Padding1      |-> offset159Padding1.value,
         strategyId             |-> strategyId.value,
         deskId                 |-> deskId.value,
         memo                   |-> memo.value ], memo.rest)

ZeroExecutionReportTradeMessage ==
    [ outboundBusinessHeader |-> ZeroOutboundBusinessHeader4,
      side                   |-> [i \in 1 .. 1 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      clordidOptional        |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      account                |-> [i \in 1 .. 4 |-> 0],
      lastQty                |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 8 |-> 0],
      cumQty                 |-> [i \in 1 .. 8 |-> 0],
      aggressorIndicator     |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      orderCategory          |-> [i \in 1 .. 1 |-> 0],
      multiLegReportingType  |-> [i \in 1 .. 1 |-> 0],
      tradeId                |-> [i \in 1 .. 4 |-> 0],
      contraBroker           |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      tradeDate              |-> [i \in 1 .. 2 |-> 0],
      totNoRelatedSym        |-> [i \in 1 .. 1 |-> 0],
      offset119Padding1      |-> [i \in 1 .. 1 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 8 |-> 0],
      execRefId              |-> [i \in 1 .. 8 |-> 0],
      crossidOptional        |-> [i \in 1 .. 8 |-> 0],
      crossedIndicator       |-> [i \in 1 .. 2 |-> 0],
      orderQty               |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId    |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus  |-> [i \in 1 .. 1 |-> 0],
      crossType              |-> [i \in 1 .. 1 |-> 0],
      crossPrioritization    |-> [i \in 1 .. 1 |-> 0],
      offset159Padding1      |-> [i \in 1 .. 1 |-> 0],
      strategyId             |-> [i \in 1 .. 4 |-> 0],
      deskId                 |-> ZeroDeskId8,
      memo                   |-> ZeroMemo10 ]

(* Execution Report Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeMessage ==
    { ZeroExecutionReportTradeMessage }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader4 }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.clordidOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.multiLegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.totNoRelatedSym = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.offset119Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.crossidOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.crossedIndicator = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.crossPrioritization = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.offset159Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.deskId = one] : one \in CheckedDeskId8 }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.memo = one] : one \in CheckedMemo10 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader5 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader5(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader5(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader5 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader5 ==
    { ZeroOutboundBusinessHeader5 }
        \cup { [ZeroOutboundBusinessHeader5 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader5 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader5 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId8 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId8(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId8(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId8 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId8 ==
    { ZeroInvestorId8 }
        \cup { [ZeroInvestorId8 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId8 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId8 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId9 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId9(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId9(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId9 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId9 ==
    { ZeroDeskId9 }
        \cup { [ZeroDeskId9 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo11 ==
    [ memoData : SampleBytes ]

EncodeMemo11(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo11(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo11 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo11 ==
    { ZeroMemo11 }
        \cup { [ZeroMemo11 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text ==
    [ textData : SampleBytes ]

EncodeText(message) ==
    EncodeUIntBE(Len(message.textData), 1)
        \o message.textData

DecodeText(bytes) ==
    LET textLength == ReadUIntBE(bytes, 1) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText ==
    { ZeroText }
        \cup { [ZeroText EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Execution Report Reject Message                                         *)
(***************************************************************************)

ExecutionReportRejectMessage ==
    [ outboundBusinessHeader   : OutboundBusinessHeader5,
      side                     : Sample(1),
      cxlRejResponseTo         : Sample(1),
      clordid                  : Sample(8),
      secondaryOrderIdOptional : Sample(8),
      securityId               : Sample(8),
      ordRejReason             : Sample(4),
      transactTime             : Sample(8),
      execId                   : Sample(8),
      orderIdOptional          : Sample(8),
      origclordid              : Sample(8),
      account                  : Sample(4),
      ordtype                  : Sample(1),
      timeInForce              : Sample(1),
      expireDate               : Sample(2),
      orderQty                 : Sample(8),
      priceOptional            : Sample(8),
      stopPx                   : Sample(8),
      minQty                   : Sample(8),
      maxFloor                 : Sample(8),
      crossidOptional          : Sample(8),
      crossedIndicator         : Sample(2),
      receivedTime             : Sample(8),
      offset146Padding3        : Sample(3),
      ordtagid                 : Sample(1),
      investorId               : InvestorId8,
      strategyId               : Sample(4),
      deskId                   : DeskId9,
      memo                     : Memo11,
      text                     : Text ]

EncodeExecutionReportRejectMessage(message) ==
    EncodeOutboundBusinessHeader5(message.outboundBusinessHeader)
        \o message.side
        \o message.cxlRejResponseTo
        \o message.clordid
        \o message.secondaryOrderIdOptional
        \o message.securityId
        \o message.ordRejReason
        \o message.transactTime
        \o message.execId
        \o message.orderIdOptional
        \o message.origclordid
        \o message.account
        \o message.ordtype
        \o message.timeInForce
        \o message.expireDate
        \o message.orderQty
        \o message.priceOptional
        \o message.stopPx
        \o message.minQty
        \o message.maxFloor
        \o message.crossidOptional
        \o message.crossedIndicator
        \o message.receivedTime
        \o message.offset146Padding3
        \o message.ordtagid
        \o EncodeInvestorId8(message.investorId)
        \o message.strategyId
        \o EncodeDeskId9(message.deskId)
        \o EncodeMemo11(message.memo)
        \o EncodeText(message.text)

DecodeExecutionReportRejectMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader5(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET side == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET cxlRejResponseTo == ReadBytes(side.rest, 1) IN IF ~cxlRejResponseTo.ok THEN Fail ELSE
    LET clordid == ReadBytes(cxlRejResponseTo.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET secondaryOrderIdOptional == ReadBytes(clordid.rest, 8) IN IF ~secondaryOrderIdOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(secondaryOrderIdOptional.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(securityId.rest, 4) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET transactTime == ReadBytes(ordRejReason.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET execId == ReadBytes(transactTime.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(execId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origclordid == ReadBytes(orderIdOptional.rest, 8) IN IF ~origclordid.ok THEN Fail ELSE
    LET account == ReadBytes(origclordid.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET ordtype == ReadBytes(account.rest, 1) IN IF ~ordtype.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordtype.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET expireDate == ReadBytes(timeInForce.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET orderQty == ReadBytes(expireDate.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(orderQty.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 8) IN IF ~maxFloor.ok THEN Fail ELSE
    LET crossidOptional == ReadBytes(maxFloor.rest, 8) IN IF ~crossidOptional.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(crossidOptional.rest, 2) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET receivedTime == ReadBytes(crossedIndicator.rest, 8) IN IF ~receivedTime.ok THEN Fail ELSE
    LET offset146Padding3 == ReadBytes(receivedTime.rest, 3) IN IF ~offset146Padding3.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(offset146Padding3.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId8(ordtagid.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(investorId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET deskId == DecodeDeskId9(strategyId.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo11(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    LET text == DecodeText(memo.rest) IN IF ~text.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader   |-> outboundBusinessHeader.value,
         side                     |-> side.value,
         cxlRejResponseTo         |-> cxlRejResponseTo.value,
         clordid                  |-> clordid.value,
         secondaryOrderIdOptional |-> secondaryOrderIdOptional.value,
         securityId               |-> securityId.value,
         ordRejReason             |-> ordRejReason.value,
         transactTime             |-> transactTime.value,
         execId                   |-> execId.value,
         orderIdOptional          |-> orderIdOptional.value,
         origclordid              |-> origclordid.value,
         account                  |-> account.value,
         ordtype                  |-> ordtype.value,
         timeInForce              |-> timeInForce.value,
         expireDate               |-> expireDate.value,
         orderQty                 |-> orderQty.value,
         priceOptional            |-> priceOptional.value,
         stopPx                   |-> stopPx.value,
         minQty                   |-> minQty.value,
         maxFloor                 |-> maxFloor.value,
         crossidOptional          |-> crossidOptional.value,
         crossedIndicator         |-> crossedIndicator.value,
         receivedTime             |-> receivedTime.value,
         offset146Padding3        |-> offset146Padding3.value,
         ordtagid                 |-> ordtagid.value,
         investorId               |-> investorId.value,
         strategyId               |-> strategyId.value,
         deskId                   |-> deskId.value,
         memo                     |-> memo.value,
         text                     |-> text.value ], text.rest)

ZeroExecutionReportRejectMessage ==
    [ outboundBusinessHeader   |-> ZeroOutboundBusinessHeader5,
      side                     |-> [i \in 1 .. 1 |-> 0],
      cxlRejResponseTo         |-> [i \in 1 .. 1 |-> 0],
      clordid                  |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderIdOptional |-> [i \in 1 .. 8 |-> 0],
      securityId               |-> [i \in 1 .. 8 |-> 0],
      ordRejReason             |-> [i \in 1 .. 4 |-> 0],
      transactTime             |-> [i \in 1 .. 8 |-> 0],
      execId                   |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional          |-> [i \in 1 .. 8 |-> 0],
      origclordid              |-> [i \in 1 .. 8 |-> 0],
      account                  |-> [i \in 1 .. 4 |-> 0],
      ordtype                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce              |-> [i \in 1 .. 1 |-> 0],
      expireDate               |-> [i \in 1 .. 2 |-> 0],
      orderQty                 |-> [i \in 1 .. 8 |-> 0],
      priceOptional            |-> [i \in 1 .. 8 |-> 0],
      stopPx                   |-> [i \in 1 .. 8 |-> 0],
      minQty                   |-> [i \in 1 .. 8 |-> 0],
      maxFloor                 |-> [i \in 1 .. 8 |-> 0],
      crossidOptional          |-> [i \in 1 .. 8 |-> 0],
      crossedIndicator         |-> [i \in 1 .. 2 |-> 0],
      receivedTime             |-> [i \in 1 .. 8 |-> 0],
      offset146Padding3        |-> [i \in 1 .. 3 |-> 0],
      ordtagid                 |-> [i \in 1 .. 1 |-> 0],
      investorId               |-> ZeroInvestorId8,
      strategyId               |-> [i \in 1 .. 4 |-> 0],
      deskId                   |-> ZeroDeskId9,
      memo                     |-> ZeroMemo11,
      text                     |-> ZeroText ]

(* Execution Report Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportRejectMessage ==
    { ZeroExecutionReportRejectMessage }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader5 }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.cxlRejResponseTo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.secondaryOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.ordRejReason = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.origclordid = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.ordtype = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.maxFloor = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.crossidOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.crossedIndicator = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.receivedTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.offset146Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId8 }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.deskId = one] : one \in CheckedDeskId9 }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.memo = one] : one \in CheckedMemo11 }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.text = one] : one \in CheckedText }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader6 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader6(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader6(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader6 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader6 ==
    { ZeroOutboundBusinessHeader6 }
        \cup { [ZeroOutboundBusinessHeader6 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader6 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader6 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId10 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId10(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId10(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId10 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId10 ==
    { ZeroDeskId10 }
        \cup { [ZeroDeskId10 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo12 ==
    [ memoData : SampleBytes ]

EncodeMemo12(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo12(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo12 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo12 ==
    { ZeroMemo12 }
        \cup { [ZeroMemo12 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Execution Report Forward Message                                        *)
(***************************************************************************)

ExecutionReportForwardMessage ==
    [ outboundBusinessHeader       : OutboundBusinessHeader6,
      side                         : Sample(1),
      ordStatus                    : Sample(1),
      clordidOptional              : Sample(8),
      secondaryOrderId             : Sample(8),
      securityId                   : Sample(8),
      account                      : Sample(4),
      lastQty                      : Sample(8),
      lastPx                       : Sample(8),
      execId                       : Sample(8),
      transactTime                 : Sample(8),
      leavesQty                    : Sample(8),
      cumQty                       : Sample(8),
      tradeId                      : Sample(4),
      contraBroker                 : Sample(4),
      orderId                      : Sample(8),
      aggressorIndicator           : Sample(1),
      settlTypeOptional            : Sample(1),
      tradeDate                    : Sample(2),
      daysToSettlementOptional     : Sample(2),
      offset118Padding2            : Sample(2),
      secondaryExecId              : Sample(8),
      execRefId                    : Sample(8),
      fixedRatePercentage8Optional : Sample(8),
      orderQty                     : Sample(8),
      tradingSessionId             : Sample(1),
      tradingSessionSubId          : Sample(1),
      securityTradingStatus        : Sample(1),
      deskId                       : DeskId10,
      memo                         : Memo12 ]

EncodeExecutionReportForwardMessage(message) ==
    EncodeOutboundBusinessHeader6(message.outboundBusinessHeader)
        \o message.side
        \o message.ordStatus
        \o message.clordidOptional
        \o message.secondaryOrderId
        \o message.securityId
        \o message.account
        \o message.lastQty
        \o message.lastPx
        \o message.execId
        \o message.transactTime
        \o message.leavesQty
        \o message.cumQty
        \o message.tradeId
        \o message.contraBroker
        \o message.orderId
        \o message.aggressorIndicator
        \o message.settlTypeOptional
        \o message.tradeDate
        \o message.daysToSettlementOptional
        \o message.offset118Padding2
        \o message.secondaryExecId
        \o message.execRefId
        \o message.fixedRatePercentage8Optional
        \o message.orderQty
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.securityTradingStatus
        \o EncodeDeskId10(message.deskId)
        \o EncodeMemo12(message.memo)

DecodeExecutionReportForwardMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader6(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET side == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET clordidOptional == ReadBytes(ordStatus.rest, 8) IN IF ~clordidOptional.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(clordidOptional.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(secondaryOrderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET account == ReadBytes(securityId.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET lastQty == ReadBytes(account.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET execId == ReadBytes(lastPx.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(transactTime.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET tradeId == ReadBytes(cumQty.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeId.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET orderId == ReadBytes(contraBroker.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(orderId.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET settlTypeOptional == ReadBytes(aggressorIndicator.rest, 1) IN IF ~settlTypeOptional.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(settlTypeOptional.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET daysToSettlementOptional == ReadBytes(tradeDate.rest, 2) IN IF ~daysToSettlementOptional.ok THEN Fail ELSE
    LET offset118Padding2 == ReadBytes(daysToSettlementOptional.rest, 2) IN IF ~offset118Padding2.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(offset118Padding2.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(secondaryExecId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET fixedRatePercentage8Optional == ReadBytes(execRefId.rest, 8) IN IF ~fixedRatePercentage8Optional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(fixedRatePercentage8Optional.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(orderQty.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET deskId == DecodeDeskId10(securityTradingStatus.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo12(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader       |-> outboundBusinessHeader.value,
         side                         |-> side.value,
         ordStatus                    |-> ordStatus.value,
         clordidOptional              |-> clordidOptional.value,
         secondaryOrderId             |-> secondaryOrderId.value,
         securityId                   |-> securityId.value,
         account                      |-> account.value,
         lastQty                      |-> lastQty.value,
         lastPx                       |-> lastPx.value,
         execId                       |-> execId.value,
         transactTime                 |-> transactTime.value,
         leavesQty                    |-> leavesQty.value,
         cumQty                       |-> cumQty.value,
         tradeId                      |-> tradeId.value,
         contraBroker                 |-> contraBroker.value,
         orderId                      |-> orderId.value,
         aggressorIndicator           |-> aggressorIndicator.value,
         settlTypeOptional            |-> settlTypeOptional.value,
         tradeDate                    |-> tradeDate.value,
         daysToSettlementOptional     |-> daysToSettlementOptional.value,
         offset118Padding2            |-> offset118Padding2.value,
         secondaryExecId              |-> secondaryExecId.value,
         execRefId                    |-> execRefId.value,
         fixedRatePercentage8Optional |-> fixedRatePercentage8Optional.value,
         orderQty                     |-> orderQty.value,
         tradingSessionId             |-> tradingSessionId.value,
         tradingSessionSubId          |-> tradingSessionSubId.value,
         securityTradingStatus        |-> securityTradingStatus.value,
         deskId                       |-> deskId.value,
         memo                         |-> memo.value ], memo.rest)

ZeroExecutionReportForwardMessage ==
    [ outboundBusinessHeader       |-> ZeroOutboundBusinessHeader6,
      side                         |-> [i \in 1 .. 1 |-> 0],
      ordStatus                    |-> [i \in 1 .. 1 |-> 0],
      clordidOptional              |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId             |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      account                      |-> [i \in 1 .. 4 |-> 0],
      lastQty                      |-> [i \in 1 .. 8 |-> 0],
      lastPx                       |-> [i \in 1 .. 8 |-> 0],
      execId                       |-> [i \in 1 .. 8 |-> 0],
      transactTime                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty                    |-> [i \in 1 .. 8 |-> 0],
      cumQty                       |-> [i \in 1 .. 8 |-> 0],
      tradeId                      |-> [i \in 1 .. 4 |-> 0],
      contraBroker                 |-> [i \in 1 .. 4 |-> 0],
      orderId                      |-> [i \in 1 .. 8 |-> 0],
      aggressorIndicator           |-> [i \in 1 .. 1 |-> 0],
      settlTypeOptional            |-> [i \in 1 .. 1 |-> 0],
      tradeDate                    |-> [i \in 1 .. 2 |-> 0],
      daysToSettlementOptional     |-> [i \in 1 .. 2 |-> 0],
      offset118Padding2            |-> [i \in 1 .. 2 |-> 0],
      secondaryExecId              |-> [i \in 1 .. 8 |-> 0],
      execRefId                    |-> [i \in 1 .. 8 |-> 0],
      fixedRatePercentage8Optional |-> [i \in 1 .. 8 |-> 0],
      orderQty                     |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId             |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId          |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      deskId                       |-> ZeroDeskId10,
      memo                         |-> ZeroMemo12 ]

(* Execution Report Forward Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportForwardMessage ==
    { ZeroExecutionReportForwardMessage }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader6 }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.clordidOptional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.settlTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.daysToSettlementOptional = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.offset118Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.fixedRatePercentage8Optional = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.deskId = one] : one \in CheckedDeskId10 }
        \cup { [ZeroExecutionReportForwardMessage EXCEPT !.memo = one] : one \in CheckedMemo12 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader7 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader7(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader7(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader7 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader7 ==
    { ZeroOutboundBusinessHeader7 }
        \cup { [ZeroOutboundBusinessHeader7 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader7 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader7 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo13 ==
    [ memoData : SampleBytes ]

EncodeMemo13(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo13(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo13 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo13 ==
    { ZeroMemo13 }
        \cup { [ZeroMemo13 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text2 ==
    [ textData : SampleBytes ]

EncodeText2(message) ==
    EncodeUIntBE(Len(message.textData), 1)
        \o message.textData

DecodeText2(bytes) ==
    LET textLength == ReadUIntBE(bytes, 1) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText2 ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText2 ==
    { ZeroText2 }
        \cup { [ZeroText2 EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Business Message Reject Message                                         *)
(***************************************************************************)

BusinessMessageRejectMessage ==
    [ outboundBusinessHeader : OutboundBusinessHeader7,
      refMsgType             : Sample(1),
      offset19Padding1       : Sample(1),
      refSeqNum              : Sample(4),
      businessRejectRefId    : Sample(8),
      businessRejectReason   : Sample(4),
      memo                   : Memo13,
      text                   : Text2 ]

EncodeBusinessMessageRejectMessage(message) ==
    EncodeOutboundBusinessHeader7(message.outboundBusinessHeader)
        \o message.refMsgType
        \o message.offset19Padding1
        \o message.refSeqNum
        \o message.businessRejectRefId
        \o message.businessRejectReason
        \o EncodeMemo13(message.memo)
        \o EncodeText2(message.text)

DecodeBusinessMessageRejectMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader7(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET refMsgType == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~refMsgType.ok THEN Fail ELSE
    LET offset19Padding1 == ReadBytes(refMsgType.rest, 1) IN IF ~offset19Padding1.ok THEN Fail ELSE
    LET refSeqNum == ReadBytes(offset19Padding1.rest, 4) IN IF ~refSeqNum.ok THEN Fail ELSE
    LET businessRejectRefId == ReadBytes(refSeqNum.rest, 8) IN IF ~businessRejectRefId.ok THEN Fail ELSE
    LET businessRejectReason == ReadBytes(businessRejectRefId.rest, 4) IN IF ~businessRejectReason.ok THEN Fail ELSE
    LET memo == DecodeMemo13(businessRejectReason.rest) IN IF ~memo.ok THEN Fail ELSE
    LET text == DecodeText2(memo.rest) IN IF ~text.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader |-> outboundBusinessHeader.value,
         refMsgType             |-> refMsgType.value,
         offset19Padding1       |-> offset19Padding1.value,
         refSeqNum              |-> refSeqNum.value,
         businessRejectRefId    |-> businessRejectRefId.value,
         businessRejectReason   |-> businessRejectReason.value,
         memo                   |-> memo.value,
         text                   |-> text.value ], text.rest)

ZeroBusinessMessageRejectMessage ==
    [ outboundBusinessHeader |-> ZeroOutboundBusinessHeader7,
      refMsgType             |-> [i \in 1 .. 1 |-> 0],
      offset19Padding1       |-> [i \in 1 .. 1 |-> 0],
      refSeqNum              |-> [i \in 1 .. 4 |-> 0],
      businessRejectRefId    |-> [i \in 1 .. 8 |-> 0],
      businessRejectReason   |-> [i \in 1 .. 4 |-> 0],
      memo                   |-> ZeroMemo13,
      text                   |-> ZeroText2 ]

(* Business Message Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessMessageRejectMessage ==
    { ZeroBusinessMessageRejectMessage }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader7 }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.refMsgType = one] : one \in Sample(1) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.offset19Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.refSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.businessRejectRefId = one] : one \in Sample(8) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.businessRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.memo = one] : one \in CheckedMemo13 }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.text = one] : one \in CheckedText2 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader7 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader7(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader7(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader7 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader7 ==
    { ZeroInboundBusinessHeader7 }
        \cup { [ZeroInboundBusinessHeader7 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader7 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader7 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Legs Group: 30 bytes                                                    *)
(***************************************************************************)

LegsGroup ==
    [ legSymbol   : Sample(20),
      legRatioQty : Sample(8),
      legSide     : Sample(1),
      padding1    : Sample(1) ]

EncodeLegsGroup(message) ==
    message.legSymbol
        \o message.legRatioQty
        \o message.legSide
        \o message.padding1

DecodeLegsGroup(bytes) ==
    LET legSymbol == ReadBytes(bytes, 20) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSymbol.rest, 8) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET padding1 == ReadBytes(legSide.rest, 1) IN IF ~padding1.ok THEN Fail ELSE
    Ok([ legSymbol   |-> legSymbol.value,
         legRatioQty |-> legRatioQty.value,
         legSide     |-> legSide.value,
         padding1    |-> padding1.value ], padding1.rest)

ZeroLegsGroup ==
    [ legSymbol   |-> [i \in 1 .. 20 |-> 0],
      legRatioQty |-> [i \in 1 .. 8 |-> 0],
      legSide     |-> [i \in 1 .. 1 |-> 0],
      padding1    |-> [i \in 1 .. 1 |-> 0] ]

(* Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroup ==
    { ZeroLegsGroup }
        \cup { [ZeroLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(20) }
        \cup { [ZeroLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegsGroup EXCEPT !.padding1 = one] : one \in Sample(1) }

(* A run of Legs Group, written one after another *)
RECURSIVE EncodeLegsGroupList(_)
EncodeLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegsGroup(Head(messages)) \o EncodeLegsGroupList(Tail(messages))

(* As many Legs Group as the field that counts them says *)
RECURSIVE ReadLegsGroupList(_, _)
ReadLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Legs Group of each kind, for the lists that carry them *)
OneLegsGroup == { ZeroLegsGroup }

(***************************************************************************)
(* Legs Groups                                                             *)
(***************************************************************************)

LegsGroups ==
    [ blockLength : Sample(2),
      legsGroup   : SampleLists(OneLegsGroup) ]

EncodeLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.legsGroup), 1)
        \o EncodeLegsGroupList(message.legsGroup)

DecodeLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET legsGroup == ReadLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~legsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         legsGroup   |-> legsGroup.value ], legsGroup.rest)

ZeroLegsGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      legsGroup   |-> << >> ]

(* Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroups ==
    { ZeroLegsGroups }
        \cup { [ZeroLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLegsGroups EXCEPT !.legsGroup = one] : one \in SampleLists(OneLegsGroup) }

(***************************************************************************)
(* Security Definition Request Message                                     *)
(***************************************************************************)

SecurityDefinitionRequestMessage ==
    [ inboundBusinessHeader : InboundBusinessHeader7,
      securityReqId         : Sample(8),
      senderLocation        : Sample(10),
      enteringTrader        : Sample(5),
      legsGroups            : LegsGroups ]

EncodeSecurityDefinitionRequestMessage(message) ==
    EncodeInboundBusinessHeader7(message.inboundBusinessHeader)
        \o message.securityReqId
        \o message.senderLocation
        \o message.enteringTrader
        \o EncodeLegsGroups(message.legsGroups)

DecodeSecurityDefinitionRequestMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader7(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(inboundBusinessHeader.rest, 8) IN IF ~securityReqId.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(securityReqId.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET legsGroups == DecodeLegsGroups(enteringTrader.rest) IN IF ~legsGroups.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader |-> inboundBusinessHeader.value,
         securityReqId         |-> securityReqId.value,
         senderLocation        |-> senderLocation.value,
         enteringTrader        |-> enteringTrader.value,
         legsGroups            |-> legsGroups.value ], legsGroups.rest)

ZeroSecurityDefinitionRequestMessage ==
    [ inboundBusinessHeader |-> ZeroInboundBusinessHeader7,
      securityReqId         |-> [i \in 1 .. 8 |-> 0],
      senderLocation        |-> [i \in 1 .. 10 |-> 0],
      enteringTrader        |-> [i \in 1 .. 5 |-> 0],
      legsGroups            |-> ZeroLegsGroups ]

(* Security Definition Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestMessage ==
    { ZeroSecurityDefinitionRequestMessage }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader7 }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.securityReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.legsGroups = one] : one \in CheckedLegsGroups }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader8 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader8(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader8(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader8 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader8 ==
    { ZeroOutboundBusinessHeader8 }
        \cup { [ZeroOutboundBusinessHeader8 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader8 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader8 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Definition Response Message: 83 bytes                          *)
(***************************************************************************)

SecurityDefinitionResponseMessage ==
    [ outboundBusinessHeader : OutboundBusinessHeader8,
      offset18Padding2       : Sample(2),
      securityReqId          : Sample(8),
      securityIdOptional     : Sample(8),
      securityResponseType   : Sample(1),
      securityStrategyType   : Sample(3),
      symbol                 : Sample(20),
      securityResponseId     : Sample(8),
      senderLocation         : Sample(10),
      enteringTrader         : Sample(5) ]

EncodeSecurityDefinitionResponseMessage(message) ==
    EncodeOutboundBusinessHeader8(message.outboundBusinessHeader)
        \o message.offset18Padding2
        \o message.securityReqId
        \o message.securityIdOptional
        \o message.securityResponseType
        \o message.securityStrategyType
        \o message.symbol
        \o message.securityResponseId
        \o message.senderLocation
        \o message.enteringTrader

DecodeSecurityDefinitionResponseMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader8(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET offset18Padding2 == ReadBytes(outboundBusinessHeader.rest, 2) IN IF ~offset18Padding2.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(offset18Padding2.rest, 8) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(securityReqId.rest, 8) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(securityIdOptional.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET securityStrategyType == ReadBytes(securityResponseType.rest, 3) IN IF ~securityStrategyType.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityStrategyType.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityResponseId == ReadBytes(symbol.rest, 8) IN IF ~securityResponseId.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(securityResponseId.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader |-> outboundBusinessHeader.value,
         offset18Padding2       |-> offset18Padding2.value,
         securityReqId          |-> securityReqId.value,
         securityIdOptional     |-> securityIdOptional.value,
         securityResponseType   |-> securityResponseType.value,
         securityStrategyType   |-> securityStrategyType.value,
         symbol                 |-> symbol.value,
         securityResponseId     |-> securityResponseId.value,
         senderLocation         |-> senderLocation.value,
         enteringTrader         |-> enteringTrader.value ], enteringTrader.rest)

ZeroSecurityDefinitionResponseMessage ==
    [ outboundBusinessHeader |-> ZeroOutboundBusinessHeader8,
      offset18Padding2       |-> [i \in 1 .. 2 |-> 0],
      securityReqId          |-> [i \in 1 .. 8 |-> 0],
      securityIdOptional     |-> [i \in 1 .. 8 |-> 0],
      securityResponseType   |-> [i \in 1 .. 1 |-> 0],
      securityStrategyType   |-> [i \in 1 .. 3 |-> 0],
      symbol                 |-> [i \in 1 .. 20 |-> 0],
      securityResponseId     |-> [i \in 1 .. 8 |-> 0],
      senderLocation         |-> [i \in 1 .. 10 |-> 0],
      enteringTrader         |-> [i \in 1 .. 5 |-> 0] ]

(* Security Definition Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionResponseMessage ==
    { ZeroSecurityDefinitionResponseMessage }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader8 }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.offset18Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityStrategyType = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.securityResponseId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroSecurityDefinitionResponseMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }

(***************************************************************************)
(* Bidirectional Business Header: 19 bytes                                 *)
(***************************************************************************)

BidirectionalBusinessHeader ==
    [ sessionId               : Sample(4),
      msgSeqNum               : Sample(4),
      sendingTime             : Sample(8),
      possResend              : Sample(1),
      marketSegmentIdOptional : Sample(1),
      padding                 : Sample(1) ]

EncodeBidirectionalBusinessHeader(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.marketSegmentIdOptional
        \o message.padding

DecodeBidirectionalBusinessHeader(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET marketSegmentIdOptional == ReadBytes(possResend.rest, 1) IN IF ~marketSegmentIdOptional.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentIdOptional.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId               |-> sessionId.value,
         msgSeqNum               |-> msgSeqNum.value,
         sendingTime             |-> sendingTime.value,
         possResend              |-> possResend.value,
         marketSegmentIdOptional |-> marketSegmentIdOptional.value,
         padding                 |-> padding.value ], padding.rest)

ZeroBidirectionalBusinessHeader ==
    [ sessionId               |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum               |-> [i \in 1 .. 4 |-> 0],
      sendingTime             |-> [i \in 1 .. 8 |-> 0],
      possResend              |-> [i \in 1 .. 1 |-> 0],
      marketSegmentIdOptional |-> [i \in 1 .. 1 |-> 0],
      padding                 |-> [i \in 1 .. 1 |-> 0] ]

(* Bidirectional Business Header at zero, then each field in turn at the values it is checked at *)
CheckedBidirectionalBusinessHeader ==
    { ZeroBidirectionalBusinessHeader }
        \cup { [ZeroBidirectionalBusinessHeader EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroBidirectionalBusinessHeader EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader EXCEPT !.marketSegmentIdOptional = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Sides Group: 5 bytes                                                    *)
(***************************************************************************)

SidesGroup ==
    [ side    : Sample(1),
      account : Sample(4) ]

EncodeSidesGroup(message) ==
    message.side
        \o message.account

DecodeSidesGroup(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET account == ReadBytes(side.rest, 4) IN IF ~account.ok THEN Fail ELSE
    Ok([ side    |-> side.value,
         account |-> account.value ], account.rest)

ZeroSidesGroup ==
    [ side    |-> [i \in 1 .. 1 |-> 0],
      account |-> [i \in 1 .. 4 |-> 0] ]

(* Sides Group at zero, then each field in turn at the values it is checked at *)
CheckedSidesGroup ==
    { ZeroSidesGroup }
        \cup { [ZeroSidesGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSidesGroup EXCEPT !.account = one] : one \in Sample(4) }

(* A run of Sides Group, written one after another *)
RECURSIVE EncodeSidesGroupList(_)
EncodeSidesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSidesGroup(Head(messages)) \o EncodeSidesGroupList(Tail(messages))

(* As many Sides Group as the field that counts them says *)
RECURSIVE ReadSidesGroupList(_, _)
ReadSidesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSidesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSidesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sides Group of each kind, for the lists that carry them *)
OneSidesGroup == { ZeroSidesGroup }

(***************************************************************************)
(* Sides Groups                                                            *)
(***************************************************************************)

SidesGroups ==
    [ blockLength : Sample(2),
      sidesGroup  : SampleLists(OneSidesGroup) ]

EncodeSidesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.sidesGroup), 1)
        \o EncodeSidesGroupList(message.sidesGroup)

DecodeSidesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET sidesGroup == ReadSidesGroupList(numInGroup.rest, numInGroup.value) IN IF ~sidesGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         sidesGroup  |-> sidesGroup.value ], sidesGroup.rest)

ZeroSidesGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      sidesGroup  |-> << >> ]

(* Sides Groups at zero, then each field in turn at the values it is checked at *)
CheckedSidesGroups ==
    { ZeroSidesGroups }
        \cup { [ZeroSidesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSidesGroups EXCEPT !.sidesGroup = one] : one \in SampleLists(OneSidesGroup) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId11 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId11(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId11(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId11 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId11 ==
    { ZeroDeskId11 }
        \cup { [ZeroDeskId11 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo14 ==
    [ memoData : SampleBytes ]

EncodeMemo14(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo14(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo14 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo14 ==
    { ZeroMemo14 }
        \cup { [ZeroMemo14 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Quote Request Message                                                   *)
(***************************************************************************)

QuoteRequestMessage ==
    [ bidirectionalBusinessHeader : BidirectionalBusinessHeader,
      securityId                  : Sample(8),
      quoteReqId                  : Sample(8),
      quoteIdOptional             : Sample(8),
      tradeIdOptional             : Sample(4),
      contraBroker                : Sample(4),
      transactTime                : Sample(8),
      price8                      : Sample(8),
      settlType                   : Sample(1),
      executeUnderlyingTrade      : Sample(1),
      orderQty                    : Sample(8),
      senderLocation              : Sample(10),
      enteringTrader              : Sample(5),
      executingTrader             : Sample(5),
      fixedRatePercentage8        : Sample(8),
      daysToSettlement            : Sample(2),
      sidesGroups                 : SidesGroups,
      deskId                      : DeskId11,
      memo                        : Memo14 ]

EncodeQuoteRequestMessage(message) ==
    EncodeBidirectionalBusinessHeader(message.bidirectionalBusinessHeader)
        \o message.securityId
        \o message.quoteReqId
        \o message.quoteIdOptional
        \o message.tradeIdOptional
        \o message.contraBroker
        \o message.transactTime
        \o message.price8
        \o message.settlType
        \o message.executeUnderlyingTrade
        \o message.orderQty
        \o message.senderLocation
        \o message.enteringTrader
        \o message.executingTrader
        \o message.fixedRatePercentage8
        \o message.daysToSettlement
        \o EncodeSidesGroups(message.sidesGroups)
        \o EncodeDeskId11(message.deskId)
        \o EncodeMemo14(message.memo)

DecodeQuoteRequestMessage(bytes) ==
    LET bidirectionalBusinessHeader == DecodeBidirectionalBusinessHeader(bytes) IN IF ~bidirectionalBusinessHeader.ok THEN Fail ELSE
    LET securityId == ReadBytes(bidirectionalBusinessHeader.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(securityId.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET quoteIdOptional == ReadBytes(quoteReqId.rest, 8) IN IF ~quoteIdOptional.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(quoteIdOptional.rest, 4) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeIdOptional.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET transactTime == ReadBytes(contraBroker.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET price8 == ReadBytes(transactTime.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    LET settlType == ReadBytes(price8.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET executeUnderlyingTrade == ReadBytes(settlType.rest, 1) IN IF ~executeUnderlyingTrade.ok THEN Fail ELSE
    LET orderQty == ReadBytes(executeUnderlyingTrade.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(orderQty.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(enteringTrader.rest, 5) IN IF ~executingTrader.ok THEN Fail ELSE
    LET fixedRatePercentage8 == ReadBytes(executingTrader.rest, 8) IN IF ~fixedRatePercentage8.ok THEN Fail ELSE
    LET daysToSettlement == ReadBytes(fixedRatePercentage8.rest, 2) IN IF ~daysToSettlement.ok THEN Fail ELSE
    LET sidesGroups == DecodeSidesGroups(daysToSettlement.rest) IN IF ~sidesGroups.ok THEN Fail ELSE
    LET deskId == DecodeDeskId11(sidesGroups.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo14(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ bidirectionalBusinessHeader |-> bidirectionalBusinessHeader.value,
         securityId                  |-> securityId.value,
         quoteReqId                  |-> quoteReqId.value,
         quoteIdOptional             |-> quoteIdOptional.value,
         tradeIdOptional             |-> tradeIdOptional.value,
         contraBroker                |-> contraBroker.value,
         transactTime                |-> transactTime.value,
         price8                      |-> price8.value,
         settlType                   |-> settlType.value,
         executeUnderlyingTrade      |-> executeUnderlyingTrade.value,
         orderQty                    |-> orderQty.value,
         senderLocation              |-> senderLocation.value,
         enteringTrader              |-> enteringTrader.value,
         executingTrader             |-> executingTrader.value,
         fixedRatePercentage8        |-> fixedRatePercentage8.value,
         daysToSettlement            |-> daysToSettlement.value,
         sidesGroups                 |-> sidesGroups.value,
         deskId                      |-> deskId.value,
         memo                        |-> memo.value ], memo.rest)

ZeroQuoteRequestMessage ==
    [ bidirectionalBusinessHeader |-> ZeroBidirectionalBusinessHeader,
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      quoteReqId                  |-> [i \in 1 .. 8 |-> 0],
      quoteIdOptional             |-> [i \in 1 .. 8 |-> 0],
      tradeIdOptional             |-> [i \in 1 .. 4 |-> 0],
      contraBroker                |-> [i \in 1 .. 4 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      price8                      |-> [i \in 1 .. 8 |-> 0],
      settlType                   |-> [i \in 1 .. 1 |-> 0],
      executeUnderlyingTrade      |-> [i \in 1 .. 1 |-> 0],
      orderQty                    |-> [i \in 1 .. 8 |-> 0],
      senderLocation              |-> [i \in 1 .. 10 |-> 0],
      enteringTrader              |-> [i \in 1 .. 5 |-> 0],
      executingTrader             |-> [i \in 1 .. 5 |-> 0],
      fixedRatePercentage8        |-> [i \in 1 .. 8 |-> 0],
      daysToSettlement            |-> [i \in 1 .. 2 |-> 0],
      sidesGroups                 |-> ZeroSidesGroups,
      deskId                      |-> ZeroDeskId11,
      memo                        |-> ZeroMemo14 ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.bidirectionalBusinessHeader = one] : one \in CheckedBidirectionalBusinessHeader }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quoteIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.tradeIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.price8 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.executeUnderlyingTrade = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.executingTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.fixedRatePercentage8 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.daysToSettlement = one] : one \in Sample(2) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.sidesGroups = one] : one \in CheckedSidesGroups }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.deskId = one] : one \in CheckedDeskId11 }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.memo = one] : one \in CheckedMemo14 }

(***************************************************************************)
(* Bidirectional Business Header: 19 bytes                                 *)
(***************************************************************************)

BidirectionalBusinessHeader2 ==
    [ sessionId               : Sample(4),
      msgSeqNum               : Sample(4),
      sendingTime             : Sample(8),
      possResend              : Sample(1),
      marketSegmentIdOptional : Sample(1),
      padding                 : Sample(1) ]

EncodeBidirectionalBusinessHeader2(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.marketSegmentIdOptional
        \o message.padding

DecodeBidirectionalBusinessHeader2(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET marketSegmentIdOptional == ReadBytes(possResend.rest, 1) IN IF ~marketSegmentIdOptional.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentIdOptional.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId               |-> sessionId.value,
         msgSeqNum               |-> msgSeqNum.value,
         sendingTime             |-> sendingTime.value,
         possResend              |-> possResend.value,
         marketSegmentIdOptional |-> marketSegmentIdOptional.value,
         padding                 |-> padding.value ], padding.rest)

ZeroBidirectionalBusinessHeader2 ==
    [ sessionId               |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum               |-> [i \in 1 .. 4 |-> 0],
      sendingTime             |-> [i \in 1 .. 8 |-> 0],
      possResend              |-> [i \in 1 .. 1 |-> 0],
      marketSegmentIdOptional |-> [i \in 1 .. 1 |-> 0],
      padding                 |-> [i \in 1 .. 1 |-> 0] ]

(* Bidirectional Business Header at zero, then each field in turn at the values it is checked at *)
CheckedBidirectionalBusinessHeader2 ==
    { ZeroBidirectionalBusinessHeader2 }
        \cup { [ZeroBidirectionalBusinessHeader2 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroBidirectionalBusinessHeader2 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader2 EXCEPT !.marketSegmentIdOptional = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader2 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId12 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId12(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId12(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId12 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId12 ==
    { ZeroDeskId12 }
        \cup { [ZeroDeskId12 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo15 ==
    [ memoData : SampleBytes ]

EncodeMemo15(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo15(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo15 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo15 ==
    { ZeroMemo15 }
        \cup { [ZeroMemo15 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text3 ==
    [ textData : SampleBytes ]

EncodeText3(message) ==
    EncodeUIntBE(Len(message.textData), 1)
        \o message.textData

DecodeText3(bytes) ==
    LET textLength == ReadUIntBE(bytes, 1) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText3 ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText3 ==
    { ZeroText3 }
        \cup { [ZeroText3 EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Quote Status Report Message                                             *)
(***************************************************************************)

QuoteStatusReportMessage ==
    [ bidirectionalBusinessHeader  : BidirectionalBusinessHeader2,
      quoteRejectReason            : Sample(4),
      securityId                   : Sample(8),
      quoteReqId                   : Sample(8),
      quoteId                      : Sample(8),
      tradeIdOptional              : Sample(4),
      contraBroker                 : Sample(4),
      transactTime                 : Sample(8),
      quoteStatus                  : Sample(1),
      quoteStatusResponseTo        : Sample(1),
      account                      : Sample(4),
      sideOptional                 : Sample(1),
      settlTypeOptional            : Sample(1),
      price8Optional               : Sample(8),
      orderQty                     : Sample(8),
      senderLocation               : Sample(10),
      enteringTrader               : Sample(5),
      executingTrader              : Sample(5),
      fixedRatePercentage8Optional : Sample(8),
      executeUnderlyingTrade       : Sample(1),
      daysToSettlementOptional     : Sample(2),
      deskId                       : DeskId12,
      memo                         : Memo15,
      text                         : Text3 ]

EncodeQuoteStatusReportMessage(message) ==
    EncodeBidirectionalBusinessHeader2(message.bidirectionalBusinessHeader)
        \o message.quoteRejectReason
        \o message.securityId
        \o message.quoteReqId
        \o message.quoteId
        \o message.tradeIdOptional
        \o message.contraBroker
        \o message.transactTime
        \o message.quoteStatus
        \o message.quoteStatusResponseTo
        \o message.account
        \o message.sideOptional
        \o message.settlTypeOptional
        \o message.price8Optional
        \o message.orderQty
        \o message.senderLocation
        \o message.enteringTrader
        \o message.executingTrader
        \o message.fixedRatePercentage8Optional
        \o message.executeUnderlyingTrade
        \o message.daysToSettlementOptional
        \o EncodeDeskId12(message.deskId)
        \o EncodeMemo15(message.memo)
        \o EncodeText3(message.text)

DecodeQuoteStatusReportMessage(bytes) ==
    LET bidirectionalBusinessHeader == DecodeBidirectionalBusinessHeader2(bytes) IN IF ~bidirectionalBusinessHeader.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(bidirectionalBusinessHeader.rest, 4) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteRejectReason.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(securityId.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(quoteReqId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(quoteId.rest, 4) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeIdOptional.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET transactTime == ReadBytes(contraBroker.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(transactTime.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET quoteStatusResponseTo == ReadBytes(quoteStatus.rest, 1) IN IF ~quoteStatusResponseTo.ok THEN Fail ELSE
    LET account == ReadBytes(quoteStatusResponseTo.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(account.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET settlTypeOptional == ReadBytes(sideOptional.rest, 1) IN IF ~settlTypeOptional.ok THEN Fail ELSE
    LET price8Optional == ReadBytes(settlTypeOptional.rest, 8) IN IF ~price8Optional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price8Optional.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(orderQty.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(enteringTrader.rest, 5) IN IF ~executingTrader.ok THEN Fail ELSE
    LET fixedRatePercentage8Optional == ReadBytes(executingTrader.rest, 8) IN IF ~fixedRatePercentage8Optional.ok THEN Fail ELSE
    LET executeUnderlyingTrade == ReadBytes(fixedRatePercentage8Optional.rest, 1) IN IF ~executeUnderlyingTrade.ok THEN Fail ELSE
    LET daysToSettlementOptional == ReadBytes(executeUnderlyingTrade.rest, 2) IN IF ~daysToSettlementOptional.ok THEN Fail ELSE
    LET deskId == DecodeDeskId12(daysToSettlementOptional.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo15(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    LET text == DecodeText3(memo.rest) IN IF ~text.ok THEN Fail ELSE
    Ok([ bidirectionalBusinessHeader  |-> bidirectionalBusinessHeader.value,
         quoteRejectReason            |-> quoteRejectReason.value,
         securityId                   |-> securityId.value,
         quoteReqId                   |-> quoteReqId.value,
         quoteId                      |-> quoteId.value,
         tradeIdOptional              |-> tradeIdOptional.value,
         contraBroker                 |-> contraBroker.value,
         transactTime                 |-> transactTime.value,
         quoteStatus                  |-> quoteStatus.value,
         quoteStatusResponseTo        |-> quoteStatusResponseTo.value,
         account                      |-> account.value,
         sideOptional                 |-> sideOptional.value,
         settlTypeOptional            |-> settlTypeOptional.value,
         price8Optional               |-> price8Optional.value,
         orderQty                     |-> orderQty.value,
         senderLocation               |-> senderLocation.value,
         enteringTrader               |-> enteringTrader.value,
         executingTrader              |-> executingTrader.value,
         fixedRatePercentage8Optional |-> fixedRatePercentage8Optional.value,
         executeUnderlyingTrade       |-> executeUnderlyingTrade.value,
         daysToSettlementOptional     |-> daysToSettlementOptional.value,
         deskId                       |-> deskId.value,
         memo                         |-> memo.value,
         text                         |-> text.value ], text.rest)

ZeroQuoteStatusReportMessage ==
    [ bidirectionalBusinessHeader  |-> ZeroBidirectionalBusinessHeader2,
      quoteRejectReason            |-> [i \in 1 .. 4 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      quoteReqId                   |-> [i \in 1 .. 8 |-> 0],
      quoteId                      |-> [i \in 1 .. 8 |-> 0],
      tradeIdOptional              |-> [i \in 1 .. 4 |-> 0],
      contraBroker                 |-> [i \in 1 .. 4 |-> 0],
      transactTime                 |-> [i \in 1 .. 8 |-> 0],
      quoteStatus                  |-> [i \in 1 .. 1 |-> 0],
      quoteStatusResponseTo        |-> [i \in 1 .. 1 |-> 0],
      account                      |-> [i \in 1 .. 4 |-> 0],
      sideOptional                 |-> [i \in 1 .. 1 |-> 0],
      settlTypeOptional            |-> [i \in 1 .. 1 |-> 0],
      price8Optional               |-> [i \in 1 .. 8 |-> 0],
      orderQty                     |-> [i \in 1 .. 8 |-> 0],
      senderLocation               |-> [i \in 1 .. 10 |-> 0],
      enteringTrader               |-> [i \in 1 .. 5 |-> 0],
      executingTrader              |-> [i \in 1 .. 5 |-> 0],
      fixedRatePercentage8Optional |-> [i \in 1 .. 8 |-> 0],
      executeUnderlyingTrade       |-> [i \in 1 .. 1 |-> 0],
      daysToSettlementOptional     |-> [i \in 1 .. 2 |-> 0],
      deskId                       |-> ZeroDeskId12,
      memo                         |-> ZeroMemo15,
      text                         |-> ZeroText3 ]

(* Quote Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteStatusReportMessage ==
    { ZeroQuoteStatusReportMessage }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.bidirectionalBusinessHeader = one] : one \in CheckedBidirectionalBusinessHeader2 }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.tradeIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.quoteStatusResponseTo = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.settlTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.price8Optional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.executingTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.fixedRatePercentage8Optional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.executeUnderlyingTrade = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.daysToSettlementOptional = one] : one \in Sample(2) }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.deskId = one] : one \in CheckedDeskId12 }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.memo = one] : one \in CheckedMemo15 }
        \cup { [ZeroQuoteStatusReportMessage EXCEPT !.text = one] : one \in CheckedText3 }

(***************************************************************************)
(* Bidirectional Business Header: 19 bytes                                 *)
(***************************************************************************)

BidirectionalBusinessHeader3 ==
    [ sessionId               : Sample(4),
      msgSeqNum               : Sample(4),
      sendingTime             : Sample(8),
      possResend              : Sample(1),
      marketSegmentIdOptional : Sample(1),
      padding                 : Sample(1) ]

EncodeBidirectionalBusinessHeader3(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.marketSegmentIdOptional
        \o message.padding

DecodeBidirectionalBusinessHeader3(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET marketSegmentIdOptional == ReadBytes(possResend.rest, 1) IN IF ~marketSegmentIdOptional.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentIdOptional.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId               |-> sessionId.value,
         msgSeqNum               |-> msgSeqNum.value,
         sendingTime             |-> sendingTime.value,
         possResend              |-> possResend.value,
         marketSegmentIdOptional |-> marketSegmentIdOptional.value,
         padding                 |-> padding.value ], padding.rest)

ZeroBidirectionalBusinessHeader3 ==
    [ sessionId               |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum               |-> [i \in 1 .. 4 |-> 0],
      sendingTime             |-> [i \in 1 .. 8 |-> 0],
      possResend              |-> [i \in 1 .. 1 |-> 0],
      marketSegmentIdOptional |-> [i \in 1 .. 1 |-> 0],
      padding                 |-> [i \in 1 .. 1 |-> 0] ]

(* Bidirectional Business Header at zero, then each field in turn at the values it is checked at *)
CheckedBidirectionalBusinessHeader3 ==
    { ZeroBidirectionalBusinessHeader3 }
        \cup { [ZeroBidirectionalBusinessHeader3 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroBidirectionalBusinessHeader3 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader3 EXCEPT !.marketSegmentIdOptional = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader3 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId13 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId13(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId13(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId13 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId13 ==
    { ZeroDeskId13 }
        \cup { [ZeroDeskId13 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo16 ==
    [ memoData : SampleBytes ]

EncodeMemo16(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo16(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo16 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo16 ==
    { ZeroMemo16 }
        \cup { [ZeroMemo16 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Quote Message                                                           *)
(***************************************************************************)

QuoteMessage ==
    [ bidirectionalBusinessHeader : BidirectionalBusinessHeader3,
      securityId                  : Sample(8),
      quoteReqId                  : Sample(8),
      quoteId                     : Sample(8),
      transactTime                : Sample(8),
      price8Optional              : Sample(8),
      orderQty                    : Sample(8),
      side                        : Sample(1),
      settlType                   : Sample(1),
      account                     : Sample(4),
      senderLocation              : Sample(10),
      enteringTrader              : Sample(5),
      executingTrader             : Sample(5),
      fixedRatePercentage8        : Sample(8),
      executeUnderlyingTrade      : Sample(1),
      daysToSettlement            : Sample(2),
      deskId                      : DeskId13,
      memo                        : Memo16 ]

EncodeQuoteMessage(message) ==
    EncodeBidirectionalBusinessHeader3(message.bidirectionalBusinessHeader)
        \o message.securityId
        \o message.quoteReqId
        \o message.quoteId
        \o message.transactTime
        \o message.price8Optional
        \o message.orderQty
        \o message.side
        \o message.settlType
        \o message.account
        \o message.senderLocation
        \o message.enteringTrader
        \o message.executingTrader
        \o message.fixedRatePercentage8
        \o message.executeUnderlyingTrade
        \o message.daysToSettlement
        \o EncodeDeskId13(message.deskId)
        \o EncodeMemo16(message.memo)

DecodeQuoteMessage(bytes) ==
    LET bidirectionalBusinessHeader == DecodeBidirectionalBusinessHeader3(bytes) IN IF ~bidirectionalBusinessHeader.ok THEN Fail ELSE
    LET securityId == ReadBytes(bidirectionalBusinessHeader.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(securityId.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(quoteReqId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(quoteId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET price8Optional == ReadBytes(transactTime.rest, 8) IN IF ~price8Optional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price8Optional.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET settlType == ReadBytes(side.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET account == ReadBytes(settlType.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(enteringTrader.rest, 5) IN IF ~executingTrader.ok THEN Fail ELSE
    LET fixedRatePercentage8 == ReadBytes(executingTrader.rest, 8) IN IF ~fixedRatePercentage8.ok THEN Fail ELSE
    LET executeUnderlyingTrade == ReadBytes(fixedRatePercentage8.rest, 1) IN IF ~executeUnderlyingTrade.ok THEN Fail ELSE
    LET daysToSettlement == ReadBytes(executeUnderlyingTrade.rest, 2) IN IF ~daysToSettlement.ok THEN Fail ELSE
    LET deskId == DecodeDeskId13(daysToSettlement.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo16(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ bidirectionalBusinessHeader |-> bidirectionalBusinessHeader.value,
         securityId                  |-> securityId.value,
         quoteReqId                  |-> quoteReqId.value,
         quoteId                     |-> quoteId.value,
         transactTime                |-> transactTime.value,
         price8Optional              |-> price8Optional.value,
         orderQty                    |-> orderQty.value,
         side                        |-> side.value,
         settlType                   |-> settlType.value,
         account                     |-> account.value,
         senderLocation              |-> senderLocation.value,
         enteringTrader              |-> enteringTrader.value,
         executingTrader             |-> executingTrader.value,
         fixedRatePercentage8        |-> fixedRatePercentage8.value,
         executeUnderlyingTrade      |-> executeUnderlyingTrade.value,
         daysToSettlement            |-> daysToSettlement.value,
         deskId                      |-> deskId.value,
         memo                        |-> memo.value ], memo.rest)

ZeroQuoteMessage ==
    [ bidirectionalBusinessHeader |-> ZeroBidirectionalBusinessHeader3,
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      quoteReqId                  |-> [i \in 1 .. 8 |-> 0],
      quoteId                     |-> [i \in 1 .. 8 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      price8Optional              |-> [i \in 1 .. 8 |-> 0],
      orderQty                    |-> [i \in 1 .. 8 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      settlType                   |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 4 |-> 0],
      senderLocation              |-> [i \in 1 .. 10 |-> 0],
      enteringTrader              |-> [i \in 1 .. 5 |-> 0],
      executingTrader             |-> [i \in 1 .. 5 |-> 0],
      fixedRatePercentage8        |-> [i \in 1 .. 8 |-> 0],
      executeUnderlyingTrade      |-> [i \in 1 .. 1 |-> 0],
      daysToSettlement            |-> [i \in 1 .. 2 |-> 0],
      deskId                      |-> ZeroDeskId13,
      memo                        |-> ZeroMemo16 ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.bidirectionalBusinessHeader = one] : one \in CheckedBidirectionalBusinessHeader3 }
        \cup { [ZeroQuoteMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.price8Optional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroQuoteMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteMessage EXCEPT !.executingTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteMessage EXCEPT !.fixedRatePercentage8 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.executeUnderlyingTrade = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.daysToSettlement = one] : one \in Sample(2) }
        \cup { [ZeroQuoteMessage EXCEPT !.deskId = one] : one \in CheckedDeskId13 }
        \cup { [ZeroQuoteMessage EXCEPT !.memo = one] : one \in CheckedMemo16 }

(***************************************************************************)
(* Bidirectional Business Header: 19 bytes                                 *)
(***************************************************************************)

BidirectionalBusinessHeader4 ==
    [ sessionId               : Sample(4),
      msgSeqNum               : Sample(4),
      sendingTime             : Sample(8),
      possResend              : Sample(1),
      marketSegmentIdOptional : Sample(1),
      padding                 : Sample(1) ]

EncodeBidirectionalBusinessHeader4(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.marketSegmentIdOptional
        \o message.padding

DecodeBidirectionalBusinessHeader4(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET marketSegmentIdOptional == ReadBytes(possResend.rest, 1) IN IF ~marketSegmentIdOptional.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentIdOptional.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId               |-> sessionId.value,
         msgSeqNum               |-> msgSeqNum.value,
         sendingTime             |-> sendingTime.value,
         possResend              |-> possResend.value,
         marketSegmentIdOptional |-> marketSegmentIdOptional.value,
         padding                 |-> padding.value ], padding.rest)

ZeroBidirectionalBusinessHeader4 ==
    [ sessionId               |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum               |-> [i \in 1 .. 4 |-> 0],
      sendingTime             |-> [i \in 1 .. 8 |-> 0],
      possResend              |-> [i \in 1 .. 1 |-> 0],
      marketSegmentIdOptional |-> [i \in 1 .. 1 |-> 0],
      padding                 |-> [i \in 1 .. 1 |-> 0] ]

(* Bidirectional Business Header at zero, then each field in turn at the values it is checked at *)
CheckedBidirectionalBusinessHeader4 ==
    { ZeroBidirectionalBusinessHeader4 }
        \cup { [ZeroBidirectionalBusinessHeader4 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroBidirectionalBusinessHeader4 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader4 EXCEPT !.marketSegmentIdOptional = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader4 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId14 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId14(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId14(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId14 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId14 ==
    { ZeroDeskId14 }
        \cup { [ZeroDeskId14 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo17 ==
    [ memoData : SampleBytes ]

EncodeMemo17(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo17(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo17 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo17 ==
    { ZeroMemo17 }
        \cup { [ZeroMemo17 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Quote Cancel Message                                                    *)
(***************************************************************************)

QuoteCancelMessage ==
    [ bidirectionalBusinessHeader : BidirectionalBusinessHeader4,
      securityId                  : Sample(8),
      quoteReqIdOptional          : Sample(8),
      quoteIdOptional             : Sample(8),
      account                     : Sample(4),
      senderLocation              : Sample(10),
      enteringTrader              : Sample(5),
      executingTrader             : Sample(5),
      deskId                      : DeskId14,
      memo                        : Memo17 ]

EncodeQuoteCancelMessage(message) ==
    EncodeBidirectionalBusinessHeader4(message.bidirectionalBusinessHeader)
        \o message.securityId
        \o message.quoteReqIdOptional
        \o message.quoteIdOptional
        \o message.account
        \o message.senderLocation
        \o message.enteringTrader
        \o message.executingTrader
        \o EncodeDeskId14(message.deskId)
        \o EncodeMemo17(message.memo)

DecodeQuoteCancelMessage(bytes) ==
    LET bidirectionalBusinessHeader == DecodeBidirectionalBusinessHeader4(bytes) IN IF ~bidirectionalBusinessHeader.ok THEN Fail ELSE
    LET securityId == ReadBytes(bidirectionalBusinessHeader.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteReqIdOptional == ReadBytes(securityId.rest, 8) IN IF ~quoteReqIdOptional.ok THEN Fail ELSE
    LET quoteIdOptional == ReadBytes(quoteReqIdOptional.rest, 8) IN IF ~quoteIdOptional.ok THEN Fail ELSE
    LET account == ReadBytes(quoteIdOptional.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(enteringTrader.rest, 5) IN IF ~executingTrader.ok THEN Fail ELSE
    LET deskId == DecodeDeskId14(executingTrader.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo17(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ bidirectionalBusinessHeader |-> bidirectionalBusinessHeader.value,
         securityId                  |-> securityId.value,
         quoteReqIdOptional          |-> quoteReqIdOptional.value,
         quoteIdOptional             |-> quoteIdOptional.value,
         account                     |-> account.value,
         senderLocation              |-> senderLocation.value,
         enteringTrader              |-> enteringTrader.value,
         executingTrader             |-> executingTrader.value,
         deskId                      |-> deskId.value,
         memo                        |-> memo.value ], memo.rest)

ZeroQuoteCancelMessage ==
    [ bidirectionalBusinessHeader |-> ZeroBidirectionalBusinessHeader4,
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      quoteReqIdOptional          |-> [i \in 1 .. 8 |-> 0],
      quoteIdOptional             |-> [i \in 1 .. 8 |-> 0],
      account                     |-> [i \in 1 .. 4 |-> 0],
      senderLocation              |-> [i \in 1 .. 10 |-> 0],
      enteringTrader              |-> [i \in 1 .. 5 |-> 0],
      executingTrader             |-> [i \in 1 .. 5 |-> 0],
      deskId                      |-> ZeroDeskId14,
      memo                        |-> ZeroMemo17 ]

(* Quote Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelMessage ==
    { ZeroQuoteCancelMessage }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.bidirectionalBusinessHeader = one] : one \in CheckedBidirectionalBusinessHeader4 }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.quoteReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.quoteIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.executingTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.deskId = one] : one \in CheckedDeskId14 }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.memo = one] : one \in CheckedMemo17 }

(***************************************************************************)
(* Bidirectional Business Header: 19 bytes                                 *)
(***************************************************************************)

BidirectionalBusinessHeader5 ==
    [ sessionId               : Sample(4),
      msgSeqNum               : Sample(4),
      sendingTime             : Sample(8),
      possResend              : Sample(1),
      marketSegmentIdOptional : Sample(1),
      padding                 : Sample(1) ]

EncodeBidirectionalBusinessHeader5(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.marketSegmentIdOptional
        \o message.padding

DecodeBidirectionalBusinessHeader5(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET marketSegmentIdOptional == ReadBytes(possResend.rest, 1) IN IF ~marketSegmentIdOptional.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentIdOptional.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId               |-> sessionId.value,
         msgSeqNum               |-> msgSeqNum.value,
         sendingTime             |-> sendingTime.value,
         possResend              |-> possResend.value,
         marketSegmentIdOptional |-> marketSegmentIdOptional.value,
         padding                 |-> padding.value ], padding.rest)

ZeroBidirectionalBusinessHeader5 ==
    [ sessionId               |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum               |-> [i \in 1 .. 4 |-> 0],
      sendingTime             |-> [i \in 1 .. 8 |-> 0],
      possResend              |-> [i \in 1 .. 1 |-> 0],
      marketSegmentIdOptional |-> [i \in 1 .. 1 |-> 0],
      padding                 |-> [i \in 1 .. 1 |-> 0] ]

(* Bidirectional Business Header at zero, then each field in turn at the values it is checked at *)
CheckedBidirectionalBusinessHeader5 ==
    { ZeroBidirectionalBusinessHeader5 }
        \cup { [ZeroBidirectionalBusinessHeader5 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroBidirectionalBusinessHeader5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroBidirectionalBusinessHeader5 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader5 EXCEPT !.marketSegmentIdOptional = one] : one \in Sample(1) }
        \cup { [ZeroBidirectionalBusinessHeader5 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Sides Group: 5 bytes                                                    *)
(***************************************************************************)

SidesGroup2 ==
    [ side    : Sample(1),
      account : Sample(4) ]

EncodeSidesGroup2(message) ==
    message.side
        \o message.account

DecodeSidesGroup2(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET account == ReadBytes(side.rest, 4) IN IF ~account.ok THEN Fail ELSE
    Ok([ side    |-> side.value,
         account |-> account.value ], account.rest)

ZeroSidesGroup2 ==
    [ side    |-> [i \in 1 .. 1 |-> 0],
      account |-> [i \in 1 .. 4 |-> 0] ]

(* Sides Group at zero, then each field in turn at the values it is checked at *)
CheckedSidesGroup2 ==
    { ZeroSidesGroup2 }
        \cup { [ZeroSidesGroup2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSidesGroup2 EXCEPT !.account = one] : one \in Sample(4) }

(* A run of Sides Group, written one after another *)
RECURSIVE EncodeSidesGroup2List(_)
EncodeSidesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSidesGroup2(Head(messages)) \o EncodeSidesGroup2List(Tail(messages))

(* As many Sides Group as the field that counts them says *)
RECURSIVE ReadSidesGroup2List(_, _)
ReadSidesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSidesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSidesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sides Group of each kind, for the lists that carry them *)
OneSidesGroup2 == { ZeroSidesGroup2 }

(***************************************************************************)
(* Sides Groups                                                            *)
(***************************************************************************)

SidesGroups2 ==
    [ blockLength : Sample(2),
      sidesGroup  : SampleLists(OneSidesGroup2) ]

EncodeSidesGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.sidesGroup), 1)
        \o EncodeSidesGroup2List(message.sidesGroup)

DecodeSidesGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET sidesGroup == ReadSidesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~sidesGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         sidesGroup  |-> sidesGroup.value ], sidesGroup.rest)

ZeroSidesGroups2 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      sidesGroup  |-> << >> ]

(* Sides Groups at zero, then each field in turn at the values it is checked at *)
CheckedSidesGroups2 ==
    { ZeroSidesGroups2 }
        \cup { [ZeroSidesGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSidesGroups2 EXCEPT !.sidesGroup = one] : one \in SampleLists(OneSidesGroup2) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId15 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId15(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId15(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId15 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId15 ==
    { ZeroDeskId15 }
        \cup { [ZeroDeskId15 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo18 ==
    [ memoData : SampleBytes ]

EncodeMemo18(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo18(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo18 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo18 ==
    { ZeroMemo18 }
        \cup { [ZeroMemo18 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text4 ==
    [ textData : SampleBytes ]

EncodeText4(message) ==
    EncodeUIntBE(Len(message.textData), 1)
        \o message.textData

DecodeText4(bytes) ==
    LET textLength == ReadUIntBE(bytes, 1) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText4 ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText4 ==
    { ZeroText4 }
        \cup { [ZeroText4 EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Quote Request Reject Message                                            *)
(***************************************************************************)

QuoteRequestRejectMessage ==
    [ bidirectionalBusinessHeader  : BidirectionalBusinessHeader5,
      quoteRequestRejectReason     : Sample(4),
      securityId                   : Sample(8),
      quoteReqId                   : Sample(8),
      quoteIdOptional              : Sample(8),
      tradeIdOptional              : Sample(4),
      contraBroker                 : Sample(4),
      transactTime                 : Sample(8),
      enteringTrader               : Sample(5),
      settlTypeOptional            : Sample(1),
      price8Optional               : Sample(8),
      orderQtyOptional             : Sample(8),
      senderLocation               : Sample(10),
      executingTrader              : Sample(5),
      fixedRatePercentage8Optional : Sample(8),
      daysToSettlementOptional     : Sample(2),
      sidesGroups                  : SidesGroups2,
      deskId                       : DeskId15,
      memo                         : Memo18,
      text                         : Text4 ]

EncodeQuoteRequestRejectMessage(message) ==
    EncodeBidirectionalBusinessHeader5(message.bidirectionalBusinessHeader)
        \o message.quoteRequestRejectReason
        \o message.securityId
        \o message.quoteReqId
        \o message.quoteIdOptional
        \o message.tradeIdOptional
        \o message.contraBroker
        \o message.transactTime
        \o message.enteringTrader
        \o message.settlTypeOptional
        \o message.price8Optional
        \o message.orderQtyOptional
        \o message.senderLocation
        \o message.executingTrader
        \o message.fixedRatePercentage8Optional
        \o message.daysToSettlementOptional
        \o EncodeSidesGroups2(message.sidesGroups)
        \o EncodeDeskId15(message.deskId)
        \o EncodeMemo18(message.memo)
        \o EncodeText4(message.text)

DecodeQuoteRequestRejectMessage(bytes) ==
    LET bidirectionalBusinessHeader == DecodeBidirectionalBusinessHeader5(bytes) IN IF ~bidirectionalBusinessHeader.ok THEN Fail ELSE
    LET quoteRequestRejectReason == ReadBytes(bidirectionalBusinessHeader.rest, 4) IN IF ~quoteRequestRejectReason.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteRequestRejectReason.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(securityId.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET quoteIdOptional == ReadBytes(quoteReqId.rest, 8) IN IF ~quoteIdOptional.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(quoteIdOptional.rest, 4) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeIdOptional.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET transactTime == ReadBytes(contraBroker.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(transactTime.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET settlTypeOptional == ReadBytes(enteringTrader.rest, 1) IN IF ~settlTypeOptional.ok THEN Fail ELSE
    LET price8Optional == ReadBytes(settlTypeOptional.rest, 8) IN IF ~price8Optional.ok THEN Fail ELSE
    LET orderQtyOptional == ReadBytes(price8Optional.rest, 8) IN IF ~orderQtyOptional.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(orderQtyOptional.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(senderLocation.rest, 5) IN IF ~executingTrader.ok THEN Fail ELSE
    LET fixedRatePercentage8Optional == ReadBytes(executingTrader.rest, 8) IN IF ~fixedRatePercentage8Optional.ok THEN Fail ELSE
    LET daysToSettlementOptional == ReadBytes(fixedRatePercentage8Optional.rest, 2) IN IF ~daysToSettlementOptional.ok THEN Fail ELSE
    LET sidesGroups == DecodeSidesGroups2(daysToSettlementOptional.rest) IN IF ~sidesGroups.ok THEN Fail ELSE
    LET deskId == DecodeDeskId15(sidesGroups.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo18(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    LET text == DecodeText4(memo.rest) IN IF ~text.ok THEN Fail ELSE
    Ok([ bidirectionalBusinessHeader  |-> bidirectionalBusinessHeader.value,
         quoteRequestRejectReason     |-> quoteRequestRejectReason.value,
         securityId                   |-> securityId.value,
         quoteReqId                   |-> quoteReqId.value,
         quoteIdOptional              |-> quoteIdOptional.value,
         tradeIdOptional              |-> tradeIdOptional.value,
         contraBroker                 |-> contraBroker.value,
         transactTime                 |-> transactTime.value,
         enteringTrader               |-> enteringTrader.value,
         settlTypeOptional            |-> settlTypeOptional.value,
         price8Optional               |-> price8Optional.value,
         orderQtyOptional             |-> orderQtyOptional.value,
         senderLocation               |-> senderLocation.value,
         executingTrader              |-> executingTrader.value,
         fixedRatePercentage8Optional |-> fixedRatePercentage8Optional.value,
         daysToSettlementOptional     |-> daysToSettlementOptional.value,
         sidesGroups                  |-> sidesGroups.value,
         deskId                       |-> deskId.value,
         memo                         |-> memo.value,
         text                         |-> text.value ], text.rest)

ZeroQuoteRequestRejectMessage ==
    [ bidirectionalBusinessHeader  |-> ZeroBidirectionalBusinessHeader5,
      quoteRequestRejectReason     |-> [i \in 1 .. 4 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      quoteReqId                   |-> [i \in 1 .. 8 |-> 0],
      quoteIdOptional              |-> [i \in 1 .. 8 |-> 0],
      tradeIdOptional              |-> [i \in 1 .. 4 |-> 0],
      contraBroker                 |-> [i \in 1 .. 4 |-> 0],
      transactTime                 |-> [i \in 1 .. 8 |-> 0],
      enteringTrader               |-> [i \in 1 .. 5 |-> 0],
      settlTypeOptional            |-> [i \in 1 .. 1 |-> 0],
      price8Optional               |-> [i \in 1 .. 8 |-> 0],
      orderQtyOptional             |-> [i \in 1 .. 8 |-> 0],
      senderLocation               |-> [i \in 1 .. 10 |-> 0],
      executingTrader              |-> [i \in 1 .. 5 |-> 0],
      fixedRatePercentage8Optional |-> [i \in 1 .. 8 |-> 0],
      daysToSettlementOptional     |-> [i \in 1 .. 2 |-> 0],
      sidesGroups                  |-> ZeroSidesGroups2,
      deskId                       |-> ZeroDeskId15,
      memo                         |-> ZeroMemo18,
      text                         |-> ZeroText4 ]

(* Quote Request Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestRejectMessage ==
    { ZeroQuoteRequestRejectMessage }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.bidirectionalBusinessHeader = one] : one \in CheckedBidirectionalBusinessHeader5 }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.quoteRequestRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.quoteIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.tradeIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.settlTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.price8Optional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.orderQtyOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.executingTrader = one] : one \in Sample(5) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.fixedRatePercentage8Optional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.daysToSettlementOptional = one] : one \in Sample(2) }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.sidesGroups = one] : one \in CheckedSidesGroups2 }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.deskId = one] : one \in CheckedDeskId15 }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.memo = one] : one \in CheckedMemo18 }
        \cup { [ZeroQuoteRequestRejectMessage EXCEPT !.text = one] : one \in CheckedText4 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader8 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader8(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader8(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader8 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader8 ==
    { ZeroInboundBusinessHeader8 }
        \cup { [ZeroInboundBusinessHeader8 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader8 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader8 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Position Maintenance Cancel Request Message: 65 bytes                   *)
(***************************************************************************)

PositionMaintenanceCancelRequestMessage ==
    [ inboundBusinessHeader : InboundBusinessHeader8,
      posReqId              : Sample(8),
      securityId            : Sample(8),
      origPosReqRefId       : Sample(8),
      posMaintRptRefId      : Sample(8),
      senderLocation        : Sample(10),
      enteringTrader        : Sample(5) ]

EncodePositionMaintenanceCancelRequestMessage(message) ==
    EncodeInboundBusinessHeader8(message.inboundBusinessHeader)
        \o message.posReqId
        \o message.securityId
        \o message.origPosReqRefId
        \o message.posMaintRptRefId
        \o message.senderLocation
        \o message.enteringTrader

DecodePositionMaintenanceCancelRequestMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader8(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET posReqId == ReadBytes(inboundBusinessHeader.rest, 8) IN IF ~posReqId.ok THEN Fail ELSE
    LET securityId == ReadBytes(posReqId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET origPosReqRefId == ReadBytes(securityId.rest, 8) IN IF ~origPosReqRefId.ok THEN Fail ELSE
    LET posMaintRptRefId == ReadBytes(origPosReqRefId.rest, 8) IN IF ~posMaintRptRefId.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(posMaintRptRefId.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader |-> inboundBusinessHeader.value,
         posReqId              |-> posReqId.value,
         securityId            |-> securityId.value,
         origPosReqRefId       |-> origPosReqRefId.value,
         posMaintRptRefId      |-> posMaintRptRefId.value,
         senderLocation        |-> senderLocation.value,
         enteringTrader        |-> enteringTrader.value ], enteringTrader.rest)

ZeroPositionMaintenanceCancelRequestMessage ==
    [ inboundBusinessHeader |-> ZeroInboundBusinessHeader8,
      posReqId              |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      origPosReqRefId       |-> [i \in 1 .. 8 |-> 0],
      posMaintRptRefId      |-> [i \in 1 .. 8 |-> 0],
      senderLocation        |-> [i \in 1 .. 10 |-> 0],
      enteringTrader        |-> [i \in 1 .. 5 |-> 0] ]

(* Position Maintenance Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedPositionMaintenanceCancelRequestMessage ==
    { ZeroPositionMaintenanceCancelRequestMessage }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader8 }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.posReqId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.origPosReqRefId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.posMaintRptRefId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroPositionMaintenanceCancelRequestMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader9 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader9(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader9(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader9 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader9 ==
    { ZeroInboundBusinessHeader9 }
        \cup { [ZeroInboundBusinessHeader9 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader9 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader9 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId16 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId16(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId16(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId16 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId16 ==
    { ZeroDeskId16 }
        \cup { [ZeroDeskId16 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo19 ==
    [ memoData : SampleBytes ]

EncodeMemo19(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo19(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo19 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo19 ==
    { ZeroMemo19 }
        \cup { [ZeroMemo19 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Position Maintenance Request Message                                    *)
(***************************************************************************)

PositionMaintenanceRequestMessage ==
    [ inboundBusinessHeader        : InboundBusinessHeader9,
      posReqId                     : Sample(8),
      securityId                   : Sample(8),
      thresholdAmount              : Sample(8),
      account                      : Sample(4),
      senderLocation               : Sample(10),
      posTransType                 : Sample(1),
      clearingBusinessDate         : Sample(2),
      contraryInstructionIndicator : Sample(1),
      enteringTrader               : Sample(5),
      longQty                      : Sample(8),
      deskId                       : DeskId16,
      memo                         : Memo19 ]

EncodePositionMaintenanceRequestMessage(message) ==
    EncodeInboundBusinessHeader9(message.inboundBusinessHeader)
        \o message.posReqId
        \o message.securityId
        \o message.thresholdAmount
        \o message.account
        \o message.senderLocation
        \o message.posTransType
        \o message.clearingBusinessDate
        \o message.contraryInstructionIndicator
        \o message.enteringTrader
        \o message.longQty
        \o EncodeDeskId16(message.deskId)
        \o EncodeMemo19(message.memo)

DecodePositionMaintenanceRequestMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader9(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET posReqId == ReadBytes(inboundBusinessHeader.rest, 8) IN IF ~posReqId.ok THEN Fail ELSE
    LET securityId == ReadBytes(posReqId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET thresholdAmount == ReadBytes(securityId.rest, 8) IN IF ~thresholdAmount.ok THEN Fail ELSE
    LET account == ReadBytes(thresholdAmount.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET posTransType == ReadBytes(senderLocation.rest, 1) IN IF ~posTransType.ok THEN Fail ELSE
    LET clearingBusinessDate == ReadBytes(posTransType.rest, 2) IN IF ~clearingBusinessDate.ok THEN Fail ELSE
    LET contraryInstructionIndicator == ReadBytes(clearingBusinessDate.rest, 1) IN IF ~contraryInstructionIndicator.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(contraryInstructionIndicator.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET longQty == ReadBytes(enteringTrader.rest, 8) IN IF ~longQty.ok THEN Fail ELSE
    LET deskId == DecodeDeskId16(longQty.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo19(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader        |-> inboundBusinessHeader.value,
         posReqId                     |-> posReqId.value,
         securityId                   |-> securityId.value,
         thresholdAmount              |-> thresholdAmount.value,
         account                      |-> account.value,
         senderLocation               |-> senderLocation.value,
         posTransType                 |-> posTransType.value,
         clearingBusinessDate         |-> clearingBusinessDate.value,
         contraryInstructionIndicator |-> contraryInstructionIndicator.value,
         enteringTrader               |-> enteringTrader.value,
         longQty                      |-> longQty.value,
         deskId                       |-> deskId.value,
         memo                         |-> memo.value ], memo.rest)

ZeroPositionMaintenanceRequestMessage ==
    [ inboundBusinessHeader        |-> ZeroInboundBusinessHeader9,
      posReqId                     |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      thresholdAmount              |-> [i \in 1 .. 8 |-> 0],
      account                      |-> [i \in 1 .. 4 |-> 0],
      senderLocation               |-> [i \in 1 .. 10 |-> 0],
      posTransType                 |-> [i \in 1 .. 1 |-> 0],
      clearingBusinessDate         |-> [i \in 1 .. 2 |-> 0],
      contraryInstructionIndicator |-> [i \in 1 .. 1 |-> 0],
      enteringTrader               |-> [i \in 1 .. 5 |-> 0],
      longQty                      |-> [i \in 1 .. 8 |-> 0],
      deskId                       |-> ZeroDeskId16,
      memo                         |-> ZeroMemo19 ]

(* Position Maintenance Request Message at zero, then each field in turn at the values it is checked at *)
CheckedPositionMaintenanceRequestMessage ==
    { ZeroPositionMaintenanceRequestMessage }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader9 }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.posReqId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.thresholdAmount = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.posTransType = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.clearingBusinessDate = one] : one \in Sample(2) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.contraryInstructionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.longQty = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.deskId = one] : one \in CheckedDeskId16 }
        \cup { [ZeroPositionMaintenanceRequestMessage EXCEPT !.memo = one] : one \in CheckedMemo19 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader9 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader9(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader9(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader9 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader9 ==
    { ZeroOutboundBusinessHeader9 }
        \cup { [ZeroOutboundBusinessHeader9 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader9 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader9 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Positions Group: 17 bytes                                               *)
(***************************************************************************)

PositionsGroup ==
    [ posType         : Sample(1),
      longQtyOptional : Sample(8),
      shortQty        : Sample(8) ]

EncodePositionsGroup(message) ==
    message.posType
        \o message.longQtyOptional
        \o message.shortQty

DecodePositionsGroup(bytes) ==
    LET posType == ReadBytes(bytes, 1) IN IF ~posType.ok THEN Fail ELSE
    LET longQtyOptional == ReadBytes(posType.rest, 8) IN IF ~longQtyOptional.ok THEN Fail ELSE
    LET shortQty == ReadBytes(longQtyOptional.rest, 8) IN IF ~shortQty.ok THEN Fail ELSE
    Ok([ posType         |-> posType.value,
         longQtyOptional |-> longQtyOptional.value,
         shortQty        |-> shortQty.value ], shortQty.rest)

ZeroPositionsGroup ==
    [ posType         |-> [i \in 1 .. 1 |-> 0],
      longQtyOptional |-> [i \in 1 .. 8 |-> 0],
      shortQty        |-> [i \in 1 .. 8 |-> 0] ]

(* Positions Group at zero, then each field in turn at the values it is checked at *)
CheckedPositionsGroup ==
    { ZeroPositionsGroup }
        \cup { [ZeroPositionsGroup EXCEPT !.posType = one] : one \in Sample(1) }
        \cup { [ZeroPositionsGroup EXCEPT !.longQtyOptional = one] : one \in Sample(8) }
        \cup { [ZeroPositionsGroup EXCEPT !.shortQty = one] : one \in Sample(8) }

(* A run of Positions Group, written one after another *)
RECURSIVE EncodePositionsGroupList(_)
EncodePositionsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePositionsGroup(Head(messages)) \o EncodePositionsGroupList(Tail(messages))

(* As many Positions Group as the field that counts them says *)
RECURSIVE ReadPositionsGroupList(_, _)
ReadPositionsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePositionsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPositionsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Positions Group of each kind, for the lists that carry them *)
OnePositionsGroup == { ZeroPositionsGroup }

(***************************************************************************)
(* Positions Groups                                                        *)
(***************************************************************************)

PositionsGroups ==
    [ blockLength    : Sample(2),
      positionsGroup : SampleLists(OnePositionsGroup) ]

EncodePositionsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.positionsGroup), 1)
        \o EncodePositionsGroupList(message.positionsGroup)

DecodePositionsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET positionsGroup == ReadPositionsGroupList(numInGroup.rest, numInGroup.value) IN IF ~positionsGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         positionsGroup |-> positionsGroup.value ], positionsGroup.rest)

ZeroPositionsGroups ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      positionsGroup |-> << >> ]

(* Positions Groups at zero, then each field in turn at the values it is checked at *)
CheckedPositionsGroups ==
    { ZeroPositionsGroups }
        \cup { [ZeroPositionsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPositionsGroups EXCEPT !.positionsGroup = one] : one \in SampleLists(OnePositionsGroup) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId17 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId17(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId17(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId17 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId17 ==
    { ZeroDeskId17 }
        \cup { [ZeroDeskId17 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo20 ==
    [ memoData : SampleBytes ]

EncodeMemo20(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo20(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo20 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo20 ==
    { ZeroMemo20 }
        \cup { [ZeroMemo20 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text5 ==
    [ textData : SampleBytes ]

EncodeText5(message) ==
    EncodeUIntBE(Len(message.textData), 1)
        \o message.textData

DecodeText5(bytes) ==
    LET textLength == ReadUIntBE(bytes, 1) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText5 ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText5 ==
    { ZeroText5 }
        \cup { [ZeroText5 EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Position Maintenance Report Message                                     *)
(***************************************************************************)

PositionMaintenanceReportMessage ==
    [ outboundBusinessHeader       : OutboundBusinessHeader9,
      posReqIdOptional             : Sample(8),
      securityId                   : Sample(8),
      posMaintRptId                : Sample(8),
      posTransType                 : Sample(1),
      posMaintAction               : Sample(1),
      posMaintStatus               : Sample(1),
      tradeIdOptional              : Sample(4),
      origPosReqRefId              : Sample(8),
      accountType                  : Sample(1),
      clearingBusinessDate         : Sample(2),
      thresholdAmount              : Sample(8),
      transactTime                 : Sample(8),
      account                      : Sample(4),
      senderLocation               : Sample(10),
      posMaintResult               : Sample(4),
      contraryInstructionIndicator : Sample(1),
      positionsGroups              : PositionsGroups,
      deskId                       : DeskId17,
      memo                         : Memo20,
      text                         : Text5 ]

EncodePositionMaintenanceReportMessage(message) ==
    EncodeOutboundBusinessHeader9(message.outboundBusinessHeader)
        \o message.posReqIdOptional
        \o message.securityId
        \o message.posMaintRptId
        \o message.posTransType
        \o message.posMaintAction
        \o message.posMaintStatus
        \o message.tradeIdOptional
        \o message.origPosReqRefId
        \o message.accountType
        \o message.clearingBusinessDate
        \o message.thresholdAmount
        \o message.transactTime
        \o message.account
        \o message.senderLocation
        \o message.posMaintResult
        \o message.contraryInstructionIndicator
        \o EncodePositionsGroups(message.positionsGroups)
        \o EncodeDeskId17(message.deskId)
        \o EncodeMemo20(message.memo)
        \o EncodeText5(message.text)

DecodePositionMaintenanceReportMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader9(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET posReqIdOptional == ReadBytes(outboundBusinessHeader.rest, 8) IN IF ~posReqIdOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(posReqIdOptional.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET posMaintRptId == ReadBytes(securityId.rest, 8) IN IF ~posMaintRptId.ok THEN Fail ELSE
    LET posTransType == ReadBytes(posMaintRptId.rest, 1) IN IF ~posTransType.ok THEN Fail ELSE
    LET posMaintAction == ReadBytes(posTransType.rest, 1) IN IF ~posMaintAction.ok THEN Fail ELSE
    LET posMaintStatus == ReadBytes(posMaintAction.rest, 1) IN IF ~posMaintStatus.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(posMaintStatus.rest, 4) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET origPosReqRefId == ReadBytes(tradeIdOptional.rest, 8) IN IF ~origPosReqRefId.ok THEN Fail ELSE
    LET accountType == ReadBytes(origPosReqRefId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET clearingBusinessDate == ReadBytes(accountType.rest, 2) IN IF ~clearingBusinessDate.ok THEN Fail ELSE
    LET thresholdAmount == ReadBytes(clearingBusinessDate.rest, 8) IN IF ~thresholdAmount.ok THEN Fail ELSE
    LET transactTime == ReadBytes(thresholdAmount.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET account == ReadBytes(transactTime.rest, 4) IN IF ~account.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(account.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET posMaintResult == ReadBytes(senderLocation.rest, 4) IN IF ~posMaintResult.ok THEN Fail ELSE
    LET contraryInstructionIndicator == ReadBytes(posMaintResult.rest, 1) IN IF ~contraryInstructionIndicator.ok THEN Fail ELSE
    LET positionsGroups == DecodePositionsGroups(contraryInstructionIndicator.rest) IN IF ~positionsGroups.ok THEN Fail ELSE
    LET deskId == DecodeDeskId17(positionsGroups.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo20(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    LET text == DecodeText5(memo.rest) IN IF ~text.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader       |-> outboundBusinessHeader.value,
         posReqIdOptional             |-> posReqIdOptional.value,
         securityId                   |-> securityId.value,
         posMaintRptId                |-> posMaintRptId.value,
         posTransType                 |-> posTransType.value,
         posMaintAction               |-> posMaintAction.value,
         posMaintStatus               |-> posMaintStatus.value,
         tradeIdOptional              |-> tradeIdOptional.value,
         origPosReqRefId              |-> origPosReqRefId.value,
         accountType                  |-> accountType.value,
         clearingBusinessDate         |-> clearingBusinessDate.value,
         thresholdAmount              |-> thresholdAmount.value,
         transactTime                 |-> transactTime.value,
         account                      |-> account.value,
         senderLocation               |-> senderLocation.value,
         posMaintResult               |-> posMaintResult.value,
         contraryInstructionIndicator |-> contraryInstructionIndicator.value,
         positionsGroups              |-> positionsGroups.value,
         deskId                       |-> deskId.value,
         memo                         |-> memo.value,
         text                         |-> text.value ], text.rest)

ZeroPositionMaintenanceReportMessage ==
    [ outboundBusinessHeader       |-> ZeroOutboundBusinessHeader9,
      posReqIdOptional             |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      posMaintRptId                |-> [i \in 1 .. 8 |-> 0],
      posTransType                 |-> [i \in 1 .. 1 |-> 0],
      posMaintAction               |-> [i \in 1 .. 1 |-> 0],
      posMaintStatus               |-> [i \in 1 .. 1 |-> 0],
      tradeIdOptional              |-> [i \in 1 .. 4 |-> 0],
      origPosReqRefId              |-> [i \in 1 .. 8 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      clearingBusinessDate         |-> [i \in 1 .. 2 |-> 0],
      thresholdAmount              |-> [i \in 1 .. 8 |-> 0],
      transactTime                 |-> [i \in 1 .. 8 |-> 0],
      account                      |-> [i \in 1 .. 4 |-> 0],
      senderLocation               |-> [i \in 1 .. 10 |-> 0],
      posMaintResult               |-> [i \in 1 .. 4 |-> 0],
      contraryInstructionIndicator |-> [i \in 1 .. 1 |-> 0],
      positionsGroups              |-> ZeroPositionsGroups,
      deskId                       |-> ZeroDeskId17,
      memo                         |-> ZeroMemo20,
      text                         |-> ZeroText5 ]

(* Position Maintenance Report Message at zero, then each field in turn at the values it is checked at *)
CheckedPositionMaintenanceReportMessage ==
    { ZeroPositionMaintenanceReportMessage }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader9 }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.posReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.posMaintRptId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.posTransType = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.posMaintAction = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.posMaintStatus = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.tradeIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.origPosReqRefId = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.clearingBusinessDate = one] : one \in Sample(2) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.thresholdAmount = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.account = one] : one \in Sample(4) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.posMaintResult = one] : one \in Sample(4) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.contraryInstructionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.positionsGroups = one] : one \in CheckedPositionsGroups }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.deskId = one] : one \in CheckedDeskId17 }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.memo = one] : one \in CheckedMemo20 }
        \cup { [ZeroPositionMaintenanceReportMessage EXCEPT !.text = one] : one \in CheckedText5 }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader10 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader10(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader10(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader10 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader10 ==
    { ZeroInboundBusinessHeader10 }
        \cup { [ZeroInboundBusinessHeader10 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader10 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader10 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Desk Id                                                                 *)
(***************************************************************************)

DeskId18 ==
    [ deskIdData : SampleBytes ]

EncodeDeskId18(message) ==
    EncodeUIntBE(Len(message.deskIdData), 1)
        \o message.deskIdData

DecodeDeskId18(bytes) ==
    LET deskIdLength == ReadUIntBE(bytes, 1) IN IF ~deskIdLength.ok THEN Fail ELSE
    LET deskIdData == ReadBytes(deskIdLength.rest, deskIdLength.value) IN IF ~deskIdData.ok THEN Fail ELSE
    Ok([ deskIdData |-> deskIdData.value ], deskIdData.rest)

ZeroDeskId18 ==
    [ deskIdData |-> << >> ]

(* Desk Id at zero, then each field in turn at the values it is checked at *)
CheckedDeskId18 ==
    { ZeroDeskId18 }
        \cup { [ZeroDeskId18 EXCEPT !.deskIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Memo                                                                    *)
(***************************************************************************)

Memo21 ==
    [ memoData : SampleBytes ]

EncodeMemo21(message) ==
    EncodeUIntBE(Len(message.memoData), 1)
        \o message.memoData

DecodeMemo21(bytes) ==
    LET memoLength == ReadUIntBE(bytes, 1) IN IF ~memoLength.ok THEN Fail ELSE
    LET memoData == ReadBytes(memoLength.rest, memoLength.value) IN IF ~memoData.ok THEN Fail ELSE
    Ok([ memoData |-> memoData.value ], memoData.rest)

ZeroMemo21 ==
    [ memoData |-> << >> ]

(* Memo at zero, then each field in turn at the values it is checked at *)
CheckedMemo21 ==
    { ZeroMemo21 }
        \cup { [ZeroMemo21 EXCEPT !.memoData = one] : one \in SampleBytes }

(***************************************************************************)
(* Allocation Instruction Message                                          *)
(***************************************************************************)

AllocationInstructionMessage ==
    [ inboundBusinessHeader : InboundBusinessHeader10,
      allocId               : Sample(8),
      securityId            : Sample(8),
      allocTransType        : Sample(1),
      allocType             : Sample(1),
      allocNoOrdersType     : Sample(1),
      quantity              : Sample(8),
      senderLocation        : Sample(10),
      enteringTrader        : Sample(5),
      tradeId               : Sample(4),
      tradeDateOptional     : Sample(2),
      individualAllocId     : Sample(8),
      allocAccount          : Sample(4),
      allocQty              : Sample(8),
      deskId                : DeskId18,
      memo                  : Memo21 ]

EncodeAllocationInstructionMessage(message) ==
    EncodeInboundBusinessHeader10(message.inboundBusinessHeader)
        \o message.allocId
        \o message.securityId
        \o message.allocTransType
        \o message.allocType
        \o message.allocNoOrdersType
        \o message.quantity
        \o message.senderLocation
        \o message.enteringTrader
        \o message.tradeId
        \o message.tradeDateOptional
        \o message.individualAllocId
        \o message.allocAccount
        \o message.allocQty
        \o EncodeDeskId18(message.deskId)
        \o EncodeMemo21(message.memo)

DecodeAllocationInstructionMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader10(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET allocId == ReadBytes(inboundBusinessHeader.rest, 8) IN IF ~allocId.ok THEN Fail ELSE
    LET securityId == ReadBytes(allocId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET allocTransType == ReadBytes(securityId.rest, 1) IN IF ~allocTransType.ok THEN Fail ELSE
    LET allocType == ReadBytes(allocTransType.rest, 1) IN IF ~allocType.ok THEN Fail ELSE
    LET allocNoOrdersType == ReadBytes(allocType.rest, 1) IN IF ~allocNoOrdersType.ok THEN Fail ELSE
    LET quantity == ReadBytes(allocNoOrdersType.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(quantity.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    LET tradeId == ReadBytes(enteringTrader.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeDateOptional == ReadBytes(tradeId.rest, 2) IN IF ~tradeDateOptional.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(tradeDateOptional.rest, 8) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET allocAccount == ReadBytes(individualAllocId.rest, 4) IN IF ~allocAccount.ok THEN Fail ELSE
    LET allocQty == ReadBytes(allocAccount.rest, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET deskId == DecodeDeskId18(allocQty.rest) IN IF ~deskId.ok THEN Fail ELSE
    LET memo == DecodeMemo21(deskId.rest) IN IF ~memo.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader |-> inboundBusinessHeader.value,
         allocId               |-> allocId.value,
         securityId            |-> securityId.value,
         allocTransType        |-> allocTransType.value,
         allocType             |-> allocType.value,
         allocNoOrdersType     |-> allocNoOrdersType.value,
         quantity              |-> quantity.value,
         senderLocation        |-> senderLocation.value,
         enteringTrader        |-> enteringTrader.value,
         tradeId               |-> tradeId.value,
         tradeDateOptional     |-> tradeDateOptional.value,
         individualAllocId     |-> individualAllocId.value,
         allocAccount          |-> allocAccount.value,
         allocQty              |-> allocQty.value,
         deskId                |-> deskId.value,
         memo                  |-> memo.value ], memo.rest)

ZeroAllocationInstructionMessage ==
    [ inboundBusinessHeader |-> ZeroInboundBusinessHeader10,
      allocId               |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      allocTransType        |-> [i \in 1 .. 1 |-> 0],
      allocType             |-> [i \in 1 .. 1 |-> 0],
      allocNoOrdersType     |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 8 |-> 0],
      senderLocation        |-> [i \in 1 .. 10 |-> 0],
      enteringTrader        |-> [i \in 1 .. 5 |-> 0],
      tradeId               |-> [i \in 1 .. 4 |-> 0],
      tradeDateOptional     |-> [i \in 1 .. 2 |-> 0],
      individualAllocId     |-> [i \in 1 .. 8 |-> 0],
      allocAccount          |-> [i \in 1 .. 4 |-> 0],
      allocQty              |-> [i \in 1 .. 8 |-> 0],
      deskId                |-> ZeroDeskId18,
      memo                  |-> ZeroMemo21 ]

(* Allocation Instruction Message at zero, then each field in turn at the values it is checked at *)
CheckedAllocationInstructionMessage ==
    { ZeroAllocationInstructionMessage }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader10 }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocTransType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocNoOrdersType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.tradeDateOptional = one] : one \in Sample(2) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.individualAllocId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocAccount = one] : one \in Sample(4) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.deskId = one] : one \in CheckedDeskId18 }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.memo = one] : one \in CheckedMemo21 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader10 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader10(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader10(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader10 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader10 ==
    { ZeroOutboundBusinessHeader10 }
        \cup { [ZeroOutboundBusinessHeader10 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader10 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader10 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Allocation Report Message: 84 bytes                                     *)
(***************************************************************************)

AllocationReportMessage ==
    [ outboundBusinessHeader : OutboundBusinessHeader10,
      allocId                : Sample(8),
      securityId             : Sample(8),
      allocReportId          : Sample(8),
      allocTransType         : Sample(1),
      allocReportType        : Sample(1),
      allocNoOrdersType      : Sample(1),
      allocRejCode           : Sample(4),
      quantity               : Sample(8),
      allocStatus            : Sample(1),
      tradeDateOptional      : Sample(2),
      transactTime           : Sample(8),
      side                   : Sample(1),
      senderLocation         : Sample(10),
      enteringTrader         : Sample(5) ]

EncodeAllocationReportMessage(message) ==
    EncodeOutboundBusinessHeader10(message.outboundBusinessHeader)
        \o message.allocId
        \o message.securityId
        \o message.allocReportId
        \o message.allocTransType
        \o message.allocReportType
        \o message.allocNoOrdersType
        \o message.allocRejCode
        \o message.quantity
        \o message.allocStatus
        \o message.tradeDateOptional
        \o message.transactTime
        \o message.side
        \o message.senderLocation
        \o message.enteringTrader

DecodeAllocationReportMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader10(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET allocId == ReadBytes(outboundBusinessHeader.rest, 8) IN IF ~allocId.ok THEN Fail ELSE
    LET securityId == ReadBytes(allocId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET allocReportId == ReadBytes(securityId.rest, 8) IN IF ~allocReportId.ok THEN Fail ELSE
    LET allocTransType == ReadBytes(allocReportId.rest, 1) IN IF ~allocTransType.ok THEN Fail ELSE
    LET allocReportType == ReadBytes(allocTransType.rest, 1) IN IF ~allocReportType.ok THEN Fail ELSE
    LET allocNoOrdersType == ReadBytes(allocReportType.rest, 1) IN IF ~allocNoOrdersType.ok THEN Fail ELSE
    LET allocRejCode == ReadBytes(allocNoOrdersType.rest, 4) IN IF ~allocRejCode.ok THEN Fail ELSE
    LET quantity == ReadBytes(allocRejCode.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET allocStatus == ReadBytes(quantity.rest, 1) IN IF ~allocStatus.ok THEN Fail ELSE
    LET tradeDateOptional == ReadBytes(allocStatus.rest, 2) IN IF ~tradeDateOptional.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradeDateOptional.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET side == ReadBytes(transactTime.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET senderLocation == ReadBytes(side.rest, 10) IN IF ~senderLocation.ok THEN Fail ELSE
    LET enteringTrader == ReadBytes(senderLocation.rest, 5) IN IF ~enteringTrader.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader |-> outboundBusinessHeader.value,
         allocId                |-> allocId.value,
         securityId             |-> securityId.value,
         allocReportId          |-> allocReportId.value,
         allocTransType         |-> allocTransType.value,
         allocReportType        |-> allocReportType.value,
         allocNoOrdersType      |-> allocNoOrdersType.value,
         allocRejCode           |-> allocRejCode.value,
         quantity               |-> quantity.value,
         allocStatus            |-> allocStatus.value,
         tradeDateOptional      |-> tradeDateOptional.value,
         transactTime           |-> transactTime.value,
         side                   |-> side.value,
         senderLocation         |-> senderLocation.value,
         enteringTrader         |-> enteringTrader.value ], enteringTrader.rest)

ZeroAllocationReportMessage ==
    [ outboundBusinessHeader |-> ZeroOutboundBusinessHeader10,
      allocId                |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      allocReportId          |-> [i \in 1 .. 8 |-> 0],
      allocTransType         |-> [i \in 1 .. 1 |-> 0],
      allocReportType        |-> [i \in 1 .. 1 |-> 0],
      allocNoOrdersType      |-> [i \in 1 .. 1 |-> 0],
      allocRejCode           |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      allocStatus            |-> [i \in 1 .. 1 |-> 0],
      tradeDateOptional      |-> [i \in 1 .. 2 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      senderLocation         |-> [i \in 1 .. 10 |-> 0],
      enteringTrader         |-> [i \in 1 .. 5 |-> 0] ]

(* Allocation Report Message at zero, then each field in turn at the values it is checked at *)
CheckedAllocationReportMessage ==
    { ZeroAllocationReportMessage }
        \cup { [ZeroAllocationReportMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader10 }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocReportId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocTransType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocReportType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocNoOrdersType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocRejCode = one] : one \in Sample(4) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.allocStatus = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.tradeDateOptional = one] : one \in Sample(2) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.senderLocation = one] : one \in Sample(10) }
        \cup { [ZeroAllocationReportMessage EXCEPT !.enteringTrader = one] : one \in Sample(5) }

(***************************************************************************)
(* Inbound Business Header: 18 bytes                                       *)
(***************************************************************************)

InboundBusinessHeader11 ==
    [ sessionId       : Sample(4),
      msgSeqNum       : Sample(4),
      sendingTime     : Sample(8),
      marketSegmentId : Sample(1),
      padding         : Sample(1) ]

EncodeInboundBusinessHeader11(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.marketSegmentId
        \o message.padding

DecodeInboundBusinessHeader11(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sendingTime.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET padding == ReadBytes(marketSegmentId.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         msgSeqNum       |-> msgSeqNum.value,
         sendingTime     |-> sendingTime.value,
         marketSegmentId |-> marketSegmentId.value,
         padding         |-> padding.value ], padding.rest)

ZeroInboundBusinessHeader11 ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 1 |-> 0],
      padding         |-> [i \in 1 .. 1 |-> 0] ]

(* Inbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedInboundBusinessHeader11 ==
    { ZeroInboundBusinessHeader11 }
        \cup { [ZeroInboundBusinessHeader11 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInboundBusinessHeader11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroInboundBusinessHeader11 EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroInboundBusinessHeader11 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId9 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId9(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId9(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId9 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId9 ==
    { ZeroInvestorId9 }
        \cup { [ZeroInvestorId9 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId9 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId9 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mass Action Request Message: 54 bytes                             *)
(***************************************************************************)

OrderMassActionRequestMessage ==
    [ inboundBusinessHeader       : InboundBusinessHeader11,
      massActionType              : Sample(1),
      massActionScope             : Sample(1),
      clordid                     : Sample(8),
      massCancelRestatementReason : Sample(1),
      ordtagid                    : Sample(1),
      sideOptional                : Sample(1),
      offset31Padding1            : Sample(1),
      asset                       : Sample(6),
      securityIdOptional          : Sample(8),
      investorId                  : InvestorId9 ]

EncodeOrderMassActionRequestMessage(message) ==
    EncodeInboundBusinessHeader11(message.inboundBusinessHeader)
        \o message.massActionType
        \o message.massActionScope
        \o message.clordid
        \o message.massCancelRestatementReason
        \o message.ordtagid
        \o message.sideOptional
        \o message.offset31Padding1
        \o message.asset
        \o message.securityIdOptional
        \o EncodeInvestorId9(message.investorId)

DecodeOrderMassActionRequestMessage(bytes) ==
    LET inboundBusinessHeader == DecodeInboundBusinessHeader11(bytes) IN IF ~inboundBusinessHeader.ok THEN Fail ELSE
    LET massActionType == ReadBytes(inboundBusinessHeader.rest, 1) IN IF ~massActionType.ok THEN Fail ELSE
    LET massActionScope == ReadBytes(massActionType.rest, 1) IN IF ~massActionScope.ok THEN Fail ELSE
    LET clordid == ReadBytes(massActionScope.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET massCancelRestatementReason == ReadBytes(clordid.rest, 1) IN IF ~massCancelRestatementReason.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(massCancelRestatementReason.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(ordtagid.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET offset31Padding1 == ReadBytes(sideOptional.rest, 1) IN IF ~offset31Padding1.ok THEN Fail ELSE
    LET asset == ReadBytes(offset31Padding1.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(asset.rest, 8) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId9(securityIdOptional.rest) IN IF ~investorId.ok THEN Fail ELSE
    Ok([ inboundBusinessHeader       |-> inboundBusinessHeader.value,
         massActionType              |-> massActionType.value,
         massActionScope             |-> massActionScope.value,
         clordid                     |-> clordid.value,
         massCancelRestatementReason |-> massCancelRestatementReason.value,
         ordtagid                    |-> ordtagid.value,
         sideOptional                |-> sideOptional.value,
         offset31Padding1            |-> offset31Padding1.value,
         asset                       |-> asset.value,
         securityIdOptional          |-> securityIdOptional.value,
         investorId                  |-> investorId.value ], investorId.rest)

ZeroOrderMassActionRequestMessage ==
    [ inboundBusinessHeader       |-> ZeroInboundBusinessHeader11,
      massActionType              |-> [i \in 1 .. 1 |-> 0],
      massActionScope             |-> [i \in 1 .. 1 |-> 0],
      clordid                     |-> [i \in 1 .. 8 |-> 0],
      massCancelRestatementReason |-> [i \in 1 .. 1 |-> 0],
      ordtagid                    |-> [i \in 1 .. 1 |-> 0],
      sideOptional                |-> [i \in 1 .. 1 |-> 0],
      offset31Padding1            |-> [i \in 1 .. 1 |-> 0],
      asset                       |-> [i \in 1 .. 6 |-> 0],
      securityIdOptional          |-> [i \in 1 .. 8 |-> 0],
      investorId                  |-> ZeroInvestorId9 ]

(* Order Mass Action Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassActionRequestMessage ==
    { ZeroOrderMassActionRequestMessage }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.inboundBusinessHeader = one] : one \in CheckedInboundBusinessHeader11 }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.massActionScope = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.massCancelRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.offset31Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.securityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionRequestMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId9 }

(***************************************************************************)
(* Outbound Business Header: 18 bytes                                      *)
(***************************************************************************)

OutboundBusinessHeader11 ==
    [ sessionId   : Sample(4),
      msgSeqNum   : Sample(4),
      sendingTime : Sample(8),
      possResend  : Sample(1),
      padding     : Sample(1) ]

EncodeOutboundBusinessHeader11(message) ==
    message.sessionId
        \o message.msgSeqNum
        \o message.sendingTime
        \o message.possResend
        \o message.padding

DecodeOutboundBusinessHeader11(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sessionId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET possResend == ReadBytes(sendingTime.rest, 1) IN IF ~possResend.ok THEN Fail ELSE
    LET padding == ReadBytes(possResend.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    Ok([ sessionId   |-> sessionId.value,
         msgSeqNum   |-> msgSeqNum.value,
         sendingTime |-> sendingTime.value,
         possResend  |-> possResend.value,
         padding     |-> padding.value ], padding.rest)

ZeroOutboundBusinessHeader11 ==
    [ sessionId   |-> [i \in 1 .. 4 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      possResend  |-> [i \in 1 .. 1 |-> 0],
      padding     |-> [i \in 1 .. 1 |-> 0] ]

(* Outbound Business Header at zero, then each field in turn at the values it is checked at *)
CheckedOutboundBusinessHeader11 ==
    { ZeroOutboundBusinessHeader11 }
        \cup { [ZeroOutboundBusinessHeader11 EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOutboundBusinessHeader11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOutboundBusinessHeader11 EXCEPT !.possResend = one] : one \in Sample(1) }
        \cup { [ZeroOutboundBusinessHeader11 EXCEPT !.padding = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Id: 8 bytes                                                    *)
(***************************************************************************)

InvestorId10 ==
    [ prefix          : Sample(2),
      offset2Padding2 : Sample(2),
      document        : Sample(4) ]

EncodeInvestorId10(message) ==
    message.prefix
        \o message.offset2Padding2
        \o message.document

DecodeInvestorId10(bytes) ==
    LET prefix == ReadBytes(bytes, 2) IN IF ~prefix.ok THEN Fail ELSE
    LET offset2Padding2 == ReadBytes(prefix.rest, 2) IN IF ~offset2Padding2.ok THEN Fail ELSE
    LET document == ReadBytes(offset2Padding2.rest, 4) IN IF ~document.ok THEN Fail ELSE
    Ok([ prefix          |-> prefix.value,
         offset2Padding2 |-> offset2Padding2.value,
         document        |-> document.value ], document.rest)

ZeroInvestorId10 ==
    [ prefix          |-> [i \in 1 .. 2 |-> 0],
      offset2Padding2 |-> [i \in 1 .. 2 |-> 0],
      document        |-> [i \in 1 .. 4 |-> 0] ]

(* Investor Id at zero, then each field in turn at the values it is checked at *)
CheckedInvestorId10 ==
    { ZeroInvestorId10 }
        \cup { [ZeroInvestorId10 EXCEPT !.prefix = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId10 EXCEPT !.offset2Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroInvestorId10 EXCEPT !.document = one] : one \in Sample(4) }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text6 ==
    [ textData : SampleBytes ]

EncodeText6(message) ==
    EncodeUIntBE(Len(message.textData), 1)
        \o message.textData

DecodeText6(bytes) ==
    LET textLength == ReadUIntBE(bytes, 1) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText6 ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText6 ==
    { ZeroText6 }
        \cup { [ZeroText6 EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Order Mass Action Report Message                                        *)
(***************************************************************************)

OrderMassActionReportMessage ==
    [ outboundBusinessHeader      : OutboundBusinessHeader11,
      massActionType              : Sample(1),
      massActionScope             : Sample(1),
      clordid                     : Sample(8),
      massActionReportId          : Sample(8),
      transactTime                : Sample(8),
      massActionResponse          : Sample(1),
      massActionRejectReason      : Sample(1),
      massCancelRestatementReason : Sample(1),
      ordtagid                    : Sample(1),
      sideOptional                : Sample(1),
      offset49Padding1            : Sample(1),
      asset                       : Sample(6),
      securityIdOptional          : Sample(8),
      investorId                  : InvestorId10,
      text                        : Text6 ]

EncodeOrderMassActionReportMessage(message) ==
    EncodeOutboundBusinessHeader11(message.outboundBusinessHeader)
        \o message.massActionType
        \o message.massActionScope
        \o message.clordid
        \o message.massActionReportId
        \o message.transactTime
        \o message.massActionResponse
        \o message.massActionRejectReason
        \o message.massCancelRestatementReason
        \o message.ordtagid
        \o message.sideOptional
        \o message.offset49Padding1
        \o message.asset
        \o message.securityIdOptional
        \o EncodeInvestorId10(message.investorId)
        \o EncodeText6(message.text)

DecodeOrderMassActionReportMessage(bytes) ==
    LET outboundBusinessHeader == DecodeOutboundBusinessHeader11(bytes) IN IF ~outboundBusinessHeader.ok THEN Fail ELSE
    LET massActionType == ReadBytes(outboundBusinessHeader.rest, 1) IN IF ~massActionType.ok THEN Fail ELSE
    LET massActionScope == ReadBytes(massActionType.rest, 1) IN IF ~massActionScope.ok THEN Fail ELSE
    LET clordid == ReadBytes(massActionScope.rest, 8) IN IF ~clordid.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(clordid.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(massActionReportId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET massActionResponse == ReadBytes(transactTime.rest, 1) IN IF ~massActionResponse.ok THEN Fail ELSE
    LET massActionRejectReason == ReadBytes(massActionResponse.rest, 1) IN IF ~massActionRejectReason.ok THEN Fail ELSE
    LET massCancelRestatementReason == ReadBytes(massActionRejectReason.rest, 1) IN IF ~massCancelRestatementReason.ok THEN Fail ELSE
    LET ordtagid == ReadBytes(massCancelRestatementReason.rest, 1) IN IF ~ordtagid.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(ordtagid.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET offset49Padding1 == ReadBytes(sideOptional.rest, 1) IN IF ~offset49Padding1.ok THEN Fail ELSE
    LET asset == ReadBytes(offset49Padding1.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(asset.rest, 8) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET investorId == DecodeInvestorId10(securityIdOptional.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET text == DecodeText6(investorId.rest) IN IF ~text.ok THEN Fail ELSE
    Ok([ outboundBusinessHeader      |-> outboundBusinessHeader.value,
         massActionType              |-> massActionType.value,
         massActionScope             |-> massActionScope.value,
         clordid                     |-> clordid.value,
         massActionReportId          |-> massActionReportId.value,
         transactTime                |-> transactTime.value,
         massActionResponse          |-> massActionResponse.value,
         massActionRejectReason      |-> massActionRejectReason.value,
         massCancelRestatementReason |-> massCancelRestatementReason.value,
         ordtagid                    |-> ordtagid.value,
         sideOptional                |-> sideOptional.value,
         offset49Padding1            |-> offset49Padding1.value,
         asset                       |-> asset.value,
         securityIdOptional          |-> securityIdOptional.value,
         investorId                  |-> investorId.value,
         text                        |-> text.value ], text.rest)

ZeroOrderMassActionReportMessage ==
    [ outboundBusinessHeader      |-> ZeroOutboundBusinessHeader11,
      massActionType              |-> [i \in 1 .. 1 |-> 0],
      massActionScope             |-> [i \in 1 .. 1 |-> 0],
      clordid                     |-> [i \in 1 .. 8 |-> 0],
      massActionReportId          |-> [i \in 1 .. 8 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      massActionResponse          |-> [i \in 1 .. 1 |-> 0],
      massActionRejectReason      |-> [i \in 1 .. 1 |-> 0],
      massCancelRestatementReason |-> [i \in 1 .. 1 |-> 0],
      ordtagid                    |-> [i \in 1 .. 1 |-> 0],
      sideOptional                |-> [i \in 1 .. 1 |-> 0],
      offset49Padding1            |-> [i \in 1 .. 1 |-> 0],
      asset                       |-> [i \in 1 .. 6 |-> 0],
      securityIdOptional          |-> [i \in 1 .. 8 |-> 0],
      investorId                  |-> ZeroInvestorId10,
      text                        |-> ZeroText6 ]

(* Order Mass Action Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassActionReportMessage ==
    { ZeroOrderMassActionReportMessage }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.outboundBusinessHeader = one] : one \in CheckedOutboundBusinessHeader11 }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.massActionScope = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.clordid = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.massActionResponse = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.massActionRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.massCancelRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.ordtagid = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.offset49Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.securityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.investorId = one] : one \in CheckedInvestorId10 }
        \cup { [ZeroOrderMassActionReportMessage EXCEPT !.text = one] : one \in CheckedText6 }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

NegotiateMessageCode == 1  \* 0x01
NegotiateResponseMessageCode == 2  \* 0x02
NegotiateRejectMessageCode == 3  \* 0x03
EstablishMessageCode == 4  \* 0x04
EstablishAckMessageCode == 5  \* 0x05
EstablishRejectMessageCode == 6  \* 0x06
TerminateMessageCode == 7  \* 0x07
NotAppliedMessageCode == 8  \* 0x08
SequenceMessageCode == 9  \* 0x09
RetransmitRequestMessageCode == 12  \* 0x0c
RetransmissionMessageCode == 13  \* 0x0d
RetransmitRejectMessageCode == 14  \* 0x0e
SimpleNewOrderMessageCode == 100  \* 0x64
SimpleModifyOrderMessageCode == 101  \* 0x65
NewOrderSingleMessageCode == 102  \* 0x66
OrderCancelReplaceRequestMessageCode == 104  \* 0x68
OrderCancelRequestMessageCode == 105  \* 0x69
NewOrderCrossMessageCode == 106  \* 0x6a
ExecutionReportNewMessageCode == 200  \* 0xc8
ExecutionReportModifyMessageCode == 201  \* 0xc9
ExecutionReportCancelMessageCode == 202  \* 0xca
ExecutionReportTradeMessageCode == 203  \* 0xcb
ExecutionReportRejectMessageCode == 204  \* 0xcc
ExecutionReportForwardMessageCode == 205  \* 0xcd
BusinessMessageRejectMessageCode == 206  \* 0xce
SecurityDefinitionRequestMessageCode == 300  \* 0x12c
SecurityDefinitionResponseMessageCode == 301  \* 0x12d
QuoteRequestMessageCode == 401  \* 0x191
QuoteStatusReportMessageCode == 402  \* 0x192
QuoteMessageCode == 403  \* 0x193
QuoteCancelMessageCode == 404  \* 0x194
QuoteRequestRejectMessageCode == 405  \* 0x195
PositionMaintenanceCancelRequestMessageCode == 501  \* 0x1f5
PositionMaintenanceRequestMessageCode == 502  \* 0x1f6
PositionMaintenanceReportMessageCode == 503  \* 0x1f7
AllocationInstructionMessageCode == 601  \* 0x259
AllocationReportMessageCode == 602  \* 0x25a
OrderMassActionRequestMessageCode == 701  \* 0x2bd
OrderMassActionReportMessageCode == 702  \* 0x2be

Payload ==
    [ tag : {NegotiateMessageCode}, body : NegotiateMessage ]
        \cup [ tag : {NegotiateResponseMessageCode}, body : NegotiateResponseMessage ]
        \cup [ tag : {NegotiateRejectMessageCode}, body : NegotiateRejectMessage ]
        \cup [ tag : {EstablishMessageCode}, body : EstablishMessage ]
        \cup [ tag : {EstablishAckMessageCode}, body : EstablishAckMessage ]
        \cup [ tag : {EstablishRejectMessageCode}, body : EstablishRejectMessage ]
        \cup [ tag : {TerminateMessageCode}, body : TerminateMessage ]
        \cup [ tag : {NotAppliedMessageCode}, body : NotAppliedMessage ]
        \cup [ tag : {SequenceMessageCode}, body : SequenceMessage ]
        \cup [ tag : {RetransmitRequestMessageCode}, body : RetransmitRequestMessage ]
        \cup [ tag : {RetransmissionMessageCode}, body : RetransmissionMessage ]
        \cup [ tag : {RetransmitRejectMessageCode}, body : RetransmitRejectMessage ]
        \cup [ tag : {SimpleNewOrderMessageCode}, body : SimpleNewOrderMessage ]
        \cup [ tag : {SimpleModifyOrderMessageCode}, body : SimpleModifyOrderMessage ]
        \cup [ tag : {NewOrderSingleMessageCode}, body : NewOrderSingleMessage ]
        \cup [ tag : {OrderCancelReplaceRequestMessageCode}, body : OrderCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {NewOrderCrossMessageCode}, body : NewOrderCrossMessage ]
        \cup [ tag : {ExecutionReportNewMessageCode}, body : ExecutionReportNewMessage ]
        \cup [ tag : {ExecutionReportModifyMessageCode}, body : ExecutionReportModifyMessage ]
        \cup [ tag : {ExecutionReportCancelMessageCode}, body : ExecutionReportCancelMessage ]
        \cup [ tag : {ExecutionReportTradeMessageCode}, body : ExecutionReportTradeMessage ]
        \cup [ tag : {ExecutionReportRejectMessageCode}, body : ExecutionReportRejectMessage ]
        \cup [ tag : {ExecutionReportForwardMessageCode}, body : ExecutionReportForwardMessage ]
        \cup [ tag : {BusinessMessageRejectMessageCode}, body : BusinessMessageRejectMessage ]
        \cup [ tag : {SecurityDefinitionRequestMessageCode}, body : SecurityDefinitionRequestMessage ]
        \cup [ tag : {SecurityDefinitionResponseMessageCode}, body : SecurityDefinitionResponseMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {QuoteStatusReportMessageCode}, body : QuoteStatusReportMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {QuoteCancelMessageCode}, body : QuoteCancelMessage ]
        \cup [ tag : {QuoteRequestRejectMessageCode}, body : QuoteRequestRejectMessage ]
        \cup [ tag : {PositionMaintenanceCancelRequestMessageCode}, body : PositionMaintenanceCancelRequestMessage ]
        \cup [ tag : {PositionMaintenanceRequestMessageCode}, body : PositionMaintenanceRequestMessage ]
        \cup [ tag : {PositionMaintenanceReportMessageCode}, body : PositionMaintenanceReportMessage ]
        \cup [ tag : {AllocationInstructionMessageCode}, body : AllocationInstructionMessage ]
        \cup [ tag : {AllocationReportMessageCode}, body : AllocationReportMessage ]
        \cup [ tag : {OrderMassActionRequestMessageCode}, body : OrderMassActionRequestMessage ]
        \cup [ tag : {OrderMassActionReportMessageCode}, body : OrderMassActionReportMessage ]

EncodePayload(message) ==
    CASE message.tag = NegotiateMessageCode -> EncodeNegotiateMessage(message.body)
      [] message.tag = NegotiateResponseMessageCode -> EncodeNegotiateResponseMessage(message.body)
      [] message.tag = NegotiateRejectMessageCode -> EncodeNegotiateRejectMessage(message.body)
      [] message.tag = EstablishMessageCode -> EncodeEstablishMessage(message.body)
      [] message.tag = EstablishAckMessageCode -> EncodeEstablishAckMessage(message.body)
      [] message.tag = EstablishRejectMessageCode -> EncodeEstablishRejectMessage(message.body)
      [] message.tag = TerminateMessageCode -> EncodeTerminateMessage(message.body)
      [] message.tag = NotAppliedMessageCode -> EncodeNotAppliedMessage(message.body)
      [] message.tag = SequenceMessageCode -> EncodeSequenceMessage(message.body)
      [] message.tag = RetransmitRequestMessageCode -> EncodeRetransmitRequestMessage(message.body)
      [] message.tag = RetransmissionMessageCode -> EncodeRetransmissionMessage(message.body)
      [] message.tag = RetransmitRejectMessageCode -> EncodeRetransmitRejectMessage(message.body)
      [] message.tag = SimpleNewOrderMessageCode -> EncodeSimpleNewOrderMessage(message.body)
      [] message.tag = SimpleModifyOrderMessageCode -> EncodeSimpleModifyOrderMessage(message.body)
      [] message.tag = NewOrderSingleMessageCode -> EncodeNewOrderSingleMessage(message.body)
      [] message.tag = OrderCancelReplaceRequestMessageCode -> EncodeOrderCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = NewOrderCrossMessageCode -> EncodeNewOrderCrossMessage(message.body)
      [] message.tag = ExecutionReportNewMessageCode -> EncodeExecutionReportNewMessage(message.body)
      [] message.tag = ExecutionReportModifyMessageCode -> EncodeExecutionReportModifyMessage(message.body)
      [] message.tag = ExecutionReportCancelMessageCode -> EncodeExecutionReportCancelMessage(message.body)
      [] message.tag = ExecutionReportTradeMessageCode -> EncodeExecutionReportTradeMessage(message.body)
      [] message.tag = ExecutionReportRejectMessageCode -> EncodeExecutionReportRejectMessage(message.body)
      [] message.tag = ExecutionReportForwardMessageCode -> EncodeExecutionReportForwardMessage(message.body)
      [] message.tag = BusinessMessageRejectMessageCode -> EncodeBusinessMessageRejectMessage(message.body)
      [] message.tag = SecurityDefinitionRequestMessageCode -> EncodeSecurityDefinitionRequestMessage(message.body)
      [] message.tag = SecurityDefinitionResponseMessageCode -> EncodeSecurityDefinitionResponseMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = QuoteStatusReportMessageCode -> EncodeQuoteStatusReportMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = QuoteCancelMessageCode -> EncodeQuoteCancelMessage(message.body)
      [] message.tag = QuoteRequestRejectMessageCode -> EncodeQuoteRequestRejectMessage(message.body)
      [] message.tag = PositionMaintenanceCancelRequestMessageCode -> EncodePositionMaintenanceCancelRequestMessage(message.body)
      [] message.tag = PositionMaintenanceRequestMessageCode -> EncodePositionMaintenanceRequestMessage(message.body)
      [] message.tag = PositionMaintenanceReportMessageCode -> EncodePositionMaintenanceReportMessage(message.body)
      [] message.tag = AllocationInstructionMessageCode -> EncodeAllocationInstructionMessage(message.body)
      [] message.tag = AllocationReportMessageCode -> EncodeAllocationReportMessage(message.body)
      [] message.tag = OrderMassActionRequestMessageCode -> EncodeOrderMassActionRequestMessage(message.body)
      [] message.tag = OrderMassActionReportMessageCode -> EncodeOrderMassActionReportMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = NegotiateMessageCode -> DecodeNegotiateMessage(bytes)
              [] tag = NegotiateResponseMessageCode -> DecodeNegotiateResponseMessage(bytes)
              [] tag = NegotiateRejectMessageCode -> DecodeNegotiateRejectMessage(bytes)
              [] tag = EstablishMessageCode -> DecodeEstablishMessage(bytes)
              [] tag = EstablishAckMessageCode -> DecodeEstablishAckMessage(bytes)
              [] tag = EstablishRejectMessageCode -> DecodeEstablishRejectMessage(bytes)
              [] tag = TerminateMessageCode -> DecodeTerminateMessage(bytes)
              [] tag = NotAppliedMessageCode -> DecodeNotAppliedMessage(bytes)
              [] tag = SequenceMessageCode -> DecodeSequenceMessage(bytes)
              [] tag = RetransmitRequestMessageCode -> DecodeRetransmitRequestMessage(bytes)
              [] tag = RetransmissionMessageCode -> DecodeRetransmissionMessage(bytes)
              [] tag = RetransmitRejectMessageCode -> DecodeRetransmitRejectMessage(bytes)
              [] tag = SimpleNewOrderMessageCode -> DecodeSimpleNewOrderMessage(bytes)
              [] tag = SimpleModifyOrderMessageCode -> DecodeSimpleModifyOrderMessage(bytes)
              [] tag = NewOrderSingleMessageCode -> DecodeNewOrderSingleMessage(bytes)
              [] tag = OrderCancelReplaceRequestMessageCode -> DecodeOrderCancelReplaceRequestMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = NewOrderCrossMessageCode -> DecodeNewOrderCrossMessage(bytes)
              [] tag = ExecutionReportNewMessageCode -> DecodeExecutionReportNewMessage(bytes)
              [] tag = ExecutionReportModifyMessageCode -> DecodeExecutionReportModifyMessage(bytes)
              [] tag = ExecutionReportCancelMessageCode -> DecodeExecutionReportCancelMessage(bytes)
              [] tag = ExecutionReportTradeMessageCode -> DecodeExecutionReportTradeMessage(bytes)
              [] tag = ExecutionReportRejectMessageCode -> DecodeExecutionReportRejectMessage(bytes)
              [] tag = ExecutionReportForwardMessageCode -> DecodeExecutionReportForwardMessage(bytes)
              [] tag = BusinessMessageRejectMessageCode -> DecodeBusinessMessageRejectMessage(bytes)
              [] tag = SecurityDefinitionRequestMessageCode -> DecodeSecurityDefinitionRequestMessage(bytes)
              [] tag = SecurityDefinitionResponseMessageCode -> DecodeSecurityDefinitionResponseMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = QuoteStatusReportMessageCode -> DecodeQuoteStatusReportMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = QuoteCancelMessageCode -> DecodeQuoteCancelMessage(bytes)
              [] tag = QuoteRequestRejectMessageCode -> DecodeQuoteRequestRejectMessage(bytes)
              [] tag = PositionMaintenanceCancelRequestMessageCode -> DecodePositionMaintenanceCancelRequestMessage(bytes)
              [] tag = PositionMaintenanceRequestMessageCode -> DecodePositionMaintenanceRequestMessage(bytes)
              [] tag = PositionMaintenanceReportMessageCode -> DecodePositionMaintenanceReportMessage(bytes)
              [] tag = AllocationInstructionMessageCode -> DecodeAllocationInstructionMessage(bytes)
              [] tag = AllocationReportMessageCode -> DecodeAllocationReportMessage(bytes)
              [] tag = OrderMassActionRequestMessageCode -> DecodeOrderMassActionRequestMessage(bytes)
              [] tag = OrderMassActionReportMessageCode -> DecodeOrderMassActionReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> NegotiateMessageCode, body |-> ZeroNegotiateMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> NegotiateMessageCode, body |-> one] : one \in CheckedNegotiateMessage }
        \cup { [tag |-> NegotiateResponseMessageCode, body |-> one] : one \in CheckedNegotiateResponseMessage }
        \cup { [tag |-> NegotiateRejectMessageCode, body |-> one] : one \in CheckedNegotiateRejectMessage }
        \cup { [tag |-> EstablishMessageCode, body |-> one] : one \in CheckedEstablishMessage }
        \cup { [tag |-> EstablishAckMessageCode, body |-> one] : one \in CheckedEstablishAckMessage }
        \cup { [tag |-> EstablishRejectMessageCode, body |-> one] : one \in CheckedEstablishRejectMessage }
        \cup { [tag |-> TerminateMessageCode, body |-> one] : one \in CheckedTerminateMessage }
        \cup { [tag |-> NotAppliedMessageCode, body |-> one] : one \in CheckedNotAppliedMessage }
        \cup { [tag |-> SequenceMessageCode, body |-> one] : one \in CheckedSequenceMessage }
        \cup { [tag |-> RetransmitRequestMessageCode, body |-> one] : one \in CheckedRetransmitRequestMessage }
        \cup { [tag |-> RetransmissionMessageCode, body |-> one] : one \in CheckedRetransmissionMessage }
        \cup { [tag |-> RetransmitRejectMessageCode, body |-> one] : one \in CheckedRetransmitRejectMessage }
        \cup { [tag |-> SimpleNewOrderMessageCode, body |-> one] : one \in CheckedSimpleNewOrderMessage }
        \cup { [tag |-> SimpleModifyOrderMessageCode, body |-> one] : one \in CheckedSimpleModifyOrderMessage }
        \cup { [tag |-> NewOrderSingleMessageCode, body |-> one] : one \in CheckedNewOrderSingleMessage }
        \cup { [tag |-> OrderCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> NewOrderCrossMessageCode, body |-> one] : one \in CheckedNewOrderCrossMessage }
        \cup { [tag |-> ExecutionReportNewMessageCode, body |-> one] : one \in CheckedExecutionReportNewMessage }
        \cup { [tag |-> ExecutionReportModifyMessageCode, body |-> one] : one \in CheckedExecutionReportModifyMessage }
        \cup { [tag |-> ExecutionReportCancelMessageCode, body |-> one] : one \in CheckedExecutionReportCancelMessage }
        \cup { [tag |-> ExecutionReportTradeMessageCode, body |-> one] : one \in CheckedExecutionReportTradeMessage }
        \cup { [tag |-> ExecutionReportRejectMessageCode, body |-> one] : one \in CheckedExecutionReportRejectMessage }
        \cup { [tag |-> ExecutionReportForwardMessageCode, body |-> one] : one \in CheckedExecutionReportForwardMessage }
        \cup { [tag |-> BusinessMessageRejectMessageCode, body |-> one] : one \in CheckedBusinessMessageRejectMessage }
        \cup { [tag |-> SecurityDefinitionRequestMessageCode, body |-> one] : one \in CheckedSecurityDefinitionRequestMessage }
        \cup { [tag |-> SecurityDefinitionResponseMessageCode, body |-> one] : one \in CheckedSecurityDefinitionResponseMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> QuoteStatusReportMessageCode, body |-> one] : one \in CheckedQuoteStatusReportMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> QuoteCancelMessageCode, body |-> one] : one \in CheckedQuoteCancelMessage }
        \cup { [tag |-> QuoteRequestRejectMessageCode, body |-> one] : one \in CheckedQuoteRequestRejectMessage }
        \cup { [tag |-> PositionMaintenanceCancelRequestMessageCode, body |-> one] : one \in CheckedPositionMaintenanceCancelRequestMessage }
        \cup { [tag |-> PositionMaintenanceRequestMessageCode, body |-> one] : one \in CheckedPositionMaintenanceRequestMessage }
        \cup { [tag |-> PositionMaintenanceReportMessageCode, body |-> one] : one \in CheckedPositionMaintenanceReportMessage }
        \cup { [tag |-> AllocationInstructionMessageCode, body |-> one] : one \in CheckedAllocationInstructionMessage }
        \cup { [tag |-> AllocationReportMessageCode, body |-> one] : one \in CheckedAllocationReportMessage }
        \cup { [tag |-> OrderMassActionRequestMessageCode, body |-> one] : one \in CheckedOrderMassActionRequestMessage }
        \cup { [tag |-> OrderMassActionReportMessageCode, body |-> one] : one \in CheckedOrderMassActionReportMessage }

(***************************************************************************)
(* Simple Open Frame, framed by Message Length                             *)
(***************************************************************************)

SimpleOpenFrame ==
    [ encodingType : Sample(2),
      blockLength  : Sample(2),
      schemaId     : Sample(2),
      version      : Sample(2),
      payload      : Payload ]

EncodeSimpleOpenFrameBody(message) ==
    message.encodingType
        \o message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeSimpleOpenFrame(message) ==
    LET body == EncodeSimpleOpenFrameBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSimpleOpenFrameBody(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET blockLength == ReadBytes(encodingType.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ encodingType |-> encodingType.value,
         blockLength  |-> blockLength.value,
         schemaId     |-> schemaId.value,
         version      |-> version.value,
         payload      |-> payload.value ], payload.rest)

DecodeSimpleOpenFrame(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSimpleOpenFrameBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSimpleOpenFrame ==
    [ encodingType |-> [i \in 1 .. 2 |-> 0],
      blockLength  |-> [i \in 1 .. 2 |-> 0],
      schemaId     |-> [i \in 1 .. 2 |-> 0],
      version      |-> [i \in 1 .. 2 |-> 0],
      payload      |-> ZeroPayload ]

(* Simple Open Frame at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOpenFrame ==
    { ZeroSimpleOpenFrame }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Simple Open Frame, written one after another *)
RECURSIVE EncodeSimpleOpenFrameList(_)
EncodeSimpleOpenFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSimpleOpenFrame(Head(messages)) \o EncodeSimpleOpenFrameList(Tail(messages))

(* As many Simple Open Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSimpleOpenFrameAll(_)
ReadSimpleOpenFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSimpleOpenFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSimpleOpenFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Simple Open Frame of each kind, for the lists that carry them *)
OneSimpleOpenFrame ==
    { [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NegotiateMessageCode, body |-> ZeroNegotiateMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NegotiateResponseMessageCode, body |-> ZeroNegotiateResponseMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NegotiateRejectMessageCode, body |-> ZeroNegotiateRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> EstablishMessageCode, body |-> ZeroEstablishMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> EstablishAckMessageCode, body |-> ZeroEstablishAckMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> EstablishRejectMessageCode, body |-> ZeroEstablishRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> TerminateMessageCode, body |-> ZeroTerminateMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NotAppliedMessageCode, body |-> ZeroNotAppliedMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SequenceMessageCode, body |-> ZeroSequenceMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> RetransmitRequestMessageCode, body |-> ZeroRetransmitRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> RetransmissionMessageCode, body |-> ZeroRetransmissionMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> RetransmitRejectMessageCode, body |-> ZeroRetransmitRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SimpleNewOrderMessageCode, body |-> ZeroSimpleNewOrderMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SimpleModifyOrderMessageCode, body |-> ZeroSimpleModifyOrderMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NewOrderSingleMessageCode, body |-> ZeroNewOrderSingleMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> OrderCancelReplaceRequestMessageCode, body |-> ZeroOrderCancelReplaceRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> OrderCancelRequestMessageCode, body |-> ZeroOrderCancelRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NewOrderCrossMessageCode, body |-> ZeroNewOrderCrossMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportNewMessageCode, body |-> ZeroExecutionReportNewMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportModifyMessageCode, body |-> ZeroExecutionReportModifyMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportCancelMessageCode, body |-> ZeroExecutionReportCancelMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportTradeMessageCode, body |-> ZeroExecutionReportTradeMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportRejectMessageCode, body |-> ZeroExecutionReportRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportForwardMessageCode, body |-> ZeroExecutionReportForwardMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> BusinessMessageRejectMessageCode, body |-> ZeroBusinessMessageRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionRequestMessageCode, body |-> ZeroSecurityDefinitionRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionResponseMessageCode, body |-> ZeroSecurityDefinitionResponseMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteStatusReportMessageCode, body |-> ZeroQuoteStatusReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteCancelMessageCode, body |-> ZeroQuoteCancelMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteRequestRejectMessageCode, body |-> ZeroQuoteRequestRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> PositionMaintenanceCancelRequestMessageCode, body |-> ZeroPositionMaintenanceCancelRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> PositionMaintenanceRequestMessageCode, body |-> ZeroPositionMaintenanceRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> PositionMaintenanceReportMessageCode, body |-> ZeroPositionMaintenanceReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> AllocationInstructionMessageCode, body |-> ZeroAllocationInstructionMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> AllocationReportMessageCode, body |-> ZeroAllocationReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> OrderMassActionRequestMessageCode, body |-> ZeroOrderMassActionRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> OrderMassActionReportMessageCode, body |-> ZeroOrderMassActionReportMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ simpleOpenFrame : SampleLists(OneSimpleOpenFrame) ]

EncodePacket(message) ==
    EncodeSimpleOpenFrameList(message.simpleOpenFrame)

DecodePacket(bytes) ==
    LET simpleOpenFrame == ReadSimpleOpenFrameAll(bytes) IN IF ~simpleOpenFrame.ok THEN Fail ELSE
    Ok([ simpleOpenFrame |-> simpleOpenFrame.value ], simpleOpenFrame.rest)

ZeroPacket ==
    [ simpleOpenFrame |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.simpleOpenFrame = one] : one \in SampleLists(OneSimpleOpenFrame) }

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

(* Every Client Ip decodes back to what was encoded, and leaves nothing over *)
RoundTripClientIp ==
    \A message \in CheckedClientIp :
        LET read == DecodeClientIp(EncodeClientIp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client App Name decodes back to what was encoded, and leaves nothing over *)
RoundTripClientAppName ==
    \A message \in CheckedClientAppName :
        LET read == DecodeClientAppName(EncodeClientAppName(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client App Version decodes back to what was encoded, and leaves nothing over *)
RoundTripClientAppVersion ==
    \A message \in CheckedClientAppVersion :
        LET read == DecodeClientAppVersion(EncodeClientAppVersion(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiateMessage ==
    \A message \in CheckedNegotiateMessage :
        LET read == DecodeNegotiateMessage(EncodeNegotiateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiate Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiateResponseMessage ==
    \A message \in CheckedNegotiateResponseMessage :
        LET read == DecodeNegotiateResponseMessage(EncodeNegotiateResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiate Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiateRejectMessage ==
    \A message \in CheckedNegotiateRejectMessage :
        LET read == DecodeNegotiateRejectMessage(EncodeNegotiateRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Credentials decodes back to what was encoded, and leaves nothing over *)
RoundTripCredentials2 ==
    \A message \in CheckedCredentials2 :
        LET read == DecodeCredentials2(EncodeCredentials2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establish Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishMessage ==
    \A message \in CheckedEstablishMessage :
        LET read == DecodeEstablishMessage(EncodeEstablishMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establish Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishAckMessage ==
    \A message \in CheckedEstablishAckMessage :
        LET read == DecodeEstablishAckMessage(EncodeEstablishAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establish Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablishRejectMessage ==
    \A message \in CheckedEstablishRejectMessage :
        LET read == DecodeEstablishRejectMessage(EncodeEstablishRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminateMessage ==
    \A message \in CheckedTerminateMessage :
        LET read == DecodeTerminateMessage(EncodeTerminateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Applied Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAppliedMessage ==
    \A message \in CheckedNotAppliedMessage :
        LET read == DecodeNotAppliedMessage(EncodeNotAppliedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceMessage ==
    \A message \in CheckedSequenceMessage :
        LET read == DecodeSequenceMessage(EncodeSequenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequestMessage ==
    \A message \in CheckedRetransmitRequestMessage :
        LET read == DecodeRetransmitRequestMessage(EncodeRetransmitRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionMessage ==
    \A message \in CheckedRetransmissionMessage :
        LET read == DecodeRetransmissionMessage(EncodeRetransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRejectMessage ==
    \A message \in CheckedRetransmitRejectMessage :
        LET read == DecodeRetransmitRejectMessage(EncodeRetransmitRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader ==
    \A message \in CheckedInboundBusinessHeader :
        LET read == DecodeInboundBusinessHeader(EncodeInboundBusinessHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId ==
    \A message \in CheckedInvestorId :
        LET read == DecodeInvestorId(EncodeInvestorId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo ==
    \A message \in CheckedMemo :
        LET read == DecodeMemo(EncodeMemo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleNewOrderMessage ==
    \A message \in CheckedSimpleNewOrderMessage :
        LET read == DecodeSimpleNewOrderMessage(EncodeSimpleNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader2 ==
    \A message \in CheckedInboundBusinessHeader2 :
        LET read == DecodeInboundBusinessHeader2(EncodeInboundBusinessHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId2 ==
    \A message \in CheckedInvestorId2 :
        LET read == DecodeInvestorId2(EncodeInvestorId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo2 ==
    \A message \in CheckedMemo2 :
        LET read == DecodeMemo2(EncodeMemo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleModifyOrderMessage ==
    \A message \in CheckedSimpleModifyOrderMessage :
        LET read == DecodeSimpleModifyOrderMessage(EncodeSimpleModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader3 ==
    \A message \in CheckedInboundBusinessHeader3 :
        LET read == DecodeInboundBusinessHeader3(EncodeInboundBusinessHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custodian Info decodes back to what was encoded, and leaves nothing over *)
RoundTripCustodianInfo ==
    \A message \in CheckedCustodianInfo :
        LET read == DecodeCustodianInfo(EncodeCustodianInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId3 ==
    \A message \in CheckedInvestorId3 :
        LET read == DecodeInvestorId3(EncodeInvestorId3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId ==
    \A message \in CheckedDeskId :
        LET read == DecodeDeskId(EncodeDeskId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo3 ==
    \A message \in CheckedMemo3 :
        LET read == DecodeMemo3(EncodeMemo3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleMessage ==
    \A message \in CheckedNewOrderSingleMessage :
        LET read == DecodeNewOrderSingleMessage(EncodeNewOrderSingleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader4 ==
    \A message \in CheckedInboundBusinessHeader4 :
        LET read == DecodeInboundBusinessHeader4(EncodeInboundBusinessHeader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custodian Info decodes back to what was encoded, and leaves nothing over *)
RoundTripCustodianInfo2 ==
    \A message \in CheckedCustodianInfo2 :
        LET read == DecodeCustodianInfo2(EncodeCustodianInfo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId4 ==
    \A message \in CheckedInvestorId4 :
        LET read == DecodeInvestorId4(EncodeInvestorId4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId2 ==
    \A message \in CheckedDeskId2 :
        LET read == DecodeDeskId2(EncodeDeskId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo4 ==
    \A message \in CheckedMemo4 :
        LET read == DecodeMemo4(EncodeMemo4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReplaceRequestMessage ==
    \A message \in CheckedOrderCancelReplaceRequestMessage :
        LET read == DecodeOrderCancelReplaceRequestMessage(EncodeOrderCancelReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader5 ==
    \A message \in CheckedInboundBusinessHeader5 :
        LET read == DecodeInboundBusinessHeader5(EncodeInboundBusinessHeader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId3 ==
    \A message \in CheckedDeskId3 :
        LET read == DecodeDeskId3(EncodeDeskId3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo5 ==
    \A message \in CheckedMemo5 :
        LET read == DecodeMemo5(EncodeMemo5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader6 ==
    \A message \in CheckedInboundBusinessHeader6 :
        LET read == DecodeInboundBusinessHeader6(EncodeInboundBusinessHeader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Sides Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossSidesGroup ==
    \A message \in CheckedCrossSidesGroup :
        LET read == DecodeCrossSidesGroup(EncodeCrossSidesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Sides Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossSidesGroups ==
    \A message \in CheckedCrossSidesGroups :
        LET read == DecodeCrossSidesGroups(EncodeCrossSidesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId4 ==
    \A message \in CheckedDeskId4 :
        LET read == DecodeDeskId4(EncodeDeskId4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo6 ==
    \A message \in CheckedMemo6 :
        LET read == DecodeMemo6(EncodeMemo6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossMessage ==
    \A message \in CheckedNewOrderCrossMessage :
        LET read == DecodeNewOrderCrossMessage(EncodeNewOrderCrossMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader ==
    \A message \in CheckedOutboundBusinessHeader :
        LET read == DecodeOutboundBusinessHeader(EncodeOutboundBusinessHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId5 ==
    \A message \in CheckedInvestorId5 :
        LET read == DecodeInvestorId5(EncodeInvestorId5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId5 ==
    \A message \in CheckedDeskId5 :
        LET read == DecodeDeskId5(EncodeDeskId5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo7 ==
    \A message \in CheckedMemo7 :
        LET read == DecodeMemo7(EncodeMemo7(message))
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

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader2 ==
    \A message \in CheckedOutboundBusinessHeader2 :
        LET read == DecodeOutboundBusinessHeader2(EncodeOutboundBusinessHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId6 ==
    \A message \in CheckedInvestorId6 :
        LET read == DecodeInvestorId6(EncodeInvestorId6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId6 ==
    \A message \in CheckedDeskId6 :
        LET read == DecodeDeskId6(EncodeDeskId6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo8 ==
    \A message \in CheckedMemo8 :
        LET read == DecodeMemo8(EncodeMemo8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportModifyMessage ==
    \A message \in CheckedExecutionReportModifyMessage :
        LET read == DecodeExecutionReportModifyMessage(EncodeExecutionReportModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader3 ==
    \A message \in CheckedOutboundBusinessHeader3 :
        LET read == DecodeOutboundBusinessHeader3(EncodeOutboundBusinessHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId7 ==
    \A message \in CheckedInvestorId7 :
        LET read == DecodeInvestorId7(EncodeInvestorId7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId7 ==
    \A message \in CheckedDeskId7 :
        LET read == DecodeDeskId7(EncodeDeskId7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo9 ==
    \A message \in CheckedMemo9 :
        LET read == DecodeMemo9(EncodeMemo9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportCancelMessage ==
    \A message \in CheckedExecutionReportCancelMessage :
        LET read == DecodeExecutionReportCancelMessage(EncodeExecutionReportCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader4 ==
    \A message \in CheckedOutboundBusinessHeader4 :
        LET read == DecodeOutboundBusinessHeader4(EncodeOutboundBusinessHeader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId8 ==
    \A message \in CheckedDeskId8 :
        LET read == DecodeDeskId8(EncodeDeskId8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo10 ==
    \A message \in CheckedMemo10 :
        LET read == DecodeMemo10(EncodeMemo10(message))
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

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader5 ==
    \A message \in CheckedOutboundBusinessHeader5 :
        LET read == DecodeOutboundBusinessHeader5(EncodeOutboundBusinessHeader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId8 ==
    \A message \in CheckedInvestorId8 :
        LET read == DecodeInvestorId8(EncodeInvestorId8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId9 ==
    \A message \in CheckedDeskId9 :
        LET read == DecodeDeskId9(EncodeDeskId9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo11 ==
    \A message \in CheckedMemo11 :
        LET read == DecodeMemo11(EncodeMemo11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText ==
    \A message \in CheckedText :
        LET read == DecodeText(EncodeText(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportRejectMessage ==
    \A message \in CheckedExecutionReportRejectMessage :
        LET read == DecodeExecutionReportRejectMessage(EncodeExecutionReportRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader6 ==
    \A message \in CheckedOutboundBusinessHeader6 :
        LET read == DecodeOutboundBusinessHeader6(EncodeOutboundBusinessHeader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId10 ==
    \A message \in CheckedDeskId10 :
        LET read == DecodeDeskId10(EncodeDeskId10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo12 ==
    \A message \in CheckedMemo12 :
        LET read == DecodeMemo12(EncodeMemo12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Forward Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportForwardMessage ==
    \A message \in CheckedExecutionReportForwardMessage :
        LET read == DecodeExecutionReportForwardMessage(EncodeExecutionReportForwardMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader7 ==
    \A message \in CheckedOutboundBusinessHeader7 :
        LET read == DecodeOutboundBusinessHeader7(EncodeOutboundBusinessHeader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo13 ==
    \A message \in CheckedMemo13 :
        LET read == DecodeMemo13(EncodeMemo13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText2 ==
    \A message \in CheckedText2 :
        LET read == DecodeText2(EncodeText2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Message Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessMessageRejectMessage ==
    \A message \in CheckedBusinessMessageRejectMessage :
        LET read == DecodeBusinessMessageRejectMessage(EncodeBusinessMessageRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader7 ==
    \A message \in CheckedInboundBusinessHeader7 :
        LET read == DecodeInboundBusinessHeader7(EncodeInboundBusinessHeader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsGroup ==
    \A message \in CheckedLegsGroup :
        LET read == DecodeLegsGroup(EncodeLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsGroups ==
    \A message \in CheckedLegsGroups :
        LET read == DecodeLegsGroups(EncodeLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestMessage ==
    \A message \in CheckedSecurityDefinitionRequestMessage :
        LET read == DecodeSecurityDefinitionRequestMessage(EncodeSecurityDefinitionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader8 ==
    \A message \in CheckedOutboundBusinessHeader8 :
        LET read == DecodeOutboundBusinessHeader8(EncodeOutboundBusinessHeader8(message))
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

(* Every Bidirectional Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBidirectionalBusinessHeader ==
    \A message \in CheckedBidirectionalBusinessHeader :
        LET read == DecodeBidirectionalBusinessHeader(EncodeBidirectionalBusinessHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sides Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSidesGroup ==
    \A message \in CheckedSidesGroup :
        LET read == DecodeSidesGroup(EncodeSidesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sides Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSidesGroups ==
    \A message \in CheckedSidesGroups :
        LET read == DecodeSidesGroups(EncodeSidesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId11 ==
    \A message \in CheckedDeskId11 :
        LET read == DecodeDeskId11(EncodeDeskId11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo14 ==
    \A message \in CheckedMemo14 :
        LET read == DecodeMemo14(EncodeMemo14(message))
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

(* Every Bidirectional Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBidirectionalBusinessHeader2 ==
    \A message \in CheckedBidirectionalBusinessHeader2 :
        LET read == DecodeBidirectionalBusinessHeader2(EncodeBidirectionalBusinessHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId12 ==
    \A message \in CheckedDeskId12 :
        LET read == DecodeDeskId12(EncodeDeskId12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo15 ==
    \A message \in CheckedMemo15 :
        LET read == DecodeMemo15(EncodeMemo15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText3 ==
    \A message \in CheckedText3 :
        LET read == DecodeText3(EncodeText3(message))
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

(* Every Bidirectional Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBidirectionalBusinessHeader3 ==
    \A message \in CheckedBidirectionalBusinessHeader3 :
        LET read == DecodeBidirectionalBusinessHeader3(EncodeBidirectionalBusinessHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId13 ==
    \A message \in CheckedDeskId13 :
        LET read == DecodeDeskId13(EncodeDeskId13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo16 ==
    \A message \in CheckedMemo16 :
        LET read == DecodeMemo16(EncodeMemo16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bidirectional Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBidirectionalBusinessHeader4 ==
    \A message \in CheckedBidirectionalBusinessHeader4 :
        LET read == DecodeBidirectionalBusinessHeader4(EncodeBidirectionalBusinessHeader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId14 ==
    \A message \in CheckedDeskId14 :
        LET read == DecodeDeskId14(EncodeDeskId14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo17 ==
    \A message \in CheckedMemo17 :
        LET read == DecodeMemo17(EncodeMemo17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelMessage ==
    \A message \in CheckedQuoteCancelMessage :
        LET read == DecodeQuoteCancelMessage(EncodeQuoteCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bidirectional Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBidirectionalBusinessHeader5 ==
    \A message \in CheckedBidirectionalBusinessHeader5 :
        LET read == DecodeBidirectionalBusinessHeader5(EncodeBidirectionalBusinessHeader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sides Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSidesGroup2 ==
    \A message \in CheckedSidesGroup2 :
        LET read == DecodeSidesGroup2(EncodeSidesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sides Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSidesGroups2 ==
    \A message \in CheckedSidesGroups2 :
        LET read == DecodeSidesGroups2(EncodeSidesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId15 ==
    \A message \in CheckedDeskId15 :
        LET read == DecodeDeskId15(EncodeDeskId15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo18 ==
    \A message \in CheckedMemo18 :
        LET read == DecodeMemo18(EncodeMemo18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText4 ==
    \A message \in CheckedText4 :
        LET read == DecodeText4(EncodeText4(message))
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

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader8 ==
    \A message \in CheckedInboundBusinessHeader8 :
        LET read == DecodeInboundBusinessHeader8(EncodeInboundBusinessHeader8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Position Maintenance Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionMaintenanceCancelRequestMessage ==
    \A message \in CheckedPositionMaintenanceCancelRequestMessage :
        LET read == DecodePositionMaintenanceCancelRequestMessage(EncodePositionMaintenanceCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader9 ==
    \A message \in CheckedInboundBusinessHeader9 :
        LET read == DecodeInboundBusinessHeader9(EncodeInboundBusinessHeader9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId16 ==
    \A message \in CheckedDeskId16 :
        LET read == DecodeDeskId16(EncodeDeskId16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo19 ==
    \A message \in CheckedMemo19 :
        LET read == DecodeMemo19(EncodeMemo19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Position Maintenance Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionMaintenanceRequestMessage ==
    \A message \in CheckedPositionMaintenanceRequestMessage :
        LET read == DecodePositionMaintenanceRequestMessage(EncodePositionMaintenanceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader9 ==
    \A message \in CheckedOutboundBusinessHeader9 :
        LET read == DecodeOutboundBusinessHeader9(EncodeOutboundBusinessHeader9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Positions Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionsGroup ==
    \A message \in CheckedPositionsGroup :
        LET read == DecodePositionsGroup(EncodePositionsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Positions Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionsGroups ==
    \A message \in CheckedPositionsGroups :
        LET read == DecodePositionsGroups(EncodePositionsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId17 ==
    \A message \in CheckedDeskId17 :
        LET read == DecodeDeskId17(EncodeDeskId17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo20 ==
    \A message \in CheckedMemo20 :
        LET read == DecodeMemo20(EncodeMemo20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText5 ==
    \A message \in CheckedText5 :
        LET read == DecodeText5(EncodeText5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Position Maintenance Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionMaintenanceReportMessage ==
    \A message \in CheckedPositionMaintenanceReportMessage :
        LET read == DecodePositionMaintenanceReportMessage(EncodePositionMaintenanceReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader10 ==
    \A message \in CheckedInboundBusinessHeader10 :
        LET read == DecodeInboundBusinessHeader10(EncodeInboundBusinessHeader10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Desk Id decodes back to what was encoded, and leaves nothing over *)
RoundTripDeskId18 ==
    \A message \in CheckedDeskId18 :
        LET read == DecodeDeskId18(EncodeDeskId18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Memo decodes back to what was encoded, and leaves nothing over *)
RoundTripMemo21 ==
    \A message \in CheckedMemo21 :
        LET read == DecodeMemo21(EncodeMemo21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Instruction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationInstructionMessage ==
    \A message \in CheckedAllocationInstructionMessage :
        LET read == DecodeAllocationInstructionMessage(EncodeAllocationInstructionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader10 ==
    \A message \in CheckedOutboundBusinessHeader10 :
        LET read == DecodeOutboundBusinessHeader10(EncodeOutboundBusinessHeader10(message))
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

(* Every Inbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundBusinessHeader11 ==
    \A message \in CheckedInboundBusinessHeader11 :
        LET read == DecodeInboundBusinessHeader11(EncodeInboundBusinessHeader11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId9 ==
    \A message \in CheckedInvestorId9 :
        LET read == DecodeInvestorId9(EncodeInvestorId9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Action Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassActionRequestMessage ==
    \A message \in CheckedOrderMassActionRequestMessage :
        LET read == DecodeOrderMassActionRequestMessage(EncodeOrderMassActionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outbound Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutboundBusinessHeader11 ==
    \A message \in CheckedOutboundBusinessHeader11 :
        LET read == DecodeOutboundBusinessHeader11(EncodeOutboundBusinessHeader11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Id decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorId10 ==
    \A message \in CheckedInvestorId10 :
        LET read == DecodeInvestorId10(EncodeInvestorId10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText6 ==
    \A message \in CheckedText6 :
        LET read == DecodeText6(EncodeText6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Action Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassActionReportMessage ==
    \A message \in CheckedOrderMassActionReportMessage :
        LET read == DecodeOrderMassActionReportMessage(EncodeOrderMassActionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Open Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOpenFrame ==
    \A message \in CheckedSimpleOpenFrame :
        LET read == DecodeSimpleOpenFrame(EncodeSimpleOpenFrame(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesSimpleOpenFrame ==
    \A message \in CheckedSimpleOpenFrame :
        LET bytes == EncodeSimpleOpenFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
