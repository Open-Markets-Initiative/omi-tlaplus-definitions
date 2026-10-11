--------------- MODULE NyseBonds_DepthOfBook_v4_01_b_Client ----------------
(***************************************************************************)
(* New York Stock Exchange DepthOfBook v4.01.b                             *)
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
(* Login Message: 34 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ username              : Sample(8),
      password              : Sample(10),
      loginSequenceNumber   : Sample(10),
      listedSubscription    : Sample(1),
      etfSubscription       : Sample(1),
      otcSubscription       : Sample(1),
      globalOtcSubscription : Sample(1),
      bondSubscription      : Sample(1),
      etx                   : Sample(1) ]

EncodeLoginMessage(message) ==
    message.username
        \o message.password
        \o message.loginSequenceNumber
        \o message.listedSubscription
        \o message.etfSubscription
        \o message.otcSubscription
        \o message.globalOtcSubscription
        \o message.bondSubscription
        \o message.etx

DecodeLoginMessage(bytes) ==
    LET username == ReadBytes(bytes, 8) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET loginSequenceNumber == ReadBytes(password.rest, 10) IN IF ~loginSequenceNumber.ok THEN Fail ELSE
    LET listedSubscription == ReadBytes(loginSequenceNumber.rest, 1) IN IF ~listedSubscription.ok THEN Fail ELSE
    LET etfSubscription == ReadBytes(listedSubscription.rest, 1) IN IF ~etfSubscription.ok THEN Fail ELSE
    LET otcSubscription == ReadBytes(etfSubscription.rest, 1) IN IF ~otcSubscription.ok THEN Fail ELSE
    LET globalOtcSubscription == ReadBytes(otcSubscription.rest, 1) IN IF ~globalOtcSubscription.ok THEN Fail ELSE
    LET bondSubscription == ReadBytes(globalOtcSubscription.rest, 1) IN IF ~bondSubscription.ok THEN Fail ELSE
    LET etx == ReadBytes(bondSubscription.rest, 1) IN IF ~etx.ok THEN Fail ELSE
    Ok([ username              |-> username.value,
         password              |-> password.value,
         loginSequenceNumber   |-> loginSequenceNumber.value,
         listedSubscription    |-> listedSubscription.value,
         etfSubscription       |-> etfSubscription.value,
         otcSubscription       |-> otcSubscription.value,
         globalOtcSubscription |-> globalOtcSubscription.value,
         bondSubscription      |-> bondSubscription.value,
         etx                   |-> etx.value ], etx.rest)

ZeroLoginMessage ==
    [ username              |-> [i \in 1 .. 8 |-> 0],
      password              |-> [i \in 1 .. 10 |-> 0],
      loginSequenceNumber   |-> [i \in 1 .. 10 |-> 0],
      listedSubscription    |-> [i \in 1 .. 1 |-> 0],
      etfSubscription       |-> [i \in 1 .. 1 |-> 0],
      otcSubscription       |-> [i \in 1 .. 1 |-> 0],
      globalOtcSubscription |-> [i \in 1 .. 1 |-> 0],
      bondSubscription      |-> [i \in 1 .. 1 |-> 0],
      etx                   |-> [i \in 1 .. 1 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.username = one] : one \in Sample(8) }
        \cup { [ZeroLoginMessage EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginMessage EXCEPT !.loginSequenceNumber = one] : one \in Sample(10) }
        \cup { [ZeroLoginMessage EXCEPT !.listedSubscription = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.etfSubscription = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.otcSubscription = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.globalOtcSubscription = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.bondSubscription = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.etx = one] : one \in Sample(1) }

(***************************************************************************)
(* Logoff Message: 1 bytes                                                 *)
(***************************************************************************)

LogoffMessage ==
    [ etx : Sample(1) ]

EncodeLogoffMessage(message) ==
    message.etx

DecodeLogoffMessage(bytes) ==
    LET etx == ReadBytes(bytes, 1) IN IF ~etx.ok THEN Fail ELSE
    Ok([ etx |-> etx.value ], etx.rest)

ZeroLogoffMessage ==
    [ etx |-> [i \in 1 .. 1 |-> 0] ]

(* Logoff Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoffMessage ==
    { ZeroLogoffMessage }
        \cup { [ZeroLogoffMessage EXCEPT !.etx = one] : one \in Sample(1) }

(***************************************************************************)
(* Heartbeat Response Message: 1 bytes                                     *)
(***************************************************************************)

HeartbeatResponseMessage ==
    [ etx : Sample(1) ]

EncodeHeartbeatResponseMessage(message) ==
    message.etx

DecodeHeartbeatResponseMessage(bytes) ==
    LET etx == ReadBytes(bytes, 1) IN IF ~etx.ok THEN Fail ELSE
    Ok([ etx |-> etx.value ], etx.rest)

ZeroHeartbeatResponseMessage ==
    [ etx |-> [i \in 1 .. 1 |-> 0] ]

(* Heartbeat Response Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatResponseMessage ==
    { ZeroHeartbeatResponseMessage }
        \cup { [ZeroHeartbeatResponseMessage EXCEPT !.etx = one] : one \in Sample(1) }

(***************************************************************************)
(* Test Request Message: 21 bytes                                          *)
(***************************************************************************)

TestRequestMessage ==
    [ testRequestText : Sample(20),
      etx             : Sample(1) ]

EncodeTestRequestMessage(message) ==
    message.testRequestText
        \o message.etx

DecodeTestRequestMessage(bytes) ==
    LET testRequestText == ReadBytes(bytes, 20) IN IF ~testRequestText.ok THEN Fail ELSE
    LET etx == ReadBytes(testRequestText.rest, 1) IN IF ~etx.ok THEN Fail ELSE
    Ok([ testRequestText |-> testRequestText.value,
         etx             |-> etx.value ], etx.rest)

ZeroTestRequestMessage ==
    [ testRequestText |-> [i \in 1 .. 20 |-> 0],
      etx             |-> [i \in 1 .. 1 |-> 0] ]

(* Test Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTestRequestMessage ==
    { ZeroTestRequestMessage }
        \cup { [ZeroTestRequestMessage EXCEPT !.testRequestText = one] : one \in Sample(20) }
        \cup { [ZeroTestRequestMessage EXCEPT !.etx = one] : one \in Sample(1) }

(***************************************************************************)
(* Client Data, selected by Client Message Type                            *)
(***************************************************************************)

LoginMessageCode == 76  \* "L"
LogoffMessageCode == 79  \* "O"
HeartbeatResponseMessageCode == 72  \* "H"
TestRequestMessageCode == 84  \* "T"

ClientData ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {LogoffMessageCode}, body : LogoffMessage ]
        \cup [ tag : {HeartbeatResponseMessageCode}, body : HeartbeatResponseMessage ]
        \cup [ tag : {TestRequestMessageCode}, body : TestRequestMessage ]

EncodeClientData(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = LogoffMessageCode -> EncodeLogoffMessage(message.body)
      [] message.tag = HeartbeatResponseMessageCode -> EncodeHeartbeatResponseMessage(message.body)
      [] message.tag = TestRequestMessageCode -> EncodeTestRequestMessage(message.body)

DecodeClientData(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = LogoffMessageCode -> DecodeLogoffMessage(bytes)
              [] tag = HeartbeatResponseMessageCode -> DecodeHeartbeatResponseMessage(bytes)
              [] tag = TestRequestMessageCode -> DecodeTestRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientData == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Client Data in turn, at the values the message it names is checked at *)
CheckedClientData ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> LogoffMessageCode, body |-> one] : one \in CheckedLogoffMessage }
        \cup { [tag |-> HeartbeatResponseMessageCode, body |-> one] : one \in CheckedHeartbeatResponseMessage }
        \cup { [tag |-> TestRequestMessageCode, body |-> one] : one \in CheckedTestRequestMessage }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientData : ClientData ]

EncodeClientPacket(message) ==
    EncodeUIntBE(message.clientData.tag, 1)
        \o EncodeClientData(message.clientData)

DecodeClientPacket(bytes) ==
    LET clientMessageType == ReadUIntBE(bytes, 1) IN IF ~clientMessageType.ok THEN Fail ELSE
    LET clientData == DecodeClientData(clientMessageType.value, clientMessageType.rest) IN IF ~clientData.ok THEN Fail ELSE
    Ok([ clientData |-> clientData.value ], clientData.rest)

ZeroClientPacket ==
    [ clientData |-> ZeroClientData ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientData = one] : one \in CheckedClientData }

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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logoff Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoffMessage ==
    \A message \in CheckedLogoffMessage :
        LET read == DecodeLogoffMessage(EncodeLogoffMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatResponseMessage ==
    \A message \in CheckedHeartbeatResponseMessage :
        LET read == DecodeHeartbeatResponseMessage(EncodeHeartbeatResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestRequestMessage ==
    \A message \in CheckedTestRequestMessage :
        LET read == DecodeTestRequestMessage(EncodeTestRequestMessage(message))
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

(* A Client Data is selected by the Client Message Type it is written under *)
SelectsClientData ==
    \A message \in CheckedClientData :
        LET read == DecodeClientData(message.tag, EncodeClientData(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
