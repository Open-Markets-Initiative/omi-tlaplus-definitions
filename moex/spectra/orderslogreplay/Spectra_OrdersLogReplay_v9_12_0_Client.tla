-------------- MODULE Spectra_OrdersLogReplay_v9_12_0_Client ---------------
(***************************************************************************)
(* Moscow Exchange SIMBA Spectra Orders Log Historical Replay v9.12.0      *)
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
(* Note: Msg Flags is a bit field set, checked as its 2 bytes rather than  *)
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
(* Logout Message: 256 bytes                                               *)
(***************************************************************************)

LogoutMessage ==
    [ text : Sample(256) ]

EncodeLogoutMessage(message) ==
    message.text

DecodeLogoutMessage(bytes) ==
    LET text == ReadBytes(bytes, 256) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroLogoutMessage ==
    [ text |-> [i \in 1 .. 256 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.text = one] : one \in Sample(256) }

(***************************************************************************)
(* Market Data Request Message: 8 bytes                                    *)
(***************************************************************************)

MarketDataRequestMessage ==
    [ applBegSeqNum : Sample(4),
      applEndSeqNum : Sample(4) ]

EncodeMarketDataRequestMessage(message) ==
    message.applBegSeqNum
        \o message.applEndSeqNum

DecodeMarketDataRequestMessage(bytes) ==
    LET applBegSeqNum == ReadBytes(bytes, 4) IN IF ~applBegSeqNum.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(applBegSeqNum.rest, 4) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    Ok([ applBegSeqNum |-> applBegSeqNum.value,
         applEndSeqNum |-> applEndSeqNum.value ], applEndSeqNum.rest)

ZeroMarketDataRequestMessage ==
    [ applBegSeqNum |-> [i \in 1 .. 4 |-> 0],
      applEndSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Market Data Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestMessage ==
    { ZeroMarketDataRequestMessage }
        \cup { [ZeroMarketDataRequestMessage EXCEPT !.applBegSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRequestMessage EXCEPT !.applEndSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

LogonMessageCode == 1000  \* 0x3e8
LogoutMessageCode == 1001  \* 0x3e9
MarketDataRequestMessageCode == 1002  \* 0x3ea

ClientPayload ==
    [ tag : {LogonMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {MarketDataRequestMessageCode}, body : MarketDataRequestMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = LogonMessageCode -> << >>
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = MarketDataRequestMessageCode -> EncodeMarketDataRequestMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = MarketDataRequestMessageCode -> DecodeMarketDataRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> LogonMessageCode, body |-> [empty |-> 0]]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> LogonMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> MarketDataRequestMessageCode, body |-> one] : one \in CheckedMarketDataRequestMessage }

(***************************************************************************)
(* Client Message                                                          *)
(***************************************************************************)

ClientMessage ==
    [ blockLength   : Sample(2),
      schemaId      : Sample(2),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.clientPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

DecodeClientMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

ZeroClientMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(***************************************************************************)
(* Client Frame, framed by Msg Size                                        *)
(***************************************************************************)

ClientFrame ==
    [ msgSeqNum     : Sample(4),
      msgFlags      : Sample(2),
      sendingTime   : Sample(8),
      clientMessage : ClientMessage ]

EncodeClientFrameBody(message) ==
    message.msgFlags
        \o message.sendingTime
        \o EncodeClientMessage(message.clientMessage)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeClientFrame(message) ==
    LET body == EncodeClientFrameBody(message)
    IN  message.msgSeqNum \o EncodeUIntLE(Len(body) + 6, 2) \o body

DecodeClientFrame(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgSeqNum.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 6 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET msgFlags == ReadBytes(framed, 2) IN IF ~msgFlags.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgFlags.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientMessage == DecodeClientMessage(sendingTime.rest) IN IF ~clientMessage.ok THEN Fail ELSE
    IF clientMessage.rest # << >> THEN Fail ELSE
    Ok([ msgSeqNum     |-> msgSeqNum.value,
         msgFlags      |-> msgFlags.value,
         sendingTime   |-> sendingTime.value,
         clientMessage |-> clientMessage.value ], beyond)

ZeroClientFrame ==
    [ msgSeqNum     |-> [i \in 1 .. 4 |-> 0],
      msgFlags      |-> [i \in 1 .. 2 |-> 0],
      sendingTime   |-> [i \in 1 .. 8 |-> 0],
      clientMessage |-> ZeroClientMessage ]

(* Client Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientFrame ==
    { ZeroClientFrame }
        \cup { [ZeroClientFrame EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroClientFrame EXCEPT !.msgFlags = one] : one \in Sample(2) }
        \cup { [ZeroClientFrame EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroClientFrame EXCEPT !.clientMessage = one] : one \in CheckedClientMessage }

(* A run of Client Frame, written one after another *)
RECURSIVE EncodeClientFrameList(_)
EncodeClientFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientFrame(Head(messages)) \o EncodeClientFrameList(Tail(messages))

(* As many Client Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientFrameAll(_)
ReadClientFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Frame of each kind, for the lists that carry them *)
OneClientFrame == { ZeroClientFrame }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientFrame : SampleLists(OneClientFrame) ]

EncodeClientPacket(message) ==
    EncodeClientFrameList(message.clientFrame)

DecodeClientPacket(bytes) ==
    LET clientFrame == ReadClientFrameAll(bytes) IN IF ~clientFrame.ok THEN Fail ELSE
    Ok([ clientFrame |-> clientFrame.value ], clientFrame.rest)

ZeroClientPacket ==
    [ clientFrame |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientFrame = one] : one \in SampleLists(OneClientFrame) }

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

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestMessage ==
    \A message \in CheckedMarketDataRequestMessage :
        LET read == DecodeMarketDataRequestMessage(EncodeMarketDataRequestMessage(message))
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

(* Every Client Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientFrame ==
    \A message \in CheckedClientFrame :
        LET read == DecodeClientFrame(EncodeClientFrame(message))
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

(* Msg Size is written from the bytes it frames *)
FramesClientFrame ==
    \A message \in CheckedClientFrame :
        LET bytes == EncodeClientFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 5, 6)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
