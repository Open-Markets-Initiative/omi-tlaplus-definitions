--------------------- MODULE SseSecurities_Mdgw_v0_63 ----------------------
(***************************************************************************)
(* Shanghai Stock Exchange Market Data Gateway v0.63                       *)
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
(* Logon Message: 74 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ sendercompid : Sample(32),
      targetcompid : Sample(32),
      heartbtint   : Sample(2),
      applverid    : Sample(8) ]

EncodeLogonMessage(message) ==
    message.sendercompid
        \o message.targetcompid
        \o message.heartbtint
        \o message.applverid

DecodeLogonMessage(bytes) ==
    LET sendercompid == ReadBytes(bytes, 32) IN IF ~sendercompid.ok THEN Fail ELSE
    LET targetcompid == ReadBytes(sendercompid.rest, 32) IN IF ~targetcompid.ok THEN Fail ELSE
    LET heartbtint == ReadBytes(targetcompid.rest, 2) IN IF ~heartbtint.ok THEN Fail ELSE
    LET applverid == ReadBytes(heartbtint.rest, 8) IN IF ~applverid.ok THEN Fail ELSE
    Ok([ sendercompid |-> sendercompid.value,
         targetcompid |-> targetcompid.value,
         heartbtint   |-> heartbtint.value,
         applverid    |-> applverid.value ], applverid.rest)

ZeroLogonMessage ==
    [ sendercompid |-> [i \in 1 .. 32 |-> 0],
      targetcompid |-> [i \in 1 .. 32 |-> 0],
      heartbtint   |-> [i \in 1 .. 2 |-> 0],
      applverid    |-> [i \in 1 .. 8 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.sendercompid = one] : one \in Sample(32) }
        \cup { [ZeroLogonMessage EXCEPT !.targetcompid = one] : one \in Sample(32) }
        \cup { [ZeroLogonMessage EXCEPT !.heartbtint = one] : one \in Sample(2) }
        \cup { [ZeroLogonMessage EXCEPT !.applverid = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Message: 260 bytes                                               *)
(***************************************************************************)

LogoutMessage ==
    [ sessionstatus : Sample(4),
      text          : Sample(256) ]

EncodeLogoutMessage(message) ==
    message.sessionstatus
        \o message.text

DecodeLogoutMessage(bytes) ==
    LET sessionstatus == ReadBytes(bytes, 4) IN IF ~sessionstatus.ok THEN Fail ELSE
    LET text == ReadBytes(sessionstatus.rest, 256) IN IF ~text.ok THEN Fail ELSE
    Ok([ sessionstatus |-> sessionstatus.value,
         text          |-> text.value ], text.rest)

ZeroLogoutMessage ==
    [ sessionstatus |-> [i \in 1 .. 4 |-> 0],
      text          |-> [i \in 1 .. 256 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.sessionstatus = one] : one \in Sample(4) }
        \cup { [ZeroLogoutMessage EXCEPT !.text = one] : one \in Sample(256) }

(***************************************************************************)
(* Channel Heartbeat: 12 bytes                                             *)
(***************************************************************************)

ChannelHeartbeat ==
    [ channelHeartbeatSecuritytype : Sample(1),
      channelHeartbeatChannelno    : Sample(2),
      appllastseqnum               : Sample(8),
      endofchannel                 : Sample(1) ]

EncodeChannelHeartbeat(message) ==
    message.channelHeartbeatSecuritytype
        \o message.channelHeartbeatChannelno
        \o message.appllastseqnum
        \o message.endofchannel

DecodeChannelHeartbeat(bytes) ==
    LET channelHeartbeatSecuritytype == ReadBytes(bytes, 1) IN IF ~channelHeartbeatSecuritytype.ok THEN Fail ELSE
    LET channelHeartbeatChannelno == ReadBytes(channelHeartbeatSecuritytype.rest, 2) IN IF ~channelHeartbeatChannelno.ok THEN Fail ELSE
    LET appllastseqnum == ReadBytes(channelHeartbeatChannelno.rest, 8) IN IF ~appllastseqnum.ok THEN Fail ELSE
    LET endofchannel == ReadBytes(appllastseqnum.rest, 1) IN IF ~endofchannel.ok THEN Fail ELSE
    Ok([ channelHeartbeatSecuritytype |-> channelHeartbeatSecuritytype.value,
         channelHeartbeatChannelno    |-> channelHeartbeatChannelno.value,
         appllastseqnum               |-> appllastseqnum.value,
         endofchannel                 |-> endofchannel.value ], endofchannel.rest)

ZeroChannelHeartbeat ==
    [ channelHeartbeatSecuritytype |-> [i \in 1 .. 1 |-> 0],
      channelHeartbeatChannelno    |-> [i \in 1 .. 2 |-> 0],
      appllastseqnum               |-> [i \in 1 .. 8 |-> 0],
      endofchannel                 |-> [i \in 1 .. 1 |-> 0] ]

(* Channel Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedChannelHeartbeat ==
    { ZeroChannelHeartbeat }
        \cup { [ZeroChannelHeartbeat EXCEPT !.channelHeartbeatSecuritytype = one] : one \in Sample(1) }
        \cup { [ZeroChannelHeartbeat EXCEPT !.channelHeartbeatChannelno = one] : one \in Sample(2) }
        \cup { [ZeroChannelHeartbeat EXCEPT !.appllastseqnum = one] : one \in Sample(8) }
        \cup { [ZeroChannelHeartbeat EXCEPT !.endofchannel = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Message: 52 bytes                                        *)
(***************************************************************************)

RetransmissionMessage ==
    [ retransmissionMessageChannelno : Sample(2),
      resendtype                     : Sample(1),
      applbegseqnum                  : Sample(8),
      applendseqnum                  : Sample(8),
      resendstatus                   : Sample(1),
      rejecttext                     : Sample(32) ]

EncodeRetransmissionMessage(message) ==
    message.retransmissionMessageChannelno
        \o message.resendtype
        \o message.applbegseqnum
        \o message.applendseqnum
        \o message.resendstatus
        \o message.rejecttext

DecodeRetransmissionMessage(bytes) ==
    LET retransmissionMessageChannelno == ReadBytes(bytes, 2) IN IF ~retransmissionMessageChannelno.ok THEN Fail ELSE
    LET resendtype == ReadBytes(retransmissionMessageChannelno.rest, 1) IN IF ~resendtype.ok THEN Fail ELSE
    LET applbegseqnum == ReadBytes(resendtype.rest, 8) IN IF ~applbegseqnum.ok THEN Fail ELSE
    LET applendseqnum == ReadBytes(applbegseqnum.rest, 8) IN IF ~applendseqnum.ok THEN Fail ELSE
    LET resendstatus == ReadBytes(applendseqnum.rest, 1) IN IF ~resendstatus.ok THEN Fail ELSE
    LET rejecttext == ReadBytes(resendstatus.rest, 32) IN IF ~rejecttext.ok THEN Fail ELSE
    Ok([ retransmissionMessageChannelno |-> retransmissionMessageChannelno.value,
         resendtype                     |-> resendtype.value,
         applbegseqnum                  |-> applbegseqnum.value,
         applendseqnum                  |-> applendseqnum.value,
         resendstatus                   |-> resendstatus.value,
         rejecttext                     |-> rejecttext.value ], rejecttext.rest)

ZeroRetransmissionMessage ==
    [ retransmissionMessageChannelno |-> [i \in 1 .. 2 |-> 0],
      resendtype                     |-> [i \in 1 .. 1 |-> 0],
      applbegseqnum                  |-> [i \in 1 .. 8 |-> 0],
      applendseqnum                  |-> [i \in 1 .. 8 |-> 0],
      resendstatus                   |-> [i \in 1 .. 1 |-> 0],
      rejecttext                     |-> [i \in 1 .. 32 |-> 0] ]

(* Retransmission Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionMessage ==
    { ZeroRetransmissionMessage }
        \cup { [ZeroRetransmissionMessage EXCEPT !.retransmissionMessageChannelno = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.resendtype = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.applbegseqnum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.applendseqnum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.resendstatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.rejecttext = one] : one \in Sample(32) }

(***************************************************************************)
(* Market Status Message: 14 bytes                                         *)
(***************************************************************************)

MarketStatusMessage ==
    [ marketStatusMessageSecuritytype : Sample(1),
      tradsesmode                     : Sample(1),
      tradingsessionid                : Sample(8),
      totnorelatedsym                 : Sample(4) ]

EncodeMarketStatusMessage(message) ==
    message.marketStatusMessageSecuritytype
        \o message.tradsesmode
        \o message.tradingsessionid
        \o message.totnorelatedsym

DecodeMarketStatusMessage(bytes) ==
    LET marketStatusMessageSecuritytype == ReadBytes(bytes, 1) IN IF ~marketStatusMessageSecuritytype.ok THEN Fail ELSE
    LET tradsesmode == ReadBytes(marketStatusMessageSecuritytype.rest, 1) IN IF ~tradsesmode.ok THEN Fail ELSE
    LET tradingsessionid == ReadBytes(tradsesmode.rest, 8) IN IF ~tradingsessionid.ok THEN Fail ELSE
    LET totnorelatedsym == ReadBytes(tradingsessionid.rest, 4) IN IF ~totnorelatedsym.ok THEN Fail ELSE
    Ok([ marketStatusMessageSecuritytype |-> marketStatusMessageSecuritytype.value,
         tradsesmode                     |-> tradsesmode.value,
         tradingsessionid                |-> tradingsessionid.value,
         totnorelatedsym                 |-> totnorelatedsym.value ], totnorelatedsym.rest)

ZeroMarketStatusMessage ==
    [ marketStatusMessageSecuritytype |-> [i \in 1 .. 1 |-> 0],
      tradsesmode                     |-> [i \in 1 .. 1 |-> 0],
      tradingsessionid                |-> [i \in 1 .. 8 |-> 0],
      totnorelatedsym                 |-> [i \in 1 .. 4 |-> 0] ]

(* Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatusMessage ==
    { ZeroMarketStatusMessage }
        \cup { [ZeroMarketStatusMessage EXCEPT !.marketStatusMessageSecuritytype = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.tradsesmode = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.tradingsessionid = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.totnorelatedsym = one] : one \in Sample(4) }

(***************************************************************************)
(* Index Market Data Snapshot Entries: 10 bytes                            *)
(***************************************************************************)

IndexMarketDataSnapshotEntries ==
    [ indexMarketDataSnapshotEntriesMdentrytype : Sample(2),
      indexMarketDataSnapshotEntriesMdentrypx   : Sample(8) ]

EncodeIndexMarketDataSnapshotEntries(message) ==
    message.indexMarketDataSnapshotEntriesMdentrytype
        \o message.indexMarketDataSnapshotEntriesMdentrypx

DecodeIndexMarketDataSnapshotEntries(bytes) ==
    LET indexMarketDataSnapshotEntriesMdentrytype == ReadBytes(bytes, 2) IN IF ~indexMarketDataSnapshotEntriesMdentrytype.ok THEN Fail ELSE
    LET indexMarketDataSnapshotEntriesMdentrypx == ReadBytes(indexMarketDataSnapshotEntriesMdentrytype.rest, 8) IN IF ~indexMarketDataSnapshotEntriesMdentrypx.ok THEN Fail ELSE
    Ok([ indexMarketDataSnapshotEntriesMdentrytype |-> indexMarketDataSnapshotEntriesMdentrytype.value,
         indexMarketDataSnapshotEntriesMdentrypx   |-> indexMarketDataSnapshotEntriesMdentrypx.value ], indexMarketDataSnapshotEntriesMdentrypx.rest)

ZeroIndexMarketDataSnapshotEntries ==
    [ indexMarketDataSnapshotEntriesMdentrytype |-> [i \in 1 .. 2 |-> 0],
      indexMarketDataSnapshotEntriesMdentrypx   |-> [i \in 1 .. 8 |-> 0] ]

(* Index Market Data Snapshot Entries at zero, then each field in turn at the values it is checked at *)
CheckedIndexMarketDataSnapshotEntries ==
    { ZeroIndexMarketDataSnapshotEntries }
        \cup { [ZeroIndexMarketDataSnapshotEntries EXCEPT !.indexMarketDataSnapshotEntriesMdentrytype = one] : one \in Sample(2) }
        \cup { [ZeroIndexMarketDataSnapshotEntries EXCEPT !.indexMarketDataSnapshotEntriesMdentrypx = one] : one \in Sample(8) }

(* A run of Index Market Data Snapshot Entries, written one after another *)
RECURSIVE EncodeIndexMarketDataSnapshotEntriesList(_)
EncodeIndexMarketDataSnapshotEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIndexMarketDataSnapshotEntries(Head(messages)) \o EncodeIndexMarketDataSnapshotEntriesList(Tail(messages))

(* As many Index Market Data Snapshot Entries as the field that counts them says *)
RECURSIVE ReadIndexMarketDataSnapshotEntriesList(_, _)
ReadIndexMarketDataSnapshotEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIndexMarketDataSnapshotEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIndexMarketDataSnapshotEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Index Market Data Snapshot Entries of each kind, for the lists that carry them *)
OneIndexMarketDataSnapshotEntries == { ZeroIndexMarketDataSnapshotEntries }

(***************************************************************************)
(* Index Market Data Snapshot Extension Fields                             *)
(***************************************************************************)

IndexMarketDataSnapshotExtensionFields ==
    [ indexMarketDataSnapshotEntries : SampleLists(OneIndexMarketDataSnapshotEntries) ]

EncodeIndexMarketDataSnapshotExtensionFields(message) ==
    EncodeUIntBE(Len(message.indexMarketDataSnapshotEntries), 2)
        \o EncodeIndexMarketDataSnapshotEntriesList(message.indexMarketDataSnapshotEntries)

DecodeIndexMarketDataSnapshotExtensionFields(bytes) ==
    LET nomdentries == ReadUIntBE(bytes, 2) IN IF ~nomdentries.ok THEN Fail ELSE
    LET indexMarketDataSnapshotEntries == ReadIndexMarketDataSnapshotEntriesList(nomdentries.rest, nomdentries.value) IN IF ~indexMarketDataSnapshotEntries.ok THEN Fail ELSE
    Ok([ indexMarketDataSnapshotEntries |-> indexMarketDataSnapshotEntries.value ], indexMarketDataSnapshotEntries.rest)

ZeroIndexMarketDataSnapshotExtensionFields ==
    [ indexMarketDataSnapshotEntries |-> << >> ]

(* Index Market Data Snapshot Extension Fields at zero, then each field in turn at the values it is checked at *)
CheckedIndexMarketDataSnapshotExtensionFields ==
    { ZeroIndexMarketDataSnapshotExtensionFields }
        \cup { [ZeroIndexMarketDataSnapshotExtensionFields EXCEPT !.indexMarketDataSnapshotEntries = one] : one \in SampleLists(OneIndexMarketDataSnapshotEntries) }

(***************************************************************************)
(* Market Data Snapshot Entries: 19 bytes                                  *)
(***************************************************************************)

MarketDataSnapshotEntries ==
    [ marketDataSnapshotEntriesMdentrytype : Sample(2),
      marketDataSnapshotEntriesMdentrypx   : Sample(8),
      mdentrysize                          : Sample(8),
      mdentrypositionno                    : Sample(1) ]

EncodeMarketDataSnapshotEntries(message) ==
    message.marketDataSnapshotEntriesMdentrytype
        \o message.marketDataSnapshotEntriesMdentrypx
        \o message.mdentrysize
        \o message.mdentrypositionno

DecodeMarketDataSnapshotEntries(bytes) ==
    LET marketDataSnapshotEntriesMdentrytype == ReadBytes(bytes, 2) IN IF ~marketDataSnapshotEntriesMdentrytype.ok THEN Fail ELSE
    LET marketDataSnapshotEntriesMdentrypx == ReadBytes(marketDataSnapshotEntriesMdentrytype.rest, 8) IN IF ~marketDataSnapshotEntriesMdentrypx.ok THEN Fail ELSE
    LET mdentrysize == ReadBytes(marketDataSnapshotEntriesMdentrypx.rest, 8) IN IF ~mdentrysize.ok THEN Fail ELSE
    LET mdentrypositionno == ReadBytes(mdentrysize.rest, 1) IN IF ~mdentrypositionno.ok THEN Fail ELSE
    Ok([ marketDataSnapshotEntriesMdentrytype |-> marketDataSnapshotEntriesMdentrytype.value,
         marketDataSnapshotEntriesMdentrypx   |-> marketDataSnapshotEntriesMdentrypx.value,
         mdentrysize                          |-> mdentrysize.value,
         mdentrypositionno                    |-> mdentrypositionno.value ], mdentrypositionno.rest)

ZeroMarketDataSnapshotEntries ==
    [ marketDataSnapshotEntriesMdentrytype |-> [i \in 1 .. 2 |-> 0],
      marketDataSnapshotEntriesMdentrypx   |-> [i \in 1 .. 8 |-> 0],
      mdentrysize                          |-> [i \in 1 .. 8 |-> 0],
      mdentrypositionno                    |-> [i \in 1 .. 1 |-> 0] ]

(* Market Data Snapshot Entries at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataSnapshotEntries ==
    { ZeroMarketDataSnapshotEntries }
        \cup { [ZeroMarketDataSnapshotEntries EXCEPT !.marketDataSnapshotEntriesMdentrytype = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataSnapshotEntries EXCEPT !.marketDataSnapshotEntriesMdentrypx = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotEntries EXCEPT !.mdentrysize = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotEntries EXCEPT !.mdentrypositionno = one] : one \in Sample(1) }

(* A run of Market Data Snapshot Entries, written one after another *)
RECURSIVE EncodeMarketDataSnapshotEntriesList(_)
EncodeMarketDataSnapshotEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDataSnapshotEntries(Head(messages)) \o EncodeMarketDataSnapshotEntriesList(Tail(messages))

(* As many Market Data Snapshot Entries as the field that counts them says *)
RECURSIVE ReadMarketDataSnapshotEntriesList(_, _)
ReadMarketDataSnapshotEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDataSnapshotEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDataSnapshotEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Data Snapshot Entries of each kind, for the lists that carry them *)
OneMarketDataSnapshotEntries == { ZeroMarketDataSnapshotEntries }

(***************************************************************************)
(* Market Data Snapshot Extension Fields                                   *)
(***************************************************************************)

MarketDataSnapshotExtensionFields ==
    [ marketDataSnapshotEntries : SampleLists(OneMarketDataSnapshotEntries) ]

EncodeMarketDataSnapshotExtensionFields(message) ==
    EncodeUIntBE(Len(message.marketDataSnapshotEntries), 2)
        \o EncodeMarketDataSnapshotEntriesList(message.marketDataSnapshotEntries)

DecodeMarketDataSnapshotExtensionFields(bytes) ==
    LET nomdentries == ReadUIntBE(bytes, 2) IN IF ~nomdentries.ok THEN Fail ELSE
    LET marketDataSnapshotEntries == ReadMarketDataSnapshotEntriesList(nomdentries.rest, nomdentries.value) IN IF ~marketDataSnapshotEntries.ok THEN Fail ELSE
    Ok([ marketDataSnapshotEntries |-> marketDataSnapshotEntries.value ], marketDataSnapshotEntries.rest)

ZeroMarketDataSnapshotExtensionFields ==
    [ marketDataSnapshotEntries |-> << >> ]

(* Market Data Snapshot Extension Fields at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataSnapshotExtensionFields ==
    { ZeroMarketDataSnapshotExtensionFields }
        \cup { [ZeroMarketDataSnapshotExtensionFields EXCEPT !.marketDataSnapshotEntries = one] : one \in SampleLists(OneMarketDataSnapshotEntries) }

(***************************************************************************)
(* Market Data Snapshot Message ExtendFields, selected by MDStreamID       *)
(***************************************************************************)

IndexMarketDataSnapshotExtensionFieldsCode == <<77, 68, 48, 48, 49>>  \* "MD001"
MarketDataSnapshotExtensionFieldsCode == <<77, 68, 48, 48, 50>>  \* "MD002"
MarketDataSnapshotExtensionFieldsCode2 == <<77, 68, 48, 48, 51>>  \* "MD003"
MarketDataSnapshotExtensionFieldsCode3 == <<77, 68, 48, 48, 52>>  \* "MD004"
MarketDataSnapshotExtensionFieldsCode4 == <<77, 68, 49, 48, 49>>  \* "MD101"
MarketDataSnapshotExtensionFieldsCode5 == <<77, 68, 49, 48, 50>>  \* "MD102"
MarketDataSnapshotExtensionFieldsCode6 == <<77, 68, 51, 48, 49>>  \* "MD301"
MarketDataSnapshotExtensionFieldsCode7 == <<77, 68, 50, 48, 49>>  \* "MD201"
MarketDataSnapshotExtensionFieldsCode8 == <<77, 68, 69, 48, 49>>  \* "MDE01"
MarketDataSnapshotExtensionFieldsCode9 == <<77, 68, 50, 49, 48>>  \* "MD210"

MarketDataSnapshotMessageExtendfields ==
    [ tag : {IndexMarketDataSnapshotExtensionFieldsCode}, body : IndexMarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode2}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode3}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode4}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode5}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode6}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode7}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode8}, body : MarketDataSnapshotExtensionFields ]
        \cup [ tag : {MarketDataSnapshotExtensionFieldsCode9}, body : MarketDataSnapshotExtensionFields ]

EncodeMarketDataSnapshotMessageExtendfields(message) ==
    CASE message.tag = IndexMarketDataSnapshotExtensionFieldsCode -> EncodeIndexMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode2 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode3 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode4 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode5 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode6 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode7 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode8 -> EncodeMarketDataSnapshotExtensionFields(message.body)
      [] message.tag = MarketDataSnapshotExtensionFieldsCode9 -> EncodeMarketDataSnapshotExtensionFields(message.body)

DecodeMarketDataSnapshotMessageExtendfields(tag, bytes) ==
    LET read ==
            CASE tag = IndexMarketDataSnapshotExtensionFieldsCode -> DecodeIndexMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode2 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode3 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode4 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode5 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode6 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode7 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode8 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] tag = MarketDataSnapshotExtensionFieldsCode9 -> DecodeMarketDataSnapshotExtensionFields(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMarketDataSnapshotMessageExtendfields == [tag |-> IndexMarketDataSnapshotExtensionFieldsCode, body |-> ZeroIndexMarketDataSnapshotExtensionFields]

(* Each Market Data Snapshot Message ExtendFields in turn, at the values the message it names is checked at *)
CheckedMarketDataSnapshotMessageExtendfields ==
    { [tag |-> IndexMarketDataSnapshotExtensionFieldsCode, body |-> one] : one \in CheckedIndexMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode2, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode3, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode4, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode5, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode6, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode7, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode8, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }
        \cup { [tag |-> MarketDataSnapshotExtensionFieldsCode9, body |-> one] : one \in CheckedMarketDataSnapshotExtensionFields }

(***************************************************************************)
(* Market Data Snapshot Message                                            *)
(***************************************************************************)

MarketDataSnapshotMessage ==
    [ marketDataSnapshotMessageSecuritytype     : Sample(1),
      tradsesmode                               : Sample(1),
      tradedate                                 : Sample(4),
      lastupdatetime                            : Sample(4),
      securityid                                : Sample(8),
      symbol                                    : Sample(8),
      preclosepx                                : Sample(8),
      totalvolumetraded                         : Sample(8),
      numtrades                                 : Sample(8),
      marketDataSnapshotMessageTotalvaluetraded : Sample(8),
      tradingphasecode                          : Sample(8),
      marketDataSnapshotMessageExtendfields     : MarketDataSnapshotMessageExtendfields ]

EncodeMarketDataSnapshotMessage(message) ==
    message.marketDataSnapshotMessageSecuritytype
        \o message.tradsesmode
        \o message.tradedate
        \o message.lastupdatetime
        \o message.marketDataSnapshotMessageExtendfields.tag
        \o message.securityid
        \o message.symbol
        \o message.preclosepx
        \o message.totalvolumetraded
        \o message.numtrades
        \o message.marketDataSnapshotMessageTotalvaluetraded
        \o message.tradingphasecode
        \o EncodeMarketDataSnapshotMessageExtendfields(message.marketDataSnapshotMessageExtendfields)

DecodeMarketDataSnapshotMessage(bytes) ==
    LET marketDataSnapshotMessageSecuritytype == ReadBytes(bytes, 1) IN IF ~marketDataSnapshotMessageSecuritytype.ok THEN Fail ELSE
    LET tradsesmode == ReadBytes(marketDataSnapshotMessageSecuritytype.rest, 1) IN IF ~tradsesmode.ok THEN Fail ELSE
    LET tradedate == ReadBytes(tradsesmode.rest, 4) IN IF ~tradedate.ok THEN Fail ELSE
    LET lastupdatetime == ReadBytes(tradedate.rest, 4) IN IF ~lastupdatetime.ok THEN Fail ELSE
    LET mdstreamid == ReadBytes(lastupdatetime.rest, 5) IN IF ~mdstreamid.ok THEN Fail ELSE
    LET securityid == ReadBytes(mdstreamid.rest, 8) IN IF ~securityid.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityid.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET preclosepx == ReadBytes(symbol.rest, 8) IN IF ~preclosepx.ok THEN Fail ELSE
    LET totalvolumetraded == ReadBytes(preclosepx.rest, 8) IN IF ~totalvolumetraded.ok THEN Fail ELSE
    LET numtrades == ReadBytes(totalvolumetraded.rest, 8) IN IF ~numtrades.ok THEN Fail ELSE
    LET marketDataSnapshotMessageTotalvaluetraded == ReadBytes(numtrades.rest, 8) IN IF ~marketDataSnapshotMessageTotalvaluetraded.ok THEN Fail ELSE
    LET tradingphasecode == ReadBytes(marketDataSnapshotMessageTotalvaluetraded.rest, 8) IN IF ~tradingphasecode.ok THEN Fail ELSE
    LET marketDataSnapshotMessageExtendfields == DecodeMarketDataSnapshotMessageExtendfields(mdstreamid.value, tradingphasecode.rest) IN IF ~marketDataSnapshotMessageExtendfields.ok THEN Fail ELSE
    Ok([ marketDataSnapshotMessageSecuritytype     |-> marketDataSnapshotMessageSecuritytype.value,
         tradsesmode                               |-> tradsesmode.value,
         tradedate                                 |-> tradedate.value,
         lastupdatetime                            |-> lastupdatetime.value,
         securityid                                |-> securityid.value,
         symbol                                    |-> symbol.value,
         preclosepx                                |-> preclosepx.value,
         totalvolumetraded                         |-> totalvolumetraded.value,
         numtrades                                 |-> numtrades.value,
         marketDataSnapshotMessageTotalvaluetraded |-> marketDataSnapshotMessageTotalvaluetraded.value,
         tradingphasecode                          |-> tradingphasecode.value,
         marketDataSnapshotMessageExtendfields     |-> marketDataSnapshotMessageExtendfields.value ], marketDataSnapshotMessageExtendfields.rest)

ZeroMarketDataSnapshotMessage ==
    [ marketDataSnapshotMessageSecuritytype     |-> [i \in 1 .. 1 |-> 0],
      tradsesmode                               |-> [i \in 1 .. 1 |-> 0],
      tradedate                                 |-> [i \in 1 .. 4 |-> 0],
      lastupdatetime                            |-> [i \in 1 .. 4 |-> 0],
      securityid                                |-> [i \in 1 .. 8 |-> 0],
      symbol                                    |-> [i \in 1 .. 8 |-> 0],
      preclosepx                                |-> [i \in 1 .. 8 |-> 0],
      totalvolumetraded                         |-> [i \in 1 .. 8 |-> 0],
      numtrades                                 |-> [i \in 1 .. 8 |-> 0],
      marketDataSnapshotMessageTotalvaluetraded |-> [i \in 1 .. 8 |-> 0],
      tradingphasecode                          |-> [i \in 1 .. 8 |-> 0],
      marketDataSnapshotMessageExtendfields     |-> ZeroMarketDataSnapshotMessageExtendfields ]

(* Market Data Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataSnapshotMessage ==
    { ZeroMarketDataSnapshotMessage }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.marketDataSnapshotMessageSecuritytype = one] : one \in Sample(1) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.tradsesmode = one] : one \in Sample(1) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.tradedate = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.lastupdatetime = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.securityid = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.preclosepx = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.totalvolumetraded = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.numtrades = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.marketDataSnapshotMessageTotalvaluetraded = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.tradingphasecode = one] : one \in Sample(8) }
        \cup { [ZeroMarketDataSnapshotMessage EXCEPT !.marketDataSnapshotMessageExtendfields = one] : one \in CheckedMarketDataSnapshotMessageExtendfields }

(***************************************************************************)
(* Tick-by-Tick Order Market Data Extension Fields: 139 bytes              *)
(***************************************************************************)

TickbytickOrderMarketDataExtensionFields ==
    [ side                                                     : Sample(1),
      quoteid                                                  : Sample(18),
      memberid                                                 : Sample(12),
      tradercode                                               : Sample(12),
      fullamounttrade                                          : Sample(1),
      settltype                                                : Sample(1),
      contractmultiplier                                       : Sample(4),
      expirationdays                                           : Sample(2),
      tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded : Sample(8),
      basketid                                                 : Sample(16),
      investorname                                             : Sample(32),
      bidtranstype                                             : Sample(1),
      bidexecinsttype                                          : Sample(1),
      expiredate                                               : Sample(4),
      secondaryorderid                                         : Sample(18),
      minqty                                                   : Sample(8) ]

EncodeTickbytickOrderMarketDataExtensionFields(message) ==
    message.side
        \o message.quoteid
        \o message.memberid
        \o message.tradercode
        \o message.fullamounttrade
        \o message.settltype
        \o message.contractmultiplier
        \o message.expirationdays
        \o message.tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded
        \o message.basketid
        \o message.investorname
        \o message.bidtranstype
        \o message.bidexecinsttype
        \o message.expiredate
        \o message.secondaryorderid
        \o message.minqty

DecodeTickbytickOrderMarketDataExtensionFields(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET quoteid == ReadBytes(side.rest, 18) IN IF ~quoteid.ok THEN Fail ELSE
    LET memberid == ReadBytes(quoteid.rest, 12) IN IF ~memberid.ok THEN Fail ELSE
    LET tradercode == ReadBytes(memberid.rest, 12) IN IF ~tradercode.ok THEN Fail ELSE
    LET fullamounttrade == ReadBytes(tradercode.rest, 1) IN IF ~fullamounttrade.ok THEN Fail ELSE
    LET settltype == ReadBytes(fullamounttrade.rest, 1) IN IF ~settltype.ok THEN Fail ELSE
    LET contractmultiplier == ReadBytes(settltype.rest, 4) IN IF ~contractmultiplier.ok THEN Fail ELSE
    LET expirationdays == ReadBytes(contractmultiplier.rest, 2) IN IF ~expirationdays.ok THEN Fail ELSE
    LET tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded == ReadBytes(expirationdays.rest, 8) IN IF ~tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded.ok THEN Fail ELSE
    LET basketid == ReadBytes(tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded.rest, 16) IN IF ~basketid.ok THEN Fail ELSE
    LET investorname == ReadBytes(basketid.rest, 32) IN IF ~investorname.ok THEN Fail ELSE
    LET bidtranstype == ReadBytes(investorname.rest, 1) IN IF ~bidtranstype.ok THEN Fail ELSE
    LET bidexecinsttype == ReadBytes(bidtranstype.rest, 1) IN IF ~bidexecinsttype.ok THEN Fail ELSE
    LET expiredate == ReadBytes(bidexecinsttype.rest, 4) IN IF ~expiredate.ok THEN Fail ELSE
    LET secondaryorderid == ReadBytes(expiredate.rest, 18) IN IF ~secondaryorderid.ok THEN Fail ELSE
    LET minqty == ReadBytes(secondaryorderid.rest, 8) IN IF ~minqty.ok THEN Fail ELSE
    Ok([ side                                                     |-> side.value,
         quoteid                                                  |-> quoteid.value,
         memberid                                                 |-> memberid.value,
         tradercode                                               |-> tradercode.value,
         fullamounttrade                                          |-> fullamounttrade.value,
         settltype                                                |-> settltype.value,
         contractmultiplier                                       |-> contractmultiplier.value,
         expirationdays                                           |-> expirationdays.value,
         tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded |-> tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded.value,
         basketid                                                 |-> basketid.value,
         investorname                                             |-> investorname.value,
         bidtranstype                                             |-> bidtranstype.value,
         bidexecinsttype                                          |-> bidexecinsttype.value,
         expiredate                                               |-> expiredate.value,
         secondaryorderid                                         |-> secondaryorderid.value,
         minqty                                                   |-> minqty.value ], minqty.rest)

ZeroTickbytickOrderMarketDataExtensionFields ==
    [ side                                                     |-> [i \in 1 .. 1 |-> 0],
      quoteid                                                  |-> [i \in 1 .. 18 |-> 0],
      memberid                                                 |-> [i \in 1 .. 12 |-> 0],
      tradercode                                               |-> [i \in 1 .. 12 |-> 0],
      fullamounttrade                                          |-> [i \in 1 .. 1 |-> 0],
      settltype                                                |-> [i \in 1 .. 1 |-> 0],
      contractmultiplier                                       |-> [i \in 1 .. 4 |-> 0],
      expirationdays                                           |-> [i \in 1 .. 2 |-> 0],
      tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded |-> [i \in 1 .. 8 |-> 0],
      basketid                                                 |-> [i \in 1 .. 16 |-> 0],
      investorname                                             |-> [i \in 1 .. 32 |-> 0],
      bidtranstype                                             |-> [i \in 1 .. 1 |-> 0],
      bidexecinsttype                                          |-> [i \in 1 .. 1 |-> 0],
      expiredate                                               |-> [i \in 1 .. 4 |-> 0],
      secondaryorderid                                         |-> [i \in 1 .. 18 |-> 0],
      minqty                                                   |-> [i \in 1 .. 8 |-> 0] ]

(* Tick-by-Tick Order Market Data Extension Fields at zero, then each field in turn at the values it is checked at *)
CheckedTickbytickOrderMarketDataExtensionFields ==
    { ZeroTickbytickOrderMarketDataExtensionFields }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.quoteid = one] : one \in Sample(18) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.memberid = one] : one \in Sample(12) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.tradercode = one] : one \in Sample(12) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.fullamounttrade = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.settltype = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.contractmultiplier = one] : one \in Sample(4) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.expirationdays = one] : one \in Sample(2) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.tickbytickOrderMarketDataExtensionFieldsTotalvaluetraded = one] : one \in Sample(8) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.basketid = one] : one \in Sample(16) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.investorname = one] : one \in Sample(32) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.bidtranstype = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.bidexecinsttype = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.expiredate = one] : one \in Sample(4) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.secondaryorderid = one] : one \in Sample(18) }
        \cup { [ZeroTickbytickOrderMarketDataExtensionFields EXCEPT !.minqty = one] : one \in Sample(8) }

(***************************************************************************)
(* Tick-by-Tick Trade Market Data Extension Fields: 53 bytes               *)
(***************************************************************************)

TickbytickTradeMarketDataExtensionFields ==
    [ bidapplseqnum                                            : Sample(18),
      offerapplseqnum                                          : Sample(18),
      tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded : Sample(8),
      trademethod                                              : Sample(1),
      marginprice                                              : Sample(8) ]

EncodeTickbytickTradeMarketDataExtensionFields(message) ==
    message.bidapplseqnum
        \o message.offerapplseqnum
        \o message.tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded
        \o message.trademethod
        \o message.marginprice

DecodeTickbytickTradeMarketDataExtensionFields(bytes) ==
    LET bidapplseqnum == ReadBytes(bytes, 18) IN IF ~bidapplseqnum.ok THEN Fail ELSE
    LET offerapplseqnum == ReadBytes(bidapplseqnum.rest, 18) IN IF ~offerapplseqnum.ok THEN Fail ELSE
    LET tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded == ReadBytes(offerapplseqnum.rest, 8) IN IF ~tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded.ok THEN Fail ELSE
    LET trademethod == ReadBytes(tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded.rest, 1) IN IF ~trademethod.ok THEN Fail ELSE
    LET marginprice == ReadBytes(trademethod.rest, 8) IN IF ~marginprice.ok THEN Fail ELSE
    Ok([ bidapplseqnum                                            |-> bidapplseqnum.value,
         offerapplseqnum                                          |-> offerapplseqnum.value,
         tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded |-> tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded.value,
         trademethod                                              |-> trademethod.value,
         marginprice                                              |-> marginprice.value ], marginprice.rest)

ZeroTickbytickTradeMarketDataExtensionFields ==
    [ bidapplseqnum                                            |-> [i \in 1 .. 18 |-> 0],
      offerapplseqnum                                          |-> [i \in 1 .. 18 |-> 0],
      tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded |-> [i \in 1 .. 8 |-> 0],
      trademethod                                              |-> [i \in 1 .. 1 |-> 0],
      marginprice                                              |-> [i \in 1 .. 8 |-> 0] ]

(* Tick-by-Tick Trade Market Data Extension Fields at zero, then each field in turn at the values it is checked at *)
CheckedTickbytickTradeMarketDataExtensionFields ==
    { ZeroTickbytickTradeMarketDataExtensionFields }
        \cup { [ZeroTickbytickTradeMarketDataExtensionFields EXCEPT !.bidapplseqnum = one] : one \in Sample(18) }
        \cup { [ZeroTickbytickTradeMarketDataExtensionFields EXCEPT !.offerapplseqnum = one] : one \in Sample(18) }
        \cup { [ZeroTickbytickTradeMarketDataExtensionFields EXCEPT !.tickbytickTradeMarketDataExtensionFieldsTotalvaluetraded = one] : one \in Sample(8) }
        \cup { [ZeroTickbytickTradeMarketDataExtensionFields EXCEPT !.trademethod = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickTradeMarketDataExtensionFields EXCEPT !.marginprice = one] : one \in Sample(8) }

(***************************************************************************)
(* Tick-by-Tick Market Data Message ExtendFields, selected by MDStreamID   *)
(***************************************************************************)

TickbytickOrderMarketDataExtensionFieldsCode == <<77, 68, 50, 49, 49>>  \* "MD211"
TickbytickOrderMarketDataExtensionFieldsCode2 == <<77, 68, 50, 49, 50>>  \* "MD212"
TickbytickOrderMarketDataExtensionFieldsCode3 == <<77, 68, 50, 49, 51>>  \* "MD213"
TickbytickOrderMarketDataExtensionFieldsCode4 == <<77, 68, 50, 49, 52>>  \* "MD214"
TickbytickOrderMarketDataExtensionFieldsCode5 == <<77, 68, 50, 49, 53>>  \* "MD215"
TickbytickOrderMarketDataExtensionFieldsCode6 == <<77, 68, 50, 49, 54>>  \* "MD216"
TickbytickTradeMarketDataExtensionFieldsCode == <<77, 68, 50, 49, 55>>  \* "MD217"

TickbytickMarketDataMessageExtendfields ==
    [ tag : {TickbytickOrderMarketDataExtensionFieldsCode}, body : TickbytickOrderMarketDataExtensionFields ]
        \cup [ tag : {TickbytickOrderMarketDataExtensionFieldsCode2}, body : TickbytickOrderMarketDataExtensionFields ]
        \cup [ tag : {TickbytickOrderMarketDataExtensionFieldsCode3}, body : TickbytickOrderMarketDataExtensionFields ]
        \cup [ tag : {TickbytickOrderMarketDataExtensionFieldsCode4}, body : TickbytickOrderMarketDataExtensionFields ]
        \cup [ tag : {TickbytickOrderMarketDataExtensionFieldsCode5}, body : TickbytickOrderMarketDataExtensionFields ]
        \cup [ tag : {TickbytickOrderMarketDataExtensionFieldsCode6}, body : TickbytickOrderMarketDataExtensionFields ]
        \cup [ tag : {TickbytickTradeMarketDataExtensionFieldsCode}, body : TickbytickTradeMarketDataExtensionFields ]

EncodeTickbytickMarketDataMessageExtendfields(message) ==
    CASE message.tag = TickbytickOrderMarketDataExtensionFieldsCode -> EncodeTickbytickOrderMarketDataExtensionFields(message.body)
      [] message.tag = TickbytickOrderMarketDataExtensionFieldsCode2 -> EncodeTickbytickOrderMarketDataExtensionFields(message.body)
      [] message.tag = TickbytickOrderMarketDataExtensionFieldsCode3 -> EncodeTickbytickOrderMarketDataExtensionFields(message.body)
      [] message.tag = TickbytickOrderMarketDataExtensionFieldsCode4 -> EncodeTickbytickOrderMarketDataExtensionFields(message.body)
      [] message.tag = TickbytickOrderMarketDataExtensionFieldsCode5 -> EncodeTickbytickOrderMarketDataExtensionFields(message.body)
      [] message.tag = TickbytickOrderMarketDataExtensionFieldsCode6 -> EncodeTickbytickOrderMarketDataExtensionFields(message.body)
      [] message.tag = TickbytickTradeMarketDataExtensionFieldsCode -> EncodeTickbytickTradeMarketDataExtensionFields(message.body)

DecodeTickbytickMarketDataMessageExtendfields(tag, bytes) ==
    LET read ==
            CASE tag = TickbytickOrderMarketDataExtensionFieldsCode -> DecodeTickbytickOrderMarketDataExtensionFields(bytes)
              [] tag = TickbytickOrderMarketDataExtensionFieldsCode2 -> DecodeTickbytickOrderMarketDataExtensionFields(bytes)
              [] tag = TickbytickOrderMarketDataExtensionFieldsCode3 -> DecodeTickbytickOrderMarketDataExtensionFields(bytes)
              [] tag = TickbytickOrderMarketDataExtensionFieldsCode4 -> DecodeTickbytickOrderMarketDataExtensionFields(bytes)
              [] tag = TickbytickOrderMarketDataExtensionFieldsCode5 -> DecodeTickbytickOrderMarketDataExtensionFields(bytes)
              [] tag = TickbytickOrderMarketDataExtensionFieldsCode6 -> DecodeTickbytickOrderMarketDataExtensionFields(bytes)
              [] tag = TickbytickTradeMarketDataExtensionFieldsCode -> DecodeTickbytickTradeMarketDataExtensionFields(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTickbytickMarketDataMessageExtendfields == [tag |-> TickbytickOrderMarketDataExtensionFieldsCode, body |-> ZeroTickbytickOrderMarketDataExtensionFields]

(* Each Tick-by-Tick Market Data Message ExtendFields in turn, at the values the message it names is checked at *)
CheckedTickbytickMarketDataMessageExtendfields ==
    { [tag |-> TickbytickOrderMarketDataExtensionFieldsCode, body |-> one] : one \in CheckedTickbytickOrderMarketDataExtensionFields }
        \cup { [tag |-> TickbytickOrderMarketDataExtensionFieldsCode2, body |-> one] : one \in CheckedTickbytickOrderMarketDataExtensionFields }
        \cup { [tag |-> TickbytickOrderMarketDataExtensionFieldsCode3, body |-> one] : one \in CheckedTickbytickOrderMarketDataExtensionFields }
        \cup { [tag |-> TickbytickOrderMarketDataExtensionFieldsCode4, body |-> one] : one \in CheckedTickbytickOrderMarketDataExtensionFields }
        \cup { [tag |-> TickbytickOrderMarketDataExtensionFieldsCode5, body |-> one] : one \in CheckedTickbytickOrderMarketDataExtensionFields }
        \cup { [tag |-> TickbytickOrderMarketDataExtensionFieldsCode6, body |-> one] : one \in CheckedTickbytickOrderMarketDataExtensionFields }
        \cup { [tag |-> TickbytickTradeMarketDataExtensionFieldsCode, body |-> one] : one \in CheckedTickbytickTradeMarketDataExtensionFields }

(***************************************************************************)
(* Tick-by-Tick Market Data Message                                        *)
(***************************************************************************)

TickbytickMarketDataMessage ==
    [ tickbytickMarketDataMessageSecuritytype : Sample(1),
      tickbytickMarketDataMessageChannelno    : Sample(2),
      applseqnum                              : Sample(8),
      securityid                              : Sample(8),
      transacttime                            : Sample(4),
      exectype                                : Sample(1),
      price                                   : Sample(8),
      orderqty                                : Sample(8),
      tickbytickMarketDataMessageExtendfields : TickbytickMarketDataMessageExtendfields ]

EncodeTickbytickMarketDataMessage(message) ==
    message.tickbytickMarketDataMessageSecuritytype
        \o message.tickbytickMarketDataMessageChannelno
        \o message.applseqnum
        \o message.tickbytickMarketDataMessageExtendfields.tag
        \o message.securityid
        \o message.transacttime
        \o message.exectype
        \o message.price
        \o message.orderqty
        \o EncodeTickbytickMarketDataMessageExtendfields(message.tickbytickMarketDataMessageExtendfields)

DecodeTickbytickMarketDataMessage(bytes) ==
    LET tickbytickMarketDataMessageSecuritytype == ReadBytes(bytes, 1) IN IF ~tickbytickMarketDataMessageSecuritytype.ok THEN Fail ELSE
    LET tickbytickMarketDataMessageChannelno == ReadBytes(tickbytickMarketDataMessageSecuritytype.rest, 2) IN IF ~tickbytickMarketDataMessageChannelno.ok THEN Fail ELSE
    LET applseqnum == ReadBytes(tickbytickMarketDataMessageChannelno.rest, 8) IN IF ~applseqnum.ok THEN Fail ELSE
    LET mdstreamid == ReadBytes(applseqnum.rest, 5) IN IF ~mdstreamid.ok THEN Fail ELSE
    LET securityid == ReadBytes(mdstreamid.rest, 8) IN IF ~securityid.ok THEN Fail ELSE
    LET transacttime == ReadBytes(securityid.rest, 4) IN IF ~transacttime.ok THEN Fail ELSE
    LET exectype == ReadBytes(transacttime.rest, 1) IN IF ~exectype.ok THEN Fail ELSE
    LET price == ReadBytes(exectype.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderqty == ReadBytes(price.rest, 8) IN IF ~orderqty.ok THEN Fail ELSE
    LET tickbytickMarketDataMessageExtendfields == DecodeTickbytickMarketDataMessageExtendfields(mdstreamid.value, orderqty.rest) IN IF ~tickbytickMarketDataMessageExtendfields.ok THEN Fail ELSE
    Ok([ tickbytickMarketDataMessageSecuritytype |-> tickbytickMarketDataMessageSecuritytype.value,
         tickbytickMarketDataMessageChannelno    |-> tickbytickMarketDataMessageChannelno.value,
         applseqnum                              |-> applseqnum.value,
         securityid                              |-> securityid.value,
         transacttime                            |-> transacttime.value,
         exectype                                |-> exectype.value,
         price                                   |-> price.value,
         orderqty                                |-> orderqty.value,
         tickbytickMarketDataMessageExtendfields |-> tickbytickMarketDataMessageExtendfields.value ], tickbytickMarketDataMessageExtendfields.rest)

ZeroTickbytickMarketDataMessage ==
    [ tickbytickMarketDataMessageSecuritytype |-> [i \in 1 .. 1 |-> 0],
      tickbytickMarketDataMessageChannelno    |-> [i \in 1 .. 2 |-> 0],
      applseqnum                              |-> [i \in 1 .. 8 |-> 0],
      securityid                              |-> [i \in 1 .. 8 |-> 0],
      transacttime                            |-> [i \in 1 .. 4 |-> 0],
      exectype                                |-> [i \in 1 .. 1 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      orderqty                                |-> [i \in 1 .. 8 |-> 0],
      tickbytickMarketDataMessageExtendfields |-> ZeroTickbytickMarketDataMessageExtendfields ]

(* Tick-by-Tick Market Data Message at zero, then each field in turn at the values it is checked at *)
CheckedTickbytickMarketDataMessage ==
    { ZeroTickbytickMarketDataMessage }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.tickbytickMarketDataMessageSecuritytype = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.tickbytickMarketDataMessageChannelno = one] : one \in Sample(2) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.applseqnum = one] : one \in Sample(8) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.securityid = one] : one \in Sample(8) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.transacttime = one] : one \in Sample(4) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.exectype = one] : one \in Sample(1) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.orderqty = one] : one \in Sample(8) }
        \cup { [ZeroTickbytickMarketDataMessage EXCEPT !.tickbytickMarketDataMessageExtendfields = one] : one \in CheckedTickbytickMarketDataMessageExtendfields }

(***************************************************************************)
(* Message Body, selected by MsgType                                       *)
(***************************************************************************)

LogonMessageCode == 1395666993  \* "S001"
LogoutMessageCode == 1395666994  \* "S002"
HeartbeatMessageCode == 1395666995  \* "S003"
ChannelHeartbeatCode == 1345335345  \* "P001"
RetransmissionMessageCode == 1345335346  \* "P002"
MarketStatusMessageCode == 1295069233  \* "M101"
MarketDataSnapshotMessageCode == 1295069234  \* "M102"
TickbytickMarketDataMessageCode == 1295134769  \* "M201"

MessageBody ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ChannelHeartbeatCode}, body : ChannelHeartbeat ]
        \cup [ tag : {RetransmissionMessageCode}, body : RetransmissionMessage ]
        \cup [ tag : {MarketStatusMessageCode}, body : MarketStatusMessage ]
        \cup [ tag : {MarketDataSnapshotMessageCode}, body : MarketDataSnapshotMessage ]
        \cup [ tag : {TickbytickMarketDataMessageCode}, body : TickbytickMarketDataMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = ChannelHeartbeatCode -> EncodeChannelHeartbeat(message.body)
      [] message.tag = RetransmissionMessageCode -> EncodeRetransmissionMessage(message.body)
      [] message.tag = MarketStatusMessageCode -> EncodeMarketStatusMessage(message.body)
      [] message.tag = MarketDataSnapshotMessageCode -> EncodeMarketDataSnapshotMessage(message.body)
      [] message.tag = TickbytickMarketDataMessageCode -> EncodeTickbytickMarketDataMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ChannelHeartbeatCode -> DecodeChannelHeartbeat(bytes)
              [] tag = RetransmissionMessageCode -> DecodeRetransmissionMessage(bytes)
              [] tag = MarketStatusMessageCode -> DecodeMarketStatusMessage(bytes)
              [] tag = MarketDataSnapshotMessageCode -> DecodeMarketDataSnapshotMessage(bytes)
              [] tag = TickbytickMarketDataMessageCode -> DecodeTickbytickMarketDataMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ChannelHeartbeatCode, body |-> one] : one \in CheckedChannelHeartbeat }
        \cup { [tag |-> RetransmissionMessageCode, body |-> one] : one \in CheckedRetransmissionMessage }
        \cup { [tag |-> MarketStatusMessageCode, body |-> one] : one \in CheckedMarketStatusMessage }
        \cup { [tag |-> MarketDataSnapshotMessageCode, body |-> one] : one \in CheckedMarketDataSnapshotMessage }
        \cup { [tag |-> TickbytickMarketDataMessageCode, body |-> one] : one \in CheckedTickbytickMarketDataMessage }

(***************************************************************************)
(* Standard Trailer: 4 bytes                                               *)
(***************************************************************************)

StandardTrailer ==
    [ checksum : Sample(4) ]

EncodeStandardTrailer(message) ==
    message.checksum

DecodeStandardTrailer(bytes) ==
    LET checksum == ReadBytes(bytes, 4) IN IF ~checksum.ok THEN Fail ELSE
    Ok([ checksum |-> checksum.value ], checksum.rest)

ZeroStandardTrailer ==
    [ checksum |-> [i \in 1 .. 4 |-> 0] ]

(* Standard Trailer at zero, then each field in turn at the values it is checked at *)
CheckedStandardTrailer ==
    { ZeroStandardTrailer }
        \cup { [ZeroStandardTrailer EXCEPT !.checksum = one] : one \in Sample(4) }

(***************************************************************************)
(* Binary Message, framed by BodyLength                                    *)
(***************************************************************************)

BinaryMessage ==
    [ sendingtime     : Sample(8),
      msgseqnum       : Sample(8),
      messageBody     : MessageBody,
      standardTrailer : StandardTrailer ]

EncodeBinaryMessageBody(message) ==
    EncodeMessageBody(message.messageBody)
        \o EncodeStandardTrailer(message.standardTrailer)

(* BodyLength counts the bytes it frames, so it is written from them *)
EncodeBinaryMessage(message) ==
    LET body == EncodeBinaryMessageBody(message)
    IN  EncodeUIntBE(message.messageBody.tag, 4) \o message.sendingtime \o message.msgseqnum \o EncodeUIntBE(Len(body) - 4, 4) \o body

DecodeBinaryMessage(bytes) ==
    LET msgtype == ReadUIntBE(bytes, 4) IN IF ~msgtype.ok THEN Fail ELSE
    LET sendingtime == ReadBytes(msgtype.rest, 8) IN IF ~sendingtime.ok THEN Fail ELSE
    LET msgseqnum == ReadBytes(sendingtime.rest, 8) IN IF ~msgseqnum.ok THEN Fail ELSE
    LET length == ReadUIntBE(msgseqnum.rest, 4) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET messageBody == DecodeMessageBody(msgtype.value, framed) IN IF ~messageBody.ok THEN Fail ELSE
    LET standardTrailer == DecodeStandardTrailer(messageBody.rest) IN IF ~standardTrailer.ok THEN Fail ELSE
    IF standardTrailer.rest # << >> THEN Fail ELSE
    Ok([ sendingtime     |-> sendingtime.value,
         msgseqnum       |-> msgseqnum.value,
         messageBody     |-> messageBody.value,
         standardTrailer |-> standardTrailer.value ], beyond)

ZeroBinaryMessage ==
    [ sendingtime     |-> [i \in 1 .. 8 |-> 0],
      msgseqnum       |-> [i \in 1 .. 8 |-> 0],
      messageBody     |-> ZeroMessageBody,
      standardTrailer |-> ZeroStandardTrailer ]

(* Binary Message at zero, then each field in turn at the values it is checked at *)
CheckedBinaryMessage ==
    { ZeroBinaryMessage }
        \cup { [ZeroBinaryMessage EXCEPT !.sendingtime = one] : one \in Sample(8) }
        \cup { [ZeroBinaryMessage EXCEPT !.msgseqnum = one] : one \in Sample(8) }
        \cup { [ZeroBinaryMessage EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroBinaryMessage EXCEPT !.standardTrailer = one] : one \in CheckedStandardTrailer }

(* A run of Binary Message, written one after another *)
RECURSIVE EncodeBinaryMessageList(_)
EncodeBinaryMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBinaryMessage(Head(messages)) \o EncodeBinaryMessageList(Tail(messages))

(* As many Binary Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadBinaryMessageAll(_)
ReadBinaryMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeBinaryMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBinaryMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Binary Message of each kind, for the lists that carry them *)
OneBinaryMessage ==
    { [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> ChannelHeartbeatCode, body |-> ZeroChannelHeartbeat]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> RetransmissionMessageCode, body |-> ZeroRetransmissionMessage]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> MarketStatusMessageCode, body |-> ZeroMarketStatusMessage]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> MarketDataSnapshotMessageCode, body |-> ZeroMarketDataSnapshotMessage]],
      [ZeroBinaryMessage EXCEPT !.messageBody = [tag |-> TickbytickMarketDataMessageCode, body |-> ZeroTickbytickMarketDataMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ binaryMessage : SampleLists(OneBinaryMessage) ]

EncodePacket(message) ==
    EncodeBinaryMessageList(message.binaryMessage)

DecodePacket(bytes) ==
    LET binaryMessage == ReadBinaryMessageAll(bytes) IN IF ~binaryMessage.ok THEN Fail ELSE
    Ok([ binaryMessage |-> binaryMessage.value ], binaryMessage.rest)

ZeroPacket ==
    [ binaryMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.binaryMessage = one] : one \in SampleLists(OneBinaryMessage) }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channel Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripChannelHeartbeat ==
    \A message \in CheckedChannelHeartbeat :
        LET read == DecodeChannelHeartbeat(EncodeChannelHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionMessage ==
    \A message \in CheckedRetransmissionMessage :
        LET read == DecodeRetransmissionMessage(EncodeRetransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatusMessage ==
    \A message \in CheckedMarketStatusMessage :
        LET read == DecodeMarketStatusMessage(EncodeMarketStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Market Data Snapshot Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMarketDataSnapshotEntries ==
    \A message \in CheckedIndexMarketDataSnapshotEntries :
        LET read == DecodeIndexMarketDataSnapshotEntries(EncodeIndexMarketDataSnapshotEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Market Data Snapshot Extension Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMarketDataSnapshotExtensionFields ==
    \A message \in CheckedIndexMarketDataSnapshotExtensionFields :
        LET read == DecodeIndexMarketDataSnapshotExtensionFields(EncodeIndexMarketDataSnapshotExtensionFields(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Snapshot Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataSnapshotEntries ==
    \A message \in CheckedMarketDataSnapshotEntries :
        LET read == DecodeMarketDataSnapshotEntries(EncodeMarketDataSnapshotEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Snapshot Extension Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataSnapshotExtensionFields ==
    \A message \in CheckedMarketDataSnapshotExtensionFields :
        LET read == DecodeMarketDataSnapshotExtensionFields(EncodeMarketDataSnapshotExtensionFields(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataSnapshotMessage ==
    \A message \in CheckedMarketDataSnapshotMessage :
        LET read == DecodeMarketDataSnapshotMessage(EncodeMarketDataSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick-by-Tick Order Market Data Extension Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripTickbytickOrderMarketDataExtensionFields ==
    \A message \in CheckedTickbytickOrderMarketDataExtensionFields :
        LET read == DecodeTickbytickOrderMarketDataExtensionFields(EncodeTickbytickOrderMarketDataExtensionFields(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick-by-Tick Trade Market Data Extension Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripTickbytickTradeMarketDataExtensionFields ==
    \A message \in CheckedTickbytickTradeMarketDataExtensionFields :
        LET read == DecodeTickbytickTradeMarketDataExtensionFields(EncodeTickbytickTradeMarketDataExtensionFields(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick-by-Tick Market Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickbytickMarketDataMessage ==
    \A message \in CheckedTickbytickMarketDataMessage :
        LET read == DecodeTickbytickMarketDataMessage(EncodeTickbytickMarketDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Standard Trailer decodes back to what was encoded, and leaves nothing over *)
RoundTripStandardTrailer ==
    \A message \in CheckedStandardTrailer :
        LET read == DecodeStandardTrailer(EncodeStandardTrailer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Binary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBinaryMessage ==
    \A message \in CheckedBinaryMessage :
        LET read == DecodeBinaryMessage(EncodeBinaryMessage(message))
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

(* A Market Data Snapshot Message ExtendFields is selected by the MDStreamID it is written under *)
SelectsMarketDataSnapshotMessageExtendfields ==
    \A message \in CheckedMarketDataSnapshotMessageExtendfields :
        LET sent == EncodeMarketDataSnapshotMessageExtendfields(message)
            read == DecodeMarketDataSnapshotMessageExtendfields(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Tick-by-Tick Market Data Message ExtendFields is selected by the MDStreamID it is written under *)
SelectsTickbytickMarketDataMessageExtendfields ==
    \A message \in CheckedTickbytickMarketDataMessageExtendfields :
        LET sent == EncodeTickbytickMarketDataMessageExtendfields(message)
            read == DecodeTickbytickMarketDataMessageExtendfields(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Body is selected by the MsgType it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET sent == EncodeMessageBody(message)
            read == DecodeMessageBody(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* BodyLength is written from the bytes it frames *)
FramesBinaryMessage ==
    \A message \in CheckedBinaryMessage :
        LET bytes == EncodeBinaryMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 21, 24)) = Len(bytes) - 28

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
