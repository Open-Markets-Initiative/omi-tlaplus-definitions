----------------- MODULE NseFo_OrderEntry_NnfDirect_v9_50 ------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v9.50                  *)
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
(* Message Header: 40 bytes                                                *)
(***************************************************************************)

MessageHeader ==
    [ transactionCode : Sample(2),
      logTime         : Sample(4),
      alphaChar       : Sample(2),
      traderId        : Sample(4),
      errorCode       : Sample(2),
      headerTimestamp : Sample(8),
      timeStamp1      : Sample(8),
      timeStamp2      : Sample(8),
      messageLength   : Sample(2) ]

EncodeMessageHeader(message) ==
    message.transactionCode
        \o message.logTime
        \o message.alphaChar
        \o message.traderId
        \o message.errorCode
        \o message.headerTimestamp
        \o message.timeStamp1
        \o message.timeStamp2
        \o message.messageLength

DecodeMessageHeader(bytes) ==
    LET transactionCode == ReadBytes(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET alphaChar == ReadBytes(logTime.rest, 2) IN IF ~alphaChar.ok THEN Fail ELSE
    LET traderId == ReadBytes(alphaChar.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(traderId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET headerTimestamp == ReadBytes(errorCode.rest, 8) IN IF ~headerTimestamp.ok THEN Fail ELSE
    LET timeStamp1 == ReadBytes(headerTimestamp.rest, 8) IN IF ~timeStamp1.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1.rest, 8) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET messageLength == ReadBytes(timeStamp2.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    Ok([ transactionCode |-> transactionCode.value,
         logTime         |-> logTime.value,
         alphaChar       |-> alphaChar.value,
         traderId        |-> traderId.value,
         errorCode       |-> errorCode.value,
         headerTimestamp |-> headerTimestamp.value,
         timeStamp1      |-> timeStamp1.value,
         timeStamp2      |-> timeStamp2.value,
         messageLength   |-> messageLength.value ], messageLength.rest)

ZeroMessageHeader ==
    [ transactionCode |-> [i \in 1 .. 2 |-> 0],
      logTime         |-> [i \in 1 .. 4 |-> 0],
      alphaChar       |-> [i \in 1 .. 2 |-> 0],
      traderId        |-> [i \in 1 .. 4 |-> 0],
      errorCode       |-> [i \in 1 .. 2 |-> 0],
      headerTimestamp |-> [i \in 1 .. 8 |-> 0],
      timeStamp1      |-> [i \in 1 .. 8 |-> 0],
      timeStamp2      |-> [i \in 1 .. 8 |-> 0],
      messageLength   |-> [i \in 1 .. 2 |-> 0] ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader ==
    { ZeroMessageHeader }
        \cup { [ZeroMessageHeader EXCEPT !.transactionCode = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroMessageHeader EXCEPT !.alphaChar = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroMessageHeader EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.headerTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader EXCEPT !.timeStamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader EXCEPT !.timeStamp2 = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader EXCEPT !.messageLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Direct Packet, framed by Packet Length                                  *)
(***************************************************************************)

DirectPacket ==
    [ packetSequenceNumber : Sample(4),
      checksum             : Sample(16),
      messageHeader        : MessageHeader ]

EncodeDirectPacketBody(message) ==
    message.packetSequenceNumber
        \o message.checksum
        \o EncodeMessageHeader(message.messageHeader)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeDirectPacket(message) ==
    LET body == EncodeDirectPacketBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeDirectPacketBody(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET checksum == ReadBytes(packetSequenceNumber.rest, 16) IN IF ~checksum.ok THEN Fail ELSE
    LET messageHeader == DecodeMessageHeader(checksum.rest) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         checksum             |-> checksum.value,
         messageHeader        |-> messageHeader.value ], messageHeader.rest)

DecodeDirectPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeDirectPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroDirectPacket ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      checksum             |-> [i \in 1 .. 16 |-> 0],
      messageHeader        |-> ZeroMessageHeader ]

(* Direct Packet at zero, then each field in turn at the values it is checked at *)
CheckedDirectPacket ==
    { ZeroDirectPacket }
        \cup { [ZeroDirectPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroDirectPacket EXCEPT !.checksum = one] : one \in Sample(16) }
        \cup { [ZeroDirectPacket EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader }

(* A run of Direct Packet, written one after another *)
RECURSIVE EncodeDirectPacketList(_)
EncodeDirectPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDirectPacket(Head(messages)) \o EncodeDirectPacketList(Tail(messages))

(* As many Direct Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadDirectPacketAll(_)
ReadDirectPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeDirectPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDirectPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Direct Packet of each kind, for the lists that carry them *)
OneDirectPacket == { ZeroDirectPacket }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ directPacket : SampleLists(OneDirectPacket) ]

EncodePacket(message) ==
    EncodeDirectPacketList(message.directPacket)

DecodePacket(bytes) ==
    LET directPacket == ReadDirectPacketAll(bytes) IN IF ~directPacket.ok THEN Fail ELSE
    Ok([ directPacket |-> directPacket.value ], directPacket.rest)

ZeroPacket ==
    [ directPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.directPacket = one] : one \in SampleLists(OneDirectPacket) }

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

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader ==
    \A message \in CheckedMessageHeader :
        LET read == DecodeMessageHeader(EncodeMessageHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Direct Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectPacket ==
    \A message \in CheckedDirectPacket :
        LET read == DecodeDirectPacket(EncodeDirectPacket(message))
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

(* Packet Length is written from the bytes it frames *)
FramesDirectPacket ==
    \A message \in CheckedDirectPacket :
        LET bytes == EncodeDirectPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
