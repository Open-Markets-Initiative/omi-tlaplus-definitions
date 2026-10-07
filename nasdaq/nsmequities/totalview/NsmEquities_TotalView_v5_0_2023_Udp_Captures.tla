----------- MODULE NsmEquities_TotalView_v5_0_2023_Udp_Captures ------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v5.0.2023 packets, as the bytes they *)
(* were captured as. Each one decodes, consumes the whole packet, and      *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS NsmEquities_TotalView_v5_0_2023_Udp

AddOrderNoMpidAttributionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 21, 152, 0, 0, 31, 26, 206, 216, 83,
       6, 0, 0, 0, 0, 1, 102, 181, 62, 66, 0, 0, 6, 64, 73, 86,
       79, 79, 32, 32, 32, 32, 0, 13, 85, 172 >>

AddOrderNoMpidAttributionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 33, 106, 0, 0, 31, 26, 206, 216, 160,
       240, 0, 0, 0, 0, 1, 69, 243, 11, 83, 0, 0, 0, 100, 82, 69,
       84, 76, 32, 32, 32, 32, 0, 1, 24, 20 >>

AddOrderNoMpidAttributionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 43, 104, 0, 0, 31, 26, 206, 217, 117,
       101, 0, 0, 0, 0, 2, 8, 97, 248, 83, 0, 0, 0, 100, 88, 76,
       70, 32, 32, 32, 32, 32, 0, 5, 46, 44 >>

AddOrderNoMpidAttributionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 43, 104, 0, 0, 31, 26, 206, 217, 173,
       9, 0, 0, 0, 0, 2, 8, 98, 4, 83, 0, 0, 15, 160, 88, 76,
       70, 32, 32, 32, 32, 32, 0, 5, 46, 44 >>

AddOrderNoMpidAttributionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 38, 23, 0, 0, 31, 26, 206, 219, 59,
       223, 0, 0, 0, 0, 2, 8, 98, 20, 83, 0, 0, 0, 200, 84, 32,
       32, 32, 32, 32, 32, 32, 0, 2, 39, 244 >>

AddOrderWithMpidAttributionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 6, 202, 0, 0, 31, 26, 206, 217, 153,
       54, 0, 0, 0, 0, 1, 32, 190, 117, 83, 0, 0, 0, 100, 67, 65,
       83, 89, 32, 32, 32, 32, 0, 38, 253, 64, 70, 76, 84, 85 >>

AddOrderWithMpidAttributionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 39, 193, 0, 0, 31, 26, 206, 219, 78,
       78, 0, 0, 0, 0, 2, 8, 98, 44, 83, 0, 0, 0, 100, 84, 83,
       86, 84, 32, 32, 32, 32, 0, 1, 2, 52, 70, 76, 84, 85 >>

AddOrderWithMpidAttributionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 12, 91, 0, 0, 31, 26, 206, 219, 112,
       21, 0, 0, 0, 0, 1, 102, 181, 250, 83, 0, 0, 3, 32, 69, 73,
       68, 79, 32, 32, 32, 32, 0, 3, 162, 120, 71, 83, 67, 79 >>

AddOrderWithMpidAttributionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 32, 170, 0, 0, 31, 26, 206, 220, 64,
       54, 0, 0, 0, 0, 1, 69, 243, 55, 83, 0, 0, 0, 100, 81, 76,
       89, 83, 32, 32, 32, 32, 0, 24, 128, 168, 70, 76, 84, 85 >>

AddOrderWithMpidAttributionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 41, 40, 0, 0, 31, 26, 206, 220, 223,
       147, 0, 0, 0, 0, 2, 8, 98, 156, 83, 0, 0, 0, 100, 86, 67,
       89, 84, 32, 32, 32, 32, 0, 4, 133, 208, 70, 76, 84, 85 >>

CrossTradeMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 81, 3, 215, 0, 1, 31, 26, 206, 225, 80,
       3, 0, 0, 0, 0, 0, 0, 0, 0, 66, 65, 67, 45, 81, 32, 32,
       32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 230, 62, 79 >>

CrossTradeMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 81, 16, 138, 0, 1, 31, 26, 206, 227, 227,
       27, 0, 0, 0, 0, 0, 0, 0, 0, 71, 67, 86, 32, 32, 32, 32,
       32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 230, 65, 79 >>

CrossTradeMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 81, 32, 39, 0, 2, 31, 26, 206, 229, 220,
       135, 0, 0, 0, 0, 0, 0, 21, 201, 80, 84, 71, 88, 32, 32, 32,
       32, 0, 2, 252, 16, 0, 0, 0, 0, 0, 3, 230, 73, 79 >>

CrossTradeMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 81, 5, 102, 0, 1, 31, 26, 206, 230, 20,
       37, 0, 0, 0, 0, 0, 0, 0, 0, 66, 78, 69, 68, 32, 32, 32,
       32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 230, 74, 79 >>

CrossTradeMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 81, 19, 228, 0, 2, 31, 26, 206, 235, 176,
       59, 0, 0, 0, 0, 0, 0, 21, 3, 73, 66, 84, 71, 32, 32, 32,
       32, 0, 3, 110, 32, 0, 0, 0, 0, 0, 3, 230, 94, 79 >>

LuldAuctionCollarMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 74, 44, 61, 0, 0, 31, 30, 112, 59, 79,
       149, 90, 88, 90, 90, 84, 32, 32, 32, 0, 2, 9, 24, 0, 2, 35,
       68, 0, 1, 170, 144, 0, 0, 0, 0 >>

LuldAuctionCollarMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 74, 44, 56, 0, 0, 31, 30, 154, 138, 209,
       241, 90, 86, 90, 90, 84, 32, 32, 32, 0, 4, 31, 120, 0, 5, 9,
       216, 0, 3, 234, 188, 0, 0, 0, 0 >>

LuldAuctionCollarMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 74, 24, 141, 0, 0, 31, 36, 125, 104, 225,
       141, 76, 84, 82, 89, 32, 32, 32, 32, 0, 0, 149, 56, 0, 0, 156,
       164, 0, 0, 121, 224, 0, 0, 0, 0 >>

LuldAuctionCollarMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 74, 35, 186, 0, 0, 31, 51, 122, 86, 99,
       252, 83, 72, 76, 84, 32, 32, 32, 32, 0, 1, 51, 208, 0, 1, 67,
       12, 0, 0, 251, 144, 0, 0, 0, 0 >>

LuldAuctionCollarMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 74, 44, 56, 0, 0, 31, 100, 116, 6, 108,
       246, 90, 86, 90, 90, 84, 32, 32, 32, 0, 4, 31, 120, 0, 5, 9,
       216, 0, 3, 182, 0, 0, 0, 0, 1 >>

MarketParticipantPositionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 26, 76, 14, 64, 0, 0, 31, 32, 129, 66, 248,
       70, 77, 65, 88, 77, 70, 68, 76, 83, 32, 32, 32, 32, 89, 78, 65 >>

MarketParticipantPositionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 26, 76, 14, 147, 0, 0, 31, 32, 130, 218, 248,
       45, 77, 65, 88, 77, 70, 71, 77, 67, 32, 32, 32, 32, 89, 78, 65 >>

MarketParticipantPositionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 26, 76, 14, 2, 0, 0, 31, 54, 240, 208, 138,
       118, 82, 73, 76, 89, 70, 66, 73, 79, 32, 32, 32, 32, 89, 78, 69 >>

MarketParticipantPositionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 26, 76, 38, 40, 0, 0, 31, 82, 44, 24, 242,
       11, 78, 73, 84, 69, 84, 65, 78, 32, 32, 32, 32, 32, 89, 78, 69 >>

MarketParticipantPositionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 26, 76, 38, 40, 0, 0, 31, 83, 154, 59, 109,
       123, 86, 73, 82, 84, 84, 65, 78, 32, 32, 32, 32, 32, 89, 78, 69 >>

NetOrderImbalanceIndicatorMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 50, 73, 30, 173, 0, 0, 31, 26, 206, 219, 67,
       241, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 79, 80, 70, 84, 65, 87, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 79, 32 >>

NetOrderImbalanceIndicatorMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 50, 73, 16, 220, 0, 0, 31, 26, 206, 219, 75,
       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 79, 71, 70, 79, 82, 61, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 79, 32 >>

NetOrderImbalanceIndicatorMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 50, 73, 26, 3, 0, 0, 31, 26, 206, 219, 87,
       213, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 79, 77, 77, 77, 32, 32, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 79, 32 >>

NetOrderImbalanceIndicatorMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 50, 73, 25, 62, 0, 0, 31, 26, 206, 222, 10,
       178, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
       0, 78, 77, 68, 67, 32, 32, 32, 32, 32, 0, 7, 22, 16, 0, 7,
       22, 16, 0, 7, 22, 16, 79, 76 >>

NetOrderImbalanceIndicatorMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 50, 73, 36, 12, 0, 0, 31, 26, 206, 224, 7,
       43, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
       0, 78, 83, 75, 79, 82, 32, 32, 32, 32, 0, 7, 15, 108, 0, 7,
       15, 108, 0, 7, 15, 108, 79, 76 >>

NonCrossTradeMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 17, 147, 0, 2, 31, 26, 206, 228, 98,
       169, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 100, 71, 79,
       79, 71, 76, 32, 32, 32, 0, 19, 153, 248, 0, 0, 0, 0, 0, 3,
       230, 66 >>

NonCrossTradeMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 26, 200, 0, 2, 31, 26, 206, 232, 195,
       220, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 14, 77, 85,
       32, 32, 32, 32, 32, 32, 0, 9, 212, 4, 0, 0, 0, 0, 0, 3,
       230, 81 >>

NonCrossTradeMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 32, 135, 0, 2, 31, 26, 206, 233, 16,
       11, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 27, 81, 67,
       79, 77, 32, 32, 32, 32, 0, 17, 4, 164, 0, 0, 0, 0, 0, 3,
       230, 83 >>

NonCrossTradeMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 2, 237, 0, 2, 31, 26, 206, 233, 38,
       188, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 2, 65, 83,
       77, 76, 32, 32, 32, 32, 0, 103, 175, 192, 0, 0, 0, 0, 0, 3,
       230, 85 >>

NonCrossTradeMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 2, 237, 0, 4, 31, 26, 206, 233, 38,
       188, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 4, 65, 83,
       77, 76, 32, 32, 32, 32, 0, 103, 175, 192, 0, 0, 0, 0, 0, 3,
       230, 86 >>

OrderCancelMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 36, 197, 0, 0, 31, 26, 206, 254, 120,
       93, 0, 0, 0, 0, 2, 4, 26, 0, 0, 0, 0, 100 >>

OrderCancelMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 17, 147, 0, 0, 31, 26, 206, 255, 139,
       155, 0, 0, 0, 0, 1, 102, 163, 138, 0, 0, 0, 100 >>

OrderCancelMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 41, 140, 0, 0, 31, 26, 207, 10, 239,
       18, 0, 0, 0, 0, 2, 8, 17, 156, 0, 0, 0, 200 >>

OrderCancelMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 25, 85, 0, 0, 31, 26, 207, 67, 63,
       189, 0, 0, 0, 0, 1, 68, 102, 199, 0, 0, 7, 208 >>

OrderCancelMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 3, 205, 0, 0, 31, 26, 207, 71, 104,
       9, 0, 0, 0, 0, 1, 32, 105, 157, 0, 0, 0, 200 >>

OrderDeleteMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 13, 25, 0, 0, 31, 26, 206, 216, 64,
       237, 0, 0, 0, 0, 1, 101, 181, 26 >>

OrderDeleteMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 13, 25, 0, 0, 31, 26, 206, 216, 65,
       186, 0, 0, 0, 0, 1, 101, 171, 42 >>

OrderDeleteMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 13, 189, 0, 0, 31, 26, 206, 216, 90,
       216, 0, 0, 0, 0, 1, 102, 139, 214 >>

OrderDeleteMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 4, 85, 0, 0, 31, 26, 206, 216, 155,
       61, 0, 0, 0, 0, 1, 32, 125, 21 >>

OrderDeleteMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 29, 75, 0, 0, 31, 26, 206, 216, 184,
       243, 0, 0, 0, 0, 1, 69, 231, 39 >>

OrderExecutedMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 9, 41, 0, 2, 31, 26, 206, 216, 240,
       97, 0, 0, 0, 0, 1, 102, 146, 154, 0, 0, 0, 25, 0, 0, 0,
       0, 0, 3, 230, 59 >>

OrderExecutedMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 37, 37, 0, 2, 31, 26, 206, 224, 23,
       90, 0, 0, 0, 0, 2, 7, 173, 224, 0, 0, 7, 208, 0, 0, 0,
       0, 0, 3, 230, 60 >>

OrderExecutedMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 37, 37, 0, 4, 31, 26, 206, 224, 23,
       90, 0, 0, 0, 0, 2, 7, 206, 236, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 3, 230, 61 >>

OrderExecutedMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 2, 96, 0, 2, 31, 26, 206, 225, 130,
       80, 0, 0, 0, 0, 1, 32, 181, 245, 0, 0, 0, 1, 0, 0, 0,
       0, 0, 3, 230, 63 >>

OrderExecutedMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 43, 206, 0, 2, 31, 26, 206, 226, 147,
       200, 0, 0, 0, 0, 1, 154, 81, 168, 0, 0, 2, 187, 0, 0, 0,
       0, 0, 3, 230, 64 >>

OrderExecutedWithPriceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 19, 228, 0, 1, 31, 26, 206, 235, 176,
       59, 0, 0, 0, 0, 1, 49, 19, 222, 0, 0, 19, 62, 0, 0, 0,
       0, 0, 3, 230, 93, 78, 0, 3, 110, 32 >>

OrderExecutedWithPriceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 43, 225, 0, 1, 31, 26, 206, 243, 40,
       82, 0, 0, 0, 0, 0, 154, 178, 56, 0, 0, 0, 4, 0, 0, 0,
       0, 0, 3, 230, 138, 78, 0, 0, 33, 52 >>

OrderExecutedWithPriceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 37, 37, 0, 2, 31, 26, 207, 78, 37,
       17, 0, 0, 0, 0, 2, 8, 104, 232, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 3, 232, 56, 89, 0, 67, 81, 52 >>

OrderExecutedWithPriceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 37, 37, 0, 4, 31, 26, 207, 78, 37,
       17, 0, 0, 0, 0, 2, 8, 109, 184, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 3, 232, 57, 89, 0, 67, 81, 52 >>

OrderExecutedWithPriceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 23, 115, 0, 2, 31, 26, 207, 88, 19,
       108, 0, 0, 0, 0, 1, 69, 255, 39, 0, 0, 0, 72, 0, 0, 0,
       0, 0, 3, 232, 74, 89, 0, 0, 189, 116 >>

OrderReplaceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 29, 179, 0, 0, 31, 26, 206, 215, 113,
       233, 0, 0, 0, 0, 0, 230, 137, 127, 0, 0, 0, 0, 1, 69, 242,
       199, 0, 0, 0, 100, 0, 16, 54, 200 >>

OrderReplaceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 29, 179, 0, 0, 31, 26, 206, 215, 123,
       228, 0, 0, 0, 0, 0, 230, 137, 135, 0, 0, 0, 0, 1, 69, 242,
       203, 0, 0, 0, 100, 0, 16, 54, 200 >>

OrderReplaceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 29, 179, 0, 0, 31, 26, 206, 215, 126,
       9, 0, 0, 0, 0, 0, 230, 137, 131, 0, 0, 0, 0, 1, 69, 242,
       207, 0, 0, 0, 100, 0, 16, 54, 200 >>

OrderReplaceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 14, 125, 0, 0, 31, 26, 206, 215, 136,
       231, 0, 0, 0, 0, 1, 94, 193, 46, 0, 0, 0, 0, 1, 102, 181,
       54, 0, 0, 0, 100, 0, 24, 160, 176 >>

OrderReplaceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 1, 54, 0, 0, 31, 26, 206, 215, 175,
       140, 0, 0, 0, 0, 1, 21, 135, 177, 0, 0, 0, 0, 1, 32, 190,
       101, 0, 0, 0, 100, 0, 3, 80, 212 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 36, 189, 0, 0, 31, 26, 213, 204, 24,
       183, 83, 79, 80, 65, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 8, 234, 0, 0, 31, 26, 215, 216, 10,
       57, 67, 80, 72, 73, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 9, 149, 0, 0, 31, 26, 216, 42, 254,
       48, 67, 85, 69, 78, 87, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 26, 150, 0, 0, 31, 26, 216, 46, 11,
       244, 77, 83, 71, 77, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 43, 195, 0, 0, 31, 26, 216, 124, 72,
       40, 89, 67, 66, 68, 45, 65, 32, 32, 49 >>

StockTradingActionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 44, 61, 0, 0, 31, 30, 112, 54, 228,
       101, 90, 88, 90, 90, 84, 32, 32, 32, 80, 32, 76, 85, 68, 80 >>

StockTradingActionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 44, 56, 0, 0, 31, 30, 154, 136, 37,
       233, 90, 86, 90, 90, 84, 32, 32, 32, 80, 32, 76, 85, 68, 80 >>

StockTradingActionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 6, 171, 0, 0, 31, 31, 154, 167, 91,
       182, 67, 65, 77, 76, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 24, 141, 0, 0, 31, 36, 125, 101, 211,
       150, 76, 84, 82, 89, 32, 32, 32, 32, 80, 32, 76, 85, 68, 80 >>

StockTradingActionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 9, 74, 0, 0, 31, 40, 249, 201, 190,
       155, 67, 83, 77, 68, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

SystemEventMessageCapture ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 12, 83, 0, 0, 0, 0, 31, 26, 206, 219, 2,
       240, 81 >>

Captures == { AddOrderNoMpidAttributionMessageCapture1, AddOrderNoMpidAttributionMessageCapture2, AddOrderNoMpidAttributionMessageCapture3, AddOrderNoMpidAttributionMessageCapture4, AddOrderNoMpidAttributionMessageCapture5, AddOrderWithMpidAttributionMessageCapture1, AddOrderWithMpidAttributionMessageCapture2, AddOrderWithMpidAttributionMessageCapture3, AddOrderWithMpidAttributionMessageCapture4, AddOrderWithMpidAttributionMessageCapture5, CrossTradeMessageCapture1, CrossTradeMessageCapture2, CrossTradeMessageCapture3, CrossTradeMessageCapture4, CrossTradeMessageCapture5, LuldAuctionCollarMessageCapture1, LuldAuctionCollarMessageCapture2, LuldAuctionCollarMessageCapture3, LuldAuctionCollarMessageCapture4, LuldAuctionCollarMessageCapture5, MarketParticipantPositionMessageCapture1, MarketParticipantPositionMessageCapture2, MarketParticipantPositionMessageCapture3, MarketParticipantPositionMessageCapture4, MarketParticipantPositionMessageCapture5, NetOrderImbalanceIndicatorMessageCapture1, NetOrderImbalanceIndicatorMessageCapture2, NetOrderImbalanceIndicatorMessageCapture3, NetOrderImbalanceIndicatorMessageCapture4, NetOrderImbalanceIndicatorMessageCapture5, NonCrossTradeMessageCapture1, NonCrossTradeMessageCapture2, NonCrossTradeMessageCapture3, NonCrossTradeMessageCapture4, NonCrossTradeMessageCapture5, OrderCancelMessageCapture1, OrderCancelMessageCapture2, OrderCancelMessageCapture3, OrderCancelMessageCapture4, OrderCancelMessageCapture5, OrderDeleteMessageCapture1, OrderDeleteMessageCapture2, OrderDeleteMessageCapture3, OrderDeleteMessageCapture4, OrderDeleteMessageCapture5, OrderExecutedMessageCapture1, OrderExecutedMessageCapture2, OrderExecutedMessageCapture3, OrderExecutedMessageCapture4, OrderExecutedMessageCapture5, OrderExecutedWithPriceMessageCapture1, OrderExecutedWithPriceMessageCapture2, OrderExecutedWithPriceMessageCapture3, OrderExecutedWithPriceMessageCapture4, OrderExecutedWithPriceMessageCapture5, OrderReplaceMessageCapture1, OrderReplaceMessageCapture2, OrderReplaceMessageCapture3, OrderReplaceMessageCapture4, OrderReplaceMessageCapture5, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture1, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture2, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture3, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture4, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture5, StockTradingActionMessageCapture1, StockTradingActionMessageCapture2, StockTradingActionMessageCapture3, StockTradingActionMessageCapture4, StockTradingActionMessageCapture5, SystemEventMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodePacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodePacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
