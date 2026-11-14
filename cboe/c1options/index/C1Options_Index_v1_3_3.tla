---------------------- MODULE C1Options_Index_v1_3_3 -----------------------
(***************************************************************************)
(* Chicago Board Options Exchange Streaming Market Index v1.3.3            *)
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
(* Symbol                                                                  *)
(***************************************************************************)

Symbol ==
    [ symbolText : SampleBytes ]

EncodeSymbol(message) ==
    EncodeUIntBE(Len(message.symbolText), 1)
        \o message.symbolText

DecodeSymbol(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolText == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolText.ok THEN Fail ELSE
    Ok([ symbolText |-> symbolText.value ], symbolText.rest)

ZeroSymbol ==
    [ symbolText |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol ==
    { ZeroSymbol }
        \cup { [ZeroSymbol EXCEPT !.symbolText = one] : one \in SampleBytes }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx ==
    { ZeroMdEntryPx }
        \cup { [ZeroMdEntryPx EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entries: 6 bytes                                                     *)
(***************************************************************************)

MdEntries ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx ]

EncodeMdEntries(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx(message.mdEntryPx)

DecodeMdEntries(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroMdEntries ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx ]

(* Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedMdEntries ==
    { ZeroMdEntries }
        \cup { [ZeroMdEntries EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntries EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx }

(* A run of Md Entries, written one after another *)
RECURSIVE EncodeMdEntriesList(_)
EncodeMdEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntries(Head(messages)) \o EncodeMdEntriesList(Tail(messages))

(* As many Md Entries as the field that counts them says *)
RECURSIVE ReadMdEntriesList(_, _)
ReadMdEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entries of each kind, for the lists that carry them *)
OneMdEntries == { ZeroMdEntries }

(***************************************************************************)
(* Index Value Message                                                     *)
(***************************************************************************)

IndexValueMessage ==
    [ symbol    : Symbol,
      mdEntries : SampleLists(OneMdEntries) ]

EncodeIndexValueMessage(message) ==
    EncodeSymbol(message.symbol)
        \o EncodeUIntBE(Len(message.mdEntries), 1)
        \o EncodeMdEntriesList(message.mdEntries)

DecodeIndexValueMessage(bytes) ==
    LET symbol == DecodeSymbol(bytes) IN IF ~symbol.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(symbol.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntriesList(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    Ok([ symbol    |-> symbol.value,
         mdEntries |-> mdEntries.value ], mdEntries.rest)

ZeroIndexValueMessage ==
    [ symbol    |-> ZeroSymbol,
      mdEntries |-> << >> ]

(* Index Value Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueMessage ==
    { ZeroIndexValueMessage }
        \cup { [ZeroIndexValueMessage EXCEPT !.symbol = one] : one \in CheckedSymbol }
        \cup { [ZeroIndexValueMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

IndexValueMessageCode == 22  \* 0x16
HeartbeatMessageCode == 16  \* 0x10

Payload ==
    [ tag : {IndexValueMessageCode}, body : IndexValueMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = IndexValueMessageCode -> EncodeIndexValueMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = IndexValueMessageCode -> DecodeIndexValueMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> IndexValueMessageCode, body |-> ZeroIndexValueMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> IndexValueMessageCode, body |-> one] : one \in CheckedIndexValueMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ messageType : Sample(1),
      msgSeqNum   : Sample(4),
      payload     : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o message.messageType
        \o message.msgSeqNum
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET templateId == ReadUIntBE(bytes, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET messageType == ReadBytes(templateId.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(messageType.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, msgSeqNum.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ messageType |-> messageType.value,
         msgSeqNum   |-> msgSeqNum.value,
         payload     |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ messageType |-> [i \in 1 .. 1 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> IndexValueMessageCode, body |-> ZeroIndexValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version        : Sample(1),
      packetLength   : Sample(2),
      sendingTime    : Sample(8),
      firstMsgSeqNum : Sample(4),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.version
        \o message.packetLength
        \o message.sendingTime
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.firstMsgSeqNum
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET packetLength == ReadBytes(version.rest, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(packetLength.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sendingTime.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET firstMsgSeqNum == ReadBytes(messageCount.rest, 4) IN IF ~firstMsgSeqNum.ok THEN Fail ELSE
    LET message == ReadMessageList(firstMsgSeqNum.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ version        |-> version.value,
         packetLength   |-> packetLength.value,
         sendingTime    |-> sendingTime.value,
         firstMsgSeqNum |-> firstMsgSeqNum.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ version        |-> [i \in 1 .. 1 |-> 0],
      packetLength   |-> [i \in 1 .. 2 |-> 0],
      sendingTime    |-> [i \in 1 .. 8 |-> 0],
      firstMsgSeqNum |-> [i \in 1 .. 4 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.firstMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol ==
    \A message \in CheckedSymbol :
        LET read == DecodeSymbol(EncodeSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx ==
    \A message \in CheckedMdEntryPx :
        LET read == DecodeMdEntryPx(EncodeMdEntryPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntries ==
    \A message \in CheckedMdEntries :
        LET read == DecodeMdEntries(EncodeMdEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueMessage ==
    \A message \in CheckedIndexValueMessage :
        LET read == DecodeIndexValueMessage(EncodeIndexValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
