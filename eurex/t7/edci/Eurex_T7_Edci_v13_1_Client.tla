-------------------- MODULE Eurex_T7_Edci_v13_1_Client ---------------------
(***************************************************************************)
(* Eurex Exchange Extended Derivatives Clearing Interface v13.1            *)
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
(* Note: Heartbeat fills what is left of the frame Body Len states, which  *)
(* is what it is read from.                                                *)
(*                                                                         *)
(* Note: Logon Request fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Logout Request fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
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
(* Heartbeat: 2 bytes                                                      *)
(***************************************************************************)

Heartbeat ==
    [ pad2 : Sample(2) ]

EncodeHeartbeat(message) ==
    message.pad2

DecodeHeartbeat(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ pad2 |-> pad2.value ], pad2.rest)

ZeroHeartbeat ==
    [ pad2 |-> [i \in 1 .. 2 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp ==
    [ msgSeqNum : Sample(4),
      pad4      : Sample(4) ]

EncodeRequestHeaderComp(message) ==
    message.msgSeqNum
        \o message.pad4

DecodeRequestHeaderComp(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ msgSeqNum |-> msgSeqNum.value,
         pad4      |-> pad4.value ], pad4.rest)

ZeroRequestHeaderComp ==
    [ msgSeqNum |-> [i \in 1 .. 4 |-> 0],
      pad4      |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp ==
    { ZeroRequestHeaderComp }
        \cup { [ZeroRequestHeaderComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Request: 82 bytes                                                 *)
(***************************************************************************)

LogonRequest ==
    [ pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp,
      heartBtInt           : Sample(4),
      partyIdSessionId     : Sample(4),
      defaultCstmApplVerId : Sample(30),
      password             : Sample(32),
      pad2v2               : Sample(2) ]

EncodeLogonRequest(message) ==
    message.pad2
        \o EncodeRequestHeaderComp(message.requestHeaderComp)
        \o message.heartBtInt
        \o message.partyIdSessionId
        \o message.defaultCstmApplVerId
        \o message.password
        \o message.pad2v2

DecodeLogonRequest(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(requestHeaderComp.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(heartBtInt.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(partyIdSessionId.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET password == ReadBytes(defaultCstmApplVerId.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(password.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2                 |-> pad2.value,
         requestHeaderComp    |-> requestHeaderComp.value,
         heartBtInt           |-> heartBtInt.value,
         partyIdSessionId     |-> partyIdSessionId.value,
         defaultCstmApplVerId |-> defaultCstmApplVerId.value,
         password             |-> password.value,
         pad2v2               |-> pad2v2.value ], pad2v2.rest)

ZeroLogonRequest ==
    [ pad2                 |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp    |-> ZeroRequestHeaderComp,
      heartBtInt           |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId     |-> [i \in 1 .. 4 |-> 0],
      defaultCstmApplVerId |-> [i \in 1 .. 30 |-> 0],
      password             |-> [i \in 1 .. 32 |-> 0],
      pad2v2               |-> [i \in 1 .. 2 |-> 0] ]

(* Logon Request at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequest ==
    { ZeroLogonRequest }
        \cup { [ZeroLogonRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp }
        \cup { [ZeroLogonRequest EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequest EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequest EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroLogonRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp2 ==
    [ msgSeqNum : Sample(4),
      pad4      : Sample(4) ]

EncodeRequestHeaderComp2(message) ==
    message.msgSeqNum
        \o message.pad4

DecodeRequestHeaderComp2(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ msgSeqNum |-> msgSeqNum.value,
         pad4      |-> pad4.value ], pad4.rest)

ZeroRequestHeaderComp2 ==
    [ msgSeqNum |-> [i \in 1 .. 4 |-> 0],
      pad4      |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp2 ==
    { ZeroRequestHeaderComp2 }
        \cup { [ZeroRequestHeaderComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Request: 10 bytes                                                *)
(***************************************************************************)

LogoutRequest ==
    [ pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp2 ]

EncodeLogoutRequest(message) ==
    message.pad2
        \o EncodeRequestHeaderComp2(message.requestHeaderComp)

DecodeLogoutRequest(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp2(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroLogoutRequest ==
    [ pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp2 ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp2 }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

HeartbeatCode == 10011  \* 0x271b
LogonRequestCode == 10000  \* 0x2710
LogoutRequestCode == 10002  \* 0x2712

ClientPayload ==
    [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {LogonRequestCode}, body : LogonRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]

EncodeClientPayload(message) ==
    CASE message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = LogonRequestCode -> EncodeLogonRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = LogonRequestCode -> DecodeLogonRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> LogonRequestCode, body |-> one] : one \in CheckedLogonRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }

(***************************************************************************)
(* Client Message, framed by Body Len                                      *)
(***************************************************************************)

ClientMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientMessageBody(message) ==
    EncodeUIntLE(message.clientPayload.tag, 2)
        \o EncodeClientPayload(message.clientPayload)

(* Body Len counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 4, 4) \o body

DecodeClientMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, templateId.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 4) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogonRequestCode, body |-> ZeroLogonRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp ==
    \A message \in CheckedRequestHeaderComp :
        LET read == DecodeRequestHeaderComp(EncodeRequestHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequest ==
    \A message \in CheckedLogonRequest :
        LET read == DecodeLogonRequest(EncodeLogonRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp2 ==
    \A message \in CheckedRequestHeaderComp2 :
        LET read == DecodeRequestHeaderComp2(EncodeRequestHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* Body Len is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
