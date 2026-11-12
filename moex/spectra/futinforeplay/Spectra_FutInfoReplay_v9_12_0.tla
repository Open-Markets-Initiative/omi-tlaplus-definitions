------------------- MODULE Spectra_FutInfoReplay_v9_12_0 -------------------
(***************************************************************************)
(* Moscow Exchange SIMBA Spectra Futures Instrument Replay v9.12.0         *)
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
(* Note: Message is of no one width: each is read by its own fields, and   *)
(* since every reading of it takes at least 8 bytes off the reader the run *)
(* ends where the data does.                                               *)
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
(* Market Data Packet Header: 16 bytes                                     *)
(***************************************************************************)

MarketDataPacketHeader ==
    [ msgSeqNum   : Sample(4),
      msgSize     : Sample(2),
      msgFlags    : Sample(2),
      sendingTime : Sample(8) ]

EncodeMarketDataPacketHeader(message) ==
    message.msgSeqNum
        \o message.msgSize
        \o message.msgFlags
        \o message.sendingTime

DecodeMarketDataPacketHeader(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET msgSize == ReadBytes(msgSeqNum.rest, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgFlags == ReadBytes(msgSize.rest, 2) IN IF ~msgFlags.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgFlags.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         msgSize     |-> msgSize.value,
         msgFlags    |-> msgFlags.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroMarketDataPacketHeader ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      msgSize     |-> [i \in 1 .. 2 |-> 0],
      msgFlags    |-> [i \in 1 .. 2 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Market Data Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataPacketHeader ==
    { ZeroMarketDataPacketHeader }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgSize = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgFlags = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Definition Message No M D Feed Types Group: 33 bytes           *)
(***************************************************************************)

SecurityDefinitionMessageNoMDFeedTypesGroup ==
    [ mdFeedType  : Sample(25),
      marketDepth : Sample(4),
      mdBookType  : Sample(4) ]

EncodeSecurityDefinitionMessageNoMDFeedTypesGroup(message) ==
    message.mdFeedType
        \o message.marketDepth
        \o message.mdBookType

DecodeSecurityDefinitionMessageNoMDFeedTypesGroup(bytes) ==
    LET mdFeedType == ReadBytes(bytes, 25) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType.rest, 4) IN IF ~marketDepth.ok THEN Fail ELSE
    LET mdBookType == ReadBytes(marketDepth.rest, 4) IN IF ~mdBookType.ok THEN Fail ELSE
    Ok([ mdFeedType  |-> mdFeedType.value,
         marketDepth |-> marketDepth.value,
         mdBookType  |-> mdBookType.value ], mdBookType.rest)

ZeroSecurityDefinitionMessageNoMDFeedTypesGroup ==
    [ mdFeedType  |-> [i \in 1 .. 25 |-> 0],
      marketDepth |-> [i \in 1 .. 4 |-> 0],
      mdBookType  |-> [i \in 1 .. 4 |-> 0] ]

(* Security Definition Message No M D Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoMDFeedTypesGroup ==
    { ZeroSecurityDefinitionMessageNoMDFeedTypesGroup }
        \cup { [ZeroSecurityDefinitionMessageNoMDFeedTypesGroup EXCEPT !.mdFeedType = one] : one \in Sample(25) }
        \cup { [ZeroSecurityDefinitionMessageNoMDFeedTypesGroup EXCEPT !.marketDepth = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoMDFeedTypesGroup EXCEPT !.mdBookType = one] : one \in Sample(4) }

(* A run of Security Definition Message No M D Feed Types Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionMessageNoMDFeedTypesGroupList(_)
EncodeSecurityDefinitionMessageNoMDFeedTypesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionMessageNoMDFeedTypesGroup(Head(messages)) \o EncodeSecurityDefinitionMessageNoMDFeedTypesGroupList(Tail(messages))

(* As many Security Definition Message No M D Feed Types Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionMessageNoMDFeedTypesGroupList(_, _)
ReadSecurityDefinitionMessageNoMDFeedTypesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionMessageNoMDFeedTypesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionMessageNoMDFeedTypesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Message No M D Feed Types Group of each kind, for the lists that carry them *)
OneSecurityDefinitionMessageNoMDFeedTypesGroup == { ZeroSecurityDefinitionMessageNoMDFeedTypesGroup }

(***************************************************************************)
(* Security Definition Message No M D Feed Types Groups                    *)
(***************************************************************************)

SecurityDefinitionMessageNoMDFeedTypesGroups ==
    [ blockLength                                 : Sample(2),
      securityDefinitionMessageNoMDFeedTypesGroup : SampleLists(OneSecurityDefinitionMessageNoMDFeedTypesGroup) ]

EncodeSecurityDefinitionMessageNoMDFeedTypesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityDefinitionMessageNoMDFeedTypesGroup), 1)
        \o EncodeSecurityDefinitionMessageNoMDFeedTypesGroupList(message.securityDefinitionMessageNoMDFeedTypesGroup)

DecodeSecurityDefinitionMessageNoMDFeedTypesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET securityDefinitionMessageNoMDFeedTypesGroup == ReadSecurityDefinitionMessageNoMDFeedTypesGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~securityDefinitionMessageNoMDFeedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength                                 |-> blockLength.value,
         securityDefinitionMessageNoMDFeedTypesGroup |-> securityDefinitionMessageNoMDFeedTypesGroup.value ], securityDefinitionMessageNoMDFeedTypesGroup.rest)

ZeroSecurityDefinitionMessageNoMDFeedTypesGroups ==
    [ blockLength                                 |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionMessageNoMDFeedTypesGroup |-> << >> ]

(* Security Definition Message No M D Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoMDFeedTypesGroups ==
    { ZeroSecurityDefinitionMessageNoMDFeedTypesGroups }
        \cup { [ZeroSecurityDefinitionMessageNoMDFeedTypesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessageNoMDFeedTypesGroups EXCEPT !.securityDefinitionMessageNoMDFeedTypesGroup = one] : one \in SampleLists(OneSecurityDefinitionMessageNoMDFeedTypesGroup) }

(***************************************************************************)
(* Security Definition Message No Underlyings Group: 37 bytes              *)
(***************************************************************************)

SecurityDefinitionMessageNoUnderlyingsGroup ==
    [ underlyingSymbol     : Sample(25),
      underlyingBoard      : Sample(4),
      underlyingSecurityId : Sample(4),
      underlyingFutureId   : Sample(4) ]

EncodeSecurityDefinitionMessageNoUnderlyingsGroup(message) ==
    message.underlyingSymbol
        \o message.underlyingBoard
        \o message.underlyingSecurityId
        \o message.underlyingFutureId

DecodeSecurityDefinitionMessageNoUnderlyingsGroup(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 25) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingBoard == ReadBytes(underlyingSymbol.rest, 4) IN IF ~underlyingBoard.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(underlyingBoard.rest, 4) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingFutureId == ReadBytes(underlyingSecurityId.rest, 4) IN IF ~underlyingFutureId.ok THEN Fail ELSE
    Ok([ underlyingSymbol     |-> underlyingSymbol.value,
         underlyingBoard      |-> underlyingBoard.value,
         underlyingSecurityId |-> underlyingSecurityId.value,
         underlyingFutureId   |-> underlyingFutureId.value ], underlyingFutureId.rest)

ZeroSecurityDefinitionMessageNoUnderlyingsGroup ==
    [ underlyingSymbol     |-> [i \in 1 .. 25 |-> 0],
      underlyingBoard      |-> [i \in 1 .. 4 |-> 0],
      underlyingSecurityId |-> [i \in 1 .. 4 |-> 0],
      underlyingFutureId   |-> [i \in 1 .. 4 |-> 0] ]

(* Security Definition Message No Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoUnderlyingsGroup ==
    { ZeroSecurityDefinitionMessageNoUnderlyingsGroup }
        \cup { [ZeroSecurityDefinitionMessageNoUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(25) }
        \cup { [ZeroSecurityDefinitionMessageNoUnderlyingsGroup EXCEPT !.underlyingBoard = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoUnderlyingsGroup EXCEPT !.underlyingSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoUnderlyingsGroup EXCEPT !.underlyingFutureId = one] : one \in Sample(4) }

(* A run of Security Definition Message No Underlyings Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionMessageNoUnderlyingsGroupList(_)
EncodeSecurityDefinitionMessageNoUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionMessageNoUnderlyingsGroup(Head(messages)) \o EncodeSecurityDefinitionMessageNoUnderlyingsGroupList(Tail(messages))

(* As many Security Definition Message No Underlyings Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionMessageNoUnderlyingsGroupList(_, _)
ReadSecurityDefinitionMessageNoUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionMessageNoUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionMessageNoUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Message No Underlyings Group of each kind, for the lists that carry them *)
OneSecurityDefinitionMessageNoUnderlyingsGroup == { ZeroSecurityDefinitionMessageNoUnderlyingsGroup }

(***************************************************************************)
(* Security Definition Message No Underlyings Groups                       *)
(***************************************************************************)

SecurityDefinitionMessageNoUnderlyingsGroups ==
    [ blockLength                                 : Sample(2),
      securityDefinitionMessageNoUnderlyingsGroup : SampleLists(OneSecurityDefinitionMessageNoUnderlyingsGroup) ]

EncodeSecurityDefinitionMessageNoUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityDefinitionMessageNoUnderlyingsGroup), 1)
        \o EncodeSecurityDefinitionMessageNoUnderlyingsGroupList(message.securityDefinitionMessageNoUnderlyingsGroup)

DecodeSecurityDefinitionMessageNoUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET securityDefinitionMessageNoUnderlyingsGroup == ReadSecurityDefinitionMessageNoUnderlyingsGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~securityDefinitionMessageNoUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                 |-> blockLength.value,
         securityDefinitionMessageNoUnderlyingsGroup |-> securityDefinitionMessageNoUnderlyingsGroup.value ], securityDefinitionMessageNoUnderlyingsGroup.rest)

ZeroSecurityDefinitionMessageNoUnderlyingsGroups ==
    [ blockLength                                 |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionMessageNoUnderlyingsGroup |-> << >> ]

(* Security Definition Message No Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoUnderlyingsGroups ==
    { ZeroSecurityDefinitionMessageNoUnderlyingsGroups }
        \cup { [ZeroSecurityDefinitionMessageNoUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessageNoUnderlyingsGroups EXCEPT !.securityDefinitionMessageNoUnderlyingsGroup = one] : one \in SampleLists(OneSecurityDefinitionMessageNoUnderlyingsGroup) }

(***************************************************************************)
(* Security Definition Message No Legs Group: 33 bytes                     *)
(***************************************************************************)

SecurityDefinitionMessageNoLegsGroup ==
    [ legSymbol     : Sample(25),
      legSecurityId : Sample(4),
      legRatioQty   : Sample(4) ]

EncodeSecurityDefinitionMessageNoLegsGroup(message) ==
    message.legSymbol
        \o message.legSecurityId
        \o message.legRatioQty

DecodeSecurityDefinitionMessageNoLegsGroup(bytes) ==
    LET legSymbol == ReadBytes(bytes, 25) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legSymbol.rest, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSecurityId.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    Ok([ legSymbol     |-> legSymbol.value,
         legSecurityId |-> legSecurityId.value,
         legRatioQty   |-> legRatioQty.value ], legRatioQty.rest)

ZeroSecurityDefinitionMessageNoLegsGroup ==
    [ legSymbol     |-> [i \in 1 .. 25 |-> 0],
      legSecurityId |-> [i \in 1 .. 4 |-> 0],
      legRatioQty   |-> [i \in 1 .. 4 |-> 0] ]

(* Security Definition Message No Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoLegsGroup ==
    { ZeroSecurityDefinitionMessageNoLegsGroup }
        \cup { [ZeroSecurityDefinitionMessageNoLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(25) }
        \cup { [ZeroSecurityDefinitionMessageNoLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(4) }

(* A run of Security Definition Message No Legs Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionMessageNoLegsGroupList(_)
EncodeSecurityDefinitionMessageNoLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionMessageNoLegsGroup(Head(messages)) \o EncodeSecurityDefinitionMessageNoLegsGroupList(Tail(messages))

(* As many Security Definition Message No Legs Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionMessageNoLegsGroupList(_, _)
ReadSecurityDefinitionMessageNoLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionMessageNoLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionMessageNoLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Message No Legs Group of each kind, for the lists that carry them *)
OneSecurityDefinitionMessageNoLegsGroup == { ZeroSecurityDefinitionMessageNoLegsGroup }

(***************************************************************************)
(* Security Definition Message No Legs Groups                              *)
(***************************************************************************)

SecurityDefinitionMessageNoLegsGroups ==
    [ blockLength                          : Sample(2),
      securityDefinitionMessageNoLegsGroup : SampleLists(OneSecurityDefinitionMessageNoLegsGroup) ]

EncodeSecurityDefinitionMessageNoLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityDefinitionMessageNoLegsGroup), 1)
        \o EncodeSecurityDefinitionMessageNoLegsGroupList(message.securityDefinitionMessageNoLegsGroup)

DecodeSecurityDefinitionMessageNoLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET securityDefinitionMessageNoLegsGroup == ReadSecurityDefinitionMessageNoLegsGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~securityDefinitionMessageNoLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                          |-> blockLength.value,
         securityDefinitionMessageNoLegsGroup |-> securityDefinitionMessageNoLegsGroup.value ], securityDefinitionMessageNoLegsGroup.rest)

ZeroSecurityDefinitionMessageNoLegsGroups ==
    [ blockLength                          |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionMessageNoLegsGroup |-> << >> ]

(* Security Definition Message No Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoLegsGroups ==
    { ZeroSecurityDefinitionMessageNoLegsGroups }
        \cup { [ZeroSecurityDefinitionMessageNoLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessageNoLegsGroups EXCEPT !.securityDefinitionMessageNoLegsGroup = one] : one \in SampleLists(OneSecurityDefinitionMessageNoLegsGroup) }

(***************************************************************************)
(* Security Definition Message No Instr Attrib Group: 35 bytes             *)
(***************************************************************************)

SecurityDefinitionMessageNoInstrAttribGroup ==
    [ instrAttribType  : Sample(4),
      instrAttribValue : Sample(31) ]

EncodeSecurityDefinitionMessageNoInstrAttribGroup(message) ==
    message.instrAttribType
        \o message.instrAttribValue

DecodeSecurityDefinitionMessageNoInstrAttribGroup(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 4) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 31) IN IF ~instrAttribValue.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value ], instrAttribValue.rest)

ZeroSecurityDefinitionMessageNoInstrAttribGroup ==
    [ instrAttribType  |-> [i \in 1 .. 4 |-> 0],
      instrAttribValue |-> [i \in 1 .. 31 |-> 0] ]

(* Security Definition Message No Instr Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoInstrAttribGroup ==
    { ZeroSecurityDefinitionMessageNoInstrAttribGroup }
        \cup { [ZeroSecurityDefinitionMessageNoInstrAttribGroup EXCEPT !.instrAttribType = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoInstrAttribGroup EXCEPT !.instrAttribValue = one] : one \in Sample(31) }

(* A run of Security Definition Message No Instr Attrib Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionMessageNoInstrAttribGroupList(_)
EncodeSecurityDefinitionMessageNoInstrAttribGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionMessageNoInstrAttribGroup(Head(messages)) \o EncodeSecurityDefinitionMessageNoInstrAttribGroupList(Tail(messages))

(* As many Security Definition Message No Instr Attrib Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionMessageNoInstrAttribGroupList(_, _)
ReadSecurityDefinitionMessageNoInstrAttribGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionMessageNoInstrAttribGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionMessageNoInstrAttribGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Message No Instr Attrib Group of each kind, for the lists that carry them *)
OneSecurityDefinitionMessageNoInstrAttribGroup == { ZeroSecurityDefinitionMessageNoInstrAttribGroup }

(***************************************************************************)
(* Security Definition Message No Instr Attrib Groups                      *)
(***************************************************************************)

SecurityDefinitionMessageNoInstrAttribGroups ==
    [ blockLength                                 : Sample(2),
      securityDefinitionMessageNoInstrAttribGroup : SampleLists(OneSecurityDefinitionMessageNoInstrAttribGroup) ]

EncodeSecurityDefinitionMessageNoInstrAttribGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityDefinitionMessageNoInstrAttribGroup), 1)
        \o EncodeSecurityDefinitionMessageNoInstrAttribGroupList(message.securityDefinitionMessageNoInstrAttribGroup)

DecodeSecurityDefinitionMessageNoInstrAttribGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET securityDefinitionMessageNoInstrAttribGroup == ReadSecurityDefinitionMessageNoInstrAttribGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~securityDefinitionMessageNoInstrAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength                                 |-> blockLength.value,
         securityDefinitionMessageNoInstrAttribGroup |-> securityDefinitionMessageNoInstrAttribGroup.value ], securityDefinitionMessageNoInstrAttribGroup.rest)

ZeroSecurityDefinitionMessageNoInstrAttribGroups ==
    [ blockLength                                 |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionMessageNoInstrAttribGroup |-> << >> ]

(* Security Definition Message No Instr Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoInstrAttribGroups ==
    { ZeroSecurityDefinitionMessageNoInstrAttribGroups }
        \cup { [ZeroSecurityDefinitionMessageNoInstrAttribGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessageNoInstrAttribGroups EXCEPT !.securityDefinitionMessageNoInstrAttribGroup = one] : one \in SampleLists(OneSecurityDefinitionMessageNoInstrAttribGroup) }

(***************************************************************************)
(* Security Definition Message No Events Group: 16 bytes                   *)
(***************************************************************************)

SecurityDefinitionMessageNoEventsGroup ==
    [ eventType : Sample(4),
      eventDate : Sample(4),
      eventTime : Sample(8) ]

EncodeSecurityDefinitionMessageNoEventsGroup(message) ==
    message.eventType
        \o message.eventDate
        \o message.eventTime

DecodeSecurityDefinitionMessageNoEventsGroup(bytes) ==
    LET eventType == ReadBytes(bytes, 4) IN IF ~eventType.ok THEN Fail ELSE
    LET eventDate == ReadBytes(eventType.rest, 4) IN IF ~eventDate.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventDate.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ eventType |-> eventType.value,
         eventDate |-> eventDate.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroSecurityDefinitionMessageNoEventsGroup ==
    [ eventType |-> [i \in 1 .. 4 |-> 0],
      eventDate |-> [i \in 1 .. 4 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Security Definition Message No Events Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoEventsGroup ==
    { ZeroSecurityDefinitionMessageNoEventsGroup }
        \cup { [ZeroSecurityDefinitionMessageNoEventsGroup EXCEPT !.eventType = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoEventsGroup EXCEPT !.eventDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessageNoEventsGroup EXCEPT !.eventTime = one] : one \in Sample(8) }

(* A run of Security Definition Message No Events Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionMessageNoEventsGroupList(_)
EncodeSecurityDefinitionMessageNoEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionMessageNoEventsGroup(Head(messages)) \o EncodeSecurityDefinitionMessageNoEventsGroupList(Tail(messages))

(* As many Security Definition Message No Events Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionMessageNoEventsGroupList(_, _)
ReadSecurityDefinitionMessageNoEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionMessageNoEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionMessageNoEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Message No Events Group of each kind, for the lists that carry them *)
OneSecurityDefinitionMessageNoEventsGroup == { ZeroSecurityDefinitionMessageNoEventsGroup }

(***************************************************************************)
(* Security Definition Message No Events Groups                            *)
(***************************************************************************)

SecurityDefinitionMessageNoEventsGroups ==
    [ blockLength                            : Sample(2),
      securityDefinitionMessageNoEventsGroup : SampleLists(OneSecurityDefinitionMessageNoEventsGroup) ]

EncodeSecurityDefinitionMessageNoEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityDefinitionMessageNoEventsGroup), 1)
        \o EncodeSecurityDefinitionMessageNoEventsGroupList(message.securityDefinitionMessageNoEventsGroup)

DecodeSecurityDefinitionMessageNoEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET securityDefinitionMessageNoEventsGroup == ReadSecurityDefinitionMessageNoEventsGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~securityDefinitionMessageNoEventsGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         securityDefinitionMessageNoEventsGroup |-> securityDefinitionMessageNoEventsGroup.value ], securityDefinitionMessageNoEventsGroup.rest)

ZeroSecurityDefinitionMessageNoEventsGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionMessageNoEventsGroup |-> << >> ]

(* Security Definition Message No Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessageNoEventsGroups ==
    { ZeroSecurityDefinitionMessageNoEventsGroups }
        \cup { [ZeroSecurityDefinitionMessageNoEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessageNoEventsGroups EXCEPT !.securityDefinitionMessageNoEventsGroup = one] : one \in SampleLists(OneSecurityDefinitionMessageNoEventsGroup) }

(***************************************************************************)
(* Security Desc                                                           *)
(***************************************************************************)

SecurityDesc ==
    [ securityDescData : SampleBytes ]

EncodeSecurityDesc(message) ==
    EncodeUIntLE(Len(message.securityDescData), 2)
        \o message.securityDescData

DecodeSecurityDesc(bytes) ==
    LET securityDescLength == ReadUIntLE(bytes, 2) IN IF ~securityDescLength.ok THEN Fail ELSE
    LET securityDescData == ReadBytes(securityDescLength.rest, securityDescLength.value) IN IF ~securityDescData.ok THEN Fail ELSE
    Ok([ securityDescData |-> securityDescData.value ], securityDescData.rest)

ZeroSecurityDesc ==
    [ securityDescData |-> << >> ]

(* Security Desc at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDesc ==
    { ZeroSecurityDesc }
        \cup { [ZeroSecurityDesc EXCEPT !.securityDescData = one] : one \in SampleBytes }

(***************************************************************************)
(* Quotation List                                                          *)
(***************************************************************************)

QuotationList ==
    [ quotationListData : SampleBytes ]

EncodeQuotationList(message) ==
    EncodeUIntLE(Len(message.quotationListData), 2)
        \o message.quotationListData

DecodeQuotationList(bytes) ==
    LET quotationListLength == ReadUIntLE(bytes, 2) IN IF ~quotationListLength.ok THEN Fail ELSE
    LET quotationListData == ReadBytes(quotationListLength.rest, quotationListLength.value) IN IF ~quotationListData.ok THEN Fail ELSE
    Ok([ quotationListData |-> quotationListData.value ], quotationListData.rest)

ZeroQuotationList ==
    [ quotationListData |-> << >> ]

(* Quotation List at zero, then each field in turn at the values it is checked at *)
CheckedQuotationList ==
    { ZeroQuotationList }
        \cup { [ZeroQuotationList EXCEPT !.quotationListData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Definition Message                                             *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ totNumReports                                : Sample(4),
      symbol                                       : Sample(25),
      securityId                                   : Sample(4),
      securityAltId                                : Sample(25),
      securityAltIdSource                          : Sample(1),
      securityType                                 : Sample(4),
      cfiCode                                      : Sample(6),
      strikePrice                                  : Sample(8),
      contractMultiplier                           : Sample(8),
      securityTradingStatus                        : Sample(1),
      currency                                     : Sample(3),
      marketSegmentId                              : Sample(1),
      tradingSessionId                             : Sample(1),
      exchangeTradingSessionIdInt32NullOptional    : Sample(4),
      volatility                                   : Sample(8),
      highLimitPx                                  : Sample(8),
      lowLimitPx                                   : Sample(8),
      minPriceIncrement                            : Sample(8),
      minPriceIncrementAmount                      : Sample(8),
      initialMarginOnBuy                           : Sample(8),
      initialMarginOnSell                          : Sample(8),
      initialMarginSyntetic                        : Sample(8),
      theorPrice                                   : Sample(8),
      theorPriceLimit                              : Sample(8),
      underlyingQty                                : Sample(8),
      underlyingCurrency                           : Sample(3),
      flags                                        : Sample(8),
      minPriceIncrementAmountCurr                  : Sample(8),
      settlPriceOpen                               : Sample(8),
      valuationMethod                              : Sample(4),
      riskFreeRate                                 : Sample(8),
      fixedSpotDiscount                            : Sample(8),
      projectedSpotDiscount                        : Sample(8),
      settlCurrency                                : Sample(3),
      negativePrices                               : Sample(1),
      derivativeContractMultiplier                 : Sample(4),
      interestRateRiskUp                           : Sample(8),
      interestRateRiskDown                         : Sample(8),
      riskFreeRate2                                : Sample(8),
      interestRate2RiskUp                          : Sample(8),
      interestRate2RiskDown                        : Sample(8),
      settlPrice                                   : Sample(8),
      tradeModeId                                  : Sample(4),
      groupMaskInt64                               : Sample(8),
      sectionIdInt32                               : Sample(4),
      baseContractIdInt32                          : Sample(4),
      tradePeriodAccess                            : Sample(8),
      highLimitPxWeekend                           : Sample(8),
      lowLimitPxWeekend                            : Sample(8),
      clearingSettlPrice                           : Sample(8),
      securityDefinitionMessageNoMDFeedTypesGroups : SecurityDefinitionMessageNoMDFeedTypesGroups,
      securityDefinitionMessageNoUnderlyingsGroups : SecurityDefinitionMessageNoUnderlyingsGroups,
      securityDefinitionMessageNoLegsGroups        : SecurityDefinitionMessageNoLegsGroups,
      securityDefinitionMessageNoInstrAttribGroups : SecurityDefinitionMessageNoInstrAttribGroups,
      securityDefinitionMessageNoEventsGroups      : SecurityDefinitionMessageNoEventsGroups,
      securityDesc                                 : SecurityDesc,
      quotationList                                : QuotationList ]

EncodeSecurityDefinitionMessage(message) ==
    message.totNumReports
        \o message.symbol
        \o message.securityId
        \o message.securityAltId
        \o message.securityAltIdSource
        \o message.securityType
        \o message.cfiCode
        \o message.strikePrice
        \o message.contractMultiplier
        \o message.securityTradingStatus
        \o message.currency
        \o message.marketSegmentId
        \o message.tradingSessionId
        \o message.exchangeTradingSessionIdInt32NullOptional
        \o message.volatility
        \o message.highLimitPx
        \o message.lowLimitPx
        \o message.minPriceIncrement
        \o message.minPriceIncrementAmount
        \o message.initialMarginOnBuy
        \o message.initialMarginOnSell
        \o message.initialMarginSyntetic
        \o message.theorPrice
        \o message.theorPriceLimit
        \o message.underlyingQty
        \o message.underlyingCurrency
        \o message.flags
        \o message.minPriceIncrementAmountCurr
        \o message.settlPriceOpen
        \o message.valuationMethod
        \o message.riskFreeRate
        \o message.fixedSpotDiscount
        \o message.projectedSpotDiscount
        \o message.settlCurrency
        \o message.negativePrices
        \o message.derivativeContractMultiplier
        \o message.interestRateRiskUp
        \o message.interestRateRiskDown
        \o message.riskFreeRate2
        \o message.interestRate2RiskUp
        \o message.interestRate2RiskDown
        \o message.settlPrice
        \o message.tradeModeId
        \o message.groupMaskInt64
        \o message.sectionIdInt32
        \o message.baseContractIdInt32
        \o message.tradePeriodAccess
        \o message.highLimitPxWeekend
        \o message.lowLimitPxWeekend
        \o message.clearingSettlPrice
        \o EncodeSecurityDefinitionMessageNoMDFeedTypesGroups(message.securityDefinitionMessageNoMDFeedTypesGroups)
        \o EncodeSecurityDefinitionMessageNoUnderlyingsGroups(message.securityDefinitionMessageNoUnderlyingsGroups)
        \o EncodeSecurityDefinitionMessageNoLegsGroups(message.securityDefinitionMessageNoLegsGroups)
        \o EncodeSecurityDefinitionMessageNoInstrAttribGroups(message.securityDefinitionMessageNoInstrAttribGroups)
        \o EncodeSecurityDefinitionMessageNoEventsGroups(message.securityDefinitionMessageNoEventsGroups)
        \o EncodeSecurityDesc(message.securityDesc)
        \o EncodeQuotationList(message.quotationList)

DecodeSecurityDefinitionMessage(bytes) ==
    LET totNumReports == ReadBytes(bytes, 4) IN IF ~totNumReports.ok THEN Fail ELSE
    LET symbol == ReadBytes(totNumReports.rest, 25) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityAltId == ReadBytes(securityId.rest, 25) IN IF ~securityAltId.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltId.rest, 1) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityAltIdSource.rest, 4) IN IF ~securityType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(cfiCode.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(strikePrice.rest, 8) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(contractMultiplier.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET currency == ReadBytes(securityTradingStatus.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(currency.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET exchangeTradingSessionIdInt32NullOptional == ReadBytes(tradingSessionId.rest, 4) IN IF ~exchangeTradingSessionIdInt32NullOptional.ok THEN Fail ELSE
    LET volatility == ReadBytes(exchangeTradingSessionIdInt32NullOptional.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET highLimitPx == ReadBytes(volatility.rest, 8) IN IF ~highLimitPx.ok THEN Fail ELSE
    LET lowLimitPx == ReadBytes(highLimitPx.rest, 8) IN IF ~lowLimitPx.ok THEN Fail ELSE
    LET minPriceIncrement == ReadBytes(lowLimitPx.rest, 8) IN IF ~minPriceIncrement.ok THEN Fail ELSE
    LET minPriceIncrementAmount == ReadBytes(minPriceIncrement.rest, 8) IN IF ~minPriceIncrementAmount.ok THEN Fail ELSE
    LET initialMarginOnBuy == ReadBytes(minPriceIncrementAmount.rest, 8) IN IF ~initialMarginOnBuy.ok THEN Fail ELSE
    LET initialMarginOnSell == ReadBytes(initialMarginOnBuy.rest, 8) IN IF ~initialMarginOnSell.ok THEN Fail ELSE
    LET initialMarginSyntetic == ReadBytes(initialMarginOnSell.rest, 8) IN IF ~initialMarginSyntetic.ok THEN Fail ELSE
    LET theorPrice == ReadBytes(initialMarginSyntetic.rest, 8) IN IF ~theorPrice.ok THEN Fail ELSE
    LET theorPriceLimit == ReadBytes(theorPrice.rest, 8) IN IF ~theorPriceLimit.ok THEN Fail ELSE
    LET underlyingQty == ReadBytes(theorPriceLimit.rest, 8) IN IF ~underlyingQty.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingQty.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET flags == ReadBytes(underlyingCurrency.rest, 8) IN IF ~flags.ok THEN Fail ELSE
    LET minPriceIncrementAmountCurr == ReadBytes(flags.rest, 8) IN IF ~minPriceIncrementAmountCurr.ok THEN Fail ELSE
    LET settlPriceOpen == ReadBytes(minPriceIncrementAmountCurr.rest, 8) IN IF ~settlPriceOpen.ok THEN Fail ELSE
    LET valuationMethod == ReadBytes(settlPriceOpen.rest, 4) IN IF ~valuationMethod.ok THEN Fail ELSE
    LET riskFreeRate == ReadBytes(valuationMethod.rest, 8) IN IF ~riskFreeRate.ok THEN Fail ELSE
    LET fixedSpotDiscount == ReadBytes(riskFreeRate.rest, 8) IN IF ~fixedSpotDiscount.ok THEN Fail ELSE
    LET projectedSpotDiscount == ReadBytes(fixedSpotDiscount.rest, 8) IN IF ~projectedSpotDiscount.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(projectedSpotDiscount.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET negativePrices == ReadBytes(settlCurrency.rest, 1) IN IF ~negativePrices.ok THEN Fail ELSE
    LET derivativeContractMultiplier == ReadBytes(negativePrices.rest, 4) IN IF ~derivativeContractMultiplier.ok THEN Fail ELSE
    LET interestRateRiskUp == ReadBytes(derivativeContractMultiplier.rest, 8) IN IF ~interestRateRiskUp.ok THEN Fail ELSE
    LET interestRateRiskDown == ReadBytes(interestRateRiskUp.rest, 8) IN IF ~interestRateRiskDown.ok THEN Fail ELSE
    LET riskFreeRate2 == ReadBytes(interestRateRiskDown.rest, 8) IN IF ~riskFreeRate2.ok THEN Fail ELSE
    LET interestRate2RiskUp == ReadBytes(riskFreeRate2.rest, 8) IN IF ~interestRate2RiskUp.ok THEN Fail ELSE
    LET interestRate2RiskDown == ReadBytes(interestRate2RiskUp.rest, 8) IN IF ~interestRate2RiskDown.ok THEN Fail ELSE
    LET settlPrice == ReadBytes(interestRate2RiskDown.rest, 8) IN IF ~settlPrice.ok THEN Fail ELSE
    LET tradeModeId == ReadBytes(settlPrice.rest, 4) IN IF ~tradeModeId.ok THEN Fail ELSE
    LET groupMaskInt64 == ReadBytes(tradeModeId.rest, 8) IN IF ~groupMaskInt64.ok THEN Fail ELSE
    LET sectionIdInt32 == ReadBytes(groupMaskInt64.rest, 4) IN IF ~sectionIdInt32.ok THEN Fail ELSE
    LET baseContractIdInt32 == ReadBytes(sectionIdInt32.rest, 4) IN IF ~baseContractIdInt32.ok THEN Fail ELSE
    LET tradePeriodAccess == ReadBytes(baseContractIdInt32.rest, 8) IN IF ~tradePeriodAccess.ok THEN Fail ELSE
    LET highLimitPxWeekend == ReadBytes(tradePeriodAccess.rest, 8) IN IF ~highLimitPxWeekend.ok THEN Fail ELSE
    LET lowLimitPxWeekend == ReadBytes(highLimitPxWeekend.rest, 8) IN IF ~lowLimitPxWeekend.ok THEN Fail ELSE
    LET clearingSettlPrice == ReadBytes(lowLimitPxWeekend.rest, 8) IN IF ~clearingSettlPrice.ok THEN Fail ELSE
    LET securityDefinitionMessageNoMDFeedTypesGroups == DecodeSecurityDefinitionMessageNoMDFeedTypesGroups(clearingSettlPrice.rest) IN IF ~securityDefinitionMessageNoMDFeedTypesGroups.ok THEN Fail ELSE
    LET securityDefinitionMessageNoUnderlyingsGroups == DecodeSecurityDefinitionMessageNoUnderlyingsGroups(securityDefinitionMessageNoMDFeedTypesGroups.rest) IN IF ~securityDefinitionMessageNoUnderlyingsGroups.ok THEN Fail ELSE
    LET securityDefinitionMessageNoLegsGroups == DecodeSecurityDefinitionMessageNoLegsGroups(securityDefinitionMessageNoUnderlyingsGroups.rest) IN IF ~securityDefinitionMessageNoLegsGroups.ok THEN Fail ELSE
    LET securityDefinitionMessageNoInstrAttribGroups == DecodeSecurityDefinitionMessageNoInstrAttribGroups(securityDefinitionMessageNoLegsGroups.rest) IN IF ~securityDefinitionMessageNoInstrAttribGroups.ok THEN Fail ELSE
    LET securityDefinitionMessageNoEventsGroups == DecodeSecurityDefinitionMessageNoEventsGroups(securityDefinitionMessageNoInstrAttribGroups.rest) IN IF ~securityDefinitionMessageNoEventsGroups.ok THEN Fail ELSE
    LET securityDesc == DecodeSecurityDesc(securityDefinitionMessageNoEventsGroups.rest) IN IF ~securityDesc.ok THEN Fail ELSE
    LET quotationList == DecodeQuotationList(securityDesc.rest) IN IF ~quotationList.ok THEN Fail ELSE
    Ok([ totNumReports                                |-> totNumReports.value,
         symbol                                       |-> symbol.value,
         securityId                                   |-> securityId.value,
         securityAltId                                |-> securityAltId.value,
         securityAltIdSource                          |-> securityAltIdSource.value,
         securityType                                 |-> securityType.value,
         cfiCode                                      |-> cfiCode.value,
         strikePrice                                  |-> strikePrice.value,
         contractMultiplier                           |-> contractMultiplier.value,
         securityTradingStatus                        |-> securityTradingStatus.value,
         currency                                     |-> currency.value,
         marketSegmentId                              |-> marketSegmentId.value,
         tradingSessionId                             |-> tradingSessionId.value,
         exchangeTradingSessionIdInt32NullOptional    |-> exchangeTradingSessionIdInt32NullOptional.value,
         volatility                                   |-> volatility.value,
         highLimitPx                                  |-> highLimitPx.value,
         lowLimitPx                                   |-> lowLimitPx.value,
         minPriceIncrement                            |-> minPriceIncrement.value,
         minPriceIncrementAmount                      |-> minPriceIncrementAmount.value,
         initialMarginOnBuy                           |-> initialMarginOnBuy.value,
         initialMarginOnSell                          |-> initialMarginOnSell.value,
         initialMarginSyntetic                        |-> initialMarginSyntetic.value,
         theorPrice                                   |-> theorPrice.value,
         theorPriceLimit                              |-> theorPriceLimit.value,
         underlyingQty                                |-> underlyingQty.value,
         underlyingCurrency                           |-> underlyingCurrency.value,
         flags                                        |-> flags.value,
         minPriceIncrementAmountCurr                  |-> minPriceIncrementAmountCurr.value,
         settlPriceOpen                               |-> settlPriceOpen.value,
         valuationMethod                              |-> valuationMethod.value,
         riskFreeRate                                 |-> riskFreeRate.value,
         fixedSpotDiscount                            |-> fixedSpotDiscount.value,
         projectedSpotDiscount                        |-> projectedSpotDiscount.value,
         settlCurrency                                |-> settlCurrency.value,
         negativePrices                               |-> negativePrices.value,
         derivativeContractMultiplier                 |-> derivativeContractMultiplier.value,
         interestRateRiskUp                           |-> interestRateRiskUp.value,
         interestRateRiskDown                         |-> interestRateRiskDown.value,
         riskFreeRate2                                |-> riskFreeRate2.value,
         interestRate2RiskUp                          |-> interestRate2RiskUp.value,
         interestRate2RiskDown                        |-> interestRate2RiskDown.value,
         settlPrice                                   |-> settlPrice.value,
         tradeModeId                                  |-> tradeModeId.value,
         groupMaskInt64                               |-> groupMaskInt64.value,
         sectionIdInt32                               |-> sectionIdInt32.value,
         baseContractIdInt32                          |-> baseContractIdInt32.value,
         tradePeriodAccess                            |-> tradePeriodAccess.value,
         highLimitPxWeekend                           |-> highLimitPxWeekend.value,
         lowLimitPxWeekend                            |-> lowLimitPxWeekend.value,
         clearingSettlPrice                           |-> clearingSettlPrice.value,
         securityDefinitionMessageNoMDFeedTypesGroups |-> securityDefinitionMessageNoMDFeedTypesGroups.value,
         securityDefinitionMessageNoUnderlyingsGroups |-> securityDefinitionMessageNoUnderlyingsGroups.value,
         securityDefinitionMessageNoLegsGroups        |-> securityDefinitionMessageNoLegsGroups.value,
         securityDefinitionMessageNoInstrAttribGroups |-> securityDefinitionMessageNoInstrAttribGroups.value,
         securityDefinitionMessageNoEventsGroups      |-> securityDefinitionMessageNoEventsGroups.value,
         securityDesc                                 |-> securityDesc.value,
         quotationList                                |-> quotationList.value ], quotationList.rest)

ZeroSecurityDefinitionMessage ==
    [ totNumReports                                |-> [i \in 1 .. 4 |-> 0],
      symbol                                       |-> [i \in 1 .. 25 |-> 0],
      securityId                                   |-> [i \in 1 .. 4 |-> 0],
      securityAltId                                |-> [i \in 1 .. 25 |-> 0],
      securityAltIdSource                          |-> [i \in 1 .. 1 |-> 0],
      securityType                                 |-> [i \in 1 .. 4 |-> 0],
      cfiCode                                      |-> [i \in 1 .. 6 |-> 0],
      strikePrice                                  |-> [i \in 1 .. 8 |-> 0],
      contractMultiplier                           |-> [i \in 1 .. 8 |-> 0],
      securityTradingStatus                        |-> [i \in 1 .. 1 |-> 0],
      currency                                     |-> [i \in 1 .. 3 |-> 0],
      marketSegmentId                              |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId                             |-> [i \in 1 .. 1 |-> 0],
      exchangeTradingSessionIdInt32NullOptional    |-> [i \in 1 .. 4 |-> 0],
      volatility                                   |-> [i \in 1 .. 8 |-> 0],
      highLimitPx                                  |-> [i \in 1 .. 8 |-> 0],
      lowLimitPx                                   |-> [i \in 1 .. 8 |-> 0],
      minPriceIncrement                            |-> [i \in 1 .. 8 |-> 0],
      minPriceIncrementAmount                      |-> [i \in 1 .. 8 |-> 0],
      initialMarginOnBuy                           |-> [i \in 1 .. 8 |-> 0],
      initialMarginOnSell                          |-> [i \in 1 .. 8 |-> 0],
      initialMarginSyntetic                        |-> [i \in 1 .. 8 |-> 0],
      theorPrice                                   |-> [i \in 1 .. 8 |-> 0],
      theorPriceLimit                              |-> [i \in 1 .. 8 |-> 0],
      underlyingQty                                |-> [i \in 1 .. 8 |-> 0],
      underlyingCurrency                           |-> [i \in 1 .. 3 |-> 0],
      flags                                        |-> [i \in 1 .. 8 |-> 0],
      minPriceIncrementAmountCurr                  |-> [i \in 1 .. 8 |-> 0],
      settlPriceOpen                               |-> [i \in 1 .. 8 |-> 0],
      valuationMethod                              |-> [i \in 1 .. 4 |-> 0],
      riskFreeRate                                 |-> [i \in 1 .. 8 |-> 0],
      fixedSpotDiscount                            |-> [i \in 1 .. 8 |-> 0],
      projectedSpotDiscount                        |-> [i \in 1 .. 8 |-> 0],
      settlCurrency                                |-> [i \in 1 .. 3 |-> 0],
      negativePrices                               |-> [i \in 1 .. 1 |-> 0],
      derivativeContractMultiplier                 |-> [i \in 1 .. 4 |-> 0],
      interestRateRiskUp                           |-> [i \in 1 .. 8 |-> 0],
      interestRateRiskDown                         |-> [i \in 1 .. 8 |-> 0],
      riskFreeRate2                                |-> [i \in 1 .. 8 |-> 0],
      interestRate2RiskUp                          |-> [i \in 1 .. 8 |-> 0],
      interestRate2RiskDown                        |-> [i \in 1 .. 8 |-> 0],
      settlPrice                                   |-> [i \in 1 .. 8 |-> 0],
      tradeModeId                                  |-> [i \in 1 .. 4 |-> 0],
      groupMaskInt64                               |-> [i \in 1 .. 8 |-> 0],
      sectionIdInt32                               |-> [i \in 1 .. 4 |-> 0],
      baseContractIdInt32                          |-> [i \in 1 .. 4 |-> 0],
      tradePeriodAccess                            |-> [i \in 1 .. 8 |-> 0],
      highLimitPxWeekend                           |-> [i \in 1 .. 8 |-> 0],
      lowLimitPxWeekend                            |-> [i \in 1 .. 8 |-> 0],
      clearingSettlPrice                           |-> [i \in 1 .. 8 |-> 0],
      securityDefinitionMessageNoMDFeedTypesGroups |-> ZeroSecurityDefinitionMessageNoMDFeedTypesGroups,
      securityDefinitionMessageNoUnderlyingsGroups |-> ZeroSecurityDefinitionMessageNoUnderlyingsGroups,
      securityDefinitionMessageNoLegsGroups        |-> ZeroSecurityDefinitionMessageNoLegsGroups,
      securityDefinitionMessageNoInstrAttribGroups |-> ZeroSecurityDefinitionMessageNoInstrAttribGroups,
      securityDefinitionMessageNoEventsGroups      |-> ZeroSecurityDefinitionMessageNoEventsGroups,
      securityDesc                                 |-> ZeroSecurityDesc,
      quotationList                                |-> ZeroQuotationList ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.totNumReports = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(25) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityAltId = one] : one \in Sample(25) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityAltIdSource = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityType = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.exchangeTradingSessionIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.highLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lowLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minPriceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minPriceIncrementAmount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.initialMarginOnBuy = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.initialMarginOnSell = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.initialMarginSyntetic = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.theorPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.theorPriceLimit = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.underlyingQty = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.flags = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minPriceIncrementAmountCurr = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.settlPriceOpen = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.valuationMethod = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.riskFreeRate = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.fixedSpotDiscount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.projectedSpotDiscount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.negativePrices = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.derivativeContractMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.interestRateRiskUp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.interestRateRiskDown = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.riskFreeRate2 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.interestRate2RiskUp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.interestRate2RiskDown = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.settlPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tradeModeId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.groupMaskInt64 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.sectionIdInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.baseContractIdInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tradePeriodAccess = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.highLimitPxWeekend = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lowLimitPxWeekend = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.clearingSettlPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionMessageNoMDFeedTypesGroups = one] : one \in CheckedSecurityDefinitionMessageNoMDFeedTypesGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionMessageNoUnderlyingsGroups = one] : one \in CheckedSecurityDefinitionMessageNoUnderlyingsGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionMessageNoLegsGroups = one] : one \in CheckedSecurityDefinitionMessageNoLegsGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionMessageNoInstrAttribGroups = one] : one \in CheckedSecurityDefinitionMessageNoInstrAttribGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionMessageNoEventsGroups = one] : one \in CheckedSecurityDefinitionMessageNoEventsGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDesc = one] : one \in CheckedSecurityDesc }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.quotationList = one] : one \in CheckedQuotationList }

(***************************************************************************)
(* Trading Session Status Message: 48 bytes                                *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ tradSesOpenTime                           : Sample(8),
      tradSesCloseTime                          : Sample(8),
      tradingSessionId                          : Sample(1),
      exchangeTradingSessionIdInt32NullOptional : Sample(4),
      tradSesStatus                             : Sample(1),
      marketSegmentId                           : Sample(1),
      tradSesEvent                              : Sample(1),
      tradePeriodId                             : Sample(8),
      settlSessBegin                            : Sample(8),
      clrSessBegin                              : Sample(8) ]

EncodeTradingSessionStatusMessage(message) ==
    message.tradSesOpenTime
        \o message.tradSesCloseTime
        \o message.tradingSessionId
        \o message.exchangeTradingSessionIdInt32NullOptional
        \o message.tradSesStatus
        \o message.marketSegmentId
        \o message.tradSesEvent
        \o message.tradePeriodId
        \o message.settlSessBegin
        \o message.clrSessBegin

DecodeTradingSessionStatusMessage(bytes) ==
    LET tradSesOpenTime == ReadBytes(bytes, 8) IN IF ~tradSesOpenTime.ok THEN Fail ELSE
    LET tradSesCloseTime == ReadBytes(tradSesOpenTime.rest, 8) IN IF ~tradSesCloseTime.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(tradSesCloseTime.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET exchangeTradingSessionIdInt32NullOptional == ReadBytes(tradingSessionId.rest, 4) IN IF ~exchangeTradingSessionIdInt32NullOptional.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(exchangeTradingSessionIdInt32NullOptional.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tradSesStatus.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET tradePeriodId == ReadBytes(tradSesEvent.rest, 8) IN IF ~tradePeriodId.ok THEN Fail ELSE
    LET settlSessBegin == ReadBytes(tradePeriodId.rest, 8) IN IF ~settlSessBegin.ok THEN Fail ELSE
    LET clrSessBegin == ReadBytes(settlSessBegin.rest, 8) IN IF ~clrSessBegin.ok THEN Fail ELSE
    Ok([ tradSesOpenTime                           |-> tradSesOpenTime.value,
         tradSesCloseTime                          |-> tradSesCloseTime.value,
         tradingSessionId                          |-> tradingSessionId.value,
         exchangeTradingSessionIdInt32NullOptional |-> exchangeTradingSessionIdInt32NullOptional.value,
         tradSesStatus                             |-> tradSesStatus.value,
         marketSegmentId                           |-> marketSegmentId.value,
         tradSesEvent                              |-> tradSesEvent.value,
         tradePeriodId                             |-> tradePeriodId.value,
         settlSessBegin                            |-> settlSessBegin.value,
         clrSessBegin                              |-> clrSessBegin.value ], clrSessBegin.rest)

ZeroTradingSessionStatusMessage ==
    [ tradSesOpenTime                           |-> [i \in 1 .. 8 |-> 0],
      tradSesCloseTime                          |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId                          |-> [i \in 1 .. 1 |-> 0],
      exchangeTradingSessionIdInt32NullOptional |-> [i \in 1 .. 4 |-> 0],
      tradSesStatus                             |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId                           |-> [i \in 1 .. 1 |-> 0],
      tradSesEvent                              |-> [i \in 1 .. 1 |-> 0],
      tradePeriodId                             |-> [i \in 1 .. 8 |-> 0],
      settlSessBegin                            |-> [i \in 1 .. 8 |-> 0],
      clrSessBegin                              |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesOpenTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesCloseTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.exchangeTradingSessionIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradePeriodId = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.settlSessBegin = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.clrSessBegin = one] : one \in Sample(8) }

(***************************************************************************)
(* Underlying Symbol Text                                                  *)
(***************************************************************************)

UnderlyingSymbolText ==
    [ underlyingSymbolTextData : SampleBytes ]

EncodeUnderlyingSymbolText(message) ==
    EncodeUIntLE(Len(message.underlyingSymbolTextData), 2)
        \o message.underlyingSymbolTextData

DecodeUnderlyingSymbolText(bytes) ==
    LET underlyingSymbolTextLength == ReadUIntLE(bytes, 2) IN IF ~underlyingSymbolTextLength.ok THEN Fail ELSE
    LET underlyingSymbolTextData == ReadBytes(underlyingSymbolTextLength.rest, underlyingSymbolTextLength.value) IN IF ~underlyingSymbolTextData.ok THEN Fail ELSE
    Ok([ underlyingSymbolTextData |-> underlyingSymbolTextData.value ], underlyingSymbolTextData.rest)

ZeroUnderlyingSymbolText ==
    [ underlyingSymbolTextData |-> << >> ]

(* Underlying Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingSymbolText ==
    { ZeroUnderlyingSymbolText }
        \cup { [ZeroUnderlyingSymbolText EXCEPT !.underlyingSymbolTextData = one] : one \in SampleBytes }

(***************************************************************************)
(* Discrete Auction Message No Underlyings Group                           *)
(***************************************************************************)

DiscreteAuctionMessageNoUnderlyingsGroup ==
    [ underlyingSymbolText : UnderlyingSymbolText ]

EncodeDiscreteAuctionMessageNoUnderlyingsGroup(message) ==
    EncodeUnderlyingSymbolText(message.underlyingSymbolText)

DecodeDiscreteAuctionMessageNoUnderlyingsGroup(bytes) ==
    LET underlyingSymbolText == DecodeUnderlyingSymbolText(bytes) IN IF ~underlyingSymbolText.ok THEN Fail ELSE
    Ok([ underlyingSymbolText |-> underlyingSymbolText.value ], underlyingSymbolText.rest)

ZeroDiscreteAuctionMessageNoUnderlyingsGroup ==
    [ underlyingSymbolText |-> ZeroUnderlyingSymbolText ]

(* Discrete Auction Message No Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedDiscreteAuctionMessageNoUnderlyingsGroup ==
    { ZeroDiscreteAuctionMessageNoUnderlyingsGroup }
        \cup { [ZeroDiscreteAuctionMessageNoUnderlyingsGroup EXCEPT !.underlyingSymbolText = one] : one \in CheckedUnderlyingSymbolText }

(* A run of Discrete Auction Message No Underlyings Group, written one after another *)
RECURSIVE EncodeDiscreteAuctionMessageNoUnderlyingsGroupList(_)
EncodeDiscreteAuctionMessageNoUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDiscreteAuctionMessageNoUnderlyingsGroup(Head(messages)) \o EncodeDiscreteAuctionMessageNoUnderlyingsGroupList(Tail(messages))

(* As many Discrete Auction Message No Underlyings Group as the field that counts them says *)
RECURSIVE ReadDiscreteAuctionMessageNoUnderlyingsGroupList(_, _)
ReadDiscreteAuctionMessageNoUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDiscreteAuctionMessageNoUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDiscreteAuctionMessageNoUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Discrete Auction Message No Underlyings Group of each kind, for the lists that carry them *)
OneDiscreteAuctionMessageNoUnderlyingsGroup == { ZeroDiscreteAuctionMessageNoUnderlyingsGroup }

(***************************************************************************)
(* Discrete Auction Message No Underlyings Groups                          *)
(***************************************************************************)

DiscreteAuctionMessageNoUnderlyingsGroups ==
    [ blockLength                              : Sample(2),
      discreteAuctionMessageNoUnderlyingsGroup : SampleLists(OneDiscreteAuctionMessageNoUnderlyingsGroup) ]

EncodeDiscreteAuctionMessageNoUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.discreteAuctionMessageNoUnderlyingsGroup), 1)
        \o EncodeDiscreteAuctionMessageNoUnderlyingsGroupList(message.discreteAuctionMessageNoUnderlyingsGroup)

DecodeDiscreteAuctionMessageNoUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET discreteAuctionMessageNoUnderlyingsGroup == ReadDiscreteAuctionMessageNoUnderlyingsGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~discreteAuctionMessageNoUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength                              |-> blockLength.value,
         discreteAuctionMessageNoUnderlyingsGroup |-> discreteAuctionMessageNoUnderlyingsGroup.value ], discreteAuctionMessageNoUnderlyingsGroup.rest)

ZeroDiscreteAuctionMessageNoUnderlyingsGroups ==
    [ blockLength                              |-> [i \in 1 .. 2 |-> 0],
      discreteAuctionMessageNoUnderlyingsGroup |-> << >> ]

(* Discrete Auction Message No Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedDiscreteAuctionMessageNoUnderlyingsGroups ==
    { ZeroDiscreteAuctionMessageNoUnderlyingsGroups }
        \cup { [ZeroDiscreteAuctionMessageNoUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDiscreteAuctionMessageNoUnderlyingsGroups EXCEPT !.discreteAuctionMessageNoUnderlyingsGroup = one] : one \in SampleLists(OneDiscreteAuctionMessageNoUnderlyingsGroup) }

(***************************************************************************)
(* Discrete Auction Message                                                *)
(***************************************************************************)

DiscreteAuctionMessage ==
    [ tradSesOpenTime                           : Sample(8),
      tradSesCloseTimeFrom                      : Sample(8),
      tradSesCloseTimeTill                      : Sample(8),
      auctionId                                 : Sample(8),
      exchangeTradingSessionIdInt32             : Sample(4),
      eventIdOpen                               : Sample(4),
      eventIdClose                              : Sample(4),
      tradePeriodId                             : Sample(8),
      discreteAuctionMessageNoUnderlyingsGroups : DiscreteAuctionMessageNoUnderlyingsGroups ]

EncodeDiscreteAuctionMessage(message) ==
    message.tradSesOpenTime
        \o message.tradSesCloseTimeFrom
        \o message.tradSesCloseTimeTill
        \o message.auctionId
        \o message.exchangeTradingSessionIdInt32
        \o message.eventIdOpen
        \o message.eventIdClose
        \o message.tradePeriodId
        \o EncodeDiscreteAuctionMessageNoUnderlyingsGroups(message.discreteAuctionMessageNoUnderlyingsGroups)

DecodeDiscreteAuctionMessage(bytes) ==
    LET tradSesOpenTime == ReadBytes(bytes, 8) IN IF ~tradSesOpenTime.ok THEN Fail ELSE
    LET tradSesCloseTimeFrom == ReadBytes(tradSesOpenTime.rest, 8) IN IF ~tradSesCloseTimeFrom.ok THEN Fail ELSE
    LET tradSesCloseTimeTill == ReadBytes(tradSesCloseTimeFrom.rest, 8) IN IF ~tradSesCloseTimeTill.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradSesCloseTimeTill.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET exchangeTradingSessionIdInt32 == ReadBytes(auctionId.rest, 4) IN IF ~exchangeTradingSessionIdInt32.ok THEN Fail ELSE
    LET eventIdOpen == ReadBytes(exchangeTradingSessionIdInt32.rest, 4) IN IF ~eventIdOpen.ok THEN Fail ELSE
    LET eventIdClose == ReadBytes(eventIdOpen.rest, 4) IN IF ~eventIdClose.ok THEN Fail ELSE
    LET tradePeriodId == ReadBytes(eventIdClose.rest, 8) IN IF ~tradePeriodId.ok THEN Fail ELSE
    LET discreteAuctionMessageNoUnderlyingsGroups == DecodeDiscreteAuctionMessageNoUnderlyingsGroups(tradePeriodId.rest) IN IF ~discreteAuctionMessageNoUnderlyingsGroups.ok THEN Fail ELSE
    Ok([ tradSesOpenTime                           |-> tradSesOpenTime.value,
         tradSesCloseTimeFrom                      |-> tradSesCloseTimeFrom.value,
         tradSesCloseTimeTill                      |-> tradSesCloseTimeTill.value,
         auctionId                                 |-> auctionId.value,
         exchangeTradingSessionIdInt32             |-> exchangeTradingSessionIdInt32.value,
         eventIdOpen                               |-> eventIdOpen.value,
         eventIdClose                              |-> eventIdClose.value,
         tradePeriodId                             |-> tradePeriodId.value,
         discreteAuctionMessageNoUnderlyingsGroups |-> discreteAuctionMessageNoUnderlyingsGroups.value ], discreteAuctionMessageNoUnderlyingsGroups.rest)

ZeroDiscreteAuctionMessage ==
    [ tradSesOpenTime                           |-> [i \in 1 .. 8 |-> 0],
      tradSesCloseTimeFrom                      |-> [i \in 1 .. 8 |-> 0],
      tradSesCloseTimeTill                      |-> [i \in 1 .. 8 |-> 0],
      auctionId                                 |-> [i \in 1 .. 8 |-> 0],
      exchangeTradingSessionIdInt32             |-> [i \in 1 .. 4 |-> 0],
      eventIdOpen                               |-> [i \in 1 .. 4 |-> 0],
      eventIdClose                              |-> [i \in 1 .. 4 |-> 0],
      tradePeriodId                             |-> [i \in 1 .. 8 |-> 0],
      discreteAuctionMessageNoUnderlyingsGroups |-> ZeroDiscreteAuctionMessageNoUnderlyingsGroups ]

(* Discrete Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedDiscreteAuctionMessage ==
    { ZeroDiscreteAuctionMessage }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.tradSesOpenTime = one] : one \in Sample(8) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.tradSesCloseTimeFrom = one] : one \in Sample(8) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.tradSesCloseTimeTill = one] : one \in Sample(8) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.exchangeTradingSessionIdInt32 = one] : one \in Sample(4) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.eventIdOpen = one] : one \in Sample(4) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.eventIdClose = one] : one \in Sample(4) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.tradePeriodId = one] : one \in Sample(8) }
        \cup { [ZeroDiscreteAuctionMessage EXCEPT !.discreteAuctionMessageNoUnderlyingsGroups = one] : one \in CheckedDiscreteAuctionMessageNoUnderlyingsGroups }

(***************************************************************************)
(* Security Group Status Message: 38 bytes                                 *)
(***************************************************************************)

SecurityGroupStatusMessage ==
    [ securityGroupId                 : Sample(8),
      haltType                        : Sample(1),
      tradeModeMask                   : Sample(4),
      groupMaskInt64NullOptional      : Sample(8),
      sectionIdInt32NullOptional      : Sample(4),
      baseContractIdInt32NullOptional : Sample(4),
      securityTradingStatus           : Sample(1),
      statusChangeTime                : Sample(8) ]

EncodeSecurityGroupStatusMessage(message) ==
    message.securityGroupId
        \o message.haltType
        \o message.tradeModeMask
        \o message.groupMaskInt64NullOptional
        \o message.sectionIdInt32NullOptional
        \o message.baseContractIdInt32NullOptional
        \o message.securityTradingStatus
        \o message.statusChangeTime

DecodeSecurityGroupStatusMessage(bytes) ==
    LET securityGroupId == ReadBytes(bytes, 8) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET haltType == ReadBytes(securityGroupId.rest, 1) IN IF ~haltType.ok THEN Fail ELSE
    LET tradeModeMask == ReadBytes(haltType.rest, 4) IN IF ~tradeModeMask.ok THEN Fail ELSE
    LET groupMaskInt64NullOptional == ReadBytes(tradeModeMask.rest, 8) IN IF ~groupMaskInt64NullOptional.ok THEN Fail ELSE
    LET sectionIdInt32NullOptional == ReadBytes(groupMaskInt64NullOptional.rest, 4) IN IF ~sectionIdInt32NullOptional.ok THEN Fail ELSE
    LET baseContractIdInt32NullOptional == ReadBytes(sectionIdInt32NullOptional.rest, 4) IN IF ~baseContractIdInt32NullOptional.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(baseContractIdInt32NullOptional.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET statusChangeTime == ReadBytes(securityTradingStatus.rest, 8) IN IF ~statusChangeTime.ok THEN Fail ELSE
    Ok([ securityGroupId                 |-> securityGroupId.value,
         haltType                        |-> haltType.value,
         tradeModeMask                   |-> tradeModeMask.value,
         groupMaskInt64NullOptional      |-> groupMaskInt64NullOptional.value,
         sectionIdInt32NullOptional      |-> sectionIdInt32NullOptional.value,
         baseContractIdInt32NullOptional |-> baseContractIdInt32NullOptional.value,
         securityTradingStatus           |-> securityTradingStatus.value,
         statusChangeTime                |-> statusChangeTime.value ], statusChangeTime.rest)

ZeroSecurityGroupStatusMessage ==
    [ securityGroupId                 |-> [i \in 1 .. 8 |-> 0],
      haltType                        |-> [i \in 1 .. 1 |-> 0],
      tradeModeMask                   |-> [i \in 1 .. 4 |-> 0],
      groupMaskInt64NullOptional      |-> [i \in 1 .. 8 |-> 0],
      sectionIdInt32NullOptional      |-> [i \in 1 .. 4 |-> 0],
      baseContractIdInt32NullOptional |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus           |-> [i \in 1 .. 1 |-> 0],
      statusChangeTime                |-> [i \in 1 .. 8 |-> 0] ]

(* Security Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityGroupStatusMessage ==
    { ZeroSecurityGroupStatusMessage }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.securityGroupId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.haltType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.tradeModeMask = one] : one \in Sample(4) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.groupMaskInt64NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.sectionIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.baseContractIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.statusChangeTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
SequenceResetMessageCode == 2  \* 0x02
SecurityDefinitionMessageCode == 29  \* 0x1d
TradingSessionStatusMessageCode == 26  \* 0x1a
DiscreteAuctionMessageCode == 24  \* 0x18
SecurityGroupStatusMessageCode == 22  \* 0x16

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {DiscreteAuctionMessageCode}, body : DiscreteAuctionMessage ]
        \cup [ tag : {SecurityGroupStatusMessageCode}, body : SecurityGroupStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = DiscreteAuctionMessageCode -> EncodeDiscreteAuctionMessage(message.body)
      [] message.tag = SecurityGroupStatusMessageCode -> EncodeSecurityGroupStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = DiscreteAuctionMessageCode -> DecodeDiscreteAuctionMessage(bytes)
              [] tag = SecurityGroupStatusMessageCode -> DecodeSecurityGroupStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> DiscreteAuctionMessageCode, body |-> one] : one \in CheckedDiscreteAuctionMessage }
        \cup { [tag |-> SecurityGroupStatusMessageCode, body |-> one] : one \in CheckedSecurityGroupStatusMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DiscreteAuctionMessageCode, body |-> ZeroDiscreteAuctionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityGroupStatusMessageCode, body |-> ZeroSecurityGroupStatusMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ marketDataPacketHeader : MarketDataPacketHeader,
      message                : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    EncodeMarketDataPacketHeader(message.marketDataPacketHeader)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET marketDataPacketHeader == DecodeMarketDataPacketHeader(bytes) IN IF ~marketDataPacketHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(marketDataPacketHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDataPacketHeader |-> marketDataPacketHeader.value,
         message                |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ marketDataPacketHeader |-> ZeroMarketDataPacketHeader,
      message                |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.marketDataPacketHeader = one] : one \in CheckedMarketDataPacketHeader }
        \cup { [ZeroUdpPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Market Data Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataPacketHeader ==
    \A message \in CheckedMarketDataPacketHeader :
        LET read == DecodeMarketDataPacketHeader(EncodeMarketDataPacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No M D Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoMDFeedTypesGroup ==
    \A message \in CheckedSecurityDefinitionMessageNoMDFeedTypesGroup :
        LET read == DecodeSecurityDefinitionMessageNoMDFeedTypesGroup(EncodeSecurityDefinitionMessageNoMDFeedTypesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No M D Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoMDFeedTypesGroups ==
    \A message \in CheckedSecurityDefinitionMessageNoMDFeedTypesGroups :
        LET read == DecodeSecurityDefinitionMessageNoMDFeedTypesGroups(EncodeSecurityDefinitionMessageNoMDFeedTypesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoUnderlyingsGroup ==
    \A message \in CheckedSecurityDefinitionMessageNoUnderlyingsGroup :
        LET read == DecodeSecurityDefinitionMessageNoUnderlyingsGroup(EncodeSecurityDefinitionMessageNoUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoUnderlyingsGroups ==
    \A message \in CheckedSecurityDefinitionMessageNoUnderlyingsGroups :
        LET read == DecodeSecurityDefinitionMessageNoUnderlyingsGroups(EncodeSecurityDefinitionMessageNoUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoLegsGroup ==
    \A message \in CheckedSecurityDefinitionMessageNoLegsGroup :
        LET read == DecodeSecurityDefinitionMessageNoLegsGroup(EncodeSecurityDefinitionMessageNoLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoLegsGroups ==
    \A message \in CheckedSecurityDefinitionMessageNoLegsGroups :
        LET read == DecodeSecurityDefinitionMessageNoLegsGroups(EncodeSecurityDefinitionMessageNoLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Instr Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoInstrAttribGroup ==
    \A message \in CheckedSecurityDefinitionMessageNoInstrAttribGroup :
        LET read == DecodeSecurityDefinitionMessageNoInstrAttribGroup(EncodeSecurityDefinitionMessageNoInstrAttribGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Instr Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoInstrAttribGroups ==
    \A message \in CheckedSecurityDefinitionMessageNoInstrAttribGroups :
        LET read == DecodeSecurityDefinitionMessageNoInstrAttribGroups(EncodeSecurityDefinitionMessageNoInstrAttribGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoEventsGroup ==
    \A message \in CheckedSecurityDefinitionMessageNoEventsGroup :
        LET read == DecodeSecurityDefinitionMessageNoEventsGroup(EncodeSecurityDefinitionMessageNoEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message No Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessageNoEventsGroups ==
    \A message \in CheckedSecurityDefinitionMessageNoEventsGroups :
        LET read == DecodeSecurityDefinitionMessageNoEventsGroups(EncodeSecurityDefinitionMessageNoEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDesc ==
    \A message \in CheckedSecurityDesc :
        LET read == DecodeSecurityDesc(EncodeSecurityDesc(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotation List decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotationList ==
    \A message \in CheckedQuotationList :
        LET read == DecodeQuotationList(EncodeQuotationList(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingSymbolText ==
    \A message \in CheckedUnderlyingSymbolText :
        LET read == DecodeUnderlyingSymbolText(EncodeUnderlyingSymbolText(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Discrete Auction Message No Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscreteAuctionMessageNoUnderlyingsGroup ==
    \A message \in CheckedDiscreteAuctionMessageNoUnderlyingsGroup :
        LET read == DecodeDiscreteAuctionMessageNoUnderlyingsGroup(EncodeDiscreteAuctionMessageNoUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Discrete Auction Message No Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscreteAuctionMessageNoUnderlyingsGroups ==
    \A message \in CheckedDiscreteAuctionMessageNoUnderlyingsGroups :
        LET read == DecodeDiscreteAuctionMessageNoUnderlyingsGroups(EncodeDiscreteAuctionMessageNoUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Discrete Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscreteAuctionMessage ==
    \A message \in CheckedDiscreteAuctionMessage :
        LET read == DecodeDiscreteAuctionMessage(EncodeDiscreteAuctionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Group Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityGroupStatusMessage ==
    \A message \in CheckedSecurityGroupStatusMessage :
        LET read == DecodeSecurityGroupStatusMessage(EncodeSecurityGroupStatusMessage(message))
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

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
