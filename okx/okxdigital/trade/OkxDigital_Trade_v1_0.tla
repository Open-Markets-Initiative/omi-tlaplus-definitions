----------------------- MODULE OkxDigital_Trade_v1_0 -----------------------
(***************************************************************************)
(* OKX Trade v1.0                                                          *)
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
(* Place Order Message: 62 bytes                                           *)
(***************************************************************************)

PlaceOrderMessage ==
    [ id             : Sample(8),
      instIdCode     : Sample(8),
      side           : Sample(1),
      ordType        : Sample(1),
      tdMode         : Sample(1),
      szExponent     : Sample(1),
      szMantissa     : Sample(8),
      pxExponent     : Sample(1),
      pxMantissa     : Sample(8),
      clOrdId        : Sample(8),
      expTime        : Sample(8),
      tag            : Sample(8),
      rpiTakerAccess : Sample(1) ]

EncodePlaceOrderMessage(message) ==
    message.id
        \o message.instIdCode
        \o message.side
        \o message.ordType
        \o message.tdMode
        \o message.szExponent
        \o message.szMantissa
        \o message.pxExponent
        \o message.pxMantissa
        \o message.clOrdId
        \o message.expTime
        \o message.tag
        \o message.rpiTakerAccess

DecodePlaceOrderMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET instIdCode == ReadBytes(id.rest, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET side == ReadBytes(instIdCode.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET tdMode == ReadBytes(ordType.rest, 1) IN IF ~tdMode.ok THEN Fail ELSE
    LET szExponent == ReadBytes(tdMode.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(szExponent.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(szMantissa.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET pxMantissa == ReadBytes(pxExponent.rest, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(pxMantissa.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET expTime == ReadBytes(clOrdId.rest, 8) IN IF ~expTime.ok THEN Fail ELSE
    LET tag == ReadBytes(expTime.rest, 8) IN IF ~tag.ok THEN Fail ELSE
    LET rpiTakerAccess == ReadBytes(tag.rest, 1) IN IF ~rpiTakerAccess.ok THEN Fail ELSE
    Ok([ id             |-> id.value,
         instIdCode     |-> instIdCode.value,
         side           |-> side.value,
         ordType        |-> ordType.value,
         tdMode         |-> tdMode.value,
         szExponent     |-> szExponent.value,
         szMantissa     |-> szMantissa.value,
         pxExponent     |-> pxExponent.value,
         pxMantissa     |-> pxMantissa.value,
         clOrdId        |-> clOrdId.value,
         expTime        |-> expTime.value,
         tag            |-> tag.value,
         rpiTakerAccess |-> rpiTakerAccess.value ], rpiTakerAccess.rest)

ZeroPlaceOrderMessage ==
    [ id             |-> [i \in 1 .. 8 |-> 0],
      instIdCode     |-> [i \in 1 .. 8 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      ordType        |-> [i \in 1 .. 1 |-> 0],
      tdMode         |-> [i \in 1 .. 1 |-> 0],
      szExponent     |-> [i \in 1 .. 1 |-> 0],
      szMantissa     |-> [i \in 1 .. 8 |-> 0],
      pxExponent     |-> [i \in 1 .. 1 |-> 0],
      pxMantissa     |-> [i \in 1 .. 8 |-> 0],
      clOrdId        |-> [i \in 1 .. 8 |-> 0],
      expTime        |-> [i \in 1 .. 8 |-> 0],
      tag            |-> [i \in 1 .. 8 |-> 0],
      rpiTakerAccess |-> [i \in 1 .. 1 |-> 0] ]

(* Place Order Message at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrderMessage ==
    { ZeroPlaceOrderMessage }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.tdMode = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.expTime = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.tag = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderMessage EXCEPT !.rpiTakerAccess = one] : one \in Sample(1) }

(***************************************************************************)
(* Place Order Response Message: 72 bytes                                  *)
(***************************************************************************)

PlaceOrderResponseMessage ==
    [ id         : Sample(8),
      code       : Sample(4),
      subCode    : Sample(4),
      ordId      : Sample(8),
      instIdCode : Sample(8),
      tsOptional : Sample(8),
      clOrdId    : Sample(8),
      tag        : Sample(8),
      inTime     : Sample(8),
      outTime    : Sample(8) ]

EncodePlaceOrderResponseMessage(message) ==
    message.id
        \o message.code
        \o message.subCode
        \o message.ordId
        \o message.instIdCode
        \o message.tsOptional
        \o message.clOrdId
        \o message.tag
        \o message.inTime
        \o message.outTime

DecodePlaceOrderResponseMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET code == ReadBytes(id.rest, 4) IN IF ~code.ok THEN Fail ELSE
    LET subCode == ReadBytes(code.rest, 4) IN IF ~subCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(subCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET instIdCode == ReadBytes(ordId.rest, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsOptional == ReadBytes(instIdCode.rest, 8) IN IF ~tsOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tsOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET tag == ReadBytes(clOrdId.rest, 8) IN IF ~tag.ok THEN Fail ELSE
    LET inTime == ReadBytes(tag.rest, 8) IN IF ~inTime.ok THEN Fail ELSE
    LET outTime == ReadBytes(inTime.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    Ok([ id         |-> id.value,
         code       |-> code.value,
         subCode    |-> subCode.value,
         ordId      |-> ordId.value,
         instIdCode |-> instIdCode.value,
         tsOptional |-> tsOptional.value,
         clOrdId    |-> clOrdId.value,
         tag        |-> tag.value,
         inTime     |-> inTime.value,
         outTime    |-> outTime.value ], outTime.rest)

ZeroPlaceOrderResponseMessage ==
    [ id         |-> [i \in 1 .. 8 |-> 0],
      code       |-> [i \in 1 .. 4 |-> 0],
      subCode    |-> [i \in 1 .. 4 |-> 0],
      ordId      |-> [i \in 1 .. 8 |-> 0],
      instIdCode |-> [i \in 1 .. 8 |-> 0],
      tsOptional |-> [i \in 1 .. 8 |-> 0],
      clOrdId    |-> [i \in 1 .. 8 |-> 0],
      tag        |-> [i \in 1 .. 8 |-> 0],
      inTime     |-> [i \in 1 .. 8 |-> 0],
      outTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Place Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrderResponseMessage ==
    { ZeroPlaceOrderResponseMessage }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.code = one] : one \in Sample(4) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.subCode = one] : one \in Sample(4) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.tsOptional = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.tag = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.inTime = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrderResponseMessage EXCEPT !.outTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Place Orders Message orders Group: 46 bytes                             *)
(***************************************************************************)

PlaceOrdersMessageOrdersGroup ==
    [ instIdCode     : Sample(8),
      side           : Sample(1),
      ordType        : Sample(1),
      tdMode         : Sample(1),
      szExponent     : Sample(1),
      szMantissa     : Sample(8),
      pxExponent     : Sample(1),
      pxMantissa     : Sample(8),
      clOrdId        : Sample(8),
      tag            : Sample(8),
      rpiTakerAccess : Sample(1) ]

EncodePlaceOrdersMessageOrdersGroup(message) ==
    message.instIdCode
        \o message.side
        \o message.ordType
        \o message.tdMode
        \o message.szExponent
        \o message.szMantissa
        \o message.pxExponent
        \o message.pxMantissa
        \o message.clOrdId
        \o message.tag
        \o message.rpiTakerAccess

DecodePlaceOrdersMessageOrdersGroup(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET side == ReadBytes(instIdCode.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET tdMode == ReadBytes(ordType.rest, 1) IN IF ~tdMode.ok THEN Fail ELSE
    LET szExponent == ReadBytes(tdMode.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(szExponent.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(szMantissa.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET pxMantissa == ReadBytes(pxExponent.rest, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(pxMantissa.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET tag == ReadBytes(clOrdId.rest, 8) IN IF ~tag.ok THEN Fail ELSE
    LET rpiTakerAccess == ReadBytes(tag.rest, 1) IN IF ~rpiTakerAccess.ok THEN Fail ELSE
    Ok([ instIdCode     |-> instIdCode.value,
         side           |-> side.value,
         ordType        |-> ordType.value,
         tdMode         |-> tdMode.value,
         szExponent     |-> szExponent.value,
         szMantissa     |-> szMantissa.value,
         pxExponent     |-> pxExponent.value,
         pxMantissa     |-> pxMantissa.value,
         clOrdId        |-> clOrdId.value,
         tag            |-> tag.value,
         rpiTakerAccess |-> rpiTakerAccess.value ], rpiTakerAccess.rest)

ZeroPlaceOrdersMessageOrdersGroup ==
    [ instIdCode     |-> [i \in 1 .. 8 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      ordType        |-> [i \in 1 .. 1 |-> 0],
      tdMode         |-> [i \in 1 .. 1 |-> 0],
      szExponent     |-> [i \in 1 .. 1 |-> 0],
      szMantissa     |-> [i \in 1 .. 8 |-> 0],
      pxExponent     |-> [i \in 1 .. 1 |-> 0],
      pxMantissa     |-> [i \in 1 .. 8 |-> 0],
      clOrdId        |-> [i \in 1 .. 8 |-> 0],
      tag            |-> [i \in 1 .. 8 |-> 0],
      rpiTakerAccess |-> [i \in 1 .. 1 |-> 0] ]

(* Place Orders Message orders Group at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrdersMessageOrdersGroup ==
    { ZeroPlaceOrdersMessageOrdersGroup }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.tdMode = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.tag = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroup EXCEPT !.rpiTakerAccess = one] : one \in Sample(1) }

(* A run of Place Orders Message orders Group, written one after another *)
RECURSIVE EncodePlaceOrdersMessageOrdersGroupList(_)
EncodePlaceOrdersMessageOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePlaceOrdersMessageOrdersGroup(Head(messages)) \o EncodePlaceOrdersMessageOrdersGroupList(Tail(messages))

(* As many Place Orders Message orders Group as the field that counts them says *)
RECURSIVE ReadPlaceOrdersMessageOrdersGroupList(_, _)
ReadPlaceOrdersMessageOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePlaceOrdersMessageOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPlaceOrdersMessageOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Place Orders Message orders Group of each kind, for the lists that carry them *)
OnePlaceOrdersMessageOrdersGroup == { ZeroPlaceOrdersMessageOrdersGroup }

(***************************************************************************)
(* Place Orders Message orders Groups                                      *)
(***************************************************************************)

PlaceOrdersMessageOrdersGroups ==
    [ blockLength                   : Sample(2),
      placeOrdersMessageOrdersGroup : SampleLists(OnePlaceOrdersMessageOrdersGroup) ]

EncodePlaceOrdersMessageOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.placeOrdersMessageOrdersGroup), 2)
        \o EncodePlaceOrdersMessageOrdersGroupList(message.placeOrdersMessageOrdersGroup)

DecodePlaceOrdersMessageOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET placeOrdersMessageOrdersGroup == ReadPlaceOrdersMessageOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~placeOrdersMessageOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         placeOrdersMessageOrdersGroup |-> placeOrdersMessageOrdersGroup.value ], placeOrdersMessageOrdersGroup.rest)

ZeroPlaceOrdersMessageOrdersGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      placeOrdersMessageOrdersGroup |-> << >> ]

(* Place Orders Message orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrdersMessageOrdersGroups ==
    { ZeroPlaceOrdersMessageOrdersGroups }
        \cup { [ZeroPlaceOrdersMessageOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPlaceOrdersMessageOrdersGroups EXCEPT !.placeOrdersMessageOrdersGroup = one] : one \in SampleLists(OnePlaceOrdersMessageOrdersGroup) }

(***************************************************************************)
(* Place Orders Message                                                    *)
(***************************************************************************)

PlaceOrdersMessage ==
    [ id                             : Sample(8),
      expTime                        : Sample(8),
      placeOrdersMessageOrdersGroups : PlaceOrdersMessageOrdersGroups ]

EncodePlaceOrdersMessage(message) ==
    message.id
        \o message.expTime
        \o EncodePlaceOrdersMessageOrdersGroups(message.placeOrdersMessageOrdersGroups)

DecodePlaceOrdersMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET expTime == ReadBytes(id.rest, 8) IN IF ~expTime.ok THEN Fail ELSE
    LET placeOrdersMessageOrdersGroups == DecodePlaceOrdersMessageOrdersGroups(expTime.rest) IN IF ~placeOrdersMessageOrdersGroups.ok THEN Fail ELSE
    Ok([ id                             |-> id.value,
         expTime                        |-> expTime.value,
         placeOrdersMessageOrdersGroups |-> placeOrdersMessageOrdersGroups.value ], placeOrdersMessageOrdersGroups.rest)

ZeroPlaceOrdersMessage ==
    [ id                             |-> [i \in 1 .. 8 |-> 0],
      expTime                        |-> [i \in 1 .. 8 |-> 0],
      placeOrdersMessageOrdersGroups |-> ZeroPlaceOrdersMessageOrdersGroups ]

(* Place Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrdersMessage ==
    { ZeroPlaceOrdersMessage }
        \cup { [ZeroPlaceOrdersMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessage EXCEPT !.expTime = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersMessage EXCEPT !.placeOrdersMessageOrdersGroups = one] : one \in CheckedPlaceOrdersMessageOrdersGroups }

(***************************************************************************)
(* Place Orders Response Message data Group: 64 bytes                      *)
(***************************************************************************)

PlaceOrdersResponseMessageDataGroup ==
    [ sCode      : Sample(4),
      subCode    : Sample(4),
      ordId      : Sample(8),
      instIdCode : Sample(8),
      tsOptional : Sample(8),
      clOrdId    : Sample(8),
      tag        : Sample(8),
      inTime     : Sample(8),
      outTime    : Sample(8) ]

EncodePlaceOrdersResponseMessageDataGroup(message) ==
    message.sCode
        \o message.subCode
        \o message.ordId
        \o message.instIdCode
        \o message.tsOptional
        \o message.clOrdId
        \o message.tag
        \o message.inTime
        \o message.outTime

DecodePlaceOrdersResponseMessageDataGroup(bytes) ==
    LET sCode == ReadBytes(bytes, 4) IN IF ~sCode.ok THEN Fail ELSE
    LET subCode == ReadBytes(sCode.rest, 4) IN IF ~subCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(subCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET instIdCode == ReadBytes(ordId.rest, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsOptional == ReadBytes(instIdCode.rest, 8) IN IF ~tsOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tsOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET tag == ReadBytes(clOrdId.rest, 8) IN IF ~tag.ok THEN Fail ELSE
    LET inTime == ReadBytes(tag.rest, 8) IN IF ~inTime.ok THEN Fail ELSE
    LET outTime == ReadBytes(inTime.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    Ok([ sCode      |-> sCode.value,
         subCode    |-> subCode.value,
         ordId      |-> ordId.value,
         instIdCode |-> instIdCode.value,
         tsOptional |-> tsOptional.value,
         clOrdId    |-> clOrdId.value,
         tag        |-> tag.value,
         inTime     |-> inTime.value,
         outTime    |-> outTime.value ], outTime.rest)

ZeroPlaceOrdersResponseMessageDataGroup ==
    [ sCode      |-> [i \in 1 .. 4 |-> 0],
      subCode    |-> [i \in 1 .. 4 |-> 0],
      ordId      |-> [i \in 1 .. 8 |-> 0],
      instIdCode |-> [i \in 1 .. 8 |-> 0],
      tsOptional |-> [i \in 1 .. 8 |-> 0],
      clOrdId    |-> [i \in 1 .. 8 |-> 0],
      tag        |-> [i \in 1 .. 8 |-> 0],
      inTime     |-> [i \in 1 .. 8 |-> 0],
      outTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Place Orders Response Message data Group at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrdersResponseMessageDataGroup ==
    { ZeroPlaceOrdersResponseMessageDataGroup }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.sCode = one] : one \in Sample(4) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.subCode = one] : one \in Sample(4) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.tsOptional = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.tag = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.inTime = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroup EXCEPT !.outTime = one] : one \in Sample(8) }

(* A run of Place Orders Response Message data Group, written one after another *)
RECURSIVE EncodePlaceOrdersResponseMessageDataGroupList(_)
EncodePlaceOrdersResponseMessageDataGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePlaceOrdersResponseMessageDataGroup(Head(messages)) \o EncodePlaceOrdersResponseMessageDataGroupList(Tail(messages))

(* As many Place Orders Response Message data Group as the field that counts them says *)
RECURSIVE ReadPlaceOrdersResponseMessageDataGroupList(_, _)
ReadPlaceOrdersResponseMessageDataGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePlaceOrdersResponseMessageDataGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPlaceOrdersResponseMessageDataGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Place Orders Response Message data Group of each kind, for the lists that carry them *)
OnePlaceOrdersResponseMessageDataGroup == { ZeroPlaceOrdersResponseMessageDataGroup }

(***************************************************************************)
(* Place Orders Response Message data Groups                               *)
(***************************************************************************)

PlaceOrdersResponseMessageDataGroups ==
    [ blockLength                         : Sample(2),
      placeOrdersResponseMessageDataGroup : SampleLists(OnePlaceOrdersResponseMessageDataGroup) ]

EncodePlaceOrdersResponseMessageDataGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.placeOrdersResponseMessageDataGroup), 2)
        \o EncodePlaceOrdersResponseMessageDataGroupList(message.placeOrdersResponseMessageDataGroup)

DecodePlaceOrdersResponseMessageDataGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET placeOrdersResponseMessageDataGroup == ReadPlaceOrdersResponseMessageDataGroupList(numInGroup.rest, numInGroup.value) IN IF ~placeOrdersResponseMessageDataGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         placeOrdersResponseMessageDataGroup |-> placeOrdersResponseMessageDataGroup.value ], placeOrdersResponseMessageDataGroup.rest)

ZeroPlaceOrdersResponseMessageDataGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      placeOrdersResponseMessageDataGroup |-> << >> ]

(* Place Orders Response Message data Groups at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrdersResponseMessageDataGroups ==
    { ZeroPlaceOrdersResponseMessageDataGroups }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPlaceOrdersResponseMessageDataGroups EXCEPT !.placeOrdersResponseMessageDataGroup = one] : one \in SampleLists(OnePlaceOrdersResponseMessageDataGroup) }

(***************************************************************************)
(* Place Orders Response Message                                           *)
(***************************************************************************)

PlaceOrdersResponseMessage ==
    [ id                                   : Sample(8),
      code                                 : Sample(4),
      placeOrdersResponseMessageDataGroups : PlaceOrdersResponseMessageDataGroups ]

EncodePlaceOrdersResponseMessage(message) ==
    message.id
        \o message.code
        \o EncodePlaceOrdersResponseMessageDataGroups(message.placeOrdersResponseMessageDataGroups)

DecodePlaceOrdersResponseMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET code == ReadBytes(id.rest, 4) IN IF ~code.ok THEN Fail ELSE
    LET placeOrdersResponseMessageDataGroups == DecodePlaceOrdersResponseMessageDataGroups(code.rest) IN IF ~placeOrdersResponseMessageDataGroups.ok THEN Fail ELSE
    Ok([ id                                   |-> id.value,
         code                                 |-> code.value,
         placeOrdersResponseMessageDataGroups |-> placeOrdersResponseMessageDataGroups.value ], placeOrdersResponseMessageDataGroups.rest)

ZeroPlaceOrdersResponseMessage ==
    [ id                                   |-> [i \in 1 .. 8 |-> 0],
      code                                 |-> [i \in 1 .. 4 |-> 0],
      placeOrdersResponseMessageDataGroups |-> ZeroPlaceOrdersResponseMessageDataGroups ]

(* Place Orders Response Message at zero, then each field in turn at the values it is checked at *)
CheckedPlaceOrdersResponseMessage ==
    { ZeroPlaceOrdersResponseMessage }
        \cup { [ZeroPlaceOrdersResponseMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroPlaceOrdersResponseMessage EXCEPT !.code = one] : one \in Sample(4) }
        \cup { [ZeroPlaceOrdersResponseMessage EXCEPT !.placeOrdersResponseMessageDataGroups = one] : one \in CheckedPlaceOrdersResponseMessageDataGroups }

(***************************************************************************)
(* Amend Order Message: 67 bytes                                           *)
(***************************************************************************)

AmendOrderMessage ==
    [ id             : Sample(8),
      instIdCode     : Sample(8),
      ordId          : Sample(8),
      clOrdId        : Sample(8),
      newSzExponent  : Sample(1),
      newSzMantissa  : Sample(8),
      newPxExponent  : Sample(1),
      newPxMantissa  : Sample(8),
      reqId          : Sample(8),
      expTime        : Sample(8),
      rpiTakerAccess : Sample(1) ]

EncodeAmendOrderMessage(message) ==
    message.id
        \o message.instIdCode
        \o message.ordId
        \o message.clOrdId
        \o message.newSzExponent
        \o message.newSzMantissa
        \o message.newPxExponent
        \o message.newPxMantissa
        \o message.reqId
        \o message.expTime
        \o message.rpiTakerAccess

DecodeAmendOrderMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET instIdCode == ReadBytes(id.rest, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(instIdCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ordId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET newSzExponent == ReadBytes(clOrdId.rest, 1) IN IF ~newSzExponent.ok THEN Fail ELSE
    LET newSzMantissa == ReadBytes(newSzExponent.rest, 8) IN IF ~newSzMantissa.ok THEN Fail ELSE
    LET newPxExponent == ReadBytes(newSzMantissa.rest, 1) IN IF ~newPxExponent.ok THEN Fail ELSE
    LET newPxMantissa == ReadBytes(newPxExponent.rest, 8) IN IF ~newPxMantissa.ok THEN Fail ELSE
    LET reqId == ReadBytes(newPxMantissa.rest, 8) IN IF ~reqId.ok THEN Fail ELSE
    LET expTime == ReadBytes(reqId.rest, 8) IN IF ~expTime.ok THEN Fail ELSE
    LET rpiTakerAccess == ReadBytes(expTime.rest, 1) IN IF ~rpiTakerAccess.ok THEN Fail ELSE
    Ok([ id             |-> id.value,
         instIdCode     |-> instIdCode.value,
         ordId          |-> ordId.value,
         clOrdId        |-> clOrdId.value,
         newSzExponent  |-> newSzExponent.value,
         newSzMantissa  |-> newSzMantissa.value,
         newPxExponent  |-> newPxExponent.value,
         newPxMantissa  |-> newPxMantissa.value,
         reqId          |-> reqId.value,
         expTime        |-> expTime.value,
         rpiTakerAccess |-> rpiTakerAccess.value ], rpiTakerAccess.rest)

ZeroAmendOrderMessage ==
    [ id             |-> [i \in 1 .. 8 |-> 0],
      instIdCode     |-> [i \in 1 .. 8 |-> 0],
      ordId          |-> [i \in 1 .. 8 |-> 0],
      clOrdId        |-> [i \in 1 .. 8 |-> 0],
      newSzExponent  |-> [i \in 1 .. 1 |-> 0],
      newSzMantissa  |-> [i \in 1 .. 8 |-> 0],
      newPxExponent  |-> [i \in 1 .. 1 |-> 0],
      newPxMantissa  |-> [i \in 1 .. 8 |-> 0],
      reqId          |-> [i \in 1 .. 8 |-> 0],
      expTime        |-> [i \in 1 .. 8 |-> 0],
      rpiTakerAccess |-> [i \in 1 .. 1 |-> 0] ]

(* Amend Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderMessage ==
    { ZeroAmendOrderMessage }
        \cup { [ZeroAmendOrderMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.newSzExponent = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.newSzMantissa = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.newPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.newPxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.reqId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.expTime = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderMessage EXCEPT !.rpiTakerAccess = one] : one \in Sample(1) }

(***************************************************************************)
(* Amend Order Response Message: 64 bytes                                  *)
(***************************************************************************)

AmendOrderResponseMessage ==
    [ id           : Sample(8),
      codeOptional : Sample(4),
      subCode      : Sample(4),
      ordId        : Sample(8),
      reqId        : Sample(8),
      tsOptional   : Sample(8),
      clOrdId      : Sample(8),
      inTime       : Sample(8),
      outTime      : Sample(8) ]

EncodeAmendOrderResponseMessage(message) ==
    message.id
        \o message.codeOptional
        \o message.subCode
        \o message.ordId
        \o message.reqId
        \o message.tsOptional
        \o message.clOrdId
        \o message.inTime
        \o message.outTime

DecodeAmendOrderResponseMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET codeOptional == ReadBytes(id.rest, 4) IN IF ~codeOptional.ok THEN Fail ELSE
    LET subCode == ReadBytes(codeOptional.rest, 4) IN IF ~subCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(subCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET reqId == ReadBytes(ordId.rest, 8) IN IF ~reqId.ok THEN Fail ELSE
    LET tsOptional == ReadBytes(reqId.rest, 8) IN IF ~tsOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tsOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET inTime == ReadBytes(clOrdId.rest, 8) IN IF ~inTime.ok THEN Fail ELSE
    LET outTime == ReadBytes(inTime.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    Ok([ id           |-> id.value,
         codeOptional |-> codeOptional.value,
         subCode      |-> subCode.value,
         ordId        |-> ordId.value,
         reqId        |-> reqId.value,
         tsOptional   |-> tsOptional.value,
         clOrdId      |-> clOrdId.value,
         inTime       |-> inTime.value,
         outTime      |-> outTime.value ], outTime.rest)

ZeroAmendOrderResponseMessage ==
    [ id           |-> [i \in 1 .. 8 |-> 0],
      codeOptional |-> [i \in 1 .. 4 |-> 0],
      subCode      |-> [i \in 1 .. 4 |-> 0],
      ordId        |-> [i \in 1 .. 8 |-> 0],
      reqId        |-> [i \in 1 .. 8 |-> 0],
      tsOptional   |-> [i \in 1 .. 8 |-> 0],
      clOrdId      |-> [i \in 1 .. 8 |-> 0],
      inTime       |-> [i \in 1 .. 8 |-> 0],
      outTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Amend Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrderResponseMessage ==
    { ZeroAmendOrderResponseMessage }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.codeOptional = one] : one \in Sample(4) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.subCode = one] : one \in Sample(4) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.reqId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.tsOptional = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.inTime = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrderResponseMessage EXCEPT !.outTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Amend Orders Message orders Group: 51 bytes                             *)
(***************************************************************************)

AmendOrdersMessageOrdersGroup ==
    [ instIdCode     : Sample(8),
      ordId          : Sample(8),
      clOrdId        : Sample(8),
      newSzExponent  : Sample(1),
      newSzMantissa  : Sample(8),
      newPxExponent  : Sample(1),
      newPxMantissa  : Sample(8),
      reqId          : Sample(8),
      rpiTakerAccess : Sample(1) ]

EncodeAmendOrdersMessageOrdersGroup(message) ==
    message.instIdCode
        \o message.ordId
        \o message.clOrdId
        \o message.newSzExponent
        \o message.newSzMantissa
        \o message.newPxExponent
        \o message.newPxMantissa
        \o message.reqId
        \o message.rpiTakerAccess

DecodeAmendOrdersMessageOrdersGroup(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(instIdCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ordId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET newSzExponent == ReadBytes(clOrdId.rest, 1) IN IF ~newSzExponent.ok THEN Fail ELSE
    LET newSzMantissa == ReadBytes(newSzExponent.rest, 8) IN IF ~newSzMantissa.ok THEN Fail ELSE
    LET newPxExponent == ReadBytes(newSzMantissa.rest, 1) IN IF ~newPxExponent.ok THEN Fail ELSE
    LET newPxMantissa == ReadBytes(newPxExponent.rest, 8) IN IF ~newPxMantissa.ok THEN Fail ELSE
    LET reqId == ReadBytes(newPxMantissa.rest, 8) IN IF ~reqId.ok THEN Fail ELSE
    LET rpiTakerAccess == ReadBytes(reqId.rest, 1) IN IF ~rpiTakerAccess.ok THEN Fail ELSE
    Ok([ instIdCode     |-> instIdCode.value,
         ordId          |-> ordId.value,
         clOrdId        |-> clOrdId.value,
         newSzExponent  |-> newSzExponent.value,
         newSzMantissa  |-> newSzMantissa.value,
         newPxExponent  |-> newPxExponent.value,
         newPxMantissa  |-> newPxMantissa.value,
         reqId          |-> reqId.value,
         rpiTakerAccess |-> rpiTakerAccess.value ], rpiTakerAccess.rest)

ZeroAmendOrdersMessageOrdersGroup ==
    [ instIdCode     |-> [i \in 1 .. 8 |-> 0],
      ordId          |-> [i \in 1 .. 8 |-> 0],
      clOrdId        |-> [i \in 1 .. 8 |-> 0],
      newSzExponent  |-> [i \in 1 .. 1 |-> 0],
      newSzMantissa  |-> [i \in 1 .. 8 |-> 0],
      newPxExponent  |-> [i \in 1 .. 1 |-> 0],
      newPxMantissa  |-> [i \in 1 .. 8 |-> 0],
      reqId          |-> [i \in 1 .. 8 |-> 0],
      rpiTakerAccess |-> [i \in 1 .. 1 |-> 0] ]

(* Amend Orders Message orders Group at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrdersMessageOrdersGroup ==
    { ZeroAmendOrdersMessageOrdersGroup }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.newSzExponent = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.newSzMantissa = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.newPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.newPxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.reqId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessageOrdersGroup EXCEPT !.rpiTakerAccess = one] : one \in Sample(1) }

(* A run of Amend Orders Message orders Group, written one after another *)
RECURSIVE EncodeAmendOrdersMessageOrdersGroupList(_)
EncodeAmendOrdersMessageOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAmendOrdersMessageOrdersGroup(Head(messages)) \o EncodeAmendOrdersMessageOrdersGroupList(Tail(messages))

(* As many Amend Orders Message orders Group as the field that counts them says *)
RECURSIVE ReadAmendOrdersMessageOrdersGroupList(_, _)
ReadAmendOrdersMessageOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAmendOrdersMessageOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAmendOrdersMessageOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Amend Orders Message orders Group of each kind, for the lists that carry them *)
OneAmendOrdersMessageOrdersGroup == { ZeroAmendOrdersMessageOrdersGroup }

(***************************************************************************)
(* Amend Orders Message orders Groups                                      *)
(***************************************************************************)

AmendOrdersMessageOrdersGroups ==
    [ blockLength                   : Sample(2),
      amendOrdersMessageOrdersGroup : SampleLists(OneAmendOrdersMessageOrdersGroup) ]

EncodeAmendOrdersMessageOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.amendOrdersMessageOrdersGroup), 2)
        \o EncodeAmendOrdersMessageOrdersGroupList(message.amendOrdersMessageOrdersGroup)

DecodeAmendOrdersMessageOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET amendOrdersMessageOrdersGroup == ReadAmendOrdersMessageOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~amendOrdersMessageOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         amendOrdersMessageOrdersGroup |-> amendOrdersMessageOrdersGroup.value ], amendOrdersMessageOrdersGroup.rest)

ZeroAmendOrdersMessageOrdersGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      amendOrdersMessageOrdersGroup |-> << >> ]

(* Amend Orders Message orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrdersMessageOrdersGroups ==
    { ZeroAmendOrdersMessageOrdersGroups }
        \cup { [ZeroAmendOrdersMessageOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroAmendOrdersMessageOrdersGroups EXCEPT !.amendOrdersMessageOrdersGroup = one] : one \in SampleLists(OneAmendOrdersMessageOrdersGroup) }

(***************************************************************************)
(* Amend Orders Message                                                    *)
(***************************************************************************)

AmendOrdersMessage ==
    [ id                             : Sample(8),
      expTime                        : Sample(8),
      amendOrdersMessageOrdersGroups : AmendOrdersMessageOrdersGroups ]

EncodeAmendOrdersMessage(message) ==
    message.id
        \o message.expTime
        \o EncodeAmendOrdersMessageOrdersGroups(message.amendOrdersMessageOrdersGroups)

DecodeAmendOrdersMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET expTime == ReadBytes(id.rest, 8) IN IF ~expTime.ok THEN Fail ELSE
    LET amendOrdersMessageOrdersGroups == DecodeAmendOrdersMessageOrdersGroups(expTime.rest) IN IF ~amendOrdersMessageOrdersGroups.ok THEN Fail ELSE
    Ok([ id                             |-> id.value,
         expTime                        |-> expTime.value,
         amendOrdersMessageOrdersGroups |-> amendOrdersMessageOrdersGroups.value ], amendOrdersMessageOrdersGroups.rest)

ZeroAmendOrdersMessage ==
    [ id                             |-> [i \in 1 .. 8 |-> 0],
      expTime                        |-> [i \in 1 .. 8 |-> 0],
      amendOrdersMessageOrdersGroups |-> ZeroAmendOrdersMessageOrdersGroups ]

(* Amend Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrdersMessage ==
    { ZeroAmendOrdersMessage }
        \cup { [ZeroAmendOrdersMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessage EXCEPT !.expTime = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersMessage EXCEPT !.amendOrdersMessageOrdersGroups = one] : one \in CheckedAmendOrdersMessageOrdersGroups }

(***************************************************************************)
(* Amend Orders Response Message data Group: 56 bytes                      *)
(***************************************************************************)

AmendOrdersResponseMessageDataGroup ==
    [ sCode   : Sample(4),
      subCode : Sample(4),
      ordId   : Sample(8),
      reqId   : Sample(8),
      ts      : Sample(8),
      clOrdId : Sample(8),
      inTime  : Sample(8),
      outTime : Sample(8) ]

EncodeAmendOrdersResponseMessageDataGroup(message) ==
    message.sCode
        \o message.subCode
        \o message.ordId
        \o message.reqId
        \o message.ts
        \o message.clOrdId
        \o message.inTime
        \o message.outTime

DecodeAmendOrdersResponseMessageDataGroup(bytes) ==
    LET sCode == ReadBytes(bytes, 4) IN IF ~sCode.ok THEN Fail ELSE
    LET subCode == ReadBytes(sCode.rest, 4) IN IF ~subCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(subCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET reqId == ReadBytes(ordId.rest, 8) IN IF ~reqId.ok THEN Fail ELSE
    LET ts == ReadBytes(reqId.rest, 8) IN IF ~ts.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ts.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET inTime == ReadBytes(clOrdId.rest, 8) IN IF ~inTime.ok THEN Fail ELSE
    LET outTime == ReadBytes(inTime.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    Ok([ sCode   |-> sCode.value,
         subCode |-> subCode.value,
         ordId   |-> ordId.value,
         reqId   |-> reqId.value,
         ts      |-> ts.value,
         clOrdId |-> clOrdId.value,
         inTime  |-> inTime.value,
         outTime |-> outTime.value ], outTime.rest)

ZeroAmendOrdersResponseMessageDataGroup ==
    [ sCode   |-> [i \in 1 .. 4 |-> 0],
      subCode |-> [i \in 1 .. 4 |-> 0],
      ordId   |-> [i \in 1 .. 8 |-> 0],
      reqId   |-> [i \in 1 .. 8 |-> 0],
      ts      |-> [i \in 1 .. 8 |-> 0],
      clOrdId |-> [i \in 1 .. 8 |-> 0],
      inTime  |-> [i \in 1 .. 8 |-> 0],
      outTime |-> [i \in 1 .. 8 |-> 0] ]

(* Amend Orders Response Message data Group at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrdersResponseMessageDataGroup ==
    { ZeroAmendOrdersResponseMessageDataGroup }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.sCode = one] : one \in Sample(4) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.subCode = one] : one \in Sample(4) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.reqId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.ts = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.inTime = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroup EXCEPT !.outTime = one] : one \in Sample(8) }

(* A run of Amend Orders Response Message data Group, written one after another *)
RECURSIVE EncodeAmendOrdersResponseMessageDataGroupList(_)
EncodeAmendOrdersResponseMessageDataGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAmendOrdersResponseMessageDataGroup(Head(messages)) \o EncodeAmendOrdersResponseMessageDataGroupList(Tail(messages))

(* As many Amend Orders Response Message data Group as the field that counts them says *)
RECURSIVE ReadAmendOrdersResponseMessageDataGroupList(_, _)
ReadAmendOrdersResponseMessageDataGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAmendOrdersResponseMessageDataGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAmendOrdersResponseMessageDataGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Amend Orders Response Message data Group of each kind, for the lists that carry them *)
OneAmendOrdersResponseMessageDataGroup == { ZeroAmendOrdersResponseMessageDataGroup }

(***************************************************************************)
(* Amend Orders Response Message data Groups                               *)
(***************************************************************************)

AmendOrdersResponseMessageDataGroups ==
    [ blockLength                         : Sample(2),
      amendOrdersResponseMessageDataGroup : SampleLists(OneAmendOrdersResponseMessageDataGroup) ]

EncodeAmendOrdersResponseMessageDataGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.amendOrdersResponseMessageDataGroup), 2)
        \o EncodeAmendOrdersResponseMessageDataGroupList(message.amendOrdersResponseMessageDataGroup)

DecodeAmendOrdersResponseMessageDataGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET amendOrdersResponseMessageDataGroup == ReadAmendOrdersResponseMessageDataGroupList(numInGroup.rest, numInGroup.value) IN IF ~amendOrdersResponseMessageDataGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         amendOrdersResponseMessageDataGroup |-> amendOrdersResponseMessageDataGroup.value ], amendOrdersResponseMessageDataGroup.rest)

ZeroAmendOrdersResponseMessageDataGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      amendOrdersResponseMessageDataGroup |-> << >> ]

(* Amend Orders Response Message data Groups at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrdersResponseMessageDataGroups ==
    { ZeroAmendOrdersResponseMessageDataGroups }
        \cup { [ZeroAmendOrdersResponseMessageDataGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroAmendOrdersResponseMessageDataGroups EXCEPT !.amendOrdersResponseMessageDataGroup = one] : one \in SampleLists(OneAmendOrdersResponseMessageDataGroup) }

(***************************************************************************)
(* Amend Orders Response Message                                           *)
(***************************************************************************)

AmendOrdersResponseMessage ==
    [ id                                   : Sample(8),
      codeOptional                         : Sample(4),
      amendOrdersResponseMessageDataGroups : AmendOrdersResponseMessageDataGroups ]

EncodeAmendOrdersResponseMessage(message) ==
    message.id
        \o message.codeOptional
        \o EncodeAmendOrdersResponseMessageDataGroups(message.amendOrdersResponseMessageDataGroups)

DecodeAmendOrdersResponseMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET codeOptional == ReadBytes(id.rest, 4) IN IF ~codeOptional.ok THEN Fail ELSE
    LET amendOrdersResponseMessageDataGroups == DecodeAmendOrdersResponseMessageDataGroups(codeOptional.rest) IN IF ~amendOrdersResponseMessageDataGroups.ok THEN Fail ELSE
    Ok([ id                                   |-> id.value,
         codeOptional                         |-> codeOptional.value,
         amendOrdersResponseMessageDataGroups |-> amendOrdersResponseMessageDataGroups.value ], amendOrdersResponseMessageDataGroups.rest)

ZeroAmendOrdersResponseMessage ==
    [ id                                   |-> [i \in 1 .. 8 |-> 0],
      codeOptional                         |-> [i \in 1 .. 4 |-> 0],
      amendOrdersResponseMessageDataGroups |-> ZeroAmendOrdersResponseMessageDataGroups ]

(* Amend Orders Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAmendOrdersResponseMessage ==
    { ZeroAmendOrdersResponseMessage }
        \cup { [ZeroAmendOrdersResponseMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroAmendOrdersResponseMessage EXCEPT !.codeOptional = one] : one \in Sample(4) }
        \cup { [ZeroAmendOrdersResponseMessage EXCEPT !.amendOrdersResponseMessageDataGroups = one] : one \in CheckedAmendOrdersResponseMessageDataGroups }

(***************************************************************************)
(* Cancel Order Message: 32 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ id         : Sample(8),
      instIdCode : Sample(8),
      ordId      : Sample(8),
      clOrdId    : Sample(8) ]

EncodeCancelOrderMessage(message) ==
    message.id
        \o message.instIdCode
        \o message.ordId
        \o message.clOrdId

DecodeCancelOrderMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET instIdCode == ReadBytes(id.rest, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(instIdCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ordId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    Ok([ id         |-> id.value,
         instIdCode |-> instIdCode.value,
         ordId      |-> ordId.value,
         clOrdId    |-> clOrdId.value ], clOrdId.rest)

ZeroCancelOrderMessage ==
    [ id         |-> [i \in 1 .. 8 |-> 0],
      instIdCode |-> [i \in 1 .. 8 |-> 0],
      ordId      |-> [i \in 1 .. 8 |-> 0],
      clOrdId    |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Order Response Message: 52 bytes                                 *)
(***************************************************************************)

CancelOrderResponseMessage ==
    [ id           : Sample(8),
      codeOptional : Sample(4),
      ordId        : Sample(8),
      tsOptional   : Sample(8),
      clOrdId      : Sample(8),
      inTime       : Sample(8),
      outTime      : Sample(8) ]

EncodeCancelOrderResponseMessage(message) ==
    message.id
        \o message.codeOptional
        \o message.ordId
        \o message.tsOptional
        \o message.clOrdId
        \o message.inTime
        \o message.outTime

DecodeCancelOrderResponseMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET codeOptional == ReadBytes(id.rest, 4) IN IF ~codeOptional.ok THEN Fail ELSE
    LET ordId == ReadBytes(codeOptional.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET tsOptional == ReadBytes(ordId.rest, 8) IN IF ~tsOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tsOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET inTime == ReadBytes(clOrdId.rest, 8) IN IF ~inTime.ok THEN Fail ELSE
    LET outTime == ReadBytes(inTime.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    Ok([ id           |-> id.value,
         codeOptional |-> codeOptional.value,
         ordId        |-> ordId.value,
         tsOptional   |-> tsOptional.value,
         clOrdId      |-> clOrdId.value,
         inTime       |-> inTime.value,
         outTime      |-> outTime.value ], outTime.rest)

ZeroCancelOrderResponseMessage ==
    [ id           |-> [i \in 1 .. 8 |-> 0],
      codeOptional |-> [i \in 1 .. 4 |-> 0],
      ordId        |-> [i \in 1 .. 8 |-> 0],
      tsOptional   |-> [i \in 1 .. 8 |-> 0],
      clOrdId      |-> [i \in 1 .. 8 |-> 0],
      inTime       |-> [i \in 1 .. 8 |-> 0],
      outTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderResponseMessage ==
    { ZeroCancelOrderResponseMessage }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.codeOptional = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.tsOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.inTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponseMessage EXCEPT !.outTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Orders Message orders Group: 24 bytes                            *)
(***************************************************************************)

CancelOrdersMessageOrdersGroup ==
    [ instIdCode : Sample(8),
      ordId      : Sample(8),
      clOrdId    : Sample(8) ]

EncodeCancelOrdersMessageOrdersGroup(message) ==
    message.instIdCode
        \o message.ordId
        \o message.clOrdId

DecodeCancelOrdersMessageOrdersGroup(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(instIdCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(ordId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    Ok([ instIdCode |-> instIdCode.value,
         ordId      |-> ordId.value,
         clOrdId    |-> clOrdId.value ], clOrdId.rest)

ZeroCancelOrdersMessageOrdersGroup ==
    [ instIdCode |-> [i \in 1 .. 8 |-> 0],
      ordId      |-> [i \in 1 .. 8 |-> 0],
      clOrdId    |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Orders Message orders Group at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrdersMessageOrdersGroup ==
    { ZeroCancelOrdersMessageOrdersGroup }
        \cup { [ZeroCancelOrdersMessageOrdersGroup EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersMessageOrdersGroup EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersMessageOrdersGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }

(* A run of Cancel Orders Message orders Group, written one after another *)
RECURSIVE EncodeCancelOrdersMessageOrdersGroupList(_)
EncodeCancelOrdersMessageOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelOrdersMessageOrdersGroup(Head(messages)) \o EncodeCancelOrdersMessageOrdersGroupList(Tail(messages))

(* As many Cancel Orders Message orders Group as the field that counts them says *)
RECURSIVE ReadCancelOrdersMessageOrdersGroupList(_, _)
ReadCancelOrdersMessageOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCancelOrdersMessageOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelOrdersMessageOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Orders Message orders Group of each kind, for the lists that carry them *)
OneCancelOrdersMessageOrdersGroup == { ZeroCancelOrdersMessageOrdersGroup }

(***************************************************************************)
(* Cancel Orders Message orders Groups                                     *)
(***************************************************************************)

CancelOrdersMessageOrdersGroups ==
    [ blockLength                    : Sample(2),
      cancelOrdersMessageOrdersGroup : SampleLists(OneCancelOrdersMessageOrdersGroup) ]

EncodeCancelOrdersMessageOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.cancelOrdersMessageOrdersGroup), 2)
        \o EncodeCancelOrdersMessageOrdersGroupList(message.cancelOrdersMessageOrdersGroup)

DecodeCancelOrdersMessageOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET cancelOrdersMessageOrdersGroup == ReadCancelOrdersMessageOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~cancelOrdersMessageOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength                    |-> blockLength.value,
         cancelOrdersMessageOrdersGroup |-> cancelOrdersMessageOrdersGroup.value ], cancelOrdersMessageOrdersGroup.rest)

ZeroCancelOrdersMessageOrdersGroups ==
    [ blockLength                    |-> [i \in 1 .. 2 |-> 0],
      cancelOrdersMessageOrdersGroup |-> << >> ]

(* Cancel Orders Message orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrdersMessageOrdersGroups ==
    { ZeroCancelOrdersMessageOrdersGroups }
        \cup { [ZeroCancelOrdersMessageOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroCancelOrdersMessageOrdersGroups EXCEPT !.cancelOrdersMessageOrdersGroup = one] : one \in SampleLists(OneCancelOrdersMessageOrdersGroup) }

(***************************************************************************)
(* Cancel Orders Message                                                   *)
(***************************************************************************)

CancelOrdersMessage ==
    [ id                              : Sample(8),
      cancelOrdersMessageOrdersGroups : CancelOrdersMessageOrdersGroups ]

EncodeCancelOrdersMessage(message) ==
    message.id
        \o EncodeCancelOrdersMessageOrdersGroups(message.cancelOrdersMessageOrdersGroups)

DecodeCancelOrdersMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET cancelOrdersMessageOrdersGroups == DecodeCancelOrdersMessageOrdersGroups(id.rest) IN IF ~cancelOrdersMessageOrdersGroups.ok THEN Fail ELSE
    Ok([ id                              |-> id.value,
         cancelOrdersMessageOrdersGroups |-> cancelOrdersMessageOrdersGroups.value ], cancelOrdersMessageOrdersGroups.rest)

ZeroCancelOrdersMessage ==
    [ id                              |-> [i \in 1 .. 8 |-> 0],
      cancelOrdersMessageOrdersGroups |-> ZeroCancelOrdersMessageOrdersGroups ]

(* Cancel Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrdersMessage ==
    { ZeroCancelOrdersMessage }
        \cup { [ZeroCancelOrdersMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersMessage EXCEPT !.cancelOrdersMessageOrdersGroups = one] : one \in CheckedCancelOrdersMessageOrdersGroups }

(***************************************************************************)
(* Cancel Orders Response Message data Group: 44 bytes                     *)
(***************************************************************************)

CancelOrdersResponseMessageDataGroup ==
    [ sCode      : Sample(4),
      ordId      : Sample(8),
      tsOptional : Sample(8),
      clOrdId    : Sample(8),
      inTime     : Sample(8),
      outTime    : Sample(8) ]

EncodeCancelOrdersResponseMessageDataGroup(message) ==
    message.sCode
        \o message.ordId
        \o message.tsOptional
        \o message.clOrdId
        \o message.inTime
        \o message.outTime

DecodeCancelOrdersResponseMessageDataGroup(bytes) ==
    LET sCode == ReadBytes(bytes, 4) IN IF ~sCode.ok THEN Fail ELSE
    LET ordId == ReadBytes(sCode.rest, 8) IN IF ~ordId.ok THEN Fail ELSE
    LET tsOptional == ReadBytes(ordId.rest, 8) IN IF ~tsOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tsOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET inTime == ReadBytes(clOrdId.rest, 8) IN IF ~inTime.ok THEN Fail ELSE
    LET outTime == ReadBytes(inTime.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    Ok([ sCode      |-> sCode.value,
         ordId      |-> ordId.value,
         tsOptional |-> tsOptional.value,
         clOrdId    |-> clOrdId.value,
         inTime     |-> inTime.value,
         outTime    |-> outTime.value ], outTime.rest)

ZeroCancelOrdersResponseMessageDataGroup ==
    [ sCode      |-> [i \in 1 .. 4 |-> 0],
      ordId      |-> [i \in 1 .. 8 |-> 0],
      tsOptional |-> [i \in 1 .. 8 |-> 0],
      clOrdId    |-> [i \in 1 .. 8 |-> 0],
      inTime     |-> [i \in 1 .. 8 |-> 0],
      outTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Orders Response Message data Group at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrdersResponseMessageDataGroup ==
    { ZeroCancelOrdersResponseMessageDataGroup }
        \cup { [ZeroCancelOrdersResponseMessageDataGroup EXCEPT !.sCode = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrdersResponseMessageDataGroup EXCEPT !.ordId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersResponseMessageDataGroup EXCEPT !.tsOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersResponseMessageDataGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersResponseMessageDataGroup EXCEPT !.inTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersResponseMessageDataGroup EXCEPT !.outTime = one] : one \in Sample(8) }

(* A run of Cancel Orders Response Message data Group, written one after another *)
RECURSIVE EncodeCancelOrdersResponseMessageDataGroupList(_)
EncodeCancelOrdersResponseMessageDataGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelOrdersResponseMessageDataGroup(Head(messages)) \o EncodeCancelOrdersResponseMessageDataGroupList(Tail(messages))

(* As many Cancel Orders Response Message data Group as the field that counts them says *)
RECURSIVE ReadCancelOrdersResponseMessageDataGroupList(_, _)
ReadCancelOrdersResponseMessageDataGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCancelOrdersResponseMessageDataGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelOrdersResponseMessageDataGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Orders Response Message data Group of each kind, for the lists that carry them *)
OneCancelOrdersResponseMessageDataGroup == { ZeroCancelOrdersResponseMessageDataGroup }

(***************************************************************************)
(* Cancel Orders Response Message data Groups                              *)
(***************************************************************************)

CancelOrdersResponseMessageDataGroups ==
    [ blockLength                          : Sample(2),
      cancelOrdersResponseMessageDataGroup : SampleLists(OneCancelOrdersResponseMessageDataGroup) ]

EncodeCancelOrdersResponseMessageDataGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.cancelOrdersResponseMessageDataGroup), 2)
        \o EncodeCancelOrdersResponseMessageDataGroupList(message.cancelOrdersResponseMessageDataGroup)

DecodeCancelOrdersResponseMessageDataGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET cancelOrdersResponseMessageDataGroup == ReadCancelOrdersResponseMessageDataGroupList(numInGroup.rest, numInGroup.value) IN IF ~cancelOrdersResponseMessageDataGroup.ok THEN Fail ELSE
    Ok([ blockLength                          |-> blockLength.value,
         cancelOrdersResponseMessageDataGroup |-> cancelOrdersResponseMessageDataGroup.value ], cancelOrdersResponseMessageDataGroup.rest)

ZeroCancelOrdersResponseMessageDataGroups ==
    [ blockLength                          |-> [i \in 1 .. 2 |-> 0],
      cancelOrdersResponseMessageDataGroup |-> << >> ]

(* Cancel Orders Response Message data Groups at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrdersResponseMessageDataGroups ==
    { ZeroCancelOrdersResponseMessageDataGroups }
        \cup { [ZeroCancelOrdersResponseMessageDataGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroCancelOrdersResponseMessageDataGroups EXCEPT !.cancelOrdersResponseMessageDataGroup = one] : one \in SampleLists(OneCancelOrdersResponseMessageDataGroup) }

(***************************************************************************)
(* Cancel Orders Response Message                                          *)
(***************************************************************************)

CancelOrdersResponseMessage ==
    [ id                                    : Sample(8),
      codeOptional                          : Sample(4),
      cancelOrdersResponseMessageDataGroups : CancelOrdersResponseMessageDataGroups ]

EncodeCancelOrdersResponseMessage(message) ==
    message.id
        \o message.codeOptional
        \o EncodeCancelOrdersResponseMessageDataGroups(message.cancelOrdersResponseMessageDataGroups)

DecodeCancelOrdersResponseMessage(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET codeOptional == ReadBytes(id.rest, 4) IN IF ~codeOptional.ok THEN Fail ELSE
    LET cancelOrdersResponseMessageDataGroups == DecodeCancelOrdersResponseMessageDataGroups(codeOptional.rest) IN IF ~cancelOrdersResponseMessageDataGroups.ok THEN Fail ELSE
    Ok([ id                                    |-> id.value,
         codeOptional                          |-> codeOptional.value,
         cancelOrdersResponseMessageDataGroups |-> cancelOrdersResponseMessageDataGroups.value ], cancelOrdersResponseMessageDataGroups.rest)

ZeroCancelOrdersResponseMessage ==
    [ id                                    |-> [i \in 1 .. 8 |-> 0],
      codeOptional                          |-> [i \in 1 .. 4 |-> 0],
      cancelOrdersResponseMessageDataGroups |-> ZeroCancelOrdersResponseMessageDataGroups ]

(* Cancel Orders Response Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrdersResponseMessage ==
    { ZeroCancelOrdersResponseMessage }
        \cup { [ZeroCancelOrdersResponseMessage EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrdersResponseMessage EXCEPT !.codeOptional = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrdersResponseMessage EXCEPT !.cancelOrdersResponseMessageDataGroups = one] : one \in CheckedCancelOrdersResponseMessageDataGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

PlaceOrderMessageCode == 1  \* 0x01
PlaceOrderResponseMessageCode == 2  \* 0x02
PlaceOrdersMessageCode == 3  \* 0x03
PlaceOrdersResponseMessageCode == 4  \* 0x04
AmendOrderMessageCode == 5  \* 0x05
AmendOrderResponseMessageCode == 6  \* 0x06
AmendOrdersMessageCode == 7  \* 0x07
AmendOrdersResponseMessageCode == 8  \* 0x08
CancelOrderMessageCode == 9  \* 0x09
CancelOrderResponseMessageCode == 10  \* 0x0a
CancelOrdersMessageCode == 11  \* 0x0b
CancelOrdersResponseMessageCode == 12  \* 0x0c

Payload ==
    [ tag : {PlaceOrderMessageCode}, body : PlaceOrderMessage ]
        \cup [ tag : {PlaceOrderResponseMessageCode}, body : PlaceOrderResponseMessage ]
        \cup [ tag : {PlaceOrdersMessageCode}, body : PlaceOrdersMessage ]
        \cup [ tag : {PlaceOrdersResponseMessageCode}, body : PlaceOrdersResponseMessage ]
        \cup [ tag : {AmendOrderMessageCode}, body : AmendOrderMessage ]
        \cup [ tag : {AmendOrderResponseMessageCode}, body : AmendOrderResponseMessage ]
        \cup [ tag : {AmendOrdersMessageCode}, body : AmendOrdersMessage ]
        \cup [ tag : {AmendOrdersResponseMessageCode}, body : AmendOrdersResponseMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {CancelOrderResponseMessageCode}, body : CancelOrderResponseMessage ]
        \cup [ tag : {CancelOrdersMessageCode}, body : CancelOrdersMessage ]
        \cup [ tag : {CancelOrdersResponseMessageCode}, body : CancelOrdersResponseMessage ]

EncodePayload(message) ==
    CASE message.tag = PlaceOrderMessageCode -> EncodePlaceOrderMessage(message.body)
      [] message.tag = PlaceOrderResponseMessageCode -> EncodePlaceOrderResponseMessage(message.body)
      [] message.tag = PlaceOrdersMessageCode -> EncodePlaceOrdersMessage(message.body)
      [] message.tag = PlaceOrdersResponseMessageCode -> EncodePlaceOrdersResponseMessage(message.body)
      [] message.tag = AmendOrderMessageCode -> EncodeAmendOrderMessage(message.body)
      [] message.tag = AmendOrderResponseMessageCode -> EncodeAmendOrderResponseMessage(message.body)
      [] message.tag = AmendOrdersMessageCode -> EncodeAmendOrdersMessage(message.body)
      [] message.tag = AmendOrdersResponseMessageCode -> EncodeAmendOrdersResponseMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = CancelOrderResponseMessageCode -> EncodeCancelOrderResponseMessage(message.body)
      [] message.tag = CancelOrdersMessageCode -> EncodeCancelOrdersMessage(message.body)
      [] message.tag = CancelOrdersResponseMessageCode -> EncodeCancelOrdersResponseMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = PlaceOrderMessageCode -> DecodePlaceOrderMessage(bytes)
              [] tag = PlaceOrderResponseMessageCode -> DecodePlaceOrderResponseMessage(bytes)
              [] tag = PlaceOrdersMessageCode -> DecodePlaceOrdersMessage(bytes)
              [] tag = PlaceOrdersResponseMessageCode -> DecodePlaceOrdersResponseMessage(bytes)
              [] tag = AmendOrderMessageCode -> DecodeAmendOrderMessage(bytes)
              [] tag = AmendOrderResponseMessageCode -> DecodeAmendOrderResponseMessage(bytes)
              [] tag = AmendOrdersMessageCode -> DecodeAmendOrdersMessage(bytes)
              [] tag = AmendOrdersResponseMessageCode -> DecodeAmendOrdersResponseMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = CancelOrderResponseMessageCode -> DecodeCancelOrderResponseMessage(bytes)
              [] tag = CancelOrdersMessageCode -> DecodeCancelOrdersMessage(bytes)
              [] tag = CancelOrdersResponseMessageCode -> DecodeCancelOrdersResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> PlaceOrderMessageCode, body |-> ZeroPlaceOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> PlaceOrderMessageCode, body |-> one] : one \in CheckedPlaceOrderMessage }
        \cup { [tag |-> PlaceOrderResponseMessageCode, body |-> one] : one \in CheckedPlaceOrderResponseMessage }
        \cup { [tag |-> PlaceOrdersMessageCode, body |-> one] : one \in CheckedPlaceOrdersMessage }
        \cup { [tag |-> PlaceOrdersResponseMessageCode, body |-> one] : one \in CheckedPlaceOrdersResponseMessage }
        \cup { [tag |-> AmendOrderMessageCode, body |-> one] : one \in CheckedAmendOrderMessage }
        \cup { [tag |-> AmendOrderResponseMessageCode, body |-> one] : one \in CheckedAmendOrderResponseMessage }
        \cup { [tag |-> AmendOrdersMessageCode, body |-> one] : one \in CheckedAmendOrdersMessage }
        \cup { [tag |-> AmendOrdersResponseMessageCode, body |-> one] : one \in CheckedAmendOrdersResponseMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> CancelOrderResponseMessageCode, body |-> one] : one \in CheckedCancelOrderResponseMessage }
        \cup { [tag |-> CancelOrdersMessageCode, body |-> one] : one \in CheckedCancelOrdersMessage }
        \cup { [tag |-> CancelOrdersResponseMessageCode, body |-> one] : one \in CheckedCancelOrdersResponseMessage }

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

(* Every Place Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrderMessage ==
    \A message \in CheckedPlaceOrderMessage :
        LET read == DecodePlaceOrderMessage(EncodePlaceOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrderResponseMessage ==
    \A message \in CheckedPlaceOrderResponseMessage :
        LET read == DecodePlaceOrderResponseMessage(EncodePlaceOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Orders Message orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrdersMessageOrdersGroup ==
    \A message \in CheckedPlaceOrdersMessageOrdersGroup :
        LET read == DecodePlaceOrdersMessageOrdersGroup(EncodePlaceOrdersMessageOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Orders Message orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrdersMessageOrdersGroups ==
    \A message \in CheckedPlaceOrdersMessageOrdersGroups :
        LET read == DecodePlaceOrdersMessageOrdersGroups(EncodePlaceOrdersMessageOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrdersMessage ==
    \A message \in CheckedPlaceOrdersMessage :
        LET read == DecodePlaceOrdersMessage(EncodePlaceOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Orders Response Message data Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrdersResponseMessageDataGroup ==
    \A message \in CheckedPlaceOrdersResponseMessageDataGroup :
        LET read == DecodePlaceOrdersResponseMessageDataGroup(EncodePlaceOrdersResponseMessageDataGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Orders Response Message data Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrdersResponseMessageDataGroups ==
    \A message \in CheckedPlaceOrdersResponseMessageDataGroups :
        LET read == DecodePlaceOrdersResponseMessageDataGroups(EncodePlaceOrdersResponseMessageDataGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Place Orders Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPlaceOrdersResponseMessage ==
    \A message \in CheckedPlaceOrdersResponseMessage :
        LET read == DecodePlaceOrdersResponseMessage(EncodePlaceOrdersResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderMessage ==
    \A message \in CheckedAmendOrderMessage :
        LET read == DecodeAmendOrderMessage(EncodeAmendOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrderResponseMessage ==
    \A message \in CheckedAmendOrderResponseMessage :
        LET read == DecodeAmendOrderResponseMessage(EncodeAmendOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Orders Message orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrdersMessageOrdersGroup ==
    \A message \in CheckedAmendOrdersMessageOrdersGroup :
        LET read == DecodeAmendOrdersMessageOrdersGroup(EncodeAmendOrdersMessageOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Orders Message orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrdersMessageOrdersGroups ==
    \A message \in CheckedAmendOrdersMessageOrdersGroups :
        LET read == DecodeAmendOrdersMessageOrdersGroups(EncodeAmendOrdersMessageOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrdersMessage ==
    \A message \in CheckedAmendOrdersMessage :
        LET read == DecodeAmendOrdersMessage(EncodeAmendOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Orders Response Message data Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrdersResponseMessageDataGroup ==
    \A message \in CheckedAmendOrdersResponseMessageDataGroup :
        LET read == DecodeAmendOrdersResponseMessageDataGroup(EncodeAmendOrdersResponseMessageDataGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Orders Response Message data Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrdersResponseMessageDataGroups ==
    \A message \in CheckedAmendOrdersResponseMessageDataGroups :
        LET read == DecodeAmendOrdersResponseMessageDataGroups(EncodeAmendOrdersResponseMessageDataGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Orders Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendOrdersResponseMessage ==
    \A message \in CheckedAmendOrdersResponseMessage :
        LET read == DecodeAmendOrdersResponseMessage(EncodeAmendOrdersResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderResponseMessage ==
    \A message \in CheckedCancelOrderResponseMessage :
        LET read == DecodeCancelOrderResponseMessage(EncodeCancelOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Orders Message orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrdersMessageOrdersGroup ==
    \A message \in CheckedCancelOrdersMessageOrdersGroup :
        LET read == DecodeCancelOrdersMessageOrdersGroup(EncodeCancelOrdersMessageOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Orders Message orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrdersMessageOrdersGroups ==
    \A message \in CheckedCancelOrdersMessageOrdersGroups :
        LET read == DecodeCancelOrdersMessageOrdersGroups(EncodeCancelOrdersMessageOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrdersMessage ==
    \A message \in CheckedCancelOrdersMessage :
        LET read == DecodeCancelOrdersMessage(EncodeCancelOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Orders Response Message data Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrdersResponseMessageDataGroup ==
    \A message \in CheckedCancelOrdersResponseMessageDataGroup :
        LET read == DecodeCancelOrdersResponseMessageDataGroup(EncodeCancelOrdersResponseMessageDataGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Orders Response Message data Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrdersResponseMessageDataGroups ==
    \A message \in CheckedCancelOrdersResponseMessageDataGroups :
        LET read == DecodeCancelOrdersResponseMessageDataGroups(EncodeCancelOrdersResponseMessageDataGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Orders Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrdersResponseMessage ==
    \A message \in CheckedCancelOrdersResponseMessage :
        LET read == DecodeCancelOrdersResponseMessage(EncodeCancelOrdersResponseMessage(message))
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
