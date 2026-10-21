------------- MODULE TaifexDerivatives_ClearingMember_v2_18_7 --------------
(***************************************************************************)
(* Taiwan Futures Exchange Clearing Member Order And Execution Report      *)
(* v2.18.7                                                                 *)
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
(* Header Time: 6 bytes                                                    *)
(***************************************************************************)

HeaderTime ==
    [ headerEpochS : Sample(4),
      headerMs     : Sample(2) ]

EncodeHeaderTime(message) ==
    message.headerEpochS
        \o message.headerMs

DecodeHeaderTime(bytes) ==
    LET headerEpochS == ReadBytes(bytes, 4) IN IF ~headerEpochS.ok THEN Fail ELSE
    LET headerMs == ReadBytes(headerEpochS.rest, 2) IN IF ~headerMs.ok THEN Fail ELSE
    Ok([ headerEpochS |-> headerEpochS.value,
         headerMs     |-> headerMs.value ], headerMs.rest)

ZeroHeaderTime ==
    [ headerEpochS |-> [i \in 1 .. 4 |-> 0],
      headerMs     |-> [i \in 1 .. 2 |-> 0] ]

(* Header Time at zero, then each field in turn at the values it is checked at *)
CheckedHeaderTime ==
    { ZeroHeaderTime }
        \cup { [ZeroHeaderTime EXCEPT !.headerEpochS = one] : one \in Sample(4) }
        \cup { [ZeroHeaderTime EXCEPT !.headerMs = one] : one \in Sample(2) }

(***************************************************************************)
(* Wake Up Call Message: 5 bytes                                           *)
(***************************************************************************)

WakeUpCallMessage ==
    [ statuscodeUint81 : Sample(1),
      startinboundnum  : Sample(4) ]

EncodeWakeUpCallMessage(message) ==
    message.statuscodeUint81
        \o message.startinboundnum

DecodeWakeUpCallMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET startinboundnum == ReadBytes(statuscodeUint81.rest, 4) IN IF ~startinboundnum.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value,
         startinboundnum  |-> startinboundnum.value ], startinboundnum.rest)

ZeroWakeUpCallMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0],
      startinboundnum  |-> [i \in 1 .. 4 |-> 0] ]

(* Wake Up Call Message at zero, then each field in turn at the values it is checked at *)
CheckedWakeUpCallMessage ==
    { ZeroWakeUpCallMessage }
        \cup { [ZeroWakeUpCallMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroWakeUpCallMessage EXCEPT !.startinboundnum = one] : one \in Sample(4) }

(***************************************************************************)
(* Wake Up Call Confirmed Message: 1 bytes                                 *)
(***************************************************************************)

WakeUpCallConfirmedMessage ==
    [ version : Sample(1) ]

EncodeWakeUpCallConfirmedMessage(message) ==
    message.version

DecodeWakeUpCallConfirmedMessage(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    Ok([ version |-> version.value ], version.rest)

ZeroWakeUpCallConfirmedMessage ==
    [ version |-> [i \in 1 .. 1 |-> 0] ]

(* Wake Up Call Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedWakeUpCallConfirmedMessage ==
    { ZeroWakeUpCallConfirmedMessage }
        \cup { [ZeroWakeUpCallConfirmedMessage EXCEPT !.version = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Notice Message: 9 bytes                                           *)
(***************************************************************************)

LogonNoticeMessage ==
    [ statuscodeUint81 : Sample(1),
      appendno         : Sample(2),
      endoutboundnum   : Sample(4),
      systemtype       : Sample(1),
      encryptMethod    : Sample(1) ]

EncodeLogonNoticeMessage(message) ==
    message.statuscodeUint81
        \o message.appendno
        \o message.endoutboundnum
        \o message.systemtype
        \o message.encryptMethod

DecodeLogonNoticeMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET appendno == ReadBytes(statuscodeUint81.rest, 2) IN IF ~appendno.ok THEN Fail ELSE
    LET endoutboundnum == ReadBytes(appendno.rest, 4) IN IF ~endoutboundnum.ok THEN Fail ELSE
    LET systemtype == ReadBytes(endoutboundnum.rest, 1) IN IF ~systemtype.ok THEN Fail ELSE
    LET encryptMethod == ReadBytes(systemtype.rest, 1) IN IF ~encryptMethod.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value,
         appendno         |-> appendno.value,
         endoutboundnum   |-> endoutboundnum.value,
         systemtype       |-> systemtype.value,
         encryptMethod    |-> encryptMethod.value ], encryptMethod.rest)

ZeroLogonNoticeMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0],
      appendno         |-> [i \in 1 .. 2 |-> 0],
      endoutboundnum   |-> [i \in 1 .. 4 |-> 0],
      systemtype       |-> [i \in 1 .. 1 |-> 0],
      encryptMethod    |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Notice Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonNoticeMessage ==
    { ZeroLogonNoticeMessage }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.appendno = one] : one \in Sample(2) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.endoutboundnum = one] : one \in Sample(4) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.systemtype = one] : one \in Sample(1) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.encryptMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Subhdr: 6 bytes                                                         *)
(***************************************************************************)

Subhdr ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgtimens  : Sample(4) ]

EncodeSubhdr(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgtimens

DecodeSubhdr(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgtimens == ReadBytes(preserve.rest, 4) IN IF ~msgtimens.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgtimens  |-> msgtimens.value ], msgtimens.rest)

ZeroSubhdr ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgtimens  |-> [i \in 1 .. 4 |-> 0] ]

(* Subhdr at zero, then each field in turn at the values it is checked at *)
CheckedSubhdr ==
    { ZeroSubhdr }
        \cup { [ZeroSubhdr EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubhdr EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubhdr EXCEPT !.msgtimens = one] : one \in Sample(4) }

(***************************************************************************)
(* Final Sequential Number Notification For Group Message: 21 bytes        *)
(***************************************************************************)

FinalSequentialNumberNotificationForGroupMessage ==
    [ subhdr            : Subhdr,
      statuscodeUint162 : Sample(2),
      partid            : Sample(1),
      endoutboundnum    : Sample(4),
      reserved8         : Sample(8) ]

EncodeFinalSequentialNumberNotificationForGroupMessage(message) ==
    EncodeSubhdr(message.subhdr)
        \o message.statuscodeUint162
        \o message.partid
        \o message.endoutboundnum
        \o message.reserved8

DecodeFinalSequentialNumberNotificationForGroupMessage(bytes) ==
    LET subhdr == DecodeSubhdr(bytes) IN IF ~subhdr.ok THEN Fail ELSE
    LET statuscodeUint162 == ReadBytes(subhdr.rest, 2) IN IF ~statuscodeUint162.ok THEN Fail ELSE
    LET partid == ReadBytes(statuscodeUint162.rest, 1) IN IF ~partid.ok THEN Fail ELSE
    LET endoutboundnum == ReadBytes(partid.rest, 4) IN IF ~endoutboundnum.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(endoutboundnum.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ subhdr            |-> subhdr.value,
         statuscodeUint162 |-> statuscodeUint162.value,
         partid            |-> partid.value,
         endoutboundnum    |-> endoutboundnum.value,
         reserved8         |-> reserved8.value ], reserved8.rest)

ZeroFinalSequentialNumberNotificationForGroupMessage ==
    [ subhdr            |-> ZeroSubhdr,
      statuscodeUint162 |-> [i \in 1 .. 2 |-> 0],
      partid            |-> [i \in 1 .. 1 |-> 0],
      endoutboundnum    |-> [i \in 1 .. 4 |-> 0],
      reserved8         |-> [i \in 1 .. 8 |-> 0] ]

(* Final Sequential Number Notification For Group Message at zero, then each field in turn at the values it is checked at *)
CheckedFinalSequentialNumberNotificationForGroupMessage ==
    { ZeroFinalSequentialNumberNotificationForGroupMessage }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.subhdr = one] : one \in CheckedSubhdr }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.statuscodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.partid = one] : one \in Sample(1) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.endoutboundnum = one] : one \in Sample(4) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Request Logon Message: 15 bytes                                         *)
(***************************************************************************)

RequestLogonMessage ==
    [ statuscodeUint81 : Sample(1),
      appendno         : Sample(2),
      fcmid            : Sample(2),
      sessionid        : Sample(2),
      systemtype       : Sample(1),
      apcode           : Sample(1),
      keyvalue         : Sample(1),
      requeststartseq  : Sample(4),
      cancelordersec   : Sample(1) ]

EncodeRequestLogonMessage(message) ==
    message.statuscodeUint81
        \o message.appendno
        \o message.fcmid
        \o message.sessionid
        \o message.systemtype
        \o message.apcode
        \o message.keyvalue
        \o message.requeststartseq
        \o message.cancelordersec

DecodeRequestLogonMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET appendno == ReadBytes(statuscodeUint81.rest, 2) IN IF ~appendno.ok THEN Fail ELSE
    LET fcmid == ReadBytes(appendno.rest, 2) IN IF ~fcmid.ok THEN Fail ELSE
    LET sessionid == ReadBytes(fcmid.rest, 2) IN IF ~sessionid.ok THEN Fail ELSE
    LET systemtype == ReadBytes(sessionid.rest, 1) IN IF ~systemtype.ok THEN Fail ELSE
    LET apcode == ReadBytes(systemtype.rest, 1) IN IF ~apcode.ok THEN Fail ELSE
    LET keyvalue == ReadBytes(apcode.rest, 1) IN IF ~keyvalue.ok THEN Fail ELSE
    LET requeststartseq == ReadBytes(keyvalue.rest, 4) IN IF ~requeststartseq.ok THEN Fail ELSE
    LET cancelordersec == ReadBytes(requeststartseq.rest, 1) IN IF ~cancelordersec.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value,
         appendno         |-> appendno.value,
         fcmid            |-> fcmid.value,
         sessionid        |-> sessionid.value,
         systemtype       |-> systemtype.value,
         apcode           |-> apcode.value,
         keyvalue         |-> keyvalue.value,
         requeststartseq  |-> requeststartseq.value,
         cancelordersec   |-> cancelordersec.value ], cancelordersec.rest)

ZeroRequestLogonMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0],
      appendno         |-> [i \in 1 .. 2 |-> 0],
      fcmid            |-> [i \in 1 .. 2 |-> 0],
      sessionid        |-> [i \in 1 .. 2 |-> 0],
      systemtype       |-> [i \in 1 .. 1 |-> 0],
      apcode           |-> [i \in 1 .. 1 |-> 0],
      keyvalue         |-> [i \in 1 .. 1 |-> 0],
      requeststartseq  |-> [i \in 1 .. 4 |-> 0],
      cancelordersec   |-> [i \in 1 .. 1 |-> 0] ]

(* Request Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestLogonMessage ==
    { ZeroRequestLogonMessage }
        \cup { [ZeroRequestLogonMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.appendno = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.fcmid = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.sessionid = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.systemtype = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.apcode = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.keyvalue = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.requeststartseq = one] : one \in Sample(4) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.cancelordersec = one] : one \in Sample(1) }

(***************************************************************************)
(* Activate Application System Message: 4 bytes                            *)
(***************************************************************************)

ActivateApplicationSystemMessage ==
    [ statuscodeUint81 : Sample(1),
      heartBtInt       : Sample(1),
      maxflowctrlcnt   : Sample(2) ]

EncodeActivateApplicationSystemMessage(message) ==
    message.statuscodeUint81
        \o message.heartBtInt
        \o message.maxflowctrlcnt

DecodeActivateApplicationSystemMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(statuscodeUint81.rest, 1) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET maxflowctrlcnt == ReadBytes(heartBtInt.rest, 2) IN IF ~maxflowctrlcnt.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value,
         heartBtInt       |-> heartBtInt.value,
         maxflowctrlcnt   |-> maxflowctrlcnt.value ], maxflowctrlcnt.rest)

ZeroActivateApplicationSystemMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0],
      heartBtInt       |-> [i \in 1 .. 1 |-> 0],
      maxflowctrlcnt   |-> [i \in 1 .. 2 |-> 0] ]

(* Activate Application System Message at zero, then each field in turn at the values it is checked at *)
CheckedActivateApplicationSystemMessage ==
    { ZeroActivateApplicationSystemMessage }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.heartBtInt = one] : one \in Sample(1) }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.maxflowctrlcnt = one] : one \in Sample(2) }

(***************************************************************************)
(* Activate Application System Confirmed Message: 1 bytes                  *)
(***************************************************************************)

ActivateApplicationSystemConfirmedMessage ==
    [ statuscodeUint81 : Sample(1) ]

EncodeActivateApplicationSystemConfirmedMessage(message) ==
    message.statuscodeUint81

DecodeActivateApplicationSystemConfirmedMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value ], statuscodeUint81.rest)

ZeroActivateApplicationSystemConfirmedMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Activate Application System Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedActivateApplicationSystemConfirmedMessage ==
    { ZeroActivateApplicationSystemConfirmedMessage }
        \cup { [ZeroActivateApplicationSystemConfirmedMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Logout Confirmed Message: 1 bytes                                       *)
(***************************************************************************)

LogoutConfirmedMessage ==
    [ statuscodeUint81 : Sample(1) ]

EncodeLogoutConfirmedMessage(message) ==
    message.statuscodeUint81

DecodeLogoutConfirmedMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value ], statuscodeUint81.rest)

ZeroLogoutConfirmedMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Logout Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutConfirmedMessage ==
    { ZeroLogoutConfirmedMessage }
        \cup { [ZeroLogoutConfirmedMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Confirm Connection Message: 1 bytes                                     *)
(***************************************************************************)

ConfirmConnectionMessage ==
    [ statuscodeUint81 : Sample(1) ]

EncodeConfirmConnectionMessage(message) ==
    message.statuscodeUint81

DecodeConfirmConnectionMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value ], statuscodeUint81.rest)

ZeroConfirmConnectionMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Confirm Connection Message at zero, then each field in turn at the values it is checked at *)
CheckedConfirmConnectionMessage ==
    { ZeroConfirmConnectionMessage }
        \cup { [ZeroConfirmConnectionMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Connection Confirmed Message: 1 bytes                                   *)
(***************************************************************************)

ConnectionConfirmedMessage ==
    [ statuscodeUint81 : Sample(1) ]

EncodeConnectionConfirmedMessage(message) ==
    message.statuscodeUint81

DecodeConnectionConfirmedMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value ], statuscodeUint81.rest)

ZeroConnectionConfirmedMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Connection Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedConnectionConfirmedMessage ==
    { ZeroConnectionConfirmedMessage }
        \cup { [ZeroConnectionConfirmedMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbolnum: 19 bytes                                                     *)
(***************************************************************************)

Symbolnum ==
    [ pseq1          : Sample(2),
      pseq2          : Sample(2),
      legsideUint822 : Sample(1),
      combop         : Sample(1),
      reserved13     : Sample(13) ]

EncodeSymbolnum(message) ==
    message.pseq1
        \o message.pseq2
        \o message.legsideUint822
        \o message.combop
        \o message.reserved13

DecodeSymbolnum(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET legsideUint822 == ReadBytes(pseq2.rest, 1) IN IF ~legsideUint822.ok THEN Fail ELSE
    LET combop == ReadBytes(legsideUint822.rest, 1) IN IF ~combop.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combop.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1          |-> pseq1.value,
         pseq2          |-> pseq2.value,
         legsideUint822 |-> legsideUint822.value,
         combop         |-> combop.value,
         reserved13     |-> reserved13.value ], reserved13.rest)

ZeroSymbolnum ==
    [ pseq1          |-> [i \in 1 .. 2 |-> 0],
      pseq2          |-> [i \in 1 .. 2 |-> 0],
      legsideUint822 |-> [i \in 1 .. 1 |-> 0],
      combop         |-> [i \in 1 .. 1 |-> 0],
      reserved13     |-> [i \in 1 .. 13 |-> 0] ]

(* Symbolnum at zero, then each field in turn at the values it is checked at *)
CheckedSymbolnum ==
    { ZeroSymbolnum }
        \cup { [ZeroSymbolnum EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolnum EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolnum EXCEPT !.legsideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolnum EXCEPT !.combop = one] : one \in Sample(1) }
        \cup { [ZeroSymbolnum EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symboltext: 20 bytes                                                    *)
(***************************************************************************)

Symboltext ==
    [ symbolChar2020 : Sample(20) ]

EncodeSymboltext(message) ==
    message.symbolChar2020

DecodeSymboltext(bytes) ==
    LET symbolChar2020 == ReadBytes(bytes, 20) IN IF ~symbolChar2020.ok THEN Fail ELSE
    Ok([ symbolChar2020 |-> symbolChar2020.value ], symbolChar2020.rest)

ZeroSymboltext ==
    [ symbolChar2020 |-> [i \in 1 .. 20 |-> 0] ]

(* Symboltext at zero, then each field in turn at the values it is checked at *)
CheckedSymboltext ==
    { ZeroSymboltext }
        \cup { [ZeroSymboltext EXCEPT !.symbolChar2020 = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbolx, selected by Symboltype                                     *)
(***************************************************************************)

SymbolnumCode == 1  \* 0x01
SymboltextCode == 2  \* 0x02

SymSymbolx ==
    [ tag : {SymbolnumCode}, body : Symbolnum ]
        \cup [ tag : {SymboltextCode}, body : Symboltext ]

EncodeSymSymbolx(message) ==
    CASE message.tag = SymbolnumCode -> EncodeSymbolnum(message.body)
      [] message.tag = SymboltextCode -> EncodeSymboltext(message.body)

DecodeSymSymbolx(tag, bytes) ==
    LET read ==
            CASE tag = SymbolnumCode -> DecodeSymbolnum(bytes)
              [] tag = SymboltextCode -> DecodeSymboltext(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolx == [tag |-> SymbolnumCode, body |-> ZeroSymbolnum]

(* Each Sym Symbolx in turn, at the values the message it names is checked at *)
CheckedSymSymbolx ==
    { [tag |-> SymbolnumCode, body |-> one] : one \in CheckedSymbolnum }
        \cup { [tag |-> SymboltextCode, body |-> one] : one \in CheckedSymboltext }

(***************************************************************************)
(* Orgtranstime Msgtime: 6 bytes                                           *)
(***************************************************************************)

OrgtranstimeMsgtime ==
    [ epochsInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeOrgtranstimeMsgtime(message) ==
    message.epochsInt324
        \o message.ms

DecodeOrgtranstimeMsgtime(bytes) ==
    LET epochsInt324 == ReadBytes(bytes, 4) IN IF ~epochsInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochsInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochsInt324 |-> epochsInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroOrgtranstimeMsgtime ==
    [ epochsInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Orgtranstime Msgtime at zero, then each field in turn at the values it is checked at *)
CheckedOrgtranstimeMsgtime ==
    { ZeroOrgtranstimeMsgtime }
        \cup { [ZeroOrgtranstimeMsgtime EXCEPT !.epochsInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgtranstimeMsgtime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msgtime: 6 bytes                                          *)
(***************************************************************************)

TransactTimeMsgtime ==
    [ epochsInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeTransactTimeMsgtime(message) ==
    message.epochsInt324
        \o message.ms

DecodeTransactTimeMsgtime(bytes) ==
    LET epochsInt324 == ReadBytes(bytes, 4) IN IF ~epochsInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochsInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochsInt324 |-> epochsInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroTransactTimeMsgtime ==
    [ epochsInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msgtime at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgtime ==
    { ZeroTransactTimeMsgtime }
        \cup { [ZeroTransactTimeMsgtime EXCEPT !.epochsInt324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgtime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Status Report Message                                             *)
(***************************************************************************)

OrderStatusReportMessage ==
    [ statuscodeUint81    : Sample(1),
      execType            : Sample(1),
      cmid                : Sample(2),
      fcmid               : Sample(2),
      orderno             : Sample(5),
      ordid               : Sample(4),
      userdefine          : Sample(8),
      symSymbolx          : SymSymbolx,
      price               : Sample(4),
      qty                 : Sample(2),
      investoracno        : Sample(4),
      investorflag        : Sample(1),
      side                : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      positionEffect      : Sample(1),
      lastPx              : Sample(4),
      lastQty             : Sample(2),
      pxsubtotal          : Sample(8),
      cumQty              : Sample(2),
      leavesQty           : Sample(2),
      beforeqty           : Sample(2),
      legsideUint822      : Sample(1),
      legpx               : Sample(4),
      legqtyUint1624      : Sample(2),
      orgtranstimeMsgtime : OrgtranstimeMsgtime,
      transactTimeMsgtime : TransactTimeMsgtime,
      targetid            : Sample(1),
      uniqid              : Sample(4),
      rptseq              : Sample(4),
      protocoltype        : Sample(1) ]

EncodeOrderStatusReportMessage(message) ==
    message.statuscodeUint81
        \o message.execType
        \o message.cmid
        \o message.fcmid
        \o message.orderno
        \o message.ordid
        \o message.userdefine
        \o EncodeUIntBE(message.symSymbolx.tag, 1)
        \o EncodeSymSymbolx(message.symSymbolx)
        \o message.price
        \o message.qty
        \o message.investoracno
        \o message.investorflag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxsubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeqty
        \o message.legsideUint822
        \o message.legpx
        \o message.legqtyUint1624
        \o EncodeOrgtranstimeMsgtime(message.orgtranstimeMsgtime)
        \o EncodeTransactTimeMsgtime(message.transactTimeMsgtime)
        \o message.targetid
        \o message.uniqid
        \o message.rptseq
        \o message.protocoltype

DecodeOrderStatusReportMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET execType == ReadBytes(statuscodeUint81.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmid == ReadBytes(execType.rest, 2) IN IF ~cmid.ok THEN Fail ELSE
    LET fcmid == ReadBytes(cmid.rest, 2) IN IF ~fcmid.ok THEN Fail ELSE
    LET orderno == ReadBytes(fcmid.rest, 5) IN IF ~orderno.ok THEN Fail ELSE
    LET ordid == ReadBytes(orderno.rest, 4) IN IF ~ordid.ok THEN Fail ELSE
    LET userdefine == ReadBytes(ordid.rest, 8) IN IF ~userdefine.ok THEN Fail ELSE
    LET symboltype == ReadUIntBE(userdefine.rest, 1) IN IF ~symboltype.ok THEN Fail ELSE
    LET symSymbolx == DecodeSymSymbolx(symboltype.value, symboltype.rest) IN IF ~symSymbolx.ok THEN Fail ELSE
    LET price == ReadBytes(symSymbolx.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investoracno == ReadBytes(qty.rest, 4) IN IF ~investoracno.ok THEN Fail ELSE
    LET investorflag == ReadBytes(investoracno.rest, 1) IN IF ~investorflag.ok THEN Fail ELSE
    LET side == ReadBytes(investorflag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxsubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxsubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxsubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeqty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeqty.ok THEN Fail ELSE
    LET legsideUint822 == ReadBytes(beforeqty.rest, 1) IN IF ~legsideUint822.ok THEN Fail ELSE
    LET legpx == ReadBytes(legsideUint822.rest, 4) IN IF ~legpx.ok THEN Fail ELSE
    LET legqtyUint1624 == ReadBytes(legpx.rest, 2) IN IF ~legqtyUint1624.ok THEN Fail ELSE
    LET orgtranstimeMsgtime == DecodeOrgtranstimeMsgtime(legqtyUint1624.rest) IN IF ~orgtranstimeMsgtime.ok THEN Fail ELSE
    LET transactTimeMsgtime == DecodeTransactTimeMsgtime(orgtranstimeMsgtime.rest) IN IF ~transactTimeMsgtime.ok THEN Fail ELSE
    LET targetid == ReadBytes(transactTimeMsgtime.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET uniqid == ReadBytes(targetid.rest, 4) IN IF ~uniqid.ok THEN Fail ELSE
    LET rptseq == ReadBytes(uniqid.rest, 4) IN IF ~rptseq.ok THEN Fail ELSE
    LET protocoltype == ReadBytes(rptseq.rest, 1) IN IF ~protocoltype.ok THEN Fail ELSE
    Ok([ statuscodeUint81    |-> statuscodeUint81.value,
         execType            |-> execType.value,
         cmid                |-> cmid.value,
         fcmid               |-> fcmid.value,
         orderno             |-> orderno.value,
         ordid               |-> ordid.value,
         userdefine          |-> userdefine.value,
         symSymbolx          |-> symSymbolx.value,
         price               |-> price.value,
         qty                 |-> qty.value,
         investoracno        |-> investoracno.value,
         investorflag        |-> investorflag.value,
         side                |-> side.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         positionEffect      |-> positionEffect.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         pxsubtotal          |-> pxsubtotal.value,
         cumQty              |-> cumQty.value,
         leavesQty           |-> leavesQty.value,
         beforeqty           |-> beforeqty.value,
         legsideUint822      |-> legsideUint822.value,
         legpx               |-> legpx.value,
         legqtyUint1624      |-> legqtyUint1624.value,
         orgtranstimeMsgtime |-> orgtranstimeMsgtime.value,
         transactTimeMsgtime |-> transactTimeMsgtime.value,
         targetid            |-> targetid.value,
         uniqid              |-> uniqid.value,
         rptseq              |-> rptseq.value,
         protocoltype        |-> protocoltype.value ], protocoltype.rest)

ZeroOrderStatusReportMessage ==
    [ statuscodeUint81    |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmid                |-> [i \in 1 .. 2 |-> 0],
      fcmid               |-> [i \in 1 .. 2 |-> 0],
      orderno             |-> [i \in 1 .. 5 |-> 0],
      ordid               |-> [i \in 1 .. 4 |-> 0],
      userdefine          |-> [i \in 1 .. 8 |-> 0],
      symSymbolx          |-> ZeroSymSymbolx,
      price               |-> [i \in 1 .. 4 |-> 0],
      qty                 |-> [i \in 1 .. 2 |-> 0],
      investoracno        |-> [i \in 1 .. 4 |-> 0],
      investorflag        |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      lastPx              |-> [i \in 1 .. 4 |-> 0],
      lastQty             |-> [i \in 1 .. 2 |-> 0],
      pxsubtotal          |-> [i \in 1 .. 8 |-> 0],
      cumQty              |-> [i \in 1 .. 2 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeqty           |-> [i \in 1 .. 2 |-> 0],
      legsideUint822      |-> [i \in 1 .. 1 |-> 0],
      legpx               |-> [i \in 1 .. 4 |-> 0],
      legqtyUint1624      |-> [i \in 1 .. 2 |-> 0],
      orgtranstimeMsgtime |-> ZeroOrgtranstimeMsgtime,
      transactTimeMsgtime |-> ZeroTransactTimeMsgtime,
      targetid            |-> [i \in 1 .. 1 |-> 0],
      uniqid              |-> [i \in 1 .. 4 |-> 0],
      rptseq              |-> [i \in 1 .. 4 |-> 0],
      protocoltype        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusReportMessage ==
    { ZeroOrderStatusReportMessage }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.cmid = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.fcmid = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.orderno = one] : one \in Sample(5) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.ordid = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.userdefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.symSymbolx = one] : one \in CheckedSymSymbolx }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.investoracno = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.investorflag = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.pxsubtotal = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.beforeqty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legsideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legpx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legqtyUint1624 = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.orgtranstimeMsgtime = one] : one \in CheckedOrgtranstimeMsgtime }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.transactTimeMsgtime = one] : one \in CheckedTransactTimeMsgtime }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.uniqid = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.rptseq = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.protocoltype = one] : one \in Sample(1) }

(***************************************************************************)
(* Longsymbolnum: 39 bytes                                                 *)
(***************************************************************************)

Longsymbolnum ==
    [ pseq1          : Sample(2),
      pseq2          : Sample(2),
      legsideUint822 : Sample(1),
      combop         : Sample(1),
      reserved33     : Sample(33) ]

EncodeLongsymbolnum(message) ==
    message.pseq1
        \o message.pseq2
        \o message.legsideUint822
        \o message.combop
        \o message.reserved33

DecodeLongsymbolnum(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET legsideUint822 == ReadBytes(pseq2.rest, 1) IN IF ~legsideUint822.ok THEN Fail ELSE
    LET combop == ReadBytes(legsideUint822.rest, 1) IN IF ~combop.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combop.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1          |-> pseq1.value,
         pseq2          |-> pseq2.value,
         legsideUint822 |-> legsideUint822.value,
         combop         |-> combop.value,
         reserved33     |-> reserved33.value ], reserved33.rest)

ZeroLongsymbolnum ==
    [ pseq1          |-> [i \in 1 .. 2 |-> 0],
      pseq2          |-> [i \in 1 .. 2 |-> 0],
      legsideUint822 |-> [i \in 1 .. 1 |-> 0],
      combop         |-> [i \in 1 .. 1 |-> 0],
      reserved33     |-> [i \in 1 .. 33 |-> 0] ]

(* Longsymbolnum at zero, then each field in turn at the values it is checked at *)
CheckedLongsymbolnum ==
    { ZeroLongsymbolnum }
        \cup { [ZeroLongsymbolnum EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongsymbolnum EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongsymbolnum EXCEPT !.legsideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroLongsymbolnum EXCEPT !.combop = one] : one \in Sample(1) }
        \cup { [ZeroLongsymbolnum EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Longsymboltext: 40 bytes                                                *)
(***************************************************************************)

Longsymboltext ==
    [ symbolChar4040 : Sample(40) ]

EncodeLongsymboltext(message) ==
    message.symbolChar4040

DecodeLongsymboltext(bytes) ==
    LET symbolChar4040 == ReadBytes(bytes, 40) IN IF ~symbolChar4040.ok THEN Fail ELSE
    Ok([ symbolChar4040 |-> symbolChar4040.value ], symbolChar4040.rest)

ZeroLongsymboltext ==
    [ symbolChar4040 |-> [i \in 1 .. 40 |-> 0] ]

(* Longsymboltext at zero, then each field in turn at the values it is checked at *)
CheckedLongsymboltext ==
    { ZeroLongsymboltext }
        \cup { [ZeroLongsymboltext EXCEPT !.symbolChar4040 = one] : one \in Sample(40) }

(***************************************************************************)
(* Sym Longsymbolx, selected by Symboltype                                 *)
(***************************************************************************)

LongsymbolnumCode == 3  \* 0x03
LongsymboltextCode == 4  \* 0x04

SymLongsymbolx ==
    [ tag : {LongsymbolnumCode}, body : Longsymbolnum ]
        \cup [ tag : {LongsymboltextCode}, body : Longsymboltext ]

EncodeSymLongsymbolx(message) ==
    CASE message.tag = LongsymbolnumCode -> EncodeLongsymbolnum(message.body)
      [] message.tag = LongsymboltextCode -> EncodeLongsymboltext(message.body)

DecodeSymLongsymbolx(tag, bytes) ==
    LET read ==
            CASE tag = LongsymbolnumCode -> DecodeLongsymbolnum(bytes)
              [] tag = LongsymboltextCode -> DecodeLongsymboltext(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymLongsymbolx == [tag |-> LongsymbolnumCode, body |-> ZeroLongsymbolnum]

(* Each Sym Longsymbolx in turn, at the values the message it names is checked at *)
CheckedSymLongsymbolx ==
    { [tag |-> LongsymbolnumCode, body |-> one] : one \in CheckedLongsymbolnum }
        \cup { [tag |-> LongsymboltextCode, body |-> one] : one \in CheckedLongsymboltext }

(***************************************************************************)
(* Orgtranstime Msgtime: 6 bytes                                           *)
(***************************************************************************)

OrgtranstimeMsgtime2 ==
    [ epochsInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeOrgtranstimeMsgtime2(message) ==
    message.epochsInt324
        \o message.ms

DecodeOrgtranstimeMsgtime2(bytes) ==
    LET epochsInt324 == ReadBytes(bytes, 4) IN IF ~epochsInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochsInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochsInt324 |-> epochsInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroOrgtranstimeMsgtime2 ==
    [ epochsInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Orgtranstime Msgtime at zero, then each field in turn at the values it is checked at *)
CheckedOrgtranstimeMsgtime2 ==
    { ZeroOrgtranstimeMsgtime2 }
        \cup { [ZeroOrgtranstimeMsgtime2 EXCEPT !.epochsInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgtranstimeMsgtime2 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msgtime: 6 bytes                                          *)
(***************************************************************************)

TransactTimeMsgtime2 ==
    [ epochsInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeTransactTimeMsgtime2(message) ==
    message.epochsInt324
        \o message.ms

DecodeTransactTimeMsgtime2(bytes) ==
    LET epochsInt324 == ReadBytes(bytes, 4) IN IF ~epochsInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochsInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochsInt324 |-> epochsInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroTransactTimeMsgtime2 ==
    [ epochsInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msgtime at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgtime2 ==
    { ZeroTransactTimeMsgtime2 }
        \cup { [ZeroTransactTimeMsgtime2 EXCEPT !.epochsInt324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgtime2 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Status Report Long Format Message                                 *)
(***************************************************************************)

OrderStatusReportLongFormatMessage ==
    [ statuscodeUint81    : Sample(1),
      execType            : Sample(1),
      cmid                : Sample(2),
      fcmid               : Sample(2),
      orderno             : Sample(5),
      ordid               : Sample(4),
      userdefine          : Sample(8),
      symLongsymbolx      : SymLongsymbolx,
      price               : Sample(4),
      qty                 : Sample(2),
      investoracno        : Sample(4),
      investorflag        : Sample(1),
      side                : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      positionEffect      : Sample(1),
      lastPx              : Sample(4),
      lastQty             : Sample(2),
      pxsubtotal          : Sample(8),
      cumQty              : Sample(2),
      leavesQty           : Sample(2),
      beforeqty           : Sample(2),
      legsideUint822      : Sample(1),
      legpx               : Sample(4),
      legqtyUint1624      : Sample(2),
      orgtranstimeMsgtime : OrgtranstimeMsgtime2,
      transactTimeMsgtime : TransactTimeMsgtime2,
      targetid            : Sample(1),
      uniqid              : Sample(4),
      rptseq              : Sample(4),
      protocoltype        : Sample(1) ]

EncodeOrderStatusReportLongFormatMessage(message) ==
    message.statuscodeUint81
        \o message.execType
        \o message.cmid
        \o message.fcmid
        \o message.orderno
        \o message.ordid
        \o message.userdefine
        \o EncodeUIntBE(message.symLongsymbolx.tag, 1)
        \o EncodeSymLongsymbolx(message.symLongsymbolx)
        \o message.price
        \o message.qty
        \o message.investoracno
        \o message.investorflag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxsubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeqty
        \o message.legsideUint822
        \o message.legpx
        \o message.legqtyUint1624
        \o EncodeOrgtranstimeMsgtime2(message.orgtranstimeMsgtime)
        \o EncodeTransactTimeMsgtime2(message.transactTimeMsgtime)
        \o message.targetid
        \o message.uniqid
        \o message.rptseq
        \o message.protocoltype

DecodeOrderStatusReportLongFormatMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET execType == ReadBytes(statuscodeUint81.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmid == ReadBytes(execType.rest, 2) IN IF ~cmid.ok THEN Fail ELSE
    LET fcmid == ReadBytes(cmid.rest, 2) IN IF ~fcmid.ok THEN Fail ELSE
    LET orderno == ReadBytes(fcmid.rest, 5) IN IF ~orderno.ok THEN Fail ELSE
    LET ordid == ReadBytes(orderno.rest, 4) IN IF ~ordid.ok THEN Fail ELSE
    LET userdefine == ReadBytes(ordid.rest, 8) IN IF ~userdefine.ok THEN Fail ELSE
    LET symboltype == ReadUIntBE(userdefine.rest, 1) IN IF ~symboltype.ok THEN Fail ELSE
    LET symLongsymbolx == DecodeSymLongsymbolx(symboltype.value, symboltype.rest) IN IF ~symLongsymbolx.ok THEN Fail ELSE
    LET price == ReadBytes(symLongsymbolx.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investoracno == ReadBytes(qty.rest, 4) IN IF ~investoracno.ok THEN Fail ELSE
    LET investorflag == ReadBytes(investoracno.rest, 1) IN IF ~investorflag.ok THEN Fail ELSE
    LET side == ReadBytes(investorflag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxsubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxsubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxsubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeqty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeqty.ok THEN Fail ELSE
    LET legsideUint822 == ReadBytes(beforeqty.rest, 1) IN IF ~legsideUint822.ok THEN Fail ELSE
    LET legpx == ReadBytes(legsideUint822.rest, 4) IN IF ~legpx.ok THEN Fail ELSE
    LET legqtyUint1624 == ReadBytes(legpx.rest, 2) IN IF ~legqtyUint1624.ok THEN Fail ELSE
    LET orgtranstimeMsgtime == DecodeOrgtranstimeMsgtime2(legqtyUint1624.rest) IN IF ~orgtranstimeMsgtime.ok THEN Fail ELSE
    LET transactTimeMsgtime == DecodeTransactTimeMsgtime2(orgtranstimeMsgtime.rest) IN IF ~transactTimeMsgtime.ok THEN Fail ELSE
    LET targetid == ReadBytes(transactTimeMsgtime.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET uniqid == ReadBytes(targetid.rest, 4) IN IF ~uniqid.ok THEN Fail ELSE
    LET rptseq == ReadBytes(uniqid.rest, 4) IN IF ~rptseq.ok THEN Fail ELSE
    LET protocoltype == ReadBytes(rptseq.rest, 1) IN IF ~protocoltype.ok THEN Fail ELSE
    Ok([ statuscodeUint81    |-> statuscodeUint81.value,
         execType            |-> execType.value,
         cmid                |-> cmid.value,
         fcmid               |-> fcmid.value,
         orderno             |-> orderno.value,
         ordid               |-> ordid.value,
         userdefine          |-> userdefine.value,
         symLongsymbolx      |-> symLongsymbolx.value,
         price               |-> price.value,
         qty                 |-> qty.value,
         investoracno        |-> investoracno.value,
         investorflag        |-> investorflag.value,
         side                |-> side.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         positionEffect      |-> positionEffect.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         pxsubtotal          |-> pxsubtotal.value,
         cumQty              |-> cumQty.value,
         leavesQty           |-> leavesQty.value,
         beforeqty           |-> beforeqty.value,
         legsideUint822      |-> legsideUint822.value,
         legpx               |-> legpx.value,
         legqtyUint1624      |-> legqtyUint1624.value,
         orgtranstimeMsgtime |-> orgtranstimeMsgtime.value,
         transactTimeMsgtime |-> transactTimeMsgtime.value,
         targetid            |-> targetid.value,
         uniqid              |-> uniqid.value,
         rptseq              |-> rptseq.value,
         protocoltype        |-> protocoltype.value ], protocoltype.rest)

ZeroOrderStatusReportLongFormatMessage ==
    [ statuscodeUint81    |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmid                |-> [i \in 1 .. 2 |-> 0],
      fcmid               |-> [i \in 1 .. 2 |-> 0],
      orderno             |-> [i \in 1 .. 5 |-> 0],
      ordid               |-> [i \in 1 .. 4 |-> 0],
      userdefine          |-> [i \in 1 .. 8 |-> 0],
      symLongsymbolx      |-> ZeroSymLongsymbolx,
      price               |-> [i \in 1 .. 4 |-> 0],
      qty                 |-> [i \in 1 .. 2 |-> 0],
      investoracno        |-> [i \in 1 .. 4 |-> 0],
      investorflag        |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      lastPx              |-> [i \in 1 .. 4 |-> 0],
      lastQty             |-> [i \in 1 .. 2 |-> 0],
      pxsubtotal          |-> [i \in 1 .. 8 |-> 0],
      cumQty              |-> [i \in 1 .. 2 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeqty           |-> [i \in 1 .. 2 |-> 0],
      legsideUint822      |-> [i \in 1 .. 1 |-> 0],
      legpx               |-> [i \in 1 .. 4 |-> 0],
      legqtyUint1624      |-> [i \in 1 .. 2 |-> 0],
      orgtranstimeMsgtime |-> ZeroOrgtranstimeMsgtime2,
      transactTimeMsgtime |-> ZeroTransactTimeMsgtime2,
      targetid            |-> [i \in 1 .. 1 |-> 0],
      uniqid              |-> [i \in 1 .. 4 |-> 0],
      rptseq              |-> [i \in 1 .. 4 |-> 0],
      protocoltype        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Status Report Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusReportLongFormatMessage ==
    { ZeroOrderStatusReportLongFormatMessage }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.cmid = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.fcmid = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.orderno = one] : one \in Sample(5) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.ordid = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.userdefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.symLongsymbolx = one] : one \in CheckedSymLongsymbolx }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.investoracno = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.investorflag = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.pxsubtotal = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.beforeqty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legsideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legpx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legqtyUint1624 = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.orgtranstimeMsgtime = one] : one \in CheckedOrgtranstimeMsgtime2 }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.transactTimeMsgtime = one] : one \in CheckedTransactTimeMsgtime2 }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.uniqid = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.rptseq = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.protocoltype = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbolnum: 19 bytes                                                     *)
(***************************************************************************)

Symbolnum2 ==
    [ pseq1          : Sample(2),
      pseq2          : Sample(2),
      legsideUint822 : Sample(1),
      combop         : Sample(1),
      reserved13     : Sample(13) ]

EncodeSymbolnum2(message) ==
    message.pseq1
        \o message.pseq2
        \o message.legsideUint822
        \o message.combop
        \o message.reserved13

DecodeSymbolnum2(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET legsideUint822 == ReadBytes(pseq2.rest, 1) IN IF ~legsideUint822.ok THEN Fail ELSE
    LET combop == ReadBytes(legsideUint822.rest, 1) IN IF ~combop.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combop.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1          |-> pseq1.value,
         pseq2          |-> pseq2.value,
         legsideUint822 |-> legsideUint822.value,
         combop         |-> combop.value,
         reserved13     |-> reserved13.value ], reserved13.rest)

ZeroSymbolnum2 ==
    [ pseq1          |-> [i \in 1 .. 2 |-> 0],
      pseq2          |-> [i \in 1 .. 2 |-> 0],
      legsideUint822 |-> [i \in 1 .. 1 |-> 0],
      combop         |-> [i \in 1 .. 1 |-> 0],
      reserved13     |-> [i \in 1 .. 13 |-> 0] ]

(* Symbolnum at zero, then each field in turn at the values it is checked at *)
CheckedSymbolnum2 ==
    { ZeroSymbolnum2 }
        \cup { [ZeroSymbolnum2 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolnum2 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolnum2 EXCEPT !.legsideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolnum2 EXCEPT !.combop = one] : one \in Sample(1) }
        \cup { [ZeroSymbolnum2 EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symboltext: 20 bytes                                                    *)
(***************************************************************************)

Symboltext2 ==
    [ symbolChar2020 : Sample(20) ]

EncodeSymboltext2(message) ==
    message.symbolChar2020

DecodeSymboltext2(bytes) ==
    LET symbolChar2020 == ReadBytes(bytes, 20) IN IF ~symbolChar2020.ok THEN Fail ELSE
    Ok([ symbolChar2020 |-> symbolChar2020.value ], symbolChar2020.rest)

ZeroSymboltext2 ==
    [ symbolChar2020 |-> [i \in 1 .. 20 |-> 0] ]

(* Symboltext at zero, then each field in turn at the values it is checked at *)
CheckedSymboltext2 ==
    { ZeroSymboltext2 }
        \cup { [ZeroSymboltext2 EXCEPT !.symbolChar2020 = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbolx, selected by Symboltype                                     *)
(***************************************************************************)

SymbolnumCode2 == 1  \* 0x01
SymboltextCode2 == 2  \* 0x02

SymSymbolx2 ==
    [ tag : {SymbolnumCode2}, body : Symbolnum2 ]
        \cup [ tag : {SymboltextCode2}, body : Symboltext2 ]

EncodeSymSymbolx2(message) ==
    CASE message.tag = SymbolnumCode2 -> EncodeSymbolnum2(message.body)
      [] message.tag = SymboltextCode2 -> EncodeSymboltext2(message.body)

DecodeSymSymbolx2(tag, bytes) ==
    LET read ==
            CASE tag = SymbolnumCode2 -> DecodeSymbolnum2(bytes)
              [] tag = SymboltextCode2 -> DecodeSymboltext2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolx2 == [tag |-> SymbolnumCode2, body |-> ZeroSymbolnum2]

(* Each Sym Symbolx in turn, at the values the message it names is checked at *)
CheckedSymSymbolx2 ==
    { [tag |-> SymbolnumCode2, body |-> one] : one \in CheckedSymbolnum2 }
        \cup { [tag |-> SymboltextCode2, body |-> one] : one \in CheckedSymboltext2 }

(***************************************************************************)
(* Orgtranstime Msgtime: 6 bytes                                           *)
(***************************************************************************)

OrgtranstimeMsgtime3 ==
    [ epochsInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeOrgtranstimeMsgtime3(message) ==
    message.epochsInt324
        \o message.ms

DecodeOrgtranstimeMsgtime3(bytes) ==
    LET epochsInt324 == ReadBytes(bytes, 4) IN IF ~epochsInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochsInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochsInt324 |-> epochsInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroOrgtranstimeMsgtime3 ==
    [ epochsInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Orgtranstime Msgtime at zero, then each field in turn at the values it is checked at *)
CheckedOrgtranstimeMsgtime3 ==
    { ZeroOrgtranstimeMsgtime3 }
        \cup { [ZeroOrgtranstimeMsgtime3 EXCEPT !.epochsInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgtranstimeMsgtime3 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msgtime: 6 bytes                                          *)
(***************************************************************************)

TransactTimeMsgtime3 ==
    [ epochsInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeTransactTimeMsgtime3(message) ==
    message.epochsInt324
        \o message.ms

DecodeTransactTimeMsgtime3(bytes) ==
    LET epochsInt324 == ReadBytes(bytes, 4) IN IF ~epochsInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochsInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochsInt324 |-> epochsInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroTransactTimeMsgtime3 ==
    [ epochsInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msgtime at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgtime3 ==
    { ZeroTransactTimeMsgtime3 }
        \cup { [ZeroTransactTimeMsgtime3 EXCEPT !.epochsInt324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgtime3 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Report Including Head Office And Branch Offices Message       *)
(***************************************************************************)

ExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    [ statuscodeUint81    : Sample(1),
      execType            : Sample(1),
      cmid                : Sample(2),
      fcmid               : Sample(2),
      orderno             : Sample(5),
      ordid               : Sample(4),
      userdefine          : Sample(8),
      symSymbolx          : SymSymbolx2,
      price               : Sample(4),
      qty                 : Sample(2),
      investoracno        : Sample(4),
      investorflag        : Sample(1),
      side                : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      positionEffect      : Sample(1),
      lastPx              : Sample(4),
      lastQty             : Sample(2),
      pxsubtotal          : Sample(8),
      cumQty              : Sample(2),
      leavesQty           : Sample(2),
      beforeqty           : Sample(2),
      legsideUint822      : Sample(1),
      legpx               : Sample(4),
      legqtyUint1624      : Sample(2),
      orgtranstimeMsgtime : OrgtranstimeMsgtime3,
      transactTimeMsgtime : TransactTimeMsgtime3,
      targetid            : Sample(1),
      uniqid              : Sample(4),
      rptseq              : Sample(4),
      protocoltype        : Sample(1),
      rptsessionid        : Sample(2) ]

EncodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(message) ==
    message.statuscodeUint81
        \o message.execType
        \o message.cmid
        \o message.fcmid
        \o message.orderno
        \o message.ordid
        \o message.userdefine
        \o EncodeUIntBE(message.symSymbolx.tag, 1)
        \o EncodeSymSymbolx2(message.symSymbolx)
        \o message.price
        \o message.qty
        \o message.investoracno
        \o message.investorflag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxsubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeqty
        \o message.legsideUint822
        \o message.legpx
        \o message.legqtyUint1624
        \o EncodeOrgtranstimeMsgtime3(message.orgtranstimeMsgtime)
        \o EncodeTransactTimeMsgtime3(message.transactTimeMsgtime)
        \o message.targetid
        \o message.uniqid
        \o message.rptseq
        \o message.protocoltype
        \o message.rptsessionid

DecodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET execType == ReadBytes(statuscodeUint81.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmid == ReadBytes(execType.rest, 2) IN IF ~cmid.ok THEN Fail ELSE
    LET fcmid == ReadBytes(cmid.rest, 2) IN IF ~fcmid.ok THEN Fail ELSE
    LET orderno == ReadBytes(fcmid.rest, 5) IN IF ~orderno.ok THEN Fail ELSE
    LET ordid == ReadBytes(orderno.rest, 4) IN IF ~ordid.ok THEN Fail ELSE
    LET userdefine == ReadBytes(ordid.rest, 8) IN IF ~userdefine.ok THEN Fail ELSE
    LET symboltype == ReadUIntBE(userdefine.rest, 1) IN IF ~symboltype.ok THEN Fail ELSE
    LET symSymbolx == DecodeSymSymbolx2(symboltype.value, symboltype.rest) IN IF ~symSymbolx.ok THEN Fail ELSE
    LET price == ReadBytes(symSymbolx.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investoracno == ReadBytes(qty.rest, 4) IN IF ~investoracno.ok THEN Fail ELSE
    LET investorflag == ReadBytes(investoracno.rest, 1) IN IF ~investorflag.ok THEN Fail ELSE
    LET side == ReadBytes(investorflag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxsubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxsubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxsubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeqty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeqty.ok THEN Fail ELSE
    LET legsideUint822 == ReadBytes(beforeqty.rest, 1) IN IF ~legsideUint822.ok THEN Fail ELSE
    LET legpx == ReadBytes(legsideUint822.rest, 4) IN IF ~legpx.ok THEN Fail ELSE
    LET legqtyUint1624 == ReadBytes(legpx.rest, 2) IN IF ~legqtyUint1624.ok THEN Fail ELSE
    LET orgtranstimeMsgtime == DecodeOrgtranstimeMsgtime3(legqtyUint1624.rest) IN IF ~orgtranstimeMsgtime.ok THEN Fail ELSE
    LET transactTimeMsgtime == DecodeTransactTimeMsgtime3(orgtranstimeMsgtime.rest) IN IF ~transactTimeMsgtime.ok THEN Fail ELSE
    LET targetid == ReadBytes(transactTimeMsgtime.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET uniqid == ReadBytes(targetid.rest, 4) IN IF ~uniqid.ok THEN Fail ELSE
    LET rptseq == ReadBytes(uniqid.rest, 4) IN IF ~rptseq.ok THEN Fail ELSE
    LET protocoltype == ReadBytes(rptseq.rest, 1) IN IF ~protocoltype.ok THEN Fail ELSE
    LET rptsessionid == ReadBytes(protocoltype.rest, 2) IN IF ~rptsessionid.ok THEN Fail ELSE
    Ok([ statuscodeUint81    |-> statuscodeUint81.value,
         execType            |-> execType.value,
         cmid                |-> cmid.value,
         fcmid               |-> fcmid.value,
         orderno             |-> orderno.value,
         ordid               |-> ordid.value,
         userdefine          |-> userdefine.value,
         symSymbolx          |-> symSymbolx.value,
         price               |-> price.value,
         qty                 |-> qty.value,
         investoracno        |-> investoracno.value,
         investorflag        |-> investorflag.value,
         side                |-> side.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         positionEffect      |-> positionEffect.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         pxsubtotal          |-> pxsubtotal.value,
         cumQty              |-> cumQty.value,
         leavesQty           |-> leavesQty.value,
         beforeqty           |-> beforeqty.value,
         legsideUint822      |-> legsideUint822.value,
         legpx               |-> legpx.value,
         legqtyUint1624      |-> legqtyUint1624.value,
         orgtranstimeMsgtime |-> orgtranstimeMsgtime.value,
         transactTimeMsgtime |-> transactTimeMsgtime.value,
         targetid            |-> targetid.value,
         uniqid              |-> uniqid.value,
         rptseq              |-> rptseq.value,
         protocoltype        |-> protocoltype.value,
         rptsessionid        |-> rptsessionid.value ], rptsessionid.rest)

ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    [ statuscodeUint81    |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmid                |-> [i \in 1 .. 2 |-> 0],
      fcmid               |-> [i \in 1 .. 2 |-> 0],
      orderno             |-> [i \in 1 .. 5 |-> 0],
      ordid               |-> [i \in 1 .. 4 |-> 0],
      userdefine          |-> [i \in 1 .. 8 |-> 0],
      symSymbolx          |-> ZeroSymSymbolx2,
      price               |-> [i \in 1 .. 4 |-> 0],
      qty                 |-> [i \in 1 .. 2 |-> 0],
      investoracno        |-> [i \in 1 .. 4 |-> 0],
      investorflag        |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      lastPx              |-> [i \in 1 .. 4 |-> 0],
      lastQty             |-> [i \in 1 .. 2 |-> 0],
      pxsubtotal          |-> [i \in 1 .. 8 |-> 0],
      cumQty              |-> [i \in 1 .. 2 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeqty           |-> [i \in 1 .. 2 |-> 0],
      legsideUint822      |-> [i \in 1 .. 1 |-> 0],
      legpx               |-> [i \in 1 .. 4 |-> 0],
      legqtyUint1624      |-> [i \in 1 .. 2 |-> 0],
      orgtranstimeMsgtime |-> ZeroOrgtranstimeMsgtime3,
      transactTimeMsgtime |-> ZeroTransactTimeMsgtime3,
      targetid            |-> [i \in 1 .. 1 |-> 0],
      uniqid              |-> [i \in 1 .. 4 |-> 0],
      rptseq              |-> [i \in 1 .. 4 |-> 0],
      protocoltype        |-> [i \in 1 .. 1 |-> 0],
      rptsessionid        |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Report Including Head Office And Branch Offices Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    { ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.cmid = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.fcmid = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.orderno = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.ordid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.userdefine = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.symSymbolx = one] : one \in CheckedSymSymbolx2 }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.investoracno = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.investorflag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.pxsubtotal = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.beforeqty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.legsideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.legpx = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.legqtyUint1624 = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.orgtranstimeMsgtime = one] : one \in CheckedOrgtranstimeMsgtime3 }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.transactTimeMsgtime = one] : one \in CheckedTransactTimeMsgtime3 }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.uniqid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.rptseq = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.protocoltype = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.rptsessionid = one] : one \in Sample(2) }

(***************************************************************************)
(* Symbolnumx: 4 bytes                                                     *)
(***************************************************************************)

Symbolnumx ==
    [ pseq : Sample(4) ]

EncodeSymbolnumx(message) ==
    message.pseq

DecodeSymbolnumx(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroSymbolnumx ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Symbolnumx at zero, then each field in turn at the values it is checked at *)
CheckedSymbolnumx ==
    { ZeroSymbolnumx }
        \cup { [ZeroSymbolnumx EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Symboltxtx: 20 bytes                                                    *)
(***************************************************************************)

Symboltxtx ==
    [ prodid : Sample(20) ]

EncodeSymboltxtx(message) ==
    message.prodid

DecodeSymboltxtx(bytes) ==
    LET prodid == ReadBytes(bytes, 20) IN IF ~prodid.ok THEN Fail ELSE
    Ok([ prodid |-> prodid.value ], prodid.rest)

ZeroSymboltxtx ==
    [ prodid |-> [i \in 1 .. 20 |-> 0] ]

(* Symboltxtx at zero, then each field in turn at the values it is checked at *)
CheckedSymboltxtx ==
    { ZeroSymboltxtx }
        \cup { [ZeroSymboltxtx EXCEPT !.prodid = one] : one \in Sample(20) }

(***************************************************************************)
(* Legsym Symbolnumx: 4 bytes                                              *)
(***************************************************************************)

LegsymSymbolnumx ==
    [ pseq : Sample(4) ]

EncodeLegsymSymbolnumx(message) ==
    message.pseq

DecodeLegsymSymbolnumx(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroLegsymSymbolnumx ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Legsym Symbolnumx at zero, then each field in turn at the values it is checked at *)
CheckedLegsymSymbolnumx ==
    { ZeroLegsymSymbolnumx }
        \cup { [ZeroLegsymSymbolnumx EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Legentrynum: 7 bytes                                                    *)
(***************************************************************************)

Legentrynum ==
    [ legsymSymbolnumx : LegsymSymbolnumx,
      legsideUint81    : Sample(1),
      legqtyUint162    : Sample(2) ]

EncodeLegentrynum(message) ==
    EncodeLegsymSymbolnumx(message.legsymSymbolnumx)
        \o message.legsideUint81
        \o message.legqtyUint162

DecodeLegentrynum(bytes) ==
    LET legsymSymbolnumx == DecodeLegsymSymbolnumx(bytes) IN IF ~legsymSymbolnumx.ok THEN Fail ELSE
    LET legsideUint81 == ReadBytes(legsymSymbolnumx.rest, 1) IN IF ~legsideUint81.ok THEN Fail ELSE
    LET legqtyUint162 == ReadBytes(legsideUint81.rest, 2) IN IF ~legqtyUint162.ok THEN Fail ELSE
    Ok([ legsymSymbolnumx |-> legsymSymbolnumx.value,
         legsideUint81    |-> legsideUint81.value,
         legqtyUint162    |-> legqtyUint162.value ], legqtyUint162.rest)

ZeroLegentrynum ==
    [ legsymSymbolnumx |-> ZeroLegsymSymbolnumx,
      legsideUint81    |-> [i \in 1 .. 1 |-> 0],
      legqtyUint162    |-> [i \in 1 .. 2 |-> 0] ]

(* Legentrynum at zero, then each field in turn at the values it is checked at *)
CheckedLegentrynum ==
    { ZeroLegentrynum }
        \cup { [ZeroLegentrynum EXCEPT !.legsymSymbolnumx = one] : one \in CheckedLegsymSymbolnumx }
        \cup { [ZeroLegentrynum EXCEPT !.legsideUint81 = one] : one \in Sample(1) }
        \cup { [ZeroLegentrynum EXCEPT !.legqtyUint162 = one] : one \in Sample(2) }

(* A run of Legentrynum, written one after another *)
RECURSIVE EncodeLegentrynumList(_)
EncodeLegentrynumList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegentrynum(Head(messages)) \o EncodeLegentrynumList(Tail(messages))

(* As many Legentrynum as the field that counts them says *)
RECURSIVE ReadLegentrynumList(_, _)
ReadLegentrynumList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegentrynum(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegentrynumList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Legentrynum of each kind, for the lists that carry them *)
OneLegentrynum == { ZeroLegentrynum }

(***************************************************************************)
(* Multilegnum                                                             *)
(***************************************************************************)

Multilegnum ==
    [ combop      : Sample(1),
      legentrynum : SampleLists(OneLegentrynum) ]

EncodeMultilegnum(message) ==
    EncodeUIntBE(Len(message.legentrynum), 1)
        \o message.combop
        \o EncodeLegentrynumList(message.legentrynum)

DecodeMultilegnum(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combop == ReadBytes(noLeg.rest, 1) IN IF ~combop.ok THEN Fail ELSE
    LET legentrynum == ReadLegentrynumList(combop.rest, noLeg.value) IN IF ~legentrynum.ok THEN Fail ELSE
    Ok([ combop      |-> combop.value,
         legentrynum |-> legentrynum.value ], legentrynum.rest)

ZeroMultilegnum ==
    [ combop      |-> [i \in 1 .. 1 |-> 0],
      legentrynum |-> << >> ]

(* Multilegnum at zero, then each field in turn at the values it is checked at *)
CheckedMultilegnum ==
    { ZeroMultilegnum }
        \cup { [ZeroMultilegnum EXCEPT !.combop = one] : one \in Sample(1) }
        \cup { [ZeroMultilegnum EXCEPT !.legentrynum = one] : one \in SampleLists(OneLegentrynum) }

(***************************************************************************)
(* Legsym Symboltxtx: 20 bytes                                             *)
(***************************************************************************)

LegsymSymboltxtx ==
    [ prodid : Sample(20) ]

EncodeLegsymSymboltxtx(message) ==
    message.prodid

DecodeLegsymSymboltxtx(bytes) ==
    LET prodid == ReadBytes(bytes, 20) IN IF ~prodid.ok THEN Fail ELSE
    Ok([ prodid |-> prodid.value ], prodid.rest)

ZeroLegsymSymboltxtx ==
    [ prodid |-> [i \in 1 .. 20 |-> 0] ]

(* Legsym Symboltxtx at zero, then each field in turn at the values it is checked at *)
CheckedLegsymSymboltxtx ==
    { ZeroLegsymSymboltxtx }
        \cup { [ZeroLegsymSymboltxtx EXCEPT !.prodid = one] : one \in Sample(20) }

(***************************************************************************)
(* Legentrytxt: 23 bytes                                                   *)
(***************************************************************************)

Legentrytxt ==
    [ legsymSymboltxtx : LegsymSymboltxtx,
      legsideUint81    : Sample(1),
      legqtyUint162    : Sample(2) ]

EncodeLegentrytxt(message) ==
    EncodeLegsymSymboltxtx(message.legsymSymboltxtx)
        \o message.legsideUint81
        \o message.legqtyUint162

DecodeLegentrytxt(bytes) ==
    LET legsymSymboltxtx == DecodeLegsymSymboltxtx(bytes) IN IF ~legsymSymboltxtx.ok THEN Fail ELSE
    LET legsideUint81 == ReadBytes(legsymSymboltxtx.rest, 1) IN IF ~legsideUint81.ok THEN Fail ELSE
    LET legqtyUint162 == ReadBytes(legsideUint81.rest, 2) IN IF ~legqtyUint162.ok THEN Fail ELSE
    Ok([ legsymSymboltxtx |-> legsymSymboltxtx.value,
         legsideUint81    |-> legsideUint81.value,
         legqtyUint162    |-> legqtyUint162.value ], legqtyUint162.rest)

ZeroLegentrytxt ==
    [ legsymSymboltxtx |-> ZeroLegsymSymboltxtx,
      legsideUint81    |-> [i \in 1 .. 1 |-> 0],
      legqtyUint162    |-> [i \in 1 .. 2 |-> 0] ]

(* Legentrytxt at zero, then each field in turn at the values it is checked at *)
CheckedLegentrytxt ==
    { ZeroLegentrytxt }
        \cup { [ZeroLegentrytxt EXCEPT !.legsymSymboltxtx = one] : one \in CheckedLegsymSymboltxtx }
        \cup { [ZeroLegentrytxt EXCEPT !.legsideUint81 = one] : one \in Sample(1) }
        \cup { [ZeroLegentrytxt EXCEPT !.legqtyUint162 = one] : one \in Sample(2) }

(* A run of Legentrytxt, written one after another *)
RECURSIVE EncodeLegentrytxtList(_)
EncodeLegentrytxtList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegentrytxt(Head(messages)) \o EncodeLegentrytxtList(Tail(messages))

(* As many Legentrytxt as the field that counts them says *)
RECURSIVE ReadLegentrytxtList(_, _)
ReadLegentrytxtList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegentrytxt(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegentrytxtList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Legentrytxt of each kind, for the lists that carry them *)
OneLegentrytxt == { ZeroLegentrytxt }

(***************************************************************************)
(* Multilegtxt                                                             *)
(***************************************************************************)

Multilegtxt ==
    [ combop      : Sample(1),
      legentrytxt : SampleLists(OneLegentrytxt) ]

EncodeMultilegtxt(message) ==
    EncodeUIntBE(Len(message.legentrytxt), 1)
        \o message.combop
        \o EncodeLegentrytxtList(message.legentrytxt)

DecodeMultilegtxt(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combop == ReadBytes(noLeg.rest, 1) IN IF ~combop.ok THEN Fail ELSE
    LET legentrytxt == ReadLegentrytxtList(combop.rest, noLeg.value) IN IF ~legentrytxt.ok THEN Fail ELSE
    Ok([ combop      |-> combop.value,
         legentrytxt |-> legentrytxt.value ], legentrytxt.rest)

ZeroMultilegtxt ==
    [ combop      |-> [i \in 1 .. 1 |-> 0],
      legentrytxt |-> << >> ]

(* Multilegtxt at zero, then each field in turn at the values it is checked at *)
CheckedMultilegtxt ==
    { ZeroMultilegtxt }
        \cup { [ZeroMultilegtxt EXCEPT !.combop = one] : one \in Sample(1) }
        \cup { [ZeroMultilegtxt EXCEPT !.legentrytxt = one] : one \in SampleLists(OneLegentrytxt) }

(***************************************************************************)
(* Sym Flexproductx, selected by Msg Type Ext                              *)
(***************************************************************************)

SymbolnumxCode == 1  \* 0x01
SymboltxtxCode == 2  \* 0x02
MultilegnumCode == 3  \* 0x03
MultilegtxtCode == 4  \* 0x04

SymFlexproductx ==
    [ tag : {SymbolnumxCode}, body : Symbolnumx ]
        \cup [ tag : {SymboltxtxCode}, body : Symboltxtx ]
        \cup [ tag : {MultilegnumCode}, body : Multilegnum ]
        \cup [ tag : {MultilegtxtCode}, body : Multilegtxt ]

EncodeSymFlexproductx(message) ==
    CASE message.tag = SymbolnumxCode -> EncodeSymbolnumx(message.body)
      [] message.tag = SymboltxtxCode -> EncodeSymboltxtx(message.body)
      [] message.tag = MultilegnumCode -> EncodeMultilegnum(message.body)
      [] message.tag = MultilegtxtCode -> EncodeMultilegtxt(message.body)

DecodeSymFlexproductx(tag, bytes) ==
    LET read ==
            CASE tag = SymbolnumxCode -> DecodeSymbolnumx(bytes)
              [] tag = SymboltxtxCode -> DecodeSymboltxtx(bytes)
              [] tag = MultilegnumCode -> DecodeMultilegnum(bytes)
              [] tag = MultilegtxtCode -> DecodeMultilegtxt(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymFlexproductx == [tag |-> SymbolnumxCode, body |-> ZeroSymbolnumx]

(* Each Sym Flexproductx in turn, at the values the message it names is checked at *)
CheckedSymFlexproductx ==
    { [tag |-> SymbolnumxCode, body |-> one] : one \in CheckedSymbolnumx }
        \cup { [tag |-> SymboltxtxCode, body |-> one] : one \in CheckedSymboltxtx }
        \cup { [tag |-> MultilegnumCode, body |-> one] : one \in CheckedMultilegnum }
        \cup { [tag |-> MultilegtxtCode, body |-> one] : one \in CheckedMultilegtxt }

(***************************************************************************)
(* Orgtranstime Msgtimex: 8 bytes                                          *)
(***************************************************************************)

OrgtranstimeMsgtimex ==
    [ epochsUint324 : Sample(4),
      nanosecond    : Sample(4) ]

EncodeOrgtranstimeMsgtimex(message) ==
    message.epochsUint324
        \o message.nanosecond

DecodeOrgtranstimeMsgtimex(bytes) ==
    LET epochsUint324 == ReadBytes(bytes, 4) IN IF ~epochsUint324.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(epochsUint324.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ epochsUint324 |-> epochsUint324.value,
         nanosecond    |-> nanosecond.value ], nanosecond.rest)

ZeroOrgtranstimeMsgtimex ==
    [ epochsUint324 |-> [i \in 1 .. 4 |-> 0],
      nanosecond    |-> [i \in 1 .. 4 |-> 0] ]

(* Orgtranstime Msgtimex at zero, then each field in turn at the values it is checked at *)
CheckedOrgtranstimeMsgtimex ==
    { ZeroOrgtranstimeMsgtimex }
        \cup { [ZeroOrgtranstimeMsgtimex EXCEPT !.epochsUint324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgtranstimeMsgtimex EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Transact Time Msgtimex: 8 bytes                                         *)
(***************************************************************************)

TransactTimeMsgtimex ==
    [ epochsUint324 : Sample(4),
      nanosecond    : Sample(4) ]

EncodeTransactTimeMsgtimex(message) ==
    message.epochsUint324
        \o message.nanosecond

DecodeTransactTimeMsgtimex(bytes) ==
    LET epochsUint324 == ReadBytes(bytes, 4) IN IF ~epochsUint324.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(epochsUint324.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ epochsUint324 |-> epochsUint324.value,
         nanosecond    |-> nanosecond.value ], nanosecond.rest)

ZeroTransactTimeMsgtimex ==
    [ epochsUint324 |-> [i \in 1 .. 4 |-> 0],
      nanosecond    |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time Msgtimex at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgtimex ==
    { ZeroTransactTimeMsgtimex }
        \cup { [ZeroTransactTimeMsgtimex EXCEPT !.epochsUint324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgtimex EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Order Status Report Message                                        *)
(***************************************************************************)

FlexOrderStatusReportMessage ==
    [ preserve             : Sample(1),
      msgtimens            : Sample(4),
      partid               : Sample(1),
      noLeg                : Sample(1),
      statuscodeUint162    : Sample(2),
      execType             : Sample(1),
      cmid                 : Sample(2),
      fcmid                : Sample(2),
      orderno              : Sample(5),
      ordid                : Sample(4),
      userdefine           : Sample(8),
      symFlexproductx      : SymFlexproductx,
      price                : Sample(4),
      qty                  : Sample(2),
      investoracno         : Sample(4),
      investorflag         : Sample(1),
      side                 : Sample(1),
      ordType              : Sample(1),
      timeInForce          : Sample(1),
      positionEffect       : Sample(1),
      lastPx               : Sample(4),
      lastQty              : Sample(2),
      pxsubtotal           : Sample(8),
      cumQty               : Sample(2),
      leavesQty            : Sample(2),
      beforeqty            : Sample(2),
      orgtranstimeMsgtimex : OrgtranstimeMsgtimex,
      transactTimeMsgtimex : TransactTimeMsgtimex,
      targetid             : Sample(1),
      uniqid               : Sample(4),
      rptseq               : Sample(4),
      rptsessionid         : Sample(2),
      rptsessionseq        : Sample(4),
      reserved12           : Sample(12) ]

EncodeFlexOrderStatusReportMessage(message) ==
    EncodeUIntBE(message.symFlexproductx.tag, 1)
        \o message.preserve
        \o message.msgtimens
        \o message.partid
        \o message.noLeg
        \o message.statuscodeUint162
        \o message.execType
        \o message.cmid
        \o message.fcmid
        \o message.orderno
        \o message.ordid
        \o message.userdefine
        \o EncodeSymFlexproductx(message.symFlexproductx)
        \o message.price
        \o message.qty
        \o message.investoracno
        \o message.investorflag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxsubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeqty
        \o EncodeOrgtranstimeMsgtimex(message.orgtranstimeMsgtimex)
        \o EncodeTransactTimeMsgtimex(message.transactTimeMsgtimex)
        \o message.targetid
        \o message.uniqid
        \o message.rptseq
        \o message.rptsessionid
        \o message.rptsessionseq
        \o message.reserved12

DecodeFlexOrderStatusReportMessage(bytes) ==
    LET msgTypeExt == ReadUIntBE(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgtimens == ReadBytes(preserve.rest, 4) IN IF ~msgtimens.ok THEN Fail ELSE
    LET partid == ReadBytes(msgtimens.rest, 1) IN IF ~partid.ok THEN Fail ELSE
    LET noLeg == ReadBytes(partid.rest, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET statuscodeUint162 == ReadBytes(noLeg.rest, 2) IN IF ~statuscodeUint162.ok THEN Fail ELSE
    LET execType == ReadBytes(statuscodeUint162.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmid == ReadBytes(execType.rest, 2) IN IF ~cmid.ok THEN Fail ELSE
    LET fcmid == ReadBytes(cmid.rest, 2) IN IF ~fcmid.ok THEN Fail ELSE
    LET orderno == ReadBytes(fcmid.rest, 5) IN IF ~orderno.ok THEN Fail ELSE
    LET ordid == ReadBytes(orderno.rest, 4) IN IF ~ordid.ok THEN Fail ELSE
    LET userdefine == ReadBytes(ordid.rest, 8) IN IF ~userdefine.ok THEN Fail ELSE
    LET symFlexproductx == DecodeSymFlexproductx(msgTypeExt.value, userdefine.rest) IN IF ~symFlexproductx.ok THEN Fail ELSE
    LET price == ReadBytes(symFlexproductx.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investoracno == ReadBytes(qty.rest, 4) IN IF ~investoracno.ok THEN Fail ELSE
    LET investorflag == ReadBytes(investoracno.rest, 1) IN IF ~investorflag.ok THEN Fail ELSE
    LET side == ReadBytes(investorflag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxsubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxsubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxsubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeqty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeqty.ok THEN Fail ELSE
    LET orgtranstimeMsgtimex == DecodeOrgtranstimeMsgtimex(beforeqty.rest) IN IF ~orgtranstimeMsgtimex.ok THEN Fail ELSE
    LET transactTimeMsgtimex == DecodeTransactTimeMsgtimex(orgtranstimeMsgtimex.rest) IN IF ~transactTimeMsgtimex.ok THEN Fail ELSE
    LET targetid == ReadBytes(transactTimeMsgtimex.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET uniqid == ReadBytes(targetid.rest, 4) IN IF ~uniqid.ok THEN Fail ELSE
    LET rptseq == ReadBytes(uniqid.rest, 4) IN IF ~rptseq.ok THEN Fail ELSE
    LET rptsessionid == ReadBytes(rptseq.rest, 2) IN IF ~rptsessionid.ok THEN Fail ELSE
    LET rptsessionseq == ReadBytes(rptsessionid.rest, 4) IN IF ~rptsessionseq.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(rptsessionseq.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ preserve             |-> preserve.value,
         msgtimens            |-> msgtimens.value,
         partid               |-> partid.value,
         noLeg                |-> noLeg.value,
         statuscodeUint162    |-> statuscodeUint162.value,
         execType             |-> execType.value,
         cmid                 |-> cmid.value,
         fcmid                |-> fcmid.value,
         orderno              |-> orderno.value,
         ordid                |-> ordid.value,
         userdefine           |-> userdefine.value,
         symFlexproductx      |-> symFlexproductx.value,
         price                |-> price.value,
         qty                  |-> qty.value,
         investoracno         |-> investoracno.value,
         investorflag         |-> investorflag.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         timeInForce          |-> timeInForce.value,
         positionEffect       |-> positionEffect.value,
         lastPx               |-> lastPx.value,
         lastQty              |-> lastQty.value,
         pxsubtotal           |-> pxsubtotal.value,
         cumQty               |-> cumQty.value,
         leavesQty            |-> leavesQty.value,
         beforeqty            |-> beforeqty.value,
         orgtranstimeMsgtimex |-> orgtranstimeMsgtimex.value,
         transactTimeMsgtimex |-> transactTimeMsgtimex.value,
         targetid             |-> targetid.value,
         uniqid               |-> uniqid.value,
         rptseq               |-> rptseq.value,
         rptsessionid         |-> rptsessionid.value,
         rptsessionseq        |-> rptsessionseq.value,
         reserved12           |-> reserved12.value ], reserved12.rest)

ZeroFlexOrderStatusReportMessage ==
    [ preserve             |-> [i \in 1 .. 1 |-> 0],
      msgtimens            |-> [i \in 1 .. 4 |-> 0],
      partid               |-> [i \in 1 .. 1 |-> 0],
      noLeg                |-> [i \in 1 .. 1 |-> 0],
      statuscodeUint162    |-> [i \in 1 .. 2 |-> 0],
      execType             |-> [i \in 1 .. 1 |-> 0],
      cmid                 |-> [i \in 1 .. 2 |-> 0],
      fcmid                |-> [i \in 1 .. 2 |-> 0],
      orderno              |-> [i \in 1 .. 5 |-> 0],
      ordid                |-> [i \in 1 .. 4 |-> 0],
      userdefine           |-> [i \in 1 .. 8 |-> 0],
      symFlexproductx      |-> ZeroSymFlexproductx,
      price                |-> [i \in 1 .. 4 |-> 0],
      qty                  |-> [i \in 1 .. 2 |-> 0],
      investoracno         |-> [i \in 1 .. 4 |-> 0],
      investorflag         |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      positionEffect       |-> [i \in 1 .. 1 |-> 0],
      lastPx               |-> [i \in 1 .. 4 |-> 0],
      lastQty              |-> [i \in 1 .. 2 |-> 0],
      pxsubtotal           |-> [i \in 1 .. 8 |-> 0],
      cumQty               |-> [i \in 1 .. 2 |-> 0],
      leavesQty            |-> [i \in 1 .. 2 |-> 0],
      beforeqty            |-> [i \in 1 .. 2 |-> 0],
      orgtranstimeMsgtimex |-> ZeroOrgtranstimeMsgtimex,
      transactTimeMsgtimex |-> ZeroTransactTimeMsgtimex,
      targetid             |-> [i \in 1 .. 1 |-> 0],
      uniqid               |-> [i \in 1 .. 4 |-> 0],
      rptseq               |-> [i \in 1 .. 4 |-> 0],
      rptsessionid         |-> [i \in 1 .. 2 |-> 0],
      rptsessionseq        |-> [i \in 1 .. 4 |-> 0],
      reserved12           |-> [i \in 1 .. 12 |-> 0] ]

(* Flex Order Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexOrderStatusReportMessage ==
    { ZeroFlexOrderStatusReportMessage }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.msgtimens = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.partid = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.noLeg = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.statuscodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.cmid = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.fcmid = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.orderno = one] : one \in Sample(5) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.ordid = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.userdefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.symFlexproductx = one] : one \in CheckedSymFlexproductx }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.investoracno = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.investorflag = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.pxsubtotal = one] : one \in Sample(8) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.beforeqty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.orgtranstimeMsgtimex = one] : one \in CheckedOrgtranstimeMsgtimex }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.transactTimeMsgtimex = one] : one \in CheckedTransactTimeMsgtimex }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.uniqid = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.rptseq = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.rptsessionid = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.rptsessionseq = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Clearing Member Initiate Operation Message: 7 bytes                     *)
(***************************************************************************)

ClearingMemberInitiateOperationMessage ==
    [ memberid : Sample(2),
      targetid : Sample(1),
      reqcmseq : Sample(4) ]

EncodeClearingMemberInitiateOperationMessage(message) ==
    message.memberid
        \o message.targetid
        \o message.reqcmseq

DecodeClearingMemberInitiateOperationMessage(bytes) ==
    LET memberid == ReadBytes(bytes, 2) IN IF ~memberid.ok THEN Fail ELSE
    LET targetid == ReadBytes(memberid.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET reqcmseq == ReadBytes(targetid.rest, 4) IN IF ~reqcmseq.ok THEN Fail ELSE
    Ok([ memberid |-> memberid.value,
         targetid |-> targetid.value,
         reqcmseq |-> reqcmseq.value ], reqcmseq.rest)

ZeroClearingMemberInitiateOperationMessage ==
    [ memberid |-> [i \in 1 .. 2 |-> 0],
      targetid |-> [i \in 1 .. 1 |-> 0],
      reqcmseq |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Member Initiate Operation Message at zero, then each field in turn at the values it is checked at *)
CheckedClearingMemberInitiateOperationMessage ==
    { ZeroClearingMemberInitiateOperationMessage }
        \cup { [ZeroClearingMemberInitiateOperationMessage EXCEPT !.memberid = one] : one \in Sample(2) }
        \cup { [ZeroClearingMemberInitiateOperationMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroClearingMemberInitiateOperationMessage EXCEPT !.reqcmseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Member Initiate Operation Confirmed Message: 8 bytes           *)
(***************************************************************************)

ClearingMemberInitiateOperationConfirmedMessage ==
    [ statuscodeUint81 : Sample(1),
      memberid         : Sample(2),
      targetid         : Sample(1),
      reqcmseq         : Sample(4) ]

EncodeClearingMemberInitiateOperationConfirmedMessage(message) ==
    message.statuscodeUint81
        \o message.memberid
        \o message.targetid
        \o message.reqcmseq

DecodeClearingMemberInitiateOperationConfirmedMessage(bytes) ==
    LET statuscodeUint81 == ReadBytes(bytes, 1) IN IF ~statuscodeUint81.ok THEN Fail ELSE
    LET memberid == ReadBytes(statuscodeUint81.rest, 2) IN IF ~memberid.ok THEN Fail ELSE
    LET targetid == ReadBytes(memberid.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET reqcmseq == ReadBytes(targetid.rest, 4) IN IF ~reqcmseq.ok THEN Fail ELSE
    Ok([ statuscodeUint81 |-> statuscodeUint81.value,
         memberid         |-> memberid.value,
         targetid         |-> targetid.value,
         reqcmseq         |-> reqcmseq.value ], reqcmseq.rest)

ZeroClearingMemberInitiateOperationConfirmedMessage ==
    [ statuscodeUint81 |-> [i \in 1 .. 1 |-> 0],
      memberid         |-> [i \in 1 .. 2 |-> 0],
      targetid         |-> [i \in 1 .. 1 |-> 0],
      reqcmseq         |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Member Initiate Operation Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedClearingMemberInitiateOperationConfirmedMessage ==
    { ZeroClearingMemberInitiateOperationConfirmedMessage }
        \cup { [ZeroClearingMemberInitiateOperationConfirmedMessage EXCEPT !.statuscodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroClearingMemberInitiateOperationConfirmedMessage EXCEPT !.memberid = one] : one \in Sample(2) }
        \cup { [ZeroClearingMemberInitiateOperationConfirmedMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroClearingMemberInitiateOperationConfirmedMessage EXCEPT !.reqcmseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Subhdr: 6 bytes                                                         *)
(***************************************************************************)

Subhdr2 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgtimens  : Sample(4) ]

EncodeSubhdr2(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgtimens

DecodeSubhdr2(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgtimens == ReadBytes(preserve.rest, 4) IN IF ~msgtimens.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgtimens  |-> msgtimens.value ], msgtimens.rest)

ZeroSubhdr2 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgtimens  |-> [i \in 1 .. 4 |-> 0] ]

(* Subhdr at zero, then each field in turn at the values it is checked at *)
CheckedSubhdr2 ==
    { ZeroSubhdr2 }
        \cup { [ZeroSubhdr2 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubhdr2 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubhdr2 EXCEPT !.msgtimens = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Clearing Member Initiate Operation Message: 14 bytes               *)
(***************************************************************************)

FlexClearingMemberInitiateOperationMessage ==
    [ subhdr   : Subhdr2,
      partid   : Sample(1),
      memberid : Sample(2),
      targetid : Sample(1),
      reqcmseq : Sample(4) ]

EncodeFlexClearingMemberInitiateOperationMessage(message) ==
    EncodeSubhdr2(message.subhdr)
        \o message.partid
        \o message.memberid
        \o message.targetid
        \o message.reqcmseq

DecodeFlexClearingMemberInitiateOperationMessage(bytes) ==
    LET subhdr == DecodeSubhdr2(bytes) IN IF ~subhdr.ok THEN Fail ELSE
    LET partid == ReadBytes(subhdr.rest, 1) IN IF ~partid.ok THEN Fail ELSE
    LET memberid == ReadBytes(partid.rest, 2) IN IF ~memberid.ok THEN Fail ELSE
    LET targetid == ReadBytes(memberid.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET reqcmseq == ReadBytes(targetid.rest, 4) IN IF ~reqcmseq.ok THEN Fail ELSE
    Ok([ subhdr   |-> subhdr.value,
         partid   |-> partid.value,
         memberid |-> memberid.value,
         targetid |-> targetid.value,
         reqcmseq |-> reqcmseq.value ], reqcmseq.rest)

ZeroFlexClearingMemberInitiateOperationMessage ==
    [ subhdr   |-> ZeroSubhdr2,
      partid   |-> [i \in 1 .. 1 |-> 0],
      memberid |-> [i \in 1 .. 2 |-> 0],
      targetid |-> [i \in 1 .. 1 |-> 0],
      reqcmseq |-> [i \in 1 .. 4 |-> 0] ]

(* Flex Clearing Member Initiate Operation Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexClearingMemberInitiateOperationMessage ==
    { ZeroFlexClearingMemberInitiateOperationMessage }
        \cup { [ZeroFlexClearingMemberInitiateOperationMessage EXCEPT !.subhdr = one] : one \in CheckedSubhdr2 }
        \cup { [ZeroFlexClearingMemberInitiateOperationMessage EXCEPT !.partid = one] : one \in Sample(1) }
        \cup { [ZeroFlexClearingMemberInitiateOperationMessage EXCEPT !.memberid = one] : one \in Sample(2) }
        \cup { [ZeroFlexClearingMemberInitiateOperationMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroFlexClearingMemberInitiateOperationMessage EXCEPT !.reqcmseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Subhdr: 6 bytes                                                         *)
(***************************************************************************)

Subhdr3 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgtimens  : Sample(4) ]

EncodeSubhdr3(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgtimens

DecodeSubhdr3(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgtimens == ReadBytes(preserve.rest, 4) IN IF ~msgtimens.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgtimens  |-> msgtimens.value ], msgtimens.rest)

ZeroSubhdr3 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgtimens  |-> [i \in 1 .. 4 |-> 0] ]

(* Subhdr at zero, then each field in turn at the values it is checked at *)
CheckedSubhdr3 ==
    { ZeroSubhdr3 }
        \cup { [ZeroSubhdr3 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubhdr3 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubhdr3 EXCEPT !.msgtimens = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Clearing Member Initiate Operation Confirmed Message: 32 bytes     *)
(***************************************************************************)

FlexClearingMemberInitiateOperationConfirmedMessage ==
    [ subhdr            : Subhdr3,
      partid            : Sample(1),
      statuscodeUint162 : Sample(2),
      memberid          : Sample(2),
      targetid          : Sample(1),
      reqcmseq          : Sample(4),
      reserved16        : Sample(16) ]

EncodeFlexClearingMemberInitiateOperationConfirmedMessage(message) ==
    EncodeSubhdr3(message.subhdr)
        \o message.partid
        \o message.statuscodeUint162
        \o message.memberid
        \o message.targetid
        \o message.reqcmseq
        \o message.reserved16

DecodeFlexClearingMemberInitiateOperationConfirmedMessage(bytes) ==
    LET subhdr == DecodeSubhdr3(bytes) IN IF ~subhdr.ok THEN Fail ELSE
    LET partid == ReadBytes(subhdr.rest, 1) IN IF ~partid.ok THEN Fail ELSE
    LET statuscodeUint162 == ReadBytes(partid.rest, 2) IN IF ~statuscodeUint162.ok THEN Fail ELSE
    LET memberid == ReadBytes(statuscodeUint162.rest, 2) IN IF ~memberid.ok THEN Fail ELSE
    LET targetid == ReadBytes(memberid.rest, 1) IN IF ~targetid.ok THEN Fail ELSE
    LET reqcmseq == ReadBytes(targetid.rest, 4) IN IF ~reqcmseq.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(reqcmseq.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ subhdr            |-> subhdr.value,
         partid            |-> partid.value,
         statuscodeUint162 |-> statuscodeUint162.value,
         memberid          |-> memberid.value,
         targetid          |-> targetid.value,
         reqcmseq          |-> reqcmseq.value,
         reserved16        |-> reserved16.value ], reserved16.rest)

ZeroFlexClearingMemberInitiateOperationConfirmedMessage ==
    [ subhdr            |-> ZeroSubhdr3,
      partid            |-> [i \in 1 .. 1 |-> 0],
      statuscodeUint162 |-> [i \in 1 .. 2 |-> 0],
      memberid          |-> [i \in 1 .. 2 |-> 0],
      targetid          |-> [i \in 1 .. 1 |-> 0],
      reqcmseq          |-> [i \in 1 .. 4 |-> 0],
      reserved16        |-> [i \in 1 .. 16 |-> 0] ]

(* Flex Clearing Member Initiate Operation Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexClearingMemberInitiateOperationConfirmedMessage ==
    { ZeroFlexClearingMemberInitiateOperationConfirmedMessage }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.subhdr = one] : one \in CheckedSubhdr3 }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.partid = one] : one \in Sample(1) }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.statuscodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.memberid = one] : one \in Sample(2) }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.targetid = one] : one \in Sample(1) }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.reqcmseq = one] : one \in Sample(4) }
        \cup { [ZeroFlexClearingMemberInitiateOperationConfirmedMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

WakeUpCallMessageCode == 10  \* 0x0a
WakeUpCallConfirmedMessageCode == 20  \* 0x14
LogonNoticeMessageCode == 30  \* 0x1e
FinalSequentialNumberNotificationForGroupMessageCode == 230  \* 0xe6
RequestLogonMessageCode == 40  \* 0x28
ActivateApplicationSystemMessageCode == 50  \* 0x32
ActivateApplicationSystemConfirmedMessageCode == 60  \* 0x3c
LogoutMessageCode == 70  \* 0x46
LogoutConfirmedMessageCode == 80  \* 0x50
ConfirmConnectionMessageCode == 104  \* 0x68
ConnectionConfirmedMessageCode == 105  \* 0x69
OrderStatusReportMessageCode == 102  \* 0x66
OrderStatusReportLongFormatMessageCode == 132  \* 0x84
ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode == 106  \* 0x6a
FlexOrderStatusReportMessageCode == 202  \* 0xca
ClearingMemberInitiateOperationMessageCode == 115  \* 0x73
ClearingMemberInitiateOperationConfirmedMessageCode == 116  \* 0x74
FlexClearingMemberInitiateOperationMessageCode == 215  \* 0xd7
FlexClearingMemberInitiateOperationConfirmedMessageCode == 216  \* 0xd8

Payload ==
    [ tag : {WakeUpCallMessageCode}, body : WakeUpCallMessage ]
        \cup [ tag : {WakeUpCallConfirmedMessageCode}, body : WakeUpCallConfirmedMessage ]
        \cup [ tag : {LogonNoticeMessageCode}, body : LogonNoticeMessage ]
        \cup [ tag : {FinalSequentialNumberNotificationForGroupMessageCode}, body : FinalSequentialNumberNotificationForGroupMessage ]
        \cup [ tag : {RequestLogonMessageCode}, body : RequestLogonMessage ]
        \cup [ tag : {ActivateApplicationSystemMessageCode}, body : ActivateApplicationSystemMessage ]
        \cup [ tag : {ActivateApplicationSystemConfirmedMessageCode}, body : ActivateApplicationSystemConfirmedMessage ]
        \cup [ tag : {LogoutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutConfirmedMessageCode}, body : LogoutConfirmedMessage ]
        \cup [ tag : {ConfirmConnectionMessageCode}, body : ConfirmConnectionMessage ]
        \cup [ tag : {ConnectionConfirmedMessageCode}, body : ConnectionConfirmedMessage ]
        \cup [ tag : {OrderStatusReportMessageCode}, body : OrderStatusReportMessage ]
        \cup [ tag : {OrderStatusReportLongFormatMessageCode}, body : OrderStatusReportLongFormatMessage ]
        \cup [ tag : {ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode}, body : ExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ]
        \cup [ tag : {FlexOrderStatusReportMessageCode}, body : FlexOrderStatusReportMessage ]
        \cup [ tag : {ClearingMemberInitiateOperationMessageCode}, body : ClearingMemberInitiateOperationMessage ]
        \cup [ tag : {ClearingMemberInitiateOperationConfirmedMessageCode}, body : ClearingMemberInitiateOperationConfirmedMessage ]
        \cup [ tag : {FlexClearingMemberInitiateOperationMessageCode}, body : FlexClearingMemberInitiateOperationMessage ]
        \cup [ tag : {FlexClearingMemberInitiateOperationConfirmedMessageCode}, body : FlexClearingMemberInitiateOperationConfirmedMessage ]

EncodePayload(message) ==
    CASE message.tag = WakeUpCallMessageCode -> EncodeWakeUpCallMessage(message.body)
      [] message.tag = WakeUpCallConfirmedMessageCode -> EncodeWakeUpCallConfirmedMessage(message.body)
      [] message.tag = LogonNoticeMessageCode -> EncodeLogonNoticeMessage(message.body)
      [] message.tag = FinalSequentialNumberNotificationForGroupMessageCode -> EncodeFinalSequentialNumberNotificationForGroupMessage(message.body)
      [] message.tag = RequestLogonMessageCode -> EncodeRequestLogonMessage(message.body)
      [] message.tag = ActivateApplicationSystemMessageCode -> EncodeActivateApplicationSystemMessage(message.body)
      [] message.tag = ActivateApplicationSystemConfirmedMessageCode -> EncodeActivateApplicationSystemConfirmedMessage(message.body)
      [] message.tag = LogoutMessageCode -> << >>
      [] message.tag = LogoutConfirmedMessageCode -> EncodeLogoutConfirmedMessage(message.body)
      [] message.tag = ConfirmConnectionMessageCode -> EncodeConfirmConnectionMessage(message.body)
      [] message.tag = ConnectionConfirmedMessageCode -> EncodeConnectionConfirmedMessage(message.body)
      [] message.tag = OrderStatusReportMessageCode -> EncodeOrderStatusReportMessage(message.body)
      [] message.tag = OrderStatusReportLongFormatMessageCode -> EncodeOrderStatusReportLongFormatMessage(message.body)
      [] message.tag = ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode -> EncodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(message.body)
      [] message.tag = FlexOrderStatusReportMessageCode -> EncodeFlexOrderStatusReportMessage(message.body)
      [] message.tag = ClearingMemberInitiateOperationMessageCode -> EncodeClearingMemberInitiateOperationMessage(message.body)
      [] message.tag = ClearingMemberInitiateOperationConfirmedMessageCode -> EncodeClearingMemberInitiateOperationConfirmedMessage(message.body)
      [] message.tag = FlexClearingMemberInitiateOperationMessageCode -> EncodeFlexClearingMemberInitiateOperationMessage(message.body)
      [] message.tag = FlexClearingMemberInitiateOperationConfirmedMessageCode -> EncodeFlexClearingMemberInitiateOperationConfirmedMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = WakeUpCallMessageCode -> DecodeWakeUpCallMessage(bytes)
              [] tag = WakeUpCallConfirmedMessageCode -> DecodeWakeUpCallConfirmedMessage(bytes)
              [] tag = LogonNoticeMessageCode -> DecodeLogonNoticeMessage(bytes)
              [] tag = FinalSequentialNumberNotificationForGroupMessageCode -> DecodeFinalSequentialNumberNotificationForGroupMessage(bytes)
              [] tag = RequestLogonMessageCode -> DecodeRequestLogonMessage(bytes)
              [] tag = ActivateApplicationSystemMessageCode -> DecodeActivateApplicationSystemMessage(bytes)
              [] tag = ActivateApplicationSystemConfirmedMessageCode -> DecodeActivateApplicationSystemConfirmedMessage(bytes)
              [] tag = LogoutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutConfirmedMessageCode -> DecodeLogoutConfirmedMessage(bytes)
              [] tag = ConfirmConnectionMessageCode -> DecodeConfirmConnectionMessage(bytes)
              [] tag = ConnectionConfirmedMessageCode -> DecodeConnectionConfirmedMessage(bytes)
              [] tag = OrderStatusReportMessageCode -> DecodeOrderStatusReportMessage(bytes)
              [] tag = OrderStatusReportLongFormatMessageCode -> DecodeOrderStatusReportLongFormatMessage(bytes)
              [] tag = ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode -> DecodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(bytes)
              [] tag = FlexOrderStatusReportMessageCode -> DecodeFlexOrderStatusReportMessage(bytes)
              [] tag = ClearingMemberInitiateOperationMessageCode -> DecodeClearingMemberInitiateOperationMessage(bytes)
              [] tag = ClearingMemberInitiateOperationConfirmedMessageCode -> DecodeClearingMemberInitiateOperationConfirmedMessage(bytes)
              [] tag = FlexClearingMemberInitiateOperationMessageCode -> DecodeFlexClearingMemberInitiateOperationMessage(bytes)
              [] tag = FlexClearingMemberInitiateOperationConfirmedMessageCode -> DecodeFlexClearingMemberInitiateOperationConfirmedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> WakeUpCallMessageCode, body |-> ZeroWakeUpCallMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> WakeUpCallMessageCode, body |-> one] : one \in CheckedWakeUpCallMessage }
        \cup { [tag |-> WakeUpCallConfirmedMessageCode, body |-> one] : one \in CheckedWakeUpCallConfirmedMessage }
        \cup { [tag |-> LogonNoticeMessageCode, body |-> one] : one \in CheckedLogonNoticeMessage }
        \cup { [tag |-> FinalSequentialNumberNotificationForGroupMessageCode, body |-> one] : one \in CheckedFinalSequentialNumberNotificationForGroupMessage }
        \cup { [tag |-> RequestLogonMessageCode, body |-> one] : one \in CheckedRequestLogonMessage }
        \cup { [tag |-> ActivateApplicationSystemMessageCode, body |-> one] : one \in CheckedActivateApplicationSystemMessage }
        \cup { [tag |-> ActivateApplicationSystemConfirmedMessageCode, body |-> one] : one \in CheckedActivateApplicationSystemConfirmedMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutConfirmedMessageCode, body |-> one] : one \in CheckedLogoutConfirmedMessage }
        \cup { [tag |-> ConfirmConnectionMessageCode, body |-> one] : one \in CheckedConfirmConnectionMessage }
        \cup { [tag |-> ConnectionConfirmedMessageCode, body |-> one] : one \in CheckedConnectionConfirmedMessage }
        \cup { [tag |-> OrderStatusReportMessageCode, body |-> one] : one \in CheckedOrderStatusReportMessage }
        \cup { [tag |-> OrderStatusReportLongFormatMessageCode, body |-> one] : one \in CheckedOrderStatusReportLongFormatMessage }
        \cup { [tag |-> ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode, body |-> one] : one \in CheckedExecutionReportIncludingHeadOfficeAndBranchOfficesMessage }
        \cup { [tag |-> FlexOrderStatusReportMessageCode, body |-> one] : one \in CheckedFlexOrderStatusReportMessage }
        \cup { [tag |-> ClearingMemberInitiateOperationMessageCode, body |-> one] : one \in CheckedClearingMemberInitiateOperationMessage }
        \cup { [tag |-> ClearingMemberInitiateOperationConfirmedMessageCode, body |-> one] : one \in CheckedClearingMemberInitiateOperationConfirmedMessage }
        \cup { [tag |-> FlexClearingMemberInitiateOperationMessageCode, body |-> one] : one \in CheckedFlexClearingMemberInitiateOperationMessage }
        \cup { [tag |-> FlexClearingMemberInitiateOperationConfirmedMessageCode, body |-> one] : one \in CheckedFlexClearingMemberInitiateOperationConfirmedMessage }

(***************************************************************************)
(* Message Tail: 1 bytes                                                   *)
(***************************************************************************)

MessageTail ==
    [ checkSum : Sample(1) ]

EncodeMessageTail(message) ==
    message.checkSum

DecodeMessageTail(bytes) ==
    LET checkSum == ReadBytes(bytes, 1) IN IF ~checkSum.ok THEN Fail ELSE
    Ok([ checkSum |-> checkSum.value ], checkSum.rest)

ZeroMessageTail ==
    [ checkSum |-> [i \in 1 .. 1 |-> 0] ]

(* Message Tail at zero, then each field in turn at the values it is checked at *)
CheckedMessageTail ==
    { ZeroMessageTail }
        \cup { [ZeroMessageTail EXCEPT !.checkSum = one] : one \in Sample(1) }

(***************************************************************************)
(* Tmp Message, framed by Msg Length                                       *)
(***************************************************************************)

TmpMessage ==
    [ msgSeqNum   : Sample(4),
      headerTime  : HeaderTime,
      fcmid       : Sample(2),
      sessionid   : Sample(2),
      payload     : Payload,
      messageTail : MessageTail ]

EncodeTmpMessageBody(message) ==
    message.msgSeqNum
        \o EncodeHeaderTime(message.headerTime)
        \o EncodeUIntBE(message.payload.tag, 1)
        \o message.fcmid
        \o message.sessionid
        \o EncodePayload(message.payload)
        \o EncodeMessageTail(message.messageTail)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeTmpMessage(message) ==
    LET body == EncodeTmpMessageBody(message)
    IN  EncodeUIntBE(Len(body) - 1, 2) \o body

DecodeTmpMessageBody(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET headerTime == DecodeHeaderTime(msgSeqNum.rest) IN IF ~headerTime.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(headerTime.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET fcmid == ReadBytes(messageType.rest, 2) IN IF ~fcmid.ok THEN Fail ELSE
    LET sessionid == ReadBytes(fcmid.rest, 2) IN IF ~sessionid.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, sessionid.rest) IN IF ~payload.ok THEN Fail ELSE
    LET messageTail == DecodeMessageTail(payload.rest) IN IF ~messageTail.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         headerTime  |-> headerTime.value,
         fcmid       |-> fcmid.value,
         sessionid   |-> sessionid.value,
         payload     |-> payload.value,
         messageTail |-> messageTail.value ], messageTail.rest)

DecodeTmpMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTmpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTmpMessage ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      headerTime  |-> ZeroHeaderTime,
      fcmid       |-> [i \in 1 .. 2 |-> 0],
      sessionid   |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload,
      messageTail |-> ZeroMessageTail ]

(* Tmp Message at zero, then each field in turn at the values it is checked at *)
CheckedTmpMessage ==
    { ZeroTmpMessage }
        \cup { [ZeroTmpMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTmpMessage EXCEPT !.headerTime = one] : one \in CheckedHeaderTime }
        \cup { [ZeroTmpMessage EXCEPT !.fcmid = one] : one \in Sample(2) }
        \cup { [ZeroTmpMessage EXCEPT !.sessionid = one] : one \in Sample(2) }
        \cup { [ZeroTmpMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroTmpMessage EXCEPT !.messageTail = one] : one \in CheckedMessageTail }

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

(* Every Header Time decodes back to what was encoded, and leaves nothing over *)
RoundTripHeaderTime ==
    \A message \in CheckedHeaderTime :
        LET read == DecodeHeaderTime(EncodeHeaderTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wake Up Call Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWakeUpCallMessage ==
    \A message \in CheckedWakeUpCallMessage :
        LET read == DecodeWakeUpCallMessage(EncodeWakeUpCallMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wake Up Call Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWakeUpCallConfirmedMessage ==
    \A message \in CheckedWakeUpCallConfirmedMessage :
        LET read == DecodeWakeUpCallConfirmedMessage(EncodeWakeUpCallConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Notice Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonNoticeMessage ==
    \A message \in CheckedLogonNoticeMessage :
        LET read == DecodeLogonNoticeMessage(EncodeLogonNoticeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subhdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubhdr ==
    \A message \in CheckedSubhdr :
        LET read == DecodeSubhdr(EncodeSubhdr(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Final Sequential Number Notification For Group Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinalSequentialNumberNotificationForGroupMessage ==
    \A message \in CheckedFinalSequentialNumberNotificationForGroupMessage :
        LET read == DecodeFinalSequentialNumberNotificationForGroupMessage(EncodeFinalSequentialNumberNotificationForGroupMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestLogonMessage ==
    \A message \in CheckedRequestLogonMessage :
        LET read == DecodeRequestLogonMessage(EncodeRequestLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Activate Application System Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActivateApplicationSystemMessage ==
    \A message \in CheckedActivateApplicationSystemMessage :
        LET read == DecodeActivateApplicationSystemMessage(EncodeActivateApplicationSystemMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Activate Application System Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActivateApplicationSystemConfirmedMessage ==
    \A message \in CheckedActivateApplicationSystemConfirmedMessage :
        LET read == DecodeActivateApplicationSystemConfirmedMessage(EncodeActivateApplicationSystemConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutConfirmedMessage ==
    \A message \in CheckedLogoutConfirmedMessage :
        LET read == DecodeLogoutConfirmedMessage(EncodeLogoutConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Confirm Connection Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConfirmConnectionMessage ==
    \A message \in CheckedConfirmConnectionMessage :
        LET read == DecodeConfirmConnectionMessage(EncodeConfirmConnectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Connection Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConnectionConfirmedMessage ==
    \A message \in CheckedConnectionConfirmedMessage :
        LET read == DecodeConnectionConfirmedMessage(EncodeConnectionConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbolnum decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolnum ==
    \A message \in CheckedSymbolnum :
        LET read == DecodeSymbolnum(EncodeSymbolnum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symboltext decodes back to what was encoded, and leaves nothing over *)
RoundTripSymboltext ==
    \A message \in CheckedSymboltext :
        LET read == DecodeSymboltext(EncodeSymboltext(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orgtranstime Msgtime decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgtranstimeMsgtime ==
    \A message \in CheckedOrgtranstimeMsgtime :
        LET read == DecodeOrgtranstimeMsgtime(EncodeOrgtranstimeMsgtime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msgtime decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgtime ==
    \A message \in CheckedTransactTimeMsgtime :
        LET read == DecodeTransactTimeMsgtime(EncodeTransactTimeMsgtime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatusReportMessage ==
    \A message \in CheckedOrderStatusReportMessage :
        LET read == DecodeOrderStatusReportMessage(EncodeOrderStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Longsymbolnum decodes back to what was encoded, and leaves nothing over *)
RoundTripLongsymbolnum ==
    \A message \in CheckedLongsymbolnum :
        LET read == DecodeLongsymbolnum(EncodeLongsymbolnum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Longsymboltext decodes back to what was encoded, and leaves nothing over *)
RoundTripLongsymboltext ==
    \A message \in CheckedLongsymboltext :
        LET read == DecodeLongsymboltext(EncodeLongsymboltext(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orgtranstime Msgtime decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgtranstimeMsgtime2 ==
    \A message \in CheckedOrgtranstimeMsgtime2 :
        LET read == DecodeOrgtranstimeMsgtime2(EncodeOrgtranstimeMsgtime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msgtime decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgtime2 ==
    \A message \in CheckedTransactTimeMsgtime2 :
        LET read == DecodeTransactTimeMsgtime2(EncodeTransactTimeMsgtime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Status Report Long Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatusReportLongFormatMessage ==
    \A message \in CheckedOrderStatusReportLongFormatMessage :
        LET read == DecodeOrderStatusReportLongFormatMessage(EncodeOrderStatusReportLongFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbolnum decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolnum2 ==
    \A message \in CheckedSymbolnum2 :
        LET read == DecodeSymbolnum2(EncodeSymbolnum2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symboltext decodes back to what was encoded, and leaves nothing over *)
RoundTripSymboltext2 ==
    \A message \in CheckedSymboltext2 :
        LET read == DecodeSymboltext2(EncodeSymboltext2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orgtranstime Msgtime decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgtranstimeMsgtime3 ==
    \A message \in CheckedOrgtranstimeMsgtime3 :
        LET read == DecodeOrgtranstimeMsgtime3(EncodeOrgtranstimeMsgtime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msgtime decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgtime3 ==
    \A message \in CheckedTransactTimeMsgtime3 :
        LET read == DecodeTransactTimeMsgtime3(EncodeTransactTimeMsgtime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Including Head Office And Branch Offices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    \A message \in CheckedExecutionReportIncludingHeadOfficeAndBranchOfficesMessage :
        LET read == DecodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(EncodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbolnumx decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolnumx ==
    \A message \in CheckedSymbolnumx :
        LET read == DecodeSymbolnumx(EncodeSymbolnumx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symboltxtx decodes back to what was encoded, and leaves nothing over *)
RoundTripSymboltxtx ==
    \A message \in CheckedSymboltxtx :
        LET read == DecodeSymboltxtx(EncodeSymboltxtx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legsym Symbolnumx decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsymSymbolnumx ==
    \A message \in CheckedLegsymSymbolnumx :
        LET read == DecodeLegsymSymbolnumx(EncodeLegsymSymbolnumx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legentrynum decodes back to what was encoded, and leaves nothing over *)
RoundTripLegentrynum ==
    \A message \in CheckedLegentrynum :
        LET read == DecodeLegentrynum(EncodeLegentrynum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multilegnum decodes back to what was encoded, and leaves nothing over *)
RoundTripMultilegnum ==
    \A message \in CheckedMultilegnum :
        LET read == DecodeMultilegnum(EncodeMultilegnum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legsym Symboltxtx decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsymSymboltxtx ==
    \A message \in CheckedLegsymSymboltxtx :
        LET read == DecodeLegsymSymboltxtx(EncodeLegsymSymboltxtx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legentrytxt decodes back to what was encoded, and leaves nothing over *)
RoundTripLegentrytxt ==
    \A message \in CheckedLegentrytxt :
        LET read == DecodeLegentrytxt(EncodeLegentrytxt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multilegtxt decodes back to what was encoded, and leaves nothing over *)
RoundTripMultilegtxt ==
    \A message \in CheckedMultilegtxt :
        LET read == DecodeMultilegtxt(EncodeMultilegtxt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orgtranstime Msgtimex decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgtranstimeMsgtimex ==
    \A message \in CheckedOrgtranstimeMsgtimex :
        LET read == DecodeOrgtranstimeMsgtimex(EncodeOrgtranstimeMsgtimex(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msgtimex decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgtimex ==
    \A message \in CheckedTransactTimeMsgtimex :
        LET read == DecodeTransactTimeMsgtimex(EncodeTransactTimeMsgtimex(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Order Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexOrderStatusReportMessage ==
    \A message \in CheckedFlexOrderStatusReportMessage :
        LET read == DecodeFlexOrderStatusReportMessage(EncodeFlexOrderStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Member Initiate Operation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingMemberInitiateOperationMessage ==
    \A message \in CheckedClearingMemberInitiateOperationMessage :
        LET read == DecodeClearingMemberInitiateOperationMessage(EncodeClearingMemberInitiateOperationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Member Initiate Operation Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingMemberInitiateOperationConfirmedMessage ==
    \A message \in CheckedClearingMemberInitiateOperationConfirmedMessage :
        LET read == DecodeClearingMemberInitiateOperationConfirmedMessage(EncodeClearingMemberInitiateOperationConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subhdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubhdr2 ==
    \A message \in CheckedSubhdr2 :
        LET read == DecodeSubhdr2(EncodeSubhdr2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Clearing Member Initiate Operation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexClearingMemberInitiateOperationMessage ==
    \A message \in CheckedFlexClearingMemberInitiateOperationMessage :
        LET read == DecodeFlexClearingMemberInitiateOperationMessage(EncodeFlexClearingMemberInitiateOperationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subhdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubhdr3 ==
    \A message \in CheckedSubhdr3 :
        LET read == DecodeSubhdr3(EncodeSubhdr3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Clearing Member Initiate Operation Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexClearingMemberInitiateOperationConfirmedMessage ==
    \A message \in CheckedFlexClearingMemberInitiateOperationConfirmedMessage :
        LET read == DecodeFlexClearingMemberInitiateOperationConfirmedMessage(EncodeFlexClearingMemberInitiateOperationConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Tail decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageTail ==
    \A message \in CheckedMessageTail :
        LET read == DecodeMessageTail(EncodeMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tmp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTmpMessage ==
    \A message \in CheckedTmpMessage :
        LET read == DecodeTmpMessage(EncodeTmpMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sym Symbolx is selected by the Symboltype it is written under *)
SelectsSymSymbolx ==
    \A message \in CheckedSymSymbolx :
        LET read == DecodeSymSymbolx(message.tag, EncodeSymSymbolx(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Longsymbolx is selected by the Symboltype it is written under *)
SelectsSymLongsymbolx ==
    \A message \in CheckedSymLongsymbolx :
        LET read == DecodeSymLongsymbolx(message.tag, EncodeSymLongsymbolx(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Symbolx is selected by the Symboltype it is written under *)
SelectsSymSymbolx2 ==
    \A message \in CheckedSymSymbolx2 :
        LET read == DecodeSymSymbolx2(message.tag, EncodeSymSymbolx2(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flexproductx is selected by the Msg Type Ext it is written under *)
SelectsSymFlexproductx ==
    \A message \in CheckedSymFlexproductx :
        LET read == DecodeSymFlexproductx(message.tag, EncodeSymFlexproductx(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesTmpMessage ==
    \A message \in CheckedTmpMessage :
        LET bytes == EncodeTmpMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 3

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
