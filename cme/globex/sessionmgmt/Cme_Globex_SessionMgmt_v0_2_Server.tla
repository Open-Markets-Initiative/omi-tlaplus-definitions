---------------- MODULE Cme_Globex_SessionMgmt_v0_2_Server -----------------
(***************************************************************************)
(* CME Group Session Management v0.2                                       *)
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
(* Negotiation Reject: 70 bytes                                            *)
(***************************************************************************)

NegotiationReject ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(1),
      padding5         : Sample(5) ]

EncodeNegotiationReject(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.padding5

DecodeNegotiationReject(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 1) IN IF ~errorCodes.ok THEN Fail ELSE
    LET padding5 == ReadBytes(errorCodes.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         padding5         |-> padding5.value ], padding5.rest)

ZeroNegotiationReject ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 1 |-> 0],
      padding5         |-> [i \in 1 .. 5 |-> 0] ]

(* Negotiation Reject at zero, then each field in turn at the values it is checked at *)
CheckedNegotiationReject ==
    { ZeroNegotiationReject }
        \cup { [ZeroNegotiationReject EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroNegotiationReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationReject EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationReject EXCEPT !.errorCodes = one] : one \in Sample(1) }
        \cup { [ZeroNegotiationReject EXCEPT !.padding5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Negotiation Response: 22 bytes                                          *)
(***************************************************************************)

NegotiationResponse ==
    [ uuid                        : Sample(8),
      requestTimestamp            : Sample(8),
      secretKeySecureIdExpiration : Sample(2),
      padding4                    : Sample(4) ]

EncodeNegotiationResponse(message) ==
    message.uuid
        \o message.requestTimestamp
        \o message.secretKeySecureIdExpiration
        \o message.padding4

DecodeNegotiationResponse(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET secretKeySecureIdExpiration == ReadBytes(requestTimestamp.rest, 2) IN IF ~secretKeySecureIdExpiration.ok THEN Fail ELSE
    LET padding4 == ReadBytes(secretKeySecureIdExpiration.rest, 4) IN IF ~padding4.ok THEN Fail ELSE
    Ok([ uuid                        |-> uuid.value,
         requestTimestamp            |-> requestTimestamp.value,
         secretKeySecureIdExpiration |-> secretKeySecureIdExpiration.value,
         padding4                    |-> padding4.value ], padding4.rest)

ZeroNegotiationResponse ==
    [ uuid                        |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp            |-> [i \in 1 .. 8 |-> 0],
      secretKeySecureIdExpiration |-> [i \in 1 .. 2 |-> 0],
      padding4                    |-> [i \in 1 .. 4 |-> 0] ]

(* Negotiation Response at zero, then each field in turn at the values it is checked at *)
CheckedNegotiationResponse ==
    { ZeroNegotiationResponse }
        \cup { [ZeroNegotiationResponse EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.secretKeySecureIdExpiration = one] : one \in Sample(2) }
        \cup { [ZeroNegotiationResponse EXCEPT !.padding4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Terminate: 70 bytes                                                     *)
(***************************************************************************)

Terminate ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(1),
      padding5         : Sample(5) ]

EncodeTerminate(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.padding5

DecodeTerminate(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 1) IN IF ~errorCodes.ok THEN Fail ELSE
    LET padding5 == ReadBytes(errorCodes.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         padding5         |-> padding5.value ], padding5.rest)

ZeroTerminate ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 1 |-> 0],
      padding5         |-> [i \in 1 .. 5 |-> 0] ]

(* Terminate at zero, then each field in turn at the values it is checked at *)
CheckedTerminate ==
    { ZeroTerminate }
        \cup { [ZeroTerminate EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroTerminate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.errorCodes = one] : one \in Sample(1) }
        \cup { [ZeroTerminate EXCEPT !.padding5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Request Ack Security Group: 6 bytes                                     *)
(***************************************************************************)

RequestAckSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeRequestAckSecurityGroup(message) ==
    message.securityGroup

DecodeRequestAckSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroRequestAckSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Request Ack Security Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckSecurityGroup ==
    { ZeroRequestAckSecurityGroup }
        \cup { [ZeroRequestAckSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Request Ack Security Group, written one after another *)
RECURSIVE EncodeRequestAckSecurityGroupList(_)
EncodeRequestAckSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestAckSecurityGroup(Head(messages)) \o EncodeRequestAckSecurityGroupList(Tail(messages))

(* As many Request Ack Security Group as the field that counts them says *)
RECURSIVE ReadRequestAckSecurityGroupList(_, _)
ReadRequestAckSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestAckSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestAckSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Request Ack Security Group of each kind, for the lists that carry them *)
OneRequestAckSecurityGroup == { ZeroRequestAckSecurityGroup }

(***************************************************************************)
(* Request Ack Security Groups                                             *)
(***************************************************************************)

RequestAckSecurityGroups ==
    [ blockLength             : Sample(2),
      requestAckSecurityGroup : SampleLists(OneRequestAckSecurityGroup) ]

EncodeRequestAckSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.requestAckSecurityGroup), 1)
        \o EncodeRequestAckSecurityGroupList(message.requestAckSecurityGroup)

DecodeRequestAckSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestAckSecurityGroup == ReadRequestAckSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestAckSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         requestAckSecurityGroup |-> requestAckSecurityGroup.value ], requestAckSecurityGroup.rest)

ZeroRequestAckSecurityGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      requestAckSecurityGroup |-> << >> ]

(* Request Ack Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckSecurityGroups ==
    { ZeroRequestAckSecurityGroups }
        \cup { [ZeroRequestAckSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRequestAckSecurityGroups EXCEPT !.requestAckSecurityGroup = one] : one \in SampleLists(OneRequestAckSecurityGroup) }

(***************************************************************************)
(* Request Ack Related Symbol Group: 4 bytes                               *)
(***************************************************************************)

RequestAckRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeRequestAckRelatedSymbolGroup(message) ==
    message.securityId

DecodeRequestAckRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroRequestAckRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Ack Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckRelatedSymbolGroup ==
    { ZeroRequestAckRelatedSymbolGroup }
        \cup { [ZeroRequestAckRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Request Ack Related Symbol Group, written one after another *)
RECURSIVE EncodeRequestAckRelatedSymbolGroupList(_)
EncodeRequestAckRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestAckRelatedSymbolGroup(Head(messages)) \o EncodeRequestAckRelatedSymbolGroupList(Tail(messages))

(* As many Request Ack Related Symbol Group as the field that counts them says *)
RECURSIVE ReadRequestAckRelatedSymbolGroupList(_, _)
ReadRequestAckRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestAckRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestAckRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Request Ack Related Symbol Group of each kind, for the lists that carry them *)
OneRequestAckRelatedSymbolGroup == { ZeroRequestAckRelatedSymbolGroup }

(***************************************************************************)
(* Request Ack Related Symbol Groups                                       *)
(***************************************************************************)

RequestAckRelatedSymbolGroups ==
    [ blockLength                  : Sample(2),
      requestAckRelatedSymbolGroup : SampleLists(OneRequestAckRelatedSymbolGroup) ]

EncodeRequestAckRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.requestAckRelatedSymbolGroup), 1)
        \o EncodeRequestAckRelatedSymbolGroupList(message.requestAckRelatedSymbolGroup)

DecodeRequestAckRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestAckRelatedSymbolGroup == ReadRequestAckRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestAckRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         requestAckRelatedSymbolGroup |-> requestAckRelatedSymbolGroup.value ], requestAckRelatedSymbolGroup.rest)

ZeroRequestAckRelatedSymbolGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      requestAckRelatedSymbolGroup |-> << >> ]

(* Request Ack Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckRelatedSymbolGroups ==
    { ZeroRequestAckRelatedSymbolGroups }
        \cup { [ZeroRequestAckRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRequestAckRelatedSymbolGroups EXCEPT !.requestAckRelatedSymbolGroup = one] : one \in SampleLists(OneRequestAckRelatedSymbolGroup) }

(***************************************************************************)
(* Request Ack                                                             *)
(***************************************************************************)

RequestAck ==
    [ mdReqId                       : Sample(4),
      subscriptionReqType           : Sample(1),
      mdReqIdStatus                 : Sample(1),
      requestAckSecurityGroups      : RequestAckSecurityGroups,
      requestAckRelatedSymbolGroups : RequestAckRelatedSymbolGroups ]

EncodeRequestAck(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o message.mdReqIdStatus
        \o EncodeRequestAckSecurityGroups(message.requestAckSecurityGroups)
        \o EncodeRequestAckRelatedSymbolGroups(message.requestAckRelatedSymbolGroups)

DecodeRequestAck(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET mdReqIdStatus == ReadBytes(subscriptionReqType.rest, 1) IN IF ~mdReqIdStatus.ok THEN Fail ELSE
    LET requestAckSecurityGroups == DecodeRequestAckSecurityGroups(mdReqIdStatus.rest) IN IF ~requestAckSecurityGroups.ok THEN Fail ELSE
    LET requestAckRelatedSymbolGroups == DecodeRequestAckRelatedSymbolGroups(requestAckSecurityGroups.rest) IN IF ~requestAckRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                       |-> mdReqId.value,
         subscriptionReqType           |-> subscriptionReqType.value,
         mdReqIdStatus                 |-> mdReqIdStatus.value,
         requestAckSecurityGroups      |-> requestAckSecurityGroups.value,
         requestAckRelatedSymbolGroups |-> requestAckRelatedSymbolGroups.value ], requestAckRelatedSymbolGroups.rest)

ZeroRequestAck ==
    [ mdReqId                       |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType           |-> [i \in 1 .. 1 |-> 0],
      mdReqIdStatus                 |-> [i \in 1 .. 1 |-> 0],
      requestAckSecurityGroups      |-> ZeroRequestAckSecurityGroups,
      requestAckRelatedSymbolGroups |-> ZeroRequestAckRelatedSymbolGroups ]

(* Request Ack at zero, then each field in turn at the values it is checked at *)
CheckedRequestAck ==
    { ZeroRequestAck }
        \cup { [ZeroRequestAck EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroRequestAck EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroRequestAck EXCEPT !.mdReqIdStatus = one] : one \in Sample(1) }
        \cup { [ZeroRequestAck EXCEPT !.requestAckSecurityGroups = one] : one \in CheckedRequestAckSecurityGroups }
        \cup { [ZeroRequestAck EXCEPT !.requestAckRelatedSymbolGroups = one] : one \in CheckedRequestAckRelatedSymbolGroups }

(***************************************************************************)
(* Request Reject: 105 bytes                                               *)
(***************************************************************************)

RequestReject ==
    [ mdReqIdOptional : Sample(4),
      mdReqRejReason  : Sample(1),
      text            : Sample(100) ]

EncodeRequestReject(message) ==
    message.mdReqIdOptional
        \o message.mdReqRejReason
        \o message.text

DecodeRequestReject(bytes) ==
    LET mdReqIdOptional == ReadBytes(bytes, 4) IN IF ~mdReqIdOptional.ok THEN Fail ELSE
    LET mdReqRejReason == ReadBytes(mdReqIdOptional.rest, 1) IN IF ~mdReqRejReason.ok THEN Fail ELSE
    LET text == ReadBytes(mdReqRejReason.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ mdReqIdOptional |-> mdReqIdOptional.value,
         mdReqRejReason  |-> mdReqRejReason.value,
         text            |-> text.value ], text.rest)

ZeroRequestReject ==
    [ mdReqIdOptional |-> [i \in 1 .. 4 |-> 0],
      mdReqRejReason  |-> [i \in 1 .. 1 |-> 0],
      text            |-> [i \in 1 .. 100 |-> 0] ]

(* Request Reject at zero, then each field in turn at the values it is checked at *)
CheckedRequestReject ==
    { ZeroRequestReject }
        \cup { [ZeroRequestReject EXCEPT !.mdReqIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRequestReject EXCEPT !.mdReqRejReason = one] : one \in Sample(1) }
        \cup { [ZeroRequestReject EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

NegotiationRejectCode == 201  \* 0xc9
NegotiationResponseCode == 202  \* 0xca
TerminateCode == 203  \* 0xcb
RequestAckCode == 206  \* 0xce
RequestRejectCode == 207  \* 0xcf

ServerPayload ==
    [ tag : {NegotiationRejectCode}, body : NegotiationReject ]
        \cup [ tag : {NegotiationResponseCode}, body : NegotiationResponse ]
        \cup [ tag : {TerminateCode}, body : Terminate ]
        \cup [ tag : {RequestAckCode}, body : RequestAck ]
        \cup [ tag : {RequestRejectCode}, body : RequestReject ]

EncodeServerPayload(message) ==
    CASE message.tag = NegotiationRejectCode -> EncodeNegotiationReject(message.body)
      [] message.tag = NegotiationResponseCode -> EncodeNegotiationResponse(message.body)
      [] message.tag = TerminateCode -> EncodeTerminate(message.body)
      [] message.tag = RequestAckCode -> EncodeRequestAck(message.body)
      [] message.tag = RequestRejectCode -> EncodeRequestReject(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = NegotiationRejectCode -> DecodeNegotiationReject(bytes)
              [] tag = NegotiationResponseCode -> DecodeNegotiationResponse(bytes)
              [] tag = TerminateCode -> DecodeTerminate(bytes)
              [] tag = RequestAckCode -> DecodeRequestAck(bytes)
              [] tag = RequestRejectCode -> DecodeRequestReject(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> NegotiationRejectCode, body |-> ZeroNegotiationReject]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> NegotiationRejectCode, body |-> one] : one \in CheckedNegotiationReject }
        \cup { [tag |-> NegotiationResponseCode, body |-> one] : one \in CheckedNegotiationResponse }
        \cup { [tag |-> TerminateCode, body |-> one] : one \in CheckedTerminate }
        \cup { [tag |-> RequestAckCode, body |-> one] : one \in CheckedRequestAck }
        \cup { [tag |-> RequestRejectCode, body |-> one] : one \in CheckedRequestReject }

(***************************************************************************)
(* Server Message                                                          *)
(***************************************************************************)

ServerMessage ==
    [ blockLength   : Sample(2),
      schemaId      : Sample(2),
      version       : Sample(2),
      serverPayload : ServerPayload ]

EncodeServerMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.serverPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeServerPayload(message.serverPayload)

DecodeServerMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(templateId.value, version.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         serverPayload |-> serverPayload.value ], serverPayload.rest)

ZeroServerMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      serverPayload |-> ZeroServerPayload ]

(* Server Message at zero, then each field in turn at the values it is checked at *)
CheckedServerMessage ==
    { ZeroServerMessage }
        \cup { [ZeroServerMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroServerMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroServerMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(***************************************************************************)
(* Server Tcp Frame, framed by Message Size                                *)
(***************************************************************************)

ServerTcpFrame ==
    [ encodingType          : Sample(2),
      messageSequenceNumber : Sample(4),
      sendingTime           : Sample(8),
      serverMessage         : ServerMessage ]

EncodeServerTcpFrameBody(message) ==
    EncodeServerMessage(message.serverMessage)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeServerTcpFrame(message) ==
    LET body == EncodeServerTcpFrameBody(message)
    IN  message.encodingType \o message.messageSequenceNumber \o message.sendingTime \o EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeServerTcpFrame(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET messageSequenceNumber == ReadBytes(encodingType.rest, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET length == ReadUIntLE(sendingTime.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET serverMessage == DecodeServerMessage(framed) IN IF ~serverMessage.ok THEN Fail ELSE
    IF serverMessage.rest # << >> THEN Fail ELSE
    Ok([ encodingType          |-> encodingType.value,
         messageSequenceNumber |-> messageSequenceNumber.value,
         sendingTime           |-> sendingTime.value,
         serverMessage         |-> serverMessage.value ], beyond)

ZeroServerTcpFrame ==
    [ encodingType          |-> [i \in 1 .. 2 |-> 0],
      messageSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendingTime           |-> [i \in 1 .. 8 |-> 0],
      serverMessage         |-> ZeroServerMessage ]

(* Server Tcp Frame at zero, then each field in turn at the values it is checked at *)
CheckedServerTcpFrame ==
    { ZeroServerTcpFrame }
        \cup { [ZeroServerTcpFrame EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroServerTcpFrame EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroServerTcpFrame EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroServerTcpFrame EXCEPT !.serverMessage = one] : one \in CheckedServerMessage }

(* A run of Server Tcp Frame, written one after another *)
RECURSIVE EncodeServerTcpFrameList(_)
EncodeServerTcpFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerTcpFrame(Head(messages)) \o EncodeServerTcpFrameList(Tail(messages))

(* As many Server Tcp Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerTcpFrameAll(_)
ReadServerTcpFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerTcpFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerTcpFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Tcp Frame of each kind, for the lists that carry them *)
OneServerTcpFrame == { ZeroServerTcpFrame }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverTcpFrame : SampleLists(OneServerTcpFrame) ]

EncodeServerPacket(message) ==
    EncodeServerTcpFrameList(message.serverTcpFrame)

DecodeServerPacket(bytes) ==
    LET serverTcpFrame == ReadServerTcpFrameAll(bytes) IN IF ~serverTcpFrame.ok THEN Fail ELSE
    Ok([ serverTcpFrame |-> serverTcpFrame.value ], serverTcpFrame.rest)

ZeroServerPacket ==
    [ serverTcpFrame |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverTcpFrame = one] : one \in SampleLists(OneServerTcpFrame) }

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

(* Every Negotiation Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiationReject ==
    \A message \in CheckedNegotiationReject :
        LET read == DecodeNegotiationReject(EncodeNegotiationReject(message))
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

(* Every Terminate decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminate ==
    \A message \in CheckedTerminate :
        LET read == DecodeTerminate(EncodeTerminate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckSecurityGroup ==
    \A message \in CheckedRequestAckSecurityGroup :
        LET read == DecodeRequestAckSecurityGroup(EncodeRequestAckSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckSecurityGroups ==
    \A message \in CheckedRequestAckSecurityGroups :
        LET read == DecodeRequestAckSecurityGroups(EncodeRequestAckSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckRelatedSymbolGroup ==
    \A message \in CheckedRequestAckRelatedSymbolGroup :
        LET read == DecodeRequestAckRelatedSymbolGroup(EncodeRequestAckRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckRelatedSymbolGroups ==
    \A message \in CheckedRequestAckRelatedSymbolGroups :
        LET read == DecodeRequestAckRelatedSymbolGroups(EncodeRequestAckRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAck ==
    \A message \in CheckedRequestAck :
        LET read == DecodeRequestAck(EncodeRequestAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestReject ==
    \A message \in CheckedRequestReject :
        LET read == DecodeRequestReject(EncodeRequestReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerMessage ==
    \A message \in CheckedServerMessage :
        LET read == DecodeServerMessage(EncodeServerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Tcp Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripServerTcpFrame ==
    \A message \in CheckedServerTcpFrame :
        LET read == DecodeServerTcpFrame(EncodeServerTcpFrame(message))
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

(* Message Size is written from the bytes it frames *)
FramesServerTcpFrame ==
    \A message \in CheckedServerTcpFrame :
        LET bytes == EncodeServerTcpFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 15, 16)) = Len(bytes) - 14

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
