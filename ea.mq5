//+------------------------------------------------------------------+
//|                                                   BOTBV1.mq5     |
//|                                   Copyright 2026, Muhammad Aldhi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      "https://www.mql5.com"
#property version   "18.07"
#property strict

//--- Include Trade Library
#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
sinput string s0 = "========================================="; // ─── TRADING SETTINGS ───
input double   InpLots = 0.01;                  // Lot Awal
input int      InpMaxOpenPositions = 5;       // Maksimal Posisi Aktif (Max Layer)
input int      InpMinDistanceEntries = 1000;   // Jarak Minimal Antar Entry Layer Baru (Points)
input double   InpMaxAllowedSpread = 3.0;      // Max Allowed Spread (Dalam Pips)

sinput string s1 = "========================================="; // ─── SUPAPER TREND INDICATOR ───
input string   InpIndName = "SIGNAL BY ALWI";    // Nama Indikator Custom
input int      InpATRPeriod = 50;              // Periode ATR
input double   InpATREntry = 5.0;              // Multiplier ATR
input double   InmSinyalTren = 5.0;            // Nilai Sinyal Tren
input bool      InpAktifFilterGaris = true;      // Filter Arah Tren Utama

sinput string s2 = "========================================="; // ─── MARTINGALE SETTINGS ───
input bool      InpUseMartingale = false;       // Aktifkan Fitur Martingale (True/False)
input double   InpMartingaleMultiplier = 1.2;  // Faktor Pengali Lot Martingale
input double   InpMaxMartingaleLots = 0.05;     // Batas Maksimal Ukuran Lot Martingale
input int      InpMartingaleTriggerPoints = 1000; // Jarak Minus Terbuka Martingale (Points)

sinput string s3 = "========================================="; // ─── PROTECTION (STOP LOSS) ───
input int      InpSL = 3000;                    // Batas Maksimal Loss per Trade (Points)
input double   InpMaxLossCurrency = 15.0;       // Max Loss Gabungan Martingale ($)

sinput string s4 = "========================================="; // ─── AUTOMATIC TRAILING STOP ───
input bool      InpAktifTrailing = true;         // Aktifkan Fungsi Trailing Stop
input int      InpJarakTrailing = 400;          // Jarak Trailing Stop (Points)
input int      InpTrailingAktif = 800;          // Syarat Trailing Aktif (Points)

sinput string s4_2 = "========================================="; // ─── AVERAGE TRAILING MARTINGALE ───
input bool      InpAktifAvgTrailing = false;     // [NON-AKTIF / LOGIKA DIBUANG]
input int      InpJarakAvgTrailing = 400;       // Tidak Digunakan
input int      InpAvgTrailingAktif = 800;       // Tidak Digunakan
input double   InpMartingaleBEProfit = 1.00;    // Target Profit BE Cluster Martingale ($)

sinput string s5 = "========================================="; // ─── PROFIT & RISK MANAGEMENT ───
input bool      InpAktifTPPartial = false;       // Aktifkan Tutup Posisi Parsial 50%
input int      InpJarakTPPartial = 150;          // Jarak Target Profit TP Parsial
input bool      InpTargetProfitHarian = false;    // Batasi Target Maksimal Profit Harian
input double   InpTargetProfitMataUang = 100.0;  // Nilai Target Profit ($)
input bool      InpBatasRugiHarian = true;       // Batasi Maksimal Kerugian Harian
input double   InpBatasRugiMataUang = 5.0;       // Nilai Batas Rugi Harian

sinput string s6 = "========================================="; // ─── TIME FILTERS ───
input bool      InnGunakanFilterWaktu = false;   // Aktifkan Pembatasan Waktu Operasional

//--- Variabel Sinkronisasi Web
double current_Lots;
int    current_MaxOpenPositions;
int    current_MinDistanceEntries;
double current_MaxAllowedSpread; 
int    current_ATRPeriod;
double current_ATREntry;
bool    current_UseMartingale;
double current_MartingaleMultiplier;
double current_MaxMartingaleLots;
int    current_MartingaleTriggerPoints;
int    current_SL;
double current_MaxLossCurrency;
bool    current_AktifTrailing;
int    current_JarakTrailing;
int    current_TrailingAktif;
bool    current_AktifAvgTrailing;
int    current_JarakAvgTrailing;
int    current_AvgTrailingAktif;
double current_MartingaleBEProfit;
double current_TargetProfitMataUang;
bool    current_InpAktifFilterGaris;
double current_MartingaleLockBEPProfit; // Dapat di-update dinamis via web

//--- Global Variables
int handle_atr;
double BufferUp[];
double BufferDown[];
double BufferTrend[]; 
int magic_number = 123456;
datetime last_entry_time = 0;
bool is_emergency_paused = false;
double highest_avg_profit_points = 0;
bool martingale_lock_trailing = false; 
ulong locked_highest_ticket = 0; 
string global_web_status = "INITIALIZING";

// ID Label Dashboard Chart
string label_owner      = "DB_Owner";
string label_web_status = "DB_WebStatus"; 
string label_pair_tf    = "DB_PairTF";
string label_balance    = "DB_Balance";
string label_equity     = "DB_Equity";
string label_freemargin = "DB_FreeMargin";
string label_profit     = "DB_Profit";
string label_pips       = "DB_PipsMove";
string label_trend      = "DB_Trend";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   current_Lots = InpLots;
   current_MaxOpenPositions = InpMaxOpenPositions;
   current_MinDistanceEntries = InpMinDistanceEntries;
   current_MaxAllowedSpread = InpMaxAllowedSpread; 
   current_ATRPeriod = InpATRPeriod;
   current_ATREntry = InpATREntry;
   current_UseMartingale = InpUseMartingale;
   current_MartingaleMultiplier = InpMartingaleMultiplier;
   current_MaxMartingaleLots = InpMaxMartingaleLots;
   current_MartingaleTriggerPoints = InpMartingaleTriggerPoints;
   current_SL = InpSL;
   current_MaxLossCurrency = InpMaxLossCurrency;
   current_AktifTrailing = InpAktifTrailing;
   current_JarakTrailing = InpJarakTrailing;
   current_TrailingAktif = InpTrailingAktif;
   current_AktifAvgTrailing = InpAktifAvgTrailing;
   current_JarakAvgTrailing = InpJarakAvgTrailing;
   current_AvgTrailingAktif = InpAvgTrailingAktif;
   current_MartingaleBEProfit = InpMartingaleBEProfit;
   current_TargetProfitMataUang = InpTargetProfitMataUang;
   current_InpAktifFilterGaris = InpAktifFilterGaris;
   current_MartingaleLockBEPProfit = InpMartingaleBEProfit; // Default fallback mengikut input default
   
   is_emergency_paused = false;
   martingale_lock_trailing = false;
   locked_highest_ticket = 0;

   handle_atr = iATR(_Symbol, _Period, current_ATRPeriod);
   if(handle_atr == INVALID_HANDLE)
   {
      Print("Gagal membuat handle ATR Internal.");
      return(INIT_FAILED);
   }
   
   trade.SetExpertMagicNumber(magic_number);

   EventSetTimer(2);

   CreateLabel(label_owner,      "OWNER: MUHAMMAD ALDHI", 40, clrGold);
   CreateLabel(label_web_status, "WEB SERVER: INITIALIZING", 65, clrWhite);
   CreateLabel(label_pair_tf,    "PAIR / TF: --", 90, clrWhite);
   CreateLabel(label_balance,    "BALANCE: $0.00", 115, clrWhite);
   CreateLabel(label_equity,     "EQUITY: $0.00", 140, clrWhite);
   CreateLabel(label_freemargin, "FREE MARGIN: $0.00", 165, clrWhite);
   CreateLabel(label_profit,     "FLOATING PROFIT: $0.00", 190, clrWhite);
   CreateLabel(label_pips,       "MOVEMENT: 0 PTS (0.0 PIPS)", 215, clrWhite);
   CreateLabel(label_trend,      "SIGNAL: WAIT...", 240, clrWhite);
   
   UpdateDashboardVisual();
   ChartRedraw(0);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   IndicatorRelease(handle_atr);
   ObjectDelete(0, label_owner);
   ObjectDelete(0, label_web_status);
   ObjectDelete(0, label_pair_tf);
   ObjectDelete(0, label_balance);
   ObjectDelete(0, label_equity);
   ObjectDelete(0, label_freemargin);
   ObjectDelete(0, label_profit);
   ObjectDelete(0, label_pips);
   ObjectDelete(0, label_trend);
}

void OnTimer()
{
   double total_current_profit = AccountInfoDouble(ACCOUNT_PROFIT);
   int active_positions = CountPositions();
   
   FetchSettingsFromWeb();
   SendDashboardToWeb(total_current_profit, active_positions);
   UpdateDashboardVisual();
}

void OnTick()
{
   double total_current_profit = AccountInfoDouble(ACCOUNT_PROFIT);
   int active_positions = CountPositions();

   if(MQLInfoInteger(MQL_TESTER))
   {
      current_Lots = InpLots;
      current_MaxOpenPositions = InpMaxOpenPositions;
      current_MinDistanceEntries = InpMinDistanceEntries;
      current_MaxAllowedSpread = InpMaxAllowedSpread; 
      current_ATRPeriod = InpATRPeriod;
      current_ATREntry = InpATREntry;
      current_UseMartingale = InpUseMartingale;
      current_MartingaleMultiplier = InpMartingaleMultiplier;
      current_MaxMartingaleLots = InpMaxMartingaleLots;
      current_MartingaleTriggerPoints = InpMartingaleTriggerPoints;
      current_SL = InpSL;
      current_MaxLossCurrency = InpMaxLossCurrency;
      current_AktifTrailing = InpAktifTrailing;
      current_JarakTrailing = InpJarakTrailing;
      current_TrailingAktif = InpTrailingAktif;
      current_AktifAvgTrailing = InpAktifAvgTrailing;
      current_JarakAvgTrailing = InpJarakAvgTrailing;
      current_AvgTrailingAktif = InpAvgTrailingAktif;
      current_MartingaleBEProfit = InpMartingaleBEProfit;
      current_TargetProfitMataUang = InpTargetProfitMataUang;
      current_InpAktifFilterGaris = InpAktifFilterGaris;
      current_MartingaleLockBEPProfit = InpMartingaleBEProfit;
   }

   if(is_emergency_paused) return; 

   if(active_positions == 0) 
   {
      martingale_lock_trailing = false;
      locked_highest_ticket = 0;
   }

   // --- Proteksi Loss Gabungan ---
   if(active_positions > 1 && current_UseMartingale && total_current_profit <= -current_MaxLossCurrency)
   {
      Print("🚨 MARTINGALE HARD LOSS LIMIT DETECTED! Force Kill.");
      SikatSemuaPosisi();
      return;
   }

   // --- Target Profit Gabungan ---
   if(active_positions > 0 && total_current_profit >= current_TargetProfitMataUang)
   {
      Print("💰 TARGET PROFIT DETECTED! Closing All Positions.");
      SikatSemuaPosisi();
      return;
   }

   // Jalankan Fungsi Lock Hard SL di titik BEP dengan rata-rata pergerakan trailing dinamis
   if(active_positions > 1 && current_UseMartingale) LockMartingaleToBEP();

   // Mengecek jika kondisi keseluruhan cluster martingale sudah memenuhi profit untuk close all
   if(active_positions > 1 && current_UseMartingale) CheckMartingaleBreakEven();

   CheckActivePositions();

   // --- Logic Entry Posisi Baru ---
   if(active_positions >= current_MaxOpenPositions) return;

   double pips_to_points_ratio = (_Digits == 3 || _Digits == 5) ? 10.0 : 1.0;
   double max_spread_points = current_MaxAllowedSpread * pips_to_points_ratio;
   int market_spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(market_spread > max_spread_points || AccountInfoDouble(ACCOUNT_BALANCE) <= 0) return; 

   // --- LAYER 1 ---
   if(active_positions == 0)
   {
      int rates_total = iBars(_Symbol, _Period);
      if(rates_total < current_ATRPeriod + 5) return;

      ArrayResize(BufferUp, 5);
      ArrayResize(BufferDown, 5);
      ArrayResize(BufferTrend, 5);
      
      double atr[];
      ArraySetAsSeries(atr, true);
      if(CopyBuffer(handle_atr, 0, 0, 5, atr) < 0) return;
      
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(_Symbol, _Period, 0, 5, rates) < 0) return;

      BufferUp[3] = rates[3].close; BufferDown[3] = rates[3].close; BufferTrend[3] = 0;

      for(int i = 2; i >= 0; i--)
      {
         double median = (rates[i].high + rates[i].low) / 2.0;
         double atr_val = atr[i];
         double basic_up = median - (current_ATREntry * atr_val);
         double basic_down = median + (current_ATREntry * atr_val);
            
         if(rates[i].close > BufferUp[i+1]) BufferUp[i] = MathMax(basic_up, BufferUp[i+1]); else BufferUp[i] = basic_up;
         if(rates[i].close < BufferDown[i+1]) BufferDown[i] = MathMin(basic_down, BufferDown[i+1]); else BufferDown[i] = basic_down;
            
         BufferTrend[i] = BufferTrend[i+1];
         if(rates[i].close > BufferDown[i+1]) BufferTrend[i] = 0; 
         if(rates[i].close < BufferUp[i+1])   BufferTrend[i] = 1; 
      }

      MqlRates current_bar[];
      CopyRates(_Symbol, _Period, 0, 1, current_bar);
      if(current_bar[0].time == last_entry_time) return;
      
      double current_lot = CalculateLotSize();

      if(BufferTrend[1] == 0)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl_price = (current_SL > 0) ? NormalizeDouble(ask - (current_SL * _Point), _Digits) : 0;
         if(trade.Buy(current_lot, _Symbol, ask, sl_price, 0, "Initial Buy")) last_entry_time = current_bar[0].time;
      }
      else if(BufferTrend[1] == 1)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl_price = (current_SL > 0) ? NormalizeDouble(bid + (current_SL * _Point), _Digits) : 0;
         if(trade.Sell(current_lot, _Symbol, bid, sl_price, 0, "Initial Sell")) last_entry_time = current_bar[0].time;
      }
   }
   // --- LAYER 2 DAN SETERUSNYA ---
   else if(active_positions > 0 && current_UseMartingale)
   {
      double last_open_price = 0;
      ENUM_POSITION_TYPE cluster_type = POSITION_TYPE_BUY;
      datetime last_pos_time = 0;

      for(int i = 0; i < PositionsTotal(); i++) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) {
            datetime p_time = (datetime)PositionGetInteger(POSITION_TIME);
            if(p_time > last_pos_time) {
               last_pos_time = p_time;
               last_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
               cluster_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            }
         }
      }

      int required_distance = (current_MartingaleTriggerPoints > current_MinDistanceEntries) ? current_MartingaleTriggerPoints : current_MinDistanceEntries;
      
      if(cluster_type == POSITION_TYPE_BUY) {
         double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if((last_open_price - current_bid) / _Point >= required_distance) {
            double current_lot = CalculateLotSize();
            trade.Buy(current_lot, _Symbol, current_bid, 0, 0, "Martingale Buy Layer " + IntegerToString(active_positions + 1));
         }
      }
      else if(cluster_type == POSITION_TYPE_SELL) {
         double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if((current_ask - last_open_price) / _Point >= required_distance) {
            double current_lot = CalculateLotSize();
            trade.Sell(current_lot, _Symbol, current_ask, 0, 0, "Martingale Sell Layer " + IntegerToString(active_positions + 1));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CORE ENGINE UPDATE VISUAL                                        |
//+------------------------------------------------------------------+
void UpdateDashboardVisual()
{
   double balance     = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity      = AccountInfoDouble(ACCOUNT_EQUITY);
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double total_profit= AccountInfoDouble(ACCOUNT_PROFIT);
   string tf_text     = StringSubstr(EnumToString(_Period), 7);
   
   if(global_web_status == "CONNECTED") {
      ObjectSetString(0, label_web_status, OBJPROP_TEXT, "WEB SERVER: CONNECTED ⚡");
      ObjectSetInteger(0, label_web_status, OBJPROP_COLOR, clrLime);
   } else {
      ObjectSetString(0, label_web_status, OBJPROP_TEXT, "WEB SERVER: DISCONNECTED 🚫");
      ObjectSetInteger(0, label_web_status, OBJPROP_COLOR, clrRed);
   }

   ObjectSetString(0, label_pair_tf, OBJPROP_TEXT, "PAIR / TF: " + _Symbol + " [" + tf_text + "]");
   ObjectSetString(0, label_balance, OBJPROP_TEXT, "BALANCE: $" + DoubleToString(balance, 2));
   ObjectSetString(0, label_equity, OBJPROP_TEXT, "EQUITY: $" + DoubleToString(equity, 2));
   ObjectSetString(0, label_freemargin, OBJPROP_TEXT, "FREE MARGIN: $" + DoubleToString(free_margin, 2));
   ObjectSetString(0, label_profit, OBJPROP_TEXT, "FLOATING PROFIT: $" + DoubleToString(total_profit, 2));
   
   if(total_profit > 0)       ObjectSetInteger(0, label_profit, OBJPROP_COLOR, clrLime);
   else if(total_profit < 0)  ObjectSetInteger(0, label_profit, OBJPROP_COLOR, clrRed);
   else                       ObjectSetInteger(0, label_profit, OBJPROP_COLOR, clrWhite);

   double total_lots_calc = 0, total_open_product_calc = 0;
   ENUM_POSITION_TYPE calc_type = POSITION_TYPE_BUY;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
      {
         double volume = PositionGetDouble(POSITION_VOLUME);
         total_lots_calc += volume;
         total_open_product_calc += (PositionGetDouble(POSITION_PRICE_OPEN) * volume);
         calc_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      }
   }

   if(total_lots_calc > 0)
   {
      double avg_price = total_open_product_calc / total_lots_calc;
      double current_market_price = (calc_type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double diff_points = (calc_type == POSITION_TYPE_BUY) ? (current_market_price - avg_price) / _Point : (avg_price - current_market_price) / _Point;
      double pips_value = diff_points / (_Digits == 3 || _Digits == 5 ? 10.0 : 1.0);
      string prefix = (diff_points > 0) ? "+" : "";
       
      ObjectSetString(0, label_pips, OBJPROP_TEXT, "MOVEMENT: " + prefix + DoubleToString(diff_points, 0) + " PTS (" + prefix + DoubleToString(pips_value, 1) + " PIPS)");
      if(diff_points > 0) ObjectSetInteger(0, label_pips, OBJPROP_COLOR, clrLime); else ObjectSetInteger(0, label_pips, OBJPROP_COLOR, clrRed);
   }
   else
   {
      ObjectSetString(0, label_pips, OBJPROP_TEXT, "MOVEMENT: 0 PTS (0.0 PIPS)");
      ObjectSetInteger(0, label_pips, OBJPROP_COLOR, clrWhite);
   }

   if(is_emergency_paused) {
      ObjectSetString(0, label_trend, OBJPROP_TEXT, "STATUS: EMERGENCY PAUSED 🚫");
      ObjectSetInteger(0, label_trend, OBJPROP_COLOR, clrOrange);
   } else if(ArraySize(BufferTrend) > 1) {
      if(BufferTrend[1] == 0) { ObjectSetString(0, label_trend, OBJPROP_TEXT, "SIGNAL: BULLISH (BUY)"); ObjectSetInteger(0, label_trend, OBJPROP_COLOR, clrLime); }
      else { ObjectSetString(0, label_trend, OBJPROP_TEXT, "SIGNAL: BEARISH (SELL)"); ObjectSetInteger(0, label_trend, OBJPROP_COLOR, clrRed); }
   } else {
      ObjectSetString(0, label_trend, OBJPROP_TEXT, "SIGNAL: WAIT...");
      ObjectSetInteger(0, label_trend, OBJPROP_COLOR, clrWhite);
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| AUXILIARY FUNCTIONS                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| FUNGSI LOCK HARD SL DI TITIK BEP + TRAILING BUFFER AMAN          |
//+------------------------------------------------------------------+
void LockMartingaleToBEP()
{
   double total_net_profit = 0;
   double total_lots = 0;
   double total_open_product = 0;
   ENUM_POSITION_TYPE cluster_type = POSITION_TYPE_BUY;
   int count = 0;

   // Perhitungan total profit, volume, dan average price
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
      {
         double volume = PositionGetDouble(POSITION_VOLUME);
         total_net_profit += (PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION));
         total_lots += volume;
         total_open_product += (PositionGetDouble(POSITION_PRICE_OPEN) * volume);
         cluster_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         count++;
      }
   }

   // Berjalan jika multi-layer dan profit cluster menyentuh batas pengaman awal (50% dari Target Profit BE Utama)
   double trigger_bep = current_MartingaleBEProfit * 0.5;
   
   if(count > 1 && total_lots > 0 && total_net_profit >= trigger_bep)
   {
      double avg_price = total_open_product / total_lots;
      double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      // Memberikan jarak nafas aman 300 points dari harga saat ini agar tidak ter-clipping spread
      int trailing_buffer_points = 300; 
      double target_sl_price = 0;

      if(cluster_type == POSITION_TYPE_BUY)
      {
         target_sl_price = NormalizeDouble(current_bid - (trailing_buffer_points * _Point), _Digits);
         // Memastikan SL pengaman tidak drop di bawah Average Price murni cluster
         if(target_sl_price < avg_price) target_sl_price = NormalizeDouble(avg_price + (50 * _Point), _Digits); 
      }
      else if(cluster_type == POSITION_TYPE_SELL)
      {
         target_sl_price = NormalizeDouble(current_ask + (trailing_buffer_points * _Point), _Digits);
         // Memastikan SL pengaman tidak melambung di atas Average Price murni cluster
         if(target_sl_price > avg_price) target_sl_price = NormalizeDouble(avg_price - (50 * _Point), _Digits);
      }

      // Terapkan Hard SL ke seluruh order di dalam cluster menggunakan sistem trailing searah
      for(int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
         {
            double current_sl = PositionGetDouble(POSITION_SL);
            
            if(cluster_type == POSITION_TYPE_BUY)
            {
               if(current_sl == 0 || target_sl_price > current_sl)
               {
                  trade.PositionModify(ticket, target_sl_price, PositionGetDouble(POSITION_TP));
               }
            }
            else if(cluster_type == POSITION_TYPE_SELL)
            {
               if(current_sl == 0 || target_sl_price < current_sl)
               {
                  trade.PositionModify(ticket, target_sl_price, PositionGetDouble(POSITION_TP));
               }
            }
         }
      }
   }
}

void CheckMartingaleBreakEven()
{
   double total_net_profit = 0;
   int cluster_positions_count = 0;

   // Hitung total profit bersih dari semua layer Martingale yang aktif
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
      {
         total_net_profit += (PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION));
         cluster_positions_count++;
      }
   }
   
   // JIKA POSISI MULTI-LAYER (SEDANG FLOATING MINUS/MARTINGALE) & TOTAL PROFIT SUDAH MENCAPAI TARGET BE SUDAH VALID
   if(cluster_positions_count > 1 && total_net_profit >= current_MartingaleBEProfit)
   {
      Print("💰 [Martingale Target Hit] Total Posisi: ", cluster_positions_count, " | Profit: $", DoubleToString(total_net_profit, 2), ". SIKAT SEMUA POSISI!");
      SikatSemuaPosisi();
   }
}

void CheckActivePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
      {
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double current_sl = PositionGetDouble(POSITION_SL);

         // Trailing standard hanya mengawal saat hanya ada 1 Single Layer (bukan saat Martingale berjalan)
         if(current_AktifTrailing && CountPositions() == 1)
         {
            if(type == POSITION_TYPE_BUY) { double dist = (current_price - open_price) / _Point; if(dist >= current_TrailingAktif) { double n_sl = NormalizeDouble(current_price - (current_JarakTrailing * _Point), _Digits); if(current_sl == 0 || n_sl > current_sl) trade.PositionModify(ticket, n_sl, PositionGetDouble(POSITION_TP)); } }
            else { double dist = (open_price - current_price) / _Point; if(dist >= current_TrailingAktif) { double n_sl = NormalizeDouble(current_price + (current_JarakTrailing * _Point), _Digits); if(current_sl == 0 || n_sl < current_sl) trade.PositionModify(ticket, n_sl, PositionGetDouble(POSITION_TP)); } }
         }
      }
   }
}

void CreateLabel(string name, string text, int y_pos, color text_color)
{
   ObjectDelete(0, name);
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 220);           
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y_pos);         
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");            
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11);              
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   }
}

double CalculateLotSize()
{
   int current_positions = CountPositions();
   if(current_positions == 0 || !current_UseMartingale) return current_Lots;
   double base_lot = current_Lots;
   for(int i = 0; i < current_positions; i++) base_lot = base_lot * current_MartingaleMultiplier;
   base_lot = NormalizeDouble(base_lot, 2);
   return (base_lot > current_MaxMartingaleLots) ? current_MaxMartingaleLots : base_lot; 
}

int CountPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) count++;
   }
   return count;
}

void SikatSemuaPosisi()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number) trade.PositionClose(ticket);
   }
}

void SendDashboardToWeb(double current_profit, int active_layers)
{
   string url = "https://enters-currency-convicted-stockings.trycloudflare.com/api/update_dashboard";
   string headers = "Content-Type: application/json\r\n";
   string tf_text = StringSubstr(EnumToString(_Period), 7);
   
   string post_data = "{"
                      "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ","
                      "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ","
                      "\"free_margin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_FREEMARGIN), 2) + ","
                      "\"profit\":" + DoubleToString(current_profit, 2) + ","
                      "\"layers\":" + IntegerToString(active_layers) + ","
                      "\"pair_tf\":\"" + _Symbol + " [" + tf_text + "]\","
                      "\"signal\":\"OPERATIONAL\""
                      "}";
                      
   char post[], result[]; string result_headers; 
   ArrayFree(post);
   int msg_len = StringLen(post_data);
   StringToCharArray(post_data, post, 0, msg_len, CP_UTF8);
   ArrayResize(post, msg_len);
   
   ResetLastError();
   int res = WebRequest("POST", url, headers, 200, post, result, result_headers);
   if(res == -1) Print("❌ Error WebRequest. Code = ", GetLastError());
}

//+------------------------------------------------------------------+
//| RE-SYNCHRONIZATION ENGINE: SINKRON DATA INPUT DARI WEB TERMINAL  |
//+------------------------------------------------------------------+
void FetchSettingsFromWeb()
{
   string url = "https://enters-currency-convicted-stockings.trycloudflare.com/api/get_settings";
   char post[], result[]; string response_headers;
   
   ResetLastError();
   int res = WebRequest("GET", url, "", 200, post, result, response_headers);
   if(res == 200)
   {
      global_web_status = "CONNECTED";
      string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      
      // --- PERBAIKAN LOGIKA EMERGENCY SHUTDOWN ---
      bool emergency_stop_active = (GetJsonValue(json, "InpEmergencyStop") == "true");
      if(emergency_stop_active)
      {
         if(!is_emergency_paused)
         {
            Print("🚨 EMERGENCY SHUTDOWN SIGNAL RECEIVED! FORCE CLOSING ALL POSITIONS.");
            is_emergency_paused = true;
            SikatSemuaPosisi(); // Tutup paksa semua posisi saat tombol ditekan
         }
      }
      else
      {
         is_emergency_paused = false;
      }
      
      // --- Pemetaan Parameter Lainnya ---
      current_Lots = StringToDouble(GetJsonValue(json, "InpLots"));
      current_MaxOpenPositions = (int)StringToInteger(GetJsonValue(json, "InpMaxOpenPositions"));
      current_MinDistanceEntries = (int)StringToInteger(GetJsonValue(json, "InpMinDistanceEntries"));
      current_MaxAllowedSpread = StringToDouble(GetJsonValue(json, "InpMaxAllowedSpread"));
      current_ATRPeriod = (int)StringToInteger(GetJsonValue(json, "InpATRPeriod"));
      current_ATREntry = StringToDouble(GetJsonValue(json, "InpATREntry"));
      current_UseMartingale = (GetJsonValue(json, "InpUseMartingale") == "true");
      current_MartingaleMultiplier = StringToDouble(GetJsonValue(json, "InpMartingaleMultiplier"));
      current_MaxMartingaleLots = StringToDouble(GetJsonValue(json, "InpMaxMartingaleLots"));
      current_MartingaleTriggerPoints = (int)StringToInteger(GetJsonValue(json, "InpMartingaleTriggerPoints"));
      current_SL = (int)StringToInteger(GetJsonValue(json, "InpSL"));
      current_MaxLossCurrency = StringToDouble(GetJsonValue(json, "InpMaxLossCurrency"));
      current_AktifTrailing = (GetJsonValue(json, "InpAktifTrailing") == "true");
      current_JarakTrailing = (int)StringToInteger(GetJsonValue(json, "InpJarakTrailing"));
      current_TrailingAktif = (int)StringToInteger(GetJsonValue(json, "InpTrailingAktif"));
      
      current_AktifAvgTrailing = (GetJsonValue(json, "InpAktifAvgTrailing") == "true");
      current_JarakAvgTrailing = (int)StringToInteger(GetJsonValue(json, "InpJarakAvgTrailing")); 
      current_AvgTrailingAktif = (int)StringToInteger(GetJsonValue(json, "InpAvgTrailingAktif")); 
      current_MartingaleBEProfit = StringToDouble(GetJsonValue(json, "InpMartingaleBEProfit"));
      current_TargetProfitMataUang = StringToDouble(GetJsonValue(json, "InpTargetProfitMataUang"));
   }
   else global_web_status = "DISCONNECTED";
}

string GetJsonValue(string json, string key)
{
   string search_key = "\"" + key + "\"";
   int pos = StringFind(json, search_key); if(pos == -1) return "";
   int start = pos + StringLen(search_key);
   int colon = StringFind(json, ":", start); if(colon == -1) return "";
   int val_start = colon + 1;
   while(val_start < StringLen(json) && (StringSubstr(json, val_start, 1) == " " || StringSubstr(json, val_start, 1) == "\t")) val_start++;
   
   if(StringSubstr(json, val_start, 1) == "\"")
   {
      val_start++;
      int val_end = StringFind(json, "\"", val_start);
      if(val_end == -1) return "";
      return StringSubstr(json, val_start, val_end - val_start);
   }
   else
   {
      int val_end = val_start;
      while(val_end < StringLen(json) && StringSubstr(json, val_end, 1) != "," && StringSubstr(json, val_end, 1) != "}" && StringSubstr(json, val_end, 1) != "\r" && StringSubstr(json, val_end, 1) != "\n") val_end++;
      return StringSubstr(json, val_start, val_end - val_start);
   }
}
