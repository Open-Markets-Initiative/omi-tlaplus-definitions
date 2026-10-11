------------- MODULE Cboe_TitaniumConsolidated_Indices_v1_4_13 -------------
(***************************************************************************)
(* Chicago Board Options Exchange Global Indices Feed v1.4.13              *)
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
(* Symbol                                                                  *)
(***************************************************************************)

Symbol ==
    [ symbolChars : SampleBytes ]

EncodeSymbol(message) ==
    EncodeUIntBE(Len(message.symbolChars), 1)
        \o message.symbolChars

DecodeSymbol(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolChars == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolChars.ok THEN Fail ELSE
    Ok([ symbolChars |-> symbolChars.value ], symbolChars.rest)

ZeroSymbol ==
    [ symbolChars |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol ==
    { ZeroSymbol }
        \cup { [ZeroSymbol EXCEPT !.symbolChars = one] : one \in SampleBytes }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx ==
    [ exponent : Sample(1),
      mantissa : Sample(4) ]

EncodeMdEntryPx(message) ==
    message.exponent
        \o message.mantissa

DecodeMdEntryPx(bytes) ==
    LET exponent == ReadBytes(bytes, 1) IN IF ~exponent.ok THEN Fail ELSE
    LET mantissa == ReadBytes(exponent.rest, 4) IN IF ~mantissa.ok THEN Fail ELSE
    Ok([ exponent |-> exponent.value,
         mantissa |-> mantissa.value ], mantissa.rest)

ZeroMdEntryPx ==
    [ exponent |-> [i \in 1 .. 1 |-> 0],
      mantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx ==
    { ZeroMdEntryPx }
        \cup { [ZeroMdEntryPx EXCEPT !.exponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx EXCEPT !.mantissa = one] : one \in Sample(4) }

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
(* Symbol                                                                  *)
(***************************************************************************)

Symbol2 ==
    [ symbolChars : SampleBytes ]

EncodeSymbol2(message) ==
    EncodeUIntBE(Len(message.symbolChars), 1)
        \o message.symbolChars

DecodeSymbol2(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolChars == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolChars.ok THEN Fail ELSE
    Ok([ symbolChars |-> symbolChars.value ], symbolChars.rest)

ZeroSymbol2 ==
    [ symbolChars |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol2 ==
    { ZeroSymbol2 }
        \cup { [ZeroSymbol2 EXCEPT !.symbolChars = one] : one \in SampleBytes }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx2 ==
    [ exponent : Sample(1),
      mantissa : Sample(4) ]

EncodeMdEntryPx2(message) ==
    message.exponent
        \o message.mantissa

DecodeMdEntryPx2(bytes) ==
    LET exponent == ReadBytes(bytes, 1) IN IF ~exponent.ok THEN Fail ELSE
    LET mantissa == ReadBytes(exponent.rest, 4) IN IF ~mantissa.ok THEN Fail ELSE
    Ok([ exponent |-> exponent.value,
         mantissa |-> mantissa.value ], mantissa.rest)

ZeroMdEntryPx2 ==
    [ exponent |-> [i \in 1 .. 1 |-> 0],
      mantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx2 ==
    { ZeroMdEntryPx2 }
        \cup { [ZeroMdEntryPx2 EXCEPT !.exponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx2 EXCEPT !.mantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entries: 6 bytes                                                     *)
(***************************************************************************)

MdEntries2 ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx2 ]

EncodeMdEntries2(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx2(message.mdEntryPx)

DecodeMdEntries2(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx2(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroMdEntries2 ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx2 ]

(* Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedMdEntries2 ==
    { ZeroMdEntries2 }
        \cup { [ZeroMdEntries2 EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntries2 EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx2 }

(* A run of Md Entries, written one after another *)
RECURSIVE EncodeMdEntries2List(_)
EncodeMdEntries2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntries2(Head(messages)) \o EncodeMdEntries2List(Tail(messages))

(* As many Md Entries as the field that counts them says *)
RECURSIVE ReadMdEntries2List(_, _)
ReadMdEntries2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntries2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntries2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entries of each kind, for the lists that carry them *)
OneMdEntries2 == { ZeroMdEntries2 }

(***************************************************************************)
(* Contributor Value Message                                               *)
(***************************************************************************)

ContributorValueMessage ==
    [ transactTime : Sample(8),
      symbol       : Symbol2,
      mdEntries    : SampleLists(OneMdEntries2) ]

EncodeContributorValueMessage(message) ==
    message.transactTime
        \o EncodeSymbol2(message.symbol)
        \o EncodeUIntBE(Len(message.mdEntries), 1)
        \o EncodeMdEntries2List(message.mdEntries)

DecodeContributorValueMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbol == DecodeSymbol2(transactTime.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(symbol.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntries2List(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbol       |-> symbol.value,
         mdEntries    |-> mdEntries.value ], mdEntries.rest)

ZeroContributorValueMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> ZeroSymbol2,
      mdEntries    |-> << >> ]

(* Contributor Value Message at zero, then each field in turn at the values it is checked at *)
CheckedContributorValueMessage ==
    { ZeroContributorValueMessage }
        \cup { [ZeroContributorValueMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroContributorValueMessage EXCEPT !.symbol = one] : one \in CheckedSymbol2 }
        \cup { [ZeroContributorValueMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries2) }

(***************************************************************************)
(* Effective Business Date: 9 bytes                                        *)
(***************************************************************************)

EffectiveBusinessDate ==
    [ byteLength                 : Sample(1),
      effectiveBusinessDateChars : Sample(8) ]

EncodeEffectiveBusinessDate(message) ==
    message.byteLength
        \o message.effectiveBusinessDateChars

DecodeEffectiveBusinessDate(bytes) ==
    LET byteLength == ReadBytes(bytes, 1) IN IF ~byteLength.ok THEN Fail ELSE
    LET effectiveBusinessDateChars == ReadBytes(byteLength.rest, 8) IN IF ~effectiveBusinessDateChars.ok THEN Fail ELSE
    Ok([ byteLength                 |-> byteLength.value,
         effectiveBusinessDateChars |-> effectiveBusinessDateChars.value ], effectiveBusinessDateChars.rest)

ZeroEffectiveBusinessDate ==
    [ byteLength                 |-> [i \in 1 .. 1 |-> 0],
      effectiveBusinessDateChars |-> [i \in 1 .. 8 |-> 0] ]

(* Effective Business Date at zero, then each field in turn at the values it is checked at *)
CheckedEffectiveBusinessDate ==
    { ZeroEffectiveBusinessDate }
        \cup { [ZeroEffectiveBusinessDate EXCEPT !.byteLength = one] : one \in Sample(1) }
        \cup { [ZeroEffectiveBusinessDate EXCEPT !.effectiveBusinessDateChars = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol3 ==
    [ symbolChars : SampleBytes ]

EncodeSymbol3(message) ==
    EncodeUIntBE(Len(message.symbolChars), 1)
        \o message.symbolChars

DecodeSymbol3(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolChars == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolChars.ok THEN Fail ELSE
    Ok([ symbolChars |-> symbolChars.value ], symbolChars.rest)

ZeroSymbol3 ==
    [ symbolChars |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol3 ==
    { ZeroSymbol3 }
        \cup { [ZeroSymbol3 EXCEPT !.symbolChars = one] : one \in SampleBytes }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx3 ==
    [ exponent : Sample(1),
      mantissa : Sample(4) ]

EncodeMdEntryPx3(message) ==
    message.exponent
        \o message.mantissa

DecodeMdEntryPx3(bytes) ==
    LET exponent == ReadBytes(bytes, 1) IN IF ~exponent.ok THEN Fail ELSE
    LET mantissa == ReadBytes(exponent.rest, 4) IN IF ~mantissa.ok THEN Fail ELSE
    Ok([ exponent |-> exponent.value,
         mantissa |-> mantissa.value ], mantissa.rest)

ZeroMdEntryPx3 ==
    [ exponent |-> [i \in 1 .. 1 |-> 0],
      mantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx3 ==
    { ZeroMdEntryPx3 }
        \cup { [ZeroMdEntryPx3 EXCEPT !.exponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx3 EXCEPT !.mantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entries: 6 bytes                                                     *)
(***************************************************************************)

MdEntries3 ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx3 ]

EncodeMdEntries3(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx3(message.mdEntryPx)

DecodeMdEntries3(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx3(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroMdEntries3 ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx3 ]

(* Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedMdEntries3 ==
    { ZeroMdEntries3 }
        \cup { [ZeroMdEntries3 EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntries3 EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx3 }

(* A run of Md Entries, written one after another *)
RECURSIVE EncodeMdEntries3List(_)
EncodeMdEntries3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntries3(Head(messages)) \o EncodeMdEntries3List(Tail(messages))

(* As many Md Entries as the field that counts them says *)
RECURSIVE ReadMdEntries3List(_, _)
ReadMdEntries3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntries3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntries3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entries of each kind, for the lists that carry them *)
OneMdEntries3 == { ZeroMdEntries3 }

(***************************************************************************)
(* Index Summary Message                                                   *)
(***************************************************************************)

IndexSummaryMessage ==
    [ transactTime          : Sample(8),
      effectiveBusinessDate : EffectiveBusinessDate,
      summaryType           : Sample(1),
      symbol                : Symbol3,
      mdEntries             : SampleLists(OneMdEntries3) ]

EncodeIndexSummaryMessage(message) ==
    message.transactTime
        \o EncodeEffectiveBusinessDate(message.effectiveBusinessDate)
        \o message.summaryType
        \o EncodeSymbol3(message.symbol)
        \o EncodeUIntBE(Len(message.mdEntries), 1)
        \o EncodeMdEntries3List(message.mdEntries)

DecodeIndexSummaryMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET effectiveBusinessDate == DecodeEffectiveBusinessDate(transactTime.rest) IN IF ~effectiveBusinessDate.ok THEN Fail ELSE
    LET summaryType == ReadBytes(effectiveBusinessDate.rest, 1) IN IF ~summaryType.ok THEN Fail ELSE
    LET symbol == DecodeSymbol3(summaryType.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(symbol.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntries3List(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    Ok([ transactTime          |-> transactTime.value,
         effectiveBusinessDate |-> effectiveBusinessDate.value,
         summaryType           |-> summaryType.value,
         symbol                |-> symbol.value,
         mdEntries             |-> mdEntries.value ], mdEntries.rest)

ZeroIndexSummaryMessage ==
    [ transactTime          |-> [i \in 1 .. 8 |-> 0],
      effectiveBusinessDate |-> ZeroEffectiveBusinessDate,
      summaryType           |-> [i \in 1 .. 1 |-> 0],
      symbol                |-> ZeroSymbol3,
      mdEntries             |-> << >> ]

(* Index Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexSummaryMessage ==
    { ZeroIndexSummaryMessage }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.effectiveBusinessDate = one] : one \in CheckedEffectiveBusinessDate }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.summaryType = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.symbol = one] : one \in CheckedSymbol3 }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries3) }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol4 ==
    [ symbolChars : SampleBytes ]

EncodeSymbol4(message) ==
    EncodeUIntBE(Len(message.symbolChars), 1)
        \o message.symbolChars

DecodeSymbol4(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolChars == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolChars.ok THEN Fail ELSE
    Ok([ symbolChars |-> symbolChars.value ], symbolChars.rest)

ZeroSymbol4 ==
    [ symbolChars |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol4 ==
    { ZeroSymbol4 }
        \cup { [ZeroSymbol4 EXCEPT !.symbolChars = one] : one \in SampleBytes }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx4 ==
    [ exponent : Sample(1),
      mantissa : Sample(4) ]

EncodeMdEntryPx4(message) ==
    message.exponent
        \o message.mantissa

DecodeMdEntryPx4(bytes) ==
    LET exponent == ReadBytes(bytes, 1) IN IF ~exponent.ok THEN Fail ELSE
    LET mantissa == ReadBytes(exponent.rest, 4) IN IF ~mantissa.ok THEN Fail ELSE
    Ok([ exponent |-> exponent.value,
         mantissa |-> mantissa.value ], mantissa.rest)

ZeroMdEntryPx4 ==
    [ exponent |-> [i \in 1 .. 1 |-> 0],
      mantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx4 ==
    { ZeroMdEntryPx4 }
        \cup { [ZeroMdEntryPx4 EXCEPT !.exponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx4 EXCEPT !.mantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entries: 6 bytes                                                     *)
(***************************************************************************)

MdEntries4 ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx4 ]

EncodeMdEntries4(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx4(message.mdEntryPx)

DecodeMdEntries4(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx4(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroMdEntries4 ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx4 ]

(* Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedMdEntries4 ==
    { ZeroMdEntries4 }
        \cup { [ZeroMdEntries4 EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntries4 EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx4 }

(* A run of Md Entries, written one after another *)
RECURSIVE EncodeMdEntries4List(_)
EncodeMdEntries4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntries4(Head(messages)) \o EncodeMdEntries4List(Tail(messages))

(* As many Md Entries as the field that counts them says *)
RECURSIVE ReadMdEntries4List(_, _)
ReadMdEntries4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntries4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntries4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entries of each kind, for the lists that carry them *)
OneMdEntries4 == { ZeroMdEntries4 }

(***************************************************************************)
(* Index Value With Status Message                                         *)
(***************************************************************************)

IndexValueWithStatusMessage ==
    [ indexStatus : Sample(1),
      symbol      : Symbol4,
      mdEntries   : SampleLists(OneMdEntries4) ]

EncodeIndexValueWithStatusMessage(message) ==
    message.indexStatus
        \o EncodeSymbol4(message.symbol)
        \o EncodeUIntBE(Len(message.mdEntries), 1)
        \o EncodeMdEntries4List(message.mdEntries)

DecodeIndexValueWithStatusMessage(bytes) ==
    LET indexStatus == ReadBytes(bytes, 1) IN IF ~indexStatus.ok THEN Fail ELSE
    LET symbol == DecodeSymbol4(indexStatus.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(symbol.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntries4List(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    Ok([ indexStatus |-> indexStatus.value,
         symbol      |-> symbol.value,
         mdEntries   |-> mdEntries.value ], mdEntries.rest)

ZeroIndexValueWithStatusMessage ==
    [ indexStatus |-> [i \in 1 .. 1 |-> 0],
      symbol      |-> ZeroSymbol4,
      mdEntries   |-> << >> ]

(* Index Value With Status Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueWithStatusMessage ==
    { ZeroIndexValueWithStatusMessage }
        \cup { [ZeroIndexValueWithStatusMessage EXCEPT !.indexStatus = one] : one \in Sample(1) }
        \cup { [ZeroIndexValueWithStatusMessage EXCEPT !.symbol = one] : one \in CheckedSymbol4 }
        \cup { [ZeroIndexValueWithStatusMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries4) }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol5 ==
    [ symbolChars : SampleBytes ]

EncodeSymbol5(message) ==
    EncodeUIntBE(Len(message.symbolChars), 1)
        \o message.symbolChars

DecodeSymbol5(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolChars == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolChars.ok THEN Fail ELSE
    Ok([ symbolChars |-> symbolChars.value ], symbolChars.rest)

ZeroSymbol5 ==
    [ symbolChars |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol5 ==
    { ZeroSymbol5 }
        \cup { [ZeroSymbol5 EXCEPT !.symbolChars = one] : one \in SampleBytes }

(***************************************************************************)
(* Date: 11 bytes                                                          *)
(***************************************************************************)

Date ==
    [ byteLength : Sample(1),
      dateChars  : Sample(10) ]

EncodeDate(message) ==
    message.byteLength
        \o message.dateChars

DecodeDate(bytes) ==
    LET byteLength == ReadBytes(bytes, 1) IN IF ~byteLength.ok THEN Fail ELSE
    LET dateChars == ReadBytes(byteLength.rest, 10) IN IF ~dateChars.ok THEN Fail ELSE
    Ok([ byteLength |-> byteLength.value,
         dateChars  |-> dateChars.value ], dateChars.rest)

ZeroDate ==
    [ byteLength |-> [i \in 1 .. 1 |-> 0],
      dateChars  |-> [i \in 1 .. 10 |-> 0] ]

(* Date at zero, then each field in turn at the values it is checked at *)
CheckedDate ==
    { ZeroDate }
        \cup { [ZeroDate EXCEPT !.byteLength = one] : one \in Sample(1) }
        \cup { [ZeroDate EXCEPT !.dateChars = one] : one \in Sample(10) }

(***************************************************************************)
(* Channels                                                                *)
(***************************************************************************)

Channels ==
    [ channel : SampleBytes ]

EncodeChannels(message) ==
    EncodeUIntBE(Len(message.channel), 1)
        \o message.channel

DecodeChannels(bytes) ==
    LET channelLength == ReadUIntBE(bytes, 1) IN IF ~channelLength.ok THEN Fail ELSE
    LET channel == ReadBytes(channelLength.rest, channelLength.value) IN IF ~channel.ok THEN Fail ELSE
    Ok([ channel |-> channel.value ], channel.rest)

ZeroChannels ==
    [ channel |-> << >> ]

(* Channels at zero, then each field in turn at the values it is checked at *)
CheckedChannels ==
    { ZeroChannels }
        \cup { [ZeroChannels EXCEPT !.channel = one] : one \in SampleBytes }

(* A run of Channels, written one after another *)
RECURSIVE EncodeChannelsList(_)
EncodeChannelsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeChannels(Head(messages)) \o EncodeChannelsList(Tail(messages))

(* As many Channels as the field that counts them says *)
RECURSIVE ReadChannelsList(_, _)
ReadChannelsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeChannels(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadChannelsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Channels of each kind, for the lists that carry them *)
OneChannels == { ZeroChannels }

(***************************************************************************)
(* Index Definition Message                                                *)
(***************************************************************************)

IndexDefinitionMessage ==
    [ currentRecordNumber  : Sample(4),
      totalNumberOfRecords : Sample(4),
      symbol               : Symbol5,
      description          : SampleBytes,
      date                 : Date,
      status               : Sample(1),
      agentClassification  : Sample(2),
      channels             : SampleLists(OneChannels) ]

EncodeIndexDefinitionMessage(message) ==
    message.currentRecordNumber
        \o message.totalNumberOfRecords
        \o EncodeSymbol5(message.symbol)
        \o EncodeUIntBE(Len(message.description), 1)
        \o message.description
        \o EncodeDate(message.date)
        \o message.status
        \o message.agentClassification
        \o EncodeUIntBE(Len(message.channels), 1)
        \o EncodeChannelsList(message.channels)

DecodeIndexDefinitionMessage(bytes) ==
    LET currentRecordNumber == ReadBytes(bytes, 4) IN IF ~currentRecordNumber.ok THEN Fail ELSE
    LET totalNumberOfRecords == ReadBytes(currentRecordNumber.rest, 4) IN IF ~totalNumberOfRecords.ok THEN Fail ELSE
    LET symbol == DecodeSymbol5(totalNumberOfRecords.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET descriptionLength == ReadUIntBE(symbol.rest, 1) IN IF ~descriptionLength.ok THEN Fail ELSE
    LET description == ReadBytes(descriptionLength.rest, descriptionLength.value) IN IF ~description.ok THEN Fail ELSE
    LET date == DecodeDate(description.rest) IN IF ~date.ok THEN Fail ELSE
    LET status == ReadBytes(date.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET agentClassification == ReadBytes(status.rest, 2) IN IF ~agentClassification.ok THEN Fail ELSE
    LET noChannels == ReadUIntBE(agentClassification.rest, 1) IN IF ~noChannels.ok THEN Fail ELSE
    LET channels == ReadChannelsList(noChannels.rest, noChannels.value) IN IF ~channels.ok THEN Fail ELSE
    Ok([ currentRecordNumber  |-> currentRecordNumber.value,
         totalNumberOfRecords |-> totalNumberOfRecords.value,
         symbol               |-> symbol.value,
         description          |-> description.value,
         date                 |-> date.value,
         status               |-> status.value,
         agentClassification  |-> agentClassification.value,
         channels             |-> channels.value ], channels.rest)

ZeroIndexDefinitionMessage ==
    [ currentRecordNumber  |-> [i \in 1 .. 4 |-> 0],
      totalNumberOfRecords |-> [i \in 1 .. 4 |-> 0],
      symbol               |-> ZeroSymbol5,
      description          |-> << >>,
      date                 |-> ZeroDate,
      status               |-> [i \in 1 .. 1 |-> 0],
      agentClassification  |-> [i \in 1 .. 2 |-> 0],
      channels             |-> << >> ]

(* Index Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDefinitionMessage ==
    { ZeroIndexDefinitionMessage }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.currentRecordNumber = one] : one \in Sample(4) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.totalNumberOfRecords = one] : one \in Sample(4) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.symbol = one] : one \in CheckedSymbol5 }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.description = one] : one \in SampleBytes }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.date = one] : one \in CheckedDate }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.agentClassification = one] : one \in Sample(2) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.channels = one] : one \in SampleLists(OneChannels) }

(***************************************************************************)
(* Payload, selected by Template ID                                        *)
(***************************************************************************)

HeartbeatMessageCode == 16  \* 0x10
IndexValueMessageCode == 22  \* 0x16
ContributorValueMessageCode == 23  \* 0x17
IndexSummaryMessageCode == 24  \* 0x18
IndexValueWithStatusMessageCode == 25  \* 0x19
IndexDefinitionMessageCode == 26  \* 0x1a

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {IndexValueMessageCode}, body : IndexValueMessage ]
        \cup [ tag : {ContributorValueMessageCode}, body : ContributorValueMessage ]
        \cup [ tag : {IndexSummaryMessageCode}, body : IndexSummaryMessage ]
        \cup [ tag : {IndexValueWithStatusMessageCode}, body : IndexValueWithStatusMessage ]
        \cup [ tag : {IndexDefinitionMessageCode}, body : IndexDefinitionMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = IndexValueMessageCode -> EncodeIndexValueMessage(message.body)
      [] message.tag = ContributorValueMessageCode -> EncodeContributorValueMessage(message.body)
      [] message.tag = IndexSummaryMessageCode -> EncodeIndexSummaryMessage(message.body)
      [] message.tag = IndexValueWithStatusMessageCode -> EncodeIndexValueWithStatusMessage(message.body)
      [] message.tag = IndexDefinitionMessageCode -> EncodeIndexDefinitionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = IndexValueMessageCode -> DecodeIndexValueMessage(bytes)
              [] tag = ContributorValueMessageCode -> DecodeContributorValueMessage(bytes)
              [] tag = IndexSummaryMessageCode -> DecodeIndexSummaryMessage(bytes)
              [] tag = IndexValueWithStatusMessageCode -> DecodeIndexValueWithStatusMessage(bytes)
              [] tag = IndexDefinitionMessageCode -> DecodeIndexDefinitionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> IndexValueMessageCode, body |-> one] : one \in CheckedIndexValueMessage }
        \cup { [tag |-> ContributorValueMessageCode, body |-> one] : one \in CheckedContributorValueMessage }
        \cup { [tag |-> IndexSummaryMessageCode, body |-> one] : one \in CheckedIndexSummaryMessage }
        \cup { [tag |-> IndexValueWithStatusMessageCode, body |-> one] : one \in CheckedIndexValueWithStatusMessage }
        \cup { [tag |-> IndexDefinitionMessageCode, body |-> one] : one \in CheckedIndexDefinitionMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexValueMessageCode, body |-> ZeroIndexValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ContributorValueMessageCode, body |-> ZeroContributorValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexSummaryMessageCode, body |-> ZeroIndexSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexValueWithStatusMessageCode, body |-> ZeroIndexValueWithStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexDefinitionMessageCode, body |-> ZeroIndexDefinitionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version        : Sample(1),
      length         : Sample(2),
      sendingTime    : Sample(8),
      firstMsgSeqNum : Sample(4),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.version
        \o message.length
        \o message.sendingTime
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.firstMsgSeqNum
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET length == ReadBytes(version.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(length.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET numberOfMessages == ReadUIntBE(sendingTime.rest, 1) IN IF ~numberOfMessages.ok THEN Fail ELSE
    LET firstMsgSeqNum == ReadBytes(numberOfMessages.rest, 4) IN IF ~firstMsgSeqNum.ok THEN Fail ELSE
    LET message == ReadMessageList(firstMsgSeqNum.rest, numberOfMessages.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ version        |-> version.value,
         length         |-> length.value,
         sendingTime    |-> sendingTime.value,
         firstMsgSeqNum |-> firstMsgSeqNum.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ version        |-> [i \in 1 .. 1 |-> 0],
      length         |-> [i \in 1 .. 2 |-> 0],
      sendingTime    |-> [i \in 1 .. 8 |-> 0],
      firstMsgSeqNum |-> [i \in 1 .. 4 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
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

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol2 ==
    \A message \in CheckedSymbol2 :
        LET read == DecodeSymbol2(EncodeSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx2 ==
    \A message \in CheckedMdEntryPx2 :
        LET read == DecodeMdEntryPx2(EncodeMdEntryPx2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntries2 ==
    \A message \in CheckedMdEntries2 :
        LET read == DecodeMdEntries2(EncodeMdEntries2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contributor Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripContributorValueMessage ==
    \A message \in CheckedContributorValueMessage :
        LET read == DecodeContributorValueMessage(EncodeContributorValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Effective Business Date decodes back to what was encoded, and leaves nothing over *)
RoundTripEffectiveBusinessDate ==
    \A message \in CheckedEffectiveBusinessDate :
        LET read == DecodeEffectiveBusinessDate(EncodeEffectiveBusinessDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol3 ==
    \A message \in CheckedSymbol3 :
        LET read == DecodeSymbol3(EncodeSymbol3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx3 ==
    \A message \in CheckedMdEntryPx3 :
        LET read == DecodeMdEntryPx3(EncodeMdEntryPx3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntries3 ==
    \A message \in CheckedMdEntries3 :
        LET read == DecodeMdEntries3(EncodeMdEntries3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexSummaryMessage ==
    \A message \in CheckedIndexSummaryMessage :
        LET read == DecodeIndexSummaryMessage(EncodeIndexSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol4 ==
    \A message \in CheckedSymbol4 :
        LET read == DecodeSymbol4(EncodeSymbol4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx4 ==
    \A message \in CheckedMdEntryPx4 :
        LET read == DecodeMdEntryPx4(EncodeMdEntryPx4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntries4 ==
    \A message \in CheckedMdEntries4 :
        LET read == DecodeMdEntries4(EncodeMdEntries4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value With Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueWithStatusMessage ==
    \A message \in CheckedIndexValueWithStatusMessage :
        LET read == DecodeIndexValueWithStatusMessage(EncodeIndexValueWithStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol5 ==
    \A message \in CheckedSymbol5 :
        LET read == DecodeSymbol5(EncodeSymbol5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDate ==
    \A message \in CheckedDate :
        LET read == DecodeDate(EncodeDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channels decodes back to what was encoded, and leaves nothing over *)
RoundTripChannels ==
    \A message \in CheckedChannels :
        LET read == DecodeChannels(EncodeChannels(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDefinitionMessage ==
    \A message \in CheckedIndexDefinitionMessage :
        LET read == DecodeIndexDefinitionMessage(EncodeIndexDefinitionMessage(message))
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

(* A Payload is selected by the Template ID it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
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
