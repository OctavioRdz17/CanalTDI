//+------------------------------------------------------------------+
//|                                                     CajasTDI.mq4 |
//|                                Copyright 2022, Octavio Rodriguez |
//|                                                   toktrading.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Octavio Rodriguez"
#property link      "toktrading.net"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|Inputs toktrading                                                 |
//+------------------------------------------------------------------+
//caduca
   int limityear  = 2023;
   int limitmonth = 1;
   int limitday   = 06;
   
//cuentas aprobadas
   int cuenta1 = 8308;
   int cuenta2 = 0934;
   int cuenta3 = 5025;
   int cuenta4 = 8101;
//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+

   //inputs del canal
  extern double ratioTP = 2; //Ratio de TP
  extern double ratioBE = 1; //Ratio de BE
  extern int pntExtBE =20; //Puntos Extra en BE
  extern double extraSlPercent = 5; //Porcentaje extra de SL 
  extern double maxCrossCanalPercent = 2; //Distancia maxima del punto de entrada   

  //inputs de riesgo
  enum TipoDeRiesgo{ PORCENTAJE, MONEDA, LOTAJE };
  input TipoDeRiesgo RiesgoTipo= 0; 
  input double CantidadRiesgo =2;

//+------------------------------------------------------------------+
//|  VARIAVBLES                                                      |
//+------------------------------------------------------------------+
 
 //break even
 int plusGestionBE=0;
 
 //
 int barrasActuales = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      //crear botones
   crearBotones(0,"Button1",0,1,35,150,33,2,"CANAL");
   crearBotones(0,"Button2",0,1,53,73,18,2,"BUY");
   crearBotones(0,"Button3",0,77,53,73,18,2,"SELL");
   
   barrasActuales = Bars(NULL,Period()); 
   
   
   
   //revision de tiempo
   if(!timecheck()){
   Alert("Se termino el tiempo de este indicador");
   Print("ESe termino el tiempo de este indicador");
   ObjectsDeleteAll(0,OBJ_TREND);
   return(INIT_FAILED);}
   
   if(logdhay())return(INIT_SUCCEEDED);
   if(IsTesting())return(INIT_SUCCEEDED);
   
   if(IsDemo()){
      Alert("Acceso permitido a la cuenta demo");
      return(INIT_SUCCEEDED);}
   else{
      Alert("Esta version solo funciona en cuentas demo");
      Print("Esta version solo funciona en cuentas demo");
      ObjectsDeleteAll(0,OBJ_TREND);
      return(INIT_FAILED);
   }
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
      //crear botones
   ObjectsDeleteAll(0,OBJ_TREND);
   ObjectDelete(0,"Button1");
   ObjectDelete(0,"Button2");
   ObjectDelete(0,"Button3");
   ObjectDelete(0,"Button4");
   ObjectDelete(0,"Button5");
  }
  
//+------------------------------------------------------------------+
//| On Chart Event                                                   |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){

     
   if(sparam == "Button1")
     {
      ObjectDelete(0,"canal1");
      dibujarCanal("canal1",clrRed);
      ObjectSetInteger(NULL,"Button1",OBJPROP_STATE,false);
     }
    if(sparam == "Button2")
     {
      //ObjectDelete(0,"Compra");
      ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
      
     }
     if(sparam == "Button3")
     {
      //ObjectDelete(0,"Venta");
      ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
      
     }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Sleep(500);
   //botones para el tester
   if(IsTesting())    botenesdeltester();


   GestionarEntradas();
   
   
   //existe nueva vela y existe el fibo para tener los niveles
   if (nuevaVela(barrasActuales) && ObjectFind(NULL,"canal1")>=0 ){
   
      double fibEntrada = ObjectGetDouble(NULL,"canal1",OBJPROP_PRICE,1);
      double fibCanal = ObjectGetDouble(NULL,"canal1",OBJPROP_PRICE,0);
     
    
      barrasActuales = Bars;
      //Cuando hay nueva vela revisa la entrada
      if(revisionEntrada(fibEntrada,fibCanal) == 1){
         
         //algorito de revision de entrada rota
         if(revisarRompimientoEntrada(1,fibEntrada,fibCanal)){
               //punto de entrada
               double puntoActualEntrada = Ask;
               crearCompra(puntoActualEntrada,fibEntrada,fibCanal); 
         }
         
        
      }
      if(revisionEntrada(fibEntrada,fibCanal) == -1){
         
         //algorito de revision de entrada rota
         if(revisarRompimientoEntrada(-1,fibEntrada,fibCanal)){
               //punto de entrada
               double puntoActualEntrada = Ask;
               //Print("Crear Venta en este punto");
               crearVenta(puntoActualEntrada,fibEntrada,fibCanal); 
         }
         
         
        
      }
      
    }
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool crearBotones(const long              chart_ID=0,                // chart's ID
                  const string            nameB="Button",            // button name
                  const int               sub_window=0,              // subwindow index
                  const int               x=0,                       // X coordinate
                  const int               y=20,                      // Y coordinate
                  const int               width=75,                  // button width
                  const int               height=18,                 // button height
                  const ENUM_BASE_CORNER  corner=CORNER_RIGHT_UPPER, // chart corner for anchoring
                  const string            text="Close OP"            // text
                        //const int               bgColor = 12
                 ){
      //--- reset the error value
      ResetLastError();
      //--- create the button
      if(!ObjectCreate(chart_ID,nameB,OBJ_BUTTON,sub_window,0,0))
        {
         Print(__FUNCTION__,
               ": failed to create the button! Error code = ",GetLastError());
         return(false);
        }
      //--- set the chart's corner, relative to which point coordinates are defined
      ObjectSetInteger(chart_ID,nameB,OBJPROP_CORNER,corner);
      //--- set button coordinates
      ObjectSetInteger(chart_ID,nameB,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(chart_ID,nameB,OBJPROP_YDISTANCE,y);
      //--- set button size
      ObjectSetInteger(chart_ID,nameB,OBJPROP_XSIZE,width);
      ObjectSetInteger(chart_ID,nameB,OBJPROP_YSIZE,height);

      //--- set the text
      ObjectSetString(chart_ID,nameB,OBJPROP_TEXT,text);
      //--- set button state
      ObjectSetInteger(chart_ID,nameB,OBJPROP_STATE,false);
      //--- set background color
      //ObjectSetInteger(chart_ID,nameB,OBJPROP_BGCOLOR,bgColor);
      //--- set text font
      /*
         ObjectSetString(chart_ID,nameB,OBJPROP_FONT,"Arial");
      //--- set font size
         ObjectSetInteger(chart_ID,nameB,OBJPROP_FONTSIZE,10);
      //--- set text color
         ObjectSetInteger(chart_ID,nameB,OBJPROP_COLOR,clrBlack);

      //--- set border color
         ObjectSetInteger(chart_ID,nameB,OBJPROP_BORDER_COLOR,clrNONE);
      //--- display in the foreground (false) or background (true)
         ObjectSetInteger(chart_ID,nameB,OBJPROP_BACK,false);

      //--- enable (true) or disable (false) the mode of moving the button by mouse
         ObjectSetInteger(chart_ID,nameB,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(chart_ID,nameB,OBJPROP_SELECTED,false);
      //--- hide (true) or display (false) graphical object name in the object list
         ObjectSetInteger(chart_ID,nameB,OBJPROP_HIDDEN,true);
      //--- set the priority for receiving the event of a mouse click in the chart
         ObjectSetInteger(chart_ID,nameB,OBJPROP_ZORDER,0);
      //--- successful execution */
      return(true);
}
/*
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void botenesdeltester(){
   if(ObjectGetInteger(NULL,"Button1",OBJPROP_STATE))
     {
         ObjectSetInteger(NULL,"Button1",OBJPROP_STATE,false);
         Print("Compra manual por boton");
         OPBOTON = true;
         //se manda la orden
         getlevels("FIBX");
         if(nivelTrampa < TP)
            orderSend(1);
         OPBOTON = false;
         ObjectDelete(0,"FIBX");  
     }
     
   if(ObjectGetInteger(NULL,"Button2",OBJPROP_STATE))
     {
        ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
        Print("Venta manual por boton");
        OPBOTON = true;
        //se manda la orden
        getlevels("FIBX");
        if(nivelTrampa > TP)
            orderSend(-1);
        OPBOTON = false;
        ObjectDelete(0,"FIBX");
     }
   if(ObjectGetInteger(NULL,"Button3",OBJPROP_STATE))
     {
        ObjectDelete(0,"FIBX");
        ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
        dibujarFibo("FIBX",clrRed);
     }
   if(ObjectGetInteger(NULL,"Button4",OBJPROP_STATE))
     {
        ObjectDelete(0,"FIB1");
        ObjectSetInteger(NULL,"Button4",OBJPROP_STATE,false);
        dibujarFibo("FIB1",clrBlack);
     }
}
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void dibujarCanal(string namex, color col){
   ObjectCreate(NULL,namex,OBJ_FIBO,0,iTime(NULL,Period(),7),iLow(NULL,Period(),7),iTime(NULL,Period(),1),iHigh(NULL,Period(),1));
  //--- En estas ordenes se checan las propiedades del fibo y se crean los niveles con sus leyendas
   ObjectSetInteger(NULL,namex,OBJPROP_COLOR,clrRed);
   ObjectSetInteger(NULL,namex,OBJPROP_RAY_RIGHT,false);
  //cantidad de niveles
   ObjectSetInteger(NULL,namex,OBJPROP_LEVELS,4);
  //color
   ObjectSetInteger(NULL,namex,OBJPROP_LEVELCOLOR,col);

  //nivel donde se ve el tp del fibo
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,0,0);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,0,"Rompimiento de Canal");

  //nivel de trampa del fibo
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,1,1);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,1,"Canal");

  //nivel minimo donde se revisa la pillada
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,2,2);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,2,"Doble Canal");

  //nivel maximo de pillada
   double percent= ((extraSlPercent  * 2 )/100  )+ 2 ;
   ObjectSetDouble(NULL,namex,OBJPROP_LEVELVALUE,3,percent);
   ObjectSetString(NULL,namex,OBJPROP_LEVELTEXT,3,"StopLoss");

 
}
//+------------------------------------------------------------------+
//| Revisa que exista una nueva vela                             |
//+------------------------------------------------------------------+

bool nuevaVela(int barsAct){

   if(Bars > barsAct) return true;
   return false;
   
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int revisionEntrada(double nivEntrada, double nivCanal){
    
   //cuando el boton esta aplastado y que el fib este colocado
   //correctamente en posicion de compra
   if(ObjectGetInteger(NULL,"Button2",OBJPROP_STATE,true) && (nivEntrada > nivCanal) ){
      
      
      //retornamos el valor a falso
      //ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
      return 1;
   }
   
   
   
   if(ObjectGetInteger(NULL,"Button3",OBJPROP_STATE,true) && (nivEntrada < nivCanal) ){
      //retornamos el valor a falso
      //ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
      return -1;
   }
   //obtener los niveles del fibo
   
   return 0;

}

//+------------------------------------------------------------------+
//|   Compra                                                         |
//+------------------------------------------------------------------+
void crearCompra(double puntoReal, double entCanal, double finCanal){
   
   //tamaño del canal
   double deltaCanal = entCanal - finCanal ; 
   
   //creamos el punto de SL
   double SLCanal = entCanal - ((deltaCanal * 2)*(1+(extraSlPercent/100)));
   
   //creamos punto de TP
   double TPCanal = ((puntoReal - SLCanal)*ratioTP) + puntoReal; 
   
   //creamos punto de BE
   double BEcanal = ((puntoReal - SLCanal)*ratioBE) + puntoReal;
   
   //normalizar puntos de la entrada
   TPCanal = NormalizeDouble(TPCanal,(int)MarketInfo(NULL,MODE_DIGITS));
   SLCanal = NormalizeDouble(SLCanal,(int)MarketInfo(NULL,MODE_DIGITS));
   BEcanal = NormalizeDouble(BEcanal,(int)MarketInfo(NULL,MODE_DIGITS));
   puntoReal = NormalizeDouble(puntoReal,(int)MarketInfo(NULL,MODE_DIGITS));
   
   
   double pipsGestionEmpate = (int)((BEcanal - puntoReal ) /Point());
   //pipsGestionEmpate = (int)NormalizeDouble (pipsGestionEmpate,0);
   //Print("BEcanal = "+ BEcanal);
   //Print("pipsGestionEmpate = "+ pipsGestionEmpate);
   int Magic = (int)crearMagic(317,(int)pipsGestionEmpate);
   //Print("Magic = "+ Magic);
   
   
   //lotaje de la entrada
   //Print("puntoReal= "+puntoReal +" SLCanal= "+SLCanal);
   double puntosSL = (puntoReal - SLCanal)/Point();
   //Print("puntosSL= "+puntosSL);
   double lots = crearLotaje((int)puntosSL);
   
   if(!OrderSend(NULL,OP_BUY,lots,puntoReal,10,SLCanal,TPCanal,NULL,(int)Magic,0,clrNONE))
           {
            Print("OrderSend failed with error #",GetLastError());
            Sleep(1000);
            //purchaseCheck();
           }
         else
           {
            //ObjectDelete(0,"canal1");
            //Print("Entrada ="+(string)orderPoint+", SL ="+(string)slPoint+", TP ="+(string)tpPoint+", Magic ="+(string)Magic);
           }
           
}

//+------------------------------------------------------------------+
//| Venta                                                            |
//+------------------------------------------------------------------+
void crearVenta(double puntoReal, double entCanal, double finCanal){
   
   //tamaño del canal
   double deltaCanal = finCanal - entCanal; 
   
   //creamos el punto de SL
   double SLCanal = entCanal + ((deltaCanal * 2)*(1+(extraSlPercent/100)));
   
   //creamos punto de TP
   double TPCanal = puntoReal - ((SLCanal - puntoReal)*ratioTP)  ; 
   
   //creamos punto de BE
   double BEcanal = puntoReal - ((SLCanal - puntoReal)*ratioBE) ;
   
   //normalizar puntos de la entrada
   TPCanal = NormalizeDouble(TPCanal,(int)MarketInfo(NULL,MODE_DIGITS));
   SLCanal = NormalizeDouble(SLCanal,(int)MarketInfo(NULL,MODE_DIGITS));
   BEcanal = NormalizeDouble(BEcanal,(int)MarketInfo(NULL,MODE_DIGITS));
   puntoReal = NormalizeDouble(puntoReal,(int)MarketInfo(NULL,MODE_DIGITS));
   
   
   double pipsGestionEmpate = (int)((puntoReal - BEcanal) /Point());
   //pipsGestionEmpate = (int)NormalizeDouble (pipsGestionEmpate,0);
   //Print("BEcanal = "+ BEcanal);
   //Print("pipsGestionEmpate = "+ pipsGestionEmpate);
   int Magic = crearMagic(317,(int)pipsGestionEmpate);
   //Print("Magic = "+ Magic);
   
   
   //lotaje de la entrada
   //Print("puntoReal= "+puntoReal +" SLCanal= "+SLCanal);
   double puntosSL = (SLCanal - puntoReal)/Point();
   //Print("puntosSL= "+puntosSL);
   double lots = crearLotaje((int)puntosSL);
   
   if(!OrderSend(NULL,OP_SELL,lots,puntoReal,10,SLCanal,TPCanal,NULL,(int)Magic,0,clrNONE))
           {
            Print("OrderSend failed with error #",GetLastError());
            Sleep(1000);
            //purchaseCheck();
           }
         else
           {
            //ObjectDelete(0,"canal1");
            //Print("Entrada ="+(string)orderPoint+", SL ="+(string)slPoint+", TP ="+(string)tpPoint+", Magic ="+(string)Magic);
           }
           
}


//+------------------------------------------------------------------+
//|  crea magic para el BE                                           |
//+------------------------------------------------------------------+
int crearMagic(int estrategia, int empate){
   /* creamos el magicnumber para la operacion
      317 numero de identificacion del robot
      00 siguintes numero es el tipo de gestion
      0000 siguientes cuatro numero es el numero de gestion de cierre
      0000 siguienters cuatro numeros gestion de empate */
      
   string est,emp,numeromagico;
   int magic;
   
   //Print("pips cierre"+(string)cierre+", pips empate"+(string)empate);
   //estrategia normalizada a 2 digitos
   est = IntegerToString(estrategia);
   
  //se pasa a string para manipular las variables
   emp = IntegerToString(empate);

  //normalizar a 4 digitos
   emp = stringAddZero(emp);

   numeromagico = StringConcatenate(est,emp);
   magic = (int)StringToInteger(numeromagico);
   return(magic);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//normalizar a 4 digitos string
string stringAddZero(string itera){
   string word;
   if(StringLen(itera)== 1)
      word = StringConcatenate("00000",itera);
   if(StringLen(itera)== 2)
      word = StringConcatenate("0000",itera);
   if(StringLen(itera)== 3)
      word = StringConcatenate("000",itera);
   if(StringLen(itera)== 4)
      word = StringConcatenate("00",itera);
   if(StringLen(itera)>= 5)
      word = StringConcatenate("0",itera);
   if(StringLen(itera)>= 6)
      word = itera;


   return (word);
}

//+------------------------------------------------------------------+
//|  Crear lotaje segun el riesgo                                    |
//+------------------------------------------------------------------+
double crearLotaje(int pips){
   double dinero = AccountBalance()  * CantidadRiesgo/100;
   if(RiesgoTipo==1)
      dinero = CantidadRiesgo;
   double tickVal  = MarketInfo(NULL,MODE_TICKVALUE);
   if(tickVal == 0) tickVal = 1;
   //Print("Dinero = "+dinero+"\nPips="+pips+"\nTickvall= "+tickVal);
   
   double LotSize = dinero/(pips*tickVal);
   //double LotSize = 0.01;
   
   //Print("MinLot ="+MarketInfo(Symbol(),MODE_LOTSTEP));
   
   
   if(LotSize<.01)
      LotSize = .01;
   if(RiesgoTipo == 2)
      LotSize = CantidadRiesgo;

   LotSize = MathCeil(LotSize *100);
   LotSize = LotSize /100;
   
   
   if(MarketInfo(Symbol(),MODE_LOTSTEP) == 1){
      if(LotSize <1)LotSize =1;
      LotSize = (int)NormalizeDouble(LotSize,0);
   }
   
   
   return LotSize;

}

//+------------------------------------------------------------------+
//|Revisa que el cierre de la vela anterior rompa el canal           |
//+------------------------------------------------------------------+
bool revisarRompimientoEntrada (int direccion, double entCanal, double canal ){

   //algortimo para ver el maximo punto de entrada   
   if(direccion == 1){
      double deltaC = entCanal - canal;
      double valorMaximoEntrada = (deltaC * maxCrossCanalPercent) + entCanal;
      
      double velaEntradaOpen  = iOpen (NULL,Period(),1);
      double velaEntradaClose = iClose(NULL,Period(),1);
      
      
      
      if(velaEntradaClose > valorMaximoEntrada ){        
         Print("El cierre de vela sobrepasa el punto maximo de entrada "+(string)valorMaximoEntrada);
         return false;
      }
      
      //Print("Vela de close = "+velaEntradaClose+"\nPunto de Entrada = "+entCanal);
         
      //revisa la vela este por afuera del limite deseado
      if(velaEntradaClose > entCanal ){
         //Print("Se rompio el punto de entrada del canal");
         //revisa la vela anterior estaba dentro del rango
         if(velaEntradaOpen < entCanal && velaEntradaOpen > canal ){
            // se confirma la entrada
            Print("Se rompio el punto de entrada del canal");
            ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
            return true;
         }else{
            Print("vela fuera del canal, no se puede procesar la entrada");
         }
      }
   }
   
   //Para las ventas
   
   if(direccion == -1){
      double deltaC = canal - entCanal;
      double valorMaximoEntrada = entCanal - (deltaC * maxCrossCanalPercent);
      
      double velaEntradaOpen  = iOpen (NULL,Period(),1);
      double velaEntradaClose = iClose(NULL,Period(),1);
      
      
      
      if(velaEntradaClose < valorMaximoEntrada ){        
         Print("El cierre de vela sobrepasa el punto maximo de entrada "+(string)valorMaximoEntrada);
         return false;
      }
      
      //Print("Vela de close = "+velaEntradaClose+"\nPunto de Entrada = "+entCanal);
         
      //revisa la vela este por afuera del limite deseado
      if(velaEntradaClose < entCanal ){
         //Print("Se rompio el punto de entrada del canal");
         //revisa la vela anterior estaba dentro del rango
         if(velaEntradaOpen > entCanal && velaEntradaOpen < canal ){
            // se confirma la entrada
            Print("Se rompio el punto de entrada del canal");
            ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
            return true;
         }else{
            Print("vela fuera del canal, no se puede procesar la entrada");
         }
      }
   }
   
   return false;

}


//+------------------------------------------------------------------+
//| Mover entradas a BE                                              |
//+------------------------------------------------------------------+
void GestionarEntradas(){
   int magicbreak, magicBE;      //magic numbers
   string magicletra;                        //magic
   double gestionBEValor; //valores de gestion
   //double SlReducido;
   
   //barrido de todas la entradas
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--){
      
      if(OrderSelect(pos, SELECT_BY_POS)                     // Only my orders w/
         &&  StringSubstr((string)OrderMagicNumber(),0,3)  == (string)317   // primeros dos numeros del magic
         &&  OrderSymbol()       == Symbol())               // and my pair.
        {
            magicbreak = OrderMagicNumber();
            magicletra = IntegerToString(magicbreak);
            magicBE    = (int)StringToInteger(StringSubstr(magicletra,3,6))+ plusGestionBE;
            //Print("magicBE= " + magicBE );
             
             //cuando tenemos una entrada de compra
             if(OrderType()==OP_BUY){
                  
                  //comprobacion para saber si ya se movio el BE
                  if(OrderStopLoss()>=(OrderOpenPrice()-(10*Point()))) return;
                  
                  gestionBEValor= OrderOpenPrice() + (magicBE * MarketInfo(NULL,MODE_POINT));
                  //Print("gestionBEValor= " + gestionBEValor );
                  
                  if( Ask > gestionBEValor ){
                     Print("Se mueve la entrada a empate ");

                     //se manda mover el TP a la zona de empate
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(pntExtBE*Point()),OrderTakeProfit(),0,clrNONE))
                     {
                         Print("Error al mover a break even "+(string)GetLastError()+" Ticket: "+(string)OrderTicket());
                         Sleep(5000);
                         //GestionarEntradas();
                     }
                  
                  }
                  
             
             }

             if(OrderType()==OP_SELL){
                  
                  //comprobacion para saber si ya se movio el BE
                  if(OrderStopLoss()<=(OrderOpenPrice()-(10*Point()))) return;
                  
                  gestionBEValor= OrderOpenPrice() - (magicBE * MarketInfo(NULL,MODE_POINT));
                  //Print("gestionBEValor= " + gestionBEValor );
                  
                  if( Bid < gestionBEValor ){
                     Print("Se mueve la entrada a empate ");

                     //se manda mover el TP a la zona de empate
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(pntExtBE*Point()),OrderTakeProfit(),0,clrNONE))
                     {
                         Print("Error al mover a break even "+(string)GetLastError()+" Ticket: "+(string)OrderTicket());
                         Sleep(5000);
                         //GestionarEntradas();
                     }
                  
                  }
                  
             
             }
               
            
        }
   
   }
     
   
   
   
   
   



}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void botenesdeltester(){

     if(ObjectGetInteger(NULL,"Button1",OBJPROP_STATE)){
         ObjectDelete(0,"canal1");
         dibujarCanal("canal1",clrRed);
         ObjectSetInteger(NULL,"Button1",OBJPROP_STATE,false);
     }
    if(ObjectGetInteger(NULL,"Button2",OBJPROP_STATE))
     {
         //ObjectDelete(0,"Compra");
         ObjectSetInteger(NULL,"Button3",OBJPROP_STATE,false);
     }
     if(ObjectGetInteger(NULL,"Button3",OBJPROP_STATE))
     {
         //ObjectDelete(0,"Compra");
         ObjectSetInteger(NULL,"Button2",OBJPROP_STATE,false);
     }

     
     
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//retorna true si el tiempo esta activo
bool timecheck(){

   if(TimeYear(TimeLocal())<limityear)return true;
   if(TimeYear(TimeLocal())>limityear)return false;
   
   if(TimeMonth(TimeLocal())<limitmonth)return true;
   if(TimeMonth(TimeLocal())>limitmonth)return false;
   
   if(TimeDay(TimeLocal())<=limitday)return true;
   if(TimeDay(TimeLocal())>limitday)return false;  
   
   return false;  
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool logdhay(){
   int AccountAprob[];
   int numeroDeCuentas = 4;
   ArrayResize(AccountAprob,numeroDeCuentas);
   int  cuenta = AccountNumber();
   string cuentaString = IntegerToString(cuenta);
   int    nomeroscuenta = StringLen(cuentaString);
   string cuentaCorta = StringSubstr(cuentaString,nomeroscuenta-4,0);
   int cortanumero = (int)StringToInteger(cuentaCorta);
   AccountAprob[0]=cuenta1;
   AccountAprob[1]=cuenta2;
   AccountAprob[2]=cuenta3;
   AccountAprob[3]=cuenta4;

   for(int i =0; i<numeroDeCuentas; i++)
     {
      if(cortanumero==AccountAprob[i])
         return true;
     }
   
   return false;

  }