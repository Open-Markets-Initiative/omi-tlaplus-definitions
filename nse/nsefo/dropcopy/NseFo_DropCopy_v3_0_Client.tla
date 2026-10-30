-------------------- MODULE NseFo_DropCopy_v3_0_Client ---------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Drop Copy v3.0                     *)
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
(* Dc Signon In Message: 16 bytes                                          *)
(***************************************************************************)

DcSignonInMessage ==
    [ password   : Sample(8),
      sessionKey : Sample(8) ]

EncodeDcSignonInMessage(message) ==
    message.password
        \o message.sessionKey

DecodeDcSignonInMessage(bytes) ==
    LET password == ReadBytes(bytes, 8) IN IF ~password.ok THEN Fail ELSE
    LET sessionKey == ReadBytes(password.rest, 8) IN IF ~sessionKey.ok THEN Fail ELSE
    Ok([ password   |-> password.value,
         sessionKey |-> sessionKey.value ], sessionKey.rest)

ZeroDcSignonInMessage ==
    [ password   |-> [i \in 1 .. 8 |-> 0],
      sessionKey |-> [i \in 1 .. 8 |-> 0] ]

(* Dc Signon In Message at zero, then each field in turn at the values it is checked at *)
CheckedDcSignonInMessage ==
    { ZeroDcSignonInMessage }
        \cup { [ZeroDcSignonInMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroDcSignonInMessage EXCEPT !.sessionKey = one] : one \in Sample(8) }

(***************************************************************************)
(* Dc Trd Subscription Request Message: 8 bytes                            *)
(***************************************************************************)

DcTrdSubscriptionRequestMessage ==
    [ sequenceNumber : Sample(8) ]

EncodeDcTrdSubscriptionRequestMessage(message) ==
    message.sequenceNumber

DecodeDcTrdSubscriptionRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroDcTrdSubscriptionRequestMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Dc Trd Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedDcTrdSubscriptionRequestMessage ==
    { ZeroDcTrdSubscriptionRequestMessage }
        \cup { [ZeroDcTrdSubscriptionRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Dc Ont Subscription Request Message: 8 bytes                            *)
(***************************************************************************)

DcOntSubscriptionRequestMessage ==
    [ sequenceNumber : Sample(8) ]

EncodeDcOntSubscriptionRequestMessage(message) ==
    message.sequenceNumber

DecodeDcOntSubscriptionRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroDcOntSubscriptionRequestMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Dc Ont Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedDcOntSubscriptionRequestMessage ==
    { ZeroDcOntSubscriptionRequestMessage }
        \cup { [ZeroDcOntSubscriptionRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Client Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

GrRequestMessageCode == 2400  \* 0x960
GrSecureUserRegistrationRequestMessageCode == 23008  \* 0x59e0
HeartbeatMessageCode == 23506  \* 0x5bd2
DcSignonInMessageCode == 2500  \* 0x9c4
DcTrdSubscriptionRequestMessageCode == 8000  \* 0x1f40
DcOntSubscriptionRequestMessageCode == 9000  \* 0x2328

ClientMessagePayload ==
    [ tag : {GrRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {GrSecureUserRegistrationRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {DcSignonInMessageCode}, body : DcSignonInMessage ]
        \cup [ tag : {DcTrdSubscriptionRequestMessageCode}, body : DcTrdSubscriptionRequestMessage ]
        \cup [ tag : {DcOntSubscriptionRequestMessageCode}, body : DcOntSubscriptionRequestMessage ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = GrRequestMessageCode -> << >>
      [] message.tag = GrSecureUserRegistrationRequestMessageCode -> << >>
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = DcSignonInMessageCode -> EncodeDcSignonInMessage(message.body)
      [] message.tag = DcTrdSubscriptionRequestMessageCode -> EncodeDcTrdSubscriptionRequestMessage(message.body)
      [] message.tag = DcOntSubscriptionRequestMessageCode -> EncodeDcOntSubscriptionRequestMessage(message.body)

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GrRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = GrSecureUserRegistrationRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = DcSignonInMessageCode -> DecodeDcSignonInMessage(bytes)
              [] tag = DcTrdSubscriptionRequestMessageCode -> DecodeDcTrdSubscriptionRequestMessage(bytes)
              [] tag = DcOntSubscriptionRequestMessageCode -> DecodeDcOntSubscriptionRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> GrRequestMessageCode, body |-> [empty |-> 0]]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> GrRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> GrSecureUserRegistrationRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> DcSignonInMessageCode, body |-> one] : one \in CheckedDcSignonInMessage }
        \cup { [tag |-> DcTrdSubscriptionRequestMessageCode, body |-> one] : one \in CheckedDcTrdSubscriptionRequestMessage }
        \cup { [tag |-> DcOntSubscriptionRequestMessageCode, body |-> one] : one \in CheckedDcOntSubscriptionRequestMessage }

(***************************************************************************)
(* Client Drop Copy Packet, framed by Packet Length                        *)
(***************************************************************************)

ClientDropCopyPacket ==
    [ packetSequenceNumber  : Sample(4),
      checksum              : Sample(16),
      traderId              : Sample(4),
      requestSequenceNumber : Sample(8),
      partitionId           : Sample(6),
      concurrentLoginId     : Sample(2),
      funcIndc              : Sample(1),
      reserve               : Sample(1),
      clientMessagePayload  : ClientMessagePayload ]

EncodeClientDropCopyPacketBody(message) ==
    message.packetSequenceNumber
        \o message.checksum
        \o EncodeUIntBE(message.clientMessagePayload.tag, 2)
        \o message.traderId
        \o message.requestSequenceNumber
        \o message.partitionId
        \o message.concurrentLoginId
        \o message.funcIndc
        \o message.reserve
        \o EncodeClientMessagePayload(message.clientMessagePayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientDropCopyPacket(message) ==
    LET body == EncodeClientDropCopyPacketBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeClientDropCopyPacketBody(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET checksum == ReadBytes(packetSequenceNumber.rest, 16) IN IF ~checksum.ok THEN Fail ELSE
    LET transactionCode == ReadUIntBE(checksum.rest, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET traderId == ReadBytes(transactionCode.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET requestSequenceNumber == ReadBytes(traderId.rest, 8) IN IF ~requestSequenceNumber.ok THEN Fail ELSE
    LET partitionId == ReadBytes(requestSequenceNumber.rest, 6) IN IF ~partitionId.ok THEN Fail ELSE
    LET concurrentLoginId == ReadBytes(partitionId.rest, 2) IN IF ~concurrentLoginId.ok THEN Fail ELSE
    LET funcIndc == ReadBytes(concurrentLoginId.rest, 1) IN IF ~funcIndc.ok THEN Fail ELSE
    LET reserve == ReadBytes(funcIndc.rest, 1) IN IF ~reserve.ok THEN Fail ELSE
    LET clientMessagePayload == DecodeClientMessagePayload(transactionCode.value, reserve.rest) IN IF ~clientMessagePayload.ok THEN Fail ELSE
    Ok([ packetSequenceNumber  |-> packetSequenceNumber.value,
         checksum              |-> checksum.value,
         traderId              |-> traderId.value,
         requestSequenceNumber |-> requestSequenceNumber.value,
         partitionId           |-> partitionId.value,
         concurrentLoginId     |-> concurrentLoginId.value,
         funcIndc              |-> funcIndc.value,
         reserve               |-> reserve.value,
         clientMessagePayload  |-> clientMessagePayload.value ], clientMessagePayload.rest)

DecodeClientDropCopyPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientDropCopyPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientDropCopyPacket ==
    [ packetSequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      checksum              |-> [i \in 1 .. 16 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      requestSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      partitionId           |-> [i \in 1 .. 6 |-> 0],
      concurrentLoginId     |-> [i \in 1 .. 2 |-> 0],
      funcIndc              |-> [i \in 1 .. 1 |-> 0],
      reserve               |-> [i \in 1 .. 1 |-> 0],
      clientMessagePayload  |-> ZeroClientMessagePayload ]

(* Client Drop Copy Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientDropCopyPacket ==
    { ZeroClientDropCopyPacket }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.checksum = one] : one \in Sample(16) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.requestSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.partitionId = one] : one \in Sample(6) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.concurrentLoginId = one] : one \in Sample(2) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.funcIndc = one] : one \in Sample(1) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.reserve = one] : one \in Sample(1) }
        \cup { [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = one] : one \in CheckedClientMessagePayload }

(* A run of Client Drop Copy Packet, written one after another *)
RECURSIVE EncodeClientDropCopyPacketList(_)
EncodeClientDropCopyPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientDropCopyPacket(Head(messages)) \o EncodeClientDropCopyPacketList(Tail(messages))

(* As many Client Drop Copy Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientDropCopyPacketAll(_)
ReadClientDropCopyPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientDropCopyPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientDropCopyPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Drop Copy Packet of each kind, for the lists that carry them *)
OneClientDropCopyPacket ==
    { [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = [tag |-> GrRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = [tag |-> GrSecureUserRegistrationRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = [tag |-> DcSignonInMessageCode, body |-> ZeroDcSignonInMessage]],
      [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = [tag |-> DcTrdSubscriptionRequestMessageCode, body |-> ZeroDcTrdSubscriptionRequestMessage]],
      [ZeroClientDropCopyPacket EXCEPT !.clientMessagePayload = [tag |-> DcOntSubscriptionRequestMessageCode, body |-> ZeroDcOntSubscriptionRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientDropCopyPacket : SampleLists(OneClientDropCopyPacket) ]

EncodeClientPacket(message) ==
    EncodeClientDropCopyPacketList(message.clientDropCopyPacket)

DecodeClientPacket(bytes) ==
    LET clientDropCopyPacket == ReadClientDropCopyPacketAll(bytes) IN IF ~clientDropCopyPacket.ok THEN Fail ELSE
    Ok([ clientDropCopyPacket |-> clientDropCopyPacket.value ], clientDropCopyPacket.rest)

ZeroClientPacket ==
    [ clientDropCopyPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientDropCopyPacket = one] : one \in SampleLists(OneClientDropCopyPacket) }

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

(* Every Dc Signon In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcSignonInMessage ==
    \A message \in CheckedDcSignonInMessage :
        LET read == DecodeDcSignonInMessage(EncodeDcSignonInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Trd Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcTrdSubscriptionRequestMessage ==
    \A message \in CheckedDcTrdSubscriptionRequestMessage :
        LET read == DecodeDcTrdSubscriptionRequestMessage(EncodeDcTrdSubscriptionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Ont Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcOntSubscriptionRequestMessage ==
    \A message \in CheckedDcOntSubscriptionRequestMessage :
        LET read == DecodeDcOntSubscriptionRequestMessage(EncodeDcOntSubscriptionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Drop Copy Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientDropCopyPacket ==
    \A message \in CheckedClientDropCopyPacket :
        LET read == DecodeClientDropCopyPacket(EncodeClientDropCopyPacket(message))
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

(* A Client Message Payload is selected by the Transaction Code it is written under *)
SelectsClientMessagePayload ==
    \A message \in CheckedClientMessagePayload :
        LET read == DecodeClientMessagePayload(message.tag, EncodeClientMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientDropCopyPacket ==
    \A message \in CheckedClientDropCopyPacket :
        LET bytes == EncodeClientDropCopyPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
