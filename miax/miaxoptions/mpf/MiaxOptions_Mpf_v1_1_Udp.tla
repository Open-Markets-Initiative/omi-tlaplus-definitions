--------------------- MODULE MiaxOptions_Mpf_v1_1_Udp ----------------------
(***************************************************************************)
(* Miami International Holdings MIAX Product Feed v1.1                     *)
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
(* Note: Application Message fills what is left of the frame Packet Length *)
(* states, which is what it is read from.                                  *)
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
(* System Time Message: 4 bytes                                            *)
(***************************************************************************)

SystemTimeMessage ==
    [ seconds : Sample(4) ]

EncodeSystemTimeMessage(message) ==
    message.seconds

DecodeSystemTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSystemTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* System Time Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTimeMessage ==
    { ZeroSystemTimeMessage }
        \cup { [ZeroSystemTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Definition Message: 37 bytes                                     *)
(***************************************************************************)

SymbolDefinitionMessage ==
    [ nanoseconds           : Sample(4),
      syntheticFutureSymbol : Sample(8),
      settlementDate        : Sample(8),
      symbolStatus          : Sample(1),
      reserved16            : Sample(16) ]

EncodeSymbolDefinitionMessage(message) ==
    message.nanoseconds
        \o message.syntheticFutureSymbol
        \o message.settlementDate
        \o message.symbolStatus
        \o message.reserved16

DecodeSymbolDefinitionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET syntheticFutureSymbol == ReadBytes(nanoseconds.rest, 8) IN IF ~syntheticFutureSymbol.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(syntheticFutureSymbol.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET symbolStatus == ReadBytes(settlementDate.rest, 1) IN IF ~symbolStatus.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(symbolStatus.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         syntheticFutureSymbol |-> syntheticFutureSymbol.value,
         settlementDate        |-> settlementDate.value,
         symbolStatus          |-> symbolStatus.value,
         reserved16            |-> reserved16.value ], reserved16.rest)

ZeroSymbolDefinitionMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      syntheticFutureSymbol |-> [i \in 1 .. 8 |-> 0],
      settlementDate        |-> [i \in 1 .. 8 |-> 0],
      symbolStatus          |-> [i \in 1 .. 1 |-> 0],
      reserved16            |-> [i \in 1 .. 16 |-> 0] ]

(* Symbol Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDefinitionMessage ==
    { ZeroSymbolDefinitionMessage }
        \cup { [ZeroSymbolDefinitionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDefinitionMessage EXCEPT !.syntheticFutureSymbol = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDefinitionMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDefinitionMessage EXCEPT !.symbolStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDefinitionMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Index Value Message: 13 bytes                                           *)
(***************************************************************************)

IndexValueMessage ==
    [ nanoseconds : Sample(4),
      symbol      : Sample(5),
      value       : Sample(4) ]

EncodeIndexValueMessage(message) ==
    message.nanoseconds
        \o message.symbol
        \o message.value

DecodeIndexValueMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanoseconds.rest, 5) IN IF ~symbol.ok THEN Fail ELSE
    LET value == ReadBytes(symbol.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         symbol      |-> symbol.value,
         value       |-> value.value ], value.rest)

ZeroIndexValueMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      symbol      |-> [i \in 1 .. 5 |-> 0],
      value       |-> [i \in 1 .. 4 |-> 0] ]

(* Index Value Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueMessage ==
    { ZeroIndexValueMessage }
        \cup { [ZeroIndexValueMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueMessage EXCEPT !.symbol = one] : one \in Sample(5) }
        \cup { [ZeroIndexValueMessage EXCEPT !.value = one] : one \in Sample(4) }

(***************************************************************************)
(* Synthetic Future Value Message: 24 bytes                                *)
(***************************************************************************)

SyntheticFutureValueMessage ==
    [ nanoseconds           : Sample(4),
      syntheticFutureSymbol : Sample(8),
      value                 : Sample(4),
      reserved8             : Sample(8) ]

EncodeSyntheticFutureValueMessage(message) ==
    message.nanoseconds
        \o message.syntheticFutureSymbol
        \o message.value
        \o message.reserved8

DecodeSyntheticFutureValueMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET syntheticFutureSymbol == ReadBytes(nanoseconds.rest, 8) IN IF ~syntheticFutureSymbol.ok THEN Fail ELSE
    LET value == ReadBytes(syntheticFutureSymbol.rest, 4) IN IF ~value.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(value.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         syntheticFutureSymbol |-> syntheticFutureSymbol.value,
         value                 |-> value.value,
         reserved8             |-> reserved8.value ], reserved8.rest)

ZeroSyntheticFutureValueMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      syntheticFutureSymbol |-> [i \in 1 .. 8 |-> 0],
      value                 |-> [i \in 1 .. 4 |-> 0],
      reserved8             |-> [i \in 1 .. 8 |-> 0] ]

(* Synthetic Future Value Message at zero, then each field in turn at the values it is checked at *)
CheckedSyntheticFutureValueMessage ==
    { ZeroSyntheticFutureValueMessage }
        \cup { [ZeroSyntheticFutureValueMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSyntheticFutureValueMessage EXCEPT !.syntheticFutureSymbol = one] : one \in Sample(8) }
        \cup { [ZeroSyntheticFutureValueMessage EXCEPT !.value = one] : one \in Sample(4) }
        \cup { [ZeroSyntheticFutureValueMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SymbolDefinitionMessageCode == 115  \* "s"
IndexValueMessageCode == 73  \* "I"
SyntheticFutureValueMessageCode == 90  \* "Z"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SymbolDefinitionMessageCode}, body : SymbolDefinitionMessage ]
        \cup [ tag : {IndexValueMessageCode}, body : IndexValueMessage ]
        \cup [ tag : {SyntheticFutureValueMessageCode}, body : SyntheticFutureValueMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SymbolDefinitionMessageCode -> EncodeSymbolDefinitionMessage(message.body)
      [] message.tag = IndexValueMessageCode -> EncodeIndexValueMessage(message.body)
      [] message.tag = SyntheticFutureValueMessageCode -> EncodeSyntheticFutureValueMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SymbolDefinitionMessageCode -> DecodeSymbolDefinitionMessage(bytes)
              [] tag = IndexValueMessageCode -> DecodeIndexValueMessage(bytes)
              [] tag = SyntheticFutureValueMessageCode -> DecodeSyntheticFutureValueMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SymbolDefinitionMessageCode, body |-> one] : one \in CheckedSymbolDefinitionMessage }
        \cup { [tag |-> IndexValueMessageCode, body |-> one] : one \in CheckedIndexValueMessage }
        \cup { [tag |-> SyntheticFutureValueMessageCode, body |-> one] : one \in CheckedSyntheticFutureValueMessage }

(***************************************************************************)
(* Application Message                                                     *)
(***************************************************************************)

ApplicationMessage ==
    [ data : Data ]

EncodeApplicationMessage(message) ==
    EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeApplicationMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroApplicationMessage ==
    [ data |-> ZeroData ]

(* Application Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationMessage ==
    { ZeroApplicationMessage }
        \cup { [ZeroApplicationMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Payload, selected by Packet Type                                        *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02
ApplicationMessageCode == 3  \* 0x03

Payload ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* Mach Message, framed by Packet Length                                   *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o message.sessionNumber
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeMachMessage(message) ==
    LET body == EncodeMachMessageBody(message)
    IN  message.sequenceNumber \o EncodeUIntLE(Len(body) + 10, 2) \o body

DecodeMachMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 10 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET packetType == ReadUIntLE(framed, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET sessionNumber == ReadBytes(packetType.rest, 1) IN IF ~sessionNumber.ok THEN Fail ELSE
    LET payload == DecodePayload(packetType.value, sessionNumber.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         sessionNumber  |-> sessionNumber.value,
         payload        |-> payload.value ], beyond)

ZeroMachMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sessionNumber  |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Mach Message at zero, then each field in turn at the values it is checked at *)
CheckedMachMessage ==
    { ZeroMachMessage }
        \cup { [ZeroMachMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMachMessage EXCEPT !.sessionNumber = one] : one \in Sample(1) }
        \cup { [ZeroMachMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodeUdpPacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodeUdpPacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroUdpPacket ==
    [ machMessage |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every System Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTimeMessage ==
    \A message \in CheckedSystemTimeMessage :
        LET read == DecodeSystemTimeMessage(EncodeSystemTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolDefinitionMessage ==
    \A message \in CheckedSymbolDefinitionMessage :
        LET read == DecodeSymbolDefinitionMessage(EncodeSymbolDefinitionMessage(message))
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

(* Every Synthetic Future Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSyntheticFutureValueMessage ==
    \A message \in CheckedSyntheticFutureValueMessage :
        LET read == DecodeSyntheticFutureValueMessage(EncodeSyntheticFutureValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationMessage ==
    \A message \in CheckedApplicationMessage :
        LET read == DecodeApplicationMessage(EncodeApplicationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET read == DecodeData(message.tag, EncodeData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
