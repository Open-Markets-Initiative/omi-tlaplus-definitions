-------------------- MODULE NseCom_DropCopy_v1_5_Client --------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Drop Copy v1.5                     *)
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
(* Signon In Message: 238 bytes                                            *)
(***************************************************************************)

SignonInMessage ==
    [ userId           : Sample(4),
      reserved8        : Sample(8),
      password         : Sample(8),
      secondReserved8  : Sample(8),
      reserved38       : Sample(38),
      brokerId         : Sample(5),
      reserved119      : Sample(119),
      reserved16       : Sample(16),
      secondReserved16 : Sample(16),
      thirdReserved16  : Sample(16) ]

EncodeSignonInMessage(message) ==
    message.userId
        \o message.reserved8
        \o message.password
        \o message.secondReserved8
        \o message.reserved38
        \o message.brokerId
        \o message.reserved119
        \o message.reserved16
        \o message.secondReserved16
        \o message.thirdReserved16

DecodeSignonInMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(userId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET password == ReadBytes(reserved8.rest, 8) IN IF ~password.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(password.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET reserved38 == ReadBytes(secondReserved8.rest, 38) IN IF ~reserved38.ok THEN Fail ELSE
    LET brokerId == ReadBytes(reserved38.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved119 == ReadBytes(brokerId.rest, 119) IN IF ~reserved119.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(reserved119.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET secondReserved16 == ReadBytes(reserved16.rest, 16) IN IF ~secondReserved16.ok THEN Fail ELSE
    LET thirdReserved16 == ReadBytes(secondReserved16.rest, 16) IN IF ~thirdReserved16.ok THEN Fail ELSE
    Ok([ userId           |-> userId.value,
         reserved8        |-> reserved8.value,
         password         |-> password.value,
         secondReserved8  |-> secondReserved8.value,
         reserved38       |-> reserved38.value,
         brokerId         |-> brokerId.value,
         reserved119      |-> reserved119.value,
         reserved16       |-> reserved16.value,
         secondReserved16 |-> secondReserved16.value,
         thirdReserved16  |-> thirdReserved16.value ], thirdReserved16.rest)

ZeroSignonInMessage ==
    [ userId           |-> [i \in 1 .. 4 |-> 0],
      reserved8        |-> [i \in 1 .. 8 |-> 0],
      password         |-> [i \in 1 .. 8 |-> 0],
      secondReserved8  |-> [i \in 1 .. 8 |-> 0],
      reserved38       |-> [i \in 1 .. 38 |-> 0],
      brokerId         |-> [i \in 1 .. 5 |-> 0],
      reserved119      |-> [i \in 1 .. 119 |-> 0],
      reserved16       |-> [i \in 1 .. 16 |-> 0],
      secondReserved16 |-> [i \in 1 .. 16 |-> 0],
      thirdReserved16  |-> [i \in 1 .. 16 |-> 0] ]

(* Signon In Message at zero, then each field in turn at the values it is checked at *)
CheckedSignonInMessage ==
    { ZeroSignonInMessage }
        \cup { [ZeroSignonInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroSignonInMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignonInMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroSignonInMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignonInMessage EXCEPT !.reserved38 = one] : one \in Sample(38) }
        \cup { [ZeroSignonInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroSignonInMessage EXCEPT !.reserved119 = one] : one \in Sample(119) }
        \cup { [ZeroSignonInMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignonInMessage EXCEPT !.secondReserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignonInMessage EXCEPT !.thirdReserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Dc Download Request Message: 8 bytes                                    *)
(***************************************************************************)

DcDownloadRequestMessage ==
    [ sequenceNumber : Sample(8) ]

EncodeDcDownloadRequestMessage(message) ==
    message.sequenceNumber

DecodeDcDownloadRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroDcDownloadRequestMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Dc Download Request Message at zero, then each field in turn at the values it is checked at *)
CheckedDcDownloadRequestMessage ==
    { ZeroDcDownloadRequestMessage }
        \cup { [ZeroDcDownloadRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Client Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

SignonInMessageCode == 2300  \* 0x8fc
HeartbeatMessageCode == 23506  \* 0x5bd2
DcDownloadRequestMessageCode == 8000  \* 0x1f40

ClientMessagePayload ==
    [ tag : {SignonInMessageCode}, body : SignonInMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {DcDownloadRequestMessageCode}, body : DcDownloadRequestMessage ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = SignonInMessageCode -> EncodeSignonInMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = DcDownloadRequestMessageCode -> EncodeDcDownloadRequestMessage(message.body)

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = SignonInMessageCode -> DecodeSignonInMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = DcDownloadRequestMessageCode -> DecodeDcDownloadRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> SignonInMessageCode, body |-> ZeroSignonInMessage]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> SignonInMessageCode, body |-> one] : one \in CheckedSignonInMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> DcDownloadRequestMessageCode, body |-> one] : one \in CheckedDcDownloadRequestMessage }

(***************************************************************************)
(* Client Direct Packet, framed by Packet Length                           *)
(***************************************************************************)

ClientDirectPacket ==
    [ packetSequenceNumber : Sample(4),
      checksum             : Sample(16),
      logTime              : Sample(4),
      alphaChar            : Sample(2),
      traderId             : Sample(4),
      errorCode            : Sample(2),
      headerTimestamp      : Sample(8),
      timeStamp1           : Sample(8),
      timeStamp2           : Sample(8),
      messageLength        : Sample(2),
      clientMessagePayload : ClientMessagePayload ]

EncodeClientDirectPacketBody(message) ==
    message.packetSequenceNumber
        \o message.checksum
        \o EncodeUIntBE(message.clientMessagePayload.tag, 2)
        \o message.logTime
        \o message.alphaChar
        \o message.traderId
        \o message.errorCode
        \o message.headerTimestamp
        \o message.timeStamp1
        \o message.timeStamp2
        \o message.messageLength
        \o EncodeClientMessagePayload(message.clientMessagePayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientDirectPacket(message) ==
    LET body == EncodeClientDirectPacketBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeClientDirectPacketBody(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET checksum == ReadBytes(packetSequenceNumber.rest, 16) IN IF ~checksum.ok THEN Fail ELSE
    LET transactionCode == ReadUIntBE(checksum.rest, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET alphaChar == ReadBytes(logTime.rest, 2) IN IF ~alphaChar.ok THEN Fail ELSE
    LET traderId == ReadBytes(alphaChar.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(traderId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET headerTimestamp == ReadBytes(errorCode.rest, 8) IN IF ~headerTimestamp.ok THEN Fail ELSE
    LET timeStamp1 == ReadBytes(headerTimestamp.rest, 8) IN IF ~timeStamp1.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1.rest, 8) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET messageLength == ReadBytes(timeStamp2.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET clientMessagePayload == DecodeClientMessagePayload(transactionCode.value, messageLength.rest) IN IF ~clientMessagePayload.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         checksum             |-> checksum.value,
         logTime              |-> logTime.value,
         alphaChar            |-> alphaChar.value,
         traderId             |-> traderId.value,
         errorCode            |-> errorCode.value,
         headerTimestamp      |-> headerTimestamp.value,
         timeStamp1           |-> timeStamp1.value,
         timeStamp2           |-> timeStamp2.value,
         messageLength        |-> messageLength.value,
         clientMessagePayload |-> clientMessagePayload.value ], clientMessagePayload.rest)

DecodeClientDirectPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientDirectPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientDirectPacket ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      checksum             |-> [i \in 1 .. 16 |-> 0],
      logTime              |-> [i \in 1 .. 4 |-> 0],
      alphaChar            |-> [i \in 1 .. 2 |-> 0],
      traderId             |-> [i \in 1 .. 4 |-> 0],
      errorCode            |-> [i \in 1 .. 2 |-> 0],
      headerTimestamp      |-> [i \in 1 .. 8 |-> 0],
      timeStamp1           |-> [i \in 1 .. 8 |-> 0],
      timeStamp2           |-> [i \in 1 .. 8 |-> 0],
      messageLength        |-> [i \in 1 .. 2 |-> 0],
      clientMessagePayload |-> ZeroClientMessagePayload ]

(* Client Direct Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientDirectPacket ==
    { ZeroClientDirectPacket }
        \cup { [ZeroClientDirectPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientDirectPacket EXCEPT !.checksum = one] : one \in Sample(16) }
        \cup { [ZeroClientDirectPacket EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroClientDirectPacket EXCEPT !.alphaChar = one] : one \in Sample(2) }
        \cup { [ZeroClientDirectPacket EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroClientDirectPacket EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroClientDirectPacket EXCEPT !.headerTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClientDirectPacket EXCEPT !.timeStamp1 = one] : one \in Sample(8) }
        \cup { [ZeroClientDirectPacket EXCEPT !.timeStamp2 = one] : one \in Sample(8) }
        \cup { [ZeroClientDirectPacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = one] : one \in CheckedClientMessagePayload }

(* A run of Client Direct Packet, written one after another *)
RECURSIVE EncodeClientDirectPacketList(_)
EncodeClientDirectPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientDirectPacket(Head(messages)) \o EncodeClientDirectPacketList(Tail(messages))

(* As many Client Direct Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientDirectPacketAll(_)
ReadClientDirectPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientDirectPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientDirectPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Direct Packet of each kind, for the lists that carry them *)
OneClientDirectPacket ==
    { [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SignonInMessageCode, body |-> ZeroSignonInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> DcDownloadRequestMessageCode, body |-> ZeroDcDownloadRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientDirectPacket : SampleLists(OneClientDirectPacket) ]

EncodeClientPacket(message) ==
    EncodeClientDirectPacketList(message.clientDirectPacket)

DecodeClientPacket(bytes) ==
    LET clientDirectPacket == ReadClientDirectPacketAll(bytes) IN IF ~clientDirectPacket.ok THEN Fail ELSE
    Ok([ clientDirectPacket |-> clientDirectPacket.value ], clientDirectPacket.rest)

ZeroClientPacket ==
    [ clientDirectPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientDirectPacket = one] : one \in SampleLists(OneClientDirectPacket) }

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

(* Every Signon In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSignonInMessage ==
    \A message \in CheckedSignonInMessage :
        LET read == DecodeSignonInMessage(EncodeSignonInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Download Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcDownloadRequestMessage ==
    \A message \in CheckedDcDownloadRequestMessage :
        LET read == DecodeDcDownloadRequestMessage(EncodeDcDownloadRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Direct Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientDirectPacket ==
    \A message \in CheckedClientDirectPacket :
        LET read == DecodeClientDirectPacket(EncodeClientDirectPacket(message))
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
FramesClientDirectPacket ==
    \A message \in CheckedClientDirectPacket :
        LET bytes == EncodeClientDirectPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
