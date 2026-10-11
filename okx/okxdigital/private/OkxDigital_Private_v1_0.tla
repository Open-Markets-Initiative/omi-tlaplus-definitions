---------------------- MODULE OkxDigital_Private_v1_0 ----------------------
(***************************************************************************)
(* OKX Private v1.0                                                        *)
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
(* Orders Channel Event Message: 140 bytes                                 *)
(***************************************************************************)

OrdersChannelEventMessage ==
    [ instIdCode             : Sample(8),
      ordId                  : Sample(8),
      clOrdId                : Sample(8),
      tag                    : Sample(8),
      pxMantissa             : Sample(8),
      pxExponent             : Sample(1),
      szMantissa             : Sample(8),
      szExponent             : Sample(1),
      side                   : Sample(1),
      tdMode                 : Sample(1),
      fillPxMantissaOptional : Sample(8),
      fillSzMantissaOptional : Sample(8),
      fillTime               : Sample(8),
      tradeIdOptional        : Sample(8),
      execTypeOptional       : Sample(1),
      fillFeeMantissa        : Sample(8),
      accFillSzMantissa      : Sample(8),
      state                  : Sample(1),
      feeMantissa            : Sample(8),
      feeExponent            : Sample(1),
      cancelSource           : Sample(1),
      amendSource            : Sample(1),
      category               : Sample(1),
      uTime                  : Sample(8),
      cTime                  : Sample(8),
      reqId                  : Sample(8),
      amendResult            : Sample(1),
      riskBypassResult       : Sample(1) ]

EncodeOrdersChannelEventMessage(message) ==
    message.instIdCode
        \o message.ordId
        \o message.clOrdId
        \o message.tag
        \o message.pxMantissa
        \o message.pxExponent
        \o message.szMantissa
        \o message.szExponent
        \o message.side
        \o message.tdMode
        \o message.fillPxMantissaOptional
        \o message.fillSzMantissaOptional
        \o message.fillTime
        \o message.tradeIdOptional
        \o message.execTypeOptional
        \o message.fillFeeMantissa
        \o message.accFillSzMantissa
        \o message.state
        \o message.feeMantissa
        \o message.feeExponent
        \o message.cancelSource
        \o message.amendSource
        \o message.category
        \o message.uTime
        \o message.cTime
        \o message.reqId
        \o message.amendResult
        \o message.riskBypassResult

DecodeOrdersChannelEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(instIdCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ordId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET tag == ReadBytes(clOrdId.rest, 8) IN IF ~tag.ok THEN Fail ELSE
    LET pxMantissa == ReadBytes(tag.rest, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(pxMantissa.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxExponent.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET szExponent == ReadBytes(szMantissa.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET side == ReadBytes(szExponent.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tdMode == ReadBytes(side.rest, 1) IN IF ~tdMode.ok THEN Fail ELSE
    LET fillPxMantissaOptional == ReadBytes(tdMode.rest, 8) IN IF ~fillPxMantissaOptional.ok THEN Fail ELSE
    LET fillSzMantissaOptional == ReadBytes(fillPxMantissaOptional.rest, 8) IN IF ~fillSzMantissaOptional.ok THEN Fail ELSE
    LET fillTime == ReadBytes(fillSzMantissaOptional.rest, 8) IN IF ~fillTime.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(fillTime.rest, 8) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET execTypeOptional == ReadBytes(tradeIdOptional.rest, 1) IN IF ~execTypeOptional.ok THEN Fail ELSE
    LET fillFeeMantissa == ReadBytes(execTypeOptional.rest, 8) IN IF ~fillFeeMantissa.ok THEN Fail ELSE
    LET accFillSzMantissa == ReadBytes(fillFeeMantissa.rest, 8) IN IF ~accFillSzMantissa.ok THEN Fail ELSE
    LET state == ReadBytes(accFillSzMantissa.rest, 1) IN IF ~state.ok THEN Fail ELSE
    LET feeMantissa == ReadBytes(state.rest, 8) IN IF ~feeMantissa.ok THEN Fail ELSE
    LET feeExponent == ReadBytes(feeMantissa.rest, 1) IN IF ~feeExponent.ok THEN Fail ELSE
    LET cancelSource == ReadBytes(feeExponent.rest, 1) IN IF ~cancelSource.ok THEN Fail ELSE
    LET amendSource == ReadBytes(cancelSource.rest, 1) IN IF ~amendSource.ok THEN Fail ELSE
    LET category == ReadBytes(amendSource.rest, 1) IN IF ~category.ok THEN Fail ELSE
    LET uTime == ReadBytes(category.rest, 8) IN IF ~uTime.ok THEN Fail ELSE
    LET cTime == ReadBytes(uTime.rest, 8) IN IF ~cTime.ok THEN Fail ELSE
    LET reqId == ReadBytes(cTime.rest, 8) IN IF ~reqId.ok THEN Fail ELSE
    LET amendResult == ReadBytes(reqId.rest, 1) IN IF ~amendResult.ok THEN Fail ELSE
    LET riskBypassResult == ReadBytes(amendResult.rest, 1) IN IF ~riskBypassResult.ok THEN Fail ELSE
    Ok([ instIdCode             |-> instIdCode.value,
         ordId                  |-> ordId.value,
         clOrdId                |-> clOrdId.value,
         tag                    |-> tag.value,
         pxMantissa             |-> pxMantissa.value,
         pxExponent             |-> pxExponent.value,
         szMantissa             |-> szMantissa.value,
         szExponent             |-> szExponent.value,
         side                   |-> side.value,
         tdMode                 |-> tdMode.value,
         fillPxMantissaOptional |-> fillPxMantissaOptional.value,
         fillSzMantissaOptional |-> fillSzMantissaOptional.value,
         fillTime               |-> fillTime.value,
         tradeIdOptional        |-> tradeIdOptional.value,
         execTypeOptional       |-> execTypeOptional.value,
         fillFeeMantissa        |-> fillFeeMantissa.value,
         accFillSzMantissa      |-> accFillSzMantissa.value,
         state                  |-> state.value,
         feeMantissa            |-> feeMantissa.value,
         feeExponent            |-> feeExponent.value,
         cancelSource           |-> cancelSource.value,
         amendSource            |-> amendSource.value,
         category               |-> category.value,
         uTime                  |-> uTime.value,
         cTime                  |-> cTime.value,
         reqId                  |-> reqId.value,
         amendResult            |-> amendResult.value,
         riskBypassResult       |-> riskBypassResult.value ], riskBypassResult.rest)

ZeroOrdersChannelEventMessage ==
    [ instIdCode             |-> [i \in 1 .. 8 |-> 0],
      ordId                  |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      tag                    |-> [i \in 1 .. 8 |-> 0],
      pxMantissa             |-> [i \in 1 .. 8 |-> 0],
      pxExponent             |-> [i \in 1 .. 1 |-> 0],
      szMantissa             |-> [i \in 1 .. 8 |-> 0],
      szExponent             |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      tdMode                 |-> [i \in 1 .. 1 |-> 0],
      fillPxMantissaOptional |-> [i \in 1 .. 8 |-> 0],
      fillSzMantissaOptional |-> [i \in 1 .. 8 |-> 0],
      fillTime               |-> [i \in 1 .. 8 |-> 0],
      tradeIdOptional        |-> [i \in 1 .. 8 |-> 0],
      execTypeOptional       |-> [i \in 1 .. 1 |-> 0],
      fillFeeMantissa        |-> [i \in 1 .. 8 |-> 0],
      accFillSzMantissa      |-> [i \in 1 .. 8 |-> 0],
      state                  |-> [i \in 1 .. 1 |-> 0],
      feeMantissa            |-> [i \in 1 .. 8 |-> 0],
      feeExponent            |-> [i \in 1 .. 1 |-> 0],
      cancelSource           |-> [i \in 1 .. 1 |-> 0],
      amendSource            |-> [i \in 1 .. 1 |-> 0],
      category               |-> [i \in 1 .. 1 |-> 0],
      uTime                  |-> [i \in 1 .. 8 |-> 0],
      cTime                  |-> [i \in 1 .. 8 |-> 0],
      reqId                  |-> [i \in 1 .. 8 |-> 0],
      amendResult            |-> [i \in 1 .. 1 |-> 0],
      riskBypassResult       |-> [i \in 1 .. 1 |-> 0] ]

(* Orders Channel Event Message at zero, then each field in turn at the values it is checked at *)
CheckedOrdersChannelEventMessage ==
    { ZeroOrdersChannelEventMessage }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.tag = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.tdMode = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.fillPxMantissaOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.fillSzMantissaOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.fillTime = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.tradeIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.execTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.fillFeeMantissa = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.accFillSzMantissa = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.state = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.feeMantissa = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.feeExponent = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.cancelSource = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.amendSource = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.category = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.uTime = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.cTime = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.reqId = one] : one \in Sample(8) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.amendResult = one] : one \in Sample(1) }
        \cup { [ZeroOrdersChannelEventMessage EXCEPT !.riskBypassResult = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Channel Event Message: 62 bytes                                   *)
(***************************************************************************)

FillsChannelEventMessage ==
    [ instIdCode     : Sample(8),
      ts             : Sample(8),
      tradeId        : Sample(8),
      ordId          : Sample(8),
      clOrdId        : Sample(8),
      fillPxMantissa : Sample(8),
      fillSzMantissa : Sample(8),
      count          : Sample(2),
      side           : Sample(1),
      execType       : Sample(1),
      fillPxExponent : Sample(1),
      fillSzExponent : Sample(1) ]

EncodeFillsChannelEventMessage(message) ==
    message.instIdCode
        \o message.ts
        \o message.tradeId
        \o message.ordId
        \o message.clOrdId
        \o message.fillPxMantissa
        \o message.fillSzMantissa
        \o message.count
        \o message.side
        \o message.execType
        \o message.fillPxExponent
        \o message.fillSzExponent

DecodeFillsChannelEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET ts == ReadBytes(instIdCode.rest, 8) IN IF ~ts.ok THEN Fail ELSE
    LET tradeId == ReadBytes(ts.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET ordId == ReadBytes(tradeId.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ordId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET fillPxMantissa == ReadBytes(clOrdId.rest, 8) IN IF ~fillPxMantissa.ok THEN Fail ELSE
    LET fillSzMantissa == ReadBytes(fillPxMantissa.rest, 8) IN IF ~fillSzMantissa.ok THEN Fail ELSE
    LET count == ReadBytes(fillSzMantissa.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET side == ReadBytes(count.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET execType == ReadBytes(side.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET fillPxExponent == ReadBytes(execType.rest, 1) IN IF ~fillPxExponent.ok THEN Fail ELSE
    LET fillSzExponent == ReadBytes(fillPxExponent.rest, 1) IN IF ~fillSzExponent.ok THEN Fail ELSE
    Ok([ instIdCode     |-> instIdCode.value,
         ts             |-> ts.value,
         tradeId        |-> tradeId.value,
         ordId          |-> ordId.value,
         clOrdId        |-> clOrdId.value,
         fillPxMantissa |-> fillPxMantissa.value,
         fillSzMantissa |-> fillSzMantissa.value,
         count          |-> count.value,
         side           |-> side.value,
         execType       |-> execType.value,
         fillPxExponent |-> fillPxExponent.value,
         fillSzExponent |-> fillSzExponent.value ], fillSzExponent.rest)

ZeroFillsChannelEventMessage ==
    [ instIdCode     |-> [i \in 1 .. 8 |-> 0],
      ts             |-> [i \in 1 .. 8 |-> 0],
      tradeId        |-> [i \in 1 .. 8 |-> 0],
      ordId          |-> [i \in 1 .. 8 |-> 0],
      clOrdId        |-> [i \in 1 .. 8 |-> 0],
      fillPxMantissa |-> [i \in 1 .. 8 |-> 0],
      fillSzMantissa |-> [i \in 1 .. 8 |-> 0],
      count          |-> [i \in 1 .. 2 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      execType       |-> [i \in 1 .. 1 |-> 0],
      fillPxExponent |-> [i \in 1 .. 1 |-> 0],
      fillSzExponent |-> [i \in 1 .. 1 |-> 0] ]

(* Fills Channel Event Message at zero, then each field in turn at the values it is checked at *)
CheckedFillsChannelEventMessage ==
    { ZeroFillsChannelEventMessage }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.ts = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.fillPxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.fillSzMantissa = one] : one \in Sample(8) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.count = one] : one \in Sample(2) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.fillPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroFillsChannelEventMessage EXCEPT !.fillSzExponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

OrdersChannelEventMessageCode == 1100  \* 0x44c
FillsChannelEventMessageCode == 1101  \* 0x44d

Payload ==
    [ tag : {OrdersChannelEventMessageCode}, body : OrdersChannelEventMessage ]
        \cup [ tag : {FillsChannelEventMessageCode}, body : FillsChannelEventMessage ]

EncodePayload(message) ==
    CASE message.tag = OrdersChannelEventMessageCode -> EncodeOrdersChannelEventMessage(message.body)
      [] message.tag = FillsChannelEventMessageCode -> EncodeFillsChannelEventMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OrdersChannelEventMessageCode -> DecodeOrdersChannelEventMessage(bytes)
              [] tag = FillsChannelEventMessageCode -> DecodeFillsChannelEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OrdersChannelEventMessageCode, body |-> ZeroOrdersChannelEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OrdersChannelEventMessageCode, body |-> one] : one \in CheckedOrdersChannelEventMessage }
        \cup { [tag |-> FillsChannelEventMessageCode, body |-> one] : one \in CheckedFillsChannelEventMessage }

(***************************************************************************)
(* Sbe Message                                                             *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Frame                                                                   *)
(***************************************************************************)

Frame ==
    [ sbeMessage : SbeMessage ]

EncodeFrame(message) ==
    EncodeSbeMessage(message.sbeMessage)

DecodeFrame(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroFrame ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Frame at zero, then each field in turn at the values it is checked at *)
CheckedFrame ==
    { ZeroFrame }
        \cup { [ZeroFrame EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

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

(* Every Orders Channel Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrdersChannelEventMessage ==
    \A message \in CheckedOrdersChannelEventMessage :
        LET read == DecodeOrdersChannelEventMessage(EncodeOrdersChannelEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Channel Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsChannelEventMessage ==
    \A message \in CheckedFillsChannelEventMessage :
        LET read == DecodeFillsChannelEventMessage(EncodeFillsChannelEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripFrame ==
    \A message \in CheckedFrame :
        LET read == DecodeFrame(EncodeFrame(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
