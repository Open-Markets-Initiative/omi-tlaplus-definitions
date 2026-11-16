---------------- MODULE Euronext_Optiq_MarketDataPacket_v1 -----------------
(***************************************************************************)
(* Euronext Market Data Packet v1                                          *)
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
(*                                                                         *)
(* Note: a Compression of any value but 1 says nothing transformed Optiq   *)
(* Message, which is then read as it stands.                               *)
(*                                                                         *)
(* Note: Compression is one bit of Packet Flags, which is read as the      *)
(* number it is: the bit says whether Optiq Message was transformed, so it *)
(* is the choice's own, and the record keeps the rest of the bits. The     *)
(* byte is written from the two together, so every bit of it is stated     *)
(* once.                                                                   *)
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
(* Optiq Message                                                           *)
(***************************************************************************)

OptiqMessageLz4 ==
    [ transformed : SampleBytes ]

EncodeOptiqMessageLz4(message) ==
    message.transformed

DecodeOptiqMessageLz4(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroOptiqMessageLz4 ==
    [ transformed |-> << >> ]

(* Optiq Message at zero, then each field in turn at the values it is checked at *)
CheckedOptiqMessageLz4 ==
    { ZeroOptiqMessageLz4 }
        \cup { [ZeroOptiqMessageLz4 EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Message Header: 8 bytes                                                 *)
(***************************************************************************)

MessageHeader ==
    [ blockLength : Sample(2),
      templateId  : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2) ]

EncodeMessageHeader(message) ==
    message.blockLength
        \o message.templateId
        \o message.schemaId
        \o message.version

DecodeMessageHeader(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadBytes(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         templateId  |-> templateId.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value ], version.rest)

ZeroMessageHeader ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      templateId  |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0] ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader ==
    { ZeroMessageHeader }
        \cup { [ZeroMessageHeader EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.templateId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.version = one] : one \in Sample(2) }

(***************************************************************************)
(* Optiq Message, framed by Frame                                          *)
(***************************************************************************)

OptiqMessage ==
    [ messageHeader : MessageHeader,
      payload       : SampleBytes ]

EncodeOptiqMessageBody(message) ==
    EncodeMessageHeader(message.messageHeader)
        \o message.payload

(* Frame counts the bytes it frames, so it is written from them *)
EncodeOptiqMessage(message) ==
    LET body == EncodeOptiqMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeOptiqMessageBody(bytes) ==
    LET messageHeader == DecodeMessageHeader(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET payload == Ok(messageHeader.rest, << >>) IN IF ~payload.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value,
         payload       |-> payload.value ], payload.rest)

DecodeOptiqMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeOptiqMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOptiqMessage ==
    [ messageHeader |-> ZeroMessageHeader,
      payload       |-> << >> ]

(* Optiq Message at zero, then each field in turn at the values it is checked at *)
CheckedOptiqMessage ==
    { ZeroOptiqMessage }
        \cup { [ZeroOptiqMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader }
        \cup { [ZeroOptiqMessage EXCEPT !.payload = one] : one \in SampleBytes }

(***************************************************************************)
(* Optiq Message, selected by Compression                                  *)
(***************************************************************************)

(* Compression is the lowest bit of Packet Flags, read as the number that set is. *)
(* CompressionOf is the key, PacketFlagsBeyond the bits beside it, PacketFlagsWith the two together. *)
CompressionOf(packetFlags) == packetFlags % 2
PacketFlagsBeyond(packetFlags) == packetFlags - CompressionOf(packetFlags)
PacketFlagsWith(beyond, compression) == beyond + compression

OptiqMessageLz4Code == 1  \* 0x01
OptiqMessagePlainCode == 0  \* stands for every value no other case names

OptiqMessageBody2 ==
    [ tag : {OptiqMessageLz4Code}, body : OptiqMessageLz4 ]
        \cup [ tag : (0 .. 1) \ {OptiqMessageLz4Code}, body : OptiqMessage ]

EncodeOptiqMessageBody2(message) ==
    CASE message.tag = OptiqMessageLz4Code -> EncodeOptiqMessageLz4(message.body)
      [] OTHER -> EncodeOptiqMessage(message.body)

DecodeOptiqMessageBody2(tag, bytes) ==
    LET read ==
            CASE tag = OptiqMessageLz4Code -> DecodeOptiqMessageLz4(bytes)
              [] OTHER -> DecodeOptiqMessage(bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOptiqMessageBody2 == [tag |-> OptiqMessageLz4Code, body |-> ZeroOptiqMessageLz4]

(* Each Optiq Message in turn, at the values the message it names is checked at *)
CheckedOptiqMessageBody2 ==
    { [tag |-> OptiqMessageLz4Code, body |-> one] : one \in CheckedOptiqMessageLz4 }
        \cup [ tag : {0, 1} \ {OptiqMessageLz4Code}, body : CheckedOptiqMessage ]

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetTime           : Sample(8),
      packetSequenceNumber : Sample(4),
      packetFlagsBeyond    : { PacketFlagsBeyond(bits) : bits \in 0 .. 255 },
      channelId            : Sample(2),
      optiqMessage         : OptiqMessageBody2 ]

EncodePacket(message) ==
    message.packetTime
        \o message.packetSequenceNumber
        \o EncodeUIntLE(PacketFlagsWith(message.packetFlagsBeyond, message.optiqMessage.tag), 2)
        \o message.channelId
        \o EncodeOptiqMessageBody2(message.optiqMessage)

DecodePacket(bytes) ==
    LET packetTime == ReadBytes(bytes, 8) IN IF ~packetTime.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetTime.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET packetFlags == ReadUIntLE(packetSequenceNumber.rest, 2) IN IF ~packetFlags.ok THEN Fail ELSE
    LET channelId == ReadBytes(packetFlags.rest, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET optiqMessage == DecodeOptiqMessageBody2(CompressionOf(packetFlags.value), channelId.rest) IN IF ~optiqMessage.ok THEN Fail ELSE
    Ok([ packetTime           |-> packetTime.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         packetFlagsBeyond    |-> PacketFlagsBeyond(packetFlags.value),
         channelId            |-> channelId.value,
         optiqMessage         |-> optiqMessage.value ], optiqMessage.rest)

ZeroPacket ==
    [ packetTime           |-> [i \in 1 .. 8 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      packetFlagsBeyond    |-> 0,
      channelId            |-> [i \in 1 .. 2 |-> 0],
      optiqMessage         |-> ZeroOptiqMessageBody2 ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.packetFlagsBeyond = one] : one \in { PacketFlagsBeyond(bits) : bits \in {0, 1, 255} } }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.optiqMessage = one] : one \in CheckedOptiqMessageBody2 }

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

(* Every Optiq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptiqMessageLz4 ==
    \A message \in CheckedOptiqMessageLz4 :
        LET read == DecodeOptiqMessageLz4(EncodeOptiqMessageLz4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader ==
    \A message \in CheckedMessageHeader :
        LET read == DecodeMessageHeader(EncodeMessageHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Optiq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptiqMessage ==
    \A message \in CheckedOptiqMessage :
        LET read == DecodeOptiqMessage(EncodeOptiqMessage(message))
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

(* A Optiq Message is selected by the Compression it is written under *)
SelectsOptiqMessageBody2 ==
    \A message \in CheckedOptiqMessageBody2 :
        LET sent == EncodeOptiqMessageBody2(message)
            read == DecodeOptiqMessageBody2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Frame is written from the bytes it frames *)
FramesOptiqMessage ==
    \A message \in CheckedOptiqMessage :
        LET bytes == EncodeOptiqMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
